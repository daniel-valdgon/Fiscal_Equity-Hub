/*============================================================================*\
 Revamp trunk scaffold - Fiscal Equity Hub
 Purpose: Define target orchestration with real and to-be-built modules
 Version: 0.1 (scaffold)
\*============================================================================*/

clear all
timer clear 1
timer on 1

* 1) Bootstrap paths and environment
if "`c(username)'"=="wb419055" {
	global root "C:/Users/wb419055/OneDrive - WBG/GSG3/GSG Fiscal Equity - WB Group - Fiscal Equity Hub/Workspace/Data-Hub"
}
else if "`c(username)'"=="wb527706" {
	global root "C:/Users/wb527706/OneDrive - WBG/GSG Fiscal Equity - WB Group - Data Hub"
}
else {
	di as err "Unsupported user for revamp trunk: `c(username)'"
	exit 198
}

global scripts "${root}/02-Scripts/wb419055"
global revamp_scripts "${scripts}/revamping"


include "${revamp_scripts}/00-01-init_softc_paths.do"

* 2) Canonical policy registry (adapted from current aux list)
include "${revamp_scripts}/01-01-Policy_Registry.do"

* 3) Inventory + manifest build (adapted from current inventory logic)
include "${revamp_scripts}/02-01-Inventory_Manifest.do"

* 4) Validation gates before indicators
*    Mapping to old 00-Trunk Section 2:
*    - A/B (fiscal consistency + income concept reconstruction): 03-03-Validate_Harmonization.do
*    - C/D (national + international poverty benchmark reconciliation): 03-04-Validate_Metadata.do
include "${revamp_scripts}/03-01-Validate_Structure.do"
include "${revamp_scripts}/03-02-Validate_Schema.do"
include "${revamp_scripts}/03-03-Validate_Harmonization.do"
include "${revamp_scripts}/03-04-Validate_Metadata.do"

* 5) Single-country calculations runner
*    This trunk can iterate over multiple countries, but the calculations file
*    itself runs one core dataset at a time.

if "$revamp_country_list"=="" {
	* Default list; set this global before running trunk to customize.
	global revamp_country_list "GNQ"
}

foreach c of global revamp_country_list {
	local c_up = upper("`c'")
	local c_lo = lower("`c'")
	local found = 0

	local cty_path "${microdata}/`c_lo'"
	capture confirm dir "`cty_path'"
	if _rc {
		di as err "Country folder not found: `cty_path'. Skipping `c_up'."
		continue
	}
	local proj_dirs : dir "`cty_path'" dirs "*"

	foreach p of local proj_dirs {
		local hfmd_path "`cty_path'/`p'/HFMD"
		local files : dir "`hfmd_path'" files "*.dta"
		foreach f of local files {
			global core_dataset_path "`hfmd_path'/`f'"
			global core_dataset_name "`f'"
			global core_country "`c_up'"
			local found = 1
			continue, break
		}
		if `found' continue, break
	}

	if !`found' {
		di as err "No HFMD dataset found for country `c_up'. Skipping."
		continue
	}

	di as txt "Running single-country calculations for `c_up' using: $core_dataset_path"
	include "${revamp_scripts}/1. Calculations_v2.do"
}

* 6) Compile/append country outputs into one dataset
include "${revamp_scripts}/07-01-Compile_Country_Outputs.do"

* 7) Regression gate and release checks
include "${revamp_scripts}/06-01-Regression_Gate.do"

timer off 1
timer list 1

di as txt "Revamp trunk scaffold completed"
exit
