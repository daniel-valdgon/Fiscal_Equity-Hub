*---------------------------------------------------------------
* Check expected variable structure
*---------------------------------------------------------------
* Read-only: HFMD must already contain sections and all derived variables.

* List of variables expected in the final HFMD database
local expected ///
section1 cp_model country syear_i syear_f p_year version hhid hhsize ae hhweight popweight hhweight_sy popweight_sy urban region division_unit ///
section2 def_sp_nat def_tmp_nat def_sp_tmp_nat cpi_2017 ppp_2017 cpi_2021 ppp_2021 def_tmp_cat def_spa_cat def_sp_inat def_tmp_inat def_sp_tmp_inat def_tmp_inat_cat def_spa_inat_cat ///
section3 zref1 ym_pvdc ym_pvpc yp_pvdc yp_pvpc yn_pvdc yn_pvpc yd_pvdc yd_pvpc yc_pvdc yc_pvpc yf_pvdc yf_pvpc ym_inat_pov_2021 ym_inat_pov_2017 ym_nat_pov yp_inat_pov_2021 yp_inat_pov_2017 yp_nat_pov yn_inat_pov_2021 yn_inat_pov_2017 yn_nat_pov yd_inat_pov_2021 yd_inat_pov_2017 yd_nat_pov yc_inat_pov_2021 yc_inat_pov_2017 yc_nat_pov yf_inat_pov_2021 yf_inat_pov_2017 yf_nat_pov ///
section4 ym yp yn yd yc yf ym_pc yp_pc yn_pc yd_pc yc_pc yf_pc ym_ae yp_ae yn_ae yd_ae yc_ae yf_ae ///
section5 ///
section5_1 pension_total ssc_pensions ssc_pensions_employee ssc_pensions_employer ssc_nopensions ssc_nopensions_employee ssc_nopensions_employer pension_total_pc ssc_pensions_pc ssc_pensions_employee_pc ssc_pensions_employer_pc ssc_nopensions_pc ssc_nopensions_employee_pc ssc_nopensions_employer_pc pension_total_ae ssc_pensions_ae ssc_pensions_employee_ae ssc_pensions_employer_ae ssc_nopensions_ae ssc_nopensions_employee_ae ssc_nopensions_employer_ae ///
section5_2 dirtax_total dirtax_proll dirtax_property dirtax_PIT dirtax_salaries dirtax_bit dirtax_capital dirtax_pit_other dirtax_other dirtax_total_pc dirtax_proll_pc dirtax_property_pc dirtax_PIT_pc dirtax_salaries_pc dirtax_bit_pc dirtax_capital_pc dirtax_pit_other_pc dirtax_other_pc dirtax_total_ae dirtax_proll_ae dirtax_property_ae dirtax_PIT_ae dirtax_salaries_ae dirtax_bit_ae dirtax_capital_ae dirtax_pit_other_ae dirtax_other_ae ///
section5_3 dirtransf_total dtr_soc_ass dtr_soc_ins dtr_cash dtr_ocash dtr_wp dtr_inkind dtr_other dirtransf_total_pc dtr_soc_ass_pc dtr_soc_ins_pc dtr_cash_pc dtr_ocash_pc dtr_wp_pc dtr_inkind_pc dtr_other_pc dirtransf_total_ae dtr_soc_ass_ae dtr_soc_ins_ae dtr_cash_ae dtr_ocash_ae dtr_wp_ae dtr_inkind_ae dtr_other_ae ///
section5_4 subsidy_total subs_elec_total subs_fuel_total subs_water_total subs_food_total subs_agric_total subs_other_total subsidy_elec_direct subsidy_elec_indirect subsidy_fuel_direct subsidy_fuel_indirect subsidy_water_direct subsidy_water_indirect subsidy_food_direct subsidy_food_indirect subsidy_agric_direct subsidy_agric_indirect subsidy_total_pc subs_elec_total_pc subs_fuel_total_pc subs_water_total_pc subs_food_total_pc subs_agric_total_pc subs_other_total_pc subsidy_elec_direct_pc subsidy_elec_indirect_pc subsidy_fuel_direct_pc subsidy_fuel_indirect_pc subsidy_water_direct_pc subsidy_water_indirect_pc subsidy_food_direct_pc subsidy_food_indirect_pc subsidy_agric_direct_pc subsidy_agric_indirect_pc subsidy_total_ae subs_elec_total_ae subs_fuel_total_ae subs_water_total_ae subs_food_total_ae subs_agric_total_ae subs_other_total_ae subsidy_elec_direct_ae subsidy_elec_indirect_ae subsidy_fuel_direct_ae subsidy_fuel_indirect_ae subsidy_water_direct_ae subsidy_water_indirect_ae subsidy_food_direct_ae subsidy_food_indirect_ae subsidy_agric_direct_ae subsidy_agric_indirect_ae ///
section5_5 indtax_total VAT_total excise_fuel excise_other CD_total other_indirect VAT_direct VAT_indirect excise_fuel_direct excise_fuel_indirect excise_other_direct excise_other_indirect CD_direct CD_indirect indtax_total_pc VAT_total_pc excise_fuel_pc excise_other_pc CD_total_pc other_indirect_pc VAT_direct_pc VAT_indirect_pc excise_fuel_direct_pc excise_fuel_indirect_pc excise_other_direct_pc excise_other_indirect_pc CD_direct_pc CD_indirect_pc indtax_total_ae VAT_total_ae excise_fuel_ae excise_other_ae CD_total_ae other_indirect_ae VAT_direct_ae VAT_indirect_ae excise_fuel_direct_ae excise_fuel_indirect_ae excise_other_direct_ae excise_other_indirect_ae CD_direct_ae CD_indirect_ae ///
section5_6 inktransf_total inktransf_total_pc inktransf_total_ae ///
section5_6a education_inKind education_pre_and_prim education_preprimary education_primary education_secondary education_tertiary education_psnt education_copay education_other education_inKind_pc education_pre_and_prim_pc education_preprimary_pc education_primary_pc education_secondary_pc education_tertiary_pc education_psnt_pc education_copay_pc education_other_pc education_inKind_ae education_pre_and_prim_ae education_preprimary_ae education_primary_ae education_secondary_ae education_tertiary_ae education_psnt_ae education_copay_ae education_other_ae ///
section5_6b health_inKind health_contr health_non_contr health_hospital health_prim health_inpatient health_outpatient health_copay health_other health_inKind_pc health_contr_pc health_non_contr_pc health_hospital_pc health_prim_pc health_inpatient_pc health_outpatient_pc health_copay_pc health_other_pc health_inKind_ae health_contr_ae health_non_contr_ae health_hospital_ae health_prim_ae health_inpatient_ae health_outpatient_ae health_copay_ae health_other_ae


