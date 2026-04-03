`timescale 1ns/1ps
`default_nettype none
// -----------------------------------------------------------------------------
// Soft MMU 68k : mmu_core_tb
// Focused integration bench for the first-pass mmu_top datapath.
//
// Compliance exercised:
//   - MC68851 PMMU User's Manual, Section 4 "Address Translation Tables"
//   - MC68851 PMMU User's Manual, Section 4 "Page Descriptors"
//   - MC68851 PMMU User's Manual, Section 5.2 "Address Translation Cache"
//   - MC68030 User's Manual, Section 9 "Memory Management Unit"
//   - M68000 Family Programmer's Reference Manual, instruction entries
//     "PLOAD", "PFLUSH", "PFLUSHA", and "PTEST"
// -----------------------------------------------------------------------------

`include "rtl/core/mmu_regs.v"
`include "rtl/core/mmu_decode.v"
`include "rtl/core/perm_check.v"
`include "rtl/core/tlb_compare.v"
`include "rtl/core/tlb_dm.v"
`include "rtl/core/pt_walker.v"
`include "rtl/core/flush_ctrl.v"

module mmu_core_tb;

  import tb_pkg::*;
  import tb_utils_pkg::*;

  localparam int VA_WIDTH      = 16;
  localparam int PA_WIDTH      = 16;
  localparam int PAGE_SHIFT    = 8;
  localparam int FC_WIDTH      = TB_FC_WIDTH;
  localparam int DESCR_WIDTH   = 32;
  localparam int TLB_ENTRIES   = 4;
  localparam int ATTR_WIDTH    = 5;
  localparam int STATUS_WIDTH  = TB_STATUS_BITS_W;
  localparam int CMD_WIDTH     = TB_CMD_WIDTH;
  localparam int RESP_FAULT_W  = TB_RESP_FAULT_WIDTH;
  localparam int VPN_WIDTH     = VA_WIDTH - PAGE_SHIFT;
  localparam int PFN_WIDTH     = PA_WIDTH - PAGE_SHIFT;
  localparam int DESCR_BYTES   = DESCR_WIDTH / 8;
  localparam int DESCR_SHIFT   = $clog2(DESCR_BYTES);

  localparam logic [1:0] DESC_DT_PAGE = 2'b10;
  localparam logic [VA_WIDTH-1:0] VA_HIT   = 16'h1234;
  localparam logic [VA_WIDTH-1:0] VA_MISS  = 16'h2234;
  localparam logic [VA_WIDTH-1:0] VA_PERM  = 16'h3234;
  localparam logic [VA_WIDTH-1:0] VA_FAULT = 16'h4234;
  localparam logic [FC_WIDTH-1:0] FC_USER_DATA = 3'b001;
  localparam logic [PA_WIDTH-1:0] TABLE_BASE = 16'h0200;

  logic                    clk;
  logic                    rst_n;

  logic                    req_valid;
  logic                    req_ready;
  logic [VA_WIDTH-1:0]     req_va;
  logic [FC_WIDTH-1:0]     req_fc;
  logic                    req_rw;
  logic                    req_fetch;

  logic                    resp_valid;
  logic [PA_WIDTH-1:0]     resp_pa;
  logic                    resp_hit;
  logic                    resp_fault;
  logic [RESP_FAULT_W-1:0] resp_fault_code;
  logic [4:0]              resp_perm_fault;

  logic                    reg_wr_en;
  logic                    reg_rd_en;
  logic [3:0]              reg_addr;
  logic [31:0]             reg_wr_data;
  logic [31:0]             reg_rd_data;

  logic                    cmd_valid;
  logic [CMD_WIDTH-1:0]    cmd_op;
  logic [VA_WIDTH-1:0]     cmd_addr;
  logic [FC_WIDTH-1:0]     cmd_fc;
  logic                    cmd_ready;
  logic                    cmd_busy;
  logic                    status_valid;
  logic [CMD_WIDTH-1:0]    status_cmd;
  logic                    status_hit;
  logic [PA_WIDTH-1:0]     status_pa;
  logic [STATUS_WIDTH-1:0] status_bits;

  logic                    walk_mem_req_valid;
  logic [PA_WIDTH-1:0]     walk_mem_req_addr;
  logic                    walk_mem_resp_valid;
  logic [DESCR_WIDTH-1:0]  walk_mem_resp_data;
  logic                    walk_mem_resp_err;
  logic                    busy;

  logic [DESCR_WIDTH-1:0]  mem_desc [0:(1<<VPN_WIDTH)-1];
  logic                    mem_err  [0:(1<<VPN_WIDTH)-1];
  logic [PA_WIDTH-1:0]     mem_req_offset;
  logic [VPN_WIDTH-1:0]    mem_word_index;
  /* verilator lint_off UNUSED */
  wire                     unused_tb = (^reg_rd_data) ^ cmd_busy ^ (^status_bits) ^ (^mem_req_offset);
  /* verilator lint_on UNUSED */

  mmu_top #(
    .VA_WIDTH      (VA_WIDTH),
    .PA_WIDTH      (PA_WIDTH),
    .PAGE_SHIFT    (PAGE_SHIFT),
    .FC_WIDTH      (FC_WIDTH),
    .DESCR_WIDTH   (DESCR_WIDTH),
    .TLB_ENTRIES   (TLB_ENTRIES),
    .ATTR_WIDTH    (ATTR_WIDTH),
    .STATUS_WIDTH  (STATUS_WIDTH),
    .CMD_WIDTH     (CMD_WIDTH),
    .CMD_NOP       (TB_CMD_NOP),
    .CMD_FLUSH_ALL (TB_CMD_FLUSH_ALL),
    .CMD_FLUSH_MATCH(TB_CMD_FLUSH_MATCH),
    .CMD_PROBE     (TB_CMD_PROBE),
    .CMD_PRELOAD   (TB_CMD_PRELOAD),
    .RESP_FAULT_W       (RESP_FAULT_W),
    .RESP_FAULT_NONE    (TB_RESP_FAULT_NONE),
    .RESP_FAULT_PERM    (TB_RESP_FAULT_PERM),
    .RESP_FAULT_INVALID (TB_RESP_FAULT_INVALID),
    .RESP_FAULT_UNMAPPED(TB_RESP_FAULT_UNMAPPED),
    .RESP_FAULT_BUS     (TB_RESP_FAULT_BUS)
  ) dut (
    .clk                (clk),
    .rst_n              (rst_n),
    .req_valid_i        (req_valid),
    .req_ready_o        (req_ready),
    .req_va_i           (req_va),
    .req_fc_i           (req_fc),
    .req_rw_i           (req_rw),
    .req_fetch_i        (req_fetch),
    .resp_valid_o       (resp_valid),
    .resp_pa_o          (resp_pa),
    .resp_hit_o         (resp_hit),
    .resp_fault_o       (resp_fault),
    .resp_fault_code_o  (resp_fault_code),
    .resp_perm_fault_o  (resp_perm_fault),
    .reg_wr_en_i        (reg_wr_en),
    .reg_rd_en_i        (reg_rd_en),
    .reg_addr_i         (reg_addr),
    .reg_wr_data_i      (reg_wr_data),
    .reg_rd_data_o      (reg_rd_data),
    .cmd_valid_i        (cmd_valid),
    .cmd_op_i           (cmd_op),
    .cmd_addr_i         (cmd_addr),
    .cmd_fc_i           (cmd_fc),
    .cmd_ready_o        (cmd_ready),
    .cmd_busy_o         (cmd_busy),
    .status_valid_o     (status_valid),
    .status_cmd_o       (status_cmd),
    .status_hit_o       (status_hit),
    .status_pa_o        (status_pa),
    .status_bits_o      (status_bits),
    .walk_mem_req_valid_o(walk_mem_req_valid),
    .walk_mem_req_addr_o(walk_mem_req_addr),
    .walk_mem_resp_valid_i(walk_mem_resp_valid),
    .walk_mem_resp_data_i (walk_mem_resp_data),
    .walk_mem_resp_err_i  (walk_mem_resp_err),
    .busy_o             (busy)
  );

  initial clk = 1'b0;
  /* verilator lint_off STMTDLY */
  always #5 clk = ~clk;
  /* verilator lint_on STMTDLY */

  assign mem_req_offset     = walk_mem_req_addr - TABLE_BASE;
  assign mem_word_index     = mem_req_offset[VPN_WIDTH+DESCR_SHIFT-1:DESCR_SHIFT];
  assign walk_mem_resp_valid = walk_mem_req_valid;
  assign walk_mem_resp_data  = mem_desc[mem_word_index];
  assign walk_mem_resp_err   = walk_mem_req_valid && mem_err[mem_word_index];

  function automatic [DESCR_WIDTH-1:0] make_page_desc(
    input logic                  valid_i,
    input logic                  s_i,
    input logic                  wp_i,
    input logic                  ci_i,
    input logic                  m_i,
    input logic                  u_i,
    input logic [PFN_WIDTH-1:0]  pfn_i
  );
    reg [DESCR_WIDTH-1:0] tmp;
    begin
      tmp = '0;
      tmp[DESCR_WIDTH-1 -: 2] = DESC_DT_PAGE;
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
      req_valid   = 1'b0;
      req_va      = '0;
      req_fc      = '0;
      req_rw      = 1'b1;
      req_fetch   = 1'b0;
      reg_wr_en   = 1'b0;
      reg_rd_en   = 1'b0;
      reg_addr    = '0;
      reg_wr_data = '0;
      cmd_valid   = 1'b0;
      cmd_op      = TB_CMD_NOP;
      cmd_addr    = '0;
      cmd_fc      = '0;
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

  task automatic reg_write(
    input logic [3:0]  addr_i,
    input logic [31:0] data_i
  );
    begin
      reg_wr_en   = 1'b1;
      reg_addr    = addr_i;
      reg_wr_data = data_i;
      /* verilator lint_off STMTDLY */
      #10;
      /* verilator lint_on STMTDLY */
      reg_wr_en   = 1'b0;
      reg_addr    = '0;
      reg_wr_data = '0;
    end
  endtask

  task automatic cpu_request(
    input logic [VA_WIDTH-1:0] va_i,
    input logic [FC_WIDTH-1:0] fc_i,
    input logic                rw_i,
    input logic                fetch_i
  );
    begin
      `TB_FATAL_IF_FALSE("request port ready before issuing CPU request", req_ready)
      req_valid = 1'b1;
      req_va    = va_i;
      req_fc    = fc_i;
      req_rw    = rw_i;
      req_fetch = fetch_i;
      /* verilator lint_off STMTDLY */
      #10;
      /* verilator lint_on STMTDLY */
      req_valid = 1'b0;
      req_va    = '0;
      req_fc    = '0;
      req_rw    = 1'b1;
      req_fetch = 1'b0;
    end
  endtask

  task automatic command_issue(
    input tb_cmd_op_e           op_i,
    input logic [VA_WIDTH-1:0]  addr_i,
    input logic [FC_WIDTH-1:0]  fc_i
  );
    begin
      `TB_FATAL_IF_FALSE("command port ready before issuing MMU command", cmd_ready)
      cmd_valid = 1'b1;
      cmd_op    = op_i;
      cmd_addr  = addr_i;
      cmd_fc    = fc_i;
      /* verilator lint_off STMTDLY */
      #10;
      /* verilator lint_on STMTDLY */
      cmd_valid = 1'b0;
      cmd_op    = TB_CMD_NOP;
      cmd_addr  = '0;
      cmd_fc    = '0;
    end
  endtask

  task automatic wait_for_resp;
    begin
      `TB_WAIT_UNTIL("translation response", 13,
                     begin
                       /* verilator lint_off STMTDLY */
                       #10;
                       /* verilator lint_on STMTDLY */
                     end,
                     resp_valid)
    end
  endtask

  task automatic wait_for_status;
    begin
      `TB_WAIT_UNTIL("command status", 13,
                     begin
                       /* verilator lint_off STMTDLY */
                       #10;
                       /* verilator lint_on STMTDLY */
                     end,
                     status_valid)
    end
  endtask

  task automatic wait_until_idle;
    begin
      `TB_WAIT_UNTIL("core idle", 13,
                     begin
                       /* verilator lint_off STMTDLY */
                       #10;
                       /* verilator lint_on STMTDLY */
                     end,
                     !busy)
    end
  endtask

  initial begin
    clear_inputs();
    clear_memory();
    tb_release_reset(rst_n);

    mem_desc[VA_HIT[VA_WIDTH-1:PAGE_SHIFT]]  = make_page_desc(1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 8'hA1);
    mem_desc[VA_MISS[VA_WIDTH-1:PAGE_SHIFT]] = make_page_desc(1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 8'hB2);
    mem_desc[VA_PERM[VA_WIDTH-1:PAGE_SHIFT]] = make_page_desc(1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 8'hC3);
    mem_desc[VA_FAULT[VA_WIDTH-1:PAGE_SHIFT]] = make_page_desc(1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 8'hD4);
    mem_err[VA_FAULT[VA_WIDTH-1:PAGE_SHIFT]] = 1'b1;

    /* verilator lint_off STMTDLY */
    #20;
    tb_assert_reset(rst_n);
    #20;
    tb_release_reset(rst_n);
    #10;
    /* verilator lint_on STMTDLY */

    reg_write(4'h0, {16'h0000, TABLE_BASE});
    reg_write(4'h2, 32'h0000_0080);

    // Preload path followed by probe and a CPU-side TLB hit.
    command_issue(TB_CMD_PRELOAD, VA_HIT, FC_USER_DATA);
    wait_for_status();
    `TB_FATAL_IF_NOT_EQUAL("preload status command", TB_CMD_PRELOAD, status_cmd)
    wait_until_idle();

    command_issue(TB_CMD_PROBE, VA_HIT, FC_USER_DATA);
    wait_for_status();
    `TB_FATAL_IF_NOT_EQUAL("probe status command", TB_CMD_PROBE, status_cmd)
    `TB_FATAL_IF_FALSE("probe hits after preload", status_hit)
    `TB_FATAL_IF_NOT_EQUAL("probe PA", 16'hA134, status_pa)
    `TB_FATAL_IF_NOT_EQUAL("probe attrs", 5'b00101, status_bits[4:0])

    cpu_request(VA_HIT, FC_USER_DATA, 1'b1, 1'b0);
    wait_for_resp();
    `TB_FATAL_IF_FALSE("direct TLB hit reported", resp_hit)
    `TB_FATAL_IF_TRUE("no fault on direct hit", resp_fault)
    `TB_FATAL_IF_NOT_EQUAL("hit PA", 16'hA134, resp_pa)

    // Flush the matching entry, confirm the probe misses, then exercise miss->walk->refill->hit.
    command_issue(TB_CMD_FLUSH_MATCH, VA_HIT, FC_USER_DATA);
    wait_for_status();
    `TB_FATAL_IF_NOT_EQUAL("flush-match status command", TB_CMD_FLUSH_MATCH, status_cmd)

    command_issue(TB_CMD_PROBE, VA_HIT, FC_USER_DATA);
    wait_for_status();
    `TB_FATAL_IF_NOT_EQUAL("post-flush probe command", TB_CMD_PROBE, status_cmd)
    `TB_FATAL_IF_TRUE("probe misses after targeted flush", status_hit)

    cpu_request(VA_MISS, FC_USER_DATA, 1'b1, 1'b0);
    wait_for_resp();
    `TB_FATAL_IF_TRUE("first access after miss does not report hit", resp_hit)
    `TB_FATAL_IF_TRUE("no fault on walker success", resp_fault)
    `TB_FATAL_IF_NOT_EQUAL("walker PA", 16'hB234, resp_pa)

    cpu_request(VA_MISS, FC_USER_DATA, 1'b1, 1'b0);
    wait_for_resp();
    `TB_FATAL_IF_FALSE("second access hits after refill", resp_hit)
    `TB_FATAL_IF_TRUE("no fault after refill hit", resp_fault)
    `TB_FATAL_IF_NOT_EQUAL("refill hit PA", 16'hB234, resp_pa)

    // User access to a supervisor-only mapping must fault.
    cpu_request(VA_PERM, FC_USER_DATA, 1'b1, 1'b0);
    wait_for_resp();
    `TB_FATAL_IF_FALSE("permission fault asserted", resp_fault)
    `TB_FATAL_IF_NOT_EQUAL("permission fault code", TB_RESP_FAULT_PERM, resp_fault_code)
    `TB_FATAL_IF_NOT_EQUAL("permission fault bits", 5'b01001, resp_perm_fault)

    // Walker-side descriptor bus fault must report as a walker fault.
    cpu_request(VA_FAULT, FC_USER_DATA, 1'b1, 1'b0);
    wait_for_resp();
    `TB_FATAL_IF_FALSE("walker fault asserted", resp_fault)
    `TB_FATAL_IF_NOT_EQUAL("walker bus fault code", TB_RESP_FAULT_BUS, resp_fault_code)
    `TB_FATAL_IF_TRUE("walker fault does not report hit", resp_hit)

    // TTR placeholder behavior is intentionally not checked here because this
    // pass does not yet decode tt0/tt1 into a transparent-bypass path.

    $display("[mmu_core_tb] PASS");
    $finish;
  end

endmodule
`default_nettype wire
