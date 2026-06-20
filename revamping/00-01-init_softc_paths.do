/*============================================================================*\
 Revamp setup
 Centralizes user paths and global folders for revamp modules
\*============================================================================*/

* Root path must be set once in trunk before including this setup file.
if "$root"=="" {
	di as err "Missing required global root in setup. Define root in 00-Trunk_Revamp.do before include."
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
global FEH_dictionary "correlative_3" // excel file with canonical policy registry and metadata

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
