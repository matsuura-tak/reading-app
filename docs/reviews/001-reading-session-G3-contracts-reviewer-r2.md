# 001-reading-session G3 契約 r3 の判定 reviewer（設計）

PASS

（観点：設計。対象：f76ac12..0c2714a の contracts/ と docs/adr/。HEAD＝0c2714a を `git rev-parse HEAD` で確認。重大 0、要修正 2、提案 7。要修正は ios-engineer が H22 の読み出しに着手する前に契約の文を直して渡すことを勧める。判定に数えない「既存」を提案に分けた）

## 1〜5 の結論
1. **H22 の組み方（送ったあとの列の数で見る、列の上限なし）**：正しい。design/001-reading-session/screens.md:17（「追い出しで列が1つ増えても入る」「25字は 172×76 で 15pt、153×68 で 13pt」）と G1 の ADR 0003（`git show 6c46e54:docs/adr/0003-vertical-composition.md` の手順 6「C×s＋(C−1)×0.25s ≤ A_w なら入る。C は 5 のあとの列の数」）がもともと「送ったあと」で、G3 r2 の `ReadingVerticalFit.fit`（ReadingWidgetSurfaceViews.swift:108-130、⌈n÷L⌉で判定して `maxColumns` を付ける）の方が逸脱していた。AC-27・AC-28・AC-35 の「欠け0字」「どの列の先頭にも禁則の字がない」は、上限なし＋n 字すべてを列に入れる手順で満たせる。表の9行と例の座標（x 155／133.75、y 51、page y 60、余り 44.25／8）は、作り手の fit.py を使わず自分で書いた検算で全行一致した（下の出力）。
2. **H33 の門を View の側に置くことを認めた点**：1-1 の例外の要件（型は `ReadingStore` に1つ・`#if` なし・既定は素通り・設定は `UITestHooks/` だけ・名前は `UITestHook` で始めない・パッケージに define なし）と観察できる振る舞い（`hold.<対象>` の相、`hook.store` 空、本物の時計の 0.3秒、放したあとの H7 の失敗）は、契約 H33「本番」（test-hooks.md:661-671）と ADR 0005 追記その2の「変えないこと」に保たれている。門を通す所は実際に `ContentView.swift:53`、`BookRegistrationViews.swift:764,778`、`FinishNightView.swift:314`、`LoadingPlaceholderViews.swift:24,48`、`SettingsAndStoreViews.swift:337,658,670`、`ShelfAndBookDetailViews.swift:39,295` で、`ReadingStore` の中は型の宣言だけ（自分の grep）。2度押しの条件は「押したらすぐ押せなくするか、進行中の印で弾く」が同期（`Task` の外）で行われれば、`Task` が走る前の窓と止めている間の窓（2回目の `pass` は `armed.remove` が nil で素通り。LoadHoldGate.swift:48）の両方を塞ぐので足りる。ただし 1-1 の括弧書きが H33 (b) より狭い（要修正2）。
3. **h22 スキーマに項目を足さない点**：足さなくてよい。構造（required／enum／const／minItems／型／allOf）は BASE と HEAD で差分なし（自分のスクリプトで比較、説明と例だけの変更）。手順の結果（s、L、C、送りの回数、kinsokuRelaxed、横縦の余り、升目の x/y、referenceL）はすべて既存の項目に式付きで載り、AC-28 の L は `L` と `referenceL` の2つで表せる。`maxColumns` は手順に出てこないので不要。実装の `rowsPerColumn`／`accessibilityLabel` は出力の名前の問題で、スキーマの変更ではない。
4. **読み出し全体がスキーマに合っていない件**
   - (a) G3 で合わせる必要があるか：**合わせるべき（ただし「既存」で、この差分の判定には数えない）**。契約 H22 は「出力：要素 `hook.widget` の値。contracts/hooks/h22-widget.schema.json」（test-hooks.md:395）とスキーマを正としており、`state: "hasLine"`（SnapshotStore.swift:325、blame bc15b693 2026-10-26）、`entryURL`（:44、同）、トップの `title`/`line`/`snapshot`（:86-88、blame 64d24cea 2026-10-27）はどれも BASE より前からある。今回ios-engineer が `composition` を「`state` が `normal` のときだけ出す」形に直すには `state` の値をまず enum に合わせる必要があり、`WidgetRenderEntry` は1つの struct なので `url`・`request.width/height`・`accessibility{…}`・`seq`・`producedAt`・`snapshotSource`・`timeline.entries/policy` も同じ直しで合わせるのが合理的。verifier が同じ venv で `hook.widget` の全体を検査する行を test-hooks.md の 7 に足すことも勧める（いまの 7 は examples の検査だけ）。
   - (b) 今の契約のまま実装できるか：**できない（要修正1）**。横書き（AC-30）の扱いが決まっておらず、しかもスキーマが横書きを満たせない。契約 H22:397 は「一行があれば `normal`」、スキーマ :495-506 は `normal` なら `composition` 必須、`composition` は `fontSize`（exclusiveMinimum 0）、`L`・`columnCount`（minimum 1）、`cells`（minItems 1）などを必須にしている。「It was raining.」は縦の升目を持たないので、契約 :437 の「横書きのときの組みの値は、この決まりの範囲の外（いまのまま）」＝今の実装（`columnCount 0`、`cells []`。VerticalLineLayout.swift:355-365）はスキーマ違反になる。作り手の報告の「`state` が `normal`（縦書き）のときだけ出す」は契約の `state` の定義（一行があれば `normal`。横書きを含む）とも食い違う。
