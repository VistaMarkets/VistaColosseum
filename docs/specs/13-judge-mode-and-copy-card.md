# Spec — Simulated pill: judge controls, copy card, web build

**Status:** spec'd 2026-10-12. Base: `main` at `207126a`. Line citations are as of that commit; after a merge, grep the quoted string rather than trusting the number.

## Executive summary

The demo proves its copy loop (creator posts, copier copies, creator earns $5.00) only to someone who runs it on a Mac or Linux box and taps through Settings twice. This spec adds three controls to the sheet the "Simulated · fixture-v1" pill already opens (switch persona, play the copy story to its ledger row, and the pill names who you are acting as), a shareable copy card offered after every copy and from the creator's ledger, and a web build on GitHub Pages so a judge opens a link instead of installing Flutter. Three phases, no new dependencies, every write still goes through `Scenario.placeOrder`.

## 1. Context & Problem Statement

The Flutter demo app in `app/` runs on fixture data with a persistent "Simulated · fixture-v1" pill (`app/lib/features/simulation/simulation_indicator.dart:23-27`). Its copy story (spec 09) has two personas, creator `maya.eth` and copier `sam.sol` (`app/lib/features/portfolio/portfolio_mock.dart:84-92`), switched from a "Demo persona" row in Settings (`app/lib/features/settings/settings_screen.dart:124-137`).

**Observed behaviour today**

