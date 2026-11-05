# 001-reading-session G3 契約 r3 の直し（横書きの composition、1-1 と H33 (b) の範囲をそろえる、提案3・4・5・7、裁定4）tech-lead r4

## 変更したファイル
- /Users/takumamatsuura/reading-app/contracts/hooks/h22-widget.schema.json
- /Users/takumamatsuura/reading-app/contracts/test-hooks.md
- /Users/takumamatsuura/reading-app/docs/adr/0003-vertical-composition.md
- /Users/takumamatsuura/reading-app/docs/adr/0005-test-hooks.md

始める前に BASE を確かめました（`git rev-parse --short HEAD` → `392c224`）。ios/、design/、ほかの docs/ には触っていません。コミットもしていません。

### 変えた所
1. **要修正1（横書きの `composition`）は案 (i) で直しました。**
   - スキーマの `composition.required` を `orientation`、`displayedLine`、`shortened` の3つに減らしました。
   - `composition` に `allOf` を足しました。`if orientation == vertical` のとき、`then` で9項目を必須にします。9項目は `frame`、`fontSize`、`L`、`referenceL`、`columnCount`、`feedCount`、`kinsokuRelaxed`、`slack`、`cells` です。
   - 制約の構造を BASE と比べました（スクリプトで抽出して diff）。違いは「required の入れ替え」と「allOf の追加」だけで、名前・型・enum・minimum・minItems は同じです。
   - test-hooks.md の「範囲の外（いまのまま）」は消し、「横書きの一行」という節に書き直しました。
     - 横書きは手順1（縮め方）だけを通り、`state` は `normal` です。
     - 必ず書く項目は `orientation: horizontal`、`displayedLine`、`shortened` です。場所を描いたときは `page` も書きます。
     - 縦書きの9項目はキーごと書きません。`columnCount: 0` や `cells: []` のように書くとスキーマ違反になる、とも書きました。
   - 横書きの例を4つ目の examples として足しました（「It was raining.」、172×76、書名 Rain、p.61）。
2. **要修正2**：1-1 の例外の文を「保存や読み込みの関数の中、または（H33 だけは）View の側で、読み込みを呼ぶ所か読み込んだ結果を画面に渡す所（H33 の (a)・(b)）」に直しました。H33 (b) の見出しの言い方、H33 の「動かし方」の止める所、ADR 0005 その2 の決めたことも、同じ範囲にそろえました。
3. **提案3**
   - 手順5の「25字以下ではここまで来ない」を、次の正確な文に直しました：送らなければ C＝⌈n÷L⌉ なので、25字以下なら必ず入り、字は落ちない。ここまで来るのは、禁則の字が多く送りで列が増える一行だけ。
   - **reviewer が出した「送りで列が1字になる並びを除く」も正確ではありませんでした。** 「あいうーーーー」をくり返した25字は、どの列も1字にならないのに、153×68 の 13pt で C が7になり、手順5に来ます（検算）。そこで、例を2つ挙げ、「AC-28 の一行はこういう並びで作らない」と書きました。
   - 手順3で送りを止めたときの値を1行で決めました。
     - `feedCount` は実際に送った字を数えます。同じ字が2つの列を続けて越えたら2と数えます。
     - `kinsokuRelaxed` は手順5の終わりだけ真で、手順3で止めたときは偽のままです。
     - 列の先頭に禁則の字が残ったかは `cells` の row 1・column 2 以上の字で見ます。
   - スキーマの `feedCount` と `kinsokuRelaxed` の説明も同じ内容に直しました。
4. **提案4**
   - 2度押しを弾く印は、`Task` を作る前に同期で立て、処理が終わったら下ろす、と書きました。
   - この1つの印で、`Task` が走る前の窓と、門で止めている間に2回目が素通りする窓の両方を塞げます。
   - `catalog.lookup` を止めている間の2つ目のバーコードはボタンではないので、この条件の外に残る、と明記しました。
   - ADR 0005 その2 の「招く悪い結果」にも1文足しました。
5. **提案5**：ADR 0003 の追記に1行足しました。決定1の W-1・W-2 の配置の記述（W-1 の縦1列の書名 10pt、W-2 の下部の書名＋ページ）も screens.md で置き換える、という内容です。横書きの行と、検査の出力も足しました。
6. **提案7**：スキーマの全体の説明、`cells` の説明、test-hooks.md の `cells[]` の行に、「examples の cells は抜粋」と書きました。
7. **裁定4**：test-hooks.md の 7 に、読み出しの全体を検査する1行を足しました。
   - `hook.widget` の値を保存し、同じ venv で h22 スキーマの全体に照らします。エラーは全部出して終了コード 1、なければ `hook.widget OK: <n> renders` で終了コード 0 です。
   - 保存する枠：W-1・W-2 の4つの枠。
   - 保存する投入：state が normal（縦書きと横書き）、noLine、noLineNoPage、hidden、empty、unavailable になるもの。
