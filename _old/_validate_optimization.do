/*------------------------------------------------------------------------------
  Validation: Does aggregating millile means produce the same centile/decile 
  means as computing directly from microdata?
  
  Mathematically:  x_bar_centile = sum(W_m * x_bar_m) / sum(W_m)  for m in centile
  This equals the direct weighted mean IF milliles nest perfectly in centiles.
  
  This script tests whether that nesting holds given how `quantiles` assigns bins.
------------------------------------------------------------------------------*/

* --- Setup (copy from main do-file) ---
clear all

if "`c(username)'"=="wb419055" {
	global root "C:\Users\wb419055\OneDrive - WBG\GSG3\GSG Fiscal Equity - WB Group - Fiscal Equity Hub\Workspace\Data Hub"	
	global scripts "${root}/02-Scripts/wb419055"
}
if "`c(username)'"=="wb527706" {
	global root "C:\Users\wb527706\OneDrive - WBG\GSG Fiscal Equity - WB Group - Data Hub"	
	global scripts "${root}/02-Scripts/wb527706"
}

global microdata "${root}/01-Data/01-02-FIA_Microdata"

local dirfiles: dir "$scripts/_ado/" files "*.ado"
foreach ado of local dirfiles {
	run "$scripts/_ado/`ado'"
}

* --- Load first available dataset ---
local dirs1 : dir `"${microdata}"' dirs "*"
local found 0
foreach subf of local dirs1 {
    if `found' continue
    local cty_path `"${microdata}/`subf'"'
    local dirs2 : dir `"`cty_path'"' dirs "*"
    foreach subf2 of local dirs2 {
        if `found' continue
        local hfmd_path `"`cty_path'/`subf2'/HFMD"'
        local files : dir `"`hfmd_path'"' files "*.dta"
        foreach f of local files {
            if `found' continue
            local f_upper : di strupper("`f'")
            local testpath `"`hfmd_path'/`f_upper'"'
            local found 1
        }
    }
}

di "Testing with: `testpath'"
use `"`testpath'"', clear

* --- Create quantile bins (same as main code) ---
set seed 80292367
local y ymp
quantiles `y'_pc [w=pondih], gen(`y'_decile_pc) nq(10) stable
quantiles `y'_pc [w=pondih], gen(`y'_centile_pc) nq(100) stable
quantiles `y'_pc [w=pondih], gen(`y'_millile_pc) nq(1000) stable

*==============================================================================
* TEST 1: Do milliles nest perfectly within centiles and deciles?
*==============================================================================
di _n "{hline 70}"
di "TEST 1: Checking perfect nesting of milliles within centiles/deciles"
di "{hline 70}"

preserve
	* For each millile, check if min centile == max centile (i.e. unique mapping)
	bys `y'_millile_pc: egen _min_cent = min(`y'_centile_pc)
	bys `y'_millile_pc: egen _max_cent = max(`y'_centile_pc)
	bys `y'_millile_pc: egen _min_dec  = min(`y'_decile_pc)
	bys `y'_millile_pc: egen _max_dec  = max(`y'_decile_pc)
	
	* Flag milliles that straddle multiple centiles/deciles
	gen _cross_cent = (_min_cent != _max_cent)
	gen _cross_dec  = (_min_dec  != _max_dec)
	
	* Summarize at millile level (one row per millile)
	bys `y'_millile_pc: keep if _n == 1
	
	count if _cross_cent == 1
	local n_cross_cent = r(N)
	if `n_cross_cent' > 0 {
		di as error "WARNING: `n_cross_cent' milliles straddle multiple centiles!"
		list `y'_millile_pc _min_cent _max_cent if _cross_cent == 1, noobs
		di as error "  => Aggregation will NOT be exact for centiles."
	}
	else {
		di as result "PASS: Every millile maps to exactly 1 centile (perfect nesting)."
	}
	
	count if _cross_dec == 1
	local n_cross_dec = r(N)
	if `n_cross_dec' > 0 {
		di as error "WARNING: `n_cross_dec' milliles straddle multiple deciles!"
		list `y'_millile_pc _min_dec _max_dec if _cross_dec == 1, noobs
		di as error "  => Aggregation will NOT be exact for deciles."
	}
	else {
		di as result "PASS: Every millile maps to exactly 1 decile (perfect nesting)."
	}
restore

*==============================================================================
* TEST 2: Compare direct centile means vs aggregated millile means
*==============================================================================
di _n "{hline 70}"
di "TEST 2: Direct centile mean vs weighted millile-mean aggregation"
di "{hline 70}"

* Create a test share variable
gen share_test = -dirtax_total_pc / `y'_pc