- A judge reaches the proof of the loop (the `COPY FEES` row on the creator's ledger, `app/lib/features/market/receipt_screens.dart:125-154`) only by rehearsal steps 33–37 (`docs/verification/rehearsal-protocol.md:45-49`): Wallet → gear → Demo persona → Home → card → ticket → Confirm → gear → Demo persona → Fees from your market. Ten taps across five screens.
- Nothing shareable comes out of a copy. The "Order filled" panel ends at Done / View in Wallet (`app/lib/features/trade/order_ticket.dart:945-957`); the ledger rows are inert text.
- The README offers a Mac or Linux build only (`README.md:44-54`). There is no `app/web/` directory and no hosted build, so a judge without a Flutter install sees only the video.

**Why it matters.** Submission cutoff is 2026-10-12 23:59 America/Los_Angeles. A judge who cannot run the app, or who cannot tell what is real, scores the loop as a mock. The fastest honest fix is to make the real store do the loop in two taps from any screen (the pill, then one button) and give the judge a link.

## 2. Current Architecture

**Files**

- `app/lib/main.dart:36-39` — `MaterialApp.builder` wraps every route in the text-scale clamp and `SimulationIndicator`.
- `app/lib/features/simulation/simulation_indicator.dart` — `resetDemo` (`:11-21`): pops every route, `Scenario.reset()`, `SettingsState.reset()`, toasts. `SimulationIndicator` (`:28-130`) draws the pill and reserves a 30 px strip; tap opens `_SimulatedNote` (`:133-171`), a bottom sheet with one sentence and a `VistaPrimaryButton` "Reset demo" (`:163-166`).
- `app/lib/scenario/scenario.dart` — the one store. `activePersona` (`:157`), `switchPersona()` (`:182-193`), `copyFeeCents()` (`:197-202`), `placeOrder()` (`:378-487`), `reset()` (`:491-515`), `Persona` enum (`:520-527`), `kCopyFeeCents = 500` (`:540`), `copyLine()` (`:543-544`), `OrderIntent` (`:563-634`), `OrderReceipt` (`:638-678`), `OrderResult` (`:681-698`).
- `app/lib/features/settings/settings_screen.dart:124-137` — the "Demo persona" row: `setState(Scenario.switchPersona)` and a toast `'Now acting as ${handle}'`.
- `app/lib/features/trade/order_ticket.dart:839-1010` — `_ReviewPanel`: `_confirm()` calls `Scenario.placeOrder` once (`:858-879`); the result panel's copy line (`:985-993`), "Simulated — no real order" (`:996`), and the Done / View in Wallet buttons (`:945-957`, `:998-1006`). `_toast` (`:801-805`), `_showWallet` (`:808-811`).
- `app/lib/features/market/receipt_screens.dart:58-187` — `LedgerScreen` with `route()` (`:61-62`); copy rows (`:128-153`) print `'${e.eventTitle} · @${e.counterparty} · ${e.asset}'`.
- `app/lib/features/share/share_call_card.dart:24-131` — `ShareCallCard`, a 346×182 link-preview image for a call; `share_call_sheet.dart:13-21` `showShareCallSheet`, `_send` (`:57-75`, Copy link writes the clipboard, everything else toasts "(simulated)"), `_targets()` (`:212-255`, Messages / Telegram / X / Copy link).
- `app/lib/features/live/live_feed.dart:23` — `LiveFeed.enabled => !Platform.environment.containsKey('FLUTTER_TEST')`; `dart:io` imported at `:2`, `package:flutter/foundation.dart` at `:5`.
- `app/lib/features/live/market_prices.dart:12-42` — `MarketPrices.base('SOL') = 214.90`, `now()`, `of()`.
- `app/lib/features/home/home_screen.dart:200-208` — a feed card opens the ticket with `sourceCallId: '${idea.callerHandle}/${idea.ticker}'`.
- `app/lib/features/home/mock_trade_idea.dart:118-139` — the `kilo.sol` SOL long card (`callPrice: 205.30`, `coinAsset: VistaAssets.coinSolRow`).
- `app/lib/app_shell.dart:16-17` — `AppShell.tab` (`ValueNotifier<int>`), `AppShell.wallet = 3`.
- `README.md:36-68` "Run it"; `:90-109` "Known limitations". `docs/specs/README.md:5-19` the spec index.

**Call flow — a copy today.** Home card → `showFeedOrderTicket(sourceCallId, sourceAuthorHandle)` (`home_screen.dart:200-208`) → Review → `_ReviewPanel._confirm()` → `Scenario.placeOrder(intent)` (`order_ticket.dart:861`) → duplicate guard on `actionId` (`scenario.dart:379-385`) → `problem()` (`:386`) → fill: receipt with `copyFeeCents` (`:415-431`), cash debit (`:458`), and, when the active persona is not the creator, one `FeeEntry(kind: copyFee, counterparty: copier handle, asset: symbol)` on the creator's ledger (`:461-479`).

**Data shapes (verbatim)**

- `enum Persona { creator('maya.eth', 'Creator'), copier('sam.sol', 'Copier') }` with `handle`, `label` (`scenario.dart:520-527`; handles from `portfolio_mock.dart:84,91`).
- `OrderIntent({required actionId, symbol, name, side, units, price, leverage, kind = OrderKind.market, icon = VistaAssets.coinPlaceholder, takeProfit, stopLoss, reduceOnly = false, clashId, sourceCallId, sourceAuthorHandle})`; `notionalCents = round(units × price × 100)`, `marginCents = round(notional / leverage)`, `feeCents = notional × feeBps ~/ 10000`, taker `feeBps = 5` (`scenario.dart:563-634`, `trade_mock.dart:71`).
- `OrderReceipt` carries `copyFeeCents` (0 unless a copy), `sourceCallId`, `sourceAuthorHandle`, `symbol`, `name`, `side` (`scenario.dart:638-678`).
- `OrderResult` is sealed: `OrderFilled(receipt)`, `OrderResting(order)`, `OrderFailed(reason)` (`:681-698`).
- `FeeEntry({required id, marketId, eventTitle, amountCents, at, kind = FeeKind.credit, sourceCallId, counterparty, asset})`; `counterparty`, `sourceCallId`, `asset` are `String?` (`market_mock.dart:121-147`). `FeeKind` has `credit` and `copyFee`.
- Copier seed cash `copierCashCents = 100000` (`portfolio_mock.dart:92`). Stale-price seed `{'AVAX'}` (`trade_mock.dart:76`), so SOL is never stale at launch.

**Real vs. mocked.** Everything is simulated by design: prices drift from `MarketPrices._base` (`market_prices.dart:12-24`), the store is in-memory, share targets toast instead of sending. The spec changes none of that. The web build probe (§4) is the one live integration.

**External contracts that must not break**

- The pill's accessibility label starts with `Simulated · fixture-v1` (`home_screen_test.dart:59` finds it by that string).
- `Scenario.placeOrder` is the only write path for money (`scenario.dart:373-378`); `switchPersona` and `reset` touch no financial total.
- The toast after a fill: `'<name> <side> filled · <total> from paper cash (simulated)'` (`order_ticket.dart:870-878`, rehearsal step 27).
- `scripts/gate.sh <log-dir>` prints `GATE: PASS`; the suite passes at 348 tests (`flutter test` on `207126a`, 2026-10-12).

## 3. Root Cause Analysis

### D1 — The proof is ten taps away *(high)*
- Symptom: a judge must follow rehearsal steps 33–37 to see the $5.00 row.
- Mechanism: the only persona switch is a Settings row (`settings_screen.dart:124-137`) and the only copy path is the ticket (`order_ticket.dart:858-879`); nothing composes them.
- Evidence: `docs/verification/rehearsal-protocol.md:45-49`.

### D2 — A copy produces nothing shareable *(medium)*
- Symptom: after "Order filled" the copier can only tap Done or View in Wallet; the creator's ledger row cannot be tapped.
- Mechanism: `_ReviewPanel` offers two buttons (`order_ticket.dart:945-957`); the ledger copy row is a plain `Row` (`receipt_screens.dart:128-153`). The share card that exists takes a `TradeIdea`, not a receipt (`share_call_card.dart:25-27`).
- Evidence: the cited widgets.

### D3 — Judges cannot run the app without a toolchain *(high)*
- Symptom: `README.md:44-54` requires Flutter 3.47 plus Xcode or a Linux desktop.
- Mechanism: no `app/web/` scaffold, no hosted build, and `live_feed.dart:23` would throw on web (`Platform._environment` throws `UnsupportedError` in the dart2js stub, `bin/cache/dart-sdk/lib/_internal/js_runtime/lib/io_patch.dart:281-283`).
- Evidence: `ls app/web` → absent; the probe in §4.

## 4. Design Constraints

**Established empirically (2026-10-12, Flutter 3.47.5 stable, Dart 3.13.4, WSL2)**

- A copy of `app/` with `flutter config --enable-web`, `flutter create --platforms=web --project-name vista_colosseum .`, then `flutter build web --release` compiles in 35 s with no errors and produces `build/web` (43 MB, `main.dart.js` 3.05 MB). Invalidated by: a dependency that pulls `dart:io` into `lib/`, or a Flutter upgrade.
- `flutter create --platforms=web --project-name vista_colosseum --no-pub .` on a copy of `app/` writes 14 files and rewrites two tracked ones: the seven to keep (`web/index.html`, `web/manifest.json`, `web/favicon.png`, `web/icons/Icon-192.png`, `Icon-512.png`, `Icon-maskable-192.png`, `Icon-maskable-512.png`), plus `test/widget_test.dart` (references a `MyApp` that does not exist, so `flutter analyze` fails), five files under `.idea/` and `vista_colosseum.iml` (both gitignored, `app/.gitignore:16,19`); it rewrites `.metadata` (the Linux platform record becomes `web`) and `pubspec.lock`. `index.html` carries `<base href="$FLUTTER_BASE_HREF">`, replaced by `--base-href` at build time. (Adversarial read, 2026-10-12, scratch `create-probe/`.)
- The guarded build (`kIsWeb ||` in `live_feed.dart:23`) renders Home at 1280×800 in headless Chromium with zero console exceptions; the unguarded build throws `Unsupported operation: Platform._environment` and cascades. (Same probe.)
- The existing Share call test taps every target label and Copy link (`app/test/home_screen_test.dart:2812-2827`), so the targets' `Semantics(button: true, label:)` is load-bearing.
- The Flutter web loader accepts `hostElement` (`bin/cache/flutter_web_sdk/flutter_js/src/types.d.ts:64`), so a page can frame the app without Dart changes; it cannot be checked by `flutter test`.
- `grep -rnE "dart:io|dart:ffi" app/lib` returns one hit: `live_feed.dart:2`. `Platform.environment` is the only member used (`:23`).
- `VistaMarkets/VistaColosseum` is public; this account has `admin: true`; GitHub Pages is not enabled (`GET /repos/VistaMarkets/VistaColosseum/pages` → 404). The REST call to create a Pages site takes `source: {branch (required), path}` and `build_type: legacy | workflow` (docs.github.com, REST "Pages", fetched 2026-10-12).
- `flutter test` on `207126a`: 348 tests, all pass.

**Imposed**

- PRD: persistent simulation label, honest confirmations, no keys or financial writes. Every new control goes through `Scenario.placeOrder` or `Scenario.switchPersona`; nothing writes a ledger row directly.
- Oct 12 ruling 1 (`docs/verification/2026-10-12-user-rulings.md`): every copy fee credits `maya.eth`, whoever authored the call. The card states that.
- The store refuses trader-market orders (`scenario.dart:342`, `traderIndexNotBuilt`), so the preset copies an asset call: `kilo.sol`'s SOL long.
- Phase 2 gate decisions (approved 2026-10-12): controls live in the pill's note; one idempotent preset; card text "Copied @kilo.sol · SOL" / "$5.00 copy fee → @maya.eth"; reuse the share targets row by extraction; host by pushing a local build to `gh-pages`.
- Phase 4 answers (user, 2026-10-12): the card's clipboard target copies the card's text without a "Simulated" suffix (Q-1); the hosted page shows a one-time launch toast pointing at the pill, not a caption (Q-2).

### Global constraints

- Flutter `3.47.5` stable, Dart SDK `^3.13.1` (`app/pubspec.yaml:7`). No new entries in `pubspec.yaml`.
- `flutter analyze` clean and `flutter test` ≥ 348 passing, every phase (`scripts/gate.sh <log-dir>` prints `GATE: PASS`).
- The pill's Semantics label begins with the literal `Simulated · fixture-v1`.
- Only `Scenario.placeOrder` changes `cashCents`, `positions`, `receipts` or `feeEntries`.
- Fill toast text unchanged: `'<name> <side> filled · <total> from paper cash (simulated)'`.
- Phone-sized layouts: no `RenderFlex` overflow on 375×667 or 390×844 at 1.3× text scale.

## 5. Target Design

**Pill and note (closes D1).** The pill reads `Simulated · fixture-v1 · <active handle>` and rebuilds on `Scenario.activePersona`. The note gains two `VistaPrimaryButton`s above "Reset demo":

- `Act as @<other handle>` → `actAs(context)`: pops every route (as `resetDemo` does), `Scenario.switchPersona()`, toast `Now acting as <handle>` (same wording as Settings).
- `Play the copy story` → `playCopyStory(context)`: pops every route; switches to the copier if not already; calls `Scenario.placeOrder` with the fixed intent below; on `OrderFailed` toasts the reason and stops (persona stays copier); otherwise switches back to the creator, sets `AppShell.tab.value = AppShell.wallet`, pushes `LedgerScreen.route()`, toasts `sam.sol copied @kilo.sol · $5.00 copy fee credited to maya.eth (simulated)`.

The preset intent, built each play: `OrderIntent(actionId: 'preset-copy', symbol: 'SOL', name: 'Solana', side: TradeSide.long, units: 100 / price, price: MarketPrices.now('SOL'), leverage: 5, icon: VistaAssets.coinSolRow, sourceCallId: 'kilo.sol/SOL', sourceAuthorHandle: 'kilo.sol')`. At the launch price (214.90, no drift under test) it costs margin 2000 + fee 5 + copy fee 500 = 2505 cents, so the copier's cash reads $974.95. The fixed `actionId` makes a second play return the first receipt and write nothing (`scenario.dart:379-382`); Reset demo clears receipts, so it plays again after a reset.

**Copy card (closes D2).** `CopyCard` is a 346×182 image like `ShareCallCard`: Vista mark top-left, `COPIED` tag top-right in `VistaType.micro`/`VistaColors.long`, line 1 `Copied @<author> · <symbol>` (`VistaType.subhead` 16), line 2 `<fee> copy fee → @<creator>` (`VistaType.body` 12), footer `by @<copier> · Simulated` (`VistaType.meta`, `textMuted`). `showCopyCardSheet` shows it over a `ShareTargets` row whose fourth target is relabelled `Copy text`; it writes the card's lines as one string, `Copied @<author> · <symbol> · <fee> copy fee → @<creator> · by @<copier>` (no "Simulated" suffix, by the user's 2026-10-12 answer to Q-1), to the clipboard and toasts `Card text copied`; any other target toasts `Shared to <target> (simulated)`. Entry points: a `Share copy card` link under "Simulated — no real order" on a filled copy, and a tap on any ledger `COPY FEES` row. The creator handle is always `Persona.creator.handle` (ruling 1).

