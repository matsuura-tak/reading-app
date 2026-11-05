（指揮役の注）G1 の 7-2（書誌の30件の確かめ、ADR 0004、国立国会図書館サーチの契約）の、tech-lead の報告。判定ではない（書誌の確かめの合否は、先に決めた線による結果）。報告の文はそのまま保存した。

## 合否
**合格。** 30件中29件で書名、著者、出版社がそろいました（線は27件）。
- 既刊は20件中20件、新刊は10件中9件です。
- 届かなかった1件は新刊10（岩波書店、9784001127188）で、0件でした。
- 出て14日以内の5件（記録だけ）は3件です。講談社の9784065452974（5日前）と新潮社の9784106111389（1日前）が0件でした。
- 選び方を「ISBN が一致する最初の item」（ADR 0004 の決め方）にしても29件で同じです。35件すべてが0件か1件だったためです。
- 書誌をこの2つに絞れることも確かめました。返った32件の link はすべて R100000002 でした。比べるために dpid なしで1回引くと、R100000134 と R100000136 の item も返りました。
- 合否は、一覧に先に書いた線と数え方のままで出しました。本の差し替え、足し、外しはしていません。
- 結果どおりなら、PRD の冒頭の (iii) で回さない限り、v1.0 から課金です。18 の Q5 は Takuma に聞かなくて済みます。

## 変更したファイル
コミットはしていません。
- /Users/takumamatsuura/reading-app/docs/adr/features/001-reading-session-ndl-check.md
  - 末尾に「結果」の節を足しただけです（`git diff --numstat` → `89 0`）。一覧の節は変えていません。
  - 中身：本ごとの表35行（件数、dc:title、取り出した著者、出版社、そろったか、どちらの書誌か、時刻）、合計と合否、14日以内の5件、書名で探す形（AC-4）の結果、0件だった3件の記録（dpid なし、openBD。合否には入れていない）。
- /Users/takumamatsuura/reading-app/docs/adr/0004-bibliographic-lookup.md（新規。型 B のすべての節と、確かめ（B）の3つの印）
- /Users/takumamatsuura/reading-app/contracts/ndl-opensearch.yaml（新規。OpenAPI 3.1）
  - GET /api/opensearch の1つだけ。operationId は `ndlOpenSearch`、引数は dpid、isbn、title、cnt です。
  - 応答の例は3つ（見つかった、0件、引数の誤り）で、どれも実際の応答から取りました。application/xml と text/xml の両方で引けます。
  - 要素の対応表と、`security: []` も書きました。

## 決めたこと（ADR 0004）
- **問い合わせの形**：dpid は `iss-ndl-opac iss-ndl-opac-inprocess` です。
  - iss-ndl-opac-national は iss-ndl-opac の一部なので入れません。
  - ISBN で引く形は cnt を付けません。
- **書名で探す件数**：cnt=200 で1回だけにし、ページ送りはしません。design r1 の推奨の cnt=50 から変えました。
  - OpenSearch には並べ替えの引数がありません（仕様書 第1.5版 表 4-1）。応答は書名の読みの順でした。
  - cnt=50 では、新潮文庫の『人間失格』（264件中175番目）が入りません。
  - 端末では、ISBN のない item と重なった ISBN を除き、並べ直します（書名の完全一致 → 前方一致 → ほか）。
  - 測った値：cnt=200 は5.70秒、635,702 バイト。cnt=500 は24.63秒。
- **要素の対応**：書名は dc:title に dcndl:volume を足します（例「マーブル館殺人事件 上」）。
  - 出版社は dc:publisher の1つ目、レーベルは seriesTitle の「 ; 」より前、出版年は issued の頭の4桁です。
  - ISBN は10桁なら13桁に直します。実際の応答で、13桁の本に「4-10-100605-9」が入っていました。
  - 書名と著者は100字で切ります。
- **送り方**
  - 同時に送るのは1件です（17-4 (1)）。待ちの打ち切りは30秒（p90 7.18秒、最大14.83秒から）、応答の上限は2 MB です。
  - `URLSessionConfiguration.ephemeral` に urlCache=nil、cookie なしを足します。応答に `Cache-Control: max-age≈6万秒, public` が付くため、既定の構成では探した ISBN と書名がディスクに残ります。
  - XML は XMLParser で、`shouldResolveExternalEntities=false` を明示します。
  - 通信のコードは ReadingStore の1ファイル（名前は仮で NDLOpenSearchClient.swift）だけに置きます。AC-103 の grep で見る場所です。
