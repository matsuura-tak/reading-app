（指揮役の注）G3 r2 の製品の直し、1体目（ios-engineer）。手数の上限で途中まで。作り手の報告で、判定ではない。

## 要約
手数の上限（70回）を超えたので、ここまでの結果を返します。**完了とは言えません。** 理由は3つです。
- `make ios-test` はまだ動いています。結果は出ていません。
- S-1 の AX5 の直し（項目8）は、最後の `make ios-build` の後に入れたため、ビルドで確かめていません。
- 自分でシミュレーターを使って撮る作業はしていません。撮る台本だけ作ってあります。

BASE は 99121e1 で、始める前に HEAD と同じことを確かめました。コミットはしていません。

## 変更したファイル
- `ios/ReadingApp/Shared/ReadingWidgetSurfaceViews.swift`（新規）
  - W-1〜W-5 の View をここにまとめ、アプリと拡張の両方のターゲットに入れました。中身は次のとおりです。
    - `ReadingLockScreenWidgetView`、`ReadingHomeSmallWidgetView`、`ReadingLiveActivityLockScreenView<EndButton>`、`ReadingControlLabelView`、`WhereStoppedSnippetView`
    - `ReadingLiveActivityStateFactory`、`ReadingWidgetPlaceholder`、`ReadingWidgetMetrics`、`ReadingWidgetStrings`、`ReadingVerticalFit`
  - View は widgetFamily も context も読みません。ファミリー、写し、大きさ、余白を引数で受けます。
  - 「終える」は `(Text) -> EndButton` の引数で受けます。
  - 縦書きは ADR 0003 の式で枠に合わせ、字を 17→13pt、20→13pt と下げます。
  - 識別子は design 6 の `widget.rectangular`、`widget.small`、`liveActivity.banner`、`liveActivity.end`、`intent.snippet` です。
- `ios/ReadingWidgetExtension/ReadingWidgets.swift`
  - 共有した View を使う形にしました。拡張は `Button(intent: EndReadingFromActivityIntent())` を渡します。
  - W-1 と W-2 に `.contentMarginsDisabled()` を付けました。
  - 直書きの文言（「しおり」「いま読んでいる本はありません」「今夜の読書を始める」など）は文言キーにしました。
  - 名前が誤っていた色 `DefaultBgSecondary` を、実在する `DefaultBackgroundSecondary` に直しました。
- `ios/ReadingApp/Intents/ReadingAppIntents.swift`：小窓を `WhereStoppedSnippetView` にし、`formatResponse` を `intent.whereStopped.*` のキーで作る形にしました。
- `ios/ReadingApp/UITestHooks/UITestHookOverlayWindow.swift`
  - 前の `WidgetShowcaseHarnessView` を消し、`UITestHookWidgetShowcaseView` に置き換えました。
    - 根は `hook.widget.showcase`、枠は `hook.widget.canvas` です。枠は実寸で `.clipped()` します。
    - 指定は H22 の文法どおりに読みます（`UITestHookWidgetShowcaseSpec.parse`）。
    - `-uitest-readouts off` でも出ます。
    - `placeholder` は `.redacted` で描きます。
    - 見本の「終える」は `Button(action: {})` です。
  - `UITestHookErrorView` を足しました。
- `ios/ReadingApp/UITestHooks/UITestHookCoordinator.swift`
  - 足したもの：`widgetShowcase`、`widgetShowcaseReadout`、`hookErrorValue`、`configureWidgetShowcase`、`configureLoadHold`（`-uitest-hold-load`）、`yomuma.uitest.load.release` の受け口。
  - 失敗のときは `H22:liveActivity.ended.noRecord` や `H33:<値>` を返します。
- `ios/ReadingApp/UITestHooks/UITestHookReadoutBuilder.swift`：`hook.widget` に `showcase` を足し、`hook.state` に `hold.<対象>` を足しました。`store.load` を止めている間、`hook.store` は空にします。
- `ios/ReadingApp/ContentView.swift`：hook.error だけの画面、見本、`GatedLoadView` による `store.load` の止め方を入れました。
- `ios/ReadingApp/Views/LoadingPlaceholderViews.swift`（新規）：`GatedLoadView`（0.3秒を ContinuousClock で数える）、S-1 の灰の帯、行の形の灰の帯、Preview 4つ。
- `ios/ReadingKit/Sources/ReadingStore/LoadHoldGate.swift`（新規）：H33 の実行時の門です。`#if` なしで、既定は素通りします。
- `ios/ReadingKit/Sources/ReadingStore/ReadingDataStore.swift`
  - 足したもの：`loadGate`、`settings.save` の失敗（値を戻し、`settingsSaveErrorSection` を立てる）。
  - 通信なしで復元したら `store.offline` を出し、購入の状態は変えません。
  - `purchaseAttempts`、`restoreAttempts`、`refundCount` を数え、`hook.storekit` に出します。この3つはスキーマで必須なのに、これまで出ていませんでした。
