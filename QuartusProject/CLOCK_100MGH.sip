set_global_assignment -entity "CLOCK_100MGH" -library "lib_CLOCK_100MGH" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "CLOCK_100MGH" -library "lib_CLOCK_100MGH" -name IP_TOOL_VERSION "25.1"
set_global_assignment -entity "CLOCK_100MGH" -library "lib_CLOCK_100MGH" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_CLOCK_100MGH" -name SPD_FILE [file join $::quartus(sip_path) "CLOCK_100MGH.spd"]

set_global_assignment -library "lib_CLOCK_100MGH" -name MISC_FILE [file join $::quartus(sip_path) "CLOCK_100MGH_sim/CLOCK_100MGH.vo"]
