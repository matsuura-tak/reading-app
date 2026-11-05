FAIL

> 指揮役の注（2026-11-05）：この報告は 2026-10-22 に Claude のセッションの reviewer が HEAD cec65d5／1ad1744 に対して出したもの。同じ名前のファイル docs/reviews/001-reading-session-G2-code-reviewer-r2.md は Takuma の側の reviewer が 6442fe2 に対して出した判定で、そちらが PR #2 の正となる。この報告は履歴として別名で残す。

# 001-reading-session G2 テストの判定 r2（reviewer）

- 日付：2026-10-22
- 対象：HEAD 1ad1744 の ios/AcceptanceTests/ と docs/verification/001-reading-session/（r1 の対象 2c0d980 以降。指示書の範囲は fd586ac..1ad1744）
- 証拠：CI run 22（cec65d5）：受け入れテスト ja_JP 80/80、en_US 80/80（xcresulttool 両構成 80/0/0）。ac18-reboot.sh は 1 段目 PASS、再起動の段で simctl 405
- 指揮役の注：読み取りだけの reviewer の報告を指揮役がそのまま保存したもの。判定は「AC-18 の 2 段目の CI 待ちの保留」。閉じる条件は下の (1)〜(4)。

## 判定の理由
重大は 0 件。テストを弱める変更はなく、受け入れテスト 80 本は ja_JP と en_US の両方で 1 回ずつ動いて全部通った（run 22）。PASS にしない理由は 2 つ。
1. **未検証が 1 つ残っている。** test_AC18_2_libraryRemainsAfterReboot は一度も動いていない。直した ac18-reboot.sh（1ad1744）も本物の simctl ではまだ動いていない（役の決まり「動かせなかった確認が 1 つでもあれば PASS にしない」）。
2. **要修正が 1 件ある。** evidence/red.log の 6 が r1 から空のまま（要修正1）。

**閉じる条件**（指揮役が run 23 のログで確かめる）
- (1) ac18-reboot.sh の出力に次の行がすべて出ていること。make ios-test の終了は 0。`ac18-reboot: state=Shutdown → shutdown を飛ばす（もう止まっている）` か `state=Booted → shutdown する`、`state=Shutdown → boot する`、`test_AC18_2_libraryRemainsAfterReboot exit=0`、`passed 2 of 2 (seed, verify after reboot)`
- (2) 同じ run の要約の f が `構成 ja_JP …：通過 80、失敗 0、飛ばした 0` と `構成 en_US …：通過 80、失敗 0、飛ばした 0`、`testFailures：0 件` であること。前に落ちた ja の 3 本がここで落ちたら、揺れが確かめられたことになり FAIL のまま。
- (3) `git diff --stat 1ad1744..<run 23 のコミット> -- ios/AcceptanceTests` が空であること。
- (4) 要修正1 を verifier が直したこと。

## 前回（r1）の指摘
| r1 の指摘 | 結果 | 根拠 |
|---|---|---|
| 重大1 AC-23 のパーセントエンコード | 直った | 477226f。UTF-8 のバイト列から形を作り、前提として `%E5%9D%8A%E3%81%A3%E3%81%A1%E3%82%83%E3%82%93` と小文字の形に等しいことを確かめる。run 22 で AC-23 は両構成 passed |
| 提案1 AC-5 の measure | G3 の計画にある | test-plan.md:158 |
| 提案2 AC-21 の割り込みの記録と .userTracking | 直った | addUIInterruptionMonitor で XCTFail。`XCTAssertEqual(interruptions, [])` |
| 提案3 AC-3 の貼り付け | 直った | LibraryAcceptanceTests.swift:66-70 |
| 提案4 AC-4 の taps | 直った | 変数を外し、理由を注に |
| 提案5 使っていない L10n | 直った | noteRetryLabel で使う（判定に数えない添付） |
| 提案6 @unchecked Sendable | 直った | 理由のコメント、listener を lock の中に |
| 提案7 target.yml の Unit | 直った | testPlans は Acceptance と AC18Reboot だけ |
| 未検証(1) コンパイル | 閉じた | 807f934、c9e7427、cec65d5 でビルドが通り 80 本が動いた |
| 未検証(1) 赤の実行 | 一部閉じた | 要修正1 |
| 未検証(2) XCUIProtectedResource.camera | 閉じた | コンパイルが通り AC-21 passed |
| 未検証(3) CI でしか確かめられない動き | 再起動の後のデータ以外は閉じた | 下の表 |
| 未検証(4) SpringBoard のアラート | AC-21 の範囲では閉じた | 割り込み 0、AC-21 passed |
| 未検証(5) org-check | 指揮役が確かめる | （指揮役の注：毎回の push で org-check は success） |
tech-lead r1 の要修正 3 件（target.yml、AC-23、ac18 の数え方）と提案 3 件も 477226f で直っている。

