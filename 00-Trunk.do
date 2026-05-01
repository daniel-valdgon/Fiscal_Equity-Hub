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
}

if "`c(username)'"=="wb527706" {
	global root     	"C:\Users\wb527706\OneDrive - WBG\Data Hub"	
}



*---> Input folders: Country economists will share either the microdata or the core indicators, if both are shared, the code should validate the consistency between them.	

global rawdata    		"${root}/01-Data/01-01-FRP" // includes .do and raw data: Upcoming replication packages MML
global microdata   		"${root}/01-Data/01-02-FIA_Microdata" // save the FMD files here, with the same naming structure, when FRP is not shared
global template    		"${root}/01-Data/01-03-FIA_Core Indicators" // FCI Save the core indicators when FMD is not shared

*---> Temporary data pipeline 
global tempsim			"${root}/01-Data/3_temp_sim" // 2 folders


*Bronze database  
global fia-data			"${root}/04-Products\00-FIA-Database/AFW_Sim_tool_Output.csv"

global core_database	"${root}/04-Products/00-FIA-Database/Core_Database.xlsx"


*============================================================================*
//	1. Revise data infrastructure/ Load all countries
*============================================================================*

* A. Data file 
* It create a dataset with information available in the datalab and save it
* It should be uploaded to Github, it should request documentation everytime is modified, it should run regular backups 
* Name of files should adapt to the ID shared by Pechi (Now)

qui: include "${root}/02-Scripts/wb419055/1-01-Inventory.do"
*dis `"`file_list'"'

* B. Policy List  
/*Loading list of policies*/ include "${root}/02-Scripts/wb419055/0-01-aux_policy_list.do"
*local misscellaneuos "hhweight deciles_pc hhsize"

*============================================================================*
//	2. Harmonize Fiscal Microdata (only needed once, create a log that validates if data was replaced or not, if it was replaced, create a log with the changes and the reason for the change)
*============================================================================*

include "${root}/02-Scripts/wb419055/2-01-MFMD2HFMD.do"

include "${root}/02-Scripts/wb419055/2-02-MFMD2HFMD_2nd_variables.do"

include "${root}/02-Scripts/wb419055/2-03-data_check_report.do"

*============================================================================*
//	3. Calculations and data checks on Indicators 
*============================================================================*


include "${root}/02-Scripts/wb419055/3-01-Incidences.do"




exit

	
