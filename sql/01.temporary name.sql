/* 1. Create 3 tables
	- spotify_charts
	- external_spotify_rates
	- song_youtube_mapping  
*/
CREATE TABLE spotify_charts (
    id SERIAL PRIMARY KEY,
    title TEXT,
    rank INT,
    date DATE,
    artist TEXT,
    url TEXT,
    region TEXT,
    chart VARCHAR(20),
    trend VARCHAR(20),
    streams INT
);

CREATE TABLE external_spotify_rates (
    payout_year INT PRIMARY KEY,
    per_stream_rate NUMERIC(7, 6),
    source_citation TEXT
);

CREATE TABLE song_youtube_mapping (
    title TEXT PRIMARY KEY,
    youtube_url TEXT
);

/* Check tables status */
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
      'spotify_charts',
      'external_spotify_rates',
      'song_youtube_mapping'
  )
ORDER BY table_name;

/* 2. Import Spotify_Charts.csv */
COPY spotify_charts (
    title,
    rank,
    date,
    artist,
    url,
    region,
    chart,
    trend,
    streams
)
FROM 'C:/charts.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE
);

/* 3. Check data status */
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT id) AS unique_ids,
    MIN(date) AS first_date,
    MAX(date) AS last_date,
    COUNT(*) FILTER (WHERE streams IS NULL) AS null_streams
FROM spotify_charts;
-- check column 'url'
SELECT
    COUNT(*) AS total_rows,
    COUNT(url) AS non_null_urls,
    COUNT(*) FILTER (
        WHERE url LIKE 'https://open.spotify.com/track/%'
    ) AS spotify_track_urls,
    COUNT(*) FILTER (
        WHERE url IS NULL
    ) AS null_urls
FROM spotify_charts;

/* 4. Create Index */
CREATE INDEX IF NOT EXISTS idx_charts_artist_date
ON spotify_charts (artist, date);

CREATE INDEX IF NOT EXISTS idx_charts_title
ON spotify_charts (title);

/* 5. Analyze data */
ANALYZE spotify_charts;
-- check duplicate record
SELECT
    title,
	artist,
    date,
    region,
    chart,
    COUNT(*) AS row_count
FROM spotify_charts
GROUP BY
    title,
	artist,
    date,
    region,
    chart
HAVING COUNT(*) > 1
ORDER BY row_count DESC
LIMIT 20;
-- check 1st record
SELECT
    id,
    title,
    rank,
    date,
    artist,
    url,
    region,
    chart,
    trend,
    streams
FROM spotify_charts
WHERE title = 'Sleigh Ride'
  AND date = DATE '2020-12-24'
  AND region = 'Hungary'
  AND chart = 'top200'
ORDER BY rank, id;
-- check
SELECT
    id,
    title,
    rank,
    date,
    artist,
    url,
    region,
    chart,
    trend,
    streams
FROM spotify_charts
WHERE title = '17. mai-sang (Tenk at nå er dagen her)'
  AND artist = 'Pudding-TV'
  AND date = DATE '2021-05-17'
  AND region = 'Norway'
  AND chart = 'top200'
ORDER BY rank, id;
-- check url
SELECT
    url,
    date,
    region,
    chart,
    COUNT(*) AS row_count,
    COUNT(DISTINCT rank) AS distinct_ranks,
    COUNT(DISTINCT streams) AS distinct_stream_counts
FROM spotify_charts
GROUP BY
    url,
    date,
    region,
    chart
HAVING COUNT(*) > 1
ORDER BY row_count DESC
LIMIT 20;

/* 6. Confirm scope */
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE streams IS NOT NULL) AS rows_with_streams,
    COUNT(*) FILTER (WHERE streams IS NULL) AS rows_without_streams,
    COUNT(DISTINCT url) AS distinct_tracks,
    MIN(date) AS first_date,
    MAX(date) AS last_date
FROM spotify_charts
WHERE artist ILIKE '%Kendrick Lamar%'
  AND region = 'Global'
  AND chart = 'top200';

-- confirm 2021's data
SELECT
    region,
    COUNT(*) AS total_rows,
    MIN(date) AS first_date,
    MAX(date) AS last_date
FROM spotify_charts
WHERE artist ILIKE '%Kendrick Lamar%'
  AND chart = 'top200'
  AND date >= DATE '2021-01-01'
GROUP BY region
ORDER BY total_rows DESC
LIMIT 20;

