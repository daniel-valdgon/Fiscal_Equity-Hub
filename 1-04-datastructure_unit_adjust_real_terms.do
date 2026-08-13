*---------------------------------------------------------------
**# Official household size adjustment 
*---------------------------------------------------------------
sum division_unit
local division_unit = `r(mean)'
dis `division_unit'

* Define the adjustment factor according to the official metadata
if "`division_unit'" == "2" {
    global hh_adj "hhsize"
	local label_division_unit "Per capita"
}
else if "`division_unit'" == "1" {
    global hh_adj "ae"
	global label_division_unit "Adult equivalent"
}
else {
    di as error "ERROR: Household size adjustment not recognized: `division_unit'"
    exit 498
}


*---------------------------------------------------------------
**# 1. Apply official household size adjustment
*---------------------------------------------------------------
foreach income in ym yp yn yd yc yf {
    
    * Convert household income aggregates into official units
    gen `income'_unit = `income' / ${hh_adj}
		  local income_label : variable label `income'
	 label var `income'_unit "`income_label' (`label_division_unit')"
	
    * Create spatial-temporal deflated income for distribution groups
    gen `income'_unit_df = `income'_unit / def_sp_tmp_nat
	label var `income'_unit_df "`income_label' (`label_division_unit'), deflacted"
	
}

di as result "Household income aggregates have been adjusted using the official household size adjustment. (${country}: `label_division_unit')"
sleep 2000


*---------------------------------------------------------------
**# 2. Create income deciles and percentiles using deflated income
*---------------------------------------------------------------
foreach income in ym yp yn yd yc yf {
    
    quietly count if !missing(`income'_unit_df)

    * If the income variable is fully missing, create empty percentile/decile variables
    if r(N) == 0 {
        gen `income'_pvdc_unit = .
        gen `income'_pvpc_unit = .
    }
    
    * Otherwise, create deciles and percentiles using population weights
    else {
        xtile `income'_pvdc_unit = `income'_unit_df [aw = hhweight * hhsize] if !missing(`income'_unit_df), nq(10)

        xtile `income'_pvpc_unit = `income'_unit_df [aw = hhweight * hhsize] if !missing(`income'_unit_df), nq(100)
    }

    label var `income'_pvdc_unit "Deciles based on `income' (`label_division_unit') spatial-temporal deflated"

    label var `income'_pvpc_unit "Percentiles based on `income' (`label_division_unit') spatial-temporal deflated"

    drop `income'_unit_df
}

di as result "Deciles and percentiles by income created."
sleep 1000


*---------------------------------------------------------------
**# 3. Create income variables for national and international poverty
*---------------------------------------------------------------
foreach income in ym yp yn yd yc yf {
    
    quietly count if !missing(`income'_unit)

    * If the adjusted income variable is fully missing, create empty poverty variables
    if r(N) == 0 {
        gen `income'_inat_pov_2021 = .
        gen `income'_inat_pov_2017 = .
        gen `income'_nat_pov       = .
    }
    
    * Otherwise, express income in real terms for poverty measurement
    else {
        
        * International poverty, 2021 PPP USD per person/day
        gen `income'_inat_pov_2021 = ///
            `income'_unit / def_sp_tmp_inat / cpi_2021 / ppp_2021 / 365 ///
            if !missing(`income'_unit)

        * International poverty, 2017 PPP USD per person/day
        gen `income'_inat_pov_2017 = ///
            `income'_unit / def_sp_tmp_inat / cpi_2017 / ppp_2017 / 365 ///
            if !missing(`income'_unit)

        * National poverty, spatial-temporal deflated local currency
        gen `income'_nat_pov = ///
            `income'_unit / def_sp_tmp_nat ///
            if !missing(`income'_unit)
    }
}

label var ym_inat_pov_2021 "Pre-fiscal income, 2021 PPP, for international poverty lines"
label var ym_inat_pov_2017 "Pre-fiscal income, 2017 PPP, for international poverty lines"
label var ym_nat_pov "Pre-fiscal income, for national poverty line"
label var yp_inat_pov_2021 "Market income plus pensions, 2021 PPP, for international poverty lines"
label var yp_inat_pov_2017 "Market income plus pensions, 2017 PPP, for international poverty lines"
label var yp_nat_pov "Market income plus pensions, for national poverty line"
label var yn_inat_pov_2021 "Net market income, 2021 PPP, for international poverty lines"
label var yn_inat_pov_2017 "Net market income, 2017 PPP, for international poverty lines"
label var yn_nat_pov "Net market income, for national poverty line"
label var yd_inat_pov_2021 "Disposable income, 2021 PPP, for international poverty lines"
label var yd_inat_pov_2017 "Disposable income, 2017 PPP, for international poverty lines"
label var yd_nat_pov "Disposable income, for national poverty line"
label var yc_inat_pov_2021 "Consumable income, 2021 PPP, for international poverty lines"
label var yc_inat_pov_2017 "Consumable income, 2017 PPP, for international poverty lines"
label var yc_nat_pov "Consumable income, for national poverty line"
label var yf_inat_pov_2021 "Final income, 2021 PPP, for international poverty lines"
label var yf_inat_pov_2017 "Final income, 2017 PPP, for international poverty lines"
label var yf_nat_pov "Final income, for national poverty line"

order ym_inat_pov_2021 ym_inat_pov_2017 ym_nat_pov yp_inat_pov_2021 yp_inat_pov_2017 yp_nat_pov yn_inat_pov_2021 yn_inat_pov_2017 yn_nat_pov yd_inat_pov_2021 yd_inat_pov_2017 yd_nat_pov yc_inat_pov_2021 yc_inat_pov_2017 yc_nat_pov yf_inat_pov_2021 yf_inat_pov_2017 yf_nat_pov, a(zref1)

order ym_unit yp_unit yn_unit yd_unit yc_unit yf_unit ym_pvdc_unit ym_pvpc_unit yp_pvdc_unit yp_pvpc_unit yn_pvdc_unit yn_pvpc_unit yd_pvdc_unit yd_pvpc_unit yc_pvdc_unit yc_pvpc_unit yf_pvdc_unit yf_pvpc_unit, a(yf)

di as result "Income variables for national and international poverty created. Please check the results."
sleep 1000