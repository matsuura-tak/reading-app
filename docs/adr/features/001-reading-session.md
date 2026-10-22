# A 技術設計メモ 001-reading-session：読んだ時間とページを残して、続きから読む

- 書いた役：tech-lead　日付：2026-10-21
- PRD：docs/prd/001-reading-session.md（AC-1〜AC-67。10、12、15。18 の 6 は指揮役が A に決めた）　デザイン：design/001-reading-session.md（1、3、6、10、D-57〜D-60）、design/tokens.md
- 契約：HTTP の契約（contracts/openapi.yaml）はない。端末の中の契約は contracts/data-model.md、contracts/test-hooks.md、contracts/telemetry.md と JSON Schema（contracts/README.md の一覧）
- ADR：0001（SwiftData、端末だけ）、0002（iOS 17.0、Xcode 26、Swift 6）、0003（計測の SDK なし）、0004（XcodeGen）、0005（テストのつなぎ口は Debug だけ）
- API の証拠の番号 A1〜A112 は docs/reviews/001-reading-session-G1-tech-lead-r1.md、-r2.md、docs/adr/ の「確かめたこと」の番号

## 1. 範囲、目標、非目標
- 範囲：iPhone のアプリ1つ（ターゲット3つ：アプリ、単体テスト、受け入れテスト）。画面 S1〜S7、保存（SwiftData の Book、ReadingSession、ActiveReading）、計測のイベントの型と端末の中で数える送り先、Debug だけのテストのつなぎ口 T1〜T22。
- 目標：PRD の AC-1〜AC-67 を、サーバーも外部ライブラリもなしで満たす。保存の失敗と強制終了で読書を失わない（1操作1回の save、失敗で rollback、時刻から経過を計算）。受け入れテストが時計と保存の失敗と送り先を差し替えて、sleep なしで決まった結果を確かめられる。
- 非目標：サーバー、アカウント、iCloud の同期、計測の第三者の SDK（003 で決め直す）、通知、ウィジェット、Live Activity、バックグラウンドの処理、iPad、ローカルの Swift パッケージ、MetricKit の購読（8）。

## 2. 受け入れ条件の対応表
operationId はすべて「なし（端末のみ）」（HTTP の API がない）。画面の ID は design/ の 1、データは contracts/data-model.md。「UI」は ios/AcceptanceTests/ の XCUITest（名前は verifier が G2 のテスト計画で決め、AC 番号を名前に入れる）。T の番号は contracts/test-hooks.md。全行で T1 か T2 を使ってデータを決めてから起動する。T8〜T10、T18（識別子と文言のキー）はほぼ全行で使うので書かない（contracts/test-hooks.md の各行が正）。この表の T と test-hooks.md の「使う AC」は同じにする（照合の出力は 4）。T6 は、localhost に届かなければ T22 に替える（裁定の追記2 の (9)）。
| AC | 画面（design/） | operationId | データ（エンティティ） | 確かめるテスト |
|---|---|---|---|---|
| AC-1 | S1（本0冊） | なし（端末のみ） | Book 0件 | UI（T1）とスクリーンショット |
| AC-2 | S2 → S3、S1 | なし（端末のみ） | Book（title、totalPages nil、lastPage 0） | UI（T1） |
| AC-3 | S2 | なし（端末のみ） | Book.title の整え方（data-model） | UI（T1） |
| AC-4 | S1 → S2 → S3 → S4 | なし（端末のみ） | Book、ActiveReading | UI（T1。タップを数える） |
| AC-5 | S1 → S4 | なし（端末のみ） | ActiveReading.startedAt、前の本 | UI（T2、T3、T16、T20） |
| AC-6 | S4 → S5 → S3 | なし（端末のみ） | ActiveReading（pausedAt、pausedTotalSeconds）、ReadingSession.durationSeconds | UI（T2、T3、T16） |
| AC-7 | S4 | なし（端末のみ） | ActiveReading（経過は計算） | UI（T2、T3、T16） |
| AC-8 | 起動 → S4 | なし（端末のみ） | ActiveReading（reading） | UI（T2、T3。終了して起動し直す） |
| AC-9 | S4 → S5 → S3 | なし（端末のみ） | ReadingSession（endPage、pagesRead）、Book.lastPage | UI（T2） |
| AC-10 | S5 → S3 | なし（端末のみ） | ReadingSession（endPage nil） | UI（T2） |
| AC-11 | S5 | なし（端末のみ） | ActiveReading（finishing）、Book.totalPages | UI（T2、T17） |
| AC-12 | S5 → S3 | なし（端末のみ） | ReadingSession.durationSeconds（分×60） | UI（T2、T3、T17） |
| AC-13 | S4 → S3 | なし（端末のみ） | ActiveReading を消す（session_discard） | UI（T2、T3） |
| AC-14 | S3 | なし（端末のみ） | Book、ReadingSession（計算する値） | UI（T2） |
| AC-15 | S1 | なし（端末のみ） | ReadingSession.startedAt（今週） | UI（T2、T3、T4、T15） |
| AC-16 | S3 → S6 → S3 | なし（端末のみ） | ReadingSession を消す。Book.lastPage は変えない | UI（T2） |
| AC-17 | S4 → S1 → S3 | なし（端末のみ） | ActiveReading（0件か1件） | UI（T2、T17） |
| AC-18 | 起動 → S1、S3 | なし（端末のみ） | Book、ReadingSession（ストアのファイル） | UI の2段（T2、T11。ac18-reboot.sh） |
| AC-19 | S5 | なし（端末のみ） | ActiveReading.finishedAt、終える入力の下書き | UI（T2、T3、T5 session_finish:*、T17） |
| AC-20 | S2 → S3 → S4 → S5 → S3 | なし（端末のみ） | 全部（計測の送り先だけ失敗） | UI（T1、T6 か T22、T7、T13、T16、T19） |
| AC-21 | 全画面 | なし（端末のみ） | なし | UI（T1、T12、T16） |
| AC-22 | S2 → S3、S1 | なし（端末のみ） | Book 21冊 | UI（T2） |
| AC-23 | S2、S4、S5 | なし（端末のみ） | TelemetryEvent（区間と真偽だけ） | UI（T2、T6 か T22、T13、T16） |
| AC-24 | S4、S5 | なし（端末のみ） | 計測の印 telemetry.weekReachedWeekStart | UI（T2、T3、T4、T6 か T22、T13、T16） |
| AC-25 | S1 → S4 | なし（端末のみ） | ReadingSession.savedAt（前の本） | UI（T2、T3、T17） |
| AC-26 | S1 → S4 | なし（端末のみ） | Book.addedAt（前の本） | UI（T2、T17） |
| AC-27 | S1 | なし（端末のみ） | ActiveReading | UI（T2） |
| AC-28 | S3 | なし（端末のみ） | Book.totalPages nil | UI（T2） |
| AC-29 | S5 → S3 | なし（端末のみ） | ReadingSession.pagesRead 0、Book.lastPage | UI（T2） |
| AC-30 | S5 | なし（端末のみ） | 分の範囲（finishedAt から計算） | UI（T2、T17） |
| AC-31 | S2 | なし（端末のみ） | Book.totalPages | UI（T1） |
| AC-32 | S5 → S3 | なし（端末のみ） | ReadingSession.endPage（9,999 まで） | UI（T2、T17） |
| AC-33 | 起動 → S4 | なし（端末のみ） | ActiveReading（paused、pausedAt） | UI（T2、T3、T16、T17） |
| AC-34 | 起動 → S4 ＋ S5 | なし（端末のみ） | ActiveReading（finishing、finishedAt）、下書きを新しく作る | UI（T2、T3、T17） |
| AC-35 | S5 → S3 | なし（端末のみ） | ReadingSession 1件 | UI（T2、T3、T5 session_finish:1、T17） |
| AC-36 | S1 | なし（端末のみ） | 今週の合計（計算） | UI（T2、T3、T4、T15） |
| AC-37 | S3 | なし（端末のみ） | Book（記録0件） | UI（T2） |
| AC-38 | S3 → S6 → S3 | なし（端末のみ） | ReadingSession（変えない） | UI（T2） |
| AC-39 | 全画面（7 の文言） | なし（端末のみ） | String Catalog | 文言の表の検査（T14。Linux） |
| AC-40 | S4 | なし（端末のみ） | 経過の秒（計算） | UI（T2、T3 で止める、T4 で ja と en、T16） |
| AC-41 | S4 | なし（端末のみ） | 経過＝max(0, …) | UI（T2、T3、T16 の set） |
| AC-42 | S2 | なし（端末のみ） | Book（足さない） | UI（T2、T5 book_add） |
| AC-43 | S3 → S6 → S7 | なし（端末のみ） | ReadingSession（残す） | UI（T2、T5 session_delete） |
| AC-44 | S1 | なし（端末のみ） | ReadingSession.startedAt の週 | UI（T2、T3、T4、T15） |
| AC-45 | S4 → S5 → S3 | なし（端末のみ） | ActiveReading.finishedAt | UI（T2、T3、T16） |
| AC-46 | S5 → S4 → S5 | なし（端末のみ） | pausedTotalSeconds、下書きを消す | UI（T2、T3、T16） |
| AC-47 | S4 → S5 → S4 → S5 | なし（端末のみ） | 下書きを消す、分の初めの値 | UI（T2、T3、T16） |
| AC-48 | S5 → S4 | なし（端末のみ） | session_cancel_finish（下へのスワイプ） | UI（T2、T3、T16。swipeDown） |
| AC-49 | S2 → S3 | なし（端末のみ） | Book | UI（T2） |
| AC-50 | S1 → S4 → S5 → S3 | なし（端末のみ） | ReadingSession | UI（T2、T3、T16） |
| AC-51 | S1 → S4 → S3 | なし（端末のみ） | ActiveReading を消す | UI（T2、T3、T16） |
| AC-52 | S3 | なし（端末のみ） | ActiveReading | UI（T2、T17） |
| AC-53 | S2 → S1 | なし（端末のみ） | Book（足さない） | UI（T2） |
| AC-54 | 起動 → S1（読み込みの失敗） | なし（端末のみ） | 読み込み（load） | UI（T2、T5 load:*） |
| AC-55 | S1 → S1 → S3 | なし（端末のみ） | 読み込み（load）。ストアを消さない | UI（T2、T5 load:1） |
| AC-56 | S1、S3 | なし（端末のみ） | ActiveReading を足さない（session_start） | UI（T2、T5 session_start:1） |
| AC-57 | S1 → S4、S3 → S4 | なし（端末のみ） | ActiveReading.startedAt＝再試行の時刻 | UI（T2、T3、T5、T16） |
| AC-58 | S4 | なし（端末のみ） | ActiveReading（reading のまま。session_pause） | UI（T2、T3、T5 session_pause:1、T16） |
| AC-59 | S4 | なし（端末のみ） | ActiveReading.pausedAt＝再試行の時刻 | UI（T2、T3、T5、T16） |
| AC-60 | S4 | なし（端末のみ） | ActiveReading（paused のまま。session_resume） | UI（T2、T3、T5 session_resume:1、T16） |
| AC-61 | S4 | なし（端末のみ） | pausedTotalSeconds＋（再試行の時刻 − pausedAt） | UI（T2、T3、T5、T16） |
| AC-62 | S4 | なし（端末のみ） | ActiveReading（reading か paused のまま。session_begin_finish） | UI（T2、T3、T5 session_begin_finish:1、T16、T17） |
| AC-63 | S4 → S5 | なし（端末のみ） | finishedAt＝再試行の時刻、下書きを作る | UI（T2、T3、T5、T16、T17） |
| AC-64 | S5 | なし（端末のみ） | finishing のまま（session_cancel_finish）。下書きを残す | UI（T2、T3、T5 session_cancel_finish:1、T16） |
| AC-65 | S5 → S4 | なし（端末のみ） | pausedTotalSeconds＋（再試行の時刻 − finishedAt）、下書きを消す | UI（T2、T3、T5、T16） |
| AC-66 | S4 | なし（端末のみ） | ActiveReading を残す（session_discard） | UI（T2、T3、T5 session_discard:1、T16） |
| AC-67 | S4 → S3 | なし（端末のみ） | ActiveReading を消す（再試行の時点で経過60秒未満） | UI（T2、T3、T5、T16） |

