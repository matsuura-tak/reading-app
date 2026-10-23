# CI c9e7427（run 21）受け入れテストの記録と、落ちた3本の見立て

- 書いた役：verifier（2026-10-22）。判定ではなく、CI の結果の記録と、次の CI でログから原因を決めるための仕掛けの記録。G2 の red（evidence/red.log）と test-plan.md は変えていない。
- コミット：c9e7427（PR #2、ブランチ claude/cool-ptolemy-17gnb3）。CI：macos-latest、Xcode 26.6、シミュレーター iPhone 17（iOS の版はこのログの範囲に出ていない。807f934 では 26.5）。
- 読んだログ：指揮役が取った末尾 4,999 行（16:09:06Z 以降。ios-c9e7427.log、リポジトリの外）。比べるために 807f934 の末尾 4,999 行（ios-807f934.log）。
- この環境（Linux）には Xcode がない。3 のスクリプトと AcceptanceTestCase の診断の追加は **Xcode では未実行・未ビルド**。

## 1. 結果

| 段 | 結果 | 根拠 |
|---|---|---|
| ios_build（Debug、Release、つなぎ口の検査） | 通過 | 指揮役の確認（この末尾のログの範囲外） |
| 単体テスト（Unit） | 通過 | 指揮役の確認（同上） |
| 受け入れテスト en_US の回（2回目） | 80 本、失敗 0 | ログ 4944〜4947：`Test Suite 'YomutokiAcceptanceTests.xctest' passed`、`Executed 80 tests, with 0 failures (0 unexpected) in 2929.978` |
| 受け入れテスト ja_JP の回（1回目） | 3 本 FAIL | ログ 4951〜4957 の `Failing tests:`：ReadingScreenAcceptanceTests の `test_AC60_resumeFailureKeepsPaused()`、`test_AC62_beginFinishFailureWhilePaused()`、`test_AC63_beginFinishRetryWhileReading()`。ja の回の `Executed` の行と失敗の文言は範囲外（2） |
| AC-18 の再起動（ac18-reboot.sh） | 動いていない | ios_test は `&&` でつながり、Acceptance の失敗（`make: *** [ios-test] Error 65`、ログ 4963）で止まった |
| 時間 | xcodebuild の testing は 6398.845 秒（約 107 分。ログ 4948）。うち en の回が 2929.978 秒（約 49 分）。CI 全体は 14:45→16:46 | ログ 4947、4948。ja の回とビルドの内訳は範囲外 |

- 落ちた 3 本が ja の回のものだと言える理由：en の回は 80 本すべて通り（4945）、構成は ja_JP と en_US の2つだけ（Acceptance.xctestplan）。`Failing tests:` には構成の名前が出ない。
- 判定上の扱い：AC-60、AC-62 (b)、AC-63 (a) は ja で落ち、同じコミットの en で通った。原因が決まるまで、この3つの AC は「未検証」（craft-verifier 1 の 4）。

## 2. ログの範囲の限界

- 指揮役が取れるのは末尾 5,000 行だけ。1 本のテストの出力は約 30〜60 行（大半が `t = ...` の自動化の行）で、2 つの回で 160 本 → 5,000 行を超え、先に走る ja の回が切れる。
- このログの `.swift:<行>: error:` の行は 0 行、`[AT-DIAG]` の行は 0 行（`grep -cE '\.swift:[0-9]+: error: |\[AT-DIAG\]'` → 0）。en の回は全部通ったので、どちらも出ないのが正しい。
- xcodebuild はログに構成の名前を出さない（`ja_JP|en_US|Configuration` の grep は git の後片付けの 1 行だけ）。最上位のスイート（`Selected tests`）の started の行も範囲外。
- `Failing tests:` の節は、標準出力と標準エラーが混ざり、`Test session results, code coverage, and logs:` と xcresult のパスの行が名前の間に入る（4953〜4955）。
- GitHub のチェックの注釈は空、xcresult（`/Users/runner/.../Test-Yomutoki-2026.10.22_14-56-51-+0000.xcresult`）はランナーの中で取り出せない。

## 3. 次の CI のための仕掛け

### 3.1 ios/AcceptanceTests/run-acceptance.sh（新規）

