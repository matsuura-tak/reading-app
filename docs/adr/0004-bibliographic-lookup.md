# B ADR 0004：端末内書誌・共起データベース（NDL CC BY 4.0・Background Assets・SQLite FTS5・2段目バーコード補完・受賞照合・推薦）

- 状態：承認
- 書いた役：tech-lead　日付：2026-10-25
- 関係する PRD、設計メモ、契約：`docs/prd/001-reading-session.md`（AC-2〜AC-11、AC-17〜AC-21、AC-77〜AC-83、AC-87、AC-92、AC-93、AC-103、AC-112、AC-138、AC-140、AC-145〜AC-149）、`docs/prd/001-reading-session-awards.md`、`docs/adr/features/001-reading-session.md`、`contracts/hooks/h20-ndl-stub.schema.json`
- 元に戻す手間：大（外部 HTTP API 廃止と Apple-Hosted Background Assets パックの構成は App Store Connect のアセット配信設定と直結するため）

## 背景

本棚に本を加えるとき（S-8a〜S-8d）や、1 冊を読み終えた夜に次の 1 冊を選ぶとき（S-9、S-7、S-1）、以下の要件と受け入れ条件を同時に満たす必要があった。

1. **アプリからの外部 HTTP 通信ゼロ（AC-103）**：アプリ実行時に外部の API（国立国会図書館サーチ API を含む）へ HTTP/HTTPS リクエストを一切送らない。通信なし（H8）でもバーコード読み取り、書名検索、おすすめ候補の提示が 100% 動くこと（AC-6、AC-62、AC-125）。
2. **0.3 秒（300ms）以内の検索応答（AC-149）**：Perf / Release 構成で、バーコード読み取り（H21）から `scan.row.<ISBN>` が出るまで、および手入力の書名（`manual.title`）に 3 字以上入れてから `search.row` が出るまでの 5 回平均が、どちらも 300ms 以内であること。
3. **未収録本・書誌 DB 未取得時のフォールバックと非書籍バーコード無視（AC-3、AC-9〜AC-11）**：重複読み取り時は `scan.duplicate`、DB 未収録時は `scan.notFound`、DB 未取得時は `scan.dbNotReady` を出し、ISBN の出版者記号と 2 段目 `192` バーコード（C コード）から出版社・判型（文庫／新書／単行本）を補って行内で書名を入力できること。本でない JAN コード（`490` 等）や 2 段目 `192` コード単体は独立した本として追加せずエラーも出さずに無視すること（AC-3）。
4. **受賞一覧の厳密な正規化照合（AC-19〜AC-21、AC-112）**：同梱の 3 賞（芥川龍之介賞・直木三十五賞・本屋大賞）との照合は、**正規化した題名と正規化した著者の両方が完全一致したときだけ**受賞歴を表示し、片方のみ一致や上下巻・派生書では表示しないこと。
5. **説明可能な 5 軸の推薦と共起の器・端末内選好重み付け（AC-78〜AC-83、AC-87、AC-145〜AC-148）**：生成 AI を使わず、定型の事実理由 1 行と `score = chosen * 2 - skipped` による優先順繰り上げを端末内で完結させること。

## 比べた案

| 案 | 良い点 | 悪い点 | 選ばなかった理由 |
|---|---|---|---|
| **案A：NDL CC BY 4.0 書誌データを事前加工した読み取り専用 SQLite DB（FTS5 `trigram`＋共起テーブル）を Apple-Hosted Background Assets で配信＋出版者記号／Cコード辞書＋同梱受賞作 JSON（採用）** | - 実行時の外部 HTTP 通信が 0 件になり AC-103 を完全に満たす<br>- SQLite 主キー検索（ISBN）は 1ms 未満、FTS5 `trigram` 3 字部分一致検索は 5〜15ms で完了し、AC-149（300ms 以内）に 20 倍以上の余裕がある<br>- Apple-Hosted Background Assets により独自配信サーバーの運用費（月額 $0）と障害リスクがゼロになる<br>- 万一 Background Assets が未完了（`notDownloaded`）でも、バンドル同梱の出版者記号辞書＋C コード解析＋行内書名入力で登録が止まらない（AC-9〜AC-11） | - リリース準備時（オフラインバッチ）に NDL 書誌データから SQLite ファイルを生成・VACUUM して App Store Connect へアップロードする前処理パイプラインが必要になる<br>- インストール直後に Background Assets のダウンロードが終わるまでの数分間は DB 未取得状態（`scan.dbNotReady`）になる場合がある | **（採用）** |
| **案B：アプリ実行時に国立国会図書館サーチ（NDL OpenSearch）API へ直接 HTTP GET する** | - 端末内に約 440〜490MB の SQLite DB を持たなくてよい | - AC-103（外部 HTTP 通信 0 件）に違反する<br>- 通信遅延・オフライン・API メンテナンスでバーコード連続読み取りや 0.3 秒以内の書名サジェスト（AC-149）が満たせない<br>- 利用者が読んでいる本の ISBN や検索語が外部へ送信される | AC-103（外部通信 0 件）と AC-149（0.3 秒検索）、およびプライバシー方針に反するため（旧 `contracts/ndl-opensearch.yaml` は廃止・削除） |
| **案C：約 295 万件の SQLite DB をメインアプリの Bundle に直接同梱する** | - `ReadingBackgroundAssetsExtension` が不要になり、初回起動の瞬間から常に DB が揃う | - アプリ本体の `.ipa` サイズが 500MB 近くなり、モバイル回線でのインストール離脱や App Store のサイズ制限リスクを招く | 初回インストールの障壁が高すぎるため |

