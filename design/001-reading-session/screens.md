# 画面の図（文字で描いたもの）001-reading-session 全体（段階1〜段階4）

- 書いた役：designer　日付：2026-10-19（2026-10-20 G1 r1 改訂、2026-10-25 Step 5b・Step 6 r1 全体仕様への更新）
- 仕様：design/001-reading-session.md（画面の番号、識別子、文言は仕様の 3、6、7 と同じ）
- 描き方：iPhone の縦（幅 393pt）。左右の余白は 16pt。縦の線（B-3）は画面ごとに書いた。`[ ]` は押せるもの、`（ ）` は注、右の欄は text style と識別子。色は tokens.md の名前で書いた。
- 押せるものの形（仕様の 3 の下の決まり）：主操作は `.borderedProminent`（塗りのボタン）、そのほかのボタンは `.bordered`（薄い塗りのボタン）、一覧の行は記号か `>` つき、ツールバーは記号、外へ開くリンクは末尾に `arrow.up.forward`。枠のない文字のボタンは使わない。

## W-1 ロック画面のウィジェット（accessoryRectangular。172×76 pt、いちばん小さい枠 153×68 pt）
縦の線：左端に場所の帯（幅は「p.9999」や「100%」が入る幅で固定。43pt）。帯の右 4pt（`space.4`）から右端までが列の場所で、列は右端から左へ並べる。内側の余白は 0（`contentMarginsDisabled`）。
```
            た待雨下    ← 1列4字。列は右から左。字はヒラギノ明朝 ProN W6、17pt から（入らなければ1pt ずつ下げる）
            ︒っや人       「、」「。」は縦書き用の字で字の枠の右上、小さい「っ」はフォントの縦書き用の字形の位置（右と上に寄る）
            　てみは       列の間は字の大きさの 0.25 倍（type.book.line.columnGap）
p.61        　いを︑    ← 場所（p.61 / 位置1450 / 52%）は左端の帯の下（ノンブルの位置）。.caption2 Semibold 12pt 固定（数字は等幅）
|-- 帯 --|                 帯の幅は 43pt 固定（ADR 0003 の実測）。桁や単位が変わっても列は動かない（widget.rectangular / widget.line / widget.page）
```
- 一行は25字まで（縮め方は PRD 11 の冒頭、AC-29）。全部の字が入るまで字を1pt ずつ下げる（下限 13pt）。入るかの式と手順は ADR 0003（1列の字数＝⌊内側の高さ÷字の大きさ⌋、列の数×字の大きさ＋(列の数−1)×列の間 ≤ 内側の幅−帯 43pt−4pt）。25字は 172×76 で 15pt（余り 35.0pt）、153×68 で 13pt（余り 28.0pt）で入る（追い出しで列が1つ増えても入る）。列は上にそろえる。
- 置き換える字（「…」「（）」「『』」「―」「〜」、半角の英数字など）は tokens.md の「縦書きの組み」の表。ひらがな・カタカナ・漢字を1字も含まない一行は横書き（AC-30）。
- 一行なし：書名（`.headline` の書体を固定の大きさで、2行まで、`widget.title`）と「p.120」（または「位置1450」「52%」）。場所もなし：書名だけ。一行あり・場所なし：一行だけ（帯は空けたまま、列の位置を変えない）。
- 隠す設定（`settings.hideOnWidgets = true`）：`widget.hidden`（「しおり」）と「p.61」（または「位置1450」「52%」）だけ（横書き、AC-34）。今の本なし：`widget.empty`。写しを読めない：`widget.unavailable`。
- 書名のない今の本（`isTitlePending = true`）：一行があれば上の図のまま。一行がなければ、書名の所に `widget.currentBookAsTitle`（「今の本」）と「p.120」、場所もなければ「今の本」だけ（AC-139）。
- 読み上げ：全体で1つ「羅生門、61ページ。下人は、雨やみを待っていた。」（位置番号のときは「羅生門、位置1450。…」、％のときは「羅生門、52パーセント。…」）。書名のない今の本は書名の所を「今の本」にする（AC-99）。押したときの URL は `yomuma://open?entry=lock_widget`。

## W-2 小のウィジェット（systemSmall。148×148〜170×170 pt。ホーム画面と StandBy）
縦の線：内側 16pt（`contentMarginsDisabled` で自分で付ける）。一行は列の場所の右上から組み、列は上にそろえる。場所（p.61 / 位置1450 / 52%）は列の場所の下の左端。
```
（内側 16pt。170pt の枠。列の場所は 138×118pt。全体識別子 widget.small）
          て や 下    ← 1列5字（⌊118÷20⌋）。列は右から左。字はヒラギノ明朝 ProN W6、20pt から（入らなければ1pt ずつ下げる）
          い み 人       列の間は字の大きさの 0.25 倍（20pt なら 5pt）
          た を は       「、」「。」は縦書き用の字、小さい「っ」はフォントの縦書き用の字形の位置
          ︒ 待 ︑
          　 っ 雨    ← 列は上にそろう。いちばん左の列は4字で、下が空く
（space.4）
p.61                  ← 場所（p.61 / 位置1450 / 52%）の行（13pt 固定、行の高さ 16pt）。列の場所の下の左端
```
- 25字は 170pt で 20pt、148pt で 19pt。押したときの URL は `yomuma://open?entry=small_widget`（AC-35）。
- StandBy ではシステムが2つ並べて大きく描き、暗い所では赤の単色にする。色と絵を足さない。
- ホーム画面では、`appearanceID`（`default`、`kinari`、`sumi`、`shu`）に応じた `containerBackground` と文字色で描く（AC-106）。