- 使い方：`bash AcceptanceTests/run-acceptance.sh '<シミュレーターの名前>'`（ios/ の中。引数は 1 つ。なければ 64）。
- 中身：`xcodebuild test -project "$IOS_DIR/Yomutoki.xcodeproj" -scheme Yomutoki -testPlan Acceptance -destination "platform=iOS Simulator,name=$SIM_NAME" -resultBundlePath "$RESULTS_DIR/Acceptance.xcresult" CODE_SIGNING_ALLOWED=NO 2>&1 | tee "$RESULTS_DIR/Acceptance.log"`。終了コードは `PIPESTATUS[0]`。再試行の引数は付けない。結果は `${AC_RESULTS_DIR:-${TMPDIR:-/tmp}/acceptance}`（リポジトリの外）。前の .xcresult は消してから動かす。
- 終わったら、終了コードに関わらず、`=== ACCEPTANCE SUMMARY ===` から `=== END ACCEPTANCE SUMMARY ===` までを標準出力に出す（CI のログの末尾に残す）。各行の頭に回の番号 `[回N]` を付ける（最上位のスイートの started で数える）。
  - a. 計画の構成の順（xctestplan から）、回ごとの言語（[AT-DIAG] の「構成：ACCEPTANCE_LANG=」から）、`Test Suite '...' (started|passed|failed) at` と `Executed N tests, with M failures` の行
  - a2. 回ごとの実行順（順番、passed／failed、クラス.テスト、秒）。T16 の初回か、順番に頼るかを見るため
  - b. `.swift:<行>: error:` の行（全件）、b2. `Test Case '...' failed` の行、b3. 異常終了（`Restarting after unexpected exit` など）と `** TEST ... **` の行
  - c. `Failing tests:` の節（`** TEST` の行まで）
  - d. `[AT-DIAG]` の行。全体で 800 行まで。超えたら「…ほか N 行（[AT-DIAG] の行）は <ログ> にある」
  - e. 落ちたテストの数と名前（c の中の `クラス.テスト()` の行）と、回ごとの内訳（b2 から）
  - f. `xcrun xcresulttool get test-results summary` で読めたときだけ、構成ごとの通過・失敗・飛ばしたの数と testFailures（読めなければ「読めなかった」と出すだけ）
- 要約の部分は python3 -I（ac18-reboot.sh と同じく macOS の python3 を使う）。CI のログの行頭の時刻と BOM を外してから読むので、tee のログ（時刻なし）でも CI のログ（時刻あり）でも同じに動く。python3 が落ちたら、grep で失敗の文言と [AT-DIAG] をそのまま出す。
- 最後は xcodebuild の終了コードで終える。xcodebuild が 0 なのに `Executed <1以上> test` の行がなければ 65。
- 要約の大きさ：失敗が数本なら 150〜300 行、上限いっぱいでも約 1,200 行で、5,000 行に収まる。
- target.yml は `*.sh` をテストのターゲットから外している（excludes）ので、このスクリプトはテストの束に入らない。
- Acceptance が通ったときは、続く ac18-reboot.sh の出力で要約が末尾から押し出されうる（落ちたテストがないので困らない）。

### 3.2 ios/AcceptanceTests/Support/AcceptanceTestCase.swift（診断の行を 2 つ足した。合否は変えない）

- 落ちたときの [AT-DIAG] に `構成：ACCEPTANCE_LANG=<ja|en>` を足した。xcodebuild が構成の名前を出さないため、要約が回と言語を結べるようにする。
- 落ちたときの [AT-DIAG] に `システムのダイアログ（SpringBoard の alert、3つまで）：<なし｜「題」 ボタン：…>` を足した。システムのダイアログはアプリの要素の木（app.debugDescription）に入らないため、4 の (i) を確かめられるようにする。
- XCTAssert は足していない。期待、待ち時間、再試行は変えていない。

### 3.3 手元で確かめたこと（Xcode なし）

| 確かめ | 結果 |
|---|---|
| `bash -n ios/AcceptanceTests/run-acceptance.sh` | 終了 0 |
| 要約の python を取り出して ios-c9e7427.log に当てる | 終了 0、113 行。b 0 行、d 0 行、c に 3 本と xcresult のパスの行、e「3 本」（xcresult のパスと `Test session results` の行は名前に数えない） |
| 同じく ios-807f934.log に当てる | 終了 0、256 行。b 24 行（`grep -cE '\.swift:[0-9]+: error: '` の 24 と一致）、b2 24 行（`Test Case ... failed` の 24 と一致）、e 44 本 |
| 時刻を外した 2 回分の合成のログ（最上位の started を 2 つ、[AT-DIAG] を 840 行） | 終了 0。回 1 と回 2 に分かれ、回 1 の言語「ja」、d は 800 行で切れ「…ほか 40 行」 |
| xcodebuild の代わりの stub（scratchpad の中）で流れだけ | 引数なし → 64。失敗のログと 65 → 65 で終わり、要約は末尾 118 行。`Executed 0 tests` と 0 → 65。通ったログと 0 → 0。stub に渡った引数に再試行の引数はない |