8. **加えて書いたこと（名前・型・enum は変えていません）**：H22 の出力に `state` と `texts` の組の表を足しました。スキーマの texts の enum や説明から読める範囲を表にしたものです。読み出しをスキーマに合わせる直しで ios-engineer と verifier が迷わないようにするためで、reviewer の 4(a) と提案9に当たります。
   - 当てはまるかは上から順に見ます：`unavailable` → `empty` → `hidden` → `normal` → `noLine` → `noLineNoPage`。
   - 一行があるときは、書名を `texts` に書かず、`accessibility.label` にだけ入れます。
9. 5章の「前の案から変えた所」に H22 と H33 の2行を、6章に検査と検算の出力を、冒頭の履歴に今回の分を足しました。

## 実行したコマンドと結果
- `git rev-parse --short HEAD` → `392c224`
- `make check-contracts`（終了コード 0）→ `ALL PASSED: 8 schemas, 29 examples validated with 0 errors.`（例が1つ増えて 28 → 29）
- `grep -cE '^### H[0-9]+' contracts/test-hooks.md` → `31`
- 7 に足した1行を試しました（入力は /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/r5/）。
  - スキーマの examples 4つ：すべて `hook.widget OK`、終了コード 0。
  - 横書きに `columnCount: 0` と `cells: []` を入れたもの：`cells : [] should be non-empty`、`columnCount : 0 is less than the minimum of 1`、終了コード 1。
  - 縦書きから `L` と `cells` を抜いたもの：`'L' is a required property`、`'cells' is a required property`、終了コード 1。
  - 今の実装に似せたもの（`state: "hasLine"`、`entryURL`、トップの `title`）：エラー4件、終了コード 1。
- 手順5に来る並びの検算（`python3 -I`、スクラッチパッドの fit.py、edge.py、edge2.py）
  - 「あ」＋「ー」×24：W-1 の両方の枠で 13pt・L 5・C 5・relaxed 真。
  - 「あいうーーーー」のくり返し25字：153×68 は送ったあとの C が7で relaxed 真。172×76 は 14pt・C 7 で入る。
  - 「そして」＋「…」×6：172×76 で 17pt・C 5・feed 11・relaxed 偽。
  - ランダムな25字20万件を 153×68 で調べると、列が1字にならないのに relaxed になるものが8,903件ありました。

## ios-engineer に頼むこと（今の契約に合わせて書き直した版。前回の5は使わない）
1. **関数を作る**：W-1・W-2 の組み方を `ReadingCore` に nonisolated の純粋な関数1つとして作る（SwiftUI と WidgetKit は import しない）。
   - 入力：ファミリー、幅、高さ、縮める前の一行。
   - 縦書きのときの出力：`frame`、`fontSize`、`L`、`referenceL`、`columnCount`、`feedCount`、`kinsokuRelaxed`、`slack`、`cells`（x と y 付き）、`displayedLine`、`shortened`、`orientation`、`page`。
   - 横書きのときの出力：`orientation`、`displayedLine`、`shortened`、`page` だけ。
   - 記号の値（W-1：i 0、B 43、g 4、R 0、s 17→13。W-2：i 16、B 0、g 0、R 20、s 20→13。列の間 0.25s）は Double の定数で、この関数の側にだけ置く。
2. **手順は test-hooks.md「H22 の組み方」の1〜5どおりにする。**
   - 列の数に上限を付けずに送り、送ったあとの C で入るかを見る。入らなければ s を1下げる。
   - 下限でも入らなければ、送らずに組んで `kinsokuRelaxed=true` にする。
   - `feedCount` は送った字を1つずつ数え、2つの列を続けて越えた字は2と数える。手順3で送りを止めても `kinsokuRelaxed` は偽のまま。
   - `referenceL` は、同じ枠でかな「あ」25字を組んだときの L。
   - 今の `layoutVerticalCells` の上限付きの送りは使わない。
3. **View を直す**：`ReadingWidgetSurfaceViews.swift` の `composeFitted` と `ReadingVerticalFit` を消し、W-1・W-2 の View は1の関数の結果をそのまま描く。
   - `ReadingWidgetMetrics` は ReadingCore の定数を SwiftUI の型に直すだけにする。
4. **組みを render ごとにする**：`SnapshotStore.fullHookPayload` で、全体に1つの `comp` を使い回すのをやめる。`renders[]` ごとに、その request の family、幅、高さで1の関数を呼ぶ。
   - 大きさが読めないときは今どおり `hook.error`（`H22:<値>`）。
