PASS

## 指摘

- **提案 1**：`contracts/dependencies.md` の受賞一覧に関する古い注記と、一部文書の終了インテント略称表記の統一
  - 場所：`contracts/dependencies.md:43`、`docs/adr/features/001-reading-session.md:126`、`docs/adr/0005-test-hooks.md:13`
  - 何が問題か：
    1. `contracts/dependencies.md:43` に「**このファイルは 2026-10-25 時点でリポジトリにない**」という r1 修正前の注記が残っている（実際には `docs/prd/001-reading-session-awards.md` が作成済み）。
    2. `contracts/test-hooks.md:56` と `contracts/hooks/hook-config.schema.json:412` では終了インテント名が `EndReadingFromActivityIntent` に統一されたが、`docs/adr/features/001-reading-session.md:126` と `docs/adr/0005-test-hooks.md:13` の説明文中に略称の `EndReadingIntent` が残っている。
  - 根拠：`docs/prd/001-reading-session-awards.md:1-89`、`contracts/hooks/hook-config.schema.json:412, 867`
  - 直す方向：G2 以降で文書を手入れする際、`contracts/dependencies.md:43` の不在注記を消し、終了インテントの表記を `EndReadingFromActivityIntent` に揃えるとより明確になる。

## 前回の指摘の追跡（r2 だけ）
| 前回の指摘 | 直った / 直っていない | 証拠 |
|---|---|---|
| **重大 1**：契約検証スクリプトの記載不一致、および受賞一覧 `docs/prd/001-reading-session-awards.md` の未作成・20行照合の未実施 | **直った** | 1. `docs/prd/001-reading-session-awards.md:1-89`（全76作品：芥川龍之介賞23行・直木三十五賞31行・本屋大賞22行）が作成された。<br>2. `docs/adr/features/001-reading-session.md:371-398` の10章に3賞計24行の公式 URL 照合記録が記載され、レビュアー自身も公式 URL（`https://bungakushinko.or.jp/award/akutagawa/list.html`、`https://bungakushinko.or.jp/award/naoki/list.html`、`https://www.hontai.or.jp/history/index.html`、`https://www.hontai.or.jp/history/hontai2024.html`）を開いて一致を確認した。<br>3. `Makefile:58-60` と `docs/adr/features/001-reading-session.md:265-270` の `make check-contracts` が外部スクリプト不使用の Python `jsonschema.Draft202012Validator` ワンライナーに統一され、`ALL PASSED: 8 schemas, 25 examples validated with 0 errors.` で通過している。 |
| **重大 2**：ADR 5本（`0001`〜`0005`）がテンプレート B の必須節を欠き、かつ古い仕様・AC 番号のまま PRD・技術設計メモ・契約と矛盾している | **直った** | `docs/adr/0001-ios-foundation.md`〜`docs/adr/0005-test-hooks.md` の全5本が刷新され、`docs/templates/adr.md:101-137` の必須節（`比べた案` の全案の悪い点、`いちばん強い反論と、それでも選んだ理由`、`招く悪い結果`、`見直す条件`、`確かめたこと`、`確かめ（B）`）をすべて満たしている。さらに、(a) 主保存先の SwiftData / `Application Support` 配置と `AC-90` 非破壊フォールバック、(b) `UIDevice.orientation == .faceDown` 1.0秒デバウンスと `CoreMotion`・近接センサー不使用、(c) 外部フォント同梱ゼロ（ヒラギノ明朝 ProN 使用）、(d) W-1/W-2 最大25字・縦書きグリフ U+FE11〜U+FE44（回転角0）・長音符のみ90度回転、(e) `scan.duplicate`・非書籍コード無視・題名＋著者の正規化完全一致による受賞照合、(f) `-uitest-*` / `UITEST_*` / `yomuma.uitest.*` / `hook.*` の全30フック（H1〜H32）および AC-1〜AC-149 との整合を確認した。 |
| **重大 3**：`h02-seed.schema.json`・`h13-store.schema.json`・`h17-state.schema.json` 間の不整合および PRD との矛盾 | **直った** | `contracts/hooks/h02-seed.schema.json` と `contracts/hooks/h13-store.schema.json` において、(1) `$id` が `urn:reading-app:contracts:hooks:h02-seed:1` と `urn:reading-app:contracts:hooks:h13-store:1` に統一され、(2) `entry` の enum が `["app", "lock_widget", "small_widget", "live_activity", "intent_start", "intent_open"]` に統一され、(3) `isTitlePending: true` のとき `title` の `minLength: 0` を許容し `false` のとき `minLength: 1` を要求する条件分岐が入り、(4) `StoredBook.tsundokuAt` が追加され、(5) `entryTime` の既定値 `"21:00"` および設定フィールド名 `widgetGuideShown`・`isPlusPurchased` が完全に一致した。 |
| **要修正 1**：`contracts/test-hooks.md` と `contracts/hooks/hook-config.schema.json` の H23・H25・H32 の定義の食い違い | **直った** | 1. H23/H32 の終了インテント名が双方で `EndReadingFromActivityIntent` に統一された。<br>2. H25 の受賞一覧シード・読み出し形式が双方で4列（`award`, `sessionOrYear`, `title`, `author`）に統一された。<br>3. H32 `WhereStoppedIntent` の `snippetTexts`（小窓）が双方で「`hideOnWidgets` のオン・オフを問わず、常時、声にも小窓にも書名と一行を一切出さず、進み具合の1文だけを出す（エラー時は空配列 `[]`）」と PRD `AC-121, AC-123, AC-133` どおりに統一された。 |

