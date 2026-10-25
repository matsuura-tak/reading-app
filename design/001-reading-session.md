# 画面の仕様：001-reading-session（よむま）

- PRD：docs/prd/001-reading-session.md（AC-1〜AC-149）
- 調査：design/001-reading-session-research.md（R-1〜R-87）
- 方向性の承認：案A「白い紙と墨」（2026-10-19 に Takuma 承認済み。2026-10-20〜2026-10-25 の決定 `docs/approvals/001-reading-session-G1-decisions.md` により、端末内書誌 DB・表紙/背表紙/本棚/奥付/ページ/スクショ OCR・あとで登録・電子書籍対応・おすすめ3か所と好み重み付けと共起の器・夜の入口の予約 Live Activity・App Shortcuts と Control・ふりかえりとカード・有料の見た目「よむま＋」を含む AC-1〜AC-149 の全範囲を v1.0 として規定）
- トークンの値：design/001-reading-session/tokens.md
- 各画面の文字の図：design/001-reading-session/screens.md

## 1. 画面の流れ（テキスト図）

タブバーは持たない（B-1、決定 1）。アプリの根は `S-1 しおりの画面` 1つで、毎晩の読書は「ロック画面・StandBy・予約 Live Activity の一行を見る → 押して開く（または Control・Siri で直接始める）→ 伏せるか押す → 起こして終える → しおりを挟む → 結果」の1本の流れで終わる。本棚、登録、読み終えた画面、設定、見た目の選択と購入は、必要なときにだけ押し出し（NavigationStack）かシート（`.sheet`）で開く。

### 1-1 毎晩の流れ（読む・挟む）
```
[W-1 ロック画面のウィジェット（accessoryRectangular）]
[W-2 ホーム画面 / StandBy のウィジェット（systemSmall）]
[W-3 夜の入口の予約 Live Activity（waiting：書名・一行・ページ）]
   │ 押す（yomuma://open?entry=lock_widget | small_widget | live_activity）
   ▼
[S-1 しおりの画面（idle）]  ◄── [W-5 Siri「続きを読む」]（entry=intent_open）
   ├─ 本0冊：空の状態 ──「本を加える」(bookmark.addBook)──► [S-8 本を加える（シート）]
   ├─ 今の本なし・積読あり：積読から最大3冊 (bookmark.noCurrent.next.<id>)
   │     ├─「この本を読む」(bookmark.noCurrent.choose) ──► その場で今の本になり通常表示へ
   │     └─「本棚から選ぶ」(bookmark.openShelf) ────────► [S-6 本棚]
   ├─ 今の本なし・積読0冊：空の状態 ──「本棚から選ぶ」──► [S-6 本棚]
   ├─ 名無しの今の本（isTitlePending=true）：
   │     └─「書名を入れる」(bookmark.setBookTitle) ─────► [S-8 本を加える（今の本を更新するシート）]
   │
   ├─ ツールバー左「本棚」(toolbar.shelf) ──────────────► [S-6 本棚（押し出し）]
   ├─ ツールバー右「設定」(toolbar.settings) ───────────► [S-10 設定（押し出し）]
   ├─「どこまで読んだかを入れる」(bookmark.setMark) ────► [S-3 しおりを挟む（シート、記録は作らない）]
   ├─「読み終えた」(bookmark.finish) ───────────────────► [S-9 読み終えた画面（シート）]
   │
   │ (a)「読み始める」(bookmark.start) を押す
   │ (b) iPhone を画面を下にして置き 1.0秒（触覚 start 1回＋読み上げ1回）
   │ (c) [W-4 コントロール (control.startReading)] / [W-5 Siri「読み始める」]（entry=intent_start）
   ▼
[S-2 読書中の画面（reading）] ＋ [W-3 読書中の Live Activity（reading：書名・経過時間・終える）]
   │（ナビゲーションバーなし、画面内の押せる要素は「終える」1つだけ。画面は自動で消える）
   │（電子書籍 isEbook=true のときは「この iPhone で読むときも、アプリを閉じたままで大丈夫です」を出す）
   │
   │「終える」(reading.end) または Live Activity の「終える」(liveActivity.end)
   ├── 経過が 60秒未満 ──► 記録を作らず [S-1] に戻り、知らせ `session.tooShort`
   ├── 端末の時刻が読み始めより前 ──► 記録を作らず [S-1] に戻り、知らせ `session.invalidTime`
   └── 経過が 60秒以上（1440分で上限。保存はここで行う）
          │（Live Activity の「終える」でアプリを前に出せない状態なら記録だけ残し、次に開いたとき S-1）
          ▼
       [S-3 しおりを挟む画面（5つの道）]
          ├─「ページを撮る」(mark.photo) ───────────────► [S-3c 写真・スクショから一行を選ぶ]
          │     （カメラ拒否なら S-3 内に `camera.denied` と `camera.openSettings` を出す）
          ├─「スクリーンショットから選ぶ」(mark.screenshot) ► PhotosPicker(.screenshots) ──► [S-3c]
          ├─「一行を入れる」(mark.manual) ──────────────► [S-3a 一行とページ（位置・％）を入れる]
          ├─「ページだけ入れる」(mark.pageOnly) ────────► [S-3b ページ（位置・％）だけ入れる]
          └─「あとで挟む」(mark.later) ─────────────────┐（しおりは前のまま）
                                                        ▼
                                             [S-4 読書の結果の画面]
                                             （p.43 → p.61 / 位置1200 → 位置1450 / 34% → 52%　18分）
                                             （1440分超えのときは知らせ `session.capped`）
                                                        │
                                                        │「閉じる」(result.close)
                                                        ▼
                                             [S-1 しおりの画面（idle）]
                                             （最初に一行を保存した直後の1回だけ
                                               [S-5 ロック画面への置き方の案内] をシートで出す）
```

### 1-2 登録の流れ（S-8 本を加えるシート）
```
[S-8 本を加える（シート。S-1 の bookmark.addBook、S-6 の shelf.addBook、S-9 の next.addBook から開く）]
   │（S-1 の bookmark.setBookTitle から開いたときは「今の本の書名を入れる」モードになり、新しい本を増やさず今の本を更新する）
   │
   ├─ 1.「バーコードを続けて読む」(register.barcode)
   │     ├── カメラ許可が未決定 ──► システムの許可ダイアログ
   │     ├── カメラ許可が拒否 ────► S-8 内に `camera.denied` ＋「設定を開く」(camera.openSettings)
   │     └── カメラ許可が許可 ────► [S-8a バーコードを続けて読む]
   │                                  ├─ 1段目 ISBN（978/979）＋2段目 Cコード（192）を連続読み取り
   │                                  ├─ 端末内書誌 DB（H20）にあれば 0.3秒以内に書名・著者・出版社・レーベルが埋まる
   │                                  ├─ DB 未取得（`scan.dbNotReady`）または DB にない（`scan.notFound`）とき：
   │                                  │    （2段目 Cコードがあれば判型、ISBN 出版社記号が一致すれば出版社名を自動セット）
   │                                  │    ├─ 行内の `scan.row.editTitle` でその場で書名を入れる
   │                                  │    └─ 行内の `scan.row.captureCover` で [S-8b 表紙・背表紙を撮る] へ（ISBN 等を引き継ぐ）
   │                                  └─「n冊を本棚に加える」(scan.addToShelf) ──► シートを閉じて保存
   │
   ├─ 2.「表紙・背表紙を撮る」(register.cover)
   │     └── カメラで1枚写す ──► [S-8b 表紙・背表紙・スクショから書名と著者を選ぶ]
   │                               ├─ 読み取った行 `cover.ocr.line.<n>` を1タップ目で書名（`cover.selectTitle`）、
   │                               │  2タップ目で著者（`cover.selectAuthor`）に入れ、欄で手直しできる
   │                               └─「保存」(cover.save) ──► シートを閉じて保存
   │
   ├─ 3.「スクリーンショット・写真から選ぶ」(register.screenshot / register.photo)
   │     └── PhotosPicker（写真権限不要）で1枚選ぶ ──► [S-8b 表紙・背表紙・スクショから書名と著者を選ぶ]
   │
   ├─ 4.「本棚・積読をまとめて撮る」(register.bookshelf)
   │     └── カメラで本棚や積読の山を1枚写す ──► [S-8d 本棚の写真から複数冊を選ぶ]
   │                                               ├─ 背表紙の行を押すごとに候補行 `bookshelf.row.<n>` を追加
   │                                               ├─ 端末内書誌 DB（H20）で完全一致1件なら著者・出版社・ISBN を自動補完
   │                                               └─「選んだn冊を積読に加える」(bookshelf.addSelected) ──► 積読に一括保存
   │
   ├─ 5.「手で入れる・書名で探す」(register.manual) ──► [S-8c 手で入れる（端末内書誌 DB 候補補完つき）]
   │                                                     ├─ `manual.title` に3字以上入れると 0.3秒以内に DB から最大20件の
   │                                                     │  候補 `search.row.<ISBN>` を表示（0件なら `search.noResults`）
   │                                                     ├─ 候補を押すと書名・著者・出版社・レーベル・出版年・ISBN を欄に自動入力
   │                                                     ├─ 候補を選ばずにそのまま `manual.author` 等を入れても保存できる
   │                                                     ├─ 電子書籍の切り替え `manual.isEbook` と単位 `mark.progressUnit`
   │                                                     └─「保存」(manual.save) ──► シートを閉じて保存
   │
   └─ 6.「あとで（すぐ読み始める）」(register.later)
         （今の本が0冊で、かつ `isTitlePending = true` の本が本棚に0冊のときだけ表示）
         └── 押すと文字入力なしで `isTitlePending = true` の今の本（表示名「今の本」）を1冊作り、
             シートを閉じてその場で [S-2 読書中の画面（reading）] を始める
```
- **置き場所の決まり（AC-2〜AC-7、AC-137〜AC-139）**：
  - 本棚に `current` の本が0冊のときに1冊加えた場合（`register.barcode` で1冊、`register.cover`、`register.screenshot`、`register.manual`、`register.later`）は、その本を `current` にする。
  - 本棚にすでに `current` の本が1冊あるときに加えた場合、または複数冊まとめて加えた場合（`register.barcode` で2冊以上、`register.bookshelf`）は、加えた本を `tsundoku` にし、今の本は変えない。ただし1冊だけ加える道で「今の本として読むか、積読にするか」を切り替える確認シート（`register.currentConflict`：積読に加える／今の本に切り替える／やめる）を出せる場合（本棚の今の本が `isTitlePending = true` の名無しの本のときは、先にその本の書名を入れるか確認するガード `book.pendingTitleGuard` を出す）。

### 1-3 本棚、本の画面、読み終えた画面、設定、見た目と購入の流れ
```
[S-6 本棚（今の本 / 積読 / 読み終えた）]
   ├─ ツールバー右「＋」(shelf.addBook) ──► [S-8 本を加える（シート）]
   └─ 本の行 (shelf.row.<id>) を押す
         ▼
      [S-7 本の画面]
         ├─ 奥付 (book.colophon)：書名、著者、出版社（レーベル）、出版年、受賞 (colophon.award)
         ├─「奥付を撮って補う」(colophon.capture / book.captureColophon) ──► [S-7c 奥付を写す（シート）]
         ├─ 記録の一覧：何晩・合計時間、各晩の行 (book.record.row.<id>) ──押す──► [S-7b 記録を直す（シート）]
         ├─（読み終えた本 finished のときだけ）「この本のあとに」(after.header)
         │     └─ 未所有の候補最大5冊 (after.candidate.<ISBNまたは受賞ID>)
         │          └─「積読に加える」(after.addToShelf) ──► その場で積読に加わり `after.added` に変化
         ├─ ツールバー右「直す」(book.edit) ──► [S-7a 本を直す（シート）]
         ├─「この本を消す」(book.delete) ──► 確認ダイアログ ──► 消して [S-6] に戻る
         └─ 下端「この本を読む」(book.readThis) ──► その本を `current` にして [S-1] に戻る
             （別の名無しの本 `isTitlePending = true` が `current` のときは確認ダイアログ `book.pendingTitleGuard`）

[S-9 読み終えた画面（S-1 の bookmark.finish から開くシート）]
   ├─ 見出し「読み終えました」
   ├─ ふりかえりの1行 (finish.reflection：記録1件以上あるときだけ。AI 不使用の定型文)
   ├─ 奥付 (finish.colophon) ＋「奥付を撮って補う」(colophon.capture) ──► [S-7c 奥付を写す]
   ├─「読み終えのカードを共有」(finish.card.share) ──► システムの共有シート（PNG 画像1枚）
   ├─ 次の1冊（最大3冊：next.candidate.<id>）
   │     ├─ 積読の本：「この本を読む」(next.choose) ──► その本を `current` にしてシートを閉じ [S-1] へ
   │     ├─ 未所有の本（書誌 DB / 受賞一覧 / 共起テーブル）：「積読に加える」(next.addToShelf) ──► 積読に加える
   │     └─「今は読まない」(next.skip) ──► 候補を見送り（端末内の好み重み付け skipped を +1）シートを閉じる
   └─（候補が0件のとき）空の状態 `next.empty.message` ＋「本を加える」(next.addBook) ──► [S-8]

[S-10 設定（S-1 の toolbar.settings から押し出し）]
   ├─ 読み始め：伏せて始める (settings.flipToStart)、夜の入口の時刻 (settings.entryTime：15分刻み)、
   │            Live Activity オフ時の案内 (settings.liveActivity.off)
   ├─ ロック画面：一行と書名を隠す (settings.hideOnWidgets)
   ├─ 見た目と購入：「見た目」(settings.appearance) ──► [S-10a 見た目と「よむま＋」]
   │                「購入を復元する」(settings.restorePurchases)
   ├─ 書誌データ：端末内書誌 DB の状態 (catalog.status / settings.h20Status) と再試行 (catalog.retry / settings.h20Retry)
   └─ 情報：プライバシーポリシー (settings.privacyPolicy)、書誌の出どころ (settings.dataSources)、
            ライセンス (settings.dataSources.license)
```

---

## 2. PRD の受け入れ基準との対応

PRD の受け入れ基準 AC-1〜AC-149（全149件）を、漏れなく画面と要素・操作に結び付ける。

