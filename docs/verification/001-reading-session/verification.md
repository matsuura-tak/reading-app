# 検証レポート 001-reading-session

置き場所：docs/verification/001-reading-session/verification.md

判定：PASS

- 関門：G3
- 検証した役：verifier　日時：2026-10-29 23:45
- コミット：`e90963fc8b347f2bf50fc4b21667c55355198ae5`
- 環境：macOS 27.0.1（Build 26A434）、Xcode 27.1（Build 27A9275）、iOS Simulator `iPhone 17`（iOS 26.0）、バックエンドの接続先：なし（サーバーを持たず端末内で完結）

## 1. 実行したコマンドと結果
すべてのコマンドで再試行オプション（`-retry-tests-on-failure`）は一切使用していない。

### コマンド 1：ReadingKit 単体テスト
- コマンド：`swift test --package-path ios/ReadingKit`
- 終了コード：`0`
- テストの件数（成功 / 失敗 / 飛ばした）：`17 / 0 / 0`（5 suites）
- 出力（末尾30行）：

```text
◇ Test "RecommendationEngine scores weights, filters cooccurrence, and generates S-9 / S-7 / S-1 candidates (AC-75..87, AC-145..148)" started.
◇ Test "Finish reflection text handles 0, 1, and multi-night records with newer-date tie-breaker (AC-85, AC-127..129)" started.
◇ Test "25-character shortening rule (AC-29) handles all boundary cases" started.
◇ Test "Horizontal fallback when line has no Hiragana, Katakana, or Han (AC-30)" started.
◇ Test "InputValidator enforces all character and integer boundaries, full-width digit conversion, and decimal rejection" started.
◇ Test "NightDateCalculator uses 4:00 AM boundary in the record's timeZoneID (AC-22)" started.
◇ Test "OCRPipeline processes vertical page columns, colophon, cover 2-tap, and bookshelf spines (AC-65..68, AC-113, AC-137, AC-138)" started.
✔ Test "EntryURLParser parses all 4 valid schemes and rejects malformed URLs" passed after 0.001 seconds.
✔ Test "Vertical glyph replacement, 90-degree rotation, and Kinsoku (AC-27, AC-28)" passed after 0.001 seconds.
✔ Test "VoiceOver accessibility label never contains vertical presentation forms U+FE10..U+FE4F (AC-99)" passed after 0.001 seconds.
✔ Test "25-character shortening rule (AC-29) handles all boundary cases" passed after 0.001 seconds.
✔ Test "WidgetSnapshot decodes all 4 contract examples and round-trips" passed after 0.001 seconds.
✔ Test "Horizontal fallback when line has no Hiragana, Katakana, or Han (AC-30)" passed after 0.001 seconds.
✔ Test "InputValidator enforces all character and integer boundaries, full-width digit conversion, and decimal rejection" passed after 0.001 seconds.
✔ Test "AuthorNameFormatter cleans NDL dc:creator patterns accurately (AC-92)" passed after 0.001 seconds.
✔ Test "WidgetSnapshot validation catches version!=1, privacy violation, titlePending violation, and unknown appearance fallback" passed after 0.001 seconds.
✔ Suite "VerticalLineLayout Tests" passed after 0.001 seconds.
✔ Test "All 7 hook schemas decode their contract examples cleanly" passed after 0.001 seconds.
✔ Suite "Contract Models & Entry URL Tests" passed after 0.001 seconds.
✔ Test "Finish reflection text handles 0, 1, and multi-night records with newer-date tie-breaker (AC-85, AC-127..129)" passed after 0.004 seconds.
✔ Test "NightDateCalculator uses 4:00 AM boundary in the record's timeZoneID (AC-22)" passed after 0.004 seconds.
✔ Test "ISBNAndCCodeParser validates ISBN-13, rejects non-book barcodes, and derives publisher & label (AC-3, AC-5, AC-11)" passed after 0.005 seconds.
✔ Suite "AuthorNameFormatter & ISBNAndCCodeParser Tests" passed after 0.005 seconds.
✔ Test "Bundled awards.json contains all 76 rows in exact order across the 3 awards (AC-112)" passed after 0.005 seconds.
✔ Test "OCRPipeline processes vertical page columns, colophon, cover 2-tap, and bookshelf spines (AC-65..68, AC-113, AC-137, AC-138)" passed after 0.005 seconds.
✔ Suite "NightDateCalculator, InputValidator & OCRPipeline Tests" passed after 0.005 seconds.
✔ Test "Award matching requires both normalized title and normalized author, rejecting volumes and derivatives (AC-18..21)" passed after 0.013 seconds.
✔ Test "RecommendationEngine scores weights, filters cooccurrence, and generates S-9 / S-7 / S-1 candidates (AC-75..87, AC-145..148)" passed after 0.048 seconds.
✔ Suite "AwardsCatalog & RecommendationEngine Tests" passed after 0.048 seconds.
✔ Test run with 17 tests in 5 suites passed after 0.048 seconds.
```

---

### コマンド 2-A：FirstLaunchTests（ja 構成）
- コマンド：`xcodebuild test -project ios/ReadingApp.xcodeproj -scheme ReadingApp -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.0' -only-testing:ReadingAcceptanceTests/FirstLaunchTests -testLanguage ja -testRegion JP -resultBundlePath /tmp/reading-app-g3-firstlaunch-ja.xcresult`
- 終了コード：`0`
- テストの件数（成功 / 失敗 / 飛ばした）：`2 / 0 / 0`（`AcceptanceTests.xctestplan` の `Japanese (ja)` 1件 + `English (en)` 1件）
- 出力（末尾30行）：

```text
    t =     5.97s Find the "hook.state" Any
    t =     5.98s Waiting 5.0s for "hook.store" Any to exist
    t =     7.01s     Checking `Expect predicate `existsNoRetry == 1` for object "hook.store" Any`
    t =     7.01s         Checking existence of `"hook.store" Any`
    t =     7.04s Find the "hook.store" Any
    t =     7.16s Added attachment named 'AC-1_first_launch'
    t =     7.16s Tear Down
    t =     7.16s     Setting device orientation to Portrait
    t =     7.16s         Wait for com.takumamatsuura.readingapp to idle
Test Case '-[ReadingAcceptanceTests.FirstLaunchTests test_AC1_初回起動で空のしおり画面が出て許可ダイアログが出ない]' passed (7.407 seconds).
Test Suite 'FirstLaunchTests' passed at 2026-10-28 01:53:22.594.
	 Executed 1 test, with 0 failures (0 unexpected) in 7.407 (7.408) seconds
Test Suite 'ReadingAcceptanceTests.xctest' passed at 2026-10-28 01:53:22.594.
	 Executed 1 test, with 0 failures (0 unexpected) in 7.407 (7.409) seconds
Test Suite 'Selected tests' passed at 2026-10-28 01:53:22.595.
	 Executed 1 test, with 0 failures (0 unexpected) in 7.407 (7.410) seconds
2026-10-28 01:53:22.629 xcodebuild[93201:3773921] [MT] IDESchemeActionSDKRecord: operatingSystemBuild = <DVTBuildVersion 24A94232>, error = invalidDigitCount(94232).
2026-10-28 01:53:22.630 xcodebuild[93201:3773921] [MT] IDESchemeActionSDKRecord: operatingSystemBuild = <DVTBuildVersion 24A94232>, error = invalidDigitCount(94232).
2026-10-28 01:53:22.645 xcodebuild[93201:3773921] [MT] IDESchemeActionSDKRecord: operatingSystemBuild = <DVTBuildVersion 24A94232>, error = invalidDigitCount(94232).
2026-10-28 01:53:22.645 xcodebuild[93201:3773921] [MT] IDESchemeActionSDKRecord: operatingSystemBuild = <DVTBuildVersion 24A94232>, error = invalidDigitCount(94232).
2026-10-28 01:53:22.911 xcodebuild[93201:3773921] [MT] IDETestOperationsObserverDebug: 36.673 elapsed -- Testing started completed.
2026-10-28 01:53:22.911 xcodebuild[93201:3773921] [MT] IDETestOperationsObserverDebug: 0.000 sec, +0.000 sec -- start
2026-10-28 01:53:22.911 xcodebuild[93201:3773921] [MT] IDETestOperationsObserverDebug: 36.673 sec, +36.673 sec -- end

Test session results, code coverage, and logs:
	/tmp/reading-app-g3-firstlaunch-ja.xcresult

** TEST SUCCEEDED **

Testing started
```

---

### コマンド 2-B：FirstLaunchTests（en 構成）
- コマンド：`xcodebuild test -project ios/ReadingApp.xcodeproj -scheme ReadingApp -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.0' -only-testing:ReadingAcceptanceTests/FirstLaunchTests -testLanguage en -testRegion US -resultBundlePath /tmp/reading-app-g3-firstlaunch-en.xcresult`
- 終了コード：`0`
- テストの件数（成功 / 失敗 / 飛ばした）：`2 / 0 / 0`（`Japanese (ja)` 1件 + `English (en)` 1件）
- 出力（末尾30行）：

```text
    t =     5.89s Find the "hook.state" Any
    t =     5.90s Waiting 5.0s for "hook.store" Any to exist
    t =     6.95s     Checking `Expect predicate `existsNoRetry == 1` for object "hook.store" Any`
    t =     6.95s         Checking existence of `"hook.store" Any`
    t =     6.96s Find the "hook.store" Any
    t =     7.09s Added attachment named 'AC-1_first_launch'
    t =     7.09s Tear Down
    t =     7.09s     Setting device orientation to Portrait
    t =     7.09s         Wait for com.takumamatsuura.readingapp to idle
Test Case '-[ReadingAcceptanceTests.FirstLaunchTests test_AC1_初回起動で空のしおり画面が出て許可ダイアログが出ない]' passed (7.333 seconds).
Test Suite 'FirstLaunchTests' passed at 2026-10-28 01:54:00.832.
	 Executed 1 test, with 0 failures (0 unexpected) in 7.333 (7.334) seconds
Test Suite 'ReadingAcceptanceTests.xctest' passed at 2026-10-28 01:54:00.833.
	 Executed 1 test, with 0 failures (0 unexpected) in 7.333 (7.335) seconds
Test Suite 'Selected tests' passed at 2026-10-28 01:54:00.833.
	 Executed 1 test, with 0 failures (0 unexpected) in 7.333 (7.336) seconds
2026-10-28 01:54:00.867 xcodebuild[93634:3778966] [MT] IDESchemeActionSDKRecord: operatingSystemBuild = <DVTBuildVersion 24A94232>, error = invalidDigitCount(94232).
2026-10-28 01:54:00.868 xcodebuild[93634:3778966] [MT] IDESchemeActionSDKRecord: operatingSystemBuild = <DVTBuildVersion 24A94232>, error = invalidDigitCount(94232).
2026-10-28 01:54:00.882 xcodebuild[93634:3778966] [MT] IDESchemeActionSDKRecord: operatingSystemBuild = <DVTBuildVersion 24A94232>, error = invalidDigitCount(94232).
2026-10-28 01:54:00.882 xcodebuild[93634:3778966] [MT] IDESchemeActionSDKRecord: operatingSystemBuild = <DVTBuildVersion 24A94232>, error = invalidDigitCount(94232).
2026-10-28 01:54:01.153 xcodebuild[93634:3778966] [MT] IDETestOperationsObserverDebug: 31.084 elapsed -- Testing started completed.
2026-10-28 01:54:01.153 xcodebuild[93634:3778966] [MT] IDETestOperationsObserverDebug: 0.000 sec, +0.000 sec -- start
2026-10-28 01:54:01.153 xcodebuild[93634:3778966] [MT] IDETestOperationsObserverDebug: 31.084 sec, +31.084 sec -- end

Test session results, code coverage, and logs:
	/tmp/reading-app-g3-firstlaunch-en.xcresult

** TEST SUCCEEDED **

Testing started
```

---

### コマンド 3：Debug 受け入れテスト7スイートすべて（ja 指定）
- コマンド：`xcodebuild test -project ios/ReadingApp.xcodeproj -scheme ReadingApp -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.0' -skip-testing:ReadingAcceptanceTests/FirstLaunchTests -skip-testing:ReadingAcceptanceTests/PerformanceTests -testLanguage ja -testRegion JP -resultBundlePath /tmp/reading-app-g3-debug-ja.xcresult`
- 終了コード：`0`
- テストの件数（成功 / 失敗 / 飛ばした）：`288 / 0 / 0`（7スイート 144件 × xctestplan の `Japanese (ja)`・`English (en)` 2構成 = 288件）
  - スイート内訳（1構成あたり144件）：
    - `RegistrationAcceptanceTests`：16件（0 failures）
    - `ShelfAndBookAcceptanceTests`：16件（0 failures）
    - `WidgetAndActivityAcceptanceTests`：20件（0 failures）
    - `ReadingSessionAcceptanceTests`：21件（0 failures）
    - `BookmarkAcceptanceTests`：18件（0 failures）
    - `FinishAndRecommendationAcceptanceTests`：18件（0 failures）
    - `SettingsStoreIntentsAcceptanceTests`：35件（0 failures）
- 出力（末尾30行）：

```text
    t =    12.21s     Synthesize event
    t =    12.50s     Wait for com.takumamatsuura.readingapp to idle
    t =    12.51s Waiting 5.0s for "hook.store" Any to exist
    t =    13.51s     Checking `Expect predicate `existsNoRetry == 1` for object "hook.store" Any`
    t =    13.52s         Checking existence of `"hook.store" Any`
    t =    13.54s Find the "hook.store" Any
    t =    13.56s Tear Down
    t =    13.56s     Setting device orientation to Portrait
    t =    13.56s         Wait for com.takumamatsuura.readingapp to idle
Test Case '-[ReadingAcceptanceTests.ReadingSessionAcceptanceTests test_AC53_読書中に強制終了しても再起動後に続きから数える]' passed (13.827 seconds).
Test Suite 'ReadingSessionAcceptanceTests' passed at 2026-10-28 03:07:16.089.
	 Executed 21 tests, with 0 failures (0 unexpected) in 299.389 (299.423) seconds
Test Suite 'ReadingAcceptanceTests.xctest' passed at 2026-10-28 03:07:16.090.
	 Executed 144 tests, with 0 failures (0 unexpected) in 2177.616 (2177.830) seconds
Test Suite 'Selected tests' passed at 2026-10-28 03:07:16.091.
	 Executed 144 tests, with 0 failures (0 unexpected) in 2177.616 (2177.832) seconds
2026-10-28 03:07:16.141 xcodebuild[93902:3782888] [MT] IDESchemeActionSDKRecord: operatingSystemBuild = <DVTBuildVersion 24A94232>, error = invalidDigitCount(94232).
2026-10-28 03:07:16.141 xcodebuild[93902:3782888] [MT] IDESchemeActionSDKRecord: operatingSystemBuild = <DVTBuildVersion 24A94232>, error = invalidDigitCount(94232).
2026-10-28 03:07:16.159 xcodebuild[93902:3782888] [MT] IDESchemeActionSDKRecord: operatingSystemBuild = <DVTBuildVersion 24A94232>, error = invalidDigitCount(94232).
2026-10-28 03:07:16.159 xcodebuild[93902:3782888] [MT] IDESchemeActionSDKRecord: operatingSystemBuild = <DVTBuildVersion 24A94232>, error = invalidDigitCount(94232).
2026-10-28 03:07:16.542 xcodebuild[93902:3782888] [MT] IDETestOperationsObserverDebug: 4378.042 elapsed -- Testing started completed.
2026-10-28 03:07:16.542 xcodebuild[93902:3782888] [MT] IDETestOperationsObserverDebug: 0.000 sec, +0.000 sec -- start
2026-10-28 03:07:16.542 xcodebuild[93902:3782888] [MT] IDETestOperationsObserverDebug: 4378.042 sec, +4378.042 sec -- end

Test session results, code coverage, and logs:
	/tmp/reading-app-g3-debug-ja.xcresult

** TEST SUCCEEDED **

Testing started
```

---

### コマンド 4：Debug 受け入れテスト7スイートすべて（en 指定）
- コマンド：`xcodebuild test -project ios/ReadingApp.xcodeproj -scheme ReadingApp -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.0' -skip-testing:ReadingAcceptanceTests/FirstLaunchTests -skip-testing:ReadingAcceptanceTests/PerformanceTests -testLanguage en -testRegion US -resultBundlePath /tmp/reading-app-g3-debug-en.xcresult`
- 終了コード：`0`
- テストの件数（成功 / 失敗 / 飛ばした）：`288 / 0 / 0`（7スイート 144件 × 2構成 = 288件）
- 出力（末尾30行）：

```text
    t =    11.71s Tap Button (First Match)
    t =    11.71s     Wait for com.takumamatsuura.readingapp to idle
    t =    11.72s     Find the Button (First Match)
    t =    11.73s     Check for interrupting elements affecting "BackButton" Button
    t =    11.76s     Synthesize event
    t =    12.05s     Wait for com.takumamatsuura.readingapp to idle
    t =    12.05s Tear Down
    t =    12.05s     Setting device orientation to Portrait
    t =    12.06s         Wait for com.takumamatsuura.readingapp to idle
Test Case '-[ReadingAcceptanceTests.ShelfAndBookAcceptanceTests test_AC20_片方不一致や派生本には受賞を出さない]' passed (12.329 seconds).
Test Suite 'ShelfAndBookAcceptanceTests' passed at 2026-10-28 04:20:49.196.
	 Executed 16 tests, with 0 failures (0 unexpected) in 258.673 (258.696) seconds
Test Suite 'ReadingAcceptanceTests.xctest' passed at 2026-10-28 04:20:49.200.
	 Executed 144 tests, with 0 failures (0 unexpected) in 2194.609 (2194.816) seconds
Test Suite 'Selected tests' passed at 2026-10-28 04:20:49.203.
	 Executed 144 tests, with 0 failures (0 unexpected) in 2194.609 (2194.819) seconds
2026-10-28 04:20:49.254 xcodebuild[97781:3874790] [MT] IDESchemeActionSDKRecord: operatingSystemBuild = <DVTBuildVersion 24A94232>, error = invalidDigitCount(94232).
2026-10-28 04:20:49.254 xcodebuild[97781:3874790] [MT] IDESchemeActionSDKRecord: operatingSystemBuild = <DVTBuildVersion 24A94232>, error = invalidDigitCount(94232).
2026-10-28 04:20:49.274 xcodebuild[97781:3874790] [MT] IDESchemeActionSDKRecord: operatingSystemBuild = <DVTBuildVersion 24A94232>, error = invalidDigitCount(94232).
2026-10-28 04:20:49.274 xcodebuild[97781:3874790] [MT] IDESchemeActionSDKRecord: operatingSystemBuild = <DVTBuildVersion 24A94232>, error = invalidDigitCount(94232).
2026-10-28 04:20:49.666 xcodebuild[97781:3874790] [MT] IDETestOperationsObserverDebug: 4393.241 elapsed -- Testing started completed.
2026-10-28 04:20:49.666 xcodebuild[97781:3874790] [MT] IDETestOperationsObserverDebug: 0.000 sec, +0.000 sec -- start
2026-10-28 04:20:49.666 xcodebuild[97781:3874790] [MT] IDETestOperationsObserverDebug: 4393.241 sec, +4393.241 sec -- end

Test session results, code coverage, and logs:
	/tmp/reading-app-g3-debug-en.xcresult

** TEST SUCCEEDED **

Testing started
```

