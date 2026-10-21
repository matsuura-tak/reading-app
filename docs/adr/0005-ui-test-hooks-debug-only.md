# ADR 0005：テストのつなぎ口は Debug ビルドで -UITest のときだけ働き、Debug/ の2つのファイルの #if DEBUG に置く

- 状態：提案
- 書いた役：tech-lead　日付：2026-10-21（同日、G1 reviewer r1 の重大1、要修正3、提案12 で改訂：ファイルを2つと決め、Release の確かめを ios_build に入れ、T22 と UITEST_LOCALE を足した）
- 関係する PRD、設計メモ、契約：docs/prd/001-reading-session.md（12 の「テストのつなぎ口」、AC の確かめ方の T1〜T22）、contracts/test-hooks.md、contracts/seed.schema.json、contracts/telemetry.md、contracts/README.md の4、CLAUDE.md の ios_build、ADR 0003、ADR 0004
- 元に戻す手間：小（2つのファイルと組み立ての場所だけ）

## 背景
- 受け入れテストは、時計の差し替え、決まったデータの投入、保存の失敗、計測の送り先の差し替えが要る（G0 verifier の T1〜T20）。sleep は使わない（PRD 11 の前書き）。
- PRD 12：テストのつなぎ口は Release ビルドで働かない。作り方は tech-lead が G1 で決め、reviewer が G2 で確かめる。
- XCUITest はアプリを別のプロセスとして起動する。渡せるのは起動の引数と環境変数（A22）、起動した後は URL を開くこと（A23、A55）。アプリは ProcessInfo の environment（A105）で受け取り、URL は onOpenURL（A16）で受け取る。アプリから XCUITest へ返せるのは、画面の要素（識別子、label、value）と、localhost の HTTP（T6。届くかは未確認）。

## 決定
- つなぎ口は、起動の引数に `-UITest` があるときだけ読む。名前は `UITEST_` で始まる環境変数（一覧と型は contracts/test-hooks.md）と、URL scheme `readingapp-uitest://`（時計の操作）。
- つなぎ口のコードは ios/Yomutoki/Debug/ の次の2つのファイルだけに置き、どちらもファイル全体を `#if DEBUG` で囲む。名前はこの2つに決める（案ではない）。アプリの組み立ての場所からの呼び出しも `#if DEBUG` の中に置く。
  - UITestHooks.swift：UITEST_ の環境変数と readingapp-uitest:// を読み、時計、暦、Locale（UITEST_LOCALE）、保存の失敗、送り先を差し替える。-UITest のときだけの 1pt の要素（`uitest.clock.applied`、`uitest.telemetry.log`）を出す。
  - HTTPTelemetrySink.swift：受け口へ POST する送り先（contracts/telemetry.md の「テストの受け口」）と、TelemetrySink に渡されたイベントを順に覚える包み（T22）。
- URL scheme は Debug の Info.plist（ios/Yomutoki/Info-Debug.plist。ADR 0004）にだけ書く（CFBundleURLTypes。A104）。
- -UITest のときに、知らない `UITEST_` の名前、形の合わない値、契約に合わない UITEST_SEED があれば、黙って無視せずにその場で止める（fatalError に名前と理由を書く）。テストの書き間違いを早く見つけるため。
- CI で次を確かめる。どれも CLAUDE.md の ios_build（app.json の commands.ios_build）に入れ、満たさなければ終了コードが0でなくなる（説明は contracts/README.md の4）：
  - `UITEST_` の文字を持つ Swift のファイルが、上の2ファイルと ios/AcceptanceTests/ の外に0件。
  - Release の実行ファイル（`-configuration Release` でビルドしたもの）の strings に `UITEST_`、`readingapp-uitest`、`-UITest`、`uitest.` が0件。
  - Release の Info.plist に CFBundleURLTypes がない（PlistBuddy の Print が失敗することを `!` で反転して確かめる）。
  - 確かめる先のファイルがないときに通ってしまわないよう、strings と PlistBuddy の前に `test -f` を置く。
