*! version 0.1.0  01May2026
* fia_concentration — Concentration shares (id=39,40), CC (id=43), Kakwani (id=42)
* Wraps logic from 3-13-Concentration_Shares_CC_Kakwani.do

cap program drop fia_concentration
program fia_concentration, rclass
	version 16.0
	syntax [aw fw pw]
	
	local wt "[`weight'`exp']"
	
	tempfile _fia_data
	save `_fia_data'
	
	* Instruments list (deduplicated)
	local instruments ${fia_tax} ${fia_indtax} ${fia_transfer} ${fia_inkind} ${fia_subsidy}
	local instruments : list uniq instruments
	
	* ---------------------------------------------------------------
	* A. Concentration Shares by Decile (id=39)
	* ---------------------------------------------------------------
	u `_fia_data', clear
	
	foreach x of local instruments {
		gen double w_`x' = `x'_pc * pondih
	}
	
	preserve
		collapse (sum) w_*, by(ymp_deciles_pc)
		foreach x of local instruments {
			qui sum w_`x'
			local tot = r(sum)
			replace w_`x' = w_`x' / `tot' if `tot' != 0
		}
		reshape long w_, i(ymp_deciles_pc) j(variable) string
		rename w_ value
		ren ymp_deciles_pc deciles_pc
		gen measure    = "concentration_share"
		gen indicator  = "concentration_share"
		gen instrument = variable
		gen income     = "ymp"
		gen context    = "equity"
		tempfile conc_shares_dec
		save `conc_shares_dec'
	restore
	
	* ---------------------------------------------------------------
	* B. Concentration Shares by Poor & Non-Poor (id=40)
	* ---------------------------------------------------------------
	u `_fia_data', clear
	gen byte is_poor = (ymp_pc < zref) if !missing(ymp_pc) & !missing(zref)
	
	foreach x of local instruments {
		gen double w_`x' = `x'_pc * pondih
	}
	
	preserve
		collapse (sum) w_*, by(is_poor)
		foreach x of local instruments {
			qui sum w_`x'
			local tot = r(sum)
			replace w_`x' = w_`x' / `tot' if `tot' != 0
		}
		reshape long w_, i(is_poor) j(variable) string
		rename w_ value
		rename is_poor deciles_pc
		gen measure    = "concentration_share_poverty"
		gen indicator  = "concentration_share_poverty"
		gen instrument = variable
		gen income     = "ymp"
		gen context    = "equity"
		gen reference  = "zref"
		tempfile conc_shares_poor
		save `conc_shares_poor'
	restore
	
	* ---------------------------------------------------------------
	* C. Concentration Coefficients (id=43) and Kakwani (id=42)
	* ---------------------------------------------------------------
	u `_fia_data', clear
	
	* Rank by pre-fiscal income
	sort ymp_pc
	gen double _cumw = sum(pondih)
	gen double _F_ymp = (_cumw - pondih/2) / _cumw[_N]
	
	* Gini of ymp_pc
	qui sum ymp_pc [aw=pondih], meanonly
	local mu_ymp = r(mean)
	qui corr ymp_pc _F_ymp [aw=pondih], cov
	local gini_ymp = 2 * r(cov_12) / `mu_ymp'
	
	* CC for each instrument
	local n_instr : word count `instruments'
	local k 0
	tempname cc_mat kak_mat
	mat `cc_mat'  = J(`n_instr', 1, .)
	mat `kak_mat' = J(`n_instr', 1, .)
	local inames ""
	
	foreach x of local instruments {
		local ++k
		local inames `inames' `x'
		qui sum `x'_pc [aw=pondih], meanonly
		local mu_x = r(mean)
		if `mu_x' != 0 {
			qui corr `x'_pc _F_ymp [aw=pondih], cov
			local cc_val = 2 * r(cov_12) / `mu_x'
			mat `cc_mat'[`k', 1]  = `cc_val'
			mat `kak_mat'[`k', 1] = `cc_val' - `gini_ymp'
		}
	}
	
	clear
	set obs `n_instr'
	gen variable = ""
	gen value_cc  = .
	gen value_kak = .
	forvalues k = 1/`n_instr' {
		local vname : word `k' of `inames'
		replace variable  = "`vname'" in `k'
		replace value_cc  = `cc_mat'[`k', 1] in `k'
		replace value_kak = `kak_mat'[`k', 1] in `k'
	}
	reshape long value_, i(variable) j(measure) string
	rename value_ value
	replace measure = "concentration_coefficient" if measure == "cc"
	replace measure = "kakwani"                   if measure == "kak"
	gen indicator  = measure
	gen instrument = variable
	gen income     = "ymp"
	gen context    = "equity"
	gen deciles_pc = .
	
	tempfile cc_kakwani
	save `cc_kakwani'
	
	* ---------------------------------------------------------------
	* D. Append all
	* ---------------------------------------------------------------
	u `conc_shares_dec', clear
	append using `conc_shares_poor'
	append using `cc_kakwani'
	
	tempfile _fia_concentration
	save `_fia_concentration'
	global fia_result_concentration `_fia_concentration'
	
	di as text "  Concentration: shares, CC, Kakwani computed"
end