## W-3 ライブアクティビティ（ロック画面のバナー・Dynamic Island・StandBy。全体識別子 `liveActivity.banner`）
```
（ア）夜の入口の予約ライブアクティビティ（待つ状態：phase = waiting。AC-36, AC-40）
┌────────────────────────────────────────────────────────────────────────┐
│ 羅生門                                         .headline               │
│ 下人は、雨やみを待っていた。                   type.book.line.liveActivity (16pt 2行まで) │
│ p.61（または 位置1450 / 52%）                  .subheadline 2つ目の色  │
│ （ボタンは置かない。バナー全体タップ widgetURL で S-1 を開く）         │
└────────────────────────────────────────────────────────────────────────┘
  Dynamic Island Compact：左 book / 右 p.61（または 位置1450 / 52%）
  Dynamic Island Minimal：book
  Dynamic Island Expanded（waiting）：書名、一行、p.61（ボタンなし。全体タップで S-1 を開く）

（イ）読書中のライブアクティビティ（phase = reading。AC-41, AC-114, AC-120, AC-144）
┌────────────────────────────────────────────────────────────────────────┐
│ 羅生門                                         .headline               │
│ 21:04 から読書中              [ 終える ]       Button(intent: EndReadingFromActivityIntent()) │
│ （一行と場所は出さない）      liveActivity.end （ラベル liveActivity.end.label「読書を終える」） │
└────────────────────────────────────────────────────────────────────────┘
  Dynamic Island Expanded（reading）：
┌────────────────────────────────────────────────────────────────────────┐
│ [book] 羅生門                                  .headline               │
│ 21:04 から読書中              [ 終える ]       liveActivity.end（Button(intent: EndReadingFromActivityIntent())） │
└────────────────────────────────────────────────────────────────────────┘
  Dynamic Island Compact：左 book / 右 21:04〜
  Dynamic Island Minimal：book

（ウ）終わった直後のライブアクティビティ（phase = ended。AC-41）
┌────────────────────────────────────────────────────────────────────────┐
│ 羅生門                                         .subheadline 2つ目の色  │
│ 10分 · p.61（または 位置1450 / 52%）           .headline 等幅数字      │
└────────────────────────────────────────────────────────────────────────┘
```
- `waiting` のときはボタンを置かず、バナー全体を押すと `yomuma://open?entry=live_activity` で S-1 を開く（AC-36、AC-40）。
- `reading` のとき押せる要素は、ロック画面バナー・Dynamic Island Expanded ともに `[ 終える ]`（`accessibilityIdentifier: "liveActivity.end"`、`Button(intent: EndReadingFromActivityIntent())`、VoiceOver ラベルは `liveActivity.end.label`「読書を終える」／"End Reading"）の1つだけ（AC-41、AC-114）。
- 書名のない今の本（`isTitlePending = true`）では、書名の所に `widget.currentBookAsTitle`（「今の本」）を出す（AC-139）。
- `settings.hideOnWidgets` がオンのときは、書名と一行を出さず `widget.hidden`（「しおり」）と場所（`reading` のときは「しおり」と開始時刻と `liveActivity.end`）だけを出す（AC-34、AC-120）。

## W-4 コントロールセンター・ロック画面・アクションボタンの Control（ControlWidgetButton。AC-114, AC-126）
```
┌──────────────────────────────┐
│ [book] 読み始める             │  ControlWidgetButton(action: StartReadingIntent())
│                              │  accessibilityIdentifier: control.startReading（単発ボタン1つ、トグルではない）
└──────────────────────────────┘
```

## W-5 Siri と App Shortcuts の応答・小窓（SnippetView。AC-121〜AC-126, AC-133, AC-143）
```
（「どこまで読んだ？」WhereStoppedIntent の小窓 ShowsSnippetView。authenticationPolicy = .alwaysAllowed）
┌────────────────────────────────────────────────────────────────────────┐
│ 61ページからです。                             .body   intent.snippet  │
└────────────────────────────────────────────────────────────────────────┘
```
- **ロック画面のプライバシー保護（AC-121、AC-123、AC-133、AC-143、判断 79）**：声の返答と小窓（`intent.snippet`）のどちらにも、**書名（例：「羅生門」）と一行の文字列（例：「下人は、雨やみを待っていた。」）は一切出さない**。出すのは次の1文だけ：
  - 単位が `page`：`intent.whereStopped.page`（「61ページからです。」／"From page 61."）
  - 単位が `location`：`intent.whereStopped.location`（「位置1450からです。」／"From location 1450."）
  - 単位が `percent`：`intent.whereStopped.percent`（「52パーセントからです。」／"From 52 percent."）
  - 場所の値がないとき：`intent.whereStopped.noPage`（「今の本には、まだページが記録されていません。」）
  - 今の本がないとき：`intent.whereStopped.noCurrent`（「いま読んでいる本が選ばれていません。」）
  - 読み込み失敗のとき：`intent.whereStopped.error`（「しおりを読み込めませんでした。よむまを開いて確かめてください。」）
- App Shortcuts の3つのインテント（日本語の言い方に `\(.applicationName)で` は0件。AC-126）：
  1. `StartReadingIntent`（「読み始める」）：声で `intent.start.started` / `intent.start.alreadyReading` / `session.start.error` を返し、W-3（`reading`）を始める（小窓は出さない）。
  2. `WhereStoppedIntent`（「どこまで読んだ？」）：上の1文だけを声と小窓（`intent.snippet`）で返す。
  3. `ContinueReadingIntent`（「続きを読む」）：アプリを前に出して S-1（`reading` なら S-2）を開く（入口の印は `intent_open`。AC-124、AC-134、AC-135）。

## S-1 しおりの画面（通常・紙の本 / 電子書籍 / 名無しの今の本）
縦の線：左 16（書名、著者、場所、`.bordered` の補助ボタン）、右 377（一行の右端）、16〜377（主操作）。上の内容は `ScrollView` で送り、主操作と伏せる案内は下端に固定する（`safeAreaInset`）。
```
[本棚 books.vertical]          しおり           [設定 gearshape]   toolbar.shelf / bookmark.navTitle / toolbar.settings
（知らせの帯があればここ。部品 N：notice / session.tooShort 等）
                                                                     space.32
羅生門                                                               .headline           bookmark.title
芥川龍之介                                                           .subheadline 2つ目の色  bookmark.author
（名無しの今の本 isTitlePending = true のときは、上の書名・著者の所に次を出す（AC-139, AC-140）：
  今の本                                                             .headline           bookmark.title（文言 widget.currentBookAsTitle）
  [ 書名を入れる ]                                                   .bordered 高さ44    bookmark.setBookTitle ）
                                                                     space.32
                                       ︵縦書きの一行。右 377 から左へ︶  type.book.line  bookmark.line
                                       　　た待雨下
                                       　　︒っや人 …（全文。60字まで）
p.61（または 位置1450 / 52%）                                        .subheadline 数字は等幅  bookmark.page
（一行も場所もまだないときは、縦書きの代わりに bookmark.noMark.message を出す）
                                                                     space.24
[ どこまで読んだかを入れる ]   space.12   [ 読み終えた ]             .bordered、文字 .subheadline、高さ44  bookmark.setMark / bookmark.finish
──（ここから下は下端に固定。safeAreaInset。上の内容だけが送られる）──
                                                                     space.12
[                       読み始める                        ]        .borderedProminent 幅いっぱい  bookmark.start
        この画面で iPhone を伏せて置いても、読み始めます。            .footnote 2つ目の色 中央  bookmark.flipHint
（電子書籍 isEbook = true のときは bookmark.flipHint.ebook（AC-144）：
  別の端末で読むなら伏せて置いても、この iPhone で読むなら「読み始める」を押して他のアプリに移っても数えられます。）
                                                                     space.16 と safe area
```
- 一行の縦書きの場所は、幅が画面の幅−32pt（393pt で 361pt。16〜377）、高さが画面の高さ×0.4 の切り捨て（852pt で 340pt）。1列の字数は⌊高さ÷字の大きさ⌋で、28pt で12字（60字は5列）。列は右上（377）から組み、上にそろえる。列が幅に入らないときと `accessibility1` 以上、および日本語の文字を含まない一行（AC-30）は横書き（下の AX5）。
- 文字の入力欄、ピッカー、セグメント、メニューを置かない（AC-42）。

