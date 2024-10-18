-- drops the database incase it exists
DROP DATABASE `DECODE GAMING BEHAVIOUR`;
-- creates the database decode gaming behaviour
CREATE DATABASE `DECODE GAMING BEHAVIOUR`;
-- code to allow us to use the database
USE `DECODE GAMING BEHAVIOUR`;
-- lets know create our player details table
CREATE TABLE Player_Details(
Number INT,
P_ID INT PRIMARY KEY,
PName varchar(30),
L1_Status INT,
L2_Status INT,
L1_code varchar(30),
L2_code varchar(30));
-- import the csv file corresponding the player details tables

-- lets create the table for level details
CREATE TABLE Level_Details(
Number INT,
P_ID INT,
Dev_ID varchar(10),
start_time varchar(30),
stages_crossed INT,
level INT,
difficulty varchar(10),
kill_count INT,
headshots_count INT,
score INT,
lives_earned INT);
-- import its corresponding csv file

-- checking if the imports where successful
SELECT * FROM player_details;

SELECT * FROM level_details;

-- 1.Extract `P_ID`, `Dev_ID`, `PName`, and `Difficulty_level` of all players at Level 0.

SELECT player_details.P_ID AS P_ID, level_details.Dev_ID AS Dev_ID, player_details.PName AS PName, level_details.difficulty AS difficulty, level_details.level AS level
FROM player_details
JOIN level_details ON player_details.P_ID = level_details.P_ID
WHERE level_details.level = 0;

-- Find `Level1_code`wise average `Kill_Count` where `lives_earned` is 2, and at least 3 stages are crossed.

SELECT * 
FROM player_details;

SELECT player_details.P_ID AS P_ID, player_details.L1_code AS L1_code, level_details.kill_count AS kill_count, level_details.lives_earned AS lives_earned, level_details.stages_crossed AS stages_crossed
FROM player_details
JOIN level_details ON player_details.P_ID = level_details.P_ID
WHERE 
    (level_details.lives_earned = 2) AND
    (level_details.stages_crossed >= 3);
    
SELECT L1_code, FLOOR(AVG(kill_count)) AS Average_kill_count
FROM (
SELECT player_details.P_ID AS P_ID, player_details.L1_code AS L1_code, level_details.kill_count AS kill_count, level_details.lives_earned AS lives_earned, level_details.stages_crossed AS stages_crossed
FROM player_details
JOIN level_details ON player_details.P_ID = level_details.P_ID
WHERE 
    (level_details.lives_earned = 2) AND
    (level_details.stages_crossed >= 3)) AS subquery
GROUP BY L1_code;

/* Find the total number of stages crossed at each difficulty level for Level 2 with players
using `zm_series` devices. Arrange the result in decreasing order of the total number of
stages crossed.*/

SELECT *
FROM level_details;

SELECT stages_crossed, difficulty, level, Dev_ID
FROM level_details
WHERE 
	(level = 2)AND
    (Dev_ID LIKE 'zm%');

SELECT SUM(stages_crossed) AS Total_stages_crossed, difficulty
FROM
(SELECT stages_crossed, difficulty, level, Dev_ID
FROM level_details
WHERE 
	(level = 2)AND
    (Dev_ID LIKE 'zm%')) AS subquery
GROUP BY difficulty
ORDER BY Total_stages_crossed DESC;

-- Extract `P_ID` and the total number of unique dates for those players who have played games on multiple days.

SELECT *
FROM level_details;

SELECT P_ID, COUNT(DISTINCT DATE(start_time)) AS Total_unique_dates
FROM level_details
GROUP BY P_ID
HAVING Total_unique_dates > 1;

/* Find `P_ID` and levelwise sum of `kill_counts` where `kill_count` is greater than the average kill count for 
Medium difficulty. */

SELECT *
FROM level_details;

SELECT P_ID, level, difficulty, kill_count
FROM level_details
WHERE 
	(difficulty = "Medium") AND
    (kill_count > (SELECT FLOOR(AVG(kill_count))
					FROM level_details));

SELECT P_ID, level, difficulty, SUM(kill_count) AS Total_kill_count
FROM (
    SELECT P_ID, level, difficulty, kill_count
    FROM level_details
    WHERE 
        (difficulty = 'Medium') AND
        (kill_count > (
            SELECT FLOOR(AVG(kill_count))
            FROM level_details
            WHERE difficulty = 'Medium'
        ))
) AS subquery
GROUP BY level, P_ID;

