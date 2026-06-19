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
	global revamp_scripts "C:/Users/wb419055/OneDrive - WBG/GSG3/GSG Fiscal Equity - WB Group - Fiscal Equity Hub/Workspace/Data-Hub/02-Scripts/wb419055/revamping"
}
else if "`c(username)'"=="wb527706" {
	global revamp_scripts "C:/Users/wb527706/OneDrive - WBG/GSG Fiscal Equity - WB Group - Data Hub/02-Scripts/wb419055/revamping"
}
else {
	di as err "Unsupported user for revamp trunk: `c(username)'"
	exit 198
}

include "${revamp_scripts}/01-00-Setup.do"

* 2) Canonical policy registry (adapted from current aux list)
include "${revamp_scripts}/01-01-Policy_Registry.do"

* 3) Inventory + manifest build (adapted from current inventory logic)
include "${revamp_scripts}/02-01-Inventory_Manifest.do"

* 4) Validation gates before indicators
include "${revamp_scripts}/03-01-Validate_Structure.do"
include "${revamp_scripts}/03-02-Validate_Schema.do"
include "${revamp_scripts}/03-03-Validate_Harmonization.do"
include "${revamp_scripts}/03-04-Validate_Metadata.do"

* 5) Staging layer (reuse existing script now, replace later)
include "${revamp_scripts}/04-01-Staging.do"

* 6) Indicator engine (reuse existing modular runner now)
include "${revamp_scripts}/05-01-Indicators_Run.do"

* 7) Regression gate and release checks
include "${revamp_scripts}/06-01-Regression_Gate.do"

timer off 1
timer list 1

di as txt "Revamp trunk scaffold completed"
exit