### S-1 のほかの形（本0冊 / 今の本なし・積読あり / 今の本なし・積読0冊 / 保存先を読めない）
```
（本0冊：AC-1）                                （今の本なし・積読0冊：AC-16）        （保存先を読めない：AC-90）
        book.closed                                    books.vertical                      exclamationmark.triangle
     まだ本がありません                             今の本がありません                  記録を読み込めませんでした
読んでいる本を1冊加えると、                    次に読む1冊を選んでください。        もう一度読み込んでください。…
ここに続きの一行が出ます。                     bookmark.noCurrent.message           store.load.error
  bookmark.empty.message                            [ 本棚から選ぶ ]                     [ もう一度読み込む ]
       [ 本を加える ]                              bookmark.openShelf                       store.retry
      bookmark.addBook

（今の本なし・積読あり：積読から最大3冊の候補をすぐ出せる形。AC-145）
        books.vertical
     今の本がありません                        bookmark.noCurrent.title
次に読む1冊を選んでください。                  bookmark.noCurrent.message（名無しの本があるときの案内別名 bookmark.unnamedNotice）
┌────────────────────────────────────────────────────────────────────────┐
│ 蜜蜂と遠雷 · 恩田陸 · 積読から・同じ著者      [ この本を読む ]          │  行：bookmark.noCurrent.next.<id> / ボタン：bookmark.noCurrent.choose
│ 檸檬 · 梶井基次郎 · 積読から                  [ この本を読む ]          │  （最大3冊）
└────────────────────────────────────────────────────────────────────────┘
       [ 本棚から選ぶ ]                        bookmark.openShelf (.bordered)
       [ 本を加える ]                          bookmark.addBook (.bordered。新しく本を加える第2ボタン)
```
- 知らせの帯が出ている間、およびシートや確認ダイアログが出ている間：伏せる案内を出さず、向きの監視を止める（`flipMonitoring=off`、AC-47）。

### S-1（AX5）
```
[本棚 toolbar.shelf]                     [設定 toolbar.settings]
羅生門                       （行数の上限なし。bookmark.title）
芥川龍之介                   （bookmark.author）
下人は、雨やみを待っていた。   （横書き、type.book.line、折り返す。bookmark.line）
p.61                         （bookmark.page）
[ どこまで読んだかを入れる ]  （縦並び。どちらも幅いっぱいの .bordered。bookmark.setMark）
[ 読み終えた ]               （bookmark.finish）
（isTitlePending = true のときはここに [ 書名を入れる ] bookmark.setBookTitle）
この画面で iPhone を伏せて    （AX のサイズでは、送る側のいちばん下に移す。bookmark.flipHint）
置いても、読み始めます。
──（ここまでを縦に送る。ScrollView）──
[        読み始める        ]   （下端に固定。safeAreaInset。文字が2行になってよい。bookmark.start）
```

## S-2 読書中の画面（fullScreenCover。ナビゲーションバーなし。AC-43, AC-144）
縦の線：中央 196.5（文字）、16〜377（ボタン）。文は `ScrollView` で送り、「終える」は下端に固定する（`safeAreaInset`）。
```
                                                                     space.32
                       羅生門                                         .title2 Bold        reading.title
                 21:04 から数えています。                             .body               reading.startedAt
  伏せても、ロックしても、ほかのアプリを使っても数え続けます。         .subheadline 2つ目の色  reading.note
（電子書籍 isEbook = true のときは reading.ebookNote（AC-144）：
  この iPhone で電子書籍を読むときも、アプリを閉じたままで数え続けます。読み終えたらロック画面やダイナミックアイランドの「終える」でも終えられます。）
（終わりの保存失敗の知らせ session.save.error はここ。閉じるボタンなし。AC-60, AC-132）
──（下端に固定）──
[                         終える                          ]          .borderedProminent  reading.end
```
- 書名のない今の本（`isTitlePending = true`）では、`reading.title` に `widget.currentBookAsTitle`（「今の本」）を出す（AC-139）。
- 画面内の押せる要素は `reading.end`（「終える」）の1つだけ。タブバーもナビゲーションバーも置かず、秒と動く数字を出さない（AC-43）。
- 読み始めた晩が今の晩と違うとき（開き直した翌朝など）は、時刻の前に月日を足す：「10月17日 21:04 から数えています。」。

## S-3 しおりを挟む画面（終えたあとは全画面の中、読まずに挟むときはシート。AC-63, AC-70, AC-142）
縦の線：左 16（問い、書名、あとで挟む）、16〜377（幅いっぱいの道）。
```
                しおりを挟む                    [xmark 閉じる]（S-1 の bookmark.setMark からシートで開いたときだけ。mark.cancel）
どこまで読みましたか。                                                .title2 Bold   mark.question
羅生門（または 今の本）                                                .subheadline 2つ目の色
                                                                     space.24
[         camera.viewfinder ページを撮る                   ]         .borderedProminent（紙の本の主操作） mark.photo
  （カメラを断ったとき AC-70）
  exclamationmark.circle カメラの使用が許可されていません。「設定」で許可するか、スクリーンショットから選ぶか、手で入れてください。  camera.denied
  [ 設定を開く ]                                                      .bordered  camera.openSettings
                                                                     space.12
[    photo.on.rectangle スクリーンショットから選ぶ          ]         .bordered（PhotosPicker .screenshots、カメラ拒否時・電子書籍の主操作） mark.screenshot
                                                                     space.12
[         square.and.pencil 一行を入れる                    ]         .bordered      mark.manual
                                                                     space.12
[                ページだけ入れる                           ]         .bordered（位置なら「位置番号だけ入れる」、％なら「％だけ入れる」） mark.pageOnly
                                                                     space.24
[ あとで挟む ]                                                       .bordered（小。読んだあとの全画面のときだけ）、高さ44  mark.later
しおりは前のまま残ります。（前のしおりが空なら「しおりは空のままです。」） .footnote 2つ目の色  mark.later.note / mark.later.note.empty
```

