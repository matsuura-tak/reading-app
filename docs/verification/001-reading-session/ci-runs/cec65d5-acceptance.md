# CI cec65d5（run 22）受け入れテストの記録と、AC-18 の再起動の段の直し

- 書いた役：verifier（2026-10-22）。判定ではなく、CI の結果の記録と、ac18-reboot.sh の直しの記録。G2 の red（evidence/red.log）と test-plan.md は変えていない。
- コミット：cec65d5（PR #2、ブランチ claude/cool-ptolemy-17gnb3）。CI：macos-latest、Xcode 26.6（`/Applications/Xcode_26.6.app`）、シミュレーター iPhone 17（iOS 26.5、UDID 10B884BF-749F-4E8B-AFCD-26AB8F1DBD01。ログ 4864〜4865、4879〜4881）。
- 読んだログ：指揮役が取った末尾 4,999 行（18:08:13Z 以降。ios-cec65d5.log、リポジトリの外）。4610〜4867 行が run-acceptance.sh の要約、4868〜4963 行が ac18-reboot.sh の出力。
- この環境（Linux）には Xcode も simctl もない。4 の直しは **Xcode と本物の simctl では未実行**（bash -n と、simctl の stub での流れだけ）。

## 1. 結果

| 段 | 結果 | 根拠 |
|---|---|---|
| ios_build（Debug、Release、つなぎ口の検査） | 通過 | 指揮役の確認（この末尾のログの範囲外） |
| 単体テスト（Unit） | 通過 | 指揮役の確認（範囲外）。ios_test は `&&` でつながり、続く run-acceptance.sh が動いたことと合う |
| 受け入れテスト 回1（ja_JP） | 80 本、失敗 0 | 要約 a（ログ 4652、4654）：`[回1] Executed 80 tests, with 0 failures (0 unexpected) in 2522.756`。17:11:45〜17:53:47 |
| 受け入れテスト 回2（en_US） | 80 本、失敗 0 | 要約 a（ログ 4691、4693）：`[回2] Executed 80 tests, with 0 failures (0 unexpected) in 2462.718`。17:54:02〜18:35:04 |
| xcresulttool の構成ごとの集計 | ja_JP 80/0/0、en_US 80/0/0（通過/失敗/飛ばした）、testFailures 0 件 | 要約 f（ログ 4864〜4866） |
| xcodebuild（Acceptance） | 終了 0、`** TEST SUCCEEDED **` | ログ 4606、4611 |
| AC-18 の 1 段目（test_AC18_1_seedLibraryBeforeReboot） | PASS（exit=0、`Executed 1 test, with 0 failures`、17.001 秒） | ログ 4944〜4948、4956、4959 |
| AC-18 の再起動の段 | FAIL：`xcrun simctl shutdown` が code=405 | ログ 4960〜4962（4 で直した） |
| AC-18 の 2 段目（test_AC18_2_libraryRemainsAfterReboot） | 動いていない | 再起動の段で止まった。`make: *** [ios-test] Error 149`（ログ 4963。149 は simctl の 405 を 256 で割った余り） |
| 時間 | Acceptance の testing は 5114.318 秒（約 85 分。ログ 4599）。run 21 の 6398.845 秒（約 107 分）より短い | ログ 4599、c9e7427-acceptance.md の 1 |

- 回と言語の結び方：xcodebuild はログに構成の名前を出さない。回1=ja_JP、回2=en_US は Acceptance.xctestplan の構成の順（ja_JP、en_US）からの読み。落ちたテストがないので [AT-DIAG] の「構成：ACCEPTANCE_LANG=」の行は出ず（d は 0 行、ログ全体でも [AT-DIAG] は要約の見出しの 1 行だけ）、ログからは確かめられない。ただし f で **両方の構成が 80/0/0** なので、どちらの回が ja でも、ja_JP で 80 本すべてが通ったことは言える。
- 異常終了（`Restarting after unexpected exit` など）はない（b3 は `** TEST SUCCEEDED **` の 1 行だけ。ログ 4858）。
- AC18RebootTests は Acceptance の計画では 0 本（ログの要約 a の `AC18RebootTests ... Executed 0 tests`）。AC18Reboot.xctestplan でだけ動く形のとおり。

## 2. 前回 ja で落ちた 3 本（AC-60、AC-62 (b)、AC-63 (a)）

