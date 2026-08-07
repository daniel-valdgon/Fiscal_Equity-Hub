/*--------------------------------------------------------------------------------
* TEST: Run the fia package on the same data as _test_pipeline.do
* and compare results with the do-file pipeline output.
*
* This script:
*   1. Loads the same dataset as _test_pipeline
*   2. Runs each fia subcommand step-by-step
*   3. Saves fia results to a tempfile
*   4. Then runs the do-file pipeline on the same data
*   5. Compares key indicators (Gini, FGT0, coverage, etc.)
*
* Run via: "C:\Program Files\Stata18\StataMP-64.exe" /e do _test_fia_package.do
*--------------------------------------------------------------------------------*/

clear all
set more off
timer clear 1
timer on 1

* ---------------------------------------------------------------
* 0. Paths and adopath
* ---------------------------------------------------------------
global root "C:\Users\wb419055\OneDrive - WBG\GSG3\GSG Fiscal Equity - WB Group - Fiscal Equity Hub\Workspace\Data Hub"

adopath ++ "${root}/02-Scripts/wb419055/_ado"
adopath ++ "${root}/02-Scripts/wb419055/_fia_package"

* ---------------------------------------------------------------
* 1. Load policy list globals (same as _test_pipeline.do)
* ---------------------------------------------------------------
global Directaxes      "PIT BIT PropertyTax FinancialTax"
global Contributions   "sscontribs_total"
global DirectTransfers "am_prog_1 am_prog_2 am_prog_3 am_prog_other"
global Subsidies_raw   "subsidy_elec_direct subsidy_elec_indirect subsidy_fuel_direct subsidy_fuel_indirect subsidy_water_direct subsidy_water_indirect subsidy_agric"
global Indtaxes        "CD_direct excise_taxes VAT_direct VAT_indirect"
global InKindTransfers "education_inKind am_health"

* ---------------------------------------------------------------
* 2. Detect microdata (same logic as 3-00-Setup.do)
* ---------------------------------------------------------------
global microdata "${root}/01-Data/01-02-FIA_Microdata"
global metadata  "${root}/01-Data/00-Aux"

global n_datasets 0
local dirs1 : dir `"${microdata}"' dirs "*"

foreach subf of local dirs1 {
	local cty : di strupper("`subf'")
	local cty_path `"${microdata}/`subf'"'
	local cty_count 0
	local dirs2 : dir `"`cty_path'"' dirs "*"

	foreach subf2 of local dirs2 {
		local cty_proj_path `"`cty_path'/`subf2'"'

		local files2 : dir `"`cty_proj_path'"' files "*.dta"
		foreach f of local files2 {
			local f_upper : di strupper("`f'")
			local cty_count = `cty_count' + 1
			global n_datasets = ${n_datasets} + 1
			global path_${n_datasets} `"`cty_proj_path'/`f_upper'"'
			global cty_${n_datasets}  "`cty'_`cty_count'"
		}

		local dirs3 : dir `"`cty_proj_path'"' dirs "*"
		foreach subf3 of local dirs3 {
			local cty_final_path `"`cty_proj_path'/`subf3'"'
			local files3 : dir `"`cty_final_path'"' files "*.dta"
			foreach f of local files3 {
				local f_upper : di strupper("`f'")
				local cty_count = `cty_count' + 1
				global n_datasets = ${n_datasets} + 1
				global path_${n_datasets} `"`cty_final_path'/`f_upper'"'
				global cty_${n_datasets}  "`cty'_`cty_count'"
				global fname_${n_datasets} "`f_upper'"
			}
		}
	}
}

di as text "Detected ${n_datasets} datasets"

* Find first dataset with ymp_pc
local test_idx 0
forvalues i = 1/$n_datasets {
	qui cap use `"${path_`i'}"', clear
	cap confirm variable ymp_pc
	if _rc == 0 {
		local test_idx = `i'
		di as text "Using dataset `i': ${path_`i'}"
		continue, break
	}
}