5. **tokens.md の「17pt（172×76、1列5字×5列）」との食い違い**：**designer に直してもらう必要がある（契約では吸収できない）**。tokens.md:68 の「17pt…1列5字×5列＝25字」「15pt（153×68…）」と :69 の「1列6字×5列」は、同じ designer の screens.md:17（25字は 15pt／13pt）、:28（1列5字＝⌊118÷20⌋）、:36（20pt／19pt）および G1 の ADR 0003 の「25字のときの結果」と矛盾しており、design/ の中で食い違っている。契約は screens.md と G1 の ADR に合っており、しかも記号の値の出どころとして tokens.md を引いている（test-hooks.md:409）ので、tokens.md 側を直すのが筋。この差分の指摘ではない（既存、提案6）。

## 指摘

### 重大
なし。差分の中にエージェント向けの指示のような文もなし。

### 要修正
1. **contracts/test-hooks.md:436-437、contracts/hooks/h22-widget.schema.json:282-296（composition の required）・:403-405（cells minItems 1）・:493-513（state normal → composition 必須）** — 横書き（AC-30）の `composition` がスキーマを満たせない（上の 4(b)）。根拠：PRD AC-30「列に分けず、横書きの1行で『It was raining.』が出る…H22 で読む」、契約 H22:397「一行があれば `normal`」、スキーマ上記の行、契約 :437「横書き…範囲の外（いまのまま）」。直す方向（どれか1つを tech-lead が決める）：(i) `composition` の縦書き専用の項目（`frame`、`fontSize`、`L`、`referenceL`、`columnCount`、`feedCount`、`kinsokuRelaxed`、`slack`、`cells`）を `orientation` が `vertical` のときだけ必須にする（if/then。必須を減らす方向なので「版」の決まりに反しない）＋横書きの例を1つ足す。(ii) 横書きの値を決める（例：`fontSize` は横書きの字の大きさ、`L`＝字数、`columnCount`＝1、`cells` は row に並べる）。(iii) 横書き用の `state` を足す（enum の追加は許される）。(i) がいちばん小さい。
2. **contracts/test-hooks.md:20（1-1 の括弧「H33 は、読み込んだ結果を画面に渡す所でもよい」）と :665（H33 (b)「読み込みの前に門を通す対象（`catalog.lookup`、`storekit.purchase`…）は、門を通ってから本物の読み込みを呼ぶ」）** — 1-1 は「結果を画面に渡す所」しか認めていないが、H33 (b) は View から「読み込みの前」に門を通すこと（`runCatalogLookup`、購入・復元のボタン）も認めている。文書の更新漏れで、今回の直しの目的（契約の文と実装のずれをなくす）が 1-1 側で再発する。直す方向：1-1 を「読み込みの関数の中、または（H33 は）View の側で読み込みを呼ぶ所か読み込んだ結果を画面に渡す所」にそろえる。

