PASS

## 指摘

- **重大**：0件
- **要修正**：0件
- **提案 1**：docs/prd/001-reading-session.md:1135（`AC-138`：本棚写真の背表紙文字読み取り）— `docs/reviews/001-reading-session-rethink-tech-lead.md` の実機/シミュレータ検証のとおり、標準設定（`minimumTextHeightFraction` 既定値）では背表紙の文字が16件中1件しか拾えず、`minimumTextHeightFraction = 0.005`（または `0.0`）かつ `recognitionLevel = .accurate`、`recognitionLanguages = ["ja-JP", "en-US"]` に下げることで180本中172本（95.6%）を拾えた。G1 の機能別技術設計メモ（`docs/adr/features/001-reading-session.md`）にこのパラメータ指定を明記すると実装時の手戻りを防げる。
- **提案 2**：docs/prd/001-reading-session.md:1011（`AC-92`：端末内書誌 DB の保存とバックアップ除外）— 展開後の SQLite ファイル（約440〜490MB）を App Group 共有領域に配置する際、iCloud バックアップ容量を圧迫しないよう `URLResourceValues.isExcludedFromBackup = true` を設定する旨と、`books` テーブル＋FTS5 `trigram` 仮想テーブル（`AC-4` の3字以上部分一致補完用）＋`cooccurrence` テーブル（`AC-148` 用）の DDL を G1 の ADR および `contracts/` で定義することを推奨する。

## 証拠

### 1. 確認した対象・差分・読んだファイル

- **判定対象コミット**：`2e26444`（差分：`git diff 5f690de...2e26444 -- docs/prd/`）
- **読んだファイル**：
  - `docs/prd/001-reading-session.md`（全1,460行）
  - `docs/prd/product.md`（全129行）
  - `docs/approvals/001-reading-session-G1-decisions.md`（全155行：Takuma 承認の5項目）
  - `docs/reviews/001-reading-session-expand-tech-lead.md`（全426行：Background Assets・300万件 SQLite 0.34ms・電子書籍スクショ OCR 検証）
  - `docs/reviews/001-reading-session-rec-tech-lead.md`（全317行：おすすめ拡張・好み重み付け・共起テーブルの器・電気通信事業法 K1 の検証）
  - `docs/reviews/001-reading-session-rethink-tech-lead.md`（全418行：表紙・背表紙・本棚・奥付 OCR・2段目バーコード・出版社記号の検証）
  - `docs/reviews/001-reading-session-G0-intents-tech-lead-r2.md`（全305行：前回 G0 PASS 時点の全 AC 検証）
  - `docs/org/gates.md`、`docs/templates/review-report.md`、`CLAUDE.md`

### 2. 今回の差分で変更・追加された受け入れ基準（AC）の実現性一覧表

