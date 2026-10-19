（指揮役の注）G1 の設計の判定（reviewer、観点は設計、r1）。対象は技術設計メモ、契約、ADR 0001〜0005、CLAUDE.md、書誌の確かめ（BASE=0fbc79c）。範囲は芯（裁定 24）。報告の文はそのまま保存した。

FAIL

## 指摘

### 重大
1. 重大、contracts/test-hooks.md:120-127（H2 の `perf500` の中身。とくに :126 の記録の行）
   - 何が問題か：`perf500` は「記録 j（0〜4999）は本 (j mod 500)+1 のもの」なので、どの本にも記録が10件ずつ入ります。数え直した結果は「500冊すべて10件。1冊目も10件」でした。一方、PRD の AC-101 の Given は「本 A に1,000件、ほかの400冊に10件ずつ、残りの99冊は0件」です（docs/prd/001-reading-session.md:1131）。G4-15 も「AC-101 の分け方」で入れると決めています（:1211）。
   - ほかの道がない：UITEST_SEED に入れられる本は100冊までです（contracts/hooks/h02-seed.schema.json:18）。また H2 は毎回 H1 の初期化を含みます（test-hooks.md:112）。AC-101 の Given を作れるのは `perf500` だけで、その中身が AC と違います。設計メモ 6 の本棚の行（docs/adr/features/001-reading-session.md:288）と、ADR 0005 の G1-10（docs/adr/0005-test-hooks.md:52-56）も `perf500` を使います。
   - 重い理由：1冊に1,000件ある本の画面という、いちばん重い場合を測れません。本の画面の区間（bookOpen）は、10件しかない軽い本で通ってしまいます。ADR 0001 の2つ目の反論（ReadingStore を MainActor にすると画面が止まる）への答えは「AC-101 で測り、超えたら @ModelActor に移す」です（docs/adr/0001-ios-foundation.md:51-52）。その見張りが効かなくなります。
   - 根拠：G1 の関門の「契約と ADR で、受け入れ条件をすべて満たせる」（docs/org/gates.md:48）。G0 の verifier r2 も「AC-101 は分け方しだい」と挙げています（docs/reviews/001-reading-session-G0-prd2-verifier-r2.md:197）。
   - 直す方向：`perf500` を AC-101 の分け方にします。例は、1冊目（A、current）に1,000件、2〜401冊目に10件ずつ、402〜500冊目は0件で、合計は5,000件のままです。A の id を契約に書き、G4-15 も同じ中身で入れます。設計メモ 6 と ADR 0005 の G1-10 の文もそろえます。

### 要修正
2. 要修正、書誌が埋まっていない本の書名を、データの形と契約で表せない
   - 場所
     - docs/adr/features/001-reading-session.md:255（title は1〜100字）
     - contracts/hooks/h02-seed.schema.json:47-49 と contracts/hooks/h13-store.schema.json:50-52（どの本も title が必須で、1字以上）
     - contracts/widget-snapshot.schema.json:48（visibleBook は title が必須）と、:5 の読む側の決まり (3)(5)（必須の項目がないか、書名が0字なら読めない扱い）
   - 何が問題か：ISBN だけで加えた本（pending、notFound）には書名がありません。AC-9 では、通信なしで読んだ I1 が今の本になります（PRD:406-411）。AC-10、AC-11、AC-113 も同じ形の本を扱います。いまの契約のままだと次のことが起きます。
     - (a) H13 がこの本を契約どおりに返せない。
     - (b) AC-113 の Given（書誌が0件の本）を H2 で入れるには、ないはずの書名を書くしかない。
     - (c) 今の本の書誌を待っている間は、写しに title を書けない。拡張は widget.unavailable を出す。仕様は W-1 について「今の本の書誌を待っている：一行とページは出す」と決めています（design/001-reading-session.md:346）。契約と仕様が食い違っています。
   - 直す方向：書誌が埋まるまでの書名の持ち方を、設計メモ 5 で決めます（例：lookupStatus が pending か notFound で、isbn があるときだけ title を省ける）。h02、h13、widget-snapshot をそれに合わせます。必須を省けるように緩めるのは、同じ大きな版の中の変更で済みます。読み上げのラベルと、書名も一行もないときの W-1 の見せ方は、designer に回します。