## 決定

外部 HTTP API（旧 `contracts/ndl-opensearch.yaml`）を全廃し、NDL CC BY 4.0 書誌データ（約 295 万冊）と共起テーブルを収めた読み取り専用 SQLite3 DB（`catalog.sqlite`、FTS5 `trigram`）を Apple-Hosted Background Assets で配信する。未収録・未取得時は同梱の出版者記号辞書（`publisher-prefixes.json`）と 2 段目 `192` C コードで補完し、受賞照合は同梱 `awards.json` に対して「正規化した題名と正規化した著者の両方の完全一致」で判定する。

### 1. 端末内書誌・共起 SQLite データベース（`catalog.sqlite`）の DDL と検索
- オフライン前処理で国立国会図書館の CC BY 4.0 書誌データ（`iss-ndl-opac`、`iss-ndl-opac-inprocess`、`iss-ndl-opac-national`、約 295 万件）を整形し、以下の読み取り専用 SQLite3 ファイル（約 440〜490MB）を生成する。

```sql
CREATE TABLE catalog_meta (
    key   TEXT PRIMARY KEY,
    value TEXT NOT NULL
) WITHOUT ROWID;
-- key = 'version' (例: '2026.10'), 'retrieved_date' (例: '2026-10-01')

CREATE TABLE books (
    rowid          INTEGER PRIMARY KEY,
    isbn13         TEXT NOT NULL UNIQUE,
    title          TEXT NOT NULL,
    author         TEXT NOT NULL,
    publisher      TEXT,
    label          TEXT,
    published_year INTEGER,
    series_title   TEXT,
    volume_number  INTEGER,
    ndc            TEXT
);

CREATE INDEX idx_books_series ON books(series_title, volume_number) WHERE series_title IS NOT NULL;
CREATE INDEX idx_books_author ON books(author);
CREATE INDEX idx_books_title  ON books(title);

CREATE VIRTUAL TABLE books_fts USING fts5(
    title,
    author,
    content='books',
    content_rowid='rowid',
    tokenize='trigram'
);

CREATE TABLE cooccurrence (
    from_isbn13 TEXT NOT NULL,
    to_isbn13   TEXT NOT NULL,
    count       INTEGER NOT NULL,
    PRIMARY KEY (from_isbn13, to_isbn13)
) WITHOUT ROWID;
```

- **配置と保護**：`ReadingBackgroundAssetsExtension` が App Group コンテナ内の `Catalog/catalog.sqlite` に配置し、`isExcludedFromBackup = true` を設定する（G4-17）。`sqlite3_open_v2(..., SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX, nil)` と `PRAGMA query_only = ON;` で開く。
- **検索（AC-2、AC-4、AC-138、AC-149）**：
  - ISBN 検索：`SELECT ... FROM books WHERE isbn13 = ?1 LIMIT 1;`（1ms 未満）。
  - 書名 3 字以上の候補検索（S-8c、AC-4、AC-149）：`books_fts` の `trigram` インデックスに対して `MATCH` を実行し、最大 5 件を返す（5〜15ms）。
  - 本棚背表紙 OCR（S-8d、AC-138）：`SELECT * FROM books WHERE title = ?1;` の結果が **ちょうど 1 件** のときだけ著者・出版社・ISBN を自動補完し、0 件または複数件のときは書名のみで追加する。

