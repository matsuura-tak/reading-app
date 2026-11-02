# ios-engineer 7体目の報告（001-reading-session G3：英語の設定で日本語が出る所）

## 結論
- BASE は 76ff911（`git rev-parse --short HEAD` で確かめた）。コミットはしていません。
- 直したもの：
  - Siri・ショートカットの答え（`spokenText` / `snippetTexts`）
  - `InputValidator.formatProgressDisplay` の「位置」
  - S-4 の `result.summary` と W-3 の終えた直後の「分」
- この3つは、design/ 7 のキーで、その時の言語の文になります。
- `make ios-build` は警告0、`swift test` は全件通りました。
- 受け入れテスト14件の結果：
  - ja：全件通りました。
  - en：7件が落ちます。どれもテストが日本語の値を決め打ちしているためです。実際に出た値は design/ 7 の英語の文でした（下の「未解決」1）。
- まだ日本語のまま残っているもの：
  - `intent.start.noCurrent` と `intent.end.completed` の2つの文。design/ 7 にキーがないので、前の文のままです。
  - 推薦の理由の文。指示の範囲の外で、新しく見つけたものです。どちらも「未解決」に書きました。

## 変更したファイル
- `ios/ReadingKit/Sources/ReadingCore/ReadingStoreStrings.swift`（新規）
  - ReadingStore が組む文を、アプリから受け取るための型です。中身は `intent.*`、`session.start.error`、`session.tooShort`、`session.save.error`、`duration.minutes`、`result.summary.*` です。
  - パッケージの中には ja・en の文を持ちません。既定値は `.keys`（キーの名前そのもの）なので、渡し忘れると見て分かります。
  - `whereStopped(unit:value:)`、`durationMinutes(_:)`、`resultSummary(unit:previous:current:currentDisplay:minutes:)` を持たせました。
- `ios/ReadingKit/Sources/ReadingCore/Models.swift`
  - `formatProgressDisplay` に `strings: WidgetSpokenStrings` を足しました。
  - `page.short`、`location.short`、`percent.short` の書式で組みます。英語では `Loc 1450` になります。
- `ios/ReadingKit/Sources/ReadingStore/ReadingDataStore.swift`
  - `storeStrings` を足しました（587行）。
  - `handleExternalIntent` の11種類の文を `storeStrings` に替えました（3069〜3286行）。
  - `latestResultSummary` を直しました（2177、2208、2353〜2361行）。
  - Live Activity の `summaryText` は「分数 · 場所」の形にしました（2865行）。拡張の `ReadingLiveActivityStateFactory.ended` と同じ形です。
  - 店の中の `formatProgressDisplay` には `snapshotStore.spokenStrings` を渡します。
- `ios/ReadingApp/Intents/ReadingAppIntents.swift`
  - `ReadingStoreStrings.localized` を足しました（10行）。String Catalog から組み、アプリと拡張の両方のターゲットに入ります。
  - インテントが自分で作る店（46、71、140行）に、`storeStrings` と `snapshotStore.spokenStrings` を入れるようにしました。
- `ios/ReadingApp/Model/ReadingAppModel.swift`：73行で `storeStrings` を入れます。
- `ios/ReadingApp/Views/BookmarkHomeView.swift`、`ShelfAndBookDetailViews.swift`、`SettingsAndStoreViews.swift`（S-10a の `previewPage`）
  - `formatProgressDisplay` に `ReadingWidgetStrings.spoken` を渡すようにしました。
- `ios/ReadingApp/Views/SessionResultAndGuideViews.swift`
  - `guideSnapshot(line:)` と `lockWidgetPreview(line:)` から、使われない `progress` の引数を消しました。
  - それで使われなくなった `samplePage` も消しました。
- `ios/ReadingApp/Resources/Localizable.xcstrings`
  - design/ 7 にあるキーを6つ足しました：`intent.start.started`、`intent.start.alreadyReading`、`duration.minutes`、`result.summary.pages`、`result.summary.locations`、`result.summary.percents`。
  - 値は design の文字どおりです（ja は全角の空白、en は空白2つ）。
