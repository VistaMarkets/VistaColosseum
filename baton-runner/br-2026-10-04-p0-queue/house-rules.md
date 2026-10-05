# House rules — baton-runner br-2026-10-04-p0-queue (finding-fixer houseRules input)

Project invariants (CONTEXT.md, docs/specs/00-baton-queue.md "Common rules", ARCH.md):
- Original, lightweight implementations. Do not copy or transplant source from the FMA or VMBE reference repos.
- No new pub dependencies. app/pubspec.yaml and app/pubspec.lock must not change (the gate's pubspec-frozen check enforces it).
- Money is int minor units (cents) or fixed-decimal strings. Never introduce new double money. A double at a pure display edge that already exists is a carried-forward finding, not a fix target.
- Every success message describes something that actually happened in state. A toast that claims a fill, reset, or save that did not mutate the store is a defect.
- Anything not built keeps the existing "— not in the demo yet" toast (the `_notBuilt` helper). Do not fake it.
- VC-DEM-004 persona switch and scenario-phase advance are deliberately excluded (gated on PRD O-06 / O-10). Do not add them, and do not describe them as built.
- app/lib/design_system/ is the single source of colour, type, spacing, radius and size tokens. Do not hardcode colours or font sizes in feature code.
- All mutable demo state lives in Scenario (app/lib/scenario/scenario.dart); screens read through it, never from a mock file's mutable list. Reset goes through resetDemo().
- Each spec's "Out of scope" section is binding; a fix that builds out-of-scope behavior is scope creep even if a reviewer asked for it.

Decided by the manager during this run (do not re-open):
- Spec 01 AC1 "one position from Scenario" is a single-source criterion, not new position UI on Home, detail or Arena.
- Spec 02 AC1 exact cash figure goes where the Wallet headline already is; no second figure.
- Overflow safety for order notional lives in Scenario (maxNotionalCents + margin check), not in ticket widgets.
- Spec 03: the simulation indicator keeps its reserved bottom strip; sheets that collided with it were made scroll-controlled rather than shrinking the indicator.
- origin/feat/premium-feel is parked; do not reconcile against it.

Runner rules finding-fixer's writer cannot know:
- A fix for a finding about TEST STRENGTH is not done until it is mutation-proven: show the mutation the old test survived and the new one catches. A test that passes with the thing it names deleted is worse than no test.
- The verification command is `scripts/gate.sh <log-dir>` run from the worktree root. It exits 0 and prints `GATE: PASS` on success; exit 1 / `GATE: FAIL` is the only failure. There is no profile variable in this repo. Run flutter commands from app/.
- Write only inside the worktree /home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue. No git mutations, no push, no gh.