## 3. 構成図
システムコンテキスト図（外とのつながりは、利用者、CI の受け入れテスト、OS のバックアップ。本番のアプリはネットワークに出ない。ADR 0003）
```mermaid
flowchart LR
  user["利用者（人）<br/>iPhone で本を足し、読む時間を計る"]
  runner["受け入れテスト（ソフトウェア）<br/>XCUITest のランナー、CI の macOS のシミュレーター<br/>アプリを起動して結果を確かめる"]
  subgraph device["信頼の境界：端末の中（iPhone、iOS 17.0 以上）"]
    app["Yomutoki（ソフトウェア）<br/>SwiftUI と SwiftData のアプリ<br/>読書の時間とページを端末の中に残す"]
  end
  user -->|"タップと文字の入力（UIKit のイベント）"| app
  runner -->|"起動の引数と環境変数、URL（XCUIApplication。Debug ビルドだけ）"| app
  backup["OS のバックアップ（外のシステム）<br/>iCloud バックアップと、Mac か PC への端末のバックアップ<br/>端末のファイルを OS が写す。アプリのコードはない"]
  device -->|"Library.store と UserDefaults を写す（OS が行う。暗号化は OS と利用者の設定。ADR 0001）"| backup
```
コンテナ図（1つのアプリのプロセスの中。ローカルの Swift パッケージは作らないので、コンテナはアプリのターゲットの中のフォルダ）
```mermaid
flowchart TB
  user["利用者（人）"]
  runner["受け入れテスト（XCUITest のランナー）<br/>別プロセス"]
  receiver["テストの受け口（verifier の HTTP サーバー）<br/>localhost。届いたイベントを数える"]
  subgraph device["信頼の境界：端末の中"]
    subgraph app["Yomutoki のプロセス"]
      ui["画面（Screens/）<br/>SwiftUI の View と @Observable のモデル<br/>S1〜S7 を出し、操作を受け、保存が通ってから状態を変える"]
      domain["ドメイン（Domain/）<br/>Swift の値型と純粋な関数<br/>経過、合計、週、前の本、題名の整え方、区間を計算する"]
      store["保存（Store/）<br/>SwiftData の mainContext、SchemaV1<br/>1操作1回の save、失敗で rollback、読み込みの失敗を返す"]
      telem["計測（Telemetry/）<br/>TelemetryEvent と TelemetrySink<br/>本番は UserDefaults で回数を数えるだけ"]
      clock["時計と暦（Domain/AppClock）<br/>Date を返す関数と Calendar<br/>本番は端末の時計と暦の設定"]
      subgraph debug["信頼の境界：テストの受け口（Debug ビルドで -UITest のときだけ。Release に入らない）"]
        hooks["UITestHooks.swift（Debug/）<br/>#if DEBUG。つなぎ口の2ファイルの片方（ADR 0005）<br/>UITEST_ と readingapp-uitest:// を読み、時計、保存の失敗、送り先を差し替える"]
        sink["HTTPTelemetrySink.swift（Debug/）<br/>URLSession。#if DEBUG。つなぎ口の2ファイルの片方<br/>イベントを1件ずつ POST する。T22 では渡されたイベントを覚える"]
      end
    end
    db[("Library.store<br/>SwiftData のファイル（Application Support）<br/>本、記録、進行中の読書")]
    defaults[("UserDefaults<br/>計測の印と回数")]
  end
  user -->|"タップと文字（UIKit のイベント）"| ui
  ui -->|"計算を頼む（関数呼び出し）"| domain
  domain -->|"今の時刻と週を読む（関数呼び出し）"| clock
  ui -->|"保存と読み込みを頼む（関数呼び出し、throws）"| store
  store -->|"読み書き（SwiftData、ファイル）"| db
  ui -->|"イベントを渡す（TelemetrySink.send、async）"| telem
  telem -->|"回数を足す（UserDefaults）"| defaults
  runner -->|"起動の引数、環境変数、URL scheme（XCUIApplication）"| hooks
  hooks -->|"差し替えを入れる（組み立ての場所で注入）"| clock
  hooks -->|"失敗させる操作を入れる（関数）"| store
  hooks -->|"送り先を差し替える（TelemetrySink）"| sink
  sink -->|"POST /events、/flushed（HTTP と JSON、localhost）"| receiver
```
- protocol は TelemetrySink の1つだけ（実装が本番と Debug の2つあるため）。時計は protocol にせず、`now: () -> Date` を持つ値（名前は AppClock。Swift 標準の Clock とぶつけない）。保存の失敗の差し替えは、保存の層の save の直前に呼ぶ関数（既定は何もしない）で入れ、protocol を作らない。

## 4. 契約の変更と互換性
HTTP の契約はない（サーバーがない。ADR 0001、0003）。契約は contracts/ の Markdown と JSON Schema。
| operationId | 足す / 変える | AC | 認証 | 作る POST の Idempotency-Key |
|---|---|---|---|---|
| なし（HTTP の operation は0件） | － | AC-1〜AC-67 は端末のみ | 不要（アカウントなし） | 対象外 |

