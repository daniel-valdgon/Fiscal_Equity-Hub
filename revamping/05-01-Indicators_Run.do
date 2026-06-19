/*============================================================================*\
 Indicator layer (bridge)
 Reuse current modular indicator runner during revamp transition
\*============================================================================*/

if ${validation_structure_pass}==0 {
	di as err "Skipping indicators because structural validation failed"
	exit 9
}

capture confirm file "${revamp_scripts}/3-00-Run_All_Indicators.do"
if _rc {
	di as err "Missing indicator runner: ${revamp_scripts}/3-00-Run_All_Indicators.do"
	exit 601
}

include "${revamp_scripts}/3-00-Run_All_Indicators.do"
