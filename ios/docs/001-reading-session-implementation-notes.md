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

## 7. 4体目（BASE 2daf7d6）で足したこと
- W-1・W-2 の読み上げ（AC-99、design/ 6 の W-1・W-2、決まり 53）
  - `VerticalLineLayout.buildWidgetAccessibilityLabel(snapshot:strings:)` を「書名、場所。一行」の書式にした。著者は入れない。一行は `latestLine`（保存した一行）から縦書き用の字形を外して作る（表示用に25字へ縮めた一行ではない）。
  - 文は ReadingCore の `WidgetSpokenStrings`（新しいファイル）で受ける。ReadingCore は String Catalog を持たないので、アプリと拡張は `ReadingWidgetStrings.spoken`（`widget.spoken`、`widget.spoken.noPage`、`widget.spoken.noLine`、`page.spoken`、`location.spoken`、`percent.spoken`、`widget.empty`、`widget.unavailable`、`widget.hidden`、`widget.currentBookAsTitle`）を渡す。`WidgetSpokenStrings.japanese` と `.english` は design/ 7 の値の写しで、単体テストと既定値に使う。
  - 場合の対応：場所あり・一行あり＝`widget.spoken`、場所なし＝`widget.spoken.noPage`、一行なし＝`widget.spoken.noLine`、どちらもなし＝書名だけ、隠す設定＝書名の所が `widget.hidden` で一行を読まない、名無しの今の本＝書名の所が `widget.currentBookAsTitle`、今の本なし＝`widget.empty`。
  - H22（`hook.widget` の `accessibilityLabel` と `renders[].accessibilityLabel`）も同じ関数と同じ文で組む（`SnapshotStore.spokenStrings` を `ReadingAppModel` の起動時に入れる）。これまで書名を2回つないでいた所をやめた。
  - S-5 の `widgetGuide.preview` は `widgetGuide.preview.label`＋W-1 のラベル。S-10a の見本は `store.preview` の1つの要素の中なので、中の W-1 の View が新しいラベルを持つだけ（`store.preview` のラベルは変えていない）。
  - W-3（Live Activity）の文の部分（`liveActivity.banner` の中の、「終える」以外）を1つのラベルにした：待つ状態「書名、61ページ。一行」、読書中「書名、22:00 から読書中」（`liveActivity.readingSince`）、終えた直後「書名、10分、61ページ」。ContentState に単位がないので、場所は表示の形（`p.`、`位置`/`Loc`、`%`）から読み方を決める。
  - `widget.unavailable`（写しを読めない）の文は `WidgetSpokenStrings.unavailable` に入れたが、拡張は写しを読めないときも空の写しにして `widget.empty` を出している（`ReadingSharedContainer.loadWidgetSnapshot`）。見た目と読み上げを `widget.unavailable` に分けるのは、まだしていない。
- S-8 の `register.footer`
  - 原因の見立て：Text 自身の要素の枠は一番長い行の幅（341pt、親は354pt）になる。監査はその幅で組み直すと行が増えて「Text clipped」と出していた（3体目が `frame(maxWidth:)` と `lineLimit(nil)` を試しても変わらなかったのは、どちらも Text 自身の要素の枠を変えないため）。
  - 直し方：幅いっぱいの枠に `.accessibilityElement(children: .combine)` を付け、枠を1つの要素にした。文は design/ 7 の `register.footer`（String Catalog に足した）にした。これまでの文は design/ と違う文を `AppL10n.pick` で書いていた。
- S-1 の AX5
  - 下端の帯を `VStack` の下から `safeAreaBar(edge: .bottom)`（iOS 26）に替え、帯の自作の背景をやめた。帯の裏に入る中身は OS の端の効果でぼける。
  - design/ 9 の S-1「伏せる案内はスクロール領域の一番下に移す」に合わせ、AX1 以上では `bookmark.flipHint` と `bookmark.flipHint.ebook` をスクロールの一番下に置き、帯は「読み始める」だけにした。

## 8. 5体目（BASE d95c86b）で足したこと
正本は docs/reviews/001-reading-session-G3-tech-lead-contracts-r4.md の「ios-engineer に頼むこと」1〜8 と、最後の「指揮役の裁定」。

