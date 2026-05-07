`timescale 1ns/1ps
`default_nettype none

module tlb_dm_tb;

  localparam int VA_WIDTH   = 16;
  localparam int PA_WIDTH   = 16;
  localparam int PAGE_SHIFT = 8;
  localparam int ENTRIES    = 4;
  localparam int FC_WIDTH   = 3;
  localparam int ATTR_WIDTH = 4;

  logic                  clk;
  logic                  rst_n;

  logic                  lookup_valid;
  logic [VA_WIDTH-1:0]   lookup_va;
  logic [FC_WIDTH-1:0]   lookup_fc;
  logic                  lookup_hit;
  logic                  lookup_miss;
  logic [PA_WIDTH-1:0]   lookup_pa;
  logic [ATTR_WIDTH-1:0] lookup_attr;

  logic                  refill_valid;
  logic [VA_WIDTH-1:0]   refill_va;
  logic [PA_WIDTH-1:0]   refill_pa;
  logic [FC_WIDTH-1:0]   refill_fc;
  logic [ATTR_WIDTH-1:0] refill_attr;

  logic                  invalidate_all;
  logic                  invalidate_match;
  logic [VA_WIDTH-1:0]   invalidate_va;
  logic [FC_WIDTH-1:0]   invalidate_fc;

  tlb_dm #(
    .VA_WIDTH   (VA_WIDTH),
    .PA_WIDTH   (PA_WIDTH),
    .PAGE_SHIFT (PAGE_SHIFT),
    .ENTRIES    (ENTRIES),
    .FC_WIDTH   (FC_WIDTH),
    .ATTR_WIDTH (ATTR_WIDTH)
  ) dut (
    .clk               (clk),
    .rst_n             (rst_n),
    .lookup_valid_i    (lookup_valid),
    .lookup_va_i       (lookup_va),
    .lookup_fc_i       (lookup_fc),
    .lookup_hit_o      (lookup_hit),
    .lookup_miss_o     (lookup_miss),
    .lookup_pa_o       (lookup_pa),
    .lookup_attr_o     (lookup_attr),
    .refill_valid_i    (refill_valid),
    .refill_va_i       (refill_va),
    .refill_pa_i       (refill_pa),
    .refill_fc_i       (refill_fc),
    .refill_attr_i     (refill_attr),
    .invalidate_all_i  (invalidate_all),
    .invalidate_match_i(invalidate_match),
    .invalidate_va_i   (invalidate_va),
    .invalidate_fc_i   (invalidate_fc)
  );

  initial clk = 1'b0;
  /* verilator lint_off STMTDLY */
  always #5 clk = ~clk;
  /* verilator lint_on STMTDLY */

  task automatic clear_inputs;
    begin
      lookup_valid     = 1'b0;
      lookup_va        = {VA_WIDTH{1'b0}};
      lookup_fc        = {FC_WIDTH{1'b0}};
      refill_valid     = 1'b0;
      refill_va        = {VA_WIDTH{1'b0}};
      refill_pa        = {PA_WIDTH{1'b0}};
      refill_fc        = {FC_WIDTH{1'b0}};
      refill_attr      = {ATTR_WIDTH{1'b0}};
      invalidate_all   = 1'b0;
      invalidate_match = 1'b0;
      invalidate_va    = {VA_WIDTH{1'b0}};
      invalidate_fc    = {FC_WIDTH{1'b0}};
    end
  endtask

  task automatic expect_lookup(
    input logic                exp_hit,
    input logic [PA_WIDTH-1:0] exp_pa,
    input logic [ATTR_WIDTH-1:0] exp_attr
  );
    begin
      /* verilator lint_off STMTDLY */
      #1;
      /* verilator lint_on STMTDLY */
      assert(lookup_hit === exp_hit)
        else $fatal(1, "lookup_hit mismatch exp=%0b got=%0b", exp_hit, lookup_hit);
      assert(lookup_miss === (lookup_valid && !exp_hit))
        else $fatal(1, "lookup_miss mismatch exp=%0b got=%0b", (lookup_valid && !exp_hit), lookup_miss);
      assert(lookup_pa === (exp_hit ? exp_pa : {PA_WIDTH{1'b0}}))
        else $fatal(1, "lookup_pa mismatch exp=%h got=%h", exp_pa, lookup_pa);
      assert(lookup_attr === (exp_hit ? exp_attr : {ATTR_WIDTH{1'b0}}))
        else $fatal(1, "lookup_attr mismatch exp=%h got=%h", exp_attr, lookup_attr);
    end
  endtask

  localparam logic [VA_WIDTH-1:0] VA_A  = 16'h1234;
  localparam logic [PA_WIDTH-1:0] PA_A  = 16'hAB34;
  localparam logic [FC_WIDTH-1:0] FC_A  = 3'b101;
  localparam logic [ATTR_WIDTH-1:0] ATTR_A = 4'b1010;

  localparam logic [VA_WIDTH-1:0] VA_B  = 16'h5634; // Same index as VA_A, different tag.
  localparam logic [PA_WIDTH-1:0] PA_B  = 16'hCD34;
  localparam logic [FC_WIDTH-1:0] FC_B  = 3'b101;
  localparam logic [ATTR_WIDTH-1:0] ATTR_B = 4'b0101;

  initial begin
    clear_inputs();
    rst_n = 1'b1;

    /* verilator lint_off STMTDLY */
    #10;
    rst_n = 1'b0;
    #10;
    rst_n = 1'b1;
    #10;

    // Reset state: any lookup misses.
    lookup_valid = 1'b1;
    lookup_va    = VA_A;
    lookup_fc    = FC_A;
    expect_lookup(1'b0, {PA_WIDTH{1'b0}}, {ATTR_WIDTH{1'b0}});

    // Refill then observe a hit with translated PA/attrs.
    refill_valid = 1'b1;
    refill_va    = VA_A;
    refill_pa    = PA_A;
    refill_fc    = FC_A;
    refill_attr  = ATTR_A;
    #10;
    refill_valid = 1'b0;
    refill_va    = {VA_WIDTH{1'b0}};
    refill_pa    = {PA_WIDTH{1'b0}};
    refill_fc    = {FC_WIDTH{1'b0}};
    refill_attr  = {ATTR_WIDTH{1'b0}};
    expect_lookup(1'b1, PA_A, ATTR_A);

    // Different FC must miss even when VA matches.
    lookup_fc = 3'b001;
    expect_lookup(1'b0, {PA_WIDTH{1'b0}}, {ATTR_WIDTH{1'b0}});

    // Collision on the same direct-mapped index replaces the old entry.
    lookup_fc = FC_A;
    refill_valid = 1'b1;
    refill_va    = VA_B;
    refill_pa    = PA_B;
    refill_fc    = FC_B;
    refill_attr  = ATTR_B;
    #10;
    refill_valid = 1'b0;
    refill_va    = {VA_WIDTH{1'b0}};
    refill_pa    = {PA_WIDTH{1'b0}};
    refill_fc    = {FC_WIDTH{1'b0}};
    refill_attr  = {ATTR_WIDTH{1'b0}};
    lookup_va = VA_A;
    expect_lookup(1'b0, {PA_WIDTH{1'b0}}, {ATTR_WIDTH{1'b0}});
    lookup_va = VA_B;
    expect_lookup(1'b1, PA_B, ATTR_B);

    // Targeted invalidate removes only the matching slot.
    invalidate_match = 1'b1;
    invalidate_va    = VA_B;
    invalidate_fc    = FC_B;
    #10;
    #1;
    invalidate_match = 1'b0;
    invalidate_va    = {VA_WIDTH{1'b0}};
    invalidate_fc    = {FC_WIDTH{1'b0}};
    expect_lookup(1'b0, {PA_WIDTH{1'b0}}, {ATTR_WIDTH{1'b0}});

    // Refill again, then whole-TLB invalidate clears the valid bits.
    refill_valid = 1'b1;
    refill_va    = VA_A;
    refill_pa    = PA_A;
    refill_fc    = FC_A;
    refill_attr  = ATTR_A;
    #10;
    refill_valid = 1'b0;
    refill_va    = {VA_WIDTH{1'b0}};
    refill_pa    = {PA_WIDTH{1'b0}};
    refill_fc    = {FC_WIDTH{1'b0}};
    refill_attr  = {ATTR_WIDTH{1'b0}};
    lookup_va = VA_A;
    lookup_fc = FC_A;
    expect_lookup(1'b1, PA_A, ATTR_A);
    invalidate_all = 1'b1;
    #10;
    invalidate_all = 1'b0;
    /* verilator lint_on STMTDLY */
    expect_lookup(1'b0, {PA_WIDTH{1'b0}}, {ATTR_WIDTH{1'b0}});

    $display("[tlb_dm_tb] PASS");
    $finish;
  end

endmodule
`default_nettype wire
