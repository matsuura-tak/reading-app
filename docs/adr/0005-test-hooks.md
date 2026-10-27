# B ADR 0005：受け入れテスト用フック（H1〜H32）の設計と本番ビルドからの完全除外

- 状態：承認
- 書いた役：tech-lead　日付：2026-10-25
- 関係する PRD、設計メモ、契約：`docs/prd/001-reading-session.md`（11章、AC-1〜AC-149）、`docs/adr/features/001-reading-session.md`、`contracts/test-hooks.md`、`contracts/hooks/*.schema.json`
- 元に戻す手間：大（全 149 件の受け入れテストが H1〜H32 の起動引数・環境変数・Darwin 通知・`hook.*` 要素識別子に依存するため）

## 背景

全 149 件の受け入れ条件（AC-1〜AC-149）を XCUITest（`ios/AcceptanceTests/`）から `@testable import` や `sleep` を使わずに決定論的・高速・外部依存ゼロで自動検証するには、以下の要素をテストプロセスから注入・観測できるつなぎ口（H1〜H32、欠番 H3・H11 を除く 30 個）が必要である。

1. **ハードウェア・センサー・権限系**：バーコード連続読み取り（ISBN-13＋2 段目 `192` C コード、H21）、Vision OCR と `PhotosPicker` スクリーンショット選択（H19）、`XCUIDevice.shared.orientation = .faceDown` と仮想時計による「1.0 秒伏せて始める」（H15、H16）、伏せ非対応端末の模擬（H18）、カメラ権限状態（H26）。
2. **時間・OS 拡張・インテント系**：時刻固定（H4）と実行中の時刻進行（H5）、タイムゾーン固定（H6）、ウィジェット W-1/W-2 の組版・VoiceOver 検証（H22）、Live Activity の予約・即時開始・8 時間上限終了と要求履歴（H23）、入口 URL 起動（H28）、App Intents 4 種（`StartReadingIntent`、`EndReadingIntent`、`WhereStoppedIntent`、`ContinueReadingIntent`）と App Shortcuts / Control の検査（H32）。
3. **データ・課金・監査・性能系**：初期化（H1）、シード投入（H2）、保存・読込失敗注入（H7）、通信なし（H8）、状態・合図・監視読み出し（H9、H17）、区間速度計測（H10）、文言キー照合（H12）、ストア全項目読み出し（H13）、初回起動端末消去（H14）、端末内書誌・共起 SQLite DB スタブ（H20）、読み終え共有カード検査（H24）、受賞一覧の差し替え・全行読み出し（H25）、画像ファイル 0 個・写真ライブラリ書き込み 0 回監査（H27）、外部 HTTP 通信 0 件監査（H29）、StoreKit 2 差し替えと返金通知（H30）、開いた外部 URL 記録（H31）。

同時に、App Store に提出する Release ビルド（本番バイナリ）にはテスト用フックの型・シンボル・分岐が 1 つも残らないようにし、かつ Release と同じ最適化（`-O`）で速度 AC（AC-55、AC-100〜AC-102、AC-114、AC-115、AC-149）を計測できる構成にする必要がある。

## 比べた案

