# 検証レポート 001-reading-session（G3 再検証 r3）

置き場所：docs/verification/001-reading-session/verification.md

判定：FAIL

- 関門：G3（verifier r2 の FAIL と ios-engineer の直し r2a〜r2i、契約 r3・r4 のあとの再検証。受け入れテストの側の不具合を直して全 149 AC を ja・en で通した）
- 検証した役：verifier　日時：2026-11-02 19:30 〜 2026-11-03（通しは 11-02 20:08〜21:55、撮影は 11-02 21:56〜11-03 09:58。撮影の途中で Mac が眠り、`test_G3_captureStates` の経過時間が 41,809 秒になっているのはそのため。眠りから戻ったあとも同じプロセスで続き、落ちた手順はない）
- コミット：`d0f1e2c3bbe103656e6acdbc3d2bb0251585f119`（製品の直しは `d6a6e91` まで。作業ツリーに ios/AcceptanceTests/ と docs/verification/ の変更が未コミットで載っている。製品のコード、contracts、design、Makefile は変えていない）
- 環境：macOS（Darwin 27.2.0）、Xcode 27.2（Build 27B52）、iOS Simulator `iPhone 17`（iOS 26.0、UDID `E5664965-B285-4795-9EE7-2D890556B3BE`。同名の端末が 2 台あるため `SIM_DESTINATION='platform=iOS Simulator,id=E5664965-…'` で固定）、バックエンドの接続先：なし（サーバーを持たない）

FAIL の理由（1つでもあれば FAIL）：AC-91 の 7 本のうち 3 本（`book.update`、`record.update`、`record.delete` の失敗）が ja・en とも落ちる。落ち方はアプリの不具合（`common.save.error` の要素がシートの中に 2 つ出る。PRD AC-91 は「1つ出て」）。11 章 (1)。ほかの 148 AC は ja・en の両構成で通り、揺れの確認（4 章）でも落ちていない。

指揮役の指示書の 1〜10 の結果の要約：
1. AC-99・AC-140：`"\(dict)"` で文字にして探す形をやめ、`renders[0].accessibility.label` / `texts["widget.title"]` を読む形にした。直したあと ja・en とも通った（書名はある。アプリの不具合ではなかった）
2. 英語の日本語の決め打ち（17 AC）：design/ 7-1 の ja と en の値を `L10n` に写し、構成ごとに比べる形にした。ja・en とも通った
3. AC-91：7 本に分けた。各 10〜21 秒（上限 2 分の内）。アプリの遅さではなかった。分けた結果、3 本がアプリの不具合で落ちる（11 章 (1)）
4. 撮影の道具を `ios/AcceptanceTests/G3EvidenceCaptureTests.swift` に移し、W-3・W-4・W-5 を契約 H22 の書き方にした。`hook.error` は出ず、5 面すべて撮れた
5. `hook.widget` の読み出し全体のスキーマ検査：撮影のテストが 7 投入×4 枠と見本つき 2 本の JSON を保存し、contracts/test-hooks.md 7 章の 1 行で照らした。10 ファイルすべて `hook.widget OK`（`evidence/logs/09-h22-schema.log`）
6. AC-27・AC-28・AC-30 を組み方の値（`cells`、`referenceL`、`L`、`orientation`、縦書きの 9 項目の有無）で確かめる形に強めた。ja・en とも通った
7. 受け入れテストのターゲットのコンパイラの警告：1,600 件余り → 0 件（`@MainActor` と async の setUp/tearDown）
8. 通し：`make ios-test`（ja・en 完走、各 151 成功 3 失敗）、erase のあと `make ios-test-first-launch`（成功）、`make ios-test-perf`（成功）、`make check-contracts`（成功）。1 章
9. 撮影と監査：27 画面×light/dark/ax5/en（各 32 枚）、通常以外の状態 118 枚、H33 の読み込み中 8 画面と placeholder 2 枚、r2 で撮れなかった 11 組のうち 9 組、監査の要約。9 章・7 章。英語の画面で和文の □ はない（目で見た：`S1_normal_en.png`、`S7_normal_en.png`、`S7a_normal_en.png`、`S9_normal_en.png`、`S3c_normal_en.png`、`S10a_normal_en.png`、`W1_normal_en.png`）
10. S-7a の欄：書名・著者の欄は空で、今の値が placeholder に入っている（不具合。11 章 (2)）。S-9 の「3晩、83分」：見出し `finish.summary` と文 `finish.reflection` の両方に出る（11 章 (6)、提案）

## 1. 実行したコマンドと結果
再試行（`-retry-tests-on-failure`）は一切付けていない。長いテストは `caffeinate -dims` を付けて動かした。末尾のログは `docs/verification/001-reading-session/evidence/logs/` に、完全なログと .xcresult はリポジトリの外（/private/tmp の作業フォルダ `scratchpad/r3/`）にある。

### コマンド 0：テストの直しの確かめ（受け入れテストのターゲットのビルドと、直した 30 テストの ja・en）
- `xcodebuild clean build-for-testing -project ios/ReadingApp.xcodeproj -scheme ReadingApp -configuration Debug -destination 'platform=iOS Simulator,id=E5664965-…'`：終了コード 0。受け入れテストのターゲットのコンパイラの警告：**0 件**（直す前は 1,600 件余り。すべて「main actor-isolated … from a nonisolated context」の型。`evidence/logs/00-test-target-build.tail.log`）。残る `warning:` の行は製品の拡張の `appintentsmetadataprocessor … Metadata extraction skipped` の 1 行だけ（コンパイラの警告ではない。r2b の未解決 6 のまま）
- 直した 30 テスト（AC-22、27、28、30、75、76、79、80、84、85、87、91_1〜7、93、99、120、121、123、125、127、128、140、141、143、148）を ja・en の 2 構成で：終了コード 65。60 本のうち成功 54、失敗 6（AC-91_2・5・6 の ja・en。11 章 (1)）、飛ばした 0（`evidence/logs/00-targeted.tail.log`）

### コマンド 1：`make ios-build`
- 指揮役が d0f1e2c で終了コード 0・警告 0 を確かめ済み（指示書）。今回はコマンド 0 の clean build-for-testing（同じ Debug 構成でアプリ・拡張・テストのターゲットをビルド）で、製品のターゲットに `warning:` の行がないことを確かめた

