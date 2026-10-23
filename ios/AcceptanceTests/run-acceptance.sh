#!/usr/bin/env bash
# 受け入れテスト（Acceptance.xctestplan。構成 ja_JP と en_US の2つの回）を再試行なしで1回動かし、終わったら要約を出す。
# 使い方（CLAUDE.md の ios_test。ios/ の中で動かす）：bash AcceptanceTests/run-acceptance.sh 'iPhone 17'
# なぜ：CI のログは末尾 5,000 行しか取れず、先に走る回（ja_JP）の失敗の文言と [AT-DIAG] が切れる
#   （docs/verification/001-reading-session/ci-runs/c9e7427-acceptance.md）。そこで xcodebuild の出力を全部
#   <結果の場所>/Acceptance.log に tee で残し、最後に要約を標準出力に出して、両方の回の失敗の文言がログの末尾に残るようにする。
# 要約（「=== ACCEPTANCE SUMMARY ===」から「=== END ACCEPTANCE SUMMARY ===」まで）：
#   a. 回の区切りと件数（Test Suite の started／passed／failed と Executed の行。xcodebuild は構成の名前を出さないので、回は
#      最上位のスイート（Selected tests か All tests）の started で数え、[AT-DIAG] の「構成：ACCEPTANCE_LANG=」で言語を結ぶ）
#   b. 失敗の文言（「.swift:<行>: error:」の行、全件）と、落ちた Test Case の行、異常終了の行
#   c. 「Failing tests:」の節
#   d. [AT-DIAG] の行（全体で DIAG_LIMIT 行まで。超えた分は Acceptance.log にあると書く）
#   e. 落ちたテストの数と名前（c から。回ごとの内訳は b の Test Case の行から）
#   f. .xcresult の構成ごとの件数と失敗（xcrun xcresulttool で読めたときだけ。読めなくても合否は変えない）
# 再試行はしない（xcodebuild に再試行の引数を付けない。xctestplan にも testRepetitionMode を書かない）。
# 終了コード：xcodebuild の終了コードをそのまま返す（要約の有無で合否を変えない）。ただし xcodebuild が 0 で終わったのに、
#   動いたテストが0本（「Executed <1以上> test」の行がない。xctestplan のターゲットの ID が合わないなど）なら 65（ac18-reboot.sh と同じ守り）。
#   引数の誤りは 64。
# 結果（.xcresult とログ）はリポジトリの外に置く（既定は ${TMPDIR:-/tmp}/acceptance。AC_RESULTS_DIR で変えられる）。
set -euo pipefail

if [ "$#" -ne 1 ] || [ -z "$1" ]; then
  echo "usage: bash AcceptanceTests/run-acceptance.sh '<シミュレーターの名前>'" >&2
  exit 64
fi
SIM_NAME="$1"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$(cd "$HERE/.." && pwd)"
RESULTS_DIR="${AC_RESULTS_DIR:-${TMPDIR:-/tmp}/acceptance}"
BUNDLE="$RESULTS_DIR/Acceptance.xcresult"
LOG="$RESULTS_DIR/Acceptance.log"
XCRESULT_JSON="$RESULTS_DIR/Acceptance-xcresult.json"
# [AT-DIAG] の行を要約に出す上限。1本の要素の木は AcceptanceTestCase.diagnosticLineLimit（200行）で切れるので、4本までは全部出る。
DIAG_LIMIT=800

mkdir -p "$RESULTS_DIR"
# xcodebuild は -resultBundlePath がすでにあると落ちるので、前の結果を消す。
rm -rf "$BUNDLE" "$LOG" "$XCRESULT_JSON" "$XCRESULT_JSON.err"
echo "run-acceptance: simulator=$SIM_NAME results=$RESULTS_DIR log=$LOG"

set +e
xcodebuild test \
  -project "$IOS_DIR/Yomutoki.xcodeproj" \
  -scheme Yomutoki \
  -testPlan Acceptance \
  -destination "platform=iOS Simulator,name=$SIM_NAME" \
  -resultBundlePath "$BUNDLE" \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tee "$LOG"
CODE="${PIPESTATUS[0]}"
set -e
echo "run-acceptance: xcodebuild exit=$CODE"

# f. の材料（Xcode 16 以降の xcresulttool。読めなければ空のまま）。
XCRESULT_ARG=""
if [ -d "$BUNDLE" ] && command -v xcrun >/dev/null 2>&1; then
  if xcrun xcresulttool get test-results summary --path "$BUNDLE" >"$XCRESULT_JSON" 2>"$XCRESULT_JSON.err"; then
    XCRESULT_ARG="$XCRESULT_JSON"
  fi
