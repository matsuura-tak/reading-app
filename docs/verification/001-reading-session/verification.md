# 検証レポート 001-reading-session（G3 再検証 r4）

置き場所：docs/verification/001-reading-session/verification.md

判定：PASS

- 関門：G3（verifier r3 の FAIL と ios-engineer の 11〜14 回目の直し r3a・r3b・r3c（`8adbf95`、`804b050`、`e381991`）のあとの再検証。全 149 AC が ja・en の両構成で通り、揺れの確認・初回起動・性能・契約スキーマ検査・証拠撮影（light/dark/ax5/en、計 222 PNG + explore 9 PNG、`asis` 画像 0 枚）もすべて通った）
- 検証した役：verifier　日時：2026-11-03 22:00 〜 2026-11-04 00:25
- コミット：`3b8f606`（製品のコードは `e381991` まで。作業ツリーには `ios/AcceptanceTests/G3EvidenceCaptureTests.swift` の 4 か所（計 7 行）と `docs/verification/001-reading-session/` の更新が未コミットで載っている。製品のコード、contracts、design、Makefile は一切変えていない）
- 環境：macOS（Darwin 27.2.0）、Xcode 27.2（Build 27B52）、iOS Simulator `iPhone 17`（iOS 26.0、UDID `E5664965-B285-4795-9EE7-2D890556B3BE`。同名の端末が 2 台あるため `SIM_DESTINATION='platform=iOS Simulator,id=E5664965-…'` で固定）、バックエンドの接続先：なし（サーバーを持たない）

指揮役の指示書（1〜4）の結果の要約：
1. `ios/AcceptanceTests/G3EvidenceCaptureTests.swift` の 4 か所を直した（5 章）：
   - 363 行：`shareCard.close` → `finish.card.close`（design/ 6 の識別子）
   - 368 行・1614 行：`colophon.title` → `colophon.ocr.publisher`（S-7c の欄の識別子）
   - 684 行：S-3 empty 用の `noLineSeed` の `page: 45` → `page: nil`（一行もページもない本にすることで `mark.later.note.empty` が出る条件を満たす）
   - 1006 行：S-7c partial の `colophon.publisher` → `colophon.ocr.publisher`
2. テストの実行と揺れの確認（1〜4 章）：
   - 受け入れテスト全 7 クラス（計 150 テスト＝149 AC 分）：`Japanese (ja)` 150/150 成功（失敗 0、飛ばした 0）、`English (en)` 150/150 成功（失敗 0、飛ばした 0）。r3 で落ちていた `test_AC91_2`・`test_AC91_5`・`test_AC91_6` を含む AC-91 の 7 本すべてが ja・en で通った
   - 揺れの確認（`-test-iterations 5 -run-tests-until-failure`、ja）：r3 で落ちていた `test_AC91_2`・`test_AC91_5`・`test_AC91_6`（計 15 回）および `test_AC47`（5 回）を含む全 27 テスト×5 回＝135 回すべて成功、失敗 0（`evidence/logs/06-flaky.summary.log`）
   - `xcrun simctl erase` のあとの `make ios-test-first-launch`：ja 1/1、en 1/1 成功（`evidence/logs/03-ios-test-first-launch.tail.log`）
   - `make ios-test-perf`：ja 4/4、en 4/4 成功（`evidence/logs/04-ios-test-perf.tail.log`）
   - `make check-contracts`：8 スキーマ・29 例すべて 0 エラーで PASS（`evidence/logs/05-check-contracts.tail.log`）
3. 証拠の撮り直しとアクセシビリティ監査（7〜9 章）：
   - `G3EvidenceCaptureTests` を `light`・`dark`・`ax5`・`en` の 4 通りで実行し、すべて終了コード 0、`MISSING` 0 件、`NOTE` 0 件（`evidence/logs/07-capture.summary.log`）
   - r3 で `asis` だった `S3_empty_light.png`（`mark.later.note.empty` 表示）、`S9_denied_light.png`（`camera.denied` 表示）、`S7c_empty_light.png`（`mark.ocr.none` と `colophon.retake` 表示）、`S10_loading_light.png`（`hold.storekit.restore=shown` でスピナー表示）がすべて期待どおりの要素つきで撮れた。古い `*_asis_light.png` 4 枚と `AC91_2_saveError_double.png` は削除した
   - AX5 の `captureWidgets` も `hook.widget.canvas` の高さが `showcase.canvasHeight` と 0.5pt 以内で一致し、5 面すべて `TEST SUCCEEDED`
   - S-7a（`book.edit.title`、`book.edit.author`）と S-3c（`mark.lineField`）の欄に今の値が初期値として入っていることを確かめた。探索 R6 で著者欄に「（改）」を追記して保存すると、書名「羅生門」を保ったまま著者が「芥川龍之介（改）」になる（`evidence/explore/X_R6_1_S_7a_open_fields.png`〜`X_R6_4_S_7_after_edit.png`）
   - `performAccessibilityAudit(for: .all)`：27 画面で合計 **10 件**（r3 の 80 件から 70 件減少。W-1・W-2・S-5・S-3a・S-3b は 0 件、S-1 は 1 件、S-10a は 2 件。縦書きの 1 字ずつの StaticText 指摘は 0 件になった）
   - H22 の JSON 10 ファイルのスキーマ検査：10 ファイルすべて `hook.widget OK`、エラー 0（`evidence/logs/09-h22-schema.log`）

## 1. 実行したコマンドと結果
再試行（`-retry-tests-on-failure`）は一切付けていない。長いテストは `caffeinate -dims` を付けて動かした。末尾のログは `docs/verification/001-reading-session/evidence/logs/` に、完全なログと .xcresult はリポジトリの外（`/private/tmp` の作業フォルダ `scratchpad/r13/`、`scratchpad/r14/`）にある。

### コマンド 1：`make ios-build` と受け入れテストのターゲットのビルド
- `xcodebuild build-for-testing -project ios/ReadingApp.xcodeproj -scheme ReadingApp -configuration Debug -destination 'platform=iOS Simulator,id=E5664965-…'`：終了コード 0。製品のターゲット・受け入れテストのターゲットともコンパイラの警告 **0 件**（`evidence/logs/00-test-target-build.tail.log`）。

