PASS

## 指摘
重大は0件、要修正は0件、提案は5件です。
- `git diff 5f690de...2e26444 -- docs/prd/` で変更された AC（AC-2〜AC-7、AC-9〜AC-12、AC-36、AC-41、AC-63、AC-70、AC-77〜AC-81、AC-83、AC-86、AC-87、AC-92、AC-93、AC-101、AC-103、AC-113、AC-114、AC-115、AC-119、AC-121〜AC-123、AC-130、AC-136）および追加された AC（AC-137〜AC-149）を含む全149件（AC-1〜AC-149）すべてに Given / When / Then / 確かめ方 / 効く機会がそろい、Then に具体的な値（件数、識別子、文言キー、状態名、秒数・ミリ秒数）があり、テストまたは画面確認で合否を1つに決められます。
- 測れない言葉（「適切に」「すばやく」「わかりやすく」など）は0件です。
- 空・エラー・オフライン・権限（カメラ拒否、データの扱い、購入の権利）の AC も、今回広がった範囲（書誌 DB 未取得 `AC-9`、DB 未収録 `AC-10`、候補0件 `AC-5`、機内モード `AC-6`、外部 HTTP 通信0件 `AC-103`、カメラ拒否時のスクショ導線 `AC-12`・`AC-70`・`AC-142`、位置No.・%の境界値エラー `AC-141`、推薦候補0件 `AC-81`、NDL 3条件表示 `AC-93`）まで漏れなくそろっています。
- 前回の G0 狭い判定 r2（`docs/reviews/001-reading-session-G0-intents-verifier-r2.md`）で残っていた要修正1〜4および提案5・7・8・9・12・13 も、このコミットですべて解消されています。

- 提案、`docs/prd/001-reading-session.md:682`、AC-47 の Given の画面一覧に旧仕様の「書名で探す」が残っている、根拠：AC-4（`:345`）で書名検索が「手で入れる」（`register.manual`）の候補補完に統合され、`register.cover`（AC-137）と `register.bookshelf`（AC-138）が加わったため、直す方向：G1 の `test-plan.md` で AC-47 の対象画面を列挙する際、「書名で探す」を除き、表紙・背表紙撮影（`register.cover`）・本棚撮影（`register.bookshelf`）・奥付撮影（`colophon.capture`）を含める（PRD を直す場合は `:682` の括弧内を合わせる）。
- 提案、`docs/prd/001-reading-session.md:236`・`:423`（AC-139、AC-140）、書名未設定（`isTitlePending = true`）の本があるときに別の本を `current` にしようとした場合の案内（`:236`「書名を入れるか奥付・表紙を撮る案内を出して無名の本が `tsundoku` に入らないようにする」）に対応する識別子・文言キーが AC にない、根拠：AC-139・AC-140 の合否自体は Given/When/Then の値で1つに決まるが、`:236` のガードの UI を実装・検証する際に識別子が必要になる、直す方向：G1 で designer が `design/001-reading-session-screens.md` と `design/copy.md` にこの案内の識別子と文言キーを定義する。
- 提案、`docs/prd/001-reading-session.md:262`・`:291`・`:1107`（AC-146）、`:262` で「この本のあとに」の行の識別子を `after.candidate.<ISBN>` としているが、受賞の一覧（`H25`）から出た未所有の本で端末内書誌 DB（`H20`）にない場合は ISBN が空になりうる（AC-83 と同じ）、根拠：`:291` の「一覧の行の識別子は `<名前>.<id か ISBN>` の形にする」、直す方向：G1 の `design/001-reading-session-screens.md` で、ISBN がない受賞一覧由来の候補のサフィックス（受賞行の id か正規化書名など）を決める。
- 提案、`docs/prd/001-reading-session.md:6`・`:114`・`:261`〜`:268`、本文中の AC 番号の参照ずれ2か所（(1) `:114` で「今の本が0冊のときのしおり画面にも候補を出す（AC-146）、本の詳細画面に『この本のあとに』5冊を出す（AC-147）」とあるが、11章の定義はそれぞれ `AC-145` と `AC-146`、(2) `:261`〜`:268` の冒頭ルールで AC-145〜AC-148 の括弧書きが1つずつずれている箇所がある）、根拠：11章の AC 本体の見出しと中身（`:1101` AC-145、`:1107` AC-146、`:1113` AC-147、`:1119` AC-148）および18章（`:1435`）は正しく一致しており合否判定には影響しない、直す方向：次回 PRD に触れる機会があれば11章の見出し番号にそろえる。
- 提案、`docs/prd/001-reading-session.md:1001`・`:1007`・`:1187`・`:1248`・`:1253`・`:1258`・`:1265`、11章末尾の G4 の表の「関わる AC」列と各 AC の「確かめ方」の G4 表記に片方向の記載が7か所ある（`G4-5` の `AC-142`、`G4-10` の `AC-10, AC-113, AC-137, AC-138`、`G4-15` の `AC-149`、`G4-22` の `AC-143`）、根拠：G4 表の側にすべて記載されているため実機確認の漏れは起きない、直す方向：`docs/verification/001-reading-session-test-plan.md` の7章（G4 手順）を更新する際に G4 表（`:1242`〜`:1265`）を正としてひも付ける。

