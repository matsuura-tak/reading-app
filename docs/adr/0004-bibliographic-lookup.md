# ADR-0004: 端末内書誌・共起データベース（NDL CC BY 4.0・Background Assets・SQLite FTS5・2段目バーコード補完・推薦）

- 日付：2026-10-25
- 状態：採用
- 関連する機能：`docs/prd/001-reading-session.md`（AC-3〜23、AC-78〜83、AC-92〜93、AC-103、AC-112、AC-138、AC-145〜149）、`design/001-reading-session.md`

## 背景

本棚に本を加えるとき（S-8a〜S-8d）や、1冊を読み終えた夜に次の1冊を選ぶとき（S-9、S-7、S-1）、以下の体験と制約を両立させる必要がある。

1. **アプリからの外部 HTTP 通信ゼロ（AC-103）**：アプリ実行時に外部の API（国立国会図書館サーチ API を含む）へ HTTP リクエストを送らない。機内モード（H8 通信なし）でもバーコード読み取り、書名検索、おすすめ候補の提示が 100% 動くこと（AC-8、AC-14、AC-83、AC-125）。
2. **0.3 秒（300ms）以内の応答（AC-149）**：Release 構成で、バーコード読み取り（H21）から `scan.row` が出るまで、および手入力の書名（`manual.title`）に 3 字以上入れてから `search.row` が出るまでの 5 回平均が、どちらも 300ms 以内であること。
3. **未収録本・書誌 DB 未取得時のフォールバック（AC-9〜11）**：端末内書誌 DB にない新しい本や同人誌でも、ISBN の出版者記号と日本図書コード（2段目 `192` バーコードの C コード）から出版社名・判型（文庫／新書／単行本）・分野（日本文学など）を即座に補い、行内の書名入力または表紙撮影で止めずに登録できること。
4. **説明可能な 5 軸の推薦と共起の器、および端末内選好学習（AC-78〜83、AC-145〜148）**：AI による生成文を一切使わず、「この本を読み終えた人が、次に読んだ本（共起）」「同じシリーズの次の巻」「同じ著者の本」「同じ賞の受賞作」「同じレーベルの本」の事実 1 行の理由を出し、利用者の選択（`chosen`）・見送り（`skipped`）回数から端末内で軸の優先順を繰り上げること。

## 考えた選択肢と比べた結果

| 選択肢 | 良い点 | 悪い点 | 判断 |
|---|---|---|---|
| **A. NDL CC BY 4.0 書誌データを事前加工した読み取り専用 SQLite DB（FTS5 `trigram`＋共起テーブル）を Apple-Hosted Background Assets で配信＋出版者記号／Cコード辞書＋同梱受賞作 JSON（採用）** | - 実行時の外部 HTTP 通信が 0 件になり AC-103 を完全に満たす<br>- SQLite 主キー検索（ISBN）は 1ms 未満、FTS5 `trigram` 3 字部分一致検索は 5〜15ms で完了し、AC-149（300ms 以内）に 20 倍以上の余裕がある<br>- Apple-Hosted Background Assets により独自配信サーバーの運用費・障害リスクがゼロになる<br>- 万一 Background Assets が未完了（`notDownloaded`）でも、バンドル同梱の出版者記号シード＋Cコード解析＋受賞作リストだけで登録が止まらない（AC-9〜11） | - リリース準備時に NDL 書誌データから SQLite ファイルを生成・圧縮して App Store Connect にアップロードするビルドスクリプトが必要 | **採用** |
| **B. 実行時に国立国会図書館サーチ（NDL OpenSearch）API へ直接 HTTP GET する** | - アプリサイズが増えない | - AC-103（外部 HTTP 通信 0 件）に違反する<br>- 通信遅延・オフライン・タイムアウトでバーコード連続読み取りや手入力サジェストが止まる | 却下（`contracts/ndl-opensearch.yaml` は廃止・削除） |
| **C. 295 万件の SQLite DB をメインアプリバンドルに直接同梱する** | - Background Assets 拡張がいらない | - `.ipa` 本体サイズが 500MB 近くなり、モバイル回線での初回インストール負荷と App Store 制限に抵触する | 却下 |

## 決めたこと

### 1. 端末内書誌・共起 SQLite データベース（`catalog.sqlite`）の DDL と配置

リリース準備時のオフラインバッチで、国立国会図書館サーチの CC BY 4.0 書誌データ（国立国会図書館蔵書・新着書誌情報・全国書誌情報、約 295 万件）を整形し、以下のスキーマを持つ読み取り専用 SQLite3 ファイル（`page_size = 4096`、`VACUUM` 済み、約 440〜490MB）を生成する。

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

