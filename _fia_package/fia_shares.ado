*! version 0.1.0  01May2026
* fia_shares — Share of consumption/income by decile (id=60)
* Wraps logic from 3-16-Consumption_Shares.do

cap program drop fia_shares
program fia_shares, rclass
	version 16.0
	syntax [aw fw pw]
	
	local wt "[`weight'`exp']"
	
	* Generate weighted income for each concept
	foreach y of global fia_income {
		gen double w_`y' = `y'_pc * pondih
	}
	
	preserve
		collapse (sum) w_*, by(ymp_deciles_pc)
		
		foreach y of global fia_income {
			qui sum w_`y'
			local tot = r(sum)
			replace w_`y' = w_`y' / `tot' if `tot' != 0
		}
		
		reshape long w_, i(ymp_deciles_pc) j(variable) string
		rename w_ value
		ren ymp_deciles_pc deciles_pc
		
		replace variable = variable + "_pc"
		
		gen measure    = "consumption_share"
		gen indicator  = "consumption_share"
		gen income     = variable
		gen context    = "equity"
		gen instrument = ""
		
		local tmppath "`c(tmpdir)'/fia_result_shares.dta"
		save "`tmppath'", replace
		global fia_result_shares "`tmppath'"
	restore
	
	* Drop temp variables
	cap drop w_*
	
	di as text "  Shares: consumption/income shares by decile computed"
end
