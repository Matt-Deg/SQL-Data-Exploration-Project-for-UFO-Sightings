USE UFOs

SELECT State, COUNT(State) AS Sightings, RANK() OVER (ORDER BY COUNT(State) DESC) AS Rank
FROM [UFO Sightings]
WHERE Country LIKE '%states%'
GROUP BY State
ORDER BY 2 DESC

SELECT State, Season, COUNT(Season) AS Sightings
FROM [UFO Sightings]
WHERE Country LIKE '%states%'
AND State LIKE '%jersey%'
GROUP BY State, Season

SELECT State, YearOccurred, COUNT(YearOccurred) AS Sightings
FROM [UFO Sightings]
WHERE Country LIKE '%states%'
AND State LIKE '%jersey%'
GROUP BY State, YearOccurred

SELECT State, County, COUNT(County) AS Sightings
FROM [UFO Sightings]
WHERE Country LIKE '%states%'
AND State LIKE '%jersey%'
GROUP BY State, County

SELECT 
State, 
Replace(Pop1910, ',', '') AS [1910],
Replace(Pop1920, ',', '') AS [1920],
Replace(Pop1930, ',', '') AS [1930], 
Replace(Pop1940, ',', '') AS [1940],
Replace(Pop1950, ',', '') AS [1950], 
Replace(Pop1960, ',', '') AS [1960],
Replace(Pop1970, ',', '') AS [1970], 
Replace(Pop1980, ',', '') AS [1980],
Replace(Pop1990, ',', '') AS [1990], 
Replace(Pop2000, ',', '') AS [2000],
Replace(Pop2010, ',', '') AS [2010]
FROM [US State Populations]
WHERE State LIKE '%jersey%'

SELECT State, CAST(City AS nvarchar) AS City, COUNT(CAST(City AS nvarchar)) AS Sightings
FROM [UFO Sightings]
WHERE Country LIKE '%states%'
AND State LIKE '%jersey%'
AND City NOT LIKE '%County%'
AND City NOT LIKE '%county%'
GROUP BY State, CAST(City AS nvarchar)
HAVING COUNT(CAST(City AS nvarchar)) >= 8
ORDER BY 3 DESC

SELECT State, Shape, COUNT(Shape) AS Sightings
FROM [UFO Sightings]
WHERE Country LIKE '%states%'
AND State LIKE '%jersey%'
AND Shape IS NOT NULL
GROUP BY State, Shape
ORDER BY 3 DESC