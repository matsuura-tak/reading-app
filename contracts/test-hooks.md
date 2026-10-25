# テストのつなぎ口（H1〜H32）

- 書いた役：tech-lead　日付：2026-10-20（G1 の 7-4a。裁定 27、28）。2026-10-25 に更新（G1 の 7-A：これまで選択肢だった H19、H23、H24、H25、H27、H30、H32 をすべて v1.0 標準仕様に昇格し、H20 を端末内の書誌 SQLite DB および共起テーブルの差し替えに、H29 を外部 HTTP 通信 0 件の検証用に更新。全149 AC に対応）
- 大きな版：1。同じ大きな版の中では足すことだけをする（引数、環境変数、通知、要素の名前と、値の意味と範囲を変えない、消さない）。
- 範囲：v1.0 の全149 AC（AC-1〜AC-149）が使う30個（H1、H2、H4〜H10、H12〜H32。H3 と H11 は欠番）。
- 関係：PRD 11 の冒頭（H1〜H32 と読み方の決まり）、設計メモ 2 と 5、ADR 0001〜0005、contracts/entry-urls.md、contracts/widget-snapshot.schema.json、contracts/hooks/ の JSON Schema、design/001-reading-session.md の 6 と 7。
- 前の案：H1〜H14 は docs/reviews/001-reading-session-G0-verifier-r1.md の証拠の 4、H15〜H18 は docs/reviews/001-reading-session-G0-tech-lead-flip-research.md の 4-3、変更差分は docs/reviews/001-reading-session-G0-prd3-verifier-r1.md。この契約が正で、前の案と違う所は「5. 前の案から変えた所」に書いた。
- 確かめたこと：6 の spike 2つと、JSON Schema の検査。

## 1. どのつなぎ口にも効く決まり

### 1-1 入る構成（ADR 0005）
| 構成 | つなぎ口 | 最適化 | 使う所 |
|---|---|---|---|
| Debug | 入る（コンパイルの条件 `UITEST_HOOKS`） | なし | 開発、G3 の画面とウィジェットのテスト |
| Perf | 入る | Release と同じ（-O、DEBUG なし） | 速さの AC（AC-55、AC-100〜AC-102、AC-114、AC-115、AC-149）、G4-15 の投入 |
| Release | 入らない（os_signpost のみ残す） | -O | TestFlight、App Store、G4 |

- つなぎ口の型と関数は、アプリのターゲットの `UITestHooks/` の下だけに置き、ファイルごと `#if UITEST_HOOKS` で包む。ローカルのパッケージとウィジェットの拡張には置かない。
- 設定がない起動（テストの起動でなく、1-3 のファイルもない）では、Debug と Perf でもつなぎ口は何もしない（本物の時計、本物の DB、読み出しの要素なし）。

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
  - `UITestHooks/config.json` を読み、同じ差し替えを効かせる（時計、タイムゾーン、保存の失敗の残りの回数、通信状態、カメラ、端末内書誌 DB、OCR、Live Activity、受賞一覧、StoreKit、インテント）。
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
| `yomuma.uitest.ocr.release` | 使わない（知らせだけ） | H19 の hold |
| `yomuma.uitest.barcode` | 読めたコード（13桁の数字を整数で。ISBN-13 または `192` で始まる2段目 Cコード） | H21 |
| `yomuma.uitest.liveactivity.transition` | 1＝予約を始まった状態（`started`）にする、2＝システムが8時間で終えた状態（`dismissedBySystem`）にする | H23 |
| `yomuma.uitest.storekit.refund` | 1＝購入を返金された状態にする | H30 |
| `yomuma.uitest.intent.run` | 1＝`StartReadingIntent`、2＝`EndReadingIntent`、3＝`WhereStoppedIntent`、4＝`ContinueReadingIntent` | H32 |

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
| `hook.liveActivity` | H23（Live Activity の状態、要求の履歴・出どころ・読み上げラベル） | contracts/hooks/hook-config.schema.json の `$defs/h23LiveActivityReadout` |
| `hook.shareCard` | H24（共有シートに渡した読み終えカード画像の検査結果） | contracts/hooks/hook-config.schema.json の `$defs/h24ShareCardReadout` |
| `hook.awards` | H25（同梱および現在有効な受賞の一覧） | contracts/hooks/hook-config.schema.json の `$defs/h25AwardsReadout` |
| `hook.mediaAudit` | H27（保存領域・App Group の画像ファイル数と写真ライブラリ書き込み回数） | contracts/hooks/hook-config.schema.json の `$defs/h27MediaAuditReadout` |
| `hook.outbound` | H29（外部 HTTP 通信の要求 0 件）と H31（開いた外部 URL） | contracts/hooks/h29-outbound.schema.json |
| `hook.storekit` | H30（StoreKit の購入・復元・返金の状態と回数） | contracts/hooks/hook-config.schema.json の `$defs/h30StoreKitReadout` |
| `hook.intents` | H32（App Intents の実行結果・声・小窓と登録済みショートカット・Control 一覧） | contracts/hooks/hook-config.schema.json の `$defs/h32IntentsReadout` |
| `hook.error` | つなぎ口の誤り（1-6） | 文字列 `<H番号>:<理由>` |

- 速さを測る起動では `-uitest-readouts off` を付け、`hook.*` の要素を出さない（測る区間に読み出しを混ぜない）。

### 1-6 失敗のときの返り方（どのつなぎ口も同じ）
- 引数か JSON が契約に合わないときは、次のようにする。
  - アプリは何も書かない（H1 の初期化も、H2 の投入も、設定のファイルも）。
  - 空の画面に `hook.error` の要素だけを出す（値の例 `H2:books[1].status`）。`hook.state` は出さない。
- テストの起動の補助の関数は、起動のたびに `hook.error` がないことを確かめてから進む。
- 契約の中で決めた振る舞い（H20 で該当する ISBN がない、H7 の回数を使い切った）は誤りではない。

### 1-7 時刻の書き方
- 入れる値：RFC 3339 の時差つき（例 `2026-10-15T23:50:00+09:00`）。
- 読み出す値：UTC の Z とミリ秒（例 `2026-10-15T14:50:00.000Z`）。

## 2. v1.0 標準のつなぎ口（全30個：H1、H2、H4〜H10、H12〜H32）
- 各つなぎ口の「使う AC」は、設計メモ 2 の対応表と PRD の確かめ方の写し。
- 「どの起動で効くか」の「全部」は、テストの起動、引数のない開き直し、システムが起こしたプロセスの3つ。

