---------------------------------------------------------------------------------------------
--Q1--BEGIN 


	SELECT DISTINCT State 
	FROM DIM_LOCATION AS D_LOC
		
		INNER JOIN FACT_TRANSACTIONS AS F_TRANS
		ON F_TRANS.IDLocation = D_LOC.IDLocation
		
		INNER JOIN DIM_DATE AS D_DATE
		ON F_TRANS.Date = D_DATE.DATE
			
			WHERE YEAR = 2005 OR YEAR > 2005


--Q1--END
---------------------------------------------------------------------------------------------
--Q2--BEGIN

	
	SELECT TOP 1 D_LOC.State, COUNT(*) AS Count_Orders 
	FROM DIM_LOCATION AS D_LOC
		
		INNER JOIN FACT_TRANSACTIONS AS F_TRANS
		ON F_TRANS.IDLocation = D_LOC.IDLocation
		
		INNER JOIN DIM_MODEL AS D_MODEL
		ON F_TRANS.IDModel = D_MODEL.IDModel

		INNER JOIN DIM_MANUFACTURER AS D_MANF
		ON D_MODEL.IDManufacturer = D_MANF.IDManufacturer

				WHERE D_LOC.Country = 'US' AND D_MANF.Manufacturer_Name = 'Samsung'
				GROUP BY D_LOC.State
				ORDER BY Count_Orders DESC

--Q2--END
---------------------------------------------------------------------------------------------
--Q3--BEGIN      
	
	SELECT	Model_Name, 
			COUNT(DISTINCT ZipCode) AS Zip_Code,
			COUNT(DISTINCT State) AS State 
	FROM FACT_TRANSACTIONS AS F_TRANS
		INNER JOIN DIM_MODEL AS D_MODEL
		ON F_TRANS.IDModel = D_MODEL.IDModel
		INNER JOIN DIM_LOCATION D_LOC
		ON D_LOC.IDLocation = F_TRANS.IDLocation
			GROUP BY Model_Name
			ORDER BY COUNT(DISTINCT State) DESC, COUNT(DISTINCT ZipCode) DESC

--Q3--END
---------------------------------------------------------------------------------------------
--Q4--BEGIN
		
	SELECT TOP 1 Model_Name, MIN(Unit_price) AS Price
	FROM DIM_MODEL AS D_MODEL 
			
			INNER JOIN FACT_TRANSACTIONS AS F_TRANS
			ON D_MODEL.IDModel = F_TRANS.IDModel 			
			GROUP BY Model_Name
			ORDER BY  MIN(Unit_price) ASC

--Q4--END
---------------------------------------------------------------------------------------------
--Q5--BEGIN
	
	SELECT DISTINCT D_MODEL.Model_Name, 
					AVG(TotalPrice) AS Avg_Price, 
					SUM(Quantity) AS Quantity 
	FROM FACT_TRANSACTIONS F_TRANS	
	INNER JOIN DIM_MODEL D_MODEL
	ON F_TRANS.IDModel=D_MODEL.IDModel
	INNER JOIN DIM_MANUFACTURER AS D_MANF
	ON D_MODEL.IDManufacturer = D_MANF.IDManufacturer
					WHERE Manufacturer_Name IN 
											(SELECT TOP 5 Manufacturer_Name FROM DIM_MANUFACTURER AS D_MANF
											INNER JOIN DIM_MODEL D_MODEL
											ON D_MANF.IDManufacturer=D_MODEL.IDManufacturer
											INNER JOIN FACT_TRANSACTIONS F_TRANS
											ON D_MODEL.IDModel=F_TRANS.IDModel
											GROUP BY Manufacturer_Name
											ORDER BY SUM(Quantity) DESC)
					GROUP BY D_MODEL.Model_Name
					ORDER BY Quantity DESC

--Q5--END
---------------------------------------------------------------------------------------------
--Q6--BEGIN

	SELECT Customer_Name, AVG(TotalPrice) FROM DIM_CUSTOMER AS D_CUS

	INNER JOIN FACT_TRANSACTIONS AS F_TRANS
	ON D_CUS.IDCustomer=F_TRANS.IDCustomer

	INNER JOIN DIM_DATE AS D_DATE
	ON F_TRANS.Date=D_DATE.DATE
	WHERE D_DATE.YEAR = 2009
	GROUP BY Customer_Name
	HAVING AVG(TotalPrice) > 500
	ORDER BY AVG(TotalPrice) DESC

