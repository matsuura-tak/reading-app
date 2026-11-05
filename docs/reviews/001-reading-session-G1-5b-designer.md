（指揮役の注）G1 の 5b（芯の画面の仕様）の、designer の報告。tech-lead、pdm、verifier への申し送りと未決を、判定と次の段で使うため保存した。判定ではない。報告の文はそのまま保存した。

## 変更したファイル
- /Users/takumamatsuura/reading-app/design/001-reading-session.md（新規、804行）：芯の画面の仕様。中身は次のとおり。
  - 0 範囲：芯の 19 画面と部品 N（知らせの帯）、選択肢の置き場所、選択肢がないときの形、確かめ中と結果待ち。
  - 1 画面の流れ。
  - 2 AC 136件の対応表。
  - 3 画面ごとの仕事、主操作、標準部品、標準から外れる所。
  - 4 決定 57行。
  - 5 7つの状態（20行）、長い文字と件数、3b が届かないときの差分。
  - 6 識別子とラベル。
  - 7 日英の文言 174行と、カメラの許可の理由の文。
  - 8 見た目、9 アクセシビリティとコントラスト、10 未決、確かめ（印あり）。
- /Users/takumamatsuura/reading-app/design/001-reading-session/tokens.md（新規）：色、文字、余白、角・影・素材・動き、触覚のトークン。独自の色はライト、ダーク、コントラストを上げる設定の値つき。
- /Users/takumamatsuura/reading-app/design/001-reading-session/screens.md（新規）：画面ごとの並びを文字で描いた図。縦の線、text style、識別子、S-1 のほかの形と AX5 の形を入れた。
- /Users/takumamatsuura/reading-app/design/001-reading-session/candidate-A-flip.md と candidate-A-flip.svg を消した。2026-10-16 の、前の製品の形のときの比べの図です。今の調査と R 番号の意味が合わないので、screens.md に置き換えました（git に残っています）。
- コミットはしていません。調査は f8ed008（2026-10-19 23:21）に入っています。仕様はまだコミットしていないので、コミットすれば調査より後になります。

## 数
- 芯の AC：85件。画面と操作がある 85件、ない 0件。
- 選択肢として残した AC：51件。指示書の分け方と照らして、差は0件です。
  - (課金) AC-104〜AC-111
  - (3) AC-84、AC-85、AC-127〜AC-129
  - (4) AC-19〜AC-21、AC-83、AC-112
  - (5) AC-36〜AC-38、AC-41、AC-97、AC-98、AC-114〜AC-120、AC-130〜AC-132、AC-136
  - (ショートカット) AC-121〜AC-124、AC-133〜AC-135
  - (6) AC-65〜AC-70、AC-94
  - (5) と (ショートカット) の両方にまたがるもの：AC-125、AC-126

## 実行したコマンドと結果
- 開いた URL：HIG の10ページを `curl` で開きました（`https://developer.apple.com/tutorials/data/design/human-interface-guidelines/<ページ>.json`）。どれも HTTP 200 で、開けなかったものはありません。
  - ページ：buttons、sheets、alerts、action-sheets、toolbars、lists-and-tables、text-fields、search-fields、loading、toggles。
  - 本文を python で取り出し、引用を仕様の 8 に書きました。
  - 調査の R の URL は、開き直していません。
- ガードに2回止められました。書き先のパスに `$` 変数があったためです。パスをそのまま書いて、やり直しました。
- `scratchpad/g1-design-spec/scripts/contrast.py`（WCAG の相対輝度の式）の出力の要点：
  - secondaryLabel はライトで #FFFFFF の上 3.44:1、#F2F2F7 の上 3.29:1 で、4.5:1 に届きません。このため独自のトークンにしました。
  - color.text.secondary：5.23 / 7.33 / コントラストを上げる設定でライト 9.12・ダーク 12.47（Form の地の上では 4.69 / 5.94 / 7.27・9.20）。
  - 主操作の文字と地：17.01 / 18.82 / 21.00。
  - .bordered（塗りが15%という想定）：12.53 / 9.85 / 14.88・9.57。
  - systemRed の記号：3.55 / 6.16 / 5.38・7.45。小さい文字に使うと 3.55:1 で届かないので、記号だけに使います。
  - 基準に届かない独自の組は0件です。
