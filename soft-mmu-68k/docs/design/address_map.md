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
- In `mmu_top`, first-pass TT/TTR qualification explicitly excludes CPU/special space even if the TT region byte matches.
- CPU/special-space accesses therefore continue down the normal translated path in this packet; no TT bypass is asserted for `FC=3'b111`.

**Transparent-translation behavior in this packet**
- `mmu_top` now performs a narrow first-pass TT/TTR qualification before normal TLB lookup / page-walk handling and only then asserts `tt_bypass`.[^68851-UM-TT][^68030-UM-TT]
- Implemented `TT0/TT1` image subset in this packet:
  `TTx[31:24]` = logical-address high-byte base.
  `TTx[23:16]` = logical-address high-byte mask, where `1` means "don't care" for the corresponding high-byte bit.
  `TTx[15]` = entry enable.
  `TTx[14]` = match supervisor normal-memory accesses.
  `TTx[13]` = match user normal-memory accesses.
  `TTx[12]` = match program space.
  `TTx[11]` = match data space.
- A transparent match requires:
  the entry enabled;
  a normal memory-space FC (`user/supervisor` × `program/data`);
  a privilege match against `TTx[14:13]`;
  a program/data class match against `TTx[12:11]`;
  the masked high-byte compare to succeed.
- CPU/special space and reserved FC encodings do not transparent-match in this first pass.
- On a transparent match, `mmu_top` bypasses page-table translation entirely and returns an identity-style physical address by resizing the logical address onto the PA bus.
- Under this first-pass policy, transparent matches also bypass page-derived permission checking for an otherwise valid request. `perm_check` still rejects malformed request encodings; `tt_bypass` is not a universal escape hatch.
- `resp_hit_o` remains reserved for translated/TLB-backed hits, so a successful transparent bypass returns `resp_valid_o=1`, `resp_fault_o=0`, identity-style `resp_pa_o`, and `resp_hit_o=0`.

**Software-side validation expectations for this subset**
- The freestanding 68k software scaffold should treat a TT match as a successful identity-style PA result, not as a translated-page hit.
- A TT non-match should continue to expect whatever translated PA or translated miss the harness programmed for that VA/FC pair.
- CPU/special space (`FC=3'b111`) must keep using the translated/probe path even when the logical-address high byte would otherwise match `TT0` or `TT1`.
- Under the current first-pass policy, software permission vectors may expect TT-qualified normal-memory accesses to bypass page-derived user/supervisor denial for valid requests, but should still expect malformed request encodings to fail.
- Targeted or whole-TLB flush structure may invalidate translated entries, but software should not claim that these shims implement full Motorola PFLUSH/PTEST/MMUSR semantics beyond the translated-vs-transparent distinction documented here.

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
- Full Motorola TT register decoding beyond the narrow `TTx[31:24]`, `TTx[23:16]`, and `TTx[15:11]` subset above.
- Architecturally complete MMUSR bit synthesis for PTEST outcomes.
- Distinguishing every Motorola-visible PTEST termination case beyond the first-pass translated-vs-transparent classification above.
- CPU-space legality filtering beyond the explicit "never TT-bypass `FC=3'b111`" rule used here, plus any other Motorola TT/TTR enable/exclude rules not represented by the subset above.

**Known simplifications / TODOs**
- The page-attribute path feeding permissions still carries a compact `{S, WP, CI, M, U}` subset, so any finer Motorola execute-vs-read policy beyond the explicit permission-bank inputs remains future work.
- A later TT packet should implement the remaining Motorola TT register fields and should only assert `tt_bypass` for fully Motorola-legal transparent-memory cases.
- Reserved FC encodings are only identified indirectly today by deasserting program/data/cpu-space. If the top-level interface later needs an explicit FC-valid flag, add it there rather than overloading the existing outputs.

*Manual refs used:* [^PRM-FC] [^68030-UM-FC] [^68030-UM-TT] [^68851-UM-TT]

[^PRM-FC]: Motorola M68000 Family Programmer's Reference Manual, function-code definitions and CPU-space usage.
[^68030-UM-FC]: Motorola MC68030 User's Manual, Section 9 "Memory Management Unit", including FC-qualified accesses and PMMU-visible address spaces.
[^68030-UM-TT]: Motorola MC68030 User's Manual, transparent translation register behavior and matching rules.
[^68851-UM-TT]: Motorola MC68851 PMMU User's Manual, transparent translation register behavior and PMMU address-space treatment.
