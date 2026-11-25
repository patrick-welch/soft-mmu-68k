`timescale 1ns/1ps
`default_nettype none

module basys3_mmu_demo_tb;
  parameter int SETTLE_BITS = 4;
  logic        clk = 1'b0;
  logic        btnC = 1'b1;
  logic [15:0] sw = 16'h0000;
  wire  [15:0] led;

  top_mmu_demo #(.SETTLE_BITS(SETTLE_BITS)) dut (
    .clk(clk), .btnC(btnC), .sw(sw), .led(led)
  );

  always #5 clk <= ~clk;

  task automatic check_panel(input logic [15:0] switches,
                             input logic [15:0] expected);
    @(negedge clk);
    sw = switches;
    btnC = 1'b1;
    repeat (2) @(negedge clk);
    if (led !== 16'h0000)
      $fatal(1, "SW=%h reset LED=%h, expected 0000", sw, led);
    btnC = 1'b0;

    // Allow the switch filter and the entire flush/access/access/probe sequence
    // to finish. Sample on falling edges, after registered outputs have settled.
    repeat ((1 << SETTLE_BITS) + 64) @(negedge clk);
    repeat (8) begin
      if (led !== expected)
        $fatal(1, "SW=%h settled LED=%h, expected %h", sw, led, expected);
      @(negedge clk);
    end
    $display("SW=%h settled LED=%h", sw, led);
  endtask

  initial begin
    // Expected front-panel readings recorded in the verification input to #46.
    check_panel(16'h0000, 16'h801C); // user data, translated
    check_panel(16'h8000, 16'h0028); // transparent translation
    check_panel(16'h0100, 16'h825E); // user data, supervisor-only page
    check_panel(16'h1100, 16'h821C); // supervisor data, same page
    $finish;
  end
endmodule

`default_nettype wire
