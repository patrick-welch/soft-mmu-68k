# Wiki Source Pages

This directory is the repo-controlled source for selected GitHub Wiki pages.

The GitHub Wiki itself is a separate Git repository, so normal branches and pull
requests in the main repo do not directly version Wiki edits. To keep Wiki pages
reviewable, maintain Markdown source here first, review it through normal repo
branches/PRs, then publish it to the Wiki with the manual workflow in
`.github/workflows/publish-wiki.yml`.

## Policy

- Treat this directory as the source of truth for pages mirrored into the Wiki.
- Do not paste ChatGPT/OpenAI citation artifacts into these files.
- Do not include assistant-only citation marker strings in public documentation.
- Keep implementation claims tied to repo files, verified manual references, or
  explicit project-status notes.
- Do not claim full Motorola PMMU compatibility unless the behavior is actually
  implemented and verified.

## Publishing

Publishing is manual-only. Use the GitHub Actions workflow:

`Publish Wiki`

The workflow copies Markdown files from this directory into the repository Wiki.
It is intentionally not triggered automatically on every push.
