/*------------------------------------------------------------------------------
* Self-contained validation: OLD vs NEW frame logic
* Uses simulated data — no dependency on microdata files
*------------------------------------------------------------------------------*/
clear all
set seed 12345

* Load custom ado files
local scripts "C:\Users\wb419055\OneDrive - WBG\GSG3\GSG Fiscal Equity - WB Group - Fiscal Equity Hub\Workspace\Data Hub\02-Scripts\wb419055"
local dirfiles: dir "`scripts'/_ado/" files "*.ado"
foreach ado of local dirfiles {
	run "`scripts'/_ado/`ado'"
}

* --- Simulate a 5000-obs dataset with fake instruments ---
set obs 5000
gen pondih = runiform() * 10 + 1
gen ymp_pc = rnormal(1000, 300)
replace ymp_pc = abs(ymp_pc) + 1

* Fake instruments (3 taxes, 2 transfers)
gen dirtax_total_pc = -rnormal(100, 30)
gen sscontribs_total_pc = -rnormal(50, 15)
gen indtax_total_pc = -rnormal(80, 25)
gen dirtransf_total_pc = rnormal(120, 40)
gen subsidy_total_pc = rnormal(60, 20)

* Create millile bins
quantiles ymp_pc [w=pondih], gen(ymp_millile_pc) nq(1000) stable
gen ymp_centile_pc = ceil(ymp_millile_pc / 10)
gen ymp_decile_pc  = ceil(ymp_millile_pc / 100)

* --- Define locals (mimicking the real script) ---
local tax dirtax_total sscontribs_total
local indtax indtax_total
local taxes `tax' `indtax'
local transfer dirtransf_total
local Subsidies subsidy_total
local spending `transfer' `Subsidies'
local y "ymp"

* --- Generate indicators (same logic as main script) ---
foreach x in `tax' `indtax' `transfer' `Subsidies' {
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
}

keep `y'_millile_pc share* uinc_* cinc_* cov_* abs_* pondih `y'_centile_pc `y'_decile_pc

* Collapse to millile means
groupfunction [aw=pondih], mean(share* uinc_* cinc_* cov_*) sum(abs_*) first(pondih) by(`y'_millile_pc)

gen `y'_centile_pc = ceil(`y'_millile_pc / 10)
gen `y'_decile_pc  = ceil(`y'_millile_pc / 100)
gen _wt = 1

* Save starting point
tempfile wide_input
save `wide_input'

di as txt _n "============================================="
di as txt "  VALIDATION: Old vs New frame logic"
di as txt "=============================================" _n

*===============================================================================
* METHOD A (OLD): frame copy to default repeated
*===============================================================================
di as txt "--- Running OLD method ---"

use `wide_input', clear
cap frame drop fr_wide_old
frame copy default fr_wide_old, replace

foreach indicator in share uinc cinc cov abs {

	frame copy fr_wide_old default, replace

	// Millile
	drop `y'_centile_pc `y'_decile_pc _wt
	reshape long `indicator'_, i(`y'_millile_pc) j(variable) string
	tostring `y'_millile_pc, gen(partition) format(%04.0f)
		replace partition = "pv_pm_" + partition
		drop `y'_millile_pc
	rename `indicator'_ value
	cap frame drop fr_mill_old
	frame copy default fr_mill_old, replace

	// Centile
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

	// Decile
	frame copy fr_wide_old default, replace
	drop `y'_millile_pc `y'_centile_pc
	groupfunction [aw=_wt], mean(`indicator'*) by(`y'_decile_pc)
	reshape long `indicator'_, i(`y'_decile_pc) j(variable) string
	tostring `y'_decile_pc, gen(partition) format(%04.0f)
		replace partition = "pv_dc_" + partition
		drop `y'_decile_pc
	rename `indicator'_ value

	// Combine
	tempfile _old_cent _old_mill
	frame fr_cent_old: save `_old_cent'
	frame fr_mill_old: save `_old_mill'
	append using `_old_cent'
	append using `_old_mill'
	cap frame drop fr_mill_old fr_cent_old

	gen indicator_name = "`indicator'"
	gen income = "`y'"
	gen instrument = variable
	gen category = "CAT_NA"
	gen povertyline = "PL_NONE_N"
	gen pension = "PEN_PDI"

	sort partition variable
	tempfile old_`indicator'
	save `old_`indicator''
}
cap frame drop fr_wide_old

*===============================================================================
* METHOD B (NEW): frame { } blocks
*===============================================================================
di as txt "--- Running NEW method ---"

use `wide_input', clear
cap frame drop fr_wide_new
frame copy default fr_wide_new, replace

foreach indicator in share uinc cinc cov abs {

	// Decile
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

	// Centile
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

	// Millile
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

	// Combine
	tempfile _tf_dec _tf_cent _tf_mill
	frame fr_dec:  save `_tf_dec'
	frame fr_cent: save `_tf_cent'
	frame fr_mill: save `_tf_mill'
	
	use `_tf_mill', clear
	append using `_tf_dec'
	append using `_tf_cent'
	cap frame drop fr_dec fr_cent fr_mill

	gen indicator_name = "`indicator'"
	gen income = "`y'"
	gen instrument = variable
	gen category = "CAT_NA"
	gen povertyline = "PL_NONE_N"
	gen pension = "PEN_PDI"

	sort partition variable
	tempfile new_`indicator'
	save `new_`indicator''
}
cap frame drop fr_wide_new

*===============================================================================
* COMPARE
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
	}
}

di as txt _n "============================================="
if `all_pass' {
	di as result "  ALL TESTS PASSED — outputs are identical"
}
else {
	di as err "  SOME TESTS FAILED — check above"
}
di as txt "=============================================" _n
