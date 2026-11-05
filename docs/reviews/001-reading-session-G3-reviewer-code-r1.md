# 001-reading-session G3 r2 コードの判定 reviewer r1

PASS

## 指摘

### 要修正
- **要修正 / H22 の読み出しと拡張の描画の食い違い** — `ios/ReadingApp/Shared/ReadingWidgetSurfaceViews.swift:169-191`（`composeFitted`）、`ios/ReadingKit/Sources/ReadingStore/SnapshotStore.swift:283-284`（`buildComposition`）。拡張と見本は枠の大きさから `ReadingVerticalFit.fit` で列数・1列の字数を決め直して描く（172×76・17pt なら 4列×4字）が、H22 の `hook.widget.renders[].composition` は枠を使わない既定（`defaultWidgetMaxColumns = 4`、`defaultWidgetRowsPerColumn = 8` → 2列×8字）のまま。BASE（fc844a7）では拡張が `composeWidget(snapshot:)` の既定をそのまま描いていたので一致していた（`git show fc844a7:ios/ReadingWidgetExtension/ReadingWidgets.swift:90,191`）。根拠：contracts/test-hooks.md H22「読めるもの：ファミリーと枠を選んで組んだ結果…縦書きの組み方の結果」、H22 撮影用の見本「読み出しと画像が食い違えば、それ自体が不具合」。欠け0字（AC-27、AC-35）は字の集合が同じなので保たれるが、`cells[].column/row` と禁則の位置（AC-28 の L）は本物の W-1・W-2 を表さなくなった。直す方向：`ReadingVerticalFit`（純粋な計算）を ReadingCore に移し、`SnapshotStore.fullHookPayload` が `spec.size` から同じ定数（帯 43pt、間 4pt、余白、17→13 / 20→13pt）で `maxColumns`・`rowsPerColumn` を求めて `renders[]` ごとに組む。必要なら h22 スキーマに `fontSize` を足す（tech-lead）。
- **要修正（契約の文言との差。受け入れは指揮役の裁定で可）/ H33 の門の置き場所** — `ios/ReadingApp/Views/LoadingPlaceholderViews.swift:6-53`（`GatedLoadView`）、`ios/ReadingApp/Views/BookRegistrationViews.swift:759-784`（`runCatalogLookup`）、`ios/ReadingApp/Views/SettingsAndStoreViews.swift:335-340,668-671`、`ios/ReadingApp/ContentView.swift:52-58`。契約 H33「本番」は「止める門は、`ReadingStore` の読み込みの関数（`store.load`…`storekit.*` の入口）に、実行時の門として置く」と書くが、`LoadHoldGate.pass` を呼ぶ所は ReadingStore に0件（`git grep 'loadGate\|LoadHoldGate'` で ReadingDataStore.swift は `public let loadGate` の宣言のみ）。守れている点：型は ReadingStore に `#if` なし（契約 1-1 の例外）、既定は素通り（`pass` は `armed.remove` が nil なら即 return）、`arm`/`release`/`hold.<対象>` は `UITestHooks/` の `#if UITEST_HOOKS` の中だけ、名前は `UITestHook` で始まらない、Package.swift の define なし。守れていない点：`store.load` は `applyLaunchConfiguration` で同期に読み終えたあと「画面に渡す所」で止め、`hook.store` は読み出し側で空にしている（`UITestHookReadoutBuilder.swift:27-29`）。観察できる振る舞い（`hold.*` の相、`hook.store` 空、0.3秒の帯、放したあとの S-1 のエラー）は契約どおり。直す方向：契約の文を「読み込みの関数、または読み込んだ結果を画面に渡す所」に広げる（tech-lead）か、`loadFromDisk`/`searchByTitleOrAuthor`/`purchasePlus`/`restorePurchases` を async にして中で `pass` を待つ。

