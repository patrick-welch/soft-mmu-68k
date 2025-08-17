// rtl/core/perm_check.v
// Soft MMU 68k — Permission check for R/W/X under User/Supervisor with TT bypass.
// Combinational only. Clean, parameterized interface.
//
// Inputs:
//   - req_r/req_w/req_x: exactly one should be 1 per cycle (read, write, fetch)
//   - is_user: 1 if access is in user mode (from mmu_decode)
//   - u_perm: {UX, UW, UR}   user  permissions (1=allowed)
//   - s_perm: {SX, SW, SR}   super permissions (1=allowed)
//   - tt_bypass: transparent translation window bypass (1 = allow unconditionally)
//
// Outputs:
//   - allow: 1 if access permitted
//   - fault: bitfield for diagnostics
//            [0] no_read
//            [1] write_protect
//            [2] no_execute
//            [3] privilege_related (user lacking perms where supervisor has them)
//            [4] bad_req (multiple or zero req_* set)

`timescale 1ns/1ps
module perm_check
(
    input  wire       req_r,
    input  wire       req_w,
    input  wire       req_x,
    input  wire       is_user,

    input  wire [2:0] u_perm,   // {UX, UW, UR}
    input  wire [2:0] s_perm,   // {SX, SW, SR}

    input  wire       tt_bypass,

    output wire       allow,
    output wire [4:0] fault
);

    // One‑hot check of request type
    wire [2:0] req = {req_x, req_w, req_r};
    wire       req_none = (req == 3'b000);
    wire       req_multi = (req[0] + req[1] + req[2]) > 1;

    // Select active permission bank based on U/S
    wire [2:0] act_perm = is_user ? u_perm : s_perm;

    // Decode individual bits
    wire ur = act_perm[0];
    wire uw = act_perm[1];
    wire ux = act_perm[2];

    // Base allow for each class
    wire allow_r = req_r & ur;
    wire allow_w = req_w & uw;
    wire allow_x = req_x & ux;

    // Fault bits (before TT bypass)
    wire no_read   = req_r & ~ur & ~tt_bypass;
    wire wr_prot   = req_w & ~uw & ~tt_bypass;
    wire no_exec   = req_x & ~ux & ~tt_bypass;

    // "Privilege related": user denied while supervisor would be allowed for same op.
    wire priv_rel_r = is_user & req_r & ~ur & s_perm[0];
    wire priv_rel_w = is_user & req_w & ~uw & s_perm[1];
    wire priv_rel_x = is_user & req_x & ~ux & s_perm[2];
    wire priv_rel   = (priv_rel_r | priv_rel_w | priv_rel_x) & ~tt_bypass;

    // Bad request (none or multiple)
    wire bad_req = (req_none | req_multi) & ~tt_bypass;

    // Overall allow (TT bypass wins)
    assign allow = tt_bypass ? 1'b1
                             : ((allow_r | allow_w | allow_x) & ~bad_req);

    assign fault = tt_bypass ? 5'b0
                             : { bad_req, priv_rel, no_exec, wr_prot, no_read };

endmodule
