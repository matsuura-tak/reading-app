# デザイントークン：001-reading-session（よむま）

- 対象：docs/prd/001-reading-session.md（AC-1〜AC-149 の全範囲）、design/001-reading-session.md
- 方向性：案A「白い紙と墨」（調査の 7。2026-10-19 に Takuma 承認済み。2026-10-20〜10-25 の包括承認により有料の見た目「よむま＋」の3種（生成り・墨・朱）と写真・スクリーンショットの読み取り枠を含む全範囲を規定）
- ダークの値を先に決め、ライトを対にした（主に夜、暗い部屋で使うため。調査の 2、8）。
- コードに生の色の値、フォントの大きさ、余白の数字を書かない。この表の名前を使う。

## 1. 色（意味の名前）

色相は標準の見た目（`default`）では白、黒、灰だけで、意味のあるとき（エラーの記号、消す操作の記号、Toggle のオン）だけシステムの色相を使う（B-5）。有料の見た目「よむま＋」（買い切り、商品 ID `jp.yomuma.plus`）では、紙と墨の延長として「生成り（`kinari`）」「墨（`sumi`）」「朱（`shu`）」の3種を選べる（AC-104〜AC-111）。
2つ目の文字の色（`color.text.secondary`）は、システムの `secondaryLabel` を使わず独自の値にする。`secondaryLabel`（ライトは #3C3C43 の不透明度 60% で、白の上で #8A8A8E）は白（#FFFFFF）との比が約 3.44:1 で、17pt 以下の文字の基準 4.5:1 に届かないため（R-24）。

### 1-1 標準の見た目（`default`）と共通の意味トークン