## 指摘
### 重大
なし。差分の中にエージェントへの指示のような文はない。2 枚の PNG も開いて確かめた（アプリの画面だけ）。

### 要修正
- **要修正1** docs/verification/001-reading-session/evidence/red.log:85-86（6 の節）
  - 何が問題か：6 の節が r1（2c0d980）から変わっていない。XCUITest の赤の記録がない。
  - 根拠：test-plan.md:192「CI の出力（終了コード、Executed N tests, with M failures、落ちたテストの最初のメッセージ）を red.log の 6 に足し」、test-plan.md:213「G2 の CI の出力を red.log の 6 に足すまで、赤の実行は済んでいない」、gates.md の G2 の例外「evidence/red.log がある」。
  - 直す方向（verifier）：実装の前の赤はもう取れない。CI が初めてテストまで進んだのは 807f934（a4065e3 はシミュレーター名で止まった）。6 に次を書く：807f934 の出力（`Executed 80 tests, with 35 failures`、ログに残った error 24 行と範囲外 11 本、ja_JP は取れていない）、コンパイルの誤りでは落ちていないこと、35 本の仕分け（ci-runs/807f934-acceptance-en.md）、テストが実装の本当の誤りを捕まえたこと（AC-35 は 6f714ed、AC-56 は 8034689 で、期待を変えずに通った）、c9e7427（en 80/0、ja 3 本 FAIL）と cec65d5（両方 80/0）の緑、AC-39 の赤から緑（exit 1 → 0）。test-plan.md:213 の印をこの事実に合わせて直す。

### 提案
r2 では新しい指摘を重大だけにする決まりなので出さない。「答え」の中の勧めは判定に数えない。

