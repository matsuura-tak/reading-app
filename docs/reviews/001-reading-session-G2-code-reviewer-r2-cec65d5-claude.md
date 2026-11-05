PASS

> 指揮役の注（2026-11-05）：この報告は 2026-10-22 に Claude のセッションの reviewer が HEAD cec65d5／1ad1744 に対して出したもの。同じ名前のファイル docs/reviews/001-reading-session-G2-code-reviewer-r2.md は Takuma の側の reviewer が 6442fe2 に対して出した判定で、そちらが PR #2 の正となる。この報告は履歴として別名で残す。

# 001-reading-session G2 コードの判定 r2（reviewer）

- 日付：2026-10-22
- 対象：HEAD cec65d5 の ios/Yomutoki/、ios/YomutokiTests/、ios/project.yml（r1 の対象 fd586ac からの差分 9 ファイル：c11db99、8034689（ios-engineer）、6f714ed、0cda7b6、3710550（Takuma））
- 証拠：CI run 22（ios ジョブ 39819724404、cec65d5）。ios_build 通過、単体テストの計画は終了 0、受け入れテスト ja_JP 80/80・en_US 80/80（xcresulttool の集計も両構成 80/0/0）。ac18-reboot.sh の simctl の扱いはこの判定の対象外（verifier が直している）
- 指揮役の注：r2 は読み取りだけの reviewer の報告を指揮役がそのまま保存したもの。

## 理由
r1 の FAIL の理由はコンパイルと CI を動かせていないことだった。今回それは CI run 22 で埋まった。
- CI の実行スクリプトは最初に失敗したコマンドで止まる作り（`sys.exit(code)`）。その上で ios_test が動いているので、ios_build（Debug と Release のビルド、entitlements、UITEST_ の grep、Release の strings、CFBundleURLTypes）は cec65d5 で通っている。
- ios_test は `xcodebuild test -testPlan Unit … && bash AcceptanceTests/run-acceptance.sh …` の順で動く。受け入れテストまで進んだので、単体テストの計画は終了コード 0 だった。
- 受け入れテストは ja_JP 80/80、en_US 80/80 が通った。xcresulttool の集計は両構成とも「通過 80、失敗 0、飛ばした 0」。
- r1 の要修正 1、2 と提案 3、6、7、9、11、12、13 はコードか文書で直っている。提案 4、5 は CI で AC-43、AC-34 が両構成で通ったことで解消。提案 8 は G3、提案 10 は G5 で見る項目として残る。
- Takuma の 3 コミットは契約と設計メモの決まりに反していない（下の表）。r2 の新しい重大は 0 件。
- PASS は指示書の範囲での判定。AC-18 は G3 の前に通る必要がある（未検証の 1）。

## 指摘
- 重大：なし。
- 要修正：なし（r1 の要修正 1、2 はどちらも直っている）。
- 提案：r2 で新しく足す提案はない。r1 から残るのは次の 2 件で、判定には数えない。
  - 提案 8（r1）：FinishSessionView.swift:142-150 の S5 の欄が HStack のままで、LabeledContent でも ViewThatFits でもない。G3 の Double-Length の画面で design-reviewer が判断する。
  - 提案 10（r1）：ios/Yomutoki/Resources/Assets.xcassets/AppIcon.appiconset に Contents.json だけがあり、画像が 0 件。G5 の前に要る。

