function R = mmu_tc_crp_span_reference(va, fc, crp, srp, tc, opts)
%MMU_TC_CRP_SPAN_REFERENCE Reference model for the current TC1B span boundary.
% Step 1: Establish the scalar reference-model function entry point.

    % Step 2: Create the options structure when the caller omits it.
    if nargin < 6 || isempty(opts)
        opts = struct();
    end

    % Step 4: Require opts to be one scalar MATLAB structure.
    if ~isstruct(opts) || ~isscalar(opts)
        error('MTC1:BadOptions', ...
            'opts must be a scalar struct.');
    end

    % Step 2: Apply packet-approved defaults while preserving caller overrides.
    if ~isfield(opts, 'va_width')
        opts.va_width = 24;
    end

    if ~isfield(opts, 'pa_width')
        opts.pa_width = 24;
    end

    if ~isfield(opts, 'page_shift')
        opts.page_shift = 12;
    end

    if ~isfield(opts, 'descr_width')
        opts.descr_width = 64;
    end

    if ~isfield(opts, 'fc_width')
        opts.fc_width = 3;
    end

    % Step 4: Enforce basic range and MATLAB uint64 representation guards.
    % VA_WIDTH <= 64 and FC_WIDTH <= 64 are MATLAB scalar uint64
    % representation limits only. They are not MC68851 or SM68861
    % architectural limits.
    if opts.va_width < 1 || opts.va_width > 64
        error('MTC1:BadVAWidth', ...
            'VA_WIDTH must satisfy 1 <= VA_WIDTH <= 64.');
    end

    if opts.pa_width < 1 || opts.pa_width > 32
        error('MTC1:BadPAWidth', ...
            'PA_WIDTH must satisfy 1 <= PA_WIDTH <= 32.');
    end

    if opts.page_shift < 0
        error('MTC1:BadPageShift', ...
            'PAGE_SHIFT must be nonnegative.');
    end

    if opts.descr_width < 1
        error('MTC1:BadDescrWidth', ...
            'DESCR_WIDTH must be positive.');
    end

    if ~isscalar(opts.fc_width) || ~isnumeric(opts.fc_width) || ...
            ~isfinite(opts.fc_width) || opts.fc_width ~= fix(opts.fc_width) || ...
            opts.fc_width < 1 || opts.fc_width > 64
        error('MTC1:BadFCWidth', ...
            'FC_WIDTH must satisfy 1 <= FC_WIDTH <= 64.');
    end

    % Step 3: Validate configuration scalars and derive VPN/descriptor sizing.
    if ~isscalar(opts.va_width) || ~isnumeric(opts.va_width) || ...
            ~isfinite(opts.va_width) || opts.va_width ~= fix(opts.va_width)
        error('MTC1:BadVAWidth', ...
            'VA_WIDTH must be a finite integer scalar.');
    end

    if ~isscalar(opts.pa_width) || ~isnumeric(opts.pa_width) || ...
            ~isfinite(opts.pa_width) || opts.pa_width ~= fix(opts.pa_width)
        error('MTC1:BadPAWidth', ...
            'PA_WIDTH must be a finite integer scalar.');
    end

    if ~isscalar(opts.page_shift) || ~isnumeric(opts.page_shift) || ...
            ~isfinite(opts.page_shift) || opts.page_shift ~= fix(opts.page_shift)
        error('MTC1:BadPageShift', ...
            'PAGE_SHIFT must be a finite integer scalar.');
    end

    if ~isscalar(opts.descr_width) || ~isnumeric(opts.descr_width) || ...
            ~isfinite(opts.descr_width) || opts.descr_width ~= fix(opts.descr_width)
        error('MTC1:BadDescrWidth', ...
            'DESCR_WIDTH must be a finite integer scalar.');
    end

    if opts.va_width <= opts.page_shift
        error('MTC1:BadVAWidth', ...
            'VA_WIDTH must exceed PAGE_SHIFT.');
    end

    if opts.pa_width <= opts.page_shift
        error('MTC1:BadPAWidth', ...
            'PA_WIDTH must exceed PAGE_SHIFT.');
    end

    vpn_width = opts.va_width - opts.page_shift;

    if vpn_width < 1 || vpn_width > 32
        error('MTC1:BadVPNWidth', ...
            'VPN_WIDTH must satisfy 1 <= VPN_WIDTH <= 32.');
    end

    if opts.pa_width > 32
        error('MTC1:BadPAWidth', ...
            'PA_WIDTH must be <= 32.');
    end

    if opts.descr_width < 64
        error('MTC1:BadDescrWidth', ...
            'DESCR_WIDTH must be >= 64 for the current walker.');
    end

    if mod(opts.descr_width, 8) ~= 0
        error('MTC1:BadDescrWidth', ...
            'DESCR_WIDTH must be a multiple of 8 bits.');
    end

    descr_bytes = opts.descr_width / 8;

    if bitand(uint64(descr_bytes), uint64(descr_bytes - 1)) ~= 0
        error('MTC1:BadDescrWidth', ...
            'DESCR_BYTES must be a power of two.');
    end

    % Step 5: Validate VA, then split it into VPN and page offset.
    if ~isnumeric(va) || ~isscalar(va) || ~isreal(va) || ...
            ~isfinite(va) || va ~= fix(va) || va < 0
        error('MTC1:BadVA', ...
            'VA must be a finite nonnegative integer scalar.');
    end

    if isa(va, 'double') && va > flintmax
        error('MTC1:BadVA', ...
            'Double-precision VA values above flintmax are not exact.');
    end

    if opts.va_width == 64
        max_va = intmax('uint64');
    else
        max_va = bitshift(uint64(1), opts.va_width) - uint64(1);
    end

    va_u = uint64(va);

    if va_u > max_va
        error('MTC1:VAOutOfRange', ...
            'VA does not fit in the configured VA_WIDTH.');
    end

    vpn = bitshift(va_u, -opts.page_shift);

    if opts.page_shift == 0
        page_offset = uint64(0);
    else
        page_mask = bitshift(uint64(1), opts.page_shift) - uint64(1);
        page_offset = bitand(va_u, page_mask);
    end

    % Step 6: Validate and preserve FC, CRP, SRP, and the 32-bit TC image.
    if ~isnumeric(fc) || ~isscalar(fc) || ~isreal(fc) || ...
            ~isfinite(fc) || fc ~= fix(fc) || fc < 0
        error('MTC1:BadFC', ...
            'FC must be a finite nonnegative integer scalar.');
    end

    if isa(fc, 'double') && fc > flintmax
        error('MTC1:BadFC', ...
            'Double-precision FC values above flintmax are not exact.');
    end

    if opts.fc_width == 64
        max_fc = intmax('uint64');
    else
        max_fc = bitshift(uint64(1), opts.fc_width) - uint64(1);
    end

    fc_u = uint64(fc);

    if fc_u > max_fc
        error('MTC1:FCOutOfRange', ...
            'FC does not fit in the configured FC_WIDTH.');
    end

    if ~isnumeric(crp) || ~isscalar(crp) || ~isreal(crp) || ...
            ~isfinite(crp) || crp ~= fix(crp) || crp < 0
        error('MTC1:BadCRP', ...
            'CRP must be a finite nonnegative integer scalar.');
    end

    if ~isnumeric(srp) || ~isscalar(srp) || ~isreal(srp) || ...
            ~isfinite(srp) || srp ~= fix(srp) || srp < 0
        error('MTC1:BadSRP', ...
            'SRP must be a finite nonnegative integer scalar.');
    end

    max_pa = bitshift(uint64(1), opts.pa_width) - uint64(1);

    crp_u = uint64(crp);
    srp_u = uint64(srp);

    if crp_u > max_pa
        error('MTC1:CRPOutOfRange', ...
            'CRP does not fit in the configured PA_WIDTH.');
    end

    if srp_u > max_pa
        error('MTC1:SRPOutOfRange', ...
            'SRP does not fit in the configured PA_WIDTH.');
    end

    if ~isnumeric(tc) || ~isscalar(tc) || ~isreal(tc) || ...
            ~isfinite(tc) || tc ~= fix(tc) || tc < 0
        error('MTC1:BadTC', ...
            'TC must be a finite nonnegative integer scalar.');
    end

    tc_u = uint64(tc);
    max_tc = uint64(2^32 - 1);

    if tc_u > max_tc
        error('MTC1:TCOutOfRange', ...
            'TC must fit in the 32-bit register image.');
    end

    % Step 7: Extract TABLE_ENTRIES from low TC bits and test the VPN span.
    table_mask = bitshift(uint64(1), vpn_width) - uint64(1);
    table_entries = bitand(tc_u, table_mask);
    in_range = vpn < table_entries;

    % Step 8: Derive pre-walk request, root-source, and fault-status results.
    descriptor_request = in_range;
    root_source = "CRP";
    srp_used = false;

    if in_range
        prewalk_fault = "none";
    else
        prewalk_fault = "unmapped_span";
    end

    % Step 9: Calculate and validate the current CRP-based descriptor address.
    descriptor_addr_valid = descriptor_request;
    descriptor_addr = uint64(0);

    if descriptor_request
        if vpn == 0
            descriptor_addr = crp_u;
        else
            if descr_bytes > double(max_pa)
                error('MTC1:DescriptorAddrOverflow', ...
                    'Descriptor address does not fit in the configured PA_WIDTH.');
            end

            descr_bytes_u = uint64(descr_bytes);
            max_vpn_for_addr = idivide( ...
                max_pa - crp_u, descr_bytes_u, 'floor');

            if vpn > max_vpn_for_addr
                error('MTC1:DescriptorAddrOverflow', ...
                    'Descriptor address does not fit in the configured PA_WIDTH.');
            end

            descriptor_addr = crp_u + vpn * descr_bytes_u;
        end
    end

    % Step 10: Return the canonical MTC1 result schema in approved order.
    R = struct( ...
        'va',                    va_u, ...
        'fc',                    fc_u, ...
        'crp',                   crp_u, ...
        'srp',                   srp_u, ...
        'tc',                    tc_u, ...
        'va_width',              opts.va_width, ...
        'pa_width',              opts.pa_width, ...
        'page_shift',            opts.page_shift, ...
        'vpn_width',             vpn_width, ...
        'descr_bytes',           descr_bytes, ...
        'vpn',                   vpn, ...
        'page_offset',           page_offset, ...
        'table_entries',         table_entries, ...
        'in_range',              in_range, ...
        'descriptor_request',    descriptor_request, ...
        'descriptor_addr_valid', descriptor_addr_valid, ...
        'descriptor_addr',       descriptor_addr, ...
        'root_source',           root_source, ...
        'srp_used',              srp_used, ...
        'prewalk_fault',         prewalk_fault);

end