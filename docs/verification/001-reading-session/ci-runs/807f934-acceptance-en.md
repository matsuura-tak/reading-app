# CI 807f934 受け入れテスト（en_US の回）の仕分け

- 書いた役：verifier（2026-10-22）。判定ではなく、落ちたテストの仕分けと直しの記録。G2 の red（evidence/red.log）とは別。
- コミット：807f934（PR #2、ブランチ claude/cool-ptolemy-17gnb3）。CI：macos-latest、Xcode 26.6、シミュレーター iPhone 17 / iOS 26.5。
- 読んだログ：指揮役が取った en_US の回の 12:50:45Z 以降の 4999 行（ios-807f934.log。リポジトリの外）。**ja_JP の回のログは取れていない**（ツールの上限）。ja_JP の結果はこの文書に入っていない。
- この環境（Linux）には Xcode がない。下の「直した一覧」と「仕掛け」は**未ビルド・未実行**。次の CI で確かめる。

## 1. 集計

`Executed 80 tests, with 35 failures (0 unexpected)`（ログ 4904 行）。全クラスが `continueAfterFailure = false` なので、落ちたテスト1本に失敗は1件。35件 = 落ちたテスト35本。

| スイート | 本数 | 失敗 | ログ | 根拠（ログの行） |
|---|---|---|---|---|
| FinishInput | 10 | 9 | 9本はあり。AC-32 の1本は 12:50:45Z より前で、ログなし | 780 |
| LoadFailure | 2 | 0 | あり | 882 |
| AddBook | 4 | 1 | あり | 1232 |
| Library | 5 | 1 | あり | 1485 |
| TelemetryAndPrivacy | 6 | 6 | あり | 2164 |
| ReadingSession | 15 | 2 | あり | 3169 |
| BookStats | 5 | 0 | あり | 3368 |
| BookDetail | 13 | 5 | あり | 4151 |
| FinishSession | 7 | 1 | あり | 4902 |
| ReadingScreen | 13 | 10 | **なし**（12:50:45Z より前に走った。80 − 上の67 = 13、35 − 25 = 10 から求めた） | 4904 |
| 計 | 80 | 35 | error の行はログに24本 | |

AC18Reboot の2本は Acceptance.xctestplan の skippedTests（ac18-reboot.sh だけが使う）。4154 行の「Executed 0 tests」はそれ。

## 2. 主な原因（3つ）

### 原因A：T16 の送り方 `XCUIApplication.open(_:)` が、アプリを起動し直していた（テスト）

- 証拠：URL を開くたびに、ログに `Open com.example.yomutoki with URL readingapp-uitest://clock?advance=60` → `Launch com.example.yomutoki` → `Setting up automation session` → `Wait for com.example.yomutoki to idle` が出る（AC-45：ログ 410〜420 行前後、AC-6：2287〜2434 行）。これは起動の手順と同じ。
- AC-6 では、2回目の操作のあと `uitest.clock.applied` の label が「2」にならず「1」のまま（ログ 2432）。数は起動ごとに0から数えるので、起動し直したことと合う。
- 起動し直すと、launchEnvironment の UITEST_SEED と UITEST_RESET が入り直り、状態が seed に戻る。テストの中で作った状態（S5 を開いた、保存の失敗の区画が出た、ホームから読み始めた）が消える。
- seed に active を入れ、URL の前に画面で状態を変えないテスト（AC-7、AC-8、AC-13、AC-41 など）は、戻っても同じ状態なので通っていた。落ちたのは「画面で状態を変えた後に時計を進める」テストだけで、仕分けと合う。
- 直し：AppSession.sendClock を `XCUIDevice.shared.system.open(url)` に替え、確かめのダイアログが出たときだけ「開く」を押す（4 の表）。受け口（onOpenURL）、URL、`uitest.clock.applied` は契約どおりで変えていない。
- 契約との関係：contracts/test-hooks.md の T16 の備考は「XCUIApplication.open(_:)（A23、A55）で送り」と書いている。送り方の文を tech-lead が直す必要がある（5 の決めてほしいこと 2）。

### 原因B：欄を消して入れ直すヘルパー（UIHelpers.replaceText）が、右寄せの短い値を消せていなかった（テスト）

