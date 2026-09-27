# Project instructions

> Twin of [`AGENTS.md`](AGENTS.md). Keep the guidance in these files equivalent;
> this copy is loaded by Claude Code.

## Architecture map

Read [`ARCH.md`](./ARCH.md) before exploring the repository or reviewing its architecture. Use its Overview, Key Paths, and File Tree to find relevant code, then verify behavior against the source files. The map is a navigation aid, not evidence that a feature is implemented.

When the architecture changes, update the curated Overview and Key Paths in `ARCH.md`. Do not edit the region between the `ARCH:TREE` markers by hand. Refresh it with `python3 .githooks/gen_arch.py`; the `.githooks/pre-commit` hook also refreshes and stages it on commit. Review `git status` before regeneration because the generator includes untracked, unignored files.

After cloning, enable the hook with `git config core.hooksPath .githooks`.

## Demo priorities

Get a working demo ready as quickly as practical. Prioritize correct demo
behavior and small changes that are easy to review. Work must stay focused,
minimal, and limited to what the demo needs.

This is temporary demo code, not a production launch. Defer production
hardening, broad refactors, new abstractions, and unrelated cleanup unless
they are necessary for the agreed demo to work.

## Source material

Use `/home/alex/VistaMobileBE` for backend reference material and
`/home/alex/Flutter-mobile-app` for frontend reference material. Read the
relevant code and documentation before implementing a demo feature to understand
its core behavior, interfaces, and applicable safety checks.

Do not copy files or transplant implementations from those repositories. Write
original, lightweight versions focused on the core feature and functionality
needed for this demo. Omit unrelated features and production infrastructure
while preserving required safety checks. Treat the source repositories as
read-only references unless separately authorized to change them.

Report the source paths consulted and the deliberate demo simplifications.

## Non-negotiable rules

This guidance supplements all applicable repository and inherited instructions;
it does not override them. Existing safety gates, worktree and feature-branch
requirements, staging discipline, review rules, and scope-confirmation rules
remain in force. Demo speed never justifies weakening or bypassing them.

Never expose credentials or enable real trades or other irreversible financial
actions. Use mock or simulated outcomes for demo financial actions, preserving
existing safety gates.

## Working approach

- Start with one observable demo behavior and the smallest useful change.
- Name the intended files before editing; keep unrelated work separate.
- Run focused checks appropriate to the change and all required repository checks.
- Report files changed, checks performed and their results, and demo limitations.
- Before expanding scope, explain the demo blocker and the minimum additional
  work needed, and obtain an explicit decision. Preserve the existing
  scope-confirmation requirements.
- Keep future changes tied to the agreed demo behavior; record deferred work
  separately rather than adding it to the current change.

## Agent skills

### Issue tracker

Track VC work in GitHub Issues for `VistaMarkets/VistaColosseum`.
See `docs/agents/issue-tracker.md`.

### Triage labels

Use the five default Matt Pocock triage labels.
See `docs/agents/triage-labels.md`.

### Domain docs

Use the single-context layout: root `CONTEXT.md` and relevant `docs/adr/` records.
Read `docs/agents/domain.md` before exploring the domain.
