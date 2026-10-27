FAIL

## 指摘

1. **[重大]** `design/001-reading-session/screens.md:358, 376, 406, 482` — `screens.md` に外部API通信（国立国会図書館サーチへのオンライン問い合わせ）および「openBD」の記述が残っており、完全オンデバイス（外部通信0件）の仕様および親ファイルと矛盾している
   - **何が問題か**:
     - `screens.md:358`（S-8 フッター）に「本の情報は、端末の中の書誌データから引き、なければ国立国会図書館サーチで補います。」と書かれている（親ファイル `design/001-reading-session.md:745` の `register.footer` は「書誌の検索と文字の読み取りはすべてこの iPhone の中で行い、外部へ送信しません。」）。
     - `screens.md:376`（S-8a）に「端末内の書誌DBからオフラインで即座に引き、なければオンラインのときだけ NDL で補う。」と書かれている。
     - `screens.md:406`（S-8c）に「候補（端末内の書誌データと国立国会図書館サーチから。選ぶとそのまま加えられます）」と書かれている。
     - `screens.md:482`（S-10 `settings.dataSources`）に「書誌（書名、著者、出版社など）は、openBD と国立国会図書館サーチ、文学賞データ…」と書かれており、NDL CC BY 4.0 の3条件と共起データの免責文が欠けている。
   - **根拠**: PRD `AC-103`（あらゆる登録と一行の読み取りの経路で外部への HTTP/HTTPS リクエストが0件）、`AC-93`（`settings.dataSources` の CC BY 4.0 の3条件と共起免責、openBD 不使用）、`AC-2`〜`AC-6`、`design/001-reading-session.md:179, 463, 745, 869`（判断30、判断42）、`R-39`（`https://ndlsearch.ndl.go.jp/file/help/api/specifications/ndlsearch_api_20250226.pdf`）。
   - **直す方向**: `design/001-reading-session/screens.md:358, 376, 406, 482` を親ファイル `design/001-reading-session.md` と揃え、外部通信や openBD への言及をすべて除き、端末内書誌DB（H20 同梱＋ODR）のみの挙動と `register.footer` / `settings.dataSources` の確定文言に統一する。

2. **[重大]** `design/001-reading-session/screens.md:76-88` — W-5（Siri「どこまで読んだ？」の小窓 `SnippetView`）に書名（`羅生門`）と一行（`「下人は、雨やみを待っていた。」`）が表示されており、ロック画面のプライバシー保護要件に違反している
   - **何が問題か**: `screens.md:76-88` の W-5 小窓（`SnippetView`）の図に、`羅生門 · p.61` および `「下人は、雨やみを待っていた。」` が含まれている。一方、親ファイル `design/001-reading-session.md:19, 286, 455, 890`（判断57）および PRD では、ロック画面越しに他人に書名や抜粋が見えないよう、音声・小窓ともに書名と一行を出さず `intent.whereStopped.*` の1文（例：「前回は61ページまででした。続きから読みますか？」）だけを出す仕様になっている。
   - **根拠**: PRD `AC-121`、`AC-123`、`AC-133`（「声の全文と小窓の中身に、一行の文字列と『羅生門』が入らない」）、`design/001-reading-session.md:455, 890`（判断57）、`R-71`、Apple HIG Siri (`https://developer.apple.com/design/human-interface-guidelines/siri`)。
   - **直す方向**: `design/001-reading-session/screens.md:76-88` の W-5 小窓から書名と一行の引用を消し、`intent.whereStopped.page` / `.location` / `.percent` / `.timeOnly` / `.empty` の1文のみを表示する構成に修正する。

