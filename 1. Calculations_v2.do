/*------------------------------------------------------------------------------
*-------------------------------------------------------------------------------
* Program: GSG3 Fiscal Equity Hub - Core Database Outputs
* Author: 	Daniel VAlderrama and Juan Manuel Monroy
* Date: 	Feb 2026
* Title: 	Generate outputs for the GSG3 Core Database
*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------
* Note: Outputs are exported in long format to the hidden sheet all_${sheetname}.
---------------------------------------------------------------------------------*/

*===============================================================================
*---> A. Paths and Macros definition
*===============================================================================
   
   clear all
   timer clear 1
   timer on 1
   
*---> A.1 Paths are defined once in revamp trunk
if "$root"=="" {
	di as err "Missing required global root. Define it in 00-Trunk_Revamp.do."
	exit 198
}

if "$scripts"=="" {
	global scripts "${root}/02-Scripts/wb419055"
}

else if "`c(username)'"=="wb527706" {
	global root     	"C:\Users\wb527706\OneDrive - WBG\GSG Fiscal Equity - WB Group - Data-Hub"	
}

else if "`c(username)'"=="wb527706" {
	global scripts "${root}/02-Scripts/wb527706"
}
*---> A.2 Define project folder paths. 
*         Input folders: Country economists will share either the microdata or
*         the core indicators, if both are shared, the code should validate the
*         consistency between them.	

	global microdata   	"${root}/01-Data/01-02-FIA_Microdata"			
	global template    	"${root}/01-Data/01-03-FIA_Core Indicators"

	global fia-data		"${root}/04-Products\00-FIA-Database/AFW_Sim_tool_Output.csv"
	global dataout       "${root}/03-Outputs\01-Cleaned-FIA-Indicators"
	global metadata       "${root}/01-Data/00-Aux"
	global dataaux        "${root}/01-Data/00-Aux/temp"

	local dirfiles: dir "$scripts/_ado/" files "*.ado"
	
	foreach ado of local dirfiles {
		run "$scripts/_ado/`ado'"
	}
	

*---> A.3 Macros for policies and income concepts values 
*         Note: new code added. 


			

		foreach t in context indicator category income povertyline partition pension {
		
		import excel "$metadata\correlative_4.xlsx", sheet("`t'") firstrow clear
		drop if `t'==""
    	tempfile `t'
		save ``t''
	}
	

	import excel "$metadata\correlative_4.xlsx", sheet("instrument") firstrow clear

	tempfile correlative
	save `correlative'
    foreach i in Directaxes Contributions DirectTransfers Subsidies Indtaxes InKindTransfers {
	
    levelsof instrument if type == "`i'", local(`i') clean
	dis "`i'"
	 
}
	local taxes `Directaxes' `Indtaxes' `Contributions'
	local spending `InKindTransfers' `DirectTransfers' `Subsidies'


	local income_concepts ym_inat_pov_2021 ym_nat_pov yp_inat_pov_2021 yp_nat_pov yn_inat_pov_2021 yn_nat_pov yd_inat_pov_2021 yd_nat_pov yc_inat_pov_2021 yc_nat_pov yf_inat_pov_2021 yf_nat_pov //hardcoded
	
	local concs `Directaxes' `Contributions' `Indtaxes' `DirectTransfers' `Subsidies' `InKindTransfers' `income_concepts' 
	
*---> A.4 Converting all macros into percapita values 
	foreach x in Directaxes Indtaxes InKindTransfers DirectTransfers Subsidies income_concepts concs  {
		local `x'_pc
		foreach y of local `x' {
			local `x'_pc ``x'_pc' `y'_pc 	
		}
		dis  `"list of `x' : ``x'_pc'"'
	}
	

*---> A.5 Other macros. Poverty lines  

	local pline line_nat line_li21 line_lm21 line_um21
	local npline line_nat 
	local ipline line_li21 line_lm21 line_um21
	
*---> A.6 Other macros. Taxonomy equivalence 
	
gl taxonomy_components context indicator category instrument income povertyline partition pension 
foreach j of global taxonomy_components  {
	
	import excel "$metadata\correlative_4.xlsx", sheet("`j'") firstrow clear
	drop if  `j' ==""
	*tempfile `j'
	*save ``j'', replace 
	save "$dataaux/dict_`j'.dta", replace

}




*============================================================================*
*--->	B. Core dataset selection (single-country mode) delete in fron of Daniel ABCD
*============================================================================*

* This file runs one country/dataset per execution.
* The trunk should set:
*   - $core_dataset_path
*   - $core_dataset_name (optional)
*   - $core_country (optional ISO3)
/*

if "$core_dataset_path"=="" {
	di as err "Missing required global: core_dataset_path"
	exit 198
}
*/
/*capture confirm file "$core_dataset_path"
if _rc {
	di as err "core_dataset_path not found: $core_dataset_path"
	exit 601
}

if "$core_dataset_name"=="" {
	local _name = subinstr("$core_dataset_path", "\\", "/", .)
	local _name = reverse(word(reverse("`_name'"),1,"/"))
	global core_dataset_name "`_name'"
}

if "$core_country"=="" {
	global core_country = upper(substr("$core_dataset_name",1,3))
}

* Keep existing variable references by setting one-slot globals.
global n_datasets 1
global path_1 "$core_dataset_path"
global cty_1 "$core_country"
global fname_1 "$core_dataset_name"

*/


