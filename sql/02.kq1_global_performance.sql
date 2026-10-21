/* KQ1 Analysis*/

-- KQ1 Data Filtering
-- Global Top 200, 2017–2021, artist includes Kendrick Lamar
CREATE TEMP VIEW kq1_filtered AS
SELECT
    title,
    url,
    artist,
    date,
    rank,
    streams
FROM public.spotify_charts
WHERE artist ILIKE '%Kendrick Lamar%'
  AND region = 'Global'
  AND chart = 'top200'
  AND date >= DATE '2017-01-01';

-- KQ1 Metric Definitions: Song-level summary
CREATE TEMP VIEW kq1_song_summary AS
SELECT
    title,

    -- Retain URLs to inspect possible version overlaps
    ARRAY_AGG(DISTINCT url ORDER BY url) AS track_urls,

    -- Number of distinct observed chart dates
    COUNT(DISTINCT date) AS chart_appearances,

    -- Best observed chart position
    MIN(rank) AS peak_rank,

    -- Total recorded streams across chart appearances
    SUM(streams) AS cumulative_chart_streams,

    -- First and last observed chart dates
    MIN(date) AS first_chart_date,
    MAX(date) AS last_chart_date,

    -- Calendar-day difference between first and last observations
    MAX(date) - MIN(date) AS chart_span_days

FROM kq1_filtered
GROUP BY title;


-- KQ1 Metric Definitions: Song-year summary
CREATE TEMP VIEW kq1_song_year_summary AS
SELECT
    title,
    EXTRACT(YEAR FROM date)::INTEGER AS chart_year,

    COUNT(DISTINCT date) AS annual_chart_appearances,
    MIN(rank) AS annual_peak_rank,
    SUM(streams) AS annual_chart_streams,

    MIN(date) AS first_chart_date_in_year,
    MAX(date) AS last_chart_date_in_year

FROM kq1_filtered
GROUP BY
    title,
    EXTRACT(YEAR FROM date)::INTEGER;

-- Inspect song-level metrics
SELECT *
FROM kq1_song_summary
ORDER BY chart_appearances DESC, peak_rank ASC;
-- output is saved as '01.kq1_song_summary'

-- Inspect song-year metrics
SELECT *
FROM kq1_song_year_summary
ORDER BY title, chart_year;
-- output is saved as '02.kq1_song_year_summary'

-- Inspect amount and year distribution of songs
SELECT
    chart_year,
    COUNT(*) AS song_year_combinations
FROM kq1_song_year_summary
GROUP BY chart_year
ORDER BY chart_year;
-- output is saved as '03.kq1_song_year_combinations'