# dw-review — `feat/br-2026-10-05-copy-story/phase-1` (copy story, spec 09)

- **Target:** `feat/br-2026-10-05-copy-story/phase-1`, phase 1 of 1 of baton-runner run `br-2026-10-05-copy-story`: the copy story (`docs/specs/09-copy-story.md`; PRD VC-CPY-001, VC-CPY-002, VC-DEM-004 persona switch). It adds a creator/copier `Persona` with per-persona books, a Settings "Demo persona" row, copy entry on `OrderIntent` (`sourceCallId`, `sourceAuthorHandle`), a flat `kCopyFeeCents = 500` copy fee debited inside `Scenario.placeOrder`, a `copyFee` row in the creator's ledger, and the "Copying @<handle> · $5.00 copy fee" line on review, receipt sheet and Receipts. Diff: `origin/main...HEAD -- app`, 19 files (13 `lib`, 6 `test`) at 4807f69.
- **Commit reviewed:** the review ran at `cc02d6cb8dc22d7e071685290ec4a8ac8f61f6eb` (cc02d6c). The fixes landed at `4807f69` ("fix(phase-1): apply the 10 adjudicated dw-review findings (F1-F10)").
- **Date:** 2026-10-05 UTC (run log 17:24:05Z review launch to 18:09:06Z close gate, then this closing unit). Skill `dw-review`, run by `baton-runner-managed`. Workflow runs `wf_d95b76b4-aa5` (review) and `wf_67c22ae4-8a7` (finding-fixer).
- **Lanes:** tautology-hunt 6, money-state-invariants 4, ui-truthfulness 4 (raw 14), plus the fixed skeptic. Merges: 1 with 10, 7 with 12, 8 with 11, 9 with 13, so 14 raw = 10 confirmed (1 HIGH, 3 MEDIUM, 6 LOW). Refuted outright: 0 (one sub-claim of raw finding 9 dropped). Checked claims that were wrong: 0. No finding is before-merge.
- **Disposition:** 10 of 10 dispositioned: 10 applied, 0 refuted, 0 already-handled, 0 real-but-decided-elsewhere (fixer coverage: failedGroups [], unreported []; skipped []). Every adjudicator verdict was fix-here. F1, F2, F3 change product code, each behind a test that ran red first. F4-F9 are test-strength fixes, each mutation-proven (the named mutant survived the old suite, the new test kills it). F10 is a style-only token refactor with no testProof.
  - Manager decisions in force (house-rules.md, verbatim): "Spec 09 has exactly one fee ledger, the creator persona's ("the ledger belongs to the creator"). A confirmed copy of ANY other author's call credits that ledger with one copyFee row; per-author ledgers do not exist and are out of scope. The creator copying someone else's call pays the fee but no row is written (she would credit herself)."

## Verdict: MERGE-WITH-FIXES

> The scope check passed. feat/br-2026-10-05-copy-story/phase-1 resolves to cc02d6c, which is also the worktree HEAD. origin/main resolves to 7d39bff. The three-dot diff lists 20 files, 14 of them under app/. The newest two commits are run bookkeeping only.
>
> I found no money or recording defect. The copy fee, the cash debit and the ledger row come from one `copyFee` local value in a single write path. All three sit after the actionId guard, problem(), the resting return and the stale-price return (scenario.dart:333-436), so a resting or failed copy writes nothing.
>
> Survivors after merging duplicates:
> - **HIGH:** Arena participation is shared between personas while receipts are per persona. "Joined Bull/Bear" can be shown to a persona who never joined, and it can contradict the active persona's own position. Reproduced in source.
> - **MEDIUM:** The ledger can show "No fee credits yet" above a $5.00 copy row and a $5.00 Total, while the chip and Portfolio row that open it still show market credits only, under a stale "ledger's sum" comment.
> - **MEDIUM:** The top bar and the Settings header still name maya.eth while the copier's cash is shown.
> - **MEDIUM:** No test proves that a resting or stale copy writes nothing.
> - **LOW:** Five test gaps and one token nit.
>
> Nothing freezes at merge, so no survivor is must-fix-before-merge. The participation bug should still be fixed before the demo is shown with persona switching. I refuted no finding outright. Each was reproduced against the tree, and duplicates were merged: 1 with 10, 7 with 12, 8 with 11, 9 with 13.

Every confirmed finding, F1 through F10, was applied at 4807f69 and the full gate passed there, so the merge-with-fixes condition is met.

## Confirmed findings

