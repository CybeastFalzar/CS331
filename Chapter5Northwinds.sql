---------------------------------------------------------------------
-- Microsoft SQL Server T-SQL Fundamentals
-- Chapter 05 - Table Expressions
-- © Itzik Ben-Gan 
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Derived Tables
---------------------------------------------------------------------

USE Northwinds2022TSQLV7;

SELECT *
FROM (SELECT CustomerId, CustomerCompanyName
      FROM Sales.Customer
      WHERE CustomerCountry = N'USA') AS USACusts;

---------------------------------------------------------------------
-- Assigning Column Aliases
---------------------------------------------------------------------

-- Following fails
/*
SELECT
  YEAR(OrderDate) AS OrderYear,
  COUNT(DISTINCT CustomerId) AS NumberOfCustomers
FROM Sales.[Order]
GROUP BY OrderYear;
*/
GO

-- Listing 5-1 Query with a Derived Table using Inline Aliasing Form
SELECT OrderYear, COUNT(DISTINCT CustomerId) AS NumberOfCustomers
FROM (SELECT YEAR(OrderDate) AS OrderYear, CustomerId
      FROM Sales.[Order]) AS D
GROUP BY OrderYear;

SELECT YEAR(OrderDate) AS OrderYear, COUNT(DISTINCT CustomerId) AS NumberOfCustomers
FROM Sales.[Order]
GROUP BY YEAR(OrderDate);

-- External column aliasing
SELECT OrderYear, COUNT(DISTINCT CustomerId) AS NumberOfCustomers
FROM (SELECT YEAR(OrderDate), CustomerId
      FROM Sales.[Order]) AS D(OrderYear, CustomerId)
GROUP BY OrderYear;
GO

---------------------------------------------------------------------
-- Using Arguments
---------------------------------------------------------------------

-- Yearly Count of Customers handled by Employee 3
DECLARE @EmployeeId AS INT = 3;

SELECT OrderYear, COUNT(DISTINCT CustomerId) AS NumberOfCustomers
FROM (SELECT YEAR(OrderDate) AS OrderYear, CustomerId
      FROM Sales.[Order]
      WHERE EmployeeId = @EmployeeId) AS D
GROUP BY OrderYear;
GO

---------------------------------------------------------------------
-- Nesting
---------------------------------------------------------------------

-- Listing 5-2 Query with Nested Derived Tables
SELECT OrderYear, NumberOfCustomers
FROM (SELECT OrderYear, COUNT(DISTINCT CustomerId) AS NumberOfCustomers
      FROM (SELECT YEAR(OrderDate) AS OrderYear, CustomerId
            FROM Sales.[Order]) AS D1
      GROUP BY OrderYear) AS D2
WHERE NumberOfCustomers > 70;

SELECT YEAR(OrderDate) AS OrderYear, COUNT(DISTINCT CustomerId) AS NumberOfCustomers
FROM Sales.[Order]
GROUP BY YEAR(OrderDate)
HAVING COUNT(DISTINCT CustomerId) > 70;

---------------------------------------------------------------------
-- Multiple References
---------------------------------------------------------------------

-- Listing 5-3 Multiple Derived Tables Based on the Same Query
SELECT Cur.OrderYear, 
  Cur.NumberOfCustomers AS curNumberOfCustomers, Prv.NumberOfCustomers AS prvNumberOfCustomers,
  Cur.NumberOfCustomers - Prv.NumberOfCustomers AS growth
FROM (SELECT YEAR(OrderDate) AS OrderYear,
        COUNT(DISTINCT CustomerId) AS NumberOfCustomers
      FROM Sales.[Order]
      GROUP BY YEAR(OrderDate)) AS Cur
  LEFT OUTER JOIN
     (SELECT YEAR(OrderDate) AS OrderYear,
        COUNT(DISTINCT CustomerId) AS NumberOfCustomers
      FROM Sales.[Order]
      GROUP BY YEAR(OrderDate)) AS Prv
    ON Cur.OrderYear = Prv.OrderYear + 1;

---------------------------------------------------------------------
-- Common Table Expressions
---------------------------------------------------------------------

WITH USACusts AS
(
  SELECT CustomerId, CustomerCompanyName
  FROM Sales.Customer
  WHERE CustomerCountry = N'USA'
)
SELECT * FROM USACusts;

---------------------------------------------------------------------
-- Assigning Column Aliases
---------------------------------------------------------------------

