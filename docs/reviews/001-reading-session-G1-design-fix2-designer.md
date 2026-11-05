（指揮役の注）G1 の 7（tech-lead の設計、spike、書誌の確かめ）で分かったことを仕様に入れた、designer の直しの報告（裁定 28）。tech-lead と verifier への申し送りを残すため保存した。判定ではない。報告の文はそのまま保存した。

## 要約
14件すべてを扱いました。直したのは許された3ファイルだけで、コミットはしていません。未着手はありません（手数は36回）。
- 新しく決めたことは、決定の表に 62〜65 の4行として足しました。どの行にも R-n と原則があります。
- 方向、範囲（芯）、AC は変えていません。識別子と文言キーも足していません。

## 扱いの表
| # | 申し送り | 扱い | 直した所 |
|---|---|---|---|
| 1 | 帯の幅 | 直した。帯は 43pt（実測、ADR 0003）。仕様 9 の余りを新しい値にした：172×76 は 15pt で余り 35.0（列が1つ増えると 16.25）、153×68 は 13pt で余り 28.0（11.75）。字の大きさは前と同じ | tokens の「縦書きの組み」、仕様の決定 8 と 9、screens の W-1 |
| 2 | 置き換えの表 | 直した（決定 63）。<br>・7-3 で足された6行を写した。<br>・「：」「；」は90度回す。縦書き用の字形がフォントになく、立てたままの「：」は縦書きの「‥」（︰）と同じ形になるため。<br>・全角に直した「－」は回す。「＝」「＜」「＞」「｛」「｝」「｜」「＿」も回す。立てたままだと「－」は「一」、「＝」は「二」と同じ形になるため。<br>・「，」「．」は回さず、小さい仮名と同じ方法で、フォントの縦書き用の字形の位置（右上）へずらす。<br>・半角の印字できる字（U+0021〜007E）は全部全角に直す。<br>・根拠は Unicode の VerticalOrientation.txt（UAX #50）と R-30 | tokens の表、仕様の決定 6 と 63 |
| 3 | 行頭の禁則 | 直した（決定 62）。<br>・JLREQ 3.1.7 の類を全部入れた：「！」「？」「・」「々」と、小さい仮名22字。<br>・同じ類の「：」「；」「，」「．」「｝」「ゝ」「ゞ」「ヽ」「ヾ」と、ハイフン（‐ ゠ – 〜 ～）も入れた。<br>・理由：AC-28 は「ー」を禁則にしている。JLREQ では「ー」「々」と小さい仮名は、行頭に許すゆるい決まりの同じ組なので、そろえた | tokens の禁則の一覧、決定 62 |
| 4 | W-2 の列とページの間 | `space.4` に決めた（R＝20pt）。`space.8` にすると、148pt の枠で25字が 19pt から 18pt に下がる | tokens の余白の表と組みの節、決定 8、仕様 8 と 9 |
| 5 | screens の W-2 の図 | 直した。列は上にそろえ、170pt の枠では 20pt で1列5字。例の一行は3列 | screens の W-2 |
| 6 | S-1 の A_w、A_h | 決めた（決定 64）。<br>・A_w＝画面の幅−32（393pt で 361）、A_h＝⌊画面の高さ×0.4⌋（852pt で 340）。<br>・28pt で1列12字。<br>・375×667pt の画面で 34pt のときだけ横書きになる | 決定 64、仕様 9、tokens、screens の S-1 |
| 7 | アプリが動いているときに URL が来たとき | 決めた（決定 65）。<br>・シート、全画面の流れ（S-2〜S-4）、確認のどれかが開いていれば、画面は何も変えない。<br>・どれも開いていなければ、押し出した画面（S-6、S-7、S-10）を動きなしで閉じて S-1 にする。<br>・どちらでも、保存を変えず、知らせ、確認、alert を出さない | 仕様 1 の「起動」、AC-40 の行、決定 9 と 65 |
| 8 | 小さい仮名と「ー」の位置の注 | 直した。<br>・小さい仮名は、フォントの縦書き用の字形と同じ位置へ字ごとにずらす。<br>・「ー」は回したあと、0.05em 左へ寄せる | tokens の表、決定 6、screens の W-1 と W-2 |
| 9 | `settings.dataSources` の文 | ADR 0004 の日英の文を、スクリプトでそのまま写した。一致はプログラムで確かめた。<br>ライセンスの開く先も書いた：日本語は deed.ja、英語は /by/4.0/ | 仕様の 6、7、10、確かめ、screens の S-10 |
| 10 | S-8b の結果 | 確かめて、書き足した。<br>・画面の並びは ADR 0004 の並べ直しの順のまま。画面では並べ替えず、並べ替えの操作も置かない。<br>・cnt=200 で最大約200行。<br>・読み込みは実測 5.70秒、30秒で打ち切ると `search.error` | 決定 27、5 の表と「とても多いとき」、screens |
| 11 | `widget.unavailable` | 文言の表（7）に日英で前からあった。文は変えていない。<br>・7 の「使う場所」に、読み上げのラベルも同じ文だと足した。<br>・6 の W の行に「写しを読めない」を足した。<br>・H22 の例の仮の文字は contracts にあるので、私は触れていない（tech-lead へ） | 仕様の 6、7 |
| 12 | AC-95 の言い方 | 「Form のいちばん上の行」にそろえた | 仕様 2 |
| 13 | W-1、W-2 の読み上げのラベル | 判断を書いた。ラベルは変えていない。<br>・ラベルは書名から始める（決定 60 の例外）。AC-99 は書名を「含む」ことだけを求め、順は決めていない。一行だけではどの本か分からないため。<br>・見える一行とページの値はラベルに入るので、WCAG 2.5.3 は満たす | 仕様 9 の読み上げ順、6 |
| 14 | ダークの .bordered | 注を足した：G3 でダークの S-1 のスクリーンショットを見て、2つのボタンが押せる形に見えるかを確かめる | 仕様 9、10 の verifier の項 |

