`timescale 1ns/1ps
`default_nettype none

module descriptor_pack_tb;

  // Pick a practical test configuration (adjust freely)
  localparam int DESCR_WIDTH = 32;
  localparam int PA_WIDTH    = 24;  // keep small for sim speed
  localparam int LIMIT_WIDTH = 12;
  localparam int PAGE_SHIFT  = 12;  // 4 KiB pages

  // Instantiate with default contiguous mappings (update to Motorola mapping later)
  logic [1:0] kind;

  // Root I/O
  logic        r_v_i, r_i_i;
  logic [1:0]  r_dt_i;
  logic [LIMIT_WIDTH-1:0] r_limit_i;
  logic [PA_WIDTH-1:0]    r_addr_i;

  // Pointer I/O
  logic        p_v_i, p_i_i;
  logic [1:0]  p_dt_i;
  logic [LIMIT_WIDTH-1:0] p_limit_i;
  logic [PA_WIDTH-1:0]    p_addr_i;

  // Page I/O
  logic        pg_v_i;
  logic [1:0]  pg_dt_i;
  logic        pg_s_i, pg_wp_i, pg_ci_i, pg_m_i, pg_u_i;
  logic [PA_WIDTH-1:0]    pg_pa_i;

  // Packed buses
  logic [DESCR_WIDTH-1:0] packed_from_fields;
  logic [DESCR_WIDTH-1:0] packed_loopback;

  // Unpacked outputs
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
    // If you want to verify Motorola packing now, override bit positions here.
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

    .packed_i (packed_from_fields), // loop back for round-trip

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

  // -----------------------------------------
  // Sanity: no negative/overflowing positions
  // (lightweight; deeper overlap checks can be added if needed)
  // -----------------------------------------
  initial begin
    if (DESCR_WIDTH <= 0) begin
      $fatal(1, "DESCR_WIDTH must be > 0");
    end
  end

  // -----------------------------------------
  // Randomized round-trip tests
  // -----------------------------------------
  task automatic check_root_roundtrip;
    r_v_i     = $urandom_range(0,1);
    r_i_i     = $urandom_range(0,1);
    r_dt_i    = $urandom_range(0,3);
    r_limit_i = $urandom;
    r_addr_i  = $urandom;

    // mask to widths
    r_limit_i = r_limit_i & ((1<<LIMIT_WIDTH)-1);
    r_addr_i  = r_addr_i  & ((1<<PA_WIDTH)-1);

    kind = 2'd0; // KIND_ROOT (matches module default)
    #1;

    assert(r_v_o     === r_v_i)     else $fatal(1, "root V mismatch");
    assert(r_i_o     === r_i_i)     else $fatal(1, "root I mismatch");
    assert(r_dt_o    === r_dt_i)    else $fatal(1, "root DT mismatch");
    assert(r_limit_o === r_limit_i) else $fatal(1, "root LIMIT mismatch");
    // r_addr_o is zero-extended if packed field is narrower; mask compare:
    assert((r_addr_o & ((1<<PA_WIDTH)-1)) === r_addr_i) else $fatal(1,"root ADDR mismatch");
  endtask

  task automatic check_ptr_roundtrip;
    p_v_i     = $urandom_range(0,1);
    p_i_i     = $urandom_range(0,1);
    p_dt_i    = $urandom_range(0,3);
    p_limit_i = $urandom;
    p_addr_i  = $urandom;

    p_limit_i &= ((1<<LIMIT_WIDTH)-1);
    p_addr_i  &= ((1<<PA_WIDTH)-1);

    kind = 2'd1; // KIND_PTR
    #1;

    assert(p_v_o     === p_v_i)     else $fatal(1, "ptr V mismatch");
    assert(p_i_o     === p_i_i)     else $fatal(1, "ptr I mismatch");
    assert(p_dt_o    === p_dt_i)    else $fatal(1, "ptr DT mismatch");
    assert(p_limit_o === p_limit_i) else $fatal(1, "ptr LIMIT mismatch");
    assert((p_addr_o & ((1<<PA_WIDTH)-1)) === p_addr_i) else $fatal(1,"ptr ADDR mismatch");
  endtask

  task automatic check_page_roundtrip;
    pg_v_i  = $urandom_range(0,1);
    pg_dt_i = $urandom_range(0,3);
    pg_s_i  = $urandom_range(0,1);
    pg_wp_i = $urandom_range(0,1);
    pg_ci_i = $urandom_range(0,1);
    pg_m_i  = $urandom_range(0,1);
    pg_u_i  = $urandom_range(0,1);

    // Constrain PA to page-aligned
    pg_pa_i = ($urandom & ((1<<PA_WIDTH)-1)) & ~((1<<PAGE_SHIFT)-1);

    kind = 2'd2; // KIND_PAGE
    #1;

    assert(pg_v_o  === pg_v_i)  else $fatal(1, "page V mismatch");
    assert(pg_dt_o === pg_dt_i) else $fatal(1, "page DT mismatch");
    assert(pg_s_o  === pg_s_i)  else $fatal(1, "page S mismatch");
    assert(pg_wp_o === pg_wp_i) else $fatal(1, "page WP mismatch");
    assert(pg_ci_o === pg_ci_i) else $fatal(1, "page CI mismatch");
    assert(pg_m_o  === pg_m_i)  else $fatal(1, "page M mismatch");
    assert(pg_u_o  === pg_u_i)  else $fatal(1, "page U mismatch");
    assert(pg_pa_o === pg_pa_i) else $fatal(1, "page PA mismatch");
  endtask

  // Optional “golden vectors” hook:
  // If you define SV include(s) populated from docs/refs/68851_notes.md
  // you can add one-liners here like:
  //   `include "docs/refs/68851_notes_tb_vectors.svh"
  // and call provided tasks to check specific known encodings.
  // (Left as TODO until vectors are available in the repo.)

  initial begin
    // Smoke: a few iterations each
    repeat (200) check_root_roundtrip();
    repeat (200) check_ptr_roundtrip();
    repeat (400) check_page_roundtrip();

    $display("[descriptor_pack_tb] All round-trip tests PASSED");
    $finish;
  end

endmodule
`default_nettype wire
