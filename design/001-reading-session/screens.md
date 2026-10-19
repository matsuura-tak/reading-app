# 画面の図（文字で描いたもの）001-reading-session 芯の画面

- 書いた役：designer　日付：2026-10-19
- 仕様：design/001-reading-session.md（画面の番号、識別子、文言は仕様の 3、6、7 と同じ）
- 描き方：iPhone の縦（幅 393pt）。左右の余白は 16pt。縦の線（B-3）は画面ごとに書いた。`[ ]` は押せるもの、`（ ）` は注、右の欄は text style と識別子。色は tokens.md の名前で書いた。
- 前の図 candidate-A-flip.md と .svg（2026-10-16。製品の形が「夜の入口、本の出口」に決まる前の、伏せて読む読書タイマーの比べ）は、この図に置き換えて消した（git に残る）。

## W-1 ロック画面のウィジェット（accessoryRectangular。172×76 pt、いちばん小さい枠 153×68 pt）
縦の線：右端から列を並べ、左端の下にページ。内側の余白は足さない［推測］。
```
た待雨下      ← 1列4字。列は右から左。字はヒラギノ明朝 ProN W6、17pt（153×68 では 15pt）
︒っや人         「、」「。」は縦書き用の字で字の枠の右上、小さい「っ」も右上
　てみは
　いを︑
p.61          ← .caption2 Semibold 12pt 固定。ノンブルの位置（左下）
```
- 一行は25字まで（縮め方は PRD 11 の冒頭）。全部の字が入るまで字を1pt ずつ下げる（下限 13pt）。
- 一行なし：書名（.headline の書体を固定の大きさで、2行まで）と「p.120」。ページもなし：書名だけ。
- 隠す設定：「しおり」と「p.61」だけ（横書き）。今の本なし：`widget.empty`。写しを読めない：`widget.unavailable`。
- 読み上げ：全体で1つ「羅生門、61ページ。下人は、雨やみを待っていた。」。

## W-2 小のウィジェット（systemSmall。148×148〜170×170 pt。ホーム画面と StandBy）
縦の線：内側 16pt。一行は右上から、ページは左下。
```
（内側 16pt）
　 待 雨 下      ← ヒラギノ明朝 ProN W6、20pt から（入らなければ下げる）。1列5〜6字
　 っ や 人
た て み は
︒ い を ︑
p.61            ← 13pt 固定
```
- StandBy ではシステムが2つ並べて大きく描き、暗い所では赤の単色にする。色と絵を足さない。

## S-1 しおりの画面（通常）
縦の線：左 16（書名、著者、ページ、文字のボタン）、右 377（一行の右端）、16〜377（主操作）。
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
[どこまで読んだかを入れる]                         [読み終えた]       .subheadline 枠なし、高さ44  bookmark.setMark / bookmark.finish
                                                                     space.12
[                       読み始める                        ]        .borderedProminent 幅いっぱい  bookmark.start
        この画面で iPhone を伏せて置いても、読み始めます。            .footnote 2つ目の色 中央  bookmark.flipHint
                                                                     space.16 と safe area
```
- 一行は、縦の1列が画面の高さの約4割に収まる字数で折る（28pt で1列 10〜12字）。入らないときと accessibility1 以上は横書き（下の AX5）。
- 文字の入力欄、ピッカー、セグメント、メニューを置かない（AC-42）。

### S-1 のほかの形
```
（本0冊）                           （今の本なし）                    （保存先を読めない）
        book.closed                        books.vertical                   exclamationmark.triangle
     まだ本がありません                  今の本がありません               記録を読み込めませんでした
読んでいる紙の本を1冊加えると、    本棚から、次に読む1冊を          もう一度読み込んでください。…
ここに続きの一行が出ます。          選んでください。
       [本を加える]                      [本棚から選ぶ]                  [もう一度読み込む]
（ContentUnavailableView。読み始めると伏せる案内は出さない）       （ツールバーは設定だけ）
```
- 一行もページもない今の本：書名と著者の下に `bookmark.noMark.message`（.subheadline 2つ目の色）。ほかは通常と同じ。
- 書誌を待つ今の本：書名の所に「ISBN 9784101000015」、下に `book.pendingInfo`。見つからない：`book.infoNotFound` と `[書名と著者を入れる]`（book.edit。.bordered）。
- 知らせの帯が出ている間：伏せる案内を出さず、伏せる道を止める（決定 43）。

### S-1（AX5）
```
[本棚]                                   [設定]
羅生門                       （行数の上限なし）
芥川龍之介
下人は、雨やみを待っていた。   （横書き、type.book.line、折り返す）
p.61
[どこまで読んだかを入れる]    （縦並びに）
[読み終えた]
[        読み始める        ]   （文字が2行になってよい）
この画面で iPhone を伏せて
置いても、読み始めます。
（入らないときは画面ごと縦に送る。ScrollView）
```

## S-2 読書中の画面（fullScreenCover。ナビゲーションバーなし）
縦の線：中央 196.5（文字）、16〜377（ボタン）。
```
                                                                     space.32
                       羅生門                                         .title2 Bold        reading.title
                 21:04 から数えています。                             .body               reading.startedAt
  伏せても、ロックしても、ほかのアプリを使っても数え続けます。         .subheadline 2つ目の色  reading.note
