# Makefile
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

# defaults
SIM ?= icarus
FST ?= -fst # Use more efficient FST format
TOPLEVEL_LANG ?= verilog
SRC_DIR = $(PWD)/../src
PROJECT_SOURCES = TT_processor_chip.v \
                  top_1_2.v \
                  i2c_slave_mmio_1_2.v \
                  mmio_decoder_1_2.v \
                  instruction_memory_1_2.v \
                  data_memory_1_2.v \
                  reg_file_1_2.v \
                  ALU_2_1_2.v \
                  BHT_3_1_2.v \
                  BTB_3_1_2.v \
                  EX_MEM_2_1_2.v \
                  Flushing_unit_3_1_2.v \
                  Forward_rs_2_1_2.v \
                  Forwarding_unit_2_1_2.v \
                  ID_EX_register_2_1_2.v \
                  IF_ID_register_1_2.v \
                  M_WB_Register_1_1_2.v \
                  PHT_2_1_2.v \
                  Pc_1_2.v \
                  Sign_extender_1_1_2.v \
                  Write_back_mux_1_1_2.v \
                  Xor_result_1_1_2.v \
                  branching_unit_3_1_2.v \
                  comparator_2_1_2.v \
                  control_unit_2_1_2.v \
                  forward_rt_2_1_2.v \
                  mux_1_1_1_2.v \
                  mux_1_execution_1_1_2.v \
                  mux_2_1_1_2.v \
                  mux_2_execution_2_1_2.v \
                  mux_3_execution_1_1_2.v \
                  stalling_unit_1_1_2.v

ifneq ($(GATES),yes)

# RTL simulation:
SIM_BUILD				= sim_build/rtl
VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))

else

# Gate level simulation:
SIM_BUILD				= sim_build/gl
COMPILE_ARGS    += -DGL_TEST
COMPILE_ARGS    += -DFUNCTIONAL
COMPILE_ARGS    += -DUSE_POWER_PINS
COMPILE_ARGS    += -DSIM
COMPILE_ARGS    += -DUNIT_DELAY=\#1
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v

# this gets copied in by the GDS action workflow
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v

endif

# Allow sharing configuration between design and testbench via `include`:
COMPILE_ARGS 		+= -I$(SRC_DIR)

# Include the testbench sources:
VERILOG_SOURCES += $(PWD)/tb.v
TOPLEVEL = tb

# List test modules to run, separated by commas and without the .py suffix:
COCOTB_TEST_MODULES = test

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
