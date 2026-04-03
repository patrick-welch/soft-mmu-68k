`timescale 1ns/1ps
`default_nettype none
// -----------------------------------------------------------------------------
// Soft MMU 68k : mmu_top
// First-pass integration wrapper for register/control, TLB lookup, page walk,
// refill, and permission checks.
//
// Compliance:
//   - MC68851 PMMU User's Manual, Section 4 "Address Translation Tables"
//   - MC68851 PMMU User's Manual, Section 4 "Page Descriptors"
//   - MC68851 PMMU User's Manual, Section 5.2 "Address Translation Cache"
//   - MC68030 User's Manual, Section 9 "Memory Management Unit"
//   - M68000 Family Programmer's Reference Manual, instruction entries
//     "PLOAD", "PFLUSH", "PFLUSHA", and "PTEST"
//
// Packet scope:
//   - Single outstanding translation request.
//   - Lookup direct-mapped TLB first.
//   - On miss, perform a minimal walker-backed refill.
//   - On permission failure, return a fault without modeling full bus timing.
//   - First-pass TT/TTR qualification is implemented ahead of TLB/walker use.
//   - This is intentionally a subset, not a full Motorola MMUSR/PTEST model.
//   - Compliance references used by this packet's TT subset:
//       MC68851 PMMU User's Manual, Section 4.4 "Transparent Translation"
//       MC68030 User's Manual, Section 9 "Memory Management Unit"
// -----------------------------------------------------------------------------

