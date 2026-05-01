*! version 0.1.0  01May2026
* fia_benefits — Benefits (concentration shares) by decile (id=39)
* Wraps logic from 3-08-Concentration_Kakwani.do
* Uses sp_groupfunction benefits() to compute share of total instrument
* accruing to each decile.

cap program drop fia_benefits
program fia_benefits, rclass
	version 16.0
	syntax [aw fw pw]
	
	local wt "[`weight'`exp']"
	
	* Benefits = share of each instrument's total by decile
	sp_groupfunction `wt', benefits(${fia_concs_pc}) by(ymp_deciles_pc)
	
	ren ymp_deciles_pc deciles_pc
	g indicator = "benefits"
	g context   = "equity"
	g instrument = variable
	
	* Drop income concepts — keep only instruments
	gen income = ""
	foreach y of global fia_income {
		replace income = "`y'_pc" if variable == "`y'_pc"
	}
	drop if income != ""
	drop income
	
	local tmppath "`c(tmpdir)'/fia_result_benefits.dta"
	save "`tmppath'", replace
	global fia_result_benefits "`tmppath'"
	
	di as text "  Benefits: concentration shares by decile computed"
end
