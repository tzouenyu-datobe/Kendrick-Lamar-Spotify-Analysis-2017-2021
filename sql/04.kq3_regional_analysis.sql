/* KQ3 analysis */
/* KQ3 data filtering */
CREATE OR REPLACE TEMP VIEW kq3_filtered AS
SELECT
    title,
    url,
    artist,
    date,
    rank,
    streams,
    region
FROM spotify_charts
WHERE artist ILIKE '%Kendrick Lamar%'
  AND region <> 'Global'
  AND chart = 'top200'
  AND date >= DATE '2017-01-01'
  AND date <= DATE '2021-12-31';
-- check kq3_filtered scope
SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT title) AS song_count,
    COUNT(DISTINCT region) AS region_count,
    MIN(date) AS first_date,
    MAX(date) AS last_date
FROM kq3_filtered;
-- check regions in kq3_filtered 
SELECT
    region,
    COUNT(*) AS row_count
FROM kq3_filtered
GROUP BY region;
-- check result of kq3_filtered
SELECT *
FROM kq3_filtered;

/* KQ3: regional song performance summary
   Analysis grain: title + region + url
   Period: 2017-01-01 to 2021-12-31
*/
CREATE TEMP VIEW kq3_song_region_summary AS
SELECT
    title,
	artist,
    url,
    region,
    COUNT(DISTINCT date) AS chart_appearances,
    MIN(rank) AS peak_rank,
    SUM(streams) AS cumulative_chart_streams,
    MIN(date) AS first_chart_date,
    MAX(date) AS last_chart_date,
    MAX(date) - MIN(date) AS chart_span_days
FROM kq3_filtered
GROUP BY
    title,
	artist,
    url,
    region;
-- check duplicate 
SELECT 
	title, 
	artist, 
	region,
	url,
	COUNT(*) 
FROM kq3_song_region_summary 
GROUP BY 
	title, 
	artist,
	region,
	url
HAVING COUNT(*) > 1;

-- check metrics of kq3_song_region_summary
SELECT *
FROM kq3_song_region_summary
WHERE chart_appearances < 1
   OR peak_rank < 1
   OR peak_rank > 200
   OR first_chart_date > last_chart_date
   OR chart_span_days < 0;
-- output: 0 rows
-- confirm result
-- print highest 5 in chart appearances songs
SELECT *
FROM kq3_song_region_summary
ORDER BY chart_appearances DESC
LIMIT 5;
-- use these 5 songs to check the accumulated results
SELECT
    COUNT(DISTINCT date) AS chart_appearances,
    MIN(rank) AS peak_rank,
    SUM(streams) AS cumulative_chart_streams,
    MIN(date) AS first_chart_date,
    MAX(date) AS last_chart_date,
    MAX(date) - MIN(date) AS chart_span_days
FROM kq3_filtered
WHERE title = 'HUMBLE.'
  AND artist = 'Kendrick Lamar'
  AND url = 'https://open.spotify.com/track/7KXjTSCq5nL1LoYtL7XAwS'
  AND region = 'Australia';
-- output: matched.

-- check result of kq3_song_region_summary
SELECT *
FROM kq3_song_region_summary
ORDER BY region, chart_appearances DESC, peak_rank ASC;
-- output is saved as '07.kq3_song_region_summary'



/* KQ3: Top 10 songs by chart appearances in each region */
WITH ranked_songs AS (
    SELECT
        region,
        title,
        artist,
        url,
        chart_appearances,
        peak_rank,
        cumulative_chart_streams,
        first_chart_date,
        last_chart_date,
        chart_span_days,
        ROW_NUMBER() OVER (  -- caculate rank
            PARTITION BY region
            ORDER BY chart_appearances DESC, peak_rank ASC
        ) AS region_rank
    FROM kq3_song_region_summary
)
SELECT *
FROM ranked_songs
WHERE region_rank <= 10
ORDER BY region, region_rank;
-- output is saved as '08.kq3_region_rank'