- 証拠：AC-47 で分の欄を「10」から「5」にしたら「510」になった（ログ 213）。カーソルが先頭にあり、消す文字が効かず、前に足された形。
- S5 の数字の欄は右寄せ（FinishSessionView.swift:151 `.multilineTextAlignment(.trailing)`）。前のヘルパーは欄の右から5%をタップしていた。値が1〜2字だと、そこは文字より左になり、カーソルが語の先頭に付いた［推測：タップの位置と字幅からの見立て］。
- AC-30 は「0」「181」「1」までは通り、「1」→「180」で誤りの文が消えなかった（ログ 4350）。「1」が消えず「1801」になったと見ると合う［推測］。

### 原因C：iOS 26 のツールバーのボタンの識別子が、種類 Other の要素に付いていた（テスト［推測］）

- 証拠：ログの `Check for interrupting elements affecting "book.save" Other`（10回）、`"session.finish.save" Other`（9回）、`"session.finish.cancel" Other`（7回）、`"book.add.cancel" Other`（2回）。ほかのボタン（home.startReading、error.retry など）は Button。
- AC-3 は空の題名（例 0、空文字）で book.save の isEnabled が true（ログ 1396）。AC-31 は総ページ 0 で誤りの文（book.add.totalPagesOutOfRange）は出たのに isEnabled が true（ログ 1154。:37 の Wait.label は通り、:41 で落ちた）。実装の `.disabled(!canSave || didSave)`（AddBookView.swift:66、:132）は Button に付くので、Other の isEnabled はそれを映さないと見た［推測：要素の木を見ていない。次の CI の [AT-DIAG] で確かめる］。

## 3. 仕分けの表（35本）

区分：テスト＝テスト側の欠陥（この場で直した）、実装＝実装側の欠陥の疑い（ios-engineer）、裁定＝指揮役の裁定待ち、不明＝ログがなく決められない（仕掛けを足した）。

