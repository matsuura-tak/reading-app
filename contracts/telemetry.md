# 計測のイベント（001-reading-session）

- 書いた役：tech-lead　日付：2026-10-21
- 決めた ADR：docs/adr/0003-telemetry-without-sdk-in-001.md（001 は第三者の SDK を入れない。本番は端末の中で数えるだけ。テストは Debug の localhost の HTTP）
- 機械で確かめる形：contracts/telemetry-events.schema.json（POST /events の本文1件）、contracts/telemetry-flushed.schema.json（POST /flushed の本文）、例は contracts/examples/telemetry-*.json と contracts/examples/flushed.json
- 元：PRD 15 の表と、その下の Save Failed と Load Failed の段落。PRD 13 の I-1 の数え方

## イベントとプロパティ
名前とプロパティ名は PRD 15 のまま。値は下の区間の文字か true / false だけ。数の生の値、題名、ページを入れない（AC-23）。threshold_min も文字の "60" で送る（すべての値を区間の文字か真偽にそろえるため）。
| イベント | プロパティ（型と値） | 出すとき（1回の操作で1件） |
|---|---|---|
| App First Opened | なし | 起動したとき、計測の印 telemetry.firstOpenedAt がなければ出して、今の時刻を入れる。保存先の読み込みより前（読み込みに失敗しても出す） |
| Book Added | has_total_pages（Bool）、book_count_bucket（"1"、"2-5"、"6-20"、"21+"） | 本の追加の保存が通ったとき。冊数は追加した後の数 |
| Reading Session Started | is_first_session（Bool）、start_source（"home"、"book_detail"、"after_add"） | 読み始めの保存が通ったとき（再試行で通ったときを含む）。失敗した回は出さない（PRD 15）。is_first_session は telemetry.firstSessionStarted が false なら true にして、印を true にする。start_source は design 1 の決まり（S1 の主操作、S3、S2 で追加した直後の S3） |
| Reading Session Finished | duration_bucket（"1-4"、"5-14"、"15-29"、"30-59"、"60-119"、"120+"）、page_entered（Bool）、pages_bucket（"0"、"1-9"、"10-29"、"30-99"、"100+"。page_entered が true のときだけ。false なら項目ごと送らない）、minutes_edited（Bool）、was_paused（Bool）、is_first_5min（Bool）、since_first_open（"0-24h"、"1-7d"、"8d+"） | 記録の保存が通ったとき |
| Reading Session Restored | reason（"relaunch"）、state（"reading"、"paused"、"finishing"） | 起動して（再試行を含む）読み込みが通り、進行中の読書があったとき。起動ごとに1件 |
| Reading Session Discarded | reason（"too_short"） | 経過60秒未満で「終える」を押し、進行中の読書を消す保存が通ったとき（AC-13、AC-51） |
| Reading Week Reached | threshold_min（"60"） | 記録の保存が通った後、その記録の startedAt の週の合計が3,600秒以上になり、telemetry.weekReachedWeekStart がその週の始まりより前（かない）とき。出したら印をその週の始まりにする（AC-24。同じ週に2回出さない） |
| Save Failed | operation（"book_add"、"session_start"、"session_pause"、"session_resume"、"session_finish"、"session_delete"） | その保存が失敗するたびに1件（再試行の失敗も1件ずつ） |
| Load Failed | なし | 保存先の読み込みが失敗するたびに1件（起動のときと、error.loadFailed.retry でまた失敗したとき。AC-54） |

区間の決め方（境目は下の値を含み、上の値を含まない形で書く）：
- book_count_bucket：追加した後の冊数 n。n = 1 → "1"、2〜5 → "2-5"、6〜20 → "6-20"、21 以上 → "21+"。
- duration_bucket：分 m = 保存した durationSeconds ÷ 60 の切り捨て（1以上）。1〜4 → "1-4"、5〜14 → "5-14"、15〜29 → "15-29"、30〜59 → "30-59"、60〜119 → "60-119"、120 以上 → "120+"。
- pages_bucket：保存した pagesRead p（読み返しは0）。0 → "0"、1〜9 → "1-9"、10〜29 → "10-29"、30〜99 → "30-99"、100 以上 → "100+"。
- since_first_open：記録の savedAt − telemetry.firstOpenedAt の秒 s。s < 86,400 → "0-24h"（負のときも）、86,400 ≤ s < 691,200（8日）→ "1-7d"、それ以上 → "8d+"。
- is_first_5min：durationSeconds が300以上で、telemetry.first5minDone が false なら true にして、印を true にする。それ以外は false。
- minutes_edited：保存したときの分の欄の値が、初めの値（contracts/data-model.md の計算する値）と違えば true。
- was_paused：ActiveReading.wasPaused。page_entered：今のページを入れたか。

I-1（PRD 13）は「is_first_5min が true で since_first_open が "0-24h" の Reading Session Finished の数 ÷ App First Opened の数」。どちらも利用者の ID なしで数えられる。