**Web build (closes D3).** `app/web/` scaffold committed; `LiveFeed.enabled` returns `true` on web before touching `Platform`; `VistaColosseumApp(web: bool = kIsWeb)` centres the app in a 390-wide column with the `MediaQuery` size overridden to that width, so every phone layout and bottom sheet stays inside the frame, and shows one launch toast, `Tap the Simulated pill at the bottom to switch persona or play the copy story`, for 8 seconds after the first frame (the user's 2026-10-12 answer to Q-2). Deploy: build with `--base-href /VistaColosseum/`, push `build/web` plus `.nojekyll` to `gh-pages`, create the Pages site from that branch. README's "Run it" opens with the link.

## 6. Decision Records

### DR-1: Judge controls live in the pill's note
- Decision: add "Act as" and "Play the copy story" to `_SimulatedNote`; the pill shows the active handle.
- Context: D1; the note is reachable from every route and sheet (`main.dart:36-39`); the Settings row stays.
- Rationale: one file, zero new navigation, and the pill is where the demo already explains itself.
- Alternatives considered:
  - Leave it as is (Settings row only) — rejected: ten taps, and the Settings row's label is read in `build` without listening (`settings_screen.dart:128`), so it cannot be the global control.
  - A separate "Judge mode" screen or flag — rejected: a flag that changes behaviour is a second thing to explain and to test; the controls are the feature.
  - Long-press on the pill — rejected: undiscoverable without a hint, and the pill's 30 px strip is already a known tap-target gap (`simulation_indicator.dart:41-46`).
- Consequences: the pill label grows by ` · maya.eth`; `home_screen_test.dart:59` switches to a prefix match. The controls are two taps from any screen, not one; a long-press would be one tap but shares the same discoverability problem (risk row in §10, Q-2). "Act as" pops open sheets the way Reset does, so a ticket opened as one persona never confirms as the other.

### DR-2: One idempotent preset through `placeOrder`
- Decision: a single "Play the copy story" that runs the real store with a fixed `actionId`.
- Context: D1; the store already guards duplicates by `actionId` (`scenario.dart:379-385`) and credits the ledger only inside `placeOrder` (`:461-479`).
- Rationale: the ledger row is the proof; running the real write path keeps it honest, and idempotence means a judge tapping twice sees one row, same as the ticket's double-tap guard (rehearsal step 27).
- Alternatives considered:
  - Seed the `copyFee` row directly into `feeEntries` — rejected: a fake row would be the thing the judge is meant to distrust, and it bypasses the only write path (global constraint).
  - Several presets (before-copy review, after-copy wallet, ledger) — rejected: three buttons to explain; the ledger is the result and Wallet is one Back away.
  - Use a fresh `actionId` per play — rejected: a second tap adds a second $5.00 row, which reads as a bug on a judge's screen.
- Consequences: after one play the button writes nothing until Reset demo, and its toast says "Already played" rather than "credited". The preset's `units` are `100 / live price`, so the notional is exactly 10000 cents at any price (`scenario.dart:617,629`): margin 2000, fee 5, copy fee 500 never drift; only the unit count on the receipt does.

### DR-3: The card copies `kilo.sol`'s SOL call and names `maya.eth` as the creator
- Decision: text `Copied @kilo.sol · SOL` / `$5.00 copy fee → @maya.eth` / `by @sam.sol · Simulated`, built from receipt or `FeeEntry` fields, no chart.
- Context: D2; the only `maya.eth` feed card is a trader market (`mock_trade_idea.dart:254-261`) and `placeOrder` refuses those (`scenario.dart:342`); ruling 1 credits every fee to `maya.eth`.
- Rationale: the card says exactly what the store recorded; `FeeEntry` carries `counterparty`, `sourceCallId` and `asset` (`market_mock.dart:145-147`) and the receipt carries `sourceAuthorHandle`, `symbol`, `copyFeeCents`, so both entry points build the same card without a `TradeIdea`.
- Alternatives considered:
  - Copy `maya.eth`'s own feed card, so the card reads "Copied @maya" as the concept asked — rejected: that card is a trader market and `placeOrder` refuses it (`scenario.dart:342`); the card would describe a copy the store cannot make.
  - Reuse `ShareCallCard` with its replay chart — rejected: it needs a `TradeIdea` and the chart painter (`share_call_card.dart:135-140`); the ledger has neither, and the chart says nothing about the fee.
- Consequences: the card exposes the demo's odd economics (kilo.sol's call, maya.eth's fee). Ruling 2 accepts that; the README's "Everything is simulated" bullet already covers it (`README.md:92-94`).

### DR-4: Extract the share targets row and reuse it; the card's fourth target copies text
- Decision: move `_targets()` (`share_call_sheet.dart:212-255`) into `ShareTargets(onSend:, copyLabel: 'Copy link')` in `share_targets.dart`; both sheets use it. The copy sheet passes `copyLabel: 'Copy text'` and puts the card's lines on the clipboard, with no "Simulated" suffix.
- Context: D2; the row is 44 lines of layout with four assets. `vistamarkets.xyz` is the live company site and answers any path with its home page (adversarial read, 2026-10-12), so a simulated link copies nothing a judge can use.
- Rationale: a move with no behaviour change for Share call; the copy sheet looks like Share call for free; copied text pastes as proof anywhere. The user chose text over a link or a PNG (Q-1).
- Alternatives considered:
  - Copy a simulated link `https://vistamarkets.xyz/copy/<code>`, matching Share call (`share_call_sheet.dart:61`) — rejected: lands on the company home page.
  - Export a PNG of the card (`RepaintBoundary.toImage` plus a download or platform share) — rejected: new platform code per target and nothing the suite can check, on deadline day.
  - Duplicate the row in the new sheet — rejected: two copies of the same four assets and sizes drift the first time one is tuned.
- Consequences: `share_call_sheet.dart` changes in a feature it does not own; the Share call test that taps every target (`home_screen_test.dart:2819-2825`) must still pass. The card on screen keeps its `· Simulated` footer; only the copied string drops it.

### DR-5: Host a local build on `gh-pages`, no workflow
- Decision: `flutter build web --release --base-href /VistaColosseum/`, push `build/web` (+ `.nojekyll`) to branch `gh-pages`, create the Pages site from it with one REST call.
- Context: D3; cutoff tonight; no `.github/workflows/` exists; admin rights confirmed.
- Rationale: nothing to debug but the build itself, which already passed in the probe; the deploy is four commands and reversible (delete the branch).
- Alternatives considered:
  - GitHub Actions Pages workflow (`subosito/flutter-action@v2.23.0`, `actions/upload-pages-artifact@v5.0.0`, `actions/deploy-pages@v5.0.1`, versions checked 2026-10-12) — rejected for tonight: a first workflow run on deadline day is a second system to make work; recorded as the follow-up.
  - Leave it as is (Mac or Linux build only) — rejected: D3 is the single biggest reason a judge sees only the video.
- Consequences: the hosted build is a snapshot; re-deploying is manual. The web app is the demo at a commit, not `main`.

### DR-6: A 390-wide phone frame on web
- Decision: `VistaColosseumApp(web: kIsWeb)` centres the app in a 390 px column and overrides `MediaQuery.size.width` to 390.
- Context: every layout and overflow test assumes a phone width (`home_screen_test.dart:75-80`, 360–430 wide); a laptop browser is 1280+ wide.
- Rationale: cheaper than making eleven screens responsive, the frame is the honest shape of a phone demo, and a Dart frame is checkable by `flutter test`.
- Alternatives considered:
  - Full-width web layout — rejected: untested widths; the feed card and pagers are phone-designed.
  - Frame the app from `index.html` with the loader's `hostElement` (a 390 px element; `flutter_web_sdk/flutter_js/src/types.d.ts:64`) — rejected: it works with no Dart change, but the only check is a browser run; the Dart frame gets AC-3.2 in the suite. Valid fallback if the Dart frame misbehaves.
- Consequences: a parameter on `VistaColosseumApp` and one test at 1280×800. Narrower windows get `min(390, window width)`.

### DR-7: Guard `LiveFeed.enabled` with `kIsWeb`
- Decision: `static bool get enabled => kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST');`.
- Context: D3; `foundation.dart` is already imported (`live_feed.dart:5`); the import of `dart:io` compiles on web (probe) and only the call throws.
- Rationale: one token; `kIsWeb` is a compile-time constant so the `Platform` call is dead code on web and unchanged on the VM.
- Alternatives considered:
  - Replace with `bool.fromEnvironment('FLUTTER_TEST')` — rejected: `flutter test` sets a process environment variable, not a `--dart-define`, so the feed would run under tests and break their determinism.
  - Remove the `dart:io` import behind a conditional import — rejected: two files for one boolean.
- Consequences: the live drift runs on web; tests are unaffected.

### DR-8: A one-time launch toast on web points at the pill
- Decision: when `VistaColosseumApp.web` is true, show `Tap the Simulated pill at the bottom to switch persona or play the copy story` as a `SnackBar` for 8 seconds after the first frame, once per page load.
- Context: the whole D1 fix hangs on a judge tapping a 30 px strip the code itself calls a known tap-target gap (`simulation_indicator.dart:41-46`); a judge arriving by link has not read the README.
- Rationale: the user chose a toast over a caption (Q-2); it uses the app's existing toast path and vanishes, leaving the frame as designed. The 8 s duration doubles the default 4 s so it survives the first look.
- Alternatives considered:
  - A permanent caption under the phone frame — rejected by the user: adds a visible element to the page.
  - Nothing beyond the README — rejected: the top risk in §10 would have no in-app mitigation.
- Consequences: a judge who tabs away in the first seconds misses it; the README still names the controls. Tests that pump `VistaColosseumApp()` see no toast because `web` defaults to `kIsWeb`, which is false on the VM.

## 7. Implementation Plan

**File manifest**

| File | Action | Responsibility | Phase |
|---|---|---|---|
| `app/lib/features/simulation/simulation_indicator.dart` | modify | pill label with handle; `actAs`, `playCopyStory`; two note buttons | 1 |
| `app/test/home_screen_test.dart` | modify | `pill` becomes a prefix `RegExp` (`:59`) | 1 |
| `app/test/judge_controls_test.dart` | create | note controls: switch, preset, idempotence, failure path | 1 |
| `docs/specs/README.md` | modify | row for spec 13 | 1 |
| `app/lib/features/share/share_targets.dart` | create | `ShareTargets` row moved out of the call sheet | 2 |
| `app/lib/features/share/share_call_sheet.dart` | modify | use `ShareTargets`; delete `_targets()` | 2 |
| `app/lib/features/share/copy_card.dart` | create | `CopyCard`, `CopyCardSheet`, `showCopyCardSheet` | 2 |
| `app/lib/features/trade/order_ticket.dart` | modify | "Share copy card" link on a filled copy | 2 |
| `app/lib/features/market/receipt_screens.dart` | modify | ledger copy rows open the sheet | 2 |
| `app/test/copy_card_test.dart` | create | card text, both entry points, clipboard, negative path | 2 |
| `app/web/index.html`, `manifest.json`, `favicon.png`, `icons/Icon-192.png`, `icons/Icon-512.png`, `icons/Icon-maskable-192.png`, `icons/Icon-maskable-512.png` | create | Flutter web scaffold (7 files) | 3 |
| `app/lib/features/live/live_feed.dart` | modify | `kIsWeb` guard (`:23`) | 3 |
| `app/lib/main.dart` | modify | `web` parameter, phone frame, launch toast | 3 |
| `app/test/web_frame_test.dart` | create | frame and toast at 1280×800; `LiveFeed.enabled` false under test | 3 |
| `README.md` | modify | browser link first in "Run it"; pill controls sentence; web limitation | 3 |

### Phase 1 — `simulation_indicator.dart`: judge controls in the note
- Outcome: from any screen, one tap on the pill then one tap plays the copy story to the creator's ledger, or switches persona; the pill names who is acting.
- Changes:
  - Modify: `app/lib/features/simulation/simulation_indicator.dart:73` — `label` becomes `'Simulated · ${Scenario.fixtureVersion} · ${persona.handle}'` inside a `ValueListenableBuilder<Persona>` on `Scenario.activePersona` wrapping the `Positioned` pill (`:88-126`); the `Semantics.label` and the `Text` use the same string.
  - Modify: `:11-21` region — add two top-level functions beside `resetDemo` (signatures in Produces).
  - Modify: `_SimulatedNote.build` (`:151-167`) — before the "Reset demo" button add `VistaPrimaryButton(label: 'Act as @${other.handle}', onPressed: () => actAs(context))` and `VistaPrimaryButton(label: 'Play the copy story', onPressed: () => playCopyStory(context))`, `VistaSpace.md` apart, where `other` is the persona that is not `Scenario.activePersona.value`. The note stays `const` (`:65`); the two buttons sit inside a `ValueListenableBuilder<Persona>(valueListenable: Scenario.activePersona, …)` so the "Act as" label follows a switch.
  - Modify: `app/test/home_screen_test.dart:59` — `const pill = 'Simulated · fixture-v1';` becomes `final pill = RegExp(r'^Simulated · fixture-v1');` (every `find.bySemanticsLabel(pill)` then matches by prefix).
  - Modify: `docs/specs/README.md:17` — append the row `| [13 Judge controls, copy card, web](13-judge-mode-and-copy-card.md) | Pill controls, shareable copy card, hosted web build | VC-DEM-003, VC-DEM-004, VC-CPY-002 | Spec'd |`.
  - Create: `app/test/judge_controls_test.dart`.
- Interfaces:
  - Consumes: `Scenario.activePersona: ValueNotifier<Persona>`, `Scenario.switchPersona(): void`, `Scenario.placeOrder(OrderIntent): OrderResult`, `Scenario.receipts`, `Scenario.cashCents`, `Persona.creator / Persona.copier` with `.handle` (`package:vista_colosseum/scenario/scenario.dart`); `MarketPrices.now(String): double` (`features/live/market_prices.dart`); `LedgerScreen.route(): Route<void>` (`features/market/receipt_screens.dart`); `AppShell.tab: ValueNotifier<int>`, `AppShell.wallet: int` (`app_shell.dart`); `VistaAssets.coinSolRow`, `VistaPrimaryButton({required String label, required VoidCallback? onPressed})`, `VistaSpace.md` (`design_system/design_system.dart`).
  - Produces (`package:vista_colosseum/features/simulation/simulation_indicator.dart`):
    - `void actAs(BuildContext context)` — captures `ScaffoldMessenger.of(context)`, `Navigator.of(context).popUntil((r) => r.isFirst)`, `Scenario.switchPersona()`, toasts `'Now acting as ${Scenario.activePersona.value.handle}'`. Never throws.
    - `const String kPresetCopyActionId = 'preset-copy'`.
    - `OrderIntent presetCopyIntent()` — the §5 intent with `actionId: kPresetCopyActionId` at `MarketPrices.now('SOL')`; pure.
    - `void playCopyStory(BuildContext context)` — synchronous, no `await`. Order: `final nav = Navigator.of(context); final messenger = ScaffoldMessenger.of(context);` first (the note's own route is popped next); `nav.popUntil((r) => r.isFirst)`; if `activePersona.value != Persona.copier` then `switchPersona()`; `final before = Scenario.copyFees.length; final r = Scenario.placeOrder(presetCopyIntent());` if `r is OrderFailed` → toast `r.reason`, return (persona left as copier); else `switchPersona()` (now creator), `AppShell.tab.value = AppShell.wallet`, `nav.push(LedgerScreen.route())`, then toast by what the store did: if `Scenario.copyFees.length > before` → `'sam.sol copied @kilo.sol · $5.00 copy fee credited to maya.eth (simulated)'`, else → `'Already played · the $5.00 copy fee is on the Fee ledger (simulated)'` (handles from `Persona.copier.handle`, `Persona.creator.handle`, fee from `formatCents(kCopyFeeCents)`). A repeat with receipt `'preset-copy'` present is an `OrderFilled` from the guard (`scenario.dart:379-382`), writes nothing, and takes the "Already played" branch.
  - Unchanged: `resetDemo` behaviour and toast; `SimulationIndicator.slot = 30`; the Settings "Demo persona" row; `Scenario.switchPersona` and `placeOrder` bodies.
- Gotchas: capture the messenger before `popUntil`, as `resetDemo` does (`:12-13`), or the toast has no scaffold. `Navigator.of(context)` inside the note is the app navigator (the sheet opens on `widget.navigator.currentContext`, `:58`). The pill label at 1.3× on 375 wide must still fit the 30 px strip; `VistaType.label` is the existing size.
- Complexity: integration.
- Non-goals: README wording (Phase 3); changing the Settings row; more than one preset; any new store method.
- Depends on: none.
- Acceptance criteria:
  - AC-1.1: given a fresh launch (`Scenario.reset()`, creator active), when the pill is tapped, then the note shows the buttons `Act as @sam.sol`, `Play the copy story`, `Reset demo` in that order, the pill's Semantics label is `Simulated · fixture-v1 · maya.eth`, and at 375×667 and 390×844 with 1.3× text every existing `find.bySemanticsLabel(pill)` test in `home_screen_test.dart` passes with no `RenderFlex` overflow; `flutter analyze` is clean and `flutter test` passes with ≥ 348 plus the new tests. (D1, global constraints)
  - AC-1.2: given the note is open with a ticket sheet and a pushed route beneath it, when `Act as @sam.sol` is tapped, then every route is popped (`Navigator.canPop()` is false), `Scenario.activePersona.value == Persona.copier`, `Scenario.cashCents.value == 100000`, the pill reads `Simulated · fixture-v1 · sam.sol`, and the toast `Now acting as sam.sol` is visible. (D1)
  - AC-1.3: given a fresh launch as creator, when `Play the copy story` is tapped, then `Scenario.activePersona.value == Persona.creator`, `Scenario.booksOf(Persona.copier).cashCents == 97495`, `Scenario.booksOf(Persona.copier).receipts` has one receipt with `id == 'preset-copy'`, `sourceAuthorHandle == 'kilo.sol'`, `copyFeeCents == 500`, `Scenario.copyFees` has exactly one entry with `amountCents == 500`, `counterparty == 'sam.sol'`, `asset == 'SOL'`, `AppShell.tab.value == AppShell.wallet`, the top route is `LedgerScreen` showing `COPY FEES` and the row `Copy fee · @sam.sol · SOL` with `$5.00`, and the toast `sam.sol copied @kilo.sol · $5.00 copy fee credited to maya.eth (simulated)` is visible. (D1)
  - AC-1.4: given AC-1.3 has run, when the pill is tapped and `Play the copy story` is tapped again, then `Scenario.copyFees.length == 1`, the copier's cash is still 97495, the ledger is on top again, and the toast reads `Already played · the $5.00 copy fee is on the Fee ledger (simulated)`, not the "credited" text; after `Reset demo`, a further play produces exactly one row and the "credited" toast again. (D1, negative: no duplicate write, honest confirmation)
  - AC-1.5: given the copier's cash is set below 2505 cents before the play (test seeds `Scenario.switchPersona(); Scenario.cashCents.value = 1000; Scenario.switchPersona();`), when `Play the copy story` is tapped, then no receipt and no `copyFee` row is written, `Scenario.activePersona.value == Persona.copier`, no `LedgerScreen` is pushed, and the toast reads `Not enough funds`. (D1, negative)

### Phase 2 — `features/share`: the copy card and its two entry points
- Outcome: a filled copy and a ledger copy row each open a sheet with a shareable 346×182 copy card and the existing share targets.
- Changes:
  - Create: `app/lib/features/share/share_targets.dart` — `ShareTargets` with the exact body of `_targets()` (`share_call_sheet.dart:212-255`): the four `(label, asset, size)` tuples, 52 px `surfaceRaised` circles, `VistaType.meta` captions, and `Semantics(button: true, label: label, excludeSemantics: true)` kept as is (the Share call test taps each label, `home_screen_test.dart:2819-2825`); the fourth tuple's label is the `copyLabel` parameter (default `'Copy link'`), its icon `VistaAssets.shareCopyLink` unchanged.
  - Modify: `app/lib/features/share/share_call_sheet.dart:136` — `_targets()` becomes `ShareTargets(onSend: _send)`; Delete: `_targets()` (`:212-255`). `_code`, `_url` and `_send` stay as they are.
  - Create: `app/lib/features/share/copy_card.dart` — `CopyCard`, `CopyCardSheet`, `showCopyCardSheet` (Produces).
  - Modify: `app/lib/features/trade/order_ticket.dart:996` — after the `Simulated — no real order` text, when `filled != null && filled.copyFeeCents > 0`, add `const SizedBox(height: VistaSpace.md)` and a `Semantics(button: true, label: 'Share copy card')` `GestureDetector` over `Text('Share copy card', style: VistaType.subhead.copyWith(color: VistaColors.accent))` that calls `showCopyCardSheet(context, copier: Scenario.activePersona.value.handle, author: filled.sourceAuthorHandle!, symbol: filled.symbol, feeCents: filled.copyFeeCents)`.
  - Modify: `app/lib/features/market/receipt_screens.dart:129-153` — wrap each copy row's `Padding` in `Semantics(button: true, label: 'Share copy card · @${e.counterparty} · ${e.asset}')` and a `GestureDetector(behavior: HitTestBehavior.opaque)` calling `showCopyCardSheet(context, copier: e.counterparty!, author: e.sourceCallId!.split('/').first, symbol: e.asset!, feeCents: e.amountCents)`. Rows whose `counterparty`, `sourceCallId` or `asset` is null are left untappable (no `Semantics` button).
  - Create: `app/test/copy_card_test.dart`.
- Interfaces:
  - Consumes: `copyLine`, `formatCents(int): String` (`features/live/live_feed.dart:68`), `Persona.creator.handle`, `Scenario.activePersona`, `OrderReceipt.{copyFeeCents, sourceAuthorHandle, symbol}`, `FeeEntry.{counterparty, sourceCallId, asset, amountCents}`, `VistaAssets.shareLogo`, `VistaType.{micro, subhead, body, meta}`, `VistaColors.{background, long, textMuted, accent, surface, surfaceRaised}`, `VistaRadius.pill`, `Clipboard.setData`, `HapticFeedback.selectionClick`.
  - Produces (`package:vista_colosseum/features/share/share_targets.dart`): `class ShareTargets extends StatelessWidget { const ShareTargets({super.key, required this.onSend, this.copyLabel = 'Copy link'}); final void Function(String label) onSend; final String copyLabel; }` — labels are exactly `'Messages'`, `'Telegram'`, `'X'`, then `copyLabel`, each a `Semantics` button with that label; `onSend` receives the label as shown.
  - Produces (`package:vista_colosseum/features/share/copy_card.dart`):
    - `class CopyCard extends StatelessWidget { const CopyCard({super.key, required this.copier, required this.author, required this.symbol, required this.feeCents}); static const double width = 346, height = 182; }` — text, top to bottom: `'Copied @$author · $symbol'`, `'${formatCents(feeCents)} copy fee → @${Persona.creator.handle}'`, `'by @$copier · Simulated'`; `COPIED` tag top-right.
    - `Future<void> showCopyCardSheet(BuildContext context, {required String copier, required String author, required String symbol, required int feeCents})` — `showModalBottomSheet` (transparent background, scrim `0x73000000` as `share_call_sheet.dart:18`) of `CopyCardSheet`: header `Share copy` + `Done`, label `WHAT THEY'LL SEE`, the `CopyCard`, `ShareTargets(copyLabel: 'Copy text')`. `onSend('Copy text')` writes `'Copied @$author · $symbol · ${formatCents(feeCents)} copy fee → @${Persona.creator.handle} · by @$copier'` to the clipboard (`Clipboard.setData`), pops, toasts `Card text copied`; any other label pops and toasts `'Shared to $label (simulated)'`. Never writes the store.
  - Unchanged: `ShareCallSheet`'s `_send`, `_url`, `_title`, preview; the Done / View in Wallet buttons and the fill toast in `_ReviewPanel`; ledger totals and row text.
- Gotchas: `_ReviewPanel` is inside a bottom sheet; `showCopyCardSheet` must use the panel's `context` (a second sheet stacks fine). The ledger row's `sourceCallId` format is `'<author>/<ticker>'` (`home_screen.dart:204`, `copy_story_test.dart:38`).
- Complexity: mechanical.
- Non-goals: a chart on the card; sharing non-copy fills; PNG export; changing `ShareCallCard`.
- Depends on: none (Phase 1 is not required; the ledger row exists today).
- Acceptance criteria:
  - AC-2.1: given a copier fill through `Scenario.placeOrder` of `OrderIntent(actionId: 'card-1', symbol: 'SOL', name: 'Solana', side: TradeSide.long, units: 100 / 214.90, price: 214.90, leverage: 5, sourceCallId: 'kilo.sol/SOL', sourceAuthorHandle: 'kilo.sol')` placed while `Persona.copier` is active (the `copyOf` helper in `copy_story_test.dart:23-40` is an ETH intent and does not fit), when the ledger row `Copy fee · @sam.sol · SOL`'s Semantics button is tapped, then a sheet shows `Share copy`, `Copied @kilo.sol · SOL`, `$5.00 copy fee → @maya.eth`, `by @sam.sol · Simulated`, and the four targets `Messages`, `Telegram`, `X`, `Copy text`. (D2)
  - AC-2.2: given the feed ticket is confirmed as copier on the `kilo.sol` SOL card (rehearsal step 34–35 path), when `Order filled` shows, then `Share copy card` is present, tapping it opens the same sheet text as AC-2.1, and `Done` / `View in Wallet` still behave as before. (D2)
  - AC-2.3: given a creator fill of the creator's own call (`copy_story_test.dart` 'own call places an ordinary order' setup), when `Order filled` shows, then `find.text('Share copy card')` finds nothing. (D2, negative)
  - AC-2.4: given the copy sheet from AC-2.1 is open, when `Copy text` is tapped, then the platform clipboard receives exactly `Copied @kilo.sol · SOL · $5.00 copy fee → @maya.eth · by @sam.sol` (no "Simulated"), the sheet closes, toast `Card text copied` shows, and `Scenario.feeEntries`, `cashCents`, `receipts` are unchanged; when `X` is tapped instead, the toast is `Shared to X (simulated)` and the clipboard is untouched. (D2)
  - AC-2.5: given the Home card's Share, when `showShareCallSheet` opens, then the four target labels `Messages`, `Telegram`, `X`, `Copy link` render as Semantics buttons and `Copy link` still copies `https://vistamarkets.xyz/c/<6 chars>` (the existing test `home_screen_test.dart:2812-2827` passes unchanged); `grep -n "_targets()" app/lib/features/share/share_call_sheet.dart` returns nothing. (D2 contract; DR-4)

### Phase 3 — `app/web`, `main.dart`, `live_feed.dart`, `README.md`: hosted web build
- Outcome: `https://vistamarkets.github.io/VistaColosseum/` serves the demo in a phone-sized frame, and the README's "Run it" opens with that link.
- Changes:
  - Create: `app/web/*` — run `flutter config --enable-web` once per machine, then from `app/`: `flutter create --platforms=web --project-name vista_colosseum --no-pub .`; then `rm test/widget_test.dart` and `git checkout -- .metadata pubspec.lock`; commit only the seven files under `web/` (`.idea/` and `*.iml` are gitignored); in `index.html` set `<title>VistaColosseum</title>`, `description` to `VistaColosseum — a simulated social-trading demo`, `apple-mobile-web-app-title` to `VistaColosseum`; in `manifest.json` set `name` and `short_name` to `VistaColosseum`.
  - Modify: `app/lib/features/live/live_feed.dart:23` — `static bool get enabled => kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST');`.
  - Modify: `app/lib/main.dart:13-17,36-39` — constructor gains `this.web = kIsWeb` (`final bool web`); when `web`, wrap the builder's result in a private `_LaunchHint` `StatefulWidget` (same file) whose `initState` schedules `WidgetsBinding.instance.addPostFrameCallback` → `ScaffoldMessenger.of(_navigator.currentContext!).showSnackBar(SnackBar(content: Text(kLaunchHint), duration: const Duration(seconds: 8)))`, once; `const kLaunchHint = 'Tap the Simulated pill at the bottom to switch persona or play the copy story';` and in `builder`, when `web`, compute `final w = math.min(390.0, MediaQuery.sizeOf(context).width);` and wrap the `SimulationIndicator` in `ColoredBox(color: VistaColors.background, child: Center(child: SizedBox(width: w, child: MediaQuery(data: MediaQuery.of(context).copyWith(size: Size(w, MediaQuery.sizeOf(context).height)), child: <the SimulationIndicator>))))`; the text-scale clamp stays outermost.
  - Modify: `README.md:36-43` — before "On a Mac", add: `**In your browser, no install:** <https://vistamarkets.github.io/VistaColosseum/> — the same simulated demo in a phone-sized frame. Tap the "Simulated · fixture-v1" pill at the bottom to switch persona or play the copy story to the creator's ledger.`; `:62-64` — extend the Reset paragraph with `The pill also offers **Act as** and **Play the copy story**.`; `:90-106` — add the bullet `- **Web build:** haptics are silent and the share targets copy text or a link rather than send; the hosted page is a snapshot of one commit.`
  - Create: `app/test/web_frame_test.dart`.
  - Deploy (commands, not files; run after the PR merges, from the `app/` of a `main` checkout):
    ```bash
    flutter build web --release --base-href /VistaColosseum/
    SHA=$(git rev-parse --short HEAD)
    cd build/web && touch .nojekyll && git init -q && git checkout -q -b gh-pages \
      && git add -A && git commit -qm "web build $SHA" \
      && git push -f git@github.com:VistaMarkets/VistaColosseum.git gh-pages:gh-pages
    echo '{"source":{"branch":"gh-pages","path":"/"}}' \
      | gh api -X POST repos/VistaMarkets/VistaColosseum/pages --input -
    ```
    Then open `https://vistamarkets.github.io/VistaColosseum/` (first deploy takes about a minute) and run AC-3.4.
- Interfaces:
  - Consumes: `kIsWeb` (`package:flutter/foundation.dart`), `VistaColors.background`, `SimulationIndicator`, `LiveFeed.enabled`.
  - Produces: `VistaColosseumApp({Key? key, Widget home = const AppShell(), bool web = kIsWeb})` and `const String kLaunchHint` (`package:vista_colosseum/main.dart`); `LiveFeed.enabled` is `true` on web, unchanged on the VM.
  - Unchanged: `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3)`; `SimulationIndicator.slot`; `LiveFeed` behaviour under `flutter test` (off).
- Gotchas: `build/` is gitignored (`app/.gitignore:33`), so the nested `git init` inside `build/web` is intentional and never touches the repo's index. `--base-href` must start and end with `/`. Pages serves `index.html` at the branch root; `.nojekyll` stops Jekyll from dropping dotfiles and underscore paths.
- Complexity: integration.
- Non-goals: a CI workflow; responsive layouts; PWA install polish; icons beyond the scaffold defaults.
- Depends on: Phase 1 (AC-3.4 drives the pill controls, and the README names them). Phase 2 is not required to build, but the deploy waits for it (§9).
- Acceptance criteria:
  - AC-3.1: given the scaffold is committed, when `cd app && flutter build web --release --base-href /VistaColosseum/` runs on Flutter 3.47.5, then it exits 0 and `build/web/index.html` contains `<base href="/VistaColosseum/">`. (D3)
  - AC-3.2: given `VistaColosseumApp(web: true)` pumped at 1280×800, when Home renders, then `tester.getSize(find.byType(HomeScreen)).width == 390`, the pill is centred within x ∈ [445, 835], no `RenderFlex` overflow is reported, the toast `kLaunchHint` is visible after the first frame, does not overlap the pill, and is gone after `pump(const Duration(seconds: 9))`; given `web: false` at 390×844, then Home's width is 390, no toast shows, and the existing overflow tests pass unchanged. (D3, DR-6, DR-8)
  - AC-3.3: given `flutter test`, when `LiveFeed.enabled` is read, then it is `false` (the suite stays deterministic), and `grep -c "kIsWeb ||" app/lib/features/live/live_feed.dart` prints `1`. (D3, DR-7)
  - AC-3.4: given the deploy commands ran, when `https://vistamarkets.github.io/VistaColosseum/` is opened in Chromium or Chrome (headless is acceptable; this box has no Chrome and no Mac, so Safari only if one is at hand, recorded as skipped otherwise), then the Home feed renders in a centred phone-width frame with the `Simulated · fixture-v1 · maya.eth` pill, the launch toast `kLaunchHint` shows above the pill, tapping the pill then `Play the copy story` lands on `Fee ledger` with the `$5.00` copy row, and the browser console shows no uncaught `UnsupportedError`. Manual; record the browser, date and a screenshot path in the PR. (D3, negative: no runtime throw)
  - AC-3.5: given `README.md`, when read, then "Run it" opens with the browser link and `grep -c "vistamarkets.github.io/VistaColosseum" README.md` prints `1`; `scripts/gate.sh <log-dir>` prints `GATE: PASS`. (D3, global constraints)

## 8. Test Strategy

- Regression per defect: D1 → AC-1.3 (`judge_controls_test.dart`, fails today because no `Play the copy story` exists); D2 → AC-2.1 (`copy_card_test.dart`, fails today because the row is inert); D3 → the manual AC-3.4 is the only behaviour check (the throw happens on web, which `flutter test` cannot run); AC-3.3's VM assertion passes today and only pins that the guard is present and tests stay deterministic.
- Contract tests: the fill toast and Done / View in Wallet (`order_ticket_test.dart`, unchanged); pill prefix label across every existing `home_screen_test.dart` pill test (AC-1.1); Share call targets unchanged (AC-2.5); `scripts/gate.sh` each phase.
- Boundary: AC-1.5 (cash below the copy's cost), AC-1.4 (repeat play, play after reset), AC-2.3 (non-copy fill has no card).
- Derived misses: empty `counterparty`/`asset` on a ledger row → untappable (Phase 2 change text); 1.3× text at 375 wide with the longer pill (AC-1.1); wide window on web (AC-3.2). Dependency failure and concurrency do not apply: no network, single-threaded store.
- `[cross-phase]`: none. Phase 3's README sentence about the pill controls depends on Phase 1 having merged; that is a sequencing note, not a criterion.

| D / DR | Criterion | Check | Test |
|---|---|---|---|
| D1 | AC-1.1 | fresh launch, pill tapped → note shows `Act as @sam.sol`, `Play the copy story`, `Reset demo`; label `Simulated · fixture-v1 · maya.eth`; existing pill tests pass at 375×667 and 390×844 at 1.3× with no overflow; analyze clean; ≥ 348 + new tests pass | `app/test/judge_controls_test.dart` 'the note offers act-as, play and reset'; `home_screen_test.dart` pill group; `scripts/gate.sh` |
| D1 | AC-1.2 | `Act as @sam.sol` pops every route, switches to copier with cash 100000, pill reads `· sam.sol`, toast `Now acting as sam.sol` | `judge_controls_test.dart` 'act as switches persona and closes sheets' |
| D1 | AC-1.3 | play as creator → creator active, copier cash 97495, one receipt `preset-copy` from `kilo.sol` with fee 500, one `copyFee` row (`sam.sol`, `SOL`), Wallet tab, `LedgerScreen` on top with `Copy fee · @sam.sol · SOL` `$5.00`, toast | `judge_controls_test.dart` 'play the copy story lands on the ledger row' |
| D1 | AC-1.4 | second play → still one row, cash 97495, ledger on top, toast `Already played · the $5.00 copy fee is on the Fee ledger (simulated)`; after Reset demo a play writes one row and the "credited" toast again | `judge_controls_test.dart` 'a repeat play writes nothing; reset lets it play again' |
| D1 | AC-1.5 | copier cash 1000 → no receipt, no row, persona copier, no ledger, toast `Not enough funds` | `judge_controls_test.dart` 'play fails whole when the copier cannot pay' |
| D2 | AC-2.1 | after a SOL copy intent (`kilo.sol/SOL`) placed as copier, ledger row tap → sheet with `Share copy`, three card lines, four targets | `app/test/copy_card_test.dart` 'the ledger row opens the copy card' |
| D2 | AC-2.2 | copier confirm on the kilo.sol SOL card → `Share copy card` link opens the same sheet; Done / View in Wallet unchanged | `copy_card_test.dart` 'order filled offers the copy card for a copy' |
| D2 | AC-2.3 | creator's own call fill → no `Share copy card` | `copy_card_test.dart` 'an ordinary fill offers no card' |
| D2 | AC-2.4 | Copy text → clipboard `Copied @kilo.sol · SOL · $5.00 copy fee → @maya.eth · by @sam.sol`, sheet closes, `Card text copied`, store unchanged; X → `Shared to X (simulated)`, clipboard untouched | `copy_card_test.dart` 'targets copy the card text or toast, and never write' |
| DR-4 | AC-2.5 | Share call still shows `Messages`, `Telegram`, `X`, `Copy link` as Semantics buttons and copies `…/c/<6>`; existing test passes; no `_targets()` left | `home_screen_test.dart:2812-2827` + grep |
| D3 | AC-3.1 | `flutter build web --release --base-href /VistaColosseum/` exits 0; `<base href="/VistaColosseum/">` in output | build log in the PR |
| DR-6, DR-8 | AC-3.2 | `web: true` at 1280×800 → Home width 390, pill centred, no overflow, launch toast visible above the pill then gone after 9 s; `web: false` → no toast, layouts unchanged | `app/test/web_frame_test.dart` 'the web frame is phone-wide and hints once' |
| DR-7 | AC-3.3 | `LiveFeed.enabled` false under test; guard present once | `web_frame_test.dart` 'the live feed stays off under test' + grep |
| D3 | AC-3.4 | hosted page renders in a frame with the launch toast, play lands on the ledger, no `UnsupportedError` | manual, recorded in the PR |
| D3 | AC-3.5 | README opens "Run it" with the link, exactly one occurrence; gate passes | grep + `scripts/gate.sh` |

## 9. Rollout & Verification

- **Sequence.** Phase 1 PR, Phase 2 PR, Phase 3 PR, each from its own worktree off `main`, each gated by `scripts/gate.sh`. Phases 1 and 2 are independent and safe to ship alone. Phase 3 merges after Phase 1. The deploy runs once, after the last of the three merges; if Phase 2 is dropped, the README's web bullet adds "no copy card in the hosted build".
- **Backward compatibility.** No persisted state, no API. The pill label change needs the one-line test update in Phase 1. The web scaffold adds files only.
- **Rollback.** Revert the phase's PR. For the hosted page: `git push git@github.com:VistaMarkets/VistaColosseum.git --delete gh-pages` and `gh api -X DELETE repos/VistaMarkets/VistaColosseum/pages`; remove the README link.
- **Post-cutover gates.** Within ten minutes of the deploy: the page loads over HTTPS, AC-3.4 passes in Chrome and Safari, and the README link resolves (HTTP 200). Before the submission form is sent: the roadmap's M7 package names the link beside the video.

## 10. Risks & Open Questions

| Risk | Likelihood / Impact | Mitigation or contingency |
|---|---|---|
| Hosted page is a snapshot that drifts from `main` (DR-5) | high / low | README says so; redeploy is the four commands in Phase 3; workflow is the follow-up |
| Judges never find the pill controls: a 30 px strip the code calls a known tap-target gap (`simulation_indicator.dart:41-46`), labelled like a status badge (DR-1) | high / high | the 8 s launch toast on web names the pill and the controls (DR-8); the README repeats it; a judge who misses both still has the Settings row |
| The launch toast is missed in the first seconds (DR-8) | medium / medium | README sentence; fallback is the caption the user declined, one `Text` in the frame |
| A web-only runtime throw beyond `Platform.environment` (D3) | low / high | the guarded build ran in headless Chromium with zero exceptions (§4); AC-3.4 repeats that on the hosted page before the README link merges |
| Pages first deploy delayed or 404 for minutes | medium / medium | deploy before the README PR merges; the Linux and Mac instructions stay |
| Judge expects a second play to add a second row (DR-2) | medium / low | the repeat toast says "Already played"; Reset demo re-arms it |
| The longer pill overflows at 1.3× on 375 wide (DR-1) | low / medium | AC-1.1 runs the existing overflow tests; fallback is dropping ` · <handle>` from the label |
| Card economics read as odd (kilo.sol's call, maya.eth's fee) (DR-3) | medium / low | ruling 2 accepts it; README "Everything is simulated" bullet |
| Copied card text carries no "Simulated" marker once pasted elsewhere (DR-4) | medium / low | the user chose this (Q-1); the card on screen and the app's pill keep the marker; README "Everything is simulated" |
| `share_call_sheet.dart` edit regresses Share call (DR-4) | low / medium | AC-2.5 |
| Three PRs on deadline day crowd the presenter's final recording | medium / medium | Phase 1 first (30 min); Phases 2–3 are each droppable without touching the other |

Open questions: none. (Q-1 and Q-2 were answered by the user on 2026-10-12 and folded into DR-4 and DR-8.)
