

* This code create names for the harmonized variables with their own policies
* Lists of policies by dimension, it should be used as a reference for the names of the folders and data files. 
* It should be updated when new policies are added to the database.

dis "Loading policies list"

local dirtax		"PIT BIT PropertyTax FinancialTax"
local ssc			"sscontribs_total"
local dirtra		"am_prog_1 am_prog_2 am_prog_3 am_prog_other"
local subs			"subsidy_elec_direct subsidy_elec_indirect subsidy_fuel_direct subsidy_fuel_indirect subsidy_water_direct subsidy_water_indirect subsidy_agric"
local indtax 		"CD_direct excise_taxes VAT_direct VAT_indirect"
local inktra 		"education_inKind am_health" 