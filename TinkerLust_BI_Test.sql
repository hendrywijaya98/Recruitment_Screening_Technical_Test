USE TinkerLust;

-- add foreign key on product to brand_details
ALTER TABLE Clean_Products ADD FOREIGN KEY (Brand_ID) REFERENCES Brand_Details(Brand_ID);
-- add foreign key on Order Item to Product product id
ALTER TABLE Order_Items ADD FOREIGN KEY (Product_ID) REFERENCES Clean_Products(product_id)
-- add foreign key on Order Item to Status status id
ALTER TABLE Order_Items ADD FOREIGN KEY (Status_ID) REFERENCES Order_Status(Status_ID);
-- add foreign key on Order Item to Orders order id
ALTER TABLE Order_Items ADD FOREIGN KEY (Order_ID) REFERENCES Clean_Orders(Order_ID);
-- add foreign key on Order Source to Orders order id
ALTER TABLE Order_Sources ADD FOREIGN KEY (Order_ID) REFERENCES Clean_Orders(Order_ID);

SELECT TOP 5 * FROM Brand_Details;
SELECT TOP 5 * FROM Order_Items;
SELECT TOP 5 * FROM Clean_Orders;
SELECT * FROM Order_Sources;
SELECT TOP 5 * FROM Clean_Products;

-- sales information from February - April 2019
SELECT DISTINCT YEAR(DATE) as Order_Year, MONTH(DATE) AS Order_Month 
FROM Order_Sources

-- Monthly Order Revenue (February - April), 
-- OrderSources.Date - Order_Items.Prices + Order_Items.Total_Price
SELECT YEAR(Order_Sources.Date) AS Order_Year, DATENAME(MONTH, Order_Sources.Date) AS Order_Month, 
SUM(Clean_Orders.Items) AS Order_Qty, SUM(CAST(Clean_Orders.Total_Price AS BIGINT)) AS Order_Rev
FROM Order_Items JOIN Order_Sources ON Order_Items.Order_ID = Order_Sources.Order_ID
JOIN Clean_Orders ON Order_Items.Order_ID = Clean_Orders.Order_ID
GROUP BY YEAR(Order_Sources.Date), DATENAME(MONTH, Order_Sources.Date)

SELECT YEAR(Order_Sources.Date) AS Order_Year, DATENAME(MONTH, Order_Sources.Date) AS Order_Month, 
Clean_Orders.Items, Order_Items.Price FROM Order_Items 
JOIN Order_Sources ON Order_Items.Order_ID = Order_Sources.Order_ID
JOIN Clean_Orders ON Order_Items.Order_ID = Clean_Orders.Order_ID

-- Most Favorite Product Category
-- Products.Category - Orders.Items + COUNT(Order_ID) + Count(Customer_ID)
-- Products.Sub_Category - Orders.Items + COUNT(Order_ID) + Count(Customer_ID)

SELECT Order_Products.Main_category, COUNT(DISTINCT Clean_Orders.Customer_ID) AS Total_Customers, 
COUNT(DISTINCT Clean_Orders.Order_ID) as Total_Orders, SUM(Clean_Orders.Items) as Total_Items, 
SUM(CAST(Clean_Orders.Total_Price AS bigint)) AS Total_Revenue
FROM Clean_Orders JOIN Order_Items ON Clean_Orders.Order_ID = Order_Items.Order_ID
JOIN (SELECT Order_Items.*, Clean_Products.gender, Clean_Products.Main_category, Clean_Products.category, 
Clean_Products.subcategory FROM Order_Items 
JOIN Clean_Products ON Order_Items.Product_ID = Clean_Products.Product_ID) AS Order_Products 
ON Clean_Orders.Order_ID = Order_Products.Order_ID GROUP BY Order_Products.Main_category

