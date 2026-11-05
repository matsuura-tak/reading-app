# B ADR 0001：iOS の土台（対応 OS・モジュール分割・外部依存ゼロ・標準書体と伏せ検知）

- 状態：承認
- 書いた役：tech-lead　日付：2026-10-25
- 関係する PRD、設計メモ、契約：`docs/prd/001-reading-session.md`（AC-1〜AC-149）、`docs/adr/features/001-reading-session.md`、`contracts/dependencies.md`、`design/001-reading-session/tokens.md`
- 元に戻す手間：大（最低対応 OS、パッケージ境界、Strict Concurrency 分離設定、および同梱フォント・センサー方針は全ターゲットの土台になるため）

## 背景

「よむま」は、本を閉じた夜の10秒でしおりの一行と場所を残し、翌晩ロック画面のウィジェット・Live Activity・コントロール・Siri ショートカットから1タップ（または iPhone を1.0秒伏せる動作）で続きへ戻れる iPhone アプリである。

PRD（`docs/prd/001-reading-session.md`）および画面仕様（`design/001-reading-session.md`）で定義された全 149 件の受け入れ条件（AC-1〜AC-149）を v1.0 で一括実装するにあたり、以下の制約と非機能目標を同時に満たす土台を決める必要があった。

1. **起動と操作の速さ（AC-55、AC-100〜AC-102、AC-149）**：コールドスタートから S-1（しおりの画面）を操作できるまでが 5 回平均 1.0 秒（1,000ms）以内（AC-100）、「終える」から S-3 表示までが 0.5 秒（500ms）以内（AC-55）、本 500 冊・記録 5,000 件での本棚（S-6）と本の画面（S-7）表示が 5 回平均 1.0 秒以内（AC-101）、ウィジェット生成が 5 回平均 0.5 秒以内（AC-102）、端末内書誌 DB 検索が 5 回平均 0.3 秒（300ms）以内（AC-149）。
2. **完全な端末内完結と外部 HTTP 通信ゼロ（AC-103）**：アカウント作成なし、独自サーバーなし、広告・解析・クラッシュ収集 SDK なし、アプリとウィジェット拡張のプロセスから外部への HTTP/HTTPS 通信は 0 件（書誌 DB の配信は OS の Apple-Hosted Background Assets、買い切り課金「よむま＋」は OS の StoreKit 2 が担う）。
3. **電池・センサーの最小化（AC-44〜AC-51、AC-54）**：近接センサーと画面常時点灯を使わず（`isProximityMonitoringEnabled == false`、`isIdleTimerDisabled == false`）、S-1 が前面かつ `idle` の間だけ `UIDevice.current.orientation == .faceDown` の 1.0 秒デバウンスで伏せ開始を検知すること。
4. **外からフォントを入れない書体設計（AC-27〜AC-30、AC-104〜AC-111）**：アプリバンドルを肥大化させず OS 標準の書体だけで紙の佇まいと 4 つの見た目（標準 `default`、および買い切り「よむま＋」の `kinari` 生成り・`sumi` 墨・`shu` 朱）を表現すること。
5. **本体と拡張（Widget / Live Activity / Control / App Intents / Background Assets）の境界共有**：S-1〜S-10a の本体画面、ウィジェット（W-1、W-2）、夜の入口と読書中の Live Activity（W-3）、コントロール（W-4）、Siri とショートカット（W-5）、および Background Assets 拡張が、同じドメイン型・同じ縦書き組版を安全に共有できること。

## 比べた案

