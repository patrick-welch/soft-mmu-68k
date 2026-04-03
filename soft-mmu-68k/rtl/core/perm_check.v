// rtl/core/perm_check.v
// Soft MMU 68k — Permission check for R/W/X under User/Supervisor.
// Combinational only. Clean, parameterized interface.
//
// Inputs:
//   - req_r/req_w/req_x: exactly one should be 1 per cycle (read, write, fetch)
//   - is_user: 1 if access is in user mode (from mmu_decode)
//   - u_perm: {UX, UW, UR}   user  permissions (1=allowed)
//   - s_perm: {SX, SW, SR}   super permissions (1=allowed)
//   - tt_bypass: transparent-translation permission bypass for a valid request
//
// Outputs:
//   - allow: 1 if access permitted
//   - fault: bitfield for diagnostics
//            [0] no_read
//            [1] write_protect
//            [2] no_execute
//            [3] privilege_related (user lacking perms where supervisor has them)
//            [4] bad_req (multiple or zero req_* set)
//
// Semantics:
//   - Illegal request encodings dominate: zero-hot or multi-hot requests are
//     denied with only bad_req asserted.
//   - tt_bypass only suppresses permission denial for a valid single request; it
//     does not legalize a malformed request encoding.
//   - privilege_related reports a user-mode denial where the supervisor bank
//     would allow the same access class.

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
    wire [1:0] req_sum = req[0] + req[1] + req[2];
    wire       req_multi = (req_sum > 2'd1);
    wire       bad_req = req_none | req_multi;
    wire       req_valid = ~bad_req;

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
    wire perm_allow = allow_r | allow_w | allow_x;

    // Fault bits for a valid request before the optional TT permission bypass.
    wire deny_r = req_valid & req_r & ~ur;
    wire deny_w = req_valid & req_w & ~uw;
    wire deny_x = req_valid & req_x & ~ux;

    wire no_read = deny_r & ~tt_bypass;
    wire wr_prot = deny_w & ~tt_bypass;
    wire no_exec = deny_x & ~tt_bypass;

    // "Privilege related": user denied while supervisor would be allowed for same op.
    wire priv_rel_r = is_user & deny_r & s_perm[0];
    wire priv_rel_w = is_user & deny_w & s_perm[1];
    wire priv_rel_x = is_user & deny_x & s_perm[2];
    wire priv_rel   = (priv_rel_r | priv_rel_w | priv_rel_x) & ~tt_bypass;

    assign allow = bad_req ? 1'b0
                           : (tt_bypass ? 1'b1 : perm_allow);

    assign fault = bad_req ? 5'b10000
                           : { 1'b0, priv_rel, no_exec, wr_prot, no_read };

endmodule
