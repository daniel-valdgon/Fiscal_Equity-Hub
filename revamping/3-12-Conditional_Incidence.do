/*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program:  GSG3 Fiscal Equity Hub - Conditional Incidence
* Author:   Daniel Valderrama & JM Monroy
* Date:     May 2026
* Title:    Conditional incidence by decile
*--------------------------------------------------------------------------------
* Indicator ID: 38 (Conditional incidence by decile)
* Context:      EQU (Equity impact)
* Income:       Pre-fiscal (ymp, id=1) and Disposable (yd, id=4)
* Instruments:  All taxes and transfers
* Deciles:      1-10 (pre-fiscal and disposable)
*--------------------------------------------------------------------------------
* Definition:   Conditional incidence = mean(X/Y) among households where X != 0.
*               Unlike unconditional incidence (id=37), this restricts to
*               beneficiaries/payers of each instrument.
*--------------------------------------------------------------------------------
* Requires: 3-00-Setup.do to be included first.
*--------------------------------------------------------------------------------*/

*===============================================================================
*---> Conditional Incidence by decile
*     share_X/Y conditional on X != 0
*===============================================================================

foreach y in ymp yd {

	u `output', clear
	keep hhid ${concs_pc} pondih *_deciles_pc

	* Taxes: negative sign (burden), conditional on paying
	foreach x in ${tax} ${indtax} {
		cap gen share_`x'_pc = -`x'_pc / `y'_pc if `x'_pc != 0 & !missing(`x'_pc)
	}

	* Transfers & subsidies: positive sign (benefit), conditional on receiving
	foreach x in ${transfer} ${inkind} ${Subsidies} {
		cap gen share_`x'_pc = `x'_pc / `y'_pc if `x'_pc != 0 & !missing(`x'_pc)
	}

	keep *_deciles_pc share* pondih

	groupfunction [aw=pondih], mean(share*) by(`y'_deciles_pc) norestore

	reshape long share_, i(`y'_deciles_pc) j(variable) string
		gen measure    = "conditional_incidence_`y'"
		rename share_ value

	ren `y'_deciles_pc deciles_pc

	* Taxonomy fields
	gen indicator  = "conditional_incidence"
	gen income     = "`y'"
	gen instrument = variable
	gen context    = "equity"

	tempfile cond_inc_`y'
	save `cond_inc_`y''
}

u `cond_inc_ymp', clear
append using `cond_inc_yd'
tempfile ind_3_12
save `ind_3_12'
