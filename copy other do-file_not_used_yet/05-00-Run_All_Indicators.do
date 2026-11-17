/*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program:  GSG3 Fiscal Equity Hub - Modular Indicator Runner
* Author:   Daniel Valderrama & JM Monroy
* Date:     May 2026
* Title:    Run all 05-xx indicator modules for each detected dataset
*--------------------------------------------------------------------------------
* This file replaces the monolithic calculation loop. It:
*   1. Loads shared setup (05-00)
*   2. Loops over each detected dataset
*   3. For each dataset, opens data, creates deciles, then runs each
*      indicator module (05-02 through 05-08), exports via 05-09
*   4. After all datasets, assembles cross-country file (3-10)
*--------------------------------------------------------------------------------
* Indicator modules and their taxonomy IDs:
*   05-02  Netcash Incidence         id_indicator = 37
*   05-03  Gini & Theil              id_indicator = 5, 66
*   05-04  Poverty FGT               id_indicator = 4, 6
*   05-05  Marginal Contributions    id_indicator = 44, 45
*   05-06  Coverage                  id_indicator = 52
*   05-07  Mean Income by Decile     id_indicator = 70
*   05-08  Concentration & Kakwani   id_indicator = 42, 43, 39
*   05-11  Redistributive Impact     id_indicator = 46, 47, 67, 68, 69
*   05-12  Conditional Incidence     id_indicator = 38
*   05-13  Conc Shares, CC, Kakwani  id_indicator = 39, 40, 42, 43
*   05-14  Targeting Errors          id_indicator = 53-59
*   05-15  CEQ Effectiveness         id_indicator = 48, 49
*   05-16  Consumption Shares        id_indicator = 60
*   05-09  Taxonomy & Export         (merges IDs, exports)
*   05-10  Cross-Country Assembly    (post-loop)
*--------------------------------------------------------------------------------*/

*===============================================================================
*---> Step 1: Shared setup (paths, macros, taxonomy, detect datasets)
*===============================================================================
include "${revamp_scripts}/05-00-Setup.do"

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

	* Fail fast: staging must have created key per-capita variables before 05-xx modules run.
	local required_pc "ymp_pc yn_pc yd_pc yc_pc yf_pc"
	foreach v of local required_pc {
		capture confirm variable `v'
		if _rc {
			di as err "Missing required variable `v' in ${path_`i'}. Run 04-01-Staging.do first."
			exit 111
		}
	}
	capture confirm variable pondih
	if _rc {
		di as err "Missing required weight variable pondih in ${path_`i'}."
		exit 111
	}

	cap drop *deciles_pc *centile_pc

	foreach y in ymp yd {
		quantiles `y'_pc [w=pondih], gen(`y'_deciles_pc)  nq(10)
		quantiles `y'_pc [w=pondih], gen(`y'_centile_pc) nq(100)
	}

	tempfile output
	save `output'

	*--- Run each indicator module -----------------------------------------
	include "${revamp_scripts}/05-02-Netcash_Incidence.do"
	include "${revamp_scripts}/05-03-Gini_Theil.do"
	include "${revamp_scripts}/05-04-Poverty_FGT.do"
	include "${revamp_scripts}/05-05-Marginal_Contributions.do"
	include "${revamp_scripts}/05-06-Coverage.do"
	include "${revamp_scripts}/05-07-Mean_Income.do"
	include "${revamp_scripts}/05-08-Concentration_Kakwani.do"
	include "${revamp_scripts}/05-11-Redistributive_Impact.do"
	include "${revamp_scripts}/05-12-Conditional_Incidence.do"
	include "${revamp_scripts}/05-13-Concentration_Shares_CC_Kakwani.do"
	include "${revamp_scripts}/05-14-Targeting_Errors.do"
	include "${revamp_scripts}/05-15-CEQ_Effectiveness.do"
	include "${revamp_scripts}/05-16-Consumption_Shares.do"

	*--- Merge taxonomy & export -------------------------------------------
	include "${revamp_scripts}/05-09-Taxonomy_Export.do"
}

*===============================================================================
*---> Step 3: Cross-country assembly
*===============================================================================
include "${revamp_scripts}/05-10-Cross_Country.do"

di as text _n "All indicator modules completed successfully."
