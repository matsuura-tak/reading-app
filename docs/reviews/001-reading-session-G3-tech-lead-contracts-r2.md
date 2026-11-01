（指揮役の注）G3 verifier r2 の指摘のうち、契約と Makefile の直し（tech-lead）。作り手の報告で、判定ではない。

## 変更したファイル
BASE は fc844a7 で、始める前に HEAD が同じことを確かめました。commit はしていません。

- /Users/takumamatsuura/reading-app/Makefile
  - venv の既定の置き場所を `/tmp` からリポジトリの外の `~/.cache/reading-app/contracts-schema-venv` に移しました（変数 `SCHEMA_VENV` で変えられます）。
  - `contracts-venv` ターゲットを足しました。venv を作り、固定した版を入れ、印のファイルを置きます。`check-contracts` は先にこれを呼ぶので、初めての環境でも `make check-contracts` 1つで動きます。ネットワークが要るのは初回だけです。
- /Users/takumamatsuura/reading-app/contracts/check-requirements.txt（新規）
  - jsonschema 4.25.1、referencing 0.36.2 と、それらが使うパッケージ（jsonschema-specifications 2025.9.1、rpds-py 0.27.1、attrs 26.1.0、typing_extensions 4.16.0）の版をすべて固定しました。
- /Users/takumamatsuura/reading-app/contracts/dependencies.md：検査の道具の行を、入れ方・置き場所・確かめた出力の3点とも新しい形に直しました。
- /Users/takumamatsuura/reading-app/contracts/test-hooks.md
  - H22 に「撮影用の見本」の節を足しました。何に合わせたか、その理由、大きさ、中身、背景、読み出し、テストでの確かめ方、失敗のときの返り方を書いています。
  - H33（読み込みを止める）を足しました。
  - H8 と H30 に、通信なしで復元を押したときの振る舞いを決めて書きました。
  - 1-4（通知）、1-5（readouts を消したときの例外）、2、4、5、6、7 を直し、8（画面と状態の組ごとの撮り方）を新しく足しました。
- /Users/takumamatsuura/reading-app/contracts/hooks/h22-widget.schema.json：省ける `showcase` と `$defs/showcase`（例2つ）を足しました。
- /Users/takumamatsuura/reading-app/contracts/hooks/h17-state.schema.json：パターン `hold.<対象>` と raw の例1つを足しました。
- /Users/takumamatsuura/reading-app/contracts/hooks/hook-config.schema.json：`widget.show.family` に `liveActivity`、`control`、`snippet` を足し、省ける `variant` を足しました。
- /Users/takumamatsuura/reading-app/docs/adr/0005-test-hooks.md：末尾に追記（2026-11-02）を足しました。案は4つ比べ、悪い結果、見直す条件、確かめたことまで書いています。
- /Users/takumamatsuura/reading-app/CLAUDE.md：check-contracts の手順と出力、つなぎ口の数（H1〜H33 の31個）を直しました。59行です。

どの変更も、大きな版1の中で足すことだけにしています。名前、型、意味を変えたり消したりはしていません。前の書き方 `accessoryRectangular:172x76` もそのまま使えます。

### 決めたこと（要点）
1. **H22 の見本**：識別子は契約どおり `hook.widget.canvas` に決め、実装をこちらに合わせます。
   - 理由1：AC-27（172×76 pt と 153×68 pt）と AC-35（170×170 pt と 148×148 pt）は「その大きさで欠けずに組めるか」を問うものです。枠そのものがその pt でないと、画像でも `frame` でも確かめられません。
   - 理由2：今の見本 `WidgetShowcaseHarnessView`（ios/ReadingApp/UITestHooks/UITestHookOverlayWindow.swift）は、拡張の View とは別に書き直した View です。字の大きさも組み方も違うので、「読み出しでは欠け0字なのに画像では2字欠ける」食い違いが起きました。
   - 理由3：`screen.*` は製品の画面の根に使っている名前なので、つなぎ口だけの画面には使いません。
   - 契約に書いたこと：
     - 拡張と同じ View の型を描く。
     - 枠は `<幅>×<高さ>` pt にし、はみ出した分は `.clipped()` で切る。
     - 根の要素は `hook.widget.showcase`。
     - readouts を消した起動でも見本は出す。
     - 指定は `<面>:<幅>x<高さ>[:<種類>]` の形。面は `accessoryRectangular`、`systemSmall`、`liveActivity`（高さの上限 160）、`control`、`snippet`。種類は `placeholder`、`waiting`、`reading`、`ended` など。
     - `w3:waiting` のような書き方は受けず、`hook.error` を返す。
     - `hook.widget.showcase` で `viewType`、枠の大きさ、`idealHeight`、`contentOverflow` を読み出す。
