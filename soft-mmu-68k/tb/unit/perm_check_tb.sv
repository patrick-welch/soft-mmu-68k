// tb/unit/perm_check_tb.sv

`timescale 1ns/1ps

module perm_check_tb;

    localparam logic [4:0] FAULT_NO_READ    = 5'b00001;
    localparam logic [4:0] FAULT_WR_PROT    = 5'b00010;
    localparam logic [4:0] FAULT_NO_EXEC    = 5'b00100;
    localparam logic [4:0] FAULT_PRIV_REL   = 5'b01000;
    localparam logic [4:0] FAULT_BAD_REQ    = 5'b10000;

    // DUT I/O
    logic       req_r, req_w, req_x;
    logic       is_user;
    logic [2:0] u_perm;   // {UX,UW,UR}
    logic [2:0] s_perm;   // {SX,SW,SR}
    logic       tt_bypass;

    logic       allow;
    logic [4:0] fault;

    // Decode DUT I/O
    logic [2:0] fc;
    logic       decode_is_user;
    logic       decode_is_super;
    logic       decode_is_program;
    logic       decode_is_data;
    logic       decode_cpu_space;

    // Instantiate DUT
    perm_check dut (
        .req_r(req_r), .req_w(req_w), .req_x(req_x),
        .is_user(is_user),
        .u_perm(u_perm), .s_perm(s_perm),
        .tt_bypass(tt_bypass),
        .allow(allow), .fault(fault)
    );

    mmu_decode decode_dut (
        .fc        (fc),
        .is_user   (decode_is_user),
        .is_super  (decode_is_super),
        .is_program(decode_is_program),
        .is_data   (decode_is_data),
        .cpu_space (decode_cpu_space)
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
        logic [1:0] req_sum;
        logic req_multi;
        logic bad_req;
        logic req_valid;

        logic [2:0] act_perm;
        logic ur, uw, ux;
        logic allow_r, allow_w, allow_x, perm_allow;
        logic deny_r, deny_w, deny_x;
        logic no_read, wr_prot, no_exec;
        logic priv_rel_r, priv_rel_w, priv_rel_x, priv_rel;

        req_none = (req == 3'b000);
        req_sum  = req[0] + req[1] + req[2];
        req_multi = (req_sum > 2'd1);
        bad_req = req_none | req_multi;
        req_valid = ~bad_req;

        act_perm = f_is_user ? f_u_perm : f_s_perm;
        ur = act_perm[0];
        uw = act_perm[1];
        ux = act_perm[2];

        allow_r = f_req_r & ur;
        allow_w = f_req_w & uw;
        allow_x = f_req_x & ux;
        perm_allow = allow_r | allow_w | allow_x;

        deny_r = req_valid & f_req_r & ~ur;
        deny_w = req_valid & f_req_w & ~uw;
        deny_x = req_valid & f_req_x & ~ux;

        no_read = deny_r & ~f_tt_bypass;
        wr_prot = deny_w & ~f_tt_bypass;
        no_exec = deny_x & ~f_tt_bypass;

        priv_rel_r = f_is_user & deny_r & f_s_perm[0];
        priv_rel_w = f_is_user & deny_w & f_s_perm[1];
        priv_rel_x = f_is_user & deny_x & f_s_perm[2];
        priv_rel   = (priv_rel_r | priv_rel_w | priv_rel_x) & ~f_tt_bypass;

        f_allow = bad_req ? 1'b0
                          : (f_tt_bypass ? 1'b1 : perm_allow);

        f_fault = bad_req ? FAULT_BAD_REQ
                          : {1'b0, priv_rel, no_exec, wr_prot, no_read};
    endfunction

    int errors;
    logic       r_allow;
    logic [4:0] r_fault;

    task automatic expect_perm_case(
        input string      name,
        input logic       t_req_r,
        input logic       t_req_w,
        input logic       t_req_x,
        input logic       t_is_user,
        input logic [2:0] t_u_perm,
        input logic [2:0] t_s_perm,
        input logic       t_tt_bypass,
        input logic       exp_allow,
        input logic [4:0] exp_fault
    );
        begin
            req_r = t_req_r;
            req_w = t_req_w;
            req_x = t_req_x;
            is_user = t_is_user;
            u_perm = t_u_perm;
            s_perm = t_s_perm;
            tt_bypass = t_tt_bypass;

            if ((allow !== exp_allow) || (fault !== exp_fault)) begin
                $error("%s: allow exp=%0b got=%0b fault exp=%05b got=%05b",
                       name, exp_allow, allow, exp_fault, fault);
                errors++;
            end
        end
    endtask

    task automatic expect_decode_case(
        input string name,
        input logic [2:0] t_fc,
        input logic       exp_is_user,
        input logic       exp_is_super,
        input logic       exp_is_program,
        input logic       exp_is_data,
        input logic       exp_cpu_space
    );
        begin
            fc = t_fc;

            if ((decode_is_user !== exp_is_user) ||
                (decode_is_super !== exp_is_super) ||
                (decode_is_program !== exp_is_program) ||
                (decode_is_data !== exp_is_data) ||
                (decode_cpu_space !== exp_cpu_space)) begin
                $error("%s: FC=%03b exp(U=%0b S=%0b P=%0b D=%0b CPU=%0b) got(U=%0b S=%0b P=%0b D=%0b CPU=%0b)",
                       name, t_fc,
                       exp_is_user, exp_is_super, exp_is_program, exp_is_data, exp_cpu_space,
                       decode_is_user, decode_is_super, decode_is_program, decode_is_data, decode_cpu_space);
                errors++;
            end
        end
    endtask

    always_comb begin
        ref_model(req_r, req_w, req_x,
                  is_user, u_perm, s_perm, tt_bypass,
                  r_allow, r_fault);
    end

    initial begin
        $display("[perm_check_tb] Starting Motorola decode + permission checks...");

        errors = 0;
        req_r = 1'b0;
        req_w = 1'b0;
        req_x = 1'b0;
        is_user = 1'b0;
        u_perm = 3'b000;
        s_perm = 3'b000;
        tt_bypass = 1'b0;
        fc = 3'b000;

        // Directed Motorola FC decode cases.
        expect_decode_case("user data FC",        3'b001, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0);
        expect_decode_case("user program FC",     3'b010, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0);
        expect_decode_case("supervisor data FC",  3'b101, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0);
        expect_decode_case("supervisor program FC", 3'b110, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0);
        expect_decode_case("cpu space FC",        3'b111, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1);
        expect_decode_case("reserved user FC",    3'b000, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0);
        expect_decode_case("reserved super FC",   3'b100, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0);

        // Directed permission checks for Motorola-relevant corner cases.
        expect_perm_case("user read allowed",
                         1'b1, 1'b0, 1'b0, 1'b1, 3'b001, 3'b001, 1'b0,
                         1'b1, 5'b00000);
        expect_perm_case("user read denied",
                         1'b1, 1'b0, 1'b0, 1'b1, 3'b000, 3'b000, 1'b0,
                         1'b0, FAULT_NO_READ);
        expect_perm_case("user write protect fault",
                         1'b0, 1'b1, 1'b0, 1'b1, 3'b101, 3'b111, 1'b0,
                         1'b0, FAULT_WR_PROT | FAULT_PRIV_REL);
        expect_perm_case("user access supervisor-only mapping",
                         1'b1, 1'b0, 1'b0, 1'b1, 3'b000, 3'b001, 1'b0,
                         1'b0, FAULT_NO_READ | FAULT_PRIV_REL);
        expect_perm_case("supervisor access supervisor mapping",
                         1'b1, 1'b0, 1'b0, 1'b0, 3'b000, 3'b001, 1'b0,
                         1'b1, 5'b00000);
        expect_perm_case("user fetch execute denied",
                         1'b0, 1'b0, 1'b1, 1'b1, 3'b001, 3'b101, 1'b0,
                         1'b0, FAULT_NO_EXEC | FAULT_PRIV_REL);
        expect_perm_case("user fetch execute allowed",
                         1'b0, 1'b0, 1'b1, 1'b1, 3'b100, 3'b100, 1'b0,
                         1'b1, 5'b00000);
        expect_perm_case("cpu-space style TT bypass still requires valid request",
                         1'b0, 1'b0, 1'b0, 1'b0, 3'b000, 3'b000, 1'b1,
                         1'b0, FAULT_BAD_REQ);
        expect_perm_case("TT bypass suppresses valid permission fault",
                         1'b1, 1'b0, 1'b0, 1'b1, 3'b000, 3'b001, 1'b1,
                         1'b1, 5'b00000);
        expect_perm_case("bad multi-request encoding",
                         1'b1, 1'b1, 1'b0, 1'b1, 3'b111, 3'b111, 1'b0,
                         1'b0, FAULT_BAD_REQ);

        for (int su = 0; su < 2; su++) begin
            is_user = su[0];
            for (int reqv = 0; reqv < 8; reqv++) begin
                {req_x, req_w, req_r} = reqv[2:0];

                for (int upv = 0; upv < 8; upv++) begin
                    u_perm = upv[2:0];
                    for (int spv = 0; spv < 8; spv++) begin
                        s_perm = spv[2:0];
                        for (int tt = 0; tt < 2; tt++) begin
                            tt_bypass = tt[0];

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

        if (errors == 0)
            $display("[perm_check_tb] PASS - all directed and exhaustive checks matched.");
        else
            $display("[perm_check_tb] FAIL - %0d mismatches.", errors);

        $finish;
    end

endmodule
