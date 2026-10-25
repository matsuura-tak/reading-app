# 画面の図（文字で描いたもの）001-reading-session 全体（段階1〜段階4）

- 書いた役：designer　日付：2026-10-19（2026-10-20 G1 r1 改訂、2026-10-25 Step 5b 全体仕様への更新）
- 仕様：design/001-reading-session.md（画面の番号、識別子、文言は仕様の 3、6、7 と同じ）
- 描き方：iPhone の縦（幅 393pt）。左右の余白は 16pt。縦の線（B-3）は画面ごとに書いた。`[ ]` は押せるもの、`（ ）` は注、右の欄は text style と識別子。色は tokens.md の名前で書いた。
- 押せるものの形（仕様の 3 の下の決まり）：主操作は `.borderedProminent`（塗りのボタン）、そのほかのボタンは `.bordered`（薄い塗りのボタン）、一覧の行は記号か `>` つき、ツールバーは記号、外へ開くリンクは末尾に `arrow.up.forward`。枠のない文字のボタンは使わない。

## W-1 ロック画面のウィジェット（accessoryRectangular。172×76 pt、いちばん小さい枠 153×68 pt）
縦の線：左端にページの帯（幅は「p.9999」や「100%」が入る幅で固定。43pt）。帯の右 4pt（`space.4`）から右端までが列の場所で、列は右端から左へ並べる。内側の余白は 0（`contentMarginsDisabled`）。
```
            た待雨下    ← 1列4字。列は右から左。字はヒラギノ明朝 ProN W6、17pt から（入らなければ1pt ずつ下げる）
            ︒っや人       「、」「。」は縦書き用の字で字の枠の右上、小さい「っ」はフォントの縦書き用の字形の位置（右と上に寄る）
            　てみは       列の間は字の大きさの 0.25 倍（type.book.line.columnGap）
p.61        　いを︑    ← ページ（または「42%」）は左端の帯の下（ノンブルの位置）。.caption2 Semibold 12pt 固定（数字は等幅）
|-- 帯 --|                 帯の幅は「p.9999」で固定（43pt。ADR 0003 の実測）。桁や単位が変わっても列は動かない
```
- 一行は25字まで（縮め方は PRD 11 の冒頭）。全部の字が入るまで字を1pt ずつ下げる（下限 13pt）。入るかの式と手順は ADR 0003（1列の字数＝⌊内側の高さ÷字の大きさ⌋、列の数×字の大きさ＋(列の数−1)×列の間 ≤ 内側の幅−帯 43pt−4pt）。25字は 172×76 で 15pt（余り 35.0pt）、153×68 で 13pt（余り 28.0pt）で入る（追い出しで列が1つ増えても入る）。列は上にそろえる。
- 置き換える字（「…」「（）」「『』」「―」「〜」、半角の英数字など）は tokens.md の「縦書きの組み」の表。
- 一行なし：書名（`.headline` の書体を固定の大きさで、2行まで）と「p.120」（または「42%」）。ページもなし：書名だけ。一行あり・ページなし：一行だけ（帯は空けたまま、列の位置を変えない）。
- 隠す設定：「しおり」と「p.61」（または「42%」）だけ（横書き）。今の本なし：`widget.empty`。写しを読めない：`widget.unavailable`。
- 書名のない今の本（`isTitlePending = true` または書誌待ちで書名が空）：一行があれば上の図のまま。一行がなければ、書名の所に「今の本」（`widget.currentBookAsTitle`）と「p.120」、ページもなければ「今の本」だけ。
- 読み上げ：全体で1つ「羅生門、61ページ。下人は、雨やみを待っていた。」（% のときは「羅生門、42パーセント。…」）。書名のない今の本は書名の所を「今の本」にする。

