all: dependencies out/markups.csv out/cw_patent_compustat.csv

dependencies:
	Rscript -e "if (!requireNamespace('renv', quietly = TRUE)) install.packages('renv')"
	Rscript -e "renv::restore()"	

out/markups.csv: R/markup.R data/macro_vars.dta data/theta_ALLsectors.dta data/theta_W_s_window.dta data/compustat_northamerica_annual.csv
	Rscript $<

out/cw_patent_compustat.csv: R/patent_crosswalk.R out/markups.csv data/cw_patent_compustat_adhps.dta data/patent_assignee.tsv
	Rscript $<

.PHONY: dependencies all