* --- Method A: Direct centile mean from microdata ---
preserve
	groupfunction [aw=pondih], mean(share_test) by(`y'_centile_pc)
	rename share_test direct_mean
	tempfile direct_centile
	save `direct_centile'
restore

* --- Method B: Millile means → aggregate to centile ---
preserve
	* Step 1: Get weights and centile mapping per millile
	frame put `y'_millile_pc `y'_centile_pc pondih, into(fr_test_wt)
	frame fr_test_wt {
		groupfunction, sum(pondih) first(`y'_centile_pc) by(`y'_millile_pc)
		rename pondih _wt
	}
	
	* Step 2: Compute millile means
	groupfunction [aw=pondih], mean(share_test) by(`y'_millile_pc)
	
	* Step 3: Bring in weights + centile mapping
	frlink 1:1 `y'_millile_pc, frame(fr_test_wt)
	frget _wt `y'_centile_pc, from(fr_test_wt)
	drop fr_test_wt
	frame drop fr_test_wt
	
	* Step 4: Aggregate to centile level
	groupfunction [aw=_wt], mean(share_test) by(`y'_centile_pc)
	rename share_test agg_mean
	
	* Step 5: Merge and compare
	merge 1:1 `y'_centile_pc using `direct_centile', nogen
	
	gen diff = abs(direct_mean - agg_mean)
	sum diff
	
	if r(max) < 1e-10 {
		di as result "PASS: Centile means are identical (max diff = " %12.2e r(max) ")"
	}
	else {
		di as error "FAIL: Centile means differ! Max absolute difference = " %12.6f r(max)
		list `y'_centile_pc direct_mean agg_mean diff if diff > 1e-10, noobs
	}
restore

*==============================================================================
* TEST 3: Compare direct decile means vs aggregated millile means
*==============================================================================
di _n "{hline 70}"
di "TEST 3: Direct decile mean vs weighted millile-mean aggregation"
di "{hline 70}"

* --- Method A: Direct decile mean from microdata ---
preserve
	groupfunction [aw=pondih], mean(share_test) by(`y'_decile_pc)
	rename share_test direct_mean
	tempfile direct_decile
	save `direct_decile'
restore

* --- Method B: Millile means → aggregate to decile ---
preserve
	frame put `y'_millile_pc `y'_decile_pc pondih, into(fr_test_wt2)
	frame fr_test_wt2 {
		groupfunction, sum(pondih) first(`y'_decile_pc) by(`y'_millile_pc)
		rename pondih _wt
	}
	
	groupfunction [aw=pondih], mean(share_test) by(`y'_millile_pc)
	
	frlink 1:1 `y'_millile_pc, frame(fr_test_wt2)
	frget _wt `y'_decile_pc, from(fr_test_wt2)
	drop fr_test_wt2
	frame drop fr_test_wt2
	
	groupfunction [aw=_wt], mean(share_test) by(`y'_decile_pc)
	rename share_test agg_mean
	
	merge 1:1 `y'_decile_pc using `direct_decile', nogen
	
	gen diff = abs(direct_mean - agg_mean)
	sum diff
	
	if r(max) < 1e-10 {
		di as result "PASS: Decile means are identical (max diff = " %12.2e r(max) ")"
	}
	else {
		di as error "FAIL: Decile means differ! Max absolute difference = " %12.6f r(max)
		list `y'_decile_pc direct_mean agg_mean diff if diff > 1e-10, noobs
	}
restore

di _n "{hline 70}"
di "VALIDATION COMPLETE"
di "{hline 70}"
