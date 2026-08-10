# PROC1B — Verified Packet and Briefing Record Bootstrap

## Preservation and release status

- **Packet ID:** `PROC1B`
- **Title:** Verified Packet and Briefing Record Bootstrap
- **Packet owner / implementation role:** MMU Documentation Manager
- **DEV Manager role:** packet definition, sequencing, scope review, PR review, and commit-specific DEV Manager Dispensation
- **Decision owner:** Project Lead
- **Depends on:** `PROC1A — Durable Packet, Memorandum, and Briefing Framework`
- **Branch:** `docs/proc1b-verified-record-bootstrap`
- **Execution release:** Project Lead released PROC1B after PROC1A merged and after the previously missing Source A and Source B artifacts were supplied. The resume direction is `PROC1B_Resume_Direction_Source_Gate_Resolved.md`.
- **Dependency verification:** PR #38 / PROC1A merged to `main` at merge commit `756ba791b3747965c04805db2e9d8eb82ba2bb5b` before the PROC1B branch was created.
- **Source filenames normalized for execution:** `MTC1_DEV_Manager_Briefing.md`, `MTC1_DEV_Manager_Review_and_Decision.md`, `SM68861_Packet_Registry_and_Memoranda_Proposal.md`.

This repository record preserves the approved PROC1B scope and execution rules. It does not broaden the bounded bootstrap authorized by the Project Lead.

## Purpose

PROC1A created the durable packet/memorandum/briefing framework. PROC1B performs the first small evidence-backed bootstrap so current packet sequence and substantive decision inputs no longer depend on chat history.

PROC1B must:

1. preserve two substantive source briefings;
2. create two management memoranda;
3. create one authoritative MTC1 packet definition from Source A plus Source B amendments;
4. preserve this PROC1B packet definition;
5. update the packet registry only for the bounded eight-packet set.

PROC1B is not complete historical archaeology.

## Source authority

Required sources:

- **Source A:** `MTC1_DEV_Manager_Briefing.md` — original MMU MATLAB Toolchain Coach briefing to the MMU Dev Manager.
- **Source B:** `MTC1_DEV_Manager_Review_and_Decision.md` — DEV Manager amendment/decision record; controls wherever it amends Source A.
- **Source C:** `SM68861_Packet_Registry_and_Memoranda_Proposal.md` — MMU Documentation Manager process-record proposal.
- **Repository evidence:** merged PROC1A definition, merged PR #38, current packet/PR protocol, current role registry, and verified historical PRs.

Do not reconstruct missing wording from memory. If a required source becomes unavailable or materially contradictory outside an accepted DEV Manager resolution, stop the affected record.

## Allowed files

Only these seven files may change:

```text
soft-mmu-68k/docs/process/packets/packet-registry.md
soft-mmu-68k/docs/process/packets/MTC1-matlab-tc-crp-span-reference.md
soft-mmu-68k/docs/process/packets/PROC1B-verified-packet-and-briefing-record-bootstrap.md
soft-mmu-68k/docs/process/memoranda/MEMO-2026-001-mtc1-scope-and-sequencing.md
soft-mmu-68k/docs/process/memoranda/MEMO-2026-002-process-record-framework-adoption.md
soft-mmu-68k/docs/process/memoranda/briefings/BRIEF-2026-001-mtc1-matlab-toolchain-coach.md
soft-mmu-68k/docs/process/memoranda/briefings/BRIEF-2026-002-process-record-proposal.md
```

No other file is authorized.

## Forbidden areas

Do not edit `AGENTS.md`, `.github/`, RTL, testbenches, golden vectors, scripts, MATLAB, FPGA collateral, design docs, Wiki, tutorials, roadmap, refs, existing process framework README files, or `docs/process/ai/`.

PROC1B must not alter the framework rules established by PROC1A. Any framework defect requires a separate amendment packet.

## Briefing preservation

### BRIEF-2026-001

