# Run from project root: Rscript scripts/prepare_track4.R
suppressPackageStartupMessages({library(dplyr); library(readr); library(tidyr)})
dir.create('data/track4',recursive=TRUE,showWarnings=FALSE)
raw4 <- read_csv('data/raw/track4/pew_issue_priorities.csv',show_col_types=FALSE,
                 col_types=cols(Topic=col_character(),.default=col_double()))
stopifnot(nrow(problems(raw4))==0,nrow(raw4)==16,ncol(raw4)==4,!anyNA(raw4),!anyDuplicated(raw4$Topic))
wide4 <- raw4 |> transmute(issue_id=row_number(),issue=Topic,
  all_registered_voters=`All RVs`,
  republican_candidate_supporters=`Republican candidate supporters`,
  democratic_candidate_supporters=`Democratic candidate supporters`)
long4 <- wide4 |> pivot_longer(cols=-c(issue_id,issue),names_to='voter_group',values_to='percent_very_important')
stopifnot(nrow(long4)==48,ncol(long4)==4,!anyDuplicated(long4[c('issue_id','voter_group')]),
          all(long4$percent_very_important>=0 & long4$percent_very_important<=100))
back4 <- long4 |> pivot_wider(names_from=voter_group,values_from=percent_very_important)
stopifnot(identical(as.data.frame(back4),as.data.frame(wide4)))
write_csv(wide4,'data/track4/issue_priorities_wide.csv')
saveRDS(wide4,'data/track4/issue_priorities_wide.rds')
write_csv(long4,'data/track4/issue_priorities.csv')
saveRDS(long4,'data/track4/issue_priorities.rds')
dictionary4 <- tribble(~variable,~meaning,
  'issue_id','Stable local identifier in source chart order (1-16).',
  'issue','Issue label as published by Pew.',
  'voter_group','All registered voters or supporters of a Republican/Democratic congressional candidate.',
  'percent_very_important','Published rounded percentage (0-100); not a respondent count.',
  'all_registered_voters','Wide-table percentage for all registered voters.',
  'republican_candidate_supporters','Wide-table percentage for Republican candidate supporters.',
  'democratic_candidate_supporters','Wide-table percentage for Democratic candidate supporters.')
write_csv(dictionary4,'data/track4/dictionary.csv')
writeLines(c(
  'PASS: source CSV parses without missing values; 16 unique issue labels.',
  'PASS: 48 unique issue/group records; percentages are between 0 and 100.',
  'PASS: long-to-wide reconstruction exactly matches all source-derived values.',
  'Output: issue_priorities 48 x 4; issue_priorities_wide 16 x 5.',
  'No respondent-level data, subgroup sample sizes or standard errors are provided in this chart table.'),
  'validation/track4_report.txt')
cat(paste(readLines('validation/track4_report.txt'),collapse='\n'),'\n')
