# デザイン仕様 001-reading-session：読んだ時間とページを残して、続きから読む

- 対象の PRD：docs/prd/001-reading-session.md（G0 承認済み。docs/approvals/001-reading-session-G0.md）。PRD の G1 の追記（コミット d8bdc90。AC-47〜AC-55、10 の題名の長さと改行、やらないこと「本の検索」。承認の記録の追記で承認の範囲に入った）を反映した版
- 調査：design/001-reading-session-research.md（コミット f8ae3e8。この仕様より先にコミット済み）
- トークン：design/tokens.md（色、文字、余白。この仕様はトークンの名前だけを使う）
- 書いた役：designer　日付：2026-10-21
- 改訂：2026-10-21 PRD の G1 の追記に合わせて、1、2（AC-47〜AC-55）、3、4（D-44、D-45 を足した）、5、6、7（book.add.titleLimit を足した）、8、9、10 を直した
- 改訂（G1 r2）：2026-10-21 G1 r1 の判定（docs/reviews/001-reading-session-G1-design-reviewer-r1.md、docs/reviews/001-reading-session-G1-tech-lead-r1.md、裁定 docs/reviews/001-reading-session-G1-ruling.md）と、PRD の追記（コミット 77baf92。AC-56〜AC-61、10 の題名の上限の形、AC-38 の When の注記）に合わせて直した。主な変更：アクセントを塗り用と文字用に分けた（tokens.md）。17pt 以下の文字は color.text.primary だけにした。placeholder をやめた。「読書中」の文字をアクセントにしない。読み始め、一時停止、再開の保存の失敗（AC-56〜AC-61）。記録の行のページを「32ページ進んだ」にした。S5 のキーボードの上の「保存」。S3 から読書中の本へ行くボタン。S6 を alert にした。題名の上限の2つの形。CI で決める項目と代わりの案（10）
- 改訂（G1 の契約の後）：2026-10-21 PRD の追記（コミット 331aa80。AC-62〜AC-67：「終える」、終える入力をやめる、60秒未満で終える、の保存の失敗と再試行。18 の 6 は指揮役が推奨 A に決めた）と、tech-lead r2 の提案2（docs/reviews/001-reading-session-G1-tech-lead-r2.md）に合わせて、1、2、4（D-58〜D-60）、5、6、7（error.saveFailed.finish、error.saveFailed.cancel、error.retry.finish、error.retry.cancel）、9、10、確かめと、tokens.md の 1 と 5 の A1 の注を直した
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
| S6 | 記録を消す確認 | S3 の alert（G1 r2 で confirmationDialog から替えた。D-16） |
| S7 | 記録を消せなかった知らせ | S3 の alert |

### 流れ
```
起動
 ├─ 保存先を読み込めない               → S1 の読み込みの失敗（error.loadFailed.*）。S4 と S5 は積まない（AC-54）
 ├─ reading か paused の読書が残っている → S1 の上に S4 を積んで開く
 ├─ finishing の読書が残っている       → S1 の上に S4 を積み、その上に S5 を開く
 └─ それ以外                            → S1

S1 ホーム
 ├─ 読み込みの失敗：「もう一度読み込む」(error.loadFailed.retry) → 読み込み中の形 → 読めたら上の「起動」と同じに分かれる（AC-55）／また失敗したら同じ表示。「＋」は出さない（D-44）
 ├─ 本が0冊：空の状態の「本を追加」(library.addBook) ──────→ S2
 ├─ 本が1冊以上：右上の「＋」(library.addBook) ────────────→ S2
 ├─ 本の行をタップ ─────────────────────────────────────→ S3（その本）
 ├─ 下端の主操作（idle）「題名／72ページから読む」(home.startReading) → 前の本で読み始め、S4
 │    └─ 読み始めの保存に失敗 → S1 のまま（idle）。帯に error.saveFailed と error.saveFailed.start、主操作の場所に「題名／もう一度読み始める」(error.retry) → 通ったら S4（AC-56、AC-57。D-51）
 └─ 下端の主操作（reading か paused）「題名／読書に戻る」(home.resumeReading) → S4

S2 本を追加（sheet）
 ├─ 「追加」(book.save) が成功 → sheet を閉じ、追加した本の S3 を push（スタック：S1 > S3。AC-49）
 ├─ 「追加」が失敗           → S2 のまま。先頭にエラーの区画（error.saveFailed、error.retry）
 └─ 「キャンセル」(book.add.cancel) → 入力が空なら閉じる。入力があれば確認（book.add.discard.confirm）してから閉じる（AC-53）

S3 本の詳細
 ├─ idle：主操作「72ページから読む」(book.startReading) → この本で読み始め、S4 を push（S1 > S3 > S4）
 │    └─ 読み始めの保存に失敗 → S3 のまま（idle）。帯に error.saveFailed と error.saveFailed.start、主操作の場所に「もう一度読み始める」(error.retry) → 通ったら S4（AC-56、AC-57。D-51）
 ├─ この本が読書中：主操作「読書に戻る」(book.resumeReading) → S4（AC-52）
 ├─ 別の本が読書中：book.startReading は無効。その上に理由の文（book.start.busy）と「読書に戻る」(book.openActiveReading) → 読書中の本の S4 を push（S1 > S3 > S4。D-33）
 └─ 記録の行の「削除」（スワイプか、「編集」から）→ S6（alert）→「記録を消す」→ 成功：行が消える／失敗：S7。「キャンセル」→ 何も変えない

S4 読書中
 ├─ 「一時停止」(reading.pause) ⇄ 「再開」(reading.resume)：S4 のまま
 │    └─ 保存に失敗 → 状態は変えない（一時停止の失敗は reading のまま経過が進み、再開の失敗は paused のまま止まる）。状態の文字の下にエラーの区画（error.saveFailed と error.saveFailed.pause か error.saveFailed.resume）、左のボタンの場所に「もう一度一時停止」か「もう一度再開」(error.retry) → 通ったら paused か reading（AC-58〜AC-61。D-51）
 ├─ 戻る（システムの戻るボタン、画面の端からのスワイプ）→ 前の画面。読書は続く
 ├─ 「終える」(reading.finish)、経過が60秒以上 → S5（finishing）
 │    └─ 保存に失敗 → S4 のまま（reading か paused のまま。reading なら経過は進む）。状態の文字の下にエラーの区画（error.saveFailed と error.saveFailed.finish）、「終える」の場所に「もう一度終える」(error.retry) → 通ったら S5。経過は再試行の時刻で止める（AC-62、AC-63。D-58）
 └─ 「終える」、経過が60秒未満 → 記録せず idle。S4 をその本の S3 に置き換え、S3 の先頭に知らせ（session.finish.tooShort。AC-13、AC-51）
      └─ 保存（読書を消す保存）に失敗 → S4 のまま（読書は消さない。reading なら経過は進む）。上と同じ区画と「もう一度終える」(error.retry) → 再試行の時点の経過で分ける：60秒未満なら記録せず idle で S3（AC-66、AC-67）、60秒以上なら「終える」と同じに S5（PRD 18 の 6 の A。D-59）

S5 読書を終える（sheet）
 ├─ 「保存」(session.finish.save。キーボードの上の「保存」session.finish.saveKeyboard も同じ。D-53) が成功 → sheet を閉じ、S4 をその本の S3 に置き換える。新しい記録は一覧の先頭（AC-50）
 ├─ 「保存」が失敗 → S5 のまま。先頭にエラーの区画（error.saveFailed、error.retry）
 └─ 「キャンセル」(session.finish.cancel) か、シートを下へスワイプ → sheet を閉じ、S4（reading。AC-46、AC-48）
      └─ やめる保存に失敗 → S5 のまま（finishing。入れかけのページと分を残す）。先頭にエラーの区画（error.saveFailed、error.saveFailed.cancel、「もう一度読書に戻る」error.retry）→ 通ったら sheet を閉じ、S4（reading。S5 にいた時間は数えない。AC-64、AC-65）。下へのスワイプで失敗したときは、閉じたシートを同じ値で開き直し、同じ区画を出す（D-60）
```

置き換えの決まり：S4 から S3 へ移るとき、スタックに同じ本の S3 があればそこまで戻る（S1 > S3 > S4 → S1 > S3）。なければ S4 を S3 に置き換える（S1 > S4 → S1 > S3）。どちらも戻るボタンで S1 に戻れる。別の本の S3 から book.openActiveReading で開いた S4（S1 > S3「こころ」> S4「坊っちゃん」）は、終えると S4 を「坊っちゃん」の S3 に置き換え（S1 > S3「こころ」> S3「坊っちゃん」）、戻るで「こころ」の S3 に戻り、そこで読み始められる。

### 指示書と PRD が設計に委ねた点の決定
- AC-4 の道：本が0冊の S1 →（1）library.addBook → S2。題名の欄 book.add.title には開いた時点で入力の焦点があり、キーボードが出ている（題名の入力に含める）→ 題名「坊っちゃん」→（2）book.save → S3 →（3）book.startReading → S4（reading）。タップは3回。
- 本を保存した後の画面（AC-22 の「保存の後の画面」、AC-49）：追加した本の S3。シートとアラートは0個。理由：PRD 10 の「前の本」は最後に記録を保存した本なので、2冊目からは S1 の主操作が追加した本にならない（AC-25）。追加した本で読み始めるまでを1回のタップにするには、その本の画面に出るのがいちばん短い。
- 終える入力の形：S4 の上の sheet（モーダル）。S5 が出ている間は、S1 と別の本の S3 に行けない。だから AC-17 と AC-27 の finishing の通りは「S5 のキャンセル（session.finish.cancel）で reading に戻してから」になる（承認の記録 docs/approvals/001-reading-session-G0.md の裁定）。このとき状態は reading なので、Then の値は reading の通りと同じになる。
- 「やめる」の出口の形：S5 のツールバーの左（ToolbarItemPlacement.cancellationAction）の「キャンセル」。ButtonRole.cancel、識別子 session.finish.cancel。シートを下へスワイプしても同じ動きにする（AC-48）。どちらも確認を出さない（AC-46 の When が1回の操作のため）。PRD の言葉「やめる」は、画面ではシステムの言い方「キャンセル」で出す。
- やめた後に残す値：今のページは残さない（PRD 10、AC-46）。分の欄も残さない。次に「終える」を押したときは、その時点の経過の分数を入れ直す。理由：やめた後も読書は進むので、前の値を残すと実際より短い記録に気づかずに保存させてしまう（性格語「確か」）。この決まりは PRD の AC-47 になった。
- 読書を保存した後の画面（AC-50）：その本の S3。新しい記録が一覧の先頭に出て、合計時間と最後のページが変わる。VoiceOver には session.saved.announcement（「24分を記録しました。」）を1回知らせる。祝う表示は出さない（調査の 5 の「淡々」、R-22）。
- 読み込みに失敗した S1（AC-54）：error.loadFailed の題、文、「もう一度読み込む」だけを出し、右上の「＋」（library.addBook）も出さない。理由：読み込めない保存先とは別の所へ本を書くおそれがある（pdm の推奨と同じ）。読み込めなかった本と記録が戻る前に新しい本を足させず、次の一手を「もう一度読み込む」の1つにする（D-44）。
- 題名が100字（PRD 10 の上限）に届いたときの見せ方（PRD 10 が designer に委ねた）：残りの字数は出さず、題名の欄の下（footer）に知らせを1つ出す。誤りとして扱わず、「追加」は有効のまま（D-45）。PRD 10 の2つの形（どちらにするかは tech-lead が設計メモで決める）に合わせて、出す条件と文を分ける（D-57）。
  - 形A（入力で止める。変換中の文字には当てない）：欄の字数が100のとき、book.add.titleLimit「題名は100字までです。超えた分は入りません。」
  - 形B（保存のときに先頭の100字に切る）：欄には100字を超えて入る。PRD 10 の空白と改行の決まりで整えたあとの字数が100を超えている間、book.add.titleLimit.onSave「題名は100字までです。超えた分は保存しません。」。変換中の文字も数に入れてよい（入力を切らないので変換は壊れない）。
- 計測の start_source（PRD 15）：S1 の主操作から始めたら home、S3 から始めたら book_detail、S2 で追加した直後の S3 から（その S3 を離れる前に）始めたら after_add。計測の作りは tech-lead が決める。
- 読み始め、一時停止、再開の保存に失敗したとき（PRD 10、AC-56〜AC-61。pdm の3つの問いへの答え。D-51、D-52）：
  - 「もう一度保存」（error.retry の S2 と S5 の文）は、この3つには合わない。利用者が押したのは「保存」ではなく「読み始める」「一時停止」「再開」だから。識別子は error.retry のまま（PRD の AC の名前）で、文は操作ごとのキー error.retry.start「もう一度読み始める」、error.retry.pause「もう一度一時停止」、error.retry.resume「もう一度再開」にする。
  - 説明文のキーは要る。題（error.saveFailed）だけでは、時間を数えているかどうかが分からないため。error.saveFailed.start「読書はまだ始まっていません。時間は数えていません。」、error.saveFailed.pause「読書は止まっていません。時間は数え続けています。」、error.saveFailed.resume「読書は一時停止のままです。時間は止まっています。」（性格語「確か」）。
  - エラーが出ている間、失敗した操作のボタン（S1、S3 の主操作、S4 の「一時停止」か「再開」）は、同じ場所と同じ形の error.retry に置き換える。同じ働きのボタンを2つ並べない。S4 の「終える」は押せるまま。
  - エラーの区画は、置き換えたボタンのすぐ上に出す（S1、S3 は下端の帯の中、S4 は状態の文字とボタンの間）。アラートにしない。再試行が通るか、その画面を離れると消える。
- 「終える」、終える入力をやめる、60秒未満で終える、の保存に失敗したとき（PRD 10、AC-62〜AC-67。pdm の問いへの答え。D-58〜D-60）：
  - 「終える」（経過60秒以上）の保存と、60秒未満で終える保存（読書を消す保存）は、利用者には同じ「終える」のボタンなので、表示を1つにする。S4 の「終える」を同じ場所と同じ形（.borderedProminent）の error.retry「もう一度終える」（error.retry.finish）に置き換え、状態の文字とボタンの間にエラーの区画（error.saveFailed と error.saveFailed.finish「読書はまだ終わっていません。ここまでの時間は消えていません。」）を出す。左の「一時停止」か「再開」は押せるまま（D-58）。
  - 再試行の時点の経過で分ける（PRD 18 の 6。指揮役が推奨 A に決めた）：「もう一度終える」は「終える」をもう一度押すのと同じに扱う。経過が60秒未満なら読書を消して S3（AC-67）、60秒以上なら S5 を開く（AC-63）。60秒未満で失敗した後に読み続けて60秒を超えたら、読書は消さずに S5 が開く。だから再試行の文は「もう一度終える」の1つにし、どちらに進むかを先に約束しない（D-59）。
  - やめる保存の失敗は、S5 の先頭（保存の失敗と同じ場所）に区画を出す。文は error.saveFailed.cancel「まだ読書に戻っていません。入れた値はそのままです。この画面にいる間の時間は数えません。」、ボタンは .bordered の error.retry「もう一度読書に戻る」（error.retry.cancel）。「もう一度保存」と見分けるため、記録を作る動詞を使わない。PRD の言葉「やめる」は画面に出ない語（上の「やめる」の出口の形）で、「やめる」だけでは読書そのものをやめると読めるので、押した結果の「読書に戻る」にする（指示書の推奨「もう一度やめる」から替えた。D-60）。「キャンセル」と2つの「保存」も押せるまま（D-14 と同じ）。
  - 下へのスワイプでやめる保存に失敗したとき（PRD 10 が tech-lead と designer に委ねた）：シートはスワイプでいったん閉じるので、同じ値のまま開き直し、先頭に同じ区画を出す（D-60）。成功するふだんのスワイプ（AC-48）の動きを変えないため。開き直したとき VoiceOver に error.saveFailed を1回知らせる。作れるかは tech-lead が設計メモで確かめる（10 の 8）。
  - エラーの区画は1画面に1つ。S4 と S5 で別の操作がまた失敗したら、最後に失敗した操作の文と再試行に替え、前の再試行のボタンは元のボタンに戻す。S4 で別の操作が通ったら（「終える」の失敗の後に一時停止が通ったなど）、区画は消えてボタンは元に戻る。状態が変わり、区画の文が当たらなくなるため。
- S6（記録を消す確認）を alert にした（D-16）：iOS の版によって confirmationDialog に「キャンセル」が出ないおそれがある（tech-lead r1 の要修正3）。alert なら「キャンセル」がいつも出て、AC-38 の「消さない」の操作が1つの形になる。

## 2. 受け入れ条件と画面の対応
AC-1〜AC-67 のすべて。識別子は 6、文言のキーは 7。AC-47〜AC-67 で使う名前の一覧は 6 の最後。

