//------------------------------------------------------------------------------
// mmu_regs.v - Motorola 68k-compatible Soft MMU register block
//
// Compliance notes:
//   - MC68030 User's Manual, Section 1 "Supervisor Programming Model
//     Supplement" (Figure 1-3): CRP, SRP, TC, TT0, TT1, MMUSR register set.
//   - MC68851 PMMU User's Manual, Section 6.3.1 "Fault Signaling": status-class
//     MMUSR/PSR result bits for bus error, limit, supervisor, access,
//     write-protect, invalid, modified, and globally shared indications.
//   - MC68851 PMMU User's Manual, Section 7 "PMOVE Instruction": software
//     access to MMU registers; this first-pass block models MMUSR locally until
//     dedicated translation-result producers are wired in.
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

    // First-pass reset defaults:
    //   - TC reset = 0 disables translation immediately after reset.
    //   - Remaining register image is initialized to zero for deterministic
    //     power-on state while preserving the existing software-visible
    //     register interface.
    localparam [PA_WIDTH-1:0] CRP_RST   = {PA_WIDTH{1'b0}};
    localparam [PA_WIDTH-1:0] SRP_RST   = {PA_WIDTH{1'b0}};
    localparam [31:0]         TC_RST    = 32'h0000_0000;
    localparam [31:0]         TT0_RST   = 32'h0000_0000;
    localparam [31:0]         TT1_RST   = 32'h0000_0000;
    localparam [15:0]         MMUSR_RST = 16'h0000;

    // MMUSR layout used here follows the 68030/68851-visible status classes:
    //   [15] B  bus error
    //   [14] L  limit violation
    //   [13] S  supervisor violation
    //   [12] A  access level violation
    //   [11] W  write-protect violation
    //   [10] I  invalid descriptor/page
    //   [ 9] M  modified
    //   [ 8]    reserved, reads as zero in this block
    //   [ 7] G  globally shared
    //   [ 6:4]  reserved, reads as zero in this block
    //   [ 3:0]  level number
    //
    // First-pass MMUSR policy for this standalone register block:
    //   - status-class bits are software-writeable so unit tests and early
    //     bring-up can model MMUSR state before hardware producers exist;
    //   - writing '1' sets/preserves a status bit, writing '0' clears it;
    //   - level bits remain directly writeable;
    //   - reserved bits read back as zero.
    localparam [15:0] MMUSR_STICKY_MASK         = 16'hFE80;
    localparam [15:0] MMUSR_LEVEL_WR_MASK       = 16'h000F;
    localparam [15:0] MMUSR_SW_WRITABLE_MASK    = MMUSR_STICKY_MASK |
                                                   MMUSR_LEVEL_WR_MASK;

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
                        // Software-visible first-pass MMUSR image: writable
                        // status-class bits plus the low level field, with
                        // reserved bits forced low.
                        mmusr <= wr_data[15:0] & MMUSR_SW_WRITABLE_MASK;
                    end
                    default: begin
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
                default:   rd_data = 32'h0000_0000;
            endcase
        end
    end

endmodule