3. 要修正、書誌を問い合わせる時の決まりが、AC-2 と AC-11 の両方に合う形で書かれていない
   - 場所
     - docs/adr/0004-bibliographic-lookup.md:47-54（送るのは「登録の直後と、アプリが前に来たとき」。「同じ回の中では送り直さない」）
     - docs/adr/features/001-reading-session.md:274
     - contracts/test-hooks.md:190（H8 を0に戻すと「NWPathMonitor がつながったと言ったときと同じ処理をする（順番待ちの問い合わせ）」）
   - 何が問題か
     - AC-2 は、本棚に加える前に、読み取りの行に書誌が出ることを求めています（PRD:367）。仕様の S-8a も、読めた行で書誌を探します（design/001-reading-session.md:360）。ところが ADR 0004 には、読み取ったときの問い合わせが書かれていません。
     - 「登録の直後」を「本棚に加えた直後」と読み、S-8a の読み取りのときの問い合わせも作るとします。すると AC-11 では、加える前に1回、加えた直後にもう1回失敗し、1回目に前に戻したときに書名が埋まります。これは AC-11 の「2回目に前に戻したあと書名が埋まる。合わせて3回」（PRD:421）に合いません。読み取りのときの問い合わせを作らなければ、今度は AC-2 に合いません。
     - 両方に合う読み方は1つだけで、それが文書に書かれていません。読み取ったときに1回だけ送り、その結果を加えた本に引き継ぎ、加えた直後には送り直さない、という読み方です。
     - 通信が戻ったときに送るかどうかも決まっていません。ADR 0004 は前に来たときにしか送りません。一方、H8 の文と PRD 9 の「通信が戻ったら加えた順に書誌を埋める」（PRD:156）は、戻ったときに送る形に読めます。両方で送ると、AC-9 で同じ本が重ねて送られることがあります。AC-9 は問い合わせの順が I1、I2、I3 であることを見ます。
   - 直す方向：ADR 0004 の「問い合わせ直しの決まり」に次の4つを書き、test-hooks.md の H8 の文もそれに合わせます。
     - (1) バーコードを読んだときに、ISBN ごとに1回送る。
     - (2) その結果を、加えた本に引き継ぐ（見つかった → found、0件 → notFound と lastLookupAt、失敗かまだ答えがない → pending）。
     - (3) 加えた直後には送り直さない。
     - (4) 通信が戻ったときに送るか。送るなら、回が重ならないことと、送っている最中の本を順番待ちに入れ直さないことも書く。

### 提案
- P1、docs/adr/features/001-reading-session.md:204-206（エンドポイントの表）
  - 表に「誰が呼べるか」「返す項目」「回数の上限」の列がありません。値は ADR 0004 と契約に散っているので、下の「エンドポイントの表」の形で1行にまとめると、G2 で見やすくなります。
  - 書名で探す操作を続けて押したときの扱いと、順番待ちの問い合わせとどちらを先にするかを、ADR 0004 の表の 6 に足してください。相手の決まり「多重アクセスが生じないよう」は、いまの形でも守れています。
