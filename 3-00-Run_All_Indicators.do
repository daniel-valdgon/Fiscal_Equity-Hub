/*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program:  GSG3 Fiscal Equity Hub - Modular Indicator Runner
* Author:   Daniel Valderrama & JM Monroy
* Date:     May 2026
* Title:    Run all 3-xx indicator modules for each detected dataset
*--------------------------------------------------------------------------------
* This file replaces the monolithic calculation loop. It:
*   1. Loads shared setup (3-00)
*   2. Loops over each detected dataset
*   3. For each dataset, opens data, creates deciles, then runs each
*      indicator module (3-02 through 3-08), exports via 3-09
*   4. After all datasets, assembles cross-country file (3-10)
*--------------------------------------------------------------------------------
* Indicator modules and their taxonomy IDs:
*   3-02  Netcash Incidence         id_indicator = 37
*   3-03  Gini & Theil              id_indicator = 5, 66
*   3-04  Poverty FGT               id_indicator = 4, 6
*   3-05  Marginal Contributions    id_indicator = 44, 45
*   3-06  Coverage                  id_indicator = 52
*   3-07  Mean Income by Decile     id_indicator = 70
*   3-08  Concentration & Kakwani   id_indicator = 42, 43, 39
*   3-11  Redistributive Impact     id_indicator = 46, 47, 67, 68, 69
*   3-12  Conditional Incidence     id_indicator = 38
*   3-13  Conc Shares, CC, Kakwani  id_indicator = 39, 40, 42, 43
*   3-14  Targeting Errors          id_indicator = 53-59
*   3-15  CEQ Effectiveness         id_indicator = 48, 49
*   3-16  Consumption Shares        id_indicator = 60
*   3-09  Taxonomy & Export         (merges IDs, exports)
*   3-10  Cross-Country Assembly    (post-loop)
*--------------------------------------------------------------------------------*/

*===============================================================================
*---> Step 1: Shared setup (paths, macros, taxonomy, detect datasets)
*===============================================================================
include "${root}/02-Scripts/wb419055/3-00-Setup.do"

*===============================================================================
*---> Step 2: Loop over each detected dataset
*===============================================================================
forvalues i = 1/$n_datasets {

	global sheetname   "${cty_`i'}"
	global datasetname "${fname_`i'}"
	di as text _n "=========================================="
	di as text "Processing: ${path_`i'} — Sheet: ${sheetname}"
	di as text "==========================================" _n

	use `"${path_`i'}"', clear

	cap drop *deciles_pc *centile_pc

	foreach y in ymp yd {
		quantiles `y'_pc [w=pondih], gen(`y'_deciles_pc)  nq(10)
		quantiles `y'_pc [w=pondih], gen(`y'_centile_pc) nq(100)
	}

	tempfile output
	save `output'

	*--- Run each indicator module -----------------------------------------
	include "${root}/02-Scripts/wb419055/3-02-Netcash_Incidence.do"
	include "${root}/02-Scripts/wb419055/3-03-Gini_Theil.do"
	include "${root}/02-Scripts/wb419055/3-04-Poverty_FGT.do"
	include "${root}/02-Scripts/wb419055/3-05-Marginal_Contributions.do"
	include "${root}/02-Scripts/wb419055/3-06-Coverage.do"
	include "${root}/02-Scripts/wb419055/3-07-Mean_Income.do"
	include "${root}/02-Scripts/wb419055/3-08-Concentration_Kakwani.do"
	include "${root}/02-Scripts/wb419055/3-11-Redistributive_Impact.do"
	include "${root}/02-Scripts/wb419055/3-12-Conditional_Incidence.do"
	include "${root}/02-Scripts/wb419055/3-13-Concentration_Shares_CC_Kakwani.do"
	include "${root}/02-Scripts/wb419055/3-14-Targeting_Errors.do"
	include "${root}/02-Scripts/wb419055/3-15-CEQ_Effectiveness.do"
	include "${root}/02-Scripts/wb419055/3-16-Consumption_Shares.do"

	*--- Merge taxonomy & export -------------------------------------------
	include "${root}/02-Scripts/wb419055/3-09-Taxonomy_Export.do"
}

*===============================================================================
*---> Step 3: Cross-country assembly
*===============================================================================
include "${root}/02-Scripts/wb419055/3-10-Cross_Country.do"

di as text _n "All indicator modules completed successfully."