### コマンド 2：`caffeinate -dims make ios-test SIM_DESTINATION='platform=iOS Simulator,id=E5664965-B285-4795-9EE7-2D890556B3BE'`
- 開始 20:08:12、終了 21:42:25（1 時間 34 分）。終了コード 2（`make: *** [ios-test] Error 65`）
- `swift test --package-path ios/ReadingKit`：`Test run with 19 tests in 2 suites passed`、`Test run with 37 tests in 9 suites passed`
- xcodebuild：`Japanese (ja)` と `English (en)` の 2 構成とも最後まで走った（`evidence/logs/02-ios-test.tail.log`、件数は `evidence/logs/02-ios-test.counts.log`）
  - ja：始まった 154 本のうち成功 151、失敗 3、飛ばした 0
  - en：始まった 154 本のうち成功 151、失敗 3、飛ばした 0
  - 154 本＝AC のテスト 155 本＋撮影の道具 4 本−`-skip-testing` の FirstLaunchTests 1 本と PerformanceTests 4 本（`test_G3_exploratory` はこの実行のあとに足したので入っていない）
  - 失敗 6 本はすべて `test_AC91_2`、`test_AC91_5`、`test_AC91_6`（ja と en）。落ち方は同じ：`common.save.error` の要素が 2 つ（期待 1 つ）。11 章 (1)
  - `Restarting after unexpected exit, crash, or test timeout` が 6 回。いずれも AC-91 の失敗の直後（`continueAfterFailure = false` の Swift のテストで失敗を止めるとき、XCTest はランナーを終了して立ち上げ直す。合計の件数には前の起動の分が含まれる）。時間切れ（`exceeded execution time allowance`）は 0 回。AC-91 の 7 本はどれも 10〜21 秒（分ける前は 2 分超）
- 判定：全 149 AC のうち AC-91 以外の 148 AC は、ja・en の両構成で通った。AC-91 は 7 本のうち 4 本が通り 3 本が落ちた（FAIL）

### コマンド 3：`xcrun simctl shutdown E5664965-…; xcrun simctl erase E5664965-…; caffeinate -dims make ios-test-first-launch SIM_DESTINATION='…id=E5664965-…'`
- 終了コード 0（erase も 0）。`** TEST SUCCEEDED **`（FirstLaunchTests、ja・en の 2 構成とも passed。`evidence/logs/03-ios-test-first-launch.tail.log`）

### コマンド 4：`caffeinate -dims make ios-test-perf SIM_DESTINATION='…id=E5664965-…'`
- 終了コード 0。ja：`Executed 4 tests, with 0 failures (0 unexpected) in 266.522 seconds`、en：`Executed 4 tests, with 0 failures (0 unexpected) in 252.935 seconds`（`evidence/logs/04-ios-test-perf.tail.log`）

### コマンド 5：`make check-contracts`
- 終了コード 0。`jsonschema 4.25.1`、`ALL PASSED: 8 schemas, 29 examples validated with 0 errors.`（`evidence/logs/05-check-contracts.tail.log`。venv は `~/.cache/reading-app/contracts-schema-venv` に既にあった）

### コマンド 6：証拠の撮影（撮影用テスト、AC の判定には使わない）
- `TEST_RUNNER_G3_CAPTURE=1 TEST_RUNNER_G3_VARIANT=<light|dark|ax5|en> TEST_RUNNER_G3_OUT_DIR=<外のフォルダ> caffeinate -dims xcodebuild test -project ios/ReadingApp.xcodeproj -scheme ReadingApp -configuration Debug -destination 'platform=iOS Simulator,id=E5664965-…' -only-testing:ReadingAcceptanceTests/G3EvidenceCaptureTests -only-test-configuration "Japanese (ja)"`（ダークは先に `xcrun simctl ui E5664965-… appearance dark`。en は `-AppleLanguages (en)` を起動の引数で渡し、本のデータは日本語のまま）
- 結果（`evidence/logs/07-capture.summary.log`、手順ごとの OK / MISSING / NOTE は `evidence/logs/07-capture-steps-<variant>.log`）：
  - light：`captureNormalScreens` passed、`accessibilityAudit` passed、`exploratory` passed、`captureWidgets` failed（W-3 ended は記録なしの投入で `hook.error=H22:liveActivity.ended.noRecord`：撮影の手順の不足。AX5 とは別）、`captureStates` failed（MISSING 5 組：9 章）
  - dark / en：5 本すべて passed。ax5：`captureWidgets` failed（`hook.widget.canvas` の frame が `showcase.canvasHeight` と合わない。11 章 (7)）
- 2 回目の light（手順を直したあと、`captureWidgets` と `captureStates` だけ）：末尾の「追記」
- 同じ 2 つの端末で並行に動かした最初の light は、ランナーが「Test crashed with signal abrt while preparing to run tests」で 16 分後に止まり、何も撮れなかった（`scratchpad/r3/capture-light.log` の 1 回目）。通しと同時に別の端末で動かしたためと見て、以後はすべて 1 台で順に動かした。環境の問題で、製品・テストの不具合ではない

### コマンド 7：H22 の読み出し全体のスキーマ検査（contracts/test-hooks.md 7 章の 1 行）
- `~/.cache/reading-app/contracts-schema-venv/bin/python -I -c '…' contracts/hooks/h22-widget.schema.json <hook.widget を保存した JSON>` を `evidence/h22/*.json` の 10 ファイルに当てた（`scratchpad/r3/h22check-all.sh`）。すべて `hook.widget OK: 4 renders`（見本つきの 2 本は `1 renders`）、終了コード 0、エラーのあるファイル 0（`evidence/logs/09-h22-schema.log`）
- 保存した投入：`normal_vertical`、`normal_horizontal`、`noLine`、`noLineNoPage`、`hidden`、`empty`、`unavailable`（4 枠 `accessoryRectangular:153x68,accessoryRectangular:172x76,systemSmall:148x148,systemSmall:170x170`）、`showcase_w1_172x76`、`showcase_w1_horizontal`（`-uitest-widget-show` つき、`showcase` も同じ 1 行で検査）、`explore_kinsoku_heavy`

