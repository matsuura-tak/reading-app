# テストのつなぎ口（H1〜H32）

- 書いた役：tech-lead　日付：2026-10-20（G1 の 7-4a。裁定 27、28）
- 大きな版：1。同じ大きな版の中では足すことだけをする（引数、環境変数、通知、要素の名前と、値の意味と範囲を変えない、消さない）。
- 範囲：芯の AC が使う23個（H1、H2、H4〜H10、H12〜H18、H20〜H22、H26、H28、H29、H31）。選択肢だけで使う7個は 4 に名前だけ書く。
- 関係：PRD 11 の冒頭（H1〜H32 と読み方の決まり）、設計メモ 2 と 5、ADR 0002、0003、0005、contracts/entry-urls.md、contracts/widget-snapshot.schema.json、contracts/ndl-opensearch.yaml、contracts/hooks/ の JSON Schema、design/001-reading-session.md の 6 と 7。
- 前の案：H1〜H14 は docs/reviews/001-reading-session-G0-verifier-r1.md の証拠の 4、H15〜H18 は docs/reviews/001-reading-session-G0-tech-lead-flip-research.md の 4-3。この契約が正で、前の案と違う所は「前の案から変えた所」に書いた。
- 確かめたこと：6 の spike 2つと、JSON Schema の検査。

## 1. どのつなぎ口にも効く決まり

### 1-1 入る構成（ADR 0005）
| 構成 | つなぎ口 | 最適化 | 使う所 |
|---|---|---|---|
| Debug | 入る（コンパイルの条件 `UITEST_HOOKS`） | なし | 開発、G3 の画面とウィジェットのテスト |
| Perf | 入る | Release と同じ（-O、DEBUG なし） | 速さの AC（AC-100〜AC-102）、G4-15 の投入 |
| Release | 入らない | -O | TestFlight、App Store、G4 |

- つなぎ口の型と関数は、アプリのターゲットの `UITestHooks/` の下だけに置き、ファイルごと `#if UITEST_HOOKS` で包む。ローカルのパッケージとウィジェットの拡張には置かない。
- 設定がない起動（テストの起動でなく、1-3 のファイルもない）では、Debug と Perf でもつなぎ口は何もしない（本物の時計、本物の通信、読み出しの要素なし）。

### 1-2 名前の決まり（G2 の grep と nm の目印。ADR 0005）
| 種類 | 形 |
|---|---|
| 起動の引数 | `-uitest-<名前>` |
| 環境変数 | `UITEST_<名前>` |
| Darwin の通知の名前 | `yomuma.uitest.<名前>` |
| 読み出しの要素の識別子 | `hook.<名前>` |
| Swift の型 | `UITestHook` で始める |

### 1-3 テストの起動と、設定のファイル
- テストの起動：`-uitest-` の引数か `UITEST_` の環境変数が1つ以上ある起動。
  - アプリは、その引数と環境変数だけから設定を作る（前の設定と混ぜない）。
  - 作った設定を、App Group の入れ物の `UITestHooks/config.json` に書き直す（形は contracts/hooks/hook-config.schema.json）。
- 引数のない起動：開き直しと、システムが起こしたプロセス。
  - `UITestHooks/config.json` を読み、同じ差し替えを効かせる（時計、タイムゾーン、保存の失敗の残りの回数、通信、カメラ、書誌の差し替え）。
  - これで、強制終了して開き直しても時計が続き、システムが起こしたプロセスでも差し替えが効く（G0 の intents の verifier の要修正3）。
- 開き直すとき、テストは `launchArguments` と `launchEnvironment` を空にしてから `launch()` する。`activate()` は前の引数を付け直す（G0 r1 の注）。
- H1 と H2 は、テストの起動の中でだけ動く「する事」で、設定のファイルには残さない。

### 1-4 動いている途中で変える口（Darwin の通知）
- テストとアプリは、Swift の `import notify` で同じ名前に登録する（spike 1）。
  - テストは状態を `notify_set_state` で書き、`notify_post` で知らせる。
  - アプリは、知らせを main actor で受けて読み直す。
- テストは setUp で登録して、tearDown まで登録を持つ。持つ者がいないと状態が消える［推測］。
- アプリが後ろにいる間に書いた値も、前に戻ったときに読める（spike 1）。

| 通知の名前 | 状態の値 | つなぎ口 |
|---|---|---|
| `yomuma.uitest.clock` | H4 の起点から進めたミリ秒（増やすだけ） | H5 |
| `yomuma.uitest.offline` | 1＝通信なし、0＝通信あり | H8 |
| `yomuma.uitest.barcode` | 読めたコード（13桁の数字を整数で） | H21 |
| `yomuma.uitest.ndl.release` | 使わない（知らせだけ） | H20 の hold |

### 1-5 読み出しの要素
- 置き場所：つなぎ口だけの窓（UIWindow）。
  - 窓の高さは alert の1つ上にする。触る操作を受けない（isUserInteractionEnabled を偽）。
  - 中に 1×1 pt の UIView を置き、それぞれを accessibility の要素にする。
- 値は、テストが読んだ瞬間に作る（accessibilityValue の getter）。
- spike 2 の結果
  - 要素の種類は other で、押せない（isHittable が偽）。押せる要素の数を変えない（buttons の数は同じだった）。
  - 窓の下のボタンを押せた。
  - シートと alert が出ている間も読めた。
  - 91,500字の値を 63 ms で読めた。
- テストの読み方：`app.descendants(matching: .any)["hook.state"].value as? String`

