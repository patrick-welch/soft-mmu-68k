# Descriptor Formats (68851/030 lineage)

**Scope**
- `descriptor_pack` now defaults to a Motorola-aligned 64-bit subset for root, pointer, and page descriptors.
- This packet is intentionally narrow: descriptor bit placement only. No walker, TLB, or top-level policy changes.

**Implemented mapping**
- Root descriptor:
  `[63]` = `L/U` via legacy `r_i_*`
  `[62:48]` = `LIMIT`
  `[33:32]` = `DT`
  `[31:4]` = root table address
  Other bits are written as zero in this first pass.
- Pointer descriptor:
  `[63]` = `L/U` via legacy `p_i_*`
  `[62:48]` = `LIMIT`
  `[33:32]` = `DT`
  `[31:4]` = next-table address
  Other bits are written as zero in this first pass.
- Page descriptor:
  `[40]` = `S`
  `[38]` = `CI`
  `[36]` = `M`
  `[35]` = `U`
  `[34]` = `WP`
  `[33:32]` = `DT`
  `[31:8]` = page base physical address
  Other bits are written as zero in this first pass.

**Compatibility shims kept for the legacy interface**
- `*_v_*` is no longer a stored bit. Motorola validity is encoded by `DT != 2'b00`.
- On pack, `*_v_i == 0` forces `DT` to `00`.
- On unpack, `*_v_o` is derived as `(DT != 00)`.
- `r_i_*` and `p_i_*` now carry Motorola `L/U`, because the old standalone invalid bit does not exist in Motorola descriptor layouts.

**Why this is a subset instead of a full manual image**
- The existing port list does not expose every long-format Motorola field.
- Missing fields include, depending on descriptor type: `SG`, access-level fields, gate/lock control, and other reserved/software-defined bits.
- Those fields are packed as zero for now so the module stays combinational and keeps its external port list.

**68851 vs 68030 deltas recorded for this packet**
- `MC68851`:
  Long-format descriptors include additional fields such as `SG`, access-level controls, and page gate/lock semantics.[^68851-UM-5.1.5.3]
- `MC68030`:
  The integrated PMMU removes several MC68851-only features, including root-pointer-table aliases and lockable/shared-global ATC behavior as externally programmable features.[^68030-UM-9.7]
- Practical implication for this module:
  The chosen default maps the common visible subset shared across the manuals for `L/U`, `LIMIT`, `DT`, address placement, and page protection/history bits, while leaving unsupported vendor-specific fields zeroed.

**Manual-driven notes per descriptor**
- Root descriptor:
  The 68851 and 68030 both place `L/U` and `LIMIT` in the upper control word and `DT` in bits `[33:32]` for the root-pointer descriptor.[^68851-UM-6.1.1][^68030-UM-9.5.1.2]
- Pointer descriptor:
  This packet treats the pointer descriptor as the long-format table-descriptor subset: upper-word `L/U` and `LIMIT`, lower-word `DT` plus table address.[^68851-UM-5.1.5.2.1][^68030-UM-9.5.1.3]
- Page descriptor:
  The page descriptor mapping follows the Motorola long-format page descriptor locations for `S`, `CI`, `M`, `U`, `WP`, `DT`, and page address.[^68851-UM-5.1.5.3][^68030-UM-9.5.1.7]

**Known TODOs**
- Add the remaining long-format fields if the surrounding MMU pipeline needs them.
- Decide whether a separate short-format mode is needed, or whether the project should standardize on long-format descriptors at this boundary.
- If external users depend on 32-bit packed descriptors, add an explicit short-format compatibility mode rather than relying on the previous contiguous placeholder layout.

[^68851-UM-5.1.5.2.1]: Motorola MC68851 PMMU User's Manual, Section 5.1.5.2.1 "Table Descriptors".
[^68851-UM-5.1.5.3]: Motorola MC68851 PMMU User's Manual, Section 5.1.5.3 "Descriptor Field Definitions".
[^68851-UM-6.1.1]: Motorola MC68851 PMMU User's Manual, Section 6.1.1 "Root Pointer".
[^68030-UM-9.5.1.2]: Motorola MC68030 User's Manual, Section 9.5.1.2 "Root Pointer Descriptor".
[^68030-UM-9.5.1.3]: Motorola MC68030 User's Manual, Section 9.5.1.3 "Short-Format Table Descriptor" and the accompanying long-format table-descriptor figure in Section 9.5.1.4.
[^68030-UM-9.5.1.7]: Motorola MC68030 User's Manual, Sections 9.5.1.5-9.5.1.8 for page and early-termination page descriptors, plus Section 9.5.1.1 "Descriptor Field Definitions".
[^68030-UM-9.7]: Motorola MC68030 User's Manual, Section 9.7 "MC68030 and MC68851 MMU Differences".