- `ios/ReadingKit/Tests/ReadingStoreTests/ReadingStoreStringsTests.swift`（新規）
  - テスト用の ja・en の写しを置きました。
  - テストの中身：「どこまで読んだ？」の答え（3件）、`result.summary` の8つの形、`formatProgressDisplay` の英語、店が英語で答えて書名と一行を含まないこと。
- `ios/ReadingKit/Tests/ReadingStoreTests/ReadingStoreTests.swift`：前からある2つの店に `.testJapanese` を入れました（期待値は変えていません）。
- `ios/docs/001-reading-session-implementation-notes.md`：「10. 7体目」の節を足しました。

## API の確認
- 新しく使った Apple の API はありません。`String(localized:)` と `String(format:locale:)` は、前から使っているものです。

## 画面の状態と識別子
- 画面の状態と、識別子（accessibilityIdentifier）は足していませんし、変えていません。
- String Catalog は240キーで、ja と en がそろったキーが240、そろっていないキーは0です。

## 実行したコマンドと結果
ログと結果のファイルは /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/r8/ にあります。
- **`swift test --package-path ios/ReadingKit`**（swifttest.log）
  - 終了コード0。ReadingStore 側は16件・2スイート、ReadingCore 側は31件・8スイートで、どちらも全件通りました。warning は0です。
- **`make ios-build`**（build.log）
  - 終了コード0、`** BUILD SUCCEEDED **`。コンパイラーの warning は0行です。
  - 前からある `appintentsmetadataprocessor` の1行（Metadata extraction skipped）が出ますが、これはコンパイラーの warning ではありません。
- **`xcodebuild build-for-testing -project ios/ReadingApp.xcodeproj -scheme ReadingApp -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.0'`**（bft.log）
  - `** TEST BUILD SUCCEEDED **`。製品のコードの warning は0です。
  - warning は ios/AcceptanceTests/ の中だけに42行あり、どれも前からあるものです。
  - 補足：最初は `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES` を付けて動かし、受け入れテストの warning がエラーになって終了コード65で止まりました。`make ios-test` と同じく、この指定を外して動かし直しました。
- **en**（`xcodebuild test-without-building … -only-test-configuration "English (en)"`。`-only-testing` は AC-121、AC-122、AC-123、AC-133、AC-134、AC-143、AC-114、AC-115、AC-119、AC-120、AC-125、AC-75、AC-76、AC-141 の14件。en.log と en.xcresult）
  - 7件通りました：AC-114、AC-115、AC-119、AC-120、AC-122、AC-133、AC-134。
  - 7件落ちました：AC-121、AC-123、AC-125、AC-143、AC-75、AC-76、AC-141。
  - 落ちた理由は、どれも H の読み出しに英語の値が出て、テストが日本語の値と比べているためです。読み出しに出た値：
    - `spokenText`：`From page 61.`、`From page 43.`、`From location 1450.`
    - `result.summary`：`18 min`、`p.43 → p.61  18 min`、`Loc 1200 → Loc 1450  18 min`
  - ログの最初のエラー：`SettingsStoreIntentsAcceptanceTests.swift:942: XCTAssertEqual failed: ("From page 61.") is not equal to ("61ページからです。")`
- **ja**（同じ14件を `-only-test-configuration "Japanese (ja)"` で。ja.log と ja.xcresult）
  - 終了コード0、`Executed 14 tests, with 0 failures`、`** TEST EXECUTE SUCCEEDED **`。
- **Release**（`xcodebuild -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath <scratchpad>/r8/dd-release SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build`、release.log）
  - `** BUILD SUCCEEDED **`、コンパイラーの warning は0です。
  - ReadingApp、ReadingWidgetExtension、ReadingBackgroundAssetsExtension のどれも、`nm -a` の UITestHook が0、`strings -a` の UITestHook が0、uitest（大文字小文字を問わない）が0でした。