-- Inline column aliasing
WITH C AS
(
  SELECT YEAR(OrderDate) AS OrderYear, CustomerId
  FROM Sales.[Order]
)
SELECT OrderYear, COUNT(DISTINCT CustomerId) AS NumberOfCustomers
FROM C
GROUP BY OrderYear;

-- External column aliasing
WITH C(OrderYear, CustomerId) AS
(
  SELECT YEAR(OrderDate), CustomerId
  FROM Sales.[Order]
)
SELECT OrderYear, COUNT(DISTINCT CustomerId) AS NumberOfCustomers
FROM C
GROUP BY OrderYear;
GO

---------------------------------------------------------------------
-- Using Arguments
---------------------------------------------------------------------

DECLARE @EmployeeId AS INT = 3;

WITH C AS
(
  SELECT YEAR(OrderDate) AS OrderYear, CustomerId
  FROM Sales.[Order]
  WHERE EmployeeId = @EmployeeId
)
SELECT OrderYear, COUNT(DISTINCT CustomerId) AS NumberOfCustomers
FROM C
GROUP BY OrderYear;
GO

---------------------------------------------------------------------
-- Defining Multiple CTEs
---------------------------------------------------------------------

WITH C1 AS
(
  SELECT YEAR(OrderDate) AS OrderYear, CustomerId
  FROM Sales.[Order]
),
C2 AS
(
  SELECT OrderYear, COUNT(DISTINCT CustomerId) AS NumberOfCustomers
  FROM C1
  GROUP BY OrderYear
)
SELECT OrderYear, NumberOfCustomers
FROM C2
WHERE NumberOfCustomers > 70;

---------------------------------------------------------------------
-- Multiple References
---------------------------------------------------------------------

WITH YearlyCount AS
(
  SELECT YEAR(OrderDate) AS OrderYear,
    COUNT(DISTINCT CustomerId) AS NumberOfCustomers
  FROM Sales.[Order]
  GROUP BY YEAR(OrderDate)
)
SELECT Cur.OrderYear, 
  Cur.NumberOfCustomers AS curNumberOfCustomers, Prv.NumberOfCustomers AS prvNumberOfCustomers,
  Cur.NumberOfCustomers - Prv.NumberOfCustomers AS growth
FROM YearlyCount AS Cur
  LEFT OUTER JOIN YearlyCount AS Prv
    ON Cur.OrderYear = Prv.OrderYear + 1;

---------------------------------------------------------------------
-- Recursive CTEs (Optional, Advanced)
---------------------------------------------------------------------

WITH EmpsCTE AS
(
  SELECT EmployeeId, EmployeeManagerId, EmployeeFirstName, EmployeeLastName
  FROM HumanResources.Employee
  WHERE EmployeeId = 2
  
  UNION ALL
  
  SELECT C.EmployeeId, C.EmployeeManagerId, C.EmployeeFirstName, C.EmployeeLastName
  FROM EmpsCTE AS P
    INNER JOIN HumanResources.Employee AS C
      ON C.EmployeeManagerId = P.EmployeeId
)
SELECT EmployeeId, EmployeeManagerId, EmployeeFirstName, EmployeeLastName
FROM EmpsCTE;

---------------------------------------------------------------------
-- Views
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Views Described
---------------------------------------------------------------------

-- Creating USACusts View
DROP VIEW IF EXISTS Sales.USACusts;
GO
CREATE VIEW Sales.USACusts
AS

SELECT
  CustomerId, CustomerCompanyName, CustomerContactName, CustomerContactTitle, CustomerAddress,
  CustomerCity, CustomerRegion, CustomerPostalCode, CustomerCountry, CustomerPhoneNumber, CustomerFaxNumber
FROM Sales.Customer
WHERE CustomerCountry = N'USA';
GO

SELECT CustomerId, CustomerCompanyName
FROM Sales.USACusts;
GO

---------------------------------------------------------------------
-- Views and ORDER BY
---------------------------------------------------------------------

-- ORDER BY in a View is not Allowed
/*
ALTER VIEW Sales.USACusts
AS

SELECT
  CustomerId, CustomerCompanyName, CustomerContactName, CustomerContactTitle, CustomerAddress,
  CustomerCity, CustomerRegion, CustomerPostalCode, CustomerCountry, CustomerPhoneNumber, CustomerFaxNumber
FROM Sales.Customer
WHERE CustomerCountry = N'USA'
ORDER BY CustomerRegion;
GO
*/

-- Instead, use ORDER BY in Outer Query
SELECT CustomerId, CustomerCompanyName, CustomerRegion
FROM Sales.USACusts
ORDER BY CustomerRegion;
GO