*---------------------------------------------------------------
**# 1. Check that the dataset contains the required base and derived variables
*---------------------------------------------------------------
unab current : _all

local missing : list expected - current
local extra   : list current - expected

* Stop if any expected variables are missing
if "`missing'" != "" {
    di as error "ERROR: these variables are missing: `missing'"
    exit 111
}

* Drop extra variables, if any, and keep only the expected structure
if "`extra'" != "" {
    di as error "WARNING: these extra variables will be dropped: `extra'"
    drop `extra'
}

* Re-check final variable structure after dropping extras
unab current : _all
local extra : list current - expected

assert "`extra'" == ""

di as result "Variable completeness check passed: all variables are either populated or completely empty."
sleep 2000

*---------------------------------------------------------------
**# 2. Check that variables are consistently coded
*---------------------------------------------------------------
* Variables should be numeric whenever they contain numeric data.
* Fully missing variables are allowed because they indicate that the
* corresponding fiscal instrument or program was not simulated.
* String variables are allowed only if they are either fully populated
* or fully empty; mixed string variables are flagged as inconsistent.

local invalid_type
local invalid_string_missing

foreach var of local expected {

    capture confirm numeric variable `var'

    if _rc == 0 {
        * Numeric variables are allowed
        continue
    }

    else {
        * String variables must be either fully populated or fully empty
        quietly count if `var' != ""
        local n_nonempty = r(N)

        quietly count if `var' == ""
        local n_empty = r(N)

        if `n_nonempty' > 0 & `n_empty' > 0 {
            local invalid_string_missing `invalid_string_missing' `var'
        }
    }
}

if "`invalid_string_missing'" != "" {
    di as error "ERROR: these string variables are partially missing: `invalid_string_missing'"
    exit 109
}

di as result "Variable completeness check passed: all variables are either populated or completely empty."
sleep 2000

*---------------------------------------------------------------
**# 3. Warn about negative numeric values without stopping execution
*---------------------------------------------------------------
* Check all numeric variables, including categories containing "other".
* Zeros and missing values do not trigger warnings.
local negative_vars

foreach var of local expected {
    capture confirm numeric variable `var'
    if _rc != 0 {
        continue
    }

    quietly count if `var' < 0 & !missing(`var')
    if r(N) > 0 {
        di as error "WARNING: `var' contains " r(N) " negative observations."
        local negative_vars `negative_vars' `var'
    }
}

if "`negative_vars'" != "" {
    di as error "WARNING: negative values found in: `negative_vars'. Execution will continue."
}
else {
    di as result "Numeric sign check completed: no negative values found."
}

sleep 3000