Create `BRIEF-2026-001-mtc1-matlab-toolchain-coach.md` with framework metadata and preserve Source A substantively. Do not silently fold Source B amendments into the original briefing. Metadata and repository links may be added; LF normalization is allowed.

### BRIEF-2026-002

Create `BRIEF-2026-002-process-record-proposal.md` with framework metadata and preserve Source C substantively. Later decisions, including substantive-briefing preservation and the PROC1A/PROC1B split, belong in MEMO-2026-002 rather than being retroactively inserted into the source proposal.

## MEMO-2026-001 — MTC1 scope and sequencing

Use Source A, Source B, Project Lead acceptance, and verified TC1A/TC1B evidence.

Record that:

- MTC1 models the current TC1B-tested single-level TC/CRP span boundary.
- MTC1 does not model full Motorola TC address geometry as current behavior.
- full TIA/TIB/TIC/TID and PS-driven geometry is deferred to a future MTC2 concept.
- no committed CSV belongs to MTC1.
- MTC1B remains an optional separate future promotion to HDL-consumed vectors.
- the approved MTC1 branch is `matlab/mtc1-tc-crp-span-reference`.
- conservative width limits apply.
- `descriptor_addr_valid` is required.
- descriptor-address overflow configurations are rejected rather than wrapped.
- nine mandatory directed cases are required.
- MTC1 may precede HW1B by Project Lead sequencing choice but is not an architectural dependency of the current Basys 3 smoke target.

Do not turn this memorandum into a Motorola technical specification.

## MEMO-2026-002 — process-record framework adoption

Use Source C, merged PROC1A, PR #38, and Project Lead direction.

Record the adopted distinctions:

```text
briefing record = preserved substantive decision input
memorandum      = project/process rationale
packet definition = authorized scope
PR/review/commit/CI = implementation and review evidence
docs/design/    = technical architecture and compatibility decisions
```

Record that the originally broader process effort was deliberately split before implementation into PROC1A (framework) and PROC1B (verified bootstrap/backfill), both owned by the MMU Documentation Manager with independent DEV Manager review/dispensation. PROC1B depends on PROC1A but may otherwise run in parallel with MTC1.

## Authoritative MTC1 packet definition

Create `MTC1-matlab-tc-crp-span-reference.md` as the consolidated authoritative packet definition. Source B controls where it amends Source A.

The durable definition must include at minimum:

- packet identity/title/owners;
- approved branch `matlab/mtc1-tc-crp-span-reference`;
- current TC1B single-level span boundary;
- four-file MATLAB scope;
- forbidden areas;
- configuration-width limits;
- `descriptor_addr_valid` requirement;
- descriptor-address overflow rejection;
- nine mandatory directed cases;
- reference-model API direction;
- deterministic in-memory generator;
- location-aware demo and assertions;
- no committed CSV;
- explicit deferred Motorola TC geometry;
- MATLAB verification requirements;
- HDL regression skip policy;
- commit/push/PR closeout;
- MTC1B/MTC2 follow-ons;
- HW1B sequencing relationship.

The packet definition records authorization; the registry carries current execution status.

## Bounded packet-registry bootstrap

Update `packet-registry.md` for exactly these identities:

```text
TC1A
TC1B
CTRL1
CTRL1B
HW1A
MTC1
PROC1A
PROC1B
```

No additional packet belongs in PROC1B.

Verify historical PR identities/states directly from GitHub. Expected PR mappings are:

```text
#29 TC1A  — TC/CRP/SRP traversal plan
#30 TC1B  — TC/CRP span tests
#31 CTRL1 — control operations behavior plan
#33 CTRL1B — control shim tests
#37 HW1A — hardware smoke repeatability plan
#38 PROC1A — durable process record framework
```

Do not use expected numbers as proof; actual GitHub results control.

Use `Merged` only when GitHub confirms merge. Unknown historical owner or dependency fields must remain explicit instead of guessed. Do not infer owner from branch prefixes.

