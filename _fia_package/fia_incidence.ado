*! version 0.1.0  01May2026
* fia_incidence — Netcash incidence (id=37) + Conditional incidence (id=38)
* Wraps logic from 3-02-Netcash_Incidence.do and 3-12-Conditional_Incidence.do

cap program drop fia_incidence
program fia_incidence, rclass
	version 16.0
	syntax [aw fw pw]
	
	local wt "[`weight'`exp']"
	
	tempfile _fia_data
	save `_fia_data'
	
	* ---------------------------------------------------------------
	* A. Netcash Incidence (id=37)
	* ---------------------------------------------------------------
	foreach y in ymp yd {
		u `_fia_data', clear
		cap confirm variable `y'_pc
		if _rc continue
		
		* Taxes: negative sign (burden)
		foreach x in ${fia_tax} ${fia_indtax} {
			cap gen share_`x'_pc = -`x'_pc / `y'_pc
		}
		* Transfers & subsidies: positive sign (benefit)
		foreach x in ${fia_transfer} ${fia_inkind} ${fia_subsidy} {
			cap gen share_`x'_pc = `x'_pc / `y'_pc
		}
		
		keep *_deciles_pc share* pondih
		groupfunction `wt', mean(share*) by(`y'_deciles_pc) norestore
		reshape long share_, i(`y'_deciles_pc) j(variable) string
		gen measure = "netcash_`y'"
		rename share_ value
		ren `y'_deciles_pc deciles_pc
		gen indicator  = "incidence"
		gen income     = "`y'"
		gen instrument = variable
		gen context    = "equity"
		
		tempfile netcash_`y'
		save `netcash_`y''
	}
	
	u `netcash_ymp', clear
	cap append using `netcash_yd'
	tempfile _fia_netcash
	save `_fia_netcash'
	
	* ---------------------------------------------------------------
	* B. Conditional Incidence (id=38)
	* ---------------------------------------------------------------
	foreach y in ymp yd {
		u `_fia_data', clear
		cap confirm variable `y'_pc
		if _rc continue
		
		foreach x in ${fia_tax} ${fia_indtax} {
			cap gen share_`x'_pc = -`x'_pc / `y'_pc if `x'_pc != 0 & !missing(`x'_pc)
		}
		foreach x in ${fia_transfer} ${fia_inkind} ${fia_subsidy} {
			cap gen share_`x'_pc = `x'_pc / `y'_pc if `x'_pc != 0 & !missing(`x'_pc)
		}
		
		keep *_deciles_pc share* pondih
		groupfunction `wt', mean(share*) by(`y'_deciles_pc) norestore
		reshape long share_, i(`y'_deciles_pc) j(variable) string
		gen measure = "conditional_incidence_`y'"
		rename share_ value
		ren `y'_deciles_pc deciles_pc
		gen indicator  = "conditional_incidence"
		gen income     = "`y'"
		gen instrument = variable
		gen context    = "equity"
		
		tempfile cond_inc_`y'
		save `cond_inc_`y''
	}
	
	u `cond_inc_ymp', clear
	cap append using `cond_inc_yd'
	
	* Append netcash
	append using `_fia_netcash'
	
	local tmppath "`c(tmpdir)'/fia_result_incidence.dta"
	save "`tmppath'", replace
	global fia_result_incidence "`tmppath'"
	
	di as text "  Incidence: netcash and conditional by decile computed"
end