| 案 | 良い点 | 悪い点 | 選ばなかった理由 |
|---|---|---|---|
| **案A：3つのビルド構成（`Debug` / `Perf` / `Release`）＋ `#if UITEST_HOOKS` による本番バイナリからの完全除外＋起動引数 `-uitest-*` / 環境変数 `UITEST_*`＋Darwin 通知 `yomuma.uitest.*`＋透過 UIWindow 上の 1×1pt 要素 `hook.*` 読み出し（採用）** | - `Release` 構成では `UITEST_HOOKS` を定義しないため、コンパイル時にフックのコード・型（`UITestHook*`）がバイナリから 100% 消え、G2/G4 の `nm` / `strings` 検査で不在を証明できる<br>- `Perf` 構成（`-O` 最適化＋`UITEST_HOOKS`＋`-uitest-readouts off`）により、本番と同じ最適化状態で速度 AC を正確に計測できる<br>- 実行中の時刻進行（H5）やバーコード注入（H21）を Darwin 通知（`notify_set_state` + `notify_post`）で行うため、カスタム URL スキームの SpringBoard 確認ダイアログや前面遷移副作用が一切起きない<br>- 1×1pt の非対話 `UIWindow` 上の `hook.*` 要素の `accessibilityValue` で JSON を読むため、押せる要素数（`buttons.count`）を変えず、シートやアラート表示中も 63ms（91,500 字時）で高速に読める | - Xcode プロジェクトに `Debug`・`Perf`・`Release` の 3 構成を定義し、`UITestHooks/` フォルダ配下にフック実装を集約する規律を守る必要がある<br>- アプリを強制終了して引数なしで再起動するテスト（AC-53、AC-89 等）でも時計や障害注入を引き継ぐため、App Group 内の `UITestHooks/config.json` に設定を書き出す処理が必要になる | **（採用）** |
| **案B：カスタム URL スキーム `readingapphook://` で実行中のフック（時刻進行・伏せ・バーコード・インテント）を発火させ、App Group の `TestHooks/out/*.json` ファイルを XCUITest から直接読む** | - `import notify` や読み出し専用 `UIWindow` を作らなくてよい | - XCUITest プロセスと被テストアプリのサンドボックス境界により、実機や一部のシミュレーター設定で App Group パスをテストターゲットから直接読めない<br>- `app.open(URL("readingapphook://..."))` を呼ぶたびにシステムがアプリを前面にアクティブ化してしまい、バックグラウンド経過（AC-52）や画面状態を変えずに時計を進めるテストが壊れる<br>- Release バイナリにカスタム URL スキームやフック分岐が残るリスクがある | バックグラウンド計測や非破壊トリガと両立せず、`contracts/test-hooks.md` の方式と矛盾するため |
| **案C：アプリ内にローカル HTTP サーバーを立てて XCUITest から REST リクエストで状態注入・読み出しを行う** | - テスト側から任意の JSON リクエストを送受信しやすい | - ローカルソケット待受が H29（外部通信ゼロ監査、AC-103）やネットワーク権限と干渉し、CI でのポート競合やバックグラウンド凍結によるタイムアウトを引き起こす | AC-103 の通信ゼロ検証と衝突し、テストの決定論性を損なうため |

## 決定

`contracts/test-hooks.md` および `contracts/hooks/*.schema.json` の定義どおり、ビルド構成を `Debug`・`Perf`・`Release` の 3 つに分け、すべてのフック実装をアプリターゲットの `UITestHooks/` 配下に置いて `#if UITEST_HOOKS` で包み、`Release` バイナリから完全に除外する。起動時の設定は `-uitest-*` 引数と `UITEST_*` 環境変数（および再起動引き継ぎ用の `UITestHooks/config.json`）、実行中の状態変更は Darwin 通知 `yomuma.uitest.*`、状態の読み出しは非対話 `UIWindow` 上の `hook.*` アクセシビリティ要素で行う。

### 1. ビルド構成と命名規則（`contracts/test-hooks.md` 1-1、1-2）

| 構成 | `UITEST_HOOKS` | 最適化 | 用途 |
|---|---|---|---|
| `Debug` | 有効 | `-Onone` | 開発、G3 の機能・画面・ウィジェット受け入れテスト |
| `Perf` | 有効 | `-O`（Release と同一） | 速度 AC（AC-55、AC-100〜AC-102、AC-114、AC-115、AC-149）、`-uitest-readouts off` 併用 |
| `Release` | **無効（完全除外）** | `-O` | TestFlight（G4）、App Store 提出（G5）。`os_signpost` のみ残す |

