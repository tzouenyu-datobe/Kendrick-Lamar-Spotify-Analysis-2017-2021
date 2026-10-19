# Kendrick Lamar Hit Songs Analysis for Spotify Music Editorial and Product teams
# Business Context

## 1. Background

In 2024, Kendrick Lamar and Drake's highly publicized beef sparked widespread discussion across the music industry. Kendrick's diss track "Not Like Us" became a major streaming hit, drawing renewed attention to his music catalog.

Imagine that Spotify's Music Editorial and Product teams want to capitalize on this cultural moment by creating a music-discovery experience that encourages listeners to explore more of Kendrick Lamar's music, rather than stopping at a single viral track.

The proposed experience could include a curated retrospective playlist featuring Kendrick's signature songs, along with smaller themed playlists based on musical styles and collaborations. These playlists could also introduce listeners to featured artists and encourage them to discover music beyond Kendrick's catalog.

The 2024 beef serves as the business scenario motivating this analysis, rather than an event whose impact will be measured. The available dataset covers 2017–2021 and will be used to examine Kendrick Lamar's historical chart performance and develop data-informed product recommendations.

## 2. Target Audience

The primary stakeholders are Spotify's Music Editorial team and Product Managers responsible for music discovery experiences.

| Stakeholder | Key Decision | How the Analysis Helps |
|---|---|---|
| Music Editorial team | Which songs should be included in the main retrospective playlist? | Identify historically prominent songs and tracks with sustained chart presence. |
| Product Manager | How can the experience encourage listeners to explore beyond Kendrick's most popular songs? | Identify opportunities for themed playlists and cross-artist discovery. |
| Regional Editorial team | Should playlist content vary across markets? | Examine historical chart patterns across regions to develop localization hypotheses. |

## 3. Business Problem

How can Spotify's Music Editorial and Product teams use Kendrick Lamar's historical chart performance and collaboration network to design a music-discovery experience that encourages listeners to explore his broader catalog and discover other artists?

The analysis will identify historically prominent and long-lasting songs, examine regional chart patterns, and identify featured artists whose collaborations could serve as entry points to additional music recommendations. The findings will inform playlist curation and potential localized content strategies.

## 4. Key Questions

### KQ1. Which Kendrick Lamar songs demonstrated the strongest chart performance and longevity on Spotify's Global Top 200 from 2017 to 2021?

**Stakeholder:** Music Editorial team

**Decision to Support:**

Which songs should be considered for the main retrospective playlist, and which tracks may be worth rediscovering because of their historical chart presence?

**Analysis Focus:**
- Chart appearances: the number of distinct chart dates on which a song appeared.
- Peak chart position: the best rank achieved during the analysis period.
- Cumulative chart streams: the sum of recorded streams across chart appearances.
- Annual chart presence: the songs appearing on the chart in each year.
- Chart span: the calendar time between a song's first and last observed chart dates.

**Expected Output:**

A song-level summary of historical chart performance, including chart appearances, peak rank, cumulative chart streams, annual presence, and chart span.

**Potential Action:**

Use the results to identify historically prominent songs and develop playlist groupings around signature hits, long-running catalog tracks, and other songs worth rediscovering.

**Data Planning:**

1. **Data Scope**
   - Chart: Global Top 200.
   - Time period: January 1, 2017, to December 31, 2021.
   - Artist filter: records whose artist metadata includes Kendrick Lamar.
   - Analysis grain: song title, with track URLs retained to inspect possible title or version overlaps.

2. **Metric Definitions**

   | Metric | Definition |
   |---|---|
   | Chart appearances | Count of distinct chart dates on which a song appears. |
   | Peak chart position | Minimum observed rank; rank 1 is the highest position. |
   | Cumulative chart streams | Sum of recorded streams within the defined chart and time scope. |
   | Annual chart presence | Whether a song appears in each calendar year, with yearly metrics aggregated by song and year. |
   | Chart span | Calendar time between the first and last observed chart dates. This is not the same as continuous chart presence. |

3. **Analysis Plan**
   - Inspect the chart-date sequence and verify the observation grain before aggregation.
   - Aggregate chart appearances, peak rank, and cumulative streams at the song level.
   - Aggregate the same metrics by song and year to compare annual chart presence.
   - Examine the distribution of chart appearances and chart span before defining a long-tail group.
   - Consider continuous chart runs only after verifying that the available snapshots support a defensible definition.

4. **Limitations**
   - Chart appearances count observed chart dates, not necessarily calendar days.
   - Chart span does not prove uninterrupted chart presence.
   - The dataset records chart entries rather than all Spotify listening activity.
   - If multiple track URLs share the same title, title-level aggregation may combine different versions or recordings. Such cases should be inspected and documented.

### KQ2. Which co-credited artists appeared in Kendrick Lamar's collaborations on the Global Top 200, and how could these collaborations inform cross-artist music discovery?

**Stakeholders:** Music Editorial team and Product Managers

**Decision to Support:**