## 2. 受け入れ条件ごとの結果
コマンド 2〜4 の結果（ja・en の 2 構成）。AC ごとに、動いたテストの数と落ちた数を構成ごとに書いた。飛ばしたテストは 0。揺れの確認（4 章）で落ちたテストはない。

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
| AC-15 | PASS | test_AC15_本の書名と著者を直しても記録が保たれる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
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
| AC-47 | PASS | test_AC47_しおり画面以外や知らせ表示中は伏せても始まらない | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
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
| AC-91 | FAIL | test_AC91_1_本を加える保存に失敗すると変更前のデータが保たれる<br>test_AC91_2_本を直す保存に失敗すると変更前のデータが保たれる<br>test_AC91_3_本を消す保存に失敗すると変更前のデータが保たれる<br>test_AC91_4_読み終える保存に失敗すると変更前のデータが保たれる<br>test_AC91_5_記録の分数を直す保存に失敗すると変更前のデータが保たれる<br>test_AC91_6_記録を消す保存に失敗すると変更前のデータが保たれる<br>test_AC91_7_しおりを挟む保存に失敗すると変更前のデータが保たれる | 4/3 | 4/3 | 0 | `logs/02-ios-test.tail.log`、`AC91_2_saveError_double.png`（11 章 (1)） |
| AC-92 | PASS | test_AC92_NDL書誌の著者名から生没年や役割語や2人目以降を除いて整形する | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-93 | PASS | test_AC93_設定画面にNDLの3条件とCCBYリンクが出てしおり画面と読書中画面には出ない | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-94 | PASS | test_AC94_OCR待ちの間も1秒以内に手入力やページ入力に移り後から結果が返っても上書きされない | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-95 | PASS | test_AC95_読後のしおり保存失敗時も記録は残り入力値を保ったまま再保存できる | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-96 | PASS | test_AC96_ウィジェットの置き方案内は最初の1回だけ出る | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-97 | PASS | test_AC97_LiveActivity予約失敗時はアラートを出さず次回前面復帰時に予約し直す | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-98 | PASS | test_AC98_読まなかった晩のLiveActivityは翌朝前面復帰で終了し今夜分を予約する | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log` |
| AC-99 | PASS | test_AC99_ウィジェットとしおり画面のVoiceOverラベルに縦書き用字形が含まれない | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log`、`accessibility-audit.log`（W-1 の節。11 章 (3)） |
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
| AC-140 | PASS | test_AC140_名無しの今の本に後からバーコードで書名と奥付を入れると記録を保って更新される | 1/0 | 1/0 | 0 | `logs/02-ios-test.tail.log`、`h22/noLine.json`（同じ形の読み出し） |
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
| オフライン、サーバーエラー | 自動 | PASS | コマンド 2 の AC-6、AC-9、AC-62、AC-110、AC-125。画面は `evidence/S10a_offline_light.png`（`store.offline`）。S-10 の復元オフライン（`store.offline`）は 2 回目の light で撮った（追記） |
| 権限を断った | 自動 | PASS | コマンド 2 の AC-12、AC-37、AC-70、AC-109、AC-118、AC-142。画面は `evidence/S3_denied_light.png`、`S7_denied_light.png`、`S7c_denied_light.png`、`S8_denied_light.png`、`S10_denied_light.png`、`S10a_denied_light.png`。S-9 のカメラ拒否は `S9_denied_asis_light.png`（`camera.denied` が出ない。11 章 (8)） |
| バックグラウンドから復帰 | 自動 | PASS | コマンド 2 の AC-40、AC-52、AC-97、AC-98、AC-111、AC-130、AC-136（ja・en とも成功） |
| 言語と地域（ja、en） | 自動 | PASS | コマンド 2 の 2 構成（en は 151 成功 3 失敗。3 失敗は ja と同じ AC-91 の不具合）。`L10n` で design/ 7-1 の en の文を比べる 17 AC が en で通った。画面は 27 画面の `*_normal_en.png`（英語の文言、日本語の本のデータ。□ なし） |
| 大きい文字、ダークモード | 自動 | PASS（AX5 に提案 1 件） | ダーク：`evidence/*_normal_dark.png` 27 枚（本当にダーク。`S1_normal_dark.png` は黒背景・白文字）。AX5：`evidence/S1_normal_ax5.png` で一行が横書き 2 行で全部読め、`読み始める` が見える（r2 の AC-101 の指摘は直っている）。下端の伏せの案内が画面の外に半分出ている（11 章 (9)、提案）。`performAccessibilityAudit` は 7 章 |
| 容量不足、割り込み | 自動 | FAIL（AC-91） | コマンド 2 の AC-59、AC-60、AC-90、AC-91（3 本が落ちる）、AC-95、AC-119、AC-132、AC-133。画面は `evidence/S1_error_light.png`、`S1_loading_error_light.png`→`S1_error_after_loading_light.png`（H33＋H7）、`S2_error_light.png`、`S3a_saveError_light.png`、`S7_error_light.png`、`S7c_error_light.png`、`S8a_error_light.png`、`S8d_error_light.png`、`S10_error_light.png`、`S10a_error_light.png`、`AC91_2_saveError_double.png` |
| 実機だけで決まる確認（G4-1〜G4-22） | G4 の人 | G4 申し送り | test-plan.md 7 章のとおり。加えて 11 章 (3) の VoiceOver の読み上げのまとまり（W-1、W-2） |

## 4. 揺れの確認
影響「大」の AC を代表する 15 テスト（r2 と同じ組）、今回直した 5 テスト（AC-27、28、30、99、140）、AC-91 の 7 本の計 27 テストに `-test-iterations 5 -run-tests-until-failure`（ja 構成、再試行なし）。Debug の 24 本は 1 回の xcodebuild（10:00〜10:38、終了コード 65）、AC-1 は `xcrun simctl erase` のあと単独（終了コード 0）、AC-100 は Perf 構成で単独（終了コード 0）。合計 118 回、落ちた 3 回はすべて AC-91_2・5・6 の 1 回目（`-run-tests-until-failure` なので 1 回で止まる）で、落ちた所と値（`common.save.error` が 2）は通し（コマンド 2）と同じ。揺れたテストは 0（`evidence/logs/06-flaky.summary.log`）。

| テストの名前 | コマンド | 回数 | 落ちた回数 | 原因の型 |
|---|---|---|---|---|
| BookmarkAcceptanceTests/test_AC65 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| BookmarkAcceptanceTests/test_AC69 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| RegistrationAcceptanceTests/test_AC3 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| RegistrationAcceptanceTests/test_AC140 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| SettingsStoreIntentsAcceptanceTests/test_AC91_5 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 1 | 1 | AC-91 の不具合（11 章 (1)）で毎回同じ所で落ちる。揺れではない |
| SettingsStoreIntentsAcceptanceTests/test_AC91_2 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 1 | 1 | AC-91 の不具合（11 章 (1)）で毎回同じ所で落ちる。揺れではない |
| SettingsStoreIntentsAcceptanceTests/test_AC116 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| SettingsStoreIntentsAcceptanceTests/test_AC91_1 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| SettingsStoreIntentsAcceptanceTests/test_AC91_3 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| SettingsStoreIntentsAcceptanceTests/test_AC90 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| SettingsStoreIntentsAcceptanceTests/test_AC91_6 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 1 | 1 | AC-91 の不具合（11 章 (1)）で毎回同じ所で落ちる。揺れではない |
| SettingsStoreIntentsAcceptanceTests/test_AC114 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| SettingsStoreIntentsAcceptanceTests/test_AC91_7 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| SettingsStoreIntentsAcceptanceTests/test_AC91_4 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| SettingsStoreIntentsAcceptanceTests/test_AC103 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| WidgetAndActivityAcceptanceTests/test_AC34 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| WidgetAndActivityAcceptanceTests/test_AC28 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| WidgetAndActivityAcceptanceTests/test_AC30 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| WidgetAndActivityAcceptanceTests/test_AC99 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| WidgetAndActivityAcceptanceTests/test_AC27 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| ReadingSessionAcceptanceTests/test_AC55 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| ReadingSessionAcceptanceTests/test_AC60 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| ReadingSessionAcceptanceTests/test_AC44 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| ReadingSessionAcceptanceTests/test_AC53 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| FirstLaunchTests/test_AC1 | Debug、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |
| PerformanceTests/test_AC100 | Perf、`-test-iterations 5 -run-tests-until-failure`、ja | 5 | 0 | — |