### コマンド 2：単体テストと受け入れテスト全 7 クラス（ja・en）
- `swift test --package-path ios/ReadingKit`：`Test run with 19 tests in 2 suites passed`、`Test run with 37 tests in 9 suites passed`（計 56 単体テスト passed）。
- `xcodebuild test-without-building -project ios/ReadingApp.xcodeproj -scheme ReadingApp -configuration Debug -destination 'platform=iOS Simulator,id=E5664965-B285-4795-9EE7-2D890556B3BE' -skip-testing:ReadingAcceptanceTests/FirstLaunchTests -skip-testing:ReadingAcceptanceTests/PerformanceTests -skip-testing:ReadingAcceptanceTests/G3EvidenceCaptureTests`（`evidence/logs/02-ios-test.counts.log`、`evidence/logs/02-ios-test.tail.log`）：
  - 全 7 クラス（`BookmarkAcceptanceTests` 15、`FinishAndRecommendationAcceptanceTests` 22、`RegistrationAcceptanceTests` 16、`ShelfAndBookAcceptanceTests` 15、`SettingsStoreIntentsAcceptanceTests` 41、`WidgetAndActivityAcceptanceTests` 20、`ReadingSessionAcceptanceTests` 21＝計 150 テスト）：
    - `Japanese (ja)`：**150 成功、0 失敗、0 スキップ**
    - `English (en)`：**150 成功、0 失敗、0 スキップ**
  - r3 で落ちていた `SettingsStoreIntentsAcceptanceTests/test_AC91_2`、`test_AC91_5`、`test_AC91_6` を含む `SettingsStoreIntentsAcceptanceTests` 41 本は ja 41/41、en 41/41 で完走（`scratchpad/r14/accept2.log`）。
  - 備考：`scratchpad/r14/accept2.log`（3 クラス 82 本×2 構成の分割実行）の ja の `ReadingSessionAcceptanceTests/test_AC47` で 1 回だけビルド直後のシミュレータの向き変更のタイミングにより step (7) で止まったため、`test_AC47` を `-test-iterations 5 -run-tests-until-failure` で 5 回連続実行して 5/5 成功（`scratchpad/r14/ac47-flaky.log`）を確かめたうえで、`ReadingSessionAcceptanceTests`（ja）全 21 本を通しで再実行し 21/21 成功（0 失敗、407.9 秒、`scratchpad/r14/accept2-rs-ja.log`）を確かめた。また同じ製品コード `e381991` での 7 クラス一括実行（`scratchpad/r13/accept.xcresult`）でも ja 150/150、en 150/150 成功している。

### コマンド 3：`xcrun simctl shutdown E5664965-…; xcrun simctl erase E5664965-…; caffeinate -dims make ios-test-first-launch SIM_DESTINATION='…id=E5664965-…'`
- 終了コード 0（erase も 0）。`** TEST SUCCEEDED **`（`FirstLaunchTests/test_AC1_初回起動で空のしおり画面が出て許可ダイアログが出ない`、ja 1/1・en 1/1 とも passed、158.196 秒。`evidence/logs/03-ios-test-first-launch.tail.log`）。

### コマンド 4：`caffeinate -dims make ios-test-perf SIM_DESTINATION='…id=E5664965-…'`
- 終了コード 0。`PerformanceTests`（AC-100、AC-101、AC-102、AC-149 の 4 本）：ja 4/4 passed（266.522 秒）、en 4/4 passed（252.935 秒）（`evidence/logs/04-ios-test-perf.tail.log`。製品のコードは r3 から性能に関わる変更なし）。

### コマンド 5：`make check-contracts`
- 終了コード 0。`jsonschema 4.25.1`、`ALL PASSED: 8 schemas, 29 examples validated with 0 errors.`（`evidence/logs/05-check-contracts.tail.log`）。

### コマンド 6：証拠の撮影とアクセシビリティ監査・探索（`G3EvidenceCaptureTests`）
- `TEST_RUNNER_G3_CAPTURE=1 TEST_RUNNER_G3_VARIANT=<light|dark|ax5|en> TEST_RUNNER_G3_OUT_DIR=<外のフォルダ> caffeinate -dims xcodebuild test-without-building -project ios/ReadingApp.xcodeproj -scheme ReadingApp -configuration Debug -destination 'platform=iOS Simulator,id=E5664965-…' -only-testing:ReadingAcceptanceTests/G3EvidenceCaptureTests -only-test-configuration "Japanese (ja)"`（ダークは起動後に `xcrun simctl ui E5664965-… appearance dark` を設定し終了後に `light` に戻した。en は `-AppleLanguages (en)` を起動引数で渡し、本のデータは日本語のまま）。
- 結果（`evidence/logs/07-capture.summary.log`、手順ごとの詳細は `evidence/logs/07-capture-steps-<light|dark|ax5|en>.log`）：
  - `light`（全 5 メソッド：`captureNormalScreens`、`captureWidgets`、`captureStates`、`accessibilityAudit`、`exploratory`）：終了コード 0（`Executed 5 tests, with 0 failures in 1820.114 seconds`）。132 枚の画面・ウィジェット PNG と 9 枚の探索 PNG、H22 JSON 10 ファイル、`accessibility-audit.log` を出力。**`MISSING` 0 件、`NOTE` 0 件**。
  - `dark`（`captureNormalScreens`、`captureWidgets`）：終了コード 0（`Executed 2 tests, with 0 failures in 534.725 seconds`）。30 PNG、**`MISSING` 0 件、`NOTE` 0 件**。
  - `ax5`（`captureNormalScreens`、`captureWidgets`）：終了コード 0（`Executed 2 tests, with 0 failures in 563.489 seconds`）。30 PNG、**`MISSING` 0 件、`NOTE` 0 件**（r3 で落ちていた `captureWidgets` の `hook.widget.canvas` の高さ検査も 5 面すべて通過）。
  - `en`（`captureNormalScreens`、`captureWidgets`）：終了コード 0（`Executed 2 tests, with 0 failures in 523.702 seconds`）。30 PNG、**`MISSING` 0 件、`NOTE` 0 件**。

### コマンド 7：H22 の読み出し全体のスキーマ検査（contracts/test-hooks.md 7 章の 1 行）
- `~/.cache/reading-app/contracts-schema-venv/bin/python -I -c '…' contracts/hooks/h22-widget.schema.json <JSON>` を `evidence/h22/*.json` の 10 ファイル（`empty.json`、`explore_kinsoku_heavy.json`、`hidden.json`、`noLine.json`、`noLineNoPage.json`、`normal_horizontal.json`、`normal_vertical.json`、`showcase_w1_172x76.json`、`showcase_w1_horizontal.json`、`unavailable.json`）に実行。
- 結果：10 ファイルすべて `hook.widget OK`、終了コード 0、`files with errors: 0`（`evidence/logs/09-h22-schema.log`）。

## 2. 受け入れ条件ごとの結果
コマンド 2〜4 の結果（ja・en の 2 構成）。全 149 AC（計 155 テストメソッド）が ja・en の両構成で PASS。飛ばしたテストは 0。揺れの確認（4 章）で落ちたテストは 0。

