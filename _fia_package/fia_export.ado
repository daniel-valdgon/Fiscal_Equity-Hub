*! version 0.1.0  01May2026
* fia_export — Append all subcommand results, merge taxonomy, export to Excel
* Wraps logic from 3-09-Taxonomy_Export.do

cap program drop fia_export
program fia_export, rclass
	version 16.0
	syntax , output(string) taxonomy(string) country(string) [sheet(string)]
	
	if "`sheet'" == "" local sheet "all"
	
	* ---------------------------------------------------------------
	* A. Append all indicator results
	* ---------------------------------------------------------------
	local first 1
	foreach mod in inequality poverty incidence marginal concentration ///
	               coverage effectiveness redistribution shares ///
	               meanincome benefits {
		if "${fia_result_`mod'}" != "" {
			if `first' {
				u "${fia_result_`mod'}", clear
				local first 0
			}
			else {
				cap append using "${fia_result_`mod'}"
			}
		}
	}
	
	if `first' {
		di as error "No indicator results to export. Run subcommands first."
		exit 198
	}
	
	cap replace context = "equity" if context == ""
	gen concat = variable + "_" + measure + "_" + ///
		cond(missing(reference), "", reference) + "_ymp_" + string(deciles_pc)
	order concat, first
	
	tempfile aux_all
	save `aux_all'
	
	* ---------------------------------------------------------------
	* B. Load and merge taxonomy components
	* ---------------------------------------------------------------
	* Taxonomy is an Excel file with sheets: context, indicator, instrument, income, reference
	local taxonomy_sheets "context indicator instrument income reference"
	
	foreach j of local taxonomy_sheets {
		preserve
			cap import excel "`taxonomy'", sheet("`j'") firstrow clear
			if _rc {
				di as text "  Warning: taxonomy sheet `j' not found, skipping"
				restore
				continue
			}
			tempfile tax_`j'
			save `tax_`j''
		restore
		
		cap merge m:m `j' using `tax_`j''
		if !_rc {
			drop if _merge == 2
			drop _merge
		}
	}
	
	* ---------------------------------------------------------------
	* C. Generate UniqueID
	* ---------------------------------------------------------------
	order value id*
	
	foreach id in id_context id_indicator id_BIID id_income id_pline {
		cap confirm variable `id'
		if _rc continue
		tostring `id', replace
		replace  `id' = "99" if `id' == ""
		replace  `id' = "99" if `id' == "."
	}
	
	tostring deciles_pc, replace
	replace  deciles_pc = "99" if deciles_pc == "."
	
	cap gen UniqueID_s = id_context + "_" + id_indicator + "_" + id_BIID ///
	                   + "_" + id_pline + "_" + deciles_pc
	
	* ---------------------------------------------------------------
	* D. Export to Excel
	* ---------------------------------------------------------------
	gen dataset = "`country'"
	
	cap confirm variable TYPE
	cap confirm variable INDICATOR
	cap confirm variable BUDGETLINEITEM
	cap confirm variable INCOMECONCEPT
	cap confirm variable POVERTYLINE
	
	order dataset UniqueID_s concat value
	
	export excel "`output'", sheet("`sheet'") sheetreplace first(variable)
	
	di as text "  Export: results saved to `output' (sheet: `sheet')"
end
