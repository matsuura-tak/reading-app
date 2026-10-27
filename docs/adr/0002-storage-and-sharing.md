# B ADR 0002：端末内の保存と App Group 共有（SwiftData 主保存先・Application Support 配置・軽量スナップショット・保護等級）

- 状態：承認
- 書いた役：tech-lead　日付：2026-10-25
- 関係する PRD、設計メモ、契約：`docs/prd/001-reading-session.md`（AC-13〜AC-26、AC-33〜AC-41、AC-52〜AC-61、AC-71〜AC-76、AC-89〜AC-91、AC-95、AC-96、AC-101、AC-114〜AC-125、AC-130〜AC-136、AC-139〜AC-147）、`docs/adr/features/001-reading-session.md`、`contracts/widget-snapshot.schema.json`、`contracts/hooks/h02-seed.schema.json`、`contracts/hooks/h13-store.schema.json`
- 元に戻す手間：大（永続化ストアの配置場所とスキーマ構造はリリース後のマイグレーションとバックアップ互換性に直結するため）

## 背景

このアプリが端末内に永続化する利用者データは、本棚の本（今の本 0〜1 冊、積読、読み終えた本）、各晩の読書記録、しおりの履歴・現在値、進行中の読書セッション（最大 1 件）、推薦理由ごとの選択・見送り重み（5 軸）、および利用者の設定である。さらに、ロック画面ウィジェット（W-1）・小ウィジェット（W-2）・Live Activity（W-3）・コントロール（W-4）・Siri ショートカット（W-5）と連携し、端末内書誌 DB（`catalog.sqlite`、約 440〜490MB）を参照する必要がある。

特に以下の要件と受け入れ条件をすべて満たす保存・共有方式を決める必要があった。

1. **主の保存先の隔離と永続性（AC-89、G4-17）**：主の保存先はアプリの `Application Support`（`Library/Application Support/ReadingStore.store`）に置き、**主の保存先を App Group コンテナには置かない**こと（PRD 12章 セキュリティとプライバシー、G4-17）。強制終了して再起動しても本・しおり・記録・設定がすべて残ること。
2. **読込失敗時に既存データを絶対に消さない復旧（AC-90）**：起動時に主の保存先を開けないとき（H7 `store.load` 注入時など）、クラッシュせず空の画面に `store.load.error` の知らせを出し、**保存済みの既存データ（本2冊と記録3件など）を消したり空ファイルで上書きしたりせず**、次の正常起動でそのまま復元されること。
3. **個別保存失敗時のロールバック（AC-59、AC-60、AC-91、AC-95、AC-119、AC-132）**：本の追加・更新・削除・状態変更、記録の更新・削除、しおり保存、セッション開始・終了が失敗したとき、トランザクションを `rollback()` して操作前の状態を完全に保ち、`common.save.error`（または `session.start.error` / `session.save.error`）を出すこと。
4. **500 冊・5,000 件での高速表示（AC-101）とロック画面連携（AC-27〜AC-41、AC-114〜AC-125）**：本 500 冊・記録 5,000 件（本 A に 1,000 件）でも本棚（S-6）と本の画面（S-7）が 5 回平均 1.0 秒以内に開き、ロック画面中でも W-1〜W-5 がエラーなく読み書きできること。
5. **バックアップ肥大化の防止（G4-17）**：利用者データ（`ReadingStore.store`）はバックアップ対象に含める一方、再取得可能な端末内書誌 DB（`catalog.sqlite`）と再生成可能な写し（`widget-snapshot.json`）には `isExcludedFromBackup = true` を設定すること。

## 比べた案

