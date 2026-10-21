/* 01.data_profiling
	- Uniqueness: Checking for duplicate chart entries.
	- Validity: Ensuring dates, ranks, and stream counts fall within reasonable/valid ranges.
	- Consistency: Verifying that the combinations of chart types, regions, and streams align with the dataset's schema definitions.
	- Coverage: Checking whether the dates, regions, and chart types match expectations.
	- Analytical Suitability: Determining whether the data recording method supports the specific metrics you intend to calculate.
*/


-- 1.check duplicate records 
-- same title and artist reocrd could have different url due to different version
SELECT
    url,
    artist,
    date,
    region,
    chart,
    COUNT(*) AS duplicate_count
FROM public.spotify_charts
GROUP BY
    url,
    artist,
    date,
    region,
    chart
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;
-- output: No duplicate records found for
-- (url, artist, date, region, chart).


-- 2.Check date coverage
SELECT
    MIN(date) AS earliest_date,
    MAX(date) AS latest_date
FROM spotify_charts;
-- output: 2017-01-01 ~ 2021-12-31

-- 3. Check rank range
SELECT
    MIN(rank) AS min_rank,
    MAX(rank) AS max_rank,
    COUNT(DISTINCT rank) AS distinct_rank_count
FROM spotify_charts;
-- output: All 200 rank values (1-200) are present.


-- 4. Check streams distribution
SELECT
    MIN(streams) AS min_streams,
    MAX(streams) AS max_streams,
    AVG(streams) AS avg_streams,
    percentile_cont(0.50)
        WITHIN GROUP (ORDER BY streams) AS median_streams,
    percentile_cont(0.75)
        WITHIN GROUP (ORDER BY streams) AS p75_streams
FROM spotify_charts;
-- output: distribution shows negative skewness

-- 5. Check region values
SELECT DISTINCT
    region
FROM spotify_charts
ORDER BY region;
-- output: 70 total rows. 'Global' and 'Taiwan' are included.
	-- note: Global is a separate chart series from regional charts.
	-- Do not add Global streams to regional streams without checking
	-- whether the intended metric requires this, as this may double-count listening activity.

-- 6. Check chart values
SELECT DISTINCT
    chart
FROM spotify_charts
ORDER BY chart;
-- output: confirmed there's only 'top200' and 'viral50'

-- 7. Check trend values
SELECT DISTINCT
    trend
FROM spotify_charts
ORDER BY trend;
-- output: 4 results, including 'MOVE_DOWN', 'MOVE_UP', 'NEW_ENTRY', 'SAME_POSITION'

-- 8. Check streams for Viral 50
SELECT
    chart,
    COUNT(*) AS total_rows,
    COUNT(streams) AS non_null_streams,
    COUNT(*) FILTER (
        WHERE streams IS NULL
    ) AS null_streams
FROM spotify_charts
WHERE chart = 'viral50'
GROUP BY chart;
-- output: same as dataset's original details

-- 9. Row count by year
SELECT
    EXTRACT(YEAR FROM date)::INT AS chart_year,
    COUNT(*) AS row_count
FROM spotify_charts
GROUP BY EXTRACT(YEAR FROM date)
ORDER BY chart_year;
-- output: range from 4401145 to 5703536

-- 10. Row count by region
SELECT
    region,
    COUNT(*) AS row_count
FROM spotify_charts
GROUP BY region
ORDER BY row_count DESC;
-- output: range from 76276(South Korea) to 455308(Argentina).

-- 11. Row count by chart type
SELECT
    chart,
    COUNT(*) AS row_count
FROM spotify_charts
GROUP BY chart
ORDER BY row_count DESC;
-- output: same as dataset description