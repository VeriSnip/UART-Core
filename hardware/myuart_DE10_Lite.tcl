set PROJECT_NAME [lindex $argv 0]
set FPGA_SOURCES [lindex $argv 1]
set SDC_FILE [lindex $argv 2]
# Split the space-separated file paths into a list
set source_files [split $FPGA_SOURCES]

project_new $PROJECT_NAME -overwrite
# Assign family, device, and top-level file
set_global_assignment -name FAMILY "MAX 10"  
set_global_assignment -name DEVICE "10M50DAF484C7G"
# Set the .sdc file name
set_global_assignment -name SDC_FILE $SDC_FILE
# Iterate through the source files and assign them individually
foreach file $source_files {
    if {[string match "*.sv" $file]} {
        set_global_assignment -name SYSTEMVERILOG_FILE $file
    } else {
        set_global_assignment -name VERILOG_FILE $file
    }
}
# Assign pins
set_location_assignment -to clk_i PIN_P11
set_location_assignment -to rx_i Pin_AB5
set_location_assignment -to tx_o Pin_AB6

project_close; # close project