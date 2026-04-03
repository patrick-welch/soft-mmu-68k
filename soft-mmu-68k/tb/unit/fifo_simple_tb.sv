`timescale 1ns/1ps
`default_nettype none

module fifo_simple_tb;

  localparam int WIDTH = 8;
  localparam int DEPTH = 4;
  localparam int COUNT_WIDTH = $clog2(DEPTH + 1);

  logic                   clk;
  logic                   rst_n;
  logic                   push_i;
  logic                   pop_i;
  logic [WIDTH-1:0]       data_i;
  logic [WIDTH-1:0]       data_o;
  logic                   full_o;
  logic                   empty_o;
  logic [COUNT_WIDTH-1:0] count_o;

  logic [WIDTH-1:0] exp_queue[$];
  logic [WIDTH-1:0] exp_data_o;

  fifo_simple #(
    .WIDTH(WIDTH),
    .DEPTH(DEPTH)
  ) dut (
    .clk    (clk),
    .rst_n  (rst_n),
    .push_i (push_i),
    .pop_i  (pop_i),
    .data_i (data_i),
    .data_o (data_o),
    .full_o (full_o),
    .empty_o(empty_o),
    .count_o(count_o)
  );

  initial clk = 1'b0;
  /* verilator lint_off STMTDLY */
  always #5 clk = ~clk;
  /* verilator lint_on STMTDLY */

  task automatic clear_inputs;
    begin
      push_i = 1'b0;
      pop_i  = 1'b0;
      data_i = {WIDTH{1'b0}};
    end
  endtask

  task automatic check_state(input string label);
    logic exp_full;
    logic exp_empty;
    begin
      exp_full  = (exp_queue.size() == DEPTH);
      exp_empty = (exp_queue.size() == 0);

      assert(count_o == COUNT_WIDTH'(exp_queue.size()))
        else $fatal(1, "%s: count mismatch exp=%0d got=%0d", label, exp_queue.size(), count_o);
      assert(full_o == exp_full)
        else $fatal(1, "%s: full mismatch exp=%0b got=%0b", label, exp_full, full_o);
      assert(empty_o == exp_empty)
        else $fatal(1, "%s: empty mismatch exp=%0b got=%0b", label, exp_empty, empty_o);
      assert(data_o == exp_data_o)
        else $fatal(1, "%s: data_o mismatch exp=%02h got=%02h", label, exp_data_o, data_o);
    end
  endtask

  task automatic drive_cycle(
    input logic             do_push,
    input logic             do_pop,
    input logic [WIDTH-1:0] push_data,
    input string            label
  );
    logic pop_ok;
    logic push_ok;
    logic [WIDTH-1:0] popped_data;
    begin
      pop_ok = do_pop && (exp_queue.size() != 0);
      push_ok = do_push && ((exp_queue.size() != DEPTH) || pop_ok);
      popped_data = exp_data_o;

      if (pop_ok) begin
        popped_data = exp_queue[0];
      end

      push_i = do_push;
      pop_i  = do_pop;
      data_i = push_data;
      /* verilator lint_off STMTDLY */
      #10;
      /* verilator lint_on STMTDLY */

      if (pop_ok) begin
        void'(exp_queue.pop_front());
        exp_data_o = popped_data;
      end

      if (push_ok) begin
        exp_queue.push_back(push_data);
      end

      clear_inputs();
      check_state(label);
    end
  endtask

  integer value;
  logic [WIDTH-1:0] expected_data;

  initial begin
    clear_inputs();
    rst_n = 1'b1;
    exp_data_o = {WIDTH{1'b0}};

    /* verilator lint_off STMTDLY */
    #10;
    rst_n = 1'b0;
    #10;
    rst_n = 1'b1;
    #10;
    /* verilator lint_on STMTDLY */

    check_state("reset empty state");

    for (value = 0; value < DEPTH; value = value + 1) begin
      drive_cycle(1'b1, 1'b0, WIDTH'(value + 32'h10), $sformatf("push until full %0d", value));
    end
    check_state("after fill");

    drive_cycle(1'b1, 1'b0, 8'hEE, "overflow protection");
    assert(count_o == COUNT_WIDTH'(DEPTH))
      else $fatal(1, "overflow protection changed count");

    for (value = 0; value < DEPTH; value = value + 1) begin
      drive_cycle(1'b0, 1'b1, {WIDTH{1'b0}}, $sformatf("pop until empty %0d", value));
      expected_data = WIDTH'(value + 32'h10);
      assert(data_o == expected_data)
        else $fatal(1, "pop data mismatch exp=%02h got=%02h", expected_data, data_o);
    end
    check_state("after drain");

    drive_cycle(1'b0, 1'b1, {WIDTH{1'b0}}, "underflow protection");
    assert(count_o == 0)
      else $fatal(1, "underflow protection changed count");

    drive_cycle(1'b1, 1'b0, 8'hA1, "sim setup push 0");
    drive_cycle(1'b1, 1'b0, 8'hB2, "sim setup push 1");
    drive_cycle(1'b1, 1'b1, 8'hC3, "simultaneous push pop");
    assert(data_o == 8'hA1)
      else $fatal(1, "simultaneous push/pop returned wrong data got=%02h", data_o);
    drive_cycle(1'b0, 1'b1, {WIDTH{1'b0}}, "post simultaneous pop 0");
    assert(data_o == 8'hB2)
      else $fatal(1, "post simultaneous data mismatch got=%02h", data_o);
    drive_cycle(1'b0, 1'b1, {WIDTH{1'b0}}, "post simultaneous pop 1");
    assert(data_o == 8'hC3)
      else $fatal(1, "post simultaneous tail mismatch got=%02h", data_o);

    for (value = 0; value < DEPTH; value = value + 1) begin
      drive_cycle(1'b1, 1'b0, WIDTH'(value + 32'h40), $sformatf("refill for full-sim %0d", value));
    end
    drive_cycle(1'b1, 1'b1, 8'h99, "simultaneous push pop while full");
    assert(count_o == COUNT_WIDTH'(DEPTH))
      else $fatal(1, "full simultaneous push/pop should keep FIFO full");
    assert(data_o == 8'h40)
      else $fatal(1, "full simultaneous push/pop returned wrong data got=%02h", data_o);

    for (value = 1; value < DEPTH; value = value + 1) begin
      drive_cycle(1'b0, 1'b1, {WIDTH{1'b0}}, $sformatf("drain full-sim %0d", value));
      expected_data = WIDTH'(value + 32'h40);
      assert(data_o == expected_data)
        else $fatal(1, "drain after full-sim mismatch exp=%02h got=%02h", expected_data, data_o);
    end
    drive_cycle(1'b0, 1'b1, {WIDTH{1'b0}}, "drain full-sim tail");
    assert(data_o == 8'h99)
      else $fatal(1, "full-sim tail mismatch got=%02h", data_o);

    $display("[fifo_simple_tb] PASS");
    $finish;
  end

endmodule
`default_nettype wire