| AC | 画面 | 要素と操作 |
|---|---|---|
| AC-1 | S-1 | 初回起動（本0冊）。`ContentUnavailableView` に `bookmark.empty.message` と `bookmark.addBook` が1つずつ出る。`bookmark.start`、システムの許可アラート、サインイン、案内画面は0個 |
| AC-2 | S-1、S-8、S-8a | `bookmark.addBook` → `register.barcode` → H21 で ISBN I1 を流す → 端末内書誌 DB（H20）から 0.3秒以内に `scan.row.9784101000015` に書名・著者・出版社・レーベルが入る → `scan.addToShelf` を押すと `current` になり、S-1 の `bookmark.title` に「こころ」が出る。外部通信（H29）は0件 |
| AC-3 | S-8a | `register.barcode` で複数の ISBN と2段目 Cコード（`1920193006001`）と本でないコード（`4901234567894`）を流す。新しい ISBN ごとに触覚 `haptic.barcodeRead` が1回と `scan.row.<ISBN>` が増え、2段目コードは単独の行にならず直前の本の判型（「文庫」）を補う。既登録の本は `scan.duplicate` を出し、同じ回の2度目と本でないコードは無視する。`scan.addToShelf` で `tsundoku` に加わる |
| AC-4 | S-8、S-8c | `register.manual` → `manual.title` に3字以上（「人間失格」）を入れる → 端末内書誌 DB（H20）から候補 `search.row.<ISBN>`（`search.row.9784040000053` など）が出る → 候補を押すと書名・著者・出版社・レーベル・出版年・ISBN が欄に入り、`manual.save` で保存される |
| AC-5 | S-8c | `manual.title` に DB にない書名（「あいうえおかきくけこ」）を入れると、`search.row` は0個で `search.noResults` が1つ出る。そのまま `manual.save` を押すと手入力のまま保存される |
| AC-6 | S-8a、S-8c | 機内モード（H8 通信なし）でも、`register.barcode` と `register.manual` の候補表示は端末内書誌 DB（H20）でその場で動き、エラーは0個、外部通信（H29）は0件 |
| AC-7 | S-8c | `manual.title`（「 羅生門　」）と `manual.author`（「芥川龍之介」）を入れ、候補を選ばずに `manual.save` を押すと、前後の空白（半角・全角）を除いて保存される |
| AC-8 | S-8c | `manual.title` が空・空白のみ・101字以上のときは欄の下に `book.title.invalid`、`manual.author` が101字以上のときは `book.author.invalid` が出て保存しない。100字ちょうど、および著者が空のときは保存できる |
| AC-9 | S-8a | 端末内書誌 DB が `notDownloaded`（H20）のときに ISBN を読むと、行に `scan.dbNotReady` と `scan.row.captureCover`、`scan.row.editTitle` が出る。`scan.row.editTitle` に書名を入れて `scan.addToShelf` を押すと、その書名と ISBN で保存される |
| AC-10 | S-8a | 端末内書誌 DB にない ISBN を読むと、行に `scan.notFound` と `scan.row.captureCover`、`scan.row.editTitle` が出る。`scan.row.editTitle` に書名を入れて `scan.addToShelf` を押すと保存される |
| AC-11 | S-8a | DB にない ISBN（`9784003101018`）と2段目バーコード（`1920193006001`）を読むと、同梱の出版社記号辞書から出版社「岩波書店」、Cコードから形態「文庫」が候補に入り、`scan.row.editTitle` で書名を入れて `scan.addToShelf` で保存される |
| AC-12 | S-8 | カメラ許可が拒否（H26）のときに `register.barcode` または `register.cover` を押すと、カメラ画面は開かず S-8 内に `camera.denied` と `camera.openSettings` が出たまま、`register.screenshot` と `register.manual` を押せる |
| AC-13 | S-1、S-6 | S-1 の `toolbar.shelf` を押すと S-6 が開き、`shelf.current`（1冊）、`shelf.tsundoku`（積読に加えた日時の新しい順）、`shelf.finished`（読み終えた日時の新しい順）の3区分が出る |
| AC-14 | S-6、S-7、S-1、W-1 | S-6 から積読または読み終えた本の S-7 を開き、下端の `book.readThis` を押すと、その本が `current`、前の今の本が `tsundoku`（しおりは保持）になり、S-1 と W-1（H22）が新しい今の本に替わる |
| AC-15 | S-7、S-7a | S-7 の `book.edit` を押すと S-7a がシートで開く。`book.edit.title` と `book.edit.author` を直して `book.edit.save` を押すと、S-6 と S-7 の奥付が更新され、記録はそのまま残る |
| AC-16 | S-7、S-1、W-1 | S-7 の `book.delete` を押すと確認ダイアログに `book.delete.confirm`（記録の件数入り）が出る。`book.delete.confirmButton`（「消す」）を押すと本と記録が消え、今の本が0冊なら S-1 に `bookmark.noCurrent.message`、W-1 に `widget.empty` が出る |
| AC-17 | S-7 | S-7 の `book.colophon` の中に、上から `colophon.title`、`colophon.author`、`colophon.publisher`（レーベルがあれば「出版社（レーベル）」）、`colophon.year`、`colophon.award`（H25 の受賞一覧と一致した賞・回/年）の最大5行が出る |
| AC-18 | S-7 | 奥付の項目（著者、出版社、出版年、受賞）が空のときは、その行自体を出さず、「不明」「なし」「受賞なし」の文字は0個 |
| AC-19 | S-7、S-9 | 受賞の照合（H25）：書名と著者の両方が（空白を除いて）一致したときだけ `colophon.award` に「第155回 芥川龍之介賞」などを出す |
| AC-20 | S-7、S-9 | 受賞の照合：書名だけ・著者だけの一致、上下巻（「鹿の王 上」）、派生書（「―創作ノート」）では `colophon.award` を出さない |
| AC-21 | S-7、S-9 | 受賞の照合：全角カンマと読点、末尾の括弧つきレーベル名「（文春文庫）」や「［新装版］」の違いを正規化して照合し、`colophon.award` を出す |
| AC-22 | S-7 | S-7 の記録一覧 `book.record.row.<id>` は、記録時のタイムゾーン（4:00 境目）で決まった「晩の日付」の新しい順に並び、端末のタイムゾーンを変えても晩の日付と「4晩」「85分」は変わらない |
| AC-23 | S-7 | 記録が0件の本では、記録の節に `book.records.empty` が1つ出て、`book.record.row` は0個 |
| AC-24 | S-7、S-7b | `book.record.row.<id>` を押すと S-7b がシートで開く。`record.minutesField` を直して `record.save` を押すと、その記録の分数と本の合計時間が更新される |
| AC-25 | S-7b | `record.minutesField` に 0、1441以上、空、小数を入れ `record.save` を押すと `record.minutes.invalid` が出て保存しない。全角数字「１２」、1、1440 は保存される |
| AC-26 | S-7b | S-7b の `record.delete` を押し、確認ダイアログで `record.delete.confirmButton`（「消す」）を押すと記録が1件消え、合計時間と何晩が更新される |
| AC-27 | W-1 | ロック画面の `accessoryRectangular`（153×68 pt と 172×76 pt）に縦書きの一行と左下の `p.61` が欠けずに出る。押したときの URL は `yomuma://open?entry=lock_widget` |
| AC-28 | W-1、W-2 | 縦書きの組み方：句読点とかぎ括弧は縦書き用の字形（U+FE11、U+FE12、U+FE41、U+FE42）に置き換え、「ー」は90度回し、列は右から左へ並び、行頭禁則の字が列の先頭に来ない |
| AC-29 | W-1、W-2、S-1 | 26字以上の一行は、ウィジェットでは13〜25字目の最後の「、」「。」で切るか、なければ24字＋「…」に縮める。S-1 の `bookmark.line` には全文が出る |
| AC-30 | W-1、W-2、S-1 | ひらがな・カタカナ・漢字を1字も含まない一行（「It was raining.」）は、縦の列に分けず横書きで出す |
| AC-31 | W-1、W-2 | 今の本に一行がないときは、書名と `p.120`（ページもなければ書名だけ）を横書きで出す |
| AC-32 | W-1、W-2 | 今の本がないとき（本0冊または積読・読了のみ）は、`widget.empty` の文だけを出す |
| AC-33 | S-3a、S-3b、S-3c、W-1、W-2 | しおりを保存して S-1 に戻るまでに `WidgetCenter.shared.reloadAllTimelines()` が1回呼ばれ、W-1・W-2 の中身が新しい一行とページになる |
| AC-34 | S-10、W-1、W-2、W-3 | S-10 で `settings.hideOnWidgets` をオンにすると、W-1、W-2、W-3（Live Activity）のどれにも書名と一行を出さず、`widget.hidden`（「しおり」）とページ（または経過時間）だけを出す。S-1 の `bookmark.line` にはそのまま出る |
| AC-35 | W-2 | `systemSmall`（148×148 pt と 170×170 pt、ホーム画面と StandBy）に縦書きの一行と `p.61` が欠けずに出る。押したときの URL は `yomuma://open?entry=small_widget` |
| AC-36 | W-3、S-3a〜S-3c | 今の本があり Live Activity が使えるとき、しおりを保存すると前の予約を取り消して次の夜の入口の時刻（既定 21:00）を `start` にした予約 Live Activity（中身は書名・一行・ページ）を1件入れる |
| AC-37 | W-3、S-10 | OS の設定で Live Activity が切れているとき（`areActivitiesEnabled == false`）、予約要求は0件でアラートも出さず、S-10 の夜の入口の節に `settings.liveActivity.off` を出す |
| AC-38 | S-10、W-3 | S-10 の `settings.entryTime` で夜の入口の時刻を 00、15、30、45 分の15分刻みで変えられ、変えると予約 Live Activity の開始時刻がその時刻になる |
| AC-39 | S-1 | 予約 Live Activity がない晩にアイコンから起動しても、S-1 に `bookmark.line`、`bookmark.page`、`bookmark.start` が出て、伏せる監視がオンになり、自動のシートやアラートは0個 |
| AC-40 | W-1、W-2、W-3、S-1 | 入口の URL（`lock_widget`、`small_widget`、`live_activity`）で開いてから、後ろに回らず 300秒以内に始まった読書にはその入口の印が付き、301秒以上または後ろに回ったあとやアイコン起動では `app` が付く |
| AC-41 | W-3、S-1、S-2、S-3b | 予約 Live Activity が表示中に読み始めると、Live Activity が `reading` の形（書名・経過時間・`liveActivity.end` の1ボタン、一行とページは出さない）に更新され、終えてしおりを保存すると「10分」「p.61」の結果を出して終わる |
| AC-42 | S-1、S-2 | S-1 から `bookmark.start` を1回押すだけで `reading`（S-2）になり、途中に文字入力欄、確認ダイアログ、シート、ピッカー、メニューは0個 |
| AC-43 | S-2 | S-2 には今の本の書名（`reading.title`）、始めた時刻（`reading.startedAt`）、説明（`reading.note`、電子書籍なら `reading.ebookNote`）と、下端の主操作 `reading.end`（「終える」）の1つだけがあり、タブバーもナビゲーションバーも0個 |
| AC-44 | S-1、S-2 | S-1 が前面でシート・確認・知らせがないとき、端末を伏せて（`faceDown`）1.0秒たつと、触覚 `haptic.readingStart` が1回鳴って `reading`（S-2）になる |
| AC-45 | S-1 | 伏せてから 1.0秒未満（0.9秒）で起こすと、`idle` のままで触覚も0回 |
| AC-46 | S-1 | 今の本がないとき（本0冊または積読のみ）は、伏せの監視はオフ（`flipMonitoring=off`）で、伏せても始まらない |
| AC-47 | S-2〜S-10a、部品 N | S-1 以外のすべての画面（S-6 本棚、S-7 本の画面、S-7a 本を直す、S-7b 記録を直す、S-7c 奥付を写す、S-8 本を加える、S-8a バーコード、S-8b 表紙・背表紙・スクショ OCR、S-8c 手で入れる・書名候補、S-8d 本棚の複数冊 OCR、S-3 しおりを挟む、S-3a〜S-3c しおり入力・写真/スクショ OCR、S-4 結果、S-5 置き方案内、S-9 読み終えた画面、S-10 設定、S-10a 見た目と購入）、S-1 の上のシート・確認ダイアログ・知らせの帯（`session.tooShort` など）が出ている間、および起動前から伏せたままのときは、向きの監視はオフまたは無視し、伏せても始まらない |
| AC-48 | S-2 | 伏せて読み始めたあと、途中で起こしても `reading` は止まらず、もう一度伏せても2つ目の読書や2回目の触覚は起きない |
| AC-49 | S-1、S-2 | 伏せて 1.0秒たって読書が始まったとき、VoiceOver の読み上げ `session.flipStarted.announcement`（「『（書名）』を読み始めました。」）を1回送る |
| AC-50 | S-1 | 今の本があり、`settings.flipToStart` がオンで伏せ検知が使えるとき、S-1 の下部に `bookmark.flipHint` が1つ出る |
| AC-51 | S-1、S-10 | S-10 で `settings.flipToStart` をオフにしたとき、または伏せ検知が使えない環境（H18）では、`flipMonitoring=off` で `bookmark.flipHint` は出ず、`bookmark.start` ボタンはそのまま押せる |
| AC-52 | S-2 | 読み始めたあと、ほかのアプリに移ったりロックしたりしている間の時間も、開始時刻との差でそのまま数える |
| AC-53 | S-2 | 読書中にアプリが強制終了されても、開き直すと `reading` として S-2 がそのまま出て、開始時刻からの経過で記録が残る |
| AC-54 | S-2 | 読書中も `isIdleTimerDisabled` と `isProximityMonitoringEnabled` はどちらも `false` のままにし、OS の自動ロックで画面が消えるようにする |
| AC-55 | S-2、S-3 | S-2 で `reading.end` を1回押すと、確認なしで 0.5秒（500ミリ秒）以内に S-3 が開く |
| AC-56 | S-2、S-1、部品 N | 経過が59秒以下で終えると、記録は残さず S-3 も出さずに S-1 に戻り、知らせの帯に `session.tooShort` を1つ出す。60秒以上なら1分以上の記録が残り S-3 が出る |
| AC-57 | S-4、部品 N | 経過が 86,460秒（切り捨て分数が1440分超）のときは記録を1440分で止め、S-4 に知らせ `session.capped` を1つ出す（86,400〜86,459秒では1440分で `session.capped` は出さない） |
| AC-58 | S-2、S-1、部品 N | 端末の時刻が読み始めより前に戻っていたときは、記録を残さず S-1 に戻り、知らせ `session.invalidTime` を1つ出す |
| AC-59 | S-1、部品 N | 読み始めの保存に失敗したとき（H7 `session.start`）は、`idle` のまま S-1 に知らせ `session.start.error` を1つ出し、触覚は0回 |
| AC-60 | S-2、部品 N | 終わりの保存に失敗したとき（H7 `session.end`）は、`reading` のまま S-2 の下端ボタンの上に知らせ `session.save.error` を出し、もう一度 `reading.end` を押せる |
| AC-61 | S-1、S-2 | `bookmark.start` と `reading.end` を 0.3秒以内に2度押ししても、画面の遷移と記録の保存は1回だけ動く |
| AC-62 | W-1、S-1〜S-4 | 通信がすべて失敗する状態（H8）でも、ウィジェットからの起動、読み始め、終える、一行とページの保存、ウィジェットの更新がエラー0個で動く |
| AC-63 | S-3 | 読んだあとの S-3 に、`mark.photo`（主操作）、`mark.screenshot`、`mark.manual`、`mark.pageOnly`、`mark.later` の5つのボタンが1つずつ出て、すべて押せる |
| AC-64 | S-1、S-3、S-3a | S-1 の `bookmark.setMark` からシートで S-3 → S-3a を開き、一行とページを保存すると、記録は増やさず S-4 も挟まずに S-1 と W-1（H22）が更新される |
| AC-65 | S-3、S-3c | S-3 の `mark.photo` でページを撮ると S-3c に右から `mark.ocr.column.1`〜`mark.ocr.column.<n>` の枠が出て、いちばん左の列（`mark.ocr.column.<n>`）が最初に選ばれ、`mark.lineField` にその文字が入る。`mark.pageField` にページを入れて `mark.save` を押すと保存される |
| AC-66 | S-3c | S-3c で別の列の枠（例：`mark.ocr.column.3`）を押すと、選択がその列1つだけに替わり、`mark.lineField` の文字がその列の文字に替わる |
| AC-67 | S-3c | S-3c で `mark.lineField` の文字を手で直して `mark.save` を押すと、直したあとの文字列で保存される |
| AC-68 | S-3c | 撮ったページから1行も文字が読み取れなかったとき（列0）、S-3c に `mark.ocr.none` と、`mark.retake`（撮り直す）、`mark.manual`（手で入れる）が1つずつ出て、前のしおりは変わらない |
| AC-69 | S-3c | ページ・表紙・背表紙・本棚・奥付の画像から文字を抜き出したあと、保存したときも `mark.later` や閉じるで抜けたときも、アプリの保存領域と App Group に画像ファイルは0個、写真ライブラリへの書き込みは0回、選ばなかった列の文字も保存しない |
| AC-70 | S-3 | カメラの許可が拒否（H26）のときに S-3 の `mark.photo` を押すと、カメラは開かず S-3 の中に `camera.denied` と `camera.openSettings` が出て、同じ画面の `mark.screenshot`、`mark.manual`、`mark.pageOnly`、`mark.later` はそのまま押せる |
| AC-71 | S-3、S-3a | S-3 の `mark.manual` から S-3a を開き、`mark.lineField` と `mark.pageField` を入れて `mark.save` を押すと、一行の前後の空白を除いて保存される |
| AC-72 | S-3a | `mark.lineField` が空・空白のみ・61字以上のときは `mark.line.invalid` が出て保存しない。60字ちょうどは保存できる |
| AC-73 | S-3、S-3b、W-1 | S-3 の `mark.pageOnly` から S-3b を開き、`mark.pageField` にページを入れて `mark.save` を押すと、ページが更新されて一行は空になり、W-1 は書名とページだけの形（AC-31）になる |
| AC-74 | S-3a、S-3b | 単位がページのとき、`mark.pageField` に 0、10000以上、小数、S-3b での空を入れると `mark.page.invalid` が出て保存しない。全角数字「６１」、1、9999 は保存される |
| AC-75 | S-3、S-4 | S-3 で `mark.later` を押すと、一行とページは前のまま残り、S-4 の `result.summary` には「18分」の分数だけが出る |
| AC-76 | S-4、S-1 | S-4 の `result.summary` は、前のページがあれば「p.43 → p.61　18分」、前のページがなければ「p.61　18分」を出し、`result.close` を1回押すと S-1 に戻る |
| AC-77 | S-1、S-9、S-7c | S-1 の `bookmark.finish` を押すと今の本が `finished` になって S-9 が開き、`finish.colophon` に奥付5行と、足りない項目を補うための `colophon.capture` ボタンが1つ出る |
| AC-78 | S-9 | S-9 の「次の1冊」には `next.candidate.<id>` が最大3冊並び、自分の `tsundoku`（重なる理由がある本 → 加えた日が新しい順）が先、足りない枠に端末内書誌 DB（H20）・受賞一覧（H25）・共起テーブルから見つけた未所有の本が続く |
| AC-79 | S-9 | 各候補に `next.reason` が1つあり、積読の本は「積読から・同じ著者」「積読から・同じ賞（直木三十五賞）」、未所有の本は「同じ賞（第157回 直木三十五賞）」「シリーズの次の巻」「同じ著者の本」などの事実1行を出す |
| AC-80 | S-9 | 未所有の候補がないときは、積読から最大3冊（理由がある本が先、残りは積読に加えた日が新しい順に「積読から」）を出す |
| AC-81 | S-9 | 積読も未所有の候補も0件のときは、`next.candidate` は0個で、`next.empty.message` と `next.addBook` が1つずつ出る |
| AC-82 | S-9、S-1、W-1 | S-9 の積読の候補の `next.choose`（「この本を読む」）を押すと、その本が `current` になり、S-9 が閉じて S-1 と W-1（H22）がその本になる |
| AC-83 | S-9 | S-9 の未所有の候補（受賞一覧 H25 由来）の `next.addToShelf`（「積読に加える」）を押すと、その本が `tsundoku` に加わり、その行の `next.addToShelf` は消えて「積読に加えました」（`next.added`）になり、今の本は0冊のまま残る |
| AC-84 | S-9 | S-9 の `finish.card.share` を押すと、書名、著者、何晩、合計時間だけを描いた PNG 画像1枚（一行の文字列と写真は含まない）をシステムの共有シート（H24）に渡す |
| AC-85 | S-9 | カードと奥付の「何晩」は、記録の件数ではなく 4:00 境目の異なる晩の日付の数（同じ晩に2回読んだら1晩、時間は合算）で数える |
| AC-86 | S-1〜S-4 | 今の本があるときの毎晩の道（S-1、S-2、S-3、S-4）には、`next.candidate` も `bookmark.noCurrent.next` も一切出さない |
| AC-87 | S-9 | 端末内書誌 DB（H20）から未所有の「シリーズの次の巻」「同じ著者の本」を `next.candidate` に出し、`next.addToShelf` を押すと H20 の書名・著者・出版社・レーベル・出版年・ISBN つきで `tsundoku` に加わる |
| AC-88 | S-10 | S-10 の `settings.privacyPolicy` を押すと、設定値のプライバシーポリシー URL（H31）を1件開く |
| AC-89 | S-1、S-6、S-7、S-10 | 画面の操作で入れた本、置き場所、一行、ページ、記録、3つの設定（伏せる道、隠す設定、夜の入口の時刻）は、アプリを強制終了して開き直してもそのまま残る |
| AC-90 | S-1 | 起動時に保存先を読めないとき（H7 `store.load`）は、S-1 に `ContentUnavailableView` で `store.load.error` と `store.retry` だけを出し、`bookmark.start` と `bookmark.addBook` は出さない。開き直して読めれば元の本と記録が出る |
| AC-91 | S-1、S-3a〜S-3c、S-7〜S-9 | 本の追加・更新・削除・状態変更、記録の更新・削除、しおりの保存が失敗したとき（H7）は、`common.save.error` が1つ出て、変更前の値がすべてそのまま保たれる |
| AC-92 | S-8a、S-8c、S-7 | 端末内書誌 DB（H20）から著者を取り出すとき、`dc:creator` の先頭から生没年・役割語（「著」「監修」「ピアニスト」）・カンマ・空白を除いて整える |
| AC-93 | S-10 | S-10 に `settings.dataSources`（NDL 3条件：出典と取得日、加工して端末内 DB を作成した旨、NDL サーチ API を用いて作成した旨＋DB の版＋共起データは NDL と無関係である旨）と `settings.dataSources.license`（CC BY 4.0 URL を開くリンク）が1つずつ出る。S-1 と S-2 には出ない |
| AC-94 | S-3c | `mark.photo` で撮ってから OCR の結果が返るまでの待ちの間も、S-3c の下部に `mark.manual` と `mark.pageOnly` を押せる状態で出し、押すと 1.0秒以内に S-3a または S-3b に切り替わり、あとから OCR 結果が返っても入力画面を上書きしない |
| AC-95 | S-3a、S-3b、S-3c | 読んだあとのしおりの保存が失敗したとき（H7 `mark.save`）は、記録（分数）は保存済みのまま、入力画面の一番上に `common.save.error` を出し、入れた一行とページを欄に残してもう一度 `mark.save` を押せる |
| AC-96 | S-5、S-1 | 初めて一行を保存して S-1 に戻ったときに1回だけ、シートで `widgetGuide`（S-5）を出す。閉じたあとは2回目以降も再起動後も出ない |
| AC-97 | W-3、S-4 | しおり保存後の予約 Live Activity の要求が失敗しても、アラートは出さず S-4 とウィジェット更新はそのまま完了し、次にアプリを前に戻したときに予約を入れ直す |
| AC-98 | W-3 | 予約 Live Activity の `staleDate` は翌朝 4:00 にし、読まなかった晩の翌朝にアプリを前に戻したときは、残っていた前夜の Live Activity を終わらせて今夜の 21:00 の予約を入れる |
| AC-99 | W-1、W-2、S-1 | W-1・W-2 の VoiceOver はウィジェット全体を1つのまとまりにして「（書名）、61ページ。（一行）」と読み、縦書き用の字形（U+FE11 等）を含まない。S-1 の `bookmark.line` のラベルは保存した一行そのもの |
| AC-100 | S-1 | 本3冊・記録10件で、起動してから S-1 を操作できるまでの5回の平均が 1.0秒以内 |
| AC-101 | S-6、S-7 | 本500冊・記録5,000件（本 A に1,000件）で、S-6（本棚）と S-7（本の画面）が開いてから出るまでの5回の平均がどちらも 1.0秒以内 |
| AC-102 | W-1、W-2 | W-1 と W-2 のタイムライン項目を返すまでの5回の平均がどちらも 0.5秒以内 |
| AC-103 | 全画面 | バーコード登録、書名候補登録、しおり保存、読書記録、読み終えカードの共有を通して、アプリ本体とウィジェットからの外部 HTTP 通信（H29）は0件 |
| AC-104 | S-1〜S-4、S-9 | 未購入のとき、毎晩の道（S-1〜S-4）と読み終えた画面（S-9）には購入シートや `store.` で始まる要素、自動のシート・アラートを一切出さない |
| AC-105 | S-10、S-10a | S-10 の `settings.appearance` から S-10a を開き、鍵の付いた有料の見た目（`kinari`、`sumi`、`shu`）を押すと、その見た目を当てた見本 `store.preview`（`accessibilityValue` はその見た目の id）と、品名・中身・値段・`store.buy`・`store.restore`・`store.close` を持つ購入シートが出る。`store.close` で閉じると `default` のまま |
| AC-106 | S-10a、S-1、W-1、W-2 | `store.buy` で「よむま＋」を買うと鍵が外れ、選んだ見た目の id が設定（H13）とウィジェット（H22）に保存され、開き直しても残る |
| AC-107 | S-10a | 購入をキャンセルしたとき（`userCancelled`）は知らせを出さずに購入シートに残り、購入がエラーで失敗したときはシート内に `store.purchase.error` が1つ出る。どちらも見た目は `default` のまま |
| AC-108 | S-10、S-10a | S-10 の `settings.restorePurchases`（またはシートの `store.restore`）を押すと、購入記録があれば「買った」状態になって `store.restore.done` が1つ出て、なければ `store.restore.none` が1つ出る |
| AC-109 | S-10a | 支払いが許可されていない端末（`canMakePayments == false`）で鍵つきの見た目を押すと、`store.buy` は出ず `store.unavailable` が1つ出る |
| AC-110 | S-10a | 通信がなく商品情報を読めないとき（H8、H30）に鍵つきの見た目を押すと、アラートは出ずシート内に `store.offline` が1つ出て `store.buy` は出ない。S-1 に戻れば `bookmark.start` はそのまま押せる |
| AC-111 | S-10a、S-1、W-1 | 購入が返金されたときは、アプリが前に戻ったときに購入状態が「買っていない」に戻り、設定とウィジェットの見た目の id が `default` に戻る（本や記録は消えない） |
| AC-112 | S-7、S-9 | 同梱の受賞一覧データ（H25）が `docs/prd/001-reading-session-awards.md` の表と全行一致する |
| AC-113 | S-7、S-9、S-7c | S-7 または S-9 の `colophon.capture`（`book.captureColophon`）を押して奥付を撮ると（H19）、S-7c の確認欄に著者・出版社・レーベル・出版年・ISBN が入り、`colophon.save` を押すと奥付が更新され、画像は残らない（H27） |
| AC-114 | W-4、W-5、W-3、S-2 | ロック画面の Control（`control.startReading`）または Siri「読み始める」を動かすと、アプリを前に出さずに 0.5秒以内に `reading` になり、声で `intent.start.started` を返し、すぐ始める Live Activity（書名・開始時刻・`liveActivity.end` ボタン、ラベルは `liveActivity.end.label`、`staleDate` は翌 4:00）が出る。残った記録の入口の印は `intent_start` |
| AC-115 | W-4、W-5、W-3、S-1、S-2 | すでに `reading` のときに「読み始める」を動かしても二重に始まらず `intent.start.alreadyReading` を返す。予約 Live Activity が表示中ならそれを `reading` に更新し、時刻前の予約があれば取り消してすぐ始める Live Activity を出し、S-1 が前面なら 1.0秒以内に S-2 に切り替える |
| AC-116 | W-3、S-3、S-1 | Live Activity の `liveActivity.end` を押すと、押した時刻で読書が終わり、アプリを前に出せる状態なら S-3 を開き、前に出せない状態ならその場で記録を保存して次に開いたとき S-1 を出し、59秒以下なら記録せず S-1 に `session.tooShort` を出す |
| AC-117 | W-4、W-5、S-1 | 今の本がないときに「読み始める」のインテントを動かすと、アプリを前に出して S-1 の空状態（`bookmark.empty.message` または `bookmark.noCurrent.message`）を見せる |
| AC-118 | W-4、W-5、S-2 | Live Activity がオフのときに「読み始める」のインテントを動かすと、その場で `reading` になり、前に出せるならアプリを開いて S-2 を出す |
| AC-119 | W-4、W-5、S-1 | 「読み始める」のインテントで保存が失敗したとき（H7 `session.start`）は、声で `session.start.error` を返し、`idle` のままにする |
| AC-120 | W-3、W-4、W-5 | `settings.hideOnWidgets` がオンのときに「読み始める」で出る Live Activity には、書名を出さず `widget.hidden`（「しおり」）と開始時刻と `liveActivity.end` だけを出す |
| AC-121 | W-5 | Siri「どこまで読んだ？」を動かすと、アプリを開かず認証も求めず（`alwaysAllowed`）、声と小窓で `intent.whereStopped.page`（「61ページからです。」）だけを返し、一行の文字列と書名は含めない |
| AC-122 | W-5 | 「どこまで読んだ？」で今の本に進み具合の値がないときは `intent.whereStopped.noPage`、今の本がないときは `intent.whereStopped.noCurrent` を返す |
| AC-123 | W-5 | `settings.hideOnWidgets` がオンのときも、「どこまで読んだ？」はページ（または位置・％）だけを答え、一行と書名は出さない |
| AC-124 | W-5、S-1 | Siri「続きを読む」を動かすと、アプリを前に出して S-1 を開き、そのあと始まった読書の入口の印は `intent_open` になる |
| AC-125 | W-3、W-4、W-5 | 機内モード（H8 通信なし）でも、「どこまで読んだ？」「読み始める」、Live Activity の「終える」がすべてエラーなしで動く |
| AC-126 | W-4、W-5 | App Shortcuts は「読み始める」「どこまで読んだ？」「続きを読む」の3つ（日本語の言い方に「で」が直後に続く「よむまで〜」は0件）、Control はボタン1つ（ラベル `control.startReading`） |
| AC-127 | S-9 | 2晩以上の記録がある本を読み終えると、S-9 に `finish.reflection`（文言キー `finish.reflection.multi`：「6晩、合計142分（2時間22分）。いちばん長かったのは10月15日の晩の38分でした。」）が1つ出る。共有するカード画像にはこの文を描かない |
| AC-128 | S-9 | 記録が1晩だけのときは `finish.reflection.single`（「1晩、30分で読み終えました。」）を出し、同じ最長分数の晩が複数あるときは新しい方の日付を `finish.reflection.multi` に出す |
| AC-129 | S-9 | 記録が0件の本を読み終えたときは、`finish.reflection` を出さず（0個）、`finish.colophon` と次の1冊を出す |
| AC-130 | S-1、W-3 | 夜の入口の時刻より前にアプリ内で読み始めたら今夜の予約 Live Activity を取り消し、読書中は予約を見直さず、終えてしおりを保存したときに翌夜の予約を入れる（1分未満で終わったときは今夜の予約を戻す） |
| AC-131 | W-4、W-5、S-2 | 「読み始める」のインテントで Live Activity の開始要求だけが失敗したときは、エラーを返さずアプリを前に出して S-2 で読書を続ける |
| AC-132 | W-3、S-2 | Live Activity の `liveActivity.end` で終わりの保存が失敗したとき（H7 `session.end`）は、Live Activity を消さずアプリを前に出して S-2 に `session.save.error` を出し、`reading.end` でやり直せる |
| AC-133 | W-5 | 「どこまで読んだ？」で保存先の読み込みに失敗したとき（H7 `store.load`）は、声と小窓で `intent.whereStopped.error` を返し、ページや書名は出さない |
| AC-134 | W-5、S-2 | すでに `reading` のときに「続きを読む」を動かすと、アプリを前に出して S-2 をそのまま見せる |
| AC-135 | W-5、S-1 | 今の本がないときに「続きを読む」を動かすと、アプリを前に出して S-1 の空状態（`bookmark.noCurrent.message` または `bookmark.empty.message`）を見せる |
| AC-136 | S-2、W-3 | 4:00 をまたいでも、Live Activity が OS の8時間上限で先に消えても、アプリ内の `reading` は勝手に終わらず、終えたときに開始時刻からの全分数が1件の記録になる |
| AC-137 | S-8、S-8b | S-8 の `register.cover`（カメラ）または `register.screenshot`（`PhotosPicker`）で画像を読み取ると、S-8b に `cover.ocr.line.1`〜`<n>` が出る。1タップ目で書名（`cover.selectTitle` → `manual.title`）、2タップ目で著者（`cover.selectAuthor` → `manual.author`）が入り、`cover.save` で保存され、画像は残らない（H27） |
| AC-138 | S-8、S-8d | S-8 の `register.bookshelf` で本棚や積読を1枚写すと、S-8d に背表紙の行が出る。押した行ごとに `bookshelf.row.<n>` ができ、端末内書誌 DB（H20）で完全一致1件の本は著者・出版社・ISBN が自動で入り、複数件または0件の本は書名だけで入り、`bookshelf.addSelected` でまとめて `tsundoku` に加わる |
| AC-139 | S-8、S-2、S-1、W-1、W-3 | 今の本が0冊で名無しの本がないとき、S-8 の `register.later` を押すと文字入力なしで `isTitlePending = true` の今の本が作られて即座に `reading`（S-2）になり、S-2、S-1 の `bookmark.title`、W-1（H22）、W-3（H23）の書名の位置に `widget.currentBookAsTitle`（「今の本」）が出る。終えて保存すると S-1 に `bookmark.setBookTitle` が1つ出て、その間 S-8 に2冊目の `register.later` は出ない |
| AC-140 | S-1、S-8、S-8a〜S-8c | S-1 の `bookmark.setBookTitle` を押してバーコード（または表紙撮影・手入力）で書誌を入れると、新しい本は増えず今の本の `isTitlePending` が `false` になり、記録としおりを残したまま書名と奥付が更新され、`bookmark.setBookTitle` は消える |
| AC-141 | S-3a、S-3b、S-4、S-1、W-1 | 電子書籍（`isEbook = true`）のしおり入力で、`mark.progressUnit` を `location`（1〜999999）または `percent`（0〜100）にして値を入れると、S-4 の `result.summary` に「位置1200 → 位置1450　18分」「34% → 52%　18分」、S-1 の `bookmark.page` と W-1（H22）に「位置1450」「52%」が出る。範囲外の値は `mark.page.invalid` を出す |
| AC-142 | S-3、S-3c | カメラ許可が拒否（H26）でも、S-3 の `mark.screenshot`（`PhotosPicker` `.screenshots`）を押すと許可アラート0個でスクリーンショットを選べ、S-3c で `mark.ocr.column.<n>` から一行と `mark.pageField` を保存でき、画像は残らない（H27） |
| AC-143 | W-5 | 電子書籍の単位が `location` または `percent` のとき、「どこまで読んだ？」は `intent.whereStopped.location`（「位置1450からです。」）または `intent.whereStopped.percent`（「52パーセントからです。」）で答え、一行と書名は出さない |
| AC-144 | S-1、S-2、W-3 | 電子書籍（`isEbook = true`）が今の本のとき、S-1 には `bookmark.flipHint.ebook`、S-2 には `reading.ebookNote` が1つずつ出て、同じ iPhone で電子書籍アプリを開いて読んだあとも Live Activity の `liveActivity.end` で終えられる |
| AC-145 | S-1 | 今の本が0冊で積読が1冊以上あるとき、S-1 に `bookmark.noCurrent.message` と積読から最大3冊の候補 `bookmark.noCurrent.next.<id>` が出て、行の `bookmark.noCurrent.choose` を1回押すとその本が `current` になる |
| AC-146 | S-7 | 読み終えた本（`finished`）の S-7 に、見出し `after.header`（「この本のあとに」）と未所有の候補最大5冊 `after.candidate.<ISBNまたは受賞ID>`（書名、著者、`after.reason`、`after.addToShelf`）が出る。`after.addToShelf` を押すと書誌つきで `tsundoku` に加わり、その行のボタンが `after.added`（「積読に加えました」）に替わる |
| AC-147 | S-9、S-7 | 候補を選んだ（`chosen`）・見送った（`skipped`）回数から理由の軸ごとの重み `score = chosen * 2 - skipped` を端末内で計算し、利用者がよく選ぶ軸（例：`sameAward`）の候補を既定の順より上に繰り上げる |
| AC-148 | S-9、S-7 | 端末内書誌 DB（H20）の共起テーブルに、`fromISBN` から `count >= 10` かつ `toISBN` の NDC が `9`（文学）で始まる未所有の本があるとき、理由 `rec.reason.readers`（「この本を読み終えた人が、次に読んだ本」）として候補に出し、画面のどこにも人数の数字は出さない |
| AC-149 | S-8a、S-8c | Release 構成で、(1) バーコード読み取り（H21）から `scan.row` が出るまで、(2) `register.manual` で `manual.title` に3字以上入れてから `search.row` が出るまでの5回の平均が、どちらも 0.3秒（300ミリ秒）以内（H10） |

---

## 3. 画面ごとの仕事と主操作、使う標準部品

どの画面も、仕事は1文、主操作は1つ（B-1、B-2）。主操作は画面の下端に固定した幅いっぱいのボタン（`.buttonStyle(.borderedProminent)`、高さ 50pt 以上）か、入力シートのツールバー右上の保存ボタン（`Button(role: .confirm)`）にする。
押せる要素と押せない文字は同じ色相（白・黒・灰）を使うので、押せることは必ず**形**（塗りのボタン `.borderedProminent` / `.bordered`、ツールバーの丸い枠、一覧の右端の `>` またはチェック、リンクの末尾の `arrow.up.forward`）で示す（決定 4、47）。

