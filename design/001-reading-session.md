# デザイン仕様 001-reading-session：読んだ時間とページを残して、続きから読む

- 対象の PRD：docs/prd/001-reading-session.md（G0 承認済み。docs/approvals/001-reading-session-G0.md）
- 調査：design/001-reading-session-research.md（コミット f8ae3e8。この仕様より先にコミット済み）
- トークン：design/tokens.md（色、文字、余白。この仕様はトークンの名前だけを使う）
- 書いた役：designer　日付：2026-10-21
- 図：design/001-reading-session/screens.md（文字で描いた画面の図）
- 原則の番号 B-1〜B-6 は .claude/skills/craft-designer/SKILL.md にある。R-n は調査の 8 の番号。
- 方向性は調査の 7 で選んだ案A「しおりと時計」。性格語は「静か」「確か」「すぐ」「おだやか」（調査の 5）。差をつける点は、差1「しおりの往復」と差2「読む間、画面は退く」（調査の 6）。
- HIG は 2026-10-21 に developer.apple.com で各ページの本文（.md）を開いて確かめた。開いたページは 8 の最後に並べた。

## 1. 画面の流れ

### 画面の一覧
| ID | 画面 | 出し方 |
|---|---|---|
| S1 | ホーム | NavigationStack の根 |
| S2 | 本を追加 | S1 から sheet |
| S3 | 本の詳細 | S1 から push |
| S4 | 読書中 | S1 か S3 から push |
| S5 | 読書を終える | S4 の上に sheet |
| S6 | 記録を消す確認 | S3 の confirmationDialog |
| S7 | 記録を消せなかった知らせ | S3 の alert |

### 流れ
```
起動
 ├─ reading か paused の読書が残っている → S1 の上に S4 を積んで開く
 ├─ finishing の読書が残っている       → S1 の上に S4 を積み、その上に S5 を開く
 └─ それ以外                            → S1

S1 ホーム
 ├─ 本が0冊：空の状態の「本を追加」(library.addBook) ──────→ S2
 ├─ 本が1冊以上：右上の「＋」(library.addBook) ────────────→ S2
 ├─ 本の行をタップ ─────────────────────────────────────→ S3（その本）
 ├─ 下端の主操作（idle）「題名／72ページから読む」(home.startReading) → 前の本で読み始め、S4
 └─ 下端の主操作（reading か paused）「題名／読書に戻る」(home.resumeReading) → S4

S2 本を追加（sheet）
 ├─ 「追加」(book.save) が成功 → sheet を閉じ、追加した本の S3 を push（スタック：S1 > S3）
 ├─ 「追加」が失敗           → S2 のまま。先頭にエラーの区画（error.saveFailed、error.retry）
 └─ 「キャンセル」(book.add.cancel) → 入力が空なら閉じる。入力があれば確認（book.add.discard.confirm）してから閉じる

S3 本の詳細
 ├─ idle：主操作「72ページから読む」(book.startReading) → この本で読み始め、S4 を push（S1 > S3 > S4）
 ├─ この本が読書中：主操作「読書に戻る」(book.resumeReading) → S4
 ├─ 別の本が読書中：book.startReading は無効。すぐ上に理由の文（book.start.busy）
 └─ 記録の行の「削除」（スワイプか、「編集」から）→ S6 →「記録を消す」→ 成功：行が消える／失敗：S7

S4 読書中
 ├─ 「一時停止」(reading.pause) ⇄ 「再開」(reading.resume)：S4 のまま
 ├─ 戻る（システムの戻るボタン、画面の端からのスワイプ）→ 前の画面。読書は続く
 ├─ 「終える」(reading.finish)、経過が60秒以上 → S5（finishing）
 └─ 「終える」、経過が60秒未満 → 記録せず idle。S4 をその本の S3 に置き換え、S3 の先頭に知らせ（session.finish.tooShort）

S5 読書を終える（sheet）
 ├─ 「保存」(session.finish.save) が成功 → sheet を閉じ、S4 をその本の S3 に置き換える。新しい記録は一覧の先頭
 ├─ 「保存」が失敗 → S5 のまま。先頭にエラーの区画（error.saveFailed、error.retry）
 └─ 「キャンセル」(session.finish.cancel) か、シートを下へスワイプ → sheet を閉じ、S4（reading）
```

置き換えの決まり：S4 から S3 へ移るとき、スタックに同じ本の S3 があればそこまで戻る（S1 > S3 > S4 → S1 > S3）。なければ S4 を S3 に置き換える（S1 > S4 → S1 > S3）。どちらも戻るボタンで S1 に戻れる。

### 指示書と PRD が設計に委ねた点の決定
- AC-4 の道：本が0冊の S1 →（1）library.addBook → S2。題名の欄 book.add.title には開いた時点で入力の焦点があり、キーボードが出ている（題名の入力に含める）→ 題名「坊っちゃん」→（2）book.save → S3 →（3）book.startReading → S4（reading）。タップは3回。
- 本を保存した後の画面（AC-22 の「保存の後の画面」）：追加した本の S3。シートとアラートは0個。理由：PRD 10 の「前の本」は最後に記録を保存した本なので、2冊目からは S1 の主操作が追加した本にならない（AC-25）。追加した本で読み始めるまでを1回のタップにするには、その本の画面に出るのがいちばん短い。
- 終える入力の形：S4 の上の sheet（モーダル）。S5 が出ている間は、S1 と別の本の S3 に行けない。だから AC-17 と AC-27 の finishing の通りは「S5 のキャンセル（session.finish.cancel）で reading に戻してから」になる（承認の記録 docs/approvals/001-reading-session-G0.md の裁定）。このとき状態は reading なので、Then の値は reading の通りと同じになる。
- 「やめる」の出口の形：S5 のツールバーの左（ToolbarItemPlacement.cancellationAction）の「キャンセル」。ButtonRole.cancel、識別子 session.finish.cancel。シートを下へスワイプしても同じ動きにする。どちらも確認を出さない（AC-46 の When が1回の操作のため）。PRD の言葉「やめる」は、画面ではシステムの言い方「キャンセル」で出す。
- やめた後に残す値：今のページは残さない（PRD 10、AC-46）。分の欄も残さない。次に「終える」を押したときは、その時点の経過の分数を入れ直す。理由：やめた後も読書は進むので、前の値を残すと実際より短い記録に気づかずに保存させてしまう（性格語「確か」）。PRD に AC がないので、報告の「未解決」で pdm に AC を頼む。
- 読書を保存した後の画面：その本の S3。新しい記録が一覧の先頭に出て、合計時間と最後のページが変わる。VoiceOver には session.saved.announcement（「24分を記録しました。」）を1回知らせる。祝う表示は出さない（調査の 5 の「淡々」、R-22）。
- 計測の start_source（PRD 15）：S1 の主操作から始めたら home、S3 から始めたら book_detail、S2 で追加した直後の S3 から（その S3 を離れる前に）始めたら after_add。計測の作りは tech-lead が決める。

## 2. 受け入れ条件と画面の対応
識別子は 6、文言のキーは 7。

