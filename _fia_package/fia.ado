*! version 0.1.0  01May2026
*! Copyright (C) World Bank 2026
*! Daniel Valderrama <dvalderrama1@worldbank.org>
*! JM Monroy <jmonroypaez@worldbank.org>
*
* Fiscal Incidence Analysis (FIA) — Standardized analytics package
* Produces a comprehensive set of CEQ-based fiscal equity indicators
* from harmonized FIA microdata. Inspired by the PEA package architecture.
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

cap program drop fia
program fia, rclass
	version 16.0
	local version : di "version " string(_caller()) ":"
	
	gettoken subcmd 0 : 0, parse(" :,=[]()+-")
	
	* Display banner
	noi _fia_logo
	
	* ---------------------------------------------------------------
	* Subcommand dispatch (PEA-style: fia <subcmd> [options])
	* ---------------------------------------------------------------
	
	if ("`subcmd'" == "core") {
		* Run all indicators and export to Excel
		fia_core `0'
	}
	else if ("`subcmd'" == "inequality") {
		* Gini, Theil, 90-10 ratio, absolute Gini
		fia_inequality `0'
	}
	else if ("`subcmd'" == "poverty") {
		* FGT0, FGT1, poverty impact
		fia_poverty `0'
	}
	else if ("`subcmd'" == "incidence") {
		* Netcash incidence and conditional incidence by decile
		fia_incidence `0'
	}
	else if ("`subcmd'" == "concentration") {
		* Concentration shares, coefficients, and Kakwani
		fia_concentration `0'
	}
	else if ("`subcmd'" == "marginal") {
		* Marginal contributions to inequality and poverty
		fia_marginal `0'
	}
	else if ("`subcmd'" == "coverage") {
		* Coverage by decile, targeting errors
		fia_coverage `0'
	}
	else if ("`subcmd'" == "effectiveness") {
		* CEQ impact and spending effectiveness
		fia_effectiveness `0'
	}
	else if ("`subcmd'" == "redistribution") {
		* Redistributive impact, Reynolds-Smolensky
		fia_redistribution `0'
	}
	else if ("`subcmd'" == "shares") {
		* Income/consumption shares by decile
		fia_shares `0'
	}
	else if ("`subcmd'" == "meanincome") {
		* Mean income by decile
		fia_meanincome `0'
	}
	else if ("`subcmd'" == "benefits") {
		* Benefits (concentration shares) by decile
		fia_benefits `0'
	}
	else if ("`subcmd'" == "export") {
		* Merge taxonomy and export to Excel
		fia_export `0'
	}
	else if ("`subcmd'" == "setup") {
		* Validate data and set globals
		fia_setup `0'
	}
	else {
		if ("`subcmd'" == "") {
			di as smcl as err "syntax error"
			di as smcl as err "{p 4 4 2}"
			di as smcl as err "{bf:fia} must be followed by a subcommand."
			di as smcl as err "Type {bf:fia core} to run all indicators,"
			di as smcl as err "or {bf:fia inequality}, {bf:fia poverty}, etc."
			di as smcl as err "Type {bf:help fia} for the full list."
			di as smcl as err "{p_end}"
			exit 198
		}
		capture which fia_`subcmd'
		if (_rc) {
			if (_rc == 1) exit 1
			di as smcl as err "unrecognized subcommand: {bf:fia `subcmd'}"
			exit 199
		}
		`version' fia_`subcmd' `0'
	}
	return add
end

* ---------------------------------------------------------------
* Banner program
* ---------------------------------------------------------------
cap program drop _fia_logo
program _fia_logo
	di as text ""
	di as text " {hline 60}"
	di as text "  Fiscal Incidence Analysis (FIA) Package v0.1.0"
	di as text "  World Bank — GSG3 Fiscal Equity Hub"
	di as text "  CEQ-based standardized fiscal equity indicators"
	di as text " {hline 60}"
	di as text ""
end
