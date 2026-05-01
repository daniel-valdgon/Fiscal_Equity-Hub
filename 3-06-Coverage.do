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
*--------------------------------------------------------------------------------*/

*===============================================================================
*---> Coverage: share of households with non-zero instrument, by decile
*     Uses sp_groupfunction with coverage() option
*===============================================================================

u `output', clear

sp_groupfunction [aw=pondih], coverage(`concs_pc') by(ymp_deciles_pc)
ren ymp_deciles_pc deciles_pc

g indicator = measure
g context   = "equity"

* Coverage applies only to instruments, not income concepts
* Drop rows where variable matches an income concept
global codes "yd_pc yf_pc ymp_pc yc_pc yn_pc"

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
