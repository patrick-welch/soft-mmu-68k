`timescale 1ns/1ps
`default_nettype none
// -----------------------------------------------------------------------------
// Soft MMU 68k : tlb_compare
// Direct-mapped ATC/TLB entry compare helper.
//
// Compliance:
//   - MC68851 PMMU User's Manual, Section 5.2 "Address Translation Cache"
//   - MC68030 User's Manual, Section 9 "Memory Management Unit"
//   - M68000 Family Programmer's Reference Manual, instruction entries
//     "PLOAD", "PFLUSH", and "PFLUSHA"
// -----------------------------------------------------------------------------

module tlb_compare #(
  parameter integer TAG_WIDTH  = 8,
  parameter integer PFN_WIDTH  = 8,
  parameter integer PAGE_SHIFT = 8,
  parameter integer FC_WIDTH   = 3,
  parameter integer ATTR_WIDTH = 4
) (
  input  wire                  valid_i,
  input  wire [TAG_WIDTH-1:0]  tag_i,
  input  wire [PFN_WIDTH-1:0]  pfn_i,
  input  wire [FC_WIDTH-1:0]   fc_i,
  input  wire [ATTR_WIDTH-1:0] attr_i,

  input  wire [TAG_WIDTH-1:0]  lookup_tag_i,
  input  wire [PAGE_SHIFT-1:0] lookup_offset_i,
  input  wire [FC_WIDTH-1:0]   lookup_fc_i,

  output wire                  hit_o,
  output wire [PFN_WIDTH+PAGE_SHIFT-1:0] pa_o,
  output wire [ATTR_WIDTH-1:0] attr_o
);

  wire entry_match = (tag_i == lookup_tag_i) && (fc_i == lookup_fc_i);

  assign hit_o  = valid_i && entry_match;
  assign pa_o   = hit_o ? {pfn_i, lookup_offset_i} : {(PFN_WIDTH+PAGE_SHIFT){1'b0}};
  assign attr_o = hit_o ? attr_i : {ATTR_WIDTH{1'b0}};

endmodule
`default_nettype wire
