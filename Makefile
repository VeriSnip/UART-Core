VTbuild_DIR ?= $(PWD)/../MyVT-Tool
MyUtils_DIR ?= $(PWD)/../MyUtils-Tool

PROJECT_NAME ?= myuart
QUIET := 1
Board_Modules := _ecp5

include $(MyUtils_DIR)/utils.mk
