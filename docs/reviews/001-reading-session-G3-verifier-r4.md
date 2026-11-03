PASS

## 指摘
- 重大度：提案（AC の外、G3 の PASS を妨げない軽微な確認メモ）
  - (1) AX5 の S-7a（`docs/verification/001-reading-session/evidence/S7a_normal_ax5.png`）で、スクロール前の初期表示の下端（固定の「保存」バーの直上）で「単位」ラベルの下半分が切れて見える（スクロールすれば `ProgressUnitPicker` まで操作・閲覧できるため機能上の支障はない）。直す役：ios-engineer（任意）。
  - (2) `performAccessibilityAudit(for: .all)`（`-uitest-readouts off`）の残り 10 件（27 画面中 21 画面は 0 件。W-1・W-2・S-5・S-3a・S-3b は 0 件に解消。残りは W-3 の `p.61` Contrast nearly passed 1、W-4 の `読み始める` Text clipped 1、S-1 の `element=nil` Hit area 1、S-3c の `element=nil` Text clipped 3、N の `element=nil` Hit area 1、S-7 の NavigationBar タイトル Dynamic Type 一部非対応 1、S-10a の `store.preview` Hit area 1 と `store.product.title` Text clipped 1）。直す役：ios-engineer（任意）。
- 食い違い：なし。

## 証拠
- 指示書 1〜4 の結果（詳細は `docs/verification/001-reading-session/verification.md`）：
  1. `ios/AcceptanceTests/G3EvidenceCaptureTests.swift` の 4 か所（計 7 行）を修正：
     - 363 行：`shareCard.close` → `finish.card.close`（design/ 6 章の識別子）
     - 368 行・1614 行：`colophon.title` → `colophon.ocr.publisher`（S-7c の欄の識別子）
     - 684 行：S-3 empty 用の `noLineSeed` の `page: 45` → `page: nil`（一行もページもない本にすることで `mark.later.note.empty` が出る条件を満たす）
     - 1006 行：S-7c partial の `colophon.publisher` → `colophon.ocr.publisher`
     - AC の判定を行う 7 クラスのテストファイルは 1 行も変えていない。
  2. テストの実行と揺れの確認（再試行なし、`SIM_DESTINATION='platform=iOS Simulator,id=E5664965-B285-4795-9EE7-2D890556B3BE'`）：
     - `xcodebuild build-for-testing`：終了コード 0、製品ターゲット・受け入れテストターゲットともコンパイラ警告 0 件（`evidence/logs/00-test-target-build.tail.log`）。
     - `swift test --package-path ios/ReadingKit`：19 + 37 = 56 単体テスト passed。
     - 受け入れテスト全 7 クラス（計 150 テスト＝149 AC 分）：`Japanese (ja)` **150/150 成功（失敗 0、スキップ 0）**、`English (en)` **150/150 成功（失敗 0、スキップ 0）**（`evidence/logs/02-ios-test.counts.log`、`02-ios-test.tail.log`）。r3 で落ちていた `test_AC91_2`・`test_AC91_5`・`test_AC91_6` を含む AC-91 の 7 本すべてが ja・en で PASS。
     - 揺れの確認（`-test-iterations 5 -run-tests-until-failure`、ja）：r3 で落ちていた `test_AC91_2`・`test_AC91_5`・`test_AC91_6`（計 15 回）および `test_AC47`（5 回）を含む全 27 テスト×5 回＝**135 回すべて成功、失敗 0**（`evidence/logs/06-flaky.summary.log`）。
     - `xcrun simctl erase` 後の `make ios-test-first-launch`：ja 1/1、en 1/1 成功（`evidence/logs/03-ios-test-first-launch.tail.log`）。
     - `make ios-test-perf`：ja 4/4、en 4/4 成功（`evidence/logs/04-ios-test-perf.tail.log`）。
     - `make check-contracts`：8 スキーマ・29 例すべて 0 エラーで PASS（`evidence/logs/05-check-contracts.tail.log`）。
  3. 証拠の撮り直しとアクセシビリティ監査：
     - `G3EvidenceCaptureTests` を `light`・`dark`・`ax5`・`en` の 4 通りで実行し、すべて終了コード 0、**`MISSING` 0 件、`NOTE` 0 件**（`evidence/logs/07-capture.summary.log`）。
     - 計 222 PNG + `explore/` 9 PNG を更新。r3 で `asis` だった `S3_empty_light.png`（`mark.later.note.empty` 表示）、`S9_denied_light.png`（`camera.denied` 表示）、`S7c_empty_light.png`（`mark.ocr.none` と `colophon.retake` 表示）、`S10_loading_light.png`（`hold.storekit.restore=shown` でスピナー表示）がすべて期待どおりの要素つきで撮れ、古い `*_asis_light.png` 4 枚と `AC91_2_saveError_double.png` を削除（`asis` 画像 0 枚）。
     - AX5 の `captureWidgets` も `hook.widget.canvas` の高さが `showcase.canvasHeight` と 0.5pt 以内で一致し、5 面すべて `TEST SUCCEEDED`。
     - S-7a（`book.edit.title`、`book.edit.author`）と S-3c（`mark.lineField`）の欄に今の値が初期値として入っていることを確かめた（探索 R6 `evidence/explore/X_R6_1_S_7a_open_fields.png`〜`X_R6_4_S_7_after_edit.png`）。
     - `performAccessibilityAudit(for: .all)`：27 画面で合計 **10 件**（r3 の 80 件から 70 件減。21 画面で指摘 0 件。縦書きの 1 字ずつの StaticText 指摘は 0 件）。
     - H22 の JSON 10 ファイルのスキーマ検査：10 ファイルすべて `hook.widget OK`、エラー 0（`evidence/logs/09-h22-schema.log`）。
  4. 検査の件数（6 章）：sleep 0、skip 0、retry 0、`@testable import` 0、表示の文字／`boundBy` 0、AC 番号抜け 0（149/149 一致）、`exists` のみ 0、`app.terminate()` 後確認抜け 0。

