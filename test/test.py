import cocotb
from cocotb.triggers import Timer


@cocotb.test()
async def test_project(dut):
    dut._log.info("Starting MIPS + Tiny Tapeout exhaustive testbench")

    # tb.v contains the complete self-checking test suite.
    # Wait long enough for the Verilog testbench to finish.
    await Timer(20, unit="ms")

    dut._log.info("Exhaustive Verilog testbench completed")
