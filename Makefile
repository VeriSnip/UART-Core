VTbuild_DIR ?= $(PWD)/../MyVT-Tool
MyUtils_DIR ?= $(PWD)/../MyUtils-Tool

PROJECT_NAME ?= myuart
QUIET := 1
Board_Modules := _ecp5
# Comment the following line to test only the UART core (use myuart_tb).
TestBench := myuart_ecp5_tb

include $(MyUtils_DIR)/utils.mk
