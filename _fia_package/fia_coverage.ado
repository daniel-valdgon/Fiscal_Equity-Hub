*! version 0.1.0  01May2026
* fia_coverage — Coverage by decile (id=52) + Targeting errors (id=53-59)
* Wraps logic from 3-06-Coverage.do and 3-14-Targeting_Errors.do

cap program drop fia_coverage
program fia_coverage, rclass
	version 16.0
	syntax [aw fw pw]
	
	local wt "[`weight'`exp']"
	
	tempfile _fia_data
	save `_fia_data'
	
	* ---------------------------------------------------------------
	* A. Coverage by Decile (id=52)
	* ---------------------------------------------------------------
	sp_groupfunction `wt', coverage(${fia_concs_pc}) by(ymp_deciles_pc)
	ren ymp_deciles_pc deciles_pc
	g indicator = measure
	g context   = "equity"
	
	* Drop income concepts — keep only instruments
	gen income = ""
	foreach code in ymp yn yd yc yf {
		replace income = "`code'" if variable == "`code'_pc"
	}
	drop if income != ""
	drop income
	g instrument = variable
	
	tempfile cov_decile
	save `cov_decile'
	
	* ---------------------------------------------------------------
	* B. Targeting Errors (id=53-59)
	* ---------------------------------------------------------------
	u `_fia_data', clear
	
	local instruments ${fia_transfer} ${fia_inkind} ${fia_subsidy}
	local instruments : list uniq instruments
	
	foreach x of local instruments {
		gen byte _ben_`x' = (`x'_pc > 0 & !missing(`x'_pc))
	}
	
	gen byte is_poor  = (ymp_pc < zref)              if !missing(ymp_pc) & !missing(zref)
	gen byte bottom10 = (ymp_deciles_pc == 1)         if !missing(ymp_deciles_pc)
	gen byte bottom20 = (ymp_deciles_pc <= 2)         if !missing(ymp_deciles_pc)
	gen byte top10    = (ymp_deciles_pc == 10)        if !missing(ymp_deciles_pc)
	gen byte top20    = (ymp_deciles_pc >= 9)         if !missing(ymp_deciles_pc)
	
	tempfile base
	save `base'
	
	* --- Coverage of poor (id=53) ---
	preserve
		keep if is_poor == 1
		collapse (mean) _ben_* `wt'
		gen all = 1
		reshape long _ben_, i(all) j(variable) string
		rename _ben_ value
		drop all
		gen measure = "coverage_poor"
		gen indicator = "coverage_poor"
		gen context = "equity"
		gen instrument = variable
		gen income = "ymp"
		gen reference = "zref"
		gen deciles_pc = .
		tempfile cov_poor
		save `cov_poor'
	restore
	
	* --- Exclusion error: poor (id=59) ---
	preserve
		keep if is_poor == 1
		foreach x of local instruments {
			replace _ben_`x' = 1 - _ben_`x'
		}
		collapse (mean) _ben_* `wt'
		gen all = 1
		reshape long _ben_, i(all) j(variable) string
		rename _ben_ value
		drop all
		gen measure = "exclusion_error_poor"
		gen indicator = "exclusion_error_poor"
		gen context = "equity"
		gen instrument = variable
		gen income = "ymp"
		gen reference = "zref"
		gen deciles_pc = .
		tempfile excl_poor
		save `excl_poor'
	restore
	
	* --- Exclusion error: bottom 10/20 (id=57,58) ---
	foreach bottomg in bottom10 bottom20 {
		u `base', clear
		keep if `bottomg' == 1
		foreach x of local instruments {
			replace _ben_`x' = 1 - _ben_`x'
		}
		collapse (mean) _ben_* `wt'
		gen all = 1
		reshape long _ben_, i(all) j(variable) string
		rename _ben_ value
		drop all
		gen measure = "exclusion_error_`bottomg'"
		gen indicator = "exclusion_error_`bottomg'"
		gen context = "equity"
		gen instrument = variable
		gen income = "ymp"
		gen reference = ""
		gen deciles_pc = .
		tempfile excl_`bottomg'
		save `excl_`bottomg''
	}
	
	* --- Inclusion errors (id=54,55,56) ---
	u `base', clear
	local n_inst : word count `instruments'
	local k 0
	tempname inc_mat
	mat `inc_mat' = J(`n_inst', 3, .)
	local inames ""
	
	foreach x of local instruments {
		local ++k
		local inames `inames' `x'
		qui sum is_poor `wt' if _ben_`x' == 1, meanonly
		mat `inc_mat'[`k', 1] = 1 - r(mean)
		qui sum top10 `wt' if _ben_`x' == 1, meanonly
		mat `inc_mat'[`k', 2] = r(mean)
		qui sum top20 `wt' if _ben_`x' == 1, meanonly
		mat `inc_mat'[`k', 3] = r(mean)
	}
	
	foreach err_idx in 1 2 3 {
		local err_name = cond(`err_idx'==1, "inclusion_error_nonpoor", ///
		                 cond(`err_idx'==2, "inclusion_error_top10", ///
		                                    "inclusion_error_top20"))
		clear
		set obs `n_inst'
		gen variable = ""
		gen value = .
		forvalues j = 1/`n_inst' {
			local vname : word `j' of `inames'
			replace variable = "`vname'" in `j'
			replace value = `inc_mat'[`j', `err_idx'] in `j'
		}
		gen measure    = "`err_name'"
		gen indicator  = "`err_name'"
		gen context    = "equity"
		gen instrument = variable
		gen income     = "ymp"
		gen reference  = cond(`err_idx'==1, "zref", "")
		gen deciles_pc = .
		tempfile `err_name'
		save ``err_name''
	}
	
	* ---------------------------------------------------------------
	* C. Append all coverage + targeting
	* ---------------------------------------------------------------
	u `cov_decile', clear
	append using `cov_poor'
	append using `excl_poor'
	append using `excl_bottom10'
	append using `excl_bottom20'
	append using `inclusion_error_nonpoor'
	append using `inclusion_error_top10'
	append using `inclusion_error_top20'
	
	tempfile _fia_coverage
	save `_fia_coverage'
	global fia_result_coverage `_fia_coverage'
	
	di as text "  Coverage: decile coverage + targeting errors computed"
end
