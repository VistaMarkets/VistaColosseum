# User rulings, October 12

The Oct 7 records ([M2–M4](2026-10-07-m2-m4-reverification.md), [M5](2026-10-07-m5-participation-and-copy.md)) held several rows as "misrepresents a financial action" until the user ruled. The user ruled on 2026-10-12. Each ruling below settles the rows named, which change class as stated. Rows that turn on code fixed in this change are noted.

Earlier ruling, Oct 9: maya.eth's trader market is the market the user lists (PR #41, closes #29).

| # | Question | Ruling | Rows settled | New class |
|---|---|---|---|---|
| 1 | Who is "the creator" paid by a copy fee (VC-CPY-002)? | The creator persona, maya.eth. Every copy fee credits her ledger, whoever authored the copied call. The PRD is amended to say so | M5 VC-CPY-002 creator row and copy-fee payee defect; the copy-story end-to-end row that rests on it | Resolved: behavior is as built |
| 2 | Should the creator persona pay a copy fee when she copies another trader's call? | Yes. She pays $5.00 and no ledger is credited. Accepted demo behavior | M5 creator-persona copy defect | Resolved: accepted as built |
| 3 | Do copy fees paid before a listing belong in the new listing's ledger? | Yes. The ledger is the creator's earnings, not only the market's | M5 pre-listing copy fees defect | Resolved: accepted as built |
| 4 | What does the copier's Wallet show of the creator's market? | Keep the row, labelled as maya.eth's market. The copier is not offered "Make a market" | M5 copier's Wallet defect | Fixed on `fix/copier-wallet-label`: the pill reads "maya.eth's market" and the fees line "Fees from maya.eth's market" for the copier; `copy_story_test.dart` "the copier's Wallet labels the market as the creator's and offers no listing (Oct 12 ruling)" |
| 5 | Does J4's "one review flow" cover limit and stop orders? | No. It covers market orders; limit and stop orders may rest without review (VC-ORD-001 defers advanced tickets) | M5 J4 exit criterion and the limit/stop defect | J4 exit criterion: passed on market orders. Defect: resolved |
| 6 | Do fixture figures count as misrepresenting a financial action? | No. They are demo content, covered by the simulation indicator (VC-DEM-003) and the presenter's explanation | M2–M4 rows: other traders' market and Profile figures, a fresh listing's seeded activity, Arena caller prices, fixture verdicts | Cosmetic |

## What still blocks exit

- **M2:** the first-call exit criterion and VC-LST-004 are fixed on `fix/first-call-fixture`: "Make your first call" opens a sheet saying posting calls is outside the demo and nothing was published, with "See a sample call" opening kilo.sol's seeded call receipt (`home_screen_test.dart` "the listing success step opens Your market for the new listing"). Four cosmetic `failed` rows remain. J1 and J2 not run on the Simulator.
- **M3:** VC-MKT-001's out-of-set screens until PR #41 merges. J2 and J5 not run on the Simulator.
- **M4:** the user removed the video-only-labels exit criterion on Oct 12, to be added later; spec 04's labels are deferred, not failed. No rehearsal.
- **M5:** the Simulator run of J1–J5 plus the copy story from reset, and the presenter's statement that the fee is invented, are `not run`.

No row of class "misrepresents a financial action" remains open once PR #41 merges.
