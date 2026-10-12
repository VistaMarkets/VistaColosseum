# VistaColosseum app

The Flutter app for the VistaColosseum demo. Run, reset and test instructions
are in the [repository README](../README.md#run-it).

- `lib/scenario/`: the demo's single source of state: personas, fixture,
  orders, receipts, the fee ledger and reset.
- `lib/features/`: one folder per screen area (home, markets, arena,
  portfolio, make_market, market, trade, settings, …).
- `lib/design_system/`: Vista colours, type, spacing and shared components.
- `test/`: widget and unit tests (`flutter test`).
- `linux/`, `ios/`, `android/`: platform runners.