### H1 データの初期化
- 目的：本0冊、記録0件、読書なし、設定は既定、写しなし、置き方の案内は見ていない、から始める。テストの順番に頼らない。
- 使う AC：AC-2、AC-4、AC-5、AC-6、AC-8、AC-9、AC-10、AC-11、AC-12、AC-16、AC-32、AC-46、AC-51、AC-53、AC-58、AC-89、AC-90、AC-92、AC-103、AC-117、AC-122、AC-126、AC-135、AC-137、AC-139。ほかのテストも最初の起動で使う（H2 は H1 を含む）。
- 動かし方：起動の引数 `-uitest-reset`。テストの起動のときだけ動く。
- 入力：なし。
- 出力：消すものは次のとおり。消したあと、ふつうに起動する。
  - 主の保存先（アプリの保存領域のストアファイル）
  - App Group の写し（widget-snapshot.json）
  - アプリの UserDefaults
  - 予約中・進行中の Live Activity
  - つなぎ口の記録（hook.outbound、hook.liveActivity、hook.shareCard、hook.intents、回数）
- 失敗：消せなければ `hook.error`（`H1:<理由>`）。
- 本番：Release に入らない（1-1）。

### H2 データの投入
- 目的：決まった id と値で、本、記録、読書中の1件、設定、推薦の重みを本番と同じ保存先に入れる。
  - 入れられる項目：本ごとの置き場所（`status`）、積読に加えた日時、読み終えた日時（`finishedAt`）、一行（`lastLine`）、進み具合の単位 `progressUnit`（`page` / `location` / `percent`）と値（`page` / `location` / `percent`）、電子書籍フラグ（`isEbook`）、書名未設定フラグ（`isTitlePending`）、ISBN、著者、出版社、レーベル、出版年、シリーズ名（`seriesTitle`）・巻数（`volumeNumber`）、NDC（`ndc`）、3つの設定（`flipToStartEnabled`、`hideOnWidgets`、`entryTime`）、見た目の id（`appearanceID`）、購入の状態（`isPlusPurchased`）、置き方の案内を見た印（`hasShownWidgetGuide`）、推薦の理由分類（`readers` / `nextVolume` / `sameAuthor` / `sameAward` / `sameLabel`）ごとの `chosen` / `skipped` カウント、記録ごとの読み始め・読み終わりの日時・晩の日付・入口の印・進み具合。
- 使う AC：AC-3、AC-7、AC-13〜AC-35、AC-36〜AC-64、AC-75〜AC-82、AC-85〜AC-91、AC-93、AC-95〜AC-102、AC-104、AC-113〜AC-125、AC-127〜AC-136、AC-138、AC-140〜AC-148。
- 動かし方
  - 小さい投入：環境変数 `UITEST_SEED` に JSON（UTF-8、200,000 バイトまで［推測。起動の環境変数の上限は確かめていない］）。
  - 大きい投入：起動の引数 `-uitest-seed-preset perf500`（下の表）。
  - どちらも H1 の初期化を含み、テストの起動のときだけ動く。
- 入力：contracts/hooks/h02-seed.schema.json。
  - 投入で `settings.hasShownWidgetGuide` は AC-96 のみ `false`、他は `true` にする（PRD 11 の H2）。
  - 読み終えた日時は `books[].finishedAt`。status が `finished` のときだけ書け、H13 の同じ名前で読める。
  - 名無しの今の本（`isTitlePending = true`）は AC-139、AC-140 で使う。
- 出力：主の保存先に入る。続けてアプリがふつうに起動し、写しを書く（widget-snapshot.schema.json の書く時）。
- 失敗：スキーマに合わない、id が重なる、activeSession.bookId が今の本でない、字の数（書記素）が範囲の外。どれも `hook.error`（`H2:<JSON の場所>`）で、何も書かない。
- 本番：Release に入らない。

`perf500` の中身（AC-101、G4-15。毎回同じ）

| 項目 | 値 |
|---|---|
| 本 | 500冊。id は `00000000-0000-4000-8000-` と12桁の番号（1〜500）。1冊目が本 A（`current`。id `00000000-0000-4000-8000-000000000001`）、2〜351冊目の350冊が `tsundoku`、352〜500冊目の149冊が `finished` |
| 書名、著者、一行 | 20字、8字、40字の日本語。番号を含む決まった文字列 |
| 記録 | 5,000件。分け方は AC-101 の Given のとおり：本 A（1冊目）に1,000件、2〜401冊目の400冊に10件ずつ、402〜500冊目の99冊は0件。本 b の r 件目（r は0から）の読み始めは 2026-10-15T21:00:00+09:00 から r 日と (b−1) 分前。通し番号 j（0〜4999。本 A の1,000件、2冊目の10件、…、401冊目の10件の順）で、記録の id は `00000000-0000-4000-9000-` と12桁の j+1、分は (j mod 60)+1。入口は `app`、タイムゾーンは `Asia/Tokyo` |
| 設定 | 既定。置き方の案内は見た |

- AC-101 の「A の本の画面を開く」は、本棚で `shelf.row.00000000-0000-4000-8000-000000000001` を押す。G4-15 も同じ中身を入れる（ADR 0005）。

### H4 時刻の固定
- 目的：アプリの「いま」を決まった時刻にする。壁時計と、経過を測る時計の両方を置き換える。
- 使う AC：AC-33、AC-34、AC-36、AC-38、AC-40、AC-41、AC-48、AC-52、AC-53、AC-55〜AC-58、AC-60〜AC-63、AC-65、AC-75、AC-76、AC-86、AC-89、AC-95、AC-97、AC-98、AC-104、AC-114〜AC-116、AC-118、AC-120、AC-124、AC-125、AC-130〜AC-132、AC-134、AC-136、AC-139、AC-141、AC-144。
- 動かし方：起動の引数 `-uitest-now <RFC 3339>`。全部の起動で効く（設定のファイルの clockBase）。
  - テストの起動で付けると、H5 の進めた量を0に戻す。
  - 時刻を戻すときは、前の時刻でテストの起動をし直す。
- 入力：時差つきの日時（秒まで、ミリ秒は省ける）。
- 出力：アプリの時計＝起点＋H5 の量。アプリの日時は、すべてこの時計から取る。
  - 晩の日付、分、入口の300秒、Live Activity の予約時刻と古くなる時刻（staleDate）、写しの日時、記録の時刻。
- 失敗：日時が読めなければ `hook.error`（`H4:<値>`）。
- 本番：Release に入らない。Release の時計は本物だけ。

### H5 時刻を進める
- 目的：起動したまま、アプリが後ろにいる間も「いま」を進める。sleep で待たない。
- 使う AC：AC-33、AC-34、AC-36、AC-38、AC-40、AC-41、AC-48、AC-52、AC-54〜AC-57、AC-60〜AC-63、AC-65、AC-75、AC-76、AC-86、AC-89、AC-95、AC-97、AC-98、AC-103、AC-104、AC-114〜AC-116、AC-118、AC-124、AC-125、AC-130〜AC-132、AC-134、AC-136、AC-139、AC-141、AC-144。
- 動かし方：Darwin の通知 `yomuma.uitest.clock`（1-4）。全部の起動で効く。
  - テストは状態に「いまの値＋進める量」を書いてから知らせる（例：301秒なら 301000 を足す）。
