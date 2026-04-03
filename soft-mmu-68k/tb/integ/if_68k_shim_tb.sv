`timescale 1ns/1ps
`default_nettype none

module if_68k_shim_tb;

  localparam int VA_WIDTH     = 16;
  localparam int PA_WIDTH     = 20;
  localparam int FC_WIDTH     = 3;
  localparam int RESP_FAULT_W = 3;

  localparam logic [RESP_FAULT_W-1:0] RESP_FAULT_NONE = 3'd0;
  localparam logic [RESP_FAULT_W-1:0] RESP_FAULT_BUS  = 3'd4;

  logic                    clk;
  logic                    rst_n;

  logic                    m68k_req_valid;
  logic                    m68k_req_ready;
  logic [VA_WIDTH-1:0]     m68k_addr;
  logic [FC_WIDTH-1:0]     m68k_fc;
  logic                    m68k_rw;
  logic                    m68k_resp_valid;
  logic [PA_WIDTH-1:0]     m68k_resp_pa;
  logic                    m68k_resp_fault;
  logic [RESP_FAULT_W-1:0] m68k_resp_fault_code;
  logic                    m68k_dtack;

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

  /* verilator lint_off UNUSED */
  wire unused_tb = ^core_req_fetch;
  /* verilator lint_on UNUSED */

  if_68k_shim #(
    .VA_WIDTH       (VA_WIDTH),
    .PA_WIDTH       (PA_WIDTH),
    .FC_WIDTH       (FC_WIDTH),
    .RESP_FAULT_W   (RESP_FAULT_W),
    .RESP_FAULT_NONE(RESP_FAULT_NONE)
  ) dut (
    .clk                    (clk),
    .rst_n                  (rst_n),
    .m68k_req_valid_i       (m68k_req_valid),
    .m68k_req_ready_o       (m68k_req_ready),
    .m68k_addr_i            (m68k_addr),
    .m68k_fc_i              (m68k_fc),
    .m68k_rw_i              (m68k_rw),
    .m68k_resp_valid_o      (m68k_resp_valid),
    .m68k_resp_pa_o         (m68k_resp_pa),
    .m68k_resp_fault_o      (m68k_resp_fault),
    .m68k_resp_fault_code_o (m68k_resp_fault_code),
    .m68k_dtack_o           (m68k_dtack),
    .core_req_valid_o       (core_req_valid),
    .core_req_ready_i       (core_req_ready),
    .core_req_va_o          (core_req_va),
    .core_req_fc_o          (core_req_fc),
    .core_req_rw_o          (core_req_rw),
    .core_req_fetch_o       (core_req_fetch),
    .core_resp_valid_i      (core_resp_valid),
    .core_resp_pa_i         (core_resp_pa),
    .core_resp_fault_i      (core_resp_fault),
    .core_resp_fault_code_i (core_resp_fault_code)
  );

  initial clk = 1'b0;
  /* verilator lint_off STMTDLY */
  always #5 clk = ~clk;
  /* verilator lint_on STMTDLY */

  task automatic clear_inputs;
    begin
      m68k_req_valid      = 1'b0;
      m68k_addr           = '0;
      m68k_fc             = '0;
      m68k_rw             = 1'b1;
      core_req_ready      = 1'b0;
      core_resp_valid     = 1'b0;
      core_resp_pa        = '0;
      core_resp_fault     = 1'b0;
      core_resp_fault_code= RESP_FAULT_NONE;
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

  task automatic issue_68k_req(
    input logic [VA_WIDTH-1:0] addr_i,
    input logic [FC_WIDTH-1:0] fc_i,
    input logic                rw_i
  );
    begin
      assert(m68k_req_ready === 1'b1) else $fatal(1, "68k request side not ready");
      m68k_req_valid = 1'b1;
      m68k_addr      = addr_i;
      m68k_fc        = fc_i;
      m68k_rw        = rw_i;
      /* verilator lint_off STMTDLY */
      #10;
      /* verilator lint_on STMTDLY */
      m68k_req_valid = 1'b0;
      m68k_addr      = '0;
      m68k_fc        = '0;
      m68k_rw        = 1'b1;
    end
  endtask

  task automatic expect_core_req(
    input logic [VA_WIDTH-1:0] addr_i,
    input logic [FC_WIDTH-1:0] fc_i,
    input logic                rw_i
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
      assert(core_req_fetch === 1'b0)
        else $fatal(1, "minimal shim must force fetch low");
    end
  endtask

  task automatic drive_core_response(
    input logic [PA_WIDTH-1:0] pa_i,
    input logic                fault_i,
    input logic [RESP_FAULT_W-1:0] fault_code_i
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
    input logic [PA_WIDTH-1:0] pa_i,
    input logic                fault_i,
    input logic [RESP_FAULT_W-1:0] fault_code_i
  );
    integer cycles;
    begin
      cycles = 0;
      while (m68k_resp_valid !== 1'b1) begin
        /* verilator lint_off STMTDLY */
        #10;
        /* verilator lint_on STMTDLY */
        cycles = cycles + 1;
        if (cycles > 4) begin
          $fatal(1, "timed out waiting for completion");
        end
      end

      assert(m68k_dtack === 1'b1) else $fatal(1, "dtack pulse missing on completion");
      assert(m68k_resp_pa === pa_i)
        else $fatal(1, "completion PA mismatch exp=%h got=%h", pa_i, m68k_resp_pa);
      assert(m68k_resp_fault === fault_i)
        else $fatal(1, "completion fault mismatch exp=%b got=%b", fault_i, m68k_resp_fault);
      assert(m68k_resp_fault_code === fault_code_i)
        else $fatal(1, "completion fault code mismatch exp=%0d got=%0d", fault_code_i, m68k_resp_fault_code);

      /* verilator lint_off STMTDLY */
      #10;
      /* verilator lint_on STMTDLY */
      assert(m68k_resp_valid === 1'b0) else $fatal(1, "response valid must be a pulse");
      assert(m68k_dtack === 1'b0) else $fatal(1, "dtack must be a pulse");
    end
  endtask

  initial begin
    apply_reset();

    assert(m68k_req_ready === 1'b1) else $fatal(1, "request side must come up ready");
    assert(core_req_valid === 1'b0) else $fatal(1, "core request must reset low");
    assert(m68k_resp_valid === 1'b0) else $fatal(1, "response valid must reset low");
    assert(m68k_dtack === 1'b0) else $fatal(1, "dtack must reset low");

    // Read-style request handshakes through to the core and completes cleanly.
    core_req_ready = 1'b1;
    issue_68k_req(16'h1234, 3'b001, 1'b1);
    expect_core_req(16'h1234, 3'b001, 1'b1);
    assert(m68k_req_ready === 1'b0) else $fatal(1, "request side must backpressure while busy");
    drive_core_response(20'hA1_234, 1'b0, RESP_FAULT_NONE);
    expect_completion(20'hA1_234, 1'b0, RESP_FAULT_NONE);
    assert(m68k_req_ready === 1'b1) else $fatal(1, "request side must reopen after read completion");

    // Write-style request uses the same thin forwarding path.
    core_req_ready = 1'b1;
    issue_68k_req(16'h4568, 3'b010, 1'b0);
    expect_core_req(16'h4568, 3'b010, 1'b0);
    drive_core_response(20'hB5_678, 1'b0, RESP_FAULT_NONE);
    expect_completion(20'hB5_678, 1'b0, RESP_FAULT_NONE);

    // Fault completion returns the core fault indication and still pulses dtack.
    core_req_ready = 1'b1;
    issue_68k_req(16'h9ABC, 3'b111, 1'b1);
    expect_core_req(16'h9ABC, 3'b111, 1'b1);
    drive_core_response(20'h0, 1'b1, RESP_FAULT_BUS);
    expect_completion(20'h0, 1'b1, RESP_FAULT_BUS);

    // Downstream backpressure must hold the buffered request stable until ready.
    core_req_ready = 1'b0;
    issue_68k_req(16'hCDEF, 3'b100, 1'b0);
    expect_core_req(16'hCDEF, 3'b100, 1'b0);
    repeat (3) begin
      /* verilator lint_off STMTDLY */
      #10;
      /* verilator lint_on STMTDLY */
      assert(core_req_valid === 1'b1) else $fatal(1, "core request must hold under backpressure");
      assert(core_req_va === 16'hCDEF) else $fatal(1, "held VA changed under backpressure");
      assert(core_req_fc === 3'b100) else $fatal(1, "held FC changed under backpressure");
      assert(core_req_rw === 1'b0) else $fatal(1, "held RW changed under backpressure");
      assert(m68k_req_ready === 1'b0) else $fatal(1, "68k side must remain stalled while buffered");
    end

    core_req_ready = 1'b1;
    /* verilator lint_off STMTDLY */
    #20;
    /* verilator lint_on STMTDLY */
    assert(core_req_valid === 1'b0) else $fatal(1, "core request must clear after ready handshake");
    drive_core_response(20'hCD_EF0, 1'b0, RESP_FAULT_NONE);
    expect_completion(20'hCD_EF0, 1'b0, RESP_FAULT_NONE);
    assert(m68k_req_ready === 1'b1) else $fatal(1, "request side must reopen after stalled transaction completes");

    $display("[if_68k_shim_tb] PASS");
    $finish;
  end

endmodule
`default_nettype wire
