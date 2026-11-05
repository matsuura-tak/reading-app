# 入口の URL（AC-40）

- 書いた役：tech-lead　日付：2026-10-20（G1 の 7-3）。2026-10-25 に直した（G1 の 7 の続き：Live Activity とアプリの外のインテントが v1.0 に入り、書誌の問い合わせ（外部通信）がなくなったため。足しただけで、値の名前と意味は変えていないので大きな版は 1 のまま）
- 大きな版：1。同じ大きな版の中では足すことだけをする（スキーム、ホスト、引数の名前、値の名前と意味を変えない、消さない）。
- 関係：PRD の AC-40、AC-27、AC-35、AC-62、AC-114、AC-124、H17（entry）、H22・H23（押したときの URL）、H28（URL で起動）、H32（インテント）、G4-18。設計メモの 3（Sys → App の矢印）、5（Session.entry → Record.entry）、7（境界4、改ざん T）。ADR 0003。contracts/widget-snapshot.schema.json、contracts/hooks/h23-live-activity.schema.json。
- 確かめたこと：7-3 の spike（下の 6）。

## 1. URL の形
`yomuma://open?entry=<入口の値>`

| 入口 | URL | 付ける所 | 記録の印（H17 の entry） | 範囲 |
|---|---|---|---|---|
| ロック画面のウィジェット（W-1、accessoryRectangular） | `yomuma://open?entry=lock_widget` | W-1 のビュー全体の widgetURL（1つだけ） | `lock_widget` | v1.0 |
| 小のウィジェット（W-2、systemSmall。ホーム画面と StandBy） | `yomuma://open?entry=small_widget` | W-2 のビュー全体の widgetURL（1つだけ） | `small_widget` | v1.0 |
| Live Activity（W-3。予約したものも、すぐ始めたものも） | `yomuma://open?entry=live_activity` | Live Activity のビュー全体の widgetURL（「終える」のボタンの外を押したとき） | `live_activity` | v1.0 |
| ホーム画面のアイコン | なし | なし | `app` | v1.0 |
| アプリの外のインテント（W-4 の Control、Action ボタン、Siri、ショートカット） | なし（インテントが印を決める。URL を使わない） | なし | 「読み始める」で始めた読書は `intent_start`。「続きを読む」で開いて300秒以内に、後ろに回らずに始めた読書は `intent_open`（PRD 11 の冒頭の「入口の印」） | v1.0 |

- Live Activity の「終える」のボタン（識別子 `liveActivity.end`）は URL でなく、インテント「終える」を動かす（PRD 11 の冒頭。H23、H32）。ボタンの外を押したときだけ上の URL で開く。
- `intent_open` の決まりは 4 の (a)〜(c) と同じで、候補を「続きを読む」がメモリに置く（URL は使わない）。

- ウィジェットの中身の状態（一行あり、一行なし、隠す、今の本なし、読めない）に関わらず、同じ入口は同じ URL にする。
- URL には、書名、一行、ページ、本の id、日時を入れない。ロック画面の外へ中身を出さず、今の本が替わっても古い URL のままで正しく開くため。
- widgetURL はビューの木に1つだけ付ける（2つ以上は動きが決まらない。Apple の文書。6）。
- スキーム `yomuma` は中の名前で、表示名（仮の英語名 Yomuma。pdm が決める）が変わっても変えない。
- アプリの Info.plist の CFBundleURLTypes に `yomuma` を1つ登録する（App Store の版にも入れる）。理由は2つ。
  - widgetURL で開くときに登録が要るかを、Apple の文書は書いていない（文書は「システムが中のアプリを起こし、onOpenURL に URL を渡す」とだけ書く）。登録しないと G4-18 で開かない恐れがある［未確認］。
  - H28 が、OS の URL の道（onOpenURL）を通して起動できる。
  - 悪い点：ほかのアプリや Safari からも開ける（5 で受け入れる）。
  - 悪い点2：ほかのアプリが canOpenURL で、このアプリが入っているか（読書アプリを使っていること）を調べられる（reviewer r1 の P6。5 で受け入れる）。

## 2. 受ける側の読み方
1. スキームが `yomuma`、ホストが `open` のときだけ、入口の URL として読む。どちらも大文字と小文字を区別しない。
2. クエリの `entry` の最初の値を読む。値は大文字と小文字を区別する。`lock_widget`、`small_widget`、`live_activity` のどれかなら、入口の候補にする。
3. それ以外のときは、入口の候補を作らない。記録の印は `app` になる。エラーを出さず、画面は 3 のとおりに開く。
   - 対象：`entry` がない、知らない値、`app`、大文字の値、ホストが `open` でない、ほかのスキーム。
