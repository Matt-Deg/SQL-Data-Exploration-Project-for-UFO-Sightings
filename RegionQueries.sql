USE UFOs

ALTER TABLE [UFO Sightings]
ADD Region nvarchar(55) DEFAULT NULL

UPDATE [UFO Sightings]
SET Region = 
    (CASE
        WHEN State IN ('Washington', 'Oregon', 'California', 'Nevada', 'Utah', 
		'Colorado', 'Wyoming', 'Idaho', 'Montana', 'Alaska', 'Hawaii', 'Arizona', 'New Mexico') THEN 'West'

        WHEN State IN ('North Dakota', 'South Dakota', 'Minnesota', 'Wisconsin', 'Michigan',
		'Nebraska', 'Kansas', 'Iowa', 'Ohio', 'Indiana', 'Illinois', 'Missouri') THEN 'Midwest'

        WHEN State IN ('Texas', 'Oklahoma', 'Arkansas', 'Louisiana', 'Mississippi', 'Alabama', 
		'Georgia', 'Florida', 'South Carolina', 'Tennessee', 'North Carolina', 'Kentucky', 'West Virginia', 'Virginia') THEN 'South'

        WHEN State IN ('Maryland', 'Delaware', 'Pennsylvania', 'New Jersey', 'New York', 'Massachusetts', 
		'Connecticut', 'Rhode Island', 'New Hampshire', 'Vermont', 'Maine', 'District of Columbia') THEN 'North'

        ELSE 'Unknown'
    END)

SELECT Distinct State, Region
FROM [UFO Sightings]
WHERE Country LIKE '%states%'
Order by 1

SELECT Region, COUNT(Region) AS Sightings
FROM [UFO Sightings]
WHERE Region NOT LIKE 'Unknown'
GROUP BY Region

SELECT YearOccurred, Region, COUNT(Region) AS Sightings
FROM [UFO Sightings]
WHERE Region NOT LIKE 'Unknown'
GROUP BY YearOccurred, Region
ORDER BY 2, 1

SELECT Region, ROUND(AVG(CAST(Seconds AS float)/60/60), 2) AS Avg_Duration_Hours
FROM [UFO Sightings]
WHERE Region NOT LIKE 'Unknown'
GROUP BY Region

WITH TempCTE AS (
SELECT
Region,
Shape,
COUNT(Shape) AS Sightings,
ROW_NUMBER() OVER (PARTITION BY Region ORDER BY COUNT(Shape) DESC) AS ShapeRank
FROM [UFO Sightings]
WHERE Region NOT LIKE 'Unknown'
GROUP BY Region, Shape
)
SELECT Region, Shape, Sightings, ShapeRank
FROM TempCTE
WHERE ShapeRank <= 3