
# Kendrick Lamar Catalog Analysis for Spotify Editorial and Product Teams

## Business Context

In 2024, Kendrick Lamar and Drake's highly publicized diss battle brought renewed attention to Kendrick Lamar's music. This project explores how Spotify's Music Editorial and Product teams could use historical chart data to design a music-discovery experience that encourages listeners to explore his broader catalog and discover related artists.

Using Spotify Charts data from 2017 to 2021, the analysis examines global chart performance, collaboration opportunities, and regional patterns.

### Target Audience

| Stakeholder | Key Decision |
|---|---|
| Music Editorial | Which tracks should anchor a retrospective playlist? |
| Product Management | How could listeners be encouraged to explore beyond popular tracks? |
| Regional Editorial | Which tracks or themes might warrant market-specific playlists? |

### Key Questions

- **KQ1: Global Performance** Which Kendrick Lamar songs demonstrated the strongest chart performance and longevity on Spotify's Global Top 200?
- **KQ2: Collaborations** Which co-credited artists could provide potential pathways for cross-artist discovery?
- **KQ3: Regional Patterns** How did chart performance vary across markets, and what opportunities might these patterns suggest for localized playlists?

## Key Findings

### KQ1. Global Chart Performance

- **HUMBLE.** was the strongest overall performer, with 681 observed chart appearances, a peak rank of #1, approximately 978.3 million cumulative chart streams, and a 741-day span between its first and last observed chart dates.
- **DNA.** recorded 326 appearances and a peak rank of #3. **All The Stars** recorded 313 appearances, a peak rank of #2, and approximately 499.8 million cumulative chart streams.
- Annual patterns varied: HUMBLE. recorded 273 appearances in 2017 and 345 in 2018, while All The Stars recorded 286 appearances in 2018.
- Tracks such as PRIDE., FEEL., LUST., and YAH. could be considered for a secondary “Beyond the Hits” playlist, subject to editorial review.

**Implication:** Historical chart performance can help identify established hits and potential catalog rediscovery candidates. Chart appearances and chart span do not indicate uninterrupted listening demand.

### KQ2. Collaboration and Cross-Artist Discovery

The analysis identifies candidate collaborations using artist metadata and collaboration indicators in track titles, then maps co-credited artists to candidate songs and summarizes their chart performance.

**Implication:** Collaboration credits can reveal potential connections between artists. Additional catalog data and editorial review are needed to determine which tracks to recommend next; chart data alone cannot demonstrate that cross-artist discovery will improve engagement.

### KQ3. Regional Chart Patterns

- **HUMBLE.** appeared in the analyst-defined regional Top 10 in 61 of 66 eligible markets (92.4%).
- **DNA.** appeared in 51 markets (77.3%), while **LOYALTY.** appeared in 44 (66.7%).
- **Alright** appeared in 16 markets (24.2%), but most qualifying records were observed on only one chart date, providing limited evidence of sustained visibility.
- **YAH.** appeared in seven markets (10.6%). In Bulgaria, it reached a peak chart rank of #6 across six observed chart dates spanning five calendar days.

**Implication:** Broadly represented tracks could form a common playlist foundation. Selected lower-coverage tracks, including YAH. in Bulgaria, may warrant further investigation, but these patterns do not establish local listener preference.

## Metric Definitions

| Metric | Definition |
|---|---|
| Chart appearances | Number of distinct observed chart dates for a song within the selected scope. |
| Peak chart position | Best observed chart rank; #1 is the highest position. |
| Cumulative chart streams | Sum of recorded streams within the selected chart and time scope. |
| Chart span | Calendar-day difference between the first and last observed chart dates; not continuous chart presence. |
| Annual chart appearances | Number of distinct observed chart dates within a calendar year. |
| Regional Top 10 coverage | Number and percentage of eligible markets in which a track identity ranks in the analyst-defined regional Top 10. |
| Regional analysis rank | Within-market ranking based on chart appearances, peak rank, title, and URL; not Spotify's official chart rank. |

## Data Source and Scope

- **Dataset:** [Spotify Charts on Kaggle](https://www.kaggle.com/datasets/dhruvildave/spotify-charts/data)
- **Scale:** Approximately 26.17 million rows and 9 columns; original CSV approximately 3.48 GB.
- **Period:** January 1, 2017 – December 31, 2021.
- **Coverage:** 70 distinct regions, including Global; the dataset includes Top 200 and Viral 50 chart entries.
- **Analysis scope:** Kendrick Lamar-related records, with Global Top 200 used for KQ1 and KQ2 and non-Global Top 200 records used for KQ3.

### Limitations

- Chart data covers observed chart entries, not all Spotify listening activity. Chart appearances represent observed dates and may not be consecutive.
- Cumulative streams are influenced by market size and chart visibility; they are not a direct measure of listener preference.
- Regional Top 10 coverage uses 66 markets with qualifying Kendrick Lamar chart records, not every region in the raw dataset.
- Collaboration identification relies partly on title-based heuristics and may include classification errors.
- Tracks with the same title but different URLs may represent separate track identities in the analysis.
- The findings are descriptive and do not establish causality or predict playlist engagement.

## Implications and Next Steps

- **Music Editorial:** Use established hits as the foundation for a retrospective playlist and review secondary catalog tracks for a “Beyond the Hits” concept.
- **Product:** Explore collaboration-based discovery pathways, then validate candidate tracks with additional catalog data and editorial input.
- **Regional Editorial:** Use cross-market coverage and selected regional patterns to generate localization hypotheses.
- **Validation:** Before launch, assess listening, playlist exposure, saves, skips, completion, and other available engagement metrics. Where feasible, compare results against a suitable baseline or control group.

## Repository Structure

```text
.
├── data/
│   └── README.md
├── sql/
│   ├── 00_setup.sql
│   ├── 01_data_profiling.sql
│   ├── 02_kq1_global_performance.sql
│   ├── 03_kq2_collaborations.sql
│   └── 04_kq3_regional_analysis.sql
├── output/
│   ├── 01_kq1_song_summary.csv
│   ├── 02_kq1_song_year_summary.csv
│   ├── 04_kq2_collaboration_candidates.csv
│   ├── 05_kq2_collaboration_song.csv
│   ├── 06_kq2_collaboration_performance.csv
│   ├── 07_kq3_song_region_summary.csv
        08_kq3_08.kq3_region_rank_top10.csv
        09_09.kq3_region_rank_top10_frequency.csv
│   ├── 11_kq3_cross_region_top10_coverage.csv
│   └── 12_kq3_representative_song_comparison.csv
└── README.md
```

## How to Reproduce

1. Obtain the dataset from Kaggle and follow `data/README.md` for data access and import instructions.
2. Create the `spotify_charts` table in PostgreSQL and import the dataset.
3. Execute the SQL scripts in numerical order.
4. Review the validation queries before interpreting the results.
5. Export query outputs using the documented filenames.
6. Use the exported results to reproduce the charts and review the findings.

The raw dataset is not included in this repository. Import paths and database settings must be adapted to the local environment.

## Deck for this analysis
https://docs.google.com/presentation/d/1FAzr48BYXjKRwpg_84t5_5Eetaj0r_0jGl9G-vAUMqU/edit?usp=sharing
