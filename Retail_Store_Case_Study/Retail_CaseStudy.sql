
												--DATA PREPARATION AND UNDERSTANDING--
----------------------------------------------------------------------------------------------------------------------------------------

--1. What is the total number of rows in each of the 3 tables in the database? 

SELECT count(*) as trans_count FROM Transactions
--ANSWER : 23053 transactions were done
SELECT count(*) as p_info_count FROM product_info
--ANSWER : 23 are the product count
SELECT count(*) as Cus_count FROM Customer
--ANSWER : 5647 are the total number of customers

----------------------------------------------------------------------------------------------------------------------------------------

--2. What is the total number of transactions that have a return? 
--ANSWER: Total number of return orders are 6627.

SELECT	SUM(CAST(Qty AS int)) AS Return_Count FROM Transactions as trans
WHERE	Qty<0

----------------------------------------------------------------------------------------------------------------------------------------

/*3. As you would have noticed, the dates provided across the datasets are not in a correct format. 
As first steps, pls convert the date variables into valid date formats before proceeding ahead.*/

SELECT convert(date, DOB, 105) FROM Customer
SELECT convert(date, tran_date, 105) FROM Transactions

----------------------------------------------------------------------------------------------------------------------------------------

--4. What is the time range of the transaction data available for analysis? 
--Show the output in number of days, months and years simultaneously in different columns. 
SELECT DATEDIFF(DAY,	MIN(convert(date, tran_date, 105)), MAX(convert(date, tran_date, 105))) FROM Transactions as trans
SELECT DATEDIFF(MONTH,	MIN(convert(date, tran_date, 105)), MAX(convert(date, tran_date, 105))) FROM Transactions as trans
SELECT DATEDIFF(YEAR,	MIN(convert(date, tran_date, 105)), MAX(convert(date, tran_date, 105))) FROM Transactions as trans

----------------------------------------------------------------------------------------------------------------------------------------

--5. Which product category does the sub-category “DIY” belong to?
--ANSWER: Books
SELECT prod_cat 
FROM product_info as p_info
		WHERE prod_subcat = 'DIY'


-------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------
														--Data Analysis--		
-------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------
--1. Which channel is most frequently used for transactions? 
--ANSWER: The 'e-Shop' is the most frequently used for transactions

SELECT	TOP 1 Store_type AS Channel, 
		COUNT(*) AS Count_Channel 
FROM Transactions as trans
		GROUP BY Store_type
		ORDER BY COUNT(*) DESC
-------------------------------------------------------------------------------------------------------------------------------------
--2. What is the count of Male and Female customers in the database? 
--ANSWER: Male are 2892 and Female are 2753

SELECT	Gender, 
		COUNT(Gender) as Gender_Count 
FROM Customer as Cus
		WHERE Gender = 'M' OR Gender = 'F'
		GROUP BY Gender
		ORDER BY COUNT(Gender)

-------------------------------------------------------------------------------------------------------------------------------------

--3. From which city do we have the maximum number of customers and how many? 
--ANSWER: City with city_code '4' has maxmimum number of customers

SELECT	TOP 1 city_code,
		COUNT(*) AS city_count
FROM Customer as Cus
		INNER JOIN Transactions as trans
		ON Cus.customer_Id = trans.cust_id
		WHERE city_code != ' '
		GROUP BY city_code
		ORDER BY COUNT(*) DESC

-------------------------------------------------------------------------------------------------------------------------------------
--4. How many sub-categories are there under the Books category? 
--ANSWER: There are total 6 sub-categories are there under the Books category.

SELECT	prod_cat, 
		COUNT(prod_subcat) 
		AS Count_subcat 
FROM product_info as p_info
		WHERE prod_cat = 'Books'
		GROUP BY prod_cat
		ORDER BY COUNT(prod_subcat)

-------------------------------------------------------------------------------------------------------------------------------------
--5. What is the maximum quantity of products ever ordered? 
--ANSWER: 5 is the maximum quantity of products ever ordered.

SELECT * FROM Transactions as trans
		 WHERE Qty IN (SELECT MAX(Qty) FROM Transactions as trans)

-------------------------------------------------------------------------------------------------------------------------------------
--6. What is the net total revenue generated in categories Electronics and Books? 

SELECT	SUM(CAST(total_amt AS float)) 
		AS Total_Revenue 
FROM Transactions as trans
		INNER JOIN product_info as p_info
		ON p_info.prod_cat_code = trans.prod_cat_code
		WHERE prod_cat IN ('Electronics', 'Books')

-------------------------------------------------------------------------------------------------------------------------------------
--7. How many customers have >10 transactions with us, excluding returns? 

SELECT	COUNT(DISTINCT cust_id) 
		AS Cust_no 
FROM Transactions as trans
		WHERE Qty > 0 
		AND 
		(SELECT DISTINCT COUNT(*) FROM Transactions as trans) > 10

-------------------------------------------------------------------------------------------------------------------------------------
--8. What is the combined revenue earned from the “Electronics” & “Clothing” categories, from “Flagship stores”? 

SELECT	SUM(CAST(total_amt AS float)) AS Total_Revenue 
FROM Transactions as trans
		INNER JOIN product_info as p_info
		ON p_info.prod_cat_code = trans.prod_cat_code
		WHERE prod_cat = 'Electronics' OR prod_cat = 'Clothing' AND Store_type = 'Flagship stores'

