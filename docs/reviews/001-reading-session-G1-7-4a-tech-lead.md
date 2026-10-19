（指揮役の注）G1 の 7-4a（テストのつなぎ口の契約と JSON Schema、ADR 0005）の、tech-lead の報告。7-4b と verifier への申し送りを残すため保存した。判定ではない。報告の文はそのまま保存した。

## 変更したファイル
新しく作ったファイルは次の9つです。コミットはしていません。ほかのファイルは変えていません。
- /Users/takumamatsuura/reading-app/contracts/test-hooks.md（507行）
  - 1：どのつなぎ口にも効く決まり。入る構成、名前、起動と設定のファイル、Darwin の通知、読み出しの要素、失敗のときの返り方、時刻の書き方。
  - 2：芯の23個。それぞれに、目的、使う AC、動かし方、入力、出力、失敗、本番に入らないこと。
  - 3：テストが読む識別子と属性。
  - 4：選択肢だけで使う7個（H19、H23、H24、H25、H27、H30、H32）。名前と「回す所が決まってから書く」だけ。
  - 5：前の案から変えた所。6：spike の結果。7：照合のしかた。
- /Users/takumamatsuura/reading-app/contracts/hooks/ の JSON Schema 7つ（Draft 2020-12。どれにも examples あり）
  - h02-seed.schema.json：H2 の投入
  - h13-store.schema.json：H13 の読み出し。写しの検査は widget-snapshot.schema.json に $ref でつなぐ
  - h17-state.schema.json：H9、H10、H17 の値の書き方。1行の文字列の形と、読んだあとの形
  - h20-ndl-stub.schema.json：H20 の差し替え。国立国会図書館の要素の名前のまま
  - h22-widget.schema.json：H22 の出力。ADR 0003 の「H22 の口」の案
  - h29-outbound.schema.json：H29 の記録と H31
  - hook-config.schema.json：開き直しとシステムの起動で読む設定のファイル
- /Users/takumamatsuura/reading-app/docs/adr/0005-test-hooks.md（型 B のすべての節。確かめ（B）は3つとも印あり）

## 実行したコマンドと結果
作業の跡（リポジトリの外）は次の場所です。
- メモ：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-7-4a/notes.md
- スクリプト：同じフォルダの gen/gen.py、gen/check.py、gen/xcheck.py
- ログ：同じフォルダの check-repo.log、xcheck2.log、uitest-probe1.log、uitest-hookwin.log

1. spike 1（Xcode 27.1、iOS 27.0 のシミュレーター）
   - 準備：7-3 の spike のプロジェクトを scratchpad に写しました。端末 tl-g1-7-4a は `xcrun simctl create` で作り、最後に `xcrun simctl delete` で消しました（消したあとの数は0）。
   - コマンド：`xcodebuild test -project Spike.xcodeproj -scheme SpikeApp -destination id=<端末> -only-testing:SpikeUITests/AXTests/testProbe`
   - 出力：
     - `PROBE1=imp=module;args=[-uitest-probe A];env=1;notify=4242`
     - `CONFIRM=none`、`STATE_AFTER_OPEN=true`
     - `PROBE2=...args=[-uitest-probe A];env=1;...urls=yomuma://open?entry=lock_widget`
     - `PROBE3=...notify=999`
     - `** TEST SUCCEEDED **`
   - 分かったこと：
     - `import notify` が使えます。
     - テストが書いた Darwin の通知の状態を、アプリが読めます。アプリが後ろにいる間に書いた値も読めます。
     - `app.terminate()` のあとに `app.open(_:)` を呼ぶと、確認の窓は出ません。URL は onOpenURL に届き、起動の引数と環境変数も渡りました。
2. spike 2（同じ環境。`-only-testing:SpikeUITests/AXTests/testHookWindow`）
   - 出力：
     - `H_TYPE=1 other=1 hittable=false`
     - `H_BUTTONS=1`
     - `H_BIG_LEN=91500 ms=63`
     - `H_TAP_THROUGH=true`
     - `H_SHEET exists=true value=state=idle;reads=10`
     - `H_ALERT exists=true value=state=idle;reads=13`
     - `** TEST SUCCEEDED **`
   - 分かったこと：つなぎ口だけの窓に置いた要素は、ボタンの数を変えず、下の画面の操作を邪魔しません。シートや alert が出ている間も読めます。
3. JSON Schema の検査
   - コマンド：`<7-3 の venv>/bin/python -I -W ignore gen/check.py /Users/takumamatsuura/reading-app/contracts/hooks /Users/takumamatsuura/reading-app/contracts/widget-snapshot.schema.json`
   - 使ったのは jsonschema 4.25.1（7-3 の venv。読むだけ）。
   - 結果：
     - metaschema の検査：8つすべて OK（hooks の7つと widget-snapshot）。
     - 例：16件すべて OK。
     - H17 の1行の例：形が合い、読み方どおりに直すと examples と同じになりました。
     - NG は0件。わざと契約に合わなくした17通りは、すべて弾かれました。たとえば、今の本が2冊、tsundoku の本に finishedAt、1441分、dc:title がない、normal なのに組みの結果がない、出どころが url、写しの page が10000。
