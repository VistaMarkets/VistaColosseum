# Phase 7 review iter 1 mutation runner: applies one exact-text mutant at a
# time to the throwaway copy mut-app/, runs the whole suite, logs, restores.
# Usage: python3 mutate.py [mutant names...]
import subprocess, sys, pathlib
HERE = pathlib.Path(__file__).parent
ROOT = HERE / "mut-app"
RS = "lib/features/market/receipt_screens.dart"
PS = "lib/features/profile/profile_screen.dart"
PP = "lib/features/profile/private_profile_screen.dart"
TM = "lib/features/market/trader_market_screen.dart"
YM = "lib/features/market/your_market_screen.dart"
SC = "lib/scenario/scenario.dart"
ALL = ["test/"]
MUTANTS = [
  ("panel-stats-row-overflows", ALL, [(RS, "            Wrap(\n              spacing: VistaSpace.xl,\n              children: [\n                for (final (text, color) in [", "            Row(\n              children: [\n                for (final (text, color) in [")]),
  ("panel-ignores-clock", ALL, [(RS, "listenable: Listenable.merge([Scenario.callReceipts, Scenario.clock]),", "listenable: Scenario.callReceipts,")]),
  ("profile-header-settled-const", ALL, [(PS, "child: VistaCountStat(value: '${m.settled}', label: 'Settled'),", "child: VistaCountStat(value: '62', label: 'Settled'),")]),
  ("profile-header-right-const", ALL, [(PS, "child: VistaCountStat(value: '${m.right}', label: 'Right'),", "child: VistaCountStat(value: '36', label: 'Right'),")]),
  ("private-header-const", ALL, [(PP, "                    value: '${m.settled}',", "                    value: '62',")]),
  ("trader-open-calls-const", ALL, [(TM, "    final n = Scenario.record(widget.handle).open;", "    const n = 9;")]),
  ("your-market-panel-wrong-handle", ALL, [(YM, "const TraderRecordPanel(handle: PortfolioMock.handle),", "const TraderRecordPanel(handle: 'kilo.sol'),")]),
  ("private-panel-wrong-handle", ALL, [(PP, "        TraderRecordPanel(handle: widget.handle),", "        const TraderRecordPanel(handle: 'kilo.sol'),")]),
  ("profile-chart-gate-on-any-call", ALL, [(PS, "          if (Scenario.record(widget.handle).settled > 0) ...[", "          if (Scenario.record(widget.handle).settled + Scenario.record(widget.handle).open > 0) ...[")]),
  ("trader-market-panel-dropped", ALL, [(TM, "        TraderRecordPanel(handle: widget.handle),\n        CallRecordList(author: widget.handle),", "        CallRecordList(author: widget.handle),")]),
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
        fails = [l for l in out.splitlines() if l.rstrip().endswith("[E]")]
        comp = "Error: " in out and "Compilation failed" in out
        verdict = "KILLED" if r.returncode != 0 else "SURVIVED"
        print(f"{name}: {verdict} (exit {r.returncode}){' COMPILE-ERROR' if comp else ''} fails={len(fails)} :: {fails[0][:150] if fails else ''}", flush=True)
    finally:
        for path, text in saved.items():
            (ROOT / path).write_text(text)
for path in {RS, PS, PP, TM, YM, SC}:
    a = (ROOT / path).read_bytes(); b = (HERE / "../../../app" / path).read_bytes()
    assert a == b, f"restore mismatch {path}"
print("restore byte-check OK")