| トークン名 | 役割と使う場所 | ライト | ダーク | コントラストを上げる（ライト / ダーク） | 背景との比（ライト / ダーク / コントラストを上げる） |
|---|---|---|---|---|---|
| `color.background.primary` | 画面の地（S-1、S-2、S-3、S-4、S-5、S-9） | systemBackground（#FFFFFF） | systemBackground（#000000） | システム色（#FFFFFF / #000000） | ー |
| `color.background.grouped` | 一覧と入力の画面の地（S-3a、S-3b、S-3c、S-6、S-7、S-7a、S-7b、S-7c、S-8、S-8a〜S-8d、S-10、S-10a） | systemGroupedBackground（#F2F2F7） | systemGroupedBackground（#000000） | システム色 | ー |
| `color.background.groupedRow` | List と Form の行・節の地 | secondarySystemGroupedBackground（#FFFFFF） | secondarySystemGroupedBackground（#1C1C1E。シートの中は #2C2C2E） | システム色（ライト #FFFFFF、ダーク #242426 / シートの中 #363638。iOS 26/27 実測） | ー |
| `color.text.primary` | 一行、書名、見出し、本文、奥付の値 | label（#000000） | label（#FFFFFF） | システム色（#000000 / #FFFFFF） | システム色（最大 21.00:1） |
| `color.text.secondary` | 著者、ページ、奥付の項目名、理由の1行、説明の文、節の見出しと説明、外へ開くリンクの末尾の記号、検索欄の虫眼鏡と消すボタン | #6C6C70 | #98989F | #48484A / #C7C7CC | `background.primary` と 5.23:1 / 7.33:1 / 9.12:1・12.47:1。Form の地（#F2F2F7 / #1C1C1E）と 4.69:1 / 5.94:1 / 7.68:1（地 #EBEBF0）・9.20:1（地 #242426）。シートの行の地（ダーク #2C2C2E）と 4.86:1 / 7.16:1（地 #363638）。どれも 4.5:1 以上 |
| `color.action.primary.background` | 主操作のボタンの塗り（S-1、S-2、S-3、S-3c、S-4、S-5、S-7、S-8a、S-8b、S-8d、S-10a の下端または購入シートの主操作） | #1C1C1E | #F2F2F7 | #000000 / #FFFFFF | `background.primary` と 17.01:1 / 18.82:1 / 21.00:1（3:1 以上） |
| `color.action.primary.label` | 主操作のボタンの文字 | #FFFFFF | #000000 | #FFFFFF / #000000 | `action.primary.background` と 17.01:1 / 18.82:1 / 21.00:1（4.5:1 以上） |
| `color.action.tint` | アプリの AccentColor（.bordered の文字と薄い塗り、Link の文字、選んだ行のチェック、ツールバーの記号）。枠のない文字のボタンには使わない | #1C1C1E | #F2F2F7 | #000000 / #FFFFFF | `background.primary` と 17.01:1 / 18.82:1 / 21.00:1。行の地（ダーク #1C1C1E）と 15.25:1、シートの行（#2C2C2E）と 12.49:1 |
| `color.action.destructive` | 消す操作（`book.delete`、`record.delete`）の記号 trash の色。文字は `color.text.primary` にする（systemRed は白の上で 3.57:1 で、.body の文字の 4.5:1 に届かないため。記号は 3:1 でよい。決定 58） | systemRed（#FF3B30） | systemRed（#FF453A） | システム色（systemRed の高コントラスト値） | 行の地と 3.57:1 / 4.92:1（シートの行 #2C2C2E と 4.02:1）で、記号の 3:1 以上 |
| `color.state.error` | エラーの記号（exclamationmark.circle）だけ。エラーの文の文字は `color.text.primary` にする（決定 44） | systemRed（#FF3B30） | systemRed（#FF453A） | システム色 | 同上（記号の 3:1 以上） |
| `color.state.on` | Toggle のオンの塗り（システムの既定のまま。`color.action.tint` を当てない。決定 48） | systemGreen | systemGreen | システム色 | システム色 |
| `color.separator` | 奥付の上下の罫線、区切り線 | separator | separator | システム色 | システム色 |
| `color.ocr.box.outer` | 写真・スクリーンショット上の読み取り枠（`mark.ocr.column.<n>`、`cover.ocr.line.<n>`、`bookshelf.row.<n>`）の外側の線（2pt） | #000000 | #000000 | #000000 / #000000 | 内側の白線（#FFFFFF）と 21.00:1。明るい紙の上で 3:1 以上 |
| `color.ocr.box.inner` | 写真・スクリーンショット上の読み取り枠の内側の線（2pt。選んだ枠は 3pt） | #FFFFFF | #FFFFFF | #FFFFFF / #FFFFFF | 外側の黒線（#000000）と 21.00:1。暗い表紙や背景の上で 3:1 以上 |
| `color.ocr.badge.background` | 読み取り枠の番号・役割札（「1」「書名」「著者」）の塗り | #1C1C1E | #F2F2F7 | #000000 / #FFFFFF | 外枠の白または黒と 17.01:1 以上 |
| `color.ocr.badge.label` | 読み取り枠の番号・役割札の文字 | #FFFFFF | #000000 | #FFFFFF / #000000 | `color.ocr.badge.background` と 17.01:1 / 18.82:1 / 21.00:1（4.5:1 以上） |

### 1-2 有料の見た目「よむま＋」（`appearanceID`：`kinari`、`sumi`、`shu`）

選んだ見た目は、しおりの画面（S-1）、読書中の画面（S-2）、しおりを挟む画面（S-3）、結果の画面（S-4）、読み終えた画面（S-9）、ウィジェット（W-1、W-2 の `systemSmall`）、読み終えのカード画像（`finish.card.share`）に反映される（AC-105、AC-106）。ロック画面の `accessoryRectangular`（W-1）と Live Activity（W-3）のロック画面表示は OS の vibrant 描画に従い、小のウィジェット（W-2）の暗い StandBy は OS の赤の単色描画に従う。

