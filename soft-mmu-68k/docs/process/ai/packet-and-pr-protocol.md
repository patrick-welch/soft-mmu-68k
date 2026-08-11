# Packet and PR protocol

This protocol defines the expected lifecycle for packetized AI-assisted work in `soft-mmu-68k`.

For packets created after PROC2A, the **GitHub packet Issue is the live operational packet control record**. Historical committed packet files remain valid records; ordinary new packets do not require duplicate committed packet Markdown.

## Authority and evidence precedence

Use this order when records conflict:

```text
current merged repository state
>
reviewed PR / reviewed commit / CI evidence
>
current approved packet Issue body plus Dev Manager or Project Lead decision comments
>
committed packet definition, when one exists
>
approved management memorandum
>
preserved source briefing
>
chat recollection / generic model memory
```

A packet Issue controls authorized operational work. It does not override merged code, reviewed tests, or durable technical evidence.

## Roles

```text
Project Lead
    final project authority and merge authority

MMU Dev Manager
    engineering decision authority: packet existence, technical scope,
    sequencing, amendments, review, commit-specific Dispensation

MMU Packet Coordinator
    packet control authority: Issue normalization, approved status,
    links, administrative completeness, queues, closeout, contradiction detection

Implementation owner
    executes only the approved packet scope
```

The Packet Coordinator may not invent technical scope, approve its own decisions, resequence work, issue Dispensation, or approve merge.

## Packet Issue lifecycle

```text
1. Specialist, Project Lead, or manager proposes work.
2. Dev Manager or Project Lead explicitly approves scope and sequencing.
3. Packet Coordinator creates or normalizes the packet Issue.
4. Packet Coordinator applies status:ready.
5. Implementation owner creates the named branch and links the Issue.
6. Implementation owner opens a PR linked to the Issue.
7. Packet Coordinator checks administrative completeness.
8. Dev Manager performs technical review, amendment, or Dispensation.
9. Project Lead merges.
10. Packet Coordinator posts closeout, records PR and merge commit, and closes the Issue.
```

A proposed Issue may exist before approval, but implementation must not begin until the Dev Manager or Project Lead explicitly approves the scope and the operational status is `ready`.

## Minimal operational labels

Documented packet labels are limited to:

```text
packet
status:proposed
status:ready
status:active
status:review
status:blocked
status:deferred
```

Closed Issue dispositions are recorded in the closeout comment as `merged`, `cancelled`, or `superseded`.

Do not create a broad subsystem/priority/manager/compatibility taxonomy unless a later packet authorizes it.

## Issue body and decision-history rules

The Issue body is the current normalized approved scope.

- Approval must be recorded in an explicit MMU Dev Manager or Project Lead comment.
- A material amendment must be recorded in a new explicit decision comment.
- After approval/amendment, the Packet Coordinator may update the Issue body to the current approved scope.
- The Packet Coordinator must maintain a short Decision History section linking the decision comments.
- Editing the body must not erase earlier decision history.
- An implementation agent may not treat an unapproved body edit as authorization.
- If the Issue body and decision comments conflict, stop and escalate.

## Required packet Issue content

The packet Issue should record:

- packet ID and title;
- decision owner;
- execution owner;
- proposed/approved branch;
- dependencies;
- goal;
- approved scope;
- allowed and forbidden files;
- requirements;
- acceptance criteria;
- verification requirements;
- source/design/memorandum links;
- branch and PR links;
- Decision History;
- blockers/deferrals;
- closeout fields.

Use `.github/ISSUE_TEMPLATE/packet.md` for post-PROC2A packets.

## Implementation owner work

Before editing, the implementation owner must read the controlling Issue, verify explicit approval/readiness, confirm the branch, allowed files, forbidden files, and verification, and stop if the Issue conflicts with approval/amendment comments.

Implementation owners must stay inside the packet. They may not expand file scope, change workflows, or repair unrelated issues unless explicitly authorized.

If blocked, stop and report rather than thrash.

## Implementation self-report

Return at minimum:

```text
Packet Issue:
Packet ID:
Branch:
Commit:
Files changed:
Files intentionally not touched:
Summary:
Verification performed:
Tests not run and reasons:
Known limitations:
Follow-up needed:
```

