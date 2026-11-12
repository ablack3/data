# Run from the analysis-a-thon directory: Rscript scripts/prepare_data.R
suppressPackageStartupMessages({library(dplyr); library(readr); library(tidyr)})
stopifnot(dir.exists('data/raw'))
dir.create('validation', showWarnings = FALSE)
checks <- character()
check <- function(condition, description) {
  if (!isTRUE(condition)) stop('FAIL: ', description)
  checks <<- c(checks, paste('PASS:', description))
}
read_checked <- function(path, col_types = cols()) {
  x <- read_csv(path, col_types = col_types, show_col_types = FALSE)
  check(nrow(problems(x)) == 0, paste('CSV parse:', path))
  x
}
write_pair <- function(x, stem) {
  write_csv(x, paste0(stem, '.csv'), na = '')
  saveRDS(x, paste0(stem, '.rds'))
}
missingness <- function(x, dataset) {
  tibble(dataset, variable = names(x), rows = nrow(x),
         missing = vapply(x, function(v) sum(is.na(v)), integer(1)))
}

# Track 1: keep the upstream redaction, categories, flags and missing values.
# Explicit types prevent all-missing city/state columns becoming logical.
tasks <- read_checked('data/raw/track1/tasks.csv', cols(
  .default = col_character(),
  text_redacted = col_logical(), is_test_or_spam = col_logical(),
  payment_confirmed = col_logical(), remote_allowed = col_logical(),
  price = col_double(), price_usd = col_double(), spots = col_integer(),
  spots_filled = col_integer(), applications = col_integer(), views = col_integer(),
  estimated_hours = col_double(), created_at = col_datetime(), deadline = col_datetime()
)) |> arrange(platform, task_id)
platforms <- read_checked('data/raw/track1/platforms.csv')
tags <- read_checked('data/raw/track1/task_tags.csv', cols(.default = col_character())) |>
  arrange(platform, task_id, tag)
check(!anyNA(tasks[c('platform', 'task_id', 'created_at')]), 'Track 1 keys and posting timestamps present')
check(!anyDuplicated(tasks[c('platform', 'task_id')]), 'Track 1 posting keys unique')
check(!anyDuplicated(platforms$platform), 'Track 1 platform keys unique')
check(!anyDuplicated(tags), 'Track 1 posting/tag combinations unique')
check(nrow(anti_join(tasks, platforms, by = 'platform')) == 0, 'Track 1 platform foreign keys valid')
check(nrow(anti_join(tags, tasks, by = c('platform', 'task_id'))) == 0, 'Track 1 tag foreign keys valid')
reconcile <- count(tasks, platform) |> left_join(platforms, by = 'platform')
check(all(reconcile$n == reconcile$n_agent_postings), 'Track 1 counts reconcile with upstream platform manifest')
check(all(tasks$price_usd >= 0, na.rm = TRUE), 'Track 1 known USD prices nonnegative')
check(all(is.na(tasks$price_usd) | (tasks$currency %in% c('USD', 'USDC') & tasks$price_usd == tasks$price)),
      'Track 1 USD prices match source USD/USDC amounts')
write_pair(tasks, 'data/track1/tasks')
write_pair(platforms, 'data/track1/platforms')
write_pair(tags, 'data/track1/task_tags')
file.copy('data/raw/track1/readme.md', 'data/track1/source_dictionary.md', overwrite = TRUE)

# Track 2: load the exact package data object without requiring installation.
env <- new.env()
load('data/raw/track2/gss_lon.rda', envir = env)
gss <- env$gss_lon
check(nrow(gss) == 75699 && ncol(gss) == 25, 'Track 2 dimensions match socviz documentation: 75699 x 25')
check(!anyNA(gss[c('year', 'id')]), 'Track 2 respondent keys present')
check(!anyDuplicated(gss[c('year', 'id')]), 'Track 2 year/id keys unique')
check(nlevels(gss$zodiac) == 12, 'Track 2 has 12 labelled zodiac categories')
write_pair(gss, 'data/track2/gss_lon')
# Keep both political outcomes and survey design variables; do not silently
# select complete cases for one outcome or impute unavailable responses.
politics <- gss |>
  filter(!is.na(zodiac)) |>
  select(year, id, zodiac, partyid, polviews, age, sex, race, degree,
         bigregion, income16, religion, wtssps, wtssall, vpsu, vstrat) |>
  arrange(year, id)
check(nrow(politics) > 0 && all(table(politics$zodiac) > 0), 'Track 2 all signs have actual observations')
check(all(is.finite(politics$wtssps) & politics$wtssps > 0), 'Track 2 zodiac subset has positive finite wtssps weights')
check(!anyNA(politics[c('vpsu', 'vstrat')]), 'Track 2 zodiac subset has complete PSU and stratum variables')
write_pair(politics, 'data/track2/gss_politics')
coverage <- gss |> group_by(year) |> summarise(
  n_respondents = n(),
  n_zodiac = sum(!is.na(zodiac)),
  n_zodiac_partyid = sum(!is.na(zodiac) & !is.na(partyid)),
  n_zodiac_polviews = sum(!is.na(zodiac) & !is.na(polviews)),
  n_zodiac_both = sum(!is.na(zodiac) & !is.na(partyid) & !is.na(polviews)),
  .groups = 'drop')