- P2、AC-113 を H2 から始めると、加えたときの1回は H29 に残りません。数は、(1) が46回でなく45回、(2) が3回でなく2回、(3) が1回でなく0回になります。どちらの始め方を使い、どう数えるかを、設計メモ 2 の AC-113 の行（:45）か test-hooks.md の H29 に書いてください。
- P3、id の大文字と小文字がそろっていません。h02 は小文字の id も通します（h02-seed.schema.json:57、:216）が、h13 は大文字だけです（h13-store.schema.json:63、:220）。行の識別子 `shelf.row.<id>` も大文字で出る見込みです。h02 を大文字に絞るか、そろえ方を書いてください。
- P4、test-hooks.md:209、:221：`-uitest-readouts off` で測った値の読み方が、G2 に先送りされています。AC-101 は芯の AC なので、latency.json の形をいま h17 か hook-config に足しておくとよいです。
- P5、設計メモ:344（G1-11 の R-1 の代わり）：「売上は分析の共有の同意に左右されない」が［推測］のまま、撤退の判定に「使う」になっています。Apple の文書で確かめるまでは、「Takuma に出す材料」に下げてください（選択肢（課金）の範囲です）。
- P6、contracts/entry-urls.md:23-26 と設計メモ 7 の I の行：スキームを App Store の版に登録すると、ほかのアプリが canOpenURL で、このアプリが入っているか（読書アプリを使っていること）を調べられます。影響は小さく受け入れてよいですが、受け入れた危険として書いておいてください。
- P7、contracts/dependencies.md:20-22：spectral の sha256 は 7-2 の記録にある値で、配布元の公開値とは照らしていません。CI に入れる前に、配布元の値と照らすか、npx で版を固定して入れる形にしてください。
- P8、CLAUDE.md:18-23：iOS のコマンドは名前が `<>` のままで、app.json の commands も空です。G1 では受け入れます。ただ、G2 の関門は app.json の commands が空でないことを求めます（docs/org/gates.md:54）。ios/ を作る最初の PR で直すことと、Takuma への依頼を、指揮役の予定に入れてください。
- P9、ADR 0004:38 の G2 の grep は「当たりは書誌の部品の1ファイルだけ」としています。ところが H20 は通信の部品の一番下を差し替えるので、つなぎ口のコードにも当たる見込みです。ADR 0002:53 と同じく「テストの構成でだけ入るつなぎ口は数えない」を足してください。
- P10、contracts/entry-urls.md:109：「URL で起動したあと H29 の要求が0件」が成り立つのは、順番待ちの本がない Given のときだけです。前に来たときの決まりで問い合わせが出るためです。Given を書き足してください。
- 要確認（Takuma。判定には数えない）
  - K1：利用者が入れた書名と ISBN を、端末から国立国会図書館サーチへ送ります（ADR 0004）。電気通信事業法の外部送信規律がこのアプリに当たるか、プライバシーポリシーに何を書けば足りるかは、法律の判断なので Takuma に確かめてほしいです。
  - App Store の「収集」の定義には当たらないという読み方（G1-12）は、下に引いた Apple の文と合っていると見ました。最後に決めるのは G5 です。

既存の問題：なし（判定した物は、どれも G1 で新しく作られたものです）。

## 採点表（design-reviewer だけ）
該当なし。

## 前回の指摘の追跡（r2 だけ）
該当なし（r1）。