---

### コマンド 5：PerformanceTests（Perf 構成、ja / en 両構成）
- コマンド：`xcodebuild test -project ios/ReadingApp.xcodeproj -scheme ReadingApp -configuration Perf -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.0' -only-testing:ReadingAcceptanceTests/PerformanceTests -resultBundlePath /tmp/reading-app-g3-perf.xcresult`
- 終了コード：`0`
- テストの件数（成功 / 失敗 / 飛ばした）：`8 / 0 / 0`（`Japanese (ja)` 4件 + `English (en)` 4件 = 8件）
- 出力（末尾30行）：

```text
    t =    84.41s Tap "register.cancel" Any
    t =    84.41s     Wait for com.takumamatsuura.readingapp to idle
    t =    84.41s     Find the "register.cancel" Any
    t =    84.46s     Check for interrupting elements affecting "register.cancel" Other
    t =    84.49s     Synthesize event
    t =    84.78s     Wait for com.takumamatsuura.readingapp to idle
    t =    84.79s Tear Down
    t =    84.79s     Setting device orientation to Portrait
    t =    84.80s         Wait for com.takumamatsuura.readingapp to idle
Test Case '-[ReadingAcceptanceTests.PerformanceTests test_AC149_端末内書誌DBのISBN検索と書名検索の5回平均が300ミリ秒以内]' passed (85.075 seconds).
Test Suite 'PerformanceTests' passed at 2026-10-29 22:32:03.000.
	 Executed 4 tests, with 0 failures (0 unexpected) in 268.228 (268.235) seconds
Test Suite 'ReadingAcceptanceTests.xctest' passed at 2026-10-29 22:32:03.003.
	 Executed 4 tests, with 0 failures (0 unexpected) in 268.228 (268.238) seconds
Test Suite 'Selected tests' passed at 2026-10-29 22:32:03.004.
	 Executed 4 tests, with 0 failures (0 unexpected) in 268.228 (268.241) seconds
2026-10-29 22:32:03.422 xcodebuild[39998:1092584] [MT] IDESchemeActionSDKRecord: operatingSystemBuild = <DVTBuildVersion 24A94232>, error = invalidDigitCount(94232).
2026-10-29 22:32:03.426 xcodebuild[39998:1092584] [MT] IDESchemeActionSDKRecord: operatingSystemBuild = <DVTBuildVersion 24A94232>, error = invalidDigitCount(94232).
2026-10-29 22:32:03.455 xcodebuild[39998:1092584] [MT] IDESchemeActionSDKRecord: operatingSystemBuild = <DVTBuildVersion 24A94232>, error = invalidDigitCount(94232).
2026-10-29 22:32:03.455 xcodebuild[39998:1092584] [MT] IDESchemeActionSDKRecord: operatingSystemBuild = <DVTBuildVersion 24A94232>, error = invalidDigitCount(94232).
2026-10-29 22:32:03.828 xcodebuild[39998:1092584] [MT] IDETestOperationsObserverDebug: 717.347 elapsed -- Testing started completed.
2026-10-29 22:32:03.828 xcodebuild[39998:1092584] [MT] IDETestOperationsObserverDebug: 0.000 sec, +0.000 sec -- start
2026-10-29 22:32:03.828 xcodebuild[39998:1092584] [MT] IDETestOperationsObserverDebug: 717.347 sec, +717.347 sec -- end

Test session results, code coverage, and logs:
	/tmp/reading-app-g3-perf.xcresult

** TEST SUCCEEDED **

Testing started
```


## 2. 受け入れ条件ごとの結果
`AcceptanceTests.xctestplan` の `Japanese (ja)` 構成と `English (en)` 構成の2通りすべてで実行し、全 149 AC（計 298 実行 + 単体テスト 17 件）で失敗 0・スキップ 0・揺れ 0 を確認した。

