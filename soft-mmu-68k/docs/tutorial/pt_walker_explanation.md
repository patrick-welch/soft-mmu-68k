## What `pt_walker.v` does

`pt_walker.v` defines a minimal single-level page-table walker named `pt_walker`. Its job is to handle a TLB miss by reading one descriptor from an abstract memory interface, checking whether that descriptor is a valid page descriptor, and returning refill information or a fault.

This is intentionally small and first-pass:

- it performs one descriptor read per translation miss
- it supports a single-level table shape
- it forwards descriptor attributes for later permission checking
- it reports invalid, unmapped, and bus-error faults
- it does not perform permission checking itself

---

## It is sequential walker control

The walker has a clock, active-low reset, and a two-state finite-state machine.

Source: [rtl/core/pt_walker.v:L80-L85](../../rtl/core/pt_walker.v#L80-L85)

```verilog
localparam [1:0] ST_IDLE = 2'd0;
localparam [1:0] ST_WAIT = 2'd1;

reg [1:0]              state_q;
reg [PA_WIDTH-1:0]     mem_req_addr_q;
reg                    mem_req_valid_q;
```

`ST_IDLE` waits for a new `start_i` request. `ST_WAIT` waits for the descriptor memory response.

---

## Parameters

The main width parameters configure address, descriptor, function-code, and attribute widths.

Source: [rtl/core/pt_walker.v:L22-L28](../../rtl/core/pt_walker.v#L22-L28)

```verilog
module pt_walker #(
  parameter integer VA_WIDTH    = 24,
  parameter integer PA_WIDTH    = 24,
  parameter integer PAGE_SHIFT  = 12,
  parameter integer DESCR_WIDTH = 64,
  parameter integer FC_WIDTH    = 3,
  parameter integer ATTR_WIDTH  = 5,
```

The descriptor bit-position parameters define the Motorola-aligned long-format page-descriptor subset used by this first-pass walker.

Source: [rtl/core/pt_walker.v:L31-L45](../../rtl/core/pt_walker.v#L31-L45)

```verilog
parameter integer DESC_DT_HI     = 33,
parameter integer DESC_DT_LO     = 32,
parameter integer DESC_S_BIT     = 40,
parameter integer DESC_WP_BIT    = 34,
parameter integer DESC_CI_BIT    = 38,
parameter integer DESC_M_BIT     = 36,
parameter integer DESC_U_BIT     = 35,
parameter integer DESC_PADDR_HI  = 31,
parameter integer DESC_PADDR_LO  = 8,

parameter [1:0] DESC_DT_PAGE  = 2'b01,
parameter [1:0] FAULT_NONE    = 2'b00,
parameter [1:0] FAULT_INVALID = 2'b01,
parameter [1:0] FAULT_UNMAPPED= 2'b10,
parameter [1:0] FAULT_BUS     = 2'b11
```

---

## Interface

The request input supplies the virtual address, function code, table base, and configured table size.

Source: [rtl/core/pt_walker.v:L50-L54](../../rtl/core/pt_walker.v#L50-L54)

```verilog
input  wire                  start_i,
input  wire [VA_WIDTH-1:0]   va_i,
input  wire [FC_WIDTH-1:0]   fc_i,
input  wire [PA_WIDTH-1:0]   table_base_i,
input  wire [VA_WIDTH-PAGE_SHIFT-1:0] table_entries_i,
```

The abstract memory interface sends one descriptor read and waits for one response.

Source: [rtl/core/pt_walker.v:L56-L60](../../rtl/core/pt_walker.v#L56-L60)

```verilog
output wire                  mem_req_valid_o,
output wire [PA_WIDTH-1:0]   mem_req_addr_o,
input  wire                  mem_resp_valid_i,
input  wire [DESCR_WIDTH-1:0] mem_resp_data_i,
input  wire                  mem_resp_err_i,
```

The result side reports completion, refill fields, and faults.

Source: [rtl/core/pt_walker.v:L62-L70](../../rtl/core/pt_walker.v#L62-L70)

```verilog
output wire                  busy_o,
output reg                   done_o,
output reg                   refill_valid_o,
output reg  [VA_WIDTH-1:0]   refill_va_o,
output reg  [PA_WIDTH-1:0]   walk_pa_base_o,
output reg  [PA_WIDTH-PAGE_SHIFT-1:0] walk_ppn_o,
output reg  [ATTR_WIDTH-1:0] walk_attr_o,
output reg                   fault_valid_o,
output reg  [1:0]            fault_code_o
```

---

## Derived widths and descriptor decode

The walker derives VPN/PFN widths and descriptor byte stride from the parameters.

Source: [rtl/core/pt_walker.v:L73-L78](../../rtl/core/pt_walker.v#L73-L78)

```verilog
localparam integer VPN_WIDTH         = VA_WIDTH - PAGE_SHIFT;
localparam integer PFN_WIDTH         = (PA_WIDTH > PAGE_SHIFT) ? (PA_WIDTH - PAGE_SHIFT) : 1;
localparam integer DESCR_BYTES       = DESCR_WIDTH / 8;
localparam integer DESCR_BYTE_SHIFT  = $clog2(DESCR_BYTES);
localparam integer DESC_PFN_HI       = PAGE_SHIFT + PFN_WIDTH - 1;
localparam integer DESC_PFN_LO       = PAGE_SHIFT;
```

The descriptor response is decoded into PFN, descriptor type, invalid flag, and attributes.

Source: [rtl/core/pt_walker.v:L87-L98](../../rtl/core/pt_walker.v#L87-L98)

```verilog
wire [VPN_WIDTH-1:0] start_vpn = va_i[VA_WIDTH-1:PAGE_SHIFT];
wire [PFN_WIDTH-1:0] resp_pfn     = mem_resp_data_i[DESC_PFN_HI:DESC_PFN_LO];
wire [1:0]            resp_dt      = mem_resp_data_i[DESC_DT_HI:DESC_DT_LO];
wire                  resp_invalid = (resp_dt == 2'b00);

wire [ATTR_WIDTH-1:0] resp_attr = {
  mem_resp_data_i[DESC_S_BIT],
  mem_resp_data_i[DESC_WP_BIT],
  mem_resp_data_i[DESC_CI_BIT],
  mem_resp_data_i[DESC_M_BIT],
```

The attribute vector continues with the used bit on the next line in the source. The packed order is `{S, WP, CI, M, U}`.

---

## Memory request outputs

The public memory request outputs are driven from internal request registers.

Source: [rtl/core/pt_walker.v:L104-L106](../../rtl/core/pt_walker.v#L104-L106)

```verilog
assign busy_o          = (state_q != ST_IDLE);
assign mem_req_valid_o = mem_req_valid_q;
assign mem_req_addr_o  = mem_req_addr_q;
```

`busy_o` is high any time the walker is not idle.

`mem_req_valid_o` is a registered one-cycle request pulse produced when a valid walk starts.

---

## Parameter validation

The `initial` block catches parameter combinations the design cannot support.

Source: [rtl/core/pt_walker.v:L108-L139](../../rtl/core/pt_walker.v#L108-L139)

```verilog
initial begin
  if (VA_WIDTH <= PAGE_SHIFT) begin
    $fatal(1, "pt_walker VA_WIDTH must exceed PAGE_SHIFT");
  end
  if (PA_WIDTH <= PAGE_SHIFT) begin
    $fatal(1, "pt_walker PA_WIDTH must exceed PAGE_SHIFT");
  end
  if (DESCR_WIDTH < 64) begin
    $fatal(1, "pt_walker DESCR_WIDTH must be >= 64 for long-format descriptors");
  end
```

The checks also require byte-aligned descriptor width, power-of-two descriptor byte size, enough attribute width, valid descriptor field positions, and a page-address field that can represent the configured PA/page geometry.

These checks are simulation/elaboration safeguards, not runtime hardware behavior.

---

## Reset and per-cycle defaults

The main state machine is clocked.

Source: [rtl/core/pt_walker.v:L141-L159](../../rtl/core/pt_walker.v#L141-L159)

```verilog
always @(posedge clk) begin
  if (!rst_n) begin
    state_q         <= ST_IDLE;
    mem_req_addr_q  <= {PA_WIDTH{1'b0}};
    mem_req_valid_q <= 1'b0;
    done_o          <= 1'b0;
    refill_valid_o  <= 1'b0;
    refill_va_o     <= {VA_WIDTH{1'b0}};
    walk_pa_base_o  <= {PA_WIDTH{1'b0}};
    walk_ppn_o      <= {PFN_WIDTH{1'b0}};
```

In the non-reset path, one-cycle outputs are cleared before the state case runs.

Source: [rtl/core/pt_walker.v:L153-L159](../../rtl/core/pt_walker.v#L153-L159)

```verilog
done_o          <= 1'b0;
refill_valid_o  <= 1'b0;
fault_valid_o   <= 1'b0;
fault_code_o    <= FAULT_NONE;
mem_req_valid_q <= 1'b0;
```

This makes `done_o`, `refill_valid_o`, `fault_valid_o`, and `mem_req_valid_o` pulse-style signals.

---

## Starting a walk

In `ST_IDLE`, a high `start_i` begins a walk.

Source: [rtl/core/pt_walker.v:L161-L176](../../rtl/core/pt_walker.v#L161-L176)

```verilog
case (state_q)
  ST_IDLE: begin
    if (start_i) begin
      refill_va_o <= va_i;

      if (start_vpn >= table_entries_i) begin
        done_o         <= 1'b1;
        fault_valid_o  <= 1'b1;
        fault_code_o   <= FAULT_UNMAPPED;
      end else begin
        mem_req_addr_q  <= table_base_i + ({ {(PA_WIDTH-VPN_WIDTH){1'b0}}, start_vpn } << DESCR_BYTE_SHIFT);
        mem_req_valid_q <= 1'b1;
        state_q         <= ST_WAIT;
```

If the VPN is outside the configured table span, the walk completes immediately with an unmapped fault.

Otherwise, the descriptor address is computed as the table base plus the VPN scaled by descriptor size.

---

## Handling the descriptor response

In `ST_WAIT`, the walker waits for `mem_resp_valid_i`.

Source: [rtl/core/pt_walker.v:L179-L199](../../rtl/core/pt_walker.v#L179-L199)

```verilog
if (mem_resp_valid_i) begin
  state_q <= ST_IDLE;
  done_o  <= 1'b1;

  if (mem_resp_err_i) begin
    fault_valid_o <= 1'b1;
    fault_code_o  <= FAULT_BUS;
  end else if (resp_invalid) begin
    fault_valid_o <= 1'b1;
    fault_code_o  <= FAULT_INVALID;
  end else if (resp_dt != DESC_DT_PAGE) begin
    fault_valid_o <= 1'b1;
    fault_code_o  <= FAULT_UNMAPPED;
  end else begin
```

The response priority is abstract memory bus error, invalid descriptor, non-page descriptor, then valid page descriptor refill.

For a valid page descriptor, the walker reports refill data.

Source: [rtl/core/pt_walker.v:L193-L197](../../rtl/core/pt_walker.v#L193-L197)

```verilog
walk_ppn_o     <= resp_pfn;
walk_pa_base_o <= {resp_pfn, {PAGE_SHIFT{1'b0}}};
walk_attr_o    <= resp_attr;
refill_valid_o <= 1'b1;
```

The returned PA base is page-aligned by appending `PAGE_SHIFT` zero bits to the PFN.

---

## Important syntax notes

`$clog2(DESCR_BYTES)` computes the shift count needed to scale a descriptor index by descriptor size.

The slice `va_i[VA_WIDTH-1:PAGE_SHIFT]` extracts the virtual page number.

The concatenation `{resp_pfn, {PAGE_SHIFT{1'b0}}}` rebuilds a page-aligned physical address base.

`<=` is used for sequential register updates inside the clocked block.

`$fatal` stops simulation/elaboration for unsupported parameter settings.

---

## Main gotchas

The first gotcha is that this walker is single-level. It does not implement a full Motorola multi-level descriptor traversal.

The second gotcha is that permission faults are not handled here. The walker forwards attributes, and permission checking happens elsewhere.

The third gotcha is that `mem_req_valid_o` is a pulse, not a held-valid request. The abstract memory side is expected to observe that pulse and later return `mem_resp_valid_i`.

The fourth gotcha is that a descriptor type other than the configured page type is treated as unmapped in this first-pass walker.

Finally, the unused `fc_i` input is intentionally reduced under a Verilator lint waiver because this walker currently does not branch on function code.