| ID | Sev | Location | Finding | Adjudicator | Disposition | Adjudicator evidence (verbatim) | As landed at 4807f69 | Red before edit |
|---|---|---|---|---|---|---|---|---|
| F1 | HIGH | `app/lib/scenario/scenario.dart:136-146` | Arena participation is not keyed by persona, so 'Joined Bull/Bear' and the crowd count disagree across a persona switch | fix-here | applied | "scenario.dart:92 `static final participation = ValueNotifier<Map<String, TradeSide>>(const {});` is a single shared map, written at :435-440 on every clash fill." | `participation` is a fifth `Books` field: seeded `{}` for the copier, read in `_active`, swapped in `switchPersona` (scenario.dart:113-148). Test `participation follows the persona, as its receipts do` (copy_story_test.dart:301). | red captured |
| F2 | MEDIUM | `app/lib/features/market/receipt_screens.dart:96-101` | Ledger shows 'No fee credits yet' above a copy-fee row and a non-zero Total, and its entry points under-report against it | fix-here | applied | "So with no market credit and one copy row the screen shows the empty state, a copy row and a non-zero Total at once. [...] What is wrong there is only the comment `// The ledger's sum, never a stored figure; opens the ledger.` at your_market_screen.dart:168 and portfolio_screen.dart:201, which stopped being true when the Total gained copy fees in this diff." | Empty state now `entries.isEmpty && copies.isEmpty` (receipt_screens.dart:95); both chip/row comments now say "Market credits only (spec 06)". Test in receipts_test.dart. Chip and Portfolio row keep market credits only, by spec 06. | red captured |
| F3 | MEDIUM | `app/lib/features/account/account_top_bar.dart:39` | Identity surfaces still say maya.eth while the copier's cash is shown | fix-here | applied | "Nothing decides this: docs/specs/09-copy-story.md line 11 keys cash/positions/orders/receipts by persona and leaves likes, favourites, follows, listing and the ledger single; it says nothing about identity text, and the manager's list (items 10-14) does not name it either." | AccountTopBar reads `Scenario.activePersona` through a ValueListenableBuilder; Settings header reads `Scenario.activePersona.value.handle` (settings_screen.dart:182); dead `SettingsMock.handle` deleted. Test `the top bar and Settings name the active persona` (scenario_test.dart). | red captured |
| F4 | MEDIUM | `app/test/copy_story_test.dart` | No test proves that a resting or stale-price copy writes no fee and no ledger row | fix-here | applied | "Spec 09 Behavior: '`resting` and `failed` results write no fee and no credit.' No Acceptance line names a test for it." | `copyOf` gained `kind`; tests `a resting copy writes no fee and no ledger row` (:192) and `a stale-price copy fails and writes nothing` (:204). | red captured |
| F5 | LOW | `app/lib/scenario/scenario.dart:197` | Copy fees leaking into marketFees, or dropping out of the ledger Total, would go unnoticed | fix-here | applied | "LedgerScreen is pumped only in receipts_test and empty_states_test, never with a copyFee row. So both mutants survive today." | `copyRows` delegates to `Scenario.copyFees`; test 1 asserts `marketFeesCents == 0`; widget test `the ledger lists a copy fee in its copy section and counts it once in the total` (:102). Fixer also added the `live_feed.dart` import the edit omitted. | red captured |
| F6 | LOW | `app/lib/features/settings/settings_screen.dart:122-137` | The Settings 'Demo persona' row and its 'Now acting as' toast have no test | fix-here | applied | "Claim holds. [...] the only Settings widget tests are scenario_test.dart:156-191 ('Reset demo in Settings ...') and home_screen_test.dart:1374/1828 (open Settings only)." | Widget test `the Settings Demo persona row switches hands and says who is acting` (:263). | red captured |
| F7 | LOW | `app/lib/features/trade/caller_play_screen.dart:47-48` | The CallerPlayScreen copy entry is untested | fix-here | applied | "Scenario.copyFeeCents (scenario.dart:152-156) returns 0 when `intent.sourceAuthorHandle == null`, so deleting those two lines makes every copy from Asset trade › Callers › play a plain order with no copy line, no fee and no ledger row." | Widget test "a caller's play copies their call with the fee" (feed_order_ticket_test.dart:72). The edit's `material.dart` import was removed again (analyze: unnecessary_import). | red captured |
| F8 | LOW | `app/lib/scenario/scenario.dart:419` | The rule that a creator copying another author's call writes no ledger row is unpinned | fix-here | applied | "Tests where the creator copies another author (copyFee > 0, activePersona creator): [...] So the mutant `copyFee > 0` alone survives." | `expect(Scenario.feeEntries.value, same(YourMarketMock.fees))` after Confirm in order_ticket_test 'feed ticket confirm adds a position and View in Wallet shows it'. | red captured |
| F9 | LOW | `app/lib/features/market/receipt_screens.dart:320-321, 370-374` | The ReceiptsScreen copy line and the persona-keyed `own` check are unpinned | fix-here | applied | "For every one of those, `author == PortfolioMock.handle` and `author == Scenario.activePersona.value.handle` give the same answer, and no listed receipt carries a copy fee, so mutant 1 (delete the copyLine Text) and mutant 2 (revert `own` to PortfolioMock.handle) both survive." | Widget test 'the receipts list shows the copy line on the copier's own paper receipt and no paper section under the creator' (:331). Reuses receipts_test's `pumpApp` (the edit's trader_record_test import would have been an ambiguous name). | red captured |
| F10 | LOW | `app/lib/features/trade/order_ticket.dart:986-993` | The new review copy line hardcodes fontSize 14 and top padding 10 | fix-here | applied | "Claim holds against the invariant as written. [...] The remaining single `fontSize: 14` literal is the carried-forward pattern of this file, not new to this run." | `figure` hoisted once (order_ticket.dart:906); `muted` derives from it; both `top: 10` became `VistaSpace.lg`. `fontSize: 14` count in the file: 9 on main, 8 now. | n/a (no testProof: style-only, behaviour identical) |

## What the fixes now reject

All ten `rejectsValidInput` answers are none or n/a. F1-F3 change display or per-persona bookkeeping only (F1: "No input gate is added or tightened"; F3: "display-only"). F4-F9 add tests only. F10 is byte-identical rendering. Nothing in the fixer run executed a rejected input.

## Refuted: 0 (one sub-claim dropped)

- **(none refuted outright) Finding 9 sub-claim: Portfolio 'Fees from your market' showing the creator's earnings to the copier is a defect** Skeptic: "The ledger is the creator's by the manager's ruling, and the spec says the listing stays shared. Which persona sees the creator's market earnings is a design choice, not a failure path. The rest of finding 9 (the top bar handle) is confirmed and merged into the identity finding."

## Checked claims that were wrong: 0

The skeptic's `checkedClaimsThatAreWrong` list is empty.

## Residual risk (verbatim)

- tautology-hunt: I did not run any test or apply any mutation, because I am read-only and the gate already passed at f9368e6. Mutant survival is argued from reading the code and grepping test/, not from execution.
- tautology-hunt: The actionId guard scans only the active persona's receipts and openOrders. I found no UI path that re-confirms the same actionId after a persona switch, so I did not file it.
- tautology-hunt: I did not check correctness outside test strength: sourceCallId uniqueness ('handle/ticker'), the copy row's marketId when the creator is unlisted, and identity surfaces that still show maya.eth while acting as the copier.
- tautology-hunt: I did not scan baton-runner/ or baton-pass/ files, which are out of scope for findings, beyond reading the review baton to avoid re-filing its items verbatim.
- money-state-invariants: Did not run any flutter test. The facts give a gate PASS at f9368e6 with identical app code; findings come from reading the source.
- money-state-invariants: UI copy and layout in receipt_screens.dart, settings_screen.dart and the review sheet (design tokens, the exact toast text) belong to another lane; I checked only that the review and receipt totals match the stored cents.
- money-state-invariants: Did not check whether the ledger is reachable before the creator lists a market. Copy fees are not filtered by listing, so a pre-listing ledger could show 'No fee credits yet' with a non-zero Total.
- money-state-invariants: Did not cover the existing double-to-cent rounding at Max (marginCents is rounded from units*price), which can push a 100% stake 1 cent over cash. That predates this diff and is not specific to the copy fee.
- ui-truthfulness: Did not run any flutter test or the gate (trusted the stated PASS at f9368e6 with 296 tests); all findings are from reading the source
- ui-truthfulness: Did not measure 1.3x text-scale rendering of the Settings row or the ledger copy row; I relied on them sitting in scroll views or using Expanded and wrapping Text
- ui-truthfulness: Scenario.placeOrder write atomicity and the creator-ledger credit rule (R1) are in another lane or already decided by the manager; I did not re-review them
- ui-truthfulness: Other persona-unaware shared state beyond participation and identity (e.g. trader-record panels, Your market screen header 'maya.eth · your market') is treated as part of the single listing per spec and was not filed

## Acceptance re-check after the fixes (closing unit, at 4807f69)

| # | Criterion | Test (name matches spec verbatim) | Code it exercises | Verdict |
|---|---|---|---|---|
| 1 | Copy confirm debits margin + fee + 500, one position, one receipt with sourceCallId, one 500 copyFee row | `copy_story_test.dart:62 'confirming a copied order debits the copy fee once and credits the creator once'` | `scenario.dart:337-447 (`copyFee` at :373, debit via `receipt.totalCents` :417, row :423-438), :636 `totalCents`` | met |
| 2 | Cancel writes nothing (deep equality) | `copy_story_test.dart:114 'cancelling a copied order writes nothing'` | `feed_order_ticket.dart review/cancel; `state()` now includes both personas' books and participation` | met |
| 3 | Insufficient funds incl. copy fee: failed, nothing written | `copy_story_test.dart:136 'copy fails whole when cash cannot cover margin, fee and copy fee'` | `scenario.dart:318-319 (`totalCents + copyFee > cash` → notEnoughFunds), :346 early return` | met |
| 4 | Repeated actionId: first result, one position, one row | `copy_story_test.dart:158 'repeated actionId on a copy does not double-pay'` | `scenario.dart:339-344 actionId guard before any write` | met |
| 5 | Own call: no copy fee, no row | `copy_story_test.dart:175 'own call places an ordinary order'` | `scenario.dart:156-160 `copyFeeCents` returns 0 for the active persona's handle` | met |
| 6 | Switch preserves both books; reset restores creator and both seeds | `copy_story_test.dart:216 'switch then reset restores creator and both seeds'` | `scenario.dart:141-152 `switchPersona`, :450-474 `reset`` | met |
| 7 | Review and receipt show the copy line; total agrees with stored cents | `feed_order_ticket_test.dart:35 'copy review shows the $5.00 copy fee in the total'` | `order_ticket.dart:903, :985-993 copy line, :994 total; scenario.dart:502 `copyLine`` | met |

Ledger copy-section visual distinctness: manual, waived (spec).

## House-rule grep on the diff (closing unit, `origin/main...HEAD -- app`)

- New `double` in `app/lib`: none (no added or removed line mentions `double`).
- `Color(` or `fontSize:` added in feature code outside `design_system`: one added line, `final figure = VistaType.body.copyWith(fontSize: 14);` (order_ticket.dart:906). It is F10's hoist of the pre-existing `row()` literal: the same hunk removes two `fontSize: 14` lines, and the file holds 8 such literals now against 9 on main. No new literal; no `Color(` added.
- `app/pubspec.yaml`, `app/pubspec.lock`: unchanged (empty diff; gate `pubspec-frozen` PASS).
- Scenario-phase advance (O-10): no added line mentions phase or advance.
- "not in the demo yet" toasts: none added or removed.

## Verification after the fixes

finding-fixer verification (`scripts/gate.sh baton-runner/br-2026-10-05-copy-story/gate-phase-1-fixer/`): `GATE: PASS`, exit 0, `01:29 +305: All tests passed!`. Its first run failed flutter-analyze on `unnecessary_import` from edit F7.1; that import was removed and the gate rerun.

Full gate after commit (`baton-runner/br-2026-10-05-copy-story/gate-phase-1-close/`), verbatim:

```text
=== gate: flutter-analyze: flutter analyze ===
PASS flutter-analyze
=== gate: flutter-test: flutter test ===
PASS flutter-test
=== gate: pubspec-frozen: git diff --exit-code 7d39bffaa1e1e594dfccb6f39359b9d9038df4e7 -- pubspec.yaml pubspec.lock ===
PASS pubspec-frozen
----
GATE: PASS
exit=0
01:32 +305: /home/alex/VistaColosseum/.worktrees/br-2026-10-05-copy-story/app/test/home_screen_test.dart: (tearDownAll)
01:32 +305: All tests passed!
hm-exit=0
```

`flutter-test.log` `01:32 +305: All tests passed!`, `flutter-analyze.log` `No issues found!`, `flutter test --dart-define=HAS_MARKET=true` `01:31 +305: All tests passed!` (hm-exit=0). The closing unit did not re-run the gate or any test.

GATE: PASS exit 0 at 4807f69, 305 tests, HAS_MARKET=true 305
