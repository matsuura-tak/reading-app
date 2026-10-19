# ADR 0005：テストのつなぎ口は Debug と Perf の構成にだけ入れ、App Store の版に入れない（外からは起動の引数と Darwin の通知で動かし、つなぎ口の窓の要素で読む。H22 はアプリの中でウィジェットと同じ部品を描く）

- 状態：提案
- 書いた役：tech-lead　日付：2026-10-20（G1 の 7-4a）
- 関係する PRD、設計メモ、契約：docs/prd/001-reading-session.md（11 の冒頭の H1〜H32、12 の速さ、付記の G1-10）、docs/adr/features/001-reading-session.md（2、3、7）、contracts/test-hooks.md、contracts/hooks/、contracts/entry-urls.md、ADR 0001、0002、0003
- 元に戻す手間：中（アプリの差し替えの部品と、受け入れテストの書き方の両方を直す。データの移行はない）

## 背景
- G2 で verifier は、実装より先に受け入れテストを書く。芯の AC 85件は、23個のつなぎ口を使う（contracts/test-hooks.md）。
  - 時計、通信、保存の失敗、カメラ、書誌、ウィジェットの中身を差し替えたり読んだりできないと、テストは sleep と本物の通信に頼り、揺れる。
- 制約
  - App Store の版には、つなぎ口を入れない（G0 r1 の証拠の 4。G2 で reviewer が確かめる）。
  - UI テストは別のプロセスで動くので、アプリの関数を直接は呼べない。PRD の H22 は @testable import を使わないと決めている。
  - システムが起こしたプロセスには、起動の引数と環境変数が渡らない（G0 の intents の verifier の要修正3）。強制終了して開き直す AC も多い。
  - 速さの AC（AC-100〜AC-102）は Release の構成で測る（PRD 12）。測るのに H2 と H10 が要る。
  - G4-15 は、本500冊と記録5,000件を TestFlight か Release のビルドに入れて測る（G1-10）。
  - Swift 6、MainActor が既定、パッケージは3つまで（ADR 0001）。

## 決定
- つなぎ口は、アプリのターゲットの `UITestHooks/` の下だけに書き、コンパイルの条件 `UITEST_HOOKS` で包む。この条件を定めるのは Debug と Perf（Release と同じ最適化）の2つの構成だけで、Release（TestFlight、App Store）には入らない。
- テストは、起動の引数と環境変数（App Group の設定のファイルに写し、開き直しとシステムの起動でも効かせる）と Darwin の通知で動かし、つなぎ口の窓の accessibility の要素で読む。
- H22 は、アプリの中でウィジェットの拡張と同じ関数と View を使って組み、その結果を返す。

決めたことの中身
- 構成

  | 構成 | `UITEST_HOOKS` | 最適化 | 使う所 |
  |---|---|---|---|
  | Debug | あり | なし | 開発、G3 の画面とウィジェットのテスト |
  | Perf | あり | Release と同じ（-O、DEBUG なし） | AC-100〜AC-102 の測定、G4-15 の投入 |
  | Release | なし | -O | TestFlight、App Store、G4 |

  - Perf は Release を写して作り、`SWIFT_ACTIVE_COMPILATION_CONDITIONS` に `UITEST_HOOKS` だけを足す。バンドル ID、App Group、entitlements は Release と同じにする。
  - PRD 12 の「Release の構成で測る」は、G3 では Perf で測ると読む。G4-15 は本物の Release で測る。
- コードの置き場所
  - つなぎ口の型は `UITestHook` で始め、アプリのターゲットの `UITestHooks/` の下に置き、ファイルごと `#if UITEST_HOOKS` で包む。
  - `UITestHooks/` の外で `UITEST_HOOKS` を書いてよいのは、アプリの組み立ての1ファイル（App の struct）だけ。そこで差し替えの部品を入れる。
  - ローカルのパッケージ（ReadingCore、ReadingStore）とウィジェットの拡張には、つなぎ口を書かない。
    - パッケージは、次の5つを init の引数で受け取る：時計、通信の部品、保存の前の確かめ、再読み込みを頼む部品、外の URL を開く部品。
    - 本番は、本物の時計、URLSession、何もしない確かめ、WidgetCenter、openURL を既定で渡す。
  - 画面のコードには `#if UITEST_HOOKS` を書かない。数える所は、本番にもある1か所の部品を通す。
    - 数える所：触覚、読み上げ、知らせ、区間の時間（signpost と同じ所）、再読み込み、通信、開いた URL。
    - つなぎ口は、その部品を差し替えるか、その部品の記録を読む。
