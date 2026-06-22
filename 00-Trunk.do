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


* Country to evaluate
global country "GNQ"
global survey_year 2022
global survey "ENH2"

if "${country}"=="GNQ" & "$survey_year" =="2022" & "$survey" =="ENH2"{
	global country_data "${microdata}/${country}/GNQ_ENH2_S2022_P2022_v01"
	global HFMD_data "${country_data}/HFMD"
	global file "HFMD_GNQ_S2022_P2022_v01"
}

*============================================================================*
//	1. Data infrastrucure
*============================================================================*
* Obj: This section will include protocols to revise the databases, q-check over the FIA data

* A. Creat percapita/peradul equivalent, y versiones national in real terms e international in real terms  
* It create a dataset with information available in the datalab and save it
* It should be uploaded to Github, it should request documentation everytime is modified, it should run regular backups 
* Name of files should adapt to the ID shared by Pechi (Now)

qui: include "${scripts}/1-01-Inventory.do"
*dis `"`file_list'"'

* A. Policy List  & income concept
/*Loading list of policies*/ include "${scripts}/0-01-aux_policy_list.do"
*local misscellaneuos "hhweight deciles_pc hhsize"

*Todas las variables del fiscal instrument, y o la variable tiene todo en numeros o todo en missing 


* C. Sp_temp deflato is the multiplication of spatial and temp t


*============================================================================*
//	2. Reproducibility Harmonize Fiscal Microdata (only needed once, create a log that validates if data was replaced or not, if it was replaced, create a log with the changes and the reason for the change)
*============================================================================*
use "$HFMD_data/${file}_h", clear


* A. Checking consistency between different levels of fiscal instruments, for example: total electricity should be equal to direct and indirect effect of electricity 
include "${scripts}/2-01-datacheck_fiscal_instruments.do"

* B. Checking income concept 
include "${scripts}/2-02-datacheck_incomes.do"

* C. Poverty and Inequality indicators from FIA background report (National poverty line)
   * Load metadata FIA excel file, filled by the poverty economist 
   * Compare the results in the report with the resutls from the microdata, minimal tolerance for differences 

include "${scripts}/2-03-datacheck_fia_metadata.do"

* D. International poverty line
   * Load poverty and inequality from PIP, ensure is the same household survey than the one used in the FIA, 
   * Test poverty with all PPP values available in PIP an dll poverty lines for disposable income
   *allow for 1 percentage points difference, if the test fails bit input 19 from FIA MEtada is different from missing then continue bubt document the percentage point difference for PPP 2021, average across thre three lines

include "${scripts}/2-04-data_check_report.do"
*============================================================================*
//	3. Calculations and data checks on Indicators 
*============================================================================*
*all indicators computed here separated in different groups but not more validation checks
include "${scripts}/3-01-Incidences.do"




exit

	
