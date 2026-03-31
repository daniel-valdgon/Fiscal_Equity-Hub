cap program drop margCont 
program define margCont
	version 16.0
	syntax[, ginDef(varname) povDef(varname) income(varname) taxes(varlist) included(varlist) excluded(varlist) pcweight(varname) data(string) pline(varname) positivetax EXPORTFile(string) EXPORTSHeet(string) restore]

	if "`restore'" == "restore"{
		preserve 
	}
		loc varlist `included' `excluded'
		loc keeplist `varlist' `income' `povDef' `ginDef' `pcweight' `pline'
		disp "`keeplist'" 
		keep `keeplist'	

	* Convert variable names into locals for labeling later on 
		foreach var in `varlist'{
			local lbl : variable label `var'
			local `var'_lbl "`lbl'"
			disp "``var'_lbl'"
		}

	 	if "`positivetax'" == "positivetax" {
			di in red "{Converting tax variables to negative}"
			foreach v in `taxes'{
				replace `v' = -`v'
			} 
		}
		else {
			di in red "{Checking that tax variables are already negative}"
			foreach v in `taxes'{
				assert `v' <= 0
			} 		
		} 

		if "`ginDef'" != ""{
			foreach v of varlist `varlist' `income'{
				disp "Deflating for the Gini calculations."
				g `v'_def = `v'/`ginDef'
			}
		}
		if "`povDef'" != "" & "`povDef'" != "`ginDef'"{
			foreach v of varlist `varlist' `income'{
				disp "Deflating for the Poverty calculations."
				g `v'_def = `v'/`povDef'
			}
		}