- 名前の決まり：引数 `-uitest-*`、環境変数 `UITEST_*`、通知 `yomuma.uitest.*`、要素 `hook.*`、型 `UITestHook*`（contracts/test-hooks.md の 1-2）。
- 動かし方と読み方：contracts/test-hooks.md の 1-3〜1-6。
- H22（ADR 0003 の「H22 の口」）
  - アプリの中で、拡張と同じ関数（写しを読む、タイムラインの項目を作る、組み）と同じ View で組む。
  - URL は描いた元のデータから返す。
  - まとまりの数は、VoiceOver と同じたどり方で数える。
  - 再読み込みは `reloadAllTimelines()` の呼び出しの回数で数える。
- H28：`XCUIApplication.open(_:)` を使う（spike 1）。アプリの口は足さない。
- G1-10（G4-15 の本500冊と記録5,000件）
  1. 実機に Perf のビルドを Xcode で入れ、`-uitest-seed-preset perf500 -uitest-readouts off` で1回起動して入れる。
  2. アプリを消さずに、同じバンドル ID の Release のビルドを上から入れる。開発の署名で Xcode から入れるか、TestFlight で入れる。
  3. 本棚に500冊があることを画面で確かめてから、Instruments の os_signpost（shelfOpen、bookOpen。Release にも残す）で測る。
  - TestFlight を上から入れても入れ物が残るかは［未確認］。残らなければ、開発の署名の Release のビルドで測る（G4-15 は「TestFlight か Release のビルド」）。

## 検討した案
| 案 | 良い点 | 悪い点 | 選ばなかった理由 |
|---|---|---|---|
| A コンパイルの条件で Debug と Perf だけに入れる。引数、通知、設定のファイルで動かし、窓の要素で読む（採用） | Release の2進のファイルに、つなぎ口のコードが入らない。テストは本番と同じアプリのターゲット（Info.plist、entitlements、URL の登録、App Group）を動かす。spike で、通知と読み出しと H28 が動いた | 構成が3つになる。テストが動かすビルドは Release と同じではない（最適化は Perf で合わせる）。名前の決まりを守り続ける | — |
| B つなぎ口をすべての構成に入れ、起動の引数があるときだけ動かす | ビルドが1つで済む。テストと App Store が同じ2進のファイル | App Store の版に差し替えのコードと文字列が入る。G0 r1 の「Release に入れない」に反する。審査で隠れた機能と見られうる［推測］ | 守る条件に反する |
| C テストだけの別のアプリのターゲットに、つなぎ口を入れる | Release のターゲットは作りからきれい | テストが、出すアプリと違うターゲット（Info.plist、entitlements、URL の登録、App Group）を動かす。2つのターゲットを同じに保ち続ける | 出すものと違うものを確かめることになる |
| D `#if DEBUG` だけにする（Perf を作らない） | いちばん簡単 | 速さの AC を、Release の最適化と H2、H10 で測れない | PRD 12 の測り方を満たせない |
| E 画面ごとの根の要素の accessibilityValue に状態を出す（G0 r1 の案） | 窓を足さない | すべての画面とシートに足す。alert の間に読めるかが分からない。画面の View の木を、つなぎ口のある構成でだけ変える | 案 A の窓で、シートと alert の間も読めた（spike 2） |
| F 動いている途中の操作を、テストだけの URL で送る | 通知の API が要らない | 入口の URL の受け口と混ざる。アプリが前面に出るので、後ろにいる間に時計を進められない | H5 の「後ろにいる間も進める」を満たせない |
| G H22 の代わりに、本物のウィジェットをホーム画面に置いて見る | 本物の描き方を見られる | 置く手順が揺れる（7-3 で2回止まった）。組みの結果と L を読めない | AC-28 と AC-99 を確かめられない。本物の見え方は G4-1、G4-3 で見る |

