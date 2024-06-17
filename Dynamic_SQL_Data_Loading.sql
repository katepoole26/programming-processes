/***************************************

Dynamic SQL 
CREATED BY : K Poole
CREATED DATE : 2/28/2017

****************************************/

USE [enter db name]

--====================================================
--Variables in SQL
--====================================================

DECLARE @ITERATE INT
SET @ITERATE = 1
PRINT @ITERATE
--1

SET @ITERATE = @ITERATE + 1
PRINT @ITERATE
--2

GO

--====================================================
--List All Integers 1 - 10
--====================================================

DECLARE @ITERATE INT
SET @ITERATE = 1

WHILE @ITERATE <= 10
BEGIN
	PRINT @ITERATE
	SET @ITERATE = @ITERATE + 1
END

GO

--====================================================
--Create a month shell for every month in 2015
--====================================================

DROP TABLE #MONTH_SHELL
CREATE TABLE #MONTH_SHELL (MONTH_START DATE)

DECLARE @MONTH_START DATE
SET @MONTH_START = '2015-01-01'

WHILE @MONTH_START <= '2015-12-01'
BEGIN
	INSERT INTO #MONTH_SHELL VALUES (@MONTH_START)
	SET @MONTH_START = DATEADD(MM, 1, @MONTH_START)
END

SELECT * FROM #MONTH_SHELL

GO

--====================================================
--Create a month shell for every month in 2015 - Use a Variable SQL Command
--====================================================

DROP TABLE #MONTH_SHELL_2
CREATE TABLE #MONTH_SHELL_2 (MONTH_START DATE)

DECLARE @SQL NVARCHAR(MAX)
DECLARE @MONTH_START VARCHAR(20)
SET @MONTH_START = '2015-01-01'

WHILE CAST(@MONTH_START AS DATE) <= '2015-12-01'
BEGIN
	SET @SQL = '
	INSERT INTO #MONTH_SHELL_2 VALUES ( ''' + @MONTH_START + ''' )
	'

	SET @MONTH_START = DATEADD(MM, 1, @MONTH_START)
	PRINT @SQL
	EXEC SP_EXECUTESQL @SQL
END

--SELECT * FROM #MONTH_SHELL_2

GO

--====================================================
--Dynamic SQL Load Script
--====================================================

DROP TABLE #SHELL
--CREATE SHELL TABLE TO IMPORT DATA
CREATE TABLE #SHELL (
	ENTITY_NAME VARCHAR(50),
	SELL_DT VARCHAR(20),
	SELL_PRICE VARCHAR(20),
	ITEM_ID VARCHAR(20)
	)

DROP TABLE #FORMAT
--CREATE TABLE TO INSERT INTO WITH SOURCE
SELECT *, CAST(NULL AS VARCHAR(200)) AS SOURCE_BRG 
INTO #FORMAT
FROM #SHELL
--SELECT * FROM #FORMAT

DROP TABLE #FILES_TO_LOAD
--LOAD FILE LIST
CREATE TABLE #FILES_TO_LOAD (FILE_NAME VARCHAR(100))
BULK INSERT #FILES_TO_LOAD
FROM '\\na2-fs1\Administration\Training\SQL\Advanced SQL\Example Files\directory.txt'
WITH (FIRSTROW = 1, ROWTERMINATOR = '\n')
--(11 row(s) affected)
--SELECT * FROM #FILES_TO_LOAD

DROP TABLE #FILES_TO_LOAD_CLEAN
--PREPARE HELPER FILE LIST
SELECT ROW_NUMBER() OVER(ORDER BY FILE_NAME) AS ROW_INDEX,
	FILE_NAME, 
	'\\na2-fs1\Administration\Training\SQL\Advanced SQL\Example Files\' + FILE_NAME AS FILE_PATH
INTO #FILES_TO_LOAD_CLEAN
FROM #FILES_TO_LOAD
WHERE FILE_NAME <> 'directory.txt'
--(10 row(s) affected)
--SELECT * FROM #FILES_TO_LOAD_CLEAN

GO

DECLARE	@ITERATE		INT
DECLARE	@FILE_NAME		VARCHAR(200)
DECLARE	@FILE_PATH		VARCHAR(500)
DECLARE	@SQL_1			NVARCHAR(MAX)
SET		@ITERATE	=	1									

WHILE	@ITERATE	<=	(SELECT	MAX(ROW_INDEX)	FROM	#FILES_TO_LOAD_CLEAN	) 
BEGIN

SET @FILE_PATH = (SELECT FILE_PATH FROM #FILES_TO_LOAD_CLEAN WHERE ROW_INDEX = @ITERATE)
SET @FILE_NAME = (SELECT FILE_NAME FROM #FILES_TO_LOAD_CLEAN WHERE ROW_INDEX = @ITERATE)

SET @SQL_1 =		'

DELETE FROM #SHELL
BULK INSERT #SHELL
FROM '''+@FILE_PATH+'''
WITH (FIRSTROW = 2, FIELDTERMINATOR = ''|'', ROWTERMINATOR = ''\n'')

INSERT INTO #FORMAT
SELECT *, '''+@FILE_NAME+''' FROM #SHELL

'

PRINT					@ITERATE
PRINT					@SQL_1
EXEC	SP_EXECUTESQL	@SQL_1
SET	@ITERATE	=	@ITERATE	+	1
END

GO

--SELECT * FROM #FORMAT