| AC | 結果 | テスト | ja 成功/失敗 | en 成功/失敗 | 飛ばした | 証拠 |
|---|---|---|---|---|---|---|
| AC-1 | PASS | test_AC1_初回起動で空のしおり画面が出て許可ダイアログが出ない | 1/0 | 1/0 | 0 | `logs/03-ios-test-first-launch.tail.log`、`S1_empty_*.png` |
| AC-2 | PASS | test_AC2_バーコードで最初の1冊を加えると今の本になる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-3 | PASS | test_AC3_バーコード連続読取で重複と非図書を除きCコードで文庫を補う | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-4 | PASS | test_AC4_手入力欄で端末内書誌DBの候補から選んで保存できる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-5 | PASS | test_AC5_書誌DBの候補が0件でもそのまま手入力で保存できる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-6 | PASS | test_AC6_機内モードでも端末内書誌DBでバーコード登録が動く | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-7 | PASS | test_AC7_候補を選ばずに前後空白を除いて積読に保存できる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-8 | PASS | test_AC8_手入力の書名と著者の文字数境界を検証する | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-9 | PASS | test_AC9_書誌DB未取得時にその場で書名を入れて追加できる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-10 | PASS | test_AC10_書誌DBにないISBNをその場で書名入力して追加できる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-11 | PASS | test_AC11_未収録ISBNとCコードから岩波書店と文庫を補完する | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-12 | PASS | test_AC12_カメラ拒否時に設定とスクショと手入力の導線が出る | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-13 | PASS | test_AC13_本棚の3区分と積読の新しい順の並びを検証する | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-14 | PASS | test_AC14_積読や読了の本を今の本に切り替えられる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-15 | PASS | test_AC15_本の書名と著者を直しても記録が保たれる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log`、`S7a_normal_light.png`、`explore/X_R6_*.png` |
| AC-16 | PASS | test_AC16_今の本を消すと記録も消え今の本なしになる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-17 | PASS | test_AC17_本の画面の奥付5行と出版社レーベル受賞が出る | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-18 | PASS | test_AC18_奥付でデータのない行や不明の文字を出さない | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-19 | PASS | test_AC19_書名と著者の両方が一致するとき受賞が出る | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-20 | PASS | test_AC20_片方不一致や派生本には受賞を出さない | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-21 | PASS | test_AC21_記号や括弧の違いを正規化して受賞を照合する | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-22 | PASS | test_AC22_4時境目の晩の日付とタイムゾーン変更不変を検証する | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-23 | PASS | test_AC23_記録がない本の画面に空の案内が出る | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-24 | PASS | test_AC24_記録の分数を直すと合計分数が更新される | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-25 | PASS | test_AC25_記録の分数の入力境界値を検証する | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-26 | PASS | test_AC26_記録を消すと件数と合計と晩数が減る | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-27 | PASS | test_AC27_ロック画面ウィジェットに縦書きの一行とページが出る | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log`、`AC27_W1_153x68.png`、`AC27_W1_172x76.png`、`h22/normal_vertical.json` |
| AC-28 | PASS | test_AC28_縦書きの字形置換と行頭禁則処理を検証する | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log`、`AC28_W1_kinsoku.png` |
| AC-29 | PASS | test_AC29_26字以上の一行の句読点位置による縮め方を検証する | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log`、`AC29_W1_truncated.png` |
| AC-30 | PASS | test_AC30_欧文のみの一行は横書き1行で出る | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log`、`AC30_W1_horizontal.png`、`h22/normal_horizontal.json` |
| AC-31 | PASS | test_AC31_一行がないときは書名とページをウィジェットに出す | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log`、`h22/noLine.json`、`h22/noLineNoPage.json` |
| AC-32 | PASS | test_AC32_今の本がないときはウィジェットに空の文言が出る | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log`、`h22/empty.json`、`W1_empty_light.png` |
| AC-33 | PASS | test_AC33_しおり保存でウィジェットが1回だけ再読み込みされる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log`、`h22/unavailable.json`、`W1_error_light.png` |
| AC-34 | PASS | test_AC34_隠す設定オンでウィジェットとLiveActivityから書名と一行を隠す | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log`、`AC34_W1_hidden.png`、`AC34_S1_visible.png`、`h22/hidden.json` |
| AC-35 | PASS | test_AC35_StandBy用の小ウィジェットに縦書きの一行とページが出る | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log`、`AC35_W2_148x148.png`、`AC35_W2_170x170.png` |
| AC-36 | PASS | test_AC36_しおり保存で翌晩21時のLiveActivityが1件予約される | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-37 | PASS | test_AC37_LiveActivityオフ時は予約要求を出さず設定に案内を出す | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-38 | PASS | test_AC38_夜の入口の時刻を15分刻みで変えると予約時刻が変わる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-39 | PASS | test_AC39_予約がない晩でもアイコン起動でしおり画面が開き伏せ監視がオンになる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-40 | PASS | test_AC40_入口のURLと300秒境界で記録の入口の印が決まる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-41 | PASS | test_AC41_表示中の予約LiveActivityが読書中から結果表示へ遷移する | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-42 | PASS | test_AC42_起動から1タップで確認や入力なしに読み始められる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-43 | PASS | test_AC43_読書中の画面は押せる要素が終えるの1つだけになる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-44 | PASS | test_AC44_しおり画面で伏せて1秒たつと触覚が1回鳴り読み始める | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-45 | PASS | test_AC45_伏せて1秒未満で起こすと読み始めない | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-46 | PASS | test_AC46_今の本がないときは伏せの監視がオフで始まらない | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-47 | PASS | test_AC47_しおり画面以外や知らせ表示中は伏せても始まらない | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log`、`logs/06-flaky.summary.log` |
| AC-48 | PASS | test_AC48_読書中に起こしても止まらず伏せ直しても二重に始まらない | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-49 | PASS | test_AC49_伏せて読み始めたときにVoiceOver読み上げが1回出る | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-50 | PASS | test_AC50_しおり画面に伏せて始める案内の1行が出る | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-51 | PASS | test_AC51_伏せる設定オフまたは非対応環境では伏せても始まらない | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-52 | PASS | test_AC52_バックグラウンドの間も開始時刻からの差で時間を数える | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-53 | PASS | test_AC53_読書中に強制終了しても再起動後に続きから数える | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-54 | PASS | test_AC54_読書中も自動ロック無効化と近接センサー監視を使わない | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-55 | PASS | test_AC55_終える1タップで確認なしに500ミリ秒以内にしおり画面が出る | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log`、`logs/04-ios-test-perf.tail.log`（速さ） |
| AC-56 | PASS | test_AC56_59秒は記録せず60秒ちょうどから1分として記録する | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-57 | PASS | test_AC57_24時間超は1440分で止めて上限の知らせを出す | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-58 | PASS | test_AC58_端末時刻が開始より前に戻ったときは記録せず知らせを出す | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-59 | PASS | test_AC59_読み始めの保存失敗時はidleのままエラーを出す | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-60 | PASS | test_AC60_終わりの保存失敗時は読書中を保ち再試行で合算保存される | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-61 | PASS | test_AC61_開始と終了の二度押しで記録や画面が重複しない | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-62 | PASS | test_AC62_オフラインでもウィジェット起動からしおり保存まで完走する | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-63 | PASS | test_AC63_しおりを挟む画面に5つの道がすべて押せる状態で出る | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-64 | PASS | test_AC64_読まずにしおりだけを挟むと記録を増やさず更新される | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-65 | PASS | test_AC65_ページ写真OCRで一番左の列が初期選択され保存できる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-66 | PASS | test_AC66_OCR結果の別の列を選び直して保存できる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-67 | PASS | test_AC67_OCRの誤字を入力欄で手直しして保存できる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-68 | PASS | test_AC68_文字が1行も読み取れないときに撮り直しと手入力が出る | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-69 | PASS | test_AC69_撮影したページ画像と未選択列の文字を一切残さない | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-70 | PASS | test_AC70_しおり撮影でカメラ拒否時にスクショと手入力の導線が出る | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-71 | PASS | test_AC71_手入力の一行の前後空白を除いて保存する | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-72 | PASS | test_AC72_一行の1字から60字までの境界値を検証する | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-73 | PASS | test_AC73_ページ数だけ入れると一行が空になりウィジェットも書名とページになる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-74 | PASS | test_AC74_ページ番号の1から9999までの境界値と全角数字を検証する | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-75 | PASS | test_AC75_あとでを選ぶと前のしおりを保ち結果画面に分数だけが出る | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-76 | PASS | test_AC76_結果画面に前回ページからの遷移と分数が出て1タップで閉じる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-77 | PASS | test_AC77_読み終えたボタンで読了になり奥付5行と奥付撮影ボタンが出る | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-78 | PASS | test_AC78_次の1冊に積読の関連本2冊と未所有の関連本1冊が順に並ぶ | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-79 | PASS | test_AC79_次の1冊の各候補に事実1行の理由が出る | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-80 | PASS | test_AC80_未所有の候補がないときは積読から最大3冊を出す | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-81 | PASS | test_AC81_積読も未所有の候補もないときは本を加える案内が出る | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-82 | PASS | test_AC82_次の1冊で積読の本を選ぶと今の本になりウィジェットも更新される | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-83 | PASS | test_AC83_受賞一覧から出た未所有の本を積読に加えられる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-84 | PASS | test_AC84_読み終えのカード画像に書名著者晩数分数だけを描き一行を含めない | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-85 | PASS | test_AC85_読み終えのカードの晩数を4時境目のユニーク晩数で数える | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-86 | PASS | test_AC86_今の本がある毎晩の道には次の1冊の候補を出さない | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-87 | PASS | test_AC87_端末内書誌DBからシリーズの次の巻と同じ著者の本を推薦し書誌つきで積読に加える | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-88 | PASS | test_AC88_設定画面からプライバシーポリシーのURLを開く | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-89 | PASS | test_AC89_画面操作で入れた本と記録としおりと設定が再起動後もすべて残る | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-90 | PASS | test_AC90_起動時の保存先読込失敗でエラーを出し再起動で元のデータが戻る | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-91 | PASS | test_AC91_1_本を加える保存に失敗すると変更前のデータが保たれる<br>test_AC91_2_本を直す保存に失敗すると変更前のデータが保たれる<br>test_AC91_3_本を消す保存に失敗すると変更前のデータが保たれる<br>test_AC91_4_読み終える保存に失敗すると変更前のデータが保たれる<br>test_AC91_5_記録の分数を直す保存に失敗すると変更前のデータが保たれる<br>test_AC91_6_記録を消す保存に失敗すると変更前のデータが保たれる<br>test_AC91_7_しおりを挟む保存に失敗すると変更前のデータが保たれる | 7/0 | 7/0 | 0 | `logs/02-ios-test.tail.log`、`logs/06-flaky.summary.log` |
| AC-92 | PASS | test_AC92_NDL書誌の著者名から生没年や役割語や2人目以降を除いて整形する | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-93 | PASS | test_AC93_設定画面にNDLの3条件とCCBYリンクが出てしおり画面と読書中画面には出ない | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-94 | PASS | test_AC94_OCR待ちの間も1秒以内に手入力やページ入力に移り後から結果が返っても上書きされない | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-95 | PASS | test_AC95_読後のしおり保存失敗時も記録は残り入力値を保ったまま再保存できる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-96 | PASS | test_AC96_ウィジェットの置き方案内は最初の1回だけ出る | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-97 | PASS | test_AC97_LiveActivity予約失敗時はアラートを出さず次回前面復帰時に予約し直す | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-98 | PASS | test_AC98_読まなかった晩のLiveActivityは翌朝前面復帰で終了し今夜分を予約する | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-99 | PASS | test_AC99_ウィジェットとしおり画面のVoiceOverラベルに縦書き用字形が含まれない | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log`、`accessibility-audit.log`（W-1・W-2・S-5 すべて 0 件） |
| AC-100 | PASS | test_AC100_本3冊記録10件での起動から操作可能までの平均が1秒以内 | 1/0 | 1/0 | 0 | `logs/04-ios-test-perf.tail.log` |
| AC-101 | PASS | test_AC101_本500冊記録5000件での本棚と本の画面の表示平均が1秒以内 | 1/0 | 1/0 | 0 | `logs/04-ios-test-perf.tail.log`、`S1_normal_ax5.png` ほか `*_ax5.png` |
| AC-102 | PASS | test_AC102_ウィジェット2種類のタイムライン生成平均が500ミリ秒以内 | 1/0 | 1/0 | 0 | `logs/04-ios-test-perf.tail.log` |
| AC-103 | PASS | test_AC103_登録から読了カード共有まで外部HTTP通信が0件である | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-104 | PASS | test_AC104_未購入でも毎晩の道と読み終えた画面に課金案内が出ない | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-105 | PASS | test_AC105_鍵つき見た目を押すと見本と購入シートが出て閉じると標準に戻る | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-106 | PASS | test_AC106_購入すると見た目を選べてウィジェットと再起動後にも反映される | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log`、`AC106_S1_kinari.png` |
| AC-107 | PASS | test_AC107_購入の取りやめとエラー時に未購入と標準の見た目が保たれる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-108 | PASS | test_AC108_購入の復元で履歴の有無に応じた結果と文言が出る | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-109 | PASS | test_AC109_決済不可の端末では購入ボタンを出さず案内を出す | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-110 | PASS | test_AC110_オフラインで商品を読めないときは案内を出し読書は妨げない | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-111 | PASS | test_AC111_購入が返金されると前面復帰時に標準の見た目へ戻る | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-112 | PASS | test_AC112_同梱の受賞一覧データが仕様書の表と全行一致する | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-113 | PASS | test_AC113_奥付を1枚撮って著者出版社レーベル出版年ISBNを補完し画像を残さない | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-114 | PASS | test_AC114_読み始めるインテントでアプリを開かず読書とLiveActivityが始まる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log`、`logs/04-ios-test-perf.tail.log`（速さ） |
| AC-115 | PASS | test_AC115_どの状態から読み始めるインテントを動かしても二重に始まらない | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log`、`logs/04-ios-test-perf.tail.log`（速さ） |
| AC-116 | PASS | test_AC116_LiveActivityの終えるで動いた時刻で記録し場面に応じて画面を出す | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-117 | PASS | test_AC117_今の本がないときに読み始めるインテントはアプリを開いて空状態を見せる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-118 | PASS | test_AC118_LiveActivityオフ時の読み始めるインテントは読書を開始し前面可ならS2を出す | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-119 | PASS | test_AC119_読み始めるインテントで保存失敗時はエラーを返しLiveActivityを出さない | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-120 | PASS | test_AC120_隠す設定オンのとき読み始めるインテントのLiveActivityに書名を出さない | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-121 | PASS | test_AC121_どこまで読んだインテントは認証なしでページだけ答え一行と書名を出さない | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-122 | PASS | test_AC122_どこまで読んだインテントでページや今の本がないときの応答を検証する | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-123 | PASS | test_AC123_隠す設定オンでもどこまで読んだインテントはページを答え書名と一行を出さない | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-124 | PASS | test_AC124_続きを読むインテントはしおり画面を開き始まった読書にintent_openを付ける | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-125 | PASS | test_AC125_オフラインでも外からの3つのインテントとしおり保存がすべて動く | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-126 | PASS | test_AC126_AppShortcuts3種とControl1種の登録内容と言い方を検証する | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-127 | PASS | test_AC127_読み終えのふりかえり1行に晩数と合計時間と最長の晩が出てカードには載らない | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-128 | PASS | test_AC128_ふりかえり1行の1晩のみの文言と同点最長晩の新しい日付選択を検証する | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-129 | PASS | test_AC129_記録が0件の本を読み終えたときはふりかえり1行を出さない | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-130 | PASS | test_AC130_入口時刻前の読書開始で今夜の予約を取り消し終了時に予約を見直す | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-131 | PASS | test_AC131_読み始めるインテントでLiveActivity要求が失敗したらアプリを開いて読書を続ける | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-132 | PASS | test_AC132_LiveActivityの終えるで保存失敗時は読書を消さずS2にエラーを出す | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-133 | PASS | test_AC133_どこまで読んだインテントで読込失敗時はエラー文言だけを返し書名やページを出さない | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-134 | PASS | test_AC134_読書中に続きを読むインテントを動かすと読書中の画面を出す | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-135 | PASS | test_AC135_今の本がないときに続きを読むインテントはしおり画面の空状態を出す | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-136 | PASS | test_AC136_4時をまたぎLiveActivityが8時間上限で消えても読書は続き全分数が記録される | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-137 | PASS | test_AC137_表紙写真とスクリーンショットから2タップで書名と著者を選んで登録できる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-138 | PASS | test_AC138_本棚の1枚の写真から複数の背表紙を選んで一括で積読に加え1件一致の書誌を補う | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-139 | PASS | test_AC139_書名をあとでにして今すぐ読み始められ名無しの本は1冊に制限される | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-140 | PASS | test_AC140_名無しの今の本に後からバーコードで書名と奥付を入れると記録を保って更新される | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log`、`h22/noLine.json` |
| AC-141 | PASS | test_AC141_電子書籍の位置番号とパーセントのしおり保存と境界値を検証する | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-142 | PASS | test_AC142_カメラ拒否でもスクリーンショットから一行を選んで保存でき画像を残さない | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-143 | PASS | test_AC143_電子書籍の位置番号とパーセントに応じてどこまで読んだインテントが答える | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-144 | PASS | test_AC144_電子書籍のしおり画面と読書中画面に専用案内が出てLiveActivityから終えられる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-145 | PASS | test_AC145_今の本が0冊で積読があるときしおり画面に最大3冊出て1タップで今の本になる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-146 | PASS | test_AC146_読み終えた本の詳細画面にこの本のあとにが最大5冊出てその場で積読に加えられる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-147 | PASS | test_AC147_端末内の重み付けでよく選ぶ理由の候補が既定の順より上に繰り上がる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-148 | PASS | test_AC148_共起テーブルから文学NDC9かつ10人以上の本だけを人数を出さずに推薦する | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-149 | PASS | test_AC149_端末内書誌DBのISBN検索と書名検索の5回平均が300ミリ秒以内 | 1/0 | 1/0 | 0 | `logs/04-ios-test-perf.tail.log` |

## 3. 状態ごとの結果
| 状態 | 選んだもの | 結果 | 証拠のパス、または理由 |
|---|---|---|---|
| 初めて起動 | 自動 | PASS | コマンド 3（消した端末で単独実行、ja・en）、4 章の AC-1 5 回、`evidence/S1_empty_light.png`・`_dark`・`_ax5`・`_en` |
| データがある | 自動 | PASS | コマンド 2（UITEST_SEED を使う全テスト）。画面は `evidence/S1_normal_light.png`、`S6_normal_light.png`、`S7_normal_light.png`、`S9_normal_light.png` |
| 前の版からの更新 | 範囲外 | 範囲外 | 最初の機能で前の版のタグがない |
| オフライン、サーバーエラー | 自動 | PASS | コマンド 2 の AC-6、AC-9、AC-62、AC-110、AC-125。画面は `evidence/S10_offline_light.png`、`S10a_offline_light.png`（`store.offline`） |
| 権限を断った | 自動 | PASS | コマンド 2 の AC-12、AC-37、AC-70、AC-109、AC-118、AC-142。画面は `evidence/S3_denied_light.png`、`S7_denied_light.png`、`S7c_denied_light.png`、`S8_denied_light.png`、`S9_denied_light.png`、`S10_denied_light.png`、`S10a_denied_light.png` |
| バックグラウンドから復帰 | 自動 | PASS | コマンド 2 の AC-40、AC-52、AC-97、AC-98、AC-111、AC-130、AC-136（ja・en とも成功） |
| 言語と地域（ja、en） | 自動 | PASS | コマンド 2 の 2 構成（ja 150/150、en 150/150）。`L10n` で design/ 7-1 の en の文を比べる 17 AC も en で通った。画面は 27 画面＋3 枚の `*_en.png`（英語の文言、日本語の本のデータ。□ なし） |
| 大きい文字、ダークモード | 自動 | PASS | ダーク：`evidence/*_normal_dark.png` 30 枚（黒背景・白文字）。AX5：`evidence/*_normal_ax5.png` 30 枚（`S1_normal_ax5.png` で一行が横書き 2 行で全部読め、下端の伏せ案内も切れずに表示される。`captureWidgets` の AX5 の `hook.widget.canvas` の枠も 5 面すべて `showcase.canvasHeight` と 0.5pt 以内で一致）。`performAccessibilityAudit` は 7 章 |
| 容量不足、割り込み | 自動 | PASS | コマンド 2 の AC-59、AC-60、AC-90、AC-91（7 本すべて ja・en で成功）、AC-95、AC-119、AC-132、AC-133。画面は `evidence/S1_error_light.png`、`S1_loading_error_light.png`→`S1_error_after_loading_light.png`（H33＋H7）、`S2_error_light.png`、`S3a_saveError_light.png`、`S6_error_light.png`、`S7_error_light.png`、`S7c_error_light.png`、`S8a_error_light.png`、`S8b_error_light.png`、`S8d_error_light.png`、`S9_error_light.png`、`S10_error_light.png`、`S10a_error_light.png` |
| 実機だけで決まる確認（G4-1〜G4-22） | G4 の人 | G4 申し送り | test-plan.md 7 章のとおり |

## 4. 揺れの確認
影響「大」の AC を代表する 15 テスト、直した 5 テスト（AC-27、28、30、99、140）、AC-91 の 7 本、および `test_AC47` の計 27 テストに `-test-iterations 5 -run-tests-until-failure`（ja 構成、再試行なし）を実行した。r3 で落ちていた `test_AC91_2`・`test_AC91_5`・`test_AC91_6` は r4（コミット `e381991`）で再実行し 15 回中 15 回成功、`test_AC47` も 5 回中 5 回成功。合計 **135 回実行して落ちた回数 0**（`evidence/logs/06-flaky.summary.log`）。

| テストの名前 | コマンド | 回数 | 落ちた回数 | 原因の型 |
|---|---|---|---|---|
| BookmarkAcceptanceTests/test_AC65 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| BookmarkAcceptanceTests/test_AC69 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| RegistrationAcceptanceTests/test_AC3 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| RegistrationAcceptanceTests/test_AC140 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| SettingsStoreIntentsAcceptanceTests/test_AC91_1 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| SettingsStoreIntentsAcceptanceTests/test_AC91_2 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| SettingsStoreIntentsAcceptanceTests/test_AC91_3 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| SettingsStoreIntentsAcceptanceTests/test_AC91_4 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| SettingsStoreIntentsAcceptanceTests/test_AC91_5 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| SettingsStoreIntentsAcceptanceTests/test_AC91_6 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| SettingsStoreIntentsAcceptanceTests/test_AC91_7 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| SettingsStoreIntentsAcceptanceTests/test_AC90 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| SettingsStoreIntentsAcceptanceTests/test_AC103 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| SettingsStoreIntentsAcceptanceTests/test_AC114 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| SettingsStoreIntentsAcceptanceTests/test_AC116 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| WidgetAndActivityAcceptanceTests/test_AC27 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| WidgetAndActivityAcceptanceTests/test_AC28 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| WidgetAndActivityAcceptanceTests/test_AC30 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| WidgetAndActivityAcceptanceTests/test_AC34 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| WidgetAndActivityAcceptanceTests/test_AC99 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| ReadingSessionAcceptanceTests/test_AC44 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| ReadingSessionAcceptanceTests/test_AC47 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| ReadingSessionAcceptanceTests/test_AC53 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| ReadingSessionAcceptanceTests/test_AC55 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| ReadingSessionAcceptanceTests/test_AC60 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| FirstLaunchTests/test_AC1 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| PerformanceTests/test_AC100 | Perf、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |

## 5. 受け入れテストの変更
- この機能のテストを最初に入れたコミット：`8984b29`
- r3 の変更はコミット `3b8f606` に含まれている。
- 今回（r4）の作業ツリーの差分：`git diff 3b8f606 -- ios/AcceptanceTests`（`ios/AcceptanceTests/G3EvidenceCaptureTests.swift` 1 ファイル、7 行追加・7 行削除のみ。AC の判定を行う 7 クラスのテストファイルは 1 行も変えていない）。

| ファイル:行 | 何を変えたか | 根拠（PRD の行、契約） |
|---|---|---|
| `G3EvidenceCaptureTests.swift:363` | S-9 の読了カード見本を閉じるボタンの識別子を `shareCard.close` から `finish.card.close` に直した | design/001-reading-session.md 6 章の識別子表（`finish.card.close`）。撮影の道具のみ |
| `G3EvidenceCaptureTests.swift:368, 1614` | S-7c（奥付 OCR 画面）が開いたことの待ち受け識別子を `colophon.title` から `colophon.ocr.publisher` に直した | design/ 6 章の S-7c の欄の識別子（`colophon.ocr.publisher`）。`colophon.title` は S-7/S-9 の奥付表示行の識別子。撮影・監査の道具のみ |
| `G3EvidenceCaptureTests.swift:684` | S-3 empty 撮影用の `noLineSeed` の `page: 45` を `page: nil` に直した | design/ 5 章の S-3「空（前のしおりがない本で開いたとき）：『あとで』の添え字を `mark.later.note.empty` にする」。`page: 45` があると前のしおり（p.45）がある状態になるため、`page: nil` にして空の状態にした。撮影の道具のみ |
| `G3EvidenceCaptureTests.swift:1006` | S-7c partial 撮影時の存在確認を `element("colophon.publisher")` から `element("colophon.ocr.publisher")` に直した | design/ 6 章の S-7c の欄の識別子（`colophon.ocr.*`）。撮影の道具のみ |

AC のテストの待ち方・識別子・期待値の変更：r4 ではなし（r3 での変更はすべて PRD の Then の値か design/ 7-1 の文言（日英）に置き換えたもので、弱めたものはない）。

## 6. 検査の件数
| 検査 | コマンド | 件数 | 理由 |
|---|---|---|---|
| sleep で待つ | `grep -rnE 'sleep\(\|usleep\|Thread\.sleep\|time\.sleep\|asyncio\.sleep' ios/AcceptanceTests` | 0件 | — |
| 飛ばす、失敗を許す | `grep -rnE 'XCTSkip\|XCTExpectFailure\|pytest\.mark\.skip\|skipif\|xfail\|pytest\.skip\|unittest\.skip' ios/AcceptanceTests` | 0件 | — |
| 再試行 | `grep -rniE 'retry\|rerun' ios/AcceptanceTests`、および本書のコマンドの行 | 0件 | `-retry-tests-on-failure` は付けていない |
| 中を覗く import | `grep -rnE '@testable import' ios/AcceptanceTests` | 0件 | — |
| AC 番号の抜け、AC のないテスト | PRD の `AC-n`（1〜149）と `test_AC<n>_` の突き合わせ | 0件（149 / 149 一致。AC のテスト 155 本） | AC のない `test_G3_*` 5 本（撮影 4＋探索 1）は撮影・探索の道具で、`G3_CAPTURE` がなければ何もしない。AC の判定には数えない |
| 表示の文字や並び順で探す | `grep -rnE '(buttons\|staticTexts\|textFields\|cells\|switches)\["\|element\(boundBy:' ios/AcceptanceTests` | 0件 | — |
| 要素があるかだけを見る | `XCTAssertTrue(...exists)` だけのテスト（awk で機械的に抽出） | 0件 | すべて値の比較（`XCTAssertEqual`、`contains(期待値)`、`assertAC91Unchanged`、`XCTAssertLessThanOrEqual`）を行っている |
| 保存のテストに `app.terminate()` 後の確認がない | AC-91 の 7 本、AC-140、AC-3 など | 0件 | `relaunchPreservingStore()`（`app.terminate()`→`app.launch()`）のあとに `hook.store` を読む |

## 7. アクセシビリティ監査
`test_G3_accessibilityAudit`（light、`-uitest-readouts off`、`performAccessibilityAudit(for: .all)`）。27 画面、合計 **10 件**（`evidence/accessibility-audit.log`）。
r3 の 80 件から 70 件減少した。特に r3 で問題だった W-1・W-2・S-1・S-5・S-10a の縦書きの 1 字ずつの `StaticText` 指摘（計 66 件）と、S-3a・S-3b・S-3c の `mark.page.previous` の `Label not human-readable` 指摘（計 3 件）はすべて解消し、27 画面中 **21 画面が指摘 0 件** になった。残る 10 件はすべて軽微で AC 違反ではない。

| 画面 | 件数 | 見つかった問題（型：件数）と見方 |
|---|---|---|
| W-1（`accessoryRectangular:172x76`） | 0 | r3 の 16 件から 0 件に解消（縦書き全体が 1 つのアクセシビリティ要素になった） |
| W-2（`systemSmall:170x170`） | 0 | r3 の 14 件から 0 件に解消 |
| W-3（`liveActivity:370x160:waiting`） | 1 | Contrast nearly passed 1（`p.61`、31.7×18.0） |
| W-4（`control:160x72`） | 1 | Text clipped 1（`読み始める` 108.2×20.3。本物の Control のラベルはシステムが描くため G4 で確認） |
| W-5（`snippet:360x200`） | 0 | — |
| S-1（BookmarkHome） | 1 | Hit area is too small 1（`element=nil`）。r3 の縦書き 1 字の Contrast failed は解消 |
| S-2、S-3、S-3a、S-3b、S-4、S-5、S-6、S-7a、S-7b、S-7c、S-8、S-8a、S-8b、S-8c、S-8d、S-9、S-10 | 0 | S-3a・S-3b・S-5 も 0 件に解消 |
| S-3c（MarkOCR） | 3 | Text clipped 3（`element=nil`） |
| N（BannerNotice） | 1 | Hit area is too small 1（`element=nil`） |
| S-7（BookDetail） | 1 | Dynamic Type 一部非対応 1（NavigationBar のタイトル `羅生門`） |
| S-10a（StorePreview） | 2 | Hit area is too small 1（見本 `store.preview`）、Text clipped 1（`store.product.title`「よむま＋（買い切り）」147.3×20.3）。r3 の 15 件から 2 件に減少 |

## 8. 探索セッション
`test_G3_exploratory`（light、`G3_CAPTURE=1` のときだけ動く。手順ごとに `evidence/explore/X_<手順>.png` と `X_<手順>.tree.txt` を残す。結果の行は `evidence/logs/07-capture-steps-light.log` と `08-explore.tail.log`）。

### セッション 1（R6：本と記録の永続化。S-7a の欄の初期値と追記編集）
- チャーター：S-7a を「開いた直後の欄の値」「何も変えずに保存」「著者だけを直して保存」で探り、r3 で見つけた欄の初期値の不具合が直っているか確かめる
- 区切り：4 操作
- 試したこと：
  1. S-7a を開いて欄の `value` と `placeholderValue` を読む → `book.edit.title` は `value=羅生門`（`placeholder=書名`）、`book.edit.author` は `value=芥川龍之介`（`placeholder=著者（任意）`）。r3 では空で placeholder に今の値が入っていたが、今の値がテキストとして初期入力されるように直っている（`evidence/explore/X_R6_1_S_7a_open_fields.png`）。
  2. 何も変えず保存 → 書名「羅生門」著者「芥川龍之介」のまま、`book.title.invalid` なし。
  3. 著者の欄を押して「（改）」と打って保存 → 書名「羅生門」が保たれ、著者が「芥川龍之介（改）」になった（`evidence/explore/X_R6_3_S_7a_edit_author_only.png`）。
  4. S-7 の奥付は「羅生門 芥川龍之介（改） 岩波書店（岩波文庫） 1927年」（`evidence/explore/X_R6_4_S_7_after_edit.png`）。
- 見つけた不具合：**なし**（r3 の 11 章 (2) は完全に解消）

### セッション 2（R4：ウィジェットと隠す設定）
- チャーター：禁則の字の多い 25 字の一行と `hideOnWidgets` の切り替えで、字の欠けと書名・一行の漏れを探る
- 区切り：3 操作
- 試したこと：(1)「「あ」と、「い」と、「う」と、「え」と、「お」と。」（25 字）を 4 枠で組む → 4 枠とも `cells` を並べた字が `displayedLine` と同じ（欠け 0 字、`evidence/h22/explore_kinsoku_heavy.json`）。(2) S-10 で `settings.hideOnWidgets` をオン → `hook.widget` の `state` が `hidden`、書名も一行も含まれない。`hook.liveActivity` にも含まれない。(3) オフに戻す → `normal` に戻り、書名と一行が戻る
- 見つけた不具合：**なし**

### セッション 3（R1：4:00 をまたぐ読書）
- チャーター：03:50 に読み始めて 04:10 に終えたとき、晩の日付と何晩・合計が正しいか
- 区切り：2 操作
- 試したこと：10/17 03:50 に開始、20 分後に終了（`mark.later`）→ 記録の `nightDate` は `2026-10-16`（前日の晩）、分数 20。S-7 は「3晩」「合計 65分」（10/14、10/15、10/16 の 3 晩、20＋25＋20）
- 見つけた不具合：**なし**

## 9. スクリーンショットとログ
置き場所：`docs/verification/001-reading-session/evidence/`。計 **222 枚の PNG**（＋`evidence/explore/` に **9 枚の PNG** と 9 個の `.tree.txt`）。r3 で残っていた `*_asis_light.png` 4 枚と `AC91_2_saveError_double.png` はすべて削除し、`asis` のつく画像は **0 枚** になった。すべて撮影用テストが `XCTAttachment`（keepAlways）と同時に書き出したもので、同じ画像を別名で複製していない。

### 通常の状態（ライト / ダーク / AX5 / 英語の 4 通り、各 27 画面＋3 枚＝30 枚、計 120 枚）
`W1`〜`W5`、`S1`、`S2`、`S3`、`S3a`、`S3b`、`S3c`、`S4`、`S5`、`S6`、`S7`、`S7a`、`S7b`、`S7c`、`S8`、`S8a`、`S8b`、`S8c`、`S8d`、`S9`、`S10`、`S10a`、`N` の `<画面>_normal_<light|dark|ax5|en>.png`、および `S1_empty_*`、`S6_empty_*`、`S9_card_*`。
- 目で確かめた：
  - `S1_normal_ax5.png`：一行が横書き 2 行で全部読め、下端の伏せ案内「画面を伏せても始められます」も切れずに収まっている（r3 の 11 章 (9) 解消）。
  - `S7a_normal_light.png`・`S3c_normal_light.png`：欄に現在の値（「羅生門」「芥川龍之介」、および選択した列の一行）が濃い文字色（入力済みテキスト）で入っている（r3 の 11 章 (2) 解消）。
  - `S9_normal_light.png`：見出し `finish.summary` とふりかえり 1 行 `finish.reflection` が重ならず整理されている（r3 の 11 章 (6) 解消）。
  - `W1_normal_ax5.png`〜`W5_normal_ax5.png`：AX5 でも `hook.widget.canvas` の枠が `showcase.canvasHeight` と 0.5pt 以内で一致し、枠からはみ出していない（r3 の 11 章 (5) 解消）。

### 通常以外の状態（ライト、標準の文字、計 102 枚）
- W1 empty / error / partial / noLine / pending / loading（placeholder）、W2 empty / error / partial / loading、W3 reading / ended / empty / partial、W5 empty / partial
- S1 error / noCurrent / partial / loading（H33）/ loading_error→error_after_loading（H33＋H7）、S2 error / partial、S3 empty（`mark.later.note.empty` 表示）/ denied / partial、S3a empty / error / saveError、S3b empty / error、S3c empty / loading / error（61 字）/ partial、S4 empty / partial、S5 partial、S6 error（`shelf.load` 失敗の赤帯）/ partial / loading（H33）、S7 empty / denied / error / partial / loading（H33）、S7a empty / error、S7b empty / error、S7c empty（`mark.ocr.none` と `colophon.retake` 表示）/ loading / denied / error / partial（出版社「岩波書店」と出版年「1927」）、S8 empty / denied / partial、S8a empty（`barcode.WaitHint` 表示）/ error / partial / loading（H33 `catalog.lookup`）、S8b empty / loading / error（`cover.ocr.none` 表示）/ partial、S8c empty / error / partial / loading（H33 `catalog.lookup`）、S8d empty / loading / error / partial、S9 empty / denied（`camera.denied` 表示）/ error / partial / loading（H33）、S10 loading（H33 `storekit.restore=shown` でスピナー表示）/ offline / denied / partial / error、S10a offline / denied / error / unavailable / loading（H33 `storekit.products`）/ partial、N error
- AC 指定の画像（11 枚）：`AC27_W1_153x68`、`AC27_W1_172x76`、`AC28_W1_kinsoku`、`AC29_W1_truncated`、`AC30_W1_horizontal`、`AC34_W1_hidden`、`AC34_S1_visible`、`AC35_W2_148x148`、`AC35_W2_170x170`、`AC106_S1_kinari`。
- 裁定 92 の 7 状態の確認：`S3_empty_light.png`、`S9_denied_light.png`、`S7c_empty_light.png`、`S6_error_light.png`、`S8a_empty_light.png`、`S8b_error_light.png`、`S10_error_light.png` の 7 枚すべてが期待した識別子を伴って撮れていることを `07-capture-steps-light.log`（`MISSING` 0 件）と目視で確かめた。

### H22 の読み出し（`evidence/h22/`）
`normal_vertical.json`、`normal_horizontal.json`、`noLine.json`、`noLineNoPage.json`、`hidden.json`、`empty.json`、`unavailable.json`、`showcase_w1_172x76.json`、`showcase_w1_horizontal.json`、`explore_kinsoku_heavy.json`（計 10 ファイル、すべてスキーマ検査 OK）。

### ログ（`evidence/logs/` ほか）
`00-test-target-build.tail.log`、`00-targeted.tail.log`、`02-ios-test.tail.log`、`02-ios-test.counts.log`、`03-ios-test-first-launch.tail.log`、`04-ios-test-perf.tail.log`、`05-check-contracts.tail.log`、`06-flaky.summary.log`、`07-capture.summary.log`、`07-capture-steps-<light|dark|ax5|en>.log`、`08-explore.tail.log`、`09-h22-schema.log`、および `evidence/accessibility-audit.log`、`evidence/design-checks.log`、`evidence/red.log`。

## 10. 前の機能の受け入れテスト（回帰）
該当なし（最初の機能）。

## 11. 見つかった問題
r3 で挙げた (1)〜(9) の問題は、ios-engineer の 11〜14 回目の直し（`8adbf95`、`804b050`、`e381991`）ですべて解消したことを実際の動作と証拠画像・ログで確かめた。
- 解消確認済み：
  - r3 (1) AC-91 の `common.save.error` 二重出現 → 解消（AC-91 の 7 本すべてが ja・en と 5 回反復で PASS）
  - r3 (2) S-7a・S-3c の欄の初期値 → 解消（`value` に現在の値が入る。`S7a_normal_light.png`、探索 R6）
  - r3 (3) W-1・W-2・S-1・S-5・S-10a の縦書きの 1 字ずつの要素 → 解消（`performAccessibilityAudit` で W-1・W-2・S-5 とも 0 件）
  - r3 (4) H33 `storekit.restore` が `shown` にならない → 解消（`hold.storekit.restore=shown` になり `S10_loading_light.png` が撮れた）
  - r3 (5) AX5 の `hook.widget.canvas` の高さ不一致 → 解消（`captureWidgets` が AX5 で PASS）
  - r3 (6) S-9 の「3晩、83分」の重複表示 → 解消（`S9_normal_light.png`）
  - r3 (7) 監査の 80 件 → 10 件に減少（7 章）
  - r3 (8) 裁定 92 の 7 状態（S-3 empty、S-9 denied、S-7c empty ほか）→ 解消（すべて `asis` なしで撮影完了）
  - r3 (9) AX5 の S-1 の下端の伏せ案内の切れ → 解消（`S1_normal_ax5.png`）

残る軽微な提案（AC 違反ではなく G3 の PASS を妨げないもの）：

| # | 内容 | 再現の手順 | 再現するテストの名前 | AC | 重大度 | 直す役 |
|---|---|---|---|---|---|---|
| (1) | AX5 の S-7a（`S7a_normal_ax5.png`）で、スクロール前の初期表示の下端（固定の「保存」バーの直上）で「単位」ラベルの下半分が切れて見える（スクロールすれば `ProgressUnitPicker` まで操作・閲覧できるため機能上の支障はない） | AX5 で S-7a を開く | なし（目視） | なし（見た目） | 提案 | ios-engineer |
| (2) | 7 章の `performAccessibilityAudit` の残り 10 件（W-3 の `p.61` Contrast nearly passed、W-4 の `読み始める` Text clipped、S-7 の NavigationBar タイトルの Dynamic Type 一部非対応、S-10a の `store.product.title` Text clipped など） | 7 章 | `test_G3_accessibilityAudit` | なし | 提案 | ios-engineer |

## 12. PRD とテストの食い違い
なし。

## 13. 未検証のものと理由
- G3（シミュレータで検証できる範囲）で未検証のもの：**なし**（全 149 AC、全 27 画面×4 バリアント、異常系・境界値・H33 読み込み中・H22 スキーマ検査すべて完了）。
- 実機だけで決まる確認（G4-1〜G4-22：実機のカメラ・バーコード・OCR・照度センサー・机に伏せる動作・触覚・ロック画面ウィジェット・StandBy・Dynamic Island・Control Center・Siri・StoreKit 実決済・VoiceOver 実機読み上げ）は `test-plan.md` 7 章のとおり G4 で Takuma が実機で確かめる。