## いちばん強い反論と、それでも選んだ理由
- 反論
  - G3 は、Release と違うビルド（Debug か Perf）で、時計、通信、失敗、ウィジェットの描き方を差し替えて確かめる。だから G3 が通っても、出す版の本物の時計や WidgetKit の道で落ちうる。
  - さらに、つなぎ口のコード自体が大きく（差し替えの部品、窓、JSON）、それ自体に不具合がありうる。
- それでも選んだ理由
  - 差し替えるのは薄い継ぎ目だけ（時計の関数、通信の部品、保存の前の確かめ、再読み込みの部品）。業務の計算と View は、本番と同じコードを通る。
  - 差し替えで見えなくなる所は、ほかの関門が見る。
    - G4（Release の実機）：G4-1、G4-15、G4-18、G4-20。
    - G2（reviewer）：拡張と H22 が同じ関数を使うこと、URL を受ける処理から保存を呼ばないことを、ソースで見る。
  - Perf は Release と同じ最適化なので、速さの差は小さい見込み［推測。G4-15 で、同じ端末の Perf と Release を比べる］。
  - つなぎ口がなければ、時間、通信、ウィジェットの AC は sleep と本物の通信に頼り、揺れるか、確かめられない。

## 結果
- これで楽になること
  - verifier が、この契約だけを見て、実装の前に受け入れテストを書ける。
  - sleep と本物の通信のない、決まった結果のテストになる。
  - 開き直しと、システムが起こしたプロセスでも、同じ差し替えが効く。
- これで難しくなること、守り続けること
  - 構成を3つ保つ。Perf のバンドル ID と entitlements を Release と同じに保つ。
  - 名前の決まりと置き場所の決まりを、PR ごとに G2 で確かめる（下の手順）。
  - 機能を変えたら、契約（contracts/test-hooks.md と JSON Schema）とつなぎ口を一緒に直す。同じ大きな版の中では足すだけ。
- G2 で reviewer が確かめる手順（ios/ ができたら、PR ごと）
  1. 構成：`xcodebuild -showBuildSettings -configuration Release | grep SWIFT_ACTIVE_COMPILATION_CONDITIONS` に `UITEST_HOOKS` がない。Debug と Perf にはある。
  2. 置き場所：次の2つの grep で、出た所がすべて `#if UITEST_HOOKS` の中にあることを読む。
     - `grep -rlE 'UITestHook|-uitest-|UITEST_|yomuma\.uitest\.|"hook\.' ios/ --include='*.swift' | grep -v '/UITestHooks/'` の結果が、アプリの組み立ての1ファイルだけ。
     - `grep -rL '#if UITEST_HOOKS' $(find ios -path '*/UITestHooks/*.swift')` の結果が空（包んでいないファイルがない）。
  3. 2進のファイル：Release を `-sdk iphonesimulator` でビルドし、アプリと拡張の2進のファイルの両方で次を見る。
     - `nm -a <2進のファイル> | grep -c UITestHook` が 0。
     - `strings -a <2進のファイル> | grep -cE 'uitest|hook\.(state|store|widget|outbound|error)'` が 0。
  4. 確かめが空振りしていないこと：同じ 3 を Perf のビルドで動かすと 1 以上になる。
     - Swift は15バイトまでの文字列をコードの中に埋めるので、strings では短い文字列を見落とす。だから 1 と nm を主にし、strings は補いにする。
  5. App Store に出す archive にも、G4 の前に 3 を動かす。
- 元に戻すときの手順と手間
  - `UITestHooks/` と Perf の構成を消し、組み立ての1ファイルの差し替えを外す。
  - 受け入れテストのうち、つなぎ口を使うもの（ほぼ全部）を書き直す。手間は中。

## 見直す条件
- G2 の 3 で、Release の2進のファイルに `UITestHook` か `uitest` が1つでも見つかった。案 C（別のターゲット）を考え直す。
- Xcode の新しい版で、Darwin の通知の状態が UI テストからアプリに届かなくなった。新しい Xcode の大きな版ごとに spike 1 を動かし直し、届かなければ、開き直しで渡す形に替える。
- G3 のテストの揺れが、100回の実行で1%を超えた（つなぎ口が原因のもの）。
- G4-15 で、同じ端末の Perf と Release の区間の時間が10%を超えて違った。速さの AC を Release だけで測る形に替える。
- Apple が、時計かウィジェットの中身をテストから読む公式の仕組みを出した（AppIntentsTesting のような形）。H4、H5、H22 をそれに替えられるか見る。
- 選択肢 (5) か（ショートカット）を残すと決まった。H23 と H32 を、システムが起こしたプロセスで同じ形に足す（contracts/test-hooks.md の 4）。

