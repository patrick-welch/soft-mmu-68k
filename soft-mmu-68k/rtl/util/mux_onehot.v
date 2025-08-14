// mux_onehot.v - parameterized one-hot mux
module mux_onehot
#(
  parameter WIDTH = 32,
  parameter N     = 4
)(
  input  wire [N-1:0][WIDTH-1:0] in,
  input  wire [N-1:0]            sel_onehot,
  output wire [WIDTH-1:0]        out
);
  integer i;
  reg [WIDTH-1:0] r;
  always @* begin
    r = {WIDTH{1'b0}};
    for (i = 0; i < N; i = i + 1) begin
      if (sel_onehot[i]) r = in[i];
    end
  end
  assign out = r;
endmodule
