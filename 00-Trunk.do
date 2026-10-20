/*============================================================================*\
 Project: Fiscal Equity Hub 
 Authors: Juan Manuel Monroy, Daniel Valderrama and Silvia Ortiz
 Start Date: February 2025
 Update Date: September 2026
 Version: 0.1
\*============================================================================*/

* Validation-only workflow: read saved HFMD.
* Configure paths with 00-init.do first. No construction do-file is called.
* The saved HFMD must already contain the complete pc/ae and poverty schema.
* National poverty uses zref1 and the country's official division_unit.
* International poverty uses yd_inat_pov_2021, always per capita, including ae countries.

version 17
set more off
if "$scripts" == "" {
    display as error "Run 00-init.do first."
    exit 198
}

* Country-survey configuration
*global run_countries `" "GNQ 2022 ENH2" "SEN 2021 EHCVM" "MRT 2019 EPCV" "GMB 2020 IHS" "COL 2021 GEIH" "ECU 2024 ENEMDU" "AGO 2018 IDREA" "LKA 2019 HIES" "MNG 2022 HSES" "MDV 2019 HIES" "'
global run_countries `" "LKA 2019 HIES" "'

foreach config of global run_countries {
	global run_country "`config'"
    global country     : word 1 of $run_country
	global survey_year : word 2 of $run_country
    global survey      : word 3 of $run_country

	include "${scripts}/1-01-paths_country_cases.do"
	
    di as result "Running ${run_country}"
	di as result "---------------------------"
	sleep 3000


*============================================================================*
**# 1. Data infrastrucure
*============================================================================*

* Obj: This section will include protocols to revise the databases, q-check over the FIA data

* It create a dataset with information available in the datalab and save it
* It should be uploaded to Github, it should request documentation everytime is modified, it should run regular backups 

* Household database
use "$HFMD_data/${file}_h", clear

* A. Verifies that all expected variables are present, drops extra variables, and checks that variables are either populated or completely empty. Completely missing fiscal instrument variables indicate that the instrument or program was not simulated
include "${scripts}/1-02-datastructure_complete_variables.do"

* B. Verifies that combined spatial-temporal deflators are equal to the product of the corresponding spatial and temporal deflators.
include "${scripts}/1-03-datastructure_deflators_check.do"

*============================================================================*
**# 2. Reproducibility Harmonize Fiscal Microdata (only needed once, create a log that validates if data was replaced or not, if it was replaced, create a log with the changes and the reason for the change)
*============================================================================*

* A. Verifies that each fiscal instrument total is equal to the sum of its lower-level components. For example, total electricity subsidies should equal the sum of direct and indirect electricity subsidies.
include "${scripts}/2-01-datacheck_fiscal_instruments.do"

* B. Verifies that income concepts can be reconstructed from disposable income and the corresponding fiscal instruments, using a small tolerance for rounding and aggregation differences.
include "${scripts}/2-02-datacheck_incomes.do"

* C. Loads selected poverty and inequality indicators from the FIA metadata file filled by the poverty economist, and compares them against indicators replicated from the microdata using the national poverty line.
include "${scripts}/2-03-datacheck_fia_metadata.do"

* D. International poverty line
   * Loads international poverty estimates from PIP for the same country, survey year, and survey acronym used in the FIA.
   * Replicates international poverty rates from the microdata using disposable income and the available PPP poverty lines.
include "${scripts}/2-04-data_check_report.do"


* E. Merge with GMD database
*include "${scripts}/2-05-data_check_GMDmerge.do"

di as result "Ended ${run_country}"
di as result "---------------------------"
	sleep 3000
}