module mmu_top #(
  parameter integer VA_WIDTH      = 24,
  parameter integer PA_WIDTH      = 24,
  parameter integer PAGE_SHIFT    = 12,
  parameter integer FC_WIDTH      = 3,
  parameter integer DESCR_WIDTH   = 32,
  parameter integer TLB_ENTRIES   = 16,
  parameter integer ATTR_WIDTH    = 5,
  parameter integer STATUS_WIDTH  = 8,
  parameter integer CMD_WIDTH     = 3,
  parameter integer RESP_FAULT_W  = 3,

  parameter [CMD_WIDTH-1:0] CMD_NOP         = 3'd0,
  parameter [CMD_WIDTH-1:0] CMD_FLUSH_ALL   = 3'd1,
  parameter [CMD_WIDTH-1:0] CMD_FLUSH_MATCH = 3'd2,
  parameter [CMD_WIDTH-1:0] CMD_PROBE       = 3'd3,
  parameter [CMD_WIDTH-1:0] CMD_PRELOAD     = 3'd4,

  parameter [RESP_FAULT_W-1:0] RESP_FAULT_NONE     = 3'd0,
  parameter [RESP_FAULT_W-1:0] RESP_FAULT_PERM     = 3'd1,
  parameter [RESP_FAULT_W-1:0] RESP_FAULT_INVALID  = 3'd2,
  parameter [RESP_FAULT_W-1:0] RESP_FAULT_UNMAPPED = 3'd3,
  parameter [RESP_FAULT_W-1:0] RESP_FAULT_BUS      = 3'd4
) (
  input  wire                    clk,
  input  wire                    rst_n,

  input  wire                    req_valid_i,
  output wire                    req_ready_o,
  input  wire [VA_WIDTH-1:0]     req_va_i,
  input  wire [FC_WIDTH-1:0]     req_fc_i,
  input  wire                    req_rw_i,
  input  wire                    req_fetch_i,

  output reg                     resp_valid_o,
  output reg  [PA_WIDTH-1:0]     resp_pa_o,
  output reg                     resp_hit_o,
  output reg                     resp_fault_o,
  output reg  [RESP_FAULT_W-1:0] resp_fault_code_o,
  output reg  [4:0]              resp_perm_fault_o,

  input  wire                    reg_wr_en_i,
  input  wire                    reg_rd_en_i,
  input  wire [3:0]              reg_addr_i,
  input  wire [31:0]             reg_wr_data_i,
  output wire [31:0]             reg_rd_data_o,

  input  wire                    cmd_valid_i,
  input  wire [CMD_WIDTH-1:0]    cmd_op_i,
  input  wire [VA_WIDTH-1:0]     cmd_addr_i,
  input  wire [FC_WIDTH-1:0]     cmd_fc_i,
  output wire                    cmd_ready_o,
  output wire                    cmd_busy_o,
  output wire                    status_valid_o,
  output wire [CMD_WIDTH-1:0]    status_cmd_o,
  output wire                    status_hit_o,
  output wire [PA_WIDTH-1:0]     status_pa_o,
  output wire [STATUS_WIDTH-1:0] status_bits_o,

  output wire                    walk_mem_req_valid_o,
  output wire [PA_WIDTH-1:0]     walk_mem_req_addr_o,
  input  wire                    walk_mem_resp_valid_i,
  input  wire [DESCR_WIDTH-1:0]  walk_mem_resp_data_i,
  input  wire                    walk_mem_resp_err_i,

  output wire                    busy_o
);

  localparam integer VPN_WIDTH = VA_WIDTH - PAGE_SHIFT;
  localparam integer TTR_KEY_WIDTH = (VA_WIDTH >= 8) ? 8 : VA_WIDTH;
  localparam integer STATUS_BIT_TT_MATCH = STATUS_WIDTH - 1;

  localparam [1:0] ST_IDLE       = 2'd0;
  localparam [1:0] ST_START_WALK = 2'd1;
  localparam [1:0] ST_WAIT_WALK  = 2'd2;

  localparam [1:0] WALK_FAULT_NONE     = 2'b00;
  localparam [1:0] WALK_FAULT_INVALID  = 2'b01;
  localparam [1:0] WALK_FAULT_UNMAPPED = 2'b10;
  localparam [1:0] WALK_FAULT_BUS      = 2'b11;

  reg [1:0]          state_q;
  reg                pending_is_cpu_q;
  reg [VA_WIDTH-1:0] pending_va_q;
  reg [FC_WIDTH-1:0] pending_fc_q;
  reg                pending_rw_q;
  reg                pending_fetch_q;

  reg                probe_pending_q;
  reg [VA_WIDTH-1:0] probe_addr_q;
  reg [FC_WIDTH-1:0] probe_fc_q;

  wire [PA_WIDTH-1:0] crp_q;
  wire [PA_WIDTH-1:0] srp_q;
  wire [31:0]         tc_q;
  wire [31:0]         tt0_q;
  wire [31:0]         tt1_q;
  wire [15:0]         mmusr_q;

  wire decode_is_user;
  wire decode_is_super;
  wire decode_is_program;
  wire decode_is_data;
  wire decode_cpu_space;
  wire decode_is_normal_mem;

  wire flush_all;
  wire flush_match;
  wire [VA_WIDTH-1:0] flush_addr;
  wire [FC_WIDTH-1:0] flush_fc;
  wire probe_req_valid;
  wire [VA_WIDTH-1:0] probe_req_addr;
  wire [FC_WIDTH-1:0] probe_req_fc;
  wire preload_req_valid;
  wire [VA_WIDTH-1:0] preload_req_addr;
  wire [FC_WIDTH-1:0] preload_req_fc;

  wire [VPN_WIDTH-1:0] table_entries_cfg;
  wire [STATUS_WIDTH-1:0] probe_status_bits;

  wire state_idle = (state_q == ST_IDLE);
  wire walker_start = (state_q == ST_START_WALK);

  wire preload_accept = state_idle && !req_valid_i && !probe_pending_q;

  wire lookup_src_cpu     = state_idle && req_valid_i;
  wire lookup_src_probe   = !lookup_src_cpu && probe_pending_q;
  wire lookup_src_preload = !lookup_src_cpu && !lookup_src_probe &&
                            preload_req_valid && preload_accept;

  wire lookup_valid = lookup_src_cpu || lookup_src_probe || lookup_src_preload;
  wire [VA_WIDTH-1:0] lookup_va = lookup_src_cpu     ? req_va_i :
                                  lookup_src_probe   ? probe_addr_q :
                                  lookup_src_preload ? preload_req_addr :
                                                       {VA_WIDTH{1'b0}};
  wire [FC_WIDTH-1:0] lookup_fc = lookup_src_cpu     ? req_fc_i :
                                  lookup_src_probe   ? probe_fc_q :
                                  lookup_src_preload ? preload_req_fc :
                                                       {FC_WIDTH{1'b0}};

  wire                  tlb_lookup_hit;
  wire                  tlb_lookup_miss;
  wire [PA_WIDTH-1:0]   tlb_lookup_pa;
  wire [ATTR_WIDTH-1:0] tlb_lookup_attr;

  wire                  walker_busy;
  wire                  walker_done;
  wire                  walker_refill_valid;
  wire [VA_WIDTH-1:0]   walker_refill_va;
  wire [PA_WIDTH-1:0]   walker_pa_base;
  wire [ATTR_WIDTH-1:0] walker_attr;
  wire                  walker_fault_valid;
  wire [1:0]            walker_fault_code;

  wire [2:0] hit_user_perm;
  wire [2:0] hit_super_perm;
  wire       hit_perm_allow;
  wire [4:0] hit_perm_fault;

  wire [2:0] walk_user_perm;
  wire [2:0] walk_super_perm;
  wire       walk_perm_allow;
  wire [4:0] walk_perm_fault;

  wire                tt0_match;
  wire                tt1_match;
  wire                tt_match_any;
  wire [PA_WIDTH-1:0] tt_lookup_pa;
  wire                tt_cpu_bypass;

  function automatic [2:0] user_perm_from_attr(
    input [ATTR_WIDTH-1:0] attr_i
  );
    begin
      user_perm_from_attr[2] = ~attr_i[4] | (attr_i[2] & ~attr_i[2]);
      user_perm_from_attr[1] = (~attr_i[4] & ~attr_i[3]) | (attr_i[1] & ~attr_i[1]);
      user_perm_from_attr[0] = ~attr_i[4] | (attr_i[0] & ~attr_i[0]);
    end
  endfunction

  function automatic [2:0] super_perm_from_attr(
    input [ATTR_WIDTH-1:0] attr_i
  );
    begin
      super_perm_from_attr[2] = 1'b1 | (attr_i[4] & ~attr_i[4]);
      super_perm_from_attr[1] = ~attr_i[3] | (attr_i[1] & ~attr_i[1]);
      super_perm_from_attr[0] = 1'b1 | (attr_i[0] & ~attr_i[0]) | (attr_i[2] & ~attr_i[2]);
    end
  endfunction

  function automatic [PA_WIDTH-1:0] va_to_pa(
    input [VA_WIDTH-1:0] va_i
  );
    integer idx;
    begin
      va_to_pa = {PA_WIDTH{1'b0}};
      for (idx = 0; idx < PA_WIDTH; idx = idx + 1) begin
        if (idx < VA_WIDTH) begin
          va_to_pa[idx] = va_i[idx];
        end
      end
    end
  endfunction

  // First-pass TT/TTR subset over the existing 32-bit TT0/TT1 register images:
  //   [31:24] logical-address high-byte base
  //   [23:16] logical-address high-byte mask (1 = don't care)
  //   [15]    entry enable
  //   [14]    match supervisor normal-memory accesses
  //   [13]    match user normal-memory accesses
  //   [12]    match program space
  //   [11]    match data space
  //
  // CPU/special space is explicitly excluded in this first pass even if the
  // region byte matches. A TT hit returns an identity-style PA and bypasses
  // descriptor translation plus permission checking for a valid request.
  /* verilator lint_off UNUSED */
  function automatic ttr_match(
    input [31:0]         ttr_i,
    input [VA_WIDTH-1:0] va_i,
    input                is_user_i,
    input                is_program_i,
    input                is_data_i,
    input                is_cpu_space_i
  );
    reg [TTR_KEY_WIDTH-1:0] va_key_v;
    reg [TTR_KEY_WIDTH-1:0] base_key_v;
    reg [TTR_KEY_WIDTH-1:0] mask_key_v;
    reg                     priv_match_v;
    reg                     space_match_v;
    reg                     compare_match_v;
    begin
      va_key_v        = va_i[VA_WIDTH-1 -: TTR_KEY_WIDTH];
      base_key_v      = ttr_i[31 -: TTR_KEY_WIDTH];
      mask_key_v      = ttr_i[23 -: TTR_KEY_WIDTH];
      priv_match_v    = (is_user_i && ttr_i[13]) || (!is_user_i && ttr_i[14]);
      space_match_v   = (is_program_i && ttr_i[12]) || (is_data_i && ttr_i[11]);
      compare_match_v = ((va_key_v & ~mask_key_v) == (base_key_v & ~mask_key_v));
      ttr_match = ttr_i[15] && !is_cpu_space_i && priv_match_v &&
                  space_match_v && compare_match_v;
    end
  endfunction
  /* verilator lint_on UNUSED */

  generate
    if (VPN_WIDTH <= 32) begin : gen_table_entries_narrow
      assign table_entries_cfg = tc_q[VPN_WIDTH-1:0];
    end else begin : gen_table_entries_wide
      assign table_entries_cfg = {{(VPN_WIDTH-32){1'b0}}, tc_q};
    end

    if (STATUS_WIDTH >= ATTR_WIDTH) begin : gen_probe_status_wide
      assign probe_status_bits = tt_match_any
                               ? ({STATUS_WIDTH{1'b0}} |
                                  ({{(STATUS_WIDTH-1){1'b0}}, 1'b1} << STATUS_BIT_TT_MATCH))
                               : {{(STATUS_WIDTH-ATTR_WIDTH){1'b0}}, tlb_lookup_attr};
    end else begin : gen_probe_status_narrow
      assign probe_status_bits = tt_match_any
                               ? ({STATUS_WIDTH{1'b0}} |
                                  ({{(STATUS_WIDTH-1){1'b0}}, 1'b1} << STATUS_BIT_TT_MATCH))
                               : tlb_lookup_attr[STATUS_WIDTH-1:0];
    end
  endgenerate

  assign req_ready_o = state_idle;
  assign busy_o      = !state_idle || walker_busy || cmd_busy_o;

  mmu_regs #(
    .VA_WIDTH(VA_WIDTH),
    .PA_WIDTH(PA_WIDTH)
  ) u_regs (
    .clk    (clk),
    .rst_n  (rst_n),
    .wr_en  (reg_wr_en_i),
    .rd_en  (reg_rd_en_i),
    .addr   (reg_addr_i),
    .wr_data(reg_wr_data_i),
    .rd_data(reg_rd_data_o),
    .crp    (crp_q),
    .srp    (srp_q),
    .tc     (tc_q),
    .tt0    (tt0_q),
    .tt1    (tt1_q),
    .mmusr  (mmusr_q)
  );

  mmu_decode u_decode (
    .fc        (lookup_fc),
    .is_user   (decode_is_user),
    .is_super  (decode_is_super),
    .is_program(decode_is_program),
    .is_data   (decode_is_data),
    .cpu_space (decode_cpu_space)
  );

  assign decode_is_normal_mem = decode_is_program | decode_is_data;
  assign tt0_match = lookup_valid &&
                     decode_is_normal_mem &&
                     ttr_match(tt0_q, lookup_va, decode_is_user,
                               decode_is_program, decode_is_data,
                               decode_cpu_space);
  assign tt1_match = lookup_valid &&
                     decode_is_normal_mem &&
                     ttr_match(tt1_q, lookup_va, decode_is_user,
                               decode_is_program, decode_is_data,
                               decode_cpu_space);
  assign tt_match_any  = tt0_match | tt1_match;
  assign tt_lookup_pa  = va_to_pa(lookup_va);
  assign tt_cpu_bypass = lookup_src_cpu && tt_match_any;

  perm_check u_hit_perm (
    .req_r    (lookup_src_cpu && !req_fetch_i && req_rw_i),
    .req_w    (lookup_src_cpu && !req_fetch_i && !req_rw_i),
    .req_x    (lookup_src_cpu && req_fetch_i),
    .is_user  (decode_is_user),
    .u_perm   (hit_user_perm),
    .s_perm   (hit_super_perm),
    .tt_bypass(tt_cpu_bypass),
    .allow    (hit_perm_allow),
    .fault    (hit_perm_fault)
  );

  perm_check u_walk_perm (
    .req_r    (pending_is_cpu_q && !pending_fetch_q && pending_rw_q),
    .req_w    (pending_is_cpu_q && !pending_fetch_q && !pending_rw_q),
    .req_x    (pending_is_cpu_q && pending_fetch_q),
    .is_user  (pending_fc_q[FC_WIDTH-1] ? 1'b0 : 1'b1),
    .u_perm   (walk_user_perm),
    .s_perm   (walk_super_perm),
    .tt_bypass(1'b0),
    .allow    (walk_perm_allow),
    .fault    (walk_perm_fault)
  );

  tlb_dm #(
    .VA_WIDTH   (VA_WIDTH),
    .PA_WIDTH   (PA_WIDTH),
    .PAGE_SHIFT (PAGE_SHIFT),
    .ENTRIES    (TLB_ENTRIES),
    .FC_WIDTH   (FC_WIDTH),
    .ATTR_WIDTH (ATTR_WIDTH)
  ) u_tlb (
    .clk               (clk),
    .rst_n             (rst_n),
    .lookup_valid_i    (lookup_valid),
    .lookup_va_i       (lookup_va),
    .lookup_fc_i       (lookup_fc),
    .lookup_hit_o      (tlb_lookup_hit),
    .lookup_miss_o     (tlb_lookup_miss),
    .lookup_pa_o       (tlb_lookup_pa),
    .lookup_attr_o     (tlb_lookup_attr),
    .refill_valid_i    (walker_refill_valid),
    .refill_va_i       (walker_refill_va),
    .refill_pa_i       (walker_pa_base),
    .refill_fc_i       (pending_fc_q),
    .refill_attr_i     (walker_attr),
    .invalidate_all_i  (flush_all),
    .invalidate_match_i(flush_match),
    .invalidate_va_i   (flush_addr),
    .invalidate_fc_i   (flush_fc)
  );

  pt_walker #(
    .VA_WIDTH    (VA_WIDTH),
    .PA_WIDTH    (PA_WIDTH),
    .PAGE_SHIFT  (PAGE_SHIFT),
    .DESCR_WIDTH (DESCR_WIDTH),
    .FC_WIDTH    (FC_WIDTH),
    .ATTR_WIDTH  (ATTR_WIDTH)
  ) u_walker (
    .clk             (clk),
    .rst_n           (rst_n),
    .start_i         (walker_start),
    .va_i            (pending_va_q),
    .fc_i            (pending_fc_q),
    .table_base_i    (crp_q),
    .table_entries_i (table_entries_cfg),
    .mem_req_valid_o (walk_mem_req_valid_o),
    .mem_req_addr_o  (walk_mem_req_addr_o),
    .mem_resp_valid_i(walk_mem_resp_valid_i),
    .mem_resp_data_i (walk_mem_resp_data_i),
    .mem_resp_err_i  (walk_mem_resp_err_i),
    .busy_o          (walker_busy),
    .done_o          (walker_done),
    .refill_valid_o  (walker_refill_valid),
    .refill_va_o     (walker_refill_va),
    .walk_pa_base_o  (walker_pa_base),
    /* verilator lint_off PINCONNECTEMPTY */
    .walk_ppn_o      (),
    /* verilator lint_on PINCONNECTEMPTY */
    .walk_attr_o     (walker_attr),
    .fault_valid_o   (walker_fault_valid),
    .fault_code_o    (walker_fault_code)
  );

  flush_ctrl #(
    .VA_WIDTH      (VA_WIDTH),
    .PA_WIDTH      (PA_WIDTH),
    .FC_WIDTH      (FC_WIDTH),
    .STATUS_WIDTH  (STATUS_WIDTH),
    .CMD_WIDTH     (CMD_WIDTH),
    .CMD_NOP       (CMD_NOP),
    .CMD_FLUSH_ALL (CMD_FLUSH_ALL),
    .CMD_FLUSH_MATCH(CMD_FLUSH_MATCH),
    .CMD_PROBE     (CMD_PROBE),
    .CMD_PRELOAD   (CMD_PRELOAD)
  ) u_flush_ctrl (
    .clk                (clk),
    .rst_n              (rst_n),
    .cmd_valid_i        (cmd_valid_i),
    .cmd_op_i           (cmd_op_i),
    .cmd_addr_i         (cmd_addr_i),
    .cmd_fc_i           (cmd_fc_i),
    .cmd_ready_o        (cmd_ready_o),
    .busy_o             (cmd_busy_o),
    .flush_all_o        (flush_all),
    .flush_match_o      (flush_match),
    .flush_addr_o       (flush_addr),
    .flush_fc_o         (flush_fc),
    .probe_req_valid_o  (probe_req_valid),
    .probe_addr_o       (probe_req_addr),
    .probe_fc_o         (probe_req_fc),
    .probe_resp_valid_i (probe_pending_q),
    .probe_resp_hit_i   (tlb_lookup_hit),
    .probe_resp_pa_i    (tlb_lookup_pa),
    .probe_resp_status_i(probe_status_bits),
    .preload_req_valid_o(preload_req_valid),
    .preload_addr_o     (preload_req_addr),
    .preload_fc_o       (preload_req_fc),
    .preload_req_ready_i(preload_accept),
    .status_valid_o     (status_valid_o),
    .status_cmd_o       (status_cmd_o),
    .status_hit_o       (status_hit_o),
    .status_pa_o        (status_pa_o),
    .status_bits_o      (status_bits_o)
  );

  assign hit_user_perm  = user_perm_from_attr(tlb_lookup_attr);
  assign hit_super_perm = super_perm_from_attr(tlb_lookup_attr);
  assign walk_user_perm = user_perm_from_attr(walker_attr);
  assign walk_super_perm = super_perm_from_attr(walker_attr);

  /* verilator lint_off UNUSED */
  wire unused_regs_decode = ^srp_q ^ ^tc_q ^ ^mmusr_q ^ decode_is_super;
  wire unused_cmd_value = ^CMD_NOP;
  /* verilator lint_on UNUSED */

  always @(posedge clk) begin
    if (!rst_n) begin
      state_q             <= ST_IDLE;
      pending_is_cpu_q    <= 1'b0;
      pending_va_q        <= {VA_WIDTH{1'b0}};
      pending_fc_q        <= {FC_WIDTH{1'b0}};
      pending_rw_q        <= 1'b0;
      pending_fetch_q     <= 1'b0;
      probe_pending_q     <= 1'b0;
      probe_addr_q        <= {VA_WIDTH{1'b0}};
      probe_fc_q          <= {FC_WIDTH{1'b0}};
      resp_valid_o        <= 1'b0;
      resp_pa_o           <= {PA_WIDTH{1'b0}};
      resp_hit_o          <= 1'b0;
      resp_fault_o        <= 1'b0;
      resp_fault_code_o   <= RESP_FAULT_NONE;
      resp_perm_fault_o   <= 5'b0;
    end else begin
      resp_valid_o      <= 1'b0;
      resp_hit_o        <= 1'b0;
      resp_fault_o      <= 1'b0;
      resp_fault_code_o <= RESP_FAULT_NONE;
      resp_perm_fault_o <= 5'b0;

      if (probe_pending_q) begin
        probe_pending_q <= 1'b0;
      end

      if (probe_req_valid) begin
        probe_pending_q <= 1'b1;
        probe_addr_q    <= probe_req_addr;
        probe_fc_q      <= probe_req_fc;
      end

      case (state_q)
        ST_IDLE: begin
          if (lookup_src_cpu) begin
            if (tt_match_any) begin
              resp_valid_o <= 1'b1;
              resp_pa_o    <= tt_lookup_pa;
            end else if (tlb_lookup_hit) begin
              resp_valid_o <= 1'b1;
              resp_pa_o    <= tlb_lookup_pa;
              resp_hit_o   <= 1'b1;
              if (!hit_perm_allow) begin
                resp_fault_o        <= 1'b1;
                resp_fault_code_o   <= RESP_FAULT_PERM;
                resp_perm_fault_o   <= hit_perm_fault;
              end
            end else if (tlb_lookup_miss) begin
              pending_is_cpu_q <= 1'b1;
              pending_va_q     <= req_va_i;
              pending_fc_q     <= req_fc_i;
              pending_rw_q     <= req_rw_i;
              pending_fetch_q  <= req_fetch_i;
              state_q          <= ST_START_WALK;
            end
          end else if (lookup_src_preload) begin
            if (tlb_lookup_miss) begin
              pending_is_cpu_q <= 1'b0;
              pending_va_q     <= preload_req_addr;
              pending_fc_q     <= preload_req_fc;
              pending_rw_q     <= 1'b1;
              pending_fetch_q  <= 1'b0;
              state_q          <= ST_START_WALK;
            end
          end
        end

        ST_START_WALK: begin
          state_q <= ST_WAIT_WALK;
        end

        ST_WAIT_WALK: begin
          if (walker_done) begin
            state_q <= ST_IDLE;
            if (pending_is_cpu_q) begin
              resp_valid_o <= 1'b1;
              resp_pa_o    <= walker_pa_base |
                              {{(PA_WIDTH-PAGE_SHIFT){1'b0}}, pending_va_q[PAGE_SHIFT-1:0]};
              if (walker_fault_valid) begin
                resp_fault_o <= 1'b1;
                case (walker_fault_code)
                  WALK_FAULT_INVALID:  resp_fault_code_o <= RESP_FAULT_INVALID;
                  WALK_FAULT_UNMAPPED: resp_fault_code_o <= RESP_FAULT_UNMAPPED;
                  WALK_FAULT_BUS:      resp_fault_code_o <= RESP_FAULT_BUS;
                  default:             resp_fault_code_o <= RESP_FAULT_NONE;
                endcase
              end else if (!walk_perm_allow) begin
                resp_fault_o      <= 1'b1;
                resp_fault_code_o <= RESP_FAULT_PERM;
                resp_perm_fault_o <= walk_perm_fault;
              end
            end
          end
        end

        default: begin
          state_q <= ST_IDLE;
        end
      endcase
    end
  end

endmodule
`default_nettype wire
