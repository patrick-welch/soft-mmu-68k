`timescale 1ns/1ps
`default_nettype none
// -----------------------------------------------------------------------------
// Soft MMU 68k : descriptor_pack
// Combinational pack/unpack for Motorola-style descriptors.
//
// Compliance references used for the bit locations below:
//   - MC68851 PMMU User's Manual, Section 5.1.5.3 "Descriptor Field Definitions"
//   - MC68851 PMMU User's Manual, Section 6.1.1 "Root Pointer"
//   - MC68030 User's Manual, Section 9.5.1.1 "Descriptor Field Definitions"
//   - MC68030 User's Manual, Sections 9.5.1.2-9.5.1.8 descriptor format figures
//
// This module keeps the existing port list, but the legacy valid/invalid ports are
// compatibility shims around Motorola descriptor encodings:
//   - *_v_* is not stored as a standalone bit; pack forces DT=00 when clear and
//     unpack reports valid when DT!=00.
//   - r_i_*/p_i_* carry the Motorola L/U control for the root/pointer subset.
//
// The packed defaults implement a 64-bit long-format-oriented subset:
//   - Root    : L/U + LIMIT + DT + table address
//   - Pointer : L/U + LIMIT + DT + table address
//   - Page    : S/CI/M/U/WP + DT + page address
//
// Fields that exist in Motorola manuals but are not present on this module's
// interface (SG, access levels, gate/lock, etc.) are packed as zero.
// Purely combinational: no clock/reset/state.
// -----------------------------------------------------------------------------

