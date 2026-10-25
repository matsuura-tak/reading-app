# ADR-0001: iOS アプリの土台（対応 OS・モジュール分割・外部依存ゼロ・同梱フォント）

- 日付：2026-10-25
- 状態：採用
- 関連する機能：`docs/prd/001-reading-session.md`（AC-1〜AC-149）、`design/001-reading-session.md`

## 背景

「よむま」は、本を閉じた夜の10秒でしおりの一行と場所を残し、翌晩ロック画面・ウィジェット・Live Activity・コントロール・Siri ショートカットから1タップ（または iPhone を伏せる動作）で続きへ戻れる iOS アプリである。

PRD（`docs/prd/001-reading-session.md`）および画面仕様（`design/001-reading-session.md`）で定義された全 149 件の受け入れ基準（AC-1〜AC-149）を v1.0 で一括実装するにあたり、以下の要件を同時に満たす土台が必要である。

1. **コールドスタートの速さ（AC-91）**：Release 構成で起動から S-1（しおりの画面）の最初の描画完了までが 5 回平均 0.4 秒（400ms）以内。
2. **書誌検索・バーコード解決の速さ（AC-149）**：Release 構成でバーコード読み取りから `scan.row` 表示まで、および手入力の書名 3 字入力から `search.row` 表示までが 5 回平均 0.3 秒（300ms）以内。
3. **完全な端末内完結と外部通信ゼロ（AC-86、AC-103）**：アカウント作成なし、独自サーバーなし、広告・解析・クラッシュ収集 SDK なし、アプリのプロセスから外部サーバーへの HTTP 通信は 0 件（書誌 DB の配信は OS の Background Assets、買い切り課金は OS の StoreKit 2 が担う）。
4. **本体と拡張（Widget / Live Activity / Control / App Intents / Background Assets）の境界共有**：S-1〜S-10a の本体画面、ロック画面・ホーム画面ウィジェット（W-1、W-2）、夜の入口と読書中の Live Activity（W-3）、コントロール（W-4）、Siri とショートカット（W-5）、および端末内書誌 DB の Background Assets 拡張が、同じ型・同じ縦書き組版・同じ保存ロジックを安全に共有できること。
5. **149 AC の自動検証（AC-1〜AC-149）**：外部通信・カメラ・時間経過・近接／姿勢センサー・StoreKit 2・Live Activity・App Intents をすべてテストフック（H1〜H32）で決定論的に差し替え可能にすること。

## 考えた選択肢と比べた結果

| 選択肢 | 良い点 | 悪い点 | 判断 |
|---|---|---|---|
| **A. iOS 26.0 以降・Swift 6.2・標準フレームワークのみ＋ローカル Swift Package（`ReadingCore` / `ReadingStore`）構成（採用）** | - 外部動的フレームワークが 0 個のため `dyld` ロード時間が最小になり、AC-91（400ms 以内）を余裕で満たす<br>- SwiftUI の標準部品・Liquid Glass・`WidgetKit`・`ActivityKit`（`Activity.request(...start:)` による日時指定開始）・`AppIntents`（`LiveActivityIntent` / `ShowsSnippetIntent` / `ControlWidget`）・`Vision`・`VisionKit`・`PhotosUI`・`StoreKit 2`・`BackgroundAssets`・`SQLite3`（FTS5 `trigram`）がすべて OS 標準で揃う<br>- サードパーティ SDK 由来のトラッキング・プライバシーマニフェスト違反リスクがゼロ（AC-86、AC-103）<br>- `ReadingCore` と `ReadingStore` をローカル Package に切り出すことで、高速な `swift test` と拡張ターゲット間のコード共有が両立する | - 縦書き 1 行描画（W-1、W-2、S-1、S-5）や SQLite3 C API ラッパーを自前で書く必要がある（ただし最大 60 字×最大 3 列、および 3 テーブルの読み取り専用クエリなので 300 行未満で完結する） | **採用** |
| **B. iOS 17 / 18 互換を残し、外部ライブラリ（GRDB、Lottie、SnapKit 等）を導入する** | - 旧 OS 端末でも動く<br>- SQLite ラッパーを外部ライブラリに任せられる | - ControlWidget（W-4）や iOS 26 の Liquid Glass 標準表現に分岐が入り、コードと検証対象が倍増する<br>- 動的フレームワーク増加でコールドスタート（AC-91）が悪化する<br>- 外部依存の監査・ライセンス管理コストが増える | 却下 |
| **C. 単一ターゲットに全コードを置き、Widget / Control / BackgroundAssets 拡張へファイルを個別ターゲットメンバシップで共有する** | - Package 定義がいらない | - 本体専用の UIKit / カメラ / StoreKit コードが Widget 拡張に混入しやすく、拡張のメモリ上限（Widget 30MB）やビルド境界が壊れやすい | 却下 |