## 5. 受け入れテストの変更
- この機能のテストを最初に入れたコミット：`8984b29`（`git log --oneline origin/main..HEAD -- ios/AcceptanceTests` のいちばん下）
- 今回の差分：`git diff d0f1e2c -- ios/AcceptanceTests`（作業ツリー。7ファイル変更＋`G3EvidenceCaptureTests.swift` 新規）
- 指揮役の裁定（docs/reviews/001-reading-session-G3-ios-fix-r2i.md の 23〜25）：AC-99・AC-140・英語の日本語の決め打ちはテストの不具合、AC-91 はテストの長さ。

| ファイル:行 | 何を変えたか | 根拠（PRD の行、契約） |
|---|---|---|
| `Support/AcceptanceTestBase.swift`（`enum L10n`、冒頭） | テスト計画の構成（Application Language）ごとの期待値を design/001-reading-session.md 7-1 の文言キーの日本語・英語の列から作る `L10n` を足した。どちらの構成かはランナーの `AppleLanguages` で決める。値は design/ 7 の文をそのまま写し、テストの側で文をつながない | PRD 11 章の各 AC は「文言キー」で Then を書く（AC-75、AC-76、AC-79、AC-80、AC-84、AC-85、AC-87、AC-93、AC-120、AC-121、AC-123、AC-125、AC-127、AC-128、AC-141、AC-143、AC-148）。design/ 7-1 が ja と en の正。test-plan 3 章「言語と地域（ja、en）」 |
| `Support/AcceptanceTestBase.swift`（`@MainActor class AcceptanceTestBase`、`setUp()/tearDown() async throws`） | XCUITest の API が MainActor 隔離になった SDK で、テストのクラスを MainActor にし、同期の setUp/tearDown を async の上書きにした。振る舞いは同じ | 指揮役の 7（受け入れテストのターゲットの警告を 0 に）。AC の期待値には触れない |
| `BookmarkAcceptanceTests.swift:367,386,412,533,535-536,568` | 「18分」「p.43 → p.61　18分」「位置1200 → 位置1450　18分」「位置1450」「34% → 52%　18分」を `L10n` の値（en は "18 min"、"p.43 → p.61  18 min"、"Loc 1200 → Loc 1450  18 min"、"Loc 1450"、"34% → 52%  18 min"）にした | PRD AC-75、AC-76、AC-141 の Then（`result.summary.pages`、`result.summary.locations`、`result.summary.percents`、`location.short`、`duration.minutes`）。design/ 7-1 の同じキーの en の列 |
| `FinishAndRecommendationAcceptanceTests.swift:186-188,241-243,346-347,399-400,492-494,538-541,546-547,569-571,591-593,909` | 推薦の理由（`next.reason.*`、`rec.reason.*`）、「3晩」「65分」、ふりかえりの「6晩」「142分（2時間22分）」「10月15日」「38分」などを `L10n` の値にした | PRD AC-79、AC-80、AC-84、AC-85、AC-87、AC-127、AC-128、AC-148 の Then。design/ 7-1 の `next.reason.sameAuthor` 等、`book.nights`、`duration.minutes`、`duration.hoursMinutes`、`finish.reflection.multi/single`。晩の日付の英語「October 15」は docs/reviews r2i の `nightDayText(_:wide:)` の記述（design/ 7 に日付の書式のキーがない。13 章） |
| `SettingsStoreIntentsAcceptanceTests.swift:333-341`（AC-93） | 「加工」「国立国会図書館」「無関係」の決め打ちを、design/ 7-1 の `settings.dataSources` の日英の文に含まれる語（出典、取得日、加工、API、CC BY 4.0、版、共起の注記）にした。確かめる条件は3条件＋版＋注記で前より多い | PRD AC-93 の Then（「日本語の構成と英語の構成のそれぞれで次の3つをすべて含む」） |
| `SettingsStoreIntentsAcceptanceTests.swift:926,942,1011,1052,1225,1251`（AC-120、AC-121、AC-123、AC-125、AC-143） | 「しおり」「61ページからです。」「位置1450からです。」「52パーセントからです。」を `L10n` の値にした | PRD AC-120（`widget.hidden`）、AC-121・AC-123・AC-125（`intent.whereStopped.page`）、AC-143（`intent.whereStopped.location/percent`）。design/ 7-1 の en の列 |
| `SettingsStoreIntentsAcceptanceTests.swift:200-330`（AC-91） | 1本で7通りを流していたテストを、H7 の対象ごとの7本（`test_AC91_1_`〜`test_AC91_7_`）に分けた。共通の確かめ `assertAC91Unchanged` で、本の数・書名・著者・置き場所・一行・ページ・記録の件数と分数のすべてを、操作の直後と開き直したあとに見る（前は一部だけ）。`common.save.error` が1つであることも見る | PRD AC-91 の Given（H7 のどれか1つ）と Then（「文言キー `common.save.error` が1つ出て、本の数、A の書名、著者、置き場所、一行、ページ、記録の件数と分数は操作の前のまま。強制終了して開き直しても同じ」）。指揮役の裁定 25（テストの長さ） |
| `ShelfAndBookAcceptanceTests.swift:515-516`（AC-22） | `book.nights` の `contains("4")`、`book.total` の `contains("1") && contains("25") || contains("85")` を、`L10n.nights(4)`、`L10n.minutes(85)` を含むことにした（弱い確かめを PRD の値に） | PRD AC-22 の Then「4晩」「85分」。design/ 7-1 の `book.nights`、`book.total`、`duration.minutes` |
| `WidgetAndActivityAcceptanceTests.swift`（AC-27） | 文字列が含まれるかだけの確かめを、`renders[]` ごとに `state`、`url`、`texts["widget.line"]`、`texts["widget.page"]`、`composition.displayedLine`、`cells[].source` を並べた文字列が一行と同じ（欠け0字）にした | PRD AC-27 の Then「どちらの枠でも…欠け0字」。contracts/test-hooks.md「H22 の組み方」の確かめ方（`cells` の字を並べると `displayedLine` と同じ）。tech-lead r3 の提案 |
| `WidgetAndActivityAcceptanceTests.swift`（AC-28） | 縦書き用の字があるかだけの確かめを、PRD の (1)〜(6) の一行（(4)〜(6) は25字で L+1＝6 字目に「、」「」」「ー」）× 2つの枠で、`cells` の `display`（U+FE11/FE12/FE41/FE42）、`rotation`（「ー」は 90）、列が右から左（`x` が減る）、`row`＝1 の字が禁則の字でない、`cells[].source` を並べると一行と同じ、`referenceL`＝5、(4)〜(6) で `L`＝`referenceL` にした | PRD AC-28 の Given/When/Then。contracts/test-hooks.md「H22 の組み方」の表（W-1 の両方の枠で `referenceL` 5、25字は L 5）と「AC-28 の一行はこういう並びで作らない」。tech-lead r3 の「verifier への影響」 |
| `WidgetAndActivityAcceptanceTests.swift`（AC-30） | `contains("horizontal")` を、`composition.orientation`＝`horizontal`、`displayedLine`＝一行、`texts["widget.line"]`、縦書きの9項目のキーがないこと、にした | PRD AC-30 の Then。contracts/test-hooks.md「横書きの一行」（9項目はキーごと書かない） |
| `WidgetAndActivityAcceptanceTests.swift`（AC-99） | `"\(dict)"` で文字にして書名を探す形をやめ、`renders[0].accessibility` の `identifier`（`widget.rectangular`）、`groupCount`＝1、`label` が「羅生門」「61」「保存した一行」を含み U+FE10〜FE4F を含まない、にした（まとまりの数と一行の確かめを足した） | PRD AC-99 の Then。contracts/hooks/h22-widget.schema.json の `accessibility`。指揮役の 1 |
| `RegistrationAcceptanceTests.swift:885-886`（AC-140） | 同じく `"\(dict)"` をやめ、`renders[0].state`＝`noLine`、`texts["widget.title"]`＝「こころ」、`texts["widget.page"]`＝「p.45」、`accessibility.label` に「こころ」、にした | PRD AC-140 の Then「ウィジェット（H22）の書名が「こころ」」。contracts/test-hooks.md H22 の `state` と `texts` の表（一行がなく進み具合がある→`noLine`、`widget.title`） |
| `G3EvidenceCaptureTests.swift`（新規。`WidgetAndActivityAcceptanceTests.swift` 末尾から移動、+約 400 行） | 撮影の道具を別ファイルに移し、W-3・W-4・W-5 の指定を契約の書き方（`liveActivity:370x160:<種類>`、`control:160x72`、`snippet:360x200`）に、`hook.widget.canvas` の frame を契約の確かめ方で確かめる形に、英語の撮影も日本語の本のデータに、H33 の読み込み中（8画面）、placeholder、奥付の足りない本での S-7/S-7c、H22 の読み出し全体の保存（7投入×4枠）、S-7a・S-9 の観察、探索（R1・R4・R6）を足した。`make ios-test` では `G3_CAPTURE` がないので何もしない | 指揮役の 4、5、9、10。contracts/test-hooks.md H22「撮影用の見本」、H33、7章、8章。AC の判定には使わない |

