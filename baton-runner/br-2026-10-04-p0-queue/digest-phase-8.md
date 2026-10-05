# Phase 8 digest: empty and failed states (spec 08), LAST phase: queue handoff — MERGE-WITH-FIXES met at 289ec88 (7 confirmed incl. 1 before-merge HIGH, 7 applied; gate PASS 289, HAS_MARKET 289)

## Public surface
- `VistaEmptyState({message, detail?, actionLabel, onAction})` (`design_system/components/vista_empty_state.dart`, exported): one short line, optional muted hint, one `VistaPillButton`; tokens only; sits inside the list.
- Call sites: Home feed "No calls to show"; Arena "No battles on “<q>”" → Clear search and crowd split → Show all; Positions; Open orders; Receipts calls ("No call receipts for <author> in fixture-v1") and paper; Ledger; Followers/Following; Profile CALLS ("No call receipts for <handle> in fixture-v1", F1); Explore failed state. Others act "Explore markets" = `AppShell.showExplore(context)` (pop to root, tab `AppShell.explore = 1`).
- `Scenario.marketsLoadFails` (`ValueNotifier<bool>`, seed false, `reset()` clears it; in `state()`/`mutateEverything()`). Read only by `MarketsScreen` and Settings.
- Settings "Simulate load failure · Explore markets list" `VistaSwitch` row directly after Reset demo (`settings_screen.dart:127-136`); no toast.
- Explore: `IndexedStack` (0 = "Couldn't load markets" + hint → Retry sets the flag false; 1 = the list) keeps the list's scroll offset (F7). No spinner anywhere. `HomeScreen.feed` is a test seam.

## Carried forward for the user (phases 1-8, one line each)
- P3 F1 MEDIUM, design call: pill tap target 30 px < 44. Raise the 30 px slot to 44, or gap the 5 flush footers 14 px (make_market_flow:138, chart_sheet:255, your_market_screen:137, opinions_screen:181, position_sheet:97).
- P1 M (P2 L-5): LiveFeed drifts after reset; `resetDemo` does not rebase it, so the Wallet change line and chart drift under the exact cash headline.
- P4: Arena sort chip-label order (Change↔Funding in `ArenaMock.sorts`) is unpinned. P4 L2: joins count fills, not people.
- P5: Maker "Trade this" ticket prices at the live mark, not the suggestion's reference price (PRD VC-ORD-001).
- P8 question: should Home's Following tab filter by `Scenario.followed`? Today both tabs show `homeFeed`, so the Home empty state is unreachable in the app.
- P2 M-1 MEDIUM: feed `_parseCents` wraps int64 for 17-18 digit amounts. P2 L: lenient feed parse; wrong-side TP/SL accepted; 4 stale scenario.dart doc comments.
- P2 user questions: invented TP/SL on fills with exits off (M-3); rule-2 waiver for double-dollar sizing; store-owned leverage cap; "Portfolio balance" label on a cash-only figure.
- P2 author items: double tap on Place skips review (M1); feature→`app_shell.dart` import cycle (M6; P8 added 5 importers); store builds presentation (M7).
- P1 L: "Logged out (simulated)" toast mutates nothing; the user can follow herself.
- P3: pill below the nav capsule (L9, sign-off); make-market step 1 overflows 20 px at 1.3x on 360x640/375x667 (N2).
- P5 L5: `homeFeed` is `List<Object>` read with `item as TradeIdea`; a third page kind crashes.
- P5 L6 + P8 refuted: `VistaPillButton`/`VistaPrimaryButton` semantics expose no tap action (excludeSemantics); design-system a11y fix, check `VistaSwitch` too.
- P6: trader-market "All receipts ›" 14 px tap target; receipt id not shown; fixture dates (SOL $300 Right while SOL marks $214.90).
- P7: share card synthesises a record (VC-FED-003 residual); Markets Traders rows hard-code counts; nara private yet has a trader market; panel below the fold on small phones; Figma 303:102 arena section gone.
- P8: own Receipts with both sections empty shows two "Explore markets"; Explore "No matches" has no Clear search; follow tab counts are `FollowMock` constants; record-panel note left unstyled.

## Deliberately not built
- VC-DEM-004 persona switch (gated O-06) and scenario-phase advance (gated O-10; VC-REC-003, VC-ARN-006). Never mark Built.
- Waiting: VC-DEM-001, VC-QA-001, VC-QA-003, VC-QA-004 (O-04, O-01); VC-MKT-001 (O-05). Not taken on: VC-FED-001/002, VC-LST-001/003/004, VC-ARN-001.

Records: `docs/reviews/2026-10-04-dw-review-phase-8-list-empty-failed-states.md`, `review-phase-8-dw.json`, `fixer-phase-8.json`, closing baton in `baton-pass/br-2026-10-04-p0-queue/`.