## r1 の指摘の解消
| r1 | 中身 | 解消したコミット | 今の場所と確かめたこと | 結果 |
|---|---|---|---|---|
| 要修正1 | 1pt の要素（UITestMarker）と showsStateMarker が Debug/ の外にあった（ADR 0005） | 8034689（外した）、059a6dc（ADR 0005 と T8 に取り下げを追記） | `grep -rnE 'showsStateMarker\|UITestMarker' ios/Yomutoki --include='*.swift' \| grep -v '/Debug/'` が 0 行。定義と呼び出しは Debug/UITestHooks.swift:771、:796、:799 だけ。ADR 0005 の 2026-10-22 の追記と T8 の備考の取り下げを確認 | 直った |
| 要修正2 | 契約の一覧の順が実装と違った | f8ccf89 | contracts/data-model.md:57「前の本（上の決め方）を先頭に置く」と LibraryStore.swift:465-479 が一致 | 直った |
| 提案3 | 追加の二度押し | c11db99 | AddBookView.swift:15、:65、:131 の `.disabled(!canSave \|\| didSave)`、:165 の guard、:169（didSave は保存が通った後に立てる） | 直った |
| 提案4 | S6 の alert から S7 が出るか | コードは変えず、CI で確認 | test_AC43_deleteFailureKeepsSession が S7 の `app.alerts` を待って確かめる（BookDetailAcceptanceTests.swift:95-96）。run 22 で ja 回1 #28、en 回2 #5 が passed | 解消（CI） |
| 提案5 | finishing を戻したときに S5 が開くか（AC-34） | コードは変えず、CI で確認 | test_AC34_finishingIsRestoredAfterForceQuit が回1 #50、回2 #69 で passed | 解消（CI） |
| 提案6 | finish() が今の時刻を 2 回読む | c11db99 | LibraryStore.swift:240 で 1 回だけ読み、:242 と :245 に渡す。:250 と :271 は引数の now を使う。呼び出し元は finish() だけ | 直った |
| 提案7 | TimelineView の起点 | c11db99 | ReadingView.swift:278 が `.periodic(from: .now, by: 1)`。設計メモ 11 の 7 の追記の例外どおり（経過は :295 で AppClock から計算） | 直った |
| 提案8 | S5 の欄の形 | なし | FinishSessionView.swift:142-150 のまま | 残り（G3） |
| 提案9 | S3 の ProgressView をすぐ出していた | c11db99 | BookDetailView.swift:20、:92-107 で 1 秒待ってから出す（D-39。S1 の HomeView.swift:75-90 と同じ作り） | 直った |
| 提案10 | AppIcon の画像 | なし | 画像 0 件 | 残り（G5） |
| 提案11 | 値の型に nonisolated がない | c11db99 | RootView.swift:4 の Route、ReadingView.swift:4、:12、:19、AddBookView.swift:18、FinishSessionView.swift:11 | 直った |
| 提案12 | ActiveReading 2 件のテストがファイルの保存先にない | c11db99 | LibraryStoreTests.swift:498-542 の twoActiveReadingsOnDiskFailLoadAndKeepFile | 直った |
| 提案13 | 設計メモの autosave の件数 | 9e78bed（tech-lead） | 設計メモ 11 の 2「2件」。grep で LibraryStore.swift:379 と Debug/UITestHooks.swift:531 の 2 件 | 直った |

## Takuma の 3 コミットの判定
| コミット | 決まり | 判定と根拠 |
|---|---|---|
| 6f714ed：LibraryStore.finishSession の beforeRollback | 1 操作 1 save | 合う。save は commit の 1 回だけ（LibraryStore.swift:395）。閉包は catch の中だけで呼ばれ、既定は `{}` なので、ほかの 7 か所の commit の動きは変わらない |
| | 失敗は rollback、状態を変えない（data-model.md:63-64） | 合う。:397 で閉包を呼んだ後も :398 で rollback し、Save Failed を出して throw する。メモリの状態（sessionModels、active、books）を変える行は :342 以降で、throw より後にある |
| | 閉包の 2 行と rollback の重なり | `book.lastPage = previousLastPage` は rollback と同じことをする二重の処理だが、結果は同じで無害。previousLastPage は :322 で読む値で、保存済みの値と同じ（どの操作も save か rollback で終わるので、未保存の変更を持ち越さない。commit の呼び出し 8 か所を確認）。`session.book = nil` は新しい記録だけに効く。逆参照（Schema.swift:30-31 の Book.sessions。inverse は ReadingSession.book）から外すだけで、その記録は rollback で捨てられ、throw が先なので sessionModels にも入らない。ActiveReading.book（Schema.swift:72）には inverse がないので、startReading の再試行には同じ問題はない。副作用は見つからなかった |
| | 単体テスト | 合う。finishFailureThenRetrySavesExactlyOne と finishFailureThenRetryOnDiskSeed(nil/72) が確かめていること：失敗の後は記録 2 件、lastPage 40、ActiveReading 1 件。再試行の後は記録 3 件、pagesRead＝endPage−40（data-model.md:32）、lastPage＝endPage か 40、Save Failed 1 回、Finished 1 回。別のコンテナで開き直しても 3 件と 0 件。AC-35 の Given と Then の形と同じ |
| 0cda7b6：AddBookView を router.isAddBookPresented = false で閉じる | 画面の状態、識別子、ADR 0005 | 合う。シートを出す側は RootView.swift:102 の `$router.isAddBookPresented` だけ。キャンセルでは pendingAddedBookID が nil なので、onDismiss（:43-48）は S3 を積まない。保存は関わらない。識別子と色の変更はない。CI で AC-3（回1 #10、回2 #21）、AC-53（#22、#32）、AC-49（#20、#30）が passed |
| 3710550：HomeView の startFailed を router.path が空でなくなったときに消す | 保存が通ってから状態を変える、design「S1 を離れると消える」（HomeView.swift:10） | 合う。成功したときは :244 で消してから openReading。失敗の表示は、S3 か S4 を積んで path が空でなくなったときだけ消える（:34-36）。Route は Hashable（RootView.swift:4）。CI で AC-56 の 2 通り（回1 #24、#27、回2 #2、#4）と AC-57 の 2 通り（回1 #32、#36、回2 #3、#11）が passed |
| 3 コミット共通 | Date() は AppClock だけ、色の直書きなし、UITEST_ は Debug/ だけ、識別子は design 6 だけ | 合う（証拠の grep。r2 の差分で足した accessibilityIdentifier は 0 行） |

