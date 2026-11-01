# 検証レポート 001-reading-session（G3 再検証 r2）

置き場所：docs/verification/001-reading-session/verification.md

判定：FAIL

- 関門：G3（design-reviewer r1 の FAIL を受けた ios-engineer の直し `31633e3` のあとの再検証）
- 検証した役：verifier　日時：2026-11-02 01:10
- コミット：`818a07e16b15bdbfc64da432f242fa64ff3511d6`（作業ツリーに ios/AcceptanceTests/WidgetAndActivityAcceptanceTests.swift の撮影用クラスの追加と docs/verification/ の更新が未コミットで載っている）
- 環境：macOS（Darwin 27.2.0）、Xcode 27.2、iOS Simulator `iPhone 17`（iOS 26.0、UDID `E5664965-B285-4795-9EE7-2D890556B3BE`。同名の端末が2台あるため `SIM_DESTINATION='platform=iOS Simulator,id=E5664965-…'` で固定）、バックエンドの接続先：なし（サーバーを持たない）

FAIL の理由（1つでもあれば FAIL）：`make ios-test` が終了コード 2（テストランナーの不時停止で片方の構成が最後まで走らず）、`make check-contracts` がこの環境で実行できない、AC-27・AC-101 に画像で確かめられる不具合が残る（11 章）、design 5 章の状態のうち 11 組が撮れていない（9 章）。

## 1. 実行したコマンドと結果
再試行（`-retry-tests-on-failure`）は一切付けていない。すべて `docs/verification/001-reading-session/evidence/logs/` に末尾のログを残した（完全なログは /private/tmp の作業フォルダ）。

### コマンド 1：`make ios-build`
- 終了コード：0
- 出力：`** BUILD SUCCEEDED **`（`evidence/logs/01-ios-build.tail.log`）

### コマンド 2：`make ios-test SIM_DESTINATION='platform=iOS Simulator,id=E5664965-B285-4795-9EE7-2D890556B3BE'`
- 終了コード：2（`make: *** [ios-test] Error 65`）
- `swift test --package-path ios/ReadingKit`：通過（ログ冒頭）
- xcodebuild：`Japanese (ja)` と `English (en)` の2構成。ログに `Restarting after unexpected exit, crash, or test timeout` が1回あり、`** TEST FAILED **`。スイート単位の `Executed` 行はすべて `0 failures` で、構成全体の `Executed 148 tests, with 0 failures` が1行しか出ていない（もう片方の構成がランナーの不時停止で合計を出していない）。どのテストで止まったかはログからは確定できなかった（`evidence/logs/02-ios-test.tail.log`）。
- 件数：成功 148（1構成分）＋不時停止前のスイート分、失敗 0、飛ばした 0。もう片方の構成の合計は未確定。
- 判定：この再検証では合格の根拠にならない（再実行が必要）。同じ型のランナーの不時停止は撮影用テストの初回実行（`evidence/logs/07-capture.summary.log` の `capture-light`）でも1回起きた。原因の型は「待ち方・順番」ではなく、アプリ起動直後の automation session の確立に失敗する環境要因と見ている。

### コマンド 3：`xcrun simctl shutdown E5664965-…; xcrun simctl erase E5664965-…; make ios-test-first-launch SIM_DESTINATION='…id=E5664965-…'`
- 終了コード：0
- 出力：`** TEST SUCCEEDED **`（FirstLaunchTests、ja・en の2構成。`evidence/logs/03-ios-test-first-launch.tail.log`）

### コマンド 4：`make ios-test-perf SIM_DESTINATION='…id=E5664965-…'`
- 終了コード：0
- 件数：`Executed 4 tests, with 0 failures (0 unexpected) in 242.830 seconds`（`evidence/logs/04-ios-test-perf.tail.log`）