SELECT Order_Products.category, COUNT(DISTINCT Clean_Orders.Customer_ID) AS Total_Customers, 
COUNT(DISTINCT Clean_Orders.Order_ID) as Total_Orders, SUM(Clean_Orders.Items) as Total_Items, 
SUM(CAST(Clean_Orders.Total_Price AS bigint)) AS Total_Revenue
FROM Clean_Orders JOIN Order_Items ON Clean_Orders.Order_ID = Order_Items.Order_ID
JOIN (SELECT Order_Items.*, Clean_Products.gender, Clean_Products.Main_category, Clean_Products.category, 
Clean_Products.subcategory FROM Order_Items 
JOIN Clean_Products ON Order_Items.Product_ID = Clean_Products.Product_ID) AS Order_Products 
ON Clean_Orders.Order_ID = Order_Products.Order_ID GROUP BY Order_Products.category

SELECT Order_Products.subcategory, COUNT(DISTINCT Clean_Orders.Customer_ID) AS Total_Customers, 
COUNT(DISTINCT Clean_Orders.Order_ID) as Total_Orders, SUM(Clean_Orders.Items) as Total_Items, 
SUM(CAST(Clean_Orders.Total_Price AS bigint)) AS Total_Revenue
FROM Clean_Orders JOIN Order_Items ON Clean_Orders.Order_ID = Order_Items.Order_ID
JOIN (SELECT Order_Items.*, Clean_Products.gender, Clean_Products.Main_category, Clean_Products.category, 
Clean_Products.subcategory FROM Order_Items 
JOIN Clean_Products ON Order_Items.Product_ID = Clean_Products.Product_ID) AS Order_Products 
ON Clean_Orders.Order_ID = Order_Products.Order_ID GROUP BY Order_Products.subcategory

SELECT Order_Products.Main_category, Order_Products.category, Order_Products.subcategory, COUNT(DISTINCT Clean_Orders.Customer_ID) AS Total_Customers, 
COUNT(DISTINCT Clean_Orders.Order_ID) as Total_Orders, SUM(Clean_Orders.Items) as Total_Items, 
SUM(CAST(Clean_Orders.Total_Price AS bigint)) AS Total_Revenue
FROM Clean_Orders JOIN Order_Items ON Clean_Orders.Order_ID = Order_Items.Order_ID
JOIN (SELECT Order_Items.*, Clean_Products.gender, Clean_Products.Main_category, Clean_Products.category, 
Clean_Products.subcategory FROM Order_Items 
JOIN Clean_Products ON Order_Items.Product_ID = Clean_Products.Product_ID) AS Order_Products 
ON Clean_Orders.Order_ID = Order_Products.Order_ID 
GROUP BY Order_Products.Main_category, Order_Products.category, Order_Products.subcategory


-- Most Favorite Product Brand AND TOP BR
-- Brand_Product.Brand_Name - Clean_Orders.Items + COUNT(Clean_Orders.Order_ID) + Count(Clean_Orders.Customer_ID)
WITH Brand_Items AS (
SELECT Order_Items.*, Brand_Product.gender, Brand_Product.Brand_Name, Brand_Product.Main_category, 
Brand_Product.category,Brand_Product.subcategory, Clean_Orders.Customer_ID, Clean_Orders.City_Destination, 
Clean_Orders.Province_Destination, Clean_Orders.Items 
FROM Order_Items JOIN (SELECT Clean_Products.*, Brand_Details.Brand_Name FROM Clean_Products 
JOIN Brand_Details ON Clean_Products.Brand_ID = Brand_Details.Brand_ID) AS Brand_Product 
ON Order_Items.Product_ID = Brand_Product.Product_ID 
JOIN Clean_Orders ON Order_Items.Order_ID = Clean_Orders.Order_ID) 
SELECT Brand_Name, SUM(Items) AS Total_Items, COUNT(DISTINCT Order_ID) AS Total_Orders, 
COUNT(DISTINCT Customer_ID) AS Total_Customers FROM Brand_Items GROUP BY Brand_Name