## Swift の型の名前（案。Swift のファイルは contracts/ に置かない。ios-engineer が ios/ に作る）
```swift
enum TelemetryEvent: Sendable, Equatable {
    case appFirstOpened
    case bookAdded(hasTotalPages: Bool, bookCount: BookCountBucket)
    case readingSessionStarted(isFirstSession: Bool, startSource: StartSource)
    case readingSessionFinished(SessionFinishedProperties)
    case readingSessionRestored(state: RestoredState)   // reason は "relaunch" だけ
    case readingSessionDiscarded                         // reason は "too_short" だけ
    case readingWeekReached                              // threshold_min は "60" だけ
    case saveFailed(operation: SaveOperation)
    case loadFailed
}
struct SessionFinishedProperties: Sendable, Equatable {
    var duration: DurationBucket
    var pages: PagesBucket?            // nil なら page_entered = false、pages_bucket を送らない
    var minutesEdited: Bool
    var wasPaused: Bool
    var isFirst5min: Bool
    var sinceFirstOpen: SinceFirstOpenBucket
}
enum BookCountBucket: String, Sendable { case one = "1", twoToFive = "2-5", sixToTwenty = "6-20", twentyOneOrMore = "21+" }      // init(count: Int)
enum DurationBucket: String, Sendable { case m1to4 = "1-4", m5to14 = "5-14", m15to29 = "15-29", m30to59 = "30-59", m60to119 = "60-119", m120OrMore = "120+" } // init(seconds: Int)
enum PagesBucket: String, Sendable { case zero = "0", p1to9 = "1-9", p10to29 = "10-29", p30to99 = "30-99", p100OrMore = "100+" } // init(pagesRead: Int)
enum SinceFirstOpenBucket: String, Sendable { case within24h = "0-24h", days1to7 = "1-7d", days8OrMore = "8d+" } // init(seconds: TimeInterval)
enum StartSource: String, Sendable { case home, bookDetail = "book_detail", afterAdd = "after_add" }
enum RestoredState: String, Sendable { case reading, paused, finishing }
enum SaveOperation: String, Sendable { case bookAdd = "book_add", sessionStart = "session_start", sessionPause = "session_pause", sessionResume = "session_resume", sessionFinish = "session_finish", sessionDelete = "session_delete" }

protocol TelemetrySink: Sendable {
    func send(_ event: TelemetryEvent) async
}
```
決まり：
- イベント名とプロパティ名の文字は、TelemetryEvent の中の1か所（例：`var name: String` と `var properties: [String: TelemetryValue]`）でだけ作る。TelemetryValue は文字と真偽の2つだけで、区間の rawValue と Bool からだけ作る。
- TelemetryEvent の関連値に String と Int を持たせない（題名とページを型の上で渡せなくする）。区間への分け方は各 enum の init の1か所でだけ書き、単体テストで境目（4と5、14と15、9と10、86,399秒と86,400秒など）を確かめる。
- 実装は2つ：本番の LocalCountingTelemetrySink（UserDefaults の telemetry.localCounts のイベント名の回数を1足すだけ。ネットワークに出ない）と、Debug の HTTPTelemetrySink（下。ios/Yomutoki/Debug/ の中で、ファイル全体を #if DEBUG）。だから protocol にする。
- 送ることで画面を止めない。送り先の失敗は画面に何も出さない（AC-20）。

## テストの受け口（Debug ビルドで -UITest のときだけ。contracts/test-hooks.md の T6、T7、T13、T19）
- 送り先：UITEST_TELEMETRY_URL（例 `http://localhost:8765`）。localhost を使う（127.0.0.1 は iOS 17 から ATS の既定で拒まれる。A48）。
- `POST <UITEST_TELEMETRY_URL>/events`、`Content-Type: application/json; charset=utf-8`、本文はイベント1件（telemetry-events.schema.json）。1件ずつ、出た順に、前の送信が終わってから送る（受け口に届く順＝出た順）。
- 例：`{"name":"Reading Session Finished","properties":{"duration_bucket":"5-14","page_entered":true,"pages_bucket":"30-99","minutes_edited":false,"was_paused":false,"is_first_5min":true,"since_first_open":"0-24h"}}`
- 成功は 2xx。2xx 以外、接続の失敗、UITEST_TELEMETRY_TIMEOUT 秒（既定30）の待ち切れは失敗。失敗したイベントは送り直さず、貯めずに捨てる（PRD 12 のオフラインの行を 001 では「捨てる」に決めた。ADR 0003）。
- 送り終わりの知らせ（T13）：送る待ち行列が空になるたびに、`POST <UITEST_TELEMETRY_CONTROL_URL>/flushed`、本文 `{"sent": n, "failed": m}`（telemetry-flushed.schema.json）。n と m は起動してからの累計。UITEST_TELEMETRY_CONTROL_URL がなければ UITEST_TELEMETRY_URL に送る。/flushed そのものは数えず、送り直さない。テストは「sent + failed が期待の件数に届いた /flushed」を待ってから、0件やちょうど1件を確かめる。
- AC-20 の形：UITEST_TELEMETRY_URL を失敗する先（届かないポート、500 を返す受け口、応答しない受け口）にし、UITEST_TELEMETRY_CONTROL_URL を正常な受け口にすると、送り終わり（failed が増えたこと）を待てる。
- 受け口が返す本文は読まない。204 か 200 を返せばよい。
- UITEST_TELEMETRY_URL がないときは、-UITest でも本番と同じ LocalCountingTelemetrySink を使う（ネットワークに出ない）。

## SDK を入れるとき（003 の G1。この節は今は使わない）
- TelemetrySink の実装を1つ足し、組み立ての場所で差し替える。イベントの型と区間は変えない。
- SDK が足す項目（端末ごとの ID、OS の版、機種、時刻）を、SDK の文書とソースで確かめ、PRD 15 の最後の行とプライバシー表記を直す。AC-23 は SDK の送る本文そのものを受け口に向けて確かめ直す（向けられなければ G1 で報告する）。