## 変更したファイル
- /Users/takumamatsuura/reading-app/design/001-reading-session.md
  - 1、2、決定 6〜9 と 27 を直し、決定 62〜65 を足した。
  - 5（W-2 と S-8b）、6、7、8 の余白、9（読み上げ順、.bordered の注、組みの計算を 43pt と W-2 と S-1 で書き直し）、10、確かめを直した。846行から864行。
- /Users/takumamatsuura/reading-app/design/001-reading-session/tokens.md
  - 帯 43pt、W-2 の R、S-1 の縦書きの場所、禁則の一覧、置き換えの表（足した6行、回す記号、ずらす「，」「．」、半角の行を1つに）、`space.4` の使い所。
- /Users/takumamatsuura/reading-app/design/001-reading-session/screens.md
  - W-1 の帯、W-2 の図を作り直した、S-1 の場所、S-8b、S-10 の書誌の出どころ。

## 実行したコマンドと結果
- 開いた URL（どちらも開けた。開けなかった URL はない）
  - `curl https://www.unicode.org/Public/UCD/latest/ucd/VerticalOrientation.txt` → HTTP 200、192064 バイト、版は 18.0.0。
    - FF0C は Tu、FF0D は R、FF0E は Tu、FF1A〜FF1B は Tr、FF1C〜FF1E は R。
    - FF3F、FF5B〜FF5E は Tr、30FC は Tr、FF01 と FF1F は Tu、30FB は U。
  - `curl -L https://www.w3.org/TR/jlreq/` → HTTP 200。3.1.7 から引いた文：
    - 「In principle, no line should begin with closing brackets (cl-02), hyphens (cl-03), dividing punctuation marks (cl-04), middle dots (cl-05), full stops (cl-06), commas (cl-07), iteration marks (cl-09), a prolonged sound mark (cl-10), small kana (cl-11)…」
    - 注：「Not a small number of books adopt a less strict set of rules which allow … "々" …, prolonged sound mark (cl-10) and small kana (cl-11) to start a line.」
  - 最初の curl は、cd の行き先に $ があってガードに止められました。迂回ではなく、絶対パスで書き直して実行しました。
- `python3 -I …/py/fit.py`（帯 43、g 4、W-2 の i 16 と R 20、25字）
  - W-1：172×76 は 15pt 余り 35.0、列が1つ増えると 16.25、2つ増えると 14pt。153×68 は 13pt 余り 28.0、列が1つ増えると 11.75、2つ増えると禁則をゆるめて組む。
  - 列の間 0.5 倍：153×68 で列が1つ増えると入らない（110.5＞106）。
  - W-2：R＝20 では 170pt が 20pt、148pt が 19pt（列が増えると 16pt）。R＝24 では 148pt が 18pt に下がる。
  - S-1（393×852）：A_w 361、A_h 340。25pt で1列13字、28pt で12字、34pt で10字。375×667 の 34pt は横書きになる。
