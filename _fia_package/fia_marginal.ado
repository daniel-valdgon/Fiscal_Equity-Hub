*! version 0.1.0  01May2026
* fia_marginal — Marginal contributions to inequality (id=45) and poverty (id=44)
* Wraps logic from 3-05-Marginal_Contributions.do

cap program drop fia_marginal
program fia_marginal, rclass
	version 16.0
	syntax [aw fw pw]
	
	local wt "[`weight'`exp']"
	
	tempfile _fia_data
	save `_fia_data'
	
	* Instruments + income globals
	local aux_taxes ${fia_tax} ${fia_indtax}
	local aux_all   ${fia_tax} ${fia_indtax} ${fia_transfer} ${fia_subsidy} ${fia_inkind}
	
	* ---------------------------------------------------------------
	* Flip taxes to negative, generate counterfactual incomes
	* ---------------------------------------------------------------
	foreach var of local aux_taxes {
		replace `var'_pc = -`var'_pc
	}
	
	local income2 ""
	foreach inc of global fia_income {
		foreach var of local aux_all {
			gen `inc'_inc_`var' = `inc'_pc + `var'_pc
			local income2 `income2' `inc'_inc_`var'
		}
	}
	
	* Restore tax sign
	foreach var of local aux_taxes {
		replace `var'_pc = -`var'_pc
	}
	
	* ---------------------------------------------------------------
	* Compute Gini and FGT for base + counterfactual incomes
	* ---------------------------------------------------------------
	sp_groupfunction `wt', gini(${fia_income_pc} `income2') ///
		poverty(${fia_income_pc} `income2') povertyline(${fia_pline}) by(all)
	
	g indicator = measure
	g context   = "equity"
	
	tempfile mc_raw
	save `mc_raw'
	
	* ---------------------------------------------------------------
	* A. MC to Inequality (id=45): Gini(Y) - Gini(Y_inc_X)
	* ---------------------------------------------------------------
	u `mc_raw', clear
	keep if indicator == "gini"
	
	gen is_base = 0
	foreach inc of global fia_income {
		replace is_base = 1 if variable == "`inc'_pc"
	}
	
	tempfile gini_base
	preserve
		keep if is_base == 1
		rename value gini_base
		rename variable base_inc
		keep base_inc gini_base
		save `gini_base'
	restore
	
	keep if is_base == 0
	gen base_inc = ""
	gen mc_instrument = ""
	foreach inc of global fia_income {
		replace base_inc = "`inc'_pc" if strpos(variable, "`inc'_inc_") == 1
		replace mc_instrument = subinstr(variable, "`inc'_inc_", "", 1) ///
			if base_inc == "`inc'_pc"
	}
	
	merge m:1 base_inc using `gini_base', nogen keep(match)
	gen mc_value = gini_base - value
	
	keep base_inc mc_instrument mc_value
	rename base_inc income
	rename mc_instrument variable
	rename mc_value value
	gen measure    = "mc_gini"
	gen indicator  = "mc_gini"
	gen context    = "equity"
	gen deciles_pc = .
	gen instrument = variable
	
	tempfile mc_gini
	save `mc_gini'
	
	* ---------------------------------------------------------------
	* B. MC to Poverty (id=44): FGT0(Y) - FGT0(Y_inc_X)
	* ---------------------------------------------------------------
	u `mc_raw', clear
	keep if indicator == "fgt0"
	
	gen is_base = 0
	foreach inc of global fia_income {
		replace is_base = 1 if variable == "`inc'_pc"
	}
	
	tempfile fgt_base
	preserve
		keep if is_base == 1
		rename value fgt_base
		rename variable base_inc
		keep base_inc fgt_base reference
		save `fgt_base'
	restore
	
	keep if is_base == 0
	gen base_inc = ""
	gen mc_instrument = ""
	foreach inc of global fia_income {
		replace base_inc = "`inc'_pc" if strpos(variable, "`inc'_inc_") == 1
		replace mc_instrument = subinstr(variable, "`inc'_inc_", "", 1) ///
			if base_inc == "`inc'_pc"
	}
	
	merge m:1 base_inc reference using `fgt_base', nogen keep(match)
	gen mc_value = fgt_base - value
	
	keep base_inc mc_instrument mc_value reference
	rename base_inc income
	rename mc_instrument variable
	rename mc_value value
	gen measure    = "mc_fgt0"
	gen indicator  = "mc_fgt0"
	gen context    = "equity"
	gen deciles_pc = .
	gen instrument = variable
	
	tempfile mc_fgt0
	save `mc_fgt0'
	
	* ---------------------------------------------------------------
	* Append MC results
	* ---------------------------------------------------------------
	u `mc_gini', clear
	append using `mc_fgt0'
	
	tempfile _fia_marginal
	save `_fia_marginal'
	global fia_result_marginal `_fia_marginal'
	
	di as text "  Marginal contributions: mc_gini, mc_fgt0 computed"
end