if `test_idx' == 0 {
	di as error "No dataset with ymp_pc found. Aborting."
	exit 1
}

global sheetname   "${cty_`test_idx'}"
global datasetname "${fname_`test_idx'}"

use `"${path_`test_idx'}"', clear
di as text "Loaded: `=_N' obs, `=c(k)' vars"

* ---------------------------------------------------------------
* PART A: Run the fia package
* ---------------------------------------------------------------
di as text _n "{hline 60}"
di as text ">>> PART A: Running fia package subcommands"
di as text "{hline 60}"

* A.1 Setup — validate and set fia_ globals
di as text _n ">>> A.1: fia setup"
fia setup [aw=pondih]

di as text "  fia_tax      = [${fia_tax}]"
di as text "  fia_indtax   = [${fia_indtax}]"
di as text "  fia_transfer = [${fia_transfer}]"
di as text "  fia_inkind   = [${fia_inkind}]"
di as text "  fia_subsidy  = [${fia_subsidy}]"
di as text "  fia_income   = [${fia_income}]"
di as text "  fia_pline    = [${fia_pline}]"

* A.2 Create deciles
di as text _n ">>> A.2: Creating deciles"
cap drop *deciles_pc *centile_pc
foreach y in ymp yd {
	cap confirm variable `y'_pc
	if _rc == 0 {
		quantiles `y'_pc [w=pondih], gen(`y'_deciles_pc)  nq(10)
		quantiles `y'_pc [w=pondih], gen(`y'_centile_pc) nq(100)
	}
}

tempfile fia_data
save `fia_data'

* A.3 Inequality
di as text _n ">>> A.3: fia inequality"
cap noisily fia inequality [aw=pondih]
local rc_ineq = _rc
if `rc_ineq' di as error "  fia inequality FAILED rc=`rc_ineq'"
else         di as text  "  fia inequality OK"

* A.4 Poverty
di as text _n ">>> A.4: fia poverty"
u `fia_data', clear
cap noisily fia poverty [aw=pondih]
local rc_pov = _rc
if `rc_pov' di as error "  fia poverty FAILED rc=`rc_pov'"
else        di as text  "  fia poverty OK"

* A.5 Incidence
di as text _n ">>> A.5: fia incidence"
u `fia_data', clear
cap noisily fia incidence [aw=pondih]
local rc_inc = _rc
if `rc_inc' di as error "  fia incidence FAILED rc=`rc_inc'"
else        di as text  "  fia incidence OK"

* A.6 Marginal contributions
di as text _n ">>> A.6: fia marginal"
u `fia_data', clear
cap noisily fia marginal [aw=pondih]
local rc_marg = _rc
if `rc_marg' di as error "  fia marginal FAILED rc=`rc_marg'"
else         di as text  "  fia marginal OK"

* A.7 Coverage + targeting
di as text _n ">>> A.7: fia coverage"
u `fia_data', clear
cap noisily fia coverage [aw=pondih]
local rc_cov = _rc
if `rc_cov' di as error "  fia coverage FAILED rc=`rc_cov'"
else        di as text  "  fia coverage OK"

* A.8 Shares
di as text _n ">>> A.8: fia shares"
u `fia_data', clear
cap noisily fia shares [aw=pondih]
local rc_sh = _rc
if `rc_sh' di as error "  fia shares FAILED rc=`rc_sh'"
else       di as text  "  fia shares OK"

* A.9 Concentration, CC, Kakwani
di as text _n ">>> A.9: fia concentration"
u `fia_data', clear
cap noisily fia concentration [aw=pondih]
local rc_conc = _rc
if `rc_conc' di as error "  fia concentration FAILED rc=`rc_conc'"
else         di as text  "  fia concentration OK"

* A.9b Mean income by decile
di as text _n ">>> A.9b: fia meanincome"
u `fia_data', clear
cap noisily fia meanincome [aw=pondih]
local rc_mi = _rc
if `rc_mi' di as error "  fia meanincome FAILED rc=`rc_mi'"
else       di as text  "  fia meanincome OK"

