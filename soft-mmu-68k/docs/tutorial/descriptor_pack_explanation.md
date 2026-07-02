## What `descriptor_pack.v` does

`descriptor_pack.v` defines a combinational hardware module named `descriptor_pack`. Its job is to convert descriptor fields into a packed 64-bit descriptor word, and also convert a packed descriptor word back into individual fields.

In other words, it performs two related operations:

- **Pack**: take separate fields like valid bit, descriptor type, limit, address, write-protect bit, cache-inhibit bit, etc., and place them into specific bit positions inside `packed_o`.
- **Unpack**: take an incoming descriptor word `packed_i` and extract those same fields into separate output signals.

The module supports three descriptor kinds:

- `KIND_ROOT`
- `KIND_PTR`
- `KIND_PAGE`

The selected kind is controlled by:

```verilog
input wire [1:0] kind_i
```

When packing, `kind_i` decides whether the module builds a root descriptor, pointer descriptor, or page descriptor.

---

## It is purely combinational logic

The file has no clock, reset, or stored state. Both main logic blocks are written as:

```verilog
always @* begin
```

That means the outputs update whenever any input used inside the block changes. This describes combinational logic, similar to wiring together multiplexers, bit slices, and simple gates.

There are two separate combinational blocks:

1. One creates `packed_o`.
2. One decodes `packed_i` into the unpacked output fields.

---

## Header directives

At the top:

```verilog
`timescale 1ns/1ps
`default_nettype none
```

`timescale 1ns/1ps` controls simulation time units and precision. A delay like `#1` would mean 1 nanosecond, with 1 picosecond precision.

`default_nettype none` is a safety directive. It prevents Verilog from silently creating undeclared wires because of typos. This is good practice in RTL because a misspelled signal name should cause an error, not become an accidental new net.

At the bottom:

```verilog
`default_nettype wire
```

This restores the default behavior for files compiled afterward.

---

## Module parameters

The module starts with many parameters:

```verilog
parameter int DESCR_WIDTH = 64,
parameter int PA_WIDTH    = 32,
parameter int LIMIT_WIDTH = 15,
parameter int PAGE_SHIFT  = 12,
```

These make the module configurable. For example, `DESCR_WIDTH` controls the packed descriptor width, and `PA_WIDTH` controls physical address width.

The file also defines bit locations using parameters such as:

```verilog
parameter int R_DT_HI    = 33,
parameter int R_DT_LO    = 32,
parameter int R_I_BIT    = 63,
parameter int R_LIMIT_HI = 62,
parameter int R_LIMIT_LO = 48,
```

These specify where fields are stored inside the packed descriptor. For example, root descriptor type bits are stored at bits `[33:32]`, and the root limit field starts at bit 62.

This is useful because the bit layout can be changed from the parameter list without rewriting all the logic.

---

## Inputs and outputs

The module has inputs for three descriptor types.

Root descriptor inputs include:

```verilog
r_v_i
r_i_i
r_dt_i
r_limit_i
r_addr_i
```

Pointer descriptor inputs include:

```verilog
p_v_i
p_i_i
p_dt_i
p_limit_i
p_addr_i
```

Page descriptor inputs include:

```verilog
pg_v_i
pg_dt_i
pg_s_i
pg_wp_i
pg_ci_i
pg_m_i
pg_u_i
pg_pa_i
```

The packed descriptor output is:

```verilog
output reg [DESCR_WIDTH-1:0] packed_o
```

The unpack side takes:

```verilog
input wire [DESCR_WIDTH-1:0] packed_i
```

and produces decoded root, pointer, and page outputs.

A key detail: unpacking does not use `kind_i`. It decodes `packed_i` into all root, pointer, and page output groups at the same time. The surrounding design must know which group is meaningful.

---

## Valid-bit behavior

The comments explain an important compatibility detail: the valid signals are not stored as separate descriptor bits.

Instead:

```verilog
wire [1:0] r_dt_enc  = r_v_i  ? r_dt_i  : 2'b00;
wire [1:0] p_dt_enc  = p_v_i  ? p_dt_i  : 2'b00;
wire [1:0] pg_dt_enc = pg_v_i ? pg_dt_i : 2'b00;
```

This means:

- if `*_v_i` is true, the descriptor type field uses `*_dt_i`
- if `*_v_i` is false, descriptor type is forced to `2'b00`

On unpack, validity is reconstructed like this:

```verilog
r_v_o = (packed_i[R_DT_HI:R_DT_LO] != 2'b00);
```

So a descriptor is considered valid when its descriptor type field is not `00`.

---

## Packing logic

The first `always @*` block creates `packed_o`.

It starts by clearing the whole descriptor:

```verilog
packed_o = {DESCR_WIDTH{1'b0}};
```

This is important because it gives every bit a known default value and avoids accidental latch inference.

Then it uses a `case` statement:

```verilog
case (kind_i)
  KIND_ROOT: begin
    ...
  end

  KIND_PTR: begin
    ...
  end

  KIND_PAGE: begin
    ...
  end

  default: begin
    packed_o = {DESCR_WIDTH{1'b0}};
  end
endcase
```

For a root descriptor, it places fields into their defined bit positions:

```verilog
packed_o[R_I_BIT] = r_i_i;
packed_o[R_LIMIT_HI -: LIMIT_WIDTH] = r_limit_i;
packed_o[R_DT_HI:R_DT_LO] = r_dt_enc;
```

The syntax:

```verilog
[R_LIMIT_HI -: LIMIT_WIDTH]
```

is an indexed part-select. It means "start at `R_LIMIT_HI` and select `LIMIT_WIDTH` bits downward."

So if `R_LIMIT_HI = 62` and `LIMIT_WIDTH = 15`, this selects bits `[62:48]`.

For addresses, the module copies only the relevant aligned address bits:

```verilog
packed_o[R_ADDR_LO +: ROOT_ADDR_COPY_W] =
    r_addr_i[ROOT_ADDR_SRC_LO +: ROOT_ADDR_COPY_W];
```

The syntax:

```verilog
[start +: width]
```

means "start at `start` and select `width` bits upward."

So the module copies a slice of the source address into a slice of the descriptor.

---

## Unpacking logic

The second `always @*` block decodes `packed_i`.

For root descriptors:

```verilog
r_dt_o    = packed_i[R_DT_HI:R_DT_LO];
r_v_o     = (packed_i[R_DT_HI:R_DT_LO] != 2'b00);
r_i_o     = packed_i[R_I_BIT];
r_limit_o = packed_i[R_LIMIT_HI -: LIMIT_WIDTH];
```

Then it clears the output address:

```verilog
r_addr_o = {PA_WIDTH{1'b0}};
```

and copies the stored address bits back into the correct address position.

The page descriptor unpacking also forces low address bits to zero:

```verilog
pg_pa_o[PAGE_SHIFT-1:0] = {PAGE_SHIFT{1'b0}};
```

That reflects page alignment. For a `PAGE_SHIFT` of 12, the lower 12 bits are zero, meaning page addresses are aligned to 4 KiB boundaries.

---

## Local parameters

The module computes several helper constants:

```verilog
localparam int ROOT_ADDR_WIDTH = ...
localparam int ROOT_ADDR_COPY_W = ...
```

These calculate how many address bits can safely be copied between the physical address and the descriptor field.

This prevents the code from blindly copying more bits than exist in either the source address or the destination field.

---

## Initial validation checks

The `initial begin` block contains simulation-time checks:

```verilog
initial begin
  if (DESCR_WIDTH < 64) begin
    $fatal(...);
  end
  ...
end
```

These checks stop simulation if invalid parameter combinations are used.

For example, because this module's default bit layout assumes Motorola-style 64-bit long-format descriptors, it rejects `DESCR_WIDTH < 64`.

These checks are for simulation/elaboration safety. They are not ordinary runtime hardware behavior.

---

## Verilator lint comments

The file contains comments like:

```verilog
/* verilator lint_off UNUSED */
input wire [PA_WIDTH-1:0] r_addr_i,
/* verilator lint_on UNUSED */
```

These tell Verilator not to warn that parts of the address input may be unused.

That makes sense here because the module intentionally ignores low alignment bits and may not use all high address bits depending on parameter values.

---

## Important syntax notes

`parameter int` is SystemVerilog-style parameter syntax. Although the file extension is `.v`, this file uses some SystemVerilog features.

`input wire` declares input ports.

`output reg` is used because the outputs are assigned inside `always` blocks. In this code, `reg` does not mean a flip-flop. Since the block is combinational and has complete assignments, it describes combinational logic.

`always @*` means the sensitivity list is inferred automatically.

`case` selects which descriptor format to pack.

`begin ... end` groups multiple statements together.

Bit slicing syntax like `[33:32]`, `[R_LIMIT_HI -: LIMIT_WIDTH]`, and `[R_ADDR_LO +: ROOT_ADDR_COPY_W]` extracts or assigns specific bit ranges.

---

## Main gotchas

The biggest gotcha is that `r_v_i`, `p_v_i`, and `pg_v_i` are compatibility inputs, not actual stored descriptor bits. They control whether the descriptor type field is forced to invalid `00`.

Another gotcha is that packing is selected by `kind_i`, but unpacking is not. The unpack logic always decodes `packed_i` as root, pointer, and page at the same time.

Also, although outputs are declared as `reg`, this module does not create registers because there is no clocked `always @(posedge clk)` block.

Finally, unused descriptor fields are intentionally packed as zero because this module implements a limited long-format-oriented subset, not a complete Motorola PMMU descriptor implementation.