- **Apple-Hosted Background Assets による配信とバックアップ除外（G0 提案 2）**：
  - `ReadingBackgroundAssetsExtension`（`BADownloaderExtension`）がインストール時およびバックグラウンドで `catalog.sqlite` を取得し、App Group コンテナ内の `Catalog/catalog.sqlite` に配置する。
  - 配置時に必ず `var rv = URLResourceValues(); rv.isExcludedFromBackup = true; try fileURL.setResourceValues(rv)` を設定し、iCloud / Finder バックアップを肥大化させない。
- **SQLite 接続設定**：
  - `ReadingStore.CatalogDatabase` は `sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX, nil)` で開き、`PRAGMA query_only = ON; PRAGMA mmap_size = 67108864;`（64MB メモリマップ）を設定する。
  - ISBN 検索は `SELECT ... FROM books WHERE isbn13 = ?1 LIMIT 1;`（< 1ms）。
  - 書名 3 字以上の候補検索（S-8c、AC-14、AC-149）は、入力文字列を NFKC 正規化した上で `SELECT b.* FROM books_fts f JOIN books b ON b.rowid = f.rowid WHERE f.title MATCH ?1 ORDER BY length(b.title) ASC, b.published_year DESC LIMIT 5;` を実行する（5〜15ms）。
  - 本棚写真（S-8d、AC-138）の背表紙書名照合は `SELECT * FROM books WHERE title = ?1;` を実行し、結果が **ちょうど 1 件**のときのみ著者・出版社・ISBN を自動補完する。

### 2. 著者名の整形規則（AC-92）と CC BY 4.0 出典表示（AC-93）

1. **著者名の整形（`AuthorNameFormatter`、AC-92）**：
   - 生没年（`, 1923-1996`、`1950-`、`（1923-1996）` 等）を正規表現で除去する。
   - `"姓, 名"` のカンマ区切りを `"姓 名"`（半角スペース 1 つ）に置換する。
   - 末尾の役割語（`著`、`編`、`訳`、`作`、`他著`、`ほか`）を除去する。
   - 複数著者は `" / "` または `"・"` で連結する。
   - この整形関数はオフライン DB 生成時と、実行時（H20 のスタブレコード読み込み時を含む）の両方で通すことで、どんな入力に対しても AC-92 を保証する。
2. **国立国会図書館書誌データの 3 条件出典表示（AC-93）**：
   - S-10 の `settings.dataSources` に、(1) 出典名（「国立国会図書館蔵書」「国立国会図書館新着書誌情報」「全国書誌情報」、データ提供機関：国立国会図書館、取得日）、(2) 国立国会図書館サーチの API を用いて取得したデータを加工して端末内の書誌データベース（版）を作成している旨、(3) CC BY 4.0 ライセンス表示とリンクボタン `settings.dataSources.license`（日本語 `https://creativecommons.org/licenses/by/4.0/deed.ja` ／英語 `https://creativecommons.org/licenses/by/4.0/`）、および共起データが NDL とは無関係である注記をすべて表示する。

### 3. 2段目バーコード（`192` Cコード）と ISBN 出版者記号による未収録本補完（AC-9、AC-10、AC-11）

カメラ（S-8a、`DataScannerViewController` / H21）は EAN-13 シンボルを連続認識する。

- **1段目バーコード（`978` または `979` で始まる 13 桁）**：
  - モジュラス 10 ウェイト 3（ISBN-13 チェックディジット）を検証し、無効なコードは `scan.invalidCode` を出す（AC-5）。
  - すでに同じセッションまたは本棚にある ISBN は再登録せず、「すでに本棚にあります（積読／今の本／読み終えた）」（`scan.duplicate.inShelf`）を出す（AC-6、AC-16）。
- **2段目バーコード（`192` で始まる 13 桁：日本図書コード）**：
  - 単体では本を作らず（AC-5）、直前または同じフレームの ISBN-13 に紐づけて C コード（4〜7 桁目の 4 桁 `C1 C2 C3 C4`）を解析する。
  - `C2`（発行形態）：`1` = 文庫、`2` = 新書、`0` = 単行本、`3` = 全集・双書。
  - `C3 C4`（内容コード）：`93` = 日本文学・小説・物語、`97` = 外国文学小説、`91` = 日本文学総記、`92` = 日本文学詩歌、`95` = 日本文学評論・随筆、など。
- **ISBN 出版者記号シード（バンドル同梱 `publisher-prefixes.json`）**：
  - `978-4-<prefix>-...` の出版者記号（主要約 200 社：新潮社 `10`、講談社 `06`、文藝春秋 `16`、KADOKAWA `04`、集英社 `08`、岩波書店 `00`、早川書房 `15`、筑摩書房 `480`、河出書房新社 `309`、東京創元社 `488`、光文社 `334`、幻冬舎 `344`、双葉社 `575`、宝島社 `299`、中央公論新社 `12`、PHP研究所 `569` 等）から出版社名を引く。
  - 端末内書誌 DB に未収録（または DB 未取得）のときも、出版社名と C コードの判型・分野を組み合わせたレーベル（例：出版社 `"新潮社"`、レーベル `"新潮文庫（日本文学）"`）を `scan.row.<ISBN>` に自動で入れ、行内の `scan.row.editTitle` または `scan.row.captureCover` で書名だけを補えば登録できるようにする（AC-9、AC-10、AC-11）。