*============================================================================*
*--->	B. Core dataset selection 
*============================================================================*

global run_countries `" "ECU 2024 ENEMDU" "'
*global run_countries `" "COL 2021 GEIH" "'

foreach config of global run_countries {

global run_country "`config'"

    global country     : word 1 of $run_country
    global survey_year : word 2 of $run_country
    global survey      : word 3 of $run_country

	include "${scripts}/1-01-paths_country_cases.do"
	
    di as result "Running ${run_country}"
	di as result "---------------------------"
	sleep 3000


* Obj: This section will include protocols to revise the databases, q-check over the FIA data

* It create a dataset with information available in the datalab and save it
* It should be uploaded to Github, it should request documentation everytime is modified, it should run regular backups 

* Household database
use "$HFMD_data/${file}_h", clear

cap ren sscontribs_* ssc_* //temporal since everything is homogeneous ABCD 
   egen ssc_total = rowtotal(ssc_nopensions ssc_pensions)   , missing  //need to check with Daniel, not found ABCD
   * o_soc_ins INS_11_2_0	Instrument: Social insurance Not found need to check with Daniel ABCD

  *housing_InKind, other_InKind   not found ABCD
  * share_ym_pc_subsidy_agric_indirect  invalid name, too long need to check with Daniel ABCD
 * subsidy_elec_indirect ABCD
 ren subsidy_elec_indirect subsidy_elec_i
  ren subsidy_agric_indirect subsidy_agric_i
  ren subsidy_water_indirect subsidy_water_i
  ren subsidy_food_indirect subsidy_food_i
  ren subsidy_fuel_indirect subsidy_fuel_i
  ren excise_other_indirect excise_other_i
  ren excise_fuel_indirect excise_fuel_i
  
  ren education_* educ_*
  * education_pre_and_prim
  * education_preprimary
  * education_primary
  * education_secondary
  * education_tertiary
  * education_psnt
  * education_copay


	tempfile output
	save `output', replace 

*===============================================================================	
*------------------------------Indicators --------------------------------------
*===============================================================================

*===============================================================================
*---> C. Netcash Position for ymp and yd.
*        Generating incidence (relative) by decil (pre-fiscal and disposable)
*===============================================================================
*///---> here most of the Danie's estimates could work, other part of its code need to be debuged ABCD


*Outline, 
*Compute mean by partition

*---> C.1  define indicators (by income in incidence), partitions 
* Indicator names should have the policyname, save in the local `x', at the very end so in the reshape that is the only thing in the name
set seed 80292367

u `output', clear 
		foreach x in `Directaxes' `Contributions' `DirectTransfers' `Subsidies' `Indtaxes' `InKindTransfers' {
				gen `x'_pc=`x' /hhsize   //need to check with Daniel ABCD
		}
		
		
		
foreach y in ym yd {
					gen `y'_pc=`y' /hhsize   //need to check with Daniel ABCD

		foreach x in `Directaxes' `Contributions' `DirectTransfers' `Subsidies' `Indtaxes' `InKindTransfers' {
			
			if strpos("`taxes'", "`x'") {
				gen share_`y'_pc_`x' = - `x'_pc / `y'_pc
			}
			else if strpos("`spending'", "`x'") {	
				gen share_`y'_pc_`x' = `x'_pc / `y'_pc
			}

			gen uinc_`y'_pc_`x' = `x'_pc / `y'_pc
			gen cinc_`y'_pc_`x' = `x'_pc / `y'_pc  if (`x'_pc > 0)
			gen cov_`y'_pc_`x'  = (`x'_pc > 0)
			
		
		} // eo foreach x
}

