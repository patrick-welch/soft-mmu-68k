# SM68861 Packet Registry

This registry is the compact durable index of authorized project packets.

It records status and relationships; it does not replace the packet definition, pull request, review record, CI evidence, or merged repository state.

| Packet | Title | Status | Depends on | Owner | Branch / PR | Decision source | Packet definition | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| PROC1A | Durable Packet, Memorandum, and Briefing Framework | Active | None | MMU Documentation Manager | `docs/proc1a-process-record-framework` / PR pending | Project Lead authorization in approved PROC1A packet | [PROC1A definition](PROC1A-durable-process-record-framework.md) | Framework packet. Historical/current packet bootstrap is intentionally deferred to PROC1B. |

## Registry status

This registry is intentionally incomplete during `PROC1A`.

Do not backfill historical or parallel packet history from memory. `PROC1B — Verified Packet and Briefing Record Bootstrap` is the intended evidence-backed follow-up for approved historical/current packet and briefing records.

Do not mark `PROC1A` as `Merged` until the merge has actually occurred. A later smallest-authorized process update may record the post-merge status.
