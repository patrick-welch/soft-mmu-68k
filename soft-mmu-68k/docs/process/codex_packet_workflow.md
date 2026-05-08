# Codex Packet Branch/PR Workflow

This is the working process for Codex-agent packets in `soft-mmu-68k`.
Keep packets small, branch-scoped, and reviewable.

## Roles

**MMU Coding Manager**
- Owns RTL implementation direction.
- Decides when a packet may change files under `rtl/`.
- Reviews architected behavior changes for manual alignment and design intent.

**MMU Test Manager**
- Owns verification direction, test coverage, and regression readiness.
- Decides when a test-only packet is required before RTL work starts.
- Reviews benches, vectors, and evidence quality.

**Codex Agent**
- Works only inside the packet scope assigned by the human/project manager.
- Creates one branch and one PR per packet.
- Runs the required review bundle before asking for acceptance.
- Reports failures honestly and leaves known TODOs in the PR description.

**Human Project Owner**
- Assigns packet scope and merge priority.
- Accepts risk, resolves scope disputes, and performs or approves merges.
- May override manager decisions when project schedule or architecture requires it.

## One Branch Per Packet

Each packet gets its own branch and PR.

```sh
git switch main
git pull --ff-only
git switch -c codex/<packet-id>-<short-topic>
```

Rules:
- One packet branch must contain only the files needed for that packet.
- Do not combine unrelated fixes, cleanup, or formatting.
- If the packet grows, stop and split it into a follow-up packet.
- If the assigned file list says "own only", do not edit outside that list.

## Branch Names

Use lowercase, slash-scoped names:

```text
codex/<packet-id>-<short-topic>
```

Examples:

```text
codex/w1-packet-workflow-doc
codex/t3-perm-check-vectors
codex/r7-tlb-invalid-hit-fix
```

Packet IDs should match the tracker or assignment label when one exists.

## What Codex Agents May Do

Codex agents may:
- Read any project file needed to understand the packet.
- Edit only files inside the assigned packet scope.
- Add focused tests when the packet scope includes testbench work.
- Add concise docs when the packet scope includes documentation.
- Run lint, unit benches, integration benches, and local git review commands.
- Create commits and PRs when explicitly asked to publish.

Codex agents must not:
- Edit RTL unless the packet explicitly allows RTL edits.
- Edit testbenches unless the packet explicitly allows TB edits.
- Edit scripts unless the packet explicitly allows script edits.
- Reformat unrelated files.
- Hide failing tests, remove assertions to make a run pass, or weaken checks without approval.
- Change branch history shared with humans unless explicitly asked.
- Merge their own PR unless the human project owner explicitly approves it.

## RTL Edit Gate

RTL edits are allowed only when the packet says RTL is in scope or the MMU Coding Manager approves it in the packet thread.

Any RTL behavior change must include:
- The exact RTL files changed.
- The architected behavior being changed.
- Relevant manual/design-doc references when behavior is visible to software.
- Test evidence that covers the changed behavior.

If an issue is found while working a non-RTL packet, document it as a TODO or follow-up packet. Do not opportunistically patch RTL.

## Test-Only Before RTL

Use a test-only packet before RTL changes when:
- The expected behavior is not already captured by a bench.
- The bug can be reproduced with a failing test.
- The behavior involves permissions, descriptor decode, TLB refill/invalidate, fault classes, or instruction-visible effects.
- The MMU Test Manager asks for proof before implementation.

The preferred sequence is:

```text
test-only packet: add failing coverage and expected behavior
RTL packet: implement fix until the new and existing tests pass
cleanup packet: refactor only if still useful after behavior is correct
```

## Required Review Bundle

Before requesting PR review, run the review bundle from the repo root.

For every packet:

```sh
git status --short
git diff --stat
git diff --check
```

For RTL or testbench packets:

```sh
scripts/run_verilator_lint.sh
scripts/run_iverilog_unit.sh
scripts/run_iverilog_integ.sh
```

For docs-only packets, `git diff --check` is the required local verification unless the reviewer asks for more.

If a command cannot be run because a tool is missing, record the command and the reason in the PR description.
If a command fails, do not request acceptance until the failure is fixed or explicitly accepted by the human project owner.

## Regression Script Use

Regression scripts are the acceptance gate for code packets.

- `scripts/run_verilator_lint.sh` checks RTL and bench lint coverage.
- `scripts/run_iverilog_unit.sh` runs unit benches.
- `scripts/run_iverilog_integ.sh` runs integration benches.

A PR that changes RTL or testbenches must include fresh results from all three scripts.
A docs-only PR does not need the HDL regressions unless the reviewer asks for them.

## PR Description

Every PR must include:

```md
## Summary
- What changed and why.

## Files Changed
- `path/to/file`: short purpose.

## Verification
- `command`: PASS/FAIL/SKIPPED with reason.

## Known TODOs
- Follow-up work, limitations, or `None`.
```

Keep the PR body factual. Include failures and skipped commands.

## Acceptance And Merge

A packet PR is acceptable when:
- The diff matches the assigned packet scope.
- No unrelated source, RTL, TB, script, or README files changed.
- Required review bundle commands are reported.
- RTL/testbench packets pass lint, unit, and integration scripts, or the human project owner accepts a documented exception.
- RTL behavior changes have matching test evidence.
- Required docs or manual references are present for architected behavior changes.
- Known TODOs are explicit and do not block the packet goal.
- The MMU Coding Manager, MMU Test Manager, or human project owner approves according to packet type.

Merge only after approval. Prefer squash merges for packet branches unless the human project owner requests a different merge style.
