/*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program: GSG3 Fiscal Equity Hub - Core Database Outputs
* Author: 	Daniel VAlderrama 
* Date: 	Feb 2026
* Title: 	Generate outputs for the GSG3 Core Database
*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Note: Outputs are exported in long format to the hidden sheet all_${sheetname}.
_---------------------------------------------------------------------------------*/
Just a small change to tach Github
*===============================================================================
*---> A. Paths and Macros definition
*===============================================================================
   
   clear all
   timer clear 1
   timer on 1
   
*---> A.1 Define user paths
if "`c(username)'"=="wb419055" {
	global root     	"C:\Users\wb419055\OneDrive - WBG\GSG3\GSG Fiscal Equity - WB Group - Fiscal Equity Hub\Workspace\Data Hub"	
}

if "`c(username)'"=="wb527706" {
	global root     	"C:\Users\wb527706\OneDrive - WBG\Data Hub"	
}

*---> A.2 Define project folder paths. 
*         Input folders: Country economists will share either the microdata or
*         the core indicators, if both are shared, the code should validate the
*         consistency between them.	

	global microdata   	"${root}/01-Data/01-02-FIA_Microdata"			
	global template    	"${root}/01-Data/01-03-FIA_Core Indicators"

	global tempsim		"${root}/01-Data/3_temp_sim"
	global fia-data		"${root}/04-Products\00-FIA-Database/AFW_Sim_tool_Output.csv"
	global dataout       "${root}/03-Outputs\01-Cleaned-FIA-Indicators\01-Cleaned-FIA-Indicators"
	global metadata       "${root}/01-Data/00-Aux"
	
*---> A.3 Macros for policies and income concepts values 

		
	local Directaxes 		"${Directaxes}"
	local Contributions 	"${Contributions}" 
	local DirectTransfers   "${DirectTransfers}"
	local Subsidies         "${Subsidies}"
	local Indtaxes 			"${Indtaxes}"
	local InKindTransfers	"${InKindTransfers}" 

	local tax dirtax_total sscontribs_total `Directaxes' `Contributions' 
	local indtax indtax_total `Indtaxes' Tax_VAT
	local inkind inktransf_total `InKindTransfers' education_inKind
	local transfer dirtransf_total `DirectTransfers' 
	local Subsidies subsidy_total `Subsidies' subsidy_elec subsidy_fuel subsidy_water
	local income ymp yn yd yc yf 
	local concs `tax' `indtax' `transfer' `inkind' `income' `Subsidies'
	

*---> A.4 Macros at per-capita values 
	foreach x in tax indtax inkind transfer income concs Subsidies {
		local `x'_pc
		foreach y of local `x' {
			local `x'_pc ``x'_pc' `y'_pc 	
		}
	}
*---> A.5 Other macros. Poverty lines  
	local pline zref line_1 line_2 line_3
	
*---> A.6 Other macros. Taxonomy equivalence 
	
gl taxonomy_components context indicator instrument income reference 
foreach j of global taxonomy_components  {
	
	import excel "$metadata\correlative.xlsx", sheet("`j'") firstrow clear
	drop if  `j' ==""
	tempfile `j'
	save ``j''
}


*============================================================================*
*--->	B. Detecting microdata 
*============================================================================*

* This code explore all subfolders available within each folder and search foll
* all dta files in there. It create asserts that the dta files have the same naming
* structure namely. It saves a global that 

*---> B.1 Identify each dataset 
global n_datasets 0

local dirs1 : dir `"${microdata}"' dirs "*"

foreach subf of local dirs1 {
    local cty : di strupper("`subf'")
    local cty_path `"${microdata}/`subf'"'
    local cty_count 0
    local dirs2 : dir `"`cty_path'"' dirs "*"

    foreach subf2 of local dirs2 {
        local cty_proj_path `"`cty_path'/`subf2'"'

        * 2nd level: GMB/MRT-type
        local files2 : dir `"`cty_proj_path'"' files "*.dta"
        foreach f of local files2 {
            local f_upper : di strupper("`f'")
            local cty_count = `cty_count' + 1
            global n_datasets = ${n_datasets} + 1
            global path_${n_datasets} `"`cty_proj_path'/`f_upper'"'
            global cty_${n_datasets} "`cty'_`cty_count'"
        }

        * 3rd level: SEN-type
        local dirs3 : dir `"`cty_proj_path'"' dirs "*"
        foreach subf3 of local dirs3 {
            local cty_final_path `"`cty_proj_path'/`subf3'"'
            local files3 : dir `"`cty_final_path'"' files "*.dta"
            foreach f of local files3 {
                local f_upper : di strupper("`f'")
                local cty_count = `cty_count' + 1
                global n_datasets = ${n_datasets} + 1
                global path_${n_datasets} `"`cty_final_path'/`f_upper'"'
                global cty_${n_datasets} "`cty'_`cty_count'"
				global fname_${n_datasets} "`f_upper'"
            }
        }
    }
}