### 組み方の関数（H22 の組み方）
- `ReadingCore` の `WidgetLineComposer.compose(family:width:height:rawLine:pageText:)`（ios/ReadingKit/Sources/ReadingCore/WidgetComposition.swift）。nonisolated の純粋な関数で、SwiftUI と WidgetKit は import しない。
- 記号の値（i、B、g、R、字の大きさの始めと下限、列の間 0.25s、場所の行 16）は `WidgetCompositionConstants.of(_:)` の1か所だけ。アプリの `ReadingWidgetMetrics` はそれを `EdgeInsets`、`CGFloat` に直すだけ。
- 手順は契約の1〜5どおり。送ったあとの列の数で入るかを見る。列の数に上限を付けない。下限でも入らなければ送らずに組んで `kinsokuRelaxed = true`。`feedCount` は1字送るごとに1。`referenceL` はかな「あ」25字を同じ枠で組んだ L。
- 横書き（AC-30）は手順1だけで、`composition` は `orientation`、`displayedLine`、`shortened`（と `page`）だけを書く（`WidgetLineComposition.encode(to:)` が升目の9項目をキーごと書かない）。
- 前の `VerticalLineLayout.composeWidget`、`H22WidgetComposition`、`H22WidgetReadout`、`H22Orientation`、既定の4列×8字（`defaultWidgetMaxColumns`、`defaultWidgetRowsPerColumn`）と、使われていなかった `UITestHookReadoutBuilder.verticalJSON` は消した。`layoutVerticalCells` はアプリの中の帯（BannerNoticeView）用に残し、既定の値を外した。

### View（W-1、W-2）
- `ReadingWidgetSurfaceViews.swift` の `composeFitted` と `ReadingVerticalFit` を消した。W-1・W-2 の View は描く大きさで `WidgetLineComposer.compose` を呼び、結果の `cells[].x`・`y`・`fontSize` を `ReadingVerticalGlyphLayer` でそのまま描く（枠の左上に重ねる overlay。View の側で字の大きさや列を決め直さない）。
- 状態は `WidgetRenderStateResolver`（ReadingCore）で決める。拡張と見本は同じ関数を使う。

### 写しを読めないとき（unavailable）
- `WidgetSnapshotReader.read(fileURL:)`／`read(data:)`（ReadingCore）で読む。ファイルなし `missing`、開けない `unopenable`、JSON・型の誤り `malformed`、版 `version`、範囲の外 `range`、隠す設定なのに一行がある `hiddenConflict`。
- 拡張は `ReadingSharedContainer.readWidgetSnapshot()` を使い、`ReadingWidgetTimelineEntry.unavailableReason` を View に渡して `widget.unavailable` を出す（読み上げも同じ文）。これまでは読めない写しも `widget.empty` にしていた。
- `UITEST_WIDGET_SNAPSHOT`（`@missing` か写しの文字列）を実装した。`UITestHookCoordinator` が読み、`SnapshotStore.snapshotOverride` に入れる。読み出しの `snapshotSource` は `override` になる。

### hook.widget の読み出し（h22 スキーマ）
- トップは `outputVersion`、`renders`、`reloadRequests`（と `-uitest-widget-show` のときの `showcase`）だけ。
- render は `request{family,width,height}`、`seq`、`producedAt`、`snapshotSource`、`state`、（unavailable のとき）`unavailableReason`、`url`、`appearanceID`、`accessibility{identifier,label,groupCount}`、`texts`、`timeline{entries,policy,elapsedMs}`、（normal のとき）`composition`。
- `renders[]` ごとに、その request の枠で組む。入力（読んだ写し、request、再読み込みの回数、読み上げの文）が前と同じなら組み直さず、`seq` と `producedAt` は前の値のまま。
- `timeline` は拡張と同じ `WidgetTimelinePlan.make(now:)`（いまの1件、`never`）。`elapsedMs` は写しを読んでから render を返すまでの実時間（ContinuousClock）。
- `-uitest-widget` の1つが読めない（ファミリーが2つ以外、幅や高さが 0 以下か数でない）ときは `hook.error`（`H22:<その1つ>`）。

### 再読み込みの出どころ（指揮役の裁定 (B)）
- `book.switch`・`book.finish` → `book.status`、`book.setTitle` → `book.update`、`settings.appearance`・`settings.hideOnWidgets` → `settings.save`。
- `store.purchase`、`store.restore`、`store.entitlement`、`store.refund` は `settings.save` で、`reloadOnlyIfChanged: true` を付けた。写し（updatedAt を除く）が変わらないときは再読み込みを求めない。購入・復元で見本の見た目（`previewAppearanceID`）が設定に入るときと、返金で見た目を標準に戻すときだけ数える。

