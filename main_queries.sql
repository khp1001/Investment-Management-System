
-- 1. Stocks held by investors with a current price above their 6-day average
SELECT DISTINCT si.symbol,
                si.companyname,
                si.currentprice
FROM investmentmanagement.stockinformation si
JOIN investmentmanagement.stockholdings sh ON si.symbol = sh.symbol
WHERE si.currentprice > (
    SELECT AVG(md.price)
    FROM investmentmanagement.marketdata md
    WHERE md.assetid = si.symbol
      AND md.assettype = 'Stock'
      AND md.date BETWEEN (CURRENT_DATE - INTERVAL '6 days') AND (CURRENT_DATE - INTERVAL '5 day')
)
ORDER BY si.symbol;

-- 2. Investors with >20% bonds, advisor experience >3 yrs, and fees < average
SELECT i.investorid,
       i.firstname,
       i.lastname
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
);

-- 3. Percentage of total investments by type, per investor
WITH investment_summary AS (
    SELECT i.investorid,
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
SELECT i.investorid,
       i.firstname,
       i.lastname,
       COALESCE(total_stock_investment, 0) AS total_stock_investment,
       COALESCE(total_bond_investment, 0) AS total_bond_investment,
       COALESCE(total_mutual_fund_investment, 0) AS total_mutual_fund_investment,
       (COALESCE(total_stock_investment, 0) / NULLIF((COALESCE(total_stock_investment, 0) + COALESCE(total_bond_investment, 0) + COALESCE(total_mutual_fund_investment, 0)), 0)) * 100 AS stock_percentage,
       (COALESCE(total_bond_investment, 0) / NULLIF((COALESCE(total_stock_investment, 0) + COALESCE(total_bond_investment, 0) + COALESCE(total_mutual_fund_investment, 0)), 0)) * 100 AS bond_percentage,
       (COALESCE(total_mutual_fund_investment, 0) / NULLIF((COALESCE(total_stock_investment, 0) + COALESCE(total_bond_investment, 0) + COALESCE(total_mutual_fund_investment, 0)), 0)) * 100 AS mutual_fund_percentage
FROM investmentmanagement.investor i
LEFT JOIN investment_summary ti ON i.investorid = ti.investorid;

-- 4. Top trading volume asset for each date
SELECT t.date,
       t.assetid,
       t.price,
       t.volume
FROM investmentmanagement.marketdata t
WHERE t.volume = (
    SELECT MAX(volume)
    FROM investmentmanagement.marketdata
    WHERE date = t.date
)
ORDER BY t.date;

-- 5. Investors with bonds below average coupon rate, sorted by yield
SELECT i.investorid,
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
ORDER BY bond_yield DESC;
