/*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program:  GSG3 Fiscal Equity Hub - Indicator Pipeline Setup
* Author:   Daniel Valderrama & JM Monroy
* Date:     May 2026
* Title:    Shared setup for all 3-xx indicator do-files
*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Note: This file is included by each modular 3-xx do-file.
*       It defines paths, macros, loads taxonomy, detects microdata,
*       and opens/prepares each dataset inside a loop.
*       After including this file, the caller has access to:
*         - `output' tempfile with deciled microdata
*         - All policy locals (tax_pc, transfer_pc, etc.)
*         - All taxonomy tempfiles (context, indicator, etc.)
*         - $n_datasets, $sheetname, $datasetname globals
*--------------------------------------------------------------------------------*/

*===============================================================================
*---> A. Paths and Macros
*===============================================================================

	global microdata   	"${root}/01-Data/01-02-FIA_Microdata"
	global template    	"${root}/01-Data/01-03-FIA_Core Indicators"
	global tempsim		"${root}/01-Data/3_temp_sim"
	global dataout      "${root}/03-Outputs/01-Cleaned-FIA-Indicators/01-Cleaned-FIA-Indicators"
	global metadata     "${root}/01-Data/00-Aux"

*---> A.3 Policy macros (from globals set by 0-01-aux_policy_list.do)
*     NOTE: All cross-file macros are globals so they survive across
*     `include' calls in the modular 3-xx do-files.

	local Directaxes 		"${Directaxes}"
	local Contributions 	"${Contributions}"
	local DirectTransfers   "${DirectTransfers}"
	local Subsidies         "${Subsidies}"
	local Indtaxes 			"${Indtaxes}"
	local InKindTransfers	"${InKindTransfers}"

	global tax        dirtax_total sscontribs_total `Directaxes' `Contributions'
	global indtax     indtax_total `Indtaxes' Tax_VAT
	global inkind     inktransf_total `InKindTransfers' education_inKind
	global transfer   dirtransf_total `DirectTransfers'
	global Subsidies  subsidy_total `Subsidies' subsidy_elec subsidy_fuel subsidy_water
	global income     ymp yn yd yc yf
	global concs      ${tax} ${indtax} ${transfer} ${inkind} ${income} ${Subsidies}

*---> A.4 Per-capita versions (deduplicated)
	foreach x in tax indtax inkind transfer income concs Subsidies {
		* Deduplicate: some policies appear in multiple groups
		local raw_list ${`x'}
		local dedup_list : list uniq raw_list
		global `x' `dedup_list'
		global `x'_pc
		foreach y in `dedup_list' {
			global `x'_pc ${`x'_pc} `y'_pc
		}
		local raw_pc ${`x'_pc}
		local dedup_pc : list uniq raw_pc
		global `x'_pc `dedup_pc'
	}

*---> A.5 Poverty lines
	global pline zref line_1 line_2 line_3
	
*---> A.5b Income codes for taxonomy mapping
	global codes "yd_pc yf_pc ymp_pc yc_pc yn_pc"

*---> A.6 Taxonomy correlative
	gl taxonomy_components context indicator instrument income reference
	foreach j of global taxonomy_components {
		import excel "$metadata/correlative.xlsx", sheet("`j'") firstrow clear
		drop if `j' == ""
		tempfile `j'
		save ``j''
	}

*===============================================================================
*---> B. Detect microdata
*===============================================================================

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
				global cty_${n_datasets}  "`cty'_`cty_count'"
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
					global cty_${n_datasets}  "`cty'_`cty_count'"
					global fname_${n_datasets} "`f_upper'"
				}
			}
		}
	}