- **4章の検査**（差分で足した行と、新しく作った2ファイルが対象）
  - 次の検査は、どれも0件でした：並行処理を黙らせる書き方、古い書き方、文字の大きさと色の直書き、onTapGesture、強制アンラップ、`print(`・apiKey・secret、URLSession・NWConnection・WKWebView、try!・as!、UserDefaults など。
  - 「動いたふり」の検査（TODO、mock、sample など）は2件あり、どちらも名前の一部が当たっただけです。前からある変数 `sampleLine` と、その説明文です。
  - PrivacyInfo.xcprivacy は変えていません。理由の申告が要る API を新しく使っていないためです。
  - Instruments と Thread Sanitizer は動かしていません（画面の作りと並行処理は変えていないため）。
- **差分の範囲**
  - `git status` で、ios/ の中だけが変わっていることを確かめました。11ファイルを変え、2ファイルを足しました。
  - ios/AcceptanceTests/、contracts/、design/、docs/、pbxproj には触っていません。

### 直したあとの日本語の直書きの残り（コメントを除く）
- `ReadingDataStore.swift` の24件：
  - 5件は H9 のテスト用の本（1034〜1042行）。
  - 7件は Live Activity の「しおり」「終える」です。描かれるかどうかは下の4を見てください。
  - 4件は、design/ 7 にキーがない2つの答えです（3085、3144行。それぞれ spoken と snippet）。
  - 2件は `recordShareCard` の既定値の「晩」「分」です。`renderedTexts` が空の時に hook の `shareCards` に記録するだけで、画面には出ません。
  - 6件はショートカットの言い方です。
- `CatalogDatabase.swift` の6件：H20 の書誌と出典の文です。
- ReadingCore の照合用の文字：AuthorNameFormatter、AwardsCatalog、OCRPipeline、VerticalLineLayout、Models.swift:231（負の数の印）、WidgetComposition の基準の字。
- `ContractModels` の賞の名前：データです。
- `WidgetSpokenStrings.japanese`：前からある写しです。
- `ISBNAndCCodeParser.nonBookGuidanceMessage`：アプリから参照されていないので、画面には出ません。
- `NightDateCalculator`：ja と en の両方の文を持っていて、`japaneseText` / `englishText` の形です。
- `RecommendationEngine.formatReason` の20件：画面に出ます（「未解決」4）。

### 指示の3と4で確かめたこと
- 3（「分」「晩」）
  - `latestResultSummary` は、S-4 の `result.summary` として画面に出ていました。直しました。
  - Live Activity の `summaryText` は、`ReadingLiveActivityLockScreenView` の ended で描かれていました。直しました。
  - 3331〜3332行の「晩」「分」は、画面には出ません。
- 4（「しおり」「終える」）
  - 隠す設定のときの「しおり」は、描く側が `widget.hidden` に置き換えるので出ません。
  - ただし、書名が空の名無しの今の本で隠す設定がオフのときは、本物の Live Activity に「しおり」がそのまま出ます（2019、2818、2894行）。
  - 「終える」（`endButtonLabel`）は hook にだけ入り、描く側は `liveActivity.end.label` を使うので出ません。

## 未解決
1. **en で落ちる受け入れテスト（verifier に直してほしい。テストは直していません）**
   - `SettingsStoreIntentsAcceptanceTests.swift`
     - 942行（AC-121）：`"61ページからです。"`
     - 1011行（AC-123）：`"61ページからです。"`
     - 1052行（AC-125）：`"43ページからです。"`
     - 1225行（AC-143）：`"位置1450からです。"`
     - 1246行（AC-143 の％）：`"52パーセントからです。"`。1225行で止まるので、ここまでは届いていません。
   - `BookmarkAcceptanceTests.swift`
     - 367行（AC-75）：`"18分"`
     - 386行（AC-76）：`"p.43 → p.61　18分"`
     - 412行：`contains("18分")`
     - 533行（AC-141）：`"位置1200 → 位置1450　18分"`
     - 536行（前からの `位置1450`）
     - 568行（AC-141）：`"34% → 52%　18分"`
   - en の正しい値は design/ 7 の en の文です。
