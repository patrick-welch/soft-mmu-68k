## What `mmu_top.v` does

`mmu_top.v` defines the first-pass integration wrapper for the core soft MMU path. It wires together the register block, function-code decoder, transparent-translation matching, direct-mapped TLB, page-table walker, permission checkers, and flush/probe/preload control.

At a high level, this module handles two kinds of activity:

- CPU translation requests, through `req_valid_i` and the response outputs
- MMU control commands, through the `cmd_*` and `status_*` ports

This is intentionally a subset implementation. The header comments call out single outstanding translation requests, direct-mapped TLB lookup, minimal walker-backed refill, first-pass TT/TTR qualification, and deferred full Motorola MMUSR/PTEST behavior.

---

## It is the core integration point

The module parameters configure address widths, page geometry, TLB size, attribute/status widths, command encodings, and response fault encodings.

Source: [rtl/core/mmu_top.v:L28-L48](../../rtl/core/mmu_top.v#L28-L48)

```verilog
module mmu_top #(
  parameter integer VA_WIDTH      = 24,
  parameter integer PA_WIDTH      = 24,
  parameter integer PAGE_SHIFT    = 12,
  parameter integer FC_WIDTH      = 3,
  parameter integer DESCR_WIDTH   = 64,
  parameter integer TLB_ENTRIES   = 16,
  parameter integer ATTR_WIDTH    = 5,
  parameter integer STATUS_WIDTH  = 8,
  parameter integer CMD_WIDTH     = 3,
  parameter integer RESP_FAULT_W  = 3,
```

These parameters are passed down into the submodules so the wrapper, TLB, walker, register block, and control path agree on widths.

---

## CPU request and response interface

The CPU-side request provides a virtual address, function code, read/write indicator, and fetch indicator.

Source: [rtl/core/mmu_top.v:L53-L68](../../rtl/core/mmu_top.v#L53-L68)

```verilog
input  wire                    req_valid_i,
output wire                    req_ready_o,
input  wire [VA_WIDTH-1:0]     req_va_i,
input  wire [FC_WIDTH-1:0]     req_fc_i,
input  wire                    req_rw_i,
input  wire                    req_fetch_i,

output reg                     resp_valid_o,
output reg  [PA_WIDTH-1:0]     resp_pa_o,
output reg                     resp_hit_o,
output reg                     resp_fault_o,
output reg  [RESP_FAULT_W-1:0] resp_fault_code_o,
output reg  [4:0]              resp_perm_fault_o,
```

`req_ready_o` is high only when the top-level state machine is idle.

`resp_valid_o` marks a completed response. The response can be a transparent-translation bypass, a TLB hit result, a walker-backed result, or a fault result.

The permission-check connections show the local convention for `req_rw_i`: for non-fetch CPU requests, `req_rw_i = 1` is treated as read and `req_rw_i = 0` is treated as write.

---

## Register, command, and walker ports

The register access interface connects software-visible register reads and writes to `mmu_regs`.

Source: [rtl/core/mmu_top.v:L70-L75](../../rtl/core/mmu_top.v#L70-L75)

```verilog
input  wire                    reg_wr_en_i,
input  wire                    reg_rd_en_i,
input  wire [3:0]              reg_addr_i,
input  wire [31:0]             reg_wr_data_i,
output wire [31:0]             reg_rd_data_o,
```

The command interface connects to `flush_ctrl` for flush, probe, and preload commands.

Source: [rtl/core/mmu_top.v:L77-L89](../../rtl/core/mmu_top.v#L77-L89)

```verilog
input  wire                    cmd_valid_i,
input  wire [CMD_WIDTH-1:0]    cmd_op_i,
input  wire [VA_WIDTH-1:0]     cmd_addr_i,
input  wire [FC_WIDTH-1:0]     cmd_fc_i,
output wire                    cmd_ready_o,
output wire                    cmd_busy_o,
output wire                    status_valid_o,
output wire [CMD_WIDTH-1:0]    status_cmd_o,
output wire                    status_hit_o,
output wire [PA_WIDTH-1:0]     status_pa_o,
output wire [STATUS_WIDTH-1:0] status_bits_o,
```

The walker memory interface is the abstract descriptor-read bus used by `pt_walker`.

Source: [rtl/core/mmu_top.v:L91-L93](../../rtl/core/mmu_top.v#L91-L93)

```verilog
output wire                    walk_mem_req_valid_o,
output wire [PA_WIDTH-1:0]     walk_mem_req_addr_o,
input  wire                    walk_mem_resp_valid_i,
```

The full port list also includes descriptor data, memory response error, and the combined `busy_o` output.

---

## Local state and fault encodings

The top-level state machine has three states.

Source: [rtl/core/mmu_top.v:L96-L107](../../rtl/core/mmu_top.v#L96-L107)

```verilog
localparam integer VPN_WIDTH = VA_WIDTH - PAGE_SHIFT;
localparam integer TTR_KEY_WIDTH = (VA_WIDTH >= 8) ? 8 : VA_WIDTH;
localparam integer STATUS_BIT_TT_MATCH = STATUS_WIDTH - 1;

localparam [1:0] ST_IDLE       = 2'd0;
localparam [1:0] ST_START_WALK = 2'd1;
localparam [1:0] ST_WAIT_WALK  = 2'd2;

localparam [1:0] WALK_FAULT_NONE     = 2'b00;
localparam [1:0] WALK_FAULT_INVALID  = 2'b01;
localparam [1:0] WALK_FAULT_UNMAPPED = 2'b10;
localparam [1:0] WALK_FAULT_BUS      = 2'b11;
```

`ST_IDLE` can perform a CPU lookup or service a preload lookup.

`ST_START_WALK` launches the walker for one cycle.

`ST_WAIT_WALK` waits for the walker to finish.

The walker fault codes are local two-bit values that later get translated into the public response fault code values.

---

## Pending request registers

When the top-level path needs to wait for the walker, it saves the current request information.

Source: [rtl/core/mmu_top.v:L109-L120](../../rtl/core/mmu_top.v#L109-L120)

```verilog
reg [1:0]          state_q;
reg                pending_is_cpu_q;
reg [VA_WIDTH-1:0] pending_va_q;
reg [FC_WIDTH-1:0] pending_fc_q;
reg                pending_rw_q;
reg                pending_fetch_q;

reg                probe_pending_q;
reg [VA_WIDTH-1:0] probe_addr_q;
reg [FC_WIDTH-1:0] probe_fc_q;
```

`pending_is_cpu_q` distinguishes a real CPU request from a preload-driven walk. CPU requests eventually produce CPU responses. Preload walks refill the TLB but do not produce CPU responses from this top-level state machine.

`probe_pending_q` is a one-cycle bridge used to feed probe lookup results back into `flush_ctrl`.

---

## Lookup source arbitration

The design chooses one lookup source at a time: CPU, probe, or preload.

Source: [rtl/core/mmu_top.v:L148-L166](../../rtl/core/mmu_top.v#L148-L166)

```verilog
wire state_idle = (state_q == ST_IDLE);
wire walker_start = (state_q == ST_START_WALK);

wire preload_accept = state_idle && !req_valid_i && !probe_pending_q;

wire lookup_src_cpu     = state_idle && req_valid_i;
wire lookup_src_probe   = !lookup_src_cpu && probe_pending_q;
wire lookup_src_preload = !lookup_src_cpu && !lookup_src_probe &&
                          preload_req_valid && preload_accept;

wire lookup_valid = lookup_src_cpu || lookup_src_probe || lookup_src_preload;
wire [VA_WIDTH-1:0] lookup_va = lookup_src_cpu     ? req_va_i :
                                lookup_src_probe   ? probe_addr_q :
                                lookup_src_preload ? preload_req_addr :
                                                     {VA_WIDTH{1'b0}};
```

CPU lookup has priority over probe lookup, and probe lookup has priority over preload lookup.

Preload lookup is accepted only when the MMU is idle, no CPU request is present, and no probe response is pending.

---

## Ready and busy outputs

The top-level ready and busy outputs summarize the state of the integration wrapper and child blocks.

Source: [rtl/core/mmu_top.v:L292-L293](../../rtl/core/mmu_top.v#L292-L293)

```verilog
assign req_ready_o = state_idle;
assign busy_o      = !state_idle || walker_busy || cmd_busy_o;
```

`req_ready_o` only reflects the top-level translation state machine.

`busy_o` also includes walker activity and command-controller activity.

---

## Register and function-code decoder instances

The register block instance owns the software-visible MMU register image.

Source: [rtl/core/mmu_top.v:L295-L311](../../rtl/core/mmu_top.v#L295-L311)

```verilog
mmu_regs #(
  .VA_WIDTH(VA_WIDTH),
  .PA_WIDTH(PA_WIDTH)
) u_regs (
  .clk    (clk),
  .rst_n  (rst_n),
  .wr_en  (reg_wr_en_i),
  .rd_en  (reg_rd_en_i),
```

The decoder instance classifies the lookup function code.

Source: [rtl/core/mmu_top.v:L314-L320](../../rtl/core/mmu_top.v#L314-L320)

```verilog
mmu_decode u_decode (
  .fc        (lookup_fc),
  .is_user   (decode_is_user),
  .is_super  (decode_is_super),
  .is_program(decode_is_program),
  .is_data   (decode_is_data),
  .cpu_space (decode_cpu_space)
```

The decode result feeds transparent translation matching and permission checks.

---

## Permission extraction helpers

The module converts packed TLB/walker attribute bits into user and supervisor permission vectors.

Source: [rtl/core/mmu_top.v:L198-L214](../../rtl/core/mmu_top.v#L198-L214)

```verilog
function automatic [2:0] user_perm_from_attr(
  input [ATTR_WIDTH-1:0] attr_i
);
  begin
    user_perm_from_attr[2] = ~attr_i[4] | (attr_i[2] & ~attr_i[2]);
    user_perm_from_attr[1] = (~attr_i[4] & ~attr_i[3]) | (attr_i[1] & ~attr_i[1]);
    user_perm_from_attr[0] = ~attr_i[4] | (attr_i[0] & ~attr_i[0]);
  end
endfunction

function automatic [2:0] super_perm_from_attr(
```

The expressions with `x & ~x` are always zero logically, but they keep otherwise-unused attribute bits visible to lint without changing behavior.

The resulting permission vectors are assigned later.

Source: [rtl/core/mmu_top.v:L465-L468](../../rtl/core/mmu_top.v#L465-L468)

```verilog
assign hit_user_perm  = user_perm_from_attr(tlb_lookup_attr);
assign hit_super_perm = super_perm_from_attr(tlb_lookup_attr);
assign walk_user_perm = user_perm_from_attr(walker_attr);
assign walk_super_perm = super_perm_from_attr(walker_attr);
```

---

## Address resize helper

Transparent translation returns an identity-style physical address by resizing the virtual address.

Source: [rtl/core/mmu_top.v:L218-L230](../../rtl/core/mmu_top.v#L218-L230)

```verilog
function automatic [PA_WIDTH-1:0] va_to_pa(
  input [VA_WIDTH-1:0] va_i
);
  integer idx;
  begin
    va_to_pa = {PA_WIDTH{1'b0}};
    for (idx = 0; idx < PA_WIDTH; idx = idx + 1) begin
      if (idx < VA_WIDTH) begin
        va_to_pa[idx] = va_i[idx];
      end
```

If PA is wider than VA, high PA bits remain zero. If PA is narrower than VA, only low PA-width bits are kept.

---

## Transparent-translation matching

The `ttr_match` function implements the first-pass TT/TTR subset over the 32-bit `tt0` and `tt1` register images.

Source: [rtl/core/mmu_top.v:L245-L267](../../rtl/core/mmu_top.v#L245-L267)

```verilog
function automatic ttr_match(
  input [31:0]         ttr_i,
  input [VA_WIDTH-1:0] va_i,
  input                is_user_i,
  input                is_program_i,
  input                is_data_i,
  input                is_cpu_space_i
);
  reg [TTR_KEY_WIDTH-1:0] va_key_v;
  reg [TTR_KEY_WIDTH-1:0] base_key_v;
  reg [TTR_KEY_WIDTH-1:0] mask_key_v;
```

The key comparison happens in the body of the function.

Source: [rtl/core/mmu_top.v:L259-L266](../../rtl/core/mmu_top.v#L259-L266)

```verilog
va_key_v        = va_i[VA_WIDTH-1 -: TTR_KEY_WIDTH];
base_key_v      = ttr_i[31 -: TTR_KEY_WIDTH];
mask_key_v      = ttr_i[23 -: TTR_KEY_WIDTH];
priv_match_v    = (is_user_i && ttr_i[13]) || (!is_user_i && ttr_i[14]);
space_match_v   = (is_program_i && ttr_i[12]) || (is_data_i && ttr_i[11]);
compare_match_v = ((va_key_v & ~mask_key_v) == (base_key_v & ~mask_key_v));
ttr_match = ttr_i[15] && !is_cpu_space_i && priv_match_v &&
            space_match_v && compare_match_v;
```

A TT hit requires enable, non-CPU-space, privilege match, program/data match, and masked high-address match.

---

## TT result wiring

The TT match wires are gated by lookup validity and normal memory-space decode.

Source: [rtl/core/mmu_top.v:L323-L336](../../rtl/core/mmu_top.v#L323-L336)

```verilog
assign decode_is_normal_mem = decode_is_program | decode_is_data;
assign tt0_match = lookup_valid &&
                   decode_is_normal_mem &&
                   ttr_match(tt0_q, lookup_va, decode_is_user,
                             decode_is_program, decode_is_data,
                             decode_cpu_space);
assign tt1_match = lookup_valid &&
                   decode_is_normal_mem &&
                   ttr_match(tt1_q, lookup_va, decode_is_user,
```

The combined TT result and bypass PA are then computed.

Source: [rtl/core/mmu_top.v:L334-L336](../../rtl/core/mmu_top.v#L334-L336)

```verilog
assign tt_match_any  = tt0_match | tt1_match;
assign tt_lookup_pa  = va_to_pa(lookup_va);
assign tt_cpu_bypass = lookup_src_cpu && tt_match_any;
```

Transparent translation bypasses descriptor translation and permission checking for CPU requests in this first-pass implementation.

---

## Probe status generation

The generate block adapts probe status width and marks TT matches in the top status bit.

Source: [rtl/core/mmu_top.v:L272-L290](../../rtl/core/mmu_top.v#L272-L290)

```verilog
generate
  if (VPN_WIDTH <= 32) begin : gen_table_entries_narrow
    assign table_entries_cfg = tc_q[VPN_WIDTH-1:0];
  end else begin : gen_table_entries_wide
    assign table_entries_cfg = {{(VPN_WIDTH-32){1'b0}}, tc_q};
  end

  if (STATUS_WIDTH >= ATTR_WIDTH) begin : gen_probe_status_wide
    assign probe_status_bits = tt_match_any
                             ? ({STATUS_WIDTH{1'b0}} |
```

The same block also sizes `table_entries_cfg` from the `tc` register image.

---

## Permission check instances

There are two permission checkers: one for TLB hits and one for walker results.

Source: [rtl/core/mmu_top.v:L338-L359](../../rtl/core/mmu_top.v#L338-L359)

```verilog
perm_check u_hit_perm (
  .req_r    (lookup_src_cpu && !req_fetch_i && req_rw_i),
  .req_w    (lookup_src_cpu && !req_fetch_i && !req_rw_i),
  .req_x    (lookup_src_cpu && req_fetch_i),
  .is_user  (decode_is_user),
  .u_perm   (hit_user_perm),
  .s_perm   (hit_super_perm),
  .tt_bypass(tt_cpu_bypass),
  .allow    (hit_perm_allow),
  .fault    (hit_perm_fault)
);

perm_check u_walk_perm (
```

The hit checker can receive `tt_cpu_bypass`. The walker-result checker uses `tt_bypass = 0` because TT hits should have bypassed the walker already.

---

## TLB, walker, and command-control instances

The direct-mapped TLB receives the selected lookup source, walker refill results, and flush invalidation signals.

Source: [rtl/core/mmu_top.v:L362-L388](../../rtl/core/mmu_top.v#L362-L388)

```verilog
tlb_dm #(
  .VA_WIDTH   (VA_WIDTH),
  .PA_WIDTH   (PA_WIDTH),
  .PAGE_SHIFT (PAGE_SHIFT),
  .ENTRIES    (TLB_ENTRIES),
  .FC_WIDTH   (FC_WIDTH),
  .ATTR_WIDTH (ATTR_WIDTH)
) u_tlb (
  .clk               (clk),
  .rst_n             (rst_n),
  .lookup_valid_i    (lookup_valid),
```

The walker starts when the top-level state enters `ST_START_WALK`.

Source: [rtl/core/mmu_top.v:L390-L421](../../rtl/core/mmu_top.v#L390-L421)

```verilog
pt_walker #(
  .VA_WIDTH    (VA_WIDTH),
  .PA_WIDTH    (PA_WIDTH),
  .PAGE_SHIFT  (PAGE_SHIFT),
  .DESCR_WIDTH (DESCR_WIDTH),
  .FC_WIDTH    (FC_WIDTH),
  .ATTR_WIDTH  (ATTR_WIDTH)
) u_walker (
  .clk             (clk),
```

`flush_ctrl` turns external control commands into TLB invalidation, probe, preload, and status activity.

Source: [rtl/core/mmu_top.v:L423-L463](../../rtl/core/mmu_top.v#L423-L463)

```verilog
flush_ctrl #(
  .VA_WIDTH      (VA_WIDTH),
  .PA_WIDTH      (PA_WIDTH),
  .FC_WIDTH      (FC_WIDTH),
  .STATUS_WIDTH  (STATUS_WIDTH),
  .CMD_WIDTH     (CMD_WIDTH),
```

These three instances form the core miss, refill, flush, probe, and preload path.

---

## Reset and per-cycle defaults

The main top-level state machine is clocked.

Source: [rtl/core/mmu_top.v:L475-L497](../../rtl/core/mmu_top.v#L475-L497)

```verilog
always @(posedge clk) begin
  if (!rst_n) begin
    state_q             <= ST_IDLE;
    pending_is_cpu_q    <= 1'b0;
    pending_va_q        <= {VA_WIDTH{1'b0}};
    pending_fc_q        <= {FC_WIDTH{1'b0}};
    pending_rw_q        <= 1'b0;
    pending_fetch_q     <= 1'b0;
```

In the non-reset path, response outputs are cleared by default.

Source: [rtl/core/mmu_top.v:L493-L497](../../rtl/core/mmu_top.v#L493-L497)

```verilog
resp_valid_o      <= 1'b0;
resp_hit_o        <= 1'b0;
resp_fault_o      <= 1'b0;
resp_fault_code_o <= RESP_FAULT_NONE;
resp_perm_fault_o <= 5'b0;
```

This makes response signals pulse-like unless the state machine assigns them high later in the same cycle.

---

## Probe bookkeeping

Probe requests from `flush_ctrl` are turned into one-cycle pending lookups.

Source: [rtl/core/mmu_top.v:L499-L506](../../rtl/core/mmu_top.v#L499-L506)

```verilog
if (probe_pending_q) begin
  probe_pending_q <= 1'b0;
end

if (probe_req_valid) begin
  probe_pending_q <= 1'b1;
  probe_addr_q    <= probe_req_addr;
  probe_fc_q      <= probe_req_fc;
```

The pending probe becomes a lookup source, and its TLB/TT result is fed back to `flush_ctrl` through the probe response ports.

---

## CPU request path in idle state

When idle and a CPU request is present, the top-level path checks TT first, then TLB hit, then TLB miss.

Source: [rtl/core/mmu_top.v:L510-L531](../../rtl/core/mmu_top.v#L510-L531)

```verilog
ST_IDLE: begin
  if (lookup_src_cpu) begin
    if (tt_match_any) begin
      resp_valid_o <= 1'b1;
      resp_pa_o    <= tt_lookup_pa;
    end else if (tlb_lookup_hit) begin
      resp_valid_o <= 1'b1;
      resp_pa_o    <= tlb_lookup_pa;
      resp_hit_o   <= 1'b1;
      if (!hit_perm_allow) begin
```

A TT match returns an identity-style PA immediately.

A TLB hit returns the TLB PA and marks `resp_hit_o`. If permissions fail, it also marks a permission fault.

A TLB miss saves the CPU request and moves to `ST_START_WALK`.

---

## Preload path in idle state

Preload requests use the same lookup path but do not produce a CPU response.

Source: [rtl/core/mmu_top.v:L532-L539](../../rtl/core/mmu_top.v#L532-L539)

```verilog
end else if (lookup_src_preload) begin
  if (tlb_lookup_miss) begin
    pending_is_cpu_q <= 1'b0;
    pending_va_q     <= preload_req_addr;
    pending_fc_q     <= preload_req_fc;
    pending_rw_q     <= 1'b1;
    pending_fetch_q  <= 1'b0;
    state_q          <= ST_START_WALK;
```

If the preload lookup misses, the walker is launched so the TLB can be refilled. Because `pending_is_cpu_q` is zero, walker completion does not emit a CPU translation response.

---

## Walker start and completion

The walker starts for one cycle through `ST_START_WALK`, then the top-level state machine waits in `ST_WAIT_WALK`.

Source: [rtl/core/mmu_top.v:L544-L550](../../rtl/core/mmu_top.v#L544-L550)

```verilog
ST_START_WALK: begin
  state_q <= ST_WAIT_WALK;
end

ST_WAIT_WALK: begin
  if (walker_done) begin
    state_q <= ST_IDLE;
```

On walker completion for a CPU request, the module emits a response using the walker PA base plus the saved page offset.

Source: [rtl/core/mmu_top.v:L551-L566](../../rtl/core/mmu_top.v#L551-L566)

```verilog
if (pending_is_cpu_q) begin
  resp_valid_o <= 1'b1;
  resp_pa_o    <= walker_pa_base |
                  {{(PA_WIDTH-PAGE_SHIFT){1'b0}}, pending_va_q[PAGE_SHIFT-1:0]};
  if (walker_fault_valid) begin
    resp_fault_o <= 1'b1;
    case (walker_fault_code)
      WALK_FAULT_INVALID:  resp_fault_code_o <= RESP_FAULT_INVALID;
      WALK_FAULT_UNMAPPED: resp_fault_code_o <= RESP_FAULT_UNMAPPED;
      WALK_FAULT_BUS:      resp_fault_code_o <= RESP_FAULT_BUS;
```

If the walker reports a fault, the local walker fault code is translated into the public response fault code. If there is no walker fault but permissions fail, the response becomes a permission fault.

---

## Important syntax notes

`function automatic` helpers keep repeated combinational calculations local to the module.

The indexed part-select `va_i[VA_WIDTH-1 -: TTR_KEY_WIDTH]` selects the high address key used for transparent translation matching.

The ternary operator is used heavily in the lookup-source mux so only one source drives `lookup_va` and `lookup_fc`.

The generate block selects width-safe implementations for table-entry sizing and probe status packing.

The top-level `always @(posedge clk)` block uses nonblocking assignments to update state and registered responses.

---

## Main gotchas

The first gotcha is that this wrapper supports a single outstanding CPU translation request. A miss is saved in pending registers while the walker runs.

The second gotcha is that TT/TTR matching happens before the TLB and walker for CPU requests. A TT match returns an identity-style PA and bypasses permission checking in this first-pass implementation.

The third gotcha is that probe and preload are folded into the same lookup fabric. CPU requests have priority, then pending probes, then preload lookups.

The fourth gotcha is that preloads can trigger walker-backed refill but do not create normal CPU responses.

The fifth gotcha is that the status and MMUSR-related behavior is intentionally first-pass. This wrapper should not be described as a complete Motorola PTEST/MMUSR model.

Finally, most real work is delegated: `mmu_regs` stores register images, `mmu_decode` classifies function codes, `tlb_dm` stores translations, `pt_walker` reads descriptors, `perm_check` checks access rights, and `flush_ctrl` handles control commands.