## 証拠
実行したコマンドと結果（2026-10-20。リポジトリは /Users/takumamatsuura/reading-app）：
```
$ git rev-parse HEAD
0fbc79c98433bba1bfa561ed14866953fe1b2db0
$ git diff --name-only 0fbc79c98433bba1bfa561ed14866953fe1b2db0...HEAD
（空。BASE と HEAD が同じ）
$ git diff --name-only 802225f..HEAD
CLAUDE.md
contracts/.spectral.yaml
contracts/dependencies.md
contracts/entry-urls.md
contracts/hooks/h02-seed.schema.json
contracts/hooks/h13-store.schema.json
contracts/hooks/h17-state.schema.json
contracts/hooks/h20-ndl-stub.schema.json
contracts/hooks/h22-widget.schema.json
contracts/hooks/h29-outbound.schema.json
contracts/hooks/hook-config.schema.json
contracts/ndl-opensearch.yaml
contracts/test-hooks.md
contracts/widget-snapshot.schema.json
docs/adr/0001-ios-foundation.md
docs/adr/0002-storage-and-sharing.md
docs/adr/0003-vertical-composition.md
docs/adr/0004-bibliographic-lookup.md
docs/adr/0005-test-hooks.md
docs/adr/features/001-reading-session-ndl-check.md
docs/adr/features/001-reading-session.md
docs/progress.md
docs/reviews/001-reading-session-G0-ruling.md
docs/reviews/001-reading-session-G1-7-1-tech-lead.md
docs/reviews/001-reading-session-G1-7-2-tech-lead.md
docs/reviews/001-reading-session-G1-7-3-tech-lead.md
docs/reviews/001-reading-session-G1-7-4a-tech-lead.md
docs/reviews/001-reading-session-G1-7-4b-tech-lead.md
docs/reviews/001-reading-session-validation-plan.md

$ grep -cE '^- AC-[0-9]+：' docs/prd/001-reading-session.md
136
$ python3 -I <scratchpad>/g1-review-design/xcheck.py docs/prd/001-reading-session.md docs/adr/features/001-reading-session.md contracts/test-hooks.md
PRD AC count 136
option 51 core 85
memo rows 85 dups []
core not in memo [] memo not core []
rows with empty cell []
 AC-16/53/58/90 missing in memo: [1] / AC-89 missing in memo: [1, 2]   （どれも「H1 と H2 を外す」という書き方）
 AC-4/9/10/11/113 extra in memo: [29]                                   （H29 を足したもの。設計メモ:29）
core H without section: [23, 24, 25]                                     （選択肢の部分だけで使う）
 H29 missing:[] extra:[4, 9, 10, 11, 113]

$ spectral-macos-arm64 --version            → 6.17.0（sha256 の頭 cb7e1bd31d85a992）
$ spectral lint contracts/ndl-opensearch.yaml --ruleset contracts/.spectral.yaml
No results with a severity of 'error' found!
$ spectral lint contracts/ndl-opensearch.yaml --ruleset contracts/.spectral.yaml --fail-severity hint
No results with a severity of 'hint' or higher found!                    exit=0
$ spectral lint <operationId を消した写し> --ruleset contracts/.spectral.yaml   （空振りしていないかの確かめ）
 30:9  warning  operation-operationId  Operation must have "operationId".
✖ 1 problem (0 errors, 1 warning, 0 infos, 0 hints)

$ oasdiff --version                        → oasdiff version 1.34.0
$ git ls-tree --name-only origin/main contracts/
contracts/.gitkeep
contracts/dependencies.md
$ git show origin/main:contracts/ndl-opensearch.yaml   → exit 128（新規）
$ oasdiff breaking --fail-on ERR <空の基準> contracts/ndl-opensearch.yaml
No breaking changes to report, but the specs are different.            exit=0
$ oasdiff changelog <空の基準> contracts/ndl-opensearch.yaml
1 changes: 0 error, 0 warning, 1 info
info [endpoint-added] at contracts/ndl-opensearch.yaml in API GET /api/opensearch   exit=0
$ oasdiff breaking --fail-on ERR contracts/ndl-opensearch.yaml <空の基準>   （逆向き）
1 changes: 1 error … [api-path-removed-without-deprecation]               exit=1

$ <venv>/bin/python -I -c '<CLAUDE.md:34 のコマンド>' contracts/hooks/*.schema.json contracts/widget-snapshot.schema.json
schemas 8 examples 16 OK                                                  exit=0
（jsonschema 4.25.1、Python 3.9.6）
$ widget-snapshot に、契約に合わない6通りを渡した
hidden_with_title rejected / v2 rejected / no_title rejected / isbn_extra rejected / page0 rejected / null_title rejected

$ python3 -I -c '（test-hooks.md:126 の perf500 の式で、本ごとの記録の数を数える）'
records per book (preset): {10: 500} book1: 10
AC-101 wants: book A=1000, 400 books x 10, 99 books x 0 -> 5000

$ git log --format='%h %ad %s' --date=iso -- docs/adr/features/001-reading-session-ndl-check.md
b29d795 2026-10-20 02:14:19 +0900 … 7-2 書誌の確かめの結果（合格 29/30）…
48263ef 2026-10-20 01:42:41 +0900 … 7-1 … 書誌の確かめの本の一覧
$ git diff 48263ef b29d795 -- docs/adr/features/001-reading-session-ndl-check.md | grep -cE '^-[^-]'
0                                    （一覧の行は消えていない）
$ git show 48263ef:docs/adr/features/001-reading-session-ndl-check.md | grep -c '^| [0-9]'
35                                   （20＋10＋5）

$ grep -rnE '書名(は|が)?(空|まだ|未定)|書名の代わり|仮の書名|title.*(pending|空)' design/001-reading-session.md docs/adr contracts
（書誌が埋まっていない本の書名の決まりは、当たりなし。要修正2）
```