tempfile output_quantiles
save `output_quantiles', replace 
}

*Prepare microdata : milliles and variable that allowed that means compute them 

	foreach y in ym yd {

		u `output_quantiles', clear	
		
		keep `y'_pvpc `y'_pvdc share_`y'* uinc_`y'* cinc_`y'* cov_`y'*  hhweight	

		* --- Single pass: millile-level weighted means (only full-data operation) ---
		*groupfunction [aw=pondih], mean(share_`y'* uinc_`y'* cinc_`y'* cov_`y'*) sum(abs_`y'* pondih) by(`y'_millile_pc)
		* Derive centile/decile from millile (guaranteed perfect nesting, to test later formally and wrote it @jmmonroyb)
		*gen `y'_centile_pc = ceil(`y'_millile_pc / 10)
		*gen `y'_decile_pc  = ceil(`y'_millile_pc / 100)
		*gen _wt = 1  // equal weight per millile (each has ~same pop by construction)

		* Store millile-wide data in frame (1000 rows, for centile/decile derivation)
		cap frame drop fr_wide
		frame copy default fr_wide, replace

		* --- Loop over each indicator: reshape to long at 3 levels ---
		foreach indicator in share uinc cinc cov  {

		* --- Decile level (work inside a copy frame, no touch on default) ---
		
			cap frame drop fr_dec
			frame copy fr_wide fr_dec
			frame fr_dec {
				drop  `y'_pvpc
				groupfunction [aw=hhweight], mean(`indicator'*) by(`y'_pvdc)
				reshape long `indicator'_`y'_pc_, i(`y'_pvdc) j(variable) string
				tostring `y'_pvdc, gen(partition) format(%04.0f)
					replace partition = "pv_dc_" + partition
					drop `y'_pvdc
				rename `indicator'_ value
			}
		
		* --- Centile level (work inside a copy frame) ---
			cap frame drop fr_cent
			frame copy fr_wide fr_cent
			frame fr_cent {
				drop  `y'_pvdc
				groupfunction [aw=hhweight], mean(`indicator'*) by(`y'_pvpc)
				reshape long `indicator'_`y'_pc_, i(`y'_pvpc) j(variable) string
				tostring `y'_pvpc, gen(partition) format(%04.0f)
					replace partition = "pv_pc_" + partition
					drop `y'_pvpc
				rename `indicator'_ value
			}


			
		* --- Combine all three levels into default ---
			tempfile _tf_dec _tf_cent 
			frame fr_dec:  save `_tf_dec'
			frame fr_cent: save `_tf_cent'
			
			use `_tf_dec', clear
			append using `_tf_cent'
			*cap frame drop fr_dec fr_cent fr_mill


*---> C.2 Generate decomposition by taxonomy items (3 levels)
* Stop here ABCD to check with Daniel the best way to call dataframes and link to identification variables 
			
			gen indicator = "`indicator'"
			gen income = "`y'"
			rename variable instrument
			gen category = "CAT_NA"
			gen povertyline = "PL_NONE_N"
			gen pension = "pdi"
			gen country= "$country"
			gen dataset = "$survey"

			order indicator category instrument income povertyline partition pension country dataset value
			save "$dataaux/`indicator'_`y'", replace

		}	  // eo foreach indicator
		
		* Drop fr_wide after all indicators are done for this y
		cap frame drop fr_wide

	} // eo foreach y

	
	
 // eo foreach dataset

*---> C.3 Compiling and saving data 
foreach indicator in share uinc cinc cov  {
	foreach y in ym yd {
		local i = 1
		use "$dataaux/`indicator'_`y'", clear
		
		if "`y'"=="ym" & "`indicator'"=="share" {
			save "$dataaux/final_dist.dta", replace
		}
		else {
			append using "$dataaux/final_dist.dta"
			save "$dataaux/final_dist.dta", replace

			isid indicator category instrument income povertyline partition pension country dataset, sort
		}
	} // eo foreach y
} // eo foreach indicator


*---> Note: debuged until here. ABCD

*===============================================================================
*---> D. Distributional indicators International values Gini, Theil, and FGT measures
		*Generate Income Concepts for Marginal Contribution
*===============================================================================