/* adjust analysis goal */
CREATE OR REPLACE VIEW view_kendrick_global_chart AS
SELECT
    id,
    date AS chart_date,
    EXTRACT(YEAR FROM date)::INT AS chart_year,
    title,
    artist,
    url AS track_url,
    rank,
    streams
FROM spotify_charts
WHERE artist ILIKE '%Kendrick Lamar%'
  AND region = 'Global'
  AND chart = 'top200'
  AND streams IS NOT NULL;

-- check scope
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT track_url) AS distinct_tracks,
    COUNT(DISTINCT chart_date) AS days_covered,
    MIN(chart_date) AS first_date,
    MAX(chart_date) AS last_date,
    SUM(streams) AS total_chart_streams
FROM view_kendrick_global_chart;

-- confirm each so
SELECT
    chart_year,
    title,
    track_url,
    COUNT(DISTINCT chart_date) AS days_on_chart,
    MIN(rank) AS peak_rank,
    SUM(streams) AS total_streams,
    ROUND(AVG(streams), 0) AS avg_daily_streams
FROM view_kendrick_global_chart
GROUP BY
    chart_year,
    title,
    track_url
ORDER BY
    chart_year DESC,
    total_streams DESC
LIMIT 20;

/*261019重新跑一次*/
-- confrim data schema
SELECT
    ordinal_position,
    column_name,
    data_type,
    udt_name,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'spotify_charts'
ORDER BY ordinal_position;

-- delete irrelated existing tables
DROP TABLE IF EXISTS external_spotify_rates;
DROP TABLE IF EXISTS song_youtube_mapping;

-- check contraints
SELECT
    conname AS constraint_name,
    contype AS constraint_type,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'public.spotify_charts'::regclass
ORDER BY contype, conname;

-- check range of streams
SELECT
    MAX(streams) AS max_streams,
    MIN(streams) AS min_streams
FROM spotify_charts;

-- check null
SELECT
    COUNT(*) FILTER (WHERE title IS NULL)  AS null_title,
    COUNT(*) FILTER (WHERE rank IS NULL)   AS null_rank,
    COUNT(*) FILTER (WHERE date IS NULL)   AS null_date,
    COUNT(*) FILTER (WHERE artist IS NULL) AS null_artist,
    COUNT(*) FILTER (WHERE url IS NULL)    AS null_url,
    COUNT(*) FILTER (WHERE region IS NULL) AS null_region,
    COUNT(*) FILTER (WHERE chart IS NULL)  AS null_chart,
    COUNT(*) FILTER (WHERE trend IS NULL)  AS null_trend,
    COUNT(*) FILTER (WHERE streams IS NULL) AS null_streams
FROM spotify_charts;

-- check relations
SELECT
    dependent_ns.nspname AS dependent_schema,
    dependent_view.relname AS dependent_view
FROM pg_depend
JOIN pg_rewrite
    ON pg_depend.objid = pg_rewrite.oid
JOIN pg_class AS dependent_view
    ON pg_rewrite.ev_class = dependent_view.oid
JOIN pg_namespace AS dependent_ns
    ON dependent_view.relnamespace = dependent_ns.oid
WHERE pg_depend.refobjid = 'public.spotify_charts'::regclass
  AND dependent_view.relkind = 'v';

-- delete existing view
DROP VIEW IF EXISTS public.view_kendrick_yearly_summary;
DROP VIEW IF EXISTS public.view_kendrick_global_chart;

-- delete existing table
DROP TABLE spotify_charts;

/*1. create table */
CREATE TABLE spotify_charts (
    id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    title TEXT NOT NULL,
    rank INTEGER NOT NULL,
    date DATE NOT NULL,
    artist TEXT NOT NULL,
    url TEXT NOT NULL,
    region TEXT NOT NULL,
    chart VARCHAR NOT NULL,
    trend VARCHAR NOT NULL,
    streams INTEGER
);

/* 2. Import data */
-- Import Spotify Charts data from CSV
-- Source: charts.csv
-- Note: id is generated automatically by PostgreSQL.

COPY public.spotify_charts (
    title,
    rank,
    date,
    artist,
    url,
    region,
    chart,
    trend,
    streams
)
FROM 'C:/Users/SURFACE/OneDrive/Documents/portfolio/Case1.5/data/charts.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ',',
    QUOTE '"',
    ESCAPE '"'
);

/* 3. Data Profiling 
	- Uniqueness: Checking for duplicate chart entries.
	- Validity: Ensuring dates, ranks, and stream counts fall within reasonable/valid ranges.
	- Consistency: Verifying that the combinations of chart types, regions, and streams align with the dataset's schema definitions.
	- Coverage: Checking whether the dates, regions, and chart types match expectations.
	- Analytical Suitability: Determining whether the data recording method supports the specific metrics you intend to calculate.
*/
-- check duplicate records
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

