/*------------------------------------------------------------------------------
  Test v2: Compare frame-based approach vs tempfile approach
  Focus on actual computed values (not sort-order-dependent first() metadata)
------------------------------------------------------------------------------*/

clear all
set more off

*--- Paths ---
global root "C:\Users\wb419055\OneDrive - WBG\GSG3\GSG Fiscal Equity - WB Group - Fiscal Equity Hub\Workspace\Data Hub"
global scripts "${root}/02-Scripts/wb419055"
global microdata "${root}/01-Data/01-02-FIA_Microdata"
global dataaux "${root}/01-Data/00-Aux/temp"

* Load ado files
local dirfiles: dir "$scripts/_ado/" files "*.ado"
foreach ado of local dirfiles {
	run "$scripts/_ado/`ado'"
}

*--- Macros (assuming globals are empty, use defaults) ---
local tax dirtax_total sscontribs_total
local indtax indtax_total Tax_VAT
local inkind inktransf_total education_inKind
local transfer dirtransf_total
local Subsidies subsidy_total subsidy_elec subsidy_fuel subsidy_water
local income ymp yn yd yc yf
local concs `tax' `indtax' `transfer' `inkind' `income' `Subsidies'

foreach x in tax indtax inkind transfer income concs Subsidies {
	local `x'_pc
	foreach y of local `x' {
		local `x'_pc ``x'_pc' `y'_pc
	}
}

*--- Load one dataset (ECU) ---
use "${microdata}/ECU/ECU_ENEMDU_S2024_P2024_v01/HFMD/ECU_ENEMDU_S2024_P2024_v01.dta", clear

* Create bins
foreach bins in deciles centile millile {
	cap noisily drop *`bins'_pc*
}

set seed 80292367
local i=0
foreach y in ymp yd {
	local ++i
	quantiles `y'_pc [w=pondih], gen(`y'_deciles_pc) nq(10) stable
	quantiles `y'_pc [w=pondih], gen(`y'_centile_pc) nq(100) stable
	quantiles `y'_pc [w=pondih], gen(`y'_millile_pc) nq(1000) stable
}

tempfile output
save `output', replace

*==============================================================================
* METHOD 1: ORIGINAL (tempfile-based) - for y=ymp
*==============================================================================
dis _n "===== RUNNING OLD METHOD (tempfiles) ====="

local y "ymp"

u `output', clear
keep hhid `concs_pc' pondih *_centile_pc *_deciles_pc *_millile_pc

foreach x in `tax' `indtax' {
	gen share_`x'_pc= -`x'_pc/ `y'_pc
}
foreach x in `transfer' `inkind' `Subsidies' {
	gen share_`x'_pc= `x'_pc/ `y'_pc
}

keep *_deciles_pc *_centile_pc *_millile_pc share* pondih

tempfile aux1
save `aux1', replace

groupfunction [aw=pondih], mean(share*) first(pondih *_centile_pc *_deciles_pc) by(`y'_millile_pc)
reshape long share_, i(`y'_millile_pc) j(variable) string
	gen measure = "netcash_`y'_millile"
	rename share_ value
	ren `y'_millile_pc millile_pc
tempfile aux2_mill
save `aux2_mill', replace

use `aux1', clear
groupfunction [aw=pondih], mean(share*) by(`y'_centile_pc) norestore
reshape long share_, i(`y'_centile_pc) j(variable) string
	gen measure = "netcash_`y'_centile"
	rename share_ value
	ren `y'_centile_pc centile_pc
tempfile aux2_cent
save `aux2_cent', replace

use `aux1', clear
groupfunction [aw=pondih], mean(share*) by(`y'_deciles_pc) norestore
reshape long share_, i(`y'_deciles_pc) j(variable) string
	gen measure = "netcash_`y'_decile"
	rename share_ value
	ren `y'_deciles_pc decile_pc

append using `aux2_cent'
append using `aux2_mill'

gen indicator = "incidence"
gen income = "`y'"
gen instrument = variable

* Keep only the meaningful analysis variables and sort deterministically
keep measure variable value indicator income instrument millile_pc centile_pc decile_pc
sort measure variable millile_pc centile_pc decile_pc

tempfile old_result
save `old_result', replace
dis "Old method: `=_N' observations"

*==============================================================================
* METHOD 2: NEW (frame-based)
*==============================================================================
dis _n "===== RUNNING NEW METHOD (frames) ====="

u `output', clear
keep hhid `concs_pc' pondih *_centile_pc *_deciles_pc *_millile_pc

foreach x in `tax' `indtax' {
	gen share_`x'_pc= -`x'_pc/ `y'_pc
}
foreach x in `transfer' `inkind' `Subsidies' {
	gen share_`x'_pc= `x'_pc/ `y'_pc
}

keep *_deciles_pc *_centile_pc *_millile_pc share* pondih

* Store micro-data in a frame for reuse (avoids disk I/O)
cap frame drop fr_micro
frame copy default fr_micro, replace

* --- Millile level ---
groupfunction [aw=pondih], mean(share*) first(pondih *_centile_pc *_deciles_pc) by(`y'_millile_pc)
reshape long share_, i(`y'_millile_pc) j(variable) string
	gen measure = "netcash_`y'_millile"
	rename share_ value
	ren `y'_millile_pc millile_pc
cap frame drop fr_mill
frame copy default fr_mill, replace

* --- Centile level ---
frame copy fr_micro default, replace
groupfunction [aw=pondih], mean(share*) by(`y'_centile_pc) norestore
reshape long share_, i(`y'_centile_pc) j(variable) string
	gen measure = "netcash_`y'_centile"
	rename share_ value
	ren `y'_centile_pc centile_pc
cap frame drop fr_cent
frame copy default fr_cent, replace

* --- Decile level ---
frame copy fr_micro default, replace
groupfunction [aw=pondih], mean(share*) by(`y'_deciles_pc) norestore
reshape long share_, i(`y'_deciles_pc) j(variable) string
	gen measure = "netcash_`y'_decile"
	rename share_ value
	ren `y'_deciles_pc decile_pc

* Combining milliles, centiles, and deciles (decile already in default)
tempfile _tf_cent _tf_mill
frame fr_cent: save `_tf_cent'
frame fr_mill: save `_tf_mill'
append using `_tf_cent'
append using `_tf_mill'

* Cleanup frames
frame drop fr_micro
frame drop fr_mill
frame drop fr_cent

gen indicator = "incidence"
gen income = "`y'"
gen instrument = variable

* Keep only the meaningful analysis variables and sort deterministically
keep measure variable value indicator income instrument millile_pc centile_pc decile_pc
sort measure variable millile_pc centile_pc decile_pc

tempfile new_result
save `new_result', replace
dis "New method: `=_N' observations"

*==============================================================================
* COMPARISON
*==============================================================================
dis _n "===== COMPARING RESULTS ====="

use `old_result', clear
dis "Old obs: `=_N'"
cf _all using `new_result'

dis _n as result "SUCCESS: Both methods produce IDENTICAL results."
dis "The frame-based approach is validated."