## 前回の指摘の追跡（r2 だけ）
| 前回の指摘（G0-intents-verifier-r2） | 直った / 直っていない | 証拠 |
|---|---|---|
| 要修正1：H32 を (ii) で作ると起動時の見直し要求が区間に入りうる（AC-115、AC-119） | 直った | `docs/prd/001-reading-session.md:310`（H23 に要求の「出どころ」を追加）、`:786`（AC-115）、`:822`（AC-119）で「時刻の区間でなく H23 の出どころで分ける」と明記 |
| 要修正2：「1分未満で終わって記録が残らなかったとき」の見直しを見る AC がない | 直った | `docs/prd/001-reading-session.md:639`〜`:640`（AC-130 に (2) 50秒で終えたときの見直しを追加） |
| 要修正3：「予約はいつも1件」が AC-130 の「0件」と字の上で合わない | 直った | `docs/prd/001-reading-session.md:273` を「まだ始まっていない予約は多くても1件（AC-97）」に修正 |
| 要修正4：G4-22 の「ロック中でオン」が1回だけで聞き取り失敗時に見ないまま合格しうる | 直った | `docs/prd/001-reading-session.md:1265` に「聞き取りに失敗した回は、同じ組み合わせで1回だけ頼み直す」と追加 |
| 提案5・7・8・9・12・13（AC-41、AC-136、G4-21、AC-114、AC-36） | 直った | `:585`（AC-36 `bookmark.start`）、`:614`〜`:616`（AC-41 一行）、`:782`（AC-114 `liveActivity.end.label`）、`:805`〜`:806`（AC-136 04:30）、`:1264`（G4-21 10回上限と何も起きない枝） |

## 証拠
- 対象：`5f690de...2e26444`（変更・追加された AC、全 AC 1〜149 の検証可能性、テストに要るつなぎ口の一覧）
  - [x] `docs/prd/001-reading-session.md`
  - [x] `docs/prd/product.md`
- 観点の表：
  1. **変更・追加された AC の検証可能性一覧**

