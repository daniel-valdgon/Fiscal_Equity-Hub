* Maya Goldman 
* July 2025 

cap program drop fiscTotals 
program define fiscTotals
	version 16.0
	syntax varlist(min = 1) [, pcweight(string) unit(integer 1) data(string) SCALEFactor(real 1) EXPORTFile(string) EXPORTSHeet(string) restore]

	if "`restore'" == "restore"{
			preserve 
	} 
		loc keeplist `varlist' `pcweight'
		keep `keeplist'	

		foreach v in `varlist' {
			assert !mi(`v')
		}

	* Convert variable names into locals for labeling later on 
		foreach v in `varlist' {
			local lbl : variable label `v'
			local `v'_lbl "`lbl'"
			disp "``v'_lbl'"
		}
		
	* Collapse the dataset  
		collapse (sum) `varlist'  [pw=`pcweight']


	* Concentration shares
	foreach i in `varlist'{
		qui sum `i' 
		gen tot_`i' = r(sum)

		loc j = "``i'_lbl'"
		disp "`j'"
		lab var tot_`i' "`j'"
	}
	keep tot_*

	//reshape long so that you have the variable on the rows, and the type of indicator on the columns 
	g id = _n  
	loc n = 0
	foreach i in `varlist'{
		loc ++n 
		disp `n'
		loc lab`n' = "``i'_lbl'"	
		ren (tot_`i') (tot_`n') 
	}
	disp "`lab1'"

	keep id tot*
	keep if _n == 1
	reshape long tot_, i(id) j(instrument)		
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
	lab var tot "Survey total"
	drop id

	if `scalefactor' != 1{
		clonevar totScaled = tot
		replace totScaled = totScaled*`scalefactor'
	}

	if "`unit'" == "6"{
		replace tot = tot/1e6
		lab var tot "Survey total (Mil. LCU)"
		if `scalefactor' != 1{
			replace totScaled = totScaled/1e6
			lab var totScaled "Scaled total (Mil. LCU)"
		}
	} 
	else if "`unit'" == "9"{
		replace tot = tot/1e9
		lab var tot "Survey total (Bil. LCU)"
		if `scalefactor' != 1{
			replace totScaled = totScaled/1e9
			lab var totScaled "Scaled total (Bil. LCU)"
		}
	} 
	else if "`unit'" == "12"{
		replace tot = tot/1e12
		lab var tot "Survey total (Tril. LCU)"
		if `scalefactor' != 1{
			replace totScaled = totScaled/1e12
			lab var totScaled "Scaled total (Tril. LCU)"
		}
	} 
		
	* Save and export the data
		if "`data'" != ""{
			save "`data'", replace
		}
		if "`exportfile'" != ""{
			export excel "`exportfile'", sheet("`exportsheet'") first(varl) cell(A1) sheetmodify keepcellfmt
			if "`exportsheet'" == ""{
				di in red "Error: Specify a sheet name!"
				exit 198
			}
			if _rc {
			    di "Excel export failed. Make sure the workbook is closed."
			}	
		}
		else{
			di in blue "{Specify an Excel workbook to export results.}"
		}

	if "`restore'" == "restore"{
		restore
	}
end

