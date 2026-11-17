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
*--------------------------------------------------------------------------------
* Method A (default): sp_groupfunction — one call for all FGT measures
* Method B (native):  Manual FGT via collapse — straightforward weighted means
*                     of indicator variables. ~2x lines but transparent.
*--------------------------------------------------------------------------------*/

*===============================================================================
*---> Poverty measures: FGT0 (headcount) and FGT1 (poverty gap)
*===============================================================================

u `output', clear

*--- Method A: sp_groupfunction ------------------------------------------------
sp_groupfunction [aw=pondih], poverty(${income_pc}) povertyline(${pline}) by(all)

*--- Method B: Native Stata (alternative) --------------------------------------
* Uncomment below and comment Method A to use native approach.
* Generates FGT alpha=0,1 for each income x poverty line combination.
/*
u `output', clear

* Generate FGT indicator variables
foreach v in ${income_pc} {
	foreach z in ${pline} {
		gen double fgt0_`v'_`z' = (`v' < `z') if !missing(`v') & !missing(`z')
		gen double fgt1_`v'_`z' = max(0, (`z' - `v') / `z') if !missing(`v') & !missing(`z')
	}
}

* Weighted mean = population FGT
preserve
	collapse (mean) fgt0_* fgt1_* [aw=pondih]
	gen all = 1

	* Reshape to long: variable x measure x reference
	reshape long fgt0_ fgt1_, i(all) j(_varline) string

	* Parse variable and reference from _varline
	* _varline format: incomevar_pc_povertyline
	
	rename fgt0_ value_fgt0
	rename fgt1_ value_fgt1
	reshape long value_, i(_varline) j(measure) string
	rename value_ value
	
	* ... additional parsing needed to extract variable/reference
restore
*/

*---> Map taxonomy fields
g indicator = measure
g context   = "equity"

gen income = ""
forvalues k = 1/5 {
	local code : word `k' of ${codes}
	replace income = "`code'" if variable == "`code'"
}

* Keep FGT0 and FGT1 only (drop FGT2)
keep if inlist(indicator, "fgt0", "fgt1")

tempfile ind_3_04
save `ind_3_04'
