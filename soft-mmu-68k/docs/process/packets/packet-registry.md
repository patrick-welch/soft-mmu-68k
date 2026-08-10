# SM68861 Packet Registry

This registry is the compact durable index of authorized project packets.

It records status and relationships; it does not replace the packet definition, pull request, review record, CI evidence, or merged repository state.

| Packet | Title | Status | Depends on | Owner | Branch / PR | Decision source | Packet definition | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC1A | TC/CRP/SRP traversal plan | Merged | — | Historical owner not backfilled | `copilot/tc1a-tc-crp-srp-traversal-spec` / [PR #29](https://github.com/patrick-welch/soft-mmu-68k/pull/29) | Verified merged PR #29 | — (historical definition not backfilled) | Merge commit `b44107d5449c0f6a2a6bd02f881ddb99680b0559`. |
| TC1B | TC/CRP span tests | Merged | TC1A | Historical owner not backfilled | `copilot/tc1b-tc-crp-span-tests` / [PR #30](https://github.com/patrick-welch/soft-mmu-68k/pull/30) | Verified merged PR #30; TC1A identified TC1B as follow-up | — (historical definition not backfilled) | Merge commit `2acf6f045853e560382646a7fdb0e247c9850ad4`; PR base was the TC1A merge commit. |
| CTRL1 | Control operations behavior plan | Merged | — | Historical owner not backfilled | `copilot/ctrl1-control-operations-plan` / [PR #31](https://github.com/patrick-welch/soft-mmu-68k/pull/31) | Verified merged PR #31 | — (historical definition not backfilled) | Merge commit `e172216923b296149a1192763dab729f09bf65ca`. |
| CTRL1B | Control shim tests | Merged | CTRL1 | Historical owner not backfilled | `codex/ctrl1b-control-shim-tests` / [PR #33](https://github.com/patrick-welch/soft-mmu-68k/pull/33) | Verified merged PR #33; CTRL1 names CTRL1B as the executable-test follow-up | — (historical definition not backfilled) | Merge commit `6b7b0cc078c72bf8caa0cfae3aa0dee8a48648c2`. |
| HW1A | Hardware smoke repeatability plan | Merged | — | Historical owner not backfilled | `docs/hw1a-hardware-smoke-repeatability-plan` / [PR #37](https://github.com/patrick-welch/soft-mmu-68k/pull/37) | Verified merged PR #37 | — (historical definition not backfilled) | Merge commit `588110d9c056736e57aab9a2c1e30cef77ee8418`; no earlier dependency backfilled. |
| MTC1 | MATLAB TC/CRP single-level span reference model | Ready | TC1B (current-behavior boundary) | Project Lead + MMU MATLAB Toolchain Coach | `matlab/mtc1-tc-crp-span-reference` approved; branch/PR not yet present | [MEMO-2026-001](../memoranda/MEMO-2026-001-mtc1-scope-and-sequencing.md) | [MTC1 definition](MTC1-matlab-tc-crp-span-reference.md) | GitHub search found no MTC1 branch or PR at PROC1B execution time; implementation status therefore remains `Ready`. |
| PROC1A | Durable Packet, Memorandum, and Briefing Framework | Merged | — | MMU Documentation Manager | `docs/proc1a-process-record-framework` / [PR #38](https://github.com/patrick-welch/soft-mmu-68k/pull/38) | Project Lead authorization in approved PROC1A packet; verified merged PR #38 | [PROC1A definition](PROC1A-durable-process-record-framework.md) | Merge commit `756ba791b3747965c04805db2e9d8eb82ba2bb5b`. |
| PROC1B | Verified Packet and Briefing Record Bootstrap | Review | PROC1A | MMU Documentation Manager | `docs/proc1b-verified-record-bootstrap` / PR pending | Project Lead release of approved PROC1B packet after source gate resolution | [PROC1B definition](PROC1B-verified-packet-and-briefing-record-bootstrap.md) | Bounded bootstrap only; row remains `Review` before merge. |

## Registry scope

This PROC1B bootstrap is intentionally bounded to the eight packet identities above. Historical owners and dependencies are left explicit when they were not durably verified; no additional packet history is reconstructed from memory.
