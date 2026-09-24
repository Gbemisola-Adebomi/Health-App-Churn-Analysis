CREATE TABLE health_app_raw(
user_id INTEGER,
age INTEGER,
gender VARCHAR(10),
region VARCHAR(50),
bmi NUMERIC(5,2),
plan_type VARCHAR(20),
monthly_fee NUMERIC(8,2),
discount_rate NUMERIC(5,2),
tenure_days INTEGER,
auto_renew BOOLEAN,
last_payment_success BOOLEAN,
weekly_sessions NUMERIC(5,1),
avg_session_minutes NUMERIC(6,1),
workout_completion_rate NUMERIC(5,2),
diet_log_adherence NUMERIC(5,2),
sleep_tracking_usage NUMERIC(5,2),
coaching_messages_per_week NUMERIC(5,1),
community_posts_per_month NUMERIC(6,1),
device_type VARCHAR(50),
wearable_connected BOOLEAN,
push_enabled BOOLEAN,
churn_within_6m BOOLEAN
);

SELECT * FROM  health_app_raw;

--confirming_the_data
SELECT * FROM  health_app_raw LIMIT 10;

SELECT COUNT(*) AS total_rows FROM  health_app_raw;

--Parent table: 1row per user
CREATE TABLE users(
user_id INTEGER PRIMARY KEY,
age INTEGER,
gender VARCHAR(10),
region VARCHAR(50),
bmi NUMERIC(5,2)
);

--subscription billing table
CREATE TABLE subscriptions(
subscription_id VARCHAR(9) PRIMARY KEY,
user_id INTEGER UNIQUE,
plan_type VARCHAR(20),
monthly_fee NUMERIC(8,2),
discount_rate NUMERIC(5,2),
tenure_days INTEGER,
auto_renew BOOLEAN,
last_payment_success BOOLEAN,
FOREIGN KEY (user_id) REFERENCES users(user_id)
);

--platform usage and behavoiur table
CREATE TABLE engagement(
engagement_id VARCHAR(9) PRIMARY KEY,
user_id INTEGER UNIQUE,
weekly_sessions NUMERIC(5,1),
avg_session_minutes NUMERIC(6,1),
workout_completion_rate NUMERIC(5,2),
diet_log_adherence NUMERIC(5,2),
sleep_tracking_usage NUMERIC(5,2),
coaching_messages_per_week NUMERIC(5,1),
community_posts_per_month NUMERIC(6,1),
device_type VARCHAR(50),
wearable_connected BOOLEAN,
push_enabled BOOLEAN,
FOREIGN KEY (user_id) REFERENCES users(user_id)
);

--churn outcome table (Target Variable)
CREATE TABLE churn_status(
churn_id VARCHAR(9),
user_id INTEGER UNIQUE,
churn_within_6m BOOLEAN,
FOREIGN KEY (user_id) REFERENCES users(user_id)
);


--create autoincrement sequence
CREATE SEQUENCE  subscriptions_seq START 1;

CREATE SEQUENCE  engagement_seq START 1;

CREATE SEQUENCE  churn_seq START 1;

--sequence verification
SELECT  sequencename FROM pg.sequenes WHERE schemaname = 'public';

INSERT INTO users(user_id, age, gender,region,bmi )
SELECT 
user_id, age, gender,region,bmi
FROM health_app_raw;

SELECT * FROM users;

INSERT INTO subscriptions(
                  subscription_id, user_id, plan_type, monthly_fee,
                discount_rate, tenure_days, auto_renew, last_payment_success)
SELECT
'S' || LPAD(nextval('subscriptions_seq')::text,8,'0'),
user_id,
plan_type,
monthly_fee,
discount_rate, tenure_days, auto_renew, last_payment_success
FROM health_app_raw;

SELECT * FROM subscriptions;

--'S' || LPAD(nextval('subscriptions_seq')::text,8,'0'), its saying
--Get the next subscription number → turn it into text → make it 8 digits by adding zeros to the left → put S in front.


INSERT INTO engagement(
engagement_id,
user_id,
weekly_sessions,
avg_session_minutes,
workout_completion_rate,
diet_log_adherence,
sleep_tracking_usage,
coaching_messages_per_week,
community_posts_per_month,
device_type,
wearable_connected,
push_enabled
)
SELECT 
'E'|| LPAD(nextval('engagement_seq'):: text, 8,'0'),
user_id,
weekly_sessions,
avg_session_minutes,
workout_completion_rate,
diet_log_adherence,
sleep_tracking_usage,
coaching_messages_per_week,
community_posts_per_month,
device_type,
wearable_connected,
push_enabled FROM health_app_raw; 

