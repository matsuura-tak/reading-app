# 001-reading-session G3 H22 の組み方と読み出し（5体目）ios-engineer の報告

## まとめ
r4 の「ios-engineer に頼むこと」の1〜8は全部やりました。ただし完了とは言えません。理由は2つです。

- **受け入れテストが2本落ちています。** AC-99 と AC-140 です（ja と en の両方）。読み出しを h22 のスキーマに合わせたことで、テストの読み方と合わなくなりました（下の「未解決」の1）。
- **`make ios-test` 全体は動かしていません。** 指示どおりで、全体は verifier r3 が動かします。

そのほかの結果です。
- `make ios-build`：通りました。警告は0件です。
- `swift test --package-path ios/ReadingKit`：全部通りました（31件と9件）。
- 4つの枠で、state 6種と追加2つを保存し、7の1行で照らしました。全部 `hook.widget OK` でした。
- 172×76 と 170×170 では、画像と `fontSize`・`columnCount` が合っていました。
- Release の `nm`/`strings` で `UITestHook` は0件のままです。

BASE は `git rev-parse --short HEAD` → `d95c86b` で確かめました。コミットはしていません。

## 変更したファイル
- /Users/takumamatsuura/reading-app/ios/ReadingKit/Sources/ReadingCore/WidgetComposition.swift（新しく作った）：組み方の関数 `WidgetLineComposer.compose(family:width:height:rawLine:pageText:)`。記号の値は `WidgetCompositionConstants` に置き、ここが唯一の置き場です。`composition` の型を持ち、横書きのときは升目の9項目をキーごと書きません。
- /Users/takumamatsuura/reading-app/ios/ReadingKit/Sources/ReadingCore/WidgetRenderState.swift（新しく作った）：
  - state の enum、`unavailableReason` の enum
  - 写しの読み方 `WidgetSnapshotReader`（拡張と H22 が同じ関数を使う）
  - state を決める `WidgetRenderStateResolver`
  - 拡張と H22 が使う `WidgetTimelinePlan`
- /Users/takumamatsuura/reading-app/ios/ReadingKit/Sources/ReadingCore/VerticalLineLayout.swift：`composeWidget` を消しました。`layoutVerticalCells` は帯の画面で使うので残し、既定の4列×8字の値だけを外しました。
- /Users/takumamatsuura/reading-app/ios/ReadingKit/Sources/ReadingCore/ContractModels.swift：`H22Orientation`、`H22WidgetComposition`、`H22WidgetReadout` を消しました。
- /Users/takumamatsuura/reading-app/ios/ReadingKit/Sources/ReadingStore/SnapshotStore.swift：
  - 読み出しの型を h22 スキーマの形に作り直しました。
  - `fullHookPayload(now:)` は render ごとに、その request の枠で組みます。
  - `-uitest-widget` の値を確かめるようにしました。
  - `snapshotOverride`、`readForRender()`、`seq` の数え方を足しました。
  - `writeSnapshot` に `reloadOnlyIfChanged` を足しました。
- /Users/takumamatsuura/reading-app/ios/ReadingKit/Sources/ReadingStore/ReadingDataStore.swift：`hookWidgetJSONString` で書名を texts と label に足していた所を消しました。再読み込みの出どころを enum の中だけにしました。
- /Users/takumamatsuura/reading-app/ios/ReadingApp/Shared/ReadingWidgetSurfaceViews.swift：
  - `composeFitted`、`ReadingVerticalFit`、`ReadingVerticalGlyphGrid` を消しました。
  - 代わりに `ReadingVerticalGlyphLayer` を作りました。関数が返した `cells[].x/y` と `fontSize` を、そのまま枠の上に重ねて描きます。
  - W-1・W-2 は `unavailableReason` を受け取り、`widget.unavailable` を出します。
  - `ReadingWidgetMetrics` は ReadingCore の値を SwiftUI の型に直すだけにしました。