この作業で変えた契約（すべて足すだけ。ただし test-hooks.md の T1 の「使う AC」から AC-23、AC-53 を T2 に移したのは書き方の直しで、つなぎ口の名前、型、動きは変えていない）：
| ファイル | 変えたこと | AC |
|---|---|---|
| contracts/data-model.md | 保存の操作の表の3行（終える60秒以上、60秒未満、やめる）に T5 の名前と失敗したときを入れた。時刻の決まり、終える入力の下書き、前の本（記録を消したとき）、state の知らない値の扱いを足した | AC-13、AC-46〜AC-48、AC-62〜AC-67 |
| contracts/test-hooks.md | T5 の操作に session_begin_finish、session_cancel_finish、session_discard。T2、T3、T5、T8、T16 の使う AC に AC-62〜AC-67 | AC-62〜AC-67 |
| contracts/telemetry.md、telemetry-events.schema.json | Save Failed の operation に同じ3つ。SaveOperation の case。Discarded は再試行で通ったときも出す | AC-62〜AC-67、PRD 15 |
| contracts/examples/telemetry-save-failed-session-discard.json | 例を1つ足した | 同上 |
| contracts/test-hooks.md（G1 reviewer r1 の後） | T22（UITEST_TELEMETRY_LOG と uitest.telemetry.log。T6 の代わり）、T4 に UITEST_LOCALE（-AppleLocale の代わり）を足した。つなぎ口のファイルを Debug/ の2つと決めた。使う AC を 2 の表とそろえた（T1 は 2 の表の T1 の行に合わせて AC-20 を足し、AC-23 と AC-53 を T2 に移した。ほかは足すだけ） | AC-15、AC-20、AC-23、AC-24、AC-36、AC-40、AC-44 |
| contracts/data-model.md（同） | 題名を切った後にもう一度前後の空白を除く。ActiveReading が2件以上なら読み込みの失敗 | AC-2、AC-3、AC-54 |
| contracts/telemetry.md（同） | T22 の覚える包みと、送り先のファイルの名前 | AC-20、AC-23、AC-24 |
| contracts/dependencies.md、contracts/README.md（同） | XcodeGen 2.46.0 とチェックサム、ajv-cli 5.0.0 の行。README の4を ios_build と同じ確かめに直した | － |
| contracts/tools/xcstrings_untranslated.py（同） | en の state が translated で値が空のキーも数える | AC-39 |

- spectral の出力：対象外（OpenAPI がない）。代わりに contracts/README.md の1の ajv を動かした（`make contracts-check`）。結果：seed.example.json、seed-ac15.json、seed-ac33.json、telemetry の例10件、flushed.json がすべて valid、終了コード0。綴りの違う operation（"session_finishing"）は終了コード1で拒まれた。
- oasdiff breaking の出力：新規（origin/main の contracts/ は .gitkeep と dependencies.md だけで、openapi.yaml はない）。代わりの互換の確かめ（contracts/README.md の2）：`git diff origin/main -- contracts/ | grep -cE '^-[^-]'` は 0（dependencies.md の表の行は消さずに足した）。
- G1 reviewer r1 の後に動かしたもの（2026-10-21、この環境の Linux）：
  - `make contracts-check`（ajv-cli@5.0.0）→ seed.example.json、seed-ac15.json、seed-ac33.json、telemetry の例10件、flushed.json がすべて valid、終了コード0（npm の deprecated の警告2行：inflight@1.0.6、glob@7.2.3。ajv-cli 5.0.0 の依存）。
  - 互換：`git diff origin/main -- contracts/ | grep -cE '^-[^-]'` → 0。
  - 2 の表の T と contracts/test-hooks.md の「使う AC」の照合（T ごとに AC の集合を比べるスクリプト。スクラッチパッドで動かした）→ 違いは T8、T9、T10、T18 だけ（識別子と文言のキーで、2 の表に書かないと決めたもの）。
  - `python3 -I contracts/tools/xcstrings_untranslated.py <例>`：提案16 の例（en が translated で値が空、plural の one が空、needs_review、shouldTranslate false）→ k.enNeedsReview（not translated）、k.enPluralOneEmpty（empty value）、k.enTranslatedEmpty（empty value）、untranslated_keys=3、終了コード1。そろった例 → untranslated_keys=0、終了コード0。前の悪い例 → 7件（前は6件。k.enTranslatedEmpty を数えるようになった）、終了コード1。引数なし → 終了コード2。
  - ios_build の後ろ半分の論理を sh で試した（PlistBuddy の代わりに true と false）：UITEST_ を持つファイルが Debug/ の2つ、AcceptanceTests/、build/ だけなら 0。Screens/ にあれば名前を出して 1。strings：ファイルなし 1、きれい 0、`UITEST_NOW` と `uitest.telemetry.log` があれば行を出して 1。PlistBuddy の反転：キーなし 0、キーあり 1、ファイルなし 1。版の検査：「Xcode 26.0」「Xcode 27.1」0、「Xcode 16.4」「Xcode 2.5」1。entitlements の値：NSFileProtectionComplete 0、NSFileProtectionCompleteUnlessOpen 1。
  - XcodeGen の zip：`echo '4d9e…6806  <zip>' | shasum -a 256 -c -` →「OK」終了コード0。違う値 →「FAILED」終了コード1。
  - `wc -l CLAUDE.md` → 62。CLAUDE.md と Makefile の ios_build、ios_test の行は diff で同じ。
- 互換性を壊す変更：なし。
- 返す enum に足した値：Save Failed の operation に3つ。読むのはテストの受け口だけで、古いアプリが読む値ではない。保存する値で enum にあたるのは ActiveReading.state（文字）で、知らない値は読み込みの失敗にして保存先を消さない（data-model.md。v1.0 の前に前方互換の方針を決め直す：ADR 0001 の見直す条件）。ActiveReading が2件以上見つかったときも読み込みの失敗。単体テストを ios-engineer に頼む：state が "unknown" のストアと、ActiveReading が2件のストアを開くと AC-54 の表示になり、ファイルが残る。
- エラーの type と文言（design/ の 7。problem+json は使わない。失敗は端末の中の保存と読み込みだけ）：
  | 失敗（T5 の名前） | 出す所と文言のキー |
  |---|---|
  | load | S1：error.loadFailed.title、error.loadFailed.message、error.loadFailed.retry |
  | book_add | S2：error.saveFailed、error.saveFailed.book、error.retry |
  | session_start | S1 か S3：error.saveFailed、error.saveFailed.start、error.retry（文 error.retry.start） |
  | session_pause、session_resume | S4：error.saveFailed.pause か .resume、error.retry（文 error.retry.pause か .resume） |
  | session_begin_finish、session_discard | S4：error.saveFailed、error.saveFailed.finish、error.retry（文 error.retry.finish。D-58） |
  | session_cancel_finish | S5：error.saveFailed、error.saveFailed.cancel、error.retry（文 error.retry.cancel。D-60） |
  | session_finish | S5：error.saveFailed、error.saveFailed.session、error.retry |
  | session_delete | S7（alert）：error.saveFailed、error.saveFailed.delete |

## 5. データモデルと移行
| エンティティ | 正しいデータの置き場所（端末 / サーバー） | 個人情報か | 保存期間 | 消し方 |
|---|---|---|---|---|
| Book | 端末（SwiftData。バックアップに入る） | 利用者が入れた内容（題名から好みがわかる）。外に出さない、ログに出さない | アプリを消すまで | アプリを消す |
| ReadingSession | 端末（SwiftData。バックアップに入る） | 行動の記録（時刻、長さ、ページ） | 利用者が消すまで | S3 の削除（AC-16）、アプリを消す |
| ActiveReading | 端末（SwiftData。バックアップに入る） | 同上 | 記録を保存するか60秒未満で終えるまで | 終える、アプリを消す |
| 計測の印 | 端末（UserDefaults） | いいえ（時刻、真偽、回数だけ） | アプリを消すまで | アプリを消す |
| 終える入力の下書き | 端末のメモリだけ（保存しない） | ページと分（外に出さない） | S5 を閉じるか、プロセスが終わるまで | 保存かやめるが通る、強制終了 |

- SwiftData の版：SchemaV1（1.0.0）。MigrationStage は0件（最初の版）。形は contracts/data-model.md。この作業で項目は変えていない。
- 前の版のストアを開けるかのテスト：001 は最初の版なので対象なし。001 の版から次の版へ上げても記録が残ることは 002 の AC（PRD 12）。
- サーバーの DB の変更：なし。
- 題名の上限は形B（保存のときに先頭の100字に切る。PRD 10 が許す形）に決めた。理由：形A は UITextField を UIViewRepresentable で包む独自の部品になり、Dynamic Type と VoiceOver と焦点を作り直す範囲が増え、変換中の動きはこの環境（Mac なし）で確かめられない（裁定の (f)）。形B は標準の TextField のままで、Character の数（A95、A96）と prefix(100)（A97）で作れる。切った後にもう一度前後の空白4種を除く（切った位置の前が空白のとき、末尾に空白を残さないため。G1 reviewer r1 の提案10。contracts/data-model.md）。見せ方は D-57 の形B（整えたあとの字数が100を超えている間 book.add.titleLimit に book.add.titleLimit.onSave を出す。String Catalog に book.add.titleLimit を入れない）。
- design 10 の 8（下へのスワイプでやめる保存に失敗したら、シートを同じ値で開き直す）：作れる見込み。作り方は contracts/data-model.md の「終える入力の下書き」。入れかけの値をシートの外（S4 の @Observable のモデル。A10）に持ち、シートを出す Bool も state と別に持つ。下へのスワイプで閉じた後の sheet(isPresented:onDismiss:content:) の onDismiss で、やめる保存を呼ぶ（A109：iOS 13.0。onDismiss の本文「The closure to execute when dismissing the sheet.」 https://developer.apple.com/documentation/swiftui/view/sheet(ispresented:ondismiss:content:) 。2026-10-21 にドキュメントの JSON を取得、200）。失敗したら Bool を true に戻して開き直す。成功するふだんのスワイプは止めないので、AC-48 の見え方は変わらない。未確認：onDismiss の中で true に戻すと開き直るか（ios-engineer が最初の CI で確かめる）。代わりの案：(1) 次の MainActor の順番（`Task { @MainActor in … }`）で true に戻す。(2) それでも開かなければ、スワイプで閉じる前に保存する形（interactiveDismissDisabled（A60）と自前の確認）になり、AC-48 の見え方が変わるので designer と pdm に戻す（design 10 の 8 のとおり）。

