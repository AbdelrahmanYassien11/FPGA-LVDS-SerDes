# Define primary clocks
create_clock -name clk_sys -period 10.000 [get_ports clk_sys]
create_clock -name clk_serial -period 2.500 [get_ports clk_serial]

# Set clock groups (asynchronous clocks)
set_clock_groups -asynchronous -group {clk_sys} -group {clk_serial}

# Define input delays relative to clk_sys
set_input_delay -clock clk_sys 2.000 [get_ports {tx_data_in[*]}]
set_input_delay -clock clk_sys 2.000 [get_ports tx_data_valid]

# Define output delays relative to clk_sys
set_output_delay -clock clk_sys 2.000 [get_ports {rx_data_out[*]}]
set_output_delay -clock clk_sys 2.000 [get_ports rx_data_valid]
set_output_delay -clock clk_sys 2.000 [get_ports tx_data_ready]

# Reset is asynchronous
set_false_path -from [get_ports reset_n]

# Derive clock uncertainty
derive_clock_uncertainty