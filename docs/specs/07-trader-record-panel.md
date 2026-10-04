# 07 — Trader record panel: capital-independent metrics

**PRD:** VC-MKT-002, VC-FED-003 (trader link). **Gap:** `profile_mock.dart` hard-codes `settled '62'`, `right '36'`; no sample count / as-of / illustrative-index explanation; no zero-history state.

## Behavior
- Derive record metrics from unit-06 `CallReceipt`s per trader: settled count, hit rate, as-of = demo clock. Computation ignores paper trade size entirely (document in a doc comment).
- Seed two fixture traders with identical call outcomes but different trade sizes; they show identical record metrics.
- Seed one trader with zero settled calls → panel shows "No settled calls yet — record unavailable" and no index chart.
- Panel copy: "Illustrative index · based on N settled calls · as of <clock>". Reuse the existing profile/record widgets; tapping a trader name on a feed card or Arena side opens this panel.

## Acceptance
- [ ] Test: two traders, same outcomes, different sizes → equal metrics.
- [ ] Test: zero-history trader → unavailable state, no crash.
- [ ] Trader link from feed card and Arena card lands on the panel.
