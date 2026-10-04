#!/usr/bin/env bash
# Deterministic quality gate for baton-runner review units.
#
# Usage: scripts/gate.sh <log-dir>
#   Runs the repo's checks, tees each to <log-dir>, prints GATE: PASS|FAIL,
#   and exits non-zero if ANY check fails. All checks run even if an earlier
#   one fails, so the review unit sees the full picture in one pass.
#
# The gate is intentionally fixed and committed: verification must be the same
# every run, not improvised per spawn. Adjust the check list here (under review)
# rather than in agent prompts.
set -uo pipefail

LOG_DIR="${1:?usage: gate.sh <log-dir>}"
mkdir -p "$LOG_DIR" || { echo "GATE: FAIL (setup error)"; exit 1; }
LOG_DIR="$(cd "$LOG_DIR" && pwd)"

# The Flutter project lives in app/; resolve it from this script's location so
# the gate runs from any cwd and the log dir may be given relative to the root.
APP_DIR="$(cd "$(dirname "$0")/../app" && pwd)" || { echo "GATE: FAIL (setup error)"; exit 1; }
cd "$APP_DIR" || { echo "GATE: FAIL (setup error)"; exit 1; }

run() {
  local name="$1" rc; shift
  echo "=== gate: ${name}: $* ==="
  "$@" >"${LOG_DIR}/${name}.log" 2>&1
  rc=$?
  # rc is captured on the line after the command, not inside an `if`: a failed
  # if-condition whose branch doesn't run resets $? to 0, reporting every
  # failure as "exit 0".
  if [ "$rc" -eq 0 ]; then
    echo "PASS ${name}"
    return 0
  fi
  echo "FAIL ${name} (exit ${rc}) -> ${LOG_DIR}/${name}.log"
  return 1
}

fail=0
run flutter-analyze flutter analyze || fail=1
run flutter-test    flutter test    || fail=1
run pubspec-frozen  git diff --exit-code "$(git merge-base HEAD origin/main)" -- pubspec.yaml pubspec.lock || fail=1

echo "----"
if [ "${fail}" -eq 0 ]; then
  echo "GATE: PASS"
else
  echo "GATE: FAIL"
fi
exit "${fail}"