| AC | 画面 | 操作 |
|---|---|---|
| AC-1 | S1（本が0冊） | 起動すると、空の状態（library.empty.title、library.empty.message）と「本を追加」（library.addBook）が1つだけ出る。右上の「＋」、今週の合計、下端の主操作は出さない。home.startReading と book.startReading は0個 |
| AC-2 | S2 → S3、S1 | S2 の book.add.title に「坊っちゃん」、総ページ数は空のまま book.save → S3。book.lastPage の value が「0」、book.totalPages は0個。戻ると S1 の本の行は1つ、home.bookCount は「1冊」 |
| AC-3 | S2 | 題名が空か空白だけ（半角、全角 U+3000、改行、タブとその組み合わせ）の間、book.save は無効。誤りの文は出さない（必須の欄で、ボタンが押せないことで伝える） |
| AC-4 | S1 → S2 → S3 → S4 | 1 の「AC-4 の道」。タップは library.addBook、book.save、book.startReading の3回。S4 の reading.title は「坊っちゃん」、状態は reading |
| AC-5 | S1 → S4 | 主操作 home.startReading を1回 → S4。reading.elapsed は 0:00 から毎秒進む。テストは label で読む（7 の経過の表：0:00 は「0分0秒」） |
| AC-6 | S4 → S5 → S3 | reading.pause →（60秒）→ reading.resume →（60秒）→ reading.finish → S5 の session.finish.save → S3 の新しい記録の行の session.row.minutes が「2分」 |
| AC-7 | S4 | 裏に回して戻っても S4 のまま。経過は開始の時刻から計算し直して出す |
| AC-8 | 起動 → S4 | reading が残っていれば、S1 の上に S4 を積んで開く。状態は reading |
| AC-9 | S4 → S5 → S3 | session.finish.page に 72 → 保存 → S3：新しい行の session.row.page「32ページ」、book.lastPage「72」、book.progress「24%」 |
| AC-10 | S5 → S3 | ページを空のまま保存 → S3：book.sessionCount「記録 2件」、新しい行に session.row.page がない、book.lastPage「40」、状態 idle |
| AC-11 | S5 | 301 を入れた時点で、欄の下に session.finish.pageOutOfRange（「0から300までの数字で入れてください。」）。session.finish.save は無効。S5 のまま（finishing） |
| AC-12 | S5 → S3 | session.finish.minutes は「180」で開く → 45 に直して保存 → S3：新しい行の session.row.minutes「45分」、book.totalTime が45分増える |
| AC-13 | S4 → S3 | 経過59秒で reading.finish → S5 を出さずに、その本の S3 へ。先頭に session.finish.tooShort。状態 idle |
| AC-14 | S3 | book.totalTime「60分」、book.sessionCount「記録 3件」、book.lastPage「72」、book.progress「24%」 |
| AC-15 | S1 | home.weekTotal の value「60分」 |
| AC-16 | S3 → S6 → S3 | 30分の行を左へスワイプ →「削除」（session.row.delete）→ S6 の「記録を消す」（session.delete.confirm）→ 行が消え、「記録 1件」、book.totalTime「20分」、book.lastPage「72」 |
| AC-17 | S4 → S1 → S3 | reading と paused：S4 の戻る → S1 の「こころ」の行 → S3。book.startReading は無効で、すぐ上に book.start.busy。finishing：S5 のキャンセルで reading に戻してから同じ道（承認の記録の裁定） |
| AC-18 | 起動 → S1、S3 | S1 の home.bookCount「2冊」。各 S3 の book.totalTime（「60分」「40分」）と book.sessionCount（3件と2件で計5件） |
| AC-19 | S5 | 保存に失敗 → S5 の先頭にエラーの区画（error.saveFailed、error.saveFailed.session、error.retry）。session.finish.minutes の value は「10」のまま、ページの欄も入れた値のまま。S5 のまま（finishing） |
| AC-20 | S2 → S3 → S4 → S5 → S3 | 通常の道。保存の後は S3 に出るので、各手順の後にシートとアラートは0個（S5 は保存で閉じる）。計測の結果は画面に何も出さない。error. で始まる識別子は失敗のときだけ出る |
| AC-21 | 全画面 | 権限を求める画面も操作もない。7 の権限の説明文は「なし」 |
| AC-22 | S2 → S3、S1 | 21冊目を追加 → S3（シートとアラートは0個）→ 戻ると S1 の home.bookCount「21冊」 |
| AC-23 | S2、S4、S5 | 画面の道は AC-9 と同じ。題名とページを画面の外に出す要素はない（計測の中身は tech-lead の契約） |
| AC-24 | S4、S5 | 読書を2回終えて保存する道（AC-6 と同じ）。週の60分に届いても画面には何も出さない（祝わない。調査の 6） |
| AC-25 | S1 → S4 | 主操作の1行目は「こころ」（最後に記録を保存した本）→ 1回で S4 |
| AC-26 | S1 → S4 | 記録が0件なので、主操作の1行目は最後に追加した「こころ」、2行目は「読み始める」→ 1回で S4 |
| AC-27 | S1 | reading と paused：S1 の主操作は home.resumeReading（label が「坊っちゃん、」で始まる）。home.startReading は0個。finishing：S5 のキャンセルで reading に戻し、S4 の戻るで S1 を出す（承認の記録の裁定） |
| AC-28 | S3 | book.lastPage「40」。book.progress と book.totalPages は0個 |
| AC-29 | S5 → S3 | 50 を入れて保存 → 新しい行の session.row.page「0ページ」、book.lastPage「50」、book.progress「16%」 |
| AC-30 | S5 | 分の欄を 0 にする（181 も同じ）→ session.finish.minutesOutOfRange（「1から180までの数字で入れてください。」）。保存は無効。S5 のまま（finishing） |
| AC-31 | S2 | 総ページ数に 0 か 10000 → 欄の下に book.add.totalPagesOutOfRange、book.save は無効。1 と 9999 では誤りの文が消え、book.save は有効 |
| AC-32 | S5 → S3 | 総ページ数が未設定：10000 → session.finish.pageOutOfRange（「0から9999までの数字で入れてください。」）、保存は無効。9999 → 保存 → S3 の book.lastPage「9999」、状態 idle |
| AC-33 | 起動 → S4 | paused なら S4 を一時停止の形で開く。reading.elapsed は「5:00」のまま（label「5分0秒」）、reading.state「一時停止中」、ボタンは reading.resume |
| AC-34 | 起動 → S4 ＋ S5 | finishing なら S4 の上に S5 を開く。session.finish.minutes「10」、session.finish.page は空 |
| AC-35 | S5 → S3 | error.retry を1回 → 成功 → S5 を閉じて S3：「記録 3件」、状態 idle、error.saveFailed は0個 |
| AC-36 | S1 | 本が1冊以上で今週の記録が0件：home.weekTotal の value「0分」。責める文や「まだ」の文は出さない |
| AC-37 | S3 | book.totalTime「0分」、book.sessionCount「記録 0件」、book.progress「0%」。一覧の代わりに book.sessions.empty。book.startReading は有効 |
| AC-38 | S3 → S6 → S3 | S6 で「キャンセル」（session.delete.cancel）→ 何も変わらない。「記録 2件」、book.totalTime「50分」 |
| AC-39 | 全画面（7 の表） | 7 のすべてのキーに ja と en がある |
| AC-40 | S4 | reading.elapsed の accessibilityLabel は ja「12分30秒」、en「12 minutes, 30 seconds」（7 の経過の表） |
| AC-41 | S4 | 時計が開始より前に戻ったら、経過は 0:00（label「0分0秒」）。負の値は出さない。エラーも出さない |
| AC-42 | S2 | 保存に失敗 → S2 の先頭にエラーの区画（error.saveFailed、error.saveFailed.book、error.retry）。book.add.title の value は「こころ」のまま。S2 は閉じない |
| AC-43 | S3 → S6 → S7 | S6 で消す → 保存に失敗 → S7（題 error.saveFailed、本文 error.saveFailed.delete、「OK」）。行は残り、「記録 2件」、book.totalTime「50分」 |
| AC-44 | S1 | home.weekTotal の value「20分」 |
| AC-45 | S4 → S5 → S3 | reading.finish を押した時刻で経過を止める。S5 にいた60秒は数えない。新しい行「2分」 |
| AC-46 | S5 → S4 → S5 | 72 を入れた S5 で session.finish.cancel → S4（reading、経過 10:00）→ 続けて reading.finish → S5 の session.finish.page は空、session.finish.minutes はその時点の経過の分数 |

## 3. 画面の仕事と主操作、標準部品
主操作は1画面に1つで、アクセントの塗り（color.accent）を使うのはその1つだけ。

| 画面 | 仕事（1文） | 主操作 | 使う標準部品 | 標準から外れる所（本来の部品、理由、対応） |
|---|---|---|---|---|
| S1 ホーム | 前の本の続きを1回で読み始め、今週読んだ時間と本の一覧を見る | 下端のボタン home.startReading（読書中は home.resumeReading） | NavigationStack、List（insetGrouped）、Section、LabeledContent、NavigationLink、toolbar（ToolbarItem の Button、SF Symbol plus）、ContentUnavailableView（0冊、読み込みの失敗）、Button（.borderedProminent、controlSize .large）、safeAreaInset(edge: .bottom)、redacted(reason: .placeholder)、ProgressView | 主操作の置き場所。本来の部品：ToolbarItem(placement: .bottomBar)。理由：ラベルが2行（前の本の題名と「72ページから読む」。差1）で、ツールバーの1行の項目に入らない。対応：中身は標準の Button と標準のスタイルなので、Dynamic Type、ダーク、コントラストを上げる設定、VoiceOver に追従する。帯の背景は不透明な color.background.grouped で、透明度を下げる設定でも見え方は変わらない。AX サイズでは帯をやめ、リストの先頭の行に移す（9） |
| S2 本を追加 | 題名だけで本を登録する | 追加（book.save） | sheet、NavigationStack、Form、Section（header、footer）、TextField（総ページ数は .keyboardType(.numberPad)）、toolbar（.cancellationAction、.confirmationAction）、FocusState（開いたら題名に焦点）、interactiveDismissDisabled（入力があるとき）、confirmationDialog | なし |
| S3 本の詳細 | その本の合計と記録を確かめ、その本で読み始める | 下端のボタン book.startReading（この本が読書中なら book.resumeReading） | List（insetGrouped）、Section、LabeledContent、EditButton と onDelete、swipeActions（Button role .destructive、SF Symbol trash）、confirmationDialog、alert、safeAreaInset の Button（.borderedProminent）、redacted | (1) 主操作の置き場所は S1 と同じ（本来の部品と理由も S1 と同じ。同じ働きの主操作を同じ場所に置く）。(2) 題名を、ナビゲーションバーの大きい見出しでなく、リストの先頭の行に .title2 で置く。本来の部品：navigationTitle の大きい見出し。理由：大きい見出しは長い題名を1行で切るので、全部を出せない（R-12「Keep text truncation to a minimum」）。対応：その行に accessibilityAddTraits(.isHeader)。ナビゲーションバーにも同じ題名を inline で置く（戻る先の名前と、スクロールした後の画面の名前のため） |
| S4 読書中 | 読んでいる間の経過を確かめ、一時停止するか終える | 終える（reading.finish） | NavigationStack の push 先、Text（経過は .largeTitle と monospacedDigit）、TimelineView（毎秒の書き直し）、Button（終えるは .borderedProminent、一時停止と再開は .bordered）、dynamicTypeSize の isAccessibilitySize と ViewThatFits による並びの切り替え、ScrollView（AX サイズのとき） | なし |
| S5 読書を終える | 今のページと読んだ時間を確かめて、記録に残す | 保存（session.finish.save） | sheet、NavigationStack、Form、Section（header、footer）、LabeledContent、TextField（.keyboardType(.numberPad)）、toolbar（.cancellationAction、.confirmationAction）、FocusState（開いたら今のページに焦点） | 分の入力に、選ぶ部品（Picker、Stepper）を使わず数字を打つ欄にする。本来の部品：HIG Entering data「When possible, offer choices instead of requiring text entry」の選ぶ部品。理由：AC-30 は 0 と 181 を入れて拒まれることを確かめるので、範囲を絞る部品では When を行えない（verifier r2 の AC-30）。180分を45分に直す（AC-12）のも打つほうが速い。対応：標準の TextField なので、VoiceOver で値を読み、直せる。範囲の外は欄のすぐ下に文で出す。今のページと総ページ数も同じ形にそろえる |
| S6 記録を消す確認 | 記録を消してよいかと、消すと何が変わるかを確かめる | 記録を消す（session.delete.confirm、role .destructive） | confirmationDialog（titleVisibility .visible、message あり） | なし |
| S7 記録を消せなかった知らせ | 記録を消せなかったことと、記録が残っていることを知らせる | OK | alert | なし |

