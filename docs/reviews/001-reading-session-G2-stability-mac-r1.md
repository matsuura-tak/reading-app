FAIL

# CI run 23 の不安定な2ケースの調査（2026-10-23）

全体の合格判定ではない。修正後の全体 CI とレビューの結果を確認するまで Draft を維持する。

## 最新 CI の事実

- 対象 `1ad1744`、[run 39834168296](https://github.com/matsuura-tak/reading-app/actions/runs/39834168296)。2026-10-23 05:41 JST に失敗で終了。
- Debug・Release のビルドと単体69件は成功。受け入れテストは英語80/80、日本語78/80、スキップ0。
- 日本語 AC-48 は下へのスワイプの後も入力画面が残った。要素の木は finishing、ページ72、分10、保存ボタンとキーボードが残る。
- 日本語 AC-9 はアプリ再起動後の件数の待機で失敗。ただし待機後の診断には「記録 2件」、最後のページ72、進み具合24%、2つの記録の行がある。この証拠だけで保存データが消えたとは判断しない。
- 前の `cec65d5` の回は160/160成功しており、再実行だけで合格にはしない。AC-18 は最新の回では前段の失敗により未実行。

## Mac での再現

- 環境：Xcode 27.1、iPhone 17 / iOS 26.0、UDID `B18DB71A-DB50-4F84-9DDD-7D63541CF3BB`。CI の Xcode 26.6 / iOS 26.5 と版は異なる。
- `1ad1744` をビルドし、AC-9 と AC-48 を日本語で `-test-iterations 5 -run-tests-until-failure` で確認した。
- AC-9 は5回成功。AC-48 は1回目で同じ「終える入力が消えない」が再現し、終了65。残りの反復は失敗で停止し、実行は計6回（成功5・失敗1・スキップ0）。
- 修正前の結果：`/private/tmp/reading-app-pr2-flaky-baseline-20261023.log` と `.xcresult`。失敗のスクリーンショットも実際に開き、入力とキーボードが残ることを確認した。

## 修正候補と根拠

修正のコミットは `bb49867`。繰り返し確認で使った3つの Swift ファイルの SHA-256 も evidence に保存した。

1. AC-48 のスワイプを、操作できるナビゲーションバーの中央から画面下部85%までの1回の下向きジェスチャとして明示する。PRD AC-48 と design 6(d) の起点を維持する。キャンセルボタンへの置き換え、閉じるまでの繰り返し、アサーションの削除はしない。
2. 存在の消失は `waitForNonExistence`、単一ラベルの一致は `wait(for:toEqual:timeout:)` を使う。待機上限10秒と期待値は維持し、時間切れ後に一致を観測しても成功に変えない。AC-9 の件数は識別子を使った StaticText のクエリで確かめる。
3. AC-9 の CI での原因はまだ断定しない。Mac では修正前も5回成功しており、広い要素検索と汎用の条件待機を置き換えたことだけで CI の安定性が証明されたとは扱わない。

Apple の [XCUIElement](https://developer.apple.com/documentation/xcuiautomation/xcuielement)、[waitForNonExistence](https://developer.apple.com/documentation/xcuiautomation/xcuielement/waitfornonexistence(timeout:))、[WWDC25 の標準の待機 API の例](https://developer.apple.com/videos/play/wwdc2025/344/) とローカル SDK で名前を確認した。座標のドラッグは [XCUICoordinate の API](https://developer.apple.com/documentation/xcuiautomation/xcuicoordinate/press(forduration:thendragto:withvelocity:thenholdforduration:)) と SDK の XCUICoordinate.h にあるものを使う。

## 修正候補の検証

AC-9 と AC-48 を日本語・英語の各5回、計20回、失敗で停止する設定で実行した。日本語10回・英語10回がすべて成功、失敗0・スキップ0、終了0、TEST SUCCEEDED。結果は `/private/tmp/reading-app-pr2-flaky-candidate-20261023.log` と `.xcresult`。xcresult の統計は「2 configurations ran with test repetitions」「20 test runs」で、構成ごとの passedTests は各10。

標準出力の抜粋、修正前後の集計 JSON、実際に開いた修正前の入力画面と修正後に読書へ戻った画面を `docs/verification/001-reading-session/evidence/mac-20261023/` に残す。全160件の CI の完走や、ほかの受け入れ条件の5回確認には数えない。

実行したコマンドは同じ行き先で、修正前は `-only-test-configuration ja_JP`、修正後は両構成を指定した。

```sh
xcodebuild test -project ios/Yomutoki.xcodeproj -scheme Yomutoki -testPlan Acceptance \
  -only-testing:YomutokiAcceptanceTests/FinishInputAcceptanceTests/test_AC48_swipeDownDismissEqualsCancel \
  -only-testing:YomutokiAcceptanceTests/FinishSessionAcceptanceTests/test_AC9_enteringPageRecordsProgress \
  -test-iterations 5 -run-tests-until-failure \
  -destination 'platform=iOS Simulator,id=B18DB71A-DB50-4F84-9DDD-7D63541CF3BB' \
  -resultBundlePath /private/tmp/reading-app-pr2-flaky-candidate-20261023.xcresult CODE_SIGNING_ALLOWED=NO
```

タイムアウトの増加、期待値の緩和、テストの除外、失敗後の再試行での成功扱いはない。製品のコード、つなぎ口、test plan の構成、CI の定義を変更していない。

## AC-18 の端末再起動

同じ専用シミュレーターで `AC18_RESULTS_DIR=/private/tmp/reading-app-pr2-ac18-20261023 bash AcceptanceTests/ac18-reboot.sh 'iPhone 17 26.0'` を ios/ で実行し、終了0。seed の1件と再起動後の1件がそれぞれ成功1・失敗0・スキップ0、`passed 2 of 2` を確認した。

seed の実行後にシミュレーターは Shutdown になっていた。スクリプトはその状態を確認して二重の shutdown をせず、boot と bootstatus の後で Booted を確認し、RESET と SEED を入れない2回目のテストで本と記録を確認した。既存のスクリプト1ad1744を使い、追加の修正はしていない。ほかのシミュレーターは操作していない。

結果は `/private/tmp/reading-app-pr2-ac18-20261023.log` と `/private/tmp/reading-app-pr2-ac18-20261023/`。2段階の集計 JSON と標準出力の抜粋を同じ evidence/mac-20261023/ に残した。これは1回の power cycle であり、G3 で要求する5回の再起動確認を終えたとは扱わない。

## 残る確認

- 修正後 HEAD の全体 CI。ローカルと CI は OS・Xcode の版が異なるため、20回成功だけで CI の問題が解消したとは断定しない。
- G2 r2 のレビューと G3 の検証・画面確認。全受け入れ条件の5回確認をこの2ケースの結果だけで完了とはしない。
- 保護された CI 設定の所有者確認（org-guard）。ガードは変更していない。