| 画面 | 仕事（1文） | 主操作（1つ） | 標準部品 | 標準から外れる所（元の部品、理由、アクセシビリティ） |
|---|---|---|---|---|
| W-1 ロック画面のウィジェット | 電話を手に取った瞬間に、昨夜止めた一行と場所を見せて続きへ戻す | ウィジェット全体を押して S-1 を開く（`widgetURL`） | WidgetKit `StaticConfiguration`（`.accessoryRectangular`） | 縦書きの文字列の描画（標準の `Text` は縦書きを組めないため、1字ずつ位置を計算して並べる。VoiceOver は全体を `.accessibilityElement(children: .ignore)` で1つにまとめ、元の文字列でラベルを付ける。AC-28、AC-99） |
| W-2 小のウィジェット | ホーム画面と充電中の StandBy で、昨夜止めた一行と場所を大きく見せる | ウィジェット全体を押して S-1 を開く（`widgetURL`） | WidgetKit `StaticConfiguration`（`.systemSmall`） | W-1 と同じ縦書きの描画 |
| W-3 夜の入口と読書中の Live Activity | 予定の時刻にロック画面に続きの一行を出し、読書中は経過時間と1タップで終える操作を出す | 待つ状態：全体を押して S-1 を開く／読書中：「終える」ボタン（`liveActivity.end`） | ActivityKit `ActivityConfiguration`、ロック画面バナー、Dynamic Island（Compact / Minimal / Expanded）、`Button(intent: EndReadingFromActivityIntent())`（`EndReadingIntent`） | 標準から外れない（Live Activity の高さに収めるため、待つ状態の一行も横書きの `Text` を使う） |
| W-4 コントロール | ロック画面・コントロールセンター・アクションボタンから、アプリを開かずに1タップで読書を始める | 「読み始める」（`control.startReading`） | WidgetKit `ControlWidget`、`ControlWidgetButton(action: StartReadingIntent())` | 標準から外れない |
| W-5 Siri とショートカットの応答 | 声やショートカットから、読書を始める・どこまで読んだかを聞く・しおりの画面を開く | 呼び出したインテントの実行 | AppIntents `AppShortcutsProvider`、`AppIntent`、`ShowsSnippetView`（小窓は1行の `Text` のみ） | 標準から外れない |
| S-1 しおりの画面 | いま読んでいる1冊の続きの一行を見せ、1タップか伏せる動作で今夜の読書を始める | 「読み始める」（`bookmark.start`、または端末を伏せて置く。今の本が0冊のときは「本を加える」`bookmark.addBook` または候補の「この本を読む」`bookmark.noCurrent.choose`） | `NavigationStack`、`ToolbarItem`、`Button`（`.borderedProminent` / `.bordered`）、`ContentUnavailableView`、`ScrollView`、`safeAreaInset(edge: .bottom)` | 縦書きの一行（S-1 の中央。標準の `Text` は縦書きを組めないため。accessibility1 以上の文字サイズと、60字が幅に入らないときは標準の横書き `Text` に切り替える。VoiceOver は保存した一行そのものを1つの要素 `bookmark.line` として読む） |
| S-2 読書中の画面 | 読書が始まったことと開始時刻だけを静かに伝え、終わるときに1タップで受け止める | 「終える」（`reading.end`） | `VStack`、`Text`、`Button`（`.borderedProminent`）、`safeAreaInset(edge: .bottom)` | ナビゲーションバーと戻るボタンを出さない（`.toolbar(.hidden, for: .navigationBar)`。読書中に他の画面へ迷い込ませず、画面内の押せる要素を `reading.end` の1つだけにするため。AC-43。VoiceOver でも書名・開始時刻・説明・「終える」の4要素だけが順番に読まれる） |
| S-3 しおりを挟む画面 | 読み終えた直後に、今夜どこまで読んだかを残す道を迷わず選ばせる | 「ページを撮る」（`mark.photo`。カメラが使えない・拒否のときは「スクリーンショットから選ぶ」`mark.screenshot`、電子書籍のときは前回使った道または `mark.screenshot`） | `NavigationStack`、`VStack`、`Button`（`.borderedProminent` / `.bordered`）、`PhotosPicker` | 標準から外れない |
| S-3a 一行とページを入れる画面 | 止めた一行と場所（ページ・位置・％）を手で入れて保存する | ツールバー右上の「保存」（`mark.save`、`Button(role: .confirm)`） | `Form`、`Section`、`TextField`、`Picker`（`.segmented`、電子書籍の単位 `mark.progressUnit`）、`ToolbarItem` | 標準から外れない |
| S-3b ページだけ入れる画面 | 止めた場所（ページ・位置・％）の数字だけを手早く入れて保存する | ツールバー右上の「保存」（`mark.save`、`Button(role: .confirm)`） | `Form`、`Section`、`TextField`（`.keyboardType(.numberPad)`）、`Picker`（`.segmented`、電子書籍の単位 `mark.progressUnit`）、`ToolbarItem` | 標準から外れない |
| S-3c 写真・スクショから一行を選ぶ画面 | 撮ったページまたは選んだスクリーンショットから止めた1行を選び、必要なら文字を直して保存する | 下端に固定した「保存」（`mark.save`、`.borderedProminent`。0文字のときは「撮り直す」`mark.retake`） | `ScrollView`、`Form`、`TextField`、`Picker`、`Button`、`ContentUnavailableView`、`safeAreaInset(edge: .bottom)` | 画像の上の読み取り列の枠ボタン（`mark.ocr.column.<n>`。Vision が返した正規化矩形の位置に白黒2重線の枠と番号札を重ねて押せるようにするため。各枠に `accessibilityIdentifier` と読み取った文字列の `accessibilityLabel`、`isSelected` トレイトを付け、accessibility1 以上の文字サイズでは枠の下に標準の `List` でも同じ行を並べる） |
| S-4 読書の結果の画面 | 今夜進んだ場所と分数を静かに確かめて、しおりの画面へ戻す | 「閉じる」（`result.close`） | `VStack`、`Text`、`Button`（`.borderedProminent`）、`safeAreaInset(edge: .bottom)` | 標準から外れない |
| S-5 ロック画面への置き方の案内 | 最初に一行を保存した夜に1回だけ、ロック画面に一行を置く手順と実際の見え方を伝える | 「閉じる」（`widgetGuide.close`） | `.sheet`、`VStack`、`Text`、`Button`（`.borderedProminent`） | 見本の枠（172×76 pt の W-1 と同じ縦書き描画を角丸枠の中に見せる。VoiceOver は `widgetGuide.preview` に「ロック画面での見え方。」と W-1 の読み上げラベルを続けて付ける） |
| S-6 本棚の画面 | 今の本、積読、読み終えた本を1つの一覧で見渡し、開く本を選ばせる | 本の行（`shelf.row.<id>`）を押して S-7 を開く（本0冊のときは「本を加える」`shelf.empty.addBook`） | `List`（`.insetGrouped`）、`Section`、`NavigationLink`、`ToolbarItem`、`ContentUnavailableView` | 標準から外れない |
| S-7 本の画面 | その本の奥付、読書の記録、読み終えたあとの候補を見せ、次に読む本にする | 下端に固定した「この本を読む」（`book.readThis`、`.borderedProminent`。その本がすでに `current` のときはボタンを出さず `book.isCurrent` の文を出す） | `List`（`.insetGrouped`）、`Section`、`Button`、`ToolbarItem`、`confirmationDialog`、`ContentUnavailableView`、`safeAreaInset(edge: .bottom)` | 奥付の節（`book.colophon`：本の最後のページの奥付の型として、上下の罫線 `color.separator` の間に項目名と値の2列を並べる。AX1 以上では1列の縦並びに切り替える。VoiceOver は行ごとに「書名、蜜蜂と遠雷」のように項目名と値を1つにまとめて読む） |
| S-7a 本を直す画面 | 本の書名、著者、電子書籍の設定を手で直して保存する | ツールバー右上の「保存」（`book.edit.save`、`Button(role: .confirm)`） | `.sheet`、`NavigationStack`、`Form`、`TextField`、`Toggle`、`Picker`、`ToolbarItem` | 標準から外れない |
| S-7b 記録を直す画面 | 選んだ晩の分数を見直すか、誤った記録を消す | ツールバー右上の「保存」（`record.save`、`Button(role: .confirm)`） | `.sheet`、`NavigationStack`、`Form`、`TextField`（`.keyboardType(.numberPad)`）、`Button(role: .destructive)`、`confirmationDialog`、`ToolbarItem` | 標準から外れない |
| S-7c 奥付を写す画面 | 本の奥付を1枚写して、著者・出版社・レーベル・出版年・ISBN を確かめて補う | 下端に固定した「保存」（`colophon.save`、`.borderedProminent`） | `.sheet`、`NavigationStack`、`Form`、`TextField`、`Button`、`ToolbarItem`、`safeAreaInset(edge: .bottom)` | カメラプレビュー（`DataScannerViewController` / `AVCaptureSession` を `UIViewControllerRepresentable` で包む。VoiceOver ではプレビューに説明ラベルを付け、写したあとは標準の `Form` の各欄に焦点を移す） |
| S-8 本を加える画面 | 手元の本に合わせて、本を加えるいちばん速い道を1つ選ばせる | 「バーコードを続けて読む」（`register.barcode`、一覧の先頭） | `.sheet`、`NavigationStack`、`List`（`.insetGrouped`）、`Section`、`Button`、`PhotosPicker`、`ToolbarItem` | 標準から外れない |
| S-8a バーコードを続けて読む画面 | 裏表紙のバーコードを次々にかざして、端末内書誌 DB からまとめて本棚に加える | 下端に固定した「n冊を本棚に加える」（`scan.addToShelf`、`.borderedProminent`） | `VStack`、`List`、`TextField`（未収録時の行内 `scan.row.editTitle`）、`Button`、`confirmationDialog`、`safeAreaInset(edge: .bottom)` | カメラのバーコード読み取り面（上半分に `DataScannerViewController` を `UIViewControllerRepresentable` で置く。新しい本が読めるたびに触覚と VoiceOver の読み上げを1回出し、下の標準 `List` に追加する） |
| S-8b 表紙・背表紙・スクショから選ぶ画面 | 表紙や背表紙、スクリーンショットの文字から書名と著者を2タップで選んで加える | 下端に固定した「保存」（`cover.save`、`.borderedProminent`） | `ScrollView`、`Form`、`TextField`、`Button`、`ContentUnavailableView`、`safeAreaInset(edge: .bottom)` | 画像の上の読み取り行の枠ボタン（S-3c と同じ白黒2重線の枠 `cover.ocr.line.<n>` と「書名」「著者」の役割札。下部に標準の `TextField` `manual.title`・`manual.author` を並べ、accessibility1 以上では標準の `List` でも行を選べる） |
| S-8c 手で入れる（書名候補つき）画面 | 書名を手で入れながら端末内書誌 DB の候補から1タップで選ぶか、そのまま保存する | ツールバー右上の「保存」（`manual.save`、`Button(role: .confirm)`） | `Form`、`Section`、`TextField`、`Toggle`、`Picker`、`Button`、`ToolbarItem` | 標準から外れない |
| S-8d 本棚の写真から複数冊を選ぶ画面 | 本棚や積読の山の1枚の写真から、複数の背表紙を押してまとめて積読に加える | 下端に固定した「選んだn冊を積読に加える」（`bookshelf.addSelected`、`.borderedProminent`） | `ScrollView`、`List`、`TextField`、`Button`、`ContentUnavailableView`、`safeAreaInset(edge: .bottom)` | 画像の上の背表紙の枠ボタン（S-3c・S-8b と同じ白黒2重線の枠。押した枠が下の標準 `List` の行 `bookshelf.row.<n>` になり、行の中で書名を直せる） |
| S-9 読み終えた画面 | 1冊を読み終えた夜に、ふりかえりと奥付を静かに見せ、カードを共有するか次の1冊を選ばせる | 次の1冊の候補の「この本を読む」（`next.choose`。未所有の候補は「積読に加える」`next.addToShelf`、候補0件のときは「本を加える」`next.addBook`） | `.sheet`、`NavigationStack`、`ScrollView`、`VStack`、`Button`（`.bordered`）、`ShareLink` / `UIActivityViewController`、`ContentUnavailableView`、`ToolbarItem` | S-7 と同じ奥付の節（`finish.colophon`）と、共有用のカード画像の描画（`ImageRenderer` で奥付の型を PNG に描く。画面の要素ではない） |
| S-10 設定の画面 | 読み始めの動作、夜の入口の時刻、ロック画面のプライバシー、見た目と購入の復元、書誌の出どころを整える | 各項目の切り替え・選択（主操作の単一ボタンは持たない） | `Form`、`Section`、`Toggle`、`DatePicker` / `Picker`（15分刻みの時刻 `settings.entryTime`）、`NavigationLink`、`Button`、`Link` | 標準から外れない |
| S-10a 見た目と「よむま＋」の画面 | 紙と墨の見た目を見比べて選び、未購入なら見本を見て買い切りで求める | 購入シートが出ているとき：「よむま＋を買う」（`store.buy`、`.borderedProminent`）／一覧のとき：見た目の行を選んで適用する | `List`（`.insetGrouped`）、`Section`、`Button`、`.sheet`（購入シート）、`ToolbarItem` | 見本の枠（`store.preview`：選んだ見た目の色トークンを当てた S-1 と W-1 の縮小見本。VoiceOver は `accessibilityIdentifier` `store.preview` に `accessibilityValue` として選んだ見た目の id を持たせる。AC-105） |
| 部品 N 知らせの帯 | 画面の流れを止めずに、起きたことと直し方を伝える | 「閉じる」（`notice.close`、`.bordered` の小さいボタン、押せる範囲 44×44 pt） | `HStack`、`Image(systemName:)`、`Text`、`Button` | 標準の `alert` を使わず画面の上部（S-2 と S-8a〜S-8d の保存失敗は下端ボタンのすぐ上）に帯で出す（自動で消えるトーストは使わず、モーダルな `alert` で操作を止めないため。R-26、決定 43。出たときに `AccessibilityNotification.Announcement` で1回読み上げる） |

---

## 4. 判断と根拠

判断の表のすべての行に、調査（`design/001-reading-session-research.md` の R-1〜R-87）の番号と、原則（HIG の URL または B-1〜B-6）を結び付ける。

| # | 判断 | 調査の根拠（R） | 原則（HIG / B-n） |
|---|---|---|---|
| 1 | タブバーを持たず、S-1（しおりの画面）を1つの根にする。本棚と設定はツールバーから押し出し、登録と読み終えた画面はシートで出す。毎晩の道でほかの画面へ迷い込ませない | R-2、R-8、R-18 | B-1、B-2、https://developer.apple.com/design/human-interface-guidelines/design-principles |
| 2 | 方向性は案A「白い紙と墨」にする。標準の見た目は白・黒・灰と縦書きの明朝で構成し、ロック画面で色が抜けても一行の版面がそのまま残るようにする | R-2、R-4、R-6、R-8、R-19 | B-5、https://developer.apple.com/design/human-interface-guidelines/color |
| 3 | 一行の書体は iOS 同梱のヒラギノ明朝 ProN（`HiraMinProN-W3` / `W6`）を使い、外部フォントを同梱しない。本文と操作はすべてシステムフォント（SF Pro / ヒラギノ角ゴ）にする | R-22、R-30 | B-4、https://developer.apple.com/design/human-interface-guidelines/typography |
| 4 | 押せる要素と押せない文字は同じ無彩色（白・黒・灰）なので、押せることは必ず形（塗りのボタン `.borderedProminent` / `.bordered`、丸いツールバー枠、一覧の `>`、リンクの `arrow.up.forward`）で示す。枠のない文字だけのボタンは置かない | R-24、R-25 | B-5、https://developer.apple.com/design/human-interface-guidelines/buttons 、https://developer.apple.com/design/human-interface-guidelines/accessibility |
| 5 | ロック画面の主の入口は `accessoryRectangular`（W-1）にし、一行（25字まで）を右から縦に組み、左端の帯の下にノンブルの位置で「p.61」（または「位置1450」「52%」）を置く | R-12、R-18、R-19 | B-3、B-6、https://developer.apple.com/design/human-interface-guidelines/widgets |
| 6 | 縦書きは1字ずつ位置を計算して並べ、句読点とかぎ括弧は縦書き用の字形（U+FE11、U+FE12、U+FE41、U+FE42）に置き換え、「ー」などは90度回し、半角英数字は全角にそろえる。保存する文字列と VoiceOver のラベルは置き換えない | R-24、R-30 | B-6、https://developer.apple.com/design/human-interface-guidelines/typography 、https://developer.apple.com/design/human-interface-guidelines/accessibility |
| 7 | W-1 と W-2 の明朝は太さ `W6` にする。ロック画面の vibrant 描画で細い横画が消えるのを防ぐため。S-1 の大きな一行（28pt）は `W3`（高コントラスト時は `W6`）にする | R-19、R-24、R-30 | https://developer.apple.com/design/human-interface-guidelines/widgets 、https://developer.apple.com/design/human-interface-guidelines/accessibility |
| 8 | W-1 と W-2 の字の大きさは固定にする。ウィジェットの枠は広がらないため、Dynamic Type で大きくすると25字が入らなくなる。大きい文字の人は押して開いた S-1 で拡大された全文を読む | R-18、R-24 | B-3、https://developer.apple.com/design/human-interface-guidelines/widgets |
| 9 | 26字以上の一行は、ウィジェットでは13〜25字目の最後の「、」「。」で切るか、なければ先頭24字＋「…」に縮める。文の途中でぶつ切りにしない。S-1 には全文（60字まで）を出す | R-18、R-26 | B-3、https://developer.apple.com/design/human-interface-guidelines/widgets |
| 10 | ひらがな・カタカナ・漢字を1字も含まない一行（欧文のみ）は、縦の列に分けず横書きにする | R-30 | B-6、https://developer.apple.com/design/human-interface-guidelines/typography |
| 11 | 今の本に一行がないときは、W-1・W-2 に書名（名無しの今の本なら「今の本」）と「p.120」を横書きで出す。今の本がないときは `widget.empty` の文を出す | R-18、R-26 | B-1、https://developer.apple.com/design/human-interface-guidelines/widgets |
| 12 | ロック画面と Live Activity は周りの人にも見えるため、設定に「一行と書名を隠す」（`settings.hideOnWidgets`）を置き、オンのときは W-1・W-2・W-3 に「しおり」とページ（または経過時間）だけを出す | R-17、R-18、R-20 | https://developer.apple.com/design/human-interface-guidelines/live-activities 、https://developer.apple.com/design/human-interface-guidelines/privacy |
| 13 | ウィジェットのギャラリーの見本も、今の本があれば利用者自身の一行をそのまま出し、なければ例文を出す。placeholder は灰の帯（redacted）にする | R-18、R-33 | https://developer.apple.com/design/human-interface-guidelines/widgets 、https://developer.apple.com/design/human-interface-guidelines/loading |
| 14 | S-1 の主操作は下端固定の「読み始める」（`bookmark.start`）と、iPhone を1.0秒伏せて置く動作の2つを対等に置く。伏せられない場面（片手、ベッド、電子書籍を同じ iPhone で読むとき）でも1タップで始められるようにする | R-1、R-29 | B-2、https://developer.apple.com/design/human-interface-guidelines/accessibility |
| 15 | S-2（読書中）の押せる要素は下端の「終える」（`reading.end`）1つだけにし、タブバーもナビゲーションバーも隠す。動く秒時計は置かず、「21:04 から数えています。」と静かに書く。「終える」と「読み終えた」には確認ダイアログを挟まない（押し間違いは記録の編集・本棚から戻せるため） | R-2、R-4、R-12、R-23 | B-1、B-2、https://developer.apple.com/design/human-interface-guidelines/alerts |
| 16 | S-3（しおりを挟む）には5つの道（`mark.photo`、`mark.screenshot`、`mark.manual`、`mark.pageOnly`、`mark.later`）を1画面に並べる。紙の本でカメラが使えるときは「ページを撮る」（`mark.photo`）を主操作（`.borderedProminent`）にし、カメラ拒否時や電子書籍（`isEbook = true`）のときは「スクリーンショットから選ぶ」（`mark.screenshot`）または前回使った道を主操作にする | R-13、R-18、R-79、R-84 | B-2、https://developer.apple.com/design/human-interface-guidelines/buttons |
| 17 | 「あとで挟む」（`mark.later`）は `.bordered` の小さいボタン（幅いっぱいにしない）で下に置き、「しおりは前のまま残ります。」（しおりが空なら「しおりは空のままです。」）を添える | R-25、R-26 | B-2、https://developer.apple.com/design/human-interface-guidelines/writing |
| 18 | S-3a は一行の欄（`mark.lineField`）に焦点を当てて開く。場所（ページ・位置・％）は任意。前の値は欄の下の消えない説明（`mark.page.previous`、`color.text.secondary`）に「前のページは43です。空のまま保存すると、43のまま残ります。」と出し、プレースホルダは「例 61」の手がかりだけにする。欄が空なら前の値をそのまま保つ | R-12、R-23、R-24、R-26 | https://developer.apple.com/design/human-interface-guidelines/text-fields 、https://developer.apple.com/design/human-interface-guidelines/accessibility |
| 19 | S-3b（場所だけ入れる）の欄の下に、保存すると一行が消えてロック画面には書名とページ（または位置・％）が出ることを書く | R-26、R-35 | https://developer.apple.com/design/human-interface-guidelines/writing |
| 20 | S-4（結果）は「p.43 → p.61」（または「位置1200 → 位置1450」「34% → 52%」）「18分」と「記録しました。」だけを出す。祝う言葉、紙吹雪、バッジ、触覚、音を出さない | R-4、R-12、R-31 | B-2、https://developer.apple.com/design/human-interface-guidelines/design-principles |
| 21 | ロック画面への置き方の案内（S-5、`widgetGuide`）は、最初に一行を保存して S-1 に戻ったときに1回だけ、シートで、利用者の一行を実際の大きさ（172×76 pt）の見本で見せる | R-18、R-27 | https://developer.apple.com/design/human-interface-guidelines/onboarding 、https://developer.apple.com/design/human-interface-guidelines/sheets |
| 22 | 初めて開いたときに案内画面、サインイン、許可の確認を出さない。S-1 の空の状態から「本を加える」（`bookmark.addBook`）だけを出す（AC-1） | R-27、R-33 | https://developer.apple.com/design/human-interface-guidelines/onboarding |
| 23 | カメラの許可は「バーコードを続けて読む」「表紙・背表紙を撮る」「本棚・積読をまとめて撮る」「ページを撮る」「奥付を撮って補う」を押したときにだけ求め、前に説明画面を挟まない。写真とスクリーンショットの選択は `PhotosPicker` を使い、写真ライブラリの許可を一切求めない（AC-12、AC-70、AC-142） | R-9、R-27、R-84 | https://developer.apple.com/design/human-interface-guidelines/privacy |
| 24 | 本を加える入口（S-8）は1つのシートの一覧に道を並べ、「バーコードを続けて読む」（`register.barcode`）を先頭にし、続けて「表紙・背表紙を撮る」（`register.cover`）、「スクリーンショットから選ぶ」（`register.screenshot`）、「本棚・積読をまとめて撮る」（`register.bookshelf`）、「手で入れる・書名で探す」（`register.manual`）、および今の本が0冊で名無しの本がないときの「あとで（すぐ読み始める）」（`register.later`）を置く | R-5、R-7、R-8、R-10 | B-1、https://developer.apple.com/design/human-interface-guidelines/lists-and-tables |
| 25 | バーコード連続読み取り（S-8a）では、新しい ISBN が読めるたびに触覚（`haptic.barcodeRead`）1回と一覧の行（`scan.row.<ISBN>`）で知らせ、端末内書誌 DB（H20）から 0.3秒以内に書名・著者・出版社・レーベルを埋める。既登録の本は知らせ `scan.duplicate` を出し、同じ回の2度目と本でないコード（49 等）は無視する | R-5、R-28、R-78 | https://developer.apple.com/design/human-interface-guidelines/playing-haptics |
| 26 | S-8a で読んだ本が1冊以上あるのに閉じるときは、確認ダイアログを出す。その間は戻るボタンを隠し（`navigationBarBackButtonHidden`）、シートを払って閉じる操作を止め（`interactiveDismissDisabled`）、出る道を「閉じる」（`role: .cancel`）→ 確認だけにする（0冊のときは確認なしで閉じられ、`role: .close`） | R-23 | https://developer.apple.com/design/human-interface-guidelines/action-sheets 、https://developer.apple.com/design/human-interface-guidelines/sheets |
| 27 | 書名で探す機能は別の検索画面に分断せず、S-8c「手で入れる」（`register.manual`）の書名欄（`manual.title`）に統合する。3字以上入れると端末内書誌 DB（H20、FTS5 trigram）から 0.3秒以内に最大20件の候補 `search.row.<ISBN>` を出し、押すと書名・著者・出版社・レーベル・出版年・ISBN を欄に自動入力する。0件のときは `search.noResults` を出し、そのまま手入力で保存できる（AC-4、AC-5、AC-7、AC-149） | R-5、R-7、R-45、R-78 | B-1、https://developer.apple.com/design/human-interface-guidelines/search-fields 、https://developer.apple.com/design/human-interface-guidelines/entering-data |
| 28 | 空、エラー、オフラインの画面は `ContentUnavailableView` で、何が起きたかと次の一手のボタンを出す | R-26、R-33 | B-1、https://developer.apple.com/design/human-interface-guidelines/writing |
| 29 | 読み込みに 0.3秒を超えたら形を先に出す（redacted の灰の帯）。読み込み中に「0冊」「0件」を出さない | R-33 | https://developer.apple.com/design/human-interface-guidelines/loading |
| 30 | アプリ本体とウィジェットから外部への HTTP 通信は一切行わない（AC-103）。書誌データは国立国会図書館の CC BY 4.0 書誌データを加工した SQLite DB を Apple-Hosted Background Assets で端末に配る（H20）。機内モードでもバーコードと書名候補が待ち時間0秒で動く（AC-6） | R-78、R-85 | B-1、https://developer.apple.com/design/human-interface-guidelines/privacy |
| 31 | S-8a で端末内書誌 DB が未取得（`notDownloaded`）のとき（`scan.dbNotReady`）や、DB にない ISBN を読んだとき（`scan.notFound`）は、通信を待たずにその場の行に `scan.row.editTitle`（書名入力欄）と `scan.row.captureCover`（表紙・背表紙を撮るボタン）を出す。2段目のバーコード（192 で始まる Cコード）が読めていれば判型（「文庫」など）を、ISBN の出版社記号が同梱辞書に合えば出版社名を自動で補う（AC-3、AC-9、AC-10、AC-11） | R-5、R-69、R-70、R-78 | B-1、https://developer.apple.com/design/human-interface-guidelines/entering-data |
| 32 | 本棚（S-6）は1つの `List` に3つの区分（`shelf.current`、`shelf.tsundoku`、`shelf.finished`）を並べる。並べ替えボタン、タブ、表紙のサムネイル、統計グラフを置かない | R-8、R-9、R-12 | B-2、https://developer.apple.com/design/human-interface-guidelines/lists-and-tables |
| 33 | 奥付（S-7 の `book.colophon`、S-9 の `finish.colophon`）は本の最後のページの型（項目名と値の2列を上下の罫線の間に並べる）にする。データのない行は出さず、「不明」「なし」「受賞なし」と書かない（AC-17、AC-18、D-2） | R-15、R-23、R-35、R-55 | B-1、B-3 |
| 34 | S-7 の記録の行（`book.record.row.<id>`）は晩の日付（4:00 境目、記録時のタイムゾーン固定）と分だけを出す。行を押すと直す・消すのシート（S-7b）が開き、消す前に `confirmationDialog` を出す | R-1、R-7、R-23 | https://developer.apple.com/design/human-interface-guidelines/action-sheets 、https://developer.apple.com/design/human-interface-guidelines/lists-and-tables |
| 35 | 本を消す確認の文（`book.delete.confirm`）に、一緒に消える記録の件数を入れる（記録0件のときは `book.delete.confirm.noRecords`） | R-23、R-26 | https://developer.apple.com/design/human-interface-guidelines/action-sheets |
| 36 | 「この本を読む」（`book.readThis`）は S-7 の下端の主操作にする。押すとその本を `current` にして S-1 に戻り、その本の続きを出す | R-18、R-33 | B-1、https://developer.apple.com/design/human-interface-guidelines/buttons |
| 37 | 読み終えた画面（S-9）は1つのスクロール（見出し → ふりかえりの1行 → 奥付とカード共有 → 次の1冊 → 戻し方の1行）にする。紙吹雪や祝う演出を置かず、毎晩の道には出さない（AC-86、D-2） | R-4、R-6、R-9、R-23 | B-2、https://developer.apple.com/design/human-interface-guidelines/design-principles |
| 38 | S-9 の「次の1冊」は最大3冊（`next.candidate.<id>`）にする。積読の本（`tsundoku`）を先に出し（ボタンは「この本を読む」`next.choose`）、3冊に足りない枠に端末内書誌 DB（H20）・同梱の受賞一覧（H25）・共起テーブルから未所有の本を補う（ボタンは「積読に加える」`next.addToShelf`）。理由は確かめられる事実1行（「積読から・同じ著者」「シリーズの次の巻」「同じ賞（第157回 直木三十五賞）」「この本を読み終えた人が、次に読んだ本」など）だけにする（AC-78〜AC-83、AC-87、AC-148） | R-6、R-9、R-31、R-35、R-86 | B-2、B-5、https://developer.apple.com/design/human-interface-guidelines/writing |
| 39 | S-9 の下に、まだ読み終えていなかったときの戻し方（`finish.undoNote`）と、今は次の本を選ばない人のための「今は読まない」（`next.skip`）を置く | R-1、R-23 | https://developer.apple.com/design/human-interface-guidelines/writing |
| 40 | 設定（S-10）は1つの `Form`（読み始め、ロック画面、見た目と購入、書誌データ、情報の5節）にする | R-9、R-16、R-87 | B-1、https://developer.apple.com/design/human-interface-guidelines/toggles |
| 41 | プライバシーポリシー（`settings.privacyPolicy`）と書誌の出どころ（`settings.dataSources`）は S-10 の「情報」に置き、毎晩の画面（S-1、S-2）には置かない（AC-43、AC-88、AC-93） | R-11、R-12、R-87 | B-2 |
| 42 | 書誌の出どころ（`settings.dataSources`）には、国立国会図書館の二次利用の3条件（①出典と取得日、②加工して端末内書誌 DB を作成した旨、③NDL サーチ API を用いて作成した旨）、書誌データの版、および「『この本を読み終えた人が、次に読んだ本』の候補は、利用者の同意のもとで集計した読書順序データに基づくもので、国立国会図書館のデータとは無関係です」を明記し、すぐ下に CC BY 4.0 ライセンスへのリンク（`settings.dataSources.license`）を置く（AC-93） | R-35、R-85 | B-1、https://developer.apple.com/design/human-interface-guidelines/privacy |
| 43 | 知らせ（部品 N）は画面の中の帯で、閉じるか次の操作まで出し、時間で勝手に消さない。出たときに1回読み上げる。S-1 に知らせかシートか確認が出ている間は伏せる道を止め、伏せる案内の1行を出さない（AC-47） | R-26、R-29 | https://developer.apple.com/design/human-interface-guidelines/alerts 、https://developer.apple.com/design/human-interface-guidelines/accessibility |
| 44 | エラーの文は、何が起きたかとどう直すかを書き、利用者を責めない。入力した文字を消さない。文字は本文の色（`color.text.primary`）にし、記号（`exclamationmark.circle`）だけ赤（`color.state.error`）にする | R-24、R-26 | B-5、https://developer.apple.com/design/human-interface-guidelines/writing |
| 45 | 文言はです・ます調で淡々と書き、感嘆符と絵文字を使わない。ボタンは動詞で始める。英語も同じ調子にする | R-21、R-26、R-31 | https://developer.apple.com/design/human-interface-guidelines/writing |
| 46 | 2つ目の文字の色（`color.text.secondary`）は独自の値（標準の見た目はライト #6C6C70、ダーク #98989F）にする。システムの `secondaryLabel` はライトで約 3.44:1 で 4.5:1 に届かないため | R-24、R-25 | https://developer.apple.com/design/human-interface-guidelines/accessibility 、https://developer.apple.com/design/human-interface-guidelines/color |
| 47 | 標準の見た目の主操作は文字の色（ライトは黒地に白、ダークは白地に黒）にする。`.borderedProminent` には `tint` と `foregroundStyle` を必ず明示する | R-2、R-19、R-24、R-25 | B-5、https://developer.apple.com/design/human-interface-guidelines/color 、https://developer.apple.com/design/human-interface-guidelines/buttons |
| 48 | `Toggle` のオンはシステムの緑（`systemGreen`）のままにし、アプリの `tint` を当てない | R-25 | https://developer.apple.com/design/human-interface-guidelines/toggles |
| 49 | 触覚は、伏せて始まった時（`.start`）と新しいバーコードが読めた時（`.success`）の2つだけにする | R-28 | https://developer.apple.com/design/human-interface-guidelines/playing-haptics |
| 50 | 動きはシステムの押し出しとシートだけにし、独自の動きを作らない | R-12、R-20 | B-2、https://developer.apple.com/design/human-interface-guidelines/accessibility |
| 51 | Liquid Glass はツールバーのボタンとシートなどシステムの操作の層だけにし、一行、奥付、一覧の地には素材を使わない | R-25 | https://developer.apple.com/design/human-interface-guidelines/materials |
| 52 | 押せる範囲はすべて 44×44 pt 以上にする。`.bordered` の小さいボタン（`mark.later`、`notice.close`）や検索欄の消すボタン、写真上の読み取り枠にも 44×44 pt 以上のヒット領域を付ける | R-24 | https://developer.apple.com/design/human-interface-guidelines/buttons |
| 53 | 一行の読み上げは全体を1つのラベルにし、縦書き用の字形（U+FE11 等）を使わず保存した一行から作る。「p.61」は「61ページ」、「位置1450」は「位置1450」、「52%」は「52パーセント」と読ませる | R-24、R-81 | https://developer.apple.com/design/human-interface-guidelines/accessibility |
| 54 | S-1 の伏せる案内の1行は、紙の本のときは `bookmark.flipHint`（「この画面で iPhone を伏せて置いても、読み始めます。」）、電子書籍（`isEbook = true`）のときは `bookmark.flipHint.ebook`（「別の端末で読むなら伏せて置いても、この iPhone で読むなら『読み始める』を押して他のアプリに移っても数えられます。」）を出す（AC-50、AC-144。Takuma が決めた） | R-29、R-82、R-83 | https://developer.apple.com/design/human-interface-guidelines/accessibility 、https://developer.apple.com/design/human-interface-guidelines/writing |
| 55 | シートの閉じる、取り消す、保存は、ツールバーの標準の記号のボタン（`Button` の `role: .close`、`.cancel`、`.confirm`）にする | R-23 | https://developer.apple.com/design/human-interface-guidelines/toolbars 、https://developer.apple.com/design/human-interface-guidelines/sheets |
| 56 | 日付、時刻、数は端末の言語の書式（`Date.FormatStyle`）に従う。記録の行は「10/17」、晩の長い書き方は「10月17日の晩」。ページ数・位置番号・出版年に桁区切りのカンマを入れない | R-26 | https://developer.apple.com/design/human-interface-guidelines/writing |
| 57 | 時間は60分未満を「18分」、60分以上を「1時間25分」と書く（ふりかえりの1行 `finish.reflection.multi` は合計分数と時間・分を併記して「142分（2時間22分）」とする。AC-127、AC-128） | R-26、R-31 | https://developer.apple.com/design/human-interface-guidelines/writing |
| 58 | 消す操作（`book.delete`、`record.delete`）は `role: .destructive` のまま、見える文字は本文の色（`color.text.primary`）にし、赤は記号 `trash` だけにする | R-23、R-24 | https://developer.apple.com/design/human-interface-guidelines/accessibility 、https://developer.apple.com/design/human-interface-guidelines/color |
| 59 | 下端の主操作（S-1、S-2、S-3c、S-4、S-7、S-7c、S-8a、S-8b、S-8d）は `safeAreaInset(edge: .bottom)` で下端に固定し、上の内容だけをスクロールさせる。AX5 でも主操作が画面の外に出ない | R-24 | B-2、https://developer.apple.com/design/human-interface-guidelines/accessibility |
| 60 | 読み上げのラベルは見える文字から始める。見える文字と読み上げを変える押せる要素（記録の行 `book.record.row.<id>`）は、見える文字（「10/17」）を `accessibilityInputLabels` に入れ、音声コントロールで見える文字のまま押せるようにする | R-24 | https://developer.apple.com/design/human-interface-guidelines/accessibility |
| 61 | S-2 の始めた時刻は、読み始めた晩が今の晩と違うとき（翌朝に開き直したときなど）だけ、月日を足す（「10月17日 21:04 から数えています。」） | R-26 | https://developer.apple.com/design/human-interface-guidelines/writing |
| 62 | 行頭の禁則の字は、JLREQ（3.1.7）の行頭禁則の類（終わり括弧、ハイフン・長音、区切り約物、中点、句読点、繰返し記号、小さい仮名）をすべてとる。追い出しが増えても字は欠けさせない（AC-28） | R-30 | B-6、https://developer.apple.com/design/human-interface-guidelines/typography |
| 63 | 全角に直した記号の縦書きの向きは Unicode UAX #50（VerticalOrientation.txt）に従う | R-30 | B-6、https://developer.apple.com/design/human-interface-guidelines/typography |
| 64 | S-1 の縦書きの場所（A_w と A_h）は、幅＝画面の幅−32pt、高さ＝画面の高さ×0.4 の切り捨てにする。60字が送りを含めて幅に入らないときと accessibility1 以上は横書きにする | R-24、R-30 | B-3、B-6、https://developer.apple.com/design/human-interface-guidelines/typography |
| 65 | アプリが動いているときに入口の URL（W-1、W-2、W-3）が来たら、シート・全画面の流れ（S-2〜S-4）・確認ダイアログが開いていれば画面を変えず、どれも開いていなければ押し出した画面（S-6、S-7、S-10、S-10a）を動きなしで閉じて S-1 にする | R-5、R-18、R-23 | B-1、https://developer.apple.com/design/human-interface-guidelines/sheets 、https://developer.apple.com/design/human-interface-guidelines/widgets |
| 66 | 書名がまだ入っていない今の本（`register.later` で作った `isTitlePending = true` の本。AC-139）は、S-1 の `bookmark.title`、S-2、W-1・W-2（H22）、W-3（H23）の書名の位置にすべて `widget.currentBookAsTitle`（「今の本」／Reading Now）を出す（Takuma が決めた） | R-18、R-23、R-26、R-35 | B-1、B-2、https://developer.apple.com/design/human-interface-guidelines/widgets 、https://developer.apple.com/design/human-interface-guidelines/accessibility |
| 67 | ページ・スクリーンショットから一行を選ぶ画面（S-3c、`AC-65`〜`AC-69`、`AC-94`、`AC-142`）では、検出した縦の列（横組みなら横の行）に右から `mark.ocr.column.1`〜`<n>` の白黒2重線の枠を付け、日本語の縦組みで最後に読み止める可能性がいちばん高い「いちばん左の列」（`mark.ocr.column.<n>`。横組みならいちばん下の行）を最初に選んだ状態にして `mark.lineField` に入れる。待ちの間も `mark.manual` と `mark.pageOnly` を押せるままにし、画像は一切保存しない | R-36、R-38、R-42、R-45、R-60 | B-1、B-5、https://developer.apple.com/design/human-interface-guidelines/entering-data 、https://developer.apple.com/design/human-interface-guidelines/privacy |
| 68 | 表紙・背表紙・スクリーンショットから1冊を加える画面（S-8b、`AC-137`）では、読み取った行 `cover.ocr.line.1`〜`<n>` のうち、利用者の1回目のタップを書名（`cover.selectTitle` → `manual.title`）、2回目のタップを著者（`cover.selectAuthor` → `manual.author`）に入れる。自動で欄に振り分けたときの取り違え（名刺・レシートの不満 R-51、R-52）を防ぎ、枠に「書名」「著者」の札を付けて下の欄でそのまま直せるようにする | R-36、R-45、R-51、R-52 | B-1、B-5、https://developer.apple.com/design/human-interface-guidelines/entering-data |
| 69 | 本棚・積読の1枚の写真から複数冊を加える画面（S-8d、`AC-138`）では、背表紙の枠を押すごとに下の候補一覧に `bookshelf.row.<n>` を足す。端末内書誌 DB（H20）で完全一致がちょうど1件の本だけ著者・出版社・ISBN を自動補完し、複数件ある書名（「こころ」など）は違う版を勝手に当てないよう書名だけで加える（Vivino の誤マッチ不満 R-54 を防ぐ） | R-42、R-49、R-54、R-77 | B-1、https://developer.apple.com/design/human-interface-guidelines/entering-data |
| 70 | 奥付を1枚撮って補う画面（S-7c、`colophon.capture`、`AC-77`、`AC-113`、`AC-140`）では、奥付のラベル（「著者」「発行所」「発行」「ISBN」など）から抜き出した著者・出版社・レーベル・出版年・ISBN（および名無しの本のときは書名）を確認欄に入れ、`colophon.save` の1タップで奥付を更新する | R-55、R-77 | B-1、B-3、https://developer.apple.com/design/human-interface-guidelines/entering-data |
| 71 | 書名を「あとで」にして今すぐ読み始める道（`register.later`、`AC-139`、`AC-140`）は、今の本が0冊で、かつ本棚に `isTitlePending = true` の本が0冊のときだけ S-8 に出す。名無しの本が何冊も本棚に溜まって区別できなくなるのを防ぐため、名無しの今の本がある間は2冊目の `register.later` を出さず、S-1 に `bookmark.setBookTitle`（「書名を入れる」）を出し、別の本を `current` に切り替えようとしたときは確認ダイアログ（`book.pendingTitleGuard`）で先に書名を入れるか尋ねる | R-23、R-26、R-47 | B-1、B-2、https://developer.apple.com/design/human-interface-guidelines/action-sheets |
| 72 | 電子書籍（`isEbook = true`、`AC-141`〜`AC-144`）では、本ごとに進捗の単位 `progressUnit`（`page` 1〜9999、`location` 1〜999999、`percent` 0〜100）を持てるようにし、S-3a・S-3b・S-3c の `mark.progressUnit`（セグメントピッカー）で切り替えられるようにする。Kindle の位置番号や％だけの本でもしおりとウィジェットと「どこまで読んだ？」が一貫して動くようにする | R-79、R-80、R-81 | B-1、https://developer.apple.com/design/human-interface-guidelines/pickers |
| 73 | おすすめを出す場所は、(1) 読み終えた画面 S-9 の「次の1冊」（最大3冊、`next.candidate.<id>`）、(2) 今の本が0冊で積読があるときの S-1（最大3冊、`bookmark.noCurrent.next.<id>`、`AC-145`）、(3) 読み終えた本の詳細画面 S-7 の「この本のあとに」（最大5冊、`after.candidate.<ISBNまたは受賞ID>`、`AC-146`）の3か所に限る。今の本があるときの毎晩の道には一切出さない（`AC-86`） | R-6、R-9、R-86 | B-1、B-2 |
| 74 | 端末内の好みの重み付け（`AC-147`）は、推薦の理由の軸（`readers`、`nextVolume`、`sameAuthor`、`sameAward`、`sameLabel`）ごとに `score = chosen * 2 - skipped` を端末内だけで計算し、よく選ぶ軸を上に繰り上げる。画面に「AI」「機械学習」とは一切書かず、事実の理由1行のままにする | R-56、R-72、R-76、R-86 | B-5、https://developer.apple.com/design/human-interface-guidelines/machine-learning |
| 75 | 共起の推薦行（`rec.reason.readers`「この本を読み終えた人が、次に読んだ本」、`AC-148`）は、端末内書誌 DB（H20）の共起テーブルで `count >= 10` かつ `toISBN` の NDC が `9`（文学）で始まる未所有の本だけを出す。少人数の推測やビジネス書・実用書からの内面の推測を防ぎ、画面には人数の数字（「12人」など）を一切出さない | R-71、R-85、R-86 | B-5、https://developer.apple.com/design/human-interface-guidelines/privacy |
| 76 | 読み終えた画面（S-9）のふりかえりの1行（`finish.reflection`、`AC-127`〜`AC-129`）は、生成 AI を使わず記録の晩の数と分数から定型文（2晩以上は `finish.reflection.multi`、1晩は `finish.reflection.single`、0件なら非表示）で組む。共有するカード画像（`finish.card.share`、`AC-84`、`AC-85`）には書名・著者・何晩・合計時間だけを描き、ふりかえりの1行も本の一行も写真も載せない | R-4、R-31、R-68 | B-2、https://developer.apple.com/design/human-interface-guidelines/privacy |
| 77 | 夜の入口の予約 Live Activity（W-3、`AC-36`〜`AC-38`、`AC-41`、`AC-97`、`AC-98`、`AC-130`、`AC-136`）は、設定した時刻（`settings.entryTime`、既定 21:00、15分刻み）に `Activity.request(...start:)` でロック画面に出し、`staleDate` を翌朝 4:00 にする。読書が始まったら経過時間と「終える」（`liveActivity.end`）1ボタンだけの表示に切り替え、終えたらその晩の分数とページを出して終える | R-17、R-61、R-87 | B-1、B-2、https://developer.apple.com/design/human-interface-guidelines/live-activities |
| 78 | ロック画面・コントロールセンター・アクションボタンの Control（W-4、`AC-114`、`AC-126`）は、トグルではなく単発の `ControlWidgetButton`（「読み始める」`control.startReading`）1つだけにする。Siri・ショートカット（W-5、`AC-114`〜`AC-126`、`AC-131`〜`AC-135`、`AC-143`）は「読み始める」「どこまで読んだ？」「続きを読む」の3つにし、日本語フレーズでアプリ名の直後に「で」を続けない（「よむまで」が「読むまで」と誤認されるのを防ぐため） | R-20、R-62〜R-67、R-73〜R-75 | B-1、https://developer.apple.com/design/human-interface-guidelines/controls 、https://developer.apple.com/design/human-interface-guidelines/siri |
| 79 | 「どこまで読んだ？」のインテント（`AC-121`〜`AC-123`、`AC-133`、`AC-143`）は `authenticationPolicy = .alwaysAllowed` にし、ロック中でも声と1行の小窓でページ・位置番号・％だけ（「61ページからです。」「位置1450からです。」「52パーセントからです。」）を答え、一行の文字列と書名は声にも小窓にも出さない | R-63、R-67、R-81 | https://developer.apple.com/design/human-interface-guidelines/siri 、https://developer.apple.com/design/human-interface-guidelines/privacy |
| 80 | 有料の見た目「よむま＋」（買い切り、商品 ID `jp.yomuma.plus`、`AC-104`〜`AC-111`）は、設定（S-10）の「見た目」（`settings.appearance`）の中だけに置き、毎晩の道や読み終えた画面には一切購入の案内を出さない。未購入で鍵つきの見た目（生成り `kinari`・墨 `sumi`・朱 `shu`）を押したときだけ、その見た目を当てた見本（`store.preview`）と買い切りの購入シート（`store.buy`、`store.restore`、`store.close`）を出す。S-10 にも「購入を復元する」（`settings.restorePurchases`）を置く | R-5、R-9、R-16、R-68、R-87 | B-2、https://developer.apple.com/design/human-interface-guidelines/in-app-purchase |
| 81 | 写真やスクリーンショットの上に描く読み取り枠（S-3c の `mark.ocr.column.<n>`、S-8b の `cover.ocr.line.<n>`、S-8d の背表紙枠）は、白い紙の上でも暗い表紙の上でも 3:1 以上のコントラストを保つため、外側黒（`#000000` 2pt）・内側白（`#FFFFFF` 2pt、選択時は 3pt）の2重線にし、番号と役割札（「1」「書名」「著者」）を付けて色だけで区別しない | R-24、R-36、R-37 | B-5、https://developer.apple.com/design/human-interface-guidelines/accessibility |