| # | テスト名 | AC | 失敗の文言（ログの行） | 原因の見立て | 区分 | 直す役 | 根拠 |
|---|---|---|---|---|---|---|---|
| 1 | FinishInput.test_AC45_timeInFinishInputIsNotCounted | AC-45 | session.finish.save が出ない（448） | 原因A。S5 を開いた後の advance=60 で起動し直し、seed の reading に戻った | テスト | verifier（済） | ログ 410〜447、FinishInputAcceptanceTests.swift:120-122 |
| 2 | FinishInput.test_AC46_cancelFinishReturnsToReading | AC-46 | session.finish.cancel が出ない（552） | 原因A（advance=120） | テスト | verifier（済） | FinishInputAcceptanceTests.swift:137-141 |
| 3 | FinishInput.test_AC48_swipeDownDismissEqualsCancel | AC-48 | S5 のナビゲーションバーが出ない（142） | 原因A（advance=120） | テスト | verifier（済） | FinishInputAcceptanceTests.swift:185-190 |
| 4 | FinishInput.test_AC50_afterSaveShowsBookDetail | AC-50 | 前提：経過 10:00 の label が「要素なし」（283） | 原因A。ホームで読み始めた後の advance=600 で起動し直し、seed の idle（S1）に戻った | テスト | verifier（済） | FinishInputAcceptanceTests.swift:209-212 |
| 5 | FinishInput.test_AC64_cancelFinishFailureKeepsInput | AC-64 | 60秒後：error.saveFailed が「要素なし」（38） | 原因A。失敗の区画は一度出た（:239 は通った）が、advance=60 で起動し直して消えた | テスト | verifier（済） | ログ 1〜38、FinishInputAcceptanceTests.swift:239-250 |
| 6 | FinishInput.test_AC65_cancelFinishRetryReturnsToReading | AC-65 | error.retry が出ない（776） | 原因A（#5 と同じ前半） | テスト | verifier（済） | FinishInputAcceptanceTests.swift:241、:266 |
| 7 | FinishInput.test_AC47_cancelFinishResetsMinutesDraft | AC-47 | "510" ≠ "5"（213） | 原因B | テスト | verifier（済） | FinishInputAcceptanceTests.swift:163-164、FinishSessionView.swift:151 |
| 8 | FinishInput.test_AC35_retryAfterOneFailureAddsExactlyOne | AC-35 | 再試行の後の本の詳細：book.title が「要素なし」（361） | 失敗の区画は出て（:97 は通った）、error.retry（Button）は押せた（ログ 330 前後の Synthesize event）。時計の URL は使っていない。再試行の保存が通らなかった疑い（rollback の後の2回目の save）［推測］ | 実装（疑い） | ios-engineer | ログ 286〜361、LibraryStore.swift:308-336、:383-393、FinishSessionView.swift:167-174 |
| 9 | FinishInput.test_AC32_pageAbove9999IsRejectedWithoutTotalPages | AC-32 | ログなし（FinishInput は10本で失敗9。ログにある error は8本） | 「10000」→「9999」の入れ直しで原因B が起きた可能性［推測］ | 不明 | 次の CI の [AT-DIAG] で決める | ログ 780、FinishInputAcceptanceTests.swift:46-58 |
| 10 | ReadingSession.test_AC6_pausedTimeIsNotCounted | AC-6 | advance=60 が効いた：label が「2」でなく「1」（2432） | 原因A。2回目の URL で起動し直し、数が1に戻った | テスト | verifier（済） | ログ 2300〜2432、ReadingSessionAcceptanceTests.swift:60-63 |
| 11 | ReadingSession.test_AC5_previousBookStartsFromHomeInOneTap | AC-5 | 3秒後の経過が「要素なし」（2690） | 原因A。ホームで読み始めた後の advance=3 | テスト | verifier（済） | ReadingSessionAcceptanceTests.swift:19-27 |
| 12 | BookDetail.test_AC51_tooShortShowsNoticeOnBookDetail | AC-51 | 前提：経過 0:59 が「要素なし」（4147） | 原因A（advance=59） | テスト | verifier（済） | BookDetailAcceptanceTests.swift:144-147 |
| 13 | BookDetail.test_AC57_startRetryFromHomeStartsAtRetryTime | AC-57 | error.retry が出ない（3749） | 原因A。読み始めの失敗の後の advance=60 | テスト | verifier（済） | BookDetailAcceptanceTests.swift:281-282 |
| 14 | BookDetail.test_AC57_startRetryFromBookDetailStartsAtRetryTime | AC-57 | error.retry が出ない（3530） | 原因A | テスト | verifier（済） | 同上（:287） |
| 15 | BookDetail.test_AC56_startFailureFromHomeKeepsIdle | AC-56 | session.state.idle が2個（3436） | 根の入れ物の識別子と、代わりの案の 1pt の要素の両方が見えた。裁定 (a) の「根が見えるか」は「見える」 | 裁定 | 指揮役 → ios-engineer か pdm | RootView.swift:115-117、:121-129、PRD AC-56 の Then「session.state.idle が1個」、design 6 の (a)「テストは exists で見る決まりのまま」 |
| 16 | BookDetail.test_AC56_startFailureFromBookDetailKeepsIdle | AC-56 | 同上（4077） | 同上 | 裁定 | 同上 | 同上 |
| 17 | Library.test_AC3_blankTitleCannotBeSaved | AC-3 | 空白の例 0（空文字）：book.save は無効 が偽（1396） | 原因C | テスト［推測］ | verifier（済） | LibraryAcceptanceTests.swift:76-78、AddBookView.swift:66、:132 |
| 18 | AddBook.test_AC31_totalPagesOutsideOneTo9999AreRejected | AC-31 | 0：book.save の isEnabled が false にならない（1154） | 原因C | テスト［推測］ | verifier（済） | AddBookAcceptanceTests.swift:37-41 |
| 19 | FinishSession.test_AC30_minutesOutsideOneToElapsedAreRejected | AC-30 | 180分では誤りの文が消えない（4350） | 原因B | テスト［推測］ | verifier（済） | FinishSessionAcceptanceTests.swift:167-172 |
| 20 | TelemetryAndPrivacy.test_AC20_allOperationsWorkWhenTelemetryIsUnreachable | AC-20 | reading.finish が出ない（1678） | 原因A。S3 で読み始めた後の advance=300 で、UITEST_RESET=1 が入り直り本が0冊に戻った | テスト | verifier（済） | TelemetryAndPrivacyAcceptanceTests.swift:39-50、AppSession.swift の LaunchConfig.fresh |
| 21 | TelemetryAndPrivacy.test_AC20_allOperationsWorkWhenTelemetryHangs | AC-20 | 同上（1798） | 原因A | テスト | verifier（済） | 同上 |
| 22 | TelemetryAndPrivacy.test_AC20_allOperationsWorkWhenTelemetryReturns500 | AC-20 | 同上（2039） | 原因A | テスト | verifier（済） | 同上 |
| 23 | TelemetryAndPrivacy.test_AC21_noPermissionPromptsDuringFirstSession | AC-21 | 同上（1923） | 原因A（advance=300） | テスト | verifier（済） | TelemetryAndPrivacyAcceptanceTests.swift:105 |
| 24 | TelemetryAndPrivacy.test_AC23_telemetryHasNoTitleOrPageValues | AC-23 | 同上（2156） | 原因A（advance=300） | テスト | verifier（済） | TelemetryAndPrivacyAcceptanceTests.swift:128 |
| 25 | TelemetryAndPrivacy.test_AC24_weekReachedIsSentOncePerWeek | AC-24 | 同上（1560） | 原因A（advance=900） | テスト | verifier（済） | TelemetryAndPrivacyAcceptanceTests.swift:205 |
| 26 | ReadingScreen.test_AC58_pauseFailureKeepsReading | AC-58 | ログなし | 原因A［推測］。failPause で失敗の区画を出した後に advance=60（:87） | テスト［推測］ | verifier（済） | ReadingScreenAcceptanceTests.swift:81-96 |
| 27 | ReadingScreen.test_AC59_pauseRetryStopsAtRetryTime | AC-59 | ログなし | 原因A［推測］（failPause の advance=60 の後に error.retry） | テスト［推測］ | verifier（済） | ReadingScreenAcceptanceTests.swift:106-110 |
| 28 | ReadingScreen.test_AC60_resumeFailureKeepsPaused | AC-60 | ログなし | 原因A［推測］（failResume の advance=60、:128） | テスト［推測］ | verifier（済） | ReadingScreenAcceptanceTests.swift:122-136 |
| 29 | ReadingScreen.test_AC61_resumeRetryStartsAtRetryTime | AC-61 | ログなし | 原因A［推測］ | テスト［推測］ | verifier（済） | ReadingScreenAcceptanceTests.swift:146-150 |
| 30 | ReadingScreen.test_AC62_beginFinishFailureWhileReading | AC-62 | ログなし | 原因A［推測］（failBeginFinish の advance=60、:169） | テスト［推測］ | verifier（済） | ReadingScreenAcceptanceTests.swift:162-194 |
| 31 | ReadingScreen.test_AC62_beginFinishFailureWhilePaused | AC-62 | ログなし | 原因A［推測］ | テスト［推測］ | verifier（済） | 同上（:200） |
| 32 | ReadingScreen.test_AC63_beginFinishRetryWhileReading | AC-63 | ログなし | 原因A［推測］ | テスト［推測］ | verifier（済） | ReadingScreenAcceptanceTests.swift:207-223 |
| 33 | ReadingScreen.test_AC63_beginFinishRetryWhilePaused | AC-63 | ログなし | 原因A［推測］ | テスト［推測］ | verifier（済） | 同上（:229） |
| 34 | ReadingScreen.test_AC66_discardFailureKeepsReading | AC-66 | ログなし | 原因A［推測］（failDiscard の advance=10、:244） | テスト［推測］ | verifier（済） | ReadingScreenAcceptanceTests.swift:237-253 |
| 35 | ReadingScreen.test_AC67_discardRetryShowsNoticeWithoutRecord | AC-67 | ログなし | 原因A［推測］ | テスト［推測］ | verifier（済） | ReadingScreenAcceptanceTests.swift:266-268 |