| AC | 変更区分 | Given / When / Then の具体値 | 確かめ方（つなぎ口） | 合否判定 |
|---|---|---|---|---|
| AC-2 | 変更 | I1 を流し `scan.row.9784101000015` に書名・著者・出版社・レーベル、`current`、外部通信0件 | G3：画面（H1, H13, H20, H21, H26, H29）、G4-10 | 決められる |
| AC-3 | 変更 | I2 + `1920193006001` で `scan.row` は2件、I2 のレーベル候補に「文庫」、触覚2回、`scan.duplicate` 1回、3冊 | G3：画面（H2, H13, H17, H20, H21, H26）、G4-10 | 決められる |
| AC-4 | 変更 | `register.manual` の `manual.title` に「人間失格」→ `search.row` 3件（I4, I5, I6）→ I5 選択で保存 | G3：画面（H1, H13, H20） | 決められる |
| AC-5 | 変更 | H20 で0件の書名 → `search.row` 0個・`search.noResults` 1つ → そのまま `manual.save` で1冊保存 | G3：画面（H1, H13, H20） | 決められる |
| AC-6 | 変更 | H8（通信全失敗）でも H20 の I1 で `scan.row.9784101000015` に「こころ」、alert 0個、H29 0件 | G3：画面（H1, H8, H13, H20, H21, H26, H29）、G4-4 | 決められる |
| AC-7 | 変更 | 候補を選ばずに前後空白つき書名を保存、空白除去、`tsundoku` | G3：画面（H2, H13） | 決められる |
| AC-9 | 変更 | H20 が `notDownloaded` → `scan.dbNotReady`、`scan.row.captureCover`、`scan.row.editTitle` 各1、書名入力で保存、H29 0件 | G3：画面（H1, H13, H20, H21, H26, H29） | 決められる |
| AC-10 | 変更 | H20 にない I4 → `scan.notFound`、`scan.row.captureCover`、`scan.row.editTitle` 各1、書名入力で保存、H29 0件 | G3：画面（H1, H13, H20, H21, H26, H29） | 決められる |
| AC-11 | 変更 | H20 にない `9784003101018` + `1920193006001` → 出版社候補「岩波書店」、レーベル候補「文庫」 | G3：画面（H1, H13, H20, H21, H26） | 決められる |
| AC-12 | 変更 | カメラ拒否時に `register.barcode` / `register.cover` → `camera.denied`、`camera.openSettings`、`register.screenshot`、`register.manual` 各1 | G3：画面（H1, H26）、G4-5 | 決められる |
| AC-63 | 変更 | しおり画面に `mark.photo`、`mark.screenshot`、`mark.manual`、`mark.pageOnly`、`mark.later` の5つが isEnabled=真 | G3：画面（H2, H4, H5） | 決められる |
| AC-70 | 変更 | カメラ拒否時に `mark.photo` → `camera.denied`、`camera.openSettings`、`mark.screenshot`、`mark.manual`、`mark.pageOnly` 各1 | G3：画面（H13, H26）、G4-5 | 決められる |
| AC-77 | 変更 | `bookmark.finish` で `finish.colophon` 5行と `colophon.capture` 1つ | G3：画面（H2, H13, H25） | 決められる |
| AC-78〜83 | 変更 | 積読＋H20＋H25 からの候補最大3冊の並び・理由・0件時・選択・積読追加 | G3：画面（H2, H13, H20, H22, H25） | 決められる |
| AC-86 | 変更 | 今の本がある毎晩の道で `next.candidate` と `bookmark.noCurrent.next` がともに0個 | G3：画面（H2, H4, H5） | 決められる |
| AC-87 | 変更 | H20 からシリーズの次の巻（U1）と同じ著者の本（U2）を出し、`next.addToShelf` で H20 の書誌一式つきで `tsundoku` に追加 | G3：画面（H2, H13, H20, H25） | 決められる |
| AC-92 | 変更 | H20 の NDL 形式の `dc:creator` / `author` から役割語・生没年・カンマ・2人目以降を整形 | G3：画面（H1, H13, H20, H21, H26） | 決められる |
| AC-93 | 変更 | `settings.dataSources` に NDL 3条件・版・「読んだ人」無関係注記、`settings.dataSources.license` で CC BY 4.0 URL | G3：画面（H2, H31） | 決められる |
| AC-101 | 変更 | 500冊（`current` 1冊・記録1,000件、`tsundoku` 350冊、`finished` 149冊、計5,000件）で5回平均1.0秒以内 | G3：画面（H2, H10）、G4-15 | 決められる |
| AC-103 | 変更 | 登録・しおり・読書・読了カード共有を通して外部 HTTP 通信要求（H29）が0件 | G3：画面（H1, H5, H20, H21, H24, H26, H29）、G4-20 | 決められる |
| AC-113 | 変更 | `colophon.capture`（H19）で著者・出版社・レーベル・出版年・ISBN を抽出して `colophon.save`、画像ファイル0個（H27） | G3：画面（H2, H13, H19, H26, H27） | 決められる |
| AC-137 | 追加 | `register.cover`（撮影）と `register.screenshot`（PhotosPicker）で `cover.ocr.line.2`・`3` を押して書名・著者を保存、画像0個 | G3：画面（H1, H13, H19, H26, H27） | 決められる |
| AC-138 | 追加 | `register.bookshelf` で3行選択 → `bookshelf.addSelected` で3冊 `tsundoku` 追加、H20 で1件一致の「羅生門」は書誌自動補完、画像0個 | G3：画面（H2, H13, H19, H20, H26, H27） | 決められる |
| AC-139 | 追加 | `register.later` で `isTitlePending = true` のまま即 `reading`、`widget.currentBookAsTitle` 表示、終えると `bookmark.setBookTitle` 表示、2冊目の `register.later` は0個 | G3：画面（H1, H4, H5, H6, H9, H13, H22, H23） | 決められる |
| AC-140 | 追加 | `bookmark.setBookTitle` からバーコード I1 で書名・書誌を保存、冊数は1冊のまま `isTitlePending = false`、記録とページ維持 | G3：画面（H2, H13, H20, H21, H22, H26） | 決められる |
| AC-141 | 追加 | `isEbook = true` で `mark.progressUnit`（`location` / `percent`）の保存・結果表示・ウィジェット表示・境界値（`location` 0/1000000、`percent` -1/101/0/100） | G3：画面・ウィジェット（H2, H4, H5, H13, H22） | 決められる |
| AC-142 | 追加 | カメラ拒否でも `mark.screenshot`（PhotosPicker）で alert 0個、`mark.ocr.column.4` 選択、保存後画像0個 | G3：画面（H2, H13, H19, H26, H27） | 決められる |
| AC-143 | 追加 | `location` 1450 / `percent` 52 のとき「どこまで読んだ？」が `intent.whereStopped.location` / `percent` で答え、一行と書名を含まない | G3：画面（H2, H13, H32） | 決められる |
| AC-144 | 追加 | `isEbook = true` のしおり画面に `bookmark.flipHint.ebook`、読書中画面に `reading.ebookNote`、`liveActivity.end` で10分記録 | G3：画面（H2, H4, H5, H13, H23, H32） | 決められる |
| AC-145 | 追加 | 今の本0冊・積読4冊でしおり画面に `bookmark.noCurrent.next` 3つ（P, R, S）、`bookmark.noCurrent.choose` で P が `current` | G3：画面（H2, H13） | 決められる |
| AC-146 | 追加 | 読了本詳細画面の `after.header` の下に `after.candidate` 5つ（上限5冊）、`after.addToShelf` で書誌つき `tsundoku` 追加・`after.added` に変化 | G3：画面（H2, H13, H20, H25） | 決められる |
| AC-147 | 追加 | `sameAward`（`chosen=3, skipped=0`）と `sameAuthor`（`chosen=0, skipped=3`）の重みで候補順が N1 → U1 に入れ替わる | G3：画面（H2, H13, H20, H25） | 決められる |
| AC-148 | 追加 | 共起テーブルで NDC「913.6」かつ `count = 12` の I2 だけ `rec.reason.readers` で出て、`count = 9`（I3）と NDC「336」（I4）は0個、人数表記なし | G3：画面（H2, H20） | 決められる |
| AC-149 | 追加 | Release 構成でバーコード読み取り（`scan.row` 表示まで）と書名入力（`search.row` 表示まで）が各5回平均0.3秒（300ms）以内 | G3：画面（H10, H20, H21）、G4-10・G4-15 | 決められる |

  2. **テストに要るつなぎ口（フック）の追加・変更点**

