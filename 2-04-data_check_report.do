*---------------------------------------------------------------
**# Get PIP international poverty rates for 2021 PPP poverty lines
*---------------------------------------------------------------
preserve
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
restore

*---------------------------------------------------------------
**# Check replication of international poverty indicators
* using HFMD data and compare against PIP results
*---------------------------------------------------------------
preserve
if "$country" == "SEN" {
    di as error "Senegal omitted since PIP results are not updated to the latest changes."
	sleep 2000
}

else {   
    *---------------------------------------------------------------
    **# 1. Check required variables
    *---------------------------------------------------------------

    foreach reqvar in yd_inat_pov_2021 popweight {
        capture confirm variable `reqvar'
        if _rc {
            di as error "Required variable `reqvar' not found."
            exit 111
        }
    }

    quietly count if !missing(yd_inat_pov_2021)
    if r(N) == 0 {
        di as error "yd_inat_pov_2021 has no non-missing values."
        exit 498
    }


    *---------------------------------------------------------------
    **# 2. Compute poverty indicators for international poverty lines
    *---------------------------------------------------------------

    local povlines 3 4.2 8.3
    local output_vars

    forvalues i = 1/3 {
        
        local povline : word `i' of `povlines'

        capture drop inat_pov_`i' inat_pov_`i'1

        apoverty yd_inat_pov_2021 [aw = popweight], ///
            line(`povline') gen(inat_pov_`i')

        local output_vars `output_vars' inat_pov_`i'

        di as txt "Created inat_pov_`i' for poverty line `povline'"
    }


    *---------------------------------------------------------------
    **# 3. Collapse estimates and convert to percentages
    *---------------------------------------------------------------

    collapse (mean) `output_vars' [aw = popweight]

    foreach var of local output_vars {
        replace `var' = `var' * 100
    }


    *---------------------------------------------------------------
    **# 4. Reshape results to long format and assign IDs
    *---------------------------------------------------------------

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


*---------------------------------------------------------------
**# 5. Bring PIP values from locals and validate replication
*---------------------------------------------------------------

gen PIP_data = .

local all_pip_passed = 1

forvalues i = 1/3 {

    local pip_value "`pov_`i'_PPP2021'"
    local povline : word `i' of `povlines'

    if "`pip_value'" == "" {
        di as error "PIP check for poverty line `povline': NO - PIP value missing"
        local all_pip_passed = 0
    }

    else {

        replace PIP_data = `pip_value' if ID == `i'

        quietly count if ID == `i'
        assert r(N) == 1

        quietly sum data if ID == `i', meanonly
        local data_value = r(mean)

        capture assert abs(PIP_data - data) < 0.5 if ID == `i'

        if _rc == 0 {
            di as result "PIP check for poverty line `povline': PASSED"
        }

        else {
            di as error "PIP check for poverty line `povline': NO | Data = " %6.2f `data_value' " | PIP = " %6.2f `pip_value'
            local all_pip_passed = 0
        }
    }
}

if `all_pip_passed' {
    di as result "All available PIP data checks passed."
}
else {
    di as error "Some PIP data checks did not pass."
}

sleep 2000
}
restore