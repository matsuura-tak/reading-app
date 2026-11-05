FAIL

## 指摘
- 重大 / ios/AcceptanceTests（`make ios-test`）/ AC-2〜AC-149：`make ios-test SIM_DESTINATION='platform=iOS Simulator,id=E5664965-…'` が終了コード 2（Error 65）。ログに「Restarting after unexpected exit, crash, or test timeout」が1回あり、片方の構成（ja/en）が完走していない。スイート単位の Executed 行はすべて 0 failures だが、構成全体の合計が1行しか出ないため全 149 AC の通しを「この実行では証拠がそろわない」扱いにした。再実行が必要（同型のランナー不時停止は撮影用テストの初回でも1回発生。/Users/takumamatsuura/reading-app/docs/verification/001-reading-session/evidence/logs/02-ios-test.tail.log）。
- 要修正 / AC-27 / docs/verification/001-reading-session/evidence/AC27_W1_172x76.png、W1_normal_light.png：172×76 指定の見本が約 133×120pt の枠で描かれ、縦書き14字のうち「い。」の2字が欠けて12字しか見えない。H22 読み出し（test_AC27、欠け0字、5回連続通過）と画像が一致しない。AC-27 は画像では未検証。
- 要修正 / AC-101 / docs/verification/001-reading-session/evidence/S1_normal_ax5.png：AX5 で S-1 の一行（bookmark.line、AX1以上は横書き）が下端の bookmark.start の裏に隠れ、字の上端の断片しか見えない。
- 要修正 / AC-99, AC-101, AC-102 / docs/verification/001-reading-session/evidence/accessibility-audit.log：performAccessibilityAudit(for: .all) 27画面、合計92件＝つなぎ口要素（hook.*、W-1〜W-5 のみ readouts を出して起動）50件＋**製品の部品 42件**（W-1 14、W-2 4、W-3 1、S-3a 2、S-3b 1、S-3c 1、S-5 13、S-8 1、S-10a 5。S-1/S-2/S-3/S-4/N/S-6/S-7/S-7a/S-7b/S-7c/S-8a〜S-8d/S-9/S-10 は0）。主なもの：widget.line ヒット領域 11×132pt（W-1/W-2）、mark.lineField/mark.pageField のプレースホルダー切れ、register.footer 切れ、store.preview の文字切れ、縦書き各字の Dynamic Type partial。r1 指摘の appearance.row.default・next.choose・record.minutesField・register.cancel 等は解消している。
- 食い違い（契約と実装）/ contracts/test-hooks.md H22：撮影用要素 `hook.widget.canvas` が実装に存在しない（readouts を出した起動でも出ない）。実装は `screen.widgetShowcase`（全画面）を出す。W-3/W-4/W-5 の指定（w3:waiting 等）は契約に書かれていない。tech-lead/ios-engineer でどちらかを直す。
- 要修正（AC-72 要確認）/ S-3c：61字の列を保存しても mark.line.invalid が出ない（test_AC72 は S-3a で通過。S-3c 経路のみの可能性）。
- 提案（design 5章との食い違い、AC 外）：S-3 の mark.later.note.empty なし（S3_empty_asis_light.png）、store.load 失敗後の S-6 に shelf.load.error なし（S6_error_asis_light.png）、S-8a の scan.hint なし、S-8b 書名空で cover.save しても book.title.invalid なし、S-9 の colophon.capture をカメラ拒否で押しても camera.denied なし、settings.save 失敗で common.save.error なし。
- 環境 / `make check-contracts`：終了コード 2。Makefile の SCHEMA_PYTHON=/tmp/reading-app-schema-venv/bin/python が存在せず、この環境では実行できない（tech-lead に venv 再作成手順か場所の変更を依頼）。
- 完了条件2（画面×状態の網羅）：通常の状態は27画面×4通り（light/dark/ax5/en）すべて撮れ、目視で dark は本当にダーク、ax5 は本当に AX5、en は本当に英語。撮れていない組 11 組：S-7 denied、S-7c empty/loading/error/denied/partial（奥付がそろった本では colophon.capture が出ず手順不足）、S-3c error、S-8b empty、S-9 error（候補条件の手順不足）、S-10 offline、S-10 error。loading 系・W-4 の状態は contracts につなぎ口がなく範囲外（13章に tech-lead 依頼）。

