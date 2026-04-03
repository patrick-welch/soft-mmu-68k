# Address Map & Function Codes (FC)

**What this defines**
- VA spaces and `FC[2:0]` decode for user/supervisor and program/data access.
- The implemented first-pass transparent-translation subset.
- The current translated-vs-transparent split visible in probes and on the
  Basys 3 smoke demo.

**Chosen first-pass FC semantics**
- `3'b001` = user data
- `3'b010` = user program
- `3'b101` = supervisor data
- `3'b110` = supervisor program
- `3'b111` = CPU/special space
- `3'b000` and `3'b100` are treated as reserved encodings in this first pass

This matches the visible Motorola function-code classes used by the current
decode and permission logic.[^PRM-FC][^68030-UM-FC]

**Permission model implemented now**
- Requests are one-hot across read, write, and execute/fetch.
- `u_perm = {UX, UW, UR}` and `s_perm = {SX, SW, SR}` remain the checker inputs.
- A user denial is marked `privilege_related` only when the supervisor bank
  would allow that same access class.
- Malformed request encodings are reported as `bad_req`; they are not silently
  converted into read, write, or execute faults.
- `tt_bypass` suppresses page-derived permission denial only for an otherwise
  valid request.

**CPU/special space treatment**
- CPU/special space is decoded only for `FC=3'b111`.
- CPU/special space is not treated as normal program or data space by the FC
  decode.
- First-pass TT/TTR qualification explicitly excludes CPU/special space.
- CPU-space requests therefore continue down the normal translated or probe path
  in the current subset; TT bypass is never asserted for `FC=3'b111`.

**Transparent-translation behavior implemented now**
- `mmu_top` performs TT qualification ahead of TLB lookup and page-walk use.
- Implemented `TT0/TT1` image subset:
  `TTx[31:24]` = logical-address high-byte base.
  `TTx[23:16]` = logical-address high-byte mask, where `1` means "don't care"
  for that high-byte bit.
  `TTx[15]` = enable.
  `TTx[14]` = match supervisor normal-memory accesses.
  `TTx[13]` = match user normal-memory accesses.
  `TTx[12]` = match program space.
  `TTx[11]` = match data space.
- A transparent match requires:
  the entry enabled;
  a normal user/supervisor program/data FC;
  a privilege match against `TTx[14:13]`;
  a program/data class match against `TTx[12:11]`;
  a masked high-byte compare to succeed.
- Reserved FC encodings and CPU/special space do not transparent-match.
- On a transparent match, page-table translation is bypassed and the physical
  address is the logical address resized onto the PA bus.
- Under the current first-pass policy, a transparent match also bypasses
  page-derived permission denial for a valid request.
- `resp_hit_o` remains reserved for translated/TLB-backed hits. A successful TT
  bypass therefore returns `resp_valid_o=1`, `resp_fault_o=0`, identity-style
  `resp_pa_o`, and `resp_hit_o=0`.

**Probe and control-path meaning in the current subset**
- `flush_ctrl` is a first-pass control shim, not a full Motorola instruction
  model.
- For `CMD_PROBE`, `status_hit_o` means "a usable first-pass result exists."
- Probe result classes:
  translated result:
  `status_hit_o = 1`, `status_bits_o[6] = 1`, `status_bits_o[7] = 0`, and
  `status_pa_o` is the translated physical address.
  transparent result:
  `status_hit_o = 1`, `status_bits_o[7] = 1`, `status_bits_o[6] = 0`, and
  `status_pa_o` mirrors the probed logical address resized to PA width.
  miss:
  `status_hit_o = 0`; the class bits are not forced by this shim.
- `CMD_FLUSH_ALL`, `CMD_FLUSH_MATCH`, and `CMD_PRELOAD` keep the current
  zero-status completion model.

**Observed Basys 3 smoke-demo behavior**
- With all switches low, the board shows the translated user-data smoke case:
  translated access succeeds and the translated probe-status class bit is set.
- With `SW15=1`, the board shows the TT-qualified identity-style case:
  no fault, probe/status hit asserted, translated-status class clear, TT-status
  class set.
- With `SW8=1` and user mode selected, the board exercises the supervisor-only
  translated page and shows a permission fault.
- With `SW12=1` and `SW8=1`, the same translated page succeeds as a supervisor
  access.

Those board observations are smoke-level confirmation of the current
translated-vs-transparent split; they are not proof of full Motorola PMMU
behavior.

**What is still intentionally deferred**
- Full Motorola TT register decoding beyond the narrow `TTx[31:24]`,
  `TTx[23:16]`, and `TTx[15:11]` subset above.
- Full Motorola legality rules for transparent translation.
- Architecturally complete `MMUSR` synthesis for `PTEST` outcomes.
- Precise modeling of all Motorola-visible `PTEST`, `PLOAD`, and `PFLUSH`
  completion and termination cases.
- Any claim that CPU-space accesses are fully filtered or faulted exactly as a
  complete Motorola PMMU would require.

**Known issues / bring-up notes**
- The current TT implementation should be described as a first-pass subset only.
- The current `MMUSR` and `PTEST` behavior should be described as first-pass
  status shims, not full Motorola compatibility.
- The Basys 3 demo is a hardware smoke harness with a tiny built-in descriptor
  responder. It is not a full system and does not execute a 68k core.
- Software-side expectations in `sw/tests_68k/` intentionally model the current
  subset: TT matches return identity-style PA results and translated invalidation
  does not erase transparent qualification.

*Manual refs used:* [^PRM-FC] [^68030-UM-FC] [^68030-UM-TT] [^68851-UM-TT]

[^PRM-FC]: Motorola M68000 Family Programmer's Reference Manual, function-code definitions and CPU-space usage.
[^68030-UM-FC]: Motorola MC68030 User's Manual, Section 9 "Memory Management Unit", including FC-qualified accesses and PMMU-visible address spaces.
[^68030-UM-TT]: Motorola MC68030 User's Manual, transparent translation register behavior and matching rules.
[^68851-UM-TT]: Motorola MC68851 PMMU User's Manual, transparent translation register behavior and PMMU address-space treatment.
