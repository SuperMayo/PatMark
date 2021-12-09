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
cat("Load data... \n")

macro_vars <- read_dta(here::here("data/macro_vars.dta"))
theta <- read_dta(here::here("data/theta_W_s_window.dta"))
theta_fixed <- read_dta(here::here("data/theta_ALLsectors.dta"))
compustat <- fread(here::here("data/compustat_northamerica_annual.csv"))

################################################################################
# Clean compustat
################################################################################
cat("Cleaning... \n")

dt <- compustat %>%
  setorder(gvkey, fyear) %>%
  .[, year := fyear] %>%
  .[, nrobs := .N, by = .(gvkey, year)] %>% # Count obs per firm-year
  .[!((nrobs == 2 | nrobs == 3) & indfmt == "FS")] %>% # Remove fin. services
  .[, .SD[1], by = .(gvkey, year)] %>% # Keep one observation per firm-year
  .[!is.na(naics)] # Drop firms without industry information

# Generate NAICS codes when there are limited digits
for (i in 2:4) {
  dt[, paste0("ind", i, "d") := fifelse(
    nchar(naics) < (i), NA_character_,
    substr(naics, 1, (i))
  )]
}

dt[, newmk2 := prcc_f * csho] # Fiscal year market value prior 1998
dt[is.na(mkvalt), mkvalt := newmk2]

time_thousand_vars <- c(
  "sale", "xlr", "oibdp", "cogs", "xsga",
  "mkvalt", "dvt", "ppegt", "ppent", "intan"
)
keep_vars <- c(
  time_thousand_vars, "gvkey", "year", "naics", "ind2d",
  "ind3d", "ind4d", "xrd", "xad", "emp"
)

to_thousand <- function(x) x * 1000
dt[, lapply(.SD, to_thousand), .SDcols = time_thousand_vars]
dt <- dt[, ..keep_vars]
dt <- merge(dt, macro_vars, by = "year")

# Generate deflated values
deflated_vars <- c(
  "sale", "cogs", "xsga", "mkvalt",
  "ppegt", "ppent", "dvt", "intan", "xlr"
)

dt[, paste0(deflated_vars, "_D") := lapply(.SD, function(x) (x / USGDP) * 100),
  .SDcols = deflated_vars
]

setnames(
  dt, c("ppegt_D", "ppent_D", "dvt_D"),
  c("capital_D", "capital2_D", "dividend_D")
)

dt[, kexp := usercost * capital_D]

# Triming
dt <- dt %>%
  .[sale > 0] %>%
  .[cogs_D > 0] %>%
  .[xsga > 0] %>%
  .[, s_g := sale / cogs] %>%
  .[s_g > 0] %>%
  .[year > 1949]

# 1% triming
dt[, s_g_p_1 := quantile(s_g, 0.01)]
dt[, s_g_p_99 := quantile(s_g, 0.99)]

dt <- dt %>%
  .[s_g > s_g_p_1] %>%
  .[s_g < s_g_p_99]

################################################################################
# Estimate main markups from De Loecker & al. 2020
################################################################################
cat("Compute markups...\n")

# Match elasticities
setDT(theta)
setDT(theta_fixed)
dt <- merge(dt, theta[, ind2d := as.character(ind2d)], by = c("ind2d", "year"))
dt <- merge(dt, theta_fixed[, ind2d := as.character(ind2d)], by = "ind2d")

# costshares estimates
dt[, costshare0 := 0.85] # Calibrated
dt[, costshare1 := cogs_D / (cogs_D + kexp)]
dt[, costshare2 := cogs_D / (cogs_D + xsga_D + kexp)]

# Firm level markup
dt[, paste0("mu_", 0:2) := lapply(.SD, function(x) x * (sale_D / cogs_D)),
  .SDcols = paste0("costshare", 0:2)
]

# NP estimation based on industry median value of costshare
iwalk(cross2(1:2, 2:4), function(x, id) {
  cost <- paste0("costshare", x[1])
  industrylevel <- paste0("ind", x[2], "d")

  dt[, medcost := median(get(cost), na.rm = TRUE),
    by = c(industrylevel, "year")
  ]

  dt[, paste0("mu_", id + 2) := medcost * (sale_D / cogs_D)]
  dt[, medcost := NULL]
})

# With Production Function estimations
dt[, mu_9 := theta_c * (sale_D / cogs_D)]
dt[, mu_10 := theta_WI1_ct * (sale_D / cogs_D)] # benchmark measure
dt[, mu_11 := theta_WI2_ct * (sale_D / cogs_D)]

# Subset data
keepvars <- c("year", "gvkey", "sale_D", paste0("mu_", 0:11))
markups <- dt[, ..keepvars]

# save
cat("Saving...\n")
fwrite(markups, here::here("out/markups.csv"))