- **命名規則**：
  - 起動引数：`-uitest-<名前>`
  - 環境変数：`UITEST_<名前>`
  - Darwin 通知：`yomuma.uitest.<名前>`
  - 読み出し要素の `accessibilityIdentifier`：`hook.<名前>`
  - Swift の型名：`UITestHook` で始める（G2 で `nm` / `grep` により Release バイナリに `UITestHook` が 0 件であることを検査する）。

### 2. 実行中トリガ（Darwin 通知 7 種）と読み出し要素（`hook.*` 11 種）

- **Darwin 通知（`import notify`、`notify_set_state` + `notify_post`）**：
  1. `yomuma.uitest.clock`：H4 の起点から進めたミリ秒（H5、および H16 の 1.0 秒伏せデバウンス判定）
  2. `yomuma.uitest.offline`：`1`＝通信なし、`0`＝通信あり（H8）
  3. `yomuma.uitest.ocr.release`：H19 の `hold: true` 待機解除（AC-94）
  4. `yomuma.uitest.barcode`：13 桁の整数（ISBN-13 または `192` 始まりの 2 段目 C コード、H21）
  5. `yomuma.uitest.liveactivity.transition`：`1`＝予約を `started` に遷移、`2`＝進行中を 8 時間上限 `dismissedBySystem` に遷移（H23）
  6. `yomuma.uitest.storekit.refund`：`1`＝購入を返金状態に遷移（H30、AC-111）
  7. `yomuma.uitest.intent.run`：`1`＝`StartReadingIntent`、`2`＝`EndReadingIntent`、`3`＝`WhereStoppedIntent`、`4`＝`ContinueReadingIntent`（H32）
- **読み出し要素（`app.descendants(matching: .any)["hook.<名前>"].value as? String`）**：
  - `hook.state`（H9、H10、H17：`h17-state.schema.json`）、`hook.store`（H13：`h13-store.schema.json`）、`hook.widget`（H22：`h22-widget.schema.json`）、`hook.liveActivity`（H23）、`hook.shareCard`（H24）、`hook.awards`（H25）、`hook.mediaAudit`（H27）、`hook.outbound`（H29、H31：`h29-outbound.schema.json`）、`hook.storekit`（H30）、`hook.intents`（H32）、`hook.error`（契約違反時 `<H番号>:<理由>`）。

### 3. 全 30 フック（H1、H2、H4〜H10、H12〜H32）の要約

（注：H3 は H2 の `activeSession` に統合、H11 は外部計測送信なしのため欠番。）

