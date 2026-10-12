# Presenter checklist: run on WSL

The full demo run, done on WSL instead of a Mac. The iOS Simulator only runs on macOS, so this run uses the app's Linux desktop build in a phone-sized window. The steps are the [rehearsal protocol](rehearsal-protocol.md)'s 41 steps, plus one extra check in section 3.

## 1. Set up

- [ ] Start a screen recording of the app window before step 1. Use Xbox Game Bar (`Win+Alt+R`) or OBS on the Windows side.
- [ ] Update `main` and note the build:

```bash
cd ~/VistaColosseum && git pull --ff-only && git rev-parse --short HEAD
```

- [ ] Launch the app with no flags, so the run lists the market from scratch:

```bash
cd ~/VistaColosseum/app && flutter run -d linux --release
```

- [ ] Write down: the build hash, the date and start time, and the target, "Linux desktop (WSLg), 402×874 window, not the iOS Simulator".

**Mouse and keyboard:** click to tap and type with the keyboard. Click and drag to swipe (pagers, sliders, sheet handles). The scroll wheel also scrolls lists.

## 2. Run the protocol

Tick each group once every step in it matches the protocol. When a step doesn't match, write down the step number and what you saw, then keep going.

- [ ] **Setup, steps 1–3:** Reset demo; Simulate load failure; Explore fails, then Retry recovers.
- [ ] **J1 browse, steps 4–9:** For You vs Following; card pager; Like and People in; Details; kilo.sol profile Follow; the two Maker cards.
- [ ] **J2 list a market, steps 10–17:** Wallet spans and Deposit; Make a market validation (blank, BTC taken, MAYA); consent; Close leaves nothing; create $MAYA; balance pager; Your market at $10,000.
- [ ] **maya.eth's market everywhere (after step 17):** see section 3.
- [ ] **J3 Arena, steps 18–24:** three battles; sorts; crowd-split slider down to 2, then empty, then Show all; Ask SOL, DOGE, Clear search; more opinions; caller profile.
- [ ] **J4 order, steps 25–32:** cancel adds nothing; double-click Confirm fills once; Wallet, receipts and Arena "Joined Bull" agree; the Explore ETH fill doesn't join; step 32's totals reconcile.
- [ ] **Copy story, steps 33–37:** switch to the copier; copy kilo.sol's SOL call with the $5.00 fee; switch back; the ledger shows one $5.00 copy row.
- [ ] **J5 outcomes, steps 38–41:** call receipt; kilo.sol profile and trader market; position sheet Close.

## 3. Extra check

- **After step 17 (PR #41):** maya.eth's market reads $10,000 and $0.0001 in the Explore → Traders row, on her Trader market (flat line) and on her Profile's market block. Home shows no deltaone call on her market.

The protocol's steps 15, 33 and 37 were updated on October 12 to match the current build.

## 4. Say these out loud on the recording

- [ ] "Everything here is simulated. No order, listing or payment leaves the device."
- [ ] "The $5 copy fee, the market cap and the 40% creator share are invented for this demo."

## 5. After the run

- [ ] Stop the recording and note where the file is saved.
- [ ] Run the seeded-market check, which the protocol covers with a test instead of a live run:

```bash
cd ~/VistaColosseum/app && flutter test --dart-define=HAS_MARKET=true
```

- [ ] Note the build hash, the start time, the recording's location, and every step that didn't match. The verification record is written from these notes.

## Not covered by this run

- The iOS Simulator itself. If the submission requires iOS, the run has to be repeated on a Mac.
- VC-QA-001's other window sizes (375×667) and 1.3× text size.
