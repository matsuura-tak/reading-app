# 画面の図（文字で描いたもの）001-reading-session 芯の画面

- 書いた役：designer　日付：2026-10-19。2026-10-20 に G1 の判定 r1 の指摘で直した（W-1 のページの帯、押せる文字の形、下端に固定する主操作、前のページの説明、S-7a と S-7b の図、S-8a の出る道、S-8b の消すボタン、S-10 のリンクの記号）。同じ日に、tech-lead の 7 の申し送りで直した（W-1 の帯の幅 43pt、W-2 の図を式どおりに、S-1 の縦書きの場所、S-8b の件数と並び、S-10 の書誌の出どころの文）
- 仕様：design/001-reading-session.md（画面の番号、識別子、文言は仕様の 3、6、7 と同じ）
- 描き方：iPhone の縦（幅 393pt）。左右の余白は 16pt。縦の線（B-3）は画面ごとに書いた。`[ ]` は押せるもの、`（ ）` は注、右の欄は text style と識別子。色は tokens.md の名前で書いた。
- 押せるものの形（仕様の 3 の下の決まり）：主操作は .borderedProminent（黒い塗り）、そのほかのボタンは .bordered（灰の塗り）、一覧の行は記号か「>」つき、ツールバーは記号、外へ開くリンクは末尾に arrow.up.forward。枠のない文字のボタンは使わない。
- 前の図 candidate-A-flip.md と .svg（2026-10-16。製品の形が「夜の入口、本の出口」に決まる前の、伏せて読む読書タイマーの比べ）は、この図に置き換えて消した（git に残る）。

## W-1 ロック画面のウィジェット（accessoryRectangular。172×76 pt、いちばん小さい枠 153×68 pt）
縦の線：左端にページの帯（幅は「p.9999」が入る幅で固定。43pt）。帯の右 4pt（space.4）から右端までが列の場所で、列は右端から左へ並べる。内側の余白は 0（既定の余白を切る。contentMarginsDisabled）［推測。G4-1 で見る］。
```
            た待雨下    ← 1列4字。列は右から左。字はヒラギノ明朝 ProN W6、17pt から（入らなければ1pt ずつ下げる）
            ︒っや人       「、」「。」は縦書き用の字で字の枠の右上、小さい「っ」はフォントの縦書き用の字形の位置（右と上に寄る）
            　てみは       列の間は字の大きさの 0.25 倍（type.book.line.columnGap）
p.61        　いを︑    ← ページは左端の帯の下（ノンブルの位置）。.caption2 Semibold 12pt 固定
|-- 帯 --|                 帯の幅は「p.9999」で固定（43pt。ADR 0003 の実測）。桁が変わっても列は動かない
```
- 一行は25字まで（縮め方は PRD 11 の冒頭）。全部の字が入るまで字を1pt ずつ下げる（下限 13pt）。入るかの式と手順は ADR 0003（1列の字数＝⌊内側の高さ÷字の大きさ⌋、列の数×字の大きさ＋(列の数−1)×列の間 ≤ 内側の幅−帯 43pt−4pt）。この式で25字は 172×76 で 15pt（余り 35.0pt）、153×68 で 13pt（余り 28.0pt）で入る（追い出しで列が1つ増えても入る。仕様の 9）。列は上にそろえる。
- 置き換える字（「…」「（）」「『』」「―」「〜」、半角の英数字など）は tokens.md の「縦書きの組み」の表。
- 一行なし：書名（.headline の書体を固定の大きさで、2行まで）と「p.120」。ページもなし：書名だけ。一行あり・ページなし：一行だけ（帯は空けたまま、列の位置を変えない）。
- 隠す設定：「しおり」と「p.61」だけ（横書き）。今の本なし：`widget.empty`。写しを読めない：`widget.unavailable`。
- 読み上げ：全体で1つ「羅生門、61ページ。下人は、雨やみを待っていた。」。ページなしは「羅生門。下人は、雨やみを待っていた。」。

