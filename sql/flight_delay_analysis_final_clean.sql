
--FLIGHT DELAY ANALYSIS DASHBOARD - COMPLETE PROJECT 
-
-- 
-- 📊 WHAT THIS DOES:
-- This SQL script creates all the data needed for your Tableau dashboard
-- It analyzes flight delays from 2020-2023 and creates 3 main charts:
--   1. Airline Performance Ranking (which airlines are best/worst)
--   2. Monthly Trends (when delays happen most)
--   3. Yearly Overview (how delays changed over time)
--
--  GOAL: Help people understand flight delay patterns and choose better airlines
--  DATA PERIOD: 2020-2023 (most recent and relevant data)
--  FOCUS: Major US airlines with meaningful delays (>10 minutes)

-- SECTION 1: LET'S EXPLORE YOUR DATA FIRST

--  STEP 1: See what tables are in your database
-- 
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';

-- 📋 STEP 2: Check the structure of your flights table
--
SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'flights_delay';

-- 📋 STEP 3: Count how many flight records we have
-- 
SELECT COUNT(*) as total_rows FROM flights_delay;


-- SECTION 2: CLEAN UP AND OPTIMIZE THE DATA

--  First, let's remove any old version of this table (if it exists)
DROP TABLE IF EXISTS flight_data_optimized;

-- Create our clean, optimized dataset
-- This will be much faster to work with and easier to understand
SELECT 
    fl_date,                                    -- The date of the flight
    EXTRACT(YEAR FROM fl_date) AS year,         -- Extract year (2020, 2021, etc.)
    EXTRACT(MONTH FROM fl_date) AS month,       -- Extract month (1-12)
    airline,                                    -- Which airline (Delta, United, etc.)
    origin_city,                                -- Where the flight started
    dest,                                       -- Where the flight ended
    dep_delay,                                  -- How late the departure was (minutes)
    arr_delay,                                  -- How late the arrival was (minutes)
    delay_due_carrier_minutes,                  -- Delays caused by the airline
    delay_due_weather_minutes,                  -- Delays caused by weather
    delay_due_nas_minutes,                      -- Delays caused by air traffic control
    delay_due_security_minutes,                 -- Delays caused by security
    delay_due_late_aircraft_minutes             -- Delays caused by previous flight being late
INTO flight_data_optimized
FROM flights_delay
WHERE 
    -- Only keep recent data (2020-2023) - most relevant for today's travelers
    EXTRACT(YEAR FROM fl_date) >= 2020
    
    -- Only keep flights with meaningful delays (>10 minutes)
    AND (dep_delay > 10 OR arr_delay > 10)
    
    -- Only keep major airlines that people actually fly
    AND airline IN (
        'Southwest Airlines Co.',      -- Southwest
        'Delta Air Lines Inc.',        -- Delta
        'American Airlines Inc.',      -- American
        'United Air Lines Inc.',       -- United
        'JetBlue Airways',             -- JetBlue
        'Alaska Airlines Inc.',        -- Alaska
        'Spirit Air Lines',            -- Spirit
        'Frontier Airlines Inc.',      -- Frontier
        'Allegiant Air',               -- Allegiant
        'Hawaiian Airlines Inc.',      -- Hawaiian
        'SkyWest Airlines Inc.',       -- SkyWest
        'Republic Airline'             -- Republic
    );

-- Check how much data we have now (should be much less than before!)
SELECT COUNT(*) as optimized_rows FROM flight_data_optimized;

-- 🏆 SECTION 3: RANK THE AIRLINES BY PERFORMANCE

-- Remove any old version of this table
DROP TABLE IF EXISTS airline_performance;

-- 🏆 Create our airline ranking table
-- This will show which airlines have the fewest delays
SELECT 
    airline,                                    -- The airline name
    COUNT(*) AS total_flights,                  -- How many flights they had
    COUNT(CASE WHEN dep_delay > 0 THEN 1 END) AS delayed_departures,  -- How many were delayed
    ROUND(
        (COUNT(CASE WHEN dep_delay > 0 THEN 1 END) * 100.0) / COUNT(*),
        2
    ) AS departure_delay_percentage,            -- What percentage were delayed
    
    -- Give each airline a performance grade (like school grades!)
    CASE 
        WHEN (COUNT(CASE WHEN dep_delay > 0 THEN 1 END) * 100.0) / COUNT(*) <= 20 THEN 'Excellent'  -- A+ (≤20% delays)
        WHEN (COUNT(CASE WHEN dep_delay > 0 THEN 1 END) * 100.0) / COUNT(*) <= 30 THEN 'Good'      -- B (≤30% delays)
        WHEN (COUNT(CASE WHEN dep_delay > 0 THEN 1 END) * 100.0) / COUNT(*) <= 40 THEN 'Fair'      -- C (≤40% delays)
        WHEN (COUNT(CASE WHEN dep_delay > 0 THEN 1 END) * 100.0) / COUNT(*) <= 50 THEN 'Poor'      -- D (≤50% delays)
        ELSE 'Very Poor'                        -- F (>50% delays)
    END AS performance_rating
