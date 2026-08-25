*---------------------------------------------------------------
**# Merge with GMD by individual
*---------------------------------------------------------------
/*preserve
use "${GMD_file}", clear

if "$country"=="COL"{
gen posicion_punto = strpos(hhid, ".")
gen hhid_nueva = substr(hhid, 1, posicion_punto - 1)
drop hhid posicion_punto
rename hhid_nueva hhid
order hhid, b(pid)
}

tempfile GMD_file_i
save `GMD_file_i', replace
restore

use "$HFMD_data/${file}_i", clear
merge 1:1 hhid pid using `GMD_file_i'
*/

*---------------------------------------------------------------
**# Merge with GMD by individual
*---------------------------------------------------------------
preserve
use "${GMD_file}", clear
duplicates drop hhid, force

if "$country"=="COL"{
gen posicion_punto = strpos(hhid, ".")
gen hhid_nueva = substr(hhid, 1, posicion_punto - 1)
drop hhid posicion_punto
rename hhid_nueva hhid
order hhid, b(pid)
}

tempfile GMD_file
save `GMD_file', replace
restore

*use "`${country}_${survey_year}_${survey}'", clear
merge 1:1 hhid using `GMD_file', assert(2 3)