| つなぎ口 | 変更内容（旧版からの差分） | 使う主な AC |
|---|---|---|
| H2（初期データの投入） | 本ごとの `isEbook`（真偽）、`isTitlePending`（真偽）、進み具合の単位 `progressUnit`（`page` / `location` / `percent`）と値、シリーズ名・巻数、NDC、および推薦の理由分類（`readers` / `nextVolume` / `sameAuthor` / `sameAward` / `sameLabel`）ごとの `chosen` / `skipped` カウントを投入できるように拡張。また AC-101 用の500冊・5,000件プリセットの内訳（`current` 1冊1,000件、`tsundoku` 350冊、`finished` 149冊）を定義 | AC-101, AC-139〜148 |
| H10（os_signpost 区間計測） | 端末内の書誌 DB 検索の2区間（(1) バーコード注入から `scan.row` 表示まで、(2) `manual.title` 3字以上入力から `search.row` 表示まで）を追加 | AC-149 |
| H13（保存状態の読み出し） | 本ごとの `isTitlePending`、`isEbook`、`progressUnit`、進み具合の値、および端末内の推薦理由ごとの `chosen` / `skipped` カウントを外から読めるように拡張 | AC-139〜141, AC-145〜147 |
| H19（写真・スクショ OCR 注入） | ページの縦書き列に加え、(a) 表紙・背表紙の認識行リスト（`cover.ocr.line.<n>` 用）、(b) 本棚・積読写真の背表紙行リスト（`bookshelf` 用）、(c) 奥付の認識行リスト（書名・著者・出版年・出版社・レーベル・ISBN 抽出用）を注入でき、カメラ撮影だけでなく `PhotosPicker`（`.screenshots` / 写真選択）の操作も本物のピッカーなしで進められるように拡張 | AC-113, AC-137, AC-138, AC-142 |
| H20（端末内書誌 DB・共起表の差し替え） | 旧「外部書誌 API スタブ」から「端末内の書誌 SQLite DB（Background Assets）および共起テーブルの差し替え」に変更。(a) テスト用の書誌レコード（ISBN、書名、著者、NDL 生データの `dc:creator` / `author`、出版社、レーベル、出版年、シリーズ名・巻数、NDC）、(b) Background Assets 未取得状態 `notDownloaded`、(c) 共起テーブルの行（`fromISBN`、`toISBN`、`count`、`ndc`）を注入できるようにする | AC-2〜6, AC-9〜11, AC-78〜81, AC-87, AC-92, AC-103, AC-138, AC-140, AC-146〜149 |
| H21（バーコード読み取り注入） | ISBN（978/979）に加え、2段目の日本図書コード（`192` で始まる13桁の Cコード）を同じ本のペアまたは連続データとして流せることを明記 | AC-3, AC-11, AC-149 |
| H22（ウィジェットの中身の読み出し） | 進み具合の表示文字列として `p.61` だけでなく電子書籍の `位置1450`・`52%`、および書名未設定時の `今の本`（`widget.currentBookAsTitle`）を読めるようにする | AC-139〜141 |
| H23（Live Activity 記録・差し替え） | 各要求（予約・取り消し・すぐ始める・更新・終わり）に要求の「出どころ」（起動／復帰時の見直し、インテント、画面操作）と `liveActivity.end` の読み上げラベルを記録できるように拡張 | AC-114, AC-115, AC-119, AC-130, AC-136, AC-139, AC-144 |
| H27（画像ファイル残存・書き込み検査） | しおり撮影（`mark.photo`）だけでなく、スクリーンショット選択（`mark.screenshot`、`register.screenshot`）、表紙撮影（`register.cover`）、本棚撮影（`register.bookshelf`）、奥付撮影（`colophon.capture`）のすべてで保存領域・App Group の画像ファイル数0個と写真ライブラリ書き込み0回を検証できるようにする | AC-69, AC-113, AC-137, AC-138, AC-142 |
| H29（外部 HTTP 通信の記録） | 旧「書誌 API 以外の通信が0件」から「アプリが出したすべての外部 HTTP 通信要求が0件（ホスト問わず0件）」の検証用に役割を更新 | AC-2, AC-6, AC-9, AC-10, AC-103 |
| H31（開いた外部 URL の記録） | プライバシーポリシー URL に加え、設定の「データの出典」から開く CC BY 4.0 ライセンス URL（`https://creativecommons.org/licenses/by/4.0/` で始まる URL）を記録 | AC-88, AC-93 |