## 4. 決定と根拠
| 決定 | 根拠（R-n） | 原則（HIG の URL か B-n） |
|---|---|---|
| D-1 読書中（S4）は push にし、全画面のモーダルにしない。戻るで S1 に戻っても読書は続く（AC-17、AC-27 の道） | R-3「Davies leaned on platform conventions」、R-6「Restore the previous state」 | HIG Modality「Present content modally only when there's a clear benefit.」https://developer.apple.com/design/human-interface-guidelines/modality 、B-1 |
| D-2 読書を終える入力（S5）は S4 の上の sheet。同時に出すモーダルは1つ | R-3「only the current step」 | HIG Sheets「A sheet helps people perform a scoped task that's closely related to their current context.」「Display only one sheet at a time from the main interface.」https://developer.apple.com/design/human-interface-guidelines/sheets |
| D-3 S5 の出口は左上の「キャンセル」と下へのスワイプ。どちらも確認なしで reading に戻る | R-1「Help people recover from mistakes.」 | HIG Sheets「The Cancel (or Close) button dismisses a sheet without saving any changes.」「Support swiping to dismiss a sheet.」（https://developer.apple.com/design/human-interface-guidelines/sheets） |
| D-4 キャンセルの後、今のページと分の欄は残さず、次は新しい経過の分数で入れ直す | R-1、R-7「Provide reasonable default settings」 | HIG Entering data「You can also prefill fields with reasonable default values」https://developer.apple.com/design/human-interface-guidelines/entering-data 、B-1 |
| D-5 本を追加した後は、追加した本の S3 に出る | R-3「How quickly can I get you back to preparing the meal」 | B-1 |
| D-6 読書を保存した後と、60秒未満で終えた後は、その本の S3 に出る。祝う表示は出さず、新しい行と合計の変化で返す。60秒未満の知らせは S3 の先頭の文にし、アラートにしない | R-1「Provide clear feedback.」、R-22、R-18 | HIG Alerts「Avoid using an alert merely to provide information.」https://developer.apple.com/design/human-interface-guidelines/alerts 、B-2 |
| D-7 S1 の主操作は、前の本の題名と「72ページから読む」を1つのボタンにする（差1 の「開く」）。ページが0なら「続きを読む」か「読み始める」 | R-2「making sure they aren't too literal or abstract」、R-14、R-21 | HIG Buttons「In general, use a button that has a prominent visual style for the most likely action in a view.」https://developer.apple.com/design/human-interface-guidelines/buttons 、B-1 |
| D-8 S1 と S3 の主操作は画面の下端に置き、片手の親指で届く場所にする | R-24、R-23 | HIG Accessibility（操作の的 44x44pt）https://developer.apple.com/design/human-interface-guidelines/accessibility 、B-3 |
| D-9 目立つ主操作は1画面に1つで、アクセントの塗りはその1つだけ | R-10「Refrain from adding color to the background of multiple controls.」 | B-2、B-5 |
| D-10 S2 を開いたら題名の欄に焦点を当て、キーボードを出す | R-7「immediately start interacting」 | HIG Entering data、B-1（https://developer.apple.com/design/human-interface-guidelines/entering-data） |
| D-11 S5 を開いたら今のページの欄に焦点を当て、数字のキーボード（numberPad）を出す。空のまま保存できる（差1 の「挟む」） | R-3「only the current step」、R-24 | HIG Virtual keyboards「Choose a keyboard that matches the type of content people are editing.」https://developer.apple.com/design/human-interface-guidelines/virtual-keyboards |
| D-12 分、今のページ、総ページ数は数字を打つ欄にし、選ぶ部品にしない（3 の逸脱）。分の欄には経過の分数を最初から入れる | R-7、R-24 | HIG Text fields「Use a number formatter to help with numeric data.」https://developer.apple.com/design/human-interface-guidelines/text-fields |
| D-13 入力は打つたびに確かめ、誤りは欄のすぐ下に文で出し、追加と保存のボタンを無効にする。入れた文字は消さない。数字以外を貼り付けたときも同じ（入力の決まりは 7） | R-8「display it as close to the problem as possible, avoid blame, and be clear about what someone can do to fix it」 | HIG Entering data「Dynamically validate field values.」、HIG Text fields「if the only legitimate value for a field is a string of digits, your app needs to alert people if they've entered characters other than digits」（https://developer.apple.com/design/human-interface-guidelines/entering-data、https://developer.apple.com/design/human-interface-guidelines/text-fields） |
| D-14 保存の失敗は、フォームの先頭にエラーの区画（何が起きたか、読書や入力が残っていること、「もう一度保存」）を出し、フォームを閉じない | R-8、R-1 | HIG Writing https://developer.apple.com/design/human-interface-guidelines/writing 、HIG Modality「help people avoid data loss」 |
| D-15 記録の削除の失敗は alert（S7）で知らせる。削除は確認のダイアログから始まり、消そうとした行の位置が決まらないので、近くに文を置けない | R-8 | HIG Alerts「an alert can tell people about a problem」（https://developer.apple.com/design/human-interface-guidelines/alerts） |
| D-16 記録を消すときは確認（S6）を出す。確認の文に、合計時間から引く分数と、最後のページが変わらないことを書く | R-1「Help people recover from mistakes.」 | HIG Action sheets「Use an action sheet — not an alert — to offer choices related to an intentional action.」「Make destructive choices visually prominent.」https://developer.apple.com/design/human-interface-guidelines/action-sheets |
| D-17 記録の削除は、スワイプのほかに、画面に見える「編集」（EditButton）からもできる | R-1 | HIG Accessibility「Offer alternatives to gestures.」、HIG Lists and tables「In iOS and iPadOS, people must enter an edit mode before they can select table items.」https://developer.apple.com/design/human-interface-guidelines/lists-and-tables |
| D-18 S2 に入力があるときは、スワイプで閉じさせず、キャンセルで「追加せずに閉じる」を確かめる | R-1 | HIG Sheets「If people have unsaved changes in the sheet when they begin swiping to dismiss it, use an action sheet to let them confirm their action.」（https://developer.apple.com/design/human-interface-guidelines/sheets） |
| D-19 本が0冊の S1 は ContentUnavailableView で、状態の説明と「本を追加」の1つだけ。説明の画面、設定、ログインを挟まない | R-7、R-5「nothing extraneous」、R-8「Provide clear next steps on any blank screens.」 | HIG Onboarding https://developer.apple.com/design/human-interface-guidelines/onboarding 、ContentUnavailableView https://developer.apple.com/documentation/swiftui/contentunavailableview |
| D-20 今週0件は「0分」と出すだけ。目標、連続日数、「まだ読めていません」の文を出さない | R-4「less about hard comparisons and more about progress」、R-22 | HIG Writing「Match your tone to the context.」、B-2（https://developer.apple.com/design/human-interface-guidelines/writing） |
| D-21 S4 に置くのは、題名、「72ページから」、経過、状態の文字、一時停止（再開）、終えるの6つだけ。合計、一覧、統計、色の面、動く飾りを置かない（差2） | R-3「displaying only the current step」、R-4「keep their focus on the counter rather than their screen」 | B-1、B-2 |
| D-22 経過は type.timer（.largeTitle と等幅の数字）。60分未満は m:ss、60分以上は h:mm:ss。数字が変わるときに動きを付けない | R-12、R-11 | HIG Typography https://developer.apple.com/design/human-interface-guidelines/typography 、HIG Motion「In apps, generally avoid adding motion to UI interactions that occur frequently.」https://developer.apple.com/design/human-interface-guidelines/motion 、B-4 |
| D-23 経過の VoiceOver の読み上げは「12分30秒」の形。毎秒は読み上げない（updatesFrequently の特性を付けず、知らせも出さない） | R-11 | HIG VoiceOver https://developer.apple.com/design/human-interface-guidelines/voiceover |
| D-24 一時停止中は、経過と状態の文字を color.text.secondary にし、「一時停止中」の文字とボタンの「再開」でも示す | R-10「Avoid relying solely on color」、R-1「Provide clear feedback.」 | HIG Accessibility「Convey information with more than color alone.」（https://developer.apple.com/design/human-interface-guidelines/accessibility） |
| D-25 起動したとき読書中が残っていれば、S4（finishing なら S4 と S5）をそのまま開く。アラートは出さない | R-6「Restore the previous state when your app restarts so people can continue where they left off.」 | HIG Launching https://developer.apple.com/design/human-interface-guidelines/launching 、HIG Alerts「Avoid showing an alert when your app starts.」 |
| D-26 アクセントは1色「しおりの色」（栗色）。値とコントラストは tokens.md | R-10、R-9、R-23 | HIG Color https://developer.apple.com/design/human-interface-guidelines/color 、B-5 |
| D-27 背景と文字はシステムの色。アプリ独自の外観の設定を置かない | R-9「Avoid offering an app-specific appearance setting.」「Prefer the system background colors.」 | HIG Dark Mode https://developer.apple.com/design/human-interface-guidelines/dark-mode |
| D-28 文字は text style だけ。大きさの段は1画面4つまで。書体は1つ | R-12「Minimize the number of typefaces you use」 | B-4、HIG Typography（https://developer.apple.com/design/human-interface-guidelines/typography） |
| D-29 Liquid Glass はシステムがバーとシートに付ける分だけ。内容の層と下端の主操作の帯には使わない | R-13「Don't use Liquid Glass in the content layer.」 | HIG Materials https://developer.apple.com/design/human-interface-guidelines/materials |
| D-30 S1 の見出しは「読書」。アプリ名にしない | R-3「leaned on platform conventions」 | HIG Toolbars「Don't title windows with your app name.」https://developer.apple.com/design/human-interface-guidelines/toolbars |
| D-31 本の一覧は、最後に記録を保存した時刻（記録がなければ追加した時刻）の新しい順。並べ替えと検索は置かない。前の本が先頭に来る | R-3「I spent a lot of time figuring out what to leave out」、R-2「deciding what not to include」 | B-2、HIG Lists and tables「Keep item text succinct」（https://developer.apple.com/design/human-interface-guidelines/lists-and-tables） |
| D-32 記録の行は、読み始めた時刻の新しい順。中身は日付と時刻、分、ページ（入れた記録だけ）の3つ。読書の速さや予測は出さない | R-1「Provide clear feedback.」、R-18 | B-1、HIG Lists and tables（https://developer.apple.com/design/human-interface-guidelines/lists-and-tables） |
| D-33 別の本が読書中なら、S3 の主操作を無効にし、すぐ上に理由と次の一手（その読書を終える）を文で出す。その本が読書中なら主操作を「読書に戻る」に変える | R-8「be clear about what someone can do to fix it」 | B-1 |
| D-34 文言は「です・ます」で短く、ボタンは動詞。感嘆符、「私たち」、「おっと」を使わず、責めない | R-8、R-26 | HIG Writing（https://developer.apple.com/design/human-interface-guidelines/writing） |
| D-35 数を含む文は String Catalog の複数形で書き、文字列をつなげない。題名などを入れる文は書式のキー（%@）で語順を言語ごとに決める | R-8 | HIG Writing、B-6（https://developer.apple.com/design/human-interface-guidelines/writing） |
| D-36 AX サイズで横並びを縦並びに変え、S1 と S3 の主操作の帯をリストの先頭に移す | R-11「enlarge text by at least 200 percent」、R-12 | HIG Typography「Consider adjusting your layout at large font sizes.」「keep primary elements toward the top of a view even when the font size is very large」（https://developer.apple.com/design/human-interface-guidelines/typography） |
| D-37 誤りの印は記号 exclamationmark.triangle を color.status.error で、文は color.text.primary。色だけで誤りを示さない | R-10、R-11 | HIG Accessibility「Convey information with more than color alone.」、HIG Alerts（exclamationmark.triangle を控えめに使う）（https://developer.apple.com/design/human-interface-guidelines/alerts、https://developer.apple.com/design/human-interface-guidelines/accessibility） |
| D-38 状態の名前（idle、reading、paused、finishing）は、画面の根の入れ物の識別子 session.state.<名前> でテストに渡す。目に見える状態は「読書中」「一時停止中」の文字で示す | R-1「Provide clear feedback.」 | B-1、HIG VoiceOver（入れ物は読み上げの対象にならない）（https://developer.apple.com/design/human-interface-guidelines/voiceover） |
| D-39 読み込みの間は形（redacted）を先に出し、「0件」「0分」と空の状態を出さない。1秒を超えたら ProgressView を足す | R-6「Launch instantly.」 | HIG Loading「Show something as soon as possible.」https://developer.apple.com/design/human-interface-guidelines/loading |
| D-40 権限を求める画面と説明の画面を置かない（求める権限がない） | R-5「no login, no cloud syncing, nothing extraneous」、R-7 | HIG Privacy「Request permission only when your app clearly needs access to the data or resource.」https://developer.apple.com/design/human-interface-guidelines/privacy |
| D-41 一時停止と再開は .bordered で文字は color.text.primary。終えると同じ大きさにし、形（塗りの有無）で主と従を分ける | R-10 | HIG Buttons「Use style — not size — to visually distinguish the preferred choice among multiple options.」（https://developer.apple.com/design/human-interface-guidelines/buttons） |
| D-42 長い題名は、S1 の行で3行、S1 の主操作で2行、S4 で3行まで出して末尾を「…」で切る。S3 では切らずに全部出す | R-12「Keep text truncation to a minimum as font size increases.」 | HIG Typography「Avoid truncating text in scrollable regions unless people can open a separate view to read the rest of the content.」（https://developer.apple.com/design/human-interface-guidelines/typography） |
| D-43 押せるものは、システムの部品の既定の大きさのまま使い、すべて 44x44pt 以上にする | R-11 | HIG Accessibility（iOS の既定 44x44pt）（https://developer.apple.com/design/human-interface-guidelines/accessibility） |

