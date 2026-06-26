function T = generate_perm_check_vectors(out_file)
%GENERATE_PERM_CHECK_VECTORS Generate exhaustive CSV golden vectors.
%
%   T = GENERATE_PERM_CHECK_VECTORS() writes ../vectors/perm_check_golden_vectors.csv
%   relative to this file and returns the table.
%
%   T = GENERATE_PERM_CHECK_VECTORS(OUT_FILE) writes to the supplied path.
%
%   This intentionally covers invalid request combinations too:
%     req_code bit 0 = req_r
%     req_code bit 1 = req_w
%     req_code bit 2 = req_x

    here = fileparts(mfilename('fullpath'));
    if nargin < 1 || strlength(string(out_file)) == 0
        out_file = fullfile(here, '..', 'vectors', 'perm_check_golden_vectors.csv');
    end

    out_dir = fileparts(out_file);
    if ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end

    n = 2 * 8 * 8 * 8 * 2;
    is_user_col   = false(n, 1);
    req_code_col  = zeros(n, 1, 'uint8');
    req_r_col     = false(n, 1);
    req_w_col     = false(n, 1);
    req_x_col     = false(n, 1);
    u_perm_col    = zeros(n, 1, 'uint8');
    s_perm_col    = zeros(n, 1, 'uint8');
    tt_bypass_col = false(n, 1);
    allow_col     = false(n, 1);
    fault_col     = zeros(n, 1, 'uint8');

    row = 0;
    for is_user = [false true]
        for req_code = uint8(0):uint8(7)
            req_r = logical(bitget(req_code, 1));
            req_w = logical(bitget(req_code, 2));
            req_x = logical(bitget(req_code, 3));
            for u_perm = uint8(0):uint8(7)
                for s_perm = uint8(0):uint8(7)
                    for tt_bypass = [false true]
                        row = row + 1;
                        [allow, fault] = mmu_perm_check_reference(req_r, req_w, req_x, is_user, u_perm, s_perm, tt_bypass);

                        is_user_col(row)   = is_user;
                        req_code_col(row)  = req_code;
                        req_r_col(row)     = req_r;
                        req_w_col(row)     = req_w;
                        req_x_col(row)     = req_x;
                        u_perm_col(row)    = u_perm;
                        s_perm_col(row)    = s_perm;
                        tt_bypass_col(row) = tt_bypass;
                        allow_col(row)     = allow;
                        fault_col(row)     = fault;
                    end
                end
            end
        end
    end

    T = table(is_user_col, req_code_col, req_r_col, req_w_col, req_x_col, ...
              u_perm_col, s_perm_col, tt_bypass_col, allow_col, fault_col, ...
              'VariableNames', {'is_user','req_code','req_r','req_w','req_x', ...
                                'u_perm','s_perm','tt_bypass','allow','fault'});

    writetable(T, out_file);
    fprintf('Wrote %d golden vectors to %s\n', height(T), out_file);
end
