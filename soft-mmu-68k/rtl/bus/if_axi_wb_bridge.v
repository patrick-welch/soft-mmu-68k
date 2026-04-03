`timescale 1ns/1ps
`default_nettype none
// -----------------------------------------------------------------------------
// Soft MMU 68k : if_axi_wb_bridge
// Minimal first-pass abstract bridge for future AXI/Wishbone wrapper work.
//
// Packet scope:
//   - Accept a simplified upstream request channel.
//   - Forward onto the existing abstract MMU/core request-response interface.
//   - Preserve one buffered request under downstream backpressure.
//   - Deliberately does not model AXI-lite or Wishbone bus timing yet.
// -----------------------------------------------------------------------------

module if_axi_wb_bridge #(
  parameter integer VA_WIDTH      = 24,
  parameter integer PA_WIDTH      = 24,
  parameter integer FC_WIDTH      = 3,
  parameter integer RESP_FAULT_W  = 3,
  parameter [RESP_FAULT_W-1:0] RESP_FAULT_NONE = {RESP_FAULT_W{1'b0}}
) (
  input  wire                    clk,
  input  wire                    rst_n,

  input  wire                    up_req_valid_i,
  output wire                    up_req_ready_o,
  input  wire [VA_WIDTH-1:0]     up_addr_i,
  input  wire [FC_WIDTH-1:0]     up_fc_i,
  input  wire                    up_rw_i,
  input  wire                    up_fetch_i,

  output reg                     up_resp_valid_o,
  output reg  [PA_WIDTH-1:0]     up_resp_pa_o,
  output reg                     up_resp_fault_o,
  output reg  [RESP_FAULT_W-1:0] up_resp_fault_code_o,

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
  reg                req_buf_fetch_q;

  assign up_req_ready_o = !req_buf_valid_q && !req_inflight_q;

  assign core_req_valid_o = req_buf_valid_q;
  assign core_req_va_o    = req_buf_va_q;
  assign core_req_fc_o    = req_buf_fc_q;
  assign core_req_rw_o    = req_buf_rw_q;
  assign core_req_fetch_o = req_buf_fetch_q;

  always @(posedge clk) begin
    if (!rst_n) begin
      req_buf_valid_q        <= 1'b0;
      req_inflight_q         <= 1'b0;
      req_buf_va_q           <= {VA_WIDTH{1'b0}};
      req_buf_fc_q           <= {FC_WIDTH{1'b0}};
      req_buf_rw_q           <= 1'b1;
      req_buf_fetch_q        <= 1'b0;
      up_resp_valid_o        <= 1'b0;
      up_resp_pa_o           <= {PA_WIDTH{1'b0}};
      up_resp_fault_o        <= 1'b0;
      up_resp_fault_code_o   <= RESP_FAULT_NONE;
    end else begin
      up_resp_valid_o      <= 1'b0;
      up_resp_fault_o      <= 1'b0;
      up_resp_fault_code_o <= RESP_FAULT_NONE;

      if (req_buf_valid_q && core_req_ready_i) begin
        req_buf_valid_q <= 1'b0;
        req_inflight_q  <= 1'b1;
      end

      if (req_inflight_q && core_resp_valid_i) begin
        req_inflight_q        <= 1'b0;
        up_resp_valid_o       <= 1'b1;
        up_resp_pa_o          <= core_resp_pa_i;
        up_resp_fault_o       <= core_resp_fault_i;
        up_resp_fault_code_o  <= core_resp_fault_code_i;
      end

      if (!req_buf_valid_q && !req_inflight_q && up_req_valid_i) begin
        req_buf_valid_q <= 1'b1;
        req_buf_va_q    <= up_addr_i;
        req_buf_fc_q    <= up_fc_i;
        req_buf_rw_q    <= up_rw_i;
        req_buf_fetch_q <= up_fetch_i;
      end
    end
  end

endmodule
`default_nettype wire