-- Check date coverage
SELECT
    MIN(date) AS earliest_date,
    MAX(date) AS latest_date
FROM spotify_charts;
-- output: 2017-01-01 ~ 2021-12-31

-- Check rank range
SELECT
    MIN(rank) AS min_rank,
    MAX(rank) AS max_rank,
    COUNT(DISTINCT rank) AS distinct_rank_count
FROM spotify_charts;
-- output: All 200 rank values (1-200) are present.

-- Check streams distribution
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

-- Check region values
SELECT DISTINCT
    region
FROM spotify_charts
ORDER BY region;
-- output: 70 total rows. 'Global' and 'Taiwan' are included.
	-- note: Global is a separate chart series from regional charts.
	-- Do not add Global streams to regional streams without checking
	-- whether the intended metric requires this, as this may double-count listening activity.

-- Check chart values
SELECT DISTINCT
    chart
FROM spotify_charts
ORDER BY chart;
-- output: confirmed there's only 'top200' and 'viral50'

-- Check trend values
SELECT DISTINCT
    trend
FROM spotify_charts
ORDER BY trend;
-- output: 4 results, including 'MOVE_DOWN', 'MOVE_UP', 'NEW_ENTRY', 'SAME_POSITION'

-- Check streams for Viral 50
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

-- Row count by year
SELECT
    EXTRACT(YEAR FROM date)::INT AS chart_year,
    COUNT(*) AS row_count
FROM spotify_charts
GROUP BY EXTRACT(YEAR FROM date)
ORDER BY chart_year;
-- output: range from 4401145 to 5703536

-- Row count by region
SELECT
    region,
    COUNT(*) AS row_count
FROM spotify_charts
GROUP BY region
ORDER BY row_count DESC;
-- output: range from 76276(South Korea) to 455308(Argentina).

-- Row count by chart type
SELECT
    chart,
    COUNT(*) AS row_count
FROM spotify_charts
GROUP BY chart
ORDER BY row_count DESC;
-- output: same as dataset description

/* 4. Create Index */
-- check installation of pg_trgm
SELECT
    version();

SELECT
    extname,
    extversion
FROM pg_extension
WHERE extname = 'pg_trgm';

-- install pg_trgm
SELECT name, default_version, installed_version
FROM pg_available_extensions
WHERE name = 'pg_trgm';
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Using a GIN trigram index to speed up substring searches in the artist column
CREATE INDEX idx_charts_artist_trgm
ON spotify_charts
USING GIN (artist gin_trgm_ops);

-- Using a composite B-tree index to speed up filtering by region, chart type, and date
CREATE INDEX idx_charts_region_chart_date
ON spotify_charts (region, chart, date);

-- Using Explain to check indexes
EXPLAIN
SELECT title, artist, date, rank, streams
FROM spotify_charts
WHERE artist ILIKE '%Kendrick Lamar%'
  AND region = 'Global'
  AND chart = 'top200'
  AND date BETWEEN DATE '2017-01-01' AND DATE '2021-12-31';

-- Using EXPLAIN ANALYZE to check actual search
EXPLAIN (ANALYZE, BUFFERS)
SELECT title, artist, date, rank, streams
FROM public.spotify_charts
WHERE artist ILIKE '%Kendrick Lamar%'
  AND region = 'Global'

-- Analyze
ANALYZE public.spotify_charts;
  AND chart = 'top200'
  AND date BETWEEN DATE '2017-01-01' AND DATE '2021-12-31';

/* 5. Data Analysis */
/* KQ1 Analysis*/
-- KQ1 Data Filtering
-- Global Top 200, 2017–2021, artist metadata includes Kendrick Lamar
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
-- output is saved as '03.song_year_combinations'

