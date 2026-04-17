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

*===============================================================================
*---> A/B. Paths and Macros definition
*===============================================================================
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
	global dataout       "${root}/03-Outputs\01-Cleaned-FIA-Indicators"

*---> B.1 Macros for policies and income concepts values 

		
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
	
	
*---> B.2 Macros at per-capita values 
	foreach x in tax indtax inkind transfer income concs Subsidies {
		local `x'_pc
		foreach y of local `x' {
			local `x'_pc ``x'_pc' `y'_pc 	
		}
	}
*---> B.3 Other macros 
	*local rank ymp_pc
	local pline zref line_1 line_2 line_3
	

	
	local countries GMB MRT

	gl GMB_source "IHS-2020-2020-D01-P01-M01"
	gl MRT_source "ECPV-2019-2019-D01-P01-M01"

*---> B.4

	foreach c of local countries {
    use "$microdata/`c'/`c'-${`c'_source}/`c'-${`c'_source}.dta", clear
	
	cap drop *deciles_pc *centile_pc
	
	foreach y in ymp yd { 
	xtile `y'_deciles_pc = `y'_pc  [aw=pondih], nq(10) 
	xtile `y'_centile_pc =`y'_pc  [aw=pondih], nq(100) 
	} 
	
	tempfile output
	
	save `output'

	gl sheetname `c'

*===============================================================================
*---> C. Netcash Position for ymp and yd.
*        Generating relative incidence by 
*===============================================================================


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
	tempfile netcash_`y'
	save `netcash_`y''

}
	
*===============================================================================
*---> D. Distributional indicators Gini, Theil, and FGT measures
		*Generate Income Concepts for Marginal Contribution
*===============================================================================

u `output', clear
		

*List of all new marginal contributinos store in income
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

*===============================================================================
*---> E.  benefits, coverage beneficiaries
*===============================================================================
 
*---> E.1 benefits, coverage beneficiaries by all	
u `output', clear


	sp_groupfunction [aw=pondih], benefits(`concs_pc') mean(`concs_pc') coverage(`concs_pc') beneficiaries(`concs_pc')  by(all)
	gen deciles_pc=0
	tempfile theall
	save `theall'

*---> E.2 benefits, coverage beneficiaries by deciles (ymp)	
u `output', clear

	sp_groupfunction [aw=pondih], benefits(`concs_pc') mean(`concs_pc') coverage(`concs_pc') beneficiaries(`concs_pc')  by(ymp_deciles_pc)
	ren ymp_deciles_pc deciles_pc

	tempfile theall_ymp
	save `theall_ymp'
	
	
*---> E.3 benefits, coverage beneficiaries by yd
u `output', clear
	
	
	sp_groupfunction [aw=pondih], benefits(`concs_pc') mean(`concs_pc') coverage(`concs_pc') beneficiaries(`concs_pc')  by(yd_deciles_pc)
	
	tempfile theall_yd
	save `theall_yd'
	
	
*---> adding previous ones and generating aux output 

    u `theall_ymp', clear
	append using `poverty'
	append using `netcash_ymp'
	append using `theall'	
		
	gen concat = variable +"_"+ measure+"_" +reference+"_ymp_"+string(deciles_pc)
	order concat, first
	
	tempfile aux1
	save `aux1'
	
	
	u `theall_yd', clear 
	append using `netcash_yd'
	
	gen concat = variable +"_"+ measure+"_"+"_yd_"+string(yd_deciles_pc)
	order concat, first
	
	append using `aux1'
	

	
	export excel "$dataout", sheet("all${sheetname}") sheetreplace first(variable)

}

timer off 1
timer list 1


*/* Mata version 

mata:
    microdata = st_global("microdata")
    dirs1 = dir(microdata, "dirs", "*")
    dataset_list = J(0, 1, "")

    for (i = 1; i <= rows(dirs1); i++) {
        cty_path = microdata + "/" + dirs1[i]
        dirs2 = dir(cty_path, "dirs", "*")

        for (j = 1; j <= rows(dirs2); j++) {
            cty_proj_path = cty_path + "/" + dirs2[j]

            // Always check for .dta at 2nd level (GMB, MRT)
            files = dir(cty_proj_path, "files", "*.dta")
            for (f = 1; f <= rows(files); f++) {
                dataset_list = dataset_list \ files[f]
            }

            // Also go one level deeper (SEN)
            dirs3 = dir(cty_proj_path, "dirs", "*")
            for (k = 1; k <= rows(dirs3); k++) {
                cty_final_path = cty_proj_path + "/" + dirs3[k]
                files = dir(cty_final_path, "files", "*.dta")
                for (f = 1; f <= rows(files); f++) {
                    dataset_list = dataset_list \ files[f]
                }
            }
        }
    }

    st_global("dataset_list", invtokens(dataset_list'))
end

di "${dataset_list}"





















global dataset_list ""

local dirs1 : dir `"${microdata}"' dirs "*"

foreach subf of local dirs1 {
    local cty_path `"${microdata}/`subf'"'
    local dirs2 : dir `"`cty_path'"' dirs "*"

    foreach subf2 of local dirs2 {
        local cty_proj_path `"`cty_path'/`subf2'"'

        * 2nd level: GMB/MRT-type
        local files2 : dir `"`cty_proj_path'"' files "*.dta"
        foreach f of local files2 {
            local f_upper = strupper("`f'")
            global dataset_list `"${dataset_list} "`cty_proj_path'/`f_upper'""'
        }

        * 3rd level: SEN-type
        local dirs3 : dir `"`cty_proj_path'"' dirs "*"
        foreach subf3 of local dirs3 {
            local cty_final_path `"`cty_proj_path'/`subf3'"'
            local files3 : dir `"`cty_final_path'"' files "*.dta"
            foreach f of local files3 {
                local f_upper = strupper("`f'")
                global dataset_list `"${dataset_list} "`cty_final_path'/`f_upper'""'
            }
        }
    }
}

* Loop over each dataset
foreach dta of global dataset_list {
    
    di "Processing: `dta'"
    use `"`dta'"', clear
    
    cap drop *deciles_pc *centile_pc
	
	foreach y in ymp yd { 
	xtile `y'_deciles_pc = `y'_pc  [aw=pondih], nq(10) 
	xtile `y'_centile_pc =`y'_pc  [aw=pondih], nq(100) 
	} 
	
	tempfile output
	
	save `output'

	gl sheetname `c'

}