## 6. 非機能の目標
表の中のコマンドの `\|` は Markdown の表のための書き方で、動かすときは `|` にする。
基準の機種：P-11 の答えで決める。暫定は「最低対応 OS（iOS 17.0）が動くいちばん遅い機種」（A12 の iPhone XS と XR の見込み。iOS 17 の対応機種の一覧は開いていないので未確認）。
| 項目 | 目標 | 測り方と時期 | 確かめる役 |
|---|---|---|---|
| 起動 | 起動から S1 で操作できるまで 2.0秒以内（5回の中央値、Release） | XCTApplicationLaunchMetric(waitUntilResponsive: true)、基準の機種の実機で G4（Takuma の Mac。P-14）。CI のシミュレーターの値は参考（G3）。公開後は Xcode Organizer の起動時間の p90（A52） | verifier |
| 読み始めの反応 | home.startReading か book.startReading から reading.elapsed の最初の表示まで 0.5秒以内 | XCTOSSignpostMetric（T20、A50）で G3（CI のシミュレーター）。実機は G4 | verifier |
| 大きなデータ | 本500冊、記録10,000件で、S1 と S3 が 1.0秒以内に出る | T21（UITEST_SEED_BULK）と XCTClockMetric、G3（CI のシミュレーター） | verifier |
| 反応（全体） | 操作から画面の変化まで 100ms 未満。250ms 以上の hang は0件 | Instruments の Hangs（G4、Takuma の Mac。なければ「未計測」と書く）。公開後は Xcode Organizer の Hangs（A52） | verifier |
| API | なし（サーバーがない）。本番のアプリが通信する箇所は0件 | `grep -rln 'URLSession' ios/Yomutoki --include='*.swift' \| grep -v '^ios/Yomutoki/Debug/' \| wc -l` が 0（G2） | reviewer |
| オフライン（画面ごと） | S1〜S7 はすべて機内モードで使える。計測の送信の失敗は捨て、画面に何も出さない。ぶつかる相手はない（端末だけ） | AC-20（T6、T7、G3）。実機の機内モードは G4 で Takuma | verifier |
| 電池 | バックグラウンドの処理0件（ファイルの保護 .complete の前提。ADR 0001）。自動ロックを止めない。毎秒の書き直しは S4 が出ている間の TimelineView だけ | `grep -rnE 'BGTaskScheduler\|beginBackgroundTask\|isIdleTimerDisabled\|UIBackgroundModes' ios/` が 0件（G2） | reviewer |
| セキュリティ | ATS の例外0件。トークンなし（アカウントなし）。ファイルの保護は .complete（Data Protection の entitlement、NSFileProtectionComplete。ADR 0001。バックグラウンドの処理0件が前提で、電池の行の grep で守る）。App Attest は使わない（守る API がない）。つなぎ口が Release に0件 | `grep -rn 'NSAllowsArbitraryLoads' ios/` が 0件（G2）。ios_build の entitlements の確かめ（PlistBuddy で NSFileProtectionComplete）と、Release の strings が0件、CFBundleURLTypes がない（ADR 0005、contracts/README.md の4。G2 の CI） | reviewer |
| プライバシー | 001 の本番は端末の外にデータを送らない。PrivacyInfo.xcprivacy は NSPrivacyTracking false、NSPrivacyCollectedDataTypes は空、UserDefaults の理由を1つ書く（理由の番号は A33 の一覧で ios-engineer が確かめる）。App Store の表記は「データの収集なし」（SDK を入れる 003 で直す） | plutil -lint と照合（G2、G4）、G5 で tech-lead が表記の下書きと照合 | reviewer |
| アクセシビリティ | AX5 で経過とすべての操作が切れない。コントラスト 4.5:1（大きい文字は 3:1）。押せる範囲 44×44pt。経過の読み上げは AC-40 の形 | G3 のスクリーンショット（ライト、ダーク、AX5、英語）を design-reviewer が測る。AC-40 は UI テスト | design-reviewer、verifier |
| 言語 | ja と en のそろっていないキー0件 | T14（`untranslated_keys=0`）、Linux で G2 と G3 | verifier |
| ビルドの警告 | 警告0件（Swift 6、並行性の検査は完全） | ios_build のログで `grep -c ' warning: '` が 0（G2。ADR 0002） | reviewer |
| 前の版からの更新 | 001 は最初の版なので対象なし。SchemaV1 から始める | 002 の AC（PRD 12） | verifier |

## 7. 脅威モデル
- 何を作るか（守るものと境界）：守るのは利用者が入れた題名と読書の記録（個人の内容）。境界は2つ：端末の中（外への送信は本番で0件）と、テストの受け口（Debug ビルドで -UITest のときだけ。UITEST_ の環境変数、readingapp-uitest:// の URL、localhost への HTTP）。認証、課金、外部のサービスはない。
- それで十分か：鍵がかかった端末からストアを読まれる危険は、ファイルの保護 .complete で減らす（ADR 0001）。鍵を開けた端末を手にした人と、バックアップから読まれる危険は受け入れる（OS の画面のロックとバックアップの暗号化に任せる）。Release につなぎ口が入らないことを機械で確かめる（ios_build）のが一番の対策。

| STRIDE | 起きうること | 対応（減らす / なくす / 移す / 受け入れる） | 確かめるテストか確認 |
|---|---|---|---|
| なりすまし（S） | ほかのアプリが readingapp-uitest://clock を開き、時計を動かして記録の時間を変える | なくす：URL scheme は Debug の Info.plist にだけあり、受けるコードは #if DEBUG（ADR 0005） | ios_build（contracts/README.md の4）：Release の Info.plist に CFBundleURLTypes がない、strings で readingapp-uitest が0件（G2 の CI） |
| 改ざん（T） | ストアのファイルや UITEST_SEED を書き換えて、変な値（負のページ、1万字の題名）を入れる | 減らす：seed は Debug だけで、合わなければ起動で止める（T2）。本番は自分の端末の自分のデータなので、読むときに範囲の外の値で落ちないようにする（経過は max(0, …)、% は totalPages nil で出さない） | 単体テスト（範囲の外の値で落ちない）、AC-41 |
| 否認（R） | 「消していない記録が消えた」と利用者が思う | 受け入れる：アカウントも監査の記録もない（個人の端末だけのため）。消す前に S6 で確かめる | AC-16、AC-38、AC-43 |
| 情報の漏れ（I） | 題名やページが計測、ログ、クラッシュの報告から外に出る。盗まれた端末やつないだ Mac から、鍵がかかったままストアのファイルを読まれる | なくす：TelemetryEvent に String と Int を持たせない、本番は送らない（ADR 0003）。Logger は既定の非公開、`privacy: .public` は操作と状態の名前だけ。減らす：ストアのファイルの保護を .complete にする（鍵がかかっている間は読めない。ADR 0001） | AC-23。`grep -rn 'privacy: .public' ios/` の行ごとに理由（G2、reviewer）。ios_build の entitlements の確かめ（G2 の CI）。実機での効き目は未確認（Mac と実機。P-14） |
| サービスの妨害（D） | 長い題名の貼り付け、とても長い数字、壊れたストアで落ちるか起動できなくなる | 減らす：題名は保存のときに100字に切る（形B）。数字の欄は桁が多くても落ちない（Int に変換できなければ範囲の外の誤り）。読み込みの失敗はストアを消さず再試行を出す（AC-54、AC-55） | 単体テスト（10万字の題名、20桁の数字）、AC-54、AC-55 |
| 権限の格上げ（E） | Release で -UITest を付けて起動し、保存の失敗や時計の差し替えを動かす | なくす：つなぎ口のコードが Release の実行ファイルに入らない（Debug/ の2ファイルの #if DEBUG） | ios_build（contracts/README.md の4。strings で UITEST_、-UITest、uitest. が0件。G2 の CI） |