- **問い合わせ直し**：失敗したら、その回は残りを送りません。lastLookupAt は HTTP 200 のときだけ書きます。見つかった本は問い合わせ直しません。
  - 引数の誤りも HTTP 200 の0件になります（仕様書と実測）。だから URL の形は単体テストで固定します。
- **openBD**：使いません。AC は足しません。
- **クレジットの文（G1-5）**：日本語と英語の構成の文を ADR に書きました。
  - 一覧の名前を入れました：国立国会図書館蔵書、国立国会図書館新着書誌情報、データ提供機関は国立国会図書館。英語は National Diet Library Catalog と NDL newly acquired bibliographic data で、日本語の名前も括弧で出します。
  - CC BY 4.0 の 3(a)(1)(B) に合わせ、「表示用に整えています」も入れました。
- **収集に当たるか（G1-12）**：当たらないとしました。表示は「データの収集なし」です。
  - PrivacyInfo は、Tracking を false、収集の型を空、required reason API を0件にします。
  - 最後に決めるのは G5 の reviewer です。
- **ラテン文字の著者（G1-13）**：35件中5件で「Horowitz Anthony」の形になりました。
  - 推奨は案 C です。author 要素の責任表示から「アンソニー・ホロヴィッツ」の形を取り、5件すべてで取れました。
  - PRD の決まりが変わるので、決まるまでは PRD のまま作ります。
- **いちばん強い反論**：出て14日以内の本は5件中2件が CC BY の書誌になく、最初の登録で「見つからない」が出ます。openBD や JPRO を足せば3件とも埋まりました。
  - それでも選んだ理由：線は15〜28日前の本で決めてあり、そこは10件中9件です（6件は新着書誌情報から）。
  - 見つからない本は手で入れられ（AC-7）、24時間ごとに45日まで問い合わせ直します（AC-113）。
  - JPRO を足すと CC BY の外になり、課金するなら申請が要ります。openBD は条項の確かめと AC の追加が要ります。
  - 見直す条件は G4-10 で10冊中9冊に届かないときです。
- **お願い**：ADR 0004 も契約も、私が書いて私が印を付けました。合格にはしていないので、reviewer に反論を出してもらってください。特に見てほしいのは次の3つです。
  - cnt=200 と端末での並べ直し
  - 「収集に当たらない」の判断
  - クレジットの文

## 実行したコマンドと結果
作業のフォルダは /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-7-2/ です。中身：raw/（生の XML）、queries.jsonl、results.json、notes.md、py/ndl.py、py/extra.py。
- **問い合わせ**：`python3 -I py/ndl.py query <一覧> <作業のフォルダ>`
  - 2026-10-20 01:48:57〜01:55:05 に76件を1件ずつ送り、間を1.2秒空けました。
  - 数えた形は `https://ndlsearch.ndl.go.jp/api/opensearch?dpid=iss-ndl-opac%20iss-ndl-opac-inprocess&isbn=<ISBN13>` で、35件すべて HTTP 200 でした。
  - 数え方は `analyze` で出しました。出力：`PASS-LINE count (first item): 29 / 30 | backlist 20 | new 9 | alt (ISBN-matching item): 29 | recent (record only): 3 / 5`
  - 著者の取り出しは、先に AC-92 の例7つで確かめました（7つとも OK、「Fox Susan」を含む）。
  - どちらの書誌から返ったかは、dpid=iss-ndl-opac-inprocess だけで引き直して見ました。新刊は新着書誌情報が6件、蔵書が3件でした。
- **書名で探す（AC-4）**：`title=人間失格&cnt=50` → 264件中50件、ISBN のある item は21件で、9784101006055 は入りませんでした。記録だけで cnt=200 と cnt=500 も引きました（上の数のとおり）。
- **引数の誤りの確かめ**：cnt=abc、知らない dpid、dpid だけの3つは、どれも HTTP 200 で totalResults 0 でした。
- **表と元のデータの照合**：結果の表35行と results.json を照らし、食い違いは0件でした（`mismatches []`、`counted ok 29 recent ok 3`）。
- **spectral**：node と brew がないので、GitHub の公式リリースの v6.17.0 の macOS 用のファイルを scratchpad に置いて動かしました（sha256 cb7e1bd3…）。ルールは scratchpad の `.spectral.yaml`（`extends: ["spectral:oas"]`）です。
  - `spectral-macos-arm64 lint contracts/ndl-opensearch.yaml --ruleset …/.spectral.yaml --fail-severity hint` → `No results with a severity of 'hint' or higher found!`、exit 0
  - 既定の重さの線でも `No results with a severity of 'error' found!`、exit 0
  - 契約の XML の例3つは、ElementTree で読めました（`well-formed: 3`）。
  - oasdiff は指示どおり行っていません（7-4）。
