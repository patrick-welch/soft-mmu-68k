# MTC1 Human-Guided MATLAB Workflow — Step 2

**Packet:** MTC1
**Branch:** `matlab/mtc1-tc-crp-span-reference`
**Goal of this step:** add and inspect the model's default configuration handling.

## What we just proved

The first call returned:

```text
struct with no fields.
```

That is a successful result for the stub. It proves MATLAB:

- found the function on the search path;
- parsed the function declaration;
- accepted all six input arguments;
- executed the function body;
- returned the value assigned to `R`.

We can now build the model in small pieces.

## Step 2A — Replace the temporary stub body

In the MATLAB Editor, find this line:

```matlab
    R = struct();
```

Replace only that line with:

```matlab
    if nargin < 6 || isempty(opts)
        opts = struct();
    end

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

    R = struct( ...
        'va_width',    opts.va_width, ...
        'pa_width',    opts.pa_width, ...
        'page_shift',  opts.page_shift, ...
        'descr_width', opts.descr_width, ...
        'fc_width',    opts.fc_width);
```

Leave the existing function declaration, comment, and final `end` in place.

Save with **Ctrl+S**.

## What this MATLAB means

`nargin` is MATLAB's count of how many input arguments were supplied to the function.

This line:

```matlab
if nargin < 6 || isempty(opts)
```

means:

```text
if the caller did not supply opts
OR
the caller supplied opts but it is empty
```

then:

```matlab
opts = struct();
```

creates an empty options structure.

Each block such as:

```matlab
if ~isfield(opts, 'va_width')
    opts.va_width = 24;
end
```

means:

```text
if opts does not already contain a field named va_width,
create that field and assign the default value 24.
```

This is how we preserve caller overrides while providing packet-approved defaults.

The final `R = struct(...)` is temporary scaffolding for this learning step. It lets us inspect the resolved configuration before we add address arithmetic.

## Step 2B — Run the same call again

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
R =

  struct with fields:

       va_width: 24
       pa_width: 24
      page_shift: 12
     descr_width: 64
        fc_width: 3
```

Field spacing may differ; the values are what matter.

## Step 2C — Prove that an option can override a default

Then run:

```matlab
opts = struct();
opts.va_width = 20;

R2 = mmu_tc_crp_span_reference( ...
    0, ...
    1, ...
    hex2dec('001000'), ...
    hex2dec('002000'), ...
    4, ...
    opts)
```

Expected key result:

```text
R2.va_width = 20
```

while the other defaults remain:

```text
pa_width    = 24
page_shift  = 12
descr_width = 64
fc_width    = 3
```

## Stop point

Please return:

1. the displayed `R` result using an empty `struct()`;
2. the displayed `R2` result using `opts.va_width = 20`.

We will review those before adding validation.