3. **[重大]** `design/001-reading-session/screens.md:42-70` — W-3（ライブアクティビティ）で `waiting` 状態にボタンを置き、`reading` 状態から `[ 終える ]`（`liveActivity.end`）ボタンを落としており、PRD と矛盾している
   - **何が問題か**:
     - `screens.md:46`（W-3 ロック画面 `waiting`）に `[ 読み始める ] Button(intent: StartReadingIntent)` があるが、PRD `AC-36` / `AC-40` および親ファイル `design/001-reading-session.md:38, 199` では `waiting` 時はボタンを置かず、ロック画面タップ（`widgetURL`）で S-1 を開く仕様である。
     - `screens.md:51-56`（W-3 ロック画面 `reading`）および `screens.md:62-70`（Dynamic Island Expanded `reading`）に `[ 終える ]`（`liveActivity.end`）ボタンがなく、「（タップで S-2 を開く）」と書かれている。これは PRD `AC-41`・`AC-114`（`reading` のとき押せる要素は `liveActivity.end` の1つ）に反する。
   - **根拠**: PRD `AC-36`、`AC-40`、`AC-41`、`AC-114`、`design/001-reading-session.md:17, 38-39, 199-203, 502`（判断53）、`R-66`、Apple HIG Live Activities (`https://developer.apple.com/design/human-interface-guidelines/live-activities`)。
   - **直す方向**: `design/001-reading-session/screens.md:42-70` を修正し、`waiting` ではボタンなし（全体タップで S-1 を開く）、`reading` ではロック画面と Dynamic Island 展開時の両方に `[ 終える ]`（`accessibilityIdentifier: "liveActivity.end"`、`Button(intent: EndReadingFromActivityIntent)`）を1つ配置する。

4. **[重大]** `design/001-reading-session/screens.md:184, 199, 207, 211, 233, 239` — S-3 / S-3a / S-3b / S-3c の進み具合の単位切り替え `mark.progressUnit` が2択（ページ / パーセント）のままになっており、電子書籍の位置No.（`location`）が欠落している
   - **何が問題か**: `screens.md` の S-3 系画面すべてで `[ ページ (p.) | パーセント (%) ]` の2択 Segmented Picker になっており、Kindle 等の位置No.に対応する `位置`（`location`、範囲 `1〜999999`）がない。
   - **根拠**: PRD `AC-141`（`mark.progressUnit` は `page` / `location` / `percent` の3択）、`AC-143`、`design/001-reading-session.md:194-197, 224-225, 429, 524, 677-686`（判断22）、`R-76`、`R-77`。
   - **直す方向**: `design/001-reading-session/screens.md:184, 199, 207, 211, 233, 239` の `mark.progressUnit` を `[ ページ | 位置 | ％ ]`（`page` / `location` / `percent`）の3択に更新し、`location` 選択時の上限（`1〜999999`、`mark.progress.outOfRange.location`）を明記する。

5. **[重大]** `design/001-reading-session/screens.md:220-239` — S-3c（写真・スクショからの行選び）の下半分に `mark.lineField` / `mark.pageField` / `mark.save` / `mark.retake` がなく、「タップで S-3a へ進む」と記述されており、PRD の画面遷移・要素要件と矛盾している
   - **何が問題か**: `screens.md:220-239` では、S-3c で枠をタップすると S-3a へ遷移する図になっており、S-3c 自体に一行入力欄や保存ボタンがない。しかし PRD `AC-65`〜`AC-68`・`AC-142` および親ファイル `design/001-reading-session.md:45-52, 228-231, 460, 528-536`（判断27）では、S-3c の下半分に `mark.lineField`・`mark.pageField`・`mark.progressUnit`・`mark.save`・`mark.retake` を常時出し、OCRが0件でも S-3c のその場で手入力して保存できる仕様である。
   - **根拠**: PRD `AC-65`、`AC-66`、`AC-67`、`AC-68`、`AC-142`、`design/001-reading-session.md:45-52, 228-231, 460, 528-536`（判断27）、Nielsen #9（エラーの認識・診断・回復）。
   - **直す方向**: `design/001-reading-session/screens.md:220-239` の S-3c 下半分に `mark.lineField`、`mark.pageField`、`mark.progressUnit`（3択）、`mark.save`、`mark.retake` を明記し、S-3c 単体で枠選択・文字修正・0件時手入力・保存が完結する図に修正する。