2. **H33**：`-uitest-hold-load <対象>` で読み込みを止め、`yomuma.uitest.load.release`（対象の番号、0 はすべて）で放します。
   - 対象は8つです：store.load、shelf.load、book.load、recommend.load、catalog.lookup、storekit.products、storekit.purchase、storekit.restore。
   - 進み具合は `hook.state` の `hold.<対象>=waiting|held|shown|released` で読めます。テストは `shown` を待ってから撮れるので、sleep は要りません。
   - テストの起動のときだけ効き、Release には入りません。AC の判定には使いません。
3. **H8 と H30**：通信なしのときは `restoreOutcome` より通信なしを優先し、`store.offline` を出します。購入の状態は変えません。
4. **撮れなかった組**：8章で、組ごとに次の4つのどれかに分けました。
   - つなぎ口を足した
   - 今あるつなぎ口で撮れる
   - 仕様上その状態は無い（W-3 の読み込み中、W-5 のエラーの小窓、保存の間の見た目など）
   - 製品の不具合（S-10 の offline と error、S-3c の61字、S-8b の空）
   - W-4 の Control の見た目と Dynamic Island はアプリの中では描けないので、G4 の実機で見ます。

## 実行したコマンドと結果
- `git rev-parse --short HEAD` → `fc844a7`
- venv のない状態から作って動かした（置き場所はスクラッチパッドの新しいフォルダ）：
  `make check-contracts SCHEMA_VENV=/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/fresh-venv` → 終了コード 0
  ```
  creating .../scratchpad/fresh-venv with /usr/bin/python3
  jsonschema 4.25.1 referencing 0.36.2
  ALL PASSED: 8 schemas, 28 examples validated with 0 errors.
  ```
- 既定の置き場所で `make check-contracts` → 終了コード 0（`creating /Users/takumamatsuura/.cache/reading-app/contracts-schema-venv`、同じ ALL PASSED）。続けてもう一度動かすと、venv を作り直さずに終了コード 0、`ALL PASSED: 8 schemas, 28 examples validated with 0 errors.` でした。
- 足したスキーマが誤りを弾くかも確かめました（venv の Python で直接）。必須項目の抜けた showcase、`surface: "w3"`、`widget.show.family: "w3"` はどれも弾かれ、正しい例は通りました。
- Apple の資料で確かめたこと：
  - `EnvironmentValues.widgetFamily` の宣言は `var widgetFamily: WidgetFamily { get }` で、読むだけです（https://developer.apple.com/documentation/swiftui/environmentvalues/widgetfamily ）。
  - Live Activity は高さが 160 pt を超えると切られることがあります（https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities ）。
  - `contentMarginsDisabled()` は、この Mac の iPhoneSimulator27.2.sdk の WidgetKit.swiftinterface 662 行にあります。
- ios/ のビルドはしていません（ios/ は書かない範囲です）。

## 未解決
- **`.venv/contracts-schema` が作業ツリーに残っています。** 途中で置き場所をリポジトリの中の `.venv/` にして一度 make を動かしたためです。.gitignore で外れているので git status には出ません。消そうとしたところガードに止められたので、回り道はしていません。Takuma に `/Users/takumamatsuura/reading-app/.venv/` を消してもらってください。今の Makefile はここを使いません。
- 未確認のもの：
  - `liveActivity` の幅 370、`control` の 160x72、`snippet` の 360x200 は見本の値で、実寸ではありません。G4 の実機で見ます。
  - 拡張の View をアプリのターゲットにも入れる形（ADR 0005 追記の案1）がビルドできるか。ios-engineer が `make ios-build` で確かめます。
- CI に `make check-contracts` を入れるには .github/ の変更が要るので、Takuma の作業です。app.json の commands は変わりません。
- 大きな判断なので、レビュアーに反論を出してもらってください。特に、見本のために W-1〜W-5 の View をアプリと拡張の両方のターゲットに入れる点（ADR 0005 追記）です。
- verifier に伝えてほしいこと：撮影用テストの `w3:waiting`、`w4:control`、`w5:snippet` と `screen.widgetShowcase` のフォールバックは、新しい契約では `hook.error` か要素なしになります。指定を `liveActivity:370x160:waiting`、`control:160x72`、`snippet:360x200` に直し、`hook.widget.canvas` の frame と `showcase.contentOverflow` を確かめてから撮ってもらってください。readouts を消した起動で監査すれば、`hook.*` の50件は混ざりません。

### 意見：テストのターゲットを同期フォルダにするか
- 賛成です。ただし `ReadingAcceptanceTests` だけにするのを勧めます。
  - `ios/AcceptanceTests/` を同期フォルダ（PBXFileSystemSynchronizedRootGroup）にすれば、verifier がファイルを足すときに pbxproj を触らなくて済みます。役割の分け方とも合います。
  - プロジェクトの形式は objectVersion 56 から 77（Xcode 16 以降）に上がります。この製品は Xcode 26 以降が前提なので害はありません。
  - アプリと拡張のターゲットは今のまま、ファイルを明示して並べる形を勧めます。`ReadingAppIntents.swift`、`ThemeTokens.swift`、これから共有する View のファイルのように、両方のターゲットに入るファイルを同期フォルダで持つと、除外の指定が増えて読みにくくなるためです。
  - .md など Swift 以外のファイルがフォルダにあれば、除外の指定が要ります。
  - 変えたあとは `make ios-build` と `make ios-test` を実際に動かして確かめる必要があります（私はまだ確かめていません）。