| 案 | 良い点 | 悪い点 | 選ばなかった理由 |
|---|---|---|---|
| **案A：iOS 26.0 以降・Swift 6.2・OS 標準フレームワークのみ＋ローカル Swift Package `ReadingKit`（`ReadingCore` / `ReadingStore`）と4ターゲット構成（採用）** | - 外部動的フレームワークと外部フォントが 0 個のため `dyld` ロード時間が最小になり、AC-100（起動 1.0 秒以内）を余裕で満たす<br>- `Activity.request(...start:)` による日時指定 Live Activity 予約（AC-36）、`ControlWidget`（W-4）、`LiveActivityIntent` / `ShowsSnippetIntent`（W-5）、`BackgroundAssets`、`Vision`、`VisionKit`、`StoreKit 2`、`SwiftData`、OS 標準 `SQLite3`（FTS5 `trigram`）がすべて OS 標準で揃う<br>- サードパーティ SDK 由来のトラッキング・通信混入リスクがゼロ（AC-103）<br>- `ReadingCore`（`nonisolated`）と `ReadingStore`（`@MainActor`）を分けることで、`swift test` の高速実行と拡張ターゲット間の安全な型共有が両立する | - iOS 25 以下の端末を切り捨てるため、旧 OS 端末の利用者はインストールできない<br>- サードパーティのラッパー（GRDB 等）を使わないため、縦書き 1 行組版（`VerticalLineLayout`）や読み取り専用 SQLite3 C API バインディング（約 200 行）を自前で保守・単体テストする必要がある | **（採用）** |
| **案B：iOS 17 / 18 互換を残し、外部ライブラリ（GRDB、TCA 等）と同梱 OFL フォント（Shippori Mincho / Klee One）を導入する** | - 旧 OS の端末でもインストールできる<br>- SQLite クエリビルダや状態管理を既存ライブラリに任せられる<br>- 独自の Web/OFL フォントで書体の個性を出せる | - iOS 26 の `Activity.request(...start:)` による日時指定 Live Activity 予約（AC-36）にフォールバック分岐が必要になり、テスト経路が倍増する<br>- 動的フレームワークと同梱フォント（約 15〜20MB）の追加によりコールドスタート（AC-100）とウィジェットのメモリ上限（30MB）を圧迫する<br>- 外部依存の Privacy Manifest 監査とライセンス管理コストが増える | AC-36（夜の入口の予約 Live Activity）と AC-100（1.0 秒起動）、および `design/001-reading-session/tokens.md` の「外からフォントを入れない」方針に反するため |
| **案C：ローカル Swift Package を作らず、単一の Xcode ターゲット群に全ソースファイルを置き Target Membership で拡張と共有する** | - `Package.swift` の管理が不要で、Xcode プロジェクトの初期設定が単純になる | - 本体専用の UIKit・カメラ（`AVFoundation` / `VisionKit`）・課金コードが `ReadingWidgetExtension` や `ReadingBackgroundAssetsExtension` に誤ってリンクされやすく、拡張のメモリ制限や審査上の API 制限に抵触しやすい<br>- シミュレーターを起動しない純粋な `swift test` が使えず、組版・正規化・推薦ロジックの単体テストフィードバックが遅くなる | 本体と拡張の責務・アクター分離をコンパイラで強制できず、保守性が低いため |

## 決定

iOS 26.0 以降・Swift 6.2（Strict Concurrency Complete）・外部依存ゼロ・外部同梱フォントゼロとし、ローカル Swift Package `ReadingKit`（`ReadingCore` と `ReadingStore` の 2 ライブラリ）＋本体・拡張・受け入れテストの 4 ターゲット構成を採用する。状態管理は標準の `@Observable`（`@MainActor`）で行い、伏せ検知は `CoreMotion` や近接センサーを使わず `UIDevice.current.orientation == .faceDown` の 1.0 秒デバウンスで行う。

### 1. 対応 OS・言語・並行性・強制アップデート方針
- **対応 OS と端末**：iOS 26.0 以降（`IPHONEOS_DEPLOYMENT_TARGET = 26.0`）、iPhone 専用（`TARGETED_DEVICE_FAMILY = 1`、Portrait 縦向き固定）。ビルドは Xcode 26 以降と iOS 26 以降の SDK で行う。
- **言語と並行性**：Swift 6.2 言語モード、並行性検査は「完全」（`SWIFT_STRICT_CONCURRENCY = complete`）、警告は 0 件（`SWIFT_TREAT_WARNINGS_AS_ERRORS = YES`）。
- **アクター分離の既定値**：
  | 単位 | 既定のアクター分離 | 理由 |
  |---|---|---|
  | `ReadingApp`（本体アプリ） | `@MainActor` | UI・カメラ・App Shortcuts の駆動が中心のため |
  | `ReadingWidgetExtension` | `@MainActor` | Widget / Live Activity / Control の View 構築が中心のため |
  | `ReadingBackgroundAssetsExtension` | `nonisolated` | バックグラウンドでの `catalog.sqlite` ファイル配置のみを担うため |
  | `ReadingCore`（ローカル Package） | `nonisolated` | 縦書き組版計算・ISBN/Cコード解析・OCR 行クラスタリング・著者名整形・推薦重み計算などの純粋関数をどのスレッドからも呼べるようにするため |
  | `ReadingStore`（ローカル Package） | `@MainActor`（SQLite クエリ実行部は専用 `actor` / `@concurrent`） | SwiftData の `ModelContext`・App Group スナップショット同期・StoreKit 2・Live Activity 調整をメインアクターで一貫管理するため |