- 入力：H4 の起点から進めたミリ秒。減らさない。
- 出力
  - アプリは知らせを受けたら、時計で決まることを判定し直す（伏せの待ち、経過の表示、入口の候補、Live Activity の staleDate 判定）。
  - 判定し直したあとの値は hook.state で読む。
- 失敗：前より小さい値は無視し、時計は動かさない。H4 がない起動では何もしない。
- 本番：Release に入らない。

### H6 タイムゾーンの固定
- 目的：晩の日付の境目と表示を決める。ことわりがなければ Asia/Tokyo（PRD 11 の冒頭）。
- 使う AC：AC-22、AC-34、AC-36、AC-38、AC-85、AC-89、AC-97、AC-98、AC-114、AC-115、AC-120、AC-127、AC-128、AC-130、AC-136、AC-139。
- 動かし方：起動の引数 `-uitest-timezone <IANA の名前>`。全部の起動で効く。
  - 端末のタイムゾーンが変わる場合（AC-22）は、別の名前でテストの起動をし直す。
- 入力：IANA のタイムゾーンの名前（例 `Asia/Tokyo`、`America/Los_Angeles`）。
- 出力：アプリが使うタイムゾーンが変わる。日時の計算と表示（SwiftUI の environment の timeZone を含む）が対象。
- 失敗：知らない名前は `hook.error`（`H6:<値>`）。
- 本番：Release に入らない。

### H7 保存の失敗を起こす
- 目的：決まった保存または読み込みを、決まった回数だけ失敗させる。
- 使う AC：AC-59（session.start）、AC-60（session.end）、AC-90（store.load）、AC-91（book.add、book.update、book.delete、book.status、record.update、record.delete、mark.save）、AC-95（mark.save）、AC-119（session.start）、AC-132（session.end）、AC-133（store.load）。S-10 の保存の失敗（design/ 5）を確かめるときは settings.save。
- 動かし方
  - 起動の引数 `-uitest-fail-save <対象>:<回数>[:<種類>]`。`,` で区切って複数書ける。
  - 全部の起動で効く。残りの回数は設定のファイルに書き直すので、開き直しても同じ失敗を繰り返さない。
- 入力
  - 対象：`session.start`、`session.end`、`book.add`、`book.update`、`book.status`、`book.delete`、`record.update`、`record.delete`、`mark.save`、`settings.save`、`store.load`。
  - 回数：1以上の整数。
  - 種類：`disk_full` か `unknown`（省くと unknown）。
- 出力：その保存は書く前に失敗する。保存先は変わらず、アプリの失敗の道（文と読み上げ、またはインテントのエラー返却）が動く。
  - 失敗させた回数は hook.state の notice と announce に出る。
  - `store.load` は起動またはインテントの読み込みで失敗する。回数が1なら、次の読み込みは成功する。
- 失敗：知らない対象、0回、知らない種類は `hook.error`（`H7:<値>`）。
- 本番：Release に入らない。

### H8 通信なし
- 目的：機内モードの代わりに、アプリの通信状態を「つながっていない」にする。動いている途中で戻せる。
- 使う AC：AC-6、AC-62、AC-110、AC-125。
- 動かし方：全部の起動で効く。
  - 起動の引数 `-uitest-offline`：起動のときから通信なし。テストの起動でこれがなければ、通信あり（状態0）にする。
  - 途中で変える：Darwin の通知 `yomuma.uitest.offline`（1-4）。
- 入力：1＝通信なし、0＝通信あり。
- 出力
  - 通信なしの間は、アプリの「通信の状態」がオフラインを返す。
  - 書誌の検索は端末内の SQLite DB（H20）を使うため、通信なしでもバーコード登録や書名候補補完はその場で動き、外部 HTTP 通信要求（H29）は0件のまま（AC-6）。
  - 課金シート（AC-110）では、通信なしのときに品が読めない状態として `store.offline` を出す。
- 失敗：0 と 1 のほかの値は 1 として扱う。
- 本番：Release に入らない。

### H9 状態を読む
- 目的：`idle` か `reading` かと、画面を点けたままにする設定を、外から読む。
- 使う AC：AC-39、AC-42〜AC-48、AC-51、AC-53、AC-54、AC-56、AC-58〜AC-61、AC-64、AC-114〜AC-119、AC-121、AC-123、AC-124、AC-130〜AC-136、AC-139。
- 動かし方：要素 `hook.state` の値を読む（1-5）。全部の起動で効く。
  - H9 と H17 の値を載せる要素はこれ1つで、画面ごとの根の要素には載せない。
- 入力：なし。
- 出力：contracts/hooks/h17-state.schema.json の `state`、`idleTimerDisabled`、`proximity`。
- 失敗：要素がないときは、テストの起動でないか、1-6 の誤りか、`-uitest-readouts off`。
- 本番：Release に入らない。

### H10 区間の時間
- 目的：アプリの中の区間を、アプリの中で測る（XCUITest の待ちで測らない）。
- 使う AC：AC-55（endToMark）、AC-94（markWait）、AC-101（shelfOpen、bookOpen）、AC-114（intentStartRequest）、AC-115（intentStartForeground）、AC-149（barcodeLookup、titleSearch）。
- 動かし方：要素 `hook.state` の `lat.<区間>` を読む。
  - 速さの AC は Perf の構成で、`-uitest-readouts off` を付けて測る。測った値は `UITestHooks/latency.json` に残り、次に readouts を出す起動の hook.state の `prevLat.<区間>` で読む（形は h17-state.schema.json の `$defs/latencyFile`）。
  - 同じ区間は os_signpost の区間でも出す（サブシステムはバンドル ID、カテゴリは latency、名前は区間の名前）。signpost は Release にも残す（G4-10、G4-15 で測るため）。
- 入力：なし。
- 出力：区間の実時間（ContinuousClock。H4 の仮の時計は使わない）を、ミリ秒の整数に切り上げ、測った順に並べる。

| 区間 | 始まり | 終わり | 関わる AC |
|---|---|---|---|
| `endToMark` | `reading.end` のボタンの動作に入った時 | しおりを挟む画面（S-3）の根が最初に出た時 | AC-55 |
| `shelfOpen` | `toolbar.shelf` のボタンの動作に入った時 | 本棚（S-6）の根が最初に出た時 | AC-101 |
| `bookOpen` | `shelf.row.<id>` を押した動作に入った時 | 本の画面（S-7）の根が最初に出た時 | AC-101 |
| `markWait` | OCR 待ちの間に `mark.manual` または `mark.pageOnly` を押した動作に入った時 | その入力画面の欄が最初に出た時 | AC-94 |
| `intentStartRequest` | 「読み始める」（`StartReadingIntent.perform()`）に入った時 | すぐ始める Live Activity の要求が返った時 | AC-114 |
| `intentStartForeground` | しおり画面が前面のときに「読み始める」（`StartReadingIntent.perform()`）に入った時 | 前面に読書中の画面（S-2）の根が最初に出た時 | AC-115 |
| `barcodeLookup` | バーコード（H21 またはスキャナ）を1件受け取った時 | 読み取り一覧に `scan.row.<ISBN>` が最初に出た時 | AC-149 |
| `titleSearch` | `manual.title` に3字以上入った時 | 候補の `search.row` が最初に出た時 | AC-149 |

