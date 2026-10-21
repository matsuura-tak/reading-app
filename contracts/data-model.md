# データモデル（001-reading-session、SchemaV1）

- 書いた役：tech-lead　日付：2026-10-21
- 決めた ADR：docs/adr/0001-local-storage-swiftdata.md（SwiftData、VersionedSchema V1、端末の中だけ、iCloud の同期なし、バックアップに含める）、docs/adr/0003-telemetry-without-sdk-in-001.md（計測の印）
- 置き場所：端末の中だけ。SwiftData のストアは Application Support の `Yomutoki/Library.store`（ModelConfiguration の url で明示、cloudKitDatabase は none）。計測の印は UserDefaults。
- 版：`SchemaV1`（Schema.Version 1.0.0）。`SchemaMigrationPlan` の stages は空。形を変えるときは SchemaV2 と MigrationStage を足し、この表を「足すだけ」で直す（項目を消す、名前や型を変える、必須にする変更は新しい ADR）。
- 時刻：保存は Date（瞬間）。画面、週、テストのデータの壁時計の時刻は、Calendar（timeZone と firstWeekday。A18、A43）を通して扱う。
- Swift の名前は案。ios-engineer が決めてよいが、項目の意味、型、制約は変えない。

## Book（本）
| 項目 | 型 | 制約 | 意味と決まり | 関係する AC |
|---|---|---|---|---|
| id | UUID | 作るときに決め、変えない | 本の行の識別子 `library.book.<小文字の UUID>`（design 6） | AC-49、AC-53 |
| title | String | 整えた後に1〜100字。1字は Character（書記素クラスタ。A95、A96） | 整え方（PRD 10）：前後の空白4種（半角空白、U+3000、改行、タブ）を除き、中の改行（LF、CR、CRLF、U+2028、U+2029。CRLF は1つ）を1つずつ半角空白1つにする。タブは置き換えない。並んだ改行はまとめない | AC-2、AC-3 |
| totalPages | Int? | nil か 1〜9,999 | 未設定なら進み具合を出さない | AC-28、AC-31 |
| lastPage | Int | 0〜9,999。totalPages があればそれ以下 | 最後のページ。新しい本は0。記録を保存するときにページを入れたら、その値にする（前より小さくても。AC-29）。記録を消しても変えない（PRD 10） | AC-9、AC-14、AC-16、AC-29 |
| addedAt | Date | | 追加の保存が通った時刻 | AC-26、AC-49 |
| sessions | [ReadingSession] | 関係。消す決まりは cascade（001 に本を消す操作はない） | | |

最後のページを本に持たせる理由：PRD 10 は「記録を消しても最後のページは変えない」（AC-16）と決めている。記録から毎回出す形（いちばん新しくページを入れた記録の値）にすると、その記録を消したときに値が変わってしまう。代わりの案（記録から出す）は、データが1か所で済む良さがあるが、PRD 10 に合わないので選ばない。

## ReadingSession（記録）
| 項目 | 型 | 制約 | 意味と決まり | 関係する AC |
|---|---|---|---|---|
| id | UUID | | 記録の行の識別子 `session.row.id.<小文字の UUID>`（design 6） | AC-10、AC-16 |
| book | Book | 必須 | | |
| startedAt | Date | | 読み始めた時刻（読み始めの保存が通った時刻。AC-57）。週の集計はこの時刻の週に数える | AC-15、AC-44 |
| durationSeconds | Int | 60 以上 | 読んだ秒。分を直さなければ、終えた時刻での経過の秒（切り捨て）。分を直したら「分 × 60」 | AC-6、AC-12、AC-13、AC-14、AC-45 |
| endPage | Int? | nil か 0〜9,999。本に totalPages があればそれ以下 | 終えるときに入れた今のページ。入れなければ nil | AC-9〜AC-11、AC-32 |
| pagesRead | Int? | endPage が nil なら nil。あれば max(0, endPage − 保存の前の book.lastPage) | 「その記録の読んだページ」（session.row.page）。読み返しは0 | AC-9、AC-29 |
| savedAt | Date | | 記録の保存が通った時刻 | AC-25、AC-50 |