4. ほかのクエリ、パス、フラグメントは無視する。
5. 新しい版で値を足しても、古い版のアプリは知らない値として 3 の扱いになる。開くことはでき、印は `app` になる。

spike の読み方の結果（ReadingCore と同じ関数。6）：

| URL | 読んだ候補 |
|---|---|
| `yomuma://open?entry=lock_widget` | `lock_widget` |
| `yomuma://open?entry=small_widget` | `small_widget` |
| `yomuma://open?entry=live_activity` | `live_activity` |
| `YOMUMA://OPEN?entry=lock_widget` | `lock_widget` |
| `yomuma://open?x=1&entry=small_widget&entry=lock_widget` | `small_widget`（最初の entry） |
| `yomuma://open?entry=app` | なし（`app`） |
| `yomuma://open?entry=LOCK_WIDGET` | なし（`app`） |
| `yomuma://open?entry=unknown` | なし（`app`） |
| `yomuma://open` | なし（`app`） |
| `yomuma://book?entry=lock_widget` | なし（`app`） |
| `https://example.com/open?entry=lock_widget` | なし（`app`） |

## 3. URL で開いたときに起きること
起きることは、次の2つだけ。
1. 状態の画面を出す。`idle` なら S-1、`reading` なら S-2（PRD 11 の冒頭の状態の決まり）。プロセスがないときも、あるときも同じ。
2. 入口の候補（入口の値と、開いた時刻）をメモリに持つ。保存しない。

URL では保存を変えない。次のことは、URL を受けた処理から起こさない。
- 主の保存先（Book、Record、Session、Settings）に書かない。
- 写し（widget-snapshot.json）に書かない。ウィジェットの再読み込みを求めない。
- 読み始めない、終えない、しおりを変えない、今の本を替えない、設定を変えない。
- 通信しない（アプリのコードは外部への HTTP 通信をしない。AC-103）。
- Live Activity の予約の見直しを、URL のせいで増やさない（見直しは「アプリが前に来たとき」の決まりで1回だけ動く。PRD 11 の冒頭）。
- 知らせ、alert、確認を出さない（読めない URL でもエラーを出さない）。

アプリが動いているときに URL が来たとき（仕様の決定 65。2026-10-20 に designer が決めた）
- シート、全画面の流れ（S-2、S-3、S-3a、S-3b、S-4）、確認（confirmationDialog）のどれかが開いていれば、画面を何も変えない（入れた字や読んだ本を消さない）。
- どれも開いていなければ、押し出した画面（S-6、S-7、S-10）を動きなしで閉じて S-1 にする。
- どちらでも、上の「保存を変えない」を守り、知らせ、確認、alert を出さない。
- 決定 65 は AC ではない。AC-40 のテストは、プロセスのない起動だけを使う。

## 4. 入口の印の決まり（AC-40）
- 読書が始まったとき（`idle` → `reading`。「読み始める」でも伏せても）、次の3つをすべて満たせば Session.entry を候補の値にする。満たさなければ `app` にする。
  - (a) 候補がある。
  - (b) 開いた時刻から読み始めの時刻までが 0秒以上 300秒以下（両端を含む）。
  - (c) 開いてから読み始めまでの間に、アプリが後ろに回っていない（scenePhase が .background になっていない）。
- 時刻はアプリの時計で測る。テストでは H4、H5 で差し替える時計。
  - 端末の時刻が戻って、差が負になったら `app`。
- 候補が消えるとき
  - アプリが後ろに回ったとき（.background）と、プロセスが終わったとき。
  - .inactive（通知センター、コントロールセンターなど）では消えない。
- 候補を変えるとき
  - 新しい入口の URL を受けたら、新しい候補で置き換える。
  - 入口でない URL（2 の 3）を受けても、候補は変えない。
- 候補は、読書を始めても消さない。
  - 300秒以内に、後ろに回らずにもう一度読み始めれば、その読書にも同じ印を付ける。
  - 理由：1分未満で終えて記録が残らなかった読書（AC-56）のあと、読み直したときに印を失わないため。
- Session.entry は、終えて残る Record.entry にそのまま写す（設計メモ 5）。記録を直す画面（S-7b）では変えない。
- 保存した印の値を読むとき、知らない値は `app` として扱う。
- 印は v1.0 では送らない（AC-103、裁定 10）。保存した値は H13 の `records[].entry` と H17 の `entry` で読む。

AC-40 の場合ごとの期待値（照らし合わせ）

