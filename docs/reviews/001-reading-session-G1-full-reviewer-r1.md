FAIL

## 指摘

- **重大 1**：`Makefile` と技術設計メモが参照する契約検証スクリプト `scripts/check_contracts.py`、および PRD `AC-112` が G1 での照合を義務づける受賞一覧 `docs/prd/001-reading-session-awards.md` がリポジトリに存在しない
  - 場所：`Makefile:31-32`、`docs/adr/features/001-reading-session.md:27, 138-140`、`contracts/dependencies.md:43`、`docs/prd/001-reading-session.md:217, 1149`
  - 根拠：
    - `docs/adr/features/001-reading-session.md:140` は「`scripts/check_contracts.py`：`contracts/` の JSON Schema と `examples` の自動検証スクリプト（`make check-contracts` から呼ぶ）」と記載しているが、`scripts/check_contracts.py` が存在せず（`Makefile` はインライン Python で書いており、記述が食い違っている）。
    - `docs/prd/001-reading-session.md:217` および `AC-112`（`docs/prd/001-reading-session.md:1149`）は「一覧の中身が公式のページと合うかは、G1 で tech-lead が20行を行ごとの出典の URL で照らす（17）」「アプリの中の受賞の一覧が `docs/prd/001-reading-session-awards.md` の表と1行も違わない」と定めているが、`docs/prd/001-reading-session-awards.md` が未作成で存在しない。
  - 直し方：`docs/prd/001-reading-session-awards.md` を作成・配置し、G1 での20行照合を完了させること。また `Makefile` と `docs/adr/features/001-reading-session.md` の `make check-contracts` の記載を整合させること。

- **重大 2**：ADR 5本（`docs/adr/0001-ios-foundation.md`〜`docs/adr/0005-test-hooks.md`）がすべてテンプレート B（`docs/templates/adr.md:101-137`・`docs/org/gates.md:49`）の必須節を欠き、かつ古い版の AC 番号・却下済み仕様のまま放置され、PRD・技術設計メモ・デザイン・契約と全面的に矛盾している
  - 場所：`docs/adr/0001-ios-foundation.md`、`docs/adr/0002-storage-and-sharing.md`、`docs/adr/0003-vertical-composition.md`、`docs/adr/0004-bibliographic-lookup.md`、`docs/adr/0005-test-hooks.md`
  - 根拠：
    1. **テンプレート B 違反**：`docs/org/gates.md:49` と `docs/templates/adr.md:101-137` が必須とする `## いちばん強い反論と、それでも選んだ理由`、`## 見直す条件`、`## 確かめたこと`、`## 確かめ（B）`（3つのチェックボックス）が `0001`〜`0005` の5本すべてに存在しない。また `0003-vertical-composition.md:19` の案 3A は `悪い点` が `- なし` となっており、「どの案にも悪い点が書いてある」に反する。
    2. **保存方式と保存場所の矛盾（SwiftData / Application Support 対 App Group `State/state.json`）**：`CLAUDE.md:53`、`contracts/dependencies.md:22`、`docs/adr/features/001-reading-session.md:48-58`、`docs/prd/001-reading-session.md:943-950` は「主の保存先は SwiftData でアプリの Application Support に置き、主の保存先を App Group に置かない（G4-17）」と規定している。しかし `0002-storage-and-sharing.md:23-36` は「B. SwiftData / CoreData（SQLite WAL）で利用者データを保存する → 却下」とし、App Group コンテナ直下の `State/state.json` を主保存先にしている。さらに `0002-storage-and-sharing.md:36, 90` は破損時に `state.corrupt-<unix_ms>.json` にリネームして空の初期状態から起動すると規定しており、PRD `AC-90`（`store.load.error` を出し、既存の本2冊と記録3件を消さずに次の起動で復元する）に違反する。
    3. **伏せ検知のセンサー・秒数の矛盾（`UIDevice.orientation` 1.0秒 対 `CMMotionManager`＋近接センサー 3.0秒）**：`docs/prd/001-reading-session.md:939`（`AC-44, AC-45, AC-54`）と `contracts/dependencies.md:35` は「`CoreMotion` と近接センサーは使わない。伏せた向きは `UIDevice` の `faceDown` 1.0秒、`isProximityMonitoringEnabled == false`」と定めているが、`0001-ios-foundation.md:41, 71` と `0005-test-hooks.md:11, 30, 53` は `CoreMotion`（`CMMotionManager`）＋近接センサー＋3秒デバウンス（`durationMs=3100`、「3秒伏せて始める」）を規定している。
    4. **同梱フォントの矛盾**：`0001-ios-foundation.md:45-47` は OFL フォント2種（`ShipporiMinchoB1`、`KleeOne`）の同梱を規定しているが、`contracts/dependencies.md:11` と `design/001-reading-session/tokens.md:63` は「外部のフォントも入れない。書体は iOS に入ったヒラギノ明朝 ProN とシステムの書体だけ」と規定している。
    5. **縦書きの列数・字数・約物の扱いの矛盾**：`0003-vertical-composition.md:28-34` は W-1 を「1列最大20字×最大3列」、W-2 を「1列最大15字×最大3列」とし、「`…` `‥` `「」『』（）` をコード側で90度回転して描画する」としているが、`design/001-reading-session/tokens.md:68-106`・`contracts/hooks/h22-widget.schema.json:565-599`・PRD `AC-28, AC-29` は W-1/W-2 とも25字（5字×5列等）で、句読点・括弧・三点リーダーを縦書き用グリフ（U+FE11、U+FE12、U+FE41〜U+FE44、U+FE19 等）へ置換し回転角を `0` にすると規定している。
    6. **書誌・バーコード・受賞照合の矛盾**：`0004-bibliographic-lookup.md:94-95` は PRD に存在しない `scan.invalidCode` と `scan.duplicate.inShelf` を規定し（PRD `AC-3` は `scan.duplicate`、本でない JAN コードは無視）、`L109` は受賞照合を「書名一致＋著者名の先頭一致、または ISBN 一致」としているが、PRD `AC-19〜AC-21` は「題名と著者の両方が、そろえた形で一致したときだけ」と規定している。
    7. **テストのつなぎ口（H1〜H32）の方式と番号の矛盾**：`0005-test-hooks.md:21-67` は `-reading-app-test-hooks <path>` 引数・`readingapphook://` URL スキーム・`TestHooks/out/h09-events.jsonl`〜`h32-intents.json` ファイル出力を規定し、H4〜H32 の番号定義も `contracts/test-hooks.md:15-51` および PRD 11（`-uitest-*` 引数、`yomuma.uitest.*` Darwin 通知、`hook.*` アクセシビリティ要素読み出し）とまったく異なる。
    8. **AC 番号の全面的なずれ**：`0001-ios-foundation.md:13-15`、`0002-storage-and-sharing.md:57-74`、`0003-vertical-composition.md:17` など。
  - 直し方：`docs/adr/0001`〜`0005` をすべて現在の PRD（AC-1〜AC-149）、`docs/adr/features/001-reading-session.md`、`contracts/test-hooks.md` と一致させ、`docs/templates/adr.md:101-137` の必須節と `確かめ（B）` を満たすこと。

