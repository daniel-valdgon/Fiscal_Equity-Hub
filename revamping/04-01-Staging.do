/*============================================================================*\
 Staging layer (bridge)
 Reuse existing clean/staging script while revamp modules are built
\*============================================================================*/

capture confirm file "${revamp_scripts}/2-01-Clean_pc_ppp_lcu.do"
if _rc {
 This step creates required *_pc variables before the 05-xx indicator modules.
	exit 601
}

include "${revamp_scripts}/2-01-Clean_pc_ppp_lcu.do"
