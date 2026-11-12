# Bonus Track 4: issues in the 2026 midterms

**Question: Which issues united or divided voters before the 2026 midterms?**

Source: [Pew Research Center's October 8, 2026 issue-priority report](https://www.pewresearch.org/politics/2026/10/08/economy-ranks-as-top-issue-in-midterms-for-all-voters-but-partisans-differ-over-the-importance-of-other-issues/), fielded September 28–October 4, 2026. The published table contains **16 issues**, rather than the 11 mentioned in the supplied research note.

| File stem | CSV and RDS dimensions | One row |
|---|---|---|
| `issue_priorities` | 48 × 4 | One issue and voter group |
| `issue_priorities_wide` | 16 × 5 | One issue, with three group percentages |

```r
issues <- readRDS('data/track4/issue_priorities.rds')
```

Groups: all registered voters, Republican candidate supporters, Democratic candidate supporters. The measure is the percentage calling each issue **very important** to their congressional vote. Percentages retain the source's rounding. The chart JSON was extracted programmatically and checked against the corresponding HTML table. `dictionary.csv` documents the variables and `../raw/track4/provenance.json` records source details and hashes.

This is an optional smaller visualization exercise: compare issue priorities, compute percentage-point gaps or identify issues important across groups. The 48 rows are published estimates, not 48 survey respondents. Multiple issues can be important to the same person, so percentages do not sum to 100 across issues. All registered voters overlaps the two supporter groups, and the two supporter groups do not necessarily exhaust all registered voters.

**This is a pre-election survey, not an exit poll or an actual vote-choice dataset.** It does not show which issues caused the election result. It lacks respondent-level joint answers, item/group sample sizes, standard errors and covariance. Do not fit individual-level predictive models, infer significance from rounded gaps alone, or substitute the full survey sample size for subgroup denominators. [Methodology](https://www.pewresearch.org/politics/2026/10/08/midterms-2026-methodology/).

The pasted NBC/Mehlman vote-by-issue numbers were not included: the supplied PDF could not be retrieved through the web tool and those figures were not independently verified. Mixing them into this table would also combine different questions and populations.

Rebuild the tidy exports offline with `Rscript scripts/prepare_track4.R`. Refresh from the publisher with `python3 scripts/download_track4.py`, then rerun preparation. Original published figures remain unchanged; no missing data were imputed and no participant analysis results are included.