作業で作ったファイル（リポジトリの外）：
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-review-design/xcheck.py
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-review-design/base-empty.yaml
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-review-design/broken.yaml

開いた URL と日付（どちらも 2026-10-20）：
- https://developer.apple.com/app-store/app-privacy-details/
  - "“Collect” refers to transmitting data off the device in a way that allows you and/or your third-party partners to access it for a period longer than what is necessary to service the transmitted request in real time."
  - "“Third-party partners” refers to analytics tools, advertising networks, third-party SDKs, or other external vendors whose code you’ve added to your app."
  - "Data that is processed only on device is not “collected” and does not need to be disclosed in your answers."
- https://ndlsearch.ndl.go.jp/help/api
  - 「本APIを利用するサイトやアプリケーションには、NDLサーチのAPIを用いていることを明記してください。」
  - 「クレジット表示には、API提供対象データプロバイダ一覧に記載されているデータプロバイダ及びそのデータ提供機関の名称を含めてください。」
  - 「APIをご利用いただく際は、多重アクセスが生じないようご対応をお願いいたします。」

対象と読んだ印：
- 観点は設計（G1）で、BASE は 0fbc79c98433bba1bfa561ed14866953fe1b2db0 です。BASE と HEAD が同じなので差分の一覧は空でした。判定したのは、指示書に並んだ物を HEAD の時点で読んだものです。
- 上の `802225f..HEAD` の一覧のうち、読み方は次のとおりです。
  - 全文を読んだ：CLAUDE.md、contracts/ の14ファイル（.spectral.yaml、dependencies.md、entry-urls.md、hooks/ の7つ、ndl-opensearch.yaml、test-hooks.md、widget-snapshot.schema.json）、docs/adr/0001〜0005 の5つ、docs/adr/features/001-reading-session-ndl-check.md、docs/adr/features/001-reading-session.md、docs/reviews/001-reading-session-G0-ruling.md
  - 節だけを読んだ：docs/reviews/001-reading-session-G1-7-1〜7-4b-tech-lead.md の5つ（申し送り、未解決、reviewer に見てほしい所の節）
  - 対象外（指揮役の記録）：docs/progress.md、docs/reviews/001-reading-session-validation-plan.md
- 入力として読んだもの
  - 全文：docs/prd/001-reading-session.md（1〜1487行）、docs/org/gates.md、docs/templates/adr.md、docs/templates/review-report.md
  - grep と抜き出しで、関わる所だけ：design/001-reading-session.md、design/001-reading-session/tokens.md と screens.md、docs/reviews/001-reading-session-G0-verifier-r1.md、-G0-prd2-verifier-r1.md、-G0-prd2-verifier-r2.md

