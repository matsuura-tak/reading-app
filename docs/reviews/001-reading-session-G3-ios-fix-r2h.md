# ios-engineer 8体目の報告（001-reading-session G3：designer の文言キーをアプリに入れる）

## 結論
- BASE は ad13217（`git rev-parse --short HEAD` で確かめた）。コミットはしていません。
- 頼まれた1〜7は終わりました。
  - String Catalog を design/ 7 にそろえました。決定 82〜86 で足したキーを入れ、値の違うキーを直し、複数形は String Catalog の複数形の形で入れました。
  - 推薦の理由は、軸と「積読にある本か」の組ごとに1つのキーから作ります。
  - インテントの声に残っていた日本語の直書き2か所をなくしました。
  - S-4 は `.first` の形と専用の読み上げキーにし、仮の値「15分」をなくしました。
  - W-3 は `ended.summary`・`ended.spoken`、名無しの本の書名、「終える」のラベルをキーにそろえました。
  - S-2 と S-7 を design/ 7 どおりにしました。
  - 7（読み込み中の読み上げ `common.loading`）は前から入っていたので、変えていません。
- 8 は数えて一覧にし、小さい4件だけ直しました。
- 確かめた結果：
  - `make ios-build` は警告0、`swift test` は55件すべて通りました。
  - 受け入れテストは、ja が56件中55件通りました。落ちた1件は AC-99 で、前から落ちていたテストの不具合です。
  - en は13件落ちました。どれもテストが日本語を決め打ちしているもの（12件）か、同じ AC-99 です。アプリの不具合で落ちたものはありません。
  - Release の `nm`/`strings` で `UITestHook` は3つのバイナリとも0件です。
- 動かし直していないもの：en の受け入れテストのあとに、`ThemeTokens.swift` の言語の判定と en の文言をいくつか直しました。そのあと動かし直したのは、ビルドと英語の撮影だけです。ja・en の受け入れテストは動かし直していません（未解決2）。

## 変更したファイル
パスはすべて /Users/takumamatsuura/reading-app/ios/ の下です。

### 文言とパッケージの文
- `ReadingApp/Resources/Localizable.xcstrings`
  - design/ 7 のキーを29個足しました：`intent.start.noCurrent`、`intent.end.completed`、`result.summary.{pages,locations,percents}.first`、`result.summary.spoken`、`result.summary.first.spoken`、`liveActivity.ended.summary`、`liveActivity.ended.spoken`、`duration.hoursMinutes`、`duration.hours`、`next.reason.*`（6）、`rec.reason.*`（5）、`book.total`、`reading.startedAt`、`colophon.capture`（en "Scan Colophon"）。
  - 複数形（en の one/other）にしたキー：`duration.minutes.spoken`、`duration.hours.spoken`、`book.nights`。`duration.hoursMinutes.spoken` は substitutions で、時間と分をそれぞれ複数形にしました。
  - 値を design/ 7 に直したキーは37個です。
    - 知らせに使う17個：`session.tooShort`、`session.invalidTime`、`session.capped`、`session.start.error`（新しい文）、`session.save.error`、`common.save.error`、`store.load.error`、`book.title.invalid`、`book.author.invalid`、`mark.line.invalid`、`mark.page.invalid`、`record.minutes.invalid`、`store.unavailable`、`store.offline`、`store.purchase.error`、`store.restore.done`、`store.restore.none`。
    - コードから参照されていない20個（`toolbar.shelf`、`bookmark.empty.title` など）。
  - `duration.minutes` の注釈を「60分以上も分のまま」に直しました。
- `ReadingKit/Sources/ReadingCore/RecommendationReasonStrings.swift`（新規）
  - 推薦の理由の書式を11個持ちます（軸と「積読にある本か」の組ごとに1つ）。既定値は `.keys` で、パッケージの中に ja・en の文は持ちません。
  - `reason(axis:isOwnedTsundoku:name:)` は、賞やレーベルの名前が空なら nil を返し、その軸を使いません。