## 決めたこと

### 1. 対応 OS・言語・ビルド設定
- **対応 OS**：iOS 26.0 以降（`IPHONEOS_DEPLOYMENT_TARGET = 26.0`）、iPhone 専用（`TARGETED_DEVICE_FAMILY = 1`、縦向き Portrait 固定）。
- **言語と並行性**：Swift 6.2、Strict Concurrency Complete（`SWIFT_STRICT_CONCURRENCY = complete`）。
- **状態管理**：Observation フレームワーク（`@Observable`、`@MainActor`）に統一し、Combine や ObservableObject は使わない。
- **ローカライズ**：`Localizable.xcstrings` と `InfoPlist.xcstrings`（日本語 `ja`・英語 `en`）で管理し、`design/001-reading-session.md` 7-1 節の全 202 文言キーと 7-2 節の App Shortcuts フレーズを完全一致させる。

### 2. 外部ライブラリゼロと、同梱する OFL フォント
- **外部コード依存ゼロ**：SwiftPM / CocoaPods / Carthage のサードパーティライブラリは 0 個とする（`contracts/dependencies.md`）。
- **使用する OS 標準フレームワーク**：
  - UI・描画：`SwiftUI`、`UIKit`（`UIPasteboard`、`UIImpactFeedbackGenerator`、`UINotificationFeedbackGenerator`、`UIApplication`）、`CoreText` / `CoreGraphics`
  - ウィジェット・Live Activity・コントロール・Siri：`WidgetKit`、`ActivityKit`、`AppIntents`
  - カメラ・OCR・画像選択：`Vision`（`VNRecognizeTextRequest`）、`VisionKit`（`DataScannerViewController`）、`AVFoundation`、`PhotosUI`（`PhotosPicker`）
  - センサー：`CoreMotion`（`CMMotionManager`）
  - 課金：`StoreKit`（StoreKit 2 `Product` / `Transaction` / `AppStore.sync()`）
  - 書誌 DB 配信・検索：`BackgroundAssets`（Apple-Hosted Background Assets）、`SQLite3`（システム `libsqlite3.tbd`、FTS5 `trigram` トークナイザ）
  - 基盤・ログ：`Foundation`、`Observation`、`os.log`（`Logger`）
- **同梱するフォント資産（AC-105、AC-111）**：
  - 標準の見た目（`default`）および W-1・W-2 の縦書きには iOS 同梱の「ヒラギノ明朝 ProN」（`HiraMinProN-W3` / `HiraMinProN-W6`）とシステムフォント（SF Pro / ヒラギノ角ゴ）を使う。
  - 買い切り「よむま＋」の3つの見た目（`kinari` 生成り、`sumi` 墨、`shu` 朱）で用いる組版フォントとして、SIL Open Font License 1.1 の **Shippori Mincho B1**（`ShipporiMinchoB1-Regular.ttf`、`ShipporiMinchoB1-Bold.ttf`）と **Klee One**（`KleeOne-Regular.ttf`、`KleeOne-SemiBold.ttf`）をアプリバンドルに同梱し、`Info.plist` の `UIAppFonts` に登録する。S-10 のライセンス表示に OFL 1.1 全文を含める（AC-111）。

### 3. ターゲットとモジュール分割