## 5. 画面ごとの状態
空とエラーには「何が起きたか」と「次の一手のボタン」を書いた。オフラインは全画面で同じ理由：001 の画面は通信を使わず、通信は計測の送信だけで、送れなくても画面に何も出さない（AC-20、PRD 12）。権限は全画面で同じ理由：001 は権限を1つも求めない（AC-21）。

| 画面 | 通常 | 空 | 読み込み中 | エラー | オフライン | 権限を断られたとき | 一部だけ読めたとき |
|---|---|---|---|---|---|---|---|
| S1 ホーム | 本が1冊以上。上から「今週」の行（home.weekTotal）、冊数の見出し（home.bookCount）、本の行（題名だけ。新しい順）。右上に「＋」。下端に主操作（idle は home.startReading、reading と paused は home.resumeReading） | 本が0冊：ContentUnavailableView（記号 books.vertical、library.empty.title、library.empty.message、ボタン library.addBook）。何が起きたか＝本がまだない、次の一手＝本を追加。「今週」、冊数、「＋」、主操作は出さない（AC-1）。本はあるが今週の記録が0件：home.weekTotal は「0分」（AC-36。これは通常の形のまま） | 最初の読み込みが終わるまで、「今週」の行と本の行3つを redacted の形で出す。値の代わりに「0分」「0冊」と空の状態は出さない。主操作は出さない。1秒を超えたら、形の上に ProgressView（ラベル common.loading）を足す（PRD 12 の線は1.0秒） | 保存先を開けない（読み込みの失敗）：ContentUnavailableView（記号 exclamationmark.triangle、error.loadFailed.title、error.loadFailed.message、ボタン error.loadFailed.retry「もう一度読み込む」）。何が起きたか＝読み込めなかった、記録は消していない。次の一手＝もう一度読み込む。PRD に AC がない（10 と報告の「未解決」） | 通常と同じ（上の理由） | なし（上の理由） | なし。本と記録は端末の中の1つの保存先から一度に読み、一部だけ届く経路がない。読めなければ「エラー」の列になる |
| S2 本を追加 | 題名の欄に焦点。総ページ数は任意。題名が入るまで「追加」は無効 | 開いた直後（両方の欄が空）：「追加」は無効。誤りの文は出さない（AC-3）。キャンセルは確認なしで閉じる | なし。読むデータがない。保存の間は「追加」を無効にし、二度押しで2冊できないようにする | (1) 総ページ数が範囲の外か数字でない：欄の下に book.add.totalPagesOutOfRange、「追加」は無効、入れた文字は残す（AC-31）。次の一手＝直す。(2) 保存の失敗：先頭にエラーの区画（error.saveFailed、error.saveFailed.book、ボタン error.retry「もう一度保存」）。題名と総ページ数は残す。S2 は閉じない（AC-42）。次の一手＝もう一度保存 | 通常と同じ（上の理由） | なし（上の理由） | なし。入力だけの画面で、読み込むものがない |
| S3 本の詳細 | 先頭に題名（book.title、全部出す）。次に値の行（最後のページ、進み具合と総ページ数は総ページ数があるときだけ、合計時間）。記録の見出し（book.sessionCount）と記録の行（新しい順）。下端に主操作（idle は book.startReading、この本が読書中なら book.resumeReading、別の本が読書中なら無効の book.startReading とすぐ上の book.start.busy）。60秒未満で終えた直後は、先頭に session.finish.tooShort の文 | 記録が0件：「記録 0件」の見出しの下に、一覧の代わりに book.sessions.empty の文。何が起きたか＝まだ記録がない、次の一手＝下端の「読み始める」（有効。AC-37）。合計時間は「0分」、総ページ数があれば進み具合は「0%」。「編集」は出さない | S1 と同じ考え：値の行と記録の行3つを redacted の形で出し、「0件」「0分」を出さない。1秒を超えたら ProgressView | (1) 記録の削除の失敗：S7（alert。題 error.saveFailed、本文 error.saveFailed.delete、ボタン「OK」）。行は残る（AC-43）。次の一手＝もう一度消す（本文に書く）。(2) 読み込みの失敗：S1 と同じ ContentUnavailableView | 通常と同じ（上の理由） | なし（上の理由） | なし（S1 と同じ理由） |
| S4 読書中 | reading：題名（reading.title）、「72ページから」（reading.fromPage。最後のページが0なら出さない）、経過（reading.elapsed、color.text.primary）、「読書中」（reading.state、color.accent）、「一時停止」と「終える」。paused：経過と状態の文字を color.text.secondary にし、「一時停止中」、ボタンは「再開」 | なし。本を決めてから入る画面で、空になる中身がない | なし。経過は開始の時刻から計算するので、開いた時点で値が出る（AC-5 の0.5秒）。起動して戻すときも同じ | 画面に出すエラーはない。端末の時計が開始より前に戻ったら経過は 0:00 にし、負の値もエラーも出さない（AC-41）。読み始め、一時停止、再開の保存に失敗したときの扱いは PRD に AC がない（報告の「未解決」で tech-lead に確かめる） | 通常と同じ（上の理由） | なし（上の理由） | なし。読書中の読書は1件だけで、一部だけ読む経路がない |
| S5 読書を終える | 先頭の見出しに題名（session.finish.book）。「今のページ」（焦点あり、空、placeholder は common.optional「任意」）とヒント（session.finish.page.hint）。「読んだ時間（分）」（経過の分数が入っている）とヒント（session.finish.minutes.hint）。値が正しい間は「保存」が有効 | 今のページが空：そのまま保存できる（AC-10）。ヒントで「入れずに保存もできます。」と伝える | なし。読むデータは開いた時点で決まっている。保存の間は「保存」を無効にし、二重の記録を作らない | (1) 今のページが範囲の外か数字でない：欄の下に session.finish.pageOutOfRange、「保存」は無効、finishing のまま（AC-11、AC-32）。(2) 分が範囲の外か数字でない：session.finish.minutesOutOfRange、同じ（AC-30）。(3) 保存の失敗：先頭にエラーの区画（error.saveFailed、error.saveFailed.session、ボタン error.retry「もう一度保存」）。ページと分は残す。終えた時刻で止めた経過も変えない（AC-19、AC-35）。次の一手＝もう一度保存か、キャンセルで読書に戻る | 通常と同じ（上の理由） | なし（上の理由） | なし。入力の画面で、読むのは読書中の1件だけ |
| S6 記録を消す確認 | 題 session.delete.title、本文 session.delete.message（引く分数と、最後のページは変わらないこと、元に戻せないこと）、「記録を消す」（destructive）、「キャンセル」 | なし。記録の行から開くので、対象は必ず1件ある | なし。読むものがない | 消すことに失敗したら S7 | 通常と同じ（上の理由） | なし（上の理由） | なし（対象は1件） |
| S7 記録を消せなかった知らせ | 題 error.saveFailed、本文 error.saveFailed.delete、「OK」 | なし（知らせだけ） | なし | これ自体がエラーの表示 | 通常と同じ（上の理由） | なし（上の理由） | なし（知らせだけ） |