-- Do not Rely on TOP 
ALTER VIEW Sales.USACusts
AS

SELECT TOP (100) PERCENT
  CustomerId, CustomerCompanyName, CustomerContactName, CustomerContactTitle, CustomerAddress,
  CustomerCity, CustomerRegion, CustomerPostalCode, CustomerCountry, CustomerPhoneNumber, CustomerFaxNumber
FROM Sales.Customer
WHERE CustomerCountry = N'USA'
ORDER BY CustomerRegion;
GO

-- Query USACusts
SELECT CustomerId, CustomerCompanyName, CustomerRegion
FROM Sales.USACusts;
GO

-- DO NOT rely on OFFSET-FETCH, even if for now the engine does return rows in rder
ALTER VIEW Sales.USACusts
AS

SELECT 
  CustomerId, CustomerCompanyName, CustomerContactName, CustomerContactTitle, CustomerAddress,
  CustomerCity, CustomerRegion, CustomerPostalCode, CustomerCountry, CustomerPhoneNumber, CustomerFaxNumber
FROM Sales.Customer
WHERE CustomerCountry = N'USA'
ORDER BY CustomerRegion
OFFSET 0 ROWS;
GO

-- Query USACusts
SELECT CustomerId, CustomerCompanyName, CustomerRegion
FROM Sales.USACusts;
GO

---------------------------------------------------------------------
-- View Options
---------------------------------------------------------------------

---------------------------------------------------------------------
-- ENCRYPTION
---------------------------------------------------------------------

ALTER VIEW Sales.USACusts
AS

SELECT
  CustomerId, CustomerCompanyName, CustomerContactName, CustomerContactTitle, CustomerAddress,
  CustomerCity, CustomerRegion, CustomerPostalCode, CustomerCountry, CustomerPhoneNumber, CustomerFaxNumber
FROM Sales.Customer
WHERE CustomerCountry = N'USA';
GO

SELECT OBJECT_DEFINITION(OBJECT_ID('Sales.USACusts'));
GO

ALTER VIEW Sales.USACusts WITH ENCRYPTION
AS

SELECT
  CustomerId, CustomerCompanyName, CustomerContactName, CustomerContactTitle, CustomerAddress,
  CustomerCity, CustomerRegion, CustomerPostalCode, CustomerCountry, CustomerPhoneNumber, CustomerFaxNumber
FROM Sales.Customer
WHERE CustomerCountry = N'USA';
GO

SELECT OBJECT_DEFINITION(OBJECT_ID('Sales.USACusts'));

EXEC sp_helptext 'Sales.USACusts';
GO

---------------------------------------------------------------------
-- SCHEMABINDING
---------------------------------------------------------------------

ALTER VIEW Sales.USACusts WITH SCHEMABINDING
AS

SELECT
  CustomerId, CustomerCompanyName, CustomerContactName, CustomerContactTitle, CustomerAddress,
  CustomerCity, CustomerRegion, CustomerPostalCode, CustomerCountry, CustomerPhoneNumber, CustomerFaxNumber
FROM Sales.Customer
WHERE CustomerCountry = N'USA';
GO

-- Try a schema change
/*
ALTER TABLE Sales.Customer DROP COLUMN CustomerAddress;
*/
GO

---------------------------------------------------------------------
-- CHECK OPTION
---------------------------------------------------------------------

-- Notice that you can insert a row through the view
INSERT INTO Sales.USACusts(
  CustomerCompanyName, CustomerContactName, CustomerContactTitle, CustomerAddress,
  CustomerCity, CustomerRegion, CustomerPostalCode, CustomerCountry, CustomerPhoneNumber, CustomerFaxNumber)
 VALUES(
  N'Customer ABCDE', N'Contact ABCDE', N'Title ABCDE', N'Address ABCDE',
  N'London', NULL, N'12345', N'UK', N'012-3456789', N'012-3456789');

-- But when you query the view, you won't see it
SELECT CustomerId, CustomerCompanyName, CustomerCountry
FROM Sales.USACusts
WHERE CustomerCompanyName = N'Customer ABCDE';

-- You can see it in the table, though
SELECT CustomerId, CustomerCompanyName, CustomerCountry
FROM Sales.Customer
WHERE CustomerCompanyName = N'Customer ABCDE';
GO

-- Add CHECK OPTION to the View
ALTER VIEW Sales.USACusts WITH SCHEMABINDING
AS

SELECT
  CustomerId, CustomerCompanyName, CustomerContactName, CustomerContactTitle, CustomerAddress,
  CustomerCity, CustomerRegion, CustomerPostalCode, CustomerCountry, CustomerPhoneNumber, CustomerFaxNumber