### 提案
3. **contracts/test-hooks.md:428** — 「25字以下では、W-1 と W-2 のどの枠でも、ここまで来ない」は正確でない。「あ」＋「ー」×24 の25字は、手順3の「前の列が1字になっても満たせないときは送らない」で列が1字ずつになり C＝25 で入らず、下限で `kinsokuRelaxed` になる（自分の検算：W-1 172×76 → s 13、L 5、C 5、relaxed True）。手順5の後退で必ず入るので実害はないが、「送りで列が1字になる並びを除く」と書く。あわせて、手順3で送りを止めたときは列の先頭に禁則の字が残るのに `kinsokuRelaxed` が偽のままで、`feedCount` も「そして」＋「…」×6 で11になる（検算）。その場合の `feedCount`・`kinsokuRelaxed` の意味を1行決めておくと verifier が迷わない。
4. **contracts/test-hooks.md:668** — 2度押しの条件は「印を同期で（`Task` の外で）立てる」と明記すると曖昧さがなくなる。止めている間の2回目（`pass` が素通りして本物の処理が走る）も同じ印で塞げること、G3 コード reviewer r1 の提案（`catalog.lookup` を止めている間の2つ目のバーコード）はボタンでないのでこの条件の外に残ることを書く。
5. **docs/adr/0003-vertical-composition.md:30-31（決定 1）** — 追記は字の大きさ（12pt・15pt）だけを置き換えたが、同じ行の「左端に縦1列の書名（10pt、最大6字）」「W-2 は下部に横書きの書名＋ページ」も design/ の W-1・W-2（帯に場所だけ、書名なし）と違う（既存。0d24bcd の書き直し由来）。追記で「決定 1 の W-1・W-2 の配置の記述も design/ screens.md に置き換える」と1行足す。
6. **既存／design/001-reading-session/tokens.md:68-69** — 上の 5。designer に直してもらう（W-1：25字は 15pt／13pt、L＝5、14字は 17pt・L＝4。W-2：L＝5、20pt／19pt）。
7. **contracts/hooks/h22-widget.schema.json:694-760、877-940（例）** — `cells` が14字のうち3つだけで、本文の「出した字ごとに1つ」と見た目が違う。例を「抜粋」と書くか全升目にする。横書きの例もない（要修正1と一緒に足す）。
8. **docs/reviews/001-reading-session-G3-tech-lead-contracts-r3.md の「ios-engineer に頼むこと」5** — 「`state` が `normal`（縦書き）のときだけ出す」は契約の `state` の定義と食い違う（上の 4(b)）。指揮役がこの行をそのまま ios-engineer に渡さない。
9. **既存／ios/ReadingKit/Sources/ReadingStore/SnapshotStore.swift:38-123、297-391** — 読み出し全体のスキーマ違反（トップの余計なキー、`entryURL`、`state: "hasLine"`、`request.size` が文字列、`accessibility` の形、`seq`・`producedAt`・`snapshotSource`・`timeline.entries/policy` なし、`texts` の `title`/`line`/`page`/`empty`）。blame はすべて BASE より前（bc15b693、64d24cea）。4(a) のとおり、同じ直しで合わせることを勧める。

## 証拠
- 対象：f76ac12..0c2714a（HEAD＝0c2714a）、観点：設計。`git diff --name-only f76ac12..0c2714a`：contracts/hooks/h22-widget.schema.json ✓（全文、BASE 版との構造比較も）、contracts/test-hooks.md ✓（差分全体＋1-1、H22、H33、5、6、7 章）、docs/adr/0003-vertical-composition.md ✓（全文＋6c46e54 版の手順・記号・25字の結果）、docs/adr/0005-test-hooks.md ✓（128-197 行＋差分）、docs/progress.md ✓（差分）、docs/reviews/001-reading-session-G3-tech-lead-contracts-r3.md ✓（全文。読んだのは観点の確認を終えたあと）。差分の外で読んだもの：docs/reviews/001-reading-session-G3-reviewer-code-r1.md（全文）、同 G3-contracts-reviewer-r1.md（冒頭と見出し。前回の基準の確認）、ios/ReadingApp/Shared/ReadingWidgetSurfaceViews.swift（全文）、ios/ReadingKit/Sources/ReadingStore/SnapshotStore.swift（全文）、ios/ReadingKit/Sources/ReadingCore/VerticalLineLayout.swift（全文）、ReadingCore/ContractModels.swift:973-1003、ReadingStore/LoadHoldGate.swift（全文）、ReadingApp/Views/LoadingPlaceholderViews.swift:1-53、SettingsAndStoreViews.swift の門の行、design/001-reading-session.md の AC 表と W-1・W-2 の行、design/001-reading-session/screens.md:1-60、tokens.md:60-104、docs/prd/001-reading-session.md:527-585（AC-27〜AC-36）、ios/AcceptanceTests/WidgetAndActivityAcceptanceTests.swift:1-200、docs/org/gates.md の契約の行。