How could Kendrick Lamar's collaborations serve as entry points for listeners to discover other artists and explore music beyond Kendrick's catalog?

**Analysis Focus:**
- Identify songs credited to Kendrick Lamar and at least one other artist that appeared on the Global Top 200.
- Extract individual co-credited artists from the artist metadata.
- Examine the chart performance of each collaboration.
- Identify collaborations that could serve as entry points for cross-artist discovery.

**Expected Output:**

A collaboration-level summary showing each song, its co-credited artists, chart appearances, peak rank, cumulative chart streams, and chart span.

A separate artist-to-song mapping will show which collaborations are associated with each co-credited artist.

**Potential Action:**

Use collaborations to develop cross-artist playlist concepts. For example, a Kendrick Lamar collaboration with SZA could serve as an entry point to a broader SZA discovery playlist. Specific song selections for the other artist would require additional data or editorial curation.

**Data Planning:**

1. **Data Scope**
   - Chart: Global Top 200.
   - Time period: January 1, 2017, to December 31, 2021.
   - Artist filter: songs whose artist metadata includes Kendrick Lamar and at least one other credited artist.
   - Analysis grain: collaboration song, with track URLs retained for validation.

2. **Metric Definitions**

   Reuse the KQ1 definitions for chart appearances, peak chart position, cumulative chart streams, and chart span.

   | Metric or Entity | Definition |
   |---|---|
   | Collaboration song | A song credited to Kendrick Lamar and at least one other artist in the available artist metadata. |
   | Co-credited artist | An individual artist extracted from the collaboration's artist metadata, excluding Kendrick Lamar. |
   | Collaborations per artist | Count of distinct collaboration songs associated with each co-credited artist. |

3. **Analysis Plan**
   - Inspect the format of the artist field before parsing it into individual names.
   - Identify collaboration songs and create an artist-to-song mapping with one record per song–co-credited artist relationship.
   - Calculate collaboration performance metrics using the same definitions as KQ1.
   - Summarize the collaborations associated with each co-credited artist.
   - Explore separate lists of collaborations ranked by cumulative chart streams and chart appearances.

4. **Limitations**
   - The artist field identifies credited artists but may not distinguish lead artists from featured artists.
   - A collaboration associated with multiple artists will appear in multiple artist-to-song relationships. These relationships should not be summed as though they were separate songs.
   - Chart performance does not establish which songs by a co-credited artist are their signature tracks.
   - Any specific cross-artist playlist recommendations require additional song-level data or editorial input.

### KQ3. How did Kendrick Lamar's chart performance vary across regions, and what opportunities might these patterns suggest for localized playlists?

**Stakeholder:** Regional Editorial team

**Decision to Support:**

Which songs and markets may warrant further exploration when developing region-specific Kendrick Lamar playlists?

**Analysis Focus:**
- Songs appearing on regional Top 200 charts.
- Chart appearances and peak chart position by song and region.
- Cumulative chart streams by song and region.
- Differences in the composition of songs appearing on regional charts.

**Expected Output:**

A regional comparison of Kendrick Lamar's chart performance, highlighting songs and markets that may warrant further exploration for localized playlist concepts.

**Potential Action:**

Develop hypotheses for region-specific playlist selections based on observed historical chart patterns, to be validated with additional listening and product engagement data.

**Data Planning:**

1. **Data Scope**
   - Chart: regional Top 200.
   - Time period: January 1, 2017, to December 31, 2021.
   - Artist filter: records whose artist metadata includes Kendrick Lamar.
   - Region scope: regional markets, with the Global chart identified and handled separately.
   - Analysis grain: song title and region, with track URLs retained for validation.

2. **Metric Definitions**

   Reuse the KQ1 definitions for chart appearances, peak chart position, cumulative chart streams, and chart span, calculated separately for each song and region.

3. **Analysis Plan**
   - Inspect the distinct values in the region and chart fields.
   - Confirm how Global and country-level chart records are represented before filtering.
   - Filter regional Top 200 records and exclude the Global chart from the regional comparison.
   - Aggregate chart performance by song and region.
   - Compare the songs appearing in each region, including their chart appearances, peak rank, and cumulative chart streams.
   - Identify regional patterns that may inform hypotheses for localized playlists.

4. **Limitations**
   - The analysis includes songs that appeared on the selected charts and does not represent all regional Spotify listening.
   - Cumulative streams can reflect differences in chart appearances and overall market listening volume. They should not be interpreted as a direct measure of relative listener preference across regions.
   - The dataset does not provide regional Spotify user counts or playlist engagement metrics.
   - The analysis can suggest localization hypotheses but cannot establish whether a proposed playlist would improve engagement or retention.

## 5. Data Scope and Interpretation

The analysis uses Spotify Charts data from January 1, 2017, to December 31, 2021. The primary analysis focuses on the Global Top 200, while regional Top 200 data are analyzed separately for KQ3.

The dataset supports historical chart-performance analysis, including observed chart appearances, rankings, chart span, and recorded streams for songs appearing on the selected charts. Because chart dates may not represent every calendar day, chart appearances and calendar span are treated as separate measures. Continuous chart runs will only be analyzed if the observation sequence supports a defensible definition.