### 長い文字、0件、多い件数、取り消せない操作
- 長い題名（PRD は長さの上限を決めていない）：S1 の本の行は3行、S1 の主操作の1行目は2行、S4 の題名は3行まで出し、末尾を「…」で切る。S3 の先頭の題名と、VoiceOver のラベルは全部を出す。S5 の見出しは2行まで。S3 のナビゲーションバーの題名はシステムどおり1行で切れる。題名の中の改行とタブは、表示では空白として1行に流す。
- 0件：本0冊は S1 の空の状態、今週0件は「0分」、記録0件は S3 の空の状態（上の表）。どれも責める文を出さない。
- 多い件数（PRD 12：本500冊、記録10,000件）：S1 と S3 は List の行を表示する分だけ作るので、件数で並びは変わらない。冊数と件数の見出しは「500冊」「記録 10,000件」と出す（分、冊、件は端末の地域の書式の桁区切り。ページの数は桁区切りなし。7 の決まり）。検索と並べ替えは置かない（PRD にない。報告の「未解決」に提案として書く）。
- 長い経過：60分以上は h:mm:ss（例 1:00:00、30:00:00）。AX5 で横に入らなければ、文字の大きさを最小 0.5 倍まで縮めて1行に収め、切らない。
- 取り消せない操作：記録を消すことだけ。必ず S6 で確かめる（AC-16、AC-38）。S6 の本文に、合計から引く分数、最後のページが変わらないこと、元に戻せないことを書く。本を消す操作は 001 にない。
- 取り消せる操作には確認を出さない：S5 のキャンセル（読書は残る）、一時停止と再開、S4 の戻る（読書は続く）。

## 6. 要素と識別子
決まり
- 文言を出す要素の accessibilityIdentifier は、その文言のキーと同じ名前にする（verifier の T10）。例：誤りの文は session.finish.pageOutOfRange。
- 値を出す行（S1 の今週、S3 の値の行）は1つの要素にまとめ、label は項目名、value は値の文字にする。テストは value を読む（T9）。
- 入力の欄（TextField）の value は欄の中の文字。label は欄の名前。
- 状態の名前（T8）：画面の根の入れ物（.accessibilityElement(children: .contain) を付けた NavigationStack の外側）の識別子を、状態に合わせて session.state.idle、session.state.reading、session.state.paused、session.state.finishing のどれか1つにする。S5 の根の入れ物にも session.state.finishing を付ける。入れ物なので VoiceOver は読まず、見た目も変わらない。テストは exists で見る（S5 が出ている間は2つ見つかることがある。どちらも finishing）。
- 経過の表示（T18 の経過の要素）：reading.elapsed の label は読み上げの形（7 の経過の表）。テストは label で経過を読む。見える文字（m:ss、h:mm:ss）と label は、7 の表のとおり1対1で対応する。value は付けない（付けると VoiceOver が「12:30」を時刻として読み上げるおそれがあるため）。
- 記録の行（T18 の新しい記録の行の見分け方）：行の入れ物の識別子は session.row.id.<記録の UUID を小文字にした文字>。行の中に session.row.date、session.row.minutes、session.row.page（ページを入れた記録だけ）がある。行は読み始めた時刻の新しい順に並ぶので、新しい記録は S3 で最初に見つかる「session.row.id.」で始まる要素。子の識別子（session.row.date など）は「session.row.id.」で始まらないので、前方一致で行だけを数えられる。
- 本の行：library.book.<本の UUID を小文字にした文字>。label は題名。
- 一覧の冊数（T18）：home.bookCount の label（「21冊」）を読む。画面の外の行は XCUITest に出ないことがあるので、行は数えない。
- 保存の後の画面（T18、AC-22）：S3。目印は book.title と、book.startReading か book.resumeReading のどちらか1つが押せる位置にあること（hittable）。
- システムが作る部品（confirmationDialog と alert のボタン、編集モードの削除ボタン、戻るボタン、EditButton）には、識別子が付かないことがある。付かないときは 7 の文字（ラベル）で探す。tech-lead が G1 で確かめる（報告の「未解決」）。

| 画面 | 要素 | accessibilityIdentifier | VoiceOver のラベル（と value） |
|---|---|---|---|
| 全画面 | 画面の根の入れ物 | session.state.idle / session.state.reading / session.state.paused / session.state.finishing | なし（入れ物。読み上げない） |
| S1 | 本を追加（右上の「＋」、本が1冊以上のとき） | library.addBook | 「本を追加」 |
| S1 | 本を追加（空の状態のボタン、本が0冊のとき） | library.addBook | 「本を追加」 |
| S1 | 空の状態の題 | library.empty.title | 「本がまだありません」（見出し） |
| S1 | 空の状態の文 | library.empty.message | 文のとおり |
| S1 | 空の状態の記号 books.vertical | なし | 読まない（飾り。accessibilityHidden） |
| S1 | 今週の合計の行 | home.weekTotal | label「今週」、value「60分」 |
| S1 | 冊数の見出し | home.bookCount | 「21冊」（見出し） |
| S1 | 本の行 | library.book.<UUID> | 題名（ボタン。システムの「詳細へ進む」の特性） |
| S1 | 主操作（idle） | home.startReading | 「坊っちゃん、72ページから読む」（キー home.primary.a11y。題名が先頭） |
| S1 | 主操作（reading か paused） | home.resumeReading | 「坊っちゃん、読書に戻る」か「坊っちゃん、一時停止中の読書に戻る」 |
| S1 | 読み込み中の形 | home.loading | 「読み込み中」（1秒を超えて ProgressView を出したとき） |
| S1、S3 | 読み込みの失敗の題、文、ボタン | error.loadFailed.title、error.loadFailed.message、error.loadFailed.retry | 文のとおり。ボタンは「もう一度読み込む」 |
| S2 | 題名の欄 | book.add.title | label「題名」、value は入れた文字（空のときは placeholder「必須」） |
| S2 | 総ページ数の欄 | book.add.totalPages | label「総ページ数」、value は入れた文字（空のときは placeholder「任意」） |
| S2 | 総ページ数のヒント | book.add.totalPagesHint | 文のとおり |
| S2 | 総ページ数の誤りの文 | book.add.totalPagesOutOfRange | 文のとおり（出たときに1回読み上げる） |
| S2 | キャンセル | book.add.cancel | 「キャンセル」 |
| S2 | 追加 | book.save | 「追加」（無効のときはシステムが「使用不可」を足す） |
| S2 | 追加せずに閉じる（確認のダイアログ） | book.add.discard.confirm | 「追加せずに閉じる」 |
| S2、S5 | エラーの区画の題 | error.saveFailed | 「変更を保存できませんでした」 |
| S2 | エラーの区画の文 | error.saveFailed.book | 文のとおり |
| S2、S5 | もう一度保存 | error.retry | 「もう一度保存」 |
| S3 | 先頭の題名 | book.title | 題名（見出し） |
| S3 | 60秒未満の知らせ | session.finish.tooShort | 文のとおり（出たときに1回読み上げる） |
| S3 | 最後のページの行 | book.lastPage | label「最後のページ」、value「72」 |
| S3 | 進み具合の行（総ページ数があるときだけ） | book.progress | label「進み具合」、value「24%」 |
| S3 | 総ページ数の行（あるときだけ） | book.totalPages | label「総ページ数」、value「300」 |
| S3 | 合計時間の行 | book.totalTime | label「合計時間」、value「60分」 |
| S3 | 記録の数の見出し | book.sessionCount | 「記録 3件」（見出し） |
| S3 | 記録が0件の文 | book.sessions.empty | 文のとおり |
| S3 | 記録の行（入れ物） | session.row.id.<UUID> | 入れ物。中の3つを順に読む |
| S3 | 記録の行の日付と時刻 | session.row.date | 「10月21日 21:30」（端末の書式） |
| S3 | 記録の行の分 | session.row.minutes | 「24分」 |
| S3 | 記録の行のページ（入れた記録だけ） | session.row.page | 「32ページ」 |
| S3 | 行のスワイプの削除 | session.row.delete | 「削除」 |
| S3 | 編集（記録が1件以上のとき） | book.edit | 「編集」（システム） |
| S3 | 主操作（idle） | book.startReading | 「72ページから読む」「続きを読む」「読み始める」のどれか |
| S3 | 主操作（この本が読書中） | book.resumeReading | 「読書に戻る」か「一時停止中の読書に戻る」 |
| S3 | 主操作が無効の理由（別の本が読書中） | book.start.busy | 文のとおり。主操作の直前に読む |
| S6 | 記録を消す | session.delete.confirm | 「記録を消す」 |
| S6 | キャンセル（AC-38 の「消さない」） | session.delete.cancel | 「キャンセル」 |
| S7 | 題、本文、OK | error.saveFailed、error.saveFailed.delete、なし | 文のとおり、「OK」 |
| S4 | 題名 | reading.title | 題名（見出し） |
| S4 | 始めたページ | reading.fromPage | 「72ページから」 |
| S4 | 経過 | reading.elapsed | 「12分30秒」（7 の経過の表。value なし） |
| S4 | 状態の文字 | reading.state | 「読書中」か「一時停止中」 |
| S4 | 一時停止 | reading.pause | 「一時停止」 |
| S4 | 再開 | reading.resume | 「再開」 |
| S4 | 終える | reading.finish | 「終える」 |
| S5 | キャンセル（PRD の「やめる」） | session.finish.cancel | 「キャンセル」 |
| S5 | 保存 | session.finish.save | 「保存」 |
| S5 | 題名の見出し | session.finish.book | 題名（見出し） |
| S5 | 今のページの欄 | session.finish.page | label「今のページ」、value は入れた文字 |
| S5 | 今のページのヒント | session.finish.page.hint | 文のとおり（キーは session.finish.page.hint か session.finish.page.hintFirst） |
| S5 | 今のページの誤りの文 | session.finish.pageOutOfRange | 文のとおり（出たときに1回読み上げる） |
| S5 | 読んだ時間の欄 | session.finish.minutes | label「読んだ時間（分）」、value は入れた文字（例「10」） |
| S5 | 読んだ時間のヒント | session.finish.minutes.hint | 文のとおり |
| S5 | 読んだ時間の誤りの文 | session.finish.minutesOutOfRange | 文のとおり（出たときに1回読み上げる） |
| S5 | エラーの区画の文 | error.saveFailed.session | 文のとおり |

PRD の仮の名前（library.addBook、book.save、home.startReading、home.resumeReading、book.startReading、book.progress、book.totalPages、home.weekTotal、session.row.page、error.retry、session.finish.cancel）は、すべてそのまま使った。足した名前は上の表のとおり。

