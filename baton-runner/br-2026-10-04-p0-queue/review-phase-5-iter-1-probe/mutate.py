# Phase 5 review iter 1 mutation runner: applies one exact-text mutant at a
# time to a throwaway copy of app/ (mut-app/), runs the `maker suggestion`
# group (plus the home suite where noted), logs, restores byte-identical.
# Usage: python3 mutate.py [mutant names...]
import subprocess, sys, pathlib
HERE = pathlib.Path(__file__).parent
ROOT = HERE / "mut-app"
MS = "lib/features/home/maker_suggestion.dart"
HS = "lib/features/home/home_screen.dart"
VF = "lib/design_system/components/vista_flow.dart"
GROUP = ["test/home_screen_test.dart", "--plain-name", "maker suggestion"]
MUTANTS = [
  ("clock-constant", [(MS, "valueListenable: Scenario.clock,", "valueListenable: ValueNotifier(TradeMock.chartEnd),")]),
  ("clock-wallclock", [(MS, "final live = s.liveAt(now);", "final live = s.liveAt(DateTime.now());")]),
  ("no-semantics-container", [(MS, "container: true,", "container: false,")]),
  ("card-overflow", [(MS, "const SizedBox(height: VistaSpace.gutter),", "const SizedBox(height: 300),")]),
  ("drop-data-path", [(MS, "Text('Built from Aggro demo prices', style: VistaType.meta),", "")]),
  ("drop-reference-line", [(MS, "              Text(\n                'Reference ${s.referencePrice} · '\n                '${live ? 'expires in ${_span(left)}' : 'expired ${_span(-left)} ago'}',\n                style: VistaType.meta,\n              ),\n", "")]),
  ("suggestions-adjacent", [(HS, "  makerSuggestions[0],\n  mockFeed[2],\n  makerSuggestions[1],", "  makerSuggestions[0],\n  makerSuggestions[1],\n  mockFeed[2],")]),
  ("both-live", [(MS, "TradeMock.chartEnd.subtract(const Duration(hours: 2))", "TradeMock.chartEnd.add(const Duration(hours: 2))")]),
  ("wrong-asset", [(HS, "symbol: item.asset,", "symbol: 'ETH',")]),
  ("badge-text", [(MS, "label: 'Maker suggestion · advisory',", "label: 'Maker suggestion',")]),
  ("expired-says-trade-this", [(MS, "label: live ? 'Trade this' : 'Expired',", "label: 'Trade this',")]),
  ("clock-write-on-trade", [(MS, "onPressed: onTrade,", "onPressed: () { Scenario.clock.value = Scenario.clock.value.add(const Duration(minutes: 1)); onTrade(); },")]),
  ("vpb-ignores-enabled", [(VF, "onTap: enabled ? onPressed : null,", "onTap: onPressed,")]),
]
only = sys.argv[1:]
for name, edits in MUTANTS:
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
        r = subprocess.run(["flutter", "test", *GROUP], cwd=ROOT, capture_output=True, text=True)
        out = r.stdout + r.stderr
        (HERE / f"mut-{name}.log").write_text(out)
        tail = [l for l in out.splitlines() if "[E]" in l or "Expected:" in l or "Actual:" in l or "Error:" in l or "All tests passed" in l or "Some tests failed" in l]
        print(f"=== {name}: rc={r.returncode} {'KILLED' if r.returncode else 'SURVIVED'}")
        for l in tail[:8]:
            print("   ", l[:220])
    finally:
        for path, text in saved.items():
            (ROOT / path).write_text(text)