*---> For now, out of the global loop
	/*
use "$HFMD_data/${file}_h", clear

	*temporal changes to the data
	rename zref line_nat 
	
	g line_li21 = 3
	g line_lm21 = 4.2
	g line_um21 = 8.3

	tempfile output
	save `output', replace


*---> D.1 List of all new marginal contributinos store in income
    local income2 "" // list with all counterfactual vectors  

	*Separating list of taxes from transfers: Final income concept always substract taxes and add up taxes (for now we keep it as it is to double check but it needs to be change)
	foreach policy of local taxes {
		replace `policy'_pc = -`policy'_pc
		cap assert (`policy'_pc >= 0 | `policy'_pc==.) // in the meantime not calculated on the basis of the final income concept 
	}

	*Computing vectors of marginal contributions, all computed with respect market income and consumable income
    local aux2 `tax' `indtax' `transfer' `Subsidies' `inkind'
	foreach inc in yd yc yf {
		   
   		foreach policy of local aux2 {
			
			
			gen `inc'_inc_`policy'=`inc'_pc-`policy'_pc // when missing the policy we want missing the counterfactual income  
			local income2 `income2' `inc'_inc_`policy'   // Store incomes to marignal contribution calculation
		}
	}

	*Turning back taxes (Spending later to positive values)
	foreach policy of local aux1 {
		replace `policy'_pc = -`policy'_pc
		cap assert (`policy'_pc >= 0 | `policy'_pc==.)
	}

	*1. Computing poverty levels 
	dis " ${fname_`i'} - List of counterfactual income concepts: `income2' "
	sp_groupfunction [aw=pondih], gini(`income_concepts_pc' `income2') theil(`income_concepts_pc' `income2') poverty(`income_concepts_pc' `income2') povertyline(`pline')  by(all) 
	gen value_level = value
	
	*2. Computing marginal contributions
	ren variable long_variable
	ren measure indicator
	gen income_concept = substr(long_variable,1,2)
	gen policy = substr(long_variable, 8, .)
	replace reference ="PL_NONE_N" if indicator == "gini" | indicator == "theil"
	replace reference = upper(reference) 
	
	gen aux_end_y=value if ( income_concept+"_pc"==long_variable)
	bysort indicator income_concept reference (value): egen sd=sd(aux_end_y) 
	bysort indicator income_concept reference (value): egen end_y=mean(aux_end_y) 

	assert end_y!=. & sd==.
	gen value_mc = (value - end_y) 
	

	*3.Computing total impact 
	foreach inc in ym yd yc yf {
		gen aux_`inc'_lvl=end_y if income_concept=="`inc'"
		bysort indicator reference: egen `inc'_lvl=mean(aux_`inc'_lvl) 
		bysort indicator reference: egen sd_`inc'_lvl=sd(aux_`inc'_lvl)
		assert `inc'_lvl!=. 
		assert sd_`inc'_lvl==0 | sd_`inc'_lvl==.

	}

	*Eliminating the calculation of total impact to have only one indicator (trick: using ym)
	gen value_totimp = ym_lvl - yc_lvl if inlist(indicator,"fgt0", "fgt1", "fgt2") & income_concept=="ym"
	replace value_totimp = ym_lvl - yf_lvl if inlist(indicator,"gini", "theil") & income_concept=="ym"

	
	*Eliminating MC that does not make sense
	foreach policy in  `indtax' `Subsidies'   {
		replace value_mc=. if policy=="`policy'" &  inlist(income_concept, "yd") // all indirect taxes, subssidies and inkind with disposable income
	}

	foreach policy in  `inkind'  {
		replace value_mc=. if policy=="`policy'" &  inlist(income_concept, "yd", "yc" ) // all contribution of inkind with consumable income 
		replace value_mc=. if inlist(indicator, "fgt0", "fgt1", "fgt2") & inlist(income_concept, "yf") // all mc to poverty with final income
	}

	assert abs(value_mc)<0.0001 | value_mc==. if income_concept+"_pc"==long_variable
	replace value_mc=. if ( income_concept+"_pc"==long_variable) // marginal contributions of income concepts  

	*Eliminating levels that are not useful now: all policy counterfactuals 
	replace value_level=. if ( income_concept+"_pc"!=long_variable)


	
*---> D.2 Generate decomposition by taxonomy items (4 levels)
*NOTE, WE EXCLUDE FOR NOW INDICATORS THAT ALLOW US TO ESTIMATE MARGINAL CONTRIBUTION

*indicator, income were defined above 		
gen category = "CAT_NA"
rename policy instrument
replace instrument = "INS_NA_N_N" if instrument=="" | instrument==" " & inlist(long_variable,"ym_pc", "yn_pc", "yd_pc", "yc_pc", "yf_pc")

rename income_concept income
rename reference povertyline
replace povertyline = "PL_NONE_N" if inlist(indicator, "gini", "theil")
gen partition = "PV_NA_NONE"
gen pension = "pdi"
gen country= substr("${fname_`i'}", 1, 3)
gen dataset = "${fname_`i'}"


replace instrument = "INS_NA_N_N" if instrument=="" | instrument==" " & country=="ECU" // @jmmonroyb, thre is a weird reason why the conditional of line 452 is not working,so I am making an exception here, please check  "replace instrument = "INS_NA_N_N" if instrumen  ..."  

save "$dataaux/pov_ineq_debug_`i'.dta", replace 

drop _population long_variable  value sd aux_* end_y all ym_lvl sd_ym_lvl yd_lvl sd_yd_lvl yc_lvl sd_yc_lvl yf_lvl sd_yf_lvl

reshape long value_, i(indicator category instrument income povertyline partition pension country dataset) j(indicator2) string

drop if value_==.
ren (indicator indicator2) (aux_indicator indicator )

*Marginal contributions only for headcount and Gini 
replace indicator ="mcp" if indicator=="mc" & inlist(aux_indicator,"fgt0")
replace indicator ="mci" if indicator=="mc" & inlist(aux_indicator,"gini") 
drop if indicator=="mc" & inlist(aux_indicator,"theil", "fgt1", "fgt2") 

*Total change in poverty and Gini 
replace income="INC_NA" if indicator=="totimp"
replace indicator ="tpi" if indicator=="totimp" & inlist(aux_indicator,"fgt0")
replace indicator ="tri" if indicator=="totimp" & inlist(aux_indicator,"gini")
drop if indicator=="totimp" & inlist(aux_indicator,"theil", "fgt1", "fgt2")

*Level for gap, theil, heacoung and gap 
replace indicator ="hcr" if indicator=="level" & inlist(aux_indicator,"fgt0")
replace indicator ="gni" if indicator=="level" & inlist(aux_indicator,"gini" )
replace indicator ="thi" if indicator=="level" & inlist(aux_indicator,"theil" )
replace indicator ="pgp" if indicator=="level" & inlist(aux_indicator,"fgt1" )
drop if aux_indicator=="fgt2" & indicator=="level"
*temporary drop to be deleted after Pecchi includes fgt1 and fgt2 in the taxonomy
drop aux_indicator
ren value_ value

order indicator category instrument income povertyline partition pension country dataset value
save "$dataaux/pov_ineq_`i'.dta", replace

}

*---> D.3 Compiling and saving data

local i = 1
use "$dataaux/pov_ineq_`i'.dta", clear
save "$dataaux/final_pov_ineq.dta", replace


*/

