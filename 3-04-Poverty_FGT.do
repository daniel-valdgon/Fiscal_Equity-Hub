/*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program:  GSG3 Fiscal Equity Hub - Poverty FGT Measures
* Author:   Daniel Valderrama & JM Monroy
* Date:     May 2026
* Title:    FGT0 (headcount) and FGT1 (poverty gap) by income concept
*--------------------------------------------------------------------------------
* Indicator IDs:
*   4 — Headcount rate (FGT0)
*   6 — Poverty gap (FGT1)
* Context:      EQU (Equity impact)
* Income:       ymp (id=1), yn (id=2), yd (id=4), yc (id=5), yf (id=6)
* Poverty lines: zref (id=1), line_1 (id=2), line_2 (id=3), line_3 (id=4)
* Deciles:      n/a (scalar, by "all")
*--------------------------------------------------------------------------------
* Requires: 3-00-Setup.do to be included first.
*--------------------------------------------------------------------------------*/

*===============================================================================
*---> Poverty measures: FGT0 (headcount) and FGT1 (poverty gap)
*     Uses sp_groupfunction with poverty() and povertyline() options
*===============================================================================

u `output', clear

sp_groupfunction [aw=pondih], poverty(`income_pc') povertyline(`pline') by(all)

*---> Map taxonomy fields
g indicator = measure
g context   = "equity"

global codes "yd_pc yf_pc ymp_pc yc_pc yn_pc"

gen income = ""
forvalues k = 1/5 {
	local code : word `k' of ${codes}
	replace income = "`code'" if variable == "`code'"
}

* Keep FGT0 and FGT1 only (drop FGT2)
keep if inlist(indicator, "fgt0", "fgt1")

tempfile ind_3_04
save `ind_3_04'