## W-2 小のウィジェット（systemSmall。148×148〜170×170 pt。ホーム画面と StandBy）
縦の線：内側 16pt（既定の余白を切り、自分で付ける。contentMarginsDisabled）。一行は列の場所の右上から組み、列は上にそろえる（ADR 0003 の位置の式）。ページは列の場所の下の左端。
```
（内側 16pt。170pt の枠。列の場所は 138×118pt）
          て や 下    ← 1列5字（⌊118÷20⌋）。列は右から左。字はヒラギノ明朝 ProN W6、20pt から（入らなければ1pt ずつ下げる）
          い み 人       列の間は字の大きさの 0.25 倍（20pt なら 5pt）
          た を は       「、」「。」は縦書き用の字、小さい「っ」はフォントの縦書き用の字形の位置
          ︒ 待 ︑
          　 っ 雨    ← 列は上にそろう。いちばん左の列は4字で、下が空く
（space.4）
p.61                  ← ページの行（13pt 固定、行の高さ 16pt）。列の場所の下の左端
```
- 例の一行「下人は、雨やみを待っていた。」（14字）は、170pt の枠で 20pt、1列5字の3列（右から「下人は、雨」「やみを待っ」「ていた。」）。25字は 170pt で 20pt、148pt で 19pt（仕様の 9）。
- 列の場所の高さは、枠から内側の 16pt の2つ分と、ページの行 16pt と `space.4` を引いた値（170pt で 118pt、148pt で 96pt）。
- StandBy ではシステムが2つ並べて大きく描き、暗い所では赤の単色にする。色と絵を足さない。
- 一行あり・ページなし：一行だけ。

## S-1 しおりの画面（通常）
縦の線：左 16（書名、著者、ページ、2つの .bordered のボタン）、右 377（一行の右端）、16〜377（主操作）。上の内容は ScrollView で送り、主操作と伏せる案内は下端に固定する（safeAreaInset）。
```
[本棚 books.vertical]          しおり           [設定 gearshape]   ツールバー（システム）。題は小さく中央
（知らせの帯があればここ。部品 N）
                                                                     space.32
羅生門                                                               .headline           bookmark.title
芥川龍之介                                                           .subheadline 2つ目の色  bookmark.author
                                                                     space.32
                                       ︵縦書きの一行。右 377 から左へ︶  type.book.line  bookmark.line
                                       　　た待雨下
                                       　　︒っや人 …（全文。60字まで）
p.61                                                                 .subheadline 数字は等幅  bookmark.page
                                                                     space.24
[ どこまで読んだかを入れる ]   space.12   [ 読み終えた ]             .bordered（灰の塗り）、文字 .subheadline、高さ44  bookmark.setMark / bookmark.finish
──（ここから下は下端に固定。safeAreaInset。上の内容だけが送られる）──
                                                                     space.12
[                       読み始める                        ]        .borderedProminent 幅いっぱい  bookmark.start
        この画面で iPhone を伏せて置いても、読み始めます。            .footnote 2つ目の色 中央  bookmark.flipHint
                                                                     space.16 と safe area
```
- 一行の縦書きの場所は、幅が画面の幅−32pt（393pt で 361pt。16〜377）、高さが画面の高さ×0.4 の切り捨て（852pt で 340pt）。1列の字数は⌊高さ÷字の大きさ⌋で、28pt で12字（60字は5列）。列は右上（377）から組み、上にそろえる。列が幅に入らないときと accessibility1 以上は横書き（下の AX5。仕様の決定 64）。
- 2つのボタンは .bordered（灰の塗りと tint の文字）。黒い塗りの「読み始める」より目立たず、塗りの形で押せると分かる（決定 4。Takuma の決定「主操作より目立たない形で画面に出しておく」）。押せない「p.61」と著者は塗りを持たない。
- 文字の入力欄、ピッカー、セグメント、メニューを置かない（AC-42）。

