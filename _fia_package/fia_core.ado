*! version 0.1.0  01May2026
* fia_core — Run all FIA indicators and export to Excel
* This is the main production command. It:
*   1. Validates data and sets up policy macros (fia_setup)
*   2. Creates deciles and centiles
*   3. Runs each indicator subcommand in sequence
*   4. Appends results, merges taxonomy, and exports (fia_export)

cap program drop fia_core
program fia_core, rclass
	version 16.0
	syntax [aw fw pw] [if] [in],  ///
		Country(string)             ///
		Output(string)              ///
		[                           ///
		TAXonomy(string)            ///
		TAX(varlist)                ///
		CONTRib(varlist)            ///
		TRANSfer(varlist)           ///
		INDtax(varlist)             ///
		INKind(varlist)             ///
		SUBSidy(varlist)            ///
		PLINe(varlist)              ///
		]
	
	* Weight handling
	local wt "[`weight'`exp']"
	
	* Mark sample
	marksample touse
	
	* ---------------------------------------------------------------
	* Step 1: Setup — validate data, set policy globals
	* ---------------------------------------------------------------
	di as text _n ">>> Step 1: Setup and validation"
	fia_setup `wt' if `touse', ///
		tax(`tax') contrib(`contrib') transfer(`transfer') ///
		indtax(`indtax') inkind(`inkind') subsidy(`subsidy') ///
		pline(`pline')
	
	* ---------------------------------------------------------------
	* Step 2: Create deciles and centiles on pre-fiscal income
	* ---------------------------------------------------------------
	di as text _n ">>> Step 2: Creating deciles and centiles"
	cap drop *_deciles_pc *_centile_pc
	foreach y in ymp yd {
		cap confirm variable `y'_pc
		if _rc == 0 {
			quantiles `y'_pc `wt' if `touse', gen(`y'_deciles_pc) nq(10)
			quantiles `y'_pc `wt' if `touse', gen(`y'_centile_pc) nq(100)
		}
	}
	
	tempfile _fia_output
	save `_fia_output'
	
	* ---------------------------------------------------------------
	* Step 3: Run each indicator module
	* ---------------------------------------------------------------
	
	* 3a. Inequality (Gini, Theil)
	di as text _n ">>> Step 3a: Inequality (Gini, Theil)"
	cap noisily fia_inequality `wt'
	if _rc di as error "  WARNING: fia_inequality returned rc=`=_rc'"
	
	* 3b. Poverty (FGT0, FGT1)
	di as text _n ">>> Step 3b: Poverty (FGT0, FGT1)"
	cap noisily fia_poverty `wt'
	if _rc di as error "  WARNING: fia_poverty returned rc=`=_rc'"
	
	* 3c. Incidence (netcash + conditional)
	di as text _n ">>> Step 3c: Incidence by decile"
	u `_fia_output', clear
	cap noisily fia_incidence `wt'
	if _rc di as error "  WARNING: fia_incidence returned rc=`=_rc'"
	
	* 3d. Marginal contributions
	di as text _n ">>> Step 3d: Marginal contributions"
	u `_fia_output', clear
	cap noisily fia_marginal `wt'
	if _rc di as error "  WARNING: fia_marginal returned rc=`=_rc'"
	
	* 3e. Coverage
	di as text _n ">>> Step 3e: Coverage by decile"
	u `_fia_output', clear
	cap noisily fia_coverage `wt'
	if _rc di as error "  WARNING: fia_coverage returned rc=`=_rc'"
	
	* 3f. Income shares
	di as text _n ">>> Step 3f: Mean income by decile"
	u `_fia_output', clear
	cap noisily fia_shares `wt'
	if _rc di as error "  WARNING: fia_shares returned rc=`=_rc'"
	
	* 3g. Concentration, CC, Kakwani
	di as text _n ">>> Step 3g: Concentration shares, CC, Kakwani"
	u `_fia_output', clear
	cap noisily fia_concentration `wt'
	if _rc di as error "  WARNING: fia_concentration returned rc=`=_rc'"
	
	* 3h. Redistributive impact + RS
	di as text _n ">>> Step 3h: Redistributive impact"
	cap noisily fia_redistribution `wt'
	if _rc di as error "  WARNING: fia_redistribution returned rc=`=_rc'"
	
	* 3i. CEQ effectiveness
	di as text _n ">>> Step 3i: CEQ effectiveness"
	cap noisily fia_effectiveness `wt'
	if _rc di as error "  WARNING: fia_effectiveness returned rc=`=_rc'"
	
	* ---------------------------------------------------------------
	* Step 4: Export
	* ---------------------------------------------------------------
	di as text _n ">>> Step 4: Taxonomy merge and Excel export"
	fia_export, output(`output') country(`country') taxonomy(`taxonomy')
	
	di as text _n ">>> FIA core complete. Output: `output'"
	return local output "`output'"
	return local country "`country'"
end