| AC | 画面 | 操作 |
|---|---|---|
| AC-1 | S1（本が0冊） | 起動すると、空の状態（library.empty.title、library.empty.message）と「本を追加」（library.addBook）が1つだけ出る。右上の「＋」、今週の合計、下端の主操作は出さない。home.startReading と book.startReading は0個 |
| AC-2 | S2 → S3、S1 | S2 の book.add.title に「坊っちゃん」、総ページ数は空のまま book.save → S3。book.lastPage の value が「0」、book.totalPages は0個。戻ると S1 の本の行は1つ、home.bookCount は「1冊」 |
| AC-3 | S2 | 題名が空か空白だけ（半角、全角 U+3000、改行、タブとその組み合わせ）の間、book.save は無効。誤りの文は出さない（見出し「題名（必須）」と、ボタンが押せないことで伝える） |
| AC-4 | S1 → S2 → S3 → S4 | 1 の「AC-4 の道」。タップは library.addBook、book.save、book.startReading の3回。S4 の reading.title は「坊っちゃん」、状態は reading |
| AC-5 | S1 → S4 | 主操作 home.startReading を1回 → S4。reading.elapsed は 0:00 から毎秒進む。テストは label で読む（7 の経過の表：0:00 は「0分0秒」） |
| AC-6 | S4 → S5 → S3 | reading.pause →（60秒）→ reading.resume →（60秒）→ reading.finish → S5 の session.finish.save → S3 の新しい記録の行の session.row.minutes が「2分」 |
| AC-7 | S4 | 裏に回して戻っても S4 のまま。経過は開始の時刻から計算し直して出す |
| AC-8 | 起動 → S4 | reading が残っていれば、S1 の上に S4 を積んで開く。状態は reading |
| AC-9 | S4 → S5 → S3 | session.finish.page に 72 → 保存 → S3：新しい行の session.row.page の label「32ページ進んだ」（session.row.pages に 32。AC の「32」はこの数。読み方は 6）、book.lastPage「72」、book.progress「24%」 |
| AC-10 | S5 → S3 | ページを空のまま保存 → S3：book.sessionCount「記録 2件」、新しい行に session.row.page がない、book.lastPage「40」、状態 idle |
| AC-11 | S5 | 301 を入れた時点で、欄の下に session.finish.pageOutOfRange（「0から300までの数字で入れてください。」）。session.finish.save は無効。S5 のまま（finishing） |
| AC-12 | S5 → S3 | session.finish.minutes は「180」で開く → 45 に直して保存 → S3：新しい行の session.row.minutes「45分」、book.totalTime が45分増える |
| AC-13 | S4 → S3 | 経過59秒で reading.finish → S5 を出さずに、その本の S3 へ。先頭に session.finish.tooShort。状態 idle |
| AC-14 | S3 | book.totalTime「60分」、book.sessionCount「記録 3件」、book.lastPage「72」、book.progress「24%」 |
| AC-15 | S1 | home.weekTotal の value「60分」 |
| AC-16 | S3 → S6 → S3 | 30分の行を左へスワイプ →「削除」（session.row.delete）→ S6（alert）の「記録を消す」（session.delete.confirm）→ 行が消え、「記録 1件」、book.totalTime「20分」、book.lastPage「72」 |
| AC-17 | S4 → S1 → S3 | reading と paused：S4 の戻る → S1 の「こころ」の行 → S3。book.startReading は無効で、その上に book.start.busy と book.openActiveReading（読書中の本へ行く。D-33）。finishing：S5 のキャンセルで reading に戻してから同じ道（承認の記録の裁定） |
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
| AC-29 | S5 → S3 | 50 を入れて保存 → 新しい行の session.row.page の label「0ページ進んだ」（session.row.pages に 0）、book.lastPage「50」、book.progress「16%」 |
| AC-30 | S5 | 分の欄を 0 にする（181 も同じ）→ session.finish.minutesOutOfRange（「1から180までの数字で入れてください。」）。保存は無効。S5 のまま（finishing） |
| AC-31 | S2 | 総ページ数に 0 か 10000 → 欄の下に book.add.totalPagesOutOfRange、book.save は無効。1 と 9999 では誤りの文が消え、book.save は有効 |
| AC-32 | S5 → S3 | 総ページ数が未設定：10000 → session.finish.pageOutOfRange（「0から9999までの数字で入れてください。」）、保存は無効。9999 → 保存 → S3 の book.lastPage「9999」、状態 idle |
| AC-33 | 起動 → S4 | paused なら S4 を一時停止の形で開く。reading.elapsed は「5:00」のまま（label「5分0秒」）、reading.state「一時停止中」、ボタンは reading.resume |
| AC-34 | 起動 → S4 ＋ S5 | finishing なら S4 の上に S5 を開く。session.finish.minutes「10」、session.finish.page は空 |
| AC-35 | S5 → S3 | error.retry を1回 → 成功 → S5 を閉じて S3：「記録 3件」、状態 idle、error.saveFailed は0個 |
| AC-36 | S1 | 本が1冊以上で今週の記録が0件：home.weekTotal の value「0分」。責める文や「まだ」の文は出さない |
| AC-37 | S3 | book.totalTime「0分」、book.sessionCount「記録 0件」、book.progress「0%」。一覧の代わりに book.sessions.empty。book.startReading は有効 |
| AC-38 | S3 → S6 → S3 | S6（alert）で「キャンセル」（session.delete.cancel）→ 何も変わらない。「記録 2件」、book.totalTime「50分」。alert には「キャンセル」がいつも出るので、PRD の注記の「確認の外側をタップ」は使わない見込み（どちらの形かは G2 の CI の出力で決める。6 の S6 の行と 10 の 2） |
| AC-39 | 全画面（7 の表） | 7 のすべてのキーに ja と en がある |
| AC-40 | S4 | reading.elapsed の accessibilityLabel は ja「12分30秒」、en「12 minutes, 30 seconds」（7 の経過の表） |
| AC-41 | S4 | 時計が開始より前に戻ったら、経過は 0:00（label「0分0秒」）。負の値は出さない。エラーも出さない |
| AC-42 | S2 | 保存に失敗 → S2 の先頭にエラーの区画（error.saveFailed、error.saveFailed.book、error.retry）。book.add.title の value は「こころ」のまま。S2 は閉じない |
| AC-43 | S3 → S6 → S7 | S6（alert）で「記録を消す」→ 保存に失敗 → S6 が閉じてから S7（題 error.saveFailed、本文 error.saveFailed.delete、「OK」）。行は残り、「記録 2件」、book.totalTime「50分」 |
| AC-44 | S1 | home.weekTotal の value「20分」 |
| AC-45 | S4 → S5 → S3 | reading.finish を押した時刻で経過を止める。S5 にいた60秒は数えない。新しい行「2分」 |
| AC-46 | S5 → S4 → S5 | 72 を入れた S5 で session.finish.cancel → S4（reading、経過 10:00）→ 続けて reading.finish → S5 の session.finish.page は空、session.finish.minutes はその時点の経過の分数 |
| AC-47 | S4 → S5 → S4 → S5 | 経過 10:00 で reading.finish → S5 の session.finish.minutes「10」を「5」に直す → session.finish.cancel → S4（reading）→ 5分後に reading.finish → S5（finishing）の session.finish.minutes の value は「15」。直した「5」も前の初めの値「10」も残さない（D-4） |
| AC-48 | S5 → S4 | session.finish.page に 72 → 2分後にシートを下へスワイプ → 確認を出さずに S4（reading）。reading.elapsed の label は「10分0秒」か「10分1秒」（S5 にいた間は数えない）。session.finish.save は0個。S4 の戻るから「坊っちゃん」の S3 を開くと book.sessionCount「記録 2件」のまま。session.finish.cancel と同じ結果（D-3） |
| AC-49 | S2 → S3 | book.add.title に「こころ」→ book.save → S2 を閉じ（book.add.title は0個）、「こころ」の S3。book.title「こころ」、book.startReading（「読み始める」）は押せる位置にある。S1 の前の本（坊っちゃん）でなく、追加した本の S3 に出る（D-5） |
| AC-50 | S1 → S4 → S5 → S3 | home.startReading → 経過 10:00 で reading.finish → session.finish.save → S5 と S4 を閉じ、「坊っちゃん」の S3（1 の置き換えの決まり。S1 > S3）。book.title「坊っちゃん」、book.sessionCount「記録 2件」、状態 idle（D-6） |
| AC-51 | S1 → S4 → S3 | home.startReading → 経過 0:59 で reading.finish → S5 を出さずに「坊っちゃん」の S3。先頭に session.finish.tooShort が1つ。book.sessionCount「記録 1件」のまま。アラートは出さない。状態 idle（D-6） |
| AC-52 | S3 | 「坊っちゃん」が reading か paused のとき、その S3 の主操作は book.resumeReading（有効）だけ。label は reading で action.resume「読書に戻る」、paused で action.resumePaused「一時停止中の読書に戻る」。book.startReading と book.start.busy は出さない。finishing のときは S5 の session.finish.cancel で reading に戻し、S4 の戻る（S3 から始めていれば S3 に戻る。S1 なら本の行から S3）で開く。label は「読書に戻る」（D-33） |
| AC-53 | S2 → S1 | book.add.title に「こころ」→ book.add.cancel → 確認のダイアログ（題 book.add.discard.title）の book.add.discard.confirm → S2 を閉じ（book.add.title は0個）、S1。home.bookCount「1冊」のまま、「こころ」の本の行（library.book.）は0個（D-18） |
| AC-54 | 起動 → S1（読み込みの失敗） | 保存先を読めない → S1 に ContentUnavailableView（error.loadFailed.title、error.loadFailed.message、ボタン error.loadFailed.retry）が1つずつ。library.empty.title、home.bookCount、home.weekTotal、home.startReading は0個。あわせて home.resumeReading、右上の「＋」（library.addBook）、本の行も出さず、S4 も積まない（D-44） |
| AC-55 | S1（読み込みの失敗）→ S1 → S3 | error.loadFailed.retry を1回 → 読み込み中の形 → 読めたら S1 の通常。error.loadFailed.title は0個、home.bookCount「2冊」。「坊っちゃん」の S3 の book.totalTime「60分」、「こころ」の S3 の book.totalTime「40分」。保存先は消していない（error.loadFailed.message のとおり。D-44） |
| AC-56 | S1 → S1、S3 → S3 | (1) S1 の home.startReading、(2) S3 の book.startReading → 読み始めの保存に失敗 → 操作した画面のまま。下端の帯に error.saveFailed（題）と error.saveFailed.start（文）、主操作の場所に error.retry（S1 は「坊っちゃん／もう一度読み始める」、S3 は「もう一度読み始める」）が1個ずつ。home.startReading（S1）と book.startReading（S3）はその間0個。session.state.idle、reading.elapsed は0個。S3 の book.sessionCount は「記録 1件」のまま（D-51、D-52） |
| AC-57 | S1 → S4、S3 → S4 | AC-56 の2通りのそれぞれで、60秒後に error.retry を1回 → 通ったら S4 を push（S1 > S4、S1 > S3 > S4）。session.state.reading、reading.title「坊っちゃん」、reading.elapsed の label「0分0秒」か「0分1秒」（失敗から再試行までの60秒は数えない）。error.saveFailed は0個。記録は1件のまま |
| AC-58 | S4 | 経過 10:00 で reading.pause → 一時停止の保存に失敗 → S4 のまま。状態の文字の下に error.saveFailed と error.saveFailed.pause、左のボタンの場所に error.retry「もう一度一時停止」が1個ずつ（reading.pause はその間0個）。session.state.reading、reading.state「読書中」のまま。60秒後の reading.elapsed の label「11分0秒」か「11分1秒」。reading.finish は押せる。記録は1件のまま |
| AC-59 | S4 | AC-58 の後（経過 11:00）に error.retry を1回 → 通ったら session.state.paused、reading.state「一時停止中」、左のボタンは reading.resume、経過は color.text.secondary。さらに60秒後も reading.elapsed の label「11分0秒」か「11分1秒」のまま。error.saveFailed は0個。記録は1件のまま |
| AC-60 | S4 | 経過 5:00 の paused で reading.resume → 再開の保存に失敗 → S4 のまま。状態の文字の下に error.saveFailed と error.saveFailed.resume、左のボタンの場所に error.retry「もう一度再開」が1個ずつ（reading.resume はその間0個）。session.state.paused、reading.state「一時停止中」のまま。60秒後も reading.elapsed の label「5分0秒」。記録は1件のまま |
| AC-61 | S4 | AC-60 の後に error.retry を1回 → 通ったら session.state.reading、reading.state「読書中」、左のボタンは reading.pause。さらに60秒後の reading.elapsed の label「6分0秒」か「6分1秒」（失敗から再試行までの60秒は数えない）。error.saveFailed は0個。記録は1件のまま |
| AC-62 | S4 | (a) reading の経過 10:00、(b) 経過 5:00 で一時停止した paused で reading.finish →「終える」の保存に失敗 → S4 のまま。状態の文字の下に error.saveFailed と error.saveFailed.finish、右のボタンの場所に error.retry「もう一度終える」が1個ずつ（reading.finish はその間0個）。S5 は開かない（session.finish.save と session.state.finishing は0個）。(a) session.state.reading で、60秒後の reading.elapsed の label「11分0秒」か「11分1秒」。(b) session.state.paused で、reading.elapsed の label「5分0秒」のまま。左のボタン（reading.pause か reading.resume）は押せる。記録は1件のまま（D-58） |
| AC-63 | S4 → S5 | AC-62 の2通りのそれぞれで、60秒後に error.retry を1回 → 通ったら S5（session.state.finishing、session.finish.save が1個）。session.finish.minutes の value は (a)「11」、(b)「5」（再試行の時刻で経過を止める）。さらに60秒たっても変わらない。error.saveFailed は0個。記録は1件のまま（D-58、D-59） |
| AC-64 | S5 | 経過 10:00 で reading.finish → S5 の session.finish.page に 72 → session.finish.cancel → やめる保存に失敗 → S5 のまま。先頭のエラーの区画に error.saveFailed と error.saveFailed.cancel、.bordered の error.retry「もう一度読書に戻る」が1個ずつ。session.state.finishing（session.state.reading は0個）、session.finish.page の value「72」、session.finish.minutes の value「10」、session.finish.save は1個（押せる）。記録は1件のまま。下へのスワイプで失敗したときも、開き直した S5 が同じ表示（D-60） |
| AC-65 | S5 → S4 | AC-64 の60秒後に error.retry を1回 → 通ったら S5 を閉じ（session.finish.save は0個）、S4。session.state.reading、reading.elapsed の label「10分0秒」か「10分1秒」（終える操作から再試行までの60秒は数えない）。error.saveFailed は0個。記録は1件のまま（D-60） |
| AC-66 | S4 | 経過 0:30 の reading で reading.finish → 60秒未満で終える保存（読書を消す保存）に失敗 → S4 のまま。AC-62 と同じ区画（error.saveFailed、error.saveFailed.finish）と、右のボタンの場所に error.retry「もう一度終える」が1個ずつ（reading.finish はその間0個）。session.state.reading、10秒後の reading.elapsed の label「0分40秒」か「0分41秒」。session.finish.tooShort と session.finish.save は0個。記録は1件のまま（D-58） |
| AC-67 | S4 → S3 | AC-66 の後（経過 0:40）に error.retry を1回 → 押した時点の経過が60秒未満なので、記録せず idle。S4 を「坊っちゃん」の S3 に置き換え（1 の置き換えの決まり）、先頭に session.finish.tooShort が1個。session.state.idle、book.title「坊っちゃん」、book.sessionCount「記録 1件」のまま、reading.elapsed と error.saveFailed は0個、アラートは0個。押した時点で60秒以上なら、読書を消さずに S5（PRD 18 の 6 の A。D-59） |

## 3. 画面の仕事と主操作、標準部品
主操作は1画面に1つで、アクセントの塗り（color.accent.fill）を使うのはその1つだけ（S2 と S5 はツールバーの確定のボタン）。エラーで主操作を error.retry に置き換えたときも、塗りは1つのまま。