| 識別子 | 中身 | 形 |
|---|---|---|
| `hook.state` | H9、H10、H17（状態、合図の回数、区間の時間、再読み込みの回数） | contracts/hooks/h17-state.schema.json（1行の文字列） |
| `hook.store` | H13（保存先の全項目と写し） | contracts/hooks/h13-store.schema.json |
| `hook.widget` | H22（ウィジェットの中身） | contracts/hooks/h22-widget.schema.json |
| `hook.outbound` | H29（通信の要求）と H31（開いた URL） | contracts/hooks/h29-outbound.schema.json |
| `hook.error` | つなぎ口の誤り（1-6） | 文字列 `<H番号>:<理由>` |

- 速さを測る起動では `-uitest-readouts off` を付け、`hook.*` の要素を出さない（測る区間に読み出しを混ぜない）。

### 1-6 失敗のときの返り方（どのつなぎ口も同じ）
- 引数か JSON が契約に合わないときは、次のようにする。
  - アプリは何も書かない（H1 の初期化も、H2 の投入も、設定のファイルも）。
  - 空の画面に `hook.error` の要素だけを出す（値の例 `H2:books[1].shelf`）。`hook.state` は出さない。
- テストの起動の補助の関数は、起動のたびに `hook.error` がないことを確かめてから進む。
- 契約の中で決めた振る舞い（H20 で合う規則がない、H7 の回数を使い切った）は誤りではない。

### 1-7 時刻の書き方
- 入れる値：RFC 3339 の時差つき（例 `2026-10-15T23:50:00+09:00`）。
- 読み出す値：UTC の Z とミリ秒（例 `2026-10-15T14:50:00.000Z`）。

## 2. 芯のつなぎ口（23個）
- 各つなぎ口の「使う AC」は、設計メモ 2 の対応表と PRD の確かめ方の写し。
- 「どの起動で効くか」の「全部」は、テストの起動、引数のない開き直し、システムが起こしたプロセスの3つ。

### H1 データの初期化
- 目的：本0冊、記録0件、読書なし、設定は既定、写しなし、置き方の案内は見ていない、から始める。テストの順番に頼らない。
- 使う AC：AC-2、AC-4、AC-5、AC-6、AC-8、AC-9、AC-10、AC-11、AC-12、AC-16、AC-32、AC-46、AC-51、AC-53、AC-58、AC-89、AC-90、AC-92、AC-103。ほかのテストも最初の起動で使う（H2 は H1 を含む）。
- 動かし方：起動の引数 `-uitest-reset`。テストの起動のときだけ動く。
- 入力：なし。
- 出力：消すものは次のとおり。消したあと、ふつうに起動する。
  - 主の保存先（SwiftData のストアのファイル）
  - App Group の写し（widget-snapshot.json）
  - アプリの UserDefaults
  - つなぎ口の記録（hook.outbound、回数）
- 失敗：消せなければ `hook.error`（`H1:<理由>`）。
- 本番：Release に入らない（1-1）。

### H2 データの投入
- 目的：決まった id と値で、本、記録、読書中の1件、設定を本番と同じ保存先に入れる。
  - 入れられる項目：置き場所、積読に加えた日時、読み終えた日時（finishedAt）、一行、ページ、ISBN、出版社、レーベル、出版年、設定、記録ごとの読み始めの日時・タイムゾーン・入口の印、置き方の案内を見た印。
- 使う AC：AC-3、AC-7、AC-13、AC-14、AC-15、AC-16、AC-17、AC-18、AC-22、AC-23、AC-24、AC-25、AC-26、AC-27、AC-28、AC-29、AC-30、AC-31、AC-32、AC-33、AC-34、AC-35、AC-39、AC-40、AC-42〜AC-64、AC-75、AC-76、AC-77〜AC-81、AC-86、AC-87、AC-88、AC-89、AC-90、AC-91、AC-93、AC-95、AC-96、AC-99、AC-100、AC-101、AC-102、AC-113。
- 動かし方
  - 小さい投入：環境変数 `UITEST_SEED` に JSON（UTF-8、200,000 バイトまで［推測。起動の環境変数の上限は確かめていない］）。
  - 大きい投入：起動の引数 `-uitest-seed-preset perf500`（下の表）。
  - どちらも H1 の初期化を含み、テストの起動のときだけ動く。
- 入力：contracts/hooks/h02-seed.schema.json。
  - 投入で `settings.widgetGuideShown` を省くと真（PRD 11 の H2）。AC-96 は false を書く。
  - 読み終えた日時は `books[].finishedAt`。shelf が finished のときだけ書け、H13 の同じ名前で読める（design r1 の C の問い4）。
- 出力：主の保存先に入る。続けてアプリがふつうに起動し、写しを書く（widget-snapshot.schema.json の書く時）。
- 失敗：スキーマに合わない、id が重なる、session.bookID が今の本でない、字の数（書記素）が範囲の外。どれも `hook.error`（`H2:<JSON の場所>`）で、何も書かない。
- 本番：Release に入らない。

`perf500` の中身（AC-101、G4-15。毎回同じ）

| 項目 | 値 |
|---|---|
| 本 | 500冊。id は `00000000-0000-4000-8000-` と12桁の番号（1〜500）。1冊目が current、2〜351冊目が tsundoku、352〜500冊目が finished |
| 書名、著者、一行 | 20字、8字、40字の日本語。番号を含む決まった文字列 |
| 記録 | 5,000件。記録 j（0〜4999）は本 (j mod 500)+1 のもの。読み始めは 2026-10-15T21:00:00+09:00 から floor(j/500) 日と (j mod 500) 分前。分は (j mod 60)+1、入口は app、タイムゾーンは Asia/Tokyo |
| 設定 | 既定。置き方の案内は見た |