- 失敗：測れなかった区間はキーを出さない。
- 本番：`lat.*` の読み出しは Release に入らない。signpost は入る。

### H12 文言キーと識別子の対応
- 目的：仮のキーを決めたキーに結び、その文を出す要素と、日英の文を引く。
- 使う AC：AC-16、AC-56〜AC-60、AC-90、AC-91、AC-95、AC-96。文言キーを見るほかの AC も同じ。
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
- 目的：本ごとの全項目、記録、読書中の1件、設定、推薦の重み、破損退避ファイル一覧を、画面を通さずに外から読む。
  - 本の項目：置き場所（`status`）、`isEbook`、`isTitlePending`、進み具合の単位（`progressUnit`）と値（`page` / `location` / `percent`）、ISBN、書名、著者、出版社、レーベル、出版年、シリーズ名・巻数、NDC、一行（`lastLine`）、加えた日時、更新日時、読み終えた日時。
  - 設定と重み：3つの設定、見た目の id（`appearanceID`）、購入の状態（`isPlusPurchased`）、推薦の理由ごとの `chosen` / `skipped` カウント。
- 使う AC：AC-2〜AC-11、AC-13〜AC-16、AC-22、AC-24〜AC-26、AC-61、AC-64、AC-67〜AC-75、AC-77、AC-82、AC-83、AC-87、AC-89〜AC-92、AC-95、AC-96、AC-105〜AC-109、AC-111、AC-113〜AC-119、AC-121〜AC-123、AC-125、AC-130〜AC-135、AC-137〜AC-147。
- 動かし方：要素 `hook.store` の値（JSON）を読む。全部の起動で効く。
  - 保存する AC は、強制終了して引数なしで開き直したあとも、これで同じ値を読む（PRD 11 の冒頭）。
- 入力：なし。
- 出力：contracts/hooks/h13-store.schema.json。
- 失敗：ストアを開けない間（H7 の store.load を含む）は、`hook.store` の値を空の文字列にする（空の本棚と見分けるため、`books` を空にして返さない）。テストは、開けたあとに読む。
- 本番：Release に入らない。

### H14 初めて起動した端末
- 目的：通知やカメラなどの許可は API でも simctl でも完全には戻せないので、端末ごと消してから起動する。
- 使う AC：AC-1。
- 動かし方：アプリの口ではない。
  - テストだけの端末を作り、`xcrun simctl erase <端末>` をしてから、その組のテスト（例 `FirstLaunchTests`）だけを `-only-testing` で動かす。
  - ほかのテストと同じ実行に混ぜない。
- 入力：消した端末。H1 と H2 は付けない。
- 出力：springboard の alert の数と、アプリが出した画面を XCUITest で見る。
- 失敗：消せないときは、その実行を落とす。
- 本番：該当なし。

### H15 伏せた向きを起こす（テストの側）
- 目的：本物の向きの知らせの流れで、伏せる、起こすを起こす。
- 使う AC：AC-44〜AC-49、AC-51、AC-54、AC-59。
- 動かし方：テストの側だけ。`XCUIDevice.shared.orientation = .faceDown`、`.portrait`、`.faceUp`。
  - 向きは次のテストに残るので、各テストの setUp で `.portrait` に戻す（flip-research の spike）。
- 入力と出力：向き。アプリの側の口はない。
- 失敗：該当なし。
- 本番：該当なし（テストのコードだけ）。

### H16 伏せの待ちの時計
- 目的：伏せが1.0秒続いたかを、sleep なしで決める。
- 使う AC：AC-44〜AC-49、AC-51、AC-54、AC-59。
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
- 使う AC：AC-3、AC-39、AC-40、AC-44〜AC-49、AC-51、AC-54、AC-59、AC-96、AC-114、AC-116、AC-118、AC-124、AC-130、AC-131。
- 動かし方：要素 `hook.state` の値を読む。全部の起動で効く。
- 入力：なし。
- 出力：contracts/hooks/h17-state.schema.json（値の書き方と読み方）。
  | キー | 値 |
  |---|---|
  | `flipMonitoring` | `on` か `off` |
  | `proximity` | `true` か `false` |
  | `startedBy` | `flip`、`button`、`intent`、`none` |
  | `haptic` | 回数 |
  | `announce` | `<文言キー>:<回数>` を `,` で並べる。例 `session.flipStarted.announcement:1` |
  | `notice` | `<文言キー>:<回数>`。置き方の案内は `widgetGuide`（AC-96） |
  | `entry` | このプロセスで最後に残った記録の入口の印（`app`、`lock_widget`、`small_widget`、`live_activity`、`intent_start`、`intent_open`、`none`）。全部の記録の印は H13 |
  | `sessionEntry` | 読書中の1件の入口の印（同じ enum） |
  | `entryCandidate` | メモリの入口の候補（`lock_widget`、`small_widget`、`live_activity`、`intent_start`、`intent_open`、`none`） |
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

### H19 写真・スクリーンショットの読み取り結果（OCR）の差し替え
- 目的：ページの本文（縦書きの列とノンブル）、表紙・背表紙、本棚（複数の背表紙）、奥付の読み取り結果を差し替え、カメラ撮影だけでなく `PhotosPicker`（`.screenshots` や写真選択）の操作も本物のピッカーなしで進められるようにする。結果を返すタイミングもテストから制御できる。
- 使う AC：AC-65〜AC-69、AC-94、AC-113、AC-137、AC-138、AC-142。
- 動かし方：全部の起動で効く。
  - 環境変数 `UITEST_OCR` に JSON（形は contracts/hooks/hook-config.schema.json の `$defs/h19OcrConfig`）を入れる。
  - `hold: true` のときは、撮影または画像選択のあと結果をすぐには返さず、テストが Darwin の通知 `yomuma.uitest.ocr.release`（1-4）を送った瞬間に結果を返す（AC-94 の待ち時間の間の操作を検証するため）。
  - カメラ撮影（`mark.photo`、`register.cover`、`register.bookshelf`、`colophon.capture`）およびスクリーンショット・写真選択（`mark.screenshot`、`register.screenshot`、`register.photo`）が押されたとき、本物のシステムカメラや PhotosPicker シートを出さず、注入された画像をメモリ上で作って処理へ進める。