--Q6--END
---------------------------------------------------------------------------------------------	
--Q7--BEGIN  

	SELECT Model_Name FROM(
	SELECT TOP 5 Model_Name, SUM(Quantity) AS SQ FROM FACT_TRANSACTIONS AS F_TRANS
	INNER JOIN DIM_MODEL AS D_MODEL
	ON F_TRANS.IDModel = D_MODEL.IDModel
	WHERE YEAR(Date) = 2008
	GROUP BY Model_Name
	ORDER BY SQ DESC) T1

	INTERSECT

	SELECT Model_Name FROM(
	SELECT TOP 6 Model_Name, SUM(Quantity) AS SQ FROM FACT_TRANSACTIONS AS F_TRANS
	INNER JOIN DIM_MODEL AS D_MODEL
	ON F_TRANS.IDModel = D_MODEL.IDModel
	WHERE YEAR(Date) = 2009
	GROUP BY Model_Name
	ORDER BY SQ DESC) T2

	INTERSECT

	SELECT Model_Name FROM(
	SELECT TOP 5 Model_Name, SUM(Quantity) AS SQ FROM FACT_TRANSACTIONS AS F_TRANS
	INNER JOIN DIM_MODEL AS D_MODEL
	ON F_TRANS.IDModel = D_MODEL.IDModel
	WHERE YEAR(Date) = 2010
	GROUP BY Model_Name
	ORDER BY SQ DESC) T3

--Q7--END
---------------------------------------------------------------------------------------------
--Q8--BEGIN

	SELECT * FROM
		(SELECT ROW_NUMBER() OVER(ORDER BY SUM(TotalPrice) DESC ) AS S_No,Manufacturer_Name, 
				SUM(TotalPrice) AS Sales, YEAR(Date) AS Year 
		FROM DIM_MANUFACTURER AS D_MANF
		INNER JOIN DIM_MODEL AS D_MODEL
		ON D_MANF.IDManufacturer = D_MODEL.IDManufacturer
		INNER JOIN FACT_TRANSACTIONS AS F_TRANS
		ON F_TRANS.IDModel = D_MODEL.IDModel
			WHERE YEAR(Date) = 2009
			GROUP BY Manufacturer_Name, YEAR(Date)
		) T1
	WHERE S_No = 2

	UNION

	SELECT * FROM
		(SELECT ROW_NUMBER() OVER(ORDER BY SUM(TotalPrice) DESC ) AS S_No,Manufacturer_Name, 
				SUM(TotalPrice) AS Sales, YEAR(Date) AS Year 
		FROM DIM_MANUFACTURER AS D_MANF
		INNER JOIN DIM_MODEL AS D_MODEL
		ON D_MANF.IDManufacturer = D_MODEL.IDManufacturer
		INNER JOIN FACT_TRANSACTIONS AS F_TRANS
		ON F_TRANS.IDModel = D_MODEL.IDModel
			WHERE YEAR(Date) = 2010
			GROUP BY Manufacturer_Name, YEAR(Date)
		) T2
	WHERE S_No = 2

--Q8--END
---------------------------------------------------------------------------------------------
--Q9--BEGIN
	
	SELECT Manufacturer_Name FROM DIM_MANUFACTURER AS D_MANF
	INNER JOIN DIM_MODEL AS D_MODEL
	ON D_MANF.IDManufacturer = D_MODEL.IDManufacturer
	INNER JOIN FACT_TRANSACTIONS AS F_TRANS
	ON F_TRANS.IDModel = D_MODEL.IDModel
		WHERE YEAR(Date) = 2010
		GROUP BY Manufacturer_Name

	EXCEPT

	SELECT Manufacturer_Name FROM DIM_MANUFACTURER AS D_MANF
	INNER JOIN DIM_MODEL AS D_MODEL
	ON D_MANF.IDManufacturer = D_MODEL.IDManufacturer
	INNER JOIN FACT_TRANSACTIONS AS F_TRANS
	ON F_TRANS.IDModel = D_MODEL.IDModel
		WHERE YEAR(Date) = 2009
		GROUP BY Manufacturer_Name

--Q9--END
---------------------------------------------------------------------------------------------
--Q10--BEGIN
	
	SELECT 
			T2.IDCustomer, Customer_Name, Sales_Year , Avg_P, Avg_Q,
			IIF(Lag_Price IS NULL, 'NA' , CONCAT(ROUND((Avg_P-Lag_Price)*100/Lag_Price, 2), '%')) as Percentage_Change
	FROM
	(SELECT *, LAG(Avg_P, 1) over(PARTITION BY T1.IDCustomer order by Sales_Year) as Lag_Price FROM
			(SELECT	IDCustomer, 
					Year(Date) Sales_Year, 
					AVG(TotalPrice) Avg_P, 
					AVG(Quantity) Avg_Q 
			FROM FACT_TRANSACTIONS AS F_TRANS
			WHERE IDCustomer IN (SELECT TOP 10 IDCustomer FROM FACT_TRANSACTIONS AS F_TRANS
								GROUP BY IDCustomer
								ORDER BY SUM(TotalPrice) DESC)
			GROUP BY IDCustomer, Year(Date)
			) as T1
	) AS T2
	inner join DIM_CUSTOMER AS D_CUS
	on T2.IDCustomer = D_CUS.IDCustomer

--Q10--END
---------------------------------------------------------------------------------------------	