---

## 5. 画面ごとの状態

空とエラーには「何が起きたか」と「次の一手のボタン」を必ず置く。読み込み中は 0.3秒を超えたら形を先に出し（redacted）、空の状態を先に出さない。知らせ（部品 N）は閉じるか次の操作まで出したままにする。すべての画面の7つの状態を埋め、「なし」にはすべて理由を括弧で添える。

| 画面 | 通常 | 空 | 読み込み中 | エラー | オフライン | 権限を断られたとき | 一部だけ読めたとき |
|---|---|---|---|---|---|---|---|
| W-1 | 縦書きの一行（25字まで）を右から組み、左端の帯の下に「p.61」（電子書籍の位置・％なら「位置1450」「52%」） | 今の本なし（本0冊も）：`widget.empty`。一行なし：書名と「p.120」。ページもなし：書名だけ。一行あり・ページなし：一行だけ（帯は空けたまま） | placeholder は一行の形の灰の帯（redacted）。本の文を出さない | 写しを読めない（バックアップから戻した直後など）：`widget.unavailable`「よむまを開くと、ここに続きの一行が出ます。」。押すと S-1 | なし（App Group の写しを読むだけで通信を使わない） | なし（OS の許可を使わない。「一行と書名を隠す」がオンのときは `widget.hidden`「しおり」とページだけを出す。AC-34） | 26字以上の一行：AC-29 の縮め方で25字まで。名無しの今の本（`isTitlePending = true`）：一行があれば一行とページ、一行がなければ書名の所に `widget.currentBookAsTitle`「今の本」とページ（ページもなければ「今の本」だけ）。日本語の字を含まない一行：横書き（AC-30） |
| W-2 | 縦書きの一行と「p.61」（または「位置1450」「52%」。列は上にそろえ、ページは列の下の左端。選んだ見た目 `appearanceID` の色トークンを適用） | W-1 と同じ（一行あり・ページなしは一行だけ） | W-1 と同じ | W-1 と同じ | なし（通信を使わない） | なし（許可を使わない。隠す設定は W-1 と同じ） | W-1 と同じ。暗い所の StandBy はシステムが赤の単色で描く（AC-35） |
| W-3 | 予定の時刻の待つ状態（`waiting`）：書名、一行（横書き）、ページ（押すと S-1）。読書中（`reading`）：書名、開始時刻からの経過時間、`liveActivity.end`「終える」ボタン1つ（AC-41、AC-114）。終えた直後（`ended`）：「10分」「p.61」 | 一行がない今の本の待つ状態：書名とページ（ページもなければ書名だけ）。今の本がないときは予約を作らない | なし（予約または開始の時点で値が確定している） | 予約や開始の要求が失敗したときは Live Activity を出さず、アプリ側の画面（S-2 または S-4）でそのまま進める（AC-97、AC-131）。「終える」で保存に失敗したときは Live Activity を消さず S-2 に `session.save.error` を出す（AC-132） | なし（端末内の時計と ActivityKit だけで動き、通信を使わない。AC-125） | Live Activity がオフ（`areActivitiesEnabled == false`）：Live Activity は出ず、アラートも出さない（S-10 に `settings.liveActivity.off` を出す。AC-37、AC-118） | `settings.hideOnWidgets` がオン：書名と一行を出さず `widget.hidden`「しおり」とページ（読書中は「しおり」と経過時間と「終える」）だけを出す（AC-34、AC-120）。名無しの今の本：書名の所に `widget.currentBookAsTitle`「今の本」を出す（AC-139） |
| W-4 | ロック画面・コントロールセンター・アクションボタンに `control.startReading`「読み始める」（記号 `book`）の単発ボタン1つを出す（AC-126） | 今の本がないときに押されたら、アプリを前に出して S-1 の空状態を見せる（AC-117） | 押してから 0.5秒以内に `reading` にして Live Activity を出す（AC-114） | 保存に失敗したときは声・通知で `session.start.error` を返し `idle` のままにする（AC-119）。Live Activity の要求だけ失敗したときはアプリを前に出して S-2 を出す（AC-131） | なし（通信を使わない。機内モードでもそのまま動く。AC-125） | Live Activity がオフのときは、その場で `reading` にしてアプリを前に出し S-2 を出す（AC-118） | すでに `reading` のときに押されたら、二重に始めず `intent.start.alreadyReading` を返す（AC-115） |
| W-5 | 「読み始める」：`intent.start.started` を声で返し Live Activity を開始。「どこまで読んだ？」：声と1行の小窓で `intent.whereStopped.page` / `location` / `percent` を返す。「続きを読む」：アプリを前に出して S-1 を開く | 「どこまで読んだ？」で進み具合がないときは `intent.whereStopped.noPage`、今の本がないときは `intent.whereStopped.noCurrent` を返す（AC-122）。「読み始める」「続きを読む」で今の本がないときは S-1 の空状態を開く（AC-117、AC-135） | なし（ローカルの SwiftData / 写しを読むだけで 0.5秒以内に返る） | 「どこまで読んだ？」で読み込みに失敗したときは `intent.whereStopped.error` を返す（AC-133）。「読み始める」で保存に失敗したときは `session.start.error` を返す（AC-119） | なし（通信を使わない。機内モードでも3つともそのまま動く。AC-125） | なし（「どこまで読んだ？」は `alwaysAllowed` でロック中も認証を求めない。`settings.hideOnWidgets` がオンでもページ・位置・％だけを答え、一行と書名は出さない。AC-121、AC-123） | すでに `reading` のときに「続きを読む」を動かすと S-2 を前に出し（AC-134）、「読み始める」を動かすと `intent.start.alreadyReading` を返す（AC-115） |
| S-1 | 書名、著者、縦書きの一行（全文）、「p.61」（または「位置1450」「52%」）、`bookmark.setMark`、`bookmark.finish`（`.bordered`）、下端に固定した `bookmark.start`、伏せる案内の1行（紙の本は `bookmark.flipHint`、電子書籍は `bookmark.flipHint.ebook`） | 本0冊：`ContentUnavailableView`（`bookmark.empty.title`、`bookmark.empty.message`、`bookmark.addBook`）。今の本なし・積読あり：`bookmark.noCurrent.title`、`bookmark.noCurrent.message`、積読から最大3冊の候補 `bookmark.noCurrent.next.<id>`（各行に `bookmark.noCurrent.choose`）と `bookmark.openShelf`（AC-145）。今の本なし・積読0冊：`bookmark.noCurrent.title`、`bookmark.noCurrent.message`、`bookmark.openShelf`。一行も場所もない：書名の下に `bookmark.noMark.message` | 起動して保存先を読む間、0.3秒を超えたら書名と一行の形の灰の帯（redacted）。空の状態を先に出さない | 保存先を読めない：`ContentUnavailableView`（`store.load.error.title`、`store.load.error`、`store.retry`）だけで、ツールバーは「設定」だけ（AC-90）。読み始めの保存失敗：知らせ `session.start.error`（AC-59）。読み終えたの保存失敗：知らせ `common.save.error`（AC-91） | なし（毎晩の道は通信を一切使わない。AC-62） | なし（S-1 自体は OS の許可を使わない。伏せ検知が使えない端末 H18 やオフのときは `bookmark.flipHint` を出さない。AC-51） | 名無しの今の本（`isTitlePending = true`）：`bookmark.title` に `widget.currentBookAsTitle`「今の本」を出し、下に `bookmark.setBookTitle`「書名を入れる」（`.bordered`）を出す（AC-139、AC-140）。一行あり・場所なし：場所の行を出さない。一行なし・場所あり：縦書きの所を詰め、著者の下に場所を出す |
| S-2 | 書名（`reading.title`）、「21:04 から数えています。」（`reading.startedAt`）、数え続けることの1行（紙の本は `reading.note`、電子書籍は `reading.ebookNote`。AC-144）、下端に固定した「終える」（`reading.end`） | なし（今の本がないと読み始められない。AC-46） | なし（端末内の開始時刻を出すだけ。開き直したときは S-1 と同じ読み込みのあとに出す） | 終わりの保存の失敗：「終える」のすぐ上に知らせ `session.save.error`（閉じるボタンなし。もう一度 `reading.end` を押せる。AC-60、AC-132） | なし（通信を使わない。AC-62） | なし（許可を使わない） | 名無しの今の本（`isTitlePending = true`）：書名の位置に `widget.currentBookAsTitle`「今の本」を出す（AC-139） |
| S-3 | 書名、問い「どこまで読みましたか。」、5つの道：`mark.photo`（ページを撮る）、`mark.screenshot`（スクリーンショットから選ぶ）、`mark.manual`（一行を入れる）、`mark.pageOnly`（ページ・位置・％だけ入れる）、`mark.later`（あとで挟む）と説明（AC-63） | 前のしおりがない：`mark.later` の下の文を `mark.later.note.empty`「しおりは空のままです。」に替える。読まずに挟むシート（AC-64）では `mark.later` は出さずツールバーに閉じる（`mark.cancel`）を出す | なし（読書の記録は「終える」を押した時点で保存済みで、0.5秒以内に開く。AC-55） | なし（この画面自体は保存を行わない。保存の失敗は S-3a〜S-3c で出す） | なし（通信を使わない。AC-62） | カメラの許可を断った状態で `mark.photo` を押したとき：カメラは開かず S-3 の中に `camera.denied` と `camera.openSettings`（「設定を開く」）を出し、同じ画面の `mark.screenshot`、`mark.manual`、`mark.pageOnly`、`mark.later` はそのまま押せる（AC-70、AC-142） | 名無しの今の本：書名の位置に `widget.currentBookAsTitle`「今の本」を出す。電子書籍（`isEbook = true`）：`mark.pageOnly` の表示文を進捗単位に合わせて出す |
| S-3a | 一行の欄（`mark.lineField`、焦点）、電子書籍のときは単位の切り替え（`mark.progressUnit`：ページ／位置／％）、場所の欄（`mark.pageField`）とその下の消えない説明（`mark.page.previous`）、ツールバーの保存（`mark.save`） | 欄は空で始まる。一行が空のまま保存を押すと `mark.line.invalid`。場所の欄が空なら前の値をそのまま保つ（前の値がなければ空のまま保存できる） | 保存の間は保存ボタンの2度押しを受けない | 入力の誤り：欄のすぐ下に `mark.line.invalid`、`mark.page.invalid`（AC-72、AC-74、AC-141）。保存の失敗：Form のいちばん上の行に `common.save.error`、入れた字は残す（AC-95） | なし（通信を使わない） | なし（許可を使わない） | なし（手入力の画面であり、読み込むのは開く前に確定している前の場所の値だけ） |
| S-3b | 電子書籍のときは単位の切り替え（`mark.progressUnit`：ページ／位置／％）、場所の欄（`mark.pageField`、焦点、数字キーボード）、その下の消えない説明（`mark.page.previous`）と一行が消えることの説明、ツールバーの保存（`mark.save`） | 空のまま保存を押すと `mark.page.invalid`（AC-74）。前の場所がないときは `mark.page.previous` を出さない | S-3a と同じ | 入力の誤り：`mark.page.invalid`（ページは 1〜9999、位置は 1〜999999、％は 0〜100 の外。AC-74、AC-141）。保存の失敗：Form のいちばん上に `common.save.error`、入れた字は残す | なし（通信を使わない） | なし（許可を使わない） | なし（手入力の画面であり、読み込むのは開く前に確定している前の場所の値だけ） |
| S-3c | 上部に撮影したページまたは選んだスクリーンショットと右から `mark.ocr.column.1`〜`<n>` の枠（いちばん左の `<n>` が初期選択）、下に `mark.lineField`（選択した列の文字が入る）、電子書籍なら `mark.progressUnit`、`mark.pageField`、下端に固定した `mark.save`、補助の `mark.retake` と `mark.manual`（AC-65〜AC-67、AC-142） | 読み取れた列が0個：`ContentUnavailableView` で `mark.ocr.none` と、`mark.retake`（「撮り直す」／スクショなら「選び直す」）、`mark.manual`（「手で入れる」）を出し、前のしおりは変えない（AC-68） | 写真を確定してから Vision の結果が返るまでの間：画像の上に ProgressView と灰の帯を出し、その下にある `mark.manual` と `mark.pageOnly` は押せるままにする（押すと 1.0秒以内に S-3a / S-3b に移り、後から返った OCR 結果で上書きしない。AC-94） | 入力の誤り：`mark.line.invalid`、`mark.page.invalid`。保存の失敗：欄の上に `common.save.error`、選んだ文字と場所は残す（AC-95） | なし（Vision の文字認識は端末内だけで動き、通信を使わない） | `mark.screenshot`（`PhotosPicker`）はカメラ許可が拒否でもアラート0個でそのまま動く（AC-142）。カメラ撮影中に権限が外されたときは S-3 に戻って `camera.denied` を出す | ルビや掠れで文字が一部崩れたとき：枠を選んで `mark.lineField` に入った文字をその場で手で直して `mark.save` で保存できる（AC-67）。柱やノンブルからページ数が取れたときは `mark.pageField` に候補として入れ、取れなければ空欄のまま手入力できる |
| S-4 | 書名、`result.summary`（「p.43 → p.61　18分」「位置1200 → 位置1450　18分」「34% → 52%　18分」）、「記録しました。」、下端に固定した「閉じる」（`result.close`） | `mark.later` の晩と、場所を変えずに一行だけ保存した晩：`result.summary` は「18分」だけ（AC-75）。前の場所がない本で初めて場所を入れた晩：「p.61　18分」（AC-76） | なし（保存は前の画面で完了している） | なし（保存の失敗は S-2 と S-3a〜S-3c で出す） | なし（通信を使わない） | なし（許可を使わない） | 経過が 86,460秒（1440分超）で上限に達したとき：`result.summary` の下に知らせ `session.capped` を出す（AC-57） |
| S-5 | 見出し、説明、利用者の一行の見本（172×76 pt、`widgetGuide.preview`）、下端の「閉じる」（`widgetGuide.close`） | なし（初めて一行を保存した直後にだけ出るため、一行は必ずある。AC-96） | なし（S-1 で読み込み済みの一行を使う） | なし（この画面の操作は閉じるだけで、失敗する保存を持たない） | なし（通信を使わない） | なし（許可を使わない） | `settings.hideOnWidgets` がオン：見本も「しおり」とページの形で見せる。場所なし：見本も一行だけ |
| S-6 | 今の本（`shelf.current`）、積読（`shelf.tsundoku`、加えた日の新しい順）、読み終えた（`shelf.finished`、読み終えた日時の新しい順）の3区分（AC-13） | 本0冊：`ContentUnavailableView`（`shelf.empty.title`、`shelf.empty.message`、`shelf.empty.addBook`）。本のない区分は見出しごと出さない | 0.3秒を超えたら行の形の灰の帯を5行（500冊でも 1.0秒以内。AC-101） | 読めない：`ContentUnavailableView`（`shelf.load.error`、`shelf.retry`） | なし（本棚はすべて端末内のデータで通信を使わない） | なし（許可を使わない） | 名無しの今の本（`isTitlePending = true`）：行の書名に `widget.currentBookAsTitle`「今の本」を出す。著者が空の本：著者の行を出さない |
| S-7 | 奥付（`book.colophon`）、奥付を撮って補うボタン（`colophon.capture` / `book.captureColophon`）、記録（何晩、合計、行 `book.record.row.<id>`）、読み終えた本なら「この本のあとに」（`after.header`、未所有の候補最大5冊 `after.candidate.<ISBNまたは受賞ID>`）、この本を消す（`book.delete`）、下端に固定した「この本を読む」（`book.readThis`）、ツールバーの「直す」（`book.edit`） | 記録0件：記録の節に `book.records.empty`（AC-23）。奥付はデータのある行だけ（書名1行だけのこともある。AC-18）。「この本のあとに」の候補が0件のときは `after.header` の節ごと出さない | 0.3秒を超えたら記録の行の形の灰の帯（記録1,000件でも 1.0秒以内。AC-101） | 読めない：`ContentUnavailableView`（`book.load.error`、`book.retry`）。今の本にする・積読に加える・消すの保存失敗：画面の上に知らせ `common.save.error`（AC-91） | なし（奥付も記録も「この本のあとに」の候補もすべて端末内 DB と同梱シードから出し、通信を使わない） | `colophon.capture` を押したときにカメラ許可が拒否なら、奥付の下に `camera.denied` と `camera.openSettings` を出し、ツールバーの `book.edit`（手で直す）を案内する | 名無しの今の本：奥付の書名に「今の本」を出し、`colophon.capture` と `book.edit` で書名と奥付を入れられる（AC-113、AC-140） |
| S-7a | 書名（`book.edit.title`）、著者（`book.edit.author`）、電子書籍の切り替え（`book.edit.isEbook`）と進捗の単位（`book.edit.progressUnit`）、出版社、レーベル、出版年、取り消す、保存（`book.edit.save`） | 著者が空の本は著者の欄が空で始まる。書名を空にして保存を押すと `book.title.invalid` | 保存の間は保存を1回しか受けない | `book.title.invalid`、`book.author.invalid`（欄のすぐ下）、`common.save.error`（Form のいちばん上の行。AC-91）。入れた字は残す | なし（通信を使わない） | なし（許可を使わない） | なし（手入力の画面であり、今の本の値をそのまま欄に出す） |
| S-7b | 晩の日付（読むだけ、`record.night`）、分の欄（`record.minutesField`）、保存（`record.save`）、この記録を消す（`record.delete`） | 空にして保存を押すと `record.minutes.invalid`（AC-25） | S-7a と同じ | `record.minutes.invalid`（欄の下）、`common.save.error`（Form のいちばん上。AC-91）。入れた字は残す | なし（通信を使わない） | なし（許可を使わない） | なし（開いた記録の値をそのまま出す） |
| S-7c | 上部に奥付のカメラプレビューと「写す」ボタン、写したあとは抜き出した書名・著者・出版社・レーベル・出版年・ISBN の確認欄と下端に固定した「保存」（`colophon.save`）（AC-113） | 1文字も読み取れなかったとき：`mark.ocr.none` と「撮り直す」（`colophon.retake`）を出し、欄は手でそのまま打てる | 写してから Vision の結果が返るまで（0.5〜1.5秒）：欄の所に ProgressView を出し、そのまま手入力もできる | 保存の失敗：Form のいちばん上に `common.save.error`、欄の値は残す | なし（端末内の Vision だけで動き、通信を使わない） | カメラ許可が拒否：S-7c の中に `camera.denied` と `camera.openSettings` を出し、確認欄に手で入れて `colophon.save` で保存できる | 奥付から一部の項目（例：出版社と出版年だけ）が読めたとき：読めた項目だけ欄に埋め、残りの欄は空のまま保存するか手で補える（AC-10、AC-113） |
| S-8 | 登録の道の一覧：`register.barcode`（バーコード）、`register.cover`（表紙・背表紙を撮る）、`register.screenshot`（スクリーンショット・写真から選ぶ）、`register.bookshelf`（本棚・積読をまとめて撮る）、`register.manual`（手で入れる・書名で探す）、および条件を満たすときの `register.later`（あとで） | 今の本が1冊あるか、`isTitlePending = true` の本がすでにあるときは `register.later` の行を出さない（AC-139） | なし（固定のメニュー行だけで読み込みはない） | カメラを持たない端末：カメラを使う3つの行（`register.barcode`、`register.cover`、`register.bookshelf`）の下に `register.scanUnavailable` を出し、`register.screenshot` と `register.manual` を使わせる | なし（すべての登録の道が端末内書誌 DB と端末内 OCR で完結し、通信を使わない。AC-6、AC-103） | カメラを断った状態で `register.barcode`、`register.cover`、`register.bookshelf` を押したとき：カメラ画面を開かず S-8 の中に `camera.denied` と `camera.openSettings` を出し、`register.screenshot` と `register.manual` はそのまま押せる（AC-12） | 端末内書誌 DB が未取得（`notDownloaded`）のとき：S-8 の下の補足に DB を準備中である旨を出し、どの道もそのまま使える（AC-9、AC-11） |
| S-8a | 上にカメラ（`scan.camera`）、下に読めた本の一覧（`scan.row.<ISBN>`）、下端に固定した「n冊を本棚に加える」（`scan.addToShelf`）。1冊以上読んだ間は戻るを隠し、閉じる（`role: .cancel`）→ 確認ダイアログだけ（決定 26） | まだ読んでいない：一覧の所に `scan.hint`。`scan.addToShelf` は押せない（0冊）。確認なしで閉じられる | 端末内書誌 DB（H20）は 0.3秒以内に返るため待ち表示は原則出ない（0.3秒を超えたときだけ行に灰の帯を出す。AC-149） | 本棚に加える保存の失敗（AC-91）：一覧の上に知らせ `common.save.error`。読んだ本の一覧は残し、もう一度 `scan.addToShelf` を押せる | なし（機内モードでも端末内書誌 DB から 0.3秒以内に書名・著者・出版社が埋まる。AC-6） | 断っているときは S-8 に残る。読む途中で権限を外されたときは S-8 に戻って `camera.denied` を出す | 端末内書誌 DB が `notDownloaded` のとき：行に `scan.dbNotReady` と `scan.row.captureCover`、`scan.row.editTitle` を出す（AC-9）。DB にない ISBN のとき：行に `scan.notFound` と `scan.row.captureCover`、`scan.row.editTitle` を出し、2段目 Cコードや ISBN 出版社記号から判型と出版社名を補う（AC-10、AC-11）。既登録の本：知らせ `scan.duplicate`（AC-3） |
| S-8b | 上部に表紙・背表紙・スクリーンショットの画像と読み取った行の枠 `cover.ocr.line.1`〜`<n>`、下に1タップ目で入る書名欄（`manual.title`、`cover.selectTitle`）と2タップ目で入る著者欄（`manual.author`、`cover.selectAuthor`）、下端に固定した「保存」（`cover.save`）（AC-137） | 読み取れた行が0個：`ContentUnavailableView` で `mark.ocr.none` と「撮り直す」（`cover.retake`）、「手で入れる」（`register.manual` → S-8c）を出す | 画像を選んでから Vision の結果が返るまで：画像の上に ProgressView を出し、下の欄にはそのまま手で打てる | 書名が空・101字以上：`book.title.invalid`。著者が101字以上：`book.author.invalid`。保存の失敗：欄の上に `common.save.error` | なし（端末内の Vision だけで動き、通信を使わない） | `register.screenshot`（`PhotosPicker`）は許可不要。カメラ撮影で権限が外れたときは S-8 に戻って `camera.denied` を出す | 表紙の帯や装飾文字で1行だけしか読めなかったとき：1タップ目で書名に入れ、著者は下の `manual.author` に手で打つか空のまま `cover.save` で保存できる |
| S-8c | 書名の欄（`manual.title`、3字以上で端末内書誌 DB の候補 `search.row.<ISBN>` が最大20件下に並び、押すと各欄に自動入力）、著者の欄（`manual.author`）、電子書籍の切り替え（`manual.isEbook`）と単位（`mark.progressUnit`）、保存（`manual.save`）（AC-4、AC-5、AC-7） | 入れる前：候補一覧は出さない。3字以上入れて DB に合う本が0件のとき：候補の位置に `search.noResults` を1行出し、そのまま `manual.save` で保存できる（AC-5） | 端末内書誌 DB は 0.3秒以内に返る（AC-149）。保存の間は `manual.save` の2度押しを受けない | `book.title.invalid`、`book.author.invalid`（欄のすぐ下。AC-8）、`common.save.error`（Form のいちばん上。AC-91）。入れた字は残す | なし（機内モードでも端末内書誌 DB の候補補完と手入力保存がそのまま動く。AC-6） | なし（許可を使わない） | 端末内書誌 DB が `notDownloaded` のとき：候補の位置に DB のダウンロード状態と再試行ボタン（`catalog.retry`）を出し、手入力での保存はそのまま動く（AC-11）。DB の候補にレーベルやページ数がないときは、ある項目だけ欄に埋める（AC-4、AC-10） |
| S-8d | 上部に本棚・積読の写真と背表紙の枠、下に押して選んだ候補の一覧 `bookshelf.row.<n>`（各行に書名欄と、DB で1件一致したときの著者・出版社）、下端に固定した「選んだn冊を積読に加える」（`bookshelf.addSelected`）（AC-138） | まだ背表紙の枠を1つも選んでいない：一覧の位置に案内 `bookshelf.hint` を出し、`bookshelf.addSelected` は押せない（0冊）。読み取れた文字が0個のときは `mark.ocr.none` と「撮り直す」「手で入れる」を出す | 写してから Vision の結果が返るまで：写真の上に ProgressView を出す | 保存の失敗：一覧の上に `common.save.error`、選んだ行は残す | なし（端末内の Vision と端末内書誌 DB だけで動き、通信を使わない） | カメラ権限が外れたときは S-8 に戻って `camera.denied` を出す | 端末内書誌 DB（H20）で完全一致が1件の本（「羅生門」）は著者・出版社・ISBN を自動で埋め、複数件ある本（「こころ」）や0件の本は書名だけで加える（AC-138） |
| S-9 | 見出し「読み終えました」、ふりかえりの1行（`finish.reflection`）、奥付（`finish.colophon`）と奥付撮影（`colophon.capture`）、カードの共有（`finish.card.share`）、次の1冊（最大3冊：`next.candidate.<id>`、理由 `next.reason`、積読は `next.choose`、未所有は `next.addToShelf`、見送りは `next.skip`）、戻し方の1行（`finish.undoNote`） | 積読も未所有の候補も0件：`next.candidate` は0個で、`ContentUnavailableView`（`next.empty.title`、`next.empty.message`、`next.addBook`）を出す（AC-81）。記録が0件の本：`finish.reflection` の行を出さない（AC-129） | 0.3秒を超えたら候補の行の形の灰の帯 | 今の本にする・積読に加えるの保存失敗：画面の上に知らせ `common.save.error`、S-9 のまま残る | なし（候補はすべて積読・端末内書誌 DB・同梱受賞一覧・同梱共起テーブルから出し、通信を使わない） | `colophon.capture` を押したときにカメラ許可が拒否なら `camera.denied` と `camera.openSettings` を出す | 奥付はデータのある行だけ出す（AC-77）。記録が1晩だけのときは `finish.reflection.single`、2晩以上のときは `finish.reflection.multi` を出す（AC-127、AC-128） |
| S-10 | 読み始め（`settings.flipToStart`、`settings.entryTime`）、ロック画面（`settings.hideOnWidgets`）、見た目と購入（`settings.appearance`、`settings.restorePurchases`）、書誌データ（状態と `catalog.retry`）、情報（`settings.privacyPolicy`、`settings.dataSources`、`settings.dataSources.license`） | なし（いつも決まった設定項目が並ぶ） | 購入の復元中は `settings.restorePurchases` の横に ProgressView を出す | 設定の保存失敗：切り替えを前の値に戻し、節の下に `common.save.error`。復元の結果：画面上部に知らせ `store.restore.done` または `store.restore.none`（AC-108） | リンクは Safari が扱い、購入の復元で通信がないときは知らせ `store.offline` を出す | OS の設定で Live Activity がオフのとき：読み始めの節に `settings.liveActivity.off` を出す（AC-37） | 伏せる道を使えない端末（H18）：`settings.flipToStart` を押せなくし、下に `settings.flipToStart.unavailable` を出す（AC-51）。端末内書誌 DB が `notDownloaded` のとき：書誌データの節に未取得の旨と再試行ボタン `catalog.retry` を出す（AC-11） |
| S-10a | 見た目の一覧（無料：標準 `default`、よむま＋：生成り `kinari`・墨 `sumi`・朱 `shu`）。未購入で鍵つきの行を押すと、見本 `store.preview`（`accessibilityValue` は見た目の id）と買い切りの購入シート（品名、中身、値段、`store.buy`、`store.restore`、`store.close`）が出る（AC-105、AC-106） | なし（4つの見た目の選択肢が常に並ぶ） | 商品情報の取得中または購入処理中はボタンの位置に ProgressView を出す | 購入失敗：シートの中に `store.purchase.error` が1つ出て、見た目は `default` のまま（AC-107）。購入キャンセル（`userCancelled`）：エラーを出さずシートに残る（AC-107） | 通信がなく商品情報を読めないとき：アラートは出さずシートの中に `store.offline` を出し、`store.buy` は出さない（AC-110） | 支払いが許可されていない端末（`canMakePayments == false`）：`store.buy` は出さず、シートの中に `store.unavailable` を出す（AC-109） | 返金されたとき：前に戻ったときに購入状態が未購入に戻り、設定とウィジェットの見た目が `default` に戻る（AC-111） |
| 部品 N | 記号（エラーは `exclamationmark.circle`、ほかは `info.circle`）、文、閉じるボタン（`notice.close`） | なし（知らせがあるときにだけ出る部品のため） | なし（確定した文を即座に出す部品のため） | エラーの知らせは記号だけ赤（`color.state.error`）、文字は本文の色（`color.text.primary`） | なし（部品自体の通信はない） | なし（部品自体の許可はない） | なし（文の全文を折り返して出す） |

