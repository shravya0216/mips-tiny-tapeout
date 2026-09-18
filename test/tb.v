`timescale 1ns / 1ps
// =============================================================================
// TT WRAPPER + FULL PROCESSOR: EXHAUSTIVE SELF-CHECKING TESTBENCH
//
// Targets tt_um_yourname (the Tiny Tapeout harness), NOT top.v directly --
// this is the actual interface that gets fabricated, so it's the one that
// needs to be proven correct end-to-end: ui_in/uo_out/uio_*/ena/rst_n in,
// nothing but $display PASS/FAIL/NOTE lines out. No waveform viewing
// required -- just run it and read (or screenshot) the console/log.
//
// Everything from the earlier master testbench is retained and re-targeted
// through the wrapper's pins, PLUS new checks specific to the wrapper
// conversion itself (open-drain compliance, unused-pin safety, ena
// tolerance) that didn't exist before this port existed.
//
// SECTIONS:
//   0.  Reset sanity (via rst_n)
//   0b. WRAPPER COMPLIANCE (continuous, whole-run invariant + static checks)
//   1.  MMIO boundaries / alignment / R0 protection
//   2.  I2C malformed transactions
//   3.  Full 54-instruction exhaustive architectural program
//   4.  PROGRAM_STALL -- load-use stall as last instr before target_pc
//   5.  PROGRAM_BRANCH_BOUNDARY -- sane target_pc
//   6.  PROGRAM_BRANCH_BOUNDARY -- target_pc branch skips over (informational)
//   7.  PROGRAM_COMBO -- stall immediately followed by a branch
//   8.  Repeatability -- reload PROGRAM_STALL a third full session
//   9.  Reprogram without reset (informational)
//   10. REGFILE MMIO-load end-to-end
//   11. ena tolerance check
//
// Adjust hierarchy paths below if your instance names differ. Since the DUT
// is now the wrapper, paths go one level deeper than before:
//   dut.top_inst.IM_inst.IM[] / dut.top_inst.REGFILE_inst.RF[]
//   dut.top_inst.DM_inst.DM[] / dut.top_inst.PC_out / dut.top_inst.target_pc
//   dut.top_inst.run_req / dut.top_inst.done
//   dut.top_inst.BHT_inst.BHT[] / dut.top_inst.BTB_inst.BTB[]
// =============================================================================

module tb;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg ena = 1'b1;
    reg [7:0] ui_in = 8'b0;
    wire [7:0] uo_out;
    reg [7:0] uio_in = 8'b0;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    always #5 clk = ~clk;

    // -------------------------------------------------------------------
    // Open-drain SDA bus model: two independent drivers (DUT + this
    // testbench acting as the MCU), resolved via tri-state + pullup, the
    // same way a real physical wire with a pull-up resistor behaves.
    // -------------------------------------------------------------------
    wire sda_line;
    pullup(sda_line);
    assign sda_line = uio_oe[0] ? uio_out[0] : 1'bz;   // DUT's own drive
    reg   mcu_sda_release = 1'b1;                       // 1 = released (Z), 0 = drive low
    assign sda_line = mcu_sda_release ? 1'bz : 1'b0;    // MCU's own drive

    always @(*) uio_in[0] = sda_line;                   // DUT reads the resolved bus

    wire scl_line = ui_in[0];

    tt_um_shravya0216_mips dut(
        .ui_in(ui_in), .uo_out(uo_out),
        .uio_in(uio_in), .uio_out(uio_out), .uio_oe(uio_oe),
        .ena(ena), .clk(clk), .rst_n(rst_n)
    );

    wire led = uo_out[0];

    integer errors;
    integer informational_notes;
    integer i;

    // -------------------------------------------------------------------
    // SECTION 0b (continuous): open-drain compliance monitor.
    // The DUT must NEVER actively drive SDA high -- it should only ever
    // pull low (uio_oe=1 with uio_out=0) or release (uio_oe=0). If uio_oe=1
    // and uio_out=1 simultaneously, that's a real electrical bug (driving
    // high on an open-drain bus), and would go completely unnoticed by any
    // test that only checks final register values -- this catches it the
    // instant it happens, anywhere in the entire run.
    // -------------------------------------------------------------------
    always @(posedge clk) begin
        if (uio_oe[0] && uio_out[0]) begin
            $display("FAIL @ %0t: WRAPPER COMPLIANCE -- DUT actively drove SDA HIGH (uio_oe[0]=1, uio_out[0]=1). Open-drain violation.", $time);
            errors = errors + 1;
        end
    end

    // -------------------------------------------------------------------
    // Programs (identical to the master testbench)
    // -------------------------------------------------------------------
    reg [31:0] progExh [0:33];
    reg [31:0] progStall [0:5];
    reg [31:0] progBranch [0:4];
    reg [31:0] progCombo [0:4];

    initial begin
        progExh[0]=32'h08100007;  progExh[1]=32'h0E110000;  progExh[2]=32'h02319000;
        progExh[3]=32'h08150014;  progExh[4]=32'h0EB60000;  progExh[5]=32'h02D6B800;
        progExh[6]=32'h08180015;  progExh[7]=32'h0F190000;  progExh[8]=32'h0339D000;
        progExh[9]=32'h081B0005;  progExh[10]=32'h037BE000; progExh[11]=32'h081C0003;
        progExh[12]=32'h0380E800; progExh[13]=32'h081E0309; progExh[14]=32'h0000F000;
        progExh[15]=32'h08130000; progExh[16]=32'h16600001; progExh[17]=32'h14000000;
        progExh[18]=32'h081F0000; progExh[19]=32'h17E00002; progExh[20]=32'h0810022B;
        progExh[21]=32'h0811022C; progExh[22]=32'h14000001; progExh[23]=32'h0812022D;
        progExh[24]=32'h08080008; progExh[25]=32'h08090000; progExh[26]=32'h01284800;
        progExh[27]=32'h0908FFFF; progExh[28]=32'h15000001; progExh[29]=32'h1400FFFC;
        progExh[30]=32'h10090000; progExh[31]=32'hFC000000; progExh[32]=32'hFC000000;
        progExh[33]=32'hFC000000;

        progStall[0]=32'h0801000A; progStall[1]=32'h08020019; progStall[2]=32'h00221800;
        progStall[3]=32'h10030000; progStall[4]=32'h0C040000; progStall[5]=32'h04812800;

        progBranch[0]=32'h14000003; progBranch[1]=32'h08020384; progBranch[2]=32'h08020385;
        progBranch[3]=32'h0803004D; progBranch[4]=32'h0803004D;

        progCombo[0]=32'h08010003; progCombo[1]=32'h0C020000; progCombo[2]=32'h14420001;
        progCombo[3]=32'h080903E7; progCombo[4]=32'h080A002C;
    end

    // -------------------------------------------------------------------
    // I2C primitives, now driving ui_in[0] (scl) and mcu_sda_release
    // instead of a raw sda wire.
    // -------------------------------------------------------------------
    task i2c_start; begin
        mcu_sda_release=1'b1; ui_in[0]=1'b1; #5000;
        mcu_sda_release=1'b0; #5000;
        ui_in[0]=1'b0; #5000;
    end endtask

    task i2c_stop; begin
        mcu_sda_release=1'b0; ui_in[0]=1'b0; #5000;
        ui_in[0]=1'b1; #5000;
        mcu_sda_release=1'b1; #5000;
    end endtask

    task i2c_write_bit; input b; begin
        ui_in[0]=1'b0; mcu_sda_release = b?1'b1:1'b0; #5000; ui_in[0]=1'b1; #5000;
    end endtask

    task i2c_ack_bit; begin
        ui_in[0]=1'b0; mcu_sda_release=1'b1; #5000; ui_in[0]=1'b1; #5000; ui_in[0]=1'b0; #5000;
    end endtask

    task i2c_write_byte; input [7:0] b; integer k; begin
        for (k=7;k>=0;k=k-1) i2c_write_bit(b[k]);
        i2c_ack_bit;
    end endtask

    task mmio_write; input [15:0] addr; input [31:0] data; begin
        i2c_start;
        i2c_write_byte(8'h84);
        i2c_write_byte(addr[15:8]); i2c_write_byte(addr[7:0]);
        i2c_write_byte(data[31:24]); i2c_write_byte(data[23:16]);
        i2c_write_byte(data[15:8]);  i2c_write_byte(data[7:0]);
        i2c_stop;
        #100;
    end endtask

    task mmio_write_wrong_addr; input [15:0] addr; input [31:0] data; begin
        i2c_start;
        i2c_write_byte(8'h10); // wrong address + W
        i2c_write_byte(addr[15:8]); i2c_write_byte(addr[7:0]);
        i2c_write_byte(data[31:24]); i2c_write_byte(data[23:16]);
        i2c_write_byte(data[15:8]);  i2c_write_byte(data[7:0]);
        i2c_stop;
        #100;
    end endtask

    task mmio_write_truncated; input [15:0] addr; input [31:0] data; input integer n_bytes; begin
        i2c_start;
        i2c_write_byte(8'h84);
        if (n_bytes>=1) i2c_write_byte(addr[15:8]);
        if (n_bytes>=2) i2c_write_byte(addr[7:0]);
        if (n_bytes>=3) i2c_write_byte(data[31:24]);
        if (n_bytes>=4) i2c_write_byte(data[23:16]);
        if (n_bytes>=5) i2c_write_byte(data[15:8]);
        if (n_bytes>=6) i2c_write_byte(data[7:0]);
        i2c_stop;
        #100;
    end endtask

    // -------------------------------------------------------------------
    // Checks
    // -------------------------------------------------------------------
    task check32; input [31:0] actual; input [31:0] expected; input [255:0] name; begin
        if (actual !== expected) begin
            $display("FAIL @ %0t: %0s actual=%h expected=%h", $time, name, actual, expected);
            errors = errors + 1;
        end else
            $display("PASS @ %0t: %0s = %h", $time, name, actual);
    end endtask

    task check1; input actual; input expected; input [255:0] name; begin
        if (actual !== expected) begin
            $display("FAIL @ %0t: %0s actual=%b expected=%b", $time, name, actual, expected);
            errors = errors + 1;
        end else
            $display("PASS @ %0t: %0s = %b", $time, name, actual);
    end endtask

    task note; input [1023:0] msg; begin
        informational_notes = informational_notes + 1;
        $display("NOTE @ %0t: %0s", $time, msg);
    end endtask

    task hard_reset; begin
        rst_n=1'b0; #100; rst_n=1'b1; #100;
    end endtask

    task set_run; input v; begin
        mmio_write(16'h3000, {31'b0, v});
    end endtask

    task set_target; input [31:0] tpc; begin
        mmio_write(16'h3004, tpc);
    end endtask

    task wait_for_done; input integer max_cycles; output reached; integer n; begin
        n = 0;
        while (!dut.top_inst.done && n < max_cycles) begin
            @(posedge clk); n = n + 1;
        end
        reached = dut.top_inst.done;
    end endtask

    reg done_flag;

    // =====================================================================
    // MAIN
    // =====================================================================
    initial begin
        errors = 0;
        informational_notes = 0;
        mcu_sda_release = 1'b1;
        ui_in[0] = 1'b1; // scl idle high

        $display("");
        $display("============================================================");
        $display(" TT WRAPPER + FULL PROCESSOR: EXHAUSTIVE TESTBENCH");
        $display("============================================================");

        // ------------------------------------------------------------
        hard_reset;
        $display("");
        $display("------------------------------------------------------------");
        $display(" SECTION 0: RESET SANITY (via rst_n)");
        $display("------------------------------------------------------------");
        check32(dut.top_inst.PC_out, 32'h0, "PC after reset");
        check1(dut.top_inst.done, 1'b0, "done after reset");
        check1(dut.top_inst.run_req, 1'b0, "run_req after reset");
        check32(dut.top_inst.REGFILE_inst.RF[0], 32'h0, "R0 after reset");

        $display("");
        $display("------------------------------------------------------------");
        $display(" SECTION 0b: WRAPPER COMPLIANCE (static pin safety)");
        $display("------------------------------------------------------------");
        check32({uio_out[7:1]}, 7'b0, "uio_out[7:1] held safe at reset");
        check32({uio_oe[7:1]},  7'b0, "uio_oe[7:1] held safe at reset");
        check32({uo_out[7:1]},  7'b0, "uo_out[7:1] held safe at reset");
        check1(led, 1'b0, "led (uo_out[0]) low at reset");
        note("Open-drain compliance monitor (Section 0b continuous check) is running for the ENTIRE remainder of this simulation, not just here -- any violation anywhere below will still be flagged and counted as a FAIL at the point it occurs.");

        // ------------------------------------------------------------
        $display("");
        $display("------------------------------------------------------------");
        $display(" SECTION 1: MMIO BOUNDARIES / ALIGNMENT / R0 PROTECTION");
        $display("------------------------------------------------------------");
        mmio_write(16'h1004, 32'h000000AA);
        check32(dut.top_inst.REGFILE_inst.RF[1], 32'h000000AA, "RF[1] valid write");
        mmio_write(16'h0000, 32'h12345678);
        check32({dut.top_inst.IM_inst.IM[0],dut.top_inst.IM_inst.IM[1],
                  dut.top_inst.IM_inst.IM[2],dut.top_inst.IM_inst.IM[3]},
                 32'h12345678, "IMEM[0] boundary (4-byte word)");
        mmio_write(16'h1000, 32'hDEADBEEF); // R0
        check32(dut.top_inst.REGFILE_inst.RF[0], 32'h0, "MMIO cannot program R0");
        mmio_write(16'h2000, 32'h11111111);
        check32(dut.top_inst.DM_inst.DM[0], 32'h11111111, "DMEM[0] boundary");
        mmio_write(16'h0002, 32'hFFFFFFFF); // misaligned, must be rejected
        check32({dut.top_inst.IM_inst.IM[0],dut.top_inst.IM_inst.IM[1],
                  dut.top_inst.IM_inst.IM[2],dut.top_inst.IM_inst.IM[3]},
                 32'h12345678, "misaligned IMEM write rejected (4-byte word)");

        // ------------------------------------------------------------
        $display("");
        $display("------------------------------------------------------------");
        $display(" SECTION 2: I2C MALFORMED TRANSACTIONS");
        $display("------------------------------------------------------------");
        mmio_write(16'h1004, 32'hCAFEBABE);
        check32(dut.top_inst.REGFILE_inst.RF[1], 32'hCAFEBABE, "RF[1] baseline before truncation tests");
        mmio_write_truncated(16'h1004, 32'h55555555, 3);
        check32(dut.top_inst.REGFILE_inst.RF[1], 32'hCAFEBABE, "STOP mid-transaction caused no partial write");
        mmio_write_wrong_addr(16'h1004, 32'h55555555);
        check32(dut.top_inst.REGFILE_inst.RF[1], 32'hCAFEBABE, "wrong I2C slave address ignored");
        mmio_write(16'h1004, 32'hA5A5A5A5);
        check32(dut.top_inst.REGFILE_inst.RF[1], 32'hA5A5A5A5, "I2C recovers cleanly after malformed transactions");

        // ------------------------------------------------------------
        $display("");
        $display("------------------------------------------------------------");
        $display(" SECTION 3: FULL EXHAUSTIVE PROGRAM (target_pc = 0x7C)");
        $display("------------------------------------------------------------");
        hard_reset;
        for (i=0;i<=33;i=i+1) mmio_write(i*16'd4, progExh[i]);
        mmio_write(16'h201C, 32'd7);
        mmio_write(16'h2050, 32'd20);
        mmio_write(16'h2054, 32'd21);
        set_target(32'h0000007C);
        set_run(1);
        wait_for_done(3000, done_flag);
        check1(done_flag, 1'b1, "S3: exhaustive program done");
        check32(dut.top_inst.PC_out, 32'h0000007C, "S3: PC stopped at target");
        check32(dut.top_inst.REGFILE_inst.RF[16], 32'd7,  "S3: R16");
        check32(dut.top_inst.REGFILE_inst.RF[17], 32'd7,  "S3: R17");
        check32(dut.top_inst.REGFILE_inst.RF[18], 32'd14, "S3: R18");
        check32(dut.top_inst.REGFILE_inst.RF[21], 32'd20, "S3: R21");
        check32(dut.top_inst.REGFILE_inst.RF[22], 32'd20, "S3: R22");
        check32(dut.top_inst.REGFILE_inst.RF[23], 32'd40, "S3: R23");
        check32(dut.top_inst.REGFILE_inst.RF[26], 32'd42, "S3: R26");
        check32(dut.top_inst.REGFILE_inst.RF[28], 32'd3,  "S3: R28 (last-write priority)");
        check32(dut.top_inst.REGFILE_inst.RF[29], 32'd3,  "S3: R29 (forwarding priority)");
        check32(dut.top_inst.REGFILE_inst.RF[30], 32'd0,  "S3: R30 ($0-writes ignored path)");
        check32(dut.top_inst.REGFILE_inst.RF[9],  32'd36, "S3: R9 loop sum (1..8)");
        check32(dut.top_inst.DM_inst.DM[0],       32'd36, "S3: DM[0] loop sum stored");
        check32(dut.top_inst.REGFILE_inst.RF[16], 32'd7, "S3: poison R16 not executed");
        check1(dut.top_inst.BHT_inst.BHT[0], 1'b1, "S3: BHT[0] one-shot trained");
        check1(led, 1'b1, "S3: led (uo_out[0]) reflects done");

        // ------------------------------------------------------------
        $display("");
        $display("------------------------------------------------------------");
        $display(" SECTION 4: PROGRAM_STALL -- load-use stall as LAST instr");
        $display("            before target_pc (regression test)");
        $display("------------------------------------------------------------");
        hard_reset;
        for (i=0;i<=5;i=i+1) mmio_write(i*16'd4, progStall[i]);
        set_target(32'h00000018);
        set_run(1);
        wait_for_done(2000, done_flag);
        check1(done_flag, 1'b1, "S4: done");
        check32(dut.top_inst.PC_out, 32'h00000018, "S4: PC stopped at target");
        check32(dut.top_inst.REGFILE_inst.RF[1], 32'd10, "S4: R1");
        check32(dut.top_inst.REGFILE_inst.RF[2], 32'd25, "S4: R2");
        check32(dut.top_inst.REGFILE_inst.RF[3], 32'd35, "S4: R3");
        check32(dut.top_inst.REGFILE_inst.RF[4], 32'd35, "S4: R4");
        check32(dut.top_inst.REGFILE_inst.RF[5], 32'd25, "S4: R5 (previously lost to stall/stop_fetch race)");
        check32(dut.top_inst.DM_inst.DM[0],      32'd35, "S4: DM[0]");

        // ------------------------------------------------------------
        $display("");
        $display("------------------------------------------------------------");
        $display(" SECTION 5: PROGRAM_BRANCH_BOUNDARY -- sane target_pc");
        $display("------------------------------------------------------------");
        hard_reset;
        for (i=0;i<=4;i=i+1) mmio_write(i*16'd4, progBranch[i]);
        set_target(32'h00000014);
        set_run(1);
        wait_for_done(2000, done_flag);
        check1(done_flag, 1'b1, "S5: done (sane target_pc)");
        check32(dut.top_inst.PC_out, 32'h00000014, "S5: PC stopped at target");
        check32(dut.top_inst.REGFILE_inst.RF[2], 32'd2, "S5: R2 poisons NOT executed (reset value)");
        check32(dut.top_inst.REGFILE_inst.RF[3], 32'd77, "S5: R3 branch target DID execute");

        // ------------------------------------------------------------
        $display("");
        $display("------------------------------------------------------------");
        $display(" SECTION 6 (INFORMATIONAL): target_pc at a branch-skipped");
        $display("            address");
        $display("------------------------------------------------------------");
        hard_reset;
        for (i=0;i<=4;i=i+1) mmio_write(i*16'd4, progBranch[i]);
        set_target(32'h00000008);
        set_run(1);
        wait_for_done(500, done_flag);
        if (done_flag) begin
            note("target_pc at a branch-skipped address still completed -- no hang.");
            check32(dut.top_inst.REGFILE_inst.RF[3], 32'd77, "S6: R3 branch target executed despite coincidence");
        end else begin
            note("target_pc at a branch-skipped address never asserted done (timed out) -- CONFIRMS target_pc must be an address the real (taken) control flow actually revisits. Registers stayed sane -- a usage caveat, not corruption.");
            check32(dut.top_inst.REGFILE_inst.RF[2], 32'd2, "S6: R2 poisons still correctly not executed, even while hung");
            check32(dut.top_inst.REGFILE_inst.RF[3], 32'd77, "S6: R3 branch target still correctly executed, even while hung");
        end

        // ------------------------------------------------------------
        $display("");
        $display("------------------------------------------------------------");
        $display(" SECTION 7: PROGRAM_COMBO -- stall immediately followed by");
        $display("            a branch, both jammed at the halt boundary");
        $display("------------------------------------------------------------");
        hard_reset;
        for (i=0;i<=4;i=i+1) mmio_write(i*16'd4, progCombo[i]);
        set_target(32'h00000014);
        set_run(1);
        wait_for_done(2000, done_flag);
        check1(done_flag, 1'b1, "S7: done");
        check32(dut.top_inst.PC_out, 32'h00000014, "S7: PC stopped at target");
        check32(dut.top_inst.REGFILE_inst.RF[9],  32'd9,  "S7: R9 poison not executed (reset value)");
        check32(dut.top_inst.REGFILE_inst.RF[10], 32'd44, "S7: R10 branch target executed");

        // ------------------------------------------------------------
        $display("");
        $display("------------------------------------------------------------");
        $display(" SECTION 8: REPEATABILITY -- reload PROGRAM_STALL a third");
        $display("            full session overall via reset");
        $display("------------------------------------------------------------");
        hard_reset;
        check1(dut.top_inst.BHT_inst.BHT[0], 1'b0, "S8: BHT[0] cleared by reset");
        for (i=0;i<=5;i=i+1) mmio_write(i*16'd4, progStall[i]);
        set_target(32'h00000018);
        set_run(1);
        wait_for_done(2000, done_flag);
        check1(done_flag, 1'b1, "S8: done");
        check32(dut.top_inst.REGFILE_inst.RF[5], 32'd25, "S8: R5 identical result on repeat run");

        // ------------------------------------------------------------
        $display("");
        $display("------------------------------------------------------------");
        $display(" SECTION 9 (INFORMATIONAL): REPROGRAM WITHOUT RESET");
        $display("------------------------------------------------------------");
        set_run(0);
        for (i=0;i<=4;i=i+1) mmio_write(i*16'd4, progBranch[i]);
        set_target(32'h00000014);
        set_run(1);
        wait_for_done(500, done_flag);
        if (done_flag && dut.top_inst.REGFILE_inst.RF[3]===32'd77 && dut.top_inst.PC_out===32'h00000014)
            note("Reprogram WITHOUT reset SUCCEEDED -- CSR RUN toggling alone is sufficient between sessions.");
        else
            note("Reprogram WITHOUT reset did NOT re-run the new program -- `done` stayed latched from the previous session. A hardware reset (rst_n) is required between sessions.");

        // ------------------------------------------------------------
        $display("");
        $display("------------------------------------------------------------");
        $display(" SECTION 10: REGFILE MMIO-LOAD END-TO-END");
        $display("------------------------------------------------------------");
        hard_reset;
        mmio_write(16'h1014, 32'd40);
        mmio_write(16'h0000, 32'h00A53000); // ADD R6,R5,R5
        mmio_write(16'h0004, 32'h10060000); // SW  R6,0($0)
        set_target(32'h00000008);
        set_run(1);
        wait_for_done(1000, done_flag);
        check1(done_flag, 1'b1, "S10: done");
        check32(dut.top_inst.REGFILE_inst.RF[5], 32'd40, "S10: R5 stays as MMIO-preloaded (untouched)");
        check32(dut.top_inst.REGFILE_inst.RF[6], 32'd80, "S10: R6 = R5+R5 using MMIO-loaded value directly");
        check32(dut.top_inst.DM_inst.DM[0],      32'd80, "S10: DM[0] derived from MMIO-loaded register");

        // ------------------------------------------------------------
        $display("");
        $display("------------------------------------------------------------");
        $display(" SECTION 11: ENA TOLERANCE -- design must not break with");
        $display("             ena low, since this wrapper doesn't gate on it");
        $display("------------------------------------------------------------");
        hard_reset;
        ena = 1'b0;
        mmio_write(16'h0000, 32'h08010005); // ADDI R1,$0,5
        set_target(32'h00000004);
        set_run(1);
        wait_for_done(500, done_flag);
        check1(done_flag, 1'b1, "S11: done with ena=0 throughout");
        check32(dut.top_inst.REGFILE_inst.RF[1], 32'd5, "S11: R1 correct with ena=0 throughout");
        ena = 1'b1;

        // ------------------------------------------------------------
        $display("");
        $display("============================================================");
        $display(" SUMMARY");
        $display("============================================================");
        $display("  Informational notes: %0d", informational_notes);
        if (errors == 0) begin
            $display(" TT WRAPPER TEST: PASS");
            $display(" All sections checked; no errors detected anywhere, including");
            $display(" the continuous open-drain compliance monitor across the full run.");
        end else begin
            $display(" TT WRAPPER TEST: FAIL");
            $display(" Total errors = %0d", errors);
        end
        $display("============================================================");
        $display("");
        $finish;
    end

endmodule