* Loop over each dataset
*---> B.2 Open microdata and create deciles/centiles 

forvalues i = 1/$n_datasets {
    global sheetname "${cty_`i'}"
	global datasetname "${fname_`i'}"
    di "Processing: ${path_`i'} - Sheet: ${sheetname}"
    use `"${path_`i'}"', clear

	cap drop *deciles_pc *centile_pc
	
	foreach y in ymp yd { 
	quantiles `y'_pc  [w=pondih], gen(`y'_deciles_pc ) nq(10) 
	quantiles `y'_pc  [w=pondih], gen(`y'_centile_pc) nq(100) 
	} 
	
	tempfile output
	
	save `output'

	* Note on deciles: Deciles are created in the code using xtile Stata Natural
	*      comand (currently). This variable is not requested by PE. Both commands 
	*      are sligthly different. _ebin incldue the boundary observation above 
	*      the threshold (one observation in our datasets, up to 66 in the largest 
	*      case (Colombia).

*===============================================================================
*---> C. Netcash Position for ymp and yd.
*        Generating incidence (relative) by decil (pre-fiscal and disposable)
*===============================================================================

*---> C.1 Estimate indicators
foreach y in ymp yd {
	
	u `output', clear	
	keep hhid `concs_pc' pondih *_centile_pc *_deciles_pc 

foreach x in `tax' `indtax'  {
	gen share_`x'_pc= -`x'_pc/ `y'_pc
	}		
	
	foreach x in `transfer' `inkind' `Subsidies' {
		gen share_`x'_pc= `x'_pc/ `y'_pc
	}
		
	keep *_deciles_pc share* pondih	
		
	groupfunction [aw=pondih], mean (share*) by(`y'_deciles_pc) norestore
	
	reshape long share_, i(`y'_deciles_pc) j(variable) string
		gen measure = "netcash_`y'" 
		rename share_ value
		
	ren `y'_deciles_pc deciles_pc
	
*---> C.2 Generate decomposition by taxonomy items (3 levels)
	gen indicator ="incidence" 
	gen income="`y'"
	gen instrument=variable
	tempfile netcash_`y'
	save `netcash_`y''

}


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

*---> D.2 Generate decomposition by taxonomy items (4 levels)

g indicator=measure
tempfile poverty

*NOTE, WE EXCLUDE FOR NOW INDICATORS THAT ALLOW US TO ESTIMATE MARGINAL CONTRIBUTION

global codes    "yd_pc yf_pc ymp_pc yc_pc yn_pc" 

gen income = ""
forvalues i = 1/5 {
    local code  : word `i' of ${codes}
    replace income = "`code'" if variable == "`code'"
}


drop if income ==""
save `poverty'

* D2 DROPED 
*---> D.3 Estimate marginal contributions.  

* Indicator pending 

*===============================================================================
*---> E.  benefits, coverage beneficiaries
*===============================================================================
	*NOTE> Functional for ymp, all is not needed in Taxonomy framework
*---> E.1 benefits, coverage beneficiaries by all. Is not needed now. 
/*
u `output', clear


	sp_groupfunction [aw=pondih], benefits(`concs_pc') mean(`concs_pc') coverage(`concs_pc') beneficiaries(`concs_pc')  by(all)
	gen deciles_pc=0
	g indicator=measure
	tempfile theall
	save `theall'
*/

*---> E.2 benefits, coverage beneficiaries by deciles (ymp)	
u `output', clear

	sp_groupfunction [aw=pondih], benefits(`concs_pc') mean(`concs_pc') coverage(`concs_pc') beneficiaries(`concs_pc')  by(ymp_deciles_pc)
	ren ymp_deciles_pc deciles_pc
   	g indicator=measure
	
	global codes    "yd_pc yf_pc ymp_pc yc_pc yn_pc" 

	gen income = ""
	forvalues i = 1/5 {
    local code  : word `i' of ${codes}
    replace income = "`code'" if variable == "`code'"
}
*---> E.3 Generate decomposition by taxonomy items (3 levels)

	*In coverage income variables does not have any sense. We drop it 
	drop if  indicator=="coverage" &  income!=""
	* Mean for each instrument or policy is nor asked. We drop it
	drop if indicator=="mean" &  income == ""
	*Beneficiaries is not asked. We drop it
	drop if  indicator=="beneficiaries" 
	*NOTE. With benefits we estimate concentration shares. For now, it is ignored. 
		drop if  indicator=="benefits" 
	* Creating instrument variable	
	g instrument=variable if  income == ""
	
	tempfile theall_ymp
	save `theall_ymp'




*===============================================================================
*---> E.  concentrations coeficients and kakwani index. To be included 
*===============================================================================

*===============================================================================
*---> F. Exporing finaldatasets
*===============================================================================	
*---> F.1 adding previous ones and generating aux output 

    u `theall_ymp', clear
	append using `poverty'
	append using `netcash_ymp'
	*append using `theall'	
		
	gen concat = variable +"_"+ measure+"_" +reference+"_ymp_"+string(deciles_pc)
	order concat, first
	
	tempfile aux1
	save `aux1'
	
	drop if indicator=="fgt2"
	g context="equity"

*===============================================================================
*---> G.  Taxonomy  Unique ID
*===============================================================================	
	
*---> G.2 merging taxonomy 

  foreach j of global taxonomy_components  {
	

	merge m:m `j' using ``j''  
	drop if _merge==2
	drop _merge
}

*---> G.3 cleaning final dataset and generating unique ID (symetric) 

    order value id*	
	
	  foreach id in id_context id_indicator id_BIID id_income id_pline {
	  	
		tostring  `id', replace 
		replace `id'="99" if `id'==""
		replace `id'="99" if `id'=="."

		
	  } 
	
	tostring deciles_pc, replace 
    replace deciles_pc="99" if deciles_pc=="."
	
	
	gen UniqueID_s = id_context +"_"+ id_indicator+"_" +id_BIID+"_"+id_pline+"_"+deciles_pc
	

	*u `theall_yd', clear 
	*append using `netcash_yd'
	
	*gen concat = variable +"_"+ measure+"_"+"_yd_"+string(deciles_pc)
	*order concat, first
	
	*append using `aux1'
	

	gen dataset = "${datasetname}"

	order dataset UniqueID_s concat value TYPE INDICATOR BUDGETLINEITEM INCOMECONCEPT POVERTYLINE
	keep dataset UniqueID_s concat value TYPE INDICATOR BUDGETLINEITEM INCOMECONCEPT POVERTYLINE
	
	export excel "$dataout", sheet("all${sheetname}") sheetreplace first(variable)
	
*	tempfile all_${sheetname}
	
*	global tmppath_`i' `"`all_${sheetname}'"'
*	save `all_${sheetname}'
}








*===============================================================================
*---> H.  Cross-country dataset 
*===============================================================================

import excel using "$dataout", describe
local sheets `r(sheets)'

* Loop and append
local first 1
foreach sheet of local sheets {
    if `first' {
        import excel using "$dataout", sheet("`sheet'") firstrow clear
        gen sheet = "`sheet'"
        local first 0
    }
    else {
        tempfile tmp
        save `tmp'
        import excel using "$dataout", sheet("`sheet'") firstrow clear
        gen sheet = "`sheet'"
        append using `tmp'
    }
}

/*

* Append all datasets into one
use `"${tmppath_1}"', clear
forvalues i = 2/$n_datasets {
    append using `"${tmppath_`i'}"'
}
*/

*===============================================================================
*---> Unique ID from Taxonomy.  
*===============================================================================

	import excel "$metadata\IndicatorsDatabase_v1.xlsx", sheet("INDICATORS") firstrow clear


	order Indicatortypecode Indicatorcode Categorycode Instrumentcode Incomecode Povertylinecode
	
	foreach k in Categorycode Indicatorcode Incomecode Povertylinecode {
		
		replace `k'=99 if `k'==.
		tostring `k' , replace 
	}
	
		gen UniqueID_s = Indicatortypecode +"_"+ Indicatorcode+"_" +Categorycode+"_"+Instrumentcode+"_"+Incomecode +"_"+Povertylinecode

		
		Indicatortypecode Indicatorcode Categorycode Instrumentcode Incomecode Povertylinecode
	
	 
	*---Ceck double __
	
	*Create System for statistic of indocator coverage 
timer off 1
timer list 1










