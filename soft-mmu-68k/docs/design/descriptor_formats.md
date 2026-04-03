# Descriptor Formats (68851/030 lineage)

**Scope**
- `descriptor_pack` now defaults to a Motorola-aligned 64-bit long-format
  subset for root, pointer, and page descriptors.
- This document describes `descriptor_pack` only.
- It does not claim that the full translation datapath has already migrated to
  Motorola long-format descriptors end to end.

**Implemented long-format subset in `descriptor_pack`**
- Root descriptor:
  `[63]` = `L/U` via legacy `r_i_*`
  `[62:48]` = `LIMIT`
  `[33:32]` = `DT`
  `[31:4]` = root table address
  other bits are written as zero in this subset
- Pointer descriptor:
  `[63]` = `L/U` via legacy `p_i_*`
  `[62:48]` = `LIMIT`
  `[33:32]` = `DT`
  `[31:4]` = next-table address
  other bits are written as zero in this subset
- Page descriptor:
  `[40]` = `S`
  `[38]` = `CI`
  `[36]` = `M`
  `[35]` = `U`
  `[34]` = `WP`
  `[33:32]` = `DT`
  `[31:8]` = page base physical address
  other bits are written as zero in this subset

**Compatibility shims kept for the existing port list**
- `*_v_*` is not stored as a standalone Motorola bit. Validity is encoded by
  `DT != 2'b00`.
- On pack, `*_v_i == 0` forces `DT` to `00`.
- On unpack, `*_v_o` is derived as `(DT != 2'b00)`.
- `r_i_*` and `p_i_*` carry Motorola `L/U`, because the earlier standalone
  invalid-bit interpretation does not match the Motorola long-format layouts.

**What this does and does not mean for the current repo**
- `descriptor_pack` is Motorola-aligned for the subset above.
- The current first-pass walker and Basys 3 smoke harness still use their own
  compact 32-bit page-descriptor image for translated access/probe behavior.
- That split is intentional in the current repo state: the descriptor-format
  packet landed without claiming a full datapath migration.

**Why this is still a subset**
- The module's external port list does not expose every Motorola long-format
  field.
- Missing fields include, depending on descriptor kind: `SG`, access-level
  fields, gate/lock controls, and other reserved or software-defined bits.
- Those fields are packed as zero so the module remains combinational and keeps
  its existing external interface.

**68851 vs 68030 deltas recorded for this subset**
- `MC68851` long-format descriptors include additional fields such as `SG`,
  access-level controls, and page gate/lock semantics.[^68851-UM-5.1.5.3]
- `MC68030` removes or internalizes several MC68851-only features, including
  root-pointer-table aliases and externally programmable lockable/shared-global
  ATC behavior.[^68030-UM-9.7]
- Practical implication for this module:
  the current default maps the common visible subset shared across the manuals
  for `L/U`, `LIMIT`, `DT`, address placement, and page protection/history
  bits, while leaving unsupported fields zeroed.

**Manual-driven notes per descriptor**
- Root descriptor:
  both the 68851 and 68030 place `L/U` and `LIMIT` in the upper control word
  and `DT` in bits `[33:32]` for the root-pointer descriptor.[^68851-UM-6.1.1][^68030-UM-9.5.1.2]
- Pointer descriptor:
  this packet treats the pointer descriptor as the long-format table-descriptor
  subset: upper-word `L/U` and `LIMIT`, lower-word `DT` plus table address.[^68851-UM-5.1.5.2.1][^68030-UM-9.5.1.3]
- Page descriptor:
  the page descriptor mapping follows the Motorola long-format page descriptor
  locations for `S`, `CI`, `M`, `U`, `WP`, `DT`, and page address.[^68851-UM-5.1.5.3][^68030-UM-9.5.1.7]

**Known issues / bring-up notes**
- Do not describe the current repo as using Motorola long-format descriptors
  throughout the live translation datapath; that is not implemented yet.
- The Basys 3 smoke demo proves the integrated first-pass datapath subset, but
  that datapath is still using a compact responder/walker page format rather
  than feeding `descriptor_pack` long-format descriptors through end to end.
- If a later packet migrates the walker or TLB refill path, this document should
  be updated together with the datapath docs so the two views stay aligned.

**Known TODOs**
- Add the remaining long-format fields if the surrounding MMU pipeline needs
  them.
- Decide whether a separate short-format mode is needed, or whether the project
  should standardize on long-format descriptors at this boundary.
- If external users depend on 32-bit packed descriptors, add an explicit
  compatibility mode rather than relying on the older placeholder layout.

[^68851-UM-5.1.5.2.1]: Motorola MC68851 PMMU User's Manual, Section 5.1.5.2.1 "Table Descriptors".
[^68851-UM-5.1.5.3]: Motorola MC68851 PMMU User's Manual, Section 5.1.5.3 "Descriptor Field Definitions".
[^68851-UM-6.1.1]: Motorola MC68851 PMMU User's Manual, Section 6.1.1 "Root Pointer".
[^68030-UM-9.5.1.2]: Motorola MC68030 User's Manual, Section 9.5.1.2 "Root Pointer Descriptor".
[^68030-UM-9.5.1.3]: Motorola MC68030 User's Manual, Section 9.5.1.3 "Short-Format Table Descriptor" and the accompanying long-format table-descriptor figure in Section 9.5.1.4.
[^68030-UM-9.5.1.7]: Motorola MC68030 User's Manual, Sections 9.5.1.5-9.5.1.8 for page and early-termination page descriptors, plus Section 9.5.1.1 "Descriptor Field Definitions".
[^68030-UM-9.7]: Motorola MC68030 User's Manual, Section 9.7 "MC68030 and MC68851 MMU Differences".
