---------------------------------------------------------------------
-- Microsoft SQL Server T-SQL Fundamentals
-- Chapter 04 - Subqueries
-- © Itzik Ben-Gan 
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Self-Contained Subqueries
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Scalar Subqueries
---------------------------------------------------------------------

-- Order with the maximum order ID
USE Northwinds2022TSQLV7;

DECLARE @maxid AS INT = (SELECT MAX(OrderId)
                         FROM Sales.[Order]);

SELECT OrderId, OrderDate, EmployeeId, CustomerId
FROM Sales.[Order]
WHERE OrderId = @MaxId;
GO

SELECT OrderId, OrderDate, EmployeeId, CustomerId
FROM Sales.[Order]
WHERE OrderId = (SELECT MAX(O.OrderId)
                 FROM Sales.[Order] AS O);

-- Scalar subquery expected to return one value
SELECT OrderId
FROM Sales.[Order]
WHERE EmployeeId = 
  (SELECT E.EmployeeId
   FROM HumanResources.Employee AS E
   WHERE E.EmployeeLastName LIKE N'C%');
GO

SELECT OrderId
FROM Sales.[Order]
WHERE EmployeeId = 
  (SELECT E.EmployeeId
   FROM HumanResources.Employee AS E
   WHERE E.EmployeeLastName LIKE N'D%');
GO

SELECT OrderId
FROM Sales.[Order]
WHERE EmployeeId = 
  (SELECT E.EmployeeId
   FROM HumanResources.Employee AS E
   WHERE E.EmployeeLastName LIKE N'A%');

---------------------------------------------------------------------
-- Multi-Valued Subqueries
---------------------------------------------------------------------

SELECT OrderId
FROM Sales.[Order]
WHERE EmployeeId IN
  (SELECT E.EmployeeId
   FROM HumanResources.Employee AS E
   WHERE E.EmployeeLastName LIKE N'D%');

SELECT O.OrderId
FROM HumanResources.Employee AS E
  INNER JOIN Sales.[Order] AS O
    ON E.EmployeeId = O.EmployeeId
WHERE E.EmployeeLastName LIKE N'D%';

-- Orders placed by US customers
SELECT CustomerId, OrderId, OrderDate, EmployeeId
FROM Sales.[Order]
WHERE CustomerId IN
  (SELECT C.CustomerId
   FROM Sales.Customer AS C
   WHERE C.CustomerCountry = N'USA');

-- Customers who placed no orders
SELECT CustomerId, CustomerCompanyName
FROM Sales.Customer
WHERE CustomerId NOT IN
  (SELECT O.CustomerId
   FROM Sales.[Order] AS O);

-- Missing order IDs
USE Northwinds2022TSQLV7;
DROP TABLE IF EXISTS dbo.Orders;
CREATE TABLE dbo.Orders(OrderId INT NOT NULL CONSTRAINT PK_Orders PRIMARY KEY);

INSERT INTO dbo.Orders(OrderId)
  SELECT OrderId
  FROM Sales.[Order]
  WHERE OrderId % 2 = 0;

SELECT n
FROM dbo.Nums
WHERE n BETWEEN (SELECT MIN(O.OrderId) FROM dbo.Orders AS O)
            AND (SELECT MAX(O.OrderId) FROM dbo.Orders AS O)
  AND n NOT IN (SELECT O.OrderId FROM dbo.Orders AS O);

-- CLeanup
DROP TABLE IF EXISTS dbo.Orders;

---------------------------------------------------------------------
-- Correlated Subqueries
---------------------------------------------------------------------

-- Orders with maximum order ID for each customer
-- Listing 4-1: Correlated Subquery
USE Northwinds2022TSQLV7;

SELECT CustomerId, OrderId, OrderDate, EmployeeId
FROM Sales.[Order] AS O1
WHERE OrderId =
  (SELECT MAX(O2.OrderId)
   FROM Sales.[Order] AS O2
   WHERE O2.CustomerId = O1.CustomerId);

SELECT MAX(O2.OrderId)
FROM Sales.[Order] AS O2
WHERE O2.CustomerId = 85;

-- Percentage of customer total
SELECT OrderId, CustomerId, DiscountedTotalAmount,
  CAST(100. * DiscountedTotalAmount / (SELECT SUM(O2.DiscountedTotalAmount)
                     FROM Sales.uvw_OrderValues AS O2
                     WHERE O2.CustomerId = O1.CustomerId)
       AS NUMERIC(5,2)) AS pct
FROM Sales.uvw_OrderValues AS O1
ORDER BY CustomerId, OrderId;

---------------------------------------------------------------------
-- EXISTS
---------------------------------------------------------------------

-- Customers from Spain who placed orders
SELECT CustomerId, CustomerCompanyName
FROM Sales.Customer AS C
WHERE CustomerCountry = N'Spain'
  AND EXISTS
    (SELECT * FROM Sales.[Order] AS O
     WHERE O.CustomerId = C.CustomerId);

