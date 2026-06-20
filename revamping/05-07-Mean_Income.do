/*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program:  GSG3 Fiscal Equity Hub - Mean Income by Decile
* Author:   Daniel Valderrama & JM Monroy
* Date:     May 2026
* Title:    Mean income by decile (pre-fiscal income)
*--------------------------------------------------------------------------------
* Indicator IDs:
*   70 — Income by decile (mean)
* Context:      EQU (Equity impact)
* Income:       ymp (id=1), yn (id=2), yd (id=4), yc (id=5), yf (id=6)
* Instruments:  n/a
* Deciles:      1-10 (pre-fiscal ymp)
*--------------------------------------------------------------------------------
* Requires: 3-00-Setup.do to be included first.
*--------------------------------------------------------------------------------
* Method A (default): sp_groupfunction — mean option
* Method B (native):  collapse (mean) — simplest possible Stata, no ado needed.
*--------------------------------------------------------------------------------*/

*===============================================================================
*---> Mean income by decile
*===============================================================================

u `output', clear

*--- Method A: sp_groupfunction ------------------------------------------------
sp_groupfunction [aw=pondih], mean(${concs_pc}) by(ymp_deciles_pc)

*--- Method B: Native collapse (alternative) -----------------------------------
* Uncomment below and comment Method A.
/*
u `output', clear
collapse (mean) ${income_pc} [aw=pondih], by(ymp_deciles_pc)
reshape long , i(ymp_deciles_pc) j(variable) string
rename v1 value
gen measure = "mean"
*/
ren ymp_deciles_pc deciles_pc

g indicator = measure
g context   = "equity"

* Map income variables
* codes defined in 3-00-Setup.do as global

gen income = ""
forvalues k = 1/5 {
	local code : word `k' of ${codes}
	replace income = "`code'" if variable == "`code'"
}

* Mean is only meaningful for income concepts, drop instruments
keep if income != ""

tempfile ind_3_07
save `ind_3_07'
