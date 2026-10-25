# 画面遷移 URL スキーム・App Intents・起動経路の契約（Entry URLs & Intents Contract）

このファイルは、ウィジェット（W-1、W-2）、Live Activity（W-3）、コントロール（W-4）、Siri とショートカット（W-5）、および受け入れテストハーネス（H4、H18、H19、H21、H32）からアプリ本体（`ReadingApp`）または拡張（`ReadingWidgetExtension`）を起動・操作する URL スキームと App Intents の唯一の契約正本です。

---

## 1. 登録する URL スキーム（`Info.plist` → `CFBundleURLTypes`）

| URL スキーム | `CFBundleURLName` | 用途 | 有効条件 |
|---|---|---|---|
| `readingapp` | `com.takumamatsuura.readingapp.url` | ウィジェット（W-1、W-2）および Live Activity（W-3）からのディープリンク | 常に有効 |
| `readingapphook` | `com.takumamatsuura.readingapp.testhook` | 受け入れテスト（XCUITest）からのイベント注入・時刻送り・インテント実行・状態ダンプ | **起動引数 `-reading-app-test-hooks` があるときのみ有効**（本番通常起動時は即座に破棄、ADR-0005） |

---

## 2. 本番ディープリンク契約（`readingapp://`）

### 2-1. ウィジェット（W-1、W-2）からの起動（AC-29）

W-1（`.accessoryRectangular`）および W-2（`.systemSmall`）は、ウィジェットルート View に以下の `widgetURL` を設定する。

```text
readingapp://bookmark?source=widget&family=accessoryRectangular
readingapp://bookmark?source=widget&family=systemSmall
```

- **クエリパラメータ**：
  - `source`（必須）：固定値 `"widget"`
  - `family`（任意）：`"accessoryRectangular"` | `"systemSmall"`
- **アプリ本体の受信時動作（`onOpenURL`）**：
  1. **状態が `idle` のとき**：
     - 開いているシートやプッシュ遷移（S-6、S-7、S-8、S-10 等）をすべて閉じ、ルート画面 **S-1（しおりの画面）** を最前面に表示する。
     - `ReadingRepository.pendingEntrySource = .widget(expiresAt: clock.now().addingTimeInterval(30))` を記録する。
     - この状態から 30 秒以内に S-1 の「読み始める」（`bookmark.start`）を押したとき、作られる `ActiveSession.entry`（および保存される `ReadingRecord.entry`）は **`"widget"`** になる（AC-29）。なお、端末を3秒伏せて始めたときはセンサー起動が優先され `entry` は **`"face_down"`** になる（AC-39、AC-50）。
  2. **状態がすでに `reading` のとき**：
     - 新しいセッションは開始せず（2 重開始防止、AC-44）、進行中の **S-2（読書中の画面）** をそのまま表示する。

### 2-2. 夜の入口・読書中の Live Activity（W-3）からの起動（AC-39、AC-136）

W-3（`ActivityConfiguration`）のロック画面バナーおよび Dynamic Island タップ時の `widgetURL` は、Live Activity の状態に応じて以下を設定する。

```text
# 待つ状態（夜の入口の予約時刻になって表示中、まだ reading ではないとき）
readingapp://bookmark?source=live_activity

# 読書中の状態（すでに reading のとき）
readingapp://session?source=live_activity
```

- **アプリ本体の受信時動作（`onOpenURL`）**：
  1. `readingapp://bookmark?source=live_activity` を受け取ったとき（`idle`）：
     - ルート画面 **S-1（しおりの画面）** を最前面に表示する。
     - `ReadingRepository.pendingEntrySource = .liveActivity(expiresAt: clock.now().addingTimeInterval(30))` を記録する。
     - 30 秒以内に「読み始める」（`bookmark.start`）を押して始まった読書の `entry` は **`"live_activity"`** になる（AC-39。伏せて始めた場合は **`"face_down"`**）。
  2. `readingapp://session?source=live_activity` を受け取ったとき（または `reading` 中に `bookmark?source=live_activity` を受け取ったとき）：
     - 進行中の **S-2（読書中の画面）** を最前面に表示する。

---

## 3. App Intents・Control・App Shortcuts の契約（W-3、W-4、W-5）

すべてのインテントは `ReadingStore` の `ReadingRepository` を通じて App Group の `state.json` と `widget-snapshot.json` を読み書きする（ADR-0002）。

### 3-1. `StartReadingIntent: LiveActivityIntent`（「読み始める」、AC-114〜120、AC-125〜126、AC-131）

W-4（ロック画面・コントロールセンター・アクションボタンの `ControlWidgetButton`）および W-5（Siri・ショートカットの「読み始める」）が呼び出すインテント。

