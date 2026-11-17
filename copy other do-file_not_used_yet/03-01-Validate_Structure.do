/*============================================================================*\
 Structural validation gate
 Uses manifest_projects.dta from revamp inventory
\*============================================================================*/

use "${tempsim}/manifest_projects.dta", clear

count if structure_ok==0
if r(N)>0 {
	global validation_structure_pass 0
	di as err "Structural validation failed for " r(N) " project folder(s)."
	list country project level folder expected_file detected_file filecount naming_ok if structure_ok==0, noobs abbreviate(24)
}
else {
	global validation_structure_pass 1
	di as txt "Structural validation passed"
}
