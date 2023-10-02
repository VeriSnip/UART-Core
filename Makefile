
VTbuild_DIR ?= $(PWD)/../MyVT-Tool
Core_Name := myuart

help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  build          to create a directory with the built rtl code."

build: clean-all
	python $(VTbuild_DIR)/VTbuild.py $(Core_Name)

clean-all:
	python $(VTbuild_DIR)/VTbuild.py --clean all


.PHONY: build help clean-all