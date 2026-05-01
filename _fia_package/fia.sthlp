{smcl}
{* *! version 0.1.0  01May2026}{...}
{vieweralsosee "fia core" "help fia_core"}{...}
{vieweralsosee "fia inequality" "help fia_inequality"}{...}
{vieweralsosee "fia poverty" "help fia_poverty"}{...}
{vieweralsosee "fia incidence" "help fia_incidence"}{...}
{vieweralsosee "fia concentration" "help fia_concentration"}{...}
{vieweralsosee "fia marginal" "help fia_marginal"}{...}
{vieweralsosee "fia coverage" "help fia_coverage"}{...}
{vieweralsosee "fia effectiveness" "help fia_effectiveness"}{...}
{vieweralsosee "fia redistribution" "help fia_redistribution"}{...}
{viewerjumpto "Syntax" "fia##syntax"}{...}
{viewerjumpto "Description" "fia##description"}{...}
{viewerjumpto "Subcommands" "fia##subcommands"}{...}
{viewerjumpto "Required variables" "fia##variables"}{...}
{viewerjumpto "Options" "fia##options"}{...}
{viewerjumpto "Examples" "fia##examples"}{...}
{viewerjumpto "Authors" "fia##authors"}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{cmd:fia} {hline 2}}Fiscal Incidence Analysis — standardized CEQ-based fiscal equity indicators{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:fia} {it:subcmd} [{it:varlist}] [{it:if}] [{it:in}] [{cmd:,} {it:options}]

{pstd}
where {it:subcmd} is one of the subcommands listed below.


{marker description}{...}
{title:Description}

{pstd}
{cmd:fia} produces a comprehensive set of CEQ-based fiscal incidence indicators 
from harmonized FIA microdata. The user loads their FIA-harmonized dataset and 
runs {cmd:fia core} to compute all indicators and export them to an Excel file 
following the FIA taxonomy (UniqueID system).

{pstd}
The package follows the architecture of the World Bank's 
{browse "https://github.com/worldbank/pea":PEA package}: a single entry point 
({cmd:fia}) dispatches to subcommand programs ({cmd:fia_inequality}, 
{cmd:fia_poverty}, etc.). Each subcommand can also be run individually 
for targeted analysis.


{marker subcommands}{...}
{title:Subcommands}

{p2colset 5 28 30 2}{...}
{p2col:{opt core}}Run all indicators and export to Excel. This is the main 
command for production use.{p_end}
{p2col:{opt setup}}Validate the loaded data and set globals (policies, 
income concepts, poverty lines). Called automatically by {cmd:core}.{p_end}
{p2col:{opt inequality}}Gini index (id=5), Theil index (id=66), 90-10 ratio 
(id=67), absolute Gini (id=68).{p_end}
{p2col:{opt poverty}}FGT0 headcount (id=4), FGT1 poverty gap (id=6), 
total poverty impact (id=47).{p_end}
{p2col:{opt incidence}}Netcash incidence by decile (id=37), conditional 
incidence (id=38).{p_end}
{p2col:{opt concentration}}Concentration shares by decile (id=39), by 
poor/non-poor (id=40), concentration coefficients (id=43), Kakwani (id=42).{p_end}
{p2col:{opt marginal}}Marginal contribution to poverty (id=44) and 
inequality (id=45).{p_end}
{p2col:{opt coverage}}Coverage by decile (id=52), coverage of poor (id=53), 
inclusion/exclusion errors (id=54-59).{p_end}
{p2col:{opt effectiveness}}CEQ impact effectiveness (id=48), CEQ spending 
effectiveness (id=49).{p_end}
{p2col:{opt redistribution}}Redistributive impact (id=46), 
Reynolds-Smolensky decomposition (id=69).{p_end}
{p2col:{opt shares}}Share of consumption/income by decile (id=60).{p_end}
{p2col:{opt export}}Merge taxonomy IDs (from correlative.xlsx) and export 
to Excel.{p_end}
{p2colreset}{...}


{marker variables}{...}
{title:Required variables in the loaded dataset}

{pstd}
The FIA-harmonized microdata must contain the following variables:

{p2colset 5 25 27 2}{...}
{p2col:{it:Variable}}Description{p_end}
{p2line}
{p2col:{cmd:hhid}}Household identifier{p_end}
{p2col:{cmd:pondih}}Household sampling weight{p_end}
{p2col:{cmd:ymp_pc}}Pre-fiscal (market + pensions) income, per capita{p_end}
{p2col:{cmd:yn_pc}}Net market income, per capita{p_end}
{p2col:{cmd:yd_pc}}Disposable income, per capita{p_end}
{p2col:{cmd:yc_pc}}Consumable income, per capita{p_end}
{p2col:{cmd:yf_pc}}Final income, per capita{p_end}
{p2col:{cmd:zref}}National food (extreme) poverty line{p_end}
{p2col:{cmd:line_1 line_2 line_3}}Additional poverty lines (national, PPP){p_end}
{p2col:{it:tax variables}}Direct taxes, contributions (per capita){p_end}
{p2col:{it:transfer variables}}Direct transfers (per capita){p_end}
{p2col:{it:indirect tax variables}}VAT, excises, customs (per capita){p_end}
{p2col:{it:in-kind variables}}Education, health in-kind (per capita){p_end}
{p2col:{it:subsidy variables}}Electricity, fuel, water subsidies (per capita){p_end}
{p2line}


{marker options}{...}
{title:Options}

{p2colset 5 30 32 2}{...}
{p2col:{opth tax(varlist)}}Direct tax variables (per capita). 
Default: {cmd:PIT_pc BIT_pc PropertyTax_pc FinancialTax_pc}{p_end}
{p2col:{opth contrib(varlist)}}Social contribution variables. 
Default: {cmd:sscontribs_total_pc}{p_end}
{p2col:{opth transfer(varlist)}}Direct transfer variables. 
Default: {cmd:am_prog_1_pc am_prog_2_pc am_prog_3_pc am_prog_other_pc}{p_end}
{p2col:{opth indtax(varlist)}}Indirect tax variables. 
Default: {cmd:CD_direct_pc excise_taxes_pc VAT_direct_pc VAT_indirect_pc}{p_end}
{p2col:{opth inkind(varlist)}}In-kind transfer variables. 
Default: {cmd:education_inKind_pc am_health_pc}{p_end}
{p2col:{opth subsidy(varlist)}}Subsidy variables. 
Default: {cmd:subsidy_elec_direct_pc ...}{p_end}
{p2col:{opth pline(varlist)}}Poverty line variables. 
Default: {cmd:zref line_1 line_2 line_3}{p_end}
{p2col:{opth output(string)}}Path to output Excel file.{p_end}
{p2col:{opth taxonomy(string)}}Path to correlative.xlsx taxonomy file.{p_end}
{p2col:{opth country(string)}}ISO3 country code for the sheet name.{p_end}
{p2colreset}{...}


{marker examples}{...}
{title:Examples}

{pstd}Minimal example — run all indicators on loaded data:{p_end}

{phang2}{cmd:. use "GMB_FIA_2015.dta", clear}{p_end}
{phang2}{cmd:. fia core, country(GMB) output("GMB_indicators.xlsx") taxonomy("correlative.xlsx")}{p_end}

{pstd}Run only inequality indicators:{p_end}

{phang2}{cmd:. use "SEN_FIA_2018.dta", clear}{p_end}
{phang2}{cmd:. fia inequality}{p_end}

{pstd}Run incidence with custom policy variables:{p_end}

{phang2}{cmd:. fia incidence, tax(PIT_pc BIT_pc) transfer(am_prog_1_pc am_prog_2_pc)}{p_end}


{marker authors}{...}
{title:Authors}

{pstd}Daniel Valderrama, The World Bank, {browse "mailto:dvalderrama1@worldbank.org":dvalderrama1@worldbank.org}{p_end}
{pstd}JM Monroy, The World Bank, {browse "mailto:jmonroypaez@worldbank.org":jmonroypaez@worldbank.org}{p_end}

{pstd}Inspired by the {browse "https://github.com/worldbank/pea":PEA package} 
by Minh Cong Nguyen, Sandra Segovia, and Henry Stemmler.{p_end}