### S-1 のほかの形
```
（本0冊）                           （今の本なし）                    （保存先を読めない）
        book.closed                        books.vertical                   exclamationmark.triangle
     まだ本がありません                  今の本がありません               記録を読み込めませんでした
読んでいる紙の本を1冊加えると、    本棚から、次に読む1冊を          もう一度読み込んでください。…
ここに続きの一行が出ます。          選んでください。
       [本を加える]                      [本棚から選ぶ]                  [もう一度読み込む]
（ContentUnavailableView。ボタンは .borderedProminent。「読み始める」と伏せる案内は出さない）  （ツールバーは設定だけ）
```
- 一行もページもない今の本：書名と著者の下に `bookmark.noMark.message`（.subheadline 2つ目の色）。ほかは通常と同じ。
- 一行あり・ページなし：一行を出し、「p.61」の行（`bookmark.page`）を出さない。
- 一行なし・ページあり（ページだけ入れたあと）：縦書きの所を詰め、著者の下に「p.61」。
- 書誌を待つ今の本：書名の所に「ISBN 9784101000015」、下に `book.pendingInfo`。見つからない：`book.infoNotFound` と `[書名と著者を入れる]`（book.edit。.bordered）。押すと S-7a を S-1 のシートで開き、保存か取り消すで S-1 に戻る。
- 知らせの帯が出ている間：伏せる案内を出さず、伏せる道を止める（決定 43）。

### S-1（AX5）
```
[本棚]                                   [設定]
羅生門                       （行数の上限なし）
芥川龍之介
下人は、雨やみを待っていた。   （横書き、type.book.line、折り返す）
p.61
[ どこまで読んだかを入れる ]  （縦並び。どちらも幅いっぱいの .bordered）
[ 読み終えた ]
この画面で iPhone を伏せて    （AX のサイズでは、送る側のいちばん下に移す）
置いても、読み始めます。
──（ここまでを縦に送る。ScrollView）──
[        読み始める        ]   （下端に固定。safeAreaInset。文字が2行になってよい）
```

## S-2 読書中の画面（fullScreenCover。ナビゲーションバーなし）
縦の線：中央 196.5（文字）、16〜377（ボタン）。文は ScrollView で送り、「終える」は下端に固定する（safeAreaInset）。
```
                                                                     space.32
                       羅生門                                         .title2 Bold        reading.title
                 21:04 から数えています。                             .body               reading.startedAt
  伏せても、ロックしても、ほかのアプリを使っても数え続けます。         .subheadline 2つ目の色  reading.note
（知らせ session.save.error はここ。閉じるボタンなし）
──（下端に固定）──
[                         終える                          ]          .borderedProminent  reading.end
```
- 押せるのは「終える」だけ。秒と動く数字を出さない。
- 読み始めた晩が今の晩と違うとき（開き直した翌朝など。AC-53、AC-57）は、時刻の前に月日を足す：「10月17日 21:04 から数えています。」。

## S-3 しおりを挟む画面（終えたあとは全画面の中、読まずに挟むときはシート）
縦の線：左 16（問い、書名、あとで挟む）、16〜377（幅いっぱいの2つの道）。
```
                しおりを挟む                    [xmark]（シートのときだけ。mark.cancel）
どこまで読みましたか。                                                .title2 Bold   mark.question
羅生門                                                                 .subheadline 2つ目の色
                                                                     space.24
[                      一行を入れる                        ]         .borderedProminent（主の道。結果待ち） mark.manual
                                                                     space.12
[                    ページだけ入れる                      ]         .bordered      mark.pageOnly
（選択肢 (6) の [撮る] はここ。1b、2b、1c の結果で並びが変わる）
                                                                     space.24
[ あとで挟む ]                                                       .bordered（小。幅いっぱいにしない）、高さ44（全画面のときだけ） mark.later
しおりは前のまま残ります。                                           .footnote 2つ目の色
```
- 2b が届かなかったら：「ページだけ入れる」を .borderedProminent にして上に、「一行を入れる」を .bordered にして下に。