- `ios/ReadingApp/Views/SettingsAndStoreViews.swift`：節の下に `common.save.error` を出します。復元の門と、その横の ProgressView を入れました。
- `ios/ReadingApp/Views/ShelfAndBookDetailViews.swift`：S-6 を `GatedLoadView` で包み、灰の帯を5行出します。
- `ios/ReadingApp/Views/BookmarkMarkFlowViews.swift` と `ios/ReadingKit/Sources/ReadingCore/OCRPipeline.swift`
  - S-3c は選んだ列を60字で黙って切っていました。これが AC-72 の不具合の原因です。
  - 切らない `joinSelectedColumns` を足し、61字のまま保存して `mark.line.invalid` が出る道にしました。
- `ios/ReadingApp/Views/BookmarkHomeView.swift`：AX1 以上では、一行をボタンより上に置きます（項目8）。**未ビルド。**
- `ios/ReadingApp/Theme/ThemeTokens.swift`：`widgetLineFixed(size:)` を足しました。
- `ios/ReadingApp/Resources/Localizable.xcstrings`：キーを足し、または直しました。ja と en は全部そろえました。
  - `widget.hidden`、`widget.empty`（値を design 7 に直した）、`widget.currentBookAsTitle`、`widget.unavailable`
  - `control.startReading`、`liveActivity.end.label`、`reading.end`、`liveActivity.readingSince`
  - `intent.whereStopped.page`、`location`、`percent`、`noPage`、`noCurrent`、`error`、`common.loading`
- `ios/ReadingApp.xcodeproj/project.pbxproj`
  - `ReadingAcceptanceTests` を同期フォルダ（`AcceptanceTests`）にしました。`.xctestplan` は対象から外しました。objectVersion は 56 から 77 に上げました。
  - 新しいファイル3つを足しました。
- `ios/docs/001-reading-session-implementation-notes.md`（新規の実装ノート）：`viewType` の一覧、H33 の門の関数、同期フォルダの使い方、hook.error の範囲を書きました。

## API の確認
| API | 確かめ方 | 最低 iOS 26 以下か |
|---|---|---|
| `contentMarginsDisabled()`、`EnvironmentValues.widgetContentMargins` | 契約の H22 に、SDK の swiftinterface の行の番号つきで確かめた記録がある。ビルドも通った | iOS 17 から使えるので以下 |
| `onGeometryChange(for:of:action:)`、`ContinuousClock.sleep(until:)`、`Duration.formatted(.units)`、`Font.custom(_:fixedSize:)` | developer.apple.com は今回開いていない。ビルドが通ったことだけが根拠 | どれも iOS 16〜18 からなので以下 |

## 画面の状態と識別子
- 全部のマスを照らす表は作れていません。
- 今回足した状態と Preview：
  - S-1 の読み込み中：`LoadingPlaceholderViews.swift` の `BookmarkLoadingPlaceholderView`。Preview は「S-1/loading」と「S-1/loading dark」。
  - S-6 の読み込み中：同じファイルの `RedactedRowsPlaceholderView`。Preview は「S-6/loading」と「S-6/loading AX5」。
- 識別子：W-1〜W-5 の全体の5つと、`liveActivity.end` を design 6 の名前にしました。
- 文言キー：足した、または直した15キーの ja と en は全部そろっています。

## 実行したコマンドと結果
- `make ios-build`：終了コード 0、`** BUILD SUCCEEDED **`。
  - 警告は25行あります。`BookRegistrationViews.swift` の 413〜463 行の palette の Sendable の警告6件が2回ずつ出たものと、拡張の埋め込み・strip の警告です。
  - `BookRegistrationViews.swift` は今回触っていないので、前からある警告だと考えています。ただし BASE で数を比べてはいません。
  - 自分が足したファイルの警告は0件です。
- `make check-contracts`：`ALL PASSED: 8 schemas, 28 examples validated with 0 errors.`
- Release ビルド（`-derivedDataPath` はスクラッチパッド）：終了コード 0。
  - アプリと拡張の両方で、`nm -a | grep -c UITestHook` が 0、`strings -a | grep -c UITestHook` が 0、`strings | grep -ci uitest` が 0、`WidgetShowcase` が 0。
  - `LoadHoldGate` の記号は残っています（アプリ408、拡張404）。門は Release に残す決まりなので、想定どおりです。
