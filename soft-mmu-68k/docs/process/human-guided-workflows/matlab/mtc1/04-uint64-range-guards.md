# MTC1 Human-Guided MATLAB Workflow — Step 4

**Packet:** MTC1
**Branch:** `matlab/mtc1-tc-crp-span-reference`
**Goal of this step:** finish the basic configuration guards before we begin virtual-address arithmetic.

## What the 96-bit test proved

The result:

```text
DESCR_BYTES must be a power of two.
```

is exactly correct.

Together, our two deliberate negative tests now prove two separate guards:

```text
DESCR_WIDTH = 48  -> rejected because it is below the current 64-bit walker minimum
DESCR_WIDTH = 96  -> rejected because 96/8 = 12 bytes, and 12 is not a power of two
```

We will report those as separate validation checks in the eventual MTC1 PR.

## Step 4A — Make sure `opts` really is a structure

Near the top of the function you currently have:

```matlab
    if nargin < 6 || isempty(opts)
        opts = struct();
    end
```

Immediately after that block, add:

```matlab
    if ~isstruct(opts) || ~isscalar(opts)
        error('MTC1:BadOptions', ...
            'opts must be a scalar struct.');
    end
```

### What this means

`isstruct(opts)` asks:

```text
Is opts a MATLAB structure?
```

`isscalar(opts)` asks:

```text
Is it one structure rather than an array of structures?
```

The `~` means logical NOT.

So:

```matlab
~isstruct(opts) || ~isscalar(opts)
```

means:

```text
if opts is not a structure
OR
opts is not scalar
```

then stop with a controlled error.

## Step 4B — Add simple range guards

Do not rewrite the validation you already entered.

After the four existing scalar/integer validation blocks for:

```text
va_width
pa_width
page_shift
descr_width
```

add these guards:

```matlab
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
```

Leave the later existing checks in place, including:

```matlab
if opts.va_width <= opts.page_shift
```

and:

```matlab
if opts.pa_width <= opts.page_shift
```

Those test a different rule: the address width must exceed the page-offset width.

## Step 4C — Save and rerun the normal case

Save with **Ctrl+S**.

Then run:

```matlab
R = mmu_tc_crp_span_reference( ...
    0, ...
    1, ...
    hex2dec('001000'), ...
    hex2dec('002000'), ...
    4, ...
    struct())
```

The result should remain:

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

Send back only the displayed `R` result or the MATLAB error.

If the valid configuration still passes, Step 5 will be our first actual address-modeling work: extracting the VPN and page offset from a virtual address.