| フック | 手段 | 主な検証対象 AC | 役割 |
|---|---|---|---|
| **H1** | `-uitest-reset` | AC-2〜12、AC-16、AC-32、AC-46、AC-51、AC-53、AC-58、AC-89、AC-90、AC-92、AC-103、AC-117、AC-122、AC-126、AC-135、AC-137、AC-139 | 主の保存先・App Group の写し・UserDefaults・Live Activity・フック記録を完全初期化する |
| **H2** | `UITEST_SEED` / `-uitest-seed-preset perf500` | AC-3、AC-7、AC-13〜64、AC-75〜82、AC-85〜91、AC-93、AC-95〜102、AC-104、AC-113〜125、AC-127〜136、AC-138、AC-140〜148 | `h02-seed.schema.json`（または 500 冊・5,000 件の `perf500`）を主の保存先に投入し写しを書く |
| **H4** | `-uitest-now <RFC3339>` | AC-33〜41、AC-48、AC-52〜63、AC-65、AC-75、AC-76、AC-86、AC-89、AC-95、AC-97、AC-98、AC-104、AC-114〜125、AC-130〜136、AC-139、AC-141、AC-144 | アプリの現在時刻の起点を固定する |
| **H5** | `yomuma.uitest.clock` | H4 と同じ＋AC-54、AC-103 | `sleep` なしで起点からの経過ミリ秒を進め、伏せデバウンス・経過時間・`staleDate` を再判定させる |
| **H6** | `-uitest-timezone <IANA>` | AC-22、AC-34、AC-36、AC-38、AC-85、AC-89、AC-97、AC-98、AC-114、AC-115、AC-120、AC-127、AC-128、AC-130、AC-136、AC-139 | タイムゾーン（既定 `Asia/Tokyo`）を固定する |
| **H7** | `-uitest-fail-save <target>:<count>[:<kind>]` | AC-59、AC-60、AC-90、AC-91（7 通り）、AC-95、AC-119、AC-132、AC-133 | 指定した保存または `store.load` を指定回数だけ失敗させる |
| **H8** | `-uitest-offline` / `yomuma.uitest.offline` | AC-6、AC-62、AC-110、AC-125 | アプリの通信状態をオフライン／オンラインに切り替える |
| **H9** | `hook.state` | AC-39、AC-42〜48、AC-51、AC-53、AC-54、AC-56、AC-58〜61、AC-64、AC-114〜119、AC-121、AC-123、AC-124、AC-130〜136、AC-139 | `state`（`idle`/`reading`）、`idleTimerDisabled`（常に `false`）、`proximity`（常に `false`）を読む |
| **H10** | `hook.state`（`lat.*` / `prevLat.*`）＋ `os_signpost` | AC-55、AC-94、AC-101、AC-114、AC-115、AC-149 | 8 区間の実時間（`ContinuousClock` ミリ秒）を計測・読み出す |
| **H12** | テスト側の `Localizable.xcstrings` 照合 | AC-16、AC-56〜60、AC-90、AC-91、AC-95、AC-96 ほか全画面 | 文言キーと同名の `accessibilityIdentifier` 要素のラベルを日英カタログと照合する |
| **H13** | `hook.store` | AC-2〜16、AC-22、AC-24〜26、AC-61、AC-64、AC-67〜75、AC-77、AC-82、AC-83、AC-87、AC-89〜92、AC-95、AC-96、AC-105〜109、AC-111、AC-113〜125、AC-130〜135、AC-137〜147 | 主の保存先の全項目と写しを `h13-store.schema.json` 形式で読む（読込失敗中は空文字列 `""`） |
| **H14** | `xcrun simctl erase`＋`FirstLaunchTests` | AC-1 | 消去済み端末で初回起動を単独実行し、システム権限アラートが 0 件であることを検証する |
| **H15** | `XCUIDevice.shared.orientation` | AC-44〜49、AC-51、AC-54、AC-59 | `.faceDown` / `.portrait` / `.faceUp` の向き変更を発生させる |
| **H16** | アプリ内仮想タイマー（H4/H5 連動） | AC-44〜49、AC-51、AC-54、AC-59 | 伏せの **1.0 秒（1,000ms）** デバウンス（999ms では開始せず、1,000ms で開始）を `sleep` なしで判定する |
| **H17** | `hook.state` | AC-3、AC-39、AC-40、AC-44〜49、AC-51、AC-54、AC-59、AC-96、AC-114、AC-116、AC-118、AC-124、AC-130、AC-131 | `flipMonitoring`、`startedBy`、`haptic`、`announce`、`notice`、`entry`、`sessionEntry`、`entryCandidate`、`widgetReloads` を読む |
| **H18** | `-uitest-flip-unavailable` | AC-51 | 伏せ検知非対応環境を模擬し、`settings.flipToStart.unavailable` 表示と `flipMonitoring=off` を検証する |
| **H19** | `UITEST_OCR`＋`yomuma.uitest.ocr.release` | AC-65〜69、AC-94、AC-113、AC-137、AC-138、AC-142 | ページ（縦書き列・ノンブル）、表紙、本棚（複数背表紙）、奥付の OCR 結果と `PhotosPicker` 選択、`hold` 待機を注入する |
| **H20** | `UITEST_NDL_STUB` | AC-2〜6、AC-9〜11、AC-78〜81、AC-87、AC-92、AC-103、AC-138、AC-140、AC-146〜149 | `h20-ndl-stub.schema.json` に従い、端末内書誌 SQLite DB（FTS5 `trigram`）・共起テーブル・DB 未取得（`notDownloaded`）を差し替える |
| **H21** | `-uitest-barcode-fake`＋`yomuma.uitest.barcode` | AC-2、AC-3、AC-6、AC-9〜11、AC-92、AC-103、AC-140、AC-149 | 1 段目 ISBN-13、2 段目 `192` C コード、および非書籍 JAN コード（`490` 等）を 1 件ずつ注入する |
| **H22** | `-uitest-widget` / `-uitest-widget-show` / `hook.widget` | AC-14、AC-16、AC-27〜35、AC-37、AC-40、AC-62、AC-64、AC-73、AC-82、AC-97、AC-99、AC-102、AC-106、AC-111、AC-125、AC-139〜141 | W-1/W-2 の組版（グリフ・回転角・列頭禁則・25字短縮）、進み具合、VoiceOver ラベル、生成時間を `h22-widget.schema.json` で読む |
| **H23** | `UITEST_LIVE_ACTIVITY`＋`yomuma.uitest.liveactivity.transition`＋`hook.liveActivity` | AC-34、AC-36〜41、AC-97、AC-98、AC-114〜120、AC-125、AC-130〜132、AC-136、AC-139、AC-144 | Live Activity の利用可否・失敗・状態遷移を注入し、`activities` と要求履歴 `requests`（`source` 付き）を読む |
| **H24** | `hook.shareCard` | AC-84、AC-85、AC-103、AC-127 | 共有シートに渡された読み終えカード PNG（1080×1350px）の文字列と `containsSavedLine == false`、`containsReflection == false` を読む |
| **H25** | `UITEST_AWARDS`＋`hook.awards` | AC-17〜21、AC-77〜83、AC-87、AC-112、AC-146、AC-147 | 受賞一覧のテスト用差し替えと、同梱本番一覧の全行読み出し（AC-112）を行う |
| **H26** | `-uitest-camera <status>[:<answer>]` | AC-1〜3、AC-6、AC-9〜12、AC-65〜70、AC-92、AC-94、AC-103、AC-113、AC-137、AC-138、AC-140、AC-142 | カメラ権限状態（`notDetermined` / `authorized` / `denied` / `restricted` / `unsupported`）を差し替える |
| **H27** | `hook.mediaAudit` | AC-69、AC-113、AC-137、AC-138、AC-142 | 保存領域と App Group の画像ファイル数（`0`）および写真ライブラリ書き込み回数（`0`）を監査する |
| **H28** | `app.open(URL("yomuma://open?entry=..."))` | AC-40、AC-62 | W-1（`lock_widget`）、W-2（`small_widget`）、W-3（`live_activity`）の入口 URL で起動する |
| **H29** | `hook.outbound`（`requests`） | AC-2、AC-6、AC-9、AC-10、AC-103 | アプリが出した外部 HTTP 通信要求が `[]`（0 件）であることを検証する |
| **H30** | `UITEST_STOREKIT`＋`yomuma.uitest.storekit.refund`＋`hook.storekit` | AC-104〜111 | StoreKit 2「よむま＋」の購入・キャンセル・失敗・復元・決済不可・返金を差し替え、状態を読む |
| **H31** | `hook.outbound`（`openedURLs`） | AC-88、AC-93 | プライバシーポリシー URL と CC BY 4.0 ライセンス URL のオープン要求を記録する |
| **H32** | `UITEST_INTENT` / `-uitest-run-intent` / `yomuma.uitest.intent.run` / `hook.intents` | AC-114〜126、AC-131〜135、AC-143、AC-144 | 4 種の App Intents を駆動し、声（`spokenText`）・小窓（`snippetTexts`）・認証ポリシー・登録済み Shortcuts 3 種と Control 1 種を読む |

