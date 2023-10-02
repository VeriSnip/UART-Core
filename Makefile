
VTbuild_DIR ?= $(PWD)/../MyVT-Tool
Core_Name := myuart

help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  build          to create a directory with the built rtl code."

build:
	python $(VTbuild_DIR)/VTbuild.py --clean all
	python $(VTbuild_DIR)/VTbuild.py $(Core_Name)

.PHONY: build help