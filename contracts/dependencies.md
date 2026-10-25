# 依存ライブラリと配布資産の許可リスト（Dependencies Allowlist）

このファイルは、このリポジトリで使用を許可する外部ライブラリ・OS 標準フレームワーク・同梱フォント／データ資産・検証ツールの唯一の正本です（管理：tech-lead）。
ここに載っていないライブラリを `Package.swift` や Xcode プロジェクトに追加してはいけません。追加が必要な場合は、先に tech-lead が比較検討（ADR）と脆弱性・ライセンス確認を行い、このファイルを更新します。

---

## 1. iOS アプリ本体・拡張（`ios/`）の外部コードライブラリ

**許可されたサードパーティ製ライブラリ：0 件（外部コード依存ゼロ）**

- `Package.swift` の `dependencies: []` は空配列を維持し、`Package.resolved` に外部パッケージが含まれないことを契約とする（ADR-0001）。
- 広告 SDK、解析（Analytics）SDK、クラッシュ収集 SDK、外部通信クライアントライブラリは一切導入しない（AC-86、AC-103）。

### 使用する Apple 標準フレームワーク（iOS 26.0 SDK 同梱）

| フレームワーク | 用途 | 使うターゲット |
|---|---|---|
| `SwiftUI` | 全画面（S-1〜S-10a、部品 N）、縦書き `Canvas`、読み終えカード `ImageRenderer`（1080×1350 PNG） | `ReadingApp`、`ReadingWidgetExtension` |
| `Observation` | `@Observable` による状態監視（`ReadingRepository`） | `ReadingCore`、`ReadingStore`、`ReadingApp` |
| `WidgetKit` | ロック画面ウィジェット W-1（`.accessoryRectangular`）、ホーム画面／StandBy ウィジェット W-2（`.systemSmall`）、コントロール W-4（`ControlWidget`） | `ReadingStore`、`ReadingApp`、`ReadingWidgetExtension` |
| `ActivityKit` | 夜の入口の予約 Live Activity（`Activity.request(...start:)`）および読書中 Live Activity（W-3） | `ReadingStore`、`ReadingApp`、`ReadingWidgetExtension` |
| `AppIntents` | `StartReadingIntent`（`LiveActivityIntent`）、`EndReadingIntent`（`LiveActivityIntent`）、`WhereStoppedIntent`（`ShowsSnippetIntent`）、`ContinueReadingIntent`、`AppShortcutsProvider`（W-4、W-5） | `ReadingStore`、`ReadingApp`、`ReadingWidgetExtension` |
| `Vision` | `VNRecognizeTextRequest`（Revision 3、`.accurate`、`["ja-JP", "en-US"]`）によるページ・表紙・本棚背表紙（`minimumTextHeightFraction = 0.005`）・奥付の端末内 OCR | `ReadingStore`、`ReadingApp` |
| `VisionKit` / `AVFoundation` | `DataScannerViewController` / `AVCaptureSession` による EAN-13（ISBN-13＋2段目 `192` Cコード）連続スキャンとページ・表紙・本棚・奥付の撮影、およびカメラ権限確認 | `ReadingApp` |
| `PhotosUI` | `PhotosPicker(matching: .screenshots)` による写真ライブラリ権限不要のスクリーンショット選択（S-3、S-8） | `ReadingApp` |
| `CoreMotion` | `CMMotionManager`（`isDeviceMotionAvailable`、`gravity.z`）と `UIDevice.current.isProximityMonitoringEnabled` による「3秒伏せて読書開始」検知 | `ReadingStore`、`ReadingApp` |
| `StoreKit` | StoreKit 2（`Product`、`Transaction`、`AppStore.sync()`）による買い切り「よむま＋」（`yomuma.plus`）の購入・復元・権利確認 | `ReadingStore`、`ReadingApp` |
| `BackgroundAssets` | `BADownloaderExtension` による Apple-Hosted Background Assets（端末内書誌・共起 SQLite DB `catalog.sqlite`）の配信・配置 | `ReadingStore`、`ReadingApp`、`ReadingBackgroundAssetsExtension` |
| `SQLite3`（`libsqlite3.tbd`） | 端末内書誌・共起 DB（`catalog.sqlite`）の読み取り専用クエリおよび FTS5 `trigram` 全文検索 | `ReadingStore` |
| `UIKit` / `CoreText` / `CoreGraphics` | `UIPasteboard`、触覚フィードバック（`UIImpactFeedbackGenerator` / `UINotificationFeedbackGenerator`）、縦書きグリフ回転・配置、PNG エンコード | `ReadingCore`、`ReadingApp`、`ReadingWidgetExtension` |
| `Foundation` / `os.log` | JSON エンコード／デコード、`NSFileCoordinator`、`FileManager`、`Logger` | 全ターゲット |