## 8. 観測と KPI イベント
- iOS のログ：Logger（subsystem はバンドル ID、category は store、telemetry、ui）。.public にするのは保存の操作の名前（SaveOperation の rawValue）と状態の名前だけ（題名とページを含まないため）。題名とページは既定の非公開のまま。
- signpost：T20 の FirstElapsedShown（subsystem "yomutoki"、category "perf"）。Release にも残す。
- MetricKit：001 は購読しない（受け取っても送る先がなく、ADR 0003 で本番は通信しない）。公開後の起動、hang、クラッシュは Xcode Organizer と App Store Connect で見る（A52。TestFlight の版で出るかは未確認）。003 で送り先を入れて購読するときは、iOS 26 以下は MXAppLaunchMetric（A51：iOS 13.0〜27.2）、iOS 27 以上は TimeToFirstDrawMetric（A51：iOS 27.0+）を #available で分ける。
- バックエンド：なし。
- 001 の本番では、イベントは端末の中で数えるだけ（UserDefaults の telemetry.localCounts）。KPI を集めて見られるのは、送り先を決め直す 003 を含む v1.0 から（PRD 13 の判定日は v1.0 の公開から数える）。PRD 14 の1行目（Takuma の7日間の読書の回数）は S3 の記録の数で数える。

| PRD 15 のイベント | 送る場所（アプリ / サーバー） | 使う所（KPI / 撤退基準 / G6 の止める基準） |
|---|---|---|
| App First Opened | アプリ | KPI：I-1 の分母。撤退基準：初日の読書（20%未満、10%未満） |
| Book Added | アプリ | KPI の補い（初日の流れのどこで止まるか）。AC-23 |
| Reading Session Started | アプリ | ガードレール：読書の完了率の分母。撤退基準：完了率60%未満 |
| Reading Session Finished | アプリ | KPI：I-1 の分子（is_first_5min、since_first_open）。完了率の分子、保存の失敗の分母。撤退基準：初日の読書、完了率 |
| Reading Session Restored | アプリ | 診断（強制終了から戻った数。完了率が下がったときの切り分け） |
| Reading Session Discarded | アプリ | 診断（60秒未満でやめた数。完了率の切り分け） |
| Reading Week Reached | アプリ | KPI：North Star（週の読書者数） |
| Save Failed | アプリ | ガードレール：保存の失敗（1,000回あたり1回未満）。G6 の止める基準の候補 |
| Load Failed | アプリ | 診断（目標と撤退の線を持たない。PRD 15） |

## 9. 依存ライブラリの変更
- ランタイムのライブラリ：なし（0件）。Package.resolved はない。
- ビルドの道具：XcodeGen 2.46.0（GitHub Releases の zip を SHA-256 で確かめてから使う。contracts/dependencies.md の1行と詳しい列。ADR 0004）。zip の取得とチェックサムはこの環境で確かめた（ADR 0004 の A112）。実行とビルドの出力は未検証（裁定の追記2 の (1)。実行ファイルは macOS 用）。最初の CI の ios_build のログ（shasum の OK、`xcodegen --version`、`xcodegen generate`、`xcodebuild -version`、ビルドの結果）を ios-engineer が報告に貼る。
- 契約の検査の道具：ajv-cli 5.0.0 を表に足した（contracts/dependencies.md。ADR なし）。解決と実行の出力は 4。
- 後で Swift パッケージを足すときの注意：XcodeGen の作るプロジェクトの中にできる Package.resolved は .gitignore で無視されるので、置き場所（例：ios/ の直下に写してコミットし、CI で比べる）を、その ADR で決める。

## 10. ADR と未確認
- この機能で書いた ADR：0001〜0005（7a で書いた。この作業で新しい ADR はない。題名の上限の形B は PRD 10 が許した2つの形の片方で、元に戻すのは小さいので ADR にせずこのメモの 5 に書いた）。
- 未確認の項目、確かめる方法、確かめる役。この表はどれも裁定（docs/reviews/001-reading-session-G1-ruling.md の裁定1、追記、追記2）に名前があり、G1 を止めない。ios-engineer は実装の最初の push の後の CI で確かめ、出た / 出ない、使った代わりの案を報告に書く（裁定の3）。G3 まで残れば G3 は通らない：
  | 項目（裁定の番号） | 確かめ方 | 代わりの案 |
  |---|---|---|
  | 裁定1 の (a)〜(g)（session.state.* が見えるか、システムの部品の識別子、.contain の「削除」、S5 の swipeDown、alert の「キャンセル」、題名の上限（形B にしたので変換中の動きは対象外）、AC-49 の push と AC-54 の読み込みの失敗） | CI のスクリーンショットと UI テストの結果 | design 6 の (a)〜(g)、裁定1 2026-10-22 の CI の結果：（807f934 は en_US の回だけ。ja_JP の回のログはない）(a) 根の識別子は見えた（S1、S3。AC-56 で session.state.idle が根と 1pt の要素で2個）→ 1pt の要素を 8034689 で外した（CI の裁定1）。S4、S5 の根は次の CI。(b) 確かめのダイアログと編集の削除のボタンは識別子の Button で押せた（session.row.delete、session.delete.confirm、session.delete.cancel、book.add.discard.confirm。AC-16、AC-38、AC-53 が通った。807f934 のログ 3350、3594、1230）。confirmationDialog の取り消しも同じ（AC-38）。(c) は G4 の人の確かめ。(g) は AC-48 が swipe の前に原因A で落ちたので次の CI。題名の上限は対象外。AC-49 と AC-54 は通った（807f934 のログ 1037、808）。 |
  | D-46、D-48、D-53（追記） | CI のスクリーンショット（ライト、ダーク、コントラストを上げる設定） | 追記の2段の案、Text の並び、safeAreaInset か D-53 をやめる |
  | XcodeGen の実行とビルドの出力（追記2 の (1)。確かめ（A）の9） | ios_build のログ（shasum の OK、xcodegen --version、generate、xcodebuild） | 下の表の1行目 2026-10-22 の CI の結果：a4065e3 のログ で `xcodegen-2.46.0.zip: OK`（109）、`Version: 2.46.0`（110）、`Created project`（116）、Debug と Release の `** BUILD SUCCEEDED **`（925、1493）→ 解消。 |
  | D-60 の開き直し（追記2 の (2)。5） | UI テストで swipeDown と UITEST_FAIL=session_cancel_finish:1 | 5 の (1)。それでも開かなければ、やめる保存の失敗のときだけシートを閉じない（AC-48 の見え方は変わらない） 2026-10-22 の CI の結果：AC-48 と AC-64 は前提の途中で原因A（下の (ix)）で落ちたので次の CI。 |
  | シミュレーターの名前「iPhone 16」（追記2 の (3)） | ios_test のログの `xcrun simctl list devices available` | 一覧の iOS 26 の iPhone に替え、CLAUDE.md と Makefile と app.json（Takuma）をそろえる 2026-10-22 の CI の結果：iPhone 16 はなかった（a4065e3 のログ 1584）。一覧に iPhone 17（iOS 26.2、26.4、26.5 の見出しの下。1505〜1534）があり、Takuma が 807f934 で CLAUDE.md と Makefile を iPhone 17 に直した → 解消。 |
  | 手で書いた xctestplan が -testPlan で動くか（追記2 の (4)） | CI。identifier は `grep -n 'YomutokiAcceptanceTests' ios/Yomutoki.xcodeproj/project.pbxproj` で見る | Xcode の形に合わせて書き直す。だめなら -testPlan をやめ、`-only-testing:YomutokiTests` と `-only-testing:YomutokiAcceptanceTests` にする 2026-10-22 の CI の結果：807f934 で `-testPlan Unit` の後に `-testPlan Acceptance` が動き80本が実行（807f934 のログ 4904）→ 解消。identifier の grep の出力はない（動いたので合っていたと見る。推測）。 |
  | CODE_SIGNING_ALLOWED=NO で UI テストのランナーが動くか（追記2 の (5)） | CI | シミュレーター向けの自動署名を許す設定（テストの行だけ `CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO`） 2026-10-22 の CI の結果：署名なしで UI テストのランナーが動いた（807f934 で80本。807f934 のログ 4904）→ 解消。CLAUDE.md の「未確認」の1文は次に CLAUDE.md を直すときに改める。 |
  | macos-latest の Xcode が 26 か（追記2 の (6)） | ios_build の版の検査（26 未満なら落ちる） | `xcode-select` で 26 を選ぶ行をコマンドに足す（app.json は Takuma） 2026-10-22 の CI の結果：`Xcode 26.6`（a4065e3 のログ 111）→ 解消。 |
  | T2 の環境変数の長さ、T16 の open の確認、T4 の -AppleLocale、T20 の signpost（追記2 の (7)） | CI | T21 の形（ファイルから読む）、launchEnvironment の再起動、T4 の UITEST_LOCALE、AC-5 の値の確かめだけに留める 2026-10-22 の CI の結果：T16 は確認のダイアログでなく起動し直しが出た（下の (ix)）。T2 は seed を使うテストが通り、今の大きさでは渡せた（例：AC-14、AC-16。807f934 のログ 3204、3350）。T4 の -AppleLocale（ja_JP の回）と T20 は次の CI。 |
  | ビルドの設定の名前 SWIFT_DEFAULT_ACTOR_ISOLATION、SWIFT_TREAT_WARNINGS_AS_ERRORS（追記2 の (8)） | ios_build のログ | CI の出力のエラーから正しい名前に直す。警告は ADR 0002 のとおりログの warning を数える 2026-10-22 の CI の結果：Debug と Release のビルドが通り、Swift のコンパイラの警告は0件（a4065e3 のログ で `.swift:行:列: warning` が0件。`warning:` の2件は appintentsmetadataprocessor の 904、1467）。設定の名前が効いているかを直接示す出力はない（未確認）。 |
  | シミュレーターのアプリから localhost の受け口に届くか（追記2 の (9)。T6） | AC-20、AC-23、AC-24 の UI テスト | T22（uitest.telemetry.log の accessibilityValue を XCUITest が読む） 2026-10-22 の CI の結果：AC-20、AC-23、AC-24 は受け口に届く前に原因A で落ちたので次の CI（CI の裁定3。今は T22 に替えない）。 |
  | contracts/README.md の4（ios_build の Release の確かめ）の行が macOS で動くか（追記2 の (10)） | ios_build のログ | 成果物のパスか道具の出力の形が違えば、CLAUDE.md、Makefile、README、app.json（Takuma）を同じに直す 2026-10-22 の CI の結果：a4065e3 のログ で entitlements の検査、UITEST_ の grep、Release の strings、`Print: Entry, ":CFBundleURLTypes", Does Not Exist`（1495）まで通り、ios_build は終了0で ios_test に進んだ（1497）→ 解消。 |