- 読んだファイル：
  - `.claude/agents/verifier.md`
  - `.claude/skills/craft-verifier/SKILL.md`
  - `docs/org/gates.md`
  - `docs/templates/review-report.md`
  - `docs/approvals/001-reading-session-G1-decisions.md`
  - `docs/prd/product.md`
  - `docs/prd/001-reading-session.md`
  - `docs/reviews/001-reading-session-G0-intents-verifier-r2.md`
- 実行したコマンドと結果：
  - `git diff 5f690de...2e26444 -- docs/prd/`（終了コード 0：変更差分の全行を確認）
  - `python3` による AC-1〜AC-149 の連番・重複・必須項目（Given / When / Then / 確かめ方 / 効く機会）検査（終了コード 0：全149件、欠番0、重複0、項目欠落0）
  - `grep -nE '適切|すばやく|わかりやすく|スムーズ|自然|きれい|十分|なるべく|できるだけ|簡単|快適|直感的|適宜' docs/prd/001-reading-session.md docs/prd/product.md`（終了コード 0：該当0件）
  - `python3` による G4 表と各 AC の双方向整合性・旧識別子残存・H1〜H32 参照検査（終了コード 0）
- 開いた URL と確認した日付：なし（G0 の verifier 判定のためローカルファイルのみ）
- 未検証：なし
