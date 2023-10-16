
VTbuild_DIR ?= $(PWD)/../MyVT-Tool
MyUtils_DIR ?= $(PWD)/../MyUtils-Tool

PROJECT_NAME ?= myuart

include $(MyUtils_DIR)/utils.mk

help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  build          to create a directory with the built rtl code."

build: clean-all
	python $(VTbuild_DIR)/VTbuild.py $(PROJECT_NAME)

clean-all:
	python $(VTbuild_DIR)/VTbuild.py --clean all


.PHONY: build help clean-all