| 見た目の ID と名前 | トークン名 | ライト | ダーク | コントラストを上げる（ライト / ダーク） | 背景との比（ライト / ダーク / コントラストを上げる） |
|---|---|---|---|---|---|
| `kinari`（生成り：書籍用紙の温かみのある紙色と墨字） | `color.background.primary` | #FBF8F1 | #171614 | #FFFDF9 / #0D0C0A | ー |
| `kinari` | `color.text.primary` | #1C1B18 | #F2ECE1 | #000000 / #FFFFFF | 16.24:1 / 15.38:1 / 20.67:1・19.55:1（4.5:1 以上） |
| `kinari` | `color.text.secondary` | #5C584F | #A69F91 | #3D3A33 / #D6CFC2 | 6.68:1 / 6.88:1 / 11.16:1・12.63:1（4.5:1 以上） |
| `kinari` | `color.action.primary.background` / `tint` | #1C1B18 | #F2ECE1 | #000000 / #FFFFFF | 16.24:1 / 15.38:1 / 20.67:1・19.55:1（3:1 以上） |
| `kinari` | `color.action.primary.label` | #FBF8F1 | #171614 | #FFFDF9 / #0D0C0A | 16.24:1 / 15.38:1 / 20.67:1・19.55:1（4.5:1 以上） |
| `sumi`（墨：落ち着いた鼠・墨の地と和紙の文字） | `color.background.primary` | #F2EFE9 | #121211 | #F7F5F0 / #0A0A09 | ー |
| `sumi` | `color.text.primary` | #141413 | #EAE6DF | #000000 / #FFFFFF | 16.06:1 / 15.07:1 / 19.37:1・19.98:1（4.5:1 以上） |
| `sumi` | `color.text.secondary` | #54524D | #9E9A93 | #383632 / #CFCBC2 | 6.80:1 / 6.69:1 / 11.07:1・12.24:1（4.5:1 以上） |
| `sumi` | `color.action.primary.background` / `tint` | #141413 | #EAE6DF | #000000 / #FFFFFF | 16.06:1 / 15.07:1 / 19.37:1・19.98:1（3:1 以上） |
| `sumi` | `color.action.primary.label` | #F2EFE9 | #121211 | #F7F5F0 / #0A0A09 | 16.06:1 / 15.07:1 / 19.37:1・19.98:1（4.5:1 以上） |
| `shu`（朱：生成り・墨の地に、主操作とノンブルの印だけ朱墨） | `color.background.primary` | #FBF8F1 | #171614 | #FFFDF9 / #0D0C0A | ー |
| `shu` | `color.text.primary` | #1C1B18 | #F2ECE1 | #000000 / #FFFFFF | 16.24:1 / 15.38:1 / 20.67:1・19.55:1（4.5:1 以上） |
| `shu` | `color.text.secondary` | #5C584F | #A69F91 | #3D3A33 / #D6CFC2 | 6.68:1 / 6.88:1 / 11.16:1・12.63:1（4.5:1 以上） |
| `shu` | `color.action.primary.background` / `tint` | #9E2A22 | #E07A72 | #7A1C15 / #FF9E96 | 地と 7.05:1 / 6.20:1 / 10.31:1・9.85:1（3:1・4.5:1 以上） |
| `shu` | `color.action.primary.label` | #FFFFFF | #171614 | #FFFFFF / #000000 | 主操作の塗りと 7.48:1 / 6.20:1 / 10.48:1・10.58:1（4.5:1 以上） |

注意：
- シートの中の入れ子の地（`tertiarySystemGroupedBackground`、ダーク #3A3A3C）には `color.text.secondary` を置かない（#98989F と #3A3A3C は 3.96:1 で 4.5:1 に届かないため）。この仕様では入れ子の行を使わない。
- ウィジェット（W-1）と Live Activity（W-3）のロック画面表示は、システムが vibrant の白と灰で描く。中では色を指定せず、主の文字を `.primary`、ページや補足を `.secondary` にする（R-19）。

## 2. 文字（タイポグラフィ）

