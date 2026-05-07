`timescale 1ns/1ps
`default_nettype none
// -----------------------------------------------------------------------------
// Soft MMU 68k : tb_pkg
// Shared constants and compact records for unit and integration testbenches.
//
// Intended use:
//   - Import this package in TBs that need canonical command/fault encodings.
//   - Reuse the small packed structs when moving status/descriptor expectations
//     around a bench without re-declaring ad hoc bitfields.
// -----------------------------------------------------------------------------

package tb_pkg;

  localparam integer TB_CMD_WIDTH        = 3;
  localparam integer TB_RESP_FAULT_WIDTH = 3;
  localparam integer TB_STATUS_BITS_W    = 8;
  localparam integer TB_ADDR_WIDTH       = 32;
  localparam integer TB_FC_WIDTH         = 3;
  localparam integer TB_DESC_PFN_WIDTH   = 24;

  typedef enum logic [TB_CMD_WIDTH-1:0] {
    TB_CMD_NOP         = 3'd0,
    TB_CMD_FLUSH_ALL   = 3'd1,
    TB_CMD_FLUSH_MATCH = 3'd2,
    TB_CMD_PROBE       = 3'd3,
    TB_CMD_PRELOAD     = 3'd4
  } tb_cmd_op_e;

  typedef enum logic [TB_RESP_FAULT_WIDTH-1:0] {
    TB_RESP_FAULT_NONE     = 3'd0,
    TB_RESP_FAULT_PERM     = 3'd1,
    TB_RESP_FAULT_INVALID  = 3'd2,
    TB_RESP_FAULT_UNMAPPED = 3'd3,
    TB_RESP_FAULT_BUS      = 3'd4
  } tb_resp_fault_e;

  typedef struct packed {
    logic [1:0]                  dt;
    logic                        valid;
    logic                        supervisor_only;
    logic                        write_protect;
    logic                        cache_inhibit;
    logic                        modified;
    logic                        used;
    logic [TB_DESC_PFN_WIDTH-1:0] pfn;
  } tb_page_desc_s;

  typedef struct packed {
    tb_cmd_op_e                  cmd;
    logic                        hit;
    logic [TB_ADDR_WIDTH-1:0]    pa;
    logic [TB_STATUS_BITS_W-1:0] bits;
  } tb_status_s;

  typedef struct packed {
    logic [TB_ADDR_WIDTH-1:0] va;
    logic [TB_FC_WIDTH-1:0]   fc;
  } tb_lookup_req_s;

endpackage

`default_nettype wire
