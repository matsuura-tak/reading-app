（指揮役の注）G3 契約の reviewer r1 の要修正3件と提案の直し（tech-lead の報告）。

## 変更したファイル
BASE は a30896c です（HEAD と一致を確認）。commit も push もしていません。ios/ には触っていません。

- /Users/takumamatsuura/reading-app/contracts/test-hooks.md
  - 見出しを「H1〜H33」に直しました（提案6）。
  - 1-1：パッケージと拡張に「置かない」のは、つなぎ口の入口（引数、環境変数、設定ファイル、Darwin 通知を読む側、`hook.*` の読み出し）だけにしました。例外として「実行時の門」を足しました。中身は次のとおりです（要修正1）。
    - `ReadingStore` に `#if` なしで置いてよい。既定は素通り。
    - 値を変えてよいのは、アプリの `#if UITEST_HOOKS` の中だけ。
    - パッケージには `UITEST_HOOKS` を定義しない。
    - 門の名前は `UITestHook` で始めない。
  - H33 の「本番」：H7 と同じ形に書き直しました（要修正1）。
    - 止める門は `ReadingStore` の読み込みの関数に置きます。`consumeFailSave` と同じ形で、`#if` では包みません。
    - 門を設定する、放す、`hold.<対象>` を書くのは、アプリの `#if UITEST_HOOKS` の中だけです。
    - Release は門を設定する入口を持たないので、止まりません。
  - H22 `reading`：共有する Live Activity の View は、「終える」の押す部分を引数で受けます（要修正2）。
    - 拡張は `Button(intent: EndReadingFromActivityIntent())` を渡します。
    - 見本は `Button(action: {})` を渡します。View の中で intent を直に作りません。
    - 確かめ方：押したあと、次の値が押す前と同じであることを見ます。H17 の `sessionEntry`、H13 の `activeSession` と記録の数、H32 の `invocations` に `EndReadingFromActivityIntent` が足されないこと。
  - H22 の余白：`padding` はシステムの既定の余白と同じ値にします（提案4）。
    - 値は拡張で `EnvironmentValues.widgetContentMargins` を読んで引数で渡すか、定数で持ちます。
    - このプロパティは SDK の WidgetKit.swiftinterface 641〜646行にあることを確かめました（iOS 17.0 から、get のみ）。
    - G4 の実機確認は ADR 0005 を参照する形にしました。
- /Users/takumamatsuura/reading-app/docs/adr/0005-test-hooks.md（追記）
  - H33 の門を H7 と同じ形にした理由を書きました。SwiftPM の define は Release でも効いてしまうためです。
  - 「Release のバイナリに門の関数は残るが、型名は `UITestHook` で始めず、nm の検査の対象外」と書き、1-1 の文を整えたことも記しました。
  - 「終える」を引数で受ける理由と、余白の決まりを書きました。
  - 招く悪い結果に2点を足しました。padding を誤ると本物の余白が変わること、門が Release に残ること。
  - 見直す条件の「`#if` が3か所」は、門の呼び出しの数に置き換えました。
  - 「G4 の実機で見ること」の表を足しました。PRD の G4 の表は pdm の持ち物なので、ADR に置いています。
    - W-1 の余白が変わらない（G4-1 と一緒に撮る）
    - W-2 の余白が変わらない（G4-3 と一緒に撮る）
    - Live Activity の「終える」が本物では読書を終える（G4-6 と一緒に見る）
    - Release で止まらず、nm で `UITestHook` が0件
- /Users/takumamatsuura/reading-app/contracts/dependencies.md:21
  - SwiftUI の「使う所」を「アプリ、ウィジェットの拡張（W-1〜W-5 の View は両ターゲット共有の1ファイル。ADR 0005 追記）」に直しました（要修正3）。
- /Users/takumamatsuura/reading-app/Makefile
  - `SCHEMA_PYTHON` をコマンドの行か環境変数で明示したときは、`contracts-venv` を通りません（venv を作りません）。そのときは、使う Python とその jsonschema の版を出してから検査します（提案5）。
  - 判定は `$(origin SCHEMA_PYTHON)` で行います。版を出すコマンドはカンマを含むので、`SCHEMA_VERSION_ARGS` という変数にまとめました。
- /Users/takumamatsuura/reading-app/CLAUDE.md
  - 契約の検査の節に、`SCHEMA_PYTHON=<python>` の使い方を1行足しました（60行）。

## 実行したコマンドと結果
- `git rev-parse HEAD` → a30896cfaa40531a51393f8e4f9173165db79b97
- `make check-contracts`（既定の venv）→ `ALL PASSED: 8 schemas, 28 examples validated with 0 errors.` 終了コード 0（最後の編集のあとにもう一度動かして同じ結果）。
- `make check-contracts SCHEMA_PYTHON=$HOME/.cache/reading-app/contracts-schema-venv/bin/python SCHEMA_VENV=<スクラッチパッド>/should-not-exist`
  - 出力：`using SCHEMA_PYTHON=... (given; venv is not created)` / `jsonschema 4.25.1 referencing 0.36.2` / `ALL PASSED: 8 schemas, 28 examples validated with 0 errors.` 終了コード 0。
  - あとで `ls` すると `should-not-exist` は「No such file or directory」でした。venv は作られていません。
