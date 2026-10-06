# Phase 1 digest: copy story (spec 09), ONLY phase — MERGE-WITH-FIXES met at 4807f69 (10 confirmed, 0 before-merge, 10 applied; gate PASS 305, HAS_MARKET 305)

## Public surface
- `enum Persona { creator('maya.eth','Creator'), copier('sam.sol','Copier') }` with `handle`, `label`; `PortfolioMock.copierHandle = 'sam.sol'`, `copierCashCents = 100000`.
- `Scenario.activePersona` (`ValueNotifier<Persona>`, seed creator, `reset()` restores it and both seeds); `Scenario.switchPersona()` swaps books only; `Scenario.booksOf(Persona)`.
- `typedef Books = ({cashCents, positions, openOrders, receipts, participation})`: participation joined Books in the F1 fix, so Arena "Joined Bull/Bear" follows the persona.
- `OrderIntent.sourceCallId`, `OrderIntent.sourceAuthorHandle` (set by the Home feed card and `CallerPlayScreen`, id `'<handle>/<ticker>'`).
- `const kCopyFeeCents = 500`; `Scenario.copyFeeCents(intent)` (0 for no source or own call); `problem()` and `maxMarginCents(..., copyFeeCents:)` count it.
- `FeeKind { credit, copyFee }`; `FeeEntry` gains `kind`, `sourceCallId`, `counterparty`, `asset`; `Scenario.copyFees` getter (ledger copy section; `marketFees` stays credits only).
- `OrderReceipt.copyFeeCents`, `.sourceCallId`, `.sourceAuthorHandle`; `totalCents = margin + fee + copyFee`; `copyLine(author, cents)` → "Copying @<handle> · $5.00 copy fee" on review, filled sheet and Receipts.
- Settings "Demo persona" row above Reset demo, value Creator/Copier, toast "Now acting as <handle>". Top bar and Settings header name the active persona (F3; `SettingsMock.handle` deleted).
- Ledger: "COPY FEES" section, rows `Copy fee · @<copier> · <asset>`, Total = market credits + copy fees; empty state only when both are empty (F2).

## Decisions made during the run
- One fee ledger, the creator's: a copier's confirmed copy of ANY author's call credits it with one copyFee row (spec text; manager ruling R1).
- The creator copying someone else's call pays the $5.00 but writes no ledger row (no self-credit); pinned by F8.
- Participation is per persona, swapped with the books (F1).
- Wallet "Fees from your market" row and Your-market chip stay market credits only (spec 06); only their comments changed (F2).
- Review R2 refuted the work baton's claim that the copier cannot copy maya's call: Asset trade › Callers › "Open maya.eth's play" works in-app.
- Three existing tests moved by $5.00 because the creator opening kaito.eth's call is now a copy (accepted file-budget overrun).

## Carried forward for the user
- Design question: should the creator ledger earn on copies of calls she did not make (e.g. kaito.eth)? Today it does, by ruling; the COPY FEES code comment (receipt_screens.dart) still says copiers paid to copy the creator's calls.
- Two "fees" figures differ once a copy lands: ledger Total includes copy fees, Wallet row and chip do not (spec 06 by design; worth a label check).
- Residual (dw lanes): `sourceCallId` is 'handle/ticker', not unique per call; copy row `marketId` when the creator is unlisted; actionId guard scans only the active persona's books.
- Residual: identity surfaces beyond top bar/Settings (Your market header "maya.eth · your market", trader-record panels) stay creator-named; Portfolio "Fees from your market" shows the creator's earnings to the copier (design choice, sub-claim refuted).
- Residual: pre-existing Max rounding (marginCents from units*price) can push a 100% stake 1 cent over cash; no device run at 1.3x for the new rows.
- Known defect, not this run's: Wallet market-cap toggle shows the seeded $44.0M market after creating a new market at $10,000.

## Deliberately not built
- Scenario-phase advance (O-10, P1): not built. Never mark it Built.
- Automatic copy execution, any payment rail, variable fee, copier-side earnings, trader-index tickets (VC-MKT-005).

Records: `docs/reviews/2026-10-05-dw-review-copy-story.md`, `review-phase-1-dw.json`, `fixer-phase-1.json`, closing baton in `baton-pass/br-2026-10-05-copy-story/`.
