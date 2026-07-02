## What `perm_check.v` does

`perm_check.v` defines a combinational permission checker named `perm_check`. Its job is to decide whether one requested access is allowed under user or supervisor permissions, and to produce a compact diagnostic fault field when it is not allowed.

The checker understands three access classes:

- read
- write
- execute/fetch

It also understands two permission banks:

- user permissions, `u_perm`
- supervisor permissions, `s_perm`

This module does not decode Motorola descriptors directly. It consumes already-extracted permission bits and produces an allow/fault result.

---

## It is purely combinational logic

There is no clock, reset, state register, or `always` block. The module is built entirely from wires and continuous assignments.

Source: [rtl/core/perm_check.v:L83-L87](../../rtl/core/perm_check.v#L83-L87)

```verilog
assign allow = tt_bypass ? 1'b1
                         : (req_valid & perm_allow);

assign fault = tt_bypass ? 5'b00000
                         : { bad_req, priv_rel, no_exec, wr_prot, no_read };
```

Any change to the request bits, privilege bit, permission inputs, or transparent-translation bypass immediately changes the outputs after combinational delay.

---

## Interface

The request side provides one-hot access-class inputs plus privilege mode.

Source: [rtl/core/perm_check.v:L32-L40](../../rtl/core/perm_check.v#L32-L40)

```verilog
input  wire       req_r,
input  wire       req_w,
input  wire       req_x,
input  wire       is_user,

input  wire [2:0] u_perm,   // {UX, UW, UR}
input  wire [2:0] s_perm,   // {SX, SW, SR}

input  wire       tt_bypass,
```

The outputs are the final allow bit and a five-bit fault field.

Source: [rtl/core/perm_check.v:L42-L43](../../rtl/core/perm_check.v#L42-L43)

```verilog
output wire       allow,
output wire [4:0] fault
```

Exactly one of `req_r`, `req_w`, or `req_x` should be high for a normal access.

The permission vectors use this layout:

- bit 2: execute
- bit 1: write
- bit 0: read

---

## Request validity

The module first packs the request bits into one vector and checks whether the request is one-hot.

Source: [rtl/core/perm_check.v:L47-L52](../../rtl/core/perm_check.v#L47-L52)

```verilog
wire [2:0] req = {req_x, req_w, req_r};
wire       req_none = (req == 3'b000);
wire [1:0] req_sum = req[0] + req[1] + req[2];
wire       req_multi = (req_sum > 2'd1);
wire       bad_req = req_none | req_multi;
wire       req_valid = ~bad_req;
```

`bad_req` is true when no request bit is set or when more than one request bit is set.

This means both zero-hot and multi-hot access requests are invalid.

---

## Permission-bank selection

The active permission bank is selected by `is_user`.

Source: [rtl/core/perm_check.v:L55-L60](../../rtl/core/perm_check.v#L55-L60)

```verilog
wire [2:0] act_perm = is_user ? u_perm : s_perm;

// Decode individual bits
wire ur = act_perm[0];
wire uw = act_perm[1];
wire ux = act_perm[2];
```

If the access is user mode, `u_perm` controls the result. If it is supervisor mode, `s_perm` controls the result.

The selected permission bits are then matched to the requested access class.

Source: [rtl/core/perm_check.v:L63-L66](../../rtl/core/perm_check.v#L63-L66)

```verilog
wire allow_r = req_r & ur;
wire allow_w = req_w & uw;
wire allow_x = req_x & ux;
wire perm_allow = allow_r | allow_w | allow_x;
```

`perm_allow` is true when the requested access class is permitted by the active permission bank.

---

## Fault bits

The module creates individual denial bits before applying the optional transparent-translation bypass.

Source: [rtl/core/perm_check.v:L69-L75](../../rtl/core/perm_check.v#L69-L75)

```verilog
wire deny_r = req_r & ~ur;
wire deny_w = req_w & ~uw;
wire deny_x = req_x & ~ux;

wire no_read = deny_r;
wire wr_prot = deny_w;
wire no_exec = deny_x;
```

It also marks a denial as privilege-related when a user-mode access is denied but the supervisor bank would allow that same class.

Source: [rtl/core/perm_check.v:L78-L81](../../rtl/core/perm_check.v#L78-L81)

```verilog
wire priv_rel_r = is_user & deny_r & s_perm[0];
wire priv_rel_w = is_user & deny_w & s_perm[1];
wire priv_rel_x = is_user & deny_x & s_perm[2];
wire priv_rel   = priv_rel_r | priv_rel_w | priv_rel_x;
```

The final fault vector layout is:

- bit 4: bad request
- bit 3: privilege-related denial
- bit 2: no execute
- bit 1: write protect
- bit 0: no read

---

## Transparent-translation bypass

Transparent translation can bypass the normal permission result in this checker.

Source: [rtl/core/perm_check.v:L83-L87](../../rtl/core/perm_check.v#L83-L87)

```verilog
assign allow = tt_bypass ? 1'b1
                         : (req_valid & perm_allow);

assign fault = tt_bypass ? 5'b00000
                         : { bad_req, priv_rel, no_exec, wr_prot, no_read };
```

When `tt_bypass` is high, access is allowed and all diagnostic fault bits are cleared.

When `tt_bypass` is low, the request must be valid and permitted by the selected permission bank.

---

## Important syntax notes

The expression `{req_x, req_w, req_r}` concatenates three one-bit signals into a three-bit vector.

The expression `req[0] + req[1] + req[2]` creates a small population count for the request bits.

The ternary operator `condition ? a : b` selects between two values.

The fault output is built by concatenating named one-bit diagnostics into a packed vector.

---

## Main gotchas

The first gotcha is that this checker expects exactly one request class. Multiple request bits are denied and flagged as `bad_req`.

The second gotcha is that `tt_bypass` wins over all other logic, including bad request encoding. If bypass is high, `allow` is high and `fault` is zero.

The third gotcha is that `priv_rel` only reports user-mode denial where supervisor permissions would allow the same access. It does not assert for supervisor-mode denials.

Finally, this module does not know about descriptors, TLB hits, or bus cycles. It only checks a request against permission vectors already supplied by other logic.