# ADR-0002: 端末内の保存形式と App Group 共有（JSON アトミック保存・ロック画面連携・Privacy Manifest）

- 日付：2026-10-25
- 状態：採用
- 関連する機能：`docs/prd/001-reading-session.md`（AC-1〜AC-149）、`design/001-reading-session.md`

## 背景

このアプリが永続化する利用者データは、本棚の本（今の本 0〜1 冊、積読、読み終えた本）、各晩の読書記録、進行中の読書セッション（最大 1 件）、推薦理由ごとの選択・見送り重み（5 軸）、利用者の設定、およびウィジェット／Live Activity／Siri ショートカット用のスナップショットである。また、端末内書誌 DB（`catalog.sqlite`、約 440〜490MB）を本体と拡張から参照できる場所に保持する必要がある。

特に以下の受け入れ基準を確実に満たす必要がある。

1. **クラッシュ・強制終了への耐性と即時復旧（AC-47、AC-48、AC-90）**：読書中（`reading`）に強制終了しても再起動で `startedAt` から再開でき、保存ファイルが破損していてもクラッシュせず `state.corrupt-<timestamp>.json` に退避して空の本棚と `store.corrupt.recovered` の知らせで立ち上がること。
2. **ロック画面・バックグラウンドからの読み書き（AC-24〜35、AC-36〜41、AC-114〜125、AC-130〜135、AC-143）**：ロック中でも W-1（ロック画面ウィジェット）と W-3（Live Activity）が描画され、W-4（Control）や W-5（Siri「どこまで読んだ？」「読み始める」）が認証なし（`alwaysAllowed`）や画面を開かずに読み書きできること。
3. **1冊の今の本と名無しの本・電子書籍の不変条件（AC-15、AC-18、AC-58、AC-139〜141）**：`status == .current` の本は常に最大 1 冊であり、`isTitlePending == true`（あとで登録）の本も最大 1 冊に保たれること。電子書籍（`isEbook == true`）では単位（`page` / `location` / `percent`）とそれぞれの進み具合が整合すること。
4. **バックアップ肥大化の防止（G0 提案 2）**：利用者データ（`state.json`）は iCloud / Finder バックアップ対象に含める一方、Background Assets で再取得可能な端末内書誌 DB（`catalog.sqlite`）には `isExcludedFromBackup = true` を設定してバックアップ容量を圧迫しないこと。
5. **Privacy Manifest（AC-86、AC-103）**：`UserDefaults`（`CA92.1`）に頼らず、App Group コンテナ内の JSON ファイルで完結させること。

## 考えた選択肢と比べた結果

| 選択肢 | 良い点 | 悪い点 | 判断 |
|---|---|---|---|
| **A. App Group コンテナ内のバージョニング付き JSON ファイル（`state.json` と `widget-snapshot.json`）＋ `.atomic` 書き込み＋ `NSFileCoordinator`（採用）** | - 10 年間で 1,000 冊・10,000 晩を記録しても `state.json` は 2MB 未満で、メモリ展開・書き出しが数ミリ秒で終わる<br>- `Data.write(to:options:.atomic)` により書き込み途中の電源断でも旧ファイルか新ファイルのどちらかが必ず残る<br>- 破損時の別名退避（AC-90）とテストフック H2（シード投入）・H7（保存失敗注入）・H13（JSON 検証）が 1 対 1 で対応する<br>- Widget 拡張（W-1、W-2）や `WhereStoppedIntent`（W-5）は数 KB の `widget-snapshot.json` だけを読めばよく、メモリ上限に余裕がある | - 全件検索にインデックスがない（ただし利用者の本棚は数百〜数千冊規模のためメモリ配列走査で 1ms 未満。295 万件の書誌検索は別ファイルの読み取り専用 `catalog.sqlite` が担う） | **採用** |
| **B. SwiftData / CoreData（SQLite WAL）で利用者データを保存する** | - クエリやリレーション管理をフレームワークに任せられる | - WAL/SHM の破損時に単一ファイル退避（AC-90）が複雑になる<br>- 本体と Widget / Intent 拡張の同時アクセスでマイグレーション競合やロック待ちが起きやすい<br>- H2 / H13 の JSON スキーマ検証との間に変換層が増える | 却下 |
| **C. `UserDefaults(suiteName:)` に保存する** | - API が単純 | - Privacy Manifest の Required Reason API（`CA92.1`）申告が必要になる<br>- 破損退避（AC-90）やファイル単位のアトミック置換・保護レベル指定が直接制御できない | 却下 |

