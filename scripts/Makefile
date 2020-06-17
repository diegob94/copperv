SHELL = /bin/bash

ROOT = $(realpath ../)
SCRIPTS = $(ROOT)/scripts
RTL = $(ROOT)/rtl
SIM = $(ROOT)/sim
UTIL = $(ROOT)/util

RTL_SOURCES = $(wildcard $(RTL)/*.v)

.PHONY: all
all: sim

# Simulation
include $(SCRIPTS)/sim.mk