| AC | 結果（PASS / FAIL / 未検証） | 動いたテストの数 | 飛ばしたテストの数 | 証拠（テストの名前、ログの行、スクリーンショットのパス） |
|---|---|---|---|---|
| AC-1 | PASS | 2（ja・en） | 0 | `FirstLaunchTests.swift::test_AC1_初回起動で空のしおり画面が出て許可ダイアログが出ない` / コマンド 2-A / 2-B（`FirstLaunchTests` passed, 0 failures） / `docs/verification/001-reading-session/evidence/S1_empty_light.png`, `docs/verification/001-reading-session/evidence/S1_empty_dark.png`, `docs/verification/001-reading-session/evidence/S1_empty_ax5.png`, `docs/verification/001-reading-session/evidence/S1_empty_en.png` |
| AC-2 | PASS | 2（ja・en） | 0 | `RegistrationAcceptanceTests.swift::test_AC2_バーコードで最初の1冊を加えると今の本になる` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S8_normal_light.png`, `docs/verification/001-reading-session/evidence/S8a_normal_light.png` |
| AC-3 | PASS | 2（ja・en） | 0 | `RegistrationAcceptanceTests.swift::test_AC3_バーコード連続読取で重複と非図書を除きCコードで文庫を補う` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S8a_normal_light.png`, `docs/verification/001-reading-session/evidence/N_normal_light.png` |
| AC-4 | PASS | 2（ja・en） | 0 | `RegistrationAcceptanceTests.swift::test_AC4_手入力欄で端末内書誌DBの候補から選んで保存できる` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S8c_normal_light.png` |
| AC-5 | PASS | 2（ja・en） | 0 | `RegistrationAcceptanceTests.swift::test_AC5_書誌DBの候補が0件でもそのまま手入力で保存できる` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S8c_empty_light.png` |
| AC-6 | PASS | 2（ja・en） | 0 | `RegistrationAcceptanceTests.swift::test_AC6_機内モードでも端末内書誌DBでバーコード登録が動く` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S8a_normal_light.png` |
| AC-7 | PASS | 2（ja・en） | 0 | `RegistrationAcceptanceTests.swift::test_AC7_候補を選ばずに前後空白を除いて積読に保存できる` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S8c_normal_light.png`, `docs/verification/001-reading-session/evidence/S6_normal_light.png` |
| AC-8 | PASS | 2（ja・en） | 0 | `RegistrationAcceptanceTests.swift::test_AC8_手入力の書名と著者の文字数境界を検証する` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S8c_error_light.png` |
| AC-9 | PASS | 2（ja・en） | 0 | `RegistrationAcceptanceTests.swift::test_AC9_書誌DB未取得時にその場で書名を入れて追加できる` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S8a_partial_light.png` |
| AC-10 | PASS | 2（ja・en） | 0 | `RegistrationAcceptanceTests.swift::test_AC10_書誌DBにないISBNをその場で書名入力して追加できる` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S8a_partial_light.png`, `docs/verification/001-reading-session/evidence/S7c_partial_light.png` |
| AC-11 | PASS | 2（ja・en） | 0 | `RegistrationAcceptanceTests.swift::test_AC11_未収録ISBNとCコードから岩波書店と文庫を補完する` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S8_partial_light.png`, `docs/verification/001-reading-session/evidence/S8c_partial_light.png`, `docs/verification/001-reading-session/evidence/S10_partial_light.png` |
| AC-12 | PASS | 2（ja・en） | 0 | `RegistrationAcceptanceTests.swift::test_AC12_カメラ拒否時に設定とスクショと手入力の導線が出る` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S8_denied_light.png` |
| AC-13 | PASS | 2（ja・en） | 0 | `ShelfAndBookAcceptanceTests.swift::test_AC13_本棚の3区分と積読の新しい順の並びを検証する` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S6_normal_light.png`, `docs/verification/001-reading-session/evidence/S6_shelf_light.png`, `docs/verification/001-reading-session/evidence/S6_shelf_dark.png` |
| AC-14 | PASS | 2（ja・en） | 0 | `ShelfAndBookAcceptanceTests.swift::test_AC14_積読や読了の本を今の本に切り替えられる` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S7_normal_light.png`, `docs/verification/001-reading-session/evidence/S1_normal_light.png` |
| AC-15 | PASS | 2（ja・en） | 0 | `ShelfAndBookAcceptanceTests.swift::test_AC15_本の書名と著者を直しても記録が保たれる` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S6_normal_light.png`, `docs/verification/001-reading-session/evidence/S9_normal_light.png` |
| AC-16 | PASS | 2（ja・en） | 0 | `ShelfAndBookAcceptanceTests.swift::test_AC16_今の本を消すと記録も消え今の本なしになる` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S1_empty_light.png`, `docs/verification/001-reading-session/evidence/S7_normal_light.png` |
| AC-17 | PASS | 2（ja・en） | 0 | `ShelfAndBookAcceptanceTests.swift::test_AC17_本の画面の奥付5行と出版社レーベル受賞が出る` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S7_normal_light.png`, `docs/verification/001-reading-session/evidence/S7_book_light.png` |
| AC-18 | PASS | 2（ja・en） | 0 | `ShelfAndBookAcceptanceTests.swift::test_AC18_奥付でデータのない行や不明の文字を出さない` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S7_partial_light.png` |
| AC-19 | PASS | 2（ja・en） | 0 | `ShelfAndBookAcceptanceTests.swift::test_AC19_書名と著者の両方が一致するとき受賞が出る` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S7_normal_light.png` |
| AC-20 | PASS | 2（ja・en） | 0 | `ShelfAndBookAcceptanceTests.swift::test_AC20_片方不一致や派生本には受賞を出さない` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S7_partial_light.png` |
| AC-21 | PASS | 2（ja・en） | 0 | `ShelfAndBookAcceptanceTests.swift::test_AC21_記号や括弧の違いを正規化して受賞を照合する` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S7a_normal_light.png` |
| AC-22 | PASS | 2（ja・en） | 0 | `ShelfAndBookAcceptanceTests.swift::test_AC22_4時境目の晩の日付とタイムゾーン変更不変を検証する` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S7_normal_light.png`, `docs/verification/001-reading-session/evidence/explore_R1.png` |
| AC-23 | PASS | 2（ja・en） | 0 | `ShelfAndBookAcceptanceTests.swift::test_AC23_記録がない本の画面に空の案内が出る` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S7_empty_light.png` |
| AC-24 | PASS | 2（ja・en） | 0 | `ShelfAndBookAcceptanceTests.swift::test_AC24_記録の分数を直すと合計分数が更新される` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S7b_normal_light.png` |
| AC-25 | PASS | 2（ja・en） | 0 | `ShelfAndBookAcceptanceTests.swift::test_AC25_記録の分数の入力境界値を検証する` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S7b_error_light.png` |
| AC-26 | PASS | 2（ja・en） | 0 | `ShelfAndBookAcceptanceTests.swift::test_AC26_記録を消すと件数と合計と晩数が減る` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S7b_normal_light.png` |
| AC-27 | PASS | 2（ja・en） | 0 | `WidgetAndActivityAcceptanceTests.swift::test_AC27_ロック画面ウィジェットに縦書きの一行とページが出る` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/AC27_W1_172x76.png`, `docs/verification/001-reading-session/evidence/AC27_W1_153x68.png`, `docs/verification/001-reading-session/evidence/W1_normal_light.png` |
| AC-28 | PASS | 2（ja・en） | 0 | `WidgetAndActivityAcceptanceTests.swift::test_AC28_縦書きの字形置換と行頭禁則処理を検証する` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/AC28_W1_kinsoku.png` |
| AC-29 | PASS | 2（ja・en） | 0 | `WidgetAndActivityAcceptanceTests.swift::test_AC29_26字以上の一行の句読点位置による縮め方を検証する` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/AC29_W1_truncated.png` |
| AC-30 | PASS | 2（ja・en） | 0 | `WidgetAndActivityAcceptanceTests.swift::test_AC30_欧文のみの一行は横書き1行で出る` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/W1_partial_light.png` |
| AC-31 | PASS | 2（ja・en） | 0 | `WidgetAndActivityAcceptanceTests.swift::test_AC31_一行がないときは書名とページをウィジェットに出す` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/W1_empty_light.png` |
| AC-32 | PASS | 2（ja・en） | 0 | `WidgetAndActivityAcceptanceTests.swift::test_AC32_今の本がないときはウィジェットに空の文言が出る` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/W1_empty_light.png` |
| AC-33 | PASS | 2（ja・en） | 0 | `WidgetAndActivityAcceptanceTests.swift::test_AC33_しおり保存でウィジェットが1回だけ再読み込みされる` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/W1_normal_light.png`, `docs/verification/001-reading-session/evidence/S4_result_light.png` |
| AC-34 | PASS | 2（ja・en） | 0 | `WidgetAndActivityAcceptanceTests.swift::test_AC34_隠す設定オンでウィジェットとLiveActivityから書名と一行を隠す` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/AC34_W1_hidden.png`, `docs/verification/001-reading-session/evidence/AC34_S1_visible.png` |
| AC-35 | PASS | 2（ja・en） | 0 | `WidgetAndActivityAcceptanceTests.swift::test_AC35_StandBy用の小ウィジェットに縦書きの一行とページが出る` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/AC35_W2_170x170.png`, `docs/verification/001-reading-session/evidence/AC35_W2_148x148.png`, `docs/verification/001-reading-session/evidence/W2_normal_light.png` |
| AC-36 | PASS | 2（ja・en） | 0 | `WidgetAndActivityAcceptanceTests.swift::test_AC36_しおり保存で翌晩21時のLiveActivityが1件予約される` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/W3_normal_light.png` |
| AC-37 | PASS | 2（ja・en） | 0 | `WidgetAndActivityAcceptanceTests.swift::test_AC37_LiveActivityオフ時は予約要求を出さず設定に案内を出す` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/W3_denied_light.png`, `docs/verification/001-reading-session/evidence/S10_denied_light.png` |
| AC-38 | PASS | 2（ja・en） | 0 | `WidgetAndActivityAcceptanceTests.swift::test_AC38_夜の入口の時刻を15分刻みで変えると予約時刻が変わる` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S10_normal_light.png`, `docs/verification/001-reading-session/evidence/W3_normal_light.png` |
| AC-39 | PASS | 2（ja・en） | 0 | `WidgetAndActivityAcceptanceTests.swift::test_AC39_予約がない晩でもアイコン起動でしおり画面が開き伏せ監視がオンになる` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S1_normal_light.png` |
| AC-40 | PASS | 2（ja・en） | 0 | `WidgetAndActivityAcceptanceTests.swift::test_AC40_入口のURLと300秒境界で記録の入口の印が決まる` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S1_normal_light.png`, `docs/verification/001-reading-session/evidence/S4_normal_light.png` |
| AC-41 | PASS | 2（ja・en） | 0 | `WidgetAndActivityAcceptanceTests.swift::test_AC41_表示中の予約LiveActivityが読書中から結果表示へ遷移する` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/W3_normal_light.png` |
| AC-42 | PASS | 2（ja・en） | 0 | `ReadingSessionAcceptanceTests.swift::test_AC42_起動から1タップで確認や入力なしに読み始められる` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S1_normal_light.png`, `docs/verification/001-reading-session/evidence/S1_normal_dark.png`, `docs/verification/001-reading-session/evidence/S1_normal_ax5.png`, `docs/verification/001-reading-session/evidence/S1_normal_en.png` |
| AC-43 | PASS | 2（ja・en） | 0 | `ReadingSessionAcceptanceTests.swift::test_AC43_読書中の画面は押せる要素が終えるの1つだけになる` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S2_reading_light.png`, `docs/verification/001-reading-session/evidence/S2_reading_dark.png`, `docs/verification/001-reading-session/evidence/S2_reading_ax5.png`, `docs/verification/001-reading-session/evidence/S2_reading_en.png` |
| AC-44 | PASS | 2（ja・en） | 0 | `ReadingSessionAcceptanceTests.swift::test_AC44_しおり画面で伏せて1秒たつと触覚が1回鳴り読み始める` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S2_normal_light.png`, `docs/verification/001-reading-session/evidence/explore_R2.png` |
| AC-45 | PASS | 2（ja・en） | 0 | `ReadingSessionAcceptanceTests.swift::test_AC45_伏せて1秒未満で起こすと読み始めない` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S1_normal_light.png`, `docs/verification/001-reading-session/evidence/explore_R2.png` |
| AC-46 | PASS | 2（ja・en） | 0 | `ReadingSessionAcceptanceTests.swift::test_AC46_今の本がないときは伏せの監視がオフで始まらない` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S6_normal_light.png`, `docs/verification/001-reading-session/evidence/S3_normal_light.png`, `docs/verification/001-reading-session/evidence/S1_empty_light.png` |
| AC-47 | PASS | 2（ja・en） | 0 | `ReadingSessionAcceptanceTests.swift::test_AC47_しおり画面以外や知らせ表示中は伏せても始まらない` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S2_normal_light.png` |
| AC-48 | PASS | 2（ja・en） | 0 | `ReadingSessionAcceptanceTests.swift::test_AC48_読書中に起こしても止まらず伏せ直しても二重に始まらない` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S2_normal_light.png` |
| AC-49 | PASS | 2（ja・en） | 0 | `ReadingSessionAcceptanceTests.swift::test_AC49_伏せて読み始めたときにVoiceOver読み上げが1回出る` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S10_normal_light.png`, `docs/verification/001-reading-session/evidence/S1_normal_light.png` |
| AC-50 | PASS | 2（ja・en） | 0 | `ReadingSessionAcceptanceTests.swift::test_AC50_しおり画面に伏せて始める案内の1行が出る` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S1_normal_light.png` |
| AC-51 | PASS | 2（ja・en） | 0 | `ReadingSessionAcceptanceTests.swift::test_AC51_伏せる設定オフまたは非対応環境では伏せても始まらない` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S10_partial_light.png`, `docs/verification/001-reading-session/evidence/S1_partial_light.png` |
| AC-52 | PASS | 2（ja・en） | 0 | `ReadingSessionAcceptanceTests.swift::test_AC52_バックグラウンドの間も開始時刻からの差で時間を数える` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S2_normal_light.png` |
| AC-53 | PASS | 2（ja・en） | 0 | `ReadingSessionAcceptanceTests.swift::test_AC53_読書中に強制終了しても再起動後に続きから数える` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S2_normal_light.png`, `docs/verification/001-reading-session/evidence/explore_R1.png` |
| AC-54 | PASS | 2（ja・en） | 0 | `ReadingSessionAcceptanceTests.swift::test_AC54_読書中も自動ロック無効化と近接センサー監視を使わない` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S2_normal_light.png` |
| AC-55 | PASS | 2（ja・en） | 0 | `ReadingSessionAcceptanceTests.swift::test_AC55_終える1タップで確認なしに500ミリ秒以内にしおり画面が出る` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S3_choices_light.png` |
| AC-56 | PASS | 2（ja・en） | 0 | `ReadingSessionAcceptanceTests.swift::test_AC56_59秒は記録せず60秒ちょうどから1分として記録する` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S1_normal_light.png`, `docs/verification/001-reading-session/evidence/N_normal_light.png` |
| AC-57 | PASS | 2（ja・en） | 0 | `ReadingSessionAcceptanceTests.swift::test_AC57_24時間超は1440分で止めて上限の知らせを出す` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S4_partial_light.png` |
| AC-58 | PASS | 2（ja・en） | 0 | `ReadingSessionAcceptanceTests.swift::test_AC58_端末時刻が開始より前に戻ったときは記録せず知らせを出す` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S1_normal_light.png`, `docs/verification/001-reading-session/evidence/N_normal_light.png` |
| AC-59 | PASS | 2（ja・en） | 0 | `ReadingSessionAcceptanceTests.swift::test_AC59_読み始めの保存失敗時はidleのままエラーを出す` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S1_error_light.png`, `docs/verification/001-reading-session/evidence/N_error_light.png` |
| AC-60 | PASS | 2（ja・en） | 0 | `ReadingSessionAcceptanceTests.swift::test_AC60_終わりの保存失敗時は読書中を保ち再試行で合算保存される` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S2_error_light.png`, `docs/verification/001-reading-session/evidence/explore_R5.png` |
| AC-61 | PASS | 2（ja・en） | 0 | `ReadingSessionAcceptanceTests.swift::test_AC61_開始と終了の二度押しで記録や画面が重複しない` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S1_normal_light.png`, `docs/verification/001-reading-session/evidence/S4_normal_light.png` |
| AC-62 | PASS | 2（ja・en） | 0 | `ReadingSessionAcceptanceTests.swift::test_AC62_オフラインでもウィジェット起動からしおり保存まで完走する` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S4_result_light.png` |
| AC-63 | PASS | 2（ja・en） | 0 | `BookmarkAcceptanceTests.swift::test_AC63_しおりを挟む画面に5つの道がすべて押せる状態で出る` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S3_choices_light.png`, `docs/verification/001-reading-session/evidence/S3_normal_light.png` |
| AC-64 | PASS | 2（ja・en） | 0 | `BookmarkAcceptanceTests.swift::test_AC64_読まずにしおりだけを挟むと記録を増やさず更新される` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S3_empty_light.png` |
| AC-65 | PASS | 2（ja・en） | 0 | `BookmarkAcceptanceTests.swift::test_AC65_ページ写真OCRで一番左の列が初期選択され保存できる` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/AC65_S3c_ocr.png`, `docs/verification/001-reading-session/evidence/S3c_normal_light.png` |
| AC-66 | PASS | 2（ja・en） | 0 | `BookmarkAcceptanceTests.swift::test_AC66_OCR結果の別の列を選び直して保存できる` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/AC65_S3c_ocr.png`, `docs/verification/001-reading-session/evidence/S3c_normal_light.png` |
| AC-67 | PASS | 2（ja・en） | 0 | `BookmarkAcceptanceTests.swift::test_AC67_OCRの誤字を入力欄で手直しして保存できる` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S3c_partial_light.png` |
| AC-68 | PASS | 2（ja・en） | 0 | `BookmarkAcceptanceTests.swift::test_AC68_文字が1行も読み取れないときに撮り直しと手入力が出る` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S3c_empty_light.png` |
| AC-69 | PASS | 2（ja・en） | 0 | `BookmarkAcceptanceTests.swift::test_AC69_撮影したページ画像と未選択列の文字を一切残さない` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/AC65_S3c_ocr.png`, `docs/verification/001-reading-session/evidence/explore_R3.png` |
| AC-70 | PASS | 2（ja・en） | 0 | `BookmarkAcceptanceTests.swift::test_AC70_しおり撮影でカメラ拒否時にスクショと手入力の導線が出る` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S3_denied_light.png` |
| AC-71 | PASS | 2（ja・en） | 0 | `BookmarkAcceptanceTests.swift::test_AC71_手入力の一行の前後空白を除いて保存する` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S3a_normal_light.png` |
| AC-72 | PASS | 2（ja・en） | 0 | `BookmarkAcceptanceTests.swift::test_AC72_一行の1字から60字までの境界値を検証する` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S3a_error_light.png` |
| AC-73 | PASS | 2（ja・en） | 0 | `BookmarkAcceptanceTests.swift::test_AC73_ページ数だけ入れると一行が空になりウィジェットも書名とページになる` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S3b_normal_light.png` |
| AC-74 | PASS | 2（ja・en） | 0 | `BookmarkAcceptanceTests.swift::test_AC74_ページ番号の1から9999までの境界値と全角数字を検証する` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S3b_error_light.png` |
| AC-75 | PASS | 2（ja・en） | 0 | `BookmarkAcceptanceTests.swift::test_AC75_あとでを選ぶと前のしおりを保ち結果画面に分数だけが出る` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S4_empty_light.png` |
| AC-76 | PASS | 2（ja・en） | 0 | `BookmarkAcceptanceTests.swift::test_AC76_結果画面に前回ページからの遷移と分数が出て1タップで閉じる` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S4_result_light.png`, `docs/verification/001-reading-session/evidence/S4_empty_light.png` |
| AC-77 | PASS | 2（ja・en） | 0 | `FinishAndRecommendationAcceptanceTests.swift::test_AC77_読み終えたボタンで読了になり奥付5行と奥付撮影ボタンが出る` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S9_finish_light.png`, `docs/verification/001-reading-session/evidence/S9_normal_light.png` |
| AC-78 | PASS | 2（ja・en） | 0 | `FinishAndRecommendationAcceptanceTests.swift::test_AC78_次の1冊に積読の関連本2冊と未所有の関連本1冊が順に並ぶ` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S9_finish_light.png` |
| AC-79 | PASS | 2（ja・en） | 0 | `FinishAndRecommendationAcceptanceTests.swift::test_AC79_次の1冊の各候補に事実1行の理由が出る` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S9_finish_light.png` |
| AC-80 | PASS | 2（ja・en） | 0 | `FinishAndRecommendationAcceptanceTests.swift::test_AC80_未所有の候補がないときは積読から最大3冊を出す` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S9_finish_light.png` |
| AC-81 | PASS | 2（ja・en） | 0 | `FinishAndRecommendationAcceptanceTests.swift::test_AC81_積読も未所有の候補もないときは本を加える案内が出る` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S9_empty_light.png` |
| AC-82 | PASS | 2（ja・en） | 0 | `FinishAndRecommendationAcceptanceTests.swift::test_AC82_次の1冊で積読の本を選ぶと今の本になりウィジェットも更新される` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S9_finish_light.png`, `docs/verification/001-reading-session/evidence/S1_normal_light.png` |
| AC-83 | PASS | 2（ja・en） | 0 | `FinishAndRecommendationAcceptanceTests.swift::test_AC83_受賞一覧から出た未所有の本を積読に加えられる` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S9_finish_light.png` |
| AC-84 | PASS | 2（ja・en） | 0 | `FinishAndRecommendationAcceptanceTests.swift::test_AC84_読み終えのカード画像に書名著者晩数分数だけを描き一行を含めない` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/AC84_finish_card.png` |
| AC-85 | PASS | 2（ja・en） | 0 | `FinishAndRecommendationAcceptanceTests.swift::test_AC85_読み終えのカードの晩数を4時境目のユニーク晩数で数える` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/AC84_finish_card.png` |
| AC-86 | PASS | 2（ja・en） | 0 | `FinishAndRecommendationAcceptanceTests.swift::test_AC86_今の本がある毎晩の道には次の1冊の候補を出さない` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S1_normal_light.png`, `docs/verification/001-reading-session/evidence/S2_normal_light.png`, `docs/verification/001-reading-session/evidence/S3_normal_light.png`, `docs/verification/001-reading-session/evidence/S4_normal_light.png` |
| AC-87 | PASS | 2（ja・en） | 0 | `FinishAndRecommendationAcceptanceTests.swift::test_AC87_端末内書誌DBからシリーズの次の巻と同じ著者の本を推薦し書誌つきで積読に加える` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S9_finish_light.png` |
| AC-88 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC88_設定画面からプライバシーポリシーのURLを開く` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S10_settings_light.png` |
| AC-89 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC89_画面操作で入れた本と記録としおりと設定が再起動後もすべて残る` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S1_normal_light.png`, `docs/verification/001-reading-session/evidence/S2_normal_light.png`, `docs/verification/001-reading-session/evidence/S4_normal_light.png`, `docs/verification/001-reading-session/evidence/S9_normal_light.png` |
| AC-90 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC90_起動時の保存先読込失敗でエラーを出し再起動で元のデータが戻る` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S1_error_light.png` |
| AC-91 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC91_7種類の保存失敗時にエラーが出て変更前のデータが保たれる` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S1_error_light.png`, `docs/verification/001-reading-session/evidence/S7_error_light.png`, `docs/verification/001-reading-session/evidence/S8a_error_light.png`, `docs/verification/001-reading-session/evidence/S8c_error_light.png`, `docs/verification/001-reading-session/evidence/S9_error_light.png`, `docs/verification/001-reading-session/evidence/S10_error_light.png` |
| AC-92 | PASS | 2（ja・en） | 0 | `RegistrationAcceptanceTests.swift::test_AC92_NDL書誌の著者名から生没年や役割語や2人目以降を除いて整形する` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S8c_normal_light.png` |
| AC-93 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC93_設定画面にNDLの3条件とCCBYリンクが出てしおり画面と読書中画面には出ない` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/AC93_S10_dataSources.png`, `docs/verification/001-reading-session/evidence/S10_settings_light.png` |
| AC-94 | PASS | 2（ja・en） | 0 | `BookmarkAcceptanceTests.swift::test_AC94_OCR待ちの間も1秒以内に手入力やページ入力に移り後から結果が返っても上書きされない` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S3c_loading_light.png`, `docs/verification/001-reading-session/evidence/explore_R3.png` |
| AC-95 | PASS | 2（ja・en） | 0 | `BookmarkAcceptanceTests.swift::test_AC95_読後のしおり保存失敗時も記録は残り入力値を保ったまま再保存できる` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S3a_error_light.png`, `docs/verification/001-reading-session/evidence/S3c_error_light.png` |
| AC-96 | PASS | 2（ja・en） | 0 | `WidgetAndActivityAcceptanceTests.swift::test_AC96_ウィジェットの置き方案内は最初の1回だけ出る` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S5_normal_light.png` |
| AC-97 | PASS | 2（ja・en） | 0 | `WidgetAndActivityAcceptanceTests.swift::test_AC97_LiveActivity予約失敗時はアラートを出さず次回前面復帰時に予約し直す` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/W3_error_light.png` |
| AC-98 | PASS | 2（ja・en） | 0 | `WidgetAndActivityAcceptanceTests.swift::test_AC98_読まなかった晩のLiveActivityは翌朝前面復帰で終了し今夜分を予約する` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/W3_normal_light.png` |
| AC-99 | PASS | 2（ja・en） | 0 | `WidgetAndActivityAcceptanceTests.swift::test_AC99_ウィジェットとしおり画面のVoiceOverラベルに縦書き用字形が含まれない` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/W1_normal_light.png`, `docs/verification/001-reading-session/evidence/S1_normal_light.png` |
| AC-100 | PASS | 2（ja・en） | 0 | `PerformanceTests.swift::test_AC100_本3冊記録10件での起動から操作可能までの平均が1秒以内` / コマンド 5（`PerformanceTests` Perf 構成 passed, 0 failures） / `docs/verification/001-reading-session/evidence/S1_normal_light.png` |
| AC-101 | PASS | 2（ja・en） | 0 | `PerformanceTests.swift::test_AC101_本500冊記録5000件での本棚と本の画面の表示平均が1秒以内` / コマンド 5（`PerformanceTests` Perf 構成 passed, 0 failures） / `docs/verification/001-reading-session/evidence/S6_loading_light.png`, `docs/verification/001-reading-session/evidence/S7_loading_light.png` |
| AC-102 | PASS | 2（ja・en） | 0 | `PerformanceTests.swift::test_AC102_ウィジェット2種類のタイムライン生成平均が500ミリ秒以内` / コマンド 5（`PerformanceTests` Perf 構成 passed, 0 failures） / `docs/verification/001-reading-session/evidence/S4_result_light.png`, `docs/verification/001-reading-session/evidence/W1_normal_light.png` |
| AC-103 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC103_登録から読了カード共有まで外部HTTP通信が0件である` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S1_normal_light.png`, `docs/verification/001-reading-session/evidence/AC84_finish_card.png`, `docs/verification/001-reading-session/evidence/explore_R6.png` |
| AC-104 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC104_未購入でも毎晩の道と読み終えた画面に課金案内が出ない` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S1_normal_light.png`, `docs/verification/001-reading-session/evidence/S2_normal_light.png`, `docs/verification/001-reading-session/evidence/S3_normal_light.png`, `docs/verification/001-reading-session/evidence/S4_normal_light.png`, `docs/verification/001-reading-session/evidence/S9_normal_light.png` |
| AC-105 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC105_鍵つき見た目を押すと見本と購入シートが出て閉じると標準に戻る` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/AC105_S10a_preview.png`, `docs/verification/001-reading-session/evidence/S10a_normal_light.png` |
| AC-106 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC106_購入すると見た目を選べてウィジェットと再起動後にも反映される` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/AC106_S1_kinari.png` |
| AC-107 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC107_購入の取りやめとエラー時に未購入と標準の見た目が保たれる` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S10a_error_light.png` |
| AC-108 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC108_購入の復元で履歴の有無に応じた結果と文言が出る` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S10_normal_light.png`, `docs/verification/001-reading-session/evidence/S10a_normal_light.png` |
| AC-109 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC109_決済不可の端末では購入ボタンを出さず案内を出す` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S10a_denied_light.png` |
| AC-110 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC110_オフラインで商品を読めないときは案内を出し読書は妨げない` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S10a_offline_light.png`, `docs/verification/001-reading-session/evidence/S10_offline_light.png` |
| AC-111 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC111_購入が返金されると前面復帰時に標準の見た目へ戻る` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S1_normal_light.png`, `docs/verification/001-reading-session/evidence/S10_normal_light.png` |
| AC-112 | PASS | 2（ja・en） | 0 | `ShelfAndBookAcceptanceTests.swift::test_AC112_同梱の受賞一覧データが仕様書の表と全行一致する` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S7_normal_light.png`, `docs/verification/001-reading-session/evidence/S9_normal_light.png` |
| AC-113 | PASS | 2（ja・en） | 0 | `ShelfAndBookAcceptanceTests.swift::test_AC113_奥付を1枚撮って著者出版社レーベル出版年ISBNを補完し画像を残さない` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S7c_normal_light.png` |
| AC-114 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC114_読み始めるインテントでアプリを開かず読書とLiveActivityが始まる` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/W4_normal_light.png`, `docs/verification/001-reading-session/evidence/W5_normal_light.png`, `docs/verification/001-reading-session/evidence/W3_normal_light.png` |
| AC-115 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC115_どの状態から読み始めるインテントを動かしても二重に始まらない` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/W4_partial_light.png`, `docs/verification/001-reading-session/evidence/W5_partial_light.png` |
| AC-116 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC116_LiveActivityの終えるで動いた時刻で記録し場面に応じて画面を出す` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/W3_normal_light.png`, `docs/verification/001-reading-session/evidence/S3_normal_light.png` |
| AC-117 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC117_今の本がないときに読み始めるインテントはアプリを開いて空状態を見せる` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/W4_empty_light.png`, `docs/verification/001-reading-session/evidence/W5_empty_light.png`, `docs/verification/001-reading-session/evidence/S1_empty_light.png` |
| AC-118 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC118_LiveActivityオフ時の読み始めるインテントは読書を開始し前面可ならS2を出す` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/W4_denied_light.png`, `docs/verification/001-reading-session/evidence/S2_normal_light.png` |
| AC-119 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC119_読み始めるインテントで保存失敗時はエラーを返しLiveActivityを出さない` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/W4_error_light.png`, `docs/verification/001-reading-session/evidence/W5_error_light.png` |
| AC-120 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC120_隠す設定オンのとき読み始めるインテントのLiveActivityに書名を出さない` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/W3_partial_light.png`, `docs/verification/001-reading-session/evidence/AC34_W1_hidden.png` |
| AC-121 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC121_どこまで読んだインテントは認証なしでページだけ答え一行と書名を出さない` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/W5_normal_light.png` |
| AC-122 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC122_どこまで読んだインテントでページや今の本がないときの応答を検証する` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/W5_empty_light.png` |
| AC-123 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC123_隠す設定オンでもどこまで読んだインテントはページを答え書名と一行を出さない` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/W5_normal_light.png`, `docs/verification/001-reading-session/evidence/AC34_W1_hidden.png` |
| AC-124 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC124_続きを読むインテントはしおり画面を開き始まった読書にintent_openを付ける` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/W5_normal_light.png`, `docs/verification/001-reading-session/evidence/S1_normal_light.png` |
| AC-125 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC125_オフラインでも外からの3つのインテントとしおり保存がすべて動く` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/W4_normal_light.png`, `docs/verification/001-reading-session/evidence/W5_normal_light.png`, `docs/verification/001-reading-session/evidence/S4_result_light.png` |
| AC-126 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC126_AppShortcuts3種とControl1種の登録内容と言い方を検証する` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/W4_normal_light.png`, `docs/verification/001-reading-session/evidence/W5_normal_light.png`, `docs/verification/001-reading-session/evidence/W5_normal_en.png` |
| AC-127 | PASS | 2（ja・en） | 0 | `FinishAndRecommendationAcceptanceTests.swift::test_AC127_読み終えのふりかえり1行に晩数と合計時間と最長の晩が出てカードには載らない` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S9_finish_light.png`, `docs/verification/001-reading-session/evidence/AC84_finish_card.png` |
| AC-128 | PASS | 2（ja・en） | 0 | `FinishAndRecommendationAcceptanceTests.swift::test_AC128_ふりかえり1行の1晩のみの文言と同点最長晩の新しい日付選択を検証する` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S9_partial_light.png` |
| AC-129 | PASS | 2（ja・en） | 0 | `FinishAndRecommendationAcceptanceTests.swift::test_AC129_記録が0件の本を読み終えたときはふりかえり1行を出さない` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S9_empty_light.png` |
| AC-130 | PASS | 2（ja・en） | 0 | `WidgetAndActivityAcceptanceTests.swift::test_AC130_入口時刻前の読書開始で今夜の予約を取り消し終了時に予約を見直す` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/W3_normal_light.png`, `docs/verification/001-reading-session/evidence/S2_normal_light.png` |
| AC-131 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC131_読み始めるインテントでLiveActivity要求が失敗したらアプリを開いて読書を続ける` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/W4_error_light.png`, `docs/verification/001-reading-session/evidence/S2_normal_light.png` |
| AC-132 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC132_LiveActivityの終えるで保存失敗時は読書を消さずS2にエラーを出す` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S2_error_light.png`, `docs/verification/001-reading-session/evidence/explore_R5.png` |
| AC-133 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC133_どこまで読んだインテントで読込失敗時はエラー文言だけを返し書名やページを出さない` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/W5_error_light.png` |
| AC-134 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC134_読書中に続きを読むインテントを動かすと読書中の画面を出す` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/W5_partial_light.png`, `docs/verification/001-reading-session/evidence/S2_normal_light.png` |
| AC-135 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC135_今の本がないときに続きを読むインテントはしおり画面の空状態を出す` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/W5_empty_light.png`, `docs/verification/001-reading-session/evidence/S1_empty_light.png` |
| AC-136 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC136_4時をまたぎLiveActivityが8時間上限で消えても読書は続き全分数が記録される` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S2_normal_light.png`, `docs/verification/001-reading-session/evidence/S4_result_light.png` |
| AC-137 | PASS | 2（ja・en） | 0 | `RegistrationAcceptanceTests.swift::test_AC137_表紙写真とスクリーンショットから2タップで書名と著者を選んで登録できる` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S8b_normal_light.png` |
| AC-138 | PASS | 2（ja・en） | 0 | `RegistrationAcceptanceTests.swift::test_AC138_本棚の1枚の写真から複数の背表紙を選んで一括で積読に加え1件一致の書誌を補う` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S8d_normal_light.png` |
| AC-139 | PASS | 2（ja・en） | 0 | `RegistrationAcceptanceTests.swift::test_AC139_書名をあとでにして今すぐ読み始められ名無しの本は1冊に制限される` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S1_partial_light.png`, `docs/verification/001-reading-session/evidence/S2_partial_light.png`, `docs/verification/001-reading-session/evidence/W1_partial_light.png`, `docs/verification/001-reading-session/evidence/W3_partial_light.png` |
| AC-140 | PASS | 2（ja・en） | 0 | `RegistrationAcceptanceTests.swift::test_AC140_名無しの今の本に後からバーコードで書名と奥付を入れると記録を保って更新される` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S1_partial_light.png`, `docs/verification/001-reading-session/evidence/S8a_normal_light.png`, `docs/verification/001-reading-session/evidence/explore_R6.png` |
| AC-141 | PASS | 2（ja・en） | 0 | `BookmarkAcceptanceTests.swift::test_AC141_電子書籍の位置番号とパーセントのしおり保存と境界値を検証する` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/AC141_S4_location.png`, `docs/verification/001-reading-session/evidence/S3a_normal_light.png`, `docs/verification/001-reading-session/evidence/S3b_normal_light.png` |
| AC-142 | PASS | 2（ja・en） | 0 | `BookmarkAcceptanceTests.swift::test_AC142_カメラ拒否でもスクリーンショットから一行を選んで保存でき画像を残さない` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S3c_denied_light.png`, `docs/verification/001-reading-session/evidence/AC65_S3c_ocr.png` |
| AC-143 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC143_電子書籍の位置番号とパーセントに応じてどこまで読んだインテントが答える` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/W5_normal_light.png` |
| AC-144 | PASS | 2（ja・en） | 0 | `SettingsStoreIntentsAcceptanceTests.swift::test_AC144_電子書籍のしおり画面と読書中画面に専用案内が出てLiveActivityから終えられる` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/AC144_S2_ebook.png`, `docs/verification/001-reading-session/evidence/S1_partial_light.png` |
| AC-145 | PASS | 2（ja・en） | 0 | `FinishAndRecommendationAcceptanceTests.swift::test_AC145_今の本が0冊で積読があるときしおり画面に最大3冊出て1タップで今の本になる` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S1_empty_light.png` |
| AC-146 | PASS | 2（ja・en） | 0 | `FinishAndRecommendationAcceptanceTests.swift::test_AC146_読み終えた本の詳細画面にこの本のあとにが最大5冊出てその場で積読に加えられる` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/AC146_S7_after.png`, `docs/verification/001-reading-session/evidence/S7_normal_light.png` |
| AC-147 | PASS | 2（ja・en） | 0 | `FinishAndRecommendationAcceptanceTests.swift::test_AC147_端末内の重み付けでよく選ぶ理由の候補が既定の順より上に繰り上がる` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S9_finish_light.png` |
| AC-148 | PASS | 2（ja・en） | 0 | `FinishAndRecommendationAcceptanceTests.swift::test_AC148_共起テーブルから文学NDC9かつ10人以上の本だけを人数を出さずに推薦する` / コマンド 3 / 4（`ReadingAcceptanceTests` ja/en passed, 0 failures） / `docs/verification/001-reading-session/evidence/S9_finish_light.png` |
| AC-149 | PASS | 2（ja・en） | 0 | `PerformanceTests.swift::test_AC149_端末内書誌DBのISBN検索と書名検索の5回平均が300ミリ秒以内` / コマンド 5（`PerformanceTests` Perf 構成 passed, 0 failures） / `docs/verification/001-reading-session/evidence/S8a_normal_light.png`, `docs/verification/001-reading-session/evidence/S8c_normal_light.png` |

## 3. 状態ごとの結果
`docs/verification/001-reading-session/test-plan.md` 3章のすべての行の結果と証拠、および G4 実機確認への申し送りを示す。

| 状態 | 選んだもの（自動 / G4 の人 / 範囲外） | 結果 | 証拠のパス、または理由 |
|---|---|---|---|
| 初めて起動 | 自動 | PASS | `FirstLaunchTests.swift::test_AC1_初回起動で空のしおり画面が出て許可ダイアログが出ない`、`docs/verification/001-reading-session/evidence/S1_empty_light.png`、`S1_empty_dark.png`、`S1_empty_ax5.png`、`S1_empty_en.png` |
| データがある | 自動 | PASS | AC-3, AC-7, AC-13〜AC-64, AC-75〜AC-91, AC-93, AC-95〜AC-102, AC-104, AC-113〜AC-125, AC-127〜AC-136, AC-138, AC-140〜AC-148 の全テスト通過、`docs/verification/001-reading-session/evidence/S1_normal_light.png`、`S6_shelf_light.png`、`S7_book_light.png`、`S9_finish_light.png` |
| 前の版からの更新 | 範囲外 | 範囲外 | `001-reading-session` がアプリの最初の機能（v1.0 初回リリース）であり、前の版のタグ・旧スキーマが存在しないため |
| オフライン、サーバーエラー | 自動 | PASS | `test_AC6`、`test_AC9`、`test_AC62`、`test_AC110`、`test_AC125` 全通過、`docs/verification/001-reading-session/evidence/S10_offline_light.png`、`S10a_offline_light.png`、`S8a_partial_light.png`、`explore_R6.png` |
| 権限を断った | 自動 | PASS | `test_AC12`、`test_AC37`、`test_AC70`、`test_AC109`、`test_AC118`、`test_AC142` 全通過、`docs/verification/001-reading-session/evidence/S3_denied_light.png`、`S7_denied_light.png`、`S7c_denied_light.png`、`S8_denied_light.png`、`S10_denied_light.png`、`S10a_denied_light.png`、`W3_denied_light.png`、`W4_denied_light.png` |
| バックグラウンドから復帰 | 自動 | PASS | `test_AC40`、`test_AC52`、`test_AC97`、`test_AC98`、`test_AC111`、`test_AC130`、`test_AC136` 全通過、`docs/verification/001-reading-session/evidence/S2_normal_light.png`、`W3_normal_light.png`、`explore_R1.png` |
| 言語と地域（ja、en） | 自動 | PASS | コマンド 2-A/2-B、コマンド 3/4、コマンド 5 の `Japanese (ja)`・`English (en)` 全構成通過、`test_AC22`・`test_AC93`・`test_AC126`、および全 27 画面の `*_normal_en.png`（`docs/verification/001-reading-session/evidence/S1_normal_en.png`〜`W5_normal_en.png`） |
| 大きい文字、ダークモード | 自動 | PASS | 全 27 画面の `*_normal_dark.png` および `*_normal_ax5.png`（`docs/verification/001-reading-session/evidence/S1_normal_dark.png`、`S1_normal_ax5.png` ほか計 54 枚）、および `docs/verification/001-reading-session/evidence/design-checks.log` の `performAccessibilityAudit()` 監査ログ |
| 容量不足、割り込み | 自動 | PASS | `test_AC59`、`test_AC60`、`test_AC90`、`test_AC91`、`test_AC95`、`test_AC119`、`test_AC132`、`test_AC133` 全通過、`docs/verification/001-reading-session/evidence/S1_error_light.png`、`S2_error_light.png`、`S3a_error_light.png`、`S7_error_light.png`、`N_error_light.png`、`explore_R5.png` |
| 実機の物理センサー・ロック画面描画・StandBy・Siri 音声・Sandbox 決済・App プライバシーレポート（G4-1〜G4-22） | G4 の人 | G4 申し送り | シミュレーターでは物理的な机・ベッド・膝の上の伏せ検知やロック画面の実描画・StandBy 赤色単色表示・実機カメラ光学ピント・VoiceOver 実機読み上げ・Sandbox 決済シート・App プライバシーレポートが決まらないため、`test-plan.md` 7章および PRD 11章の `G4-1`〜`G4-22` を G4 で Takuma が Release ビルド実機にて確認する |

## 4. 揺れの確認
影響「大」の AC（R1〜R6・R10）を代表する 15 テストすべてに対して `-test-iterations 5 -run-tests-until-failure` を実行し、5回連続×15テスト＝75回すべて成功（落ちた回数 0）を確認した。

| テストの名前 | コマンド | 回数 | 落ちた回数 | 原因の型（待ち方、順番、時刻、外部サービス、後片付け） |
|---|---|---|---|---|
| `FirstLaunchTests/test_AC1_初回起動で空のしおり画面が出て許可ダイアログが出ない` | `xcodebuild test -project ios/ReadingApp.xcodeproj -scheme ReadingApp -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.0' -only-test-configuration "Japanese (ja)" -test-iterations 5 -run-tests-until-failure -only-testing:ReadingAcceptanceTests/FirstLaunchTests/test_AC1_初回起動で空のしおり画面が出て許可ダイアログが出ない` | 5 | 0 | なし（8.241s, 8.263s, 8.301s, 8.404s, 8.394s） |
| `RegistrationAcceptanceTests/test_AC3_バーコード連続読取で重複と非図書を除きCコードで文庫を補う` | 同上（`-only-testing:ReadingAcceptanceTests/RegistrationAcceptanceTests/test_AC3_バーコード連続読取で重複と非図書を除きCコードで文庫を補う`） | 5 | 0 | なし（16.248s, 16.685s, 16.550s, 16.443s, 16.329s） |
| `ReadingSessionAcceptanceTests/test_AC44_しおり画面で伏せて1秒たつと触覚が1回鳴り読み始める` | 同上（`-only-testing:ReadingAcceptanceTests/ReadingSessionAcceptanceTests/test_AC44_しおり画面で伏せて1秒たつと触覚が1回鳴り読み始める`） | 5 | 0 | なし（7.159s, 7.178s, 7.078s, 7.196s, 7.071s） |
| `ReadingSessionAcceptanceTests/test_AC53_読書中に強制終了しても再起動後に続きから数える` | 同上（`-only-testing:ReadingAcceptanceTests/ReadingSessionAcceptanceTests/test_AC53_読書中に強制終了しても再起動後に続きから数える`） | 5 | 0 | なし（13.648s, 13.733s, 13.629s, 13.561s, 13.704s） |
| `ReadingSessionAcceptanceTests/test_AC55_終える1タップで確認なしに500ミリ秒以内にしおり画面が出る` | 同上（`-only-testing:ReadingAcceptanceTests/ReadingSessionAcceptanceTests/test_AC55_終える1タップで確認なしに500ミリ秒以内にしおり画面が出る`） | 5 | 0 | なし（43.993s, 44.733s, 44.299s, 43.735s, 43.835s） |
| `ReadingSessionAcceptanceTests/test_AC60_終わりの保存失敗時は読書中を保ち再試行で合算保存される` | 同上（`-only-testing:ReadingAcceptanceTests/ReadingSessionAcceptanceTests/test_AC60_終わりの保存失敗時は読書中を保ち再試行で合算保存される`） | 5 | 0 | なし（12.246s, 12.304s, 12.171s, 12.202s, 12.211s） |
| `BookmarkAcceptanceTests/test_AC65_ページ写真OCRで一番左の列が初期選択され保存できる` | 同上（`-only-testing:ReadingAcceptanceTests/BookmarkAcceptanceTests/test_AC65_ページ写真OCRで一番左の列が初期選択され保存できる`） | 5 | 0 | なし（23.548s, 22.538s, 22.724s, 22.242s, 21.943s） |
| `BookmarkAcceptanceTests/test_AC69_撮影したページ画像と未選択列の文字を一切残さない` | 同上（`-only-testing:ReadingAcceptanceTests/BookmarkAcceptanceTests/test_AC69_撮影したページ画像と未選択列の文字を一切残さない`） | 5 | 0 | なし（22.529s, 22.238s, 22.088s, 22.389s, 22.196s） |
| `WidgetAndActivityAcceptanceTests/test_AC27_ロック画面ウィジェットに縦書きの一行とページが出る` | 同上（`-only-testing:ReadingAcceptanceTests/WidgetAndActivityAcceptanceTests/test_AC27_ロック画面ウィジェットに縦書きの一行とページが出る`） | 5 | 0 | なし（4.994s, 5.002s, 5.026s, 4.989s, 5.029s） |
| `WidgetAndActivityAcceptanceTests/test_AC34_隠す設定オンでウィジェットとLiveActivityから書名と一行を隠す` | 同上（`-only-testing:ReadingAcceptanceTests/WidgetAndActivityAcceptanceTests/test_AC34_隠す設定オンでウィジェットとLiveActivityから書名と一行を隠す`） | 5 | 0 | なし（8.881s, 7.340s, 7.285s, 7.238s, 7.189s） |
| `SettingsStoreIntentsAcceptanceTests/test_AC90_起動時の保存先読込失敗でエラーを出し再起動で元のデータが戻る` | 同上（`-only-testing:ReadingAcceptanceTests/SettingsStoreIntentsAcceptanceTests/test_AC90_起動時の保存先読込失敗でエラーを出し再起動で元のデータが戻る`） | 5 | 0 | なし（10.761s, 10.701s, 10.676s, 10.606s, 10.507s） |
| `SettingsStoreIntentsAcceptanceTests/test_AC103_登録から読了カード共有まで外部HTTP通信が0件である` | 同上（`-only-testing:ReadingAcceptanceTests/SettingsStoreIntentsAcceptanceTests/test_AC103_登録から読了カード共有まで外部HTTP通信が0件である`） | 5 | 0 | なし（28.441s, 27.457s, 27.202s, 27.291s, 27.287s） |
| `SettingsStoreIntentsAcceptanceTests/test_AC114_読み始めるインテントでアプリを開かず読書とLiveActivityが始まる` | 同上（`-only-testing:ReadingAcceptanceTests/SettingsStoreIntentsAcceptanceTests/test_AC114_読み始めるインテントでアプリを開かず読書とLiveActivityが始まる`） | 5 | 0 | なし（9.934s, 10.142s, 10.034s, 9.993s, 9.913s） |
| `SettingsStoreIntentsAcceptanceTests/test_AC116_LiveActivityの終えるで動いた時刻で記録し場面に応じて画面を出す` | 同上（`-only-testing:ReadingAcceptanceTests/SettingsStoreIntentsAcceptanceTests/test_AC116_LiveActivityの終えるで動いた時刻で記録し場面に応じて画面を出す`） | 5 | 0 | なし（21.197s, 21.119s, 21.152s, 21.220s, 21.418s） |
| `PerformanceTests/test_AC100_本3冊記録10件での起動から操作可能までの平均が1秒以内` | `xcodebuild test -project ios/ReadingApp.xcodeproj -scheme ReadingApp -configuration Perf -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.0' -only-test-configuration "Japanese (ja)" -test-iterations 5 -run-tests-until-failure -only-testing:ReadingAcceptanceTests/PerformanceTests/test_AC100_本3冊記録10件での起動から操作可能までの平均が1秒以内` | 5 | 0 | なし（34.622s, 32.105s, 31.978s, 32.099s, 31.871s） |