## S-3a 一行と場所を入れる画面（Form。S-3 の `mark.manual` から。AC-71, AC-72, AC-74, AC-95, AC-141）
```
<           一行を入れる                       [checkmark 保存]（role .confirm）mark.save
（保存の失敗は Form のいちばん上の行に exclamationmark.circle と common.save.error。入れた字は残す。AC-95）
一行
[下人は、雨やみを待っていた。                          ]   TextField（axis .vertical、2〜4行）焦点  mark.lineField
1〜60字。ロック画面には25字まで出ます。                       節の説明（color.text.secondary） mark.line.footer
（誤り）exclamationmark.circle 一行は1〜60字で入れてください。  記号だけ赤、文は本文の色  mark.line.invalid
どこまで読んだか
単位  [ ページ | 位置 | ％ ]                                  Picker(.segmented)（page / location / percent の3択） mark.progressUnit
[例 61（位置のときは 例 1450、％のときは 例 52）       ]   TextField .numberPad  mark.pageField
前の値はp.43です。空のまま保存すると、p.43のまま残ります。     節の説明（消えない。color.text.secondary） mark.page.previous
（前の記録が位置のとき：前の値は位置1200です。空のまま保存すると、位置1200のまま残ります。）
（前の記録が％のとき：前の値は34%です。空のまま保存すると、34%のまま残ります。）
（前の記録がないとき：空のままでも保存できます。 mark.page.footer.optional）
（誤り）exclamationmark.circle ページは1〜9999（位置は1〜999999、％は0〜100）の整数の数字で入れてください。
                                                              mark.page.invalid（位置範囲外の別名 mark.progress.outOfRange.location）
```
- `mark.progressUnit` は `page`（ページ：範囲 `1〜9999`）、`location`（位置：範囲 `1〜999999`）、`percent`（％：範囲 `0〜100`）の3択（AC-141）。範囲外の値や小数は `mark.page.invalid`（位置の `1〜999999` 範囲外は別名 `mark.progress.outOfRange.location`）を出して保存しない。

## S-3b 場所（ページ・位置・％）だけ入れる画面（Form。S-3 の `mark.pageOnly` から。AC-73, AC-74, AC-141）
```
<           ページだけ入れる                   [checkmark 保存]  mark.save
（保存の失敗は Form のいちばん上の行に exclamationmark.circle と common.save.error。入れた字は残す）
どこまで読んだか
単位  [ ページ | 位置 | ％ ]                                  Picker(.segmented)（page / location / percent の3択） mark.progressUnit
[例 61（位置のときは 例 1450、％のときは 例 52）       ]   TextField .numberPad 焦点  mark.pageField
前のページは43です。（位置なら「前の位置は位置1200です。」、％なら「前の値は34%です。」）  mark.page.previous（前の値があるときだけ）
保存すると一行は消え、ロック画面には書名と場所が出ます。       mark.pageOnly.footer
（誤り）exclamationmark.circle ページは1〜9999（位置は1〜999999、％は0〜100）の整数の数字で入れてください。
                                                              mark.page.invalid（位置範囲外の別名 mark.progress.outOfRange.location）
```
- 単位の範囲：`page` は `1〜9999`、`location` は `1〜999999`、`percent` は `0〜100`（AC-74、AC-141）。

## S-3c 写真・スクリーンショットから一行を選ぶ画面（S-3 の `mark.photo` / `mark.screenshot` から。S-3c 単体で選択・修正・保存が完結。AC-65〜AC-69, AC-94, AC-95, AC-141, AC-142）
```
<                 一行を選ぶ                    [撮り直す]（スクショなら「選び直す」） mark.retake
（保存の失敗は欄の上に exclamationmark.circle と common.save.error。選んだ文字と場所は残す。AC-95）
止めた行の枠を押すと、下の欄に入ります。文字はそのまま手で直せます。 .subheadline 2つ目の色  mark.ocr.hint
┌────────────────────────────────────────────────────────────────────────┐
│              ［撮ったページまたはスクリーンショットの静止画］          │
│        ┌───┐  ┌───┐  ┌───┐                                             │
│        │(3)│  │(2)│  │(1)│   ← 白黒2重枠（外 2pt 黒 #000000、内 2pt 白 #FFFFFF、選択中は 3pt）│
│        │ ほ│  │ や│  │ 下│     右から左へ番号札 (1)(2)(3)…             │
│        │ か│  │ み│  │ 人│     mark.ocr.column.1 / .2 / .3             │
│        │ に│  │ を│  │ は│     最初にいちばん左の列 (3) が選ばれ、     │
│        └───┘  └───┘  └───┘     下の mark.lineField に文字が入る        │
└────────────────────────────────────────────────────────────────────────┘
（下半分：常時表示。別の画面へ遷移せず S-3c のこの場で文字修正・場所入力・保存が完結する）
一行（1〜60字）
[ほかには誰もいない。                                  ]   TextField（手でそのまま直せる。AC-67） mark.lineField
（誤り）exclamationmark.circle 一行は1〜60字で入れてください。  mark.line.invalid
どこまで読んだか
単位  [ ページ | 位置 | ％ ]                                  Picker(.segmented)（page 1〜9999 / location 1〜999999 / percent 0〜100 の3択） mark.progressUnit
[61                                                    ]   TextField .numberPad（柱・ノンブルから拾えれば候補を入れる） mark.pageField
前の値はp.43です。空のまま保存すると、p.43のまま残ります。     mark.page.previous
（誤り）exclamationmark.circle ページは1〜9999（位置は1〜999999、％は0〜100）の整数の数字で入れてください。
                                                              mark.page.invalid（位置範囲外の別名 mark.progress.outOfRange.location）
[ 撮り直す ] (mark.retake, .bordered)    [ 一行を入れる ] (mark.manual, .bordered)
──（下端に固定。safeAreaInset）──
[                         保存                            ]   .borderedProminent  mark.save

──（読み取り待ちの間 AC-94：画像の上に ProgressView、下には待たずに抜けられるボタンを常時有効で出す）──
  [ 一行を入れる ] (mark.manual, .bordered)    [ ページだけ入れる ] (mark.pageOnly, .bordered)

──（読み取れた列が0個のとき AC-68：画像の位置に ContentUnavailableView を出し、下の欄でそのまま手入力もできる）──
  text.magnifyingglass
  文字を読み取れませんでした。明るい所で撮り直すか、手で入れてください。  mark.ocr.none
  [ 撮り直す ] (.borderedProminent, mark.retake)    [ 一行を入れる ] (.bordered, mark.manual)
```
- **S-3c 単体での完結（AC-65〜AC-68、AC-142、判断 67）**：列の枠 `mark.ocr.column.<n>` を押すと S-3a に遷移するのではなく、同じ S-3c の下半分の `mark.lineField` の文字がその列の文字に替わる（初期状態はいちばん左の列 `mark.ocr.column.<n>` が選ばれ `mark.lineField` に入っている）。利用者はその場で `mark.lineField` の崩れた字を直し（AC-67）、`mark.progressUnit`（`page` / `location` / `percent` の3択）と `mark.pageField` を入れ、下端の `mark.save` で保存する。
- 画像はメモリ上だけで処理し、保存時・キャンセル時ともにファイルには一切残さない（AC-69、AC-142）。