## W-2 小のウィジェット（systemSmall。148×148〜170×170 pt。ホーム画面と StandBy）
縦の線：内側 16pt（`contentMarginsDisabled` で自分で付ける）。一行は列の場所の右上から組み、列は上にそろえる。ページ（または %）は列の場所の下の左端。
```
（内側 16pt。170pt の枠。列の場所は 138×118pt）
          て や 下    ← 1列5字（⌊118÷20⌋）。列は右から左。字はヒラギノ明朝 ProN W6、20pt から（入らなければ1pt ずつ下げる）
          い み 人       列の間は字の大きさの 0.25 倍（20pt なら 5pt）
          た を は       「、」「。」は縦書き用の字、小さい「っ」はフォントの縦書き用の字形の位置
          ︒ 待 ︑
          　 っ 雨    ← 列は上にそろう。いちばん左の列は4字で、下が空く
（space.4）
p.61                  ← ページまたは % の行（13pt 固定、行の高さ 16pt）。列の場所の下の左端
```
- 25字は 170pt で 20pt、148pt で 19pt。
- StandBy ではシステムが2つ並べて大きく描き、暗い所では赤の単色にする。色と絵を足さない。
- ホーム画面では、`appearanceID`（`default`、`kinari`、`sumi`、`shu`）に応じた `containerBackground` と文字色で描く（R-62）。

## W-3 ライブアクティビティ（ロック画面のバナー・Dynamic Island・StandBy）
```
（ア）入口の時刻のライブアクティビティ（夜の待機：phase = waiting）
┌────────────────────────────────────────────────────────────────────────┐
│ 羅生門                                         .subheadline 2つ目の色  │
│ 「下人は、雨やみを待っていた。」               type.book.line.liveActivity (15pt 2行まで) │
│ p.61                         [ 読み始める ]    Button(intent: StartReadingIntent) .borderedProminent │
└────────────────────────────────────────────────────────────────────────┘
  Dynamic Island Compact：左 book.closed / 右 p.61（または 42%）
  Dynamic Island Minimal：book.closed

（イ）読書中のライブアクティビティ（phase = reading）
┌────────────────────────────────────────────────────────────────────────┐
│ 羅生門                                         .headline               │
│ 21:04 から数えています。                       .subheadline 2つ目の色  │
│ （秒もタイマーも出さない）                     （タップで S-2 を開く） │
└────────────────────────────────────────────────────────────────────────┘
  Dynamic Island Compact：左 book.fill / 右 21:04〜
  Dynamic Island Minimal：book.fill

（ウ）終わったあとのライブアクティビティ（phase = ended）
┌────────────────────────────────────────────────────────────────────────┐
│ 羅生門                                         .subheadline 2つ目の色  │
│ p.43 → p.61 · 18分 · 記録しました。            .headline 等幅数字      │
└────────────────────────────────────────────────────────────────────────┘
```
- 書名のない今の本（`isTitlePending = true`）では、書名の所に「今の本」（`widget.currentBookAsTitle`）を出す。

## W-4 コントロールセンターとアクションボタンの Control（ControlWidgetButton）
```
┌──────────────────────────────┐
│ [book.closed] 読み始める      │  ControlWidgetButton(action: StartReadingIntent())
│ 羅生門                        │  control.startReading
└──────────────────────────────┘
```

## W-5 Siri と App Shortcuts のスニペット（SnippetView）
```
┌────────────────────────────────────────────────────────────────────────┐
│ 羅生門 · p.61                                  .subheadline 2つ目の色  │
│ 「下人は、雨やみを待っていた。」               type.book.line.liveActivity │
└────────────────────────────────────────────────────────────────────────┘
```