参考（指摘ではない）：BookDetailView は今も onDisappear で startFailed を消している（BookDetailView.swift:37、:335-336）。3710550 が HomeView で替えた作りと同じ。ただし S3 からの AC-56 と AC-57 は両構成で通っており、不具合の証拠はない。

## 裁定 (a) の確認（CI の裁定 1）
1pt の要素を外した後、session.state.* は RootView.swift:112-113 と FinishSessionView.swift:98-99 の根の識別子だけになった。run 22 では次が両構成で通った。
- AC-56 の `XCTAssertEqual(s.count("session.state.idle"), 1, …)`（BookDetailAcceptanceTests.swift:236）。
- `expectState`（UIHelpers.swift:168-173）を使う S4 と S5 のテスト：AC-62 (a)(b)、AC-63 (a)(b)、AC-64、AC-46、AC-48、AC-34。
これで S1、S3、S4（積んだ画面）、S5（シート）の根の識別子が XCUITest から見えることが確かめられ、裁定 1 の「いちばん強い反論」（S4 と S5 は未確認）は解消した。

## 証拠（抜粋。実行したコマンドと結果）
- `git diff --stat cec65d5 -- ios/Yomutoki ios/YomutokiTests ios/project.yml` → 空。`git diff --name-only fd586ac..cec65d5 -- …` → 9 件。
- `git diff --name-only fd586ac...cec65d5 | grep -E '(AcceptanceTests|tests/acceptance)/|^\.claude/|^\.github/|\.xctestplan$|…'` → .claude/org/app.json、.claude/org/lock.json、.github/workflows/ios.yml（a4065e3、Takuma。docs/approvals/001-reading-session-ci-settings.md に許可）、ios/AcceptanceTests/ の 16 件（e43d611、2ed7279（verifier）、3c3f790（Takuma））。ios-engineer の差分には 0 件。
- `git diff -U0 fd586ac...cec65d5 | grep -E '^\+.*(XCTSkip|\.disabled\(|withKnownIssue|XCTExpectFailure|…)'` → 本番の差分は `.disabled(!canSave || didSave)` の 2 行だけ。XCTSkip、withKnownIssue、XCTExpectFailure は 0。
- アサーションの数：`git diff -U0 fd586ac...cec65d5 -- '*Tests*' '*tests*' | grep -iE '^[-+][^-+].*(assert|#expect|#require)'` → `62 +`、`4 -`（−4 は `s.count`／`isEnabled` を同じ期待値のまま `buttonCount`／`control(...)` に置き換えたもの）。ios/YomutokiTests だけでは `55 +`。
- 依存の変更なし（Package.resolved、*.lock → 0 行）。
- 設計メモ 11 の grep：foregroundStyle(.primary…) 0、autosaveEnabled = false は LibraryStore.swift:379 と Debug/UITestHooks.swift:531、Date() は AppClock と Debug/ だけ、`.now` は ReadingView.swift:278 だけ、showsStateMarker|UITestMarker（Debug/ の外）0、UITEST_／readingapp-uitest／"uitest.（Debug/ と AcceptanceTests/ の外）0、URLSession（Debug/ の外）0、BGTaskScheduler 等 0、NSAllowsArbitraryLoads 0、privacy: .public は LibraryStore.swift:399 の 1 件。
- 書き方の grep：try!、as!、@unchecked、nonisolated(unsafe)、TODO、FIXME → 0。fatalError は Debug/UITestHooks.swift:704、:754、:765（契約どおり）。try? は #Preview とテストの defer だけ。色の直書き 0。
- `grep -c '@Test' ios/YomutokiTests/*.swift` → 69（Takuma の Mac の記録と一致）。Unit.xctestplan に skippedTests なし。
- `python3 -I contracts/tools/xcstrings_untranslated.py ios/Yomutoki/Resources/*.xcstrings` → untranslated_keys=0（AC-39）。
- `git diff --stat 3710550 cec65d5 -- ios/Yomutoki ios/YomutokiTests ios/project.yml` → 空（Takuma の Mac の記録はこの HEAD と同じコード）。`git diff --stat a4065e3 cec65d5 -- …` → 8 ファイル +147/−42。全部読み、警告を出しそうな書き方はなかった。
- CI のログ：ios-a4065e3.log（109 xcodegen OK、111 Xcode 26.6、925・1493 BUILD SUCCEEDED、1495 CFBundleURLTypes なし、Swift の警告 0）、ios-cec65d5.log（4606 TEST SUCCEEDED、4610-4867 の要約：両回 80/0、[AT-DIAG] 0 行、xcresulttool 両構成 80/0/0、testFailures 0。4956 以降 AC18 の前半 PASS と simctl 405）。
- 読んだファイル：ios/Yomutoki の App/YomutokiApp、Model/LibraryStore、Screens/{AddBook,BookDetail,FinishSession,Home,Reading,Root}View（全体）、ios/YomutokiTests/LibraryStoreTests（差分 168 行と StoreHarness）。ios/project.yml と Unit.xctestplan は差分 0。

