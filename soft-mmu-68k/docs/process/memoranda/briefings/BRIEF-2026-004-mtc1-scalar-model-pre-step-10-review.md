# BRIEF-2026-004 — MTC1 Scalar Model Pre-Step-10 Review

## Repository record metadata

- **Title:** MTC1 Scalar Model Review — Before Step 10
- **Source date:** Unknown / not stated in the preserved source
- **Originating role:** MMU MATLAB Toolchain Coach
- **Recipient / decision role:** Project Lead / MMU Dev Manager
- **Record status:** Source briefing
- **Related packet:** MTC1
- **Related implementation:** PR #40
- **Provenance:** Preserved from Project Lead-supplied local MTC1 working collateral

## Preservation note

The material between the markers below is the preserved source body. The metadata and preservation note above were added for repository recordkeeping and are not part of the original Toolchain Coach source. This briefing is decision input; it is not itself the final MTC1 approval.

<!-- BEGIN PRESERVED SOURCE BODY -->
# MTC1 Scalar Model Review — Before Step 10

**Packet:** MTC1
**Branch:** `matlab/mtc1-tc-crp-span-reference`
**Status:** Step 9 behavior verified; one implementation-constraint decision remains before final scalar-model cleanup.

## Step 9 verification

The three Step 9 checks behaved correctly:

```text
Last in-range VPN:
    descriptor_request    = 1
    descriptor_addr_valid = 1
    descriptor_addr       = 4120 (0x001018)

First out-of-range VPN:
    descriptor_request    = 0
    descriptor_addr_valid = 0
    descriptor_addr       = 0
    prewalk_fault         = "unmapped_span"

PA-width overflow:
    rejected with:
    "Descriptor address does not fit in the configured PA_WIDTH."
```

This completes the scalar model's required MTC1 behavior:

```text
VPN
PAGE_OFFSET
VPN_WIDTH
TABLE_ENTRIES
IN_RANGE
ROOT_SOURCE
SRP_USED
DESCRIPTOR_REQUEST
PREWALK_FAULT
DESCRIPTOR_ADDR_VALID
DESCRIPTOR_ADDR
PA-width overflow rejection
```

## Result-schema cleanup

The canonical packet approves these result fields:

```text
va
fc
crp
srp
tc
va_width
pa_width
page_shift
vpn_width
descr_bytes
vpn
page_offset
table_entries
in_range
descriptor_request
descriptor_addr_valid
descriptor_addr
root_source
srp_used
prewalk_fault
```

Our current temporary result also returns:

```text
descr_width
fc_width
```

Those two fields are useful configuration inputs but are not in the approved result schema.

**Recommended Step 10 cleanup:** keep `descr_width` and `fc_width` as options/validation inputs, but remove them from `R` so the returned structure matches the approved packet schema exactly.

## Implementation-constraint decision needed

During Step 4 we added:

```text
VA_WIDTH <= 64
FC_WIDTH <= 64
```

These are not architectural MTC1 configuration limits from the canonical packet. They arose because the current MATLAB implementation uses `uint64` for integer-safe scalar and bit arithmetic.

They therefore must not silently become MMU or Motorola constraints.

### Recommended disposition

Retain both limits as **MATLAB implementation representation constraints only**, and document them in the model/README and eventual PR as items for DEV Manager dispensation:

```text
VA_WIDTH <= 64
    MATLAB scalar implementation limit caused by uint64 representation.
    Not an MC68851 architectural claim.

FC_WIDTH <= 64
    MATLAB scalar implementation limit caused by uint64 representation.
    Not an MC68851 architectural claim.
```

This is the smallest implementation consistent with the current model and does not affect the project's normal MTC1 configuration:

```text
VA_WIDTH = 24
FC_WIDTH = 3
```

The alternative is to rework the scalar representation to support widths beyond 64 bits, which is outside the practical needs of this packet unless explicitly desired.

## Decision requested

Please choose:

```text
A — APPROVE the recommended implementation-only <=64 limits and document them for DEV Manager dispensation.

B — DO NOT APPROVE; rework the MATLAB numeric representation so those limits are unnecessary.
```

If **A** is approved, Step 10 will be a small cleanup only:

```text
- add a Step 10 comment;
- remove descr_width and fc_width from R;
- reorder R to the canonical approved field order;
- run one normal call and inspect fieldnames(R).
```

No generator work will begin until the scalar-model schema is aligned.
<!-- END PRESERVED SOURCE BODY -->
