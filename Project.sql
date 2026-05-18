
#1----Find number of routes

SELECT COUNT(*) AS num_routes FROM routes;

#2-----Find number of stops

SELECT COUNT(*)  AS num_stpps
FROM stops;


#3----- Keep trip_id, trip_headsign, route_id, direction_id, service_id

SELECT trip_id, trip_headsign, route_id, direction_id, service_id
FROM trips;

#4-------Keep trips that go northbound

SELECT *
FROM trips
WHERE trip_headsign LIKE 'NORTH%';


#5-- Find the first stop of each trip

SELECT trip_id, stop_id, stop_sequence
FROM stop_times
WHERE stop_sequence = 1;

#6----Find the minimum stop sequence of each trip (note that some trips in the stop_times table do not have stop_sequence==1)

SELECT trip_id, MIN(CAST(stop_sequence AS UNSIGNED)) AS min_seq
FROM stop_times
GROUP BY trip_id;


#7-----Find trips that do not have stop_sequence==1

SELECT trip_id, MIN(CAST(stop_sequence AS UNSIGNED)) AS min_seq
FROM stop_times
GROUP BY trip_id
HAVING min_seq!=1;



#8----- Find all transit stops located within the bounding box around York University.

SELECT stop_id, stop_name, stop_lat, stop_lon
FROM stops
WHERE stop_lon BETWEEN -79.51699349886277 AND -79.49314289586839
    AND stop_lat BETWEEN 43.76716912360669 AND 43.78247182148897;
    


#9------Find all night service streetcar routes
SELECT *
FROM routes
WHERE route_type = 0 AND route_id BETWEEN 299 AND 400;


#10---- Find all active services that might be active on Monday

SELECT *
FROM calendar
WHERE monday = 1;

#11--- Find number of trips stop at stop_id = 1099

SELECT COUNT(DISTINCT trip_id)
FROM stop_times
WHERE stop_id = 1099;



#12--- Find number of unique stops in the stop times table

Select COUNT(DISTINCT stop_id) 
FROM stop_times;

#13--- Find stops that are not used

SELECT * FROM
stops
WHERE stop_id NOT IN (
SELECT DISTINCT stop_id
FROM stop_times);

#14--- Find stop_ids that thier stop_codes are not number

SELECT *
FROM stops
WHERE stop_code REGEXP '[^0-9]';



#15--- Find number of trips per route
SELECT route_id, COUNT(*) AS num_trips
FROM trips
GROUP BY route_id;


#16---- Find all routes that are bus
SELECT *
FROM routes
WHERE route_type = 3;

#17---- Find number of stops per trip
SELECT trip_id, COUNT(*) AS num_stops
FROM stop_times
GROUP BY trip_id;


#18---- Find trips with more than 30 stops
SELECT trip_id, COUNT(*) AS num_stops
FROM stop_times
GROUP BY trip_id
HAVING num_stops > 30;

#19----Find last stop of each trip

SELECT st.trip_id, st.stop_id, st.stop_sequence
FROM stop_times AS st
JOIN
(SELECT trip_id, MAX(CAST(stop_sequence AS UNSIGNED)) AS max_seq
FROM stop_times
GROUP BY trip_id) AS tmax
ON st.trip_id = tmax.trip_id AND CAST(st.stop_sequence AS UNSIGNED) = tmax.max_seq;


#20---- Find number of trips by direction
SELECT direction_id, COUNT(*) AS num_trips
FROM trips
GROUP BY direction_id;


#21---- Find number of trips for each route and direction

SELECT route_id, direction_id, COUNT(*) AS num_trips
FROM trips
GROUP BY route_id, direction_id;


#22--- Find trips that are not in the stop times table
SELECT * 
FROM trips
WHERE trip_id NOT IN (
SELECT DISTINCT trip_id
FROM stop_times);

#23----- Find trips that thier trip_short_name is null or empty

SELECT *
FROM trips
WHERE trip_short_name IS NULL 
   OR trip_short_name = '';
   
#24---- Find unique combination of route_id and trip_short_name
   
SELECT DISTINCT route_id, trip_short_name
FROM trips;


