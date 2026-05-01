/*----------------------------------------------------------------------
  Example: Using the fia package for Fiscal Incidence Analysis
  
  This minimal example shows how to run the full FIA pipeline 
  on a harmonized microdata file and export results to Excel.
----------------------------------------------------------------------*/

* --- Preliminaries ---
clear all
set more off

* Point Stata to the fia package ado files
* (In production, install with: net install fia, from("..."))
adopath ++ "${root}/_fia_package"

* --- Load harmonized FIA microdata ---
use "${root}/microdata_GMB.dta", clear

* --- Option A: One-shot — run the entire pipeline ---
* Syntax: fia core [aw=weight], country(ISO) output(file.xlsx) taxonomy(file.xlsx)

fia core [aw=pondih], ///
    country(GMB) ///
    output("${root}/output/GMB_indicators.xlsx") ///
    taxonomy("${root}/../01-01-FIA_Metadata/correlative.xlsx") ///
    tax(PIT CIT) ///
    transfer(CCT UCT pensions) ///
    indtax(VAT excise) ///
    inkind(education health) ///
    subsidy(energy_sub food_sub) ///
    pline(zref line_1)

* --- Option B: Step-by-step — run individual subcommands ---
* Useful for debugging or when you only need specific indicators.

/*
* First set up globals
fia setup [aw=pondih], ///
    tax(PIT CIT) transfer(CCT UCT) indtax(VAT) ///
    inkind(education health) subsidy(energy_sub) pline(zref)

* Create deciles
quantiles ymp_pc [aw=pondih], gen(ymp_deciles_pc) nq(10)

* Run only inequality
fia inequality [aw=pondih]
* Results are in: ${fia_result_inequality}

* Run only poverty
fia poverty [aw=pondih]
* Results are in: ${fia_result_poverty}

* Run only coverage + targeting
fia coverage [aw=pondih]
* Results are in: ${fia_result_coverage}

* Run only concentration & Kakwani
fia concentration [aw=pondih]
* Results are in: ${fia_result_concentration}

* Export all computed indicators
fia export, output("output.xlsx") country(GMB) taxonomy("correlative.xlsx")
*/

* --- Option C: Fine-grained results access ---
* After running subcommands, each saves results in a global tempfile.
* You can load and inspect them:

/*
use ${fia_result_inequality}, clear
list if indicator == "gini"

use ${fia_result_poverty}, clear
list if indicator == "fgt0"

use ${fia_result_concentration}, clear
list if indicator == "kakwani"
*/
