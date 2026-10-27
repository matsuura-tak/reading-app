（指揮役の注）G1 の設計の判定 r1（reviewer FAIL）への、tech-lead の直しの報告。指摘ごとの扱いの表と、reviewer に反論を頼みたい所を、r2 で使うため保存した。判定ではない。報告の文はそのまま保存した。

## 要約
r1 の指摘はすべて扱いました。重大1、要修正2、要修正3、提案の P1〜P10、K1、designer の申し送り（コミット bbc61cb）です。直さずに残した指摘はなく、まだ手を付けていないものもありません。
- 手数は38回でした。
- 書いたのは、許された場所だけです（contracts/、docs/adr/、CLAUDE.md）。
- design/、docs/prd/、.claude/、.github/ には触れていません。PRD の AC は変えていません。コミットはしていません。
- 自分で書いた契約と ADR なので、合否は reviewer の r2 に任せます。反論してほしい所は最後の節に並べました。

## 指摘ごとの扱い
| 指摘 | 扱い | 場所 | 中身と理由 |
|---|---|---|---|
| 重大1 perf500 | 直した | test-hooks.md:126-133（H2 の表と数え直し）、設計メモ:145（AC-101 の行）、:296（6 の本棚の行）、:308（数え直しの注）、ADR 0005:52-56（G1-10 の手順 1 と 3） | 記録の分け方を AC-101 の Given に合わせた。<br>・本 A（1冊目、current）に1,000件。A の id は `00000000-0000-4000-8000-000000000001`。<br>・2〜401冊目に10件ずつ、402〜500冊目は0件。<br>読み始めの時刻、記録の id、分は式で決めた。G3 の AC-101 と G4-15 は同じ中身を使い、本の画面は A を開く |
| 要修正2 書名 | 直した | 設計メモ:264-268（5 の「書名のない本」）、h02 と h13 の book（title を required から外し、if/else を足した）、widget-snapshot.schema.json（visibleBook の required を外した。出し方と読み上げの決まりを足し、:95 に例を足した）、test-hooks.md:116、:386 | title を省けるのは、次の3つがそろう本だけ：isbn がある、lookupStatus が pending か notFound、manuallyEdited が偽。<br>写しの読み方は仕様に合わせた。一行があれば一行とページを出す（仕様 5 の W-1 と同じ）。title がないことは「読めない」扱いにしない。<br>一行も書名もないときと、書名がないときの読み上げは、designer に回す（下） |
| 要修正3 問い合わせ | 直した | ADR 0004:47-71（決まり (1)〜(4)）、:72-81（回数と順の表）、test-hooks.md:195-196（H8）、:420-423（H29）、設計メモ:35、:42-45、:282 | (1) 読み取ったときに ISBN ごとに1回送る。<br>(2) 結果を加えた本に引き継ぐ（見つかった → found、0件 → notFound と lastLookupAt、失敗か答えがまだない → pending）。<br>(3) 加えた直後には送らない。<br>(4) 通信が戻ったときも「回」を始める。回は同時に1つで、途中に来たきっかけは捨てる。回の中身は始めたときに決め、答えを待っている ISBN と送っている最中の本は入れない。後ろに回ったら、その回を終える。<br>通信がないときは (1) も (4) も送らない。<br>表は AC-2、9、10、11、113 の5つで、どれも PRD の Then の回数と順に合う |
| P1 | 直した | 設計メモ:204-206、ADR 0004:33（表の 6） | エンドポイントの表に3列を足した：誰が呼べるか、返す項目、回数の上限。<br>表の 6 には次を足した。<br>・利用者の操作の要求を、回の要求より先に送る。<br>・書名で探すを続けて押したら、前の要求を取り消してから最後の語だけを送る |
| P2 | 直した | 設計メモ:45、test-hooks.md:420-423 | AC-113 は H2 で始める。H29 で数える数は PRD の「合わせて」より1つ少ない：45件、2件、0件 |
| P3 | 直した | h02（本の id、記録の id、session.bookID を大文字だけに）、test-hooks.md:117、設計メモ 5 の id | main に出す前の版 1 の下書きで、使う側がまだないため、版は上げていない |
| P4 | 直した | h17-state.schema.json（`prevLat.*` と `$defs/latencyFile`）、test-hooks.md:215、:227-230 | 測る起動は、値を latency.json に残す。次の `-uitest-readouts on` の起動は、それを `prevLat.<区間>` に出してから消す |
| P5 | 直した | 設計メモ:355 | R-1 の代わりの値は「使わない。Takuma に出す材料」に下げた |
| P6 | 直した | entry-urls.md:27、:109-113、設計メモ:329（I の行の (e)） | 受け入れた危険として書いた。見直す条件も書いた |
| P7 | 直した | dependencies.md:20 | 手元の sha256 が、GitHub の API の digest と完全に一致した |
| P8 | 直した（注と予定） | CLAUDE.md:17、設計メモ:393 | app.json の値は、Takuma に頼む予定として書いた |
| P9 | 直した | ADR 0004:38 | `UITestHooks/` の下の H20 と H29 のつなぎ口は、grep の当たりに数えない |
| P10 | 直した | entry-urls.md:116 | Given に「書誌の順番待ちの本がない」を足した |
| K1 | 足した（前はなかった） | 設計メモ:321、ADR 0004:45（表の 18） | 送る情報、送り先、目的を、プライバシーポリシーに書く（G5 で pdm）。外部送信規律に当たるかは、指揮役が Takuma に聞く |
| 置き換えの表 | 写した | ADR 0003:135-138 | 「：」「；」は回す。「－」「＝」「＜」「＞」「｛」「｝」「｜」「＿」も回す。「，」「．」はずらす。半角の行は designer の文に合わせた |
| 禁則の一覧（決定 62） | 写した | ADR 0003:141〜 | JLREQ 3.1.7 の類を全部入れ、追い出しが増えたときの字の大きさも書いた |
| W-2 の R＝20 | 写した | ADR 0003:80 | ［designer に確かめる］を外した |
| S-1 の A_w と A_h | 写した | ADR 0003:109 | ［未決］を外した |
| entry-urls の 3 の「決まっていないこと」 | 直した | entry-urls.md:65-70 | 決定 65 の中身にした |
| H22 の例の仮の文 | 直した | h22-widget.schema.json の例の2か所 | 仕様 7 の `widget.unavailable` の文に替えた |
| 「，」「．」を Core Text で確かめること | 未確認に足した | 設計メモ:371（0003 の (5)）、ADR 0003:137 | ios/ を作る最初のビルドで確かめる |

