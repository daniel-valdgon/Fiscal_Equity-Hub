/*============================================================================*\
 Revamp inventory + manifest
 Adapted from 1-01-Inventory.do and 3-00-Setup.do discovery logic
 Output: ${tempsim}/manifest_projects.dta
\*============================================================================*/

tempname ph
tempfile manifest

postfile `ph' str12 country str120 project str244 folder str120 expected_file str120 detected_file int filecount byte naming_ok byte level using `manifest', replace

local dirs1 : dir "${microdata}" dirs "*"

foreach cty_dir of local dirs1 {
	if substr("`cty_dir'",1,1)=="_" continue

	local cty : di strupper("`cty_dir'")
	local cty_path "${microdata}/`cty_dir'"
	local dirs2 : dir "`cty_path'" dirs "*"

	foreach proj2 of local dirs2 {
		local path2 "`cty_path'/`proj2'"
		local files2 : dir "`path2'" files "*.dta"
		local n2 : word count `files2'
		local expected2 "`proj2'.dta"

		if `n2'==0 {
			post `ph' ("`cty'") ("`proj2'") ("`path2'") ("`expected2'") ("") (0) (0) (2)
		}
		else {
			foreach f of local files2 {
				local ok = lower("`f'")==lower("`expected2'")
				post `ph' ("`cty'") ("`proj2'") ("`path2'") ("`expected2'") ("`f'") (`n2') (`ok') (2)
			}
		}

		local dirs3 : dir "`path2'" dirs "*"
		foreach proj3 of local dirs3 {
			local path3 "`path2'/`proj3'"
			local files3 : dir "`path3'" files "*.dta"
			local n3 : word count `files3'
			local expected3 "`proj3'.dta"

			if `n3'==0 {
				post `ph' ("`cty'") ("`proj3'") ("`path3'") ("`expected3'") ("") (0) (0) (3)
			}
			else {
				foreach f3 of local files3 {
					local ok3 = lower("`f3'")==lower("`expected3'")
					post `ph' ("`cty'") ("`proj3'") ("`path3'") ("`expected3'") ("`f3'") (`n3') (`ok3') (3)
				}
			}
		}
	}
}

postclose `ph'
use `manifest', clear

gen structure_ok = (filecount==1 & naming_ok==1)
order country project level folder detected_file expected_file filecount naming_ok structure_ok

save "${tempsim}/manifest_projects.dta", replace

count
global n_manifest = r(N)
count if structure_ok==0
global n_manifest_fail = r(N)

di as txt "Manifest rows      : ${n_manifest}"
di as txt "Structure failures : ${n_manifest_fail}"
