/*Q1: Write a query to fetch the museums (name and city) that are open on both Monday and Sunday.*/

SELECT m.name AS museum_name, m.city
FROM museum_hours AS mh
JOIN museums AS m
ON mh.museum_id = m.museum_id
WHERE day = 'Sunday'
AND EXISTS (
	SELECT * FROM museum_hours AS mh2
	WHERE mh.museum_id = mh2.museum_id
	AND day = 'Monday'
	)
-------------------------------------------------------------------------------------------------------------------

/*Q2: Write a query to fetch the museums (name and city) that are not open on Monday.*/

SELECT DISTINCT m.name AS museum_name, m.city
FROM museum_hours AS mh
JOIN museums AS m
ON mh.museum_id = m.museum_id
WHERE mh.museum_id NOT IN(
	SELECT DISTINCT museum_id 
	FROM museum_hours
	WHERE day = 'Monday'
	)
-------------------------------------------------------------------------------------------------------------------

/*Q3: Write a query to find out which museum is open for the longest during a day? 
      Display museum name, state, opening duration and day.*/

WITH museum_open_duration AS (
	SELECT m.name AS museum_name, m.state, mh.day,
	to_timestamp(open, 'HH:MI AM') AS open_time,
	to_timestamp(close, 'HH:MI PM') AS close_time,
	to_timestamp(close, 'HH:MI PM') - to_timestamp(open, 'HH:MI AM') AS duration,
	RANK() OVER(ORDER BY(to_timestamp(close, 'HH:MI PM') - to_timestamp(open, 'HH:MI AM')) DESC) AS rk
	FROM museum_hours mh JOIN museums m
	ON mh.museum_id = m.museum_id
	)
SELECT museum_name, state, day, open_time, close_time, duration 
FROM museum_open_duration
WHERE rk < 2
-------------------------------------------------------------------------------------------------------------------

/*Q4: Write a query to find out which museum has the most paintings of the most popular style? 
      (The most popular style is defined based on the number of panitings of each style).*/

SELECT m.name, m.city, count(aw.name) AS num_of_paintings_of_impressionism
FROM museums m join art_work aw
ON m.museum_id = aw.museum_id
WHERE aw.style = (
	SELECT style FROM  (
		SELECT style, COUNT(name) AS num_of_paintings,
		RANK() OVER(ORDER BY COUNT(style) DESC) AS rk
		FROM art_work
		GROUP BY style) x
	WHERE x.rk < 2
	)
GROUP BY m.name, m.city
ORDER BY num_of_paintings_of_impressionism DESC
LIMIT 1
-------------------------------------------------------------------------------------------------------------------

/*Q5: Write a query to fetch the top 5 museums (name and number of paintings) with the most paintings.*/

--Query no.1:

SELECT m.name AS museum_name, COUNT(aw.work_id) AS num_of_paintings
FROM museums m JOIN art_work aw
ON m.museum_id = aw.museum_id
GROUP BY m.name
ORDER BY num_of_paintings DESC
LIMIT 5

--Query no.2:

WITH museum_paintings AS (
	SELECT m.name AS museum_name, 
	COUNT(aw.work_id) AS num_of_paintings,
	RANK() OVER(ORDER BY count(aw.work_id) DESC) as museum_rank
	FROM museums m JOIN art_work aw ON m.museum_id = aw.museum_id
	GROUP BY m.name
	)
SELECT museum_name, num_of_paintings
FROM museum_paintings
WHERE museum_rank < 6
-------------------------------------------------------------------------------------------------------------------

/*Q6: Write a query to find out which country and city have the most museums? 
      Output two separate columns to display the country and the city.
      If there are multiple values, separate them with comma.*/

WITH 
cte_country AS (
	SELECT country, COUNT(1),
	RANK() OVER(ORDER BY COUNT(1) DESC) AS rk1
	FROM museums
	GROUP BY country
	),
cte_city AS (
	SELECT city, COUNT(1),
	RANK() OVER(ORDER BY COUNT(1) DESC) AS rk2
	FROM museums
	GROUP BY city
	)
SELECT string_agg(DISTINCT country, ' , ') AS country, 
       string_agg(city, ' , ') AS city
FROM cte_country CROSS JOIN cte_city
WHERE cte_country.rk1 = 1
AND cte_city.rk2 = 1
-------------------------------------------------------------------------------------------------------------------

/*Q7: Identify the artists and the museums where the most expensive and least expensive paintings are placed. 
      Display the artist name, sale_price, painting name, canvas label, museum name, museum city and museum country.*/

SELECT e.full_name AS artist_name, a.name AS painting_name, p.regular_price AS price, 
c.label AS canvas_label, m.name AS museum_name, m.city AS museum_city, m.country AS museum_country
FROM product_size p LEFT JOIN canvas_size c ON p.size_id = c.size_id
JOIN art_work a ON p.work_id = a.work_id
JOIN artists e ON a.artist_id = e.artist_id
JOIN museums m ON a.museum_id = m.museum_id
WHERE p.regular_price = (SELECT MAX(regular_price) FROM product_size)

UNION ALL

SELECT e.full_name AS artist_name, a.name AS painting_name, p.regular_price AS price, 
c.label AS canvas_label, m.name AS museum_name, m.city AS museum_city, m.country AS museum_country
FROM product_size p LEFT JOIN canvas_size c ON p.size_id = c.size_id
JOIN art_work a ON p.work_id = a.work_id
JOIN artists e ON a.artist_id = e.artist_id
JOIN museums m ON a.museum_id = m.museum_id
WHERE p.regular_price = (SELECT MIN(regular_price) FROM product_size)
-------------------------------------------------------------------------------------------------------------------
