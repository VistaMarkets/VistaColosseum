# Multi-Agent Review: spec docs/specs/00-baton-queue.md (baton-runner queue index)

## Executive Summary
Five reviewers (architect, critical-thinking, silent-failure-hunter, security, penetration-tester) read the queue, the eight unit specs, the PRD/roadmap/drift report, the Flutter source and the installed `ClaudesMods:baton-runner` 1.74.0 skill. All agree the eight-unit order is sound and every cited code gap is real, but the queue cannot run as written: the runner's pre-flight requires a `scripts/gate.sh` that does not exist (and the shipped template is Python-only), the run worktree is cut from `origin/main` where none of these specs exist, and the "common rules" are never delivered to any work unit. The "Closes" column overclaims VC-DEM-004 (persona/phase controls built by nobody) and the premium-feel independence claim is contradicted by measured file overlap. Recommended action: block the run; land `scripts/gate.sh` + the specs on `main`, inline the rules into each unit, fix the Closes and Depends columns, then re-review. 4 HIGH after dedupe, under the budget of 8 — no demotions.

## Critical Findings

**1. The runner never executes the queue's gate; `scripts/gate.sh` is missing and the shipped template is Python-only**
- Location: `00-baton-queue.md:3` (gate line), `:18` (run command); skill `SKILL.md:75-80`, `REFERENCE.md:71-94`, `scripts/gate.sh:39-42`
- Description: Review units run `scripts/gate.sh <log-dir>`, never a prompt-supplied command; pre-flight halts if the script is absent from `origin/main` (listed as fatal). Reproduced: `ls scripts` → no such directory; `git ls-tree -r origin/main | grep gate` → nothing. The plugin template runs `uv run pytest/ruff/mypy`, so even copying it verbatim means no phase can reach CLEAN on a Flutter repo. The queue's `cd app && flutter analyze && flutter test` is prose with no execution path.
- Suggested fix: Commit a Flutter `scripts/gate.sh` (`cd app && flutter analyze && flutter test`, print `GATE: PASS|FAIL`, non-zero on failure; optionally the grep checks in Medium #10) to `main` before invoking, and point the queue's gate line at the script.
- Raised by: silent-failure-hunter (CRITICAL), architect-reviewer, security-reviewer, penetration-tester (HIGH) — higher severity kept.

## High Findings

**1. Specs are not on `origin/main`; the run worktree will not contain them**
- Location: `00-baton-queue.md:18`; `REFERENCE.md:11-17`
- Description: The runner does `worktree add … origin/main`. `git ls-tree -r origin/main -- docs/specs | wc -l` → 0; `origin/main == HEAD == c1a6b18`; the nine spec files are staged only on `claude/project-status-0b9273` (unpushed). Every path in the run command resolves to nothing inside the run worktree.
- Suggested fix: Add a precondition line: "Merge this branch (specs + `scripts/gate.sh`) to `main` before invoking."
- Raised by: architect-reviewer, silent-failure-hunter, security-reviewer, penetration-tester.

**2. "Common rules for every unit" reach no unit**
- Location: `00-baton-queue.md:16,18`; `SKILL.md:49-56,100-101`; `REFERENCE.md:136-152`
- Description: Each phase runs with fresh context — its own spec plus prior digests. `00-baton-queue.md` is not in the run command, so "no new pub deps", "int-cents money", "truthful success messages", "keep the not-built toast" are invisible to every work, review and fix unit. The gate (`flutter_lints` only) cannot catch violations either.
- Suggested fix: Copy the rules block into each unit spec's header (or into a repo `CLAUDE.md` the work-unit prompt already cites), and add `ClaudesMods:audit-numeric-types` + `git diff --exit-code origin/main -- app/pubspec.yaml app/pubspec.lock` to `gate.sh`.
- Raised by: silent-failure-hunter, security-reviewer, penetration-tester.

**3. "Closes VC-DEM-004" is false — persona and scenario-phase controls are in nobody's scope**
- Location: `00-baton-queue.md:7-8` ("half of" / "rest of VC-DEM-004"); PRD line 84; `01-scenario-store.md:23`
- Description: PRD requires presenter controls for "reset, persona and scenario phase" plus truthful notifications (P0; persona switch also named in PRD §1). Unit 01 ships reset only and scopes persona/phase out; unit 02 adds no control. The review unit verifies spec criteria, not PRD IDs, so both units go CLEAN while the P0 stays open and the next drift pass marks it Built.
- Suggested fix: Rewrite as "VC-DEM-004 (reset + truthful notifications only; persona/phase deferred)" and record the residual, or add a small persona-switch unit.
- Raised by: architect-reviewer, silent-failure-hunter, security-reviewer, penetration-tester.

**4. "Does not depend on the premium-feel branch" is contradicted by measured overlap**
- Location: `00-baton-queue.md:3`
- Description: `git diff --stat origin/main...origin/feat/premium-feel` on files units 02/03/04 edit: `order_ticket.dart` 252 lines, `feed_order_ticket.dart` 215, `arena_screen.dart` 186, `app_shell.dart` 117, `crowd_filter_panel.dart` deleted (76), `settings_screen.dart` 5 — 14 files, 609+/502-. Whichever lands second takes non-mechanical conflicts (fatal to the runner, `REFERENCE.md:316`); if premium-feel lands first, every line citation in units 02–04 is stale and unit 04's `crowd_filter_panel.dart:70` target no longer exists.
- Suggested fix: Record the merge-or-park decision (drift finding 1) as a precondition of unit 02 in the queue preamble; re-cite afterwards.
- Raised by: silent-failure-hunter, security-reviewer.

## Medium and Low Findings

| Severity | Title | Location | Reviewer(s) | One-line description |
|---|---|---|---|---|
| MEDIUM | Missing dependency edges 03→02, 06→02 (and 07→04) | `00-baton-queue.md:9,12,13`; `03:13`, `06:8`, `07:9` | architect, silent-failure-hunter, security, penetration-tester | Unit 03 verifies unit 02's sheet, unit 06 consumes unit 02's `Receipt`, unit 07 needs unit 04's `Battle.id/asset`; column lists only "1"/"6" — harmless sequentially, wrong for any re-order or wave-runner. Fix: 03→1,2; 06→1,2; 07→4,6. |
| MEDIUM | Unit 04 reopens unit 02's contract (`clashId`, `PortfolioPosition`) | `00-baton-queue.md:10`; `02:7-8,24`; `04:10-11`; `portfolio_mock.dart:14-27` | architect, silent-failure-hunter, penetration-tester, critical-thinking | 04 needs `clashId` on `OrderIntent`/position and participation keyed by `actionId`, which 02 scopes out; `PortfolioPosition` is `const` with string money fields and no id. Fix: 02 defines optional `clashId` + int-cent fields; 04 adds behavior only. |
| MEDIUM | Scenario state inventory split without an owner (`FeeEntry`, follows) | `01:7`; `06:6`; `08:6`; `follow_list_screen.dart:29,50` | architect, security, critical-thinking | 01 says `Scenario` owns fee-ledger entries and participation but the types live in 06/04; follows are not in 01's list yet 08 empties them. Fix: 01 lists exactly what it seeds; later units extend. |
| MEDIUM | Decision-free P0 work omitted without saying so | `00-baton-queue.md:1-3` | architect, security, critical-thinking | LST-002's 40% demo label (`make_market_flow.dart:627`), ARN-005 crowd-split labelling, FED-003 "Call details"×2 need no O-01/O-04/O-05 and are in no unit; 29 P0 IDs in drift vs 18 closed. Fix: add to units 6/4/7 or an explicit "Deliberately excluded" line. |
| MEDIUM | Unit 01 exceeds the runner's right-size budget | `00-baton-queue.md:7`; `SKILL.md:85-86`; `REFERENCE.md:125-127` | architect, silent-failure-hunter, penetration-tester, critical-thinking | 14–17 files touched vs ~10 limit; the runner will split or bail. Fix: pre-split into 01a (store + seed + reset + tests) and 01b (caller migration + Settings row). |
| MEDIUM | "Closes VC-ORD-003" with no rounding rule; money rule unenforceable | `00-baton-queue.md:8,16`; `02:12`; `order_ticket.dart:120-122` | silent-failure-hunter, security, critical-thinking | PRD demands "specified rounding"; 02 says int cents but not where conversion happens or how it rounds, while requiring review/receipt/Wallet to agree to the cent; 44 `double` money lines today. Fix: one sentence (e.g. `cents = (units*price*100).round()`, fees `cents*bps ~/ 10000`) + an audit step in `gate.sh`. |
| MEDIUM | Untestable acceptance criteria will stall the review loop | `06:13`; `07:14`; `01:17`; `00-baton-queue.md:16` | silent-failure-hunter, architect | CLEAN needs a test cited by path per criterion; "visually and type-distinct", "lands on the panel", "same value on four screens" name none → three failed iterations → PAUSE. Fix: name a widget test per criterion or mark "manual, waived". |
| MEDIUM | "Closes VC-DEM-002" while prices and calls stay outside the store | `00-baton-queue.md:7`; PRD line 82; `arena_mock.dart:17` | silent-failure-hunter | PRD names identities, calls, prices in the store; 01 excludes them and Arena price is a String. Fix: qualify as "financial state; prices/calls remain const fixtures". |
| MEDIUM | Duplicate-guard acceptance is vacuous as written | `02:7,19`; `04:15`; `order_ticket.dart:196,204` | penetration-tester | `_place()` mints a new `actionId` per tap, so a store-level same-id test passes while a real double-tap creates two positions; "disable while in flight" is a no-op on a sync store. Fix: mint the id at ticket open and require a widget test that taps twice. |
| MEDIUM | "Decision-free" conflicts with O-05 for unit 07's copy | `00-baton-queue.md:3`; `07:9`; PRD O-05 | penetration-tester (contested by security — see Disagreements) | "Illustrative index · based on N settled calls" presupposes the A-05 outcome. Fix: state the assumption rather than claim independence. |
| MEDIUM | Gate omits the grep-able checks the specs name | `00-baton-queue.md:3`; `01:20`; `06:14` | penetration-tester | `grep 'PortfolioMock.positions' lib` (1 hit) and "no `All receipts — not in the demo yet`" (3 sites) are deterministic and cheap but not in the gate. Fix: add to `gate.sh`. |
| LOW | Demo clock semantics contradict reset determinism | `01:7,10` | architect | "Advanced only by reset" vs "reset restores the seed exactly". Fix: "fixed at fixture start; reset restores it". |
| LOW | Run-command shape vs. command hint | `commands/baton-runner.md:3`; `00-baton-queue.md:18` | silent-failure-hunter, penetration-tester | Hint is `<queue-path-or-ref>` (singular); eight paths work per `SKILL.md:28` but the hint invites passing `00`, which the skill does not parse. |
| LOW | Unit 08 "1–7" dependency overstates | `00-baton-queue.md:14` | silent-failure-hunter | The Explore/Markets failure toggle and `VistaEmptyState` need no units 2–7. |
| LOW | VC-FED-003 residual untracked | `00-baton-queue.md:13` | silent-failure-hunter | "(trader link)" is honest, but Call details ×2 and like/follow persistence close nowhere. |
| LOW | "No new pub dependencies" unenforced | `00-baton-queue.md:16` | security, penetration-tester | `pubspec.lock` is tracked; add `git diff --exit-code origin/main -- app/pubspec.yaml app/pubspec.lock` to the gate. |
| LOW | VC-MKT-003 and VC-ORD-001 over-claimed for unit 02 | `00-baton-queue.md:8`; `account_top_bar.dart:58-61` | security, penetration-tester, critical-thinking | Chart ranges and deposit/withdraw demo-boundary copy are untouched; ORD-001's Maker entry point only exists after unit 05; trader-market ticket still toasts "filled". Fix: narrow the cell ("position/cash clauses of MKT-003", "ORD-001 except Maker entry"). |

## Coverage Report
Reviewers: 5/5 returned
Reviewed at: c1a6b18863bfb577acc00e356678b6ecf60d2c0f
Any commit after this one is unreviewed.

**Confirmed:**
- Gate command is runnable and clean here: `flutter analyze` → "No issues found"; `flutter test` → 170 passed, exit 0 (38–60 s wall across runs); 88 `testWidgets`/`test(` in 4 files, so the gate is not vacuous — architect, silent-failure-hunter, security, penetration-tester.
- Sequential order 1→8 is topologically valid for every stated edge and every missing edge found (1→{2,3,6}, 2→{4,5}, 6→7, all→8; no back-edges) — architect, silent-failure-hunter, penetration-tester. Edges 2→1, 4→2, 5→2, 6→1, 7→6 traced to spec text — security.
- Every "Closes" ID (16) exists once in PRD §4 and in the drift table; VC-FED-003 "(trader link)" is an honest partial — all four severity reviewers.
- Every unit-spec gap citation resolves against source: `portfolio_mock.dart:74,83`; `market_mock.dart:52,65-77`; `order_ticket.dart:72,196-235` (market branch mutates nothing, toasts "filled (simulated)"); `feed_order_ticket.dart:135-170`; `arena_screen.dart:24,57,83`; `crowd_filter_panel.dart:70`; `opinions_screen.dart:136 'BTC'`; `profile_mock.dart:54-55`; `settings_screen.dart:114 "Log out"`; `account_state.dart:21 @visibleForTesting reset`; "All receipts" ×3 (`your_market_screen.dart:108`, `profile_screen.dart:269`, `trader_market_screen.dart:288`); zero Maker/Aggro hits; `main.dart:21 MaterialApp.builder` — all four severity reviewers.
- `app/pubspec.yaml` has a single dependency (`flutter_svg`); premium-feel's pubspec change adds fonts, not packages — all four severity reviewers.
- Premium-feel overlap with units 02–04 measured (14 files, 609+/502-) — silent-failure-hunter, security.
- `home_screen_test.dart:48-53` device list exists and includes 375×667; smallest is 360×640, no 390×844 (393×852 instead) — architect, security, penetration-tester.
- Baton-runner invocation shape (ordered path list) matches `SKILL.md` `<phase list>` — architect, silent-failure-hunter.
- No network, no persistence: only `dart:io Platform` (`live_feed.dart:2`) and a clipboard URL (`share_call_sheet.dart:61`); the only external inputs are build-time `--dart-define`; unit 03's "Nothing leaves this device" is true and there is no local-state tamper surface until persistence lands — security, penetration-tester.
- Independence from O-01/O-04 holds — security, penetration-tester (O-05 contested, see Disagreements).
- Excluded P0 IDs at the ID level (DEM-001, FED-001/002, LST-001–004, MKT-001, QA-001/003/004) are decision-gated or already Built/Partial per drift — silent-failure-hunter (see Disagreements for the sub-item caveat).
- Unit 03's `MaterialApp.builder` approach is viable in principle: tickets are `showModalBottomSheet` routes rendering under a builder-level overlay — architect (contested as inconclusive by penetration-tester).

**Examined, inconclusive:**
- Whether `PortfolioMock.spans` (six labels, `portfolio_mock.dart:80`) actually switches the series so VC-MKT-003's "two chart ranges" is already met — needs a runtime or test check (architect, security).
- Whether a `GATE_RUNNER` override or the user-scope `~/.claude/skills/baton-runner` copy could supply the gate without editing — REFERENCE says it is an edit; user-scope copy not read (architect).
- Whether unit 04's Arena price reconciles with `MarketPrices` after unit 01 — needs the `Battle.asset` wiring the spec is silent on (silent-failure-hunter).
- Whether `flutter test` in a fresh `.worktrees/` checkout picks up `OpenRunde` font assets identically — runtime check (silent-failure-hunter).
- Whether `tdd`, `baton-pass`, `multi-agent-review` resolve under their namespaces (`mattpocock-skills:tdd`, `ClaudesMods:*`) in the run worktree — needs a live pre-flight (security; listed as not-examined by architect and silent-failure-hunter).
- Whether the `MaterialApp.builder` overlay stays visible over modal bottom sheets — needs a widget test (penetration-tester).
- Whether the baton-runner manager would inline the common rules on its own — depends on manager behaviour, not a file (penetration-tester).

**Not examined (residual risk):**
- The evidence register `docs/prd/2026-10-01-vc-hackathon-evidence.md` — no reviewer read it.
- The `baton-runner-managed` variant as an alternative run path.
- Whether a repo-level `CLAUDE.md` exists in VistaColosseum to carry the common rules (the work-unit prompt cites it).
- Whether unit 08's failure toggle survives reset.
- `docs/agents/` conventions.

Engagement check: all five reviewers engaged — each severity-using reviewer has a substantive Confirmed list backed by commands, and critical-thinking's items cite file lines and command output. No `[DID NOT ENGAGE]` tags. No emptiness/docs-only claims were made; every reviewer treated the SKILL.md/REFERENCE.md/gate.sh bodies as executable surface.

## Unstated Assumptions and Open Questions (from critical-thinking)
- The queue assumes the prose gate is what the runner executes; the skill runs `scripts/gate.sh` and stops if it is absent. Who writes it, with what contents, and does it land on `origin/main` first?
- The run command assumes the specs exist where the runner branches from; they are staged only on this branch. Is merging a precondition, and should the queue say so?
- "rest of VC-DEM-004" assumes units 1+2 complete it; persona switching (PRD §1) and phase advance have no home, while unit 8 adds another presenter control under VC-QA-002. Deferred by which decision, or decision-free P0 that belongs in the queue?
- Row 6 assumes unit 6 needs only unit 1, but its receipts contract needs unit 2's `Receipt`. Should it read "1, 2"?
- Specs 01 and 06 both claim `FeeEntry`/fee-ledger ownership. Which unit defines the type and the seed?
- Spec 04 needs a clash reference on a position; `PortfolioPosition` has no id and display-string money, so 02's "agree to the cent" is asserted against a type with no numeric fields. Does 02 extend the type, or does 04?
- Spec 03 acceptance verifies unit 02's sheet while row 3 depends on 1 only. "1, 2", or drop the line?
- Unit 2's Closes overstates MKT-003 (chart ranges, deposit/withdraw copy), ORD-003 (no rounding rule) and ORD-001 (Maker entry absent until unit 5; trader-market ticket still toasts "filled"). Narrow the cell or add the behaviors?
- "Decision-free P0" silently omits ARN-005 labelling, LST-002's 40% label, FED-001/002 verification and QA-003 rehearsal; 29 drift P0 IDs vs 18 closed. Add one line naming the excluded IDs and the decision each waits on.
- Unit 1 touches ~14+ files vs the runner's ~10 budget. Split, or accept the runner will flag it?
- The gate cannot enforce "no new `double` money" or "success messages describe what happened". Is a grep in `gate.sh` or a reviewer checklist the intended enforcement?
- The staged `.gitignore` ignores `.drift-status/`, the source of every gap citation. Deliberate? Will line citations such as `order_ticket.dart:196-235` still be checkable after unit 1 shifts them?
- Why is unit 6 after 4 and 5 when its only edge is 1 and the roadmap puts VC-REC-001 (M3) before Arena (M4)? Risk-driven or incidental? The runner stops on the first failed unit, so the order matters.

## Reviewer Disagreements
1. **Severity of the missing `scripts/gate.sh`.** silent-failure-hunter: CRITICAL; architect, security, penetration-tester: HIGH. Resolution: CRITICAL — the run cannot start, and the merge rule takes the higher severity.
2. **`MaterialApp.builder` overlay over modal sheets.** architect confirms it viable (bottom sheets are routes under the builder-level overlay); penetration-tester marks it inconclusive pending a runtime/widget test. Resolution: treat as plausible but unverified; unit 03 should name a widget test that opens a ticket and asserts the indicator is still visible.
3. **O-05 independence of unit 07.** security confirms "illustrative index" is mandated by VC-MKT-002 regardless of O-05; penetration-tester says the copy presupposes the A-05 outcome. Resolution: security's reading is the more specific PRD trace; keep penetration-tester's point as a one-line note in the queue ("assumes A-05; reword if O-05 goes otherwise") rather than a dependency.
4. **Are the excluded P0s all decision-gated?** silent-failure-hunter confirms the excluded IDs are gated or Built/Partial; architect, security and critical-thinking name decision-free sub-items (LST-002's 40% label, ARN-005 labelling, FED-003 call details). Resolution: both hold at different granularity — the IDs are gated, the sub-items are not. Add an explicit exclusion line or fold the sub-items into units 4/6/7.
5. **Unit 01 file count.** 14 (penetration-tester), ~16 (architect), ~17 (silent-failure-hunter) — different counting bases, same conclusion: over the ~10 budget. No resolution needed.

## Recommended Changes (Prioritized)
1. Add `scripts/gate.sh` (Flutter analyze + test, `GATE: PASS|FAIL`, non-zero on failure) to this branch and point the queue's gate line at it.
2. Merge this branch (specs + `gate.sh`) to `main` and state that precondition in the queue preamble.
3. Copy the common-rules block into each unit spec's header (or a repo `CLAUDE.md`) so work/review/fix units actually see it.
4. Rewrite the DEM-004 cells as "reset + truthful notifications only; persona/phase deferred" and record the residual (or add a persona-switch unit).
5. Record the premium-feel merge-or-park decision as a precondition of unit 02 and re-cite line numbers afterwards.
6. Fix the Depends column: 03→1,2; 06→1,2; 07→4,6; trim 08's "1–7" to what it actually needs.
7. Move the `clashId`/int-cent shape of `OrderIntent`, `PortfolioPosition` and `Receipt` into unit 02 so unit 04 adds behavior only.
8. Make unit 01 list exactly the fields it seeds and say that 04/05/06 extend the store with their own types.
9. Pre-split unit 01 into 01a (store + seed + reset + tests) and 01b (caller migration + Settings reset row).
10. Add one rounding sentence to unit 02 and an `audit-numeric-types` / pubspec-diff / `PortfolioMock.positions` / "All receipts" grep step to `gate.sh`.
11. Name a test file per acceptance criterion in units 01, 03, 06 and 07, or mark the criterion "manual, waived".
12. Require unit 02's `actionId` to be minted at ticket open and a widget test that taps confirm twice.
13. Narrow the remaining Closes cells (DEM-002, MKT-003, ORD-001, FED-003) and add a "Deliberately excluded" line naming the P0 IDs and sub-items left out and the decision each waits on.
14. Fix the demo-clock wording in unit 01 ("fixed at fixture start; reset restores it") and note the assumed A-05 outcome in unit 07.

## Open Questions for the Author
- Will `scripts/gate.sh` be written here, and is merging this branch to `main` the intended precondition of the run?
- Is persona switching deferred by an explicit decision, or is it decision-free P0 that should get its own unit?
- Merge or park `feat/premium-feel` before unit 02?
- Which unit owns `FeeEntry` and the `clashId`/numeric fields on `PortfolioPosition` — 01/02, or 06/04?
- Is the unit-6-after-4/5 ordering risk-driven (land the confirm path first) or incidental?
- Is `.drift-status/` meant to be git-ignored given it is the source of every gap citation?
- Should the common rules be enforced by `gate.sh` grep checks, a reviewer checklist line, or both?
- Is unit 01 to be pre-split, or do you accept the runner splitting it on its own terms?

## Report Audit

1. **Coverage Report over-credits reviewers on composite Confirmed lines (class 5/6).**
   - Report: "`app/pubspec.yaml` has a single dependency (`flutter_svg`); premium-feel's pubspec change adds fonts, not packages — all four severity reviewers."
   - Source: only security-reviewer states "premium-feel's pubspec change adds fonts, not packages." architect-reviewer lists "`feat/premium-feel` (25 commits)" under **Not examined**; penetration-tester lists "`feat/premium-feel` divergence (25 commits)" under **Not examined**. Crediting those two with a premium-feel confirmation contradicts their own not-examined lists.
   - Same pattern, smaller: "Every 'Closes' ID (16) exists once in PRD §4 and in the drift table; VC-FED-003 '(trader link)' is an honest partial — all four severity reviewers." Architect says only "Every 'Closes' ID exists in PRD §4"; security says only "Every 'Closes' ID exists in PRD §4." The drift-table clause is silent-failure-hunter's alone; the "honest partial" clause is penetration-tester's alone.

2. **"Independence from O-01/O-04 holds — security, penetration-tester" (class 6).**
   - Source: security-reviewer's Validated list says "Independence from O-01/O-04/O-05 holds." penetration-tester's Validated list contains no O-01/O-04 confirmation; its only decision-ID statement is finding 7, "'Decision-free' claim conflicts with O-05." The pen-tester is credited with a confirmation it did not make.

3. **LOW row "VC-MKT-003 and VC-ORD-001 over-claimed for unit 02 — security, penetration-tester, critical-thinking" (class 6, minor).**
   - Source: security L9 and penetration-tester L10 address VC-MKT-003 only. The VC-ORD-001 half ("Maker-suggestion entry point does not exist until unit 5", "trader-market ticket … still ends in the 'filled' toast") appears only in critical-thinking's item "Unit 2's Closes overstates VC-MKT-003 and VC-ORD-001/003." The merged row credits security and penetration-tester with the ORD-001 claim.

4. **Disagreement 4 recasts critical-thinking's ID-level claim as a sub-item claim (class 6, minor).**
   - Report: "architect, security and critical-thinking name decision-free sub-items … Resolution: both hold at different granularity — the IDs are gated, the sub-items are not."
   - Source: critical-thinking names whole IDs as "Not queued and not blocked by O-01/O-04/O-05: … VC-FED-001/002 verification, VC-QA-003 rehearsal" — which directly contradicts silent-failure-hunter's "Excluded P0 IDs (DEM-001, FED-001/002, … QA-001/003/004) … all are decision-gated (O-04/O-05) or already Built/Partial." The report preserves CT's text verbatim in the Unstated Assumptions section, so nothing is lost, but the Disagreement entry's "the IDs are gated" resolution does not acknowledge that CT disputed it at the ID level.

No other defects found: every reviewer finding reaches a section, all reviewer HIGHs land in Critical/High with no demotion, the "4 HIGH" count reconciles, and the Medium/Low attributions otherwise match the source.