---

## 2. 同梱フォント・データ資産のライセンス一覧

| 資産名 | 配置場所 | ライセンス | 用途と表示義務（AC-93、AC-111、AC-112） |
|---|---|---|---|
| **Shippori Mincho B1**（`ShipporiMinchoB1-Regular.ttf`、`ShipporiMinchoB1-Bold.ttf`） | `ReadingApp` / `ReadingWidgetExtension` バンドル | **SIL Open Font License 1.1**（FONTDASU / フォン出す） | よむま＋の見た目（`kinari` 生成り、`sumi` 墨）の明朝体。S-10 のライセンス表示に著作権表示と OFL 1.1 全文を掲載する（AC-111） |
| **Klee One**（`KleeOne-Regular.ttf`、`KleeOne-SemiBold.ttf`） | `ReadingApp` / `ReadingWidgetExtension` バンドル | **SIL Open Font License 1.1**（FONTWORKS / フォントワークス） | よむま＋の見た目（`shu` 朱）の教科書体・楷書系書体。S-10 のライセンス表示に著作権表示と OFL 1.1 全文を掲載する（AC-111） |
| **端末内書誌データベース**（`catalog.sqlite`） | Apple-Hosted Background Assets → App Group `Catalog/catalog.sqlite` | **CC BY 4.0**（国立国会図書館書誌データ：「国立国会図書館蔵書」「国立国会図書館新着書誌情報」「全国書誌情報」） | ISBN・書名・背表紙からの端末内書誌検索（AC-3〜14、AC-138、AC-149）。S-10 の `settings.dataSources` と `settings.dataSources.license` に NDL 利用規約の 3 条件（出典名・API 取得データを加工して作成した旨・CC BY 4.0 リンク）を明記する（AC-93） |
| **文学賞受賞作リスト**（`awards.json`） | `ReadingStore` バンドル | 事実データ（賞名・回次・受賞年・書名・著者・出版社・ISBN） | 芥川龍之介賞（第1回〜第174回）・直木三十五賞（第1回〜第174回）・本屋大賞（第1回〜第22回）の奥付表示と推薦（AC-19〜21、AC-83、AC-112） |
| **国内主要出版者記号シード**（`publisher-prefixes.json`） | `ReadingStore` バンドル | 事実データ（ISBN 出版者記号と出版社名の対応） | 書誌 DB 未収録・未取得時の出版社名・レーベル自動補完（AC-9〜11） |

---

## 3. 開発・契約検証ツール（アプリバイナリには含まれない）

| ツール | バージョン | ライセンス | 用途 |
|---|---|---|---|
| `jsonschema`（Python パッケージ） | 4.26.0 | MIT | `contracts/widget-snapshot.schema.json` および `contracts/hooks/*.schema.json` の JSON Schema Draft 2020-12 妥当性検証と `examples` 検証（`make check-contracts`） |

（注：アプリのプロセスから外部 HTTP 通信を一切行わない設計［AC-103］に統一したため、OpenAPI 契約ファイル `contracts/ndl-opensearch.yaml` は廃止し、JSON Schema による端末内境界契約に一本化している。）
