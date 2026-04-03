`timescale 1ns/1ps
`default_nettype none

module pt_walker_tb;

  localparam int VA_WIDTH    = 16;
  localparam int PA_WIDTH    = 16;
  localparam int PAGE_SHIFT  = 8;
  localparam int DESCR_WIDTH = 32;
  localparam int FC_WIDTH    = 3;
  localparam int ATTR_WIDTH  = 5;
  localparam int VPN_WIDTH   = VA_WIDTH - PAGE_SHIFT;
  localparam int PFN_WIDTH   = PA_WIDTH - PAGE_SHIFT;
  localparam int DESCR_BYTES = DESCR_WIDTH / 8;
  localparam int DESCR_BYTE_SHIFT = $clog2(DESCR_BYTES);

  localparam logic [1:0] DESC_DT_PAGE = 2'b10;
  localparam logic [1:0] DESC_DT_PTR  = 2'b01;
  localparam logic [1:0] FAULT_NONE   = 2'b00;
  localparam logic [1:0] FAULT_INVALID= 2'b01;
  localparam logic [1:0] FAULT_UNMAPPED=2'b10;
  localparam logic [1:0] FAULT_BUS    = 2'b11;

  logic clk;
  logic rst_n;

  logic                  start;
  logic [VA_WIDTH-1:0]   va;
  logic [FC_WIDTH-1:0]   fc;
  logic [PA_WIDTH-1:0]   table_base;
  logic [VPN_WIDTH-1:0]  table_entries;

  logic                  mem_req_valid;
  logic [PA_WIDTH-1:0]   mem_req_addr;
  logic                  mem_resp_valid;
  logic [DESCR_WIDTH-1:0] mem_resp_data;
  logic                  mem_resp_err;

  logic                  busy;
  logic                  done;
  logic                  refill_valid;
  logic [VA_WIDTH-1:0]   refill_va;
  logic [PA_WIDTH-1:0]   walk_pa_base;
  logic [PFN_WIDTH-1:0]  walk_ppn;
  logic [ATTR_WIDTH-1:0] walk_attr;
  logic                  fault_valid;
  logic [1:0]            fault_code;

  logic [DESCR_WIDTH-1:0] mem_desc [0:(1<<VPN_WIDTH)-1];
  logic                   mem_err  [0:(1<<VPN_WIDTH)-1];
  logic [PA_WIDTH-1:0]    mem_req_offset;
  logic [VPN_WIDTH-1:0]   mem_word_index;
  logic                   mem_req_offset_aligned;
  logic                   mem_req_offset_upper_zero;

  pt_walker #(
    .VA_WIDTH    (VA_WIDTH),
    .PA_WIDTH    (PA_WIDTH),
    .PAGE_SHIFT  (PAGE_SHIFT),
    .DESCR_WIDTH (DESCR_WIDTH),
    .FC_WIDTH    (FC_WIDTH),
    .ATTR_WIDTH  (ATTR_WIDTH)
  ) dut (
    .clk            (clk),
    .rst_n          (rst_n),
    .start_i        (start),
    .va_i           (va),
    .fc_i           (fc),
    .table_base_i   (table_base),
    .table_entries_i(table_entries),
    .mem_req_valid_o(mem_req_valid),
    .mem_req_addr_o (mem_req_addr),
    .mem_resp_valid_i(mem_resp_valid),
    .mem_resp_data_i(mem_resp_data),
    .mem_resp_err_i (mem_resp_err),
    .busy_o         (busy),
    .done_o         (done),
    .refill_valid_o (refill_valid),
    .refill_va_o    (refill_va),
    .walk_pa_base_o (walk_pa_base),
    .walk_ppn_o     (walk_ppn),
    .walk_attr_o    (walk_attr),
    .fault_valid_o  (fault_valid),
    .fault_code_o   (fault_code)
  );

  initial clk = 1'b0;
  /* verilator lint_off STMTDLY */
  always #5 clk = ~clk;
  /* verilator lint_on STMTDLY */

  assign mem_req_offset = mem_req_addr - table_base;
  assign mem_word_index = mem_req_offset[VPN_WIDTH+DESCR_BYTE_SHIFT-1:DESCR_BYTE_SHIFT];
  assign mem_req_offset_aligned = (mem_req_offset[DESCR_BYTE_SHIFT-1:0] == '0);
  assign mem_req_offset_upper_zero = (mem_req_offset[PA_WIDTH-1:VPN_WIDTH+DESCR_BYTE_SHIFT] == '0);
  assign mem_resp_valid = mem_req_valid;
  assign mem_resp_data  = mem_desc[mem_word_index];
  assign mem_resp_err   = mem_req_valid && mem_err[mem_word_index];

  function automatic [DESCR_WIDTH-1:0] make_page_desc(
    input logic                        valid_i,
    input logic [1:0]                  dt_i,
    input logic                        s_i,
    input logic                        wp_i,
    input logic                        ci_i,
    input logic                        m_i,
    input logic                        u_i,
    input logic [PFN_WIDTH-1:0]        pfn_i
  );
    reg [DESCR_WIDTH-1:0] tmp;
    begin
      tmp = '0;
      tmp[DESCR_WIDTH-1 -: 2] = dt_i;
      tmp[DESCR_WIDTH-3]      = valid_i;
      tmp[DESCR_WIDTH-4]      = s_i;
      tmp[DESCR_WIDTH-5]      = wp_i;
      tmp[DESCR_WIDTH-6]      = ci_i;
      tmp[DESCR_WIDTH-7]      = m_i;
      tmp[DESCR_WIDTH-8]      = u_i;
      tmp[DESCR_WIDTH-9 -: PFN_WIDTH] = pfn_i;
      make_page_desc = tmp;
    end
  endfunction

  task automatic clear_inputs;
    begin
      start         = 1'b0;
      va            = '0;
      fc            = '0;
      table_base    = '0;
      table_entries = '0;
    end
  endtask

  task automatic clear_memory;
    integer idx;
    begin
      for (idx = 0; idx < (1 << VPN_WIDTH); idx = idx + 1) begin
        mem_desc[idx] = '0;
        mem_err[idx]  = 1'b0;
      end
    end
  endtask

  task automatic drive_walk(
    input logic [VA_WIDTH-1:0]  va_i,
    input logic [VPN_WIDTH-1:0] entries_i
  );
    begin
      va            = va_i;
      table_base    = 16'h0200;
      table_entries = entries_i;
      fc            = 3'b101;
      start         = 1'b0;
    end
  endtask

  task automatic expect_success(
    input logic [VA_WIDTH-1:0]  exp_va,
    input logic [PFN_WIDTH-1:0] exp_ppn,
    input logic [ATTR_WIDTH-1:0] exp_attr
  );
    begin
      assert(done === 1'b1) else $fatal(1, "expected done on success");
      assert(refill_valid === 1'b1) else $fatal(1, "expected refill_valid on success");
      assert(fault_valid === 1'b0) else $fatal(1, "unexpected fault on success");
      assert(fault_code === FAULT_NONE) else $fatal(1, "unexpected fault code %0d", fault_code);
      assert(busy === 1'b0) else $fatal(1, "walker must be idle when success completes");
      assert(mem_req_offset_aligned === 1'b1) else $fatal(1, "descriptor request must be aligned");
      assert(mem_req_offset_upper_zero === 1'b1) else $fatal(1, "descriptor request index overflowed table space");
      assert(refill_va === exp_va) else $fatal(1, "refill_va mismatch exp=%h got=%h", exp_va, refill_va);
      assert(walk_ppn === exp_ppn) else $fatal(1, "walk_ppn mismatch exp=%h got=%h", exp_ppn, walk_ppn);
      assert(walk_pa_base === {exp_ppn, {PAGE_SHIFT{1'b0}}})
        else $fatal(1, "walk_pa_base mismatch exp=%h got=%h", {exp_ppn, {PAGE_SHIFT{1'b0}}}, walk_pa_base);
      assert(walk_attr === exp_attr) else $fatal(1, "walk_attr mismatch exp=%h got=%h", exp_attr, walk_attr);
    end
  endtask

  task automatic expect_fault(
    input logic [1:0] exp_fault
  );
    begin
      assert(done === 1'b1) else $fatal(1, "expected done on fault");
      assert(refill_valid === 1'b0) else $fatal(1, "refill_valid must stay low on fault");
      assert(fault_valid === 1'b1) else $fatal(1, "fault_valid missing");
      assert(busy === 1'b0) else $fatal(1, "walker must be idle when fault completes");
      assert(mem_req_offset_aligned === 1'b1 || exp_fault == FAULT_UNMAPPED)
        else $fatal(1, "descriptor request must be aligned on faulted lookup");
      assert(fault_code === exp_fault)
        else $fatal(1, "fault_code mismatch exp=%0d got=%0d", exp_fault, fault_code);
    end
  endtask

  initial begin
    clear_inputs();
    clear_memory();
    rst_n = 1'b1;

    /* verilator lint_off STMTDLY */
    #10;
    rst_n = 1'b0;
    #10;
    rst_n = 1'b1;
    #10;
    /* verilator lint_on STMTDLY */

    mem_desc[8'h12] = make_page_desc(1'b1, DESC_DT_PAGE, 1'b1, 1'b0, 1'b1, 1'b0, 1'b1, 8'hA5);
    drive_walk(16'h1234, 8'h40);
    start = 1'b1;
    /* verilator lint_off STMTDLY */
    #10;
    start = 1'b0;
    #10;
    /* verilator lint_on STMTDLY */
    expect_success(16'h1234, 8'hA5, 5'b10101);

    mem_desc[8'h22] = make_page_desc(1'b0, DESC_DT_PAGE, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 8'h00);
    drive_walk(16'h2234, 8'h40);
    start = 1'b1;
    /* verilator lint_off STMTDLY */
    #10;
    start = 1'b0;
    #10;
    /* verilator lint_on STMTDLY */
    expect_fault(FAULT_INVALID);

    mem_desc[8'h32] = make_page_desc(1'b1, DESC_DT_PTR, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 8'h55);
    drive_walk(16'h3234, 8'h40);
    start = 1'b1;
    /* verilator lint_off STMTDLY */
    #10;
    start = 1'b0;
    #10;
    /* verilator lint_on STMTDLY */
    expect_fault(FAULT_UNMAPPED);

    mem_err[8'h42] = 1'b1;
    drive_walk(16'h4234, 8'h80);
    start = 1'b1;
    /* verilator lint_off STMTDLY */
    #10;
    start = 1'b0;
    #10;
    /* verilator lint_on STMTDLY */
    expect_fault(FAULT_BUS);

    drive_walk(16'hF234, 8'h40);
    start = 1'b1;
    /* verilator lint_off STMTDLY */
    #10;
    start = 1'b0;
    #1;
    /* verilator lint_on STMTDLY */
    expect_fault(FAULT_UNMAPPED);

    $display("[pt_walker_tb] PASS");
    $finish;
  end

endmodule
`default_nettype wire
