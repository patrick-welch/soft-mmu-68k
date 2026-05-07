`timescale 1ns/1ps
`default_nettype none
// -----------------------------------------------------------------------------
// Soft MMU 68k : tb_utils
// Tiny shared helper layer for unit and integration TBs.
//
// Intended use:
//   - Compile this file before benches that use the macros below.
//   - Import tb_utils_pkg for the small reset/fault-name helpers.
//   - Keep helpers side-effect-light; this is not a scoreboard framework.
// -----------------------------------------------------------------------------

`ifndef TB_UTILS_SV
`define TB_UTILS_SV

`define TB_FATAL_IF_NOT_EQUAL(WHAT, EXP, ACT) \
  begin \
    if ((ACT) !== (EXP)) begin \
      $fatal(1, "[TB_FATAL_IF_NOT_EQUAL] %s exp=%0h act=%0h", WHAT, EXP, ACT); \
    end \
  end

`define TB_FATAL_IF_TRUE(WHAT, COND) \
  begin \
    if ((COND) === 1'b1) begin \
      $fatal(1, "[TB_FATAL_IF_TRUE] %s", WHAT); \
    end \
  end

`define TB_FATAL_IF_FALSE(WHAT, COND) \
  begin \
    if ((COND) !== 1'b1) begin \
      $fatal(1, "[TB_FATAL_IF_FALSE] %s", WHAT); \
    end \
  end

// Bounded zero-time polling helper.
// The caller supplies a small STEP statement so benches can reuse the same
// pattern with either hand-stepped models or combinational settle checks.
`define TB_WAIT_UNTIL(WHAT, LIMIT, STEP_STMT, COND) \
  begin : tb_wait_block_``__LINE__ \
    int tb_wait_iter; \
    bit tb_wait_seen; \
    tb_wait_seen = 1'b0; \
    for (tb_wait_iter = 0; (tb_wait_iter < (LIMIT)) && (!tb_wait_seen); tb_wait_iter = tb_wait_iter + 1) begin \
      if ((COND) === 1'b1) begin \
        tb_wait_seen = 1'b1; \
      end else begin \
        STEP_STMT; \
      end \
    end \
    if (!tb_wait_seen && ((COND) === 1'b1)) begin \
      tb_wait_seen = 1'b1; \
    end \
    if (!tb_wait_seen) begin \
      $fatal(1, "[TB_WAIT_UNTIL] %s timed out after %0d step(s)", WHAT, LIMIT); \
    end \
  end

/* verilator lint_off DECLFILENAME */
package tb_utils_pkg;
  import tb_pkg::*;

  function automatic string tb_fault_name(input tb_resp_fault_e fault_i);
    begin
      case (fault_i)
        TB_RESP_FAULT_NONE:     tb_fault_name = "none";
        TB_RESP_FAULT_PERM:     tb_fault_name = "perm";
        TB_RESP_FAULT_INVALID:  tb_fault_name = "invalid";
        TB_RESP_FAULT_UNMAPPED: tb_fault_name = "unmapped";
        TB_RESP_FAULT_BUS:      tb_fault_name = "bus";
        default:                tb_fault_name = "unknown";
      endcase
    end
  endfunction

  task automatic tb_assert_reset(output logic rst_n);
    begin
      rst_n = 1'b0;
    end
  endtask

  task automatic tb_release_reset(output logic rst_n);
    begin
      rst_n = 1'b1;
    end
  endtask

endpackage
/* verilator lint_on DECLFILENAME */

`endif

`default_nettype wire
