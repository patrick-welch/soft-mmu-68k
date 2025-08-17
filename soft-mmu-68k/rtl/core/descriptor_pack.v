`timescale 1ns/1ps
`default_nettype none
// -----------------------------------------------------------------------------
// Soft MMU 68k : descriptor_pack
// Combinational pack/unpack for 68851/68030 root, pointer, and page descriptors
// -----------------------------------------------------------------------------
// Notes
//  • This module does NOT hard-code layout. All field positions are parameters.
//  • Defaults use a compact, contiguous layout so round-trips work out-of-box.
//  • To match Motorola layouts, set *_POS parameters to the correct bit indices
//    (see docs/refs/68851_notes.md). The testbench includes a sanity checker
//    for overlapping/overflowing fields.
//  • Purely combinational (no clock/reset), as requested.
// -----------------------------------------------------------------------------

module descriptor_pack #(
  // ----------------------------
  // Global configuration
  // ----------------------------
  parameter int DESCR_WIDTH   = 32,
  parameter int PA_WIDTH      = 32,    // physical address width
  parameter int LIMIT_WIDTH   = 12,    // limit/length bits for root/pointer
  parameter int PAGE_SHIFT    = 12,    // page size = 1<<PAGE_SHIFT
  // ----------------------------
  // Kind encoding (do not change unless you also update testbench)
  // ----------------------------
  parameter [1:0] KIND_ROOT   = 2'd0,
  parameter [1:0] KIND_PTR    = 2'd1,
  parameter [1:0] KIND_PAGE   = 2'd2,

  // ----------------------------------------------------------------------------
  // Root Descriptor bit positions in packed word (all indices 0..DESCR_WIDTH-1)
  // ----------------------------------------------------------------------------
  // Example default packing (MSB..LSB):
  // [DT(2)][V][I][LIMIT(LIMIT_WIDTH)][ADDR(PA_WIDTH)]
  // Everything not covered is zeroed.
  parameter int R_DT_HI       = DESCR_WIDTH-1,
  parameter int R_DT_LO       = DESCR_WIDTH-2,
  parameter int R_V_BIT       = DESCR_WIDTH-3,
  parameter int R_I_BIT       = DESCR_WIDTH-4,
  parameter int R_LIMIT_HI    = R_I_BIT-1,
  parameter int R_LIMIT_LO    = R_LIMIT_HI-LIMIT_WIDTH+1,
  parameter int R_ADDR_HI     = R_LIMIT_LO-1,
  parameter int R_ADDR_LO     = R_ADDR_HI-PA_WIDTH+1,

  // ----------------------------------------------------------------------------
  // Pointer Descriptor bit positions
  // ----------------------------------------------------------------------------
  // Default: same field order as root
  parameter int P_DT_HI       = DESCR_WIDTH-1,
  parameter int P_DT_LO       = DESCR_WIDTH-2,
  parameter int P_V_BIT       = DESCR_WIDTH-3,
  parameter int P_I_BIT       = DESCR_WIDTH-4,
  parameter int P_LIMIT_HI    = P_I_BIT-1,
  parameter int P_LIMIT_LO    = P_LIMIT_HI-LIMIT_WIDTH+1,
  parameter int P_ADDR_HI     = P_LIMIT_LO-1,
  parameter int P_ADDR_LO     = P_ADDR_HI-PA_WIDTH+1,

  // ----------------------------------------------------------------------------
  // Page Descriptor bit positions
  // ----------------------------------------------------------------------------
  // Typical page fields: DT,V,Supervisor(S),WriteProtect(WP),CacheInhibit(CI),
  // Modified(M),Used(U), and PFN (physical frame number = PA >> PAGE_SHIFT).
  // Default order (MSB..LSB): [DT(2)][V][S][WP][CI][M][U][PFN]
  parameter int PG_DT_HI      = DESCR_WIDTH-1,
  parameter int PG_DT_LO      = DESCR_WIDTH-2,
  parameter int PG_V_BIT      = DESCR_WIDTH-3,
  parameter int PG_S_BIT      = DESCR_WIDTH-4,
  parameter int PG_WP_BIT     = DESCR_WIDTH-5,
  parameter int PG_CI_BIT     = DESCR_WIDTH-6,
  parameter int PG_M_BIT      = DESCR_WIDTH-7,
  parameter int PG_U_BIT      = DESCR_WIDTH-8,
  // Packed PFN width = PA_WIDTH - PAGE_SHIFT
  parameter int PFN_WIDTH     = (PA_WIDTH > PAGE_SHIFT) ? (PA_WIDTH-PAGE_SHIFT) : 1,
  parameter int PG_PFN_HI     = PG_U_BIT-1,
  parameter int PG_PFN_LO     = PG_PFN_HI-PFN_WIDTH+1
)(
  // =========================
  // Control
  // =========================
  input  wire [1:0] kind_i,  // KIND_ROOT/KIND_PTR/KIND_PAGE select

  // =========================
  // Root inputs (to pack)
  // =========================
  input  wire        r_v_i,
  input  wire        r_i_i,
  input  wire [1:0]  r_dt_i,
  input  wire [LIMIT_WIDTH-1:0] r_limit_i,
  input  wire [PA_WIDTH-1:0]    r_addr_i,

  // =========================
  // Pointer inputs (to pack)
  // =========================
  input  wire        p_v_i,
  input  wire        p_i_i,
  input  wire [1:0]  p_dt_i,
  input  wire [LIMIT_WIDTH-1:0] p_limit_i,
  input  wire [PA_WIDTH-1:0]    p_addr_i,

  // =========================
  // Page inputs (to pack)
  // =========================
  input  wire        pg_v_i,
  input  wire [1:0]  pg_dt_i,
  input  wire        pg_s_i,   // supervisor-only
  input  wire        pg_wp_i,  // write-protect
  input  wire        pg_ci_i,  // cache inhibit
  input  wire        pg_m_i,   // modified
  input  wire        pg_u_i,   // used
  input  wire [PA_WIDTH-1:0]    pg_pa_i,  // full PA; internally shifted to PFN

  // =========================
  // Pack output
  // =========================
  output reg  [DESCR_WIDTH-1:0] packed_o,

  // =========================
  // Unpack input (shared)
  // =========================
  input  wire [DESCR_WIDTH-1:0] packed_i,

  // =========================
  // Unpacked outputs (all 3 decoded in parallel; use the set matching kind_i)
  // =========================
  // Root
  output reg        r_v_o,
  output reg        r_i_o,
  output reg [1:0]  r_dt_o,
  output reg [LIMIT_WIDTH-1:0] r_limit_o,
  output reg [PA_WIDTH-1:0]    r_addr_o,

  // Pointer
  output reg        p_v_o,
  output reg        p_i_o,
  output reg [1:0]  p_dt_o,
  output reg [LIMIT_WIDTH-1:0] p_limit_o,
  output reg [PA_WIDTH-1:0]    p_addr_o,

  // Page
  output reg        pg_v_o,
  output reg [1:0]  pg_dt_o,
  output reg        pg_s_o,
  output reg        pg_wp_o,
  output reg        pg_ci_o,
  output reg        pg_m_o,
  output reg        pg_u_o,
  output reg [PA_WIDTH-1:0]    pg_pa_o   // reconstructed from PFN<<PAGE_SHIFT
);

  // ----------------------------------------------------------------------------
  // Helpers
  // ----------------------------------------------------------------------------
  wire [PFN_WIDTH-1:0] pg_pfn_i = (PA_WIDTH > PAGE_SHIFT) ? pg_pa_i[PA_WIDTH-1:PAGE_SHIFT] :
                                  {PFN_WIDTH{1'b0}};

  // ----------------------------------------------------------------------------
  // PACK (combinational)
  // ----------------------------------------------------------------------------
  always @* begin
    packed_o = {DESCR_WIDTH{1'b0}};
    case (kind_i)
      KIND_ROOT: begin
        packed_o[R_DT_HI:R_DT_LO]     = r_dt_i;
        packed_o[R_V_BIT]             = r_v_i;
        packed_o[R_I_BIT]             = r_i_i;
        packed_o[R_LIMIT_HI:R_LIMIT_LO]= r_limit_i;
        packed_o[R_ADDR_HI:R_ADDR_LO] = r_addr_i[PA_WIDTH-1:0];
      end
      KIND_PTR: begin
        packed_o[P_DT_HI:P_DT_LO]     = p_dt_i;
        packed_o[P_V_BIT]             = p_v_i;
        packed_o[P_I_BIT]             = p_i_i;
        packed_o[P_LIMIT_HI:P_LIMIT_LO]= p_limit_i;
        packed_o[P_ADDR_HI:P_ADDR_LO] = p_addr_i[PA_WIDTH-1:0];
      end
      KIND_PAGE: begin
        packed_o[PG_DT_HI:PG_DT_LO] = pg_dt_i;
        packed_o[PG_V_BIT]          = pg_v_i;
        packed_o[PG_S_BIT]          = pg_s_i;
        packed_o[PG_WP_BIT]         = pg_wp_i;
        packed_o[PG_CI_BIT]         = pg_ci_i;
        packed_o[PG_M_BIT]          = pg_m_i;
        packed_o[PG_U_BIT]          = pg_u_i;
        packed_o[PG_PFN_HI:PG_PFN_LO]= pg_pfn_i;
      end
      default: begin
        packed_o = {DESCR_WIDTH{1'b0}};
      end
    endcase
  end

  // ----------------------------------------------------------------------------
  // UNPACK (combinational; all 3 variants in parallel)
  // ----------------------------------------------------------------------------
  always @* begin
    // Root
    r_dt_o    = packed_i[R_DT_HI:R_DT_LO];
    r_v_o     = packed_i[R_V_BIT];
    r_i_o     = packed_i[R_I_BIT];
    r_limit_o = packed_i[R_LIMIT_HI:R_LIMIT_LO];
    r_addr_o  = { { (PA_WIDTH-(R_ADDR_HI-R_ADDR_LO+1)){1'b0} }, packed_i[R_ADDR_HI:R_ADDR_LO] };

    // Pointer
    p_dt_o    = packed_i[P_DT_HI:P_DT_LO];
    p_v_o     = packed_i[P_V_BIT];
    p_i_o     = packed_i[P_I_BIT];
    p_limit_o = packed_i[P_LIMIT_HI:P_LIMIT_LO];
    p_addr_o  = { { (PA_WIDTH-(P_ADDR_HI-P_ADDR_LO+1)){1'b0} }, packed_i[P_ADDR_HI:P_ADDR_LO] };

    // Page
    pg_dt_o   = packed_i[PG_DT_HI:PG_DT_LO];
    pg_v_o    = packed_i[PG_V_BIT];
    pg_s_o    = packed_i[PG_S_BIT];
    pg_wp_o   = packed_i[PG_WP_BIT];
    pg_ci_o   = packed_i[PG_CI_BIT];
    pg_m_o    = packed_i[PG_M_BIT];
    pg_u_o    = packed_i[PG_U_BIT];

    // PFN -> PA (shift left PAGE_SHIFT)
    begin : REBUILD_PA
      integer i;
      reg [PFN_WIDTH-1:0] pfn;
      reg [PA_WIDTH-1:0]  tmp;
      pfn = packed_i[PG_PFN_HI:PG_PFN_LO];
      tmp = {PA_WIDTH{1'b0}};
      // place PFN into PA[PA_WIDTH-1:PAGE_SHIFT], zeros below
      tmp[PA_WIDTH-1:PAGE_SHIFT] = pfn;
      tmp[PAGE_SHIFT-1:0]        = {PAGE_SHIFT{1'b0}};
      pg_pa_o = tmp;
    end
  end

endmodule
`default_nettype wire