### 長い文字、0件、とても多いとき、取り消せない操作
- **長い文字**：
  - 長い書名（100字まで）：S-1 と S-6 は2行まで出して末尾を「…」（読み上げは全文）。S-7 と S-9 の奥付、S-7a、S-8c は全文を折り返して出す。accessibility1 以上の文字サイズではすべての画面で行数の上限を外す。
  - 長い一行（60字まで）：S-1 は全文（縦書きで幅に入らなければ横書きに切り替え）。W-1 と W-2 は AC-29 の縮め方で25字まで。
  - 長い著者（100字まで）：S-1 は1行で末尾「…」、奥付と入力欄は全文。
- **0件**：本0冊（S-1、S-6）、記録0件（S-7、S-9 のふりかえり非表示）、次の1冊の候補0件（S-9）、書名候補0件（S-8c の `search.noResults`）、OCR 0文字（S-3c・S-7c・S-8b・S-8d の `mark.ocr.none`）はすべて上の表のとおり。「0冊」「0件」という数字を見出しにしない。
- **とても多いとき**：本500冊、1冊に記録1,000件でも、S-6 と S-7 は `List` の遅延描画で 1.0秒以内（AC-101）。S-8a で読んだ本が多いときは、一覧の最後の行（いま読んだ本）が見える所まで自動スクロールする。S-8c の端末内書誌 DB 候補は FTS5 trigram で上位20件までに絞って 0.3秒以内に出す（AC-4、AC-149）。
- **取り消せない操作の確認（`confirmationDialog`）**：
  1. 本を消す（`book.delete`：一緒に消える記録の件数を `book.delete.confirm` に入れる。AC-16）
  2. 記録を消す（`record.delete`：AC-26）
  3. 読んだ本が1冊以上あるのに S-8a を加えずに閉じる（`scan.discard.confirm`：決定 26）
  4. 名無しの今の本（`isTitlePending = true`）があるときに、別の本を今の本にしようとするか積読へ移そうとするとき（`book.pendingTitleGuard`：先にその本の書名を入れるか確認する。決定 71）
  - 押し間違いを本棚から戻せる「読み終えた」（`bookmark.finish`）と、記録を直せる「終える」（`reading.end`）には確認を挟まない（決定 15）。

---

## 6. 要素と識別子

PRD の識別子はすべてそのまま使う。PRD にない補助の要素には「（足した）」と書く。
- **一覧の行の識別子の末尾（`<id>` / `<ISBN>`）の決まり（PRD 11 の冒頭、および verifier 提案3への回答）**：
  - 本棚の行 `shelf.row.<本の id>` と、S-1 の積読候補 `bookmark.noCurrent.next.<id>`：`<id>` は SwiftData の本の UUID（大文字の文字列、例 `00000000-0000-4000-8000-000000000001`）。
  - S-9 の次の1冊 `next.candidate.<id>`：本棚（`tsundoku`）にある本は `<本の id>`（UUID 大文字）。端末内書誌 DB（H20）または共起テーブルから出た未所有の本は `<ISBN>`（13桁数字、例 `9784041026000`）。同梱の受賞一覧（H25）から出た未所有の本で H20 に ISBN がないときは、受賞一覧の決定論的な行 ID `<awardID>`（`<賞の識別子>-<回または年>`、例 `naoki-157`、`akutagawa-155`、`honya-2017`）を付ける。
  - S-7 の「この本のあとに」の候補 `after.candidate.<ISBN>`（または `<awardID>`）：H20 由来の未所有の本は `after.candidate.<ISBN>`（例 `after.candidate.9784041026000`）、H25 由来で ISBN がない未所有の本は `after.candidate.<awardID>`（例 `after.candidate.naoki-157`）とする。XCUITest で前方一致（`identifier BEGINSWITH "after.candidate."` または `next.candidate.`）で引くときも、個別 ID で引くときも一意に決まる。
  - 行の中のボタンやラベル（`next.reason`、`next.choose`、`next.addToShelf`、`after.reason`、`after.addToShelf`、`after.added`、`bookmark.noCurrent.choose`、`scan.row.captureCover`、`scan.row.editTitle`）は、その行（`next.candidate.<id>` など）の子要素として探せるようにする。
  - 文を出す要素（知らせ、入力誤り、空の文）の `accessibilityIdentifier` は、文言キーと同じ名前にする。

