USE UFOs

SELECT Country, COUNT(Country) AS Sightings
FROM [UFO Sightings]
GROUP BY Country
ORDER BY 2 DESC

SELECT (YearOccurred - (YearOccurred % 10)) AS Decade, COUNT(YearOccurred) AS YearlySightings
FROM [UFO Sightings]
GROUP BY YearOccurred - (YearOccurred % 10)
ORDER BY Decade DESC

WITH rankedCities AS (
    SELECT 
        Country, 
        CAST(City AS nvarchar) AS City, 
		COUNT(CAST(City AS nvarchar)) AS Sightings,
        ROW_NUMBER() OVER (PARTITION BY Country ORDER BY COUNT(CAST(City AS nvarchar)) DESC) AS CityRank
    FROM [UFO Sightings]
	WHERE CAST(City AS nvarchar) IS NOT NULL
    GROUP BY Country, CAST(City AS nvarchar)
)
SELECT 
    Country, 
    City,
	Sightings
FROM rankedCities
WHERE CityRank = 1;

SELECT Shape, COUNT(Shape) AS Sightings
FROM [UFO Sightings]
WHERE Shape IS NOT NULL
AND Shape NOT LIKE 'Other'
AND Shape NOT LIKE 'Unknown'
GROUP BY Shape
ORDER BY 2 DESC

SELECT (YearOccurred - (YearOccurred % 10)) AS Decade, AVG((CAST(Seconds AS Float)/60)/60) AS Avg_Duration_Hours
FROM [UFO Sightings]
GROUP BY YearOccurred - (YearOccurred % 10)
ORDER BY Decade DESC