### H4 時刻の固定
- 目的：アプリの「いま」を決まった時刻にする。壁時計と、経過を測る時計の両方を置き換える。
- 使う AC：AC-10、AC-33、AC-34、AC-40、AC-48、AC-52、AC-53、AC-55、AC-56、AC-57、AC-58、AC-60、AC-61、AC-62、AC-63、AC-75、AC-76、AC-86、AC-89、AC-95、AC-113。
- 動かし方：起動の引数 `-uitest-now <RFC 3339>`。全部の起動で効く（設定のファイルの clockBase）。
  - テストの起動で付けると、H5 の進めた量を0に戻す。
  - 時刻を戻すときは、前の時刻でテストの起動をし直す。
- 入力：時差つきの日時（秒まで、ミリ秒は省ける）。
- 出力：アプリの時計＝起点＋H5 の量。アプリの日時は、すべてこの時計から取る。
  - 晩の日付、分、入口の300秒、問い合わせ直しの24時間、写しの日時、記録の時刻。
- 失敗：日時が読めなければ `hook.error`（`H4:<値>`）。
- 本番：Release に入らない。Release の時計は本物だけ。
- 注意：仮の時計なので、端末が眠ると止まる時計の不具合は G4 で見る（G0 r1）。

### H5 時刻を進める
- 目的：起動したまま、アプリが後ろにいる間も「いま」を進める。sleep で待たない。
- 使う AC：AC-33、AC-34、AC-40、AC-48、AC-52、AC-54、AC-55、AC-56、AC-57、AC-60、AC-61、AC-62、AC-63、AC-75、AC-76、AC-86、AC-89、AC-95、AC-103、AC-113。
- 動かし方：Darwin の通知 `yomuma.uitest.clock`（1-4）。全部の起動で効く。
  - テストは状態に「いまの値＋進める量」を書いてから知らせる（例：301秒なら 301000 を足す）。
- 入力：H4 の起点から進めたミリ秒。減らさない。
- 出力
  - アプリは知らせを受けたら、時計で決まることを判定し直す（伏せの待ち、経過の表示、入口の候補）。
  - 判定し直したあとの値は hook.state で読む。
- 失敗：前より小さい値は無視し、時計は動かさない。H4 がない起動では何もしない。
- 本番：Release に入らない。

### H6 タイムゾーンの固定
- 目的：晩の日付の境目と表示を決める。ことわりがなければ Asia/Tokyo（PRD 11 の冒頭）。
- 使う AC：AC-10、AC-22、AC-34、AC-89、AC-113。
- 動かし方：起動の引数 `-uitest-timezone <IANA の名前>`。全部の起動で効く。
  - 端末のタイムゾーンが変わる場合（AC-22）は、別の名前でテストの起動をし直す。
- 入力：IANA のタイムゾーンの名前（例 `Asia/Tokyo`、`America/Los_Angeles`）。
- 出力：アプリが使うタイムゾーンが変わる。日時の計算と表示（SwiftUI の environment の timeZone を含む）が対象。
- 失敗：知らない名前は `hook.error`（`H6:<値>`）。
- 本番：Release に入らない。

### H7 保存の失敗を起こす
- 目的：決まった保存を、決まった回数だけ失敗させる。
- 使う AC：AC-59（session.start）、AC-60（session.end）、AC-90（store.load）、AC-91（book.add、book.update、book.delete、book.status、record.update、record.delete、mark.save）、AC-95（mark.save）。S-10 の保存の失敗（design/ 5）を確かめるときは settings.save。
- 動かし方
  - 起動の引数 `-uitest-fail-save <対象>:<回数>[:<種類>]`。`,` で区切って複数書ける。
  - 全部の起動で効く。残りの回数は設定のファイルに書き直すので、開き直しても同じ失敗を繰り返さない。
- 入力
  - 対象：`session.start`、`session.end`、`book.add`、`book.update`、`book.status`、`book.delete`、`record.update`、`record.delete`、`mark.save`、`settings.save`、`store.load`。
  - 回数：1以上の整数。
  - 種類：`disk_full` か `unknown`（省くと unknown）。
- 出力：その保存は書く前に失敗する。保存先は変わらず、アプリの失敗の道（文と読み上げ）が動く。
  - 失敗させた回数は hook.state の notice と announce に出る。
  - `store.load` は起動の読み込みで失敗する。回数が1なら、「もう一度読み込む」は成功する。
- 失敗：知らない対象、0回、知らない種類は `hook.error`（`H7:<値>`）。
- 本番：Release に入らない。
  - 失敗させる場所は ReadingStore の保存の入口の1か所。ReadingStore は「保存の前に呼ぶ確かめ」を受け取れ、本番はなにもしない既定を渡す（ADR 0005）。

### H8 通信なし
- 目的：機内モードの代わりに、アプリの通信を「つながっていない」で失敗させる。動いている途中で戻せる。
- 使う AC：AC-6、AC-9、AC-62。
- 動かし方：全部の起動で効く。
  - 起動の引数 `-uitest-offline`：起動のときから通信なし。テストの起動でこれがなければ、通信あり（状態0）にする。
  - 途中で変える：Darwin の通知 `yomuma.uitest.offline`（1-4）。
- 入力：1＝通信なし、0＝通信あり。
- 出力
  - 通信なしの間は、アプリの通信の部品の要求が URLError の notConnectedToInternet ですぐ失敗する。アプリの「通信の状態」の元も、つながっていないを返す。
  - 0 に戻したら、アプリは NWPathMonitor がつながったと言ったときと同じ処理をする（順番待ちの問い合わせ。AC-9）。
  - 失敗させた要求も H29 に outcome `offline` で残る（PRD 11 の H8）。
- 失敗：0 と 1 のほかの値は 1 として扱う。
- 本番：Release に入らない。

