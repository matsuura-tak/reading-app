#!/usr/bin/env bash
# AC-18：端末（シミュレーター）を再起動しても、本と記録が残る（contracts/test-hooks.md の T11、A53）。
# 使い方（CLAUDE.md の ios_test の最後。ios/ の中で動かす）：bash AcceptanceTests/ac18-reboot.sh 'iPhone 17'
#   1. データを作る実行（AC18RebootTests/test_AC18_1_seedLibraryBeforeReboot だけ）
#   2. 再起動：simctl list devices -j で state を読み、Booted なら shutdown、Shutdown なら飛ばす（xcodebuild test の後に止まっていることがある。
#      CI run 22 で shutdown が code=405「Unable to shutdown device in current state: Shutdown」で落ちた）。続けて boot（Booted なら飛ばす）と bootstatus
#   3. 確かめる実行（AC18RebootTests/test_AC18_2_libraryRemainsAfterReboot だけ。UITEST_RESET も UITEST_SEED も渡さない）
# 再試行はしない（xcodebuild に再試行の引数を付けない）。どこかで落ちたら、その終了コードで終わる。
# 動いたテストの数は xcodebuild の出力（<結果の場所>/<テスト名>.log に tee で残す）の「Executed 1 test, with 0 failures」で確かめる。
# 0本のまま成功で終わった（xctestplan のターゲットの ID や -only-testing の名前が合わない）ときは 65 で終わる。
# 再起動の段で state が Booted か Shutdown に決まらない（Booting、Shutting Down などのまま 60 秒）ときは 67、UDID が一覧から消えたときは 66 で終わる。
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

# UDID の今の state（Booted、Shutdown、Booting、Shutting Down など）を出す。一覧にないときは空。UDID の決め方と同じく python3 -I で読む。
sim_state() {
  xcrun simctl list devices -j | python3 -I -c '
import json, sys
udid = sys.argv[1]
devices = json.load(sys.stdin)["devices"]
found = [d.get("state", "") for runtime in devices for d in devices[runtime] if d.get("udid") == udid]
print(found[0] if found else "")
' "$UDID"
}

# state が Booted か Shutdown になるまで待ち、SIM_STATE に入れる。待つのは state の変化（2 秒ごとに読み直す）で、最大 60 秒。
# 決まらなければ 67、UDID が一覧にないときは 66 を返す。simctl か python3 が落ちたときは 0 でない終了コード（pipefail なので右端の失敗。simctl が落ちると python3 の 1）を返す。
STATE_WAIT_MAX=60
STATE_WAIT_STEP=2
SIM_STATE=""
wait_settled_state() {
  local waited=0
  local state
  state="$(sim_state)" || return $?
  while [ "$state" != "Booted" ] && [ "$state" != "Shutdown" ]; do
    if [ -z "$state" ]; then
      echo "ac18-reboot: udid=$UDID が simctl list devices -j にない" >&2
      return 66
    fi
    if [ "$waited" -ge "$STATE_WAIT_MAX" ]; then
      echo "ac18-reboot: state=$state のまま ${STATE_WAIT_MAX} 秒たっても Booted か Shutdown にならない" >&2
      return 67
    fi
    echo "ac18-reboot: state=$state → Booted か Shutdown になるのを待つ（${waited} 秒経過）"
    sleep "$STATE_WAIT_STEP"
    waited=$((waited + STATE_WAIT_STEP))
    state="$(sim_state)" || return $?
  done
  SIM_STATE="$state"
  return 0
}

PASSED=0

# 1. データを作る実行
run_one test_AC18_1_seedLibraryBeforeReboot || exit $?

# 2. 再起動（A53）。止める → 起動する → 起動し終わるのを待つ。
# xcodebuild test が終わるとシミュレーターが Shutdown に戻っていることがある（CI run 22、macos-latest、Xcode 26.6）。
# そのときは shutdown を飛ばす（止まっている状態から起動するので、再起動の意味は変わらない）。
echo "ac18-reboot: reboot $UDID"
wait_settled_state || exit $?
if [ "$SIM_STATE" = "Booted" ]; then
  echo "ac18-reboot: state=$SIM_STATE → shutdown する"
  xcrun simctl shutdown "$UDID"
else
  echo "ac18-reboot: state=$SIM_STATE → shutdown を飛ばす（もう止まっている）"
fi
wait_settled_state || exit $?
if [ "$SIM_STATE" = "Booted" ]; then
  echo "ac18-reboot: state=$SIM_STATE → boot を飛ばす（もう起動している）"
else
  echo "ac18-reboot: state=$SIM_STATE → boot する"
  xcrun simctl boot "$UDID"
fi
xcrun simctl bootstatus "$UDID"
echo "ac18-reboot: state=$(sim_state)（bootstatus の後）"

# 3. 確かめる実行
run_one test_AC18_2_libraryRemainsAfterReboot || exit $?
if [ "$PASSED" -ne 2 ]; then
  echo "ac18-reboot: 通った実行は $PASSED 本（2本のはず）" >&2
  exit 1
fi
echo "ac18-reboot: passed $PASSED of 2 (seed, verify after reboot)"