- **型とポリシー**：
  - `LiveActivityIntent` に準拠する。
  - 通常時はアプリを前面に開かず（`openAppWhenRun = false`）、その場でセッションを開始して読書中 Live Activity（W-3）を立ち上げる。
- **分岐規則**：
  1. **今の本があり、`idle` で、Live Activity が許可（`areActivitiesEnabled == true`）されているとき（AC-114、AC-120）**：
     - `ActiveSession(bookId: currentBook.id, startedAt: now, entry: .intentStart)` を `state.json` に保存する。
     - 今夜の予約 Live Activity があれば終了し、読書中の Live Activity（`source = "intent"`）を開始する（`settings.hideOnWidgets == true` のときは書名を出さず `widget.hidden`「しおり」と開始時刻と `liveActivity.end` のみ、AC-120）。
     - 声のダイアログとして `intent.start.started`（「読書を始めました。」／「Started reading.」）を返す。
  2. **すでに `reading` のとき（AC-115）**：
     - 既存の `startedAt` を変えず、2 重に開始しない。声のダイアログとして `intent.start.alreadyReading`（「すでに読書中です。」／「A reading session is already running.」）を返す。
  3. **今の本がないとき（`currentBook == nil`、AC-117）**：
     - セッションを開始せず、アプリを前面に開いて（`opensIntent` / `openAppWhenRun` または Foreground 遷移要求）**S-1 の空状態**（`bookmark.empty.message` または `bookmark.noCurrent.message`）を表示する。
  4. **Live Activity がオフ（`areActivitiesEnabled == false`）または Live Activity の開始要求だけが失敗したとき（AC-118、AC-131）**：
     - `ActiveSession(entry: .intentStart)` はその場で保存して `reading` に遷移し、エラーは返さずアプリを前面に開いて **S-2（読書中の画面）** を表示する。
  5. **保存先の書き込みに失敗したとき（H7 `session.start`、AC-119）**：
     - `idle` のままにし、声のダイアログとして `session.start.error` を返す。

### 3-2. `EndReadingIntent: LiveActivityIntent`（Live Activity の「終える」、AC-40、AC-116、AC-125、AC-132、AC-144）

W-3（読書中の Live Activity）の「終える」ボタン（`liveActivity.end`）が呼び出すインテント。

- **分岐規則**：
  1. **正常時（AC-40、AC-116、AC-144）**：
     - アプリを開かずにその場で `ActiveSession` を終了し、`minutes = max(1, Int(endedAt.timeIntervalSince(startedAt) / 60))`（上限 1440）の `ReadingRecord` を 1 件保存して `idle` に戻す（電子書籍アプリを開いて読んだあとも同様に動作する、AC-144）。
     - 読書中の Live Activity を即座に終了（`.immediate`）し、翌夜の入口の予約 Live Activity を入れ直す（1 分未満で終わった場合で今夜の予約時刻がまだ未来なら今夜の予約を戻す、AC-130）。
  2. **保存に失敗したとき（H7 `session.end`、AC-132）**：
     - `ActiveSession` と読書中の Live Activity を消さず、アプリを前面に開いて **S-2** に `session.save.error` の知らせの帯（部品 N）を出し、`reading.end` でやり直せるようにする。

### 3-3. `WhereStoppedIntent: ShowsSnippetIntent`（「どこまで読んだ？」、AC-121〜123、AC-125、AC-133、AC-143）

W-5（Siri・ショートカットの「どこまで読んだ？」）が呼び出すインテント。

- **型とポリシー**：
  - `ShowsSnippetIntent` に準拠する。
  - `static let openAppWhenRun: Bool = false`
  - `static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed`（ロック中でもパスコード／Face ID 認証を求めずに応答する、AC-121）。
- **返却する声（`IntentDialog`）と小窓（Snippet View）の規則**：
  - 小窓は声とまったく同じ 1 行の `Text` のみを返し、**しおりの一行（`lastLine`）と書名（`title`）は `hideOnWidgets` のオン・オフにかかわらず一切含めない**（AC-121、AC-123、AC-143）。
  - 今の本があり進み具合の値があるとき：
    - `progressUnit == .page`：`intent.whereStopped.page`（「61ページからです。」／「From page 61.」、AC-121）
    - `progressUnit == .location`：`intent.whereStopped.location`（「位置1450からです。」／「From location 1450.」、AC-143）
    - `progressUnit == .percent`：`intent.whereStopped.percent`（「52パーセントからです。」／「From 52 percent.」、AC-143）
  - 今の本に進み具合の値がないとき：`intent.whereStopped.noPage`（AC-122）
  - 今の本がないとき：`intent.whereStopped.noCurrent`（AC-122）
  - 保存先の読み込みに失敗したとき（H7 `store.load`）：`intent.whereStopped.error`（AC-133）

