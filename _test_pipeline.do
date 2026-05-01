/*--------------------------------------------------------------------------------
* TEST: Run modular indicator pipeline on first available dataset
* This file tests that 3-00-Setup + all 3-xx modules execute without error.
* Run via: "C:\Program Files\Stata18\StataMP-64.exe" /e do _test_pipeline.do
*--------------------------------------------------------------------------------*/

clear all
set more off
timer clear 1
timer on 1

* Set root
global root "C:\Users\wb419055\OneDrive - WBG\GSG3\GSG Fiscal Equity - WB Group - Fiscal Equity Hub\Workspace\Data Hub"

* Install ado path
adopath ++ "${root}/02-Scripts/wb419055/_ado"

* Load policy list (sets globals Directaxes, Contributions, etc.)
* Since 0-01-aux sets locals not globals, we set them here directly
global Directaxes     "PIT BIT PropertyTax FinancialTax"
global Contributions  "sscontribs_total"
global DirectTransfers "am_prog_1 am_prog_2 am_prog_3 am_prog_other"
global Subsidies      "subsidy_elec_direct subsidy_elec_indirect subsidy_fuel_direct subsidy_fuel_indirect subsidy_water_direct subsidy_water_indirect subsidy_agric"
global Indtaxes       "CD_direct excise_taxes VAT_direct VAT_indirect"
global InKindTransfers "education_inKind am_health"

di as text "=== Loading 3-00-Setup.do ==="
include "${root}/02-Scripts/wb419055/3-00-Setup.do"

di as text "=== Setup complete. n_datasets = ${n_datasets} ==="
di as text "=== Globals check: pline = [${pline}] ==="
di as text "=== Globals check: income_pc = [${income_pc}] ==="
di as text "=== Globals check: concs_pc = [${concs_pc}] ==="
di as text "=== Globals check: tax = [${tax}] ==="

* Only test first dataset
if ${n_datasets} == 0 {
	di as error "No datasets detected. Aborting test."
	exit 1
}

* Find the first dataset that has ymp_pc (some datasets like ECU may not)
local test_idx 0
forvalues i = 1/$n_datasets {
	qui cap use `"${path_`i'}"', clear
	cap confirm variable ymp_pc
	if _rc == 0 {
		local test_idx = `i'
		di as text "Using dataset `i': ${path_`i'}"
		continue, break
	}
	else {
		di as text "Skipping dataset `i' (no ymp_pc): ${path_`i'}"
	}
}

if `test_idx' == 0 {
	di as error "No dataset with ymp_pc found. Aborting test."
	exit 1
}

* Process selected dataset
global sheetname   "${cty_`test_idx'}"
global datasetname "${fname_`test_idx'}"
di as text "=== Processing: ${path_`test_idx'} — Sheet: ${sheetname} ==="

use `"${path_`test_idx'}"', clear

cap drop *deciles_pc *centile_pc

foreach y in ymp yd {
	quantiles `y'_pc [w=pondih], gen(`y'_deciles_pc)  nq(10)
	quantiles `y'_pc [w=pondih], gen(`y'_centile_pc) nq(100)
}

tempfile output
save `output'

di as text "=== Data loaded: `=_N' obs, `=c(k)' vars ==="

* Test each module
di as text _n "=== 3-02: Netcash Incidence ==="
cap noisily include "${root}/02-Scripts/wb419055/3-02-Netcash_Incidence.do"
if _rc di as error "3-02 FAILED with rc = `=_rc'"
else   di as text  "3-02 OK"

di as text _n "=== 3-03: Gini & Theil ==="
cap noisily include "${root}/02-Scripts/wb419055/3-03-Gini_Theil.do"
if _rc di as error "3-03 FAILED with rc = `=_rc'"
else   di as text  "3-03 OK"

di as text _n "=== 3-04: Poverty FGT ==="
cap noisily include "${root}/02-Scripts/wb419055/3-04-Poverty_FGT.do"
if _rc di as error "3-04 FAILED with rc = `=_rc'"
else   di as text  "3-04 OK"

di as text _n "=== 3-05: Marginal Contributions ==="
cap noisily include "${root}/02-Scripts/wb419055/3-05-Marginal_Contributions.do"
if _rc di as error "3-05 FAILED with rc = `=_rc'"
else   di as text  "3-05 OK"

di as text _n "=== 3-06: Coverage ==="
cap noisily include "${root}/02-Scripts/wb419055/3-06-Coverage.do"
if _rc di as error "3-06 FAILED with rc = `=_rc'"
else   di as text  "3-06 OK"

di as text _n "=== 3-07: Mean Income ==="
cap noisily include "${root}/02-Scripts/wb419055/3-07-Mean_Income.do"
if _rc di as error "3-07 FAILED with rc = `=_rc'"
else   di as text  "3-07 OK"

di as text _n "=== 3-08: Concentration & Kakwani ==="
cap noisily include "${root}/02-Scripts/wb419055/3-08-Concentration_Kakwani.do"
if _rc di as error "3-08 FAILED with rc = `=_rc'"
else   di as text  "3-08 OK"

di as text _n "=== 3-11: Redistributive Impact ==="
cap noisily include "${root}/02-Scripts/wb419055/3-11-Redistributive_Impact.do"
if _rc di as error "3-11 FAILED with rc = `=_rc'"
else   di as text  "3-11 OK"

di as text _n "=== 3-12: Conditional Incidence ==="
cap noisily include "${root}/02-Scripts/wb419055/3-12-Conditional_Incidence.do"
if _rc di as error "3-12 FAILED with rc = `=_rc'"
else   di as text  "3-12 OK"

di as text _n "=== 3-13: Concentration Shares, CC & Kakwani ==="
cap noisily include "${root}/02-Scripts/wb419055/3-13-Concentration_Shares_CC_Kakwani.do"
if _rc di as error "3-13 FAILED with rc = `=_rc'"
else   di as text  "3-13 OK"

timer off 1
timer list 1

di as text _n "=== TEST COMPLETE ==="
