############################################################
# 1. Primary input clock (50 MHz reference)
############################################################
create_clock -name clk_in -period 20.000 [get_ports clk_in]


############################################################
# 2. Auto-derive PLL generated clocks
############################################################
derive_pll_clocks


############################################################
# 3. CDC constraints for 2FF synchronizers
############################################################
# Data crossing clk_sys (100MHz) → clk_serial (400MHz)
set_max_delay -from [get_clocks {*general[0]*divclk}] \
              -to   [get_clocks {*general[1]*divclk}] \
              10.000

# Data crossing clk_serial (400MHz) → clk_sys (100MHz)
set_max_delay -from [get_clocks {*general[1]*divclk}] \
              -to   [get_clocks {*general[0]*divclk}] \
              2.500


############################################################
# 4. Input delays (System domain - clk_sys)
############################################################
# Assume external device has 3ns Tco + 1ns PCB trace = 4ns total
set_input_delay -clock [get_clocks {*general[0]*divclk}] -max 4.0 [get_ports {tx_data_in[*]}]
set_input_delay -clock [get_clocks {*general[0]*divclk}] -max 4.0 [get_ports tx_data_valid]

# Min delay (for hold analysis) - typically Tco_min + PCB_min
set_input_delay -clock [get_clocks {*general[0]*divclk}] -min 1.0 [get_ports {tx_data_in[*]}]
set_input_delay -clock [get_clocks {*general[0]*divclk}] -min 1.0 [get_ports tx_data_valid]


############################################################
# 5. Output delays (System domain - clk_sys)
############################################################
# Assume 1ns PCB trace + 2ns external device Tsu = 3ns total
set_output_delay -clock [get_clocks {*general[0]*divclk}] -max 3.0 [get_ports {rx_data_out[*]}]
set_output_delay -clock [get_clocks {*general[0]*divclk}] -max 3.0 [get_ports rx_data_valid]
set_output_delay -clock [get_clocks {*general[0]*divclk}] -max 3.0 [get_ports tx_data_ready]

# Min delay (for hold analysis) - typically PCB_min + Th (hold time)
set_output_delay -clock [get_clocks {*general[0]*divclk}] -min 0.5 [get_ports {rx_data_out[*]}]
set_output_delay -clock [get_clocks {*general[0]*divclk}] -min 0.5 [get_ports rx_data_valid]
set_output_delay -clock [get_clocks {*general[0]*divclk}] -min 0.5 [get_ports tx_data_ready]


############################################################
# 6. Reset handling (asynchronous)
############################################################
set_false_path -from [get_ports reset_n]


############################################################
# 7. Input clock constraints
############################################################
# Don't analyze timing on the input clock port itself
set_false_path -from [get_ports clk_in]


############################################################
# 8. Derive clock uncertainty
############################################################
derive_clock_uncertainty