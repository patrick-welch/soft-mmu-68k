# MTC1 Human-Guided MATLAB Workflow — Step 3

**Packet:** MTC1
**Branch:** `matlab/mtc1-tc-crp-span-reference`
**Goal of this step:** validate the resolved configuration and compute two derived values: `VPN_WIDTH` and `DESCR_BYTES`.

## What Step 2 proved

Your two useful results were exactly what we wanted:

```text
empty opts:
VA_WIDTH    = 24
PA_WIDTH    = 24
PAGE_SHIFT  = 12
DESCR_WIDTH = 64
FC_WIDTH    = 3
```

and:

```text
opts.va_width = 20
```

correctly overrode only `VA_WIDTH`, while the other defaults remained unchanged.

The earlier `struct with no fields` result was simply the pre-Step-2 stub behavior. The later calls confirm the saved function is now executing the new code.

## Step 3A — Add validation after the defaults

In `mmu_tc_crp_span_reference.m`, locate the last default block:

```matlab
    if ~isfield(opts, 'fc_width')
        opts.fc_width = 3;
    end
```

Immediately after that block, add:

```matlab
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
```

## What the new MATLAB is doing

A few pieces are worth understanding:

```matlab
opts.va_width ~= fix(opts.va_width)
```

checks whether the value has a fractional part. For example:

```text
24    -> valid integer
24.5  -> rejected
```

This:

```matlab
vpn_width = opts.va_width - opts.page_shift;
```

implements the packet relationship:

```text
VPN_WIDTH = VA_WIDTH - PAGE_SHIFT
```

With our defaults:

```text
24 - 12 = 12
```

And:

```matlab
descr_bytes = opts.descr_width / 8;
```

converts descriptor width from bits into bytes:

```text
64 bits / 8 = 8 bytes
```

Finally:

```matlab
bitand(uint64(descr_bytes), uint64(descr_bytes - 1)) ~= 0
```

is a standard integer test for "not a power of two."

For the default eight-byte descriptor:

```text
8  = binary 1000
7  = binary 0111
AND             0000
```

so 8 passes.

## Step 3B — Expand the temporary result structure

Replace the current temporary `R = struct(...)` block with:

```matlab
    R = struct( ...
        'va_width',    opts.va_width, ...
        'pa_width',    opts.pa_width, ...
        'page_shift',  opts.page_shift, ...
        'descr_width', opts.descr_width, ...
        'fc_width',    opts.fc_width, ...
        'vpn_width',   vpn_width, ...
        'descr_bytes', descr_bytes);
```

Save the file with **Ctrl+S**.

## Step 3C — Run only the normal default case

In the Command Window, run:

```matlab
R = mmu_tc_crp_span_reference( ...
    0, ...
    1, ...
    hex2dec('001000'), ...
    hex2dec('002000'), ...
    4, ...
    struct())
```

Expected result:

```text
va_width:     24
pa_width:     24
page_shift:   12
descr_width:  64
fc_width:     3
vpn_width:    12
descr_bytes:  8
```

## Stop point

Send back the displayed `R` result.

Do not run an invalid configuration yet. Once the valid case behaves correctly, the next step will intentionally trigger one validation error so you can see how MATLAB reports a controlled model failure.
