# Analysis-a-thon

**[Open the presentation](https://ablack3.github.io/data/)** · [Download all data and code](https://github.com/ablack3/data/archive/refs/heads/main.zip)

Prepared November 12, 2026. All three datasets are downloaded locally and usable offline. No API keys, live scraping, or `socviz` installation are needed to use the supplied RDS files.

## Project layout

- `analysis-a-thon.Rproj`: opens the project in RStudio.
- `data/track1/`, `data/track2/`, `data/track3/`: analysis-ready CSV and RDS datasets.
- `data/raw/`: preserved source downloads.
- `slides/index.qmd`: four-slide Quarto Reveal.js source.
- `slides/theme.scss`: presentation styling.
- `docs/index.html`: self-contained HTML deck published by GitHub Pages.
- `slides/analysis-a-thon.pptx`: earlier PowerPoint version.
- `scripts/`: download and preparation code.
- `validation/`: checks and dataset coverage reports.
- `starter.R`: offline R entry point.

## Start here

Clone the repository and open `analysis-a-thon.Rproj` in RStudio:

```sh
git clone git@github.com:ablack3/data.git
cd data
```

Open this directory as your R working directory, then run `source("starter.R")`.

The repository includes the data, so participants do not need to run the download or preparation scripts.

## Competition schedule and voting

The schedule below assumes six teams. Allow four minutes for each additional team.

| Segment | Duration | Elapsed time |
|---|---:|---|
| Intro: tracks, data and judging criteria | 10 minutes | 0:00–0:10 |
| Analysis | 60 minutes | 0:10–1:10 |
| Presentations: three minutes plus one-minute transition per team | 24 minutes | 1:10–1:34 |
| Ranked-choice voting | 5 minutes | 1:34–1:39 |
| Results and prize awarding | 5 minutes | 1:39–1:44 |

The organizer will create the ballot on [RCV123](https://www.rcv123.org/) during analysis time, once team names are known. Proposed settings: one overall contest, one winner, ranking of all entries allowed, randomized candidate order, and results hidden until voting closes. Share the ballot link or QR code after presentations. The ballot has not yet been created.

See [EVENT_BRIEF.md](EVENT_BRIEF.md) for the suggested judging criteria and [the four-slide HTML deck](https://ablack3.github.io/data/) for track introductions.

| Track | Main file | Verified coverage |
|---|---|---|
| 1: Trends in AI-agent job postings | `data/track1/tasks.rds` or `.csv` | 449 postings, four platforms; posting timestamps February 4–September 14, 2026 |
| 2: Political preferences by astrological sign | `data/track2/gss_politics.rds` or `.csv` | 64,451 respondents with zodiac signs, 1976–2022 |
| 3: Shipping during the Hormuz disruption | `data/track3/chokepoints_daily.rds` or `.csv` | 34,428 chokepoint-days; 12 corridors; January 1, 2019–November 8, 2026 |

Prefer RDS in R: dates, factor levels, labels, numeric types and missing values are preserved. CSV exports have blank missing values and category labels instead of factor codes. Full source files and download provenance are retained under `data/raw/` and `download_manifest.json`.

## Track 1 — jobs posted by AI agents

Source: [ablack3/trends-in-agent-hiring](https://github.com/ablack3/trends-in-agent-hiring), commit `9f53734cdea0e890f228394c2a8ea186550ef863`; original snapshot September 14, 2026. These are jobs **posted by agents**, not AI-engineering job advertisements.

- `tasks`: one row per `(platform, task_id)`; 449 rows.
- `platforms`: one row per platform; four rows. Includes coverage, access notes and upstream provenance.
- `task_tags`: one row per `(platform, task_id, tag)`; 857 rows. Joining tags to tasks multiplies postings with multiple tags; do not sum posting-level measures after that join without correcting the grain.
- Platform counts: Taskmarket 389, RentAHuman 31, Claw Earn 17, BasedAgents 12.
- Full field definitions: `data/track1/source_dictionary.md`.

Cleaning performed: explicit column types, UTC timestamp parsing, deterministic sorting and CSV/RDS exports. No posting was removed; upstream redaction, classifications and missing values remain intact.

Known limitations: seven missing prices; five missing titles and descriptions; three flagged test/spam postings; 420 unknown payout confirmations. Unknown is not false or zero. `price_usd` retains the upstream USD/USDC convention; it is not a new foreign-exchange conversion. Separate hourly rates from per-task prices if extending the data. Completion is not confirmed payment. Agent labels are self-reported; keyword-derived task types need scrutiny. This is a convenience sample captured once, not a complete longitudinal hiring series: posting-date trends can reflect platform coverage and survival of listings. The upstream repository flags RentAHuman scraping/redistribution restrictions; these files are local copies of the already-cleaned repository data, not a new scrape. Check those terms before public redistribution.

## Track 2 — socviz GSS

Source: [socviz `gss_lon` documentation](https://kjhealy.github.io/socviz/reference/gss_lon.html) and the [package source](https://github.com/kjhealy/socviz), commit `f285a44959705860f8d042fbda1c2d054c9c8eb4`, development version `2.0.0.9000`.

Accessibility verified by downloading and loading the actual package data object, not merely checking documentation. The package itself was not installed; the supplied local files avoid an installation dependency and freeze this exact version.

- `gss_lon`: complete, unchanged package data, 75,699 respondents × 25 variables, 1972–2024.
- `gss_politics`: 64,451 respondents with a nonmissing zodiac sign, retaining politics, demographics, weights and design variables. No political outcome, covariate or weight is imputed.
- 64,112 have both zodiac and `partyid`; 58,367 have zodiac and `polviews`; 58,143 have both political outcomes. Each analysis must state its own denominator.
- **Every 2024 zodiac value is missing.** The zodiac challenge covers 1976–2022, not 2024.
- Key: `(year, id)`, not `id` alone. Dictionary and original category ordering: `data/track2/dictionary.csv`.
- Coverage by survey year and counts by sign: `validation/gss_coverage_by_year.csv` and `validation/gss_zodiac_counts.csv`.

Cleaning performed: preserved the full object; created a transparent nonmissing-zodiac subset with 16 selected fields; sorted that subset by year/id. RDS preserves the original factor labels and levels. `partyid` includes an Other Party category; do not treat its numeric factor code as an interval scale. Missing survey items can mean not asked in a wave or ballot, not only nonresponse.

`wtssps`, `vpsu` and `vstrat` are present and complete in the zodiac subset; weights are positive and finite. Use the GSS survey-design documentation before population inference, especially when pooling waves. Simple unweighted summaries describe these sampled respondents. Adjust comparisons for survey year and specify how waves contribute to pooled estimates. Avoid claiming astrology causes any association, or selecting the largest of many differences without a multiplicity/validation plan.

## Track 3 — IMF PortWatch

Source: [IMF PortWatch](https://portwatch.imf.org/), [methodology](https://portwatch.imf.org/pages/data-and-methodology), and its [official ArcGIS daily chokepoint table](https://services9.arcgis.com/weJ1QsnbMYJlCHdG/arcgis/rest/services/Daily_Chokepoints_Data/FeatureServer/0).

Downloaded directly from IMF rather than a third-party combined CSV, retaining the requested 12 corridors and ship-type counts. The API was paginated to completion: 34,428 expected and retrieved records, unique source object IDs, unchanged source edit metadata during download. The last observed date is November 8, not the download date.

Corridors: Hormuz, Malacca, Suez, Bab el-Mandeb, Panama, Taiwan, Luzon, Sunda, Lombok, Bosporus, Cape of Good Hope and Gibraltar. Each has 2,869 consecutive days.

| Field | Meaning |
|---|---|
| `date` | Observation date |
| `portid`, `portname` | Source corridor identifier and name; despite the API naming, these are chokepoints |
| `n_container` | Container-ship transits per day |
| `n_dry_bulk` | Dry-bulk vessel transits per day |
| `n_general_cargo` | General-cargo vessel transits per day |
| `n_roro` | Roll-on/roll-off vessel transits per day |
| `n_tanker` | Tanker transits per day |
| `n_cargo` | Sum of the four non-tanker cargo categories |
| `n_total` | `n_cargo + n_tanker` |

`chokepoints_daily` is the main wide table; its unique key is `(portid, date)`. `chokepoints_by_ship_type` is an optional 172,140-row long table containing the five mutually exclusive ship types. It intentionally excludes `n_cargo` and `n_total` to avoid double counting.

Cleaning performed: parsed dates, selected transit counts, sorted by chokepoint/date, and reshaped an optional long table. No missing days or missing count values were found; none were filled. All counts are nonnegative integers. Every subtotal reconciles. Source capacity fields remain in `data/raw/track3/portwatch.csv`; they are omitted from the starter tables to keep transit counts distinct from capacity or trade volume.

Use **February 28, 2026** as a documented event marker, with pre/post windows declared before comparing results. The [IMF April 2026 regional outlook](https://www.imf.org/-/media/files/publications/reo/mcd-cca/2026/april/english/text.pdf) marks that date as the attack onset. “Hormuz disruption” is more precise than assuming a complete, continuous closure: the [February 28 JMIC advisory](https://www.ukmto.org/-/media/ukmto/products/001-jmic-advisory-note-28_feb_2026.pdf) reported reduced but continuing commercial traffic.

These are AIS-observed transits, not necessarily all actual crossings or unique ships. Signal gaps and changes in reporting can affect observed counts. A ship can cross multiple chokepoints; summing them does not estimate unique global shipping. Tankers are not equivalent to oil volume. Other corridors are comparisons, not automatically unaffected controls; aggregate changes cannot establish individual-vessel rerouting or causation. Estimates can be revised; all competitors should use this frozen snapshot.

Attribution: Sources: UN Global Platform; IMF PortWatch (portwatch.imf.org). No third-party Creative Commons license is asserted for IMF data.

## Validation and reproduction

`validation/report.txt` records 31 passing checks: parsing, keys, relationships, source-count reconciliation, survey coverage, weights, daily continuity, count validity and shipping subtotals. Missingness is enumerated for every field in `validation/missingness.csv`. These checks establish structural readiness, not truth of the upstream classifications or representativeness of the samples.

To recreate derived files offline, from this directory:

```sh
Rscript scripts/prepare_data.R
```

Preparation requires `dplyr`, `readr` and `tidyr`; using `starter.R` requires only base R. Exact preparation versions are in `validation/sessionInfo.txt`.

`python3 scripts/download_data.py` retrieves the pinned GitHub sources and refreshes the IMF snapshot up to the fixed cutoff November 12, 2026. IMF can revise historical observations, so a later download may differ. Preserve the included raw files and manifest to reproduce this edition exactly. `checksums.sha256` records the delivered data-file hashes.

## Build and publish the presentation

Requires Quarto (rendered with version 1.9.38). From the repository root:

```sh
bash scripts/build_slides.sh
```

This renders `slides/index.qmd` to a self-contained `docs/index.html`. GitHub Pages publishes the `/docs` folder on `main`. Commit and push the rendered HTML after slide changes. The hosted deck links directly to the CSV and RDS files in this repository. It contains four slides, including the competition schedule on the overview.
