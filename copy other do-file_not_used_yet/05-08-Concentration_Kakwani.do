/*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program:  GSG3 Fiscal Equity Hub - Concentration & Kakwani
* Author:   Daniel Valderrama & JM Monroy
* Date:     May 2026
* Title:    Concentration coefficients and Kakwani index
*--------------------------------------------------------------------------------
* Indicator IDs:
*   42 — Kakwani index
*   43 — Concentration coefficients
*   39 — Concentration shares by decile
* Context:      EQU (Equity impact)
* Income:       Pre-fiscal (ymp, id=1)
* Instruments:  All fiscal instruments
* Deciles:      Scalar (Kakwani/CC) or 1-10 (concentration shares)
*--------------------------------------------------------------------------------
* Requires: 3-00-Setup.do to be included first.
*--------------------------------------------------------------------------------*/

*===============================================================================
*---> Concentration coefficients, Kakwani index, concentration shares
*     - CC: rank by income, compute Gini-like coefficient on instrument
*     - Kakwani = CC - Gini(income)
*     - Concentration shares: share of total instrument by decile
*===============================================================================

* NOTE: This module is a placeholder for the full implementation.
*       The sp_groupfunction command with benefits() provides the
*       building blocks for concentration shares. The Kakwani index
*       requires the Gini of income (from 3-03) and the concentration
*       coefficient of each instrument.

u `output', clear

* Concentration shares via benefits
sp_groupfunction [aw=pondih], benefits(${concs_pc}) by(ymp_deciles_pc)
ren ymp_deciles_pc deciles_pc

g indicator = "benefits"
g context   = "equity"

* Map instrument
g instrument = variable

* Filter: only instrument-level benefits (not income concepts)
* codes defined in 3-00-Setup.do as global

gen income = ""
forvalues k = 1/5 {
	local code : word `k' of ${codes}
	replace income = "`code'" if variable == "`code'"
}

drop if income != ""
drop income

tempfile ind_3_08
save `ind_3_08'

di as text "Note: 3-08 saves concentration shares (benefits by decile)."
di as text "      Kakwani = CC(instrument) - Gini(income)."
di as text "      Full Kakwani computation to be added in next iteration."