4. 芯の AC との照合
   - コマンド：`python3 -I gen/xcheck.py /Users/takumamatsuura/reading-app`
   - 出力：
     ```
     core ACs in memo: 85
     core ACs found in PRD 11: 85 missing: []
     contract core hooks: 23 [1, 2, 4, 5, 6, 7, 8, 9, 10, 12, 13, 14, 15, 16, 17, 18, 20, 21, 22, 26, 28, 29, 31]
     contract option names: [19, 23, 24, 25, 27, 30, 32]
     MISSING from contract: none
       option-only hook H23 appears in core ACs: ['AC-34', 'AC-39', 'AC-40']
       option-only hook H24 appears in core ACs: ['AC-103']
       option-only hook H25 appears in core ACs: ['AC-17', 'AC-18', 'AC-77', 'AC-78', 'AC-79', 'AC-80', 'AC-81', 'AC-87']
     core hook set == brief's 23: True
     H29: uses=1 doc=6 doc-lacks=[] doc-extra=[4, 9, 10, 11, 113]
     ```
   - H29 のほかの22個は、つなぎ口ごとの「使う AC」が、PRD と設計メモから数えた AC と一致しました。
   - H23、H24、H25 は、芯の AC の中の選択肢の部分だけに出ます（G1 デザインの判定 r1 の D と同じ）。
   - H29 に多く出ている5件は、わざと足したものです。H20 の問い合わせの順と回数を H29 で読むためです。

## 決めたこと
- 構成：つなぎ口は Debug と Perf だけに入ります。Perf は、Release と同じ最適化にコンパイルの条件 `UITEST_HOOKS` を足した構成です。Release（TestFlight、App Store）には入りません。
- コードの置き場所：
  - アプリのターゲットの `UITestHooks/` の下だけに置き、ファイルごと `#if UITEST_HOOKS` で包みます。
  - パッケージと拡張には書きません。パッケージは、時計、通信の部品、保存の前の確かめ、再読み込み、外の URL を開く部品を init で受け取ります。
- G2 での確かめ方（ADR 0005）：
  - Release の build settings に `UITEST_HOOKS` がないこと。
  - grep で、包まれていない置き場所がないこと。
  - Release の2進のファイルで `nm` と `strings` が0件になること。
  - 同じ確かめを Perf で動かすと1件以上になること（空振りしていない証拠）。
- 動かし方：
  - テストの起動の引数と環境変数から設定を作り、App Group の `UITestHooks/config.json` に書きます。
  - 引数のない開き直しと、システムが起こしたプロセスは、このファイルを読みます。H4、H6、H7、H8、H20、H26 が効きます（G0 intents の verifier の要修正3）。
  - 動いている途中の操作は Darwin の通知で送ります（`yomuma.uitest.clock`、`.offline`、`.barcode`、`.ndl.release`）。
- 読み出し：つなぎ口だけの窓に `hook.state`、`hook.store`、`hook.widget`、`hook.outbound`、`hook.error` を置きます。H9 と H17 の値を載せる要素は `hook.state` です。
- H28：(a) の `XCUIApplication.open(_:)` に決めました（spike 1）。確認の窓が出たときは、(b) の springboard の「開く」に切り替えます。(c) は OS の URL の道を通らないので使いません。
- 再読み込みの数え方：
  - 写しを書いたあとに `reloadAllTimelines()` を1回だけ呼び、その呼び出しの回数を数えます。W-1 と W-2 は1回で頼むので、ファミリーの数では数えません。
  - 呼び出しごとに出どころを付けます（launch か、写しを変えた保存の H7 の名前）。
  - AC-33 は、`mark.save` の差が1かを見ます。
- AC-99 のまとまりの数は、H22 がアプリの中で、VoiceOver と同じたどり方で数えます。
- H7 の対象に `settings.save` を足し、対象は11個になりました。
- 読み終えた日時 finishedAt：H2 の `books[].finishedAt` で入れ、H13 の同じ名前で読みます。
- 見た目の文字と読み上げが違う要素は、`label` の属性で読みます。対象は `bookmark.page`、`result.summary`、`book.record.row.<id>`、`colophon.*`。
- `search.clear` と `mark.page.previous` の使い方は、test-hooks.md の 3 に書きました。
- H20：
  - 応答の種類は items、zero、paramError（HTTP 200 の0件）、http。
  - 10桁の値を `dcndl:ISBN` にも `dcndl:ISBN13` にも書けます。`dcndl:volume` も書けます。
  - `hold` を付けた応答は、テストが送るまで止めます。
  - 差し替えを入れずにテストを起動すると、本物には送らずに失敗させ、H29 に `noStub` と残します。H29 のホストは ndlsearch.ndl.go.jp です。
- G1-10：
  1. 実機に Perf のビルドを入れ、`-uitest-seed-preset perf500` で本500冊と記録5,000件を入れる。
  2. アプリを消さずに、Release のビルド（開発の署名か TestFlight）を上から入れる。
  3. signpost で測る。
