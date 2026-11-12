# Analysis-a-thon

Pick one track. Make one defensible finding. Explain it in three minutes.

Suggested format: solo or teams of up to three; 60 minutes for analysis, followed by three minutes per presentation. R and AI assistance are allowed; disclose assistance and verify the code and claims. Prize: organizer to specify.

## Choose your track

| Track | Challenge | Possible directions |
|---|---|---|
| 1 — Describe the trends in AI-agent job postings | What are AI agents asking others to do, and what do they offer to pay? | Task mix, differences across platforms, prices, completion status, posting-date patterns |
| 2 — Do political preferences cluster by astrological sign? | Do party affiliation or ideology differ meaningfully across zodiac signs? | Within-sign political distributions, survey-year differences, effect sizes, whether apparent patterns survive validation |
| 3 — How did shipping change during the 2026 Hormuz disruption? | How did observed transits change after the February 28 attacks, across Hormuz and other major corridors? | Baseline-relative changes, timing and persistence, tankers versus other cargo, comparison corridors |

The local files and source limitations are described in `README.md`. Use the same frozen files for every team. No live downloads are required.

Track 1 is about jobs posted **by** agents and is a one-time marketplace snapshot. Track 2 uses predefined zodiac groups: no unsupervised clustering algorithm is required. Zodiac data are unavailable for 2024. Track 3 measures observed chokepoint transits, not total world trade or proven causal effects.

## Submit

- One chart, one main finding, and the denominator or comparison behind it.
- A short statement of uncertainty or the strongest alternative explanation.
- A runnable R script or Quarto document and any final figure files.

A well-supported null result is eligible to win. Novelty does not require statistical significance. Do not reward extravagant claims or penalize a team for finding no convincing association.

## Suggested schedule

- Minutes 0–10: choose a track, inspect the data, define the question and comparison.
- Minutes 10–40: analyze and check assumptions.
- Minutes 40–55: produce one clear chart and verify the conclusion.
- Minutes 55–60: freeze the submission and prepare the three-minute explanation.

## Judging — 100 points

| Criterion | Points | What earns credit |
|---|---:|---|
| Analytical validity | 35 | Correct unit, denominator, missing-data handling and comparisons |
| Insight | 25 | A focused question and a conclusion supported by the analysis |
| Communication | 20 | A readable chart and concise explanation |
| Reproducibility | 10 | Code runs from the supplied local files |
| Skepticism | 10 | Meaningful uncertainty, limitations or sensitivity checks |

Suggested prize rule: one overall winner across tracks; ties go to analytical validity, then communication. Duration, team size and prize rule are proposed defaults, not confirmed event logistics.
