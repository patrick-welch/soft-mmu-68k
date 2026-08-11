# MTC1 Human-Guided MATLAB Workflow — Step 9

**Packet:** MTC1
**Branch:** `matlab/mtc1-tc-crp-span-reference`
**Goal of this step:** calculate the descriptor address for an in-range VPN, expose its validity flag, and reject PA-width overflow.

## New annotation convention

Starting with this step, each new implementation section will begin with a MATLAB comment that records the workflow step and its purpose.

For Step 9, use:

```matlab
    % Step 9: Calculate and validate the current CRP-based descriptor address.
```

We will keep using this convention for every new section from here forward.

After the model is complete, the earlier sections can be back-annotated in one cleanup pass rather than interrupting the current implementation flow.

## What Step 8 proved

The pre-walk control behavior is correct on both sides of the span boundary:

```text
VPN = 3:
    IN_RANGE           = 1
    DESCRIPTOR_REQUEST = 1
    ROOT_SOURCE        = "CRP"
    SRP_USED           = 0
    PREWALK_FAULT      = "none"

VPN = 4:
    IN_RANGE           = 0
    DESCRIPTOR_REQUEST = 0
    ROOT_SOURCE        = "CRP"
    SRP_USED           = 0
    PREWALK_FAULT      = "unmapped_span"
```

An in-range result still means only that a descriptor read is permitted.

## Repository and packet anchor

The current RTL walker forms the request address from the table base plus the VPN scaled by descriptor size.

The MTC1 packet defines the reference behavior as:

```text
DESCRIPTOR_ADDR = CRP + VPN * DESCR_BYTES, when IN_RANGE
```

and requires:

```text
DESCRIPTOR_ADDR_VALID = DESCRIPTOR_REQUEST
```

If the resulting descriptor address cannot be represented in the selected `PA_WIDTH`, MTC1 must reject the case rather than wrap the address.

## Step 9A — Add descriptor-address calculation

In `mmu_tc_crp_span_reference.m`, place this section after the Step 8 pre-walk control logic and before `R = struct(...)`:

```matlab
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
```

## Why the overflow check comes before the arithmetic

The obvious expression would be:

```matlab
descriptor_addr = crp_u + vpn * uint64(descr_bytes);
```

but a reference model should not first perform an arithmetic operation that might overflow and only inspect the wrapped result afterward.

Instead, for nonzero VPNs we calculate the largest VPN that can still fit:

```text
MAX_VPN_FOR_ADDR =
    floor((MAX_PA - CRP) / DESCR_BYTES)
```

Then:

```text
VPN <= MAX_VPN_FOR_ADDR  -> arithmetic is safe
VPN >  MAX_VPN_FOR_ADDR  -> reject the configuration
```

Only after proving the result fits do we perform:

```matlab
descriptor_addr = crp_u + vpn * descr_bytes_u;
```

For `VPN = 0`, the formula reduces directly to:

```text
DESCRIPTOR_ADDR = CRP
```

so no multiplication is needed.

## Step 9B — Add the address fields to `R`

At the end of the current result structure, add:

```matlab
        'descriptor_addr_valid', descriptor_addr_valid, ...
        'descriptor_addr',       descriptor_addr, ...
```

A convenient final portion of the structure is:

```matlab
        'table_entries',         table_entries, ...
        'in_range',              in_range, ...
        'descriptor_request',    descriptor_request, ...
        'descriptor_addr_valid', descriptor_addr_valid, ...
        'descriptor_addr',       descriptor_addr, ...
        'root_source',           root_source, ...
        'srp_used',              srp_used, ...
        'prewalk_fault',         prewalk_fault);
```

Save with **Ctrl+S**.

## Step 9C — Verify the last in-range descriptor address

Run:

```matlab
Rlast = mmu_tc_crp_span_reference( ...
    hex2dec('003345'), ...
    1, ...
    hex2dec('001000'), ...
    hex2dec('002000'), ...
    4, ...
    struct())
```

The address arithmetic is:

```text
CRP         = 0x001000 = 4096
VPN         = 3
DESCR_BYTES = 8

offset = 3 * 8
       = 24
       = 0x18

DESCRIPTOR_ADDR = 0x001000 + 0x18
                = 0x001018
                = 4120
```

The important fields should therefore be:

```text
descriptor_request:    1
descriptor_addr_valid: 1
descriptor_addr:       4120
```

## Step 9D — Verify the out-of-range sentinel

Then run:

```matlab
Rout = mmu_tc_crp_span_reference( ...
    hex2dec('004345'), ...
    1, ...
    hex2dec('001000'), ...
    hex2dec('002000'), ...
    4, ...
    struct())
```

Because this VPN is out of range:

```text
descriptor_request:    0
descriptor_addr_valid: 0
descriptor_addr:       0
```

The zero address is only a sentinel. `descriptor_addr_valid = 0` tells the caller that the address is not meaningful.

## Step 9E — Deliberately test PA-width overflow

After the two normal cases pass, run:

```matlab
opts = struct();
opts.pa_width = 13;

Roverflow = mmu_tc_crp_span_reference( ...
    hex2dec('001000'), ...
    1, ...
    hex2dec('001FF8'), ...
    0, ...
    2, ...
    opts)
```

For a 13-bit physical address:

```text
MAX_PA      = 0x1FFF = 8191
CRP         = 0x1FF8 = 8184
VPN         = 1
DESCR_BYTES = 8
```

The candidate descriptor address would be:

```text
0x1FF8 + 8 = 0x2000
```

which requires 14 bits and therefore cannot be represented by `PA_WIDTH = 13`.

Expected MATLAB error:

```text
Descriptor address does not fit in the configured PA_WIDTH.
```

## Stop point

Send back:

1. the displayed `Rlast` result;
2. the displayed `Rout` result;
3. the exact result of the intentional `Roverflow` test.

Do not start the generator yet.

Once these pass, we will review the scalar model against the packet's approved result fields and then decide the smallest next implementation step.
