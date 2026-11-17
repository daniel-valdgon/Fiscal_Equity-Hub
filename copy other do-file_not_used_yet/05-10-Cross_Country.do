/*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program:  GSG3 Fiscal Equity Hub - Cross-Country Assembly
* Author:   Daniel Valderrama & JM Monroy
* Date:     May 2026
* Title:    Assemble cross-country dataset from exported sheets
*--------------------------------------------------------------------------------
* This file reads all exported sheets from the indicators Excel file
* and appends them into a single cross-country dataset.
*--------------------------------------------------------------------------------
* Requires: 3-09-Taxonomy_Export.do to have run for all datasets.
*--------------------------------------------------------------------------------*/

*===============================================================================
*---> Cross-country dataset assembly
*===============================================================================

import excel using "$dataout", describe
local sheets `r(sheets)'

* Loop and append all country sheets
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

di as text "Cross-country dataset assembled: `=_N' observations from `=wordcount(`"`sheets'"')' sheets."