### 受け入れテストで落ちたもの（テストは直していない）
- AC-99 と AC-140 は、`readHookJSON("hook.widget")` で読んだ辞書を `"\(widget)"` で文字列にしてから書名を探す。Foundation の辞書の説明では、入れ子の辞書の中の日本語は `\U7f85` の形に書き換わる。そのため、トップの `title` がなくなると、書名が `renders[].accessibility.label` と `texts` にあっても見つからない。h22 のトップは `additionalProperties: false` なので、アプリの側でトップに書名を戻せない。verifier が `readHookString` で読む形にする必要がある。

## 9. 6体目（BASE d204eac）で足したこと

### 写しのファイル `widget-snapshot.json` を契約の形にした（G3 r2 の指揮役の裁定 4：契約が正）
- 型（`ReadingCore/ContractModels.swift`）：`WidgetSnapshot{schemaVersion, hideOnWidgets, appearanceID, currentBook?}`、`WidgetSnapshotBook{title?, isTitlePending(真のときだけ書く), line?, progress?}`、`WidgetSnapshotProgress{unit, value}`。前の `version`、`updatedAt`、本の `id`、`author`、`progressUnit`、`progressDisplay`、`latestLine`、`latestLineId` はなくした（PRD 12：ISBN、著者、本の id、日時を書かない）。
- 書く側（`SnapshotStore.makeSnapshot(currentBook:settings:)`、`writeSnapshot` はこれを書くだけ）
  - hidden のときは `progress` だけ。書名、一行、名無しの本フラグ、「しおり」の文字も書かない（ロック中にも読める写しのプライバシー）。
  - 名無しの今の本は `title` を書かず `isTitlePending: true`。
  - 一行は縮めない全文（前は25字に縮めて書いていた）。25字への縮め方は描くときに `WidgetLineComposer` が行う。
  - 範囲の外の値（書名 1〜100 字、一行 1〜60 字、進み具合の単位ごとの範囲）は、読む側が読めなくなるのでキーごと書かない。
  - 書き方は契約どおり `Data.write(options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])`（iOS）。null は書かない。
- 読む側（`WidgetSnapshotReader`。拡張、H22 の読み出し、撮影用の見本が同じ関数）
  - (3) JSON でない・型が違う・必須がない → `malformed`。(4) `schemaVersion` が 1 でない → `version`。(5) 範囲の外、知らない単位 → `range`。(6) hidden なのに書名・一行・isTitlePending → `hiddenConflict`。(7) 名無しなのに書名 → `malformed`（G3 r2 の裁定 3）。知らない項目は読み流し、知らない `appearanceID` は default。
  - 書名がなく名無しの印もない今の本は、契約の (3)〜(7) に当たらないので読める。書名の所は `widget.currentBookAsTitle` の文にする（契約の「出し方」）。前は「しおり」を出していた。
- 前の版の形のファイル（`version` を持ち `schemaVersion` がない）：契約に移行の決まりはない。落ちず、`unavailable(version)` として読めないものにする。アプリは起動のたびに写しを書き直すので、次に書くまでの間だけ。`SnapshotStore.init` も前の形を読まず、今の本なしから始める。
- 進み具合の短い形は写しに書かず、描くときに `page.short`、`location.short`、`percent.short`（design/ 7。String Catalog に足した）で作る（`WidgetSpokenStrings.progressText`）。英語のときは `Loc 1450`（前は英語でも「位置1450」）。
- 読み上げのラベルの一行は、写しの全文を25字に縮めたもの（ウィジェットに描く一行と同じ。前と同じ文）。W-3 の待つ状態の一行も同じに縮める。
- W-5 の拡張の外の読み方（`ReadingSharedContainer.loadWidgetSnapshot`）は `progress{unit,value}` から答える。

