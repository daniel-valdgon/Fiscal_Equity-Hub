*! version 0.1.0  01May2026
* fia_setup — Validate FIA microdata and set policy globals
* Called by fia_core or can be run standalone.
* Sets globals: $fia_tax, $fia_indtax, $fia_transfer, $fia_inkind,
*               $fia_subsidy, $fia_income, $fia_concs, $fia_pline
*               and their _pc versions.

cap program drop fia_setup
program fia_setup
	version 16.0
	syntax [aw fw pw] [if] [in], ///
		[                          ///
		TAX(varlist)               ///
		CONTRib(varlist)           ///
		TRANSfer(varlist)          ///
		INDtax(varlist)            ///
		INKind(varlist)            ///
		SUBSidy(varlist)           ///
		PLINe(varlist)             ///
		]
	
	* ---------------------------------------------------------------
	* A. Validate required variables
	* ---------------------------------------------------------------
	foreach v in hhid pondih ymp_pc {
		cap confirm variable `v'
		if _rc {
			di as error "Required variable {bf:`v'} not found in dataset."
			exit 111
		}
	}
	
	* Validate income concepts (warn if missing, don't error)
	foreach y in yn_pc yd_pc yc_pc yf_pc {
		cap confirm variable `y'
		if _rc {
			di as text "  Note: `y' not found — some indicators will be skipped."
		}
	}
	
	* ---------------------------------------------------------------
	* B. Set policy macros with defaults
	* ---------------------------------------------------------------
	
	* Direct taxes
	if "`tax'" == "" {
		local tax "PIT BIT PropertyTax FinancialTax"
	}
	if "`contrib'" == "" {
		local contrib "sscontribs_total"
	}
	global fia_tax dirtax_total `tax' `contrib'
	
	* Indirect taxes
	if "`indtax'" == "" {
		local indtax "CD_direct excise_taxes VAT_direct VAT_indirect"
	}
	global fia_indtax indtax_total `indtax' Tax_VAT
	
	* Direct transfers
	if "`transfer'" == "" {
		local transfer "am_prog_1 am_prog_2 am_prog_3 am_prog_other"
	}
	global fia_transfer dirtransf_total `transfer'
	
	* In-kind transfers
	if "`inkind'" == "" {
		local inkind "education_inKind am_health"
	}
	global fia_inkind inktransf_total `inkind'
	
	* Subsidies
	if "`subsidy'" == "" {
		local subsidy "subsidy_elec_direct subsidy_elec_indirect subsidy_fuel_direct subsidy_fuel_indirect subsidy_water_direct subsidy_water_indirect subsidy_agric"
	}
	global fia_subsidy subsidy_total `subsidy' subsidy_elec subsidy_fuel subsidy_water
	
	* Income concepts
	global fia_income ymp yn yd yc yf
	
	* All fiscal instruments + income
	global fia_concs ${fia_tax} ${fia_indtax} ${fia_transfer} ${fia_inkind} ${fia_income} ${fia_subsidy}
	
	* Poverty lines
	if "`pline'" == "" {
		local pline "zref line_1 line_2 line_3"
	}
	global fia_pline `pline'
	
	* ---------------------------------------------------------------
	* C. Deduplicate and create _pc versions
	* ---------------------------------------------------------------
	foreach x in fia_tax fia_indtax fia_inkind fia_transfer fia_income fia_concs fia_subsidy {
		local raw_list ${`x'}
		local dedup_list : list uniq raw_list
		global `x' `dedup_list'
		
		* Build per-capita list
		global `x'_pc
		foreach y in `dedup_list' {
			cap confirm variable `y'_pc
			if _rc == 0 {
				global `x'_pc ${`x'_pc} `y'_pc
			}
		}
		local raw_pc ${`x'_pc}
		local dedup_pc : list uniq raw_pc
		global `x'_pc `dedup_pc'
	}
	
	di as text "  Setup complete."
	di as text "  Tax instruments:     ${fia_tax}"
	di as text "  Indirect taxes:      ${fia_indtax}"
	di as text "  Direct transfers:    ${fia_transfer}"
	di as text "  In-kind transfers:   ${fia_inkind}"
	di as text "  Subsidies:           ${fia_subsidy}"
	di as text "  Income concepts:     ${fia_income}"
	di as text "  Poverty lines:       ${fia_pline}"
end
