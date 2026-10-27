# アプリの地図

このファイルはこのアプリの地図です。tech-lead（テックリード）が手入れし、100行以内に保ちます。
アプリ名と一言の説明は .claude/org/app.json の app_name と idea にあります。
組織の決まりは .claude/rules/org.md、関門は docs/org/gates.md、進み具合は docs/progress.md を読みます。

## 概要
- 何のアプリか：夜、ロック画面のウィジェットや Live Activity に出る「自分の本の続きの一行」から読み始め、伏せて読み（電子書籍は同じ iPhone でも数え）、しおり（一行とページ・位置No.・%）を挟んで閉じ、読み終えた夜に奥付・カード・推薦（積読＋端末内書誌 DB 約295万冊＋受賞＋共起の器）で次の1冊へ渡す iPhone の読書アプリ（「よむま」）。データは端末の中だけで、アプリの外部 HTTP 通信は0件（AC-103）。
- 使う人：平日の夜にスマホへ流れて、本を開けずにいる人（PRD の 13）。iOS 26 以上の iPhone を使う人。
- いまの段階：001-reading-session の G2/G3。全149 AC（AC-1〜AC-149）を v1.0 対象とし、`ios/`（アプリ、拡張、ローカル Swift パッケージ `ReadingKit`、単体テスト）と `ios/AcceptanceTests/`（全149 AC の受け入れテスト）が実装され、`make ios-build`・`make ios-test`・`make ios-test-first-launch`・`make ios-test-perf`・`make check-contracts` が実動確認済み。

## ビルド/テストのコマンド
.claude/org/app.json の commands（`ios_build`: `"make ios-build"`, `ios_test`: `"make ios-test"`, `backend_test`: `""`）と同じものを書きます。CI は app.json の方を使います。
コマンドを変えたら、app.json の更新を Takuma に頼みます（.claude/ は Takuma だけが直せます）。
受け入れテストは、受け入れテストのフォルダの中の設定だけで動く形にします。

### iOS（すべて動かして確かめた）
- ビルド（`app.json` の `ios_build`）：`make ios-build`
  - 中身：`xcodebuild -project ios/ReadingApp.xcodeproj -scheme ReadingApp -configuration Debug -destination 'generic/platform=iOS Simulator' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build`（`** BUILD SUCCEEDED **` を確認済み）
- テスト（`app.json` の `ios_test`）：`make ios-test`
  - 中身：`swift test --package-path ios/ReadingKit` と `xcodebuild test -project ios/ReadingApp.xcodeproj -scheme ReadingApp -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.0' -skip-testing:ReadingAcceptanceTests/FirstLaunchTests -skip-testing:ReadingAcceptanceTests/PerformanceTests`（実動確認済み）
- 初回起動端末テスト（H14、AC-1）：専用シミュレーターを `xcrun simctl erase <端末>` で消してから `make ios-test-first-launch`（`-only-testing:ReadingAcceptanceTests/FirstLaunchTests`）を単独で動かす（実動確認済み）。
- 速さの AC（AC-55、AC-100〜102、AC-114、AC-115、AC-149）：`make ios-test-perf`（`-configuration Perf`、Release と同じ `-O` に `UITEST_HOOKS` のみ付与、`-only-testing:ReadingAcceptanceTests/PerformanceTests`、実動確認済み）。

### バックエンド
- なし（自前のサーバーも外部 API 通信も持たない。PRD 10、AC-103）。

### 契約の検査（動かして確かめた。版と入れ方は contracts/dependencies.md）
- OpenAPI（spectral / oasdiff）：外部 HTTP 通信を0件（AC-103）にしたため `contracts/ndl-opensearch.yaml` は廃止・削除した（ADR 0004）。
- JSON Schema（jsonschema 4.25.1。`make check-contracts`）：
  - コマンド：`make check-contracts`
  - 出力：`ALL PASSED: 8 schemas, 25 examples validated with 0 errors.`

## 構成
既定の場所です。app.json の paths を変えたら、この表も同じに直します（バックエンドはサーバーがないので使わない）。