## 7. 文言
決まり
- 文は「です・ます」で短く。ボタンは動詞。英語のボタンと題は title-style capitalization、文は sentence case。感嘆符、「私たち」「we」、「おっと」「oops」を使わない（R-8、調査の 5）。
- 文字列はつなげない。数は String Catalog の複数形（英語の one と other）を使う。日本語の複数形は other だけ。
- 数の書式：分、冊、件は端末の地域の書式（桁区切りあり。例 1,234分）。ページの数（最後のページ、総ページ数、読んだページ、入力の範囲の文の数）は桁区切りなし（例 9999。本のページ番号の書き方と、入力できる形にそろえる）。% はキー format.percent（ja と en ともに「24%」の形。値は整数で切り捨て。PRD 10）。日付と時刻は端末の書式（月と日、時と分。今年でなければ年も）で、形を固定しない。
- 日本語の行の折り返しはシステムに任せ、文の中に改行を入れない（禁則はシステムが守る）。
- 入力の決まり（D-13）：数字の欄は、前後の空白を除き、全角の数字は半角として読む。それ以外の文字（桁区切りの「,」、小数点、符号、文字）が1つでもあれば、範囲の外と同じ誤りの文を出す。欄の文字は消さず、直さない。桁がとても多い数字も範囲の外として扱う。

| キー | 日本語 | 英語 | 使う場所 |
|---|---|---|---|
| home.title | 読書 | Reading | S1 の見出し |
| library.addBook | 本を追加 | Add Book | S1 の「＋」のラベル、空の状態のボタン |
| library.empty.title | 本がまだありません | No Books Yet | S1 の空の状態 |
| library.empty.message | 読んでいる本の題名を入れると、すぐに読み始められます。 | Enter the title of a book you're reading, and you can start right away. | S1 の空の状態 |
| home.weekTotal.label | 今週 | This Week | S1 の今週の行の項目名 |
| format.minutes | %lld分 | one: %lld minute ／ other: %lld minutes | S1 の今週、S3 の合計時間、記録の行の分 |
| home.bookCount | %lld冊 | one: %lld book ／ other: %lld books | S1 の冊数の見出し |
| action.readFromPage | %lldページから読む | Read from Page %lld | S1 の主操作の2行目、S3 の主操作（最後のページが1以上） |
| action.continue | 続きを読む | Continue Reading | 同上（最後のページが0で、記録が1件以上） |
| action.start | 読み始める | Start Reading | 同上（最後のページが0で、記録が0件） |
| action.resume | 読書に戻る | Back to Reading | S1 と S3 の主操作（reading） |
| action.resumePaused | 一時停止中の読書に戻る | Back to Paused Reading | S1 と S3 の主操作（paused） |
| home.primary.a11y | %1$@、%2$@ | %1$@, %2$@ | S1 の主操作の VoiceOver のラベル（1つ目は題名、2つ目は上の action.*） |
| common.loading | 読み込み中 | Loading | S1、S3 の ProgressView |
| book.add.navTitle | 本を追加 | Add Book | S2 の題 |
| book.add.titleField | 題名 | Title | S2 の題名の欄の見出し（Section の header）と、欄の VoiceOver のラベル |
| book.add.totalPagesField | 総ページ数 | Total Pages | S2 の総ページ数の欄の見出しと、欄の VoiceOver のラベル |
| common.required | 必須 | Required | S2 の題名の欄の placeholder |
| common.optional | 任意 | Optional | S2 の総ページ数の欄と、S5 の今のページの欄の placeholder |
| book.add.totalPagesHint | 入れると、進み具合を％で出します。 | Add this to see your progress as a percentage. | S2 の総ページ数の下 |
| book.add.totalPagesOutOfRange | 1から9999までの数字で入れてください。 | Enter a number from 1 to 9999. | S2 の総ページ数の下（範囲の外か数字でないとき。ヒントと入れ替える） |
| book.save | 追加 | Add | S2 の確定のボタン |
| common.cancel | キャンセル | Cancel | S2 と S5 の左上、S6 の取り消し |
| book.add.discard.title | この本を追加せずに閉じますか？ | Close without adding this book? | S2 の確認のダイアログの題 |
| book.add.discard.confirm | 追加せずに閉じる | Close Without Adding | S2 の確認のダイアログ（destructive） |
| error.saveFailed | 変更を保存できませんでした | Couldn't Save Changes | S2 と S5 のエラーの区画の題、S7 の題 |
| error.saveFailed.book | 入れた題名はそのままです。もう一度保存してください。 | What you entered is still here. Try saving again. | S2 のエラーの区画 |
| error.saveFailed.session | 読書は消えていません。読んだ時間も変わっていません。もう一度保存してください。 | Your reading session is still here, and the time hasn't changed. Try saving again. | S5 のエラーの区画 |
| error.saveFailed.delete | 記録は消えていません。もう一度消してください。 | The session wasn't deleted. Try deleting it again. | S7 の本文 |
| error.retry | もう一度保存 | Save Again | S2 と S5 のエラーの区画のボタン |
| error.loadFailed.title | 本と記録を読み込めませんでした | Couldn't Load Your Books | S1、S3 の読み込みの失敗 |
| error.loadFailed.message | 端末の中の記録は消していません。もう一度読み込んでください。 | Nothing on this iPhone was deleted. Try loading again. | 同上 |
| error.loadFailed.retry | もう一度読み込む | Load Again | 同上のボタン |
| common.ok | OK | OK | S7 のボタン |
| book.stat.lastPage | 最後のページ | Last Page | S3 の値の行の項目名 |
| book.stat.progress | 進み具合 | Progress | S3 の値の行の項目名 |
| book.stat.totalPages | 総ページ数 | Total Pages | S3 の値の行の項目名 |
| book.stat.totalTime | 合計時間 | Total Time | S3 の値の行の項目名 |
| format.percent | %lld%% | %lld%% | S3 の進み具合の値（例 24%） |
| book.sessionCount | 記録 %lld件 | one: %lld session ／ other: %lld sessions | S3 の記録の見出し |
| book.sessions.empty | まだ記録はありません。読書を終えると、ここに残ります。 | No sessions yet. Finished sessions appear here. | S3 の記録が0件のとき |
| session.row.pages | %lldページ | one: %lld page ／ other: %lld pages | S3 の記録の行のページ |
| session.row.delete | 削除 | Delete | S3 の行のスワイプ |
| book.start.busy | 「%@」を読書中です。その読書を終えると、この本で読み始められます。 | You're reading “%@.” Finish that session to start this book. | S3 の主操作の上（別の本が読書中） |
| session.finish.tooShort | 1分未満だったので、記録しませんでした。 | That was under a minute, so it wasn't saved. | S3 の先頭（60秒未満で終えた直後） |
| session.saved.announcement | %lld分を記録しました。 | one: Saved %lld minute. ／ other: Saved %lld minutes. | 読書を保存して S3 に出たときの VoiceOver の知らせ（画面には出さない） |
| session.delete.title | この記録を消しますか？ | Delete this session? | S6 の題 |
| session.delete.message | 合計時間から%lld分を引きます。最後のページは変わりません。消した記録は元に戻せません。 | one: %lld minute will be subtracted from the total time. The last page won't change. You can't undo this. ／ other: %lld minutes will be subtracted from the total time. The last page won't change. You can't undo this. | S6 の本文 |
| session.delete.confirm | 記録を消す | Delete Session | S6 の destructive のボタン |
| reading.fromPage | %lldページから | From page %lld | S4 の題名の下 |
| reading.state.reading | 読書中 | Reading | S4 の状態の文字 |
| reading.state.paused | 一時停止中 | Paused | S4 の状態の文字 |
| reading.pause | 一時停止 | Pause | S4 のボタン |
| reading.resume | 再開 | Resume | S4 のボタン |
| reading.finish | 終える | Finish | S4 の主操作 |
| reading.elapsed.ms | %1$lld分%2$lld秒 | %1$lld minutes, %2$lld seconds（1つ目は one: %lld minute ／ other: %lld minutes、2つ目は one: %lld second ／ other: %lld seconds） | S4 の経過の VoiceOver のラベル（60分未満） |
| reading.elapsed.hms | %1$lld時間%2$lld分%3$lld秒 | %1$lld hours, %2$lld minutes, %3$lld seconds（それぞれ one: hour、minute、second ／ other: hours、minutes、seconds） | S4 の経過の VoiceOver のラベル（60分以上） |
| session.finish.navTitle | 読書を終える | Finish Reading | S5 の題 |
| session.finish.page.label | 今のページ | Current Page | S5 の欄の項目名 |
| session.finish.page.hint | 前回は%lldページでした。入れずに保存もできます。 | Last time you were on page %lld. You can also save without a page. | S5 の今のページの下（最後のページが1以上） |
| session.finish.page.hintFirst | 入れずに保存もできます。 | You can also save without a page. | S5 の今のページの下（最後のページが0） |
| session.finish.pageOutOfRange | 0から%lldまでの数字で入れてください。 | Enter a number from 0 to %lld. | S5 の今のページの下（%lld は総ページ数。未設定なら 9999。ヒントと入れ替える） |
| session.finish.minutes.label | 読んだ時間（分） | Minutes Read | S5 の欄の項目名 |
| session.finish.minutes.hint | 経過は%lld分です。読んでいない時間があれば、短く直せます。 | one: %lld minute has passed. If you weren't reading the whole time, enter less. ／ other: %lld minutes have passed. If you weren't reading the whole time, enter less. | S5 の読んだ時間の下 |
| session.finish.minutesOutOfRange | 1から%lldまでの数字で入れてください。 | Enter a number from 1 to %lld. | S5 の読んだ時間の下（%lld は経過の分数。ヒントと入れ替える） |
| session.finish.save | 保存 | Save | S5 の確定のボタン |

経過の表示と読み上げ（AC-5、AC-7、AC-8、AC-33、AC-40、AC-41、AC-46 の期待する文字）
見える文字は、60分未満は「分:秒」（分は0で埋めない、秒は2桁）、60分以上は「時:分:秒」（時は0で埋めない、分と秒は2桁）。区切りは ja と en ともにコロン。読み上げの文は、上の reading.elapsed.ms と reading.elapsed.hms のキーで作り、0の単位も省かない（形をいつも同じにして、テストで期待する文字を1つに決めるため）。システムの時間の整形（DateComponentsFormatter など）の出力には合わせない。実装はこの表の文字を出す。

