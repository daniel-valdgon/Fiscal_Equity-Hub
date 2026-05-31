/*------------------------------------------------------------------------------
* Validation Test: OLD vs NEW frame-based indicator loop
* Purpose: Confirm that the refactored code (using frame { } blocks) produces
*          EXACTLY the same output as the original copy-to-default approach.
*
* Instructions: Run this AFTER Section A (paths/macros) and Section B (detecting 
*   microdata) have executed, and after `output' tempfile exists from the bins step.
*   This test uses the first dataset and first income concept (ymp) with 
*   indicator = "share" as the test case.
*------------------------------------------------------------------------------*/

timer clear 2
timer on 2

di as txt _n "============================================="
di as txt "  VALIDATION: Old vs New frame logic"
di as txt "=============================================" _n

* --- Setup: load data and prepare the wide millile dataset (shared by both) ---
local y "ymp"

u `output', clear	
keep hhid `concs_pc' pondih *_centile_pc *_decile_pc *_millile_pc

foreach x in `tax' `indtax' `transfer' `inkind' `Subsidies' {
	
	if strpos("`taxes'", "`x'") {
		gen share_`x'_pc = - `x'_pc / `y'_pc
	}
	else if strpos("`spending'", "`x'") {	
		gen share_`x'_pc = `x'_pc / `y'_pc
	}

	gen uinc_`x'_pc = `x'_pc / `y'_pc
	gen cinc_`x'_pc = share_`x'_pc if (share_`x'_pc > 0)
	gen cov_`x'_pc  = (share_`x'_pc > 0)
	gen abs_`x'_pc  = `x'_pc

} // eo foreach x

keep `y'_millile_pc share* uinc_* cinc_* cov_* abs_* pondih	
groupfunction [aw=pondih], mean(share* uinc_* cinc_* cov_*) sum(abs_*) first(pondih) by(`y'_millile_pc)

gen `y'_centile_pc = ceil(`y'_millile_pc / 10)
gen `y'_decile_pc  = ceil(`y'_millile_pc / 100)
gen _wt = 1

* Save this as the shared starting point for both methods
tempfile wide_input
save `wide_input'


*===============================================================================
* METHOD A (OLD): frame copy fr_wide → default, repeated 
*===============================================================================

di as txt _n "--- Running OLD method (frame copy to default) ---"

use `wide_input', clear
cap frame drop fr_wide_old
frame copy default fr_wide_old, replace