- `SCHEMA_PYTHON=... make check-contracts`（環境変数で渡す）→ 上と同じ出力で、終了コード 0。
- `make check-contracts SCHEMA_PYTHON=/usr/bin/false-python`（ない Python）→ `no such file or directory`、Error 127 で落ちます。venv に切り替わって通ってしまうことはありません。
- 途中で一度、版を出すコマンドを `$(if)` の中に直に書いてカンマで割れ、`unmatched '` で落ちました。変数にまとめて直しています。
- `grep -n widgetContentMargins <iPhoneSimulator27.2.sdk の WidgetKit.swiftinterface>` → 644行。641〜646行は `extension EnvironmentValues`、`@available(iOS 17.0 …)`、`{ get }` です。
- `grep '"sessionEntry"\|"activeSession"\|"records"' contracts/hooks/h13*.json h17*.json` → H22 の確かめ方で使う項目が、どれもスキーマにあることを確かめました。

## 未解決
- ios/ を書いていないため、次の3つは動かしていません。
  - View の共有と「終える」の引数化が `make ios-build`（警告0）で通るか
  - `widgetContentMargins` の値が実際にいくつになるか
  - 門の名前が `nm` に出ないか
- 3つとも ios-engineer の実装後に確かめることになります。
- PRD 11 の G4 の表（pdm の持ち物）には余白の確かめを足していません。ADR 0005 の「G4 の実機で見ること」に置き、G4-1、G4-3、G4-6 と一緒に撮る形にしました。PRD の表にも載せるなら、pdm に頼む必要があります。
- 契約と ADR の直しを、自分で合格にはしていません。指揮役が差分を確かめる扱いで構いませんが、次の2点は reviewer に反論を出してもらう価値があります。
  - 1-1 に「実行時の門」という例外を足したこと
  - nm の検査の対象から門を外したこと

## ios-engineer に頼むこと（最新の全部。これだけを見て実装できるように並べ直しました）
- **見本の View を拡張と共有する**
  - W-1〜W-5 の View の型を、アプリと拡張の両方のターゲットに入る1つのファイルに移します。`ReadingLockScreenWidgetView`、`ReadingHomeSmallWidgetView`、Live Activity のロック画面の View、Control のラベルの View、WhereStoppedIntent の小窓の View です。
  - View は `@Environment(\.widgetFamily)` や `ActivityViewContext` を読みません。ファミリー、`WidgetSnapshot`、`ReadingActivityAttributes` と `ContentState` を引数で受けます。
  - 小窓の View は、`WhereStoppedIntent.perform()` からも同じ型を使います。文は同じ関数で作ります。
  - Live Activity の View は、「終える」の押す部分を引数で受けます（例：ラベルを受けてボタンを返す `@ViewBuilder` の引数）。View の中で `EndReadingFromActivityIntent` を直に作りません。
    - 拡張は `Button(intent: EndReadingFromActivityIntent()) { label }` を渡します。
    - 見本は `Button(action: {}) { label }` を渡します。
    - 識別子 `liveActivity.end` と見た目は両方で同じにします。
- **余白**
  - 拡張の W-1 と W-2 の `Widget` に `.contentMarginsDisabled()` を付け、余白は View の `padding` で持ちます。
  - `padding` の値は、システムの既定の余白と同じにします。拡張で `@Environment(\.widgetContentMargins)` を読んで View の引数に渡すか、同じ値を定数で持ちます。見本には拡張と同じ値を渡します。
  - 本物のウィジェットの見た目（文字の位置）を変えないでください。
- **見本の画面を作り直す**
  - `WidgetShowcaseHarnessView` の書き直した View をやめ、共有した型を描きます。
  - 根は `hook.widget.showcase`、枠は `hook.widget.canvas` にします。枠は `<幅>×<高さ>` pt で `.clipped()` します。`liveActivity` と `snippet` は中身に合わせた高さで、指定の高さを上限にします。
  - `-uitest-readouts off` でも見本は出します。
  - 指定の読み方は契約 H22 の文法どおりにします。文字列に何が含まれるかで分ける今の読み方はやめます。範囲の外の指定は `hook.error`（`H22:<値>`）にします。
  - 全体の要素の識別子は、design 6 の `widget.rectangular`、`widget.small`、`liveActivity.banner`、`control.startReading`、`intent.snippet` にします。`widget.accessoryRectangular`、`snippet.whereStopped` などは消します。
  - `placeholder` は、拡張の `placeholder(in:)` の項目に `.redacted(reason: .placeholder)` を付けて描きます。
  - `ended` で記録がなければ `hook.error`（`H22:liveActivity.ended.noRecord`）にします。
  - 背景は、`accessoryRectangular` が黒で配色 dark、ほかは拡張の containerBackground と同じ色です。
