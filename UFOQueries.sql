USE UFOs
--Looking at all of the data
SELECT * 
FROM [UFO Sightings]
ORDER BY 9,4

--Selecting desired columns for analysis
SELECT YearOccurred, Season, Month, Country, State
FROM [UFO Sightings]
ORDER BY 4,1

-------------------------------------------------------------------------------------------------------------------------
--Understanding the selected data

--Number of sightings and percentage of total sightings per country
SELECT Country, COUNT(Country) AS NumSightings, COUNT(Country) * 100.0 / SUM(COUNT(Country)) OVER () AS PercentOfTotal
FROM [UFO Sightings]
GROUP BY Country
ORDER BY 2 DESC

--Number of sightings per decade
SELECT (YearOccurred - (YearOccurred % 10)) AS Decade, COUNT(YearOccurred) AS YearlySightings
FROM [UFO Sightings]
GROUP BY YearOccurred - (YearOccurred % 10)
ORDER BY Decade DESC

--Percentages of sightings distributed in a specific season or month
WITH SeasonCTE AS (
    SELECT Season, COUNT(Season) AS Sightings, COUNT(Season) * 100.0 / SUM(COUNT(Season)) OVER () AS PercentageOfSightings
    FROM [UFO Sightings]
    GROUP BY Season
),
MonthCTE AS (
    SELECT Month, COUNT(Month) AS Sightings, COUNT(Month) * 100.0 / SUM(COUNT(Month)) OVER () AS PercentageOfSightings
    FROM [UFO Sightings]
    GROUP BY Month
)
SELECT 'Season' AS Category, Season AS TimeFrame, PercentageOfSightings
FROM SeasonCTE
UNION ALL
SELECT 'Month' AS Category, CAST(Month AS NVARCHAR(2)) AS TimeFrame, PercentageOfSightings
FROM MonthCTE
ORDER BY PercentageOfSightings DESC;

-------------------------------------------------------------------------------------------------------------------------
--Looking at the United States

--Sightings per county (with state numbers also included)
SELECT County, COUNT(County) AS CountySightings, State, SUM(COUNT(County)) OVER (PARTITION BY State) AS StateSightings
FROM [UFO Sightings]
WHERE Country like '%states%'
and County is not null
GROUP BY State, County
ORDER BY 3,1

--Counties with over 500 sightings
SELECT County, COUNT(County) AS CountySightings, State
FROM [UFO Sightings]
WHERE Country like '%states%'
and County is not null
GROUP BY State, County
HAVING COUNT(County) >= 500

--Identifying hotspots by discerning upper-range outliers of a statistical 99% confidence interval
WITH HotspotsCTE AS (
SELECT State, County, COUNT(County) AS Sightings,
STDEV(COUNT(County)) OVER () AS StandardDev,
AVG(COUNT(County)) OVER () AS SampleMean
FROM [UFO Sightings]
WHERE Country like '%states%'
and County is not null
and YearOccurred >= 2000 and YearOccurred <= 2009
GROUP BY State, County
)
SELECT State, County, Sightings
FROM HotspotsCTE
WHERE Sightings >= (SampleMean + (2.576*StandardDev))
ORDER BY 3 DESC

-------------------------------------------------------------------------------------------------------------------------

--Incorporating other datasets to look at the United States from 2000-2014

--Calculating Sightings per every 10,000 people for each state--

--Gets the average population and density for each state
--during the time period using 2000 and 2010 records from the US State Populations dataset
WITH StatePopsCTE AS (
SELECT 
     State,
     (CAST(REPLACE(Pop2010, ',', '') AS bigint) +
     CAST(REPLACE(Pop2000, ',', '') AS bigint))/2 AS Avg_Population,
     (CAST(REPLACE(Density2010, ',', '') AS float) +
     CAST(REPLACE(Density2000, ',', '') AS float))/2.0 AS Avg_Density
FROM [US State Populations]
)
SELECT
     UFO.State, 
     COUNT(UFO.State) AS Sightings,
     StatePops.Avg_Population,
     StatePops.Avg_Density,
     ROUND(COUNT(UFO.State)/(StatePops.Avg_Population/10000.0), 2) AS SightingsPerTenThousand