5. **`composition` の形**
   - `state` が `normal` のときだけ書く。一行がないときの書名の縦組みは読み出しに出さない。
   - 縦書きのときは9項目すべてを書く。`rowsPerColumn` は `L` にし、`accessibilityLabel` は `composition` から外す。
   - 横書き（AC-30）のときは `orientation: "horizontal"`、`displayedLine`、`shortened`（と描いたときの `page`）だけを書く。`columnCount: 0`、`rowsPerColumn: 0`、`cells: []` はキーごと消す。
6. **読み出し全体を h22 スキーマに合わせる**（reviewer の提案9のずれ。`SnapshotStore.swift` の `WidgetRenderEntry`、`FullWidgetHookPayload`、`ReadingDataStore.hookWidgetJSONString`）
   - **トップ**：書くのは `outputVersion: 1`、`renders`、`reloadRequests{total, byCause}`、`-uitest-widget-show` のときの `showcase` だけ。`title`、`line`、`progress`、`accessibilityLabel`、`snapshot`、トップの `composition`、`reloadTimelineCount`、`lastReloadAt`、`lastRenderMs` は消す。
   - **render のキーを直す**
     - `family` と `size`（文字列）は消し、`request{family, width, height}` にする。width と height は数。
     - `entryURL` は `url` にする。
   - **render に足す**
     - `seq`：このプロセスで組んだ順、1から。
     - `producedAt`：アプリの時計、`YYYY-MM-DDTHH:MM:SS.mmmZ`。
     - `snapshotSource`：`file` か `override`。
     - `unavailableReason`：`unavailable` のときだけ書く。
     - `accessibility{identifier: widget.rectangular / widget.small, label, groupCount}`。
     - `timeline{entries:[{date,state}]（1件以上）, policy: never / atEnd / {after}, elapsedMs}`。
   - **`state` と `texts`**：test-hooks.md H22「出力」の新しい表どおりにする。
     - `hasLine` は `normal` にする。
     - `texts` の `title`、`line`、`page`、`empty`、`widget.empty` は消す。
     - empty、hidden、unavailable は `messageKey` と `message` で書く。
     - 一行があるときは `widget.title` を書かない。`hookWidgetJSONString` が書名を texts に足している所も、この表に合わせる。
   - **hidden のとき**：`accessibility.label` に書名と一行を入れない（AC-34 のテストは生の文字列に「羅生門」がないことを見る）。
   - **`reloadRequests.byCause`**：キーは enum（`launch`、`book.add`、`book.update`、`book.status`、`book.delete`、`mark.save`、`settings.save`）だけ、値は1以上。h17 の決まり「出どころは launch か、写しを変えた保存の H7 の名前」に合わせる。
     - 今の `book.switch` と `book.finish` は `book.status` に、`settings.appearance` は `settings.save` にする。
     - `store.*` は下の「未解決」の裁定を待つ。
   - **エンコーダー**：`.sortedKeys, .withoutEscapingSlashes` は変えない。テストは生の文字列に `yomuma://open?entry=lock_widget` が含まれるかを見ているため。
7. **単体テストを足す**（`ReadingKit`）
   - 契約の表の9行で、s、L、C、送り、`referenceL`、`slack.horizontal` が合うこと。
   - 「あ、」×12＋「あ」で字が落ちない（`cells` の数＝字の数）こと。
   - 「あ」＋「ー」×24（W-1 の両方の枠）が relaxed 真で、`cells` が25個あること。
   - 「そして」＋「…」×6 が feed 11・relaxed 偽であること。
   - 「It was raining.」の `composition` のキーが `orientation`、`displayedLine`、`shortened`（と `page`）だけであること。
8. **確かめて出力を残す**
   - `make ios-build`（警告0）と `make ios-test` を動かす。
   - `-uitest-widget accessoryRectangular:153x68,accessoryRectangular:172x76,systemSmall:148x148,systemSmall:170x170` で、state 6種（normal は縦書きと横書き）になる投入それぞれについて `hook.widget` の値を保存する。test-hooks.md の 7 の1行で全部が `hook.widget OK` になることを示す。
   - 同じ枠の `-uitest-widget-show` の画像と、`fontSize`・`columnCount` が合うことを見る。

## verifier への影響
- **新しい道具**：7 の全体の検査の1行。state 6種と横書きで `hook.widget` を保存して照らします。`showcase` も同じ1行で検査されます。
- **AC-30**：今のテスト（生の文字列に「It was raining.」と「horizontal」が含まれるか）はそのまま通ります。次を確かめる形に強めることを勧めます。
  - `renders[0].composition.orientation == "horizontal"`
  - `displayedLine == "It was raining."`
  - `cells` と `columnCount` のキーがない
  - `texts["widget.line"]` が同じ文字列
