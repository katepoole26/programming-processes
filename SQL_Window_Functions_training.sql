/************************************************
purpose: SQL window functions training script
created by: K Poole
created on: 4/24/2022
************************************************/

-------------------------------------
use  [enter db name]
-------------------------------------


--tables to use
  select top 100 * from partitions.sdud_nm_ms_2000_2002 
  select top 100 * from partitions.sdud_nm_ms_2000_2002_subset
  

/*============================================================
  example #1
  calculate total spend by drug using group by 
==============================================================*/
/*
NDC, National Drug Code 
It is a universal product identifier for human drugs in the United States. 
The code is present on all nonprescription (OTC) and prescription medication packages and inserts in the US.
*/

  select state, ndc, product_name
    ,sum(Total_Amount_Reimbursed) reimb_amt_ndc
  from partitions.sdud_nm_ms_2000_2002_subset
  group by state, ndc, product_name
  order by 1,2 

  select *  
    ,sum(Total_Amount_Reimbursed) over (partition by state, ndc, product_name) reimb_amt_ndc
  from partitions.sdud_nm_ms_2000_2002_subset

  select *  
    ,sum(Total_Amount_Reimbursed) over (partition by state, ndc, product_name) reimb_amt_ndc
	,Total_Amount_Reimbursed/sum(Total_Amount_Reimbursed) over (partition by state, ndc, product_name) perc_of_reimb_amt_ndc
	,CAST(Total_Amount_Reimbursed/sum(Total_Amount_Reimbursed) over (partition by state, ndc, product_name) AS DECIMAL(3,2)) perc_of_reimb_amt_ndc_Rounded
  from partitions.sdud_nm_ms_2000_2002_subset

/*============================================================
  example #2
  goal: count ncd quarters in period and sum spend 
==============================================================*/

	SELECT TOP 10* FROM [partitions].[sdud_nm_ms_2000_2002]
	
	SELECT NDC, State, COUNT(DISTINCT Quarter), SUM(Total_Amount_Reimbursed)
	FROM [partitions].[sdud_nm_ms_2000_2002]
	GROUP BY NDC, State
	
	SELECT NDC, State, Year, Quarter_Begin_Date, 
	Quarter, 
	COUNT(Quarter) over(partition by NDC, State) AS Quarter_Count, 
	Total_Amount_Reimbursed,
	SUM(Total_Amount_Reimbursed) over(partition by NDC, State) AS NDC_State_Total_Amount_Reimbursed
	FROM [partitions].[sdud_nm_ms_2000_2002]
	ORDER BY NDC, State, Quarter_Begin_Date

/*==========================================================
  exercise #2
  find min and max quarters for each ndc/state
===========================================================*/

	SELECT TOP 10* FROM [partitions].[sdud_nm_ms_2000_2002]
	
	SELECT NDC, State,
	MIN(Quarter_Begin_Date) as Min_Quarter,
	MAX(Quarter_Begin_Date) as Max_Quarter
	FROM [partitions].[sdud_nm_ms_2000_2002]
	GROUP BY NDC, State
	ORDER BY NDC, State
	
	SELECT NDC, State, Year, Quarter_Begin_Date, 
	Quarter, 
	MIN(Quarter_Begin_Date) over(partition by NDC, State) as Min_Quarter,
	MAX(Quarter_Begin_Date) over(partition by NDC, State) as Max_Quarter
	FROM [partitions].[sdud_nm_ms_2000_2002]
	ORDER BY NDC, State, Quarter_Begin_Date

