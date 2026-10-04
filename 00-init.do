/*============================================================================*\
 Project: Fiscal Equity Hub 
 Authors: Juan Manuel Monroy, Daniel Valderrama and Silvia Ortiz
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
