//------------------------------------------------------------------------------
// mmu_regs_tb.sv - Unit testbench for mmu_regs
//------------------------------------------------------------------------------

`timescale 1ns/1ps

module mmu_regs_tb;

    localparam VA_WIDTH = 32;
    localparam PA_WIDTH = 32;

    logic                  clk;
    logic                  rst_n;
    logic                  wr_en, rd_en;
    logic [3:0]            addr;
    logic [31:0]           wr_data;
    logic [31:0]           rd_data;

    logic [PA_WIDTH-1:0]   crp;
    logic [PA_WIDTH-1:0]   srp;
    logic [31:0]           tc;
    logic [31:0]           tt0;
    logic [31:0]           tt1;
    logic [15:0]           mmusr;

    // DUT
    mmu_regs #(
        .VA_WIDTH(VA_WIDTH),
        .PA_WIDTH(PA_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .addr(addr),
        .wr_data(wr_data),
        .rd_data(rd_data),
        .crp(crp),
        .srp(srp),
        .tc(tc),
        .tt0(tt0),
        .tt1(tt1),
        .mmusr(mmusr)
    );

    // Clock gen
    initial clk = 0;
    always #5 clk = ~clk;

    // Test procedure
    initial begin
        $display("Starting mmu_regs_tb...");
        rst_n = 1;
        wr_en = 0;
        rd_en = 0;
        addr = 0;
        wr_data = 0;

        // Reset
        @(posedge clk);
        rst_n = 0;
        @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        // Check reset values
        assert(crp   == {PA_WIDTH{1'b0}});
        assert(srp   == {PA_WIDTH{1'b0}});
        assert(tc    == 32'h0000_0000);
        assert(tt0   == 32'h0000_0000);
        assert(tt1   == 32'h0000_0000);
        assert(mmusr == 16'h0000);

        // Write/read CRP
        wr_en = 1;
        addr = 4'h0;
        wr_data = 32'h1234_5678;
        @(posedge clk);
        wr_en = 0; rd_en = 1;
        @(posedge clk);
        assert(rd_data == 32'h1234_5678);
        rd_en = 0;

        // MMUSR sticky bit behavior
        wr_en = 1;
        addr = 4'h5;
        wr_data = 32'h0000_00FF; // set sticky bits
        @(posedge clk);
        wr_en = 0;

        // Attempt clear of sticky bits by writing 0
        wr_en = 1;
        addr = 4'h5;
        wr_data = 32'h0000_0000; // should clear sticky bits
        @(posedge clk);
        wr_en = 0;

        // Final check
        rd_en = 1;
        addr = 4'h5;
        @(posedge clk);
        assert(rd_data[7:0] == 8'h00);
        rd_en = 0;

        $display("All tests passed.");
        $finish;
    end

endmodule