FROM [UFO Sightings] UFO
JOIN StatePopsCTE StatePops
     ON UFO.State = StatePops.State
WHERE UFO.Country like '%states%'
and UFO.YearOccurred >= 2000
GROUP BY UFO.State, StatePops.Avg_Population, StatePops.Avg_Density
Order by 5 DESC

--Looking at the Sightings relationship with AQI--

--First look at AQI table with the desired columns
--Notes:

--AQI is an index between 0 and 500, with 0 being the cleanest air possible and 500 being the most polluted possible.

--Columns 4 through 9 are sums created by adding records from all reporting counties together for that year,
--meaning they must be divided by the number of reporting counties that year to reflect a true estimate/average
--(This is done when inserting into the temp table in the next query)

--Days_CO = Sum Number of Days CO was main pollutant
--Days_NO2 = Sum Number of Days NO2 was main pollutant
--Days_Ozone = Sum Number of Days Ozone was main pollutant
--Days_PM2.5 = Sum Number of Days Particulate Matter with diameter of 2.5 micrometers or smaller was main pollutant
--Days_PM10 = Sum Number of Days Particulate Matter with a diameter of 10 micrometers or smaller was main pollutant

--Looking at all of the data needed
SELECT State, Year, ReportingCounties, Median_AQI, Days_CO, Days_NO2, Days_Ozone, [Days_PM2.5], Days_PM10
FROM [US AQI]
WHERE Year >= 2000 and Year <= 2014

--Creating a temporary table to record information over the time period of 2000-2009
DROP Table if exists #AQIMeasures
Create Table #AQIMeasures
(
State nvarchar(50),
Avg_Median float,
Days_CO int,
Days_NO2 int,
Days_Ozone int,
[Days_PM2.5] int,
Days_PM10 int
)
Insert into #AQIMeasures
SELECT 
     State,
	 ROUND(SUM(Median_AQI / CAST(ReportingCounties AS float))/15, 2) AS Avg_Median,
     ROUND(SUM(Days_CO / CAST(ReportingCounties AS float)), 0) AS Days_CO,
	 ROUND(SUM(Days_NO2 / CAST(ReportingCounties AS float)), 0) AS Days_NO2,
	 ROUND(SUM(Days_Ozone / CAST(ReportingCounties AS float)), 0) AS Days_Ozone,
	 ROUND(SUM([Days_PM2.5] / CAST(ReportingCounties AS float)), 0) AS [Days_PM2.5],
	 ROUND(SUM(Days_PM10 / CAST(ReportingCounties AS float)), 0) AS Days_PM10
FROM [US AQI]
WHERE Year >= 2000 and Year <= 2009
GROUP BY State

--Utilizing the temp table to compare AQI data to UFO sightings

--Sightings vs. Average Median AQI
SELECT UFO.State, COUNT(UFO.State) AS Sightings, AQI.Avg_Median
FROM [UFO Sightings] UFO
JOIN #AQIMeasures AQI
     ON UFO.State = AQI.State
WHERE UFO.YearOccurred >= 2000 AND UFO.YearOccurred <= 2009
GROUP BY UFO.State, AQI.Avg_Median
ORDER BY 3

--Sightings vs. Pollutant Ranks
SELECT 
     UFO.State,
	 COUNT(UFO.State) AS Sightings,
	 RANK() OVER (ORDER BY AQI.Days_CO) AS CO_Rank,
	 RANK() OVER (ORDER BY AQI.Days_NO2) AS NO2_Rank,
	 RANK() OVER (ORDER BY AQI.Days_Ozone) AS Ozone_Rank,
	 RANK() OVER (ORDER BY AQI.[Days_PM2.5]) AS [PM2.5_Rank],
	 RANK() OVER (ORDER BY AQI.Days_PM10) AS PM10_Rank
FROM [UFO Sightings] UFO
JOIN #AQIMeasures AQI
     ON UFO.State = AQI.State
