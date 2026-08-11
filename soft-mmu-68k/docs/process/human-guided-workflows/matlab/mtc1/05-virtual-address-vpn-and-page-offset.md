# MTC1 Human-Guided MATLAB Workflow — Step 5

**Packet:** MTC1
**Branch:** `matlab/mtc1-tc-crp-span-reference`
**Goal of this step:** validate the virtual address and split it into VPN and page offset.

## What Step 4 proved

The normal default configuration still passes after the added guards:

```text
VA_WIDTH    = 24
PA_WIDTH    = 24
PAGE_SHIFT  = 12
DESCR_WIDTH = 64
FC_WIDTH    = 3
VPN_WIDTH   = 12
DESCR_BYTES = 8
```

That means our configuration scaffolding is stable enough to begin modeling the address itself.

## Step 5A — Add virtual-address validation

In `mmu_tc_crp_span_reference.m`, find the point after the descriptor-size validation, after this block:

```matlab
    if bitand(uint64(descr_bytes), uint64(descr_bytes - 1)) ~= 0
        error('MTC1:BadDescrWidth', ...
            'DESCR_BYTES must be a power of two.');
    end
```

Immediately after it, add:

```matlab
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
```

## What this does

The first block requires `va` to be:

```text
numeric
scalar
real
finite
an integer
nonnegative
```

The `flintmax` check matters because ordinary MATLAB `double` values cannot represent every integer once the number gets very large. We do not want a reference model silently accepting an already-rounded address.

Then:

```matlab
va_u = uint64(va);
```

gives us an unsigned 64-bit integer representation for the bit operations that follow.

The `max_va` calculation enforces the configured `VA_WIDTH`.

For the normal default:

```text
VA_WIDTH = 24
```

the largest legal address is:

```text
0xFFFFFF
```

## Step 5B — Split the virtual address

Immediately after the VA validation above, add:

```matlab
    vpn = bitshift(va_u, -opts.page_shift);

    if opts.page_shift == 0
        page_offset = uint64(0);
    else
        page_mask = bitshift(uint64(1), opts.page_shift) - uint64(1);
        page_offset = bitand(va_u, page_mask);
    end
```

## What the split means

With the default:

```text
VA_WIDTH   = 24
PAGE_SHIFT = 12
```

the virtual address is conceptually:

```text
+-------------+-------------+
|   VPN       | page offset |
|  12 bits    |   12 bits   |
+-------------+-------------+
```

This line:

```matlab
vpn = bitshift(va_u, -opts.page_shift);
```

shifts the address right by 12 bits, discarding the page offset.

This:

```matlab
page_mask = bitshift(uint64(1), opts.page_shift) - uint64(1);
```

builds a mask containing twelve low `1` bits:

```text
0xFFF
```

Then:

```matlab
page_offset = bitand(va_u, page_mask);
```

keeps only those low twelve bits.

## Step 5C — Add the two values to the temporary result

Replace your current `R = struct(...)` block with:

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
        'vpn',         vpn, ...
        'page_offset', page_offset);
```

Save with **Ctrl+S**.

## Step 5D — Use an address that makes the split visible

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

We deliberately chose:

```text
VA = 0x012345
```

With 4 KiB pages (`PAGE_SHIFT = 12`), we expect:

```text
VPN         = 0x012 = 18 decimal
page_offset = 0x345 = 837 decimal
```

So the new fields should show:

```text
va:          74565
vpn:         18
page_offset: 837
```

## Stop point

Send back the displayed `R` result.

Do not add TC-span or descriptor-address logic yet. Once this split is correct, the next step will validate the remaining scalar inputs (`fc`, `crp`, `srp`, and `tc`) before we use them.
