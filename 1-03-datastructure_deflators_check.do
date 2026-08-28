*---------------------------------------------------------------
**# Check consistency of combined spatial and temporal deflators
*---------------------------------------------------------------
local check_failed = 0

* National poverty line deflator
capture assert def_sp_tmp_nat == def_sp_nat * def_tmp_nat ///
    if !missing(def_sp_nat) | !missing(def_tmp_nat)

if _rc != 0 {
    di as error "No se cumple el chequeo: el deflactor espacial nacional multiplicado por el deflactor temporal nacional no es igual al deflactor espacial-temporal nacional."
    local check_failed = 1
}

* International poverty line deflator
capture assert def_sp_tmp_inat == def_sp_inat * def_tmp_inat ///
    if !missing(def_sp_inat) | !missing(def_tmp_inat)

if _rc != 0 {
    di as error "No se cumple el chequeo: el deflactor espacial internacional multiplicado por el deflactor temporal internacional no es igual al deflactor espacial-temporal internacional."
    local check_failed = 1
}

if `check_failed' == 0 {
    di as result "Se cumple el chequeo de consistencia entre los deflactores espaciales, temporales y espaciales-temporales."
}
if `check_failed' == 1 {
    di as error "No se cumple el chequeo de consistencia entre los deflactores espaciales, temporales y espaciales-temporales."
}

sleep 2000

