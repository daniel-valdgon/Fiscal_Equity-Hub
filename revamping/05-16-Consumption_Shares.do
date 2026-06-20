/*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program:  GSG3 Fiscal Equity Hub - Share of Consumption by Decile
* Author:   Daniel Valderrama & JM Monroy
* Date:     May 2026
* Title:    Share of total consumption/income accruing to each decile
*--------------------------------------------------------------------------------
* Indicator ID: 60 (Share of consumption by decile)
* Context:      EQU (Equity impact)
* Income:       All income concepts (ymp, yn, yd, yc, yf)
* Instruments:  n/a
* Deciles:      1-10 (pre-fiscal ymp)
*--------------------------------------------------------------------------------
* Definition:
*   Share(Y, d) = sum(Y_i * w_i, i in d) / sum(Y_i * w_i, all)
*   Shows what fraction of total income each decile commands.
*--------------------------------------------------------------------------------
* Requires: 3-00-Setup.do to be included first.
*--------------------------------------------------------------------------------*/

*===============================================================================
*---> Share of consumption/income by decile
*===============================================================================

u `output', clear

* Generate weighted income for each concept
foreach y of global income {
	gen double w_`y' = `y'_pc * pondih
}

preserve
	collapse (sum) w_*, by(ymp_deciles_pc)
	
	* Convert to shares
	foreach y of global income {
		qui sum w_`y'
		local tot = r(sum)
		replace w_`y' = w_`y' / `tot' if `tot' != 0
	}
	
	reshape long w_, i(ymp_deciles_pc) j(variable) string
	rename w_ value
	ren ymp_deciles_pc deciles_pc
	
	* Append _pc suffix to variable for taxonomy matching
	replace variable = variable + "_pc"
	
	gen measure    = "consumption_share"
	gen indicator  = "consumption_share"
	gen income     = variable
	gen context    = "equity"
	gen instrument = ""
	
	tempfile ind_3_16
	save `ind_3_16'
restore