-- Top Brand Revenue
-- Brand_Details.Brand_Name - Orders.Total_Price + Orders.Item
-- Brand_Details.Brand_Name - Orders.Item + COUNT(Orders.Order_ID)
WITH Brand_Revenue AS (
SELECT Order_Items.*, Brand_Product.gender, Brand_Product.Brand_Name, Brand_Product.Main_category, 
Brand_Product.category,Brand_Product.subcategory, Clean_Orders.Customer_ID, Clean_Orders.City_Destination, 
Clean_Orders.Province_Destination, Clean_Orders.Items 
FROM Order_Items JOIN (SELECT Clean_Products.*, Brand_Details.Brand_Name FROM Clean_Products 
JOIN Brand_Details ON Clean_Products.Brand_ID = Brand_Details.Brand_ID) AS Brand_Product 
ON Order_Items.Product_ID = Brand_Product.Product_ID 
JOIN Clean_Orders ON Order_Items.Order_ID = Clean_Orders.Order_ID) 
SELECT Brand_Name, SUM(Items) AS Total_Items, COUNT(DISTINCT Order_ID) AS Total_Orders, 
SUM(CAST(Price AS BIGINT)) AS Total_Revenue FROM Brand_Revenue GROUP BY Brand_Name


-- Brand with Status
-- Status + Brand - COUNT(Clean_Orders.Order_ID)
-- Status + Brand - Clean_Orders.Items
SELECT Product_Brand.Brand_Name, Order_Status.Status, SUM(Clean_Orders.Items) AS Total_Items, 
SUM(CAST(Order_Items.Price AS bigint)) AS Potential_Revenue FROM Order_Items JOIN Order_Status 
ON Order_Items.Status_ID = Order_Status.Status_ID JOIN (SELECT Clean_Products.*, Brand_Details.Brand_Name 
FROM Clean_Products JOIN Brand_Details ON Clean_Products.Brand_ID = Brand_Details.Brand_ID) AS Product_Brand 
ON Order_Items.Product_ID = Product_Brand.product_id JOIN Clean_Orders ON Order_Items.Order_ID = Clean_Orders.Order_ID
WHERE NOT Order_Status.Status IN('Cancelled', 'Refunded') GROUP BY Product_Brand.Brand_Name, Order_Status.Status 
ORDER BY Total_Items DESC

SELECT Product_Brand.Brand_Name, Order_Status.Status, SUM(Clean_Orders.Items) AS Total_Items, 
SUM(CAST(Order_Items.Price AS bigint)) AS Potential_Revenue FROM Order_Items JOIN Order_Status 
ON Order_Items.Status_ID = Order_Status.Status_ID JOIN (SELECT Clean_Products.*, Brand_Details.Brand_Name 
FROM Clean_Products JOIN Brand_Details ON Clean_Products.Brand_ID = Brand_Details.Brand_ID) AS Product_Brand 
ON Order_Items.Product_ID = Product_Brand.product_id JOIN Clean_Orders ON Order_Items.Order_ID = Clean_Orders.Order_ID
WHERE Order_Status.Status IN('Cancelled', 'Refunded') GROUP BY Product_Brand.Brand_Name, Order_Status.Status 
ORDER BY Total_Items DESC

-- Customer Demography - Gender, City, Domicile
-- Gender, Clean_Products.Gender - COUNT(Clean_Orders.Customer_ID)
SELECT Clean_Products.gender, COUNT(DISTINCT Product_Orders.Customer_ID) as Customers FROM Clean_Products JOIN Order_Items 
ON Clean_Products.Product_ID = Order_Items.Product_ID
JOIN (SELECT Order_Items.Product_ID, Clean_Orders.*,Order_Items.Price FROM Order_Items 
JOIN Clean_Orders ON Order_Items.Order_ID = Clean_Orders.Order_ID) AS Product_Orders 
ON Clean_Products.product_id = Product_Orders.Product_ID 
GROUP BY Clean_Products.gender