-- Customers from Spain who didn't place Orders
SELECT CustomerId, CustomerCompanyName
FROM Sales.Customer AS C
WHERE CustomerCountry = N'Spain'
  AND NOT EXISTS
    (SELECT * FROM Sales.[Order] AS O
     WHERE O.CustomerId = C.CustomerId);

---------------------------------------------------------------------
-- Beyond the Fundamentals of Subqueries
-- (Optional, Advanced)
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Returning "Previous" or "Next" Value
---------------------------------------------------------------------
SELECT OrderId, OrderDate, EmployeeId, CustomerId,
  (SELECT MAX(O2.OrderId)
   FROM Sales.[Order] AS O2
   WHERE O2.OrderId < O1.OrderId) AS prevOrderId
FROM Sales.[Order] AS O1;

SELECT OrderId, OrderDate, EmployeeId, CustomerId,
  (SELECT MIN(O2.OrderId)
   FROM Sales.[Order] AS O2
   WHERE O2.OrderId > O1.OrderId) AS nextOrderId
FROM Sales.[Order] AS O1;

---------------------------------------------------------------------
-- Running Aggregates
---------------------------------------------------------------------

SELECT orderyear, TotalQuantity
FROM Sales.uvw_OrderTotalQuantityByYear;

SELECT OrderYear, TotalQuantity,
  (SELECT SUM(O2.TotalQuantity)
   FROM Sales.uvw_OrderTotalQuantityByYear AS O2
   WHERE O2.orderyear <= O1.OrderYear) AS runqty
FROM Sales.uvw_OrderTotalQuantityByYear; AS O1
ORDER BY orderyear;

---------------------------------------------------------------------
-- Misbehaving Subqueries
---------------------------------------------------------------------

---------------------------------------------------------------------
-- NULL Trouble
---------------------------------------------------------------------

-- Customers who didn't place orders

-- Using NOT IN
SELECT CustomerId, CustomerCompanyName
FROM Sales.Customer
WHERE CustomerId NOT IN(SELECT O.CustomerId
                    FROM Sales.[Order] AS O);

-- Add a row to the Orders table with a NULL CustomerId
INSERT INTO Sales.[Order]
  (CustomerId, EmployeeId, OrderDate, RequiredDate, ShipToDate, shipperid,
   freight, ShipToName, ShipToAddress, ShipToCity, ShipToRegion,
   ShipToPostalCode, ShipToCountry)
  VALUES(NULL, 1, '20160212', '20160212',
         '20160212', 1, 123.00, N'abc', N'abc', N'abc',
         N'abc', N'abc', N'abc');

-- Following returns an empty set
SELECT CustomerId, CustomerCompanyName
FROM Sales.Customer
WHERE CustomerId NOT IN(SELECT O.CustomerId
                    FROM Sales.[Order] AS O);

-- Exclude NULLs explicitly
SELECT CustomerId, CustomerCompanyName
FROM Sales.Customer
WHERE CustomerId NOT IN(SELECT O.CustomerId 
                    FROM Sales.[Order] AS O
                    WHERE O.CustomerId IS NOT NULL);

-- Using NOT EXISTS
SELECT CustomerId, CustomerCompanyName
FROM Sales.Customer AS C
WHERE NOT EXISTS
  (SELECT * 
   FROM Sales.[Order] AS O
   WHERE O.CustomerId = C.CustomerId);

-- Cleanup
DELETE FROM Sales.[Order] WHERE CustomerId IS NULL;
GO

---------------------------------------------------------------------
-- Substitution Error in a Subquery Column Name
---------------------------------------------------------------------

-- Create and populate table Sales.MyShippers
DROP TABLE IF EXISTS Sales.MyShippers;

CREATE TABLE Sales.MyShippers
(
  shipper_id  INT          NOT NULL,
  CustomerCompanyName NVARCHAR(40) NOT NULL,
  phone       NVARCHAR(24) NOT NULL,
  CONSTRAINT PK_MyShippers PRIMARY KEY(shipper_id)
);

INSERT INTO Sales.MyShippers(shipper_id, CustomerCompanyName, phone)
  VALUES(1, N'Shipper GVSUA', N'(503) 555-0137'),
	      (2, N'Shipper ETYNR', N'(425) 555-0136'),
				(3, N'Shipper ZHISN', N'(415) 555-0138');
GO

-- Shippers who shipped orders to customer 43

-- Bug
SELECT shipper_id, CustomerCompanyName
FROM Sales.MyShippers
WHERE shipper_id IN
  (SELECT shipper_id
   FROM Sales.[Order]
   WHERE CustomerId = 43);
GO

-- The safe way using aliases, bug identified
SELECT shipper_id, CustomerCompanyName
FROM Sales.MyShippers
WHERE shipper_id IN
  (SELECT O.ShipperId
   FROM Sales.[Order] AS O
   WHERE O.CustomerId = 43);
GO

-- Bug corrected
SELECT shipper_id, CustomerCompanyName
FROM Sales.MyShippers
WHERE shipper_id IN
  (SELECT O.shipperid
   FROM Sales.[Order] AS O
   WHERE O.CustomerId = 43);

-- Cleanup
DROP TABLE IF EXISTS Sales.MyShippers;