/*==========================================================
  << ranks examples >>
===========================================================*/
	--1) SHOW USES OF ALL THREE RANKING FUNCTIONS
	SELECT STATE, NDC, YEAR, TOTAL_AMOUNT_REIMBURSED
	FROM [partitions].[sdud_nm_ms_2000_2002]
	WHERE NDC='00517460525' AND year=2001
	ORDER BY TOTAL_AMOUNT_REIMBURSED DESC
	
	SELECT STATE, NDC, YEAR, TOTAL_AMOUNT_REIMBURSED,
			 RANK() OVER(PARTITION BY STATE, NDC, YEAR ORDER BY TOTAL_AMOUNT_REIMBURSED DESC) AS _RANK,
			 DENSE_RANK() OVER(PARTITION BY STATE, NDC, YEAR ORDER BY TOTAL_AMOUNT_REIMBURSED DESC) AS _DENSE_RANK,
			 ROW_NUMBER() OVER(PARTITION BY STATE, NDC, YEAR ORDER BY TOTAL_AMOUNT_REIMBURSED DESC) AS _ROW_NUMBER
	FROM [partitions].[sdud_nm_ms_2000_2002]
	ORDER BY STATE, NDC ASC, YEAR ASC, TOTAL_AMOUNT_REIMBURSED DESC
	
	DROP TABLE #RANK
	SELECT *, 
			 RANK() OVER(PARTITION BY STATE, NDC, YEAR ORDER BY TOTAL_AMOUNT_REIMBURSED DESC) AS _RANK,
			 DENSE_RANK() OVER(PARTITION BY STATE, NDC, YEAR ORDER BY TOTAL_AMOUNT_REIMBURSED DESC) AS _DENSE_RANK,
			 ROW_NUMBER() OVER(PARTITION BY STATE, NDC, YEAR ORDER BY TOTAL_AMOUNT_REIMBURSED DESC) AS _ROW_NUMBER
	INTO #RANK
	FROM [partitions].[sdud_nm_ms_2000_2002]
	--(226934 row(s) affected)
	--00:00:01
	--SELECT DISTINCT NDC FROM #RANK

		--REPORT OUT TABLE
		SELECT STATE, NDC, YEAR, QUARTER, TOTAL_AMOUNT_REIMBURSED, _RANK, _DENSE_RANK, _ROW_NUMBER FROM #RANK 
		WHERE NDC='00517460525' AND year=2001


	--2) ROW_NUMBER: TOP 5 DRUGS WITH MOST PRESCRIPTIONS DISPENSED IN Q1 2002
	DROP TABLE #RX_DISP
	SELECT *,
		ROW_NUMBER() OVER(PARTITION BY YEAR, QUARTER ORDER BY NUMBER_OF_PRESCRIPTIONS DESC) AS RANKING
	INTO #RX_DISP
	FROM [partitions].[sdud_nm_ms_2000_2002]
	--(226934 row(s) affected)
	--SELECT TOP 100 * FROM #REIMBURSEMENT 
	--SELECT DISTINCT YEAR FROM #REIMBURSEMENT

		--Output
		SELECT * FROM #RX_DISP WHERE RANKING BETWEEN 1 AND 5 AND YEAR=2002 AND QUARTER=1

	--3) RANK: IN Q3 2000, WHAT RANK IS METHOTREXATE (NDC 00378001401)
	DROP TABLE #METHOTREXATE_RANK
	SELECT *,
		RANK() OVER(PARTITION BY YEAR, QUARTER, STATE ORDER BY NUMBER_OF_PRESCRIPTIONS DESC) AS RANKING
	INTO #METHOTREXATE_RANK
	FROM [partitions].[sdud_nm_ms_2000_2002]
	--(226934 row(s) affected)

		--Output
		SELECT * FROM #METHOTREXATE_RANK WHERE YEAR=2000 AND QUARTER=3 AND STATE='NM' /*AND NDC='00378001401'*/ ORDER BY RANKING --8495

		SELECT COUNT(1) FROM #METHOTREXATE_RANK WHERE YEAR=2000 AND QUARTER=3 AND STATE='NM' AND RANKING BETWEEN 1 AND 664 --665
		SELECT RANKING, COUNT(1) FROM #METHOTREXATE_RANK WHERE YEAR=2000 AND QUARTER=3 AND STATE='NM' GROUP BY RANKING HAVING COUNT(1) > 1 ORDER BY 1
			SELECT * FROM #METHOTREXATE_RANK WHERE YEAR=2000 AND QUARTER=3 AND STATE='NM' AND RANKING=11
			SELECT * FROM #METHOTREXATE_RANK WHERE YEAR=2000 AND QUARTER=3 AND STATE='NM' AND RANKING <= 13 ORDER BY RANKING


	--4) DENSE RANK: IDENTIFY QUARTER WITH 8TH HIGHEST VOLUME OF RX DISPENSED FOR COUMADIN BETWEEN 2000 AND 2002
	DROP TABLE #COUMADIN
	SELECT *,
		DENSE_RANK() OVER(PARTITION BY NDC, STATE ORDER BY NUMBER_OF_PRESCRIPTIONS DESC) AS RANKING
	INTO #COUMADIN
	FROM [partitions].[sdud_nm_ms_2000_2002]
	--(226934 row(s) affected)

		--Output
		SELECT * FROM #COUMADIN WHERE NDC='00002808501' ORDER BY RANKING
		SELECT * FROM #COUMADIN WHERE NDC='00002808501' AND RANKING=8


	/*
	--ROLL UP THE DATA TO A YEARLY LEVEL
	-- drop table partitions.sdud_nm_ms_2000_2002_subset_2
	SELECT YEAR, QUARTER, SUM(TOTAL_AMOUNT_REIMBURSED) AS TOTAL_AMOUNT_REIMBURSED
	INTO partitions.sdud_nm_ms_2000_2002_subset_2
	FROM [partitions].[sdud_nm_ms_2000_2002]
	GROUP BY YEAR, QUARTER
	--(12 row(s) affected)
	--SELECT * FROM partitions.sdud_nm_ms_2000_2002_subset_MAM ORDER BY 3 DESC

	--RUN UPDATE STATEMENT TO FORCE A TIE
	UPDATE partitions.sdud_nm_ms_2000_2002_subset_2
	SET TOTAL_AMOUNT_REIMBURSED = 152311264.93000
	WHERE YEAR=2002 AND QUARTER=1
	--(1 row(s) affected)
	--SELECT * FROM partitions.sdud_nm_ms_2000_2002_subset_MAM ORDER BY 3 DESC
	*/


	--5) RANK & DENSE RANK EXAMPLE: TOP 3 DOLLAR AMTS VS. TOP 3 YEAR/QUARTERS
	select top 100 * from partitions.sdud_nm_ms_2000_2002_subset_2
	ORDER BY TOTAL_AMOUNT_REIMBURSED DESC
	
	/*
	UPDATE partitions.sdud_nm_ms_2000_2002_subset_2
	SET TOTAL_AMOUNT_REIMBURSED = '152427454.190'
	WHERE YEAR = '2002' AND QUARTER = '1' AND TOTAL_AMOUNT_REIMBURSED = '152311264.930'
	*/

	--A.TOP 5 QUARTERS
	SELECT
	YEAR, QUARTER, TOTAL_AMOUNT_REIMBURSED, 
	RANK() OVER(ORDER BY TOTAL_AMOUNT_REIMBURSED DESC) AS RANKING
	FROM partitions.sdud_nm_ms_2000_2002_subset_2

	--B.TOP 5 DOLLAR AMTS
	SELECT
	YEAR, QUARTER, TOTAL_AMOUNT_REIMBURSED, 
	DENSE_RANK() OVER(ORDER BY TOTAL_AMOUNT_REIMBURSED DESC) AS RANKING
	FROM partitions.sdud_nm_ms_2000_2002_subset_2
	