SELECT * FROM engagement;

INSERT INTO churn_status(
churn_id ,user_id,churn_within_6m )
SELECT 
'C'||LPAD(nextval('churn_seq')::text, 8,'0'),
user_id,
churn_within_6m 
FROM health_app_raw; 

SELECT * FROM churn_status;
--unique users should equal unique total rows
SELECT COUNT (user_id) AS unique_users FROM health_app_raw;

-- How many users are in each plan?
SELECT
    plan_type,
    COUNT(*)AS total_users,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM health_app_raw), 2) AS pct
FROM health_app_raw
GROUP BY plan_type
ORDER BY total_users DESC;

--users per region
SELECT region, COUNT(*)AS total_users,
ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM health_app_raw),2) AS pct
FROM health_app_raw
GROUP BY region
ORDER BY total_users DESC;

--users by device_type
SELECT device_type, COUNT(*) AS total_users,
ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM health_app_raw),2) AS pct
FROM health_app_raw
GROUP BY device_type
ORDER BY total_users DESC;

-- How many users churned vs stayed?
SELECT
    churn_within_6m,
    COUNT(*) AS total_users,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM health_app_raw), 2) AS pct
FROM health_app_raw
GROUP BY churn_within_6m;

-- Check min/max/avg for all key numeric columns
SELECT
    MIN(age)                     AS min_age,
    MAX(age)                     AS max_age,
    ROUND(AVG(age), 1)           AS avg_age,
    MIN(bmi)                     AS min_bmi,
    MAX(bmi)                     AS max_bmi,
    ROUND(AVG(bmi), 2)           AS avg_bmi,
    MIN(weekly_sessions)         AS min_sessions,
    MAX(weekly_sessions)         AS max_sessions,
    ROUND(AVG(weekly_sessions), 1) AS avg_sessions,
    MIN(tenure_days)             AS min_tenure,
    MAX(tenure_days)             AS max_tenure,
	ROUND(AVG(tenure_days),1)    AS avg_tenure_days
FROM health_app_raw;

--missing value audit
-- Full NULL audit across all columns in one result
SELECT
    COUNT(*) FILTER (WHERE user_id IS NULL)                  AS missing_user_id,
    COUNT(*) FILTER (WHERE age IS NULL)                      AS missing_age,
    COUNT(*) FILTER (WHERE gender IS NULL)                   AS missing_gender,
    COUNT(*) FILTER (WHERE region IS NULL)                   AS missing_region,
    COUNT(*) FILTER (WHERE bmi IS NULL)                      AS missing_bmi,
    COUNT(*) FILTER (WHERE plan_type IS NULL)                AS missing_plan_type,
    COUNT(*) FILTER (WHERE monthly_fee IS NULL)              AS missing_monthly_fee,
    COUNT(*) FILTER (WHERE discount_rate IS NULL)            AS missing_discount_rate,
    COUNT(*) FILTER (WHERE tenure_days IS NULL)              AS missing_tenure_days,
    COUNT(*) FILTER (WHERE auto_renew IS NULL)               AS missing_auto_renew,
    COUNT(*) FILTER (WHERE last_payment_success IS NULL)     AS missing_last_payment,
    COUNT(*) FILTER (WHERE weekly_sessions IS NULL)          AS missing_weekly_sessions,
    COUNT(*) FILTER (WHERE avg_session_minutes IS NULL)      AS missing_avg_session_min,
    COUNT(*) FILTER (WHERE workout_completion_rate IS NULL)  AS missing_workout_rate,
    COUNT(*) FILTER (WHERE diet_log_adherence IS NULL)       AS missing_diet_log,
    COUNT(*) FILTER (WHERE sleep_tracking_usage IS NULL)     AS missing_sleep_tracking,
    COUNT(*) FILTER (WHERE coaching_messages_per_week IS NULL) AS missing_coaching,
    COUNT(*) FILTER (WHERE community_posts_per_month IS NULL)  AS missing_community,
    COUNT(*) FILTER (WHERE device_type IS NULL)              AS missing_device_type,
    COUNT(*) FILTER (WHERE wearable_connected IS NULL)       AS missing_wearable,
    COUNT(*) FILTER (WHERE push_enabled IS NULL)             AS missing_push,
    COUNT(*) FILTER (WHERE churn_within_6m IS NULL)          AS missing_churn
FROM health_app_raw;


--duplicate users i.e user i.d that appers more than once
SELECT user_id ,COUNT(*) AS duplicate_users FROM health_app_raw
GROUP BY user_id
HAVING COUNT(*) > 1;

