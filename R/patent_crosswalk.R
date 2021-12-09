#!/usr/bin/env Rscript 

box::use(
  data.table[...],
  haven[read_dta],
  magrittr[`%>%`],
  here,
  purrr[cross2, iwalk]
)

################################################################################
# Load data
################################################################################
markups <- fread(here::here("out/markups.csv"))
crosswalk <- read_dta(here::here("data/cw_patent_compustat_adhps.dta")) %>%
  setDT()
assignee <- fread(here::here("data/patent_assignee.tsv"))

################################################################################
# Match data
################################################################################

#remove leading 0 in patent id for crosswalk
crosswalk[, patent_id := fifelse(
    substr(patent, 1, 1) == "0", substr(patent, 2, 10), patent
)]

# Merge tables
dt <- merge(crosswalk, assignee, by = "patent_id", all.y = TRUE)

# If some gvkey is not matched (bvecause out of sample),
# we can still try to recover by the assignee id from patentsview.
# However, in patentsview, one patent may have multiple assignee.
# We then define the imputed assignee_id gvkey as the most frequent gvkey
# We can then impute gvkey for patents and have a score based on frequency.
dt[!is.na(gvkey), Ngvkey := .N, by = .(assignee_id, gvkey)]
dt[!is.na(gvkey), fracgvkey := Ngvkey/.N, by = .(assignee_id)]
dt[, gvkey_imp := gvkey[which.max(fracgvkey)], by = assignee_id]
dt[, impscore := max(fracgvkey, na.rm = TRUE), by = assignee_id]

# Keep assignees with a compustat id
dt <- dt[!is.na(gvkey_imp)]

out <- dt[, .(patent_id,
       gvkey_adhps = gvkey,
       assignee_id,
       gvkey = gvkey_imp,
       impscore)]

# save
fwrite(out, here::here("out/cw_patent_compustat.csv"))