### コードの reviewer r1 の提案の直し（指揮役の裁定 4）
- `store.buy` と `settings.restorePurchases`：action の中で `Task` を作る前に、進行中の印（`purchaseInFlight`、`restoreInFlight`）を同期で立て、本物の処理が終わったら下ろす。立っている間の押下は弾く（契約 H33 の「2度押しの印」）。`store.restore`（S-10a）は action が同期なので変えていない。
- `storekit.purchase`・`storekit.restore` の ProgressView：`HeldLoadProgressView`（`LoadingPlaceholderViews.swift`）で、門に止められて 0.3秒（ContinuousClock）を超えてから出し、出したときに `markShown` する。0.3秒までは購入のボタンをそのまま出す。
- `catalog.lookup` を止めている間の2つ目以降の読み取り（S-8a のバーコード）：素通りさせず `queuedCatalogLookups` に待たせ、放したあと1回目の次に来た順に引く。帯は放すまで保つ。
- Background Assets 拡張の `LM_FILTER_WARNINGS = YES`：付けて clean ビルドすると `appintentsmetadataprocessor` に `--quiet-warnings` が渡ったが、`warning: Metadata extraction skipped, no AppIntents.framework dependency found` の1行は消えなかった。指示どおり元に戻した（pbxproj の差分なし）。

### 受け入れテストで落ちたもの（テストは直していない）
- AC-99、AC-140（ja・en）：8 に書いたテストの読み方の不具合のまま。
- AC-141（en だけ。ja は通る）：536行目で `readHookString("hook.widget").contains("位置1450")` を確かめている。契約 H22 は英語の `texts["widget.page"]` を `Loc 1450`、design/ 7 の `location.short` の en も `Loc %lld` と決めている。前は写しに「位置1450」を直書きしていたため、英語でも通っていた。アプリは契約どおりにしたので、テストを言語ごとの値にする直しが要る（verifier）。

## 10. 7体目（BASE 76ff911）で足したこと
英語の設定で日本語が出る所を直した（docs/reviews/001-reading-session-G3-ios-fix-r2f.md の「3.」と指揮役の裁定 4）。

### ReadingStore が組む文をアプリから渡す形に
- `ReadingCore/ReadingStoreStrings.swift` を足した。Siri・ショートカットの答え（`intent.start.started`、`intent.start.alreadyReading`、`session.start.error`、`session.tooShort`、`session.save.error`、`intent.whereStopped.page`/`location`/`percent`/`noPage`/`noCurrent`/`error`）、`duration.minutes`、`result.summary.pages`/`locations`/`percents` の文を持つ。
- パッケージの中には ja・en の文を持たない。既定値は `ReadingStoreStrings.keys`（文言キーの名前そのもの）で、渡し忘れると画面や答えにキーの名前が出る。
- アプリと拡張は `ReadingStoreStrings.localized`（`ReadingApp/Intents/ReadingAppIntents.swift`、両方のターゲットに入る）で String Catalog から組み、`ReadingAppModel.init` とインテントが自分で作る `ReadingDataStore` に入れる。インテントが作る店には `snapshotStore.spokenStrings` も入れる。
- 単体テストの ja・en の写しはテストのターゲットの中だけに置く（`ReadingStoreStringsTests.swift` の `testJapanese`、`testEnglish`）。

### 直した所
- `handleExternalIntent` の `spokenText` と `snippetTexts`：design/ 7 のキーの文にした。答えには書名と一行を入れない（AC-121、決まり 79）。
- `InputValidator.formatProgressDisplay`：`strings: WidgetSpokenStrings` を受け、`page.short`、`location.short`、`percent.short` の書式で組む。英語では `Loc 1450`。アプリの画面（S-1、S-7、S-10a）は `ReadingWidgetStrings.spoken`、店の中は `snapshotStore.spokenStrings` を渡す。
- S-4 の `result.summary`（`latestResultSummary`）：分数は `duration.minutes`、場所の進みは `result.summary.*`。前の場所がない晩の「p.61　18分」の形は design/ 7 にキーがないので、同じ単位の `result.summary.*` の「%2$lld と %3$@ の間」を区切りに使う（ja は全角の空白、en は空白2つ）。
- W-3 の終えた直後の `summaryText`：`duration.minutes` で組み、拡張の `ReadingLiveActivityStateFactory.ended` と同じ「分数 · 場所」の形にした（読み上げのラベルが「 · 」で分けて読むため）。
- String Catalog に design/ 7 のキーを6つ足した：`intent.start.started`、`intent.start.alreadyReading`、`duration.minutes`、`result.summary.pages`、`result.summary.locations`、`result.summary.percents`。
- `WidgetGuideSheetView` の `guideSnapshot(line:)` と `lockWidgetPreview(line:)` から使われない `progress` の引数を消した（それに伴い、使われなくなった `samplePage` も消した）。

