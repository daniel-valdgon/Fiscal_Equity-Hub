/*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program:  GSG3 Fiscal Equity Hub - CEQ Effectiveness Indicators
* Author:   Daniel Valderrama & JM Monroy
* Date:     May 2026
* Title:    CEQ Impact Effectiveness and Spending Effectiveness
*--------------------------------------------------------------------------------
* Indicator IDs:
*   48 — CEQ Impact Effectiveness
*   49 — CEQ Spending Effectiveness
* Context:      EQU (Equity impact)
* Income:       Pre-fiscal (ymp, id=1) vs Disposable (yd, id=4)
* Instruments:  Each fiscal instrument
*--------------------------------------------------------------------------------
* Definitions (CEQ methodology, Lustig 2018):
*   Impact Effectiveness (IE):
*     For poverty:    IE = (FGT_pre - FGT_post) / (FGT_pre - FGT_post*)
*       where FGT_post* = poverty if transfers were perfectly targeted
*     For inequality: IE = (Gini_pre - Gini_post) / Gini_pre
*
*   Spending Effectiveness (SE):
*     SE = (FGT_pre - FGT_post) / (spending/GDP)
*     Simplified here as: change in poverty per unit of spending (% of total Y)
*
*   Simplified computable version:
*     IE_poverty(X) = [FGT0(Y) - FGT0(Y+X)] / FGT0(Y)
*       = marginal contribution to poverty / baseline poverty
*     IE_gini(X) = [Gini(Y) - Gini(Y+X)] / Gini(Y)
*       = marginal contribution to inequality / baseline Gini
*     SE_poverty(X) = [FGT0(Y) - FGT0(Y+X)] / [sum(X * w) / sum(Y * w)]
*       = poverty reduction per unit of spending as share of total income
*--------------------------------------------------------------------------------
* Requires: 3-00-Setup.do + 3-05-Marginal_Contributions.do to have run
*           (needs ind_3_05 tempfile with mc_gini and mc_fgt0).
*           Also needs ind_3_03 (Gini) and ind_3_04 (FGT0) for baselines.
*--------------------------------------------------------------------------------*/

*===============================================================================
*---> A. Get baseline Gini and FGT0 for pre-fiscal income (ymp)
*===============================================================================

* Baseline Gini(ymp)
u `ind_3_03', clear
keep if indicator == "gini" & variable == "ymp_pc"
local gini_ymp = value[1]

* Baseline FGT0(ymp) for each poverty line
u `ind_3_04', clear
keep if indicator == "fgt0" & variable == "ymp_pc"
tempfile fgt0_baselines
save `fgt0_baselines'

*===============================================================================
*---> B. CEQ Impact Effectiveness for inequality (id=48, Gini-based)
*     IE_gini(X) = MC_gini(X) / Gini(ymp)
*===============================================================================

u `ind_3_05', clear
keep if indicator == "mc_gini" & income == "ymp_pc"

gen ie_value = value / `gini_ymp' if `gini_ymp' != 0
drop value
rename ie_value value

replace measure   = "ceq_impact_effectiveness_gini"
replace indicator = "ceq_impact_effectiveness"
replace context   = "equity"

tempfile ie_gini
save `ie_gini'

*===============================================================================
*---> C. CEQ Impact Effectiveness for poverty (id=48, FGT0-based)
*     IE_fgt0(X) = MC_fgt0(X, pline) / FGT0(ymp, pline)
*===============================================================================

u `ind_3_05', clear
keep if indicator == "mc_fgt0" & income == "ymp_pc"

* Merge baseline FGT0 for each poverty line
rename reference _ref
merge m:1 _ref using `fgt0_baselines', keepusing(value) nogen keep(match)
rename value fgt0_base
rename _ref reference

gen ie_value = value / fgt0_base if fgt0_base != 0
drop value fgt0_base
rename ie_value value

gen measure   = "ceq_impact_effectiveness_fgt0"
replace indicator = "ceq_impact_effectiveness"
replace context   = "equity"

tempfile ie_fgt0
save `ie_fgt0'

*===============================================================================
*---> D. CEQ Spending Effectiveness (id=49)
*     SE(X) = MC_fgt0(X) / [sum(X*w) / sum(ymp*w)]
*     = poverty reduction per unit of instrument spending as % of total income
*===============================================================================

u `output', clear
qui sum ymp_pc [aw=pondih], meanonly
local total_income = r(sum)

* Compute spending share for each instrument
local instruments ${transfer} ${inkind} ${Subsidies}
local instruments : list uniq instruments

local n_inst : word count `instruments'
local k 0
tempname spend_mat
mat `spend_mat' = J(`n_inst', 1, .)
local inames ""

foreach x of local instruments {
	local ++k
	local inames `inames' `x'
	qui sum `x'_pc [aw=pondih], meanonly
	mat `spend_mat'[`k', 1] = abs(r(sum)) / `total_income'
}

* Build spending share dataset
clear
set obs `n_inst'
gen variable = ""
gen spend_share = .
forvalues j = 1/`n_inst' {
	local vname : word `j' of `inames'
	replace variable = "`vname'" in `j'
	replace spend_share = `spend_mat'[`j', 1] in `j'
}
tempfile spending
save `spending'

* Merge MC_fgt0 with spending shares
u `ind_3_05', clear
keep if indicator == "mc_fgt0" & income == "ymp_pc"
merge m:1 variable using `spending', nogen keep(match)

gen se_value = value / spend_share if spend_share != 0
drop value spend_share
rename se_value value

replace measure   = "ceq_spending_effectiveness"
replace indicator = "ceq_spending_effectiveness"
replace context   = "equity"

tempfile se_fgt0
save `se_fgt0'

*===============================================================================
*---> E. Append all effectiveness indicators
*===============================================================================

u `ie_gini', clear
append using `ie_fgt0'
append using `se_fgt0'

tempfile ind_3_15
save `ind_3_15'
