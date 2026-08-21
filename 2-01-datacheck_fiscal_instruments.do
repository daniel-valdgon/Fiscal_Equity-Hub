*---------------------------------------------------------------
**# Check that fiscal instrument totals equal the sum of components
*---------------------------------------------------------------

di as error "IMPORTANT: All programs that were NOT simulated must be coded as missing, not zero. Otherwise, these checks may fail."
sleep 2000


*---------------------------------------------------------------
* Social Security Contributions (no pensions)
*---------------------------------------------------------------
if !missing(ssc_nopensions_employee) | !missing(ssc_nopensions_employer){

	egen ssc_nopensions_check = rowtotal(ssc_nopensions_employee ///
	    ssc_nopensions_employer), missing

	compare ssc_nopensions_check ssc_nopensions

	assert missing(ssc_nopensions_check) == missing(ssc_nopensions)

	assert ///
	    (ssc_nopensions != 0 & abs((ssc_nopensions_check - ssc_nopensions) / ssc_nopensions) < 0.01) | ///
	    (ssc_nopensions == 0 & abs(ssc_nopensions_check) < 1) ///
	    if !missing(ssc_nopensions, ssc_nopensions_check)

	drop ssc_nopensions_check
	
	dis "Checked disaggregation ssc_nopensions"
}
else{
	dis as error "No disaggregation to check ssc_nopensions"
	sleep 1000
}


*---------------------------------------------------------------
* Direct taxes
*---------------------------------------------------------------
if !missing(dirtax_PIT) | !missing(dirtax_proll) | !missing(dirtax_property) | ///
   !missing(dirtax_capital) | !missing(dirtax_other) | !missing(dirtax_bit){

	egen dirtax_total_check = rowtotal(dirtax_PIT dirtax_proll dirtax_property ///
	    dirtax_capital dirtax_other dirtax_bit), missing

	compare dirtax_total_check dirtax_total

	assert missing(dirtax_total_check) == missing(dirtax_total)

	assert ///
	    (dirtax_total != 0 & abs((dirtax_total_check - dirtax_total) / dirtax_total) < 0.01) | ///
	    (dirtax_total == 0 & abs(dirtax_total_check) < 1) ///
	    if !missing(dirtax_total, dirtax_total_check)

	drop dirtax_total_check
	
	dis "Checked disaggregation dirtax_total"
}
else{
	dis as error "No disaggregation to check dirtax_total"
	sleep 1000
}


*---------------------------------------------------------------
* Direct transfers
*---------------------------------------------------------------
if !missing(dtr_soc_ass) | !missing(dtr_soc_ins) {

	egen dirtransf_total_check = rowtotal(dtr_soc_ass dtr_soc_ins), missing

	compare dirtransf_total_check dirtransf_total

	assert missing(dirtransf_total_check) == missing(dirtransf_total)

	assert ///
	    (dirtransf_total != 0 & abs((dirtransf_total_check - dirtransf_total) / dirtransf_total) < 0.01) | ///
	    (dirtransf_total == 0 & abs(dirtransf_total_check) < 1) ///
	    if !missing(dirtransf_total, dirtransf_total_check)

	drop dirtransf_total_check
	
	dis "Checked disaggregation dirtransf_total"
}
else{
	dis as error "No disaggregation to check dirtransf_total"
	sleep 1000
}


*---------------------------------------------------------------
* Social assistance
*---------------------------------------------------------------
if !missing(dtr_cash) | !missing(dtr_ocash) | !missing(dtr_wp) | ///
   !missing(dtr_inkind) | !missing(dtr_other){

	egen dtr_soc_ass_check = rowtotal(dtr_cash dtr_ocash dtr_wp ///
	    dtr_inkind dtr_other), missing

	compare dtr_soc_ass_check dtr_soc_ass

	assert missing(dtr_soc_ass_check) == missing(dtr_soc_ass)

	assert ///
	    (dtr_soc_ass != 0 & abs((dtr_soc_ass_check - dtr_soc_ass) / dtr_soc_ass) < 0.01) | ///
	    (dtr_soc_ass == 0 & abs(dtr_soc_ass_check) < 1) ///
	    if !missing(dtr_soc_ass, dtr_soc_ass_check)

	drop dtr_soc_ass_check
	
	dis "Checked disaggregation dtr_soc_ass"
}
else{
	dis as error "No disaggregation to check dtr_soc_ass"
	sleep 1000
}


*---------------------------------------------------------------
* Subsidies
*---------------------------------------------------------------
if !missing(subs_elec_total) | !missing(subs_fuel_total) | ///
   !missing(subs_water_total) | !missing(subs_food_total) | ///
   !missing(subs_agric_total) | !missing(subs_other_total){

	egen subsidy_total_check = rowtotal(subs_elec_total subs_fuel_total ///
	    subs_water_total subs_food_total subs_agric_total subs_other_total), missing

	compare subsidy_total_check subsidy_total

	assert missing(subsidy_total_check) == missing(subsidy_total)

	assert ///
	    (subsidy_total != 0 & abs((subsidy_total_check - subsidy_total) / subsidy_total) < 0.01) | ///
	    (subsidy_total == 0 & abs(subsidy_total_check) < 1) ///
	    if !missing(subsidy_total, subsidy_total_check)

	drop subsidy_total_check
	
	dis "Checked disaggregation subsidy_total"
}
else{
	dis as error "No disaggregation to check subsidy_total"
	sleep 1000
}


