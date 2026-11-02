# 001-reading-session 実装ノート（ios-engineer、G3 r2 の直し）

BASE 99121e1。正本の一覧は docs/reviews/001-reading-session-G3-tech-lead-contracts-fix.md の最後の節。

## 1. H22 の見本の `viewType` に出る型の名前
W-1〜W-5 の View は ios/ReadingApp/Shared/ReadingWidgetSurfaceViews.swift の1つのファイルにあり、このファイルはアプリ（ReadingApp）と拡張（ReadingWidgetExtension）の両方のターゲットに入る（project.pbxproj の A10000F0… と A20000F0…）。

| 面 | `viewType` | 拡張で使う所 |
|---|---|---|
| `accessoryRectangular` | `ReadingLockScreenWidgetView` | `ReadingLockScreenWidgetEntryView`（ReadingWidgets.swift）が GeometryReader の大きさと `ReadingWidgetMetrics.lockScreenContentMargins` を渡す |
| `systemSmall` | `ReadingHomeSmallWidgetView` | `ReadingHomeSmallWidgetEntryView`（同）が大きさと `ReadingWidgetMetrics.homeSmallContentMargins` を渡す |
| `liveActivity` | `ReadingLiveActivityLockScreenView` | `ReadingLiveActivityWidget` の `ActivityConfiguration` が `Button(intent: EndReadingFromActivityIntent()) { label }` を渡す。見本は `Button(action: {}) { label }` |
| `control` | `ReadingControlLabelView` | `ReadingControlWidget` の `ControlWidgetButton` のラベル |
| `snippet` | `WhereStoppedSnippetView` | `WhereStoppedIntent.perform()` の `ShowsSnippetView`。文は `WhereStoppedIntent.formatResponse(for:)` |

照らし方：`grep -n 'struct ReadingLockScreenWidgetView\|struct ReadingHomeSmallWidgetView\|struct ReadingLiveActivityLockScreenView\|struct ReadingControlLabelView\|struct WhereStoppedSnippetView' ios/`

余白：W-1 と W-2 の `Widget` に `.contentMarginsDisabled()` を付け、余白は View の `padding` で持つ。値は design/001-reading-session/screens.md の W-1「内側の余白は 0」、W-2「内側 16pt」を定数にした（見本と拡張で同じ値）。W-1 の `accessoryInline` と `accessoryCircular` は `@Environment(\.widgetContentMargins)` の値をそのまま渡す。システムの既定の余白と同じかは G4 の実機で見る（ADR 0005 の追記）。

## 2. H33 の門
- 型：`LoadHoldGate`（ios/ReadingKit/Sources/ReadingStore/LoadHoldGate.swift。`#if` なし。`ReadingDataStore.loadGate` が持つ）。
- 門の関数：`LoadHoldGate.pass(_:)`（既定は止める対象が空で、すぐ返る）。
- 状態を読む関数：`willHold(_:)`、`isHolding(_:)`、`markShown(_:)`。
- 設定する関数：`arm(_:)`、`release(_:)`。呼ぶのは ios/ReadingApp/UITestHooks/UITestHookCoordinator.swift の `configureLoadHold(store:args:)` と `yomuma.uitest.load.release` の受け口だけ（どちらも `#if UITEST_HOOKS` の中）。
- `hold.<対象>` は ios/ReadingApp/UITestHooks/UITestHookReadoutBuilder.swift の `stateJSON` で `hook.state` に足す。
- Package.swift に define は足していない。名前は `UITestHook` で始めない（nm の検査の対象外）。Release の nm で `LoadHoldGate` の記号が残ることを確かめた（門は Release に残る。設定する入口は残らない）。
- 0.3秒は `GatedLoadView`（ios/ReadingApp/Views/LoadingPlaceholderViews.swift）で `ContinuousClock` で数える。

### 門を置いた所と、まだ置いていない所
| 対象 | 状態 |
|---|---|
| `store.load` | 置いた。`ContentView.gatedMainAppContent`。読み込みのデータは起動の時点で読み終えており、門は「画面に渡す所」で止める（下の注意）。止めている間 `hook.store` は空 |
| `shelf.load` | 置いた。`ShelfView.body` を `GatedLoadView` で包み、灰の帯5行 |
| `storekit.restore` | 置いた。S-10 の `settings.restorePurchases` の押下で `pass` を待ち、横に ProgressView |
| `book.load` | 置いた（2体目）。S-7 の記録の節を `GatedLoadView` で包み、行の形の灰の帯3行 |
| `recommend.load` | 置いた（2体目）。S-9 の候補の節（`gatedCandidatesSection`）を包み、行の形の灰の帯3行 |
| `storekit.products` | 置いた（2体目）。S-10a の `store.buy` の位置を包み、ProgressView |
| `storekit.purchase` | 置いた（2体目）。`store.buy` の押下で `pass` を待ち、止めている間はボタンの位置に ProgressView |
| `catalog.lookup` | 置いた（3体目）。`BookAddFlowSheetView.runCatalogLookup`：S-8a のバーコードの1件（`appendScannedRow`）と S-8c の書名の候補（`manual.title` の入力）で `pass` を待つ。0.3秒を超えたら一覧・候補の位置に `RedactedRowListView`（S-8a は1行、S-8c は3行）。止めている間は `scan.hint` と `search.noResults` を出さない。S-8c は止めている間の入力で引き直さず、放したあとに最新の入力で1回引く |

注意：`store.load` の読み込み本体（`loadFromDisk()`、`seedFromJSON`）は起動の `init` で同期に動くため、門はその後の画面の切り替えで止めている。H7 `store.load` を一緒に付けた場合は、放したあとに S-1 のエラーが出る（見た目は契約どおり）が、「読み込みに入った所で止める」の厳密な形ではない。reviewer に判断を頼む。

