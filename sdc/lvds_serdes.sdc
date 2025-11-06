############################################################
# 1. Primary input clock (50 MHz reference)
############################################################
create_clock -name clk_in -period 20.000 [get_ports clk_in]
# (20 ns period = 50 MHz)


############################################################
# 2. Generated clocks from PLL outputs
############################################################
# These come from the internal PLL instance inside pll_inst1.
# Quartus automatically infers frequency ratios from the PLL.

# System domain (e.g., 100 MHz)
create_generated_clock -name clk_sys \
    -source [get_ports clk_in] \
    [get_pins {pll_inst1|pll_inst|outclk_0}]

# Serial domain (e.g., 400 MHz)
create_generated_clock -name clk_serial \
    -source [get_ports clk_in] \
    [get_pins {pll_inst1|pll_inst|outclk_1}]


############################################################
# 3. Do NOT mark these clocks asynchronous
############################################################
# (They come from the same PLL, so leave them related)
# set_clock_groups -asynchronous -group {clk_sys} -group {clk_serial}


############################################################
# 4. Define input/output delays relative to clk_sys
############################################################
# (Assume your system-side I/Os are in the clk_sys domain)

# Optional I/O delays (uncomment if connecting to real hardware timing)
#set_input_delay  -clock clk_sys 2.0 [get_ports {tx_data_in[*]}]
#set_input_delay  -clock clk_sys 2.0 [get_ports tx_data_valid]
#set_output_delay -clock clk_sys 2.0 [get_ports {rx_data_out[*]}]
#set_output_delay -clock clk_sys 2.0 [get_ports rx_data_valid]
#set_output_delay -clock clk_sys 2.0 [get_ports tx_data_ready]


############################################################
# 5. Reset handling (asynchronous)
############################################################
set_false_path -from [get_ports reset_n]
set_false_path -to [get_ports reset_n]


############################################################
# 6. Derive clock uncertainty (tool-specific)
############################################################
derive_clock_uncertainty
