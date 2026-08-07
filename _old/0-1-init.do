*Initialize work environment

global suser = c(username)

clear all
set more off
cap set maxvar 10000
set seed 23081980 
set sortseed 11041985
version 17

*Define username
global suser = c(username)

*Install packages used in the process
local commands = "ineqdeco grstyle pyramid_chart waffle vselect missings   diff outreg2 spider geodist vincenty fastgini tabout logout shp2dta coefplot spmap distinct clonevar splitvallabels indeplist confirmdir wbopendata mdesc heatplot" //palettes  graphfunctions colrspace moremata (this code should be added in this list if you are running maps for the first time or other elaborated graphs)
local commands_removed = "dropmiss lassoregress"
local commands_added = "elasticregress"
local commands_edited = "`commands' `commands_added'"
foreach c of local commands_edited {
	qui capture which `c' 
	qui if _rc!=0 {
		noisily di "This command requires '`c''. The package will now be downloaded and installed."
		ssc install `c'
	}
}

*Daniel
else if (inlist("${suser}","wb419055", "wb419055")) {
	
	
		
			*Local directory of the Git repository (not necessarily the same as the project folder)
			global gdDo = "C:\Users\wb419055\OneDrive - WBG\GSG3\GSG Fiscal Equity - WB Group - Fiscal Equity Hub\Workspace\Data-Hub\01-Data\01-02-FIA_Microdata"
		
			*Local directory of the project folder
			local ldAnalysis = "C:\Users\wb419055\OneDrive - WBG\GSG3\GSG Fiscal Equity - WB Group - Fiscal Equity Hub\Workspace\Data-Hub\01-Data\01-02-FIA_Microdata"
			
			*Local of Rawdata (same in this case as project folder but not necesssarily in a bigger project)
			global gdData	= "$ldAnalysis"
}
*Silvia
else if (inlist("${suser}", "Silvia", "Silvia")) {
	*Local directory of the repository
	global gdDo = "C:\Users\Silvia\OneDrive\World Bank\Projects\GNQ-PA\2-scripts\Silvia\EQG-Poverty-Assesment"
	
	*Local directory to the shared folder
	local ldAnalysis = "C:\Users\Silvia\OneDrive\World Bank\Projects\GNQ-PA"
	
	*Local of data (it could be inside or outside the project's  folder)
	global gdData	= "`ldAnalysis'/1-Data"
	


}

include "$gdDo/_set_up.do"

*If needed, create directories, and sub-directories used in the process 
foreach d in "${gdData}" "${gdOutput}" "${gdTemp}" "${microdata}" {
	confirmdir "`d'" 
	if _rc!=0 mkdir "`d'" 
}



global countrylist = "GNQ SEN GMB MRT"

foreach c of global countrylist {
	
	local scripts: dir "$gdDo/`c'" files "*.do"

	d
	foreach s of local scripts {
		di as txt "Running $s"
		*do "$gdDo/`c'/$s"
	}

}