/*==========================================================
  example #4:
  calculate price increase quarter over quarter
===========================================================*/

  SELECT TOP 10* FROM partitions.sdud_nm_ms_2000_2002_subset
  
  drop table #e4
  select *
    ,rank() over (partition by state, ndc order by year, quarter) as date_rank
  into #e4
  from partitions.sdud_nm_ms_2000_2002_subset
  create clustered index pkey on #e4 (state, ndc, year, quarter)
  

  select a.* 
    ,b.date_rank   as prev_qtr_rank
    ,b.Total_Amount_Reimbursed as prev_qtr_spend
  from #e4 a
  left join #e4 b on 
    a.ndc = b.ndc 
    and a.state  = b.state
    and b.date_rank = a.date_rank - 1
  

/*==================================================================================================
  exercise #4:
  note that some records have NULL reimbursement 
  fill in these records where necessary using the reimbursement from the previous two quarters
==================================================================================================*/

  select * from partitions.sdud_nm_ms_2000_2002


	--table for you to use
  drop table #y4
  select *
    ,rank() over (partition by state, ndc order by year, quarter) as date_rank
  into #y4
  from partitions.sdud_nm_ms_2000_2002
  create clustered index pkey on #y4 (state, ndc, year, quarter)
  /*
  A clustered index stores data rows in a sorted structure based on its key values. 
  Each table has only one clustered index because data rows can be only sorted in one order.
  */
  --(226934 row(s) affected)

  SELECT State, NDC, YEAR, QUARTER, Total_Amount_Reimbursed, date_rank
  FROM #y4
  WHERE State = 'MS'
  AND NDC = '00002513687'
  ORDER BY State, NDC, YEAR, QUARTER, Total_Amount_Reimbursed 

  --hint: you probably want to use the coalesce() function
  --coalesce will return the first non-NULL value in a table
  SELECT COALESCE(NULL, NULL, 'a', NULL, 'b')

    select coalesce('current spend', 'prev_qtr_spend', 'prev_prev_qtr_spend')  union all
    select coalesce(null,            'prev_qtr_spend', 'prev_prev_qtr_spend') union all
    select coalesce(null,             null,            'prev_prev_qtr_spend')
    
	--Example of NDC 00002513687 in MS
	select 
	a.State
	,a.NDC
	,a.YEAR
	,a.QUARTER
	,a.date_rank
    ,a.Total_Amount_Reimbursed
    ,b.date_rank   as prev_qtr_rank
    ,b.Total_Amount_Reimbursed as prev_qtr_spend
	,c.date_rank   as prev_prev_qtr_rank
	,c.Total_Amount_Reimbursed as prev_prev_qtr_spend
	,COALESCE(a.Total_Amount_Reimbursed, b.Total_Amount_Reimbursed, c.Total_Amount_Reimbursed) AS If_NULL_Use_Previous_Quarter
  from #y4 a
  left join #y4 b on 
    a.ndc = b.ndc 
    and a.state  = b.state
    and b.date_rank = a.date_rank - 1
  left join #y4 c on 
    a.ndc = c.ndc 
    and a.state  = c.state
    and c.date_rank = a.date_rank - 2 
  WHERE a.State = 'MS'
  AND a.NDC = '00002513687'
  
  --So how does this affect the process of riding NULL values past the second quarter of 2002?
  --What might one do to remedy that null situation?
	
  