AC の追跡（芯の85件）：
- 件数
  - PRD の AC は136件で、そのうち選択肢が51件、芯が85件です。
  - 設計メモ 2 の行は85件ちょうどでした。芯の AC との差、重なり、空の欄は、どれも0件です（上の xcheck.py の出力）。
- 章ごとのたどり方
  - 登録と最初の本（AC-1〜12、92、113。14件）
    - 外への問い合わせ：ndlOpenSearch の isbn（AC-2、3、9、10、11、92、113）、title（AC-4、5、6）。ほかは端末の中だけ（AC-1、7、8、12）。
    - 保存の項目：Book の lookupStatus、lastLookupAt、manuallyEdited。
    - つなぎ口：H1、H2、H4〜H6、H8、H13、H14、H20、H21、H26、H29。
  - 本棚と本の画面（AC-13〜18、22〜26。11件）：端末の中だけ。Book と Record。H2、H6、H12、H13、H22。
  - ウィジェット（AC-27〜35、39、40、96、99。13件）：写しは widget-snapshot.schema.json、URL は entry-urls.md。H22、H28、H17。
  - 読み始める、伏せる、数える（AC-42〜62。21件）：Session から Record へ。H4、H5、H7、H9、H10、H12、H15〜H17。AC-62 は H8、H22、H28 も使う。
  - しおり（AC-63、64、71〜76、95。9件）：Book の line と page、写し。H7、H13、H22。
  - 読み終えた夜（AC-77〜82、86、87。8件）：Book の shelf と finishedAt。H2、H13、H22。H25 は選択肢 (4) の部分だけで使う。
  - 設定と保存（AC-88〜91、93、103。6件）：H7、H13、H29、H31。クレジットの文は ADR 0004。AC-103 は H29 と G2 の grep で見る。
  - 速さ（AC-100〜102。3件）：H2（perf500）、H10、H22。G3 は Perf の構成で測る（裁定 29）。
- 行はあるが、契約のままではたどりきれない AC
  - AC-101：重大1。
  - AC-9、10、11、113：要修正2 と 3。
- つなぎ口の照合
  - 芯の AC が使う23個は、どれも test-hooks.md に節があります。
  - 各節の「使う AC」とのずれは H29 の5件だけで、意図して足したものです。

エンドポイントの表（認可の空欄なし）：
| operationId | 誰が呼べるか | 持ち主の確かめ | 返す項目（アプリが読むもの） | 回数の上限 |
|---|---|---|---|---|
| ndlOpenSearch（GET https://ndlsearch.ndl.go.jp/api/opensearch） | 誰でも呼べる（相手の公開 API。`security: []`。契約:51） | 該当なし。相手は利用者のデータを持たず、返すのは公開の書誌。ID、クッキー、キャッシュは送らず、残さない（ADR 0004 の表の 9） | 契約:95-104 の7つの要素だけ。ほかは読まない | 同時に1件（ADR 0004 の表の 6、契約:48）。ISBN は加えたときと前に来たとき。notFound は24時間に1回、45日まで。書名で探すのは操作1回につき cnt=200 で1回。待ちは30秒、応答は2 MB まで。続けて押したときの扱いは書いていない（P1） |
- 判断：自前のサーバーがなく、相手には利用者のデータがありません。だから、持ち主を確かめる認可は要りません。`security: []` と説明の文で十分です。こちらが受け持つのは、受け取った応答を確かめることで、打ち切り、大きさの上限、外部の実体を読まない設定、100字で切ること、ISBN の直し方が、ADR 0004 と設計メモ 7 の D の行にあります。

G0 で verifier が挙げたつなぎ口：
- G0 r1 の証拠の 4 にある H1〜H14
  - H3 は H2 にまとめ、H11 は外部の計測がないので外しました。理由は test-hooks.md の 5 にあります。
  - ほかはすべて contracts/ にあります。