| テスト | run 21（c9e7427）ja | run 22 回1（ja_JP）の順番と秒 | run 22 回2（en_US）の順番と秒 |
|---|---|---|---|
| ReadingScreenAcceptanceTests.test_AC60_resumeFailureKeepsPaused | FAIL | 43 番目、passed、30.934 秒（ログ 4737） | 55 番目、passed、31.204 秒（ログ 4829） |
| ReadingScreenAcceptanceTests.test_AC62_beginFinishFailureWhilePaused | FAIL | 45 番目、passed、31.329 秒（ログ 4739） | 59 番目、passed、31.519 秒（ログ 4833） |
| ReadingScreenAcceptanceTests.test_AC63_beginFinishRetryWhileReading | FAIL | 41 番目、passed、40.653 秒（ログ 4735） | 58 番目、passed、40.324 秒（ログ 4832） |

- 3 本とも今回は ja_JP で通った。秒も en と同じくらいで、待ちの上限に近づいた様子はない。
- **原因は決められないまま通った。** run 21 では失敗の文言がログの範囲外で、今回は失敗がないので [AT-DIAG]（システムのダイアログ、T16 の確かめのダイアログ）も出ていない。c9e7427-acceptance.md の 4.2 の見立て（(i)+(ii) 初回の回の T16 の揺れ、(iii) 画面の変化の順、3 の paused で区画が出たままの経過、(iv) ja の文言）のどれも、確かめても打ち消してもいない。ただ、同じテストのコードが ja で落ちて（run 21）また通った（run 22）ので、毎回の失敗（3、(iv)）より**揺れの疑い**が強くなった。
- 判定上の扱い：一度緑になっただけでは合格にしない（craft-verifier 1 の 4）。AC-60、AC-62 (b)、AC-63 (a) は「未検証」のまま。G3 で ja_JP と en_US の両方を、再試行なしの `-test-iterations 5 -run-tests-until-failure` で確かめることを勧める（例：`-only-test-configuration ja_JP -only-testing:YomutokiAcceptanceTests/ReadingScreenAcceptanceTests/test_AC60_resumeFailureKeepsPaused` など 3 本。en_US も同じ）。1 回でも落ちれば、run-acceptance.sh の要約 b と d で原因の型を決める。
- 直したテスト：なし。待ち時間、期待、再試行は変えていない。

## 3. 要約の仕掛け（run-acceptance.sh）が動いたこと

- `=== ACCEPTANCE SUMMARY ===`（ログ 4610）から `=== END ACCEPTANCE SUMMARY ===`（ログ 4867）まで、a〜f の全部の節が出た。xcodebuild の終了コード 0（4611）。
- a は回1と回2に分かれた（最上位のスイート `Selected tests` の started で数える形が働いた）。a2 は 160 行（ログ 4694 の見出し）。b、b2、c、d、e は 0 行・0 本で、失敗がないことと合う。f は xcresulttool の JSON を読めて、構成ごとの件数が出た（c9e7427-acceptance.md の 6 の「f の JSON のキーは未確認」はこれで確かめられた）。
- ログ 4833 の行の途中に BOM が入っていた（CI のログの区切りによるもの）が、要約の行の中身は読める。要約は CI のログから読んだもので、Acceptance.log と .xcresult（ランナーの中）は取り出していない。

## 4. AC-18 の再起動の段の失敗と直し方

### 4.1 原因

- run 22 の出力（ログ 4959〜4963）：
  ```
  ac18-reboot: test_AC18_1_seedLibraryBeforeReboot exit=0
  ac18-reboot: reboot 10B884BF-749F-4E8B-AFCD-26AB8F1DBD01
  An error was encountered processing the command (domain=com.apple.CoreSimulator.SimError, code=405):
  Unable to shutdown device in current state: Shutdown
  make: *** [ios-test] Error 149
  ```
- CI（macos-latest、Xcode 26.6）では、1 段目の xcodebuild test が終わった時点でシミュレーターが Shutdown に戻っていた。前の ac18-reboot.sh は state を見ずに `xcrun simctl shutdown` を呼び、止まっている端末への shutdown が code=405 で落ち、`set -e` で終わった。テストの失敗ではなく、スクリプトの手順の誤り（AC-18 の 2 段目はまだ動いていない）。

### 4.2 直し方（ios/AcceptanceTests/ac18-reboot.sh）

