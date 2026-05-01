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
*--------------------------------------------------------------------------------*/

*===============================================================================
*---> Gini & Theil on each income concept
*     Uses sp_groupfunction with gini() and theil() options
*===============================================================================

u `output', clear

sp_groupfunction [aw=pondih], gini(`income_pc') theil(`income_pc') by(all)

*---> Map taxonomy fields
g indicator = measure
g context   = "equity"

global codes "yd_pc yf_pc ymp_pc yc_pc yn_pc"

gen income = ""
forvalues k = 1/5 {
	local code : word `k' of ${codes}
	replace income = "`code'" if variable == "`code'"
}

* Keep only Gini and Theil rows
keep if inlist(indicator, "gini", "theil")

tempfile ind_3_03
save `ind_3_03'
