/*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program:  GSG3 Fiscal Equity Hub - Taxonomy & Export
* Author:   Daniel Valderrama & JM Monroy
* Date:     May 2026
* Title:    Merge taxonomy IDs and export to Excel
*--------------------------------------------------------------------------------
* This file appends all indicator tempfiles produced by 3-02 through 3-08,
* merges taxonomy components to generate UniqueID, and exports to Excel.
*--------------------------------------------------------------------------------
* Requires: 3-00-Setup.do included first, plus all 3-0x indicator files run.
*           Expected tempfiles: ind_3_02 ... ind_3_08
*--------------------------------------------------------------------------------*/

*===============================================================================
*---> F. Append all indicator modules
*===============================================================================

	u `ind_3_02', clear                    // Netcash incidence
	cap append using `ind_3_03'            // Gini & Theil
	cap append using `ind_3_04'            // FGT poverty
	cap append using `ind_3_05'            // Marginal contributions (raw)
	cap append using `ind_3_06'            // Coverage
	cap append using `ind_3_07'            // Mean income
	cap append using `ind_3_08'            // Concentration / Kakwani

	* Ensure context is set
	cap replace context = "equity" if context == ""

	gen concat = variable + "_" + measure + "_" + reference + "_ymp_" + string(deciles_pc)
	order concat, first

	tempfile aux_all
	save `aux_all'

*===============================================================================
*---> G. Taxonomy Unique ID
*===============================================================================

*---> G.1 Merge each taxonomy component
	foreach j of global taxonomy_components {
		merge m:m `j' using ``j''
		drop if _merge == 2
		drop _merge
	}

*---> G.2 Clean and generate UniqueID

	order value id*

	foreach id in id_context id_indicator id_BIID id_income id_pline {
		tostring `id', replace
		replace  `id' = "99" if `id' == ""
		replace  `id' = "99" if `id' == "."
	}

	tostring deciles_pc, replace
	replace  deciles_pc = "99" if deciles_pc == "."

	gen UniqueID_s = id_context + "_" + id_indicator + "_" + id_BIID ///
	               + "_" + id_pline + "_" + deciles_pc

*===============================================================================
*---> H. Export
*===============================================================================

	gen dataset = "${datasetname}"

	order dataset UniqueID_s concat value TYPE INDICATOR BUDGETLINEITEM INCOMECONCEPT POVERTYLINE
	keep  dataset UniqueID_s concat value TYPE INDICATOR BUDGETLINEITEM INCOMECONCEPT POVERTYLINE

	export excel "$dataout", sheet("all${sheetname}") sheetreplace first(variable)
