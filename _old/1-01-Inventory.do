



*First level countries
local current_dirs : dir "${microdata}" dirs "*"

	foreach subf of local current_dirs {
		*2nd level : 
		local cty_path `"${microdata}/`subf'"'
		local current_dirs2nd : dir "`cty_path'" dirs "*"
			foreach subf of local current_dirs2nd {
				local cty_proj_path "`cty_path'/`subf'"
				
				*Search dta files in the 2nd level
				local dta_subf: dir "`cty_proj_path'" files "*.dta"
				*Only one file per folder 
				local ndta : word count `dta_subf'
				capture noisily assert `ndta' == 1
				if _rc {
					cap di as err "[rc=`rc'] Folder [`cty_proj_path'] has [`ndta'] .dta file(s): [`dta_subf']"
				}
				*Name of folder same as name of data file
				capture noisily assert "`dta_subf'" == "`subf'.dta"
				if _rc {
					cap di as err "[rc=`rc'] Name mismatch in [`cty_proj_path']: expected [`subf'.dta], found [`dta_subf']"
					
				}
			}
	}