-- create temp view kq3_top10_songs_by_region for further analysis
CREATE TEMP VIEW kq3_top10_songs_by_region AS
WITH ranked_songs AS (
    SELECT
        region,
        title,
        artist,
        url,
        chart_appearances,
        peak_rank,
        cumulative_chart_streams,
        first_chart_date,
        last_chart_date,
        chart_span_days,
        ROW_NUMBER() OVER (  -- caculate rank
            PARTITION BY region
            ORDER BY chart_appearances DESC, peak_rank ASC
        ) AS region_rank
    FROM kq3_song_region_summary
)
SELECT *
FROM ranked_songs
WHERE region_rank <= 10;  -- delete order by

-- check top10 songs' rank frequency
SELECT
    title,
    artist,
    region_rank,
    COUNT(*) AS region_count,
    STRING_AGG(region, ', ' ORDER BY region) AS regions
FROM kq3_top10_songs_by_region
GROUP BY
    title,
    artist,
    region_rank
ORDER BY
    region_rank ASC,
    region_count DESC,
    title ASC;
-- output is saved as '09.kq3_region_rank_top10_frequency'

/* KQ3: rank all songs within each region */
-- in each region, give a song a rank base on composite of chart_appearances and peak_rank
CREATE TEMP VIEW kq3_songs_by_region AS
SELECT
    region,
    title,
    artist,
    url,
    chart_appearances,
    peak_rank,
    cumulative_chart_streams,
    first_chart_date,
    last_chart_date,
    chart_span_days,
    ROW_NUMBER() OVER (
        PARTITION BY region
        ORDER BY
            chart_appearances DESC,
            peak_rank ASC,
            title ASC,
            url ASC
    ) AS region_rank 
FROM kq3_song_region_summary;

-- check 4 metric
SELECT *
FROM kq3_songs_by_region
WHERE region_rank <= 10
ORDER BY
    region ASC,
    chart_appearances DESC,
    chart_span_days DESC,
    cumulative_chart_streams DESC,
    peak_rank ASC;
-- output is saved as '10.kq3_songs_by_region'

/* KQ3: Cross-region Top 10 coverage */
CREATE OR REPLACE TEMP VIEW kq3_song_top10_region_coverage AS
SELECT
    title,
    artist,
    url,
    COUNT(DISTINCT region) AS top10_region_count,
    ROUND(
        100.0 * COUNT(DISTINCT region)
        / (
            SELECT COUNT(DISTINCT region)
            FROM kq3_songs_by_region
        ),
        1
    ) AS top10_region_pct,
    STRING_AGG(
        DISTINCT region,
        ', ' ORDER BY region
    ) AS regions
FROM kq3_songs_by_region
WHERE region_rank <= 10
GROUP BY
    title,
    artist,
    url;


/* ============================================================
   KQ3: Regional Top 10 Coverage Detail

   Business question:
   Which Kendrick Lamar songs rank in the Top 10 by observed
   chart visibility in each regional market, and how widely
   do these songs appear across markets?

   Purpose:
   1. Combine each song's regional performance with its
      cross-region Top 10 coverage.
   2. Identify the markets where each song ranks in the
      regional Top 10.
   3. Compare local chart performance using the four metrics
      established in KQ1/KQ3.
   4. Provide evidence for further exploration of localized
      playlist opportunities.

   Existing views used:
   - kq3_songs_by_region:
     Song-level performance and analyst-defined ranking
     within each region.
   - kq3_song_top10_region_coverage:
     Number and percentage of regions where each song ranks
     in the regional Top 10.

   Important interpretation:
   - region_rank is an analyst-defined ranking based on
     chart_appearances DESC, peak_rank ASC, title ASC, url ASC.
     It is NOT Spotify's original chart rank.
   - Regional Top 10 means the 10 songs with the highest
     observed chart visibility in each region.
   - Different URLs are retained as separate track identities.
   ============================================================ */

CREATE OR REPLACE TEMP VIEW kq3_regional_top10_coverage_detail AS