（知らせ session.save.error はここ。閉じるボタンなし）
[                         終える                          ]          .borderedProminent  reading.end
```
- 押せるのは「終える」だけ。秒と動く数字を出さない。

## S-3 しおりを挟む画面（終えたあとは全画面の中、読まずに挟むときはシート）
縦の線：左 16（問い、書名）、16〜377（ボタン）。
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
[あとで挟む]                                                         枠なし、高さ44（全画面のときだけ） mark.later
しおりは前のまま残ります。                                           .footnote 2つ目の色
```
- 2b が届かなかったら：「ページだけ入れる」を .borderedProminent にして上に、「一行を入れる」を .bordered にして下に。

## S-3a 一行を入れる（Form）
```
<           一行を入れる                       [checkmark 保存]（role .confirm）mark.save
一行
[止めた行を、本のとおりに                              ]   TextField（axis .vertical、2〜4行）焦点  mark.lineField
1〜60字。ロック画面には25字まで出ます。                       節の説明
（誤り）exclamationmark.circle 一行は1〜60字で入れてください。  記号だけ赤、文は本文の色  mark.line.invalid
ページ
[前は 43                                              ]   TextField .numberPad  mark.pageField
空のままでも保存できます（ページは空になります）。
（保存の失敗は Form のいちばん上に common.save.error。入れた字は残す）
```

## S-3b ページだけ入れる（Form）
```
<           ページだけ入れる                   [checkmark 保存]  mark.save
ページ
[前は 43                                              ]   TextField .numberPad 焦点  mark.pageField
保存すると一行は消え、ロック画面には書名とページが出ます。
（誤り）exclamationmark.circle ページは1〜9999の数字で入れてください。  mark.page.invalid
```

## S-4 結果の画面（全画面の中）
縦の線：中央 196.5、16〜377（ボタン）。
```
                                                                     space.32
                        羅生門                                        .headline      result.title
                     p.43 → p.61                                      .title 等幅    result.summary（2行で1つの要素）
                         18分
                     記録しました。                                   .subheadline 2つ目の色  result.saved
（知らせ session.capped はここ）
[                         閉じる                          ]          .borderedProminent  result.close
```

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
読み終えた                                                  shelf.finished（読み終えた日の新しい順）
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
[trash この本を消す]                                         role .destructive  book.delete
──（下端。safeAreaInset）──
[                      この本を読む                        ]   .borderedProminent  book.readThis
（今の本のときはボタンの代わりに「今読んでいる本です。」 book.isCurrent）
```

## S-8 本を加える（シート、List）
```
本を加える                                       [xmark]   register.cancel
[barcode.viewfinder   バーコードを続けて読む          ]    register.barcode（先頭の行）
  （断ったとき）exclamationmark.circle カメラの使用が許可されていません。…   camera.denied
  [設定を開く]                                                                camera.openSettings
[magnifyingglass      書名で探す                    > ]    register.search
[square.and.pencil    手で入れる                    > ]    register.manual
本の情報は、ISBN か書名を国立国会図書館サーチに送って探します。   節の説明
```

## S-8a バーコードを続けて読む
```
<                 バーコードを続けて読む          [xmark]   scan.cancel（読んだ本があれば確認）
［カメラ。DataScanner。画面の高さの半分（AX では3分の1）］   scan.camera
本の裏のバーコードを写してください。続けて読めます。       （まだ0冊のとき）
（知らせ）「こころ」はもう本棚にあります。                   scan.duplicate
こころ　夏目漱石　新潮社（新潮文庫）                         scan.row.9784101000015（読んだ順）
ISBN 9784087000023　（灰の帯）書誌を探しています             scan.row.9784087000023
[                   2冊を本棚に加える                      ]   .borderedProminent  scan.addToShelf
```

## S-8b 書名で探す
```
<                     書名で探す
[magnifyingglass 人間失格                       (消す)]      search.field（TextField。焦点。改行の印は「検索」）
人間失格　太宰治　新潮社（新潮文庫）　2006      checkmark     search.row.9784000000048（I4。選んだ行。状態「選択中」）
人間失格　太宰治　KADOKAWA（角川文庫）　1989                  search.row.<ISBN>
目当ての本がないときは、手で入れられます。  [手で入れる]      search.footer / register.manual
[                     この本を加える                       ]  .borderedProminent（選ぶまで押せない）register.confirm
```

## S-8c 手で入れる（Form）
```
[xmark 取り消す]          手で入れる          [checkmark 保存]   manual.cancel / manual.save
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
- 積読0冊：「次の1冊」の下を ContentUnavailableView（`next.empty.title`、`next.empty.message`、[本を加える] `next.addBook`）にする。
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
  プライバシーポリシー                                       settings.privacyPolicy（Link）
  書誌の出どころ                                             settings.dataSources（ADR の文字列）
  ライセンス（CC BY 4.0）                                    settings.dataSources.license（Link）
```

## 部品 N 知らせの帯（GroupBox）
```
[info.circle  1分未満の読書は記録に残しません。                 [閉じる]]   notice / notice.close
```
- 地は GroupBox の既定。文は本文の色、エラーのときだけ記号が exclamationmark.circle（赤）。S-2 では [閉じる] を置かない。
- 画面の内容のいちばん上（ナビゲーションバーの下、左右 16）に出す。出たときに読み上げを1回。
