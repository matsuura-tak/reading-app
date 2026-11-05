（指揮役の注）G1 の設計の判定（reviewer、観点は設計、r2。往復2回の最後の回）。対象は r1（0fbc79c）からの直しと、55e9503 の時点の設計メモ、契約、ADR、CLAUDE.md。範囲は芯（裁定 24）。報告の文はそのまま保存した。

PASS

## 指摘

### 重大
なし。

### 要修正
なし（r1 の要修正2と3は直りました。下の「前回の指摘の追跡」を見てください）。

### 提案
r2 では新しい提案を出しません（r2 は重大だけを新しく挙げる決まりです）。r1 の P1〜P10 は、すべて直ったか、理由を付けて受け入れました。

- 判定に数えない参考
  - CLAUDE.md:32 と contracts/dependencies.md:22（jsonschema の行）は、出力を `schemas 8 examples 16 OK` と書いたままです。CLAUDE.md:35 のコマンドを自分で動かすと、いまは `schemas 8 examples 20 OK` が出ます。文書の数が古いだけで、検査は通ります。次に tech-lead が触るときに直せば足ります。
- 要確認（Takuma 向け。判定に数えない）
  - K1：外部送信規律に当たるかを決めるのは法律の判断です。tech-lead は、送る情報、送り先、目的をプライバシーポリシーに書く予定を残しました（ADR 0004 の表の 18、設計メモ:321）。Takuma に聞くのは指揮役の予定に入っています（設計メモ:394）。

既存の問題：なし。

## 採点表（design-reviewer だけ）
該当なし。

## 前回の指摘の追跡（r2 だけ）
| r1 の指摘 | 結果 | 確かめた場所と方法 |
|---|---|---|
| 重大1 perf500 の分け方が AC-101 と違う | 直った | test-hooks.md:126-132 の表を、自分のスクリプトで作り直して数えました。記録は5,000件です。本 A（1冊目、current、id …0001）が1,000件、2〜401冊目が10件ずつ（400冊）、402〜500冊目が0件（99冊）でした。PRD:1131 の Given と同じです。記録の id と読み始めの時刻は5,000件とも別々で、大文字の pattern にも合います。設計メモ:145、:314、ADR 0005:52-56（G1-10 と G4-15 も同じ中身。A を5回開く）もそろっています |
| 要修正2 書名のない本を表せない | 直った | 設計メモ:265-269 に決まりがあります。title を省けるのは、isbn があり、pending か notFound で、manuallyEdited が真でない本だけです。<br>h02 と h13 の if/else と、写しの visibleBook を、自分で作った例で試しました：<br>・受けた：pending や notFound で書名なし、manuallyEdited が false で書名なし、写しの `{}` と `{page}`<br>・弾いた：found で書名なし、手で直した本で書名なし、ISBN なしで書名なし、lookupStatus を省いて書名なし（h02 で省くと found か none になる。h02:134）、書名が0字<br>写しの読み方は、仕様の決定 66 と同じです（下の表） |
| 要修正3 問い合わせの時が AC-2 と AC-11 の両方に合わない | 直った | ADR 0004:47-80 に (1)〜(4) と、回数と順の表があります。表の AC-2、9、10、11、113 の5行を、PRD の When と Then（:364-369、:406-429）に1行ずつ当てました。回数も順も合っています（下の「反論を頼まれた所への答え」）。H8（test-hooks.md:195-196）と H29（:424-427）も同じ決まりです |
| P1 エンドポイントの表 | 直った | 設計メモ:204-206 に、誰が呼べるか、持ち主の確かめ、返す項目、回数の上限の列が入りました。ADR 0004:33（表の 6）に、利用者の操作を先に送ることと、続けて押したら前の要求を取り消すことが入りました |
| P2 AC-113 の数え方 | 直った | 設計メモ:45 と test-hooks.md:424-427 にあります。数は 45、2、0 です。24〜1,080時間を24時間ごとに数えると45件で、計算が合います |
| P3 id の大文字と小文字 | 直った | h02 の本、記録、session.bookID の pattern を `[0-9A-F]` にしました。小文字の id は h02 でも h13 でも弾かれることを確かめました |
| P4 latency.json の形 | 直った | h17 に `^prevLat\.(endToMark\|shelfOpen\|bookOpen)$` と `$defs/latencyFile` があり、流れは test-hooks.md:227-230 にあります。8通りを試し、例は受け、知らない区間、空の配列、負の値、lat の `{}`、Release は弾きました |
| P5 R-1 の代わり | 直った | 設計メモ:356 は「使わない。Takuma に出す材料」です |
| P6 canOpenURL | 直った | entry-urls.md:27、:109-112 と、設計メモ:340 の I の (e) にあります。見直す条件もあります |
| P7 spectral の sha256 | 直った | 手元の値 `cb7e1bd3…e38d142` が、GitHub の API の digest と一致しました。大きさ 91192736 も手元のファイルと同じです（自分で開いて確かめた。下の URL） |
| P8 app.json の commands | 理由があるので受け入れる | CLAUDE.md:17 と設計メモ:393 に、ios/ を作る最初の PR で決めて Takuma に頼む予定があります。G2 の関門（gates.md）がそこで見ます |
| P9 grep の当たり | 直った | ADR 0004:43（表の 11）に「`UITestHooks/` の下の H20 と H29 は数えない」があります |
| P10 URL で起動したときの Given | 直った | entry-urls.md:116 に「書誌の順番待ちの本がない」が入りました |
| K1 外部送信規律（要確認） | 記録と予定に入った（判定に数えない） | ADR 0004 の表の 18、設計メモ:321、:394 |

