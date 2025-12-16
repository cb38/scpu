# Configuration
VERILATOR = verilator
VERILATOR_FLAGS = -Wall --trace --trace-fst -cc --exe --sv --Wno-UNDRIVEN --Wno-UNUSEDSIGNAL --Wno-DECLFILENAME
COMPILER = g++
COMPILER_FLAGS = -std=c++17 -Wall -Wextra -Wno-unused-parameter -Wno-unused-variable
CLANG_FORMAT = clang-format

# Directories
HW_DIR = hw
RTL_DIR = $(HW_DIR)/rtl
TB_DIR = $(HW_DIR)/tb
GEN_DIR = $(HW_DIR)/gen
OBJ_DIR = $(GEN_DIR)/obj_dir
SIM_DIR = $(GEN_DIR)/sim
ASM_DIR = asm

# Source files - ORDER MATTERS: packages first, then modules
PKG_SOURCES = $(RTL_DIR)/cpu_pkg.sv
RTL_SOURCES = $(PKG_SOURCES) $(RTL_DIR)/sram.sv $(RTL_DIR)/CpuID.sv
TB_SOURCES = $(TB_DIR)/cpu_tb.sv
CPP_HEADERS = $(TB_DIR)/assembler.h
CPP_MAIN = $(TB_DIR)/main.cpp

# Output files
EXECUTABLE = $(SIM_DIR)/cpu_sim
FST_DUMP = $(SIM_DIR)/waveform.fst
COVERAGE = $(SIM_DIR)/coverage.dat

# Program file
PROGRAM = $(ASM_DIR)/cpu.asm

# Phony targets
.PHONY: all compile sim clean format help

# Default target
all: compile sim

# Help target
help:
	@echo "Available targets:"
	@echo "  all       - Compile and run simulation (default)"
	@echo "  compile   - Compile with Verilator"
	@echo "  sim       - Run simulation"
	@echo "  clean     - Clean generated files"
	@echo "  format    - Format SystemVerilog files"
	@echo "  wave      - Open waveform in viewer (gtkwave or similar)"
	@echo "  help      - Display this message"

# Compile target
compile: $(EXECUTABLE)

$(EXECUTABLE): $(RTL_SOURCES) $(TB_SOURCES) $(CPP_HEADERS) $(CPP_MAIN)
	@mkdir -p $(OBJ_DIR) $(SIM_DIR)
	@echo "Compiling with Verilator..."
	$(VERILATOR) $(VERILATOR_FLAGS) \
		--top-module cpu_tb \
		-Mdir $(OBJ_DIR) \
		--output-split 20000 \
		--timing \
		$(PKG_SOURCES) $(RTL_DIR)/sram.sv $(RTL_DIR)/CpuID.sv \
		$(TB_DIR)/cpu_tb.sv \
		$(CPP_MAIN)
	@echo "Building C++ simulation..."
	cd $(OBJ_DIR) && make -f Vcpu_tb.mk
	@cp $(OBJ_DIR)/Vcpu_tb $(EXECUTABLE)
	@echo "Build complete: $(EXECUTABLE)"

# Simulation target
sim: compile $(PROGRAM)
	@echo "Running simulation..."
	$(EXECUTABLE) +program=$(PROGRAM)
	@if [ -f $(FST_DUMP) ]; then \
		echo "Waveform generated: $(FST_DUMP)"; \
	fi

# View waveform
wave: sim
	@if command -v gtkwave > /dev/null; then \
		gtkwave $(FST_DUMP); \
	elif command -v vivado > /dev/null; then \
		vivado -source view_wave.tcl; \
	else \
		echo "Warning: No waveform viewer found"; \
	fi

# Format code
format:
	@echo "Formatting SystemVerilog files..."
	$(CLANG_FORMAT) -i $(RTL_SOURCES) $(TB_SOURCES)
	@echo "Formatting complete"

# Clean target
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(OBJ_DIR) $(SIM_DIR) $(GEN_DIR)
	@echo "Clean complete"

# Verbose simulation
sim-verbose: compile $(PROGRAM)
	@echo "Running simulation with verbose output..."
	$(EXECUTABLE) +program=$(PROGRAM) +verbose=1

# Debug simulation with GDB
sim-debug: compile $(PROGRAM)
	@echo "Running simulation under GDB..."
	gdb --args $(EXECUTABLE) +program=$(PROGRAM)

# Check dependencies
check-deps:
	@echo "Checking dependencies..."
	@command -v $(VERILATOR) >/dev/null 2>&1 || \
		(echo "Error: $(VERILATOR) not found"; exit 1)
	@command -v $(COMPILER) >/dev/null 2>&1 || \
		(echo "Error: $(COMPILER) not found"; exit 1)
	@echo "All dependencies found"

# Info target
info:
	@echo "Project: Simple CPU"
	@echo "Build System: Verilator"
	@echo "RTL Sources: $(RTL_SOURCES)"
	@echo "Testbench: $(TB_SOURCES)"
	@echo "Output: $(EXECUTABLE)"
	@echo "Waveform: $(FST_DUMP)"

.DEFAULT_GOAL := all
