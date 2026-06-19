/*============================================================================*\
 Revamp policy registry
 Adapted from 0-01-aux_policy_list.do, exported as globals for cross-file use
\*============================================================================*/

di as txt "Loading revamp policy registry"

* Canonical fiscal policy families
global Directaxes "PIT BIT PropertyTax FinancialTax"
global Contributions "sscontribs_total"
global DirectTransfers "am_prog_1 am_prog_2 am_prog_3 am_prog_other"
global Subsidies "subsidy_elec_direct subsidy_elec_indirect subsidy_fuel_direct subsidy_fuel_indirect subsidy_water_direct subsidy_water_indirect subsidy_agric"
global Indtaxes "CD_direct excise_taxes VAT_direct VAT_indirect"
global InKindTransfers "education_inKind am_health"

* Convenience sets used in validation scripts
global var_dtr "${Directaxes} ${Contributions} ${DirectTransfers} ${Subsidies} ${Indtaxes} ${InKindTransfers}"

* Income concepts expected in active pipeline
global IncomeConcepts "ymp yn yd yc yf"
