PASS

## 指摘
- 重大：なし
- 要修正：なし
- 提案：
  1. `design/001-reading-session/screens.md:358,376,406,482`：ASCII ワイヤーフレームの注記に旧案のオンライン NDL サーチ補完・openBD 言及が残っています。正本の `design/001-reading-session.md` および `docs/prd/001-reading-session.md` では外部 HTTP 通信 0 件・Apple-Hosted Background Assets による端末内書誌 SQLite DB 完結に統一されており、正本優先が明記されているため実装上の阻害はありませんが、機会があれば注記を正本に合わせておくと誤読を防げます。
  2. `design/001-reading-session/screens.md:199,211,254`：`S-3a`・`S-3b` の ASCII 図内のセグメント表示が `[ ページ (p.) | パーセント (%) ]` の2択表記になっています。正本の `design/001-reading-session.md:195-197`（`mark.unit.picker`）および AC-141 のとおり `[ ページ (p.) | 位置 | % ]`（`page` / `location` / `percent`）の3択にそろえるとより明確です。
  3. `design/001-reading-session/screens.md:40,46,51,76`：`W-3` の ASCII 図で `waiting` にボタンが描かれ `reading` に `liveActivity.end`（「終える」）が描かれていない点、および `W-5` の小窓に書名・一行が描かれている点が旧案のままです。正本の `design/001-reading-session.md` および AC-41・AC-114・AC-121・AC-123 とおり、`W-3` は `reading` のみ `liveActivity.end` 1要素、`W-5` は進み具合の1行のみ（書名・一行は出さない）が正です。
  4. `design/001-reading-session/screens.md:122,176,180,354,355,412,496-499`：ASCII 図脇の識別子メモの一部に旧名が残っています。正本の `design/001-reading-session.md:569-725`（6章の識別子一覧）が AC-1〜AC-149 と完全一致しているため、実装・テストは正本の6章に従います。

## 証拠

### 1. 今の技術スタックでの実現可能性と各画面の必要データ・操作

結論：**全画面（`W-1`〜`W-5`、`S-1`〜`S-10a`、部品 `N`）および全 149 AC（AC-1〜AC-149）は、現在の技術スタック（iOS 26.0 以上、Swift 6、SwiftUI、SwiftData、WidgetKit、ActivityKit、AppIntents、Vision、VisionKit、PhotosUI、StoreKit 2、BackgroundAssets、SQLite3 C API / FTS5、サードパーティ依存 0 件）で 100% 構築可能**です。