/* KQ2 Analysis */
/*
-- KQ2: Inspect artist metadata format
SELECT DISTINCT artist
FROM spotify_charts
WHERE artist ILIKE '%Kendrick Lamar%'
  AND region = 'Global'
  AND chart = 'top200'
  AND date >= DATE '2017-01-01'
  AND date <= DATE '2021-12-31'
ORDER BY artist
LIMIT 50;
-- output: only 6 rows in total, seems wrong

-- Inspect title & artist & url
SELECT DISTINCT
    title,
    artist,
    url
FROM public.spotify_charts
WHERE artist ILIKE '%Kendrick Lamar%'
  AND region = 'Global'
  AND chart = 'top200'
  AND date >= DATE '2017-01-01'
  AND date <= DATE '2021-12-31'
ORDER BY artist, title;
-- output: collaboration cans shows in title or artist column.

-- check kq2 data filtering
SELECT DISTINCT
    title,
    artist,
    url
FROM public.spotify_charts
WHERE region = 'Global'
  AND chart = 'top200'
  AND date >= DATE '2017-01-01'
  AND date <= DATE '2021-12-31'
  AND (
      artist ILIKE '%Kendrick Lamar%'
      OR (
          title ILIKE '%Kendrick Lamar%'
          AND (
              title ILIKE '%with %'
              OR title ILIKE '%feat.%'
              OR title ILIKE '%featuring %'
          )
      )
  )
ORDER BY title, artist, url;
-- ouput: 49 rows

-- KQ2: Identify collaboration candidates
CREATE TEMP VIEW kq2_collab_candidates AS
SELECT DISTINCT
    title,
    artist,
    url,
    CASE
        WHEN artist ILIKE '%Kendrick Lamar%'
             AND artist LIKE '%,%'
            THEN 'Multiple artists in artist field'
        WHEN title ILIKE '%Kendrick Lamar%'
             AND (
                 title ILIKE '%with %'
                 OR title ILIKE '%feat%'
                 OR title ILIKE '%featuring %'
             )
            THEN 'Collaboration indicated in title'
        WHEN artist ILIKE '%Kendrick Lamar%'
             AND (
                 title ILIKE '%with %'
                 OR title ILIKE '%feat%'
                 OR title ILIKE '%featuring %'
             )
            THEN 'Collaboration indicated in title'
    END AS collaboration_evidence
FROM public.spotify_charts
WHERE region = 'Global'
  AND chart = 'top200'
  AND date >= DATE '2017-01-01'
  AND date <= DATE '2021-12-31'
  AND (
      (
          artist ILIKE '%Kendrick Lamar%'
          AND (
              artist LIKE '%,%'
              OR title ILIKE '%with %'
              OR title ILIKE '%feat%'
              OR title ILIKE '%featuring %'
          )
      )
      OR
      (
          title ILIKE '%Kendrick Lamar%'
          AND (
              title ILIKE '%with %'
              OR title ILIKE '%feat%'
              OR title ILIKE '%featuring %'
          )
      )
  );

-- check view of kq2_collab_candidates
SELECT *
FROM kq2_collab_candidates
ORDER BY title, artist, url;
-- check scale of kq2_collab_candidates
SELECT
    COUNT(*) AS candidate_records,
    COUNT(DISTINCT title) AS distinct_titles,
    COUNT(DISTINCT url) AS distinct_urls
FROM kq2_collab_candidates;
-- output: 34 rows left, inconsistent with previous query before view

-- confirm query without view
SELECT
    COUNT(*) AS candidate_records,
    COUNT(DISTINCT title) AS distinct_titles,
    COUNT(DISTINCT url) AS distinct_urls
FROM public.spotify_charts
WHERE region = 'Global'
  AND chart = 'top200'
  AND date >= DATE '2017-01-01'
  AND date <= DATE '2021-12-31'
  AND (
      artist ILIKE '%Kendrick Lamar%'
      OR (
          title ILIKE '%Kendrick Lamar%'
          AND (
              title ILIKE '%with %'
              OR title ILIKE '%feat%'
              OR title ILIKE '%featuring %'
          )
      )
  );
-- output: records unmatch

-- check difference between original query and view
WITH source_candidates AS (
    SELECT DISTINCT
        title,
        artist,
        url
    FROM public.spotify_charts
    WHERE region = 'Global'
      AND chart = 'top200'
      AND date >= DATE '2017-01-01'
      AND date <= DATE '2021-12-31'
      AND (
          artist ILIKE '%Kendrick Lamar%'
          OR (
              title ILIKE '%Kendrick Lamar%'
              AND (
                  title ILIKE '%with %'
                  OR title ILIKE '%feat%'
                  OR title ILIKE '%featuring %'
              )
          )
      )
)
SELECT
    s.title,
    s.artist,
    s.url
FROM source_candidates s
LEFT JOIN kq2_collab_candidates v
    ON s.title = v.title
   AND s.artist = v.artist
   AND s.url = v.url
WHERE v.url IS NULL
ORDER BY s.title, s.artist, s.url;

-- check unique value of title
SELECT
    COUNT(*) AS candidate_records,
    COUNT(DISTINCT title) AS distinct_titles,
    COUNT(DISTINCT url) AS distinct_urls
FROM kq2_collab_candidates;

-- display candidate songs
SELECT DISTINCT
    title,
    artist
FROM kq2_collab_candidates
ORDER BY title, artist;

-- create view
CREATE TEMP VIEW kq2_artist_song_mapping AS
SELECT DISTINCT
    c.title,
    c.url,
    TRIM(a.artist_name) AS artist_name
FROM kq2_collab_candidates c
CROSS JOIN LATERAL
    regexp_split_to_table(c.artist, ',') AS a(artist_name);
-- check result
SELECT *
FROM kq2_artist_song_mapping
ORDER BY title, artist_name;
-- output: 41 rows

--
CREATE TEMP VIEW kq2_title_collaborators AS
SELECT DISTINCT
    title,
    url,
    CASE
        WHEN title ILIKE '%All The Stars (with SZA)%'
            THEN 'SZA'
        WHEN title ILIKE '%Big Shot (with Travis Scott)%'
            THEN 'Travis Scott'
        WHEN title ILIKE '%LOVE. FEAT. ZACARI%'
            THEN 'Zacari'
        WHEN title ILIKE '%LOYALTY. FEAT. RIHANNA%'
            THEN 'Rihanna'
        WHEN title ILIKE '%with Kendrick Lamar%'
            THEN 'Kendrick Lamar'
        WHEN title ILIKE '%feat. Kendrick Lamar%'
            THEN 'Kendrick Lamar'
        WHEN title ILIKE '%feat Kendrick Lamar%'
            THEN 'Kendrick Lamar'
        ELSE NULL
    END AS collaborator
FROM kq2_collab_candidates;
-- check result
SELECT *
FROM kq2_title_collaborators
WHERE collaborator IS NOT NULL
ORDER BY title, url;
-- create temp view of 25 collaboration songs
CREATE TEMP VIEW kq2_title_review AS
SELECT
    title,
    ARRAY_AGG(DISTINCT artist ORDER BY artist) AS artist_values,
    ARRAY_AGG(DISTINCT url ORDER BY url) AS track_urls
FROM kq2_collab_candidates
GROUP BY title;
-- check result
SELECT *
FROM kq2_title_review
ORDER BY title;
-- output: 25 rows

--
DROP VIEW IF EXISTS
    kq2_title_review,
    kq2_title_collaborators,
    kq2_artist_song_mapping,
    kq2_collab_candidates;
*/

