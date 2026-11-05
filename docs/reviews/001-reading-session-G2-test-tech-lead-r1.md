VERDICT: FAIL
CRITICAL: 6
MAJOR: 2
SUMMARY: テスト計画（test-plan.md）、AcceptanceTests.xctestplan、red.log、および Support/AcceptanceTestBase.swift の骨格や自己完結性（@testable import なし・sleep/skip なし・リトライなし）は基準を満たしていますが、Swift 受け入れテスト本体（ios/AcceptanceTests/*.swift）において、contracts/test-hooks.md・contracts/hooks/*.schema.json・design/001-reading-session.md 第6章で定義されたフック識別子・JSON スキーマ・accessibilityIdentifier との重大な不整合が多数存在するため FAIL と判定します。

FINDINGS:

## 指摘

### [CRITICAL-1] 未定義の `hook.*` 読み出し識別子（7種）への依存
- **根拠**: `contracts/test-hooks.md` 第1-5節および第7節で定義されている `hook.*` 要素は `hook.state`, `hook.store`, `hook.widget`, `hook.liveActivity`, `hook.shareCard`, `hook.awards`, `hook.mediaAudit`, `hook.outbound`, `hook.storekit`, `hook.intents`, `hook.error` の11種のみです。
- **問題箇所**: 以下の7種の未定義識別子を `readHookJSON(...)` で読み出しています。
  1. `hook.perf`: `PerformanceTests.swift`, `ReadingSessionAcceptanceTests.swift`, `BookmarkAcceptanceTests.swift` → H10 に従い `hook.state` の `lat.<section>` / `prevLat.<section>` を読むこと。
  2. `hook.widgets`: `PerformanceTests.swift`, `BookmarkAcceptanceTests.swift`, `FinishAndRecommendationAcceptanceTests.swift`, `SettingsStoreIntentsAcceptanceTests.swift` → H22 に従い `hook.widget` の `renders` 配列および `timeline.elapsedMs` を読むこと。
  3. `hook.events`: `ReadingSessionAcceptanceTests.swift`, `SettingsStoreIntentsAcceptanceTests.swift` → H17 に従い `hook.state` の `startedBy`, `haptic`, `announce`, `notice`, `proximity`, `entry` キーを読むこと。
  4. `hook.media`: `BookmarkAcceptanceTests.swift` → H27 に従い `hook.mediaAudit` を読むこと。
  5. `hook.share`: `FinishAndRecommendationAcceptanceTests.swift` → H24 に従い `hook.shareCard` の `cards` 配列を読むこと。
  6. `hook.urls`: `SettingsStoreIntentsAcceptanceTests.swift` → H31 に従い `hook.outbound` の `openedURLs` 配列を読むこと。
  7. `hook.liveActivities`: `SettingsStoreIntentsAcceptanceTests.swift` → H23 に従い `hook.liveActivity` を読むこと。

### [CRITICAL-2] `hook.state`（H17）のフォーマット不整合（`readHookJSON("hook.state")` の誤用）
- **根拠**: `contracts/test-hooks.md` 第1-5節および `contracts/hooks/h17-state.schema.json` の規定により、`hook.state` の `accessibilityValue` は JSON ではなくセミコロン区切りの1行 `key=value;...` 文字列です。
- **問題箇所**: `ReadingSessionAcceptanceTests.swift`, `BookmarkAcceptanceTests.swift`, `SettingsStoreIntentsAcceptanceTests.swift` で `readHookJSON("hook.state")` を呼んでおり、パースエラーになります。`readHookState()` を使い、キー名も H17 契約に合わせる必要があります。

### [CRITICAL-3] `UITEST_SEED`（H2）の JSON が `h02-seed.schema.json` に違反
- **根拠**: `contracts/hooks/h02-seed.schema.json`
- **問題箇所**: 全テストファイルの `UITEST_SEED` ペイロードに以下のスキーマ違反があります。
  - トップレベル必須キー（`schemaVersion: 1`, `books`, `records`, `activeSession`, `settings`）の欠落、および `additionalProperties: false` 違反。
  - `SeedBook` / `SeedRecord` / `SeedActiveSession` の `id` / `bookId` が UUID 形式ではなく任意文字列になっている。
  - 未定義プロパティ名の使用と必須キーの欠落（`isbn13`, `lastLine`, `page`, `progressUnit`, `location`, `percent`, `bookId`, `flipToStartEnabled`, `appearanceMode`, `plusPurchased`, `onboardingCompleted` 等）。

### [CRITICAL-4] `hook.store`（H13）の読み出し階層・プロパティ名の不整合
- **根拠**: `contracts/hooks/h13-store.schema.json` ではトップレベルは `{ "schemaVersion": 1, "dumpedAt": "...", "corruptBackupFiles": [...], "state": { "schemaVersion": 1, "books": [...], "records": [...], "activeSession": ..., "settings": {...} } }` です。
- **問題箇所**: 全テストファイルで `store["books"]` 等とトップレベル直下を参照しており（正しくは `store["state"]["books"]`）、プロパティ名も H13 スキーマと不一致です。

### [CRITICAL-5] H19・H20・H23・H25・H30・H32 の入出力 JSON がスキーマ定義と不一致
- **根拠**: `contracts/hooks/hook-config.schema.json` および `contracts/hooks/h20-ndl-stub.schema.json`。
- **問題箇所**: H19 (`UITEST_OCR`), H20 (`UITEST_NDL_STUB`), H23 (`UITEST_LIVE_ACTIVITY`), H25 (`UITEST_AWARDS`), H30 (`UITEST_STOREKIT`), H32 (`UITEST_INTENT` / `hook.intents`) のキー名・構造がスキーマと不一致です。

### [CRITICAL-6] `design/001-reading-session.md` 第6章に存在しない `accessibilityIdentifier` の使用
- **根拠**: `design/001-reading-session.md` 第6章および `contracts/test-hooks.md` 第7節。
- **問題箇所**: `tab.*`, `toolbar.bookmark`, `scan.commit`（正：`scan.addToShelf`）, `bookshelf.commit`（正：`bookshelf.addSelected`）, `record.edit.minutes` / `record.edit.save`（正：`record.minutesField` / `record.save`）, `book.records.summary`（正：`book.nights` / `book.total`）, `appearance.option.kinari`（正：`appearance.kinari`）、添字付き候補識別子、`perf500` の本 ID。

### [MAJOR-1] テスト計画（test-plan.md）に対してテスト実装が省略・形骸化している AC が存在
- **問題箇所**: `test_AC89`, `test_AC91`, `test_AC103`, `test_AC112`, および `test_AC115`, `test_AC116`, `test_AC118`, `test_AC122`, `test_AC126`, `test_AC141` のサブケース。

### [MAJOR-2] `test_AC33` のアサーション不備
- **問題箇所**: `WidgetAndActivityAcceptanceTests.swift` で `XCTAssertTrue(stateRaw.contains("1"))` としており、`readHookState()["widgetReloads"]` または `hook.widget` の `reloadRequests` を検証する必要があります。