| 案 | 良い点 | 悪い点 | 選ばなかった理由 |
|---|---|---|---|
| **案A：主の保存先は SwiftData（`VersionedSchema` `SchemaV1`、6エンティティ）でアプリの `Application Support` に置き、App Group コンテナには軽量な写し `Shared/widget-snapshot.json` とインテント状態ファイルのみを `.atomic` 書き出しする（採用）** | - 主の保存先を App Group に置かない条件（AC-89、G4-17）を完全に満たし、Widget 拡張との SQLite WAL ロック競合やマイグレーション衝突が構造的に起きない<br>- SwiftData の `ModelContext.rollback()` により、個別操作の保存失敗（AC-91）時にメモリとディスクの不整合なく即座に元の状態へ戻せる<br>- 起動時の読込失敗（AC-90）ではインメモリの空 `ModelContainer(isStoredInMemoryOnly: true)` にフォールバックするだけでディスク上の `ReadingStore.store` を一切傷つけず、次回起動でそのまま復元できる<br>- 本 500 冊・記録 5,000 件（AC-101）でもインデックス付きフェッチで 1.0 秒以内を満たし、Widget 拡張は数 KB の `widget-snapshot.json` だけを読めばよい | - 主の保存先（SwiftData）を更新するたびに、App Group の `Shared/widget-snapshot.json` を再生成して `.atomic` 書き出しする同期処理（`SnapshotWriter`）を `ReadingStore` 内で漏れなく呼ぶ必要がある<br>- テストのつなぎ口 H2（シード投入）と H13（ストア読み出し）で SwiftData エンティティと JSON Schema の相互変換コードを書く必要がある | **（採用）** |
| **案B：SwiftData データベース自体を App Group コンテナ直下に置き、本体と `ReadingWidgetExtension` の両方から直接 `ModelContainer` を開く** | - `widget-snapshot.json` への書き出しが不要になり、本体と拡張で同じ SwiftData モデルを直接クエリできる | - PRD 12章および G4-17 の「主の保存先を App Group に置かない」に明確に違反する<br>- Widget 拡張（メモリ上限 30MB）がタイムライン生成のたびに SQLite WAL を開き、本体の書き込みやマイグレーションとデッドロック・破損を起こしやすい | G4-17 と AC-89 の要件に違反し、拡張との同時アクセスによるデータベース破損リスクが高いため |
| **案C：SwiftData を使わず、App Group コンテナ内の単一 JSON ファイル（`State/state.json`）を正本として毎回全件読み書きし、破損時は別名リネームして初期化する** | - JSON Schema（H2 / H13）と保存形式が 1 対 1 になり変換コードが薄い | - 主の保存先を App Group に置くため G4-17 に違反する<br>- 読込失敗時にファイルを別名退避して空状態で上書き初期化すると、一時的な読込エラー（AC-90）で既存の本2冊と記録3件が消えてしまい AC-90 に違反する<br>- 本 500 冊・記録 5,000 件（AC-101）のたびに巨大 JSON 全体をシリアライズし直す負荷がかかる | AC-90（読込失敗時の既存データ保持と次回復元）および G4-17（主の保存先を App Group に置かない）を満たせないため |

## 決定

主の保存先には SwiftData（`VersionedSchema` `SchemaV1`）を採用し、アプリコンテナの `Library/Application Support/ReadingStore.store` に配置する。App Group コンテナ（`group.com.takumamatsuura.readingapp`）には主の保存先を置かず、ウィジェット・Live Activity・Siri 用の軽量な写し `Shared/widget-snapshot.json`（`contracts/widget-snapshot.schema.json`）と Background Assets の書誌 DB `Catalog/catalog.sqlite` のみを配置する。ファイル保護等級はどちらも `.completeUntilFirstUserAuthentication` とする。

### 1. 保存場所・保護等級・バックアップ属性の一覧

| 保存対象 | コンテナとパス | 形式 | `FileProtectionType` | `isExcludedFromBackup` |
|---|---|---|---|---|
| **主の保存先（正本）** | アプリコンテナ `Library/Application Support/ReadingStore.store`（および `-wal` / `-shm`） | SwiftData（`SchemaV1`） | `.completeUntilFirstUserAuthentication` | `false`（iCloud / Finder バックアップ対象） |
| **ウィジェット・Siri 用の写し** | App Group `group.com.takumamatsuura.readingapp` 内 `Shared/widget-snapshot.json` | JSON（`widget-snapshot.schema.json`、`Data.write(..., options: .atomic)`） | `.completeUntilFirstUserAuthentication` | `true`（主の保存先から再生成可能） |
| **端末内書誌・共起 DB** | App Group `group.com.takumamatsuura.readingapp` 内 `Catalog/catalog.sqlite` | 読み取り専用 SQLite3（FTS5 `trigram`、ADR 0004） | `.completeUntilFirstUserAuthentication` | **`true`**（Background Assets で再取得可能、G4-17） |

