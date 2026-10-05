# Review iter 2 mutation runner: applies one exact-text mutant at a time to a
# throwaway copy of app/ (mut-app/), runs the named tests, restores the file.
import subprocess, sys, pathlib, re
ROOT = pathlib.Path(__file__).parent / "mut-app"
MUTANTS = [
    ("H1-revert-isScrollControlled",
     [("lib/features/trade/order_ticket.dart", "            isScrollControlled: true,\n", ""),
      ("lib/features/trade/feed_order_ticket.dart", "      isScrollControlled: true,\n", "")],
     [("test/home_screen_test.dart", ["--name", "(applies leverage|leverage applies) at 1.3x text"])]),
    ("AC3-blank-simulated-label",
     [("lib/features/trade/order_ticket.dart", "Text('Simulated — no real order', style: muted)", "Text('', style: muted)")],
     [("test/order_ticket_test.dart", ["--plain-name", "double tap confirm places one position"])]),
    ("AC1-AC2-no-pill-in-builder",
     [("lib/main.dart", "child: SimulationIndicator(navigator: _navigator, child: child!),", "child: child!,")],
     [("test/home_screen_test.dart", ["--plain-name", "simulation indicator"]),
      ("test/scenario_test.dart", ["--plain-name", "the simulated pill explains itself"])]),
    ("AC1-AC2-no-padding-reserve",
     [("lib/features/simulation/simulation_indicator.dart", "bottom: mq.padding.bottom + SimulationIndicator.slot,", "bottom: mq.padding.bottom,")],
     [("test/home_screen_test.dart", ["--plain-name", "simulation indicator"])]),
    ("M2-no-popUntil",
     [("lib/features/simulation/simulation_indicator.dart", "  Navigator.of(context).popUntil((route) => route.isFirst);\n", "")],
     [("test/home_screen_test.dart", ["--plain-name", "Reset demo from the pill"]),
      ("test/scenario_test.dart", ["--plain-name", "the simulated pill explains itself"])]),
]
only = sys.argv[1:] 
for name, edits, runs in MUTANTS:
    if only and name not in only:
        continue
    saved = {}
    for path, old, new in edits:
        p = ROOT / path
        saved.setdefault(path, p.read_text())
        text = p.read_text()
        n = text.count(old)
        assert n >= 1, f"{name}: pattern not found in {path}"
        p.write_text(text.replace(old, new))
        print(f"[{name}] {path}: replaced {n} occurrence(s)")
    try:
        for test, args in runs:
            r = subprocess.run(["flutter", "test", test, *args], cwd=ROOT, capture_output=True, text=True)
            out = r.stdout + r.stderr
            (pathlib.Path(__file__).parent / f"mut-{name}-{pathlib.Path(test).stem}.log").write_text(out)
            last = [l for l in out.splitlines() if re.search(r"\+\d+.*(All tests passed|Some tests failed|tests? failed)", l)]
            fails = sorted(set(m.group(1) for m in re.finditer(r"^.*?: (.+) \[E\]$", out, re.M)))
            print(f"[{name}] {test} exit={r.returncode} :: {last[-1].strip() if last else out.splitlines()[-1]}")
            for f in fails:
                print(f"    FAILED: {f}")
    finally:
        for path, text in saved.items():
            (ROOT / path).write_text(text)
        print(f"[{name}] restored")