- /Users/takumamatsuura/reading-app/ios/ReadingWidgetExtension/ReadingWidgets.swift：timeline の項目が写しを読めなかった理由を持ちます。読み方とタイムラインの決まりは ReadingCore の関数を使います。
- /Users/takumamatsuura/reading-app/ios/ReadingApp/Theme/ThemeTokens.swift：`ReadingSharedContainer.readWidgetSnapshot()` を足しました。コメントも直しました。
- /Users/takumamatsuura/reading-app/ios/ReadingApp/UITestHooks/UITestHookCoordinator.swift：`-uitest-widget` が読めないときは `hook.error` に `H22:<値>` を出します。`UITEST_WIDGET_SNAPSHOT`（`@missing` か写しの文字列そのもの）を実装しました。
- /Users/takumamatsuura/reading-app/ios/ReadingApp/UITestHooks/UITestHookOverlayWindow.swift：W-1・W-2 の見本を `readForRender()` で読むようにしました（読み出しと同じ関数）。W-3・W-5 はこれまでどおりアプリの中の写しを使います。
- /Users/takumamatsuura/reading-app/ios/ReadingApp/UITestHooks/UITestHookReadoutBuilder.swift と UITestHookTypes.swift：使われていなかった `verticalJSON` と `UITestHookVerticalPayload` を消しました。
- テスト：
  - /Users/takumamatsuura/reading-app/ios/ReadingKit/Tests/ReadingCoreTests/WidgetCompositionTests.swift（新しく作った）
  - ReadingStoreTests.swift、VerticalLineLayoutTests.swift、WidgetSpokenLabelTests.swift、ContractModelsTests.swift（消した API に合わせて直した）
- /Users/takumamatsuura/reading-app/ios/docs/001-reading-session-implementation-notes.md：「8. 5体目」の節を足しました。

## r4 の1〜8ごとにやったことと証拠
1. **関数**
   - `WidgetLineComposer.compose` を、nonisolated の純粋な関数として作りました。import は Foundation だけです。
   - 縦書きのときは13項目を出します。横書きのときは `orientation`、`displayedLine`、`shortened`、`page` だけです。
   - 記号の値は `WidgetCompositionConstants.of(_:)` の1か所だけに置きました。W-1 は i0・B43・g4・R0・17→13、W-2 は i16・B0・g0・R20・20→13、列の間は 0.25s です。
2. **手順**
   - 列の数に上限を付けずに送り、送ったあとの C で入るかを見ます。下限でも入らなければ、送らずに組んで relaxed を真にします。
   - `feedCount` は1字送るごとに1と数えます。`referenceL` は「あ」25字を同じ枠で組んだときの L です。
   - 手順は tech-lead の fit.py と同じにしました。
   - 単体テストで、契約の表の9行がすべて合いました。
3. **View**
   - `composeFitted` と `ReadingVerticalFit` を消しました。`grep -rn 'composeFitted\|ReadingVerticalFit' ios --include='*.swift'` → 0件です。
   - 拡張と見本は同じ View の型を使い、描く大きさで関数を呼びます。
4. **render ごとに組む**
   - 例：normal-vertical.json は、153×68 が 17pt・C4・L4、172×76 が 17pt・C4・L4、148×148 が 20pt・C4・L4、170×170 が 20pt・C3・L5 です。
   - 入力が前と同じなら組み直しません。`seq` と `producedAt` は前の値のままです。
5. **`composition` の形**：normal のときだけ書きます。横書きの例は `{"displayedLine":"It was raining.","orientation":"horizontal","page":{...},"shortened":false}` です。
6. **読み出しの全体**
   - トップは `outputVersion`、`renders`、`reloadRequests`、`showcase` だけです。
   - render には `request{family,width,height}`、`seq`、`producedAt`（UTC、ミリ秒付き）、`snapshotSource`、`url`、`accessibility{identifier,label,groupCount:1}` を書きます。
   - `timeline` は `entries:[{date,state}]`、`policy:"never"`、`elapsedMs` です。拡張と同じ `WidgetTimelinePlan` を使い、`elapsedMs` は実時間を ContinuousClock で測ります。
   - texts は state の表どおりです。hidden のときの label は「しおり、61ページ」で、書名も一行も入りません。
   - エンコーダーは `.sortedKeys, .withoutEscapingSlashes` のままです。