- `make ios-test`：**実行中です。** ログは `/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ios-test.log`（最後に `exit=` の行が付きます）。
  - これまでに出た結果：
    - swift test：8件と17件がすべて成功
    - XCTest：`Executed 20 tests, with 0 failures` などで、成功は31件、失敗は0件
    - `G3EvidenceCaptureTests` の suite が passed
  - 最終の件数は出ていません。この xcodebuild がまだシミュレーター（iPhone 17、OS 26.0）を使っています。verifier r3 は、これが終わってから始めてください。
- 4章の検査は、時間切れで数えていません。

## 監査の42件（項目9）
手を付けたのは W-1〜W-5 の約19件だけで、動かして確かめてはいません。
- 見本を拡張と同じ View にし、全体を1つの要素にまとめました。前の見本の `widget.line` の 11×132pt の要素は無くなっています。
- S-3a、S-3b、S-3c、S-5、S-8、S-10a の残り23件（プレースホルダー切れ、`register.footer`、`store.preview` の文字切れなど）は手付かずです。

## 落ちの切り分け（項目10）
- `~/Library/Logs/DiagnosticReports` に、11/1〜11/2 の ReadingApp の落ちの記録はありませんでした。あったのは 10/27 の `ReadingAcceptanceTests-Runner` の1件だけです。
- このことから、アプリが落ちたのではなく、テストの実行役の時間切れだった見込みが高いです。xcresult での確かめはしていません。

## 未解決（上の番号で）
- 3（H33）：`book.load`、`recommend.load`、`catalog.lookup`、`storekit.products`、`storekit.purchase` の門と灰の帯がありません。指定すると `waiting` のまま進みません。
- 3（H33 の `store.load`）：読み込み本体は起動の時点で同期で終わるため、門は「画面に渡す所」で止めています。「読み込みに入った所で止める」の厳密な形ではないので、reviewer に判断を頼みたいです（実装ノートの2章）。
- 5（製品の不具合）：
  - S-8b の認識0件で `mark.ocr.none` が出ない件は未着手です。
  - `mark.later.note.empty`、`shelf.load.error`、`scan.hint`、`book.title.invalid`、`camera.denied`、`colophon.capture` は確かめていません。
  - `settings.save` と S-3c の61字は直しましたが、動かして確かめていません。
- 8：ビルドもスクリーンショットもまだです。
- 9：上の表のとおりです。
- 10：xcresult での確かめが残っています。
- 撮影：台本 `/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/shots.sh`（引数は udid、アプリのパス、出力先）と、seed.json を用意しました。まだ動かしていません。シミュレーターは作っていません。
- 7：verifier は、`WidgetAndActivityAcceptanceTests.swift` の末尾の撮影用クラスを `G3EvidenceCaptureTests.swift` に「移す」だけでよいです。pbxproj の編集は要りません。元の場所に残すと、二重定義でビルドが落ちます。
- 仕様の穴：Live Activity の読書中の文「21:04 から読書中」に、design 7 のキーがありません。仮に `liveActivity.readingSince`（「%@ から読書中」／"Reading since %@"）を足しました。designer に決めてもらう必要があります。
- 前からの欠け（今回の範囲外）：
  - アプリの多くの画面が、String Catalog を通さず `AppL10n.pick("ja","en")` で直書きしています。
  - H2、H7、H30 などの `hook.error` は実装がありません。今回は H22 と H33 だけ作りました。
  - ストアの予約の Live Activity は mode `"scheduled"` で作っていて、共有の factory を通っていません。
- W-1 と W-2 の余白は、design の値（W-1 は 0、W-2 は 16pt）を定数にしました。システムの既定の余白と同じかは、G4 の実機で見る必要があります。

## 記録（指揮役が保存するときに書き足す）
- 日付：2026-11-02。BASE 99121e1
- 範囲の確かめ：変更は ios/ の下だけ（ios/AcceptanceTests/ は触っていない）
- 次：残り（3 の門5つ、5、8 のビルド、9 の23件、10、撮影）を2体目の ios-engineer に続けさせる（裁定 20 と同じ、手数の上限での分割）
- 指揮役の追記：1体目が始めた `make ios-test` は終了コード2（Error 65）。AC-142 が約17,498秒止まったあと `Failed to get matching snapshots: Error getting main window kAXErrorServerNotFound` で失敗し、`Restarting after unexpected exit` が2回。ほかのスイートは ja・en とも 0 failures。ログ：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ios-test.log