- **`hook.widget` に `showcase` を足す**
  - 形は h22-widget.schema.json の `$defs/showcase` です。`viewType` には描いた型の名前を入れます。
  - `idealHeight` と `contentOverflow` は fixedSize で測ります。
- **H33 を作る（H7 と同じ形）**
  - 止める門は、`ReadingStore` の読み込みの関数に、`#if` なしの実行時の門として置きます。`consumeFailSave(for:)` と同じ形で、既定は素通りです。
    - 対象は8つです：`store.load`、`shelf.load`、`book.load`、`recommend.load`、`catalog.lookup`、`storekit.products`、`storekit.purchase`、`storekit.restore`。
    - 読み込みがアプリのターゲットにある対象も、同じ形の門にします。
  - `ReadingKit/Package.swift` に `UITEST_HOOKS` の define を足さないでください。
  - 門の型と関数の名前は `UITestHook` で始めないでください。
  - 次の処理は、アプリの `#if UITEST_HOOKS` の中（`UITestHooks/` のコーディネータ）だけに置きます。
    - `-uitest-hold-load` を読み、門に対象を設定する。
    - `yomuma.uitest.load.release` を受けて放す。
    - `hook.state` に `hold.<対象>`（`waiting`、`held`、`shown`、`released`）を書く。
  - 0.3秒は本物の時計（ContinuousClock）で数えます。超えたら、design 5 の読み込み中の形を出します。
  - S-1、S-6、S-7、S-9 の灰の帯（redacted）は今の実装にほぼありません。ProgressView は BookmarkMarkFlowViews.swift の1か所だけです。design 5 のとおりに作ってください。
- **H8 と H30**
  - 通信なしで復元を押したら、通信の誤りで終え、`store.offline` を出し、`restoreAttempts` を1つ増やします。
- **G3 r2 で見つかった製品の不具合を直す**（つなぎ口はすでにあります）
  - `settings.save` が失敗しても `common.save.error` が出ず、値が前に戻らない。
  - S-3c で61字の列を保存しても `mark.line.invalid` が出ない（AC-72）。
  - S-8b で認識が0件のとき `mark.ocr.none` が出ない。
  - design 5 と食い違っている `mark.later.note.empty`、`shelf.load.error`、`scan.hint`、`book.title.invalid`（S-8b）、`camera.denied`（S-9）。
  - S-7 で、奥付がそろった本に `colophon.capture` が出ないのが仕様どおりかを確かめる。
- **拡張の文言の直書きを文言キーにする**（reviewer の提案7。判定には数えません）
  - ReadingWidgets.swift:102、155、233、368 ほかの「しおり」「いま読んでいる本はありません」「今夜の読書を始める」を、Localizable を通すようにします。
  - View を共有すると、英語の撮影でそのまま出てしまうためです。
- **テストのターゲットと報告**
  - `ios/AcceptanceTests/G3EvidenceCaptureTests.swift` をテストのターゲットに足します。できれば `ReadingAcceptanceTests` を同期フォルダにしてください。
  - そのあと `make ios-build`、`make ios-test`、`make check-contracts` を動かし、出力を報告に書いてください。
  - 実装ノートに、次の2つを書いてください。
    - `viewType` に出る型の名前の一覧。reviewer が `grep -n 'struct <viewType>' ios/` で照らせるようにするためです。
    - H33 の門の関数の名前。nm の検査の対象外であることを確かめられるようにするためです。

## 記録（指揮役が保存するときに書き足す）
- 日付：2026-11-02。BASE a30896c
- 指揮役の確かめ（裁定 22 と同じ扱い。判定役の3回目は呼ばない）
  - 範囲：変更は CLAUDE.md、Makefile、contracts/dependencies.md、contracts/test-hooks.md、docs/adr/0005-test-hooks.md だけ。
  - 要修正1：test-hooks.md 1-1 に「実行時の門」の例外（既定は素通り、値を変えるのはアプリの `#if UITEST_HOOKS` の中だけ、名前は `UITestHook` で始めない）と、H33 の「本番」を H7 と同じ形にした文がある。reviewer の直す方向と同じ。
  - 要修正2：H22 `reading` に、拡張は `Button(intent:)`、見本は `Button(action: {})` を渡す形と、押しても状態が変わらないことの確かめ方がある。
  - 要修正3：dependencies.md の SwiftUI の行が直っている。
  - `make check-contracts` → `ALL PASSED: 8 schemas, 28 examples validated with 0 errors.`
  - tech-lead が「反論を出してもらう価値がある」とした2点（1-1 の例外、nm の対象外）は、どちらも reviewer 自身の直す方向の文。ios-engineer の実装のあと、reviewer（コード）が実物で見る。