- `sim_state`：`xcrun simctl list devices -j` を python3 -I で読み、UDID の state を出す（一覧にないときは空）。UDID の決め方と同じ流儀。
- `wait_settled_state`：state が Booted か Shutdown になるまで、2 秒ごとに state を読み直して最大 60 秒待つ（`simctl bootstatus -b` は使わない）。決まらなければ 67、UDID が一覧から消えたら 66、simctl か python3 が落ちたら 0 でない終了コード。
- 再起動の段：state が Booted なら `xcrun simctl shutdown`、Shutdown なら「shutdown を飛ばす」と出す。もう一度 state を読み、Shutdown なら `xcrun simctl boot`、Booted なら「boot を飛ばす」と出す（守り）。その後の `xcrun simctl bootstatus "$UDID"` は前と同じ。終わりに bootstatus の後の state を出す。
- 何をしたかは `ac18-reboot: state=<state> → shutdown する／shutdown を飛ばす（もう止まっている）／boot する／boot を飛ばす（もう起動している）` の行で CI のログに残る。
- 変えていないもの：`set -euo pipefail`、UDID の決め方、run_one、xcodebuild の引数、`Executed 1 test, with 0 failures` の数え方。再試行は足していない。
- AC-18 の意味（PRD：端末を再起動しても本と記録が残る。contracts/test-hooks.md の T11：データを作る実行と確かめる実行の間でシミュレーターを再起動する）は、「止まった状態（自分で止めたか、もう止まっていたか）→ boot → bootstatus → 確かめる実行」で満たす。どの道でも、1 段目の後に Shutdown を見たか、shutdown が成功したかのどちらかを通るので、止めずに 2 段目に進むことはない。

### 4.3 手元で確かめたこと（Linux。Xcode と simctl はない）

- `bash -n ios/AcceptanceTests/ac18-reboot.sh` → 終了 0。
- simctl の stub（scratchpad の中。`simctl list devices -j` の形の JSON を返し、止まっている端末への shutdown は code=405 と終了 149、起動している端末への boot は終了 149 にする。同じ名前「iPhone 17」の別の UDID と別の機種も一覧に入れた）、xcodebuild の stub（`Executed 1 test, with 0 failures` を出す）、sleep の stub（待たずに呼ばれたことだけ残す）を PATH の先に置いて、スクリプト全体を流した。

| 場合（state の移り方） | 終了 | simctl の呼び出し（1 段目の後） |
|---|---|---|
| 前のスクリプト、Shutdown（run 22 の再現） | 149 | shutdown → 405 で落ちる（run 22 と同じ文言） |
| Shutdown（run 22 の形） | 0 | list → 「shutdown を飛ばす」→ list → boot → bootstatus → 2 段目、`passed 2 of 2` |
| Booted | 0 | list → shutdown → list → boot → bootstatus → 2 段目 |
| Booting → Booting → Booted | 0 | 2 秒の待ちを 2 回 → shutdown → boot |
| Shutting Down → Shutdown | 0 | 2 秒の待ちを 1 回 → 「shutdown を飛ばす」→ boot |
| Booting のまま | 67 | 2 秒の待ちを 30 回（0〜58 秒）→「60 秒たっても…ならない」。shutdown、boot、2 段目は呼ばない |
| UDID が一覧から消えた | 66 | list → 「simctl list devices -j にない」 |
| shutdown の後も Booted（守り） | 0 | shutdown → 「boot を飛ばす」→ bootstatus → 2 段目 |
| list が落ちる | 1 | list で終わる（pipefail で python3 の 1）。shutdown、boot は呼ばない |

- craft-verifier の 4 の検査（ac18-reboot.sh）：`sleep\(|usleep|Thread\.sleep|time\.sleep|asyncio\.sleep` 0 件、`-i 'retry|rerun'` 0 件。ただし bash の `sleep "$STATE_WAIT_STEP"` が 1 行ある（4 の型には当たらない）。時間で合わせるためではなく、simctl の state の変化を 2 秒ごとに読み直す間で、上限は 60 秒。

## 5. 次の CI で見ること

- ac18-reboot.sh の出力に `ac18-reboot: state=Shutdown → shutdown を飛ばす（もう止まっている）`（または `state=Booted → shutdown する`）、`state=Shutdown → boot する`、`state=Booted（bootstatus の後）`、`test_AC18_2_libraryRemainsAfterReboot exit=0`、`passed 2 of 2 (seed, verify after reboot)` が出ること。
- 2 段目が落ちたら、それは AC-18 のテストの失敗として扱う（スクリプトの手順の問題とは分ける）。

## 6. 未確認

- 直した ac18-reboot.sh は Xcode と本物の simctl で未実行。`simctl list devices -j` の state の文字（Booted、Shutdown、Booting、Shutting Down）は Xcode 26.6 の出力では確かめていない（Shutdown は run 22 の 405 の文言「current state: Shutdown」と合う。Booted などは run 22 のログに出ていない）。
- xcodebuild test の後に毎回 Shutdown に戻るのか、ときどきなのかは分からない。どちらでも 4.2 の形で動く。
- 回1=ja_JP、回2=en_US は計画の構成の順からの読み（1 のとおり）。2 の順番（43、45、41 番目）はこの読みに頼る。
- AC-60、AC-62 (b)、AC-63 (a) の run 21 の失敗の原因は決まっていない（2）。