/* KQ2: Count candidate records under three collaboration scenarios
   Scope:
   - Chart: Global Top 200
   - Period: 2017-01-01 to 2021-12-31

   Purpose:
   Count records matching each of the three collaboration scenarios
   before building the final collaboration dataset.
*/

SELECT
    /* Case A:
       Kendrick Lamar appears in the artist field,
       there is no comma indicating multiple artists,
       and the title contains a collaboration marker.
       These are potential collaborations whose co-artist
       may only be recorded in the title.
    */
    COUNT(DISTINCT (title, artist, url))
        FILTER (
            WHERE artist ILIKE '%Kendrick Lamar%'
              AND artist NOT LIKE '%,%'
              AND (
                  title ILIKE '%with %'
                  OR title ILIKE '%feat%'
                  OR title ILIKE '%featuring %'
              )
        ) AS case_a,

    /* Case B:
       Kendrick Lamar does not appear in the artist field,
       but the title mentions Kendrick Lamar and contains
       a collaboration marker.
       These are potential collaborations where the title
       may identify Kendrick as a featured artist.
    */
    COUNT(DISTINCT (title, artist, url))
        FILTER (
            WHERE artist NOT ILIKE '%Kendrick Lamar%'
              AND title ILIKE '%Kendrick Lamar%'
              AND (
                  title ILIKE '%with %'
                  OR title ILIKE '%feat%'
                  OR title ILIKE '%featuring %'
                  OR title LIKE '%&%'
              )
        ) AS case_b,

    /* Case C:
       Kendrick Lamar and at least one other artist are
       listed in the artist field.
       These are collaborations identifiable directly
       from the artist metadata.
    */
    COUNT(DISTINCT (title, artist, url))
        FILTER (
            WHERE artist ILIKE '%Kendrick Lamar%'
              AND artist LIKE '%,%'
        ) AS case_c

FROM public.spotify_charts

/* Apply the shared dataset scope to all three cases. */
WHERE region = 'Global'
  AND chart = 'top200'
  AND date >= DATE '2017-01-01'
  AND date <= DATE '2021-12-31';

