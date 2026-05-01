*! version 0.1.0  01May2026
* fia_effectiveness — CEQ Impact Effectiveness (id=48) + Spending Effectiveness (id=49)
* Wraps logic from 3-15-CEQ_Effectiveness.do
* Requires: fia_marginal to have run first ($fia_result_marginal),
*           fia_inequality ($fia_result_inequality),
*           fia_poverty ($fia_result_poverty)

cap program drop fia_effectiveness
program fia_effectiveness, rclass
	version 16.0
	syntax [aw fw pw]
	
	local wt "[`weight'`exp']"
	
	tempfile _fia_data
	save `_fia_data'
	
	* ---------------------------------------------------------------
	* A. Baseline Gini(ymp)
	* ---------------------------------------------------------------
	u ${fia_result_inequality}, clear
	keep if indicator == "gini" & variable == "ymp_pc"
	local gini_ymp = value[1]
	
	* ---------------------------------------------------------------
	* B. Baseline FGT0(ymp) by poverty line
	* ---------------------------------------------------------------
	u ${fia_result_poverty}, clear
	keep if indicator == "fgt0" & variable == "ymp_pc"
	rename value fgt0_base
	keep reference fgt0_base
	tempfile fgt0_baselines
	save `fgt0_baselines'
	
	* ---------------------------------------------------------------
	* C. Impact Effectiveness for inequality (Gini-based)
	*    IE_gini(X) = MC_gini(X) / Gini(ymp)
	* ---------------------------------------------------------------
	u ${fia_result_marginal}, clear
	keep if indicator == "mc_gini" & income == "ymp_pc"
	
	gen ie_value = value / `gini_ymp' if `gini_ymp' != 0
	drop value
	rename ie_value value
	replace measure   = "ceq_impact_effectiveness_gini"
	replace indicator = "ceq_impact_effectiveness"
	replace context   = "equity"
	
	tempfile ie_gini
	save `ie_gini'
	
	* ---------------------------------------------------------------
	* D. Impact Effectiveness for poverty (FGT0-based)
	*    IE_fgt0(X) = MC_fgt0(X, pline) / FGT0(ymp, pline)
	* ---------------------------------------------------------------
	u ${fia_result_marginal}, clear
	keep if indicator == "mc_fgt0" & income == "ymp_pc"
	
	cap confirm variable reference
	if _rc {
		gen value_orig = value
		gen fgt0_base = .
	}
	else {
		merge m:1 reference using `fgt0_baselines', nogen keep(match master)
		gen value_orig = value
	}
	
	gen ie_value = value_orig / fgt0_base if fgt0_base != 0 & !missing(fgt0_base)
	drop value value_orig fgt0_base
	rename ie_value value
	replace measure   = "ceq_impact_effectiveness_fgt0"
	replace indicator = "ceq_impact_effectiveness"
	replace context   = "equity"
	
	tempfile ie_fgt0
	save `ie_fgt0'
	
	* ---------------------------------------------------------------
	* E. Spending Effectiveness
	*    SE(X) = MC_fgt0(X) / [sum(X*w) / sum(ymp*w)]
	* ---------------------------------------------------------------
	u `_fia_data', clear
	qui sum ymp_pc `wt', meanonly
	local total_income = r(sum)
	
	local instruments ${fia_transfer} ${fia_inkind} ${fia_subsidy}
	local instruments : list uniq instruments
	local n_inst : word count `instruments'
	local k 0
	tempname spend_mat
	mat `spend_mat' = J(`n_inst', 1, .)
	local inames ""
	
	foreach x of local instruments {
		local ++k
		local inames `inames' `x'
		qui sum `x'_pc `wt', meanonly
		mat `spend_mat'[`k', 1] = abs(r(sum)) / `total_income'
	}
	
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
	
	u ${fia_result_marginal}, clear
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
	
	* ---------------------------------------------------------------
	* F. Append all effectiveness indicators
	* ---------------------------------------------------------------
	u `ie_gini', clear
	append using `ie_fgt0'
	append using `se_fgt0'
	
	local tmppath "`c(tmpdir)'/fia_result_effectiveness.dta"
	save "`tmppath'", replace
	global fia_result_effectiveness "`tmppath'"
	
	di as text "  Effectiveness: IE_gini, IE_fgt0, SE computed"
end
