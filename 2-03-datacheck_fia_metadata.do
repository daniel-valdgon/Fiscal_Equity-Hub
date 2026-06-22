*---------------------------------------------------------------
**# Load FIA metadata values for poverty and inequality checks
*---------------------------------------------------------------
import excel "$country_data/Master_data/documentation/Metadata_FIA", ///
    clear firstrow

* Keep only FIA metadata indicators used in the replication checks
keep if inlist(ID, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17)

* Ensure metadata responses are numeric
destring Response, replace

* Store FIA metadata responses in locals named response_ID
forvalues i = 1/`=_N' {
    
    local id = ID[`i']
    local response_`id' = Response[`i']
}
di as txt "Stored FIA metadata value for ID as local response_id"

*---------------------------------------------------------------
**# Get PIP international poverty rates for 2021 PPP poverty lines
*---------------------------------------------------------------
local povlines 3 4.2 8.3

forvalues i = 1/3 {

    local povline : word `i' of `povlines'

    * Retrieve PIP results for the selected poverty line
    quietly pip, povline(`povline')

    * Keep the survey-country-year observation used for validation
    keep if country_code == "${country}"
    keep if year == ${survey_year}
    keep if survey_acronym == "$survey"

    * The PIP query should return exactly one relevant observation
    assert _N == 1

    * Store PIP headcount in percentage points
    quietly summarize headcount, meanonly
    local pov_`i'_PPP2021 = r(mean) * 100
}

di as txt "Stored PIP by poverty line as local pov_i_PPP2021"


*---------------------------------------------------------------
**# Check replication of inequality and poverty indicators
* using HFMD data and compare against FIA metadata
*-------------------------------------------------------------------
use "$HFMD_data/${file}_h", clear

local income_variables ym_pc yp_pc yn_pc yd_pc yc_pc yf_pc
local output_vars

*---------------------------------------------------------------
* 1. Deflate income variables and compute poverty/Gini
*---------------------------------------------------------------
foreach var of local income_variables {

    * Skip variable if it does not exist in the dataset
    capture confirm variable `var'
    if _rc {
        di as txt "Skipping `var': variable not found"
        continue
    }

    * Create deflated income variable
    capture drop `var'_def
    gen double `var'_def = `var' / def_sp_tmp_nat ///
        if !missing(`var', def_sp_tmp_nat) & def_sp_tmp_nat != 0

    * Skip variable if all deflated values are missing
    quietly count if !missing(`var'_def)
    if r(N) == 0 {
        di as txt "Skipping `var'_def: all values are missing"
        continue
    }

    * Poverty using national poverty line
    apoverty `var'_def [aw = popweight], varpl(zref) gen(pov_`var'_def)

    * Inequality
    ineqdeco `var'_def [aw = popweight]
    gen double gini_`var'_def = `r(gini)'

    local output_vars `output_vars' pov_`var'_def gini_`var'_def
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

replace ID = 8  if label == "gini_yp_pc_def"
replace ID = 9  if label == "gini_yn_pc_def"
replace ID = 10 if label == "gini_yd_pc_def"
replace ID = 11 if label == "gini_yc_pc_def"
replace ID = 12 if label == "gini_yf_pc_def"

replace ID = 14 if label == "pov_yp_pc_def1"
replace ID = 15 if label == "pov_yn_pc_def1"
replace ID = 16 if label == "pov_yd_pc_def1"
replace ID = 17 if label == "pov_yc_pc_def1"

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

    assert abs(FIA_metadata - data) < 0.1 if ID == `num'

    di as result "Assert passed for ID `num'"
}

di "All available FIA metadata (gini/poverty) checks passed."
sleep 2000


*---------------------------------------------------------------
**# Check replication of international poverty indicators
* using HFMD data and compare against PIP results
*---------------------------------------------------------------

if "$country" == "SEN" {
    di as result "Senegal omitted since PIP results are not updated to the latest changes."
}

else {
    use "$HFMD_data/${file}_h", clear

    *-----------------------------------------------------------
    * 1. Create welfare aggregate in 2021 PPP USD per person/day
    *-----------------------------------------------------------
    foreach reqvar in yd_pc def_sp_tmp_inat cpi_2021 ppp_2021 popweight {
        capture confirm variable `reqvar'
        if _rc {
            di as error "Required variable `reqvar' not found."
            exit 111
        }
    }

    capture drop yd_pov_2021
    gen double yd_pov_2021 = yd_pc / def_sp_tmp_inat / cpi_2021 / ppp_2021 / 365 ///
        if !missing(yd_pc, def_sp_tmp_inat, cpi_2021, ppp_2021) ///
        & def_sp_tmp_inat != 0 ///
        & cpi_2021 != 0 ///
        & ppp_2021 != 0

    quietly count if !missing(yd_pov_2021)
    if r(N) == 0 {
        di as error "yd_pov_2021 has no non-missing values."
        exit 498
    }

    *-----------------------------------------------------------
    * 2. Compute poverty indicators for international lines
    *-----------------------------------------------------------
    local povlines 3 4.2 8.3
    local output_vars

    forvalues i = 1/3 {
        local povline : word `i' of `povlines'
        capture drop __pov* inat_pov_`i'

        apoverty yd_pov_2021 [aw = popweight], line(`povline') gen(inat_pov_`i')

        local output_vars `output_vars' inat_pov_`i'

        di as txt "Created inat_pov_`i' for poverty line `povline'"
    }

    *-----------------------------------------------------------
    * 3. Collapse estimates and convert to percentages
    *-----------------------------------------------------------

    collapse (mean) `output_vars' [aw = popweight]

    foreach var of local output_vars {
        replace `var' = `var' * 100
    }

    *-----------------------------------------------------------
    * 4. Reshape results to long format and assign IDs
    *-----------------------------------------------------------

    xpose, clear varname

    rename (v1 _varname) (data label)

    gen ID = .
    forvalues i = 1/3 {
        replace ID = `i' if label == "inat_pov_`i'1"
    }
	
    keep if !missing(ID)
    sort ID

    assert _N == 3

    order ID label data

    *-----------------------------------------------------------
    * 5. Bring PIP values from globals and validate replication
    *-----------------------------------------------------------

    gen PIP_data = .

    forvalues i = 1/3 {

        local pip_value "`pov_`i'_PPP2021'"		
        if "`pip_value'" == "" {
            di as error "Missing global pov_`i'_PPP2021"
            exit 498
        }

        replace PIP_data = `pip_value' if ID == `i'

        quietly count if ID == `i'
        assert r(N) == 1

        capture assert abs(PIP_data - data) < 0.1 if ID == `i'
        local rc = _rc

        if `rc' != 0 {
            di as error "PIP check failed for international poverty line ID `i'"
            list ID label data PIP_data if ID == `i', noobs
            exit `rc'
        }

        di as result "Assert passed for international poverty line ID `i'"
    }

    di as result "All available PIP data checks passed."
	sleep 2000
}