*---> new two indicators added here 
*===============================================================================
*---> E.  kakwani index.
*===============================================================================

*---> Note: For now, only on the global loop
	
*---> E.1 Preparing main output database 
	local rank ym_nat_pov
		
	u `output', clear 

			foreach x in `Directaxes' `Contributions' `DirectTransfers' `Subsidies' `Indtaxes' `InKindTransfers'  {
			
				gen `x'_pc= - `x'/ hhsize
			}
			
			foreach x in `income_concepts' {
				ren `x' `x'_pc 
				
			}
			
	rename zref line_nat 
 	g line_li21 = 3
	g line_lm21 = 4.2
	g line_um21 = 8.3
	
	tempfile output_a
	save `output_a'

	
*---> E.2 groupfunction for concentration_coefficient taking main dofile	

	foreach x of local concs_pc{
		covconc `x' [aw=hhweight] , rank(`rank')	//gini and concentration coefficients
		local _`x' = r(conc)
		}
	
	groupfunction [aw=hhweight], sum(`concs_pc') by(ym_pvpc) norestore
		qui count
		local _1 =r(N)
		local nnn=`_1'+ 1  //add one more obs, the total obs goes from 100 to 101
		set obs `nnn'
		replace ym_pvpc = 0 in `nnn'
	
		sort ym_pvpc
		putmata x = (`concs_pc') if ym_pvpc!=0, replace 
		mata: x = J(1,cols(x),0) \ x  //generate a constant row, add to the top
		mata: x = x:/quadcolsum(x)  //divide each element by the column total
		mata: for(i=1; i<=cols(x);i++) x[.,i] = quadrunningsum(x[.,i])  //replace exisiting matrix by new elements
		
		getmata (`concs_pc') = x, replace
		
		qui count
		local _1 =r(N)
		local nnn=`_1'+ 1 //add one more obs, the total obs goes to 102
		set obs `nnn'
		
		replace ym_pvpc = 999 in `nnn'
		foreach x of local concs_pc{
			replace `x' = `_`x'' in `nnn'  //replace the last observation with gini/concentration coefficient
		}	
	order ym_pvpc, first
	
	tempfile concentration
	save `concentration'
*---> E.3 Prepare dataset for Kakwani 	
	keep if ym_pvpc==999
	ds
	local vars `r(varlist)'
	dis
	
	foreach v of local vars {
		    local val_`v' = `v'[1]

	}

	clear
	set obs `=wordcount("`vars'")'
	g varname = ""
	g value   = .

		local i = 1
			foreach v of local vars {
				replace varname = "`v'"      in `i'
				replace value   = `val_`v'' in `i'
			local ++i
		}
*---> E.4 Discuss with Daniel reference ABCD ym_inat_pov_2021_pc? and method 

	sum value if varname=="ym_inat_pov_2021_pc"
	g reference=`r(mean)'

	g instrument = substr(varname, 1, length(varname) - 3)

	merge 1:1 instrument using `correlative'


    g kakwani= -value + reference 
	replace kakwani= value - reference if type=="Directaxes" |  type=="Indtaxes" |  type=="Contributions"

*---> E.5 Preparing clean dataset

	
	g indicator="kakw"
	g country="$country"
	g survey="$survey"
	g dataset="${file}"
	g category="CAT_NA"
	drop if INSTRUMENT_ID==""
	
	g income="ym" //given ym_inat_pov_2021_pc
	g povertyline="PL_NONE_N"
	g partition="PV_NA_NONE"
	g pension="pdi"
	g context="equity"
	drop value
	ren kakwani value 
	
	drop _merge 
		foreach t in context indicator category income povertyline partition pension {
				merge m:1 `t' using ``t''
				keep if _merge==3
				drop _merge 
		}
	
	gl toreport ID_CONTEXT INDICATOR_ID CATEGORY_ID INSTRUMENT_ID INCOME_ID POVERTY_LINE_ID PARTITION_VALUE_ID PENSION_ID country dataset country value  	    
	order $toreport 
	keep $toreport

	tempfile kakwani
	save `kakwani'
	

*===============================================================================
*---> F.  Marginal contribution
*===============================================================================	
*---> F.1 Using standard approach 
 
	use `output_a', clear
	
	gen all = 1

	local aux `Directaxes' `Indtaxes'  `Contributions' 
		foreach var of local aux {
	
			gen inc_`var'=ym_nat_pov_pc-`var'_pc
			local income2 `income2' inc_`var'   // Store incomes to marignal contribution calculation
	
		}
	local auxII `InKindTransfers' `DirectTransfers'  `Subsidies'
		foreach var of local auxII {
	
			gen inc_`var'=ym_nat_pov_pc+`var'_pc
			local income2 `income2' inc_`var' // Store incomes to marignal contribution calculation
		}

	
	sp_groupfunction [aw=hhweight], gini(`income_concepts_pc' `income2')  poverty(`income_concepts_pc' `income2') povertyline(`pline')  by(all) 

*---> F.2 Estimate marginal distributions by income reference
	g mc_d=.
	g mc_m=.

	foreach t in gini fgt0 {
		sum value if variable=="yd_nat_pov_pc" & measure=="`t'" 
		replace mc_d=r(mean)-value if measure=="`t'"
		sum value if variable=="ym_nat_pov_pc" & measure=="`t'" 
			replace mc_m=r(mean)-value if measure=="`t'" 
	}

		
	foreach t in local `income_concepts_pc'{
	drop if variable=="`income_concepts_pc'"
	}
	
	drop if measure=="fgt1" | measure=="fgt2"

*---> F.3 Preparing clean dataset

	drop value _population

	g country="$country"
	g survey="$survey"
	g dataset="${file}"
	g category="CAT_NA"

	g indicator="mci" if measure=="gini" 
	replace indicator="mcp" if measure=="fgt0" 
	
	g instrument = substr(variable, 5, length(variable) - 3)
	g aux = substr(variable, 1, 1)
	drop if aux=="y"
	drop aux

	merge m:1 instrument using `correlative'
	
	keep if _merge==3 
	drop _merge
	
	preserve 
	drop mc_m
	g income="yd"
	ren mc_d value
		tempfile aux
		save `aux'
	restore 
	
	g income="ym"
	drop mc_d
	ren mc_m value 
	
	append using `aux'

	
	drop if INSTRUMENT_ID==""
	
	ren reference povertyline
	replace povertyline="PL_NONE_N" if povertyline==""
	g partition="PV_NA_NONE"
	g pension="pdi"
	g context="equity"

		foreach t in context indicator category income povertyline partition pension {
				merge m:1 `t' using ``t''
				keep if _merge==3
				drop _merge 
		}
	
	order $toreport 
	keep $toreport	
	
		tempfile marginal_contrib
		save `marginal_contrib'
	
	}
		
		
		
		
/*


*===============================================================================
*---> Z. Exporing finaldatasets | Taxonomy  Unique ID
*===============================================================================	
*---> Z.1 adding previous ones and generating aux output 

    u "$dataaux/final_dist.dta" , clear
	append using "$dataaux\final_pov_ineq"
	
	*Temporal indicators dropped until Pecchi add them 
	drop if indicator=="share" | indicator=="mean"
	drop if instrument=="inktransf_total"

	*Adding up dictionary names (softcoded)
	merge m:1 indicator using "$dataaux\dict_indicator.dta", keepusing(INDICATOR_ID) assert(match using) keep(match) nogen
	
	merge m:1 category using "$dataaux\dict_category.dta", keepusing(CATEGORY_ID) assert(match using) keep(match) nogen
	
	merge m:1 instrument using "$dataaux\dict_instrument.dta", keepusing(INSTRUMENT_ID) assert(match using) keep(match) nogen
		
	merge m:1 income using "$dataaux\dict_income.dta", keepusing(INCOME_ID)  assert(match using) keep(match) nogen
	
	merge m:1 povertyline using "$dataaux\dict_povertyline.dta", keepusing(POVERTY_LINE_ID) assert(match using) keep(match) nogen

	merge m:1 partition using "$dataaux\dict_partition.dta", keepusing(PARTITION_VALUE_ID) assert(match using) keep(match) nogen

	merge m:1 pension using "$dataaux\dict_pension.dta", keepusing(PENSION_ID) assert(match using) keep(match) nogen
	
	keep INDICATOR_ID CATEGORY_ID INSTRUMENT_ID INCOME_ID POVERTY_LINE_ID PARTITION_VALUE_ID PENSION_ID country dataset value

	export excel using "$dataout/01-Cleaned-FIA-Indicators.dta", sheet("database_rep", replace) first(variable)  
	save "$dataout/01-Cleaned-FIA-Indicators_rep.dta", replace
	save "$dataout/01-Cleaned-FIA-Indicators_${core_country}_rep.dta", replace

	

exit 



*===============================================================================
*---> E.  concentrations coeficients and kakwani index. To be included 
*===============================================================================

/*
local j=0
forvalues i = 1/$n_datasets {
local ++j

	**************Temporal subsection to be deleted after debugging, to be included in the harmonization do-file 
	* globals to call dataset and define the spreadsheet name .
	global sheetname    "${cty_`i'}"
    global datasetname  "${fname_`i'}"
	global indivname "d_`i'" // @jmmonroyb, do we need this? 
    di "Processing: ${path_`i'} - Sheet: ${sheetname}"

    use `"${path_`i'}"', clear


	foreach y in ymp yd {
		quantiles `y'_pc [w=pondih], gen(`y'_millile_pc) nq(1000) stable
		quantiles `y'_pc [w=pondih], gen(`y'_centile_pc) nq(100) stable
		quantiles `y'_pc [w=pondih], gen(`y'_decile_pc) nq(10) stable
    }
		* Note on bins: bins are created in the code to ensure consistent construction across countries.
		*		quantiles correct (in a different way) than _ebin by ties between observations when defining the different bins. 
		*      _ebin include the boundary observation above. This implies some mmistmatches, more in larger datasets like COL (66 mistmacthces)

	tempfile output
	save `output', replace 
	
*------------------------------Indicators --------------------------------------------

*Outline, 
*Compute mean by partition

*---> C.1  define indicators (by income in incidence), partitions 
set seed 80292367
foreach y in ymp yd {
		foreach x in `tax' `indtax' `transfer' `inkind' `Subsidies' {
			
		gen newas_`y'_`x'  = `x'_pc
		
		} // eo foreach x
}

