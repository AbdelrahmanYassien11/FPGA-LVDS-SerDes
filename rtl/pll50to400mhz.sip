set_global_assignment -entity "pll50to400mhz" -library "lib_pll50to400mhz" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "pll50to400mhz" -library "lib_pll50to400mhz" -name IP_TOOL_VERSION "13.1"
set_global_assignment -entity "pll50to400mhz" -library "lib_pll50to400mhz" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_pll50to400mhz" -name SPD_FILE [file join $::quartus(sip_path) "pll50to400mhz.spd"]

set_global_assignment -library "lib_pll50to400mhz" -name MISC_FILE [file join $::quartus(sip_path) "pll50to400mhz_sim/pll50to400mhz.vo"]
