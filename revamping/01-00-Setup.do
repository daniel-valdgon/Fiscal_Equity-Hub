/*============================================================================*\
 Revamp setup
 Centralizes user paths and global folders for revamp modules
\*============================================================================*/

* User-specific root
if "`c(username)'"=="wb419055" {
	global root "C:/Users/wb419055/OneDrive - WBG/GSG3/GSG Fiscal Equity - WB Group - Fiscal Equity Hub/Workspace/Data-Hub"
}
else if "`c(username)'"=="wb527706" {
	global root "C:/Users/wb527706/OneDrive - WBG/GSG Fiscal Equity - WB Group - Data Hub"
}
else {
	di as err "Unsupported user for revamp setup: `c(username)'"
	exit 198
}

* Script roots
global scripts "${root}/02-Scripts/wb419055"
global revamp_scripts "${scripts}/revamping"

* Data and product folders
global rawdata "${root}/01-Data/01-01-FRP"
global microdata "${root}/01-Data/01-02-FIA_Microdata"
global template "${root}/01-Data/01-03-FIA_Core Indicators"
global tempsim "${root}/01-Data/3_temp_sim"
global metadata "${root}/01-Data/00-Aux"
global dataout "${root}/03-Outputs/01-Cleaned-FIA-Indicators/01-Cleaned-FIA-Indicators"
global core_database "${root}/04-Products/00-FIA-Database/Core_Database.xlsx"

* Revamp artifacts
global revamp_output "${root}/03-Outputs/02-Quality-Checks/revamping"
cap mkdir "${tempsim}"
cap mkdir "${root}/03-Outputs/02-Quality-Checks"
cap mkdir "${revamp_output}"

di as txt "Revamp setup loaded"
di as txt "root      : ${root}"
di as txt "microdata : ${microdata}"