- `ReadingKit/Sources/ReadingCore/RecommendationEngine.swift`
  - `formatReason` は `String?` を返し、`strings` を受け取ります。
  - `awardDisplayName` を足しました。未所有の本では、前と同じく回や年を前に付けます（「第157回 直木三十五賞」）。
  - `nextCandidates`、`afterCandidates`、`noCurrentCandidates` に `reasonStrings` を足しました。
  - どの軸にも当たらない積読の本は `next.reason.tsundoku` にしました。「積読から」の直書きはなくなりました。
- `ReadingKit/Sources/ReadingCore/ReadingStoreStrings.swift`
  - 足した項目：`resultSummary*FirstFormat`、`intentStartNoCurrent`、`intentEndCompleted`、`liveActivityEndLabel`、`liveActivityEndedSummaryFormat`。どれも既定値はキーの名前です。
  - `resultSummary` は、前の場所がなければ `.first` を使います。書式から区切りを取り出す作りと、`currentDisplay` の引数は消しました。
  - `liveActivityEndedSummary` と、型 `SessionResultFigures` を足しました。
- `ReadingKit/Sources/ReadingCore/ContractModels.swift`：読み上げのために、Live Activity の `ContentState` に省略できる `minutes` を足しました。

### 店
- `ReadingKit/Sources/ReadingStore/ReadingDataStore.swift`
  - インテントの声の2つの文をキーに替えました。
  - `endButtonLabel` を `liveActivity.end.label` の文にしました。
  - Live Activity の書名は `liveActivityDisplayTitle` で決めます。隠す設定なら `widget.hidden`、名無しの本なら `widget.currentBookAsTitle` です。
  - 終えた直後の文をキーで組むようにしました。
  - `latestResultFigures` と `recommendationReasonStrings` を足しました。

### アプリ
- `ReadingApp/Intents/ReadingAppIntents.swift`：`ReadingStoreStrings.localized` に新しい項目を入れ、`RecommendationReasonStrings.localized` を足しました。
- `ReadingApp/Model/ReadingAppModel.swift`：推薦の理由の文を店に入れます。
- `ReadingApp/Shared/ReadingWidgetSurfaceViews.swift`
  - W-3 の終えた直後の読み上げは `liveActivity.ended.spoken` と `duration.minutes.spoken` で組みます。
  - `ReadingLiveActivityStateFactory.ended` の文は `duration.minutes` と `liveActivity.ended.summary` で組みます（`Duration.formatted` はやめました）。
  - `durationMinutes` と `durationMinutesSpoken` を足しました。
- `ReadingApp/Views/SessionResultAndGuideViews.swift`（S-4）
  - `?? "15分"` をなくしました。まとめがなければ出しません。
  - 読み上げは `spokenSummary`（`result.summary.spoken`、`.first.spoken`、`duration.minutes.spoken`）で組みます。`humanReadableSummary` は消しました。
  - 「記録しました。」の en を "Session saved." にしました（design/ 7 どおり）。
- `ReadingApp/Views/ReadingSessionView.swift`（S-2）
  - `reading.startedAt` の時刻を、システムの短い時刻の書式にしました。晩をまたいだときは、同じ `%@` に月日つきの時刻を入れます。
  - `reading.note` の en を design/ 7 どおりにしました。
- `ReadingApp/Views/ShelfAndBookDetailViews.swift`（S-7）
  - `book.nights`（複数形）と `book.total`（分のまま）にしました。読み上げの分数は `duration.minutes.spoken` です。
  - `colophon.capture` をキーで出すようにしました。
- `ReadingApp/Views/FinishNightView.swift`
  - `colophon.capture` をキーで出すようにしました。
  - 名無しの本の書名を `currentBookAsTitle` にしました（en は "Current Book" でした）。
  - `next.header` の en を "Your Next Book" にしました。
  - Preview の理由もキーから取るようにしました。
