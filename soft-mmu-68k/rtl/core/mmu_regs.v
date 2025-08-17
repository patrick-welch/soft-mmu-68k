//------------------------------------------------------------------------------
// mmu_regs.v - Motorola 68k-compatible Soft MMU register block
// Packet: P1
//------------------------------------------------------------------------------

`timescale 1ns/1ps

module mmu_regs #(
    parameter VA_WIDTH = 32,     // Virtual address width
    parameter PA_WIDTH = 32      // Physical address width
)(
    input  wire                  clk,
    input  wire                  rst_n,        // Active-low synchronous reset

    // Register access interface
    input  wire                  wr_en,        // Write enable
    input  wire                  rd_en,        // Read enable
    input  wire [3:0]            addr,         // Register select (byte-aligned index)
    input  wire [31:0]           wr_data,      // Write data
    output reg  [31:0]           rd_data,      // Read data

    // Outputs to rest of MMU
    output reg  [PA_WIDTH-1:0]   crp,           // Current Root Pointer
    output reg  [PA_WIDTH-1:0]   srp,           // Supervisor Root Pointer
    output reg  [31:0]           tc,            // Translation Control
    output reg  [31:0]           tt0,           // Transparent Translation 0
    output reg  [31:0]           tt1,           // Transparent Translation 1
    output reg  [15:0]           mmusr          // MMU Status Register
);

    // Register address map (word offsets)
    localparam REG_CRP   = 4'h0;
    localparam REG_SRP   = 4'h1;
    localparam REG_TC    = 4'h2;
    localparam REG_TT0   = 4'h3;
    localparam REG_TT1   = 4'h4;
    localparam REG_MMUSR = 4'h5;

    // Reset defaults per Motorola spec (placeholder values — adjust per docs/refs)
    localparam [PA_WIDTH-1:0] CRP_RST   = {PA_WIDTH{1'b0}};
    localparam [PA_WIDTH-1:0] SRP_RST   = {PA_WIDTH{1'b0}};
    localparam [31:0]         TC_RST    = 32'h0000_0000;
    localparam [31:0]         TT0_RST   = 32'h0000_0000;
    localparam [31:0]         TT1_RST   = 32'h0000_0000;
    localparam [15:0]         MMUSR_RST = 16'h0000;

    // Sticky bits mask for MMUSR (per Motorola spec — adjust to match docs/refs)
    localparam [15:0] MMUSR_STICKY_MASK = 16'h00FF; // example: low byte is sticky

    // Sequential logic
    always @(posedge clk) begin
        if (!rst_n) begin
            crp   <= CRP_RST;
            srp   <= SRP_RST;
            tc    <= TC_RST;
            tt0   <= TT0_RST;
            tt1   <= TT1_RST;
            mmusr <= MMUSR_RST;
        end else begin
            if (wr_en) begin
                case (addr)
                    REG_CRP:   crp   <= wr_data[PA_WIDTH-1:0];
                    REG_SRP:   srp   <= wr_data[PA_WIDTH-1:0];
                    REG_TC:    tc    <= wr_data;
                    REG_TT0:   tt0   <= wr_data;
                    REG_TT1:   tt1   <= wr_data;
                    REG_MMUSR: begin
                        // MMUSR: writable bits + sticky bits that require explicit clear
                        // Sticky bits clear only if written as '0'
                        mmusr <= (mmusr & MMUSR_STICKY_MASK & ~wr_data[15:0]) |
                                 (wr_data[15:0] & ~MMUSR_STICKY_MASK);
                    end
                endcase
            end
        end
    end

    // Combinational read mux
    always @(*) begin
        rd_data = 32'h0000_0000;
        if (rd_en) begin
            case (addr)
                REG_CRP:   rd_data = {{(32-PA_WIDTH){1'b0}}, crp};
                REG_SRP:   rd_data = {{(32-PA_WIDTH){1'b0}}, srp};
                REG_TC:    rd_data = tc;
                REG_TT0:   rd_data = tt0;
                REG_TT1:   rd_data = tt1;
                REG_MMUSR: rd_data = {16'h0000, mmusr};
            endcase
        end
    end

endmodule