-- Domicile (Clean_Orders), Province - COUNT(Customer_ID), City - COUNT(Customer_ID)
SELECT Province_Destination, City_Destination, COUNT(Customer_ID) as Customers 
FROM Clean_Orders GROUP BY Province_Destination, City_Destination ORDER BY COUNT(Customer_ID) DESC

SELECT Province_Destination, COUNT(Customer_ID) as Customers FROM Clean_Orders 
GROUP BY Province_Destination ORDER BY COUNT(Customer_ID) DESC

-- In a single order, there can be more than 1 items
WITH Item_Sales_Ordered AS (
SELECT Clean_Orders.Order_ID, OrderStat.Status, Order_Items.Product_ID, Clean_Orders.Items, Order_Items.Price, 
Clean_Orders.Total_price FROM Clean_Orders JOIN Order_Items ON Clean_Orders.Order_ID = Order_Items.Order_ID 
JOIN (SELECT Order_Items.Order_ID,Order_Status.* FROM Order_Items JOIN Order_Status 
ON Order_Items.Status_ID = Order_Status.Status_ID) AS OrderStat ON Clean_Orders.Order_ID = OrderStat.Order_ID)
SELECT Order_ID, SUM(Items) Items_Ordered, SUM(Price) AS Orders_Total_Prices FROM Item_Sales_Ordered
GROUP BY Order_ID ORDER BY Items_Ordered DESC;

WITH Orders_Data AS (
SELECT Clean_Orders.Order_ID, OrderStat.Status, Order_Items.Product_ID, Clean_Orders.Items, Order_Items.Price, 
Clean_Orders.Total_price FROM Clean_Orders JOIN Order_Items ON Clean_Orders.Order_ID = Order_Items.Order_ID 
JOIN (SELECT Order_Items.Order_ID,Order_Status.* FROM Order_Items JOIN Order_Status 
ON Order_Items.Status_ID = Order_Status.Status_ID) AS OrderStat ON Clean_Orders.Order_ID = OrderStat.Order_ID)
SELECT * FROM Orders_Data;

-- The order with no marketing channel information on sales source goes to "Others"
WITH Sales_Marketing_Channel AS (
SELECT Clean_Orders.Order_ID, Clean_Orders.Order_Created, Clean_Orders.Customer_ID, Clean_Orders.Items, 
OrderStat.Price, Order_Sources.Date, Order_Sources.Source, OrderStat.Status 
FROM Clean_Orders JOIN Order_Sources ON Clean_Orders.Order_ID = Order_Sources.Order_ID
JOIN (SELECT Order_Items.Order_ID, Order_Items.Price, Order_Status.* FROM Order_Items JOIN Order_Status 
ON Order_Items.Status_ID = Order_Status.Status_ID) AS OrderStat ON Clean_Orders.Order_ID = OrderStat.Order_ID) 
SELECT Source, COUNT(Order_ID) AS Orders_Number, SUM(Items) as Total_Items, SUM(Price) AS Total_Revenue 
FROM Sales_Marketing_Channel GROUP BY Source;

SELECT Clean_Orders.Order_ID, Clean_Orders.Order_Created, Clean_Orders.Customer_ID, 
Clean_Orders.Province_Destination, Clean_Orders.City_Destination, Clean_Orders.Items, 
OrderStat.Price, Order_Sources.Date, Order_Sources.Source, OrderStat.Status 
FROM Clean_Orders JOIN Order_Sources ON Clean_Orders.Order_ID = Order_Sources.Order_ID
JOIN (SELECT Order_Items.Order_ID, Order_Items.Price ,Order_Status.* FROM Order_Items JOIN Order_Status 
ON Order_Items.Status_ID = Order_Status.Status_ID) AS OrderStat ON Clean_Orders.Order_ID = OrderStat.Order_ID; 

