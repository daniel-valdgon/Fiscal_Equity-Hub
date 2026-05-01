/*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program:  GSG3 Fiscal Equity Hub - Redistributive Impact & RS Decomposition
* Author:   Daniel Valderrama & JM Monroy
* Date:     May 2026
* Title:    Reynolds-Smolensky, total redistributive & poverty impact
*--------------------------------------------------------------------------------
* Indicator IDs:
*   46 — Total redistributive impact (Gini_pre - Gini_post)
*   47 — Total poverty impact (FGT0_pre - FGT0_post)
*   69 — Reynolds-Smolensky decomposition (Gini_Y - CC_tax + CC_transfer)
*   67 — 90-10 ratio (P90/P10)
*   68 — Absolute Gini (Gini * mean)
* Context:      EQU (Equity impact)
* Income:       Multiple income concepts compared pairwise
*--------------------------------------------------------------------------------
* Method:   Native Stata — these are derived indicators computed from
*           Gini/FGT values already estimated. No sp_groupfunction needed.
*           Uses covconc.ado for concentration coefficients.
*--------------------------------------------------------------------------------
* Requires: 3-00-Setup.do + 3-03-Gini_Theil.do + 3-04-Poverty_FGT.do
*           to have run (needs ind_3_03 and ind_3_04 tempfiles).
*--------------------------------------------------------------------------------*/

*===============================================================================
*---> A. Total Redistributive Impact (id=46)
*     Gini(ymp) - Gini(yd) for pre-fiscal to disposable
*     Gini(ymp) - Gini(yc) for pre-fiscal to consumable
*     Gini(ymp) - Gini(yf) for pre-fiscal to final
*===============================================================================

u `ind_3_03', clear

* Keep only Gini
keep if indicator == "gini"

* Reshape to get Gini values side by side
keep variable value
rename value gini_val
rename variable inc_var

* Create a temp dataset with one row per income concept
tempfile gini_wide
save `gini_wide'

* Calculate pairwise differences
levelsof inc_var, local(inc_list)
local n_inc : word count `inc_list'

* Redistributive impact: Gini(ymp_pc) - Gini(Y_pc) for Y in {yn, yd, yc, yf}
preserve
	keep if inc_var == "ymp_pc"
	local gini_ymp = gini_val[1]
restore

local ri_n = 0
tempname ri_mat
mat `ri_mat' = J(4, 1, .)
local ri_names ""

foreach y in yn_pc yd_pc yc_pc yf_pc {
	preserve
		keep if inc_var == "`y'"
		if _N > 0 {
			local gini_y = gini_val[1]
			local ++ri_n
			mat `ri_mat'[`ri_n', 1] = `gini_ymp' - `gini_y'
			local ri_names `ri_names' `y'
		}
	restore
}

* Build output dataset
clear
local true_n = `ri_n'
if `true_n' == 0 local true_n = 1
set obs `true_n'
gen variable = ""
gen value = .
gen measure = "redistributive_impact"
gen indicator = "redistributive_impact"
gen income = ""
gen context = "equity"
gen deciles_pc = .

forvalues k = 1/`ri_n' {
	local vname : word `k' of `ri_names'
	replace variable = "`vname'" in `k'
	replace income   = "`vname'" in `k'
	replace value    = `ri_mat'[`k', 1] in `k'
}

drop if variable == ""

tempfile redist_impact
save `redist_impact'

*===============================================================================
*---> B. 90-10 Ratio (id=67)
*     Ratio of income at 90th percentile to 10th percentile
*===============================================================================

u `output', clear

foreach y in ${income} {
	qui _pctile `y'_pc [aw=pondih], p(10 90)
	local p10_`y' = r(r1)
	local p90_`y' = r(r2)
}

clear
local n_inc : word count ${income}
set obs `n_inc'
gen variable = ""
gen value = .
gen measure = "p90_p10_ratio"
gen indicator = "p90_p10_ratio"
gen income = ""
gen context = "equity"
gen deciles_pc = .

local k 0
foreach y in ${income} {
	local ++k
	replace variable = "`y'_pc" in `k'
	replace income   = "`y'_pc" in `k'
	if `p10_`y'' != 0 {
		replace value = `p90_`y'' / `p10_`y'' in `k'
	}
}

tempfile ratio_9010
save `ratio_9010'

*===============================================================================
*---> C. Absolute Gini (id=68)
*     Absolute Gini = Gini(Y) * mean(Y)
*===============================================================================

u `output', clear

foreach y in ${income} {
	qui sum `y'_pc [aw=pondih], meanonly
	local mean_`y' = r(mean)
}

u `gini_wide', clear

gen abs_gini = .
foreach y in ${income} {
	replace abs_gini = gini_val * `mean_`y'' if inc_var == "`y'_pc"
}

rename inc_var variable
rename abs_gini value
drop gini_val
gen measure    = "absolute_gini"
gen indicator  = "absolute_gini"
gen income     = variable
gen context    = "equity"
gen deciles_pc = .

tempfile abs_gini
save `abs_gini'

*===============================================================================
*---> D. Total Poverty Impact (id=47)
*     FGT0(ymp) - FGT0(yd) for each poverty line
*===============================================================================

u `ind_3_04', clear
keep if indicator == "fgt0"

* This requires pairing pre-fiscal vs post-fiscal poverty
* For now, save FGT0 values — differencing across income concepts
* is done by comparing variable (income) within each reference (poverty line)

tempfile pov_impact_raw
save `pov_impact_raw'

* Compute differences: FGT0(ymp) - FGT0(Y) for each poverty line
preserve
	keep if variable == "ymp_pc"
	rename value fgt0_ymp
	keep reference fgt0_ymp
	tempfile fgt0_base
	save `fgt0_base'
restore

preserve
	keep if variable != "ymp_pc"
	merge m:1 reference using `fgt0_base', nogen
	gen value_diff = fgt0_ymp - value
	drop value fgt0_ymp
	rename value_diff value
	gen measure   = "poverty_impact"
	gen indicator = "poverty_impact"
	gen context   = "equity"
	gen deciles_pc = .
	rename variable income
	gen variable = income
	tempfile pov_impact
	save `pov_impact'
restore

*===============================================================================
*---> E. Append all derived indicators
*===============================================================================

u `redist_impact', clear
append using `ratio_9010'
append using `abs_gini'
cap append using `pov_impact'

tempfile ind_3_11
save `ind_3_11'