## S-1 しおりの画面（通常・紙の本 / 電子書籍 / まだ題を入れていない今の本）
縦の線：左 16（書名、著者、ページ、2つの `.bordered` のボタン）、右 377（一行の右端）、16〜377（主操作）。上の内容は `ScrollView` で送り、主操作と伏せる案内は下端に固定する（`safeAreaInset`）。
```
[本棚 books.vertical]          しおり           [設定 gearshape]   ツールバー（システム）。題は小さく中央
（知らせの帯があればここ。部品 N）
                                                                     space.32
羅生門                                                               .headline           bookmark.title
芥川龍之介                                                           .subheadline 2つ目の色  bookmark.author
（まだ題を入れていない今の本 isTitlePending = true のときは、上の2行の代わりに次を出す：
  今の本                                                             .headline           bookmark.title
  あとで書名を入れられます。                                         .subheadline 2つ目の色  book.pendingTitle
  [ 書名を入れる ]                                                   .bordered 高さ44    bookmark.setBookTitle ）
                                                                     space.32
                                       ︵縦書きの一行。右 377 から左へ︶  type.book.line  bookmark.line
                                       　　た待雨下
                                       　　︒っや人 …（全文。60字まで）
p.61（または 42%）                                                   .subheadline 数字は等幅  bookmark.page
                                                                     space.24
[ どこまで読んだかを入れる ]   space.12   [ 読み終えた ]             .bordered、文字 .subheadline、高さ44  bookmark.setMark / bookmark.finish
──（ここから下は下端に固定。safeAreaInset。上の内容だけが送られる）──
                                                                     space.12
[                       読み始める                        ]        .borderedProminent 幅いっぱい  bookmark.start
        この画面で iPhone を伏せて置いても、読み始めます。            .footnote 2つ目の色 中央  bookmark.flipHint
（電子書籍 isEbook = true のときは bookmark.flipHint.ebook：
  「読み始める」を押すか、伏せて置いて、リーダーのアプリに移れます。）
                                                                     space.16 と safe area
```
- 一行の縦書きの場所は、幅が画面の幅−32pt（393pt で 361pt。16〜377）、高さが画面の高さ×0.4 の切り捨て（852pt で 340pt）。1列の字数は⌊高さ÷字の大きさ⌋で、28pt で12字（60字は5列）。列は右上（377）から組み、上にそろえる。列が幅に入らないときと `accessibility1` 以上は横書き（下の AX5）。
- 文字の入力欄、ピッカー、セグメント、メニューを置かない（AC-42）。

### S-1 のほかの形（本0冊 / 今の本なし・積読あり / 保存先を読めない）
```
（本0冊）                                      （今の本なし・積読0冊）              （保存先を読めない）
        book.closed                                    books.vertical                      exclamationmark.triangle
     まだ本がありません                             今の本がありません                  記録を読み込めませんでした
読んでいる本を1冊加えると、                    本棚から、次に読む1冊を             もう一度読み込んでください。…
ここに続きの一行が出ます。                     選んでください。
       [本を加える]                                   [本棚から選ぶ]                     [もう一度読み込む]
     bookmark.addBook                               bookmark.chooseBook                   data.load.retry

（今の本なし・積読あり：最大3冊の候補をすぐ出せる形）
        books.vertical
     今の本がありません                        bookmark.noCurrent.title
次に読む1冊を選んでください。                  bookmark.noCurrent.message
┌────────────────────────────────────────────────────────────────────────┐
│ 蜜蜂と遠雷 · 恩田陸                          [ この本を読む ]          │  bookmark.noCurrent.next.<id> (.bordered)
│ 檸檬 · 梶井基次郎                            [ この本を読む ]          │
└────────────────────────────────────────────────────────────────────────┘
       [ 本棚から選ぶ ]                        bookmark.chooseBook (.bordered)
```
- 書誌を待つ今の本：書名の所に「ISBN 9784101000015」、下に `book.pendingInfo`。見つからない：`book.infoNotFound` と `[書名と著者を入れる]`（`book.edit`、`.bordered`）。
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
縦の線：中央 196.5（文字）、16〜377（ボタン）。文は `ScrollView` で送り、「終える」は下端に固定する（`safeAreaInset`）。
```
                                                                     space.32
                       羅生門                                         .title2 Bold        reading.title
                 21:04 から数えています。                             .body               reading.startedAt
  伏せても、ロックしても、ほかのアプリを使っても数え続けます。         .subheadline 2つ目の色  reading.note
（電子書籍 isEbook = true のときは reading.ebookNote：
  リーダーのアプリに移って読めます。読み終えたら、ここに戻って「終える」を押してください。）
（知らせ session.save.error はここ。閉じるボタンなし）
──（下端に固定）──
[                         終える                          ]          .borderedProminent  reading.end
```
- 書名のない今の本（`isTitlePending = true`）では、`reading.title` に「今の本」を出す。
- 押せるのは「終える」だけ。秒と動く数字を出さない。
- 読み始めた晩が今の晩と違うとき（開き直した翌朝など）は、時刻の前に月日を足す：「10月17日 21:04 から数えています。」。

