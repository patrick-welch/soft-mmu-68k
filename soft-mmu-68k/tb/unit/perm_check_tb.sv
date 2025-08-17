// tb/unit/perm_check_tb.sv  (FIXED for verilator --lint-only)

`timescale 1ns/1ps

module perm_check_tb;

    // DUT I/O
    logic       req_r, req_w, req_x;
    logic       is_user;
    logic [2:0] u_perm;   // {UX,UW,UR}
    logic [2:0] s_perm;   // {SX,SW,SR}
    logic       tt_bypass;

    logic       allow;
    logic [4:0] fault;

    // Instantiate DUT
    perm_check dut (
        .req_r(req_r), .req_w(req_w), .req_x(req_x),
        .is_user(is_user),
        .u_perm(u_perm), .s_perm(s_perm),
        .tt_bypass(tt_bypass),
        .allow(allow), .fault(fault)
    );

    // Reference model (mirrors RTL intent)
    function automatic void ref_model
    (
        input  logic       f_req_r, f_req_w, f_req_x,
        input  logic       f_is_user,
        input  logic [2:0] f_u_perm,
        input  logic [2:0] f_s_perm,
        input  logic       f_tt_bypass,
        output logic       f_allow,
        output logic [4:0] f_fault
    );
        logic [2:0] req = {f_req_x, f_req_w, f_req_r};
        logic req_none;

        // Use a sized sum to keep Verilator happy
        logic [1:0] req_sum;
        logic req_multi;

        logic [2:0] act_perm;
        logic ur, uw, ux;
        logic allow_r, allow_w, allow_x;
        logic no_read, wr_prot, no_exec;
        logic priv_rel_r, priv_rel_w, priv_rel_x, priv_rel;
        logic bad_req;

        req_none = (req == 3'b000);
        req_sum  = req[0] + req[1] + req[2];
        req_multi = (req_sum > 2'd1);

        act_perm = f_is_user ? f_u_perm : f_s_perm;
        ur = act_perm[0];
        uw = act_perm[1];
        ux = act_perm[2];

        allow_r = f_req_r & ur;
        allow_w = f_req_w & uw;
        allow_x = f_req_x & ux;

        no_read = f_req_r & ~ur & ~f_tt_bypass;
        wr_prot = f_req_w & ~uw & ~f_tt_bypass;
        no_exec = f_req_x & ~ux & ~f_tt_bypass;

        priv_rel_r = f_is_user & f_req_r & ~ur & f_s_perm[0];
        priv_rel_w = f_is_user & f_req_w & ~uw & f_s_perm[1];
        priv_rel_x = f_is_user & f_req_x & ~ux & f_s_perm[2];
        priv_rel   = (priv_rel_r | priv_rel_w | priv_rel_x) & ~f_tt_bypass;

        bad_req = (req_none | req_multi) & ~f_tt_bypass;

        f_allow = f_tt_bypass ? 1'b1
                              : ((allow_r | allow_w | allow_x) & ~bad_req);

        f_fault = f_tt_bypass ? 5'b0
                              : { bad_req, priv_rel, no_exec, wr_prot, no_read };
    endfunction

    // Move declarations to top-level of the initial block (no mid-block decls)
    int errors;
    logic       r_allow;        // <— was mid-block; now hoisted
    logic [4:0] r_fault;        // <— was mid-block; now hoisted

    initial begin
        $display("[perm_check_tb] Starting exhaustive checks…");

        errors = 0;

        for (int su = 0; su < 2; su++) begin
            is_user = su[0];
            for (int req_sel = 0; req_sel < 3; req_sel++) begin
                {req_x, req_w, req_r} = 3'b000;
                case (req_sel)
                    0: req_r = 1'b1;
                    1: req_w = 1'b1;
                    2: req_x = 1'b1;
                endcase

                for (int upv = 0; upv < 8; upv++) begin
                    u_perm = upv[2:0];
                    for (int spv = 0; spv < 8; spv++) begin
                        s_perm = spv[2:0];
                        for (int tt = 0; tt < 2; tt++) begin
                            tt_bypass = tt[0];

                            // Evaluate reference
                            ref_model(req_r, req_w, req_x,
                                      is_user, u_perm, s_perm, tt_bypass,
                                      r_allow, r_fault);

                            #1; // settle

                            if (allow !== r_allow || fault !== r_fault) begin
                                $error("Mismatch: U=%0d RWX=%b%b%b u_perm=%b s_perm=%b TT=%0d | DUT allow=%0b fault=%05b, REF allow=%0b fault=%05b",
                                       is_user, req_r, req_w, req_x, u_perm, s_perm, tt_bypass,
                                       allow, fault, r_allow, r_fault);
                                errors++;
                            end
                        end
                    end
                end
            end
        end

        // Bad request cases
        {req_r, req_w, req_x} = 3'b000; is_user = 1'b1; u_perm = 3'b111; s_perm = 3'b111; tt_bypass = 1'b0; #1;
        {req_r, req_w, req_x} = 3'b110; is_user = 1'b0; u_perm = 3'b000; s_perm = 3'b111; tt_bypass = 1'b0; #1;

        if (errors == 0)
            $display("[perm_check_tb] PASS — all combinations matched.");
        else
            $display("[perm_check_tb] FAIL — %0d mismatches.", errors);

        $finish;
    end

endmodule