- `ReadingApp/Views/BannerNoticeView.swift`：`message(forKey:)` は `String(localized: String.LocalizationValue(key))` で引きます。`AppL10n.pick` の直書き17件をやめました。
- `ReadingApp/Theme/ThemeTokens.swift`
  - `AppL10n.isEnglish` は、`-AppleLanguages` の最後の引数を読むようにしました（Bundle の選び方に合わせるため）。
  - 引数が2つあるとき、String Catalog の文と `AppL10n` の文が同じ画面で別の言語になっていました。

### テストとノート
- `ReadingKit/Tests/ReadingCoreTests/RecommendationReasonStringsTests.swift`（新規）。確かめること：
  - 10通りの組の ja・en の文。
  - 名前が空（nil、""、空白）なら、その軸を使わないこと。
  - 賞の表示名。
  - 英語の文を渡すと、S-9・S-7・S-1 の候補の理由が英語になること。
  - レーベルが空の本どうしは、同じレーベルの軸に当たらないこと。
- `ReadingKit/Tests/ReadingStoreTests/ReadingStoreStringsTests.swift`
  - ja・en の写しに新しい項目を足し、`session.start.error` を新しい文にしました。
  - 足したテスト：`.first`、`liveActivityEndedSummary`、`SessionResultFigures`、今の本がないときの en の声。
- `ReadingKit/Tests/ReadingCoreTests/AwardsAndRecommendationTests.swift`：`formatReason` の新しい形に合わせました。期待値は変えていません。
- `docs/001-reading-session-implementation-notes.md`：「11. 8体目」を足しました。

## API の確認
| API | URL | 対応 OS | 最低対応 OS（iOS 26）以下か |
|---|---|---|---|
| `Date.FormatStyle`（`init(date:time:)`、`.dateTime.month().day().hour().minute()`、`timeZone`） | https://developer.apple.com/documentation/foundation/date/formatstyle | iOS 15.0+ | 以下 |
| `String.localizedStringWithFormat` / `NSLocalizedString`（複数形） | https://developer.apple.com/documentation/foundation/nsstring/localizedstringwithformat(_:_:) | iOS 2.0+ | 以下 |
| `String(localized: String.LocalizationValue)` | https://developer.apple.com/documentation/swift/string/init(localized:table:bundle:locale:comment:) | iOS 15.0+ | 以下 |

- 今回は URL を開いて確かめ直していません。3つとも iOS 26 の SDK でビルドが通っています。

## 画面の状態と識別子
- 画面の状態と識別子（`accessibilityIdentifier`）は、足していませんし変えていません。
- String Catalog は269キーです。ja と en がそろったキーが269、そろっていないキーは0です。
- design/ 7 との突き合わせ（両方にあるキー）
  - 値が違って見えるのは複数形の4キーだけです。複数形を別の形で持っているためで、文の違いではありません。
  - design/ 7 にあって catalog にないキーは153です（前は182）。これは、アプリが `AppL10n.pick` で出していて catalog を引かない文です。

## 実行したコマンドと結果
ログと結果は /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/r9/ にあります。

- **`make ios-build`**（build3.log。すべての変更のあとの最後の実行）
  - 終了コード0、`** BUILD SUCCEEDED **`、コンパイラーの warning は0です。
  - 前からある `appintentsmetadataprocessor` の1行（Metadata extraction skipped）が出ます。これはコンパイラーの warning ではありません。
- **`swift test --package-path ios/ReadingKit`**（swifttest2.log。ContractModels を変えたあとに動かし直した）
  - 終了コード0。ReadingStore 側は19件・2スイート、ReadingCore 側は36件・9スイートで、すべて通りました。warning は0です。