fi

echo "=== ACCEPTANCE SUMMARY ==="
echo "xcodebuild の終了コード：$CODE"
echo "ログ：$LOG"
echo "結果：$BUNDLE"
set +e
python3 -I - "$LOG" "$HERE/Acceptance.xctestplan" "$XCRESULT_ARG" "$DIAG_LIMIT" <<'PY'
import json
import os
import re
import sys

log_path, plan_path, xcresult_json, diag_limit = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])

# CI のログ（GitHub Actions）は行の頭に時刻（と、まれに BOM）が付く。tee のログには付かない。どちらも同じに読む。
PREFIX = re.compile(r"^﻿?(?:\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z )?")
SUITE = re.compile(r"^Test Suite '([^']+)' (started|passed|failed) at ")
TOP_SUITES = {"Selected tests", "All tests"}
EXECUTED = re.compile(r"^\s*Executed (\d+) tests?, with (\d+) failures?")
ERROR = re.compile(r"\.swift:\d+: error: ")
CASE_STARTED = re.compile(r"^Test Case '-\[[\w.]+ \w+\]' started")
CASE_FAILED = re.compile(r"^Test Case '-\[([\w.]+) (\w+)\]' failed")
CASE_DONE = re.compile(r"^Test Case '-\[([\w.]+) (\w+)\]' (passed|failed) \(([\d.]+) seconds\)")
ABNORMAL = re.compile(
    r"Restarting after unexpected exit|Early unexpected exit|Test crashed|crashed with signal|Test runner exited|"
    r"timed out while|exceeded execution time allowance|\*\* TEST (?:EXECUTE )?(?:FAILED|INTERRUPTED|SUCCEEDED) \*\*"
)
FAILING_HEAD = re.compile(r"^Failing tests:\s*$")
FAILING_NAME = re.compile(r"^\s+(\w+\.\w+\(\))\s*$")
FAILING_END = re.compile(r"^\*\* TEST ")
DIAG = re.compile(r"\[AT-DIAG\]")
DIAG_LANG = re.compile(r"\[AT-DIAG\] 構成：ACCEPTANCE_LANG=(\w+)")
SECTION_CAP = 200

with open(log_path, encoding="utf-8", errors="replace") as f:
    lines = [PREFIX.sub("", raw.rstrip("\r\n")) for raw in f]

run = 0
saw_top_start = False
run_langs = {}
suites, cases, errors, failed_cases, abnormal, failing, diags = [], [], [], [], [], [], []
case_index = {}
in_failing = False

def tag():
    return f"[回{run}]" if run else "[回?]"

for line in lines:
    m = SUITE.match(line)
    if m and m.group(1) in TOP_SUITES and m.group(2) == "started":
        run += 1
        saw_top_start = True
    elif run == 0 and (
        m or EXECUTED.match(line) or CASE_STARTED.match(line) or CASE_DONE.match(line)
        or ERROR.search(line) or DIAG.search(line)
    ):
        run = 1  # ログの頭が切れて、最上位の started がない
    if m or EXECUTED.match(line):
        suites.append(f"{tag()} {line.strip()}")
    dm = CASE_DONE.match(line)
    if dm:
        case_index[run] = case_index.get(run, 0) + 1
        cls = dm.group(1).split(".")[-1]
        cases.append(f"{tag()} {case_index[run]:>3} {dm.group(3):<6} {cls}.{dm.group(2)} ({dm.group(4)}s)")
    if ERROR.search(line):
        errors.append(f"{tag()} {line}")
    cm = CASE_FAILED.match(line)
    if cm:
        failed_cases.append((run, f"{cm.group(1)}.{cm.group(2)}", line))
    if ABNORMAL.search(line):
        abnormal.append(f"{tag()} {line.strip()}")
    if FAILING_HEAD.match(line):
        in_failing = True
    if in_failing:
        failing.append(line)
        if FAILING_END.match(line):
            in_failing = False
    if DIAG.search(line):
        diags.append(f"{tag()} {line.strip()}")
        lm = DIAG_LANG.search(line)
        if lm:
            run_langs.setdefault(run, set()).add(lm.group(1))

def capped(items, cap, what):
    for item in items[:cap]:
        print(item)
    if len(items) > cap:
        print(f"…ほか {len(items) - cap} 行（{what}）は {log_path} にある")

try:
    with open(plan_path, encoding="utf-8") as f:
        plan_names = [c.get("name", "?") for c in json.load(f).get("configurations", [])]
except (OSError, ValueError) as e:
    plan_names = [f"読めない（{e}）"]

