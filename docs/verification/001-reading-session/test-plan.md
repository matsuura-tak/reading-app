# テスト計画 001-reading-session：読んだ時間とページを残して、続きから読む

- 書いた役：verifier　日付：2026-10-21
- 実装のコードを見ずに書いた：はい（2026-10-21 の初版作成時は ios/ の実装がまだなく、ios/AcceptanceTests/ の外は開いていない）
- 2026-10-23 の補記：5章の実行手順を現行 Makefile とスクリプトにそろえ、8章に実装後の初回 macOS CI の実ログと、実装前の UI 赤実行が未確認である履歴上の不足を記録した。受け入れ条件と期待値は変えていない。製品実装は読んでいない。
- この版の範囲：前半と後半（2026-10-21）。前半は計画の全章（2 は AC-1〜AC-67 の全行）、ios/AcceptanceTests/ の設定、共通の部品、AC-1〜AC-30 のテスト。後半は AC-31〜AC-67 のテスト（AC-39 は ac39-xcstrings.sh）、Support/UIHelpers.swift の末尾に足した小さな部品（Wait.enabled、expectSaveFailed、expectNoSaveFailed、expectSessionCount、beginDeleteSession、goBack(toBookTitled:)。前半の部品は変えていない）、8 の赤の証拠、2 の「…」で略した名前を全部の名前に書き直したこと（値は変えていない）。
- 後半で読み足したファイル：contracts/tools/xcstrings_untranslated.py（AC-39）、contracts/data-model.md の「保存の操作」と「計算する値」、design/001-reading-session.md の 1（S1 > S3 > S4 の積み方）と 5 の長い題名の行（S3 のナビゲーションバーの題名は本の題名）。
- 読んだファイル（PRD、design/、contracts/ と、指示書が挙げた ADR と判定の記録だけ）：
  - docs/prd/001-reading-session.md（9〜12、15）
  - design/001-reading-session.md（1、5、6、7、9、10）、design/tokens.md、design/001-reading-session/screens.md（見出し）
  - contracts/test-hooks.md（T1〜T22）、contracts/seed.schema.json、contracts/seed.example.json、contracts/examples/（seed-ac15.json、seed-ac33.json、telemetry-*.json、flushed.json）、contracts/data-model.md、contracts/telemetry.md、contracts/telemetry-flushed.schema.json、contracts/README.md
  - docs/adr/0004-project-generation-xcodegen.md、docs/adr/features/001-reading-session.md の 11、docs/templates/test-plan.md、docs/org/gates.md（G2、G3）、CLAUDE.md（ios_test）
  - docs/reviews/001-reading-session-G0-verifier-r2.md、-G0-tech-lead-r1.md と -G1-tech-lead-r2.md の確かめ済みの API（A22〜A28、A43〜A65）
  - XcodeGen 2.46.0 の Docs/ProjectSpec.md と Sources/ProjectSpec/Scheme.swift、Target.swift（testPlans のパスが include の相対で読まれること）、XcodeProj 9.14.0 の ReferenceGenerator.swift（ターゲットの ID の作り方）
- 期待する文字は design/ の 7 の ja と en をそのまま写した（ios/AcceptanceTests/Support/L10n.swift）。実装の出力に合わせて直さない。

## 1. リスク
影響「大」の例：データが消える、数や金額が間違う、他人のデータが見える、起動で落ちる、主な流れが最後まで進まない。
影響「大」は、自動テスト、3章の行、6章の探索1本。影響「小」は代表のテスト1本。
| # | リスク | 影響（大中小） | 起きやすさ（大中小） | 関わる AC | 試す深さ |
|---|---|---|---|---|---|
| R1 | 本、記録、進行中の読書が消える（強制終了、端末の再起動、保存の失敗、削除の失敗、読み込みの失敗） | 大 | 中 | AC-8、AC-16、AC-18、AC-19、AC-33〜AC-35、AC-42、AC-43、AC-54、AC-55、AC-64 | 自動（保存の後に終了して起動し直して見る。AC-2、AC-9、AC-16 も）、3章の「データがある」「容量不足」、探索 C1 |
| R2 | 読んだ時間を数え違える（一時停止、裏、終える入力、時計の戻し、失敗から再試行までの時間） | 大 | 大 | AC-5〜AC-8、AC-12、AC-13、AC-30、AC-33、AC-34、AC-41、AC-45〜AC-48、AC-57〜AC-63、AC-65〜AC-67 | 自動（時計を止めて T16 で決まった秒だけ進め、label を秒の単位で見る。境界 59秒と60秒）、3章の「復帰」、探索 C2 |
| R3 | 合計、進み具合、週の集計、ページの数が間違う | 大 | 中 | AC-9、AC-10、AC-12、AC-14〜AC-16、AC-24、AC-28、AC-29、AC-36、AC-44 | 自動（丸めの境界 90秒×3、299/300、週の始めの月曜と日曜、日をまたぐ記録）、探索 C3 |
| R4 | 主な流れが最後まで進まない（0冊から読み始め、終えて保存、保存の後の画面） | 大 | 中 | AC-1、AC-2、AC-4、AC-5、AC-49〜AC-51 | 自動（タップの数を数える）、3章の「初めて起動」、探索 C4 |
| R5 | 読書中が2件になる、状態を取り違える | 大 | 中 | AC-17、AC-27、AC-52、AC-56、AC-57 | 自動（reading、paused、finishing の3通りをそれぞれ。無効のボタンも押してみる）、探索 C5 |
| R6 | 計測に題名やページの値が出る | 大 | 小 | AC-23 | 自動（届いた全体を UTF-8 とパーセントエンコードで数える）、3章の「オフライン」、探索 C6 |
| R7 | 起動で落ちる、読み込めないのに空に見えて新しい本を別の所に書く | 大 | 小 | AC-8、AC-33、AC-34、AC-54、AC-55 | 自動（seed は ajv で schema に合うことを確かめた）、探索 C7 |
| R8 | 計測の失敗が画面に出る、操作が止まる | 中 | 中 | AC-20 | 自動（届かない先、500、応答しない先の3通り） |
| R9 | 入力の範囲の誤り（空白だけの題名、ページと分と総ページ数の範囲） | 中 | 中 | AC-3、AC-11、AC-30〜AC-32 | 自動（同値分割と境界値） |
| R10 | ja と en の文言の抜け、VoiceOver の読み上げ | 中 | 中 | AC-39、AC-40（全テストを ja と en の2構成で動かす） | 自動、G4 の人（VoiceOver の操作） |
| R11 | 権限のダイアログ、冊数の制限や課金の画面、確認の取り消し、追加をやめる | 中 | 小 | AC-21、AC-22、AC-38、AC-53 | 代表のテスト1本ずつ |

## 2. 受け入れ条件とテストの対応
すべての AC に1つ以上のテストを付ける。名前に AC 番号を入れる（AC-3 なら test_AC3_<結果>）。AC のないテストは作らない。
技法：同値分割と境界値、状態遷移、デシジョンテーブル、ペアワイズ、代表の1例。
確かめる結果は具体的な値で書く。要素があるかだけにしない。