-------------------------------------------------------------------------------------------------------------------------------------
/*9. What is the total revenue generated from “Male” customers in “Electronics” category? Output should display 
total revenue by prod sub-cat. */

SELECT	SUM(CAST(total_amt AS float)) 
		AS Total_Revenue 
FROM Transactions as trans
		INNER JOIN Customer as Cus
		ON trans.cust_id = Cus.customer_Id
		INNER JOIN product_info as p_info
		ON trans.prod_cat_code = p_info.prod_cat_code
	WHERE prod_cat = 'Electronics' AND Gender = 'M'

-------------------------------------------------------------------------------------------------------------------------------------
--10.What is percentage of sales and returns by product sub category; display only top 5 sub categories in terms of sales? 

SELECT TOP 5 RP.prod_subcat_code, Return_Percent, Sales_Percent FROM
		-- Return Percentage--
		(SELECT	prod_subcat_code, 
				CONCAT(ROUND(SUM(CAST(Qty AS float)*100)/(SELECT ROUND(SUM(CAST(ABS(Qty) AS float)), 2) FROM Transactions), 2), '%') 
				AS Return_Percent 
		FROM Transactions as trans
				WHERE Qty < 0
				GROUP BY prod_subcat_code) AS RP
JOIN
	--Sales Percentage--
		(SELECT	prod_subcat_code, 
				ROUND(SUM(CAST(total_amt AS float)*100)/(SELECT ROUND(SUM(CAST(total_amt AS float)), 2) FROM Transactions), 2) 
				AS Sales_Percent 
		FROM Transactions as trans
				GROUP BY prod_subcat_code) AS SP

ON RP.prod_subcat_code = SP.prod_subcat_code
ORDER BY Sales_Percent desc

-------------------------------------------------------------------------------------------------------------------------------------
/*11. For all customers aged between 25 to 35 years find what is the net total revenue generated by these 
consumers in last 30 days of transactions from max transaction date available in the data?*/

SELECT SUM(cast(total_amt as FLOAT)) AS Total_Revenue 
FROM
(SELECT *, YEAR(MAX_DATE) - YEAR(convert(date, DOB, 105)) AS AGE 
			FROM
				(SELECT *, MAX(convert(date, tran_date, 105)) OVER () as MAX_DATE 
				FROM Transactions as T
				INNER JOIN Customer AS C
				ON T.cust_id = C.customer_Id)
				AS T) 
AS T2
WHERE AGE BETWEEN 25 AND 35 AND 
convert(date, tran_date, 105) >= DATEADD(day, -30, MAX_DATE)

-------------------------------------------------------------------------------------------------------------------------------------
--12.Which product category has seen the max value of returns in the last 3 months of transactions? 

SELECT MIN(CAST(total_amt AS float)) FROM
(SELECT *, MAX(convert(date, tran_date, 105)) OVER () as MAX_DATE 
			FROM Transactions as T
			INNER JOIN Customer AS C
			ON T.cust_id = C.customer_Id)  as T 
WHERE 
convert(date, tran_date, 105) >= DATEADD(MONTH, -3, MAX_DATE) AND
CAST(total_amt AS float) < 0

-------------------------------------------------------------------------------------------------------------------------------------
--13.Which store-type sells the maximum products; by value of sales amount and by quantity sold? 

SELECT	TOP 1 Store_type, 
		SUM(CAST(Qty AS float)) AS Total_Qty, 
		SUM(CAST(total_amt AS float)) AS Total_Sales 
FROM Transactions as trans
GROUP BY Store_type
ORDER BY Total_Qty DESC, Total_Sales DESC

-------------------------------------------------------------------------------------------------------------------------------------
--14.What are the categories for which average revenue is above the overall average. 

SELECT * FROM	
(SELECT	prod_cat, AVG(CAST(total_amt AS float)) 
		AS Avg_Revenue 
		FROM Transactions as trans
		INNER JOIN product_info as p_info
		ON trans.prod_cat_code = p_info.prod_cat_code
		GROUP BY prod_cat)
	 AS Table1
WHERE Avg_Revenue > (SELECT AVG(CAST(total_amt AS float)) FROM Transactions)
ORDER BY Avg_Revenue DESC

-------------------------------------------------------------------------------------------------------------------------------------
/*15. Find the average and total revenue by each subcategory for the categories which are among 
top 5 categories in terms of quantity sold.*/

SELECT prod_cat, prod_subcat, Avg_Revenue, Total_Revenue FROM
(SELECT TOP 5 trans.prod_cat_code, prod_cat, 
			SUM(CAST(Qty AS float)) AS Avg_Quantity 
			FROM Transactions as trans
			INNER JOIN product_info as p_info
			ON trans.prod_cat_code = p_info.prod_cat_code
			GROUP BY trans.prod_cat_code, prod_cat
			ORDER BY Avg_Quantity DESC) 
		AS T1
JOIN 
(SELECT * FROM 
(SELECT	T.prod_cat_code, 
			prod_subcat, 
			ROUND(AVG(CAST(total_amt AS float)), 2) AS Avg_Revenue, 
			ROUND(SUM(CAST(total_amt AS float)), 2) AS Total_Revenue 
			FROM Transactions t
			INNER JOIN product_info as p_info
			ON T.prod_subcat_code = p_info.prod_sub_cat_code
			GROUP BY T.prod_cat_code, prod_subcat) AS TABLE_2) 
		AS T2

ON T1.prod_cat_code = T2.prod_cat_code

ORDER BY prod_cat

-------------------------------------------------------------------------------------------------------------------------------------