WHERE UFO.YearOccurred >= 2000 AND UFO.YearOccurred <= 2009
GROUP BY UFO.State, AQI.Days_CO, AQI.Days_NO2, AQI.Days_Ozone, AQI.[Days_PM2.5], AQI.Days_PM10
ORDER BY 5 --Can change which column to explore further insights on which pollutant is best predictor of sightings (if any)


--Looking at Alcohol Consumption using a subquery to join with UFO Sightings
SELECT 
     ALC.State,
	 UFOQuery.Sightings,
	 ROUND(AVG(Total_Consumption_Per_Capita), 2) AS Total_Consumption
FROM [US Alcohol Consumption] ALC
JOIN 
    (SELECT
	     State,
		 COUNT(State) AS Sightings
     FROM [UFO Sightings]
     WHERE YearOccurred >= 2000
     GROUP BY State
	 ) AS UFOQuery
ON UFOQuery.State = ALC.State
WHERE ALC.Year >= 2000 AND ALC.Year <= 2014
GROUP BY ALC.State, UFOQuery.Sightings
ORDER BY 3 DESC

--Calculating Percentage of Population above working class age in 2010-2014
SELECT EMP.State, ROUND((AVG(WorkingClassPop))/(CAST(REPLACE(Pop2010, ',', '') AS bigint))*100, 2) AS Percentage_WorkingClass, UFOQuery.Sightings
FROM [US Employment] EMP
JOIN [US State Populations] SP
     ON EMP.State = SP.State
JOIN 
(Select
    State,
	COUNT(State) AS Sightings
     FROM [UFO Sightings]
     WHERE YearOccurred >= 2000
     GROUP BY State
	 ) AS UFOQuery
	 ON UFOQuery.State = EMP.State
WHERE EMP.Year >=2010 AND EMP.Year <=2014
GROUP BY EMP.State, Pop2010, UFOQuery.Sightings
ORDER BY 2 DESC

--Creating a statewide view for 2000-2009
CREATE VIEW StatewideStats AS
WITH UFO_CTE AS (
SELECT State, COUNT(State) AS Sightings
FROM [UFO Sightings]
WHERE YearOccurred >= 2000 AND YearOccurred <= 2009
GROUP BY State
),
PopCTE AS (
SELECT EMP.State, SP.Pop2000, ROUND((AVG(WorkingClassPop))/(CAST(REPLACE(SP.Pop2000, ',', '') AS bigint))*100, 2) AS Percentage_WorkingClass
FROM [US Employment] EMP
JOIN [US State Populations] SP
     ON EMP.State = SP.State
WHERE EMP.Year >=2000 AND EMP.Year <=2009
GROUP BY EMP.State, Pop2000
),
ALC_CTE AS (
SELECT State, AVG(Total_Consumption_Per_Capita) AS Total_Consumption
FROM [US Alcohol Consumption]
WHERE Year >= 2000 AND Year <= 2009
GROUP BY State
),
AQI_CTE AS (
SELECT
	 State,
	 ROUND(SUM(Median_AQI / CAST(ReportingCounties AS float))/15, 2) AS Avg_Median,
     ROUND(SUM(Days_CO / CAST(ReportingCounties AS float)), 0) AS Days_CO,
	 ROUND(SUM(Days_NO2 / CAST(ReportingCounties AS float)), 0) AS Days_NO2,
	 ROUND(SUM(Days_Ozone / CAST(ReportingCounties AS float)), 0) AS Days_Ozone,
	 ROUND(SUM([Days_PM2.5] / CAST(ReportingCounties AS float)), 0) AS [Days_PM2.5],
	 ROUND(SUM(Days_PM10 / CAST(ReportingCounties AS float)), 0) AS Days_PM10
FROM [US AQI]
WHERE Year >= 2000 and Year <= 2009
GROUP BY State
)
SELECT AQI_CTE.*, UFO_CTE.Sightings, PopCTE.Pop2000, PopCTE.Percentage_WorkingClass, ALC_CTE.Total_Consumption
FROM UFO_CTE
JOIN PopCTE ON UFO_CTE.State = PopCTE.State
JOIN ALC_CTE ON PopCTE.State = ALC_CTE.State
JOIN AQI_CTE ON ALC_CTE.State = AQI_CTE.State