/*==================================================================================================
  example #5:
  calculate previous & next quarter's reimbursement using lag & lead 
==================================================================================================*/

	SELECT State, NDC, Year, Quarter, Total_Amount_Reimbursed
	FROM #y4
	WHERE State = 'MS'
	AND NDC = '00002513687'
	ORDER BY State, NDC, YEAR, QUARTER, Total_Amount_Reimbursed 

	SELECT State, NDC, Year, Quarter, Total_Amount_Reimbursed,
	LAG(Total_Amount_Reimbursed, 1) over (partition by State, NDC order by Year, Quarter) AS LAG,
	LEAD(Total_Amount_Reimbursed, 1) over (partition by State, NDC order by Year, Quarter) AS LEAD
	FROM #y4
	WHERE State = 'MS'
	AND NDC = '00002513687'
	ORDER BY State, NDC, YEAR, QUARTER, Total_Amount_Reimbursed 

	SELECT State, NDC, Year, Quarter, Total_Amount_Reimbursed,
	LAG(Total_Amount_Reimbursed, 1) over (partition by State, NDC order by Year, Quarter) AS prev_qtr_spend,
	LAG(Total_Amount_Reimbursed, 2) over (partition by State, NDC order by Year, Quarter) AS prev_prev_qtr_spend,
	COALESCE(
		Total_Amount_Reimbursed,
		LAG(Total_Amount_Reimbursed, 1) over (partition by State, NDC order by Year, Quarter),
		LAG(Total_Amount_Reimbursed, 2) over (partition by State, NDC order by Year, Quarter)
	) AS If_NULL_Use_Previous_Quarter
	FROM #y4
	WHERE State = 'MS'
	AND NDC = '00002513687'
	ORDER BY State, NDC, YEAR, QUARTER, Total_Amount_Reimbursed 