#25--- Find number of unique trip_short_name for each route
SELECT route_id, COUNT(DISTINCT trip_short_name) AS num_unique_short_names
FROM trips
GROUP BY route_id;


#26---- Find the length of each shape_id


SELECT shape_id, MAX(shape_dist_traveled) AS length
FROM shapes
GROUP BY shape_id;


#27----- Find approximate length of each trip


SELECT t.trip_id,t.route_id, t.direction_id, sh.length
FROM trips AS t
JOIN (
SELECT shape_id, MAX(shape_dist_traveled) AS length
FROM shapes
GROUP BY shape_id) AS sh
ON sh.shape_id = t.shape_id;


#28----- Find the trip length statistics for each route and direction and service_id.

SELECT 
tshr.route_id,
tshr.service_id,
tshr.direction_id,
COUNT(tshr.trip_id) AS num_trips,
ROUND(MIN(tshr.length),2) AS min_trip_length,
ROUND(MAX(tshr.length),2) AS max_trip_length,
ROUND(AVG(tshr.length),2) AS avg_trip_length,
ROUND(STDDEV(tshr.length),2) AS std_trip_length
FROM(
SELECT t.trip_id,t.route_id, t.direction_id, t.service_id, sh.length
FROM trips AS t
JOIN (
SELECT shape_id, MAX(shape_dist_traveled) AS length
FROM shapes
GROUP BY shape_id) AS sh
ON sh.shape_id = t.shape_id) AS tshr
GROUP BY tshr.route_id, tshr.service_id, tshr.direction_id
ORDER BY tshr.route_id,tshr.service_id, tshr.direction_id;



#29---- Create a new table (a copy of calendar) and add corrected start and end dates, and add time horizon duration

CREATE TABLE calendar1
LIKE calendar;

INSERT calendar1
SELECT *
FROM calendar;


SELECT * from calendar1;

ALTER TABLE calendar1
ADD COLUMN start_date_corrected DATE,
ADD COLUMN end_date_corrected DATE;

SET SQL_SAFE_UPDATES = 0;

UPDATE calendar1
SET 
  start_date_corrected = STR_TO_DATE(start_date, '%Y%m%d'),
  end_date_corrected   = STR_TO_DATE(end_date, '%Y%m%d');
  

ALTER TABLE calendar1
ADD COLUMN num_days INT;

UPDATE calendar1
SET num_days = DATEDIFF(end_date_corrected, start_date_corrected);

SET SQL_SAFE_UPDATES = 0;

SELECT * from calendar1;


#30---- Create a new table (a copy of calendar_dates) and add corrected date

CREATE TABLE calendar_dates1
LIKE calendar_dates;

INSERT calendar_dates1
SELECT * 
FROM calendar_dates;

SELECT * FROM calendar_dates1;



ALTER TABLE calendar_dates1
ADD COLUMN date_corrected DATE;

UPDATE calendar_dates1
SET date_corrected = STR_TO_DATE(`date`, '%Y%m%d');



#31---- Find the start and end date of the GTFS feeds 
SELECT MIN(start_date_corrected) AS start_date, MAX(end_date_corrected) AS end_date
FROM calendar1;


#32---- Find number of trips for each service_id

SELECT service_id, COUNT(trip_id) AS num_trips
FROM trips
GROUP BY service_id;

#33---- Find number of routes by route type (bus, streetcar, subway, other)

SELECT rtype.route_type, 
CASE
WHEN rtype.route_type = 0 THEN 'streetcar'
WHEN rtype.route_type = 1 THEN 'subway'
WHEN rtype.route_type = 3 THEN 'bus'
ELSE 'other'
END AS service_type,
rtype.num_routes
FROM(
SELECT route_type, COUNT(route_id) AS num_routes
FROM routes
GROUP BY route_type) AS rtype;


#34---- Find number of unique blocks

SELECT COUNT(DISTINCT block_id)
FROM trips;

#35--- Find 5 top block_ids with maximum number of trips

SELECT block_id, COUNT(DISTINCT trip_id) AS num_trips
FROM trips
GROUP BY block_id 
ORDER BY num_trips DESC
LIMIT 5;