## いちばん強い反論と、それでも選んだ理由

- **いちばん強い反論**：「`#if UITEST_HOOKS` で Release バイナリからフックを完全に除外すると、本番に出す Release バイナリそのものに対して H10（区間速度）や H29（外部通信 0 件）の自動テストを走らせることができないのではないか。」
- **それでも選んだ理由**：
  1. 本番バイナリ（Release）にデータ初期化（H1）や課金バイパス（H30）のコードパスを 1 行でも残すことは、重大なセキュリティ・審査リスク（STRIDE の E：権限の格上げ）を招くため、コンパイル時に物理的に除外するのが最も安全だからである。
  2. 最適化オプション（`-O`）を Release と完全に一致させた `Perf` 構成を用意し、さらに `os_signpost` は Release にも残し、G2 での静的検査（`URLSession` 等の grep 0 件、`nm` での `UITestHook` 0 件）と G4 での Release 実機確認（G4-15 録画コマ数計測、G4-20 iOS の App プライバシーレポートによる通信 0 件確認）を組み合わせることで、性能も通信ゼロも Release 実機で完全に保証できるからである。

## 招く悪い結果

- **これで楽になること**：
  - `sleep` や実カメラ・実課金ダイアログに一切頼らずに全 149 AC を XCUITest から決定論的に再現・検証でき、Release バイナリへのテストコード混入リスクがゼロになる。
