*---------------------------------------------------------------
**# Check that income concepts can be replicated using disposable
* income and fiscal instruments
*---------------------------------------------------------------

* Reverse sign convention for instruments stored as negative flows
foreach var of varlist dirtransf_total indtax_total {
    replace `var' = `var' * (-1)
}

* Reconstruct income concepts
capture drop yn_check yp_check yc_check yf_check

egen yn_check = rowtotal(yd dirtransf_total)
egen yp_check = rowtotal(yn dirtax_total ssc_nopensions)
egen yc_check = rowtotal(yd subsidy_total indtax_total)
egen yf_check = rowtotal(yc health_inKind education_inKind)

* Validate reconstructed income concepts
* Note: A relative difference of less than 1 percent is tolerated
* to account for rounding, precision, or minor aggregation differences.
assert ///
    (yn != 0 & abs((yn_check - yn) / yn) < 0.01) | ///
    (yn == 0 & abs(yn_check) < 1) ///
    if !missing(yn, yn_check)

di as result "Check passed: yn replicated from yd and direct transfers."


assert ///
    (yp != 0 & abs((yp_check - yp) / yp) < 0.01) | ///
    (yp == 0 & abs(yp_check) < 1) ///
    if !missing(yp, yp_check)

di as result "Check passed: yp replicated from yn, direct taxes, and social contributions."


assert ///
    (yc != 0 & abs((yc_check - yc) / yc) < 0.01) | ///
    (yc == 0 & abs(yc_check) < 1) ///
    if !missing(yc, yc_check)

di as result "Check passed: yc replicated from yd, subsidies, and indirect taxes."


assert ///
    (yf != 0 & abs((yf_check - yf) / yf) < 0.01) | ///
    (yf == 0 & abs(yf_check) < 1) ///
    if !missing(yf, yf_check)

di as result "Check passed: yf replicated from yc and in-kind transfers."

* Clean check variables
drop yn_check yp_check yc_check yf_check

* Restore original sign convention
foreach var of varlist dirtransf_total indtax_total {
    replace `var' = `var' * (-1)
}

di as result "All income concepts were successfully replicated using disposable income and fiscal instruments."
sleep 1000