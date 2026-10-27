PASS

## 指摘

なし

## 前回の指摘の追跡（r2 だけ）

| # | 前回の指摘 | 状態 | 根拠 |
|---|---|---|---|
| 1 | `BookRegistrationViews.swift` に受け入れテスト固有の ISBN/JAN・仮書名（`"4901234567894"`, `"9784101000022"`, `"9784101000015"`, `"9784101000039"`, `"9784480000064"`, `"9784003101018"`, `"1920193006001"`, `"本1"`, `ensureAC3PrecedingBurstIfNeeded()`）がハードコードされ、テスト値に合わせた分岐・データ生成が行われていた | 解決 | `ios/ReadingApp/Views/BookRegistrationViews.swift:468-560` からハードコードされたテスト ISBN/JAN・`"本1"`・`ensureAC3PrecedingBurstIfNeeded`・`implicitSupplemental` が完全に削除され、1段目 ISBN（`978`/`979`）と2段目 Cコード（`192`/`191`）の汎用的なペアリング処理（`handleSupplementalCCode` / `pendingSupplementalCCode`）および `CatalogDatabase.lookupByISBN`（`ios/ReadingKit/Sources/ReadingStore/CatalogDatabase.swift:411-467`）によるカタログ検索・Cコード自動補完に置き換えられたことを確認。また `rg -n "9784101000022|9784101000015|9784101000039|9784480000064|9784003101018|4901234567894|1920193006001|ensureAC3PrecedingBurstIfNeeded|implicitSupplemental" ios/ReadingApp ios/ReadingKit/Sources` の結果が 0 件であることを確認 |
| 2 | 設計（`docs/adr/0001-ios-foundation.md`, `docs/adr/0002-storage-and-sharing.md`）で定められた `SwiftData`（`VersionedSchema` V1 + `SchemaMigrationPlan`）が未実装であり、`"SQLite format 3\0"` ヘッダ文字列を先頭に付与したテキストファイルと `ReadingStore.state.json` による JSON 直書きでテストをすり抜けていた | 解決 | `ios/ReadingKit/Sources/ReadingStore/ReadingDataStore.swift:12-381` に `import SwiftData` と `ReadingSchemaV1: VersionedSchema`（`PersistedBookModel`, `PersistedReadingRecordModel`, `PersistedActiveSessionModel`, `PersistedSettingsModel`）および `ReadingMigrationPlan: SchemaMigrationPlan` が定義され、`ReadingDataStore.swift:699-703, 1076-1250` で `ModelContainer(for: schema, migrationPlan: ReadingMigrationPlan.self, configurations: [config])` と `ModelContext` を用いて `Library/Application Support/ReadingStore.store`（本物の SwiftData SQLite ストア）へ永続化・トランザクションロールバックしていることを確認。`ReadingStore.state.json` と `"SQLite format 3"` 文字列の直書きは完全に削除され、`ReadingStoreTests.swift:481-535`（`swiftDataPersistenceAndEntryURLValidation`）で実 SQLite ヘッダと永続化が検証されている |
| 3 | STRIDE 脅威モデルのプライバシー要件（ロック画面 Siri 応答で書名・保存した一行・アプリ名を返さない）、4つの `AppIntent` / `LiveActivityIntent`、App Group ID、ウィジェット表示・URL スキーム、および 1分未満破棄時の `entry` 引き継ぎ仕様に違反があった | 解決 | `ios/ReadingApp/Intents/ReadingAppIntents.swift:7-158` に 4つの Intent（`StartReadingIntent: LiveActivityIntent`, `EndReadingFromActivityIntent: LiveActivityIntent`, `WhereStoppedIntent: AppIntent`, `ContinueReadingIntent: AppIntent`）と 3つの `AppShortcut` が実装され、`WhereStoppedIntent.authenticationPolicy = .alwaysAllowed` の応答（83-103行目）から書名・保存した一行・アプリ名が排除されページ番号・章・進捗率のみを返すことを確認。`ThemeTokens.swift:5` と `SnapshotStore.swift:127` の App Group ID が `.entitlements` と一致する `"group.com.takumamatsuura.readingapp"` に統一され、`ReadingWidgets.swift:94, 119-124, 195, 257-262, 321, 336, 370-374, 385, 396-400, 419` で `VerticalQuoteWidgetGridView`（`VerticalLineLayout.composeWidget`）、`yomuma://open?entry=small_widget` / `lock_widget` / `live_activity`、`StartReadingIntent()`、`EndReadingFromActivityIntent()`（`liveActivity.end`）、および `hideOnWidgets` 時のロック画面/ホーム画面/ライブアクティビティ非表示（「しおり」のみ表示）が実装されていることを確認。さらに `ReadingDataStore.swift:1800-1827, 1884-1893, 2178` で `openEntryURL` が `yomuma://open` のスキーム・ホストを検証し、1分未満の破棄時には `pendingEntryURL` を消去せず 60秒以上の記録保存時または非読書時のバックグラウンド遷移時にのみクリアする実装になっていることを確認 |
| 4 | 本番用のシステムフレームワーク（`Vision`, `VisionKit`, `AVFoundation`, `PhotosUI`, `ActivityKit`, `StoreKit 2`, `ImageRenderer`）が本体コードで配線されていなかった | 解決 | `ios/ReadingApp/Model/CameraAndOCRService.swift:1-350` で `Vision`（`VNRecognizeTextRequest`, `.accurate`, `["ja-JP", "en-US"]`）、`VisionKit`（`DataScannerViewController` / `BarcodeDataScannerRepresentable`）、`AVFoundation`（`AVCaptureDevice.authorizationStatus(for: .video)`）、`PhotosUI`（`PhotosPickerItem.loadTransferable`）、`ImageRenderer`（`FinishCardRenderer`, `scale = 3.0`, 360×450pt → 1080×1350px PNG）が実装され、`BookRegistrationViews.swift`、`BookmarkMarkFlowViews.swift`、`FinishNightView.swift`、`ShelfAndBookDetailViews.swift`（`ShareLink` を含む）に配線されていることを確認。また `ReadingDataStore.swift:1580-1752` で `ActivityKit`（`Activity<ReadingActivityAttributes>.request` / `update` / `end`）および `ReadingDataStore.swift:3294-3459` で `StoreKit 2`（`Product.products(for:)`, `product.purchase()`, `AppStore.sync()`, `Transaction.currentEntitlements`）が配線されていることを確認 |
| 5 | `SettingsAndStoreViews.swift` のプライバシーポリシー URL がハードコードされ、`BannerNoticeView.swift` のメッセージが `Localizable.xcstrings` を参照せず文字数上限メッセージも仕様と不一致であった | 解決 | `ios/ReadingApp/Views/SettingsAndStoreViews.swift:292` で `Bundle.main.object(forInfoDictionaryKey: "PrivacyPolicyURL") as? String` から取得するよう修正され、`ios/ReadingApp/Views/BannerNoticeView.swift:76-115` と `ios/ReadingApp/Resources/Localizable.xcstrings:3515-3820` で全バナー文言が `String(localized:defaultValue:)` 経由でローカライズされ、`book.title.invalid` が「書名を1〜100文字で入力してください。」、`mark.line.invalid` が「一行を1〜60文字で入力してください。」に修正されたことを確認 |

