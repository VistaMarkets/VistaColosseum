# Phase 6 review iter 1 mutation runner: applies one exact-text mutant at a
# time to the throwaway copy mut-app/, runs the named tests, logs, restores.
# Usage: python3 mutate.py [mutant names...]
import subprocess, sys, pathlib
HERE = pathlib.Path(__file__).parent
ROOT = HERE / "mut-app"
RS = "lib/features/market/receipt_screens.dart"
MM = "lib/features/make_market/make_market_flow.dart"
PS = "lib/features/profile/profile_screen.dart"
TM = "lib/features/market/trader_market_screen.dart"
PF = "lib/features/portfolio/portfolio_screen.dart"
YM = "lib/features/market/your_market_screen.dart"
SC = "lib/scenario/scenario.dart"
RT = ["test/receipts_test.dart"]
RST = ["test/receipts_test.dart", "test/scenario_test.dart"]
MUTANTS = [
  ("forholding-ignores-open", RT, [(RS, "          c.side == holding.side &&\n          c.result == CallOutcome.open) {", "          c.side == holding.side) {")]),
  ("record-item-opens-first", RT, [(RS, "Navigator.of(context).push(CallReceiptScreen.route(receipt)),", "Navigator.of(context).push(CallReceiptScreen.route(Scenario.callReceipts.value.first)),")]),
  ("ledger-footer-no-safe", RT, [(RS, "MediaQuery.paddingOf(context).bottom + VistaSpace.xxl,", "VistaSpace.xxl,")]),
  ("listing-label-dropped", RT, [(MM, "                        YourMarketMock.shareLabel,", "                        '',")]),
  ("ledger-label-dropped", RT, [(RS, "'Illustrative demo ledger · ${YourMarketMock.shareLabel}',", "'Illustrative demo ledger',")]),
  ("example-not-backed-out", RT, [(RS, "final fee = e.amountCents * 100 ~/ pct;", "final fee = e.amountCents;")]),
  ("profile-wrong-handle", RT, [(PS, ".push(CallReceiptScreen.forHolding(widget.handle, h)),", ".push(CallReceiptScreen.forHolding(PortfolioMock.handle, h)),")]),
  ("trader-wrong-handle", RT, [(TM, "CallReceiptScreen.forHolding(widget.handle, h)", "CallReceiptScreen.forHolding('maya.eth', h)")]),
  ("unavailable-blank", RT, [(RS, "value ?? unavailable,", "value ?? '',")]),
  ("receipts-ignore-author", RT, [(RS, "if (c.author == author) c,", "c,")]),
  ("wallet-row-constant", RT, [(PF, "formatCents(Scenario.marketFeesCents),", "formatCents(4280),")]),
  ("chip-constant", RT, [(YM, "value: formatCents(Scenario.marketFeesCents),", "value: formatCents(4280),")]),
  ("reset-no-callreceipts", RST, [(SC, "    callReceipts.value = YourMarketMock.record;\n", "")]),
  ("reset-no-fees", RST, [(SC, "    feeEntries.value = YourMarketMock.fees;\n", "")]),
  ("ledger-entry-amount-hidden", RT, [(RS, "                      formatCents(e.amountCents),\n", "                      e.marketId,\n")]),
  ("ledger-entry-no-market", RT, [(RS, "Text('${e.marketId} · ${_when(e.at)}', style: muted),", "Text(_when(e.at), style: muted),")]),
]
only = sys.argv[1:]
for name, tests, edits in MUTANTS:
    if only and name not in only:
        continue
    saved = {}
    for path, old, new in edits:
        p = ROOT / path
        saved.setdefault(path, p.read_text())
        text = p.read_text()
        n = text.count(old)
        assert n == 1, f"{name}: pattern count {n} in {path}"
        p.write_text(text.replace(old, new))
    try:
        r = subprocess.run(["flutter", "test", *tests], cwd=ROOT, capture_output=True, text=True)
        out = r.stdout + r.stderr
        (HERE / f"mut-{name}.log").write_text(out)
        last = [l for l in out.splitlines() if l.strip()][-1:] 
        verdict = "KILLED" if r.returncode != 0 else "SURVIVED"
        print(f"{name}: {verdict} (exit {r.returncode}) :: {last[0][:160] if last else ''}", flush=True)
    finally:
        for path, text in saved.items():
            (ROOT / path).write_text(text)
