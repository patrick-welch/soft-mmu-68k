# `tlb_dm.v` Tutorial

> This tutorial explains the current SM68861 RTL implementation. It is not a
> complete Motorola PMMU specification and should not be read as a compatibility
> claim beyond the behavior implemented and tested in this repository.

## What `tlb_dm.v` does

`tlb_dm.v` defines a minimum direct-mapped TLB, also described in the comments as an ATC/TLB. It stores one entry per index, performs a combinational lookup of the indexed entry, supports synchronous refill, and supports whole-TLB or targeted invalidation.

This module is intentionally simple:

- one direct-mapped slot per index
- no associative search
- no replacement policy beyond overwriting the indexed slot
- whole-TLB invalidate
- address-and-function-code targeted invalidate

The actual one-entry compare is delegated to `tlb_compare.v`.

---

## Not implemented here

This module does not implement a fully associative MC68851 ATC, multi-way replacement, descriptor walking, or permission checking. It provides the current direct-mapped TLB storage, lookup, refill, and invalidation behavior.

---

## It combines combinational lookup with sequential storage updates

The lookup path computes an index, reads the selected arrays, and compares the selected entry combinationally.

The refill and invalidation path updates stored arrays on the rising clock edge.

Source: [rtl/core/tlb_dm.v:L133-L158](../../rtl/core/tlb_dm.v#L133-L158)

```verilog
always @(posedge clk) begin
  if (!rst_n) begin
    for (idx = 0; idx < ENTRIES; idx = idx + 1) begin
      valid_mem[idx] <= 1'b0;
      tag_mem[idx]   <= {TAG_WIDTH{1'b0}};
      pfn_mem[idx]   <= {PFN_WIDTH{1'b0}};
      fc_mem[idx]    <= {FC_WIDTH{1'b0}};
      attr_mem[idx]  <= {ATTR_WIDTH{1'b0}};
    end
  end else if (invalidate_all_i) begin
```

The reset and invalidate operations are synchronous.

---

## Parameters and interface

The module is parameterized by virtual/physical widths, page size, entry count, function-code width, and attribute width.

Source: [rtl/core/tlb_dm.v:L19-L25](../../rtl/core/tlb_dm.v#L19-L25)

```verilog
module tlb_dm #(
  parameter integer VA_WIDTH   = 24,
  parameter integer PA_WIDTH   = 24,
  parameter integer PAGE_SHIFT = 12,
  parameter integer ENTRIES    = 16,
  parameter integer FC_WIDTH   = 3,
  parameter integer ATTR_WIDTH = 4
) (
```

The lookup interface supplies a virtual address and function code and returns hit/miss, physical address, and attributes.

Source: [rtl/core/tlb_dm.v:L30-L36](../../rtl/core/tlb_dm.v#L30-L36)

```verilog
input  wire                  lookup_valid_i,
input  wire [VA_WIDTH-1:0]   lookup_va_i,
input  wire [FC_WIDTH-1:0]   lookup_fc_i,
output wire                  lookup_hit_o,
output wire                  lookup_miss_o,
output wire [PA_WIDTH-1:0]   lookup_pa_o,
output wire [ATTR_WIDTH-1:0] lookup_attr_o,
```

The refill interface writes a translated VA/PA/function-code/attribute tuple into the indexed entry.

Source: [rtl/core/tlb_dm.v:L38-L42](../../rtl/core/tlb_dm.v#L38-L42)

```verilog
input  wire                  refill_valid_i,
input  wire [VA_WIDTH-1:0]   refill_va_i,
input  wire [PA_WIDTH-1:0]   refill_pa_i,
input  wire [FC_WIDTH-1:0]   refill_fc_i,
input  wire [ATTR_WIDTH-1:0] refill_attr_i,
```

The invalidate interface supports whole-TLB and address/function-code match invalidation.

Source: [rtl/core/tlb_dm.v:L44-L47](../../rtl/core/tlb_dm.v#L44-L47)

```verilog
input  wire                  invalidate_all_i,
input  wire                  invalidate_match_i,
input  wire [VA_WIDTH-1:0]   invalidate_va_i,
input  wire [FC_WIDTH-1:0]   invalidate_fc_i
```

---

## Derived widths

The address geometry determines index, VPN, PFN, and tag widths.

Source: [rtl/core/tlb_dm.v:L50-L53](../../rtl/core/tlb_dm.v#L50-L53)

```verilog
localparam integer INDEX_WIDTH = $clog2(ENTRIES);
localparam integer VPN_WIDTH   = VA_WIDTH - PAGE_SHIFT;
localparam integer PFN_WIDTH   = PA_WIDTH - PAGE_SHIFT;
localparam integer TAG_WIDTH   = VPN_WIDTH - INDEX_WIDTH;
```

The VPN is split into an index and tag. The low virtual-address bits below `PAGE_SHIFT` are the page offset.

---

## Stored arrays

The TLB entry storage is implemented as separate arrays for valid, tag, PFN, function code, and attributes.

Source: [rtl/core/tlb_dm.v:L57-L61](../../rtl/core/tlb_dm.v#L57-L61)

```verilog
reg                    valid_mem [0:ENTRIES-1];
reg [TAG_WIDTH-1:0]    tag_mem   [0:ENTRIES-1];
reg [PFN_WIDTH-1:0]    pfn_mem   [0:ENTRIES-1];
reg [FC_WIDTH-1:0]     fc_mem    [0:ENTRIES-1];
reg [ATTR_WIDTH-1:0]   attr_mem  [0:ENTRIES-1];
```

Each index has exactly one entry. If two virtual pages map to the same index, the later refill overwrites the earlier entry.

---

## Lookup, refill, and invalidate address slicing

The lookup virtual address is split into VPN, index, tag, and offset.

Source: [rtl/core/tlb_dm.v:L63-L66](../../rtl/core/tlb_dm.v#L63-L66)

```verilog
wire [VPN_WIDTH-1:0] lookup_vpn    = lookup_va_i[VA_WIDTH-1:PAGE_SHIFT];
wire [INDEX_WIDTH-1:0] lookup_index = lookup_vpn[INDEX_WIDTH-1:0];
wire [TAG_WIDTH-1:0] lookup_tag    = lookup_vpn[VPN_WIDTH-1:INDEX_WIDTH];
wire [PAGE_SHIFT-1:0] lookup_offset = lookup_va_i[PAGE_SHIFT-1:0];
```

Refill and targeted invalidate use the same split.

Source: [rtl/core/tlb_dm.v:L68-L75](../../rtl/core/tlb_dm.v#L68-L75)

```verilog
wire [VPN_WIDTH-1:0] refill_vpn    = refill_va_i[VA_WIDTH-1:PAGE_SHIFT];
wire [INDEX_WIDTH-1:0] refill_index = refill_vpn[INDEX_WIDTH-1:0];
wire [TAG_WIDTH-1:0] refill_tag    = refill_vpn[VPN_WIDTH-1:INDEX_WIDTH];
wire [PFN_WIDTH-1:0] refill_pfn    = refill_pa_i[PA_WIDTH-1:PAGE_SHIFT];

wire [VPN_WIDTH-1:0] invalidate_vpn = invalidate_va_i[VA_WIDTH-1:PAGE_SHIFT];
wire [INDEX_WIDTH-1:0] invalidate_index = invalidate_vpn[INDEX_WIDTH-1:0];
wire [TAG_WIDTH-1:0] invalidate_tag = invalidate_vpn[VPN_WIDTH-1:INDEX_WIDTH];
```

The page offsets of refill and invalidate addresses are intentionally ignored.

---

## Targeted invalidation match

Targeted invalidation checks the selected indexed entry for valid, tag, and function-code match.

Source: [rtl/core/tlb_dm.v:L82-L84](../../rtl/core/tlb_dm.v#L82-L84)

```verilog
wire invalidate_entry_hit = valid_mem[invalidate_index] &&
                            (tag_mem[invalidate_index] == invalidate_tag) &&
                            (fc_mem[invalidate_index] == invalidate_fc_i);
```

Only the indexed slot is checked. This is a direct-mapped TLB, not an associative structure.

---

## One-entry compare helper

The selected array entry is passed into `tlb_compare`.

Source: [rtl/core/tlb_dm.v:L90-L108](../../rtl/core/tlb_dm.v#L90-L108)

```verilog
tlb_compare #(
  .TAG_WIDTH (TAG_WIDTH),
  .PFN_WIDTH (PFN_WIDTH),
  .PAGE_SHIFT(PAGE_SHIFT),
  .FC_WIDTH  (FC_WIDTH),
  .ATTR_WIDTH(ATTR_WIDTH)
) lookup_cmp (
  .valid_i        (valid_mem[lookup_index]),
  .tag_i          (tag_mem[lookup_index]),
  .pfn_i          (pfn_mem[lookup_index]),
  .fc_i           (fc_mem[lookup_index]),
```

The helper returns raw hit, PA, and attribute results for the selected entry.

---

## Lookup outputs

The public lookup outputs are gated by `lookup_valid_i`.

Source: [rtl/core/tlb_dm.v:L110-L113](../../rtl/core/tlb_dm.v#L110-L113)

```verilog
assign lookup_hit_o  = lookup_valid_i && lookup_hit_raw;
assign lookup_miss_o = lookup_valid_i && !lookup_hit_raw;
assign lookup_pa_o   = lookup_valid_i ? lookup_pa_raw : {PA_WIDTH{1'b0}};
assign lookup_attr_o = lookup_hit_o ? lookup_attr_raw : {ATTR_WIDTH{1'b0}};
```

If `lookup_valid_i` is low, both hit and miss are low and the PA output is zero.

Attributes are meaningful only on a hit.

---

## Parameter validation

The `initial` block enforces basic geometry constraints.

Source: [rtl/core/tlb_dm.v:L115-L130](../../rtl/core/tlb_dm.v#L115-L130)

```verilog
initial begin
  if (ENTRIES < 2) begin
    $fatal(1, "tlb_dm ENTRIES must be >= 2");
  end
  if ((1 << INDEX_WIDTH) != ENTRIES) begin
    $fatal(1, "tlb_dm ENTRIES must be a power of two");
  end
```

The checks require at least two entries, power-of-two entry count, address widths greater than `PAGE_SHIFT`, and at least one tag bit.

---

## Refill and invalidate priority

The sequential block gives whole-TLB invalidation priority over targeted invalidation and refill.

Source: [rtl/core/tlb_dm.v:L142-L158](../../rtl/core/tlb_dm.v#L142-L158)

```verilog
end else if (invalidate_all_i) begin
  for (idx = 0; idx < ENTRIES; idx = idx + 1) begin
    valid_mem[idx] <= 1'b0;
  end
end else begin
  if (invalidate_match_i && invalidate_entry_hit) begin
    valid_mem[invalidate_index] <= 1'b0;
  end

  if (refill_valid_i) begin
    valid_mem[refill_index] <= 1'b1;
    tag_mem[refill_index]   <= refill_tag;
```

If `invalidate_all_i` is high, every valid bit is cleared and no refill happens that cycle.

If targeted invalidate and refill happen together in the non-whole-flush path, both branches can execute. A refill to the same index can write the entry valid again later in the same clocked block.

---

## Important syntax notes

`$clog2(ENTRIES)` computes the number of bits needed to index the entry array.

The arrays `valid_mem`, `tag_mem`, `pfn_mem`, `fc_mem`, and `attr_mem` model direct-mapped TLB storage.

The `for` loop in the clocked block resets or invalidates all entries one index at a time.

Slicing the VPN into low index bits and high tag bits is what makes the structure direct-mapped.

---

## Main gotchas

The first gotcha is that this is direct-mapped. Only one candidate entry is checked per lookup.

The second gotcha is that function code is part of both lookup and targeted invalidation matching.

The third gotcha is that whole-TLB invalidate takes priority over refill in the same cycle.

The fourth gotcha is that lookup is combinational from the current array contents, while refill and invalidation are synchronous updates.

Finally, refill and invalidate page offsets are ignored. The TLB stores and matches page-level entries, not byte-level addresses.