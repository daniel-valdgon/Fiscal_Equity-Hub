*! version 0.1.0  01May2026
* fia_poverty — FGT0 (id=4), FGT1 (id=6)
* Wraps logic from 3-04-Poverty_FGT.do

cap program drop fia_poverty
program fia_poverty, rclass
	version 16.0
	syntax [aw fw pw]
	
	local wt "[`weight'`exp']"
	
	sp_groupfunction `wt', poverty(${fia_income_pc}) povertyline(${fia_pline}) by(all)
	
	g indicator = measure
	g context   = "equity"
	
	gen income = ""
	foreach y of global fia_income {
		replace income = "`y'_pc" if variable == "`y'_pc"
	}
	
	keep if inlist(indicator, "fgt0", "fgt1")
	
	tempfile _fia_poverty
	save `_fia_poverty'
	global fia_result_poverty `_fia_poverty'
	
	di as text "  Poverty: FGT0 and FGT1 computed"
end
