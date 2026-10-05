# 09: Copy story — persona switch, copied order, copy fee

## Rules for this unit

Common rules for every unit: original lightweight code (CONTEXT.md), no new pub dependencies, money as `int` minor units or fixed-decimal strings (never new `double` money), every success message describes something that actually happened, keep the existing "— not in the demo yet" toast for anything you don't build. Run `scripts/gate.sh <log-dir>` before returning; it must print `GATE: PASS`. Every acceptance criterion names its test as `app/test/<file>.dart: <test name>` or is marked `manual, waived`; add the tests the spec names.

**PRD:** VC-CPY-001, VC-CPY-002, VC-DEM-004 (persona switch). **Decision:** O-06, October 4 — the copy story is P0 with fixture numbers (PRD v0.5 §8). **Gap:** no persona in `Scenario` (`app/lib/scenario/scenario.dart`); the feed ticket (`feed_order_ticket.dart`) places an order from a call but records nothing about the call it came from; the ledger (unit 06) has no copy row.

## Behavior

- **Personas.** `Scenario` gains `activePersona` ∈ {`creator`, `copier`} as a `ValueListenable`, seeded `creator`, restored by `reset()`. The copier is a second seeded identity with its own paper cash (fixture: `100000` cents) and an empty position list; the creator keeps today's seed. Cash, positions, open orders and receipts are keyed by persona; likes, favourites, follows, listing and the fee ledger stay as they are (the ledger belongs to the creator). Switch control: a "Demo persona" row in Settings (`settings_screen.dart`, above "Reset demo") that toggles and toasts "Now acting as <name>". Switching never mutates financial state.
- **Copy entry.** `OrderIntent` gains optional `sourceCallId` and `sourceAuthorHandle`. The feed ticket sets both from the call it opened from. A call whose author is the active persona places an ordinary order (no copy fee, no credit); any other call is a copy. Viewing, liking, following and opening the ticket never call `placeOrder`.
- **Copy fee on confirm.** Inside `Scenario.placeOrder`, when the intent is a copy and the order would fill: validate `marginCents + feeCents + copyFeeCents ≤ cash` (insufficient funds fails the whole order, nothing is written); debit the copier `copyFeeCents = 500` (fixture constant `kCopyFeeCents`, flat per confirmed copy) in the same write as margin and fee; append one `FeeEntry{kind: copyFee, amountCents: 500, sourceCallId, counterparty: copier handle}` to the creator ledger (type from unit 06); stamp the copier's `Receipt` with `sourceCallId` and `copyFeeCents`. All of this is under the existing `actionId` duplicate guard, so a repeated confirm returns the first result and writes nothing. `resting` and `failed` results write no fee and no credit.
- **Surfaces.** Review sheet adds the line "Copying @<handle> · $5.00 copy fee" to the paper-funds-required total. Receipt shows the same. The creator's ledger (unit 06) shows the row as `Copy fee · @copier · <asset>` in its copy section. Money formatting via the unit-02 helper.
- **Not built:** automatic copy execution, any payment rail, variable fee, copier-side earnings. Reuse the existing "— not in the demo yet" toast if a control is needed as a placeholder.

## Acceptance

- [ ] Confirm a copy as copier → copier cash reduced by margin + fee + 500; one position; one receipt with `sourceCallId`; creator ledger gains exactly one `copyFee` row of 500. Test: `app/test/copy_story_test.dart: 'confirming a copied order debits the copy fee once and credits the creator once'`.
- [ ] Cancel → store unchanged (deep equality). Test: `app/test/copy_story_test.dart: 'cancelling a copied order writes nothing'`.
- [ ] Insufficient funds including the copy fee → `failed`, no position, no debit, no ledger row. Test: `app/test/copy_story_test.dart: 'copy fails whole when cash cannot cover margin, fee and copy fee'`.
- [ ] Repeated `actionId` → first result returned, one position, one ledger row. Test: `app/test/copy_story_test.dart: 'repeated actionId on a copy does not double-pay'`.
- [ ] Call authored by the active persona → no copy fee, no ledger row. Test: `app/test/copy_story_test.dart: 'own call places an ordinary order'`.
- [ ] Persona switch preserves both personas' financial state; `reset()` restores `creator` and both seeds. Test: `app/test/copy_story_test.dart: 'switch then reset restores creator and both seeds'`.
- [ ] Review sheet and receipt show the copy line and the total agrees with the stored cents. Widget test: `app/test/feed_order_ticket_test.dart: 'copy review shows the $5.00 copy fee in the total'`. Visual distinctness of the ledger copy section: manual, waived.

## Out of scope
Automatic copy execution, real or variable payment, scenario phase advance (O-10, P1), copier earnings, trader-index tickets (VC-MKT-005).