2. **design/ 7 にキーがない文（designer に決めてほしい）**
   - 「読み始める」で今の本がないとき：今は「いま読んでいる本がありません。」です。アプリは開きます。
   - Live Activity の「終える」で保存できたとき：今は「読書を終えました。」です。
   - どちらも、キーが決まるまでは日本語のままです。
   - もう1つ、S-4 で前の場所がない晩の「p.61　18分」の形にもキーがありません。今は `result.summary.*` の区切りを流用しています。
3. **String Catalog の値が design/ 7 と違うキー（直していません）**
   - `session.start.error`、`session.save.error`、`session.tooShort`、`session.capped` は、前から design の文と違っています。例：catalog は「読書を始められませんでした。もう一度お試しください。」、design は「読み始めを保存できませんでした。もう一度「読み始める」を押してください。」。
   - 今回、インテントの答えもこのキーを通すようになったので、目立ちます。値をそろえるかを決めてほしいです。受け入れテストが画面の文を比べているかは、確かめていません。
4. **英語で日本語が出る所を、新しく見つけました（範囲の外なので直していません）**
   - `RecommendationEngine.formatReason`（「積読から・同じ著者」など）が S-9 と S-7 の `next.reason` に出ます。
   - S-4 の読み上げのラベル `humanReadableSummary` は、「p.」を「ページ」に置き換えています。design/ 7 に、読み上げ用のキーはありません。
   - S-4 の `latestResultSummary ?? "15分"`（SessionResultAndGuideViews.swift:22）は、仮の値が出る作りです。
   - 名無しの今の本の Live Activity の書名が「しおり」になります。契約では `widget.currentBookAsTitle` です。
   - `endButtonLabel` の値「終える」は、契約の `liveActivity.end.label` の文と違います。
5. **`duration.minutes` は design で「60分未満」とされています。**
   - S-4 と W-3 では、60分以上も `%lld分` のままにしました。前と同じ振る舞いで、AC-57 の1440分のためです。
   - `duration.hoursMinutes` を使うべきかは、designer に決めてほしいです。
6. **Mac で動かしていないもの**
   - `make ios-test` の全体と `make ios-test-perf`。
   - 本物の Siri の声と小窓。今回は H の読み出しと単体テストで確かめました。

## 記録（指揮役が保存するときに書き足す）
- 日付：2026-11-02。BASE 76ff911。差分は ios/ の中だけ（ios/AcceptanceTests/ と pbxproj は変わっていない）。
- 指揮役の確かめ：scratchpad/r8/build.log `** BUILD SUCCEEDED **`、warning 0行。ja.xcresult は14件通過・失敗0。en.xcresult は7件通過・失敗7で、en.log の失敗は `("From page 61.") is not equal to ("61ページからです。")` など、テストが日本語を決め打ちしているもの。
- 指揮役の裁定
  1. 未解決1（en で落ちる7件と BookmarkAcceptanceTests の行）：テストの不具合。verifier r3 が design/ 7 の言語ごとの値に直す。
  2. 未解決2・5と、文言の食い違い（design/ 7 にキーがない文、`duration.minutes` の60分以上）：designer が design/ 7 を決める。
  3. 未解決3（String Catalog の値が design/ 7 と違う `session.*`、およびコード reviewer r1 の `common.save.error`・`colophon.capture` en）：design/ 7 が正。designer の確定のあと、ios-engineer が String Catalog を design/ 7 にそろえる。
  4. 未解決4（推薦の理由 `RecommendationEngine.formatReason`、S-4 の読み上げ、`?? "15分"` の仮の値、名無しの今の本の Live Activity の書名「しおり」）：英語の利用者に見える不具合。designer の確定のあと、ios-engineer の8体目が直す。
