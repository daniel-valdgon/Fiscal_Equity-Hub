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

*---> Compute marginal contributions by differencing
* MC_gini(Y, X) = Gini(Y) - Gini(Y_inc_X)
* MC_fgt0(Y, X) = FGT0(Y) - FGT0(Y_inc_X)

tempfile mc_raw
save `mc_raw'

* --- MC to Inequality (id=45): Gini(Y) - Gini(Y_inc_X) ---
u `mc_raw', clear
keep if indicator == "gini"

* Separate base incomes from counterfactual
gen is_base = 0
foreach inc in ymp_pc yn_pc yd_pc yc_pc {
	replace is_base = 1 if variable == "`inc'"
}

* Save base Gini values to tempfile
tempfile gini_base
preserve
	keep if is_base == 1
	rename value gini_base
	rename variable base_inc
	keep base_inc gini_base
	save `gini_base'
restore

* Counterfactual Gini values — parse income and instrument from variable name
keep if is_base == 0
* variable format: inc_inc_instrument (e.g. ymp_inc_PIT)
gen base_inc = ""
gen mc_instrument = ""
foreach inc in ymp yn yd yc {
	replace base_inc = "`inc'_pc" if strpos(variable, "`inc'_inc_") == 1
	replace mc_instrument = subinstr(variable, "`inc'_inc_", "", 1) if base_inc == "`inc'_pc"
}

merge m:1 base_inc using `gini_base', nogen keep(match)
gen mc_value = gini_base - value

keep base_inc mc_instrument mc_value
rename base_inc income
rename mc_instrument variable
rename mc_value value
gen measure   = "mc_gini"
gen indicator = "mc_gini"
gen context   = "equity"
gen deciles_pc = .
gen instrument = variable

tempfile mc_gini
save `mc_gini'

* --- MC to Poverty (id=44): FGT0(Y) - FGT0(Y_inc_X) ---
u `mc_raw', clear
keep if indicator == "fgt0"

gen is_base = 0
foreach inc in ymp_pc yn_pc yd_pc yc_pc {
	replace is_base = 1 if variable == "`inc'"
}

tempfile fgt_base
preserve
	keep if is_base == 1
	rename value fgt_base
	rename variable base_inc
	keep base_inc fgt_base reference
	save `fgt_base'
restore

keep if is_base == 0
gen base_inc = ""
gen mc_instrument = ""
foreach inc in ymp yn yd yc {
	replace base_inc = "`inc'_pc" if strpos(variable, "`inc'_inc_") == 1
	replace mc_instrument = subinstr(variable, "`inc'_inc_", "", 1) if base_inc == "`inc'_pc"
}

merge m:1 base_inc reference using `fgt_base', nogen keep(match)
gen mc_value = fgt_base - value

keep base_inc mc_instrument mc_value reference
rename base_inc income
rename mc_instrument variable
rename mc_value value
gen measure   = "mc_fgt0"
gen indicator = "mc_fgt0"
gen context   = "equity"
gen deciles_pc = .
gen instrument = variable

tempfile mc_fgt0
save `mc_fgt0'

* --- Append MC results ---
u `mc_gini', clear
append using `mc_fgt0'

tempfile ind_3_05
save `ind_3_05'
