VERDICT: FAIL
CRITICAL: 6
MAJOR: 6
SUMMARY:
001-reading-session のステップ 10（G2 前の受け入れテストレビュー・視点：テスト）を実施しました。`docs/verification/001-reading-session/test-plan.md` には AC-1〜AC-149 の全 149 件の計画が記載されていますが、`ios/AcceptanceTests/` のテストコードに **(1) ファイル間で非互換なヘルパー呼び出し規約の分裂**、**(2) `contracts/test-hooks.md` に存在しない `hook.*` 読み出し要素識別子（`hook.events` / `hook.perf` / `hook.media` / `hook.widgets` / `hook.liveActivities` / `hook.share` / `hook.urls`）の広範な使用**、**(3) `design/001-reading-session.md` で廃止・不在と定められたタブバー識別子（`tab.shelf` / `tab.settings` / `tab.bookmark`）および不一致な要素識別子の使用**、**(4) `contracts/hooks/h02-seed.schema.json` に違反する `UITEST_SEED` JSON（起動時に `hook.error = H2:<path>` で全テスト停止）**、**(5) `contracts/hooks/h13-store.schema.json` や H19/H20/H23/H25/H30/H32 スキーマと不一致な JSON 読み書き**、**(6) 複数 AC における必須検証ケースの欠落と再起動後の永続化未検証** が確認されたため FAIL と判定します。

FINDINGS:
- [CRITICAL] C-1: ファイル前半（`FirstLaunchTests` / `RegistrationAcceptanceTests` / `ShelfAndBookAcceptanceTests` / `WidgetAndActivityAcceptanceTests`）と後半（`ReadingSessionAcceptanceTests` / `BookmarkAcceptanceTests` / `FinishAndRecommendationAcceptanceTests` / `SettingsStoreIntentsAcceptanceTests` / `PerformanceTests`）で `AcceptanceTestBase` のメソッド呼び出しが統一されているか・型チェックが通るかを確認すること
- [CRITICAL] C-2: `contracts/test-hooks.md` §1-5・§7 で禁止されている契約外の `hook.*` 読み出し識別子（`hook.events`, `hook.perf`, `hook.media`, `hook.widgets`, `hook.liveActivities`, `hook.share`, `hook.urls`）を排除し、H9/H10/H17（`hook.state` の 1 行文字列形式）の契約と一致させること
- [CRITICAL] C-3: `design/001-reading-session.md` §1（B-1「タブバーは持たない」）および §6-2 の要素識別子一覧に存在しない `tab.shelf`, `tab.settings`, `tab.bookmark`, `scan.commit`（正：`scan.addToShelf`）, `bookshelf.commit`（正：`bookshelf.addSelected`）, `record.edit.minutes` / `record.edit.save`（正：`record.minutesField` / `record.save`）等を修正すること
- [CRITICAL] C-4: 全テストファイルの `UITEST_SEED`（H2）ペイロードを `contracts/hooks/h02-seed.schema.json` 完全準拠（UUID 形式の `id`、`isbn13`、`lastLine`、`page`、`progressUnit`、`location`、`percent`、`bookId`、`flipToStartEnabled`、`settings.recommendationWeights` 等）にすること
- [CRITICAL] C-5: `hook.store`（H13）の読み出しで `contracts/hooks/h13-store.schema.json` の `state` ラッパー（`store["state"]["books"]` 等）を参照し、H19（`UITEST_OCR`）・H20（`UITEST_NDL_STUB`）・H23（`UITEST_LIVE_ACTIVITY`）・H25（`UITEST_AWARDS`）・H30（`UITEST_STOREKIT`）・H32（`UITEST_INTENT` / `hook.intents`）の JSON スキーマに完全準拠させること
- [CRITICAL] C-6: `AC-89`（画面操作での永続化）と `AC-103`（バーコード・書名検索・ページ撮影の各操作で外部 HTTP 通信 0 件）で AC が求める画面操作を省略せず実行すること
- [MAJOR] M-1: `AC-47`（伏せて始めるが動かない場面）で PRD AC-47 および `test-plan.md` が求める画面・シート・`session.tooShort` 表示中・起動前からの `faceDown` を検証すること
- [MAJOR] M-2: `AC-91`（保存失敗の 7 箇所：`(1) book.add`, `(2) book.update`, `(3) book.delete`, `(4) book.status`, `(5) record.update`, `(6) record.delete`, `(7) mark.save`）の全 7 箇所を検証すること
- [MAJOR] M-3: `AC-115`, `AC-116`, `AC-117`, `AC-118`, `AC-122`, `AC-126`（App Intents / Shortcuts / Control）で PRD が定める全分岐ケースを検証すること
- [MAJOR] M-4: `AC-69`（文字認識中の `mark.later` キャンセル）、`AC-73`（ウィジェットへの書名と `p.61` の反映）、`AC-76`（前のページがないときの `p.61　18分`）、`AC-141`（パーセント `34% → 52%` および位置・％の境界値 `0 / 1000000 / -1 / 101 / 0 / 100`）の検証ケースを追加すること
- [MAJOR] M-5: `AC-93`（NDL 出典・CC BY 4.0 の 3 条件、書誌データ作成時点、共起データの注記、S-2 読書中画面での非表示）および `AC-112`（同梱 `awards.json` 全 76 件と `docs/prd/001-reading-session-awards.md` の全行一致）のアサーションを強化すること
- [MAJOR] M-6: 保存・変更を伴う全テスト（`AC-65`〜`AC-67`, `AC-71`, `AC-73`, `AC-82`, `AC-83`, `AC-87`, `AC-137`〜`AC-141`, `AC-145`, `AC-146`）で `relaunchPreservingStore()` 後の永続化確認を行うこと