| 画面 | 仕事（1文） | 主操作 | 使う標準部品 | 標準から外れる所（本来の部品、理由、対応） |
|---|---|---|---|---|
| S1 ホーム | 前の本の続きを1回で読み始め、今週読んだ時間と本の一覧を見る | 下端のボタン home.startReading（読書中は home.resumeReading。本が0冊なら空の状態の library.addBook、読み込みの失敗なら error.loadFailed.retry だけ。読み始めの保存に失敗したら、同じ場所の error.retry） | NavigationStack、List（insetGrouped）、Section、LabeledContent、NavigationLink、toolbar（ToolbarItem の Button、SF Symbol plus）、ContentUnavailableView（0冊、読み込みの失敗）、Button（.borderedProminent、controlSize .large）、safeAreaInset(edge: .bottom)、redacted(reason: .placeholder)、ProgressView | 主操作の置き場所。本来の部品：ToolbarItem(placement: .bottomBar)。理由：ラベルが2行（前の本の題名と「72ページから読む」。差1）で、ツールバーの1行の項目に入らない。対応：中身は標準の Button と標準のスタイルなので、Dynamic Type、ダーク、コントラストを上げる設定、VoiceOver に追従する。帯の背景は不透明な color.background.grouped で、透明度を下げる設定でも見え方は変わらない。AX サイズでは帯をやめ、リストの先頭の行に移す（9） |
| S2 本を追加 | 題名だけで本を登録する | 追加（book.save。.borderedProminent。D-46） | sheet、NavigationStack、Form、Section（header、footer）、TextField（総ページ数は .keyboardType(.numberPad)。placeholder なし）、toolbar（.cancellationAction、.confirmationAction）、FocusState（開いたら題名に焦点）、interactiveDismissDisabled（入力があるとき）、confirmationDialog（追加せずに閉じる確認） | 題名の欄は、tech-lead が設計メモで決める形による（PRD 10、tech-lead r1 の要修正1、裁定1）。形A（変換中の文字に上限を当てないために UITextField を包む［UIViewRepresentable］と決めた場合）：本来の部品は SwiftUI の TextField。理由は、SwiftUI の TextField から変換中の文字（markedTextRange）を知る手段が見つかっていない（未確認）ため、確定した文字だけを100字で止めるには UIKit の欄が要る。対応は (1) Dynamic Type：font を UIFont.preferredFont(forTextStyle: .body) にし、adjustsFontForContentSizeCategory を true にして AX5 まで大きくする。行の高さは Form に任せる。(2) VoiceOver：UITextField の標準の読み上げを使い、accessibilityLabel は book.add.titleField、accessibilityIdentifier は book.add.title、value は入れた文字。(3) 見た目：文字は color.text.primary、カーソルは AccentColor（color.accent.text）、背景は透明で行の背景（color.background.row）のまま。枠と placeholder を描かない。(4) 焦点：S2 を開いたら最初の応答者にする（D-10）。(5) ダークとコントラストを上げる設定は、システムの色なので追従する。形B（保存のときに先頭の100字に切る場合）：標準の TextField のままで、外れる所はない。知らせの出し方は 1 と D-57 |
| S3 本の詳細 | その本の合計と記録を確かめ、その本で読み始める | 下端のボタン book.startReading（この本が読書中なら book.resumeReading。読み始めの保存に失敗したら、同じ場所の error.retry。別の本が読書中なら book.startReading は無効で、その上の book.openActiveReading（.bordered）が読書中の本へ行く道。D-33） | List（insetGrouped）、Section、LabeledContent、EditButton と onDelete、swipeActions（Button role .destructive、SF Symbol trash）、alert（S6 と S7）、safeAreaInset の Button（.borderedProminent と .bordered）、redacted | (1) 主操作の置き場所は S1 と同じ（本来の部品と理由も S1 と同じ。同じ働きの主操作を同じ場所に置く）。(2) 題名を、ナビゲーションバーの大きい見出しでなく、リストの先頭の行に .title2 で置く。本来の部品：navigationTitle の大きい見出し。理由：大きい見出しは長い題名を1行で切るので、全部を出せない（R-12「Keep text truncation to a minimum」）。対応：その行に accessibilityAddTraits(.isHeader)。ナビゲーションバーにも同じ題名を inline で置く（戻る先の名前と、スクロールした後の画面の名前のため） |
| S4 読書中 | 読んでいる間の経過を確かめ、一時停止するか終える | 終える（reading.finish） | NavigationStack の push 先、Text（経過は .largeTitle と monospacedDigit）、TimelineView（毎秒の書き直し）、Button（終えるとその場所に出る error.retry「もう一度終える」は .borderedProminent、一時停止と再開とその場所に出る error.retry は .bordered）、Label（エラーの区画の記号と題）、dynamicTypeSize の isAccessibilitySize と ViewThatFits による並びの切り替え、ScrollView（AX サイズのとき） | なし |
| S5 読書を終える | 今のページと読んだ時間を確かめて、記録に残す | 保存（session.finish.save。.borderedProminent。キーボードが出ている間は、キーボードの上にも .bordered の session.finish.saveKeyboard。D-46、D-53） | sheet、NavigationStack、Form、Section（header、footer）、LabeledContent、TextField（.keyboardType(.numberPad)。placeholder なし）、toolbar（.cancellationAction、.confirmationAction、ToolbarItemPlacement.keyboard）、FocusState（開いたら今のページに焦点） | (1) 分の入力に、選ぶ部品（Picker、Stepper）を使わず数字を打つ欄にする。本来の部品：HIG Entering data「When possible, offer choices instead of requiring text entry」の選ぶ部品。理由：AC-30 は 0 と 181 を入れて拒まれることを確かめるので、範囲を絞る部品では When を行えない（verifier r2 の AC-30）。180分を45分に直す（AC-12）のも打つほうが速い。対応：標準の TextField なので、VoiceOver で値を読み、直せる。範囲の外は欄のすぐ下に文で出す。今のページと総ページ数も同じ形にそろえる。(2) 下へのスワイプで、入れた値があっても確認なしに閉じる。本来の形：HIG Sheets「If people have unsaved changes in the sheet when they begin swiping to dismiss it, use an action sheet to let them confirm their action.」（https://developer.apple.com/design/human-interface-guidelines/sheets ）。理由：閉じても読書は消えず reading に戻るだけで（AC-48）、入れかけのページは残さない決まり（PRD 10、AC-46）、分は次に開いたときに経過の分数で入り直す（AC-47）。確かめても守るものがなく、AC-46 と AC-48 は1回の操作で読書に戻ることを求める。対応：「キャンセル」と同じ動きにし（D-3）、戻った S4 で経過がそのまま見える。VoiceOver ではシステムの「閉じる」の操作（2本指でこする）でも同じ |
| S6 記録を消す確認 | 記録を消してよいかと、消すと何が変わるかを確かめる | 記録を消す（session.delete.confirm。destructive の形を付けない。D-16） | alert（題、本文、「キャンセル」と「記録を消す」の2つのボタン） | なし |
| S7 記録を消せなかった知らせ | 記録を消せなかったことと、記録が残っていることを知らせる | OK | alert | なし |

## 4. 決定と根拠
| 決定 | 根拠（R-n） | 原則（HIG の URL か B-n） |
|---|---|---|
| D-1 読書中（S4）は push にし、全画面のモーダルにしない。戻るで S1 に戻っても読書は続く（AC-17、AC-27 の道） | R-3「Davies leaned on platform conventions」、R-6「Restore the previous state」 | HIG Modality「Present content modally only when there's a clear benefit.」https://developer.apple.com/design/human-interface-guidelines/modality 、B-1 |
| D-2 読書を終える入力（S5）は S4 の上の sheet。同時に出すモーダルは1つ | R-3「only the current step」 | HIG Sheets「A sheet helps people perform a scoped task that's closely related to their current context.」「Display only one sheet at a time from the main interface.」https://developer.apple.com/design/human-interface-guidelines/sheets |
| D-3 S5 の出口は左上の「キャンセル」と下へのスワイプ。どちらも確認なしで reading に戻る（AC-46、AC-48）。スワイプで確認を出さないのは HIG Sheets の「unsaved changes」の文から外れる（3 の S5 の (2) に、本来の形、理由、対応） | R-1「Help people recover from mistakes.」 | HIG Sheets「The Cancel (or Close) button dismisses a sheet without saving any changes.」「Support swiping to dismiss a sheet.」（https://developer.apple.com/design/human-interface-guidelines/sheets） |
| D-4 キャンセルの後、今のページと分の欄は残さず、次は新しい経過の分数で入れ直す（AC-46、AC-47） | R-1、R-7「Provide reasonable default settings」 | HIG Entering data「You can also prefill fields with reasonable default values」https://developer.apple.com/design/human-interface-guidelines/entering-data 、B-1 |
| D-5 本を追加した後は、追加した本の S3 に出る（AC-49） | R-3「How quickly can I get you back to preparing the meal」 | B-1 |
| D-6 読書を保存した後と、60秒未満で終えた後は、その本の S3 に出る。祝う表示は出さず、新しい行と合計の変化で返す。60秒未満の知らせは S3 の先頭の文にし、アラートにしない（AC-50、AC-51） | R-1「Provide clear feedback.」、R-22、R-18 | HIG Alerts「Avoid using an alert merely to provide information.」https://developer.apple.com/design/human-interface-guidelines/alerts 、B-2 |
| D-7 S1 の主操作は、前の本の題名と「72ページから読む」を1つのボタンにする（差1 の「開く」）。ページが0なら「続きを読む」か「読み始める」 | R-2「making sure they aren't too literal or abstract」、R-14、R-21 | HIG Buttons「In general, use a button that has a prominent visual style for the most likely action in a view.」https://developer.apple.com/design/human-interface-guidelines/buttons 、B-1 |
| D-8 S1 と S3 の主操作は画面の下端に置き、片手の親指で届く場所にする | R-3「How quickly can I get you back to preparing the meal, rather than reading?」（開いて確認）と PRD 5 の O-1「読もうと思っても、始めるまでが面倒で、結局スマホを触ってしまう」を主な根拠にし、R-24（片手で持つ人 49%）と R-23（就寝前 46.7%）は抜粋なので補いにだけ使う（調査の決まり：抜粋だけの R は1つで決定を支えない） | HIG Toolbars「A toolbar consists of one or more sets of controls arranged horizontally along the top or bottom edge of the view」https://developer.apple.com/design/human-interface-guidelines/toolbars 、HIG Accessibility（操作の的 44x44pt）https://developer.apple.com/design/human-interface-guidelines/accessibility 、B-3 |
| D-9 目立つ主操作は1画面に1つで、アクセントの塗り（color.accent.fill）はその1つだけ | R-10「Refrain from adding color to the background of multiple controls.」 | B-2、B-5 |
| D-10 S2 を開いたら題名の欄に焦点を当て、キーボードを出す | R-7「immediately start interacting」 | HIG Entering data、B-1（https://developer.apple.com/design/human-interface-guidelines/entering-data） |
| D-11 S5 を開いたら今のページの欄に焦点を当て、数字のキーボード（numberPad）を出す。空のまま保存できる（差1 の「挟む」） | R-3「only the current step」、R-24 | HIG Virtual keyboards「Choose a keyboard that matches the type of content people are editing.」https://developer.apple.com/design/human-interface-guidelines/virtual-keyboards |
| D-12 分、今のページ、総ページ数は数字を打つ欄にし、選ぶ部品にしない（3 の逸脱）。分の欄には経過の分数を最初から入れる | R-7、R-24 | HIG Text fields「Use a number formatter to help with numeric data.」https://developer.apple.com/design/human-interface-guidelines/text-fields |
| D-13 入力は打つたびに確かめ、誤りは欄のすぐ下に文で出し、追加と保存のボタンを無効にする。入れた文字は消さない。数字以外を貼り付けたときも同じ（入力の決まりは 7） | R-8「display it as close to the problem as possible, avoid blame, and be clear about what someone can do to fix it」 | HIG Entering data「Dynamically validate field values.」、HIG Text fields「if the only legitimate value for a field is a string of digits, your app needs to alert people if they've entered characters other than digits」（https://developer.apple.com/design/human-interface-guidelines/entering-data、https://developer.apple.com/design/human-interface-guidelines/text-fields） |
| D-14 S2 と S5 の保存の失敗は、フォームの先頭にエラーの区画（何が起きたか、読書や入力が残っていること、「もう一度保存」の .bordered のボタン）を出し、フォームを閉じない。確定のボタンも押せるままで、同じ働きをする | R-8、R-1 | HIG Writing https://developer.apple.com/design/human-interface-guidelines/writing 、HIG Modality「help people avoid data loss」 |
| D-15 記録の削除の失敗は alert（S7）で知らせる。削除は確認の alert（S6）から始まり、消そうとした行の位置が決まらないので、近くに文を置けない | R-8 | HIG Alerts「an alert can tell people about a problem」（https://developer.apple.com/design/human-interface-guidelines/alerts） |
| D-16 記録を消すときは確認（S6）を出す。確認の文に、合計時間から引く分数と、最後のページが変わらないこと、元に戻せないことを書く。確認は alert にする（G1 r2 で confirmationDialog から替えた）：選ぶのは「消す」か「やめる」の2つだけで、ほかの選択肢がない。alert なら「キャンセル」が iOS の版によらずいつも出る（tech-lead r1 の要修正3）。「記録を消す」には destructive の形を付けない（利用者がスワイプか「編集」で自分から選んだ操作のため） | R-1「Help people recover from mistakes.」 | HIG Alerts「when people take an uncommon destructive action that they can't undo, it's important to display an alert in case they initiated the action accidentally.」「Use the destructive style to identify a button that performs a destructive action people didn't deliberately choose.」「If there's a destructive action, include a Cancel button」https://developer.apple.com/design/human-interface-guidelines/alerts 、HIG Action sheets「Although an alert can also help people confirm or cancel an action that has destructive consequences, it doesn't provide additional choices related to the action.」https://developer.apple.com/design/human-interface-guidelines/action-sheets |
| D-17 記録の削除は、スワイプのほかに、画面に見える「編集」（EditButton）からもできる | R-1 | HIG Accessibility「Offer alternatives to gestures.」、HIG Lists and tables「In iOS and iPadOS, people must enter an edit mode before they can select table items.」https://developer.apple.com/design/human-interface-guidelines/lists-and-tables |
| D-18 S2 に入力があるときは、スワイプで閉じさせず、キャンセルで「追加せずに閉じる」を確かめる（AC-53） | R-1 | HIG Sheets「If people have unsaved changes in the sheet when they begin swiping to dismiss it, use an action sheet to let them confirm their action.」（https://developer.apple.com/design/human-interface-guidelines/sheets） |
| D-19 本が0冊の S1 は ContentUnavailableView で、状態の説明と「本を追加」の1つだけ。説明の画面、設定、ログインを挟まない | R-7、R-5「nothing extraneous」、R-8「Provide clear next steps on any blank screens.」 | HIG Onboarding https://developer.apple.com/design/human-interface-guidelines/onboarding 、ContentUnavailableView https://developer.apple.com/documentation/swiftui/contentunavailableview |
| D-20 今週0件は「0分」と出すだけ。目標、連続日数、「まだ読めていません」の文を出さない | R-4「less about hard comparisons and more about progress」、R-22 | HIG Writing「Match your tone to the context.」、B-2（https://developer.apple.com/design/human-interface-guidelines/writing） |
| D-21 S4 に置くのは、題名、「72ページから」、経過、状態の文字、一時停止（再開）、終えるの6つだけ。合計、一覧、統計、色の面、動く飾りを置かない（差2） | R-3「displaying only the current step」、R-4「keep their focus on the counter rather than their screen」 | B-1、B-2 |
| D-22 経過は type.timer（.largeTitle と等幅の数字）。60分未満は m:ss、60分以上は h:mm:ss。数字が変わるときに動きを付けない | R-12、R-11 | HIG Typography https://developer.apple.com/design/human-interface-guidelines/typography 、HIG Motion「In apps, generally avoid adding motion to UI interactions that occur frequently.」https://developer.apple.com/design/human-interface-guidelines/motion 、B-4 |
| D-23 経過の VoiceOver の読み上げは「12分30秒」の形。毎秒は読み上げない（updatesFrequently の特性を付けず、知らせも出さない） | R-11 | HIG VoiceOver https://developer.apple.com/design/human-interface-guidelines/voiceover |
| D-24 一時停止中は、経過（.largeTitle の 34pt。基準は 3:1）だけを color.text.secondary にし、「一時停止中」の文字（color.text.primary）とボタンの「再開」でも示す。17pt 以下の状態の文字は灰色にしない（D-48） | R-10「Avoid relying solely on color」、R-1「Provide clear feedback.」 | HIG Accessibility「Convey information with more than color alone.」（https://developer.apple.com/design/human-interface-guidelines/accessibility） |
| D-25 起動したとき読書中が残っていれば、S4（finishing なら S4 と S5）をそのまま開く。アラートは出さない | R-6「Restore the previous state when your app restarts so people can continue where they left off.」 | HIG Launching https://developer.apple.com/design/human-interface-guidelines/launching 、HIG Alerts「Avoid showing an alert when your app starts.」 |
| D-26 アクセントは1色「しおりの色」（栗色）。塗り用（color.accent.fill）と文字用（color.accent.text）の2つの値の組に分ける（D-47）。値とコントラストは tokens.md | R-10、R-9、R-23 | HIG Color https://developer.apple.com/design/human-interface-guidelines/color 、B-5 |
| D-27 背景と文字はシステムの色。アプリ独自の外観の設定を置かない | R-9「Avoid offering an app-specific appearance setting.」「Prefer the system background colors.」 | HIG Dark Mode https://developer.apple.com/design/human-interface-guidelines/dark-mode |
| D-28 文字は text style だけ。大きさの段は1画面4つまで。書体は1つ | R-12「Minimize the number of typefaces you use」 | B-4、HIG Typography（https://developer.apple.com/design/human-interface-guidelines/typography） |
| D-29 Liquid Glass はシステムがバーとシートに付ける分だけ。内容の層と下端の主操作の帯には使わない | R-13「Don't use Liquid Glass in the content layer.」 | HIG Materials https://developer.apple.com/design/human-interface-guidelines/materials |
| D-30 S1 の見出しは「読書」。アプリ名にしない | R-3「leaned on platform conventions」 | HIG Toolbars「Don't title windows with your app name.」https://developer.apple.com/design/human-interface-guidelines/toolbars |
| D-31 本の一覧は、最後に記録を保存した時刻（記録がなければ追加した時刻）の新しい順。並べ替えと検索は置かない（検索は PRD 10 のやらないこと）。前の本が先頭に来る | R-3「I spent a lot of time figuring out what to leave out」、R-2「deciding what not to include」 | B-2、HIG Lists and tables「Keep item text succinct」（https://developer.apple.com/design/human-interface-guidelines/lists-and-tables） |
| D-32 記録の行は、読み始めた時刻の新しい順。中身は日付と時刻、分、ページ（入れた記録だけ）の3つ。読書の速さや予測は出さない | R-1「Provide clear feedback.」、R-18 | B-1、HIG Lists and tables（https://developer.apple.com/design/human-interface-guidelines/lists-and-tables） |
| D-33 別の本が読書中なら、S3 の主操作を無効にし、その上に理由と次の一手（その読書を終える）を文で出し、文のすぐ下にその読書へ行くボタン「読書に戻る」（book.openActiveReading。.bordered。読書中の本が paused なら「一時停止中の読書に戻る」）を置く。押すと読書中の本の S4 を push する（1 の置き換えの決まり）。その本が読書中なら主操作を「読書に戻る」に変える（AC-17、AC-52）。G1 r2 で足した（design-reviewer r1 の提案10） | R-8「be clear about what someone can do to fix it」、R-1「Help people recover from mistakes.」 | B-1、HIG Design principles「Give them the freedom to act, keep them informed about what's happening, and make it easy to recover from mistakes.」https://developer.apple.com/design/human-interface-guidelines/design-principles |
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
| D-44 保存先を読み込めないときの S1 は、ContentUnavailableView の題（error.loadFailed.title）、文（error.loadFailed.message）、ボタン「もう一度読み込む」（error.loadFailed.retry）だけにする。右上の「＋」（library.addBook）、今週、冊数、本の行、下端の主操作、空の状態、読書中の S4 は出さない。押すと読み込み中の形に戻り、読めたら起動と同じに分かれる（AC-54、AC-55） | R-8「Provide clear next steps on any blank screens.」「be clear about what someone can do to fix it」、R-6「Restore the previous state when your app restarts so people can continue where they left off.」 | B-1、B-2、ContentUnavailableView https://developer.apple.com/documentation/swiftui/contentunavailableview |
| D-45 題名が100字（PRD 10 の上限）に届いたら、題名の欄の下（Section の footer）に book.add.titleLimit を type.note、color.text.primary で出し、VoiceOver に1回知らせる。100字より短くしたら消す。残りの字数は出さない。誤りとして扱わない（記号 exclamationmark.triangle と color.status.error を使わず、「追加」は有効のまま）。出す条件と文は形A と形B で分ける（D-57） | R-2「Every feature you add to your product, asks something of the person using it. It asks for their time, their attention, and their trust.」、R-8「display it as close to the problem as possible」、R-1「Provide clear feedback.」 | HIG Entering data「provide feedback as soon as you detect a problem」https://developer.apple.com/design/human-interface-guidelines/entering-data 、B-2、B-5 |
| D-46 S2 と S5 の確定のボタン（book.save、session.finish.save）は .borderedProminent（目立つ形）にする。塗りは color.accent.fill、ラベルは color.text.onAccent をアプリが .foregroundStyle で決め、システムの既定の色に任せない。どちらの値も、システムが既定で白いラベルを描いた場合にも 4.5:1 を満たすように選んだ（tokens.md 5 の A1） | R-10「Refrain from adding color to the background of multiple controls.」、R-11（17pt までは 4.5:1） | HIG Toolbars「Use the `.prominent` style for key actions such as Done or Submit. This separates and tints the action so there's a clear focal point.」https://developer.apple.com/design/human-interface-guidelines/toolbars 、HIG Color「the system applies the app accent color to the background in prominent buttons — such as the Done button」https://developer.apple.com/design/human-interface-guidelines/color 、B-5 |
| D-47 アクセントを塗り用（color.accent.fill）と文字用（color.accent.text）に分ける。塗り用のダークは白い文字で 4.5:1 以上になる暗さ（相対輝度 0.146）、文字用のダークは黒と elevated の背景の上で 4.5:1 以上。AccentColor（システムの tint）は文字用にし、目立つボタンには1つずつ塗り用を付ける | R-10「In dark environments, colors appear bright and saturated.」、R-9「For custom foreground and background colors, strive for a contrast ratio of 7:1, especially in small text.」、R-11 | HIG Color「Make sure all your app's colors work well in light, dark, and increased contrast contexts.」https://developer.apple.com/design/human-interface-guidelines/color 、B-5 |
| D-48 17pt 以下で情報を持つ文字は、すべて color.text.primary にする。List、Form、LabeledContent、ContentUnavailableView、ProgressView がシステムの既定で secondaryLabel にする所（セクションの見出しと footer、LabeledContent の値、空の状態と読み込みの失敗の文、読み込み中のラベル）も替える。階層は大きさと太さで作る。secondaryLabel は一時停止中の経過（34pt）だけ | R-11（コントラストの表）、R-12 | HIG Accessibility「If your app doesn't provide this minimum contrast by default, ensure it at least provides a higher contrast color scheme when the system setting Increase Contrast is turned on.」https://developer.apple.com/design/human-interface-guidelines/accessibility （secondaryLabel はライトの既定で 3.44:1、コントラストを上げても 4.22:1。tokens.md 5 の B2）、B-4 |
| D-49 入力欄に placeholder を置かない。S2 の必須と任意は見出し（「題名（必須）」「総ページ数（任意）」）で、S5 の今のページが任意であることは footer のヒント（「入れずに保存もできます。」）で伝える | R-11、R-8「display it as close to the problem as possible」 | HIG Text fields「Because placeholder text disappears when people start typing, it can also be useful to include a separate label describing the field to remind people of its purpose.」https://developer.apple.com/design/human-interface-guidelines/text-fields （placeholderText はどの組も 4.5:1 に届かない。tokens.md 5 の B4）、B-2 |
| D-50 アクセントの意味は「押せる」の1つにする。状態の文字「読書中」は color.text.primary にし、「もう一度保存」などの再試行は文字のボタンにせず .bordered（tint は color.text.primary）か、主操作の場所では .borderedProminent にする | R-10「Refrain from adding color to the background of multiple controls.」、R-1「Provide clear feedback.」 | HIG Color「Avoid using the same color to mean different things ... if you use your brand color to indicate that a borderless button is interactive, using the same or similar color to stylize noninteractive text is confusing.」https://developer.apple.com/design/human-interface-guidelines/color 、B-5 |
| D-51 読み始め、一時停止、再開の保存に失敗したら、状態を変えず、失敗した操作のボタンを同じ場所と同じ形の error.retry に置き換え、そのすぐ上にエラーの区画（記号、error.saveFailed、時間を数えているかを言う文）を出す。アラートにしない。再試行が通るか、画面を離れると消える。S4 の「終える」は押せるまま（AC-56〜AC-61） | R-8「display it as close to the problem as possible, avoid blame, and be clear about what someone can do to fix it」、R-1「Provide clear feedback.」「Help people recover from mistakes.」 | HIG Design principles「Recovering from the unexpected shouldn't cost people their time or work.」https://developer.apple.com/design/human-interface-guidelines/design-principles 、HIG Alerts「Avoid using an alert merely to provide information.」https://developer.apple.com/design/human-interface-guidelines/alerts 、B-1 |
| D-52 error.retry の文は、失敗した操作の動詞にする（S2、S5「もう一度保存」、読み始め「もう一度読み始める」、一時停止「もう一度一時停止」、再開「もう一度再開」）。識別子は PRD の AC のとおり error.retry の1つ | R-8「When labeling buttons and links, it's almost always best to use a verb.」 | HIG Alerts「Aim for a one- or two-word title that describes the result of selecting the button.」https://developer.apple.com/design/human-interface-guidelines/alerts 、HIG Writing「Be clear. Choose words that are easily understood and convey the right thing.」https://developer.apple.com/design/human-interface-guidelines/writing |
| D-53 S5 の「保存」を、キーボードが出ている間はキーボードの上（ToolbarItemPlacement.keyboard の右端）にも置く。形は .bordered（塗りは1画面に1つのまま。D-9）、識別子は session.finish.saveKeyboard、押せる条件と働きは session.finish.save と同じ。数字のキーボードには確定のキーがなく、右上の「保存」は片手の親指からいちばん遠いため（差1「挟む」） | R-3「How quickly can I get you back to preparing the meal, rather than reading?」（開いて確認）。R-24（片手で持つ人 49%）は抜粋なので補い | HIG Virtual keyboards「Place custom controls above the keyboard thoughtfully. ... make sure they're relevant to the current task. ... If you use a standard toolbar to contain your controls, it automatically adopts Liquid Glass.」と、キーボードの上にボタンを置く図を正しい例とする図 https://developer.apple.com/design/human-interface-guidelines/virtual-keyboards 、B-1 |
| D-54 記録の行のページは、進んだ量であることを文字で示す（「32ページ進んだ」、en「32 pages read」）。ページ番号を示す「%lldページから」と見分ける | R-8、R-1「Provide clear feedback.」 | HIG Writing「Be clear. Choose words that are easily understood and convey the right thing.」https://developer.apple.com/design/human-interface-guidelines/writing 、B-1 |
| D-55 英語のボタンは動詞で始める（「Back to Reading」を「Return to Reading」に） | R-8「When labeling buttons and links, it's almost always best to use a verb.」 | HIG Buttons「consider starting the label with a verb to help convey the button's action」https://developer.apple.com/design/human-interface-guidelines/buttons |
| D-56 システムの部品が自分で描く色（スワイプと編集モードの削除の赤、alert の文字）は、アプリから変えない。コントラストの値は tokens.md 5 の C に書き、届かない組は 10 に残す | R-11、R-9「Prefer the system background colors.」 | HIG Buttons「a destructive button uses the system red color」https://developer.apple.com/design/human-interface-guidelines/buttons 、HIG Accessibility「Prefer system-defined colors. These colors have their own accessible variants」https://developer.apple.com/design/human-interface-guidelines/accessibility |
| D-57 題名の上限の知らせは、tech-lead が設計メモで決める形に合わせる。形A（入力で止める）は欄の字数が100のとき book.add.titleLimit、形B（保存のときに切る）は整えたあとの字数が100を超えている間 book.add.titleLimit.onSave。どちらも識別子は book.add.titleLimit で、使わない方のキーは String Catalog に入れない | R-1「Provide clear feedback.」、R-8「display it as close to the problem as possible」 | HIG Entering data「provide feedback as soon as you detect a problem」https://developer.apple.com/design/human-interface-guidelines/entering-data 、B-1 |
| D-58 「終える」の保存（経過60秒以上の保存と、60秒未満で読書を消す保存）に失敗したら、D-51 と同じ形にする。状態を変えず、「終える」を同じ場所と同じ形（.borderedProminent）の error.retry「もう一度終える」に置き換え、状態の文字とボタンの間にエラーの区画（記号、error.saveFailed、error.saveFailed.finish）を出す。2つの保存は利用者には同じ「終える」なので、文と再試行は1つずつにする。左の「一時停止」か「再開」は押せるまま。エラーの区画は1画面に1つ（最後に失敗した操作）（AC-62、AC-63、AC-66） | R-8「display it as close to the problem as possible, avoid blame, and be clear about what someone can do to fix it」、R-1「Provide clear feedback.」「Help people recover from mistakes.」 | HIG Design principles「Recovering from the unexpected shouldn't cost people their time or work.」https://developer.apple.com/design/human-interface-guidelines/design-principles 、HIG Alerts「Avoid using an alert merely to provide information.」https://developer.apple.com/design/human-interface-guidelines/alerts 、B-1、B-2 |
| D-59 60秒未満で終える保存の再試行は、「終える」をもう一度押すのと同じに扱い、押した時点の経過で分ける（60秒未満なら記録せず S3、60秒以上なら読書を消さずに S5）。PRD 18 の 6 で指揮役が A に決めた。失敗の後に読み続けた60秒以上の読書を、利用者が選ばないまま捨てないため。再試行の文はどちらに進むかを約束しない「もう一度終える」にする（AC-67） | R-1「Help people recover from mistakes.」、R-8「When labeling buttons and links, it's almost always best to use a verb.」 | HIG Design principles「Recovering from the unexpected shouldn't cost people their time or work.」https://developer.apple.com/design/human-interface-guidelines/design-principles 、HIG Writing「Be clear. Choose words that are easily understood and convey the right thing.」https://developer.apple.com/design/human-interface-guidelines/writing 、B-1 |
| D-60 終える入力をやめる保存（「キャンセル」と下へのスワイプ）に失敗したら、S5 の先頭（保存の失敗と同じ場所）にエラーの区画（記号、error.saveFailed、error.saveFailed.cancel、.bordered の error.retry「もう一度読書に戻る」）を出す。再試行の文は、記録を作る「もう一度保存」と見分けるため、押した結果の動詞「読書に戻る」にする（画面に出ない語「やめる」は使わない）。「キャンセル」と2つの「保存」も押せるまま（D-14 と同じ）。下へのスワイプの失敗は、閉じたシートを同じ値のまま開き直して同じ区画を出し、成功するふだんのスワイプの動きは変えない（AC-64、AC-65） | R-8「When labeling buttons and links, it's almost always best to use a verb.」「display it as close to the problem as possible」、R-1「Help people recover from mistakes.」 | HIG Alerts「Aim for a one- or two-word title that describes the result of selecting the button.」https://developer.apple.com/design/human-interface-guidelines/alerts 、HIG Design principles「Recovering from the unexpected shouldn't cost people their time or work.」https://developer.apple.com/design/human-interface-guidelines/design-principles 、B-1 |

