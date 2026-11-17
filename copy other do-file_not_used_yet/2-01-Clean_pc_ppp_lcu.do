
*============================================================================*
//	Preparing data
*============================================================================*

foreach x in `dirtax' `ssc' `dirtra' `subs' `indtax' `inktra' { // all countries 
	local x_total
	foreach y of local x { // all policies
		local x_total `x_total' `y'

		foreach z in pc { // all indicators 
			local y_`z' = `y' / hhsize
			local x_total_`z' = `x_total' / hhsize
		}
	}
	local `x'_total `x_total'
