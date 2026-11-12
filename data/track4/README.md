# Bonus Track 4: issue bundles in the 2026 midterms

**Question: Which issues do voters prioritize together, and how do these combinations differ by party or vote choice?**

Source: [NORC Civic Health & Elections Project](https://civichealth.norc.org/download-data.html). Registered voters surveyed in the week leading up to the 2026 midterms; frozen November 12, 2026. This replaces the earlier aggregate Pew table.

| File | Dimensions | Contents |
|---|---|---|
| `voter_issues.rds` | 113,020 × 32 | Compressed R starter table; one respondent per row |
| `voter_issues_csv.zip` | 113,020 × 32 | Same table as CSV, plus dictionary and response-code mappings |
| `../raw/track4/civichealth_csv.zip` | 113,020 × 402 | Full original CSV, unchanged bytes, compressed without redundant SAV/Stata copies |
| `../raw/track4/civichealth_codebook.zip` | Documentation | Original questionnaire, full variable list, response options and workbook |

```r
# Base R; no packages required to load the data.
voters <- readRDS("data/track4/voter_issues.rds")
issue_columns <- grep("^issues_", names(voters), value = TRUE)
issue_columns <- setdiff(issue_columns, "issues_selected")
issue_matrix <- as.matrix(voters[issue_columns])

# Alternative: read CSV directly from ZIP without expanding it on disk.
voters_csv <- read.csv(unz("data/track4/voter_issues_csv.zip", "voter_issues.csv"),
                       colClasses = c(su_id = "character"), na.strings = "")
```

The starter contains `su_id`, `chep_weight`, state, likely-voter status, reported/intended House choice, party identification, ideology, age group, gender, education, race/ethnicity (`raceth4`, four categories), income, **12 binary issue indicators**, **six issue disagreement questions**, and `issues_selected`. `dictionary.csv` maps lowercase cleaned names to original fields; `response_options.csv` records original category codes and labels.

The broad race/ethnicity field avoids much of the disclosure suppression in the detailed source field.

Cleaning: retain every respondent; preserve ID as text; validate finite positive weights; keep issue indicators as integer 0/1; label other coded categories as factors in RDS; map source categories containing SKIPPED, REFUSED, DISCLOSURE or NOT ASKED to NA; sort by ID. No imputation. Source codes and distinctions remain available in the full archive. CSV uses readable factor labels and blanks for missing values.

## Interpretation

- The issue question asks for the **top three** among 12 issues. Not selected does not mean opposed or unimportant. The selection cap affects correlations and association rules.
- All 113,020 records remain; 282 selected no issues. Treat those records explicitly when defining a basket-analysis denominator; do not silently assume indifference.
- Six `diffview_*` items ask whether the respondent could vote for a candidate with a different position on that issue. These offer an additional set of categorical associations.
- `housevote` combines reported/intended choice in a pre-election survey; it is not a validated vote or an official result. Registered voters include nonvoters.
- Use `chep_weight` for population summaries. Standard `arules::apriori()` support/confidence/lift are unweighted; label them sample descriptions, or calculate weighted measures separately.
- Keep missing values distinct from no/false. Factor codes are not meaningful numeric scales. Some full-survey questions are restricted to states or subsets; consult the questionnaire.
- NORC weights may be revised against final election counts. Everyone should use this frozen snapshot.
- Discoveries need held-out confirmation and sensitivity checks; party composition can explain apparent issue bundles. Association is not causation.

## Reproduce and verify

`Rscript scripts/prepare_track4.R` regenerates the starter from the archived CSV and codebook offline. Requires dplyr/readr; participant loading uses base R. `python3 scripts/download_track4.py` refreshes the upstream snapshot and may change results. Provenance and hashes: `../raw/track4/provenance.json` and root `checksums.sha256`.

`validation/track4_report.txt` records dimensions, keys, codes, weights and complete CSV/RDS round-trip checks; `validation/track4_missingness.csv` records missingness. Private example analyses are not published.

Track 4 download sizes: starter RDS **1.52 MB**, starter CSV ZIP **2.97 MB**, full source CSV ZIP **15.12 MB** (original CSV **88.18 MB**). Sizes are decimal MB, rounded.