-- The Item ID is unique. If an item has been ordered and the status is cancelled, then it can be ordered again.
SELECT Order_Status.Status, Clean_Orders.Order_ID, Clean_Orders.Customer_ID, Clean_Orders.City_Destination, 
Clean_Orders.Province_Destination, Clean_Orders.Items, Clean_Orders.Total_Price 
FROM Order_Items JOIN Clean_Orders ON Order_Items.Order_ID = Clean_Orders.Order_ID 
JOIN Order_Status ON Order_Items.Status_ID = Order_Status.Status_ID

SELECT Order_Status.Status, COUNT(Clean_Orders.Order_ID) AS Total_Orders, SUM(Clean_Orders.Items) AS Order_Qty 
FROM Order_Items JOIN Clean_Orders ON Order_Items.Order_ID = Clean_Orders.Order_ID 
JOIN Order_Status ON Order_Items.Status_ID = Order_Status.Status_ID
GROUP BY Order_Status.Status 

-- Count the number of completed items per day
SELECT DATENAME(WEEKDAY, DAY(Clean_Orders.Order_Created)) AS Day_Order, SUM(Clean_Orders.Items) as Total_Items 
FROM Order_Items JOIN (SELECT * FROM Order_Status WHERE Status = 'Completed') AS Order_Complete 
ON Order_Items.Status_ID = Order_Complete.Status_ID 
JOIN Clean_Orders ON Order_Items.Order_ID  = Clean_Orders.Order_ID
GROUP BY DAY(Clean_Orders.Order_Created)

-- Percentage of customers who made completed order more than one.
SELECT CAST(COUNT(Customer_ID) AS FLOAT)/
		CAST((SELECT COUNT(Customer_ID) AS Total_Customers FROM (SELECT Clean_Orders.Customer_ID, 
		COUNT(Clean_Orders.Order_ID) AS Total_Orders FROM Order_Items 
JOIN Order_Status ON Order_Items.Status_ID = Order_Status.Status_ID 
JOIN Clean_Orders ON Order_Items.Order_ID  = Clean_Orders.Order_ID GROUP BY Clean_Orders.Customer_ID) AS FLOAT) 
FROM (SELECT Clean_Orders.Customer_ID, COUNT(Clean_Orders.Order_ID) AS Total_Orders FROM Order_Items 
JOIN Order_Status ON Order_Items.Status_ID = Order_Status.Status_ID 
JOIN Clean_Orders ON Order_Items.Order_ID  = Clean_Orders.Order_ID 
WHERE Status = 'Completed' GROUP BY Clean_Orders.Customer_ID HAVING COUNT(Clean_Orders.Order_ID) > 1) 

-- 912 Customers
SELECT COUNT(Customer_ID) AS Total_Customers FROM (SELECT Clean_Orders.Customer_ID, 
COUNT(Clean_Orders.Order_ID) AS Total_Orders FROM Order_Items 
JOIN Order_Status ON Order_Items.Status_ID = Order_Status.Status_ID 
JOIN Clean_Orders ON Order_Items.Order_ID  = Clean_Orders.Order_ID 
WHERE Status = 'Completed' GROUP BY Clean_Orders.Customer_ID HAVING 
COUNT(Clean_Orders.Order_ID) > 1) AS Complete_Than_one

-- 1821 Customers
SELECT COUNT(Customer_ID) AS Total_Customers FROM (SELECT Clean_Orders.Customer_ID, 
COUNT(Clean_Orders.Order_ID) AS Total_Orders FROM Order_Items 
JOIN Order_Status ON Order_Items.Status_ID = Order_Status.Status_ID 
JOIN Clean_Orders ON Order_Items.Order_ID  = Clean_Orders.Order_ID 
GROUP BY Clean_Orders.Customer_ID) AS Entire_Customers

SELECT ROUND((CAST(912 AS FLOAT)/CAST(1821 AS FLOAT)*100),2) AS Customer_Percentage