- 入力：`$defs/h19OcrConfig`。
  - `page`：縦書きの列 `columns`（右から c1, c2, ...。空配列なら認識0件で `mark.ocr.none`）と `detectedPage`。
  - `cover`：表紙・背表紙の認識行 `lines`（`cover.ocr.line.1`, `2`, ...）。
  - `bookshelf`：本棚・平積みの背表紙行 `spines`（`bookshelf.row.1`, `2`, ...）。
  - `colophon`：奥付の認識行 `lines`（書名・著者・出版年・出版社・レーベル・ISBN 抽出用）。
- 出力：各画面の OCR 選択・確認 UI に結果が出る。一時画像データがファイルにも写真ライブラリにも残らないことは H27 で検証する。
- 失敗：JSON がスキーマに合わなければ `hook.error`（`H19:<場所>`）。
- 本番：Release に入らない。Release は本物のカメラ・PhotosPicker・Vision だけ。

### H20 端末内の書誌 SQLite DB（Background Assets）および共起テーブルの差し替え
- 目的：端末内の書誌 SQLite DB（Background Assets の `catalog.sqlite`、FTS5 `trigram` 索引つき）および共起テーブルの状態と中身を差し替える。外部への HTTP 通信は一切行わない。
  - 差し替えられる状態：(a) テスト用の書誌レコード（ISBN、書名、著者、NDL 生データの `dc:creator` / `rawCreator` / `author`、出版社、レーベル、出版年、シリーズ名・巻数、NDC）、(b) Background Assets 未取得状態 `notDownloaded`（AC-9）、(c) 共起テーブルの行（`fromISBN`、`toISBN`、`count`、`ndc`。AC-148）。
- 使う AC：AC-2〜AC-6、AC-9〜AC-11、AC-78〜AC-81、AC-87、AC-92、AC-103、AC-138、AC-140、AC-146〜AC-149。
- 動かし方：全部の起動で効く。
  - 環境変数 `UITEST_NDL_STUB` に JSON を入れる（設定ファイルの `ndlStub` に保存される）。
- 入力：contracts/hooks/h20-ndl-stub.schema.json。
  - `status`：`"ready"`（既定）または `"notDownloaded"`。
  - `books`：端末内の SQLite DB に投入する書誌の配列。`dc:creator` または `rawCreator` が指定された行は、アプリの NDL 著者名整形ロジック（役割語・生没年・カンマ・空白・2人目以降の除去。AC-92）を通して保存・表示される。
  - `cooccurrences`：共起テーブルの行（`fromISBN`、`toISBN`、`count`、`ndc`）。アプリは文学（`ndc` が `"9"` で始まる）かつ `count >= 10` の行だけを `rec.reason.readers` の候補に出す（AC-148）。
- 出力
  - `status: "ready"` のときは、インメモリまたはテスト用の一時 SQLite DB（本番と同じスキーマ・FTS5 `trigram` 索引）を構築して検索に応答する。
  - `status: "notDownloaded"` のときは、DB 未取得として `scan.dbNotReady` を返す（AC-9）。
  - どの状態でも外部への HTTP 通信は行わず、H29 の `requests` は 0 件になる（AC-103）。
- 失敗：JSON がスキーマに合わなければ `hook.error`（`H20:<場所>`）。
- 本番：Release に入らない。Release は Background Assets / バンドルの `catalog.sqlite` を読む。

### H21 バーコードの読み取りの差し替え
- 目的：読めたコードの並びを流す。1段目の ISBN（`978` / `979`）だけでなく、2段目の日本図書コード（`192` で始まる13桁の Cコード）も流せる。読み取りの画面を、本物のカメラなしで進める。
- 使う AC：AC-2、AC-3、AC-6、AC-9〜AC-11、AC-92、AC-103、AC-140、AC-149。
- 動かし方
  - 起動の引数 `-uitest-barcode-fake` で、読み取りの部品を差し替える。S-8a はカメラの代わりの面を出す（識別子 `scan.camera` は同じ）。
  - コードは Darwin の通知 `yomuma.uitest.barcode` で1つずつ流す（1-4）。
  - 全部の起動で効く。
- 入力：状態に13桁の数字を整数で書いてから知らせる。1回の知らせが1回の読み取り。
  - `978` / `979` で始まる13桁は ISBN として扱う。同じコードを2回流せば、重なりの読み取り（AC-3）になる。
  - `192` で始まる13桁（日本図書コード／Cコード）は単独の別の本としては追加せず、直前に読んだ ISBN の本（または同じ組の本）の判型・レーベル候補（5桁目：1＝文庫、2＝新書、0＝単行本）の補完に使う（AC-3、AC-11）。
  - `490` などの本でない JAN コードは無視する（AC-3）。
- 出力：アプリは本物の読み取りと同じ関数でコードを受ける（ISBN の確かめ、Cコード補完、重なり、端末内書誌 DB の検索）。
- 失敗：13桁でない値は、読めたコードとして流さず、無視する。
- 本番：Release に入らない。

### H22 ウィジェットの中身を読む
- 目的：ウィジェットの中身を、@testable import を使わずに外から読む（ADR 0003 の「H22 の口」）。
  - 読めるもの：ファミリーと枠を選んで組んだ結果、タイムラインの項目、縦書きの組み方の結果、進み具合の表示（`p.61`、`位置1450`、`52%`）、名無しの今の本の書名表示（`今の本` / `widget.currentBookAsTitle`）、読み上げのラベルとまとまりの数、押したときの URL、再読み込みの要求の回数、項目を返すまでの時間、見た目の id。
- 使う AC：AC-14、AC-16、AC-27〜AC-35、AC-37、AC-40、AC-62、AC-64、AC-73、AC-82、AC-97、AC-99、AC-102、AC-106、AC-111、AC-125、AC-139〜AC-141。
- 動かし方：全部の起動で効く。
  - 起動の引数 `-uitest-widget <ファミリー>:<幅>x<高さ>[,…]`（例 `accessoryRectangular:172x76,systemSmall:170x170`）。
  - 写しを差し替えて組む：環境変数 `UITEST_WIDGET_SNAPSHOT` に写しの文字列そのもの。`@missing` はファイルなし。壊れた写しの AC に使う。
  - スクリーンショット：起動の引数 `-uitest-widget-show <ファミリー>:<幅>x<高さ>`。つなぎ口だけの画面にウィジェットの View を1つ出し、要素 `hook.widget.canvas` を XCUITest で撮る。