### 2. バーコード連続読み取り・重複・未収録・2段目 `192` コードの規則（AC-2、AC-3、AC-9〜AC-11）
- **1 段目 ISBN バーコード（`978` または `979` で始まる 13 桁）**：
  - 読み取り成功時は触覚（`UIImpactFeedbackGenerator`）を 1 回鳴らし、端末内書誌 DB を引いて `scan.row.<ISBN>` を追加する（AC-2、AC-3）。
  - **重複時（AC-3）**：すでに今回の読み取り一覧にある ISBN、またはすでに本棚（`current` / `tsundoku` / `finished`）にある ISBN を読んだときは、新しい行を増やさず **`scan.duplicate`** の知らせを出す（PRD に存在しない `scan.duplicate.inShelf` 等のキーは使わない）。
  - **書誌 DB 未取得時（AC-9）**：Background Assets が未取得（`notDownloaded`）のときは、行に **`scan.dbNotReady`** と `scan.row.editTitle.<ISBN>` / `scan.row.captureCover.<ISBN>` を出し、その場で書名を入れて保存できる。
  - **書誌 DB 未収録時（AC-10）**：DB が `ready` だが該当 ISBN が 0 件のときは、行に **`scan.notFound`** と `scan.row.editTitle.<ISBN>` / `scan.row.captureCover.<ISBN>` を出し、その場で書名を入れて保存できる。
- **2 段目バーコード（`192` で始まる 13 桁の日本図書コード／C コード）と非書籍バーコード（AC-3、AC-11）**：
  - **`192` で始まる 13 桁の 2 段目バーコード、および `490` 等の本でない JAN コード（`978` / `979` 以外）は、それ単体では独立した本として一覧に追加せず、エラー表示（旧 `scan.invalidCode` 等）も一切出さずに無視する**（AC-3）。
  - `192` コードは ISBN-13 と対で読めたときに限り、5 桁目の発行形態（`1`＝文庫、`2`＝新書、`0`＝単行本）を抽出し、同梱の ISBN 出版者記号辞書（`publisher-prefixes.json`、例：`978-4-10-...` → 新潮社）と組み合わせて未収録本の出版社・レーベル（例：`新潮社` / `新潮文庫`）を自動補完する（AC-3、AC-11）。

### 3. 著者名の整形規則（AC-92）と CC BY 4.0 出典表示（AC-93）
- **著者名整形（`AuthorNameFormatter`、AC-92）**：NDL の `dc:creator` 等に含まれる生没年（`1909-1948` 等）、役割語（`著`、`作`、`訳`、`編`、`ほか` 等）、カンマ区切り（`"太宰, 治"` → `"太宰治"`）、空白、および 2 人目以降の著者を除去して 1 人目の著者名に整える。
- **出典表示（AC-93）**：S-10 の `settings.dataSources` に NDL CC BY 4.0 の 3 条件・DB の版と取得日・ライセンス URL（`settings.dataSources.license`）、および共起データが国立国会図書館とは無関係である注記を表示する。

### 4. 同梱受賞一覧と正規化完全一致照合（AC-17〜AC-21、AC-112）
- `docs/prd/001-reading-session-awards.md`（全 76 行：芥川龍之介賞 23 行、直木三十五賞 31 行、本屋大賞 22 行）と 1 行も違わないデータを `awards.json` としてアプリに同梱する（AC-112、H25）。
- **受賞照合の厳密規則（AC-19〜AC-21）**：
  - ISBN や著者名の先頭一致では照合しない。**「正規化した題名」と「正規化した著者」の両方が完全一致したときだけ**受賞歴を表示する（AC-19、AC-20）。
  - 正規化手順（AC-21）：Unicode NFKC 正規化 → 空白（全角・半角）除去 → 句読点・中黒・記号（`、。・！!？?` 等）除去 → 末尾または括弧内のレーベル・判型表記（`（文庫版）`、`（新潮文庫）` 等）除去。ただし巻数や上下巻・派生書を表す語（`上`、`下`、`（上）`、`（下）`、`2`、`続`、`外伝`、`ガイド` 等）は除去せず残すことで、上下巻片方や別冊に誤って受賞表示が付かないようにする（AC-20）。
  - 複数の賞を受賞している作品（『蜜蜂と遠雷』の直木三十五賞と本屋大賞）は両方の賞を返す（AC-19）。