### 直していない所（理由）
- `intent.start.noCurrent`（「いま読んでいる本がありません。」）と `intent.end.completed`（「読書を終えました。」）：design/ 7 にキーがないので、前の文のまま。
- Live Activity の `title` の「しおり」：隠す設定のときは、描く側（`ReadingLiveActivityLockScreenView`）が `widget.hidden` に置き換えるので出ない。ただし書名が空の本（名無しの今の本）で隠す設定がオフのときは、本物の Live Activity に「しおり」がそのまま出る（ja でも design/ の `widget.currentBookAsTitle` と違う）。
- `endButtonLabel` の「終える」：受け入れテストの読み出し（hook.liveActivity）にだけ入り、描く側は `liveActivity.end.label` を使うので出ない。契約（hook-config.schema.json）は `liveActivity.end.label` の文と決めているので、値は契約と違う。
- `recordShareCard` の既定の「晩」「分」：`renderedTexts` が渡されない時だけの記録（hook の `shareCards`）で、画面には出ない。
- ショートカットの言い方（`ReadingDataStore.swift` の `${applicationName} …`）、H20 の書誌と出典（`CatalogDatabase.swift`）、AuthorNameFormatter・AwardsCatalog・OCRPipeline・VerticalLineLayout の日本語の照合用の文字：書誌のデータ、出典、照合の規則なので訳さない。

## 11. 8体目（BASE ad13217）で足したこと
designer が決めた文言キー（design/ 7、決定 82〜86）をアプリに入れ、英語のときに日本語が出る残りを直した（docs/reviews/001-reading-session-G3-designer-keys.md）。

### String Catalog
- design/ 7 で足したキー29個を足した：`intent.start.noCurrent`、`intent.end.completed`、`result.summary.{pages,locations,percents}.first`、`result.summary.spoken`、`result.summary.first.spoken`、`liveActivity.ended.summary`、`liveActivity.ended.spoken`、`duration.hoursMinutes`、`duration.hours`、`next.reason.*`（6）、`rec.reason.*`（5）、`book.total`、`reading.startedAt`、`colophon.capture`、複数形の `duration.minutes.spoken`、`duration.hours.spoken`、`book.nights`、置き換え（substitutions）で時と分をそれぞれ複数形にする `duration.hoursMinutes.spoken`。
- 値を design/ 7 にそろえたキー17個：`session.tooShort`、`session.invalidTime`、`session.capped`、`session.start.error`、`session.save.error`、`common.save.error`、`store.load.error`、`book.title.invalid`、`book.author.invalid`、`mark.line.invalid`、`mark.page.invalid`、`record.minutes.invalid`、`store.unavailable`、`store.offline`、`store.purchase.error`、`store.restore.done`、`store.restore.none`。
- 知らせの文（`BannerNoticeView.message(forKey:)`）は、`AppL10n.pick` の直書きをやめ、同じ名前のキーを String Catalog から引く。

### 推薦の理由（決定 85）
- `ReadingCore/RecommendationReasonStrings.swift` を足した。軸と「積読にある本か」の組ごとに1つの書式を持ち、`reason(axis:isOwnedTsundoku:name:)` で文にする。賞やレーベルの名前が空なら nil を返し、その軸を使わない。パッケージの中には ja・en の文を持たず、既定値は `keys`。
- `RecommendationEngine.formatReason` は `String?` を返す。`nextCandidates`、`afterCandidates`、`noCurrentCandidates` に `reasonStrings` を足し、どの軸にも当たらない積読の本は `next.reason.tsundoku`。
- 賞の表示名（`awardDisplayName`）：未所有の本は回や年を前に付ける（「第157回 直木三十五賞」）。積読の本は賞の名前だけ（前と同じ）。
- アプリは `RecommendationReasonStrings.localized`（ReadingAppIntents.swift）を `ReadingDataStore.recommendationReasonStrings` に入れる（ReadingAppModel.init）。

### インテントの声（決定 84）
- `ReadingStoreStrings` に `intentStartNoCurrent`、`intentEndCompleted`、`liveActivityEndLabel`、`liveActivityEndedSummaryFormat`、`resultSummary*FirstFormat` を足した（足した引数は既定値がキーの名前）。日本語の直書きの2か所（今の本なしの「読み始める」、Live Activity の「終える」）はなくなった。