## 決めたこと

### 1. App Group コンテナ内のディレクトリ構成とバックアップ・保護属性

App Group 識別子を `group.com.takumamatsuura.readingapp` とし、コンテナ直下に以下を配置する。

| パス | 用途 | `FileProtectionType` | `isExcludedFromBackup` |
|---|---|---|---|
| `State/state.json` | 本棚の本、読書記録、進行中セッション、設定、推薦重みの正本 | `.completeUntilFirstUserAuthentication` | `false`（バックアップ対象） |
| `State/state.corrupt-<unix_ms>.json` | 読み込み失敗時に退避した破損ファイル（AC-90） | `.completeUntilFirstUserAuthentication` | `false` |
| `State/widget-snapshot.json` | W-1、W-2、W-3、W-5（`WhereStoppedIntent`）用の軽量スナップショット（`contracts/widget-snapshot.schema.json` 準拠） | `.completeUntilFirstUserAuthentication` | `true`（`state.json` から再生成可能） |
| `Catalog/catalog.sqlite` | NDL CC BY 4.0 書誌＋共起の読み取り専用 SQLite DB（ADR-0004） | `.completeUntilFirstUserAuthentication` | **`true`**（G0 提案 2：再取得可能なためバックアップ対象外） |

- **データ保護レベル（`.completeUntilFirstUserAuthentication`）の理由**：端末起動後の最初のロック解除以降は、画面ロック中であっても W-1（ロック画面ウィジェット）、W-3（夜の入口・読書中 Live Activity）、W-4（ロック画面 Control `StartReadingIntent`）、W-5（ロック画面 Siri「どこまで読んだ？」`WhereStoppedIntent`、`authenticationPolicy = .alwaysAllowed`、AC-121）がエラーなくファイルを読み書きできるようにするため。

### 2. 正本データ（`state.json`）のスキーマと不変条件

`state.json` のルート構造（`PersistedState`、`schemaVersion = 1`）は以下のフィールドを持つ（テストフック H2 / H13 の JSON Schema と一致）。

- **`books: [Book]`**：
  - `id: UUID`
  - `isbn13: String?`（`^97[89][0-9]{10}$` または `nil`）
  - `title: String`（1〜200 文字。`isTitlePending == true` のときは内部保持文字列として `"今の本"` を持ち、表示時に文言キー `widget.currentBookAsTitle` を使う）
  - `author: String`（0〜200 文字）
  - `publisher: String?`、`label: String?`、`publishedYear: Int?`、`seriesTitle: String?`、`volumeNumber: Int?`、`ndc: String?`
  - `status: BookStatus`（`current` | `tsundoku` | `finished`）
  - `isEbook: Bool`（既定 `false`、AC-141、AC-144）
  - `isTitlePending: Bool`（既定 `false`、`register.later` で作られた名無しの本のとき `true`、AC-139、AC-140）
  - `progressUnit: ProgressUnit`（`page` | `location` | `percent`。紙の本は常に `page`、電子書籍は選択可能、AC-141）
  - `page: Int?`（`1...9999`）、`location: Int?`（`1...999999`）、`percent: Int?`（`0...100`）
  - `lastLine: String?`（改行を空白に正規化した 1〜60 書記素クラスタ、AC-53、AC-54）
  - `createdAt: Date`、`updatedAt: Date`、`finishedAt: Date?`
- **`records: [ReadingRecord]`**：
  - `id: UUID`、`bookId: UUID`
  - `startedAt: Date`、`endedAt: Date`、`minutes: Int`（`max(1, Int(endedAt.timeIntervalSince(startedAt) / 60))`、上限 1440、AC-42、AC-46）
  - `nightDate: String`（`YYYY-MM-DD`。ローカルタイムゾーンで 04:00 未満は前日の日付に属する、AC-49）
  - `entry: SessionEntry`（`app` | `face_down` | `widget` | `live_activity` | `intent_start` | `intent_open`、AC-29、AC-39、AC-50、AC-114、AC-124）
  - `progressUnit: ProgressUnit`
  - `startPage: Int?`、`endPage: Int?`、`startLocation: Int?`、`endLocation: Int?`、`startPercent: Int?`、`endPercent: Int?`
  - `savedLine: String?`
- **`activeSession: ActiveSession?`**：
  - `bookId: UUID`、`startedAt: Date`、`entry: SessionEntry`、`liveActivityId: String?`
  - `activeSession != nil` のときアプリ状態は `reading`、`nil` のとき `idle`（AC-47、AC-48）。