--Our missing values bmi & community post
--MEAN will be used to replace the missing feilds because they are continuous values

--FOR BMI
SELECT ROUND(AVG(bmi),2) AS avg_bmi
FROM users
WHERE bmi IS NOT NULL;

--For community_post_month
	SELECT ROUND(AVG (community_posts_per_month),1) AS avg_community_post
	FROM health_app_raw 
	WHERE community_posts_per_month IS NOT NULL;

--INPUTING AVERAGE TO UPDATE MISSING values
-- Replace NULL values with the dataset average
--FOR BMI
UPDATE users
SET bmi=(SELECT ROUND(AVG(bmi),2) AS avg_bmi
FROM users 
WHERE bmi IS NOT NULL)
WHERE bmi IS NULL;

select * from users;

--for commumity posts per months
UPDATE engagement SET community_posts_per_month = (
    SELECT ROUND(AVG(community_posts_per_month), 1)
    FROM engagement
    WHERE community_posts_per_month IS NOT NULL
)
WHERE community_posts_per_month IS NULL;

SELECT COUNT(*) FILTER (WHERE bmi IS NULL) AS remaining_null_bmi
FROM users;

SELECT COUNT(*) FILTER (WHERE community_posts_per_month IS NULL) AS remaining_nulls
FROM engagement;

--validation
-- Validate gender values
SELECT gender, COUNT(*) AS total FROM health_app_raw GROUP BY gender ORDER BY total DESC;

-- Validate region values
SELECT region, COUNT(*) AS total FROM health_app_raw GROUP BY region ORDER BY total DESC;

-- Validate plan_type values
SELECT plan_type, COUNT(*) AS total FROM health_app_raw GROUP BY plan_type ORDER BY total DESC;

-- Validate device_type values
SELECT device_type, COUNT(*) AS total FROM health_app_raw GROUP BY device_type ORDER BY total DESC;


SELECT * FROM churn_status;

--Answering our 7 key question
--Q1 --what is our overall churn rate
SELECT 
 COUNT (*) AS total_users,
 SUM (CASE WHEN c.churn_within_6m = TRUE THEN 1 ELSE 0 END) AS churned_users,
 SUM (CASE WHEN c.churn_within_6m = FALSE THEN 1 ELSE 0 END) AS retained_users,
 SUM (CASE WHEN c.churn_within_6m = TRUE THEN 1 ELSE 0 END) *100 / COUNT(*) AS churn_rate
 FROM users u
 JOIN churn_status c
 ON u.user_id = c.user_id;

 
 --Q2 --which subscription plan has the highest churn rate?

 SELECT 
 s.plan_type,
 COUNT (*) AS total_users,
 SUM (CASE WHEN c.churn_within_6m = TRUE THEN 1 ELSE 0 END) AS churned_users,
ROUND( SUM (CASE WHEN c.churn_within_6m = TRUE THEN 1 ELSE 0 END) *100.0 / COUNT(*),2) AS churn_rate_pct,
ROUND( SUM ( CASE WHEN c.churn_within_6m = TRUE THEN 1 ELSE 0 END ) * 100.0 /
             (SELECT COUNT (*) FROM churn_status WHERE churn_within_6m = TRUE),2) AS share_of_total_churn_pct
 FROM subscriptions s
 JOIN churn_status c
 ON s.user_id = c.user_id
GROUP BY s.plan_type
ORDER BY  share_of_total_churn_pct DESC;