- flip-research の H15〜H18：あります。
- prd2 r1 の要修正3 で挙がったもの：すべてあります。
  - H2 の項目、H8 を途中で戻すこと、H8 と H20 の数え方（H29 の outcome offline）、H10 の S-3、H13 の本ごとの項目、H17 の entry と回数、H7 の book.status と mark.save、H21 のカメラなし、H22 の外からの読み出しと枠と URL、H14 のコマンド。
- prd2 r2 の指摘11
  - 芯の分（H22 の appearanceID、H29 のエンコードを戻した記録）はあります。
  - H23 の URL、H30、見た目の id を H13 で読むことは選択肢の分で、裁定 24 により後で足します。
  - 「AC-101 は分け方しだい」：契約が AC と合っていません（重大1）。

元に戻しにくい判断と、私のいちばん強い反論：
| 判断（ADR） | 私の反論 | ADR の答えと戻し方 | 結果 |
|---|---|---|---|
| 最低 iOS 26、パッケージ2つ、ReadingStore は MainActor（0001） | 1冊に1,000件の本の画面を MainActor で読むと止まる | AC-101 と Hangs で測り、超えたら @ModelActor に移す（:51-52、:73） | 測る投入が違う（重大1）。直れば受け入れる |
| 主の保存先は App Group の外、等級は既定（0002） | 芯だけなら主の保存先は強い等級にできる。強い方から緩める方が戻しやすい | 案 C と、見直す条件「(5) と（ショートカット）を両方回したら比べ直す」。戻す手間は中（:6、:91、:95） | 受け入れる |
| 自前の縦書きの組み（0003） | 25個の Text を置くウィジェットは、vibrant の描き方、拡張のメモリ、OS の更新での字形の位置のずれに弱い | 見直す条件（G4-1、G4-3、AC-102、字形の単体テスト）、次の案 C、戻し方（View だけを替える） | 受け入れる（未確認は G4） |
| 書誌は NDL だけ、「収集」に当たらない（0004） | 表示は「データの収集なし」でも、利用者の入れた書名が外へ出る。審査で問われうる | 反論2 と「検索履歴」への切り替え、見直す条件。Apple の定義の文は上の引用で確かめた | 受け入れる。法律は K1 |
| つなぎ口は Debug と Perf だけ（0005） | Perf は Release と同じバンドル ID なので、誤って Perf を archive して出しうる | G2 の手順 3〜5（出す archive に nm と strings をかけ、Perf では1以上になることも見る） | 受け入れる |
| 写し、URL、つなぎ口の契約の版 | アップデートの直後に、古い拡張が新しい写しを読む | 知らない項目は無視し、知らない版は unavailable で描き、起動のたびに写しを書き直す | 受け入れる |
| URL スキームを App Store の版に登録（entry-urls.md） | ほかのアプリから、入れていることを調べられる | 書いていない | P6 |

作り手が反論を頼んだ所：
- ReadingStore を MainActor にしたこと：重大1 が直れば受け入れます。
- 保護の等級を既定にしたこと：受け入れます。写しはロック中に拡張が読み、主の保存先にも見直す条件があります。
- cnt=200 と端末での並べ直し：受け入れます。AC-4 の6件は書名がどれも同じで、同じ組の中は応答の順のままなので、期待（I4、I5、I6）とぶつかりません。遅さ（5.70秒、635,702 バイト）と見直す条件も書いてあります。
- 「収集に当たらない」：受け入れます（最後は G5）。上の Apple の文と合います。
- クレジットの文：受け入れます。17-4 の明記の文を1文目が、データプロバイダの名前（国立国会図書館蔵書、国立国会図書館新着書誌情報）とデータ提供機関（国立国会図書館）を2文目が満たします。
- 写しから ISBN を外し、隠すときに書名を書かないこと：受け入れます。スキーマが弾くことを自分で確かめました（上の6通り）。
- URL スキームを App Store の版にも登録すること：受け入れます。P6 を足してください。
- 小さい仮名のずらしを、組むときに Core Text で引くこと：受け入れます。拡張でのビルドは、ios/ を作る最初の PR で確かめる予定です（ADR 0003:174）。
- G3 は Perf、G4 は Release（裁定 29）：受け入れます。パッケージが -O にならなかったとしても、遅く出る側に振れるので、合格が甘くなることはありません。
- G1-11 の代わりの出し方：P5。
- 道具を GitHub の配布ファイルで動かしたこと：受け入れます（P7）。
- 7-4b で頼まれた所
  - 確かめ（A）の印の付け方：裁定 24 どおりで、problem+json は外の API なので対象外でよいです。
  - 拡張の分離の証拠：G1 には足ります。
  - 知らない値は起きない、という理屈：受け入れます。古い版を上から入れたときは AC-90 の道に入り、データを消しません。

