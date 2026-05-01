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
*--------------------------------------------------------------------------------*/

*===============================================================================
*---> Mean income by decile
*     Uses sp_groupfunction with mean() option
*===============================================================================

u `output', clear

sp_groupfunction [aw=pondih], mean(`concs_pc') by(ymp_deciles_pc)
ren ymp_deciles_pc deciles_pc

g indicator = measure
g context   = "equity"

* Map income variables
global codes "yd_pc yf_pc ymp_pc yc_pc yn_pc"

gen income = ""
forvalues k = 1/5 {
	local code : word `k' of ${codes}
	replace income = "`code'" if variable == "`code'"
}

* Mean is only meaningful for income concepts, drop instruments
keep if income != ""

tempfile ind_3_07
save `ind_3_07'
