*---------------------------------------------------------------
**# Merge with GMD by individual
*---------------------------------------------------------------
/*preserve
use "${GMD_file}", clear

	capture confirm hhid_orig
	if _rc != 0 {
		drop hhid
		rename hhid_orig hhid
	}

	capture confirm pid_orig
	if _rc != 0 {
		drop pid
		rename pid_orig pid
	}

tempfile GMD_file_i
save `GMD_file_i', replace

use "$HFMD_data/${file}_i", clear
merge 1:1 hhid pid using `GMD_file_i'
//, assert(2 3)

di as result "Matching correctly individuals database and GMD"
sleep 2000
restore*/

*---------------------------------------------------------------
**# Merge with GMD by individual
*---------------------------------------------------------------
preserve
use "${GMD_file}", clear
duplicates drop hhid, force

	capture confirm variable hhid_orig
	if _rc == 0 {
		quietly count if !missing(hhid_orig)

		if r(N) > 0 {
			capture drop hhid
			rename hhid_orig hhid
		}
	}
	
	destring hhid, replace
	tempfile GMD_file
	save `GMD_file', replace
	
use "`${country}_${survey_year}_${survey}'", clear
merge 1:1 hhid using `GMD_file'

destring hhid, replace
di as result "Matching correctly households database and GMD"
sleep 2000
restore

