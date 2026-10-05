# Phase 4 review iter 1 mutation runner: applies one exact-text mutant at a
# time to a throwaway copy of app/ (mut-app/), runs the named tests, restores.
# Usage: python3 mutate.py [mutant names...]
import subprocess, sys, pathlib, re
HERE = pathlib.Path(__file__).parent
ROOT = HERE / "mut-app"
H = "test/home_screen_test.dart"
S = "test/scenario_test.dart"
AM = "lib/features/arena/arena_mock.dart"
AS = "lib/features/arena/arena_screen.dart"
OP = "lib/features/arena/opinions_screen.dart"
CP = "lib/features/arena/crowd_filter_panel.dart"
SC = "lib/scenario/scenario.dart"
SORT = (H, ["--plain-name", "sort chips order the battles by volume, change and funding"])
RANGE = (H, ["--plain-name", "the crowd range filters the cards and the panel counts them"])
EMPTY = (H, ["--plain-name", "an empty crowd split says so; Show all restores the cards"])
ASK = (H, ["--plain-name", "Ask filters by asset; no match names the assets there are"])
JOINW = (H, ["--plain-name", "joining: Cancel counts nothing; a fill counts once, shows"])
JOINS = (S, ["--plain-name", "a clash fill joins its side once per action; a failure joins none"])
AC2 = (H, ["--plain-name", "a battle's opinions trade that battle's asset and clash"])
LABEL = (H, ["--plain-name", "the crowd split is labelled crowd split, never odds"])
ARENA = (H, ["--plain-name", "Arena tab shows the battles with the crowd filter"])
SALL = (S, [])
MUTANTS = [
  ("sort-no-tiebreak", [(AM, "return c != 0 ? c : a.id.compareTo(b.id);", "return c;")], [SORT]),
  ("sort-chips-all-volume", [(AM, "1 => b.changePct,", "1 => b.volume,"), (AM, "2 => b.fundingPct,", "2 => b.volume,")], [SORT]),
  ("buckets-constant", [(AM, "counts[b.bucket]++;", "counts[0]++;")], [RANGE]),
  ("list-ignores-range", [(AM, "if (b.bucket >= v.from && b.bucket < v.to) b,", "b,")], [RANGE, EMPTY]),
  ("panel-counts-all", [(CP, "final count = ArenaMock.visible(view).length;", "final count = ArenaMock.battles.length;")], [RANGE]),
  ("show-all-noop", [(AS, "Scenario.setArena(from: 0, to: ArenaMock.bucketCount),", "Scenario.setArena(),")], [EMPTY]),
  ("ask-no-filter", [(AM, "if (b.asset.contains(q)) b,", "b,")], [ASK]),
  ("ask-field-ignores-reset", [(AS, "if (_ask.text != q) _ask.text = q;", "")], [ASK]),
  ("arena-no-clashId", [(AS, "showOrderTicket(context, symbol: b.asset, side: side, clashId: b.id);", "showOrderTicket(context, symbol: b.asset, side: side);")], [JOINW]),
  ("card-ignores-joins", [(AS, "'and ${seeded + Scenario.joins(b.id, side)}';", "'and $seeded';")], [JOINW]),
  ("joins-ignore-side", [(SC, ".where((r) => r.clashId == clashId && r.side == side)", ".where((r) => r.clashId == clashId)")], [JOINS]),
  ("no-participation-write", [(SC, "if (intent.clashId case final clash?) {", "if (intent.clashId case final clash? when clash.isEmpty) {")], [JOINS, JOINW]),
  ("replay-not-deduped", [(SC, "if (r.id == id) return OrderFilled(r);", "if (r.id == id && id.isEmpty) return OrderFilled(r);")], [JOINS]),
  ("failure-joins", [(SC, "    final problem = Scenario.problem(intent);\n", "    if (intent.clashId case final c?) {\n      participation.value = {...participation.value, c: intent.side};\n    }\n    final problem = Scenario.problem(intent);\n")], [JOINS]),
  ("opinions-hardcode-btc", [(OP, "symbol: b.asset,", "symbol: 'BTC',")], [AC2]),
  ("opinions-no-clashId", [(OP, "                clashId: b.id,\n", "")], [AC2]),
  ("label-header", [(OP, "'Crowd split $bull% bull'", "'$bull% bull'")], [LABEL]),
  ("label-dock", [(OP, "'Crowd split · $opinionCount opinions'", "'$opinionCount opinions'")], [LABEL]),
  ("label-panel", [(CP, "return 'Crowd split $lo/${100 - lo} +';", "return '$lo/${100 - lo} +';")], [ARENA]),
  ("reset-keeps-arena", [(SC, "    arena.value = ArenaMock.allBattles;\n  }", "  }")], [SALL]),
  ("reset-keeps-participation", [(SC, "    participation.value = const {};\n", "")], [SALL]),
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
        print(f"[{name}] {path}: replaced {n}")
    try:
        for test, args in runs:
            r = subprocess.run(["flutter", "test", test, *args], cwd=ROOT, capture_output=True, text=True)
            out = r.stdout + r.stderr
            (HERE / f"mut-{name}-{pathlib.Path(test).stem}.log").write_text(out)
            last = [l for l in out.splitlines() if re.search(r"(All tests passed|Some tests failed|No tests ran)", l)]
            fails = sorted(set(m.group(1) for m in re.finditer(r"^\d\d:\d\d \+\d+(?: ~\d+)? -\d+: (.+) \[E\]$", out, re.M)))
            exp = [l.strip() for l in out.splitlines() if re.match(r"\s*(Expected|Actual|Error):", l)][:2]
            verdict = "KILLED" if r.returncode != 0 else "SURVIVED"
            print(f"[{name}] {verdict} {test} exit={r.returncode} :: {last[-1].strip()[-60:] if last else out.splitlines()[-1][-60:]}")
            for f in fails: print(f"    FAILED: {f[-110:]}")
            for e in exp: print(f"    {e[:160]}")
    finally:
        for path, text in saved.items():
            (ROOT / path).write_text(text)
        print(f"[{name}] restored")