### 提案
- `SettingsAndStoreViews.swift:347-354,659-666`：`storekit.restore`・`storekit.purchase` の ProgressView は止めた瞬間に出て 0.3秒後に `markShown` する。契約 H33「0.3秒を超えたら…読み込み中の形を出し」とは順が逆（止めたときだけの話で、ふつうの起動には影響なし）。
- `SettingsAndStoreViews.swift:668-676`：`store.buy` の action が `Task {}` になったため、Task が走る前の2度押しで `purchasePlus()` が2回呼ばれ得る（止めていないとき）。AC-61 の対象外だが、`storePurchaseAttempts` が2つ増える。押したら即 `disabled` にするか、進行中フラグで弾く。
- `BookRegistrationViews.swift:759-784`：`catalog.lookup` を止めている間に2つ目のバーコードが来ると、2回目の `pass` は素通りして `catalogLookupPending = false` にし、1回目を止めたまま帯が消える（止めているときだけの端）。
- 既存 / `SnapshotStore.swift:320-347`（blame 64d24cea 2026-10-27、bc15b693 2026-10-26。BASE より前）：H22 の `texts["widget.title"]`・`texts["widget.empty"]` が「しおり」「いま読んでいる本はありません」の直書き。契約 H22 は名無しの今の本で `widget.currentBookAsTitle` の文、design/ 7 の `widget.empty` は「今の本を選ぶと、ここに続きの一行が出ます。」。拡張の描画と読み上げは String Catalog を通っていて英語で日本語は出ない（`ReadingWidgetStrings`、`SnapshotStore.spokenStrings`）が、読み出しの `texts` だけ設計とずれる。`spokenStrings` を `texts` にも使えば数行で直る。次の直しでまとめてよい。
- 既存 / `AppL10n.pick` の直書き：HEAD 285 か所（BASE 289）。言語で分けているので英語に日本語は混ざらないが、design/ 7 と値がずれる（例：`Localizable.xcstrings` の `common.save.error`「保存できませんでした。もう一度お試しください。」≠ design/ 7「保存できませんでした。変更は反映されていません。もう一度試してください。」、`colophon.capture` en「Scan Colophon to Complete」≠「Scan Colophon」）。別の作業として移行を頼む。
- 既存 / `ios/ReadingApp/Theme/ThemeTokens.swift:22-34` `loadWidgetSnapshot`：写しが読めないときも空の写しを返すため `widget.unavailable`（design/ 5 の W-1 の行、design/ 6 の W-1・W-2 の行）の状態がない。AC にはない（PRD に `widget.unavailable` は0件）。
- design/ 7 にキーがない文：`liveActivity.readingSince`（「%@ から読書中」。design/ 6 は「22時0分から読書中」）、`common.loading`。designer / design-reviewer r2 で決める。
- `ios/ReadingWidgetExtension/ReadingWidgets.swift:122`：Control の `.description` を消した。design/ にその文のキーはないので差し支えないが、意図したか確認。
- verifier の範囲：`build-for-testing` で `ios/AcceptanceTests/` に警告 3,324行（main actor の `tap()` 等。`make ios-test` は `SWIFT_TREAT_WARNINGS_AS_ERRORS` を付けないので落ちない）。製品のターゲットは0件。

## 1〜6 の結論
1. **H33 の置き場所**：契約の「ReadingStore の読み込みの関数の中」からは外れる（`pass` は View 側のみ）。1-1 の例外の要件（`#if` なし、既定素通り、設定はつなぎ口だけ、名前、define なし）と観察できる振る舞いは満たすので、今回は受け入れてよい。契約の文を広げるか実装を寄せるかは tech-lead の裁定（上の要修正2）。
2. **Release の `LoadHoldGate`**：契約どおり（1-1「門の関数は Release のバイナリに残る」）。自分の Release ビルドで `nm` に `LoadHoldGate` 408（アプリ）・404（拡張）、`UITestHook` 0、`strings` の `uitest`/`-uitest`/`UITEST_`/`yomuma.uitest` 0。素通りは `LoadHoldGate.pass` の `guard armed.remove(point) != nil else { return }` と `GatedLoadView.init` の `isLoaded = !gate.willHold(point)`、`runCatalogLookup` の `guard gate.willHold else { perform(); return }` で、待ちを足さない。
3. **`widget.unavailable` なし**：design/ 5・6 に状態はあるが AC はない。BASE より前からの欠け（既存）。G3 の判定では数えないが、design-reviewer の画面×状態の表で空く欄なので、次の直しで `loadWidgetSnapshot` が「ファイルなし／壊れ」を区別して返す形にするのを勧める（小さい）。
4. **H22 `texts` の直書きと `AppL10n.pick`**：製品の画面・拡張・読み上げで英語のときに日本語が出る所は、今回の差分の範囲では見つからなかった（`String(localized:)` 経由、ja/en とも揃っていることを xcstrings を読んで確認）。`texts` の直書きは H22 契約・design/ 7 とずれる既存の問題。G3 で必須ではないが、`spokenStrings` で数行なので次回まとめて直すのが良い。
5. **W-1〜W-5 の共有と「終える」**：契約どおり。`ReadingLiveActivityLockScreenView` は `(Text) -> EndButton` の引数で受け（`ReadingWidgetSurfaceViews.swift:433-447`）、拡張は `Button(intent: EndReadingFromActivityIntent())`（`ReadingWidgets.swift:138`）、見本は `Button(action: {}) { label }`（`UITestHookOverlayWindow.swift` の `.liveActivity` 分岐）。共有ファイルに `EndReadingFromActivityIntent` の参照は0件。`viewType` の5型は共有ファイルに `struct` がある。
6. **`appintentsmetadataprocessor … Metadata extraction skipped`**：コンパイラの警告ではなく、Background Assets 拡張の `ExtractAppIntentsMetadata` 段の道具のログ。CLAUDE.md の「警告は0件（`SWIFT_TREAT_WARNINGS_AS_ERRORS=YES`）」はコンパイラの警告の話なので数えない（自分の clean ビルドで Swift の警告は0行）。消すなら、この Mac の Xcode 27.2 の `AppIntentsMetadata.xcspec`（SwiftBuild.framework 内）127〜133行にある `LM_FILTER_WARNINGS`（Boolean、YES で `--quiet-warnings`）を `ReadingBackgroundAssetsExtension` のターゲットに `LM_FILTER_WARNINGS = YES` として付ける。よく言われる `LM_SKIP_METADATA_EXTRACTION` はこの Xcode の xcspec に存在しない。