/* KQ2: Count distinct candidate records across all three cases.
   This checks whether the sum of the three case counts
   equals the number of unique candidate records.
*/

WITH candidate_records AS (
    SELECT DISTINCT
        title,
        artist,
        url
    FROM public.spotify_charts
    WHERE region = 'Global'
      AND chart = 'top200'
      AND date >= DATE '2017-01-01'
      AND date <= DATE '2021-12-31'
      AND (
          (
              artist ILIKE '%Kendrick Lamar%'
              AND (
                  (
                      artist NOT LIKE '%,%'
                      AND (
                          title ILIKE '%with %'
                          OR title ILIKE '%feat%'
                          OR title ILIKE '%featuring %'
                      )
                  )
                  OR artist LIKE '%,%'
              )
          )
          OR (
              artist NOT ILIKE '%Kendrick Lamar%'
              AND title ILIKE '%Kendrick Lamar%'
              AND (
                  title ILIKE '%with %'
                  OR title ILIKE '%feat%'
                  OR title ILIKE '%featuring %'
                  OR title LIKE '%&%'
              )
          )
      )
)
SELECT
    COUNT(*) AS distinct_candidate_records,
    COUNT(DISTINCT title) AS distinct_titles,
    COUNT(DISTINCT url) AS distinct_urls
FROM candidate_records;


/* KQ2: Review all distinct collaboration candidates
   Purpose:
   - List candidate records under the three agreed scenarios.
   - Retain title, artist metadata, and URL for validation.
   - Count distinct URLs for each title to flag possible versions.
*/

WITH candidate_records AS (
    SELECT DISTINCT
        title,
        artist,
        url
    FROM public.spotify_charts
    WHERE region = 'Global'
      AND chart = 'top200'
      AND date >= DATE '2017-01-01'
      AND date <= DATE '2021-12-31'
      AND (
          /* Case A: Kendrick in artist, single artist field,
             collaboration marker in title */
          (
              artist ILIKE '%Kendrick Lamar%'
              AND artist NOT LIKE '%,%'
              AND (
                  title ILIKE '%with %'
                  OR title ILIKE '%feat%'
                  OR title ILIKE '%featuring %'
              )
          )

          OR

          /* Case B: Kendrick absent from artist,
             but title identifies a collaboration with Kendrick */
          (
              artist NOT ILIKE '%Kendrick Lamar%'
              AND title ILIKE '%Kendrick Lamar%'
              AND (
                  title ILIKE '%with %'
                  OR title ILIKE '%feat%'
                  OR title ILIKE '%featuring %'
                  OR title LIKE '%&%'
              )
          )

          OR

          /* Case C: Kendrick and other artists in artist metadata */
          (
              artist ILIKE '%Kendrick Lamar%'
              AND artist LIKE '%,%'
          )
      )
),
title_url_counts AS (
    SELECT
        title,
        COUNT(DISTINCT url) AS url_count
    FROM candidate_records
    GROUP BY title
)
SELECT
    c.title,
    c.artist,
    c.url,
    t.url_count
FROM candidate_records c
JOIN title_url_counts t
    ON c.title = t.title
ORDER BY
    t.url_count DESC,
    c.title,
    c.artist,
    c.url;
-- output is saved as '04.kq2_collaboration_song_with_duplicate_url'


-- KQ2 Step 2
-- Goal: Calculate chart performance metrics at the collaboration-song level.
-- Song grain: One row per exact song title.
-- Rule: Different URLs with the same title are treated as the same song.

WITH candidate_records AS (

    -- Identify candidate collaborations using the three agreed scenarios.
    -- Scenario A: Kendrick appears in artist metadata alone;
    --             collaboration indicators appear in the title.
    -- Scenario B: Kendrick is in the title but not in artist metadata;
    --             the title also contains a collaboration indicator.
    -- Scenario C: Kendrick and another artist appear in artist metadata.

    SELECT DISTINCT
        title,
        artist,
        url
    FROM public.spotify_charts
    WHERE region = 'Global'
      AND chart = 'top200'
      AND date >= DATE '2017-01-01'
      AND date < DATE '2022-01-01'
      AND (
          (
              artist ILIKE '%Kendrick Lamar%'
              AND artist NOT LIKE '%,%'
              AND (
                  title ILIKE '%with %'
                  OR title ILIKE '%feat%'
                  OR title ILIKE '%featuring %'
              )
          )
          OR (
              artist NOT ILIKE '%Kendrick Lamar%'
              AND title ILIKE '%Kendrick Lamar%'
              AND (
                  title ILIKE '%with %'
                  OR title ILIKE '%feat%'
                  OR title ILIKE '%featuring %'
                  OR title LIKE '%&%'
              )
          )
          OR (
              artist ILIKE '%Kendrick Lamar%'
              AND artist LIKE '%,%'
          )
      )
),