### コマンド 5：`make check-contracts`
- 終了コード：2
- 理由：Makefile の `SCHEMA_PYTHON=/tmp/reading-app-schema-venv/bin/python` が存在しない（/tmp の venv が消えている）。**この環境では実行できない**。tech-lead に、venv を作り直す手順（contracts/dependencies.md）か、リポジトリ内に置ける形への変更を頼む（`evidence/logs/05-check-contracts.tail.log`）。

### コマンド 6：証拠の撮影（撮影用テスト、AC の判定には使わない）
- `TEST_RUNNER_G3_CAPTURE=1 TEST_RUNNER_G3_VARIANT=<light|dark|ax5|en> TEST_RUNNER_G3_OUT_DIR=<外のフォルダ> xcodebuild test -project ios/ReadingApp.xcodeproj -scheme ReadingApp -configuration Debug -destination 'platform=iOS Simulator,id=E5664965-…' -only-testing:ReadingAcceptanceTests/G3EvidenceCaptureTests -only-test-configuration "Japanese (ja)"`（en は `"English (en)"`。ダークは先に `xcrun simctl ui E5664965-… appearance dark`）
- 結果（`evidence/logs/07-capture.summary.log`、各ステップの OK / MISSING は `evidence/logs/07-capture-steps.log`）：
  - light：`captureNormalScreens` passed、`captureWidgets` passed、`accessibilityAudit` passed、`captureStates` failed（撮れなかった状態が 11 組。9 章）
  - dark / ax5 / en：4 テストすべて passed

## 2. 受け入れ条件ごとの結果
r1（2026-10-29、コミット `e90963f`）では全 149 AC の受け入れテストが ja・en の2構成で通った。今回（直し `31633e3` のあと）は `make ios-test` が片方の構成の途中でランナーの不時停止により完走せず、しかも停止位置を特定できないため、**全 149 AC を「この実行では合格の証拠がそろわない」扱いにする**。個別に再実行して通ったもの（4 章の 15 テスト×5 回、FirstLaunchTests、PerformanceTests）だけを PASS とする。

| AC | 結果 | 動いたテストの数 | 飛ばしたテストの数 | 証拠 |
|---|---|---|---|---|
| AC-1 | PASS | 2（ja・en）＋5（揺れ） | 0 | コマンド 3、`evidence/logs/06-flaky.summary.log` 1 行目、`evidence/S1_empty_light.png`・`S1_empty_dark.png`・`S1_empty_ax5.png`・`S1_empty_en.png` |
| AC-3 | PASS | 5（揺れ） | 0 | `evidence/logs/06-flaky.summary.log`（test_AC3） |
| AC-27 | 未検証（画像で食い違い） | 5（揺れ、H22 の読み出しは通る） | 0 | `evidence/AC27_W1_172x76.png`・`AC27_W1_153x68.png`：172×76 指定の見本が約 133×120pt の枠で描かれ、縦書き14字のうち「い。」の2字が欠けて12字しか見えない。H22 の読み出し（欠け0字）と画像が一致しない。11 章 (2) |
| AC-34 | PASS | 5（揺れ） | 0 | `evidence/logs/06-flaky.summary.log`（test_AC34）、`evidence/AC34_W1_hidden.png`、`AC34_S1_visible.png` |
| AC-44, AC-53, AC-55, AC-60 | PASS | 各 5（揺れ） | 0 | `evidence/logs/06-flaky.summary.log` |
| AC-65, AC-69 | PASS | 各 5（揺れ） | 0 | 同上、`evidence/S3c_normal_light.png` |
| AC-90, AC-103, AC-114, AC-116 | PASS | 各 5（揺れ） | 0 | 同上 |
| AC-100 | PASS | 5（揺れ、Perf）＋1（コマンド 4） | 0 | `evidence/logs/06-flaky.summary.log` 15 行目、`evidence/logs/04-ios-test-perf.tail.log` |
| AC-55, AC-101, AC-102, AC-114, AC-115, AC-149（速さ） | PASS（速さの数値のみ） | 4（コマンド 4） | 0 | `evidence/logs/04-ios-test-perf.tail.log` |
| AC-101（Dynamic Type の見た目） | FAIL | — | — | `evidence/S1_normal_ax5.png`：AX5 で S-1 の一行（`bookmark.line`）が下端の `bookmark.start` の裏に隠れ、文字の上端の断片だけが見える。11 章 (3) |
| 上記以外の AC-2〜AC-149 | 未検証（この実行） | コマンド 2 のスイート単位では失敗 0 | 0 | コマンド 2 の不時停止により構成全体の完走を示せない。再実行で確定させる |

