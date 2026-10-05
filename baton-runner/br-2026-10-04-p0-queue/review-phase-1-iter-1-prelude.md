# Review context: phase 1 (docs/specs/01-scenario-store.md)

Repo root (a git worktree): /home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue. The Flutter app lives in app/. Resolve every path against that root, not your own cwd.

Phase diff: `git -C /home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue diff main...HEAD -- app/` (base main, head feat/br-2026-10-04-p0-queue/phase-1). Read-only git only.

Judge findings against the intent in /home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/docs/specs/01-scenario-store.md. Read it in full, especially "## Rules for this unit", "## Behavior", "## Acceptance" and "## Out of scope".

Run-wide rules the change must satisfy:
- No new pub dependencies: app/pubspec.yaml and app/pubspec.lock unchanged.
- Money in int minor units (cents), never double. Flag any new double used for money.
- Every success message (toast, snackbar) describes something that actually happened in state.
- VC-DEM-004 persona switch and scenario phase advance are deliberately excluded and must not have been built. Persistence across restarts is out of scope.

Known deferral, not this unit's defect: `OrderTicket.available = 1000` (double, app/lib/features/trade/order_ticket.dart:72) is owned by docs/specs/02-truthful-order-confirm.md's Gap line ("money is double (available = 1000)"; spec 02 adds margin <= cash).

Gate status: `scripts/gate.sh` passed (flutter analyze clean, 176 tests pass, pubspec frozen).

Reviewers are READ-ONLY: no edits to product code or tests, no git mutations, no gh.
