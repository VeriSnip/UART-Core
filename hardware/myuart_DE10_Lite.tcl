# Input argumments
set PROJECT_NAME [lindex $argv 0]
set FPGA_SOURCES [lindex $argv 1]
set FPGA_TOP [lindex $argv 2]
set SDC_FILE [lindex $argv 3]
set OUTPUT_DIRECTORY [lindex $argv 4]

# Split the space-separated file paths into a list
set source_files [split $FPGA_SOURCES]

project_new $PROJECT_NAME -overwrite
# Assign family, device, and top-level file
set_global_assignment -name FAMILY "MAX 10"  
set_global_assignment -name DEVICE "10M50DAF484C7G"
# Iterate through the source files and assign them individually
foreach file $source_files {
    if {[string match "*.sv" $file]} {
        set_global_assignment -name SYSTEMVERILOG_FILE $file
    } else {
        set_global_assignment -name VERILOG_FILE $file
    }
}
set_global_assignment -name TOP_LEVEL_ENTITY $FPGA_TOP
# Set the .sdc file name
set_global_assignment -name SDC_FILE $SDC_FILE
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY $OUTPUT_DIRECTORY
# Assign pins
set_location_assignment PIN_P11 -to clk_i
set_location_assignment PIN_B8 -to arst_i
set_location_assignment Pin_AB5 -to rx_i
set_location_assignment Pin_AB6 -to tx_o

project_close; # close project