AC のテストの待ち方・識別子の変更：なし。期待値の変更は上の表のとおりで、すべて PRD の Then の値か design/ 7-1 の文言（日英）に置き換えたもの。弱めたものはない。

## 6. 検査の件数
| 検査 | コマンド | 件数 | 理由 |
|---|---|---|---|
| sleep で待つ | `grep -rnE 'sleep\(\|usleep\|Thread\.sleep\|time\.sleep\|asyncio\.sleep' ios/AcceptanceTests` | 0件 | — |
| 飛ばす、失敗を許す | `grep -rnE 'XCTSkip\|XCTExpectFailure\|pytest\.mark\.skip\|skipif\|xfail\|pytest\.skip\|unittest\.skip' ios/AcceptanceTests` | 0件 | — |
| 再試行 | `grep -rniE 'retry\|rerun' ios/AcceptanceTests`、および本書のコマンドの行 | 0件 | `-retry-tests-on-failure` は付けていない |
| 中を覗く import | `grep -rnE '@testable import' ios/AcceptanceTests` | 0件 | — |
| AC 番号の抜け、AC のないテスト | PRD の `AC-n`（1〜149）と `test_AC<n>_` の突き合わせ | 0件（149 / 149 一致。AC のテスト 155 本） | AC のない `test_G3_*` 5 本（撮影 4＋探索 1）は撮影・探索の道具で、`G3_CAPTURE` がなければ何もしない。AC の判定には数えない |
| 表示の文字や並び順で探す | `grep -rnE '(buttons\|staticTexts\|textFields\|cells\|switches)\["\|element\(boundBy:' ios/AcceptanceTests` | 0件 | 撮影用の `app.menuItems["Select All"]` / `["すべてを選択"]` はシステムの編集メニュー（例外）で、この検査の型には当たらない |
| 要素があるかだけを見る | `XCTAssertTrue(...exists)` だけのテスト（awk で機械的に抽出） | 0件 | 機械抽出で挙がった 15 本（AC-19、AC-21、AC-22、AC-32、AC-35、AC-41、AC-49、AC-85、AC-91_1/2/3/6/7、AC-98、AC-100）を目で見た。すべて `XCTAssertTrue(x.contains(値))`、`XCTAssertEqual` を持つ補助関数（`assertAC91Unchanged`）、`XCTAssertLessThanOrEqual`（速さ）のどれかで値を見ている |
| 保存のテストに `app.terminate()` 後の確認がない | AC-91 の7本、AC-140、AC-3 など | 0件 | `relaunchPreservingStore()`（`app.terminate()`→`app.launch()`）のあとに `hook.store` を読む |

## 7. アクセシビリティ監査
`test_G3_accessibilityAudit`（light、`-uitest-readouts off`、`performAccessibilityAudit(for: .all)`）。27 画面、合計 80 件（`evidence/accessibility-audit.log`）。r2 は 42 件の製品の指摘があり、r2b〜r2i で直された。VoiceOver での確認は G4 の人に回す。

| 画面 | 件数 | 見つかった問題（型：件数）と見方 |
|---|---|---|
| W-1（`accessoryRectangular:172x76`） | 16 | Dynamic Type 非対応 14＋一部非対応 1（縦書きの字 1 つずつが `StaticText`。design/ 9 の W-1・W-2 と見本の Dynamic Type の例外に当たる）、Text clipped 1（`p.61`、25.3×13.3）。**縦書きの字が 1 字ずつ別の要素として XCUITest の木に出ている**（11 章 (3)） |
| W-2（`systemSmall:170x170`） | 14 | Dynamic Type 非対応 14（同上。字が 1 つずつ要素） |
| W-3（`liveActivity:370x160:waiting`） | 2 | Text clipped 1（`下人の行方は、誰も知らない。` 216×16）、Contrast nearly passed 1（`p.61`） |
| W-4（`control:160x72`） | 1 | Text clipped 1（`読み始める` 108.2×20.3。Control のラベルはシステムが描くので G4 で見る） |
| W-5（`snippet:360x200`） | 0 | — |
| S-1 | 1 | Contrast failed 1（縦書きの一行の 1 字「方」） |
| S-2、S-3、S-4、S-6、S-8、S-8a、S-8b、S-8c、S-8d、S-7a、S-7b、S-7c、S-9、S-10 | 0 | — |
| S-3a、S-3b | 各 1 | Label not human-readable 1（`mark.page.previous`「前の値はp.45です。…」。`p.45` の表記が理由で、文は design/ 7 のとおり。提案） |
| S-3c | 4 | Text clipped 3（要素なし）、Label not human-readable 1（同上） |
| S-5 | 23 | Dynamic Type 非対応 21＋一部 1（置き方案内の中の W-1 の見本。design/ 9 の例外）、Text clipped 1（`p.61`） |
| N | 1 | Contrast failed 1（要素なし） |
| S-7 | 1 | Dynamic Type 一部非対応 1 |
| S-10a | 15 | Dynamic Type 非対応 12＋一部 1（見た目の見本の中の W-1）、Text clipped 2（`p.61`、`store.product.title`「よむま＋（買い切り）」147.3×20.3） |

