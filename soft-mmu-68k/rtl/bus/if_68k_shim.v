`timescale 1ns/1ps
`default_nettype none
// -----------------------------------------------------------------------------
// Soft MMU 68k : if_68k_shim
// Minimal first-pass 68k-facing shim that adapts a simplified request channel
// onto the abstract MMU/core request-response interface.
//
// Packet scope:
//   - Single buffered request, single outstanding core transaction.
//   - No cycle-exact 68k timing; dtack is a completion pulse only.
//   - Fetch classification is left for a later packet and is forced low here.
// -----------------------------------------------------------------------------

module if_68k_shim #(
  parameter integer VA_WIDTH      = 24,
  parameter integer PA_WIDTH      = 24,
  parameter integer FC_WIDTH      = 3,
  parameter integer RESP_FAULT_W  = 3,
  parameter [RESP_FAULT_W-1:0] RESP_FAULT_NONE = {RESP_FAULT_W{1'b0}}
) (
  input  wire                    clk,
  input  wire                    rst_n,

  input  wire                    m68k_req_valid_i,
  output wire                    m68k_req_ready_o,
  input  wire [VA_WIDTH-1:0]     m68k_addr_i,
  input  wire [FC_WIDTH-1:0]     m68k_fc_i,
  input  wire                    m68k_rw_i,

  output reg                     m68k_resp_valid_o,
  output reg  [PA_WIDTH-1:0]     m68k_resp_pa_o,
  output reg                     m68k_resp_fault_o,
  output reg  [RESP_FAULT_W-1:0] m68k_resp_fault_code_o,
  output reg                     m68k_dtack_o,

  output wire                    core_req_valid_o,
  input  wire                    core_req_ready_i,
  output wire [VA_WIDTH-1:0]     core_req_va_o,
  output wire [FC_WIDTH-1:0]     core_req_fc_o,
  output wire                    core_req_rw_o,
  output wire                    core_req_fetch_o,

  input  wire                    core_resp_valid_i,
  input  wire [PA_WIDTH-1:0]     core_resp_pa_i,
  input  wire                    core_resp_fault_i,
  input  wire [RESP_FAULT_W-1:0] core_resp_fault_code_i
);

  reg                req_buf_valid_q;
  reg                req_inflight_q;
  reg [VA_WIDTH-1:0] req_buf_va_q;
  reg [FC_WIDTH-1:0] req_buf_fc_q;
  reg                req_buf_rw_q;

  assign m68k_req_ready_o = !req_buf_valid_q && !req_inflight_q;

  assign core_req_valid_o = req_buf_valid_q;
  assign core_req_va_o    = req_buf_va_q;
  assign core_req_fc_o    = req_buf_fc_q;
  assign core_req_rw_o    = req_buf_rw_q;
  assign core_req_fetch_o = 1'b0;

  always @(posedge clk) begin
    if (!rst_n) begin
      req_buf_valid_q         <= 1'b0;
      req_inflight_q          <= 1'b0;
      req_buf_va_q            <= {VA_WIDTH{1'b0}};
      req_buf_fc_q            <= {FC_WIDTH{1'b0}};
      req_buf_rw_q            <= 1'b1;
      m68k_resp_valid_o       <= 1'b0;
      m68k_resp_pa_o          <= {PA_WIDTH{1'b0}};
      m68k_resp_fault_o       <= 1'b0;
      m68k_resp_fault_code_o  <= RESP_FAULT_NONE;
      m68k_dtack_o            <= 1'b0;
    end else begin
      m68k_resp_valid_o      <= 1'b0;
      m68k_resp_fault_o      <= 1'b0;
      m68k_resp_fault_code_o <= RESP_FAULT_NONE;
      m68k_dtack_o           <= 1'b0;

      if (req_buf_valid_q && core_req_ready_i) begin
        req_buf_valid_q <= 1'b0;
        req_inflight_q  <= 1'b1;
      end

      if (req_inflight_q && core_resp_valid_i) begin
        req_inflight_q         <= 1'b0;
        m68k_resp_valid_o      <= 1'b1;
        m68k_resp_pa_o         <= core_resp_pa_i;
        m68k_resp_fault_o      <= core_resp_fault_i;
        m68k_resp_fault_code_o <= core_resp_fault_code_i;
        m68k_dtack_o           <= 1'b1;
      end

      if (!req_buf_valid_q && !req_inflight_q && m68k_req_valid_i) begin
        req_buf_valid_q <= 1'b1;
        req_buf_va_q    <= m68k_addr_i;
        req_buf_fc_q    <= m68k_fc_i;
        req_buf_rw_q    <= m68k_rw_i;
      end
    end
  end

endmodule
`default_nettype wire
