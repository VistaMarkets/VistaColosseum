# dw-review — `feat/br-2026-10-04-p0-queue/phase-5` (Maker suggestion card, spec 05)

- **Target:** `feat/br-2026-10-04-p0-queue/phase-5`, phase 5 of baton-runner run `br-2026-10-04-p0-queue`: a Maker suggestion card in the Home feed. It adds the `Suggestion` fixture and two seeded cards (SOL long, live; ETH short, expired) timed on `Scenario.clock`, and "Trade this" opens the unit-02 feed ticket on the suggestion's asset and side (`docs/specs/05-maker-suggestion-card.md`, PRD VC-FED-004). The branch is stacked on `feat/br-2026-10-04-p0-queue/phase-4` (`96abf7f70c6d99ee30a26b3defb687cc23547378`), which is draft [VistaColosseum#15](https://github.com/VistaMarkets/VistaColosseum/pull/15). Phases 1-3 are on main as [VistaColosseum#10](https://github.com/VistaMarkets/VistaColosseum/pull/10), [VistaColosseum#12](https://github.com/VistaMarkets/VistaColosseum/pull/12) and [VistaColosseum#13](https://github.com/VistaMarkets/VistaColosseum/pull/13). Diff reviewed: `feat/br-2026-10-04-p0-queue/phase-4...feat/br-2026-10-04-p0-queue/phase-5` (46 files; 4 under `app/`: `maker_suggestion.dart` (new), `home_screen.dart`, `home_screen_test.dart`, `order_ticket_test.dart`).
- **Commit reviewed:** the review ran at `87271f155e4d93410c7f3d79e226feb29be9622c`. The fixes landed at `d935436e9ca91e26b404682a57db19558a13e605`.
- **Date:** 2026-10-04. Skill `dw-review`, run by `baton-runner-managed`. Workflow runs `wf_6ecdbb4a-a23` (review) and `wf_c48cc226-da2` (finding-fixer).
- **Lanes:** tautology-hunt 5, state-truthfulness 0, layout-semantics 1 (raw 6), plus the fixed skeptic. Merges: 1 (tautology-hunt's reference-line finding and its tautological `referencePrice` finding became F3). Confirmed: 5 (1 MEDIUM, 4 LOW; severities as the lanes filed them). Refuted: 0. None is marked before-merge.
- **Disposition:** 5 of 5 dispositioned: 5 applied, 0 annotated, 0 skipped, 0 unreported (fixer coverage: no failed groups, none unreported). Every adjudicator verdict was fix-here. F1, F3, F4 and F5 are in the writer's applied list. F2 has an empty edits list: by the run's house rule 11 its proof lives in the test F1 added, so it is applied via F1's test. F5 is the only product-code change (`maker_suggestion.dart`: the badge label colour), behind a colour pin that ran red first. F1-F4 are test-strength fixes in `home_screen_test.dart`, each mutation-proven: the mutant survived the old tests and the new tests kill it.
  - Run manager's note (log 2026-10-05T03:15:57Z): "Trade this" opens the phase-2 feed ticket, which prices at the live mark (`MarketPrices.now`). The suggestion's reference price does not seed the ticket price. That is an author call against PRD VC-ORD-001 ("reference price"), not a spec 05 gap: spec 05 asks only that asset and direction be prefilled.

## Verdict: APPROVE

"Scope checked and fine. In /home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue, phase-5 resolves to 87271f1 (also HEAD) and phase-4 to 96abf7f. The three-dot diff lists 46 files. The app/ part is maker_suggestion.dart (new), home_screen.dart, home_screen_test.dart and order_ticket_test.dart. The only uncommitted change is baton-runner/.../log.md.

All six findings hold when checked against the tree. Five are gaps in the tests and one is a small contrast miss on the advisory badge. None is a product bug, none is permanent, and none is CRITICAL or HIGH. I merged the reference-line finding with the tautological referencePrice finding, because a single rendered-text check fixes both.

One reviewer's "verified as correct" claim is wrong: tautology-hunt says the app does not clamp text scale. app/lib/main.dart clamps it to 1.3 (MediaQuery.withClampedTextScaling, maxScaleFactor 1.3). Their conclusion that the 1.3x overflow test is real still holds, because 1.3 is the clamp ceiling.

Nothing must be fixed before merge. All survivors can be fixed after."

## Confirmed findings

### F1 MEDIUM — Ticket-prefill test cannot tell 'uses the suggestion's asset/direction' from a hardcoded SOL/long

**Location:** app/test/home_screen_test.dart:2885-2896; wiring at app/lib/features/home/home_screen.dart (symbol: item.asset, side: item.direction) at 87271f1. Now `app/test/home_screen_test.dart:2909` (new test), assertions `:2932-2933`; wiring unchanged at `app/lib/features/home/home_screen.dart:91-92` at d935436. Raised by tautology-hunt.

Only the live suggestion (SOL long) is traded in the suite, and ETH short is expired at the seeded clock. Suppose home_screen.dart passed symbol: 'SOL' and side: TradeSide.long instead of item.asset and item.direction. The (symbol, side) record check and the 'Long $200 · 2x' text check would both still pass. grep shows makerSuggestions is referenced only in home_screen_test.dart, so no other test catches it. The iter-1 'wrong-asset' mutant was killed only because it changed the value to 'ETH'.

**Applied:** Added the test 'a card follows the demo clock, and Trade this opens the ticket on that suggestion's asset and side' just before the expired-suggestion test. It moves Scenario.clock 3h earlier so the ETH short is live, taps its Trade this, asserts the ticket's (symbol, side) is (ETH, short) and that 'Short $200 · 2x' shows, then sets the clock back to chartEnd with the card still mounted and asserts it flips to ('Expired', false). Mutation proof: with home_screen.dart hardcoded to symbol 'SOL' / side TradeSide.long, the old maker group passed ('00:03 +14: All tests passed!') and the new test failed (red below). This test also covers F2: the clock-snapshot mutant (valueListenable: ValueNotifier(Scenario.clock.value)) fails it at line 2926 with 'Expected: (String, bool):<(Expired, false)> Actual: (String, bool):<(Trade this, true)>'. Both mutants were reverted and the group passed (+15).

**Test:** `app/test/home_screen_test.dart: a card follows the demo clock, and Trade this opens the ticket on that suggestion's asset and side`.

Red output, verbatim from the writer:

```text
00:00 +0: maker suggestion a card follows the demo clock, and Trade this opens the ticket on that suggestion's asset and side
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: (String, TradeSide):<(ETH, TradeSide.short)>
  Actual: (String, TradeSide):<(SOL, TradeSide.long)>

This was caught by the test expectation on the following line:
  file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/home_screen_test.dart line 2921
The test description was:
  a card follows the demo clock, and Trade this opens the ticket on that suggestion's asset and side
00:01 +0 -1: maker suggestion a card follows the demo clock, and Trade this opens the ticket on that suggestion's asset and side [E]
00:01 +0 -1: Some tests failed.
(old maker group under the same mutant: 00:03 +14: All tests passed!)
```

### F2 LOW — No widget test moves Scenario.clock while a card is mounted, so the card's link to the demo clock is unpinned

**Location:** app/lib/features/home/maker_suggestion.dart:78-79; app/test/home_screen_test.dart:2810-2935 at 87271f1. Now `app/test/home_screen_test.dart:2913-2915` (clock moved 3h earlier) and `:2935-2937` (clock back to chartEnd, card flips); product unchanged at `app/lib/features/home/maker_suggestion.dart:78-79` at d935436. Raised by tautology-hunt.

Mutant: replace `valueListenable: Scenario.clock` with ValueNotifier(TradeMock.chartEnd). The iter-1 probe recorded this in mutate-run-1.txt line 1 as 'clock-constant: rc=0 SURVIVED', with +14 passing. The only Scenario.clock read in the group is at line 2836, in a pure test that never builds the card. Today this has no visible effect in the product, because nothing in lib writes the clock except Scenario.reset (scenario.dart:266), and that writes the same chartEnd. The gap only matters once a later phase advances the clock.

**Applied:** via F1's test. The adjudicator's verdict is fix-here with an empty edits list: by house rule 11 one test covers both findings, so the writer applied it once, under F1. The writer's F1 summary records the F2 proof: "This test also covers F2: the clock-snapshot mutant (valueListenable: ValueNotifier(Scenario.clock.value)) fails it at line 2926 with 'Expected: (String, bool):<(Expired, false)> Actual: (String, bool):<(Trade this, true)>'."

**Test:** `app/test/home_screen_test.dart: a card follows the demo clock, and Trade this opens the ticket on that suggestion's asset and side` (F1's test).

F2's testProof, verbatim:

> app/test/home_screen_test.dart, the test F1 inserts: its final line is `expect((button().label, button().enabled), ('Expired', false));`, after `Scenario.clock.value = TradeMock.chartEnd; await tester.pump();` with the ETH card mounted. Mutation: in app/lib/features/home/maker_suggestion.dart replace `valueListenable: Scenario.clock,` with `valueListenable: ValueNotifier(Scenario.clock.value),`. The old maker group passes, and the new test fails on the flip assertion. clock-constant (`valueListenable: ValueNotifier(TradeMock.chartEnd),`) also survives the old group and is killed by the new test. Both verified on a scratch copy with flutter test --plain-name 'maker suggestion'.

### F3 LOW — Reference-price/expiry line is never asserted, and the referencePrice unit check just restates the getter

**Location:** app/lib/features/home/maker_suggestion.dart:31 and 111-115; app/test/home_screen_test.dart:2841-2842 at 87271f1. Now `app/test/home_screen_test.dart:2874-2875` (reference-line entry, checked at `:2877`) and `:2841-2842` (reworded comment); product unchanged at `maker_suggestion.dart:31` and `:111-115` at d935436. Raised by tautology-hunt (two raw findings merged by the skeptic).

Mutant drop-reference-line deletes the 'Reference $214.90 · expires in 4h' Text, and all maker tests still pass (mutate-run-2.txt: 'drop-reference-line: rc=0 SURVIVED'). Other mistakes would also pass unseen: a wrong span sign (`_span(left)` on the expired branch, which prints '-2h') or a wrong asset's quote. Separately, `expect(s.referencePrice, TradeMock.quotes[s.asset]!.price)` repeats the getter body word for word. A forked copy holding today's value would pass, so the comment 'not a forked copy' claims more than the check proves.

**Applied:** Added the line 'Reference ${TradeMock.quotes[s.asset]!.price} · ${s == live ? 'expires in 4h' : 'expired 2h ago'}' to the text list in the maker layout loop (F3.1). Reworded the referencePrice comment in the seeded unit test so it claims only what the check proves (F3.2). Mutation proof: with the span-sign mutant ('expired ${_span(left)} ago') in maker_suggestion.dart, the old group passed ('00:04 +15: All tests passed!') and the new entry failed (red below). Mutant reverted; group passed (+15).

**Test:** `app/test/home_screen_test.dart: both cards render without overflow on <phone> at <1.0|1.3>x text` (10 cases).

Red output, verbatim from the writer:

```text
00:00 +0: maker suggestion both cards render without overflow on small Android 360x640 at 1.0x text
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: exactly one matching candidate
  Actual: _HitTestableWidgetFinder:<Found 0 widgets with text "Reference $2,968.40 · expired 2h ago"
(considering only hit-testable widgets with a RenderBox): []>
   Which: means none were found but one was expected

This was caught by the test expectation on the following line:
  file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/home_screen_test.dart line 2877
The test description was:
  both cards render without overflow on small Android 360x640 at 1.0x text
00:01 +0 -1: maker suggestion both cards render without overflow on small Android 360x640 at 1.0x text [E]
  Test failed. See exception logs above.
  ... and 6 more
```

### F4 LOW — The expired-button test's 'Confirm' assertion cannot detect that the ticket opened

**Location:** app/test/home_screen_test.dart:2917 at 87271f1. Now `app/test/home_screen_test.dart:2959` (`expect(find.byType(FeedOrderTicket), findsNothing);`), next to the `BottomSheet` guard at `:2958`. Raised by tautology-hunt.

If the expired button did open the feed ticket, the sheet would show its first screen (Market/Limit tabs, leverage, side/amount button). 'Confirm' appears only in the review panel's action (order_ticket.dart:956), and that panel renders only after _review is set (feed_order_ticket.dart:214-215). So find.textContaining('Confirm') finds nothing even when the ticket is open. The real guard is the BottomSheet check on line 2916. The test name 'so nothing can be confirmed' rests on that line, not this one.

**Applied:** Replaced the dead expect(find.textContaining('Confirm'), findsNothing) in the expired-suggestion test with expect(find.byType(FeedOrderTicket), findsNothing). The BottomSheet assertion stays as it was. Mutation proof: with vista_flow.dart onTap: onPressed (ignores enabled) and the BottomSheet line removed to isolate it, the old 'Confirm' assertion passed ('00:01 +1: All tests passed!') and the new one failed (red below). Mutant reverted and the BottomSheet line restored.

**Test:** `app/test/home_screen_test.dart: an expired suggestion says Expired, is disabled and opens no ticket, so nothing can be confirmed`.

Red output, verbatim from the writer:

```text
Expected: no matching candidates
  Actual: _TypeWidgetFinder:<Found 1 widget with type "FeedOrderTicket": [
            FeedOrderTicket(dependencies: [MediaQuery], state: _FeedOrderTicketState#bcff5),
          ]>
   Which: means one was found but none were expected

This was caught by the test expectation on the following line:
  file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/home_screen_test.dart line 2950
The test description was:
  an expired suggestion says Expired, is disabled and opens no ticket, so nothing can be confirmed
00:01 +0 -1: maker suggestion an expired suggestion says Expired, is disabled and opens no ticket, so nothing can be confirmed [E]
00:01 +0 -1: Some tests failed.
(old 'Confirm' assertion alone under the same mutant: 00:01 +1: All tests passed!)
```

### F5 LOW — Advisory badge text is 4.26:1 contrast, below WCAG AA 4.5:1 for small text

**Location:** app/lib/features/home/maker_suggestion.dart:95-99 at 87271f1. Now `app/lib/features/home/maker_suggestion.dart:98` (`textColor: VistaColors.textPrimary`); colour pin at `app/test/home_screen_test.dart:2892-2899`. Raised by layout-semantics.

The VistaTag label uses VistaType.labelStrong (11pt w700, not large text) in VistaColors.accent #5AA6DE. Its fill is accentTint 0x385AA6DE over the card's surface #1F1F1F, which blends to about rgb(44,61,73). The contrast is 4.26:1 on every device and text scale. This badge is the label that marks the card as advisory. For context, the existing enabled primary button (white on accent) is 2.64:1, so the design system already falls short of AA in places. This is a pairing choice new in this diff, not a regression.

**Applied:** Changed the advisory badge's VistaTag textColor from VistaColors.accent to VistaColors.textPrimary, keeping the existing accentTint fill. No new token (decision 10). Wrote the optional colour pin first, in the 'Trade this opens the ticket on the suggestion's asset and side' test after turnTo(live): it asserts the badge Text style colour equals VistaColors.textPrimary. It failed against the old code (red below) and passes after the edit.

**Test:** `app/test/home_screen_test.dart: Trade this opens the ticket on the suggestion's asset and side` (colour pin).

F5's testProof is not n/a. The adjudicator offered the test only as an optional pin; the writer wrote it first and it ran red, so the red is quoted. testProof, verbatim:

> Optional pin, runnable under scripts/gate.sh: in app/test/home_screen_test.dart, inside the maker-suggestion group after mounting a card, assert `expect(tester.widget<Text>(find.text('Maker suggestion · advisory')).style!.color, VistaColors.textPrimary);`. It fails against the current code (color is VistaColors.accent 0xFF5AA6DE) and passes after the edit. Without it nothing in the suite reaches the colour; the existing test at line 2869 only checks hit-testability.

Red output, verbatim from the writer:

```text
The following TestFailure was thrown running a test:
Expected: Color:<Color(alpha: 1.0000, red: 0.9608, green: 0.9529, blue: 1.0000, colorSpace:
ColorSpace.sRGB)>
  Actual: Color:<Color(alpha: 1.0000, red: 0.3529, green: 0.6510, blue: 0.8706, colorSpace:
ColorSpace.sRGB)>

This was caught by the test expectation on the following line:
  file:///home/alex/VistaColosseum/.worktrees/br-2026-10-04-p0-queue/app/test/home_screen_test.dart line 2893
The test description was:
  Trade this opens the ticket on the suggestion's asset and side
00:01 +0 -1: maker suggestion Trade this opens the ticket on the suggestion's asset and side [E]
00:01 +0 -1: Some tests failed.
```

## What the fixes now reject

All five adjudicator `rejectsValidInput` answers are none, so no fix rejects valid input. Verbatim:

- **F1:** none. It is a new test and changes no production code. It sets Scenario.clock.value only inside the test, and the file-level setUp restores it. No gate or validator is tightened, so no documented procedure produces input it would now refuse.
- **F2:** none. The change is a test that moves the clock, which setUp restores via Scenario.reset (scenario.dart:266). No production gate changes.
- **F3:** none. The layout test now requires the reference/expiry line to be hit-testable on every phone at 1.0x and 1.3x, and the dry run passed on all of them. The comment edit changes no behaviour.
- **F4:** none. FeedOrderTicket is the only thing the card's onTrade opens (home_screen.dart:89 `onTrade: () => showFeedOrderTicket(`), and an expired card must open nothing (spec 05 Acceptance: "expired → confirm unavailable"). No correct state shows a FeedOrderTicket after tapping Expired.
- **F5:** none - this is a colour token swap on one static label; it accepts and rejects no input. Checked: VistaTag's own default textColor is already VistaColors.textPrimary (vista_chips.dart:40), so the edit uses an existing token and an existing pairing; no document describes producing an accent-coloured badge label.

Nothing in the fixer run executed a rejected input. The only state the new tests write is `Scenario.clock` inside F1's test, and the file-level `setUp` restores it through `Scenario.reset()`.

## Refuted: 0

The skeptic refuted nothing. All six raw findings held against the tree; two of them were merged into F3.

## Checked claims that were wrong: 1

The skeptic's entry, verbatim:

> tautology-hunt: 'The app does not override the platform text scale (no textScaler clamp in lib)' is false. app/lib/main.dart wraps the app in MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3). Their conclusion still holds: 1.3x is the real worst case, so the 1.3x overflow test is meaningful. The layout-semantics lane stated the clamp correctly.

## Residual risk (verbatim)

- tautology-hunt: Did not rerun the full suite or the gate; relied on the stated pass at 87271f1 (251 tests both modes).
- tautology-hunt: Semantics of the live 'Trade this' node are not asserted (only the expired node); no mutant breaks only the live node's semantics.
- tautology-hunt: Did not verify that onDetails from the suggestion ticket routes to AssetTradeScreen(item.asset); it is unasserted.
- tautology-hunt: The worktree shows ` M baton-runner/br-2026-10-04-p0-queue/log.md` (uncommitted), run bookkeeping outside scope.
- state-truthfulness: Ran no tests; relied on the gate result given in the brief and on reading the code.
- state-truthfulness: FeedOrderTicket initState and other phase-2 internals were not re-audited for store writes on open; relied on the state() equality test and the iter-1 mutants.
- state-truthfulness: Whether the simulation pill's Reset (simulation_indicator.dart:14) can be tapped while the ticket sheet is open; a reset restores the same clock value, so it cannot change the expiry.
- state-truthfulness: Whether the rationale ('SOL leads the majors') stays true as LiveFeed ticks prices during a session; the text is static and hedged.
- layout-semantics: Did not run flutter test or a fresh probe; overflow and semantics geometry rely on the passing suite plus the iter-1 probe log, cross-checked against the source.
- layout-semantics: Landscape, tablet sizes and text scales between 1.0 and 1.3 are not on the device list and were not checked.
- layout-semantics: Mid-swipe PageView frames (page partly under the nav or pill) were not examined; only settled pages are tested.
- layout-semantics: Real-device screen-reader activation (TalkBack/VoiceOver fallback when a node has no tap action) was not exercised.
- layout-semantics: Contrast of pre-existing tokens used unchanged (VistaType.meta textSecondary on surface, enabled primary button white on accent at 2.64:1) is a design-system matter outside this diff.

## Verification after the fixes

finding-fixer verification (`scripts/gate.sh baton-runner/br-2026-10-04-p0-queue/gate-phase-5-fixer/`), verbatim:

```text
=== gate: flutter-analyze: flutter analyze ===
PASS flutter-analyze
=== gate: flutter-test: flutter test ===
PASS flutter-test
=== gate: pubspec-frozen: git diff --exit-code c95349cc2a9a40be16d4bddee74c512129ac0114 -- pubspec.yaml pubspec.lock ===
PASS pubspec-frozen
----
GATE: PASS
exit=0
(flutter-test.log tail: 00:39 +252: All tests passed!; flutter-analyze.log tail: No issues found! (ran in 0.8s))
```

Full gate after commit (`baton-runner/br-2026-10-04-p0-queue/gate-phase-5-close/`):

GATE: PASS exit 0 at d935436, 252 tests, HAS_MARKET=true 252
