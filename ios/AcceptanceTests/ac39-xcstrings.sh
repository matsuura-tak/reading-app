#!/usr/bin/env bash
# AC-39：日本語と英語の文言がそろっている（contracts/test-hooks.md の T14）。
# String Catalog（ios/Yomutoki/Resources/*.xcstrings）で、ja か en の訳がない（state が translated でない）キーが0件であること。
# T14 のコマンド `python3 -I contracts/tools/xcstrings_untranslated.py ios/Yomutoki/Resources/*.xcstrings` を包むだけ。
# 合格：出力の最後の行が `untranslated_keys=0` で、終了コード0。
# 使い方（リポジトリのどこからでもよい）：bash ios/AcceptanceTests/ac39-xcstrings.sh
# CLAUDE.md の ios_test に入っていないので、G3 で verifier が手で動かす（test-plan の 5。app.json に足すかは Takuma。P-12）。
# Linux でも動く（Python 3 だけを使う）。再試行はしない。
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
TOOL="$ROOT/contracts/tools/xcstrings_untranslated.py"

test_AC39_stringCatalogFullyTranslated() {
  local name="test_AC39_stringCatalogFullyTranslated"
  shopt -s nullglob
  local files=("$ROOT"/ios/Yomutoki/Resources/*.xcstrings)
  shopt -u nullglob
  if [ "${#files[@]}" -eq 0 ]; then
    echo "$name: FAIL（ios/Yomutoki/Resources/*.xcstrings が1つもない）"
    return 1
  fi
  echo "$name: files=${files[*]#"$ROOT/"}"
  local out code
  set +e
  out="$(python3 -I "$TOOL" "${files[@]}")"
  code=$?
  set -e
  printf '%s\n' "$out"
  local last
  last="$(printf '%s\n' "$out" | tail -n 1)"
  if [ "$code" -ne 0 ] || [ "$last" != "untranslated_keys=0" ]; then
    echo "$name: FAIL（exit=${code}、最後の行=${last}）"
    return 1
  fi
  echo "$name: PASS（exit=0、最後の行=${last}）"
}

test_AC39_stringCatalogFullyTranslated