- 入力：上の引数と環境変数。
- 出力：要素 `hook.widget` の値。contracts/hooks/h22-widget.schema.json。
  - 進み具合の文字列（`texts["widget.page"]` と `composition.page.text`）：紙の本（`page`）は `p.61`、電子書籍の位置番号（`location`）は `位置1450`（英語は `Loc 1450`）、パーセント（`percent`）は `52%`（AC-141）。
  - 名無しの今の本（`isTitlePending = true`、AC-139）：状態は書名のある本と同じ（一行があれば `normal`、一行がなく進み具合があれば `noLine`、どちらもなければ `noLineNoPage`）。一行がなければ `texts["widget.title"]` に文言キー `widget.currentBookAsTitle` の文（「今の本」／英語 "Reading Now"）が入り、読み上げのラベルの書名の所も同じ文になる。
- 失敗：ファミリーか枠が読めなければ `hook.error`（`H22:<値>`）。
- 本番：Release に入らない。拡張には何も足さない。

### H23 Live Activity の要求の記録と差し替え
- 目的：Live Activity（夜の入口の予約と、読書中の表示）の初期状態・利用可否（`areActivitiesEnabled`）・要求失敗を差し替え、アプリが出した要求（予約・取り消し・すぐ始める・更新・終わり）とその「出どころ」（`launchReconcile` / `foregroundReconcile` / `intent` / `app`）、中身、押したときの URL、`liveActivity.end` ボタンの読み上げラベルを外から読む。
- 使う AC：AC-34、AC-36〜AC-41、AC-97、AC-98、AC-114〜AC-120、AC-125、AC-130〜AC-132、AC-136、AC-139、AC-144。
- 動かし方：全部の起動で効く。
  - 環境変数 `UITEST_LIVE_ACTIVITY` に JSON（形は contracts/hooks/hook-config.schema.json の `$defs/h23LiveActivityConfig`）を入れる。
  - 動いている途中で状態を変える：Darwin の通知 `yomuma.uitest.liveactivity.transition`（1-4）。状態 `1` で予約中の Live Activity を始まった状態（`started`）にし（AC-41、AC-98、AC-115(3)）、状態 `2` で進行中の Live Activity をシステムが8時間で終えた状態（`dismissedBySystem`）にする（AC-136）。
  - 読み出し：要素 `hook.liveActivity` の値（JSON、形は `$defs/h23LiveActivityReadout`）を読む。
- 出力
  - `activities`：現在存在している Live Activity の一覧。
  - `requests`：このプロセスでアプリが出した要求の履歴。各要求の `source` により、起動時／前面復帰時の見直し（`launchReconcile` / `foregroundReconcile`）と、インテント（`intent`）や画面操作（`app`）による要求を時刻の区間に頼らず区別できる（AC-115、AC-119、AC-130）。
  - `reading` 状態の項目には `endButtonIdentifier: "liveActivity.end"`、`endButtonLabel`（文言キー `liveActivity.end.label` の文）、`endIntentName: "EndReadingIntent"` が記録される（AC-114）。
- 失敗：JSON がスキーマに合わなければ `hook.error`（`H23:<場所>`）。
- 本番：Release に入らない。

### H24 共有シートに渡したものの記録（読み終えカード検査）
- 目的：読み終えた画面で `finish.card.share` を押したときに共有シート（UIActivityViewController / ShareLink）に渡された PNG 画像の形式・寸法・描画された文字列・禁止項目（一行、写真、ふりかえりの1行が含まれないこと）を外から読む。
- 使う AC：AC-84、AC-85、AC-103、AC-127。
- 動かし方：全部の起動で効く。
  - `finish.card.share` を押すと、つなぎ口が生成されたカード画像とメタデータを記録する。
  - 読み出し：要素 `hook.shareCard` の値（JSON、形は contracts/hooks/hook-config.schema.json の `$defs/h24ShareCardReadout`）を読む。
- 出力：`cards[]` に `format: "png"`、`widthPx`、`heightPx`、`renderedTexts`（書名、著者、何晩、合計分など）、`containsSavedLine: false`、`containsPhoto: false`、`containsReflection: false`。
- 失敗：該当なし。
- 本番：Release に入らない。

### H25 受賞の一覧の差し替えと読み出し
- 目的：テスト用の受賞作行への差し替えと、アプリに同梱された本番の受賞一覧（芥川龍之介賞・直木三十五賞・本屋大賞）の全行読み出し（AC-112）を行う。
- 使う AC：AC-17〜AC-21、AC-77〜AC-83、AC-87、AC-112、AC-146、AC-147。
- 動かし方：全部の起動で効く。
  - 差し替え：環境変数 `UITEST_AWARDS` に JSON（形は contracts/hooks/hook-config.schema.json の `$defs/h25AwardsConfig`）を入れる。省いたときは同梱の本番一覧（`mode: "bundled"`）を使う。
  - 読み出し：要素 `hook.awards` の値（JSON、形は `$defs/h25AwardsReadout`）を読む（AC-112）。
- 失敗：JSON がスキーマに合わなければ `hook.error`（`H25:<場所>`）。
- 本番：Release に入らない。

### H26 カメラの許可の状態の差し替え
- 目的：カメラの許可の状態を、未決定、許可、拒否、制限、読めない端末にする。
- 使う AC：AC-1〜AC-3、AC-6、AC-9〜AC-12、AC-65〜AC-70、AC-92、AC-94、AC-103、AC-113、AC-137、AC-138、AC-140、AC-142。
- 動かし方：起動の引数 `-uitest-camera <状態>[:<求めたときの答え>]`。全部の起動で効く。
  - 例 `-uitest-camera notDetermined:granted`。
- 入力
  - 状態：`notDetermined`、`authorized`、`denied`、`restricted`、`unsupported`。
  - 答え：`granted` か `denied`。未決定で、アプリが許可を求めたときの結果。省くと granted。
- 出力
  - アプリの許可の部品は、AVCaptureDevice の代わりにこの値を返す。本物の許可のダイアログは出ない。
  - 拒否のときは、バーコード・表紙撮影（AC-12）でもしおり撮影（AC-70）でも `camera.denied` とスクリーンショット選択導線（`register.screenshot` / `mark.screenshot`）が出る。
- 失敗：知らない値は `hook.error`（`H26:<値>`）。
- 本番：Release に入らない。

### H27 画像のファイルの数と写真ライブラリへの書き込みの回数
- 目的：しおり撮影（`mark.photo`）、スクリーンショット選択（`mark.screenshot`、`register.screenshot`）、表紙撮影（`register.cover`）、本棚撮影（`register.bookshelf`）、奥付撮影（`colophon.capture`）のすべてで、アプリの保存領域（Documents、Library、tmp）と App Group の画像ファイル（jpg、jpeg、heic、png）が 0 個であり、写真ライブラリへの書き込みが 0 回であることを外から読む。
- 使う AC：AC-69、AC-113、AC-137、AC-138、AC-142。
- 動かし方：要素 `hook.mediaAudit` の値（JSON、形は contracts/hooks/hook-config.schema.json の `$defs/h27MediaAuditReadout`）を読む。全部の起動で効く。
- 入力：なし。
- 出力：`savedImageFileCount`（0 であること）、`savedImagePaths`（`[]` であること）、`photoLibraryWriteCount`（0 であること）。
- 失敗：該当なし。
- 本番：Release に入らない。