7. **再読み込みの出どころ（裁定 (B)）**
   - 置き換え：`book.switch`/`book.finish` → `book.status`、`settings.appearance` → `settings.save`。enum の外だった `book.setTitle` → `book.update`、`settings.hideOnWidgets` → `settings.save` も直しました。
   - `store.purchase`/`restore`/`entitlement`/`refund` は `settings.save` と `reloadOnlyIfChanged: true` にしました。写しが変わらなければ数えません。
   - 今の数（`grep -n 'cause: "' ReadingDataStore.swift`）：book.add 3、book.delete 1、book.status 2、book.update 2、mark.save 1、settings.save 9。enum の外は0件です。
8. **単体テスト**
   - 足したもの：契約の表の9行、「あ、」×12＋「あ」の4枠（欠け0字）、「あ」＋「ー」×24（W-1 の2枠で relaxed 真・13pt・L5・C5・cells 25個）、「そして」＋「…」×6（17pt・C5・feed 11・relaxed 偽）、「あいうーーーー」のくり返し、横書きと縦書きのキーの組、state の表、unavailable の理由。
   - Store の側：差し替えの `@missing` と壊れた写し、枠の誤り、写しを変えない保存が数えられないこと。
   - `swift test --package-path ios/ReadingKit` → `Test run with 31 tests in 8 suites passed` と `Test run with 9 tests in 1 suite passed`。

## 4つの枠×状態の検査
`-uitest-widget accessoryRectangular:153x68,accessoryRectangular:172x76,systemSmall:148x148,systemSmall:170x170` で起動し、`hook.widget` の値を保存しました。保存には、スクラッチパッドに作った XCUITest（`XCUIApplication(bundleIdentifier:)` でインストール済みの Debug 版を起動する）を使いました。リポジトリには入れていません。

照らす1行はスクリプトにしました（/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/r6/check-all.sh）。中身は契約の7の1行そのままです。

結果（ja、/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/r6/dump-ja/）：
```
empty.json: hook.widget OK: 4 renders
hidden.json: hook.widget OK: 4 renders
noLine-titlePending.json: hook.widget OK: 4 renders
noLine.json: hook.widget OK: 4 renders
noLineNoPage.json: hook.widget OK: 4 renders
normal-horizontal.json: hook.widget OK: 4 renders
normal-vertical.json: hook.widget OK: 4 renders
show-*（ac27・kana25・hokosai×4枠、unavailable×2枠。showcase も一緒に照らした）: 14件すべて hook.widget OK: 1 renders
unavailable-malformed.json: hook.widget OK: 4 renders
unavailable-missing.json: hook.widget OK: 4 renders
overall_fail=0
```
en（/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/r6/dump-en/）も9件すべて OK、`overall_fail=0` でした。

unavailable は今の実装では出せなかったので、出せるようにしました。
- `UITEST_WIDGET_SNAPSHOT=@missing` → `unavailableReason: missing`、`snapshotSource: override`
- 壊れた写し → `malformed`
- 拡張も、読めない写しで `widget.unavailable` を出すように直しました。これまでは `widget.empty` を出していました。

## 画像と読み出しを照らした結果
同じ起動で `-uitest-widget <枠>` と `-uitest-widget-show <枠>` を一緒に渡しました。
- **172×76（AC-27 の14字）**：読み出しは 17pt・C4・L4 です。画像も4列×4字（下人は、／雨やみを／待ってい／た。）で、字の高さは約51px＝17pt（@3x）でした。canvas は (115,413,172,76)、`contentOverflow` は偽です。
- **170×170（同じ14字）**：読み出しは 20pt・C3・L5 です。画像も3列×5字（下人は、雨／やみを待っ／ていた。）で、字は約60px＝20ptでした。
- **153×68（かな25字）**：読み出しは 13pt・C5・L5 で、画像も5×5でした。
- **unavailable の 170×170**：画像に `widget.unavailable` の文が出ました。
- 画像のパス：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/r6/dump-ja/show-*.png

