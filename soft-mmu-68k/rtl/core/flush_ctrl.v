`timescale 1ns/1ps
`default_nettype none
// -----------------------------------------------------------------------------
// Soft MMU 68k : flush_ctrl
// Minimal instruction-control shim for TLB flush, probe, and preload requests.
//
// Compliance:
//   - MC68851 PMMU User's Manual, Section 5.2 "Address Translation Cache"
//   - M68000 Family Programmer's Reference Manual, instruction entries
//     "PFLUSH", "PFLUSHA", "PLOAD", and "PTEST"
//
// Packet scope:
//   - First-pass control only; not a full instruction model.
//   - One in-flight probe or preload request at a time.
//   - Whole-TLB flush emits a one-cycle pulse.
//   - Address+FC targeted flush emits a one-cycle pulse with explicit operands.
//   - Probe returns a small latched status/result record.
//   - Preload only drives a request/ready handshake; no walk completion model yet.
// -----------------------------------------------------------------------------

module flush_ctrl #(
  parameter integer VA_WIDTH    = 24,
  parameter integer PA_WIDTH    = 24,
  parameter integer FC_WIDTH    = 3,
  parameter integer STATUS_WIDTH = 8,
  parameter integer CMD_WIDTH   = 3,

  parameter [CMD_WIDTH-1:0] CMD_NOP          = 3'd0,
  parameter [CMD_WIDTH-1:0] CMD_FLUSH_ALL    = 3'd1,
  parameter [CMD_WIDTH-1:0] CMD_FLUSH_MATCH  = 3'd2,
  parameter [CMD_WIDTH-1:0] CMD_PROBE        = 3'd3,
  parameter [CMD_WIDTH-1:0] CMD_PRELOAD      = 3'd4
) (
  input  wire                    clk,
  input  wire                    rst_n,

  input  wire                    cmd_valid_i,
  input  wire [CMD_WIDTH-1:0]    cmd_op_i,
  input  wire [VA_WIDTH-1:0]     cmd_addr_i,
  input  wire [FC_WIDTH-1:0]     cmd_fc_i,
  output wire                    cmd_ready_o,
  output wire                    busy_o,

  output reg                     flush_all_o,
  output reg                     flush_match_o,
  output reg  [VA_WIDTH-1:0]     flush_addr_o,
  output reg  [FC_WIDTH-1:0]     flush_fc_o,

  output reg                     probe_req_valid_o,
  output reg  [VA_WIDTH-1:0]     probe_addr_o,
  output reg  [FC_WIDTH-1:0]     probe_fc_o,
  input  wire                    probe_resp_valid_i,
  input  wire                    probe_resp_hit_i,
  input  wire [PA_WIDTH-1:0]     probe_resp_pa_i,
  input  wire [STATUS_WIDTH-1:0] probe_resp_status_i,

  output reg                     preload_req_valid_o,
  output reg  [VA_WIDTH-1:0]     preload_addr_o,
  output reg  [FC_WIDTH-1:0]     preload_fc_o,
  input  wire                    preload_req_ready_i,

  output reg                     status_valid_o,
  output reg  [CMD_WIDTH-1:0]    status_cmd_o,
  output reg                     status_hit_o,
  output reg  [PA_WIDTH-1:0]     status_pa_o,
  output reg  [STATUS_WIDTH-1:0] status_bits_o
);

  localparam [1:0] ST_IDLE         = 2'd0;
  localparam [1:0] ST_WAIT_PROBE   = 2'd1;
  localparam [1:0] ST_WAIT_PRELOAD = 2'd2;

  reg [1:0] state_q;

  assign cmd_ready_o = (state_q == ST_IDLE);
  assign busy_o      = (state_q != ST_IDLE);

  initial begin
    if (VA_WIDTH < 1) begin
      $fatal(1, "flush_ctrl VA_WIDTH must be >= 1");
    end
    if (PA_WIDTH < 1) begin
      $fatal(1, "flush_ctrl PA_WIDTH must be >= 1");
    end
    if (FC_WIDTH < 1) begin
      $fatal(1, "flush_ctrl FC_WIDTH must be >= 1");
    end
    if (STATUS_WIDTH < 1) begin
      $fatal(1, "flush_ctrl STATUS_WIDTH must be >= 1");
    end
    if (CMD_WIDTH < 3) begin
      $fatal(1, "flush_ctrl CMD_WIDTH must be >= 3");
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      state_q              <= ST_IDLE;
      flush_all_o          <= 1'b0;
      flush_match_o        <= 1'b0;
      flush_addr_o         <= {VA_WIDTH{1'b0}};
      flush_fc_o           <= {FC_WIDTH{1'b0}};
      probe_req_valid_o    <= 1'b0;
      probe_addr_o         <= {VA_WIDTH{1'b0}};
      probe_fc_o           <= {FC_WIDTH{1'b0}};
      preload_req_valid_o  <= 1'b0;
      preload_addr_o       <= {VA_WIDTH{1'b0}};
      preload_fc_o         <= {FC_WIDTH{1'b0}};
      status_valid_o       <= 1'b0;
      status_cmd_o         <= CMD_NOP;
      status_hit_o         <= 1'b0;
      status_pa_o          <= {PA_WIDTH{1'b0}};
      status_bits_o        <= {STATUS_WIDTH{1'b0}};
    end else begin
      flush_all_o       <= 1'b0;
      flush_match_o     <= 1'b0;
      probe_req_valid_o <= 1'b0;
      status_valid_o    <= 1'b0;

      case (state_q)
        ST_IDLE: begin
          if (cmd_valid_i) begin
            case (cmd_op_i)
              CMD_FLUSH_ALL: begin
                flush_all_o   <= 1'b1;
                status_valid_o <= 1'b1;
                status_cmd_o  <= CMD_FLUSH_ALL;
                status_hit_o  <= 1'b0;
                status_pa_o   <= {PA_WIDTH{1'b0}};
                status_bits_o <= {STATUS_WIDTH{1'b0}};
              end

              CMD_FLUSH_MATCH: begin
                flush_match_o  <= 1'b1;
                flush_addr_o   <= cmd_addr_i;
                flush_fc_o     <= cmd_fc_i;
                status_valid_o <= 1'b1;
                status_cmd_o   <= CMD_FLUSH_MATCH;
                status_hit_o   <= 1'b0;
                status_pa_o    <= {PA_WIDTH{1'b0}};
                status_bits_o  <= {STATUS_WIDTH{1'b0}};
              end

              CMD_PROBE: begin
                probe_req_valid_o <= 1'b1;
                probe_addr_o      <= cmd_addr_i;
                probe_fc_o        <= cmd_fc_i;
                state_q           <= ST_WAIT_PROBE;
              end

              CMD_PRELOAD: begin
                preload_req_valid_o <= 1'b1;
                preload_addr_o      <= cmd_addr_i;
                preload_fc_o        <= cmd_fc_i;
                state_q             <= ST_WAIT_PRELOAD;
              end

              default: begin
                status_valid_o <= 1'b1;
                status_cmd_o   <= CMD_NOP;
                status_hit_o   <= 1'b0;
                status_pa_o    <= {PA_WIDTH{1'b0}};
                status_bits_o  <= {STATUS_WIDTH{1'b0}};
              end
            endcase
          end
        end

        ST_WAIT_PROBE: begin
          if (probe_resp_valid_i) begin
            state_q         <= ST_IDLE;
            status_valid_o  <= 1'b1;
            status_cmd_o    <= CMD_PROBE;
            status_hit_o    <= probe_resp_hit_i;
            status_pa_o     <= probe_resp_pa_i;
            status_bits_o   <= probe_resp_status_i;
          end
        end

        ST_WAIT_PRELOAD: begin
          if (preload_req_ready_i) begin
            preload_req_valid_o <= 1'b0;
            state_q             <= ST_IDLE;
            status_valid_o      <= 1'b1;
            status_cmd_o        <= CMD_PRELOAD;
            status_hit_o        <= 1'b0;
            status_pa_o         <= {PA_WIDTH{1'b0}};
            status_bits_o       <= {STATUS_WIDTH{1'b0}};
          end
        end

        default: begin
          state_q             <= ST_IDLE;
          preload_req_valid_o <= 1'b0;
        end
      endcase
    end
  end

endmodule
`default_nettype wire