### H9 状態を読む
- 目的：`idle` か `reading` かと、画面を点けたままにする設定を、外から読む。
- 使う AC：AC-39、AC-42〜AC-48、AC-51、AC-53、AC-54、AC-56、AC-58、AC-59、AC-60、AC-61、AC-64。
- 動かし方：要素 `hook.state` の値を読む（1-5）。全部の起動で効く。
  - H9 と H17 の値を載せる要素はこれ1つで、画面ごとの根の要素には載せない。
- 入力：なし。
- 出力：contracts/hooks/h17-state.schema.json の `state`、`idleTimerDisabled`、`proximity`。
- 失敗：要素がないときは、テストの起動でないか、1-6 の誤りか、`-uitest-readouts off`。
- 本番：Release に入らない。

### H10 区間の時間
- 目的：アプリの中の区間を、アプリの中で測る（XCUITest の待ちで測らない）。
- 使う AC：AC-55（endToMark）、AC-101（shelfOpen、bookOpen）。
- 動かし方：要素 `hook.state` の `lat.<区間>` を読む。
  - 速さの AC は Perf の構成で、`-uitest-readouts off` を付けて測り、最後に readouts を出す起動で読む［推測。下の注］。
  - 同じ区間は os_signpost の区間でも出す（サブシステムはバンドル ID、カテゴリは latency、名前は区間の名前）。signpost は Release にも残す（G4-15 で Instruments で測るため）。
- 入力：なし。
- 出力：区間の実時間（ContinuousClock。H4 の仮の時計は使わない）を、ミリ秒の整数に切り上げ、測った順に並べる。
  | 区間 | 始まり | 終わり |
  |---|---|---|
  | `endToMark` | `reading.end` のボタンの動作に入った時 | しおりを挟む画面（S-3）の根が最初に出た時 |
  | `shelfOpen` | `toolbar.shelf` のボタンの動作に入った時 | 本棚（S-6）の根が最初に出た時 |
  | `bookOpen` | `shelf.row.<id>` を押した動作に入った時 | 本の画面（S-7）の根が最初に出た時 |
  - 「最初に出た時」は、根の onAppear のあとの最初の CATransaction の確定の時［推測。どの呼び出しで取るかは ios-engineer が決め、G2 で reviewer が見る］。
- 失敗：測れなかった区間はキーを出さない。
- 本番：`lat.*` の読み出しは Release に入らない。signpost は入る。
- 注：readouts を off にすると、同じプロセスでは値を読めない。速さの AC では、測る起動で値を設定のファイルの横（`UITestHooks/latency.json`）に書き、次の readouts on の起動の hook.state に前の起動の値として出す形も、G2 で verifier と決めてよい（足すだけ）。

### H12 文言キーと識別子の対応
- 目的：仮のキーを決めたキーに結び、その文を出す要素と、日英の文を引く。
- 使う AC：AC-16、AC-56、AC-57、AC-58、AC-59、AC-60、AC-90、AC-91、AC-95、AC-96。文言キーを見るほかの AC も同じ。
- 動かし方：アプリの口ではない。
  - 識別子は design/ 6、文言は design/ 7 を正とする。
  - 文を出す要素（知らせ、誤り、空の文）の識別子は、文言キーと同じ名前（design/ 6）。
- 入力：テストのターゲットに、アプリと同じ String Catalog（Localizable.xcstrings）を入れる。
  - ja.lproj か en.lproj から、キーで期待の文を引き、%lld などは AC の値で埋める。
  - アプリは `-AppleLanguages (ja) -AppleLocale ja_JP` で起こす。英語の構成では en と en_US。
- 出力：要素の label と、引いた文が同じかを比べる。
- 失敗：キーがカタログにないとき、テストの補助の関数が落ちる（テストの誤り）。
- 本番：該当なし（アプリにコードを足さない）。

### H13 保存を読む
- 目的：本ごとの全項目、記録、読書中の1件、設定、写しを、画面を通さずに外から読む。
  - 本の項目：置き場所、ISBN、著者、出版社、レーベル、一行、ページ、加えた日時、積読に加えた日時、読み終えた日時、書誌の状態、前に問い合わせた日時、手で直した印。
- 使う AC：AC-2、AC-3、AC-4、AC-7、AC-8、AC-9、AC-10、AC-11、AC-13、AC-14、AC-15、AC-16、AC-22、AC-24、AC-25、AC-26、AC-61、AC-64、AC-71〜AC-75、AC-77、AC-82、AC-89、AC-90、AC-91、AC-92、AC-95、AC-96、AC-113。
- 動かし方：要素 `hook.store` の値（JSON）を読む。全部の起動で効く。
  - 保存する AC は、強制終了して引数なしで開き直したあとも、これで同じ値を読む（PRD 11 の冒頭）。
- 入力：なし。
- 出力：contracts/hooks/h13-store.schema.json。
  - 前の案（G0 r1）の「一覧の行の識別子」は、design/ 6 の `<名前>.<id>` の形になった。
  - この H13 は PRD 11 の冒頭の定義（保存を外から読む）に合わせた。
- 失敗：ストアを開けない間（H7 の store.load を含む）は、`hook.store` の値を空の文字列にする（空の本棚と見分けるため、`books` を空にして返さない）。テストは、開けたあとに読む。
- 本番：Release に入らない。

### H14 初めて起動した端末
- 目的：通知などの許可は API でも simctl でも戻せないので、端末ごと消してから起動する。
- 使う AC：AC-1。
- 動かし方：アプリの口ではない。
  - テストだけの端末を作り、`xcrun simctl erase <端末>` をしてから、その組のテスト（例 `FirstLaunchTests`）だけを `-only-testing` で動かす。
  - ほかのテストと同じ実行に混ぜない。
  - コマンドは 7-4b で CLAUDE.md に書き、app.json の commands は Takuma が書く。
- 入力：消した端末。H1 と H2 は付けない。
- 出力：springboard の alert の数と、アプリが出した画面を XCUITest で見る。
- 失敗：消せないときは、その実行を落とす。
- 本番：該当なし。