## S-4 読書の結果の画面（全画面の中。AC-57, AC-75, AC-76, AC-141）
縦の線：中央 196.5、16〜377（ボタン）。文は `ScrollView` で送り、「閉じる」は下端に固定する。
```
                                                                     space.32
                        羅生門                                        .headline      result.title
                   p.43 → p.61　18分                                  .title 等幅    result.summary
                     記録しました。                                   .subheadline 2つ目の色  result.saved
（24時間上限に達したときの知らせ session.capped はここ。AC-57）
──（下端に固定）──
[                         閉じる                          ]          .borderedProminent  result.close
```
- 単位が `location` のときは「位置1200 → 位置1450　18分」（`result.summary.locations`）、`percent` のときは「34% → 52%　18分」（`result.summary.percents`）（AC-141）。前の値がないときは「p.61　18分」、「あとで挟む」（`mark.later`）のときは「18分」だけを出す（AC-75、AC-76）。
- 書名のない今の本（`isTitlePending = true`）では、`result.title` に `widget.currentBookAsTitle`（「今の本」）を出す。

## S-5 ロック画面への置き方の案内（シート .medium。AX では .large。整体識別子 `widgetGuide`。AC-96）
```
ロック画面に置く                                                     .headline（widgetGuide.title）
ロック画面を長押しして「カスタマイズ」を選び、時計の下の枠に         .body（widgetGuide.body）
「よむま」を加えると、iPhone を手に取るたびに、この一行が出ます。
                 ［W-1 と同じ部品の見本。172×76 pt］                 widgetGuide.preview
[                         閉じる                          ]          .borderedProminent  widgetGuide.close
```

## S-6 本棚の画面（List .insetGrouped。AC-13, AC-101）
```
< しおり                 本棚                      [plus]   shelf.addBook
今の本                                                      shelf.current
  羅生門                                             >      shelf.row.<id>（.body）
  芥川龍之介                                                （.subheadline 2つ目の色）
  （名無しの今の本 isTitlePending = true は「今の本」widget.currentBookAsTitle）
積読                                                        shelf.tsundoku（積読に加えた日時の新しい順）
  蜜蜂と遠雷 · 恩田陸                                >      shelf.row.<id>
読み終えた                                                  shelf.finished（読み終えた日時の新しい順）
  檸檬 · 梶井基次郎                                  >      shelf.row.<id>
```
- 本0冊のときは `ContentUnavailableView` に `shelf.empty.title`、`shelf.empty.message`、`shelf.empty.addBook` を出す。読み込み失敗のときは `shelf.load.error` と `shelf.retry` を出す。

## S-7 本の画面（List .insetGrouped と、下端の主操作。AC-14〜AC-26, AC-113, AC-146）
縦の線：奥付の名前の列は左 16+16、値の列は名前の列の最長の幅のあと 12。
```
< 本棚                                           [直す]   book.edit
（保存の失敗は画面上部に知らせ common.save.error。AC-91）
───────────────────────────────────────────────            罫線（separator）
書名      蜜蜂と遠雷                                       Grid  book.colophon / colophon.title
著者      恩田陸                                                 colophon.author
出版社    幻冬舎                                                 colophon.publisher（レーベルがあれば「新潮社（新潮文庫）」）
出版年    2016年                                                 colophon.year
受賞      第156回 直木三十五賞、2017年 本屋大賞                  colophon.award（H25 で一致があるときだけ。AC-17〜AC-21）
───────────────────────────────────────────────
[ text.viewfinder 奥付を撮って補う ]                       .bordered  colophon.capture（別名 book.captureColophon。AC-113）
  （カメラ拒否のときはここに camera.denied と camera.openSettings を出す）
記録
  4晩                          合計 1時間25分               book.nights / book.total（AC-22）
  10/17                                   10分   >          book.record.row.<id>（押すと S-7b）
  10/16                                   30分   >
  （記録が0件のときは book.records.empty を1つ出す。AC-23）
この本のあとに（読み終えた本 finished のときだけ、未所有の本を最大5冊。AC-146）  after.header
  夜のピクニック · 恩田陸                                  after.candidate.<ISBNまたは受賞ID>（最大5冊）
  同じ著者の本                                              .subheadline 2つ目の色  after.reason
  [ 積読に加える ]                                         .bordered  after.addToShelf（押すと「積読に加えました」after.added）
[trash この本を消す]                                       role .destructive。文字は本文の色、記号 trash だけ赤  book.delete
──（下端に固定。safeAreaInset）──
[                      この本を読む                        ]   .borderedProminent  book.readThis
（その本が current のときはボタンの代わりに「今読んでいる本です。」 book.isCurrent を出す）
```
- 奥付はデータのある行だけ出し、空の項目や「不明」「なし」「受賞なし」は一切出さない（AC-18）。
- 本を消すときは確認ダイアログに `book.delete.confirm`（記録件数入り）と `book.delete.confirmButton`（「消す」）を出す（AC-16）。
- 別の名無しの今の本（`isTitlePending = true`）があるときに `book.readThis` を押すと、確認ダイアログ `book.pendingTitleGuard`（`book.pendingTitleGuard.setTitle` / `book.pendingTitleGuard.continueAnyway` / `book.pendingTitleGuard.cancel`）を出す。

## S-7a 本を直す画面（シート、Form。S-7 の `book.edit` から。AC-15, AC-141, AC-144）
```
[xmark 取り消す]          本を直す          [checkmark 保存]   book.edit.cancel / book.edit.save
（保存の失敗は Form のいちばん上の行に common.save.error。入れた字は残す。AC-91）
書名      [蜜蜂と遠雷                         ]   book.edit.title
（誤り）exclamationmark.circle 書名は1〜100字で入れてください。  book.title.invalid
著者      [恩田陸                             ]   book.edit.author
（誤り）exclamationmark.circle 著者は100字までで入れてください。  book.author.invalid
書名は1〜100字、著者は100字まで（空でもかまいません）。  book.edit.footer
電子書籍  [Toggle]                                book.edit.isEbook（Toggle）
単位      [ ページ | 位置 | ％ ]                  book.edit.progressUnit（Picker .segmented：page / location / percent の3択）
出版社    [幻冬舎                             ]   book.edit.publisher
レーベル  [幻冬舎文庫                         ]   book.edit.label
出版年    [2016                               ]   book.edit.year（.numberPad、4桁まで）
```

## S-7b 記録を直す画面（シート、Form。S-7 の `book.record.row.<id>` から。AC-24〜AC-26）
```
[xmark 取り消す]          記録を直す          [checkmark 保存]   record.cancel / record.save
（保存の失敗は Form のいちばん上の行に common.save.error。入れた字は残す。AC-91）
晩        10月16日の晩                                       record.night（読むだけ）
分  [30                                ]                    record.minutesField（.numberPad）
1〜1440分                                                   record.minutes.footer
（誤り）exclamationmark.circle 分は1〜1440の数字で入れてください。  record.minutes.invalid
[trash この記録を消す]                                       role .destructive。文字は本文の色、記号 trash だけ赤  record.delete
```
- `record.delete` を押すと確認ダイアログに `record.delete.confirm` と `record.delete.confirmButton`（「消す」）を出す（AC-26）。

