（指揮役の注）reviewer r1 の要修正2 を受けて、書名のない今の本のウィジェットでの見せ方を決めた、designer の報告。判定ではない。報告の文はそのまま保存した。

## 決めたこと（指示書の 1〜4）
ルールは1つです。書名のない今の本では、W-1 と W-2 の書名の所に `widget.currentBookAsTitle`「今の本」（英語 "Reading Now"）を出します（決定 66）。
- アプリの画面で書名の所に `book.isbnAsTitle` を出すのと同じ型です。
- 言葉は、本棚の区分 `shelf.current` と `widget.empty` の「今の本」にそろえました。
- 写しには書誌の状態がありません（PRD 12）。そのため、書誌を待っている本にも見つからなかった本にも正しい言葉だけを使います。

1. 見せ方
   - 一行があるとき：変えません（一行とページ）。
   - 一行がなくページがあるとき：書名の所に「今の本」と「p.120」を出します。字と場所は書名と同じです。
   - 一行もページもないとき：「今の本」だけを出します。
   - ISBN は出しません。
2. 読み上げのラベル：書名の所を「今の本」にし、順と書式は書名のある本と同じにします。
   - 一行とページがある：「今の本、61ページ。下人は、雨やみを待っていた。」
   - 一行だけ：「今の本。下人は、雨やみを待っていた。」
   - ページだけ：「今の本、120ページ」
   - どちらもない：「今の本」
3. 状態：新しい名前は要りません。
   - 一行あり → `normal`。一行なし・ページあり → `noLine`。どちらもなし → `noLineNoPage`。
   - 一行がないとき、H22 の `texts` の `widget.title` には「今の本」が入ります。
4. 文言：キーを2つ足しました（仕様の 7）。
   - `widget.currentBookAsTitle`：「今の本」／"Reading Now"
   - `widget.spoken.noLine`：「%1$@、%2$@」／"%1$@, %2$@"（名前とページ）
   - 2つ目のキーは、書名のある一行なしの本（「檸檬、120ページ」）と隠す設定（「しおり、61ページ」）の書式としても使います。この2つの書式は、これまで 7 にありませんでした。
- 選ばなかった案と理由は、決定 66 に書きました。
  - 書名の所を空ける
  - 「書誌を待っています」
  - 「書名なし」
  - `widget.hidden` の「しおり」を使う
  - 案内の文を出す

## 変更したファイル
- /Users/takumamatsuura/reading-app/design/001-reading-session.md
  - :5 直した記録
  - :348 決定 66（R-18、R-23、R-26、R-35／B-1、B-2、HIG の widgets と accessibility）
  - :355 状態の表の W-1 の「一部だけ読めたとき」（W-2 は「W-1 と同じ」のまま）
  - :393-394 識別子の表（ラベルの例と、`widget.title` に出す文）
  - :585-586 文言キー2つ
  - :767 読み上げ順
  - :783 Double-Length で確かめる所
  - :845 verifier への申し送り
  - :851 tech-lead への申し送り（写し先）
  - :860 と :866 確かめの印の注（決定は 66 行、キーを2つ足した）
- /Users/takumamatsuura/reading-app/design/001-reading-session/screens.md：:3 直した記録、:22-23 W-1 の見せ方と読み上げ、:41 W-2
- tokens.md は変えていません（新しいトークンは要りません）。contracts/ と docs/ には触れていません。コミットはしていません。

## 実行したコマンドと結果
- 書き換え：`python3 -I …/g1-design-fix3/py/edit.py <repo> dry` で確かめてから `write` で書いた。どの古い文も、ちょうど1か所に当たった（count=1）。行数は仕様 862 → 867、screens 329 → 331。
- 照合：`python3 -I …/g1-design-fix3/py/check.py /Users/takumamatsuura/reading-app`
  - 調査の R は35個。決定表は66行で、1〜66 が抜けなく続く。R の欠け、調査にない R、原則の空欄は0件（`bad []`）。
  - 文言キーは170個で、日英の空欄は0、重複は0。2つの新しいキーは 7 にある（参照は10か所と5か所）。
  - 日英で書式の数が合わないと出たのは、もとからある複数形の4キーだけ（book.nights、book.delete.confirm、scan.addToShelf、scan.discard.confirm）。英語を one と other で書いているためで、今回の差分はこの4キーに触れていない（grep で0行）。
  - 5 の表は8列で21行、6 の表は4列で112行。列のずれは0件。
- 古い文の残り：`grep -rn "今の本の書誌を待っている…" design/` で当たったのは S-1 の行（アプリの画面の正しい記述）だけ。
- `git status --short`：変わったのは design/ の2ファイルだけ。
- 開いた URL：なし。新しい R も作っていません。
- スクリプトとメモ：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-design-fix3/（notes.md、py/edit.py、py/check.py）

## 未解決
1. tech-lead に契約へ写してもらう所（指揮役から回してください）
   - contracts/widget-snapshot.schema.json の description の [出し方] と [読み上げのラベル] にある「未決」
   - contracts/test-hooks.md の H22 の「書名のない今の本」
   - 設計メモ 5 の「見せ方」と 10 の申し送り
   - enum は足しません。
2. S-3b の `mark.pageOnly.footer`（「ロック画面には書名とページが出ます」）は、書名のない今の本ではロック画面が「今の本」とページになり、文と少しずれます。今の本の書名が埋まるまでの短い間だけなので、文は変えていません。直すかは design-reviewer の r2 に任せます。
3. 言葉を「今の本」と "Reading Now" にしたのは、見た目と文言の判断です。キーの文を替えるだけで戻せるので、推奨のまま進めました。Takuma が別の言葉を選ぶなら、1か所の差し替えで済みます。
4. 範囲の外で気づいたこと（直していません）：ウィジェットの書名の字（.headline の書体を固定の大きさで、2行まで）は screens.md にだけあり、tokens.md のトークンになっていません。

## 記録（指揮役が保存するときに書き足す）
- 種類：作り手（designer）の報告（判定ではない）
- 直した物：design/001-reading-session.md、design/001-reading-session/screens.md（コミット 3055436）
- 日付：2026-10-20
- 次：契約の「未決」（widget-snapshot.schema.json の出し方と読み上げ、test-hooks.md の H22、設計メモ 5 と 10）を、tech-lead に写させる
