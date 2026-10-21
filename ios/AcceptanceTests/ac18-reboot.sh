#!/usr/bin/env bash
# AC-18：端末（シミュレーター）を再起動しても、本と記録が残る（contracts/test-hooks.md の T11、A53）。
# 使い方（CLAUDE.md の ios_test の最後。ios/ の中で動かす）：bash AcceptanceTests/ac18-reboot.sh 'iPhone 16'
#   1. データを作る実行（AC18RebootTests/test_AC18_1_seedLibraryBeforeReboot だけ）
#   2. xcrun simctl shutdown と boot（起動し終わるまで bootstatus で待つ）
#   3. 確かめる実行（AC18RebootTests/test_AC18_2_libraryRemainsAfterReboot だけ。UITEST_RESET も UITEST_SEED も渡さない）
# 再試行はしない（xcodebuild に再試行の引数を付けない）。どこかで落ちたら、その終了コードで終わる。
# 動いたテストの数は xcodebuild の出力（<結果の場所>/<テスト名>.log に tee で残す）の「Executed 1 test, with 0 failures」で確かめる。
# 0本のまま成功で終わった（xctestplan のターゲットの ID や -only-testing の名前が合わない）ときは 65 で終わる。
# 結果のファイル（.xcresult）はリポジトリの外に置く（既定は ${TMPDIR:-/tmp}/ac18-reboot。AC18_RESULTS_DIR で変えられる）。
set -euo pipefail

if [ "$#" -ne 1 ] || [ -z "$1" ]; then
  echo "usage: bash AcceptanceTests/ac18-reboot.sh '<シミュレーターの名前>'" >&2
  exit 64
fi
SIM_NAME="$1"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$(cd "$HERE/.." && pwd)"
RESULTS_DIR="${AC18_RESULTS_DIR:-${TMPDIR:-/tmp}/ac18-reboot}"
TARGET="YomutokiAcceptanceTests/AC18RebootTests"

# 名前が同じ機種が複数あると、xcodebuild の name= と simctl が別の機種を選ぶおそれがあるので、UDID を1つに決めて両方に使う。
UDID="$(xcrun simctl list devices available -j | python3 -I -c '
import json, sys
name = sys.argv[1]
devices = json.load(sys.stdin)["devices"]
found = [d["udid"] for runtime in sorted(devices, reverse=True) for d in devices[runtime] if d.get("name") == name and d.get("isAvailable", True)]
print(found[0] if found else "")
' "$SIM_NAME")"
if [ -z "$UDID" ]; then
  echo "ac18-reboot: シミュレーター「$SIM_NAME」が見つからない" >&2
  exit 66
fi
echo "ac18-reboot: simulator=$SIM_NAME udid=$UDID results=$RESULTS_DIR"
mkdir -p "$RESULTS_DIR"

run_one() {
  local test_name="$1"
  local bundle="$RESULTS_DIR/$test_name.xcresult"
  local log="$RESULTS_DIR/$test_name.log"
  rm -rf "$bundle" "$log"
  echo "ac18-reboot: run $TARGET/$test_name (log=$log)"
  set +e
  xcodebuild test \
    -project "$IOS_DIR/Yomutoki.xcodeproj" \
    -scheme Yomutoki \
    -testPlan AC18Reboot \
    -destination "id=$UDID" \
    -only-testing:"$TARGET/$test_name" \
    -resultBundlePath "$bundle" \
    CODE_SIGNING_ALLOWED=NO 2>&1 | tee "$log"
  local code="${PIPESTATUS[0]}"
  set -e
  echo "ac18-reboot: $test_name exit=$code"
  if [ "$code" -ne 0 ]; then
    return "$code"
  fi
  if ! grep -q 'Executed 1 test, with 0 failures' "$log"; then
    echo "ac18-reboot: $test_name の出力に「Executed 1 test, with 0 failures」がない（動いたテストが1本ではない。$log）" >&2
    return 65
  fi
  PASSED=$((PASSED + 1))
  return 0
}

PASSED=0

# 1. データを作る実行
run_one test_AC18_1_seedLibraryBeforeReboot || exit $?

# 2. 再起動（A53）
echo "ac18-reboot: reboot $UDID"
xcrun simctl shutdown "$UDID"
xcrun simctl boot "$UDID"
xcrun simctl bootstatus "$UDID"

# 3. 確かめる実行
run_one test_AC18_2_libraryRemainsAfterReboot || exit $?
if [ "$PASSED" -ne 2 ]; then
  echo "ac18-reboot: 通った実行は $PASSED 本（2本のはず）" >&2
  exit 1
fi
echo "ac18-reboot: passed $PASSED of 2 (seed, verify after reboot)"