* A.9c Benefits by decile
di as text _n ">>> A.9c: fia benefits"
u `fia_data', clear
cap noisily fia benefits [aw=pondih]
local rc_ben = _rc
if `rc_ben' di as error "  fia benefits FAILED rc=`rc_ben'"
else        di as text  "  fia benefits OK"

* A.10 Redistribution (needs $fia_result_inequality and $fia_result_poverty)
di as text _n ">>> A.10: fia redistribution"
u `fia_data', clear
cap noisily fia redistribution [aw=pondih]
local rc_red = _rc
if `rc_red' di as error "  fia redistribution FAILED rc=`rc_red'"
else        di as text  "  fia redistribution OK"

* A.11 Effectiveness (needs $fia_result_marginal, inequality, poverty)
di as text _n ">>> A.11: fia effectiveness"
u `fia_data', clear
cap noisily fia effectiveness [aw=pondih]
local rc_eff = _rc
if `rc_eff' di as error "  fia effectiveness FAILED rc=`rc_eff'"
else        di as text  "  fia effectiveness OK"

* ---------------------------------------------------------------
* Save fia results by appending all globals
* ---------------------------------------------------------------
di as text _n ">>> Appending all fia results"

local first 1
foreach mod in inequality poverty incidence marginal concentration ///
               coverage redistribution shares effectiveness ///
               meanincome benefits {
	if "${fia_result_`mod'}" != "" {
		cap confirm file "${fia_result_`mod'}"
		if _rc {
			di as text "  WARNING: fia_result_`mod' file not found"
			continue
		}
		if `first' {
			u "${fia_result_`mod'}", clear
			gen _source_mod = "`mod'"
			local first 0
		}
		else {
			preserve
				u "${fia_result_`mod'}", clear
				gen _source_mod = "`mod'"
				tempfile _append_tmp
				save `_append_tmp'
			restore
			append using `_append_tmp'
		}
	}
	else {
		di as text "  WARNING: fia_result_`mod' is empty"
	}
}

tempfile fia_all
cap save `fia_all'

local fia_N = _N
di as text "  FIA package produced `fia_N' indicator rows"

* ---------------------------------------------------------------
* PART B: Run the do-file pipeline on same data (for comparison)
* ---------------------------------------------------------------
di as text _n "{hline 60}"
di as text ">>> PART B: Running do-file pipeline"
di as text "{hline 60}"

* Re-set pipeline globals (3-00 already set them but we need to restore)
global Subsidies "$Subsidies_raw"
include "${root}/02-Scripts/wb419055/3-00-Setup.do"