foreach indicator in share uinc cinc cov abs {

	// Restore wide millile data (old approach: copy to default each time)
	frame copy fr_wide_old default, replace

	// --- Millile level ---
	drop `y'_centile_pc `y'_decile_pc _wt
	reshape long `indicator'_, i(`y'_millile_pc) j(variable) string
	tostring `y'_millile_pc, gen(partition) format(%04.0f)
		replace partition = "pv_pm_" + partition
		drop `y'_millile_pc
	rename `indicator'_ value
	
	cap frame drop fr_mill_old
	frame copy default fr_mill_old, replace

	// --- Centile level ---
	frame copy fr_wide_old default, replace
	drop `y'_millile_pc `y'_decile_pc
	groupfunction [aw=_wt], mean(`indicator'*) by(`y'_centile_pc)
	reshape long `indicator'_, i(`y'_centile_pc) j(variable) string
	tostring `y'_centile_pc, gen(partition) format(%04.0f)
		replace partition = "pv_pc_" + partition
		drop `y'_centile_pc
	rename `indicator'_ value
	
	cap frame drop fr_cent_old
	frame copy default fr_cent_old, replace

	// --- Decile level ---
	frame copy fr_wide_old default, replace
	drop `y'_millile_pc `y'_centile_pc
	groupfunction [aw=_wt], mean(`indicator'*) by(`y'_decile_pc)
	reshape long `indicator'_, i(`y'_decile_pc) j(variable) string
	tostring `y'_decile_pc, gen(partition) format(%04.0f)
		replace partition = "pv_dc_" + partition
		drop `y'_decile_pc
	rename `indicator'_ value

	// --- Combine ---
	tempfile _old_cent _old_mill
	frame fr_cent_old: save `_old_cent'
	frame fr_mill_old: save `_old_mill'
	append using `_old_cent'
	append using `_old_mill'
	cap frame drop fr_mill_old fr_cent_old

	// --- Taxonomy columns ---
	gen indicator = "`indicator'"
	gen income = "`y'"
	gen instrument = variable
	gen category = "CAT_NA"
	gen povertyline = "PL_NONE_N"
	gen pension = "PEN_PDI"

	// Sort for comparison (order-agnostic)
	sort partition variable
	
	tempfile old_`indicator'
	save `old_`indicator''
}
cap frame drop fr_wide_old


*===============================================================================
* METHOD B (NEW): frame { } blocks, no touch on default during computation
*===============================================================================

di as txt _n "--- Running NEW method (frame { } blocks) ---"

use `wide_input', clear
cap frame drop fr_wide_new
frame copy default fr_wide_new, replace

foreach indicator in share uinc cinc cov abs {

	// --- Decile level ---
	cap frame drop fr_dec
	frame copy fr_wide_new fr_dec
	frame fr_dec {
		drop `y'_millile_pc `y'_centile_pc
		groupfunction [aw=_wt], mean(`indicator'*) by(`y'_decile_pc)
		reshape long `indicator'_, i(`y'_decile_pc) j(variable) string
		tostring `y'_decile_pc, gen(partition) format(%04.0f)
			replace partition = "pv_dc_" + partition
			drop `y'_decile_pc
		rename `indicator'_ value
	}

	// --- Centile level ---
	cap frame drop fr_cent
	frame copy fr_wide_new fr_cent
	frame fr_cent {
		drop `y'_millile_pc `y'_decile_pc
		groupfunction [aw=_wt], mean(`indicator'*) by(`y'_centile_pc)
		reshape long `indicator'_, i(`y'_centile_pc) j(variable) string
		tostring `y'_centile_pc, gen(partition) format(%04.0f)
			replace partition = "pv_pc_" + partition
			drop `y'_centile_pc
		rename `indicator'_ value
	}

	// --- Millile level ---
	cap frame drop fr_mill
	frame copy fr_wide_new fr_mill
	frame fr_mill {
		drop `y'_centile_pc `y'_decile_pc _wt
		reshape long `indicator'_, i(`y'_millile_pc) j(variable) string
		tostring `y'_millile_pc, gen(partition) format(%04.0f)
			replace partition = "pv_pm_" + partition
			drop `y'_millile_pc
		rename `indicator'_ value
	}

	// --- Combine ---
	tempfile _tf_dec _tf_cent _tf_mill
	frame fr_dec:  save `_tf_dec'
	frame fr_cent: save `_tf_cent'
	frame fr_mill: save `_tf_mill'
	
	use `_tf_mill', clear
	append using `_tf_dec'
	append using `_tf_cent'
	cap frame drop fr_dec fr_cent fr_mill

	// --- Taxonomy columns ---
	gen indicator = "`indicator'"
	gen income = "`y'"
	gen instrument = variable
	gen category = "CAT_NA"
	gen povertyline = "PL_NONE_N"
	gen pension = "PEN_PDI"

	// Sort for comparison (same sort as OLD)
	sort partition variable
	
	tempfile new_`indicator'
	save `new_`indicator''
}
cap frame drop fr_wide_new


*===============================================================================
* COMPARE: cf _all for each indicator
*===============================================================================

di as txt _n "============================================="
di as txt "  COMPARISON RESULTS"
di as txt "=============================================" _n

local all_pass = 1

foreach indicator in share uinc cinc cov abs {
	
	use `old_`indicator'', clear
	
	cap cf _all using `new_`indicator''
	
	if _rc == 0 {
		di as txt "  [PASS] `indicator': datasets are IDENTICAL"
	}
	else {
		di as err "  [FAIL] `indicator': datasets DIFFER (rc = " _rc ")"
		local all_pass = 0
		
		// Show details of differences
		di as txt "    Checking dimensions..."
		qui count
		local n_old = r(N)
		qui use `new_`indicator'', clear
		qui count
		local n_new = r(N)
		di as txt "    Old N = `n_old', New N = `n_new'"
		
		if `n_old' == `n_new' {
			// Check value differences
			use `old_`indicator'', clear
			rename value value_old
			rename partition partition_old
			
			qui use `new_`indicator'', clear
			rename value value_new
			rename partition partition_new
			
			// Merge on observation number
			use `old_`indicator'', clear
			gen _obs = _n
			tempfile _check_old
			save `_check_old'
			
			use `new_`indicator'', clear
			gen _obs = _n
			merge 1:1 _obs using `_check_old', nogen
			
			qui count if abs(value - value_old) > 1e-10 & !missing(value) & !missing(value_old)
			di as txt "    Value differences (>1e-10): " r(N)
			
			qui count if partition != partition_old
			di as txt "    Partition mismatches: " r(N)
		}
	}
}

di as txt _n "============================================="
if `all_pass' {
	di as result "  ALL TESTS PASSED — outputs are identical"
}
else {
	di as err "  SOME TESTS FAILED — check differences above"
}
di as txt "=============================================" _n

timer off 2
timer list 2