## 証拠
実行したコマンドと結果（2026-10-20。リポジトリは /Users/takumamatsuura/reading-app）：
```
$ git rev-parse HEAD → 55e95039a45da531676f982f2c849f9bb79e70ba
$ git diff --name-only 55e95039a45da531676f982f2c849f9bb79e70ba...HEAD
（空。BASE と HEAD が同じ）
$ git diff --stat 0fbc79c 55e9503   （r1 の対象からの直し）
CLAUDE.md, contracts/dependencies.md, contracts/entry-urls.md, contracts/hooks/h02-seed.schema.json, h13-store.schema.json,
h17-state.schema.json, h22-widget.schema.json, contracts/test-hooks.md, contracts/widget-snapshot.schema.json,
design/001-reading-session.md, design/001-reading-session/screens.md, tokens.md, docs/adr/0003-…, 0004-…, 0005-…,
docs/adr/features/001-reading-session.md, docs/progress.md, docs/reviews/ の5つ（22 files, +1119 −131）
$ git log --format='%h %s' --name-only 0fbc79c..55e9503 -- contracts docs/adr CLAUDE.md design docs/prd .claude .github
6c46e54、a039d4d（tech-lead）：contracts/、docs/adr/、CLAUDE.md だけ
bbc61cb、3055436（designer）：design/ だけ
docs/prd/、.claude/、.github/：変更なし
$ git diff --stat 0fbc79c 55e9503 -- contracts/ndl-opensearch.yaml contracts/.spectral.yaml
（空。OpenAPI と spectral のルールは変わっていない）
$ shasum -a 256 spectral-macos-arm64 → cb7e1bd31d85a9920100d79e7ba138cc75cf529dfa8e7492c69affe52e38d142（版 6.17.0）
$ spectral lint contracts/ndl-opensearch.yaml --ruleset contracts/.spectral.yaml
No results with a severity of 'error' found!   exit=0
$ spectral lint … --fail-severity hint
No results with a severity of 'hint' or higher found!   exit=0
$ spectral lint <operationId を消した写し>   （空振りしていないかの確かめ）
 30:9  warning  operation-operationId  Operation must have "operationId".
$ oasdiff --version → oasdiff version 1.34.0
$ oasdiff breaking --fail-on ERR <0fbc79c の契約> contracts/ndl-opensearch.yaml → No changes detected  exit=0
$ oasdiff changelog <0fbc79c の契約> contracts/ndl-opensearch.yaml → No changes detected  exit=0
$ git ls-tree --name-only origin/main contracts/ → contracts/.gitkeep, contracts/dependencies.md
$ oasdiff breaking --fail-on ERR <空の基準> contracts/ndl-opensearch.yaml
No breaking changes to report, but the specs are different.  exit=0
$ oasdiff breaking --fail-on ERR contracts/ndl-opensearch.yaml <空の基準>   （逆向き）
1 changes: 1 error … [api-path-removed-without-deprecation]
$ <venv>/bin/python -I -c '<CLAUDE.md:35 のコマンド>' contracts/hooks/*.schema.json contracts/widget-snapshot.schema.json
schemas 8 examples 20 OK   exit=0   （jsonschema 4.25.1、Python 3.9.6）
$ <venv>/bin/python -I g1-review-design-r2/schemacheck.py <repo>   （自分で書いた31通り）
schemas 8 examples 20 / cases 31 mismatch 0   exit=0
h22 の状態の enum：normal, noLine, noLineNoPage, hidden, empty, unavailable（増えていない）
$ python3 -I g1-review-design/xcheck.py <PRD> <設計メモ> contracts/test-hooks.md   （r1 と同じスクリプト）
PRD AC count 136 / option 51 core 85 / memo rows 85 dups [] / core not in memo [] memo not core [] / rows with empty cell []
AC-16/53/58/90 missing [1]、AC-89 missing [1, 2]、AC-4/9/10/11/113 extra [29]、core H without section [23, 24, 25]   （r1 と同じ）
$ grep -cE '^- AC-[0-9]+：' docs/prd/001-reading-session.md → 136
$ python3 -I -（test-hooks.md:128 の式で perf500 を作り直して数えた）
total 5000 | books by record count {0: 99, 10: 400, 1000: 1} | book A(1) = 1000
shelves {'current': 1, 'tsundoku': 350, 'finished': 149} | unique ids 5000 | ids match upper pattern True | unique startedAt 5000
$ python3 -I -（仕様の settings.dataSources の文と、ADR 0004:84、:86 を比べた）
ja equal: True / en equal: True
$ grep -rnE '登録の直後|j mod 500|（文言キー widget.unavailable の文）|［designer に確かめる］|［未決|前に来たときに1回|仕様 5 の W-1' contracts docs/adr CLAUDE.md
（当たりなし。古い文は残っていない）
$ ls ios backend → どちらもない / git ls-files | grep -ciE 'AcceptanceTests|tests/acceptance' → 0
$ wc -l CLAUDE.md → 64
$ grep -nE '^## ' docs/adr/000[1-5]-*.md
5つとも、背景、決定、検討した案、いちばん強い反論、結果、見直す条件、確かめたこと、確かめ（B）の節がある
```

