capture log close _all
log using "02-Scripts/wb419055/revamping/_test_trunk_guard.log", replace text

* Run only setup + guard by calling trunk; downstream may stop on data checks,
* but the include guard executes before the rest of the pipeline.
do "02-Scripts/wb419055/revamping/00-Trunk_Revamp.do"

log close
exit, clear