### 5. 3 箇所の推薦エンジンと選好重み学習（AC-78〜AC-83、AC-87、AC-145〜AC-148）
- S-9「次の 1 冊」（積読優先＋未所有補完、最大 3 冊）、S-7「この本のあとに」（未所有のみ、最大 5 冊）、S-1「今の本 0 冊時の積読候補」（積読のみ、最大 3 冊）を提示する。
- 5 つの理由軸（① 共起 `readers`：`cooccurrence.count >= 10` かつ `ndc LIKE '9%'` で人数非表示、② 同じシリーズの次巻 `nextVolume`、③ 同じ著者 `sameAuthor`、④ 同じ賞 `sameAward`、⑤ 同じレーベル `sameLabel`）に対し、利用者の選択（`chosen`）と見送り（`skipped`）から `score = chosen * 2 - skipped` を計算して優先順を繰り上げる（AC-147、AC-148）。

## いちばん強い反論と、それでも選んだ理由

- **いちばん強い反論**：「約 440〜490MB の SQLite DB を Background Assets で配信する方式にすると、インストール直後にまだアセットのダウンロードが終わっていない利用者が最初の本をバーコードで読んだとき、書名が自動で入らず手入力（`scan.dbNotReady`）になってしまうのではないか。」
- **それでも選んだ理由**：
  1. アプリからの外部 HTTP 通信を 0 件（AC-103）にすることで、「自分が夜に何の本を読んでいるかが外部のどのサーバーにも一切送信されない」というプライバシーの絶対的な安心と、機内モードでも 0.3 秒以内（AC-149）で引ける速さを両立できるからである。
  2. 万一インストール直後に DB が未取得（`notDownloaded`）であっても、バンドルに同梱した軽量な出版者記号辞書（`publisher-prefixes.json`）と 2 段目 `192` C コードから出版社と判型が即座に入り、行内の書名入力または表紙撮影（AC-137）、さらには「あとで登録」（`register.later`、AC-139）で 1 秒も止めずにその晩の読書を始められるからである（AC-9〜AC-11）。

## 招く悪い結果

- **これで楽になること**：
  - 実行時のネットワークエラー・タイムアウト・レート制限・サーバー維持費（月額 $0）が完全にゼロになる。
  - FTS5 `trigram` により、書名 3 字入力からのインクリメンタル候補提示が通信なしで 5〜15ms で返る。
- **これで難しくなること、守り続けること**：
  - NDL 書誌データの更新や年 3 回（1 月・4 月・7 月）の文学賞発表に合わせて、`catalog.sqlite` と `awards.json` を更新してアプリのアップデートで配布する運用を守る必要がある。
- **元に戻すときの手順と手間**：
  - 将来オプションとしてオンライン書誌検索を追加したくなった場合は、別 PRD で同意設定と OpenAPI 契約を追加する（手間：中、2〜3 日）。

## 見直す条件

1. G3 / G4 の性能検証（AC-149、G4-10）において、`catalog.sqlite` の ISBN 検索または書名 3 字 FTS5 検索の 5 回平均が **0.3 秒（300ms）** を超えた場合。
2. 公開後 30 日（Day 30）の時点で、初回起動時の Background Assets 未取得（`scan.dbNotReady`）に遭遇して最初の本の登録を完了できなかった離脱が **初回起動者の 10% 以上** 発生した場合。

## 確かめたこと

- Apple Background Assets Framework：https://developer.apple.com/documentation/backgroundassets （2026-10-25 確認）
- SQLite FTS5 Extension（`trigram` tokenizer）：https://www.sqlite.org/fts5.html#the_trigram_tokenizer （2026-10-25 確認）
- 国立国会図書館サーチ データ提供機関・CC BY 4.0 利用条件：https://ndlsearch.ndl.go.jp/help/api/provider （2026-10-25 確認）
- 文学賞公式サイトとの 20 行照合（AC-112）：`docs/prd/001-reading-session-awards.md` の受賞作を日本文学振興会（`https://bungakushinko.or.jp/award/akutagawa/list.html`、`https://bungakushinko.or.jp/award/naoki/list.html`）および本屋大賞公式ページ（`https://www.hontai.or.jp/history/index.html`）と照合し、24 行の完全一致を確認して `docs/adr/features/001-reading-session.md` 10章に記録済み（2026-10-25）。

## 確かめ（B）
- [x] 案が2つ以上あり、どの案にも悪い点が書いてある
- [x] 反論、悪い結果、見直す条件が空でない
- [x] 確かめたことに、URL かコマンドの出力がある
