# Project instructions

## Architecture map

Read [`ARCH.md`](./ARCH.md) before exploring the repository or reviewing its architecture. Use its Overview, Key Paths, and File Tree to find relevant code, then verify behavior against the source files. The map is a navigation aid, not evidence that a feature is implemented.

When the architecture changes, update the curated Overview and Key Paths in `ARCH.md`. Do not edit the region between the `ARCH:TREE` markers by hand. Refresh it with `python3 .githooks/gen_arch.py`; the `.githooks/pre-commit` hook also refreshes and stages it on commit. Review `git status` before regeneration because the generator includes untracked, unignored files.

After cloning, enable the hook with `git config core.hooksPath .githooks`.
