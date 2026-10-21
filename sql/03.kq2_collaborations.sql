/* KQ2 Analysis */

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


/* KQ2 View 1: Candidate collaboration songs */
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