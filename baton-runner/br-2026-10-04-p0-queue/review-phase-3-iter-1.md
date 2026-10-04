# Multi-Agent Review: spec 03-simulation-indicator — phase 3, iteration 1 (5 files at 21092df)

## Executive Summary
Six reviewers checked the phase-3 simulation pill (`main.dart`, the new `simulation_indicator.dart`, `settings_screen.dart` and two test files) against spec 03, both digests and the work baton. Most of them measured against a phase-2 baseline in scratch copies. The core design holds: every bar, sheet and route honours `padding.bottom`, the pill's text is true, the pubspec is frozen and VC-DEM-004 was not built. One HIGH regression breaks it: the 30px strip makes the non-scrolling leverage sheet overflow, and its "Set Nx" button can't be tapped at 1.3x text on 360x640 and on the spec's own 375x667. Four of the five severity-using reviewers raised it. The gate missed it because the per-size ticket tests mount a bare `MaterialApp` without the pill. Reset-from-anywhere also leaves stale sheets on screen, with the confirmation toast hidden behind them.

The counts are raw and unchallenged, because refutation was off: 0 CRITICAL, 1 HIGH, 7 MEDIUM, 20 LOW. The HIGH cap of 8 was not reached, so nothing was demoted. Recommended action: fix the leverage sheet and route the layout tests through the app builder before merge, and address the reset-to-root issue in the same pass.

## Critical Findings
None.

## High Findings

**H1. The leverage sheet overflows with the 30px strip, and "Set Nx" can't be tapped at 1.3x on 360x640 and 375x667**
- **Location:**
  - `app/lib/features/trade/order_ticket.dart:1121-1144`: `_LeverageSheet` is a non-scrolling `Column` with bottom padding `24 + safe`.
  - It opens without `isScrollControlled` at `order_ticket.dart:571` ("Cross · Nx") and `feed_order_ticket.dart:153` (feed "custom"), so the sheet is capped at 9/16 of the screen height.
  - The strip comes from `simulation_indicator.dart:69-72`.
- **Description:** `safe` now includes the 30px slot, so the capped sheet loses 30px of room. Measured with `VistaColosseumApp` against the phase-2 baseline:

  | Size / text | Overflow (phase 2 → phase 3) | Set tappable (phase 2 → phase 3) |
  |---|---|---|
  | 360x640 / 1.0x | 0 → 8px (new) | yes → yes |
  | 360x640 / 1.3x | 23 → 53px | yes → no |
  | 375x667 / 1.3x | 7.8 → 38px | yes → no (only the top ~16px responds) |

  The button's centre falls outside the Column's box, which can't be hit-tested, and the pill covers the rest. In the OrderTicket this sheet is the only way to change leverage, so leverage is stuck on these phones. This breaks spec 03 Behavior ("must not cover … action buttons at 375×667 … survives 1.3× text scaling") and AC2 ("no overflow at the smallest viewport"). Sizes 390x844 and up are clean.
- **Suggested fix:** Pass `isScrollControlled: true` at both call sites and wrap the `_LeverageSheet` body in a `SingleChildScrollView` with a max-height cap. Add a test through `VistaColosseumApp` at 360x640 and 375x667 @1.3x that taps Set, asserts the ticket's leverage changed, and checks `takeException()` is null.
- **Raised by:** code-reviewer, mobile-app-developer, tdd-guide, architect-reviewer.

## Medium and Low Findings