## S-3 しおりを挟む画面（終えたあとは全画面の中、読まずに挟むときはシート）
縦の線：左 16（問い、書名、あとで挟む）、16〜377（幅いっぱいの道）。
```
                しおりを挟む                    [xmark]（シートのときだけ。mark.cancel）
どこまで読みましたか。                                                .title2 Bold   mark.question
羅生門（または 今の本）                                                .subheadline 2つ目の色
                                                                     space.24
[               ページを撮って一行を選ぶ                  ]         .borderedProminent（紙の本の主操作） mark.camera
  （カメラを断ったとき）exclamationmark.circle カメラの使用が許可されていません。…  camera.denied
  [ 設定を開く ]                                                      .bordered  camera.openSettings
                                                                     space.12
[          画面の写真を撮って一行を選ぶ（スクショ）        ]         .bordered（電子書籍のときはこれが .borderedProminent で先頭） mark.photoPicker
                                                                     space.12
[                      一行を入れる                        ]         .bordered      mark.manual
                                                                     space.12
[                 ページか%だけ入れる                      ]         .bordered      mark.pageOnly
                                                                     space.24
[ あとで挟む ]                                                       .bordered（小。全画面のときだけ）、高さ44  mark.later
しおりは前のまま残ります。                                           .footnote 2つ目の色
```

## S-3a 一行を入れる（Form。S-3 から、または S-3c で列を選んだあと）
```
<           一行を入れる                       [checkmark 保存]（role .confirm）mark.save
（保存の失敗は Form のいちばん上の行に exclamationmark.circle と common.save.error。入れた字は残す）
一行
[下人は、雨やみを待っていた。                          ]   TextField（axis .vertical、2〜4行）焦点  mark.lineField
1〜60字。ロック画面には25字まで出ます。                       節の説明（color.text.secondary）
（誤り）exclamationmark.circle 一行は1〜60字で入れてください。  記号だけ赤、文は本文の色  mark.line.invalid
どこまで読んだか
[ ページ (p.) | パーセント (%) ]                              Picker(.segmented)  mark.progressUnit
[例 61（% のときは 例 42）                             ]   TextField .numberPad  mark.pageField
前のページは43です。空のまま保存すると、43のまま残ります。     節の説明（消えない。color.text.secondary） mark.page.previous
（前の記録が % のとき：前は42%です。空のまま保存すると、42%のまま残ります。）
（前の記録がないとき：空のままでも保存できます。）
```
- S-3c で列を選んで来たときは、`mark.lineField` にその列の字（60字に縮めたもの）と、端のノンブルから拾えたときの `mark.pageField` が入った状態で開き、すぐ「保存」を押せる。

## S-3b ページか%だけ入れる（Form）
```
<           ページか%だけ入れる                [checkmark 保存]  mark.save
どこまで読んだか
[ ページ (p.) | パーセント (%) ]                              Picker(.segmented)  mark.progressUnit
[例 61（% のときは 例 42）                             ]   TextField .numberPad 焦点  mark.pageField
前のページは43です。                                           節の説明（前の記録があるときだけ） mark.page.previous
保存すると一行は消え、ロック画面には書名とページが出ます。
（誤り）exclamationmark.circle ページは1〜9999の数字で入れてください。  mark.page.invalid
（% の誤り）exclamationmark.circle パーセントは0〜100の数字で入れてください。
```