## 3. `ReadingAcceptanceTests` の同期フォルダ
- `ReadingAcceptanceTests` のターゲットを `PBXFileSystemSynchronizedRootGroup`（`AcceptanceTests` フォルダ）にした。objectVersion を 77 にした。
- `AcceptanceTests.xctestplan` は `membershipExceptions` で外した（スキームが参照するだけで、テストのバンドルには入れない）。
- これで ios/AcceptanceTests/ に Swift ファイルを足すと、ターゲットに自動で入る。verifier は `WidgetAndActivityAcceptanceTests.swift` の末尾の撮影用のクラスを `ios/AcceptanceTests/G3EvidenceCaptureTests.swift` に移すだけでよい（project.pbxproj の編集は要らない）。同じクラスを2つのファイルに残すと、二重定義でビルドが落ちる。

## 4. hook.error
契約 1-6 の `hook.error` は、これまで実装がなかった。H22（見本の指定の誤り、`liveActivity.ended.noRecord`、今の本がないときの `waiting`/`reading`）と H33（知らない対象）だけ、`UITestHookCoordinator.hookErrorValue` と `UITestHookErrorView` で出す。ほかのつなぎ口（H2、H7、H30 など）の `hook.error` はまだない。

## 5. 2体目（BASE 14737ca）で足したこと
- AC-142 の約17,498秒の停止：原因は Mac の眠り。`pmset -g log` に `2026-11-02 02:34:23 Sleep Entering Sleep state due to 'Low Power Sleep'` と `07:25:04 Wake from Hibernate ... due to acattach/UserActivity` があり、AC-142 の起動（02:34:21）と失敗（起動から17,469秒＝07:25頃）に重なる。単独で `-test-iterations 3` を ja・en で動かして6回とも成功（ログ：スクラッチパッドの g3fix/ac142-iter.log）。長いテストは `caffeinate -dims` を付け、電源につないで動かす。
- 警告：`BookRegistrationViews.swift` の PhotosPicker のラベル（Sendable の閉包で main actor の `palette` を読んでいた）を、閉包の外で作る `PhotosPickerThemedLabel` にした。プロジェクトの3つの構成に `COPY_PHASE_STRIP = NO`（Xcode のひな形と同じ。拡張の埋め込みの「not stripping binary」警告）。`BackgroundAssetsHandler.swift` に `import ExtensionFoundation`。Background Assets 拡張の埋め込み先が `ReadingApp.app/ReadingApp.app/Extensions` と二重になっていたのを、`dstSubfolderSpec = 16`（Products Directory）で `ReadingApp.app/Extensions` に直した。
- 残る1行：`appintentsmetadataprocessor ... warning: Metadata extraction skipped, no AppIntents.framework dependency found`（ReadingBackgroundAssetsExtension の ExtractAppIntentsMetadata の道具のログ）。コンパイラの警告ではないが、消す設定は確かめていない。
- design 5 との食い違い：S-3 の `mark.later.note.empty`（識別子を前のしおりの有無で切り替え、en の文を design 7 に）、S-6 の `shelf.load.error`／`shelf.retry`（`ShelfListViewState.loadError`、Preview「S-6/loadError」「S-6/empty」）、S-8a の `scan.hint`、S-8b の保存で書名が空・101字以上なら `book.title.invalid`（先頭の候補で黙って埋めるのをやめた）、S-8b の0件を `ContentUnavailableView`（`mark.ocr.none`、`cover.retake`、`register.manual`）、S-7 の `colophon.capture` を常に出す（screens.md の S-7 の例は奥付がそろった本でもボタンを出している）、S-7c にカメラ拒否の `camera.denied`／`camera.openSettings`（S-7 と S-9 の両方から開く）。

## 6. 3体目（BASE 563aa31）で足したこと
- H33 の `catalog.lookup`：上の2章の表。門が素通りのとき（Release とふつうの起動）は、これまでと同じに同期で引き、待ちを足さない。
- 監査（`G3EvidenceCaptureTests/test_G3_accessibilityAudit`、ja、light）を直す前と後で動かした。
  - `mark.lineField`（S-3a、S-3c）と `mark.pageField`（S-3a、S-3b）を `TextField(axis: .vertical)` にした（`lineLimit(1...6)`、`1...3`）。大きい文字でプレースホルダーと値が欄の幅を超えて横に切れていた（Text clipped）。改行は `onChange` で取り除く（一行と場所は1行の値）。
  - S-5 の `widgetGuide.preview` を、拡張と同じ `ReadingLockScreenWidgetView` を 172×76 pt で描く形にした（design/ 3 の S-5「W-1 と同じ縦書き描画」）。写しは `snapshotStore.currentSnapshot`（隠す設定・場所なしも W-1 と同じ）。読み上げを design/ 3 の「ロック画面での見え方。」＋W-1 のラベルにした。
  - S-10a の `store.preview` の中の W-1 の縮小見本を、同じ `ReadingLockScreenWidgetView`（選んだ見た目の色）にした（design/ 3 の S-10a「W-1 の縮小見本」）。
  - W-1・W-2 と、その見本（S-5、S-10a）の縦書きの各字は、design/ 9 の `type.book.line.widget.rectangular`（17/15pt 固定）と ADR 0003 の収め方で大きさを固定しているため、監査の「Dynamic Type font sizes are unsupported」が残る。直すには design/ と ADR の判断が要る。
- `RedactedRowListView`（LoadingPlaceholderViews.swift）を足し、`RedactedRowsPlaceholderView` はそれを使う形にした。
