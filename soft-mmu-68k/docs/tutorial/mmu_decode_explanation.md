# `mmu_decode.v` Tutorial

> This tutorial explains the current SM68861 RTL implementation. It is not a
> complete Motorola PMMU specification and should not be read as a compatibility
> claim beyond the behavior implemented and tested in this repository.

## What `mmu_decode.v` does

`mmu_decode.v` defines a small combinational helper named `mmu_decode`. Its job is to interpret the Motorola 68k function-code field and turn it into simple classification signals for the rest of the MMU.

The input is the 3-bit function code, usually written as `FC[2:0]`. The outputs answer practical questions such as:

- is this user space or supervisor space?
- is this a program access or a data access?
- is this CPU/special space?

This module does not translate addresses, check permissions, or store state. It only decodes the function-code class.

---

## Not implemented here

This module does not validate full Motorola function-code legality, perform address translation, enforce permissions, or store MMU state. It only classifies the function-code bits used by the current RTL.

---

## It is purely combinational logic

There is no clock, reset, or `always` block in this file. All outputs are driven by continuous assignments from the current value of `fc`.

Source: [rtl/core/mmu_decode.v:L39-L44](../../rtl/core/mmu_decode.v#L39-L44)

```verilog
assign is_super  = fc[2];
assign is_user   = ~fc[2];
assign cpu_space = fc_cpu_space;

assign is_program = fc_user_prog | fc_super_prog;
assign is_data    = fc_user_data | fc_super_data;
```

Because the logic is continuous, any change on `fc` immediately changes the decoded outputs after normal combinational propagation delay.

---

## Interface

The module has one input and five classification outputs.

Source: [rtl/core/mmu_decode.v:L24-L30](../../rtl/core/mmu_decode.v#L24-L30)

```verilog
input  wire [2:0] fc,          // Function code from core

output wire       is_user,     // 1 = user space
output wire       is_super,    // 1 = supervisor space
output wire       is_program,  // 1 = program access for a valid memory-space FC
output wire       is_data,     // 1 = data access    for a valid memory-space FC
output wire       cpu_space    // 1 = CPU/special space (FC == 3'b111)
```

`fc` is the raw Motorola-style function code from the CPU side of the design.

`is_user` and `is_super` split the access by privilege class.

`is_program` and `is_data` identify normal memory-space program/data accesses.

`cpu_space` identifies the explicit CPU/special-space code.

---

## Function-code classes

The file creates named wires for the valid function-code classes implemented by this first-pass decoder.

Source: [rtl/core/mmu_decode.v:L33-L37](../../rtl/core/mmu_decode.v#L33-L37)

```verilog
wire fc_user_data   = (fc == 3'b001);
wire fc_user_prog   = (fc == 3'b010);
wire fc_super_data  = (fc == 3'b101);
wire fc_super_prog  = (fc == 3'b110);
wire fc_cpu_space   = (fc == 3'b111);
```

The supported normal memory encodings are:

- `3'b001`: user data
- `3'b010`: user program
- `3'b101`: supervisor data
- `3'b110`: supervisor program

The explicit CPU/special-space encoding is:

- `3'b111`: CPU/special space

The reserved encodings `3'b000` and `3'b100` are not treated as normal memory accesses in this first pass.

---

## User and supervisor decode

The privilege decode uses bit 2 of the function code directly.

Source: [rtl/core/mmu_decode.v:L39-L40](../../rtl/core/mmu_decode.v#L39-L40)

```verilog
assign is_super  = fc[2];
assign is_user   = ~fc[2];
```

That means any function code with `fc[2] = 1` is classified as supervisor, and any function code with `fc[2] = 0` is classified as user.

This includes reserved encodings. For example, `3'b000` still makes `is_user` true even though it is not a valid normal memory class in this decoder.

---

## Program, data, and CPU-space outputs

Program and data outputs assert only for the explicit valid memory-space encodings.

Source: [rtl/core/mmu_decode.v:L41-L44](../../rtl/core/mmu_decode.v#L41-L44)

```verilog
assign cpu_space = fc_cpu_space;

assign is_program = fc_user_prog | fc_super_prog;
assign is_data    = fc_user_data | fc_super_data;
```

This is the important distinction from the privilege outputs. `is_user` and `is_super` are simple bit-2 classifications, but `is_program`, `is_data`, and `cpu_space` require one of the implemented function-code values.

For reserved encodings, all three of these outputs are low:

- `is_program = 0`
- `is_data = 0`
- `cpu_space = 0`

That lets downstream logic treat reserved function codes as not being normal memory accesses.

---

## Important syntax notes

`wire` declarations create combinational nets.

`assign` statements continuously drive output nets.

Equality comparisons such as `(fc == 3'b001)` produce one-bit true/false results.

The bit select `fc[2]` reads the high privilege-class bit of the three-bit function code.

There is no `default_nettype none` directive in this file. That is different from several other core RTL files, so typo protection depends on the surrounding compile setup for this module.

---

## Main gotchas

The first gotcha is that `is_user` and `is_super` are not validity checks. They simply reflect `fc[2]` and `~fc[2]`.

The second gotcha is that reserved function-code values do not assert `is_program`, `is_data`, or `cpu_space`. They are intentionally classified as not-normal-memory in this first-pass interface.

The third gotcha is that CPU/special space is separate from supervisor data/program space. `3'b111` sets `cpu_space`, but it does not set `is_program` or `is_data`.

Finally, this module is only a decoder. Permission checking, transparent translation matching, TLB lookup, and page walking are handled by other modules.