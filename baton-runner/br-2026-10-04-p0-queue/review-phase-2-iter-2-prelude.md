# Project prelude: phase 2 review, iteration 2 (VistaColosseum, Flutter app in app/)

## Where things are (use absolute paths; read-only)
- Worktree root: /home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue (branch feat/br-2026-10-04-p0-queue/phase-2, HEAD 02c61e6396f8d07e7a7115b4db47e092d27384d4). Do NOT read the other checkout your shell may start in; run git as `git -C /home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue ...`.
- Whole phase diff: `git -C <root> diff feat/br-2026-10-04-p0-queue/phase-1...HEAD -- app/`
- What the iteration-1 fix changed: `git -C <root> diff a7aee5a..HEAD -- app/` (commit b4a7db7)
- Spec (the intent; read Rules, Behavior, Acceptance, Out of scope in full): <root>/docs/specs/02-truthful-order-confirm.md
- Phase-1 digest (conventions this phase must honour): <root>/baton-runner/br-2026-10-04-p0-queue/digest-phase-1.md
- Work baton (what the author claimed): <root>/baton-pass/br-2026-10-04-p0-queue/2026-10-04T120621-phase2-truthful-order-confirm.md
- Iteration-1 synthesized review report (findings H1, M1-M8, L1-L18): <root>/baton-runner/br-2026-10-04-p0-queue/review-phase-2-iter-1.md
- Iteration-1 fix baton (each finding marked FIXED / REFUTED / DEFERRED with reasons and RED evidence): <root>/baton-pass/br-2026-10-04-p0-queue/2026-10-04T125834-phase2-fix-iter1.md
- Later specs (to judge "deferred to spec 03/04" claims): <root>/docs/specs/03-simulation-indicator.md ... 08-list-empty-failed-states.md

## Run-wide rules from the user (every finding should be judged against these)
1. No new pub dependencies: app/pubspec.yaml and app/pubspec.lock unchanged.
2. Money in int minor units (cents), never double. Flag any double used for stored or computed money.
3. Every success message describes something that actually happened in state.
4. VC-DEM-004 persona switch and phase advance are deliberately excluded and must NOT have been built.

## Facts already established by the caller (do not re-derive; do verify if you doubt them)
- Gate (`scripts/gate.sh`): flutter analyze clean, flutter test +201 all passed, pubspec frozen; `flutter test --dart-define=HAS_MARKET=true` also +201 all passed.
- H1 re-check by hand: a review-only probe drove every Home trader-market card (7 handles, Market and Limit), Home card -> Details -> trader market page (Market, Limit, Stop), and Arena -> caller maya.eth -> Profile -> Market page (Market, Limit), plus direct `Scenario.placeOrder` on every trader handle x every OrderKind. All refused with "Trader-index ticket — not in the demo yet" and left the store deep-equal. Log: <root>/baton-runner/br-2026-10-04-p0-queue/gate-phase-2-iter-2/h1-probe/h1-probe.log.

## What this iteration must decide
1. For every iteration-1 finding (H1, M1-M8, L1-L18): is it genuinely resolved, still standing, soundly deferred, or soundly refuted? Do NOT re-raise an item the fix baton refuted or deferred with a sound reason. If you judge a refutation or deferral UNSOUND (e.g. the item is in this spec's scope and the reason does not hold), raise it as a standing finding and say why the reason fails.
2. Did the fix commit (b4a7db7) introduce anything new? Focus: `Scenario.problem` (new order of checks, `tradable`, leverage/finite/dust guards), both tickets' `_traderIndex` / `_problem` / `_place` / `_notBuilt`, and `_ReviewPanel` Retry re-quote (`requote`, `_intent` held in panel state, `_busy`).
3. Are the tests real: would each fail if the implementation it pins were reverted or mutated?
4. M4 / AC1: the fix baton defers "which Wallet figure AC1 means" as an author question. Give your view on whether AC1's wording ("Wallet shows ... cash reduced by margin + fee; totals on review, receipt and Wallet agree to the cent"; named test is a store test in scenario_test.dart) is genuinely ambiguous or plainly requires a to-the-cent cash figure on the Wallet.

## Out of scope for this spec (do not raise as defects of this phase)
Trader-index tickets themselves (VC-MKT-005; only the refusal is in scope), advanced order types, Arena participation counting (spec 04 wires it), the simulation indicator (spec 03), fee ledger (spec 06), empty/failed list states (spec 08), VC-DEM-004.