## 指示書の問いへの答え
1. **期待を緩めていないか → 緩めていない。** `git diff -U0 fd586ac..1ad1744 -- ios/AcceptanceTests` で `-` のアサーションは 4 行だけ：count → buttonCount 2 か所、`el().isEnabled` → `control().isEnabled` 2 か所の 1 対 1 の置き換え。`Wait.enabled` 3 か所も同じ。足した行は replaceText の前提の XCTAssertEqual 2 行（厳しくする方向）。待ち時間の定数（timeout 10、optional 2、telemetry 60）、テストの名前、識別子の文字は不変。buttonCount：PRD:549/:555 の「session.finish.save が 1 個」は「終える入力が開いている」の意味。Takuma の Mac の要素の木（toolbar-save-hierarchy-before.txt:6-7）では同じ識別子の Other と Button が入れ子で 1 組あり、正しい実装でも全種類で数えると 2 になる。Button を数えれば保存ボタンが 2 つ並べば 2 になり重複は見つけられる。control()：mac-r1:36「Other は有効・Button は無効と実測」。Other の isEnabled は .disabled を映さないので、前のテストは間違った要素を見ていた。
2. **飛ばし、再試行、ごまかし → ない。** XCTSkip、XCTExpectFailure、@testable、testRepetitionMode、-retry-tests-on-failure、-test-iterations：0 件。skippedTests は Acceptance.xctestplan の AC-18 の 2 本だけ（r1 と同じ）。run-acceptance.sh の終了コードは PIPESTATUS[0] のまま、要約は set +e の中で合否を変えない、0 本で緑なら 65。run 22 の a2 を数えると各回 80 行・名前の重複 0・全部 passed。ac18-reboot.sh:99 の `sleep "$STATE_WAIT_STEP"` は許される形と判断（simctl の state を 2 秒ごとに読み直す間隔。上限 60 秒で決まらなければ 67。落ちる側にしか効かない）。ただし gates.md の G3 の「sleep … の検査が 0 件」で迷わないよう、verifier が test-plan の確かめに「1 件の例外（理由つき）」と書くのがよい。
3. **赤から緑の過程 → 仕分けは妥当。** 原因A：807f934 のログ 406-409 で Open の下に Launch と Setting up automation session、AC-6 は label == "2" で失敗（2432-2433）。run 22 では `Opening default application for URL` 28 回とも直後 8 行に Launch なし、SpringBoard を探した行 0。置き換え先は T16 の 2026-10-22 の改訂と合う。原因B：213 行 `("510") is not equal to ("5")`。原因C：Mac で実測。実装 1（AC-35）はテストを変えず 6f714ed で通った。裁定 2（AC-56）は期待 1 個のまま 8034689 で通った。不明 1（AC-32）は replaceText 以外変えず run 22 で通った。
4. **G1 の裁定と設計メモ 10 のうちテストで決まったもの**：(a) 根の識別子は S1、S3、S4、S5 で見える（決まった）。(g) swipeDown は代わりの案の形で決まった（AC-48）。T16 の確かめのダイアログは en の回では出ない。T6 の localhost は決まった（T22 に替えなくてよい。計測の 6 本が両構成 passed）。-AppleLanguages/-AppleLocale は決まった（ja_JP 80/0/0）。-testPlan、include の testPlans、CODE_SIGNING_ALLOWED=NO、xctestplan の ID、約 3KB の環境変数、XCTOSSignpostMetric は決まった。**D-60 は残る**（swipeDown と `UITEST_FAIL=session_cancel_finish:1` を組んだテストがない。設計メモ:309「G3 まで残れば G3 は通らない」）。(b) は識別子と文字のどちらで探したか未確認。(c) VoiceOver と iOS 17 は G4。**AC-18 の再起動の後のデータは run 23 待ち**。
5. **ja_JP の 3 本（AC-60、AC-62(b)、AC-63(a)）→ 今は FAIL の理由にしない。G3 の条件として引き継ぐ。** run 21 と run 22 の間にアプリのコードの変更はない（`git diff --stat c9e7427..cec65d5 -- ios ':!ios/AcceptanceTests'` が空）。揺れの疑いが強いが、原因がテストかアプリかは決められない。gates.md の G3「一度でも落ちたテストを 5 回繰り返し、1 回も落ちない」を verifier の案（再試行なしの -test-iterations 5 -run-tests-until-failure を ja_JP と en_US で）で満たす。勧め（判定に数えない）：-only-testing で 3 本だけ繰り返すと落ちた条件（その回の最初のほうで新しいシミュレーターで T16 を使う）にならないおそれがあるので、少なくとも 1 回は新しいシミュレーターで Acceptance を ja_JP から全部回すか、ReadingScreenAcceptanceTests のクラスを丸ごと繰り返す。
6. **AC-18 → 保留（条件付き PASS にしない）。** 1 段目は run 22 で PASS。再起動の段は simctl 405 で落ちた。1ad1744 の直しは理にかなっている（state を読み、Booted なら shutdown、Shutdown なら飛ばして boot と bootstatus。どの道でも 2 段目の前に「止まった状態から起動した」ことを通る）。bash -n は exit 0。本物の simctl では未実行。
7. **red.log → 要修正1。**

