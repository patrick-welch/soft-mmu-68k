## What `flush_ctrl.v` does

`flush_ctrl.v` defines a small sequential hardware module named `flush_ctrl`. Its job is to accept high-level MMU control commands and turn them into simple control pulses, request handshakes, and status results for the rest of the soft MMU.

In practical terms, it is the control shim for operations such as:

- **Flush all**: request that the whole TLB be flushed.
- **Flush match**: request that one address and function-code match be flushed.
- **Probe**: ask another block to probe an address/function-code pair and report the result.
- **Preload**: ask another block to begin a preload request.

This module is intentionally first-pass control logic. It is not a full architectural model of every `PFLUSH`, `PLOAD`, or `PTEST` detail. The comments in the RTL call that out directly, especially for the deferred full PTEST/MMUSR behavior.

---

## It is sequential control logic

Unlike `descriptor_pack.v`, this file is not purely combinational. It has a clock and reset:

Source: [rtl/core/flush_ctrl.v:L42-L43](../../rtl/core/flush_ctrl.v#L42-L43)

```verilog
input wire clk,
input wire rst_n,
```

The main behavior is inside:

Source: [rtl/core/flush_ctrl.v:L163](../../rtl/core/flush_ctrl.v#L163)

```verilog
always @(posedge clk) begin
```

That means the state and registered outputs update on the rising edge of `clk`.

The reset is active-low:

Source: [rtl/core/flush_ctrl.v:L164](../../rtl/core/flush_ctrl.v#L164)

```verilog
if (!rst_n) begin
```

When `rst_n` is low, the module returns to the idle state and clears all registered outputs to known values.

---

## Header directives

At the top:

Source: [rtl/core/flush_ctrl.v:L1-L2](../../rtl/core/flush_ctrl.v#L1-L2)

```verilog
`timescale 1ns/1ps
`default_nettype none
```

`timescale 1ns/1ps` controls simulation time units and precision. A delay like `#1` would mean 1 nanosecond, with 1 picosecond precision.

`default_nettype none` is a safety directive. It prevents Verilog from silently creating undeclared wires because of typos. In RTL, that is important because a misspelled signal should cause an error instead of becoming an accidental net.

At the bottom:

Source: [rtl/core/flush_ctrl.v:L271](../../rtl/core/flush_ctrl.v#L271)

```verilog
`default_nettype wire
```

This restores normal Verilog default-net behavior for files compiled afterward.

---

## Module parameters

The module begins with width parameters:

Source: [rtl/core/flush_ctrl.v:L30-L34](../../rtl/core/flush_ctrl.v#L30-L34)

```verilog
parameter integer VA_WIDTH     = 24,
parameter integer PA_WIDTH     = 24,
parameter integer FC_WIDTH     = 3,
parameter integer STATUS_WIDTH = 8,
parameter integer CMD_WIDTH    = 3,
```

These let the same control block adapt to different address, function-code, status, and command widths.

The module also defines command encodings:

Source: [rtl/core/flush_ctrl.v:L36-L40](../../rtl/core/flush_ctrl.v#L36-L40)

```verilog
parameter [CMD_WIDTH-1:0] CMD_NOP         = 3'd0,
parameter [CMD_WIDTH-1:0] CMD_FLUSH_ALL   = 3'd1,
parameter [CMD_WIDTH-1:0] CMD_FLUSH_MATCH = 3'd2,
parameter [CMD_WIDTH-1:0] CMD_PROBE       = 3'd3,
parameter [CMD_WIDTH-1:0] CMD_PRELOAD     = 3'd4
```

These command values are compared against `cmd_op_i` when a command is accepted.

---

## Command input interface

The command input side is:

Source: [rtl/core/flush_ctrl.v:L45-L50](../../rtl/core/flush_ctrl.v#L45-L50)

```verilog
input  wire                 cmd_valid_i,
input  wire [CMD_WIDTH-1:0] cmd_op_i,
input  wire [VA_WIDTH-1:0]  cmd_addr_i,
input  wire [FC_WIDTH-1:0]  cmd_fc_i,
output wire                 cmd_ready_o,
output wire                 busy_o,
```

`cmd_valid_i` tells `flush_ctrl` that a command is being presented.

`cmd_op_i` selects which command is being requested.

`cmd_addr_i` carries the virtual address operand for commands that need an address.

`cmd_fc_i` carries the 68k function-code operand for commands that need address-space classification.

`cmd_ready_o` is true only when the state machine is idle:

Source: [rtl/core/flush_ctrl.v:L139](../../rtl/core/flush_ctrl.v#L139)

```verilog
assign cmd_ready_o = (state_q == ST_IDLE);
```

`busy_o` is true when the state machine is not idle:

Source: [rtl/core/flush_ctrl.v:L140](../../rtl/core/flush_ctrl.v#L140)

```verilog
assign busy_o = (state_q != ST_IDLE);
```

The important handshake rule is simple: this module accepts a new command only while it is in `ST_IDLE`.

---

## Flush outputs

The flush output side is:

Source: [rtl/core/flush_ctrl.v:L52-L55](../../rtl/core/flush_ctrl.v#L52-L55)

```verilog
output reg                 flush_all_o,
output reg                 flush_match_o,
output reg [VA_WIDTH-1:0]  flush_addr_o,
output reg [FC_WIDTH-1:0]  flush_fc_o,
```

`flush_all_o` is a one-cycle pulse for whole-TLB flush requests.

`flush_match_o` is a one-cycle pulse for targeted flush requests.

For a targeted flush, the module also latches the address and function code into:

Source: [rtl/core/flush_ctrl.v:L54-L55](../../rtl/core/flush_ctrl.v#L54-L55)

```verilog
flush_addr_o
flush_fc_o
```

Those operand outputs tell the downstream TLB logic which virtual address and function-code combination should be matched.

---

## Probe request and response interface

The probe request side is:

Source: [rtl/core/flush_ctrl.v:L57-L59](../../rtl/core/flush_ctrl.v#L57-L59)

```verilog
output reg                probe_req_valid_o,
output reg [VA_WIDTH-1:0] probe_addr_o,
output reg [FC_WIDTH-1:0] probe_fc_o,
```

When a probe command is accepted, `flush_ctrl` pulses `probe_req_valid_o`, drives `probe_addr_o` and `probe_fc_o`, saves the probed address internally, and moves to `ST_WAIT_PROBE`.

The probe response side is:

Source: [rtl/core/flush_ctrl.v:L60-L63](../../rtl/core/flush_ctrl.v#L60-L63)

```verilog
input wire                    probe_resp_valid_i,
input wire                    probe_resp_hit_i,
input wire [PA_WIDTH-1:0]     probe_resp_pa_i,
input wire [STATUS_WIDTH-1:0] probe_resp_status_i,
```

`probe_resp_valid_i` tells the state machine that the probe result is ready.

`probe_resp_hit_i` says whether the translation path found a normal translated hit.

`probe_resp_pa_i` carries the physical address result for a translated hit.

`probe_resp_status_i` carries status bits from the probe path, including the TT/TTR match indication used by this first-pass model.

---

## Preload request interface

The preload request side is:

Source: [rtl/core/flush_ctrl.v:L65-L68](../../rtl/core/flush_ctrl.v#L65-L68)

```verilog
output reg                preload_req_valid_o,
output reg [VA_WIDTH-1:0] preload_addr_o,
output reg [FC_WIDTH-1:0] preload_fc_o,
input  wire               preload_req_ready_i,
```

When a preload command is accepted, the module asserts `preload_req_valid_o`, drives the address and function code, and moves to `ST_WAIT_PRELOAD`.

The module stays in `ST_WAIT_PRELOAD` until `preload_req_ready_i` is true. At that point it clears `preload_req_valid_o`, returns to idle, and emits a simple completion status.

This is only a request/ready control model. It does not model a complete page-table walk or preload completion result.

---

## Status output interface

The status output side is:

Source: [rtl/core/flush_ctrl.v:L70-L74](../../rtl/core/flush_ctrl.v#L70-L74)

```verilog
output reg                  status_valid_o,
output reg [CMD_WIDTH-1:0]  status_cmd_o,
output reg                  status_hit_o,
output reg [PA_WIDTH-1:0]   status_pa_o,
output reg [STATUS_WIDTH-1:0] status_bits_o
```

`status_valid_o` pulses when the module has a command result to report.

`status_cmd_o` records which command produced the status.

`status_hit_o` is meaningful for probe-style results. For flush and preload completion statuses, this module drives it low.

`status_pa_o` carries the reported physical address for probe results. For non-probe statuses, it is driven to zero.

`status_bits_o` carries status classification bits. For flush and preload completion statuses, this module drives those bits to zero.

---

## State machine

The state machine has three states:

Source: [rtl/core/flush_ctrl.v:L77-L79](../../rtl/core/flush_ctrl.v#L77-L79)

```verilog
localparam [1:0] ST_IDLE         = 2'd0;
localparam [1:0] ST_WAIT_PROBE   = 2'd1;
localparam [1:0] ST_WAIT_PRELOAD = 2'd2;
```

The current state is stored in:

Source: [rtl/core/flush_ctrl.v:L83](../../rtl/core/flush_ctrl.v#L83)

```verilog
reg [1:0] state_q;
```

The states mean:

- `ST_IDLE`: ready to accept a new command.
- `ST_WAIT_PROBE`: waiting for `probe_resp_valid_i`.
- `ST_WAIT_PRELOAD`: waiting for `preload_req_ready_i`.

There is also one saved operand register:

Source: [rtl/core/flush_ctrl.v:L84](../../rtl/core/flush_ctrl.v#L84)

```verilog
reg [VA_WIDTH-1:0] probe_addr_q;
```

That register preserves the probed virtual address so a transparent-translation result can mirror the original VA into `status_pa_o`.

---

## Reset behavior

On reset, the module does three important things.

First, it returns the state machine to idle:

Source: [rtl/core/flush_ctrl.v:L165](../../rtl/core/flush_ctrl.v#L165)

```verilog
state_q <= ST_IDLE;
```

Second, it clears saved operands and command outputs:

Source: [rtl/core/flush_ctrl.v:L166-L170](../../rtl/core/flush_ctrl.v#L166-L170)

```verilog
probe_addr_q <= {VA_WIDTH{1'b0}};
flush_addr_o <= {VA_WIDTH{1'b0}};
flush_fc_o   <= {FC_WIDTH{1'b0}};
```

Third, it clears every pulse, request, and status output:

Source: [rtl/core/flush_ctrl.v:L167-L181](../../rtl/core/flush_ctrl.v#L167-L181)

```verilog
flush_all_o         <= 1'b0;
flush_match_o       <= 1'b0;
probe_req_valid_o   <= 1'b0;
preload_req_valid_o <= 1'b0;
status_valid_o      <= 1'b0;
```

This makes the reset state deterministic and prevents stale control pulses or stale status from leaking out after reset.

---

## Default behavior each cycle

In the non-reset path, several pulse-like outputs are cleared at the start of every clock cycle:

Source: [rtl/core/flush_ctrl.v:L183-L186](../../rtl/core/flush_ctrl.v#L183-L186)

```verilog
flush_all_o       <= 1'b0;
flush_match_o     <= 1'b0;
probe_req_valid_o <= 1'b0;
status_valid_o    <= 1'b0;
```

This is why `flush_all_o`, `flush_match_o`, `probe_req_valid_o`, and `status_valid_o` behave as one-cycle pulses unless a later branch in the same clocked block assigns them high.

Notice that `preload_req_valid_o` is not cleared in this default group. That is intentional: preload valid remains asserted while the module waits in `ST_WAIT_PRELOAD`, and is cleared only when `preload_req_ready_i` is observed.

---

## Flush-all command

In `ST_IDLE`, when `cmd_valid_i` is true and `cmd_op_i` is `CMD_FLUSH_ALL`, the module does this:

Source: [rtl/core/flush_ctrl.v:L192-L198](../../rtl/core/flush_ctrl.v#L192-L198)

```verilog
flush_all_o    <= 1'b1;
status_valid_o <= 1'b1;
status_cmd_o   <= CMD_FLUSH_ALL;
status_hit_o   <= 1'b0;
status_pa_o    <= {PA_WIDTH{1'b0}};
status_bits_o  <= {STATUS_WIDTH{1'b0}};
```

The flush request is a one-cycle pulse. The module also emits a one-cycle status record saying that a flush-all command was accepted.

The state stays idle because there is no multi-cycle response to wait for.

---

## Targeted flush command

For `CMD_FLUSH_MATCH`, the module emits a targeted flush pulse:

Source: [rtl/core/flush_ctrl.v:L201-L206](../../rtl/core/flush_ctrl.v#L201-L206)

```verilog
flush_match_o  <= 1'b1;
flush_addr_o   <= cmd_addr_i;
flush_fc_o     <= cmd_fc_i;
status_valid_o <= 1'b1;
status_cmd_o   <= CMD_FLUSH_MATCH;
```

The address and function code are copied from the command input into the flush operand outputs.

Like `CMD_FLUSH_ALL`, this command completes immediately from the state machine's point of view, so the module remains in `ST_IDLE`.

---

## Probe command

For `CMD_PROBE`, the module starts a probe request:

Source: [rtl/core/flush_ctrl.v:L212-L217](../../rtl/core/flush_ctrl.v#L212-L217)

```verilog
probe_req_valid_o <= 1'b1;
probe_addr_o      <= cmd_addr_i;
probe_fc_o        <= cmd_fc_i;
probe_addr_q      <= cmd_addr_i;
state_q           <= ST_WAIT_PROBE;
```

The request valid output is a one-cycle pulse. The probed address and function code are driven to the probe path.

The module also saves the virtual address in `probe_addr_q`. This saved copy matters later if the response indicates a transparent translation match.

After launching the request, the state machine moves to `ST_WAIT_PROBE`. While in that state, `cmd_ready_o` is false and `busy_o` is true.

---

## Probe response handling

In `ST_WAIT_PROBE`, the module waits for:

Source: [rtl/core/flush_ctrl.v:L238-L239](../../rtl/core/flush_ctrl.v#L238-L239)

```verilog
probe_resp_valid_i
```

When the response arrives, it returns to idle and emits a status record:

Source: [rtl/core/flush_ctrl.v:L240-L246](../../rtl/core/flush_ctrl.v#L240-L246)

```verilog
state_q        <= ST_IDLE;
status_valid_o <= 1'b1;
status_cmd_o   <= CMD_PROBE;
status_hit_o   <= probe_status_hit(probe_resp_hit_i, probe_resp_status_i);
status_pa_o    <= is_tt_match_status(probe_resp_status_i) ? va_to_status_pa(probe_addr_q)
                                                          : probe_resp_pa_i;
status_bits_o  <= normalize_probe_status(probe_resp_hit_i, probe_resp_status_i);
```

There are two important cases.

For a normal translated hit, the status hit bit is true, the translated-status bit is set, and the physical address comes from `probe_resp_pa_i`.

For a transparent-translation match, the status hit bit is also true, but the physical address mirrors the probed virtual address resized to `PA_WIDTH`. This matches the file header's first-pass TT/TTR-aware behavior.

For a miss, this shim does not force extra class bits. It reports the normalized status according to the helper functions.

---

## Preload command

For `CMD_PRELOAD`, the module starts a preload request:

Source: [rtl/core/flush_ctrl.v:L220-L224](../../rtl/core/flush_ctrl.v#L220-L224)

```verilog
preload_req_valid_o <= 1'b1;
preload_addr_o      <= cmd_addr_i;
preload_fc_o        <= cmd_fc_i;
state_q             <= ST_WAIT_PRELOAD;
```

Unlike the probe request valid signal, `preload_req_valid_o` is not automatically cleared on the next cycle. It remains asserted while the state machine waits for `preload_req_ready_i`.

That gives the downstream preload logic a level-style valid signal that stays high until the request is accepted.

---

## Preload ready handling

In `ST_WAIT_PRELOAD`, the module watches:

Source: [rtl/core/flush_ctrl.v:L250-L251](../../rtl/core/flush_ctrl.v#L250-L251)

```verilog
preload_req_ready_i
```

When ready is true, the module completes the request:

Source: [rtl/core/flush_ctrl.v:L252-L258](../../rtl/core/flush_ctrl.v#L252-L258)

```verilog
preload_req_valid_o <= 1'b0;
state_q             <= ST_IDLE;
status_valid_o      <= 1'b1;
status_cmd_o        <= CMD_PRELOAD;
status_hit_o        <= 1'b0;
status_pa_o         <= {PA_WIDTH{1'b0}};
status_bits_o       <= {STATUS_WIDTH{1'b0}};
```

This status means the preload request handshake completed. It does not mean a full architectural preload operation, page walk, or final translation result has been modeled.

---

## Default and unknown commands

If `cmd_op_i` does not match one of the implemented commands, the default branch emits a `CMD_NOP` status:

Source: [rtl/core/flush_ctrl.v:L227-L232](../../rtl/core/flush_ctrl.v#L227-L232)

```verilog
status_valid_o <= 1'b1;
status_cmd_o   <= CMD_NOP;
status_hit_o   <= 1'b0;
status_pa_o    <= {PA_WIDTH{1'b0}};
status_bits_o  <= {STATUS_WIDTH{1'b0}};
```

This gives the caller a visible completion indication even for an unrecognized command encoding.

There is also a default state-machine branch:

Source: [rtl/core/flush_ctrl.v:L262-L264](../../rtl/core/flush_ctrl.v#L262-L264)

```verilog
default: begin
  state_q             <= ST_IDLE;
  preload_req_valid_o <= 1'b0;
end
```

That branch recovers to idle if the state register ever holds an unexpected value.

---

## TT/TTR status bits

The module defines two status bit positions:

Source: [rtl/core/flush_ctrl.v:L80-L81](../../rtl/core/flush_ctrl.v#L80-L81)

```verilog
localparam integer STATUS_BIT_TT_MATCH   = STATUS_WIDTH - 1;
localparam integer STATUS_BIT_TRANSLATED = STATUS_WIDTH - 2;
```

The top status bit is treated as the transparent-translation match bit.

The next bit down is treated as the translated-result bit.

This is a local first-pass status convention used by this shim. It should not be described as a complete architecturally final MMUSR model.

---

## Helper function: `va_to_status_pa`

The `va_to_status_pa` function resizes a virtual address into a physical-address-width value:

Source: [rtl/core/flush_ctrl.v:L86-L88](../../rtl/core/flush_ctrl.v#L86-L88)

```verilog
function automatic [PA_WIDTH-1:0] va_to_status_pa(
  input [VA_WIDTH-1:0] va_i
);
```

It starts by clearing the output:

Source: [rtl/core/flush_ctrl.v:L91](../../rtl/core/flush_ctrl.v#L91)

```verilog
va_to_status_pa = {PA_WIDTH{1'b0}};
```

Then it copies address bits one at a time while the destination index is still inside the virtual-address width:

Source: [rtl/core/flush_ctrl.v:L92-L96](../../rtl/core/flush_ctrl.v#L92-L96)

```verilog
for (idx = 0; idx < PA_WIDTH; idx = idx + 1) begin
  if (idx < VA_WIDTH) begin
    va_to_status_pa[idx] = va_i[idx];
  end
end
```

If `PA_WIDTH` is wider than `VA_WIDTH`, the high physical-address bits remain zero. If `PA_WIDTH` is narrower than `VA_WIDTH`, only the low `PA_WIDTH` bits are copied.

This function is used when a probe response says the address matched transparent translation, so the status PA should mirror the probed VA rather than use `probe_resp_pa_i`.

---

## Helper function: `is_tt_match_status`

The `is_tt_match_status` function reads the transparent-translation match bit from a status value:

Source: [rtl/core/flush_ctrl.v:L100-L102](../../rtl/core/flush_ctrl.v#L100-L102)

```verilog
function automatic is_tt_match_status(
  input [STATUS_WIDTH-1:0] status_i
);
```

The key line is:

Source: [rtl/core/flush_ctrl.v:L105](../../rtl/core/flush_ctrl.v#L105)

```verilog
is_tt_match_status = status_i[STATUS_BIT_TT_MATCH];
```

Because `STATUS_BIT_TT_MATCH` is `STATUS_WIDTH - 1`, this checks the top bit of the status field.

The function includes a defensive branch for `STATUS_WIDTH >= 1`, but the `initial` parameter checks already require `STATUS_WIDTH` to be at least 2.

---

## Helper function: `normalize_probe_status`

The `normalize_probe_status` function adjusts probe status bits before reporting them:

Source: [rtl/core/flush_ctrl.v:L112-L115](../../rtl/core/flush_ctrl.v#L112-L115)

```verilog
function automatic [STATUS_WIDTH-1:0] normalize_probe_status(
  input                    resp_hit_i,
  input [STATUS_WIDTH-1:0] resp_status_i
);
```

It starts with the response status as the default:

Source: [rtl/core/flush_ctrl.v:L118](../../rtl/core/flush_ctrl.v#L118)

```verilog
status_v = resp_status_i;
```

Then it applies this rule:

Source: [rtl/core/flush_ctrl.v:L120-L124](../../rtl/core/flush_ctrl.v#L120-L124)

```verilog
if (is_tt_match_status(resp_status_i)) begin
  status_v[STATUS_BIT_TRANSLATED] = 1'b0;
end else if (resp_hit_i) begin
  status_v[STATUS_BIT_TRANSLATED] = 1'b1;
end
```

So a transparent-translation match clears the translated bit, while a normal hit sets the translated bit.

This keeps the two status classes distinct in the first-pass status result.

---

## Helper function: `probe_status_hit`

The `probe_status_hit` function computes the `status_hit_o` value for probe results:

Source: [rtl/core/flush_ctrl.v:L130-L135](../../rtl/core/flush_ctrl.v#L130-L135)

```verilog
probe_status_hit = resp_hit_i | is_tt_match_status(resp_status_i);
```

That means a probe counts as a hit if either:

- the translation response reports a normal hit, or
- the status bits report a transparent-translation match.

This matches the header comment: both translated results and transparent bypasses report `status_hit_o = 1`.

---

## Initial validation checks

The `initial begin` block contains simulation/elaboration checks for invalid parameter combinations:

Source: [rtl/core/flush_ctrl.v:L142-L160](../../rtl/core/flush_ctrl.v#L142-L160)

```verilog
initial begin
  if (VA_WIDTH < 1) begin
    $fatal(1, "flush_ctrl VA_WIDTH must be >= 1");
  end
  ...
end
```

The checks require:

- `VA_WIDTH >= 1`
- `PA_WIDTH >= 1`
- `FC_WIDTH >= 1`
- `STATUS_WIDTH >= 2`
- `CMD_WIDTH >= 3`

`STATUS_WIDTH` must be at least 2 because this module reserves two status bits for TT/TTR-aware classification: one for transparent-translation match and one for translated result.

These checks are not ordinary runtime hardware behavior. They are there to catch bad parameter choices during simulation or elaboration.

---

## Important syntax notes

`parameter integer` defines compile-time configuration values.

`localparam` defines constants that cannot be overridden by module instantiation.

`input wire` declares input ports.

`output reg` is used for outputs assigned inside the clocked `always` block. In this file, those `reg` outputs are real sequential registers because they are assigned inside `always @(posedge clk)`.

`<=` is a nonblocking assignment. It is the normal style for sequential logic because all left-hand-side registers update together on the clock edge.

`assign` is used for continuous combinational outputs such as `cmd_ready_o` and `busy_o`.

`function automatic` defines a reentrant helper function. The functions here are used to compute resized addresses and normalized status values.

`case` selects behavior based on the state machine state and the command opcode.

---

## Main gotchas

The first gotcha is that this module accepts only one in-flight probe or preload at a time. Once it leaves `ST_IDLE`, `cmd_ready_o` goes low and new commands are not accepted until the outstanding operation completes.

The second gotcha is that flush outputs are pulses, but preload valid is level-held. `flush_all_o`, `flush_match_o`, `probe_req_valid_o`, and `status_valid_o` are cleared by default each cycle. `preload_req_valid_o` stays high in `ST_WAIT_PRELOAD` until `preload_req_ready_i` is true.

The third gotcha is that probe transparent-translation handling does not use `probe_resp_pa_i`. For a TT/TTR match, `status_pa_o` is derived from the saved virtual address using `va_to_status_pa`.

The fourth gotcha is that the status bits are a first-pass local convention. The module distinguishes translated hits from transparent-translation matches, but it does not implement a full architectural PTEST/MMUSR status model.

Finally, this module is a control shim. It emits flush pulses, probe requests, preload requests, and small status records, but the actual TLB invalidation, translation probe, transparent-translation comparison, and preload walk behavior live outside this file.