| 画面 | 要素 | accessibilityIdentifier | VoiceOver のラベル |
|---|---|---|---|
| W-1、W-2 | ウィジェット全体（読み上げは1つのまとまり） | `widget.rectangular`、`widget.small`（足した。H22 で読む名前） | 「羅生門、61ページ。下人は、雨やみを待っていた。」（書名、場所、一行。縦書き用の字形は使わない。AC-99）。電子書籍の位置・％のときは「羅生門、位置1450。…」「羅生門、52パーセント。…」。場所なし「羅生門。下人は、雨やみを待っていた。」。一行なし「檸檬、120ページ」（`widget.spoken.noLine`）、場所もなし「檸檬」。隠す設定のとき「しおり、61ページ」。名無しの今の本（`isTitlePending = true`）は書名の所を `widget.currentBookAsTitle`「今の本」にして同じ書式で読む（「今の本、61ページ。…」）。今の本なし：`widget.empty` の文。写しを読めない：`widget.unavailable` の文 |
| W-1、W-2 | 一行、場所、書名（読み上げからは隠し、全体のラベルに入れる） | `widget.line`、`widget.page`、`widget.title`（足した。H22 で読む名前） | （全体のラベルに入る） |
| W-3 | 夜の入口・読書中の Live Activity 全体 | `liveActivity.banner`（足した。H23 で読む名前） | 待つ状態：「羅生門、61ページ。下人は、雨やみを待っていた。」（隠す設定なら「しおり、61ページ」）。読書中：「羅生門、22時0分から読書中」（隠す設定なら「しおり、22時0分から読書中」）。終えた直後：「羅生門、10分、61ページ」 |
| W-3 | Live Activity の「終える」ボタン（読書中に1つだけ出る） | `liveActivity.end` | 文言キー `liveActivity.end.label` の文（「読書を終える」／「End Reading」。AC-114） |
| W-4 | ロック画面・コントロールセンターの「読み始める」ボタン | `control.startReading` | 文言キー `control.startReading` の文（「読み始める」／「Start Reading」。AC-126） |
| W-5 | Siri・ショートカットの小窓（`ShowsSnippetView`）の文 | `intent.snippet`（足した。H32 で読む名前） | 声の返答と同じ文（`intent.whereStopped.page`、`intent.whereStopped.location`、`intent.whereStopped.percent`、`intent.whereStopped.noPage`、`intent.whereStopped.noCurrent`、`intent.whereStopped.error`） |
| S-1 | ツールバー左の本棚ボタン | `toolbar.shelf` | 「本棚」 |
| S-1 | ツールバー右の設定ボタン | `toolbar.settings` | 「設定」 |
| S-1 | 今の本の書名（名無しの今の本のときは `widget.currentBookAsTitle`「今の本」） | `bookmark.title` | 書名（見出しトレイト `.isHeader`） |
| S-1 | 今の本の著者 | `bookmark.author`（足した） | 著者 |
| S-1 | 続きの一行 | `bookmark.line` | 保存した一行そのもの（AC-99） |
| S-1 | 場所（ページ「p.61」、位置「位置1450」、％「52%」） | `bookmark.page` | 「61ページ」「位置1450」「52パーセント」（AC-99、AC-141） |
| S-1 | どこまで読んだかを入れるボタン | `bookmark.setMark` | 「どこまで読んだかを入れる」 |
| S-1 | 読み終えたボタン | `bookmark.finish` | 「読み終えた」。ヒント「奥付と次の1冊を出します。」 |
| S-1 | 名無しの今の本に書名を入れるボタン（`isTitlePending = true` のときだけ出る） | `bookmark.setBookTitle` | 「書名を入れる」（AC-139、AC-140） |
| S-1 | 読み始めるボタン（主操作） | `bookmark.start` | 「読み始める」 |
| S-1 | 伏せる案内の1行（紙の本） | `bookmark.flipHint` | 文言キー `bookmark.flipHint` の文（AC-50） |
| S-1 | 伏せる・電子書籍案内の1行（`isEbook = true` のとき） | `bookmark.flipHint.ebook` | 文言キー `bookmark.flipHint.ebook` の文（AC-144） |
| S-1 | 本0冊の空状態の文 | `bookmark.empty.message` | 文言キー `bookmark.empty.message` の文（AC-1） |
| S-1 | 本0冊のときの「本を加える」ボタン | `bookmark.addBook` | 「本を加える」（AC-1） |
| S-1 | 今の本なしの文（および名無しの本があるときの案内） | `bookmark.noCurrent.message`（別名 `bookmark.unnamedNotice`）、第2ボタン `bookmark.addBook` | 文言キー `bookmark.noCurrent.message` の文（AC-16、AC-139、AC-145） |
| S-1 | 今の本なし・積読ありのときの候補の行（最大3冊） | `bookmark.noCurrent.next.<id>`（前方一致 `bookmark.noCurrent.next`） | 「（書名）、（著者）、（理由）」（AC-145） |
| S-1 | 今の本なしの候補の行の中の「この本を読む」ボタン | `bookmark.noCurrent.choose` | 「この本を読む、（書名）」（AC-145） |
| S-1 | 本棚から選ぶボタン | `bookmark.openShelf`（足した） | 「本棚から選ぶ」 |
| S-1 | しおりがまだないときの案内文 | `bookmark.noMark.message`（足した） | 文のとおり |
| S-1 | 保存先を読めないときの文と再試行ボタン | `store.load.error`、`store.retry`（`store.retry` は足した） | 文のとおり、「もう一度読み込む」（AC-90） |
| 部品 N | 知らせの帯と文 | `notice`（足した）。文の要素は文言キーと同じ識別子（`session.tooShort`、`session.invalidTime`、`session.start.error`、`session.save.error`、`session.capped`、`common.save.error`、`scan.duplicate`、`store.restore.done`、`store.restore.none`） | 文のとおり（出たときに1回読み上げを送る） |
| 部品 N | 知らせを閉じるボタン | `notice.close`（足した） | 「閉じる」。ヒント「知らせを閉じます。」 |
| S-2 | 読書中の本の書名 | `reading.title`（足した） | 書名（名無しの本なら「今の本」） |
| S-2 | 始めた時刻の文 | `reading.startedAt`（足した） | 「21時4分から数えています。」 |
| S-2 | 数え続けることの1行（紙の本） | `reading.note`（足した） | 文のとおり |
| S-2 | 電子書籍でアプリを閉じてよい旨の1行（`isEbook = true`） | `reading.ebookNote` | 文言キー `reading.ebookNote` の文（AC-144） |
| S-2 | 終えるボタン（画面内の唯一の押せる要素） | `reading.end` | 「終える」（AC-43） |
| S-3 | 問いの見出し | `mark.question`（足した） | 「どこまで読みましたか。」（見出しトレイト） |
| S-3 | ページを撮るボタン | `mark.photo` | 「ページを撮る」（AC-63、AC-65） |
| S-3 | スクリーンショットから選ぶボタン（`PhotosPicker`） | `mark.screenshot` | 「スクリーンショットから選ぶ」（AC-63、AC-142） |
| S-3 | 一行を入れるボタン | `mark.manual` | 「一行を入れる」（AC-63、AC-71） |
| S-3 | ページ（位置・％）だけ入れるボタン | `mark.pageOnly` | 「ページだけ入れる」（電子書籍で単位が位置なら「位置番号だけ入れる」、％なら「％だけ入れる」）（AC-63、AC-73） |
| S-3 | あとで挟むボタン | `mark.later` | 「あとで挟む」。ヒント「しおりは前のまま残ります。」（AC-63、AC-75） |
| S-3 | 閉じるボタン（S-1 の `bookmark.setMark` からシートで開いたときだけ） | `mark.cancel`（足した） | 「閉じる」 |
| S-3、S-8、S-7c | カメラの許可がないときの文と設定を開くボタン | `camera.denied`、`camera.openSettings` | 文のとおり、「設定を開く」（AC-12、AC-70） |
| S-3a、S-3c | 一行の入力欄 | `mark.lineField` | 「一行」（AC-65、AC-71） |
| S-3a、S-3b、S-3c | 電子書籍の進捗単位ピッカー（`page` / `location` / `percent`） | `mark.progressUnit` | 「進み具合の単位」（セグメント：ページ、位置、％）（AC-141） |
| S-3a、S-3b、S-3c | ページ・位置番号・％の入力欄 | `mark.pageField` | 単位に合わせて「ページ」「位置番号」「パーセント」（AC-65、AC-71、AC-73、AC-141） |
| S-3a、S-3b、S-3c | 前の場所の消えない説明（前の値があるときだけ） | `mark.page.previous`（足した） | 文のとおり（「前のページは43です。…」） |
| S-3a、S-3b、S-3c | 保存ボタン | `mark.save` | 「保存」（AC-65、AC-71、AC-73） |
| S-3a、S-3b、S-3c | 一行・場所の入力誤りの文 | `mark.line.invalid`、`mark.page.invalid`（位置の範囲外 1〜999999 外の別名 `mark.progress.outOfRange.location`） | 文のとおり（出たときに1回読み上げ）（AC-72、AC-74、AC-141） |
| S-3c | 読み取った列（または行）の枠ボタン（右から1始まり） | `mark.ocr.column.<n>`（例：`mark.ocr.column.1`〜`mark.ocr.column.6`、前方一致 `mark.ocr.column`） | 「列 <n>、（読み取った文字列）」。選ばれている枠には `.isSelected` トレイトを付ける（AC-65、AC-66、AC-142） |
| S-3c、S-7c、S-8b、S-8d | 文字が1つも読み取れなかったときの文 | `mark.ocr.none` | 文言キー `mark.ocr.none` の文（AC-68） |
| S-3c | 撮り直す（スクショのときは選び直す）ボタン | `mark.retake` | 「撮り直す」（スクショのときは「選び直す」）（AC-68） |
| S-4 | 本の書名 | `result.title`（足した） | 書名 |
| S-4 | 読書のまとめ（場所の進みと分数） | `result.summary` | 「43ページから61ページ、18分」「位置1200から位置1450、18分」「34パーセントから52パーセント、18分」。前の場所なし「61ページ、18分」。あとで挟む「18分」（AC-75、AC-76、AC-141） |
| S-4 | 記録しましたの文と閉じるボタン | `result.saved`、`result.close`（足した） | 文のとおり、「閉じる」 |
| S-5 | 置き方の案内のシート全体、見本、閉じるボタン | `widgetGuide`、`widgetGuide.preview`（足した）、`widgetGuide.close`（足した） | 見出し「ロック画面に置く」、「ロック画面での見え方。」＋W-1 のラベル、「閉じる」（AC-96） |
| S-6 | 本棚の3つの区分 | `shelf.current`、`shelf.tsundoku`、`shelf.finished` | 「今の本」「積読」「読み終えた」（AC-13） |
| S-6 | 本の行 | `shelf.row.<本の id>`（足した） | 「（書名）、（著者）」 |
| S-6 | ツールバーの「＋」本を加えるボタン、空状態の「本を加える」ボタン | `shelf.addBook`、`shelf.empty.addBook`（足した） | 「本を加える」 |
| S-6 | 読み込めないときの文と再試行ボタン | `shelf.load.error`、`shelf.retry`（足した） | 文のとおり、「もう一度読み込む」 |
| S-7、S-9 | 奥付のまとまり | `book.colophon`（S-7）、`finish.colophon`（S-9） | 「奥付」（AC-17、AC-77） |
| S-7、S-9 | 奥付の各行 | `colophon.title`、`colophon.author`、`colophon.publisher`、`colophon.year`、`colophon.award` | 行ごとに「書名、蜜蜂と遠雷」「著者、恩田陸」「出版社、新潮社、新潮文庫」「出版年、2016年」「受賞、第156回 直木三十五賞、2017年 本屋大賞」（AC-17〜AC-21、AC-77） |
| S-7、S-9 | 奥付を撮って補うボタン | `colophon.capture`（S-7 では別名 `book.captureColophon` も同じ要素またはエイリアスとして対応） | 「奥付を撮って補う」（AC-77、AC-113） |
| S-7c | 奥付の確認欄の保存ボタンと撮り直すボタン | `colophon.save`、`colophon.retake`（`retake` は足した） | 「保存」「撮り直す」（AC-113） |
| S-7 | 何晩・合計時間 | `book.nights`、`book.total`（足した） | 「4晩」「合計1時間25分」（AC-22） |
| S-7 | 記録の行 | `book.record.row.<記録の id>`（前方一致 `book.record.row`） | 「10月17日の晩、10分」。見える文字「10/17」を `accessibilityInputLabels` に入れる（AC-22、決定 60） |
| S-7 | 記録が0件のときの文 | `book.records.empty` | 文言キー `book.records.empty` の文（AC-23） |
| S-7 | 読み終えた本の「この本のあとに」の見出し | `after.header` | 「この本のあとに」（見出しトレイト。AC-146） |
| S-7 | 「この本のあとに」の候補の行（最大5冊） | `after.candidate.<ISBN>`（H25 由来で ISBN がないときは `after.candidate.<awardID>`、前方一致 `after.candidate`） | 「（書名）、（著者）、（理由）」（AC-146） |
| S-7 | 「この本のあとに」の行の中の理由の1行 | `after.reason` | 理由の文（AC-146） |
| S-7 | 「この本のあとに」の行の中の「積読に加える」ボタンと、加えたあとの表示 | `after.addToShelf`、`after.added` | 「積読に加える、（書名）」、「積読に加えました」（AC-146） |
| S-7 | この本を読むボタン（主操作） | `book.readThis` | 「この本を読む」（AC-14） |
| S-7 | 今読んでいる本ですの表示（`current` の本のとき） | `book.isCurrent`（足した） | 文のとおり |
| S-7 | ツールバーの「直す」ボタン | `book.edit` | 「直す」（AC-15） |
| S-7 | この本を消すボタンと、確認ダイアログの文・消すボタン | `book.delete`、`book.delete.confirm`、`book.delete.confirmButton`（`confirmButton` は足した） | 「この本を消す」、確認文、「消す」（AC-16） |
| S-7、S-1 | 名無しの今の本（`isTitlePending = true`）があるときに別の本を `current` にするときの確認ダイアログ（verifier 提案2） | `book.pendingTitleGuard`、`book.pendingTitleGuard.setTitle`、`book.pendingTitleGuard.continueAnyway`、`book.pendingTitleGuard.cancel`（足した） | 確認文、「今の本の書名を入れる」「そのまま切り替える」「取り消す」 |
| S-7a | 書名欄、著者欄、電子書籍トグル、進捗単位ピッカー、保存、取り消す | `book.edit.title`、`book.edit.author`、`book.edit.isEbook`、`book.edit.progressUnit`、`book.edit.save`、`book.edit.cancel`（足した） | 「書名」「著者」「電子書籍」「進み具合の単位」「保存」「取り消す」（AC-15） |
| S-7b | 晩の日付、分の欄、保存、取り消す、この記録を消す、確認の消すボタン、誤りの文 | `record.night`、`record.minutesField`、`record.save`、`record.cancel`、`record.delete`、`record.delete.confirmButton`（以上足した）、`record.minutes.invalid`（PRD） | 「10月16日の晩」「分」「保存」「取り消す」「この記録を消す」「消す」、誤りの文（AC-24〜AC-26） |
| S-8 | バーコードを続けて読む行 | `register.barcode` | 「バーコードを続けて読む」（AC-2、AC-3） |
| S-8 | 表紙・背表紙を撮る行 | `register.cover` | 「表紙・背表紙を撮る」（AC-12、AC-137） |
| S-8 | スクリーンショット・写真から選ぶ行（`PhotosPicker`） | `register.screenshot`（写真全般を選ぶ補助ボタン `register.photo` も同じ `PhotosPicker` 導線として対応） | 「スクリーンショットから選ぶ」（AC-12、AC-137） |
| S-8 | 本棚・積読をまとめて撮る行 | `register.bookshelf` | 「本棚・積読をまとめて撮る」（AC-138） |
| S-8、S-3c、S-8b、S-8d | 手で入れる・書名で探す行 | `register.manual` | 「手で入れる」（S-8 では「手で入れる・書名で探す」）（AC-4、AC-7） |
| S-8 | あとで（すぐ読み始める）行（今の本0冊かつ名無しの本0冊のときだけ） | `register.later` | 「あとで（すぐ読み始める）」（AC-139） |
| S-8 | 閉じるボタン、カメラ制限・非対応の文 | `register.cancel`、`camera.restricted`、`register.scanUnavailable`（足した） | 「閉じる」、文のとおり |
| S-8a | カメラ読み取り領域 | `scan.camera`（足した） | 「カメラ。本の裏のバーコードを写してください。」 |
| S-8a | 読み取った本の行 | `scan.row.<ISBN>`（例：`scan.row.9784101000015`、前方一致 `scan.row`） | 「（書名）、（著者）、（出版社）、（レーベル）」（AC-2、AC-3） |
| S-8a | 書誌 DB 未取得時の行内メッセージ、DB 未収録時の行内メッセージ | `scan.dbNotReady`、`scan.notFound` | 文言キー `scan.dbNotReady`、`scan.notFound` の文（AC-9、AC-10） |
| S-8a | DB 未取得・未収録の行内の「表紙を撮る」ボタンと「書名を入れる」欄 | `scan.row.captureCover`、`scan.row.editTitle` | 「表紙・背表紙を撮る」「書名」（AC-9、AC-10、AC-11） |
| S-8a | 既登録の本の知らせ | `scan.duplicate` | 文言キー `scan.duplicate` の文（AC-3） |
| S-8a | n冊を本棚に加えるボタン（主操作）、閉じる、破棄確認ボタン | `scan.addToShelf`、`scan.cancel`（足した）、`scan.discard.confirmButton`（足した） | 「2冊を本棚に加える」「閉じる」「加えずに閉じる」（AC-2、AC-3） |
| S-8b | 表紙・背表紙・スクショの読み取り行の枠（1始まり） | `cover.ocr.line.<n>`（例：`cover.ocr.line.1`、`cover.ocr.line.2`、`cover.ocr.line.3`） | 「行 <n>、（読み取った文字列）」（AC-137） |
| S-8b | 書名として選ばれた枠・欄の印、著者として選ばれた枠・欄の印 | `cover.selectTitle`、`cover.selectAuthor` | 「書名に選択」「著者に選択」（AC-137） |
| S-8b | 表紙・背表紙・スクショから保存するボタン | `cover.save` | 「保存」（AC-137） |
| S-8c | 書名の入力欄（インクリメンタル検索欄）、著者の入力欄、電子書籍トグル、進捗単位ピッカー、保存ボタン、取り消すボタン | `manual.title`（別名 `manual.searchField`）、`manual.author`、`manual.isEbook`、`mark.progressUnit`、`manual.save`、`manual.cancel`（`cancel` は足した） | 「書名」「著者」「電子書籍」「進み具合の単位」「保存」「取り消す」（AC-4、AC-5、AC-7、AC-8、AC-141） |
| S-8c | `manual.title` に3字以上入れたときに出る端末内書誌 DB の候補の行（最大20件） | `search.row.<ISBN>`（例：`search.row.9784040000053`、前方一致 `search.row`、別名 `manual.candidate.<ISBN>`） | 「（書名）、（著者）、（出版社）、（レーベル）、（出版年）」（選んだ行には `.isSelected` トレイトを付ける。AC-4） |
| S-8c | 端末内書誌 DB に合う候補が0件のときの文 | `search.noResults` | 文言キー `search.noResults` の文（AC-5） |
| S-8c、S-7a、S-8b | 書名・著者の入力誤りの文 | `book.title.invalid`、`book.author.invalid` | 文言キーのとおり（AC-8） |
| S-8d | 本棚の写真から選んだ背表紙の候補行（1始まり） | `bookshelf.row.<n>`（例：`bookshelf.row.1`〜`bookshelf.row.3`） | 「候補 <n>、（書名）、（著者・出版社）」（AC-138） |
| S-8d | 選んだn冊を積読に加えるボタン（主操作） | `bookshelf.addSelected` | 「選んだ3冊を積読に加える」（AC-138） |
| S-9 | 読み終えましたの見出し | `finish.title`（足した） | 「読み終えました」（見出しトレイト） |
| S-9 | ふりかえりの1行（記録1件以上のときだけ出る） | `finish.reflection` | 文言キー `finish.reflection.multi` または `finish.reflection.single` の文（AC-127〜AC-129） |
| S-9 | 読み終えのカードを共有するボタン | `finish.card.share` | 「読み終えのカードを共有」（AC-84、AC-85） |
| S-9 | 次の1冊の候補の行（最大3冊） | `next.candidate.<id>`（前方一致 `next.candidate`） | 「（書名）、（著者）。（理由）」（AC-78〜AC-83、AC-87、AC-147、AC-148） |
| S-9 | 候補の行の中の理由の1行 | `next.reason` | 理由の文（AC-79、AC-148） |
| S-9 | 積読の候補の「この本を読む」ボタン | `next.choose` | 「この本を読む、（書名）」（AC-82） |
| S-9 | 未所有の候補の「積読に加える」ボタンと、加えたあとの表示 | `next.addToShelf`、`next.added`（`added` は足した） | 「積読に加える、（書名）」、「積読に加えました」（AC-83、AC-87） |
| S-9 | 今は次の本を選ばずに閉じる「今は読まない」ボタン | `next.skip` | 「今は読まない」（AC-147） |
| S-9 | 候補が0件のときの文と「本を加える」ボタン | `next.empty.message`、`next.addBook` | 文言キー `next.empty.message` の文、「本を加える」（AC-81） |
| S-9 | 戻し方の1行と閉じるボタン | `finish.undoNote`、`finish.close`（足した） | 文のとおり、「閉じる」 |
| S-10 | 伏せて始めるトグルと、使えない端末の説明文 | `settings.flipToStart`、`settings.flipToStart.unavailable`（`unavailable` は足した） | 「伏せて始める」とオン・オフ、文のとおり（AC-51） |
| S-10 | 夜の入口の時刻ピッカー（15分刻み）と、Live Activity がオフのときの文 | `settings.entryTime`、`settings.liveActivity.off` | 「夜の入口の時刻、（時刻）」、文言キー `settings.liveActivity.off` の文（AC-37、AC-38） |
| S-10 | 一行と書名を隠すトグル | `settings.hideOnWidgets` | 「一行と書名を隠す」とオン・オフ（AC-34） |
| S-10 | 見た目の選択画面を開く行 | `settings.appearance` | 「見た目、（現在の見た目名）」（AC-105） |
| S-10 | 購入を復元するボタン | `settings.restorePurchases` | 「購入を復元する」（AC-108） |
| S-10、S-8c | 端末内書誌 DB の状態と再試行ボタン | `catalog.status`（別名 `settings.h20Status`）、`catalog.retry`（別名 `settings.h20Retry`。足した。H20/H28 連携） | 状態の文、「書誌データを今すぐ取得する」（AC-11、AC-92） |
| S-10 | プライバシーポリシーへのリンク | `settings.privacyPolicy` | 「プライバシーポリシー、Safari で開きます」（AC-88） |
| S-10 | 書誌の出どころの文と、CC BY 4.0 ライセンスへのリンク | `settings.dataSources`、`settings.dataSources.license` | 見出しと文言キー `settings.dataSources` の全文、「ライセンス、CC BY 4.0、Safari で開きます」（AC-93） |
| S-10a | 見た目の選択肢の行（`default`、`kinari`、`sumi`、`shu`） | `appearance.row.default`、`appearance.row.kinari`、`appearance.row.sumi`、`appearance.row.shu`（足した） | 「標準（白と黒）、選択中」「生成り、よむま＋（未購入なら『鍵つき』）」など（AC-105、AC-106） |
| S-10a | 購入シートの見た目の見本 | `store.preview` | ラベル「見た目の見本」、`accessibilityValue` に選んだ見た目の id（`kinari`、`sumi`、`shu`）（AC-105） |
| S-10a | 購入シートの「よむま＋を買う」「購入を復元する」「閉じる」ボタン | `store.buy`、`store.restore`、`store.close` | 「よむま＋を買う」「購入を復元する」「閉じる」（AC-105、AC-106） |
| S-10a、S-10 | 購入・復元のエラーと状態の文 | `store.purchase.error`、`store.restore.done`、`store.restore.none`、`store.unavailable`、`store.offline` | 各文言キーの文（AC-107〜AC-110） |

---

## 7. 文言

### 7-1 文言キーの一覧（日本語・英語）
- **調子**：です・ます調で淡々と書く。感嘆符（`！`）、絵文字、冗談を使わない。ほめない、祝わない。ボタンは動詞（英語は動詞で始める）。エラーは何が起きたかとどう直すかを書き、利用者を責めない（R-21、R-26、R-31）。
- **組み立て方**：文字列を `+` でつなげず、書名・ISBN・数・時刻はすべて書式の引数（`%@`、`%lld`）で入れる。英語の数は String Catalog の複数形（`one` / `other`）を使う。ページ数、位置番号、出版年には桁区切りのカンマを入れない。