- **重大 3**：契約スキーマ（`h02-seed.schema.json`・`h13-store.schema.json`・`h17-state.schema.json`）間の不整合、および PRD（`AC-13`、`AC-36`、`AC-40`、`AC-96`、`AC-139`）との矛盾
  - 場所：`contracts/hooks/h02-seed.schema.json`、`contracts/hooks/h13-store.schema.json`
  - 根拠：
    1. **`entry` の enum の不一致**：`h02-seed.schema.json:314-322` と `h13-store.schema.json:357-365` は記録の `entry` を `["app", "face_down", "widget", "live_activity", "intent_start", "intent_open"]` としているが、`contracts/entry-urls.md:36`、`contracts/test-hooks.md:191`、`h17-state.schema.json:103-110`、`docs/adr/features/001-reading-session.md:68`、PRD `AC-40` は `["app", "lock_widget", "small_widget", "live_activity", "intent_start", "intent_open"]` と定めている。
    2. **名無しの今の本（`AC-139`）の `title` 制約の不一致**：`h02-seed.schema.json:122-125` の `BookSeed.title` が `"minLength": 1` となっており、PRD `AC-139`（「書名が空のまま `isTitlePending = true` で保存され」）および `h13-store.schema.json:152-154`（`"minLength": 0`）と矛盾し、`AC-140` の Given（「名無しの今の本が1冊ある」）を H2 シードで投入できない。
    3. **`StoredBook` に `tsundokuAt` が欠落**：`h02-seed.schema.json:249-253` の `BookSeed` には `tsundokuAt` があるのに、`h13-store.schema.json:125-281` の `StoredBook`（`additionalProperties: false`）には `tsundokuAt` が無く、`AC-13` や `docs/adr/features/001-reading-session.md:62` が定める積読追加日時を H13 で保持・検証できない。
    4. **`entryTime` 既定値の不一致**：`h02-seed.schema.json:365-370` の `SettingsSeed.entryTime` の `default` が `"22:00"` となっており、PRD `AC-36` および `h13-store.schema.json:411` の `"21:00"` と矛盾する。
    5. **`SettingsSeed` と `StoredSettings` のフィールド名不一致**：`h02-seed.schema.json:387-395` は `hasShownWidgetGuide` と `plusPurchased`、`h13-store.schema.json:430-438` は `widgetGuideShown` と `isPlusPurchased`、`contracts/test-hooks.md:118` は `widgetGuideShown` となっており、H2 と H13 で設定項目名が食い違っている。
    6. **JSON Schema の `$id` 形式の不統一**：`docs/adr/features/001-reading-session.md:28` は「すべての JSON Schema（8ファイル）に `$id`（末尾 `:1`）…を付与している」と述べているが、`h02-seed.schema.json:3` と `h13-store.schema.json:3` は `https://readingapp.local/contracts/hooks/...`（末尾 `:1` なし）になっており、他6ファイルの `urn:reading-app:contracts:...:1` と一致していない。
  - 直し方：`h02-seed.schema.json` と `h13-store.schema.json` の `entry` enum、`title` の `minLength`（`isTitlePending: false` のときだけ `minLength: 1` にする条件分岐を含む）、`StoredBook.tsundokuAt`、`entryTime` の既定値 `"21:00"`、設定フィールド名（`widgetGuideShown`、`isPlusPurchased`）、および `$id` 形式（`urn:reading-app:contracts:hooks:...:1`）を統一すること。