作業で作ったファイル（リポジトリの外）：
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-review-design-r2/schemacheck.py
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-review-design-r2/base-r1.yaml

使った道具（前の回と同じもの）：
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-7-2/spectral-bin/spectral-macos-arm64
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-7-4b/oasdiff-bin/oasdiff
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-7-4b/venv/bin/python
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-review-design/xcheck.py

開いた URL と日付：
- https://api.github.com/repos/stoplightio/spectral/releases/tags/v6.17.0（2026-10-20）
  - spectral-macos-arm64 の項目："digest": "sha256:cb7e1bd31d85a9920100d79e7ba138cc75cf529dfa8e7492c69affe52e38d142"、"size": 91192736、"tag_name": "v6.17.0"

対象と読んだ印：
- 観点は設計（G1。範囲は裁定 24 の芯）です。BASE と HEAD は 55e95039a45da531676f982f2c849f9bb79e70ba で同じです。判定したのは、r1 の対象（0fbc79c）からの直しの差分と、HEAD の時点の契約、ADR、設計メモ、CLAUDE.md です。
- 全文を読んだ：0fbc79c..55e9503 の、次のファイルの差分のすべて
  - CLAUDE.md
  - contracts/dependencies.md、entry-urls.md、test-hooks.md、widget-snapshot.schema.json
  - contracts/hooks/ の h02、h13、h17、h22
  - docs/adr/0003、0004、0005、docs/adr/features/001-reading-session.md
  - 直しの報告4つと r1（データとして読んだ）
  - これと r1 での全文の読みを合わせて、HEAD の契約と ADR を全部見たことになります