## S-3a 一行を入れる（Form）
```
<           一行を入れる                       [checkmark 保存]（role .confirm）mark.save
（保存の失敗は Form のいちばん上の行に exclamationmark.circle と common.save.error。入れた字は残す）
一行
[止めた行を、本のとおりに                              ]   TextField（axis .vertical、2〜4行）焦点  mark.lineField
1〜60字。ロック画面には25字まで出ます。                       節の説明（color.text.secondary）
（誤り）exclamationmark.circle 一行は1〜60字で入れてください。  記号だけ赤、文は本文の色  mark.line.invalid
ページ
[例 61                                                ]   TextField .numberPad。プレースホルダは手がかりだけ  mark.pageField
前のページは43です。空のまま保存すると、43のまま残ります。     節の説明（消えない。color.text.secondary） mark.page.previous
（前のページがないとき：空のままでも保存できます。）
```
- ページの欄が空なら、ページは変えない（前のページがなければ、ページなしのまま）。

## S-3b ページだけ入れる（Form）
```
<           ページだけ入れる                   [checkmark 保存]  mark.save
ページ
[例 61                                                ]   TextField .numberPad 焦点  mark.pageField
前のページは43です。                                           節の説明（消えない。前のページがあるときだけ） mark.page.previous
保存すると一行は消え、ロック画面には書名とページが出ます。
（誤り）exclamationmark.circle ページは1〜9999の数字で入れてください。  mark.page.invalid
```

## S-4 結果の画面（全画面の中）
縦の線：中央 196.5、16〜377（ボタン）。文は ScrollView で送り、「閉じる」は下端に固定する。
```
                                                                     space.32
                        羅生門                                        .headline      result.title
                     p.43 → p.61                                      .title 等幅    result.summary（2行で1つの要素）
                         18分
                     記録しました。                                   .subheadline 2つ目の色  result.saved
（知らせ session.capped はここ）
──（下端に固定）──
[                         閉じる                          ]          .borderedProminent  result.close
```
- 「あとで挟む」と、ページを入れずに一行だけ保存した晩：「18分」だけ。前のページがない：「p.61」と「18分」。

## S-5 置き方の案内（シート .medium。AX では .large）
```
ロック画面に置く                                                     .headline（シートの題）
ロック画面を長押しして「カスタマイズ」を選び、時計の下の枠に         .body
「よむま」を加えると、iPhone を手に取るたびに、この一行が出ます。
                 ［W-1 と同じ部品の見本。172×76 pt］                 widgetGuide.preview
[                         閉じる                          ]          .borderedProminent  widgetGuide.close
```

## S-6 本棚（List .insetGrouped）
```
< しおり                 本棚                      [plus]   shelf.addBook
今の本                                                      shelf.current
  羅生門                                             >      shelf.row.<id>（.body）
  芥川龍之介                                                （.subheadline 2つ目の色）
積読                                                        shelf.tsundoku（加えた日の新しい順）
  …
読み終えた                                                  shelf.finished（読み終えた日時の新しい順）
  …
```

## S-7 本の画面（List .insetGrouped と、下端の主操作）
縦の線：奥付の名前の列は左 16+16、値の列は名前の列の最長の幅のあと 12。
```
< 本棚                                           [直す]   book.edit
───────────────────────────────────────────────            罫線（separator）
書名      蜜蜂と遠雷                                       Grid  book.colophon / colophon.title
著者      恩田陸                                                 colophon.author
出版社    幻冬舎                                                 colophon.publisher
出版年    2016年                                                 colophon.year
（選択肢 (4) の受賞の行はここ）
───────────────────────────────────────────────
（書誌を待つ文、見つからない文はここ）
記録
  4晩                          合計 1時間25分               book.nights / book.total
  10/17                                   10分   >          book.record.row.<id>
  10/16                                   30分   >
[trash この本を消す]                                         role .destructive。文字は本文の色（color.text.primary）、記号 trash だけ赤（color.action.destructive）  book.delete
──（下端に固定。safeAreaInset）──
[                      この本を読む                        ]   .borderedProminent  book.readThis
（今の本のときはボタンの代わりに「今読んでいる本です。」 book.isCurrent）
```

