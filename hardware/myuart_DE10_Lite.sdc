#**************************************************************
# Time Information
#**************************************************************
set_time_format -unit ns -decimal_places 3  		
#**************************************************************
# Create Clock
#************************************************************** 		
create_clock -name {clk} -period 4.000 -waveform { 0.000 2.000 } [get_ports {clk_i}]
#**************************************************************
# Set Clock Uncertainty
#**************************************************************
set_clock_uncertainty -rise_from [get_clocks {clk}] -rise_to [get_clocks {clk}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clk}] -fall_to [get_clocks {clk}]  0.020   
set_clock_uncertainty -fall_from [get_clocks {clk}] -rise_to [get_clocks {clk}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clk}] -fall_to [get_clocks {clk}]  0.020  
#**************************************************************
# Set False Path
#************************************************************** 		
# set_false_path -from [get_clocks {clk clkx2}] -through [get_pins -compatibility_mode *]  -to [get_clocks {clk clkx2}]