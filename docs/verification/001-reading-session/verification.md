FAIL

# 検証レポート 001-reading-session（G3・画面/監査の第1フェーズ）

- 検証役：verifier。実行・画像確認：2026-10-23 16:56〜17:07 JST、証拠に基づく最終整理：同日22:37 JST以降。
- 固定コミット：`6442fe2e5b1ad1f4956123c938076c6da462b874`。ブランチ：`claude/cool-ptolemy-17gnb3`。作業コピー：`/private/tmp/reading-app-pr2-20261023-resume`。
- 環境：macOS 27.0.1（26A434）、Xcode 27.1（27A9275）、専用 iPhone 17 / iOS 26.0（23A343）、UDID `B18DB71A-DB50-4F84-9DDD-7D63541CF3BB`。バックエンドなし。
- CI環境は別：iPhone 17 / iOS 26.5。全体CIを今回verifierが新規実行したとは扱わない。固定HEADの取得済み完全ログを読み、日英各80件・AC18前後2件の実行と結果を照合した。
- 7画面のlight監査、正常表示の代表状態32枚（S4 reading/pausedを含む8状態×4条件）、AX5での分の編集・保存・再起動後保持を確認した。一方、全状態の画面証拠、高リスク/過去失敗テストの全5回、探索C1〜C7などは未完。監査指摘23件も未解決で、全G3のPASSではない。
- 製品コードは開かず、製品ソース・既存受け入れテスト・設定の変更0。一時ハーネスは削除済みで、実行時ソースはevidence内の`.swift.txt`に保存。コミット・pushはしていない。

## 指摘

1. 要修正（関門の未完了、AC-1〜AC-67）：CIの単回成功を全G3の合格に読み替えない。現在のテスト定義とCI実行対応は確認できたが、verifier自身の全体判定実行と要求する反復・探索・全状態証拠の完了には数えない。2章のCI実行数と今回自身の実行数を分けた。
2. 提案・未解決（番号付きACの外、PRD12/design9）：7画面の`performAccessibilityAudit(for: .all)`で計23件。Dynamic Type18、contrast2、hitRegion3。handlerは全件`false`を返し、除外していない。6画面は監査FAIL、S4 readingは指摘0。7章と全findingを参照。
3. 提案・未解決（番号付きACの外、PRD12）：S5で`Invalid frame dimension (negative or non-finite)`が残る（r2 4件、r3 1件、r4 1件）。原因未特定。r4の操作成功で警告が消えたとはしない。
4. ハーネスの問題と製品を区別：r1は重複変数名によるcompile error。r2のAX5失敗2件は不適切なスワイプと、表示範囲外の件数をStaticTextに限定して待つ問題。r3もスワイプ始点がキーボード上の帯に重なり1件失敗。r4は帯を避けるスワイプ1回で欄へ到達し、5分に編集・保存・再起動後保持まで成功した。既存の失敗ログは消していない。

## 証拠

本文の`E/`は`docs/verification/001-reading-session/evidence/g3-20261023/`を指す。CI全体の原本は`/private/tmp/reading-app-pr2-ci-6442fe2-20261023.log`、取得・終了の記録は`docs/reviews/001-reading-session-G2-ci-6442fe2.md`。CI行番号は制御文字を改行扱いにせず、原本をLFで分割して数えた。`E/ci-6442fe2-excerpts.log`と`E/ci-6442fe2-test-cases.json`に対応を保存。

## 1. 実行したコマンドと結果

### 固定HEADの既存CI（今回新規に全体実行したものではない）

