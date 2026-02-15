 USE nedex;
SHOW TABLES;
 
describe hr;

-- ##############################################################
-- 3️⃣ Change emp_id column if needed
-- ##############################################################
ALTER TABLE hr
CHANGE COLUMN ï»¿id emp_id VARCHAR(20) NULL;

-- ##############################################################
-- 4️⃣ Convert birthdate to proper DATE
-- ##############################################################
ALTER TABLE hr MODIFY COLUMN birthdate VARCHAR(20);

UPDATE hr
SET birthdate = CASE
    WHEN birthdate IS NULL OR TRIM(birthdate) = '' THEN NULL
    -- MM/DD/YYYY or M/D/YYYY
    WHEN birthdate LIKE '%/%' THEN STR_TO_DATE(birthdate, '%c/%e/%Y')
    -- MM-DD-YYYY or M-D-YYYY
    WHEN birthdate LIKE '%-%-%' AND LENGTH(birthdate) >= 8 THEN STR_TO_DATE(birthdate, '%c-%e-%Y')
    -- MM-DD-YY or M-D-YY
    WHEN birthdate LIKE '%-%-%' AND LENGTH(birthdate) <= 8 THEN STR_TO_DATE(birthdate, '%c-%e-%y')
    ELSE NULL
END;

ALTER TABLE hr MODIFY COLUMN birthdate DATE;

-- ##############################################################
-- 5️⃣ Convert hire_date to proper DATE
-- ##############################################################
ALTER TABLE hr MODIFY COLUMN hire_date VARCHAR(20);

UPDATE hr
SET hire_date = CASE
    WHEN hire_date IS NULL OR TRIM(hire_date) = '' THEN NULL
    WHEN hire_date LIKE '%/%' THEN STR_TO_DATE(hire_date, '%c/%e/%Y')
    WHEN hire_date LIKE '%-%-%' THEN STR_TO_DATE(hire_date, '%c-%e-%Y')
    ELSE NULL
END;

ALTER TABLE hr MODIFY COLUMN hire_date DATE;

-- ##############################################################
-- 6️⃣ Convert termdate to proper DATE
-- ##############################################################
ALTER TABLE hr MODIFY COLUMN termdate VARCHAR(30);

UPDATE hr
SET termdate = NULL
WHERE TRIM(termdate) = '' OR termdate = '0000-00-00';

UPDATE hr
SET termdate = DATE(STR_TO_DATE(termdate, '%Y-%m-%d %H:%i:%s UTC'))
WHERE termdate IS NOT NULL;

ALTER TABLE hr MODIFY COLUMN termdate DATE;

-- ##############################################################
-- 7️⃣ Add age column and calculate age safely
-- ##############################################################
ALTER TABLE hr ADD COLUMN age INT;

UPDATE hr
SET age = CASE
    WHEN birthdate IS NULL THEN NULL
    WHEN birthdate > CURDATE() THEN NULL
    ELSE TIMESTAMPDIFF(YEAR, birthdate, CURDATE())
END;



- ################### Youngest and oldest active employees ############################# -- 

SELECT MIN(age) AS youngest, MAX(age) AS oldest
FROM hr
WHERE age >= 18
  AND termdate IS NULL;

-- 1. What is the gender breakdown of employees in the company?
SELECT gender, COUNT(*) AS count
FROM hr
WHERE age >= 18 
  AND termdate IS NULL
GROUP BY gender;

-- 2. What is the race/ethnicity breakdown of employees in the company?

SELECT  race, count(*) AS count FROM hr 
WHERE age >= 18 
  AND termdate IS NULL
GROUP BY race
ORDER BY count DESC ;


-- 3. What is the age distribution of employees in the company?
SELECT CASE 
        WHEN age BETWEEN 18 AND 24 THEN '18-24'
        WHEN age BETWEEN 25 AND 34 THEN '25-34'
        WHEN age BETWEEN 35 AND 44 THEN '35-44'
        WHEN age BETWEEN 45 AND 54 THEN '45-54'
        WHEN age BETWEEN 55 AND 64 THEN '55-64'
        WHEN age >= 65 THEN '65+'
        ELSE 'Unknown'
       END AS age_group, gender,
       COUNT(*) AS count
