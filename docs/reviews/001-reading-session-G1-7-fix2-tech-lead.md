（指揮役の注）仕様の決定 66（書名のない今の本のウィジェット）を契約と設計メモに写した、tech-lead の報告。判定ではない。報告の文はそのまま保存した。

決定 66 の中身を4ファイルに写しました。書名のない今の本のウィジェットについて、題目の所に残っていた「未決」は0件です。JSON Schema の検査は、前の check.py、check_new.py と、今回足した8通りがすべて通りました。コミットはしていません。

## 変更したファイル
- /Users/takumamatsuura/reading-app/contracts/widget-snapshot.schema.json:5（description。版、形、enum は変えていない）
  - [出し方]：一行がなければ、書名の所に書名と p.ページを出します（ページがなければ書名の所だけ）。書名の所は、title があれば title、なければ `widget.currentBookAsTitle` の文（「今の本」／Reading Now）です。字と場所は書名と同じにしました。
  - ISBN は出しません。title がないことは「読めない」扱いにしません。
  - H22 の状態は title の有無で変えません（normal、noLine、noLineNoPage）。
  - 前の文が引いていた「仕様 5 の W-1『今の本の書誌を待っている：一行とページは出す』」は、もう仕様にありません。引き先を「仕様の決定 66」に替えました。
  - [読み上げのラベル]：書名の所から読み始め、書式は title の有無で変えません。一行とページがあれば `widget.spoken`、一行だけなら `widget.spoken.noPage`、ページだけなら `widget.spoken.noLine`、どちらもなければ書名の所だけです。例は仕様 6 の4つを写しました。隠すときは書名の所が `widget.hidden` の文になります（例「しおり、61ページ」）。
  - 指示書にない書き足しが1つあります。「拡張が描くときに出し、アプリは写しの title に入れない」という書く側の決まりです。理由は「## 未解決」の 3 に書きました。
- /Users/takumamatsuura/reading-app/contracts/hooks/h22-widget.schema.json：examples に2つ目を足しました（ファイルの末尾。43行増え、enum は変えていない）。
  - W-1、`state: noLine`、`texts` は `widget.title`「今の本」と `widget.page`「p.120」。
  - 読み上げのラベルは「今の本、120ページ」、まとまりは1つ。組みの結果（composition）はありません。
- /Users/takumamatsuura/reading-app/contracts/test-hooks.md:386-390（H22 の「書名のない今の本」）
  - 状態の enum は足しません。状態の決め方は書名のある本と同じです。
  - 一行があれば、組み、URL、texts、読み上げのラベルの形も、書名のある本と同じです。
  - 一行がなければ、`texts` の `widget.title` に「今の本」が入ります。ページがあれば `widget.page` も入ります。
  - 読み上げのラベルの例を4つ載せ、上の例の2つ目を指しました。
- /Users/takumamatsuura/reading-app/docs/adr/features/001-reading-session.md
  - :269（5 の「見せ方」）：決定 66 の形に直し、写した所を並べました。
  - :393（10 の designer の申し送り）：済みにし、「この行で残っているものはない」と書きました。
  - :395（10 の verifier の申し送り）：書名のない今の本のウィジェットは H2 と H22 で確かめられる、と書き足しました。どの AC のテストに入れるかは verifier が決めます。
  - :233（4 の検査の記録）：今回の検査の結果を1行足しました。指示書は 5 と 10 だけでしたが、契約の検査の出力は設計メモに残す決まりなので、同じファイルの 4 にも足しました。

## 実行したコマンドと結果
（作業のフォルダ：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-7-fix1/。python は g1-7-4b/venv、jsonschema 4.25.1）
- 直し：`py/edit_fix2.py <repo> dry` のあと `write`、続けて `py/edit_fix2b.py <repo>`
  - 置き換えはすべて1件ずつ一致しました（ws description、test-hooks H22、memo 5、memo 10 designer、memo 10 verifier、ws writer rule、memo 4 check record）。
  - widget-snapshot は前と同じ書式を保つため、文字のまま置き換えました。description 以外の中身が変わらないことは、スクリプトの中で確かめました。
  - 途中で、変数を使った出力先をガードに止められました。パスをそのまま書いて実行し直しています。