## 実行したコマンドと結果
- `make ios-build` → 終了コード 0、`** BUILD SUCCEEDED **`。`warning:` は0件です（ログ：scratchpad/r6/build.log）。
- `swift test`（ios/ReadingKit）→ 終了コード 0。40件成功、失敗0、飛ばした0。
- 受け入れテスト：`xcodebuild test ... -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.0'` で、次をテストプランの ja と en の構成で動かしました。
  - `-only-testing:ReadingAcceptanceTests/WidgetAndActivityAcceptanceTests`
  - `hook.widget` を読むテスト11本：Bookmark の AC64・AC73・AC141、Finish の AC82、ReadingSession の AC62、Registration の AC140、Settings の AC106・AC111・AC125、Shelf の AC14・AC16。h17 の `widgetReloads` を読むのは AC-33 だけで、上のクラスに入っています。
  - 結果：終了コード 65。58件成功、4件失敗で、失敗は AC-99 と AC-140 の ja と en です。AC-33、AC-106、AC-111、AC-27〜35 は通りました。
  - 結果ファイル：scratchpad/r6/accept.xcresult、ログ：scratchpad/r6/accept.log
  - 失敗の最初の行：`WidgetAndActivityAcceptanceTests.swift:682: error: ... test_AC99_... : XCTAssertTrue failed`、`RegistrationAcceptanceTests.swift:886: error: ... test_AC140_... : XCTAssertTrue failed`
- Release（`-configuration Release`、`SWIFT_TREAT_WARNINGS_AS_ERRORS=YES`）→ BUILD SUCCEEDED。
  - アプリ本体：`nm -a | grep -c UITestHook` → 0、`strings | grep -c UITestHook` → 0、`UITEST_WIDGET_SNAPSHOT` → 0
  - ウィジェット拡張：上と同じく、どれも0件
- 4章の検査（変えたファイルについて）：
  - 並行処理を黙らせる書き方：0件
  - 古い書き方：0件
  - `.frame(height:`：1件。W-2 の場所の行の高さ16で、前からあった行です。契約の R の値です。
  - 強制アンラップ：0件。`print`/秘密：0件。外部への通信：0件
  - `Formatter()|.sorted|.filter`：4件。View の body の中ではありません（SnapshotStore の読み出しと、W-3 の文の組み立て）。
- PrivacyInfo.xcprivacy は変えていません（申告が要る新しい API はありません）。
- API の確認（どれも最低対応 iOS 26 より前からある）：
  - ContinuousClock、iOS 16：https://developer.apple.com/documentation/swift/continuousclock
  - ISO8601DateFormatter の `.withFractionalSeconds`、iOS 11：https://developer.apple.com/documentation/foundation/iso8601dateformatter/options/withfractionalseconds
  - TimelineReloadPolicy の never/atEnd/after、iOS 14：https://developer.apple.com/documentation/widgetkit/timelinereloadpolicy

## 未解決
1. **AC-99 と AC-140 が落ちる（verifier に頼むこと）。**
   - テストは `readHookJSON("hook.widget")` で読んだ辞書を `"\(widget)"` で文字列にしてから、「羅生門」「こころ」を探しています。
   - Foundation の辞書の説明では、入れ子の辞書の中の日本語が `\U7f85\U751f\U9580` の形に書き換わります。これまで通っていたのは、トップに `title` があったからです。
   - h22 のトップは `additionalProperties: false` なので、アプリの側でトップに書名を戻すことはできません。
   - 書名は `renders[].accessibility.label`（「羅生門、61ページ。…」）に入っています。swift のスクリプトで、説明の文字列には書名が見つからないことを確かめました（scratchpad/r6/desc.swift）。
   - テストを `readHookString` で読む形にする必要があります。テストは直していません。
2. **購入と復元のときの再読み込み（裁定の読み方を確かめてほしい）。**
   - 裁定は「購入と復元は写しを変えないので、再読み込みを求めない」です。
   - ただし実装では、購入と復元で見本の見た目（`previewAppearanceID`）が `settings.appearanceID` に入り、写しの見た目が変わります。
   - そこで「写しが変わったときだけ `settings.save` で数え、変わらなければ求めない」にしました。文字どおりに「一度も求めない」にすると、本物のウィジェットが古い見た目のまま残ります。文字どおりにするなら1行で戻せます。
