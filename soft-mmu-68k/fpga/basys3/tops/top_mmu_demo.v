// top_mmu_demo.v - board smoke: switches drive VA bits; LEDs show hit/miss
module top_mmu_demo(
  input  wire        clk,
  input  wire [15:0] sw,
  output wire [15:0] led
);
  // toy VA from switches
  wire [23:0] va = {8'h00, sw[15:0]};
  wire [23:0] pa;
  wire hit, fault;

  mmu_top #(.VA_WIDTH(24), .PA_WIDTH(24)) u_mmu (
    .clk(clk), .rst_n(1'b1),
    .va_in(va),
    .fc_in(3'b001),    // user data, placeholder
    .rw_n(1'b1),       // read
    .pa_out(pa), .hit(hit), .fault(fault)
  );

  assign led[0] = hit;
  assign led[1] = fault;
  assign led[15:2] = pa[13:0];  // show PA nibble-ish for fun
endmodule
