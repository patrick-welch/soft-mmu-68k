//------------------------------------------------------------------------------
// mmu_regs_tb.sv - Unit testbench for mmu_regs
//------------------------------------------------------------------------------

`timescale 1ns/1ps

module mmu_regs_tb;

    localparam VA_WIDTH = 32;
    localparam PA_WIDTH = 32;

    localparam [3:0] REG_CRP   = 4'h0;
    localparam [3:0] REG_SRP   = 4'h1;
    localparam [3:0] REG_TC    = 4'h2;
    localparam [3:0] REG_TT0   = 4'h3;
    localparam [3:0] REG_TT1   = 4'h4;
    localparam [3:0] REG_MMUSR = 4'h5;

    logic                clk;
    logic                rst_n;
    logic                wr_en;
    logic                rd_en;
    logic [3:0]          addr;
    logic [31:0]         wr_data;
    logic [31:0]         rd_data;

    logic [PA_WIDTH-1:0] crp;
    logic [PA_WIDTH-1:0] srp;
    logic [31:0]         tc;
    logic [31:0]         tt0;
    logic [31:0]         tt1;
    logic [15:0]         mmusr;

    integer              phase;

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

    task automatic expect32;
        input [31:0] actual;
        input [31:0] expected;
        input [8*64-1:0] what;
        begin
            if (actual !== expected) begin
                $display("FAIL %0s: expected=%08h actual=%08h", what, expected, actual);
                $fatal(1);
            end
        end
    endtask

    task automatic expect16;
        input [15:0] actual;
        input [15:0] expected;
        input [8*64-1:0] what;
        begin
            if (actual !== expected) begin
                $display("FAIL %0s: expected=%04h actual=%04h", what, expected, actual);
                $fatal(1);
            end
        end
    endtask

    initial begin
        clk      = 1'b0;
        phase    = 0;
        rst_n    = 1'b1;
        wr_en    = 1'b0;
        rd_en    = 1'b0;
        addr     = 4'h0;
        wr_data  = 32'h0000_0000;
        $display("Starting mmu_regs_tb...");
    end

    always @(negedge clk) begin
        wr_en   <= 1'b0;
        rd_en   <= 1'b0;
        addr    <= 4'h0;
        wr_data <= 32'h0000_0000;

        case (phase)
            0: begin
                rst_n <= 1'b0;
            end
            1: begin
                rst_n <= 1'b1;
            end
            2: begin
                rd_en <= 1'b1;
                addr  <= REG_CRP;
            end
            3: begin
                rd_en <= 1'b1;
                addr  <= REG_SRP;
            end
            4: begin
                rd_en <= 1'b1;
                addr  <= REG_TC;
            end
            5: begin
                rd_en <= 1'b1;
                addr  <= REG_TT0;
            end
            6: begin
                rd_en <= 1'b1;
                addr  <= REG_TT1;
            end
            7: begin
                rd_en <= 1'b1;
                addr  <= REG_MMUSR;
            end
            8: begin
                wr_en   <= 1'b1;
                addr    <= REG_CRP;
                wr_data <= 32'h1234_5678;
            end
            9: begin
                wr_en   <= 1'b1;
                addr    <= REG_SRP;
                wr_data <= 32'h89AB_CDEF;
            end
            10: begin
                wr_en   <= 1'b1;
                addr    <= REG_TC;
                wr_data <= 32'h0000_8000;
            end
            11: begin
                wr_en   <= 1'b1;
                addr    <= REG_TT0;
                wr_data <= 32'h1357_2468;
            end
            12: begin
                wr_en   <= 1'b1;
                addr    <= REG_TT1;
                wr_data <= 32'h2468_1357;
            end
            13: begin
                rd_en <= 1'b1;
                addr  <= REG_CRP;
            end
            14: begin
                rd_en <= 1'b1;
                addr  <= REG_SRP;
            end
            15: begin
                rd_en <= 1'b1;
                addr  <= REG_TC;
            end
            16: begin
                rd_en <= 1'b1;
                addr  <= REG_TT0;
            end
            17: begin
                rd_en <= 1'b1;
                addr  <= REG_TT1;
            end
            18: begin
                wr_en   <= 1'b1;
                addr    <= REG_MMUSR;
                wr_data <= 32'h0000_FE8A;
            end
            19: begin
                rd_en <= 1'b1;
                addr  <= REG_MMUSR;
            end
            20: begin
                wr_en   <= 1'b1;
                addr    <= REG_MMUSR;
                wr_data <= 32'h0000_0085;
            end
            21: begin
                rd_en <= 1'b1;
                addr  <= REG_MMUSR;
            end
            22: begin
                wr_en   <= 1'b1;
                addr    <= REG_MMUSR;
                wr_data <= 32'h0000_8283;
            end
            23: begin
                wr_en   <= 1'b1;
                addr    <= REG_MMUSR;
                wr_data <= 32'h0000_820F;
            end
            24: begin
            end
            25: begin
                wr_en   <= 1'b1;
                addr    <= REG_MMUSR;
                wr_data <= 32'h0000_01F0;
            end
            26: begin
                rd_en <= 1'b1;
                addr  <= REG_MMUSR;
            end
            default: begin
            end
        endcase
    end

    always @(posedge clk) begin
        case (phase)
            2: begin
                expect32(crp,   32'h0000_0000, "CRP reset output");
                expect32(srp,   32'h0000_0000, "SRP reset output");
                expect32(tc,    32'h0000_0000, "TC reset output");
                expect32(tt0,   32'h0000_0000, "TT0 reset output");
                expect32(tt1,   32'h0000_0000, "TT1 reset output");
                expect16(mmusr, 16'h0000,      "MMUSR reset output");
                expect32(rd_data, 32'h0000_0000, "CRP reset readback");
            end
            3: begin
                expect32(rd_data, 32'h0000_0000, "SRP reset readback");
            end
            4: begin
                expect32(rd_data, 32'h0000_0000, "TC reset readback");
            end
            5: begin
                expect32(rd_data, 32'h0000_0000, "TT0 reset readback");
            end
            6: begin
                expect32(rd_data, 32'h0000_0000, "TT1 reset readback");
            end
            7: begin
                expect32(rd_data, 32'h0000_0000, "MMUSR reset readback");
            end
            13: begin
                expect32(crp, 32'h1234_5678, "CRP write output");
                expect32(srp, 32'h89AB_CDEF, "SRP write output");
                expect32(tc,  32'h0000_8000, "TC write output");
                expect32(tt0, 32'h1357_2468, "TT0 write output");
                expect32(tt1, 32'h2468_1357, "TT1 write output");
                expect32(rd_data, 32'h1234_5678, "CRP write/read");
            end
            14: begin
                expect32(rd_data, 32'h89AB_CDEF, "SRP write/read");
            end
            15: begin
                expect32(rd_data, 32'h0000_8000, "TC write/read");
            end
            16: begin
                expect32(rd_data, 32'h1357_2468, "TT0 write/read");
            end
            17: begin
                expect32(rd_data, 32'h2468_1357, "TT1 write/read");
            end
            19: begin
                expect16(mmusr, 16'hFE8A, "MMUSR sticky set + level write");
                expect32(rd_data, 32'h0000_FE8A, "MMUSR sticky set readback");
            end
            21: begin
                expect16(mmusr, 16'h0085, "MMUSR sticky clear/preserve + level update");
                expect32(rd_data, 32'h0000_0085, "MMUSR sticky clear/preserve readback");
            end
            24: begin
                expect16(mmusr, 16'h820F, "MMUSR sticky preserve on write-one");
            end
            26: begin
                expect16(mmusr, 16'h0080, "MMUSR reserved bits held low");
                expect32(rd_data, 32'h0000_0080, "MMUSR reserved bits readback");
                expect32(crp, 32'h1234_5678, "CRP unchanged by MMUSR writes");
                expect32(srp, 32'h89AB_CDEF, "SRP unchanged by MMUSR writes");
                expect32(tc,  32'h0000_8000, "TC unchanged by MMUSR writes");
                expect32(tt0, 32'h1357_2468, "TT0 unchanged by MMUSR writes");
                expect32(tt1, 32'h2468_1357, "TT1 unchanged by MMUSR writes");
            end
            27: begin
                $display("mmu_regs_tb PASSED.");
                $finish;
            end
            default: begin
            end
        endcase

        phase <= phase + 1;
    end

endmodule
