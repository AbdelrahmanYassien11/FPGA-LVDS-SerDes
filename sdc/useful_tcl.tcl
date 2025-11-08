# Show current project info
get_current_design

# Show available ports
foreach_in_collection port [get_ports] {
    puts [get_port_info -name $port]
}

# Report netlist info
report_netlist_namespace



# 1. Create the timing netlist
create_timing_netlist

# 2. Read in your SDC file(s) — optional for now
# read_sdc path_to_your_sdc_file.sdc

# 3. Update the netlist (builds internal timing data)
update_timing_netlist

# 4. Now query your design
get_pins -hierarchical *pll*
get_pins -hierarchical *outclk*


# Find all registers
get_registers *

# Find registers matching a pattern
get_registers {*serializer*}

# Find all pins
get_pins *

# Find pins matching pattern
get_pins {*outclk*}

# Find all ports
get_ports *

# reporting all setup violations for a certian clock path
report_timing -setup -from_clock [get_clocks {*general[0]*}] -to_clock [get_clocks {*general[0]*}] -detail full_path -panel_name "All Setup Violations" -file setup_violations.txt