| 経過の秒 | 見える文字 | ja の読み上げ（accessibilityLabel） | en の読み上げ（accessibilityLabel） |
|---|---|---|---|
| 0 | 0:00 | 0分0秒 | 0 minutes, 0 seconds |
| 1 | 0:01 | 0分1秒 | 0 minutes, 1 second |
| 61 | 1:01 | 1分1秒 | 1 minute, 1 second |
| 300 | 5:00 | 5分0秒 | 5 minutes, 0 seconds |
| 750 | 12:30 | 12分30秒 | 12 minutes, 30 seconds |
| 665 | 11:05 | 11分5秒 | 11 minutes, 5 seconds |
| 3599 | 59:59 | 59分59秒 | 59 minutes, 59 seconds |
| 3600 | 1:00:00 | 1時間0分0秒 | 1 hour, 0 minutes, 0 seconds |
| 3723 | 1:02:03 | 1時間2分3秒 | 1 hour, 2 minutes, 3 seconds |
| 7384 | 2:03:04 | 2時間3分4秒 | 2 hours, 3 minutes, 4 seconds |

権限を求める理由の説明文：なし。001 は権限を1つも求めない（AC-21、PRD 10）。Info.plist に UsageDescription のキーを足さない。求めるタイミングもない。

## 8. 見た目
- 使うトークン（色、文字、余白）：すべて design/tokens.md。
  - 色：color.background.screen（S4）、color.background.grouped（S1、S2、S3、S5、下端の主操作の帯）、color.background.row、color.text.primary、color.text.secondary、color.text.placeholder、color.separator、color.accent（主操作の塗り、シートの確定のボタン、「もう一度保存」、S4 の「読書中」、カーソル）、color.text.onAccent（主操作の文字）、color.status.error（誤りの記号だけ）、color.fill.secondaryButton（S4 の一時停止と再開）。
  - 文字と、画面ごとの大きさの段（4段まで。B-4）：
    - S1：type.navTitle（.largeTitle）、type.body と type.primaryTitle（17pt の段）、type.secondary（.subheadline。主操作の2行目）、type.note（.footnote。冊数の見出し）。4段。
    - S2：システムの inline の題、type.body（欄）、type.note（ヒントと誤り）。エラーの区画の題は .headline（17pt の段）。3段。
    - S3：type.bookHeading（.title2 の太字）、type.body（値と行の分とページ、主操作）、type.secondary（記録の日付、60秒未満の知らせ）、type.note（見出し、無効の理由）。4段。
    - S4：type.readingTitle（.title3）、type.secondary（「72ページから」、状態の文字）、type.timer（.largeTitle、等幅の数字）、type.body（ボタン）。4段。
    - S5：S2 と同じ3段。
  - 余白：S4 は、題名と「72ページから」の間 space.s、題名のまとまりと経過の間 space.l、経過と状態の間 space.s、経過のまとまりとボタンの間は最小 space.xl（残りは Spacer）、画面の左右と2つのボタンの間 space.m。S1 と S3 の下端の主操作は、左右 space.m、上 space.xs、下は安全領域まで。主操作の1行目と2行目の間 space.xxs。記録の行の分とページの間 space.xs。List と Form の中はシステムの既定。
  - そろえる縦の線（B-3）：S1、S2、S3、S5 は、リストの行の文字の左端（システムの既定の余白）を1本の線にし、下端の主操作の左右の端は画面の端から space.m。S4 は画面の中央の縦の線に、題名、「72ページから」、経過、状態をそろえ、ボタンは左右 space.m の間に2つ並べる。
- 新しく足すトークン（意味の名前と、ライト、ダーク、高コントラストの値）：color.accent（しおりの色）ライト #7A4427、ダーク #C99671、コントラストを上げる（ライト）#5E3219、（ダーク）#E3B994。color.text.onAccent ライト #FFFFFF、ダーク #000000、コントラストを上げる（ライト）#FFFFFF、（ダーク）#000000。理由は tokens.md の 1。ほかの色はシステムの色。
- 使う SF Symbols の名前（すべて developer.apple.com で名前を確かめた。文字と並べるときは Label で文字と同じ大きさと太さにする）：
  - plus：S1 の「本を追加」（HIG Icons の Standard icons の Add。https://developer.apple.com/design/human-interface-guidelines/icons ）
  - books.vertical：S1 の空の状態の記号（WWDC24「Elevate your tab and sidebar experience in iPadOS」のコードの Tab("Library", systemImage: "books.vertical")。https://developer.apple.com/videos/play/wwdc2024/10147/ ）
  - trash：S3 の行のスワイプの「削除」（HIG Icons の Delete）
  - exclamationmark.triangle：誤りの文とエラーの区画の印、読み込みの失敗の記号（HIG Alerts の本文「a caution symbol like `exclamationmark.triangle`」。控えめに使えという文に従い、誤りのときだけ出す）
  - システムが自分で出す記号（戻る、行の「＞」、iOS の版によってキャンセルと確定が xmark と checkmark で出る場合）は、名前を指定しない。xmark と checkmark は HIG Icons の Cancel と Done にある。
  - 塗りの記号（.fill）は使わない（選ぶ状態とタブがないため）。
- 性格語が表れている場所（語ごとに画面と要素）：
  - 静か：S4 に置くのは6つの要素だけで、色の面と動きがない（D-21、D-22）。読書を保存した後に祝う表示を出さない（D-6）。アクセントの塗りは1画面に1つ（D-9）。
  - 確か：S5 のヒントに経過の分数を出す（session.finish.minutes.hint）。保存の失敗の文で、読書と時間が残っていることを言う（error.saveFailed.session）。S6 の本文で、引く分数と最後のページが変わらないことを言う（session.delete.message）。起動したら読書中の画面に戻る（D-25）。
  - すぐ：S1 の主操作が1回で読み始めになる（home.startReading、AC-5）。S2 は開いた時点で題名の欄に焦点（D-10）。S5 は開いた時点で今のページの欄に数字のキーボード（D-11）。本を追加したらその本の S3 に出る（D-5）。
  - おだやか：今週0件は「0分」とだけ出す（AC-36、D-20）。60秒未満は責めない知らせ（session.finish.tooShort）。S5 はキャンセルで読書に戻れ、分を短く直せる（D-3、AC-12）。誤りの文は「〜で入れてください」の形で、責めない（D-13）。
- 差をつける点が表れている場所：
  - 差1「しおりの往復」：開く＝S1 の主操作（1行目に前の本の題名、2行目に「72ページから読む」）と、S4 の「72ページから」。挟む＝S5 を開いた時点で今のページの欄に焦点と数字のキーボード、ヒント「前回は40ページでした。入れずに保存もできます。」。挟んだページが、次に S1 を開いたときの主操作の2行目に出る。
  - 差2「読む間、画面は退く」：S4。6つの要素、大きな等幅の経過、アクセントは「終える」の塗りと「読書中」の文字だけ。
- 参考にした HIG のページ（URL。どれも 2026-10-21 に .md の本文を開いた）：
  - https://developer.apple.com/design/human-interface-guidelines/sheets
  - https://developer.apple.com/design/human-interface-guidelines/modality
  - https://developer.apple.com/design/human-interface-guidelines/text-fields
  - https://developer.apple.com/design/human-interface-guidelines/entering-data
  - https://developer.apple.com/design/human-interface-guidelines/virtual-keyboards
  - https://developer.apple.com/design/human-interface-guidelines/lists-and-tables
  - https://developer.apple.com/design/human-interface-guidelines/action-sheets
  - https://developer.apple.com/design/human-interface-guidelines/alerts
  - https://developer.apple.com/design/human-interface-guidelines/buttons
  - https://developer.apple.com/design/human-interface-guidelines/toolbars
  - https://developer.apple.com/design/human-interface-guidelines/icons
  - https://developer.apple.com/design/human-interface-guidelines/color
  - https://developer.apple.com/design/human-interface-guidelines/dark-mode
  - https://developer.apple.com/design/human-interface-guidelines/accessibility
  - https://developer.apple.com/design/human-interface-guidelines/voiceover
  - https://developer.apple.com/design/human-interface-guidelines/typography
  - https://developer.apple.com/design/human-interface-guidelines/motion
  - https://developer.apple.com/design/human-interface-guidelines/materials
  - https://developer.apple.com/design/human-interface-guidelines/loading
  - https://developer.apple.com/design/human-interface-guidelines/launching
  - https://developer.apple.com/design/human-interface-guidelines/onboarding
  - https://developer.apple.com/design/human-interface-guidelines/writing
  - https://developer.apple.com/design/human-interface-guidelines/privacy

## 9. アクセシビリティ
- いちばん大きい文字（AX5）で並びを変える場所（dynamicTypeSize が isAccessibilitySize のとき。HIG Typography「consider using a stacked layout where text appears above secondary items」）：
  - S1：下端の主操作の帯をやめ、リストの最初の行に主操作を置く（題名は2行まで、2行目は切らない）。今週の行は「今週」の下に「60分」を置く縦並び。本の行の題名は3行まで。
  - S2：欄は1行の幅いっぱいのまま。ヒントと誤りの文は折り返す。
  - S3：下端の主操作の帯をやめ、先頭の題名のすぐ下に主操作（とその上の無効の理由）を置く。値の行は、項目名の下に値を置く縦並び。記録の行は、日付、分、ページを縦に3行で並べる。
  - S4：全体を ScrollView に入れる。「一時停止」と「終える」の横並びを縦並びにし、上に「終える」、下に「一時停止」（HIG Alerts「at the top in a stack of buttons」）。経過は1行のまま、入らなければ最小 0.5 倍まで縮める。題名は3行まで。
  - S5：「今のページ」「読んだ時間（分）」の項目名の下に欄を置く縦並び。
  - S6、S7：システムの部品が並べ替える。
- 色だけで区別していないか：
  - 一時停止中は、文字「一時停止中」とボタン「再開」でも示す（D-24）。
  - 誤りは、記号 exclamationmark.triangle と文で示し、色は記号だけ（D-37）。
  - 主操作は塗りのほかに、ボタンの形と位置（下端）と動詞のラベルで分かる。無効の主操作は、システムの無効の見た目と、すぐ上の理由の文で示す。
  - 記録の行と本の行に色は使わない。