- いちばん強い反論：G3 は Release でないビルドで、時計、通信、ウィジェットを差し替えて確かめます。だから G3 が通っても、出す版で落ちうるうえ、つなぎ口のコード自体にも不具合がありえます。
  - それでも選んだ理由：差し替えるのは薄い継ぎ目だけで、計算と View は本番と同じコードを通ります。差し替えで見えない所は G4（Release の実機）と G2 のソースの確かめで補えます。Perf は Release と同じ最適化です。
  - この判断は、reviewer に反論を出してもらうよう頼みます（自分の契約と ADR を自分で合格にはしません）。

## 7-4b への申し送り
- contracts/entry-urls.md
  - 5 の「H22 の再読み込みの要求が0回」は、「launch のほかの出どころが0」に直してください。写しは起動のたびに書くので、起動の分の1回は残ります（widget-snapshot.schema.json）。
  - 6 の H28 の申し送りは、決まったので test-hooks.md の H28 を指してください。
- 設計メモ
  - 3：187行目は、ADR 0005 と test-hooks.md を指すように直してください。
  - 4：test-hooks.md と hooks の7つ、上の 3 の検査の出力を足してください。
  - 6：AC-100〜AC-102 は、G3 では Perf の構成で測ると書いてください。
  - 7：「つなぎ口がストアの版に入らない」の行は、ADR 0005 の G2 の手順を指してください。
  - 10：ADR 0005 と、その未確認の項目を足してください。
  - 2（任意）：AC-4、AC-9、AC-10、AC-11、AC-113 の行に H29 を足してください。
- CLAUDE.md：次を書いてください。ios/ がまだないので、コマンドは「未確認」になります。
  - 構成が3つ（Debug、Perf、Release）あること。
  - つなぎ口はテストの構成だけ（`UITEST_HOOKS`）という決まり。
  - H14 のコマンド。
  - JSON Schema の検査のコマンド（venv の jsonschema）。
  - app.json の commands の更新は、Takuma に頼んでください。
- dependencies.md：アプリの依存は増えていません。jsonschema は検査の道具なので、アプリの依存には入れていません。
- ADR 0001：構成の行に Perf を足すかを決めてください。7-3 の頼みの［推測］外しも残っています。

## verifier への申し送り
- 起動の補助の関数：
  - 起動のたびに、`hook.error` がないことを確かめてから進んでください。
  - 開き直すときは、`launchArguments` と `launchEnvironment` を空にしてから `launch()` を呼んでください。設定のファイルで、時計などの差し替えが続きます。
- Darwin の通知：`yomuma.uitest.clock` には setUp で登録し、tearDown まで登録を持ち続けてください。時計を進めるときは、状態の値を足してから知らせます。
- 投入と差し替えの JSON は、起動の前に contracts/hooks のスキーマで検査してください。本500冊は `-uitest-seed-preset perf500` で入れます。
- 本の登録を通るテストには、`UITEST_NDL_STUB` を必ず入れてください。入れないと、本物に送らずに失敗します（`noStub`）。
- AC-40 と AC-62 は、`app.terminate()` のあとに `app.open(URL)` で起こしてください。
- AC-99 は、H22 の `accessibility.groupCount` で見てください。XCUITest の子の数では数えません。
- AC-28 の L は、H22 の `composition.referenceL` で読んでください。
- AC-33 は、`widgetReloads` の `mark.save` の差が1かを見てください。
- G2 で、`-uitest-readouts off` で測った H10 の値をどう読むかを決めてください（test-hooks.md の H10 の注）。

## 未解決
1. PRD 12 の「Release の構成で測る」を、G3 では Perf と読んでよいか。指揮役と pdm に確かめてほしいです。
2. 未確認のまま置いたもの（ADR 0005）。下の3つの上から順に、ios/ を作る最初の PR か G4 で確かめます。
   - Perf の構成で、ローカルのパッケージが -O で組まれるか。
   - nm で Swift の型の名前が見えるか。
   - TestFlight を上から入れても、アプリの入れ物が残るか。
   - 画面の外の窓で、まとまりの数を数えられるか。
   - 起動の環境変数の大きさの上限（H2 の 200,000 バイトは［推測］）。
   - 登録する者がいないとき、通知の状態が残るか。
   - H10 の「最初に出た時」に、CATransaction の確定の時を使えるか。
3. H22 の例の `widget.unavailable` の文は仮の文字です（「（文言キー widget.unavailable の文）」）。
4. 未着手：なし（手数は42回）。

## 記録（指揮役が保存するときに書き足す）
- 種類：作り手（tech-lead）の報告（判定ではない）
- 書いた物：contracts/test-hooks.md、contracts/hooks/ の JSON Schema 7つ、docs/adr/0005-test-hooks.md（コミット e8fa4eb）
- 日付：2026-10-20
- 指揮役の判断：未解決の1（PRD 12 の「Release の構成で測る」を G3 では Perf と読んでよいか）は、よいとする（裁定 29）