| 画面 / 部品 | 主な役割・対応 AC | 必要なデータ（保存・参照先） | 必要な操作・フレームワーク | 成立性 |
|---|---|---|---|---|
| `W-1` ロック画面ウィジェット (`accessoryRectangular`) | 縦書きの一行（最大25字）＋左帯の進み具合（`p.61` / `位置 1280` / `42%`）。AC-27〜AC-34、AC-99、AC-102、AC-140、AC-141 | App Group の `widget-snapshot.json` | `WidgetKit`、`ReadingCore` の縦組み関数＋SwiftUI `Text` 配置、`widgetURL(yomuma://open?entry=lock_widget)` | OK |
| `W-2` ホーム / StandBy 小ウィジェット (`systemSmall`) | 縦書きの一行＋下段1行の進み具合、4種の見た目テーマ。AC-35、AC-102、AC-106 | 同上（`widget-snapshot.json`） | `WidgetKit`、`containerBackground(for: .widget)`、`widgetURL(yomuma://open?entry=small_widget)` | OK |
| `W-3` 今夜の読書の Live Activity | `waiting` / `reading` / `result`。AC-36〜AC-41、AC-98、AC-114〜AC-120、AC-144 | `ActivityAttributes` + `ContentState` | `ActivityKit`（`Activity.request(...start:)` で予約、`pushType: nil`）、`LiveActivityIntent` | OK |
| `W-4` 「読み始める」Control (`ControlWidgetButton`) | コントロールセンター・ロック画面・Action ボタンから1タップで読書開始。AC-114〜AC-120、AC-126 | SwiftData（`completeUntilFirstUserAuthentication`） | `WidgetKit` (`ControlWidget`)、`AppIntents` (`StartReadingIntent: LiveActivityIntent`) | OK |
| `W-5` 「どこまで読んだ？」Snippet (`ShowsSnippetIntent`) | Siri・ショートカットで進み具合1行だけを返し、一行と書名を伏せる。AC-121〜AC-123、AC-143 | SwiftData の `current` の本 | `AppIntents` (`WhereStoppedIntent`、`supportedModes`、`.alwaysAllowed`、結果ダイアログ＋`SnippetView`) | OK |
| `S-1` しおりの画面（ホーム） | 今の本の一行（縦書き全文）・進み具合・伏せ検知・おすすめ（`current` 不在時）。AC-1、AC-30、AC-42〜AC-51、AC-64、AC-96、AC-140、AC-144、AC-145 | SwiftData、端末内書誌・共起 SQLite DB、同梱受賞リスト | `SwiftUI`、`UIDevice.orientationDidChangeNotification`、`UIImpactFeedbackGenerator`、`UIAccessibility.post` | OK |
| `S-2` 読書中の画面 | 書名（または「いま読んでいる本」）と `reading.end`（「終える」）のみ。AC-42〜AC-45、AC-52〜AC-59 | SwiftData の `ReadingSession` | 壁時計 `Date` の差分計算 | OK |
| `S-3a`〜`S-3d` しおりを挟む画面（4つの道） | 手入力・ページ/位置/%のみ・本文撮影・スクショ選択、非同期 OCR 待ち中のフォールバック、60字制限。AC-55、AC-63〜AC-74、AC-94、AC-95、AC-141、AC-142 | SwiftData の `Book`、撮影・選択した `CGImage`（メモリ上のみ） | `Vision` (`VNRecognizeTextRequest`)、`PhotosUI` (`PhotosPicker` + `.screenshots`)、`AVFoundation` | OK |
| `S-4` 読書のあとの画面 | 今夜の分数・進み具合・累計晩数と時間。AC-20〜AC-26、AC-56〜AC-58 | SwiftData の `ReadingRecord`、`Book` | `SwiftUI`、タイムゾーン固定の晩数集計（`ReadingCore`） | OK |
| `S-5` ウィジェットの置き方の案内 | 初回しおり保存後の1回だけ出す案内シート。AC-96 | SwiftData の `Settings.widgetGuideShown` | `SwiftUI` `.sheet`、`ReadingCore` の `W-1` プレビュー View（172×76pt） | OK |
| `S-6` 本棚の画面 | 読んでいる（最大1冊）・積読・読了の3区分、本500冊・記録5,000件で1.0秒以内。AC-13〜AC-16、AC-101、AC-140 | SwiftData の `Book` 一覧 | `SwiftUI` `List`、`os_signpost`（`shelfOpen`） | OK |
| `S-7` / `S-7a`〜`S-7c` 本の画面・編集・奥付撮影 | 晩数・時間・記録の編集削除・書誌編集・奥付 OCR 補完・受賞表示・読了本の「この本のあとに」（最大5冊）。AC-15〜AC-26、AC-77、AC-112、AC-113、AC-140、AC-146〜AC-148 | SwiftData、端末内書誌・共起 SQLite DB、同梱受賞データ | `SwiftUI`、`Vision`（奥付の出版年・出版社・レーベル・ISBN 抽出）、`PhotosPicker` | OK |
| `S-8` / `S-8a`〜`S-8d` 本を加える画面（5つの道） | バーコード連続読取（2段目 `192` Cコード対応）・表紙撮影・本棚複数冊撮影・書名/著者検索・手入力・「あとで」。AC-2〜AC-12、AC-92、AC-137〜AC-140、AC-149 | 端末内書誌 SQLite DB（FTS5 trigram + ISBN 主キー索引、Background Assets で配信）、SwiftData の `Book` | `VisionKit` (`DataScannerViewController`)、`Vision`、`PhotosPicker`、`SQLite3` | OK |
| `S-9` 読み終えた夜の画面 | ふりかえり1行・奥付・受賞・次の1冊（最大3冊）・共有カード。AC-75〜AC-87、AC-112、AC-113、AC-127、AC-147、AC-148 | SwiftData、端末内書誌・共起 SQLite DB、同梱受賞データ | `SwiftUI`、`ImageRenderer`（1080×1350px PNG、一行は載せない AC-84）、`ShareLink` / `UIActivityViewController` | OK |
| `S-10` / `S-10a` 設定の画面・見た目とよむま＋ | 伏せ開始・ウィジェット非表示・入口時刻・見た目4種と購入/復元・NDL 3条件クレジット・プライバシーポリシー。AC-34、AC-36、AC-51、AC-88、AC-93、AC-104〜AC-111 | SwiftData の `Settings` | `StoreKit 2`、同梱 OFL フォント（Shippori Mincho B1、Klee One） | OK |
| `部品 N` 知らせ（Notice） | 画面上部の非モーダルな1行バナー（alert 0個）。AC-6、AC-9、AC-56〜AC-60、AC-91、AC-95、AC-97、AC-107〜AC-110 | メモリ上の表示キュー（`hook.state` の `notice` に記録） | `SwiftUI` オーバーレイ、`accessibilityElementsHidden` 制御 | OK |

### 2. Step 7 で更新・追加・削除する項目
1. 削除：`contracts/ndl-opensearch.yaml`（および `contracts/.spectral.yaml`）— 外部 HTTP 通信0件（AC-103）に伴い廃止。
2. 更新：`docs/adr/0001`〜`0005`（とくに `0004` を Background Assets 配信の端末内 SQLite 書誌・共起 DB に全面改訂）、`docs/adr/features/001-reading-session.md`（全149 AC 対応）、`contracts/entry-urls.md`、`contracts/widget-snapshot.schema.json`、`contracts/test-hooks.md`、`contracts/hooks/*.schema.json`、`CLAUDE.md`、`Makefile`。

### 3. 確認の記録
- 読んだファイル：`design/001-reading-session-research.md`、`design/001-reading-session.md`、`design/001-reading-session/screens.md`、`design/001-reading-session/tokens.md`、`docs/prd/001-reading-session.md`、`docs/adr/*`、`contracts/*`
- 動かしたコマンド：`ls -la docs/adr/ contracts/ contracts/hooks/`（exit 0）、`ls -la docs/adr/features/`（exit 0）
- 未検証：なし