#36--- Find routes wit no trips

SELECT r.route_id
FROM routes r
LEFT JOIN trips t
ON r.route_id = t.route_id
WHERE t.trip_id IS NULL;


#37--- Find missing stop_sequence

SELECT t1.trip_id, t1.stop_sequence + 1 AS missing_seq
FROM stop_times t1
LEFT JOIN stop_times t2
  ON t1.trip_id = t2.trip_id
 AND t1.stop_sequence + 1 = t2.stop_sequence
WHERE t2.trip_id IS NULL;


#36--- Create a new table and find start time and end time of each trip

CREATE TABLE trip_start_time 
(trip_id INT,
direction_id INT,
arrival_time VARCHAR(16));


INSERT INTO trip_start_time (trip_id, direction_id, arrival_time)
SELECT st.trip_id, t.direction_id, st.arrival_time
FROM stop_times AS st
JOIN trips AS t
    ON st.trip_id = t.trip_id
JOIN (
    SELECT trip_id, MIN(CAST(stop_sequence AS UNSIGNED)) AS min_seq
    FROM stop_times
    GROUP BY trip_id
) AS trm
ON st.trip_id = trm.trip_id 
AND CAST(st.stop_sequence AS UNSIGNED) = trm.min_seq;

ALTER TABLE trip_start_time
ADD COLUMN arrival_time_sec INT;

UPDATE trip_start_time
SET arrival_time_sec =
    SUBSTRING_INDEX(arrival_time, ':', 1) * 3600 +
    SUBSTRING_INDEX(SUBSTRING_INDEX(arrival_time, ':', 2), ':', -1) * 60 +
    SUBSTRING_INDEX(arrival_time, ':', -1);

select * from trip_start_time;


#---- Create new table similar to trip_start_time with additional route_id and service_id columns

CREATE TABLE trip_start_enriched (
    trip_id INT,
    direction_id INT,
    arrival_time VARCHAR(16),
    arrival_time_sec INT,
    route_id INT,
    service_id INT
);

INSERT INTO trip_start_enriched
SELECT 
    ttime.trip_id,
    ttime.direction_id,
    ttime.arrival_time,
    ttime.arrival_time_sec,
    tser.route_id,
    tser.service_id
FROM trip_start_time AS ttime
JOIN trips AS tser
ON ttime.trip_id = tser.trip_id;

SELECT * from trip_start_enriched;


#-- Find earelst trips for each trip_id, route_id, direction_id, service_id

SELECT route_id, direction_id, service_id, MIN(arrival_time_sec) AS `earliest trip`
FROM trip_start_enriched
GROUP BY route_id, direction_id, service_id
having route_id = 115
ORDER BY route_id, direction_id;


#---- Add hour, minute, and second of starting time of trips
ALTER TABLE trip_start_enriched
ADD COLUMN hour_time INT,
ADD COLUMN minute_time INT,
ADD COLUMN second_time INT;

UPDATE trip_start_enriched
SET 
    hour_time   = FLOOR(arrival_time_sec / 3600),
    minute_time = FLOOR((arrival_time_sec % 3600) / 60),
    second_time = arrival_time_sec % 60;
    
SELECT * FROM trip_start_enriched;


#---- Create new table as horly_trips and find the number of trips for each hour and service_id

CREATE TABLE horly_trips (
service_id INT,
hour_time INT,
num_trips int);

INSERT INTO horly_trips (service_id, hour_time, num_trips)
SELECT service_id, hour_time, COUNT(trip_id) AS num_trips
FROM trip_start_enriched
GROUP BY service_id, hour_time;

SELECT * FROM horly_trips
ORDER BY service_id, hour_time;



# FIND trip_ids that have only one stop in the stop_times file and delete them as erro data
SELECT trip_id, COUNT(stop_sequence) AS num_stops
FROM stop_times
GROUP BY trip_id
Having num_stops = 1;

CREATE TABLE stop_times_corrected
LIKE stop_times;

INSERT stop_times_corrected
SELECT * from stop_times;