## ios-engineer に頼むこと
- **見本の View を拡張と共有する**：W-1〜W-5 の View の型（`ReadingLockScreenWidgetView`、`ReadingHomeSmallWidgetView`、Live Activity のロック画面の View、Control のラベルの View、WhereStoppedIntent の小窓の View）を、アプリと拡張の両方のターゲットに入る1つのファイルに移します。
  - View は `@Environment(\.widgetFamily)` や `ActivityViewContext` を読まず、引数でファミリー、`WidgetSnapshot`、`ReadingActivityAttributes` と `ContentState` を受ける形にします。
  - 小窓の View は `WhereStoppedIntent.perform()` からも同じ型を使い、文は同じ関数で作ります。
- 拡張の W-1 と W-2 の `Widget` に `.contentMarginsDisabled()` を付け、余白は View の `padding` で持ちます。
- **見本の画面を作り直す**：`WidgetShowcaseHarnessView` の書き直した View をやめ、共有した型を描きます。
  - 根は `hook.widget.showcase`、枠は `hook.widget.canvas` にします。枠は `<幅>×<高さ>` pt で `.clipped()` します。`liveActivity` と `snippet` は中身に合わせた高さで、指定の高さを上限にします。
  - `-uitest-readouts off` でも見本は出します。
  - 指定の読み方は契約 H22 の文法どおりにし、文字列に何が含まれるかで分ける今の読み方はやめます。範囲の外の指定は `hook.error`（`H22:<値>`）にします。
  - 全体の要素の識別子は design 6 の `widget.rectangular`、`widget.small`、`liveActivity.banner`、`control.startReading`、`intent.snippet` にします。`widget.accessoryRectangular`、`snippet.whereStopped` などは消します。
  - `placeholder` は拡張の `placeholder(in:)` の項目に `.redacted(reason: .placeholder)` を付けて描きます。
  - `ended` で記録がなければ `hook.error`（`H22:liveActivity.ended.noRecord`）にします。
  - 背景は、`accessoryRectangular` が黒の背景で配色 dark、ほかは拡張の containerBackground と同じ色です。
- **`hook.widget` に `showcase` を足す**：h22-widget.schema.json の `$defs/showcase` の形で、`viewType` は描いた型の名前です。`idealHeight` と `contentOverflow` は fixedSize で測ります。
- **H33 を作る**：`-uitest-hold-load` と `yomuma.uitest.load.release`、8つの対象の止める所を作ります。
  - 止める所はすべて `#if UITEST_HOOKS` で包みます。
  - 0.3 秒は本物の時計（ContinuousClock）で数え、超えたら design 5 の読み込み中の形を出します。
  - `hook.state` に `hold.<対象>` を出します。
  - S-1、S-6、S-7、S-9 の灰の帯（redacted）は今の実装にほぼ無いので（ProgressView は BookmarkMarkFlowViews.swift の1か所だけ）、design 5 のとおりに作ります。
- **H8 と H30**：通信なしで復元を押したら、通信の誤りで終え、`store.offline` を出し、`restoreAttempts` を1つ増やします。
- **G3 r2 で見つかった製品の不具合を直す**（つなぎ口はすでにあります）：
  - `settings.save` の失敗で `common.save.error` が出ず、値が前に戻らない
  - S-3c で61字の列を保存しても `mark.line.invalid` が出ない（AC-72）
  - S-8b で認識が0件のとき `mark.ocr.none` が出ない
  - design 5 との食い違いとして指摘された `mark.later.note.empty`、`shelf.load.error`、`scan.hint`、`book.title.invalid`（S-8b）、`camera.denied`（S-9）
  - S-7 で奥付がそろった本に `colophon.capture` が出ないのが仕様どおりかの確認
- `ios/AcceptanceTests/G3EvidenceCaptureTests.swift` をテストのターゲットに足します。できれば `ReadingAcceptanceTests` を同期フォルダにします（上の意見）。そのあと `make ios-build`、`make ios-test`、`make check-contracts` の出力を報告に書いてください。
- 終わったら、reviewer が `grep -n 'struct <viewType>' ios/` で見本の型が拡張と同じであることを照らせるよう、`viewType` に出る型の名前を実装ノートに並べてください。

## 記録（指揮役が保存するときに書き足す）
- 日付：2026-11-02。BASE fc844a7
- 範囲の確かめ：変更は CLAUDE.md、Makefile、contracts/、docs/adr/0005 だけ。指揮役が `make check-contracts` を動かし直し、`ALL PASSED: 8 schemas, 28 examples validated with 0 errors.`
- 次：reviewer（設計）が H22・H33・ADR 0005 の追記を判定してから、ios-engineer が実装する