- ios-engineer 13b の報告で「CI で確かめる」とした10点のうち、上の表になかった4点（ほかの6点は上の表の行に入っている）。裁定にはまだ名前がないが、上の表と同じに扱う（最初の push の後の CI で確かめ、出た / 出ない、使った代わりの案を報告に書く。G3 まで残れば G3 は通らない）：
  | 項目 | 確かめ方 | 代わりの案 |
  |---|---|---|
  | ContentUnavailableView の中の Text の識別子（AC-1 の library.empty.title、library.empty.message、AC-54 の error.loadFailed.title、error.loadFailed.message。ios/Yomutoki/Screens/HomeView.swift の emptyView、loadFailedView、BookDetailView.swift の ContentUnavailableView）。部品が中の Text をまとめ、Text に付けた accessibilityIdentifier が XCUITest から見えない恐れ | AC-1、AC-54 の UI テスト（識別子で要素を取り、label を文言と比べる）。落ちたら app.debugDescription をログに残す | その所だけ ContentUnavailableView をやめ、VStack に Image、Text（.isHeader）、Text、Button を並べる（D-48 の代わりの案「標準の Text の並び」と同じ形。designer に見た目の差を知らせる） |
  | String(localized:defaultValue:locale:) の数の桁区切り（ios/Yomutoki/Screens/Localized.swift の Loc.minutes、bookCount、sessionCount。design 7 の「1,234分」「記録 10,000件」）。書式の文の数に locale の桁区切りが付くか。単体テストはまだない | UI テストで1,000以上の値（分か件）を ja と en で出し、label を比べる（ios/AcceptanceTests/Support/L10n.swift の数の書式の決まり）。あわせて Loc.minutes(1234, locale: ja_JP) を比べる単体テストを足す | 数を `value.formatted(.number.locale(locale))` で先に文字にして書式の文に入れ、複数形は数の引数で選ぶ形に String Catalog を直す（この形は未確認。D-35 の「文字列をつなげない」は守る） |
  | 起動時の finishing の S5 の開き方（AC-34。ios/Yomutoki/Screens/RootView.swift の restore が path = [.reading] を積み、ReadingView.swift の ReadingModel.appeared が S5 を開く）。起動直後の push の途中でシートが出ない、または2回出る恐れ | AC-34 の UI テスト（ios/AcceptanceTests/Tests/FinishInputAcceptanceTests.swift の AC-34。finishing で起動し直し、S5 の要素の label を見る） | 読み込みが通ったら最初の描画の前に path を積む（push の動きを出さない）。それでも出なければ S4 の .task で次の描画を待ってから S5 を開く。どちらも S1 → S4 → S5 の並び（design 1）は変えない |
  | knownRegions と InfoPlist.xcstrings（ios/project.yml の developmentLanguage: ja と LOCALIZATION_PREFERS_STRING_CATALOGS、ios/Yomutoki/Resources/InfoPlist.xcstrings の CFBundleDisplayName）。.lproj のフォルダがなく xcstrings だけのとき、XcodeGen が作る knownRegions に en と ja が入るか。InfoPlist.xcstrings がビルドで各言語の InfoPlist.strings になりアプリに入るか（入らないと T4 の en でアプリの名前が英語にならない） | xcodegen generate の後の `grep -A4 knownRegions ios/Yomutoki.xcodeproj/project.pbxproj` と、ios_build の後に成果物の Yomutoki.app の中を `find -name 'InfoPlist.strings'` で見た出力（ios_build のログ） | project.yml の Info.plist の項目に CFBundleLocalizations（ja、en）を足す。InfoPlist.xcstrings が変換されなければ ja.lproj と en.lproj に InfoPlist.strings を置き、T14 の数える対象もそれに直す |
- この改訂（G1 reviewer r1 の後）で生まれた未確認。裁定の追記3 (i)〜(v) に入った（docs/reviews/001-reading-session-G1-ruling.md:47-53。Mac がないので CI か実機でしか確かめられない。どれも代わりの案がある）：
  | 項目 | 確かめ方 | 代わりの案 |
  |---|---|---|
  | (i) XcodeGen の zip を展開したまま動かして SettingPresets を見つけるか、`xcodegen --version` の形（ADR 0004） | ios_build のログ | `build/tools/xcodegen/install.sh build/tools/prefix` で写してから動かす。zip が使えなければ Mint（`mint run yonaskolb/xcodegen@2.46.0`） 2026-10-22 の CI の結果：展開したまま動いた（a4065e3 のログ 110、116）→ 解消。 |
  | (ii) include の合わせ方（target.yml のスキームの testPlans の配列、target.yml からの相対のパス。ADR 0004）。target.yml がないときに generate が落ちることは確認済み（XcodeGen 2.46.0 の Sources/ProjectSpec/SpecFile.swift:95、:100-105。G1 reviewer r2 の参考2） | xcodegen generate の後の `xcodebuild -list` と ios_test の出力 | include の relativePaths を false にし、パスを ios/ から書く 2026-10-22 の CI の結果：target.yml の `-testPlan Acceptance` が動いた（807f934 のログ 4904）→ 解消。 |
  | (iii) `xcodebuild -version` の1行目が「Xcode 26.0」の形か（ADR 0002 の版の検査） | ios_build のログ | grep の形を出力に合わせて直す 2026-10-22 の CI の結果：1行目は `Xcode 26.6`（a4065e3 のログ 111）で grep が通った → 解消。 |
  | (iv) uitest.telemetry.log の accessibilityValue の長さの上限（T22） | AC-20、AC-23、AC-24 の UI テスト（T22 に替えたときだけ） | 値を最後の n 件だけにする形を契約に足す |
  | (v) ファイルの保護（ADR 0001）：TestFlight のビルドに entitlement が入るか、実機で効くか、.complete のファイルが iCloud バックアップに入るか | G4 の前に Mac で `codesign -d --entitlements -`（P-14）。バックアップは Apple Platform Security の文書で | 入らなければ ADR 0001 を開き直す（ファイルごとの setResourceValue の案） |
  | (vi) View の中に入れた `private nonisolated enum Field`（ios/Yomutoki/Screens/FinishSessionView.swift:12、AddBookView.swift:19）に、Swift 6 の言語モードと既定の MainActor の分離で警告が出ないか | ios_build のログ（warning の数。ADR 0002 の警告0件） | nonisolated を外す（SE-0434 で既定の分離のままでも通る見込み。未確認） 2026-10-22 の CI の結果：ビルドが通り Swift の警告0件（a4065e3 のログ 925、1493）→ 解消（nonisolated は外していない）。 |
  | (vii) ReadingView.swift:280 の `TimelineView(.periodic(from: .now, by: 1))` の `.now` が `Date.now` として型が決まるか | ios_build のログ（コンパイルのエラー） | `.periodic(from: Date.now, by: 1)` と明示する（11 の 7 の例外のまま） 2026-10-22 の CI の結果：ビルドが通った（a4065e3 のログ 925、1493）→ 解消（`.now` のまま）。 |
  | (viii) ios/YomutokiTests/LibraryStoreTests.swift:376-420 の twoActiveReadingsOnDiskFailLoadAndKeepFile が、同じ SQLite のファイルを3つの ModelContainer で開く（書く用は do の範囲で手放す。読む用 h と確かめる用 reader は同時に開いている）。SwiftData でこれが通るか | ios_test の単体テスト（Unit.xctestplan）の結果 | 読む用の container を手放してから確かめる用を開く（例：h の確かめを do の範囲に入れる。今のコードは既に確かめる用を読む用の後に開いているので、順だけでは足りない） 2026-10-22 の CI の結果：807f934 の ios ジョブは Unit の後に Acceptance に進んだ（&& でつなぐので Unit は通った。件数はログの範囲外）。Takuma の Mac でも67件成功、失敗0（docs/reviews/001-reading-session-ci-settings-verification.md:24、:37）→ 解消。 |
  | (ix) XCUIApplication.open(_:) がアプリを起動し直すか（2026-10-22。CI 807f934 の原因A） | CI 807f934 で分かった：起動し直した。URL を開くと `Open com.example.yomutoki with URL readingapp-uitest://clock?advance=60` の直後に `Launch com.example.yomutoki` が出て（807f934 のログ 406、407）、AC-6 で uitest.clock.applied が「2」でなく「1」（2432）。UITEST_SEED と UITEST_RESET が入り直り、画面で変えた状態が消える（docs/verification/001-reading-session/ci-runs/807f934-acceptance-en.md の原因A） | T16 を改訂（contracts/test-hooks.md、2026-10-22）：XCUIDevice.shared.system.open(_:) でシステムから開き、確かめのダイアログが出れば押す（verifier の AppSession.sendClock）。次の CI でも起動し直すかダイアログを押せなければ `uitest.clock.advance.<秒>` のボタン（T16 の代わりの案） |
  | (x) iOS 26 のツールバーのボタンの識別子が付く要素（2026-10-22。原因C） | CI 807f934 で分かった：book.save、session.finish.save、session.finish.cancel、book.add.cancel は Other の要素に付いた（807f934 のログ の `Check for interrupting elements affecting "book.save" Other` など。最初は 926）。AC-3、AC-31 で無効のはずの book.save の isEnabled が true（1396、1154）［推測：Other の isEnabled は .disabled を映さない］ | テスト側で control()（識別子の Button、なければ中の Button）を使う（verifier）。契約と design 6 の識別子の名前は変えない。次の CI の [AT-DIAG] の要素の木で確かめる |
  | (xi) 右寄せの数字の欄の入れ直し（2026-10-22。原因B） | CI 807f934 で分かった：AC-47 で分の欄の「10」を「5」にすると「510」（807f934 のログ 213） | テスト側：右端のタップと、残ればダブルタップで選んで消す（verifier の UIHelpers.replaceText）。実装と契約は変えない |