## 確かめたこと
- spike 1（2026-10-20。Xcode 27.1（27A9275）、iOS 27.0 のシミュレーター iPhone 17。7-3 の spike のプロジェクトを scratchpad に写して使い、端末は自分の名前で作って最後に消した）
  - コマンド：`xcodebuild test -project Spike.xcodeproj -scheme SpikeApp -destination id=<端末> -only-testing:SpikeUITests/AXTests/testProbe`
  - 出力
    - `PROBE1=imp=module;args=[-uitest-probe A];env=1;notify=4242;rc=0;urls=`
    - `CONFIRM=none`
    - `STATE_AFTER_OPEN=true`
    - `PROBE2=imp=module;args=[-uitest-probe A];env=1;notify=4242;rc=0;urls=yomuma://open?entry=lock_widget`
    - `PROBE3=imp=module;args=[-uitest-probe A];env=1;notify=999;rc=0;urls=yomuma://open?entry=lock_widget`
    - `** TEST SUCCEEDED **`
  - 読み方
    - `import notify` は module として読めた。
    - UI テストの `notify_set_state` の値を、アプリが読めた。後ろにいる間に書いた値も読めた。
    - `app.terminate()` のあとの `app.open(_:)` では、確認が出ずに onOpenURL に届き、起動の引数と環境変数も渡った。
- spike 2（同じ環境。`-only-testing:SpikeUITests/AXTests/testHookWindow`）
  - 出力
    - `H_TYPE=1 other=1 hittable=false`
    - `H_MAIN=state=idle;reads=4`
    - `H_BUTTONS=1 H_OTHERS_WITH_HOOK=2`
    - `H_BIG_LEN=91500 ms=63`
    - `H_TAP_THROUGH=true`
    - `H_SHEET exists=true value=state=idle;reads=10`
    - `H_ALERT_SHOWN=true`
    - `H_ALERT exists=true value=state=idle;reads=13`
    - `** TEST SUCCEEDED **`
  - 読み方
    - alert の1つ上の窓の要素は other で押せず、ボタンの数を変えず、下の画面を押せた。
    - シートと alert の間も読めた。値は読むたびに作られた。
- JSON Schema：jsonschema 4.25.1（Draft 2020-12）で、contracts/hooks/ の7つの metaschema の検査と例の検査が通った。契約に合わない17通りは弾かれた（7-4a の報告に出力）。
- 文書（今回は開いていない。前の段の引用）
  - widgetURL はビューの木に1つ：https://developer.apple.com/documentation/swiftui/view/widgeturl(_:) （contracts/entry-urls.md の 6）
  - AppIntentsTesting は iOS 27.0 から（docs/reviews/001-reading-session-G0-intents-tech-lead-r2.md。選択肢の H32 で使う）
- 未確認
  - Perf の構成で、ローカルのパッケージが -O で組まれるか（Xcode が独自の構成名をパッケージのどの構成に当てるか）。ios/ を作る最初の PR で、ビルドのログの -O を見る。
  - G2 の 3 の nm で、Swift の型の名前が見えること。Perf のビルドで 1 以上になることを、最初の PR で見る。
  - TestFlight のビルドを、開発の署名のビルドの上から入れたときに、アプリの入れ物が残るか（G1-10 の 2）。
  - 画面の外の窓で、VoiceOver のまとまりの数を数えられるか（H22）。
  - 起動の環境変数の大きさの上限（H2 の 200,000 バイト）。
  - 実機で `XCUIApplication.open(_:)` が確認なしに届くか（G3 はシミュレーターだけで使う）。

## 確かめ（B）
- [x] 案が2つ以上あり、どの案にも悪い点が書いてある（A〜G の7つ）
- [x] 反論、悪い結果、見直す条件が空でない
- [x] 確かめたことに、URL かコマンドの出力がある（spike 1、spike 2 のコマンドと出力。URL は前の段の引用で、今回は開いていない）
