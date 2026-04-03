`timescale 1ns/1ps
`default_nettype none
// -----------------------------------------------------------------------------
// Soft MMU 68k : tlb_dm
// Minimum direct-mapped ATC/TLB with synchronous refill and invalidate hooks.
//
// Compliance:
//   - MC68851 PMMU User's Manual, Section 5.2 "Address Translation Cache"
//   - MC68030 User's Manual, Section 9 "Memory Management Unit"
//   - M68000 Family Programmer's Reference Manual, instruction entries
//     "PLOAD", "PFLUSH", and "PFLUSHA"
//
// Behavioral notes:
//   - One entry per index, no associative replacement policy in this packet.
//   - Refills overwrite the indexed slot directly.
//   - Invalidate supports whole-TLB flush and address+FC targeted flush.
// -----------------------------------------------------------------------------

module tlb_dm #(
  parameter integer VA_WIDTH   = 24,
  parameter integer PA_WIDTH   = 24,
  parameter integer PAGE_SHIFT = 12,
  parameter integer ENTRIES    = 16,
  parameter integer FC_WIDTH   = 3,
  parameter integer ATTR_WIDTH = 4
) (
  input  wire                  clk,
  input  wire                  rst_n,

  input  wire                  lookup_valid_i,
  input  wire [VA_WIDTH-1:0]   lookup_va_i,
  input  wire [FC_WIDTH-1:0]   lookup_fc_i,
  output wire                  lookup_hit_o,
  output wire                  lookup_miss_o,
  output wire [PA_WIDTH-1:0]   lookup_pa_o,
  output wire [ATTR_WIDTH-1:0] lookup_attr_o,

  input  wire                  refill_valid_i,
  input  wire [VA_WIDTH-1:0]   refill_va_i,
  input  wire [PA_WIDTH-1:0]   refill_pa_i,
  input  wire [FC_WIDTH-1:0]   refill_fc_i,
  input  wire [ATTR_WIDTH-1:0] refill_attr_i,

  input  wire                  invalidate_all_i,
  input  wire                  invalidate_match_i,
  input  wire [VA_WIDTH-1:0]   invalidate_va_i,
  input  wire [FC_WIDTH-1:0]   invalidate_fc_i
);

  localparam integer INDEX_WIDTH = $clog2(ENTRIES);
  localparam integer VPN_WIDTH   = VA_WIDTH - PAGE_SHIFT;
  localparam integer PFN_WIDTH   = PA_WIDTH - PAGE_SHIFT;
  localparam integer TAG_WIDTH   = VPN_WIDTH - INDEX_WIDTH;

  integer idx;

  reg                    valid_mem [0:ENTRIES-1];
  reg [TAG_WIDTH-1:0]    tag_mem   [0:ENTRIES-1];
  reg [PFN_WIDTH-1:0]    pfn_mem   [0:ENTRIES-1];
  reg [FC_WIDTH-1:0]     fc_mem    [0:ENTRIES-1];
  reg [ATTR_WIDTH-1:0]   attr_mem  [0:ENTRIES-1];

  wire [VPN_WIDTH-1:0] lookup_vpn    = lookup_va_i[VA_WIDTH-1:PAGE_SHIFT];
  wire [INDEX_WIDTH-1:0] lookup_index = lookup_vpn[INDEX_WIDTH-1:0];
  wire [TAG_WIDTH-1:0] lookup_tag    = lookup_vpn[VPN_WIDTH-1:INDEX_WIDTH];
  wire [PAGE_SHIFT-1:0] lookup_offset = lookup_va_i[PAGE_SHIFT-1:0];

  wire [VPN_WIDTH-1:0] refill_vpn    = refill_va_i[VA_WIDTH-1:PAGE_SHIFT];
  wire [INDEX_WIDTH-1:0] refill_index = refill_vpn[INDEX_WIDTH-1:0];
  wire [TAG_WIDTH-1:0] refill_tag    = refill_vpn[VPN_WIDTH-1:INDEX_WIDTH];
  wire [PFN_WIDTH-1:0] refill_pfn    = refill_pa_i[PA_WIDTH-1:PAGE_SHIFT];

  wire [VPN_WIDTH-1:0] invalidate_vpn = invalidate_va_i[VA_WIDTH-1:PAGE_SHIFT];
  wire [INDEX_WIDTH-1:0] invalidate_index = invalidate_vpn[INDEX_WIDTH-1:0];
  wire [TAG_WIDTH-1:0] invalidate_tag = invalidate_vpn[VPN_WIDTH-1:INDEX_WIDTH];
  /* verilator lint_off UNUSED */
  wire ignored_page_offsets = ^refill_va_i[PAGE_SHIFT-1:0] ^
                              ^refill_pa_i[PAGE_SHIFT-1:0] ^
                              ^invalidate_va_i[PAGE_SHIFT-1:0];
  /* verilator lint_on UNUSED */

  wire invalidate_entry_hit = valid_mem[invalidate_index] &&
                              (tag_mem[invalidate_index] == invalidate_tag) &&
                              (fc_mem[invalidate_index] == invalidate_fc_i);

  wire                  lookup_hit_raw;
  wire [PA_WIDTH-1:0]   lookup_pa_raw;
  wire [ATTR_WIDTH-1:0] lookup_attr_raw;

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
    .attr_i         (attr_mem[lookup_index]),
    .lookup_tag_i   (lookup_tag),
    .lookup_offset_i(lookup_offset),
    .lookup_fc_i    (lookup_fc_i),
    .hit_o          (lookup_hit_raw),
    .pa_o           (lookup_pa_raw),
    .attr_o         (lookup_attr_raw)
  );

  assign lookup_hit_o  = lookup_valid_i && lookup_hit_raw;
  assign lookup_miss_o = lookup_valid_i && !lookup_hit_raw;
  assign lookup_pa_o   = lookup_valid_i ? lookup_pa_raw : {PA_WIDTH{1'b0}};
  assign lookup_attr_o = lookup_hit_o ? lookup_attr_raw : {ATTR_WIDTH{1'b0}};

  initial begin
    if (ENTRIES < 2) begin
      $fatal(1, "tlb_dm ENTRIES must be >= 2");
    end
    if ((1 << INDEX_WIDTH) != ENTRIES) begin
      $fatal(1, "tlb_dm ENTRIES must be a power of two");
    end
    if (VA_WIDTH <= PAGE_SHIFT) begin
      $fatal(1, "tlb_dm VA_WIDTH must exceed PAGE_SHIFT");
    end
    if (PA_WIDTH <= PAGE_SHIFT) begin
      $fatal(1, "tlb_dm PA_WIDTH must exceed PAGE_SHIFT");
    end
    if (VPN_WIDTH <= INDEX_WIDTH) begin
      $fatal(1, "tlb_dm VA_WIDTH/PAGE_SHIFT/ENTRIES leave no tag bits");
    end
  end

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
        pfn_mem[refill_index]   <= refill_pfn;
        fc_mem[refill_index]    <= refill_fc_i;
        attr_mem[refill_index]  <= refill_attr_i;
      end
    end
  end

endmodule
`default_nettype wire
