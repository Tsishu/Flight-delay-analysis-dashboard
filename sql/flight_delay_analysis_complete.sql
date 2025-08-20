-- =====================================================
-- FLIGHT DELAY ANALYSIS DASHBOARD - COMPLETE PROJECT
-- =====================================================
-- This file contains all SQL code used to create the data for the Tableau dashboard
-- Created for: Flight Delay Analysis 2020-2023
-- Dashboard includes: Airline Performance, Monthly Trends, Yearly Overview
-- =====================================================

-- =====================================================
-- SECTION 1: EXPLORE ORIGINAL DATA STRUCTURE
-- =====================================================

-- Check what tables exist in your database
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';

-- Check the structure of your main flights table
SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'flights_delay';

-- Check the size of your original data
SELECT COUNT(*) as total_rows FROM flights_delay;

-- =====================================================
-- SECTION 2: CREATE OPTIMIZED FLIGHT DATA TABLE
-- =====================================================

-- Drop if exists
DROP TABLE IF EXISTS flight_data_optimized;

-- Create optimized table with smart filters (reduces from 1M+ to ~428K rows)
CREATE TABLE flight_data_optimized AS
SELECT 
    fl_date,
    EXTRACT(YEAR FROM fl_date) AS year,
    EXTRACT(MONTH FROM fl_date) AS month,
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
    -- Keep only 2020-2023 (most relevant)
    EXTRACT(YEAR FROM fl_date) >= 2020
    -- Keep only flights with meaningful delays (>10 minutes)
    AND (dep_delay > 10 OR arr_delay > 10)
    -- Keep only major airlines (top 12 by volume)
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

-- Verify the optimization worked
SELECT COUNT(*) as optimized_rows FROM flight_data_optimized;

-- =====================================================
-- SECTION 3: CREATE AIRLINE PERFORMANCE TABLE (Chart 1)
-- =====================================================

-- Drop if exists
DROP TABLE IF EXISTS airline_performance;

-- Create airline performance table for Chart 1
CREATE TABLE airline_performance AS
SELECT 
    airline,
    COUNT(*) AS total_flights,
    COUNT(CASE WHEN dep_delay > 0 THEN 1 END) AS delayed_departures,
    ROUND(
        (COUNT(CASE WHEN dep_delay > 0 THEN 1 END) * 100.0) / COUNT(*),
        2
    ) AS departure_delay_percentage,
    CASE 
        WHEN (COUNT(CASE WHEN dep_delay > 0 THEN 1 END) * 100.0) / COUNT(*) <= 20 THEN 'Excellent'
        WHEN (COUNT(CASE WHEN dep_delay > 0 THEN 1 END) * 100.0) / COUNT(*) <= 30 THEN 'Good'
        WHEN (COUNT(CASE WHEN dep_delay > 0 THEN 1 END) * 100.0) / COUNT(*) <= 40 THEN 'Fair'
        WHEN (COUNT(CASE WHEN dep_delay > 0 THEN 1 END) * 100.0) / COUNT(*) <= 50 THEN 'Poor'
        ELSE 'Very Poor'
    END AS performance_rating
FROM flight_data_optimized
GROUP BY airline 
HAVING COUNT(*) >= 50
ORDER BY departure_delay_percentage ASC;

-- Verify airline performance data
SELECT * FROM airline_performance ORDER BY departure_delay_percentage;

-- =====================================================
-- SECTION 4: CREATE MONTHLY TRENDS TABLE (Chart 2)
-- =====================================================

-- Drop if exists
DROP TABLE IF EXISTS monthly_delay_trends_clean;

-- Create monthly trends table with proper month names for Chart 2
CREATE TABLE monthly_delay_trends_clean AS
SELECT 
    fl_date,
    EXTRACT(YEAR FROM fl_date) AS year,
    EXTRACT(MONTH FROM fl_date) AS month,
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

-- Verify monthly trends data
SELECT COUNT(*) as monthly_rows FROM monthly_delay_trends_clean;

-- =====================================================
-- SECTION 5: CREATE YEARLY OVERVIEW TABLE (Chart 3)
-- =====================================================

-- Drop if exists
DROP TABLE IF EXISTS yearly_delay_overview;

-- Create yearly overview table for Chart 3
CREATE TABLE yearly_delay_overview AS
SELECT 
    EXTRACT(YEAR FROM fl_date) AS year,
    -- Calculate TRUE yearly averages (not sum of monthly averages)
    ROUND(AVG(dep_delay), 2) AS yearly_avg_dep_delay,
    ROUND(AVG(arr_delay), 2) AS yearly_avg_arr_delay,
    COUNT(*) AS total_flights,
    COUNT(CASE WHEN dep_delay > 0 THEN 1 END) AS delayed_flights,
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
GROUP BY EXTRACT(YEAR FROM fl_date)
ORDER BY year;

-- Verify yearly overview data
SELECT * FROM yearly_delay_overview ORDER BY year;

-- =====================================================
-- SECTION 6: EXPORT TABLES TO CSV FOR TABLEAU
-- =====================================================

-- Export airline performance data (Chart 1)
COPY airline_performance TO 'C:\Users\Lenovo\Documents\Flights\airline_performance.csv' CSV HEADER;

-- Export monthly trends data (Chart 2)
COPY monthly_delay_trends_clean TO 'C:\Users\Lenovo\Documents\Flights\monthly_trends_clean.csv' CSV HEADER;

-- Export yearly overview data (Chart 3)
COPY yearly_delay_overview TO 'C:\Users\Lenovo\Documents\Flights\yearly_overview.csv' CSV HEADER;

-- =====================================================
-- SECTION 7: VERIFICATION QUERIES
-- =====================================================

-- Check final table sizes
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

-- Check data ranges
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

-- =====================================================
-- PROJECT SUMMARY
-- =====================================================
/*
This SQL file creates all the data needed for your Flight Delay Analysis Dashboard:

1. flight_data_optimized: Optimized from 1M+ to ~428K rows
2. airline_performance: Airline rankings with performance ratings
3. monthly_delay_trends_clean: Monthly trends with proper month names
4. yearly_delay_overview: Yearly averages for comparison

Dashboard Components:
- Chart 1: Airline Performance Ranking (horizontal bars)
- Chart 2: Monthly Trends by Year (line chart)
- Chart 3: Yearly Overview (vertical bars)
- Key Insights: Summary of main findings
- Interactive Filters: Year, Airline, Month

Data Period: 2020-2023
Focus: Major airlines with meaningful delays (>10 minutes)
Output: 3 CSV files ready for Tableau import

Your dashboard is now complete and professional!
*/
