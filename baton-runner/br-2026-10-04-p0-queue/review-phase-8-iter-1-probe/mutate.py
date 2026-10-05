# Phase 8 review iter 1 mutation runner: one exact-text mutant at a time in the
# throwaway copy mut-app/, runs the named tests, logs, restores.
# Usage: python3 mutate.py [--all] [mutant names...]
import subprocess, sys, pathlib
HERE = pathlib.Path(__file__).parent
ROOT = HERE / "mut-app"
ST = "lib/features/settings/settings_screen.dart"
RS = "lib/features/market/receipt_screens.dart"
ES = "lib/design_system/components/vista_empty_state.dart"
PS = "lib/features/profile/profile_screen.dart"
AR = "lib/features/arena/arena_screen.dart"
ROW = """                    // Presenter-only: fails the Explore list until Retry.
                    VistaSettingRow(
                      title: 'Simulate load failure',
                      subtitle: 'Explore markets list',
                      trailing: VistaSwitch(
                        value: Scenario.marketsLoadFails.value,
                        semanticLabel: 'Simulate load failure',
                        onChanged: (on) => Scenario.marketsLoadFails.value = on,
                      ),
                    ),
"""
MUTANTS = [
  ("switch-not-beside-reset", [(ST, ROW, ""), (ST, "                  children: [\n                    _account(),", "                  children: [\n" + ROW + "                    _account(),")]),
  ("receipts-paper-plain-text", [(RS, """                VistaEmptyState(
                  message: 'No paper orders yet',
                  actionLabel: 'Explore markets',
                  onAction: () => AppShell.showExplore(context),
                ),""", "                Text('No paper orders yet', style: VistaType.bodyRegular),")]),
  ("empty-state-overflows", [(ES, "      child: Column(\n        mainAxisSize: MainAxisSize.min,", "      child: Row(\n        mainAxisSize: MainAxisSize.min,")]),
  ("empty-line-overflows", [(ES, "          Text(message, textAlign: TextAlign.center, style: VistaType.subhead),", "          Row(children: [Text(message, textAlign: TextAlign.center, style: VistaType.subhead)]),")]),
  ("reset-keeps-toggle", [("lib/scenario/scenario.dart", "    marketsLoadFails.value = false;\n  }", "  }")]),
  ("retry-noop", [("lib/features/markets/markets_screen.dart", "onAction: () => Scenario.marketsLoadFails.value = false,", "onAction: () {},")]),
  ("failure-leaks-to-arena", [(AR, "    final shown = ArenaMock.visible(view);", "    final shown = Scenario.marketsLoadFails.value ? <Battle>[] : ArenaMock.visible(view);")]),
  ("profile-list-ignores-strip", [(PS, "bottom: MediaQuery.paddingOf(context).bottom + 24,", "bottom: 0,")]),
  ("arena-clear-search-noop", [(AR, "onAction: () => Scenario.setArena(query: ''),", "onAction: () {},")]),
]
args = sys.argv[1:]
full = "--all" in args
only = [a for a in args if a != "--all"]
tests = ["test/"] if full else ["test/empty_states_test.dart", "test/scenario_test.dart"]
for name, edits in MUTANTS:
    if only and name not in only:
        continue
    saved = {}
    try:
        for path, old, new in edits:
            p = ROOT / path
            saved.setdefault(path, p.read_text())
            text = p.read_text()
            n = text.count(old)
            assert n == 1, f"{name}: pattern count {n} in {path}"
            p.write_text(text.replace(old, new))
        r = subprocess.run(["flutter", "test", *tests], cwd=ROOT, capture_output=True, text=True)
        out = r.stdout + r.stderr
        (HERE / f"mut-{name}{'-all' if full else ''}.log").write_text(out)
        fails = [l for l in out.splitlines() if l.rstrip().endswith("[E]")]
        comp = "Compilation failed" in out
        verdict = "KILLED" if r.returncode != 0 else "SURVIVED"
        last = [l for l in out.splitlines() if "tests passed" in l or "tests failed" in l][-1:]
        print(f"{name}: {verdict} (exit {r.returncode}){' COMPILE-ERROR' if comp else ''} fails={len(fails)} {last} :: {[f[:160] for f in fails[:3]]}", flush=True)
    finally:
        for path, text in saved.items():
            (ROOT / path).write_text(text)
for path in {ST, RS, ES, PS, AR, 'lib/scenario/scenario.dart', 'lib/features/markets/markets_screen.dart'}:
    a = (ROOT / path).read_bytes(); b = (HERE / "../../../app" / path).read_bytes()
    assert a == b, f"restore mismatch {path}"
print("restored OK")
