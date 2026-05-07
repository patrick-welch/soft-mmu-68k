`timescale 1ns/1ps
`default_nettype none

module descriptor_pack_tb;

  localparam int DESCR_WIDTH = 64;
  localparam int PA_WIDTH    = 32;
  localparam int LIMIT_WIDTH = 15;
  localparam int PAGE_SHIFT  = 12;

  localparam logic [1:0] KIND_ROOT = 2'd0;
  localparam logic [1:0] KIND_PTR  = 2'd1;
  localparam logic [1:0] KIND_PAGE = 2'd2;

  // Motorola-aligned long-format subset used by descriptor_pack defaults:
  //   - Root/pointer: [63]=L/U, [62:48]=LIMIT, [33:32]=DT, [31:4]=ADDR[31:4]
  //   - Page       : [40]=S, [38]=CI, [36]=M, [35]=U, [34]=WP,
  //                  [33:32]=DT, [31:8]=PA[31:8]
  //
  // Compliance references:
  //   - MC68851 PMMU User's Manual, Sections 5.1.5.3 and 6.1.1
  //   - MC68030 User's Manual, Sections 9.5.1.1-9.5.1.8

  logic [1:0] kind;

  logic        r_v_i, r_i_i;
  logic [1:0]  r_dt_i;
  logic [LIMIT_WIDTH-1:0] r_limit_i;
  logic [PA_WIDTH-1:0]    r_addr_i;

  logic        p_v_i, p_i_i;
  logic [1:0]  p_dt_i;
  logic [LIMIT_WIDTH-1:0] p_limit_i;
  logic [PA_WIDTH-1:0]    p_addr_i;

  logic        pg_v_i;
  logic [1:0]  pg_dt_i;
  logic        pg_s_i, pg_wp_i, pg_ci_i, pg_m_i, pg_u_i;
  logic [PA_WIDTH-1:0]    pg_pa_i;

  logic [DESCR_WIDTH-1:0] packed_from_fields;
  logic [DESCR_WIDTH-1:0] packed_to_fields;

  logic        r_v_o, r_i_o;
  logic [1:0]  r_dt_o;
  logic [LIMIT_WIDTH-1:0] r_limit_o;
  logic [PA_WIDTH-1:0]    r_addr_o;

  logic        p_v_o, p_i_o;
  logic [1:0]  p_dt_o;
  logic [LIMIT_WIDTH-1:0] p_limit_o;
  logic [PA_WIDTH-1:0]    p_addr_o;

  logic        pg_v_o;
  logic [1:0]  pg_dt_o;
  logic        pg_s_o, pg_wp_o, pg_ci_o, pg_m_o, pg_u_o;
  logic [PA_WIDTH-1:0]    pg_pa_o;

  descriptor_pack #(
    .DESCR_WIDTH (DESCR_WIDTH),
    .PA_WIDTH    (PA_WIDTH),
    .LIMIT_WIDTH (LIMIT_WIDTH),
    .PAGE_SHIFT  (PAGE_SHIFT)
  ) dut (
    .kind_i   (kind),

    .r_v_i    (r_v_i),
    .r_i_i    (r_i_i),
    .r_dt_i   (r_dt_i),
    .r_limit_i(r_limit_i),
    .r_addr_i (r_addr_i),

    .p_v_i    (p_v_i),
    .p_i_i    (p_i_i),
    .p_dt_i   (p_dt_i),
    .p_limit_i(p_limit_i),
    .p_addr_i (p_addr_i),

    .pg_v_i   (pg_v_i),
    .pg_dt_i  (pg_dt_i),
    .pg_s_i   (pg_s_i),
    .pg_wp_i  (pg_wp_i),
    .pg_ci_i  (pg_ci_i),
    .pg_m_i   (pg_m_i),
    .pg_u_i   (pg_u_i),
    .pg_pa_i  (pg_pa_i),

    .packed_o (packed_from_fields),
    .packed_i (packed_to_fields),

    .r_v_o    (r_v_o),
    .r_i_o    (r_i_o),
    .r_dt_o   (r_dt_o),
    .r_limit_o(r_limit_o),
    .r_addr_o (r_addr_o),

    .p_v_o    (p_v_o),
    .p_i_o    (p_i_o),
    .p_dt_o   (p_dt_o),
    .p_limit_o(p_limit_o),
    .p_addr_o (p_addr_o),

    .pg_v_o   (pg_v_o),
    .pg_dt_o  (pg_dt_o),
    .pg_s_o   (pg_s_o),
    .pg_wp_o  (pg_wp_o),
    .pg_ci_o  (pg_ci_o),
    .pg_m_o   (pg_m_o),
    .pg_u_o   (pg_u_o),
    .pg_pa_o  (pg_pa_o)
  );

  task automatic clear_inputs;
    begin
      kind       = KIND_ROOT;
      r_v_i      = 1'b0;
      r_i_i      = 1'b0;
      r_dt_i     = 2'b00;
      r_limit_i  = '0;
      r_addr_i   = '0;
      p_v_i      = 1'b0;
      p_i_i      = 1'b0;
      p_dt_i     = 2'b00;
      p_limit_i  = '0;
      p_addr_i   = '0;
      pg_v_i     = 1'b0;
      pg_dt_i    = 2'b00;
      pg_s_i     = 1'b0;
      pg_wp_i    = 1'b0;
      pg_ci_i    = 1'b0;
      pg_m_i     = 1'b0;
      pg_u_i     = 1'b0;
      pg_pa_i    = '0;
      packed_to_fields = '0;
    end
  endtask

  task automatic expect_packed(
    input logic [DESCR_WIDTH-1:0] expected,
    input string name
  );
    begin
      #1;
      assert (packed_from_fields === expected)
        else $fatal(1, "%s pack mismatch: expected %h got %h", name, expected, packed_from_fields);
    end
  endtask

  task automatic expect_root_decode(
    input logic        exp_v,
    input logic        exp_lu,
    input logic [1:0]  exp_dt,
    input logic [LIMIT_WIDTH-1:0] exp_limit,
    input logic [PA_WIDTH-1:0]    exp_addr,
    input string name
  );
    begin
      #1;
      assert (r_v_o     === exp_v)     else $fatal(1, "%s root valid mismatch", name);
      assert (r_i_o     === exp_lu)    else $fatal(1, "%s root L/U mismatch", name);
      assert (r_dt_o    === exp_dt)    else $fatal(1, "%s root DT mismatch", name);
      assert (r_limit_o === exp_limit) else $fatal(1, "%s root LIMIT mismatch", name);
      assert (r_addr_o  === exp_addr)  else $fatal(1, "%s root ADDR mismatch", name);
    end
  endtask

  task automatic expect_ptr_decode(
    input logic        exp_v,
    input logic        exp_lu,
    input logic [1:0]  exp_dt,
    input logic [LIMIT_WIDTH-1:0] exp_limit,
    input logic [PA_WIDTH-1:0]    exp_addr,
    input string name
  );
    begin
      #1;
      assert (p_v_o     === exp_v)     else $fatal(1, "%s ptr valid mismatch", name);
      assert (p_i_o     === exp_lu)    else $fatal(1, "%s ptr L/U mismatch", name);
      assert (p_dt_o    === exp_dt)    else $fatal(1, "%s ptr DT mismatch", name);
      assert (p_limit_o === exp_limit) else $fatal(1, "%s ptr LIMIT mismatch", name);
      assert (p_addr_o  === exp_addr)  else $fatal(1, "%s ptr ADDR mismatch", name);
    end
  endtask

  task automatic expect_page_decode(
    input logic        exp_v,
    input logic [1:0]  exp_dt,
    input logic        exp_s,
    input logic        exp_wp,
    input logic        exp_ci,
    input logic        exp_m,
    input logic        exp_u,
    input logic [PA_WIDTH-1:0] exp_pa,
    input string name
  );
    begin
      #1;
      assert (pg_v_o  === exp_v)  else $fatal(1, "%s page valid mismatch", name);
      assert (pg_dt_o === exp_dt) else $fatal(1, "%s page DT mismatch", name);
      assert (pg_s_o  === exp_s)  else $fatal(1, "%s page S mismatch", name);
      assert (pg_wp_o === exp_wp) else $fatal(1, "%s page WP mismatch", name);
      assert (pg_ci_o === exp_ci) else $fatal(1, "%s page CI mismatch", name);
      assert (pg_m_o  === exp_m)  else $fatal(1, "%s page M mismatch", name);
      assert (pg_u_o  === exp_u)  else $fatal(1, "%s page U mismatch", name);
      assert (pg_pa_o === exp_pa) else $fatal(1, "%s page PA mismatch", name);
    end
  endtask

  task automatic check_root_golden;
    logic [DESCR_WIDTH-1:0] expected;
    begin
      clear_inputs();
      kind      = KIND_ROOT;
      r_v_i     = 1'b1;
      r_i_i     = 1'b1;
      r_dt_i    = 2'b11;
      r_limit_i = 15'h1234;
      r_addr_i  = 32'h89AB_CDE0;

      expected = 64'h9234_0003_89AB_CDE0;
      expect_packed(expected, "root Motorola pack");

      packed_to_fields = expected;
      expect_root_decode(1'b1, 1'b1, 2'b11, 15'h1234, 32'h89AB_CDE0, "root Motorola unpack");

      packed_to_fields = 64'h8001_0000_0000_0000;
      expect_root_decode(1'b0, 1'b1, 2'b00, 15'h0001, 32'h0000_0000, "root invalid decode");
    end
  endtask

  task automatic check_ptr_golden;
    logic [DESCR_WIDTH-1:0] expected;
    begin
      clear_inputs();
      kind      = KIND_PTR;
      p_v_i     = 1'b1;
      p_i_i     = 1'b0;
      p_dt_i    = 2'b10;
      p_limit_i = 15'h0456;
      p_addr_i  = 32'h1020_3040;

      expected = 64'h0456_0002_1020_3040;
      expect_packed(expected, "pointer Motorola pack");

      packed_to_fields = expected;
      expect_ptr_decode(1'b1, 1'b0, 2'b10, 15'h0456, 32'h1020_3040, "pointer Motorola unpack");

      packed_to_fields = 64'h0000_0000_7654_3210;
      expect_ptr_decode(1'b0, 1'b0, 2'b00, 15'h0000, 32'h7654_3210, "pointer invalid decode");
    end
  endtask

  task automatic check_page_golden;
    logic [DESCR_WIDTH-1:0] expected;
    begin
      clear_inputs();
      kind    = KIND_PAGE;
      pg_v_i  = 1'b1;
      pg_dt_i = 2'b01;
      pg_s_i  = 1'b1;
      pg_wp_i = 1'b1;
      pg_ci_i = 1'b0;
      pg_m_i  = 1'b1;
      pg_u_i  = 1'b1;
      pg_pa_i = 32'hCAFE_B000;

      expected = 64'h0000_011D_CAFE_B000;
      expect_packed(expected, "page Motorola pack");

      packed_to_fields = expected;
      expect_page_decode(1'b1, 2'b01, 1'b1, 1'b1, 1'b0, 1'b1, 1'b1,
                         32'hCAFE_B000, "page Motorola unpack");

      packed_to_fields = 64'h0000_0100_1234_5600;
      expect_page_decode(1'b0, 2'b00, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0,
                         32'h1234_5000, "page invalid decode");
    end
  endtask

  initial begin
    check_root_golden();
    check_ptr_golden();
    check_page_golden();
    $display("[descriptor_pack_tb] Motorola-aligned golden pack/unpack checks PASSED");
    $finish;
  end

endmodule
`default_nettype wire