- **AC-28**：一行は禁則の字が多い並びで作りません（手順5に来る例を契約に書きました）。列の先頭に禁則の字が残ったかは、`kinsokuRelaxed` ではなく `cells` の row 1・column 2 以上で見ます。`L==referenceL` を先に確かめることは前回と同じです。
- **生の文字列で見ているテスト**：読み出しを合わせると、トップの `snapshot`、`title`、`line` が消えます。それでも次の所に値が残るので、今の contains の確かめは通る見込みです。ただし ios-engineer の直しのあとに実際に動かして確かめる必要があります。
  - 書名：一行があるときは `accessibility.label`、ないときは `texts["widget.title"]`。
  - 一行：`texts["widget.line"]`。
  - 場所：`texts["widget.page"]`。
  - URL：`url`。
  - 空のとき：`messageKey: widget.empty`。
- **`state`**：AC-31 の `state == "noLine"` は変わりません。`hasLine` を読むテストはありません（grep で確かめました）。
- **AC-33 の `byCause["mark.save"] == 1`**：変わりません。

## 未解決
- **`reloadRequests.byCause` と h17 の `widgetReloads` に、enum にない出どころが出ている**（今回の範囲外で見つけたもの。既存）。今の実装は `store.purchase`、`store.restore`、`store.refund`、`store.entitlement`、`book.switch`、`book.finish`、`settings.appearance` を出しています（ReadingDataStore.swift:1677、1709、1853、2469、2518、2569、2618、2657、2698、2708）。h17 の決まり（H7 の保存の名前）に従えば、`book.*` の2つは `book.status`、`settings.appearance` は `settings.save` にできます。`store.*` は当てはまる名前がありません。指揮役に決めてほしいことです。
  - (A) 推奨：tech-lead が h22 の `byCause` と h17 の `widgetReloads` の enum に `store.entitlement` を1つ足し（足すことは版の決まりで許される）、ios-engineer が `store.*` をそこにまとめる。
  - (B) 写しを変えない購入と復元では再読み込みを求めない。返金で見た目を戻すときは `settings.save` として数える。
  - 今回の指示では enum を変えないことになっていたので、どちらも入れていません。
- design/ の tokens.md の字の大きさの食い違い（reviewer の提案6）は designer の持ち物で、手を付けていません。
- 自分で書いた契約と ADR の追記なので、自分では合格にしていません。次の3点は、指揮役が差分で確かめるときに見てください。
  - 横書きのとき9項目を書かないことを、スキーマでは禁じず、文の決まりだけにした点。スキーマで禁じると必須を減らす向きを超えてしまうためです。ただし 0 や空の配列は minimum と minItems で弾かれます。
  - `state` と `texts` の表を足した点。名前・型・enum は変えていませんが、決まりとしては新しく明文化したものです。
  - 提案3で、reviewer の文案ではなく別の文にした点。
- ビルドはしていません（ios/ は書かない役のため）。

## 記録（指揮役が保存するときに書き足す）
- 日付：2026-11-02。BASE 392c224。差分は contracts/ と docs/adr/ の4ファイルだけ。
- 指揮役の確かめ（裁定 22 と同じく、3回目の判定は呼ばない）
  - `make check-contracts` → `ALL PASSED: 8 schemas, 29 examples validated with 0 errors.`
  - `grep -cE '^### H[0-9]+' contracts/test-hooks.md` → 31。
  - スキーマの差分：`composition.required` を3つに減らし、9項目を `if orientation == vertical then required` に移しただけ。名前・型・enum は変わっていない。
  - 1-1 の門の置き場所は H33 (a)(b) と同じ範囲になった。
- 指揮役の裁定
  - **未解決の `store.*` の再読み込みの出どころ**：(B) を採る。購入と復元は写しを変えないので、ウィジェットの再読み込みを求めない。返金で見た目を標準に戻すときは、写しを変える保存として `settings.save` で数える。`book.switch`・`book.finish` は `book.status`、`settings.appearance` は `settings.save` にする（契約の enum は変えない）。理由：enum を足すと契約の直しと判定がもう1回要るため。また、写しを変えない再読み込みはウィジェットの再読み込みの予算を無駄に使うため。
  - 横書きで9項目を書かないことを、スキーマでは禁じず文の決まりだけにした点：受け入れる（0や空の配列は minimum と minItems で弾かれる）。
  - `state` と `texts` の表を足した点、提案3の文を reviewer の案から変えた点：受け入れる（反例の検算がある）。