## S-7a 本を直す（シート、Form。S-7 から。書誌が見つからない今の本は S-1 の「書名と著者を入れる」からも）
```
[xmark 取り消す]          本を直す          [checkmark 保存]   book.edit.cancel / book.edit.save
（保存の失敗は Form のいちばん上の行に common.save.error。入れた字は残す）
書名  [蜜蜂と遠雷                         ]   book.edit.title
著者  [恩田陸                             ]   book.edit.author
書名は1〜100字、著者は100字まで（空でもかまいません）。
```
- 保存か取り消すでシートを閉じ、開いた画面（S-7 か S-1）に戻る。

## S-7b 記録を直す（シート、Form）
```
[xmark 取り消す]          記録を直す          [checkmark 保存]   record.cancel / record.save
（保存の失敗は Form のいちばん上の行に common.save.error。入れた字は残す）
晩        10月16日の晩                                       record.night（読むだけ）
分  [30                                ]                    record.minutesField
1〜1440分
[trash この記録を消す]                                       role .destructive。文字は本文の色、記号 trash だけ赤  record.delete
```

## S-8 本を加える（シート、List）
```
本を加える                                       [xmark]   register.cancel
[barcode.viewfinder   バーコードを続けて読む          ]    register.barcode（先頭の行）
  （断ったとき）exclamationmark.circle カメラの使用が許可されていません。…   camera.denied
  [ 設定を開く ]                                             .bordered  camera.openSettings
[magnifyingglass      書名で探す                    > ]    register.search
[square.and.pencil    手で入れる                    > ]    register.manual
本の情報は、ISBN か書名を国立国会図書館サーチに送って探します。   節の説明
```

## S-8a バーコードを続けて読む
```
<                 バーコードを続けて読む          [xmark]   scan.cancel
（読んだ本が1冊以上の間：< を隠し、端からのスワイプとシートを払って閉じる操作を止める。xmark は role .cancel で、押すと確認）
［カメラ。DataScanner。画面の高さの半分（AX では3分の1）］   scan.camera
本の裏のバーコードを写してください。続けて読めます。       （まだ0冊のとき）
（知らせ）「こころ」はもう本棚にあります。                   scan.duplicate（加える保存の失敗 common.save.error もここ）
こころ　夏目漱石　新潮社（新潮文庫）                         scan.row.9784101000015（読んだ順）
ISBN 9784087000023　（灰の帯）書誌を探しています             scan.row.9784087000023
──（下端に固定。safeAreaInset）──
[                   2冊を本棚に加える                      ]   .borderedProminent  scan.addToShelf
```
- 0冊の間：<、端からのスワイプ、シートを払う操作、xmark（role .close）で、確認なしに出られる。

## S-8b 書名で探す
```
<                     書名で探す
[magnifyingglass 人間失格                  (xmark.circle.fill)]  search.field（TextField。焦点。改行の印は「検索」）/ search.clear（字があるときだけ。44×44pt）
人間失格　太宰治　新潮社（新潮文庫）　2006      checkmark     search.row.9784000000048（I4。選んだ行。状態「選択中」）
人間失格　太宰治　KADOKAWA（角川文庫）　1989                  search.row.<ISBN>
目当ての本がないときは、手で入れられます。                    search.footer
[ 手で入れる ]                                               .bordered（小）  register.manual
（知らせ common.save.error は、加える保存に失敗したときここ）
──（下端に固定。safeAreaInset）──
[                     この本を加える                       ]  .borderedProminent（選ぶまで押せない。結果の行がない間は出さない）register.confirm
```
- 結果は1回の問い合わせ（cnt=200。ADR 0004）で返った分だけ（ISBN のある件だけで、同じ ISBN は1行。続きを読み込まない）。最大で約200行で、List の遅延の描き方で出す。並びは ADR 0004 の並べ直しのまま（書名が入れた書名と同じ → 入れた書名で始まる → ほか。同じ組の中は応答の順）で、画面では並べ替えない。「目当ての本がないときは」と「手で入れる」はいちばん下にあり、遠いときは戻って S-8 の「手で入れる」でも入れられる。