### AC 対応表（この差分が触る AC と、使うつなぎ口・データ）
| AC | つなぎ口 | この差分で決まったデータ | 満たせるか |
|---|---|---|---|
| AC-27（W-1 153×68・172×76 で14字が欠けず p.61） | H22 `renders[].composition`（request の枠で組む）＋ `showcase` | s 17、L 4、C 4、`cells` 14個、`texts["widget.page"]` | 満たせる（検算一致） |
| AC-28（字形・回転・禁則、L） | H22 `cells[].display/rotation/column/row`、`L`、`referenceL` | 送りあと判定・上限なし、`referenceL`＝かな25字の L（両枠で5） | 満たせる。(4)〜(6) は verifier が25字で作るか `L==referenceL` を先に確かめる（ADR 0003 追記に明記あり） |
| AC-29（縮め方） | H22 `displayedLine`、`shortened` | 変えない | 満たせる |
| AC-30（横書き） | H22 `composition.orientation: horizontal` | **未決**（要修正1） | 契約どおりに出すとスキーマ違反 |
| AC-31、AC-32、AC-34（一行なし／本なし／隠す） | H22 `state`、`texts` | `composition` は `normal` のときだけ（変更なし） | 満たせる |
| AC-35（W-2 148・170） | H22 同上 | 170：20pt・L5・C3、148：20pt・L4・C4 | 満たせる（検算一致） |
| AC-99（読み上げ） | H22 `accessibility.label` | 変えない | 影響なし |
| H33 | AC なし（G3 の証拠） | 門を通す所 (a)/(b)、既定素通り、2度押し | 保たれている |

### つなぎ口の表（エンドポイントの代わり。誰が呼べるか／信頼の境界）
| 口 | 呼べるもの | 境界と検証 | Release |
|---|---|---|---|
| H22 `hook.widget`（読み出し） | XCUITest が `accessibilityValue` を読む。Debug／Perf の `UITestHooks/` だけ | 端末内の写しだけ。通信なし、他人のデータなし | 入らない（1-1） |
| H22 の組みの関数（`ReadingCore`） | View（アプリ・拡張）と `SnapshotStore` | 純粋関数、入力は枠と一行 | 入る（製品の組版そのもの） |
| H33 `LoadHoldGate` | `pass`/`willHold`/`markShown` は製品の View、`arm`/`release` は `UITestHooks/` だけ | 既定は `armed` 空で即 return（LoadHoldGate.swift:48） | 関数は残るが入口なし。名前は `UITestHook` で始まらない |

### 元に戻しにくい判断への、いちばん強い反論と ADR の答え
- **組みを枠ごとに決め直し、送ったあとの C で判定する**：反論「字の大きさが一行の字数で変わるので、PRD AC-28 が『枠の性質』として扱う L が一定でなくなり、短い一行では禁則の確かめが空振りする」。ADR 0003 追記の「招く悪い結果」が同じ点を認め、`referenceL` と「verifier は25字で作る」で答えている。戻し方：test-hooks.md の表・ReadingCore の単体テスト・tokens.md の3か所と書いてある（:121）。十分。
- **H33 の門を製品の View に置く**：反論「Release の製品コードに、テストのためだけの `await`・`.task`・`Task` の道が残る」。ADR 0005 追記その2は「既定は素通り、待ちと読み込み中の形を足さない、最初の描画から中身」と `nm` で答え、見直す条件（8か所を超えたら actor にまとめて (a) に戻す）を持つ。`GatedLoadView.init` の `isLoaded = !gate.willHold(point)` と `.task` の `guard !isLoaded` を読んで、止めないときは待ちがないことを確認。十分。
- **スキーマに項目を足さない**：反論「実装の `rowsPerColumn`／`accessibilityLabel` と名前が違い、直しの範囲が読み出し全体に広がる」。これは 4(a) のとおり出力の形の問題で、スキーマの「版」の決まり（名前・型・意味を変えない）を守るには実装側を合わせるしかない。妥当。