INTO airline_performance
FROM flight_data_optimized
GROUP BY airline 
HAVING COUNT(*) >= 50                          -- Only include airlines with enough data to be reliable
ORDER BY departure_delay_percentage ASC;       -- Sort from best (lowest delays) to worst

-- Let's see our airline rankings!
SELECT * FROM airline_performance ORDER BY departure_delay_percentage;


-- SECTION 4: ANALYZE MONTHLY DELAY PATTERNS

-- Remove any old version of this table
DROP TABLE IF EXISTS monthly_delay_trends_clean;

-- Create our monthly trends table
SELECT 
    fl_date,                                    -- The exact date of the flight
    EXTRACT(YEAR FROM fl_date) AS year,         -- Which year (2020, 2021, etc.)
    EXTRACT(MONTH FROM fl_date) AS month,       -- Which month (1-12)
    
    -- Convert month numbers to actual month names (easier to read!)
    CASE 
        WHEN EXTRACT(MONTH FROM fl_date) = 1 THEN 'January'
        WHEN EXTRACT(MONTH FROM fl_date) = 2 THEN 'February'
        WHEN EXTRACT(MONTH FROM fl_date) = 3 THEN 'March'
        WHEN EXTRACT(MONTH FROM fl_date) = 4 THEN 'April'
        WHEN EXTRACT(MONTH FROM fl_date) = 5 THEN 'May'
        WHEN EXTRACT(MONTH FROM fl_date) = 6 THEN 'June'
        WHEN EXTRACT(MONTH FROM fl_date) = 7 THEN 'July'
        WHEN EXTRACT(MONTH FROM fl_date) = 8 THEN 'August'
        WHEN EXTRACT(MONTH FROM fl_date) = 9 THEN 'September'
        WHEN EXTRACT(MONTH FROM fl_date) = 10 THEN 'October'
        WHEN EXTRACT(MONTH FROM fl_date) = 11 THEN 'November'
        ELSE 'December'
    END AS month_name,
    
    airline,                                    -- Which airline
    origin_city,                                -- Starting city
    dest,                                       -- Destination city
    dep_delay,                                  -- Departure delay (minutes)
    arr_delay,                                  -- Arrival delay (minutes)
    delay_due_carrier_minutes,                  -- Airline-caused delays
    delay_due_weather_minutes,                  -- Weather-caused delays
    delay_due_nas_minutes,                      -- Air traffic control delays
    delay_due_security_minutes,                 -- Security delays
    delay_due_late_aircraft_minutes             -- Previous flight delays
INTO monthly_delay_trends_clean
FROM flights_delay
WHERE 
    -- Only recent data (2020-2023)
    EXTRACT(YEAR FROM fl_date) >= 2020
    
    -- Only meaningful delays (>10 minutes)
    AND (dep_delay > 10 OR arr_delay > 10)
    
    --  Only major airlines
    AND airline IN (
        'Southwest Airlines Co.',
        'Delta Air Lines Inc.', 
        'American Airlines Inc.',
        'United Air Lines Inc.',
        'JetBlue Airways',
        'Alaska Airlines Inc.',
        'Spirit Air Lines',
        'Frontier Airlines Inc.',
        'Allegiant Air',
        'Hawaiian Airlines Inc.',
        'SkyWest Airlines Inc.',
        'Republic Airline'
    );

-- check how much monthly data we have
SELECT COUNT(*) as monthly_rows FROM monthly_delay_trends_clean;

-- SECTION 5: ANALYZE YEARLY DELAY TRENDS
 
-- Remove any old version of this table
DROP TABLE IF EXISTS yearly_delay_overview;

