/*============================================================================*\
 Project: Fiscal Equity Hub 
 Authors: Juan Manuel Monroy and Daniel Valderrama
 Start Date: February 2025
 Update Date: April 2025
 Version: 0.1
\*============================================================================*/

   clear all
   timer clear 1
   timer on 1
   
*---> Define user paths
if "`c(username)'"=="wb419055" {
	global root     	"C:\Users\wb419055\OneDrive - WBG\GSG3\GSG Fiscal Equity - WB Group - Fiscal Equity Hub\Workspace\Data Hub"	
   global scripts		"${root}/02-Scripts/wb419055"
}

if "`c(username)'"=="wb527706" {
	global root     	"C:\Users\wb527706\OneDrive - WBG\GSG Fiscal Equity - WB Group - Data-Hub"	
   global scripts		"${root}/02-Scripts/wb527706"
}

else if "`c(username)'"=="wb527706" {
	global root     	"C:\Users\wb527706\OneDrive - WBG\Data Hub"	
}

else if "`c(username)'"=="Silvia" {
	global root     	"C:\Users\Silvia\OneDrive\World Bank\Projects\Data-Hub"	
   global scripts		"${root}/02-Scripts/Silvia"
}

*---> Input folders: Country economists will share either the microdata or the core indicators, if both are shared, the code should validate the consistency between them.	

global rawdata    		"${root}/01-Data/01-01-FRP" // includes .do and raw data: Upcoming replication packages MML
global microdata   		"${root}/01-Data/01-02-FIA_Microdata" // save the FMD files here, with the same naming structure, when FRP is not shared
global template    		"${root}/01-Data/01-03-FIA_Core Indicators" // FCI Save the core indicators when FMD is not shared

*---> Temporary data pipeline 
global tempsim			"${root}/01-Data/3_temp_sim" // 2 folders


*Bronze database  
global fia-data			"${root}/04-Products/00-FIA-Database/AFW_Sim_tool_Output.csv"

global core_database	"${root}/04-Products/00-FIA-Database/Core_Database.xlsx"


* Country-survey configuration
*global run_countries `" "GNQ 2022 ENH2" "SEN 2021 EHCVM" "MRT 2019 EPCV" "GMB 2020 IHS" "COL 2021 GEIH" "AGO 2018 IDREA" "LKA 2019 HIES" "MNG 2022 HSES" "ECU 2024 ENEMDU" "'
global run_countries `" "SEN 2021 EHCVM" "'
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

* C. Applies the official household size adjustment, either per capita or adult equivalent, and creates income variables in real terms for national and international poverty measurement.
include "${scripts}/1-04-datastructure_unit_adjust_real_terms.do"

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

tempfile ${country}_${survey_year}_${survey}
save `${country}_${survey_year}_${survey}', replace

* E. Merge with GMD database
include "${scripts}/2-05-data_check_GMDmerge.do"

di as result "Ended ${run_country}"
di as result "---------------------------"
	sleep 3000
	
}
exit

	