candidate_titles AS (

    -- Deduplicate song titles so different URLs for the same song
    -- do not create multiple collaboration-song records.

    SELECT DISTINCT title
    FROM candidate_records
),

song_daily AS (

    -- Aggregate all URLs for the same song on the same chart date.
    -- This prevents multiple URLs from inflating chart appearances.
    -- Streams are summed across URLs for that song and date.

    SELECT
        c.title,
        c.date,
        SUM(c.streams) AS daily_streams,
        MIN(c.rank) AS best_daily_rank
    FROM public.spotify_charts c
    JOIN candidate_titles t
      ON c.title = t.title
    WHERE c.region = 'Global'
      AND c.chart = 'top200'
      AND c.date >= DATE '2017-01-01'
      AND c.date < DATE '2022-01-01'
    GROUP BY
        c.title,
        c.date
)

-- Final output: one row per collaboration song.

SELECT
    title AS collaboration_song,

    -- Number of distinct dates the song appeared on the chart.
    COUNT(*) AS chart_appearances,

    -- Lower rank numbers indicate better chart positions.
    MIN(best_daily_rank) AS peak_rank,

    -- Total streams across all chart dates and URLs.
    SUM(daily_streams) AS cumulative_chart_streams,

    -- First and last chart dates observed within the analysis period.
    MIN(date) AS first_chart_date,
    MAX(date) AS last_chart_date,

    -- Elapsed days between first and last appearance.
    MAX(date) - MIN(date) AS chart_span_days

FROM song_daily
GROUP BY title
ORDER BY
    cumulative_chart_streams DESC,
    collaboration_song;
-- output is saved as '05.kq2_collaboration_song'

-- KQ2 View 1: Candidate collaboration songs
-- Purpose: Store candidate Kendrick Lamar collaborations for reuse.
-- Grain: One row per distinct title, artist metadata, and URL.
-- Different URLs may represent the same song released on different albums.

CREATE OR REPLACE VIEW public.kq2_collab_candidates AS
SELECT DISTINCT
    title,
    artist,
    url
FROM public.spotify_charts
WHERE region = 'Global'
  AND chart = 'top200'
  AND date >= DATE '2017-01-01'
  AND date < DATE '2022-01-01'
  AND (
      -- Scenario A:
      -- Kendrick is the only artist in metadata;
      -- another collaborator may be listed in the title.
      (
          artist ILIKE '%Kendrick Lamar%'
          AND artist NOT LIKE '%,%'
          AND (
              title ILIKE '%with %'
              OR title ILIKE '%feat%'
              OR title ILIKE '%featuring %'
          )
      )

      OR

      -- Scenario B:
      -- Kendrick appears in the title but not in artist metadata.
      -- Collaboration indicators identify a potential collaboration.
      (
          artist NOT ILIKE '%Kendrick Lamar%'
          AND title ILIKE '%Kendrick Lamar%'
          AND (
              title ILIKE '%with %'
              OR title ILIKE '%feat%'
              OR title ILIKE '%featuring %'
              OR title LIKE '%&%'
          )
      )

      OR

      -- Scenario C:
      -- Kendrick and at least one other artist appear in metadata.
      (
          artist ILIKE '%Kendrick Lamar%'
          AND artist LIKE '%,%'
      )
  );

-- Validate the candidate View.
-- Count distinct songs separately from URL-level records.
SELECT
    COUNT(*) AS candidate_records,
    COUNT(DISTINCT title) AS distinct_songs,
    COUNT(DISTINCT url) AS distinct_urls
FROM public.kq2_collab_candidates;


/* KQ2 View 2: Artist-to-song mapping */
-- Purpose: Map each collaboration song to each co-credited artist.
-- Source: Reuse kq2_collab_candidates.
-- Grain: One row per distinct song title and co-credited artist.

CREATE VIEW kq2_artist_song_mapping AS
WITH metadata_artists AS (

    -- Split artist metadata into individual artist names.
    SELECT
        title,
        TRIM(artist_name) AS co_credited_artist
    FROM kq2_collab_candidates
    CROSS JOIN LATERAL
        regexp_split_to_table(artist, ',') AS artist_name
),