- **`xcodebuild build-for-testing -project ReadingApp.xcodeproj -scheme ReadingApp -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.0' -derivedDataPath …/r9/dd`**（bft.log、bft3.log）
  - `** TEST BUILD SUCCEEDED **`。製品のコードの warning は0で、warning は AcceptanceTests/ の中だけです。
- **ja の受け入れテスト**（`xcodebuild test-without-building … -only-test-configuration "Japanese (ja)"`。ja.log、ja.xcresult。runtests.sh）
  - 対象：FinishAndRecommendationAcceptanceTests（全部）、WidgetAndActivityAcceptanceTests（全部）、BookmarkAcceptanceTests の AC-75・AC-76・AC-141、SettingsStoreIntentsAcceptanceTests の AC-114〜AC-125・AC-133・AC-134・AC-143。
  - 56件中、通過55・失敗1・飛ばした0で、終了コードは65です。
  - 落ちたのは `WidgetAndActivityAcceptanceTests.swift:682`（AC-99、`XCTAssertTrue(widgetRaw.contains("羅生門"))`）です。前から落ちていたもので、`"\(dict)"` で文字列にすると日本語が書き換わるテストの読み方の不具合です（実装ノートの9）。
- **en の受け入れテスト**（同じ対象を `"English (en)"` で。en.log、en.xcresult）
  - 56件中、通過43・失敗13です。13件は、日本語を決め打ちしたテスト12件と AC-99 です（未解決1）。
- **英語の撮影**（`TEST_RUNNER_G3_CAPTURE=1 TEST_RUNNER_G3_VARIANT=en … -only-test-configuration "English (en)" -only-testing:ReadingAcceptanceTests/G3EvidenceCaptureTests/test_G3_captureNormalScreens`。capture2.log）
  - 1件、失敗0でした。
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/r9/shots-en/S4_normal_en.png
    - 「Tonight's Reading / p.61 → p.78  18 min / Session saved. / Close」で、すべて英語でした（目で確かめた）。
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/r9/shots-en/S9_normal_en.png
    - 理由「From your pile」、「Your Next Book」「Scan Colophon」「Share Finish Card」「Skip for Now」は英語でした。
    - 日本語が残っている所は、未解決3に書きました。
  - 補足：最初は ja の構成に en の引数を足して撮りました（…/r9/shots/）。その撮影で `AppL10n` の文だけが日本語になったので、`AppL10n.isEnglish` を直してから撮り直しました。
- **Release**（`xcodebuild -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath …/r9/dd-release SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build`。release.log）
  - `** BUILD SUCCEEDED **`。
  - ReadingApp、ReadingWidgetExtension、ReadingBackgroundAssetsExtension のどれも、`nm -a` の UITestHook が0、`strings -a` の UITestHook が0、uitest（大文字小文字を問わない）が0でした（pipeline.txt）。
- **4章の検査**（差分で足した行と、新しく作った2ファイルが対象）。次の検査はどれも0件でした：
  - 並行処理を黙らせる書き方
  - 古い書き方
  - 文字の大きさと色の直書き
  - `onTapGesture`
  - 強制アンラップ
  - `print`・`apiKey`・`secret`
  - URLSession・NWConnection・WKWebView
  - `try!`・`as!`
  - `Formatter()`・`.sorted`・`.filter`
  - UserDefaults など
  - TODO・mock・sample など
- **その他**
  - PrivacyInfo.xcprivacy は変えていません。理由の申告が要る API を新しく使っていないためです。
  - Instruments と Thread Sanitizer は動かしていません。画面の作りと並行処理を変えていないためです。
  - 差分の範囲：ios/ の中だけで、17ファイルを変え、2ファイルを足しました（SwiftPM が自動で拾う）。ios/AcceptanceTests/、contracts/、design/、docs/、pbxproj には触っていません。

