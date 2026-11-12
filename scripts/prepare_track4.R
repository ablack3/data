# Run from repository root. No network access; all respondents retained.
suppressPackageStartupMessages({library(dplyr); library(readr)})
raw_dir <- 'data/raw/track4'
out <- 'data/track4'
dir.create(out, showWarnings=FALSE)
scratch <- tempfile('chep_'); dir.create(scratch)
unzip(file.path(raw_dir,'civichealth_csv.zip'),exdir=scratch)
unzip(file.path(raw_dir,'civichealth_codebook.zip'),exdir=scratch)
# Read source as strings: IDs and categorical codes must not be guessed.
raw <- read_csv(file.path(scratch,'civichealth_datafile.csv'),
  col_types=cols(.default=col_character()),na=c('','NA'),show_col_types=FALSE)
stopifnot(nrow(problems(raw))==0,nrow(raw)==113020,ncol(raw)==402,
  !anyNA(raw$SU_ID),!anyDuplicated(raw$SU_ID))
strip_quotes <- function(x) sub('"$','',sub('^"','',x))
labels <- read_csv(file.path(scratch,'variable_list.csv'),show_col_types=FALSE) |>
  mutate(label=strip_quotes(label))
options <- read_csv(file.path(scratch,'response_options.csv'),
  col_types=cols(.default=col_character()),show_col_types=FALSE) |>
  mutate(value_label=strip_quotes(value_label))
issue_names <- grep('^ISSUES_',names(raw),value=TRUE)
view_names <- grep('^DIFFVIEW_',names(raw),value=TRUE)
context <- c('SU_ID','CHEP_WEIGHT','P_STATE','LIKELYVOTER','HOUSEVOTE',
 'PARTY','PARTY5','IDEO5','AGE6','GENDER3','EDUC','RACETH4','INCOME')
selected <- c(context,issue_names,view_names)
stopifnot(length(issue_names)==12,length(view_names)==6,all(selected %in% names(raw)))
clean <- raw |> select(all_of(selected))
clean$CHEP_WEIGHT <- as.numeric(clean$CHEP_WEIGHT)
stopifnot(all(is.finite(clean$CHEP_WEIGHT)),all(clean$CHEP_WEIGHT>0))
for (v in issue_names) {
  stopifnot(all(clean[[v]] %in% c('0','1')))
  clean[[v]] <- as.integer(clean[[v]])
}
# Label categorical fields. Source-coded nonresponse/disclosure suppression -> NA.
# Original codes and exact missing reasons remain in the archived source CSV.
for (v in setdiff(selected,c('SU_ID','CHEP_WEIGHT',issue_names))) {
  opts <- options |> filter(variable==v)
  if (nrow(opts)==0) next # P_STATE is already a readable state label.
  stopifnot(all(is.na(clean[[v]]) | clean[[v]] %in% opts$value))
  missing_code <- grepl('SKIPPED|REFUSED|DISCLOSURE|NOT ASKED',opts$value_label)
  clean[[v]][clean[[v]] %in% opts$value[missing_code]] <- NA_character_
  clean[[v]] <- factor(clean[[v]],levels=opts$value[!missing_code],labels=opts$value_label[!missing_code])
}
# Check the math here: count selected issues, preserving zero-selection records.
clean$issues_selected <- rowSums(as.data.frame(clean[issue_names]))
stopifnot(all(clean$issues_selected %in% 0:3))
names(clean) <- tolower(names(clean))
clean <- clean |> arrange(su_id)
saveRDS(clean,file.path(out,'voter_issues.rds'),compress='xz')
write_csv(clean,file.path(scratch,'voter_issues.csv'),na='')
# ZIP includes portable CSV and codebook; RDS is separately compressed for base R.
dictionary <- labels |> filter(variable %in% selected) |>
 mutate(source_variable=variable,variable=tolower(variable)) |>
 select(variable,source_variable,label)
dictionary <- bind_rows(dictionary,tibble(variable='issues_selected',source_variable=NA_character_,label='Number of selected top-priority issues (0-3); zero is not interpreted as indifference.'))
write_csv(dictionary,file.path(out,'dictionary.csv'))
write_csv(options |> filter(variable %in% selected),file.path(out,'response_options.csv'))
file.copy(file.path(out,c('dictionary.csv','response_options.csv')),scratch,overwrite=TRUE)
zip_path <- normalizePath(out)
old <- getwd(); setwd(scratch)
utils::zip(file.path(zip_path,'voter_issues_csv.zip'),c('voter_issues.csv','dictionary.csv','response_options.csv'),flags='-q -9 -X')
setwd(old)
# Verify both delivered formats independently and compare every value.
rds <- readRDS(file.path(out,'voter_issues.rds'))
unzip(file.path(out,'voter_issues_csv.zip'),exdir=scratch)
csv <- read.csv(file.path(scratch,'voter_issues.csv'),colClasses='character',na.strings='',check.names=FALSE)
stopifnot(identical(clean,rds),nrow(csv)==nrow(clean),identical(names(csv),names(clean)))
for (v in names(clean)) {
 if (is.numeric(clean[[v]])) stopifnot(isTRUE(all.equal(as.numeric(csv[[v]]),clean[[v]],check.attributes=FALSE)))
 else stopifnot(identical(csv[[v]],as.character(clean[[v]])))
}
write_csv(tibble(variable=names(clean),missing=vapply(clean,function(x)sum(is.na(x)),integer(1))), 'validation/track4_missingness.csv')
report <- c('PASS: source 113020 x 402; unique nonmissing SU_ID.',
 paste0('PASS: delivered voter_issues ',nrow(clean),' x ',ncol(clean),'; all respondents retained.'),
 'PASS: twelve issue indicators complete and binary; selections range 0-3.',
 paste0('Zero-selection records retained: ',sum(clean$issues_selected==0),'.'),
 'PASS: survey weights positive and finite; category codes checked against codebook.',
 'PASS: compressed RDS and zipped CSV load in R and agree in every cell.',
 'Nonresponse and disclosure-suppression codes mapped to NA in selected categorical fields; no imputation.',
 'Raw CSV preserves all 402 columns and original codes. See track4_missingness.csv.')
writeLines(report,'validation/track4_report.txt');cat(paste(report,collapse='\n'),'\n')
unlink(scratch,recursive=TRUE)
