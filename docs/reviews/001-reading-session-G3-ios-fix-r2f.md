# ios-engineer 6体目の報告（001-reading-session G3）

## 結論
- 写しのファイル `widget-snapshot.json` を、契約 `contracts/widget-snapshot.schema.json` の形にしました。直したのは書く側（`SnapshotStore`）と読む側（`WidgetSnapshotReader`）の両方です。
  - hidden のときは書名も一行も書きません。「しおり」の文字も書きません。
  - 5つの場合の JSON は、どれもスキーマに照らしてエラー0でした。
  - `UITEST_WIDGET_SNAPSHOT` に契約の8つの例を入れたとき、`hook.widget` の読み出しが h22 スキーマに照らしてエラー0でした。
- コードの reviewer の提案のうち、次の3つを直しました。
  - `store.buy` と復元のボタンの2度押し
  - `catalog.lookup` を止めている間に来た2つ目のバーコード
  - `storekit.*` の ProgressView を出す順（0.3秒のあとに出す）
- `LM_FILTER_WARNINGS = YES` は試しましたが、その1行は消えませんでした。指示どおり元に戻しました（pbxproj の差分は0）。
- `make ios-build` は通り、コンパイラの警告は0です。`swift test` は全部通りました。
- **受け入れテストは45件中42件が通り、3件が落ちました。** 新しく落ちたのは AC-141 の en の1件で、テストが契約と食い違っています（下の「未解決」の1）。AC-99 と AC-140 は、前から分かっていたテストの読み方の不具合です。
- BASE は `git rev-parse --short HEAD` → `d204eac` で確かめました。コミットはしていません。

## 変更したファイル
- /Users/takumamatsuura/reading-app/ios/ReadingKit/Sources/ReadingCore/ContractModels.swift：写しの型を契約の形に作り直しました。
  - `WidgetSnapshot{schemaVersion, hideOnWidgets, appearanceID, currentBook?}`、`WidgetSnapshotBook{title?, isTitlePending, line?, progress?}`、`WidgetSnapshotProgress{unit, value}`。
  - `id`、`author`、`updatedAt`、`progressDisplay`、`latestLine` はなくしました。
  - `isTitlePending` は真のときだけ書きます。読むときに偽が書いてあれば型の誤りにします。
  - 確かめる決まりは、契約の「読む側」の (4)〜(7) です。
- /Users/takumamatsuura/reading-app/ios/ReadingKit/Sources/ReadingCore/WidgetRenderState.swift：理由の対応を直しました（privacy → `hiddenConflict`、(7) → `malformed`）。状態は `line` と `progress` で決めます。
- /Users/takumamatsuura/reading-app/ios/ReadingKit/Sources/ReadingCore/WidgetSpokenStrings.swift：`page.short`、`location.short`、`percent.short` の書式を足しました。`progressText(_:)` と `spokenProgress(_:)` も足しました。
- /Users/takumamatsuura/reading-app/ios/ReadingKit/Sources/ReadingCore/VerticalLineLayout.swift：読み上げのラベルを新しい型で組むようにしました。
  - 書名がないときは `widget.currentBookAsTitle` を読みます。
  - 一行は、全文を25字に縮めてから読みます。前と同じ文です。
- /Users/takumamatsuura/reading-app/ios/ReadingKit/Sources/ReadingStore/SnapshotStore.swift：
  - `makeSnapshot(currentBook:settings:)` を足しました（書く側の決まり）。
  - 書き方を契約どおり `[.atomic, .completeFileProtectionUntilFirstUserAuthentication]` にしました。
  - init は前の版の形を読まず、今の本なしから始めます。
  - H22 の `texts` を新しい型と短い形で作るようにしました。
- /Users/takumamatsuura/reading-app/ios/ReadingApp/Shared/ReadingWidgetSurfaceViews.swift：
  - `ReadingWidgetStrings.progressText(for:)` を足し、短い形を String Catalog から引きます。
  - `displayTitle` は、書名がなければ `widget.currentBookAsTitle` を返します。
  - W-3 の一行は、全文を25字に縮めて出します。placeholder も新しい型にしました。
