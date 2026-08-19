*---------------------------------------------------------------
**# Load FIA metadata values for poverty and inequality checks
*---------------------------------------------------------------
preserve
import excel "$country_data/Master_data/documentation/Metadata_FIA", clear 

drop E F
rename (A B C D) (ID Type Variable Response)
drop if ID=="ID" 
drop if Variable==""
	destring ID, replace


* Keep only FIA metadata indicators used in the replication checks
keep if inlist(ID, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,18)

* Ensure metadata responses are numeric
destring Response, replace

* Store FIA metadata responses in locals named response_ID
forvalues i = 1/`=_N' {
    
    local id = ID[`i']
    local response_`id' = Response[`i']
}
di as txt "Stored FIA metadata value for ID as local response_id"
restore

*---------------------------------------------------------------
**# Check replication of inequality and poverty indicators
* using HFMD data and compare against FIA metadata
*-------------------------------------------------------------------
local income_variables ym_nat_pov yp_nat_pov yn_nat_pov yd_nat_pov yc_nat_pov yf_nat_pov
local output_vars

*---------------------------------------------------------------
**# 1. Compute poverty and Gini using national-poverty real income variables
*---------------------------------------------------------------
preserve
foreach var of local income_variables {

    * Skip variable if it does not exist in the dataset
    capture confirm variable `var'
    if _rc {
        di as txt "Skipping `var': variable not found"
        continue
    }

    * Skip variable if all values are missing
    quietly count if !missing(`var')
    if r(N) == 0 {
        di as txt "Skipping `var': all values are missing"
        continue
    }

    * Poverty using national poverty line
    apoverty `var' [aw = popweight], varpl(zref) gen(pov_`var')

    * Inequality
    ineqdeco `var' [aw = popweight]
    gen double gini_`var' = `r(gini)'

    local output_vars `output_vars' pov_`var' gini_`var'
}

* Stop if no indicators were created
if "`output_vars'" == "" {
    di as error "No poverty or inequality indicators were created."
    exit 498
}

*---------------------------------------------------------------
* 2. Collapse indicators and reshape to long format
*---------------------------------------------------------------
collapse (mean) `output_vars' [aw = popweight]

foreach var of varlist `output_vars' {
    replace `var' = `var' * 100
}

xpose, clear varname

rename (v1 _varname) (data label)
order label data

*---------------------------------------------------------------
* 3. Assign FIA metadata IDs to replicated indicators
*---------------------------------------------------------------
gen ID = .
replace ID = 8  if label == "gini_ym_nat_pov"
replace ID = 9  if label == "gini_yp_nat_pov"
replace ID = 10  if label == "gini_yn_nat_pov"
replace ID = 11 if label == "gini_yd_nat_pov"
replace ID = 12 if label == "gini_yc_nat_pov"
replace ID = 13 if label == "gini_yf_nat_pov"

replace ID = 14 if label == "pov_ym_nat_pov1"
replace ID = 15 if label == "pov_yp_nat_pov1"
replace ID = 16 if label == "pov_yn_nat_pov1"
replace ID = 17 if label == "pov_yd_nat_pov1"
replace ID = 18 if label == "pov_yc_nat_pov1"

drop if label =="pov_yf_nat_pov1" //not measuring poverty with the final income
keep if !missing(ID)
sort ID
order ID label data

*---------------------------------------------------------------
* 4. Bring FIA metadata values from locals response_ID
*---------------------------------------------------------------
gen FIA_metadata = .

levelsof ID, local(ids_to_check)

foreach num of local ids_to_check {
    local value : copy local response_`num'

    if "`value'" == "" {
        di as error "Missing local response_`num'"
        exit 498
    }

    replace FIA_metadata = `value' if ID == `num'
}

*---------------------------------------------------------------
* 5. Validate replicated values against FIA metadata
*---------------------------------------------------------------

foreach num of local ids_to_check {

    levelsof label if ID == `num', local(lbl) clean

    capture assert abs(FIA_metadata - data) < 1 if ID == `num'

    if _rc == 0 {
        di as result "`lbl': CHECK PASSED (comparing results from data with FIA metadata)"
    }
    else {
        di as error "`lbl': CHECK NO PASSED (comparing results from data with FIA metadata)"
    }
}

di "All available FIA metadata (gini/poverty) checks done."
sleep 2000
restore

