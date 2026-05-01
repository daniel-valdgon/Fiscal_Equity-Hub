/*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program:  GSG3 Fiscal Equity Hub - Netcash Incidence
* Author:   Daniel Valderrama & JM Monroy
* Date:     May 2026
* Title:    Incidence by decile (netcash position)
*--------------------------------------------------------------------------------
* Indicator ID: 37 (Incidence by decile)
* Context:      EQU (Equity impact)
* Income:       Pre-fiscal (ymp, id=1) and Disposable (yd, id=4)
* Instruments:  All taxes (negative share) and transfers (positive share)
* Deciles:      1-10 (pre-fiscal and disposable)
*--------------------------------------------------------------------------------
* Requires: 3-00-Setup.do to be included first (provides `output' tempfile,
*           policy locals, taxonomy tempfiles, and dataset globals).
*--------------------------------------------------------------------------------*/

*===============================================================================
*---> Netcash Position: incidence (relative) by decile
*     share_X_pc = -X_pc/Y_pc  for taxes
*     share_X_pc = +X_pc/Y_pc  for transfers
*     Indicator id_indicator = 37
*===============================================================================

foreach y in ymp yd {

	u `output', clear
	keep hhid `concs_pc' pondih *_centile_pc *_deciles_pc

	* Taxes: negative sign (burden)
	foreach x in `tax' `indtax' {
		gen share_`x'_pc = -`x'_pc / `y'_pc
	}

	* Transfers & subsidies: positive sign (benefit)
	foreach x in `transfer' `inkind' `Subsidies' {
		gen share_`x'_pc = `x'_pc / `y'_pc
	}

	keep *_deciles_pc share* pondih

	groupfunction [aw=pondih], mean(share*) by(`y'_deciles_pc) norestore

	reshape long share_, i(`y'_deciles_pc) j(variable) string
		gen measure    = "netcash_`y'"
		rename share_ value

	ren `y'_deciles_pc deciles_pc

	* Taxonomy fields
	gen indicator  = "incidence"
	gen income     = "`y'"
	gen instrument = variable

	tempfile netcash_`y'
	save `netcash_`y''
}

* Store in a combined tempfile for downstream use
u `netcash_ymp', clear
append using `netcash_yd'
tempfile ind_3_02
save `ind_3_02'