## 5. 受け入れテストの変更
- この機能のテストを最初に入れたコミット：`8984b29`（実装前のステップ10で reviewer 指摘を反映して確定したコミット：`3f26059`）
- コマンド：`git diff 3f26059..HEAD -- ios/AcceptanceTests`（および `git diff 8984b29..3f26059 -- ios/AcceptanceTests`）

| ファイル:行 | 何を変えたか | PRD の根拠（AC 番号と PRD の文） |
|---|---|---|
| `ios/AcceptanceTests/PerformanceTests.swift:54-60` | ステップ10のテスト計画レビュー修正時（`80f00e4`）に `XCTApplicationLaunchMetric(waitUntilResponsive: true)` を追加した際に消し忘れていた、XCUITest ランナーの再ビルド・再接続時間（約3秒）を含む手動の `Date()` ループを削除し、PRD 指定の `XCTApplicationLaunchMetric(waitUntilResponsive: true)` による計測に統一 | AC-100（`docs/prd/001-reading-session.md` 671行目：「Perf 構成でアプリを起動（`XCTApplicationLaunchMetric(waitUntilResponsive: true)` で5回測る）｜起動から「しおり」画面が操作できるようになるまでの5回の平均が 1.0秒（1,000ミリ秒）以内である」） |
| `ios/AcceptanceTests/Support/AcceptanceTestBase.swift:75-100` | `postDarwinNotification` で `yomuma.uitest.barcode` を連続送信する際、OS の Darwin 通知の合流（coalescing）により64ビット `notify_set_state` が次の通知で上書きされる競合を防ぐため、アプリ側が `state` を読み取って `0` に戻すのを待つ ACK ハンドシェイクを追加（テストの検証値・アサーションは一切変更なし） | AC-3（`docs/prd/001-reading-session.md` 494行目：「カメラを閉じずに次の順番でバーコードを続けて読み取らせる（H21）：① ISBN `9784062000024`（…）と2段目の Cコード `1920193006001`、② もう一度 `9784062000024`（同じ回の重複）、③ `9784101000015`（すでに本棚にある重複）、④ `9784003000038`（…）、⑤ `4901234567894`」）および `contracts/test-hooks.md` H21 |
| `ios/AcceptanceTests/*.swift`（`8984b29..3f26059`） | 実装に入る前のステップ10（受け入れテストレビュー r1/r2）において、reviewer 指摘に基づき PRD の条件漏れ・境界値・英語構成検証を補完 | AC-1〜AC-149（`docs/reviews/001-reading-session-step10-tests-r1.md`〜`r3.md` で PASS 確定済み） |

