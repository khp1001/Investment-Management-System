from flask import Flask, jsonify
import psycopg2
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

app = Flask(__name__)

# Database configuration
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'dpg-csbsmolds78s73bf2930-a.oregon-postgres.render.com'),
    'port': os.getenv('DB_PORT', '5432'),
    'dbname': os.getenv('DB_NAME', 'Investment_Management_System'),
    'user': os.getenv('DB_USER', 'khanak'),
    'password': os.getenv('DB_PASSWORD', '12345678@kk')
}

def get_db_connection():
    """Establish database connection"""
    return psycopg2.connect(**DB_CONFIG)

@app.route('/stocks/above_avg', methods=['GET'])
def get_stocks_above_avg():
    """Endpoint 1: Stocks with price above 6-day average"""
    query = """
    SELECT DISTINCT si.symbol, si.companyname, si.currentprice
    FROM investmentmanagement.stockinformation si
    JOIN investmentmanagement.stockholdings sh ON si.symbol = sh.symbol
    WHERE si.currentprice > (
        SELECT AVG(md.price)
        FROM investmentmanagement.marketdata md
        WHERE md.assetid = si.symbol
        AND md.assettype = 'Stock'
        AND md.date BETWEEN (CURRENT_DATE - INTERVAL '6 days') AND CURRENT_DATE
    )
    ORDER BY si.symbol
    """
    return execute_query(query)

@app.route('/investors/bond_heavy', methods=['GET'])
def get_investors_above_threshold():
    """Endpoint 2: Investors with >20% bonds and experienced advisors"""
    query = """
    SELECT i.investorid, i.firstname, i.lastname
    FROM investmentmanagement.investor i
    JOIN investmentmanagement.bondholdings bh ON i.investorid = bh.investorid
    JOIN investmentmanagement.bondinformation b ON bh.bondid = b.bondid
    JOIN investmentmanagement.advisor a ON i.advisorid = a.advisorid
    WHERE a.experience > 3
    GROUP BY i.investorid, i.firstname, i.lastname, a.fees
    HAVING SUM(bh.quantity * b.bondprice) > 0.2 * (
        SELECT SUM(total_investment)
        FROM (
            SELECT SUM(bh2.quantity * b2.bondprice) AS total_investment
            FROM investmentmanagement.bondholdings bh2
            JOIN investmentmanagement.bondinformation b2 ON bh2.bondid = b2.bondid
            WHERE bh2.investorid = i.investorid
            UNION
            SELECT SUM(sh.quantity * si.currentprice)
            FROM investmentmanagement.stockholdings sh
            JOIN investmentmanagement.stockinformation si ON sh.symbol = si.symbol
            WHERE sh.investorid = i.investorid
            UNION
            SELECT SUM(mf.quantity * f.nav)
            FROM investmentmanagement.mutualfundholdings mf
            JOIN investmentmanagement.fund f ON mf.fundid = f.fundid
            WHERE mf.investorid = i.investorid
        ) AS total_investments
    )
    AND a.fees < (
        SELECT AVG(fees)
        FROM investmentmanagement.advisor
        WHERE experience > 3
    )
    """
    return execute_query(query)

@app.route('/investors/portfolio', methods=['GET'])
def get_investor_portfolio():
    """Endpoint 3: Investment portfolio percentages by type"""
    query = """
    WITH investment_summary AS (
        SELECT
            i.investorid,
            SUM(CASE WHEN si.symbol IS NOT NULL THEN sh.quantity * si.currentprice ELSE 0 END) AS total_stock_investment,
            SUM(CASE WHEN bi.bondid IS NOT NULL THEN bh.quantity * bi.bondprice ELSE 0 END) AS total_bond_investment,
            SUM(CASE WHEN fi.fundid IS NOT NULL THEN mh.quantity * fi.nav ELSE 0 END) AS total_mutual_fund_investment
        FROM investmentmanagement.investor i
        LEFT JOIN investmentmanagement.stockholdings sh ON i.investorid = sh.investorid
        LEFT JOIN investmentmanagement.stockinformation si ON sh.symbol = si.symbol
        LEFT JOIN investmentmanagement.bondholdings bh ON i.investorid = bh.investorid
        LEFT JOIN investmentmanagement.bondinformation bi ON bh.bondid = bi.bondid
        LEFT JOIN investmentmanagement.mutualfundholdings mh ON i.investorid = mh.investorid
        LEFT JOIN investmentmanagement.fund fi ON mh.fundid = fi.fundid
        GROUP BY i.investorid
    )
    SELECT
        i.investorid,
        i.firstname,
        i.lastname,
        COALESCE(total_stock_investment, 0) AS total_stock_investment,
        COALESCE(total_bond_investment, 0) AS total_bond_investment,
        COALESCE(total_mutual_fund_investment, 0) AS total_mutual_fund_investment,
        ROUND((COALESCE(total_stock_investment, 0) / NULLIF((COALESCE(total_stock_investment, 0) + 
              COALESCE(total_bond_investment, 0) + COALESCE(total_mutual_fund_investment, 0)), 0)) * 100, 2) AS stock_percentage,
        ROUND((COALESCE(total_bond_investment, 0) / NULLIF((COALESCE(total_stock_investment, 0) + 
              COALESCE(total_bond_investment, 0) + COALESCE(total_mutual_fund_investment, 0)), 0)) * 100, 2) AS bond_percentage,
        ROUND((COALESCE(total_mutual_fund_investment, 0) / NULLIF((COALESCE(total_stock_investment, 0) + 
              COALESCE(total_bond_investment, 0) + COALESCE(total_mutual_fund_investment, 0)), 0)) * 100, 2) AS mutual_fund_percentage
    FROM investmentmanagement.investor i
    LEFT JOIN investment_summary ti ON i.investorid = ti.investorid
    """
    return execute_query(query)

@app.route('/market/top_volume', methods=['GET'])
def get_max_volume_market_data():
    """Endpoint 4: Top trading volume assets by date"""
    query = """
    SELECT t.date, t.assetid, t.price, t.volume
    FROM investmentmanagement.marketdata t
    WHERE t.volume = (
        SELECT MAX(volume)
        FROM investmentmanagement.marketdata
        WHERE date = t.date
    )
    ORDER BY t.date
    """
    return execute_query(query)

@app.route('/investors/low_yield_bonds', methods=['GET'])
def get_investors_bond_info():
    """Endpoint 5: Investors holding bonds with below-average coupon rates"""
    query = """
    SELECT
        i.investorid,
        i.firstname,
        i.lastname,
        b.bondname,
        bh.quantity,
        bh.quantity * bi.bondprice AS total_bond_value,
        bi.couponrate AS bond_yield
    FROM investmentmanagement.investor i
    JOIN investmentmanagement.bondholdings bh ON i.investorid = bh.investorid
    JOIN investmentmanagement.bondinformation bi ON bh.bondid = bi.bondid
    JOIN investmentmanagement.bondinformation b ON bh.bondid = b.bondid
    WHERE bi.couponrate < (
        SELECT AVG(couponrate)
        FROM investmentmanagement.bondinformation
    )
    ORDER BY bond_yield DESC
    """
    return execute_query(query)

def execute_query(query):
    """Helper function to execute SQL queries and return JSON results"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        cursor.execute(query)
        results = cursor.fetchall()
        cursor.close()
        conn.close()
        return jsonify(results)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)