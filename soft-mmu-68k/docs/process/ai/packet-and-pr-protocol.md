# Packet and PR protocol

This protocol defines the expected lifecycle for packetized AI-assisted work in `soft-mmu-68k`.

## Lifecycle

1. Packet brief
2. Implementation agent work
3. Agent self-report
4. DEV Manager review
5. Amend or approve
6. DEV Manager Dispensation
7. Merge
8. Update durable project state if needed

## 1. Packet brief

A packet brief defines a bounded unit of work before an implementation agent starts.

````markdown
# Packet: <packet id> - <short title>

## Role

You are the implementation agent for this packet.

## Branch

Create or use branch: `<branch-name>`

## Goal

<one paragraph describing the intended change>

## Allowed files

- `<path>`

## Do not edit

- `<path>`

## Requirements

- <requirement>

## Verification

Run:

```bash
<exact command>
```

If a command is skipped, report why.

## Commit

Commit message:

```text
<message>
```

## Final response required

Return:

1. Branch
2. Commit hash
3. Files changed
4. Tests run
5. Tests not run
6. Known limitations
7. Follow-up needed
````

## 2. Implementation agent work

Implementation agents must stay inside the packet. They may not expand file scope, change workflows, or repair unrelated issues unless the packet explicitly authorizes that work.

If blocked, the agent must stop and report rather than thrash.

## 3. Agent self-report

````markdown
# Agent result report

## Branch

`<branch>`

## Commit

`<commit>`

## Files changed

- `<path>` - <summary>

## Files intentionally not touched

- `<path>`

## Summary

<what changed>

## Verification performed

```bash
<command>
```

Result: `<pass/fail/skipped>`

## Tests not run

- `<test>` - <reason>

## Known limitations

- <limitation>

## Follow-up needed

- <follow-up>
````

## 4. DEV Manager review

The DEV Manager reviews the PR against the packet brief, repository state, CI, and relevant source material.

```markdown
# DEV Manager PR Review

PR: #<number>
Branch: `<branch>`
Reviewed HEAD: `<sha>`
Base: `<base branch or sha>`

## Scope review

- Allowed files changed: <yes/no>
- Forbidden files changed: <yes/no>
- Packet scope preserved: <yes/no>

## Behavior review

<summary of behavior or documentation reviewed>

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

## 5. Amendment request

Use an amendment request when the PR is close but not ready.

````markdown
# Amendment request

PR: #<number>
Reviewed HEAD: `<sha>`

## Required changes

1. <change>
2. <change>

## Files allowed for amendment

- `<path>`

## Files still forbidden

- `<path>`

## Verification required after amendment

```bash
<command>
```

## Notes

Any additional push, amend, or force-push invalidates the previous review state and requires re-review.
````

## 6. DEV Manager Dispensation

DEV Manager Dispensation is a commit-specific merge authorization. It is not a general approval of a branch name or topic.

```markdown
# DEV Manager Dispensation

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

## 7. Merge

Before merge, confirm:

- PR head still matches reviewed HEAD
- required checks still pass or are intentionally skipped
- no new commits appeared after dispensation
- PR body accurately describes tests and skipped tests

## 8. Update durable project state

If the packet changes project process, architecture, compatibility status, test scope, MATLAB vector policy, or board bring-up status, update durable documentation in the same PR or a follow-up documentation packet.

Chat summaries are not durable project state unless copied into repository documentation or PR history.