| Severity | Title | Location | Reviewer(s) | One-line description |
|---|---|---|---|---|
| MEDIUM | Per-size layout tests skip the pill | `home_screen_test.dart:1838-1855` (`pumpBtc`, used at :1975); `order_ticket_test.dart:37-49` (`openTicket`), :214-241 | code-reviewer, mobile-app-developer, tdd-guide, architect-reviewer | Tests pump `MaterialApp(home: …)` without `SimulationIndicator`, so they measure 30px more room than the app has. Re-run with the builder, "ticket renders without overflow on 360x640" fails with an 8px overflow. Fix: a shared builder/`pumpApp` helper. |
| MEDIUM | Reset from the pill leaves open sheets and routes on pre-reset state | `simulation_indicator.dart:150-158`; `feed_order_ticket.dart:80,262`; `order_ticket.dart:934-956`; `position_sheet.dart:250-263`; `make_market_flow.dart:836`; `your_market_screen.dart:39-43` | code-reviewer, mobile-app-developer, tdd-guide, silent-failure-hunter, architect-reviewer | Measured after reset: the feed ticket shows old cash, the filled panel says "Order filled" with a live "View in Wallet", the position sheet toasts "updated (simulated)" for a deleted position, and make-market says "Your market is open" while `hasMarket` is false. No wrong store write was found. This strains rule 3. Fix: pop to root on reset. |
| MEDIUM | "Demo reset to fixture-v1" toast is hidden under any open sheet | `simulation_indicator.dart:12-16` | mobile-app-developer, silent-failure-hunter, architect-reviewer (code-reviewer: LOW) | The snackbar renders in the page Scaffold under the modal. It exists but has `hitTestable=0`, and the modal barrier keeps it out of the semantics tree, so the user gets no confirmation. Fixed by pop-to-root. |
| MEDIUM | Pill tap target is 30px tall, under the 44px token | `simulation_indicator.dart:36, 76-114` | code-reviewer, mobile-app-developer (tdd-guide, architect-reviewer: LOW) | `iOSTapTargetGuideline` fails (138.9×30). Outside Settings, the pill is the only way to reach the note and Reset. Contrast passes at about 5.0:1. |
| MEDIUM | Pill position (safe area) and keyboard rise are untested | `simulation_indicator.dart:81`; tests at `home_screen_test.dart:2292-2395` | tdd-guide, mobile-app-developer (code-reviewer, architect-reviewer: LOW) | The `bottom: 0`, top-of-screen and no-`viewInsets` mutants all survive 219/219. "Respects safe area" and "above the keyboard" are unguarded. |
| MEDIUM | `viewPadding` reserve is untested, and the harness can't model it | `simulation_indicator.dart:71`; `phones`/`launch` helpers set `padding` but not `viewPadding` | tdd-guide, architect-reviewer | The no-`viewPadding` mutant survives. With padding 34 and viewPadding 0 (impossible on a device), the harness shows snackbars under the pill at 390x844. Fix: set `viewPadding` in the helpers and add a snackbar-clearance test. |
| MEDIUM | No test detects a pill that no longer fits its slot at 1.3x | `home_screen_test.dart:2331-2344`; `simulation_indicator.dart:36` | tdd-guide | The `slot = 16` mutant passes all 219 tests because the text clips silently. The current value fits (17px text, 25px Material, 30px slot). |
| LOW | `expectPillClear(… .hitTestable())` blind spot | `home_screen_test.dart:2363, 2377, 2391` | code-reviewer (mobile-app-developer, inside a MEDIUM) | `hitTestable()` drops any target whose centre the pill covers, so a covered field vanishes from the check instead of failing it. |
| LOW | Bottom buttons sit flush on the pill; fallback branches are dead | `chart_sheet.dart:255`, `position_sheet.dart:97`, `make_market_flow.dart:138`, `opinions_screen.dart:181`, `your_market_screen.dart:137` | mobile-app-developer, architect-reviewer | `bottomInset` is always ≥30, so the 16/30/34 fallbacks never run. The gap between button and pill is 0px everywhere, and the position sheet's margin shrank from 34 to 30. |
| LOW | Reset is easy to trigger by accident | `simulation_indicator.dart:143-157` | mobile-app-developer | Reset is 2 taps from any screen, as the note's primary button, with no confirm, undo or prominent Cancel. |
| LOW | Feed ticket Limit CTA opens half under the pill at 360x640 | `feed_order_ticket.dart:200-207` | architect-reviewer | 25px overlap that needs 41.2px of scroll to clear (11.2px before). It can be scrolled clear, but it is the sheet's main action. |
| LOW | Floating snackbars overlap the pill while the keyboard is up | `simulation_indicator.dart:76-81` with `scaffold.dart` `minViewPadding` | mobile-app-developer, architect-reviewer | Scaffold zeroes `minViewPadding.bottom` when the keyboard is open, so the pill covers part of the snackbar text. The doc comment overclaims. |
| LOW | Keyboard-open overflow behind the feed ticket grows by 30px | `trade_idea_card.dart:59` | code-reviewer, mobile-app-developer, tdd-guide | Home card overflow goes 73→103px at 360x640 and 22→52px at 375x667, plus a new 12px at 390x844. It is hidden behind the sheet, but debug builds draw stripes. |
| LOW | A swipe that starts on the pill is swallowed | `simulation_indicator.dart:91` | mobile-app-developer | The opaque detector wins the hit test, so a list never sees a scroll that starts on the pill. |
| LOW | Pill accessibility gaps | `simulation_indicator.dart:82-113` | code-reviewer, mobile-app-developer, architect-reviewer | No `Focus`, so keyboard/switch users can't reach it. It stays in the semantics tree outside open modals. Its label has no hint. |
| LOW | Spec deviation: pill sits below the nav, not above it | `simulation_indicator.dart` / `main.dart` builder | code-reviewer | Disclosed in the baton with a reason, but product/design hasn't signed off. |
| LOW | Static navigator `GlobalKey` | `main.dart:14` | code-reviewer, architect-reviewer | Two mounted `VistaColosseumApp` instances would throw a duplicate-GlobalKey error. Hold the key in a State. |
| LOW | Settings and simulation features import each other | `settings_screen.dart:8` ↔ `simulation_indicator.dart:5` | architect-reviewer | `resetDemo` coordinates the store, settings and a toast from a widget file. Move it to `reset_demo.dart`. |
| LOW | Undo-after-reset guard is untested | `simulation_indicator.dart:13` (`hideCurrentSnackBar`); `portfolio_screen.dart:35-49` | silent-failure-hunter | With the hide removed, Undo writes a wiped order into the fresh fixture, and the suite still passes 219/219. |
| LOW | Double-open guard is untested | `simulation_indicator.dart:48` | tdd-guide | The no-`_open`-guard mutant passes and stacks 2 notes. |
| LOW | Screen-reader activation is untested | `simulation_indicator.dart:88` | tdd-guide | Removing the Semantics `onTap` passes 219/219. |
| LOW | Make-market pill tests cover step 1 only | `home_screen_test.dart:2381-2393` | tdd-guide | The 375x667 variant passes even with the strip removed, because the footer already pads 30px. |
| LOW | AC3 label is asserted once, without the pill | `order_ticket_test.dart:117`; `order_ticket.dart:976` | tdd-guide | Nothing pins the label in the filled or failed states. |
| LOW | A failing pill test can leak SettingsState | `scenario_test.dart:93, 136-162` | tdd-guide | `setUp` resets only Scenario. Add `SettingsState.reset()`. |
| LOW | Baton's `scrollUntilVisible` explanation is inaccurate | work baton, "Verification" | tdd-guide | The row is built but offstage, not outside the cache extent. The tests themselves are fine. |
| LOW | "Nothing leaves this device" has user-triggered clipboard exceptions | `share_call_sheet.dart:61`; `settings_screen.dart:97` | silent-failure-hunter, architect-reviewer | OS clipboard sync (Universal Clipboard, cloud keyboards) can carry copied text off the device. Nit; optional wording "Nothing is sent anywhere". |
| LOW | "fixture-v1" names two different seeds | `scenario.dart:19-22, 220-236` | silent-failure-hunter | `HAS_MARKET=true` changes the seed, but the label and toast still say fixture-v1. Pre-existing nit. |

