`timescale 1ns/1ps
`default_nettype none

module instr_shim_tb;

  localparam int VA_WIDTH     = 16;
  localparam int PA_WIDTH     = 20;
  localparam int FC_WIDTH     = 3;
  localparam int STATUS_WIDTH = 8;
  localparam int CMD_WIDTH    = 3;

  localparam logic [CMD_WIDTH-1:0] CMD_NOP         = 3'd0;
  localparam logic [CMD_WIDTH-1:0] CMD_FLUSH_ALL   = 3'd1;
  localparam logic [CMD_WIDTH-1:0] CMD_FLUSH_MATCH = 3'd2;
  localparam logic [CMD_WIDTH-1:0] CMD_PROBE       = 3'd3;
  localparam logic [CMD_WIDTH-1:0] CMD_PRELOAD     = 3'd4;
  localparam int STATUS_BIT_TT_MATCH   = STATUS_WIDTH - 1;
  localparam int STATUS_BIT_TRANSLATED = STATUS_WIDTH - 2;

  logic                    clk;
  logic                    rst_n;

  logic                    cmd_valid;
  logic [CMD_WIDTH-1:0]    cmd_op;
  logic [VA_WIDTH-1:0]     cmd_addr;
  logic [FC_WIDTH-1:0]     cmd_fc;
  logic                    cmd_ready;
  logic                    busy;

  logic                    flush_all;
  logic                    flush_match;
  logic [VA_WIDTH-1:0]     flush_addr;
  logic [FC_WIDTH-1:0]     flush_fc;

  logic                    probe_req_valid;
  logic [VA_WIDTH-1:0]     probe_addr;
  logic [FC_WIDTH-1:0]     probe_fc;
  logic                    probe_resp_valid;
  logic                    probe_resp_hit;
  logic [PA_WIDTH-1:0]     probe_resp_pa;
  logic [STATUS_WIDTH-1:0] probe_resp_status;

  logic                    preload_req_valid;
  logic [VA_WIDTH-1:0]     preload_addr;
  logic [FC_WIDTH-1:0]     preload_fc;
  logic                    preload_req_ready;

  logic                    status_valid;
  logic [CMD_WIDTH-1:0]    status_cmd;
  logic                    status_hit;
  logic [PA_WIDTH-1:0]     status_pa;
  logic [STATUS_WIDTH-1:0] status_bits;

  flush_ctrl #(
    .VA_WIDTH    (VA_WIDTH),
    .PA_WIDTH    (PA_WIDTH),
    .FC_WIDTH    (FC_WIDTH),
    .STATUS_WIDTH(STATUS_WIDTH),
    .CMD_WIDTH   (CMD_WIDTH),
    .CMD_NOP     (CMD_NOP),
    .CMD_FLUSH_ALL(CMD_FLUSH_ALL),
    .CMD_FLUSH_MATCH(CMD_FLUSH_MATCH),
    .CMD_PROBE   (CMD_PROBE),
    .CMD_PRELOAD (CMD_PRELOAD)
  ) dut (
    .clk                (clk),
    .rst_n              (rst_n),
    .cmd_valid_i        (cmd_valid),
    .cmd_op_i           (cmd_op),
    .cmd_addr_i         (cmd_addr),
    .cmd_fc_i           (cmd_fc),
    .cmd_ready_o        (cmd_ready),
    .busy_o             (busy),
    .flush_all_o        (flush_all),
    .flush_match_o      (flush_match),
    .flush_addr_o       (flush_addr),
    .flush_fc_o         (flush_fc),
    .probe_req_valid_o  (probe_req_valid),
    .probe_addr_o       (probe_addr),
    .probe_fc_o         (probe_fc),
    .probe_resp_valid_i (probe_resp_valid),
    .probe_resp_hit_i   (probe_resp_hit),
    .probe_resp_pa_i    (probe_resp_pa),
    .probe_resp_status_i(probe_resp_status),
    .preload_req_valid_o(preload_req_valid),
    .preload_addr_o     (preload_addr),
    .preload_fc_o       (preload_fc),
    .preload_req_ready_i(preload_req_ready),
    .status_valid_o     (status_valid),
    .status_cmd_o       (status_cmd),
    .status_hit_o       (status_hit),
    .status_pa_o        (status_pa),
    .status_bits_o      (status_bits)
  );

  initial clk = 1'b0;
  /* verilator lint_off STMTDLY */
  always #5 clk = ~clk;
  /* verilator lint_on STMTDLY */

  task automatic clear_inputs;
    begin
      cmd_valid         = 1'b0;
      cmd_op            = CMD_NOP;
      cmd_addr          = {VA_WIDTH{1'b0}};
      cmd_fc            = {FC_WIDTH{1'b0}};
      probe_resp_valid  = 1'b0;
      probe_resp_hit    = 1'b0;
      probe_resp_pa     = {PA_WIDTH{1'b0}};
      probe_resp_status = {STATUS_WIDTH{1'b0}};
      preload_req_ready = 1'b0;
    end
  endtask

  task automatic launch_cmd(
    input logic [CMD_WIDTH-1:0] op_i,
    input logic [VA_WIDTH-1:0]  addr_i,
    input logic [FC_WIDTH-1:0]  fc_i
  );
    begin
      cmd_valid = 1'b1;
      cmd_op    = op_i;
      cmd_addr  = addr_i;
      cmd_fc    = fc_i;
      /* verilator lint_off STMTDLY */
      #10;
      /* verilator lint_on STMTDLY */
      cmd_valid = 1'b0;
      cmd_op    = CMD_NOP;
      cmd_addr  = {VA_WIDTH{1'b0}};
      cmd_fc    = {FC_WIDTH{1'b0}};
    end
  endtask

  task automatic expect_status(
    input logic [CMD_WIDTH-1:0]    exp_cmd,
    input logic                    exp_hit,
    input logic [PA_WIDTH-1:0]     exp_pa,
    input logic [STATUS_WIDTH-1:0] exp_bits,
    input string                   label_i
  );
    begin
      assert(status_valid === 1'b1) else $fatal(1, "%s: status_valid missing", label_i);
      assert(status_cmd === exp_cmd) else $fatal(1, "%s: status_cmd mismatch", label_i);
      assert(status_hit === exp_hit) else $fatal(1, "%s: status_hit mismatch", label_i);
      assert(status_pa === exp_pa) else $fatal(1, "%s: status_pa mismatch", label_i);
      assert(status_bits === exp_bits) else $fatal(1, "%s: status_bits mismatch", label_i);
    end
  endtask

  task automatic expect_idle_outputs;
    begin
      assert(cmd_ready === 1'b1) else $fatal(1, "cmd_ready must be high when idle");
      assert(busy === 1'b0) else $fatal(1, "busy must be low when idle");
      assert(flush_all === 1'b0) else $fatal(1, "flush_all must reset low");
      assert(flush_match === 1'b0) else $fatal(1, "flush_match must reset low");
      assert(probe_req_valid === 1'b0) else $fatal(1, "probe_req_valid must reset low");
      assert(preload_req_valid === 1'b0) else $fatal(1, "preload_req_valid must reset low");
      assert(status_valid === 1'b0) else $fatal(1, "status_valid must reset low");
    end
  endtask

  initial begin
    clear_inputs();
    rst_n = 1'b1;

    /* verilator lint_off STMTDLY */
    #10;
    rst_n = 1'b0;
    #10;
    rst_n = 1'b1;
    #1;
    /* verilator lint_on STMTDLY */
    expect_idle_outputs();

    // Whole-TLB flush command emits a one-cycle pulse and immediate status.
    launch_cmd(CMD_FLUSH_ALL, 16'h0000, 3'b000);
    assert(flush_all === 1'b1) else $fatal(1, "whole flush pulse missing");
    assert(flush_match === 1'b0) else $fatal(1, "targeted flush pulse must stay low");
    expect_status(CMD_FLUSH_ALL, 1'b0, {PA_WIDTH{1'b0}}, {STATUS_WIDTH{1'b0}}, "whole flush");
    assert(cmd_ready === 1'b1) else $fatal(1, "whole flush must not stall command port");
    /* verilator lint_off STMTDLY */
    #10;
    /* verilator lint_on STMTDLY */
    assert(flush_all === 1'b0) else $fatal(1, "whole flush pulse must clear");

    // Address+FC targeted flush captures operands and emits its own pulse.
    launch_cmd(CMD_FLUSH_MATCH, 16'h12A4, 3'b101);
    assert(flush_match === 1'b1) else $fatal(1, "targeted flush pulse missing");
    assert(flush_all === 1'b0) else $fatal(1, "whole flush must stay low on targeted flush");
    assert(flush_addr === 16'h12A4) else $fatal(1, "targeted flush address mismatch");
    assert(flush_fc === 3'b101) else $fatal(1, "targeted flush FC mismatch");
    expect_status(CMD_FLUSH_MATCH, 1'b0, {PA_WIDTH{1'b0}}, {STATUS_WIDTH{1'b0}}, "targeted flush");
    /* verilator lint_off STMTDLY */
    #10;
    /* verilator lint_on STMTDLY */
    assert(flush_match === 1'b0) else $fatal(1, "targeted flush pulse must clear");

    // Probe command emits a request pulse, stalls until response, then reports
    // either a translated hit, a transparent-bypass match, or a miss.
    launch_cmd(CMD_PROBE, 16'hBEEF, 3'b010);
    assert(probe_req_valid === 1'b1) else $fatal(1, "probe request pulse missing");
    assert(probe_addr === 16'hBEEF) else $fatal(1, "probe address mismatch");
    assert(probe_fc === 3'b010) else $fatal(1, "probe FC mismatch");
    assert(busy === 1'b1) else $fatal(1, "probe must set busy while awaiting response");
    assert(cmd_ready === 1'b0) else $fatal(1, "probe must deassert cmd_ready while busy");
    assert(status_valid === 1'b0) else $fatal(1, "probe status must wait for response");
    /* verilator lint_off STMTDLY */
    #10;
    /* verilator lint_on STMTDLY */
    assert(probe_req_valid === 1'b0) else $fatal(1, "probe request pulse must clear");
    probe_resp_hit    = 1'b1;
    probe_resp_pa     = 20'hA5_234;
    probe_resp_status = 8'h16;
    probe_resp_valid  = 1'b1;
    /* verilator lint_off STMTDLY */
    #10;
    /* verilator lint_on STMTDLY */
    probe_resp_valid  = 1'b0;
    probe_resp_hit    = 1'b0;
    probe_resp_pa     = {PA_WIDTH{1'b0}};
    probe_resp_status = {STATUS_WIDTH{1'b0}};
    expect_status(CMD_PROBE, 1'b1, 20'hA5_234, 8'h56, "probe translated hit");
    assert(busy === 1'b0) else $fatal(1, "probe busy must clear after response");
    assert(cmd_ready === 1'b1) else $fatal(1, "probe cmd_ready must restore after response");
    assert(status_bits[STATUS_BIT_TRANSLATED] === 1'b1) else $fatal(1, "translated probe must set translated class bit");
    assert(status_bits[STATUS_BIT_TT_MATCH] === 1'b0) else $fatal(1, "translated probe must not set TT match class bit");

    launch_cmd(CMD_PROBE, 16'h2468, 3'b001);
    assert(probe_req_valid === 1'b1) else $fatal(1, "TT-style probe request pulse missing");
    /* verilator lint_off STMTDLY */
    #10;
    /* verilator lint_on STMTDLY */
    probe_resp_hit    = 1'b0;
    probe_resp_pa     = {PA_WIDTH{1'b0}};
    probe_resp_status = 8'h80;
    probe_resp_valid  = 1'b1;
    /* verilator lint_off STMTDLY */
    #10;
    /* verilator lint_on STMTDLY */
    probe_resp_valid  = 1'b0;
    probe_resp_status = {STATUS_WIDTH{1'b0}};
    expect_status(CMD_PROBE, 1'b1, 20'h02468, 8'h80, "probe transparent bypass");
    assert(status_bits[STATUS_BIT_TT_MATCH] === 1'b1) else $fatal(1, "transparent probe must set TT match class bit");
    assert(status_bits[STATUS_BIT_TRANSLATED] === 1'b0) else $fatal(1, "transparent probe must not set translated class bit");

    launch_cmd(CMD_PROBE, 16'h1357, 3'b101);
    assert(probe_req_valid === 1'b1) else $fatal(1, "probe miss request pulse missing");
    /* verilator lint_off STMTDLY */
    #10;
    /* verilator lint_on STMTDLY */
    probe_resp_hit    = 1'b0;
    probe_resp_pa     = {PA_WIDTH{1'b0}};
    probe_resp_status = 8'h00;
    probe_resp_valid  = 1'b1;
    /* verilator lint_off STMTDLY */
    #10;
    /* verilator lint_on STMTDLY */
    probe_resp_valid  = 1'b0;
    expect_status(CMD_PROBE, 1'b0, {PA_WIDTH{1'b0}}, 8'h00, "probe miss");
    assert(status_bits[STATUS_BIT_TT_MATCH] === 1'b0) else $fatal(1, "probe miss must not set TT match class bit");
    assert(status_bits[STATUS_BIT_TRANSLATED] === 1'b0) else $fatal(1, "probe miss must not set translated class bit");

    // Preload command holds valid until the downstream request handshake completes.
    launch_cmd(CMD_PRELOAD, 16'hCAFE, 3'b111);
    assert(preload_req_valid === 1'b1) else $fatal(1, "preload request must assert");
    assert(preload_addr === 16'hCAFE) else $fatal(1, "preload address mismatch");
    assert(preload_fc === 3'b111) else $fatal(1, "preload FC mismatch");
    assert(busy === 1'b1) else $fatal(1, "preload must set busy while waiting for ready");
    assert(cmd_ready === 1'b0) else $fatal(1, "preload must deassert cmd_ready while busy");
    assert(status_valid === 1'b0) else $fatal(1, "preload status must wait for ready");
    /* verilator lint_off STMTDLY */
    #20;
    /* verilator lint_on STMTDLY */
    assert(preload_req_valid === 1'b1) else $fatal(1, "preload request must stay asserted until ready");
    preload_req_ready = 1'b1;
    /* verilator lint_off STMTDLY */
    #10;
    /* verilator lint_on STMTDLY */
    preload_req_ready = 1'b0;
    assert(preload_req_valid === 1'b0) else $fatal(1, "preload request must clear after ready");
    expect_status(CMD_PRELOAD, 1'b0, {PA_WIDTH{1'b0}}, {STATUS_WIDTH{1'b0}}, "preload complete");
    assert(busy === 1'b0) else $fatal(1, "preload busy must clear after ready");
    assert(cmd_ready === 1'b1) else $fatal(1, "preload cmd_ready must restore after ready");

    $display("[instr_shim_tb] PASS");
    $finish;
  end

endmodule
`default_nettype wire