## 3. 状態ごとの結果
| 状態 | 選んだもの | 結果 | 証拠のパス、または理由 |
|---|---|---|---|
| 初めて起動 | 自動 | PASS | コマンド 3（消した端末で単独実行）、`evidence/S1_empty_light.png` ほか 4 通り |
| データがある | 自動 | 未検証（この実行） | コマンド 2 が完走していない。画面は `evidence/S1_normal_light.png`、`S6_normal_light.png`、`S7_normal_light.png`、`S9_normal_light.png` |
| 前の版からの更新 | 範囲外 | 範囲外 | 最初の機能で前の版のタグがない |
| オフライン、サーバーエラー | 自動 | 一部 | `evidence/S10a_offline_light.png`（`store.offline`）。S-10 の復元オフラインは `notice` が出ず撮れていない（9 章） |
| 権限を断った | 自動 | 一部 | `evidence/S3_denied_light.png`、`S8_denied_light.png`、`S10_denied_light.png`（Live Activity オフ）、`S10a_denied_light.png`。S-7・S-7c・S-9 のカメラ拒否は撮れていない（9 章、11 章 (5)） |
| バックグラウンドから復帰 | 自動 | 未検証（この実行） | AC-52、AC-97、AC-98 などはコマンド 2 の中。再実行で確定 |
| 言語と地域（ja、en） | 自動 | PASS（画面） | 全 27 画面の `*_normal_en.png`（例 `evidence/S1_normal_en.png` は英語の文言と英語の一行で描かれている） |
| 大きい文字、ダークモード | 自動 | FAIL | ダーク：`evidence/S1_normal_dark.png` ほか 27 枚は本当にダーク。AX5：`evidence/S1_normal_ax5.png` で一行が隠れる（11 章 (3)） |
| 容量不足、割り込み | 自動 | 一部 | `evidence/S1_error_light.png`、`S2_error_light.png`、`S3a_saveError_light.png`、`S7_error_light.png`、`S8a_error_light.png`、`S8d_error_light.png`、`S10a_error_light.png`。S-10 の設定保存失敗は `common.save.error` が出ず撮れていない |
| 実機だけで決まる確認（G4-1〜G4-22） | G4 の人 | G4 申し送り | test-plan.md 7 章のとおり |

## 4. 揺れの確認
影響「大」の AC を代表する 15 テストに `-test-iterations 5 -run-tests-until-failure`（ja 構成、再試行なし）。75 回すべて成功、落ちた回数 0（`evidence/logs/06-flaky.summary.log`）。

| テストの名前 | 回数 | 落ちた回数 |
|---|---|---|
| FirstLaunchTests/test_AC1 | 5 | 0 |
| RegistrationAcceptanceTests/test_AC3 | 5 | 0 |
| ReadingSessionAcceptanceTests/test_AC44、test_AC53、test_AC55、test_AC60 | 各 5 | 0 |
| BookmarkAcceptanceTests/test_AC65、test_AC69 | 各 5 | 0 |
| WidgetAndActivityAcceptanceTests/test_AC27、test_AC34 | 各 5 | 0 |
| SettingsStoreIntentsAcceptanceTests/test_AC90、test_AC103、test_AC114、test_AC116 | 各 5 | 0 |
| PerformanceTests/test_AC100（Perf） | 5 | 0 |