## 変更したファイル
- `/Users/takumamatsuura/reading-app/ios/AcceptanceTests/G3EvidenceCaptureTests.swift`（撮影・監査の道具の識別子 4 か所・計 7 行のみ）
- `/Users/takumamatsuura/reading-app/docs/verification/001-reading-session/verification.md`（r4 PASS に全面更新）
- `/Users/takumamatsuura/reading-app/docs/verification/001-reading-session/test-plan.md`（実行状況の更新）
- `/Users/takumamatsuura/reading-app/docs/verification/001-reading-session/evidence/`（222 PNG、`explore/` 9 PNG + 9 tree、`h22/*.json` 10 ファイル、`logs/*`、`accessibility-audit.log`、`design-checks.log` 更新、旧 `*_asis_light.png` 4 枚と `AC91_2_saveError_double.png` 削除）

## 未解決
- なし（シミュレータで検証できる G3 範囲はすべて完了。G4-1〜G4-22 は実機確認へ申し送り）。

## 記録（指揮役が保存するときに書き足す）
- 関門：G3 r4（ios-engineer 11〜14体目 `8adbf95`・`804b050`・`e381991`、reviewer r2 `3b8f606` PASS のあと）。日付：2026-11-04。BASE `3b8f606`
- 範囲の確かめ：変更は `ios/AcceptanceTests/G3EvidenceCaptureTests.swift`（撮影用のみ）と `docs/verification/001-reading-session/` だけ。製品のコード、contracts、design、Makefile、`.claude`、`.github` は一切触っていない。
- 裁定：
  - 38. `verifier` r4 の判定 **PASS**（全 149 AC が ja・en の両構成で 150/150 成功、揺れの確認 27 テスト×5 回＝135/135 成功、初回起動・性能・契約スキーマ検査・証拠撮影 222 PNG + explore 9 PNG すべて成功、`MISSING` 0 件・`NOTE` 0 件・`asis` 画像 0 枚、アクセシビリティ監査 80 件→10 件）を採る。次は `design-reviewer` r2 で実画面とアクセシビリティの最終判定を行う。