## 6. 検査の件数
`craft-verifier` 4章の 6 つの機械検査（grep / diff）の結果はすべて `0件` である。

| 検査 | コマンド | 件数 | 理由 |
|---|---|---|---|
| sleep で待つ | `grep -rnE 'sleep\(|usleep\|Thread\.sleep\|time\.sleep\|asyncio\.sleep' ios/AcceptanceTests` | 0件 | — |
| 飛ばす、失敗を許す | `grep -rnE 'XCTSkip\|XCTExpectFailure\|pytest\.mark\.skip\|skipif\|xfail\|pytest\.skip\|unittest\.skip' ios/AcceptanceTests` | 0件 | — |
| 再試行 | `grep -rniE 'retry\|rerun' ios/AcceptanceTests` | 0件 | — |
| 中を覗く import | `grep -rnE '@testable import' ios/AcceptanceTests` | 0件 | — |
| AC 番号の抜け（PRD にあってテストにない、その逆） | `diff <(grep -oE 'AC-[0-9]+' docs/prd/001-reading-session.md \| sed 's/AC-/AC/' \| sort -u) <(grep -rhoE 'AC[0-9]+_' ios/AcceptanceTests \| sed 's/_//' \| sort -u)` | 0件（PRD 149件 / テスト 149件 完全一致） | — |
| 表示の文字や並び順で探す | `grep -rnE '(buttons\|staticTexts\|textFields\|cells\|switches)\["\|element\(boundBy:' ios/AcceptanceTests` | 0件 | — |

## 7. アクセシビリティ監査
`design/001-reading-session.md` の全 27 画面・部品（`W-1`〜`W-5`、`S-1`〜`S-10a`、`N`）に対して `try app.performAccessibilityAudit(for: .all)` を実行した。詳細ログと `craft-design-reviewer` の5つの機械チェック結果は `docs/verification/001-reading-session/evidence/design-checks.log` に保存している。実機 VoiceOver での読み上げ確認は G4（`G4-13`）に申し送る。

| 画面 | テストの名前 | 結果 | 見つかった問題 |
|---|---|---|---|
| W-1（ロック画面の横長ウィジェット `accessoryRectangular`） | `FirstLaunchTests/test_G3_Part2A1_AuditAndLight` | PASS | 製品 UI 要素の hitRegion（44×44pt）・elementDetection・trait 違反 0件、WCAG コントラスト 51/51 組 4.5:1 以上達成（`-DUITEST_HOOKS` 専用の 1×1pt 不可視オーバーレイ要素 10 個に対する機械検知は製品コード外のテストフックのため見送り。詳細は `design-checks.log`） |
| W-2（ホーム画面・StandBy の小ウィジェット `systemSmall`） | `FirstLaunchTests/test_G3_Part2A1_AuditAndLight` | PASS | 製品 UI 要素の hitRegion（44×44pt）・elementDetection・trait 違反 0件、WCAG コントラスト 51/51 組 4.5:1 以上達成（`-DUITEST_HOOKS` 専用の 1×1pt 不可視オーバーレイ要素 10 個に対する機械検知は製品コード外のテストフックのため見送り。詳細は `design-checks.log`） |
| W-3（夜の入口・読書中の Live Activity） | `FirstLaunchTests/test_G3_Part2A1_AuditAndLight` | PASS | 製品 UI 要素の hitRegion（44×44pt）・elementDetection・trait 違反 0件、WCAG コントラスト 51/51 組 4.5:1 以上達成（`-DUITEST_HOOKS` 専用の 1×1pt 不可視オーバーレイ要素 10 個に対する機械検知は製品コード外のテストフックのため見送り。詳細は `design-checks.log`） |
| W-4（Control Center / Action Button の ControlWidgetButton） | `FirstLaunchTests/test_G3_Part2A1_AuditAndLight` | PASS | 製品 UI 要素の hitRegion（44×44pt）・elementDetection・trait 違反 0件、WCAG コントラスト 51/51 組 4.5:1 以上達成（`-DUITEST_HOOKS` 専用の 1×1pt 不可視オーバーレイ要素 10 個に対する機械検知は製品コード外のテストフックのため見送り。詳細は `design-checks.log`） |
| W-5（Siri・App Shortcuts 3種） | `FirstLaunchTests/test_G3_Part2A1_AuditAndLight` | PASS | 製品 UI 要素の hitRegion（44×44pt）・elementDetection・trait 違反 0件、WCAG コントラスト 51/51 組 4.5:1 以上達成（`-DUITEST_HOOKS` 専用の 1×1pt 不可視オーバーレイ要素 10 個に対する機械検知は製品コード外のテストフックのため見送り。詳細は `design-checks.log`） |
| S-1（しおりの画面） | `FirstLaunchTests/test_G3_Part2A1_AuditAndLight` | PASS | 製品 UI 要素の hitRegion（44×44pt）・elementDetection・trait 違反 0件、WCAG コントラスト 51/51 組 4.5:1 以上達成（`-DUITEST_HOOKS` 専用の 1×1pt 不可視オーバーレイ要素 10 個に対する機械検知は製品コード外のテストフックのため見送り。詳細は `design-checks.log`） |
| S-2（読書中の画面） | `FirstLaunchTests/test_G3_Part2A2_AuditAndLight` | PASS | 製品 UI 要素の hitRegion（44×44pt）・elementDetection・trait 違反 0件、WCAG コントラスト 51/51 組 4.5:1 以上達成（`-DUITEST_HOOKS` 専用の 1×1pt 不可視オーバーレイ要素 10 個に対する機械検知は製品コード外のテストフックのため見送り。詳細は `design-checks.log`） |
| S-3（しおりを挟む：5つの道の選択） | `FirstLaunchTests/test_G3_Part2A2_AuditAndLight` | PASS | 製品 UI 要素の hitRegion（44×44pt）・elementDetection・trait 違反 0件、WCAG コントラスト 51/51 組 4.5:1 以上達成（`-DUITEST_HOOKS` 専用の 1×1pt 不可視オーバーレイ要素 10 個に対する機械検知は製品コード外のテストフックのため見送り。詳細は `design-checks.log`） |
| S-3a（しおりを挟む：一行と場所の手入力） | `FirstLaunchTests/test_G3_Part2A2_AuditAndLight` | PASS | 製品 UI 要素の hitRegion（44×44pt）・elementDetection・trait 違反 0件、WCAG コントラスト 51/51 組 4.5:1 以上達成（`-DUITEST_HOOKS` 専用の 1×1pt 不可視オーバーレイ要素 10 個に対する機械検知は製品コード外のテストフックのため見送り。詳細は `design-checks.log`） |
| S-3b（しおりを挟む：場所だけの手入力） | `FirstLaunchTests/test_G3_Part2A2_AuditAndLight` | PASS | 製品 UI 要素の hitRegion（44×44pt）・elementDetection・trait 違反 0件、WCAG コントラスト 51/51 組 4.5:1 以上達成（`-DUITEST_HOOKS` 専用の 1×1pt 不可視オーバーレイ要素 10 個に対する機械検知は製品コード外のテストフックのため見送り。詳細は `design-checks.log`） |
| S-3c（しおりを挟む：ページ写真・スクショの縦書き列選択） | `FirstLaunchTests/test_G3_Part2A2_AuditAndLight` | PASS | 製品 UI 要素の hitRegion（44×44pt）・elementDetection・trait 違反 0件、WCAG コントラスト 51/51 組 4.5:1 以上達成（`-DUITEST_HOOKS` 専用の 1×1pt 不可視オーバーレイ要素 10 個に対する機械検知は製品コード外のテストフックのため見送り。詳細は `design-checks.log`） |
| S-4（読書の記録の結果画面） | `FirstLaunchTests/test_G3_Part2A2_AuditAndLight` | PASS | 製品 UI 要素の hitRegion（44×44pt）・elementDetection・trait 違反 0件、WCAG コントラスト 51/51 組 4.5:1 以上達成（`-DUITEST_HOOKS` 専用の 1×1pt 不可視オーバーレイ要素 10 個に対する機械検知は製品コード外のテストフックのため見送り。詳細は `design-checks.log`） |
| S-5（ロック画面へのウィジェット配置案内） | `FirstLaunchTests/test_G3_Part2A2_AuditAndLight` | PASS | 製品 UI 要素の hitRegion（44×44pt）・elementDetection・trait 違反 0件、WCAG コントラスト 51/51 組 4.5:1 以上達成（`-DUITEST_HOOKS` 専用の 1×1pt 不可視オーバーレイ要素 10 個に対する機械検知は製品コード外のテストフックのため見送り。詳細は `design-checks.log`） |
| S-6（本棚の画面） | `FirstLaunchTests/test_G3_Part2A1_AuditAndLight` | PASS | 製品 UI 要素の hitRegion（44×44pt）・elementDetection・trait 違反 0件、WCAG コントラスト 51/51 組 4.5:1 以上達成（`-DUITEST_HOOKS` 専用の 1×1pt 不可視オーバーレイ要素 10 個に対する機械検知は製品コード外のテストフックのため見送り。詳細は `design-checks.log`） |
| S-7（本の詳細画面：奥付・記録・この本のあとに） | `FirstLaunchTests/test_G3_Part2A1_AuditAndLight` | PASS | 製品 UI 要素の hitRegion（44×44pt）・elementDetection・trait 違反 0件、WCAG コントラスト 51/51 組 4.5:1 以上達成（`-DUITEST_HOOKS` 専用の 1×1pt 不可視オーバーレイ要素 10 個に対する機械検知は製品コード外のテストフックのため見送り。詳細は `design-checks.log`） |
| S-7a（本の奥付の手入力編集シート） | `FirstLaunchTests/test_G3_Part2A1_AuditAndLight` | PASS | 製品 UI 要素の hitRegion（44×44pt）・elementDetection・trait 違反 0件、WCAG コントラスト 51/51 組 4.5:1 以上達成（`-DUITEST_HOOKS` 専用の 1×1pt 不可視オーバーレイ要素 10 個に対する機械検知は製品コード外のテストフックのため見送り。詳細は `design-checks.log`） |
| S-7b（記録の分数編集・削除シート） | `FirstLaunchTests/test_G3_Part2A1_AuditAndLight` | PASS | 製品 UI 要素の hitRegion（44×44pt）・elementDetection・trait 違反 0件、WCAG コントラスト 51/51 組 4.5:1 以上達成（`-DUITEST_HOOKS` 専用の 1×1pt 不可視オーバーレイ要素 10 個に対する機械検知は製品コード外のテストフックのため見送り。詳細は `design-checks.log`） |
| S-7c（奥付のカメラ・写真読み取りシート） | `FirstLaunchTests/test_G3_Part2A1_AuditAndLight` | PASS | 製品 UI 要素の hitRegion（44×44pt）・elementDetection・trait 違反 0件、WCAG コントラスト 51/51 組 4.5:1 以上達成（`-DUITEST_HOOKS` 専用の 1×1pt 不可視オーバーレイ要素 10 個に対する機械検知は製品コード外のテストフックのため見送り。詳細は `design-checks.log`） |
| S-8（本を加える：登録の道の選択シート） | `FirstLaunchTests/test_G3_Part2A1_AuditAndLight` | PASS | 製品 UI 要素の hitRegion（44×44pt）・elementDetection・trait 違反 0件、WCAG コントラスト 51/51 組 4.5:1 以上達成（`-DUITEST_HOOKS` 専用の 1×1pt 不可視オーバーレイ要素 10 個に対する機械検知は製品コード外のテストフックのため見送り。詳細は `design-checks.log`） |
| S-8a（バーコード連続読み取り画面） | `FirstLaunchTests/test_G3_Part2A1_AuditAndLight` | PASS | 製品 UI 要素の hitRegion（44×44pt）・elementDetection・trait 違反 0件、WCAG コントラスト 51/51 組 4.5:1 以上達成（`-DUITEST_HOOKS` 専用の 1×1pt 不可視オーバーレイ要素 10 個に対する機械検知は製品コード外のテストフックのため見送り。詳細は `design-checks.log`） |
| S-8b（表紙・背表紙・スクショからの2タップ書名・著者選択） | `FirstLaunchTests/test_G3_Part2A2_AuditAndLight` | PASS | 製品 UI 要素の hitRegion（44×44pt）・elementDetection・trait 違反 0件、WCAG コントラスト 51/51 組 4.5:1 以上達成（`-DUITEST_HOOKS` 専用の 1×1pt 不可視オーバーレイ要素 10 個に対する機械検知は製品コード外のテストフックのため見送り。詳細は `design-checks.log`） |
| S-8c（書名・著者の手入力と端末内書誌 DB 検索） | `FirstLaunchTests/test_G3_Part2A2_AuditAndLight` | PASS | 製品 UI 要素の hitRegion（44×44pt）・elementDetection・trait 違反 0件、WCAG コントラスト 51/51 組 4.5:1 以上達成（`-DUITEST_HOOKS` 専用の 1×1pt 不可視オーバーレイ要素 10 個に対する機械検知は製品コード外のテストフックのため見送り。詳細は `design-checks.log`） |
| S-8d（本棚・積読の複数背表紙一括選択） | `FirstLaunchTests/test_G3_Part2A2_AuditAndLight` | PASS | 製品 UI 要素の hitRegion（44×44pt）・elementDetection・trait 違反 0件、WCAG コントラスト 51/51 組 4.5:1 以上達成（`-DUITEST_HOOKS` 専用の 1×1pt 不可視オーバーレイ要素 10 個に対する機械検知は製品コード外のテストフックのため見送り。詳細は `design-checks.log`） |
| S-9（読み終えた画面：ふりかえり・奥付・カード共有・次の1冊） | `FirstLaunchTests/test_G3_Part2A2_AuditAndLight` | PASS | 製品 UI 要素の hitRegion（44×44pt）・elementDetection・trait 違反 0件、WCAG コントラスト 51/51 組 4.5:1 以上達成（`-DUITEST_HOOKS` 専用の 1×1pt 不可視オーバーレイ要素 10 個に対する機械検知は製品コード外のテストフックのため見送り。詳細は `design-checks.log`） |
| S-10（設定画面） | `FirstLaunchTests/test_G3_Part2A2_AuditAndLight` | PASS | 製品 UI 要素の hitRegion（44×44pt）・elementDetection・trait 違反 0件、WCAG コントラスト 51/51 組 4.5:1 以上達成（`-DUITEST_HOOKS` 専用の 1×1pt 不可視オーバーレイ要素 10 個に対する機械検知は製品コード外のテストフックのため見送り。詳細は `design-checks.log`） |
| S-10a（見た目の選択と「よむま＋」見本・購入シート） | `FirstLaunchTests/test_G3_Part2A2_AuditAndLight` | PASS | 製品 UI 要素の hitRegion（44×44pt）・elementDetection・trait 違反 0件、WCAG コントラスト 51/51 組 4.5:1 以上達成（`-DUITEST_HOOKS` 専用の 1×1pt 不可視オーバーレイ要素 10 個に対する機械検知は製品コード外のテストフックのため見送り。詳細は `design-checks.log`） |
| 部品 N（画面上部の知らせバナー） | `FirstLaunchTests/test_G3_Part2A1_AuditAndLight` | PASS | 製品 UI 要素の hitRegion（44×44pt）・elementDetection・trait 違反 0件、WCAG コントラスト 51/51 組 4.5:1 以上達成（`-DUITEST_HOOKS` 専用の 1×1pt 不可視オーバーレイ要素 10 個に対する機械検知は製品コード外のテストフックのため見送り。詳細は `design-checks.log`） |

## 8. 探索セッション
`test-plan.md` 6章の影響「大」のリスク R1〜R6 ごとに探索セッションを実施した。詳細な実行ログと `app.debugDescription` は `docs/verification/001-reading-session/evidence/design-checks.log` に記録している。

### セッション 1（R1：読書時間と晩の計算）
- チャーター：読書時間と晩の計算（S-1〜S-4、S-7、S-9）を、4:00 前後の連続読書・バックグラウンド移行・強制終了・タイムゾーン変更・記録編集と削除を組み合わせる操作で探り、合計分数・何晩・ふりかえり1行の食い違いを見つける
- 区切り（予定と実際。時間か操作の数）：予定：30分または40操作 ／ 実際：18操作（約10分）
- 試したこと：`2026-10-17` の晩の記録（20分）がある状態で、`2026-10-18T03:50:00+09:00`（`Asia/Tokyo`）に `bookmark.start` で読み始め、アプリを強制終了して `2026-10-18T04:15:00+09:00` かつタイムゾーンを `America/Los_Angeles` に変更して再起動し、`reading.end` → `mark.later` → `result.close` → `bookmark.finish` で S-9 の `finish.reflection` を確認した。
- 見つけた不具合（11章の番号）：なし（`2026-10-18T03:50:00+09:00` 開始の25分が開始時点のタイムゾーン `Asia/Tokyo` の4:00境目で `2026-10-17` の晩に帰属し、既存の20分と合算されて「1晩、45分で読み終えました。」と正確に表示された）
- 疑問：なし
- 次に試すこと：G4 実機確認（G4-8・G4-9）にて、実機の画面ロックおよび電源オフ再起動をまたぐ計測を確認する。
- 使い捨てのテスト：消した（証拠画像：`docs/verification/001-reading-session/evidence/explore_R1.png`）

### セッション 2（R2：伏せて始める動作）
- チャーター：伏せて始める動作（S-1、S-2、各シート）を、0.9秒/1.0秒の連続反転・シート開閉直後の伏せ・電子書籍モード・設定オンオフ切り替えで探り、誤開始や `flipMonitoring` の切り忘れを見つける
- 区切り（予定と実際。時間か操作の数）：予定：30分または40操作 ／ 実際：20操作（約10分）
- 試したこと：S-1 で `faceDown` 0.9秒→`portrait` に戻して2秒待機し `state == idle` を確認。続いて `bookmark.setMark` で S-3 シートを開いた状態で `faceDown` 1.5秒→`portrait` に戻し `state == idle` を確認。シートを `mark.cancel` で閉じた直後に `faceDown` 1.0秒→`portrait` で `state == reading` に遷移することを確認した。
- 見つけた不具合（11章の番号）：なし（0.9秒未満およびシート表示中は誤発火せず、シートを閉じて S-1 に戻ると `flipMonitoring` が即座に再開された）
- 疑問：なし
- 次に試すこと：G4 実機確認（G4-7・G4-14）にて、机・ベッドの布団・膝の上での物理的な伏せ動作と3晩の誤開始0回を確認する。
- 使い捨てのテスト：消した（証拠画像：`docs/verification/001-reading-session/evidence/explore_R2.png`）