-------------------------------------------------------------------------------------------------------------------------

--Incorporating another dataset to look at the United States from a county-level view 2000-2014


--Sightings Per Ten Thousand in each county
SELECT UFO.State, UFO.County, COUNT(UFO.County) AS CountySightings, (CP.Pop2010 + CP.Pop2000)/2 AS Population,
COUNT(UFO.County)/(((CP.Pop2010 + CP.Pop2000)/2)/10000.0) AS SightingsPerTenThousand
FROM [UFO Sightings] UFO
JOIN [US County Populations] CP
     ON UFO.County = LTRIM(RTRIM(SUBSTRING(REPLACE(CP.County, 'County', ''), 1, CHARINDEX(',', REPLACE(CP.County, 'County', '')) - 1)))
	 AND UFO.State = LTRIM(RTRIM(SUBSTRING(REPLACE(CP.County, 'County', ''), CHARINDEX(',', REPLACE(CP.County, 'County', '')) + 1, LEN(REPLACE(CP.County, 'County', '')))))
WHERE UFO.Country like '%states%'
and UFO.YearOccurred >= 2000 AND UFO.YearOccurred <= 2014
AND ((CP.Pop2010 + CP.Pop2000)/2) > 1000
GROUP BY UFO.State, UFO.County, (CP.Pop2010 + CP.Pop2000)
ORDER BY 1,2

--Looking at categories of the US County Stats dataset
SELECT DISTINCT Description, Unit
FROM [US County Stats]
Order by 2

--Creating a county-wide view of the 2000s using the US County Stats dataset
--Note: NumberOfJobs is the total number of jobs filled in the county, not amount of employed persons among the county's population
--This means that it is possible for the total number of jobs to be larger than the population,
--assuming people commute across county lines for work
CREATE VIEW CountywideStats AS
WITH UFO AS (
SELECT State, County, COUNT(County) AS Sightings
FROM [UFO Sightings]
WHERE YearOccurred >= 2000 AND YearOccurred <= 2009
GROUP BY State, County
),
CountyIncome AS (
SELECT RTRIM(LTRIM(SUBSTRING(Region, 1, (CHARINDEX(',', Region) - 1)))) AS County,
RTRIM(LTRIM(SUBSTRING(Region, (CHARINDEX(',', Region) + 1), LEN(Region)))) AS State, [2000] AS [Per Capita Personal Income (Dollars)]
FROM [US County Stats]
WHERE Region like '%,%'
AND Description = 'Per capita personal income 4/'
),
CountyPopulation AS (
SELECT RTRIM(LTRIM(SUBSTRING(Region, 1, (CHARINDEX(',', Region) - 1)))) AS County,
RTRIM(LTRIM(SUBSTRING(Region, (CHARINDEX(',', Region) + 1), LEN(Region)))) AS State, [2000] AS [Population]
FROM [US County Stats]
WHERE Region like '%,%'
AND Description = 'Population (persons) 3/'
),
CountyEmployment AS (
SELECT RTRIM(LTRIM(SUBSTRING(Region, 1, (CHARINDEX(',', Region) - 1)))) AS County,
RTRIM(LTRIM(SUBSTRING(Region, (CHARINDEX(',', Region) + 1), LEN(Region)))) AS State, [2000] AS [NumberOfJobs]
FROM [US County Stats]
WHERE Region like '%,%'
AND Description = 'Total employment (number of jobs)'
)
SELECT UFO.*, CountyPopulation.Population, CountyIncome.[Per Capita Personal Income (Dollars)],
CountyEmployment.NumberOfJobs
FROM UFO
JOIN CountyIncome
ON UFO.State = CountyIncome.State
AND UFO.County = CountyIncome.County
JOIN CountyPopulation
ON CountyIncome.State = CountyPopulation.State
AND CountyIncome.County = CountyPopulation.County
JOIN CountyEmployment
ON CountyPopulation.State = CountyEmployment.State
AND CountyPopulation.County = CountyEmployment.County
Order by 1, 2