### H15 伏せた向きを起こす（テストの側）
- 目的：本物の向きの知らせの流れで、伏せる、起こすを起こす。
- 使う AC：AC-44、AC-45、AC-46、AC-47、AC-48、AC-49、AC-51、AC-54、AC-59。
- 動かし方：テストの側だけ。`XCUIDevice.shared.orientation = .faceDown`、`.portrait`、`.faceUp`。
  - 向きは次のテストに残るので、各テストの setUp で `.portrait` に戻す（flip-research の spike）。
- 入力と出力：向き。アプリの側の口はない。
- 失敗：該当なし。
- 本番：該当なし（テストのコードだけ）。

### H16 伏せの待ちの時計
- 目的：伏せが1.0秒続いたかを、sleep なしで決める。
- 使う AC：AC-44、AC-45、AC-46、AC-47、AC-48、AC-49、AC-51、AC-54、AC-59。
- 動かし方：アプリの側の決まりで、引数はない。
  - H4 のある起動では、伏せの待ちを H4 の時計で数える。
  - 本物のタイマーは使わず、H5 の知らせと向きの変わり目で判定し直す。
- 入力：H15 の向きと、H5 の進めた量（1000 ms 以上で始まる。999 ms では始まらない）。
- 出力：始まったかを hook.state の `state` と `startedBy=flip` で読む。
- 失敗：H4 がない起動では、本物の1.0秒で数える。
- 本番：Release に入らない（Release は本物のタイマーだけ）。

### H17 合図と監視の状態を読む（H9 の続き）
- 目的
  - 次の回数を「アプリが出した回数」として数える：触覚、読み上げ、知らせ、置き方の案内、ウィジェットの再読み込みの要求。
  - 伏せの監視、近接センサー、入口の印を読む。
- 使う AC：AC-3、AC-39、AC-40、AC-44〜AC-49、AC-51、AC-54、AC-59、AC-96。
- 動かし方：要素 `hook.state` の値を読む。全部の起動で効く。
- 入力：なし。
- 出力：contracts/hooks/h17-state.schema.json（値の書き方と読み方）。
  | キー | 値 |
  |---|---|
  | `flipMonitoring` | on か off |
  | `proximity` | true か false |
  | `startedBy` | flip、button、none |
  | `haptic` | 回数 |
  | `announce` | `<文言キー>:<回数>` を `,` で並べる。例 `session.flipStarted.announcement:1` |
  | `notice` | `<文言キー>:<回数>`。置き方の案内は `widgetGuide`（AC-96） |
  | `entry` | このプロセスで最後に残った記録の入口の印。全部の記録の印は H13 |
  | `sessionEntry` | 読書中の1件の入口の印 |
  | `entryCandidate` | メモリの入口の候補（contracts/entry-urls.md の 4） |
  | `widgetReloads` | `<出どころ>:<回数>`（H22 の再読み込みの数え方） |
  - 回数は、プロセスが始まってからの数（開き直すと0から）。
  - 体に届いたか、聞こえたかは G4 で見る。
- 失敗：H9 と同じ。
- 本番：Release に入らない。

### H18 伏せの検知を使えない状態のまね
- 目的：Mac で動くときや、向きの知らせのない端末と同じ動きを、シミュレーターで作る。
- 使う AC：AC-51。
- 動かし方：起動の引数 `-uitest-flip-unavailable`。全部の起動で効く。
- 入力：なし。
- 出力
  - アプリの伏せの検知が「使えない」を返す。
  - 設定（S-10）に `settings.flipToStart.unavailable` が出る。S-1 に `bookmark.flipHint` は出ない（design/ 5、6）。
- 失敗：該当なし。
- 本番：Release に入らない。

### H20 書誌の問い合わせの差し替え
- 目的：国立国会図書館サーチへの問い合わせ（contracts/ndl-opensearch.yaml の ndlOpenSearch）の応答を差し替える。
  - 差し替えられる応答：ISBN と書名ごとの応答、0件、引数の誤り、HTTP の失敗。
  - 問い合わせの順と回数は H29 で読む。
- 使う AC：AC-2、AC-3、AC-4、AC-5、AC-9、AC-10、AC-11、AC-92、AC-103、AC-113。
- 動かし方：全部の起動で効く。
  - 環境変数 `UITEST_NDL_STUB` に JSON を入れる。
  - `hold` の応答は、テストが Darwin の通知 `yomuma.uitest.ndl.release` を送るまで止める（書誌を待つ間の画面を見るため）。
- 入力：contracts/hooks/h20-ndl-stub.schema.json。要素の名前は国立国会図書館のまま（PRD 11 の冒頭）。
  - 書ける要素：`dc:title`、`dcndl:volume`、`author`、`dc:creator`、`dc:publisher`、`dcndl:seriesTitle`、`dcterms:issued`、`dc:identifier`（`xsi:type` が `dcndl:ISBN`、`dcndl:ISBN13` ほか）。
  - 10桁の値（ハイフンつき）を `dcndl:ISBN` にも `dcndl:ISBN13` にも書ける（実際の応答に10桁が入っていた。7-2）。
  - 0件は `zero`。引数の誤りは `paramError`（国立国会図書館は HTTP 200 の0件を返す。ndl-opensearch.yaml の ParamError）。HTTP の失敗は `http` と状態。
- 出力
  - つなぎ口は JSON から、本物と同じ名前空間の RSS 2.0 の XML を組んで返す。アプリの XMLParser の読み方（著者の取り出しを含む）もそのまま通る。
  - 差し替えは、アプリの通信の部品の一番下（送る直前）に入る。だから H29 にも記録される。