## S-3c 撮ったページ・画面の写真から一行を選ぶ画面
```
<                 一行を選ぶ
止めた行を押してください。                                           .subheadline 2つ目の色  mark.ocr.instruction
┌────────────────────────────────────────────────────────────────────────┐
│                        ［撮ったページの静止画］                        │
│        ┌───┐  ┌───┐  ┌───┐                                             │
│        │(3)│  │(2)│  │(1)│   ← 2重枠（外 1pt 黒 #000000、内 2pt 白 #FFFFFF）│
│        │ て│  │ や│  │ 下│     右から左へ番号バッジ (1)(2)(3)…          │
│        │ い│  │ み│  │ 人│     mark.ocr.column.1 / .2 / .3              │
│        │ た│  │ を│  │ は│     タップで S-3a へ進む                     │
│        └───┘  └───┘  └───┘                                             │
└────────────────────────────────────────────────────────────────────────┘
（読み取り中：ProgressView と、待たずに抜けられる2つのボタン）
  [ 一行を入れる ] (mark.manual)    [ ページか%だけ入れる ] (mark.pageOnly)

（0件だったとき：ContentUnavailableView）
  text.magnifyingglass
  文字を読み取れませんでした                                         mark.ocr.none
  明るい所で撮り直すか、手で一行を入れられます。
  [ 撮り直す ] (.bordered)    [ 一行を入れる ] (.borderedProminent, mark.manual)    [ ページか%だけ入れる ] (.bordered, mark.pageOnly)
```

## S-4 結果の画面（全画面の中）
縦の線：中央 196.5、16〜377（ボタン）。文は `ScrollView` で送り、「閉じる」は下端に固定する。
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
- % のときは「35% → 42%」と「18分」。ページから %（または % からページ）へ単位が変わった晩は、新しい方の値（「42%」と「18分」など）と「記録しました。」を出す。
- 書名のない今の本（`isTitlePending = true`）では、`result.title` に「今の本」を出す。

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
  （まだ題を入れていない本は「今の本」と「あとで書名を入れられます。」）
積読                                                        shelf.tsundoku（加えた日の新しい順）
  蜜蜂と遠雷 · 恩田陸                                >      shelf.row.<id>
読み終えた                                                  shelf.finished（読み終えた日時の新しい順）
  檸檬 · 梶井基次郎                                  >      shelf.row.<id>
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
受賞      第156回直木賞、2017年本屋大賞                          colophon.award（受賞があるときだけ）
───────────────────────────────────────────────
（書誌を待つ文 book.pendingInfo、見つからない文 book.infoNotFound、題がまだの文 book.pendingTitle はここ）
[ 奥付を撮って補う ]                                       .bordered  colophon.capture
記録
  4晩                          合計 1時間25分               book.nights / book.total
  10/17                                   10分   >          book.record.row.<id>
  10/16                                   30分   >
この本のあとに（書誌DBから引いた同じ著者の本や受賞作。あるときだけ）  after.header
  夜のピクニック · 恩田陸 · 新潮社   [積読に加える]         after.candidate.<ISBN> (.bordered。既にあれば「本棚にあります」)
[trash この本を消す]                                         role .destructive。文字は本文の色、記号 trash だけ赤  book.delete
──（下端に固定。safeAreaInset）──
[                      この本を読む                        ]   .borderedProminent  book.readThis
（今の本のときはボタンの代わりに「今読んでいる本です。」 book.isCurrent）
```

## S-7a 本を直す（シート、Form。S-7 から、または S-1 の `bookmark.setBookTitle` / `book.edit`、ガードのシートから）
```
[xmark 取り消す]          本を直す          [checkmark 保存]   book.edit.cancel / book.edit.save
（保存の失敗は Form のいちばん上の行に common.save.error。入れた字は残す）
書名  [蜜蜂と遠雷                         ]   book.edit.title
著者  [恩田陸                             ]   book.edit.author
出版社 [幻冬舎                            ]   book.edit.publisher
出版年 [2016                              ]   book.edit.year（.numberPad、4桁まで）
形態  [ 紙の本 | 電子書籍 ]                   book.edit.format（Picker .segmented）
書名は1〜100字、著者は100字まで（空でもかまいません）。
```
- まだ題を入れていない本（`isTitlePending = true`）を別の本に切り替える前や読み終える前に出るガードの案内（`book.pendingTitleGuard`）から開いたときは、保存すると `isTitlePending = false` になり、そのまま元の操作（切り替えまたは読み終える）へ進む。

## S-7b 記録を直す（シート、Form）
```
[xmark 取り消す]          記録を直す          [checkmark 保存]   record.cancel / record.save
（保存の失敗は Form のいちばん上の行に common.save.error。入れた字は残す）
晩        10月16日の晩                                       record.night（読むだけ）
分  [30                                ]                    record.minutesField
1〜1440分
[trash この記録を消す]                                       role .destructive。文字は本文の色、記号 trash だけ赤  record.delete
```

## S-7c 奥付を撮って補う画面（S-7 の `colophon.capture` から）
```
<                 奥付を撮って補う              [checkmark 保存]  colophon.save
奥付を写すと、書名・著者・出版社・出版年・ISBN を拾います。      colophon.ocr.instruction
┌────────────────────────────────────────────────────────────────────────┐
│                       ［撮った奥付の静止画］                           │
│   ┌────────────────────────────┐                                       │
│   │ (1) 蜜蜂と遠雷             │  colophon.ocr.line.1                  │
│   │ (2) 著者 恩田陸            │  colophon.ocr.line.2                  │
│   │ (3) 発行所 株式会社幻冬舎  │  colophon.ocr.line.3                  │
│   │ (4) ISBN978-4-344-03003-9  │  colophon.ocr.line.4                  │
│   └────────────────────────────┘                                       │
└────────────────────────────────────────────────────────────────────────┘
拾った書誌（タップや文字入力で直せます）
  書名    [蜜蜂と遠雷                     ]   book.edit.title
  著者    [恩田陸                         ]   book.edit.author
  出版社  [幻冬舎                         ]   book.edit.publisher
  出版年  [2016                           ]   book.edit.year