- (vi)〜(viii) は 2026-10-21 に足した（ios-engineer の実装の報告で、Mac でしか確かめられないと分かったもの）。裁定の追記3 にはまだ名前がないが、上の表と同じに扱う（最初の CI で確かめ、出た / 出ない、使った代わりの案を報告に書く。G3 まで残れば G3 は通らない）。
- (ix)〜(xi) と各行の「2026-10-22 の CI の結果」は 2026-10-22 に足した。出どころは CI の2回のログ（リポジトリの外）：a4065e3（ios_build が通り、ios_test が iPhone 16 で落ちた回）と 807f934（en_US の回の末尾 4999 行）、docs/verification/001-reading-session/ci-runs/807f934-acceptance-en.md、docs/reviews/001-reading-session-G2-ci-ruling.md。
- CI の時間（2026-10-22）：ios_build は約74秒（a4065e3 のログ 107 の 11:55:39 → 1497 の 11:56:53）。Acceptance の en_US の回は80本で約35分（807f934 のログ 4904 の 2120秒）。807f934 の CI 全体は約78分（12:01→13:19。開始は指揮役の値でログの範囲外）。Acceptance が落ちて ac18-reboot.sh は動いていないが、11 の申し送りの見積もり（70〜135分）は合っていた。
- CI で決まらないもの：
  | 項目 | 確かめ方 | 代わりの案 |
  |---|---|---|
  | iOS 17 で1回確かめる場所（ADR 0002） | G3 の後に指揮役が Takuma に聞く | iOS 17 の実機で G4 の確認リスト、またはランタイムを入れた CI の手動の実行 |
  | 基準の機種（6） | P-11 の Takuma の答え | 暫定のまま G4 で CI の値を参考にする（P-14） |
  | PrivacyInfo.xcprivacy の UserDefaults の理由の番号 | A33 の一覧を ios-engineer が開く | － |

## 11. 実装の決まり（ios-engineer へ）
1. 色は Color の値で渡す（tech-lead r2 の提案1）。トークンは Asset Catalog の Color Set（design/tokens.md 1）か Color.primary などの Color の値にし、`.foregroundStyle(.primary)` のような階層の形（HierarchicalShapeStyle）を文字の色に使わない（A90）。確かめ：`grep -rnE 'foregroundStyle\(\.(primary|secondary|tertiary)' ios/Yomutoki` が 0件。
2. 自動保存を切る：ModelContainer を作った直後に `mainContext.autosaveEnabled = false`（A4）。1つの操作は1回の save（A3）、失敗したら rollback（A5）。確かめ：`grep -rn 'autosaveEnabled = false' ios/Yomutoki` が2件（本番の Model/LibraryStore.swift が1件、Debug/UITestHooks.swift の SeedWriter が1件。Debug/ の外では1件）。2026-10-21 に1件から直した（G2 の code reviewer r1 の提案13）。
3. 保存が通ってから画面とメモリの状態を変える（tech-lead r2 の提案3）。操作の時刻は保存が通った回の時刻（再試行ならその時刻。PRD 10）。失敗した回の値を残さない。
4. 題名は形B（5）。単体テスト：100字と101字、結合した絵文字、CRLF と U+2028、前後の全角空白、10万字の貼り付け、切った後に末尾の空白を除く例（99字＋U+3000＋1字は99字になる）。
5. 60秒未満で終える保存の再試行は、押した時点の経過で session_discard か session_begin_finish に分ける（D-59、PRD 18 の 6 の A）。T5 の数は、その回に試した操作の数を使う。
6. 終える入力の下書きとシートの Bool は S4 のモデルに持つ（5、contracts/data-model.md）。
7. 時計は AppClock（`now: () -> Date`）と Calendar を組み立ての場所で入れる。Date() をほかで直接呼ばない（つなぎ口が効かなくなるため）。確かめ：`grep -rn 'Date()' ios/Yomutoki --include='*.swift'` の行が AppClock と Debug/ の中だけ。
   - 追記（2026-10-21、G2 の code reviewer r1 の提案7）：例外：TimelineView の刻みの起点 `.periodic(from: .now, by:)` は端末の時刻でよい（ReadingView.swift。AppClock の時刻が端末より先だと刻みが始まらないため。下の 10 の (vii) で `Date.now` と書いたときも同じ）。表示と保存の値には使わず、経過は AppClock の今で計算する。確かめの grep（`Date()`）は変えない。
8. 計測の型は contracts/telemetry.md のとおり。関連値に String と Int を持たせない。
9. 最初の CI で、裁定の (a)〜(g) と D-46、D-48、D-53、D-60 と 10 の表の未確認を確かめ、結果と使った代わりの案を報告に書く（裁定の3）。G3 まで残れば G3 は通らない。
10. ファイルの保護（ADR 0001）：project.yml の Yomutoki の entitlements に `com.apple.developer.default-data-protection: NSFileProtectionComplete` を書く（path は Yomutoki/Yomutoki.entitlements。ios_build がこのパスを PlistBuddy で読む）。バックグラウンドの処理（BGTaskScheduler、beginBackgroundTask、UIBackgroundModes）を足さない。
11. T4 の UITEST_LOCALE と T22（UITEST_TELEMETRY_LOG と uitest.telemetry.log）は最初から作る（verifier が CI の結果で切り替えるため。contracts/test-hooks.md）。つなぎ口のコードは Debug/UITestHooks.swift と Debug/HTTPTelemetrySink.swift の2つだけ（ADR 0005。ios_build の grep で落ちる）。
   - 追記（2026-10-22）：ADR 0005 の 2026-10-21 の例外（RootView.swift と FinishSessionView.swift の 1pt の要素）は 8034689 で外して取り下げたので、この文は今は例外なしで文どおり（`grep -rnE 'UITestMarker|showsStateMarker' ios/Yomutoki --include='*.swift' | grep -v '/Debug/'` が0行。HEAD ba8b82a）。