6. **[重大]** `design/001-reading-session/screens.md` の複数画面（S-1、S-3、S-7a、S-8、S-8b、S-8c、S-9、S-10、S-10a）で `accessibilityIdentifier`・画面構成・文言が PRD および `design/001-reading-session.md` と食い違っている
   - **何が問題か**:
     1. **S-1（`screens.md:107, 122, 132`）**: 本棚を開くボタンが `bookmark.chooseBook`（正しくは `bookmark.openShelf`、PRD `AC-16` / 親 `:510`）、読み込み失敗の再試行が `data.load.retry`（正しくは `store.retry`、PRD `AC-109` / 親 `:512`）になっている。また、今の本0冊かつ名無しの本1冊以上のときの案内 `bookmark.unnamedNotice` と第2ボタン `bookmark.addBook`（PRD `AC-139` / 親 `:511`）が `screens.md:107` から抜けている。
     2. **S-3（`screens.md:176, 180`）**: 撮影ボタンが `mark.camera`（正しくは `mark.photo`、PRD `AC-63` / 親 `:521`）、スクショ選択が `mark.photoPicker`（正しくは `mark.screenshot`、PRD `AC-65, AC-142` / 親 `:522`）になっている。
     3. **S-7a（`screens.md:312`）・S-8b（`screens.md:394, 404`）・S-8c（`screens.md:412`）**: 電子書籍トグルが `book.edit.format` / `manual.format` の Segmented Picker になっているが、PRD `AC-6, AC-140` / 親 `:561, 579` では `Toggle`（`book.edit.isEbook` / `manual.isEbook`）である。また S-8b の保存ボタンが `register.confirm`（正しくは `manual.save`、親 `:581`）になっており、S-8b 上部のインクリメンタル検索欄 `manual.searchField` と候補行 `manual.candidate.<isbn13>`（PRD `AC-6〜AC-8` / 親 `:573-574`）が S-8c に分離されたままになっている。
     4. **S-8（`screens.md:347-357`）**: 登録の入り口が `register.barcode` / `register.cover` / `register.bookshelfPhoto` / `register.search` / `register.manual` / `register.later` になっており、PRD `AC-4, AC-12, AC-137〜AC-139` / 親 `:563-568` で定められた6つ（`register.barcode`、`register.cover`、`register.screenshot`、`register.bookshelf`、`register.manual`、`register.later`）と一致しない。
     5. **S-9（`screens.md:434`）**: `finish.reflection` が `4晩 · 合計 1時間25分（10月14日〜10月17日）`（`.subheadline`）になっており、PRD `AC-127, AC-128` / 親 `:813-814` の定型文テンプレート（`%1$lld晩、合計%2$lld分（%3$@）。いちばん長かったのは%4$@の晩の%5$lld分でした。` 等、`.body`）と異なる。
     6. **S-10（`screens.md:470`）・S-10a（`screens.md:496-501`）**: S-10 に端末内書誌データの状態行 `settings.h20Status` と `settings.h20Retry`（PRD `AC-92` / 親 `:595-596`）がない。また S-10a のテーマ行 ID が `store.appearance.default/kinari/sumi/shu`（正しくは `appearance.row.default/kinari/sumi/shu`、PRD `AC-96` / 親 `:603`）、価格表記が `¥600`（正しくは `¥980`、PRD `AC-99` / 親 `:882`）になっている。
   - **根拠**: PRD `AC-4`、`AC-6`〜`AC-8`、`AC-12`、`AC-16`、`AC-63`、`AC-65`、`AC-92`、`AC-96`、`AC-99`、`AC-109`、`AC-127`、`AC-128`、`AC-137`〜`AC-142`、`docs/org/gates.md:38-42`（G1 通過条件：ファイル間の一貫性と追跡性）。
   - **直す方向**: `design/001-reading-session/screens.md` の該当箇所を親ファイル `design/001-reading-session.md`（セクション2・3・5・6・7）と完全に一致させる。