```

## S-8 本を加える（シート、List。6つの入り口）
```
本を加える                                       [xmark]   register.cancel
[barcode.viewfinder   バーコードを続けて読む          ]    register.barcode（先頭の行）
  （断ったとき）exclamationmark.circle カメラの使用が許可されていません。…   camera.denied
  [ 設定を開く ]                                             .bordered  camera.openSettings
[book.closed          表紙を撮って加える            > ]    register.cover
[books.vertical       本棚の写真を撮ってまとめて加える > ]  register.bookshelfPhoto
[magnifyingglass      書名や著者で探す              > ]    register.search
[square.and.pencil    手で入れる                    > ]    register.manual
[clock                あとで書名を入れる（すぐ読み始める）] register.later（S-1 の本0冊のとき、または「今の本としてすぐ読む」とき）
本の情報は、端末の中の書誌データから引き、なければ国立国会図書館サーチで補います。   節の説明
```
- `register.later` を押すと、書名を入れないまま `isTitlePending = true` の「今の本」を作ってシートを閉じ、すぐ S-1 から読み始められる。

## S-8a バーコードを続けて読む
```
<                 バーコードを続けて読む          [xmark]   scan.cancel
（読んだ本が1冊以上の間：< を隠し、端からのスワイプとシートを払って閉じる操作を止める。xmark は role .cancel で、押すと確認）
［カメラ。DataScanner。画面の高さの半分（AX では3分の1）］   scan.camera
本の裏のバーコードを写してください。続けて読めます。       （まだ0冊のとき）
（知らせ）「こころ」はもう本棚にあります。                   scan.duplicate（加える保存の失敗 common.save.error もここ）
こころ　夏目漱石　新潮社（新潮文庫）                         scan.row.9784101000015（端末内DBで即解決）
ISBN 9784087000023　書誌データを用意しています…             scan.row.9784087000023 / scan.dbNotReady
ISBN 9784999999996　書誌が見つかりませんでした               scan.row.9784999999996 / scan.notFound
  [ 表紙を撮る ] (scan.row.captureCover)   [ 書名を入れる ] (scan.row.editTitle)