3. **unavailable の理由の対応で、契約に決まっていない所があります。**
   - widget-snapshot の読む側の決まりの (7)「名無しなのに title がある」は、h22 の `unavailableReason` の enum にありません。今は `malformed` にしています。
   - 一行の id だけがある（一行はない）ときも `malformed` にしました。
4. **写しのファイルの形が契約と違います（前からあるずれ。今回の範囲の外）。**
   - アプリが書く `widget-snapshot.json` は `version`/`updatedAt`/`currentBook{id,title,author,latestLine,progressDisplay…}` の形です。`contracts/widget-snapshot.schema.json`（`schemaVersion`、`line`、`progress{unit,value}`、hidden のときは書名を書かない）とは違います。
   - そのため、契約の形の写しを `UITEST_WIDGET_SNAPSHOT` に入れると `malformed` になります。範囲の外なので、tech-lead に見てもらう必要があります。
5. **`launch` の再読み込みは数えていません。** 起動のときに写しを書いても、`byCause` に `launch` は出ません。enum では許されていますが、必須ではないので今のままにしました。
6. **Mac で動かしていないもの。**
   - `make ios-test` 全体と `make ios-test-perf`（AC-102 の `elapsedMs`）は動かしていません。AC-102 は `timeline.elapsedMs` を読むので、今の形でそのまま読めるはずです。
   - 本物のロック画面とホーム画面で unavailable がどう見えるかは、G4 の実機で見ます。

## 記録（指揮役が保存するときに書き足す）
- 日付：2026-11-02。BASE d95c86b。100手の上限で止まったあと、報告を返した。差分は ios/ の中だけ（ios/AcceptanceTests/ は触っていない）。
- 指揮役の確かめ
  - scratchpad/r6/build.log：`** BUILD SUCCEEDED **`、コンパイラーの warning 0行。
  - `swift test --package-path ios/ReadingKit`（指揮役が動かした）：`Test run with 31 tests in 8 suites passed`、`Test run with 9 tests in 1 suite passed`。
  - scratchpad/r6/accept.xcresult の要約：totalTestCount 31、passed 29、failed 2（AC-99、AC-140。テストプランの構成ごとに数えると58件成功、4件失敗）。
  - 落ちた2本のテストの行を読んだ：WidgetAndActivityAcceptanceTests.swift:680-682 と RegistrationAcceptanceTests.swift:884-886 は、`readHookJSON("hook.widget")` の辞書を `"\(widget)"` で文字列にして書名を探している。入れ子の辞書の説明では日本語が `\U....` に書き換わるため見つからない。書名は `renders[].accessibility.label` に入っている。
- 指揮役の裁定
  1. **AC-99・AC-140**：アプリの不具合ではなく、テストの読み方の不具合。verifier r3 が、生の JSON の文字列（`readHookString` など）か `renders[].accessibility.label`／`texts` を読む形に直す。確かめる中身（書名がウィジェットに出ること）は弱めない。
  2. **購入と復元のときの再読み込み（未解決2）**：5体目の読み方を受け入れる。写しが変わったときだけ `settings.save` で数え、変わらなければ求めない。前の裁定の前提（購入と復元は写しを変えない）が実装と違っていたため。本物のウィジェットが古い見た目のまま残らないことを優先する。
  3. **unavailable の理由（未解決3）**：今の `malformed` への寄せ方を受け入れる。契約に足すかどうかは G3 のあとで tech-lead に回す。
  4. **写しのファイルの形が contracts/widget-snapshot.schema.json と違う（未解決4。既存）**：契約が正。hidden のときに書名を書かないことは、ロック中にも読める写し（保護の等級 `.completeUntilFirstUserAuthentication`）のプライバシーの決まりなので、実装を契約に合わせる。ios-engineer の6体目に、コードの reviewer の提案の小さな直しと一緒に頼む。
  5. **`launch` の再読み込み（未解決5）**：今のままでよい（enum では許されるが必須ではない）。
