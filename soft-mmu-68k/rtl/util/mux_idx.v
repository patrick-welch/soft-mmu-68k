// mux_idx.v - parameterized index-based mux
module mux_idx
#(
  parameter WIDTH = 32,
  parameter SELW  = 2
)(
  input  wire [WIDTH-1:0] in [0:(1<<SELW)-1],
  input  wire [SELW-1:0]  sel,
  output wire [WIDTH-1:0] out
);
  assign out = in[sel];
endmodule