*---------------------------------------------------------------
* Electricity, fuel, water, food, and agriculture subsidies
*---------------------------------------------------------------
foreach x in elec fuel water food agric {

	if !missing(subsidy_`x'_direct) | !missing(subsidy_`x'_indirect){

		egen `x'_check = rowtotal(subsidy_`x'_direct ///
		    subsidy_`x'_indirect), missing

		compare `x'_check subs_`x'_total

		assert missing(`x'_check) == missing(subs_`x'_total)

		assert ///
		    (subs_`x'_total != 0 & abs((`x'_check - subs_`x'_total) / subs_`x'_total) < 0.01) | ///
		    (subs_`x'_total == 0 & abs(`x'_check) < 1) ///
		    if !missing(subs_`x'_total, `x'_check)

		drop `x'_check
		
		dis "Checked disaggregation subs_`x'_total"
	}
	else{
		dis as error "No disaggregation to check subs_`x'_total"
		sleep 1000
	}
}


*---------------------------------------------------------------
* Indirect taxes
*---------------------------------------------------------------
if !missing(VAT_total) | !missing(excise_fuel) | !missing(excise_other) | ///
   !missing(CD_total) | !missing(other_indirect){

	egen indtax_total_check = rowtotal(VAT_total excise_fuel excise_other ///
	    CD_total other_indirect), missing

	compare indtax_total_check indtax_total

	assert missing(indtax_total_check) == missing(indtax_total)

	assert ///
	    (indtax_total != 0 & abs((indtax_total_check - indtax_total) / indtax_total) < 0.01) | ///
	    (indtax_total == 0 & abs(indtax_total_check) < 1) ///
	    if !missing(indtax_total, indtax_total_check)

	drop indtax_total_check
	
	dis "Checked disaggregation indtax_total"
}
else{
	dis as error "No disaggregation to check indtax_total"
	sleep 1000
}


*---------------------------------------------------------------
* VAT and customs duties
*---------------------------------------------------------------
foreach x in VAT CD {

	if !missing(`x'_direct) | !missing(`x'_indirect){

		egen `x'_check = rowtotal(`x'_direct `x'_indirect), missing

		compare `x'_check `x'_total

		assert missing(`x'_check) == missing(`x'_total)

		assert ///
		    (`x'_total != 0 & abs((`x'_check - `x'_total) / `x'_total) < 0.01) | ///
		    (`x'_total == 0 & abs(`x'_check) < 1) ///
		    if !missing(`x'_total, `x'_check)

		drop `x'_check
		
		dis "Checked disaggregation `x'_total"
	}
	else{
		dis as error "No disaggregation to check `x'_total"
		sleep 1000
	}
}


*---------------------------------------------------------------
* Excise taxes
*---------------------------------------------------------------
foreach x in excise_fuel excise_other {

	if !missing(`x'_direct) | !missing(`x'_indirect){

		egen `x'_check = rowtotal(`x'_direct `x'_indirect), missing

		compare `x'_check `x'

		assert missing(`x'_check) == missing(`x')

		assert ///
		    (`x' != 0 & abs((`x'_check - `x') / `x') < 0.01) | ///
		    (`x' == 0 & abs(`x'_check) < 1) ///
		    if !missing(`x', `x'_check)

		drop `x'_check
		
		dis "Checked disaggregation `x'"
	}
	else{
		dis as error "No disaggregation to check `x'"
		sleep 1000
	}
}


*---------------------------------------------------------------
* In-kind transfers
*---------------------------------------------------------------

foreach x in education_copay health_copay {
	replace `x' = `x' * -1
}


* Total in-kind transfers
if !missing(education_inKind) | !missing(health_inKind){

	egen inktransf_total_check = rowtotal(education_inKind ///
	    health_inKind), missing

	format inktransf_total_check %20.1f

	compare inktransf_total_check inktransf_total

	assert missing(inktransf_total_check) == missing(inktransf_total)

	assert ///
	    (inktransf_total != 0 & abs((inktransf_total_check - inktransf_total) / inktransf_total) < 0.01) | ///
	    (inktransf_total == 0 & abs(inktransf_total_check) < 1) ///
	    if !missing(inktransf_total, inktransf_total_check)

	drop inktransf_total_check
	
	dis "Checked disaggregation inktransf_total"
}
else{
	dis as error "No disaggregation to check inktransf_total"
	sleep 1000
}


*---------------------------------------------------------------
* Education in-kind transfers
*---------------------------------------------------------------
if !missing(education_pre_and_prim) | !missing(education_secondary) | ///
   !missing(education_tertiary) | !missing(education_psnt) | ///
   !missing(education_copay){

	egen inkeduc_total_check = rowtotal(education_pre_and_prim ///
	    education_secondary education_tertiary education_psnt ///
	    education_copay), missing

	format inkeduc_total_check %20.1f

	compare inkeduc_total_check education_inKind

	assert missing(inkeduc_total_check) == missing(education_inKind)

	assert ///
	    (education_inKind != 0 & abs((inkeduc_total_check - education_inKind) / education_inKind) < 0.01) | ///
	    (education_inKind == 0 & abs(inkeduc_total_check) < 1) ///
	    if !missing(education_inKind, inkeduc_total_check)

	drop inkeduc_total_check
	
	dis "Checked disaggregation education_inKind"
}
else{
	dis as error "No disaggregation to check education_inKind"
	sleep 1000
}


foreach x in education_copay health_copay {
	replace `x' = `x' * -1
}


di as result "Fiscal instruments organized, standardized, and checked to sum to totals."
sleep 2000