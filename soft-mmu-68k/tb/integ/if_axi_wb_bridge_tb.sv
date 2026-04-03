`timescale 1ns/1ps
`default_nettype none

module if_axi_wb_bridge_tb;

  localparam int VA_WIDTH     = 18;
  localparam int PA_WIDTH     = 22;
  localparam int FC_WIDTH     = 3;
  localparam int RESP_FAULT_W = 3;

  localparam logic [RESP_FAULT_W-1:0] RESP_FAULT_NONE    = 3'd0;
  localparam logic [RESP_FAULT_W-1:0] RESP_FAULT_INVALID = 3'd2;

  logic                    clk;
  logic                    rst_n;

  logic                    up_req_valid;
  logic                    up_req_ready;
  logic [VA_WIDTH-1:0]     up_addr;
  logic [FC_WIDTH-1:0]     up_fc;
  logic                    up_rw;
  logic                    up_fetch;
  logic                    up_resp_valid;
  logic [PA_WIDTH-1:0]     up_resp_pa;
  logic                    up_resp_fault;
  logic [RESP_FAULT_W-1:0] up_resp_fault_code;

  logic                    core_req_valid;
  logic                    core_req_ready;
  logic [VA_WIDTH-1:0]     core_req_va;
  logic [FC_WIDTH-1:0]     core_req_fc;
  logic                    core_req_rw;
  logic                    core_req_fetch;
  logic                    core_resp_valid;
  logic [PA_WIDTH-1:0]     core_resp_pa;
  logic                    core_resp_fault;
  logic [RESP_FAULT_W-1:0] core_resp_fault_code;

  if_axi_wb_bridge #(
    .VA_WIDTH       (VA_WIDTH),
    .PA_WIDTH       (PA_WIDTH),
    .FC_WIDTH       (FC_WIDTH),
    .RESP_FAULT_W   (RESP_FAULT_W),
    .RESP_FAULT_NONE(RESP_FAULT_NONE)
  ) dut (
    .clk                   (clk),
    .rst_n                 (rst_n),
    .up_req_valid_i        (up_req_valid),
    .up_req_ready_o        (up_req_ready),
    .up_addr_i             (up_addr),
    .up_fc_i               (up_fc),
    .up_rw_i               (up_rw),
    .up_fetch_i            (up_fetch),
    .up_resp_valid_o       (up_resp_valid),
    .up_resp_pa_o          (up_resp_pa),
    .up_resp_fault_o       (up_resp_fault),
    .up_resp_fault_code_o  (up_resp_fault_code),
    .core_req_valid_o      (core_req_valid),
    .core_req_ready_i      (core_req_ready),
    .core_req_va_o         (core_req_va),
    .core_req_fc_o         (core_req_fc),
    .core_req_rw_o         (core_req_rw),
    .core_req_fetch_o      (core_req_fetch),
    .core_resp_valid_i     (core_resp_valid),
    .core_resp_pa_i        (core_resp_pa),
    .core_resp_fault_i     (core_resp_fault),
    .core_resp_fault_code_i(core_resp_fault_code)
  );

  initial clk = 1'b0;
  /* verilator lint_off STMTDLY */
  always #5 clk = ~clk;
  /* verilator lint_on STMTDLY */

  task automatic clear_inputs;
    begin
      up_req_valid         = 1'b0;
      up_addr              = '0;
      up_fc                = '0;
      up_rw                = 1'b1;
      up_fetch             = 1'b0;
      core_req_ready       = 1'b0;
      core_resp_valid      = 1'b0;
      core_resp_pa         = '0;
      core_resp_fault      = 1'b0;
      core_resp_fault_code = RESP_FAULT_NONE;
    end
  endtask

  task automatic apply_reset;
    begin
      clear_inputs();
      rst_n = 1'b0;
      /* verilator lint_off STMTDLY */
      #20;
      /* verilator lint_on STMTDLY */
      rst_n = 1'b1;
      /* verilator lint_off STMTDLY */
      #10;
      /* verilator lint_on STMTDLY */
    end
  endtask

  task automatic issue_upstream_req(
    input logic [VA_WIDTH-1:0] addr_i,
    input logic [FC_WIDTH-1:0] fc_i,
    input logic                rw_i,
    input logic                fetch_i
  );
    begin
      assert(up_req_ready === 1'b1) else $fatal(1, "upstream request side not ready");
      up_req_valid = 1'b1;
      up_addr      = addr_i;
      up_fc        = fc_i;
      up_rw        = rw_i;
      up_fetch     = fetch_i;
      /* verilator lint_off STMTDLY */
      #10;
      /* verilator lint_on STMTDLY */
      up_req_valid = 1'b0;
      up_addr      = '0;
      up_fc        = '0;
      up_rw        = 1'b1;
      up_fetch     = 1'b0;
    end
  endtask

  task automatic expect_core_req(
    input logic [VA_WIDTH-1:0] addr_i,
    input logic [FC_WIDTH-1:0] fc_i,
    input logic                rw_i,
    input logic                fetch_i
  );
    integer cycles;
    begin
      cycles = 0;
      while (core_req_valid !== 1'b1) begin
        /* verilator lint_off STMTDLY */
        #10;
        /* verilator lint_on STMTDLY */
        cycles = cycles + 1;
        if (cycles > 4) begin
          $fatal(1, "timed out waiting for core request");
        end
      end

      assert(core_req_va === addr_i)
        else $fatal(1, "core request VA mismatch exp=%h got=%h", addr_i, core_req_va);
      assert(core_req_fc === fc_i)
        else $fatal(1, "core request FC mismatch exp=%b got=%b", fc_i, core_req_fc);
      assert(core_req_rw === rw_i)
        else $fatal(1, "core request RW mismatch exp=%b got=%b", rw_i, core_req_rw);
      assert(core_req_fetch === fetch_i)
        else $fatal(1, "core request fetch mismatch exp=%b got=%b", fetch_i, core_req_fetch);
    end
  endtask

  task automatic drive_core_response(
    input logic [PA_WIDTH-1:0]      pa_i,
    input logic                     fault_i,
    input logic [RESP_FAULT_W-1:0]  fault_code_i
  );
    begin
      core_resp_valid      = 1'b1;
      core_resp_pa         = pa_i;
      core_resp_fault      = fault_i;
      core_resp_fault_code = fault_code_i;
      /* verilator lint_off STMTDLY */
      #10;
      /* verilator lint_on STMTDLY */
      core_resp_valid      = 1'b0;
      core_resp_pa         = '0;
      core_resp_fault      = 1'b0;
      core_resp_fault_code = RESP_FAULT_NONE;
    end
  endtask

  task automatic expect_completion(
    input logic [PA_WIDTH-1:0]      pa_i,
    input logic                     fault_i,
    input logic [RESP_FAULT_W-1:0]  fault_code_i
  );
    integer cycles;
    begin
      cycles = 0;
      while (up_resp_valid !== 1'b1) begin
        /* verilator lint_off STMTDLY */
        #10;
        /* verilator lint_on STMTDLY */
        cycles = cycles + 1;
        if (cycles > 4) begin
          $fatal(1, "timed out waiting for completion");
        end
      end

      assert(up_resp_pa === pa_i)
        else $fatal(1, "completion PA mismatch exp=%h got=%h", pa_i, up_resp_pa);
      assert(up_resp_fault === fault_i)
        else $fatal(1, "completion fault mismatch exp=%b got=%b", fault_i, up_resp_fault);
      assert(up_resp_fault_code === fault_code_i)
        else $fatal(1, "completion fault code mismatch exp=%0d got=%0d", fault_code_i, up_resp_fault_code);

      /* verilator lint_off STMTDLY */
      #10;
      /* verilator lint_on STMTDLY */
      assert(up_resp_valid === 1'b0) else $fatal(1, "response valid must be a pulse");
    end
  endtask

  initial begin
    apply_reset();

    assert(up_req_ready === 1'b1) else $fatal(1, "request side must come up ready");
    assert(core_req_valid === 1'b0) else $fatal(1, "core request must reset low");
    assert(up_resp_valid === 1'b0) else $fatal(1, "response valid must reset low");

    // Read-style request forwards onto the abstract core request side.
    core_req_ready = 1'b1;
    issue_upstream_req(18'h12_345, 3'b001, 1'b1, 1'b0);
    expect_core_req(18'h12_345, 3'b001, 1'b1, 1'b0);
    assert(up_req_ready === 1'b0) else $fatal(1, "request side must backpressure while a transaction is active");
    drive_core_response(22'h2A_BCD, 1'b0, RESP_FAULT_NONE);
    expect_completion(22'h2A_BCD, 1'b0, RESP_FAULT_NONE);
    assert(up_req_ready === 1'b1) else $fatal(1, "request side must reopen after read completion");

    // Write-style request uses the same forwarding path.
    core_req_ready = 1'b1;
    issue_upstream_req(18'h2A_468, 3'b010, 1'b0, 1'b0);
    expect_core_req(18'h2A_468, 3'b010, 1'b0, 1'b0);
    drive_core_response(22'h31_0F0, 1'b0, RESP_FAULT_NONE);
    expect_completion(22'h31_0F0, 1'b0, RESP_FAULT_NONE);

    // Fetch classification must be preserved for future front-end wrappers.
    core_req_ready = 1'b1;
    issue_upstream_req(18'h03_210, 3'b101, 1'b1, 1'b1);
    expect_core_req(18'h03_210, 3'b101, 1'b1, 1'b1);
    drive_core_response(22'h11_234, 1'b0, RESP_FAULT_NONE);
    expect_completion(22'h11_234, 1'b0, RESP_FAULT_NONE);

    // Fault completion forwards the abstract core fault response unchanged.
    core_req_ready = 1'b1;
    issue_upstream_req(18'h3F_000, 3'b111, 1'b1, 1'b0);
    expect_core_req(18'h3F_000, 3'b111, 1'b1, 1'b0);
    drive_core_response(22'h0, 1'b1, RESP_FAULT_INVALID);
    expect_completion(22'h0, 1'b1, RESP_FAULT_INVALID);

    // Downstream backpressure must hold the one buffered request stable.
    core_req_ready = 1'b0;
    issue_upstream_req(18'h15_5AA, 3'b100, 1'b0, 1'b1);
    expect_core_req(18'h15_5AA, 3'b100, 1'b0, 1'b1);
    repeat (3) begin
      /* verilator lint_off STMTDLY */
      #10;
      /* verilator lint_on STMTDLY */
      assert(core_req_valid === 1'b1) else $fatal(1, "core request must hold under backpressure");
      assert(core_req_va === 18'h15_5AA) else $fatal(1, "held VA changed under backpressure");
      assert(core_req_fc === 3'b100) else $fatal(1, "held FC changed under backpressure");
      assert(core_req_rw === 1'b0) else $fatal(1, "held RW changed under backpressure");
      assert(core_req_fetch === 1'b1) else $fatal(1, "held fetch changed under backpressure");
      assert(up_req_ready === 1'b0) else $fatal(1, "upstream side must remain stalled while buffered");
    end

    core_req_ready = 1'b1;
    /* verilator lint_off STMTDLY */
    #20;
    /* verilator lint_on STMTDLY */
    assert(core_req_valid === 1'b0) else $fatal(1, "core request must clear after ready handshake");
    drive_core_response(22'h2D_EE0, 1'b0, RESP_FAULT_NONE);
    expect_completion(22'h2D_EE0, 1'b0, RESP_FAULT_NONE);
    assert(up_req_ready === 1'b1) else $fatal(1, "request side must reopen after stalled transaction completes");

    $display("[if_axi_wb_bridge_tb] PASS");
    $finish;
  end

endmodule
`default_nettype wire