## 8. 探索セッション
`test_G3_exploratory`（light、`G3_CAPTURE=1` のときだけ動く。手順ごとに `evidence/explore/X_<手順>.png` と `X_<手順>.tree.txt`（`app.debugDescription`）を残す。結果の行は `evidence/logs/07-capture-steps-light.log` の `RESULT`、`R4`、`R1`）。R2、R3、R5 は今回は行っていない（13 章）。

### セッション 1（R6：本と記録の永続化。S-7a の欄）
- チャーター：S-7a を「何も変えずに保存」「著者だけを直して保存」で探り、書名の消失や入力値の扱いを見つける
- 区切り：4 操作（予定 40 操作のうち、S-7a に絞った）
- 試したこと：(1) S-7a を開いて欄の `value` と `placeholderValue` を読む → 書名・著者とも `value`＝`placeholder`＝今の値（XCUITest は空の欄の `value` に placeholder を返すので、欄は空）。(2) 何も変えず保存 → 書名「羅生門」著者「芥川龍之介」のまま、`book.title.invalid` なし。(3) 著者の欄を押して「（改）」と打って保存 → 著者が「（改）」になった（「芥川龍之介（改）」ではない。欄が空で、打った字だけが値になる）。(4) S-7 の奥付は「羅生門 （改） 岩波書店（岩波文庫） 1927年」
- 見つけた不具合：11 章 (2)
- 疑問：空のまま保存すると前の値が残る作りなので、書名を空にして保存したときの `book.title.invalid`（design/ 5）がどう出るかは、`S7a_error_light.png`（書名の欄を全選択して消してから保存）で出ている
- 使い捨てのテスト：`test_G3_exploratory` として残した（`G3_CAPTURE` がなければ何もしない。AC の判定には数えない）

### セッション 2（R4：ウィジェットと隠す設定）
- チャーター：禁則の字の多い 25 字の一行と `hideOnWidgets` の切り替えで、字の欠けと書名・一行の漏れを探る
- 区切り：3 操作
- 試したこと：(1)「「あ」と、「い」と、「う」と、「え」と、「お」と。」（25 字、「」」「、」「。」が 10 字）を 4 枠で組む → 4 枠とも `cells` を並べた字が `displayedLine` と同じ（欠け 0 字）。読み出しはスキーマに合う（`evidence/h22/explore_kinsoku_heavy.json`）。(2) S-10 で `settings.hideOnWidgets` をオン → `hook.widget` の `state` が `hidden`、書名も一行も含まれない。`hook.liveActivity` にも含まれない。(3) オフに戻す → `normal` に戻り、書名と一行が戻る
- 見つけた不具合：なし
- 使い捨てのテスト：同上

### セッション 3（R1：4:00 をまたぐ読書）
- チャーター：03:50 に読み始めて 04:10 に終えたとき、晩の日付と何晩・合計が正しいか
- 区切り：2 操作
- 試したこと：10/17 03:50 に開始、20 分後に終了（`mark.later`）→ 記録の `nightDate` は `2026-10-16`（前日の晩）、分数 20。S-7 は「3晩」「合計 65分」（10/14、10/15、10/16 の 3 晩、20＋25＋20）
- 見つけた不具合：なし
- 使い捨てのテスト：同上

## 9. スクリーンショットとログ
置き場所：`docs/verification/001-reading-session/evidence/`。r2 の画像はすべて消し、今回撮った画像に入れ替えた（通常 27 画面×4 通り＋`S1_empty`・`S6_empty`・`S9_card`×4＋通常以外＋AC 指定＋探索）。すべて撮影用テストが `XCTAttachment`（keepAlways）と同時に書き出したもので、同じ画像を別名で複製していない。

### 通常の状態（ライト / ダーク / AX5 / 英語の 4 通り、各 27 画面＋3 枚＝30 枚、計 120 枚）
`W1`〜`W5`、`S1`、`S2`、`S3`、`S3a`、`S3b`、`S3c`、`S4`、`S5`、`S6`、`S7`、`S7a`、`S7b`、`S7c`、`S8`、`S8a`、`S8b`、`S8c`、`S8d`、`S9`、`S10`、`S10a`、`N` の `<画面>_normal_<light|dark|ax5|en>.png`。加えて `S1_empty_*`、`S6_empty_*`、`S9_card_*`。
- 目で確かめた：`S1_normal_en.png`・`S7_normal_en.png`・`S7a_normal_en.png`・`S9_normal_en.png`・`S3c_normal_en.png`・`S10a_normal_en.png`・`W1_normal_en.png` は英語の文言で、書名・著者・一行（和文）が □ にならず描けている（r2i の未解決 5 の確かめ）。`S1_normal_dark.png` は黒背景・白文字。`S1_normal_ax5.png` は AX5 で一行が横書き 2 行で全部読める。
- W-1〜W-5 は契約 H22 の `hook.widget.canvas` を撮った。枠の大きさは `canvas.frame` で確かめた（`evidence/logs/07-capture-steps-light.log` の `CANVAS` 行）：W-1 172×76、153×68、W-2 170×170、148×148、W-3 370×94.3（中身に合わせる面。`showcase.canvasHeight` と同じ）、W-4 160×72、W-5 360×52.3。同じ起動の `renders[].composition`（`RENDER` 行）と画像の列の数・字の大きさが合う：W-1 172×76 の 14 字は 17pt・4 列（`AC27_W1_172x76.png` で 4 列）、153×68 も 17pt・4 列、W-2 170×170 は 20pt・3 列、148×148 は 20pt・4 列（`AC35_W2_148x148.png` で 4 列）。`contentOverflow` はすべて偽。
- W-3 は Live Activity のロック画面のバナーの形（書名、「21:00 から読書中」、`終える`）で描けている（`W3_normal_light.png`、`W3_reading_light.png`）。r2 の「書名の 1 行だけ」は直っている。

### 通常以外の状態（ライト、標準の文字）
撮れたもの（`<画面>_<状態>_light.png`）：W1 empty / error / partial / noLine / pending / loading（placeholder）、W2 empty / error / partial / loading、W3 reading / empty / partial、W5 empty / partial、S1 error / noCurrent / partial / loading（H33）/ loading→error、S2 error / partial、S3 denied / partial、S3a empty / error / saveError、S3b empty / error、S3c empty / loading / error（61 字）/ partial、S4 empty / partial、S5 partial、S6 error / partial / loading（H33）、S7 empty / denied / error / partial / loading（H33）、S7a empty / error、S7b empty / error、S7c loading / denied / error、S8 empty / denied / partial、S8a error / partial / loading（H33 `catalog.lookup`）、S8b empty / loading / error / partial、S8c empty / error / partial / loading（H33 `catalog.lookup`）、S8d empty / loading / error / partial、S9 empty / partial / loading（H33）、S10 denied / partial / error、S10a offline / denied / error / unavailable / loading（H33 `storekit.products`）/ partial、N error。AC 指定の画像：`AC27_W1_153x68`、`AC27_W1_172x76`、`AC28_W1_kinsoku`、`AC29_W1_truncated`、`AC30_W1_horizontal`、`AC34_W1_hidden`、`AC34_S1_visible`、`AC35_W2_148x148`、`AC35_W2_170x170`、`AC106_S1_kinari`、`AC91_2_saveError_double`。