### S-4
- 前の場所がない晩は `result.summary.*.first`（前の版の「区切りを取り出す」作りはやめた）。
- 読み上げは `result.summary.spoken`・`result.summary.first.spoken`・`duration.minutes.spoken` で組む。値は店の `latestResultFigures`（`SessionResultFigures`。見える文字と同時に入れ替える）。「p.」を「ページ」に置き換える作りはやめた。
- `latestResultSummary ?? "15分"` の仮の値をやめた。まとめがなければ `result.summary` を出さない。

### W-3（Live Activity）
- 終えた直後の見える文字は `liveActivity.ended.summary`（店と拡張の `ReadingLiveActivityStateFactory.ended` の両方）。読み上げは `liveActivity.ended.spoken`。そのため `ContentState` に `minutes`（省略可）を足した。
- 書名の所：隠す設定なら `widget.hidden`、名無しの今の本と書名が空の本は `widget.currentBookAsTitle`（前は「しおり」）。H23 の `endButtonLabel` は `liveActivity.end.label` の文。
- 読書中の `liveActivity.readingSince` は前から短い時刻の書式（変えていない）。

### S-2、S-7
- S-2 の `reading.startedAt`：システムの短い時刻の書式。晩をまたいだときは同じキーの `%@` に月日つきの時刻を入れる（design/ 7 に別のキーがないため）。
- S-7 の `book.nights`（複数形）と `book.total`（分のまま）。`book.total` の読み上げの分数は `duration.minutes.spoken`。
- `colophon.capture`（S-7、S-9）はキーで出す（ja「奥付を撮って補う」、en「Scan Colophon」）。

## 12. 9体目と10体目（BASE 1b5d441 → 49fea4c）で足したこと
9体目が途中で止まった作業の木を、10体目が続けて終えた（docs/reviews/001-reading-session-G3-ios-fix-r2i-partial.md）。

### 英語だけの端末で和文が□になる（豆腐）
- 起きていたこと：端末の言語が英語だけのとき、システムの書体（SF Pro）で描く和文（本のデータの書名・著者・出版社と、アプリの文に残っていた「晩」「分」「年」「（）」）が□になった。明朝の custom フォント（`HiraMinProN-W3`、縦書きの一行）は名前で指しているので正しく描けていた。
- 原因：システムの書体の置き換えの一覧（cascade list）が英語の一覧になり、このシミュレーターでは和文に当たる書体がなかった。実機では中国語の書体（PingFang SC）の字形になる見込み［推測。G4 の実機で見る］。どちらも、組みの言語を日本語にすればヒラギノ角ゴに当たる。
- 直し方（書体は同梱しない。文言の言語は変えない）
  - SwiftUI の Text：画面の根（`ReadingApp.swift`）、ウィジェット・Live Activity の View（拡張は別のプロセスなので View ごと）、読み終えのカード（`ImageRenderer`）に `.japaneseTextTypesetting()`（`typesettingLanguage(ja)`、iOS 17）。
  - UIKit が描く文字（`TextField` の中、確認ダイアログ）には SwiftUI の修飾子が届かない。S-7a の欄が□のままだったので、窓の trait（`window.traitOverrides.typesettingLanguage`、`UIMutableTraits`、iOS 17）を日本語にする `JapaneseWindowTypesettingInstaller`（`ReadingApp.swift`）を足した。シートと確認ダイアログは同じ窓に出るので受け継ぐ。上書きしていない trait を読むと UIKit の assert で落ちるので、読まずに入れる。
  - ナビゲーションバーの題には窓の trait も届かなかった（S-7 の題「羅生門」が□のまま）。S-7 だけは題が本のデータなので、`ToolbarItem(placement: .principal)` に SwiftUI の `Text` を置いて和文の組みを当てた（`navigationTitle` は戻るボタンと読み上げのために残す）。ほかの画面の題はアプリの文で、本のデータを入れていない。
- 撮影：Japanese のデータ（`G3_VARIANT=light`）を English (en) の構成で撮る（10体目の scratchpad r10）。