本文と操作はすべてシステムの書体（SF Pro / ヒラギノ角ゴ）と Dynamic Type の text style を使う。
独自のフォントを使うのは「本から写した一行」と「読み終えのカードの書名」だけで、iOS に入ったヒラギノ明朝 ProN（`HiraMinProN-W3`、`HiraMinProN-W6`）を使う（外からフォントを入れない。R-22、R-30）。Ultralight、Thin、Light の太さは使わない（R-24）。

| トークン名 | 書体と太さ | 既定の大きさ（Large） | Dynamic Type | 行間・字間・組み | 使う場所 |
|---|---|---|---|---|---|
| `type.book.line` | `HiraMinProN-W3`（コントラストを上げる設定のときは `W6`） | 28pt | `.title` に合わせて拡大縮小（`UIFontMetrics(forTextStyle: .title)`）。accessibility1 以上では横書きに切り替える | 縦書きの列の間は字の大きさの 0.25 倍（28pt で 7pt）。1字ごとの縦の間は 0pt（全角の字の高さのまま）。横書きのときは行間 8pt | S-1 の続きの一行、読み終えのカード（`finish.card.share`）の書名 |
| `type.book.line.widget.rectangular` | `HiraMinProN-W6`（ロック画面の vibrant で細い横画が消えないよう W6。決定 7） | 17pt（172×76 pt の枠。1列5字×5列＝25字）、15pt（153×68 pt の枠。1列5字×5列＝25字）。禁則の送りが6字以上（7列）のときだけ 14pt / 13pt に下げる（ADR 0003 の手順 7） | 固定（ウィジェットの枠は広がらないため。決定 8） | 列の間は字の大きさの 0.25 倍（17pt で 4.25pt、15pt で 3.75pt）。枠の右端から左へ組む | W-1、S-5 の見本、S-10a の見本 |
| `type.book.line.widget.small` | `HiraMinProN-W6` | 20pt（170×170 pt の枠。1列6字×5列）、19pt（148×148 pt の枠。1列6字×5列）。148pt で送りが増えて6列になるときは 16pt | 固定 | 列の間は字の大きさの 0.25 倍（20pt で 5pt、19pt で 4.75pt） | W-2 |
| `type.book.line.liveActivity` | `HiraMinProN-W6` | 16pt | `.subheadline` に合わせて拡大縮小（上限 `.xxxLarge`） | 横書き（Live Activity の高さに収めるため） | W-3（予定の時刻の待つ状態の一行） |
| `type.screen.title` | システム `.largeTitle` Regular | 34pt | 追従 | システムの既定 | S-9 の見出し「読み終えました」 |
| `type.prompt.title` | システム `.title2` Bold | 22pt | 追従 | システムの既定 | S-2 の書名、S-3 の問い、S-5 の見出し、S-10a の購入シートの題 |
| `type.result.value` | システム `.title` Regular、`monospacedDigit()` | 28pt | 追従 | システムの既定 | S-4 の `result.summary`（「p.43 → p.61」「位置1200 → 位置1450」「34% → 52%」「18分」） |
| `type.book.title` | システム `.headline` Semibold | 17pt | 追従 | システムの既定 | S-1 の書名、S-4 の書名、S-9・S-1（noCurrent）・S-7（after）の候補の書名、W-1・W-2 で一行がないときの書名（固定 14pt Semibold）、W-3 の書名 |
| `type.action.primary` | システム `.headline` Semibold | 17pt | 追従 | システムの既定 | 主操作のボタンの文字 |
| `type.body` | システム `.body` Regular | 17pt | 追従 | システムの既定 | List と Form の行、奥付の値、入力欄、エラーと知らせの文、S-2 の始めた時刻、S-9 のふりかえりの1行（`finish.reflection`） |
| `type.subheadline` | システム `.subheadline` Regular（ページの数字は `monospacedDigit()`） | 15pt | 追従 | システムの既定 | S-1 の著者とページ、S-1 の2つの .bordered ボタン、奥付の項目名、次の1冊・この本のあとにの理由、一覧の補足、S-2 の数え続ける1行と電子書籍の案内（`reading.ebookNote`）、S-4 の「記録しました。」 |
| `type.footnote` | システム `.footnote` Regular | 13pt | 追従 | システムの既定 | S-1 の伏せる案内（`bookmark.flipHint`、`bookmark.flipHint.ebook`）、S-3 の「しおりは前のまま残ります。」、Form の節の説明、S-8 の説明、S-9 の戻し方の1行、S-10 の書誌の出どころの本文 |
| `type.widget.page` | システム `.caption2` Semibold、`monospacedDigit()` | 12pt（W-1）、13pt（W-2） | 固定 | システムの既定 | W-1、W-2 の「p.61」「位置1450」「52%」と「しおり」 |

