*---------------------------------------------------------------
**# Check that fiscal instrument totals equal the sum of components
*---------------------------------------------------------------

di as error "IMPORTANT: All programs that were NOT simulated must be coded as missing, not zero. Otherwise, these checks may fail."
sleep 2000


*---------------------------------------------------------------
* Social Security Contributions (no pensions)
*---------------------------------------------------------------

egen sscontribs_nopensions_check = rowtotal(sscontribs_nopensions_employee ///
    sscontribs_nopensions_employer), missing

compare sscontribs_nopensions_check sscontribs_nopensions
assert missing(sscontribs_nopensions_check) == missing(sscontribs_nopensions)
assert abs((sscontribs_nopensions_check / sscontribs_nopensions) - 1) < 0.01 ///
    if !missing(sscontribs_nopensions_check, sscontribs_nopensions) ///
    & sscontribs_nopensions_check != 0 & sscontribs_nopensions != 0

drop sscontribs_nopensions_check


*---------------------------------------------------------------
* Direct taxes
*---------------------------------------------------------------

egen dirtax_total_check = rowtotal(dirtax_PIT dirtax_proll dirtax_property ///
    dirtax_capital dirtax_other dirtax_bit), missing

compare dirtax_total_check dirtax_total
assert missing(dirtax_total_check) == missing(dirtax_total)
assert abs((dirtax_total_check / dirtax_total) - 1) < 0.01 ///
    if !missing(dirtax_total_check, dirtax_total) ///
    & dirtax_total_check != 0 & dirtax_total != 0

drop dirtax_total_check


*---------------------------------------------------------------
* Direct transfers
*---------------------------------------------------------------

egen dirtransf_total_check = rowtotal(dtr_soc_ass dtr_soc_ins), missing

compare dirtransf_total_check dirtransf_total
assert missing(dirtransf_total_check) == missing(dirtransf_total)
assert abs((dirtransf_total_check / dirtransf_total) - 1) < 0.01 ///
    if !missing(dirtransf_total_check, dirtransf_total) ///
    & dirtransf_total_check != 0 & dirtransf_total != 0

drop dirtransf_total_check


* Social assistance

egen dtr_soc_ass_check = rowtotal(dtr_cash dtr_ocash dtr_wp dtr_inkind dtr_other), missing

compare dtr_soc_ass_check dtr_soc_ass
assert missing(dtr_soc_ass_check) == missing(dtr_soc_ass)
assert abs((dtr_soc_ass_check / dtr_soc_ass) - 1) < 0.01 ///
    if !missing(dtr_soc_ass_check, dtr_soc_ass) ///
    & dtr_soc_ass_check != 0 & dtr_soc_ass != 0

drop dtr_soc_ass_check


*---------------------------------------------------------------
* Subsidies
*---------------------------------------------------------------

egen subsidy_total_check = rowtotal(subs_elec_total subs_fuel_total ///
    subs_water_total subs_food_total subs_agric_total subs_other_total), missing

compare subsidy_total_check subsidy_total
assert missing(subsidy_total_check) == missing(subsidy_total)
assert abs((subsidy_total_check / subsidy_total) - 1) < 0.01 ///
    if !missing(subsidy_total_check, subsidy_total) ///
    & subsidy_total_check != 0 & subsidy_total != 0

drop subsidy_total_check


* Electricity, fuel, water, food, and agriculture subsidies

foreach x in elec fuel water food agric {

    egen `x'_check = rowtotal(subsidy_`x'_direct subsidy_`x'_indirect), missing

    compare `x'_check subs_`x'_total
    assert missing(`x'_check) == missing(subs_`x'_total)
    assert abs((`x'_check / subs_`x'_total) - 1) < 0.01 ///
        if !missing(`x'_check, subs_`x'_total) ///
        & `x'_check != 0 & subs_`x'_total != 0

    drop `x'_check
}


*---------------------------------------------------------------
* Indirect taxes
*---------------------------------------------------------------

egen indtax_total_check = rowtotal(VAT_total excise_fuel excise_other ///
    CD_total other_indirect), missing

compare indtax_total_check indtax_total
assert missing(indtax_total_check) == missing(indtax_total)
assert abs((indtax_total_check / indtax_total) - 1) < 0.01 ///
    if !missing(indtax_total_check, indtax_total) ///
    & indtax_total_check != 0 & indtax_total != 0

drop indtax_total_check


* VAT and customs duties

foreach x in VAT CD {

    egen `x'_check = rowtotal(`x'_direct `x'_indirect), missing

    compare `x'_check `x'_total
    assert missing(`x'_check) == missing(`x'_total)
    assert abs((`x'_check / `x'_total) - 1) < 0.01 ///
        if !missing(`x'_check, `x'_total) ///
        & `x'_check != 0 & `x'_total != 0

    drop `x'_check
}


* Excise taxes

foreach x in excise_fuel excise_other {

    egen `x'_check = rowtotal(`x'_direct `x'_indirect), missing

    compare `x'_check `x'
    assert missing(`x'_check) == missing(`x')
    assert abs((`x'_check / `x') - 1) < 0.01 ///
        if !missing(`x'_check, `x') ///
        & `x'_check != 0 & `x' != 0

    drop `x'_check
}


*---------------------------------------------------------------
* In-kind transfers
*---------------------------------------------------------------

egen inktransf_total_check = rowtotal(education_inKind health_inKind), missing

compare inktransf_total_check inktransf_total
assert missing(inktransf_total_check) == missing(inktransf_total)
assert abs((inktransf_total_check / inktransf_total) - 1) < 0.01 ///
    if !missing(inktransf_total_check, inktransf_total) ///
    & inktransf_total_check != 0 & inktransf_total != 0

drop inktransf_total_check


* Education in-kind transfers

egen inkeduc_total_check = rowtotal(education_pre_and_prim education_secondary ///
    education_tertiary education_psnt education_copay), missing

compare inkeduc_total_check education_inKind
assert missing(inkeduc_total_check) == missing(education_inKind)
assert abs((inkeduc_total_check / education_inKind) - 1) < 0.01 ///
    if !missing(inkeduc_total_check, education_inKind) ///
    & inkeduc_total_check != 0 & education_inKind != 0

drop inkeduc_total_check


di as result "Fiscal instruments organized, standardized, and checked to sum to totals."
sleep 2000