- [CI run 39895904848](https://github.com/matsuura-tak/reading-app/actions/runs/39895904848)、SUCCESS。コマンドはMakefileの`make ios-build` / `make ios-test`（後者はUnit→Acceptance→AC18の順）。Acceptanceのxcodebuild終了0。単体69件、通常Acceptance ja_JP/en_US各80成功・失敗0・skip0、AC18 seed/再起動後各1成功・skip0。
- 生のpassedは162回、固有82メソッド。AC39は別シェルのためCIの162回には入らない。原本LF行：Unit2759、構成18244/18245、AC18最終18471。
- AC5 FirstElapsedShown、原本8536：0.091929, 0.106902, 0.080491, 0.082020, 0.072084秒、算術平均0.0866852秒。原本12638：0.087190, 0.083408, 0.067250, 0.070336, 0.072002秒、平均0.0760372秒。どちらも0.5秒以下。明示的な対応のない回順を言語名に読み替えない。

### 一時ハーネス r1 / r2

r1は指揮役の実行代行。`E/g3-visual-r1-compile.log`：137行のローカル変数`title`の再宣言でビルド失敗、UI実行0。製品不良ではない。親が終了65を確認した実行で、保存ログには`TEST FAILED`を残す。

r2の実行は指揮役が開始し、verifierが結果回収と画像確認を引き継いだ。実際のコマンド：

```sh
xcodebuild test -project ios/Yomutoki.xcodeproj -scheme Yomutoki -testPlan Acceptance -only-test-configuration ja_JP -only-testing:YomutokiAcceptanceTests/G3VisualAuditTemporaryTests -destination 'platform=iOS Simulator,id=B18DB71A-DB50-4F84-9DDD-7D63541CF3BB' -resultBundlePath /private/tmp/reading-app-g3-visual-r2-20261023.xcresult CODE_SIGNING_ALLOWED=NO
```

- `E/g3-visual-r2.log`、`E/g3-visual-r2-summary.json`：4メソッド、成功2（dark/en）、失敗2（ax5/light）、skip0。XCTestのfailureイベントは25件（AX5ハーネス2＋監査23）で、25テストが落ちた意味ではない。`TEST FAILED`、xcresultもFailed。開始した親セッションの数値終了コードはverifierから再取得できず、数値の自己確認とは扱わない。
- `ja_JP`はランナー構成。各アプリ起動のAppleLanguages/AppleLocale/category/appearanceをハーネスで独立指定し、enは`(en)`/`en_US`、AX5は`UICTContentSizeCategoryAccessibilityXXXL`。英語を日本語UIに変更していない。
- 監査はlightのS1〜S7、`.all`。S4 pausedは撮影のみで追加監査していない。

### AX5追加 r3（失敗を保持）

```sh
xcodebuild test -project ios/Yomutoki.xcodeproj -scheme Yomutoki -testPlan Acceptance -only-test-configuration ja_JP -only-testing:YomutokiAcceptanceTests/G3VisualAuditTemporaryTests/test_G3_ax5_formInteraction -only-testing:YomutokiAcceptanceTests/G3VisualAuditTemporaryTests/test_G3_ax5_alerts -destination 'platform=iOS Simulator,id=B18DB71A-DB50-4F84-9DDD-7D63541CF3BB' -resultBundlePath /private/tmp/reading-app-g3-ax5-r3-20261023.xcresult CODE_SIGNING_ALLOWED=NO
```

- 終了65。成功1（AX5 S6/S7）、失敗1（フォームの到達性assertion）、skip0、failureイベント1。`E/g3-ax5-r3.log` / `E/g3-ax5-r3-summary.json`。
- スワイプ始点y=508はtreeにあるキーボード上Toolbarの上端y=508と重なる。欄に直接tapするとXCTestが自動スクロールし、編集10→5、保存、件数2、新行5分、再起動後件数2のassertionは通った。ただし自動スクロールだけでは利用者の手動到達性の証明にしない。

### AX5/英語追加 r4（ハーネス座標の修正）

```sh
xcodebuild test -project ios/Yomutoki.xcodeproj -scheme Yomutoki -testPlan Acceptance -only-test-configuration ja_JP -only-testing:YomutokiAcceptanceTests/G3VisualAuditTemporaryTests/test_G3_ax5_formInteraction -only-testing:YomutokiAcceptanceTests/G3VisualAuditTemporaryTests/test_G3_en_cleanS2 -destination 'platform=iOS Simulator,id=B18DB71A-DB50-4F84-9DDD-7D63541CF3BB' -resultBundlePath /private/tmp/reading-app-g3-additional-r4-20261023.xcresult CODE_SIGNING_ALLOWED=NO
```

- 終了0。成功2、失敗0、skip0。`E/g3-additional-r4.log` / `E/g3-additional-r4-summary.json`。再試行オプションは付けていない。ハーネスの操作方法を証拠に基づいて直した別実行で、r2/r3の失敗を抹消したものではない。
- Toolbarより60pt上（y=448）からフォーム内へ1回スワイプ。minutesがisHittable=trueとなった後にtapし、10→5と編集、キーボード上の保存を操作。S3へ遷移、スクロール後「記録 2件」、新しい行「5分」。seed/resetなしで終了・起動し直し、同じ件数2を確認した。通常AC12の180→45等の所定入力をこの補助観測で置き換えない。
- S2 enに写ったOSキーボードの初回説明は、システムのContinueで閉じて追加撮影。元画像も保持。

### AC39（今回verifierが実行）

`bash ios/AcceptanceTests/ac39-xcstrings.sh`：終了0、検査1件成功、翻訳不足0。`E/ac39-catalog.log`。正負対照の新規実行は本フェーズでは行っていない。

## 2. 受け入れ条件ごとの結果

CI欄は固定HEADの**既存CI**で実際に動いた固有メソッド数/実行回数。通常は日英で同じ1本を2回、AC18は別の2本を各1回。今回自身のAC判定実行はAC39のみで、画面補助ハーネスは所定ACテストの代用に数えない。skipはCI・今回とも0。全体G3の未完項目を残すため、AC39以外は最終判定を未検証とした（単回CIには失敗0）。全メソッド・各回数の照合根拠は`E/ci-6442fe2-test-cases.json`。AC18の2本を通常計画から外す設定は別計画で実行済みで、実行時スキップとは区別する。

| AC | G3結果 | CI固有 / 実行回数 / skip | 今回自身のAC実行 / skip | 証拠（原本LF行・メソッド） |
|---|---|---|---|---|
| AC-1 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 6533, 10666。`LibraryAcceptanceTests.test_AC1_emptyLibraryShowsEmptyStateAndOnlyAddBook` |
| AC-2 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 6667, 10645。`LibraryAcceptanceTests.test_AC2_addBookWithTitleOnly` |
| AC-3 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 6511, 11175。`LibraryAcceptanceTests.test_AC3_blankTitleCannotBeSaved` |
| AC-4 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 6603, 10581。`LibraryAcceptanceTests.test_AC4_zeroBooksToReadingInThreeTapsOrFewer` |
| AC-5 | 未検証（G3完了条件未達） | 2 / 4 / 0 | 0 / 0 | CI原本LF行 8119, 8538, 12468, 12640。`ReadingSessionAcceptanceTests.test_AC5_previousBookStartsFromHomeInOneTap`<br>`ReadingSessionAcceptanceTests.test_AC5_startToFirstElapsedMeasuredBySignpost` |
| AC-6 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 8382, 12991。`ReadingSessionAcceptanceTests.test_AC6_pausedTimeIsNotCounted` |
| AC-7 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 8259, 13149。`ReadingSessionAcceptanceTests.test_AC7_elapsedKeepsRunningInBackground` |
| AC-8 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 8589, 12519。`ReadingSessionAcceptanceTests.test_AC8_forceQuitRestoresReadingAndElapsed` |
| AC-9 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 10021, 14667。`FinishSessionAcceptanceTests.test_AC9_enteringPageRecordsProgress` |
| AC-10 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 10204, 15056。`FinishSessionAcceptanceTests.test_AC10_finishWithoutPage` |
| AC-11 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 10345, 14359。`FinishSessionAcceptanceTests.test_AC11_pageAboveTotalPagesIsRejected` |
| AC-12 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 9911, 14746。`FinishSessionAcceptanceTests.test_AC12_editMinutesWhenFinishing` |
| AC-13 | 未検証（G3完了条件未達） | 2 / 4 / 0 | 0 / 0 | CI原本LF行 8060, 8860, 13042, 13096。`ReadingSessionAcceptanceTests.test_AC13_boundarySixtySecondsOpensFinishInput`<br>`ReadingSessionAcceptanceTests.test_AC13_underOneMinuteIsNotRecorded` |
| AC-14 | 未検証（G3完了条件未達） | 2 / 4 / 0 | 0 / 0 | CI原本LF行 4122, 4262, 12179, 12229。`BookStatsAcceptanceTests.test_AC14_bookTotalsAreShown`<br>`BookStatsAcceptanceTests.test_AC14_totalAddsSecondsBeforeFlooring` |
| AC-15 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 4228, 12195。`BookStatsAcceptanceTests.test_AC15_weekTotalExcludesLastWeek` |
| AC-16 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 4212, 12151。`BookStatsAcceptanceTests.test_AC16_deleteSessionKeepsLastPage` |
| AC-17 | 未検証（G3完了条件未達） | 3 / 6 / 0 | 0 / 0 | CI原本LF行 8206, 8741, 9023, 12322, 12409, 12827。`ReadingSessionAcceptanceTests.test_AC17_cannotStartAnotherBookWhileFinishing`<br>`ReadingSessionAcceptanceTests.test_AC17_cannotStartAnotherBookWhilePaused`<br>`ReadingSessionAcceptanceTests.test_AC17_cannotStartAnotherBookWhileReading` |
| AC-18 | 未検証（G3完了条件未達） | 2 / 2 / 0 | 0 / 0 | CI原本LF行 18323, 18453。`AC18RebootTests.test_AC18_1_seedLibraryBeforeReboot`<br>`AC18RebootTests.test_AC18_2_libraryRemainsAfterReboot` |
| AC-19 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 10134, 14557。`FinishSessionAcceptanceTests.test_AC19_saveFailureKeepsFinishingSession` |
| AC-20 | 未検証（G3完了条件未達） | 3 / 6 / 0 | 0 / 0 | CI原本LF行 5676, 5835, 5998, 11463, 11626, 11901。`TelemetryAndPrivacyAcceptanceTests.test_AC20_allOperationsWorkWhenTelemetryHangs`<br>`TelemetryAndPrivacyAcceptanceTests.test_AC20_allOperationsWorkWhenTelemetryIsUnreachable`<br>`TelemetryAndPrivacyAcceptanceTests.test_AC20_allOperationsWorkWhenTelemetryReturns500` |
| AC-21 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 5393, 11745。`TelemetryAndPrivacyAcceptanceTests.test_AC21_noPermissionPromptsDuringFirstSession` |
| AC-22 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 6736, 10511。`LibraryAcceptanceTests.test_AC22_twentyFirstBookHasNoLimitOrPaywall` |
| AC-23 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 5283, 11305。`TelemetryAndPrivacyAcceptanceTests.test_AC23_telemetryHasNoTitleOrPageValues` |
| AC-24 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 5520, 12029。`TelemetryAndPrivacyAcceptanceTests.test_AC24_weekReachedIsSentOncePerWeek` |
| AC-25 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 8417, 12675。`ReadingSessionAcceptanceTests.test_AC25_previousBookIsTheLastSavedOne` |
| AC-26 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 8936, 13184。`ReadingSessionAcceptanceTests.test_AC26_withoutSessionsPreviousBookIsTheLastAdded` |
| AC-27 | 未検証（G3完了条件未達） | 3 / 6 / 0 | 0 / 0 | CI原本LF行 8630, 8806, 8901, 12716, 12868, 13249。`ReadingSessionAcceptanceTests.test_AC27_homeShowsOnlyResumeWhileFinishing`<br>`ReadingSessionAcceptanceTests.test_AC27_homeShowsOnlyResumeWhilePaused`<br>`ReadingSessionAcceptanceTests.test_AC27_homeShowsOnlyResumeWhileReading` |
| AC-28 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 4291, 12061。`BookStatsAcceptanceTests.test_AC28_noProgressWithoutTotalPages` |
| AC-29 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 10431, 14444。`FinishSessionAcceptanceTests.test_AC29_lowerPageMeansRereading` |
| AC-30 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 9831, 14985。`FinishSessionAcceptanceTests.test_AC30_minutesOutsideOneToElapsedAreRejected` |
| AC-31 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 9504, 15434。`AddBookAcceptanceTests.test_AC31_totalPagesOutsideOneTo9999AreRejected` |
| AC-32 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 7349, 17602。`FinishInputAcceptanceTests.test_AC32_pageAbove9999IsRejectedWithoutTotalPages` |
| AC-33 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 3688, 16656。`ReadingScreenAcceptanceTests.test_AC33_pausedIsRestoredAfterForceQuit` |
| AC-34 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 7600, 17806。`FinishInputAcceptanceTests.test_AC34_finishingIsRestoredAfterForceQuit` |
| AC-35 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 6831, 17694。`FinishInputAcceptanceTests.test_AC35_retryAfterOneFailureAddsExactlyOne` |
| AC-36 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 5154, 13518。`BookDetailAcceptanceTests.test_AC36_weekTotalIsZeroWithoutSessionsThisWeek` |
| AC-37 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 4494, 14140。`BookDetailAcceptanceTests.test_AC37_bookWithoutSessionsShowsEmptyState` |
| AC-38 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 4557, 13823。`BookDetailAcceptanceTests.test_AC38_cancelDeleteKeepsSession` |
| AC-39 | PASS（今回のカタログ検査） | 0 / 0 / 0 | 1 / 0 | `evidence/g3-20261023/ac39-catalog.log`：不足0、終了0 |
| AC-40 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 3488, 15852。`ReadingScreenAcceptanceTests.test_AC40_elapsedLabelReadsMinutesAndSeconds` |
| AC-41 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 3537, 16705。`ReadingScreenAcceptanceTests.test_AC41_clockSetBackShowsZeroNotNegative` |
| AC-42 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 9589, 15519。`AddBookAcceptanceTests.test_AC42_bookAddFailureKeepsTitle` |
| AC-43 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 5138, 13924。`BookDetailAcceptanceTests.test_AC43_deleteFailureKeepsSession` |
| AC-44 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 4935, 13429。`BookDetailAcceptanceTests.test_AC44_sessionAcrossWeekBoundaryCountsInStartWeek` |
| AC-45 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 6908, 17473。`FinishInputAcceptanceTests.test_AC45_timeInFinishInputIsNotCounted` |
| AC-46 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 7766, 17972。`FinishInputAcceptanceTests.test_AC46_cancelFinishReturnsToReading` |
| AC-47 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 7488, 16999。`FinishInputAcceptanceTests.test_AC47_cancelFinishResetsMinutesDraft` |
| AC-48 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 7903, 17396。`FinishInputAcceptanceTests.test_AC48_swipeDownDismissEqualsCancel` |
| AC-49 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 9204, 15209。`AddBookAcceptanceTests.test_AC49_afterAddShowsNewBookDetail` |
| AC-50 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 8003, 17099。`FinishInputAcceptanceTests.test_AC50_afterSaveShowsBookDetail` |
| AC-51 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 4630, 13502。`BookDetailAcceptanceTests.test_AC51_tooShortShowsNoticeOnBookDetail` |
| AC-52 | 未検証（G3完了条件未達） | 3 / 6 / 0 | 0 / 0 | CI原本LF行 4456, 4688, 4919, 13413, 13576, 13658。`BookDetailAcceptanceTests.test_AC52_bookDetailOffersResumeAfterCancellingFinish`<br>`BookDetailAcceptanceTests.test_AC52_bookDetailOffersResumeWhilePaused`<br>`BookDetailAcceptanceTests.test_AC52_bookDetailOffersResumeWhileReading` |
| AC-53 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 9279, 15134。`AddBookAcceptanceTests.test_AC53_discardingAddKeepsBookCount` |
| AC-54 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 9053, 13352。`LoadFailureAcceptanceTests.test_AC54_loadFailureShowsRetryInsteadOfEmpty` |
| AC-55 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 9126, 13325。`LoadFailureAcceptanceTests.test_AC55_loadRetryRestoresLibrary` |
| AC-56 | 未検証（G3完了条件未達） | 2 / 4 / 0 | 0 / 0 | CI原本LF行 4762, 4837, 13998, 14215。`BookDetailAcceptanceTests.test_AC56_startFailureFromBookDetailKeepsIdle`<br>`BookDetailAcceptanceTests.test_AC56_startFailureFromHomeKeepsIdle` |
| AC-57 | 未検証（G3完了条件未達） | 2 / 4 / 0 | 0 / 0 | CI原本LF行 4398, 5037, 13760, 14102。`BookDetailAcceptanceTests.test_AC57_startRetryFromBookDetailStartsAtRetryTime`<br>`BookDetailAcceptanceTests.test_AC57_startRetryFromHomeStartsAtRetryTime` |
| AC-58 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 3003, 15716。`ReadingScreenAcceptanceTests.test_AC58_pauseFailureKeepsReading` |
| AC-59 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 3897, 16507。`ReadingScreenAcceptanceTests.test_AC59_pauseRetryStopsAtRetryTime` |
| AC-60 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 3993, 15948。`ReadingScreenAcceptanceTests.test_AC60_resumeFailureKeepsPaused` |
| AC-61 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 3111, 15824。`ReadingScreenAcceptanceTests.test_AC61_resumeRetryStartsAtRetryTime` |
| AC-62 | 未検証（G3完了条件未達） | 2 / 4 / 0 | 0 / 0 | CI原本LF行 3460, 4091, 15620, 16605。`ReadingScreenAcceptanceTests.test_AC62_beginFinishFailureWhilePaused`<br>`ReadingScreenAcceptanceTests.test_AC62_beginFinishFailureWhileReading` |
| AC-63 | 未検証（G3完了条件未達） | 2 / 4 / 0 | 0 / 0 | CI原本LF行 3236, 3362, 16162, 16387。`ReadingScreenAcceptanceTests.test_AC63_beginFinishRetryWhilePaused`<br>`ReadingScreenAcceptanceTests.test_AC63_beginFinishRetryWhileReading` |
| AC-64 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 7219, 17258。`FinishInputAcceptanceTests.test_AC64_cancelFinishFailureKeepsInput` |
| AC-65 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 7060, 16860。`FinishInputAcceptanceTests.test_AC65_cancelFinishRetryReturnsToReading` |
| AC-66 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 3637, 16262。`ReadingScreenAcceptanceTests.test_AC66_discardFailureKeepsReading` |
| AC-67 | 未検証（G3完了条件未達） | 1 / 2 / 0 | 0 / 0 | CI原本LF行 3777, 16037。`ReadingScreenAcceptanceTests.test_AC67_discardRetryShowsNoticeWithoutRecord` |

## 3. 状態ごとの結果

| 状態 | 選んだもの | 結果 | 証拠・残り |
|---|---|---|---|
| 初めて起動 | 自動 | CI単回成功、G3未完 | AC1〜4/20/21/31。今回S2入力通常のみ、S1空等の現HEAD全状態撮影は未完 |
| データがある | 自動 | CI単回成功、代表画面確認 | S1/S3、S4 reading/paused、S5 finishingの4条件。S1 active/S3 current/busy等は未完 |
| 前の版からの更新 | 範囲外 | test-planどおり | 001は初版、PRD12。内部版から次版は002で扱う |
| オフライン・500・タイムアウト | 自動 | CI AC20の3メソッド×日英は成功 | 今回新規の接続先障害探索C6は未実施。実機機内モードはG4 |
| 権限を断った | 自動 | CI AC21成功 | 権限0の仕様を割込監視で検査。断る操作自体はない |
| バックグラウンド復帰 | 自動 | CI AC7/8/33/34成功 | S2/S5入力途中復帰は探索C2未実施 |
| ja/en言語・地域 | 自動 | CI各80成功、代表画面確認 | enはAppleLanguages(en)を維持。過去S5の四角表示は今回は再現せず、日本語題名が正常。原因解決の証明や別環境保証にはしない |
| 大きい文字・ダーク | 自動撮影、design-reviewer判定 | 代表32枚確認、監査FAIL/未解決 | AX5 S5の手動スクロール・編集・保存・保持を確認。全状態とDouble-Length未完。VoiceOver実操作はG4 |
| 容量不足・割り込み | 自動保存失敗、G4実機 | CIの失敗注入ACは成功 | 実容量不足/電話割込はG4、今回S7失敗表示を4条件撮影 |

## 4. 揺れの確認

未完。固定HEADで影響「大」の全対象と一度でも落ちた対象を5回、AC18の再起動を5回完了していない。過去HEADのAC9/48等の部分反復は、現在HEADの全反復の代用にしない。r2/r3/r4は一時ハーネスの観測/修正であり、既存ACの5回反復に算入しない。新たな長い反復は指揮役への今回の引渡し後のフェーズで行う。

| 対象 | 必要回数 | 本フェーズで新規完了 | 状態 |
|---|---|---|---|
| R1〜R7の高リスクAC全対象 | 5 | 0 | 未検証 |
| 過去に失敗した所定ACテスト | 5 | 0 | 未検証。履歴上の失敗原因・修正はG2記録を参照 |
| AC18 power cycle | 5 | 0 | 既存CIの1回成功は照合、5回は未完 |

## 5. 受け入れテストの変更

- 最初のコミット：`037a276`、後半追加：`2c0d980`。`git log --oneline origin/main..HEAD -- ios/AcceptanceTests/`と`git diff 037a276..HEAD -- ios/AcceptanceTests/`を取得。20ファイルの履歴差分を`E/acceptance-history.diff.txt`に保存。
- 固定HEADの全文/弱体化の独立レビューは`docs/reviews/001-reading-session-G2-tests-tech-lead-r2-resumed.md`（gpt-6-astra）。67AC/82メソッド、全23テスト対象、追加18/削除11のassertion変更を確認し、欠落・期待値の弱体化・実行対応不備0と報告している。verifier自身がその全文レビューを再実施したとは扱わない。
- 主な根拠対応：AppSessionのsystem.openはT16とAC5〜8/33/45〜48/57〜67、実Button選択と入力補助はAC3/9/31/32/63/64の値・個数を保持、AC48の1回のシートジェスチャはAC48/design6(d)、AC23のencoding/JSON/値の型とAC21割込監視は同番号AC、AC18の端末状態確認はAC18/T11、AC39の変数境界は同ACの不足0と終了非0を保持。詳細は上記レビューの静的検査・対照節。
- 過去の実装前UI82本の赤は未実行のまま。実装後の初回CI69失敗を実装前の赤に読み替えない。`docs/reviews/001-reading-session-G2-ruling.md`は過去G2を遡及PASSにせず、完成HEADを通常G2で評価する裁定。現在のG3完了を免除していない。

今回の恒久テスト・期待値・設定・スクリプト変更は0。許可された一時Swiftハーネスだけを追加して実行し、削除した。計画書の修正は次の2件のみ。

| ファイル | 変更 | PRD/契約の根拠 |
|---|---|---|
| `test-plan.md` 4章 | 時計URLの送り方をXCUIDevice.shared.system.openへ訂正 | T16、CI裁定。時刻操作の適用数・各AC期待値は変更なし |
| `test-plan.md` 末尾 | sleep「フォルダ全体0」をUI0/CLI1に訂正 | AC18/T11の端末状態待ち。検査事実の訂正でコード/期待値変更なし |

## 6. 検査の件数

一時Swift削除後の既存`ios/AcceptanceTests/`を検査。0件でないものを隠さない。

| 検査 | コマンド/証拠 | 件数 | 理由 |
|---|---|---|---|
| sleep固定待機 | `rg -n 'sleep\(|usleep|Thread\.sleep|time\.sleep|asyncio\.sleep|^[[:space:]]*sleep[[:space:]]' ios/AcceptanceTests/`、`E/scan-sleep.log` | UI 0 / CLI 1 | ac18-reboot.sh:99。端末stateの最大60秒/2秒刻み確認。画面の固定時間待機・失敗テスト再試行ではない |
| 飛ばす/失敗を許す | `rg -n 'XCTSkip|XCTExpectFailure|pytest\.mark\.skip|skipif|xfail|pytest\.skip|unittest\.skip' ios/AcceptanceTests/`、`E/scan-skip.log` | 0 | AC18の計画分離は別計画で実行済み、実際skip0 |
| 再試行（広い語検索） | `rg -ni 'retry|rerun' ios/AcceptanceTests/`、`E/scan-retry.log` | 66行、実行側再試行0 | 製品のerror.retry/error.loadFailed.retry、文言・ACのRetry名・その照合/注記。66行を`E/scan-retry-explanations.tsv`で1行ずつ説明。判定コマンドにも再試行引数なし |
| 内部import | `rg -n '@testable import' ios/AcceptanceTests/`、`E/scan-internal-import.log` | 0 | 製品実装をテストへimportしていない |
| AC番号の不足/余分 | PRD AC-1〜67と所定テスト名ACを照合 | 0 / 0 | 全67。CI82固有メソッド+別シェルAC39。CI原本との対応は2章 |
| 表示文字/並び順の直書き検索 | `rg -n '(buttons|staticTexts|textFields|cells|switches)\["|element\(boundBy:' ios/AcceptanceTests/`、`E/scan-selectors.log` | 0 | これは指定grepの件数。動的predicateのシステム文言選択はdesign6の例外として存在し、文字検索一般0とは主張しない |
| 存在だけの判定 | 独立tech-leadの全テスト確認 | 存在のみで終わるAC 0 | 直接exists16行は診断/選択/移動8と結果の補足8（上記G2レビュー）。今回verifierは全メソッドを再静読していない |

## 7. アクセシビリティ監査

`test_G3_light`が各画面で`performAccessibilityAudit(for: .all)`を呼んだ。finding handlerはすべてfalse。次表の件数はrawログ23件と一致し、0件でない画面をPASSにしていない。全finding・対象element・詳細は`E/audit-issues.json`/`.tsv`と`E/g3-visual-r2.log`。xcresultの監査/失敗の添付65個（説明・画面・要素画像等）は`E/r2-failure-attachments/manifest.json`から辿れる。nilのelementを推測で特定していない。

| 画面 | テスト | 結果 | finding |
|---|---|---|---|
| S1 normal | test_G3_light | FAIL・2件 | Dynamic Type2：今週、30分 |
| S2 normal | test_G3_light | FAIL・3件 | Dynamic Type2：キャンセル/追加。Contrast1：題名（必須）の見出し |
| S3 normal | test_G3_light | FAIL・8件 | Hit area3（element=nil）、Dynamic Type5：24%、記録3件、進み具合、300、総ページ数 |
| S4 reading | test_G3_light | PASS・0件（この画面のこの監査のみ） | paused/エラー状態や全条件の監査、VoiceOverは別 |
| S5 normal | test_G3_light | FAIL・3件 | Contrast1：session.finish.book。Dynamic Type2：保存/キャンセル |
| S6 normal | test_G3_light | FAIL・4件 | Dynamic Type4：alert題・本文、element=nil2件 |
| S7 normal | test_G3_light | FAIL・3件 | Dynamic Type3：alert題・本文、element=nil1件 |

Dynamic Type18、contrast2、hitRegion3。S1/S3のAX5画像ではラベルが拡大し、Toolbarやalertも標準部品由来であるが、これだけで監査結果を誤検出と確定しない。S6/S7のAX5画像は大きく拡大され、S6本文はシステムのスクロール領域に続く。全設定域の追従、最小押下領域の実測、実画素contrastと素の標準部品との対照は未完。製品原因が明確なAC不良はこのフェーズでは確定していない。指揮役へ未解決findingとして返す。VoiceOverの実操作はG4の人に回す。

## 8. 探索セッション

test-plan C1〜C7はすべて未実施。今回の7画面撮影/監査とAX5操作は限定した不足確認であり、30分/40操作の各チャーターを終えた証拠に数えない。

| チャーター | 区切り | 今回 | 次フェーズ |
|---|---|---|---|
| C1 保存/終了/再起動と失敗後保持 | 40操作 | 未実施 | T5全操作の失敗、途中終了、連続再起動 |
| C2 経過/復帰/入力途中/60秒境界 | 40操作 | 未実施 | 時計進退、一時停止連打、S2/S5復帰 |
| C3 合計/週/削除/分修正 | 30分 | 未実施 | 手計算oracleで比較 |
| C4 0冊/日英/100字と絵文字/戻る | 40操作 | 未実施 | 長文、スワイプ、主流路 |
| C5 active状態と別本の開始抑止 | 40操作 | 未実施 | S1/S3/S4往復と戻る道 |
| C6 計測本文の秘密値・失敗後 | 30分 | 未実施 | UTF8/%XX/%xx/JSON全階層 |
| C7 起動失敗と3状態復元 | 30分 | 未実施 | load:* / load:1、時計戻し |

一時ハーネスは削除済み。r2/r3/r4ソースは`E/G3VisualAuditTemporaryTests-rN.swift.txt`に再現用として保存。恒久ACテストに変更したものはない。

## 9. スクリーンショットとログ

次表の全32枚を実際に開いて確認した。パスは`E/`からの相対。S1はidle、S3はidleで記録あり、S2は題名入力済み、S5は空ページ/10分、S6/S7は削除操作からの標準alert。通常状態の代表32枚は揃ったが、design全状態の完成を意味しない。

| ファイル | 画面/状態 | 見た目 | 対応する範囲 |
|---|---|---|---|
| `screens/S1_normal_light.png` | S1_normal | light | 正常表示の代表状態。AC表とは別の画面証拠 |
| `screens/S1_normal_dark.png` | S1_normal | dark | 正常表示の代表状態。AC表とは別の画面証拠 |
| `screens/S1_normal_ax5.png` | S1_normal | ax5 | 正常表示の代表状態。AC表とは別の画面証拠 |
| `screens/S1_normal_en.png` | S1_normal | en | 正常表示の代表状態。AC表とは別の画面証拠 |
| `screens/S2_normal_light.png` | S2_normal | light | 正常表示の代表状態。AC表とは別の画面証拠 |
| `screens/S2_normal_dark.png` | S2_normal | dark | 正常表示の代表状態。AC表とは別の画面証拠 |
| `screens/S2_normal_ax5.png` | S2_normal | ax5 | 正常表示の代表状態。AC表とは別の画面証拠 |
| `r4-screens/S2_normal_clean_en.png` | S2_normal | en | 正常表示の代表状態。AC表とは別の画面証拠 |
| `screens/S3_normal_light.png` | S3_normal | light | 正常表示の代表状態。AC表とは別の画面証拠 |
| `screens/S3_normal_dark.png` | S3_normal | dark | 正常表示の代表状態。AC表とは別の画面証拠 |
| `screens/S3_normal_ax5.png` | S3_normal | ax5 | 正常表示の代表状態。AC表とは別の画面証拠 |
| `screens/S3_normal_en.png` | S3_normal | en | 正常表示の代表状態。AC表とは別の画面証拠 |
| `screens/S4_reading_light.png` | S4_reading | light | 正常表示の代表状態。AC表とは別の画面証拠 |
| `screens/S4_reading_dark.png` | S4_reading | dark | 正常表示の代表状態。AC表とは別の画面証拠 |
| `screens/S4_reading_ax5.png` | S4_reading | ax5 | 正常表示の代表状態。AC表とは別の画面証拠 |
| `screens/S4_reading_en.png` | S4_reading | en | 正常表示の代表状態。AC表とは別の画面証拠 |
| `screens/S4_paused_light.png` | S4_paused | light | 正常表示の代表状態。AC表とは別の画面証拠 |
| `screens/S4_paused_dark.png` | S4_paused | dark | 正常表示の代表状態。AC表とは別の画面証拠 |
| `screens/S4_paused_ax5.png` | S4_paused | ax5 | 正常表示の代表状態。AC表とは別の画面証拠 |
| `screens/S4_paused_en.png` | S4_paused | en | 正常表示の代表状態。AC表とは別の画面証拠 |
| `screens/S5_normal_light.png` | S5_normal | light | 正常表示の代表状態。AC表とは別の画面証拠 |
| `screens/S5_normal_dark.png` | S5_normal | dark | 正常表示の代表状態。AC表とは別の画面証拠 |
| `screens/S5_normal_ax5.png` | S5_normal | ax5 | 正常表示の代表状態。AC表とは別の画面証拠 |
| `screens/S5_normal_en.png` | S5_normal | en | 正常表示の代表状態。AC表とは別の画面証拠 |
| `screens/S6_normal_light.png` | S6_normal | light | 正常表示の代表状態。AC表とは別の画面証拠 |
| `screens/S6_normal_dark.png` | S6_normal | dark | 正常表示の代表状態。AC表とは別の画面証拠 |
| `r3-screens/S6_normal_ax5.png` | S6_normal | ax5 | 正常表示の代表状態。AC表とは別の画面証拠 |
| `screens/S6_normal_en.png` | S6_normal | en | 正常表示の代表状態。AC表とは別の画面証拠 |
| `screens/S7_normal_light.png` | S7_normal | light | 正常表示の代表状態。AC表とは別の画面証拠 |
| `screens/S7_normal_dark.png` | S7_normal | dark | 正常表示の代表状態。AC表とは別の画面証拠 |
| `r3-screens/S7_normal_ax5.png` | S7_normal | ax5 | 正常表示の代表状態。AC表とは別の画面証拠 |
| `screens/S7_normal_en.png` | S7_normal | en | 正常表示の代表状態。AC表とは別の画面証拠 |

追加で実際に開いて確認した画像：`screens/S5_minutes_scrolled_ax5.png`（r2のtapによる自動スクロール後）、`r4-screens/S5_form_scroll_1_ax5.png`、`r4-screens/S5_minutes_edited_5_ax5.png`、`r4-screens/S3_after_keyboard_save_ax5.png`、`r4-screens/S3_after_relaunch_ax5.png`。各撮影には同名`_tree.txt`があり、r2/r3/r4-capture-map.tsvで元添付名と対応する。S2英語の元画像は置き換えて消さず、`E/screens/S2_normal_en.png`（OSのkeyboard案内あり）も保持した。

見た目の観測：S4のAX5は終える/一時停止を縦並び、S1/S3主操作はリスト内、S5は項目名の下に欄、S6/S7はシステムが大きく配置している。S5の保存は4条件で全文表示、darkでも白字。S2 darkの追加は黒字に見えるため、design-reviewerへの提案として色と実画素contrastの確認を残す（AC外、最低比率の実測なし）。en画像の日本語題名は今回正常で、前回のen単独四角表示の環境依存が解消した証明にはしない。今回en,jaへの切替は行っていない。

全量エクスポートの明らかな自動添付重複はリポジトリ外の`/private/tmp/reading-app-g3-raw-r{2,3,4}-attachments-20261023/`に保持し、全manifestは`E/rN-all-attachments-manifest.json`へ保存。リポジトリ内には全監査/失敗添付65個、手動名付き画像・tree、原本ログ・summaryを保持。結果bundleはリポジトリ外の上記xcresult3個。manifestの全自動添付をリポジトリ内へ残したとは扱わない。

## 10. 前の機能の受け入れテスト（回帰）

該当なし。001が最初の機能で前機能はない。現行機能の単体69件と通常Acceptance160/AC18前後2は既存CIで照合しただけで、本フェーズの新しい回帰実行ではない。

## 11. 見つかった問題

| # | 内容 | 再現/証拠 | AC | 重大度 | 担当/次の扱い |
|---|---|---|---|---|---|
| G3-A11Y-1 | 6画面の監査23finding未解決 | lightの一時ハーネス`.all`、全件false、7章全raw | 番号付きAC外（PRD12/design9） | 提案 | 指揮役→designer/ios-engineer。実画素/標準対照を含めて原因を確定してから修正範囲を決める |
| G3-WARN-1 | Invalid frame dimension残存 | r2/r3/r4 summaryのruntimeWarnings | 番号付きAC外 | 提案 | ios-engineer。現象の隠蔽・フィルタなし |
| G3-VIS-1 | S2 dark追加の黒字 | screens/S2_normal_dark.png | 番号付きAC外 | 提案 | designer/ios-engineer。実contrastは未測定、AC不良確定ではない |
| G3-HARNESS-1 | r1 compile、r2/r3操作と検索の不備 | 各原本ログと保存ソース。r4は内容内操作成功 | 製品AC不良として数えない | 検証上の不備 | verifier。期待値を変更せず、限定した切り分けを完了 |

製品原因を特定した番号付きACの新規不良は0。本フェーズでは恒久再現テストを追加していない。監査FAILを「製品不良なし＝G3 PASS」に変換しない。

## 12. PRDとテストの食い違い

新たに確定した食い違いなし。r2/r3のハーネス不備は所定のAC期待値を変える根拠にしていない。AC12の所定180→45など、既存の試す値を維持。過去の赤の未実行についてはG2裁定を参照し、架空の赤を作らない。

## 13. 未検証のものと理由

- 全G3の判定実行・高リスク/過去失敗対象の5回とAC18の5 power cycles。既存CIの単回成功を代用しない。
- S1 active（reading/paused等）とS3 current/busy、各空/読み込み/入力エラー/保存失敗/再試行の全状態、長い題名・多件数・長い経過の画面証拠。過去HEADの画像を現HEAD全状態の代用にしない。
- S1〜S7のDouble-Length、全条件/全状態の監査、23findingの実画素contrast・hit領域・標準部品/OSとの対照。今回のlight代表7画面以外を監査済みにしない。
- 探索C1〜C7（各30分/40操作）、大量データ性能のG3証拠、G4実機/VoiceOver/起動性能/割り込み等。全体G3の残りの非機能確認も別フェーズ。
- 原因未特定のframe warning、以前のen単独日本語題名四角表示の別環境確認。
- 実装前UI82本の赤の履歴不足は残る。完成HEADの通常G2で評価する裁定によってその過去事実は変えない。

最終シミュレーターは専用`iPhone 17 26.0`のShutdownを読み取り確認（`E/final-simulator-state.json`）。他のシミュレーターは操作していない。今回のソース/恒久テスト差分0の最終確認は`E/final-integrity.txt`。ここで長い反復・新たな調査は開始せず、指揮役へ次フェーズを引き渡す。


## 14. S2追加ボタンの修正後・局所画面確認（2026-10-23 22:59 JST）

この節は上の6442fe2固定HEADフェーズの**後**の確認。HEADはまだ`6442fe2`だが、ios-engineerによる`AddBookView.swift`のラベル色指定1行追加（+1/-0）を含む作業木をビルドしている。先の監査23件・FAIL・画像・「製品差分0」は修正前フェーズの記録として維持し、今回の結果で書き換えない。

- 修正ファイルのSHA-256：`604d14eacb971af2f55143319b2435f179f0b692d023f16e36f5bb732b531a4d`（撮影前後で一致）。`evidence/g3-20261023/s2-after/product-source-sha256.txt`。verifierは製品ソースを開かず、ハッシュと変更量だけ確認した。製品の変更内容と1行以外の差分なしは実装担当/指揮役の確認による。
- 実装担当の事前結果は`/private/tmp/reading-app-s2-fix-20261023/report.md`とsummary.json。make ios-build、Unit69、AC2/42/49日英6件はすべて終了0（そのsummaryを`S2E/ios-engineer-summary.json`へ保存）。これはverifierが新たに実行したものではない。
- 以下の`S2E/`は`evidence/g3-20261023/s2-after/`。一時ハーネスソースは`S2E/G3S2AfterTemporaryTests.swift.txt`、結果は`S2E/summary.json`、全実行ログは`S2E/S2-after.log`。全bundle/自動添付は`/private/tmp/reading-app-s2-visual-20261023/S2-after.xcresult`と同じフォルダのattachments/に保存。

```sh
xcodebuild test -project ios/Yomutoki.xcodeproj -scheme Yomutoki -testPlan Acceptance -only-test-configuration ja_JP -only-testing:YomutokiAcceptanceTests/G3S2AfterTemporaryTests -destination 'platform=iOS Simulator,id=B18DB71A-DB50-4F84-9DDD-7D63541CF3BB' -resultBundlePath /private/tmp/reading-app-s2-visual-20261023/S2-after.xcresult CODE_SIGNING_ALLOWED=NO
```

終了0、4メソッド成功・失敗0・skip0、再試行なし。`ja_JP`はランナー構成で、アプリには各条件を独立指定した。英語はAppleLanguages(en)/en_USを維持。題名`Reading notes`を入れたS2で、追加ボタンが有効かつ押せることを確認して撮影した。保存操作の追加検査や既存AC期待値の変更はしていない。

| 実際に開いて確認した画像 | 結果 |
|---|---|
| `S2E/S2_after_dark.png` | 栗色の追加ボタンが白字になり全文表示。今回の黒字の指摘はこの代表状態で改善を確認 |
| `S2E/S2_after_light.png` | 追加/キャンセル、題名・総ページ数とヒントを確認。追加は白字で全文表示 |
| `S2E/S2_after_ax5.png` | 大きな文字の題名と見出し、追加/キャンセルの全文表示を確認 |
| `S2E/S2_after_en.png` | Add/Cancel、Title/Total Pagesとヒントを確認。通常英語キーボードで撮影 |

各画像と同名の`_tree.txt`、元添付との`capture-map.json`を保存。4条件に表示の新しい崩れは見つからなかった。無効状態、高コントラスト、他画面/他状態への範囲拡張はしていない。

### 同じ矩形の画素比較

修正前`evidence/g3-20261023/screens/S2_normal_dark.png`と修正後`S2E/S2_after_dark.png`はともに1206×2622px。treeとログで両方の追加ボタンは`(334,82,48,36)pt`、3倍表示の同じROI `(1002,246)-(1146,354)px`（15552画素）を比較した。画像の色や文字は加工せず、元画素を読み取った。

| 項目 | 修正前 | 修正後 |
|---|---:|---:|
| 黒 #000000 の画素 | 1474 | 0 |
| 白 #FFFFFF の画素 | 0 | 1474 |
| 背景 #9F5833 の画素 | 12468 | 12468 |

黒1474画素は**同じ位置**で白1474画素になり、背景12468画素も同じ位置・同じ色で一致した。境界のアンチエイリアスを含む変化は計2318画素。計測値/領域/限界は`S2E/pixel-comparison.json`。これは当該矩形の前後比較で、全設定のcontrast基準や監査23件の解消を検証したものではない。

一時Swiftは削除し、生成プロジェクトも削除後の状態で再生成した。既存Acceptanceテスト/設定の差分0、新しい恒久テスト0、verifierによる製品変更0。専用simはShutdownを確認し、他simを操作していない（`S2E/final-simulator-state.json`）。G3-VIS-1のS2通常darkでの黒字という観測は改善したが、監査23件・反復・探索・全状態等の未完は維持し、**G3全体はFAILのまま**。この局所撮影フェーズの書き込みは完了。