### 3-4. `ContinueReadingIntent: AppIntent`（「続きを読む」、AC-124、AC-134、AC-135）

W-5（Siri・ショートカットの「続きを読む」）が呼び出すインテント。

- **型とポリシー**：
  - `static let supportedModes: IntentModes = [.foreground(.immediate)]`（`openAppWhenRun = true`）。
- **分岐規則**：
  1. **`idle` で今の本があるとき（AC-124）**：
     - アプリを前面に出して **S-1** を開き、`ReadingRepository.pendingEntrySource = .intentOpen(expiresAt: clock.now().addingTimeInterval(30))` を記録する。そのあと S-1 の「読み始める」で始まった読書の `entry` は **`"intent_open"`** になる（AC-124）。
  2. **すでに `reading` のとき（AC-134）**：
     - アプリを前面に出して **S-2** をそのまま見せる。
  3. **今の本がないとき（AC-135）**：
     - アプリを前面に出して **S-1 の空状態**（`bookmark.noCurrent.message` または `bookmark.empty.message`）を見せる。

---

## 4. 記録の入口区分（`ReadingRecord.entry`）の決定規則まとめ

| 値 | 記録される条件 | 対応 AC |
|---|---|---|
| `"app"` | アプリを通常起動（または 30 秒の引き継ぎ窓が切れた状態）で S-1 の「読み始める」（`bookmark.start`）を押したとき、または S-8 の「あとで」（`register.later`）で即座に始まったとき | AC-39、AC-50、AC-139 |
| `"face_down"` | S-1 が前面にある状態で iPhone を伏せて 3 秒経過して始まったとき（直前にウィジェットや Live Activity から開いていても `"face_down"` が優先される） | AC-39、AC-50 |
| `"widget"` | W-1 または W-2 をタップして S-1 が開いてから 30 秒以内に `bookmark.start` を押したとき | AC-29 |
| `"live_activity"` | W-3（待つ状態の夜の入口 Live Activity）をタップして S-1 が開いてから 30 秒以内に `bookmark.start` を押したとき | AC-39 |
| `"intent_start"` | W-4（コントロール）または W-5（Siri／ショートカット）の `StartReadingIntent`（「読み始める」）で直接始まったとき | AC-114 |
| `"intent_open"` | W-5（Siri／ショートカット）の `ContinueReadingIntent`（「続きを読む」）で S-1 が開いてから 30 秒以内に `bookmark.start` を押したとき | AC-124 |

---

## 5. テストフック用 URL スキーム契約（`readingapphook://`）

起動引数 `-reading-app-test-hooks` が有効なときのみ、XCUITest から `XCUIApplication.open(_:)` で以下の URL を呼び出せる。

| URL 形式 | 動作 | 対応フック・AC |
|---|---|---|
| `readingapphook://open-bookmark?source=widget&family=accessoryRectangular` | W-1 タップと同等のディープリンク遷移を発火する | H22、AC-29 |
| `readingapphook://open-bookmark?source=live_activity` | W-3（待つ状態）タップと同等のディープリンク遷移を発火する | H23、AC-39 |
| `readingapphook://face-down?active=true&durationMs=3100` | 近接＋下向き重力センサーの伏せ状態を模擬注入する（`durationMs < 3000` なら開始せず、`>= 3000` なら開始する） | H18、AC-39、AC-50、AC-52 |
| `readingapphook://scan-barcode?codes=9784167911300,1920193007804` | S-8a のカメラスキャナに 1 個またはカンマ区切りの複数バーコード（ISBN-13・2段目 `192` コード・不正コード）を注入する | H21、AC-3〜11、AC-140、AC-149 |
| `readingapphook://advance-time?seconds=1080` | H4 の仮想時計を指定秒数だけ進め、Live Activity の予約時刻到来・4:00 境界・経過分数を更新する | H4、AC-36〜49、AC-130、AC-136 |
| `readingapphook://run-intent?name=StartReadingIntent` | 指定した App Intent（`StartReadingIntent` / `EndReadingIntent` / `WhereStoppedIntent` / `ContinueReadingIntent`）をインプロセス実行し、結果を `out/h32-intents.json` に書き出す | H32、AC-114〜126、AC-131〜135、AC-143 |
| `readingapphook://dump-state` | H13、H14、H17、H22、H23、H24、H26、H27、H28、H29、H30、H31、H32 の全スナップショット JSON を即座に `out/` へ書き出す | 全フック |
