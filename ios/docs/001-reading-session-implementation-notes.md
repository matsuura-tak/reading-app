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
| `book.load`、`recommend.load`、`catalog.lookup`、`storekit.products`、`storekit.purchase` | 未実装。`-uitest-hold-load` に書くと `waiting` のまま進まない |

注意：`store.load` の読み込み本体（`loadFromDisk()`、`seedFromJSON`）は起動の `init` で同期に動くため、門はその後の画面の切り替えで止めている。H7 `store.load` を一緒に付けた場合は、放したあとに S-1 のエラーが出る（見た目は契約どおり）が、「読み込みに入った所で止める」の厳密な形ではない。reviewer に判断を頼む。

## 3. `ReadingAcceptanceTests` の同期フォルダ
- `ReadingAcceptanceTests` のターゲットを `PBXFileSystemSynchronizedRootGroup`（`AcceptanceTests` フォルダ）にした。objectVersion を 77 にした。
- `AcceptanceTests.xctestplan` は `membershipExceptions` で外した（スキームが参照するだけで、テストのバンドルには入れない）。
- これで ios/AcceptanceTests/ に Swift ファイルを足すと、ターゲットに自動で入る。verifier は `WidgetAndActivityAcceptanceTests.swift` の末尾の撮影用のクラスを `ios/AcceptanceTests/G3EvidenceCaptureTests.swift` に移すだけでよい（project.pbxproj の編集は要らない）。同じクラスを2つのファイルに残すと、二重定義でビルドが落ちる。

## 4. hook.error
契約 1-6 の `hook.error` は、これまで実装がなかった。H22（見本の指定の誤り、`liveActivity.ended.noRecord`、今の本がないときの `waiting`/`reading`）と H33（知らない対象）だけ、`UITestHookCoordinator.hookErrorValue` と `UITestHookErrorView` で出す。ほかのつなぎ口（H2、H7、H30 など）の `hook.error` はまだない。