- 失敗
  - JSON がスキーマに合わなければ `hook.error`（`H20:<場所>`）。
  - テストの起動で `UITEST_NDL_STUB` がないときは、本物に送らず、通信なしと同じ失敗にし、H29 に outcome `noStub` で残す（テストの書き忘れが画面に出るように）。
- 本番：Release に入らない。Release の通信は本物の URLSession だけ。

### H21 バーコードの読み取りの差し替え
- 目的：読めたコードの並びを流す。読み取りの画面を、本物のカメラなしで進める。
- 使う AC：AC-2、AC-3、AC-9、AC-10、AC-11、AC-92、AC-103。
- 動かし方
  - 起動の引数 `-uitest-barcode-fake` で、読み取りの部品を差し替える。S-8a はカメラの代わりの面を出す（識別子 `scan.camera` は同じ）。
  - コードは Darwin の通知 `yomuma.uitest.barcode` で1つずつ流す（1-4）。
  - 全部の起動で効く。
- 入力：状態に13桁の数字を整数で書いてから知らせる。1回の知らせが1回の読み取り。同じコードを2回流せば、重なりの読み取り（AC-3）になる。
- 出力：アプリは本物の読み取りと同じ関数でコードを受ける（ISBN の確かめ、重なり、書誌の問い合わせ）。
- 失敗：13桁でない値は、読めたコードとして流さず、無視する。
- 本番：Release に入らない。

### H22 ウィジェットの中身を読む
- 目的：ウィジェットの中身を、@testable import を使わずに外から読む（ADR 0003 の「H22 の口」）。
  - 読めるもの：ファミリーと枠を選んで組んだ結果、タイムラインの項目、縦書きの組み方の結果、読み上げのラベルとまとまりの数、押したときの URL、再読み込みの要求の回数、項目を返すまでの時間、見た目の id。
- 使う AC：AC-14、AC-16、AC-27〜AC-35、AC-40、AC-62、AC-64、AC-73、AC-82、AC-99、AC-102。
- 動かし方：全部の起動で効く。
  - 起動の引数 `-uitest-widget <ファミリー>:<幅>x<高さ>[,…]`（例 `accessoryRectangular:172x76,systemSmall:170x170`）。
  - 写しを差し替えて組む：環境変数 `UITEST_WIDGET_SNAPSHOT` に写しの文字列そのもの。`@missing` はファイルなし。壊れた写しの AC に使う。
  - スクリーンショット：起動の引数 `-uitest-widget-show <ファミリー>:<幅>x<高さ>`。つなぎ口だけの画面にウィジェットの View を1つ出し、要素 `hook.widget.canvas` を XCUITest で撮る。
- 作り
  - アプリの中で、拡張と同じ関数（写しを読む、タイムラインの項目を作る、ReadingCore の組み）と、同じ View（W-1、W-2）を使う。
  - 組む時：起動したときと、アプリが再読み込みを求めるたび。システムが写しを読み直すのと同じ時に組み直し、`renders` を最新に置き換える。
  - 押したときの URL：widgetURL はアプリの中では働かないので、描いた元のデータから返す。拡張が同じ関数（`EntryURL.url`）を使うことは、G2 で reviewer が grep で見る。
- まとまりの数（AC-99）
  - XCUITest の要素は数えない。自動化の木には子の Text が残る（ADR 0003。15個）。
  - H22 は、View をつなぎ口の窓（画面の外）の UIHostingController に置く。VoiceOver と同じたどり方（要素になったところで止まる）で数え、数えたら外す［推測。画面の外の窓で数えられるかは、H22 を作る最初の PR で確かめる］。
- 再読み込みの数え方（verifier の目で決めた）
  - アプリは、写しを書いたあとに `WidgetCenter.shared.reloadAllTimelines()` を1回だけ呼ぶ。W-1 と W-2 を1回の呼び出しで頼む。
  - 数えるのは、この呼び出しの回数。ファミリーの数では数えない。
  - 呼び出しごとに出どころを付ける。出どころは `launch`（起動の写し）か、写しを変えた保存の H7 の名前（`book.add`、`book.update`、`book.status`、`book.delete`、`mark.save`、`settings.save`）。
  - AC-33 は、保存を押す前と、しおりの画面に戻ったあとの `mark.save` の差が1。
  - URL で起動したときは、`launch` のほかの出どころが0（URL を受けた処理は再読み込みを求めない。contracts/entry-urls.md の 3）。
- 入力：上の引数と環境変数。
- 出力：要素 `hook.widget` の値。contracts/hooks/h22-widget.schema.json。
  - 状態（normal、noLine、noLineNoPage、hidden、empty、unavailable）、読めない理由。
  - 組みの結果：枠の W、H、i、B、g、R、字の大きさ s、L、referenceL、列の数、送りの回数、kinsokuRelaxed、余り、向き、出した字の並び、縮めたか、升目ごとの元の字・出す字・回す角度・ずらす量・列・行・位置、ページの文字と位置。
  - 読み上げのラベルとまとまりの数、URL、見た目の id、タイムラインの項目と更新の決まり、項目を返すまでの実時間（elapsedMs。AC-102 は Perf の構成で見る）。
  - 再読み込みの要求の回数（合計と出どころごと。hook.state の widgetReloads と同じ数）。
  - 例の数値は形の例で、組みの計算の結果ではない（升目も2つだけ書いた）。
- 失敗：ファミリーか枠が読めなければ `hook.error`（`H22:<値>`）。
- 本番：Release に入らない。拡張には何も足さない。

### H26 カメラの許可の状態の差し替え
- 目的：カメラの許可の状態を、未決定、許可、拒否、制限、読めない端末にする。
- 使う AC：AC-1、AC-2、AC-3、AC-9、AC-10、AC-11、AC-12、AC-92、AC-103。
- 動かし方：起動の引数 `-uitest-camera <状態>[:<求めたときの答え>]`。全部の起動で効く。
  - 例 `-uitest-camera notDetermined:granted`。
