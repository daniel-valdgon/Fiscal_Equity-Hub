/*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program:  GSG3 Fiscal Equity Hub - Concentration Shares, CC & Kakwani
* Author:   Daniel Valderrama & JM Monroy
* Date:     May 2026
* Title:    Concentration shares by decile and by poor/non-poor,
*           concentration coefficients, and Kakwani index
*--------------------------------------------------------------------------------
* Indicator IDs:
*   39 — Concentration shares by decile
*   40 — Concentration shares by poor & non-poor
*   42 — Kakwani index
*   43 — Concentration coefficients
* Context:      EQU (Equity impact)
* Income:       Pre-fiscal (ymp, id=1)
* Instruments:  All fiscal instruments
*--------------------------------------------------------------------------------
* Definitions:
*   Concentration share(decile d) = sum(X_i * w_i, i in d) / sum(X_i * w_i, all)
*   Concentration Coefficient = 2*cov(X, F(Y)) / mean(X) where F(Y) is the
*     cumulative distribution of income Y ranked by Y.
*   Kakwani = CC(instrument) - Gini(income)
*     Positive Kakwani => progressive (for taxes) or regressive (for transfers)
*--------------------------------------------------------------------------------
* Requires: 3-00-Setup.do to be included first.
*           Uses covconc.ado from _ado/ for concentration coefficients.
*--------------------------------------------------------------------------------*/

*===============================================================================
*---> A. Concentration Shares by Decile (id=39)
*     Share of each instrument's total that accrues to each decile
*===============================================================================

u `output', clear

* Instruments only (exclude income concepts from concs) — deduplicated
local instruments ${tax} ${indtax} ${transfer} ${inkind} ${Subsidies}
local instruments : list uniq instruments

* Generate weighted values, then collapse
foreach x of local instruments {
	gen double w_`x' = `x'_pc * pondih
}

preserve
	collapse (sum) w_*, by(ymp_deciles_pc)
	
	foreach x of local instruments {
		qui sum w_`x'
		local tot = r(sum)
		replace w_`x' = w_`x' / `tot' if `tot' != 0
	}

	reshape long w_, i(ymp_deciles_pc) j(variable) string
	rename w_ value
	ren ymp_deciles_pc deciles_pc

	gen measure    = "concentration_share"
	gen indicator  = "concentration_share"
	gen instrument = variable
	gen income     = "ymp"
	gen context    = "equity"

	tempfile conc_shares_dec
	save `conc_shares_dec'
restore

*===============================================================================
*---> B. Concentration Shares by Poor & Non-Poor (id=40)
*     Same as above but by poverty status instead of decile
*===============================================================================

u `output', clear

local instruments ${tax} ${indtax} ${transfer} ${inkind} ${Subsidies}
local instruments : list uniq instruments

* Use first poverty line (zref) for poor/non-poor classification
gen byte is_poor = (ymp_pc < zref) if !missing(ymp_pc) & !missing(zref)

foreach x of local instruments {
	gen double w_`x' = `x'_pc * pondih
}

preserve
	collapse (sum) w_*, by(is_poor)
	
	foreach x of local instruments {
		qui sum w_`x'
		local tot = r(sum)
		replace w_`x' = w_`x' / `tot' if `tot' != 0
	}

	reshape long w_, i(is_poor) j(variable) string
	rename w_ value
	rename is_poor deciles_pc

	gen measure    = "concentration_share_poverty"
	gen indicator  = "concentration_share_poverty"
	gen instrument = variable
	gen income     = "ymp"
	gen context    = "equity"
	gen reference  = "zref"

	tempfile conc_shares_poor
	save `conc_shares_poor'
restore

*===============================================================================
*---> C. Concentration Coefficients (id=43) and Kakwani Index (id=42)
*     CC = 2*cov(X, F(Y)) / mean(X)
*     Kakwani = CC - Gini(Y)
*===============================================================================

u `output', clear

local instruments ${tax} ${indtax} ${transfer} ${inkind} ${Subsidies}
local instruments : list uniq instruments

* Rank households by pre-fiscal income
sort ymp_pc
gen double _cumw = sum(pondih)
gen double _F_ymp = (_cumw - pondih/2) / _cumw[_N]

* Gini of ymp_pc (needed for Kakwani)
qui sum ymp_pc [aw=pondih], meanonly
local mu_ymp = r(mean)
qui corr ymp_pc _F_ymp [aw=pondih], cov
local gini_ymp = 2 * r(cov_12) / `mu_ymp'

* Compute CC for each instrument
local n_instr : word count `instruments'
local k 0

tempname cc_mat kak_mat
mat `cc_mat' = J(`n_instr', 1, .)
mat `kak_mat' = J(`n_instr', 1, .)
local inames ""

foreach x of local instruments {
	local ++k
	local inames `inames' `x'
	
	qui sum `x'_pc [aw=pondih], meanonly
	local mu_x = r(mean)
	
	if `mu_x' != 0 {
		qui corr `x'_pc _F_ymp [aw=pondih], cov
		local cc_val = 2 * r(cov_12) / `mu_x'
		mat `cc_mat'[`k', 1] = `cc_val'
		mat `kak_mat'[`k', 1] = `cc_val' - `gini_ymp'
	}
}

* Build CC dataset
clear
set obs `n_instr'
gen variable = ""
gen value_cc = .
gen value_kak = .

forvalues k = 1/`n_instr' {
	local vname : word `k' of `inames'
	replace variable   = "`vname'" in `k'
	replace value_cc   = `cc_mat'[`k', 1] in `k'
	replace value_kak  = `kak_mat'[`k', 1] in `k'
}

* Reshape to long (CC and Kakwani as separate rows)
reshape long value_, i(variable) j(measure) string
rename value_ value
replace measure = "concentration_coefficient" if measure == "cc"
replace measure = "kakwani" if measure == "kak"

gen indicator  = measure
gen instrument = variable
gen income     = "ymp"
gen context    = "equity"
gen deciles_pc = .

tempfile cc_kakwani
save `cc_kakwani'

*===============================================================================
*---> D. Append all concentration indicators
*===============================================================================

u `conc_shares_dec', clear
append using `conc_shares_poor'
append using `cc_kakwani'

tempfile ind_3_13
save `ind_3_13'