## ActiveReading（進行中の読書。0件か1件）
状態 idle は「この行がない」こと。reading、paused、finishing のときだけ1件ある。同じストアに置くので、読み込みに失敗したときは本と記録と一緒に読めない（AC-54 で S4 と S5 を出さないことと合う）。
| 項目 | 型 | 制約 | 意味と決まり | 関係する AC |
|---|---|---|---|---|
| book | Book | 必須 | 読んでいる本 | AC-17、AC-27 |
| state | String | "reading" / "paused" / "finishing" のどれか | 状態の名前（T8 の session.state.*） | AC-8、AC-33、AC-34 |
| startedAt | Date | | 読み始めた時刻 | AC-5、AC-57 |
| pausedTotalSeconds | Double | 0 以上 | 止めていた秒の合計。終える入力（finishing）にいてやめた時間もここに足す（PRD 10、AC-46〜AC-48） | AC-6、AC-46 |
| pausedAt | Date? | state が paused のときだけ値がある | 一時停止の保存が通った時刻 | AC-33、AC-59 |
| finishedAt | Date? | state が finishing のときだけ値がある | 「終える」操作の時刻。経過はここで止まる（PRD 10） | AC-19、AC-34、AC-45 |
| wasPaused | Bool | | 一度でも一時停止したか（計測の was_paused） | － |

分の欄の初めの値は保存しない。finishedAt から計算する（finishing で強制終了して戻ったときも同じ値になる。AC-34）。入れかけのページと分は S5 の画面の中だけに持ち、保存しない（AC-46、AC-47）。

## 計算する値（保存しない）
- 経過の秒 = max(0, 終わりの時刻 − startedAt − pausedTotalSeconds)。終わりの時刻は reading なら今、paused なら pausedAt、finishing なら finishedAt。端末の時刻が戻っても0で止める（AC-41）。
- 分の欄の初めの値 = 経過の秒（finishing のとき）÷ 60 の切り捨て。直せる範囲は1〜この値（AC-30）。
- 本の合計 = その本の記録の durationSeconds の和 ÷ 60 の切り捨て（秒で足してから分にする。PRD 10）。
- 今週の合計 = startedAt が今週（Calendar.dateInterval(of: .weekOfYear, for: 今)。A18）に入る記録の durationSeconds の和 ÷ 60 の切り捨て。
- 進み具合 = lastPage × 100 ÷ totalPages の整数の割り算（切り捨て。299/300 は99%）。totalPages が nil なら出さない。
- 前の本（PRD 10）：ActiveReading があればその本。なければ savedAt がいちばん新しい記録の本。記録が0件なら addedAt がいちばん新しい本。
- 本の一覧の順（design の D-31）：ActiveReading の本を先頭に、そのほかは「その本の記録の savedAt の最大、なければ addedAt」の新しい順。