## 証拠（抜粋）
- 対象：2c0d980..1ad1744（指示書の範囲 fd586ac..1ad1744）。HEAD は ee2c89a（1ad1744 との差は G2 コード r2 の報告だけ）。`git status --short` は空。
- 読んだファイル：ci-runs の 3 件（全文）、evidence/mac-20261022（全文と PNG 2 枚）、Support/AcceptanceTestCase.swift（全文）、Support/{AppSession,L10n,UIHelpers}.swift（差分の全部。AppSession.swift:90-130 は今の版も）、Tests/ の 11 ファイル（差分の全部。Library:52-87、FinishInput:182-196 は今の版も）、run-acceptance.sh、ac18-reboot.sh（全文）、xctestplan 2 つ（全文）、target.yml と test-plan.md（477226f の差分と関係する節）、ac39-xcstrings.sh（動かした）。
- 範囲の外の変更：.claude/org/app.json、lock.json、.github/workflows/ios.yml は a4065e3（Takuma）。Unit.xctestplan は ffcc7fd（ios-engineer。コードの観点）。受け入れテストを変えた作り手のコミットはない。3c3f790 は Takuma の変更で、中身は 1 で判断した。
- テストを弱める変更の検査：`git diff -U0 <BASE>..1ad1744 | grep -E '^\+.*(XCTSkip|\.disabled\(|withKnownIssue|XCTExpectFailure|…)'` → .md の文とアプリの SwiftUI の .disabled だけ。アサーションの数：fd586ac から `62 +`、`4 -`。2c0d980 から `344 +`、`10 -`（単体テスト含む。ios/AcceptanceTests だけで `16 +`、`10 -`。− の 10 行は置き換え 4、AC-23 の書き直し 4、AC-4 の taps 1、threshold の `as? String` 1）。func test_ の差分 0 行。`git grep -nE 'sleep|retry-tests-on-failure|testRepetitionMode|test-iterations|XCTSkip|XCTExpectFailure|skippedTests|@testable' 1ad1744 -- ios/AcceptanceTests` → コメント 4 行、skippedTests 1、ac18-reboot.sh:99 の sleep 1、要約の skippedTests のキー 1。
- run 22 のログ（ios-cec65d5.log）：4610-4867 の要約（xcodebuild 0、f は両構成 80/0/0、testFailures 0、b/b2/c/d/e は 0）。a2 の 160 行をソースの func test_ 82 本と比べ `{('1','passed'):80, ('2','passed'):80}`、欠けたのは AC18 の 2 本だけ。4596 `Executed 80 tests, with 0 failures`、4606 TEST SUCCEEDED、4944-4963 AC-18 の 1 段目 PASS と shutdown 405、Error 149。`Opening default application for URL` 28 回で直後 8 行の Launch は 0、SpringBoard を探した行 0。
- 807f934 のログ：406-409 Open の後に Launch、2432-2433 AC-6 の label == "2" で失敗、213 `("510") is not equal to ("5")`、4904 `Executed 80 tests, with 35 failures`。c9e7427 のログ：Failing tests に AC-62(b)、AC-60、AC-63(a)。a4065e3 のログ：シミュレーターが見つからず Error 70（テストは動いていない）。
- コードの変化：`git diff --stat c9e7427..cec65d5 -- ios ':!ios/AcceptanceTests'` → 空。`git diff --name-only cec65d5..1ad1744` → docs/progress.md、cec65d5-acceptance.md、ac18-reboot.sh だけ。
- 手元で動かしたもの：bash -n の 2 本は exit 0。`bash ios/AcceptanceTests/ac39-xcstrings.sh` → untranslated_keys=0、PASS。
- 開いた URL：なし。

## AC 対応表（r1 以降に変わった AC だけ）
| AC | テスト | 確かめている結果 | 変わったこと | run 22 |
|---|---|---|---|---|
| AC-3 | Library.test_AC3 | 保存できず、起動し直しても本が 0 冊 | 押せるかを Button で見る | 両方 passed |
| AC-31 | AddBook.test_AC31 | 範囲の外で誤りの文が出て保存されない | 同上 | 両方 passed |
| AC-11、AC-30 | FinishSession の 2 本 | 範囲の中なら保存でき記録が増える | 同上。replaceText に前提 | 両方 passed |
| AC-63(a)(b)、AC-64 | ReadingScreen と FinishInput | finishing、分の欄の値、記録 1 件のまま | 保存ボタンを Button で数える | 両方 passed |
| AC-5〜7、20、21、23、24、45〜48、50、51、57〜67 | T16 を使う全部 | 経過、状態、記録、計測 | 時計の送り方を system.open に | 両方 passed |
| AC-18 | AC18Reboot の 2 本 | 再起動の後も本と記録が残る | 基底のクラスだけ | 1 段目 PASS、2 段目は未実行 |
| AC-39 | ac39-xcstrings.sh | 翻訳していないキー 0 | 不変 | PASS |

## 未検証
- AC-18 の 2 段目と、1ad1744 の ac18-reboot.sh の本物の simctl での動き（run 23 待ち）。
- run 22 の ja_JP の回の生のログ（範囲外。要約と xcresulttool の数だけ）。ja の回で T16 の確かめのダイアログが出たかは不明。
- org-check の CI の状態（指揮役が確かめる：毎回 success）。
- G3 に引き継ぐもの（G2 の未検証には数えない）：ja の 3 本の 5 回の繰り返し、D-60、AC-5 の 0.5 秒の値、iOS 17（G4）。
