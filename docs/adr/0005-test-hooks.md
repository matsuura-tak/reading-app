# ADR-0005: 受け入れテスト用フック（H1〜H32）の設計と本番ビルドでの無害化

- 日付：2026-10-25
- 状態：採用
- 関連する機能：`docs/prd/001-reading-session.md`（AC-1〜AC-149）、`design/001-reading-session.md`、`contracts/test-hooks.md`

## 背景

全 149 件の受け入れ基準（AC-1〜AC-149）を XCUITest（`ios/AcceptanceTests/`）および単体テストから決定論的・高速・外部依存ゼロで自動検証するには、以下の要素をテストハーネスから注入・観測できる必要がある。

1. **ハードウェア・センサー系**：カメラのバーコード連続読み取り（ISBN-13＋2段目 `192` Cコード、H21）、Vision OCR（ページの縦書き列・ノンブル、表紙、本棚の複数背表紙、奥付、および `PhotosPicker` スクリーンショット選択、H19）、近接＋重力センサーによる「3秒伏せて始める」（H18）、カメラ権限と実機有無（H26）、触覚フィードバック（H28）。
2. **時間・OS 拡張系**：4:00 日付境界や 24 時間上限をまたぐ時計操作（H4）、ウィジェット W-1/W-2 の表示内容と VoiceOver ラベル（H22）、夜の入口の予約 Live Activity と読書中 Live Activity（W-3、H23）、Control（W-4）と Siri / App Shortcuts（W-5：`StartReadingIntent`、`EndReadingIntent`、`WhereStoppedIntent`、`ContinueReadingIntent`、H32）。
3. **データ・課金・監査系**：初期シード投入（H2）、保存・読み込み・破損障害注入（H7）、端末内書誌・共起 SQLite DB と未取得状態のスタブ（H20）、同梱受賞作リストの検証・差し替え（H25）、StoreKit 2 買い切り課金「よむま＋」のスタブ（H30）、読み終え共有カード画像の検査（H24）、画像非保持監査（H27）、外部 HTTP 通信ゼロ監査（H29）、外部 URL 遷移記録（H31）、計測タイマー（H10）。

同時に、App Store に提出する本番実行時（テスト起動引数がない通常起動）には、これらのフックが一切発火せず、セキュリティや審査上のリスクにならない構造にする必要がある。

## 考えた選択肢と比べた結果

| 選択肢 | 良い点 | 悪い点 | 判断 |
|---|---|---|---|
| **A. 起動引数 `-reading-app-test-hooks <path>` によるゲート＋App Group 内の `TestHooks/` ディレクトリ経由の JSON ファイル I/O＋カスタム URL `readingapphook://` トリガ（採用）** | - XCUITest は別プロセスで動くため、App Group 共有ディレクトリ（または環境変数 `READING_APP_HOOK_DIR`）上の JSON ファイルを介すると、リクエスト投入とスナップショット読み出しが 100% 同期・型安全に行える<br>- 実行中にセンサー（H18）・時間経過（H4）・バーコード（H21）・インテント実行（H32）を発火させたいときは `XCUIApplication.open(URL("readingapphook://..."))` で遅延なくトリガできる<br>- 起動引数 `-reading-app-test-hooks` がない通常起動時は `TestHookRuntime.isEnabled == false` となり、`readingapphook://` URL を含む全フック処理が無視される | - Release 構成のパフォーマンステスト（AC-91、AC-94、AC-149）でも計測できるよう、フックコード自体は `#if DEBUG` で消さず、起動引数の有無でゲートする必要がある | **採用** |
| **B. アプリ内にローカル HTTP サーバーを立てて XCUITest から通信する** | - 双方向通信がしやすい | - ローカルソケット待受が H29（外部通信ゼロ監査）やネットワーク権限と干渉し、ポート競合で CI が不安定になる | 却下 |
| **C. `#if DEBUG` のみでフックを有効化する** | - Release バイナリからコードが消える | - AC-91（Release 構成でコールドスタート 0.4 秒以内）や AC-149（Release 構成でバーコード・書名検索 0.3 秒以内）を H10・H20・H21 で計測できなくなる | 却下 |

## 決めたこと

### 1. フックの有効化ゲートと安全性