──（下端に固定。safeAreaInset）──
[                   3冊を本棚に加える                      ]   .borderedProminent  scan.addToShelf
```
- 端末内の書誌DBからオフラインで即座に引き、なければオンラインのときだけ NDL で補う。どちらでも見つからない行には `[ 表紙を撮る ]`（`scan.row.captureCover` → S-8b）と `[ 書名を入れる ]`（`scan.row.editTitle` → S-7a と同じ入力）を行の中に出す。

## S-8b 表紙を撮って加える
```
<                 表紙を撮って加える
表紙の文字を押して、書名と著者を選んでください。                     cover.instruction
┌────────────────────────────────────────────────────────────────────────┐
│                       ［撮った表紙の静止画］                           │
│         ┌────┐   ┌──────┐                                              │
│         │(2) │   │ (1)  │   ← 2重枠（外 1pt 黒、内 2pt 白）            │
│         │ 恩 │   │ 蜜蜂 │     cover.ocr.line.1 / .2                    │
│         │ 田 │   │ と   │     一番大きい枠を最初から書名に選ぶ         │
│         │ 陸 │   │ 遠雷 │                                              │
│         └────┘   └──────┘                                              │
└────────────────────────────────────────────────────────────────────────┘
選ぶ先：[ 書名を選ぶ ] (cover.selectTitle)  [ 著者を選ぶ ] (cover.selectAuthor)
書名  [蜜蜂と遠雷                         ]   manual.title（手で直すこともできる）
著者  [恩田陸                             ]   manual.author
形態  [ 紙の本 | 電子書籍 ]                   manual.format
──（下端に固定。safeAreaInset）──
[                      この本を加える                      ]   .borderedProminent  cover.save
```

## S-8c 書名や著者で探す・手で入れる（統合画面）
```
<                   書名や著者で探す          [checkmark 保存]   manual.save
書名  [人間失格                           ]   manual.title（焦点。2字以上で端末内DBを即時検索）
著者  [太宰治                             ]   manual.author
形態  [ 紙の本 | 電子書籍 ]                   manual.format（Picker .segmented）

候補（端末内の書誌データと国立国会図書館サーチから。選ぶとそのまま加えられます）
  人間失格 · 太宰治 · 新潮社 · 2006              checkmark   search.row.9784101006055（選んだ候補）
  人間失格 · 太宰治 · KADOKAWA · 2007                        search.row.9784041099025
（候補が0件のとき）
  候補が見つかりませんでした。入れた書名のまま保存できます。 search.noResults
──（候補を選んでいるときは下端に固定。選ばずに上の「保存」でも入れた字のまま加えられる）──
[                      この本を加える                      ]   .borderedProminent  register.confirm
```

## S-8d 本棚の写真を撮ってまとめて加える
```
<             本棚の写真から加える
背表紙から読み取った本です。本棚に加える本を選んでください。         bookshelf.instruction
┌────────────────────────────────────────────────────────────────────────┐
│            ［撮った本棚の静止画（背表紙の枠に番号バッジ）］            │
└────────────────────────────────────────────────────────────────────────┘
[checkmark.circle.fill] (1) 蜜蜂と遠雷 · 恩田陸 · 幻冬舎             bookshelf.row.1（端末内DBで解決）
[checkmark.circle.fill] (2) こころ · 夏目漱石（もう本棚にあります）   bookshelf.row.2（重複は最初からオフ）
[circle]                (3) 読み取った文字：『夜のピクニック』        bookshelf.row.3（タップで書名を直せる）
──（下端に固定。safeAreaInset）──
[                   2冊を本棚に加える                      ]   .borderedProminent  bookshelf.addSelected
```

## S-9 読み終えた画面（シート .large。1つのスクロール）
縦の線：左 16（見出し、ふりかえり、奥付、読了カード、候補）、16〜377（ボタン）。
```
[xmark]                                                     finish.close
読み終えました                                               .largeTitle  finish.title
4晩 · 合計 1時間25分（10月14日〜10月17日）                   .subheadline 2つ目の色  finish.reflection
───────────────────────────────────────                     finish.colophon（S-7 と同じ型）
書名      蜜蜂と遠雷
著者      恩田陸
出版社    幻冬舎
出版年    2016年
受賞      第156回直木賞、2017年本屋大賞                      colophon.award
───────────────────────────────────────
[square.and.arrow.up 読了カードを共有する]                   .bordered  finish.card.share（押すと ShareLink で画像を共有）
                                                             space.24