### 本のデータを言語ごとの文に（`BookTextFormat`、ThemeTokens.swift）
- `publisherWithLabel`（`colophon.publisher.withLabel`）、`publishedYear`（`colophon.year.value`）、`nights`（`book.nights`）、`finishReflection`（`finish.reflection.single` / `.multi`、括弧の中は `duration.hoursMinutes` / `duration.hours`）、`nightDayText`（晩の月日。読み上げと S-7b は「10月16日」、S-7 の見える行は「10/16」。決定 60）。
- `ReadingDataStore.buildFinishReflection` は `buildFinishReflectionSummary`（数だけを返す）に替えた。文は S-9・S-7 が組む。
- S-9 の `finish.summary`（「3晩、83分」）：design/ 7 に組み合わせのキーがないので、`book.nights` と `duration.minutes` をシステムの並べ方の書式（`.list(type: .and, width: .narrow)`）で並べる。
- S-7 の記録の行：見える文字は「10/16」と `duration.minutes`、読み上げは `book.record.spoken` と `duration.minutes.spoken`、`accessibilityInputLabels` に見える文字（決定 60）。前は「2026-10-16」と「18分」の直書きだった。
- S-7b：`record.night`（「10月16日の晩」）。前は「読んだ晩」と「2026-10-16」。
- S-7 の題：名無しの今の本は `widget.currentBookAsTitle`、本が読めないときは空（前は「本」の直書き）。
- 読み終えのカード（画像と H24 の記録）：`book.nights` と `duration.minutes`。
- S-8c の書誌候補の補足（著者・出版社・レーベル）：「・」の直書きをやめ、システムの並べ方の書式。

### 推薦（8体目の未解決7）
- `RecommendationEngine.afterCandidates` は、本棚が空のとき「コンビニ人間」を起点の本にしていた。S-7 は本棚にある本からしか開かないので画面には出ないが、決まった本を起点にした候補を作らないよう、本棚が空なら候補0件にした（単体テスト `afterCandidatesEmptyShelfReturnsNothing`）。

### `AppL10n.pick` の残り
- design/ 7 に文がある所は移した（S-9 の11か所は9体目、S-7 の題と S-7b の晩は10体目）。残りは design/ 7 に文がないので移していない（文は作らない）。一覧は10体目の報告の「未解決」。

## 13. 11体目（BASE 642cdba）で直したこと（G3 verifier r3 の指摘と裁定 30）

### AC-91：`common.save.error` が S-7a・S-7b で2つ
- 原因：S-7（`BookDetailView`）の帯 `BannerNoticeView(model:)` と、シート（S-7a・S-7b・S-7c）の帯が同じ `store.activeErrorKey` を見て両方出ていた。iOS 26 の iPhone のシートは下の画面を縮めないので、下の S-7 の帯もシートの帯とほぼ同じ位置（7pt 上）にあり、XCUITest の木にも残った。S-7 自体の保存（`book.status`、`book.delete`）と S-8c・S-3b は、下に帯を出す画面がないので1つだった。
- 直し方：シートを出している間は、下の画面（S-7 と S-9）の帯を出さない（`detailSheet == nil`、S-9 は2つのシートが閉じているとき）。帯はシートの中の1つだけになる。

### S-7a・S-3c の欄の値
- S-7a：書名・著者の欄は今の本の値で始まる（名無しの今の本の書名と、著者が空の本の著者は空で始まる。design/ 5）。placeholder は欄の名前のキー（`book.edit.title`、`book.edit.author`）。保存は欄の値をそのまま渡し、書名が空なら `book.title.invalid`、著者が空なら著者なしで保存する（前は空なら前の値を残していた）。
- S-3c：選んだ列の文を `mark.lineField` の値にする（列を選び直すと替わる）。placeholder は `mark.line.placeholder`。保存は欄の値（空なら `mark.line.invalid`）。
  - 欄に値が入ったあと最初に欄に触れたときは、文の全体を選ぶ（`TextField(_:text:selection:axis:)` と `TextSelection`、iOS 18）。打てば置き換わり、もう一度押せば字の間に入って直せる。AC-67 の「手で直す」を、文の全体を打ち直す形でも、1字だけ直す形でもできるようにするため。design/ にこの決めはないので、designer に確かめてもらう。

### W-1・W-2 の縦書きの字が1字ずつ要素に出る（AC-99、H22）
- 原因：`.accessibilityElement(children: .ignore)` と、字の層の `.accessibilityHidden(true)` を付けても、SwiftUI は中の `Text` を XCUITest の木（とアクセシビリティ監査）に子として出していた。
- 直し方：W-1・W-2 の View の全体を `accessibilityRepresentation`（iOS 15）で、文字を描かない要素（`Color.clear` にラベルと識別子）1つに置き換える（`widgetSingleAccessibilityElement`）。表し方を `Text` にすると、監査がその見えない文を「Text clipped」と数えたため。拡張とアプリの見本（H22、S-5、S-10a）は同じ View の型なので両方に効く。`hook.widget` の `accessibility.groupCount` は、この作りで常に1つ。

