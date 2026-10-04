# 08 — Loading, empty and failed states on core lists

**PRD:** VC-QA-002. Run last; it audits what units 01–07 built.

## Behavior
- For Home feed, Arena list, Open orders, Positions, Receipts, Ledger, Following/Followers: render an intentional empty state (short line + one action) when the list is empty after reset or filtering. Use one shared `VistaEmptyState` widget in the design system.
- One seeded failure: the Explore/Markets list has a presenter-only "Simulate load failure" toggle in Settings (next to Reset demo); when on, the list shows a failed state with Retry; Retry clears the toggle and loads. No other screen depends on it.
- Loading: lists that are instant stay instant; do not add fake spinners.
- Ensure no route throws on an empty collection (run each screen in a widget test with an emptied scenario).

## Acceptance
- [ ] Widget test: every listed screen renders with an empty scenario without overflow or exception.
- [ ] Failure toggle → failed state → Retry → loaded.
- [ ] All existing tests still pass; `flutter analyze` clean.