## Coverage Report
Reviewers: 6/6 returned
Reviewed at: 21092df3ed0e754ddfb66f8cd045c6b1262ba2b8
Any commit after this one is unreviewed.

No reviewer is tagged `[DID NOT ENGAGE]`: all six have substantive Confirmed lists. silent-failure-hunter left the coverage, Q5 and Q6 lanes to the others.

**Confirmed:**
- **Run-wide rules:**
  - The pubspec is frozen: 0 diff lines in `pubspec.yaml`/`pubspec.lock` (all six).
  - The only new `double` is the layout `slot` (critical-thinking, code-reviewer, architect-reviewer).
  - No persona switch or phase advance exists, by grep (critical-thinking, code-reviewer, tdd-guide, architect-reviewer).
  - Reviewers report the worktree untouched; HEAD is still 21092df (all).
- **Pill label** reads `Scenario.fixtureVersion` (`simulation_indicator.dart:62`) (all).
- **Note sentence** matches spec 03 exactly (critical-thinking, code-reviewer, silent-failure-hunter, architect-reviewer).
- **"Nothing leaves this device" holds for app code:**
  - No `http`, `Image.network`, `HttpClient` or url_launcher.
  - `flutter_svg` is the only dependency, with asset SVGs only, and fonts are bundled.
  - The release AndroidManifest has no INTERNET permission (silent-failure-hunter, architect-reviewer).
  - Raised by all.