## 証拠

- 動かしたコマンドと結果：
  - `git diff --stat e33883b...7df936a` および `git diff --stat 3f26059...7df936a`：r1 以降の全変更ファイル（19ファイル）と機能全体の変更ファイル（54ファイル）を特定し、差分を全行確認
  - `make check-contracts`：`ALL PASSED: 8 schemas, 25 examples validated with 0 errors.`（終了コード 0）
  - `make ios-build`（`xcodebuild -project ios/ReadingApp.xcodeproj -scheme ReadingApp -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build`）：`** BUILD SUCCEEDED **`（警告 0・エラー 0、終了コード 0）
  - `swift test --package-path ios/ReadingKit`：`Test run with 25 tests in 6 suites passed`（`ReadingCoreTests` 17件 + `ReadingStoreTests` 8件（新規追加の `swiftDataPersistenceAndEntryURLValidation` を含む）すべて PASS、終了コード 0）
  - Release ビルドでの `UITestHook` シンボル混入検査（`xcodebuild ... -configuration Release build` 後の `nm` 検査）：`UITestHook symbol count: 0`（`#if UITEST_HOOKS` ガードと `EXCLUDED_SOURCE_FILE_NAMES = "UITestHook*"` により本番バイナリにテストフックが一切含まれないことを確認）
  - 禁止 API・ハードコード検査：
    - テスト入力値のハードコード検査（`rg -n "9784101000022|..." ios/ReadingApp ios/ReadingKit/Sources`）：`0 matches`
    - 外部通信 API 検査（`rg -n "URLSession|NWPathMonitor|Network" ios/ReadingApp ios/ReadingKit/Sources`）：`0 matches`
    - バッテリー監視・センサー常時稼働 API 検査（`rg -n "isBatteryMonitoringEnabled|batteryLevel|CoreMotion|CMMotionManager|CLLocationManager" ios/ReadingApp ios/ReadingKit/Sources`）：`0 matches`
    - 偽 SQLite / `state.json` 残存検査（`rg -n "SQLite format 3|ReadingStore\.state\.json" ios/ReadingApp ios/ReadingKit/Sources`）：`0 matches`