r2 で撮れていなかった 11 組の今回：S-7 denied・S-7c loading/denied/error（奥付の足りない本で撮れた）、S-3c error（撮れた）、S-8b empty（撮れた）、S-10 error（撮れた）、W-1/W-2 loading（H22 placeholder で撮れた）、S-1/S-6/S-7/S-9/S-8a/S-8c/S-10a loading（H33 で撮れた。`hold.<対象>=shown` を待って撮った：`HOLD` 行）、W-4 の各状態（契約 8 章のとおり描く状態がないので normal のみ）。残り：S-7c empty / partial、S-9 error、S-10 offline、S-10 loading（`storekit.restore`）は 1 回目の light で MISSING（手順の不足と、`hold.storekit.restore` が `held` のまま `shown` にならない件）。手順を直して 2 回目の light で撮った結果は末尾の「追記」。

期待した要素が出ず「そのまま」撮ったもの（名前に `asis`）：`S3_empty_asis_light.png`（`mark.later.note.empty` なし。r2 と同じ。11 章 (8)）、`S9_denied_asis_light.png`（`camera.denied` なし。11 章 (8)）。

### H22 の読み出し（`evidence/h22/`）
`normal_vertical.json`、`normal_horizontal.json`、`noLine.json`、`noLineNoPage.json`、`hidden.json`、`empty.json`、`unavailable.json`、`showcase_w1_172x76.json`、`showcase_w1_horizontal.json`、`explore_kinsoku_heavy.json`。検査はコマンド 7。

### 探索（`evidence/explore/`）
`X_R6_1_S_7a_open_fields.png` 〜 `X_R1_2_book_nights_after_4am_session.png`（9 枚）と同名の `.tree.txt`。

### ログ（`evidence/logs/`）
`00-test-target-build.tail.log`、`00-targeted.tail.log`、`02-ios-test.tail.log`、`02-ios-test.counts.log`、`03-ios-test-first-launch.tail.log`、`04-ios-test-perf.tail.log`、`05-check-contracts.tail.log`、`06-flaky.summary.log`、`07-capture.summary.log`、`07-capture-steps-<light|dark|ax5|en>.log`、`09-h22-schema.log`。ほかに `evidence/accessibility-audit.log`、`evidence/red.log`（実装前の赤）、`evidence/design-checks.log`（r1）。

## 10. 前の機能の受け入れテスト（回帰）
該当なし（最初の機能）。

## 11. 見つかった問題
| # | 内容 | 再現の手順 | 再現するテストの名前 | AC | 重大度 | 直す役 |
|---|---|---|---|---|---|---|
| (1) | **`common.save.error` がシートの中に 2 つ出る。** S-7a（本を直す）・S-7b（記録を直す・消す）で保存が失敗したとき、識別子 `common.save.error` の `StaticText` が 2 つある（frame (71.7, 163.0, 169.0, 58.0) と (71.7, 156.0, 169.0, 58.0)、同じ文、7pt ずれて重なる。画面には 1 つしか見えない：`evidence/AC91_2_saveError_double.png`）。ja・en とも同じ。S-7（`book.status`、`book.delete`）、S-8c（`book.add`）、S-3b（`mark.save`）では 1 つ。PRD AC-91「文言キー `common.save.error` が1つ出て」。VoiceOver が 2 回読む可能性もある | `-uitest-fail-save book.update:1` で S-7a の書名を直して保存。または `record.update:1` / `record.delete:1` で S-7b | `test_AC91_2_本を直す保存に失敗すると変更前のデータが保たれる`、`test_AC91_5_…`、`test_AC91_6_…`（SettingsStoreIntentsAcceptanceTests.swift:241。失敗の文に 2 要素の type・frame・label を出す） | AC-91 | 要修正 | ios-engineer |
| (2) | **S-7a の書名・著者の欄が空で、今の値が placeholder に入っている。** 欄を押して打つと前の値に続かず、打った字だけが値になる（著者に「（改）」と打つと著者が「（改）」になる）。空のまま保存すると前の値が残る。design/ 5 の S-7a「今の本の値をそのまま欄に出す」と違う。見た目は `evidence/S7a_normal_light.png`・`S7a_normal_en.png`（灰色の placeholder）。S-3c の `mark.lineField` も同じ形（選んだ列の文が placeholder。`S3c_normal_en.png`） | S-7 の `book.edit` → 欄の `value` と `placeholderValue` を読む（`evidence/logs/07-capture-steps-light.log` の `FIELD` 行）。著者だけ直して保存 | `test_G3_exploratory`（R6 1〜3）。AC のテスト `test_AC15` は新しい値を打つので通る | AC-15（design/ 5 S-7a、S-3c） | 要修正 | ios-engineer |
| (3) | **W-1・W-2 の縦書きの字が 1 字ずつ `StaticText` の要素として XCUITest の木に出る**（`evidence/accessibility-audit.log` の W-1 の 14 件・W-2 の 14 件の要素が「下」「人」…の 1 字。S-5・S-10a の見本も同じ）。`hook.widget` の `accessibility.groupCount` は 1 で AC-99 のテストは通るが、これはアプリが自分で数えた値。contracts/test-hooks.md H22「拡張の View は全体を 1 つの要素にまとめている」なら、字は要素として出ないはず。VoiceOver が 1 字ずつ読むなら AC-99 に反する | `-uitest-widget-show accessoryRectangular:172x76 -uitest-readouts off` で `performAccessibilityAudit` か `app.debugDescription` | なし（監査の道具で見つけた。`test_AC99` は読み出しの値を見る） | AC-99 | 要修正（G4-13 の VoiceOver で確かめるまでは「要確認」） | ios-engineer |
| (4) | **H33 の `storekit.restore` が `held` のまま `shown` にならない。** `-uitest-hold-load storekit.restore` で S-10 の `settings.restorePurchases` を押すと `hook.state` の `hold.storekit.restore=held` になるが、5 秒待っても `shown`（読み込み中の形を出した）にならない（`evidence/logs/07-capture-steps-light.log` の `MISSING S-10 loading`）。ほかの 7 対象（`store.load`、`shelf.load`、`book.load`、`recommend.load`、`catalog.lookup`×2、`storekit.products`）は `shown` になった | 上の手順 | なし（撮影の道具） | なし（契約 H33。AC の外） | 提案 | ios-engineer |
| (5) | **AX5 で `hook.widget.canvas` の frame が `showcase.canvasHeight` と合わない。** `systemSmall:170x170` で frame の高さ 171.67（頼んだ 170 と 1.67pt 違う）、`liveActivity:370x160:waiting` で frame の高さ 191（`canvasHeight` は 160 と報告。中身が 160 を超えても枠で切られていない）。契約 H22「枠の外にはみ出した中身は枠で切る」「0.5pt 以内で同じ」 | `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL -uitest-widget-show systemSmall:170x170` | なし（撮影の道具の XCTAssertEqual。`evidence/logs/07-capture-steps-ax5.log`） | なし（契約 H22。AC の外。本物の W-2 は WidgetKit が切る） | 提案 | ios-engineer |
| (6) | S-9 の「3晩、83分」が見出し `finish.summary` と文 `finish.reflection`「3晩、合計83分（1時間23分）。…」に二度出る（`evidence/S9_normal_light.png`、`S9_normal_en.png`。`NIGHT_TEXTS count=2`）。`finish.summary` は design/ 7 にキーがない（r2i の未解決 8） | S-9 を開く | なし | なし（AC-127 は文の方だけを問う） | 提案 | designer（キーを決める）→ ios-engineer |
| (7) | 監査（7 章）：S-1 の縦書きの一行の 1 字「方」の Contrast failed、N の Contrast failed、W-3 の一行と W-4 のラベルの Text clipped、S-10a の `store.product.title` の Text clipped、S-3a/S-3b/S-3c の `mark.page.previous` の Label not human-readable（`p.45`） | 7 章 | `test_G3_accessibilityAudit` | AC-99、AC-101（見た目） | 提案 | ios-engineer |
| (8) | design/ 5 との食い違い（r2 の 11 章 (5) の残り）：S-3 で前のしおりがないときの `mark.later.note.empty` が出ない（`S3_empty_asis_light.png`）。S-9 の `colophon.capture` をカメラ拒否で押しても `camera.denied` が出ない（`S9_denied_asis_light.png`。S-7 からの `colophon.capture` では出る：`S7_denied_light.png`）。S-7c で奥付から 1 文字も読めなかったとき `mark.ocr.none` と `colophon.retake` が出ず、空の欄だけが出る（`S7c_empty_asis_light.png`） | 9 章 | なし | なし（design/ 5） | 提案 | ios-engineer |
| (9) | AX5 の S-1 で、`読み始める` の下の伏せの案内の文が画面の下端で半分切れている（`evidence/S1_normal_ax5.png` の最下部） | AX5 で S-1 | なし | AC-101（見た目） | 提案 | ios-engineer |

