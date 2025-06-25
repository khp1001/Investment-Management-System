-- Create schema
CREATE SCHEMA investmentmanagement;

-- Create the Advisor table first
CREATE TABLE investmentmanagement.advisor (
    advisorid INT PRIMARY KEY,
    firstname VARCHAR(100),
    lastname VARCHAR(100),
    phonenumber VARCHAR(20),
    email VARCHAR(255),
    experience INT,
    fees INT
);

-- Create the Investor table, referencing Advisor
CREATE TABLE investmentmanagement.investor (
    investorid INT PRIMARY KEY,
    firstname VARCHAR(100),
    lastname VARCHAR(100),
    dob DATE,
    age INT CHECK (age > 18),
    email VARCHAR(255),
    phonenumber VARCHAR(20),
    address VARCHAR(255),
    datejoined DATE,
    advisorid INT,
    FOREIGN KEY (advisorid) REFERENCES investmentmanagement.advisor(advisorid) ON DELETE SET NULL
);

-- Proceed to create other tables as per the original schema
CREATE TABLE investmentmanagement.stockinformation (
    symbol VARCHAR(10) PRIMARY KEY,
    companyname VARCHAR(255),
    currentprice DECIMAL(10, 2),
    marketcap DECIMAL(15, 2),
    sector VARCHAR(100),
    dividendyield DECIMAL(5, 2),
    priceearningsratio DECIMAL(5, 2),
    "52weekhigh" DECIMAL(10, 2),
    "52weeklow" DECIMAL(10, 2)
);

CREATE TABLE investmentmanagement.bondinformation (
    bondid INT PRIMARY KEY,
    bondname VARCHAR(255),
    bondprice DECIMAL(10, 2),
    couponrate DECIMAL(5, 2),
    maturitydate DATE,
    creditrating VARCHAR(10)
);

CREATE TABLE investmentmanagement.fund (
    fundid INT PRIMARY KEY,
    fundname VARCHAR(255),
    fundtype VARCHAR(100),
    nav DECIMAL(10, 2),
    expenseratio DECIMAL(5, 2),
    fundmanager VARCHAR(100),
    inceptiondate DATE
);

CREATE TABLE investmentmanagement.stockholdings (
    stockholdingid INT PRIMARY KEY,
    investorid INT,
    symbol VARCHAR(10),
    quantity INT,
    FOREIGN KEY (investorid) REFERENCES investmentmanagement.investor(investorid) ON DELETE CASCADE,
    FOREIGN KEY (symbol) REFERENCES investmentmanagement.stockinformation(symbol) ON DELETE CASCADE
);

CREATE TABLE investmentmanagement.bondholdings (
    bondholdingid INT PRIMARY KEY,
    investorid INT,
    bondid INT,
    quantity INT,
    FOREIGN KEY (investorid) REFERENCES investmentmanagement.investor(investorid) ON DELETE CASCADE,
    FOREIGN KEY (bondid) REFERENCES investmentmanagement.bondinformation(bondid) ON DELETE CASCADE
);

CREATE TABLE investmentmanagement.mutualfundholdings (
    mutualfundholdingid INT PRIMARY KEY,
    investorid INT,
    fundid INT,
    quantity INT,
    FOREIGN KEY (investorid) REFERENCES investmentmanagement.investor(investorid) ON DELETE CASCADE,
    FOREIGN KEY (fundid) REFERENCES investmentmanagement.fund(fundid) ON DELETE CASCADE
);

CREATE TABLE investmentmanagement.stocktransaction (
    transactionid INT PRIMARY KEY,
    investorid INT,
    symbol VARCHAR(10),
    transactiontype VARCHAR(10),
    quantity INT,
    price DECIMAL(10, 2),
    transactiondate DATE,
    transactionvalue DECIMAL(15, 2),
    FOREIGN KEY (investorid) REFERENCES investmentmanagement.investor(investorid) ON DELETE CASCADE,
    FOREIGN KEY (symbol) REFERENCES investmentmanagement.stockinformation(symbol) ON DELETE CASCADE
);

CREATE TABLE investmentmanagement.bondtransaction (
    transactionid INT PRIMARY KEY,
    investorid INT,
    bondid INT,
    transactiontype VARCHAR(10),
    quantity INT,
    price DECIMAL(10, 2),
    transactiondate DATE,
    transactionvalue DECIMAL(15, 2),
    FOREIGN KEY (investorid) REFERENCES investmentmanagement.investor(investorid) ON DELETE CASCADE,
    FOREIGN KEY (bondid) REFERENCES investmentmanagement.bondinformation(bondid) ON DELETE CASCADE
);

CREATE TABLE investmentmanagement.fundtransaction (
    transactionid INT PRIMARY KEY,
    investorid INT,
    fundid INT,
    transactiontype VARCHAR(10),
    quantity INT,
    price DECIMAL(10, 2),
    transactiondate DATE,
    transactionvalue DECIMAL(15, 2),
    FOREIGN KEY (investorid) REFERENCES investmentmanagement.investor(investorid) ON DELETE CASCADE,
    FOREIGN KEY (fundid) REFERENCES investmentmanagement.fund(fundid) ON DELETE CASCADE
);

CREATE TABLE investmentmanagement.marketdata (
    marketdataid INT PRIMARY KEY,
    date DATE,
    assettype VARCHAR(50),
    assetid VARCHAR(50),
    price DECIMAL(10, 2),
    volume INT
);

-- Trigger to update holdings after a buy or sell transaction for Stock
CREATE OR REPLACE FUNCTION updatestockholdings()
RETURNS TRIGGER AS $$
DECLARE
    currentquantity INT;