write_csv(coverage, 'validation/gss_coverage_by_year.csv')
write_csv(count(politics, zodiac), 'validation/gss_zodiac_counts.csv')
dictionary <- bind_rows(lapply(names(gss), function(nm) {
  v <- gss[[nm]]
  label <- attr(v, 'label')
  tibble(variable = nm, class = paste(class(v), collapse = '/'),
         source_label = if (is.null(label)) '' else label,
         levels_in_order = paste(levels(v), collapse = ' | '))
}))
write_csv(dictionary, 'data/track2/dictionary.csv')

# Track 3: direct IMF observations, 12 requested corridors. Capacities are left
# in raw data; the event file exposes only documented vessel transit counts.
shipping_raw <- read_checked('data/raw/track3/portwatch.csv')
shipping <- shipping_raw |>
  select(date, portid, portname, n_container, n_dry_bulk, n_general_cargo,
         n_roro, n_tanker, n_cargo, n_total) |> arrange(portid, date)
check(inherits(shipping$date, 'Date'), 'Track 3 dates parsed as Date')
check(!anyDuplicated(shipping[c('portid', 'date')]), 'Track 3 chokepoint/date keys unique')
check(!anyNA(shipping), 'Track 3 no missing dates, identifiers or counts')
check(n_distinct(shipping$portid) == 12, 'Track 3 contains all 12 requested chokepoints')
check(all(shipping |> select(starts_with('n_')) >= 0), 'Track 3 vessel counts nonnegative')
check(all(as.matrix(select(shipping, starts_with('n_'))) %% 1 == 0), 'Track 3 vessel counts are integers')
# Check the math here: n_cargo is already the sum of the four cargo categories.
check(all(with(shipping, n_cargo == n_container + n_dry_bulk + n_general_cargo + n_roro)),
      'Track 3 cargo subcategories reconcile to n_cargo')
# Check the math here: total includes cargo plus tankers, without double counting.
check(all(with(shipping, n_total == n_cargo + n_tanker)), 'Track 3 cargo plus tankers reconcile to n_total')
check(all(format(shipping_raw$date, '%Y-%m-%d') == sprintf('%04d-%02d-%02d', shipping_raw$year, shipping_raw$month, shipping_raw$day)),
      'Track 3 date agrees with source year/month/day')
shipping_coverage <- shipping |> group_by(portid, portname) |> summarise(
  rows = n(), first_date = min(date), last_date = max(date),
  # Check the math here: every date in the closed daily interval must be present.
  expected_days = as.integer(max(date) - min(date)) + 1L, .groups = 'drop')
check(all(shipping_coverage$rows == shipping_coverage$expected_days), 'Track 3 no daily gaps within each chokepoint')
check(n_distinct(shipping_coverage$first_date) == 1 && n_distinct(shipping_coverage$last_date) == 1,
      'Track 3 all chokepoints share the same date coverage')
write_csv(shipping_coverage, 'validation/shipping_coverage.csv')
write_pair(shipping, 'data/track3/chokepoints_daily')
# Five mutually exclusive types only: exclude n_cargo and n_total from long data.
shipping_long <- shipping |>
  select(date, portid, portname, n_container, n_dry_bulk, n_general_cargo, n_roro, n_tanker) |>
  pivot_longer(starts_with('n_'), names_to = 'ship_type', names_prefix = 'n_', values_to = 'transits')
write_pair(shipping_long, 'data/track3/chokepoints_by_ship_type')

write_csv(bind_rows(missingness(tasks, 'tasks'), missingness(platforms, 'platforms'),
                   missingness(tags, 'task_tags'), missingness(gss, 'gss_lon'),
                   missingness(politics, 'gss_politics'), missingness(shipping, 'chokepoints_daily')),
          'validation/missingness.csv')
summary <- c(
  sprintf('Track 1: %s postings; %s platforms; %s tags; %s to %s UTC.', nrow(tasks), nrow(platforms), nrow(tags), min(tasks$created_at), max(tasks$created_at)),
  sprintf('Track 1: %s missing prices; %s missing titles; %s missing descriptions; %s test/spam flags; %s missing payout confirmations.', sum(is.na(tasks$price_usd)), sum(is.na(tasks$title)), sum(is.na(tasks$description)), sum(tasks$is_test_or_spam), sum(is.na(tasks$payment_confirmed))),
  sprintf('Track 2: %s full rows; %s zodiac rows; %s with partyid; %s with polviews; %s with both.', nrow(gss), nrow(politics), sum(!is.na(politics$partyid)), sum(!is.na(politics$polviews)), sum(!is.na(politics$partyid) & !is.na(politics$polviews))),
  sprintf('Track 2 zodiac coverage: %s to %s. 2024 nonmissing zodiac: %s.', min(politics$year), max(politics$year), sum(!is.na(gss$zodiac[gss$year == 2024]))),
  sprintf('Track 3: %s daily rows; %s corridors; %s to %s; %s long rows.', nrow(shipping), n_distinct(shipping$portid), min(shipping$date), max(shipping$date), nrow(shipping_long))
)
writeLines(c(checks, '', summary), 'validation/report.txt')
capture.output(sessionInfo(), file = 'validation/sessionInfo.txt')
cat(paste(c(checks, '', summary), collapse = '\n'), '\n')

# Bonus track has its own raw chart snapshot, dictionary and validation report.
source('scripts/prepare_track4.R')
