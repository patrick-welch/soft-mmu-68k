function [allow, fault] = mmu_perm_check_reference(req_r, req_w, req_x, is_user, u_perm, s_perm, tt_bypass)
%MMU_PERM_CHECK_REFERENCE Reference model for soft-mmu-68k perm_check.v.
%
%   [ALLOW, FAULT] = MMU_PERM_CHECK_REFERENCE(REQ_R, REQ_W, REQ_X,
%   IS_USER, U_PERM, S_PERM, TT_BYPASS) models the intended combinational
%   behavior of rtl/core/perm_check.v.
%
%   Permission bit convention, matching the project RTL draft:
%     bit 0 / MATLAB bitget(...,1): read  permission
%     bit 1 / MATLAB bitget(...,2): write permission
%     bit 2 / MATLAB bitget(...,3): exec  permission
%
%   FAULT is a uint8 bitfield:
%     bit 0: no_read
%     bit 1: write_protect
%     bit 2: no_execute
%     bit 3: privilege_related
%     bit 4: bad_req, meaning zero or multiple request type bits asserted
%
%   TT_BYPASS intentionally wins: ALLOW=1 and FAULT=0.

    req_r = logical(req_r);
    req_w = logical(req_w);
    req_x = logical(req_x);
    is_user = logical(is_user);
    tt_bypass = logical(tt_bypass);

    u_perm = uint8(u_perm);
    s_perm = uint8(s_perm);

    if tt_bypass
        allow = true;
        fault = uint8(0);
        return;
    end

    req_count = double(req_r) + double(req_w) + double(req_x);
    bad_req = (req_count ~= 1);

    if is_user
        act_perm = u_perm;
    else
        act_perm = s_perm;
    end

    can_r = logical(bitget(act_perm, 1));
    can_w = logical(bitget(act_perm, 2));
    can_x = logical(bitget(act_perm, 3));

    sup_r = logical(bitget(s_perm, 1));
    sup_w = logical(bitget(s_perm, 2));
    sup_x = logical(bitget(s_perm, 3));

    no_read = req_r && ~can_r;
    write_protect = req_w && ~can_w;
    no_execute = req_x && ~can_x;

    privilege_related = is_user && ( ...
        (req_r && ~can_r && sup_r) || ...
        (req_w && ~can_w && sup_w) || ...
        (req_x && ~can_x && sup_x));

    allow = ~bad_req && ( ...
        (req_r && can_r) || ...
        (req_w && can_w) || ...
        (req_x && can_x));

    fault = uint8(0);
    fault = bitor(fault, uint8(no_read)          * uint8(1));
    fault = bitor(fault, uint8(write_protect)    * uint8(2));
    fault = bitor(fault, uint8(no_execute)       * uint8(4));
    fault = bitor(fault, uint8(privilege_related)* uint8(8));
    fault = bitor(fault, uint8(bad_req)          * uint8(16));
end
