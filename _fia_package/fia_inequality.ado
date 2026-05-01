*! version 0.1.0  01May2026
* fia_inequality — Gini (id=5), Theil (id=66)
* Wraps logic from 3-03-Gini_Theil.do

cap program drop fia_inequality
program fia_inequality, rclass
	version 16.0
	syntax [aw fw pw]
	
	local wt "[`weight'`exp']"
	
	* Uses sp_groupfunction for Gini + Theil on all income concepts
	sp_groupfunction `wt', gini(${fia_income_pc}) theil(${fia_income_pc}) by(all)
	
	g indicator = measure
	g context   = "equity"
	
	gen income = ""
	foreach y of global fia_income {
		replace income = "`y'_pc" if variable == "`y'_pc"
	}
	
	keep if inlist(indicator, "gini", "theil")
	
	tempfile _fia_inequality
	save `_fia_inequality'
	global fia_result_inequality `_fia_inequality'
	
	di as text "  Inequality: Gini and Theil computed for ${fia_income}"
end