SELECT
    /* -----------------------------------------
       A. Song identity
       Keep title, artist, and URL to distinguish
       different track identities and releases.
       ----------------------------------------- */
    s.title,
    s.artist,
    s.url,

    /* -----------------------------------------
       B. Regional information
       region identifies the market where the song
       ranks in the analyst-defined regional Top 10.
       region_rank is the song's position within that
       regional analysis ranking.
       ----------------------------------------- */
    s.region,
    s.region_rank,

    /* -----------------------------------------
       C. Cross-region Top 10 coverage
       These metrics describe how widely the same
       track identity appears in regional Top 10 lists.
       They are repeated for each qualifying region.
       ----------------------------------------- */
    c.top10_region_count,
    c.top10_region_pct,
    c.regions AS top10_regions,

    /* -----------------------------------------
       D. Local chart performance
       Continue using the four performance metrics
       established in KQ1/KQ3.
       ----------------------------------------- */
    s.chart_appearances,
    s.peak_rank,
    s.cumulative_chart_streams,
    s.first_chart_date,
    s.last_chart_date,
    s.chart_span_days

FROM kq3_songs_by_region AS s

/* Join by the complete track identity used in the
   cross-region coverage view.
   Matching only title could incorrectly combine tracks
   with the same title but different artists or URLs. */
INNER JOIN kq3_song_top10_region_coverage AS c
    ON  s.title = c.title
    AND s.artist = c.artist
    AND s.url = c.url

/* Retain only songs ranked in the regional Top 10.
   No threshold is applied to cross-region coverage:
   all qualifying songs remain available for comparison. */
WHERE s.region_rank <= 10;



/* KQ3: Compare cross-region Top 10 coverage

   Purpose:
   Review how widely each song appears in regional
   Top 10 lists before selecting representative cases.

   Data source:
   kq3_song_top10_region_coverage

   Note:
   Coverage measures the number of regions where a song
   ranks in the analyst-defined regional Top 10.
   It does not directly measure local listener preference.
*/

SELECT
    title,
    artist,
    top10_region_count,
    top10_region_pct,
    regions
FROM kq3_song_top10_region_coverage
ORDER BY
    top10_region_count DESC,
    top10_region_pct DESC,
    title ASC;
-- output is saved as'11.kq3_cross-region_Top10_coverage'

/* ============================================================
   KQ3: Representative Song Comparison

   Purpose:
   Compare three representative songs with different levels
   of cross-region Top 10 coverage.

   Selected cases:
   1. HUMBLE. : broad cross-region coverage
   2. Alright : more concentrated, but still multi-region
   3. YAH.    : limited cross-region coverage

   Data source:
   kq3_regional_top10_coverage_detail

   Scope:
   - Only records where the song ranks in a regional Top 10.
   - Keep the four existing performance metrics.
   - Retain track identity by title + artist + URL.
   - Do not recalculate rankings or coverage metrics.
   ============================================================ */

SELECT
    /* Song identity */
    title,
    artist,
    url,

    /* Cross-region coverage */
    top10_region_count,
    top10_region_pct,

    /* Regional market and analyst-defined regional ranking */
    region,
    region_rank,

    /* Local chart performance metrics */
    chart_appearances,
    peak_rank,
    cumulative_chart_streams,
    chart_span_days

FROM kq3_regional_top10_coverage_detail

/* Select only the three agreed representative cases.
   URL is retained in the output because identical titles
   may represent different track identities. */
WHERE title IN ('HUMBLE.', 'Alright', 'YAH.')
  AND artist = 'Kendrick Lamar'

ORDER BY
    CASE title
        WHEN 'HUMBLE.' THEN 1
        WHEN 'Alright' THEN 2
        WHEN 'YAH.' THEN 3
        ELSE 4
    END,
    chart_appearances DESC,
    peak_rank ASC,
    region ASC;
-- output is saved as '12.kq3_representitve_song_comparison'

-- check region market 
SELECT DISTINCT region
FROM spotify_charts
WHERE region <> 'Global'

EXCEPT

SELECT DISTINCT region
FROM kq3_songs_by_region

ORDER BY region;
-- output: 3 missing regions are Andorra, Russia, South Korea.

-- confirm South Korea's record
SELECT
    chart,
    COUNT(*) AS row_count,
    COUNT(DISTINCT date) AS observed_dates,
    MIN(date) AS first_date,
    MAX(date) AS last_date,
    COUNT(*) FILTER (
        WHERE artist ILIKE '%Kendrick Lamar%'
    ) AS kendrick_rows
FROM spotify_charts
WHERE region = 'South Korea'
  AND date >= DATE '2017-01-01'
  AND date <= DATE '2021-12-31'
GROUP BY chart
ORDER BY chart;
-- output: no Kendrick Lamar related record in these dataset

