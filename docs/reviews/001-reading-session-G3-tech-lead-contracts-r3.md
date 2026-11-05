# 001-reading-session G3 契約の直し（H22 の組み方、H33 の門の置き場所）tech-lead r3

## 変更したファイル
- /Users/takumamatsuura/reading-app/contracts/test-hooks.md
- /Users/takumamatsuura/reading-app/contracts/hooks/h22-widget.schema.json
- /Users/takumamatsuura/reading-app/docs/adr/0003-vertical-composition.md
- /Users/takumamatsuura/reading-app/docs/adr/0005-test-hooks.md

BASE は f76ac12 で確かめてから始めました（`git rev-parse --short HEAD` → `f76ac12`）。ios/、design/、docs/prd/ は触っていません。コミットもしていません。

### H33（要修正2、裁定2）
- **門の置き場所を広げた**：H33 の「本番」をこう書き直しました。
  - 門の型は `ReadingStore` に1つだけ置く。
  - 門を通す所は (a) 読み込みの関数の中、または (b) 読み込んだ結果を画面に渡す所（View の側。`GatedLoadView`、ボタンの action、`runCatalogLookup` など）。
  - `store.load` は、起動時に同期で読み終えたあと (b) で止める。`catalog.lookup` と `storekit.purchase` / `storekit.restore` は、門を通ってから本物の処理を呼ぶ。
- **守る要件は変えていない**：既定は素通り、`#if` の外、名前は `UITestHook` で始めない、設定はつなぎ口だけ（`#if UITEST_HOOKS` の中）。観察できる振る舞い（`hold.*` の相、`hook.store` が空、0.3秒の帯、放したあとの H7 のエラー）も同じです。
- **止めないときの決まりを足した**：時間の待ちと読み込み中の形を足さず、(b) の画面は最初の描画から中身を出す。
  - ボタンを `Task` で包むのは許します。ただし2度押しを弾くことを条件にしました。指揮役の裁定4の「store.buy の2度押し」と同じ件です。
  - 今の購入・復元のボタンはまだ2度押しを弾いていません。
- **関連箇所**：
  - 1-1 の例外の文に「H33 は、読み込んだ結果を画面に渡す所でもよい」を足しました。
  - `store.load` の行の「止める所」を直し、5章に1行足しました。
  - ADR 0005 に「追記（2026-11-02 その2）」を足しました。比べた案は「契約を広げる」と「読み込みの関数を async にする」の2つで、門を通す所は今4か所です。

### H22（要修正1、裁定1）
- **組み方を契約に書いた**：「H22 の組み方」の節を新しく作りました。
  - `renders[]` の1つずつについて、`request` の family と幅×高さから、拡張と見本が描くのと同じ手順で字の大きさ s、1列の字数 L、列を決め直します。
  - 既定（4列×8字）で組んだ結果は出しません。
- **計算の置き場所**：`ReadingCore` の純粋な関数1つにします（SwiftUI を使わない nonisolated）。
  - W-1・W-2 の View と `SnapshotStore` の両方がこれを呼びます。
  - 定数（W-1：余白0、帯43、間4、s 17→13。W-2：余白16、場所の行20、s 20→13。列の間 0.25s）もそこに1か所だけ置きます。
- **手順**：G1 の ADR 0003（6c46e54 版）にあり、0d24bcd の書き直しで落ちていた手順を戻しました。
  - 今の `ReadingVerticalFit.fit` との違いは1点です。入るかどうかを、禁則で字を送ったあとの列の数で見て、列の数に上限を付けません。
  - 今の実装は送る前の列の数で判定してから上限を付けるので、送りの多い一行では最後の列で字が落ちる可能性があります。
- **スキーマに項目は足していない**：
  - 項目は既にスキーマにあります（`fontSize`、`L` は1列の字数、`columnCount`、`frame{W,H,i,B,g,R}`、`referenceL`、`feedCount`、`slack`、`cells[].x/y`）。足したのは各項目の意味の説明（式）だけです。
  - 手順では列の上限を使わないので `maxColumns` は要りません。実装の `rowsPerColumn` は `L` に当たります。
  - 例の2つは手順の値に直しました（172×76 の14字：17pt、L＝4、4列、余り 44.25 / 8、`x`＝155 など）。
- **検算**：同じ手順を Python で書いて計算しました（/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/fit.py）。
  - AC-27 の14字：W-1 の 172×76 と 153×68 はどちらも 17pt・L＝4・4列。W-2 は 170 で 20pt・L＝5・3列、148 で 20pt・L＝4・4列。
  - `referenceL` は4つの枠すべてで5。かな25字の値は 6c46e54 版の表と同じでした。
