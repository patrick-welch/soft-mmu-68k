// rtl/core/mmu_decode.v
// Soft MMU 68k — Function Code decode (FC[2:0]) to U/S and P/D domains.
// Combinational only. No latches.
//
// Notes (matches common 68020/030 FC usage):
//   FC[2] = S bit (1 = supervisor, 0 = user)
//   FC[1] = space (0 = program/data space, 1 = CPU/special space)
//   FC[0] = P/D    (0 = data, 1 = program)   — only meaningful when FC[1]==0
//
// This block provides simple, side‑effect‑free decode signals you can fan out.
// If FC[1]==1 (CPU/special), program/data are deasserted.

`timescale 1ns/1ps
module mmu_decode
(
    input  wire [2:0] fc,          // Function code from core

    output wire       is_user,     // 1 = user space
    output wire       is_super,    // 1 = supervisor space
    output wire       is_program,  // 1 = program access (only when cpu_space==0)
    output wire       is_data,     // 1 = data access    (only when cpu_space==0)
    output wire       cpu_space    // 1 = CPU/special space (TT typically bypasses)
);

    assign is_super  = fc[2];
    assign is_user   = ~fc[2];
    assign cpu_space = fc[1];

    // Only meaningful for memory space (cpu_space == 0)
    assign is_program = (~cpu_space) &  fc[0];
    assign is_data    = (~cpu_space) & ~fc[0];

endmodule