The PR must link the controlling packet Issue.

## Packet Coordinator administrative check

Before technical review, the Packet Coordinator may check:

- Issue has explicit approval/amendment decision evidence;
- Issue body reflects the current approved scope;
- branch matches approved branch;
- PR links the Issue;
- changed-file set is administratively consistent with allowed scope;
- verification/results fields are present;
- status/PR links are current;
- obvious Issue/PR contradictions are escalated.

This is not technical PR approval and does not replace DEV Manager review.

## DEV Manager review

The DEV Manager reviews the PR against the controlling packet Issue, explicit decision comments, repository state, CI, and relevant source material.

```markdown
# DEV Manager PR Review

Packet Issue: #<number>
Packet: <id>
PR: #<number>
Branch: `<branch>`
Reviewed HEAD: `<sha>`
Base: `<base branch or sha>`

## Scope review

- Allowed files changed: <yes/no>
- Forbidden files changed: <yes/no>
- Approved scope preserved: <yes/no>

## Behavior / documentation review

<summary>

## Verification review

- CI result: <pass/fail/not run>
- Local commands reviewed: <commands>
- Tests skipped: <tests and reasons>

## Compatibility review

- Implemented behavior:
- Tested behavior:
- Deferred behavior:
- Uncertain interpretation:

## Findings

- <finding>

## Decision

<amend / approve / reject>
```

## Amendment request

A material amendment requires an explicit Dev Manager or Project Lead Issue decision comment. The Packet Coordinator may then normalize the Issue body and add the decision comment to Decision History.

Any additional push, amend, or force-push after reviewed HEAD requires re-review.

## DEV Manager Dispensation

DEV Manager Dispensation is a commit-specific merge authorization. It is not general approval of a branch name, Issue, or topic.

```markdown
# DEV Manager Dispensation

Packet Issue: #<number>
PR: #<number> - <title>
Branch: `<branch>`
Reviewed HEAD: `<sha>`
Base: `<base branch>` at `<base sha>`

## Scope reviewed

- <files and packet scope reviewed>

## Tests and CI reviewed

- <CI run or command>
- <result>

## Conditions

- <condition>

## Compatibility and deferred behavior

- Implemented behavior:
- Tested behavior:
- Deferred compatibility work:
- Uncertain interpretation:

## Approval decision

Approved for merge / Not approved for merge.

This dispensation applies only to reviewed commit `<sha>`.
Any further push, amend, or force-push invalidates this dispensation and requires re-review.
```

## Merge

Before merge, confirm:

- PR head still matches reviewed HEAD;
- required checks still pass or are intentionally skipped;
- no new commits appeared after Dispensation;
- PR body accurately describes tests and skipped tests;
- the controlling packet Issue is linked and current.

The Project Lead retains final merge authority where project process requires it.

## Packet closeout

After merge, the Packet Coordinator posts a concise closeout comment recording:

- disposition (`merged`, `cancelled`, or `superseded`);
- PR number;
- reviewed HEAD;
- merge commit when applicable;
- tests/checks disposition;
- material deferred follow-up, if any.

Then close the packet Issue when the approved lifecycle permits closure.

Do not require a Git commit merely to change operational packet status from Ready to Active, Review, or Merged.

## Durable process records

Committed packet definitions, memoranda, and briefings are no longer automatic for every packet.

- Create a committed packet/specification when stable complex scope or durable project knowledge justifies it.
- Create a memorandum only for consequential governance, verification-policy, waiver/risk, role, material sequencing, or comparable decisions.
- Preserve a full briefing only when it contains unique evidence/analysis, material alternatives/disagreement, a major handoff, or explicit Project Lead retention direction.

Do not reconstruct historical records from memory when reliable evidence is unavailable.

## Historical transition

The historical `docs/process/packets/packet-registry.md` is frozen by PROC2A. It remains a bootstrap record and is not the live packet-status source.

Do not create packet Issues retroactively for TC1A, TC1B, CTRL1, CTRL1B, HW1A, MTC1, PROC1A, PROC1B, or earlier P-series history unless a later packet explicitly authorizes a specific migration need.