### 縦書きの字の置き換えと回転（`type.book.line`、`type.book.line.widget.*`）
- 描画のときだけ置き換える。保存する文字列と VoiceOver のラベルは元のまま（AC-28、AC-99）。
- 置き換える前に、半角の英数字と半角の記号（U+0021〜U+007E）と半角の空白（U+0020）を、対応する全角（U+FF01〜U+FF5E、U+3000）に直す（1列の幅をそろえるため。決定 6）。
- 縦書き用の字形に置き換える字（ヒラギノ明朝 ProN に字形があるもの）：
  | 元の字 | 縦書き用の字 |
  |---|---|
  | `、`（U+3001） | `︑`（U+FE11） |
  | `。`（U+3002） | `︒`（U+FE12） |
  | `「`（U+300C） | `﹁`（U+FE41） |
  | `」`（U+300D） | `﹂`（U+FE42） |
  | `『`（U+300E） | `﹃`（U+FE43） |
  | `』`（U+300F） | `﹄`（U+FE44） |
  | `（`（U+FF08） | `︵`（U+FE35） |
  | `）`（U+FF09） | `︶`（U+FE36） |
  | `〔`（U+3014） | `︹`（U+FE39） |
  | `〕`（U+3015） | `︺`（U+FE3A） |
  | `【`（U+3010） | `︻`（U+FE3B） |
  | `】`（U+3011） | `︼`（U+FE3C） |
  | `〈`（U+3008） | `︿`（U+FE3F） |
  | `〉`（U+3009） | `﹀`（U+FE40） |
  | `《`（U+300A） | `︽`（U+FE3D） |
  | `》`（U+300B） | `︾`（U+FE3E） |
  | `［`（U+FF3B） | `﹇`（U+FE47） |
  | `］`（U+FF3D） | `﹈`（U+FE48） |
  | `…`（U+2026） | `︙`（U+FE19） |
  | `‥`（U+2025） | `︰`（U+FE30） |
- 90度時計回りに回して描く字（Unicode UAX #50 の向きが R の字と、Tr のうち上の表にない字。決定 63）：`ー`（U+30FC）、`―`（U+2015）、`—`（U+2014）、`–`（U+2013）、`‐`（U+2010）、`〜`（U+301C）、`～`（U+FF5E）、`゠`（U+30A0）、`：`（U+FF1A）、`；`（U+FF1B）、`－`（U+FF0D）、`＝`（U+FF1D）、`＜`（U+FF1C）、`＞`（U+FF1E）、`｛`（U+FF5B）、`｝`（U+FF5D）、`｜`（U+FF5C）、`＿`（U+FF3F）。
- フォントの縦書き用の字形の位置（右上）へずらして描く字（UAX #50 の向きが Tu で、回さない字。決定 63、ADR 0003）：小さい仮名（`ぁぃぅぇぉっゃゅょゎゕゖァィゥェォッャュョヮヵヶ`）と、全角のカンマ・ピリオド（`，` U+FF0C、`．` U+FF0E）。
- 上のどれでもない全角の字（かな、漢字、全角の英数字、全角の `！` `？` `・` `／` `％` `＆` `＃` `＊` `＋` `＠` など）は、立てたまま描く。
- 行頭の禁則（列の先頭に置かない字。前の列の最後の字を次の列の先頭に送る。決定 62）：
  - 終わり括弧：`」` `』` `）` `〉` `》` `】` `］` `〕` `｝`（対応する縦書き用の字 U+FE42、FE44、FE36、FE40、FE3E、FE3C、FE48、FE3A を含む）
  - ハイフン・長音：`ー` `‐` `゠` `–` `—` `―` `〜` `～` `－`
  - 区切り約物・中点・句読点：`！` `？` `・` `：` `；` `。` `．` `、` `，`（対応する U+FE11、FE12 を含む）
  - 繰返し記号：`々` `ゝ` `ゞ` `ヽ` `ヾ`
  - 小さい仮名：`ぁ` `ぃ` `ぅ` `ぇ` `ぉ` `っ` `ゃ` `ゅ` `ょ` `ゎ` `ゕ` `ゖ` `ァ` `ィ` `ゥ` `ェ` `ォ` `ッ` `ャ` `ュ` `ョ` `ヮ` `ヵ` `ヶ`