- **保護等級 `.completeUntilFirstUserAuthentication` の理由**：端末起動後の最初のロック解除以降は、画面ロック中であっても W-1（ロック画面ウィジェット）、W-3（夜の入口・読書中 Live Activity）、W-4（ロック画面 Control `StartReadingIntent`）、W-5（ロック画面 Siri「どこまで読んだ？」`WhereStoppedIntent`、`authenticationPolicy = .alwaysAllowed`、AC-121）がファイルを読めるようにするため。

### 2. SwiftData `SchemaV1` の 6 エンティティとドメイン規則

最初から `VersionedSchema`（`ReadingSchemaV1`、バージョン `1.0.0`）で包み、以下の 6 エンティティを定義する。

1. **`BookRecord`（本）**：
   - `id: UUID`（一意）、`isbn13: String?`（`^97[89][0-9]{10}$` または `nil`）
   - `title: String`（通常は 1〜100 書記素クラスタ、AC-8。ただし「あとで登録」`register.later` で作られた名無しの今の本 `isTitlePending == true` のときは空文字列 `""` を許容し、画面やウィジェットでは `widget.currentBookAsTitle`「今の本」を表示する、AC-139・AC-140）
   - `author: String`（0〜100 書記素クラスタ、前後空白除去済み、AC-7・AC-8・AC-92）
   - `publisher: String?`、`label: String?`、`publishedYear: Int?`、`seriesTitle: String?`、`volumeNumber: Int?`、`ndc: String?`、`cCode: String?`、`manuallyEdited: Bool`
   - `status: String`（`current` | `tsundoku` | `finished`）。`status == "current"` の本は常に最大 1 冊、`isTitlePending == true` の本も最大 1 冊（AC-13、AC-14、AC-139、AC-140）。
   - `isEbook: Bool`（既定 `false`）、`progressUnit: String`（`page` | `location` | `percent`。紙の本は常に `page`、AC-141）
   - `currentPage: Int?`（1〜9999、AC-74）、`currentLocation: Int?`（1〜999999、AC-141）、`currentPercent: Int?`（0〜100、AC-141）
   - `currentLine: String?`（前後空白除去・改行を半角空白に正規化した 1〜60 書記素クラスタ、AC-71・AC-72。数字のみ保存 `mark.pageOnly` のときは `nil` に消去する、AC-73）
   - `addedAt: Date`、`tsundokuAt: Date?`（積読並び順用、AC-13）、`updatedAt: Date`、`finishedAt: Date?`（`status == "finished"` のときのみ、AC-77）
2. **`ReadingSessionRecord`（各晩の読書記録）**：
   - `id: UUID`、`bookId: UUID`（親 `BookRecord` 削除時にカスケード削除、AC-16）
   - `startedAt: Date`、`endedAt: Date`、`timeZoneID: String`（記録時の IANA タイムゾーン識別子、例 `"Asia/Tokyo"`。後から端末のタイムゾーンが変わっても記録時のタイムゾーンと **4:00 境目** で晩の日付 `nightDate` を固定計算する、AC-22・AC-85）
   - `minutes: Int`（経過秒数 `elapsed = endedAt.timeIntervalSince(startedAt)` に対し、60 秒未満は記録を作らず破棄して `session.tooShort`、60 秒以上は `min(1440, Int(floor(elapsed / 60.0)))` で計算、1〜1440 分、AC-24・AC-25・AC-56・AC-57）
   - `entry: String`（`app` | `lock_widget` | `small_widget` | `live_activity` | `intent_start` | `intent_open`、AC-40・AC-114・AC-124）
   - `progressUnit: String`、`startPage: Int?`、`endPage: Int?`、`startLocation: Int?`、`endLocation: Int?`、`startPercent: Int?`、`endPercent: Int?`