コマンド 2 のランナー不時停止は、どのテストかを特定できていないため、この表に足せていない。

## 5. 受け入れテストの変更
- この機能のテストを最初に入れたコミット：`8984b29`（確定 `3f26059`）
- コマンド：`git diff 818a07e -- ios/AcceptanceTests`（今回の差分）、`git diff 3f26059..818a07e -- ios/AcceptanceTests`（r1 までの差分は r1 の 5 章のとおり）

| ファイル:行 | 何を変えたか | 根拠 |
|---|---|---|
| `ios/AcceptanceTests/WidgetAndActivityAcceptanceTests.swift`（末尾、`final class G3EvidenceCaptureTests`、+1,305 行） | G3 の証拠撮影の道具を追加（画面×状態の撮影、全画面の `performAccessibilityAudit(for: .all)`）。test runner の環境変数 `G3_CAPTURE=1` がないと何もせずに終わるので `make ios-test` の判定には影響しない（ja・en で 4 件ずつ 0.3 秒で通る）。AC のテストは1行も変えていない | docs/org/gates.md G3（画面×状態のスクリーンショットと監査）。新しいファイル `G3EvidenceCaptureTests.swift` に置きたかったが、`ios/ReadingApp.xcodeproj` のテストターゲットがファイルを明示列挙していて verifier の範囲外のため、既存ファイルの末尾に置いた（13 章） |
| `ios/AcceptanceTests/FirstLaunchTests.swift` | 前の verifier が途中で残した撮影用テスト 3 本（+1,306 行、未コミット）を取り除き、コミット `818a07e` の内容に戻した | H14（AC-1）の「消した端末で単独で動かす」前提を守るため |

AC のテストの期待値・待ち方・識別子の変更：なし。

## 6. 検査の件数
| 検査 | コマンド | 件数 | 理由 |
|---|---|---|---|
| sleep で待つ | `grep -rnE 'sleep\(\|usleep\|Thread\.sleep\|time\.sleep\|asyncio\.sleep' ios/AcceptanceTests` | 0件 | — |
| 飛ばす、失敗を許す | `grep -rnE 'XCTSkip\|XCTExpectFailure\|pytest\.mark\.skip\|skipif\|xfail\|pytest\.skip\|unittest\.skip' ios/AcceptanceTests` | 0件 | — |
| 再試行 | `grep -rniE 'retry\|rerun' ios/AcceptanceTests` | 0件 | — |
| 中を覗く import | `grep -rnE '@testable import' ios/AcceptanceTests` | 0件 | — |
| AC 番号の抜け | PRD の `AC-n` と `AC<n>_` の突き合わせ | 0件（149 / 149 一致） | AC のない `test_G3_*` 4 本は撮影用の道具（5 章）で、AC の判定には数えない |
| 表示の文字や並び順で探す | `grep -rnE '(buttons\|staticTexts\|textFields\|cells\|switches)\["\|element\(boundBy:\|menuItems\["' ios/AcceptanceTests` | 8件 | すべて撮影用クラスの `app.menuItems["Select All"]` / `["すべてを選択"]`（WidgetAndActivityAcceptanceTests.swift:1540-1543、1559-1562）。システムの編集メニューで欄を空にするためで、製品の要素ではない |

## 7. アクセシビリティ監査
撮影用テスト `G3EvidenceCaptureTests/test_G3_accessibilityAudit`（light、ja）で 27 画面すべてに `performAccessibilityAudit(for: .all)` を実行した。全文は `docs/verification/001-reading-session/evidence/accessibility-audit.log`。合計 92 件のうち、つなぎ口の要素（識別子が `hook.` で始まる 1×1pt の読み出し要素。W-1〜W-5 は H22 の撮影のため readouts を出して起動している）が 50 件、**製品の部品が 42 件**。S-1〜S-10a・N は `-uitest-readouts off` で起動しており、つなぎ口の要素は0。