ReadingScreen の13本のうち、時計の URL を「画面で状態を変えた後」に送るのはちょうど上の10本（AC-33、AC-40、AC-41 の3本は seed のままなので起動し直しても同じ）。失敗の数10と合うので原因A と見たが、ログがないので［推測］。

区分の集計：**テスト 31**（原因A 27＝ログあり17、ログなしの［推測］10。原因B 2。原因C 2［推測］）、**実装（疑い）1**（AC-35）、**裁定 2**（AC-56）、**不明 1**（AC-32）、仕掛け不足 0（仕掛けは全部のテストに足した）。31 + 1 + 2 + 1 = 35。

## 4. 直した一覧（ios/AcceptanceTests/ の中だけ。未ビルド）

| ファイル | 直した所 | 理由 | AC |
|---|---|---|---|
| Support/AppSession.swift | sendClock：`app.open(url)` を `XCUIDevice.shared.system.open(url)` に。2秒で効かなければ springboard の「開く」「Open」を探して押す（confirmOpenIfAsked、新規）。待つ値は今までどおり「起動してからの操作の数」 | 原因A。2回目からの操作で起動し直しが起きれば、ここの Wait.label で「1」と出て分かる | AC-5、6、20、21、23、24、45〜48、50、51、57〜67 |
| Support/AppSession.swift | shot：AcceptanceTestCase なら最後のスクリーンショットの名前と枚数を覚える | 3 の仕掛け | 全部 |
| Support/L10n.swift | systemOpenLabels（「開く」「Open」）を足した | システムの確かめのダイアログの文字（design 6 の (b)） | 同上 |
| Support/UIHelpers.swift | replaceText：右端（99%）をタップ → 消す → 残れば右端をダブルタップして消す → 空になったこと、入れた後の値が text であることを「前提」で確かめる。placeholder は空とみなす（typedText、新規） | 原因B。消せないときは AC の失敗ではなく前提の失敗として出す | AC-30、AC-47（ほか replaceText を使う AC-9、11、12、29、31、32、34、46、48、64、65） |
| Support/UIHelpers.swift | control(id)（新規）：識別子の付いた Button、なければ識別子の要素の中の Button、なければ識別子の要素 | 原因C | AC-3、AC-30、AC-31 ほか |
| Tests/LibraryAcceptanceTests.swift:76-78 | book.save の isEnabled を `s.control("book.save")` で見る | 原因C | AC-3 |
| Tests/AddBookAcceptanceTests.swift:28-42 | Wait.enabled の対象を `s.control("book.save")` に（3か所） | 原因C | AC-31 |
| Tests/FinishSessionAcceptanceTests.swift:75-76、:173 | session.finish.save の isEnabled を `s.control(...)` で見る | 原因C（有効を見る側。Other のままだと無効でも通ってしまう） | AC-11、AC-30 |
| Tests/*.swift（11クラス） | 親を XCTestCase から AcceptanceTestCase に | 3 の仕掛け | 全部 |

期待する値、AC 番号、識別子の名前、待ち時間の定数は変えていない。AC-56 の「1個」は裁定待ちなので変えていない。飛ばし、再試行、期待の緩めはない。

## 5. 足した仕掛け

- Support/AcceptanceTestCase.swift（新規）：`tearDownWithError` で `testRun?.hasSucceeded == false` のときだけ、行頭が `[AT-DIAG]` の行を標準出力に出す。中身は、落ちたテストの名前、直前の AppSession.shot の有無（枚数と最後の名前）、アプリの状態、`XCUIApplication().debugDescription` の先頭200行（上限は `diagnosticLineLimit`）。落ちた直後の画面の PNG を `FAIL_<テスト名>` の名で添付する（keepAlways）。合否は変えない。
- AppSession.confirmOpenIfAsked：システムのダイアログを押したときに `[AT-DIAG] T16：…` を出す（T16 の備考の「確認のダイアログが出るか」の答えになる）。
- 次の CI で見る：`grep -n '\[AT-DIAG\]' <ログ>`。

## 6. ios-engineer へ（この節だけで直せるように）

### AC-35：記録の保存が1回失敗した後の再試行で、本の詳細に移らない
- 期待（PRD AC-35）：UITEST_FAIL=session_finish:1、記録2件、経過10:00 の finishing。保存 → 失敗の区画 → error.retry を1回 → S5 が閉じて「坊っちゃん」の S3、「記録 3件」、状態 idle、error.saveFailed は0個。
- 実際（CI 807f934、ログ 286〜361）：失敗の区画（error.saveFailed の label「Couldn't Save Changes」、error.retry）は出た。error.retry（Button）を押した後、10秒たっても book.title がない。時計の URL は使っていないので原因A ではない。
- 疑い［推測］：1回目の失敗で `LibraryStore.commit` が `context.rollback()`（LibraryStore.swift:388）した後の、2回目の `finishSession`（:308-336）。1回目で insert した ReadingSession、`session.book = book`、`context.delete(model)`（activeModel）が rollback で戻り切らず、2回目の `context.save()` が本当に失敗して `finishFailure = .save` のまま、という形を疑う。ほかに、rollback の後の `activeModel` の参照が使えない、`book.sessions` の配列に捨てた記録が残る、も同じ所。
- 確かめ方：(1) 単体テストで、FailureInjector に `.sessionFinish: .times(1)` を入れ、finishing を作って `finishSession` を2回呼ぶ。1回目は `StoreError.saveFailed`、2回目は通り、記録が1件だけ増え、`active` が nil。もう一度保存先を開き直しても同じ。(2) シミュレーターのログ（LibraryStore.swift:389 の Logger）で `save failed: session_finish` が2回出ていないか。(3) 次の CI の `[AT-DIAG]` の要素の木で、再試行の後に error.saveFailed が残っているか。
- 同じ形の再試行（AC-57、59、61、63、65、67：読み始め、一時停止、再開、終える、やめる、60秒未満で終える）は原因A で隠れていた。直すなら rollback の後の2回目の保存を、操作ごとに単体テストで確かめてほしい。

### AC-56（指揮役の裁定が「実装」のときだけ）
- 期待（PRD AC-56 の Then）：`session.state.idle` が1個。
- 実際：2個（ログ 3436、4077）。根の入れ物（RootView.swift:116-117 の `.accessibilityElement(children: .contain)` と識別子）と、代わりの案の 1pt の要素（RootView.swift:115、:121-129）の両方。
- 直す所：代わりの案の 1pt の要素（RootView.swift:115、:121-129。FinishSessionView.swift:100、:192-200 と、それを渡す ReadingView.swift:216、RootView.swift:101 の showsStateMarker）を外す。先に次の CI の `[AT-DIAG]` の要素の木で、S4 と S5 でも根の識別子が見えていることを確かめてから外す。
- 確かめ方：AC-56 の2本で count が1、ほかの expectState を使う全テストが通る。

## 7. 指揮役に決めてほしいこと

1. AC-56：推奨は「実装（1pt の要素を外す）」。PRD の Then が「1個」で、CI で根の識別子が見えた（裁定 (a) は「見える」）ので代わりの案は要らない。反論：根が見えたのは S1 と S3 だけで確かめた。S4、S5 で根が見えないと、外すと expectState を使う多くのテストが落ちる（次の CI の要素の木を見てから外せば避けられる）。
2. T16 の送り方：推奨は、テストの直し（XCUIDevice.system.open）を受け、tech-lead に contracts/test-hooks.md の T16 の備考の「XCUIApplication.open(_:)（A23、A55）で送り」を直してもらう。反論：契約の文と食い違ったまま次の CI を回すことになる。system.open でもダイアログを押せない、または起動し直すなら、契約の代わりの案（-UITest のときだけの uitest.clock.advance.<秒> のボタン。ios-engineer と tech-lead）に替える。
3. T6 → T22：推奨は「今は替えない」。TelemetryAndPrivacy の6本は、受け口に届く前に原因A で本が0冊に戻って落ちており、localhost に届かない証拠はない。反論：次の CI で届かなかったら、もう1回 CI を待つことになる（70〜135分）。
4. ja_JP の回のログ：次の CI では `gh run view --log` を `[AT-DIAG]|error:|Executed|Test Case .* failed` で絞って取り、en_US と ja_JP の両方を見たい。

## 8. 未確認と未着手

- 未ビルド、未実行（この環境に Xcode がない）。Swift 6 の言語モード（target.yml の SWIFT_VERSION 6.0）で、AcceptanceTestCase の `MainActor.assumeIsolated` と、`XCUIDevice.shared.system.open(_:)`（iOS 16.4 以上）、`XCTAttachment(data:uniformTypeIdentifier:)` を読んで確かめただけ。
- `XCUIDevice.system.open` で、動いているアプリが起動し直さないか、確かめのダイアログが出るか、は未確認（次の CI）。
- 原因C の「Other の isEnabled は .disabled を映さない」と、control(id) が中の Button を見つけられるかは未確認［推測］。
- ReadingScreen の10本と AC-32 はログがなく、見立ては［推測］。
- ja_JP の回は見ていない。
- evidence/red.log と test-plan.md には触っていない。
