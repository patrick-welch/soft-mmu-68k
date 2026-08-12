# MTC1 Human-Guided MATLAB Workflow

This directory preserves the historical human-guided MATLAB exercise used while implementing and verifying **MTC1 — MATLAB TC/CRP Single-Level Span Reference Model**.

The authoritative merged implementation is under [`soft-mmu-68k/scripts/matlab/`](../../../../../scripts/matlab/), and MTC1 was merged through [PR #40](https://github.com/patrick-welch/soft-mmu-68k/pull/40). The durable MTC1 packet definition is [`docs/process/packets/MTC1-matlab-tc-crp-span-reference.md`](../../../packets/MTC1-matlab-tc-crp-span-reference.md).

These files are preserved as historical process/learning collateral. They do not override merged MATLAB source, tests, packet decisions, reviewed PR/CI evidence, or current project documentation. Interactive language such as requests to send output back to the MATLAB Toolchain Coach, then-current branch names, intermediate PASS/PENDING states, and staging instructions is retained intentionally as part of the historical guided exercise.

## Behavioral boundary

The MTC1 exercise models the current TC1B-tested single-level TC/CRP span boundary. It uses the current project behavior in which the table span comes from the low `VPN_WIDTH` TC bits, CRP supplies the root/table base, and SRP is inert for this model. It is not a complete implementation or claim of Motorola MC68851 TC address geometry.

The merged MTC1 implementation documentation remains authoritative for current model details and deferred behavior.

The preserved workflow/checkpoint set contains **30 documents**: Steps 1-28 plus the Step 21A and Step 28A review/corrective checkpoints.

## Reading order

1. [`01-environment-and-function-shell.md`](01-environment-and-function-shell.md)
2. [`02-defaults-and-option-overrides.md`](02-defaults-and-option-overrides.md)
3. [`03-option-validation-and-result-structure.md`](03-option-validation-and-result-structure.md)
4. [`04-uint64-range-guards.md`](04-uint64-range-guards.md)
5. [`05-virtual-address-vpn-and-page-offset.md`](05-virtual-address-vpn-and-page-offset.md)
6. [`06-fc-crp-srp-and-tc-validation.md`](06-fc-crp-srp-and-tc-validation.md)
7. [`07-table-span-and-range-decision.md`](07-table-span-and-range-decision.md)
8. [`08-control-results-and-prewalk-fault.md`](08-control-results-and-prewalk-fault.md)
9. [`09-descriptor-address-and-overflow.md`](09-descriptor-address-and-overflow.md)
10. [`10-canonical-result-schema.md`](10-canonical-result-schema.md)
11. [`11-generator-shell-and-path.md`](11-generator-shell-and-path.md)
12. [`12-first-in-range-case.md`](12-first-in-range-case.md)
13. [`13-last-in-range-case.md`](13-last-in-range-case.md)
14. [`14-first-out-of-range-case.md`](14-first-out-of-range-case.md)
15. [`15-alternate-crp-pair.md`](15-alternate-crp-pair.md)
16. [`16-tc-span-change-pair.md`](16-tc-span-change-pair.md)
17. [`17-srp-inert-supervisor-case.md`](17-srp-inert-supervisor-case.md)
18. [`18-page-offset-invariance-pair.md`](18-page-offset-invariance-pair.md)
19. [`19-zero-table-span.md`](19-zero-table-span.md)
20. [`20-tc-upper-bits-inert.md`](20-tc-upper-bits-inert.md)
21. [`21-source-review-preparation.md`](21-source-review-preparation.md)
22. [`21a-source-review-and-cleanup.md`](21a-source-review-and-cleanup.md) — source-review checkpoint produced from the Step 21 review handoff.
23. [`22-matlab-readme-documentation.md`](22-matlab-readme-documentation.md)
24. [`23-location-aware-demo-shell.md`](23-location-aware-demo-shell.md)
25. [`24-core-demo-assertions.md`](24-core-demo-assertions.md)
26. [`25-paired-demo-assertions.md`](25-paired-demo-assertions.md)
27. [`26-environment-and-pre-staging-capture.md`](26-environment-and-pre-staging-capture.md)
28. [`27-final-source-review-and-staging-prep.md`](27-final-source-review-and-staging-prep.md)
29. [`28-scoped-staging-and-whitespace-gates.md`](28-scoped-staging-and-whitespace-gates.md)
30. [`28a-scoped-staging-retry.md`](28a-scoped-staging-retry.md) - corrective checkpoint after the initial scoped staging attempt left the index empty.

## Related decision-support briefing

The pre-Step-10 scalar-model review is preserved separately as [`BRIEF-2026-004-mtc1-scalar-model-pre-step-10-review.md`](../../../memoranda/briefings/BRIEF-2026-004-mtc1-scalar-model-pre-step-10-review.md). It is preserved decision input, not the final MTC1 approval; the merged implementation and PR #40 review evidence remain authoritative.