### セッション 3（R3：しおり保存と OCR）
- チャーター：しおり保存と OCR（S-3、S-3a〜S-3c、S-7c、S-8b、S-8d）を、OCR 待ち中の別導線遷移・カメラ拒否時のスクショ選択・単位（ページ/位置/％）切り替え・キャンセル連打で探り、入力値の消失や一時画像ファイルの残存を見つける
- 区切り（予定と実際。時間か操作の数）：予定：30分または40操作 ／ 実際：16操作（約10分）
- 試したこと：`-uitest-ocr` で `hold: true` を注入し、S-3c の OCR 処理中画面から `mark.manual` を押して S-3a に移り「手入力した一行」を入力した後に `releaseOCR()` で遅延 OCR 結果を返却させた。さらに `mark.save` 保存後に `hook.mediaAudit` で保存領域と App Group の画像ファイル数を確認した。
- 見つけた不具合（11章の番号）：なし（後から返った OCR 結果で手入力中の文字列が上書きされず、`savedImageFileCount == 0` で一時画像ファイルも一切残らなかった）
- 疑問：なし
- 次に試すこと：G4 実機確認（G4-10・G4-12）にて、実機カメラでの文庫本5枚の撮影速度と縦書き認識を確認する。
- 使い捨てのテスト：消した（証拠画像：`docs/verification/001-reading-session/evidence/explore_R3.png`）

### セッション 4（R4：ウィジェットと Live Activity）
- チャーター：ウィジェットと Live Activity（W-1〜W-3、S-1、S-10）を、25字/26字/禁則文字・欧文混在・`hideOnWidgets` 切り替え・夜の入口時刻変更で探り、文字欠けやロック画面への書名・一行の漏洩を見つける
- 区切り（予定と実際。時間か操作の数）：予定：30分または40操作 ／ 実際：15操作（約8分）
- 試したこと：W-1（`172x76`）と W-2（`170x170`）を有効にした状態で S-10 を開き、`settings.hideOnWidgets` をオンに切り替えて S-1 に戻り、`hook.widget` のスナップショット JSON と W-1/W-2 の表示内容を確認した。
- 見つけた不具合（11章の番号）：なし（`hideOnWidgets` をオンにした瞬間に `hook.widget` から書名「こころ」と一行が完全に消え、「しおり」とページ番号のみになった）
- 疑問：なし
- 次に試すこと：G4 実機確認（G4-1・G4-2・G4-3・G4-6）にて、ロック画面の vibrant 表示と StandBy の赤色単色表示を実機で確認する。
- 使い捨てのテスト：消した（証拠画像：`docs/verification/001-reading-session/evidence/explore_R4.png`）

### セッション 5（R5：App Intents と Live Activity の連携）
- チャーター：App Intents（`StartReadingIntent`、`EndReadingFromActivityIntent`、`WhereStoppedIntent`、`ContinueReadingIntent`）を、アプリ前面中・背面中・予約 Live Activity 表示中・保存失敗注入下で交互に呼び出して探り、二重セッションや状態の不整合を見つける
- 区切り（予定と実際。時間か操作の数）：予定：30分または40操作 ／ 実際：18操作（約10分）
- 試したこと：`failSave: "session.end:1"` を注入した状態で `WhereStoppedIntent` → `StartReadingIntent` → 600秒経過 → `EndReadingFromActivityIntent` を実行。保存失敗時に `state == reading` が維持され S-2 に `session.save.error` が出ることを確認し、さらに300秒経過後に `reading.end` で再試行して保存された記録の分数を確認した。
- 見つけた不具合（11章の番号）：なし（保存失敗で開始時刻や読書中状態が消えず、再試行により合計15分の記録が欠損なく保存された）
- 疑問：なし
- 次に試すこと：G4 実機確認（G4-21・G4-22）にて、ロック中の実機からアクションボタンと Siri 音声でインテントを起動して確認する。
- 使い捨てのテスト：消した（証拠画像：`docs/verification/001-reading-session/evidence/explore_R5.png`）

### セッション 6（R6：本と記録の永続化と外部通信0件）
- チャーター：本と記録の永続化（S-1、S-6〜S-10）を、`register.later`（名無しの今の本）からの書名後付け・本の削除・H7 保存失敗後の再試行・機内モード切り替えで探り、データ破損や外部通信の発生を見つける
- 区切り（予定と実際。時間か操作の数）：予定：30分または40操作 ／ 実際：20操作（約10分）
- 試したこと：オフライン（`-uitest-offline`）かつ `failSave: "book.update:1"` の状態で、`bookmark.addBook` → `register.later` で名無しの今の本を作成して10分間の読書を記録。その後 S-1 の `bookmark.setBookTitle` からバーコード `9784101000015`（「こころ」）を読み取り、1回目の `scan.addToShelf` 失敗後に2回目の `scan.addToShelf` で保存し、`hook.outbound` の外部 HTTP 通信件数を確認した。
- 見つけた不具合（11章の番号）：なし（1回目の更新失敗後も読み取ったバーコード行が消えず、2回目のタップで既存の10分の記録を保ったまま「こころ」に更新され、外部 HTTP 通信は `0件` だった）
- 疑問：なし
- 次に試すこと：G4 実機確認（G4-17・G4-20）にて、iCloud バックアップ復元と iOS の App プライバシーレポート（ネットワーク活動0件）を実機で確認する。
- 使い捨てのテスト：消した（証拠画像：`docs/verification/001-reading-session/evidence/explore_R6.png`）

## 9. スクリーンショットとログ
置き場所：`docs/verification/001-reading-session/evidence/`。以下の表に記載した全 249 ファイル（スクリーンショット 247 枚 + ログ 2 件）がすべて実在することを `ls` で確認済みである。

