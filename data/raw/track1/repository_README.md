# Trends in Agent Hiring

![Cartoon of a human freeing a lobster for an AI agent](art/lobster_liberation.png)

A TidyTuesday dataset of **job postings made by AI agents** on RentAHuman, Taskmarket, Claw Earn and BasedAgents. Every value traces back to a raw API response.

- **Dataset, relationships and data dictionary:** [tidytuesday/readme.md](tidytuesday/readme.md)
- **TidyTuesday submission folder:** `tt_submission/` (generated; not submitted)

## Quick start

Requires R 4.6.1 and [uv](https://docs.astral.sh/uv/). R packages are pinned with renv (`renv.lock`); Python packages for the redact stage are pinned with uv (`uv.lock`, Python 3.12).

```r
install.packages("renv")
renv::restore()
```

```bash
uv sync --locked
```

Rebuild everything from a saved snapshot (no network; needs the raw files, which are not in git):

```bash
Rscript run_all.R
```

Take a new snapshot from the live APIs, then rebuild:

```bash
Rscript run_all.R --fetch
```

## Pipeline

```
live APIs ──fetch──▶ data/raw/<snapshot>/        raw JSON (local only) + manifest.csv (committed)
                         │
                       parse                      offline, deterministic
                         ▼
                     data/interim/<platform>/     per-platform tables (not committed)
                         │
                       build                      keeps AI-agent postings; offline, deterministic
                         ▼
                     data/interim/combined/       unredacted tidy tables (not committed)
                         │
                      redact                      Presidio + spaCy: names, emails, phones, handles, wallets, secrets
                         ▼
                     finalize ─▶ tidytuesday/     platforms.csv, tasks.csv, task_tags.csv
                         │
               check ─ plots ─ submit
                         ▼
             logs/, plots/, art/, tt_submission/
```

| stage | scripts | input | output |
|---|---|---|---|
| fetch | `R/fetch/<platform>.R` | live public APIs | `data/raw/<snapshot>/<platform>/*.json`, `data/raw/<snapshot>/manifest.csv` |
| parse | `R/parse/<platform>.R` | raw JSON | `data/interim/<platform>/*.csv` |
| build | `R/build/dataset.R` | interim CSVs, `R/platforms.R` | `data/interim/combined/*.csv` (AI-agent postings, unredacted) |
| redact | `python/redact_text.py` (run with `uv run`) | combined text columns | `data/interim/redacted/*_text.csv`, `redaction_log.csv` |
| finalize | `R/build/finalize.R` | combined + redacted | `tidytuesday/*.csv`, `logs/redaction_log.csv` |
| check | `R/check/dataset.R` | `tidytuesday/` | pass/fail report (keys, joins, vocabularies, dictionary, checksums, no emails or wallets left); exits 1 on failure |
| plots | `R/plots/prices.R`, `R/plots/task_types.R`, `R/art/render_cartoon.R` | `tidytuesday/`, `art/*.svg` | `plots/`, `art/lobster_liberation.png` |
| submit | `R/tidytuesday/make_submission.R` | `tidytuesday/`, `plots/`, `art/` | `tt_submission/` |

`run_all.R` runs the stages in order, stops at the first failure, and logs each step to `logs/pipeline_runs.csv`. Options: `--fetch`, `--snapshot=<id>`, `--no-submissions` (skip Taskmarket per-task submissions during fetch, about 6 minutes). Each script also runs on its own, e.g. `Rscript R/parse/taskmarket.R --snapshot=2026-09-14`.

## Scope

A posting is kept when its platform labels the poster as an AI agent (RentAHuman `agentType`, Taskmarket `requesterActorType`, Claw Earn `createdBy`, BasedAgents `creator_kind`). The labels are self-reported and not verified. BountyBook was fetched in snapshot 2026-09-14 but is excluded because it does not publish who posted a job.

## Provenance

- **Raw snapshot.** `data/raw/<snapshot>/manifest.csv` has one row per raw file: endpoint, query and paging, request count, record count, fetch start and end times (UTC), warnings, fields removed for privacy, SHA-256 checksum, and R and httr2 versions.
- **Final tables.** `tidytuesday/platforms.csv` carries the snapshot id, raw file path, checksum, fetch time, endpoint and warnings for each platform. `R/check/dataset.R` verifies each checksum when the raw file is present.
- **Platform facts** (URLs, work type, poster field, access terms) are defined once in `R/platforms.R`.
- **Runs.** `logs/pipeline_runs.csv` records every step with times and exit status; `logs/sessionInfo.txt` and `logs/python_packages.txt` hold the R session and Python packages of the latest run.
- **Snapshot 2026-09-14** was created from files saved by earlier scripts (`R/one_off/import_legacy_raw_2026-09-14.R` documents how). Its fetch times come from file modification times, and non-integer JSON numbers were stored rounded to 4 decimal places.

## Personal information

- **At fetch:** RentAHuman bounty `createdBy` (can hold an email) and worker profile names, bios, photos, profile URLs and ids are removed before raw files are written.
- **In cleaning:** `python/redact_text.py` replaces people's names, email addresses, phone numbers, social handles and profile URLs, wallet addresses, street addresses, secrets (API keys, tokens, webhook URLs), IP addresses, and card, bank and SSN numbers in titles, descriptions and tags with placeholders such as `<PERSON>`, using Microsoft Presidio with spaCy `en_core_web_lg`. `logs/redaction_log.csv` records entity counts per posting, never the original text.
- **Not in git:** raw API responses (`data/raw/<snapshot>/<platform>/*.json`) and interim tables (`data/interim/`), because they contain unredacted text and wallet addresses.
- **Credit:** no names are stored in the code. The TidyTuesday `meta.yaml` credit comes from `TT_ATTRIBUTION` / `TT_GITHUB` or the R options `tidytuesdayR.attribution` / `tidytuesdayR.github`; without them the submit stage writes a placeholder and warns.
- **Limits:** name detection is statistical. It removes too much rather than too little (some product and agent names become `<PERSON>`) and may still miss some names.

## Reproducibility limits

- **Fetching is not reproducible.** APIs return their current state, and most endpoints are undocumented. Everything after fetch is reproducible from a snapshot's raw files.
- **Access limits.** RentAHuman anonymous paging stops after 100 rows per query; set `RENTAHUMAN_API_KEY` to use your own key (read from the environment, never written to disk).
- **Terms of use.** RentAHuman's terms prohibit scraping. Get permission before redistributing.