## 未解決
1. **en で落ちる受け入れテスト（verifier に直してほしい。テストは直していません）**
   - どのテストも最初に落ちた所で止まるので、その先の行は動いていません。

   | ファイル | 行 | AC | 実際の値（en、design/ 7 の文） | テストが比べている値 |
   |---|---|---|---|---|
   | BookmarkAcceptanceTests.swift | 367 | AC-75 | "18 min" | "18分" |
   | BookmarkAcceptanceTests.swift | 386 | AC-76 | "p.43 → p.61  18 min" | 日本語 |
   | BookmarkAcceptanceTests.swift | 533 | AC-141 | "Loc 1200 → Loc 1450  18 min" | 日本語 |
   | FinishAndRecommendationAcceptanceTests.swift | 186 | AC-79 | "From your pile · Same author" | "積読から・同じ著者" |
   | FinishAndRecommendationAcceptanceTests.swift | 241 | AC-80 | 同上 | 同上 |
   | FinishAndRecommendationAcceptanceTests.swift | 492 | AC-87 | 同上 | 同上 |
   | FinishAndRecommendationAcceptanceTests.swift | 909 | AC-148 | "Read next by people who finished this book" | 日本語 |
   | SettingsStoreIntentsAcceptanceTests.swift | 926 | AC-120 | "Bookmark"（`widget.hidden` の en） | "しおり" |
   | SettingsStoreIntentsAcceptanceTests.swift | 942 | AC-121 | "From page 61." | 日本語 |
   | SettingsStoreIntentsAcceptanceTests.swift | 1011 | AC-123 | "From page 61." | 日本語 |
   | SettingsStoreIntentsAcceptanceTests.swift | 1052 | AC-125 | "From page 43." | 日本語 |
   | SettingsStoreIntentsAcceptanceTests.swift | 1225 | AC-143 | "From location 1450." | 日本語 |
   | WidgetAndActivityAcceptanceTests.swift | 682 | AC-99 | 前からの失敗（ja と同じ） | — |

   - まだ届いていないが、同じ理由で落ちるはずの行：FinishAndRecommendation の187〜188、242〜243、493〜494行、Bookmark の412、536、568行、SettingsStoreIntents の1246行。
   - `session.start.error` の古い文を全文で比べているテストは見つかりませんでした（「お試しください」などで grep して0件）。
2. **最後の変更のあとに動かし直していないもの**
   - 受け入れテストのあとに直したもの：`AppL10n.isEnglish` で最後の引数を読む、en の文言（"Session saved."、"Your Next Book"、reading.note の en）、S-9 の名無しの本の書名、コードが参照しない catalog の値20個。
   - このあと動かし直したのは、`make ios-build`、build-for-testing、英語の撮影だけです。
   - ja の文言は変えていませんが、ja・en の受け入れテストは動かし直していません。
3. **英語で日本語が残っている所（範囲の外。S-9 の en で見えた）**
   - FinishNightView.swift:38 `"\(nights)晩・\(mins)分"`。
   - ふりかえり（`model.store.buildFinishReflection`）。`finish.reflection.multi` で組み、時間に直す部分は `duration.hoursMinutes` を使う必要があります。
   - 出版社とレーベルの「（…）」：FinishNightView.swift:132、ShelfAndBookDetailViews.swift:395。`colophon.publisher.withLabel` で組むべき所です。
   - 「1927年」：FinishNightView.swift:153・212、ShelfAndBookDetailViews.swift:419。`colophon.year.value` で組むべき所です。
   - S-6 の見出し（ShelfAndBookDetailViews.swift:96、114）も design/ 7 と違います。