BEGIN
    IF NEW.transactiontype = 'Buy' THEN
        SELECT quantity INTO currentquantity
        FROM investmentmanagement.stockholdings
        WHERE investorid = NEW.investorid AND symbol = NEW.symbol;

        IF currentquantity IS NOT NULL THEN
            UPDATE investmentmanagement.stockholdings
            SET quantity = quantity + NEW.quantity
            WHERE investorid = NEW.investorid AND symbol = NEW.symbol;
        ELSE
            INSERT INTO investmentmanagement.stockholdings (investorid, symbol, quantity)
            VALUES (NEW.investorid, NEW.symbol, NEW.quantity);
        END IF;
    ELSIF NEW.transactiontype = 'Sell' THEN
        SELECT quantity INTO currentquantity
        FROM investmentmanagement.stockholdings
        WHERE investorid = NEW.investorid AND symbol = NEW.symbol;

        IF currentquantity < NEW.quantity THEN
            RAISE EXCEPTION 'Insufficient stock holdings to sell';
        ELSE
            UPDATE investmentmanagement.stockholdings
            SET quantity = quantity - NEW.quantity
            WHERE investorid = NEW.investorid AND symbol = NEW.symbol;

            IF currentquantity - NEW.quantity = 0 THEN
                DELETE FROM investmentmanagement.stockholdings
                WHERE investorid = NEW.investorid AND symbol = NEW.symbol;
            END IF;
        END IF;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER updatestockholdingsafterbuyorsell
AFTER INSERT ON investmentmanagement.stocktransaction
FOR EACH ROW
EXECUTE FUNCTION updatestockholdings();

-- Similarly, create the triggers for Bond and Mutual Fund holdings

-- Trigger to update holdings after a buy or sell transaction for Bond
CREATE OR REPLACE FUNCTION updatebondholdings()
RETURNS TRIGGER AS $$
DECLARE
    currentquantity INT;
BEGIN
    IF NEW.transactiontype = 'Buy' THEN
        SELECT quantity INTO currentquantity
        FROM investmentmanagement.bondholdings
        WHERE investorid = NEW.investorid AND bondid = NEW.bondid;

        IF currentquantity IS NOT NULL THEN
            UPDATE investmentmanagement.bondholdings
            SET quantity = quantity + NEW.quantity
            WHERE investorid = NEW.investorid AND bondid = NEW.bondid;
        ELSE
            INSERT INTO investmentmanagement.bondholdings (investorid, bondid, quantity)
            VALUES (NEW.investorid, NEW.bondid, NEW.quantity);
        END IF;
    ELSIF NEW.transactiontype = 'Sell' THEN
        SELECT quantity INTO currentquantity
        FROM investmentmanagement.bondholdings
        WHERE investorid = NEW.investorid AND bondid = NEW.bondid;

        IF currentquantity < NEW.quantity THEN
            RAISE EXCEPTION 'Insufficient bond holdings to sell';
        ELSE
            UPDATE investmentmanagement.bondholdings
            SET quantity = quantity - NEW.quantity
            WHERE investorid = NEW.investorid AND bondid = NEW.bondid;

            IF currentquantity - NEW.quantity = 0 THEN
                DELETE FROM investmentmanagement.bondholdings
                WHERE investorid = NEW.investorid AND bondid = NEW.bondid;
            END IF;
        END IF;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER updatebondholdingsafterbuyorsell
AFTER INSERT ON investmentmanagement.bondtransaction
FOR EACH ROW
EXECUTE FUNCTION updatebondholdings();

-- Trigger to update holdings after a buy or sell transaction for Mutual Fund
CREATE OR REPLACE FUNCTION updatemutualfundholdings()
RETURNS TRIGGER AS $$
DECLARE
    currentquantity INT;
BEGIN
    IF NEW.transactiontype = 'Buy' THEN
        SELECT quantity INTO currentquantity
        FROM investmentmanagement.mutualfundholdings
        WHERE investorid = NEW.investorid AND fundid = NEW.fundid;

        IF currentquantity IS NOT NULL THEN
            UPDATE investmentmanagement.mutualfundholdings
            SET quantity = quantity + NEW.quantity
            WHERE investorid = NEW.investorid AND fundid = NEW.fundid;
        ELSE
            INSERT INTO investmentmanagement.mutualfundholdings (investorid, fundid, quantity)
            VALUES (NEW.investorid, NEW.fundid, NEW.quantity);
        END IF;
    ELSIF NEW.transactiontype = 'Sell' THEN
        SELECT quantity INTO currentquantity
        FROM investmentmanagement.mutualfundholdings
        WHERE investorid = NEW.investorid AND fundid = NEW.fundid;

        IF currentquantity < NEW.quantity THEN
            RAISE EXCEPTION 'Insufficient mutual fund holdings to sell';
        ELSE
            UPDATE investmentmanagement.mutualfundholdings
            SET quantity = quantity - NEW.quantity
            WHERE investorid = NEW.investorid AND fundid = NEW.fundid;

            IF currentquantity - NEW.quantity = 0 THEN
                DELETE FROM investmentmanagement.mutualfundholdings
                WHERE investorid = NEW.investorid AND fundid = NEW.fundid;
            END IF;
        END IF;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER updatemutualfundholdingsafterbuyorsell
AFTER INSERT ON investmentmanagement.fundtransaction
FOR EACH ROW
EXECUTE FUNCTION updatemutualfundholdings();