- `ProcessInfo.processInfo.arguments` に `"-reading-app-test-hooks"` が含まれるときだけ `TestHookRuntime.shared.isEnabled = true` になる。
- 通常起動時（App Store 審査・一般利用者）は `isEnabled == false` であり、本番の `SystemClock`、`CatalogDatabase`（`catalog.sqlite`）、`DataScannerViewController`、`VNRecognizeTextRequest`、`CMMotionManager`、`StoreKit 2` がそのまま使われ、`readingapphook://` スキームは即座に破棄される。

### 2. 全 29 フック（H1, H2, H4〜H10, H12〜H32）の一覧と役割

（注：H3 と H11 は番号欠番。詳細なリクエスト／レスポンス形式は `contracts/test-hooks.md` および `contracts/hooks/*.schema.json` で定義する。）

| フック | 名前 | 主な検証対象 AC | 概要 |
|---|---|---|---|
| **H1** | `reset` | 全 AC | App Group 内の `State/` と `TestHooks/out/`、進行中 Live Activity、時計・障害・スタブ状態を完全初期化する |
| **H2** | `seed` | 全 AC | `h02-seed.schema.json` に従い、本棚・記録・進行中セッション・設定・推薦重みを起動前に投入する |
| **H4** | `clock` | AC-36〜49、AC-95〜96、AC-130、AC-136 | 現在時刻の固定と、`readingapphook://advance-time?seconds=<n>` による時間経過を注入する |
| **H5** | `locale` | AC-27、AC-49、AC-93 | ロケール（`ja_JP` / `en_US`）とタイムゾーン（`Asia/Tokyo` 等）を固定する |
| **H6** | `latency` | AC-94、AC-149 | 書誌 DB 検索や OCR 処理に指定ミリ秒の遅延を注入する |
| **H7** | `fault` | AC-90、AC-107、AC-119、AC-131〜133 | `store.load`、`store.corrupt`、`book.create`、`session.start`、`session.end`、`mark.save`、`record.update`、`record.delete`、`book.update`、`book.delete`、`settings.update`、`liveActivity.start`、`storekit.purchase`、`storekit.restore` の失敗を注入する |
| **H8** | `network` | AC-8、AC-14、AC-83、AC-110、AC-125 | オフライン（機内モード相当）状態を注入する |
| **H9** | `log` | AC-89、AC-95〜96 | 構造化イベントログ（`out/h09-events.jsonl`）を書き出し、禁止フィールド（`lastLine` 等）が含まれないことを検証する |
| **H10** | `perf` | AC-91、AC-94、AC-149 | `coldStartMs`、`barcodeLookupMs`、`titleSearchMs`、`ocrProcessMs` の実測値を `out/h10-perf.json` に書き出す |
| **H12** | `identifiers` | 全 UI AC | `design/001-reading-session.md` 6-2 節の全 `accessibilityIdentifier` を要素に付与する |
| **H13** | `store` | AC-15〜23、AC-53〜90、AC-139〜148 | 保存済み `state.json` と破損退避ファイル一覧を `h13-store.schema.json` 形式で `out/h13-store.json` に書き出す |
| **H14** | `ui-state` | 全画面 AC | 現在表示中の画面 ID（`S-1`〜`S-10a`）、表示中の知らせの帯（部品 N）の文言キーを `out/h14-ui-state.json` に書き出す |
| **H15** | `a11y` | AC-99〜102 | VoiceOver ラベル・トレイト・44×44pt 最小ヒット領域の検査結果を `out/h15-a11y.json` に書き出す |
| **H16** | `layout` | AC-28、AC-100 | Dynamic Type AX5 や長文での文字切れ・要素重なり検査結果を `out/h16-layout.json` に書き出す |
| **H17** | `state` | AC-36〜52、AC-114〜136 | 状態機械（`idle` / `reading`）、今の本、進行中セッション、予約・稼働中 Live Activity の要約を `h17-state.schema.json` 形式で `out/h17-state.json` に書き出す |
| **H18** | `sensor` | AC-39、AC-50〜52 | `readingapphook://face-down?active=true&durationMs=3100` による伏せ動作注入と、センサー非搭載端末（`sensorAvailable: false`）の模擬を行う |
| **H19** | `ocr` | AC-65〜70、AC-94、AC-113、AC-137〜138、AC-142 | ページ（縦書き列＋ノンブル）、表紙・背表紙、本棚（複数背表紙）、奥付の OCR 結果またはテスト画像の注入と、`PhotosPicker` のスクリーンショット自動選択を行う |
| **H20** | `catalog` | AC-3〜14、AC-78〜83、AC-92、AC-138、AC-146〜149 | `h20-ndl-stub.schema.json` に従い、端末内書誌 DB（`books`＋FTS5 `trigram`＋`cooccurrence`）のテスト用 SQLite データ投入、および DB 未取得状態（`status: "notDownloaded"`）の模擬を行う |
| **H21** | `barcode` | AC-3〜11、AC-16、AC-140、AC-149 | `readingapphook://scan-barcode?codes=9784167911300,1920193007804` 等により 1段目 ISBN-13 と 2段目 `192` Cコードの連続読み取りを注入する |
| **H22** | `widget` | AC-24〜34、AC-99、AC-106、AC-139、AC-141 | `h22-widget.schema.json` に従い、W-1（`.accessoryRectangular`）と W-2（`.systemSmall`）の描画テキスト・列数・フォント・色トークン・VoiceOver ラベルを `out/h22-widget.json` に書き出す |
| **H23** | `live-activity` | AC-36〜41、AC-97〜98、AC-114〜120、AC-130〜132、AC-136、AC-144 | 予約済み（`scheduled`）および稼働中（`active`）の Live Activity の一覧、`scheduledFor`、`staleDate`、`source`（`reconcile` / `intent` / `app`）、書名、一行、`endButtonLabel`、および OS 設定 `areActivitiesEnabled` のオーバーライドを管理し `out/h23-live-activity.json` に書き出す |
| **H24** | `share-card` | AC-84〜85、AC-106、AC-127 | S-9 で生成した読み終えカード PNG のピクセル寸法（`1080x1350`）、描画された文字列一覧、`containsSavedLine == false`、`containsReflection == false` を `out/h24-share-card.json` に書き出す |
| **H25** | `awards` | AC-19〜21、AC-83、AC-112 | 同梱受賞作リスト（芥川賞・直木賞・本屋大賞）の件数・範囲検査結果の出力と、テスト用受賞作データの差し替えを行う |
| **H26** | `permission` | AC-1、AC-12、AC-70、AC-142 | カメラ権限状態（`notDetermined` / `authorized` / `denied` / `restricted`）、カメラ利用可否（`isCameraAvailable`）、OS 権限ダイアログ要求回数を管理し `out/h26-permission.json` に書き出す |
| **H27** | `media-audit` | AC-69、AC-113、AC-137〜138、AC-142 | アプリコンテナ・App Group・一時ディレクトリ内の画像ファイル数（`savedImageFileCount`）と写真ライブラリ書き込み回数（`photoLibraryWriteCount`）を監査し `out/h27-media-audit.json` に書き出す（どちらも常に `0`） |
| **H28** | `haptics` | AC-3、AC-39 | 発火した触覚イベントの履歴を `out/h28-haptics.json` に書き出す |
| **H29** | `outbound` | AC-86、AC-103 | `URLProtocol` インターセプタによりアプリプロセスからの全 HTTP/HTTPS リクエストを監視・遮断し、`h29-outbound.schema.json` 形式で `out/h29-outbound.json` に書き出す（`totalCount == 0`） |
| **H30** | `storekit` | AC-104〜110 | StoreKit 2 の購入可否（`canMakePayments`）、商品価格表示、購入結果（`success` / `userCancelled` / `failed`）、復元結果（`restored` / `none`）を注入し、取引状態を `out/h30-storekit.json` に書き出す |
| **H31** | `opened-urls` | AC-88、AC-93 | `settings.privacyPolicy` や `settings.dataSources.license`、OS 設定遷移で要求された外部 URL の履歴を `out/h31-opened-urls.json` に書き出す |
| **H32** | `intents` | AC-114〜126、AC-131〜135、AC-143 | `readingapphook://run-intent?name=StartReadingIntent`（または `EndReadingIntent` / `WhereStoppedIntent` / `ContinueReadingIntent`）で App Intent を実行し、返却された音声ダイアログ文字列・スニペット小窓文字列・`authenticationPolicy`・`AppShortcutsProvider` の登録フレーズ一覧を `out/h32-intents.json` に書き出す |

## 引き受けること

- すべての JSON Schema（`contracts/hooks/*.schema.json` と `contracts/widget-snapshot.schema.json`）は Draft 2020-12 で記述し、`examples` を含めて `python3 -m jsonschema`（`Draft202012Validator`）でエラー 0 件であることを CI および `make check-contracts` で常時検証する。