- 入力
  - 状態：`notDetermined`、`authorized`、`denied`、`restricted`、`unsupported`。
  - 答え：`granted` か `denied`。未決定で、アプリが許可を求めたときの結果。省くと granted。
- 出力
  - アプリの許可の部品は、AVCaptureDevice の代わりにこの値を返す。本物の許可のダイアログは出ない。
  - 表示は design/ の S-8 の状態（`camera.denied`、`camera.restricted`、`register.scanUnavailable`）。
- 失敗：知らない値は `hook.error`（`H26:<値>`）。
- 本番：Release に入らない。

### H28 入口の URL で起動する
- 目的：ロック画面のウィジェット、小のウィジェットから開いたのと同じ URL で、アプリを起こす。
- 使う AC：AC-40、AC-62。
- 動かし方：テストの側だけ（contracts/entry-urls.md の 6 の (a)）。
  - プロセスのない起動は、`app.terminate()` のあとに `app.open(URL(string: "yomuma://open?entry=lock_widget")!)`。
  - spike 1 の結果：確認の窓は出なかった。アプリは前面に出て、onOpenURL に URL が届いた。XCUIApplication に置いた起動の引数と環境変数も、そのプロセスに渡った。だから H2、H4、H5 と一緒に使える。
  - もし今後の OS で確認の窓が出たら、springboard の `開く`（英語では `Open`）を押してから進む（(b)。7-3 の spike で届いた）。
  - (c) の「テストの構成だけの引数で受け口の関数に渡す」は使わない。OS の URL の道（スキームの登録と onOpenURL）を通らなくなるため。
- 入力：contracts/entry-urls.md の 1 の URL。
- 出力：アプリの onOpenURL が受ける。入口の候補は hook.state の `entryCandidate`、残った印は H13 か hook.state の `entry` で読む。
- 失敗：届かなければ、`entryCandidate` が none のまま。テストは落ちる。
- 本番：アプリの口は足さない。スキームの登録は Release にも入る（entry-urls.md の 1）。

### H29 アプリが出した通信の要求の記録
- 目的：アプリが出した要求の送り先と中身（パーセントエンコードを戻した URL、ヘッダー、本文）を記録する（AC-103）。
- 使う AC：AC-103。H20 の順と回数を見る AC（AC-4、AC-9、AC-10、AC-11、AC-113）も、ここで読む。
- 動かし方：要素 `hook.outbound` の `requests` を読む。全部の起動で効く。
- 入力：なし。
- 出力：contracts/hooks/h29-outbound.schema.json。
  - 記録する場所は、アプリの通信の部品（ReadingStore の書誌の部品）の、送る直前の1か所。H20 と H8 の失敗も記録される。
  - 本番の送り先は `ndlsearch.ndl.go.jp` だけ（AC-103、G4-20。ndl-opensearch.yaml の servers）。
- 記録できないもの：部品を通らない通信と、URLSession が後から足すヘッダー（User-Agent など）。G2 で reviewer が grep で補う（PRD AC-103 の確かめ方）。
- 失敗：該当なし（記録だけ）。
- 本番：Release に入らない。

### H31 アプリが開いた URL の記録
- 目的：アプリが開こうとした外の URL（プライバシーポリシー、ライセンス）を記録する。
- 使う AC：AC-88、AC-93。
- 動かし方：全部の起動で効く。
  - 要素 `hook.outbound` の `openedURLs` を読む。
  - 既定では、記録だけして本当には開かない（アプリが前面に残り、次の操作を続けられる）。
  - 本当に開くときは、起動の引数 `-uitest-openurl passthrough`。
- 入力：なし。
- 出力：開こうとした URL の全体と時刻、本当に開いたか。
  - アプリは外の URL を、SwiftUI の openURL の1か所の部品から開く。その部品を差し替える。
- 失敗：該当なし。
- 本番：Release に入らない。

## 3. テストが読む識別子と属性（つなぎ口に関わる分）
- 識別子は design/ 6 を正とする。この契約で足すのは `hook.*` だけで、画面の要素には足さない。
- H9 と H17 の値を載せる要素は `hook.state`（1-5）。画面ごとの根の要素には載せない（G0 r1 の案から変えた）。
- 見える文字と読み上げが違う要素は、`label` の属性（XCUIElement.label。VoiceOver のラベル）で読む。`value` は空のことがある。見える文字（「p.61」「10/17」）は XCUITest では読めないので、画面のテストでは比べない。
  | 要素 | 読む属性 | 比べる値 |
  |---|---|---|
  | `bookmark.page` | label | 「61ページ」の形（design/ 6。英語の構成では英語の形）。AC の値（ページ）をこの形に直して比べる |
  | `result.summary` | label | 「43ページから61ページ、18分」などの形（design/ 6） |
  | `book.record.row.<記録の id>` | label | 「10月17日の晩、10分」の形。見える「10/17」は accessibilityInputLabels で、XCUITest では読まない |
  | `colophon.title`、`colophon.author`、`colophon.publisher`、`colophon.year` | label | 「名前、値」（例「出版社、新潮社、新潮文庫」） |
  - 形の文は H12 のとおり String Catalog から引く。
- design/ で足された識別子のうち、テストが使うもの
  - `search.clear`：S-8b の検索欄に字があるときだけ出るボタン（label は文言キー `search.clear` の文）。押したあと、`search.field` の値が空に戻ることを見る。
  - `mark.page.previous`：S-3a と S-3b の、前のページがあるときだけ出る消えない文。label は文言キー `mark.page.previous` の文で、%lld に前のページが入る。前のページがない本では0個。
