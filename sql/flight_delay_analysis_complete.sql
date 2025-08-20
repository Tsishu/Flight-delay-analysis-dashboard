
-- FLIGHT DELAY ANALYSIS DASHBOARD

-- CREATE  FLIGHT DATA TABLE

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

-- CREATE AIRLINE PERFORMANCE TABLE (Chart 1)

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


-- CREATE MONTHLY TRENDS TABLE (Chart 2)

-- Create a monthly trends table with proper month names for Chart 2
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

-- CREATE YEARLY OVERVIEW TABLE (Chart 3)

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










