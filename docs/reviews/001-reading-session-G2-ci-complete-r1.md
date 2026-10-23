FAIL

# 全体 CI の成功と残る確認（2026-10-23）

この記録の FAIL は G2/G3 全体の判定。iOS の全体 CI は成功したが、所有者確認と独立したレビュー、G3 の未検証が残るため完成とはしない。

## 指摘

- 重大（G2/G3 の未完了）：`docs/org/gates.md` の G2/G3 に必要なレビュー、影響「大」と既往失敗の5回確認、全画面・全状態の証拠、アクセシビリティ監査、探索がそろっていない。
- 重大（所有者確認）：`org-guard` は `.claude/org/app.json`、`.claude/org/lock.json`、`.github/workflows/ios.yml` の変更を検出し失敗する。ガードの無効化や成功扱いへの変更はしない。すでに許可された同じ3ファイルを [設定PR #3](https://github.com/matsuura-tak/reading-app/pull/3) に分離した。Takuma がその差分を確認して main に取り込んだ後、機能PRに main を取り込んで保護設定の差分を解消する。
- Mac で観測した終える入力のレイアウト警告と、画面の大きい文字での収まりは G3 の確認が必要。今回の CI 成功だけで解消とはしない。

## 証拠

対象は `6b979bbe1112cbef711fc9b7f685d05c826d7e7a`。[run 39862607381](https://github.com/matsuura-tak/reading-app/actions/runs/39862607381) は iOS ジョブが2026-10-23 07:07:45〜08:58:03 JST、約110分18秒で成功した。`gh run view 39862607381 --repo matsuura-tak/reading-app --json status,conclusion,jobs,url,headSha` で `completed`、`success` と対象 SHA を確認した。

`gh run view 39862607381 --repo matsuura-tak/reading-app --log` の保存先は `/private/tmp/reading-app-pr2-ci-6b979bb.log`。以下はその完全ログの行番号。

| 確認 | 実行結果 | ログの根拠 |
|---|---|---|
| 環境 | Xcode 26.6、iPhone 17 / iOS 26.5 | 322、18210〜18214行 |
| Debug / Release | 両方 `BUILD SUCCEEDED` | 1140、1707行 |
| Unit | 69件、12スイート成功 | 2720行：`Test run with 69 tests in 12 suites passed` |
| Acceptance ja_JP | 成功80・失敗0・飛ばした0 | 18211行の xcresulttool の構成別集計 |
| Acceptance en_US | 成功80・失敗0・飛ばした0 | 18210行の同じ集計 |
| Acceptance 全体 | 成功160・失敗0・飛ばした0。失敗の文言0行、異常終了なし | 17956〜18213行の `ACCEPTANCE SUMMARY`。`testFailures: 0 件` |
| AC-18 再起動前 | 1件成功、exit=0 | 18288〜18305行 |
| AC-18 再起動 | seed 実行後の Shutdown を確認し、boot、bootstatus 後 Booted | 18306〜18312行 |
| AC-18 再起動後 | 1件成功、exit=0、`passed 2 of 2` | 18416〜18434行 |
| PR の他の確認 | plan、org-check 成功。org-guard 失敗 | PR #2 の statusCheckRollup。guard の実行は [39862602621](https://github.com/matsuura-tak/reading-app/actions/runs/39862602621) |

Acceptance で AC18RebootTests が0件なのは、別の AC18Reboot 計画で再起動の前後に分けて実行するため。2件が後段で実行されたことを上のログで確認した。1回の再起動であり、G3 の5回確認には不足する。

Swift のコンパイラの `*.swift:<行>:<列>: warning:` は0件。ログ全体の `warning:` は5件あり、すべて AppIntents のメタデータ抽出器の `Metadata extraction skipped. No AppIntents.framework dependency found.`。警告が全種類0件だったとは記録しない。

CI の実行は Makefile の既定コマンドであり、失敗後の再試行やテストの期待値変更による成功扱いはない。以前の AC-9/48 の修正前後の比較と日英20回の結果は `001-reading-session-G2-stability-mac-r1.md` に残す。今回の成功はその修正後の全体実行の証拠であり、全 AC の5回確認とは区別する。

### 実行数と AC-5 の速度

要約の a2 からテストの名前を数え、2構成とも80件で、同じ65個の AC 番号を含むことを確認した。AC-18 と AC-39 を除く AC-1〜67 がすべて含まれる。AC-18 は前述の別計画で2段階、AC-39 は後述のシェルで確認する。これはテストの実行数の確認であり、G3 の画面・監査・探索の完了を意味しない。

AC-5 の速度は measure の成功表示だけで合格にしない。ログ7436、13922行の `Duration (FirstElapsedShown), s` の実測値を読み、5回の平均が0.5秒以下であることを別に計算した。

| 回 | 5回の実測値（秒） | 平均（秒） | 0.5秒以下 |
|---|---|---|---|
| 1 | 0.135466、0.164043、0.160638、0.118352、0.106318 | 0.1369634 | はい |
| 2 | 0.158082、0.179062、0.141413、0.173731、0.179245 | 0.1663066 | はい |

回1/2と言語の対応は計画の構成順からの推定なので、この表では言語を断定しない。両構成が動いたことは xcresulttool の構成別集計で確認でき、どちらの平均も基準を満たす。

### AC-39 の Mac 互換性の補助修正

CI の既定コマンドには AC-39 のシェルが入っていないため、Mac で別に実行した。Mac 標準 Bash 3.2.57 では、判定後の `echo` 内の `$last）` が変数名の一部として解釈され、翻訳不足0件なのに `unbound variable`、終了1になった。修正前の出力は `/private/tmp/reading-app-pr2-ac39-before-20261023.log`。

`7123291` で成功・失敗表示の変数を `${last}`、`${code}` と明示した。期待値、Python の判定、終了コードの条件は変えていない。PRD AC-39 の翻訳不足0件という判定を Mac 上でも実行するための修正。

- `bash ios/AcceptanceTests/ac39-xcstrings.sh`：`untranslated_keys=0`、`PASS（exit=0、最後の行=untranslated_keys=0）`、終了0。
- `/private/tmp/reading-app-pr2-ac39-negative-20261023` の検証用コピーで `action.continue` の英訳1件だけを `needs_review` にした：`untranslated_keys=1`、`FAIL（exit=1、最後の行=untranslated_keys=1）`、終了1。`unbound variable` は0件。
- `/bin/bash --version`：3.2.57。`bash -n ios/AcceptanceTests/ac39-xcstrings.sh` と `git diff --check`：終了0。

上の全体 CI が検証したのは `6b979bb` であり、このシェル表示修正を含むコミットの全体 CI 成功とは混同しない。

### 既往失敗3件の5回確認

2026-10-23 09:30〜09:48 JST、Xcode 27.1（27A9275）、macOS 27.0.1、iPhone 17 / iOS 26.0（23A343）、専用端末 `B18DB71A-DB50-4F84-9DDD-7D63541CF3BB` で、下の3件を両言語で5回ずつ実行した。終了0、`TEST SUCCEEDED`、成功30・失敗0・飛ばした0。期待値や待機上限は変更していない。

```sh
xcodebuild test -project ios/Yomutoki.xcodeproj -scheme Yomutoki -testPlan Acceptance \
  -only-testing:YomutokiAcceptanceTests/ReadingScreenAcceptanceTests/test_AC60_resumeFailureKeepsPaused \
  -only-testing:YomutokiAcceptanceTests/ReadingScreenAcceptanceTests/test_AC62_beginFinishFailureWhilePaused \
  -only-testing:YomutokiAcceptanceTests/ReadingScreenAcceptanceTests/test_AC63_beginFinishRetryWhileReading \
  -test-iterations 5 -run-tests-until-failure \
  -destination 'platform=iOS Simulator,id=B18DB71A-DB50-4F84-9DDD-7D63541CF3BB' \
  -resultBundlePath /private/tmp/reading-app-pr2-stability-errors-20261023.xcresult \
  CODE_SIGNING_ALLOWED=NO
```

| テスト | ja_JP | en_US | 失敗 / 飛ばした |
|---|---|---|---|
| `test_AC60_resumeFailureKeepsPaused` | 5回成功 | 5回成功 | 0 / 0 |
| `test_AC62_beginFinishFailureWhilePaused` | 5回成功 | 5回成功 | 0 / 0 |
| `test_AC63_beginFinishRetryWhileReading` | 5回成功 | 5回成功 | 0 / 0 |

ログは `/private/tmp/reading-app-pr2-stability-errors-20261023.log`。`xcrun xcresulttool get test-results summary --path /private/tmp/reading-app-pr2-stability-errors-20261023.xcresult --format json` の出力は `/private/tmp/reading-app-pr2-stability-errors-summary-20261023.json`。`devicesAndConfigurations` は ja_JP と en_US が各 passedTests=15、failedTests=0、skippedTests=0、expectedFailures=0。statistics は `30 test runs`。トップレベルの passedTests=3 は固有のテスト数であり、実行回数30と区別する。

既知の `Invalid frame dimension (negative or non-finite)` は今回も10件あり、いずれも AC-63 のシートを開く付近。成功した30回にこの実行時警告がないとは扱わない。原因と画面の影響は未解決で、G3 の確認に残す。

実行を始めたコミットは `6b979bb`。実行中にコミットした `7123291` との差分は AC-39 のシェルの結果表示2行だけで、アプリ・テストの Swift ファイルは同一。主要3ファイルの SHA-256：

```text
b8b3a6f2fdb5774a8882eb25d06e37cdd988a019d75d1f39b88a4fede4b1a96d  Tests/ReadingScreenAcceptanceTests.swift
5bceb295eb6f40cecca15a9b2056edfddfedeff86c71cea76bbb20d78b22cf3e  Support/UIHelpers.swift
988ea1ac8f105415152d0a9c20de29dd7199910801916a3c32bf7e98014edfea  Support/AppSession.swift
```

前回の AC-9/48 の日英20回に加え、この3件の日英30回が成功した。ほかの影響「大」の AC の5回確認、再起動5回、監査や探索の完了には数えない。

### AC ごとの自動テストの実行数

下表は実行したテストの名前と数の対応だけを示す。全体の G3 合否、未実行の監査や探索の代替にはしない。Acceptance は両構成とも失敗0・飛ばした0。AC-18 と39の別実行を除き、テスト数は各言語の件数。

| AC | 実行数 | 証拠のテスト名 |
|---|---|---|
| AC-1 | ja/en 各1件 | `LibraryAcceptanceTests.test_AC1_emptyLibraryShowsEmptyStateAndOnlyAddBook` |
| AC-2 | ja/en 各1件 | `LibraryAcceptanceTests.test_AC2_addBookWithTitleOnly` |
| AC-3 | ja/en 各1件 | `LibraryAcceptanceTests.test_AC3_blankTitleCannotBeSaved` |
| AC-4 | ja/en 各1件 | `LibraryAcceptanceTests.test_AC4_zeroBooksToReadingInThreeTapsOrFewer` |
| AC-5 | ja/en 各2件 | `ReadingSessionAcceptanceTests.test_AC5_previousBookStartsFromHomeInOneTap`<br>`ReadingSessionAcceptanceTests.test_AC5_startToFirstElapsedMeasuredBySignpost` |
| AC-6 | ja/en 各1件 | `ReadingSessionAcceptanceTests.test_AC6_pausedTimeIsNotCounted` |
| AC-7 | ja/en 各1件 | `ReadingSessionAcceptanceTests.test_AC7_elapsedKeepsRunningInBackground` |
| AC-8 | ja/en 各1件 | `ReadingSessionAcceptanceTests.test_AC8_forceQuitRestoresReadingAndElapsed` |
| AC-9 | ja/en 各1件 | `FinishSessionAcceptanceTests.test_AC9_enteringPageRecordsProgress` |
| AC-10 | ja/en 各1件 | `FinishSessionAcceptanceTests.test_AC10_finishWithoutPage` |
| AC-11 | ja/en 各1件 | `FinishSessionAcceptanceTests.test_AC11_pageAboveTotalPagesIsRejected` |
| AC-12 | ja/en 各1件 | `FinishSessionAcceptanceTests.test_AC12_editMinutesWhenFinishing` |
| AC-13 | ja/en 各2件 | `ReadingSessionAcceptanceTests.test_AC13_boundarySixtySecondsOpensFinishInput`<br>`ReadingSessionAcceptanceTests.test_AC13_underOneMinuteIsNotRecorded` |
| AC-14 | ja/en 各2件 | `BookStatsAcceptanceTests.test_AC14_bookTotalsAreShown`<br>`BookStatsAcceptanceTests.test_AC14_totalAddsSecondsBeforeFlooring` |
| AC-15 | ja/en 各1件 | `BookStatsAcceptanceTests.test_AC15_weekTotalExcludesLastWeek` |
| AC-16 | ja/en 各1件 | `BookStatsAcceptanceTests.test_AC16_deleteSessionKeepsLastPage` |
| AC-17 | ja/en 各3件 | `ReadingSessionAcceptanceTests.test_AC17_cannotStartAnotherBookWhileFinishing`<br>`ReadingSessionAcceptanceTests.test_AC17_cannotStartAnotherBookWhilePaused`<br>`ReadingSessionAcceptanceTests.test_AC17_cannotStartAnotherBookWhileReading` |
| AC-18 | ja 2段階各1件 | `AC18RebootTests.test_AC18_1_seedLibraryBeforeReboot` / `test_AC18_2_libraryRemainsAfterReboot` |
| AC-19 | ja/en 各1件 | `FinishSessionAcceptanceTests.test_AC19_saveFailureKeepsFinishingSession` |
| AC-20 | ja/en 各3件 | `TelemetryAndPrivacyAcceptanceTests.test_AC20_allOperationsWorkWhenTelemetryHangs`<br>`TelemetryAndPrivacyAcceptanceTests.test_AC20_allOperationsWorkWhenTelemetryIsUnreachable`<br>`TelemetryAndPrivacyAcceptanceTests.test_AC20_allOperationsWorkWhenTelemetryReturns500` |
| AC-21 | ja/en 各1件 | `TelemetryAndPrivacyAcceptanceTests.test_AC21_noPermissionPromptsDuringFirstSession` |
| AC-22 | ja/en 各1件 | `LibraryAcceptanceTests.test_AC22_twentyFirstBookHasNoLimitOrPaywall` |
| AC-23 | ja/en 各1件 | `TelemetryAndPrivacyAcceptanceTests.test_AC23_telemetryHasNoTitleOrPageValues` |
| AC-24 | ja/en 各1件 | `TelemetryAndPrivacyAcceptanceTests.test_AC24_weekReachedIsSentOncePerWeek` |
| AC-25 | ja/en 各1件 | `ReadingSessionAcceptanceTests.test_AC25_previousBookIsTheLastSavedOne` |
| AC-26 | ja/en 各1件 | `ReadingSessionAcceptanceTests.test_AC26_withoutSessionsPreviousBookIsTheLastAdded` |
| AC-27 | ja/en 各3件 | `ReadingSessionAcceptanceTests.test_AC27_homeShowsOnlyResumeWhileFinishing`<br>`ReadingSessionAcceptanceTests.test_AC27_homeShowsOnlyResumeWhilePaused`<br>`ReadingSessionAcceptanceTests.test_AC27_homeShowsOnlyResumeWhileReading` |
| AC-28 | ja/en 各1件 | `BookStatsAcceptanceTests.test_AC28_noProgressWithoutTotalPages` |
| AC-29 | ja/en 各1件 | `FinishSessionAcceptanceTests.test_AC29_lowerPageMeansRereading` |
| AC-30 | ja/en 各1件 | `FinishSessionAcceptanceTests.test_AC30_minutesOutsideOneToElapsedAreRejected` |
| AC-31 | ja/en 各1件 | `AddBookAcceptanceTests.test_AC31_totalPagesOutsideOneTo9999AreRejected` |
| AC-32 | ja/en 各1件 | `FinishInputAcceptanceTests.test_AC32_pageAbove9999IsRejectedWithoutTotalPages` |
| AC-33 | ja/en 各1件 | `ReadingScreenAcceptanceTests.test_AC33_pausedIsRestoredAfterForceQuit` |
| AC-34 | ja/en 各1件 | `FinishInputAcceptanceTests.test_AC34_finishingIsRestoredAfterForceQuit` |
| AC-35 | ja/en 各1件 | `FinishInputAcceptanceTests.test_AC35_retryAfterOneFailureAddsExactlyOne` |
| AC-36 | ja/en 各1件 | `BookDetailAcceptanceTests.test_AC36_weekTotalIsZeroWithoutSessionsThisWeek` |
| AC-37 | ja/en 各1件 | `BookDetailAcceptanceTests.test_AC37_bookWithoutSessionsShowsEmptyState` |
| AC-38 | ja/en 各1件 | `BookDetailAcceptanceTests.test_AC38_cancelDeleteKeepsSession` |
| AC-39 | シェル1件 | `test_AC39_stringCatalogFullyTranslated`（前節の修正後、終了0） |
| AC-40 | ja/en 各1件 | `ReadingScreenAcceptanceTests.test_AC40_elapsedLabelReadsMinutesAndSeconds` |
| AC-41 | ja/en 各1件 | `ReadingScreenAcceptanceTests.test_AC41_clockSetBackShowsZeroNotNegative` |
| AC-42 | ja/en 各1件 | `AddBookAcceptanceTests.test_AC42_bookAddFailureKeepsTitle` |
| AC-43 | ja/en 各1件 | `BookDetailAcceptanceTests.test_AC43_deleteFailureKeepsSession` |
| AC-44 | ja/en 各1件 | `BookDetailAcceptanceTests.test_AC44_sessionAcrossWeekBoundaryCountsInStartWeek` |
| AC-45 | ja/en 各1件 | `FinishInputAcceptanceTests.test_AC45_timeInFinishInputIsNotCounted` |
| AC-46 | ja/en 各1件 | `FinishInputAcceptanceTests.test_AC46_cancelFinishReturnsToReading` |
| AC-47 | ja/en 各1件 | `FinishInputAcceptanceTests.test_AC47_cancelFinishResetsMinutesDraft` |
| AC-48 | ja/en 各1件 | `FinishInputAcceptanceTests.test_AC48_swipeDownDismissEqualsCancel` |
| AC-49 | ja/en 各1件 | `AddBookAcceptanceTests.test_AC49_afterAddShowsNewBookDetail` |
| AC-50 | ja/en 各1件 | `FinishInputAcceptanceTests.test_AC50_afterSaveShowsBookDetail` |
| AC-51 | ja/en 各1件 | `BookDetailAcceptanceTests.test_AC51_tooShortShowsNoticeOnBookDetail` |
| AC-52 | ja/en 各3件 | `BookDetailAcceptanceTests.test_AC52_bookDetailOffersResumeAfterCancellingFinish`<br>`BookDetailAcceptanceTests.test_AC52_bookDetailOffersResumeWhilePaused`<br>`BookDetailAcceptanceTests.test_AC52_bookDetailOffersResumeWhileReading` |
| AC-53 | ja/en 各1件 | `AddBookAcceptanceTests.test_AC53_discardingAddKeepsBookCount` |
| AC-54 | ja/en 各1件 | `LoadFailureAcceptanceTests.test_AC54_loadFailureShowsRetryInsteadOfEmpty` |
| AC-55 | ja/en 各1件 | `LoadFailureAcceptanceTests.test_AC55_loadRetryRestoresLibrary` |
| AC-56 | ja/en 各2件 | `BookDetailAcceptanceTests.test_AC56_startFailureFromBookDetailKeepsIdle`<br>`BookDetailAcceptanceTests.test_AC56_startFailureFromHomeKeepsIdle` |
| AC-57 | ja/en 各2件 | `BookDetailAcceptanceTests.test_AC57_startRetryFromBookDetailStartsAtRetryTime`<br>`BookDetailAcceptanceTests.test_AC57_startRetryFromHomeStartsAtRetryTime` |
| AC-58 | ja/en 各1件 | `ReadingScreenAcceptanceTests.test_AC58_pauseFailureKeepsReading` |
| AC-59 | ja/en 各1件 | `ReadingScreenAcceptanceTests.test_AC59_pauseRetryStopsAtRetryTime` |
| AC-60 | ja/en 各1件 | `ReadingScreenAcceptanceTests.test_AC60_resumeFailureKeepsPaused` |
| AC-61 | ja/en 各1件 | `ReadingScreenAcceptanceTests.test_AC61_resumeRetryStartsAtRetryTime` |
| AC-62 | ja/en 各2件 | `ReadingScreenAcceptanceTests.test_AC62_beginFinishFailureWhilePaused`<br>`ReadingScreenAcceptanceTests.test_AC62_beginFinishFailureWhileReading` |
| AC-63 | ja/en 各2件 | `ReadingScreenAcceptanceTests.test_AC63_beginFinishRetryWhilePaused`<br>`ReadingScreenAcceptanceTests.test_AC63_beginFinishRetryWhileReading` |
| AC-64 | ja/en 各1件 | `FinishInputAcceptanceTests.test_AC64_cancelFinishFailureKeepsInput` |
| AC-65 | ja/en 各1件 | `FinishInputAcceptanceTests.test_AC65_cancelFinishRetryReturnsToReading` |
| AC-66 | ja/en 各1件 | `ReadingScreenAcceptanceTests.test_AC66_discardFailureKeepsReading` |
| AC-67 | ja/en 各1件 | `ReadingScreenAcceptanceTests.test_AC67_discardRetryShowsNoticeWithoutRecord` |

## 次に進める作業

1. 追加のシェル修正とこの検証記録を含む HEAD を push し、その HEAD の全体 CI を確認する。
2. 所有者が確認する設定PR #3 の取り込み後、機能PR #2 に main を取り込む。G2 r2 と G3 の残る5回確認・画面・アクセシビリティ・探索の証拠をそろえる。
3. 全条件がそろうまで Draft を維持する。main へのマージと公開は行わない。

## 記録

- 関門：G2 / G3 の進捗確認（正式な独立レビューの代替ではない）
- 対象：PR #2、HEAD `6b979bb` と設定PR #3
- 日付：2026-10-23