共通：ファイルは ios/AcceptanceTests/Tests/ の中。すべて画面のテスト（XCUITest）で、Acceptance.xctestplan の ja_JP と en_US の2構成で動く（AC-18 は AC18Reboot.xctestplan の ja_JP だけ）。下の文字は ja で書き、en は design/ の 7 の英語（L10n.swift）。時計は UITEST_NOW＝2026-10-21T21:30:00（水）、Asia/Tokyo、止めたまま（UITEST_CLOCK_FROZEN=1）で、T16 で進める。「坊っちゃん」＝本1（UUID …0001）、「こころ」＝本2（…0002）。「新しい行」は S3 の session.row.id. で始まる行のうち seed で入れていない行。「件数を見る」ときは、最後に S3 の book.sessionCount を読む（S5 にいるときは「キャンセル」で reading に戻してから。AppSession.goToBookDetail）。

前半（この版で書いた。Library＝LibraryAcceptanceTests.swift、Reading＝ReadingSessionAcceptanceTests.swift、Finish＝FinishSessionAcceptanceTests.swift、Stats＝BookStatsAcceptanceTests.swift、Telemetry＝TelemetryAndPrivacyAcceptanceTests.swift、AC18＝AC18RebootTests.swift）
| AC | リスク | 技法 | 試す値（境界、遷移、ルールの列） | 種類（API / 画面） | ファイル::テストの名前 | 確かめる結果（具体的な値） |
|---|---|---|---|---|---|---|
| AC-1 | R4 | 代表の1例（空） | UITEST_RESET=1、本0冊、記録0件 | 画面 | Library::test_AC1_emptyLibraryShowsEmptyStateAndOnlyAddBook | library.empty.title の label「本がまだありません」、library.empty.message の label「読んでいる本の題名を入れると、すぐに読み始められます。」、library.addBook が1個、home.startReading と book.startReading が0個。スクリーンショット AC1_空の状態 |
| AC-2 | R4、R1 | 代表の1例 | 題名「坊っちゃん」、総ページ数は空 | 画面 | Library::test_AC2_addBookWithTitleOnly | 詳細の book.title「坊っちゃん」、book.lastPage の value「0」、book.totalPages が0個。終了して起動し直した後、home.bookCount「1冊」、library.book. で始まる行が1つで label「坊っちゃん」 |
| AC-3 | R9 | 同値分割（空、空白だけの5種と組み合わせ） | ""、" "、U+3000、"\n"、"\t"、" U+3000\n\t"、"U+3000\t \r\n"（改行とタブを含む4つは貼り付け） | 画面 | Library::test_AC3_blankTitleCannotBeSaved | 前提：打った値は欄の value が同じ文字、貼り付けた4つは貼り付けの後に value が空でも placeholder でもない（貼り付けの失敗を空文字の例と取り違えないため）。どの値でも book.save の isEnabled が false のまま（押しても false）、入力は開いたまま。閉じた後も library.empty.title が出る（本0冊）。起動し直しても本の行は0個 |
| AC-4 | R4 | 代表の1例（操作の数） | 0冊 → library.addBook → 題名「坊っちゃん」→ book.save → book.startReading | 画面 | Library::test_AC4_zeroBooksToReadingInThreeTapsOrFewer | 数えるタップを3回（library.addBook、book.save、book.startReading）だけした後に session.state.reading、reading.title「坊っちゃん」。題名の欄のタップとキーボードは数えない。タップの数は手順で決まるので比べるアサーションは置かず、合否はこの流れで決まる |
| AC-5 | R2、R4 | 状態遷移（idle→reading）と境界（0〜1秒、2〜4秒） | 記録1件の「坊っちゃん」、home.startReading を1回。時計を3秒進める | 画面 | Reading::test_AC5_previousBookStartsFromHomeInOneTap、Reading::test_AC5_startToFirstElapsedMeasuredBySignpost | reading、reading.title「坊っちゃん」、reading.elapsed の label が「0分0秒」か「0分1秒」、3秒後は「0分2秒」〜「0分4秒」。0.5秒は T20 の FirstElapsedShown を XCTOSSignpostMetric で5回測り、G3 で xcresult の平均が 0.5秒以下であることを読む（measure は基準値なしでは落ちないため。12 の測り方）。G3 の verification.md に5回の値と平均を貼る（取り出し方は5章） |
| AC-6 | R2 | 状態遷移（reading→paused→reading→finishing→idle） | 経過0:00 から 60秒、止めて60秒、再開して60秒 | 画面 | Reading::test_AC6_pausedTimeIsNotCounted | 止めている間 label「1分0秒」のまま、再開60秒後「2分0秒」。保存の後の新しい行の session.row.minutes の label「2分」（一時停止を数えれば「3分」） |
| AC-7 | R2 | 状態（裏から復帰） | 経過1:00、press(.home) の後に時計を600秒進め、activate | 画面 | Reading::test_AC7_elapsedKeepsRunningInBackground | アプリが前でなくなった（state が runningForeground でない）こと、戻った後 reading、label が「11分0秒」〜「11分5秒」 |
| AC-8 | R1、R2、R7 | 状態（強制終了から復帰） | reading 経過5:00、terminate、UITEST_NOW を5分後にして起動 | 画面 | Reading::test_AC8_forceQuitRestoresReadingAndElapsed | 起動直後に reading、reading.title「坊っちゃん」、label が「10分0秒」〜「10分5秒」 |
| AC-9 | R3、R1 | 代表の1例（進み） | 総ページ数300、最後のページ40、今のページ72 | 画面 | Finish::test_AC9_enteringPageRecordsProgress | book.sessionCount「記録 2件」（1件増えた）、新しい行の session.row.page の label「32ページ進んだ」、book.lastPage「72」、book.progress「24%」。起動し直した後も「記録 2件」「72」「24%」 |
| AC-10 | R3 | 同値分割（ページなし） | 最後のページ40、記録1件、ページを空のまま保存 | 画面 | Finish::test_AC10_finishWithoutPage | 「記録 2件」、新しい行の session.row.page が0個、book.lastPage「40」、session.state.idle |
| AC-11 | R9 | 境界値（300 と 301） | 総ページ数300の finishing で 301、続けて 300 | 画面 | Finish::test_AC11_pageAboveTotalPagesIsRejected | 301：session.finish.pageOutOfRange の label「0から300までの数字で入れてください。」、finishing のまま、S5 は開いたまま。300：誤りの文は消え、session.finish.save が有効。最後に「記録 1件」（増えない） |
| AC-12 | R2、R3 | 代表の1例（分を直す） | 経過180分の finishing、分を 180 → 45。前の合計は15分 | 画面 | Finish::test_AC12_editMinutesWhenFinishing | 前提：分の欄の value「180」。新しい行の session.row.minutes「45分」、book.totalTime「60分」（15分＋45分） |
| AC-13 | R2 | 境界値（59秒と60秒） | 経過0:59 で終える。境界の相手は経過1:00 | 画面 | Reading::test_AC13_underOneMinuteIsNotRecorded、Reading::test_AC13_boundarySixtySecondsOpensFinishInput | 59秒：session.finish.tooShort の label「1分未満だったので、記録しませんでした。」、idle、session.finish.save が0個、「記録 1件」。60秒：finishing、session.finish.minutes の value「1」、tooShort は0個 |
| AC-14 | R3 | 代表の1例と境界値（丸め） | 10分、20分、30分、最後のページ72/300。丸めの境界は90秒×3件 | 画面 | Stats::test_AC14_bookTotalsAreShown、Stats::test_AC14_totalAddsSecondsBeforeFlooring | book.totalTime「60分」、book.sessionCount「記録 3件」、book.lastPage「72」、book.progress「24%」。90秒×3件は「4分」（PRD 10 の丸め） |
| AC-15 | R3 | デシジョンテーブル（週の始め×記録の日） | 月曜始まり（UITEST_FIRST_WEEKDAY=2）、10-18（日）40分、10-19（月）25分、10-20（火）35分 | 画面 | Stats::test_AC15_weekTotalExcludesLastWeek | home.weekTotal の value「60分」（日曜始まりなら100分になる組） |
| AC-16 | R1、R3 | 状態遷移（記録2件→1件） | 20分と30分、最後のページ72。30分を消して確認で消す | 画面 | Stats::test_AC16_deleteSessionKeepsLastPage | 30分の行が消え20分の行は残る、「記録 1件」、book.totalTime「20分」、book.lastPage「72」。起動し直しても同じ |
| AC-17 | R5 | 状態遷移（3状態）×別の本 | 「坊っちゃん」が reading（5:00）、paused（5:00、1分止めた）、finishing（10:00。キャンセルしてから） | 画面 | Reading::test_AC17_cannotStartAnotherBookWhileReading、Reading::test_AC17_cannotStartAnotherBookWhilePaused、Reading::test_AC17_cannotStartAnotherBookWhileFinishing | 「こころ」の book.startReading の isEnabled が false、押しても状態は変わらず reading.title は0個。ホームの home.resumeReading が1個で label が「坊っちゃん」で始まる、home.startReading が0個 |
| AC-18 | R1 | 状態（端末の再起動） | seed.example.json と同じ5件 → simctl shutdown と boot → RESET も SEED もなしで起動 | 画面（2段） | AC18::test_AC18_1_seedLibraryBeforeReboot、AC18::test_AC18_2_libraryRemainsAfterReboot（ac18-reboot.sh） | 再起動の後、home.bookCount「2冊」、本の行が2つ、「坊っちゃん」の book.totalTime「60分」と「記録 3件」、「こころ」の「40分」と「記録 2件」（計5件） |
| AC-19 | R1 | 状態（保存の失敗） | UITEST_FAIL=session_finish:*、経過10:00 で終えた finishing。失敗の後に時計を120秒進める | 画面 | Finish::test_AC19_saveFailureKeepsFinishingSession | error.saveFailed の label「変更を保存できませんでした」、error.retry がある、finishing のまま、session.finish.minutes の value「10」（120秒後も「10」）、最後に「記録 1件」（変わらない） |
| AC-20 | R8 | 同値分割（失敗の3種） | 送り先が http://localhost:9、500 を返す受け口、30秒応答しない受け口（UITEST_TELEMETRY_TIMEOUT=3）。CONTROL は正常な受け口 | 画面 | Telemetry::test_AC20_allOperationsWorkWhenTelemetryIsUnreachable、Telemetry::test_AC20_allOperationsWorkWhenTelemetryReturns500、Telemetry::test_AC20_allOperationsWorkWhenTelemetryHangs | 追加、読み始め、終えて保存、本の詳細の各手順の後に app.alerts と app.sheets が0個、識別子が error. で始まる要素が0個。「記録 1件」。送信4件の失敗（/flushed の failed＝4、sent＝0）を待った後も同じ |
| AC-21 | R11 | 代表の1例（権限） | 起動の前に camera、photos、location、userTracking を未回答に戻す。追加、読み始め、5分、終えて保存 | 画面 | Telemetry::test_AC21_noPermissionPromptsDuringFirstSession | 各手順の後に SpringBoard の alerts が0個、アプリの alerts が0個。手順の途中の割り込み（addUIInterruptionMonitor の記録）が0件（出たらその場で落とす）。「記録 1件」 |
| AC-22 | R11 | 境界値（20冊→21冊） | seed で20冊、21冊目「坊っちゃん」 | 画面 | Library::test_AC22_twentyFirstBookHasNoLimitOrPaywall | 前提「20冊」。保存の後 app.alerts と app.sheets が0個、book.add.title が0個、book.startReading が押せる（isHittable）。戻ったホームの home.bookCount「21冊」 |
| AC-23 | R6 | 代表の1例（全体を数える） | flags で App First Opened 送り済み、本0冊。「坊っちゃん」を追加、読み始め、5分、ページ72で終える | 画面 | Telemetry::test_AC23_telemetryHasNoTitleOrPageValues | 15 の名前のイベントは Book Added、Reading Session Started、Reading Session Finished の3件。前提：パーセントエンコードの形は UTF-8 のバイト列から作り、元の文字と違い、大文字は %E5%9D%8A%E3%81%A3%E3%81%A1%E3%82%83%E3%82%93、小文字は %e5%9d%8a%e3%81%a3%e3%81%a1%e3%82%83%e3%82%93 に等しい。届いた要求の全体で、UTF-8 の「坊っちゃん」、%XX の形、%xx の形がそれぞれ0回。JSON を読み直した events の全部の値（キーと入れ子も。\uXXXX で書き出された題名を見つけるため）で3つの形が0回。プロパティの値で 72（数か文字）が0個 |
| AC-24 | R3 | 境界値（50分→65分→75分） | 月曜始まり、今週50分、15分の読書と10分の読書を続けて終える | 画面 | Telemetry::test_AC24_weekReachedIsSentOncePerWeek | 前提 home.weekTotal「50分」。送信5件の後、Reading Week Reached がちょうど1件、threshold_min が文字の "60"（as? String で比べる。contracts/telemetry.md） |
| AC-25 | R5 | デシジョンテーブル（追加の順×保存の順） | 「こころ」を先に、「坊っちゃん」を後に追加。最後の記録は「坊っちゃん」2日前、「こころ」1日前 | 画面 | Reading::test_AC25_previousBookIsTheLastSavedOne | home.startReading で reading、reading.title「こころ」 |
| AC-26 | R5 | デシジョンテーブル（記録0件） | 「坊っちゃん」の後に「こころ」を追加、記録0件 | 画面 | Reading::test_AC26_withoutSessionsPreviousBookIsTheLastAdded | reading、reading.title「こころ」 |
| AC-27 | R5 | 状態遷移（3状態） | AC-17 と同じ3通り（finishing はキャンセルしてから） | 画面 | Reading::test_AC27_homeShowsOnlyResumeWhileReading、Reading::test_AC27_homeShowsOnlyResumeWhilePaused、Reading::test_AC27_homeShowsOnlyResumeWhileFinishing | home.startReading が0個、home.resumeReading が1個で label が「坊っちゃん」で始まる |
| AC-28 | R3 | 同値分割（総ページ数なし） | 「こころ」総ページ数なし、最後のページ40、記録2件 | 画面 | Stats::test_AC28_noProgressWithoutTotalPages | book.lastPage「40」、book.progress が0個 |
| AC-29 | R3 | 境界値（前より小さいページ） | 300/72 で今のページ50 | 画面 | Finish::test_AC29_lowerPageMeansRereading | 「記録 2件」、新しい行の session.row.page「0ページ進んだ」、book.lastPage「50」、book.progress「16%」 |
| AC-30 | R9、R2 | 境界値（0、1、180、181） | 経過180分の finishing | 画面 | Finish::test_AC30_minutesOutsideOneToElapsedAreRejected | 0 と 181：session.finish.minutesOutOfRange の label「1から180までの数字で入れてください。」、finishing のまま。1 と 180：誤りの文が消え session.finish.save が有効。最後に「記録 1件」 |

