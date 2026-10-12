# VistaColosseum

<p align="center">
  <picture>
    <source srcset="docs/assets/vista-logo-static.png" media="(prefers-reduced-motion: reduce)" />
    <source srcset="docs/assets/vista-logo-animated.gif" type="image/gif" />
    <img src="docs/assets/vista-logo-static.png" alt="Vista logo" width="240" height="240" />
  </picture>
</p>

**An arena for trading talent.**

VistaColosseum brings the energy of spectator sports to social trading.
Traders put their convictions on display, spectators follow the rivalries,
and settled results build the record behind every reputation.

**This repository is a hackathon demo.** Every price, order, balance, fee and
result in it is simulated. Nothing leaves the device, no real money moves, and
the app never connects to a backend or a blockchain.

## What the demo shows

| Journey | What you can do |
|---|---|
| J1 — discover a call | Browse the Home feed (For You and Following), replay a call, open its asset market and the trader's profile. Maker suggestions are labelled as advisory. |
| J2 — become a listed creator | Make a market from the Wallet: pick a ticker, agree to the listing terms, and see one consistent market cap ($10,000) on every screen. |
| J3 — understand a clash | In the Arena, sort battles, filter by crowd split, ask about a market, and read more opinions. |
| J4 — take a side | Place a simulated market order through one review screen. Cancel adds nothing, and a double-click fills once. Wallet, receipts and the Arena agree. |
| J5 — explain outcomes | Read a call receipt, a trader's record and the fee ledger. A call's verdict, trading P&L and fee income are three separate figures. |
| Copy story | Switch to a second persona, copy a call, and watch a $5.00 demo copy fee land in the creator's ledger. |

Two personas: **maya.eth**, the creator ($12,480.00 paper cash), and
**sam.sol**, the copier ($1,000.00). Switch between them in Settings → Demo
persona.

## Run it

You need Flutter 3.47 stable. From the repository root:

```bash
cd app && flutter pub get
```

On a Mac with Xcode, in the iOS Simulator:

```bash
cd app && flutter run
```

On Linux (including WSL), as a desktop app in a phone-sized window:

```bash
cd app && flutter run -d linux --release
```

To start with the creator's market already listed:

```bash
cd app && flutter run --dart-define=HAS_MARKET=true
```

**Reset:** Wallet → Settings (gear) → **Reset demo**. You can also tap the
"Simulated · fixture-v1" pill at the bottom of any screen. Reset restores
every balance, position, order and listing to the fixture.

**Input on a computer:** click to tap, click and drag to swipe, and use the
scroll wheel and keyboard.

## Tests

```bash
scripts/gate.sh /tmp/gate-logs
```

This runs `flutter analyze`, the full widget and unit test suite (348 tests),
and a check that dependencies are unchanged. It prints `GATE: PASS` or `GATE: FAIL`.

## Evidence

| Document | What it is |
|---|---|
| [Verification index](docs/verification/README.md) | Every milestone record, and which one is current |
| [Rehearsal 1](docs/verification/m6-rehearsal-1.md) | The full 41-step run from reset. Every step passed |
| [Rulings, Oct 12](docs/verification/2026-10-12-user-rulings.md) | How the demo's money rules were decided |
| [Master PRD](docs/prd/2026-10-01-vc-hackathon-master-prd.md) | Scope, requirements and acceptance criteria |
| [Roadmap](docs/prd/2026-10-01-vc-hackathon-roadmap.md) | Milestones and their current status |
| [Specs](docs/specs/README.md) | One spec per built feature, with its pull request |
| [ARCH.md](ARCH.md) | File-by-file map of the repository |

## Known limitations

- **Everything is simulated.** The market cap, token supply, 40% creator share
  and $5.00 copy fee are invented for the demo narrative. They do not describe
  the product's real economics.
- **Fixture figures are demo content.** Other traders' market figures, Arena
  caller prices (fixed at session open) and a new market's seeded holder counts
  come from the fixture and do not move with the live demo prices.
- **Not built:** posting your own calls (the first-call button offers a sample
  call instead), scripted challenge and settlement progression, a
  scenario-phase control, and the trader-index ticket. All are deferred.
- **Limit and stop orders** rest in Open orders without the review screen.
  Only market orders go through review.
- **Not yet verified:** the second rehearsal, the 390×844 and 375×667
  viewport checks at 1.3× text, and Figma design fidelity.
- **Target:** rehearsal 1 ran as a Linux desktop app on WSL. The iOS
  Simulator run is from October 5 (milestone M1).

The full list, including small cosmetic issues, is in the
[verification index](docs/verification/README.md#known-limitations).

## The product vision

The demo is one slice of a larger product:

- **Arena.** Discover traders and opposing market calls in a mobile-first clash feed.
- **Tradefeed.** Maker turns market data from Aggro into suggested orders for
  users to review. Merchant handles the purchase.
- **Record.** Every trader's history of settled calls, open to inspection.
- **TPX, the Trader Performance Exchange.** Long and short positions on trader
  performance indices, built from settled results.
- **Market.** Traders share orders for others to copy, and can earn from the copies.
