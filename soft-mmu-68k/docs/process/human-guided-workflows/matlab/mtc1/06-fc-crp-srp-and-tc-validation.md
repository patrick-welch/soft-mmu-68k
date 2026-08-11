# MTC1 Human-Guided MATLAB Workflow — Step 6

**Packet:** MTC1
**Branch:** `matlab/mtc1-tc-crp-span-reference`
**Goal of this step:** validate and preserve the remaining scalar inputs: `fc`, `crp`, `srp`, and `tc`.

## What Step 5 proved

The address split is correct for:

```text
VA = 0x012345
```

with the default 4 KiB page size:

```text
VPN         = 0x012 = 18
PAGE_OFFSET = 0x345 = 837
```

So the model is now correctly separating the virtual-page number from the page offset.

Before we use the other inputs in TC/span arithmetic, we will validate them the same way: accept only finite nonnegative integer scalars that fit their configured widths.

## Step 6A — Validate `fc`

In `mmu_tc_crp_span_reference.m`, place the following block after the virtual-address split code and before the temporary `R = struct(...)` block:

```matlab
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
```

### What this means

The default packet configuration is:

```text
FC_WIDTH = 3
```

so the valid numeric range is:

```text
0 through 7
```

MTC1 is not interpreting the Motorola meaning of every function-code value here. We are only ensuring that the supplied value fits the current configured field width.

## Step 6B — Validate `crp` and `srp`

Immediately after the `fc` block, add:

```matlab
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
```

### Why both roots are validated

For current MTC1 behavior:

```text
ROOT_SOURCE = CRP
SRP_USED    = false
```

SRP is intentionally inert in the current traversal path, but it is still an input to the reference model. Validating and preserving it lets later directed cases prove explicitly that changing SRP does not change the current result.

Because MTC1 constrains:

```text
PA_WIDTH <= 32
```

the PA-width calculation above is safely representable in `uint64`.

## Step 6C — Validate the 32-bit TC register image

Immediately after the root-pointer validation, add:

```matlab
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
```

For MTC1, `TC` is therefore treated as a complete 32-bit register image, even though only its low `VPN_WIDTH` bits will be used by the current single-level span model.

## Step 6D — Preserve the validated inputs in the temporary result

Replace the current temporary `R = struct(...)` block with:

```matlab
    R = struct( ...
        'va_width',    opts.va_width, ...
        'pa_width',    opts.pa_width, ...
        'page_shift',  opts.page_shift, ...
        'descr_width', opts.descr_width, ...
        'fc_width',    opts.fc_width, ...
        'vpn_width',   vpn_width, ...
        'descr_bytes', descr_bytes, ...
        'va',          va_u, ...
        'fc',          fc_u, ...
        'crp',         crp_u, ...
        'srp',         srp_u, ...
        'tc',          tc_u, ...
        'vpn',         vpn, ...
        'page_offset', page_offset);
```

Save with **Ctrl+S**.

## Step 6E — Run the same visible-address test

In the Command Window, run:

```matlab
R = mmu_tc_crp_span_reference( ...
    hex2dec('012345'), ...
    1, ...
    hex2dec('001000'), ...
    hex2dec('002000'), ...
    4, ...
    struct())
```

Expected new fields:

```text
fc:   1
crp:  4096
srp:  8192
tc:   4
```

while the previously verified fields remain:

```text
vpn:         18
page_offset: 837
```

## Stop point

Send back the displayed `R` result or the exact MATLAB error.

Do not add TC span extraction yet.

Once this passes, Step 7 will implement the first specifically TC-related behavior:

```text
TABLE_ENTRIES = low VPN_WIDTH bits of TC
IN_RANGE      = VPN < TABLE_ENTRIES
```