| AC番号 | 変更種別 | 要件の要点 | 実現性判定 | 技術的根拠・SDK・スパイク検証結果 |
|---|---|---|---|---|
| **AC-2** | 変更 | ISBN（978/979）読取時、外部通信を一切行わず端末内書誌 DB（`H20`）から0.3秒以内に書名・著者・出版社・NDC・ページ数等を自動入力し1タップ追加 | **今の構成で作れる** | iOS 26.0 シミュレータ（`iPhone 17 Pro`）上で300万件ダミー SQLite（`all3m.sqlite`、487MB）に対し `isbn13 INTEGER PRIMARY KEY` 検索を実行し、中央値 **0.34ms**、p99 **3.00ms**、最大 **3.22ms** を実測済み（`expand-tech-lead.md`）。0.3秒（300ms）に対して約100倍の余裕がある。 |
| **AC-3** | 変更 | カメラ画面で「タイトルで入れる」または「写真から読み取る」へ1タップ切替 | **今の構成で作れる** | SwiftUI の画面状態遷移のみで実装可能。 |
| **AC-4** | 変更 | 手入力で書名を3字以上入れたとき端末内書誌 DB（`H20`）から最大20件候補表示し、タップで著者・出版社・ISBN等を自動入力（DB 未取得時は手入力のみ） | **今の構成で作れる** | SQLite FTS5 `trigram` トークナイザ（3文字以上の部分一致索引）で300万件に対する `MATCH` 検索が中央値 **1.40ms**、最大 **1.92ms** で応答することを iOS 26.0 シミュレータで実測済み（`expand-tech-lead.md`）。 |
| **AC-5** | 変更 | しおり画面から登録画面へ1タップ遷移、または「あとで」を選んだ時に仮の本（`isTitlePending = true`）を「いま読んでいる本」に即座に作成 | **今の構成で作れる** | SwiftData のローカルモデル操作のみで完結。外部依存なし。 |
| **AC-6** | 変更 | 「いま読んでいる本」が1冊の状態で新しい本を「いま読んでいる本」として追加しようとした時のシート（積読にする／切り替える／やめる）を端末内書誌 DB 取得・手入力・写真読取・あとで登録のすべてで共通適用 | **今の構成で作れる** | 登録経路に依存しないドメイン層の共通バリデーションと SwiftUI `.confirmationDialog` / `.sheet` で実装可能。 |
| **AC-7** | 変更 | 書名のみ必須、著者名・総ページ数は任意、端末内書誌 DB で入らなかった項目は空欄保存 | **今の構成で作れる** | SwiftData スキーマの Optional フィールド定義で対応。 |
| **AC-9** | 変更 | 端末内書誌 DB 未取得時または該当 ISBN なし時、外部通信待ち時間0秒で即座に手入力・写真読取画面へ切り替え、ISBN・出版社名（ISBN 出版社記号シード一致時）・日本図書コード（Cコード4桁：2段目バーコード読取時）を引き継ぐ | **今の構成で作れる** | `DataScannerViewController` は1フレーム内の複数 EAN-13（`978...` と `192...`）を同時返却可能。2段目バーコード先頭 `192`/`191` の4〜7桁目から Cコードを抽出する処理と、ISBN 出版社記号シード JSON からの出版社名逆引きを `rethink-tech-lead.md` で実装・検証済み。 |
| **AC-10** | 変更 | 端末内書誌 DB で書名・著者のみ入りページ数が空欄のときは入った項目だけ埋め、空欄のページ数を手入力または奥付読取で補える | **今の構成で作れる** | ローカル DB 検索結果の部分バインディングと Vision OCR の組み合わせで実装可能。 |
| **AC-11** | 変更 | 端末内書誌 DB が未取得（`notDownloaded`）のとき設定画面と手入力画面にダウンロード状態と再試行ボタン（`H28`）を出し、その間も手入力・写真読取・あとで登録が動く | **今の構成で作れる** | `AssetPackManager.shared` のステータス監視および `ensureLocalAvailability` 呼び出しを `BookCatalogDownloadPort`（`H28`）で抽象化することで実装・テスト可能。 |
| **AC-12** | 変更 | カメラ権限を「バーコード・写真から読み取る」選択時のみ要求し、写真選択（スクショ含む）は `PhotosPicker` を使い写真ライブラリ権限を求めない | **今の構成で作れる** | `AVCaptureDevice.requestAccess(for: .video)` の遅延呼び出しと、`PhotosUI.PhotosPicker`（Out-of-process ピッカーのため `NSPhotoLibraryUsageDescription` 不要）で標準対応。 |
| **AC-63** | 変更 | 電子書籍の進捗単位が「位置（Location）」または「％」のとき、対応する数値（位置：1〜999999、％：0〜100）を入力でき、ページ数設定時は従来通りページ番号（1〜9999） | **今の構成で作れる** | Book モデルの `progressUnit`（`page` / `location` / `percent`）に応じた入力バリデーションと表示フォーマットの分岐のみで実装可能。 |
| **AC-70** | 変更 | 権限要求はカメラ（バーコード・写真読取選択時のみ）と通知（設定画面で ON 時のみ）の2つに限定し、写真ライブラリ（`PhotosPicker` 使用）・位置情報・連絡先・マイク・トラッキング（ATT）は一切要求しない | **今の構成で作れる** | `Info.plist` に `NSCameraUsageDescription` のみを記載し、不要な UsageDescription や `AppTrackingTransparency` をリンクしない構成で保証できる。 |
| **AC-77〜87** | 変更 | 読了画面「つぎに読む本」候補最大3冊・決定論的選出・受賞作シード・Cコード/NDC | **今の構成で作れる** | すべてローカル SQLite / SwiftData のクエリと決定論的ソートで完結（`rec-tech-lead.md` で設計・検証済み）。 |
| **AC-92〜93** | 変更 | NDL 書誌データの Background Assets 配信と CC BY 4.0 クレジット3条件表示 | **今の構成で作れる** | iOS 26 `BackgroundAssets` フレームワークと静的テキスト・`Link` で実装可能。 |
| **AC-101〜103** | 変更 | 500冊性能1.0秒以内・外部 HTTP 通信0件 | **今の構成で作れる** | ローカル SwiftData と SQLite FTS5 `trigram`（中央値1.4ms）、独自外部通信コードなし。 |
| **AC-113, AC-137〜140** | 変更・新規 | 表紙・背表紙・本棚・奥付 OCR と「あとで」登録 | **今の構成で作れる** | Vision `RecognizeTextRequest`（revision 3, `ja-JP`/`en-US`）と `isTitlePending` フラグで完結（`rethink-tech-lead.md` で検証済み）。 |
| **AC-141〜144** | 新規 | 電子書籍の進捗単位、スクショ OCR、Live Activity からの終了 | **今の構成で作れる** | `PhotosPicker` (`.screenshots`) + `Vision` + Live Activity で完結（`expand-tech-lead.md` で検証済み）。 |
| **AC-145〜149** | 新規 | おすすめ拡張、端末内好み重み付け、共起テーブルの器、書誌 DB 検索速度0.3秒以内 | **今の構成で作れる** | ローカル重み付け、SQLite 主キー検索（0.34ms）＋FTS5 trigram（1.40ms）で完結。 |

### 3. 利用者1,000人あたりの月の費用

- **月額 $0（0円／月）**：独自バックエンドサーバーを持たず、アプリからの外部 API 通信もゼロ（`AC-103`）であり、Apple-Hosted Background Assets と StoreKit 2 は Apple Developer Program 年額費用（$99/年）の範囲内で追加従量課金なく提供される。

### 4. 実行したコマンド・未検証項目

- **実行したコマンド**：
  - `git diff --name-only 5f690de...2e26444 -- docs/prd/`
  - `git diff 5f690de...2e26444 -- docs/prd/001-reading-session.md`
  - `grep -nE '^- AC-[0-9]+：' docs/prd/001-reading-session.md | wc -l`（149件を確認）
  - `git status --short`
- **未検証**：なし