## 5. 画面ごとの状態
空とエラーには「何が起きたか」と「次の一手のボタン」を書いた。オフラインは全画面で同じ理由：001 の画面は通信を使わず、通信は計測の送信だけで、送れなくても画面に何も出さない（AC-20、PRD 12）。権限は全画面で同じ理由：001 は権限を1つも求めない（AC-21）。

| 画面 | 通常 | 空 | 読み込み中 | エラー | オフライン | 権限を断られたとき | 一部だけ読めたとき |
|---|---|---|---|---|---|---|---|
| S1 ホーム | 本が1冊以上。上から「今週」の行（home.weekTotal）、冊数の見出し（home.bookCount）、本の行（題名だけ。新しい順）。右上に「＋」。下端に主操作（idle は home.startReading、reading と paused は home.resumeReading） | 本が0冊：ContentUnavailableView（記号 books.vertical、library.empty.title、library.empty.message、ボタン library.addBook）。何が起きたか＝本がまだない、次の一手＝本を追加。「今週」、冊数、「＋」、主操作は出さない（AC-1）。本はあるが今週の記録が0件：home.weekTotal は「0分」（AC-36。これは通常の形のまま） | 最初の読み込みが終わるまで、「今週」の行と本の行3つを redacted の形で出す。値の代わりに「0分」「0冊」と空の状態は出さない。主操作は出さない。1秒を超えたら、形の上に ProgressView（ラベル common.loading）を足す（PRD 12 の線は1.0秒） | 保存先を開けない（読み込みの失敗）：ContentUnavailableView（記号 exclamationmark.triangle、error.loadFailed.title、error.loadFailed.message、ボタン error.loadFailed.retry「もう一度読み込む」）。何が起きたか＝読み込めなかった、記録は消していない。次の一手＝もう一度読み込む。このとき右上の「＋」（library.addBook）、今週、冊数、本の行、下端の主操作、空の状態（library.empty.*）は出さず、読書中の S4 も積まない（AC-54、D-44）。押すと読み込み中の形に戻り、読めたら通常（読書中が残っていれば S4 を積む。D-25）、また失敗したら同じ表示（AC-55）。(2) 読み始めの保存の失敗（AC-56、AC-57、D-51）：状態は idle のまま。下端の帯の中、主操作の場所のすぐ上に、記号 exclamationmark.triangle（color.status.error）と題 error.saveFailed（type.primaryTitle）、文 error.saveFailed.start「読書はまだ始まっていません。時間は数えていません。」（type.note、color.text.primary）。主操作 home.startReading は、同じ形（.borderedProminent、2行）の error.retry に置き換える：1行目は題名、2行目は error.retry.start「もう一度読み始める」。何が起きたか＝始められなかった、時間は数えていない。次の一手＝もう一度読み始める（通れば S4。60秒後に通っても経過は 0:00 から）。押している間は無効にし、二度押しで2回始めない。また失敗したら同じ表示のまま、VoiceOver に error.saveFailed をもう1回知らせる。本の行を開くなどで S1 を離れると消え、戻ったときは通常の主操作 | 通常と同じ（上の理由） | なし（上の理由） | なし。本と記録は端末の中の1つの保存先から一度に読み、一部だけ届く経路がない。読めなければ「エラー」の列になる |
| S2 本を追加 | 題名の欄に焦点。見出しは「題名（必須）」「総ページ数（任意）」（book.add.titleField、book.add.totalPagesField。placeholder は置かない。D-49）。題名が入るまで「追加」は無効。題名の上限の知らせ（D-45、D-57）：形A は欄の字数が100のとき book.add.titleLimit（上限は確定した文字に当てるので、変換中の文字では知らせを出さない）。形B は整えたあとの字数が100を超えている間 book.add.titleLimit.onSave。どちらも誤りではないので「追加」は有効のまま（PRD 10） | 開いた直後（両方の欄が空）：「追加」は無効。誤りの文は出さない（AC-3）。キャンセルは確認なしで閉じる | なし。読むデータがない。保存の間は「追加」を無効にし、二度押しで2冊できないようにする | (1) 総ページ数が範囲の外か数字でない：欄の下に book.add.totalPagesOutOfRange、「追加」は無効、入れた文字は残す（AC-31）。次の一手＝直す。(2) 保存の失敗：先頭にエラーの区画（記号、error.saveFailed、error.saveFailed.book、.bordered のボタン error.retry「もう一度保存」）。題名と総ページ数は残す。S2 は閉じない（AC-42）。「追加」も押せるままで、同じ働き（D-14）。次の一手＝もう一度保存 | 通常と同じ（上の理由） | なし（上の理由） | なし。入力だけの画面で、読み込むものがない |
| S3 本の詳細 | 先頭に題名（book.title、全部出す）。次に値の行（最後のページ、進み具合と総ページ数は総ページ数があるときだけ、合計時間）。記録の見出し（book.sessionCount）と記録の行（新しい順）。下端に主操作（idle は book.startReading、この本が読書中なら book.resumeReading、別の本が読書中なら、上から book.start.busy の文、読書中の本へ行く .bordered の book.openActiveReading「読書に戻る」、無効の book.startReading。D-33）。60秒未満で終えた直後は、先頭に session.finish.tooShort の文。文字はすべて color.text.primary（D-48） | 記録が0件：「記録 0件」の見出しの下に、一覧の代わりに book.sessions.empty の文。何が起きたか＝まだ記録がない、次の一手＝下端の「読み始める」（有効。AC-37）。合計時間は「0分」、総ページ数があれば進み具合は「0%」。「編集」は出さない | S1 と同じ考え：値の行と記録の行3つを redacted の形で出し、「0件」「0分」を出さない。1秒を超えたら ProgressView | (1) 記録の削除の失敗：S6 の alert が閉じてから S7（alert。題 error.saveFailed、本文 error.saveFailed.delete、ボタン「OK」）。行は残る（AC-43）。次の一手＝もう一度消す（本文に書く）。(2) 読み込みの失敗：S1 と同じ ContentUnavailableView。主操作と「編集」は出さない（D-44 と同じ理由）。(3) 読み始めの保存の失敗（AC-56、AC-57、D-51）：S1 の (2) と同じ。帯に記号、error.saveFailed、error.saveFailed.start、主操作 book.startReading を同じ形の error.retry「もう一度読み始める」（1行）に置き換える。状態は idle のまま。次の一手＝もう一度読み始める。S3 を離れると消える | 通常と同じ（上の理由） | なし（上の理由） | なし（S1 と同じ理由） |
| S4 読書中 | reading：題名（reading.title）、「72ページから」（reading.fromPage。最後のページが0なら出さない）、経過（reading.elapsed）、「読書中」（reading.state）、「一時停止」と「終える」。文字はすべて color.text.primary（D-48、D-50）。paused：経過だけを color.text.secondary（34pt。3:1 の基準）にし、状態の文字は「一時停止中」（color.text.primary）、ボタンは「再開」 | なし。本を決めてから入る画面で、空になる中身がない | なし。経過は開始の時刻から計算するので、開いた時点で値が出る（AC-5 の0.5秒）。起動して戻すときも同じ | (1) 一時停止の保存の失敗（AC-58、AC-59、D-51）：状態は reading のまま、経過は進み続ける。状態の文字とボタンの間（space.m）にエラーの区画：記号 exclamationmark.triangle（color.status.error）と題 error.saveFailed（type.primaryTitle）、文 error.saveFailed.pause「読書は止まっていません。時間は数え続けています。」（type.secondary。S4 の大きさの段を4つに保つため .footnote を使わない）。「一時停止」を同じ形（.bordered）の error.retry「もう一度一時停止」に置き換える。「終える」は押せるまま。次の一手＝もう一度一時停止か、そのまま終える。(2) 再開の保存の失敗（AC-60、AC-61）：状態は paused のまま、経過は止まったまま。同じ区画で、文は error.saveFailed.resume「読書は一時停止のままです。時間は止まっています。」、「再開」を error.retry「もう一度再開」に置き換える。(1)(2) とも、再試行が通るか、S4 を離れるか、「終える」が通ると区画は消える。押している間は無効にする。また失敗したら同じ表示のまま、VoiceOver に error.saveFailed をもう1回知らせる。(3) 「終える」の保存の失敗（経過60秒以上。AC-62、AC-63、D-58）：状態は reading か paused のまま（reading なら経過は進み、paused なら止まったまま）。S5 は開かない。同じ区画で、文は error.saveFailed.finish「読書はまだ終わっていません。ここまでの時間は消えていません。」。「終える」を同じ形（.borderedProminent）の error.retry「もう一度終える」に置き換える。左の「一時停止」か「再開」は押せるまま。次の一手＝もう一度終える（通れば S5。経過は再試行の時刻で止め、S5 の分の欄はその分数）。(4) 60秒未満で終える保存（読書を消す保存）の失敗（AC-66、AC-67、D-58、D-59）：読書は消さず、状態はそのまま（reading なら経過は進む）。(3) と同じ区画、文、「もう一度終える」。押した時点の経過が60秒未満なら記録せず S3（先頭に session.finish.tooShort）、60秒以上なら読書を消さずに S5。(3)(4) とも、再試行が通るか、S4 を離れるか、一時停止か再開が通ると区画は消え、「終える」に戻る。押している間は無効にし、また失敗したら同じ表示のまま VoiceOver に error.saveFailed をもう1回知らせる。エラーの区画は1つだけで、別の操作がまた失敗したら最後の操作の文と再試行に替える。(5) 端末の時計が開始より前に戻ったら経過は 0:00 にし、負の値もエラーも出さない（AC-41） | 通常と同じ（上の理由） | なし（上の理由） | なし。読書中の読書は1件だけで、一部だけ読む経路がない |
| S5 読書を終える | 先頭の見出しに題名（session.finish.book）。「今のページ」（焦点あり、空、placeholder なし）とヒント（session.finish.page.hint。任意であることもこの文で伝える。D-49）。「読んだ時間（分）」（経過の分数が入っている）とヒント（session.finish.minutes.hint）。値が正しい間は「保存」が有効。キーボードが出ている間は、キーボードの上の右端にも「保存」（session.finish.saveKeyboard、.bordered。押せる条件と働きは同じ。D-53） | 今のページが空：そのまま保存できる（AC-10）。ヒントで「入れずに保存もできます。」と伝える | なし。読むデータは開いた時点で決まっている。保存の間は「保存」を無効にし、二重の記録を作らない | (1) 今のページが範囲の外か数字でない：欄の下に session.finish.pageOutOfRange、「保存」は無効、finishing のまま（AC-11、AC-32）。(2) 分が範囲の外か数字でない：session.finish.minutesOutOfRange、同じ（AC-30）。(3) 保存の失敗：先頭にエラーの区画（記号、error.saveFailed、error.saveFailed.session、.bordered のボタン error.retry「もう一度保存」）。ページと分は残す。終えた時刻で止めた経過も変えない（AC-19、AC-35）。2つの「保存」も押せるままで、同じ働き（D-14）。次の一手＝もう一度保存か、キャンセルで読書に戻る。(4) やめる保存の失敗（「キャンセル」か下へのスワイプ。AC-64、AC-65、D-60）：finishing のまま、経過は止まったまま。S5 は閉じない（スワイプで閉じたときは同じ値で開き直す）。同じ先頭の区画で、文は error.saveFailed.cancel「まだ読書に戻っていません。入れた値はそのままです。この画面にいる間の時間は数えません。」、.bordered のボタン error.retry「もう一度読書に戻る」。入れかけのページと分は残す。「キャンセル」と2つの「保存」も押せるまま。次の一手＝もう一度読書に戻るか、そのまま保存。通ったら S5 を閉じて S4（reading。S5 にいた時間は数えない）。区画は1つだけで、保存とやめるのうち最後に失敗した方の文とボタンにする | 通常と同じ（上の理由） | なし（上の理由） | なし。入力の画面で、読むのは読書中の1件だけ |
| S6 記録を消す確認 | alert。題 session.delete.title、本文 session.delete.message（引く分数と、最後のページは変わらないこと、元に戻せないこと）、「キャンセル」（session.delete.cancel）と「記録を消す」（session.delete.confirm。destructive の形は付けない。D-16） | なし。記録の行から開くので、対象は必ず1件ある | なし。読むものがない | 消すことに失敗したら、S6 を閉じてから S7 | 通常と同じ（上の理由） | なし（上の理由） | なし（対象は1件） |
| S7 記録を消せなかった知らせ | 題 error.saveFailed、本文 error.saveFailed.delete、「OK」 | なし（知らせだけ） | なし | これ自体がエラーの表示 | 通常と同じ（上の理由） | なし（上の理由） | なし（知らせだけ） |