* Find the same dataset again
local test_idx2 0
forvalues i = 1/$n_datasets {
	if "${cty_`i'}" == "${sheetname}" {
		local test_idx2 = `i'
		continue, break
	}
}

use `"${path_`test_idx2'}"', clear

cap drop *deciles_pc *centile_pc
foreach y in ymp yd {
	quantiles `y'_pc [w=pondih], gen(`y'_deciles_pc)  nq(10)
	quantiles `y'_pc [w=pondih], gen(`y'_centile_pc) nq(100)
}

tempfile output
save `output'

* Run each module
cap restore
cap noisily include "${root}/02-Scripts/wb419055/3-02-Netcash_Incidence.do"
cap restore
cap noisily include "${root}/02-Scripts/wb419055/3-03-Gini_Theil.do"
cap restore
cap noisily include "${root}/02-Scripts/wb419055/3-04-Poverty_FGT.do"
cap restore
cap noisily include "${root}/02-Scripts/wb419055/3-05-Marginal_Contributions.do"
cap restore
cap noisily include "${root}/02-Scripts/wb419055/3-06-Coverage.do"
cap restore
cap noisily include "${root}/02-Scripts/wb419055/3-07-Mean_Income.do"
cap restore
cap noisily include "${root}/02-Scripts/wb419055/3-08-Concentration_Kakwani.do"
cap restore
cap noisily include "${root}/02-Scripts/wb419055/3-11-Redistributive_Impact.do"
cap restore
cap noisily include "${root}/02-Scripts/wb419055/3-12-Conditional_Incidence.do"
cap restore
cap noisily include "${root}/02-Scripts/wb419055/3-13-Concentration_Shares_CC_Kakwani.do"
cap restore
cap noisily include "${root}/02-Scripts/wb419055/3-14-Targeting_Errors.do"
cap restore
cap noisily include "${root}/02-Scripts/wb419055/3-15-CEQ_Effectiveness.do"
cap restore
cap noisily include "${root}/02-Scripts/wb419055/3-16-Consumption_Shares.do"

* Append all pipeline tempfiles
u `ind_3_02', clear
cap append using `ind_3_03'
cap append using `ind_3_04'
cap append using `ind_3_05'
cap append using `ind_3_06'
cap append using `ind_3_07'
cap append using `ind_3_08'
cap append using `ind_3_11'
cap append using `ind_3_12'
cap append using `ind_3_13'
cap append using `ind_3_14'
cap append using `ind_3_15'
cap append using `ind_3_16'

tempfile pipeline_all
save `pipeline_all'

local pipe_N = _N
di as text "  Pipeline produced `pipe_N' indicator rows"

* ---------------------------------------------------------------
* PART C: Compare key indicators
* ---------------------------------------------------------------
di as text _n "{hline 60}"
di as text ">>> PART C: Comparing FIA package vs Do-file pipeline"
di as text "{hline 60}"

local n_compare 0
local n_match   0
local n_differ  0

* --- C.1 Compare Gini(ymp_pc) ---
di as text _n "--- Gini(ymp_pc) ---"

u `pipeline_all', clear
keep if indicator == "gini" & variable == "ymp_pc"
if _N > 0 {
	local pipe_gini_ymp = value[1]
	di as text "  Pipeline: `pipe_gini_ymp'"
}
else {
	local pipe_gini_ymp = .
	di as text "  Pipeline: not found"
}

u `fia_all', clear
keep if indicator == "gini" & variable == "ymp_pc"
if _N > 0 {
	local fia_gini_ymp = value[1]
	di as text "  FIA:      `fia_gini_ymp'"
}
else {
	local fia_gini_ymp = .
	di as text "  FIA:      not found"
}

local n_compare = `n_compare' + 1
if abs(`pipe_gini_ymp' - `fia_gini_ymp') < 0.0001 {
	di as text "  MATCH (diff = " %9.6f (`pipe_gini_ymp' - `fia_gini_ymp') ")"
	local n_match = `n_match' + 1
}
else {
	di as error "  DIFFER (pipe=`pipe_gini_ymp' fia=`fia_gini_ymp')"
	local n_differ = `n_differ' + 1
}

* --- C.2 Compare Theil(ymp_pc) ---
di as text _n "--- Theil(ymp_pc) ---"

u `pipeline_all', clear
keep if indicator == "theil" & variable == "ymp_pc"
if _N > 0 {
	local pipe_theil = value[1]
	di as text "  Pipeline: `pipe_theil'"
}
else local pipe_theil = .

u `fia_all', clear
keep if indicator == "theil" & variable == "ymp_pc"
if _N > 0 {
	local fia_theil = value[1]
	di as text "  FIA:      `fia_theil'"
}
else local fia_theil = .

local n_compare = `n_compare' + 1
if abs(`pipe_theil' - `fia_theil') < 0.0001 {
	di as text "  MATCH (diff = " %9.6f (`pipe_theil' - `fia_theil') ")"
	local n_match = `n_match' + 1
}
else {
	di as error "  DIFFER"
	local n_differ = `n_differ' + 1
}

* --- C.3 Compare FGT0(ymp_pc) ---
di as text _n "--- FGT0(ymp_pc) ---"

u `pipeline_all', clear
keep if indicator == "fgt0" & variable == "ymp_pc"
if _N > 0 {
	local pipe_fgt0 = value[1]
	di as text "  Pipeline: `pipe_fgt0'"
}
else local pipe_fgt0 = .

