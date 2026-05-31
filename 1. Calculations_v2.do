/*------------------------------------------------------------------------------
*-------------------------------------------------------------------------------
* Program: GSG3 Fiscal Equity Hub - Core Database Outputs
* Author: 	Daniel VAlderrama 
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
   
*---> A.1 Define user paths
if "`c(username)'"=="wb419055" {
	global root     	"C:\Users\wb419055\OneDrive - WBG\GSG3\GSG Fiscal Equity - WB Group - Fiscal Equity Hub\Workspace\Data Hub"	

   global scripts		"${root}/02-Scripts/wb419055"
}

if "`c(username)'"=="wb527706" {
	global root     	"C:\Users\wb527706\OneDrive - WBG\GSG Fiscal Equity - WB Group - Data Hub"	
    global scripts		"${root}/02-Scripts/wb527706"
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

	*Original policy instruments, harmonized level of dissagregation should come ideally from a excel file that is core to the harmonization process (@jmmonroyb, create the excel file with the names not as per-capita and wih the meaning of each of them based on th emanual, when the excel is read immediately the list of instuments are created) 
	local Directaxes 		"${Directaxes}"
	local Contributions 	"${Contributions}" 
	local DirectTransfers   "${DirectTransfers}"
	local Subsidies         "${Subsidies}"
	local Indtaxes 			"${Indtaxes}"
	local InKindTransfers	"${InKindTransfers}" 

	*Gropus adding the totals of each of the previous categories 
	local tax dirtax_total sscontribs_total `Directaxes' `Contributions' 
	local indtax indtax_total  Tax_VAT `Indtaxes' //@ Tax_VAT needs to be moved to indtaxes when we have the final excel file with the names
	local taxes `tax' `indtax'
	
	local inkind inktransf_total  education_inKind `InKindTransfers'
	local transfer dirtransf_total `DirectTransfers' 
	local Subsidies subsidy_total  subsidy_elec subsidy_fuel subsidy_water `Subsidies' // @jmmonroyb, subsidy_elec subsidy_fuel subsidy_water need to bemoved to `Subsidies' when we have the final excel file
	local spending `inkind' `transfer' `Subsidies'
	
	local income_concepts ym yn yd yc yf 
	local concs `tax' `indtax' `transfer' `Subsidies' `inkind' `income_concepts' 
	

*---> A.4 Converting all macros into percapita values 
	foreach x in tax indtax inkind transfer Subsidies income_concepts concs  {
		local `x'_pc
		foreach y of local `x' {
			local `x'_pc ``x'_pc' `y'_pc 	
		}
		dis  `"list of `x' : ``x'_pc'"'
	}
	*Example: 
	*list of tax : dirtax_total_pc sscontribs_total_pc
	*list of indtax : indtax_total_pc Tax_VAT_pc
	*list of inkind : inktransf_total_pc education_inKind_pc
	*list of transfer : dirtransf_total_pc
	*list of Subsidies : subsidy_total_pc subsidy_elec_pc subsidy_fuel_pc subsidy_water_pc
	*list of income_concepts : ymp_pc yn_pc yd_pc yc_pc yf_pc
	*list of concs : dirtax_total_pc sscontribs_total_pc indtax_total_pc Tax_VAT_pc dirtransf_total_pc subsidy_total_pc subsidy_elec_pc subsidy_fuel_pc subsidy_water_pc inktransf_total_pc education_inKind_pc ymp_pc yn_pc yd_pc yc_pc yf_pc

*---> A.5 Other macros. Poverty lines  

	local pline line_nat line_li21 line_lm21 line_um21
	local npline line_nat 
	local ipline line_li21 line_lm21 line_um21
	
*---> A.6 Other macros. Taxonomy equivalence 
	
gl taxonomy_components context indicator instrument income povertyline partition pension 
foreach j of global taxonomy_components  {
	
	import excel "$metadata\correlative_2.xlsx", sheet("`j'") firstrow clear
	drop if  `j' ==""
	tempfile `j'
	save ``j'', replace 
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
        * Fixed structure: CountryName/dataname/HFMD/dataname.dta
        local hfmd_path `"`cty_path'/`subf2'/HFMD"'
        local f_upper : di strupper("`subf2'")
        local files : dir `"`hfmd_path'"' files "*.dta"

        foreach f of local files {
            local f_upper : di strupper("`f'")
            local cty_count = `cty_count' + 1
            global n_datasets   = ${n_datasets} + 1
            global path_${n_datasets}  `"`hfmd_path'/`f_upper'"'
            global cty_${n_datasets}   "`cty'_`cty_count'" // * @jmmonroyb, names for each country shoudl use database id SEN_S2022_P2022, so we avoid Senegal_2 that when this is scaled up create confusions 
            global fname_${n_datasets} "`f_upper'"
        }
    }
}

*===============================================================================
*---> C. Netcash Position for ymp and yd.
*        Generating incidence (relative) by decil (pre-fiscal and disposable)
*===============================================================================


* Loop over each country:
* @jmmonroyb, final do-file that will be used by country economist should not include this loop as they will have one country. So we need to ensure smooth tranistion and less loop dependent as poosible 

*@jmmonroyb, to debug we run with one data and call with a loop all the entire master file to run across countries 

local j=0
forvalues i = 1/$n_datasets {
local ++j

	* globals to call dataset and define the spreadsheet name .
	global sheetname    "${cty_`i'}"
    global datasetname  "${fname_`i'}"
	global indivname "d_`i'" // @jmmonroyb, do we need this? 
    di "Processing: ${path_`i'} - Sheet: ${sheetname}"

    use `"${path_`i'}"', clear

	*General variables that could serve multiple indicators are created once here 
	foreach bins in deciles centile millile {
    	cap  drop *`bins'_pc* 
	}

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
* Indicator names should have the policyname, save in the local `x', at the very end so in the reshape that is the only thing in the name
set seed 80292367
foreach y in ymp yd {
		foreach x in `tax' `indtax' `transfer' `inkind' `Subsidies' {
			
			if strpos("`taxes'", "`x'") {
				gen share_`y'_pc_`x' = - `x'_pc / `y'_pc
			}
			else if strpos("`spending'", "`x'") {	
				gen share_`y'_pc_`x' = `x'_pc / `y'_pc
			}

			gen uinc_`y'_pc_`x' = `x'_pc / `y'_pc
			gen cinc_`y'_pc_`x' = `x'_pc / `y'_pc  if (`x'_pc > 0)
			gen cov_`y'_pc_`x'  = (`x'_pc > 0)
			gen abs_`y'_pc_`x'  = `x'_pc
		
		} // eo foreach x
}

tempfile output_quantiles
save `output_quantiles', replace 


*Prepare microdata : milliles and variable that allowed that means compute them 

	foreach y in ymp yd {

		u `output_quantiles', clear	
		
		keep `y'_millile_pc `y'_centile_pc `y'_decile_pc share_`y'* uinc_`y'* cinc_`y'* cov_`y'* abs_`y'* pondih	

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
		foreach indicator in share uinc cinc cov abs {

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
			gen pension = "PEN_PDI"
			gen country= substr("${fname_`i'}", 1, 3)
			gen dataset = "${fname_`i'}"

			order indicator category instrument income povertyline partition pension country dataset value
			save "$dataaux/`indicator'_`y'_`i'", replace

		}	  // eo foreach indicator
		
		* Drop fr_wide after all indicators are done for this y
		cap frame drop fr_wide

	} // eo foreach y

} // eo foreach dataset

*---> C.3 Compiling and saving data 
foreach indicator in share uinc cinc cov abs {
	foreach y in ymp yd {
		forvalues i = 1/$n_datasets {	
			
			use "$dataaux/`indicator'_`y'_`i'", clear
			
			if `i'==1 & "`y'"=="ymp" & "`indicator'"=="share" {
				save "$dataaux/final_dist.dta", replace
			}
			else {
				append using "$dataaux/final_dist.dta"
				save "$dataaux/final_dist.dta", replace

				isid indicator category instrument income povertyline partition pension country dataset, sort
			}	
			
		} // eo foreach country
	} // eo foreach y
} // eo foreach indicator

exit



*===============================================================================
*---> D. Distributional indicators International values Gini, Theil, and FGT measures
		*Generate Income Concepts for Marginal Contribution
*===============================================================================

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
	gen value_totimp = ym_lvl - yc_lvl if inlist(indicator,"fgt0" "fgt1" "fgt2")
	replace value_totimp = ym_lvl - yf_lvl if inlist(indicator,"gini" "theil")
	

	*Eliminating MC that does not make sense
	foreach policy in  `indtax' `Subsidies'   {
		replace value_mc=. if policy=="`policy'" &  inlist(income_concept, "yd") // all indirect taxes, subssidies and inkind with disposable income
	}

	foreach policy in  `inkind'  {
		replace value_mc=. if policy=="`policy'" &  inlist(income_concept, "yd" "yc" ) // all contribution of inkind with consumable income 
		replace value_mc=. if inlist(indicator, "fgt0" "fgt1" "fgt2") & inlist(income_concept, "yf") // all mc to poverty with final income
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
replace instrument = "INS_NA_N_N" if instrument=="" | instrument==" " & inlist(long_variable,"ym_pc" "yn_pc" "yd_pc" "yc_pc" "yf_pc")

rename income_concept income
rename reference povertyline
replace povertyline = "PL_NONE_N" if inlist(indicator, "gini" "theil")
gen partition = "PV_NA_NONE"
gen pension = "PEN_PDI"
gen country= substr("${fname_`i'}", 1, 3)
gen dataset = "${fname_`i'}"


replace instrument = "INS_NA_N_N" if instrument=="" | instrument==" " & country=="ECU" // @jmmonroyb, thre is a weird reason why the conditional of line 452 is not working,so I am making an exception here, please check  "replace instrument = "INS_NA_N_N" if instrumen  ..."  

save "$dataaux/pov_ineq_debug_`i'.dta", replace 

drop _population long_variable  value sd aux_* end_y all ym_lvl sd_ym_lvl yd_lvl sd_yd_lvl yc_lvl sd_yc_lvl yf_lvl sd_yf_lvl

reshape long value_, i(indicator category instrument income povertyline partition pension country dataset) j(indicator2) string

drop if value_==.
ren (indicator indicator2) (aux_indicator indicator )

replace indicator ="mcp" if indicator=="mc" & inlist(aux_indicator,"fgt0" "fgt1" "fgt2")
replace indicator ="mci" if indicator=="mc" & inlist(aux_indicator,"gini" "theil") 
replace indicator ="tpi" if indicator=="totimp" & inlist(aux_indicator,"fgt0" "fgt1" "fgt2")
replace indicator ="tri" if indicator=="totimp" & inlist(aux_indicator,"gini" "theil")

replace indicator ="hcr" if indicator=="level" & inlist(aux_indicator,"fgt0")
replace indicator ="gni" if indicator=="level" & inlist(aux_indicator,"gini" )

*temporary drop to be deleted after Pecchi includes fgt1 and fgt2 in the taxonomy
drop if aux_indicator=="fgt1" | aux_indicator=="fgt2" | aux_indicator=="theil"

order indicator category instrument income povertyline partition pension country dataset value
save "$dataaux/pov_ineq_`i'.dta", replace

}

*---> D.3 Compiling and saving data

forvalues i = 1/$n_datasets {	
			
			use "$dataaux/pov_ineq_`i'.dta", clear
			
			if `i'==1 {
				save "$dataaux/final_pov_ineq.dta", replace
			}
			else {
				append using "$dataaux/final_pov_ineq.dta"
				save "$dataaux/final_pov_ineq.dta", replace
				isid indicator category instrument income povertyline partition pension country dataset, sort
			}	
			
} // eo foreach country


*===============================================================================
*---> E.  concentrations coeficients and kakwani index. To be included 
*===============================================================================

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
*---> B. Concentration Shares by Poor & Non-Poor (id=40)
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
*---> C. Concentration Coefficients (id=43) and Kakwani Index (id=42)
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
*---> D. Append all concentration indicators
*===============================================================================

u `conc_shares_dec', clear
append using `conc_shares_poor'
append using `cc_kakwani'

tempfile ind_3_13
save `ind_3_13'



*===============================================================================
*---> F. Exporing finaldatasets
*===============================================================================	
*---> F.1 adding previous ones and generating aux output 

    u "$dataaux\theall_ymp", clear
	append using "$dataaux\poverty"
	append using "$dataaux\netcash_ymp" 
		
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
	
	export excel "$dataout\01-Cleaned-FIA-Indicators", sheet("all${sheetname}") sheetreplace first(variable)
	
*	tempfile all_${sheetname}
	
*	global tmppath_`i' `"`all_${sheetname}'"'
	save "$dataaux\_$indivname", replace
}


*===============================================================================
*---> H.  Cross-country dataset 
*===============================================================================


* Append all datasets into one
use  "$dataaux\_d_1" , clear
forvalues i = 2/$n_datasets {
    append using  "$dataaux\_d_`i'"
}

save "$dataout\FIA_Indicators.dta", replace



*===============================================================================
*---> This sections in under construction. It consists in generating an Unique 
*     ID from Original Taxonomy that matches the taxonomy by decomposition. 
*===============================================================================

	import excel "$metadata\IndicatorsDatabase_v1.xlsx", sheet("INDICATORS") firstrow clear


	order Indicatortypecode Indicatorcode Categorycode Instrumentcode Incomecode Povertylinecode
	
	foreach k in Categorycode Indicatorcode Incomecode Povertylinecode {
		
		replace `k'=99 if `k'==.
		tostring `k' , replace 
	}
	
	replace Instrumentcode="99" if Instrumentcode==""
	
	drop if Indicatortypecode==""
	
		gen UniqueID_s = Indicatortypecode +"_"+ Indicatorcode+"_" +Categorycode+"_"+Instrumentcode+"_"+Incomecode +"_"+Povertylinecode


	*Create System for statistic of indicator coverage 
timer off 1
timer list 1