- /Users/takumamatsuura/reading-app/ios/ReadingApp/Resources/Localizable.xcstrings：`page.short`（p.%lld / p.%lld）、`location.short`（位置%lld / Loc %lld）、`percent.short`（%lld%% / %lld%%）を design/ 7 の値で足しました。
- /Users/takumamatsuura/reading-app/ios/ReadingApp/Intents/ReadingAppIntents.swift：W-5 の答えを `progress{unit,value}` から作ります。
- /Users/takumamatsuura/reading-app/ios/ReadingApp/Theme/ThemeTokens.swift、/Users/takumamatsuura/reading-app/ios/ReadingWidgetExtension/ReadingWidgets.swift、/Users/takumamatsuura/reading-app/ios/ReadingApp/UITestHooks/UITestHookOverlayWindow.swift：新しい初期化に合わせました。W-3 の `bookId` は、主の保存先の今の本から取ります。
- /Users/takumamatsuura/reading-app/ios/ReadingApp/Views/SessionResultAndGuideViews.swift、/Users/takumamatsuura/reading-app/ios/ReadingApp/Views/SettingsAndStoreViews.swift：S-5 と S-10a の見本の写しを新しい型で組みます。
- /Users/takumamatsuura/reading-app/ios/ReadingApp/Views/SettingsAndStoreViews.swift：
  - 進行中の印 `restoreInFlight` と `purchaseInFlight` を足しました。`Task` を作る前に同期で立て、本物の処理が終わったら下ろします。立っている間は押しても弾きます。
  - ProgressView は `HeldLoadProgressView` で出します。
- /Users/takumamatsuura/reading-app/ios/ReadingApp/Views/LoadingPlaceholderViews.swift：`HeldLoadProgressView` を新しく作りました。
  - 門で止められて 0.3秒（ContinuousClock）を超えてから ProgressView に替え、出したときに `markShown` します。
  - それまでは中身（購入のボタン）をそのまま出します。
- /Users/takumamatsuura/reading-app/ios/ReadingApp/Views/BookRegistrationViews.swift：止めている間の2つ目以降の読み取りを `queuedCatalogLookups` に待たせます。放したあと、1回目のあとに来た順に引きます。帯は放すまで保ちます。
- テスト（/Users/takumamatsuura/reading-app/ios/ReadingKit/Tests/）
  - ContractModelsTests.swift：契約の8つの例を読んで書き戻すテストと、読む側の決まりのテストを書き直しました。
  - ReadingStoreTests.swift：3つ足しました。
    - 写しの5つの場合
    - 前の版の形のファイル
    - H22 の差し替えで契約の8つの例を読む（契約のファイルから読む）
  - WidgetCompositionTests.swift、VerticalLineLayoutTests.swift、WidgetSpokenLabelTests.swift：新しい型に合わせました。期待する値は変えていません。
- /Users/takumamatsuura/reading-app/ios/docs/001-reading-session-implementation-notes.md：「9. 6体目」の節を足しました。

## 前の版の形の写しの扱い
- 契約に移行の決まりはありません。`schemaVersion` がなく `version` を持つファイルは、落とさずに `unavailable(version)` にしました。`malformed` にはしていません。
- アプリは起動のたびに写しを書き直すので、読めないのは次に書くまでの間だけです。単体テスト `legacyWidgetSnapshotFile` で確かめました。

## API の確認
| API | URL | 対応 OS | 最低対応 OS（26.0）以下か |
|---|---|---|---|
| `Data.WritingOptions.completeFileProtectionUntilFirstUserAuthentication` | https://developer.apple.com/documentation/foundation/nsdata/writingoptions/completefileprotectionuntilfirstuserauthentication | iOS 4+ | 以下（契約に名前があります。ビルドが通ることで確かめました。今回は文書の本文を開いていません） |

ほかに新しく使った Apple の API はありません（`.task(id:)` と `ContinuousClock` は前から使っています）。

## 画面の状態と識別子
- 画面と識別子は足しも変えもしていません。`store.buy` と `settings.restorePurchases` は名前もそのままです。
- W-1・W-2 の unavailable は、写しの理由（missing、unopenable、malformed、version、range、hiddenConflict）で出ます。
- String Catalog は234キーで、ja と en がそろったものが234、欠けは0です。

