`timescale 1ns/1ps
`default_nettype none

module tb_utils_smoke_tb;

  import tb_pkg::*;
  import tb_utils_pkg::*;

  logic rst_n;
  logic ready;
  int countdown;
  tb_status_s status_rec;
  tb_lookup_req_s lookup_req;
  tb_page_desc_s page_desc;
  /* verilator lint_off UNUSED */
  wire unused_smoke = ^status_rec ^ ^lookup_req ^ ^page_desc;
  /* verilator lint_on UNUSED */

  task automatic countdown_step;
    begin
      if (countdown > 0) begin
        countdown = countdown - 1;
      end
      if (countdown == 0) begin
        ready = 1'b1;
      end
    end
  endtask

  initial begin
    tb_assert_reset(rst_n);
    `TB_FATAL_IF_NOT_EQUAL("reset starts asserted", 1'b0, rst_n)

    tb_release_reset(rst_n);
    `TB_FATAL_IF_NOT_EQUAL("reset releases high", 1'b1, rst_n)

    status_rec = '0;
    status_rec.cmd  = TB_CMD_PROBE;
    status_rec.hit  = 1'b1;
    status_rec.pa   = 32'h0000_1234;
    status_rec.bits = 8'hA5;

    lookup_req = '0;
    lookup_req.va = 32'h0000_1234;
    lookup_req.fc = 3'b101;

    page_desc = '0;
    page_desc.dt              = 2'b10;
    page_desc.valid           = 1'b1;
    page_desc.supervisor_only = 1'b0;
    page_desc.write_protect   = 1'b1;
    page_desc.cache_inhibit   = 1'b0;
    page_desc.modified        = 1'b1;
    page_desc.used            = 1'b1;
    page_desc.pfn             = 24'h00CA_FE;

    `TB_FATAL_IF_NOT_EQUAL("probe opcode matches shared package", TB_CMD_PROBE, status_rec.cmd)
    `TB_FATAL_IF_FALSE("status hit stores expected value", status_rec.hit)
    `TB_FATAL_IF_NOT_EQUAL("status PA stores expected value", 32'h0000_1234, status_rec.pa)
    `TB_FATAL_IF_NOT_EQUAL("status bits store expected value", 8'hA5, status_rec.bits)
    `TB_FATAL_IF_NOT_EQUAL("lookup VA stores expected value", 32'h0000_1234, lookup_req.va)
    `TB_FATAL_IF_NOT_EQUAL("lookup FC stores expected value", 3'b101, lookup_req.fc)
    `TB_FATAL_IF_NOT_EQUAL("page descriptor DT stores expected value", 2'b10, page_desc.dt)
    `TB_FATAL_IF_FALSE("page descriptor valid bit stores expected value", page_desc.valid)
    `TB_FATAL_IF_NOT_EQUAL("page descriptor flags store expected value", 5'b01011,
                           {page_desc.supervisor_only, page_desc.write_protect,
                            page_desc.cache_inhibit, page_desc.modified, page_desc.used})
    `TB_FATAL_IF_NOT_EQUAL("page descriptor PFN stores expected value", 24'h00CA_FE, page_desc.pfn)
    `TB_FATAL_IF_FALSE("fault-name helper returns expected text", tb_fault_name(TB_RESP_FAULT_BUS) == "bus")

    ready = 1'b0;
    countdown = 3;
    `TB_WAIT_UNTIL("countdown reaches ready", 4, countdown_step(), ready)
    `TB_FATAL_IF_FALSE("bounded wait helper drove ready high", ready)
    `TB_FATAL_IF_NOT_EQUAL("countdown consumed all steps", 0, countdown)
    `TB_FATAL_IF_TRUE("shared fault enum none must not equal bus", TB_RESP_FAULT_NONE == TB_RESP_FAULT_BUS)

    $display("[tb_utils_smoke_tb] PASS");
    $finish;
  end

endmodule

`default_nettype wire