確かめ（A）と（B）を自分で確かめた結果：
- （A）
  - 2 の表：85件と51件の範囲の行があり、空の欄はありません（xcheck.py）。
  - 3 の図：要素8つと矢印9本に、技術、責任、用途、通信の方式があります（読んで確かめた）。
  - 契約の operation：operationId、例3つ、`security: []`、AC 番号があります。
  - spectral と oasdiff：上の出力のとおりです。
  - 互換性を壊す変更：ありません（新規）。
  - 5 のエンティティ：7つとも列はそろっています。ただし書名の持ち方が足りません（要修正2）。
  - 6 の非機能：13行すべてに数字と測り方があります。ただし AC-101 の投入が違います（重大1）。
  - 7：STRIDE の6行があり、受け入れた危険に理由があります。
  - 8：イベント3つと Day 7 継続率に送る場所があります。
  - 9：新しい依存はありません。
- （B）
  - ADR 0001〜0005 のどれにも、案が2つ以上（悪い点つき）、反論、見直す条件、確かめたこと（URL かコマンドの出力）があります。
  - ADR 0005 の文書の引用は、前の段で開いたものです（:142 に書いてあるとおり）。

書誌の確かめ（合格 29/30）：
- 結果の表を数え直すと、既刊20件中20件、新刊10件中9件で、合わせて29件でした。線の27件を超えています。既刊の出版社は10社でした。
- 一覧のコミット（01:42:41）が、問い合わせの記録（01:48:57 から）より先にあり、一覧の行は消えていません（上の git の出力）。

未検証：
- CLAUDE.md:19-23 の iOS のビルドとテストのコマンドは、ios/ がないので動かしていません（G1 では形だけを受け入れました）。
- 7-1、7-3、7-4a の spike（Xcode のビルド、シミュレーターでの UI テスト、notify、H28、窓の読み出し）は、動かし直していません。ADR の記録を読んだだけです。
- 書誌の30件は、問い合わせ直していません（結果の表と、コミットの順だけを確かめました）。
- ADR が引く Apple の文書のうち、app-privacy-details 以外（Data Protection、SwiftData、widgetURL、URLSession、upcoming requirements）は開き直していません。
- design/ の仕様、G0 の verifier の報告、7-1〜7-4a の報告は、関わる所だけを grep と節の抜き出しで読みました。
- 未追跡の .agents/、.codex/、AGENTS.md は判定の対象の外なので、開いていません。

## 記録（指揮役が保存するときに書き足す）
- 関門：G1
- 判定した役：reviewer（観点：設計）
- 回：r1
- 対象：0fbc79c98433bba1bfa561ed14866953fe1b2db0 の時点の、指示書に並んだ契約、ADR、設計メモ、CLAUDE.md、書誌の確かめ
- 日付：2026-10-20
- 指揮役が書き足したこと：結果は FAIL（重大1件、要修正2件、提案10件、Takuma への要確認1件）。重大1 は、PRD の AC-101 の Given（:1131）と contracts/test-hooks.md の perf500（:126）を読んで、指摘のとおりと確かめた
- 判定したモデル：opus（fable が使えないため）