- localhost の受け口に届かないと CI で分かったとき（裁定の追記2 の (9)）は、T22（送ったイベントを並べた要素 `uitest.telemetry.log` の accessibilityValue を XCUITest が読む）に替える。-AppleLocale が効かないと分かったとき（同 (7)）は、T4 の UITEST_LOCALE に替える。どちらも ios-engineer が最初から作っておき、verifier が CI の結果で切り替える（契約の名前と形は contracts/test-hooks.md の T4 と T22）。
- 追記（2026-10-21、G2 の code reviewer r1 の要修正1。上の文は変えず、例外を足す）：
  - 例外1（呼び出しの場所）：design 6 の (a) の代わりの案（session.state.* の 1pt の要素 UITestMarker。contracts/test-hooks.md の T8）は、Debug/ の2つのファイルの中だけでは置けない。S5 はシートで表示の階層が別なので、根の UITestOverlay だけでは S5 の上に置けない。根の画面の要素も、同じ画面の識別子と同じ状態の名前（RootView の stateName）を使うため RootView に置く。そのため ios/Yomutoki/Screens/RootView.swift（根の画面）と ios/Yomutoki/Screens/FinishSessionView.swift（S5 のシート）の2か所から、`#if DEBUG` の中で UITestMarker を呼ぶことを許す。UITestMarker の定義は Debug/UITestHooks.swift のまま。
  - 例外2（引数）：引数 showsStateMarker（Bool。既定は false。true を渡すのは組み立ての場所 YomutokiApp の `#if DEBUG` の中だけ）が、Release のコードの RootView、ReadingView、FinishSessionView を通ることを許す。1pt の要素を置くかどうかだけを決める表示の要素で、本番の答え（保存、時計、計測、画面の流れ）を変える分岐ではないため。
  - 対象外：各 Screens の #Preview と ios/Yomutoki/Screens/PreviewSupport.swift の `#if DEBUG` は Xcode のプレビューのためで、テストのつなぎ口ではない（UITEST_ の名前、readingapp-uitest://、uitest. の要素を持たない）。この ADR の対象にしない。
  - 確かめ方は変えない（上の CI の3つ：UITEST_ を持つ Swift のファイルが2ファイルと ios/AcceptanceTests/ の外に0件、Release の strings に UITEST_、readingapp-uitest、-UITest、uitest. が0件、Release の Info.plist に CFBundleURLTypes がない）。
  - 下の「いちばん強い反論」の「#if DEBUG の中は2ファイルに限る」は、この例外の2か所と #Preview を加えて読む。G2 の reviewer は Debug/ の2ファイルの差分に加え、`grep -rnE 'UITestMarker|showsStateMarker' ios/Yomutoki --include='*.swift' | grep -v '/Debug/'` の行が、組み立ての場所 App/YomutokiApp.swift の `#if DEBUG` の中の1行（true を渡す所）と、RootView.swift、ReadingView.swift、FinishSessionView.swift の中だけで、UITestMarker の呼び出しが `#if DEBUG` の中の2件だけかを見る（2026-10-21 の HEAD で、この形の16行を確かめた）。

## 検討した案
| 案 | 良い点 | 悪い点 | 選ばなかった理由 |
|---|---|---|---|
| A：-UITest と UITEST_* を、Debug/ の2ファイルの #if DEBUG で読む（選んだ） | Release にコードが入らない。CI の strings で機械的に確かめられる。標準の仕組み（launchEnvironment と onOpenURL）だけ | 受け入れテストは Debug ビルドで走るので、Release の最適化の下の動きは G4 の実機で人が見る | － |
| B：テスト用の3つ目のビルド構成（UITest）を作る | Debug の開発の動きとテストの動きを分けられる | 構成が3つになり、XcodeGen の設定、署名、CI の行列が増える | 001 の規模に対して重い |
| C：#if を使わず、実行時に -UITest を見るだけ | 1つのビルドで済む | つなぎ口のコードと URL scheme が Release に入る。利用者が引数を渡せないとしても、審査とセキュリティの説明が要る | PRD 12「Release ビルドで働かない」を、コードがないことで示せない |
| D：テストのバンドルからアプリに注入する（ホストのある単体テストの形） | 起動の引数が要らない | XCUITest は別のプロセスなので、受け入れテストからは使えない | 受け入れテスト（UI テスト）に使えない |
| E：つなぎ口を1ファイルにまとめる（前の版） | 置き場所が1つ | 送り先（URLSession の HTTP）と、時計や保存の差し替えが1ファイルに混ざり長くなる。telemetry.md と図は既に送り先を別の部品にしていた（G1 reviewer r1 の提案12） | 2ファイルの方が部品の分け方と合う。数は CI の grep で固定できる |

