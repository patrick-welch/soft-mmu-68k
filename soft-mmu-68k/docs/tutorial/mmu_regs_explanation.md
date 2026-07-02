## What `mmu_regs.v` does

`mmu_regs.v` defines the software-visible MMU register block used by the current soft MMU design. It stores a first-pass image of key Motorola-style MMU registers and provides a simple read/write interface for software or testbench access.

The registers modeled here are:

- `crp`: current root pointer
- `srp`: supervisor root pointer
- `tc`: translation control
- `tt0`: transparent translation register 0
- `tt1`: transparent translation register 1
- `mmusr`: MMU status register image

This is a register block, not a translator. It does not perform TLB lookup, page walking, permission checking, or transparent-translation matching by itself.

---

## It is a mixed sequential and combinational module

The stored registers update in a clocked block.

Source: [rtl/core/mmu_regs.v:L85-L95](../../rtl/core/mmu_regs.v#L85-L95)

```verilog
always @(posedge clk) begin
    if (!rst_n) begin
        crp   <= CRP_RST;
        srp   <= SRP_RST;
        tc    <= TC_RST;
        tt0   <= TT0_RST;
        tt1   <= TT1_RST;
        mmusr <= MMUSR_RST;
    end else begin
        if (wr_en) begin
            case (addr)
```

The read data is produced by a separate combinational read mux.

Source: [rtl/core/mmu_regs.v:L115-L125](../../rtl/core/mmu_regs.v#L115-L125)

```verilog
always @(*) begin
    rd_data = 32'h0000_0000;
    if (rd_en) begin
        case (addr)
            REG_CRP:   rd_data = {{(32-PA_WIDTH){1'b0}}, crp};
            REG_SRP:   rd_data = {{(32-PA_WIDTH){1'b0}}, srp};
            REG_TC:    rd_data = tc;
            REG_TT0:   rd_data = tt0;
            REG_TT1:   rd_data = tt1;
            REG_MMUSR: rd_data = {16'h0000, mmusr};
            default:   rd_data = 32'h0000_0000;
```

So writes are synchronous, while reads are combinational and gated by `rd_en`.

---

## Interface

The module is parameterized by virtual and physical address width.

Source: [rtl/core/mmu_regs.v:L17-L19](../../rtl/core/mmu_regs.v#L17-L19)

```verilog
module mmu_regs #(
    parameter VA_WIDTH = 32,     // Virtual address width
    parameter PA_WIDTH = 32      // Physical address width
)(
```

The access interface uses a simple address, write-enable, read-enable, and 32-bit data bus.

Source: [rtl/core/mmu_regs.v:L22-L29](../../rtl/core/mmu_regs.v#L22-L29)

```verilog
input  wire                  clk,
input  wire                  rst_n,        // Active-low synchronous reset

input  wire                  wr_en,        // Write enable
input  wire                  rd_en,        // Read enable
input  wire [3:0]            addr,         // Register select (byte-aligned index)
input  wire [31:0]           wr_data,      // Write data
output reg  [31:0]           rd_data,      // Read data
```

The stored register values are also exposed as outputs to the rest of the MMU.

Source: [rtl/core/mmu_regs.v:L32-L37](../../rtl/core/mmu_regs.v#L32-L37)

```verilog
output reg  [PA_WIDTH-1:0]   crp,           // Current Root Pointer
output reg  [PA_WIDTH-1:0]   srp,           // Supervisor Root Pointer
output reg  [31:0]           tc,            // Translation Control
output reg  [31:0]           tt0,           // Transparent Translation 0
output reg  [31:0]           tt1,           // Transparent Translation 1
output reg  [15:0]           mmusr          // MMU Status Register
```

---

## Register address map

The register select values are local parameters.

Source: [rtl/core/mmu_regs.v:L41-L46](../../rtl/core/mmu_regs.v#L41-L46)

```verilog
localparam REG_CRP   = 4'h0;
localparam REG_SRP   = 4'h1;
localparam REG_TC    = 4'h2;
localparam REG_TT0   = 4'h3;
localparam REG_TT1   = 4'h4;
localparam REG_MMUSR = 4'h5;
```

The `addr` input chooses which register the read or write operation targets.

Only these six values have behavior. Any other address reads as zero and ignores writes.

---

## Reset defaults

The reset constants are all zero in this first-pass implementation.

Source: [rtl/core/mmu_regs.v:L53-L58](../../rtl/core/mmu_regs.v#L53-L58)

```verilog
localparam [PA_WIDTH-1:0] CRP_RST   = {PA_WIDTH{1'b0}};
localparam [PA_WIDTH-1:0] SRP_RST   = {PA_WIDTH{1'b0}};
localparam [31:0]         TC_RST    = 32'h0000_0000;
localparam [31:0]         TT0_RST   = 32'h0000_0000;
localparam [31:0]         TT1_RST   = 32'h0000_0000;
localparam [15:0]         MMUSR_RST = 16'h0000;
```

The most important practical effect is that `TC_RST = 0`, so translation is disabled by reset in the current register image.

The reset is synchronous because it is checked inside `always @(posedge clk)`. The reset input is active-low, but it takes effect on a clock edge.

---

## MMUSR writable mask

The `mmusr` register is not treated as a free-form 16-bit register. Writes are filtered through a mask.

Source: [rtl/core/mmu_regs.v:L79-L82](../../rtl/core/mmu_regs.v#L79-L82)

```verilog
localparam [15:0] MMUSR_STICKY_MASK         = 16'hFE80;
localparam [15:0] MMUSR_LEVEL_WR_MASK       = 16'h000F;
localparam [15:0] MMUSR_SW_WRITABLE_MASK    = MMUSR_STICKY_MASK |
                                               MMUSR_LEVEL_WR_MASK;
```

The mask preserves software-writeable status-class bits and the low level-number field. Reserved bits are forced low.

This is a first-pass local MMUSR model so tests and early bring-up can write meaningful status images before all hardware status producers are wired in.

---

## Write behavior

On a write, the address selects which register is updated.

Source: [rtl/core/mmu_regs.v:L94-L107](../../rtl/core/mmu_regs.v#L94-L107)

```verilog
if (wr_en) begin
    case (addr)
        REG_CRP:   crp   <= wr_data[PA_WIDTH-1:0];
        REG_SRP:   srp   <= wr_data[PA_WIDTH-1:0];
        REG_TC:    tc    <= wr_data;
        REG_TT0:   tt0   <= wr_data;
        REG_TT1:   tt1   <= wr_data;
        REG_MMUSR: begin
            // Software-visible first-pass MMUSR image: writable
            // status-class bits plus the low level field, with
            // reserved bits forced low.
            mmusr <= wr_data[15:0] & MMUSR_SW_WRITABLE_MASK;
        end
```

For `crp` and `srp`, only the low `PA_WIDTH` bits of `wr_data` are stored.

For `tc`, `tt0`, and `tt1`, the full 32-bit value is stored.

For `mmusr`, only the masked low 16 bits are stored.

---

## Read behavior

The read mux starts with a zero default and only returns register data when `rd_en` is high.

Source: [rtl/core/mmu_regs.v:L115-L125](../../rtl/core/mmu_regs.v#L115-L125)

```verilog
always @(*) begin
    rd_data = 32'h0000_0000;
    if (rd_en) begin
        case (addr)
            REG_CRP:   rd_data = {{(32-PA_WIDTH){1'b0}}, crp};
            REG_SRP:   rd_data = {{(32-PA_WIDTH){1'b0}}, srp};
            REG_TC:    rd_data = tc;
            REG_TT0:   rd_data = tt0;
            REG_TT1:   rd_data = tt1;
            REG_MMUSR: rd_data = {16'h0000, mmusr};
            default:   rd_data = 32'h0000_0000;
```

`crp` and `srp` are zero-extended to 32 bits when `PA_WIDTH` is less than 32.

`mmusr` is returned in the low 16 bits, with the high 16 bits set to zero.

When `rd_en` is low, `rd_data` remains zero.

---

## Important syntax notes

`output reg` is used for values assigned inside procedural blocks. For the stored registers, those are real sequential registers because they are assigned inside `always @(posedge clk)`.

`always @(*)` describes combinational read-mux logic. The default assignment to `rd_data` prevents latch inference.

`<=` is a nonblocking assignment and is the expected style for clocked register updates.

The replication expression `{PA_WIDTH{1'b0}}` creates a zero vector of the configured physical-address width.

The concatenation `{{(32-PA_WIDTH){1'b0}}, crp}` zero-extends the root pointer to 32 bits.

---

## Main gotchas

The first gotcha is that reset is active-low but synchronous. `rst_n` must be low at a rising clock edge to reset the registers.

The second gotcha is that `rd_data` is zero unless `rd_en` is asserted.

The third gotcha is that `mmusr` writes are masked. Reserved bits do not read back as written.

The fourth gotcha is that this block exposes a software-visible register image only. It does not by itself update MMUSR from real translation faults or implement full PMOVE behavior.

Finally, this file does not use `default_nettype none`, unlike several other core RTL files.