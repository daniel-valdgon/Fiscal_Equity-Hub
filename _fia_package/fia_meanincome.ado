*! version 0.1.0  01May2026
* fia_meanincome — Mean income by decile (id=70)
* Wraps logic from 3-07-Mean_Income.do

cap program drop fia_meanincome
program fia_meanincome, rclass
	version 16.0
	syntax [aw fw pw]
	
	local wt "[`weight'`exp']"
	
	* Mean of all income + instrument variables by decile
	sp_groupfunction `wt', mean(${fia_concs_pc}) by(ymp_deciles_pc)
	
	ren ymp_deciles_pc deciles_pc
	g indicator = measure
	g context   = "equity"
	
	* Keep only income concepts (drop instruments)
	gen income = ""
	foreach y of global fia_income {
		replace income = "`y'_pc" if variable == "`y'_pc"
	}
	keep if income != ""
	
	local tmppath "`c(tmpdir)'/fia_result_meanincome.dta"
	save "`tmppath'", replace
	global fia_result_meanincome "`tmppath'"
	
	di as text "  Mean income: by decile computed for ${fia_income}"
end
