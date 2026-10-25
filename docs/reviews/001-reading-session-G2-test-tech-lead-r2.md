VERDICT: FAIL
CRITICAL: 2
MAJOR: 0

SUMMARY:
前回の指摘（CRITICAL-1〜6、MAJOR-1〜2）のうち、`AcceptanceTestBase.swift` および主要な受け入れテスト8ファイル（`RegistrationAcceptanceTests.swift`、`ShelfAndBookAcceptanceTests.swift`、`WidgetAndActivityAcceptanceTests.swift`、`ReadingSessionAcceptanceTests.swift`、`BookmarkAcceptanceTests.swift`、`FinishAndRecommendationAcceptanceTests.swift`、`SettingsStoreIntentsAcceptanceTests.swift`）の修正は完了し、契約（`contracts/test-hooks.md`・`contracts/hooks/*.schema.json`）および `design/001-reading-session.md` と整合していることを確認しました。
しかし、`PerformanceTests.swift` と `FirstLaunchTests.swift` の2ファイルに前回の指摘（CRITICAL-3、CRITICAL-4、CRITICAL-5、CRITICAL-6）の修正漏れが残っており、さらに `PerformanceTests.swift` には `AcceptanceTestBase.swift` のシグネチャ変更に伴う Swift コンパイルエラーと未定義フック・未定義識別子の使用があります。この2ファイルを修正すれば PASS となります。

FINDINGS:

## 指摘

- CRITICAL-1（前回の CRITICAL-3 / CRITICAL-5 / CRITICAL-6 未解消 + コンパイルエラー）：`PerformanceTests.swift` が `AcceptanceTestBase` のメソッド変更への未追従によるコンパイルエラー、JSON Schema 違反、未定義の起動引数・識別子、`test-plan.md` とのテスト名・閾値の不一致を含んでいます。
  1. `makeSeedBook` / `makeSeedRecord` の引数名および `resetAndLaunch` の呼び出しを `AcceptanceTestBase.swift` に合わせること。
  2. `status` を `"current"` / `"tsundoku"` にし、`ndlStubJSON` のトップレベルを `"stubVersion": 1, "status": "ready", "books": [...]` にし、未定義の `"pageCount"` を除去すること。
  3. `test_AC100` は `measure(metrics: [XCTApplicationLaunchMetric(waitUntilResponsive: true)])` または実測を使い、`-uitest-barcode-queue` ではなく `sendBarcode("9784101000015")` を使うこと。
  4. `design/001-reading-session.md` 第6章の識別子（`bookmark.start`, `toolbar.shelf`, `book.colophon`, `shelf.addBook`, `register.barcode`, `register.manual`, `manual.title`, `manual.cancel`, `register.cancel`）を使うこと。
  5. `test-plan.md` 第2章のテストメソッド名と閾値（AC-101 は `<= 1000.0` ms、AC-149 は `<= 300.0` ms）に合わせること。

- CRITICAL-2（前回の CRITICAL-4 未解消）：`FirstLaunchTests.swift` で `store["books"]` を直接参照しているため、`readStoreBooks()` を使って `XCTAssertEqual(readStoreBooks().count, 0)` とすること。