## 12. PRD とテストの食い違い
なし。AC-91 の「1つ」は PRD の文のとおりにテストし、実装に合わせていない（11 章 (1)）。

## 13. 未検証のものと理由
- AC-91：7 本のうち 3 本（`book.update`、`record.update`、`record.delete`）が落ちる（11 章 (1)）。4 本は通る。
- 探索のチャーター R2（伏せて始める）、R3（しおり保存と OCR）、R5（App Intents）：今回は行っていない（手数）。R1・R4・R6 は 8 章。
- 晩の日付の英語の書き方「October 15」は design/ 7 にキーがなく、docs/reviews r2i の `nightDayText(_:wide:)` の記述から決めた。designer がキーを決めたら `L10n.nightDay` をそれに合わせる（5 章）。
- `finish.summary` のキー（11 章 (6)）、`AppL10n.pick` の 21 か所（r2i の未解決 3）は designer 待ち。
- W-3 の Dynamic Island、W-4 の本物の Control、本物のロック画面のウィジェット、VoiceOver の読み上げのまとまり（11 章 (3)）、G4-1〜G4-22 は G4 で Takuma が実機で確かめる。
- 2 回目の light の撮影（S-7c empty / partial、S-9 error、S-10 offline、W-3 ended）：末尾の「追記」。

## 追記（2 回目の light の撮影）
- コマンド：`TEST_RUNNER_G3_CAPTURE=1 TEST_RUNNER_G3_VARIANT=light TEST_RUNNER_G3_OUT_DIR=<外のフォルダ> caffeinate -dims xcodebuild test … -only-testing:ReadingAcceptanceTests/G3EvidenceCaptureTests/test_G3_captureWidgets -only-testing:ReadingAcceptanceTests/G3EvidenceCaptureTests/test_G3_captureStates -only-test-configuration "Japanese (ja)"`（11-03 10:51〜11:12、終了コード 65。`captureWidgets` passed 295 秒、`captureStates` failed 879 秒。手順ごとの OK / MISSING / NOTE は `evidence/logs/07-capture-steps-light2.log`）
- 直した手順と結果（画像は `evidence/` に足した。1 回目の light と同じ名前の画像は 2 回目のもので上書き）：
  - W-3 ended：記録つきの投入で撮れた（`W3_ended_light.png`：「羅生門」「10分 · p.61」）。1 回目の `H22:liveActivity.ended.noRecord` は手順の不足（契約どおりの振る舞い）
  - S-9 error：読み終える保存（`book.status`）は通し、未所有の同じ著者の候補「鼻」の `next.addToShelf` を `-uitest-fail-save book.add:1` で失敗させた → `common.save.error` が S-9 の上に出て S-9 のまま（`S9_error_light.png`。design/ 5 の S-9 エラーのとおり）
  - S-10 offline：`-uitest-offline` で `settings.restorePurchases` を押すと `store.offline`（「通信できないため、商品の情報を読み込めませんでした。…」）が出た（`S10_offline_light.png`。契約 8 章のとおり）
  - S-7c partial（出版社と出版年だけ読めたとき）：出版社「岩波書店」と出版年「1927」が欄に入り、著者と ISBN は空（`S7c_partial_light.png`。design/ 5 のとおり）。1 回目の MISSING は、S-7c の欄に `colophon.publisher` の識別子がない（design/ 6 の `colophon.*` は S-7・S-9 の奥付の行の名前で、S-7c の欄の名前は design/ 6 にない）ことによる手順の不足
  - S-7c empty（0 文字）：`mark.ocr.none` と `colophon.retake` が出ず、空の欄のフォームだけが出る（`S7c_empty_asis_light.png`。要素の有無：`colophon.retake=false`、`colophon.save=true`）。design/ 5 の S-7c「1文字も読み取れなかったとき：`mark.ocr.none` と「撮り直す」（`colophon.retake`）を出し」と違う → 11 章 (8) に足す（提案）
  - S-10 loading（`storekit.restore`）：2 回目も `held` のまま `shown` にならず（`S10_loading_asis_light.png` は `held` の画面）。11 章 (4)
- 2 回目で撮れなかった組：S-10 loading（`storekit.restore`）だけ。design/ 5 の画面×状態で残るのは、仕様上ない状態（W-3 の読み込み中・オフライン、W-4 の読み込み中・エラー・権限なし、W-5 のエラー、S-3a/S-3b/S-7a/S-7b/S-8c の保存の間）と、G4 の実機で見るもの（Dynamic Island、本物の Control）