- **状態管理**：Observation フレームワーク（`@Observable`）に統一し、Combine や `ObservableObject`、TCA 等の外部フレームワークは使わない。
- **強制アップデート**：このアプリは自前のバックエンドサーバーを持たず外部 HTTP 通信を 0 件（AC-103）とするため、サーバー応答ヘッダーによる強制アップデート機構は設けない。データ形式の互換性は端末内の SwiftData `VersionedSchema` と `widget-snapshot.json` の `version` フィールドで守る（ADR 0002）。

### 2. 外部依存ゼロ・外部フォント同梱ゼロ・センサー制限
- **外部ライブラリゼロ**：SwiftPM / CocoaPods / Carthage のサードパーティライブラリは 0 個とする（`contracts/dependencies.md`）。`Package.resolved` も作らない。
- **外部フォント同梱ゼロ（`design/001-reading-session/tokens.md` 2節）**：
  - `ShipporiMinchoB1` や `KleeOne` 等の外部フォントファイルは一切同梱しない。
  - しおりの一行・書名・読み終えカードの明朝体には iOS 標準搭載の **ヒラギノ明朝 ProN**（`Hiragino Mincho ProN`、`HiraMinProN-W3` / `HiraMinProN-W6`）を使い、UI ラベル・ボタン・数字にはシステムフォント（SF Pro / ヒラギノ角ゴシック、数字は `.monospacedDigit()`）を使う。
  - 買い切り「よむま＋」（商品 ID `jp.yomuma.plus`、AC-104〜AC-111）の 4 つの見た目（`default` 標準、`kinari` 生成り、`sumi` 墨、`shu` 朱）は、フォントの差し替えではなく `design/001-reading-session/tokens.md` に定義された紙色・墨色・朱色のカラートークン（ライト／ダーク／ハイコントラスト対応）で表現する。
- **伏せ検知とセンサー制限（AC-44〜AC-51、AC-54）**：
  - **`CoreMotion`（`CMMotionManager`）と近接センサーは一切使わない**（`contracts/dependencies.md` 35行）。
  - 画面が消えるのを防ぐ設定も使わず、常時 `UIApplication.shared.isIdleTimerDisabled == false` かつ `UIDevice.current.isProximityMonitoringEnabled == false` を維持する（AC-54）。
  - 伏せて読み始める動作は、S-1（しおりの画面）が前面にあり、状態が `idle`、今の本が 1 冊あり、シートや知らせの帯が出ておらず、`settings.flipToStart == true` の間だけ `UIDevice.orientationDidChangeNotification` を監視し、`UIDevice.current.orientation == .faceDown` が **1.0 秒（1,000ms）** 継続したときに触覚（`UIImpactFeedbackGenerator(style: .light)`）1 回と VoiceOver 通知（`session.flipStarted.announcement`）1 回を出して `reading` に遷移する（AC-44、AC-45、AC-47、AC-49）。0.9 秒以内に起こされた場合はキャンセルする（AC-45）。

### 3. モジュールとターゲット構成

```text
ios/
├── ReadingApp.xcodeproj
├── ReadingKit/                          # ローカル Swift Package（外部依存 0 個）
│   ├── Package.swift
│   ├── Sources/
│   │   ├── ReadingCore/                 # 純粋ドメイン・縦書き組版・ISBN/Cコード解析・OCR 整形・著者名整形・推薦重み計算
│   │   └── ReadingStore/                # SwiftData 主保存先・App Group 写し・SQLite 書誌/共起 DB・受賞辞書・StoreKit 2・Live Activity 調整
│   └── Tests/
│       ├── ReadingCoreTests/            # 単体テスト（25字短縮・縦書きグリフ置換・行頭禁則・著者名整形・推薦スコア等）
│       └── ReadingStoreTests/           # 単体テスト（SwiftData 永続化・ロールバック・SQLite FTS5・スナップショット出力等）
├── ReadingApp/                          # 本体ターゲット（S-1〜S-10a、部品 N、カメラ/OCR UI、App Shortcuts、#if UITEST_HOOKS）
├── ReadingWidgetExtension/              # 拡張ターゲット（W-1 ロック画面、W-2 小、W-3 Live Activity、W-4 ControlWidget）
├── ReadingBackgroundAssetsExtension/    # 拡張ターゲット（Apple-Hosted Background Assets の catalog.sqlite 配置）
└── AcceptanceTests/                     # XCUITest 受け入れテストターゲット（ReadingAcceptanceTests、verifier が管理）
```

## いちばん強い反論と、それでも選んだ理由