| 場合 | 起動 | 読み始めまで | 後ろに回ったか | 印 |
|---|---|---|---|---|
| (1) | `yomuma://open?entry=lock_widget` | すぐ | いいえ | `lock_widget` |
| (2) | `yomuma://open?entry=small_widget` | すぐ | いいえ | `small_widget` |
| (3) | `yomuma://open?entry=live_activity` | すぐ | いいえ | `live_activity` |
| (4) | ホーム画面のアイコン | すぐ | いいえ | `app` |
| (5) | (1) の URL | ホーム画面に移ってから戻る | はい | `app` |
| (6) | (1) の URL | 299秒 | いいえ | `lock_widget` |
| (7) | (1) の URL | 301秒 | いいえ | `app` |
| 境目（AC にはない） | (1) の URL | 300秒 | いいえ | `lock_widget` |

## 5. 境界と脅威（設計メモ 7 の境界4）
- 端末のほかのアプリや Safari からも、この URL を開ける。
- iOS 27.0 のシミュレーターでは、外から開くとシステムが「“アプリ名” で開きますか?」（キャンセル／開く）を出した。「開く」を押すまで、アプリには届かなかった（6）。
- 偽の URL でできるのは、アプリを開くことと、入口の印を偽ることだけ。印は端末の中だけで、v1.0 は送らない。保存は変わらない（3）。
- だから受け入れる（設計メモ 7 の T の行）。
- 入っているかを調べられること（1 の悪い点2）も受け入れる（設計メモ 7 の I の行の (e)）。
  - 分かるのは「入っている」ことだけで、書名、一行、記録は出ない。
  - 登録をやめると、widgetURL で開けない恐れがあり（1）、H28 も OS の URL の道を通れない。
  - 見直す条件：G4-18 で、登録なしでも widgetURL で開けると分かったとき。そのときは、登録をテストの構成だけに残す案と比べる。
- 確かめ方
  - G2：reviewer が、URL を受ける処理から、保存、写し、再読み込み、通信の呼び出しがないことをコードで読む。
  - G3：verifier が、URL で起動する前とあとで次を見る。H13 のデータが同じ。H29 の要求が0件。H22 の再読み込みの要求のうち、`launch` のほかの出どころが0（7-4b で直した）。
    - 書誌は端末内の DB だけで引く（ADR 0004）ので、H29 はいつも0件のはず。前の版にあった「書誌の順番待ちの本がない」の Given は要らなくなった。
    - Live Activity の要求（H23）は、出どころ `foregroundReconcile` か `launchReconcile` のものだけで、URL のせいの出どころはない（contracts/test-hooks.md の H23）。
    - アプリは起動のたびに写しを書く（contracts/widget-snapshot.schema.json）ので、プロセスのない起動では、出どころ `launch` の1回が残る。これは URL のせいではない。
    - 出どころの名前と数え方は contracts/test-hooks.md の H22。

## 6. spike で確かめたこと（2026-10-20）
- 環境：Xcode 27.1、iOS 27.0 のシミュレーター（iPhone 17 Pro）。spike はリポジトリの外で行い、端末は最後に消した。
- 読み方：2 の表の11件を、ReadingCore と同じ関数で読んだ。
- 拡張が付ける URL：`EntryURL.url(.lockWidget)` は `yomuma://open?entry=lock_widget`、`.smallWidget` は `yomuma://open?entry=small_widget`。
- `xcrun simctl openurl <端末> 'yomuma://open?entry=lock_widget'` は exit 0 だった。
  - ただし、システムの確認（“SpikeApp” で開きますか?）が出たまま止まり、アプリに届かなかった（スクリーンショットで確かめた）。
  - UI テストで springboard の「開く」を押すと、アプリの onOpenURL に `yomuma://open?entry=unknown` が届いた。読みは「なし（`app`）」だった。
- Apple の文書
  - https://developer.apple.com/documentation/widgetkit/linking-to-specific-app-scenes-from-your-widget-or-live-activity ：「When the widget or Live Activity receives an interaction, the system activates the containing app and passes the URL to onOpenURL(perform:), application(_:open:options:), …」。スキームの登録には触れていない。
  - https://developer.apple.com/documentation/swiftui/view/widgeturl(_:) ：「Widgets support one widgetURL modifier in their view hierarchy. If multiple views have widgetURL modifiers, the behavior is undefined.」
- 未確認（G4-18 で Takuma が見る）
  - 本物のウィジェットを押したときに、確認が出ずに開くこと。
  - 登録しなくても開くか。
- H28（7-4a で決めた。形は contracts/test-hooks.md の H28 を正とする）
  - `simctl openurl` と Safari の道では確認が出る。
  - H28 は (a) の `XCUIApplication.open(_:)` にした。7-4a の spike 1 で、`app.terminate()` のあとに呼ぶと確認は出ず、onOpenURL に URL が届いた（ADR 0005）。
  - 確認が出たときは (b) の springboard の「開く」に切り替える。(c) のテストの構成だけの引数は、OS の URL の道を通らないので使わない。