- **Reset toast is truthful:** it fires after `Scenario.reset()` and `SettingsState.reset()`. Settings and the note share the single `resetDemo` path, which resolves the phase-1 "split reset handler" carried item. Mutating out either reset fails the tests (code-reviewer, silent-failure-hunter, architect-reviewer, tdd-guide, critical-thinking).
- **Bottom insets:**
  - Every bar, sheet and route pads by `MediaQuery.paddingOf(context).bottom`.
  - There is no `removePadding`, `bottomNavigationBar`, FAB, dialog or `DraggableScrollableSheet`.
  - `_LeverageSheet` is the only non-scrolling capped sheet (code-reviewer, mobile-app-developer, architect-reviewer).
- **Coverage sweep:**
  - It covered all six sizes at 1.0x and 1.3x: every tab, pushed route, sheet and make-market step, plus the note.
  - At scroll end, no interactive control sits under the pill, except H1. Nav gap is 6.0px at all sizes (critical-thinking, mobile-app-developer, architect-reviewer; code-reviewer at 3 sizes).
  - The pill stayed hit-testable on top in all 534 scans (mobile-app-developer).
- **Baseline diff:** the only new overflow exceptions versus phase 2 are the leverage-sheet ones. Explore Traders (6px), ticket rows (right) and make-market create (20px bottom) at 1.3x are pre-existing (architect-reviewer, critical-thinking, code-reviewer).
- **Keyboard open:** all ticket and make-market fields stay clear of the pill at all six sizes, and the pill sits directly above the keyboard (code-reviewer, tdd-guide, mobile-app-developer, architect-reviewer).
- **Snackbars:** with a realistic `viewPadding` and the keyboard down, floating snackbars sit above the pill (code-reviewer, mobile-app-developer, architect-reviewer, tdd-guide).
- **Pill guards and fit:**
  - The re-entrancy guard holds: a second tap keeps one note (code-reviewer, silent-failure-hunter, tdd-guide).
  - The pill fits its slot at 1.3x: 17px text in a 25px Material in the 30px slot (tdd-guide).
  - Contrast is about 5.0:1, AA (code-reviewer, mobile-app-developer).
- **No wrong store write after reset:**
  - `placeOrder`/`_problem` re-check the live store, filled panels show no Confirm, and cash only goes down via `placeOrder`.
  - `hideCurrentSnackBar` clears pending Undo and "View in Wallet" snackbars (code-reviewer, silent-failure-hunter, architect-reviewer, mobile-app-developer).
  - Settings, follow lists, profiles, favorite stars, Edit favorites and Portfolio listen to the store and refresh on reset (silent-failure-hunter).