```text
ios/
├── ReadingApp.xcodeproj
├── ReadingKit/                          # ローカル Swift Package
│   ├── Package.swift
│   ├── Sources/
│   │   ├── ReadingCore/                 # 純粋ドメイン・組版計算・OCR 整形・推薦重み・時計/乱数/障害注入プロトコル
│   │   └── ReadingStore/                # App Group 永続化・SQLite 書誌/共起 DB・受賞作辞書・StoreKit 2・Live Activity 調整
│   └── Tests/
│       ├── ReadingCoreTests/            # 単体テスト（組版・ISBN/Cコード解析・OCR 抽出・推薦スコア・ふりかえり文言等）
│       └── ReadingStoreTests/           # 単体テスト（状態遷移・原子書き込み・SQLite FTS5・マイグレーション・破損復旧等）
├── ReadingApp/                          # 本体アプリターゲット（S-1〜S-10a、部品 N、カメラ/OCR UI、App Shortcuts、H1〜H32 起動）
├── ReadingWidgetExtension/              # Widget / Live Activity / Control 拡張（W-1、W-2、W-3、W-4）
├── ReadingBackgroundAssetsExtension/    # Apple-Hosted Background Assets 拡張（catalog.sqlite の配置・除外属性設定）
└── AcceptanceTests/                     # XCUITest 受け入れテスト（verifier が管理）
```

| モジュール / ターゲット | 責務 | リンク先 |
|---|---|---|
| `ReadingCore` | ドメインモデル（`Book`、`ReadingRecord`、`ActiveSession`、`UserSettings`、`WidgetSnapshot`、`RecommendationWeight`、`AppearanceID`、`ProgressUnit`）、縦書き 1〜3 列レイアウト計算、ISBN-13・2段目バーコード（`192` Cコード）・出版社記号解析、OCR 矩形からの縦書き列・表紙行・背表紙・奥付抽出、推薦スコア計算（`chosen * 2 - skipped`）、読み終えふりかえり文生成、テストフック設定型（`HookConfig`） | 本体・全拡張・全テスト |
| `ReadingStore` | `ReadingRepository`（`@MainActor @Observable`）、App Group アトミック JSON 保存（`state.json` / `widget-snapshot.json`）、端末内 SQLite 書誌・共起 DB（`CatalogDatabase`、読み取り専用・FTS5 `trigram`）、同梱受賞作リスト（`AwardsCatalog` / H25）、`StoreManager`（StoreKit 2 `yomuma.plus`）、`LiveActivityCoordinator`（今夜の予約・即時開始・終了・4:00 境界再計算）、`FaceDownDetector`（近接＋重力ベクトル＋3秒デバウンス）、`OCRPipeline`（`VNRecognizeTextRequest`）、`OutboundNetworkGuard`（H29） | 本体・Widget 拡張・テスト |
| `ReadingApp` | 画面 S-1〜S-10a と部品 N（知らせの帯）、`DataScannerViewController` / `AVCaptureSession` ラッパー、`PhotosPicker`（`.screenshots`）、`ImageRenderer` による読み終えカード画像生成（1080×1350 PNG）、`AppShortcutsProvider`（`StartReadingIntent`、`WhereStoppedIntent`、`ContinueReadingIntent`）、テストフック H1〜H32 のディスパッチ | App Store 配布バイナリ |
| `ReadingWidgetExtension` | W-1（`.accessoryRectangular`）、W-2（`.systemSmall`）、W-3（`ActivityConfiguration` による夜の入口・読書中 Live Activity と `EndReadingIntent`）、W-4（`ControlWidget` による `StartReadingIntent` ボタン） | 本体アプリに内包 |
| `ReadingBackgroundAssetsExtension` | `BADownloaderExtension` により Apple-Hosted Background Assets の `catalog.sqlite` を受け取り、App Group コンテナ内の `Catalog/catalog.sqlite` に配置して `isExcludedFromBackup = true` を設定する | 本体アプリに内包 |

## 引き受けること

- iOS 26.0 未満の端末にはインストールできない。
- サードパーティの ORM や UI ライブラリを使わないため、SQLite3 の `sqlite3_prepare_v2` バインディングと縦書き 1 行キャンバスを `ReadingCore` / `ReadingStore` 内で保守し、単体テストで境界値を網羅する。
- 本体と `ReadingWidgetExtension` の両方から実行されうる `StartReadingIntent` / `EndReadingIntent` / `WhereStoppedIntent` のため、状態変更とスナップショット書き出しは必ず `ReadingStore` のアトミック書き込みとファイルロック（`NSFileCoordinator`）を経由する（ADR-0002）。