- **開いたページ**
  - 国立国会図書館サーチ：API のヘルプ（17-4 (1)(2)）、データプロバイダ一覧（日本語と英語）、外部提供インタフェース仕様書 第1.5版の PDF（PDFKit で文字を取り出して読んだ）
  - Apple の文書：app-privacy-details、URLSessionConfiguration の ephemeral と2つの timeout、privacy-manifest-files
  - CC BY 4.0 の legalcode

## 7-3、7-4 への申し送り
- **7-4**
  - 設計メモ 2 の AC-4 の行が「cnt=50」のままです。cnt=200 と並べ直しに直し、195行目の「（仮）」を外してください。
  - 設計メモ 4 に貼るもの：上の spectral の出力。oasdiff は「新規」（main に契約がない）。
  - 設計メモ 5：Book の要素の対応は、契約の対応表を指すように直してください。
  - 設計メモ 7：次の［推測］が決まりました。
    - S の行：長さは100字で切る
    - I の (c)：ephemeral、キャッシュなし、クッキーなし
    - D の行：cnt=50 を cnt=200 に、待ちは30秒、上限は2 MB
  - 設計メモ 10：ADR 0004 は書き終えました。
  - contracts/.spectral.yaml を作ってください。7-2 では書けない場所なので、scratchpad に置きました。CLAUDE.md の spectral の動かし方（node なし）も決めてください。
  - H20 の差し替えは NDL の要素の名前のままにします。含めるもの：dcndl:volume、10桁の値の入った dcndl:ISBN と dcndl:ISBN13、0件、引数の誤り。H29 と G4-20 のホストは ndlsearch.ndl.go.jp です。
- **7-3**
  - NDL の書名と巻には半角の括弧（例「第3部[2]」）が入ります。書名に巻を足すので、写しとウィジェットの書名が長くなります。縦書きの置き換えの表を決めるときに見てください。
- **ほかの役**（指揮役から回してください）
  - designer：`settings.dataSources` の日英の文を文言表に写すこと。S-8b に最大約200件の行が並ぶこと。
  - verifier：AC-4 の並べ直しのテストと、H20 の形。

## 未解決
1. **G1-13（ラテン文字の著者）は、決める人が要ります。** 推奨は案 C です。
   - 採るなら、pdm が PRD の 11 の冒頭と AC-92 を直し、verifier が AC-92 に行を足します。designer と pdm の判断が要るので、指揮役から回してください。
2. **書名で探す結果の並べ直しを AC にするか。** PRD にない振る舞いで、AC-4 の今の期待値とはぶつかりません。pdm と verifier に聞いてください。
3. **未確認のまま置いたもの**
   - HTTP 200 のほかの応答の形
   - dpid で絞ったとき、item の値に、同定でまとめたほかの提供元の値が混ざらないか（返った link はすべて R100000002 でした）
   - 相手が「+」を空白と読むか（`%2B` にして避けます）
   - R100000001 はどの提供元か（一覧の表に行がありません）
   - Swift での作り（ephemeral、XMLParser、NWPathMonitor）は spike をしていません
   - 案 D（SRU）の並べ替え
4. **新刊の穴**：出て14日以内の本は5件中2件が NDL にありませんでした。合否には関わりませんが、課金の判断の材料として Takuma に伝えるかは指揮役が決めてください。
5. **spectral の入れ方**：npx でなく、公式の配布ファイルを scratchpad で動かしました。CI に入れる形は 7-4 で決めます。

## 記録（指揮役が保存するときに書き足す）
- 種類：作り手（tech-lead）の報告と、書誌の確かめの結果
- 書いた物：docs/adr/features/001-reading-session-ndl-check.md（結果の節を足した。一覧の節は変えていない：git diff --numstat 48263ef は 89 0）、docs/adr/0004-bibliographic-lookup.md、contracts/ndl-opensearch.yaml（コミット b29d795）
- 日付：2026-10-20
- 指揮役が確かめたこと
  - scratchpad の results.json（35行）から数え直した：既刊 20/20、新刊 9/10、14日以内 3/5。合格の線の30件では 29/30 で、線（27件）を超える。届かなかった ISBN は 9784001127188（新刊）、9784065452974 と 9784106111389（14日以内）で、報告と同じ。
  - 9784001127188 を同じ形（dpid=iss-ndl-opac iss-ndl-opac-inprocess）で問い合わせ直し、totalResults 0 を確かめた。
- これで決まること：PRD の冒頭の (iii) で回さない限り、v1.0 から課金する。18 の Q5（申請を出すか）は聞かなくてよい