The 2024 beef serves as the business scenario motivating this analysis, not as an event whose impact will be measured. The available data cannot directly measure the impact of the 2024 beef, all Spotify listening activity, playlist engagement, listener retention, or artist revenue.

The findings will inform playlist curation and product hypotheses rather than establish that a particular playlist strategy will improve engagement or retention.

# Key Findings



# Methodology
The analysis was conducted in PostgreSQL using pgAdmin.


# Data Source
1. Dataset 
    Dataset: [Spotify Charts — Kaggle](https://www.kaggle.com/datasets/dhruvildave/spotify-charts/data)
    The raw dataset is not included in this repository. Refer to `data/README.md` for dataset access and import notes.
2. Data Overview
    - File Size: 3.48 GB (uncompressed CSV)
    - Record Count: 26,173,514 rows * 9 columns
3. Data Granularity & Scope 
    - Unit of Analysis: Each record represents the ranking and performance of an individual track for a specific chart, region, and date.
    - Temporal Coverage: January 1, 2017 – December 31, 2021
    - Temporal Frequency: Snapshot-based, updated every 2–3 days (daily chart format)
    - Inclusion Criteria: Tracks featured on Spotify's Top 200 or Viral 50 charts across 70 distinct regions.
    - streams data is only recorded for Top 200 charts; all Viral 50 entries have null values for this field.
4. Data Dictionary & Column Profiles
    | Column | Data Type | Missing Values | Cardinality (Unique) | Description / Notes |
    | :--- | :--- | :--- | :--- | :--- |
    | `title` | String | 0 (0%) | 164,807 | Track name. |
    | `rank` | Integer | 0 (0%) | 200 | Chart position (ranges from 1 to 200). |
    | `date` | Date | 0 (0%) | ~1,826 | Chart release date (`YYYY-MM-DD`). |
    | `artist` | String | 0 (0%) | ~96.2K | Name of the artist(s). |
    | `url` | String | 0 (0%) | 217,704 | Spotify track link / Unique identifier. |
    | `region` | Categorical | 0 (0%) | 70 | Market/Country covered (e.g., Global, Argentina). |
    | `chart` | Categorical | 0 (0%) | 2 | Chart type: mutually exclusive between `top200` (~78%) and `viral50` (~22%). |
    | `trend` | Categorical | 0 (0%) | 4 | Track movement. Contains 4 discrete categories: `MOVE_DOWN` (43%), `MOVE_UP` (37%), and two additional states (e.g., `SAME_POSITION`, `NEW_ENTRY` — pending verification via EDA). |
    | `streams` | Integer | ~5.85M (22.3%) | Continuous | Stream count. Missing exclusively for `viral50` entries, as Spotify does not report stream volume for Viral charts. |
5. Inference Limitations:
    **What this dataset can answer:**
    - A song’s ranking on the Spotify Top 200 chart.
    - A song’s chart performance across different years, months, and regions.
    - How long a song remains on the chart.
    - The recorded stream counts for songs featured on the Top 200 chart.
    - How often and for how long a song appears on the Viral 50 chart across different years, months, and regions. However, stream counts are not available for Viral 50 entries.

    **What this dataset cannot answer:**
    - Whether a region’s higher stream counts are caused by a larger Spotify user base.
    - How much revenue an artist earns from streaming.

## Metric Definitions






##  Implications



# Repository Structure
-- 這段留給AI改
```text
case1/
├── README.md
├── data/
│   └── README.md
├── sql/
│   ├── 01_data_import_check.sql
│   ├── 02_customer_metrics.sql
│   ├── 03_customer_segmentation.sql
│   └── 04_customer_value_contribution.sql
├── docs/
│   ├── analysis_log.md
│   └── ai_collaboration.md
├── output/
│   ├── 03_rfm_combination_distribution.csv
│   ├── 03_high_value_segment_distribution.csv
│   ├── 03_high_value_segment_comparison.csv
│   ├── 03_campaign_response_distribution.csv
│   ├── 03_product_spending_mix_comparison.csv
│   ├── 03_purchase_channel_comparison.csv
│   ├── 03_campaign_response_validation.csv
│   └── 04_customer_value_contribution.csv
└── .gitignore
```



# How to Reproduce

1. Obtain the dataset from Kaggle and follow the import instructions in `data/README.md`.
2. Load the data into PostgreSQL using the table name ``.
3. Execute the SQL files in numerical order, from data validation through customer value contribution analysis.
4. Compare the query results with the CSV outputs in `output/`.

The output files provide reference results for reviewing the analysis.




# Deliverables
-- 最後改
- **[View the Customer Segmentation Case Study (PDF)](docs/Case%201_%20Customer%20Segmentation%20for%20CRM%20Prioritization.pdf)** — Visual summary of the segmentation analysis, key findings, and CRM implications.
- SQL analysis and reference outputs are available in this repository.