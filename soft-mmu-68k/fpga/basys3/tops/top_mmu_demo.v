`timescale 1ns/1ps
`default_nettype none
// -----------------------------------------------------------------------------
// Basys 3 first-pass MMU smoke demo.
//
// Intent:
//   - Keep the front panel small: switches choose a canned VA/control subset.
//   - Self-configure the current mmu_top register interface after reset.
//   - Use a tiny built-in descriptor responder instead of a full bus/system.
//   - Auto-run a short demo sequence after the switches settle.
//
// Limits:
//   - This is not a bus-accurate SoC integration.
//   - Only a few canned VPN cases are modeled in the descriptor responder.
//   - LEDs show a compact status/result view rather than a full trace.
// -----------------------------------------------------------------------------

module top_mmu_demo (
  input  wire        clk,
  input  wire        btnC,
  input  wire [15:0] sw,
  output wire [15:0] led
);

  localparam integer VA_WIDTH       = 24;
  localparam integer PA_WIDTH       = 24;
  localparam integer PAGE_SHIFT     = 12;
  localparam integer FC_WIDTH       = 3;
  localparam integer STATUS_WIDTH   = 8;
  localparam integer CMD_WIDTH      = 3;
  localparam integer RESP_FAULT_W   = 3;
  localparam integer SETTLE_BITS    = 20;

  localparam [3:0] REG_CRP          = 4'h0;
  localparam [3:0] REG_TC           = 4'h2;
  localparam [3:0] REG_TT0          = 4'h3;
  localparam [3:0] REG_TT1          = 4'h4;

  localparam [CMD_WIDTH-1:0] CMD_FLUSH_ALL   = 3'd1;
  localparam [CMD_WIDTH-1:0] CMD_FLUSH_MATCH = 3'd2;
  localparam [CMD_WIDTH-1:0] CMD_PROBE       = 3'd3;
  localparam [CMD_WIDTH-1:0] CMD_PRELOAD     = 3'd4;

  localparam [1:0] MODE_ACCESS      = 2'b00;
  localparam [1:0] MODE_PROBE       = 2'b01;
  localparam [1:0] MODE_PRELOAD     = 2'b10;
  localparam [1:0] MODE_FLUSH_MATCH = 2'b11;

  localparam [PA_WIDTH-1:0] TABLE_BASE_ADDR  = 24'h001000;
  localparam [31:0]         TC_DEMO_VALUE    = 32'h00000FFF;
  localparam [31:0]         TT0_DEMO_VALUE   = 32'hF000F800;
  localparam [31:0]         TT1_DEMO_VALUE   = 32'h00000000;

  localparam [5:0] CFG_IDLE         = 6'd0;
  localparam [5:0] CFG_WRITE_CRP    = 6'd1;
  localparam [5:0] CFG_WRITE_TC     = 6'd2;
  localparam [5:0] CFG_WRITE_TT0    = 6'd3;
  localparam [5:0] CFG_WRITE_TT1    = 6'd4;
  localparam [5:0] CFG_DONE         = 6'd5;

  localparam [5:0] SEQ_IDLE         = 6'd0;
  localparam [5:0] SEQ_FLUSH_ALL    = 6'd1;
  localparam [5:0] SEQ_FLUSH_MATCH  = 6'd2;
  localparam [5:0] SEQ_WAIT_CMD     = 6'd3;
  localparam [5:0] SEQ_REQ1         = 6'd4;
  localparam [5:0] SEQ_WAIT_REQ1    = 6'd5;
  localparam [5:0] SEQ_REQ2         = 6'd6;
  localparam [5:0] SEQ_WAIT_REQ2    = 6'd7;
  localparam [5:0] SEQ_PRELOAD      = 6'd8;
  localparam [5:0] SEQ_WAIT_PRELOAD = 6'd9;
  localparam [5:0] SEQ_PROBE        = 6'd10;
  localparam [5:0] SEQ_WAIT_PROBE   = 6'd11;

  localparam [1:0] DESC_DT_PAGE     = 2'b10;

  wire rst_n = ~btnC;

  reg  [5:0]              cfg_state_q;
  reg  [5:0]              seq_state_q;
  reg  [15:0]             sw_shadow_q;
  reg  [SETTLE_BITS-1:0]  settle_ctr_q;
  reg                     rerun_pending_q;

  reg                     reg_wr_en_q;
  reg  [3:0]              reg_addr_q;
  reg  [31:0]             reg_wr_data_q;

  reg                     cmd_valid_q;
  reg  [CMD_WIDTH-1:0]    cmd_op_q;
  reg  [VA_WIDTH-1:0]     cmd_addr_q;
  reg  [FC_WIDTH-1:0]     cmd_fc_q;

  reg                     req_valid_q;
  reg  [VA_WIDTH-1:0]     req_va_q;
  reg  [FC_WIDTH-1:0]     req_fc_q;
  reg                     req_rw_q;
  reg                     req_fetch_q;

  reg                     walk_resp_valid_q;
  reg  [31:0]             walk_resp_data_q;
  reg                     walk_resp_err_q;
  reg                     walk_pending_q;
  reg  [PA_WIDTH-1:0]     walk_req_addr_q;

  reg  [PA_WIDTH-1:0]     last_display_pa_q;
  reg                     last_resp_fault_q;
  reg                     last_resp_hit_q;
  reg  [RESP_FAULT_W-1:0] last_resp_fault_code_q;
  reg                     last_status_hit_q;
  reg                     last_status_translated_q;
  reg                     last_status_tt_q;

  wire                    req_ready;
  wire                    resp_valid;
  wire [PA_WIDTH-1:0]     resp_pa;
  wire                    resp_hit;
  wire                    resp_fault;
  wire [RESP_FAULT_W-1:0] resp_fault_code;

  wire                    cmd_ready;
  wire                    cmd_busy;
  wire                    status_valid;
  wire                    status_hit;
  wire [PA_WIDTH-1:0]     status_pa;
  wire [STATUS_WIDTH-1:0] status_bits;

  wire                    walk_mem_req_valid;
  wire [PA_WIDTH-1:0]     walk_mem_req_addr;
  wire                    mmu_busy;

  wire [1:0]              demo_mode = sw_shadow_q[14:13];
  wire                    demo_tt_region = sw_shadow_q[15];
  wire                    demo_supervisor = sw_shadow_q[12];
  wire                    demo_program = sw_shadow_q[11];
  wire                    demo_write = sw_shadow_q[10];
  wire [1:0]              demo_page = sw_shadow_q[9:8];
  wire [11:0]             demo_offset = {sw_shadow_q[7:0], 4'h0};

  wire [7:0]              demo_region = demo_tt_region ? 8'hF0 : 8'h00;
  wire [VA_WIDTH-1:0]     demo_va = {demo_region, 2'b00, demo_page, demo_offset};
  wire [FC_WIDTH-1:0]     demo_fc = demo_supervisor
                                  ? (demo_program ? 3'b110 : 3'b101)
                                  : (demo_program ? 3'b010 : 3'b001);
  wire                    demo_req_rw = ~demo_write;

  wire                    settle_done = &settle_ctr_q;
  wire                    cfg_done = (cfg_state_q == CFG_DONE);
  wire                    seq_idle = (seq_state_q == SEQ_IDLE);

  wire [STATUS_WIDTH-1:0] status_tt_mask = {{(STATUS_WIDTH-1){1'b0}}, 1'b1} << (STATUS_WIDTH-1);
  wire [STATUS_WIDTH-1:0] status_translated_mask = {{(STATUS_WIDTH-1){1'b0}}, 1'b1} << (STATUS_WIDTH-2);

  wire [PA_WIDTH-1:0] walk_index_addr = (walk_req_addr_q - TABLE_BASE_ADDR) >> 2;
  wire [PA_WIDTH-PAGE_SHIFT-1:0] walk_index_word =
    walk_index_addr[PA_WIDTH-PAGE_SHIFT-1:0];

  function automatic [31:0] make_page_desc(
    input                   valid_i,
    input                   super_only_i,
    input                   write_protect_i,
    input [PA_WIDTH-PAGE_SHIFT-1:0] pfn_i
  );
    begin
      make_page_desc = 32'h00000000;
      make_page_desc[31:30] = DESC_DT_PAGE;
      make_page_desc[29]    = valid_i;
      make_page_desc[28]    = super_only_i;
      make_page_desc[27]    = write_protect_i;
      make_page_desc[23:12] = pfn_i[11:0];
    end
  endfunction

  mmu_top u_mmu_top (
    .clk                 (clk),
    .rst_n               (rst_n),
    .req_valid_i         (req_valid_q),
    .req_ready_o         (req_ready),
    .req_va_i            (req_va_q),
    .req_fc_i            (req_fc_q),
    .req_rw_i            (req_rw_q),
    .req_fetch_i         (req_fetch_q),
    .resp_valid_o        (resp_valid),
    .resp_pa_o           (resp_pa),
    .resp_hit_o          (resp_hit),
    .resp_fault_o        (resp_fault),
    .resp_fault_code_o   (resp_fault_code),
    .resp_perm_fault_o   (),
    .reg_wr_en_i         (reg_wr_en_q),
    .reg_rd_en_i         (1'b0),
    .reg_addr_i          (reg_addr_q),
    .reg_wr_data_i       (reg_wr_data_q),
    .reg_rd_data_o       (),
    .cmd_valid_i         (cmd_valid_q),
    .cmd_op_i            (cmd_op_q),
    .cmd_addr_i          (cmd_addr_q),
    .cmd_fc_i            (cmd_fc_q),
    .cmd_ready_o         (cmd_ready),
    .cmd_busy_o          (cmd_busy),
    .status_valid_o      (status_valid),
    .status_cmd_o        (),
    .status_hit_o        (status_hit),
    .status_pa_o         (status_pa),
    .status_bits_o       (status_bits),
    .walk_mem_req_valid_o(walk_mem_req_valid),
    .walk_mem_req_addr_o (walk_mem_req_addr),
    .walk_mem_resp_valid_i(walk_resp_valid_q),
    .walk_mem_resp_data_i(walk_resp_data_q),
    .walk_mem_resp_err_i (walk_resp_err_q),
    .busy_o              (mmu_busy)
  );

  assign led[0]    = mmu_busy;
  assign led[1]    = last_resp_fault_q;
  assign led[2]    = last_resp_hit_q;
  assign led[3]    = last_status_hit_q;
  assign led[4]    = last_status_translated_q;
  assign led[5]    = last_status_tt_q;
  assign led[8:6]  = last_resp_fault_code_q;
  assign led[15:9] = last_display_pa_q[18:12];

  always @(posedge clk) begin
    if (!rst_n) begin
      cfg_state_q               <= CFG_IDLE;
      seq_state_q               <= SEQ_IDLE;
      sw_shadow_q               <= 16'h0000;
      settle_ctr_q              <= {SETTLE_BITS{1'b0}};
      rerun_pending_q           <= 1'b1;
      reg_wr_en_q               <= 1'b0;
      reg_addr_q                <= 4'h0;
      reg_wr_data_q             <= 32'h00000000;
      cmd_valid_q               <= 1'b0;
      cmd_op_q                  <= {CMD_WIDTH{1'b0}};
      cmd_addr_q                <= {VA_WIDTH{1'b0}};
      cmd_fc_q                  <= {FC_WIDTH{1'b0}};
      req_valid_q               <= 1'b0;
      req_va_q                  <= {VA_WIDTH{1'b0}};
      req_fc_q                  <= {FC_WIDTH{1'b0}};
      req_rw_q                  <= 1'b1;
      req_fetch_q               <= 1'b0;
      walk_resp_valid_q         <= 1'b0;
      walk_resp_data_q          <= 32'h00000000;
      walk_resp_err_q           <= 1'b0;
      walk_pending_q            <= 1'b0;
      walk_req_addr_q           <= {PA_WIDTH{1'b0}};
      last_display_pa_q         <= {PA_WIDTH{1'b0}};
      last_resp_fault_q         <= 1'b0;
      last_resp_hit_q           <= 1'b0;
      last_resp_fault_code_q    <= {RESP_FAULT_W{1'b0}};
      last_status_hit_q         <= 1'b0;
      last_status_translated_q  <= 1'b0;
      last_status_tt_q          <= 1'b0;
    end else begin
      reg_wr_en_q       <= 1'b0;
      cmd_valid_q       <= 1'b0;
      req_valid_q       <= 1'b0;
      walk_resp_valid_q <= 1'b0;
      walk_resp_err_q   <= 1'b0;

      if (sw != sw_shadow_q) begin
        sw_shadow_q     <= sw;
        settle_ctr_q    <= {SETTLE_BITS{1'b0}};
        rerun_pending_q <= 1'b1;
      end else if (rerun_pending_q && !settle_done) begin
        settle_ctr_q <= settle_ctr_q + {{(SETTLE_BITS-1){1'b0}}, 1'b1};
      end

      if (walk_pending_q) begin
        walk_pending_q    <= 1'b0;
        walk_resp_valid_q <= 1'b1;

        case (walk_index_word[1:0])
          2'd0: begin
            walk_resp_data_q <= make_page_desc(1'b1, 1'b0, 1'b0, 12'h040);
          end
          2'd1: begin
            walk_resp_data_q <= make_page_desc(1'b1, 1'b1, 1'b0, 12'h041);
          end
          2'd2: begin
            walk_resp_data_q <= make_page_desc(1'b0, 1'b0, 1'b0, 12'h042);
          end
          default: begin
            walk_resp_data_q <= 32'h00000000;
          end
        endcase

        if (walk_index_word[1:0] == 2'd3) begin
          walk_resp_err_q <= 1'b1;
        end
      end

      if (walk_mem_req_valid) begin
        walk_pending_q  <= 1'b1;
        walk_req_addr_q <= walk_mem_req_addr;
      end

      if (resp_valid) begin
        last_display_pa_q      <= resp_pa;
        last_resp_fault_q      <= resp_fault;
        last_resp_hit_q        <= resp_hit;
        last_resp_fault_code_q <= resp_fault_code;
      end

      if (status_valid) begin
        last_display_pa_q        <= status_pa;
        last_status_hit_q        <= status_hit;
        last_status_translated_q <= |(status_bits & status_translated_mask);
        last_status_tt_q         <= |(status_bits & status_tt_mask);
      end

      case (cfg_state_q)
        CFG_IDLE: begin
          cfg_state_q <= CFG_WRITE_CRP;
        end

        CFG_WRITE_CRP: begin
          reg_wr_en_q   <= 1'b1;
          reg_addr_q    <= REG_CRP;
          reg_wr_data_q <= {{(32-PA_WIDTH){1'b0}}, TABLE_BASE_ADDR};
          cfg_state_q   <= CFG_WRITE_TC;
        end

        CFG_WRITE_TC: begin
          reg_wr_en_q   <= 1'b1;
          reg_addr_q    <= REG_TC;
          reg_wr_data_q <= TC_DEMO_VALUE;
          cfg_state_q   <= CFG_WRITE_TT0;
        end

        CFG_WRITE_TT0: begin
          reg_wr_en_q   <= 1'b1;
          reg_addr_q    <= REG_TT0;
          reg_wr_data_q <= TT0_DEMO_VALUE;
          cfg_state_q   <= CFG_WRITE_TT1;
        end

        CFG_WRITE_TT1: begin
          reg_wr_en_q   <= 1'b1;
          reg_addr_q    <= REG_TT1;
          reg_wr_data_q <= TT1_DEMO_VALUE;
          cfg_state_q   <= CFG_DONE;
        end

        default: begin
          cfg_state_q <= CFG_DONE;
        end
      endcase

      case (seq_state_q)
        SEQ_IDLE: begin
          if (cfg_done && rerun_pending_q && settle_done) begin
            rerun_pending_q          <= 1'b0;
            last_resp_fault_q        <= 1'b0;
            last_resp_hit_q          <= 1'b0;
            last_resp_fault_code_q   <= {RESP_FAULT_W{1'b0}};
            last_status_hit_q        <= 1'b0;
            last_status_translated_q <= 1'b0;
            last_status_tt_q         <= 1'b0;
            last_display_pa_q        <= {PA_WIDTH{1'b0}};

            if (demo_mode == MODE_FLUSH_MATCH) begin
              seq_state_q <= SEQ_FLUSH_MATCH;
            end else begin
              seq_state_q <= SEQ_FLUSH_ALL;
            end
          end
        end

        SEQ_FLUSH_ALL: begin
          if (cmd_ready) begin
            cmd_valid_q <= 1'b1;
            cmd_op_q    <= CMD_FLUSH_ALL;
            cmd_addr_q  <= {VA_WIDTH{1'b0}};
            cmd_fc_q    <= {FC_WIDTH{1'b0}};
            seq_state_q <= SEQ_WAIT_CMD;
          end
        end

        SEQ_FLUSH_MATCH: begin
          if (cmd_ready) begin
            cmd_valid_q <= 1'b1;
            cmd_op_q    <= CMD_FLUSH_MATCH;
            cmd_addr_q  <= demo_va;
            cmd_fc_q    <= demo_fc;
            seq_state_q <= SEQ_WAIT_CMD;
          end
        end

        SEQ_WAIT_CMD: begin
          if (!cmd_busy) begin
            case (demo_mode)
              MODE_PROBE: begin
                seq_state_q <= SEQ_PROBE;
              end
              MODE_PRELOAD: begin
                seq_state_q <= SEQ_PRELOAD;
              end
              default: begin
                seq_state_q <= SEQ_REQ1;
              end
            endcase
          end
        end

        SEQ_PRELOAD: begin
          if (cmd_ready) begin
            cmd_valid_q <= 1'b1;
            cmd_op_q    <= CMD_PRELOAD;
            cmd_addr_q  <= demo_va;
            cmd_fc_q    <= demo_fc;
            seq_state_q <= SEQ_WAIT_PRELOAD;
          end
        end

        SEQ_WAIT_PRELOAD: begin
          if (!cmd_busy) begin
            seq_state_q <= SEQ_REQ1;
          end
        end

        SEQ_REQ1: begin
          if (req_ready) begin
            req_valid_q <= 1'b1;
            req_va_q    <= demo_va;
            req_fc_q    <= demo_fc;
            req_rw_q    <= demo_req_rw;
            req_fetch_q <= demo_program;
            seq_state_q <= SEQ_WAIT_REQ1;
          end
        end

        SEQ_WAIT_REQ1: begin
          if (resp_valid) begin
            if (demo_mode == MODE_ACCESS) begin
              seq_state_q <= SEQ_REQ2;
            end else begin
              seq_state_q <= SEQ_PROBE;
            end
          end
        end

        SEQ_REQ2: begin
          if (req_ready) begin
            req_valid_q <= 1'b1;
            req_va_q    <= demo_va;
            req_fc_q    <= demo_fc;
            req_rw_q    <= demo_req_rw;
            req_fetch_q <= demo_program;
            seq_state_q <= SEQ_WAIT_REQ2;
          end
        end

        SEQ_WAIT_REQ2: begin
          if (resp_valid) begin
            seq_state_q <= SEQ_PROBE;
          end
        end

        SEQ_PROBE: begin
          if (cmd_ready) begin
            cmd_valid_q <= 1'b1;
            cmd_op_q    <= CMD_PROBE;
            cmd_addr_q  <= demo_va;
            cmd_fc_q    <= demo_fc;
            seq_state_q <= SEQ_WAIT_PROBE;
          end
        end

        SEQ_WAIT_PROBE: begin
          if (status_valid) begin
            seq_state_q <= SEQ_IDLE;
          end
        end

        default: begin
          seq_state_q <= SEQ_IDLE;
        end
      endcase
    end
  end

endmodule
`default_nettype wire