-- Create our yearly comparison table
-- This will show how delays have changed from year to year
SELECT 
    EXTRACT(YEAR FROM fl_date) AS year,         -- Which year (2020, 2021, 2022, 2023)
    
    -- Calculate the average delay times for each year
    -- (This gives us the "typical" delay length for each year)
    ROUND(AVG(dep_delay), 2) AS yearly_avg_dep_delay,    -- Average departure delay (minutes)
    ROUND(AVG(arr_delay), 2) AS yearly_avg_arr_delay,    -- Average arrival delay (minutes)
    
    -- Count the total flights and delayed flights
    COUNT(*) AS total_flights,                          -- How many flights total
    COUNT(CASE WHEN dep_delay > 0 THEN 1 END) AS delayed_flights,  -- How many were delayed
    
    -- Calculate what percentage of flights were delayed each year
    ROUND(
        (COUNT(CASE WHEN dep_delay > 0 THEN 1 END) * 100.0) / COUNT(*),
        2
    ) AS yearly_delay_percentage                        -- Percentage of flights delayed
INTO yearly_delay_overview
FROM flights_delay
WHERE 
    -- Only recent years (2020-2023)
    EXTRACT(YEAR FROM fl_date) >= 2020
    
    --  Only meaningful delays (>10 minutes)
    AND (dep_delay > 10 OR arr_delay > 10)
    
    -- Only major airlines
    AND airline IN (
        'Southwest Airlines Co.',
        'Delta Air Lines Inc.', 
        'American Airlines Inc.',
        'United Air Lines Inc.',
        'JetBlue Airways',
        'Alaska Airlines Inc.',
        'Spirit Air Lines',
        'Frontier Airlines Inc.',
        'Allegiant Air',
        'Hawaiian Airlines Inc.',
        'SkyWest Airlines Inc.',
        'Republic Airline'
    )
GROUP BY EXTRACT(YEAR FROM fl_date)             -- Group all data by year
ORDER BY year;                                  -- Sort chronologically

-- Let's see our yearly trends!
SELECT * FROM yearly_delay_overview ORDER BY year;


-- SECTION 6: EXPORT DATA FOR TABLEAU DASHBOARD

--  Export Chart 1: Airline Performance Rankings
-- This creates a file with airline rankings and performance grades
SELECT * FROM airline_performance;

-- Export Chart 2: Monthly Delay Trends  
-- This creates a file with delay patterns by month and year
SELECT * FROM monthly_delay_trends_clean;

-- Export Chart 3: Yearly Overview
-- This creates a file with year-over-year delay comparisons
SELECT * FROM yearly_delay_overview;



-- ✅ SECTION 7: CHECK THAT EVERYTHING WORKED
--
-- 
--

-- Check how many rows we have in each table

SELECT 
    'airline_performance' as table_name, COUNT(*) as rows
FROM airline_performance
UNION ALL
SELECT 
    'monthly_delay_trends_clean' as table_name, COUNT(*) as rows
FROM monthly_delay_trends_clean
UNION ALL
SELECT 
    'yearly_delay_overview' as table_name, COUNT(*) as rows
FROM yearly_delay_overview;

--  Check the range of our data (min and max values)
SELECT 
    'airline_performance' as table_name,
    MIN(departure_delay_percentage) as min_delay_pct,
    MAX(departure_delay_percentage) as max_delay_pct
FROM airline_performance
UNION ALL
SELECT 
    'yearly_delay_overview' as table_name,
    MIN(yearly_avg_dep_delay) as min_delay_min,
    MAX(yearly_avg_dep_delay) as max_delay_min
FROM yearly_delay_overview;

-- 
-- SECTION 8: TROUBLESHOOTING (IF SOMETHING GOES WRONG)
-- 
-- If you get errors when running the script, use these queries to figure out what's wrong
-- Think of this as your "first aid kit" for debugging!

--  Check if your main table exists and has data

SELECT COUNT(*) FROM flights_delay;

--  Check what columns your table has and their data types

SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'flights_delay' 
AND column_name IN ('fl_date', 'airline', 'dep_delay', 'arr_delay');

--  Check for missing data (NULL values)
SELECT 
    COUNT(*) as total_rows,
    COUNT(fl_date) as non_null_dates,
    COUNT(airline) as non_null_airlines,
    COUNT(dep_delay) as non_null_dep_delays,
    COUNT(arr_delay) as non_null_arr_delays
FROM flights_delay;

--  Check what date range the data covers

SELECT 
    MIN(fl_date) as earliest_date,
    MAX(fl_date) as latest_date
FROM flights_delay;