3. **`BookmarkRecord`（しおりの保存履歴・最新状態）**：
   - `id: UUID`、`bookId: UUID`、`line: String?`（1〜60 字）、`progressUnit: String`、`page: Int?`、`location: Int?`、`percent: Int?`、`updatedAt: Date`
4. **`ActiveSessionRecord`（進行中の読書セッション、最大 1 件）**：
   - `id: UUID`、`bookId: UUID`、`startedAt: Date`、`timeZoneID: String`、`entry: String`、`startedBy: String`（`button` | `flip` | `intent`）、`liveActivityId: String?`
   - 存在するときアプリ状態は `reading`、0 件のとき `idle`（AC-52、AC-53）。
5. **`RecommendationWeightRecord`（推薦理由 5 軸の選好重み）**：
   - `axis: String`（`readers` | `nextVolume` | `sameAuthor` | `sameAward` | `sameLabel`）、`chosen: Int`（既定 0）、`skipped: Int`（既定 0）。スコア `score = chosen * 2 - skipped` の降順で理由軸の優先順を繰り上げる（AC-147）。
6. **`AppSettingsRecord`（利用者の設定、単一行）**：
   - `flipToStart: Bool`（既定 `true`、AC-50・AC-51）
   - `hideOnWidgets: Bool`（既定 `false`、AC-34・AC-120・AC-123）
   - `entryTime: String`（`"HH:mm"` 形式、15 分刻み、**既定 `"21:00"`**、AC-36・AC-38）
   - `widgetGuideShown: Bool`（既定 `false`、初回の一行保存直後に 1 回だけ案内シートを出して `true` にする、AC-96）
   - `appearanceID: String`（`default` | `kinari` | `sumi` | `shu`、既定 `"default"`、AC-105〜AC-111）
   - `isPlusPurchased: Bool`（既定 `false`、AC-106〜AC-111）

### 3. 読込失敗時の非破壊フォールバック（AC-90）と保存失敗時のロールバック（AC-91）

1. **起動時の読込失敗（AC-90）**：
   - 起動時（または H7 `-uitest-fail-save store.load:1` 注入時）に `ReadingStore.store` のオープンまたは初期フェッチが失敗した場合、**ディスク上の既存の `ReadingStore.store` ファイルを削除・移動・空上書きすることは絶対に行わない**。
   - アプリは一時的な読み取り専用インメモリ空状態（本 0 冊表示）で S-1 を立ち上げ、知らせの帯（部品 N）に `store.load.error` を表示し、App Group の `widget-snapshot.json` も上書きしない（H13 の `hook.store` は空文字列 `""` を返す）。
   - その後アプリを再起動して読込が成功した際、ディスク上にそのまま温存されていた本（例：2 冊）と記録（例：3 件）が 1 件も欠けずに復元される（AC-90）。
2. **個別操作の保存失敗（AC-59、AC-60、AC-91、AC-95、AC-119、AC-132）**：
   - `book.add`、`book.update`、`book.delete`、`book.status`、`record.update`、`record.delete`、`mark.save`、`session.start`、`session.end`、`settings.save` の保存処理でエラーが発生した場合（H7 注入を含む）、ただちに `modelContext.rollback()` を呼び出してメモリ上の変更を取り消し、`widget-snapshot.json` の書き出しや `WidgetCenter.shared.reloadAllTimelines()` も行わない。
   - 画面上部に `common.save.error`（セッション開始時は `session.start.error`、終了時は `session.save.error`）を表示し、再試行でそのまま保存できるようにする。

### 4. `PrivacyInfo.xcprivacy` の宣言
- `NSPrivacyTracking`: `false`、`NSPrivacyTrackingDomains`: `[]`、`NSPrivacyCollectedDataTypes`: `[]`（AC-103）。
- `NSPrivacyAccessedAPITypes`：`NSPrivacyAccessedAPICategoryFileTimestamp`（`C617.1`）、`NSPrivacyAccessedAPICategoryDiskSpace`（`E174.1`）、`NSPrivacyAccessedAPICategoryUserDefaults`（`CA92.1`、システムフレームワーク内部利用分）。