| 画面 | 製品の指摘 | 中身（要素、種類） |
|---|---|---|
| W-1 | 14 | `widget.line` Hit area too small（11×132pt）、`widget.page` と縦書きの各字（13 個）Dynamic Type partially unsupported |
| W-2 | 4 | `widget.line` Hit area too small、書名 Dynamic Type partially unsupported・Text clipped、`widget.page` Text clipped |
| W-3 | 1 | `screen.widgetShowcase`（一行の文字）Text clipped |
| W-4、W-5 | 0 | — |
| S-1、S-2、S-3、S-4、N、S-6、S-7、S-7a、S-7b、S-7c、S-8a、S-8b、S-8c、S-8d、S-9、S-10 | 0 | — |
| S-3a | 2 | `mark.lineField`、`mark.pageField` Text clipped（プレースホルダー） |
| S-3b | 1 | `mark.pageField` Text clipped |
| S-3c | 1 | `mark.lineField` Text clipped |
| S-5 | 13 | 見本（172×76pt）の縦書きの各字と `p.61` Dynamic Type partially unsupported |
| S-8 | 1 | `register.footer` Text clipped |
| S-10a | 5 | `store.preview` の書名・一行・`p.61` Text clipped、書名・`p.61` Dynamic Type partially unsupported |

r1 で指摘のあった `appearance.row.default` のヒット領域、`next.choose`・`next.author`・`book.unit.*`・`scan.addToShelf` のコントラスト、`record.minutesField`・`manual.author`・`mark.pageField`・`result.summary` のラベル、`register.cancel`・`mark.cancel` の Dynamic Type は、今回の監査では出ていない（直っている）。残りは 11 章 (4)。VoiceOver の実機確認は G4。

## 8. 探索セッション
今回（r2）は手数の上限のため探索セッションを行っていない。r1 の 6 セッションの証拠画像（`explore_R1`〜`R6.png`）は、同じ画面の複製だったため今回の撮り直しで削除した。探索セッションは G3 の次の回で行う（13 章）。

## 9. スクリーンショットとログ
置き場所：`docs/verification/001-reading-session/evidence/`。古い画像（複製・名前違いが多数）はすべて消し、今回撮った 198 枚に入れ替えた。すべて撮影用テストが `XCTAttachment`（keepAlways）と同時に書き出したもので、同じ画像を別名で複製していない。MD5 が一致する組は 3 組だけで、いずれも同じ種と同じ指定を別名で撮ったもの（`AC27_W1_172x76` = `W1_normal_light`、`AC35_W2_170x170` = `W2_normal_light`、`S2_error_light` = `N_error_light`（S-2 の `session.save.error` は部品 N そのもの））。

### 通常の状態（ライト / ダーク / AX5 / 英語の4通り、各 27 画面＝108 枚）
`W1`〜`W5`、`S1`、`S2`、`S3`、`S3a`、`S3b`、`S3c`、`S4`、`S5`、`S6`、`S7`、`S7a`、`S7b`、`S7c`、`S8`、`S8a`、`S8b`、`S8c`、`S8d`、`S9`、`S10`、`S10a`、`N` の `<画面>_normal_<light|dark|ax5|en>.png`。加えて `S1_empty_*`、`S6_empty_*`、`S9_card_*` の4通り。目で確かめた：`S1_normal_dark.png` は黒背景・白文字、`S1_normal_ax5.png` は AX5 の大きさ（一行が隠れる不具合あり）、`S1_normal_en.png` は英語（Bookmark / Place Bookmark / Start Reading）。

### W-1〜W-5 の撮り方と注意
`-uitest-widget-show <ファミリー>:<幅>x<高さ>` で起動し、contracts/test-hooks.md H22 の `hook.widget.canvas` を待ったが**実装にはその要素がなく**、`screen.widgetShowcase` が出る（11 章 (1)）。そのため画面全体を撮った。W-3（`w3:waiting` / `reading` / `ended`）、W-4（`w4:control`）、W-5（`w5:snippet`）の指定は契約に書かれていないが、`hook.error` は出ず見本が描かれた。W-3 の見本は Live Activity の形ではなく書名の1行だけ（`W3_normal_light.png`）。

