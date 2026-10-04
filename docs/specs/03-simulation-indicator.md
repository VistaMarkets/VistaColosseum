# 03 — Persistent simulation indicator

**PRD:** VC-DEM-003. **Gap:** "simulated" appears only in transient toasts.

## Behavior
- A small persistent pill ("Simulated · fixture-v1") rendered once in `AppShell` above the floating nav, visible on every tab and every pushed route (wrap `MaterialApp.builder`). Reads fixture version from `Scenario`.
- Tap → sheet: "All prices, fills, balances and results are simulated. Nothing leaves this device." plus the Reset demo button (same action as Settings).
- Must not cover nav, form fields or action buttons at 375×667 and 390×844; respects safe area; survives 1.3× text scaling.

## Acceptance
- [ ] Pill visible on Home, Explore, Arena, Wallet, and inside the order ticket and make-market flow.
- [ ] Widget test: pill present on each tab; no overflow at the smallest viewport in `home_screen_test.dart`'s device list.
- [ ] Review/confirmation sheet from unit 02 shows the simulated label (verify, don't duplicate).
