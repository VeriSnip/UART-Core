VTbuild_DIR ?= $(PWD)/../MyVT-Tool
MyUtils_DIR ?= $(PWD)/../MyUtils-Tool

PROJECT_NAME ?= myuart
QUIET := 1
Board_Modules := _fpga
PROJECT_FPGA_TOP := $(PROJECT_NAME)_fpga
PROJECT_FPGA_DIR = $(PROJECT_RTL_DIR)/fpga
#BOARD := DE10_Lite
# Comment the following line to test only the UART core (use myuart_tb).
TestBench := myuart_ecp5_tb

include $(MyUtils_DIR)/utils.mk