tempfile output_quantiles
save `output_quantiles', replace 


*Prepare microdata : milliles and variable that allowed that means compute them 

	foreach y in ymp yd {

		u `output_quantiles', clear	
		
		keep `y'_millile_pc `y'_centile_pc `y'_decile_pc share_`y'* uinc_`y'* cinc_`y'* cov_`y'*  pondih	


		* Store millile-wide data in frame (1000 rows, for centile/decile derivation)
		cap frame drop fr_wide
		frame copy default fr_wide, replace

		* --- Loop over each indicator: reshape to long at 3 levels ---
		foreach indicator in share uinc cinc cov  {

		* --- Decile level (work inside a copy frame, no touch on default) ---
		
			cap frame drop fr_dec
			frame copy fr_wide fr_dec
			frame fr_dec {
				drop `y'_millile_pc `y'_centile_pc
				groupfunction [aw=pondih], mean(`indicator'*) by(`y'_decile_pc)
				reshape long `indicator'_`y'_pc_, i(`y'_decile_pc) j(variable) string
				tostring `y'_decile_pc, gen(partition) format(%04.0f)
					replace partition = "pv_dc_" + partition
					drop `y'_decile_pc
				rename `indicator'_ value
			}
		
		* --- Centile level (work inside a copy frame) ---
			cap frame drop fr_cent
			frame copy fr_wide fr_cent
			frame fr_cent {
				drop `y'_millile_pc `y'_decile_pc
				groupfunction [aw=pondih], mean(`indicator'*) by(`y'_centile_pc)
				reshape long `indicator'_`y'_pc_, i(`y'_centile_pc) j(variable) string
				tostring `y'_centile_pc, gen(partition) format(%04.0f)
					replace partition = "pv_pc_" + partition
					drop `y'_centile_pc
				rename `indicator'_ value
			}

		* --- Millile level (work inside a copy frame) ---
			cap frame drop fr_mill
			frame copy fr_wide fr_mill
			frame fr_mill {
				drop `y'_centile_pc `y'_decile_pc 
				groupfunction [aw=pondih], mean(`indicator'*) by(`y'_millile_pc)
				reshape long `indicator'_`y'_pc_, i(`y'_millile_pc) j(variable) string
				save "${dataaux}/debugging.dta", replace
				tostring `y'_millile_pc, gen(partition) format(%04.0f)
					replace partition = "pv_pm_" + partition
					drop `y'_millile_pc
				rename `indicator'_ value
			}
			
		* --- Combine all three levels into default ---
			tempfile _tf_dec _tf_cent _tf_mill
			frame fr_dec:  save `_tf_dec'
			frame fr_cent: save `_tf_cent'
			frame fr_mill: save `_tf_mill'
			
			use `_tf_mill', clear
			append using `_tf_dec'
			append using `_tf_cent'
			*cap frame drop fr_dec fr_cent fr_mill


*---> C.2 Generate decomposition by taxonomy items (3 levels)
			
			gen indicator = "`indicator'"
			gen income = "`y'"
			rename variable instrument
			gen category = "CAT_NA"
			gen povertyline = "PL_NONE_N"
			gen pension = "pdi"
			gen country= substr("${fname_`i'}", 1, 3)
			gen dataset = "${fname_`i'}"

			order indicator category instrument income povertyline partition pension country dataset value
			save "$dataaux/`indicator'_`y'_`i'", replace

		}	  // eo foreach indicator
		
		* Drop fr_wide after all indicators are done for this y
		cap frame drop fr_wide

	} // eo foreach y

} // eo foreach dataset