### 通常以外の状態（ライト、標準の文字）
撮れたもの（`<画面>_<状態>_light.png`）：W1 empty / error / partial / noLine / pending、W2 empty / error / partial、W3 empty / reading / ended / partial、W5 empty / partial、S1 error / noCurrent / partial、S2 error / partial、S3 denied / partial、S3a empty / error / saveError、S3b empty / error、S3c empty / loading / partial、S4 empty / partial、S5 partial、S6 partial、S7 empty / error / partial、S7a empty / error、S7b empty / error、S8 empty / denied / partial、S8a error / partial、S8b loading / partial、S8c empty / error / partial、S8d empty / loading / error / partial、S9 empty / partial、S10 denied / partial、S10a offline / denied / error / loading / partial、N error。AC 指定の画像：`AC27_W1_153x68`、`AC27_W1_172x76`、`AC28_W1_kinsoku`、`AC29_W1_truncated`、`AC34_W1_hidden`、`AC34_S1_visible`、`AC35_W2_148x148`、`AC35_W2_170x170`、`AC106_S1_kinari`。

期待した要素が出ず「そのまま」撮ったもの（名前に `asis`。design 5 章との食い違いの候補）：`S3_empty_asis_light.png`（`mark.later.note.empty` なし）、`S6_error_asis_light.png`（`store.load` 失敗後の本棚に `shelf.load.error` なし）、`S8a_empty_asis_light.png`（`scan.hint` なし）、`S8b_error_asis_light.png`（書名空で `cover.save` を押しても `book.title.invalid` なし）、`S9_denied_asis_light.png`（カメラ拒否で `colophon.capture` を押しても `camera.denied` なし）。

**撮れていない組（11 組）と理由**：
| 画面×状態 | 理由 |
|---|---|
| S-7 denied、S-7c empty / loading / error / denied / partial | S-7（本 A は奥付がそろっている）に `colophon.capture` / `book.captureColophon` が出ず、S-7c に入れなかった。奥付の足りない本でやり直す必要がある（撮影手順の不足） |
| S-3c error | 61 字の列を保存しても `mark.line.invalid` が 5 秒以内に出ない（AC-72 の確認が要る。11 章 (5)） |
| S-8b empty | `cover` の行が 0 件のとき `mark.ocr.none` が出ない（design 5 章 482 行。11 章 (5)） |
| S-9 error | 同じ著者の積読を候補にしても `next.candidate.<id>` が出なかった（撮影手順の不足。候補の条件を test-plan に合わせて直す） |
| S-10 offline | 復元をオフラインで押しても `notice` が出ない |
| S-10 error | `-uitest-fail-save settings.save:1` で `settings.hideOnWidgets` を切り替えても `common.save.error` が出ない（design 5 章 S-10 エラー。11 章 (5)） |
| W-1 / W-2 loading、S-1 / S-6 / S-7 / S-9 loading、S-10 loading、W-4 の各状態 | 読み込みを 0.3 秒以上遅らせるつなぎ口、復元の途中を止めるつなぎ口、Control の状態を描くつなぎ口が contracts/test-hooks.md にない（範囲外。tech-lead への依頼を 13 章に） |

### ログ
`evidence/accessibility-audit.log`、`evidence/logs/01-ios-build.tail.log`〜`05-check-contracts.tail.log`、`06-flaky.summary.log`、`07-capture.summary.log`、`07-capture-steps.log`、`evidence/red.log`（実装前の赤）、`evidence/design-checks.log`（r1 の機械チェックに今回の監査の要約を追記）。

## 10. 前の機能の受け入れテスト（回帰）
該当なし（最初の機能）。

