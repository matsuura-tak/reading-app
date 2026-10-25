VERDICT: FAIL
CRITICAL: 3
MAJOR: 4

SUMMARY:
r1 の指摘（C-1〜C-6、M-1〜M-6、および tech-lead r1 の CRITICAL-1〜6、MAJOR-1〜2）のうち、`Support/AcceptanceTestBase.swift` と主要7テストファイルの大部分は修正されていることを確認しました。
しかし、`ios/AcceptanceTests/PerformanceTests.swift` が r1 から未更新のまま残されており、`ios/AcceptanceTests/FirstLaunchTests.swift` でも `hook.store` のトップレベル `books` 参照による空振り判定が残っています。また、`AcceptanceTestBase.runExternalIntent` の Darwin 通知コードが `contracts/test-hooks.md` §1-4 の定義（1〜4）から外れている点、および MAJOR 4件を検出したため FAIL と判定します。

FINDINGS:
- [CRITICAL-1] `PerformanceTests.swift`:
  1. `launchApp` や旧引数ラベル（`isCurrentBook`, `markPage`, `pageCount`, `durationSec`）を `AcceptanceTestBase.swift` の現行 API（`resetAndLaunch`, `makeSeedBook`, `makeSeedRecord`）に合わせること。
  2. `status` を `"current"` / `"tsundoku"` に修正すること。
  3. `ndlStubJSON` を `"stubVersion": 1, "status": "ready", "books": [...]` にし、禁止キー `"pageCount"` を除去すること。
  4. 未定義の起動引数 `"-uitest-barcode-queue"` を廃止し、`sendBarcode(...)` を使うこと。
  5. `test_AC100` は `XCTApplicationLaunchMetric(waitUntilResponsive: true)` で計測すること。
  6. `test_AC102` で `($0["request"] as? [String: Any])?["family"]` および `($0["timeline"] as? [String: Any])?["elapsedMs"]` を参照すること。
  7. 未定義の `accessibilityIdentifier`（`screen.bookmark`, `screen.book`, `toolbar.addBook`, `add.method.barcode`, `add.method.search`, `search.query`, `search.cancel`）を `design/001-reading-session.md` §6 の識別子（`bookmark.start`, `toolbar.shelf`, `book.colophon`, `shelf.addBook`, `register.barcode`, `register.manual`, `manual.title`, `manual.cancel`, `register.cancel`）に修正すること。
  8. テストメソッド名4件を `test-plan.md` の日本語名に一致させ、閾値を AC-101 `<= 1000.0` ms、AC-149 `<= 300.0` ms に合わせること。
- [CRITICAL-2] `FirstLaunchTests.swift`: `readStoreBooks()` を使って `XCTAssertEqual(readStoreBooks().count, 0)` とすること。
- [CRITICAL-3] `AcceptanceTestBase.swift`: `runExternalIntent` の `notify_set_state` 値を `contracts/test-hooks.md` §1-4 どおり常に `1`〜`4` のみにし、`canContinueInForeground: false` は起動時の `UITEST_INTENT`（`makeIntentConfigJSON(canContinueInForeground: false)`）で設定すること。
- [MAJOR-1] `WidgetAndActivityAcceptanceTests.swift`: `test_AC29` で `hook.widget` の `renders` から描画された一行が `c.expected` と一致することをアサートすること。
- [MAJOR-2] `SettingsStoreIntentsAcceptanceTests.swift`: `test_AC105`〜`test_AC110` で S-10a の見た目選択行に `design/001-reading-session.md` §6 どおり `appearance.row.kinari` / `appearance.row.default` を使うこと。
- [MAJOR-3] `SettingsStoreIntentsAcceptanceTests.swift`: `test_AC89` で `settings.entryTime` も `22:45` に変更してから `relaunchPreservingStore` し、`XCTAssertEqual(settings["entryTime"] as? String, "22:45")` を検証すること。
- [MAJOR-4] `ShelfAndBookAcceptanceTests.swift`: `test_AC112` で `docs/prd/001-reading-session-awards.md` の全76件すべての期待値リストを定義し、全76件が1字違わず一致することを検証すること。