* Marginal contribution 
	loc y `income'
	loc x = substr("`y'", 1, 2)
	foreach i in `included'{
		loc z = substr("`i'", 1, strlen("`i'") - 3)
		di "`y' less `i'"
		g `x'_`z' = `y' - `i'
		lab var `x'_`z' "Income w/o $`i'" 
		
		if "`ginDef'" != "" | "`povDef'" != ""{
			g `x'_`z'_d = `y'_def - `i'_def
			lab var `x'_`z'_d "Income w/o `i' (defl.)" 
		}
	}

	foreach i in `excluded'{
		loc z = substr("`i'", 1, strlen("`i'") - 3)
		di "`y' plus `i'"
		g `x'_`z' = `y' + `i'
		lab var `x'_`z' "Income w. $`i'"
		
		if "`ginDef'" != "" | "`povDef'" != ""{
			g `x'_`z'_d = `y'_def + `i'_def
			lab var `x'_`z'_d "Income w. `i' (defl.)"
		}
	}

	// Calculate inequality and poverty for the extended income concepts
	
	if "`ginDef'" != ""{
		qui ineqdeco `y'_def [w = `pcweight']
		g gi_`x' = r(gini)*100
		foreach i in `varlist'{
			loc z = substr("`i'", 1, strlen("`i'") - 3)
			qui ineqdeco `x'_`z'_d [w = `pcweight']
			g gi_`x'_`z' = r(gini)*100
		}
	}
	else{
		qui ineqdeco `y' [w = `pcweight']
		g gi_`x' = r(gini)*100
		foreach i in `varlist'{
			loc z = substr("`i'", 1, strlen("`i'") - 3)
			qui ineqdeco `x'_`z' [w = `pcweight']
			g gi_`x'_`z' = r(gini)*100
		}
	} 
		
	if "`povDef'" != ""{
		qui povdeco `y'_def [w = `pcweight'], varpl(`pline')
		g ph_`pline'_`x' = r(fgt0)*100
		g pg_`pline'_`x' = r(fgt1)*100

		foreach i in `varlist'{
			loc z = substr("`i'", 1, strlen("`i'") - 3)
			qui povdeco `x'_`z'_d [w = `pcweight'], varpl(`pline')   
			g ph_`x'_`z' = r(fgt0)*100
			g pg_`x'_`z' = r(fgt1)*100
		} 
	}
	else{
		qui povdeco `y' [w = `pcweight'], varpl(`pline')
		g ph_`pline'_`x' = r(fgt0)*100
		g pg_`pline'_`x' = r(fgt1)*100

		foreach i in `varlist'{
			loc z = substr("`i'", 1, strlen("`i'") - 3)
			qui povdeco `x'_`z' [w = `pcweight'], varpl(`pline')   
			g ph_`x'_`z' = r(fgt0)*100
			g pg_`x'_`z' = r(fgt1)*100
		} 
	}
							
		* Calculate marginal contributions as the value WITHOUT the variable less the value WITH the variable 
		if "`included'" != ""{
			foreach i in `included'{
				loc z = substr("`i'", 1, strlen("`i'") - 3)
				g mcgi_`x'_`z' = gi_`x'_`z' - gi_`x'
				g mcph_`x'_`z' = ph_`x'_`z' - ph_`pline'_`x'
				g mcpg_`x'_`z' = pg_`x'_`z' - pg_`pline'_`x'
			} 	
		}

		* For education and health
		if "`excluded'" != ""{
			foreach i in `excluded'{
				loc z = substr("`i'", 1, strlen("`i'") - 3)
				g mcgi_`x'_`z' = gi_`x' - gi_`x'_`z'
				g mcph_`x'_`z' = ph_`pline'_`x' - ph_`x'_`z'
				g mcpg_`x'_`z' = pg_`pline'_`x' - pg_`x'_`z'
			} 
		}
		loc mcList mcgi_`x'_ mcph_`x'_ mcpg_`x'_
		disp "`mcList'"

	//reshape long so that you have the variable on the rows, and the type of indicator on the columns 
	g id = _n  
	loc n = 0
	foreach i in `varlist'{
		loc z = substr("`i'", 1, strlen("`i'") - 3)
		loc ++n 
		disp `n'
		loc lab`n' = "``i'_lbl'"	
		foreach j in `mcList'{   //foreach variable, and for each indicator (i.e. mcgi, mcph, mcpg)
			ren (`j'`z') (`j'`n')
		} 
	}
	disp "`lab1'"

	keep id mc*
	keep if _n == 1
	reshape long `mcList', i(id) j(instrument)		
	ren (*_) (*)
 
	lab var instrument "Fiscal instrument"
	lab def instrument_lbl 1"`lab1'" 2"`lab2'" 3"`lab3'" 4"`lab4'" 5"`lab5'" 6"`lab6'" 7"`lab7'" 8"`lab8'" 9"`lab9'" 10"`lab10'" ///
	11"`lab11'" 12"`lab12'" 13"`lab13'" 14"`lab14'" 15"`lab15'" 16"`lab16'" 17"`lab17'" 18"`lab18'" 19"`lab19'" 20"`lab20'" ///
	21"`lab21'" 22"`lab22'" 23"`lab23'" 24"`lab24'" 25"`lab25'" 26"`lab26'" 27"`lab27'" 28"`lab28'" 29"`lab29'" 30"`lab30'" ///
	31"`lab31'" 32"`lab32'" 33"`lab33'" 34"`lab34'" 35"`lab35'" 36"`lab36'" 37"`lab37'" 38"`lab38'" 39"`lab39'" 40"`lab40'" ///
	41"`lab41'" 42"`lab42'" 43"`lab43'" 44"`lab44'" 45"`lab45'" 46"`lab46'" 47"`lab47'" 48"`lab48'" 49"`lab49'" 50"`lab50'" ///
	51"`lab51'" 52"`lab52'" 53"`lab53'" 54"`lab54'" 55"`lab55'" 56"`lab56'" 57"`lab57'" 58"`lab58'" 59"`lab59'" 60"`lab60'" ///
	61"`lab61'" 62"`lab62'" 63"`lab63'" 64"`lab64'" 65"`lab65'" 66"`lab66'" 67"`lab67'" 68"`lab68'" 69"`lab69'" 70"`lab70'" ///
	71"`lab71'" 72"`lab72'" 73"`lab73'" 74"`lab74'" 75"`lab75'" 76"`lab76'" 77"`lab77'" 78"`lab78'" 79"`lab79'" 80"`lab80'",  replace

	lab val instrument instrument_lbl
	foreach y in `income'{
		lab var mcgi_`x' "Gini (`x')"
		lab var mcph_`x' "Headc. (`x')"
		lab var mcpg_`x' "Gap (`x')"
	}		
	drop id 
		
	* Save and export the data
		if "`data'" != ""{
			save "`data'", replace
		}
		if "`exportfile'" != ""{
			export excel "`exportfile'", sheet("`exportsheet'") first(varl) cell(A1) sheetmodify keepcellfmt
			if "`exportfile'" == ""{
				di in red "Error: Specify a sheet name!"
				exit 198
			}
			if _rc {
			    di "Excel export failed. Try creating the file first or check sheet name."
			}	
		}
		else{
			di "Failure to specify an Excel output spreadsheet. No Excel results produced."
		}
	if "`restore'" == "restore"{
		restore
	}
end



/* Still to do: 
	Get the ado to run in the case where we submit more than one income concept. 
*/
