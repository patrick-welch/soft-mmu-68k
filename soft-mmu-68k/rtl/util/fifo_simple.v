`timescale 1ns/1ps
`default_nettype none

module fifo_simple #(
  parameter integer WIDTH = 32,
  parameter integer DEPTH = 4
) (
  input  wire                    clk,
  input  wire                    rst_n,
  input  wire                    push_i,
  input  wire                    pop_i,
  input  wire [WIDTH-1:0]        data_i,
  output reg  [WIDTH-1:0]        data_o,
  output wire                    full_o,
  output wire                    empty_o,
  output wire [$clog2(DEPTH + 1)-1:0] count_o
);

  localparam integer ADDR_WIDTH  = (DEPTH <= 1) ? 1 : $clog2(DEPTH);
  localparam integer COUNT_WIDTH = $clog2(DEPTH + 1);
  localparam [ADDR_WIDTH-1:0] LAST_PTR = ADDR_WIDTH'(DEPTH - 1);

  reg [WIDTH-1:0] mem [0:DEPTH-1];
  reg [ADDR_WIDTH-1:0] wr_ptr;
  reg [ADDR_WIDTH-1:0] rd_ptr;
  reg [COUNT_WIDTH-1:0] count_r;

  integer idx;

  wire fifo_full  = (count_r == DEPTH[COUNT_WIDTH-1:0]);
  wire fifo_empty = (count_r == {COUNT_WIDTH{1'b0}});
  wire do_push    = push_i && (!fifo_full || pop_i);
  wire do_pop     = pop_i && !fifo_empty;

  assign full_o  = fifo_full;
  assign empty_o = fifo_empty;
  assign count_o = count_r;

  initial begin
    if (DEPTH < 1) begin
      $fatal(1, "fifo_simple DEPTH must be >= 1");
    end
    if (WIDTH < 1) begin
      $fatal(1, "fifo_simple WIDTH must be >= 1");
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      data_o  <= {WIDTH{1'b0}};
      wr_ptr  <= {ADDR_WIDTH{1'b0}};
      rd_ptr  <= {ADDR_WIDTH{1'b0}};
      count_r <= {COUNT_WIDTH{1'b0}};
      for (idx = 0; idx < DEPTH; idx = idx + 1) begin
        mem[idx] <= {WIDTH{1'b0}};
      end
    end else begin
      if (do_pop) begin
        data_o <= mem[rd_ptr];
        if (rd_ptr == LAST_PTR) begin
          rd_ptr <= {ADDR_WIDTH{1'b0}};
        end else begin
          rd_ptr <= rd_ptr + 1'b1;
        end
      end

      if (do_push) begin
        mem[wr_ptr] <= data_i;
        if (wr_ptr == LAST_PTR) begin
          wr_ptr <= {ADDR_WIDTH{1'b0}};
        end else begin
          wr_ptr <= wr_ptr + 1'b1;
        end
      end

      case ({do_push, do_pop})
        2'b10: count_r <= count_r + 1'b1;
        2'b01: count_r <= count_r - 1'b1;
        default: count_r <= count_r;
      endcase
    end
  end

endmodule
`default_nettype wire