## AC 対応表（r2 で変わった所。結果は run 22）
| AC | 実装 | テスト | 結果 |
|---|---|---|---|
| AC-35、AC-19 | LibraryStore.swift:322、:334-340、:390-405 | test_AC35、test_AC19、単体 finishFailureThenRetry* 3 件 | AC-35 は回1 #59、回2 #63 で passed。AC-19 は回1 #14 で passed。単体は終了 0 |
| AC-3、AC-53、AC-42、AC-49 | AddBookView.swift:15、:65、:131、:139、:165-171、:187 | test_AC3、test_AC53、test_AC42、test_AC49 | 両構成で passed |
| AC-56、AC-57 | HomeView.swift:34-36、:240-255 | test_AC56 ×2、test_AC57 ×2 | 両構成で passed |
| AC-13、62、63、66、67 | LibraryStore.swift:237-286 | test_AC13 ×2、test_AC62 ×2、test_AC63 ×2、test_AC66、test_AC67 | 両構成で passed |
| AC-7、40、41 | ReadingView.swift:278、:294-296 | test_AC7、test_AC40、test_AC41 | 両構成で passed |
| AC-43、34、48 | BookDetailView.swift:38-61、:319-326、ReadingView.swift:44-47、:166-178 | test_AC43、test_AC34、test_AC48 | 両構成で passed |
| data-model.md:36 | LibraryStore.swift:94-114、:455-463 | 単体 twoActiveReadingsOnDiskFailLoadAndKeepFile | 単体は終了 0 |
| 全体 | － | Acceptance.xctestplan の 80 本 ×2 構成 | 両構成 80/0/0 |
| AC-39 | Localizable.xcstrings | xcstrings_untranslated.py | untranslated_keys=0 |
| AC-18 | 変わっていない | ac18-reboot.sh | 前半 passed。後半は simctl の SimError 405 で動いていない（未検証 1） |

範囲の外の変更：ios-engineer と Takuma の ios/Yomutoki 側の差分は、どれも r1 の提案、CI の裁定 1、AC-35、AC-3、AC-56 に紐づく。開いた URL：なし。

## 未検証
1. AC-18 の後半（再起動の後）：ac18-reboot.sh が simctl の shutdown で止まり、動いていない。AC-18 に関わるコード（Schema、保存先、entitlements）は r2 で変わっていない。G3 の前に verifier の直した ac18-reboot.sh で通る必要がある。
2. cec65d5 のコンパイル警告の行そのもの：run 22 のビルドの部分は末尾 4,999 行の外。補った証拠：a4065e3 の CI のログで Swift の警告 0 件、その後の差分（8 ファイル）を全部読んだこと、同じコードでの Takuma の Mac の記録「Swift の新しい警告は 0 件」。
3. 単体テストの件数を CI で直接は見ていない：計画が終了 0 だったことは && の順から。69 件は @Test の数と Takuma の記録で補った。
4. 後の関門で見るもの：Xcode 27.1 / iOS 26.0（Mac）の `Invalid frame dimension` の実行時警告 6 件（発生元不明。G3 の画面の確認で見る）、iOS 17 での確認（G4 の前）、AppIcon（G5 の前）、S5 の欄の形（G3 の design-reviewer）、run 21 で ja_JP の 3 本（AC-60、AC-62 (b)、AC-63 (a)）が落ちて run 22 で通ったこと（揺れの可能性。G3 で verifier が確かめる）。
