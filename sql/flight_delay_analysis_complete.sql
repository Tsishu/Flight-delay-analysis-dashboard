-- =====================================================
-- FLIGHT DELAY ANALYSIS PROJECT
-- Created by: Atsushi Satomura
-- Date: August 20 2025
-- Purpose: Analyze US flight delays 2020-2023 for Tableau dashboard
-- =====================================================

-- First, let's create a clean dataset by filtering out unnecessary data
-- This reduces our dataset from over 1 million rows to about 428K rows
-- We only keep flights with meaningful delays (>10 min) and major airlines

CREATE TABLE flight_data_optimized AS
SELECT 
    fl_date,
    EXTRACT(YEAR FROM fl_date) AS year,        -- Extract year for analysis
    EXTRACT(MONTH FROM fl_date) AS month,      -- Extract month for trends
    airline,
    origin_city,
    dest,
    dep_delay,                                 -- Departure delay in minutes
    arr_delay,                                 -- Arrival delay in minutes
    delay_due_carrier_minutes,                 -- Airline-caused delays
    delay_due_weather_minutes,                 -- Weather-related delays
    delay_due_nas_minutes,                     -- National Air System delays
    delay_due_security_minutes,                -- Security-related delays
    delay_due_late_aircraft_minutes            -- Late aircraft delays
FROM csv_flight_data
WHERE 
    -- Focus on recent years (2020-2023) for relevant analysis
    EXTRACT(YEAR FROM fl_date) >= 2020
    -- Only include flights with significant delays (>10 min) to focus on problematic flights
    AND (dep_delay > 10 OR arr_delay > 10)
    -- Limit to major airlines that have enough data for meaningful analysis
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

-- Quick check to make sure our filtering worked
SELECT COUNT(*) as optimized_rows FROM flight_data_optimized;

-- =====================================================
-- CHART 1: AIRLINE PERFORMANCE RANKING
-- This table will show which airlines perform best/worst with delays
-- =====================================================

CREATE TABLE airline_performance AS
SELECT 
    airline,
    COUNT(*) AS total_flights,                 -- Total flights for each airline
    COUNT(CASE WHEN dep_delay > 0 THEN 1 END) AS delayed_departures,  -- Count of delayed flights
    -- Calculate delay percentage for each airline
    ROUND(
        (COUNT(CASE WHEN dep_delay > 0 THEN 1 END) * 100.0) / COUNT(*),
        2
    ) AS departure_delay_percentage,
    -- Create performance categories based on delay percentages
    -- This helps stakeholders quickly understand airline performance
    CASE 
        WHEN (COUNT(CASE WHEN dep_delay > 0 THEN 1 END) * 100.0) / COUNT(*) <= 20 THEN 'Excellent'
        WHEN (COUNT(CASE WHEN dep_delay > 0 THEN 1 END) * 100.0) / COUNT(*) <= 30 THEN 'Good'
        WHEN (COUNT(CASE WHEN dep_delay > 0 THEN 1 END) * 100.0) / COUNT(*) <= 40 THEN 'Fair'
        WHEN (COUNT(CASE WHEN dep_delay > 0 THEN 1 END) * 100.0) / COUNT(*) <= 50 THEN 'Poor'
        ELSE 'Very Poor'
    END AS performance_rating
FROM flight_data_optimized
GROUP BY airline 
HAVING COUNT(*) >= 50                          -- Only include airlines with enough data
ORDER BY departure_delay_percentage ASC;       -- Best performers first

-- Let's see how our airline performance table looks
SELECT * FROM airline_performance ORDER BY departure_delay_percentage;

-- =====================================================
-- CHART 2: MONTHLY TRENDS BY YEAR
-- This will show seasonal patterns and year-over-year trends
-- =====================================================

CREATE TABLE monthly_delay_trends_clean AS
SELECT 
    fl_date,
    EXTRACT(YEAR FROM fl_date) AS year,
    EXTRACT(MONTH FROM fl_date) AS month,
    -- Convert month numbers to readable names for better visualization
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
    airline,
    origin_city,
    dest,
    dep_delay,
    arr_delay,
    delay_due_carrier_minutes,
    delay_due_weather_minutes,
    delay_due_nas_minutes,
    delay_due_security_minutes,
    delay_due_late_aircraft_minutes
FROM csv_flight_data
WHERE 
    EXTRACT(YEAR FROM fl_date) >= 2020
    AND (dep_delay > 10 OR arr_delay > 10)
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

-- Check how many rows we have for monthly analysis
SELECT COUNT(*) as monthly_rows FROM monthly_delay_trends_clean;

-- =====================================================
-- CHART 3: YEARLY OVERVIEW COMPARISON
-- This shows how delays changed year by year
-- =====================================================

CREATE TABLE yearly_delay_overview AS
SELECT 
    EXTRACT(YEAR FROM fl_date) AS year,
    -- Calculate average delays per year (not sum of monthly averages)
    ROUND(AVG(dep_delay), 2) AS yearly_avg_dep_delay,    -- Average departure delays
    ROUND(AVG(arr_delay), 2) AS yearly_avg_arr_delay,    -- Average arrival delays
    COUNT(*) AS total_flights,                            -- Total flights per year
    COUNT(CASE WHEN dep_delay > 0 THEN 1 END) AS delayed_flights,  -- Count of delayed flights
    -- Calculate what percentage of flights were delayed each year
    ROUND(
        (COUNT(CASE WHEN dep_delay > 0 THEN 1 END) * 100.0) / COUNT(*),
        2
    ) AS yearly_delay_percentage
FROM csv_flight_data
WHERE 
    EXTRACT(YEAR FROM fl_date) >= 2020
    AND (dep_delay > 10 OR arr_delay > 10)
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
GROUP BY EXTRACT(YEAR FROM fl_date)                       -- Group by year to get yearly averages
ORDER BY year;                                            -- Chronological order

-- Let's see our yearly summary data
SELECT * FROM yearly_delay_overview ORDER BY year;

-- =====================================================
-- SUMMARY: We now have 3 tables ready for Tableau:
-- 1. airline_performance - for ranking chart
-- 2. monthly_delay_trends_clean - for trend analysis
-- 3. yearly_delay_overview - for year comparison
-- =====================================================