## S-7c 奥付を写す画面（シート。S-7 または S-9 の `colophon.capture` から。AC-77, AC-113, AC-140）
```
<                 奥付を撮って補う              [撮り直す]   colophon.retake
（保存の失敗は Form のいちばん上に common.save.error。欄の値は残す）
┌────────────────────────────────────────────────────────────────────────┐
│                ［奥付のカメラプレビュー / 写した奥付］                 │
│  （カメラ拒否時は camera.denied と camera.openSettings を出す）        │
│  （0文字のときは mark.ocr.none と colophon.retake を出す）             │
└────────────────────────────────────────────────────────────────────────┘
拾った奥付（手でそのまま直せます）
  書名      [青を売る                         ]   book.edit.title
  著者      [坂崎かおる                       ]   book.edit.author
  出版社    [祥伝社                           ]   book.edit.publisher
  レーベル  [祥伝社文庫                       ]   book.edit.label
  出版年    [2024                             ]   book.edit.year
  ISBN      [9784396350017                    ]   book.edit.isbn
──（下端に固定。safeAreaInset）──
[                         保存                            ]   .borderedProminent  colophon.save
```
- 画像はメモリ上だけで処理し、保存時・キャンセル時ともにファイルには一切残さない（AC-69、AC-113）。

## S-8 本を加える画面（シート、List。6つの入り口。AC-2〜AC-12, AC-103, AC-137〜AC-140）
```
本を加える                                       [xmark 閉じる]   register.cancel
[barcode.viewfinder   バーコードを続けて読む              > ]    register.barcode（先頭の行。主操作）
  （カメラを断ったとき AC-12）
  exclamationmark.circle カメラの使用が許可されていません。「設定」で許可するか、スクリーンショットから選ぶか、手で入れてください。  camera.denied
  [ 設定を開く ]                                                 .bordered  camera.openSettings
[text.viewfinder      表紙・背表紙を撮る                  > ]    register.cover
[photo.on.rectangle   スクリーンショットから選ぶ          > ]    register.screenshot（PhotosPicker。別名 register.photo）
[books.vertical       本棚・積読をまとめて撮る            > ]    register.bookshelf
[square.and.pencil    手で入れる・書名で探す              > ]    register.manual
[clock                あとで（すぐ読み始める）              ]    register.later（今の本0冊かつ isTitlePending の本0冊のときだけ表示。AC-139）
書誌の検索と文字の読み取りはすべてこの iPhone の中で行い、外部へ送信しません。   節の説明  register.footer（AC-103）
```
- **完全オンデバイス（AC-6、AC-103、判断 30）**：すべての登録経路が端末内書誌 DB（H20、Apple-Hosted Background Assets で配信）と端末内 Vision OCR で完結し、外部 API への HTTP/HTTPS 通信は0件。
- `register.later` を押すと、文字入力なしで `isTitlePending = true` の今の本（表示名 `widget.currentBookAsTitle`「今の本」）が1冊作られ、シートを閉じてその場で S-2（`reading`）が始まる（AC-139）。
- S-1 の `bookmark.setBookTitle` から開いたときは「今の本の書名を入れる」モードになり、選んだ道で入れた書誌で今の本を更新し（`isTitlePending = false`）、新しい本は増やさない（AC-140）。

## S-8a バーコードを続けて読む画面（S-8 の `register.barcode` から。AC-2, AC-3, AC-6, AC-9〜AC-11, AC-92, AC-149）
```
<                 バーコードを続けて読む          [xmark 閉じる]   scan.cancel
（読んだ本が1冊以上の間：< を隠し、シートを払って閉じる操作を止め、xmark を押すと破棄確認 scan.discard.confirm / scan.discard.confirmButton）
［カメラ。DataScanner。画面の高さの半分（AX では3分の1）］         scan.camera
本の裏のバーコード（2段あるときは両方）を写してください。続けて読めます。  scan.hint（まだ0冊のとき）
（知らせ）「こころ」はもう本棚にあります。                         scan.duplicate（保存失敗 common.save.error もここ）
こころ · 夏目漱石 · 新潮社（新潮文庫）                             scan.row.9784101000015（端末内書誌 DB H20 から 0.3秒以内に即解決）
ISBN 9784087000023
  端末内の書誌データを準備中です。この場で書名を入れるか、表紙を撮って加えられます。  scan.row.9784087000023 / scan.dbNotReady（AC-9）
  書名 [こころ                               ] (scan.row.editTitle)   [ 表紙・背表紙を撮る ] (scan.row.captureCover)
ISBN 9784003101018 · 岩波書店（文庫）
  端末内の書誌データにない本です。この場で書名を入れるか、表紙を撮って加えられます。  scan.row.9784003101018 / scan.notFound（AC-10, AC-11）
  書名 [青を売る                             ] (scan.row.editTitle)   [ 表紙・背表紙を撮る ] (scan.row.captureCover)
──（下端に固定。safeAreaInset）──
[                   3冊を本棚に加える                      ]       .borderedProminent  scan.addToShelf（0冊のときは scan.addToShelf.none 無効）
```
- 端末内の書誌 DB（H20）からオフラインで 0.3秒以内に引き、外部への通信は一切行わない（AC-2、AC-6、AC-103、AC-149）。
- 2段目の日本図書コード（`192` で始まる13桁）が読めたときは単独の行にはせず、直前の ISBN の行の判型（「文庫」など）を補い、DB 未収録時は同梱の出版社記号辞書から出版社名（「岩波書店」など）も補う（AC-3、AC-11）。
- DB 未取得（`scan.dbNotReady`）または DB 未収録（`scan.notFound`）の行には、その場で書名を入れる欄 `scan.row.editTitle` と表紙撮影へ進むボタン `scan.row.captureCover`（→ S-8b）を行の中に出す（AC-9、AC-10）。

## S-8b 表紙・背表紙・スクリーンショットから選ぶ画面（S-8 の `register.cover` / `register.screenshot` から。AC-137）
```
<                 表紙・背表紙から選ぶ            [撮り直す]   cover.retake
（保存の失敗は欄の上に common.save.error。入れた字は残す）
1回目に押した行が「書名」、2回目に押した行が「著者」に入ります。     .subheadline 2つ目の色  cover.hint
┌────────────────────────────────────────────────────────────────────────┐
│         ［撮った表紙・背表紙またはスクリーンショットの静止画］         │
│         ┌────┐   ┌──────┐   ┌────┐                                     │
│         │(3) │   │ (2)  │   │(1) │  ← 白黒2重枠（外 2pt 黒、内 2pt 白）│
│         │ 夏 │   │ ここ │   │ 新 │    cover.ocr.line.1 / .2 / .3       │
│         │ 目 │   │ ろ   │   │ 潮 │    1タップ目に [書名] cover.selectTitle │
│         │ 漱 │   │ [書名]│   │ 文 │    2タップ目に [著者] cover.selectAuthor │
│         │ 石 │   └──────┘   │ 庫 │    の役割札が付く                   │
│         │[著者]│             └────┘                                     │
│         └────┘                                                         │
└────────────────────────────────────────────────────────────────────────┘
書名      [こころ                           ]   manual.title（手で直すこともできる。誤りは book.title.invalid）
著者      [夏目漱石                         ]   manual.author（誤りは book.author.invalid）
電子書籍  [Toggle]                              manual.isEbook（Toggle）
[ 撮り直す ] (cover.retake, .bordered)    [ 手で入れる ] (register.manual, .bordered)
──（下端に固定。safeAreaInset）──
[                         保存                            ]   .borderedProminent  cover.save
```
- 0文字のときは `ContentUnavailableView` で `mark.ocr.none` と `cover.retake`、`register.manual` を出す。画像は一切保存しない（AC-69、AC-137）。

