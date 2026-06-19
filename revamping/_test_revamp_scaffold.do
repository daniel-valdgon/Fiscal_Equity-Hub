capture log close _all
log using "02-Scripts/wb419055/revamping/_test_revamp_scaffold.log", replace text

include "02-Scripts/wb419055/revamping/01-00-Setup.do"
include "${revamp_scripts}/01-01-Policy_Registry.do"
include "${revamp_scripts}/02-01-Inventory_Manifest.do"
include "${revamp_scripts}/03-01-Validate_Structure.do"

di as txt "PASS: revamp scaffold pre-indicator modules executed"

log close
exit, clear
