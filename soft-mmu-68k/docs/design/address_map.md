# Address Map & Function Codes (FC)

**What this defines**
- VA spaces & FC[2:0] → User/Supervisor × Program/Data
- Transparent translation regions (TTR) vs translated regions
- Device vs cacheable attributes (if modeled)

**Chosen first-pass FC semantics**
- `3'b001` = user data
- `3'b010` = user program
- `3'b101` = supervisor data
- `3'b110` = supervisor program
- `3'b111` = CPU/special space
- `3'b000` and `3'b100` are treated as reserved/illegal encodings in this packet

This matches the Motorola-visible function-code classes used by the PMMU-facing cores rather than the previous bit-sliced shorthand. The decode block therefore only asserts `is_program` or `is_data` for the four normal memory-space codes, and only asserts `cpu_space` for `3'b111`.[^PRM-FC][^68030-UM-FC]

**Permission model used by this packet**
- Requests are one-hot across read, write, and execute/fetch.
- `u_perm = {UX, UW, UR}` and `s_perm = {SX, SW, SR}` remain the checker inputs.
- A user denial is marked `privilege_related` only when the corresponding supervisor permission bit would allow that same access class.
- Illegal request encodings are reported as `bad_req` only and are not converted into read/write/execute faults.
- `tt_bypass` suppresses permission denial only for a valid single request. It does not bless malformed request encodings.

This keeps the fault output stable and reviewable: malformed requests are easy to spot, write faults stay distinct from read and execute denials, and supervisor-only mappings show up as a user denial plus `privilege_related`.

**CPU/special space treatment**
- CPU/special space is not treated as program or data space in the FC decode.
- This packet does not yet implement a full Motorola CPU-space access path; the decode simply identifies that class so higher layers can keep it separate from normal translated memory traffic.

**Transparent-translation behavior in this packet**
- TT behavior is intentionally narrow in this first pass: `perm_check` treats `tt_bypass` as an already-qualified "permission checks are skipped for this valid memory request" signal.
- It is not a universal escape hatch for malformed requests.
- The current packet does not yet model full Motorola TT matching, enable bits, masks, or explicit CPU-space exclusions at the top level. That qualification still belongs in the eventual TT decode/match stage before asserting `tt_bypass`.[^68030-UM-TT][^68851-UM-TT]

**P6b control/status meaning for TT/TTR-aware probe results**
- `flush_ctrl` remains a control-layer shim, not a full MMUSR/PTEST implementation.
- For `CMD_PROBE`, `status_hit_o` now means "the probe found a usable first-pass result," which can be either:
  translated hit:
  `status_hit_o = 1`, `status_bits_o[6] = 1`, `status_bits_o[7] = 0`, and `status_pa_o` is the translated physical address returned by the lower layer.
  transparent match / transparent bypass:
  `status_hit_o = 1`, `status_bits_o[7] = 1`, `status_bits_o[6] = 0`, and `status_pa_o` mirrors the probed logical address resized onto the PA bus because no page-table translation was consumed in this first-pass model.
- A normal probe miss remains `status_hit_o = 0`; P6b does not force either class bit for misses.
- The low payload bits below the top two class bits remain backend-defined. Today that means translated-probe attribute payloads can still pass through unchanged in the lower bits, while a future TT-aware responder can mark transparent bypass with bit `[7]`.
- `CMD_FLUSH_ALL`, `CMD_FLUSH_MATCH`, and `CMD_PRELOAD` keep their existing zero-status completion model in P6b.

**What is still intentionally deferred**
- Real TT register decode and mask matching in `mmu_top` or another top-level matcher.
- Architecturally complete MMUSR bit synthesis for PTEST outcomes.
- Distinguishing every Motorola-visible PTEST termination case beyond the first-pass translated-vs-transparent classification above.
- CPU-space legality filtering and other TT/TTR enable/exclude rules that belong in the future top-level TT match stage rather than this command/status shim.

**Known simplifications / TODOs**
- The page-attribute path feeding permissions still carries a compact `{S, WP, CI, M, U}` subset, so any finer Motorola execute-vs-read policy beyond the explicit permission-bank inputs remains future work.
- A later TT packet should implement actual TT register matching and should only assert `tt_bypass` for Motorola-legal transparent-memory cases.
- Reserved FC encodings are only identified indirectly today by deasserting program/data/cpu-space. If the top-level interface later needs an explicit FC-valid flag, add it there rather than overloading the existing outputs.

*Manual refs used:* [^PRM-FC] [^68030-UM-FC] [^68030-UM-TT] [^68851-UM-TT]

[^PRM-FC]: Motorola M68000 Family Programmer's Reference Manual, function-code definitions and CPU-space usage.
[^68030-UM-FC]: Motorola MC68030 User's Manual, Section 9 "Memory Management Unit", including FC-qualified accesses and PMMU-visible address spaces.
[^68030-UM-TT]: Motorola MC68030 User's Manual, transparent translation register behavior and matching rules.
[^68851-UM-TT]: Motorola MC68851 PMMU User's Manual, transparent translation register behavior and PMMU address-space treatment.