Select * from stop_times_corrected;


DELETE st
FROM stop_times_corrected AS st
JOIN (
    SELECT trip_id
    FROM stop_times_corrected
    GROUP BY trip_id
    HAVING COUNT(stop_sequence) = 1
) AS bad_trips
ON st.trip_id = bad_trips.trip_id;



#---- Retrieve comprehensive trip-level statistics and attributes by joining the trips, stop_times, routes, and shapes tables.

CREATE TABLE trip_information_final AS
SELECT trip_final1.*, r.route_type,
CASE
WHEN r.route_type = 0 THEN 'streetcar'
WHEN r.route_type = 3 AND r.route_id <899 THEN 'bus'
WHEN r.route_type = 3 AND r.route_id >899 THEN 'express'
ELSE 'other'
END AS service_type,
sh.trip_length_m
FROM (
SELECT trip_final.*, t.route_id, t.service_id, t.direction_id, t.shape_id
FROM
(
SELECT trip_data.*,
	SUBSTRING_INDEX(trip_data.start_time, ':', 1) * 3600 +
    SUBSTRING_INDEX(SUBSTRING_INDEX(trip_data.start_time, ':', 2), ':', -1) * 60 +
    SUBSTRING_INDEX(trip_data.start_time, ':', -1) AS start_time_second,
	SUBSTRING_INDEX(trip_data.end_time, ':', 1) * 3600 +
    SUBSTRING_INDEX(SUBSTRING_INDEX(trip_data.end_time, ':', 2), ':', -1) * 60 +
    SUBSTRING_INDEX(trip_data.end_time, ':', -1)AS end_time_second,
    ROUND((
        (SUBSTRING_INDEX(trip_data.end_time, ':', 1) * 3600 +
		SUBSTRING_INDEX(SUBSTRING_INDEX(trip_data.end_time, ':', 2), ':', -1) * 60 +
		SUBSTRING_INDEX(trip_data.end_time, ':', -1))
        -
        (SUBSTRING_INDEX(trip_data.start_time, ':', 1) * 3600 +
		SUBSTRING_INDEX(SUBSTRING_INDEX(trip_data.start_time, ':', 2), ':', -1) * 60 +
		SUBSTRING_INDEX(trip_data.start_time, ':', -1))
    )/60,0) AS trip_duration_minute
FROM(
SELECT tripinfo.*, st.stop_id AS first_stop, st.arrival_time AS start_time, stt.stop_id AS last_stop, stt.arrival_time AS end_time
FROM(
SELECT trip_id, COUNT(*) AS num_stops, MIN(stop_sequence) AS min_seq, MAX(stop_sequence) AS max_seq
FROM stop_times
GROUP BY trip_id) AS tripinfo
JOIN stop_times AS st
ON tripinfo.trip_id = st.trip_id AND tripinfo.min_seq = st.stop_sequence
JOIN stop_times as stt
ON tripinfo.trip_id = stt.trip_id AND tripinfo.max_seq = stt.stop_sequence) AS trip_data)AS trip_final
JOIN trips AS t
ON trip_final.trip_id = t.trip_id) AS trip_final1
JOIN routes AS r
ON r.route_id = trip_final1.route_id
JOIN (
SELECT shape_id, ROUND(MAX(shape_dist_traveled)) AS trip_length_m
FROM shapes
GROUP BY shape_id) AS sh
ON trip_final1.shape_id = sh.shape_id;


select * from trip_information_final;

#---- The above solution is advaced but it is not optimal. Convert it to a production-level using CTE logic
CREATE TABLE trip_information_production AS

WITH tripinfo AS (
    SELECT 
        trip_id,
        COUNT(*) AS num_stops,
        MIN(stop_sequence) AS min_seq,
        MAX(stop_sequence) AS max_seq
    FROM stop_times
    GROUP BY trip_id
),

trip_bounds AS (
    SELECT 
        ti.trip_id,
        ti.num_stops,
        st.stop_id AS first_stop,
        st.arrival_time AS start_time,
        stt.stop_id AS last_stop,
        stt.arrival_time AS end_time
    FROM tripinfo ti
    JOIN stop_times st
        ON ti.trip_id = st.trip_id 
       AND ti.min_seq = st.stop_sequence
    JOIN stop_times stt
        ON ti.trip_id = stt.trip_id 
       AND ti.max_seq = stt.stop_sequence
),