FROM hr
GROUP BY age_group, gender
ORDER BY age_group, gender ASC;
SELECT CASE 
        WHEN age BETWEEN 18 AND 24 THEN '18-24'
        WHEN age BETWEEN 25 AND 34 THEN '25-34'
        WHEN age BETWEEN 35 AND 44 THEN '35-44'
        WHEN age BETWEEN 45 AND 54 THEN '45-54'
        WHEN age BETWEEN 55 AND 64 THEN '55-64'
        WHEN age >= 65 THEN '65+'
        ELSE 'Unknown'
       END AS age_group, gender,
       COUNT(*) AS count
FROM hr
GROUP BY age_group, gender
ORDER BY age_group, gender ASC;

-- 4. How many employees work at headquarters versus remote locations?
SELECT  location,  COUNT(*) AS count FROM hr
WHERE age >= 18
  AND termdate IS NULL
GROUP BY  location 
ORDER BY count DESC;


-- 5. What is the average length of employment for employees who have been terminated?
SELECT 
    ROUND(AVG(DATEDIFF(termdate, hire_date)) / 365, 0) AS average_length_employment
FROM hr
WHERE age >= 18
  AND termdate IS NOT NULL
  AND termdate <= CURDATE()
   ;


-- 6. How does the gender distribution vary across departments and job titles?
SELECT 
 department, gender, count(*) as count
FROM hr
WHERE age >= 18
  AND termdate IS NOT NULL
  AND termdate <= CURDATE()
  GROUP BY department,gender
  ORDER BY department ASC;

-- 7. What is the distribution of job titles across the company?
SELECT jobtitle , count(*) as count
FROM hr
WHERE age >= 18
  AND termdate IS NOT NULL
  AND termdate <= CURDATE()

  GROUP BY jobtitle 
  ORDER BY jobtitle DESC;

-- 8. Which department has the highest turnover rate?
SELECT  
    department,
    total_count,
    terminated_count,
    ROUND(terminated_count / total_count, 3) AS termination_rate
FROM (
    SELECT  
        department,
        COUNT(*) AS total_count,
        SUM(CASE 
                WHEN termdate IS NOT NULL 
                     AND termdate <= CURDATE() 
                THEN 1 
                ELSE 0 
            END) AS terminated_count
    FROM hr
    WHERE age >= 18
    GROUP BY department
) AS subquery
ORDER BY termination_rate DESC;


-- 9. What is the distribution of employees across locations by city and state?
SELECT  location_state, count(*) AS count FROM hr
WHERE age >= 18
  AND termdate IS NOT NULL
  GROUP BY location_state
  ORDER BY count desc;
  ;

-- 10. How has the company's employee count changed over time based on hire and term dates?
SELECT 
    year,
    hires,
    terminations,
    hires - terminations AS net_change,
    ROUND((hires - terminations) / hires * 100, 2) AS net_change_percent
FROM (
    SELECT 
        YEAR(hire_date) AS year,
        COUNT(*) AS hires,
        SUM(CASE 
                WHEN termdate IS NOT NULL 
                     AND termdate <= CURDATE()
                THEN 1 
                ELSE 0 
            END) AS terminations
    FROM hr
    WHERE age >= 18
      AND hire_date IS NOT NULL
    GROUP BY YEAR(hire_date)
) AS subquery
ORDER BY year ASC;

-- 11. What is the tenure distribution for each department?
SELECT 
    department,
    ROUND(AVG(TIMESTAMPDIFF(YEAR, hire_date, termdate)), 0) AS avg_tenure_years
FROM hr
WHERE age >= 18
  AND hire_date IS NOT NULL
  AND termdate IS NOT NULL
  AND termdate <= CURDATE()
GROUP BY department
ORDER BY avg_tenure_years DESC;