| ファイル | 画面と状態 | 見た目（ライト / ダーク / AX5 / 英語） | 対応する AC |
|---|---|---|---|
| `docs/verification/001-reading-session/evidence/AC105_S10a_preview.png` | `test-plan.md` 7章 指定証拠（S10a_preview） | ライト | AC-105 |
| `docs/verification/001-reading-session/evidence/AC106_S1_kinari.png` | `test-plan.md` 7章 指定証拠（S1_kinari） | ライト | AC-106 |
| `docs/verification/001-reading-session/evidence/AC141_S4_location.png` | `test-plan.md` 7章 指定証拠（S4_location） | ライト | AC-141 |
| `docs/verification/001-reading-session/evidence/AC144_S2_ebook.png` | `test-plan.md` 7章 指定証拠（S2_ebook） | ライト | AC-144 |
| `docs/verification/001-reading-session/evidence/AC146_S7_after.png` | `test-plan.md` 7章 指定証拠（S7_after） | ライト | AC-146 |
| `docs/verification/001-reading-session/evidence/AC27_W1_153x68.png` | `test-plan.md` 7章 指定証拠（W1_153x68） | ライト | AC-27 |
| `docs/verification/001-reading-session/evidence/AC27_W1_172x76.png` | `test-plan.md` 7章 指定証拠（W1_172x76） | ライト | AC-27 |
| `docs/verification/001-reading-session/evidence/AC28_W1_kinsoku.png` | `test-plan.md` 7章 指定証拠（W1_kinsoku） | ライト | AC-28 |
| `docs/verification/001-reading-session/evidence/AC29_W1_truncated.png` | `test-plan.md` 7章 指定証拠（W1_truncated） | ライト | AC-29 |
| `docs/verification/001-reading-session/evidence/AC34_S1_visible.png` | `test-plan.md` 7章 指定証拠（S1_visible） | ライト | AC-34 |
| `docs/verification/001-reading-session/evidence/AC34_W1_hidden.png` | `test-plan.md` 7章 指定証拠（W1_hidden） | ライト | AC-34 |
| `docs/verification/001-reading-session/evidence/AC35_W2_148x148.png` | `test-plan.md` 7章 指定証拠（W2_148x148） | ライト | AC-35 |
| `docs/verification/001-reading-session/evidence/AC35_W2_170x170.png` | `test-plan.md` 7章 指定証拠（W2_170x170） | ライト | AC-35 |
| `docs/verification/001-reading-session/evidence/AC65_S3c_ocr.png` | `test-plan.md` 7章 指定証拠（S3c_ocr） | ライト | AC-65 |
| `docs/verification/001-reading-session/evidence/AC84_finish_card.png` | `test-plan.md` 7章 指定証拠（finish_card） | ライト | AC-84 |
| `docs/verification/001-reading-session/evidence/AC93_S10_dataSources.png` | `test-plan.md` 7章 指定証拠（S10_dataSources） | ライト | AC-93 |
| `docs/verification/001-reading-session/evidence/N_error_light.png` | 画面 N・状態 `error` | ライト | AC-3, AC-56〜AC-60, AC-91 |
| `docs/verification/001-reading-session/evidence/N_normal_ax5.png` | 画面 N・状態 `normal` | AX5 | AC-3, AC-56〜AC-60, AC-91 |
| `docs/verification/001-reading-session/evidence/N_normal_dark.png` | 画面 N・状態 `normal` | ダーク | AC-3, AC-56〜AC-60, AC-91 |
| `docs/verification/001-reading-session/evidence/N_normal_en.png` | 画面 N・状態 `normal` | 英語 | AC-3, AC-56〜AC-60, AC-91 |
| `docs/verification/001-reading-session/evidence/N_normal_light.png` | 画面 N・状態 `normal` | ライト | AC-3, AC-56〜AC-60, AC-91 |
| `docs/verification/001-reading-session/evidence/S10_denied_light.png` | 画面 S10・状態 `denied` | ライト | AC-34, AC-37, AC-38, AC-49, AC-51, AC-88, AC-91, AC-93, AC-108, AC-110, AC-111 |
| `docs/verification/001-reading-session/evidence/S10_error_light.png` | 画面 S10・状態 `error` | ライト | AC-34, AC-37, AC-38, AC-49, AC-51, AC-88, AC-91, AC-93, AC-108, AC-110, AC-111 |
| `docs/verification/001-reading-session/evidence/S10_loading_light.png` | 画面 S10・状態 `loading` | ライト | AC-34, AC-37, AC-38, AC-49, AC-51, AC-88, AC-91, AC-93, AC-108, AC-110, AC-111 |
| `docs/verification/001-reading-session/evidence/S10_normal_ax5.png` | 画面 S10・状態 `normal` | AX5 | AC-34, AC-37, AC-38, AC-49, AC-51, AC-88, AC-91, AC-93, AC-108, AC-110, AC-111 |
| `docs/verification/001-reading-session/evidence/S10_normal_dark.png` | 画面 S10・状態 `normal` | ダーク | AC-34, AC-37, AC-38, AC-49, AC-51, AC-88, AC-91, AC-93, AC-108, AC-110, AC-111 |
| `docs/verification/001-reading-session/evidence/S10_normal_en.png` | 画面 S10・状態 `normal` | 英語 | AC-34, AC-37, AC-38, AC-49, AC-51, AC-88, AC-91, AC-93, AC-108, AC-110, AC-111 |
| `docs/verification/001-reading-session/evidence/S10_normal_light.png` | 画面 S10・状態 `normal` | ライト | AC-34, AC-37, AC-38, AC-49, AC-51, AC-88, AC-91, AC-93, AC-108, AC-110, AC-111 |
| `docs/verification/001-reading-session/evidence/S10_offline_light.png` | 画面 S10・状態 `offline` | ライト | AC-34, AC-37, AC-38, AC-49, AC-51, AC-88, AC-91, AC-93, AC-108, AC-110, AC-111 |
| `docs/verification/001-reading-session/evidence/S10_partial_light.png` | 画面 S10・状態 `partial` | ライト | AC-34, AC-37, AC-38, AC-49, AC-51, AC-88, AC-91, AC-93, AC-108, AC-110, AC-111 |
| `docs/verification/001-reading-session/evidence/S10_settings_light.png` | 画面 S10・状態 `settings` | ライト | AC-34, AC-37, AC-38, AC-49, AC-51, AC-88, AC-91, AC-93, AC-108, AC-110, AC-111 |
| `docs/verification/001-reading-session/evidence/S10a_denied_light.png` | 画面 S10a・状態 `denied` | ライト | AC-105〜AC-111 |
| `docs/verification/001-reading-session/evidence/S10a_error_light.png` | 画面 S10a・状態 `error` | ライト | AC-105〜AC-111 |
| `docs/verification/001-reading-session/evidence/S10a_loading_light.png` | 画面 S10a・状態 `loading` | ライト | AC-105〜AC-111 |
| `docs/verification/001-reading-session/evidence/S10a_normal_ax5.png` | 画面 S10a・状態 `normal` | AX5 | AC-105〜AC-111 |
| `docs/verification/001-reading-session/evidence/S10a_normal_dark.png` | 画面 S10a・状態 `normal` | ダーク | AC-105〜AC-111 |
| `docs/verification/001-reading-session/evidence/S10a_normal_en.png` | 画面 S10a・状態 `normal` | 英語 | AC-105〜AC-111 |
| `docs/verification/001-reading-session/evidence/S10a_normal_light.png` | 画面 S10a・状態 `normal` | ライト | AC-105〜AC-111 |
| `docs/verification/001-reading-session/evidence/S10a_offline_light.png` | 画面 S10a・状態 `offline` | ライト | AC-105〜AC-111 |
| `docs/verification/001-reading-session/evidence/S10a_partial_light.png` | 画面 S10a・状態 `partial` | ライト | AC-105〜AC-111 |
| `docs/verification/001-reading-session/evidence/S1_empty_ax5.png` | 画面 S1・状態 `empty` | AX5 | AC-1, AC-16, AC-39, AC-42, AC-44〜AC-51, AC-56, AC-58, AC-59, AC-86, AC-90, AC-100, AC-139, AC-140, AC-144, AC-145 |
| `docs/verification/001-reading-session/evidence/S1_empty_dark.png` | 画面 S1・状態 `empty` | ダーク | AC-1, AC-16, AC-39, AC-42, AC-44〜AC-51, AC-56, AC-58, AC-59, AC-86, AC-90, AC-100, AC-139, AC-140, AC-144, AC-145 |
| `docs/verification/001-reading-session/evidence/S1_empty_en.png` | 画面 S1・状態 `empty` | 英語 | AC-1, AC-16, AC-39, AC-42, AC-44〜AC-51, AC-56, AC-58, AC-59, AC-86, AC-90, AC-100, AC-139, AC-140, AC-144, AC-145 |
| `docs/verification/001-reading-session/evidence/S1_empty_light.png` | 画面 S1・状態 `empty` | ライト | AC-1, AC-16, AC-39, AC-42, AC-44〜AC-51, AC-56, AC-58, AC-59, AC-86, AC-90, AC-100, AC-139, AC-140, AC-144, AC-145 |
| `docs/verification/001-reading-session/evidence/S1_error_light.png` | 画面 S1・状態 `error` | ライト | AC-1, AC-16, AC-39, AC-42, AC-44〜AC-51, AC-56, AC-58, AC-59, AC-86, AC-90, AC-100, AC-139, AC-140, AC-144, AC-145 |
| `docs/verification/001-reading-session/evidence/S1_loading_light.png` | 画面 S1・状態 `loading` | ライト | AC-1, AC-16, AC-39, AC-42, AC-44〜AC-51, AC-56, AC-58, AC-59, AC-86, AC-90, AC-100, AC-139, AC-140, AC-144, AC-145 |
| `docs/verification/001-reading-session/evidence/S1_normal_ax5.png` | 画面 S1・状態 `normal` | AX5 | AC-1, AC-16, AC-39, AC-42, AC-44〜AC-51, AC-56, AC-58, AC-59, AC-86, AC-90, AC-100, AC-139, AC-140, AC-144, AC-145 |
| `docs/verification/001-reading-session/evidence/S1_normal_dark.png` | 画面 S1・状態 `normal` | ダーク | AC-1, AC-16, AC-39, AC-42, AC-44〜AC-51, AC-56, AC-58, AC-59, AC-86, AC-90, AC-100, AC-139, AC-140, AC-144, AC-145 |
| `docs/verification/001-reading-session/evidence/S1_normal_en.png` | 画面 S1・状態 `normal` | 英語 | AC-1, AC-16, AC-39, AC-42, AC-44〜AC-51, AC-56, AC-58, AC-59, AC-86, AC-90, AC-100, AC-139, AC-140, AC-144, AC-145 |
| `docs/verification/001-reading-session/evidence/S1_normal_light.png` | 画面 S1・状態 `normal` | ライト | AC-1, AC-16, AC-39, AC-42, AC-44〜AC-51, AC-56, AC-58, AC-59, AC-86, AC-90, AC-100, AC-139, AC-140, AC-144, AC-145 |
| `docs/verification/001-reading-session/evidence/S1_partial_light.png` | 画面 S1・状態 `partial` | ライト | AC-1, AC-16, AC-39, AC-42, AC-44〜AC-51, AC-56, AC-58, AC-59, AC-86, AC-90, AC-100, AC-139, AC-140, AC-144, AC-145 |
| `docs/verification/001-reading-session/evidence/S2_error_light.png` | 画面 S2・状態 `error` | ライト | AC-43, AC-47, AC-48, AC-52〜AC-55, AC-60, AC-132, AC-134, AC-136, AC-144 |
| `docs/verification/001-reading-session/evidence/S2_normal_ax5.png` | 画面 S2・状態 `normal` | AX5 | AC-43, AC-47, AC-48, AC-52〜AC-55, AC-60, AC-132, AC-134, AC-136, AC-144 |
| `docs/verification/001-reading-session/evidence/S2_normal_dark.png` | 画面 S2・状態 `normal` | ダーク | AC-43, AC-47, AC-48, AC-52〜AC-55, AC-60, AC-132, AC-134, AC-136, AC-144 |
| `docs/verification/001-reading-session/evidence/S2_normal_en.png` | 画面 S2・状態 `normal` | 英語 | AC-43, AC-47, AC-48, AC-52〜AC-55, AC-60, AC-132, AC-134, AC-136, AC-144 |
| `docs/verification/001-reading-session/evidence/S2_normal_light.png` | 画面 S2・状態 `normal` | ライト | AC-43, AC-47, AC-48, AC-52〜AC-55, AC-60, AC-132, AC-134, AC-136, AC-144 |
| `docs/verification/001-reading-session/evidence/S2_partial_light.png` | 画面 S2・状態 `partial` | ライト | AC-43, AC-47, AC-48, AC-52〜AC-55, AC-60, AC-132, AC-134, AC-136, AC-144 |
| `docs/verification/001-reading-session/evidence/S2_reading_ax5.png` | 画面 S2・状態 `reading` | AX5 | AC-43, AC-47, AC-48, AC-52〜AC-55, AC-60, AC-132, AC-134, AC-136, AC-144 |
| `docs/verification/001-reading-session/evidence/S2_reading_dark.png` | 画面 S2・状態 `reading` | ダーク | AC-43, AC-47, AC-48, AC-52〜AC-55, AC-60, AC-132, AC-134, AC-136, AC-144 |
| `docs/verification/001-reading-session/evidence/S2_reading_en.png` | 画面 S2・状態 `reading` | 英語 | AC-43, AC-47, AC-48, AC-52〜AC-55, AC-60, AC-132, AC-134, AC-136, AC-144 |
| `docs/verification/001-reading-session/evidence/S2_reading_light.png` | 画面 S2・状態 `reading` | ライト | AC-43, AC-47, AC-48, AC-52〜AC-55, AC-60, AC-132, AC-134, AC-136, AC-144 |
| `docs/verification/001-reading-session/evidence/S3_choices_light.png` | 画面 S3・状態 `choices` | ライト | AC-55, AC-63, AC-64, AC-70 |
| `docs/verification/001-reading-session/evidence/S3_denied_light.png` | 画面 S3・状態 `denied` | ライト | AC-55, AC-63, AC-64, AC-70 |
| `docs/verification/001-reading-session/evidence/S3_empty_light.png` | 画面 S3・状態 `empty` | ライト | AC-55, AC-63, AC-64, AC-70 |
| `docs/verification/001-reading-session/evidence/S3_normal_ax5.png` | 画面 S3・状態 `normal` | AX5 | AC-55, AC-63, AC-64, AC-70 |
| `docs/verification/001-reading-session/evidence/S3_normal_dark.png` | 画面 S3・状態 `normal` | ダーク | AC-55, AC-63, AC-64, AC-70 |
| `docs/verification/001-reading-session/evidence/S3_normal_en.png` | 画面 S3・状態 `normal` | 英語 | AC-55, AC-63, AC-64, AC-70 |
| `docs/verification/001-reading-session/evidence/S3_normal_light.png` | 画面 S3・状態 `normal` | ライト | AC-55, AC-63, AC-64, AC-70 |
| `docs/verification/001-reading-session/evidence/S3_partial_light.png` | 画面 S3・状態 `partial` | ライト | AC-55, AC-63, AC-64, AC-70 |
| `docs/verification/001-reading-session/evidence/S3a_empty_light.png` | 画面 S3a・状態 `empty` | ライト | AC-71, AC-72, AC-94, AC-95, AC-141 |
| `docs/verification/001-reading-session/evidence/S3a_error_light.png` | 画面 S3a・状態 `error` | ライト | AC-71, AC-72, AC-94, AC-95, AC-141 |
| `docs/verification/001-reading-session/evidence/S3a_loading_light.png` | 画面 S3a・状態 `loading` | ライト | AC-71, AC-72, AC-94, AC-95, AC-141 |
| `docs/verification/001-reading-session/evidence/S3a_normal_ax5.png` | 画面 S3a・状態 `normal` | AX5 | AC-71, AC-72, AC-94, AC-95, AC-141 |
| `docs/verification/001-reading-session/evidence/S3a_normal_dark.png` | 画面 S3a・状態 `normal` | ダーク | AC-71, AC-72, AC-94, AC-95, AC-141 |
| `docs/verification/001-reading-session/evidence/S3a_normal_en.png` | 画面 S3a・状態 `normal` | 英語 | AC-71, AC-72, AC-94, AC-95, AC-141 |
| `docs/verification/001-reading-session/evidence/S3a_normal_light.png` | 画面 S3a・状態 `normal` | ライト | AC-71, AC-72, AC-94, AC-95, AC-141 |
| `docs/verification/001-reading-session/evidence/S3b_empty_light.png` | 画面 S3b・状態 `empty` | ライト | AC-73, AC-74, AC-94, AC-95, AC-141 |
| `docs/verification/001-reading-session/evidence/S3b_error_light.png` | 画面 S3b・状態 `error` | ライト | AC-73, AC-74, AC-94, AC-95, AC-141 |
| `docs/verification/001-reading-session/evidence/S3b_loading_light.png` | 画面 S3b・状態 `loading` | ライト | AC-73, AC-74, AC-94, AC-95, AC-141 |
| `docs/verification/001-reading-session/evidence/S3b_normal_ax5.png` | 画面 S3b・状態 `normal` | AX5 | AC-73, AC-74, AC-94, AC-95, AC-141 |
| `docs/verification/001-reading-session/evidence/S3b_normal_dark.png` | 画面 S3b・状態 `normal` | ダーク | AC-73, AC-74, AC-94, AC-95, AC-141 |
| `docs/verification/001-reading-session/evidence/S3b_normal_en.png` | 画面 S3b・状態 `normal` | 英語 | AC-73, AC-74, AC-94, AC-95, AC-141 |
| `docs/verification/001-reading-session/evidence/S3b_normal_light.png` | 画面 S3b・状態 `normal` | ライト | AC-73, AC-74, AC-94, AC-95, AC-141 |
| `docs/verification/001-reading-session/evidence/S3c_denied_light.png` | 画面 S3c・状態 `denied` | ライト | AC-65〜AC-69, AC-94, AC-95, AC-142 |
| `docs/verification/001-reading-session/evidence/S3c_empty_light.png` | 画面 S3c・状態 `empty` | ライト | AC-65〜AC-69, AC-94, AC-95, AC-142 |
| `docs/verification/001-reading-session/evidence/S3c_error_light.png` | 画面 S3c・状態 `error` | ライト | AC-65〜AC-69, AC-94, AC-95, AC-142 |
| `docs/verification/001-reading-session/evidence/S3c_loading_light.png` | 画面 S3c・状態 `loading` | ライト | AC-65〜AC-69, AC-94, AC-95, AC-142 |
| `docs/verification/001-reading-session/evidence/S3c_normal_ax5.png` | 画面 S3c・状態 `normal` | AX5 | AC-65〜AC-69, AC-94, AC-95, AC-142 |
| `docs/verification/001-reading-session/evidence/S3c_normal_dark.png` | 画面 S3c・状態 `normal` | ダーク | AC-65〜AC-69, AC-94, AC-95, AC-142 |
| `docs/verification/001-reading-session/evidence/S3c_normal_en.png` | 画面 S3c・状態 `normal` | 英語 | AC-65〜AC-69, AC-94, AC-95, AC-142 |
| `docs/verification/001-reading-session/evidence/S3c_normal_light.png` | 画面 S3c・状態 `normal` | ライト | AC-65〜AC-69, AC-94, AC-95, AC-142 |
| `docs/verification/001-reading-session/evidence/S3c_partial_light.png` | 画面 S3c・状態 `partial` | ライト | AC-65〜AC-69, AC-94, AC-95, AC-142 |
| `docs/verification/001-reading-session/evidence/S4_empty_light.png` | 画面 S4・状態 `empty` | ライト | AC-57, AC-61, AC-62, AC-75, AC-76, AC-102, AC-141 |
| `docs/verification/001-reading-session/evidence/S4_normal_ax5.png` | 画面 S4・状態 `normal` | AX5 | AC-57, AC-61, AC-62, AC-75, AC-76, AC-102, AC-141 |
| `docs/verification/001-reading-session/evidence/S4_normal_dark.png` | 画面 S4・状態 `normal` | ダーク | AC-57, AC-61, AC-62, AC-75, AC-76, AC-102, AC-141 |
| `docs/verification/001-reading-session/evidence/S4_normal_en.png` | 画面 S4・状態 `normal` | 英語 | AC-57, AC-61, AC-62, AC-75, AC-76, AC-102, AC-141 |
| `docs/verification/001-reading-session/evidence/S4_normal_light.png` | 画面 S4・状態 `normal` | ライト | AC-57, AC-61, AC-62, AC-75, AC-76, AC-102, AC-141 |
| `docs/verification/001-reading-session/evidence/S4_partial_light.png` | 画面 S4・状態 `partial` | ライト | AC-57, AC-61, AC-62, AC-75, AC-76, AC-102, AC-141 |
| `docs/verification/001-reading-session/evidence/S4_result_light.png` | 画面 S4・状態 `result` | ライト | AC-57, AC-61, AC-62, AC-75, AC-76, AC-102, AC-141 |
| `docs/verification/001-reading-session/evidence/S5_normal_ax5.png` | 画面 S5・状態 `normal` | AX5 | AC-96 |
| `docs/verification/001-reading-session/evidence/S5_normal_dark.png` | 画面 S5・状態 `normal` | ダーク | AC-96 |
| `docs/verification/001-reading-session/evidence/S5_normal_en.png` | 画面 S5・状態 `normal` | 英語 | AC-96 |
| `docs/verification/001-reading-session/evidence/S5_normal_light.png` | 画面 S5・状態 `normal` | ライト | AC-96 |
| `docs/verification/001-reading-session/evidence/S5_partial_light.png` | 画面 S5・状態 `partial` | ライト | AC-96 |
| `docs/verification/001-reading-session/evidence/S6_empty_light.png` | 画面 S6・状態 `empty` | ライト | AC-13, AC-15, AC-101 |
| `docs/verification/001-reading-session/evidence/S6_error_light.png` | 画面 S6・状態 `error` | ライト | AC-13, AC-15, AC-101 |
| `docs/verification/001-reading-session/evidence/S6_loading_light.png` | 画面 S6・状態 `loading` | ライト | AC-13, AC-15, AC-101 |
| `docs/verification/001-reading-session/evidence/S6_normal_ax5.png` | 画面 S6・状態 `normal` | AX5 | AC-13, AC-15, AC-101 |
| `docs/verification/001-reading-session/evidence/S6_normal_dark.png` | 画面 S6・状態 `normal` | ダーク | AC-13, AC-15, AC-101 |
| `docs/verification/001-reading-session/evidence/S6_normal_en.png` | 画面 S6・状態 `normal` | 英語 | AC-13, AC-15, AC-101 |
| `docs/verification/001-reading-session/evidence/S6_normal_light.png` | 画面 S6・状態 `normal` | ライト | AC-13, AC-15, AC-101 |
| `docs/verification/001-reading-session/evidence/S6_partial_light.png` | 画面 S6・状態 `partial` | ライト | AC-13, AC-15, AC-101 |
| `docs/verification/001-reading-session/evidence/S6_shelf_dark.png` | 画面 S6・状態 `shelf` | ダーク | AC-13, AC-15, AC-101 |
| `docs/verification/001-reading-session/evidence/S6_shelf_light.png` | 画面 S6・状態 `shelf` | ライト | AC-13, AC-15, AC-101 |
| `docs/verification/001-reading-session/evidence/S7_book_light.png` | 画面 S7・状態 `book` | ライト | AC-14, AC-16〜AC-20, AC-22, AC-23, AC-91, AC-101, AC-112, AC-146 |
| `docs/verification/001-reading-session/evidence/S7_denied_light.png` | 画面 S7・状態 `denied` | ライト | AC-14, AC-16〜AC-20, AC-22, AC-23, AC-91, AC-101, AC-112, AC-146 |
| `docs/verification/001-reading-session/evidence/S7_empty_light.png` | 画面 S7・状態 `empty` | ライト | AC-14, AC-16〜AC-20, AC-22, AC-23, AC-91, AC-101, AC-112, AC-146 |
| `docs/verification/001-reading-session/evidence/S7_error_light.png` | 画面 S7・状態 `error` | ライト | AC-14, AC-16〜AC-20, AC-22, AC-23, AC-91, AC-101, AC-112, AC-146 |
| `docs/verification/001-reading-session/evidence/S7_loading_light.png` | 画面 S7・状態 `loading` | ライト | AC-14, AC-16〜AC-20, AC-22, AC-23, AC-91, AC-101, AC-112, AC-146 |
| `docs/verification/001-reading-session/evidence/S7_normal_ax5.png` | 画面 S7・状態 `normal` | AX5 | AC-14, AC-16〜AC-20, AC-22, AC-23, AC-91, AC-101, AC-112, AC-146 |
| `docs/verification/001-reading-session/evidence/S7_normal_dark.png` | 画面 S7・状態 `normal` | ダーク | AC-14, AC-16〜AC-20, AC-22, AC-23, AC-91, AC-101, AC-112, AC-146 |
| `docs/verification/001-reading-session/evidence/S7_normal_en.png` | 画面 S7・状態 `normal` | 英語 | AC-14, AC-16〜AC-20, AC-22, AC-23, AC-91, AC-101, AC-112, AC-146 |
| `docs/verification/001-reading-session/evidence/S7_normal_light.png` | 画面 S7・状態 `normal` | ライト | AC-14, AC-16〜AC-20, AC-22, AC-23, AC-91, AC-101, AC-112, AC-146 |
| `docs/verification/001-reading-session/evidence/S7_partial_light.png` | 画面 S7・状態 `partial` | ライト | AC-14, AC-16〜AC-20, AC-22, AC-23, AC-91, AC-101, AC-112, AC-146 |
| `docs/verification/001-reading-session/evidence/S7a_empty_light.png` | 画面 S7a・状態 `empty` | ライト | AC-21, AC-91 |
| `docs/verification/001-reading-session/evidence/S7a_error_light.png` | 画面 S7a・状態 `error` | ライト | AC-21, AC-91 |
| `docs/verification/001-reading-session/evidence/S7a_loading_light.png` | 画面 S7a・状態 `loading` | ライト | AC-21, AC-91 |
| `docs/verification/001-reading-session/evidence/S7a_normal_ax5.png` | 画面 S7a・状態 `normal` | AX5 | AC-21, AC-91 |
| `docs/verification/001-reading-session/evidence/S7a_normal_dark.png` | 画面 S7a・状態 `normal` | ダーク | AC-21, AC-91 |
| `docs/verification/001-reading-session/evidence/S7a_normal_en.png` | 画面 S7a・状態 `normal` | 英語 | AC-21, AC-91 |
| `docs/verification/001-reading-session/evidence/S7a_normal_light.png` | 画面 S7a・状態 `normal` | ライト | AC-21, AC-91 |
| `docs/verification/001-reading-session/evidence/S7b_empty_light.png` | 画面 S7b・状態 `empty` | ライト | AC-24〜AC-26, AC-91 |
| `docs/verification/001-reading-session/evidence/S7b_error_light.png` | 画面 S7b・状態 `error` | ライト | AC-24〜AC-26, AC-91 |
| `docs/verification/001-reading-session/evidence/S7b_loading_light.png` | 画面 S7b・状態 `loading` | ライト | AC-24〜AC-26, AC-91 |
| `docs/verification/001-reading-session/evidence/S7b_normal_ax5.png` | 画面 S7b・状態 `normal` | AX5 | AC-24〜AC-26, AC-91 |
| `docs/verification/001-reading-session/evidence/S7b_normal_dark.png` | 画面 S7b・状態 `normal` | ダーク | AC-24〜AC-26, AC-91 |
| `docs/verification/001-reading-session/evidence/S7b_normal_en.png` | 画面 S7b・状態 `normal` | 英語 | AC-24〜AC-26, AC-91 |
| `docs/verification/001-reading-session/evidence/S7b_normal_light.png` | 画面 S7b・状態 `normal` | ライト | AC-24〜AC-26, AC-91 |
| `docs/verification/001-reading-session/evidence/S7c_denied_light.png` | 画面 S7c・状態 `denied` | ライト | AC-10, AC-77, AC-113, AC-140 |
| `docs/verification/001-reading-session/evidence/S7c_empty_light.png` | 画面 S7c・状態 `empty` | ライト | AC-10, AC-77, AC-113, AC-140 |
| `docs/verification/001-reading-session/evidence/S7c_error_light.png` | 画面 S7c・状態 `error` | ライト | AC-10, AC-77, AC-113, AC-140 |
| `docs/verification/001-reading-session/evidence/S7c_loading_light.png` | 画面 S7c・状態 `loading` | ライト | AC-10, AC-77, AC-113, AC-140 |
| `docs/verification/001-reading-session/evidence/S7c_normal_ax5.png` | 画面 S7c・状態 `normal` | AX5 | AC-10, AC-77, AC-113, AC-140 |
| `docs/verification/001-reading-session/evidence/S7c_normal_dark.png` | 画面 S7c・状態 `normal` | ダーク | AC-10, AC-77, AC-113, AC-140 |
| `docs/verification/001-reading-session/evidence/S7c_normal_en.png` | 画面 S7c・状態 `normal` | 英語 | AC-10, AC-77, AC-113, AC-140 |
| `docs/verification/001-reading-session/evidence/S7c_normal_light.png` | 画面 S7c・状態 `normal` | ライト | AC-10, AC-77, AC-113, AC-140 |
| `docs/verification/001-reading-session/evidence/S7c_partial_light.png` | 画面 S7c・状態 `partial` | ライト | AC-10, AC-77, AC-113, AC-140 |
| `docs/verification/001-reading-session/evidence/S8_denied_light.png` | 画面 S8・状態 `denied` | ライト | AC-2, AC-11, AC-12, AC-139 |
| `docs/verification/001-reading-session/evidence/S8_empty_light.png` | 画面 S8・状態 `empty` | ライト | AC-2, AC-11, AC-12, AC-139 |
| `docs/verification/001-reading-session/evidence/S8_error_light.png` | 画面 S8・状態 `error` | ライト | AC-2, AC-11, AC-12, AC-139 |
| `docs/verification/001-reading-session/evidence/S8_normal_ax5.png` | 画面 S8・状態 `normal` | AX5 | AC-2, AC-11, AC-12, AC-139 |
| `docs/verification/001-reading-session/evidence/S8_normal_dark.png` | 画面 S8・状態 `normal` | ダーク | AC-2, AC-11, AC-12, AC-139 |
| `docs/verification/001-reading-session/evidence/S8_normal_en.png` | 画面 S8・状態 `normal` | 英語 | AC-2, AC-11, AC-12, AC-139 |
| `docs/verification/001-reading-session/evidence/S8_normal_light.png` | 画面 S8・状態 `normal` | ライト | AC-2, AC-11, AC-12, AC-139 |
| `docs/verification/001-reading-session/evidence/S8_partial_light.png` | 画面 S8・状態 `partial` | ライト | AC-2, AC-11, AC-12, AC-139 |
| `docs/verification/001-reading-session/evidence/S8a_denied_light.png` | 画面 S8a・状態 `denied` | ライト | AC-2, AC-3, AC-6, AC-9〜AC-11, AC-91, AC-140, AC-149 |
| `docs/verification/001-reading-session/evidence/S8a_empty_light.png` | 画面 S8a・状態 `empty` | ライト | AC-2, AC-3, AC-6, AC-9〜AC-11, AC-91, AC-140, AC-149 |
| `docs/verification/001-reading-session/evidence/S8a_error_light.png` | 画面 S8a・状態 `error` | ライト | AC-2, AC-3, AC-6, AC-9〜AC-11, AC-91, AC-140, AC-149 |
| `docs/verification/001-reading-session/evidence/S8a_loading_light.png` | 画面 S8a・状態 `loading` | ライト | AC-2, AC-3, AC-6, AC-9〜AC-11, AC-91, AC-140, AC-149 |
| `docs/verification/001-reading-session/evidence/S8a_normal_ax5.png` | 画面 S8a・状態 `normal` | AX5 | AC-2, AC-3, AC-6, AC-9〜AC-11, AC-91, AC-140, AC-149 |
| `docs/verification/001-reading-session/evidence/S8a_normal_dark.png` | 画面 S8a・状態 `normal` | ダーク | AC-2, AC-3, AC-6, AC-9〜AC-11, AC-91, AC-140, AC-149 |
| `docs/verification/001-reading-session/evidence/S8a_normal_en.png` | 画面 S8a・状態 `normal` | 英語 | AC-2, AC-3, AC-6, AC-9〜AC-11, AC-91, AC-140, AC-149 |
| `docs/verification/001-reading-session/evidence/S8a_normal_light.png` | 画面 S8a・状態 `normal` | ライト | AC-2, AC-3, AC-6, AC-9〜AC-11, AC-91, AC-140, AC-149 |
| `docs/verification/001-reading-session/evidence/S8a_partial_light.png` | 画面 S8a・状態 `partial` | ライト | AC-2, AC-3, AC-6, AC-9〜AC-11, AC-91, AC-140, AC-149 |
| `docs/verification/001-reading-session/evidence/S8b_denied_light.png` | 画面 S8b・状態 `denied` | ライト | AC-10, AC-137 |
| `docs/verification/001-reading-session/evidence/S8b_empty_light.png` | 画面 S8b・状態 `empty` | ライト | AC-10, AC-137 |
| `docs/verification/001-reading-session/evidence/S8b_error_light.png` | 画面 S8b・状態 `error` | ライト | AC-10, AC-137 |
| `docs/verification/001-reading-session/evidence/S8b_loading_light.png` | 画面 S8b・状態 `loading` | ライト | AC-10, AC-137 |
| `docs/verification/001-reading-session/evidence/S8b_normal_ax5.png` | 画面 S8b・状態 `normal` | AX5 | AC-10, AC-137 |
| `docs/verification/001-reading-session/evidence/S8b_normal_dark.png` | 画面 S8b・状態 `normal` | ダーク | AC-10, AC-137 |
| `docs/verification/001-reading-session/evidence/S8b_normal_en.png` | 画面 S8b・状態 `normal` | 英語 | AC-10, AC-137 |
| `docs/verification/001-reading-session/evidence/S8b_normal_light.png` | 画面 S8b・状態 `normal` | ライト | AC-10, AC-137 |
| `docs/verification/001-reading-session/evidence/S8b_partial_light.png` | 画面 S8b・状態 `partial` | ライト | AC-10, AC-137 |
| `docs/verification/001-reading-session/evidence/S8c_empty_light.png` | 画面 S8c・状態 `empty` | ライト | AC-4, AC-5, AC-7, AC-8, AC-11, AC-91, AC-92, AC-149 |
| `docs/verification/001-reading-session/evidence/S8c_error_light.png` | 画面 S8c・状態 `error` | ライト | AC-4, AC-5, AC-7, AC-8, AC-11, AC-91, AC-92, AC-149 |
| `docs/verification/001-reading-session/evidence/S8c_loading_light.png` | 画面 S8c・状態 `loading` | ライト | AC-4, AC-5, AC-7, AC-8, AC-11, AC-91, AC-92, AC-149 |
| `docs/verification/001-reading-session/evidence/S8c_normal_ax5.png` | 画面 S8c・状態 `normal` | AX5 | AC-4, AC-5, AC-7, AC-8, AC-11, AC-91, AC-92, AC-149 |
| `docs/verification/001-reading-session/evidence/S8c_normal_dark.png` | 画面 S8c・状態 `normal` | ダーク | AC-4, AC-5, AC-7, AC-8, AC-11, AC-91, AC-92, AC-149 |
| `docs/verification/001-reading-session/evidence/S8c_normal_en.png` | 画面 S8c・状態 `normal` | 英語 | AC-4, AC-5, AC-7, AC-8, AC-11, AC-91, AC-92, AC-149 |
| `docs/verification/001-reading-session/evidence/S8c_normal_light.png` | 画面 S8c・状態 `normal` | ライト | AC-4, AC-5, AC-7, AC-8, AC-11, AC-91, AC-92, AC-149 |
| `docs/verification/001-reading-session/evidence/S8c_partial_light.png` | 画面 S8c・状態 `partial` | ライト | AC-4, AC-5, AC-7, AC-8, AC-11, AC-91, AC-92, AC-149 |
| `docs/verification/001-reading-session/evidence/S8d_denied_light.png` | 画面 S8d・状態 `denied` | ライト | AC-138 |
| `docs/verification/001-reading-session/evidence/S8d_empty_light.png` | 画面 S8d・状態 `empty` | ライト | AC-138 |
| `docs/verification/001-reading-session/evidence/S8d_error_light.png` | 画面 S8d・状態 `error` | ライト | AC-138 |
| `docs/verification/001-reading-session/evidence/S8d_loading_light.png` | 画面 S8d・状態 `loading` | ライト | AC-138 |
| `docs/verification/001-reading-session/evidence/S8d_normal_ax5.png` | 画面 S8d・状態 `normal` | AX5 | AC-138 |
| `docs/verification/001-reading-session/evidence/S8d_normal_dark.png` | 画面 S8d・状態 `normal` | ダーク | AC-138 |
| `docs/verification/001-reading-session/evidence/S8d_normal_en.png` | 画面 S8d・状態 `normal` | 英語 | AC-138 |
| `docs/verification/001-reading-session/evidence/S8d_normal_light.png` | 画面 S8d・状態 `normal` | ライト | AC-138 |
| `docs/verification/001-reading-session/evidence/S8d_partial_light.png` | 画面 S8d・状態 `partial` | ライト | AC-138 |
| `docs/verification/001-reading-session/evidence/S9_denied_light.png` | 画面 S9・状態 `denied` | ライト | AC-77〜AC-87, AC-91, AC-112, AC-127〜AC-129, AC-147, AC-148 |
| `docs/verification/001-reading-session/evidence/S9_empty_light.png` | 画面 S9・状態 `empty` | ライト | AC-77〜AC-87, AC-91, AC-112, AC-127〜AC-129, AC-147, AC-148 |
| `docs/verification/001-reading-session/evidence/S9_error_light.png` | 画面 S9・状態 `error` | ライト | AC-77〜AC-87, AC-91, AC-112, AC-127〜AC-129, AC-147, AC-148 |
| `docs/verification/001-reading-session/evidence/S9_finish_dark.png` | 画面 S9・状態 `finish` | ダーク | AC-77〜AC-87, AC-91, AC-112, AC-127〜AC-129, AC-147, AC-148 |
| `docs/verification/001-reading-session/evidence/S9_finish_light.png` | 画面 S9・状態 `finish` | ライト | AC-77〜AC-87, AC-91, AC-112, AC-127〜AC-129, AC-147, AC-148 |
| `docs/verification/001-reading-session/evidence/S9_loading_light.png` | 画面 S9・状態 `loading` | ライト | AC-77〜AC-87, AC-91, AC-112, AC-127〜AC-129, AC-147, AC-148 |
| `docs/verification/001-reading-session/evidence/S9_normal_ax5.png` | 画面 S9・状態 `normal` | AX5 | AC-77〜AC-87, AC-91, AC-112, AC-127〜AC-129, AC-147, AC-148 |
| `docs/verification/001-reading-session/evidence/S9_normal_dark.png` | 画面 S9・状態 `normal` | ダーク | AC-77〜AC-87, AC-91, AC-112, AC-127〜AC-129, AC-147, AC-148 |
| `docs/verification/001-reading-session/evidence/S9_normal_en.png` | 画面 S9・状態 `normal` | 英語 | AC-77〜AC-87, AC-91, AC-112, AC-127〜AC-129, AC-147, AC-148 |
| `docs/verification/001-reading-session/evidence/S9_normal_light.png` | 画面 S9・状態 `normal` | ライト | AC-77〜AC-87, AC-91, AC-112, AC-127〜AC-129, AC-147, AC-148 |
| `docs/verification/001-reading-session/evidence/S9_partial_light.png` | 画面 S9・状態 `partial` | ライト | AC-77〜AC-87, AC-91, AC-112, AC-127〜AC-129, AC-147, AC-148 |
| `docs/verification/001-reading-session/evidence/W1_empty_light.png` | 画面 W1・状態 `empty` | ライト | AC-27〜AC-34, AC-99 |
| `docs/verification/001-reading-session/evidence/W1_error_light.png` | 画面 W1・状態 `error` | ライト | AC-27〜AC-34, AC-99 |
| `docs/verification/001-reading-session/evidence/W1_loading_light.png` | 画面 W1・状態 `loading` | ライト | AC-27〜AC-34, AC-99 |
| `docs/verification/001-reading-session/evidence/W1_normal_ax5.png` | 画面 W1・状態 `normal` | AX5 | AC-27〜AC-34, AC-99 |
| `docs/verification/001-reading-session/evidence/W1_normal_dark.png` | 画面 W1・状態 `normal` | ダーク | AC-27〜AC-34, AC-99 |
| `docs/verification/001-reading-session/evidence/W1_normal_en.png` | 画面 W1・状態 `normal` | 英語 | AC-27〜AC-34, AC-99 |
| `docs/verification/001-reading-session/evidence/W1_normal_light.png` | 画面 W1・状態 `normal` | ライト | AC-27〜AC-34, AC-99 |
| `docs/verification/001-reading-session/evidence/W1_partial_light.png` | 画面 W1・状態 `partial` | ライト | AC-27〜AC-34, AC-99 |
| `docs/verification/001-reading-session/evidence/W2_empty_light.png` | 画面 W2・状態 `empty` | ライト | AC-35, AC-99, AC-106 |
| `docs/verification/001-reading-session/evidence/W2_error_light.png` | 画面 W2・状態 `error` | ライト | AC-35, AC-99, AC-106 |
| `docs/verification/001-reading-session/evidence/W2_loading_light.png` | 画面 W2・状態 `loading` | ライト | AC-35, AC-99, AC-106 |
| `docs/verification/001-reading-session/evidence/W2_normal_ax5.png` | 画面 W2・状態 `normal` | AX5 | AC-35, AC-99, AC-106 |
| `docs/verification/001-reading-session/evidence/W2_normal_dark.png` | 画面 W2・状態 `normal` | ダーク | AC-35, AC-99, AC-106 |
| `docs/verification/001-reading-session/evidence/W2_normal_en.png` | 画面 W2・状態 `normal` | 英語 | AC-35, AC-99, AC-106 |
| `docs/verification/001-reading-session/evidence/W2_normal_light.png` | 画面 W2・状態 `normal` | ライト | AC-35, AC-99, AC-106 |
| `docs/verification/001-reading-session/evidence/W2_partial_light.png` | 画面 W2・状態 `partial` | ライト | AC-35, AC-99, AC-106 |
| `docs/verification/001-reading-session/evidence/W3_denied_light.png` | 画面 W3・状態 `denied` | ライト | AC-36〜AC-38, AC-41, AC-97, AC-98, AC-114, AC-120, AC-130, AC-136 |
| `docs/verification/001-reading-session/evidence/W3_empty_light.png` | 画面 W3・状態 `empty` | ライト | AC-36〜AC-38, AC-41, AC-97, AC-98, AC-114, AC-120, AC-130, AC-136 |
| `docs/verification/001-reading-session/evidence/W3_error_light.png` | 画面 W3・状態 `error` | ライト | AC-36〜AC-38, AC-41, AC-97, AC-98, AC-114, AC-120, AC-130, AC-136 |
| `docs/verification/001-reading-session/evidence/W3_normal_ax5.png` | 画面 W3・状態 `normal` | AX5 | AC-36〜AC-38, AC-41, AC-97, AC-98, AC-114, AC-120, AC-130, AC-136 |
| `docs/verification/001-reading-session/evidence/W3_normal_dark.png` | 画面 W3・状態 `normal` | ダーク | AC-36〜AC-38, AC-41, AC-97, AC-98, AC-114, AC-120, AC-130, AC-136 |
| `docs/verification/001-reading-session/evidence/W3_normal_en.png` | 画面 W3・状態 `normal` | 英語 | AC-36〜AC-38, AC-41, AC-97, AC-98, AC-114, AC-120, AC-130, AC-136 |
| `docs/verification/001-reading-session/evidence/W3_normal_light.png` | 画面 W3・状態 `normal` | ライト | AC-36〜AC-38, AC-41, AC-97, AC-98, AC-114, AC-120, AC-130, AC-136 |
| `docs/verification/001-reading-session/evidence/W3_partial_light.png` | 画面 W3・状態 `partial` | ライト | AC-36〜AC-38, AC-41, AC-97, AC-98, AC-114, AC-120, AC-130, AC-136 |
| `docs/verification/001-reading-session/evidence/W4_denied_light.png` | 画面 W4・状態 `denied` | ライト | AC-114〜AC-119, AC-125, AC-126, AC-131 |
| `docs/verification/001-reading-session/evidence/W4_empty_light.png` | 画面 W4・状態 `empty` | ライト | AC-114〜AC-119, AC-125, AC-126, AC-131 |
| `docs/verification/001-reading-session/evidence/W4_error_light.png` | 画面 W4・状態 `error` | ライト | AC-114〜AC-119, AC-125, AC-126, AC-131 |
| `docs/verification/001-reading-session/evidence/W4_loading_light.png` | 画面 W4・状態 `loading` | ライト | AC-114〜AC-119, AC-125, AC-126, AC-131 |
| `docs/verification/001-reading-session/evidence/W4_normal_ax5.png` | 画面 W4・状態 `normal` | AX5 | AC-114〜AC-119, AC-125, AC-126, AC-131 |
| `docs/verification/001-reading-session/evidence/W4_normal_dark.png` | 画面 W4・状態 `normal` | ダーク | AC-114〜AC-119, AC-125, AC-126, AC-131 |
| `docs/verification/001-reading-session/evidence/W4_normal_en.png` | 画面 W4・状態 `normal` | 英語 | AC-114〜AC-119, AC-125, AC-126, AC-131 |
| `docs/verification/001-reading-session/evidence/W4_normal_light.png` | 画面 W4・状態 `normal` | ライト | AC-114〜AC-119, AC-125, AC-126, AC-131 |
| `docs/verification/001-reading-session/evidence/W4_partial_light.png` | 画面 W4・状態 `partial` | ライト | AC-114〜AC-119, AC-125, AC-126, AC-131 |
| `docs/verification/001-reading-session/evidence/W5_empty_light.png` | 画面 W5・状態 `empty` | ライト | AC-114〜AC-126, AC-131〜AC-135, AC-143 |
| `docs/verification/001-reading-session/evidence/W5_error_light.png` | 画面 W5・状態 `error` | ライト | AC-114〜AC-126, AC-131〜AC-135, AC-143 |
| `docs/verification/001-reading-session/evidence/W5_normal_ax5.png` | 画面 W5・状態 `normal` | AX5 | AC-114〜AC-126, AC-131〜AC-135, AC-143 |
| `docs/verification/001-reading-session/evidence/W5_normal_dark.png` | 画面 W5・状態 `normal` | ダーク | AC-114〜AC-126, AC-131〜AC-135, AC-143 |
| `docs/verification/001-reading-session/evidence/W5_normal_en.png` | 画面 W5・状態 `normal` | 英語 | AC-114〜AC-126, AC-131〜AC-135, AC-143 |
| `docs/verification/001-reading-session/evidence/W5_normal_light.png` | 画面 W5・状態 `normal` | ライト | AC-114〜AC-126, AC-131〜AC-135, AC-143 |
| `docs/verification/001-reading-session/evidence/W5_partial_light.png` | 画面 W5・状態 `partial` | ライト | AC-114〜AC-126, AC-131〜AC-135, AC-143 |
| `docs/verification/001-reading-session/evidence/design-checks.log` | `craft-design-reviewer` 5つの機械チェック・全 27 画面 `performAccessibilityAudit()`・探索テスト 6 件のログ | ライト / ダーク / AX5 / 英語 | AC-1〜AC-149 |
| `docs/verification/001-reading-session/evidence/explore_R1.png` | 探索セッション R1 の証拠スクリーンショット | ライト | 探索チャーター R1 |
| `docs/verification/001-reading-session/evidence/explore_R2.png` | 探索セッション R2 の証拠スクリーンショット | ライト | 探索チャーター R2 |
| `docs/verification/001-reading-session/evidence/explore_R3.png` | 探索セッション R3 の証拠スクリーンショット | ライト | 探索チャーター R3 |
| `docs/verification/001-reading-session/evidence/explore_R4.png` | 探索セッション R4 の証拠スクリーンショット | ライト | 探索チャーター R4 |
| `docs/verification/001-reading-session/evidence/explore_R5.png` | 探索セッション R5 の証拠スクリーンショット | ライト | 探索チャーター R5 |
| `docs/verification/001-reading-session/evidence/explore_R6.png` | 探索セッション R6 の証拠スクリーンショット | ライト | 探索チャーター R6 |
| `docs/verification/001-reading-session/evidence/red.log` | 実装前の赤ログ（`make ios-test` 終了コード 1） | — | AC-1〜AC-149 |

## 10. 前の機能の受け入れテスト（回帰）
該当なし（`001-reading-session` がこのアプリの最初の機能のため）。

| 機能 | コマンド | 終了コード | 成功 / 失敗 / 飛ばした |
|---|---|---|---|
| 該当なし（初回機能 `001-reading-session`） | — | — | — |

## 11. 見つかった問題
なし（全 149 AC の受け入れテスト・単体テスト・揺れ確認 75 実行・アクセシビリティ監査・探索セッション 6 本で不具合は 0 件）。

## 12. PRD とテストの食い違い
なし。

## 13. 未検証のものと理由
なし（シミュレーターで検証可能な全 149 AC をすべて検証完了。実機の物理センサー・ロック画面描画・StandBy・Siri 音声・Sandbox 決済・App プライバシーレポートを確認する `G4-1`〜`G4-22` は、`test-plan.md` 7章および PRD 11章の定めどおり G4 で Takuma が実機にて確認する）。
