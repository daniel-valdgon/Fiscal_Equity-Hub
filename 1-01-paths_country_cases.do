*---------------------------------------------------------------
* Paths for specific contry case
*---------------------------------------------------------------

* EQUATORIAL GUINEA (GNQ 2022 ENH2)
if "${country}"=="GNQ" & "$survey_year" =="2022" & "$survey" =="ENH2"{
	global country_data "${microdata}/${country}/GNQ_ENH2_S2022_P2022_v01"
	global HFMD_data "${country_data}/HFMD"
	global file "HFMD_GNQ_S2022_P2022_v01"
	global GMD_file ""
}

* SENEGAL (SEN 2021 EHCVM)
else if "${country}"=="SEN" & "$survey_year" =="2021" & "$survey" =="EHCVM"{
	global country_data "${microdata}/${country}/SEN_EHCVM_S2021_P2021_v01"
	global HFMD_data "${country_data}/HFMD"
	global file "HFMD_SEN_S2021_P2021_v01"
	global GMD_file  "${country_data}\Master_data\data_raw\other_harmonization\GMD\SEN_2021_EHCVM_V01_M_V02_A_GMD_ALL.dta"
}

* MAURITANIA (MRT 2019 EPCV)
else if "${country}"=="MRT" & "$survey_year" =="2019" & "$survey" =="EPCV"{
	global country_data "${microdata}/${country}/MRT_EPCV_S2019_P2019_v01"
	global HFMD_data "${country_data}/HFMD"
	global file "HFMD_MRT_S2019_P2019_v01"
	global GMD_file  "${country_data}\Master_data\data_raw\other_harmonization\GMD\MRT_2019_EPCV_V01_M_V02_A_GMD_ALL.dta"
}

* GAMBIA (GMB 2020 IHS)
else if "${country}"=="GMB" & "$survey_year" =="2020" & "$survey" =="IHS"{
	global country_data "${microdata}/${country}/GMB_IHS_S2020_P2020_v01"
	global HFMD_data "${country_data}/HFMD"
	global file "HFMD_GMB_S2020_P2020_v01"
	global GMD_file  "${country_data}\Master_data\data_raw\other_harmonization\GMD\GMB_2020_IHS_V02_M_V03_A_GMD_ALL.dta"
}

* COLOMBIA (COL 2021 GEIH)
else if "${country}"=="COL" & "$survey_year" =="2021" & "$survey" =="GEIH"{
	global country_data "${microdata}/${country}/COL_GEIH_S2021_P2021_v01"
	global HFMD_data "${country_data}/HFMD"
	global file "COL_GEIH_S2021_P2021_v01"
	global GMD_file  "${country_data}\Master_data\data_raw\other_harmonization\GMD\COL_2021_GEIH_V02_M_V01_A_GMD_ALL.dta"
}

* ECUADOR (ECU 2024 ENEMDU)
else if "${country}"=="ECU" & "$survey_year" =="2024" & "$survey" =="ENEMDU"{
	global country_data "${microdata}/${country}/ECU_ENEMDU_S2024_P2024_v01"
	global HFMD_data "${country_data}/HFMD"
	global file "ECU_ENEMDU_S2024_P2024_v01"
	global GMD_file "${country_data}\Master_data\data_raw\other_harmonization\GMD\ECU_2024_ENEMDU_V01_M_V01_A_GMD_ALL.dta"
}

* ANGOLA (AGO 2018 IDREA)
else if "${country}"=="AGO" & "$survey_year" =="2018" & "$survey" =="IDREA"{
	global country_data "${microdata}/${country}/AGO_IDREA_S2018_P2023_v01"
	global HFMD_data "${country_data}/HFMD"
	global file "HFMD_AGO_S2018_P2023_v01"
	global GMD_file 	"${country_data}\Master_data\data_raw\other_harmonization\GMD\AGO_2018_IDREA_V01_M_V01_A_GMD_GPWG.dta"
}

* SRI LANKA (LKA 2019 HIES)
else if "${country}"=="LKA" & "$survey_year" =="2019" & "$survey" =="HIES"{
	global country_data "${microdata}/${country}/LKA_HIES_S2019_P2024_v01"
	global HFMD_data "${country_data}/HFMD"
	global file "HFMD"
	global GMD_file ""
}

* MONGOLIA (MNG 2022 HSES)
else if "${country}"=="MNG" & "$survey_year" =="2022" & "$survey" =="HSES"{
	global country_data "${microdata}/${country}/MNG_HSES_S2022_P2022_v01"
	global HFMD_data "${country_data}/HFMD"
	global file "HFMD"
	global GMD_file ""
}