## 4. 落ちた 3 本の見立て（失敗の文言がないので、すべて［推測］）

### 4.1 コードから言えること

- 3 本とも、同じ前半を持つ兄弟が同じ ja の回で通っている：AC-60 と AC-61（failResume）、AC-62 (b) と AC-63 (b)（failBeginFinish(paused: true)）、AC-63 (a) と AC-62 (a)（failBeginFinish(paused: false)）。3 本とも en の回で通り、AC-63 (a) は Mac の ja でも通った（docs/reviews/001-reading-session-G2-mac-r1.md の 4）。前半で毎回落ちる欠陥なら兄弟も落ちるので、**前半の失敗なら揺れ、毎回の失敗なら各テストの後半**のどちらか。
- 失敗の行番号は、helper が呼び出し元の file と line を渡すので、前半（failResume、failBeginFinish）の失敗は呼び出しの行に出る：AC-60 は ReadingScreenAcceptanceTests.swift:135、AC-62 (b) は :201、AC-63 (a) は :224。AC-60 の後半は :136〜:140。どの手順かは**文言**で分かる（4.3）。
- 後半で AC-60 と AC-62 (b) だけが見るもの：paused で保存の失敗の区画が出たまま 60 秒進めた後の、`error.saveFailed` の再確認と `reading.elapsed` の「5分0秒」（ほかのテストは paused で区画が出た後の経過を見ない。AC-33 は区画なしの paused で「5分0秒」を見て ja で通った）。AC-63 (a) だけが見るもの：reading の失敗から再試行して S5 を出した後の 2 回目の T16 と、`session.finish.minutes` の「11」。

### 4.2 有力な順

1. **(i)+(ii) ja の回が CI の最初の回であることに結びつく揺れ（T16 の時計の操作か、待ちの上限）。** 3 本すべてと、兄弟が通ったこと、en で 0 本だったことを説明できる。ja の回は、そのシミュレーターで初めて `XCUIDevice.shared.system.open` を使う回（その前は Unit だけ）。sendClock は、2 秒（Wait.optional）で効かなければ確かめのダイアログを 2 秒だけ探し、その後 10 秒待つ。ダイアログが 4 秒より後に出ると誰も押さず、T16 の失敗になる（en の回の AC-60 では URL を開いてから約 1.1 秒で効き、ダイアログの行はない。ログ 2581〜2585）。ダイアログが残ると次のテストにも響く。
2. **(iii) URL を開いたときの画面の変化の順（揺れ）。** システムから URL を開いたとき（とくにダイアログが出て消えたとき）、アプリの活性が変わり、保存の失敗の区画や経過が変わる順番の問題。AC-60、AC-62 (b) は 60 秒後の `error.saveFailed` の再確認で、AC-63 (a) は 1 回目の T16 の後の `error.retry` で落ちる形になる。区画が消えたのなら AC-60、AC-62 の Then（区画が 1 個ずつ残る）に反するので、アプリの側の問題として扱う（テストは直さない）。
3. **paused で区画が出たまま 60 秒後の経過（AC-60、AC-62 (b) だけ。毎回の失敗）。** 4.1 のとおり、この 2 本だけが見る手順。ただし AC-63 (a) を説明できず、en で通るので、言語で変わる配置などアプリの側の振る舞いが要る。
4. **(iv) ja の文言に頼る所。** いちばん弱い。失敗の道で使う ja の値（errorSaveFailed「変更を保存できませんでした」、elapsedLabels(300)「5分0秒」、sessionCount(1)、戻るボタンの文字）は、ja で通った兄弟（AC-61、AC-63 (b)、AC-62 (a)、AC-33、AC-58）も同じものを使う。noteRetryLabel は判定に数えないので除く。

### 4.3 次の CI の要約のどこを見れば決まるか