## いちばん強い反論と、それでも選んだ理由

- **いちばん強い反論**：「主の保存先を SwiftData（`Application Support`）にし、拡張用に App Group の `Shared/widget-snapshot.json` を別途書き出す二層構造にすると、保存のたびにスナップショット JSON を同期する手間が増え、App Group に単一の JSON や SQLite を置くより実装が複雑になるのではないか。」
- **それでも選んだ理由**：
  1. 主の保存先を App Group に置かないことは PRD 12章および G4-17 の明示的なセキュリティ・アーキテクチャ要件であり、かつ Widget 拡張（30MB メモリ上限）が本体のデータベースロックと競合してクラッシュや WAL 破損を引き起こすのを根絶できるからである。
  2. W-1・W-2・W-3・W-5 が必要とするのは「今の本 1 冊の書名・一行・進み具合と表示設定」だけであり、数 KB の `widget-snapshot.json` を `.atomic` 書き出しする形に絞ることで、ウィジェットのタイムライン生成速度（AC-102：0.5 秒以内）と Siri「どこまで読んだ？」の即時応答（AC-121）を最も速く安定して実現できるからである。

## 招く悪い結果

- **これで楽になること**：
  - 本体と拡張のプロセス間競合による DB ロックやマイグレーション破損が起きない。
  - `ModelContext.rollback()` と非破壊フォールバックにより、AC-90（読込失敗からの完全復元）と AC-91（7 通りの保存失敗ロールバック）を確実に満たせる。
- **これで難しくなること、守り続けること**：
  - 今の本・しおり・設定を変更するすべてのトランザクションのコミット直後に、`SnapshotWriter` で `Shared/widget-snapshot.json` を更新し、必要なときだけ `WidgetCenter.shared.reloadAllTimelines()` を呼ぶ規律（AC-33：しおり保存 1 回につき 1 回）を守る必要がある。
  - スキーマを変更する際は必ず `ReadingSchemaV2` と `SchemaMigrationPlan` を追加し、v1.0 のストアファイルを開く移行テストを書く必要がある。
- **元に戻すときの手順と手間**：
  - 万一 SwiftData から生の SQLite テーブル管理へ置き換える場合は、`ReadingStore` 内の永続化アダプタを差し替え、同じ `Application Support` パス上でマイグレーションを行う（手間：大、3〜5 日）。

## 見直す条件

1. G3 の性能検証（AC-101：`perf500` 本 500 冊・記録 5,000 件）において、S-6 または S-7 の表示時間が 5 回平均 **1.0 秒（1,000ms）** を超え、`FetchDescriptor` のインデックスやバッチ設定で 1 日以内に 1.0 秒以内へ短縮できない場合。
2. G3 / G4 の検証において、本体と App Intents（`StartReadingIntent` / `EndReadingIntent`）の境界で `widget-snapshot.json` と `ReadingStore.store` の不整合が **1 件でも** 再現した場合。

## 確かめたこと

- Apple SwiftData `SchemaMigrationPlan` / `VersionedSchema`：https://developer.apple.com/documentation/swiftdata/schemamigrationplan （2026-10-25 確認）
- Apple Encrypting Your App's Files（`completeUntilFirstUserAuthentication`）：https://developer.apple.com/documentation/uikit/encrypting-your-app-s-files （2026-10-25 確認）
- Apple Optimizing Your App's Data for iCloud Backup（`isExcludedFromBackup`）：https://developer.apple.com/documentation/foundation/optimizing-your-app-s-data-for-icloud-backup （2026-10-25 確認）
- スナップショットとストア契約の JSON Schema 検証（2026-10-25 実行）：
  ```text
  $ make check-contracts
  ALL PASSED: 8 schemas, 25 examples validated with 0 errors.
  ```

## 確かめ（B）
- [x] 案が2つ以上あり、どの案にも悪い点が書いてある
- [x] 反論、悪い結果、見直す条件が空でない
- [x] 確かめたことに、URL かコマンドの出力がある
