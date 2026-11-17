capture log close _all
log using "02-Scripts/wb419055/revamping/_test_05_runner_links.log", replace text

* Minimal compile/load test for renamed indicator runner wiring
include "02-Scripts/wb419055/revamping/01-00-Setup.do"
global validation_structure_pass 1
include "${revamp_scripts}/05-01-Indicators_Run.do"

log close
exit, clear
