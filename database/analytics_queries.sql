-- 1. List all investors with their advisor's full name.

SELECT i.investorid, i.firstname AS investor_firstname, i.lastname AS investor_lastname,
       a.firstname AS advisor_firstname, a.lastname AS advisor_lastname
FROM investmentmanagement.investor i
JOIN investmentmanagement.advisor a ON i.advisorid = a.advisorid;


-- 2. Find all stocks with a dividend yield greater than 5%.

SELECT symbol, companyname, dividendyield
FROM investmentmanagement.stockinformation
WHERE dividendyield > 5;


-- 3. Get the total value of all stocks held by an investor.

SELECT sh.investorid, SUM(sh.quantity * si.currentprice) AS total_stock_value
FROM investmentmanagement.stockholdings sh
JOIN investmentmanagement.stockinformation si ON sh.symbol = si.symbol
GROUP BY sh.investorid;


-- 4. Get the number of different stocks held by each investor.

SELECT sh.investorid, COUNT(DISTINCT sh.symbol) AS number_of_stocks
FROM investmentmanagement.stockholdings sh
GROUP BY sh.investorid;


-- 5. Find the advisors who have at least 5 clients.

SELECT a.advisorid, a.firstname, a.lastname
FROM investmentmanagement.advisor a
JOIN investmentmanagement.investor i ON a.advisorid = i.advisorid
GROUP BY a.advisorid
HAVING COUNT(i.investorid) >= 4;


-- 6. Get all bond transactions by an investor along with the total transaction value.

SELECT bt.investorid, bt.transactiontype, SUM(bt.quantity * bt.price) AS total_transaction_value
FROM investmentmanagement.bondtransaction bt
GROUP BY bt.investorid, bt.transactiontype;


-- 7. List investors who have held both stocks and bonds.

SELECT i.investorid, i.firstname, i.lastname
FROM investmentmanagement.investor i
JOIN investmentmanagement.stockholdings sh ON i.investorid = sh.investorid
JOIN investmentmanagement.bondholdings bh ON i.investorid = bh.investorid;


-- 8. Find investors who have held stocks for more than 3 years.

SELECT i.investorid, i.firstname, i.lastname
FROM investmentmanagement.investor i
JOIN investmentmanagement.stockholdings sh ON i.investorid = sh.investorid
WHERE EXTRACT(YEAR FROM AGE(i.datejoined)) > 3;


-- 9. Get the total bond holdings for each investor.

SELECT bh.investorid, SUM(bh.quantity * bi.bondprice) AS total_bond_value
FROM investmentmanagement.bondholdings bh
JOIN investmentmanagement.bondinformation bi ON bh.bondid = bi.bondid
GROUP BY bh.investorid;


-- 10. Find the mutual funds with the lowest expense ratio.

SELECT fundname, expenseratio
FROM investmentmanagement.fund
ORDER BY expenseratio ASC;


-- 11. Find the stock with the highest current price in each sector.

SELECT si.sector, si.symbol, si.companyname, si.currentprice
FROM investmentmanagement.stockinformation si
WHERE si.currentprice = (
    SELECT MAX(currentprice)
    FROM investmentmanagement.stockinformation
    WHERE sector = si.sector
);


-- 12. Get the average price of bonds by credit rating.

SELECT creditrating, AVG(bondprice) AS avg_bond_price
FROM investmentmanagement.bondinformation
GROUP BY creditrating;


-- 13. Find the mutual fund with the highest NAV in each fund type.

SELECT f.fundtype, f.fundname, f.nav
FROM investmentmanagement.fund f
WHERE f.nav = (
    SELECT MAX(nav)
    FROM investmentmanagement.fund
    WHERE fundtype = f.fundtype
);


-- 14. Get investors who have not made any transactions in the last 6 months.

SELECT i.investorid, i.firstname, i.lastname
FROM investmentmanagement.investor i
WHERE NOT EXISTS (
    SELECT 1
    FROM investmentmanagement.stocktransaction st
    WHERE st.investorid = i.investorid AND st.transactiondate > CURRENT_DATE - INTERVAL '6 months'
);


-- 15. Find the advisors with the highest total fees.

SELECT a.advisorid, a.firstname, a.lastname, SUM(a.fees) AS total_fees
FROM investmentmanagement.advisor a
GROUP BY a.advisorid
ORDER BY total_fees DESC;


-- 16. List the total number of transactions for each investor in stocks, bonds, and mutual funds.

SELECT st.investorid, 
       COUNT(DISTINCT st.transactionid) AS stock_transactions, 
       COUNT(DISTINCT bt.transactionid) AS bond_transactions,
       COUNT(DISTINCT ft.transactionid) AS fund_transactions
FROM investmentmanagement.stocktransaction st
JOIN investmentmanagement.bondtransaction bt ON st.investorid = bt.investorid
JOIN investmentmanagement.fundtransaction ft ON st.investorid = ft.investorid
GROUP BY st.investorid;


-- 17. Find the total number of transactions for investors who have more than 3 stock transactions.

SELECT st.investorid, COUNT(*) AS total_transactions
FROM investmentmanagement.stocktransaction st
GROUP BY st.investorid
HAVING COUNT(*) > 3;