## 変更したファイル
- /Users/takumamatsuura/reading-app/docs/adr/features/001-reading-session.md：2 の AC-2、9、10、11、113、101 の行、4、5、6、7、8、10、確かめの見出し
- /Users/takumamatsuura/reading-app/docs/adr/0003-vertical-composition.md
- /Users/takumamatsuura/reading-app/docs/adr/0004-bibliographic-lookup.md
- /Users/takumamatsuura/reading-app/docs/adr/0005-test-hooks.md
- /Users/takumamatsuura/reading-app/contracts/test-hooks.md：H2、H8、H10、H22、H29
- /Users/takumamatsuura/reading-app/contracts/entry-urls.md
- /Users/takumamatsuura/reading-app/contracts/dependencies.md
- /Users/takumamatsuura/reading-app/contracts/widget-snapshot.schema.json
- /Users/takumamatsuura/reading-app/contracts/hooks/h02-seed.schema.json
- /Users/takumamatsuura/reading-app/contracts/hooks/h13-store.schema.json
- /Users/takumamatsuura/reading-app/contracts/hooks/h17-state.schema.json
- /Users/takumamatsuura/reading-app/contracts/hooks/h22-widget.schema.json
- /Users/takumamatsuura/reading-app/CLAUDE.md：1行足して64行
- 合わせて13ファイル（+299 −65）。contracts/ndl-opensearch.yaml は変えていない。

## 実行したコマンドと結果
- JSON の書き換え：`python3 -I …/g1-7-fix1/py/edit_json.py <repo> dry` のあと `write`。
  - 5ファイルとも、読んで書き直しても元の形が変わらないことを確かめてから書いた。
  - h02 の UUID の pattern は3か所を置き換えた。
- 7-4a の検査（jsonschema 4.25.1）：`…/g1-7-4b/venv/bin/python -I …/g1-7-4a/gen/check.py contracts/hooks contracts/widget-snapshot.schema.json` → exit 0
  - metaschema は 8/8 OK、例は 19/19 OK（足した例は3つ）。
  - h17 の raw は 2/2 OK。
  - 前からある、わざと壊した形は17通りとも弾かれた（NG 0件）。
  - 出力：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-7-fix1/check-old.log
- 足した22通り：`check_new.py` → `cases 22 mismatch 0`（受ける9、弾く13）
  - 弾かれたもの：found で書名なし、lookupStatus を省いて書名なし、手で直したのに書名なし、小文字の本の id、小文字の記録の id、写しの書名が0字、知らない prevLat、latency.json の知らない区間と空の lat。
  - 受けたもの：pending と notFound で書名なし、写しで書名なしの一行とページ。
  - 出力：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-7-fix1/check-new.log
- perf500 の数え直し（`python3 -I …/g1-7-fix1/py/perf500.py`。出力は perf500.log）
  ```
  total records 5000 | A 00000000-0000-4000-8000-000000000001 current 1000
  books by record count {0: 99, 10: 400, 1000: 1} | books with 10: 2 - 401 | books with 0: 402 - 500
  shelves {'current': 1, 'tsundoku': 350, 'finished': 149} | unique record ids 5000 | unique (book,startedAt) 5000
  ```
- 文書の書き換え：`edit_text.py` で8ファイル、51か所を書き換えた。
  - どの古い文も、ちょうど1か所に当たることを確かめてから書いた。
  - そのあと設計メモを2か所、H8 を1か所、小さく直した。