| 要約の行 | (i)+(ii) | (iii) | 3 | (iv) |
|---|---|---|---|---|
| b の文言 | 「T16 の時計の操作（advance=60）が効いた：label が「1」にならない（今は「0」）」（前半なら :135、:201、:224）。(ii) なら「… が出ない」「（今は「要素なし」）」 | AC-60、AC-62 (b)：「60秒後：error.saveFailed：label が「変更を保存できませんでした」にならない（今は「要素なし」）」。AC-63 (a)：「error.retry が出ない」 | AC-60（:138）、AC-62 (b)（:201）：「60秒後の経過（5:00 のまま）：label が ["5分0秒"] のどれにもならない（今は「X」）」。X が「6分0秒」なら失敗の後も数えている、「要素なし」なら配置 | ja の文字を並べた期待と今の値が食い違う文言 |
| d | `[AT-DIAG] T16：システムの確かめのダイアログが出たので…` が回 1 にある、または `[AT-DIAG] システムのダイアログ` が「なし」でない | 要素の木に error.saveFailed がない、uitest.clock.applied の label は進んでいる | 要素の木の reading.elapsed の label | — |
| a2、b2 | 3 本が回 1 の早い順番（T16 を使う最初のテスト）にある。落ちたテストの秒が前半＋約 14 秒 | 順番に関係しない | ja で毎回落ちる | ja で毎回落ちる |
| a | 回 1 の言語 ja | 同 | 同 | 同 |

- どれに決まっても、その AC は G3 で ja と en の両方を `-test-iterations 5 -run-tests-until-failure`（再試行なし）で確かめる（craft-verifier 2 の G3 の 3）。Mac で先に確かめるなら `-only-test-configuration ja_JP` と `-only-testing:YomutokiAcceptanceTests/ReadingScreenAcceptanceTests/test_AC60_resumeFailureKeepsPaused` など 3 本。

### 4.4 直したテスト

- なし。コードの読みだけで欠陥と言える所は見つからなかった。待ち時間を伸ばす、再試行する、期待を緩める、は していない。3.2 の診断の行の追加は合否を変えない。

## 5. tech-lead への依頼

Makefile の ios-test と CLAUDE.md の ios_test の行（commands.ios_test の中身）で、Acceptance の部分を置き換える。ios/ の中で動く点、その前後の `&&` は変えない。

- 置き換える前：
  `xcodebuild test -project Yomutoki.xcodeproj -scheme Yomutoki -testPlan Acceptance -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO`
- 置き換えた後：
  `bash AcceptanceTests/run-acceptance.sh 'iPhone 17'`
- 置き換えた後の ios_test の後半：`... && xcodebuild test -project Yomutoki.xcodeproj -scheme Yomutoki -testPlan Unit -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO && bash AcceptanceTests/run-acceptance.sh 'iPhone 17' && bash AcceptanceTests/ac18-reboot.sh 'iPhone 17'`
- あわせて CLAUDE.md の「決まり」の「ios/AcceptanceTests/ の target.yml、…、ac39-xcstrings.sh は verifier が書く」と、構成の表の ios/AcceptanceTests/ の行に run-acceptance.sh を足す。
- 終了コードは xcodebuild のものを返すので、`make ios-test` の失敗の扱いは今と同じ（0 本で成功のときだけ 65 に変わる）。
- 参考（Takuma だけが直せる所）：.github/workflows/ios.yml で `${TMPDIR}/acceptance/Acceptance.xcresult` と `Acceptance.log` を成果物として上げれば、要約の外の行（スクリーンショット、全部の要素の木）も取れる。

## 6. 未確認

- run-acceptance.sh は Xcode と本物の xcodebuild で未実行（bash -n、要約の python の手元のログへの当て、stub での流れだけ）。
- f の `xcresulttool get test-results summary` の JSON のキー（devicesAndConfigurations、testPlanConfiguration.configurationName、testFailures）は、この環境で確かめられない。違っていても「想定のキーがない」と出すだけで、合否は変えない。
- AcceptanceTestCase.swift の追加は未ビルド（Swift 6 の言語モード。キーパスを使わず、MainActor.assumeIsolated の中だけで XCUIApplication を触る形にした）。
- xcodebuild が計画の構成の順（ja_JP、en_US）に回すことは、en が後だったことからの推測。次の CI では [AT-DIAG] の構成の行（落ちたときだけ出る）で確かめる。