## 証拠
- 対象：fc844a7..7adfbcc（HEAD = 7adfbcc を `git rev-parse` で確認）、観点：コード、`git diff fc844a7..7adfbcc -- ios/ ':!ios/AcceptanceTests'`
- `git diff --name-only`（ios/ の29ファイル、すべて読んだ ✓）：project.pbxproj ✓、ContentView.swift ✓、Intents/ReadingAppIntents.swift ✓、Model/ReadingAppModel.swift ✓、Resources/Localizable.xcstrings ✓（足したキーの ja/en を Python で確認）、Shared/ReadingWidgetSurfaceViews.swift ✓（全文）、Theme/ThemeTokens.swift ✓、UITestHooks/UITestHookCoordinator.swift ✓、UITestHookOverlayWindow.swift ✓、UITestHookReadoutBuilder.swift ✓、Views/BookRegistrationViews.swift ✓、BookmarkHomeView.swift ✓、BookmarkMarkFlowViews.swift ✓、FinishNightView.swift ✓、LoadingPlaceholderViews.swift ✓（全文）、SessionResultAndGuideViews.swift ✓、SettingsAndStoreViews.swift ✓、ShelfAndBookDetailViews.swift ✓、ReadingBackgroundAssetsExtension/BackgroundAssetsHandler.swift ✓、ReadingCore/OCRPipeline.swift ✓、VerticalLineLayout.swift ✓、WidgetSpokenStrings.swift ✓（全文）、ReadingStore/LoadHoldGate.swift ✓（全文）、ReadingDataStore.swift ✓、SnapshotStore.swift ✓、Tests/VerticalLineLayoutTests.swift ✓、Tests/WidgetSpokenLabelTests.swift ✓（全文）、ReadingWidgetExtension/ReadingWidgets.swift ✓、docs/001-reading-session-implementation-notes.md ✓。差分の外で呼び出し元として読んだもの：ReadingApp.swift、UITestHookCoordinator の `applyLaunchConfiguration`、ReadingDataStore の `loadFromDisk`/`seedFromJSON`/`purchasePlus`/`restorePurchases`、ContractModels の `decodeForWidgetRenderer`、Models の `validateTitle`、AcceptanceTests の AC-28/32/137/139 と `texts` を読む箇所。
- 差分の中にエージェント向けの指示のような文：なし。