## 実行したコマンドと結果
（ログはすべて /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/r7/ にあります。）
- `make ios-build`（build4.log）：終了コード 0、`** BUILD SUCCEEDED **`。コンパイラの警告は0行です。残る1行は `appintentsmetadataprocessor ... warning: Metadata extraction skipped` で、コンパイラの警告ではありません（前の裁定で数えないもの）。
- `swift test --package-path ios/ReadingKit`：終了コード 0。`Test run with 12 tests in 1 suite passed` と `Test run with 31 tests in 8 suites passed` でした。
- 写しの5つの JSON：
  - 単体テスト `widgetSnapshotFileShape` が書いたものを `snapshots/widget-snapshot-{normal,hidden,titlePending,noLine,noCurrentBook}.json` に保存しました。
  - `~/.cache/reading-app/contracts-schema-venv/bin/python -I validate.py contracts/widget-snapshot.schema.json …` → 5つとも OK、`jsonschema 4.25.1 errors 0`。
  - hidden の写しは `{"appearanceID":"default","currentBook":{"progress":{"unit":"page","value":61}},"hideOnWidgets":true,"schemaVersion":1}` です。
- `hook.widget` に契約の形の写しを差し替えた場合：
  - `snapshots/hook-widget-example0〜7.json` を `contracts/hooks/h22-widget.schema.json` に照らし、8つとも OK、errors 0 でした。
  - state はそれぞれ normal、noLine、noLineNoPage、normal、noLine、noLine、hidden、empty でした。
  - en の位置は `Loc 1450` になります（H22 の決まりどおり）。
- `LM_FILTER_WARNINGS = YES` を付けて clean ビルド（build-clean.log）：`--quiet-warnings` は渡りましたが、warning の1行は残りました。pbxproj は元に戻しました。
- 受け入れテスト（accept.log、accept.xcresult）：`xcodebuild test … -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.0'` に `-only-testing` で次を指定しました。
  - WidgetAndActivityAcceptanceTests（AC-34 を含む）
  - RegistrationAcceptanceTests
  - AC-105〜AC-111
  - AC-73 と AC-141（写しの進み具合の形が変わったので足しました）
  - 結果：ja と en の両方で、45件中42件が成功、3件が失敗、飛ばしたものは0でした。
  - 落ちたもの：
    - AC-99（ja・en）、AC-140（ja・en）：分かっていたテストの読み方の不具合です。
    - AC-141（en だけ）：下の「未解決」の1です。
  - AC-34（hidden）と、購入・復元・返金（AC-105〜AC-111）は、ja・en とも通りました。
- Release（release.log、`-derivedDataPath` は scratchpad）：終了コード 0。ReadingApp、ReadingWidgetExtension、ReadingBackgroundAssetsExtension のどれも、`nm -a` の UITestHook が0、`strings -a` の UITestHook が0、uitest（大文字小文字を問わず）が0でした。
- 4章の検査（差分の足した行が対象）：`DispatchQueue.main|@unchecked Sendable|nonisolated(unsafe)|Task.detached|@preconcurrency|ObservableObject|@Published|@StateObject|.system(size:|.frame(height:|Color(red:|onTapGesture|print(|try!|as!|URLSession|NWConnection` は0件、強制アンラップも0件でした。PrivacyInfo.xcprivacy は変えていません（理由の申告が要る API を新しく使っていないため）。
- 差分は ios/ の中の21ファイルだけです。ios/AcceptanceTests/、contracts/、design/、docs/ には触っていません。

## 3. ReadingStore に残る日本語の直書き（見つけただけで、直していません）
- `ReadingDataStore.swift:3057-3272` の `handleExternalIntent` の `spokenText`（「読書を始めました。」「\(page)ページからです。」「位置\(loc)からです。」など）：
  - `WhereStoppedIntent.perform` は、`ReadingDataStore.shared` があるとき、この文をそのまま Siri の答えとスニペットに出します。
  - そのため、**英語の設定でも日本語が出ます**。String Catalog に `intent.whereStopped.*` のキーはあります。
  - 十数か所あり、小さい直しではないので、次の作業として頼みたいです。