後半（名前と値は前半で決め、テストは後半で書いた。AddBook＝AddBookAcceptanceTests.swift、FinishInput＝FinishInputAcceptanceTests.swift、ReadingScreen＝ReadingScreenAcceptanceTests.swift、Detail＝BookDetailAcceptanceTests.swift、Load＝LoadFailureAcceptanceTests.swift）
| AC | リスク | 技法 | 試す値（境界、遷移、ルールの列） | 種類（API / 画面） | ファイル::テストの名前 | 確かめる結果（具体的な値） |
|---|---|---|---|---|---|---|
| AC-31 | R9 | 境界値（0、1、9999、10000） | 題名「坊っちゃん」、総ページ数を順に入れる | 画面 | AddBook::test_AC31_totalPagesOutsideOneTo9999AreRejected | 0 と 10000：book.save の isEnabled が false、book.add.totalPagesOutOfRange の label「1から9999までの数字で入れてください。」。1 と 9999：book.save の isEnabled が true。閉じた後も本0冊（library.empty.title） |
| AC-32 | R9 | 境界値（9999 と 10000） | 総ページ数なし、最後のページ40、finishing | 画面 | FinishInput::test_AC32_pageAbove9999IsRejectedWithoutTotalPages | 10000：session.finish.pageOutOfRange「0から9999までの数字で入れてください。」、finishing。9999：保存でき「記録 2件」、book.lastPage「9999」、idle（G0 r2 の読み） |
| AC-33 | R1、R2、R7 | 状態（paused で強制終了） | seed-ac33.json の形（5:00 で止めた）、5分後に起動 | 画面 | ReadingScreen::test_AC33_pausedIsRestoredAfterForceQuit | paused、reading.title「坊っちゃん」、label「5分0秒」 |
| AC-34 | R1、R2、R7 | 状態（finishing で強制終了） | 10:00 で終えた finishing、今のページに 72 を入れてから強制終了（入れかけの値は保存しない。PRD 10。欄が空であることに意味を持たせるため）、5分後に起動 | 画面 | FinishInput::test_AC34_finishingIsRestoredAfterForceQuit | finishing、session.finish.minutes「10」、session.finish.page の value が空、最後に「記録 1件」 |
| AC-35 | R1 | 状態遷移（失敗→再試行1回） | UITEST_FAIL=session_finish:1、記録2件、10:00 の finishing | 画面 | FinishInput::test_AC35_retryAfterOneFailureAddsExactlyOne | 再試行1回の後 book.sessionCount「記録 3件」、idle、error.saveFailed が0個。起動し直しても「記録 3件」 |
| AC-36 | R3 | 同値分割（今週0件） | 月曜始まり、先週（10-18）40分だけ | 画面 | Detail::test_AC36_weekTotalIsZeroWithoutSessionsThisWeek | home.weekTotal の value「0分」 |
| AC-37 | R3 | 同値分割（記録0件） | 「坊っちゃん」300/0、記録0件 | 画面 | Detail::test_AC37_bookWithoutSessionsShowsEmptyState | book.totalTime「0分」、book.sessionCount「記録 0件」、book.progress「0%」、book.sessions.empty の label「まだ記録はありません。読書を終えると、ここに残ります。」、book.startReading の isEnabled が true |
| AC-38 | R11 | 状態遷移（確認で取り消す） | 20分と30分、30分の行の削除 → S6 の「キャンセル」（session.delete.cancel。なければ文字「キャンセル」） | 画面 | Detail::test_AC38_cancelDeleteKeepsSession | 「記録 2件」、book.totalTime「50分」 |
| AC-39 | R10 | 代表の1例（表の検査） | ios/Yomutoki/Resources/*.xcstrings（T14） | 文言の表 | ac39-xcstrings.sh::test_AC39_stringCatalogFullyTranslated | `python3 -I contracts/tools/xcstrings_untranslated.py ios/Yomutoki/Resources/*.xcstrings` の最後の行が `untranslated_keys=0`、終了コード0 |
| AC-40 | R10 | ペアワイズ（言語2×経過1） | 経過750秒で止めた reading。ja_JP と en_US の構成 | 画面 | ReadingScreen::test_AC40_elapsedLabelReadsMinutesAndSeconds | reading.elapsed の label が ja「12分30秒」、en「12 minutes, 30 seconds」 |
| AC-41 | R2 | 境界（開始より前の時刻） | reading 経過5:00（読み始め 21:25、今 21:30）の後、時計を読み始めの10分前の 2026-10-21T21:15:00 に set（T16） | 画面 | ReadingScreen::test_AC41_clockSetBackShowsZeroNotNegative | label「0分0秒」、label が「-」で始まる要素が0個、reading のまま |
| AC-42 | R1 | 状態（保存の失敗） | UITEST_FAIL=book_add:*、本1冊、題名「こころ」 | 画面 | AddBook::test_AC42_bookAddFailureKeepsTitle | error.saveFailed「変更を保存できませんでした」と error.retry（label「もう一度保存」）が1個ずつ、book.add.title の value「こころ」。閉じた後の home.bookCount「1冊」、label「こころ」の本の行が0個 |
| AC-43 | R1 | 状態（保存の失敗） | UITEST_FAIL=session_delete:*、20分と30分 | 画面 | Detail::test_AC43_deleteFailureKeepsSession | S7 の error.saveFailed（なければ文字）、OK の後「記録 2件」、book.totalTime「50分」。起動し直しても同じ |
| AC-44 | R3 | 境界（週の境目をまたぐ記録） | 日曜始まり（1）、今日 2026-10-25（日）21:30。土 23:50 に始めた30分、日 9:00 に始めた20分 | 画面 | Detail::test_AC44_sessionAcrossWeekBoundaryCountsInStartWeek | home.weekTotal「20分」 |
| AC-45 | R2 | 状態遷移（finishing の間は止まる） | reading 2:00、終えて60秒後に保存 | 画面 | FinishInput::test_AC45_timeInFinishInputIsNotCounted | 新しい行の session.row.minutes「2分」 |
| AC-46 | R2 | 状態遷移（finishing→reading） | 10:00 で終えてページ72、2分後に session.finish.cancel、続けて終える | 画面 | FinishInput::test_AC46_cancelFinishReturnsToReading | reading、label「10分0秒」か「10分1秒」、記録の数は変わらない。次の S5 の session.finish.page の value が空 |
| AC-47 | R2 | 状態遷移（下書きを捨てる） | 10:00 で終え、分を 10→5、やめて5分後に終える | 画面 | FinishInput::test_AC47_cancelFinishResetsMinutesDraft | finishing、session.finish.minutes の value「15」 |
| AC-48 | R2 | 状態遷移（スワイプで閉じる） | 記録2件、10:00 で終えてページ72、2分後に S5 のナビゲーションバー（session.finish.cancel を含むバー）の中央から画面下部85%まで1回だけ下へ動かす（design 6 の (d)：欄の上でなくバーを起点にする。press 0.05秒、fast、終点での保持0秒。修正前の swipeDown の失敗と根拠は G2-stability-mac-r1） | 画面 | FinishInput::test_AC48_swipeDownDismissEqualsCancel | reading、label「10分0秒」か「10分1秒」、session.finish.save が0個、「記録 2件」 |
| AC-49 | R4 | 代表の1例 | 記録1件の「坊っちゃん」、S2 で「こころ」を追加 | 画面 | AddBook::test_AC49_afterAddShowsNewBookDetail | book.add.title が0個、book.title「こころ」、book.startReading が1個で isHittable が true |
| AC-50 | R4 | 状態遷移（finishing→idle） | 記録1件、home.startReading、10分、終えて保存 | 画面 | FinishInput::test_AC50_afterSaveShowsBookDetail | session.finish.save と reading.finish が0個、book.title「坊っちゃん」、「記録 2件」、idle |
| AC-51 | R4、R2 | 境界値（59秒） | 記録1件、home.startReading、59秒で終える | 画面 | Detail::test_AC51_tooShortShowsNoticeOnBookDetail | session.finish.save が0個、book.title「坊っちゃん」、session.finish.tooShort が1個、「記録 1件」、alerts が0個、idle |
| AC-52 | R5 | 状態遷移（3状態） | 「坊っちゃん」が reading、paused、finishing（キャンセル後） | 画面 | Detail::test_AC52_bookDetailOffersResumeWhileReading、Detail::test_AC52_bookDetailOffersResumeWhilePaused、Detail::test_AC52_bookDetailOffersResumeAfterCancellingFinish | book.resumeReading が1個で isEnabled true、book.startReading と book.start.busy が0個。label は reading と finishing 後「読書に戻る」、paused「一時停止中の読書に戻る」 |
| AC-53 | R11 | 状態遷移（追加をやめる） | 本1冊、「こころ」を入れて book.add.cancel → book.add.discard.confirm（なければ文字「追加せずに閉じる」） | 画面 | AddBook::test_AC53_discardingAddKeepsBookCount | book.add.title が0個、home.bookCount「1冊」、label「こころ」の本の行が0個。起動し直しても同じ |
| AC-54 | R7、R1 | 状態（読み込みの失敗） | seed.example.json と同じ5件、UITEST_FAIL=load:* | 画面 | Load::test_AC54_loadFailureShowsRetryInsteadOfEmpty | error.loadFailed.title「本と記録を読み込めませんでした」、error.loadFailed.message、error.loadFailed.retry「もう一度読み込む」が1個ずつ。library.empty.title、home.bookCount、home.weekTotal、home.startReading が0個 |
| AC-55 | R7、R1 | 状態遷移（失敗→再試行1回） | UITEST_FAIL=load:1 | 画面 | Load::test_AC55_loadRetryRestoresLibrary | error.loadFailed.title が0個、home.bookCount「2冊」、「坊っちゃん」の book.totalTime「60分」、「こころ」の「40分」 |
| AC-56 | R5、R1 | 状態（保存の失敗）×入口2つ | UITEST_FAIL=session_start:1、記録1件。home.startReading と book.startReading | 画面 | Detail::test_AC56_startFailureFromHomeKeepsIdle、Detail::test_AC56_startFailureFromBookDetailKeepsIdle | error.saveFailed と error.retry が1個ずつ、session.state.idle が1個、reading.elapsed が0個、「記録 1件」 |
| AC-57 | R2 | 状態遷移（失敗→60秒→再試行） | AC-56 の2通り、60秒後に error.retry | 画面 | Detail::test_AC57_startRetryFromHomeStartsAtRetryTime、Detail::test_AC57_startRetryFromBookDetailStartsAtRetryTime | reading、reading.title「坊っちゃん」、label「0分0秒」か「0分1秒」、error.saveFailed が0個、「記録 1件」 |
| AC-58 | R2 | 状態（一時停止の失敗） | UITEST_FAIL=session_pause:1、reading 10:00、一時停止して60秒 | 画面 | ReadingScreen::test_AC58_pauseFailureKeepsReading | error.saveFailed と error.retry が1個ずつ、reading、label「11分0秒」か「11分1秒」、「記録 1件」 |
| AC-59 | R2 | 状態遷移（失敗→再試行→60秒） | AC-58 の後に error.retry、60秒 | 画面 | ReadingScreen::test_AC59_pauseRetryStopsAtRetryTime | paused、label「11分0秒」か「11分1秒」、error.saveFailed が0個、「記録 1件」 |
| AC-60 | R2 | 状態（再開の失敗） | UITEST_FAIL=session_resume:1、5:00 の paused、再開して60秒 | 画面 | ReadingScreen::test_AC60_resumeFailureKeepsPaused | error.saveFailed と error.retry が1個ずつ、paused、label「5分0秒」、「記録 1件」 |
| AC-61 | R2 | 状態遷移（失敗→60秒→再試行→60秒） | AC-60 の後に error.retry、60秒 | 画面 | ReadingScreen::test_AC61_resumeRetryStartsAtRetryTime | reading、label「6分0秒」か「6分1秒」、error.saveFailed が0個、「記録 1件」 |
| AC-62 | R2、R1 | 状態（「終える」の失敗）×元の状態2つ | UITEST_FAIL=session_begin_finish:1。(a) reading 10:00、(b) 5:00 の paused。終えて60秒 | 画面 | ReadingScreen::test_AC62_beginFinishFailureWhileReading、ReadingScreen::test_AC62_beginFinishFailureWhilePaused | error.saveFailed と error.retry が1個ずつ、session.finish.save と session.state.finishing が0個。(a) reading、label「11分0秒」か「11分1秒」。(b) paused、label「5分0秒」。「記録 1件」 |
| AC-63 | R2 | 状態遷移（失敗→再試行→60秒） | AC-62 の2通り、error.retry、60秒 | 画面 | ReadingScreen::test_AC63_beginFinishRetryWhileReading、ReadingScreen::test_AC63_beginFinishRetryWhilePaused | finishing、session.finish.save が1個、session.finish.minutes の value (a)「11」(b)「5」、error.saveFailed が0個、「記録 1件」 |
| AC-64 | R1、R2 | 状態（やめるの失敗） | UITEST_FAIL=session_cancel_finish:1、10:00 で終えてページ72、session.finish.cancel、60秒 | 画面 | FinishInput::test_AC64_cancelFinishFailureKeepsInput | error.saveFailed と error.retry が1個ずつ、session.finish.save が1個、finishing（reading は0個）、page の value「72」、minutes の value「10」、「記録 1件」 |
| AC-65 | R2 | 状態遷移（失敗→再試行） | AC-64 の後に error.retry | 画面 | FinishInput::test_AC65_cancelFinishRetryReturnsToReading | session.finish.save が0個、reading、label「10分0秒」か「10分1秒」、error.saveFailed が0個、「記録 1件」 |
| AC-66 | R2、R1 | 境界（60秒未満の失敗） | UITEST_FAIL=session_discard:1、reading 0:30、終えて10秒 | 画面 | ReadingScreen::test_AC66_discardFailureKeepsReading | error.saveFailed と error.retry が1個ずつ、reading、label「0分40秒」か「0分41秒」、session.finish.tooShort と session.finish.save が0個、「記録 1件」 |
| AC-67 | R2 | 状態遷移（失敗→再試行。40秒で押す） | AC-66 の後に error.retry | 画面 | ReadingScreen::test_AC67_discardRetryShowsNoticeWithoutRecord | idle、book.title「坊っちゃん」、session.finish.tooShort が1個、「記録 1件」、reading.elapsed と error.saveFailed が0個、alerts が0個 |

## 3. 試す状態
全行で「自動」「G4 の人」「範囲外」のどれかを選ぶ。範囲外には理由を書く。空欄は不可。
| 状態 | 選んだもの | 作り方 | どのテストで、または理由 |
|---|---|---|---|
| 初めて起動 | 自動 | UITEST_RESET=1（T1）。AppSession.launch(.fresh) | AC-1、AC-2、AC-3、AC-4、AC-20、AC-21。後半は AC-31 |
| データがある | 自動 | UITEST_SEED（T2、T17）。seed は Support/Fixture.swift で組み、同じ形を python で写して ajv で seed.schema.json に合うことを確かめた（21件 valid）。後半のテストの seed も同じ方法で23件 valid（8 と red.log の 5） | AC-5〜AC-19、AC-22〜AC-30。後半は AC-32〜AC-38、AC-40〜AC-67。500冊と10,000件は 9 |
| 前の版からの更新（版を飛ばす更新も） | 範囲外 | － | 001 が最初の版（PRD 12「前の版からの更新：なし」）。前のタグがない。002 で AC にする |
| オフライン、サーバーエラー（500、タイムアウト） | 自動 | 計測の送り先を http://localhost:9、500 を返す受け口、応答しない受け口に向ける（T6、T7、T19）。001 の通信は計測だけ。実機の機内モードは G4 の人 | AC-20 の3本。AC-23、AC-24 は正常な受け口 |
| 権限を断った（その場で、あとから設定で） | 自動 | 起動の前に resetAuthorizationStatus(for:)（camera、photos、location、userTracking）で未回答に戻し、手順の区切りで SpringBoard の alerts を数え、手順の途中の割り込みは addUIInterruptionMonitor で記録して落とす（T12） | AC-21。001 は権限を1つも求めない（PRD 10）ので「その場で断る」「あとから設定で断る」の動きはなく、求めないことを確かめる |
| バックグラウンドから復帰 | 自動 | XCUIDevice.shared.press(.home) の後、時計の URL（T16）で前に出し、activate() | AC-7。強制終了からは AC-8、AC-33、AC-34（後半）。裏に回して戻したときの入力の途中（S2、S5 の入れかけの値）は AC がないので探索 C2 で見て、見つけたことは提案にする |
| 言語と地域（ja、en） | 自動 | Acceptance.xctestplan の構成 ja_JP（language ja、region JP）と en_US（en、US）。起動の引数 -AppleLanguages、-AppleLocale と UITEST_LOCALE も同じ値（T4） | すべてのテストが2構成で動く。AC-40 は ja と en の文字を別に決めている。週の始めは UITEST_FIRST_WEEKDAY で固定（AC-15、AC-24、AC-36、AC-44） |
| 大きい文字、ダークモード | 自動（撮影だけ。判定は G3 の design-reviewer） | G3 で -UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL と `xcrun simctl ui booted appearance dark` で撮る（7 の4通り） | PRD 12 の AX5 とダークは AC がなく、G3 の design-reviewer がスクリーンショットで見る。VoiceOver の操作は G4 の人 |
| 容量不足、電話などの割り込み | 自動（保存の失敗）、G4 の人（割り込み） | 保存の失敗は UITEST_FAIL（T5）で入れる。電話の割り込みはシミュレーターで作れないので G4 の実機 | AC-19、AC-35、AC-42、AC-43、AC-54〜AC-67（後半が多い） |

## 4. テストのつなぎ口と接続先
テストが状態を作るために使うもの。すべて contracts/test-hooks.md にある（足りないものはない）。アプリへは -UITest と UITEST_* だけを渡す。ACCEPTANCE_ で始まる2つは、アプリでなくテストを動かす側（XCTest のランナー）の環境変数で、test plan の構成が渡す。
| 何（初期化、データの投入、接続先、時刻の固定） | 名前（launch argument、環境変数、API） | contracts/ の場所 |
|---|---|---|
| つなぎ口を働かせる | 起動の引数 `-UITest`（AppSession.launch が必ず付ける。Acceptance.xctestplan の commandLineArgumentEntries はランナーに渡るだけ） | test-hooks.md の共通の決まり |
| 初期化 | UITEST_RESET=1 | T1 |
| データの投入 | UITEST_SEED（seed.schema.json。時刻は壁時計） | T2、T17、seed.schema.json |
| 時刻の固定と進め方 | UITEST_NOW、UITEST_CLOCK_FROZEN=1、URL `readingapp-uitest://clock?advance=<秒>` / `set=<壁時計>` / `freeze=<0か1>` を XCUIApplication.open で送り、`uitest.clock.applied` の label が送った数になるのを待つ | T3、T16 |
| 時間帯 | UITEST_TIME_ZONE=Asia/Tokyo | T15 |
| 言語と暦 | `-AppleLanguages (ja)`/`(en)`、`-AppleLocale ja_JP`/`en_US`、UITEST_LOCALE、UITEST_FIRST_WEEKDAY | T4 |
| 保存の失敗 | UITEST_FAIL（例 session_finish:*、book_add:*、load:1） | T5 |
| 状態の名前 | session.state.idle / reading / paused / finishing（descendants(matching: .any) で探す） | T8、design 6 |
| 計測の受け口 | UITEST_TELEMETRY_URL＝http://localhost:<NWListener の空きポート>、UITEST_TELEMETRY_CONTROL_URL（AC-20 だけ別の正常な口）、POST /events と POST /flushed（Support/TelemetryReceiver.swift） | T6、T7、T13、telemetry.md、telemetry-flushed.schema.json |
| 応答しない受け口の待ち | UITEST_TELEMETRY_TIMEOUT=3（受け口は30秒返さずに閉じる） | T19 |
| 計測の代わりの読み口 | UITEST_TELEMETRY_LOG=1 と `uitest.telemetry.log` の value。test plan の ACCEPTANCE_TELEMETRY_PATH を log にすると切り替わる | T22 |
| 端末の再起動 | ac18-reboot.sh（simctl shutdown、boot、bootstatus） | T11 |
| 権限を未回答に戻す | resetAuthorizationStatus(for:) | T12 |
| 経過の最初の表示の区間 | XCTOSSignpostMetric(subsystem: "yomutoki", category: "perf", name: "FirstElapsedShown") | T20 |
| 文言の表の検査 | `python3 -I contracts/tools/xcstrings_untranslated.py ios/Yomutoki/Resources/*.xcstrings` | T14 |
| テストの言語（ランナー側） | ACCEPTANCE_LANG=ja / en（Support/L10n.swift が読む） | アプリに渡さないので契約の外 |

## 5. 動かすコマンドと設定
受け入れテストは、受け入れテストのフォルダの中の設定だけで動かす。
- 設定のファイル（すべて ios/AcceptanceTests/ の中）：target.yml（ターゲット YomutokiAcceptanceTests と、スキーム Yomutoki の testPlans。ios/project.yml が include で読む。testPlans は Acceptance と AC18Reboot の2つだけで、Unit.xctestplan は project.yml の側に defaultPlan 付きで書かれる）、Acceptance.xctestplan（実行順はランダム、Automatic Screen Capture はオンで全部残す、再試行なし、構成 ja_JP と en_US、AC-18 の2本は skippedTests）、AC18Reboot.xctestplan（AC-18 の2本だけ。ac18-reboot.sh が使う）、run-acceptance.sh、ac18-reboot.sh。
- iOS（正本は Makefile の ios-test。macOS と Xcode 26 以降、リポジトリの根で）：`make ios-test`。XcodeGen の取得・検査・生成の後、iPhone 17 で Unit → `bash AcceptanceTests/run-acceptance.sh 'iPhone 17'` → `bash AcceptanceTests/ac18-reboot.sh 'iPhone 17'` の順に動く（最後の2つは ios/ の中から呼ばれる）。前段が失敗した場合は後段に進まない。
- G3 の保存先の例（リポジトリの根で）：`AC_RESULTS_DIR=/tmp/001-acceptance AC18_RESULTS_DIR=/tmp/001-ac18-reboot make ios-test`。run-acceptance.sh は `AC_RESULTS_DIR` に Acceptance.log、Acceptance.xcresult、読めた場合は Acceptance-xcresult.json を残し、末尾に両構成の要約を出す。ac18-reboot.sh は `AC18_RESULTS_DIR` に再起動前後の各ログと .xcresult を残す。いずれもリポジトリの外。スクリプトは同名の前回結果を消すので、実行ごとに未使用の保存先へ変え、以下の参照先もそろえる。
- AC-39（後半）：`bash ios/AcceptanceTests/ac39-xcstrings.sh`（リポジトリの根で。T14 のコマンドを包むだけ。ios_test に入らないので、app.json に足すかは Takuma。P-12）。
- バックエンド：なし（001 は app.json の stacks が ios だけ。backend/tests/acceptance/ は使わない）。
- 判定の実行では再試行を付けない（-retry-tests-on-failure を付けない。xctestplan に testRepetitionMode を書かない）。
- G3 の実行数の確かめ（0本や片方の構成だけで緑になるのを見つける）：`xcrun xcresulttool get test-results summary --path /tmp/001-acceptance/Acceptance.xcresult` で、Acceptance の実行は160本（80本 × 構成 ja_JP と en_US の2つ）、通った160、落ちた0、飛ばした0。AC18Reboot は ac18-reboot.sh の2回の実行がそれぞれ1本（スクリプトが出力の「Executed 1 test, with 0 failures」を grep し、なければ 65 で落ちる。最後の行は「passed 2 of 2」）。数が違えば、その計画の AC は FAIL。
- AC-5 の0.5秒の取り出し（案。動かなければ `xcrun xcresulttool get test-results --help` で確かめる）：`xcrun xcresulttool get test-results metrics --path /tmp/001-acceptance/Acceptance.xcresult --test-id 'YomutokiAcceptanceTests/ReadingSessionAcceptanceTests/test_AC5_startToFirstElapsedMeasuredBySignpost()'` で、XCTOSSignpostMetric（FirstElapsedShown）の5回の値を構成ごとに読む。verification.md に5回の値と平均を貼り、平均が 0.5秒以下なら AC-5 の0.5秒は合格。
- 再試行のボタンの文（design 6 の error.retry.start などの文。AC-56〜AC-66 の Then の外）：`xcrun xcresulttool export attachments --path /tmp/001-acceptance/Acceptance.xcresult --output-path <evidence/>` の後、名前が DESIGN_retryLabel_ で始まる添付を数える。0件でなければ、1件ずつ verification.md に「提案」（design 6 との食い違い）として書く。AC の判定には数えない（L10n.swift の noteRetryLabel）。
- 揺れの確認：影響「大」の AC のテスト（R1〜R7 の AC）と、一度でも落ちたテストを `xcodebuild test … -testPlan Acceptance -only-testing:YomutokiAcceptanceTests/<クラス>/<テスト> -test-iterations 5 -run-tests-until-failure` で5回。AC-18 は ac18-reboot.sh を5回。
- 計測の確かめ方の切り替え：localhost に届かないと G2 の CI で分かったら、Acceptance.xctestplan の両方の構成の ACCEPTANCE_TELEMETRY_PATH を log にする（T22。PRD の根拠：AC-23 の「確かめ方」と test-hooks.md の T6 の備考）。-AppleLocale が効かなくても UITEST_LOCALE を同時に渡しているので、替える所はない。

## 6. 探索のチャーター
影響「大」のリスクごとに1本。G3 で行い、結果は verification.md の8章に書く。
| リスク | チャーター（<対象> を <手段や条件> で探り、<知りたいこと> を見つける） | 区切り（30分か40操作） |
|---|---|---|
| R1 | C1：本と記録と進行中の読書を、保存の途中の強制終了、保存の失敗（T5 の全操作を1回ずつ）の後の強制終了、再起動の連続で探り、消えたり重なったりする記録を見つける | 40操作 |
| R2 | C2：経過の表示を、一時停止と再開の連打、裏に回したままの時計の進めと戻し、S2 と S5 の入力の途中で裏に回して戻す、60秒の前後での「終える」で探り、秒が飛ぶ、負になる、止まらない所を見つける | 40操作 |
| R3 | C3：合計と週の集計を、月曜始まりと日曜始まり、日付をまたぐ記録、記録の削除の後、分を直した記録で探り、表示と seed から計算した値が合わない所を見つける | 30分 |
| R4 | C4：0冊からの流れを、ja と en、長い題名（100字、絵文字）、戻るとスワイプの戻りで探り、主な流れが途中で止まる所や、保存の後に別の画面に出る所を見つける | 40操作 |
| R5 | C5：読書中の状態を、ホームと本の詳細と S4 を行き来し、別の本の詳細から book.openActiveReading で戻る道で探り、読書中が2件になる道や、無効のはずの操作が効く所を見つける | 40操作 |
| R6 | C6：計測の本文を、題名に記号や数字（「72」）を含む本、ページを入れた記録と入れない記録、保存の失敗の後で探り、題名やページの生の値が出る所を見つける（題名は UTF-8、%XX と %xx、JSON の \uXXXX の形でも探す） | 30分 |
| R7 | C7：起動を、読み込みの失敗（load:*、load:1）、reading と paused と finishing が残った状態、時計を戻した状態で探り、起動で落ちる所や空の状態に見える所を見つける | 30分 |

## 7. 画面で確かめるもの
自動のテストで確かめにくいもの。G3 でスクリーンショットを docs/verification/001-reading-session/evidence/ に撮る（テストの XCTAttachment と Automatic Screen Capture から `xcrun xcresulttool export attachments` で書き出す）。
| AC | 手順 | 撮るスクリーンショットのファイル名（AC3_オフライン.png の形） |
|---|---|---|
| AC-1 | 0冊で起動 | AC1_空の状態.png |
| AC-4、AC-5 | 読み始めた直後の S4 | AC4_読書中.png、AC5_読み始めた直後.png |
| AC-6、AC-12 | 保存の後の S3 の記録の行 | AC6_記録の行.png、AC12_分を直した記録.png |
| AC-11、AC-30 | S5 の誤りの文 | AC11_ページが範囲の外.png、AC30_0分.png、AC30_181分.png |
| AC-13 | 60秒未満で終えた後の S3 | AC13_1分未満.png |
| AC-17、AC-27 | 別の本の詳細と、読書中のホーム（3状態） | AC17_<状態>_こころの詳細.png、AC27_<状態>_ホーム.png |
| AC-19 | S5 の保存の失敗 | AC19_保存の失敗.png |
| AC-20 | 3通りの送り先の後の S3 | AC20_届かない先.png、AC20_500.png、AC20_応答しない先.png |
| AC-31〜AC-67（後半） | 範囲の外、読み込みの失敗、各保存の失敗の区画と再試行の後、強制終了から戻った画面 | AC31_総ページ数0.png、AC31_総ページ数10000.png、AC32_ページ10000.png、AC33_起動し直した後.png、AC34_起動し直した後.png、AC35_再試行の後.png、AC36_今週0分.png、AC37_記録0件の詳細.png、AC38_消す確認.png、AC40_経過12分30秒.png、AC41_時計を戻した後.png、AC42_本の追加の失敗.png、AC43_削除の失敗.png、AC44_週をまたぐ記録.png、AC45_記録の行.png、AC46_やめた後.png、AC47_次の終える入力.png、AC48_スワイプで閉じた後.png、AC49_追加した本の詳細.png、AC50_保存の後.png、AC51_1分未満の知らせ.png、AC52_<reading|paused|finishing>_本の詳細.png、AC53_追加をやめる確認.png、AC54_読み込みの失敗.png、AC55_再試行の後.png、AC56_<ホーム|本の詳細>_読み始めの失敗.png、AC57_<ホーム|本の詳細>_読み始めの再試行の後.png、AC58_一時停止の失敗.png、AC59_一時停止の再試行の後.png、AC60_再開の失敗.png、AC61_再開の再試行の後.png、AC62_<reading|paused>_終えるの失敗.png、AC63_<reading|paused>_終えるの再試行の後.png、AC64_やめる保存の失敗.png、AC65_やめる再試行の後.png、AC66_60秒未満で終える失敗.png、AC67_60秒未満の再試行の後.png（テストの XCTAttachment の名前） |
| 全画面 | design/ の S1〜S7 の全状態を、通常はライト、ダーク、AX5、英語の4通り | <画面>_<状態>_<light|dark|ax5|en>.png（G3） |

## 8. 赤の証拠と履歴上の不足
- 2026-10-21 の実装前：XCUITest の82本（AC-1〜AC-38、AC-40〜AC-67）は**その環境では実行できなかった**。Linux 6.18 x86_64 で xcodebuild、xcrun、swift、swiftc がなく、ios/Yomutoki/ と ios/project.yml もなかった（red.log の1〜2）。実装前にビルドや識別子の不足で落ちるという記述は見込みであり、実行結果ではない。実装前の UI 赤実行は未確認のまま残る。
- 2026-10-23 に実ログを補記：[初回 macOS CI run 39775008108](https://github.com/matsuura-tak/reading-app/actions/runs/39775008108)（PR HEAD 807f9341f234bf3018e33ca3b5507af9d731f55b）は**実装後**の実行。Unit 67件成功、Acceptance の回1は80件中34件失敗、回2は80件中35件失敗、`TEST FAILED`、xcodebuild の終了65（make と CI ステップは終了2）。AC-18 の再起動には進んでいない。全失敗69回分の最初のエラー・開始・終了を回番号と原本行番号付きで evidence/history-807f934.log に保存した。これは実装前に機能不足で落ちた証拠ではなく、現在の緑でもその不足を埋めない。
- 初回 CI の失敗には、状態の印が2個、時計 URL で起動し直して seed/reset が再投入されるテスト側の問題、AC-35 の再試行後に詳細に戻れない製品側の問題などが混在する（G2-ci-ruling、G2-mac-r1）。69回の失敗すべてを機能未実装とは扱わない。原因の裁定と、生ログの最初のメッセージを区別する。
- AC-39（Linux で動く。この環境で実行した）：`bash ios/AcceptanceTests/ac39-xcstrings.sh` → 終了コード1、`test_AC39_stringCatalogFullyTranslated: FAIL（ios/Yomutoki/Resources/*.xcstrings が1つもない）`。落ちた理由：String Catalog がまだない＝機能がまだない。書き間違いでないことは、リポジトリの外の写しに1キーの .xcstrings を置き、translated なら exit=0（untranslated_keys=0）、en が needs_review なら exit=1（untranslated_keys=1）になることで確かめた。
- 書き間違いで落ちないための、2026-10-21 の環境での確かめ（red.log の 4、5）：つなぎ口の UITEST_ の名前12個がすべて contracts/test-hooks.md にある（comm の差0行）。後半のテストが使う seed 23個を Fixture.swift どおりに python で写し、`npx -y ajv-cli@5.0.0 validate -s contracts/seed.schema.json` で23個とも valid（終了コード0）、data-model.md の最後の節の制約（lastPage と endPage が totalPages 以下、bookId、state と pausedAt と finishedAt の組、題名100字）も0件。Seeds.libraryOfFive は contracts/seed.example.json と books、sessions が一致。当時は Swift のコンパイル未確認だったが、上記の実装後 CI ではコンパイル後に160回の Acceptance 実行へ進んでいる。
- ログ：docs/verification/001-reading-session/evidence/red.log

## 9. 範囲の外
- 本500冊、記録10,000件でホームと本の詳細が1.0秒以内（PRD 12）：AC がない。UITEST_SEED_BULK（T21）と XCTClockMetric で測れるが、合否の線を持つ AC ではないので、この計画のテストに入れない。測るかは指揮役が G3 で決める。
- 起動から2.0秒（PRD 12）：Release ビルドの実機の測定で G4（設計メモの 6）。
- VoiceOver で全部を操作できること、実機の機内モード、電話などの割り込み：G4 の人。
- 題名の100字の上限（PRD 10。AC がない）：探索 C4 で見て、見つけたことは提案にする。
- 前の版からの更新：001 が最初の版（3 の表）。
- バックエンド：001 にはサーバーがない（contracts/README.md）。

## 確かめ（提出前に verifier が印を付ける。reviewer はこれを信じずに確かめる）
- [x] 読んだファイルが PRD、design/、contracts/ だけで、冒頭に全部並んでいる。（ほかに指示書が挙げた ADR、判定の記録、テンプレート、XcodeGen と XcodeProj の公開のソースを読んだ。冒頭に並べた）
- [x] PRD のすべての AC 番号が、2章とテストの名前にある。AC のないテストがない。（PRD の AC 67個とテストの名前の AC 67個が comm で差0。2章のテストの名前83個とコードの名前83個（XCUITest 82本と ac39-xcstrings.sh の関数1つ）が comm で差0）
- [x] 2章の全行に、技法、試す値、具体的な値の結果がある。「正しく」「適切に」だけの結果がない。
- [x] 影響「大」のリスクのすべてに、自動テスト、3章の行、6章のチャーターがある。（R1〜R7。R6 は前半の AC-23、R7 は前半の AC-8 と後半の AC-54、AC-55）
- [x] 3章の9行すべてに選んだものがあり、範囲外には理由がある。
- [x] 4章のつなぎ口がすべて contracts/ にあるか、「未解決」に依頼として書いた。（すべて contracts/ にある）
- [x] 受け入れテストのフォルダで、sleep、skip、xfail、XCTExpectFailure、retry、@testable import が0件（grep のコマンドと件数を報告に書いた）。（xctestplan の skippedTests の2行を除く。retry に当たるのは、アプリの再試行の識別子 error.retry と error.loadFailed.retry、その文字の L10n.errorRetry*、errorLoadFailedRetry、design 6 の再試行のボタンの文を見る noteRetryLabel とその添付の名前 DESIGN_retryLabel_（G2 r1 の提案5。AC の判定に数えない）、2章で決めたテストの名前（AC-35、AC-57、AC-59、AC-61、AC-63、AC-65、AC-67 の「Retry」。AC の中身がアプリの再試行）と、target.yml の「再試行しない」の注記1行だけ。テストを動かす側の再試行（-retry-tests-on-failure、testRepetitionMode）は0件）
- [ ] 8章の赤の証拠があり、落ちた理由が書き間違いではなく「機能がまだない」こと。（AC-39 は実装前に String Catalog がないことで終了1。XCUITest の82本は実装前に実行できず、その赤実行は未確認。red.log の6と history-807f934.log に補記した初回 macOS CI は実装後なので、この項目は完了にしない）