Supported relationships may include TC1B→TC1A, CTRL1B→CTRL1, MTC1→TC1B current-behavior boundary, and PROC1B→PROC1A. Leave unsupported historical dependencies blank/explicit.

Do not create reconstructed packet-definition files for TC1A, TC1B, CTRL1, CTRL1B, or HW1A.

### MTC1 status

Use:

- `Ready` if approved but no durable implementation activity exists;
- `Active` only with durable implementation evidence;
- `Review` if an MTC1 PR is open;
- `Merged` only if the MTC1 PR is merged.

Do not infer `Active` from intent alone.

### PROC1B status

Use `Review` before PR review/merge. Do not mark PROC1B `Merged` before the merge actually occurs.

## Provenance discipline

Use actual source files, PRs, packet definitions, and repository evidence. Do not write “according to prior chat” when a durable source exists. Label conservative interpretations when needed. PROC1B introduces no new Motorola-family compatibility claims.

## Acceptance criteria

PROC1B is complete when:

- PROC1A was verified merged before branch creation;
- both source briefings are preserved from actual artifacts with provenance metadata;
- both memoranda accurately record the approved decisions;
- MTC1's durable definition consolidates Source A and Source B without adding requirements;
- this PROC1B definition preserves the released scope;
- registry rows are limited to the authorized eight identities;
- historical PR identities and merged states are GitHub-verified;
- unknown owner/dependency information is explicit rather than guessed;
- no historical packet definitions except MTC1 are reconstructed;
- no ordinary chat transcript is archived;
- only the seven authorized files change;
- `git diff --check` passes for the complete branch delta before DEV Manager Dispensation;
- work concludes with commit, push, and pull request.

## Verification

Required branch-delta checks:

```bash
git status --short --branch
git diff --stat
git diff --check
```

Before commit/staging in a shell-backed worktree:

```bash
git status --short --branch
git diff --cached --stat
git diff --cached --check
git diff --cached
```

If an implementation environment cannot run `git diff --check`, report it as **SKIPPED** with the reason and obtain an independent shell-backed PASS before DEV Manager Dispensation. The one-time PROC1A waiver does not carry forward.

## HDL / MATLAB / FPGA disposition

Do not run local HDL regression, MATLAB, Vivado, or hardware for PROC1B. Report:

```text
SKIPPED: documentation/process-record packet; no RTL, testbench, HDL-consumed vector, MATLAB, script, FPGA, or workflow changes.
```

If GitHub Actions runs automatically, report its result separately. Do not alter workflow triggers.

## Closeout

Recommended commit/PR title:

```text
PROC1B: bootstrap verified packet and briefing records
```

Required review sequence:

```text
Documentation Manager implementation/self-report
-> MMU Dev Manager review
-> DEV Manager Dispensation
-> Project Lead merge approval / merge
```

DEV Manager Dispensation is commit-specific. Any later push/amend/force-push after reviewed HEAD requires re-review.

Do not merge until source records, historical PR evidence, `git diff --check`, automatic CI state, DEV Manager Dispensation, unchanged reviewed HEAD, and Project Lead approval are all satisfied.

## Explicit non-goals

PROC1B does not change RTL, tests, MATLAB, FPGA collateral, GitHub Actions, PROC1A framework rules, technical compatibility claims, or execute MTC1/HW1B. It does not create a complete packet history, archive every chat message, or create MTC1B/MTC2.

## Stop conditions

Stop immediately if PROC1A/framework evidence is absent, required source material becomes unavailable, a briefing must be reconstructed from memory, Source A/B conflict beyond the accepted DEV Manager resolution, a historical PR identity/state mismatches, scope would exceed eight registry rows or seven files, historical ownership/dependencies would require guessing, MTC1 MATLAB files would need changes, or a technical architecture/compatibility decision would have to be invented.