## 証拠
- `make ios-build`：exit 0、BUILD SUCCEEDED（evidence/logs/01-ios-build.tail.log）
- `make ios-test SIM_DESTINATION=…id=E5664965…`：exit 2（上記。evidence/logs/02-ios-test.tail.log）
- `xcrun simctl erase E5664965…` → `make ios-test-first-launch SIM_DESTINATION=…`：exit 0、TEST SUCCEEDED（ja・en、evidence/logs/03-ios-test-first-launch.tail.log）
- `make ios-test-perf SIM_DESTINATION=…`：exit 0、Executed 4 tests, 0 failures（evidence/logs/04-ios-test-perf.tail.log）
- `make check-contracts`：exit 2、venv なし（evidence/logs/05-check-contracts.tail.log）
- 揺れ：影響「大」の15テスト × `-test-iterations 5 -run-tests-until-failure`（再試行なし）＝75回、落ち0（evidence/logs/06-flaky.summary.log）
- 撮影：TEST_RUNNER_G3_CAPTURE=1 TEST_RUNNER_G3_VARIANT=<light|dark|ax5|en> … -only-testing:ReadingAcceptanceTests/G3EvidenceCaptureTests。light: captureStates のみ failed（11組 MISSING）、dark/ax5/en は4本すべて passed（evidence/logs/07-capture.summary.log、07-capture-steps.log）
- 画像：docs/verification/001-reading-session/evidence/ の古い PNG を全削除し、新規 198 枚に入れ替え（MD5 重複は3組のみで、同一種・同一指定の別名：AC27_W1_172x76=W1_normal_light、AC35_W2_170x170=W2_normal_light、S2_error_light=N_error_light）。git 上は tracked 67 枚削除・18 枚新規・残りは上書き。
- 4章の検査：sleep 0、skip 0、retry 0、@testable 0、AC 抜け 0（149/149）、表示文字で探す 8件（すべて撮影用クラスの app.menuItems["Select All"/"すべてを選択"]、システムの編集メニュー）
- レポート：/Users/takumamatsuura/reading-app/docs/verification/001-reading-session/verification.md（1〜13章を更新）、evidence/design-checks.log（監査要約を追記）、evidence/accessibility-audit.log

## 変更したファイル
- /Users/takumamatsuura/reading-app/ios/AcceptanceTests/WidgetAndActivityAcceptanceTests.swift：末尾に `final class G3EvidenceCaptureTests`（+1,305行、撮影と監査の道具。test runner 環境変数 G3_CAPTURE=1 がなければ即終了し `make ios-test` では ja/en 各4件が0.3秒で通る）。AC のテストは1行も変更なし。別ファイル G3EvidenceCaptureTests.swift に置きたかったが、ios/ReadingApp.xcodeproj のテストターゲットがファイルを明示列挙していて verifier の範囲外のため、既存ファイル末尾に置いた。
- /Users/takumamatsuura/reading-app/ios/AcceptanceTests/FirstLaunchTests.swift：前 verifier の未コミットの撮影用テスト3本（+1,306行）を取り除き 818a07e の内容に戻した（H14/AC-1 の前提を守るため）。
- /Users/takumamatsuura/reading-app/docs/verification/001-reading-session/verification.md、evidence/（PNG 198枚、accessibility-audit.log、design-checks.log 追記、logs/ 8ファイル）
- シミュレーターは既存の iPhone 17（E5664965…）を使い、新規作成なし。commit/push はしていない。

## 未解決
- `make ios-test` の再実行（ランナー不時停止の切り分け）。手数の上限（45回）に達したため今回は再実行できていない。
- `make check-contracts` の venv（tech-lead）。
- 撮影用クラスを ios/AcceptanceTests/G3EvidenceCaptureTests.swift に分けるため、pbxproj のターゲットへのファイル追加（ios-engineer/tech-lead）。
- contracts/test-hooks.md への依頼：hook.widget.canvas の実装か契約の修正、読み込み遅延（loading 状態撮影用）、復元の途中停止、Control（W-4）の状態指定。
- 探索セッション（r1 の6本）は今回未実施。撮れていない 11 組の撮り直し（S-7c は奥付の足りない本で、S-9 error は候補条件を合わせて）。
- .agents/、.codex/、AGENTS.md が作業ツリーに未追跡で存在する（私は触っていない）。

## 記録（指揮役が保存するときに書き足す）
- 関門：G3 r2（design-reviewer r1 の FAIL を受けた直し 31633e3 のあと）
- 日付：2026-11-02。BASE 818a07e
- 範囲の確かめ：変更は ios/AcceptanceTests/ と docs/verification/ だけ（指揮役が git status で確かめた）