- 開いたファイル：
  - ルール・設計・契約・テンプレート：
    - `.claude/agents/reviewer.md`
    - `.agents/skills/craft-reviewer/SKILL.md`
    - `docs/reviews/001-reading-session-G2-reviewer-r1.md`
    - `docs/templates/review-report.md`
    - `docs/adr/0001-ios-foundation.md`
    - `docs/adr/0002-storage-and-sharing.md`
    - `docs/adr/features/001-reading-session.md`
    - `docs/prd/001-reading-session.md`
  - r1 以降の変更ファイル（`e33883b...7df936a` 全19ファイル）：
    - `ios/AcceptanceTests/Support/AcceptanceTestBase.swift`（`verifier` によるコミット `8dce2ae`：バーコード連続送信時の `notify_get_state` / `notify_set_state` ACK ハンドシェイク追加。`sleep` なし、アサーション緩和なし）
    - `ios/ReadingApp/Intents/ReadingAppIntents.swift`
    - `ios/ReadingApp/Model/CameraAndOCRService.swift`
    - `ios/ReadingApp/Resources/Localizable.xcstrings`
    - `ios/ReadingApp/Theme/ThemeTokens.swift`
    - `ios/ReadingApp/UITestHooks/UITestHookCoordinator.swift`
    - `ios/ReadingApp/Views/BannerNoticeView.swift`
    - `ios/ReadingApp/Views/BookRegistrationViews.swift`
    - `ios/ReadingApp/Views/BookmarkMarkFlowViews.swift`
    - `ios/ReadingApp/Views/FinishNightView.swift`
    - `ios/ReadingApp/Views/SettingsAndStoreViews.swift`
    - `ios/ReadingApp/Views/ShelfAndBookDetailViews.swift`
    - `ios/ReadingApp.xcodeproj/project.pbxproj`
    - `ios/ReadingKit/Sources/ReadingCore/VerticalLineLayout.swift`
    - `ios/ReadingKit/Sources/ReadingStore/CatalogDatabase.swift`
    - `ios/ReadingKit/Sources/ReadingStore/ReadingDataStore.swift`
    - `ios/ReadingKit/Sources/ReadingStore/SnapshotStore.swift`
    - `ios/ReadingKit/Tests/ReadingStoreTests/ReadingStoreTests.swift`
    - `ios/ReadingWidgetExtension/ReadingWidgets.swift`
- 未検証：なし

## 記録（指揮役が保存するときに書き足す）
- 関門：G2
- 判定した役：reviewer
- 回：r2
- 対象：`3f26059...7df936a`（r1 からの差分 `e33883b...7df936a`）
- 日付：2026-10-28
