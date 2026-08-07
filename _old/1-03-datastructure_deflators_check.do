*---------------------------------------------------------------
**# Check consistency of combined spatial and temporal deflators
*---------------------------------------------------------------

* National poverty line deflator:
* the combined spatial-temporal deflator should equal the product
* of the spatial deflator and the temporal deflator.
assert def_sp_tmp_nat == def_sp_nat * def_tmp_nat ///
    if !missing(def_sp_nat) | !missing(def_tmp_nat)

* International poverty line deflator:
* the combined spatial-temporal international deflator should equal
* the product of the international spatial and temporal deflators.
assert def_sp_tmp_inat == def_sp_inat * def_tmp_inat ///
    if !missing(def_sp_inat) | !missing(def_tmp_inat)

di as result "Spatial-temporal deflator consistency checks passed."
sleep 2000