- **これで難しくなること、守り続けること**：
  - フックのすべての型と関数を `UITestHooks/` 配下に閉じ込め、`#if UITEST_HOOKS` の外に漏らさないこと、および 8 つの JSON Schema（`contracts/hooks/*.schema.json`、`contracts/widget-snapshot.schema.json`）と実装のシリアライズ形式を完全一致させることを守り続ける必要がある。
- **元に戻すときの手順と手間**：
  - フックの引数名や JSON Schema を変更する場合は、`contracts/test-hooks.md`、`contracts/hooks/*.schema.json`、`ReadingApp/UITestHooks/`、および `ios/AcceptanceTests/` を同時に更新する必要がある（手間：大、2〜4 日）。

## 見直す条件

1. G2 / G4 のバイナリ検査において、Release ビルドの実行バイナリから `nm` または `strings` で `UITestHook` または `-uitest-` が **1 件でも** 検出された場合（即座にビルド設定を修正する）。
2. G3 の受け入れテスト実行において、`hook.*` 要素の読み出し時間または Darwin 通知の伝播待ちが原因で **100ms 以上** の遅延またはフレーキー失敗が **5 回連続実行中 1 回でも** 発生した場合。

## 確かめたこと

- spike 1（Darwin 通知 `import notify` によるプロセス間状態伝達、2026-10-20、Xcode 27.1 / iOS 27.0 シミュレーター iPhone 17、`contracts/test-hooks.md` 6章）：UI テストが `notify_set_state` + `notify_post` で送った整数値を、前面・バックグラウンド復帰後のアプリが遅延なく読めることを確認済み。
- spike 2（非対話 `UIWindow` 上の 1×1pt 要素 `hook.*` 読み出し、同環境、`contracts/test-hooks.md` 6章）：`isUserInteractionEnabled = false` の窓に置いた `hook.*` 要素が `buttons.count` を変えず、シートやアラート表示中も 91,500 字の JSON を **63ms** で読めることを確認済み。
- 全 8 JSON Schema と 25 examples の自動検証（2026-10-25 実行）：
  ```text
  $ make check-contracts
  ALL PASSED: 8 schemas, 25 examples validated with 0 errors.
  ```

## 確かめ（B）
- [x] 案が2つ以上あり、どの案にも悪い点が書いてある
- [x] 反論、悪い結果、見直す条件が空でない
- [x] 確かめたことに、URL かコマンドの出力がある