--Q3 How does churn differ that geographic region?
SELECT 
u.region,
COUNT (*) AS total_users,
SUM( CASE WHEN c.churn_within_6m = TRUE THEN 1 ELSE 0 END) AS churned_users,
ROUND( 
SUM( CASE WHEN c.churn_within_6m = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT (*),2) AS churn_rate_pct,
ROUND(
SUM ( CASE WHEN c.churn_within_6m = TRUE THEN 1 ELSE 0 END) * 100.0/
(SELECT COUNT(*) FROM churn_status WHERE churn_within_6m = TRUE),2) AS share_of_total_churn_pct
FROM users u
JOIN churn_status c
ON u.user_id = c.user_id
GROUP BY region
ORDER BY share_of_total_churn_pct DESC;

-- Q4 Does auto-renewal status affect churn?
SELECT 
s.auto_renew, COUNT(*) AS total_users,
SUM( CASE WHEN NOT c.churn_within_6m = TRUE THEN 1 ELSE 0 END) AS retained_users, 
SUM (CASE WHEN c.churn_within_6m =TRUE THEN 1 ELSE 0 END) AS churned_users,
ROUND(
SUM( CASE WHEN c.churn_within_6m = TRUE THEN 1 ELSE 0 END) * 100.0/COUNT(*),2) AS churn_rate_pct_per_autorenewal,
ROUND (
SUM( CASE WHEN c.churn_within_6m = TRUE THEN 1 ELSE 0 END) * 100.0 / 
(SELECT COUNT(*) FROM churn_status WHERE churn_within_6m = TRUE),2) AS share_of_total_churn_pct
FROM subscriptions s
JOIN churn_status  c
ON s.user_id = c.user_id
GROUP BY auto_renew
ORDER BY share_of_total_churn_pct DESC;

--Q5 Are churned users less engaged than retained users?
--Compares average behavioral metrics between churned and retained users
SELECT
    c.churn_within_6m,
    ROUND(AVG(e.weekly_sessions), 2)          AS avg_weekly_sessions,
    ROUND(AVG(e.avg_session_minutes), 2)      AS avg_session_minutes,
    ROUND(AVG(e.workout_completion_rate), 2)  AS avg_workout_completion,
    ROUND(AVG(e.diet_log_adherence), 2)       AS avg_diet_adherence,
    ROUND(AVG(e.sleep_tracking_usage), 2)     AS avg_sleep_tracking,
    ROUND(AVG(e.coaching_messages_per_week), 2) AS avg_coaching_msgs
FROM engagement e
JOIN churn_status c ON e.user_id = c.user_id
GROUP BY c.churn_within_6m;

-- Q6 How is churn distributed across device types?
SELECT 
 e.device_type,
    COUNT(*) AS total_users,
    SUM(CASE WHEN c.churn_within_6m = TRUE THEN 1 ELSE 0 END) AS churned_users,
    ROUND(
    SUM(CASE WHEN c.churn_within_6m = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*),2) AS churn_rate_pct,
	ROUND (
    SUM( CASE WHEN c.churn_within_6m = TRUE THEN 1 ELSE 0 END) * 100.0 / 
    (SELECT COUNT(*) FROM churn_status WHERE churn_within_6m = TRUE),2) AS share_of_total_churn_pct
FROM engagement e
JOIN churn_status c
ON e.user_id = c.user_id
GROUP BY e.device_type
ORDER BY share_of_total_churn_pct DESC;


--Q7 — Do users who complete more workouts churn less?
SELECT 
 CASE
  WHEN e.workout_completion_rate < 0.5 THEN 'Low'
  WHEN e.workout_completion_rate  BETWEEN 0.50 AND 0.74 THEN 'Mid'
  ELSE 'High'
 END AS completion_band,
 COUNT (*) AS total_uses,
 ROUND(
    SUM(CASE WHEN c.churn_within_6m = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*),2) AS churn_rate_pct,
 ROUND (
    SUM( CASE WHEN c.churn_within_6m = TRUE THEN 1 ELSE 0 END) * 100.0 / 
    (SELECT COUNT(*) FROM churn_status WHERE churn_within_6m = TRUE),2) AS share_of_total_churn_pct
FROM engagement e
JOIN churn_status c ON e.user_id = c.user_id
GROUP BY completion_band
ORDER BY  share_of_total_churn_pct DESC;

 SELECT workout_completion_rate FROM engagement;

 --for export to power bi
 CREATE VIEW vw_analysis_base AS
SELECT
    u.user_id,
    u.age,
    u.gender,
    u.region,
    s.plan_type,
    s.auto_renew,
    s.tenure_days,
    e.weekly_sessions,
    e.avg_session_minutes,
    e.workout_completion_rate,
    e.diet_log_adherence,
    e.sleep_tracking_usage,
    e.device_type,
    c.churn_within_6m
FROM users u
JOIN subscriptions  s ON u.user_id = s.user_id
JOIN engagement    e ON u.user_id = e.user_id
JOIN churn_status  c ON u.user_id = c.user_id;

SELECT * FROM vw_analysis_base;

--KPI VIEWS
CREATE VIEW vw_kpi_base AS
SELECT
    COUNT(*) AS total_users,
    SUM(CASE WHEN c.churn_within_6m = TRUE  THEN 1 ELSE 0 END) AS total_churned,
    SUM(CASE WHEN c.churn_within_6m = FALSE THEN 1 ELSE 0 END)  AS total_retained,
    ROUND(
        SUM(CASE WHEN c.churn_within_6m = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM users u
JOIN churn_status c ON u.user_id = c.user_id;

SELECT * FROM vw_kpi_base;