- **ADR 0003**：「追記（2026-11-02）」を足しました。「決定1」の固定の大きさ（12pt・15pt）は、この手順で置き換えると書いています。比べた案は3つです。

## 実行したコマンドと結果
- `git rev-parse --short HEAD` → `f76ac12`
- `make check-contracts` → 終了コード 0、`ALL PASSED: 8 schemas, 28 examples validated with 0 errors.`
- `python3 -I fit.py`（スクラッチパッドにある手順の検算）→ 上の表の値。test-hooks.md の「H22 の組み方」の表に載せました。
- `composition` だけをスキーマで検査する1行（例1で試して `composition OK: 1 renders`、終了コード 0）：
  `~/.cache/reading-app/contracts-schema-venv/bin/python -I -c 'import json,sys; from jsonschema import Draft202012Validator as V; s=json.load(open(sys.argv[1],encoding="utf-8")); c=s["$defs"]["render"]["properties"]["composition"]; d=json.load(open(sys.argv[2],encoding="utf-8")); rs=[r for r in d["renders"] if "composition" in r]; [V(c).validate(r["composition"]) for r in rs]; print(f"composition OK: {len(rs)} renders")' contracts/hooks/h22-widget.schema.json <hook.widget を保存した JSON>`
- `git grep` で門を通す所と、テストが `hook.widget` から読む項目を確かめました。テストが読むのは `displayedLine`、`texts`、`reloadRequests` だけで、`cells`、`L`、`column/row` は読んでいません。
- H の見出しは31個のままで、番号、必須の項目、enum は変えていません。

## ios-engineer に頼むこと（H22 の直し方）
1. **関数を作る**：`ReadingCore`（例：`VerticalLineLayout.swift`）に、W-1・W-2 の組み方を1つの nonisolated の関数として作る。
   - 入力：ファミリー、幅、高さ、写し、読み上げの文。
   - 出力：`frame`、`fontSize`、`L`、`referenceL`、`columnCount`、`feedCount`、`kinsokuRelaxed`、`slack`、`cells`（x と y 付き）、`displayedLine`、`shortened`、`orientation`。
   - 記号の値は契約の表のとおり Double の定数で、この関数の側にだけ置く。
2. **手順は契約どおりにする**（test-hooks.md「H22 の組み方」の手順1〜5）。
   - 列に分けるときは上限なしで送り、送ったあとの C で入るかを見る。入らなければ s を1下げる。
   - 下限でも入らなければ、送らずに組んで `kinsokuRelaxed=true` にする。
   - `referenceL` は同じ枠で「あ」25字を組んだときの L。
   - 今の `layoutVerticalCells` の上限付きの送りは、この関数からは使わない。
3. **View を直す**：`ReadingWidgetSurfaceViews.swift` の `composeFitted` と `ReadingVerticalFit` を消し、W-1・W-2 の View は手順1の関数の結果をそのまま描く（格子の行数は `L`、字の大きさは `fontSize`）。
   - `ReadingWidgetMetrics` の余白、帯、間、列の間は、ReadingCore の定数を SwiftUI の型に直すだけにする。
4. **読み出しを直す**：`SnapshotStore.fullHookPayload` で、全体に1つの `comp` を使い回すのをやめる。`renders[]` ごとに `spec.family` と `spec.size`（幅×高さ）から手順1の関数を呼び、その結果を `composition` にする。
   - 大きさが読めないときは今どおり `hook.error`（`H22:<値>`）。
5. **`composition` をスキーマの形で書き出す**：`$defs/render/properties/composition` の形にする。
   - `rowsPerColumn` は `L` にし、`accessibilityLabel` は `composition` から外す。
   - `state` が `normal`（縦書き）のときだけ出す。
   - 横書き（AC-30）は今のままでよい。AC-30 のテストは JSON に `horizontal` が含まれるかを見るので、`orientation: "horizontal"` は消さない。
6. **単体テストを足す**：`ReadingKit` に、契約の表の9行（s、L、C、送り、`referenceL`、余り）が一致するテストを足す。送りの多い一行（例：「あ、」を12回くり返して「あ」を足した25字）で、字が落ちない（`cells` の数＝字の数）ことも確かめる。
7. **確かめて出力を残す**：
   - `make ios-build`（警告0）と `make ios-test` を動かす。
   - `-uitest-widget accessoryRectangular:153x68,accessoryRectangular:172x76,systemSmall:148x148,systemSmall:170x170` と AC-27 の投入で起動し、`hook.widget` の値を保存して、上の1行で `composition` を検査する。
   - 同じ枠の `-uitest-widget-show` の画像と `fontSize`・`columnCount` が合うことを見る。