### AC 対応表（差分が触った AC）
| AC | 実装 | テスト | 自分で動かした結果 |
|---|---|---|---|
| AC-27 | ReadingWidgetSurfaceViews.swift:195-305、UITestHookOverlayWindow.swift 見本 | test_AC27 | ja/en とも passed |
| AC-35 | 同 309-388 | test_AC35 | ja/en passed |
| AC-99 | VerticalLineLayout.swift:266-296、WidgetSpokenStrings.swift、ReadingWidgetSurfaceViews.swift:52-54 | test_AC99、WidgetSpokenLabelTests（9場合×ja/en） | ja/en passed、swift test 20件通過 |
| AC-72 | OCRPipeline.swift:203-214 `joinSelectedColumns`（切らない）→ ReadingDataStore.swift:2228 `validateLine` で `mark.line.invalid` | test_AC72 | ja/en passed |
| AC-8 / S-8b `book.title.invalid` | BookRegistrationViews.swift:240-246 | test_AC8、test_AC137 | ja/en passed |
| AC-139 | 共有 View の `displayTitle`、`WidgetSpokenStrings.currentBookAsTitle` | test_AC139 | ja/en passed |
| AC-108 / AC-110（`store.offline`、復元） | ReadingDataStore.swift:2594-2600 | test_AC108、test_AC110 | ja/en passed |
| AC-91 の `settings.save` | ReadingDataStore.swift:2423-2452、SettingsAndStoreViews.swift:188-203 | （verifier の AC-91 は2分上限の件で別途） | コードを読んで確認。未実行 |
| AC-103 | — | — | `grep -rnE 'URLSession|NWConnection|CFStream|WKWebView|URLRequest' ios/`（AcceptanceTests 除く）→ BackgroundAssetsHandler.swift:25 の `URLRequest` のみ（PRD の例外） |
| AC-69 | OCR の画像を保存するコードの追加なし。`joinSelectedColumns` は文字列だけ | test_AC137 の `hook.mediaAudit` 0/0 | passed |
| 範囲外（AC に紐づかない変更）：pbxproj の同期フォルダ化・`COPY_PHASE_STRIP`・`dstSubfolderSpec`、`import ExtensionFoundation`、`PhotosPickerThemedLabel`（警告直し）、H33 の門一式、H22 の見本一式、`hook.error`、S-1 の `safeAreaBar`、S-3a/b/c の `TextField(axis: .vertical)`、`register.footer`、`mark.later.note.empty`、`shelf.load.error`、`scan.hint`、`camera.denied`（S-7c）、`colophon.capture` 常時表示、`mark.ocr.none`（S-8b） — いずれも design/ 5・6・7 または契約 H22/H33 に根拠あり |

### テストを弱める変更の検査（craft-reviewer 3-2）
- A `git diff --name-only … | grep -E '(AcceptanceTests|…)\.pbxproj$…'` → `ios/ReadingApp.xcodeproj/project.pbxproj` のみ。内容：`ReadingAcceptanceTests` を `PBXFileSystemSynchronizedRootGroup`（`AcceptanceTests`、`membershipExceptions = AcceptanceTests.xctestplan`）に。外れたテストがないことを `build-for-testing` の成果物で確認：`nm ReadingAcceptanceTests` の `test_AC` の一意な数 149 ＝ 源の `func test_AC` 149。10クラス＋`G3EvidenceCaptureTests`＋`AcceptanceTestBase` の記号すべてあり。xctestplan は束に入っていない（Info.plist、バイナリ、_CodeSignature のみ）。スキームの TestPlanReference はそのまま。→ 重大ではない。
- B skip 系の追加 → 0件（exit 1）。
- C `*Tests*` の assert の増減 → `+` 11、`-` 2（`VerticalLineLayoutTests.swift:147-148` の `contains("コンビニ人間、村田沙耶香")`/`contains("p. 142")` を design/ 6 505行の書式「書名、場所。一行」の等値に替えたもの。design を引用できるので正当）。
- D 本番コードの `UITest`/`#if DEBUG` 等 → `ContentView.swift` の `UITestHookCoordinator`/`UITestHookErrorView`/`UITestHookWidgetShowcaseView` は 28〜44行の `#if UITEST_HOOKS` の中（`grep -n 'UITEST_HOOKS\|#else\|#endif' ContentView.swift` で 17/22、28/36/38、40/44 を確認）。それ以外の当たりは `UITestHooks/` と md。テスト中だけ答えを変える分岐なし。
- テストの入力値の決め打ち：`羅生門`、`こころ`、`p.61` を本番コードで grep → 条件分岐に出ない（Preview と placeholder の `■` のみ）。