## S-8c 手で入れる・書名で探す画面（インクリメンタル検索統合画面。S-8 の `register.manual` から。AC-4〜AC-8, AC-141, AC-149）
```
[xmark 取り消す]      手で入れる・書名で探す      [checkmark 保存]   manual.cancel / manual.save
（保存の失敗は Form のいちばん上の行に common.save.error。入れた字は残す。AC-91）
書名      [人間失格                         ]   manual.title（別名 manual.searchField。焦点。3字以上で端末内書誌 DB H20 を 0.3秒以内に即時検索）
（誤り）exclamationmark.circle 書名は1〜100字で入れてください。  book.title.invalid

候補（端末内の書誌データ H20 から最大20件。押すと下の各欄に書名・著者・出版社・レーベル・出版年・ISBN が入る。AC-4）
  人間失格 · 太宰治 · 新潮社（新潮文庫） · 2006              search.row.9784000000048（別名 manual.candidate.9784000000048）
  人間失格 · 太宰治 · KADOKAWA（角川文庫） · 1989  checkmark  search.row.9784040000053（選んだ候補。.isSelected）
  人間失格 · 太宰治 · 中央公論新社 · 2019                    search.row.9784120000065
（候補が0件のとき AC-5）
  「あいうえおかきくけこ」に合う候補は書誌データにありませんでした。このまま保存できます。  search.noResults
（端末内書誌 DB が未取得 notDownloaded のとき AC-11）
  端末内の書誌データをまだ取得していません。通信できるときに取得します。  catalog.status（別名 settings.h20Status）
  [ 書誌データを今すぐ取得する ]                             catalog.retry（別名 settings.h20Retry）

著者      [太宰治                           ]   manual.author
（誤り）exclamationmark.circle 著者は100字までで入れてください。  book.author.invalid
書名は1〜100字、著者は100字まで（空でもかまいません）。  manual.footer
電子書籍  [Toggle]                              manual.isEbook（Toggle）
単位      [ ページ | 位置 | ％ ]                mark.progressUnit（Picker .segmented：page / location / percent の3択）
```
- **インクリメンタル検索と手入力の統合（AC-4〜AC-8、AC-149、判断 27）**：別の検索画面に分けず、書名欄 `manual.title`（別名 `manual.searchField`）に3字以上入れると端末内の書誌 SQLite DB（H20、FTS5 trigram）から 0.3秒以内に候補行 `search.row.<ISBN>`（別名 `manual.candidate.<ISBN>`）が出る。候補を押して `manual.save` で保存することも、候補を選ばずに手入力のまま `manual.save` で保存することもできる。外部への通信は0件（AC-6、AC-103）。

## S-8d 本棚・積読の写真から複数冊を選ぶ画面（S-8 の `register.bookshelf` から。AC-138）
```
<                 本棚・積読から選ぶ
（保存の失敗は一覧の上に common.save.error。選んだ行は残す）
加えたい本の背表紙の枠を押してください。何冊でも選べます。           .subheadline 2つ目の色  bookshelf.hint
┌────────────────────────────────────────────────────────────────────────┐
│       ［撮った本棚・積読の静止画（背表紙の行に白黒2重枠と番号）］      │
│         r1「こころ」  r2「人間失格」  r3「羅生門」  r4「新潮文庫」     │
└────────────────────────────────────────────────────────────────────────┘
選んだ本（押した枠の分だけ行が増え、書名を手で直せます）
  (1) [こころ                 ]                                      bookshelf.row.1（DB に複数件あるため書名のみ）
  (2) [人間失格               ]                                      bookshelf.row.2
  (3) [羅生門                 ]  芥川龍之介 · 新潮社                 bookshelf.row.3（端末内書誌 DB H20 で1件完全一致のため著者・出版社・ISBN 自動補完）
──（下端に固定。safeAreaInset）──
[                 選んだ3冊を積読に加える                  ]         .borderedProminent  bookshelf.addSelected
```
- 背表紙の自動分割には頼らず、利用者が押した背表紙の枠の数だけ候補行 `bookshelf.row.<n>` が増える。端末内書誌 DB（H20）で完全一致が1件の本だけ著者・出版社・ISBN を自動補完する（AC-138）。画像は一切保存しない（AC-69）。

## S-9 読み終えた画面（シート .large。1つのスクロール。AC-77〜AC-87, AC-113, AC-127〜AC-129, AC-147, AC-148）
縦の線：左 16（見出し、ふりかえり、奥付、カード共有、次の1冊）、16〜377（ボタン）。
```
[xmark 閉じる]                                              finish.close
読み終えました                                              .largeTitle  finish.title
6晩、合計142分（2時間22分）。いちばん長かったのは10月15日の晩の38分でした。
                                                            .body        finish.reflection（文言キー finish.reflection.multi。AC-127）
（1晩だけのときは finish.reflection.single：「1晩、30分で読み終えました。」AC-128。記録0件のときは非表示 AC-129）
───────────────────────────────────────                     finish.colophon（S-7 と同じ奥付の型。AC-77）
書名      蜜蜂と遠雷                                        colophon.title
著者      恩田陸                                            colophon.author
出版社    幻冬舎                                            colophon.publisher
出版年    2016年                                            colophon.year
受賞      第156回 直木三十五賞、2017年 本屋大賞             colophon.award
───────────────────────────────────────
[ text.viewfinder 奥付を撮って補う ]                        .bordered  colophon.capture（押すと S-7c。AC-77, AC-113）
[ square.and.arrow.up 読み終えのカードを共有 ]              .bordered  finish.card.share（書名・著者・何晩・合計時間だけの PNG 画像。一行とふりかえりは載せない。AC-84, AC-85）
                                                            space.24
次の1冊                                                     .headline  next.header
積読と、この本につながる本から選んでいます。                .footnote 2つ目の色  next.subheader
  （候補は最大3冊：自分の積読 tsundoku が先、足りない枠に端末内書誌 DB H20・受賞 H25・共起テーブルの未所有の本。AC-78〜AC-80, AC-87, AC-147, AC-148）
  獣の奏者                                                  .headline  next.candidate.<id>
  上橋菜穂子                                                .subheadline
  積読から・同じ著者                                        .subheadline 2つ目の色  next.reason
  [ この本を読む ]                                          .bordered  next.choose（押すと current になり S-1 へ。AC-82）
  ─────────────────────────────────────
  鹿の王 2                                                  .headline  next.candidate.9784041026000
  上橋菜穂子 · KADOKAWA（角川文庫）                         .subheadline
  シリーズの次の巻                                          .subheadline 2つ目の色  next.reason（共起なら「この本を読み終えた人が、次に読んだ本」rec.reason.readers、人数は出さない AC-148）
  [ 積読に加える ]                                          .bordered  next.addToShelf（押すと tsundoku に加わり「積読に加えました」next.added。AC-83, AC-87）
  （積読も未所有の候補も0件のときは ContentUnavailableView に next.empty.message と [ 本を加える ] next.addBook を出す。AC-81）
                                                            space.16
[ 今は読まない ]                                            .bordered  next.skip（見送って S-9 を閉じ、今の本0冊になる。AC-147）
まだ読み終えていなかったときは、本棚でこの本を開き、        .footnote 2つ目の色  finish.undoNote
「この本を読む」を押すと戻せます。
```