- 関わる所だけを読んだ
  - design/001-reading-session.md：決定 62〜66、:122-125、W-1 と W-2 の行、S-7a、S-8a、S-8b、S-10、文言表
  - tokens.md：50〜100行
  - screens.md：22、64行
  - PRD：AC-2〜11、AC-113、AC-101、:156、:316
  - docs/org/gates.md：G1 の節
- 対象外：docs/progress.md（指揮役の記録）
- 差分の中に、エージェントへの指示のような文はありませんでした（grep で探しました）。

仕様の直し（決定 62〜66）が契約と ADR に写っているか：
| 決定 | 仕様 | 写し先 | 結果 |
|---|---|---|---|
| 62 禁則 | design:344、tokens.md:55-65 | ADR 0003:141-152 | 一致。9つの類、小さい仮名22字、AC-28 の6字、送りが増えたときの字の大きさがそろっています。送りの止め方は、ADR 0003:61 の「前の列が1字になっても満たせなければ送らない」で、終わりがあります |
| 63 置き換え | design:345、tokens.md:92-95 | ADR 0003:135-138 | 一致。「：」「；」を回す、「－」から「＿」までの8字を回す、「，」「．」をずらす、半角の行。古い「：は立てる」の行は消えています |
| W-2 の R（決定 8） | tokens.md:68 | ADR 0003:80 | 一致（20）。［designer に確かめる］は消えています |
| 64 S-1 の A_w と A_h | design:346、tokens.md:69、screens.md:64 | ADR 0003:109 | 一致。393×852 では 361 と 340 で、28pt なら1列12字。375×667 の 34pt は9列が 374pt で、343pt を超えて横書きになります。計算し直して合いました |
| 65 URL が来たときの画面 | design:122-125、:347 | entry-urls.md:65-69 | 一致。閉じない画面の一覧と、S-6、S-7、S-10 を閉じることが同じです |
| 66 書名のない今の本 | design:348、:355、:393-394、:586 | widget-snapshot.schema.json:5、test-hooks.md:386-390、h22 の例2、設計メモ:269 | 一致。状態は増やしていません。「今の本」と "Reading Now"、読み上げの4つの例、ISBN を出さないことも同じです |
| （7-2 の申し送り）クレジットの文 | design の `settings.dataSources` の行 | ADR 0004:84、:86 | 日本語も英語も、文字が完全に一致しました |

反論を頼まれた所への答え：
- ADR 0004 の (4)：受け入れます。
  - 通信が戻ったときに回を始めることは、PRD:156 の「通信が戻ったら加えた順に書誌を埋める」に合います。
  - 私のいちばん強い反論は、回の途中で通信が揺れた場合です。失敗で回が止まり、その間に来た「戻った」は捨てられるので、本が次に前に来るまで待つことがあります。それでも、AC-9 の10秒は前に戻した時から数えます（PRD:409）。前に来れば新しい回が始まり（ADR 0004:62）、送っている本は入れません（:61）。だから AC は満たせます。
  - 後ろに回った回が、最後の答えを待っている間も「動いている」に数えるかは、文から読み取りにくい所です。:62 の「前に来たら新しい回を始める」を正として作っているかを、G2 でコードで見ます。
- 通信がないときは読み取りでも送らないこと：受け入れます。
  - PRD:316 の H8 の決まり（通信がないときの問い合わせも記録に数える）は、つなぎ口の働きとして残っています（test-hooks.md:197）。
  - AC-9 の「順は I1、I2、I3」（PRD:409）は、I1、I2、I3 の3件でちょうど満たします。
  - 仕様の S-8a の通信がない列（design:369「行に `book.pendingInfo`（加えられる。AC-9）」）とも合います。
- title を省ける条件に「manuallyEdited が偽」を入れたこと：受け入れます。
  - S-7a は、保存に書名1〜100字を求めます（design:366、:619、:623）。だから手で直した本には、必ず書名があります。
- 版を上げずに id を大文字に絞り、title の必須を緩めたこと：受け入れます。
  - 使う側がまだありません。origin/main の contracts/ は .gitkeep と dependencies.md だけで、ios/ と backend/ もありません。受け入れテストのファイルも0件です。
  - 各スキーマの [版] に、この例外と理由が書いてあります。