| キー | 日本語 | 英語 | 使う場所 |
|---|---|---|---|
| `bookmark.navTitle` | しおり | Bookmark | S-1 のナビゲーションタイトル。足した |
| `toolbar.shelf` | 本棚 | Bookshelf | S-1 のツールバー左（記号 `books.vertical`）。PRD |
| `toolbar.settings` | 設定 | Settings | S-1 のツールバー右（記号 `gearshape`）。PRD |
| `bookmark.start` | 読み始める | Start Reading | S-1 の主操作。PRD |
| `bookmark.setMark` | どこまで読んだかを入れる | Mark Your Place | S-1。PRD |
| `bookmark.finish` | 読み終えた | Mark as Finished | S-1。PRD |
| `bookmark.finish.hint` | 奥付と次の1冊を出します。 | Shows the colophon and your next book. | S-1 の `bookmark.finish` の VoiceOver ヒント。足した |
| `bookmark.setBookTitle` | 書名を入れる | Add Book Title | S-1（名無しの今の本 `isTitlePending = true` のとき）。PRD（AC-139、AC-140） |
| `bookmark.flipHint` | この画面で iPhone を伏せて置いても、読み始めます。 | You can also start by placing iPhone face down on this screen. | S-1（紙の本、伏せる道オン）。PRD（AC-50） |
| `bookmark.flipHint.ebook` | 別の端末で読むなら伏せて置いても、この iPhone で読むなら「読み始める」を押して他のアプリに移っても数えられます。 | Place iPhone face down if reading on another device, or tap Start Reading and switch apps on this iPhone. | S-1（電子書籍 `isEbook = true`）。PRD（AC-144） |
| `bookmark.empty.title` | まだ本がありません | No Books Yet | S-1（本0冊の見出し）。足した |
| `bookmark.empty.message` | 読んでいる本を1冊加えると、ここに続きの一行が出ます。 | Add a book you're reading, and the line where you stopped will appear here. | S-1（本0冊の文）。PRD（AC-1） |
| `bookmark.addBook` | 本を加える | Add a Book | S-1（本0冊のボタン）。PRD（AC-1） |
| `bookmark.noCurrent.title` | 今の本がありません | No Current Book | S-1（今の本なしの見出し）。足した |
| `bookmark.noCurrent.message` | 次に読む1冊を選んでください。 | Choose the next book to read. | S-1（今の本なしの文）。PRD（AC-16、AC-145） |
| `bookmark.noCurrent.choose` | この本を読む | Read This Book | S-1 の積読候補 `bookmark.noCurrent.next.<id>` のボタン。PRD（AC-145） |
| `bookmark.openShelf` | 本棚から選ぶ | Choose from Bookshelf | S-1（今の本なしの補助ボタン）。足した |
| `bookmark.noMark.message` | どこまで読んだかを入れると、ここに続きの一行が出ます。 | Mark your place, and the line will appear here. | S-1（一行も場所もないとき）。足した |
| `page.short` | p.%lld | p.%lld | S-1、S-4、W-1、W-2、W-3（単位が `page` のとき）。足した |
| `page.spoken` | %lldページ | page %lld | 単位が `page` のときの読み上げ。足した |
| `location.short` | 位置%lld | Loc %lld | S-1、S-4、W-1、W-2、W-3（単位が `location` のとき。AC-141）。足した |
| `location.spoken` | 位置%lld | location %lld | 単位が `location` のときの読み上げ。足した |
| `percent.short` | %lld%% | %lld%% | S-1、S-4、W-1、W-2、W-3（単位が `percent` のとき。AC-141）。足した |
| `percent.spoken` | %lldパーセント | %lld percent | 単位が `percent` のときの読み上げ。足した |
| `book.isbnAsTitle` | ISBN %@ | ISBN %@ | 書名が空で ISBN があるときの表示用。足した |
| `widget.currentBookAsTitle` | 今の本 | Reading Now | 名無しの今の本（`isTitlePending = true`）の S-1、S-2、S-3、S-6、S-7、W-1、W-2、W-3 の書名の位置。PRD（AC-139、決定 66） |
| `book.pendingTitleGuard.title` | 今の本にまだ書名が入っていません | Current Book Has No Title Yet | 名無しの今の本があるときに別の本を `current` にしようとしたときの確認（verifier 提案2）。足した |
| `book.pendingTitleGuard.message` | 先に今の本の書名を入れるか、そのまま「今の本」として積読に移すかを選んでください。 | Enter a title for your current book first, or move it to your pile as “Reading Now”. | 同上。足した |
| `book.pendingTitleGuard.setTitle` | 今の本の書名を入れる | Enter Title First | 同上。足した |
| `book.pendingTitleGuard.continueAnyway` | そのまま切り替える | Switch Anyway | 同上。足した |
| `store.load.error.title` | 記録を読み込めませんでした | Couldn't Load Your Books | S-1（保存先読込失敗の見出し）。足した |
| `store.load.error` | もう一度読み込んでください。続くときは、アプリを終了して開き直してください。 | Try loading again. If it keeps happening, quit Yomuma and open it again. | S-1。PRD（AC-90） |
| `store.retry` | もう一度読み込む | Try Again | S-1。足した |
| `notice.close` | 閉じる | Dismiss | 部品 N。足した |
| `notice.close.hint` | 知らせを閉じます。 | Dismisses the notice. | 部品 N のヒント。足した |
| `session.tooShort` | 1分未満の読書は記録に残しません。 | Sessions shorter than 1 minute aren't saved. | S-1 の知らせ。PRD（AC-56） |
| `session.invalidTime` | 端末の時刻が読み始めより前になっていたので、この読書は記録に残しませんでした。「設定」で日付と時刻を確かめてから、もう一度読み始めてください。 | This session wasn't saved because the device's time was set earlier than when you started. Check the date and time in Settings, then start again. | S-1 の知らせ。PRD（AC-58） |
| `session.start.error` | 読み始めを保存できませんでした。もう一度「読み始める」を押してください。 | Couldn't start the session. Tap Start Reading again. | S-1 の知らせ、および「読み始める」インテントの失敗応答。PRD（AC-59、AC-119） |
| `common.save.error` | 保存できませんでした。変更は反映されていません。もう一度試してください。 | Couldn't save. Nothing was changed. Please try again. | 各画面の保存失敗の知らせ。PRD（AC-91、AC-95） |
| `session.flipStarted.announcement` | 「%@」を読み始めました。 | Started reading %@. | 伏せて始まったときの読み上げ。PRD（AC-49） |
| `reading.startedAt` | %@ から数えています。 | Counting since %@. | S-2。足した |
| `reading.note` | 伏せても、ロックしても、ほかのアプリを使っても数え続けます。 | Keeps counting while iPhone is face down, locked, or in another app. | S-2（紙の本）。足した |
| `reading.ebookNote` | この iPhone で電子書籍を読むときも、アプリを閉じたままで数え続けます。読み終えたらロック画面やダイナミックアイランドの「終える」でも終えられます。 | Keeps counting while you read in your e-book app on this iPhone. When you finish, you can also tap End Reading on the Lock Screen or Dynamic Island. | S-2（電子書籍 `isEbook = true`）。PRD（AC-144） |
| `reading.end` | 終える | End Reading | S-2 の主操作。PRD（AC-43） |
| `liveActivity.end.label` | 読書を終える | End Reading | W-3（Live Activity）の `liveActivity.end` ボタンの読み上げラベル。PRD（AC-114） |
| `session.save.error` | 終わりを保存できませんでした。読書は続いています。もう一度「終える」を押してください。 | Couldn't save the end of this session. It's still running. Tap End Reading again. | S-2 の知らせ。PRD（AC-60、AC-132） |
| `mark.navTitle` | しおりを挟む | Mark Your Place | S-3 のナビゲーションタイトル。足した |
| `mark.question` | どこまで読みましたか。 | Where did you stop? | S-3。足した |
| `mark.photo` | ページを撮る | Capture Page | S-3（記号 `camera.viewfinder`）。PRD（AC-63、AC-65） |
| `mark.screenshot` | スクリーンショットから選ぶ | Choose from Screenshots | S-3（記号 `photo.on.rectangle`）。PRD（AC-63、AC-142） |
| `mark.manual` | 一行を入れる | Enter the Line | S-3、S-3c。PRD（AC-63、AC-71、AC-94） |
| `mark.pageOnly` | ページだけ入れる | Enter Page Only | S-3、S-3c（電子書籍で位置・％のときは「位置・％だけ入れる」）。PRD（AC-63、AC-73、AC-94） |
| `mark.later` | あとで挟む | Mark Later | S-3。PRD（AC-63、AC-75） |
| `mark.later.note` | しおりは前のまま残ります。 | Your bookmark stays where it was. | S-3。足した |
| `mark.later.note.empty` | しおりは空のままです。 | Your bookmark stays empty. | S-3（前のしおりがないとき）。足した |
| `mark.cancel` | 閉じる | Close | S-3（読まずに挟むシートの閉じる）。足した |
| `mark.progressUnit.label` | 単位 | Unit | S-3a、S-3b、S-3c、S-7a、S-8c の `mark.progressUnit`。足した |
| `mark.progressUnit.page` | ページ | Page | `mark.progressUnit` の選択肢（`page`）。PRD（AC-141） |
| `mark.progressUnit.location` | 位置 | Location | `mark.progressUnit` の選択肢（`location`）。PRD（AC-141） |
| `mark.progressUnit.percent` | ％ | % | `mark.progressUnit` の選択肢（`percent`）。PRD（AC-141） |
| `mark.line.label` | 一行 | Line | S-3a、S-3c。足した |
| `mark.line.placeholder` | 止めた行を、本のとおりに | Type the line as printed | S-3a、S-3c。足した |
| `mark.line.footer` | 1〜60字。ロック画面には25字まで出ます。 | 1–60 characters. Up to 25 appear on the Lock Screen. | S-3a、S-3c。足した |
| `mark.page.label` | ページ | Page | S-3a、S-3b、S-3c（位置のときは「位置番号」、％のときは「％」）。足した |
| `mark.page.placeholder` | 例 61 | e.g. 61 | S-3a、S-3b、S-3c（位置のときは「例 1450」、％のときは「例 52」）。足した |
| `mark.page.footer.keep` | 前の値は%1$@です。空のまま保存すると、%1$@のまま残ります。 | Previous: %1$@. If you leave this blank, it stays at %1$@. | S-3a、S-3c の `mark.page.previous`。足した |
| `mark.page.footer.optional` | 空のままでも保存できます。 | You can leave this blank. | S-3a、S-3c（前の値がないとき）。足した |
| `mark.page.previous` | 前のページは%lldです。 | Previous page: %lld. | S-3b の `mark.page.previous`（位置なら「前の位置は位置%lldです。」、％なら「前の値は%lld%です。」）。足した |
| `mark.pageOnly.footer` | 保存すると一行は消え、ロック画面には書名と場所が出ます。 | Saving clears the line. The Lock Screen will show the title and place. | S-3b。足した |
| `mark.save` | 保存 | Save | S-3a、S-3b、S-3c。PRD（AC-65、AC-71、AC-73） |
| `mark.line.invalid` | 一行は1〜60字で入れてください。 | Enter a line of 1 to 60 characters. | S-3a、S-3c。PRD（AC-72） |
| `mark.page.invalid` | ページは1〜9999（位置は1〜999999、％は0〜100）の整数の数字で入れてください。 | Enter a whole number: 1–9999 for page, 1–999999 for location, or 0–100 for %. | S-3a、S-3b、S-3c。PRD（AC-74、AC-141） |
| `mark.ocr.hint` | 止めた行の枠を押すと、下の欄に入ります。文字はそのまま手で直せます。 | Tap the box for the line where you stopped. You can edit the text below. | S-3c。足した |
| `mark.ocr.none` | 文字を読み取れませんでした。明るい所で撮り直すか、手で入れてください。 | No text was found. Retake the photo in better light, or enter it manually. | S-3c、S-7c、S-8b、S-8d。PRD（AC-68） |
| `mark.retake` | 撮り直す | Retake | S-3c（スクショのときは「選び直す」／「Choose Another」）。PRD（AC-68） |
| `result.summary.pages` | p.%1$lld → p.%2$lld　%3$@ | p.%1$lld → p.%2$lld  %3$@ | S-4 の `result.summary`（ページ）。PRD（AC-76） |
| `result.summary.locations` | 位置%1$lld → 位置%2$lld　%3$@ | Loc %1$lld → Loc %2$lld  %3$@ | S-4 の `result.summary`（位置番号）。PRD（AC-141） |
| `result.summary.percents` | %1$lld%% → %2$lld%%　%3$@ | %1$lld%% → %2$lld%%  %3$@ | S-4 の `result.summary`（％）。PRD（AC-141） |
| `result.saved` | 記録しました。 | Session saved. | S-4。足した |
| `result.close` | 閉じる | Done | S-4 の主操作。足した |
| `session.capped` | 24時間で数えるのを止めました。分数は、本の画面の記録で直せます。 | Counting stopped at 24 hours. You can edit the minutes in the book's reading log. | S-4 の知らせ。PRD（AC-57） |
| `widgetGuide.title` | ロック画面に置く | Add to Your Lock Screen | S-5（`widgetGuide`）。PRD（AC-96） |
| `widgetGuide.body` | ロック画面を長押しして「カスタマイズ」を選び、時計の下の枠に「よむま」を加えると、iPhone を手に取るたびに、この一行が出ます。 | Touch and hold the Lock Screen, tap Customize, and add Yomuma below the clock. This line will appear each time you pick up iPhone. | S-5。足した |
| `widgetGuide.preview.label` | ロック画面での見え方。 | How it looks on the Lock Screen. | S-5 の見本の読み上げ。足した |
| `widgetGuide.close` | 閉じる | Done | S-5 の主操作。足した |
| `widget.displayName` | 続きの一行 | Where You Stopped | ウィジェットギャラリーの表示名。足した |
| `widget.description` | 今の本の、止めた一行と場所を出します。 | Shows the line and place where you stopped in your current book. | ウィジェットギャラリーの説明。足した |
| `widget.empty` | 今の本を選ぶと、ここに続きの一行が出ます。 | Choose a book in Yomuma to see your place here. | W-1、W-2。PRD（AC-32） |
| `widget.hidden` | しおり | Bookmark | W-1、W-2、W-3（`settings.hideOnWidgets` がオンのとき）。PRD（AC-34、AC-120） |
| `widget.unavailable` | よむまを開くと、ここに続きの一行が出ます。 | Open Yomuma to show your place here. | W-1、W-2（写しを読めないとき）。足した |
| `widget.spoken` | %1$@、%2$@。%3$@ | %1$@, %2$@. %3$@ | W-1、W-2、W-3 の読み上げ（書名、場所、一行）。足した |
| `widget.spoken.noPage` | %1$@。%2$@ | %1$@. %2$@ | W-1、W-2 の読み上げ（場所なし）。足した |
| `widget.spoken.noLine` | %1$@、%2$@ | %1$@, %2$@ | W-1、W-2 の読み上げ（一行なし）。足した |
| `shelf.navTitle` | 本棚 | Bookshelf | S-6 の題。足した |
| `shelf.current` | 今の本 | Reading Now | S-6 の区分。PRD（AC-13） |
| `shelf.tsundoku` | 積読 | To Read | S-6 の区分。PRD（AC-13） |
| `shelf.finished` | 読み終えた | Finished | S-6 の区分。PRD（AC-13） |
| `shelf.addBook` | 本を加える | Add a Book | S-6 のツールバーと空状態。足した |
| `shelf.empty.title` | 本棚に本がありません | No Books on Your Bookshelf | S-6。足した |
| `shelf.empty.message` | 読んでいる本と、積んである本を加えてください。 | Add the book you're reading and the ones waiting in your pile. | S-6。足した |
| `shelf.load.error` | 本棚を読み込めませんでした。もう一度読み込んでください。 | Couldn't load your bookshelf. Try loading again. | S-6。足した |
| `shelf.retry` / `book.retry` | もう一度読み込む | Try Again | S-6、S-7。足した |
| `colophon.header` | 奥付 | Colophon | S-7（`book.colophon`）、S-9（`finish.colophon`）。足した |
| `colophon.title.label` | 書名 | Title | 奥付（`colophon.title`）。PRD（AC-17） |
| `colophon.author.label` | 著者 | Author | 奥付（`colophon.author`）。PRD（AC-17） |
| `colophon.publisher.label` | 出版社 | Publisher | 奥付（`colophon.publisher`）。PRD（AC-17） |
| `colophon.publisher.withLabel` | %1$@（%2$@） | %1$@ (%2$@) | 奥付（出版社とレーベル）。PRD（AC-17） |
| `colophon.year.label` | 出版年 | Published | 奥付（`colophon.year`）。PRD（AC-17） |
| `colophon.year.value` | %lld年 | %lld | 奥付（出版年の値）。PRD（AC-17） |
| `colophon.award.label` | 受賞 | Awards | 奥付（`colophon.award`）。PRD（AC-17、AC-19〜AC-21） |
| `colophon.capture` | 奥付を撮って補う | Scan Colophon | S-7（`colophon.capture` / `book.captureColophon`）、S-9（`colophon.capture`）。PRD（AC-77、AC-113） |
| `colophon.save` | 保存 | Save | S-7c の保存ボタン。PRD（AC-113） |
| `book.records.header` | 記録 | Reading Log | S-7。足した |
| `book.nights` | %lld晩 | one: %lld night / other: %lld nights | S-7、S-9（カード）。PRD（AC-22、AC-84、AC-85） |
| `book.total` | 合計 %@ | Total %@ | S-7。PRD（AC-22） |
| `book.records.empty` | まだ記録がありません。読み始めて終えると、ここに残ります。 | No sessions yet. They appear here after you start and end reading. | S-7。PRD（AC-23） |
| `book.record.spoken` | %1$@の晩、%2$@ | Night of %1$@, %2$@ | S-7 の `book.record.row.<id>` の読み上げ。足した |
| `after.header` | この本のあとに | After This Book | S-7（読み終えた本 `finished` のおすすめ節の見出し）。PRD（AC-146） |
| `after.addToShelf` | 積読に加える | Add to Pile | S-7 の `after.candidate` のボタン。PRD（AC-146） |
| `after.added` | 積読に加えました | Added to Pile | S-7 で `after.addToShelf` を押したあとの表示。PRD（AC-146） |
| `book.readThis` | この本を読む | Read This Book | S-7 の主操作。PRD（AC-14） |
| `book.isCurrent` | 今読んでいる本です。 | You're reading this book. | S-7（`current` の本のとき）。足した |
| `book.edit` | 直す | Edit | S-7 のツールバー。PRD（AC-15） |
| `book.delete` | この本を消す | Delete This Book | S-7。PRD（AC-16） |
| `book.delete.confirm` | 「%1$@」と、この本の記録%2$lld件を消します。元に戻せません。 | one: Delete “%1$@” and its %2$lld session? This can't be undone. / other: Delete “%1$@” and its %2$lld sessions? This can't be undone. | S-7 の確認（記録1件以上）。PRD（AC-16） |
| `book.delete.confirm.noRecords` | 「%@」を消します。元に戻せません。 | Delete “%@”? This can't be undone. | S-7 の確認（記録0件）。足した |
| `book.delete.confirmButton` / `record.delete.confirmButton` | 消す | Delete | 確認ダイアログの破壊ボタン。足した |
| `book.load.error` | この本を読み込めませんでした。もう一度読み込んでください。 | Couldn't load this book. Try loading again. | S-7。足した |
| `book.edit.navTitle` | 本を直す | Edit Book | S-7a。足した |
| `book.edit.title` / `manual.title` | 書名 | Title | S-7a、S-8b、S-8c。PRD（AC-4、AC-7） |
| `book.edit.author` / `manual.author` | 著者 | Author | S-7a、S-8b、S-8c。PRD（AC-7） |
| `book.edit.isEbook` / `manual.isEbook` | 電子書籍 | E-Book | S-7a、S-8c の Toggle。PRD（AC-141、AC-144） |
| `book.edit.footer` / `manual.footer` | 書名は1〜100字、著者は100字まで（空でもかまいません）。 | Title: 1–100 characters. Author: up to 100 (optional). | S-7a、S-8c。足した |
| `book.edit.save` / `manual.save` / `record.save` / `cover.save` | 保存 | Save | S-7a、S-8c、S-7b、S-8b。PRD（AC-4、AC-7、AC-137） |
| `book.edit.cancel` / `manual.cancel` / `record.cancel` | 取り消す | Cancel | S-7a、S-8c、S-7b。足した |
| `book.title.invalid` | 書名は1〜100字で入れてください。 | Enter a title of 1 to 100 characters. | S-7a、S-8b、S-8c。PRD（AC-8） |
| `book.author.invalid` | 著者は100字までで入れてください。 | Enter an author name of up to 100 characters. | S-7a、S-8b、S-8c。PRD（AC-8） |
| `record.navTitle` | 記録を直す | Edit Session | S-7b。足した |
| `record.night` | %@の晩 | Night of %@ | S-7b。足した |
| `record.minutes.label` | 分 | Minutes | S-7b。足した |
| `record.minutes.footer` | 1〜1440分 | 1 to 1,440 minutes | S-7b。足した |
| `record.delete` | この記録を消す | Delete This Session | S-7b。PRD（AC-26） |
| `record.delete.confirm` | この記録（%@）を消します。元に戻せません。 | Delete this session (%@)? This can't be undone. | S-7b の確認。足した |
| `record.minutes.invalid` | 分は1〜1440の数字で入れてください。 | Enter minutes from 1 to 1,440. | S-7b。PRD（AC-25） |
| `register.navTitle` | 本を加える | Add a Book | S-8。足した |
| `register.barcode` | バーコードを続けて読む | Scan Barcodes | S-8（記号 `barcode.viewfinder`）。PRD（AC-2、AC-3） |
| `register.cover` | 表紙・背表紙を撮る | Scan Cover or Spine | S-8（記号 `text.viewfinder`）。PRD（AC-12、AC-137） |
| `register.screenshot` | スクリーンショットから選ぶ | Choose from Screenshots | S-8（記号 `photo.on.rectangle`、`register.photo` も同じ）。PRD（AC-12、AC-137） |
| `register.bookshelf` | 本棚・積読をまとめて撮る | Scan Bookshelf or Pile | S-8（記号 `books.vertical`）。PRD（AC-138） |
| `register.manual` | 手で入れる・書名で探す | Enter or Search by Title | S-8（記号 `square.and.pencil`）、S-3c・S-8b・S-8d の補助ボタン（「手で入れる」）。PRD（AC-4、AC-7） |
| `register.later` | あとで（すぐ読み始める） | Add Title Later (Start Now) | S-8（記号 `clock`、今の本0冊かつ名無しの本0冊のときだけ）。PRD（AC-139） |
| `register.footer` | 書誌の検索と文字の読み取りはすべてこの iPhone の中で行い、外部へ送信しません。 | Book lookup and text recognition happen entirely on this iPhone. Nothing is sent outside. | S-8 の下の説明（AC-103）。足した |
| `register.cancel` / `scan.cancel` / `finish.close` | 閉じる | Close | シートの閉じる。足した |
| `camera.denied` | カメラの使用が許可されていません。「設定」で許可するか、スクリーンショットから選ぶか、手で入れてください。 | Camera access is off. Allow it in Settings, choose from screenshots, or enter the text manually. | S-3、S-7c、S-8。PRD（AC-12、AC-70） |
| `camera.openSettings` | 設定を開く | Open Settings | S-3、S-7c、S-8。PRD（AC-12、AC-70） |
| `camera.restricted` | この iPhone ではカメラが制限されています。スクリーンショットから選ぶか、手で入れてください。 | The camera is restricted on this iPhone. Choose from screenshots or enter the details manually. | S-8。足した |
| `register.scanUnavailable` | この端末ではカメラの読み取りを使えません。スクリーンショットから選ぶか、手で入れてください。 | Camera scanning isn't available on this device. Choose from screenshots or enter the details manually. | S-8。足した |
| `scan.navTitle` | バーコードを続けて読む | Scan Barcodes | S-8a。足した |
| `scan.hint` | 本の裏のバーコード（2段あるときは両方）を写してください。続けて読めます。 | Point the camera at the barcode on the back of a book. You can scan one after another. | S-8a。足した |
| `scan.dbNotReady` | 端末内の書誌データを準備中です。この場で書名を入れるか、表紙を撮って加えられます。 | On-device book data is still downloading. Enter the title here or scan the cover. | S-8a の行（H20 が `notDownloaded` のとき）。PRD（AC-9） |
| `scan.notFound` | 端末内の書誌データにない本です。この場で書名を入れるか、表紙を撮って加えられます。 | Not found in on-device book data. Enter the title here or scan the cover. | S-8a の行（H20 にない ISBN のとき）。PRD（AC-10） |
| `scan.row.captureCover` | 表紙・背表紙を撮る | Scan Cover | S-8a の行内ボタン。PRD（AC-9、AC-10） |
| `scan.row.editTitle` | 書名を入れる | Enter Title | S-8a の行内入力欄のラベル・プレースホルダ。PRD（AC-9、AC-10、AC-11） |
| `scan.duplicate` | 「%@」はもう本棚にあります。 | “%@” is already on your bookshelf. | S-8a の知らせ。PRD（AC-3） |
| `scan.addToShelf` | %lld冊を本棚に加える | one: Add %lld Book to Bookshelf / other: Add %lld Books to Bookshelf | S-8a の主操作。PRD（AC-2、AC-3） |
| `scan.addToShelf.none` | 本棚に加える | Add to Bookshelf | S-8a（0冊のとき、無効状態）。足した |
| `scan.discard.confirm` | 読んだ%lld冊を加えずに閉じます。 | one: Close without adding %lld scanned book? / other: Close without adding %lld scanned books? | S-8a の破棄確認。足した |
| `scan.discard.confirmButton` | 加えずに閉じる | Close Without Adding | S-8a の破棄確認。足した |
| `cover.navTitle` | 表紙・背表紙から選ぶ | Select Title and Author | S-8b。足した |
| `cover.hint` | 1回目に押した行が「書名」、2回目に押した行が「著者」に入ります。 | First tap sets the title; second tap sets the author. | S-8b（AC-137）。足した |
| `cover.selectTitle` | 書名 | Title | S-8b の1タップ目の役割札。PRD（AC-137） |
| `cover.selectAuthor` | 著者 | Author | S-8b の2タップ目の役割札。PRD（AC-137） |
| `bookshelf.navTitle` | 本棚・積読から選ぶ | Select Books from Photo | S-8d。足した |
| `bookshelf.hint` | 加えたい本の背表紙の枠を押してください。何冊でも選べます。 | Tap the spine boxes for the books you want to add. | S-8d（AC-138）。足した |
| `bookshelf.addSelected` | 選んだ%lld冊を積読に加える | one: Add %lld Selected Book to Pile / other: Add %lld Selected Books to Pile | S-8d の主操作。PRD（AC-138） |
| `search.noResults` | 「%@」に合う候補は書誌データにありませんでした。このまま保存できます。 | No matches for “%@” in book data. You can save it as entered. | S-8c（`manual.title` の候補が0件のとき）。PRD（AC-5） |
| `finish.title` | 読み終えました | Finished | S-9 の見出し。足した |
| `finish.reflection.multi` | %1$lld晩、合計%2$lld分（%3$@）。いちばん長かったのは%4$@の晩の%5$lld分でした。 | %1$lld nights, %2$lld min (%3$@) in total. Your longest night was %4$@, at %5$lld min. | S-9 の `finish.reflection`（2晩以上）。PRD（AC-127、AC-128） |
| `finish.reflection.single` | 1晩、%lld分で読み終えました。 | Finished in 1 night, %lld min. | S-9 の `finish.reflection`（1晩だけ）。PRD（AC-128） |
| `finish.card.share` | 読み終えのカードを共有 | Share Finish Card | S-9 のカード共有ボタン。PRD（AC-84、AC-85） |
| `next.header` | 次の1冊 | Your Next Book | S-9。足した |
| `next.subheader` | 積読と、この本につながる本から選んでいます。 | Picked from your pile and books connected to this one. | S-9。足した |
| `next.reason.tsundoku` | 積読から | From your pile | S-9、S-1（noCurrent）の理由。PRD（AC-80） |
| `next.reason.sameAuthor` | 積読から・同じ著者 | From your pile · Same author | S-9、S-1 の理由。PRD（AC-79） |
| `next.reason.sameAward` | 積読から・同じ賞（%@） | From your pile · Same award (%@) | S-9、S-1 の理由。PRD（AC-79） |
| `next.reason.sameLabel` | 積読から・同じレーベル（%@） | From your pile · Same imprint (%@) | S-9、S-1 の理由。PRD |
| `rec.reason.readers` | この本を読み終えた人が、次に読んだ本 | Read next by people who finished this book | S-9（`next.reason`）、S-7（`after.reason`）の共起の理由（人数は出さない）。PRD（AC-148） |
| `rec.reason.nextVolume` | シリーズの次の巻 | Next volume in the series | S-9、S-7 の未所有の候補の理由。PRD（AC-87） |
| `rec.reason.sameAuthor` | 同じ著者の本 | By the same author | S-9、S-7 の未所有の候補の理由。PRD（AC-87、AC-146、AC-147） |
| `rec.reason.sameAward` | 同じ賞（%@） | Same award (%@) | S-9、S-7 の未所有の候補の理由（例：「同じ賞（第157回 直木三十五賞）」）。PRD（AC-79、AC-146、AC-147） |
| `next.choose` | この本を読む | Read This Book | S-9 の積読候補のボタン。PRD（AC-82） |
| `next.addToShelf` | 積読に加える | Add to Pile | S-9 の未所有候補のボタン。PRD（AC-83、AC-87） |
| `next.added` | 積読に加えました | Added to Pile | S-9 で `next.addToShelf` を押したあとの表示。足した |
| `next.skip` | 今は読まない | Not Right Now | S-9 の下部で候補を見送って閉じるボタン。PRD（AC-147） |
| `next.empty.title` | 次の候補がありません | No Next Book Yet | S-9（空状態の見出し）。足した |
| `next.empty.message` | 積読の本がありません。次に読む本を加えてください。 | There are no books in your pile. Add the book you'll read next. | S-9。PRD（AC-81） |
| `next.addBook` | 本を加える | Add a Book | S-9。PRD（AC-81） |
| `finish.undoNote` | まだ読み終えていなかったときは、本棚でこの本を開き、「この本を読む」を押すと戻せます。 | Not finished after all? Open this book in your bookshelf and tap Read This Book. | S-9 の一番下。足した |
| `settings.navTitle` | 設定 | Settings | S-10。足した |
| `settings.section.start` | 読み始めと夜の入口 | Starting a Session | S-10。足した |
| `settings.flipToStart` | 伏せて始める | Start When Face Down | S-10。PRD（AC-51） |
| `settings.flipToStart.footer` | しおりの画面で iPhone を伏せて置くと、読書が始まります。オフにすると、「読み始める」ボタンだけで始めます。 | Placing iPhone face down on the bookmark screen starts a session. When this is off, use the Start Reading button. | S-10。足した |
| `settings.flipToStart.unavailable` | この端末では、伏せて始める道を使えません。 | Starting face down isn't available on this device. | S-10（H18）。PRD（AC-51） |
| `settings.entryTime` | 夜の入口の時刻 | Evening Entry Time | S-10（15分刻みの時刻選択）。PRD（AC-38） |
| `settings.entryTime.footer` | この時刻になると、ロック画面に今の本の続きの一行が出ます。 | At this time each evening, the Lock Screen shows the line where you stopped. | S-10。足した |
| `settings.liveActivity.off` | ロック画面の「ライブアクティビティ」がオフになっているため、夜の入口の時刻の表示は出ません。iPhone の「設定」＞「アプリ」＞「よむま」でオンにできます。 | Live Activities are turned off, so the evening entry won't appear on the Lock Screen. You can turn them on in iPhone Settings > Apps > Yomuma. | S-10（`areActivitiesEnabled == false` のとき）。PRD（AC-37） |
| `settings.section.lockScreen` | ロック画面 | Lock Screen | S-10。足した |
| `settings.hideOnWidgets` | 一行と書名を隠す | Hide Line and Title | S-10。PRD（AC-34） |
| `settings.hideOnWidgets.footer` | ロック画面とホーム画面のウィジェット、およびライブアクティビティに一行と書名を出さず、「しおり」と場所だけを出します。アプリの中には出ます。 | Widgets and Live Activities show only “Bookmark” and your place. The line and title still appear in the app. | S-10。足した |
| `settings.section.appearance` | 見た目と購入 | Appearance & Purchases | S-10。足した |
| `settings.appearance` | 見た目 | Appearance | S-10。PRD（AC-105） |
| `settings.restorePurchases` | 購入を復元する | Restore Purchases | S-10。PRD（AC-108） |
| `appearance.default` | 標準（白と黒） | Default (Paper & Ink) | S-10a（`default`）。足した |
| `appearance.kinari` | 生成り | Kinari (Warm Cream) | S-10a（`kinari`、よむま＋）。足した |
| `appearance.sumi` | 墨 | Sumi (Deep Charcoal) | S-10a（`sumi`、よむま＋）。足した |
| `appearance.shu` | 朱 | Shu (Vermilion Seal) | S-10a（`shu`、よむま＋）。足した |
| `store.product.title` | よむま＋（買い切り） | Yomuma+ (One-Time Purchase) | S-10a の購入シート。PRD（AC-105） |
| `store.product.description` | 生成り・墨・朱の3つの見た目を、しおりの画面、ウィジェット、読み終えのカードで使えます。1回の購入でずっと使えます。 | Unlock three paper-and-ink appearances (Kinari, Sumi, Shu) for your bookmark screen, widgets, and finish cards. Pay once, keep forever. | S-10a の購入シート。PRD（AC-105） |
| `store.buy` | よむま＋を買う（¥980） | Buy Yomuma+ | S-10a の購入シートの主操作（`Product.displayPrice` を併記。基準価格 ¥980）。PRD（AC-105、AC-106） |
| `store.restore` | 購入を復元する | Restore Purchases | S-10a の購入シート。PRD（AC-105） |
| `store.close` | 閉じる | Close | S-10a の購入シート。PRD（AC-105） |
| `store.purchase.error` | 購入を完了できませんでした。支払いは行われていません。もう一度試してください。 | Couldn't complete the purchase. You weren't charged. Please try again. | S-10a の購入シート。PRD（AC-107） |
| `store.restore.done` | 購入を復元しました。「よむま＋」の見た目を選べます。 | Purchases restored. Yomuma+ appearances are now available. | S-10、S-10a。PRD（AC-108） |
| `store.restore.none` | この Apple Account で購入された記録が見つかりませんでした。 | No previous purchases were found for this Apple Account. | S-10、S-10a。PRD（AC-108） |
| `store.unavailable` | この iPhone では App Store での購入が制限されているため、購入できません。 | In-app purchases are restricted on this iPhone. | S-10a。PRD（AC-109） |
| `store.offline` | 通信できないため、商品の情報を読み込めませんでした。通信が戻ってから試してください。 | You're offline, so product details couldn't be loaded. Try again when connected. | S-10a、S-10。PRD（AC-110） |
| `settings.section.catalog` | 書誌データ | Book Catalog | S-10。足した |
| `catalog.status.ready` | 端末内の書誌データ（%@版）は準備できています。 | On-device book catalog (version %@) is ready. | S-10（AC-11）。足した |
| `catalog.status.notDownloaded` | 端末内の書誌データをまだ取得していません。通信できるときに取得します。 | On-device book catalog hasn't been downloaded yet. | S-10、S-8c（AC-11）。足した |
| `catalog.retry` | 書誌データを今すぐ取得する | Download Book Catalog Now | S-10、S-8c（AC-11）。足した |
| `settings.section.info` | 情報 | About | S-10。足した |
| `settings.privacyPolicy` | プライバシーポリシー | Privacy Policy | S-10。PRD（AC-88） |
| `settings.dataSources.header` | 書誌の出どころ | Book Data | S-10。足した |
| `settings.dataSources` | 書誌（書名、著者、出版社など）は、国立国会図書館書誌データ（「国立国会図書館蔵書」「国立国会図書館新着書誌情報」「全国書誌情報」、データ提供機関：国立国会図書館、取得日：%1$@）を出典とし、国立国会図書館サーチの API を用いて取得したデータをこのアプリで加工して端末内の書誌データベース（版：%1$@）を作成しています。ライセンスはクリエイティブ・コモンズ 表示 4.0 国際 パブリック・ライセンス（CC BY 4.0）です。なお、「この本を読み終えた人が、次に読んだ本」の候補は、利用者の同意のもとで集計した読書順序データに基づくもので、国立国会図書館のデータとは無関係です。 | Book details (title, author, publisher, and so on) derive from National Diet Library bibliographic data (“National Diet Library Catalog” 国立国会図書館蔵書, “NDL newly acquired bibliographic data” 国立国会図書館新着書誌情報, and “Japanese National Bibliography” 全国書誌情報; provided by the National Diet Library, Japan 国立国会図書館; retrieved on %1$@). This app retrieved the data using the NDL Search API and processed it to create the on-device book database (version %1$@) under the Creative Commons Attribution 4.0 International Public License (CC BY 4.0). Note: “Read next by people who finished this book” recommendations are based on reading-order data aggregated with user consent and are unrelated to National Diet Library data. | S-10（AC-93 の3条件＋版＋共起データの注記をすべて含む）。PRD（AC-93） |
| `settings.dataSources.license` | ライセンス（CC BY 4.0） | License (CC BY 4.0) | S-10（`https://creativecommons.org/licenses/by/4.0/deed.ja` / `https://creativecommons.org/licenses/by/4.0/` を開く）。PRD（AC-93） |
| `control.startReading` | 読み始める | Start Reading | W-4（`ControlWidgetButton` のラベル）。PRD（AC-126） |
| `intent.start.started` | 読書を始めました。 | Started reading. | W-5（「読み始める」インテントの開始時の声の文）。PRD（AC-114） |
| `intent.start.alreadyReading` | すでに読書中です。 | A reading session is already running. | W-5（読書中に「読み始める」を動かしたときの声の文）。PRD（AC-115） |
| `intent.whereStopped.page` | %lldページからです。 | From page %lld. | W-5（「どこまで読んだ？」で単位が `page` のときの声と小窓の全文。書名と一行は含めない）。PRD（AC-121、AC-123、AC-125） |
| `intent.whereStopped.location` | 位置%lldからです。 | From location %lld. | W-5（「どこまで読んだ？」で単位が `location` のときの声と小窓の全文）。PRD（AC-143） |
| `intent.whereStopped.percent` | %lldパーセントからです。 | From %lld percent. | W-5（「どこまで読んだ？」で単位が `percent` のときの声と小窓の全文）。PRD（AC-143） |
| `intent.whereStopped.noPage` | 今の本には、まだページが記録されていません。 | No page is saved for your current book yet. | W-5（「どこまで読んだ？」で今の本に場所の値がないとき）。PRD（AC-122） |
| `intent.whereStopped.noCurrent` | いま読んでいる本が選ばれていません。 | No current book is selected. | W-5（「どこまで読んだ？」で今の本が0冊のとき）。PRD（AC-122） |
| `intent.whereStopped.error` | しおりを読み込めませんでした。よむまを開いて確かめてください。 | Couldn't load your bookmark. Open Yomuma to check. | W-5（「どこまで読んだ？」で保存先の読み込みに失敗したとき）。PRD（AC-133） |
| `duration.minutes` | %lld分 | %lld min | 60分未満の時間。足した |
| `duration.hoursMinutes` | %1$lld時間%2$lld分 | %1$lld hr %2$lld min | 60分以上（分が0なら `duration.hours`）。足した |
| `duration.hours` | %lld時間 | %lld hr | 足した |

