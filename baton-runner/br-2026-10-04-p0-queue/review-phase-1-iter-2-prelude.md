# Review context: phase 1, review iteration 2 (docs/specs/01-scenario-store.md)

Repo root (a git worktree): /home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue. The Flutter app lives in app/. Resolve every path against that root, not your own cwd.

Phase diff: `git -C /home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue diff main...HEAD -- app/` (base main, head feat/br-2026-10-04-p0-queue/phase-1 at f55c061). The iteration-1 fixes alone: `git -C <root> show 0bd9559 -- app/`. Read-only git only.

Judge findings against the intent in /home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/docs/specs/01-scenario-store.md. Read it in full, especially "## Rules for this unit", "## Behavior", "## Acceptance" and "## Out of scope".

## This is iteration 2. Read these first

- Iteration-1 synthesized report (C0/H3/M8/L13): /home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/baton-runner/br-2026-10-04-p0-queue/review-phase-1-iter-1.md
- Fix baton (what was fixed with RED evidence, what was deferred, what was refuted and why): /home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/baton-pass/br-2026-10-04-p0-queue/2026-10-04T105911-phase1-fix-iter1.md

Your job, in this order:
1. For every iteration-1 finding the fix baton marks **fixed**, check it is genuinely resolved in the code and that its new test would fail if the fix were reverted. If not, raise it again as a standing finding and say why.
2. Check whether the fixes introduced anything new (regressions, new second sources, dead code, new overclaiming toasts, test holes).
3. For items marked **refuted**, accept the refutation if its reason is sound. If you find a refutation unsound, raise it as a standing finding and say explicitly "refutation unsound: <why>".
4. For items marked **deferred**, do not re-raise them merely because they are still present. Re-raise one only if it is genuinely inside this spec's scope and blocks an acceptance criterion or a run-wide rule; otherwise list it as "carried forward" without a severity.

Three iteration-1 intent gaps to confirm closed: (a) AC1 listing has one source (Your market title, make-a-market prefill); (b) AC2 Wallet pager returns to "My portfolio" after a listed→unlisted reset; (c) the AC1 test's Arena step is now a real assertion.

## Run-wide rules the change must satisfy
- No new pub dependencies: app/pubspec.yaml and app/pubspec.lock unchanged.
- Money in int minor units (cents), never double. Flag any new double used for money.
- Every success message (toast, snackbar) describes something that actually happened in state.
- VC-DEM-004 persona switch and scenario phase advance are deliberately excluded and must not have been built. Persistence across restarts is out of scope.

Known deferral, not this unit's defect: `OrderTicket.available = 1000` (double, app/lib/features/trade/order_ticket.dart) is owned by docs/specs/02-truthful-order-confirm.md (spec 02 adds margin <= cash and one money-formatting helper).

## Gate status
`scripts/gate.sh baton-runner/br-2026-10-04-p0-queue/gate-phase-1-iter-2/` → GATE: PASS (flutter analyze clean, 180 tests pass, pubspec frozen). `flutter test --dart-define=HAS_MARKET=true` → 180 tests pass (log: baton-runner/br-2026-10-04-p0-queue/gate-phase-1-iter-2/extra-flutter-test-has-market-true.log).

Reviewers are READ-ONLY: no edits to product code or tests, no git mutations, no gh. Report every finding you have, at its honest severity; do not pre-filter.