### 長い文字、0件、多い件数、取り消せない操作
- 長い題名（PRD 10：題名は100字まで。1字は見た目の1文字＝書記素で数える）：S1 の本の行は3行、S1 の主操作の1行目は2行、S4 の題名は3行まで出し、末尾を「…」で切る。S3 の先頭の題名と、VoiceOver のラベルは全部を出す。S5 の見出しは2行まで。S3 のナビゲーションバーの題名はシステムどおり1行で切れる。題名の中の改行は、保存のときに1つずつ半角の空白1つに置き換わる（PRD 10）ので、表示に改行は出ない。残ったタブは、表示では空白として1行に流す。100字に届いたときの S2 の見せ方は D-45。
- 0件：本0冊は S1 の空の状態、今週0件は「0分」、記録0件は S3 の空の状態（上の表）。どれも責める文を出さない。
- 多い件数（PRD 12：本500冊、記録10,000件）：S1 と S3 は List の行を表示する分だけ作るので、件数で並びは変わらない。冊数と件数の見出しは「500冊」「記録 10,000件」と出す（分、冊、件は端末の地域の書式の桁区切り。ページの数は桁区切りなし。7 の決まり）。検索と並べ替えは置かない（検索は PRD 10 のやらないこと。並べ替えも PRD にない）。
- 長い経過：60分以上は h:mm:ss（例 1:00:00、30:00:00）。AX5 で横に入らなければ、文字の大きさを最小 0.5 倍まで縮めて1行に収め、切らない。
- 取り消せない操作：記録を消すことだけ。必ず S6 で確かめる（AC-16、AC-38）。S6 の本文に、合計から引く分数、最後のページが変わらないこと、元に戻せないことを書く。本を消す操作は 001 にない。
- 取り消せる操作には確認を出さない：S5 のキャンセルと下へのスワイプ（読書は残る。AC-46、AC-48）、一時停止と再開、S4 の戻る（読書は続く）。

## 6. 要素と識別子
決まり
- 文言を出す要素の accessibilityIdentifier は、その文言のキーと同じ名前にする（verifier の T10）。例：誤りの文は session.finish.pageOutOfRange。
  - 例外（識別子は1つで、文のキーが場面で変わるもの）：error.retry（S2 と S5 は error.retry、読み始めは error.retry.start、一時停止は error.retry.pause、再開は error.retry.resume、「終える」（60秒以上と60秒未満）は error.retry.finish、やめる（「キャンセル」と下へのスワイプ）は error.retry.cancel の文。D-52、D-58、D-60）。book.add.titleLimit（形A は book.add.titleLimit、形B は book.add.titleLimit.onSave の文。D-57）。book.openActiveReading（文は action.resume か action.resumePaused）。session.finish.saveKeyboard（文は session.finish.save）。テストは識別子で見つけ、文は 7 のキーで確かめる。
- エラーの区画の文：S2 は error.saveFailed.book、S5 は error.saveFailed.session、読み始めは error.saveFailed.start、一時停止は error.saveFailed.pause、再開は error.saveFailed.resume、「終える」（60秒以上と60秒未満の両方）は error.saveFailed.finish、やめる（「キャンセル」と下へのスワイプ）は error.saveFailed.cancel。どれも識別子はキーと同じ。題はどこでも error.saveFailed。
- 値を出す行（S1 の今週、S3 の値の行）は1つの要素にまとめ、label は項目名、value は値の文字にする。テストは value を読む（T9）。
- 入力の欄（TextField）の value は欄の中の文字。label は欄の名前。
- 状態の名前（T8）：画面の根の入れ物（.accessibilityElement(children: .contain) を付けた NavigationStack の外側）の識別子を、状態に合わせて session.state.idle、session.state.reading、session.state.paused、session.state.finishing のどれか1つにする。S5 の根の入れ物にも session.state.finishing を付ける。入れ物なので VoiceOver は読まず、見た目も変わらない。テストは exists で見る（S5 が出ている間は2つ見つかることがある。どちらも finishing）。
- 経過の表示（T18 の経過の要素）：reading.elapsed の label は読み上げの形（7 の経過の表）。テストは label で経過を読む。見える文字（m:ss、h:mm:ss）と label は、7 の表のとおり1対1で対応する。value は付けない（付けると VoiceOver が「12:30」を時刻として読み上げるおそれがあるため）。
- 記録の行（T18 の新しい記録の行の見分け方）：行の入れ物の識別子は session.row.id.<記録の UUID を小文字にした文字>。行の中に session.row.date、session.row.minutes、session.row.page（ページを入れた記録だけ）がある。行は読み始めた時刻の新しい順に並ぶので、新しい記録は S3 で最初に見つかる「session.row.id.」で始まる要素。子の識別子（session.row.date など）は「session.row.id.」で始まらないので、前方一致で行だけを数えられる。
- 記録の行の分とページ（テストが読む値の決まり。design-reviewer r1 の指摘5）：テストは label を読む。value は付けない（付けると VoiceOver が「32ページ進んだ、32」と2回読むため）。session.row.minutes の label は format.minutes に分を入れた文字（ja「24分」、en「24 minutes」）。session.row.page の label は session.row.pages に読んだページ（PRD 10 の「その記録の読んだページ」。読み返しは0）を入れた文字（ja「32ページ進んだ」、en「32 pages read」。1 は en「1 page read」）。AC-9 の「32」と AC-29 の「0」は、この %lld に入る数。見える文字と label は同じ。
- 本の行：library.book.<本の UUID を小文字にした文字>。label は題名。
- 利用者が入れた文字と計算した値を出す要素（book.title、reading.title、session.finish.book の題名、TextField の value、値の行の value）は文言のキーを持たない。題名と値をそのまま出す。欄と値の行の label は 7 のキー（例：session.finish.minutes の label は session.finish.minutes.label、book.totalTime の label は book.stat.totalTime）。
- 一覧の冊数（T18）：home.bookCount の label（「21冊」）を読む。画面の外の行は XCUITest に出ないことがあるので、行は数えない。
- 保存の後の画面（T18、AC-22）：S3。目印は book.title と、book.startReading か book.resumeReading のどちらか1つが押せる位置にあること（hittable）。
- システムが作る部品（alert のボタン、編集モードの削除ボタン、戻るボタン、EditButton）には、識別子が付かないことがある。付かないときは 7 の文字（ラベル）で探す（下の「CI の出力で決めること」の (b)）。