- 古い文の残り：`grep -rn '登録の直後|［designer に確かめる］|［未決。designer|決まっていないこと（designer|（文言キー widget.unavailable の文）|j mod 500|前に来たときに1回' contracts docs/adr CLAUDE.md` → 0件
- つなぎ口の照合（7-4a の xcheck.py）→ exit 0
  - 芯は85件、つなぎ口は23個。`MISSING from contract: none`。
  - 全部のつなぎ口で、使う AC の欠けと余りは0。H29 も uses=6 doc=6。
- reviewer の xcheck.py
  - PRD 136件＝芯85件＋選択肢51件。設計メモの行は85で、重なり、抜け、空の欄は0。
  - ずれは r1 の基準と同じで、新しいずれはない：AC-16、53、58、89、90 は H1 と H2 を外す書き方、H29 は意図して足した5件。
- `grep -cE '^- AC-[0-9]+：' docs/prd/001-reading-session.md` → 136
- spectral 6.17.0 は2回とも exit 0。ほかに出たのは道具の DEP0040 の知らせだけ。
  - `lint contracts/ndl-opensearch.yaml --ruleset contracts/.spectral.yaml` → `No results with a severity of 'error' found!`
  - `--fail-severity hint` を付けて → `No results with a severity of 'hint' or higher found!`
- oasdiff 1.34.0
  - origin/main に契約がない（exit 128）ので「新規」。
  - 空の基準と比べて → `No breaking changes to report, but the specs are different.`（exit 0）
  - HEAD と今を比べて：breaking も changelog も `No changes detected`（exit 0）。OpenAPI はこの直しで変えていない。
- P7
  - `shasum -a 256 spectral-macos-arm64` → `cb7e1bd31d85a9920100d79e7ba138cc75cf529dfa8e7492c69affe52e38d142`
  - `curl https://api.github.com/repos/stoplightio/spectral/releases/tags/v6.17.0` → HTTP 200。spectral-macos-arm64 の digest は `sha256:cb7e1bd3…e38d142` で一致した。
- `wc -l CLAUDE.md` → 64
- `git status --short`：変わったのは上の13ファイルだけ。.agents/、.codex/、AGENTS.md は前からあるもので、触れていない。
- 作業のメモとスクリプト：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-7-fix1/（notes.md、py/edit_json.py、py/edit_text.py、py/check_new.py、py/perf500.py と各ログ）

## designer への申し送り（指揮役から回してください）
アプリの画面は、仕様ですでに決まっています（書名の所に `book.isbnAsTitle`「ISBN %@」）。残っているのは、書名のない今の本のウィジェット（W-1、W-2）だけです。写しには ISBN を置けない（PRD 12）ので、ウィジェットでは「ISBN %@」を使えません。
1. 一行も書名もないとき（ISBN で加えた直後で、書誌を待っているか見つからなかったとき）の見せ方。ページがあるときとないときの両方。
2. 書名がないときの読み上げのラベル。一行があるときとないときの両方。
3. 新しい状態の名前が要るなら教えてください。H22 の enum に足します。足すだけなので、版は変えません。

## reviewer に反論を頼みたい所
- ADR 0004 の (4) について：
  - 通信が戻ったときにも回を始めること（PRD 9 の文に合わせた）。
  - 回の途中に来たきっかけを捨てること。
  - 後ろに回ったら、その回を終えること。
- 通信がないときは、読み取りでも送らないこと。このため AC-9 では、H29 に offline の要求が残りません。H8 の「失敗させた要求を記録する」働きは、そのまま残しました。
- title を省ける条件に「manuallyEdited が偽」を入れたこと。
- h02 の id を大文字に絞ったことと、title の必須を緩めたことを、版を上げずに行ったこと。理由は、main に出す前の下書きだからです。
- `prevLat.*` と latency.json の形。

## 未解決
1. 書名のない今の本のウィジェットでの見せ方と読み上げ（designer。上の申し送り）。
2. K1：外部送信規律に当たるか。指揮役から Takuma に聞いてください。
3. P8：ios/ を作る最初の PR でコマンドを決め、app.json に入れるよう Takuma に頼むこと。G2 の関門の前に要ります。
4. ヒラギノで、Core Text が「，」「．」の縦書きの位置を返すか（最初のビルドで確かめる）。
5. ［推測］latency.json は区間の終わりのあとに書くので、測った値には効かない見込み。最初の実装で確かめます。
6. ［推測］実機で NWPathMonitor の知らせが短い間に揺れると、回が増えるかもしれません。失敗したら1回で止まるので、要求は回ごとに1件までです。G4-4 で見ます。
7. 前からある未決（積読の並びに使う日時、G1-13）は、範囲の外なので変えていません。

## 記録（指揮役が保存するときに書き足す）
- 種類：作り手（tech-lead）の直しの報告（判定ではない）
- 直した物：contracts/ の9ファイル、docs/adr/ の4ファイル、CLAUDE.md（コミット 6c46e54）
- 日付：2026-10-20
- 指揮役が確かめたこと：作り手が触ったのは許された場所だけ。重大1（perf500）は contracts/test-hooks.md の表と、作り手の数え直しの出力（本 A 1,000件、10件の本 400冊、0件の本 99冊、合わせて5,000件）で直ったことを見た
