/*============================================================================*\
 Staging layer (bridge)
 Reuse existing clean/staging script while revamp modules are built
\*============================================================================*/

capture confirm file "${revamp_scripts}/2-01-Clean_pc_ppp_lcu.do"
if _rc {
	di as err "Missing bridge staging file: ${revamp_scripts}/2-01-Clean_pc_ppp_lcu.do"
	exit 601
}

include "${revamp_scripts}/2-01-Clean_pc_ppp_lcu.do"
