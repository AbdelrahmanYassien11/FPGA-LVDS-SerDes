# Show current project info
get_current_design

# Show available ports
foreach_in_collection port [get_ports] {
    puts [get_port_info -name $port]
}

# Report netlist info
report_netlist_namespace