### 実行したコマンドと出力
- `git rev-parse HEAD` → `0c2714af23901f25bcdfd6a337851b3da4184e37`。`git diff --stat f76ac12..0c2714a` → 6 files、+308/−47。
- `make check-contracts` → `ALL PASSED: 8 schemas, 28 examples validated with 0 errors.`、exit 0。
- 自分の検算（/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/rv/refit.py、手順1〜5を独立に実装、`python3 -I`）：W1 172×76 14字 {s 17, L 4, C 4, feed 0, sh 44.25, sv 8, refL 5}／W1 153×68 14字 {17, 4, 4, 0, 25.25, 0, 5}／W1 172×76 かな25 {15, 5, 5, 0, 35.0, 5}／W1 153×68 かな25 {13, 5, 5, 0, 28.0, 5}／W1 172×76 「歩行祭は、…」15字 {17, 4, 4, feed 1, 44.25, 5}／W2 170 14字 {20, 5, 3, 0, 68.0, 5}／W2 148 14字 {20, 4, 4, 0, 21.0, 5}／W2 170 かな25 {20, 5, 5, 0, 18.0, 5}／W2 148 かな25 {19, 5, 5, 0, 2.0, 5}。表の9行すべて一致。例の座標：x col1 155.0、x col2 133.75、y row4 51、page y 60（例と一致）。境界：「あ、」×12＋あ → W1 172 {15, L5, C6, feed 5, sh 16.25}、W1 153 {13, 5, 6, 5, 11.75}（6c46e54 版の「送りで列が1つ増えたとき」と一致）。「あ」＋「ー」×24 → W1 172 {13, 5, 5, relaxed True}（提案3の根拠）。
- スキーマ構造の比較（required/enum/const/minItems/minimum/type/pattern/allOf 等を BASE と HEAD で抽出して diff）→ 差分なし（164 行同一）。
- `grep -cE '^### H[0-9]+'` → BASE 31、HEAD 31。
- `git grep -n '\.pass(\|willHold(\|GatedLoadView(' -- ios ':!ios/AcceptanceTests'` → 上の 2 の11か所（LoadHoldGate.swift の宣言を除く）。ReadingStore の中に呼び出しなし。
- `git blame`：h22 schema の cells minItems／orientation enum／allOf（state normal）はすべて e8fa4eb0（2026-10-20、G1）。SnapshotStore.swift:325（`hasLine`）・:44（`entryURL`）は bc15b693（2026-10-26）、:86-88（トップの `title`/`line`）は 64d24cea（2026-10-27）。いずれも BASE より前 → 既存。
- `grep -rn 'hook\.widget' ios/AcceptanceTests/` → 読む項目は `renders[].texts["widget.line"]`／`composition.displayedLine`（AC-29）、文字列 contains（AC-27、28、30 など）。`cells`、`L`、`column/row`、`state` を読むテストなし（作り手の報告と件数一致）。
- 開いた規則：PRD AC-27〜AC-36（docs/prd/001-reading-session.md:529-582）、design/ の AC 表（001-reading-session.md:190-198）、screens.md:8-38、tokens.md:68-69・79、contracts/test-hooks.md:10-34・386-455・632-671・712-725、h22-widget.schema.json 全文、ADR 0003 全文と 6c46e54 版 46-101 行、ADR 0005:131-197、docs/org/gates.md:47-61。外部の URL：この差分は端末内の契約と ADR だけで、審査・OWASP・Apple の要件に関わる項目（通信、権限、課金、収集）を変えていないため開いていない。

### 未検証
- `make ios-build`／`make ios-test` は動かしていない（この差分は contracts/ と docs/adr/ だけで ios/ を変えていないため。契約を Swift にしたときの値は ios-engineer の単体テストで確かめる）。
- 本物のウィジェットの列数・字の大きさが H22 の `composition` と一致するかは、実機（G4-1、G4-3）でしか見られない。

## 記録（指揮役が保存するときに書き足す）
- 種類：判定（観点：設計）。対象 f76ac12..0c2714a。日付：2026-11-02。結果：PASS（重大0、要修正2、提案7）。
- 指揮役の裁定
  1. 要修正1（横書きの `composition` がスキーマを満たせない）：reviewer の (i) で直す。縦書きだけの項目を `orientation` が `vertical` のときだけ必須にし、横書きの例を1つ足す（必須を減らす向きで、版の決まりに反しない）。tech-lead。
  2. 要修正2（1-1 の括弧が H33 (b) より狭い）：1-1 を H33 (b) にそろえる。tech-lead。
  3. 提案3・4・5・7：同じ直しで tech-lead が直す（手順3で送りを止めたときの `feedCount`・`kinsokuRelaxed` の意味、2度押しの印を同期で立てる、ADR 0003 決定1の配置の記述、例の `cells` を「抜粋」と書く）。
  4. 4(a)・提案9（読み出し全体がスキーマに合っていない。既存）：G3 で合わせる。ios-engineer の5体目が H22 の直しと一緒に行い、verifier が同じ venv で `hook.widget` の全体を検査する。tech-lead は test-hooks.md の 7 に全体を検査する行を足す。
  5. 提案6（tokens.md の字の大きさの食い違い。既存）：designer に直してもらう。design-reviewer r2 の前に行う。
  6. 提案8：tech-lead r3 の「ios-engineer に頼むこと」5の「`state` が `normal`（縦書き）のときだけ」は、そのまま ios-engineer に渡さない。直した契約から頼む。
  7. 直しのあとは、3回目の判定を呼ばず、指揮役が差分で確かめる（裁定 22 と同じ）。
