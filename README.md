# Firm markups and firm patents

This project reproduces individual Compustat firms markups using the method
of _De Loecker, J., Eeckhout, J., & Unger, G. (2020). The rise of market power and the macroeconomic implications. The Quarterly Journal of Economics_ and matches
firms to USPTO patents based on the crosswalk from _Dorn, D., Hanson, G. H., Pisano, G., & Shu, P. (2020). Foreign competition and domestic innovation: Evidence from US patents. American Economic Review: Insights_

## Data
Some data is available on the repo, some has to be downloaded yourself because
they are either too large or not public (compustat).
Here is the list of files that must be in the `data` folder


  - `theta_ALLsectors.dta` [_included_] Sector elasticities estimations from [Jan de Loecker website](https://sites.google.com/site/deloeckerjan/data-and-code)
  - `theta_W_s_window.dta` [_included_] Sector-year Elasticities estimations from [Jan de Loecker website](https://sites.google.com/site/deloeckerjan/data-and-code)
  - `macro_vars.dta` [_included_] Macro variables for deflated measures from [Jan de Loecker website](https://sites.google.com/site/deloeckerjan/data-and-code)
  - `cw_patent_compustat_adhps.dta` [__NOT INCLUDED__] Crosswalk table between patents and compustat ID from [David Dorn website (link [I1]) ](https://www.ddorn.net/data.html#Patents)
  - `patent_assignee.tsv` [__NOT INCLUDED__] Patent to assignee unique ID from [PatentsView](https://patentsview.org/download/data-download-tables)
  - `compustat_northamerica_annual.csv` [__NOT INCLUDED__] Compustat - Capital IQ data
    - Entire database, annual data, consolidated account.
    - __Note:__ The file name must match, don't forget to rename!

## Reproduce
`R` is needed.

Run `make` in the root directory.

## Results 
Two tables are available in the `out` directory

### markup
This table partially reproduces the intermediate table in the code of _De Loecker & al._
Definitions of variable are identical, and the reader may want to investigate their
code for more information.

The estimations mu_0...mu_11 are based on various estimations of input elasticity.

```markdown
markups.csv

   year         Compustat fiscal year
   gvkey        Compustat ID
   sale_D       Deflated sales

   /* Markup estimations based on costshare */
   mu_0         markup; costshare = 0.85 (fig 1 NBER)
   mu_1         markup; costshare = cogs_D/(cogs_D+kexp)
   mu_2         markup; costshare = cogs_D/(cogs_D+xsga_D+kexp) 

   /* Markup estimations based on median costshare by industry */ 
   mu_3         markup; 2 digit NAICS; costshare = cogs_D/(cogs_D+kexp)
   mu_4         markup; 3 digit NAICS; costshare = cogs_D/(cogs_D+kexp)
   mu_5         markup; 4 digits NAICS; costshare = cogs_D/(cogs_D+kexp)
   mu_6         markup; 2 digits NAICS; costshare = cogs_D/(cogs_D+kexp+xsga_D)
   mu_7         markup; 3 digits NAICS; costshare = cogs_D/(cogs_D+kexp+xsga_D)
   mu_8         markup; 4 digits NAICS; costshare = cogs_D/(cogs_D+kexp+xsga_D)
   
   /* Markup estimations based on production function estimate */
   mu_9         markup; estimated theta; sector theta
   mu_10        markup; estimated theta; sector-time theta (Benchmark)
   mu_11        markup; estimated theta; sector-time theta, alternative specification
```

### cw_patent_compustat
This is a many-to-many table linking patents to compustat ID and assignee ID.
One patent may have multiple assignee. `gvkey_adhps` is the original match
from Dorn et al. . I try to match additional patents by leveraging patentsView
disambiguation. The imputed (new) compustat ID is given by `gvkey`. A matching
fit is also given by `impscore` in ]0,1]. 

```markdown
cw_patent_compustat.csv

   patent_id    patent ID in the PatentsView database
   gvkey_adhps  Compustat ID, derived from Dorn et al. paper
   assignee_id  Disambiguated ID from PatentsView
   gvkey        Imputed compustat ID
   impscore     Imputation fit 
```