| 場所 | 中身 | 書く役 |
|---|---|---|
| ios/ | iOS アプリ（`ReadingApp`）、Widget/Live Activity/Control 拡張（`ReadingWidgetExtension`）、Background Assets 拡張（`ReadingBackgroundAssetsExtension`）、ローカル Swift パッケージ `ReadingKit`（`ReadingCore`、`ReadingStore`）と単体テスト | ios-engineer |
| ios/AcceptanceTests/ | iOS の受け入れテスト（XCUITest、AC-1〜AC-149） | verifier |
| contracts/ | 契約（`widget-snapshot.schema.json`、`entry-urls.md`、`test-hooks.md`、`hooks/*.schema.json`）、依存ライブラリの許可リスト（`dependencies.md`） | tech-lead |
| .gitignore、README.md、Makefile、fastlane/ など | ルートの設定ファイル | tech-lead |
| design/ | 調査（`<機能名>-research.md`）、画面の仕様、デザイントークン、文言 | designer |
| docs/prd/、docs/support/、metadata/ | PRD、受賞作一覧（`001-reading-session-awards.md`）、サポートページ、ストア掲載文 | pdm |
| docs/adr/ | 技術判断の記録（`0001`〜`0005`）、機能ごとの技術設計メモ（`docs/adr/features/`） | tech-lead |
| docs/verification/ | テスト計画、検証レポート、証拠 | verifier |
| docs/progress.md、docs/reviews/、docs/approvals/ | 進捗、判定の記録、Takuma の承認 | 指揮役 |
| .claude/、.github/ | 組織の定義と CI（キットが管理） | Takuma だけ |

## このアプリだけの決まり
- 全149 AC（AC-1〜AC-149）を v1.0 で一括実装する（v1.1 先送りなし）。最低 iOS 26.0、iPhone 専用（縦向き固定）。Xcode 26 以降と iOS 26 以降の SDK でビルドする（ADR 0001）。
- Swift 6 の言語モード、並行性の検査は完全（`SWIFT_STRICT_CONCURRENCY = complete`）、警告は0件（`SWIFT_TREAT_WARNINGS_AS_ERRORS=YES`）。
- サードパーティの外部ライブラリは0個。Apple の標準フレームワークと OS 同梱の `libsqlite3.tbd` だけを使う（`contracts/dependencies.md`）。
- アプリとウィジェット拡張から外部への HTTP 通信は0件（AC-103）。`URLSession`、`NWConnection`、`WKWebView` 等は使わない。
- 書誌・共起データベース（`catalog.sqlite`、NDL CC BY 4.0 書誌約295万冊、FTS5 `trigram` 索引、ISBN 主キー、`cooccurrence` テーブル）は Apple-Hosted Background Assets で配信し、App Group コンテナに置いて `isExcludedFromBackup = true` を設定する（ADR 0002、0004）。
- 保存と共有（ADR 0002）：保護の等級は既定の `.completeUntilFirstUserAuthentication`（ロック中の Live Activity・Control・Siri「どこまで読んだ？」を動かすため）。拡張は App Group の `widget-snapshot.json` を読む。
- Vision OCR（ADR 0003）：`VNRecognizeTextRequest`（`.accurate`、`ja-JP`/`en-US`）でページ縦書き列、表紙・背表紙、本棚の複数背表紙（`minimumTextHeightFraction = 0.005`）、奥付を端末内で認識し、画像はファイルにも写真ライブラリにも一切残さない（AC-69、H27）。
- 構成は Debug、Perf（Release 最適化 `-O` ＋ `UITEST_HOOKS`）、Release の3つ。テストのつなぎ口（H1〜H32、欠番 H3・H11 を除く30個）は `contracts/test-hooks.md` と `contracts/hooks/*.schema.json` に従う（ADR 0005）。
- 識別子（`accessibilityIdentifier`）と文言キーは `design/001-reading-session.md` の6章・7章を正とする。Logger の書名・著者・一行・ISBN・検索語は既定の `.private` のままにする。