- **要修正 1**：`contracts/test-hooks.md` と `contracts/hooks/hook-config.schema.json` および画面仕様の間の H23・H25・H32 の定義の食い違い
  - 場所：`contracts/test-hooks.md:221, 229, 260`、`contracts/hooks/hook-config.schema.json:412, 592-632, 864-872, 908-914`
  - 根拠：
    1. **H23/H32 の終了インテント名**：`contracts/test-hooks.md:221` と `design/001-reading-session/screens.md:56` は `EndReadingFromActivityIntent` としているが、`contracts/hooks/hook-config.schema.json:412, 867` は `"EndReadingIntent"` と規定している。
    2. **H25 受賞一覧のシード形式**：`contracts/test-hooks.md:229` は `UITEST_AWARDS` の JSON 例を `[{"id": "akutagawa-155", "award": "芥川龍之介賞", "number": "第155回", "year": 2016, "title": "コンビニ人間", "author": "村田沙耶香"}]`（`number` と `year` の別フィールド）としているが、`contracts/hooks/hook-config.schema.json:592-632` の `h25AwardItem` は `required: ["award", "sessionOrYear", "title", "author"]` かつ `additionalProperties: false` であり、`test-hooks.md` の JSON を渡すとスキーマ検証エラーになる。
    3. **H32 `WhereStoppedIntent` の小窓（Snippet）の扱い**：`contracts/hooks/hook-config.schema.json:913` は `snippetTexts` を「hideOnWidgets がオンまたはエラー時は一行と書名を含まない」と説明し、`contracts/test-hooks.md:260` も「小窓には書名と一行とページを出す（ただし hideOnWidgets がオンのときは…出さない）」と記述しているが、PRD `AC-121, AC-123`（`docs/prd/001-reading-session.md:1185-1197`）および `design/001-reading-session/screens.md:93` は、`hideOnWidgets` のオン・オフを問わず**常時**小窓（`intent.snippet`）にも書名と一行を出さずページ等の1文だけを出すと定めている。
  - 直し方：`contracts/test-hooks.md` と `contracts/hooks/hook-config.schema.json` のインテント名、`h25AwardItem` のフィールド構造、`WhereStoppedIntent` の `snippetTexts` 仕様を PRD に合わせて統一すること。

## 証拠
- 対象：`f3a87f8f7b2e36c304bc6017755809bca88629ca...03d27f3490536948ee340e7acde9381a9cd26c6a`（観点：設計、対象機能：`001-reading-session`）
- 読んだファイル：`docs/prd/001-reading-session.md`、`docs/adr/features/001-reading-session.md`、`docs/adr/0001-ios-foundation.md`〜`docs/adr/0005-test-hooks.md`、`contracts/*`、`design/001-reading-session*`、`CLAUDE.md`、`Makefile`、`.gitignore`
- 実行したコマンドと結果：ローカルファイルとスキーマの直接照合で判定完結
- 開いた URL と確認した日付：なし
- 未検証：なし