- `scratchpad/g1-design-spec/scripts/check.py` の出力：
  - `PRD AC 136 / mapped 136 / missing [] / extra [] / dup []`、`options 51 / diff vs brief []`、`core 85 / core rows without a screen code []`
  - `research R 35 1 - 35 / spec R not in research []`、`decision rows 57 / rows without R [] / rows without principle []`
  - 画面の行 20、状態の行 20、文言の行 174 で、どれも空の欄は0件です。表の列の数がずれている行も0件です。
  - 仮の名前「しおりどき」は0回、絵文字も0個です。
  - PRD にあって仕様にない識別子は、選択肢のもの（intent.*、store.*、mark.ocr.*、liveActivity.*、finish.reflection.* など）と、H7 の失敗させる対象の名前（book.add など）だけでした。
- `git log -- design/001-reading-session-research.md` の出力は `f8ed008 2026-10-19 23:21:41`。仕様はまだコミットしていません。

## 未解決
1. **Takuma に確かめ中（推奨で進めた）**
   - 見た目の方向（案A）と、S-1 の2つのボタンを画面に出しておくことです。仕様の決定 1 と 4 に書きました。
   - メニューに入れる答えになったら、AC-42 の「メニュー0個」とぶつかります。置き場所を一緒に決め直す必要があります。
2. **結果待ち**
   - Q-A：`bookmark.flipHint` の文を2つ用意しました。
   - 1b、2b、1c：S-3 の主の道です。今は「一行を入れる」を主にしてあり、2b が届かなければ入れ替えます。
   - 3b：S-9 です。届かないときの差分は 5 に書きました。
   - 3d と G4-1（ロック画面の vibrant の色と太さ）も結果待ちです。
3. **tech-lead に決めてほしいこと**
   - `settings.dataSources` の日英の文字列（G1-5）。
   - `.searchable` の欄に識別子 `search.field` を付けられるか。今は TextField で代えています。
   - 縦書きの組みの作りと、W-1 の内側の余白（余白なしは［推測］）。
   - S-6 の「読み終えた」を並べる日時。
   - コントラストを上げる設定の背景の実際の値（想定が3つあります）。
   - 書名で探すときの、1回の問い合わせで返る件数。
   - Button の role の .close と .confirm を使えるか（iOS 26 にあるとみていますが、確かめていません）。
4. **pdm に伝えること**
   - 英語の表示名が決まっていません。仮に Yomuma と書きました。
   - PRD 17 の審査メモのボタンの名前を、仕様の文（「一行を入れる」）に合わせる必要があります。
   - S-3a でページを空のまま保存すると、ページを空にするようにしました。これは PRD の AC にない入力の決まりです。
   - G1-13（ラテン文字の著者が「Fox Susan」と出る）は、このままにするのが designer の推奨です。
5. **verifier に伝えること**
   - 足した識別子は 6 に書きました。
   - `bookmark.page` と `result.summary` は、見た目の文字と読み上げの文が違います。テストは値で比べてください。
   - 知らせの帯の識別子は `notice` で、中の文の要素は文言キーと同じ名前です。
   - S-1 に知らせかシートが出ている間は、伏せる道を止め、伏せる案内も出しません。AC-47 をこう読んだためです。
6. **申し送りのうち、今回描いていないもの**：G1-7、G1-8、G1-15 は選択肢の仕様で決めます。
7. **設定の「3つ」**：芯の設定は切り替えが2つです。入口の時刻は (5) の選択肢なので、置き場所だけを書きました。
8. **自分で気づいた心配**：ダークでは S-2 の「終える」が白い地のボタンになります。暗い部屋でまぶしいおそれがありますが、ほかの画面とそろえて、このままにしました。
9. **調査に足りない所**（仕様では新しい R を作っていません）
   - HIG の10ページは、原則の欄にだけ使いました。
   - 競合が毎晩の画面にボタンをいくつ置いているかの数えは、調査にありません。
10. **確かめの印**：芯の範囲ではすべて付けました。次の2つは、ほかの役の答え待ちという注を付けています。
    - コントラストを上げる設定の背景が想定の値であること。
    - `settings.dataSources` の文が ADR 待ちであること。

## 記録（指揮役が保存するときに書き足す）
- 種類：作り手（designer）の報告（判定ではない）
- 書いた物：design/001-reading-session.md、design/001-reading-session/tokens.md、design/001-reading-session/screens.md（コミット 4b947e8）。前の図 candidate-A-flip.md と .svg を消した
- 日付：2026-10-19
- 指揮役が確かめたこと：作り手が触ったのは design/ の中だけ。調査（f8ed008、23:21）が仕様（4b947e8、23:57）より前のコミットにある。仕様の決定 1 と 4 の「Takuma に確かめ中」は、Takuma が推奨どおりに決めた（docs/approvals/001-reading-session-G1-decisions.md）ので、次の直しで替えさせる