## 11. 見つかった問題
1. **食い違い（契約と実装）**：contracts/test-hooks.md H22 は撮影用の要素を `hook.widget.canvas` と定めるが、実装は `screen.widgetShowcase`（全画面）を出し `hook.widget.canvas` がない（readouts を出した起動でも出ない。`evidence/logs/07-capture-steps.log` の `DEVIATION` 行）。契約か実装のどちらかを直す（tech-lead / ios-engineer）。
2. **要修正（AC-27）**：`evidence/AC27_W1_172x76.png`・`W1_normal_light.png`。172×76 指定の見本が約 133×120pt の角丸枠で描かれ、「下人の行方は、誰も知らない。」14 字のうち「い。」が枠の下で欠けて 12 字しか見えない。H22 の読み出し（`test_AC27`、欠け 0 字）と画像が一致せず、AC-27 を画像で確かめられない。見本が本物の WidgetKit の描画と同じかも含めて ios-engineer が確かめる。
3. **要修正（AC-101）**：`evidence/S1_normal_ax5.png`。AX5 で S-1 の一行（`bookmark.line`。AX1 以上は横書きに切り替える仕様、design/001-reading-session.md 328 行）が下端の `bookmark.start` の裏に隠れ、字の上端の断片しか見えない。
4. **要修正（AC-99、AC-101、AC-102）**：7 章の製品の指摘 42 件。とくに `widget.line` のヒット領域（W-1、W-2）、`mark.lineField` / `mark.pageField` のプレースホルダーの切れ（S-3a〜S-3c）、`register.footer` の切れ（S-8）、`store.preview` の文字の切れ（S-10a）。
5. **要修正（design 5 章との食い違い。AC の外は「提案」）**：(a) S-3 で前のしおりがないときの `mark.later.note.empty` が出ない（提案）。(b) `store.load` 失敗後の S-6 に `shelf.load.error` が出ない（提案）。(c) S-8a の `scan.hint` が出ない（提案）。(d) S-8b で書名空のまま `cover.save` を押しても `book.title.invalid` が出ない（AC-8 の書名の検査は S-8c のみなので提案）。(e) S-9 の `colophon.capture` をカメラ拒否で押しても `camera.denied` が出ない（design 545 行。提案）。(f) `settings.save` の失敗で `common.save.error` が出ない（提案）。(g) S-3c で 61 字の列を保存しても `mark.line.invalid` が出ない（**AC-72 に関わるため要確認**。`test_AC72` は S-3a で通っているので、S-3c の経路だけの可能性）。
6. **環境**：`make check-contracts` の venv（/tmp）が消えていて実行できない（tech-lead）。`make ios-test` でランナーの不時停止が 1 回起きた（再実行が要る）。

## 12. PRD とテストの食い違い
なし（AC のテストは変えていない）。

## 13. 未検証のものと理由
- 全 149 AC の `make ios-test` による通し：片方の構成がランナーの不時停止で完走せず（1 章コマンド 2）。次の回で再実行する。
- `make check-contracts`：この環境では実行できない（venv がない）。
- 9 章の「撮れていない組（11 組）」。うち loading 系と W-4 の状態は contracts/test-hooks.md につなぎ口がなく、tech-lead への依頼：(1) 読み込みを N ミリ秒遅らせる引数（`-uitest-slow-load <ms>` など）、(2) 購入の復元を止める引数、(3) Control（W-4）の状態を描く `-uitest-widget-show` の指定。
- 探索セッション（8 章）：今回は行っていない。
- 撮影用クラスを `G3EvidenceCaptureTests.swift` に分ける：`ios/ReadingApp.xcodeproj` の `ReadingAcceptanceTests` ターゲットにファイルを足す作業が verifier の範囲外のため、ios-engineer か tech-lead に `ios/AcceptanceTests/G3EvidenceCaptureTests.swift` をターゲットに足してもらったあとで移す。
- 実機だけで決まる G4-1〜G4-22 は G4 で Takuma が確認する。
