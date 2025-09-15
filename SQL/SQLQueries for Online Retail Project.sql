Use HenryKinyaraDatabase;

SELECT*FROM [HenryKinyaraDatabase].[dbo].[Online Retail];

--DATA ANALYSIS

-- total number of transactions.

Select Count(*) From [Online Retail] AS Total_Number_Of_Transactions;

-- top 10 countries by total sales (excluding UK if needed)
Select  Top 10 Count(*) AS Total_Number_Of_Transactions, [Online Retail].Country From [Online Retail]
Group By [Online Retail].Country
Order by Total_Number_Of_Transactions Desc;

-- the total sales revenue (Quantity × UnitPrice).
Select SUM(Cast (Quantity*UnitPrice As float)) AS Total_Sales_Revenue From [Online Retail];


-- unique products that exist in the dataset.
Select Distinct Count([Online Retail].StockCode) AS NO_of_Unique_Products From [Online Retail];



-- customers Who have only made a single purchase

Select Distinct ([Online Retail].CustomerID) as Number_of_Customers, Count( [Online Retail].InvoiceNo) AS NO_Of_Invoices From [Online Retail]
Group by [Online Retail].CustomerID
Having Count( [Online Retail].InvoiceNo)='1';

With Number_Single_Purchasing_Individuals as(Select Distinct ([Online Retail].CustomerID) as Number_of_Customers, Count( [Online Retail].InvoiceNo) AS NO_Of_Invoices From [Online Retail]
Group by [Online Retail].CustomerID
Having Count( [Online Retail].InvoiceNo)='1')
Select Count(*) As NO_of_customers_who_have_a_single_purchase From Number_Single_Purchasing_Individuals;

-- products are most commonly purchased together?

-- top 10 customers by total spend.
With Expenditure AS (Select [Online Retail].CustomerID As Customers, ROUND(SUM(Cast (Quantity*UnitPrice As float)), 2)AS Total_Spend From [Online Retail]
Group by [Online Retail].CustomerID)
Select Top 10 Total_Spend ,Customers From Expenditure
Order by Total_Spend Desc;



--monthly revenue trend across the dataset
WITH MonthlyRevenue AS (
    SELECT 
        YEAR(InvoiceDate) AS SalesYear,
        MONTH(InvoiceDate) AS SalesMonth,
        ROUND(SUM(Quantity * UnitPrice), 2) AS Total_Revenue
    FROM [Online Retail]
    GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate)
)
SELECT 
    SalesYear,
    SalesMonth,
    Total_Revenue,
    LAG(Total_Revenue) OVER (ORDER BY SalesYear, SalesMonth) AS Prev_Revenue,
    CASE 
        WHEN LAG(Total_Revenue) OVER (ORDER BY SalesYear, SalesMonth) = 0 
             OR LAG(Total_Revenue) OVER (ORDER BY SalesYear, SalesMonth) IS NULL
        THEN NULL
        ELSE ROUND(
            ((Total_Revenue - LAG(Total_Revenue) OVER (ORDER BY SalesYear, SalesMonth)) * 100.0) 
            / LAG(Total_Revenue) OVER (ORDER BY SalesYear, SalesMonth),
            2
        )
    END AS MoM_Growth_Percent
FROM MonthlyRevenue
ORDER BY SalesYear, SalesMonth;


--Use a window function to rank customers by spend within each country.
Select SUM(Cast((Quantity * UnitPrice) as float)) As Gross_Spend, [Online Retail].Country From [Online Retail]
Group by [Online Retail].Country
Order by Gross_Spend desc;

--Identify the fastest growing products by revenue YoY.
WITH MonthlyRevenue AS (
    SELECT 
        YEAR(InvoiceDate) AS SalesYear,
        MONTH(InvoiceDate) AS SalesMonth,
        ROUND(SUM(Quantity * UnitPrice), 2) AS Total_Revenue,
		[Online Retail].Description AS Description
    FROM [Online Retail]
    GROUP BY [Online Retail].Description,YEAR(InvoiceDate), MONTH(InvoiceDate)
)
SELECT
    Description,
    SalesYear,
    SalesMonth,
    Total_Revenue,
    LAG(Total_Revenue) OVER (ORDER BY SalesYear, SalesMonth) AS Prev_Revenue,
    CASE 
        WHEN LAG(Total_Revenue) OVER (ORDER BY SalesYear, SalesMonth) = 0 
             OR LAG(Total_Revenue) OVER (ORDER BY SalesYear, SalesMonth) IS NULL
        THEN NULL
        ELSE ROUND(
            ((Total_Revenue - LAG(Total_Revenue) OVER (ORDER BY SalesYear, SalesMonth)) * 100.0) 
            / LAG(Total_Revenue) OVER (ORDER BY SalesYear, SalesMonth),
            2
        )
    END AS MoM_Growth_Percent
FROM MonthlyRevenue
ORDER BY Total_Revenue Desc;


--Identify product bundles (frequently purchased together) using SQL self-joins.

SELECT 
    A.Description AS Product_A,
    B.Description AS Product_B,
    COUNT(*) AS Times_Bought_Together
FROM [Online Retail] A
INNER JOIN [Online Retail] B
    ON A.InvoiceNo = B.InvoiceNo      -- same order
   AND A.CustomerID = B.CustomerID    -- same customer
   AND A.Description < B.Description  -- avoid self-join duplicates
WHERE A.Description IS NOT NULL
  AND B.Description IS NOT NULL
GROUP BY A.Description, B.Description
ORDER BY Times_Bought_Together DESC;
