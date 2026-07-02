# `tlb_compare.v` Tutorial

> This tutorial explains the current SM68861 RTL implementation. It is not a
> complete Motorola PMMU specification and should not be read as a compatibility
> claim beyond the behavior implemented and tested in this repository.

## What `tlb_compare.v` does

`tlb_compare.v` defines a tiny combinational helper named `tlb_compare`. It checks one TLB entry against one lookup request.

The helper answers three questions:

- does this entry hit?
- if it hits, what physical address should be returned?
- if it hits, what attribute bits should be returned?

This module compares a single entry only. It does not store a TLB array, choose an index, refill entries, or invalidate entries. Those responsibilities live in `tlb_dm.v`.

---

## Not implemented here

This module does not store entries, choose indexes, refill TLB state, invalidate entries, or perform associative lookup. It only compares one supplied TLB entry against one lookup request.

---

## It is purely combinational logic

The module has no clock, reset, or internal state. It is built from one match wire and three continuous assignments.

Source: [rtl/core/tlb_compare.v:L36-L40](../../rtl/core/tlb_compare.v#L36-L40)

```verilog
wire entry_match = (tag_i == lookup_tag_i) && (fc_i == lookup_fc_i);

assign hit_o  = valid_i && entry_match;
assign pa_o   = hit_o ? {pfn_i, lookup_offset_i} : {(PFN_WIDTH+PAGE_SHIFT){1'b0}};
assign attr_o = hit_o ? attr_i : {ATTR_WIDTH{1'b0}};
```

The output result changes whenever the entry inputs or lookup inputs change.

---

## Parameters

The module is parameterized by tag, PFN, page-offset, function-code, and attribute widths.

Source: [rtl/core/tlb_compare.v:L14-L19](../../rtl/core/tlb_compare.v#L14-L19)

```verilog
module tlb_compare #(
  parameter integer TAG_WIDTH  = 8,
  parameter integer PFN_WIDTH  = 8,
  parameter integer PAGE_SHIFT = 8,
  parameter integer FC_WIDTH   = 3,
  parameter integer ATTR_WIDTH = 4
) (
```

`PAGE_SHIFT` is also the width of the page offset used to rebuild the final physical address.

---

## Entry inputs

The first input group describes the stored TLB entry.

Source: [rtl/core/tlb_compare.v:L21-L25](../../rtl/core/tlb_compare.v#L21-L25)

```verilog
input  wire                  valid_i,
input  wire [TAG_WIDTH-1:0]  tag_i,
input  wire [PFN_WIDTH-1:0]  pfn_i,
input  wire [FC_WIDTH-1:0]   fc_i,
input  wire [ATTR_WIDTH-1:0] attr_i,
```

`valid_i` says whether the entry can be used.

`tag_i` and `fc_i` are compared against the lookup key.

`pfn_i` and `attr_i` are returned only on a hit.

---

## Lookup inputs and outputs

The lookup side supplies the tag, page offset, and function code for the current lookup.

Source: [rtl/core/tlb_compare.v:L27-L33](../../rtl/core/tlb_compare.v#L27-L33)

```verilog
input  wire [TAG_WIDTH-1:0]  lookup_tag_i,
input  wire [PAGE_SHIFT-1:0] lookup_offset_i,
input  wire [FC_WIDTH-1:0]   lookup_fc_i,

output wire                  hit_o,
output wire [PFN_WIDTH+PAGE_SHIFT-1:0] pa_o,
output wire [ATTR_WIDTH-1:0] attr_o
```

The physical address width produced by this helper is `PFN_WIDTH + PAGE_SHIFT`, which matches a PFN concatenated with a page offset.

---

## Hit check

The raw match checks both tag and function code.

Source: [rtl/core/tlb_compare.v:L36-L38](../../rtl/core/tlb_compare.v#L36-L38)

```verilog
wire entry_match = (tag_i == lookup_tag_i) && (fc_i == lookup_fc_i);

assign hit_o  = valid_i && entry_match;
```

The final hit also requires `valid_i`. A stale or invalid entry cannot hit even if its tag and function code happen to match.

---

## Physical address and attributes

On a hit, the physical address is formed from the stored PFN and the incoming page offset.

Source: [rtl/core/tlb_compare.v:L39-L40](../../rtl/core/tlb_compare.v#L39-L40)

```verilog
assign pa_o   = hit_o ? {pfn_i, lookup_offset_i} : {(PFN_WIDTH+PAGE_SHIFT){1'b0}};
assign attr_o = hit_o ? attr_i : {ATTR_WIDTH{1'b0}};
```

On a miss, both `pa_o` and `attr_o` are driven to zero.

This makes downstream logic less likely to accidentally consume stale entry data after a miss.

---

## Important syntax notes

The expression `(tag_i == lookup_tag_i) && (fc_i == lookup_fc_i)` is a Boolean match condition.

The concatenation `{pfn_i, lookup_offset_i}` rebuilds a byte physical address from a page frame number and the original page offset.

The replication `{(PFN_WIDTH+PAGE_SHIFT){1'b0}}` builds a zero vector matching the output address width.

---

## Main gotchas

The first gotcha is that function code is part of the match. Two lookups with the same virtual page tag but different function codes can produce different hit results.

The second gotcha is that this helper has no memory. It only compares the single entry supplied on its inputs.

The third gotcha is that miss outputs are intentionally zeroed. A consumer must use `hit_o` to know whether `pa_o` and `attr_o` are meaningful.