- **New tests are real (tdd-guide's table, corroborated by critical-thinking, code-reviewer and architect-reviewer):**
  - Kills: revert 7, no-reserve 8, slot=0 7, below-navigator 7, home-only 4, note-changed 1, no-settings-reset 2, no-scenario-reset 2, no-pop 1, toast-changed 2.
  - The AC3 blank mutation fails "double tap confirm places one position" (tdd-guide, mobile-app-developer, architect-reviewer).
- **Q5:** the `ensureVisible` → `scrollUntilVisible` edits keep the trailing `hitTestable` assertion. Reverting them fails with "Bad state: No element", not an overflow. This is an accommodation, not a weakening (critical-thinking, code-reviewer, mobile-app-developer, tdd-guide, architect-reviewer).

**Examined, inconclusive:**
- **Real-device keyboard behaviour:** the engine reporting `padding.bottom = 0` while the keyboard is up, the frames during keyboard animation, and Android edge-to-edge. Blocker: probes emulated this with `FakeViewPadding` and no device (critical-thinking, code-reviewer, mobile-app-developer, tdd-guide, architect-reviewer).
- **VoiceOver/TalkBack traversal** while a modal is open with the pill outside the navigator. Blocker: semantics-tree inspection only (critical-thinking, mobile-app-developer, architect-reviewer, tdd-guide).
- **`_showNote` has no try/finally:** a synchronous throw would leave `_open` stuck and the pill dead. Blocker: no reachable trigger; needs fault injection (silent-failure-hunter).
- **LiveFeed rebuild on a device:** OrderTicket may refresh its cash-derived values from price ticks, but the feed ticket has no listener. Blocker: `FLUTTER_TEST` disables LiveFeed (silent-failure-hunter).
- **Real-world rate of accidental taps** on flush buttons. Blocker: needs a device trial (architect-reviewer).
- **Position-sheet "updated (simulated)" toast after reset:** code-reviewer's probe did not surface it after one pump. silent-failure-hunter's probe did measure it (present=1), so the claim stands.

**Not examined (residual risk):**
- Landscape orientation, which is allowed by Info.plist and the Android manifest. critical-thinking raised it as an assumption, but no one measured it.
- Tablet sizes and other Android nav-bar inset shapes.
- Web and desktop targets, and iOS/Android runner configuration beyond the manifest permission check.
- Text-selection handles and the magnifier near the pill.
- Golden/visual appearance of the pill over each scrim colour.
- The `HAS_MARKET=true` variant beyond the caller's +219 pass, apart from the label naming.
- ARCH.md and STATE edits in the phase, and the gate logs themselves (the caller established the gate).
- `signal_replay_chart.dart` painting and `vista_*` component internals beyond their bottom padding.
- LiveFeed drift after reset (carried, out of scope).

## Unstated Assumptions and Open Questions (from critical-thinking)
- **Core assumption:** honouring `padding.bottom` is enough. It is not for height-capped, non-scrolling sheets, which is the leverage-sheet regression (matches H1). At 360x640/1.3x, a tap on the Set button's centre opens the pill's note and leaves the sheet open.
- **The overflow guard never mounts the pill** (matches the MEDIUM on per-size layout tests). The five `bottomInset > 0 ? … : fallback` branches now run only in tests.
- **Stale UI after reset** (matches the MEDIUM on stale UI). Also reported: `YourMarketScreen` stays labelled "· your market" while `hasMarket` is false.
- **Reset sits where Long was.**
  - The note's full-width Reset button (375x667: y 567–621; 390x844: y 710–764) overlaps the band where the Long/Short buttons were (591–637 and 734–780).
  - A user who misses Long and taps again in the same spot wipes the session.
  - Needs a design decision: confirm or undo, a secondary style, or spacing.
- **Keyboard open:** in the OrderTicket at 375x667 with a 260px keyboard, the pill covers the centre of "Place market long" (376–407 against 377–407) until the user scrolls. At baseline it was tappable. This meets the "scroll clear" rule but hides the primary action at the moment it's needed.
- **Mutation gaps:** `bottom: 0`, ignoring `viewInsets`, no `viewPadding` reserve, `slot = 20` and removing the `_open` guard all survive. The `hitTestable` finder hides covered targets, and the harness omits `viewPadding`.
- **1.3x evidence covers tabs only.** The tickets already overflow to the right at 1.3x (38/32px at 360x640) and make-market create overflows 20px at the bottom, both identical at baseline. Is AC2 met in spirit, given the leverage sheet now overflows at 360x640/1.0x?
- **Design deviation:** the pill sits below the nav, over every sheet, and is not dimmed by scrims. A top placement or per-surface placement was not considered. Needs design sign-off.
- **Accessibility:** besides the 30px target, no Focus and escaping modal semantics, the pill still announces itself as a button while the note is open, but a tap then does nothing.
- **Truthfulness:** is "fixture-v1" the dataset's name or a claim about current state? After trading and LiveFeed drift (carried), the persistent label and the "reset to fixture-v1" toast read as an ambient claim about prices. Clipboard sync is a caveat to "Nothing leaves this device".
- **Smaller assumptions:**
  - The static navigator key.
  - Landscape is allowed, and the strip costs more there.
  - The baton's "Decisions phases 04–08 must honour" should add three items: capped sheets lose 30px, layout tests must mount the pill, and the harness must set `viewPadding`.
- **Q5 wording:** the change at :1264 is in the shared `openPosition` helper, so it affects every position-sheet test at every size, not only 360x640.

## Reviewer Disagreements
- **Tap-target severity and fix direction.**
  - Severity: code-reviewer and mobile-app-developer rate it MEDIUM; tdd-guide and architect-reviewer rate it LOW. architect-reviewer notes it meets WCAG 2.5.8 AA (24px).
  - Fix: architect-reviewer (L3) suggests *shrinking* the hit box to the visible pill to avoid mis-taps. The others want a 44px target. code-reviewer warns against extending it upward; mobile-app-developer suggests extending it downward into the system inset.
  - **Resolution:** keep MEDIUM. Extend the hit area downward into `padding.bottom` where a system inset exists. Where there is none, design chooses between `slot = 44` and an accepted deviation. Never extend it upward over content.
- **Toast hidden under sheets:** code-reviewer rates it LOW; three others rate it MEDIUM. **Resolution:** MEDIUM. It is the only confirmation of a destructive global action, and the same pop-to-root change fixes it anyway.
- **Order of operations for the reset fix:**
  - mobile-app-developer: pop, then `resetDemo`.
  - architect-reviewer: pop, reset, toast.
  - code-reviewer and tdd-guide: `popUntil` inside `resetDemo` after the reset.
  - silent-failure-hunter: popping does not remove the snackbar, so keep `hideCurrentSnackBar`.
  - **Resolution:** in `resetDemo`, capture the root `ScaffoldMessenger` first, then `popUntil(isFirst)`, reset, hide the current snackbar and show the toast. The note's context is unmounted after the pop, so capture the messenger before it.
- **Clipboard and "Nothing leaves this device":** mobile-app-developer lists clipboard writes as staying on the device; silent-failure-hunter, architect-reviewer and critical-thinking note OS clipboard sync. **Resolution:** the sentence is true for the app's own code, and sync is OS behaviour after an explicit user action. LOW nit, optional rewording.
- **Platform channels:** architect-reviewer says there are none; code-reviewer notes haptics and clipboard use them. **Resolution:** code-reviewer is right. Both are local-only, so the network conclusion stands.
- **Baton's Q5 explanation:** tdd-guide says the row was built but offstage, not outside the cache extent. critical-thinking says the :1264 change affects all sizes. Both agree the tests are not weakened. **Resolution:** correct the baton wording only.

## Recommended Changes (Prioritized)
1. Pass `isScrollControlled: true` at `order_ticket.dart:571` and `feed_order_ticket.dart:153`, and wrap the `_LeverageSheet` body in a capped `SingleChildScrollView` (H1).
2. Add a leverage-sheet test through `VistaColosseumApp` at 360x640 and 375x667 @1.3x that taps Set and asserts leverage changed, with no exception.
3. Expose the app builder (for example a static `VistaColosseumApp.builder`) and route `pumpBtc`, `openTicket` and the order-ticket review loop through a shared `pumpApp` helper.
4. Set `tester.view.viewPadding` alongside `padding` in every `phones`/`launch` helper.
5. In `resetDemo`, capture the messenger, `popUntil(isFirst)`, reset both stores, hide the current snackbar and toast. Then add a test that resets over a filled ticket and asserts the ticket is gone and the toast is hit-testable.
6. Add the tests the surviving mutants call for:
   - The pill's bottom equals `H - padding.bottom` on 390x844.
   - A keyboard case: the pill's bottom equals the keyboard top.
   - The pill's Material height is at most `slot` at 1.3x.
   - Snackbar clearance with `viewPadding` set.
   - A two-tap double-open check.
   - The semantics tap opens the note.
   - Undo is hidden after reset.
7. Change `expectPillClear` to take overlap rects from plain finders and assert `hitTestable` separately.
8. Replace the dead `bottomInset > 0 ? … : fallback` branches with `bottomInset + gap`, or a gap built into `slot`, once design picks the spacing.
9. Get design sign-off on: the pill below the nav, the 30px tap target, a confirm or undo on Reset, and the 0px button gap.
10. Clean up the nits:
    - Add `SettingsState.reset()` to the scenario `setUp`.
    - Move the navigator key into a State.
    - Move `resetDemo` to its own file.
    - Fix the keyboard-up snackbar doc comment.
    - Correct the baton's Q5 wording.
    - Amend the digest's 04–08 conventions: capped sheets lose 30px, layout tests mount the pill, the harness sets `viewPadding`.

## Open Questions for the Author
- Should a reset from Settings also pop to root, closing Settings itself, or should only the note's Reset do that?
- For height-capped sheets: make them scroll-controlled, or exclude the 30px reserve inside sheets?
- Is a 30px pill target acceptable, or should the strip grow (14px more on every screen) or extend its hit area into the system inset?
- Should Reset get a confirm or undo step, given it now sits 2 taps from any screen and lands where Long/Short were?
- Is "fixture-v1" the dataset's name or a claim about current state? Should `HAS_MARKET=true` show a different label?
- Is landscape supported? If not, should orientation be locked?
- With the keyboard up, is it acceptable that the pill covers "Place market long" (until scroll) and part of snackbars, or should tickets add `slot` while `viewInsets.bottom > 0`?
- Does AC2 count as met while the 1.3x make-market create step overflows by 20px (pre-existing)?
- Keep "Nothing leaves this device", or switch to "Nothing is sent anywhere"?

## Notes
- No reviewer failed to spawn or returned empty. The one degraded lens slot: L-LANG:dart has no agent in the pool and degraded to code-reviewer (see the roster bullet below).
- Roster came from context-aware selection: L-ADVERSARIAL → critical-thinking; L-BASELINE → code-reviewer (also owned Dart/Flutter idiom, because L-LANG:dart has no agent in the pool and degraded to it); L-MOBILE → mobile-app-developer; L-TEST → tdd-guide; L-RESILIENCE → silent-failure-hunter; L-ARCH → architect-reviewer. No real-world risk flag fired (simulated money, no keys, no external I/O), so no security or red-team lane was selected; the "Nothing leaves this device" claim was checked by every reviewer under mandatory check (b).
- All six reviewers and the synthesizer are parked agents (~/.claude/agents-parked/). They ran by the paste method as general-purpose subagents, with the first paragraph of each agent body as the role plus a one-line lane assignment, explicit read-only prohibitions, on the orchestrator's model.
- Per-reviewer recovery checkpoints under `.claude/reviews/<slug>/` were not written, because containment allowed writing only the report file.
- Containment disclosures from the reviewers themselves: critical-thinking created its first probe file with the Write tool inside the session scratchpad copy (outside the repo), although its brief forbade calling Write. critical-thinking and silent-failure-hunter each report that their first `flutter test` in a scratch copy ran Flutter's implicit pub resolve, which may have contacted pub.dev; later runs used `--no-pub`. All probes lived under the session scratchpad, outside the repo. The orchestrator confirmed after all reviewers returned that `git -C <root> status` shows only the caller's two pre-existing untracked paths and HEAD is still 21092df.
- Refutation (`--adversarial`) was off, so all finding counts are raw and unchallenged.
- `--high-cap` is 8 (effective cap min(8, ceil(6 × 1.5)) = 8).

## Report Audit

1. **Confirmed list credits a check to reviewers who never reported it (class 6)**
   - Report, Coverage Report → Confirmed → Run-wide rules: "Reviewers report the worktree untouched; HEAD is still 21092df (all)."
   - Source: tdd-guide's Validated section covers only "pubspec.yaml and pubspec.lock diff is 0 lines; no money code in the diff; no persona or phase-advance code (grep)". It says nothing about the worktree or HEAD.
   - architect-reviewer's Validated section also makes no worktree or `git status` claim. It says only "I ran probes in a scratch copy of the app."
   - critical-thinking is the only reviewer that names "HEAD 21092df". The orchestrator's own check appears separately in Notes ("The orchestrator confirmed after all reviewers returned…"). Crediting the check to "(all)" overstates it.

2. **A Confirmed entry is contradicted by the report's own LOW row and by measured source data (class 5)**
   - Report, Confirmed → Baseline diff: "the only new overflow exceptions versus phase 2 are the leverage-sheet ones."
   - Report's own LOW row "Keyboard-open overflow behind the feed ticket grows by 30px": "…plus a new 12px at 390x844."
   - Source, mobile-app-developer's table (Phase 2 → Phase 3): "390x844 | none | 12px" and "393x852 | none | 16px".
   - Source, tdd-guide: "at 230px it goes from none to 22px".
   - Source, critical-thinking: "a new 3px at 390x844 at 1.3x".
   - The architect-reviewer sweep behind the bullet was the keyboard-closed sweep, but the Confirmed entry carries no "keyboard down" qualifier.

3. **The Executive Summary overstates how many reviewers measured against the phase-2 baseline (class 4)**
   - Report: "Most of them measured against a phase-2 baseline in scratch copies."
   - Source: only critical-thinking ("rebuilt as the phase-2 baseline from `git show phase-2:`"), mobile-app-developer ("an untouched phase-2 copy (`git archive`)") and architect-reviewer ("a phase-2 baseline (exported with `git archive`)") did.
   - code-reviewer measured "with the pill vs without it (bare `MaterialApp` + `AppShell`…)".
   - tdd-guide measured "with the pill vs. the same app without `SimulationIndicator`".
   - silent-failure-hunter ran no baseline.
   - That is 3 of 6, not most.

4. **tdd-guide's fix ordering is misattributed in the Reviewer Disagreements section (class 6)**
   - Report: "code-reviewer and tdd-guide: `popUntil` inside `resetDemo` after the reset."
   - Source, tdd-guide: "Either pop routes to the root before or on reset (for example `navigator.popUntil(isFirst)` in `resetDemo`), or have the live step watch `AccountState.hasMarket` and close when it turns false."
   - tdd-guide did not say "after the reset". It also offered a second option (the live step watching `hasMarket`) that the disagreement entry drops.
   - Only code-reviewer said "after the reset".