## S-10 設定の画面（Form。AC-34, AC-37, AC-38, AC-51, AC-88, AC-92, AC-93, AC-105, AC-108）
```
< しおり                    設定                             settings.navTitle
読み始めと夜の入口                                           settings.section.start
  伏せて始める                                    [Toggle]   settings.flipToStart
  しおりの画面で iPhone を伏せて置くと、読書が始まります。…  settings.flipToStart.footer
  （伏せ検知非対応端末 H18 では settings.flipToStart.unavailable を出す。AC-51）
  夜の入口の時刻                                  [21:00]    settings.entryTime（15分刻み：00 / 15 / 30 / 45分。AC-38）
  この時刻になると、ロック画面に今の本の続きの一行が出ます。 settings.entryTime.footer
  （OS の Live Activity がオフ areActivitiesEnabled == false のとき AC-37：
    ロック画面の「ライブアクティビティ」がオフになっているため、夜の入口の時刻の表示は出ません。…  settings.liveActivity.off）
ロック画面                                                   settings.section.lockScreen
  一行と書名を隠す                                [Toggle]   settings.hideOnWidgets（AC-34）
  ロック画面とホーム画面のウィジェット、およびライブアクティビティに一行と書名を出さず、「しおり」と場所だけを出します。…
見た目と購入                                                 settings.section.appearance
  見た目                                  標準（白と黒） >   settings.appearance（押すと S-10a。AC-105）
  購入を復元する                                             settings.restorePurchases（AC-108。結果は知らせ store.restore.done / store.restore.none）
書誌データ                                                   settings.section.catalog
  端末内の書誌データ（2026-10版）は準備できています。        catalog.status（別名 settings.h20Status。未取得時は catalog.status.notDownloaded）
  [ 書誌データを今すぐ取得する ]                             catalog.retry（別名 settings.h20Retry。未取得時に表示。AC-11, AC-92）
情報                                                         settings.section.info
  プライバシーポリシー                     arrow.up.forward  settings.privacyPolicy（Link。AC-88）
  書誌の出どころ                                             settings.dataSources.header（.body）
  書誌（書名、著者、出版社など）は、国立国会図書館書誌データ（「国立国会図書館蔵書」「国立国会図書館新着書誌情報」「全国書誌情報」、データ提供機関：国立国会図書館、取得日：2026-10-01）を出典とし、国立国会図書館サーチの API を用いて取得したデータをこのアプリで加工して端末内の書誌データベース（版：2026-10）を作成しています。ライセンスはクリエイティブ・コモンズ 表示 4.0 国際 パブリック・ライセンス（CC BY 4.0）です。なお、「この本を読み終えた人が、次に読んだ本」の候補は、利用者の同意のもとで集計した読書順序データに基づくもので、国立国会図書館のデータとは無関係です。
                                                             settings.dataSources（.footnote 2つ目の色。NDL CC BY 4.0 の3条件＋版＋共起免責。AC-93）
  ライセンス（CC BY 4.0）                  arrow.up.forward  settings.dataSources.license（Link。https://creativecommons.org/licenses/by/4.0/ を開く。AC-93）
```

## S-10a 見た目と「よむま＋」の画面（一覧と買い切り購入シート。AC-105〜AC-111）
```
< 設定                      見た目
  標準（白と黒）                                 checkmark   appearance.row.default（無料）
  生成り                                         lock        appearance.row.kinari（よむま＋。購入済みなら lock なし）
  墨                                             lock        appearance.row.sumi（よむま＋）
  朱                                             lock        appearance.row.shu（よむま＋）

──（未購入で鍵つきの行 kinari / sumi / shu を押したときに出る購入シート AC-105）──
よむま＋（買い切り）                             [xmark 閉じる]   store.product.title / store.close
生成り・墨・朱の3つの見た目を、しおりの画面、ウィジェット、       .body  store.product.description
読み終えのカードで使えます。1回の購入でずっと使えます。
┌────────────────────────────────────────────────────────────────────────┐
│           ［選んだ見た目（kinari / sumi / shu）の見本］                │  store.preview（accessibilityValue は選んだ見た目の id）
│        しおりの画面（S-1）とウィジェット（W-1）が実際の色で出る        │
└────────────────────────────────────────────────────────────────────────┘
（購入失敗のときはここに store.purchase.error、通信なしのときは store.offline、支払い制限端末では store.unavailable を出す。AC-107, AC-109, AC-110）
──（下端に固定。safeAreaInset）──
[                よむま＋を買う（¥980）                    ]  .borderedProminent  store.buy（Product.displayPrice を出す。基準価格 ¥980。AC-105）
[                     購入を復元する                       ]  .bordered           store.restore
```

## 部品 N 知らせの帯（非モーダルな1行バナー）
```
[info.circle  1分未満の読書は記録に残しません。                 [ 閉じる ]]   notice / session.tooShort / notice.close
```
- エラーのときだけ記号が `exclamationmark.circle`（赤 `color.state.error`）で、文字は常に本文の色（`color.text.primary`）。S-2 の `session.save.error` では `[ 閉じる ]` を置かない。
- 閉じる（`notice.close`）は `.bordered` の小さいボタン（押せる範囲は 44×44pt 以上）。読み上げは「閉じる」、ヒント「知らせを閉じます。」。
- 画面の内容のいちばん上（ナビゲーションバーの下、左右 16）に出す（S-2 と S-8a〜S-8d の保存失敗は下端ボタンのすぐ上）。出たときに VoiceOver の読み上げを1回送り、閉じるか次の操作まで勝手に消さない。
