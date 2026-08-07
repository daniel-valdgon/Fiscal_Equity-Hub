*---------------------------------------------------------------
* Check expected variable structure
*---------------------------------------------------------------
* List of variables expected in the final HFMD database
local expected ///
section1 cp_model country syear_i syear_f p_year version hhid hhsize ae hhweight popweight hhweight_sy popweight_sy urban region ///
section2 def_sp_nat def_tmp_nat def_sp_tmp_nat cpi_2017 ppp_2017 cpi_2021 ppp_2021 def_tmp_cat def_spa_cat def_sp_inat def_tmp_inat def_sp_tmp_inat def_tmp_inat_cat def_spa_inat_cat ///
section3 zref1 ///
section4 ym yp yn yd yc yf ///
section5 ///
section5_1 pension_total sscontribs_pensions sscontribs_pensions_employee sscontribs_pensions_employer sscontribs_nopensions sscontribs_nopensions_employee sscontribs_nopensions_employer ///
section5_2 dirtax_total dirtax_PIT dirtax_proll dirtax_property dirtax_bit dirtax_capital dirtax_other ///
section5_3 dirtransf_total dtr_soc_ass dtr_soc_ins dtr_cash dtr_ocash dtr_wp dtr_inkind dtr_other ///
section5_4 subsidy_total subs_elec_total subs_fuel_total subs_water_total subs_food_total subs_agric_total subs_other_total subsidy_elec_direct subsidy_elec_indirect subsidy_fuel_direct subsidy_fuel_indirect subsidy_water_direct subsidy_water_indirect subsidy_food_direct subsidy_food_indirect subsidy_agric_direct subsidy_agric_indirect ///
section5_5 indtax_total VAT_total excise_fuel excise_other CD_total other_indirect VAT_direct VAT_indirect excise_fuel_direct excise_fuel_indirect excise_other_direct excise_other_indirect CD_direct CD_indirect ///
section5_6 education_inKind education_pre_and_prim education_preprimary education_primary education_secondary education_tertiary education_psnt education_copay ///
section5_7 health_inKind health_contr health_non_contr health_hospital health_prim health_inpatient health_outpatient health_copay


*---------------------------------------------------------------
**# 1. Check that the dataset contains exactly the expected variables
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

di as result "Variable structure check passed: all expected variables are present and extra variables were removed if needed."
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