12. G2 に出す単位（裁定の追記2 の要修正4）：実装の変更は、ios-engineer が「できた」と報告した HEAD を1つの変更として G2 に出す。途中の push は G2 に出さない。その HEAD で CI が緑であること。途中の push（雛形だけ、AC の一部だけ）は赤でもよい。雛形だけの変更を別に G2 に出すことはしない。verifier の受け入れテストの変更は gates.md の例外のとおり（スタックの CI は落ちるのが正しい）。
13. project.yml とスキームの決まり（tech-lead の G2 r1）：
   - project.yml の name は Yomutoki のまま変えない。xctestplan のターゲットの ID はこの名前から作られる（md5("NT_PBXNativeTarget-Yomutoki-YomutokiAcceptanceTests_1") の先頭24文字 DC1C774817D8D1F9A3D54A52 が Acceptance.xctestplan と AC18Reboot.xctestplan の identifier。tech-lead の G2 r1 の証拠）。
   - スキーム Yomutoki は最上位の schemes: に書く（target.yml の schemes.Yomutoki と合わさるため）。Yomutoki のターゲットの scheme: では作らない（同じ名前のスキームが別にでき、合わさらない見込み。推測）。
   - Unit.xctestplan は ios/YomutokiTests/Unit.xctestplan に置き、project.yml の schemes.Yomutoki.test.testPlans に `path: YomutokiTests/Unit.xctestplan, defaultPlan: true` で書く。project.yml の側に Acceptance.xctestplan と AC18Reboot.xctestplan を書かない（ADR 0004 の grep で include の1行の外に AcceptanceTests が出ないこと）。
   - 最初の CI で、ios/ の中で `grep -E '[0-9A-F]{24} /\* YomutokiAcceptanceTests \*/ = \{' Yomutoki.xcodeproj/project.pbxproj` の ID を xctestplan の identifier（DC1C774817D8D1F9A3D54A52）と照らし、結果を報告に書く。違えば報告する（xctestplan は verifier が直す）。

雛形の作り方（ios-engineer が ios/ に作る。tech-lead はコードを書かない）：
- ios/project.yml（XcodeGen。ADR 0004）：name Yomutoki。options の deploymentTarget は iOS 17.0、disabledValidations に missingTestPlans（受け入れテストの xctestplan を verifier が書く前でも generate できる。XcodeGen の ProjectSpec に「Disable checking if test plan paths exist. This can be useful if your test plans haven't been created yet.」とある。https://raw.githubusercontent.com/yonaskolb/XcodeGen/master/Docs/ProjectSpec.md を 2026-10-21 に取得）。
- 設定：SWIFT_VERSION 6.0、TARGETED_DEVICE_FAMILY 1、アプリのターゲットの既定の actor 分離は MainActor（ADR 0002）、警告をエラーにする設定（名前は未確認）。Info.plist は Debug と Release で分ける（ADR 0004）。entitlements は 10。
- ターゲット：Yomutoki（application、ios/Yomutoki/）、YomutokiTests（bundle.unit-test、ios/YomutokiTests/）、YomutokiAcceptanceTests（bundle.ui-testing、ios/AcceptanceTests/。定義は verifier の ios/AcceptanceTests/target.yml。project.yml は `include: [AcceptanceTests/target.yml]` を持ち、:REPLACE を使わない。ADR 0004）。
- スキーム Yomutoki の test の testPlans：Unit.xctestplan は project.yml の側に `defaultPlan: true` 付きで書く（ios-engineer。中身は YomutokiTests だけ。13）。Acceptance.xctestplan と AC18Reboot.xctestplan は target.yml のスキームの testPlans が持つ（verifier。defaultPlan を付けない。Acceptance の中身は YomutokiAcceptanceTests だけで、AC-18 の2つのテストは skippedTests に入れる。AC18Reboot は ac18-reboot.sh だけが使う）。include は target.yml が先に合わさり、project.yml が上に重なる（ProjectSpec の Include の節。A107）。配列は後ろに足され重複は消えないので、合わさった testPlans は Acceptance、AC18Reboot、Unit の順になり、既定の計画は project.yml の defaultPlan で決まる（既定が2つ以上だと SpecValidation で落ちる。2.46.0 の SpecValidation.swift:235-242。tech-lead の G2 r1）。XcodeGen は xctestplan を作らないので手で書く（ProjectSpec の Test Plan の節）。
- AC-18 の2段は verifier の ios/AcceptanceTests/ac18-reboot.sh（引数はシミュレーターの名前。`-testPlan AC18Reboot` と -only-testing で、データを作るテストだけ → `xcrun simctl shutdown` と `boot` → 確かめるテストだけ。どれも -retry-tests-on-failure なし）。
- AC-39 は verifier の ios/AcceptanceTests/ac39-xcstrings.sh（T14 の xcstrings_untranslated.py を包む。Linux でも動く）。ios_test に入っておらず、G3 で verifier が手で動かす。CI に入れるなら Takuma が app.json の ios_test の頭に `bash ios/AcceptanceTests/ac39-xcstrings.sh &&` を足す（そのとき tech-lead が CLAUDE.md と Makefile を同じ1行に直す）。
- 順番：ios-engineer の雛形（project.yml、空のアプリ、Unit.xctestplan、entitlements、Debug/ の2ファイル）と verifier の target.yml、Acceptance.xctestplan、AC18Reboot.xctestplan、ac18-reboot.sh、ac39-xcstrings.sh、受け入れテスト（red）→ 実装。001 では verifier の分が G2 で先にできたので、ios-engineer は target.yml がある状態で雛形を作る。target.yml がないと xcodegen generate が落ち（確認済み。XcodeGen 2.46.0 の Sources/ProjectSpec/SpecFile.swift:95、:100-105。G1 reviewer r2 の参考2）、ios_build も ios_test も落ちる。雛形だけの変更は G2 に出さない（12）。

申し送り（G1 reviewer r1 の提案17、18）：
- verifier へ：AC-18 の2つのテストは Acceptance.xctestplan の skippedTests に入り、ac18-reboot.sh で別に動く。G3 の「飛ばされていない」（docs/org/gates.md の G3）に対しては、検証レポートに ac18-reboot.sh の出力から動いた数（2）と結果を数えて書き、xcresult の skipped にこの2つが入るのは決めたとおりだと同じ所に書く。
- verifier へ：受け入れテストのターゲットとテスト計画の定義は ios/AcceptanceTests/target.yml に書く（ADR 0004。:REPLACE を使わない。sources の excludes に target.yml、*.xctestplan、*.sh を入れてバンドルに写さない）。T6 が CI で届かなければ T22 に、-AppleLocale が効かなければ UITEST_LOCALE に替え、テスト計画に書く。
- 指揮役へ（CI の時間。tech-lead の G2 r1 の 5）：CI の ios ジョブの上限は60分（.github/workflows/ios.yml:52 の timeout-minutes）。見積もり（推測）は、受け入れテスト160本（80本×ja と en の2つの構成。AC-20 の30秒待ちを含む）で53〜107分、ios_test のビルド5〜8分、単体テスト2〜3分、ac18-reboot.sh 4〜6分、ios_build 6〜10分で、合計70〜135分。60分を超えるおそれが高い。Takuma に頼む：ios.yml の timeout-minutes を 150 にするか、ジョブを分ける（例：ios_build、単体テスト、受け入れテストを別のジョブにし、app.json の commands も分ける）。縮める案（未確認）：-parallel-testing-enabled YES。最初の CI で ios-engineer が ios_build と ios_test の時間を測り、報告に書く。

## 確かめ（A）
- [x] 2 の表に PRD の全 AC があり、空の欄がない（AC-1〜AC-67 の67行。`grep -cE '^\| AC-[0-9]+ \|'` で 67）
- [x] 3 の図のすべての要素に技術と責任が、すべての矢印に用途と通信方式がある
- [x] 契約のすべての operation に operationId、成功とエラーの例、認証の要否、AC 番号がある。エラーは problem+json（対象外：HTTP の operation は0件。端末の中の失敗と文言は 4 の表）
- [x] 4 に spectral と oasdiff の出力（または「未検査」と理由）がある。互換性を壊すなら ADR と大きな版の上げがある（spectral は対象外で代わりに ajv の出力、oasdiff は新規。壊す変更なし）
- [x] 5 の全エンティティに置き場所、個人情報か、保存期間、消し方がある。モデルを変えたなら MigrationStage がある（項目は変えていない。SchemaV1 のまま）
- [x] 6 のすべての行に数字と測り方がある
- [x] 7 が STRIDE の6行か「新しい境界なし」のどちらか。受け入れた危険に理由がある
- [x] 8 で、PRD 15 の全イベントに送る場所がある（9イベント、すべてアプリ）
- [ ] 新しい依存に、解決とビルドの出力があり、dependencies.md の全列が埋まっている（未検証：裁定の追記2 の (1) により G1 を止めず、G2 の最初の CI の出力で確かめる。XcodeGen 2.46.0 は全列を埋め、zip の取得と SHA-256 までこの環境で確かめた。実行とビルドの出力はまだない。ajv-cli 5.0.0 は全列を埋め、`make contracts-check` の出力が 4 にある） → 2026-10-22：XcodeGen 2.46.0 の実行とビルドの出力が CI a4065e3 で出た（10 の表の追記2 の (1) と (i)）。印は G2 の reviewer の確かめの後に付ける。
