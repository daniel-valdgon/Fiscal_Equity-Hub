/*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program:  GSG3 Fiscal Equity Hub - Coverage of Poor & Targeting Errors
* Author:   Daniel Valderrama & JM Monroy
* Date:     May 2026
* Title:    Coverage of the poor, inclusion errors, exclusion errors
*--------------------------------------------------------------------------------
* Indicator IDs:
*   53 — Coverage of the poor
*   54 — Inclusion error: Nonpoor population
*   55 — Inclusion error: Top 10%
*   56 — Inclusion error: Top 20%
*   57 — Exclusion error: Bottom 10%
*   58 — Exclusion error: Bottom 20%
*   59 — Exclusion error: Poor population
* Context:      EQU (Equity impact)
* Income:       Pre-fiscal (ymp, id=1)
* Instruments:  All fiscal instruments (transfers, in-kind, subsidies)
* Reference:    Poverty lines (zref, line_1, line_2, line_3)
*--------------------------------------------------------------------------------
* Definitions:
*   Coverage of the poor    = P(X>0 | poor)
*   Inclusion error nonpoor = P(nonpoor | X>0) = share of beneficiaries nonpoor
*   Inclusion error top 10  = P(top decile | X>0)
*   Inclusion error top 20  = P(top 2 deciles | X>0)
*   Exclusion error bottom 10 = P(X==0 | bottom decile)
*   Exclusion error bottom 20 = P(X==0 | bottom 2 deciles)
*   Exclusion error poor    = P(X==0 | poor)
*--------------------------------------------------------------------------------
* Requires: 3-00-Setup.do to be included first.
*--------------------------------------------------------------------------------*/

u `output', clear

* Instruments for targeting analysis (transfers, in-kind, subsidies — not taxes)
local instruments ${transfer} ${inkind} ${Subsidies}
local instruments : list uniq instruments

* --- Generate beneficiary indicators ---
foreach x of local instruments {
	gen byte _ben_`x' = (`x'_pc > 0 & !missing(`x'_pc))
}

* --- Generate poverty and decile flags ---
gen byte is_poor = (ymp_pc < zref) if !missing(ymp_pc) & !missing(zref)
gen byte bottom10 = (ymp_deciles_pc == 1)  if !missing(ymp_deciles_pc)
gen byte bottom20 = (ymp_deciles_pc <= 2)  if !missing(ymp_deciles_pc)
gen byte top10    = (ymp_deciles_pc == 10) if !missing(ymp_deciles_pc)
gen byte top20    = (ymp_deciles_pc >= 9)  if !missing(ymp_deciles_pc)

tempfile base
save `base'

*===============================================================================
*---> A. Coverage of the poor (id=53)
*     P(X>0 | poor) for each instrument
*===============================================================================

preserve
	keep if is_poor == 1
	collapse (mean) _ben_* [aw=pondih]
	gen all = 1
	reshape long _ben_, i(all) j(variable) string
	rename _ben_ value
	drop all
	gen measure    = "coverage_poor"
	gen indicator  = "coverage_poor"
	gen context    = "equity"
	gen instrument = variable
	gen income     = "ymp"
	gen reference  = "zref"
	gen deciles_pc = .
	tempfile cov_poor
	save `cov_poor'
restore

*===============================================================================
*---> B. Exclusion error: poor (id=59)
*     P(X==0 | poor)
*===============================================================================

preserve
	keep if is_poor == 1
	foreach x of local instruments {
		replace _ben_`x' = 1 - _ben_`x'
	}
	collapse (mean) _ben_* [aw=pondih]
	gen all = 1
	reshape long _ben_, i(all) j(variable) string
	rename _ben_ value
	drop all
	gen measure    = "exclusion_error_poor"
	gen indicator  = "exclusion_error_poor"
	gen context    = "equity"
	gen instrument = variable
	gen income     = "ymp"
	gen reference  = "zref"
	gen deciles_pc = .
	tempfile excl_poor
	save `excl_poor'
restore

*===============================================================================
*---> C. Exclusion error: bottom 10% (id=57) and bottom 20% (id=58)
*===============================================================================

foreach bottomg in bottom10 bottom20 {

	u `base', clear
	keep if `bottomg' == 1
	foreach x of local instruments {
		replace _ben_`x' = 1 - _ben_`x'
	}
	collapse (mean) _ben_* [aw=pondih]
	gen all = 1
	reshape long _ben_, i(all) j(variable) string
	rename _ben_ value
	drop all
	gen measure    = "exclusion_error_`bottomg'"
	gen indicator  = "exclusion_error_`bottomg'"
	gen context    = "equity"
	gen instrument = variable
	gen income     = "ymp"
	gen reference  = ""
	gen deciles_pc = .
	tempfile excl_`bottomg'
	save `excl_`bottomg''
}

*===============================================================================
*---> D. Inclusion error: nonpoor (id=54)
*     P(nonpoor | X>0) = share of beneficiaries who are nonpoor
*===============================================================================

u `base', clear

local n_inst : word count `instruments'
local k 0
tempname inc_mat
mat `inc_mat' = J(`n_inst', 3, .)
local inames ""

foreach x of local instruments {
	local ++k
	local inames `inames' `x'
	
	* Among beneficiaries: share nonpoor
	qui sum is_poor [aw=pondih] if _ben_`x' == 1, meanonly
	mat `inc_mat'[`k', 1] = 1 - r(mean)
	
	* Among beneficiaries: share top 10
	qui sum top10 [aw=pondih] if _ben_`x' == 1, meanonly
	mat `inc_mat'[`k', 2] = r(mean)
	
	* Among beneficiaries: share top 20
	qui sum top20 [aw=pondih] if _ben_`x' == 1, meanonly
	mat `inc_mat'[`k', 3] = r(mean)
}

* Build inclusion error datasets
foreach err_idx in 1 2 3 {
	local err_name = cond(`err_idx'==1, "inclusion_error_nonpoor", ///
	                 cond(`err_idx'==2, "inclusion_error_top10", ///
	                                    "inclusion_error_top20"))
	clear
	set obs `n_inst'
	gen variable = ""
	gen value = .
	forvalues j = 1/`n_inst' {
		local vname : word `j' of `inames'
		replace variable = "`vname'" in `j'
		replace value = `inc_mat'[`j', `err_idx'] in `j'
	}
	gen measure    = "`err_name'"
	gen indicator  = "`err_name'"
	gen context    = "equity"
	gen instrument = variable
	gen income     = "ymp"
	gen reference  = cond(`err_idx'==1, "zref", "")
	gen deciles_pc = .
	
	tempfile `err_name'
	save ``err_name''
}

*===============================================================================
*---> E. Append all targeting indicators
*===============================================================================

u `cov_poor', clear
append using `excl_poor'
append using `excl_bottom10'
append using `excl_bottom20'
append using `inclusion_error_nonpoor'
append using `inclusion_error_top10'
append using `inclusion_error_top20'

tempfile ind_3_14
save `ind_3_14'
