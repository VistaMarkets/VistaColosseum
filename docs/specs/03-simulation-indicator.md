# 03: Persistent simulation indicator

## Rules for this unit

Common rules for every unit: original lightweight code (CONTEXT.md), no new pub dependencies, money as `int` minor units or fixed-decimal strings (never new `double` money), every success message describes something that actually happened, keep the existing "— not in the demo yet" toast for anything you don't build. Run `scripts/gate.sh <log-dir>` before returning; it must print `GATE: PASS`. Every acceptance criterion names its test as `app/test/<file>.dart: <test name>` or is marked `manual, waived`; add the tests the spec names.

**PRD:** VC-DEM-003. **Gap:** "simulated" appears only in transient toasts.

## Behavior
- A small persistent pill ("Simulated · fixture-v1") rendered once in `AppShell` above the floating nav, visible on every tab and every pushed route (wrap `MaterialApp.builder`). Reads fixture version from `Scenario`.
- Tap → sheet: "All prices, fills, balances and results are simulated. Nothing leaves this device." plus the Reset demo button (same action as Settings).
- Must not cover nav, form fields or action buttons at 375×667 and 390×844; respects safe area; survives 1.3× text scaling.

## Acceptance
- [ ] Pill visible on Home, Explore, Arena, Wallet, and inside the order ticket and make-market flow.
- [ ] Widget test: pill present on each tab; no overflow at the smallest viewport in `home_screen_test.dart`'s device list.
- [ ] Review/confirmation sheet from unit 02 shows the simulated label (verify, don't duplicate).
