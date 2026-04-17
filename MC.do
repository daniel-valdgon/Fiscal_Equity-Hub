*===============================================================================
*---> D. Distributional indicators Gini, Theil, and FGT measures
		*Generate Income Concepts for Marginal Contribution
*===============================================================================

u `output', clear
		

*---> D.1 List of all new marginal contributinos store in income
    local income2 ""

    local aux1 `tax' `indtax'
foreach var of local aux1{
	replace `var' = -`var'
	replace `var'_pc = -`var'_pc
}

    local aux2 `tax' `indtax' `transfer' `Subsidies' `inkind'
foreach inc in ymp yn yd yc {   //(AGV) I'm excluding final income because it does not make sense contributing to that
   foreach var of local aux2 {
		gen `inc'_inc_`var'=`inc'_pc+`var'_pc
		local income2 `income2' `inc'_inc_`var'   // Store incomes to marignal contribution calculation
	}
}

foreach var of local aux1{
	replace `var' = -`var'
	replace `var'_pc = -`var'_pc
}

sp_groupfunction [aw=pondih], gini(`income_pc' `income2') theil(`income_pc' `income2') poverty(`income_pc' `income2') povertyline(`pline')  by(all) 


tempfile poverty
save `poverty'

*---> D.2 Creating taxonomy categories only for Poverty and inequality indicators. Mimic Taxonomy  
*---> Note, IT WILL CHANGE WHEN USING SOFTLABELS OR SO. NOW, JUST TO BEGING, HARDCODED! 
*          To become no-hardcoded, it needs to be in xls that is imported here. Centraliced principle. 
 
global codes    "yd_pc       yf_pc   ymp_pc        yc_pc    	yn_pc" 
global labels   "Disposable  Final   Pre-fiscal    Consumable	Net-market"

gen income = ""
forvalues i = 1/5 {
    local code  : word `i' of ${codes}
    local label : word `i' of ${labels}
    replace income = "`label'" if variable == "`code'"
}


global code_1  "fgt0"   
global code_2  "fgt1"   
global code_3  "gini"  
global code_4  "theil"

global label_1 "Headcount rate"
global label_2 "Poverty gap"
global label_3 "Gini index"
global label_4 "Theil index"

gen indicator=""
forvalues i = 1/4 {
    replace indicator = "${label_`i'}" if measure == "${code_`i'}"
}
drop if measure=="fgt2"

preserve
drop if income==""
tempfile povineq
save `povineq'
restore 
}


*---> D.3 Estimate marginal contributions 

* Keep only yc_pc
preserve

keep if income==""
tempfile consumable
save `consumable'

restore
* Merge with the other dataset


keep if variable == "yc_pc"

* Create compound name: measure alone if no reference, measure_reference if reference exists
gen colname = measure
replace colname = measure + "_" + reference if reference != ""

* Keep only what is needed and reshape wide
keep all variable value colname

* Reshape: one row per all+variable, one column per measure_reference
reshape wide value, i(all variable) j(colname) string

* Remove the "value" prefix added by reshape
foreach var of varlist value* {
    local newname = subinstr("`var'", "value", "", 1)
    rename `var' `newname'
}
drop variable
merge 1:m all using `consumable', nogenerate

* For inequality measures (no poverty line)
foreach m in gini theil {
    gen mc_`m' = `m' - value
}

* For poverty measures loop over poverty lines using the pline local
foreach m in fgt0 fgt1 {
    foreach p of local pline {
        gen mc_`m'_`p' = `m'_`p' - value
    }
}



********************************************************************************

*---> D.2 Creating taxonomy categories only for Poverty and inequality indicators. Mimic Taxonomy  
*---> Note, IT WILL CHANGE WHEN USING SOFTLABELS OR SO. NOW, JUST TO BEGING, HARDCODED! 
*          To become no-hardcoded, it needs to be in xls that is imported here. Centraliced principle. 
 
global codes    "yd_pc       yf_pc   ymp_pc        yc_pc    	yn_pc" 
global labels   "Disposable  Final   Pre-fiscal    Consumable	Net-market"

gen income = ""
forvalues i = 1/5 {
    local code  : word `i' of ${codes}
    local label : word `i' of ${labels}
    replace income = "`label'" if variable == "`code'"
}


global code_1  "fgt0"   
global code_2  "fgt1"   
global code_3  "gini"  
global code_4  "theil"

global label_1 "Headcount rate"
global label_2 "Poverty gap"
global label_3 "Gini index"
global label_4 "Theil index"

gen indicator=""
forvalues i = 1/4 {
    replace indicator = "${label_`i'}" if measure == "${code_`i'}"
}
drop if measure=="fgt2"

preserve
drop if income==""
tempfile povineq
save `povineq'
restore 