CI の出力で決めること（この環境に Mac がないため。指揮役の裁定 docs/reviews/001-reading-session-G1-ruling.md の1。どれも G2 の CI の出力で決める。代わりの案を使ったかは ios-engineer が報告に書く）
- (a) 画面の根の入れ物の識別子 session.state.* が XCUITest から見え、子の識別子を上書きしないか。CI の出力で決める。代わりの案は、-UITest で起動したときだけ、画面の隅に 1pt の透明な要素を置き、それに session.state.<名前> の識別子を付ける（XCUITest から見えるよう accessibilityHidden にはしない。-UITest のときだけ置くので、利用者の画面と VoiceOver には出ない）。テストは exists で見る決まりのまま。
- (b) alert のボタン（S6 の「キャンセル」「記録を消す」、S7 の「OK」）、S2 の確認のダイアログ（confirmationDialog）のボタン、編集モードの「削除」、戻るボタン、EditButton に識別子が付くか。CI の出力で決める。代わりの案は、7 の文字で探す（ja と en のどちらで動かすかはテストの設定に合わせる。session.delete.cancel は common.cancel「キャンセル」、session.delete.confirm は session.delete.confirm「記録を消す」、book.add.discard.confirm は「追加せずに閉じる」、S7 は common.ok「OK」）。編集モードの「削除」はシステムの文字で、String Catalog では決められない。
- (c) 記録の行を入れ物（.accessibilityElement(children: .contain)）にしたとき、VoiceOver の行のアクションに「削除」が出るか。CI の出力で決める（XCUITest でアクションの一覧を読めなければ G4 で人が実機で確かめる）。代わりの案は、行の3つの子（session.row.date、session.row.minutes、session.row.page）のそれぞれに accessibilityAction(named:) で「削除」（session.row.delete の文）を付け、同じ S6 を開く。「編集」からも消せるので、消す道は残る。
- (d) S5 を下へスワイプして閉じられるか（AC-48）。CI の出力で決める。代わりの案は、欄の上でなくナビゲーションバーに対して swipeDown() を行う（欄の上だとスクロールやキーボードを閉じる動きになるおそれ）。
- (e) S6 の「キャンセル」（session.delete.cancel）が出るか（AC-38）。S6 は alert にした（D-16）ので出る見込み。CI の出力で決める。代わりの案は、出ない形（confirmationDialog に戻した場合など）なら、確認の外側をタップして閉じる操作を「消さない」とする（PRD の AC-38 の When の注記と同じ）。テストはどちらか1つの形で書く。S2 の確認のダイアログ（confirmationDialog。D-18）も同じで、「キャンセル」が出ない形なら、外側をタップするとダイアログだけが閉じ、S2 の入力は残る（AC-53 は「追加せずに閉じる」の側だけを使うので、AC の手順は変わらない）。
- (f) 題名の上限を変換中の文字に当てない作り（PRD 10）。tech-lead の設計メモで形A か形B を決め、CI の出力で確かめる。代わりの案は形B（保存のときに切る）。見せ方は 1 と D-57、部品は 3 の S2。
- (g) AC-49 の、S2 を閉じてから追加した本の S3 を push する動き（push が落ちないか）。AC-54 の、読み込みの失敗を画面に出せるか（@Query と ModelContainer の失敗の扱い）。どちらも作りは tech-lead が決め、CI の出力で確かめる。画面の形は 1 と 5 のまま変えない。

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
| S1 | 主操作（reading か paused） | home.resumeReading | 「坊っちゃん、読書に戻る」か「坊っちゃん、一時停止中の読書に戻る」（home.primary.a11y と action.resume か action.resumePaused） |
| S1 | 読み込み中の形 | home.loading | 「読み込み中」（1秒を超えて ProgressView を出したとき） |
| S1、S3 | 読み込みの失敗の題、文、ボタン | error.loadFailed.title、error.loadFailed.message、error.loadFailed.retry | 文のとおり（題は見出し）。ボタンは「もう一度読み込む」。このとき library.addBook、library.empty.*、home.weekTotal、home.bookCount、library.book.*、home.startReading、home.resumeReading は出さない（D-44） |
| S1、S3 | 読み込みの失敗の記号 exclamationmark.triangle | なし | 読まない（飾り。何が起きたかは題で伝える） |
| S1、S3、S4 | 読み始め、一時停止、再開、「終える」の保存の失敗：エラーの区画の題 | error.saveFailed | 「変更を保存できませんでした」（出たときに1回知らせる） |
| S1、S3 | 読み始めの保存の失敗：エラーの区画の文 | error.saveFailed.start | 文のとおり |
| S1 | 読み始めの再試行（主操作の場所。home.startReading と置き換え） | error.retry | 「坊っちゃん、もう一度読み始める」（home.primary.a11y と error.retry.start。題名が先頭） |
| S3 | 読み始めの再試行（主操作の場所。book.startReading と置き換え） | error.retry | 「もう一度読み始める」（error.retry.start） |
| S1、S3、S4 | エラーの区画の記号 exclamationmark.triangle | なし | 読まない（何が起きたかは題で伝える） |
| S2 | 題名の見出し（Section の header） | なし | 「題名（必須）」（book.add.titleField。見出し） |
| S2 | 題名の欄 | book.add.title | label「題名（必須）」（book.add.titleField）、value は入れた文字（空のときは空。placeholder なし） |
| S2 | 題名の上限の知らせ（形A は100字のとき、形B は100字を超えている間だけ） | book.add.titleLimit | 文のとおり（形A は book.add.titleLimit、形B は book.add.titleLimit.onSave の文。出たときに1回読み上げる） |
| S2 | 総ページ数の見出し | なし | 「総ページ数（任意）」（book.add.totalPagesField。見出し） |
| S2 | 総ページ数の欄 | book.add.totalPages | label「総ページ数（任意）」（book.add.totalPagesField）、value は入れた文字（空のときは空。placeholder なし） |
| S2 | 総ページ数のヒント | book.add.totalPagesHint | 文のとおり |
| S2 | 総ページ数の誤りの文 | book.add.totalPagesOutOfRange | 文のとおり（出たときに1回読み上げる） |
| S2 | キャンセル | book.add.cancel | 「キャンセル」 |
| S2 | 追加 | book.save | 「追加」（無効のときはシステムが「使用不可」を足す） |
| S2 | 追加せずに閉じる（確認のダイアログ） | book.add.discard.confirm | 「追加せずに閉じる」 |
| S2、S5 | エラーの区画の題 | error.saveFailed | 「変更を保存できませんでした」 |
| S2 | エラーの区画の文 | error.saveFailed.book | 文のとおり |
| S2、S5 | もう一度保存（エラーの区画の中。.bordered） | error.retry | 「もう一度保存」（error.retry） |
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
| S3 | 記録の行の分 | session.row.minutes | 「24分」（format.minutes。テストは label を読む。value なし） |
| S3 | 記録の行のページ（入れた記録だけ） | session.row.page | 「32ページ進んだ」（session.row.pages。テストは label を読む。value なし） |
| S3 | 行のスワイプの削除 | session.row.delete | 「削除」 |
| S3 | 編集（記録が1件以上のとき） | book.edit | 「編集」（システム） |
| S3 | 主操作（idle） | book.startReading | 「72ページから読む」「続きを読む」「読み始める」のどれか |
| S3 | 主操作（この本が読書中） | book.resumeReading | reading（finishing をやめた後を含む）は「読書に戻る」（action.resume）、paused は「一時停止中の読書に戻る」（action.resumePaused） |
| S3 | 主操作が無効の理由（別の本が読書中） | book.start.busy | 文のとおり。「読書に戻る」と無効の主操作の前に読む |
| S3 | 読書中の本へ行く（別の本が読書中のとき。.bordered） | book.openActiveReading | 「読書に戻る」か「一時停止中の読書に戻る」（action.resume か action.resumePaused。読書中の本の状態による） |
| S6 | alert の題と本文 | session.delete.title、session.delete.message | 文のとおり |
| S6 | 記録を消す | session.delete.confirm | 「記録を消す」 |
| S6 | キャンセル（AC-38 の「消さない」） | session.delete.cancel | 「キャンセル」。alert なのでいつも出る見込み。出ない形のときの「消さない」は確認の外側をタップ（上の「CI の出力で決めること」の (e)、PRD の AC-38 の注記） |
| S7 | 題、本文、OK | error.saveFailed、error.saveFailed.delete、なし | 文のとおり、「OK」 |
| S4 | 題名 | reading.title | 題名（見出し） |
| S4 | 始めたページ | reading.fromPage | 「72ページから」 |
| S4 | 経過 | reading.elapsed | 「12分30秒」（7 の経過の表。value なし） |
| S4 | 状態の文字 | reading.state | 「読書中」か「一時停止中」 |
| S4 | 一時停止 | reading.pause | 「一時停止」 |
| S4 | 再開 | reading.resume | 「再開」 |
| S4 | 終える | reading.finish | 「終える」 |
| S4 | 一時停止の保存の失敗：エラーの区画の文 | error.saveFailed.pause | 文のとおり |
| S4 | 再開の保存の失敗：エラーの区画の文 | error.saveFailed.resume | 文のとおり |
| S4 | 一時停止か再開の再試行（左のボタンの場所。reading.pause か reading.resume と置き換え） | error.retry | 「もう一度一時停止」か「もう一度再開」（error.retry.pause か error.retry.resume） |
| S4 | 「終える」の保存の失敗（60秒以上と60秒未満）：エラーの区画の文 | error.saveFailed.finish | 文のとおり |
| S4 | 「終える」の再試行（右のボタンの場所。reading.finish と置き換え。.borderedProminent） | error.retry | 「もう一度終える」（error.retry.finish） |
| S5 | キャンセル（PRD の「やめる」） | session.finish.cancel | 「キャンセル」 |
| S5 | 保存（ツールバーの右。.borderedProminent） | session.finish.save | 「保存」 |
| S5 | 保存（キーボードの上の右端。キーボードが出ている間だけ。.bordered） | session.finish.saveKeyboard | 「保存」（session.finish.save の文。押せる条件と働きは session.finish.save と同じ） |
| S5 | 題名の見出し | session.finish.book | 題名（見出し） |
| S5 | 今のページの欄 | session.finish.page | label「今のページ」、value は入れた文字 |
| S5 | 今のページのヒント | session.finish.page.hint | 文のとおり（キーは session.finish.page.hint か session.finish.page.hintFirst） |
| S5 | 今のページの誤りの文 | session.finish.pageOutOfRange | 文のとおり（出たときに1回読み上げる） |
| S5 | 読んだ時間の欄 | session.finish.minutes | label「読んだ時間（分）」、value は入れた文字（例「10」） |
| S5 | 読んだ時間のヒント | session.finish.minutes.hint | 文のとおり |
| S5 | 読んだ時間の誤りの文 | session.finish.minutesOutOfRange | 文のとおり（出たときに1回読み上げる） |
| S5 | エラーの区画の文 | error.saveFailed.session | 文のとおり |
| S5 | やめる保存の失敗：エラーの区画の文 | error.saveFailed.cancel | 文のとおり |
| S5 | やめる保存の再試行（エラーの区画の中。.bordered。「もう一度保存」と同じ場所） | error.retry | 「もう一度読書に戻る」（error.retry.cancel） |

PRD の仮の名前（library.addBook、book.save、home.startReading、home.resumeReading、book.startReading、book.progress、book.totalPages、home.weekTotal、session.row.page、error.retry、session.finish.cancel）は、すべてそのまま使った。足した名前は上の表のとおり。

AC-47〜AC-61 で使う名前（PRD 11 の識別子と文言。識別子は上の表、キーは 7 にある。括弧の中は 7 のキー）
- AC-47：session.finish.minutes（label は session.finish.minutes.label、value「15」）、session.finish.cancel（common.cancel）、reading.finish（reading.finish）、session.state.finishing
- AC-48：session.finish.page（label は session.finish.page.label）、シートの下へのスワイプ（識別子なし。session.finish.cancel と同じ動き）、reading.elapsed（label は reading.elapsed.ms「10分0秒」「10分1秒」）、session.finish.save（0個）、book.sessionCount（book.sessionCount「記録 2件」）、session.state.reading
- AC-49：book.add.title（label は book.add.titleField）、book.save（book.save）、book.title（題名そのもの。キーなし）、book.startReading（「こころ」は記録0件で最後のページ0なので action.start「読み始める」）
- AC-50：home.startReading（home.primary.a11y と action.*）、reading.finish、session.finish.save、book.title、book.sessionCount「記録 2件」、session.state.idle
- AC-51：home.startReading、reading.finish、session.finish.save（0個）、book.title、session.finish.tooShort（session.finish.tooShort）、book.sessionCount「記録 1件」、アラートは出さない、session.state.idle
- AC-52：book.resumeReading（action.resume「読書に戻る」、action.resumePaused「一時停止中の読書に戻る」）、book.startReading と book.start.busy（0個。book.start.busy のキーは別の本が読書中のときだけ使う）、session.finish.cancel
- AC-53：book.add.title、book.add.cancel（common.cancel）、book.add.discard.confirm（book.add.discard.confirm。ダイアログの題は book.add.discard.title）、home.bookCount（home.bookCount「1冊」）、library.book.<UUID>（label は題名）
- AC-54：error.loadFailed.title、error.loadFailed.message、error.loadFailed.retry（どれも同じ名前のキー）。0個のもの：library.empty.title、home.bookCount、home.weekTotal、home.startReading（D-44 で library.addBook、home.resumeReading、library.book.* も出さない）
- AC-55：error.loadFailed.retry、error.loadFailed.title（0個）、home.bookCount「2冊」、book.totalTime（label は book.stat.totalTime、value は format.minutes「60分」「40分」）
- AC-56：home.startReading、book.startReading（どちらも失敗の間は0個）、error.saveFailed（error.saveFailed）、error.saveFailed.start（error.saveFailed.start）、error.retry（S1 は home.primary.a11y と error.retry.start、S3 は error.retry.start）、session.state.idle、reading.elapsed（0個）、book.sessionCount「記録 1件」
- AC-57：error.retry、session.state.reading、reading.title、reading.elapsed（label は reading.elapsed.ms「0分0秒」「0分1秒」）、error.saveFailed（0個）
- AC-58：reading.pause（失敗の間は0個）、error.saveFailed、error.saveFailed.pause、error.retry（error.retry.pause）、session.state.reading、reading.state（reading.state.reading）、reading.elapsed（「11分0秒」「11分1秒」）、reading.finish
- AC-59：error.retry、session.state.paused、reading.state（reading.state.paused）、reading.resume、reading.elapsed（「11分0秒」「11分1秒」）、error.saveFailed（0個）
- AC-60：reading.resume（失敗の間は0個）、error.saveFailed、error.saveFailed.resume、error.retry（error.retry.resume）、session.state.paused、reading.elapsed（「5分0秒」）
- AC-61：error.retry、session.state.reading、reading.pause、reading.elapsed（「6分0秒」「6分1秒」）、error.saveFailed（0個）
- AC-62：reading.finish（失敗の間は0個）、error.saveFailed、error.saveFailed.finish、error.retry（error.retry.finish）、session.finish.save と session.state.finishing（0個）、(a) session.state.reading と reading.elapsed（「11分0秒」「11分1秒」）、(b) session.state.paused と reading.elapsed（「5分0秒」）、book.sessionCount「記録 1件」
- AC-63：error.retry、session.state.finishing、session.finish.save（1個）、session.finish.minutes（value は (a)「11」、(b)「5」）、error.saveFailed（0個）
- AC-64：reading.finish、session.finish.page（value「72」）、session.finish.cancel（common.cancel）、error.saveFailed、error.saveFailed.cancel、error.retry（error.retry.cancel）、session.state.finishing、session.state.reading（0個）、session.finish.save（1個）、session.finish.minutes（value「10」）
- AC-65：error.retry、session.finish.save（0個）、session.state.reading、reading.elapsed（「10分0秒」「10分1秒」）、error.saveFailed（0個）
- AC-66：reading.finish（失敗の間は0個）、error.saveFailed、error.saveFailed.finish、error.retry（error.retry.finish）、session.state.reading、reading.elapsed（「0分40秒」「0分41秒」）、session.finish.tooShort と session.finish.save（0個）
- AC-67：error.retry、session.state.idle、book.title「坊っちゃん」、session.finish.tooShort（1個）、book.sessionCount「記録 1件」、reading.elapsed と error.saveFailed（0個）、アラートは0個

## 7. 文言
決まり
- 文は「です・ます」で短く。ボタンは動詞。英語のボタンは動詞で始め（例「Return to Reading」。D-55）、ボタンと題は title-style capitalization、文は sentence case。感嘆符、「私たち」「we」、「おっと」「oops」を使わない（R-8、調査の 5）。
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
| action.resume | 読書に戻る | Return to Reading | S1 と S3 の主操作（reading。finishing をやめた後を含む。AC-52）、S3 の book.openActiveReading（別の本が reading のとき） |
| action.resumePaused | 一時停止中の読書に戻る | Return to Paused Reading | S1 と S3 の主操作（paused。AC-52）、S3 の book.openActiveReading（別の本が paused のとき） |
| home.primary.a11y | %1$@、%2$@ | %1$@, %2$@ | S1 の主操作と、そこに出る error.retry の VoiceOver のラベル（1つ目は題名、2つ目は上の action.* か error.retry.start） |
| common.loading | 読み込み中 | Loading | S1、S3 の ProgressView |
| book.add.navTitle | 本を追加 | Add Book | S2 の題 |
| book.add.titleField | 題名（必須） | Title (Required) | S2 の題名の欄の見出し（Section の header）と、欄の VoiceOver のラベル（必須であることを見出しで伝える。placeholder は置かない。D-49） |
| book.add.totalPagesField | 総ページ数（任意） | Total Pages (Optional) | S2 の総ページ数の欄の見出しと、欄の VoiceOver のラベル（D-49） |
| book.add.totalPagesHint | 入れると、進み具合を％で出します。 | Add this to see your progress as a percentage. | S2 の総ページ数の下 |
| book.add.totalPagesOutOfRange | 1から9999までの数字で入れてください。 | Enter a number from 1 to 9999. | S2 の総ページ数の下（範囲の外か数字でないとき。ヒントと入れ替える） |
| book.add.titleLimit | 題名は%lld字までです。超えた分は入りません。 | one: Titles can have up to %lld character. Extra characters aren't added. ／ other: Titles can have up to %lld characters. Extra characters aren't added. | S2 の題名の欄の下（形A。欄の字数が上限の100字に届いている間だけ。%lld は100。D-45、D-57） |
| book.add.titleLimit.onSave | 題名は%lld字までです。超えた分は保存しません。 | one: Titles can have up to %lld character. Extra characters won't be saved. ／ other: Titles can have up to %lld characters. Extra characters won't be saved. | S2 の題名の欄の下（形B。整えたあとの字数が100を超えている間だけ。%lld は100。識別子は book.add.titleLimit。D-57） |
| book.save | 追加 | Add | S2 の確定のボタン |
| common.cancel | キャンセル | Cancel | S2 と S5 の左上、S6 の alert の取り消し |
| book.add.discard.title | この本を追加せずに閉じますか？ | Close without adding this book? | S2 の確認のダイアログの題 |
| book.add.discard.confirm | 追加せずに閉じる | Close Without Adding | S2 の確認のダイアログ（destructive） |
| error.saveFailed | 変更を保存できませんでした | Couldn't Save Changes | S2、S5 のエラーの区画の題、S1、S3、S4 のエラーの区画の題（読み始め、一時停止、再開、「終える」の保存の失敗）、S7 の題 |
| error.saveFailed.book | 入れた題名はそのままです。もう一度保存してください。 | What you entered is still here. Try saving again. | S2 のエラーの区画 |
| error.saveFailed.session | 読書は消えていません。読んだ時間も変わっていません。もう一度保存してください。 | Your reading session is still here, and the time hasn't changed. Try saving again. | S5 のエラーの区画 |
| error.saveFailed.delete | 記録は消えていません。もう一度消してください。 | The session wasn't deleted. Try deleting it again. | S7 の本文 |
| error.saveFailed.start | 読書はまだ始まっていません。時間は数えていません。 | Your reading session hasn't started, and the timer isn't running. | S1、S3 のエラーの区画の文（読み始めの保存の失敗。AC-56） |
| error.saveFailed.pause | 読書は止まっていません。時間は数え続けています。 | Your reading isn't paused. The timer is still running. | S4 のエラーの区画の文（一時停止の保存の失敗。AC-58） |
| error.saveFailed.resume | 読書は一時停止のままです。時間は止まっています。 | Your reading is still paused. The timer is stopped. | S4 のエラーの区画の文（再開の保存の失敗。AC-60） |
| error.saveFailed.finish | 読書はまだ終わっていません。ここまでの時間は消えていません。 | Your reading session hasn't ended. The time so far hasn't been lost. | S4 のエラーの区画の文（「終える」の保存の失敗。経過60秒以上と60秒未満の両方。AC-62、AC-66） |
| error.saveFailed.cancel | まだ読書に戻っていません。入れた値はそのままです。この画面にいる間の時間は数えません。 | You haven't returned to reading yet. What you entered is still here. Time on this screen isn't counted. | S5 のエラーの区画の文（やめる保存の失敗。「キャンセル」と下へのスワイプ。AC-64） |
| error.retry | もう一度保存 | Save Again | S2 と S5 のエラーの区画のボタン（識別子 error.retry） |
| error.retry.start | もう一度読み始める | Try Starting Again | S1、S3 の主操作の場所の再試行（識別子 error.retry。AC-56、AC-57） |
| error.retry.pause | もう一度一時停止 | Try Pausing Again | S4 の左のボタンの場所の再試行（識別子 error.retry。AC-58、AC-59） |
| error.retry.resume | もう一度再開 | Try Resuming Again | S4 の左のボタンの場所の再試行（識別子 error.retry。AC-60、AC-61） |
| error.retry.finish | もう一度終える | Try Finishing Again | S4 の右のボタンの場所の再試行（識別子 error.retry。「終える」と60秒未満で終える、の両方。AC-62、AC-63、AC-66、AC-67） |
| error.retry.cancel | もう一度読書に戻る | Try Returning to Reading Again | S5 のエラーの区画のボタン（識別子 error.retry。やめる保存の失敗。AC-64、AC-65） |
| error.loadFailed.title | 本と記録を読み込めませんでした | Couldn't Load Your Books | S1、S3 の読み込みの失敗（AC-54） |
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
| session.row.pages | %lldページ進んだ | one: %lld page read ／ other: %lld pages read | S3 の記録の行のページ（その記録で進んだページの数。読み返しは0。D-54） |
| session.row.delete | 削除 | Delete | S3 の行のスワイプ |
| book.start.busy | 「%@」を読書中です。その読書を終えると、この本で読み始められます。 | You're reading “%@.” Finish that session to start this book. | S3 の主操作の上（別の本が読書中） |
| session.finish.tooShort | 1分未満だったので、記録しませんでした。 | That was under a minute, so it wasn't saved. | S3 の先頭（60秒未満で終えた直後） |
| session.saved.announcement | %lld分を記録しました。 | one: Saved %lld minute. ／ other: Saved %lld minutes. | 読書を保存して S3 に出たときの VoiceOver の知らせ（画面には出さない） |
| session.delete.title | この記録を消しますか？ | Delete this session? | S6 の alert の題 |
| session.delete.message | 合計時間から%lld分を引きます。最後のページは変わりません。消した記録は元に戻せません。 | one: %lld minute will be subtracted from the total time. The last page won't change. You can't undo this. ／ other: %lld minutes will be subtracted from the total time. The last page won't change. You can't undo this. | S6 の alert の本文 |
| session.delete.confirm | 記録を消す | Delete Session | S6 の alert の消すボタン（destructive の形は付けない。D-16） |
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
| session.finish.save | 保存 | Save | S5 の確定のボタン（ツールバーの右と、キーボードの上の session.finish.saveKeyboard） |

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
  - 色：color.background.screen（S4）、color.background.grouped（S1、S2、S3、S5、下端の主操作の帯）、color.background.row、color.text.primary（17pt 以下の文字のすべて。List、Form、LabeledContent、ContentUnavailableView、ProgressView が既定で secondaryLabel にするセクションの見出し、footer、値、文、ラベルも .foregroundStyle(color.text.primary) に替える。D-48）、color.text.secondary（S4 の一時停止中の経過だけ。D-24）、color.separator、color.accent.fill（.borderedProminent の塗り：S1、S3 の主操作とその場所の error.retry、S1 の「本を追加」と「もう一度読み込む」、S4 の「終える」、S2 と S5 の確定のボタン。D-46、D-47）、color.accent.text（AccentColor：システムが付ける文字のボタン、alert のボタン、カーソル）、color.text.onAccent（塗りの上のラベル）、color.status.error（誤りとエラーの区画の記号だけ）、color.fill.secondaryButton（.bordered：S4 の一時停止と再開とその場所の error.retry、S2 と S5 のエラーの区画の error.retry、S5 のキーボードの上の「保存」、S3 の book.openActiveReading）。color.text.placeholder は使わない（D-49）。押せない文字にアクセントを使わない（D-50）。
  - 文字と、画面ごとの大きさの段（4段まで。B-4）：
    - S1：type.navTitle（.largeTitle）、type.body と type.primaryTitle（17pt の段。エラーの区画の題も）、type.secondary（.subheadline。主操作の2行目）、type.note（.footnote。冊数の見出し、エラーの区画の文）。4段。
    - S2：システムの inline の題、type.body（欄）、type.note（ヒント、誤り、題名の上限の知らせ）。エラーの区画の題は .headline（17pt の段）。3段。
    - S3：type.bookHeading（.title2 の太字）、type.body（値と行の分とページ、主操作、「読書に戻る」）と type.primaryTitle（エラーの区画の題）、type.secondary（記録の日付、60秒未満の知らせ）、type.note（見出し、無効の理由、エラーの区画の文）。4段。
    - S4：type.readingTitle（.title3）、type.secondary（「72ページから」、状態の文字、エラーの区画の文）、type.timer（.largeTitle、等幅の数字）、type.body（ボタン）と type.primaryTitle（エラーの区画の題）。4段。
    - S5：S2 と同じ3段。
  - 余白：S4 は、題名と「72ページから」の間 space.s、題名のまとまりと経過の間 space.l、経過と状態の間 space.s、状態の文字とエラーの区画の間 space.m、経過のまとまり（エラーの区画を含む）とボタンの間は最小 space.xl（残りは Spacer）、画面の左右と2つのボタンの間 space.m。S1 と S3 の下端の主操作は、左右 space.m、上 space.xs、下は安全領域まで。帯の中のエラーの区画、理由の文、「読書に戻る」と主操作の間は space.xs。主操作の1行目と2行目の間 space.xxs。記号と文字の間 space.xxs。記録の行の分とページの間 space.xs。List と Form の中はシステムの既定。
  - そろえる縦の線（B-3）：S1、S2、S3、S5 は、リストの行の文字の左端（システムの既定の余白）を1本の線にし、下端の主操作の左右の端は画面の端から space.m。S4 は画面の中央の縦の線に、題名、「72ページから」、経過、状態をそろえ、ボタンは左右 space.m の間に2つ並べる。
