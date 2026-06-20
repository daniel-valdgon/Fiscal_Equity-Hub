/*============================================================================*\
 Revamp policy registry
 Adapted from 0-01-aux_policy_list.do, exported as globals for cross-file use
\*============================================================================*/

di as txt "Loading revamp policy registry"


import excel "${metadata}/${FEH_dictionary}.xlsx", sheet("instrument") firstrow clear
keep instrument INSTRUMENT_ID

* Dynamic classification of instruments by INSTRUMENT_ID code (positions 5-6)
* Categories: 04=Directaxes, 05=Indtaxes, 11=DirectTransfers, 12=education_inKind, 13=health_inKind, 16=Subsidies
gen category = substr(INSTRUMENT_ID, 5, 2)

* Exclude special indirect tax variants from direct tax classification
gen is_excluded_04 = (category=="04") & (inlist(INSTRUMENT_ID, "INS_04_2_0", "INS_04_2_1", "INS_04_2_2"))

* INS_04_2_* are SSC components and should populate Contributions
gen is_contrib_04_2 = (category=="04") & (inlist(INSTRUMENT_ID, "INS_04_2_0", "INS_04_2_1", "INS_04_2_2"))

* Exclude pension total variants from direct transfers classification
gen is_excluded_11 = (category=="11") & (inlist(INSTRUMENT_ID, "INS_11_2_0", "INS_11_2_1"))

* Initialize globals
global Directaxes ""
global Contributions ""
global DirectTransfers ""
global Subsidies ""
global Indtaxes ""
global education_inKind ""
global health_inKind ""
global InKindTransfers ""

* Build globals by category
forvalues i = 1/`=_N' {
	local cat = category[`i']
	local instr = instrument[`i']
	local id = INSTRUMENT_ID[`i']
	local excl = is_excluded_04[`i']
	local isssc = is_contrib_04_2[`i']
	local excl11 = is_excluded_11[`i']

	if `isssc' {
		global Contributions "${Contributions} `instr'"
	}
	
	if `excl' continue
	if `excl11' continue
	
	if "`cat'"=="04" {
		global Directaxes "${Directaxes} `instr'"
	}
	else if "`cat'"=="05" {
		global Indtaxes "${Indtaxes} `instr'"
	}
	else if "`cat'"=="11" {
		global DirectTransfers "${DirectTransfers} `instr'"
	}
	else if "`cat'"=="12" {
		global education_inKind "${education_inKind} `instr'"
	}
	else if "`cat'"=="13" {
		global health_inKind "${health_inKind} `instr'"
	}
	else if "`cat'"=="16" {
		global Subsidies "${Subsidies} `instr'"
	}
}



* Build InKindTransfers composite
global InKindTransfers "${education_inKind} ${health_inKind}"

di as txt "Directaxes:        ${Directaxes}"
di as txt "Contributions:     ${Contributions}"
di as txt "DirectTransfers:   ${DirectTransfers}"
di as txt "Subsidies:         ${Subsidies}"
di as txt "Indtaxes:          ${Indtaxes}"
di as txt "education_inKind:  ${education_inKind}"
di as txt "health_inKind:     ${health_inKind}"
di as txt "InKindTransfers:   ${InKindTransfers}"


* Convenience sets used in validation scripts
global var_dtr "${Directaxes} ${Contributions} ${DirectTransfers} ${Subsidies} ${Indtaxes} ${InKindTransfers}"

* Income concepts expected in active pipeline
global IncomeConcepts "ymp yn yd yc yf"