/* Find `Level` and its corresponding `Level_code`wise sum of lives earned, excluding Level
 0. Arrange in ascending order of level. */
  
SELECT player_details.L1_code, player_details.L2_code, MAX(level_details.level) AS level, SUM(level_details.lives_earned) AS Total_lives
FROM player_details
JOIN level_details ON player_details.P_ID = level_details.P_ID
GROUP BY L1_code, L2_code
HAVING level != 0
ORDER BY level ASC;

 /*  Find the top 3 scores based on each `Dev_ID` and rank them in increasing order using
`Row_Number`. Display the difficulty as well. */

SELECT
    `Row_Number`,
    Dev_ID,
    score,
    difficulty
FROM
    (
        SELECT
            RANK() OVER (ORDER BY SUM(score) DESC) AS `Row_Number`,
            Dev_ID,
            SUM(score) AS score,
            difficulty
        FROM
            level_details
        GROUP BY
            Dev_ID,
            difficulty
    ) AS subquery
WHERE
    `Row_Number` <= 3;

--  8. Find the `first_login` datetime for each device ID. 

SELECT Dev_ID, MIN(start_time) AS first_login
FROM level_details
GROUP BY Dev_ID;

 /* 9. Find the top 5 scores based on each difficulty level and rank them in increasing order
using `Rank`. Display `Dev_ID` as well. */

SELECT (RANK() OVER(ORDER BY SUM(score) DESC)) AS `Rank`,
Dev_ID, SUM(score) AS Top_Score, difficulty
FROM level_details
GROUP BY difficulty, Dev_ID;

/* 10. Find the device ID that is first logged in (based on `start_datetime`) for each player
(`P_ID`). Output should contain player ID, device ID, and first login datetime. */

SELECT P_ID, Dev_ID, MIN(start_time) AS first_login
FROM level_details
GROUP BY P_ID, Dev_ID;

-- 11. For each player and date, determine how many `kill_counts` were played by the player so far.
-- a) Using window functions

SELECT
    P_ID,
    DATE(start_time) AS Date_played,
    SUM(kill_count) OVER (PARTITION BY P_ID ORDER BY start_time) AS Total_kills_so_far
FROM
    level_details;


-- b) Without window functions

SELECT
    ld.P_ID,
    DATE(ld.start_time) AS Date_played,
    SUM(ld2.kill_count) AS Total_kills_so_far
FROM
    level_details ld
JOIN
    level_details ld2 ON ld.P_ID = ld2.P_ID AND ld.start_time >= ld2.start_time
GROUP BY
    ld.P_ID,
    DATE(ld.start_time);

-- 12. Find the cumulative sum of stages crossed over `start_datetime` for each `P_ID`, excluding the most recent `start_datetime`.

SELECT P_ID, SUM(stages_crossed) AS cumulative_sum_of_stages_crossed, start_time
FROM level_details
GROUP BY start_time, P_ID;

-- 13. Extract the top 3 highest sums of scores for each `Dev_ID` and the corresponding `P_ID`.

SELECT P_ID, Dev_ID, SUM(score) AS highest_sums_of_scores
FROM level_details
GROUP BY P_ID, Dev_ID
ORDER BY highest_sums_of_scores DESC
LIMIT 3;

-- 14. Find players who scored more than 50% of the average score, scored by the sum of scores for each `P_ID`.

SELECT (FLOOR((50/100)*(AVG(score)))) AS score
    FROM level_details;

SELECT player_details.P_ID,player_details.PName, level_details.score
FROM player_details
JOIN level_details ON player_details.P_ID = level_details.P_ID
WHERE
	(score > 
    (SELECT (FLOOR((50/100)*(AVG(score)))) AS score
    FROM level_details));

/* 15. Create a stored procedure to find the top `n` `headshots_count` based on each `Dev_ID`
and rank them in increasing order using `Row_Number`. Display the difficulty as well.*/
 
 SELECT RANK() OVER (ORDER BY SUM(headshots_count) DESC) AS `Row_Number`, Dev_ID, SUM(headshots_count) AS total_headshots, difficulty
 FROM level_details
 GROUP BY Dev_ID, difficulty;



