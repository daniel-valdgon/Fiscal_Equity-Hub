/*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program:  GSG3 Fiscal Equity Hub - Marginal Contributions
* Author:   Daniel Valderrama & JM Monroy
* Date:     May 2026
* Title:    Marginal contribution to inequality and poverty
*--------------------------------------------------------------------------------
* Indicator IDs:
*   44 — Marginal contribution to poverty headcount
*   45 — Marginal contribution to inequality (Gini)
* Context:      EQU (Equity impact)
* Income:       ymp (id=1), yn (id=2), yd (id=4), yc (id=5)
* Instruments:  Each tax/transfer instrument
* Deciles:      n/a (scalar, by "all")
*--------------------------------------------------------------------------------
* Method: For each income Y and instrument X, create Y_inc_X = Y_pc + X_pc.
*         Then compute Gini(Y_inc_X) and FGT0(Y_inc_X).
*         Marginal contribution = indicator(Y) - indicator(Y_inc_X).
*         Sign convention: taxes are flipped negative before adding.
*--------------------------------------------------------------------------------
* Requires: 3-00-Setup.do to be included first.
*--------------------------------------------------------------------------------*/

*===============================================================================
*---> Marginal contributions to Gini and FGT0
*===============================================================================

u `output', clear

*---> Flip taxes to negative for the addition
local aux1 ${tax} ${indtax}
foreach var of local aux1 {
	replace `var'    = -`var'
	replace `var'_pc = -`var'_pc
}

*---> Generate counterfactual incomes: Y_inc_X = Y_pc + X_pc
local income2 ""
local aux2 ${tax} ${indtax} ${transfer} ${Subsidies} ${inkind}

foreach inc in ymp yn yd yc {
	foreach var of local aux2 {
		gen `inc'_inc_`var' = `inc'_pc + `var'_pc
		local income2 `income2' `inc'_inc_`var'
	}
}

*---> Restore original sign for taxes
foreach var of local aux1 {
	replace `var'    = -`var'
	replace `var'_pc = -`var'_pc
}

*---> Compute Gini and poverty for base + counterfactual incomes
sp_groupfunction [aw=pondih], gini(${income_pc} `income2') ///
	poverty(${income_pc} `income2') povertyline(${pline}) by(all)

*---> Keep only base income rows for computing marginal differences
* The full marginal contribution calculation requires subtracting
* indicator(Y_inc_X) from indicator(Y). This reshape is pending
* full implementation once the differencing logic is validated.

g indicator = measure
g context   = "equity"

* For now, save the raw components needed for marginal contributions
tempfile ind_3_05
save `ind_3_05'

di as text "Note: 3-05 saves raw Gini/FGT for base and counterfactual incomes."
di as text "      Marginal contributions = indicator(Y) - indicator(Y_inc_X)."
di as text "      Full differencing logic to be added in next iteration."
