/*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program:  GSG3 Fiscal Equity Hub - Coverage by Decile
* Author:   Daniel Valderrama & JM Monroy
* Date:     May 2026
* Title:    Coverage rates by decile (pre-fiscal income)
*--------------------------------------------------------------------------------
* Indicator IDs:
*   52 — Coverage by decile
* Context:      EQU (Equity impact)
* Income:       n/a (coverage is instrument-based, not income-based)
* Instruments:  All fiscal instruments
* Deciles:      1-10 (pre-fiscal ymp)
*--------------------------------------------------------------------------------
* Requires: 3-00-Setup.do to be included first.
*--------------------------------------------------------------------------------
* Method A (default): sp_groupfunction — coverage option
* Method B (native):  gen indicator + collapse mean — simpler, no ado needed.
*                     ~same line count because reshape is needed either way.
*--------------------------------------------------------------------------------*/

*===============================================================================
*---> Coverage: share of households with non-zero instrument, by decile
*===============================================================================

u `output', clear

*--- Method A: sp_groupfunction ------------------------------------------------
sp_groupfunction [aw=pondih], coverage(${concs_pc}) by(ymp_deciles_pc)

*--- Method B: Native collapse (alternative) -----------------------------------
* Coverage = weighted share of hh where X > 0. 
* Uncomment below and comment Method A.
/*
u `output', clear
foreach v in ${concs_pc} {
	gen byte _cov_`v' = (`v' > 0 & !missing(`v'))
}
collapse (mean) _cov_* [aw=pondih], by(ymp_deciles_pc)
reshape long _cov_, i(ymp_deciles_pc) j(variable) string
rename _cov_ value
gen measure = "coverage"
*/
ren ymp_deciles_pc deciles_pc

g indicator = measure
g context   = "equity"

* Coverage applies only to instruments, not income concepts
* Drop rows where variable matches an income concept
* codes defined in 3-00-Setup.do as global

gen income = ""
forvalues k = 1/5 {
	local code : word `k' of ${codes}
	replace income = "`code'" if variable == "`code'"
}

drop if income != ""
drop income

* Instrument mapping
g instrument = variable

tempfile ind_3_06
save `ind_3_06'
