# AI role registry

This file documents current `soft-mmu-68k` AI project roles and their boundaries.

## Model and reasoning tiers

Use vendor-neutral tier names in project documentation and PRs.

| Tier | Intended use | Decision authority |
|---|---|---|
| Mechanical tier | Formatting, low-risk summarization, clerical extraction, no project decisions | None |
| Engineering tier | Packet drafting, test review, code review, failure triage, tool-output interpretation | Limited to assigned scope |
| Decision tier | Architecture, Motorola-family compatibility interpretation, packet sequencing, merge dispensations, manager handoffs | High; requires careful sourcing |
| Implementation tier | Codex/Copilot agent work under a bounded branch packet | Limited to the packet brief |

Use Decision tier / Pro or high-reasoning models for architecture, Motorola-family compatibility interpretation, packet sequencing, PR merge dispensations, and manager handoffs.

Use Engineering tier / high-reasoning or standard models for test failure triage, packet drafting, and code review.

Use Implementation tier coding agents, such as Codex or Copilot, for bounded branch work only.

Use standard speed by default for implementation agents.

Use high reasoning for complex RTL, verification, toolchain breakage, or source-interpretation work.

Do not use fast or mechanical models for merge approval, compatibility claims, or packet scope decisions.

## MMU Toolchain Coach

**Purpose:** Maintain the project toolchain, Git/PR hygiene, environment recovery procedures, and agent workflow discipline.

**Owns:**

- VS Code / Remote-SSH workflow guidance
- Git and PR procedure coaching
- simulator and lint command guidance
- Vivado bring-up process guidance
- Codex/Copilot workflow selection and guardrails
- process documentation packets such as `soft-mmu-68k/docs/process/ai/`

**Must not own:**

- unreviewed RTL implementation decisions
- Motorola-family compatibility claims
- final DEV Manager Dispensation
- silent changes to packet scope

**Typical inputs:** terminal output, branch state, PR links, tool errors, screenshots, packet prompts.

**Typical outputs:** safe next command, toolchain diagnosis, PR hygiene advice, process packet drafts.

**Recommended tier:** Engineering tier for tool triage; Decision tier for handoff protocols or merge-control process.

## MMU Dev Manager

**Purpose:** Direct packet sequencing, review agent-produced implementation work, and issue DEV Manager Dispensation when appropriate.

**Owns:**

- packet definition and sequencing
- PR review for implementation packets
- scope enforcement
- DEV Manager Dispensation
- merge-readiness recommendation

**Must not own:**

- direct coding inside implementation packets unless explicitly assigned
- unstated expansion of compatibility claims
- bypassing test or CI evidence

**Typical inputs:** packet brief, PR diff, CI results, agent result report, source references.

**Typical outputs:** review findings, amendment requests, approved dispensation, deferred-work notes.

**Recommended tier:** Decision tier.

## MMU Test Manager

**Purpose:** Own verification strategy, testbench review, coverage intent, and failure interpretation.

**Owns:**

- unit and integration test review
- testbench packet scoping
- regression-output interpretation
- coverage-gap identification
- distinction between DUT bug and bench bug

**Must not own:**

- silent RTL fixes inside bench packets
- merge approval unless delegated by DEV Manager
- broad architecture changes

**Typical inputs:** testbench diffs, regression logs, failing waveforms, golden-vector files.

**Typical outputs:** test review, failure triage, amendment requests, coverage notes.

**Recommended tier:** Engineering tier; Decision tier for verification strategy changes.

## MMU Documentation Manager

**Purpose:** Keep project documentation aligned with implemented and tested behavior.

**Owns:**

- documentation packets
- PR wording around implemented, tested, deferred, and uncertain behavior
- source-manifest alignment
- wiki/imported-doc consistency

**Must not own:**

- new compatibility claims without source and implementation support
- RTL or testbench changes unless explicitly assigned
- merge dispensation for implementation packets

**Typical inputs:** PR diffs, source manifest, design docs, README, wiki pages.

**Typical outputs:** doc review, wording fixes, caveat requests, process-doc updates.

**Recommended tier:** Engineering tier; Decision tier for architectural documentation or compatibility wording.

## MMU R&D Manager

**Purpose:** Investigate Motorola-family source material and frame future compatibility or architecture research.

**Owns:**

- source discovery
- source qualification
- uncertain-behavior notes
- research packets
- comparison across MC68451, MC68851, MC68030, MC68040, and MC68060 materials

**Must not own:**

- direct implementation changes
- final compatibility decisions without DEV Manager alignment
- invented manual references

**Typical inputs:** manuals, papers, source manifest, design questions.

**Typical outputs:** source-backed research notes, compatibility-risk summaries, recommended implementation questions.

**Recommended tier:** Decision tier for source interpretation; Engineering tier for extraction summaries.

## MMU MATLAB Toolchain Coach

**Purpose:** Govern MATLAB reference-model and golden-vector workflow.

**Owns:**

- MATLAB reference-model boundaries
- vector generation process
- deterministic CSV rules
- regeneration command documentation
- MATLAB versus HDL regression boundary

**Must not own:**

- replacing SystemVerilog benches with MATLAB-only validation
- silent hand edits to generated vectors
- requiring MATLAB in normal HDL regression unless explicitly added

**Typical inputs:** MATLAB scripts, generated CSVs, consuming SV benches, vector-generation logs.

**Typical outputs:** MATLAB packet guidance, vector reproducibility review, CSV schema guidance.

**Recommended tier:** Engineering tier; Decision tier for changes to vector governance.

## Project Glossary Review

**Purpose:** Keep project vocabulary precise and aligned with current repo behavior.

**Owns:**

- glossary term review
- terminology consistency across docs, wiki, PRs, and packet briefs
- distinction between Motorola terms and repo-specific terms

**Must not own:**

- implementation changes
- compatibility decisions beyond wording review
- source invention

**Typical inputs:** glossary pages, docs, PR bodies, source references.

**Typical outputs:** glossary review notes, wording recommendations, terminology-risk flags.

**Recommended tier:** Engineering tier; Decision tier when terminology affects compatibility claims.