FROM Sales.Customer
WHERE CustomerCountry = N'USA'
WITH CHECK OPTION;
GO

-- Notice that you can't insert a row through the view
/*
INSERT INTO Sales.USACusts(
  CustomerCompanyName, CustomerContactName, CustomerContactTitle, CustomerAddress,
  CustomerCity, CustomerRegion, CustomerPostalCode, CustomerCountry, CustomerPhoneNumber, CustomerFaxNumber)
 VALUES(
  N'Customer FGHIJ', N'Contact FGHIJ', N'Title FGHIJ', N'Address FGHIJ',
  N'London', NULL, N'12345', N'UK', N'012-3456789', N'012-3456789');
*/
GO

-- Cleanup
DELETE FROM Sales.Customer
WHERE CustomerId > 91;

DROP VIEW IF EXISTS Sales.USACusts;
GO

---------------------------------------------------------------------
-- Inline User Defined Functions
---------------------------------------------------------------------

-- Creating GetCustOrders function
USE Northwinds2022TSQLV7;
DROP FUNCTION IF EXISTS dbo.GetCustOrders;
GO
CREATE FUNCTION dbo.GetCustOrders
  (@cid AS INT) RETURNS TABLE
AS
RETURN
  SELECT OrderId, CustomerId, EmployeeId, OrderDate, requireddate,
    ShipToDate, shipperid, freight, ShipToName, ShipToAddress, ShipToCity,
    ShipToRegion, ShipToPostalCode, ShipToCountry
  FROM Sales.[Order]
  WHERE CustomerId = @cid;
GO

-- Test Function
SELECT OrderId, CustomerId
FROM dbo.GetCustOrders(1) AS O;

SELECT O.OrderId, O.CustomerId, OD.ProductId, OD.Quantity
FROM dbo.GetCustOrders(1) AS O
  INNER JOIN Sales.OrderDetail AS OD
    ON O.OrderId = OD.OrderId;
GO

-- Cleanup
DROP FUNCTION IF EXISTS dbo.GetCustOrders;
GO

---------------------------------------------------------------------
-- APPLY
---------------------------------------------------------------------

SELECT S.ShipperId, E.EmployeeId
FROM Sales.Shipper AS S
  CROSS JOIN HumanResources.Employee AS E;

SELECT S.ShipperId, E.EmployeeId
FROM Sales.Shipper AS S
  CROSS APPLY HumanResources.Employee AS E;

-- 3 most recent orders for each customer
SELECT C.CustomerId, A.OrderId, A.OrderDate
FROM Sales.Customer AS C
  CROSS APPLY
    (SELECT TOP (3) OrderId, EmployeeId, OrderDate, requireddate 
     FROM Sales.[Order] AS O
     WHERE O.CustomerId = C.CustomerId
     ORDER BY OrderDate DESC, OrderId DESC) AS A;

-- With OFFSET-FETCH
SELECT C.CustomerId, A.OrderId, A.OrderDate
FROM Sales.Customer AS C
  CROSS APPLY
    (SELECT OrderId, EmployeeId, OrderDate, requireddate 
     FROM Sales.[Order] AS O
     WHERE O.CustomerId = C.CustomerId
     ORDER BY OrderDate DESC, OrderId DESC
     OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY) AS A;

-- 3 most recent orders for each customer, preserve customers
SELECT C.CustomerId, A.OrderId, A.OrderDate
FROM Sales.Customer AS C
  OUTER APPLY
    (SELECT TOP (3) OrderId, EmployeeId, OrderDate, requireddate 
     FROM Sales.[Order] AS O
     WHERE O.CustomerId = C.CustomerId
     ORDER BY OrderDate DESC, OrderId DESC) AS A;

-- Creation Script for the Function TopOrders
DROP FUNCTION IF EXISTS dbo.TopOrders;
GO
CREATE FUNCTION dbo.TopOrders
  (@CustomerId AS INT, @n AS INT)
  RETURNS TABLE
AS
RETURN
  SELECT TOP (@n) OrderId, EmployeeId, OrderDate, requireddate 
  FROM Sales.[Order]
  WHERE CustomerId = @CustomerId
  ORDER BY OrderDate DESC, OrderId DESC;
GO

SELECT
  C.CustomerId, C.CustomerCompanyName,
  A.OrderId, A.EmployeeId, A.OrderDate, A.requireddate 
FROM Sales.Customer AS C
  CROSS APPLY dbo.TopOrders(C.CustomerId, 3) AS A;