- 日本語の字（ひらがな、カタカナ、漢字）が1字もない一行は、横書きにする（AC-30）。

## 3. 余白（8pt グリッドと 4pt の補助）

使う値はこの6つだけ。

| トークン名 | 値 | 使う場所 |
|---|---|---|
| `space.4` | 4pt | 書名と著者の間、候補の書名と著者の間、欄と誤りの文の間、W-1 のページの帯と列の間、W-2 の列の場所とページの行の間 |
| `space.8` | 8pt | 説明の文とボタンの間、奥付の行の間、知らせの帯の中の間 |
| `space.12` | 12pt | 並んだボタンの間（S-1 の2つの .bordered、S-3 の道のボタンの間）、奥付の名前と値の間、候補の行の中の間 |
| `space.16` | 16pt | 画面の左右の余白、下端の主操作と safe area の下端の間、主操作のボタンの上下の内側の余白、W-2 の四方の内側の余白（システムの既定の余白は `contentMarginsDisabled` で切る。W-1 の四方は 0pt） |
| `space.24` | 24pt | まとまり（節）の間（S-1 のページとボタンの間、S-7 と S-9 の奥付と次の節の間） |
| `space.32` | 32pt | S-1 の書名・著者のまとまりと、縦書きの一行の間 |

- 縦書きの列の間は余白のトークンではなく、字の大きさの 0.25 倍（`type.book.line.columnGap`。2 の表）。

## 4. 角丸

| トークン名 | 値 | 使う場所 |
|---|---|---|
| `radius.control` | 12pt | 主操作と .bordered のボタン（ButtonBorderShape `.roundedRectangle(radius: 12)`）、知らせの帯 |
| `radius.card` | 16pt | S-5 と S-10a の中のウィジェットの見本の枠、写真・スクリーンショットのプレビュー枠 |
| `radius.ocrBox` | 4pt | 写真・スクリーンショット上の読み取り枠（`mark.ocr.column.<n>`、`cover.ocr.line.<n>`、`bookshelf.row.<n>`）と札 |

- List、Form、シート、アラートの角丸はシステムの既定のままにする。

## 5. 触覚と動き

| トークン名 | 値 | 使う場所 |
|---|---|---|
| `haptic.readingStart` | `.sensoryFeedback(.start, trigger:)` | しおりの画面で伏せて1.0秒たち、読書が始まったときに1回だけ（AC-44、AC-48） |
| `haptic.barcodeRead` | `.sensoryFeedback(.success, trigger:)` | S-8a で、本棚にない新しい ISBN のバーコードが読めたときに、1冊につき1回（AC-3） |

- ほかの場所（ボタンを押したとき、終えたとき、結果の画面、読み終えた画面、写真・スクリーンショットの読み取り）では触覚を出さない（R-28、性格語「静か」）。
- 動きはシステムの NavigationStack の押し出しと `.sheet` の出入りだけを使い、独自のアニメーションの秒数やバネの値は持たない（決定 50）。