- **いちばん強い反論**：「iOS 26.0 以降に限定すると iOS 18 以前の端末を使っている利用者を獲得できず、また `UIDevice.orientation == .faceDown` だけではベッドの上で斜めに伏せたときや布団の上に置いたときの角度を `CMMotionManager` の重力ベクトルほど細かく調整できないのではないか。」
- **それでも選んだ理由**：
  1. 毎晩決まった時刻にロック画面へ夜の入口を出す予約 Live Activity（`Activity.request(...start:)`、AC-36）は iOS 26 の ActivityKit API を前提としており、この体験こそが「夜、スマホへ流れて本を開けない人を1タップで本へ戻す」というプロダクトの核（PRD 1章・13章）だからである。
  2. `CoreMotion` と近接センサーを使わず `UIDevice.orientation == .faceDown` の 1.0 秒デバウンスに絞ることで、近接センサーによる意図しない画面暗転や電池消費を完全に防ぎ（AC-54）、かつ XCUITest の標準 API（`XCUIDevice.shared.orientation = .faceDown`、H15）と仮想時計（H4/H5/H16）だけで 0.9 秒と 1.0 秒の境界を 100% 決定論的に自動検証できるからである（`docs/reviews/001-reading-session-G0-tech-lead-flip-research.md`）。

## 招く悪い結果

- **これで楽になること**：
  - 外部ライブラリと外部フォントが 0 個のため、サプライチェーン攻撃・SDK 由来の通信混入・フォントライセンス表示漏れのリスクがゼロになり、起動速度（AC-100：1.0 秒以内）と外部通信ゼロ（AC-103）を確実に守れる。
  - ドメインと組版ロジックが `ReadingCore` に分離されているため、本体と `ReadingWidgetExtension` で縦書き組版（`VerticalLineLayout`）のズレが起きない。
- **これで難しくなること、守り続けること**：
  - iOS 26.0 未満の端末には配信できない。
  - SQLite3 C API の読み取りラッパー（`sqlite3_open_v2` / `sqlite3_prepare_v2`）と縦書き組版エンジンを `ReadingKit` 内で自前保守し、境界値の単体テストを維持し続ける必要がある。
- **元に戻すときの手順と手間**：
  - もし SQLite ラッパーや組版に外部ライブラリを導入したくなった場合は、`contracts/dependencies.md` に検証結果を追加して `ReadingKit/Package.swift` の `dependencies` に 1 行追加する（手間：中、2〜3 日）。

## 見直す条件

1. G3 の性能検証（Perf 構成）または G4 の実機検証（G4-15）において、コールドスタート 5 回平均が **1.0 秒（1,000ms）** を超えるか、書誌 DB 検索 5 回平均が **0.3 秒（300ms）** を超え、2 日以内に標準構成のチューニングで解消できない場合。
2. 公開後 30 日（Day 30）の時点で、G4-7 / 実機利用において `UIDevice.orientation == .faceDown` 1.0 秒デバウンスの誤発火または不発に関するサポート問い合わせが **全利用者の 3% 以上** 発生した場合（その場合は v1.1 で加速度センサー併用の ADR を起案する）。
3. 公開後 90 日（Day 90）の時点で、iOS 26 未満の利用者からの対応要望がレビュー・問い合わせの **20% 以上** を占め、かつ iOS 26 の普及率が想定を下回った場合。

## 確かめたこと

- Apple Upcoming Requirements（Xcode 26 / iOS 26 SDK 要件）：https://developer.apple.com/news/upcoming-requirements/ （2026-10-25 確認）
- Apple Organizing Your Code with Local Packages：https://developer.apple.com/documentation/xcode/organizing-your-code-with-local-packages （2026-10-25 確認）
- Apple Migrating to the `@Observable` macro：https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro （2026-10-25 確認）
- Swift 6.2 Released（Approachable Concurrency / Default Actor Isolation）：https://www.swift.org/blog/swift-6.2-released/ （2026-10-25 確認）
- 伏せ検知の spike（`docs/reviews/001-reading-session-G0-tech-lead-flip-research.md`、2026-10-20 実行）：シミュレーター iPhone 17 で `XCUIDevice.shared.orientation = .faceDown` により `UIDevice.orientationDidChangeNotification` が発火し、`isProximityMonitoringEnabled == false` かつ `isIdleTimerDisabled == false` のまま 1.0 秒デバウンスで `reading` へ遷移できることを確認済み。
- ルート `Makefile` のビルド・テストコマンド確認（2026-10-25 実行）：
  ```text
  $ make check-contracts
  ALL PASSED: 8 schemas, 25 examples validated with 0 errors.
  ```

## 確かめ（B）
- [x] 案が2つ以上あり、どの案にも悪い点が書いてある
- [x] 反論、悪い結果、見直す条件が空でない
- [x] 確かめたことに、URL かコマンドの出力がある