- 動きを減らす設定、透明度を下げる設定のとき：
  - 動きを減らす：アプリ独自の動きがない（経過の数字は動きなしで書き換える。祝う動きがない）。画面の切り替えはシステムの push と sheet で、システムが設定に合わせる。変えるものはない。
  - 透明度を下げる：内容の層に半透明の部品がなく、下端の主操作の帯も不透明な color.background.grouped。システムのバーとシートはシステムが不透明にする。変えるものはない。
  - コントラストを上げる：color.accent と color.text.onAccent は高コントラストの値に切り替わる（tokens.md）。ほかはシステムの色が切り替わる。
  - ダーク：システムの設定に従う（D-27）。S4 は寝る前の暗い部屋で使うので、背景は color.background.screen（ダークで黒）、明るい面はない。
- VoiceOver の読み上げ順（見た目の順。読み上げの順を入れ替えない）：
  - S1（本が1冊以上）：「読書」（見出し）→「本を追加」→「今週、60分」→「21冊」（見出し）→ 本の行（題名）を上から → 主操作「坊っちゃん、72ページから読む」。AX サイズでは主操作が「今週」の前に来る。
  - S1（本が0冊）：「読書」→「本がまだありません」（見出し）→ 文 →「本を追加」。記号は読まない。
  - S2：「キャンセル」→「本を追加」（見出し）→「追加」→（エラーの区画）→「題名」（見出し）→「題名」の欄 →「総ページ数」（見出し）→「総ページ数」の欄 → ヒントか誤りの文。
  - S3：戻る →（ナビゲーションバーの題名）→「編集」→ 題名（見出し）→（60秒未満の知らせ）→「最後のページ、72」→「進み具合、24%」→「総ページ数、300」→「合計時間、60分」→「記録 3件」（見出し）→ 記録の行（日付 → 分 → ページ）を新しい順に →（無効の理由）→ 主操作。記録の行のどの要素にいても、アクションに「削除」が出る（スワイプの代わり。出ないときは「編集」から消せる）。
  - S4：戻る → 題名（見出し）→「72ページから」→「12分30秒」→「読書中」→「一時停止」→「終える」。経過は、指を置いたときに今の値を1回読むだけ。毎秒の読み上げと知らせは出さない（PRD 12）。
  - S5：「キャンセル」→「読書を終える」（見出し）→「保存」→（エラーの区画）→ 題名（見出し）→「今のページ」の欄 → ヒントか誤りの文 →「読んだ時間（分）」の欄 → ヒントか誤りの文。
  - 知らせ（AccessibilityNotification.Announcement）：読書を保存して S3 に出たとき session.saved.announcement を1回。60秒未満で S3 に出たとき session.finish.tooShort を1回。誤りの文が出たとき、その文を1回（同じ誤りが続く間は繰り返さない）。保存に失敗したとき error.saveFailed を1回。
  - 飾りの記号（books.vertical）は読まない。ラベルは、画面に見える文字を先頭に入れる（S1 の主操作は題名から始まる）。
- 英語が長くなったとき（疑似言語 Double-Length で確かめる画面）：
  - S1 の主操作（「Back to Paused Reading」と長い題名。2行で切れずに収まるか）、今週の行。
  - S4 の2つのボタン（横並びで「Pause」「Finish」が倍になっても1行に収まるか。収まらなければ縦並びに切り替える。dynamicTypeSize だけでなく、幅が足りないときも縦並びにする＝ViewThatFits）。
  - S3 の値の行と主操作の無効の理由、S5 のヒントと誤りの文、S6 の本文、S2 のヒント。
  - 日本語より英語が2倍を超えて長くなる文言と置き場所：「読書」→「Reading」（S1 の大きい見出し。1行に収まる）、「再開」→「Resume」と「終える」→「Finish」（S4 のボタン。上の ViewThatFits）、「今週」→「This Week」（S1 の行の項目名。値と縦に並べ替えられる）、「任意」→「Optional」（S5 の欄の placeholder。欄の幅に収まる）。どれも折り返しか並べ替えで切れない。
- 押せる範囲：すべてシステムの部品の既定の大きさ（ツールバーのボタン、リストの行、controlSize .large のボタン、TextField の行）を使い、44x44pt 以上。小さくする指定をしない（D-43）。

コントラスト（独自の色を使う組。計算の式と背景の値は design/tokens.md の 5。システム色だけの組は「システム色」）
基準は、17pt 以下の文字が 4.5:1 以上、18pt 以上か太字の文字とアイコンや操作部品の枠が 3:1 以上。

| 前景（文字、アイコン、枠）と背景の組 | ライト | ダーク | コントラストを上げる |
|---|---|---|---|
| color.text.onAccent / color.accent（S1、S3 の主操作の文字、S4 の「終える」の文字） | 7.83:1（#FFFFFF / #7A4427） | 8.08:1（#000000 / #C99671） | ライト 10.79:1（#FFFFFF / #5E3219）、ダーク 11.63:1（#000000 / #E3B994） |
| color.accent / color.background.screen（S4 の「読書中」の文字） | 7.83:1（#7A4427 / #FFFFFF） | 8.08:1（#C99671 / #000000） | ライト 10.79:1、ダーク 11.63:1 |
| color.accent / color.background.grouped（下端の主操作の形の枠、S2 と S5 の確定のボタンの文字） | 7.01:1（#7A4427 / #F2F2F7） | 8.08:1（#C99671 / #000000） | ライト 9.08:1（#5E3219 / #EBEBF0）、ダーク 11.63:1 |
| color.accent / color.background.row（S2 と S5 の「もう一度保存」の文字） | 7.83:1（#7A4427 / #FFFFFF） | 6.55:1（#C99671 / #1C1C1E） | ライト 10.79:1、ダーク 8.58:1（#E3B994 / #242426） |
| color.status.error / color.background.grouped（欄の下の誤りの記号） | 3.20:1（#FF383C / #F2F2F7） | 6.12:1（#FF4245 / #000000） | ライト 3.83:1（#E9152D / #EBEBF0）、ダーク 7.15:1（#FF6165 / #000000） |
| color.status.error / color.background.row（エラーの区画の記号） | 3.57:1（#FF383C / #FFFFFF） | 4.96:1（#FF4245 / #1C1C1E） | ライト 4.56:1（#E9152D / #FFFFFF）、ダーク 5.28:1（#FF6165 / #242426） |
| color.text.primary、color.text.secondary、color.text.placeholder と各背景 | システム色 | システム色 | システム色 |
| color.fill.secondaryButton（S4 の一時停止と再開。tint は color.text.primary） | システム色 | システム色 | システム色 |

計算に使った道具：python3 で WCAG 2 の相対輝度の式（design-reviewer の手引きのコマンドと同じ式）。例 `python3 -c "…" FFFFFF 7A4427` → 7.83。全部の組のコマンドと出力は報告に書いた。誤りの記号（3:1 の基準）のライトは 3.20:1 で余裕が小さい。記号の意味は文でも伝えるので、色が見えなくても意味は失われない。

## 10. 決まっていないこと
どれも報告の「未解決」にも書いた。
1. PRD に AC がないこと（pdm に足してほしい）：(a) S5 のキャンセルの後、分の欄も残さず、次は新しい経過の分数で入れ直す。(b) S5 を下へスワイプしても session.finish.cancel と同じ。(c) 本を追加した後と、読書を保存した後と、60秒未満で終えた後は、その本の S3 に出る。(d) この本が読書中のとき、S3 の主操作は book.resumeReading。(e) S2 に入力があるとき、キャンセルで「追加せずに閉じる」を確かめる。(f) 読み込みの失敗の表示（error.loadFailed.*）。
2. tech-lead に確かめてほしいこと：(a) 画面の根の入れ物の識別子 session.state.* が XCUITest から見え、子の識別子を上書きしないか（spike）。(b) confirmationDialog と alert のボタン、編集モードの削除ボタンに識別子が付くか。iOS の版で confirmationDialog の「キャンセル」が出ない場合の「消さない」の操作。(c) 記録の行を入れ物（.contain）にしたとき、VoiceOver の行のアクションに「削除」が出るか。(d) 経過の読み上げをシステムの整形でなく String Catalog のキーで作ること（AC-40 の期待する文字を 7 の表で固定するため）。(e) 読み始め、一時停止、再開の保存に失敗したときの扱いと、読み込みの失敗が起こりうるか。読み込みに失敗しても保存先を消さないこと。(f) 数字の欄の決まり（全角の数字を受け付け、ほかの文字は誤りにする。とても長い数字で落ちない）。
3. verifier に伝えること：経過は reading.elapsed の label（読み上げの形）で読む。見える文字との対応は 7 の表。
4. Takuma に見てほしい見た目：しおりの色（栗色）。報告の「未解決」に推奨と反論を書いた。
5. 題名の長さの上限と、題名の中の改行の扱い（保存のときに空白に置き換えるか）は PRD にない。表示の決まりだけ 5 に書いた。
6. 本が500冊のときの検索は置かない（PRD にない）。必要なら次の機能の PRD で扱う提案にする。

## 確かめ（提出前に designer が印を付ける。design-reviewer はこれを信じずに確かめる）
- [x] 調査が先にあり、決定表のすべての行に R-n と原則がある（R-n は調査に実在する）（調査はコミット f8ae3e8。4 の D-1〜D-43 のすべての行に R-n と、HIG の URL か B-n がある）
- [x] 全画面に、仕事、主操作1つ、使う標準部品がある（3 の S1〜S7。標準から外れる所は S1、S3、S5 に本来の部品、理由、対応を書いた）
- [x] 全画面の7つの状態が埋まっている（5 の S1〜S7。該当しない所は「なし」と理由）
- [x] 押せる範囲が 44x44pt 以上。コントラストが基準を満たし、独自の色の組に数字が3通りある（9 と tokens.md の 5。コントラストを上げる設定はライトとダークの両方の値を書いた）
- [x] AX5 での並びと、VoiceOver の読み上げ順が書いてある（9）
- [x] 性格語と差をつける点が、画面のどこに表れているか書いてある（8）
- [x] 文言が日英そろい、テストで使う要素に accessibilityIdentifier がある（7 と 6。システムの部品で識別子が付かないものは 6 の決まりと 10 の 2(b)）
