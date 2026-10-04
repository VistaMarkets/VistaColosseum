# 07: Trader record panel: capital-independent metrics

## Rules for this unit

Common rules for every unit: original lightweight code (CONTEXT.md), no new pub dependencies, money as `int` minor units or fixed-decimal strings (never new `double` money), every success message describes something that actually happened, keep the existing "— not in the demo yet" toast for anything you don't build. Run `scripts/gate.sh <log-dir>` before returning; it must print `GATE: PASS`. Every acceptance criterion names its test as `app/test/<file>.dart: <test name>` or is marked `manual, waived`; add the tests the spec names.

**PRD:** VC-MKT-002, VC-FED-003 (trader link). **Gap:** `profile_mock.dart` hard-codes `settled '62'`, `right '36'`; no sample count / as-of / illustrative-index explanation; no zero-history state.

## Behavior
- Derive record metrics from unit-06 `CallReceipt`s per trader: settled count, hit rate, as-of = demo clock. Computation ignores paper trade size entirely (document in a doc comment).
- Seed two fixture traders with identical call outcomes but different trade sizes; they show identical record metrics.
- Seed one trader with zero settled calls → panel shows "No settled calls yet — record unavailable" and no index chart.
- Panel copy: "Illustrative index · based on N settled calls · as of <clock>". Reuse the existing profile/record widgets; tapping a trader name on a feed card or Arena side opens this panel.

## Acceptance
- [ ] Test: two traders, same outcomes, different sizes → equal metrics.
- [ ] Test: zero-history trader → unavailable state, no crash.
- [ ] Trader link from feed card and Arena card lands on the panel. Tests: `app/test/trader_record_test.dart: 'feed card trader link opens the record panel'` and `'Arena card trader link opens the record panel'`.
