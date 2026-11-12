# Set your working directory to analysis-a-thon, then source this file.
# Offline; no package installation needed. RDS preserves types and factor labels.
stopifnot(file.exists('data/track1/tasks.rds'))
tasks <- readRDS('data/track1/tasks.rds')
platforms <- readRDS('data/track1/platforms.rds')
task_tags <- readRDS('data/track1/task_tags.rds')
gss <- readRDS('data/track2/gss_politics.rds')
shipping <- readRDS('data/track3/chokepoints_daily.rds')
shipping_by_type <- readRDS('data/track3/chokepoints_by_ship_type.rds')
event_date <- as.Date('2026-02-28')

# Inspect before choosing an outcome, exclusions, comparison window or model.
str(tasks)
str(gss)
str(shipping)

# Track 1 keys: platform + task_id. Tags are one-to-many.
# Leave unknown price/payment as NA; consider the is_test_or_spam flag explicitly.
# Track 2 keys: year + id. Filter only the outcome needed for your question:
gss_party <- gss[!is.na(gss$partyid), ]
gss_ideology <- gss[!is.na(gss$polviews), ]
# Neither subset has been split for predictive validation. If predicting,
# reserve held-out years before any data-dependent preprocessing or tuning.
# Track 3 keys: portid + date. n_total already includes tankers and cargo.
# Example corridor selection, with no event effect calculated for you:
hormuz <- shipping[shipping$portname == 'Strait of Hormuz', ]

# Bonus Track 4: individual respondents, with binary top-three issue selections.
voters <- readRDS('data/track4/voter_issues.rds')
issue_columns <- setdiff(grep('^issues_', names(voters), value=TRUE), 'issues_selected')
issue_matrix <- as.matrix(voters[issue_columns])
# Nonselection does not mean opposition. Standard arules metrics are unweighted.
# Define how zero-selection records and survey weights enter your analysis.
