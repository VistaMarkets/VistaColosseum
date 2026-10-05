# 05: Maker suggestion card in the Tradefeed

## Rules for this unit

Common rules for every unit: original lightweight code (CONTEXT.md), no new pub dependencies, money as `int` minor units or fixed-decimal strings (never new `double` money), every success message describes something that actually happened, keep the existing "— not in the demo yet" toast for anything you don't build. Run `scripts/gate.sh <log-dir>` before returning; it must print `GATE: PASS`. Every acceptance criterion names its test as `app/test/<file>.dart: <test name>` or is marked `manual, waived`; add the tests the spec names.

**PRD:** VC-FED-004. **Gap:** zero Maker/Aggro/suggestion content in `lib/`.

## Behavior
- New `Suggestion` fixture type (`home/maker_suggestion.dart`): asset, direction, rationale (2 lines), reference price, `expiresAt` (demo clock), `source: 'Maker · demo recommendation'`. Seed two: one live, one expired.
- Render as a visually distinct card in the Home feed (badge "Maker suggestion · advisory"), between existing idea cards. Viewing never calls the store.
- "Trade this" opens the unit-02 ticket prefilled; the expired card's button is disabled with "Expired" and cannot confirm.
- Card text states the data path in one line: "Built from Aggro demo prices".

## Acceptance
- [ ] Both cards render without overflow on the test device list.
- [ ] Test: live suggestion → ticket prefilled with asset/direction; expired → confirm unavailable; no store mutation from rendering or opening.