print("--- a. 回の区切りと件数 ---")
print(f"計画の構成の順：{'、'.join(plan_names)}（xcodebuild はログに構成の名前を出さない。回の番号は最上位のスイートの started の順）")
if not saw_top_start:
    print("注意：最上位のスイート（Selected tests／All tests）の started がない。ログの頭が切れていて、回の番号は当てにならない")
for r in sorted(run_langs):
    print(f"回{r} の言語（[AT-DIAG] の構成の行から）：{'、'.join(sorted(run_langs[r]))}")
capped(suites, SECTION_CAP, "Test Suite と Executed の行")
print(f"--- a2. 回ごとの実行順（順番、結果、テスト、秒）{len(cases)} 行 ---")
capped(cases, 2 * SECTION_CAP, "Test Case の終わりの行")

print(f"--- b. 失敗の文言（.swift:<行>: error:）{len(errors)} 行 ---")
for item in errors:
    print(item)
print(f"--- b2. 落ちた Test Case {len(failed_cases)} 行 ---")
for r, _, line in failed_cases:
    print(f"[回{r}] {line.strip()}" if r else f"[回?] {line.strip()}")
print(f"--- b3. 異常終了と終わりの行 {len(abnormal)} 行 ---")
capped(abnormal, 50, "異常終了と終わりの行")

print("--- c. Failing tests: の節 ---")
if failing:
    capped(failing, SECTION_CAP, "Failing tests: の節")
else:
    print("（Failing tests: の行はない）")

print(f"--- d. [AT-DIAG] の行 {len(diags)} 行（上限 {diag_limit} 行）---")
capped(diags, diag_limit, "[AT-DIAG] の行")

names = [m.group(1) for m in (FAILING_NAME.match(l) for l in failing) if m]
print(f"--- e. 落ちたテスト（Failing tests: から）{len(names)} 本 ---")
for name in names:
    print(f"  {name}")
by_run = {}
for r, name, _ in failed_cases:
    by_run.setdefault(r, []).append(name)
for r in sorted(by_run):
    lang = "、".join(sorted(run_langs.get(r, []))) or "言語は不明"
    print(f"回{r if r else '?'}（{lang}）：{len(by_run[r])} 本：{'、'.join(by_run[r])}")

print("--- f. .xcresult の構成ごとの件数（xcresulttool get test-results summary）---")
if not xcresult_json:
    print("（読めなかった、または .xcresult がない）")
else:
    try:
        with open(xcresult_json, encoding="utf-8") as f:
            data = json.load(f)
        for dc in data.get("devicesAndConfigurations", []) or []:
            conf = (dc.get("testPlanConfiguration") or {}).get("configurationName", "?")
            dev = dc.get("device") or {}
            print(
                f"構成 {conf}（{dev.get('deviceName', '?')} {dev.get('osVersion', '')}）："
                f"通過 {dc.get('passedTests', '?')}、失敗 {dc.get('failedTests', '?')}、飛ばした {dc.get('skippedTests', '?')}"
            )
        failures = data.get("testFailures", []) or []
        print(f"testFailures：{len(failures)} 件")
        for item in failures[:50]:
            text = str(item.get("failureText", "")).replace("\n", " ")[:400]
            print(f"  {item.get('testIdentifierString') or item.get('testName', '?')}：{text}")
        if "devicesAndConfigurations" not in data and "testFailures" not in data:
            print(f"（想定のキーがない。キー：{', '.join(sorted(data))}）")
    except (OSError, ValueError, AttributeError) as e:
        print(f"（読めなかった：{e}）")
PY
SUMMARY_CODE=$?
set -e
if [ "$SUMMARY_CODE" -ne 0 ]; then
  echo "（要約を作れなかった：python3 の終了コード $SUMMARY_CODE。代わりに失敗の文言と [AT-DIAG] をそのまま出す）"
  grep -E '\.swift:[0-9]+: error: |\[AT-DIAG\]|^Failing tests:|^[[:space:]]+[A-Za-z0-9_]+\.[A-Za-z0-9_]+\(\)[[:space:]]*$' "$LOG" | head -n "$DIAG_LIMIT" || true
fi
echo "=== END ACCEPTANCE SUMMARY ==="

if [ "$CODE" -eq 0 ] && ! grep -qE 'Executed [1-9][0-9]* tests?, with' "$LOG"; then
  echo "run-acceptance: xcodebuild は 0 で終わったが、動いたテストが0本（「Executed <1以上> test」の行がない。$LOG）" >&2
  exit 65
fi
exit "$CODE"