- `widget.line`、`widget.title`、`widget.page` は読み上げから隠すので、XCUITest でなく H22 の `texts` で読む。

## 4. 選択肢だけで使うつなぎ口（名前だけ）
回す所が決まってから書く。番号と名前は PRD 11 の冒頭のとおり。
- H19 写真の読み取りの結果の差し替え（選択肢 (6)）
- H23 Live Activity の要求の記録と差し替え（選択肢 (5)）
- H24 共有シートに渡したものの記録（選択肢 (3)）
- H25 受賞の一覧の差し替え（選択肢 (4)）
- H27 画像のファイルの数と写真ライブラリへの書き込みの回数（選択肢 (6)）
- H30 StoreKit の差し替え（選択肢（課金））
- H32 アプリの外からのインテントを動かす（選択肢 (5) と（ショートカット））

選択肢を残すときは、この契約に節を足し、contracts/hooks/ の enum に値を足す（同じ大きな版）。足す値の例は次のとおり。
- 入口の印：`live_activity`、`intent_start`、`intent_open`
- 区間：`markWait`、`intentStartRequest`、`intentStartForeground`
- 設定：入口の時刻、見た目の id、購入の状態

## 5. 前の案から変えた所
| つなぎ口 | 前の案 | この契約 | 理由 |
|---|---|---|---|
| H2 | 環境変数 `UITEST_SEED` | 同じ。大きい投入は `-uitest-seed-preset perf500` | 本500冊と記録5,000件は環境変数に入りきらない［推測］ |
| H3 | 読書中の状態の投入 | H2 の `session` にまとめた | PRD 11 の冒頭に H3 がない |
| H5 | Darwin の通知などの候補 | Darwin の通知の状態に決めた | spike 1 で、後ろにいる間も含めて届いた |
| H7 | 対象8つ | 対象11個（`book.status`、`mark.save`、`settings.save` を足した） | PRD 11 の H7、design/ 5 の S-10 |
| H9、H17 | 各画面の根の要素の accessibilityValue | つなぎ口の窓の `hook.state` の1つ | シートと alert の間も読め（spike 2）、画面の View に何も足さない |
| H10 | 終わりの画面の accessibilityValue | `hook.state` の `lat.*` と signpost | 区間が3つになり、読み出しを1か所にした |
| H11 | 計測の送り先 | なし | v1.0 は外に送らない（裁定 10） |
| H13 | 一覧の行の識別子 | 保存を読む `hook.store` | PRD 11 の冒頭の定義に合わせた。行の識別子は design/ 6 |
| H17 | `announce=<最後の文言キー>` | `announce=<キー>:<回数>` の並び | PRD 11 の H17 |

## 6. 確かめたこと
- spike 1（2026-10-20、Xcode 27.1、iOS 27.0 のシミュレーター iPhone 17。リポジトリの外で作り、端末は最後に消した）
  - `import notify` は、アプリと UI テストの両方で module として読めた。
  - テストが `notify_set_state` で書いた 4242 を、アプリが `notify_get_state` で読めた。
  - ホーム画面に移したあとに書いた 999 も、`activate()` のあとに読めた。
  - `app.terminate()` のあとの `app.open(URL(string: "yomuma://open?entry=lock_widget")!)` では、次のようになった。
    - springboard の確認は出なかった。
    - `wait(for: .runningForeground)` は真。
    - onOpenURL に `yomuma://open?entry=lock_widget` が届いた。
    - 起動の引数 `-uitest-probe A` と環境変数 `UITEST_X=1` が、そのプロセスに渡っていた。
  - `** TEST SUCCEEDED **`（33.07秒）
- spike 2（同じ環境）
  - alert の1つ上の高さの UIWindow（触る操作を受けない）に、1×1 pt の要素を2つ置いた。
  - 要素の種類は other（rawValue 1）で、isHittable は偽。`app.buttons.count` は1のまま。
  - 窓の下のボタンを押せた（シートが開いた）。
  - シートの間も alert の間も、`hook.state` の値を読めた。値の getter は読むたびに呼ばれた。
  - 91,500字の値を 63 ms で読めた。
  - `** TEST SUCCEEDED **`（13.61秒）
- JSON Schema：contracts/hooks/ の7つと contracts/widget-snapshot.schema.json を jsonschema 4.25.1 の Draft 2020-12 で読んだ。
  - 例はすべて通った。H17 の1行の例は、読み方どおりに直すと examples と同じになった。
  - 契約に合わない17通りは、すべて弾かれた。
- 未確認
  - 起動の環境変数の大きさの上限。
  - Darwin の通知の状態が、登録する者がいないときに消えるか。
  - 画面の外の窓で、VoiceOver のまとまりの数を数えられるか（H22）。
  - CATransaction の確定の時を「最初に出た時」にできるか（H10）。
  - 実機（G4）で `XCUIApplication.open(_:)` が確認なしに届くか。G4 では H28 を使わない。

## 7. 照合のしかた（G2 で verifier と reviewer が使う）
- 芯の AC が使うつなぎ口が、すべてこの契約にあること：PRD 11 の芯の AC の節から `H[0-9]+` を取り出し、この文書の「### H<番号>」と 4 の一覧に照らす（7-4a の報告に、コマンドと出力がある）。
- JSON Schema：`python3 -m venv` に jsonschema を入れ、contracts/hooks/*.json の metaschema の検査と examples の検査をする。
- G2 の受け入れテストは、ここにない引数、環境変数、通知、`hook.*` の識別子を使わない（`grep -rhoE -- '-uitest-[a-z-]+|UITEST_[A-Z_]+|yomuma\.uitest\.[a-z.]+|hook\.[a-z.]+' ios/AcceptanceTests | sort -u` の結果が、この文書にあるものだけ）。