### H28 入口の URL で起動する
- 目的：ロック画面のウィジェット、小のウィジェット、Live Activity から開いたのと同じ URL で、アプリを起こす。
- 使う AC：AC-40、AC-62。
- 動かし方：テストの側だけ（contracts/entry-urls.md の 6 の (a)）。
  - プロセスのない起動は、`app.terminate()` のあとに `app.open(URL(string: "yomuma://open?entry=lock_widget")!)`（または `small_widget`、`live_activity`）。
- 入力：contracts/entry-urls.md の 1 の URL。
- 出力：アプリの onOpenURL が受ける。入口の候補は hook.state の `entryCandidate`、残った印は H13 か hook.state の `entry` で読む。
- 失敗：届かなければ、`entryCandidate` が none のまま。テストは落ちる。
- 本番：アプリの口は足さない。スキームの登録は Release にも入る（entry-urls.md の 1）。

### H29 アプリが出した外部 HTTP 通信の要求の記録（0件の検証）
- 目的：アプリ本体が出そうとしたすべての外部 HTTP/HTTPS 通信の要求を記録し、どのホストに対しても要求が 0 件（`requests` が空配列 `[]`）であることを検証する。
- 使う AC：AC-2、AC-6、AC-9、AC-10、AC-103。
- 動かし方：要素 `hook.outbound` の `requests` を読む。全部の起動で効く。
- 入力：なし。
- 出力：contracts/hooks/h29-outbound.schema.json。
  - 書誌 DB も端末内 SQLite DB（H20）で完結するため、登録・しおり・読書・読了カード共有のどの操作を通しても `requests` は常に `[]`（0件）になる（AC-103）。
- 記録できないもの：URLProtocol 等を通らない低レベル通信。G2 で reviewer が `grep -rnE 'URLSession|NWConnection|CFStream|WKWebView|URLRequest' ios/` で補う（PRD AC-103 の確かめ方）。
- 失敗：該当なし（記録だけ）。
- 本番：Release に入らない。

### H30 StoreKit 2 の差し替え
- 目的：買い切り課金「よむま＋」の商品情報取得、購入（成功・取りやめ・失敗）、購入の復元（あり・なし）、決済不可端末（`canMakePayments == false`）、および返金（entitlement 取り消し）を差し替える。
- 使う AC：AC-104〜AC-111。
- 動かし方：全部の起動で効く。
  - 環境変数 `UITEST_STOREKIT` に JSON（形は contracts/hooks/hook-config.schema.json の `$defs/h30StoreKitConfig`）を入れる。
  - 動いている途中で返金を起こす：Darwin の通知 `yomuma.uitest.storekit.refund`（1-4、状態 `1`）を送る（AC-111）。アプリを後ろにしてから前に戻すと、購入状態が「買っていない」に戻り、設定とウィジェットの見た目の id が `default` に戻る。
  - 読み出し：要素 `hook.storekit` の値（JSON、形は `$defs/h30StoreKitReadout`）および H13 の `settings.isPlusPurchased`、`settings.appearanceID` を読む。
- 失敗：JSON がスキーマに合わなければ `hook.error`（`H30:<場所>`）。
- 本番：Release に入らない。Release は本物の StoreKit 2 だけ。

### H31 アプリが開いた外部 URL の記録
- 目的：アプリが開こうとした外の URL（プライバシーポリシー AC-88、設定の「データの出典」から開く CC BY 4.0 ライセンス URL `https://creativecommons.org/licenses/by/4.0/` AC-93）を記録する。
- 使う AC：AC-88、AC-93。
- 動かし方：全部の起動で効く。
  - 要素 `hook.outbound` の `openedURLs` を読む。
  - 既定では、記録だけして本当には開かない（アプリが前面に残り、次の操作を続けられる）。
  - 本当に開くときは、起動の引数 `-uitest-openurl passthrough`。
- 入力：なし。
- 出力：contracts/hooks/h29-outbound.schema.json の `openedURLs`。
- 失敗：該当なし。
- 本番：Release に入らない。

### H32 アプリの外からのインテント（App Intents）を動かす
- 目的：アプリの外からのインテント（「読み始める」`StartReadingIntent`、Live Activity の「終える」`EndReadingIntent`、「どこまで読んだ？」`WhereStoppedIntent`、「続きを読む」`ContinueReadingIntent`）をテストから駆動し、返り値（前に出すか、認証ポリシー、声の文言キーと全文、小窓の文字列）および登録された App Shortcuts 3種と Control 1種を外から読む。
- 使う AC：AC-114〜AC-126、AC-131〜AC-135、AC-143、AC-144。
- 動かし方：全部の起動で効く。
  - 設定：環境変数 `UITEST_INTENT` に JSON（形は contracts/hooks/hook-config.schema.json の `$defs/h32IntentsConfig`、`canContinueInForeground` など）を入れる。
  - 起動と同時にインテントを動かす（プロセスのない状態からの実行を検証するとき）：起動の引数 `-uitest-run-intent <StartReadingIntent|EndReadingIntent|WhereStoppedIntent|ContinueReadingIntent>`。
  - 動いている途中でインテントを動かす：Darwin の通知 `yomuma.uitest.intent.run`（1-4。1＝`StartReadingIntent`、2＝`EndReadingIntent`、3＝`WhereStoppedIntent`、4＝`ContinueReadingIntent`）。
  - 読み出し：要素 `hook.intents` の値（JSON、形は `$defs/h32IntentsReadout`）を読む。
- 出力
  - `invocations`：実行したインテントごとの `intent`、`authenticationPolicy`（`WhereStoppedIntent` は `alwaysAllowed`）、`opensApp`、`requestedForeground`、`outcome`、`dialogKey`、`spokenText`（`WhereStoppedIntent` ではページ・位置番号・％に応じた文の型で、一行・書名・アプリ名を含まない。AC-121、AC-143）、`snippetTexts`（小窓の文字列。`hideOnWidgets` がオンまたはエラーのときは一行と書名を含まない。AC-123、AC-133）。
  - `registeredShortcuts`：登録された3つの App Shortcuts の `intent`、`phrases`（`${applicationName}` を含み、直後に「で」が続かないこと）、`systemImageName`（AC-126）。
  - `registeredControls`：登録された1つの Control の `kind: "button"`、`intent: "StartReadingIntent"`、`labelKey: "control.startReading"`（AC-126）。
- 失敗：知らないインテント名やスキーマ違反は `hook.error`（`H32:<値>`）。
- 本番：Release に入らない。