## verifier への影響
- `cells[].column/row` は意味が変わります。今までは枠を使わない既定（8字ごとの列）でしたが、これからは本物の W-1・W-2 の列になります。禁則の位置も本物のものになり、`L` は一行の字の数で変わります（14字なら4、25字なら5）。今のテストはこれらを読んでいないので、そのままでは落ちません。
- **AC-28**：(4)〜(6) の「L+1 字目」の L は `referenceL`（W-1 の両方の枠で5）です。
  - 短い一行だと実際の L が4になり、禁則の字が列の先頭に来ないので、確かめにならない可能性があります。一行は25字で作る（このとき L＝`referenceL`）か、各 render の `L`＝`referenceL` を先に確かめてください。
  - 今の AC-28 のテストは縦書き用の字があるかしか見ていません。`cells` で「`column`≥2 かつ `row`＝1 の字が禁則の字でない」ことと、字がそろうことを確かめる形に強めることを勧めます。
- **AC-27、AC-35**：「欠け0字」を `cells` の字を並べて `displayedLine` と比べる形にし、同じ枠の `showcase.contentOverflow=false` と組で見ることを勧めます。今は文字列が含まれるかしか見ていません。
- **AC-29、AC-30、AC-99**：縮め方、横書き、読み上げは変わらないので、影響はありません。
- **H33**：振る舞いは変わらないので、撮り方（`hold.<対象>=shown` を待つ）はそのままです。

## 未解決
- **重大（指揮役の判断が要る）**：`hook.widget` の読み出しは、今 `composition` 以外も h22-widget.schema.json に合っていません。コードを読んで確かめました（`SnapshotStore.swift` の `WidgetRenderEntry`、`FullWidgetHookPayload`）。
  - トップに `title`、`line`、`snapshot`、`composition` などの余計なキーがある。
  - render のキーが違う：`entryURL`（スキーマは `url`）、`state: "hasLine"`（enum にない値）、`request.size` が文字列（スキーマは width / height の数）、`accessibilityLabel`（スキーマは `accessibility{identifier,label,groupCount}`）。`seq`、`producedAt`、`snapshotSource`、`timeline.entries/policy` がない。`texts` に `title`、`empty` などの余計なキーがある。
  - G2 と G3 の判定では、スキーマ全体との照合はしていませんでした。テストは文字列が含まれるかで読むので、今は落ちません。
  - 推奨：同じ直しで ios-engineer に読み出し全体をスキーマに合わせてもらい、`make check-contracts` と同じ venv で全体を検査する。今回の手順5は `composition` に限っています。
- 横書き（AC-30）の `composition` の値（`fontSize`、`cells` など、必須の項目）は決めていません。上の重大の件で全体を合わせるなら、tech-lead が別に決めます。
- design/ の tokens.md の `type.book.line.widget.rectangular` は「17pt（172×76、1列5字×5列）」と書いていますが、手順では25字は 15pt・L＝5、14字は 17pt・L＝4 です。screens.md の「17pt から 1pt ずつ下げる」とは合っています。designer に直すかどうか確かめてもらう項目です。
- ビルドはしていません（ios/ は書かない役のため）。手順を Swift で書いたときの値は、ios-engineer の単体テストで確かめます。
- 自分で書いた契約と ADR の追記なので、reviewer に反論を出してもらってください。特に次の3点です。
  - 入るかの判定を「送ったあと」に変えた点。
  - H33 で門を View の側に置くことを認めた点。
  - スキーマに項目を足さないと決めた点。

## 記録（指揮役が保存するときに書き足す）
- 日付：2026-11-02。BASE f76ac12。差分は contracts/ と docs/adr/ の4ファイルだけ（指揮役が `git status` で確かめた）。
- 指揮役の確かめ：`make check-contracts` → `ALL PASSED: 8 schemas, 28 examples validated with 0 errors.`
- 次：組み方の判定を「送ったあと」に変えた点、H33 の View の側を認めた点、スキーマに項目を足さない点、読み出し全体がスキーマに合っていない件（未解決の「重大」）と横書きの `composition` を、reviewer（設計）に判定してもらう。