u `fia_all', clear
keep if indicator == "fgt0" & variable == "ymp_pc"
if _N > 0 {
	local fia_fgt0 = value[1]
	di as text "  FIA:      `fia_fgt0'"
}
else local fia_fgt0 = .

local n_compare = `n_compare' + 1
if abs(`pipe_fgt0' - `fia_fgt0') < 0.0001 {
	di as text "  MATCH (diff = " %9.6f (`pipe_fgt0' - `fia_fgt0') ")"
	local n_match = `n_match' + 1
}
else {
	di as error "  DIFFER"
	local n_differ = `n_differ' + 1
}

* --- C.4 Compare Gini(yd_pc) ---
di as text _n "--- Gini(yd_pc) ---"

u `pipeline_all', clear
keep if indicator == "gini" & variable == "yd_pc"
if _N > 0 {
	local pipe_gini_yd = value[1]
	di as text "  Pipeline: `pipe_gini_yd'"
}
else local pipe_gini_yd = .

u `fia_all', clear
keep if indicator == "gini" & variable == "yd_pc"
if _N > 0 {
	local fia_gini_yd = value[1]
	di as text "  FIA:      `fia_gini_yd'"
}
else local fia_gini_yd = .

local n_compare = `n_compare' + 1
if abs(`pipe_gini_yd' - `fia_gini_yd') < 0.0001 {
	di as text "  MATCH (diff = " %9.6f (`pipe_gini_yd' - `fia_gini_yd') ")"
	local n_match = `n_match' + 1
}
else {
	di as error "  DIFFER"
	local n_differ = `n_differ' + 1
}

* --- C.5 Compare redistributive_impact ---
di as text _n "--- Redistributive Impact (gini ymp→yd) ---"

u `pipeline_all', clear
keep if indicator == "redistributive_impact" & variable == "yd_pc"
if _N > 0 {
	local pipe_ri = value[1]
	di as text "  Pipeline: `pipe_ri'"
}
else local pipe_ri = .

u `fia_all', clear
keep if indicator == "redistributive_impact" & variable == "yd_pc"
if _N > 0 {
	local fia_ri = value[1]
	di as text "  FIA:      `fia_ri'"
}
else local fia_ri = .

local n_compare = `n_compare' + 1
if abs(`pipe_ri' - `fia_ri') < 0.0001 {
	di as text "  MATCH (diff = " %9.6f (`pipe_ri' - `fia_ri') ")"
	local n_match = `n_match' + 1
}
else {
	di as error "  DIFFER"
	local n_differ = `n_differ' + 1
}

* --- C.6 Compare coverage (first instrument, decile 1) ---
di as text _n "--- Coverage (first instrument, decile 1) ---"

u `pipeline_all', clear
keep if indicator == "coverage" & deciles_pc == 1
if _N > 0 {
	local pipe_cov_var = variable[1]
	local pipe_cov = value[1]
	di as text "  Pipeline: `pipe_cov' (var=`pipe_cov_var')"
}
else local pipe_cov = .

u `fia_all', clear
keep if indicator == "coverage" & deciles_pc == 1 & variable == "`pipe_cov_var'"
if _N > 0 {
	local fia_cov = value[1]
	di as text "  FIA:      `fia_cov'"
}
else local fia_cov = .

local n_compare = `n_compare' + 1
if abs(`pipe_cov' - `fia_cov') < 0.0001 {
	di as text "  MATCH (diff = " %9.6f (`pipe_cov' - `fia_cov') ")"
	local n_match = `n_match' + 1
}
else {
	di as error "  DIFFER"
	local n_differ = `n_differ' + 1
}

* --- C.7 Compare mc_gini (first instrument, ymp_pc) ---
di as text _n "--- MC Gini (first instrument, ymp) ---"

u `pipeline_all', clear
keep if indicator == "mc_gini" & income == "ymp_pc"
if _N > 0 {
	sort variable
	local pipe_mc_var = variable[1]
	local pipe_mc = value[1]
	di as text "  Pipeline: `pipe_mc' (var=`pipe_mc_var')"
}
else local pipe_mc = .

