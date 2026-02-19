-- Healthcare Analytics Project SQL Queries
-- These queries were used for data analysis and dashboard preparation

use hospital_db;
-- OBJECTIVE 1: ENCOUNTERS OVERVIEW

-- a. How many total encounters occurred each year?
SELECT 
    YEAR(START) AS encounter_year,
    COUNT(*) AS total_encounters
FROM encounters
GROUP BY YEAR(START)
ORDER BY encounter_year;

-- b. For each year, what percentage of all encounters belonged to each encounter class
-- (ambulatory, outpatient, wellness, urgent care, emergency, and inpatient)?
SELECT 
    YEAR(START) AS encounter_year,
    ENCOUNTERCLASS,
    COUNT(*) * 100.0 / 
        SUM(COUNT(*)) OVER (PARTITION BY YEAR(START)) 
        AS percentage_of_encounters
FROM encounters
GROUP BY YEAR(START), ENCOUNTERCLASS
ORDER BY encounter_year, ENCOUNTERCLASS;

-- c. What percentage of encounters were over 24 hours versus under 24 hours?
SELECT 
    CASE 
        WHEN DATEDIFF(day, [START], [STOP]) >= 1 
        THEN 'Over 24 Hours'
        ELSE 'Under 24 Hours'
    END AS duration_group,

    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS percentage

FROM encounters

GROUP BY 
    CASE 
        WHEN DATEDIFF(day, [START], [STOP]) >= 1 
        THEN 'Over 24 Hours'
        ELSE 'Under 24 Hours'
    END;

-- OBJECTIVE 2: COST & COVERAGE INSIGHTS

-- a. How many encounters had zero payer coverage, and what percentage of total encounters does this represent?
SELECT 
    COUNT(*) AS zero_coverage_encounters,
    COUNT(*) * 100.0 / (SELECT COUNT(*) FROM encounters) AS percentage_of_total
FROM encounters
WHERE PAYER_COVERAGE = 0;

-- b. What are the top 10 most frequent procedures performed and the average base cost for each?
SELECT TOP 10
    DESCRIPTION,
    COUNT(*) AS procedure_count,
    AVG(BASE_COST) AS avg_base_cost
FROM procedures
GROUP BY DESCRIPTION
ORDER BY procedure_count DESC;

-- c. What are the top 10 procedures with the highest average base cost and the number of times they were performed?
SELECT TOP 10
    DESCRIPTION,
    COUNT(*) AS times_performed,
    AVG(BASE_COST) AS avg_base_cost
FROM procedures
GROUP BY DESCRIPTION
ORDER BY avg_base_cost DESC;

-- d. What is the average total claim cost for encounters, broken down by payer?
SELECT 
    PAYER,
    AVG(TOTAL_CLAIM_COST) AS avg_total_claim_cost
FROM encounters
WHERE TOTAL_CLAIM_COST IS NOT NULL
GROUP BY PAYER
ORDER BY avg_total_claim_cost DESC;

-- OBJECTIVE 3: PATIENT BEHAVIOR ANALYSIS

-- a. How many unique patients were admitted each quarter over time?
SELECT 
    YEAR(START) AS encounter_year,
    DATEPART(QUARTER, START) AS encounter_quarter,
    COUNT(DISTINCT PATIENT) AS unique_patients
FROM encounters
GROUP BY 
    YEAR(START),
    DATEPART(QUARTER, START)
ORDER BY 
    encounter_year,
    encounter_quarter;

-- b. How many patients were readmitted within 30 days of a previous encounter?
WITH patient_visits AS (
    SELECT
        PATIENT,
        START,
        LAG(START) OVER (PARTITION BY PATIENT ORDER BY START) AS previous_visit
    FROM encounters
)

SELECT 
    COUNT(*) AS readmissions_within_30_days
FROM patient_visits
WHERE previous_visit IS NOT NULL
AND DATEDIFF(DAY, previous_visit, START) <= 30;

-- c. Which patients had the most readmissions?
WITH patient_visits AS (
    SELECT
        PATIENT,
        START,
        LAG(START) OVER (PARTITION BY PATIENT ORDER BY START) AS previous_visit
    FROM encounters
),
readmissions AS (
    SELECT
        PATIENT
    FROM patient_visits
    WHERE previous_visit IS NOT NULL
      AND DATEDIFF(DAY, previous_visit, START) <= 30
)

SELECT TOP 10
    PATIENT,
    COUNT(*) AS readmission_count
FROM readmissions
GROUP BY PATIENT
ORDER BY readmission_count DESC;