**********************
local j=0
forvalues i = 1/$n_datasets {
local ++j

	* globals to call dataset and define the spreadsheet name .
	global sheetname    "${cty_`i'}"
    global datasetname  "${fname_`i'}"
	global indivname "d_`i'" // @jmmonroyb, do we need this? 
    di "Processing: ${path_`i'} - Sheet: ${sheetname}"

    use `"${path_`i'}"', clear
	*temporal changes to the data
	rename (ymp_pc ) (ym_pc )
	rename (zref line_1 line_2 line_3) (line_nat line_li21 line_lm21 line_um21 )

	tempfile output
	save `output', replace
		
*===============================================================================
*---> E1a. Concentration Shares by Deciles (id=39)

u `output', clear

* Instruments only (exclude income concepts from concs) — deduplicated
local instruments ${tax} ${indtax} ${transfer} ${inkind} ${Subsidies}
local instruments : list uniq instruments

* Generate weighted values, then collapse
foreach x of local instruments {
	gen double w_`x' = `x'_pc * pondih
}

preserve
	collapse (sum) w_*, by(ymp_deciles_pc)
	
	foreach x of local instruments {
		qui sum w_`x'
		local tot = r(sum)
		replace w_`x' = w_`x' / `tot' if `tot' != 0
	}

	reshape long w_, i(ymp_deciles_pc) j(variable) string
	rename w_ value
	ren ymp_deciles_pc deciles_pc

	gen measure    = "concentration_share"
	gen indicator  = "concentration_share"
	gen instrument = variable
	gen income     = "ymp"
	gen context    = "equity"

	tempfile conc_shares_dec
	save `conc_shares_dec'
restore

*===============================================================================
*---> E1b. Concentration Shares by Poor & Non-Poor (id=40)
*     Same as above but by poverty status instead of decile
*===============================================================================

u `output', clear

local instruments ${tax} ${indtax} ${transfer} ${inkind} ${Subsidies}
local instruments : list uniq instruments

* Use first poverty line (zref) for poor/non-poor classification
gen byte is_poor = (ymp_pc < zref) if !missing(ymp_pc) & !missing(zref)

foreach x of local instruments {
	gen double w_`x' = `x'_pc * pondih
}

preserve
	collapse (sum) w_*, by(is_poor)
	
	foreach x of local instruments {
		qui sum w_`x'
		local tot = r(sum)
		replace w_`x' = w_`x' / `tot' if `tot' != 0
	}

	reshape long w_, i(is_poor) j(variable) string
	rename w_ value
	rename is_poor deciles_pc

	gen measure    = "concentration_share_poverty"
	gen indicator  = "concentration_share_poverty"
	gen instrument = variable
	gen income     = "ymp"
	gen context    = "equity"
	gen reference  = "zref"

	tempfile conc_shares_poor
	save `conc_shares_poor'
restore

*===============================================================================
*---> E1c. Concentration Coefficients (id=43) and Kakwani Index (id=42)
*     CC = 2*cov(X, F(Y)) / mean(X)
*     Kakwani = CC - Gini(Y)
*===============================================================================

u `output', clear

local instruments ${tax} ${indtax} ${transfer} ${inkind} ${Subsidies}
local instruments : list uniq instruments

* Rank households by pre-fiscal income
sort ymp_pc
gen double _cumw = sum(pondih)
gen double _F_ymp = (_cumw - pondih/2) / _cumw[_N]

* Gini of ymp_pc (needed for Kakwani)
qui sum ymp_pc [aw=pondih], meanonly
local mu_ymp = r(mean)
qui corr ymp_pc _F_ymp [aw=pondih], cov
local gini_ymp = 2 * r(cov_12) / `mu_ymp'

* Compute CC for each instrument
local n_instr : word count `instruments'
local k 0

tempname cc_mat kak_mat
mat `cc_mat' = J(`n_instr', 1, .)
mat `kak_mat' = J(`n_instr', 1, .)
local inames ""

foreach x of local instruments {
	local ++k
	local inames `inames' `x'
	
	qui sum `x'_pc [aw=pondih], meanonly
	local mu_x = r(mean)
	
	if `mu_x' != 0 {
		qui corr `x'_pc _F_ymp [aw=pondih], cov
		local cc_val = 2 * r(cov_12) / `mu_x'
		mat `cc_mat'[`k', 1] = `cc_val'
		mat `kak_mat'[`k', 1] = `cc_val' - `gini_ymp'
	}
}

* Build CC dataset
clear
set obs `n_instr'
gen variable = ""
gen value_cc = .
gen value_kak = .

forvalues k = 1/`n_instr' {
	local vname : word `k' of `inames'
	replace variable   = "`vname'" in `k'
	replace value_cc   = `cc_mat'[`k', 1] in `k'
	replace value_kak  = `kak_mat'[`k', 1] in `k'
}

* Reshape to long (CC and Kakwani as separate rows)
reshape long value_, i(variable) j(measure) string
rename value_ value
replace measure = "concentration_coefficient" if measure == "cc"
replace measure = "kakwani" if measure == "kak"

gen indicator  = measure
gen instrument = variable
gen income     = "ymp"
gen context    = "equity"
gen deciles_pc = .

tempfile cc_kakwani
save `cc_kakwani'

*===============================================================================
*---> E1d. Append all concentration indicators
*===============================================================================

u `conc_shares_dec', clear
append using `conc_shares_poor'
append using `cc_kakwani'

tempfile ind_3_13
save `ind_3_13'
*/