u `fia_all', clear
keep if indicator == "mc_gini" & income == "ymp_pc" & variable == "`pipe_mc_var'"
if _N > 0 {
	local fia_mc = value[1]
	di as text "  FIA:      `fia_mc'"
}
else local fia_mc = .

local n_compare = `n_compare' + 1
if abs(`pipe_mc' - `fia_mc') < 0.0001 {
	di as text "  MATCH (diff = " %9.6f (`pipe_mc' - `fia_mc') ")"
	local n_match = `n_match' + 1
}
else {
	di as error "  DIFFER"
	local n_differ = `n_differ' + 1
}

* --- C.8 Compare concentration_share (first instrument, decile 1) ---
di as text _n "--- Concentration Share (first instrument, decile 1) ---"

u `pipeline_all', clear
keep if indicator == "concentration_share" & deciles_pc == 1
if _N > 0 {
	sort variable
	local pipe_cs_var = variable[1]
	local pipe_cs = value[1]
	di as text "  Pipeline: `pipe_cs' (var=`pipe_cs_var')"
}
else local pipe_cs = .

u `fia_all', clear
keep if indicator == "concentration_share" & deciles_pc == 1 & variable == "`pipe_cs_var'"
if _N > 0 {
	local fia_cs = value[1]
	di as text "  FIA:      `fia_cs'"
}
else local fia_cs = .

local n_compare = `n_compare' + 1
if abs(`pipe_cs' - `fia_cs') < 0.0001 {
	di as text "  MATCH (diff = " %9.6f (`pipe_cs' - `fia_cs') ")"
	local n_match = `n_match' + 1
}
else {
	di as error "  DIFFER"
	local n_differ = `n_differ' + 1
}

* --- C.9 Row count comparison ---
di as text _n "--- Row Counts ---"
di as text "  FIA package:  `fia_N' rows"
di as text "  Pipeline:     `pipe_N' rows"

* ---------------------------------------------------------------
* Summary
* ---------------------------------------------------------------
di as text _n "{hline 60}"
di as text ">>> COMPARISON SUMMARY"
di as text "{hline 60}"
di as text "  Indicators compared: `n_compare'"
di as text "  Matches:             `n_match'"
di as text "  Differences:         `n_differ'"

if `n_differ' == 0 {
	di as text _n "  ALL COMPARISONS PASSED"
}
else {
	di as error _n "  `n_differ' COMPARISONS FAILED — investigate"
}

di as text _n "{hline 60}"

* ---------------------------------------------------------------
* Summary table of each subcommand status
* ---------------------------------------------------------------
di as text _n ">>> SUBCOMMAND STATUS"
di as text "{hline 40}"
di as text "  inequality:     " cond(`rc_ineq' == 0, "OK", "FAILED rc=`rc_ineq'")
di as text "  poverty:        " cond(`rc_pov'  == 0, "OK", "FAILED rc=`rc_pov'")
di as text "  incidence:      " cond(`rc_inc'  == 0, "OK", "FAILED rc=`rc_inc'")
di as text "  marginal:       " cond(`rc_marg' == 0, "OK", "FAILED rc=`rc_marg'")
di as text "  coverage:       " cond(`rc_cov'  == 0, "OK", "FAILED rc=`rc_cov'")
di as text "  shares:         " cond(`rc_sh'   == 0, "OK", "FAILED rc=`rc_sh'")
di as text "  concentration:  " cond(`rc_conc' == 0, "OK", "FAILED rc=`rc_conc'")
di as text "  redistribution: " cond(`rc_red'  == 0, "OK", "FAILED rc=`rc_red'")
di as text "  effectiveness:  " cond(`rc_eff'  == 0, "OK", "FAILED rc=`rc_eff'")
di as text "  meanincome:     " cond(`rc_mi'   == 0, "OK", "FAILED rc=`rc_mi'")
di as text "  benefits:       " cond(`rc_ben'  == 0, "OK", "FAILED rc=`rc_ben'")
di as text "{hline 40}"

timer off 1
timer list 1

di as text _n "=== FIA PACKAGE TEST COMPLETE ==="