4. **8：`AppL10n.pick` と design/ 7 の突き合わせ**
   - 直書きの組は264個ありました。
     - 71個は design/ 7 と一致しました。
     - 41個は、キーはあるのに値が違いました。
     - 152個は、ja・en の文からキーを見つけられませんでした。
   - 値が違う例：
     - `toolbar.shelf` の en "Shelf"（design は "Bookshelf"）
     - `bookmark.finish`
     - `after.add*` の "Stack"（design は "Pile"）
     - `mark.navTitle` の en "Place Bookmark"（design は "Mark Your Place"）
     - `mark.screenshot`、`settings.*`、`appearance.*`
     - `scan.row.editTitle` の ja「書名を入力」（design は「書名を入れる」）
   - 直したのは4件です：`result.saved`、S-9 の `widget.currentBookAsTitle`、`next.header`、`reading.note`。
   - 一覧は …/scratchpad/r9/picks.py を動かすと出ます。
   - 全部をキーに移すのは別の作業になります。受け入れテストがラベルを比べている可能性があるので、verifier と合わせて進める必要があります。
5. **design/ に書いていないことを、自分で決めた所（designer に確かめてほしい）**
   - S-2 で晩をまたいだときは、`reading.startedAt` の `%@` に月日つきの時刻を入れました。
   - 未所有の本の賞の表示名に回を入れました（「第157回 直木三十五賞」。AC-79 のテストの期待値と同じ）。積読の本は賞の名前だけです。
   - `book.total` の読み上げは、分を読み上げの形にしました（"Total 85 minutes"）。見える文字は "Total 85 min" です。
6. **Mac・実機で確かめていないもの**
   - Dynamic Island。
   - 本物の Siri の声と、複数形（en の "1 minute" / "10 minutes"。`durationMinutesSpoken`）。
   - `make ios-test` の全体と、`make ios-test-perf`。
7. **残しているが画面には出ないもの**
   - `RecommendationEngine.afterCandidates` で、本が0冊のときに「コンビニ人間」を基準の本にする作り。範囲の外なので変えていませんが、仮の値に見えるので reviewer に見てほしいです。
   - H23 の読み込みの既定値「しおり」（ReadingDataStore.swift の2780行あたり）。テストの入力だけで使います。

## 記録（指揮役が保存するときに書き足す）
- 日付：2026-11-02。BASE ad13217。差分は ios/ の中だけ（ios/AcceptanceTests/ と pbxproj は変わっていない）。
- 指揮役の確かめ
  - scratchpad/r9/build3.log：`** BUILD SUCCEEDED **`、warning 0行。
  - ja.xcresult：通過55・失敗1（AC-99）。en.xcresult：通過43・失敗13（日本語の決め打ち12件と AC-99）。
  - scratchpad/r9/shots-en/S9_normal_en.png を見た。
    - 英語になった所：「Finished Reading」「Your Next Book」「From your pile」「Scan Colophon」など。
    - **見つけた不具合（報告にない）**：英語の設定で、日本語の文字が□（字形のない豆腐）で描かれている。対象は「3晩・83分」、ふりかえりの文、レーベルの「（…）」、「1927年」。
    - 英語の設定で日本語の字が描けないなら、英語の iPhone で日本語の本を読む人の書名・一行・著者も□になるおそれがある。
- 指揮役の裁定
  1. **豆腐（□）**：いちばん重い不具合として、ios-engineer の9体目が最初に直す。原因（英語のときに使うフォントが日本語の字を持たず、置き換えも効いていない、など）を突き止める。英語の設定で日本語の書名・一行・著者が正しく描けることを撮って示す。
  2. 未解決3・4（英語で日本語が残る所と、`AppL10n.pick` の値が design/ 7 と違う41件、キーの見つからない152件）：design-reviewer r2 が最後の回なので、G3 のうちに直す。9体目が、`AppL10n.pick` を design/ 7 のキーを通す形に移す。design/ 7 にない文は「未解決」に書いて designer に回す。
  3. 未解決1（en で落ちるテスト）：verifier r3 が言語ごとの値に直す。
  4. 未解決5（designer が書いていない所を自分で決めた3つ）：今の形を受け入れ、design-reviewer r2 に見てもらう。
  5. 未解決7（本が0冊のときに「コンビニ人間」を基準の本にする作り）：9体目が、画面に出るかを確かめる。出るなら直す。
