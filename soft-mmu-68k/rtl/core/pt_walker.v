`timescale 1ns/1ps
`default_nettype none
// -----------------------------------------------------------------------------
// Soft MMU 68k : pt_walker
// Minimal single-level page-table walker with a one-request abstract memory bus.
//
// Compliance:
//   - MC68851 PMMU User's Manual, Section 4 "Address Translation Tables"
//   - MC68851 PMMU User's Manual, Section 4 "Page Descriptors"
//   - MC68030 User's Manual, Section 9 "Memory Management Unit"
//
// Packet scope:
//   - Deliberately minimal, reviewable, and single-level only.
//   - One descriptor read per translation miss.
//   - Permission faults are not handled here; attributes are forwarded to P3.
//   - Faults in this packet:
//       * invalid descriptor  : descriptor valid bit clear
//       * unmapped            : descriptor type not page, or VA outside table span
//       * bus error           : abstract memory response indicates error
// -----------------------------------------------------------------------------

module pt_walker #(
  parameter integer VA_WIDTH    = 24,
  parameter integer PA_WIDTH    = 24,
  parameter integer PAGE_SHIFT  = 12,
  parameter integer DESCR_WIDTH = 32,
  parameter integer FC_WIDTH    = 3,
  parameter integer ATTR_WIDTH  = 5,

  // Compact default page-descriptor layout used by this packet.
  parameter integer DESC_DT_HI  = DESCR_WIDTH-1,
  parameter integer DESC_DT_LO  = DESCR_WIDTH-2,
  parameter integer DESC_V_BIT  = DESCR_WIDTH-3,
  parameter integer DESC_S_BIT  = DESCR_WIDTH-4,
  parameter integer DESC_WP_BIT = DESCR_WIDTH-5,
  parameter integer DESC_CI_BIT = DESCR_WIDTH-6,
  parameter integer DESC_M_BIT  = DESCR_WIDTH-7,
  parameter integer DESC_U_BIT  = DESCR_WIDTH-8,

  parameter [1:0] DESC_DT_PAGE  = 2'b10,
  parameter [1:0] FAULT_NONE    = 2'b00,
  parameter [1:0] FAULT_INVALID = 2'b01,
  parameter [1:0] FAULT_UNMAPPED= 2'b10,
  parameter [1:0] FAULT_BUS     = 2'b11
) (
  input  wire                  clk,
  input  wire                  rst_n,

  input  wire                  start_i,
  input  wire [VA_WIDTH-1:0]   va_i,
  input  wire [FC_WIDTH-1:0]   fc_i,
  input  wire [PA_WIDTH-1:0]   table_base_i,
  input  wire [VA_WIDTH-PAGE_SHIFT-1:0] table_entries_i,

  output wire                  mem_req_valid_o,
  output wire [PA_WIDTH-1:0]   mem_req_addr_o,
  input  wire                  mem_resp_valid_i,
  input  wire [DESCR_WIDTH-1:0] mem_resp_data_i,
  input  wire                  mem_resp_err_i,

  output wire                  busy_o,
  output reg                   done_o,
  output reg                   refill_valid_o,
  output reg  [VA_WIDTH-1:0]   refill_va_o,
  output reg  [PA_WIDTH-1:0]   walk_pa_base_o,
  output reg  [PA_WIDTH-PAGE_SHIFT-1:0] walk_ppn_o,
  output reg  [ATTR_WIDTH-1:0] walk_attr_o,
  output reg                   fault_valid_o,
  output reg  [1:0]            fault_code_o
);

  localparam integer VPN_WIDTH         = VA_WIDTH - PAGE_SHIFT;
  localparam integer PFN_WIDTH         = (PA_WIDTH > PAGE_SHIFT) ? (PA_WIDTH - PAGE_SHIFT) : 1;
  localparam integer DESCR_BYTES       = DESCR_WIDTH / 8;
  localparam integer DESCR_BYTE_SHIFT  = $clog2(DESCR_BYTES);
  localparam integer DESC_PFN_HI       = DESC_U_BIT - 1;
  localparam integer DESC_PFN_LO       = DESC_PFN_HI - PFN_WIDTH + 1;

  localparam [1:0] ST_IDLE = 2'd0;
  localparam [1:0] ST_WAIT = 2'd1;

  reg [1:0]              state_q;
  reg [PA_WIDTH-1:0]     mem_req_addr_q;
  reg                    mem_req_valid_q;

  wire [VPN_WIDTH-1:0] start_vpn = va_i[VA_WIDTH-1:PAGE_SHIFT];
  wire [PFN_WIDTH-1:0] resp_pfn  = mem_resp_data_i[DESC_PFN_HI:DESC_PFN_LO];
  wire                  resp_v    = mem_resp_data_i[DESC_V_BIT];
  wire [1:0]            resp_dt   = mem_resp_data_i[DESC_DT_HI:DESC_DT_LO];

  wire [ATTR_WIDTH-1:0] resp_attr = {
    mem_resp_data_i[DESC_S_BIT],
    mem_resp_data_i[DESC_WP_BIT],
    mem_resp_data_i[DESC_CI_BIT],
    mem_resp_data_i[DESC_M_BIT],
    mem_resp_data_i[DESC_U_BIT]
  };

  /* verilator lint_off UNUSED */
  wire unused_fc = ^fc_i;
  /* verilator lint_on UNUSED */

  assign busy_o          = (state_q != ST_IDLE);
  assign mem_req_valid_o = mem_req_valid_q;
  assign mem_req_addr_o  = mem_req_addr_q;

  initial begin
    if (VA_WIDTH <= PAGE_SHIFT) begin
      $fatal(1, "pt_walker VA_WIDTH must exceed PAGE_SHIFT");
    end
    if (PA_WIDTH <= PAGE_SHIFT) begin
      $fatal(1, "pt_walker PA_WIDTH must exceed PAGE_SHIFT");
    end
    if ((DESCR_WIDTH % 8) != 0) begin
      $fatal(1, "pt_walker DESCR_WIDTH must be byte-aligned");
    end
    if ((1 << DESCR_BYTE_SHIFT) != DESCR_BYTES) begin
      $fatal(1, "pt_walker DESCR_WIDTH/8 must be a power of two");
    end
    if (ATTR_WIDTH < 5) begin
      $fatal(1, "pt_walker ATTR_WIDTH must be >= 5");
    end
    if (DESC_PFN_LO < 0) begin
      $fatal(1, "pt_walker descriptor PFN field does not fit DESCR_WIDTH");
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      state_q         <= ST_IDLE;
      mem_req_addr_q  <= {PA_WIDTH{1'b0}};
      mem_req_valid_q <= 1'b0;
      done_o          <= 1'b0;
      refill_valid_o  <= 1'b0;
      refill_va_o     <= {VA_WIDTH{1'b0}};
      walk_pa_base_o  <= {PA_WIDTH{1'b0}};
      walk_ppn_o      <= {PFN_WIDTH{1'b0}};
      walk_attr_o     <= {ATTR_WIDTH{1'b0}};
      fault_valid_o   <= 1'b0;
      fault_code_o    <= FAULT_NONE;
    end else begin
      done_o          <= 1'b0;
      refill_valid_o  <= 1'b0;
      fault_valid_o   <= 1'b0;
      fault_code_o    <= FAULT_NONE;
      mem_req_valid_q <= 1'b0;

      case (state_q)
        ST_IDLE: begin
          if (start_i) begin
            refill_va_o <= va_i;

            if (start_vpn >= table_entries_i) begin
              done_o         <= 1'b1;
              fault_valid_o  <= 1'b1;
              fault_code_o   <= FAULT_UNMAPPED;
            end else begin
              mem_req_addr_q  <= table_base_i + ({ {(PA_WIDTH-VPN_WIDTH){1'b0}}, start_vpn } << DESCR_BYTE_SHIFT);
              mem_req_valid_q <= 1'b1;
              state_q         <= ST_WAIT;
            end
          end
        end

        ST_WAIT: begin
          if (mem_resp_valid_i) begin
            state_q <= ST_IDLE;
            done_o  <= 1'b1;

            if (mem_resp_err_i) begin
              fault_valid_o <= 1'b1;
              fault_code_o  <= FAULT_BUS;
            end else if (!resp_v) begin
              fault_valid_o <= 1'b1;
              fault_code_o  <= FAULT_INVALID;
            end else if (resp_dt != DESC_DT_PAGE) begin
              fault_valid_o <= 1'b1;
              fault_code_o  <= FAULT_UNMAPPED;
            end else begin
              walk_ppn_o     <= resp_pfn;
              walk_pa_base_o <= {resp_pfn, {PAGE_SHIFT{1'b0}}};
              walk_attr_o    <= resp_attr;
              refill_valid_o <= 1'b1;
            end
          end
        end

        default: begin
          state_q <= ST_IDLE;
        end
      endcase
    end
  end

endmodule
`default_nettype wire