## S-8c 手で入れる（Form）
```
[xmark 取り消す]          手で入れる          [checkmark 保存]   manual.cancel / manual.save
（保存の失敗は Form のいちばん上の行に common.save.error。入れた字は残し、シートは閉じない）
書名  [                                   ]   manual.title（焦点）
著者  [                                   ]   manual.author
書名は1〜100字、著者は100字まで（空でもかまいません）。
```

## S-9 読み終えた画面（シート .large。1つのスクロール）
縦の線：左 16（見出し、奥付、候補）、16〜377（候補のボタン）。
```
[xmark]                                                     finish.close
読み終えました                                               .largeTitle  finish.title
（選択肢 (3) のふりかえりの1行はここ）
───────────────────────────────────────                     finish.colophon（S-7 と同じ型）
書名      蜜蜂と遠雷
著者      恩田陸
出版社    幻冬舎
出版年    2016年
（選択肢 (4) の受賞の行はここ）
───────────────────────────────────────
                                                             space.24
次の1冊                                                      .headline  next.header
積読から選んでいます。                                       .footnote 2つ目の色
  P の書名                                                   .headline  next.candidate.<id>
  P の著者                                                   .subheadline
  積読から・同じ著者                                         .subheadline 2つ目の色  next.reason
  [この本を読む]                                             .bordered  next.choose
  （2冊目、3冊目も同じ形。区切りは Divider）
（選択肢 (4) の新しい本の行と、(3) のカードはここ）
まだ読み終えていなかったときは、本棚でこの本を開き、          .footnote 2つ目の色  finish.undoNote
「この本を読む」を押すと戻せます。
```
- 積読0冊：「次の1冊」の下を ContentUnavailableView（`next.empty.title`、`next.empty.message`、[本を加える] `next.addBook`。.borderedProminent）にする。押すと S-8（S-9 の上のシート）。加えると S-8 と S-9 が閉じて、S-1 に加えた本が今の本として出る。加えずに閉じると S-9 に戻る。
- 3b が届かなかったとき：候補は1冊だけ（5 の差分）。

## S-10 設定（Form）
```
< しおり                    設定
読み始め
  伏せて始める                                    [Toggle]   settings.flipToStart
  しおりの画面で iPhone を伏せて置くと、読書が始まります。オフにすると、…
ロック画面
  一行と書名を隠す                                [Toggle]   settings.hideOnWidgets
  ロック画面とホーム画面のウィジェットに、一行と書名を出さず、…
（選択肢 (5) の入口の時刻の節、(課金) の節はここ）
情報
  プライバシーポリシー                     arrow.up.forward   settings.privacyPolicy（Link。記号は color.text.secondary）
  書誌の出どころ                                              文言キー settings.dataSources.header（.body）
  書誌（書名、著者、出版社など）は、国立国会図書館サーチ…       settings.dataSources（.footnote 2つ目の色。押せない。記号なし。ADR 0004 の文。行数の上限なし）
  ライセンス（CC BY 4.0）                  arrow.up.forward   settings.dataSources.license（Link）
```

## 部品 N 知らせの帯（GroupBox）
```
[info.circle  1分未満の読書は記録に残しません。                 [ 閉じる ]]   notice / notice.close
```
- 地は GroupBox の既定。文は本文の色、エラーのときだけ記号が exclamationmark.circle（赤）。S-2 では [閉じる] を置かない。
- 閉じるは .bordered の小さいボタン（押せる範囲は 44×44pt 以上）。読み上げは「閉じる」、ヒント「知らせを閉じます。」。
- 画面の内容のいちばん上（ナビゲーションバーの下、左右 16）に出す。S-8a は一覧の上（カメラのすぐ下）、S-8b は「この本を加える」のすぐ上。出たときに読み上げを1回。