- `check.py contracts/hooks contracts/widget-snapshot.schema.json`：exit 0
  - metaschema 8/8 OK
  - 例 20/20 OK（`example h22-widget 1 OK` を含む）
  - 弾くべき17通りは17通りとも弾かれた。NG は0行
  - ログ：check-old-fix2.log
- `py/check_new.py <repo>`：exit 0、`schemas 8 examples 20`、`cases 22 mismatch 0`（ログ：check-new-fix2.log）
- `py/check_fix2.py <repo>`（今回足した8通り）：exit 0、`cases 8 mismatch 0`（ログ：check-fix2.log）
  - 受ける4：h22 の例の2つ目（noLine）、noLineNoPage で「今の本」だけ、写しの `{page:120}`、写しの title に「今の本」
  - 弾く4：noLine に組み、状態 noTitle、texts に ISBN、noLine に読めない理由
- 4ファイルの `grep -n '未決'`
  - test-hooks.md:395、:401 は「未決定」です。H26 のカメラの許可の状態の名前（notDetermined）で、決めることが残っている印ではありません。
  - 001-reading-session.md:37 は AC-4 の「AC にするかは 10 の未決」で、書名で探した結果の並べ直しの話です（pdm と verifier への申し送り）。今回の題目とは別なので、範囲の外として残しました。
  - 書名のない今の本の「未決」は0件です。
- 古い言い回し（「designer が仕様 5/6 で決める」「仕様で決めたあとに足す」「designer が決める（10 の申し送り）」「残りは書名のない今の本」と、もう仕様にない引用）の grep：0件（exit 1）
- `git diff --stat`：4 files changed, 53 insertions(+), 5 deletions(-)
  - contracts/openapi.yaml は変えていないので、spectral と oasdiff は前の回の出力のままです。
  - つなぎ口の照合（xcheck.py）は、今回は回していません。

## 未解決
1. 仕様に直接書かれていない所が1つあります。隠す設定のときにページもない場合、読み上げは「しおり」だけになるはずです。これは `widget.spoken.noLine` と写しの [出し方] から導いたもので、仕様の文にはありません。契約にも書いておらず、例「しおり、61ページ」だけを載せました。reviewer の r2 で、仕様と合っているかを見てもらうよう頼みます。
2. 範囲の外で、今回は変えなかったもの
   - 設計メモ:37 の AC-4 の「未決」（pdm と verifier への申し送りのまま）
   - test-hooks.md の H26 の「未決定」（許可の状態の名前）
3. ios-engineer と verifier への申し送り：アプリが写しの title に「今の本」を書いてしまうことは、JSON Schema の形では弾けません（check_fix2 の受ける4の最後の例）。書いてしまうと、英語の端末でも「今の本」と出ます。そこで、写しの [出し方] に書く側の決まりとして書きました。
   - 単体テストの案：書名のない本で写しを書くと、title のキーがないこと。
   - reviewer には、この書き足しが決定 66 の範囲に収まっているかを見てもらうよう頼みます。
4. 自分の直しを自分で合格にはしません。指示書のとおり、reviewer の r2 で契約と仕様を合わせて判定してもらいます。

## 記録（指揮役が保存するときに書き足す）
- 種類：作り手（tech-lead）の報告（判定ではない）
- 直した物：contracts/widget-snapshot.schema.json、contracts/hooks/h22-widget.schema.json、contracts/test-hooks.md、docs/adr/features/001-reading-session.md（コミット a039d4d）
- 日付：2026-10-20
- 次：reviewer の設計の判定 r2（往復2回の最後の回）