- **`settings: UserSettings`**：
  - `flipToStartEnabled: Bool`（既定 `true`、AC-51）
  - `hideOnWidgets: Bool`（既定 `false`、AC-34、AC-41、AC-120、AC-123）
  - `hasShownWidgetGuide: Bool`（既定 `false`、AC-35）
  - `entryTime: String`（`"HH:mm"` 形式、15 分刻み、既定 `"22:00"`、AC-36、AC-38）
  - `appearanceID: AppearanceID`（`default` | `kinari` | `sumi` | `shu`、既定 `default`、AC-105〜107）
  - `isPlusPurchased: Bool`（StoreKit 2 購入状態キャッシュ、既定 `false`、AC-106、AC-108）
  - `recommendationWeights: [RecommendationAxis: RecommendationWeight]`（`readers`、`nextVolume`、`sameAuthor`、`sameAward`、`sameLabel` の各軸に対する `chosen: Int` と `skipped: Int`、既定すべて 0、AC-147）
  - `firstNightCompletedAt: Date?`、`seventhNightReachedAt: Date?`（NSM 判定用、AC-95、AC-96）

### 3. 不変条件とトランザクション更新手順

`ReadingRepository` のすべての変更メソッドは単一のミューテーションクロージャ内で以下の不変条件を強制してから書き出す。

1. **今の本は最大 1 冊**：ある本を `status = .current` にするとき、既存の `status == .current` の本（自分以外）はすべて自動的に `status = .tsundoku` に移す（AC-15、AC-18、AC-76、AC-82、AC-145）。
2. **名無しの本は最大 1 冊**：`isTitlePending == true` の本が存在するときは新たな `register.later` を作らず、S-1 の `bookmark.setBookTitle` から書誌を入れたときは新しい本を増やさず既存の `current` 本の `title`・`author`・書誌項目を上書きして `isTitlePending = false` にする（AC-139、AC-140）。
3. **アトミック書き込みと Widget / Live Activity 同期**：
   - `NSFileCoordinator` で排他制御した上で `state.json` を `.atomic` 書き込みし、直後に `widget-snapshot.json` を `.atomic` 書き込みする。
   - H7 で保存失敗が注入されている操作（`book.create`、`session.start`、`session.end`、`mark.save`、`record.update`、`record.delete`、`book.update`、`book.delete`、`settings.update`）では、メモリ上の状態も変更せずエラーを返し、知らせの帯（部品 N）または Siri 応答で伝える（AC-90、AC-119、AC-132）。
   - 保存成功後、`WidgetCenter.shared.reloadAllTimelines()` と `LiveActivityCoordinator.reconcile()` を呼ぶ。
4. **破損ファイルからの自動復旧（AC-90）**：
   - 起動時に `state.json` の JSON デコードまたはスキーマ検証が失敗した場合、元のファイルを `state.corrupt-<unix_ms>.json` にリネーム退避し、初期状態の `state.json` と `widget-snapshot.json` を書き出して起動する。画面上部に `store.corrupt.recovered` の知らせの帯（部品 N）を出す。

### 4. PrivacyInfo.xcprivacy の宣言

- `NSPrivacyTracking`: `false`
- `NSPrivacyTrackingDomains`: `[]`
- `NSPrivacyCollectedDataTypes`: `[]`（すべての読書データ・カメラ画像・OCR 結果は端末外へ一切送信しない、AC-69、AC-86、AC-103）
- `NSPrivacyAccessedAPITypes`:
  - `NSPrivacyAccessedAPICategoryFileTimestamp`（理由コード `C617.1`：App Group コンテナ内のファイル管理）
  - `NSPrivacyAccessedAPICategoryDiskSpace`（理由コード `E174.1`：書誌 DB 配置・書き込み時の空き容量確認）

## 引き受けること

- マイグレーションが必要になった場合は `schemaVersion` をインクリメントし、`ReadingStore` のデコーダで旧バージョンから新バージョンへの純粋関数変換を通す。
- 本体アプリと `StartReadingIntent` / `EndReadingIntent` が同時にファイルへ触れる可能性があるため、拡張側で状態を変えた直後に本体がフォアグラウンドにある場合は `scenePhase` 復帰時および Darwin Notification（`com.takumamatsuura.readingapp.stateDidChange`）で `ReadingRepository` を再読み込みする。