## 証拠
- 対象：`f3a87f8f7b2e36c304bc6017755809bca88629ca...13f671548aab08369cb2610d61fe605d6f337098`（観点：設計、対象機能：`001-reading-session`）
  - [x] `.gitignore`
  - [x] `CLAUDE.md`
  - [x] `Makefile`
  - [x] `contracts/dependencies.md`
  - [x] `contracts/entry-urls.md`
  - [x] `contracts/hooks/h02-seed.schema.json`
  - [x] `contracts/hooks/h13-store.schema.json`
  - [x] `contracts/hooks/h17-state.schema.json`
  - [x] `contracts/hooks/h20-ndl-stub.schema.json`
  - [x] `contracts/hooks/h22-widget.schema.json`
  - [x] `contracts/hooks/h29-outbound.schema.json`
  - [x] `contracts/hooks/hook-config.schema.json`
  - [x] `contracts/test-hooks.md`
  - [x] `contracts/widget-snapshot.schema.json`
  - [x] `design/001-reading-session.md`
  - [x] `design/001-reading-session-research.md`
  - [x] `design/001-reading-session/screens.md`
  - [x] `design/001-reading-session/tokens.md`
  - [x] `docs/adr/0001-ios-foundation.md`
  - [x] `docs/adr/0002-storage-and-sharing.md`
  - [x] `docs/adr/0003-vertical-composition.md`
  - [x] `docs/adr/0004-bibliographic-lookup.md`
  - [x] `docs/adr/0005-test-hooks.md`
  - [x] `docs/adr/features/001-reading-session.md`
  - [x] `docs/prd/001-reading-session-awards.md`
  - [x] `docs/prd/001-reading-session.md`
- 観点の表：AC-1〜AC-149 全149件の対応表・信頼境界の認可表・ADR 5本の反論検証表を確認しすべて OK。
- 実行したコマンドと結果：`make check-contracts` → `ALL PASSED: 8 schemas, 25 examples validated with 0 errors.`（終了コード 0）
- 開いた URL と確認した日付：
  - `https://bungakushinko.or.jp/award/akutagawa/list.html`（2026-10-26 確認）
  - `https://bungakushinko.or.jp/award/naoki/list.html`（2026-10-26 確認）
  - `https://www.hontai.or.jp/history/index.html`、`https://www.hontai.or.jp/history/hontai2024.html`（2026-10-26 確認）
- 未検証：なし

## 記録（指揮役が保存するときに書き足す）
- 関門：G1
- 判定した役：reviewer（観点：設計）
- 回：r2
- 対象：`001-reading-session`（`f3a87f8f7b2e36c304bc6017755809bca88629ca...13f671548aab08369cb2610d61fe605d6f337098`）
- 日付：2026-10-26