title_artists AS (

    -- Extract artists explicitly named after "with", "feat.", or "featuring".
    SELECT
        title,
        TRIM(
            regexp_replace(
                collaborator_text,
                '\s*\([^)]*\)\s*$',
                ''
            )
        ) AS co_credited_artist
    FROM kq2_collab_candidates
    CROSS JOIN LATERAL (
        SELECT regexp_matches(
            title,
            '(?i)(?:with|feat\.?|featuring)\s+(.+)$'
        ) AS match_parts
    ) AS extracted
    CROSS JOIN LATERAL (
        SELECT extracted.match_parts[1] AS collaborator_text
    ) AS parsed
),

all_artists AS (

    -- Combine artists extracted from metadata and titles.
    SELECT title, co_credited_artist
    FROM metadata_artists

    UNION ALL

    SELECT title, co_credited_artist
    FROM title_artists
)

-- Keep one record per distinct song–artist relationship.
-- Exclude Kendrick Lamar from the co-credited artist list.
SELECT DISTINCT
    title AS collaboration_song,
    TRIM(co_credited_artist) AS co_credited_artist
FROM all_artists
WHERE co_credited_artist IS NOT NULL
  AND TRIM(co_credited_artist) <> ''
  AND TRIM(co_credited_artist) NOT ILIKE '%Kendrick Lamar%';

-- Review the artist-to-song mapping.
SELECT
    collaboration_song,
    co_credited_artist
FROM kq2_artist_song_mapping
ORDER BY
    collaboration_song,
    co_credited_artist;

/* KQ2 Metric: Number of distinct collaboration songs per co-credited artist */
-- Source: Reuse kq2_artist_song_mapping.
-- Each song counts once per artist, regardless of how many URLs it has.
SELECT
    co_credited_artist,
    COUNT(DISTINCT collaboration_song) AS collaboration_count
FROM kq2_artist_song_mapping
GROUP BY co_credited_artist
ORDER BY
    collaboration_count DESC,
    co_credited_artist;

/* KQ2 Metric: Number of distinct collaboration songs per co-credited artist */
-- Source: Reuse kq2_artist_song_mapping.
-- Each song counts once per artist, regardless of how many URLs it has.
SELECT
    co_credited_artist,
    COUNT(DISTINCT collaboration_song) AS collaboration_count
FROM kq2_artist_song_mapping
GROUP BY co_credited_artist
ORDER BY
    collaboration_count DESC,
    co_credited_artist;

/* KQ2 Step 4 */
-- Purpose: Combine collaboration performance with co-credited artists.
-- Song metrics are calculated before joining the artist mapping,
-- so multiple artists do not inflate song-level streams.
WITH song_daily AS (

    -- Aggregate different URLs for the same song on each chart date.
    SELECT
        c.title,
        c.date,
        SUM(c.streams) AS daily_streams,
        MIN(c.rank) AS best_daily_rank
    FROM public.spotify_charts c
    JOIN (
        SELECT DISTINCT collaboration_song
        FROM kq2_artist_song_mapping
    ) m
      ON c.title = m.collaboration_song
    WHERE c.region = 'Global'
      AND c.chart = 'top200'
      AND c.date >= DATE '2017-01-01'
      AND c.date < DATE '2022-01-01'
    GROUP BY
        c.title,
        c.date
),

song_performance AS (

    -- Calculate performance metrics once per song.
    SELECT
        title AS collaboration_song,
        COUNT(*) AS chart_appearances,
        MIN(best_daily_rank) AS peak_rank,
        SUM(daily_streams) AS cumulative_chart_streams,
        MIN(date) AS first_chart_date,
        MAX(date) AS last_chart_date,
        MAX(date) - MIN(date) AS chart_span_days
    FROM song_daily
    GROUP BY title
),

artist_list AS (

    -- Collect the co-credited artists associated with each song.
    SELECT
        collaboration_song,
        STRING_AGG(
            co_credited_artist,
            ', ' ORDER BY co_credited_artist
        ) AS co_credited_artists
    FROM kq2_artist_song_mapping
    GROUP BY collaboration_song
)

-- Final output: one row per collaboration song.
SELECT
    p.collaboration_song,
    a.co_credited_artists,
    p.chart_appearances,
    p.peak_rank,
    p.cumulative_chart_streams,
    p.first_chart_date,
    p.last_chart_date,
    p.chart_span_days
FROM song_performance p
LEFT JOIN artist_list a
  ON p.collaboration_song = a.collaboration_song
ORDER BY
    p.cumulative_chart_streams DESC,
    p.chart_appearances DESC;
-- output is saved as '06.kq2_collaboration_performance'