### 7-2 App Shortcuts の言い方と記号、Control のラベル、小窓の対応表（AC-121〜AC-126、AC-133、AC-143）
- **日本語の言い方の決まり（AC-126）**：アプリ名（`よむま`）の差し込み `\(.applicationName)` の直後に助詞「で」を続けない（「よむまで」が「読むまで」と音声認識で衝突するため。R-64）。「の」「を使って」「から」でつなぐ。

| インテント | 役割 | 記号（SF Symbols） | 日本語の言い方（すべて `\(.applicationName)` を含む。「\(.applicationName)で」は0件） | 英語の言い方（すべて `\(.applicationName)` を含む） | 小窓（Snippet）の中身 |
|---|---|---|---|---|---|
| `StartReadingIntent`（「読み始める」） | アプリを開かずに読書を始め、Live Activity を出す（今の本がないとき・Live Activity オフ時はアプリを開く） | `play.fill` | ①「\(.applicationName)の読書を始める」<br>②「\(.applicationName)を使って読み始める」<br>③「\(.applicationName)から読み始める」 | ① "Start reading in \(.applicationName)"<br>② "Begin reading with \(.applicationName)" | 出さない（声 `intent.start.started` / `intent.start.alreadyReading` / `session.start.error` と Live Activity で伝える） |
| `WhereStoppedIntent`（「どこまで読んだ？」） | ロック中でも認証なし（`alwaysAllowed`）で、止めたページ・位置・％だけを答え、一行と書名は出さない | `bookmark` | ①「\(.applicationName)はどこまで読んだ」<br>②「\(.applicationName)のしおりは何ページ」<br>③「\(.applicationName)の続きのページを教えて」 | ① "Where did I stop in \(.applicationName)"<br>② "What page am I on in \(.applicationName)" | 声とまったく同じ1行の `Text`（`intent.whereStopped.page` / `location` / `percent` / `noPage` / `noCurrent` / `error`）。書名と一行は小窓にも一切出さない（AC-121、AC-123、AC-133、AC-143） |
| `ContinueReadingIntent`（「続きを読む」） | アプリを前に出して S-1（読書中なら S-2）を開く | `book` | ①「\(.applicationName)の続きを読む」<br>②「\(.applicationName)のしおりを開く」<br>③「\(.applicationName)から続きを開く」 | ① "Continue reading in \(.applicationName)"<br>② "Open my bookmark in \(.applicationName)" | 出さない（アプリ自身が前面に開くため） |

- **Control（W-4、AC-126）**：種類は `ControlWidgetButton`（トグルではない）の1つだけ。動かすインテントは `StartReadingIntent`、ラベルは文言キー `control.startReading`（「読み始める」／「Start Reading」）、記号は `book`。

### 7-3 許可を求める理由の文と、求める時（AC-1、AC-12、AC-70、AC-142）
- 求める OS の許可は**カメラだけ**（写真とスクリーンショットは `PhotosPicker` を使うため `NSPhotoLibraryUsageDescription` は不要で、写真ライブラリの許可は一切求めない。位置情報、連絡先、マイク、トラッキング ATT も一切求めない。AC-12、AC-70、AC-142）。
- カメラの許可を求める時は、利用者がカメラを使うボタン（`register.barcode`、`register.cover`、`register.bookshelf`、`mark.photo`、`colophon.capture`）を初めて押したとき（未決定 `notDetermined` のとき）だけ。最初の起動では求めず（AC-1）、前に独自の説明画面も挟まない（R-27）。
- `NSCameraUsageDescription`（InfoPlist.xcstrings）：
  - 日本語：「本のバーコードや表紙・背表紙・奥付、および読み止めたページの文字をこの iPhone の中で読み取るためにカメラを使います。写真は保存せず、外部へ送信しません。」
  - 英語：「Yomuma uses the camera to scan barcodes, covers, spines, colophons, and the line where you stopped on this iPhone. Photos are never saved or sent outside.」

---

## 8. 見た目

- **使うトークン**（すべての値とコントラスト比は `design/001-reading-session/tokens.md`）：
  - 色：標準（`default`）と、よむま＋の3種（生成り `kinari`、墨 `sumi`、朱 `shu`）の意味トークン（`color.background.primary`、`color.background.grouped`、`color.background.groupedRow`、`color.text.primary`、`color.text.secondary`、`color.action.primary.background`、`color.action.primary.label`、`color.action.tint`、`color.action.destructive`、`color.state.error`、`color.state.on`、`color.separator`）、および写真上の読み取り枠のトークン（`color.ocr.box.outer`、`color.ocr.box.inner`、`color.ocr.badge.background`、`color.ocr.badge.label`）。
  - 文字：`type.book.line`（ヒラギノ明朝 ProN W3、28pt、Dynamic Type `.title` 追従）、`type.book.line.widget.rectangular`（W6、17pt/15pt 固定）、`type.book.line.widget.small`（W6、20pt/19pt 固定）、`type.book.line.liveActivity`（W6、16pt）、およびシステムの text style（`.largeTitle`、`.title`、`.title2`、`.headline`、`.body`、`.subheadline`、`.footnote`、`.caption2`）。
  - 余白：`space.4`、`space.8`、`space.12`、`space.16`、`space.24`、`space.32` の6つだけ。
- **画面ごとの文字の段（B-4：3段を目安に最大4段まで）**：
  - S-1：一行（`type.book.line`）、書名・主操作（`.headline`）、著者・場所・補助ボタン（`.subheadline`）、伏せる案内（`.footnote`）の4段。
  - S-2：書名（`.title2` Bold）、始めた時刻（`.body`）、数え続ける1行（`.subheadline`）、主操作（`.headline`）の4段。
  - S-3：問い（`.title2` Bold）、書名とボタンの説明（`.subheadline` / `.footnote`）、ボタン（`.headline`）の3段。
  - S-4：まとめ（`.title`、`monospacedDigit`）、書名と主操作（`.headline`）、「記録しました。」（`.subheadline`）の3段。
  - S-6、S-7、S-7a〜S-7c、S-8、S-8a〜S-8d、S-10、S-10a：`List` と `Form` の既定（行 `.body`、補足 `.subheadline`、節の見出しと説明 `.footnote`、主操作 `.headline`）。
  - S-9：見出し（`.largeTitle`）、ふりかえりと奥付の値（`.body`）、候補の書名（`.headline`）、奥付の項目名・理由・戻し方（`.subheadline` / `.footnote`）の4段。
  - W-1、W-2：一行（明朝 W6）と場所（`.caption2` Semibold）の2段。
  - W-3（Live Activity）：書名（`.headline`）、一行または経過時間（`.subheadline`）の2段。
- **使う SF Symbols の名前**（文字と同じ太さと大きさ。塗りの記号は検索・入力消去の `xmark.circle.fill` と Live Activity 開始の `play.fill` のほかは使わない。アプリアイコンには使わない）：
  - `books.vertical`（本棚、本棚まとめて撮影）、`gearshape`（設定）、`plus`（本を加える）、`barcode.viewfinder`（バーコード）、`text.viewfinder`（表紙・背表紙撮影、奥付撮影）、`camera.viewfinder`（ページを撮る）、`photo.on.rectangle`（スクリーンショットから選ぶ）、`square.and.pencil`（手で入れる）、`clock`（あとで登録）、`book.closed`（本0冊の空状態）、`book`（コントロールとショートカット）、`bookmark`（どこまで読んだ？）、`play.fill`（読み始めるショートカット）、`lock`（未購入のよむま＋の見た目）、`square.and.arrow.up`（読み終えカードの共有）、`exclamationmark.triangle`（読込エラー）、`exclamationmark.circle`（入力エラーとエラーの知らせ）、`info.circle`（通常の知らせ）、`camera`（カメラ権限なし）、`checkmark`（選択中）、`trash`（消す操作、記号だけ赤）、`arrow.up.forward`（外部リンクの末尾）、`arrow.counterclockwise`（撮り直す）。
- **性格語が表れている場所**：
  - **静か**：S-2 に動く秒時計がなく、押せる要素が「終える」1つだけ。S-4 と S-9 に紙吹雪や祝う言葉がない。毎晩の道と読み終えた画面に課金バナーを出さない（AC-104）。外部通信は0件（AC-103）。
  - **確か**：S-2「伏せても、ロックしても、ほかのアプリを使っても数え続けます。」、S-3a「前のページは43です。空のまま保存すると、43のまま残ります。」、奥付はデータのある行だけ、推薦の理由は確かめられる事実1行（AI で文を作らない）、写真・スクショの読み取りは枠と欄で確かめてその場で直せ、画像は一切残さない（AC-69）。
  - **まっすぐ**：どの画面も主操作は1つで動詞から始まる。初回起動の案内もカメラの事前説明画面も挟まない（AC-1、AC-12）。今すぐ読みたい夜は「あとで」（`register.later`）の1タップで読書に入れる（AC-139）。
  - **急かさない**：連続日数、目標、ノルマ、未読数のバッジを出さない。知らせを時間で消さない。S-9 に「今は読まない」（`next.skip`）と戻し方の1行を置く。
  - **紙の側**：ヒラギノ明朝の縦書きの一行（W-1、W-2、S-1、S-5）。ノンブルの位置の「p.61」。奥付の型（S-7、S-9、読み終えのカード）。紙と墨の見た目「生成り・墨・朱」（S-10a）。
- **参考にした HIG のページ（URL）**：
  - https://developer.apple.com/design/human-interface-guidelines/widgets
  - https://developer.apple.com/design/human-interface-guidelines/live-activities
  - https://developer.apple.com/design/human-interface-guidelines/controls
  - https://developer.apple.com/design/human-interface-guidelines/siri
  - https://developer.apple.com/design/human-interface-guidelines/in-app-purchase
  - https://developer.apple.com/design/human-interface-guidelines/entering-data
  - https://developer.apple.com/design/human-interface-guidelines/machine-learning
  - https://developer.apple.com/design/human-interface-guidelines/design-principles
  - https://developer.apple.com/design/human-interface-guidelines/accessibility
  - https://developer.apple.com/design/human-interface-guidelines/typography
  - https://developer.apple.com/design/human-interface-guidelines/materials
  - https://developer.apple.com/design/human-interface-guidelines/color
  - https://developer.apple.com/design/human-interface-guidelines/dark-mode
  - https://developer.apple.com/design/human-interface-guidelines/writing
  - https://developer.apple.com/design/human-interface-guidelines/privacy
  - https://developer.apple.com/design/human-interface-guidelines/onboarding
  - https://developer.apple.com/design/human-interface-guidelines/playing-haptics
  - https://developer.apple.com/design/human-interface-guidelines/buttons
  - https://developer.apple.com/design/human-interface-guidelines/sheets
  - https://developer.apple.com/design/human-interface-guidelines/alerts
  - https://developer.apple.com/design/human-interface-guidelines/action-sheets
  - https://developer.apple.com/design/human-interface-guidelines/toolbars
  - https://developer.apple.com/design/human-interface-guidelines/lists-and-tables
  - https://developer.apple.com/design/human-interface-guidelines/text-fields
  - https://developer.apple.com/design/human-interface-guidelines/search-fields
  - https://developer.apple.com/design/human-interface-guidelines/pickers
  - https://developer.apple.com/design/human-interface-guidelines/loading
  - https://developer.apple.com/design/human-interface-guidelines/toggles

---

## 9. アクセシビリティ

- **いちばん大きい文字（AX5）で並びを変える場所**：
  - **S-1**：一行を横書きに切り替える（accessibility1 以上、および縦で幅に入らないとき）。「どこまで読んだかを入れる」「読み終えた」（および名無しの本の「書名を入れる」）の横並びを縦並び（幅いっぱいの `.bordered`）にする。書名と著者の行数の上限を外す。「読み始める」は下端に固定したまま幅いっぱいにし、上の内容だけを縦に送る。伏せる案内はスクロール領域の一番下に移す。
  - **S-2、S-3、S-4**：もともと縦並び。文字は折り返し、切らない。S-4 の「p.43 → p.61　18分」は2行に分かれてよい。下端の主操作は固定し、上の文だけを送る。
  - **S-3c、S-8b、S-8d（写真・スクリーンショットの読み取り画面）**：accessibility1 以上の文字サイズでは、画像の上の枠ボタンに加えて、画像の下に標準の `List` で読み取った行（同じ識別子 `mark.ocr.column.<n>` / `cover.ocr.line.<n>`）を縦に並べ、細かい枠を狙わなくても大きな文字の行で選べるようにする。下端の保存・追加ボタンは固定する。
  - **S-6、S-8、S-8c、S-10a**：行の書名と補足、ボタンは縦に折り返す。行数の上限を外す。
  - **S-7、S-9 の奥付**：項目名と値の左右2列をやめ、項目名の下に値を縦に積む（accessibility1 以上）。
  - **S-7（「この本のあとに」）、S-9（「次の1冊」）、S-1（今の本なしの候補）**：候補の行のボタン（`next.choose`、`next.addToShelf`、`after.addToShelf`、`bookmark.noCurrent.choose`）を書名と理由の下に幅いっぱいで回す。
  - **S-8a**：カメラ領域を画面の高さの3分の1に縮め、読めた本の一覧に高さを回す。行内の `scan.row.captureCover` と `scan.row.editTitle` は縦に積む。
  - **W-1、W-2**：枠が広がらないため固定サイズ（決定 8）。大きい文字の利用者は押して開いた S-1 で拡大された全文を読む。
  - **W-3（Live Activity）**：上限 `.xxxLarge` まで拡大し、書名と経過時間と「終える」ボタンが重ならないよう2行に折り返す。
- **色だけで区別していないか**：
  - 選んだ枠（S-3c、S-8b、S-8d）：白黒2重線の内側の太さ（2pt → 3pt）と、番号・役割札（「✓ 6」「書名」「著者」）、および VoiceOver の `.isSelected` トレイトで示す。
  - 選んだ行（S-8c の書名候補、S-10a の見た目）：チェックの記号 `checkmark` と `.isSelected` トレイト。
  - 未購入の見た目（S-10a）：鍵の記号 `lock` と「よむま＋」の補足文。
  - エラー：記号 `exclamationmark.circle` の形と説明の文で伝える。赤は記号の色だけで、文字は本文の色。
  - 消す操作：文字（「この本を消す」「この記録を消す」）と記号 `trash` の形で伝える。赤は記号だけ。
- **動きを減らす設定、透明度を下げる設定のとき**：
  - 独自の動きはない。画面の出入りはシステムの押し出しとシートで、動きを減らす設定ではシステムがフェードに切り替える。伏せて始まったことは、触覚・読み上げ・起こしたときの S-2 の3つで伝える。
  - ツールバーとシートの Liquid Glass は、透明度を下げる設定でシステムが不透明にする。
- **VoiceOver の読み上げ順**：
  - **W-1、W-2**：1つのまとまり（書名または「今の本」または「しおり」→ 場所 → 一行。AC-99）。
  - **W-3**：待つ状態は1つのまとまり（書名 → 場所 → 一行）。読書中は、書名と経過時間のまとまり → `liveActivity.end`（「読書を終える」ボタン）。
  - **S-1**：本棚、設定（ツールバー）→（知らせ）→ 書名 → 著者 → 一行 → 場所 → どこまで読んだかを入れる → 読み終えた →（名無しの本なら）書名を入れる → 読み始める → 伏せる案内。
  - **S-2**：書名 → 始めた時刻 → 数え続ける1行（または電子書籍の案内）→（知らせ）→ 終える。
  - **S-3**：問い → 書名 → ページを撮る →（カメラ拒否の文と設定を開く）→ スクリーンショットから選ぶ → 一行を入れる → ページだけ入れる → あとで挟む →（シートのとき）閉じる。
  - **S-3a、S-3b**：一行の欄（S-3a）→ 進捗単位ピッカー（電子書籍のとき）→ 場所の欄 → 前の場所の説明 → 保存。
  - **S-3c**：案内文 → 読み取った列 `mark.ocr.column.1`〜`<n>`（右から順）→ 一行の欄 `mark.lineField` →（電子書籍のとき）単位ピッカー `mark.progressUnit` → 場所の欄 `mark.pageField` → 撮り直す → 手で入れる → 保存 `mark.save`。
  - **S-4**：書名 → まとめ → 記録しました →（知らせ）→ 閉じる。
  - **S-5**：見出し → 説明 → 見本 → 閉じる。
  - **S-6**：今の本 → 積読 → 読み終えた（区分の見出し、行の順）→ 本を加える（ツールバー）。
  - **S-7**：奥付（行ごと：`colophon.title`、`colophon.author`、`colophon.publisher`、`colophon.year`、`colophon.award`）→ 奥付を撮って補う `colophon.capture` → 記録の見出し（何晩、合計）→ 記録の行 `book.record.row.<id>` →（読み終えた本なら）「この本のあとに」見出し `after.header` → 候補ごと（書名・著者・`after.reason` → `after.addToShelf`）→ この本を消す `book.delete` → この本を読む `book.readThis` → 直す `book.edit`（ツールバー）。
  - **S-8**：バーコードを続けて読む → 表紙・背表紙を撮る → スクリーンショットから選ぶ → 本棚・積読をまとめて撮る → 手で入れる・書名で探す →（条件を満たすとき）あとで → 端末内処理の説明 → 閉じる。
  - **S-8a**：カメラ →（知らせ）→ 読めた行 `scan.row.<ISBN>`（未取得・未収録なら行内の文と `scan.row.editTitle`・`scan.row.captureCover`）→ n冊を本棚に加える `scan.addToShelf` → 閉じる。
  - **S-8b**：案内文 → 読み取った行 `cover.ocr.line.1`〜`<n>` → 書名の欄 `manual.title` → 著者の欄 `manual.author` → 撮り直す → 手で入れる → 保存 `cover.save`。
  - **S-8c**：書名の欄 `manual.title` → 候補の行 `search.row.<ISBN>`（または `search.noResults`）→ 著者の欄 `manual.author` → 電子書籍トグル → 保存 `manual.save`。
  - **S-8d**：案内文 → 背表紙の枠 → 選んだ候補の行 `bookshelf.row.<n>` → 選んだn冊を積読に加える `bookshelf.addSelected`。
  - **S-9**：見出し → ふりかえりの1行 `finish.reflection` → 奥付 `finish.colophon` → 奥付を撮って補う `colophon.capture` → 読み終えのカードを共有 `finish.card.share` → 次の1冊の見出しと説明 → 候補ごと（書名・著者・`next.reason` → `next.choose` または `next.addToShelf`）→ 今は読まない `next.skip` → 戻し方の1行 → 閉じる。
  - **S-10**：読み始めと夜の入口（伏せて始める → 夜の入口の時刻 → Live Activity オフの案内）→ ロック画面（一行と書名を隠す）→ 見た目と購入（見た目 → 購入を復元する）→ 書誌データ（状態 → 再取得）→ 情報（プライバシーポリシー → 書誌の出どころ → ライセンス）。
  - **S-10a**：見た目の行（標準、生成り、墨、朱）。購入シートが出ているときは、品名 → 説明 → 見本 `store.preview` → 値段 → よむま＋を買う `store.buy` → 購入を復元する `store.restore` → 閉じる `store.close`。
- **英語が長くなったとき（疑似言語 Double-Length で確かめる画面）**：
  - S-1、S-2、S-3（5つの道のボタン）、S-3c、S-4、S-7（「この本のあとに」の理由とボタン）、S-8（6つの道）、S-8a〜S-8d、S-9（ふりかえり、理由、ボタン）、S-10、S-10a、W-1〜W-3。ボタンの文字は折り返して切らず、横並びは入らなければ `ViewThatFits` で縦並びにする。
- **押せる範囲**：どの押せる要素も **44×44 pt 以上**。`.bordered` のボタン（`bookmark.setMark`、`bookmark.finish`、`bookmark.setBookTitle`、`mark.later`、`notice.close`、`colophon.capture`、`finish.card.share`、`next.choose`、`next.addToShelf`、`after.addToShelf`）も高さを 44pt 以上にする。写真上の読み取り枠（`mark.ocr.column.<n>`、`cover.ocr.line.<n>`）も `.contentShape` で最小 44×44 pt のヒット領域を確保し、accessibility1 以上では標準の `List` 行でも押せるようにする。

### コントラスト比の計算結果（独自の色を使うすべての組）
基準は、17pt 以下の文字が **4.5:1 以上**、18pt 以上か太字の文字とアイコンや操作部品の枠が **3:1 以上**（WCAG 2.1 / 2.2 相対輝度式）。

| 前景（文字、アイコン、枠）と背景の組 | ライト | ダーク | コントラストを上げる（ライト / ダーク） |
|---|---|---|---|
| 標準 `default`：`color.text.primary`（label）とすべての背景 | システム色（最大 21.00:1） | システム色（最大 21.00:1） | システム色（21.00:1） |
| 標準 `default`：`color.text.secondary` と `color.background.primary`（#FFFFFF / #000000） | **5.23:1**（#6C6C70） | **7.33:1**（#98989F） | **9.12:1**（#48484A） / **12.47:1**（#C7C7CC） |
| 標準 `default`：`color.text.secondary` と Form・List の地（#F2F2F7 / #1C1C1E） | **4.69:1** | **5.94:1** | **7.68:1**（地 #EBEBF0） / **9.20:1**（地 #242426） |
| 標準 `default`：`color.text.secondary` とシート内の行の地（ダーク #2C2C2E） | **5.23:1**（#FFFFFF） | **4.86:1** | **9.12:1**（#FFFFFF） / **7.16:1**（地 #363638） |
| 標準 `default`：`color.action.primary.label` と `color.action.primary.background` | **17.01:1**（#FFFFFF / #1C1C1E） | **18.82:1**（#000000 / #F2F2F7） | **21.00:1**（#FFFFFF / #000000、#000000 / #FFFFFF） |
| 標準 `default`：`color.action.primary.background` と画面の地（主操作の形） | **17.01:1** | **18.82:1** | **21.00:1** |
| 標準 `default`：`color.action.tint`（Link・.bordered の文字）と行の地 | **17.01:1**（#FFFFFF） | **15.25:1**（#1C1C1E）、**12.49:1**（#2C2C2E） | **21.00:1** / **15.49:1**（#242426）、**12.06:1**（#363638） |
| 標準 `default`：`color.state.error` / `color.action.destructive`（systemRed の記号のみ、3:1 基準）と行の地 | **3.57:1**（#FF3B30 / #FFFFFF） | **4.92:1**（#FF453A / #1C1C1E）、**4.02:1**（#2C2C2E） | システム色（3:1 以上） |
| 写真上の読み取り枠：`color.ocr.box.outer`（#000000）と `color.ocr.box.inner`（#FFFFFF）の2重線、および札 `color.ocr.badge.label` と `background` | **21.00:1**（2重線の間。どんな背景輝度に対しても外側か内側のどちらかが必ず **4.58:1 以上**、3:1 基準を満たす）。札は **17.01:1** | **21.00:1**（2重線）。札は **18.82:1** | **21.00:1**（2重線・札とも） |
| よむま＋ `kinari`（生成り）：`color.text.primary`（#1C1B18 / #F2ECE1）と地（#FBF8F1 / #171614） | **16.24:1** | **15.38:1** | **20.67:1**（#000000 / #FFFDF9） / **19.55:1**（#FFFFFF / #0D0C0A） |
| よむま＋ `kinari`（生成り）：`color.text.secondary`（#5C584F / #A69F91）と地 | **6.68:1** | **6.88:1** | **11.16:1**（#3D3A33 / #FFFDF9） / **12.63:1**（#D6CFC2 / #0D0C0A） |
| よむま＋ `kinari`（生成り）：主操作の文字と塗り、および塗りと地 | **16.24:1** | **15.38:1** | **20.67:1** / **19.55:1** |
| よむま＋ `sumi`（墨）：`color.text.primary`（#141413 / #EAE6DF）と地（#F2EFE9 / #121211） | **16.06:1** | **15.07:1** | **19.37:1**（#000000 / #F7F5F0） / **19.98:1**（#FFFFFF / #0A0A09） |
| よむま＋ `sumi`（墨）：`color.text.secondary`（#54524D / #9E9A93）と地 | **6.80:1** | **6.69:1** | **11.07:1**（#383632 / #F7F5F0） / **12.24:1**（#CFCBC2 / #0A0A09） |
| よむま＋ `sumi`（墨）：主操作の文字と塗り、および塗りと地 | **16.06:1** | **15.07:1** | **19.37:1** / **19.98:1** |
| よむま＋ `shu`（朱）：`color.action.primary.label`（#FFFFFF / #171614）と朱の塗り（#9E2A22 / #E07A72） | **7.48:1** | **6.20:1** | **10.48:1**（#FFFFFF / #7A1C15） / **10.58:1**（#000000 / #FF9E96） |
| よむま＋ `shu`（朱）：朱の塗り（`color.action.primary.background` / `tint`）と地（#FBF8F1 / #171614） | **7.05:1** | **6.20:1** | **10.31:1**（#7A1C15 / #FFFDF9） / **9.85:1**（#FF9E96 / #0D0C0A） |

---

## 10. 未解決

- なし（2026-10-19〜2026-10-25 に Takuma が方向性・範囲・端末内書誌 DB・OCR・電子書籍・おすすめ・予約 Live Activity・App Shortcuts・買い切り「よむま＋」をすべて承認・決定済み。`docs/approvals/001-reading-session-G1-decisions.md`、`docs/approvals/001-reading-session-G0.md`）。

## 確かめ（提出前に designer が印を付ける。design-reviewer はこれを信じずに確かめる）
- [x] PRD のすべての AC に対応する画面と操作がある（2節の表に AC-1〜AC-149 の全149件を漏れなく記載）
- [x] どの画面にも7つの状態があり、「なし」には理由がある（5節の表に W-1〜W-5、S-1〜S-10a、部品 N の7状態をすべて記載し、すべての「なし」に括弧で理由を記載）
- [x] 判断の表のすべての行に、R の番号と原則がある（4節の判断 1〜81 のすべての行に R-1〜R-87 と HIG URL / B-1〜B-6 を記載）
- [x] どの画面も仕事は1文、主操作は1つ（3節の表にすべての画面の1文の仕事と1つの主操作を記載）
- [x] 標準部品から外れる所には、元の部品、理由、アクセシビリティの扱いがある（3節の表に記載）
- [x] 色のすべての組にコントラスト比の計算があり、基準を満たす（9節の表と tokens.md にライト・ダーク・コントラストを上げるの3モードすべての計算値を記載し、文字 4.5:1 以上、記号・枠 3:1 以上を満たす）
- [x] 押せる範囲 44×44pt、AX5 の並び替えがある（9節に記載）
- [x] 文言キーと識別子が PRD と一致している（6節と7節に PRD の全識別子・全文言キーを日英で記載）