## 保存の操作（1つの操作は1回の save。失敗したら rollback し、状態を変えない）
| 操作 | 1回の save で変えるもの | T5 の名前（UITEST_FAIL） | 失敗したとき | 通ったときの計測（contracts/telemetry.md） |
|---|---|---|---|---|
| 読み込み | 読むだけ（ストアを開き、全部を読む） | load | error.loadFailed を出す。保存先を消さず、別の保存先を作らない（AC-54、AC-55） | 失敗ごとに Load Failed |
| 本を追加 | Book を足す | book_add | S2 の入力を残す（AC-42） | Book Added。失敗は Save Failed（book_add） |
| 読み始める | ActiveReading を足す（reading、startedAt＝通った時刻、pausedTotalSeconds 0、wasPaused false） | session_start | idle のまま（AC-56） | Reading Session Started。失敗は Save Failed（session_start） |
| 一時停止 | state を paused、pausedAt＝通った時刻、wasPaused true | session_pause | reading のまま、経過は進む（AC-58） | 失敗は Save Failed（session_pause） |
| 再開 | pausedTotalSeconds に（通った時刻 − pausedAt）を足し、pausedAt を nil、state を reading | session_resume | paused のまま（AC-60） | 失敗は Save Failed（session_resume） |
| 終える（経過60秒以上） | reading から：finishedAt＝時刻、state を finishing。paused から：先に pausedTotalSeconds に（時刻 − pausedAt）を足し、pausedAt を nil | なし（未解決） | 未決定（PRD と design に AC と画面がない） | なし |
| 終える（経過60秒未満） | ActiveReading を消す | なし（未解決） | 未決定 | Reading Session Discarded |
| 終える入力をやめる | pausedTotalSeconds に（時刻 − finishedAt）を足し、finishedAt を nil、state を reading | なし（未解決） | 未決定 | なし |
| 記録を保存 | ReadingSession を足す。ページを入れたら book.lastPage を更新。ActiveReading を消す | session_finish | finishing のまま、入力を残す（AC-19、AC-35） | Reading Session Finished。条件を満たせば Reading Week Reached。失敗は Save Failed（session_finish） |
| 記録を消す | ReadingSession を消す（book.lastPage は変えない） | session_delete | 記録を残し、S7 を出す（AC-43） | 失敗は Save Failed（session_delete） |
| 起動して戻す | 読むだけ（読み込みが通り、ActiveReading があるとき） | － | － | Reading Session Restored |

## 計測の印（UserDefaults。SwiftData に入れない）
| キー | 型 | 意味 |
|---|---|---|
| telemetry.firstOpenedAt | Date | App First Opened を出した時刻。ないときは起動したときに出して入れる。since_first_open の起点 |
| telemetry.firstSessionStarted | Bool | 読み始めを一度でも出したか（is_first_session） |
| telemetry.first5minDone | Bool | 5分以上の記録を一度でも出したか（is_first_5min） |
| telemetry.weekReachedWeekStart | Date | Reading Week Reached を出した週の始まりの時刻（いちばん新しいもの） |
| telemetry.localCounts | [String: Int] | 本番の送り先（端末の中で数えるだけ。ADR 0003）のイベント名ごとの回数 |

## 置き場所、個人情報、保存期間、消し方
| エンティティ | 置き場所 | 個人情報か | 保存期間 | 消し方 |
|---|---|---|---|---|
| Book | 端末（SwiftData）。バックアップに入る | 利用者が入れた内容（題名から読書の好みがわかる）。端末の外に出さない。ログに出さない（Logger の既定の非公開のまま） | アプリを消すまで（001 に本を消す操作はない） | アプリを消す |
| ReadingSession | 端末（SwiftData）。バックアップに入る | 利用者の行動の記録（時刻、長さ、ページ）。端末の外に出さない | 利用者が消すまで | 本の詳細の削除（AC-16）。アプリを消す |
| ActiveReading | 端末（SwiftData）。バックアップに入る | 同上 | 記録を保存するか、60秒未満で終えるまで | 終える。アプリを消す |
| 計測の印 | 端末（UserDefaults）。バックアップに入る | いいえ（時刻、真偽、回数だけ。題名とページを持たない） | アプリを消すまで | アプリを消す |

## テストのデータとの対応
- UITEST_SEED（contracts/seed.schema.json）の books、sessions、active、flags は、上の Book、ReadingSession、ActiveReading、計測の印に1対1で入る。壁時計の時刻は UITEST_TIME_ZONE で Date にする。
- JSON Schema で書けない制約（bookId が books にあること、lastPage と endPage が totalPages 以下、state と pausedAt と finishedAt の組、title の100字（書記素））は、アプリがデータを入れる前に確かめ、合わなければ止める（ADR 0005）。