module descriptor_pack #(
  // ----------------------------
  // Global configuration
  // ----------------------------
  parameter int DESCR_WIDTH   = 64,
  parameter int PA_WIDTH      = 32,
  parameter int LIMIT_WIDTH   = 15,
  parameter int PAGE_SHIFT    = 12,
  // ----------------------------
  // Kind encoding (do not change unless you also update testbench)
  // ----------------------------
  parameter [1:0] KIND_ROOT   = 2'd0,
  parameter [1:0] KIND_PTR    = 2'd1,
  parameter [1:0] KIND_PAGE   = 2'd2,

  // ----------------------------------------------------------------------------
  // Root descriptor defaults: Motorola long-format root-pointer subset
  // ----------------------------------------------------------------------------
  parameter int R_DT_HI       = 33,
  parameter int R_DT_LO       = 32,
  parameter int R_V_BIT       = -1,   // compatibility only; not stored
  parameter int R_I_BIT       = 63,   // legacy r_i_* carries Motorola L/U
  parameter int R_LIMIT_HI    = 62,
  parameter int R_LIMIT_LO    = 48,
  parameter int R_ADDR_HI     = 31,
  parameter int R_ADDR_LO     = 4,

  // ----------------------------------------------------------------------------
  // Pointer descriptor defaults: Motorola long-format table-descriptor subset
  // ----------------------------------------------------------------------------
  parameter int P_DT_HI       = 33,
  parameter int P_DT_LO       = 32,
  parameter int P_V_BIT       = -1,   // compatibility only; not stored
  parameter int P_I_BIT       = 63,   // legacy p_i_* carries Motorola L/U
  parameter int P_LIMIT_HI    = 62,
  parameter int P_LIMIT_LO    = 48,
  parameter int P_ADDR_HI     = 31,
  parameter int P_ADDR_LO     = 4,

  // ----------------------------------------------------------------------------
  // Page descriptor defaults: Motorola long-format page-descriptor subset
  // ----------------------------------------------------------------------------
  parameter int PG_DT_HI      = 33,
  parameter int PG_DT_LO      = 32,
  parameter int PG_V_BIT      = -1,   // compatibility only; not stored
  parameter int PG_S_BIT      = 40,
  parameter int PG_WP_BIT     = 34,
  parameter int PG_CI_BIT     = 38,
  parameter int PG_M_BIT      = 36,
  parameter int PG_U_BIT      = 35,
  parameter int PFN_WIDTH     = (PA_WIDTH > PAGE_SHIFT) ? (PA_WIDTH-PAGE_SHIFT) : 1,
  parameter int PG_PFN_HI     = 31,
  parameter int PG_PFN_LO     = 8
)(
  // =========================
  // Control
  // =========================
  input  wire [1:0] kind_i,

  // =========================
  // Root inputs (to pack)
  // =========================
  input  wire        r_v_i,
  input  wire        r_i_i,
  input  wire [1:0]  r_dt_i,
  input  wire [LIMIT_WIDTH-1:0] r_limit_i,
  /* verilator lint_off UNUSED */
  input  wire [PA_WIDTH-1:0]    r_addr_i,
  /* verilator lint_on UNUSED */

  // =========================
  // Pointer inputs (to pack)
  // =========================
  input  wire        p_v_i,
  input  wire        p_i_i,
  input  wire [1:0]  p_dt_i,
  input  wire [LIMIT_WIDTH-1:0] p_limit_i,
  /* verilator lint_off UNUSED */
  input  wire [PA_WIDTH-1:0]    p_addr_i,
  /* verilator lint_on UNUSED */

  // =========================
  // Page inputs (to pack)
  // =========================
  input  wire        pg_v_i,
  input  wire [1:0]  pg_dt_i,
  input  wire        pg_s_i,
  input  wire        pg_wp_i,
  input  wire        pg_ci_i,
  input  wire        pg_m_i,
  input  wire        pg_u_i,
  /* verilator lint_off UNUSED */
  input  wire [PA_WIDTH-1:0]    pg_pa_i,
  /* verilator lint_on UNUSED */

  // =========================
  // Pack output
  // =========================
  output reg  [DESCR_WIDTH-1:0] packed_o,

  // =========================
  // Unpack input (shared)
  // =========================
  input  wire [DESCR_WIDTH-1:0] packed_i,

  // =========================
  // Unpacked outputs
  // =========================
  output reg        r_v_o,
  output reg        r_i_o,
  output reg [1:0]  r_dt_o,
  output reg [LIMIT_WIDTH-1:0] r_limit_o,
  output reg [PA_WIDTH-1:0]    r_addr_o,

  output reg        p_v_o,
  output reg        p_i_o,
  output reg [1:0]  p_dt_o,
  output reg [LIMIT_WIDTH-1:0] p_limit_o,
  output reg [PA_WIDTH-1:0]    p_addr_o,

  output reg        pg_v_o,
  output reg [1:0]  pg_dt_o,
  output reg        pg_s_o,
  output reg        pg_wp_o,
  output reg        pg_ci_o,
  output reg        pg_m_o,
  output reg        pg_u_o,
  output reg [PA_WIDTH-1:0]    pg_pa_o
);

  localparam int ROOT_ADDR_WIDTH = (R_ADDR_HI >= R_ADDR_LO) ? (R_ADDR_HI - R_ADDR_LO + 1) : 1;
  localparam int PTR_ADDR_WIDTH  = (P_ADDR_HI >= P_ADDR_LO) ? (P_ADDR_HI - P_ADDR_LO + 1) : 1;
  localparam int PAGE_ADDR_WIDTH = (PG_PFN_HI >= PG_PFN_LO) ? (PG_PFN_HI - PG_PFN_LO + 1) : 1;

  localparam int ROOT_ADDR_SRC_LO = 4;
  localparam int PTR_ADDR_SRC_LO  = 4;
  localparam int PAGE_ADDR_SRC_LO = 8;

  localparam int ROOT_ADDR_COPY_W = ((PA_WIDTH > ROOT_ADDR_SRC_LO) &&
                                     ((PA_WIDTH - ROOT_ADDR_SRC_LO) < ROOT_ADDR_WIDTH)) ?
                                    (PA_WIDTH - ROOT_ADDR_SRC_LO) : ROOT_ADDR_WIDTH;
  localparam int PTR_ADDR_COPY_W  = ((PA_WIDTH > PTR_ADDR_SRC_LO) &&
                                     ((PA_WIDTH - PTR_ADDR_SRC_LO) < PTR_ADDR_WIDTH)) ?
                                    (PA_WIDTH - PTR_ADDR_SRC_LO) : PTR_ADDR_WIDTH;
  localparam int PAGE_ADDR_COPY_W = ((PA_WIDTH > PAGE_ADDR_SRC_LO) &&
                                     ((PA_WIDTH - PAGE_ADDR_SRC_LO) < PAGE_ADDR_WIDTH)) ?
                                    (PA_WIDTH - PAGE_ADDR_SRC_LO) : PAGE_ADDR_WIDTH;

  wire [1:0] r_dt_enc  = r_v_i  ? r_dt_i  : 2'b00;
  wire [1:0] p_dt_enc  = p_v_i  ? p_dt_i  : 2'b00;
  wire [1:0] pg_dt_enc = pg_v_i ? pg_dt_i : 2'b00;

  initial begin
    if (DESCR_WIDTH < 64) begin
      $fatal(1, "descriptor_pack DESCR_WIDTH must be >= 64 for Motorola long-format defaults");
    end
    if (LIMIT_WIDTH > (R_LIMIT_HI - R_LIMIT_LO + 1)) begin
      $fatal(1, "descriptor_pack LIMIT_WIDTH exceeds Motorola root/pointer limit field");
    end
    if (PAGE_SHIFT < 8) begin
      $fatal(1, "descriptor_pack PAGE_SHIFT must be >= 8 for Motorola page-address field");
    end
  end

  always @* begin
    packed_o = {DESCR_WIDTH{1'b0}};

    case (kind_i)
      KIND_ROOT: begin
        packed_o[R_I_BIT] = r_i_i;
        packed_o[R_LIMIT_HI -: LIMIT_WIDTH] = r_limit_i;
        packed_o[R_DT_HI:R_DT_LO] = r_dt_enc;
        if (ROOT_ADDR_COPY_W > 0) begin
          packed_o[R_ADDR_LO +: ROOT_ADDR_COPY_W] = r_addr_i[ROOT_ADDR_SRC_LO +: ROOT_ADDR_COPY_W];
        end
      end

      KIND_PTR: begin
        packed_o[P_I_BIT] = p_i_i;
        packed_o[P_LIMIT_HI -: LIMIT_WIDTH] = p_limit_i;
        packed_o[P_DT_HI:P_DT_LO] = p_dt_enc;
        if (PTR_ADDR_COPY_W > 0) begin
          packed_o[P_ADDR_LO +: PTR_ADDR_COPY_W] = p_addr_i[PTR_ADDR_SRC_LO +: PTR_ADDR_COPY_W];
        end
      end

      KIND_PAGE: begin
        packed_o[PG_S_BIT] = pg_s_i;
        packed_o[PG_CI_BIT] = pg_ci_i;
        packed_o[PG_M_BIT] = pg_m_i;
        packed_o[PG_U_BIT] = pg_u_i;
        packed_o[PG_WP_BIT] = pg_wp_i;
        packed_o[PG_DT_HI:PG_DT_LO] = pg_dt_enc;
        if (PAGE_ADDR_COPY_W > 0) begin
          packed_o[PG_PFN_LO +: PAGE_ADDR_COPY_W] = pg_pa_i[PAGE_ADDR_SRC_LO +: PAGE_ADDR_COPY_W];
        end
      end

      default: begin
        packed_o = {DESCR_WIDTH{1'b0}};
      end
    endcase
  end

  always @* begin
    // Root: r_v_o is a compatibility decode from DT != invalid.
    r_dt_o    = packed_i[R_DT_HI:R_DT_LO];
    r_v_o     = (packed_i[R_DT_HI:R_DT_LO] != 2'b00);
    r_i_o     = packed_i[R_I_BIT];
    r_limit_o = packed_i[R_LIMIT_HI -: LIMIT_WIDTH];
    r_addr_o  = {PA_WIDTH{1'b0}};
    if (ROOT_ADDR_COPY_W > 0) begin
      r_addr_o[ROOT_ADDR_SRC_LO +: ROOT_ADDR_COPY_W] = packed_i[R_ADDR_LO +: ROOT_ADDR_COPY_W];
    end

    // Pointer: p_v_o is a compatibility decode from DT != invalid.
    p_dt_o    = packed_i[P_DT_HI:P_DT_LO];
    p_v_o     = (packed_i[P_DT_HI:P_DT_LO] != 2'b00);
    p_i_o     = packed_i[P_I_BIT];
    p_limit_o = packed_i[P_LIMIT_HI -: LIMIT_WIDTH];
    p_addr_o  = {PA_WIDTH{1'b0}};
    if (PTR_ADDR_COPY_W > 0) begin
      p_addr_o[PTR_ADDR_SRC_LO +: PTR_ADDR_COPY_W] = packed_i[P_ADDR_LO +: PTR_ADDR_COPY_W];
    end

    // Page: pg_v_o is a compatibility decode from DT != invalid.
    pg_dt_o   = packed_i[PG_DT_HI:PG_DT_LO];
    pg_v_o    = (packed_i[PG_DT_HI:PG_DT_LO] != 2'b00);
    pg_s_o    = packed_i[PG_S_BIT];
    pg_wp_o   = packed_i[PG_WP_BIT];
    pg_ci_o   = packed_i[PG_CI_BIT];
    pg_m_o    = packed_i[PG_M_BIT];
    pg_u_o    = packed_i[PG_U_BIT];
    pg_pa_o   = {PA_WIDTH{1'b0}};
    if (PAGE_ADDR_COPY_W > 0) begin
      pg_pa_o[PAGE_ADDR_SRC_LO +: PAGE_ADDR_COPY_W] = packed_i[PG_PFN_LO +: PAGE_ADDR_COPY_W];
    end
    if (PAGE_SHIFT > 0) begin
      pg_pa_o[PAGE_SHIFT-1:0] = {PAGE_SHIFT{1'b0}};
    end
  end

endmodule
`default_nettype wire