- `prevLat.*` と latency.json の形：受け入れます（上の8通り）。
  - 書く時が測る値に影響しないかは、tech-lead の未解決 5 のとおり、最初の実装で確かめてください。
- 写しの title に「今の本」を書かない、という書く側の決まり：受け入れます。
  - 決定 66 は「写しに title がない」を前提にしています。英語の端末で正しく出すには、拡張の側で文を出すしかありません。だから決定 66 の範囲に収まります。
- 隠す設定でページもないときの読み上げ（「しおり」だけ）：受け入れます。
  - 仕様の決定 12（design:294）は「読み上げのラベルも同じ」です。出すものは r1 のときからの [出し方]「ページがなければ widget.hidden だけ」なので、ラベルは「しおり」になります。仕様と食い違う所はありません。

AC の追跡とエンドポイントの表（G1 の関門の reviewer の項目）：
- AC の件数
  - PRD の AC は136件で、芯85件と選択肢51件です。
  - 設計メモの行は85件です。重なり、抜け、空の欄は0件でした。
  - ずれは r1 と同じで、増えていません：AC-16、53、58、89、90 は H1 と H2 を外す書き方です。H29 は意図して足した5件です。
- 行はあるのに、契約でたどれない AC は、もうありません。
  - AC-101 は perf500 でたどれます。
  - AC-2、9、10、11、113 は ADR 0004 の表でたどれます。
- エンドポイントの表（設計メモ:206 を確かめたもの）
| operationId | 誰が呼べるか | 持ち主の確かめ | 返す項目 | 回数の上限 |
|---|---|---|---|---|
| ndlOpenSearch（GET ndlsearch.ndl.go.jp/api/opensearch） | 誰でも呼べる公開 API（`security: []`）。ID、クッキー、キャッシュは送らない | 該当なし（相手は利用者のデータを持たない） | 契約の対応表にある要素だけ | 同時に1件で、利用者の操作を先に送る。isbn は、読み取りで ISBN ごとに1回と、回で1冊に1回。notFound は24時間に1回で45日まで。title は操作1回につき1回（続けて押したら前の要求を取り消す）。待ちは30秒、応答は 2 MB まで |
- 認可の空欄はありません。
- G0 で verifier が挙げたつなぎ口は、すべて contracts/ にあります（r1 から減っていません）。
- 確かめ（A）（B）
  - spectral、oasdiff、JSON Schema は、上のとおり動かし直しました。
  - ADR 0001〜0005 の節も、上のとおりそろっています。
  - CLAUDE.md は64行です。

未検証：
次の点はどれも、G1 の関門の reviewer の項目ではありません。r1 でも同じ扱いにしたので、判定には響きません。
- iOS のビルドとテストのコマンドは、ios/ がないので動かしていません（r1 と同じ）。
- ADR 0004 の (4) が実機でどう動くかは、確かめていません（NWPathMonitor の揺れ、止められたプロセスで答えを待っている要求）。G4-4 で見ます。
- 7-1〜7-4a の spike は、動かし直していません。
- tech-lead のスクリプト（check_new.py、check_fix2.py、perf500.py）は動かしていません。同じ所を、自分の31通りと perf500 の作り直しで確かめました。
- 仕様の差分（92KB）のうち、契約と ADR に関わらない所（見た目、文の言い回し）は、行ごとには読んでいません。仕様の良し悪しは範囲の外です。
- r2 では新しい規則の文を引いていないので、Apple の文書は開き直していません。
- 未追跡の .agents/、.codex/、AGENTS.md は、対象の外なので開いていません。

## 記録（指揮役が保存するときに書き足す）
- 関門：G1
- 判定した役：reviewer（観点：設計）
- 回：r2（往復2回の最後）
- 対象：55e95039a45da531676f982f2c849f9bb79e70ba の時点の契約、ADR、設計メモ、CLAUDE.md（r1 の 0fbc79c からの直し）
- 日付：2026-10-20
- 指揮役が書き足したこと：結果は PASS（重大0、要修正0）。これで芯の G1 の /feature の 6（design-reviewer r2、tech-lead r1）と 8（reviewer r2）がすべて PASS
- 判定したモデル：opus（fable が使えないため）