### 動かしたコマンドと出力
- `make ios-build`（差分ビルド）→ `** BUILD SUCCEEDED **`、exit 0、`warning:` 0行。
- `xcodebuild clean` → `make ios-build`（SwiftCompile 172段）→ exit 0、`warning:` 1行＝`appintentsmetadataprocessor[…] warning: Metadata extraction skipped, no AppIntents.framework dependency found`。Swift の警告 0。
- Release：`xcodebuild -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath <scratchpad>/rv-dd-rel SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build` → exit 0、警告は同じ1行。`nm -a`/`strings -a`：ReadingApp・ReadingWidgetExtension・ReadingBackgroundAssetsExtension とも `UITestHook` 0、`uitest`（大小）0、`WidgetShowcase` 0、`hook.` 0。`LoadHoldGate` はアプリ 408、Widget 拡張 404、BA 拡張 0。BA 拡張は `ReadingApp.app/Extensions/ReadingBackgroundAssetsExtension.appex` にある（`dstSubfolderSpec = 16` の直しを確認）。Widget 拡張の束に `ja.lproj/Localizable.strings`、`en.lproj/Localizable.strings` あり（共有 View の `String(localized:)` が拡張でも引ける）。
- `swift test --package-path ios/ReadingKit` → `Test run with 20 tests in 6 suites passed`（`Widget spoken label (AC-99)` 9場合を含む）。
- `xcodebuild build-for-testing …（iPhone 17, OS 26.0）` → exit 0（警告 3,324行はすべて `ios/AcceptanceTests/`）。
- `xcodebuild test-without-building -xctestrun … -only-testing:` 9本（AC-27、35、99、72、137、139、8、108、110）→ `Test Suite 'ReadingAcceptanceTests.xctest' passed`、ja：`Executed 9 tests, with 0 failures`、en：`Executed 9 tests, with 0 failures`、exit 0（13:27 完了、結果：<scratchpad>/rv-subset.xcresult）。
- `make check-contracts` → `ALL PASSED: 8 schemas, 28 examples validated with 0 errors.`
- 追加の grep：`@unchecked Sendable|nonisolated(unsafe)|try!|as!|fatalError|空の catch` の追加行 0。`Logger|os_log` の追加行 0（既存の `.public` は ClockProvider.swift:128 の metric 名のみ）。`EndReadingFromActivityIntent` は共有ファイルに0件。`-uitest-hold-load`/`release` の `arm`/`release` 呼び出しは UITestHookCoordinator.swift:93,519-521 のみ。h22 `$defs/showcase` の必須12項目と `UITestHookWidgetShowcaseReadout` の12項目が一致。h17 の `hold.<対象>` の正規表現8対象と `LoadHoldGate.Point` の8値・番号1〜8が一致。
- 開いた規則：contracts/test-hooks.md（2026-11-02 版：1-1、H7、H8、H22、H30、H33 を引用）、contracts/hooks/h22-widget.schema.json・h17-state.schema.json、design/001-reading-session.md 6章（505〜510行）・7章（644〜879行）・5章（449〜474行）、docs/prd/001-reading-session.md（AC-27、35、66、69、72、99、103、139）、CLAUDE.md「このアプリだけの決まり」。Apple の build-settings-reference は本文が取れず未引用（Xcode 27.2 の `AppIntentsMetadata.xcspec` を直接開いて `LM_FILTER_WARNINGS` を確認）。

### 未検証
- `make ios-test` の全149 AC の通し（約2時間）は動かしていない。動かしたのは上の9本×ja/en と ReadingKit の単体テスト。AC-91（`settings.save` を含む7種）は未実行。
- S-1 の AX5、S-8 の `register.footer`、監査の件数は画像・監査ログを自分では撮っていない（design-reviewer r2 / verifier r3 の範囲）。
- `widgetContentMargins` の実値と本物のウィジェットの余白の一致は実機（G4）でしか見られない。
- 指摘の `LM_FILTER_WARNINGS = YES` は xcspec で引数（`--quiet-warnings`）を確かめただけで、付けてビルドしてはいない。

## 記録（指揮役が保存するときに書き足す）
- 種類：判定（観点：コード）。対象 fc844a7..7adfbcc。日付：2026-11-02。結果：PASS（要修正2、提案9）。
- 指揮役の裁定
  1. **要修正1（H22 の読み出しと描画の食い違い）**：直す。読み出しが本物の W-1・W-2 の組み方（枠から決めた列数と字数）を表すようにする。h22 スキーマに項目を足す要否は tech-lead が決め、そのあと ios-engineer が直す。
  2. **要修正2（H33 の門の置き場所）**：今の実装を受け入れる。観察できる振る舞いは契約どおりで、1-1 の例外の要件も満たすため。契約の文を「読み込みの関数、または読み込んだ結果を画面に渡す所」に広げる直しを tech-lead に頼む。
  3. **結論6（appintentsmetadataprocessor の1行）**：「警告0」に数えない（コンパイラの警告ではない）。ただし手間が小さいので、ios-engineer が Background Assets 拡張に `LM_FILTER_WARNINGS = YES` を付けて消えるかを試す。消えなければそのままでよい。
  4. **提案のうち次の直しでまとめるもの**：H22 の `texts` の直書きを `spokenStrings` に、`widget.unavailable` の状態（`loadWidgetSnapshot` が「ファイルなし／壊れ」を分ける）、`store.buy` の2度押し、`catalog.lookup` の2つ目の `pass`、`storekit.*` の ProgressView を0.3秒のあとに出す順。
  5. **次の直しに入れないもの**：`AppL10n.pick` から String Catalog への移行（285か所。別の作業）、design/ 7 にキーのない文（`liveActivity.readingSince`、`common.loading`。design-reviewer r2 の指摘を待つ）、受け入れテストの警告（verifier）。