- 新しく足すトークン（意味の名前と、ライト、ダーク、高コントラストの値）：color.accent.fill（しおりの色・塗り）ライト #7A4427、ダーク #9F5833、コントラストを上げる（ライト）#5E3219、（ダーク）#E3B994。color.accent.text（しおりの色・文字。AccentColor）ライト #7A4427、ダーク #CF9D78、コントラストを上げる（ライト）#5E3219、（ダーク）#E3B994。color.text.onAccent ライト #FFFFFF、ダーク #FFFFFF、コントラストを上げる（ライト）#FFFFFF、（ダーク）#000000。理由と、G2 の CI で替える代わりの値は tokens.md の 1。ほかの色はシステムの色。前の版の color.accent は、この2つに分けてなくした（G1 r1 の指摘1、3）。
- 使う SF Symbols の名前（すべて developer.apple.com で名前を確かめた。文字と並べるときは Label で文字と同じ大きさと太さにする）：
  - plus：S1 の「本を追加」（HIG Icons の Standard icons の Add。https://developer.apple.com/design/human-interface-guidelines/icons ）
  - books.vertical：S1 の空の状態の記号（WWDC24「Elevate your tab and sidebar experience in iPadOS」のコードの Tab("Library", systemImage: "books.vertical")。https://developer.apple.com/videos/play/wwdc2024/10147/ ）
  - trash：S3 の行のスワイプの「削除」（HIG Icons の Delete）。スワイプのボタンは記号だけを見せ、「削除」はラベルとして読み上げる。塗りと記号の色はシステム（tokens.md 5 の C1）
  - exclamationmark.triangle：誤りの文とエラーの区画（S2、S5、S1、S3 の帯、S4）の印、読み込みの失敗の記号（HIG Alerts の本文「a caution symbol like `exclamationmark.triangle`」。控えめに使えという文に従い、誤りのときだけ出す）
  - システムが自分で出す記号（戻る、行の「＞」、iOS の版によってキャンセルと確定が xmark と checkmark で出る場合）は、名前を指定しない。xmark と checkmark は HIG Icons の Cancel と Done にある。
  - 塗りの記号（.fill）は使わない（選ぶ状態とタブがないため）。
- 性格語が表れている場所（語ごとに画面と要素）：
  - 静か：S4 に置くのは6つの要素だけで、色の面と動きがない（D-21、D-22）。S4 で色があるのは「終える」の塗りだけで、状態の文字も黒か白（D-50）。読書を保存した後に祝う表示を出さない（D-6）。アクセントの塗りは1画面に1つ（D-9）。
  - 確か：S5 のヒントに経過の分数を出す（session.finish.minutes.hint）。保存の失敗の文で、読書と時間が残っていることを言う（error.saveFailed.session）。S6 の本文で、引く分数と最後のページが変わらないことを言う（session.delete.message）。起動したら読書中の画面に戻る（D-25）。読み込めなかったときは、端末の中の記録を消していないことを言う（error.loadFailed.message、D-44）。題名が100字に届いたら、超えた分が入らない（形B は保存しない）ことを欄の下で言う（book.add.titleLimit、D-45、D-57）。読み始め、一時停止、再開の保存に失敗したら、時間を数えているかどうかをそのまま言う（error.saveFailed.start、error.saveFailed.pause、error.saveFailed.resume、D-51）。記録の行は「32ページ進んだ」と量で言う（D-54）。
  - すぐ：S1 の主操作が1回で読み始めになる（home.startReading、AC-5）。S2 は開いた時点で題名の欄に焦点（D-10）。S5 は開いた時点で今のページの欄に数字のキーボードがあり、その真上の「保存」を親指で押せる（D-11、D-53）。本を追加したらその本の S3 に出る（D-5）。別の本の S3 からも、読書中の本へ1回で行ける（D-33）。
  - おだやか：今週0件は「0分」とだけ出す（AC-36、D-20）。60秒未満は責めない知らせ（session.finish.tooShort）。S5 はキャンセルで読書に戻れ、分を短く直せる（D-3、AC-12）。誤りの文は「〜で入れてください」の形で、責めない（D-13）。保存の失敗の後は、押したボタンと同じ場所で「もう一度〜」を押すだけで済む（D-51、D-52）。
- 差をつける点が表れている場所：
  - 差1「しおりの往復」：開く＝S1 の主操作（1行目に前の本の題名、2行目に「72ページから読む」）と、S4 の「72ページから」。挟む＝S5 を開いた時点で今のページの欄に焦点と数字のキーボード、キーボードの真上の「保存」（D-53）、ヒント「前回は40ページでした。入れずに保存もできます。」。挟んだページが、次に S1 を開いたときの主操作の2行目に出る。
  - 差2「読む間、画面は退く」：S4。6つの要素、大きな等幅の経過、アクセントは「終える」の塗りだけ。
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
  - S1：下端の主操作の帯をやめ、リストの最初の行に主操作を置く（題名は2行まで、2行目は切らない）。読み始めの保存に失敗したときは、その行の中で主操作の場所の上にエラーの区画（記号と題、文）を縦に置き、主操作の場所は error.retry。今週の行は「今週」の下に「60分」を置く縦並び。本の行の題名は3行まで。
  - S2：欄は1行の幅いっぱいのまま。見出し、ヒント、誤りの文、題名の上限の知らせは折り返す。
  - S3：下端の主操作の帯をやめ、先頭の題名のすぐ下に主操作を置く。その上に、無効の理由と「読書に戻る」（別の本が読書中のとき）か、エラーの区画（読み始めの保存に失敗したとき）を縦に置く。値の行は、項目名の下に値を置く縦並び。記録の行は、日付、分、ページを縦に3行で並べる。
  - S4：全体を ScrollView に入れる。「一時停止」と「終える」の横並びを縦並びにし、上に「終える」、下に「一時停止」（HIG Alerts「at the top in a stack of buttons」）。エラーの区画は状態の文字のすぐ下で、文は折り返す。一時停止と再開の error.retry は「一時停止」と同じ下の位置、「もう一度終える」（error.retry）は「終える」と同じ上の位置。経過は1行のまま、入らなければ最小 0.5 倍まで縮める。題名は3行まで。
  - S5：「今のページ」「読んだ時間（分）」の項目名の下に欄を置く縦並び。キーボードの上の「保存」はシステムのツールバーが大きさを合わせる。
  - S6、S7：システムの alert が並べ替える。
- 色だけで区別していないか：
  - 一時停止中は、文字「一時停止中」とボタン「再開」でも示す（D-24）。
  - 誤りと保存の失敗は、記号 exclamationmark.triangle と文で示し、色は記号だけ（D-37）。
  - 主操作は塗りのほかに、ボタンの形と位置（下端）と動詞のラベルで分かる。無効の主操作は、システムの無効の見た目と、その上の理由の文で示す。
  - 状態の文字（「読書中」「一時停止中」）に色を使わない（D-50）。
  - 記録の行と本の行に色は使わない。
- 動きを減らす設定、透明度を下げる設定のとき：
  - 動きを減らす：アプリ独自の動きがない（経過の数字は動きなしで書き換える。祝う動きがない。エラーの区画は動きなしで出す）。画面の切り替えはシステムの push と sheet で、システムが設定に合わせる。変えるものはない。
  - 透明度を下げる：内容の層に半透明の部品がなく、下端の主操作の帯も不透明な color.background.grouped。システムのバー、ツールバー（キーボードの上を含む）、シート、alert はシステムが不透明にする。変えるものはない。
  - コントラストを上げる：color.accent.fill、color.accent.text、color.text.onAccent は高コントラストの値に切り替わる（tokens.md 1）。ダークの塗りは明るい #E3B994 に、ラベルは黒になる。ほかはシステムの色が切り替わる。
  - ダーク：システムの設定に従う（D-27）。S4 は寝る前の暗い部屋で使うので、背景は color.background.screen（ダークで黒）、明るい面は「終える」の塗り（#9F5833。暗い栗色）だけ。
- VoiceOver の読み上げ順（見た目の順。読み上げの順を入れ替えない）：
  - S1（本が1冊以上）：「読書」（見出し）→「本を追加」→「今週、60分」→「21冊」（見出し）→ 本の行（題名）を上から → 主操作「坊っちゃん、72ページから読む」。AX サイズでは主操作が「今週」の前に来る。
  - S1（読み始めの保存に失敗）：… 本の行 →「変更を保存できませんでした」→「読書はまだ始まっていません。時間は数えていません。」→「坊っちゃん、もう一度読み始める」。記号は読まない。
  - S1（本が0冊）：「読書」→「本がまだありません」（見出し）→ 文 →「本を追加」。記号は読まない。
  - S1（読み込みの失敗）：「読書」→「本と記録を読み込めませんでした」（見出し）→ 文 →「もう一度読み込む」。記号は読まない。「本を追加」はない（D-44）。
  - S2：「キャンセル」→「本を追加」（見出し）→「追加」→（エラーの区画：題 → 文 →「もう一度保存」）→「題名（必須）」（見出し）→「題名（必須）」の欄 →（題名の上限の知らせ）→「総ページ数（任意）」（見出し）→「総ページ数（任意）」の欄 → ヒントか誤りの文。
  - S3：戻る →（ナビゲーションバーの題名）→「編集」→ 題名（見出し）→（60秒未満の知らせ）→「最後のページ、72」→「進み具合、24%」→「総ページ数、300」→「合計時間、60分」→「記録 3件」（見出し）→ 記録の行（日付 → 分 →「32ページ進んだ」）を新しい順に →（無効の理由 →「読書に戻る」）か（エラーの区画の題 → 文）→ 主操作（か error.retry「もう一度読み始める」）。記録の行のどの要素にいても、アクションに「削除」が出る（スワイプの代わり。出ないときの代わりの案は 6 の (c)。「編集」からも消せる）。
  - S4：戻る → 題名（見出し）→「72ページから」→「12分30秒」→「読書中」→（エラーの区画の題 → 文）→「一時停止」（か「もう一度一時停止」「再開」「もう一度再開」）→「終える」（か「もう一度終える」）。経過は、指を置いたときに今の値を1回読むだけ。毎秒の読み上げと知らせは出さない（PRD 12）。
  - S5：「キャンセル」→「読書を終える」（見出し）→「保存」→（エラーの区画：題 → 文 →「もう一度保存」か「もう一度読書に戻る」）→ 題名（見出し）→「今のページ」の欄 → ヒントか誤りの文 →「読んだ時間（分）」の欄 → ヒントか誤りの文 →（キーボードの上の「保存」）。
  - S6（alert）：「この記録を消しますか？」→ 本文 →「キャンセル」→「記録を消す」（並びはシステム）。
  - 知らせ（AccessibilityNotification.Announcement）：読書を保存して S3 に出たとき session.saved.announcement を1回。60秒未満で S3 に出たとき session.finish.tooShort を1回。誤りの文が出たとき、その文を1回（同じ誤りが続く間は繰り返さない）。保存に失敗したとき（S2、S5、読み始め、一時停止、再開、「終える」、やめる。下へのスワイプの失敗で S5 を開き直したときも）error.saveFailed を1回。再試行がまた失敗したときも1回（画面が変わらないので、失敗したことを知らせる）。題名の上限の知らせが出たとき、その文を1回（出たまま打ち続けても繰り返さない）。
  - 飾りの記号（books.vertical、エラーの区画と読み込みの失敗の exclamationmark.triangle）は読まない。ラベルは、画面に見える文字を先頭に入れる（S1 の主操作と、その場所の error.retry は題名から始まる）。
- 英語が長くなったとき（疑似言語 Double-Length で確かめる画面。G3 で S1〜S7 の全画面を Double-Length で撮る）：
  - 7 の72キーのうち、英語が日本語の2倍を超えるキーは37（数え方：7 の表の「日本語」と「英語」の列の文字数を python3 の len で比べた。複数形は other の形だけを数え、（ ）の中の注は除いた。%lld などの書式の記号もそのまま数えた）。下の一覧はその37キーのすべてと、2倍に届かないが同じ行に並ぶ session.row.pages（1.5倍）。置き場所ごとの対応：
    - 1行の部品の中に入るもの：home.title「Reading」（大きい見出し。1行に収まる）、reading.state.reading「Reading」、session.finish.navTitle「Finish Reading」（シートの題。システムが切る）、book.stat.totalTime、book.stat.totalPages（値の行の項目名。AX サイズと幅が足りないときは値と縦に並べ替える）、home.weekTotal.label「This Week」（同じ）。
    - ボタン：action.resume「Return to Reading」、action.resumePaused「Return to Paused Reading」、action.continue、action.start（S1、S3 の主操作。2行目は切らずに折り返す）、reading.resume「Resume」、error.retry.pause「Try Pausing Again」、error.retry.resume「Try Resuming Again」、error.retry.finish「Try Finishing Again」（S4 の横並び。収まらなければ ViewThatFits で縦並び）、error.retry.cancel「Try Returning to Reading Again」（S5 のエラーの区画の .bordered。切らずに折り返す）、session.delete.confirm「Delete Session」（alert。システムが縦に並べ替える）、book.add.discard.confirm「Close Without Adding」（確認のダイアログ。システムが折り返す）、session.row.delete「Delete」（スワイプ。記号だけを見せる）。
    - S5 の LabeledContent の項目名：session.finish.page.label「Current Page」、session.finish.minutes.label「Minutes Read」は欄と横に並ぶ。項目名を切らずに折り返し、欄の幅が足りなければ AX サイズと同じく項目名の下に欄を置く（ViewThatFits）。Double-Length で確かめる画面に入れる（design-reviewer r1 の提案7）。
    - 見出しと文（折り返す所）：book.add.titleField「Title (Required)」、book.add.totalPagesField「Total Pages (Optional)」、book.add.totalPagesHint、book.add.titleLimit、book.add.titleLimit.onSave、session.finish.page.hint、session.finish.page.hintFirst、session.finish.minutes.hint、session.finish.tooShort、library.empty.message、error.saveFailed.start、error.saveFailed.pause、error.saveFailed.resume、error.saveFailed.finish、error.saveFailed.cancel、error.saveFailed.session、error.saveFailed.delete、session.delete.message、book.add.discard.title。どれも行数を限らず折り返す。
    - 数と単位：format.minutes「%lld minutes」（値の行と記録の行。記録の行は日付、分、ページが横に入らなければ縦に並べる）、session.row.pages「%lld pages read」（同じ）、reading.elapsed.ms（VoiceOver のラベルだけで、画面に出ない）。
  - S1 の主操作（「Return to Paused Reading」と長い題名。2行で切れずに収まるか）、今週の行、帯の中のエラーの区画。
  - S4 の2つのボタンとエラーの区画（横並びで「Pause」「Finish」「Try Resuming Again」「Try Finishing Again」が倍になっても1行に収まるか。収まらなければ縦並びに切り替える。dynamicTypeSize だけでなく、幅が足りないときも縦並びにする＝ViewThatFits）。
  - S3 の値の行と主操作の無効の理由と「Return to Reading」、記録の行、S5 の項目名とヒントと誤りの文、S6 の本文、S2 の見出しとヒントと題名の上限の知らせ、S1 の読み込みの失敗（ContentUnavailableView の題と文。システムが折り返す）。