## いちばん強い反論と、それでも選んだ理由
- 反論：受け入れテストが Debug ビルドで通っても、利用者が使う Release ビルドで同じ動きになる保証はない（最適化、#if DEBUG の中にうっかり入った本番のコード）。テストのための差し替え（時計、保存の失敗）が、本物の時計と本物の保存の道を通らないので、そこの不具合を見逃す。
- それでも選んだ理由：差し替えるのは境目（時計、暦と Locale、保存の層の入口の失敗、送り先）だけで、画面と保存の層の本体は同じコードを通る。#if DEBUG の中は2ファイルに限るので、本番のコードが紛れたら reviewer が G2 でその2ファイルの差分で見つけられる。Release の動きは G4 で Takuma が実機の確認リストで見る（docs/org/gates.md の G4。7日間も TestFlight の Release ビルドで使う。ADR 0004）。

## 結果
- これで楽になること：つなぎ口がどこにあるか、Release に入っていないかを、grep と strings で数えられ、CI が落とす。
- これで難しくなること、守り続けること：つなぎ口を足すときは contracts/test-hooks.md に行を足してから実装する（契約にない名前は contracts/README.md の3の名前のずれの確かめで見つける）。Release の確かめは macOS の CI でしか動かない。ios_build が Debug と Release の2回のビルドを含むので、CI の時間が延びる（設計メモの 11 の申し送り）。
- 元に戻すときの手順と手間：2つのファイルと組み立ての場所を消すか、案 B の構成に移す。手間は小。

## 見直す条件
- Release の実行ファイルの確かめで、つなぎ口の文字が1件でも出た（そのとき案 B を考える）。
- XCUIApplication.open で確認のダイアログが出て、URL scheme が使えないと CI の出力で分かった（そのとき contracts/test-hooks.md の T16 の代わりの案に替える）。
- 環境変数の長さの上限で UITEST_SEED が渡せないと分かった（そのとき T2 の代わりの案に替える）。
- localhost の受け口に届かない、または -AppleLocale が効かないと CI の出力で分かった（そのとき T22、UITEST_LOCALE に替える。上の決定）。
- 受け入れテストを Release ビルドで走らせる必要が出た。
- 追記（2026-10-21）：決定の例外の2か所（RootView.swift、FinishSessionView.swift）の `#if DEBUG` に、1pt の要素の外のもの（本番の答えを変える分岐、UITEST_ の名前）が入った（そのとき Debug/ に移すか、この ADR を開き直す）。

## 確かめたこと
- A22 XCUIApplication（launchArguments、launchEnvironment）https://developer.apple.com/documentation/xcuiautomation/xcuiapplication
- A23 と A55 XCUIApplication.open(_:) iOS 16.4+。本文「Launches the application by URL.」https://developer.apple.com/documentation/xcuiautomation/xcuiapplication/open(_:)
- A16 onOpenURL(perform:) iOS 14.0+ https://developer.apple.com/documentation/swiftui/view/onopenurl(perform:)
- A104 CFBundleURLTypes iOS 2.0 https://developer.apple.com/documentation/bundleresources/information-property-list/cfbundleurltypes （2026-10-21 に JSON を取得）
- A105 ProcessInfo.environment iOS 2.0。本文「The variable names (keys) and their values in the environment from which the process was launched.」https://developer.apple.com/documentation/foundation/processinfo/environment （2026-10-21 に JSON を取得）
- A64 accessibilityIdentifier(_:)。本文「Use this value for testing. It isn't visible to the user.」（識別子は Release に残してよい根拠）
- ios_build の `!` と `test -f` の組み合わせの動きは、この環境の sh で試した（ファイルがないときに落ちること、文字が出たときに落ちること。出力は設計メモの 4）。strings と PlistBuddy そのものは macOS でしか動かない。
- 未確認：環境変数の長さの上限。XCUIApplication.open で確認のダイアログが出るか。-AppleLocale の効き方。localhost に届くか。uitest.telemetry.log の accessibilityValue の長さの上限。Release のビルドの成果物のパス（`build/release/Build/Products/Release-iphonesimulator/Yomutoki.app`）と、strings と PlistBuddy の行が CI で動くこと（どれも G2 の CI の出力で確かめる。裁定の追記2 の (7)、(9)、(10)）。
- spike：Mac がないので、していない。

## 確かめ（B）
- [x] 案が2つ以上あり、どの案にも悪い点が書いてある
- [x] 反論、悪い結果、見直す条件が空でない
- [x] 確かめたことに、URL かコマンドの出力がある