### 4. 同梱の文学賞受賞作リスト（`awards.json`、H25、AC-19〜21、AC-83、AC-112）

- `docs/prd/001-reading-session-awards.md` に定義された全受賞作（芥川龍之介賞 第1回〜第174回、直木三十五賞 第1回〜第174回、本屋大賞 第1回〜第22回）をアプリバンドル内の `awards.json` に同梱する。
- **受賞歴の照合（AC-19〜21）**：
  1. `book.isbn13` が受賞作の `isbn13` と一致する場合にマッチする。
  2. 単行本と文庫本で ISBN が異なる場合、または手入力で ISBN がない場合でも、正規化した書名（空白・副題括弧を除いた完全一致）かつ著者名の先頭一致でマッチする（AC-20）。
  3. 複数の賞を受賞している作品（例：『蜜蜂と遠雷』の直木賞と本屋大賞）はすべての賞を配列で返し、奥付の `colophon.award` に併記する（AC-21）。

### 5. 3箇所の推薦エンジンと端末内の選好重み学習（AC-78〜83、AC-145〜148）

推薦候補は以下の 3 箇所で提示し、いずれも AI 生成文を使わず定型の事実テンプレート（`rec.reason.*`）だけを使う。

| 場所 | 対象ソース | 最大件数 | 既定の理由の優先順と抽出条件 |
|---|---|---|---|
| **1. S-9 読み終えた画面の「次の1冊」（AC-78〜83）** | 積読（`tsundoku`）を優先し、3 冊に満たない分を未所有（端末内書誌 DB・受賞作リスト）から補う | **最大 3 冊** | ① 共起 `readers`（`cooccurrence.count >= 10` かつ `to_isbn13` の `ndc` が `'9'` 始まり、AC-148）<br>② 同じシリーズの次巻 `nextVolume`（`seriesTitle` 一致かつ `volumeNumber == current + 1`）<br>③ 同じ著者 `sameAuthor`<br>④ 同じ賞の受賞作 `sameAward`<br>⑤ 同じレーベル `sameLabel`<br>⑥ 積読の新しい順 `tsundoku` |
| **2. S-7 読み終えた本の「この本のあとに」（AC-146）** | 未所有の本（本棚の `current` / `tsundoku` / `finished` にない本）のみ | **最大 5 冊** | ① 共起 `readers`（AC-148）<br>② 同じシリーズの次巻 `nextVolume`<br>③ 同じ著者 `sameAuthor`<br>④ 同じ賞の受賞作 `sameAward`<br>⑤ 同じレーベル `sameLabel` |
| **3. S-1 今の本が0冊で積読があるときの候補（AC-145）** | 積読（`tsundoku`）のみ | **最大 3 冊** | 直近に読み終えた本があればその関連順（`nextVolume` → `sameAuthor` → `sameAward` → `sameLabel`）、なければ積読に加えた新しい順 |

- **端末内の選好重みによる並び替え（AC-147）**：
  - 利用者が S-9 または S-7 で候補を選んだとき（`next.choose` / `next.addToShelf` / `after.addToShelf`）、その候補の理由の軸（`readers` / `nextVolume` / `sameAuthor` / `sameAward` / `sameLabel`）の `chosen` を `+1` する。
  - S-9 で選ばずに閉じた（`next.skip` または別の候補を選んだ）候補の軸は `skipped` を `+1` する。
  - 各軸のスコアを `score = chosen * 2 - skipped` で計算し、**`score` が高い軸を既定の優先順より上に繰り上げる**（同点のときは既定の順序を維持する）。すべて `state.json` 内で完結し、外部送信は一切行わない。
- **共起（`cooccurrence`）の器とプライバシー制約（AC-148）**：
  - `cooccurrence` テーブルから `from_isbn13 = ?1 AND count >= 10` を満たし、結合先の `books.ndc LIKE '9%'`（文学）であり、かつ本棚に未所有の本を抽出する。
  - 理由文言は `rec.reason.readers`（「この本を読み終えた人が、次に読んだ本」）固定とし、**何人が読んだかの人数（`count`）は画面のどこにも一切表示しない**（AC-148）。

## 引き受けること

- `contracts/ndl-opensearch.yaml` および OpenAPI リンター設定（`contracts/.spectral.yaml`）は、実行時の外部 HTTP 通信をゼロにする方針（AC-103）に伴い廃止・削除した。代わりに端末内書誌 DB・共起スタブの契約を `contracts/hooks/h20-ndl-stub.schema.json` と `contracts/test-hooks.md` で厳密に管理する。