### H33 の `storekit.restore` が `held` のまま
- 原因：S-10 の復元の `HeldLoadProgressView` は中身が `EmptyView` で、`Group` に付けた `.task(id:)` が動かなかった（描くものがない View の修飾子は動かない）。ほかの7つは中身があった。
- 直し方：`HeldLoadProgressView` に大きさ0の `Color.clear` を常に置き、`.task` がいつも動くようにした。S-10 の HStack の間は ProgressView の側で取る（出していない間にボタンの幅を削らない）。

### AX5 の `hook.widget.canvas` の frame（H22）
- 原因：枠は `.frame(width:height:)` で実寸だったが、XCUITest の要素の frame は子の要素を合わせた大きさになり、大きい文字で中身が枠を超えると枠より大きく出た（systemSmall 171.67、liveActivity 191）。
- 直し方：枠を動かないスクロールの入れ物（`ScrollView` と `.scrollDisabled(true)`）にした。入れ物は自分の大きさを要素の frame に持つ。固定の面は枠の高さで、中身に合わせる面は中身の高さで描き、はみ出した分は枠で切る。

### AX5 の S-1 で伏せる案内が下端で半分切れる
- 原因：大きい文字では伏せる案内をスクロールの一番下に置く（design/ 9）。中身が画面より長く、`safeAreaBar` の「読み始める」の帯の下（ホームインジケーターの帯）に、スクロールの中身の伏せる案内の行が半分だけ透けて見えた。
- 直し方：S-1 のスクロールの下端の端の効果を、システムのはっきりした形（`.scrollEdgeEffectStyle(.hard, for: .bottom)`、iOS 26）にした。帯に自作の背景は付けない。`safeAreaBar` は中身の下に帯の分の余白を足すので、一番下まで送れば案内は帯の上に出る見込み［推測。一番下まで送った画面は撮っていない］。

## 14. 12体目と13体目（BASE d7d7a8e → c584c9e）で合わせたこと（designer の決定 87〜96、裁定 35〜39）
- 文言：`AppL10n`（言語の引数を見て日英を選ぶ仮の仕組み）を消し、画面の文字はすべて String Catalog のキーから出す（`AppL10n.pick` 0か所）。決定 87〜96 の新しいキー19個を ja・en で入れ、`mark.ocr.none`・`shelf.load.error`・`book.load.error` は見出し（`*.title`）と文に分けた。
- 識別子の改名：`shareCard.*` → `finish.card.close`／`finish.card.canvas`／`finish.card.shareImage`、`colophon.ocr.pickPhoto` → `colophon.pickPhoto`、`store.purchasedBadge` → `store.purchased`。`bookmark.line.empty` は使わない（一行も場所もないときだけ `bookmark.noMark.message`）。
- AC-84（裁定 36）：H24 の記録は S-9 の `finish.card.share` を押した時点で行う（`FinishNightView` の `shareCardButtonSection`）。S-9a のシートはそのあと開く見本で、記録の時点は変えていない。
- 大きい文字（決定 93）：`SheetHeaderBar` は accessibility1 以上で題を描かず、題は内容の先頭の `SheetContentTitle`（`.headline`、見出しトレイト）が出す。進み具合の単位は `progressUnitPickerStyle()`（accessibility1 以上は `.inline`）。S-1 のスクロールの下に `space.16` を足した。
- 1つの要素（決定 94）：S-1 の縦書きの一行、S-5・S-10a の見本は `singleAccessibilityElement`（`accessibilityRepresentation`）で1つの要素にする。
- S-9 の `finish.summary`（何晩・合計分）は出さない（決定 89）。帯の題も出さず、`finish.title` は内容に1回。
- S-10a の今の本なし：仮の本（書名・著者・p.61）を描かず、見本の一行 `store.preview.sample.line` と注記 `store.preview.sample.note` だけ（決定 88）。
- 残り：S-7c の「写す」（`colophon.shutter`）とカメラの面は作っていない。S-3c・S-8b の「写す」も実際のカメラで撮る作りがなく、H23 の読み取りの設定だけを読む（Release では常に0文字になる）。S-8c に `manual.isEbook` と単位の切り替えがない。どれも決定 87〜96 の範囲の外で、報告で上げた。