- `python3 -I …/py/edit.py …`
  - dry run ですべての置き換えが1か所ずつ当たったのを見てから書いた。3ファイルとも changed。
  - そのあと決定 63 の言い方を1か所、小さく直した。
- `python3 -I …/py/check.py …` の出力
  - `decisions: 65 numbers 1..N sequential: True`
  - `R in research: 35 | R used in decisions: 31 | problems: []`
  - `5 states: rows=20 wrong-columns=[]`、`empty cells in 5: []`
  - 6、7、2、tokens の表は、どれも列数のずれ0。
  - `settings.dataSources ja == ADR: True | en == ADR: True`
  - 6 にも 7 にもない参照は4つ：`book.record.row.<id>`、`mark.page.placeholder.previous`、`next.candidate.<id>`、`store.preview`。HEAD でも同じ数あり、前からあるものです。
  - トークンの参照の漏れは0。
  - 古い文の残りは「38〜40」と「仮の文」の2つ。どちらも意図した経緯の文で、残りは0。
- `git status --short`：変わったのは design/ の3ファイルだけ（+102 −61）。

## verifier への申し送り
- AC-28 の L を出す一行と (4)〜(6) の一行で、L＋1 字目のほかの「列の頭に来うる所」に、広げた禁則の字（小さい仮名、「々」「・」「！」「？」など）を置かないでください。置くと追い出しが増え、字の大きさか L が変わります。W-2 の 148pt は、追い出しがあると 19pt から 16pt に下がります。
- 決定 65（アプリが動いているときの URL）は AC ではありません。AC-40 は、プロセスのない起動のままでよいです。
- G3 で、ダークの S-1 のスクリーンショットを残してください。
- `settings.dataSources` は ADR 0004 の文になりました。ライセンスの開く先は、日本語が deed.ja です。
- S-8b は最大で約200行、並びは ADR 0004 の順です。

## tech-lead への申し送り
- ADR 0003 に写してほしいもの
  - 置き換えの表：「：」の行を「そのまま立てる」から「回す」に替える。「；」「－」「＝」「＜」「＞」「｛」「｝」「｜」「＿」を回す行を足す。「，」「．」をずらす行を足す。
  - 禁則の一覧（決定 62）。
  - W-2 の R＝20（［designer に確かめる］は外せます）。
  - S-1 の A_w と A_h（［未決］は外せます）。
- 「，」「．」のずらしは、ヒラギノで Core Text が FF0C と FF0E の縦書きの位置を返すかを、まだ確かめていません。返さなければ立てたままになります。最初のビルドで確かめてください。
- contracts/entry-urls.md の 3 の「決まっていないこと」は、決定 65 です。
- H22 の例の仮の文は、7 の `widget.unavailable` の文に替えられます。

## 未解決
1. reviewer が設計の判定を並べて行っている間に design/ を直しました。判定が直す前の版を見ている恐れがあります。
2. 禁則を厳しい決まりにしたのは見た目の判断です。小さい仮名と「々」を列の頭に許すゆるい決まりに戻すなら、表を直すだけで元に戻せます。反論があれば Takuma に回してください。
3. 回した「：」「－」などと、ずらした「，」「．」の位置は、まだ測っていません。G3 のスクリーンショットで見ます。
4. VerticalOrientation.txt は調査の R にしていません（調査は範囲の外）。決定 63 の R は R-30 だけです。
5. S-8b の「手で入れる」は約200行のいちばん下に残しました。戻って S-8 から入れる道（2タップ）があります。遠すぎるかは、design-reviewer の判断に任せます。
6. S-1 の式は縦向きを前提にしました。横向きに対応するかは仕様にありません。
7. iOS 26 の色の値（G1-3）は前のとおり残っています。

作業メモとスクリプト（リポジトリの外）：
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-design-fix2/notes.md
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-design-fix2/py/fit.py
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-design-fix2/py/edit.py
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-design-fix2/py/check.py

## 記録（指揮役が保存するときに書き足す）
- 種類：作り手（designer）の報告（判定ではない）
- 直した物：design/001-reading-session.md、tokens.md、screens.md（コミット bbc61cb）
- 日付：2026-10-20
- 指揮役が確かめたこと：作り手が触ったのは design/ の3ファイルだけ。直しは reviewer の設計の判定（r1）と並べて行った。r1 は直す前の仕様を入力にしていたが、判定した物（設計メモ、契約、ADR）は変わっていない