## 3. テストが読む識別子と属性（つなぎ口に関わる分）
- 識別子は design/ 6 を正とする。この契約で足すのは `hook.*` だけで、画面の要素には足さない。
- H9 と H17 の値を載せる要素は `hook.state`（1-5）。画面ごとの根の要素には載せない。
- 見える文字と読み上げが違う要素は、`label` の属性（XCUIElement.label。VoiceOver のラベル）で読む。`value` は空のことがある。
  | 要素 | 読む属性 | 比べる値 |
  |---|---|---|
  | `bookmark.page` | label | 紙の本は「61ページ」、電子書籍は「位置1450」「52パーセント」などの形（design/ 6。AC-141） |
  | `result.summary` | label | 「43ページから61ページ、18分」「位置1200から位置1450、18分」「34パーセントから52パーセント、18分」などの形（AC-76、AC-141） |
  | `book.record.row.<記録の id>` | label | 「10月17日の晩、10分」の形 |
  | `colophon.title`、`colophon.author`、`colophon.publisher`、`colophon.year` | label | 「名前、値」（例「出版社、新潮社、新潮文庫」） |
- `widget.line`、`widget.title`、`widget.page` は読み上げから隠すので、XCUITest でなく H22 の `texts` で読む。

## 4. 欠番のつなぎ口
- H3：読書中の状態の投入は H2 の `activeSession` に統合したため欠番。
- H11：外部への計測送信は v1.0 で行わない（裁定 10、AC-103）ため欠番。
- これ以外の H1〜H32（計30個）はすべて第2章のとおり v1.0 の標準仕様に含まれる。

## 5. 前の案から変えた所
| つなぎ口 | 前の案 | この契約（2026-10-25 更新） | 理由 |
|---|---|---|---|
| H2 | 本の基本項目と設定のみ | `isEbook`、`isTitlePending`、`progressUnit`（`page`/`location`/`percent`）、シリーズ名・巻数、NDC、推薦理由ごとの `chosen`/`skipped` を追加 | AC-101、AC-139〜AC-148 |
| H10 | 3区間（`endToMark`、`shelfOpen`、`bookOpen`） | 8区間（`markWait`、`intentStartRequest`、`intentStartForeground`、`barcodeLookup`、`titleSearch` を追加） | AC-94、AC-114、AC-115、AC-149 |
| H13 | 本・記録・設定の基本読み出し | `isTitlePending`、`isEbook`、`progressUnit`、進み具合の値、推薦重み `chosen`/`skipped` を追加 | AC-139〜AC-141、AC-145〜AC-147 |
| H17 | 入口の印3種 | `entry` / `sessionEntry` / `entryCandidate` に `live_activity`、`intent_start`、`intent_open` を追加 | AC-40、AC-114、AC-124 |
| H19 | 選択肢（ページ縦書き列のみ） | v1.0 標準に昇格。ページに加え表紙（`cover`）・本棚（`bookshelf`）・奥付（`colophon`）と PhotosPicker スクリーンショット選択に対応 | AC-113、AC-137、AC-138、AC-142 |
| H20 | 外部 NDL OpenSearch API スタブ | 端末内の書誌 SQLite DB（Background Assets、`status: ready / notDownloaded`、`books`）および共起テーブル（`cooccurrences`）の差し替えに変更。`$id` とファイル名は維持 | 2026-10-25 Takuma 決定、ADR 0004、AC-2〜AC-11、AC-87、AC-92、AC-103、AC-148、AC-149 |
| H21 | ISBN-13 のみ | 2段目の日本図書コード（`192` で始まる13桁 Cコード）の連続注入に対応 | AC-3、AC-11、AC-149 |
| H22 | 紙の本のページ（`p.61`）のみ | 電子書籍の `位置1450`・`52%`、および名無しの今の本の `今の本`（`widget.currentBookAsTitle`）を追加 | AC-139〜AC-141 |
| H23 | 選択肢 | v1.0 標準に昇格。要求の「出どころ」（`launchReconcile` / `foregroundReconcile` / `intent` / `app`）と `liveActivity.end` の読み上げラベル記録を追加 | AC-34、AC-36〜AC-41、AC-97、AC-98、AC-114〜AC-120、AC-130〜AC-132、AC-136、AC-139、AC-144 |
| H24、H25、H27、H30、H32 | 選択肢（第4章に名前だけ） | すべて v1.0 標準に昇格し、第2章と `hook-config.schema.json` に定義 | 全149 AC の標準化 |
| H29 | 書誌 API 以外の通信記録 | アプリが出したすべての外部 HTTP 通信要求が 0 件（ホスト問わず 0 件）であることの検証用に変更 | AC-2、AC-6、AC-9、AC-10、AC-103 |
| H31 | プライバシーポリシー URL のみ | 設定の「データの出典」から開く CC BY 4.0 ライセンス URL を追加 | AC-88、AC-93 |

## 6. 確かめたこと
- spike 1（2026-10-20、Xcode 27.1、iOS 27.0 のシミュレーター iPhone 17。リポジトリの外で作り、端末は最後に消した）
  - `import notify` は、アプリと UI テストの両方で module として読めた。
  - テストが `notify_set_state` で書いた 4242 を、アプリが `notify_get_state` で読めた。
  - ホーム画面に移したあとに書いた 999 も、`activate()` のあとに読めた。
  - `app.terminate()` のあとの `app.open(URL(string: "yomuma://open?entry=lock_widget")!)` では、springboard の確認は出ず、onOpenURL に URL が届き、起動の引数と環境変数も渡った。
- spike 2（同じ環境）
  - alert の1つ上の高さの UIWindow（触る操作を受けない）に、1×1 pt の要素を置いた。
  - 要素の種類は other で、isHittable は偽。押せる要素の数を変えず、シートと alert の間も `hook.*` の値を読めた。
- JSON Schema（2026-10-25 更新）：`contracts/hooks/*.schema.json` の7つと `contracts/widget-snapshot.schema.json` の計8ファイルを `jsonschema` の Draft 2020-12 で検証し、全スキーマと全 examples がエラー0で通ることを確認した。

## 7. 照合のしかた（G2 で verifier と reviewer が使う）
- 全149 AC が使うつなぎ口（H1、H2、H4〜H10、H12〜H32 の計30個）が、すべてこの契約の第2章にあること。
- JSON Schema：リポジトリ外の venv の `jsonschema` で `contracts/hooks/*.schema.json` と `contracts/widget-snapshot.schema.json` の metaschema 検査と examples 検査を行い、エラー0件であること。
- G2 の受け入れテストは、ここにない引数、環境変数、通知、`hook.*` の識別子を使わない（`grep -rhoE -- '-uitest-[a-z-]+|UITEST_[A-Z_]+|yomuma\.uitest\.[a-z.]+|hook\.[a-zA-Z.]+' ios/AcceptanceTests | sort -u` の結果が、この文書にあるものだけ）。
