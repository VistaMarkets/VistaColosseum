# House rules — baton-runner br-2026-10-05-copy-story (finding-fixer houseRules input)

Project invariants (CONTEXT.md, docs/specs/00-baton-queue.md "Common rules", ARCH.md):
- Original, lightweight implementations. Do not copy or transplant source from the FMA or VMBE reference repos.
- No new pub dependencies. app/pubspec.yaml and app/pubspec.lock must not change (the gate's pubspec-frozen check enforces it).
- Money is int minor units (cents) or fixed-decimal strings. Never introduce new double money. A double at a pure display edge that already exists is a carried-forward finding, not a fix target.
- Every success message describes something that actually happened in state. A toast that claims a fill, reset, or save that did not mutate the store is a defect.
- Anything not built keeps the existing "— not in the demo yet" toast (the `_notBuilt` helper). Do not fake it.
- Spec 09 BUILDS the VC-DEM-004 persona switch (O-06 decided P0 on Oct 4). Scenario-phase advance stays excluded (O-10, P1): do not add it, do not describe it as built.
- app/lib/design_system/ is the single source of colour, type, spacing, radius and size tokens. Do not hardcode colours or font sizes in feature code.
- All mutable demo state lives in Scenario (app/lib/scenario/scenario.dart); screens read through it, never from a mock file's mutable list. Reset goes through resetDemo().
- Each spec's "Out of scope" section is binding; a fix that builds out-of-scope behavior is scope creep even if a reviewer asked for it.

Decided by the manager during this run (do not re-open):
- Spec 01 AC1 "one position from Scenario" is a single-source criterion, not new position UI on Home, detail or Arena.
- Spec 02 AC1 exact cash figure goes where the Wallet headline already is; no second figure.
- Overflow safety for order notional lives in Scenario (maxNotionalCents + margin check), not in ticket widgets.
- Spec 03: the simulation indicator keeps its reserved bottom strip; sheets that collided with it were made scroll-controlled rather than shrinking the indicator.
- origin/feat/premium-feel is parked; do not reconcile against it.
- Spec 09 fixture constants are decided: kCopyFeeCents = 500 flat per confirmed copy; copier seed cash 100000 cents; copy entries carry sourceCallId and sourceAuthorHandle on OrderIntent; the fee ledger stays the creator's.
- Known defect carried, not this unit's: the Wallet market-cap toggle shows the seeded $44.0M market after creating a new market at $10,000 (seen in the Oct 5 recording).

Runner rules finding-fixer's writer cannot know:
- A fix for a finding about TEST STRENGTH is not done until it is mutation-proven: show the mutation the old test survived and the new one catches. A test that passes with the thing it names deleted is worse than no test.
- The verification command is `scripts/gate.sh <log-dir>` run from the worktree root. It exits 0 and prints `GATE: PASS` on success; exit 1 / `GATE: FAIL` is the only failure. There is no profile variable in this repo. Run flutter commands from app/.
- Write only inside the worktree /home/alex/VistaColosseum/.worktrees/br-2026-10-05-copy-story. No git mutations, no push, no gh.
- Spec 09 has exactly one fee ledger, the creator persona's ("the ledger belongs to the creator"). A confirmed copy of ANY other author's call credits that ledger with one copyFee row; per-author ledgers do not exist and are out of scope. The creator copying someone else's call pays the fee but no row is written (she would credit herself).