- `ReadingDataStore.swift:2016、2809、2879-2882`：Live Activity の状態の `title` に「しおり」、`endButtonLabel` に「終える」が入っています。描くときは `ReadingWidgetStrings` を通すので、画面には出ません。
- `ReadingDataStore.swift:2174、2205、2347-2352、2857-2859、3331-3332`：`latestResultSummary` などの「分」「晩」。画面に出るかどうかは確かめていません。
- `ReadingDataStore.swift:3951-3966`（ショートカットの言い方）、`CatalogDatabase.swift`（H20 の本の値と出典の文）：書誌のデータと出典なので、そのままでよい所です。
- ReadingStore の外の `InputValidator.formatProgressDisplay`（ReadingCore/Models.swift:289）は「位置」を直書きしています。S-10a の `previewPage` などで使われています。

## 未解決
1. **AC-141 の en が新しく落ちます（verifier に頼むこと）。**
   - BookmarkAcceptanceTests.swift:536 で `readHookString("hook.widget").contains("位置1450")` を確かめています。
   - 契約 H22（test-hooks.md 396行）は、英語を `Loc 1450` と決めています。design/ 7 の `location.short` の en も `Loc %lld` です。
   - 前は写しに「位置1450」を直書きしていたので、英語でも通っていました。
   - テストを言語ごとの値にする直しが要ります。テストは直していません。
2. **書名も名無しの印もない今の本の扱い（tech-lead に見てほしいこと）。**
   - 契約の読む側の決まり (3)〜(7) に当たらないので、読めるものにしました。書名の所は `widget.currentBookAsTitle` を出します。
   - 前は `range` にして、「しおり」を出していました。契約に足すかどうかを決めてほしいです。
3. **読み上げの一行の長さ（契約で決まっていないこと）。**
   - 写しには60字までの全文を書くようにしました。読み上げのラベルと W-3 の一行は、前と同じく25字に縮めた一行です。
   - 全文を読むかどうかは、契約にも design/ にも書かれていません。
4. **前の版の形の写しを `version` の理由にしたこと。** 契約 (4) の「知らない大きな版」に寄せた読み方です。この扱いでよいか、tech-lead に確かめてほしいです。
5. **Mac で動かしていないもの。**
   - `make ios-test` の全体と `make ios-test-perf`。
   - 本物のロック画面での写しの読み方（保護の等級）は、G4 の実機で見ます。
6. **`SessionResultAndGuideViews.guideSnapshot(line:progress:)` の `progress` の引数が使われなくなりました。** 害はありませんが、次の直しで消せます。

## 記録（指揮役が保存するときに書き足す）
- 日付：2026-11-02。BASE d204eac。差分は ios/ の中だけ（ios/AcceptanceTests/ と pbxproj は変わっていない）。
- 指揮役の確かめ
  - scratchpad/r7/build4.log：`** BUILD SUCCEEDED **`、コンパイラーの warning 0行。
  - scratchpad/r7/accept.xcresult：45件中42件成功、失敗3（AC-99、AC-140、AC-141）。
  - scratchpad/r7/snapshots/widget-snapshot-{normal,hidden,titlePending,noLine,noCurrentBook}.json を、指揮役が venv で contracts/widget-snapshot.schema.json に照らした：5つともエラー0。
- 指揮役の裁定
  1. AC-141 の en（`位置1450` を探す）：テストが契約 H22 と design/ 7（en は `Loc 1450`）と食い違っている。verifier r3 が言語ごとの値に直す。
  2. 未解決2（書名も名無しの印もない今の本）、未解決4（前の版の写しを `version` の理由に）：今の扱いを受け入れる。契約に足すかは G3 のあとで tech-lead に回す。
  3. 未解決3（読み上げの一行は25字に縮めたもの）：前と同じ振る舞いなので、今のままでよい。
  4. **「3. 日本語の直書き」のうち、英語の設定で日本語が出るもの**（Siri とショートカットの答えの `spokenText`、`InputValidator.formatProgressDisplay` の「位置」、画面に出るなら「分」「晩」）：英語の利用者に見える不具合なので、verifier r3 の前に ios-engineer の7体目が直す。
