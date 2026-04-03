// rtl/core/mmu_decode.v
// Soft MMU 68k — Motorola function-code decode.
// Combinational only. No latches.
//
// Motorola 68k-style FC[2:0] classes used here:
//   3'b001 = user data
//   3'b010 = user program
//   3'b101 = supervisor data
//   3'b110 = supervisor program
//   3'b111 = CPU/special space
//   3'b000 and 3'b100 are treated as reserved/illegal in this first pass
//
// Outputs intentionally remain simple:
//   - is_user / is_super reflect the privilege half selected by FC[2]
//   - is_program / is_data only assert for valid memory-space FC encodings
//   - cpu_space only asserts for the explicit CPU-space code (3'b111)
//
// Reserved encodings deassert program/data/cpu_space so downstream logic can
// treat them as "not a normal memory access" without adding a new interface pin.

`timescale 1ns/1ps
module mmu_decode
(
    input  wire [2:0] fc,          // Function code from core

    output wire       is_user,     // 1 = user space
    output wire       is_super,    // 1 = supervisor space
    output wire       is_program,  // 1 = program access for a valid memory-space FC
    output wire       is_data,     // 1 = data access    for a valid memory-space FC
    output wire       cpu_space    // 1 = CPU/special space (FC == 3'b111)
);

    wire fc_user_data   = (fc == 3'b001);
    wire fc_user_prog   = (fc == 3'b010);
    wire fc_super_data  = (fc == 3'b101);
    wire fc_super_prog  = (fc == 3'b110);
    wire fc_cpu_space   = (fc == 3'b111);

    assign is_super  = fc[2];
    assign is_user   = ~fc[2];
    assign cpu_space = fc_cpu_space;

    assign is_program = fc_user_prog | fc_super_prog;
    assign is_data    = fc_user_data | fc_super_data;

endmodule