次の1冊                                                      .headline  next.header
積読と、この本につながる本から選んでいます。                 .footnote 2つ目の色
  （積読の候補：最大3冊）
  檸檬                                                       .headline  next.candidate.<UUID>
  梶井基次郎                                                 .subheadline
  積読から                                                   .subheadline 2つ目の色  next.reason
  [ この本を読む ]                                           .bordered  next.choose
  ─────────────────────────────────────
  （書誌DBから引いた新しい本の候補：同じ著者・受賞作）
  夜のピクニック                                             .headline  next.candidate.9784101234151
  恩田陸 · 新潮社                                            .subheadline
  同じ著者の本・第2回本屋大賞                                .subheadline 2つ目の色  next.reason
  [ 積読に加える ]                                           .bordered  next.addToShelf
                                                             space.16
[ 今は選ばない ]                                             .bordered  next.skip（押すと S-9 を閉じ、今の本なしになる）
まだ読み終えていなかったときは、本棚でこの本を開き、          .footnote 2つ目の色  finish.undoNote
「この本を読む」を押すと戻せます。
```

## S-10 設定（Form）
```
< しおり                    設定
読み始め
  伏せて始める                                    [Toggle]   settings.flipToStart
  しおりの画面で iPhone を伏せて置くと、読書が始まります。…
夜の入口
  入口の時刻                                    [21:00]      settings.entryTime（DatePicker .hourAndMinute）
  この時刻になると、ロック画面に今の本の一行と「読み始める」を出します。
  今晩のロック画面表示を消す                                 settings.liveActivity.off（出ているときだけ押せる）
ロック画面
  一行と書名を隠す                                [Toggle]   settings.hideOnWidgets
  ロック画面とホーム画面のウィジェットに、一行と書名を出さず、…
よむま＋（紙と佇まい）
  よむま＋と紙の色                        生成り（kinari） > settings.appearance（押すと S-10a）
  購入を復元する                                             settings.restorePurchases（AppStore.sync()）
情報
  プライバシーポリシー                     arrow.up.forward   settings.privacyPolicy（Link）
  書誌の出どころ                                              文言キー settings.dataSources.header（.body）
  書誌（書名、著者、出版社など）は、openBD と国立国会図書館サーチ、文学賞データ…  settings.dataSources（.footnote 2つ目の色）
  ライセンス（CC BY 4.0）                  arrow.up.forward   settings.dataSources.license（Link）
```

## S-10a よむま＋（紙と佇まい）の案内と切り替え画面（シート）
```
よむま＋（紙と佇まい）                           [xmark]   store.close
夜のしおりと読了カードに、3つの紙の色（生成り・墨・朱）と   .body
奥付の印を加えます。買い切りで、すべての機能は無料のまま使えます。
┌────────────────────────────────────────────────────────────────────────┐
│           ［選んだ佇まい（標準 / 生成り / 墨 / 朱）の見本］            │  store.preview
│            しおりの一行と読了カードが実際の色で切り替わる              │
└────────────────────────────────────────────────────────────────────────┘
佇まいを選ぶ（購入前もすべて試せます）
  ( ) 標準（白と黒）                             store.appearance.default
  (•) 生成り（きなり）                           store.appearance.kinari
  ( ) 墨（すみ）                                 store.appearance.sumi
  ( ) 朱（しゅ）                                 store.appearance.shu
──（下端に固定。未購入のときだけ購入・復元ボタンを出す）──
[                よむま＋を購入する（¥600）                ]  .borderedProminent  store.buy（Product.displayPrice を出す）
[                       購入を復元する                      ]  .bordered           store.restore
```

## 部品 N 知らせの帯（GroupBox）
```
[info.circle  1分未満の読書は記録に残しません。                 [ 閉じる ]]   notice / notice.close
```
- 地は `GroupBox` の既定。文は本文の色、エラーのときだけ記号が `exclamationmark.circle`（赤）。S-2 では `[閉じる]` を置かない。
- 閉じるは `.bordered` の小さいボタン（押せる範囲は 44×44pt 以上）。読み上げは「閉じる」、ヒント「知らせを閉じます。」。
- 画面の内容のいちばん上（ナビゲーションバーの下、左右 16）に出す。S-8a は一覧の上（カメラのすぐ下）、S-8c は下端ボタンのすぐ上。出たときに読み上げを1回。
