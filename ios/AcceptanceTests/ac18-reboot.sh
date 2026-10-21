#!/usr/bin/env bash
# AC-18：端末（シミュレーター）を再起動しても、本と記録が残る（contracts/test-hooks.md の T11、A53）。
# 使い方（CLAUDE.md の ios_test の最後。ios/ の中で動かす）：bash AcceptanceTests/ac18-reboot.sh 'iPhone 16'
#   1. データを作る実行（AC18RebootTests/test_AC18_1_seedLibraryBeforeReboot だけ）
#   2. xcrun simctl shutdown と boot（起動し終わるまで bootstatus で待つ）
#   3. 確かめる実行（AC18RebootTests/test_AC18_2_libraryRemainsAfterReboot だけ。UITEST_RESET も UITEST_SEED も渡さない）
# 再試行はしない（xcodebuild に再試行の引数を付けない）。どこかで落ちたら、その終了コードで終わる。
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
  rm -rf "$bundle"
  echo "ac18-reboot: run $TARGET/$test_name"
  set +e
  xcodebuild test \
    -project "$IOS_DIR/Yomutoki.xcodeproj" \
    -scheme Yomutoki \
    -testPlan AC18Reboot \
    -destination "id=$UDID" \
    -only-testing:"$TARGET/$test_name" \
    -resultBundlePath "$bundle" \
    CODE_SIGNING_ALLOWED=NO
  local code=$?
  set -e
  echo "ac18-reboot: $test_name exit=$code"
  return "$code"
}

# 1. データを作る実行
run_one test_AC18_1_seedLibraryBeforeReboot || exit $?

# 2. 再起動（A53）
echo "ac18-reboot: reboot $UDID"
xcrun simctl shutdown "$UDID"
xcrun simctl boot "$UDID"
xcrun simctl bootstatus "$UDID"

# 3. 確かめる実行
run_one test_AC18_2_libraryRemainsAfterReboot || exit $?
echo "ac18-reboot: passed 2 of 2 (seed, verify after reboot)"
