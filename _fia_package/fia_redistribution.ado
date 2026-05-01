*! version 0.1.0  01May2026
* fia_redistribution — Redistributive impact (id=46), Poverty impact (id=47),
*   90-10 ratio (id=67), Absolute Gini (id=68), Reynolds-Smolensky (id=69)
* Wraps logic from 3-11-Redistributive_Impact.do
* Requires: fia_inequality ($fia_result_inequality), fia_poverty ($fia_result_poverty)

cap program drop fia_redistribution
program fia_redistribution, rclass
	version 16.0
	syntax [aw fw pw]
	
	local wt "[`weight'`exp']"
	
	tempfile _fia_data
	save `_fia_data'
	
	* ---------------------------------------------------------------
	* A. Total Redistributive Impact (id=46)
	*    Gini(ymp) - Gini(Y) for Y in {yn, yd, yc, yf}
	* ---------------------------------------------------------------
	u ${fia_result_inequality}, clear
	keep if indicator == "gini"
	keep variable value
	rename value gini_val
	rename variable inc_var
	
	tempfile gini_wide
	save `gini_wide'
	
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
	
	clear
	local true_n = max(`ri_n', 1)
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
	
	* ---------------------------------------------------------------
	* B. 90-10 Ratio (id=67)
	* ---------------------------------------------------------------
	u `_fia_data', clear
	
	foreach y of global fia_income {
		qui _pctile `y'_pc `wt', p(10 90)
		local p10_`y' = r(r1)
		local p90_`y' = r(r2)
	}
	
	clear
	local n_inc : word count ${fia_income}
	set obs `n_inc'
	gen variable = ""
	gen value = .
	gen measure = "p90_p10_ratio"
	gen indicator = "p90_p10_ratio"
	gen income = ""
	gen context = "equity"
	gen deciles_pc = .
	
	local k 0
	foreach y of global fia_income {
		local ++k
		replace variable = "`y'_pc" in `k'
		replace income   = "`y'_pc" in `k'
		if `p10_`y'' != 0 {
			replace value = `p90_`y'' / `p10_`y'' in `k'
		}
	}
	
	tempfile ratio_9010
	save `ratio_9010'
	
	* ---------------------------------------------------------------
	* C. Absolute Gini (id=68)
	*    Absolute Gini = Gini(Y) * mean(Y)
	* ---------------------------------------------------------------
	u `_fia_data', clear
	foreach y of global fia_income {
		qui sum `y'_pc `wt', meanonly
		local mean_`y' = r(mean)
	}
	
	u `gini_wide', clear
	gen abs_gini = .
	foreach y of global fia_income {
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
	
	* ---------------------------------------------------------------
	* D. Total Poverty Impact (id=47)
	*    FGT0(ymp) - FGT0(Y) for each poverty line
	* ---------------------------------------------------------------
	u ${fia_result_poverty}, clear
	keep if indicator == "fgt0"
	
	tempfile pov_raw
	save `pov_raw'
	
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
		cap drop measure
		gen measure   = "poverty_impact"
		cap drop indicator
		gen indicator = "poverty_impact"
		cap drop context
		gen context   = "equity"
		cap drop deciles_pc
		gen deciles_pc = .
		cap drop income
		rename variable income
		gen variable = income
		tempfile pov_impact
		save `pov_impact'
	restore
	
	* ---------------------------------------------------------------
	* E. Reynolds-Smolensky Decomposition (id=69)
	*    RS = Gini(Y_pre) - CC(Y_post ranked by Y_pre)
	* ---------------------------------------------------------------
	u `_fia_data', clear
	
	sort ymp_pc
	gen double _cumw = sum(pondih)
	gen double _F_ymp = (_cumw - pondih/2) / _cumw[_N]
	
	qui sum ymp_pc `wt', meanonly
	local mu_ymp = r(mean)
	qui corr ymp_pc _F_ymp `wt', cov
	local gini_ymp_rs = 2 * r(cov_12) / `mu_ymp'
	
	local rs_n = 0
	local rs_names ""
	tempname rs_mat
	mat `rs_mat' = J(4, 1, .)
	
	foreach y in yn yd yc yf {
		cap confirm variable `y'_pc
		if _rc continue
		qui sum `y'_pc `wt', meanonly
		local mu_y = r(mean)
		if `mu_y' != 0 {
			qui corr `y'_pc _F_ymp `wt', cov
			local cc_post = 2 * r(cov_12) / `mu_y'
			local ++rs_n
			mat `rs_mat'[`rs_n', 1] = `gini_ymp_rs' - `cc_post'
			local rs_names `rs_names' `y'_pc
		}
	}
	
	clear
	local true_n = max(`rs_n', 1)
	set obs `true_n'
	gen variable = ""
	gen value = .
	gen measure    = "reynolds_smolensky"
	gen indicator  = "reynolds_smolensky"
	gen income     = ""
	gen context    = "equity"
	gen deciles_pc = .
	
	forvalues k = 1/`rs_n' {
		local vname : word `k' of `rs_names'
		replace variable = "`vname'" in `k'
		replace income   = "`vname'" in `k'
		replace value    = `rs_mat'[`k', 1] in `k'
	}
	drop if variable == ""
	
	tempfile rs_decomp
	save `rs_decomp'
	
	* ---------------------------------------------------------------
	* F. Append all
	* ---------------------------------------------------------------
	u `redist_impact', clear
	append using `ratio_9010'
	append using `abs_gini'
	cap append using `pov_impact'
	cap append using `rs_decomp'
	
	local tmppath "`c(tmpdir)'/fia_result_redistribution.dta"
	save "`tmppath'", replace
	global fia_result_redistribution "`tmppath'"
	
	di as text "  Redistribution: RI, 90-10, abs Gini, poverty impact, RS computed"
end