trip_time AS (
    SELECT 
        *,

        -- start time in seconds (GTFS safe)
        (
            SUBSTRING_INDEX(start_time, ':', 1) * 3600 +
            SUBSTRING_INDEX(SUBSTRING_INDEX(start_time, ':', 2), ':', -1) * 60 +
            SUBSTRING_INDEX(start_time, ':', -1)
        ) AS start_time_second,

        -- end time in seconds
        (
            SUBSTRING_INDEX(end_time, ':', 1) * 3600 +
            SUBSTRING_INDEX(SUBSTRING_INDEX(end_time, ':', 2), ':', -1) * 60 +
            SUBSTRING_INDEX(end_time, ':', -1)
        ) AS end_time_second

    FROM trip_bounds
),

trip_duration AS (
    SELECT 
        *,
        ROUND((end_time_second - start_time_second) / 60, 0) AS trip_duration_minute
    FROM trip_time
),

trip_enriched AS (
    SELECT 
        td.*,
        t.route_id,
        t.service_id,
        t.direction_id,
        t.shape_id
    FROM trip_duration td
    JOIN trips t
        ON td.trip_id = t.trip_id
),

shape_length AS (
    SELECT 
        shape_id,
        ROUND(MAX(shape_dist_traveled)) AS trip_length_m
    FROM shapes
    GROUP BY shape_id
)

SELECT 
    te.*,
    r.route_type,

    CASE
        WHEN r.route_type = 0 THEN 'streetcar'
        WHEN r.route_type = 3 AND r.route_id < 900 THEN 'bus'
        WHEN r.route_type = 3 AND r.route_id >= 900 THEN 'express'
        ELSE 'other'
    END AS service_type,

    sh.trip_length_m

FROM trip_enriched te
JOIN routes r
    ON te.route_id = r.route_id
JOIN shape_length sh
    ON te.shape_id = sh.shape_id;



#---- Identify trips that contain only a single stop, which may indicate incomplete or erroneous data.
SELECT * FROM trip_information_production
WHERE num_stops = 1;


#--- Count trips per hour for each service_id:
SELECT  service_id, FLOOR(arrival_time_sec / 3600) AS hour, 
       COUNT(*) AS num_trips
FROM trip_start_enriched
GROUP BY service_id, hour
ORDER BY service_id, hour ASC;

#------
WITH trip_sen AS (
sELECT trip_id, COUNT(*) AS num_stops, MIN(stop_sequence) AS min_seq, MAX(stop_sequence) AS max_seq
FROM stop_times
GROUP BY trip_id),

trip_stop AS (
SELECT t.*, st.stop_id AS first_stop, sst.stop_id AS end_stop
FROM trip_sen AS t
JOIN stop_times AS st
ON t.trip_id = st.trip_id AND t.min_seq = st.stop_sequence
JOIN stop_times AS sst
ON t.trip_id = sst.trip_id AND t.max_seq = sst.stop_sequence)
SELECT * FROM trip_stop;


#----

WITH route_info AS (
    SELECT route_id, route_long_name, route_type
    FROM routes
    WHERE route_type = 3   -- only bus
),

trip_sig AS (
    SELECT trip_id, direction_id, route_id
    FROM trips
    WHERE direction_id = 0  -- only one direction
)

SELECT trip_sig.*, route_info.route_long_name, route_info.route_type
FROM trip_sig
JOIN route_info 
ON trip_sig.route_id = route_info.route_id;

#-----
WITH shape_info AS (
SELECT shape_id, Max(shape_dist_traveled) As shape_length
FROM shapes
GROUP BY shape_id),

trip_info AS (
SELECT trip_id, shape_id
FROM trips)

SELECT trip_info.*, shape_info.shape_length AS trip_length
FROM trip_info
JOIN shape_info
ON shape_info.shape_id = trip_info.shape_id;



