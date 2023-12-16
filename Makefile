VTbuild_DIR ?= $(PWD)/../MyVT-Tool
MyUtils_DIR ?= $(PWD)/../MyUtils-Tool

PROJECT_NAME ?= myuart

# MyVT variables used by MyUtils
QUIET := 1

# FPGA/Board variables used by MyUtils
FPGA_TOP_MODULES := _fpga 
PROJECT_FPGA_TOP := $(PROJECT_NAME)_fpga
PROJECT_FPGA_DIR = $(PROJECT_RTL_DIR)/fpga
SUPPORTED_BOARDS := IceSugar_pro DE10_Lite
BOARD ?= DE10_Lite

# Simulation variables used by MyUtils
SUPPORTED_SIMULATORS := QuestaSim
SIMULATOR := QuestaSim
## Comment the following line to test only the UART core (uses myuart_tb by default).
PROJECT_SIM_TOP := $(PROJECT_NAME)_fpga_tb

include $(MyUtils_DIR)/utils.mk