7. **[要修正]** `design/001-reading-session.md:20, 287, 290, 444, 456` — `ContinueReadingIntent` の呼びかけ代表フレーズが本文中で「続きから読む」となっており、PRD（AC-124、AC-126）およびセクション7-2の「続きを読む」と表記が揺れている
   - **何が問題か**: セクション7-2（`design/001-reading-session.md:891`）の `AppShortcut.phrases` では第1フレーズが「`${applicationName}で続きを読む`」と PRD 通り定義されているが、セクション2（`:20`）、セクション3（`:287, 290`）、セクション4（`:444, 456`）では「Siri『続きから読む』」と書かれている。
   - **根拠**: PRD `AC-124`、`AC-126`（「`<AppName>で続きを読む`」）、`design/001-reading-session.md:891`。
   - **直す方向**: `design/001-reading-session.md:20, 287, 290, 444, 456` の表記を「Siri『続きを読む』（別名『続きから読む』）」のように PRD の代表フレーズ「続きを読む」を主として揃える。

---

## 採点表

| カテゴリ | 点数 | 必須項目（★）の検証結果と根拠 |
|---|---|---|
| **A. 調査と位置づけ** | **2 / 2** | **★1〜★4**: 適合。`307a14a` → `72991d5` で調査が先にコミット。直接競合4件＋隣接3件＋Flighty。`R-1`〜`R-87` すべてに出典 URL と確認日。ターゲット仮説・ブランド5語・差別化 D-1/D-2・方向性2案が明記。 |
| **B. 画面の絞り込みと流れ** | **2 / 2** | **★1〜★3**: 適合。全画面に1文の仕事と主アクション1つ。カード内データ3点以内、タブバー不使用（0個）、最大階層2段。 |
| **C. 視覚の階層とトークン** | **2 / 2** | **★1〜★4**: 適合。4段階・2ウェイト、余白 8pt（補助 4pt）倍数、4テーマの Light/Dark/ハイコントラスト HEX 値、WCAG 2.2 AA/AAA コントラスト比すべて再計算して適合確認済み。 |
| **D. プラットフォームと HIG** | **2 / 2** | **★1〜★4**: 適合。標準部品と独自部品の理由、最小 44×44pt、Dynamic Type AX1〜AX5・VoiceOver・Reduce Motion・Increased Contrast、HIG URL 引用すべて適合。 |
| **E. 状態とエラーの網羅** | **2 / 2** | **★1〜★3**: 適合。全22行×7状態の表に空欄0件、「なし」すべてに理由。ニールセン #5・#9 適合。 |
| **F. マイクロコピー** | **2 / 2** | **★1〜★2**: 適合。日英対訳・Siri フレーズ・Info.plist 権限文言まで全キー網羅、動詞形ボタン・エラー回復・空状態の次の一歩すべて適合。 |
| **G. 一貫性と追跡性** | **0 / 2** | **★1**: **不適合（0点）**。`design/001-reading-session.md` 単体では全149件が追跡されているが、`design/001-reading-session/screens.md` に旧ドラフトの記述（指摘1〜6）が残っている。<br>**★2**: 適合。判断1〜81すべてに `R-1`〜`R-87`・HIG URL・`B-1`〜`B-6` が付与。 |
| **H. 全体の印象** | **1 / 2** | `design/001-reading-session.md` と `tokens.md` は高い密度で体現しているが、`screens.md` の旧仕様残存により1点減点。 |
| **合計** | **13 / 16** | **不合格（FAIL）**：カテゴリ G が 0点（必須項目 ★1 不適合）かつ「重大」な指摘が 6件あるため。 |

---

## 証拠
- 読んだファイル：`design/001-reading-session-research.md`、`design/001-reading-session.md`、`design/001-reading-session/screens.md`、`design/001-reading-session/tokens.md`、`docs/prd/001-reading-session.md`、`.git/logs/HEAD`
- コミット順序検証：`307a14a`（research）→ `72991d5`（spec）を確認
- コントラスト比再計算：全4テーマ（`default` / `kinari` / `sumi` / `shu`）の Light / Dark / ハイコントラスト、およびエラー・OCR オーバーレイ色を相対輝度式で再計算し全項目基準クリアを確認
- 開いた URL：`https://apps.apple.com/jp/app/id6757129946`、`https://itunes.apple.com/rss/customerreviews/id=6757129946/sortBy=mostRecent/json?cc=jp`
- 未検証：なし