- 押せる範囲：すべてシステムの部品の既定の大きさ（ツールバーのボタン、キーボードの上のツールバーのボタン、リストの行、controlSize .large のボタン、TextField の行、alert のボタン）を使い、44x44pt 以上。小さくする指定をしない（D-43）。

コントラスト（G1 r1 の指摘1、2 で広げた。計算の式、背景とシステムの色の値と出典、コマンドは design/tokens.md の 5。どの組もライト、ダーク、コントラストを上げる設定の3通りで書いた）
基準は、17pt 以下の文字が 4.5:1 以上、18pt 以上か太字の文字とアイコンや操作部品の形が 3:1 以上（R-11、PRD 12）。式は、相対輝度 L = 0.2126R + 0.7152G + 0.0722B（各チャンネルは c ≤ 0.04045 なら c/12.92、それ以外は ((c+0.055)/1.055)^2.4）、比 = (明るい方の L + 0.05) / (暗い方の L + 0.05)。半透明のシステム色は、背景に重ねた色（各チャンネル round(α × 前景 + (1 − α) × 背景)）で計算した。

| 組（前景 / 背景）と使う所 | ライト | ダーク | コントラストを上げる（ライト / ダーク） | 基準と結果 |
|---|---|---|---|---|
| 確定のボタンと主操作：color.text.onAccent / color.accent.fill（S2 の「追加」、S5 の「保存」、S1 と S3 の主操作と error.retry、S1 の「本を追加」「もう一度読み込む」、S4 の「終える」とその場所の error.retry「もう一度終える」） | #FFFFFF / #7A4427 = 7.83:1 | #FFFFFF / #9F5833 = 5.36:1 | #FFFFFF / #5E3219 = 10.79:1 / #000000 / #E3B994 = 11.63:1 | 4.5:1。満たす。システムが既定のコントラストでラベルを白にしても同じ値（tokens.md 5 の A1 の注）。コントラストを上げる設定でシステムがアプリのラベルの色を使わなかったときの代わりの値は、ライト（黒いラベル）とダーク（白いラベル）の両方を tokens.md 1 に置いた（#000000 / #AD6137 = 4.54:1、#FFFFFF / #AD6137 = 4.62:1） |
| 塗りの形：color.accent.fill / 置かれる背景（帯、S4、シートのバー） | #7A4427 / #F2F2F7 = 7.01:1、/ #FFFFFF = 7.83:1 | #9F5833 / #000000 = 3.92:1、/ #1C1C1E = 3.17:1 | #5E3219 / #EBEBF0 = 9.08:1 / #E3B994 / #000000 = 11.63:1、/ #242426 = 8.58:1 | 3:1。満たす |
| システムがアクセントを付ける文字：color.accent.text / 背景（戻る、キャンセル、編集、＋、確定のボタンが文字で描かれる版） | #7A4427 / #FFFFFF = 7.83:1、/ #F2F2F7 = 7.01:1 | #CF9D78 / #000000 = 8.75:1、/ #1C1C1E = 7.09:1、/ #2C2C2E = 5.80:1 | #5E3219 / #FFFFFF = 10.79:1、/ #EBEBF0 = 9.08:1 / #E3B994 / #000000 = 11.63:1、/ #363638 = 6.68:1 | 4.5:1。満たす |
| alert のボタン（S6 の「キャンセル」「記録を消す」、S7 の「OK」）：color.accent.text / alert の背景の見積もり | #7A4427 / #E5E5EA = 6.23:1 | #CF9D78 / #3A3A3C = 4.73:1 | #5E3219 / #D8D8DC = 7.59:1 / #E3B994 / #444446 = 5.38:1 | 4.5:1。満たす（見積もり。G3 で測る） |
| カーソル：color.accent.text / 入力欄の行 | #7A4427 / #FFFFFF = 7.83:1 | #CF9D78 / #2C2C2E = 5.80:1 | #5E3219 / #FFFFFF = 10.79:1 / #E3B994 / #363638 = 6.68:1 | 3:1。満たす |
| 17pt 以下の文字のすべて：color.text.primary（label）/ 背景 | #000000 / #FFFFFF = 21.00:1、/ #F2F2F7 = 18.82:1 | #FFFFFF / #000000 = 21.00:1、/ #1C1C1E = 17.01:1、/ #2C2C2E = 13.94:1 | #000000 / #EBEBF0 = 17.67:1 / #FFFFFF / #363638 = 12.06:1 | 4.5:1。満たす |
| secondaryLabel を 17pt 以下の文字に使った場合（前の版：S4 の「72ページから」「一時停止中」、S2 の題名の上限の知らせ、S3 の日付、欄の下のヒント） | #8A8A8E / #FFFFFF = 3.44:1、#85858B / #F2F2F7 = 3.29:1 | #8D8D93 / #000000 = 6.36:1、#98989F / #1C1C1E = 5.94:1、#9F9FA5 / #2C2C2E = 5.29:1 | #7B7B7F / #FFFFFF = 4.22:1、#74747B / #EBEBF0 = 3.90:1 / #9F9FA6 / #000000 = 7.98:1、#B1B1B8 / #363638 = 5.66:1 | 4.5:1。ライトで満たさない → 使わない。すべて color.text.primary に替えた（D-48） |
| 一時停止中の経過（type.timer、34pt）：color.text.secondary（secondaryLabel）/ color.background.screen | #8A8A8E / #FFFFFF = 3.44:1 | #8D8D93 / #000000 = 6.36:1 | #7B7B7F / #FFFFFF = 4.22:1 / #9F9FA6 / #000000 = 7.98:1 | 3:1（18pt 以上）。満たす |
| placeholderText（前の版の「必須」「任意」）/ 入力欄の行 | #C5C5C7 / #FFFFFF = 1.72:1 | #656569 / #2C2C2E = 2.40:1 | #B6B6B8 / #FFFFFF = 2.02:1 / #7A7A7F / #363638 = 2.82:1 | 4.5:1。満たさない → placeholder を置かない（D-49） |
| 誤りとエラーの区画の記号：color.status.error / grouped | #FF383C / #F2F2F7 = 3.20:1 | #FF4245 / #000000 = 6.12:1、/ #1C1C1E = 4.96:1 | #E9152D / #EBEBF0 = 3.83:1 / #FF6165 / #000000 = 7.15:1、/ #242426 = 5.28:1 | 3:1。満たす（ライトは余裕が小さい。意味は文でも伝える） |
| 同じ記号：color.status.error / row と screen（S2、S5、S4 のエラーの区画） | #FF383C / #FFFFFF = 3.57:1 | #FF4245 / #000000 = 6.12:1、/ #2C2C2E = 4.06:1 | #E9152D / #FFFFFF = 4.56:1 / #FF6165 / #000000 = 7.15:1、/ #363638 = 4.11:1 | 3:1。満たす |
| .bordered のボタン：color.text.primary / その塗り（見積もり） | #000000 / #D1D1D6 = 13.80:1 | #FFFFFF / #3A3A3C = 11.35:1 | #000000 / #BCBCC0 = 11.09:1 / #FFFFFF / #444446 = 9.72:1 | 4.5:1。満たす（見積もり） |
| システムの削除の赤（アプリは色を指定しない）：白い記号か文字 / systemRed（スワイプの trash、編集モードの赤い丸と「削除」） | #FFFFFF / #FF383C = 3.57:1 | #FFFFFF / #FF4245 = 3.43:1 | #FFFFFF / #E9152D = 4.56:1 / #FFFFFF / #FF6165 = 2.94:1 | 記号は 3:1、文字は 4.5:1。記号はコントラストを上げるダークで、文字はコントラストを上げるライト以外で届かない。D-56 と 10 の 5 |
| S2 の確認のダイアログの「追加せずに閉じる」（destructive。システムが systemRed の文字で描く）/ ダイアログの背景（値の表がないので白と grouped と elevated の行で見積もる） | #FF383C / #FFFFFF = 3.57:1、/ #F2F2F7 = 3.20:1 | #FF4245 / #2C2C2E = 4.06:1 | #E9152D / #FFFFFF = 4.56:1、/ #EBEBF0 = 3.83:1 / #FF6165 / #363638 = 4.11:1 | 文字が 18pt 以上なら 3:1 で満たし、17pt 以下なら 4.5:1 に届かない。文字の大きさは iOS の版で変わり、見ていない。G3 で測る。10 の 5 |
| S2 の確認のダイアログの題、S6 と S7 の alert の題と本文 | システムが描く（値は見ていない） | 同じ | 同じ | 4.5:1。G3 のスクリーンショットで測る |
| 無効のボタン | システムの無効の見た目 | 同じ | 同じ | 対象外（WCAG 1.4.3 の例外）。理由は近くの文で伝える |

計算に使った道具：python3 で WCAG 2 の相対輝度の式（design-reviewer の手引きのコマンドと同じ式）と、半透明の色を重ねる式。コマンドは tokens.md 5 の最後にあり、例 `… FFFFFF 9F5833` → 5.36、`… 60,60,67,153 FFFFFF` → 8A8A8E。全部の組の出力は報告に書いた。

## 10. 決まっていないこと
残っているものは報告の「未解決」にも書いた。
1. AC との対応：2 の表は AC-1〜AC-67 の67行。「終える」、終える入力をやめる、60秒未満で終える、の保存の失敗は PRD の追記で AC-62〜AC-67 になった（D-58〜D-60）。読み始め、一時停止、再開の保存の失敗は PRD の追記で AC-56〜AC-61 になった。まだ AC がない画面の動きは、題名の上限の知らせ（D-45、D-57。PRD 10 は「AC はない」としている）、S3 から読書中の本へ行く book.openActiveReading（D-33）、S5 のキーボードの上の「保存」（D-53）。どれも G1 r2 の design/ の決定で、AC にするかは pdm が決める（報告の「未解決」）。
2. CI の出力で決めること（Mac がないため。裁定の1）：6 の「CI の出力で決めること」の (a)〜(g) に、決め方と代わりの案を書いた。(a) session.state.* が見えるか（代わりは 1pt の要素）、(b) システムの部品の識別子（代わりは 7 の文字で探す）、(c) .contain の行の「削除」のアクション（代わりは accessibilityAction(named:)）、(d) S5 の swipeDown（代わりはナビゲーションバーに対して行う）、(e) S6 の「キャンセル」（alert にしたので出る見込み。代わりは外側をタップ）、(f) 題名の上限の作り（代わりは形B）、(g) AC-49 の push と AC-54 の読み込みの失敗。tech-lead r1 の証拠3 の (d) 経過の読み上げは「作れる」と答えがあり、7 の表のとおり String Catalog のキーで作る。(f) 数字の欄の決まり（全角の数字を受け付け、ほかの文字は誤りにする。とても長い数字で落ちない）は、単体テストで tech-lead と ios-engineer が確かめる。
3. verifier に伝えること：経過は reading.elapsed の label（読み上げの形）で読む。見える文字との対応は 7 の表。記録の行の分とページは label で読む（6）。error.retry は識別子が1つで、文は操作ごとに変わる（6 の例外、7）。S4 の「もう一度終える」は、押した時点の経過で S3（60秒未満）か S5（60秒以上）に分かれる（D-59）。S6 は alert（6 の (b)(e)）。
4. Takuma に見てほしい見た目：しおりの色（栗色）と、ダークの塗りを暗い栗色 #9F5833 にしたこと（前の版の明るい #C99671 と黒い文字から、白い文字に替えた）。報告の「未解決」に推奨と反論を書いた。
5. システムの削除の赤（tokens.md 5 の C1、C2、C5）：S2 の確認のダイアログの「追加せずに閉じる」は systemRed の文字で、文字の大きさが 18pt 以上なら 3:1 で満たし、17pt 以下なら届かない（版で変わり、見ていない。G3 で測る）。スワイプと編集モードの削除は、システムが systemRed の塗りに白い記号と文字を描き、アプリは色を変えない（D-56）。白い記号はコントラストを上げるダークで 2.94:1（3:1 に届かない）、編集モードの「削除」の文字は 3.43〜3.57:1（コントラストを上げるライトだけ 4.56:1）。同じ操作は色に頼らない道（VoiceOver などのアクション「削除」）でも行え、確認の alert（S6）の文字は基準を満たす。スワイプのボタンだけは tint で独自の赤に替えられるが、編集モードの赤は替えられず、2つの赤が並ぶ。どちらにするかを報告の「未解決」に上げた。
6. 題名の上限の形（PRD 10）：形A か形B かは tech-lead が設計メモで決める。見せ方は両方とも決めた（1、3 の S2、D-57、7）。
7. 検索は 001 では置かない（PRD 10 のやらないこと）。D-31 と 5 の「多い件数」をこれに合わせた。
8. 下へのスワイプでやめる保存に失敗したときの開き直し（D-60。PRD 10 が tech-lead と designer に委ねた）：見た目は「閉じたシートを同じ値のまま開き直し、先頭に error.saveFailed.cancel の区画を出す」に決めた。入れかけのページと分を、シートを閉じても残る所に持つ必要がある。作れるかは tech-lead が設計メモで確かめる。作れず、スワイプで閉じる前に保存する形（閉じるのを止める形）にする場合は、成功するふだんのスワイプでもシートが一度戻ってから閉じる動きになり、AC-48 の見え方が変わるので、designer に戻す（報告の「未解決」）。
9. コントラストを上げる設定のダークで、システムが確定のボタンに白いラベルを描いた場合（#FFFFFF / #E3B994 = 1.81:1。tech-lead r2 の提案2）：代わりの値（color.accent.fill #AD6137、color.text.onAccent #FFFFFF）を tokens.md 1 に足した。替えるかは G2 の CI のスクリーンショットで決める。

## 確かめ（提出前に designer が印を付ける。design-reviewer はこれを信じずに確かめる）
2 の表は AC-1〜AC-67 の67行（G1 の契約の後の追記で印を付け直した）。
- [x] 調査が先にあり、決定表のすべての行に R-n と原則がある（R-n は調査に実在する）（調査はコミット f8ae3e8 で、この版でも変えていない。4 の D-1〜D-60 のすべての行に R-n と、HIG の URL か B-n がある。G1 の契約の後に足した D-58〜D-60 は、D-51、D-52 と同じ R-1、R-8 と HIG Design principles、Alerts、Writing を引く。G1 r2 で足した D-46〜D-57 は R-1、R-3、R-8、R-9、R-10、R-11、R-12、R-24 を引く。D-8 は抜粋の R-23、R-24 を補いにし、開いた R-3 と PRD 5 の O-1 を主にした）
- [x] 全画面に、仕事、主操作1つ、使う標準部品がある（3 の S1〜S7。S1 と S3 の主操作は状態ごとに1つで、保存の失敗のときは同じ場所の error.retry。標準から外れる所は S1、S3、S5 に本来の部品、理由、対応を書き、S5 に下へのスワイプの逸脱を、S2 に UITextField を包む場合の条件つきの逸脱を足した）
- [x] 全画面の7つの状態が埋まっている（5 の S1〜S7。S1、S3、S4 のエラーの列に、読み始め、一時停止、再開の保存の失敗の表示、キー、次の操作を足した。G1 の契約の後に、S4 に「終える」と60秒未満で終える保存の失敗、S5 にやめる保存の失敗を足した）
- [x] 押せる範囲が 44x44pt 以上。コントラストが基準を満たし、独自の色の組に数字が3通りある（9 と tokens.md の 5。独自の色の組はすべて基準を満たす。システムの色を文字に使う組も3通りで計算し、届かない secondaryLabel と placeholderText は使わないことにした。システムが自分で描く削除の赤は基準に届かない組があり、10 の 5 と報告の「未解決」に上げた。G1 の契約の後に、コントラストを上げる設定のダークでシステムが白いラベルを描いた場合の代わりの値 #AD6137 を、式と数字（白い文字 4.62:1、形 / #000000 4.54:1、形 / #242426 3.35:1）付きで tokens.md 1 と 5 の A1 の注に足した）
- [x] AX5 での並びと、VoiceOver の読み上げ順が書いてある（9。保存の失敗の区画、S3 の「読書に戻る」、S5 のキーボードの上の「保存」、S6 の alert を足した。G1 の契約の後に「もう一度終える」「もう一度読書に戻る」の位置と読み上げを足した）
- [x] 性格語と差をつける点が、画面のどこに表れているか書いてある（8）
- [x] 文言が日英そろい、テストで使う要素に accessibilityIdentifier がある（7 の76キーで、ja か en が空の行は0。6 に AC-56〜AC-67 の名前と、識別子とキーが1対1でない例外を書いた。システムの部品で識別子が付かないものは 6 の「CI の出力で決めること」の (b)）
