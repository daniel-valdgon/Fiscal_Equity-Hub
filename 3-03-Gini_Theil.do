/*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program:  GSG3 Fiscal Equity Hub - Gini & Theil Inequality
* Author:   Daniel Valderrama & JM Monroy
* Date:     May 2026
* Title:    Gini index and Theil index by income concept
*--------------------------------------------------------------------------------
* Indicator IDs:
*   5  — Gini index
*   66 — Theil index
* Context:      EQU (Equity impact)
* Income:       ymp (id=1), yn (id=2), yd (id=4), yc (id=5), yf (id=6)
* Instruments:  n/a (computed on income concepts)
* Deciles:      n/a (scalar, by "all")
*--------------------------------------------------------------------------------
* Requires: 3-00-Setup.do to be included first.
*--------------------------------------------------------------------------------
* Method A (default): sp_groupfunction — computes Gini+Theil in one call
* Method B (native):  Manual weighted Gini + Theil via Mata, ~same line count,
*                     avoids ado overhead for large datasets.
*--------------------------------------------------------------------------------*/

*===============================================================================
*---> Gini & Theil on each income concept
*===============================================================================

u `output', clear

*--- Method A: sp_groupfunction (comment out B if using A) ---------------------
sp_groupfunction [aw=pondih], gini(${income_pc}) theil(${income_pc}) by(all)

*--- Method B: Native Mata Gini + Theil (alternative) -------------------------
* Uncomment below and comment Method A to use native approach.
* Performance: comparable to sp_groupfunction (both use Mata internally).
/*
local n_inc : word count ${income_pc}
local results_n = `n_inc' * 2
tempname vals
mat `vals' = J(`results_n', 1, .)
local rnames ""
local row 0

foreach v in ${income_pc} {
	* Gini: 2*cov(y, rank(y)) / mean(y)
	sort `v'
	tempvar rnk wsum
	gen double `rnk' = sum(pondih)
	replace `rnk' = (`rnk' - pondih/2) / `rnk'[_N]
	
	qui sum `v' [aw=pondih], meanonly
	local mu = r(mean)
	qui corr `v' `rnk' [aw=pondih], cov
	local cov_yr = r(cov_12)
	local gini_val = 2 * `cov_yr' / `mu'
	
	local ++row
	mat `vals'[`row', 1] = `gini_val'
	local rnames `rnames' gini_`v'
	
	* Theil: sum(w_i * (y_i/mu) * ln(y_i/mu)) / sum(w_i)
	tempvar th_term
	gen double `th_term' = pondih * (`v'/`mu') * ln(`v'/`mu') if `v' > 0
	qui sum `th_term', meanonly
	local sum_th = r(sum)
	qui sum pondih if `v' > 0, meanonly
	local sum_w = r(sum)
	
	local ++row
	mat `vals'[`row', 1] = `sum_th' / `sum_w'
	local rnames `rnames' theil_`v'
	
	drop `rnk' `wsum' `th_term'
}
* Convert to dataset ... (reshape needed, skipping for brevity)
*/

*---> Map taxonomy fields
g indicator = measure
g context   = "equity"

gen income = ""
forvalues k = 1/5 {
	local code : word `k' of ${codes}
	replace income = "`code'" if variable == "`code'"
}

* Keep only Gini and Theil rows
keep if inlist(indicator, "gini", "theil")

tempfile ind_3_03
save `ind_3_03'
