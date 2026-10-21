# ADR 0005：テストのつなぎ口は Debug ビルドで -UITest のときだけ働き、1つのファイルの #if DEBUG に置く

- 状態：提案
- 書いた役：tech-lead　日付：2026-10-21
- 関係する PRD、設計メモ、契約：docs/prd/001-reading-session.md（12 の「テストのつなぎ口」、AC の確かめ方の T1〜T20）、contracts/test-hooks.md、contracts/seed.schema.json、contracts/telemetry.md、ADR 0003、ADR 0004
- 元に戻す手間：小（1つのファイルと組み立ての場所だけ）

## 背景
- 受け入れテストは、時計の差し替え、決まったデータの投入、保存の失敗、計測の送り先の差し替えが要る（G0 verifier の T1〜T20）。sleep は使わない（PRD 11 の前書き）。
- PRD 12：テストのつなぎ口は Release ビルドで働かない。作り方は tech-lead が G1 で決め、reviewer が G2 で確かめる。
- XCUITest はアプリを別のプロセスとして起動する。渡せるのは起動の引数と環境変数（A22）、起動した後は URL を開くこと（A23、A55）。アプリは ProcessInfo の environment（A105）で受け取り、URL は onOpenURL（A16）で受け取る。

## 決定
- つなぎ口は、起動の引数に `-UITest` があるときだけ読む。名前は `UITEST_` で始まる環境変数（一覧と型は contracts/test-hooks.md）と、URL scheme `readingapp-uitest://`（時計の操作）。
- つなぎ口を読んで、時計、暦、保存の層、計測の送り先を差し替えるコードは、すべて ios/Yomutoki/Debug/UITestHooks.swift（案）の1ファイルに置き、ファイル全体を `#if DEBUG` で囲む。アプリの組み立ての場所からの呼び出しも `#if DEBUG` の中に置く。
- URL scheme は Debug の Info.plist（ios/Yomutoki/Info-Debug.plist。ADR 0004）にだけ書く（CFBundleURLTypes。A104）。
- -UITest のときに、知らない `UITEST_` の名前、形の合わない値、契約に合わない UITEST_SEED があれば、黙って無視せずにその場で止める（fatalError に名前と理由を書く）。テストの書き間違いを早く見つけるため。
- CI で次を確かめる（コマンドは contracts/README.md）：Release の実行ファイルに `UITEST_`、`readingapp-uitest`、`-UITest` の文字が0件。Release の Info.plist に CFBundleURLTypes がない。`UITEST_` の文字を持つ Swift のファイルが、上の1ファイルと受け入れテストのフォルダの外に0件。

## 検討した案
| 案 | 良い点 | 悪い点 | 選ばなかった理由 |
|---|---|---|---|
| A：-UITest と UITEST_* を、1ファイルの #if DEBUG で読む（選んだ） | Release にコードが入らない。CI の strings で機械的に確かめられる。標準の仕組み（launchEnvironment と onOpenURL）だけ | 受け入れテストは Debug ビルドで走るので、Release の最適化の下の動きは G4 の実機で人が見る | － |
| B：テスト用の3つ目のビルド構成（UITest）を作る | Debug の開発の動きとテストの動きを分けられる | 構成が3つになり、XcodeGen の設定、署名、CI の行列が増える | 001 の規模に対して重い |
| C：#if を使わず、実行時に -UITest を見るだけ | 1つのビルドで済む | つなぎ口のコードと URL scheme が Release に入る。利用者が引数を渡せないとしても、審査とセキュリティの説明が要る | PRD 12「Release ビルドで働かない」を、コードがないことで示せない |
| D：テストのバンドルからアプリに注入する（ホストのある単体テストの形） | 起動の引数が要らない | XCUITest は別のプロセスなので、受け入れテストからは使えない | 受け入れテスト（UI テスト）に使えない |

## いちばん強い反論と、それでも選んだ理由
- 反論：受け入れテストが Debug ビルドで通っても、利用者が使う Release ビルドで同じ動きになる保証はない（最適化、#if DEBUG の中にうっかり入った本番のコード）。テストのための差し替え（時計、保存の失敗）が、本物の時計と本物の保存の道を通らないので、そこの不具合を見逃す。
- それでも選んだ理由：差し替えるのは境目の4つ（時計、暦、保存の層の入口の失敗、送り先）だけで、画面と保存の層の本体は同じコードを通る。#if DEBUG の中は1ファイルに限るので、本番のコードが紛れたら reviewer が G2 でそのファイルの差分で見つけられる。Release の動きは G4 で Takuma が実機の確認リストで見る（docs/org/gates.md の G4）。

## 結果
- これで楽になること：つなぎ口がどこにあるか、Release に入っていないかを、grep と strings で数えられる。
- これで難しくなること、守り続けること：つなぎ口を足すときは contracts/test-hooks.md に行を足してから実装する（契約にない名前は CI の名前のずれの確かめで落ちる）。Release の確かめは macOS の CI でしか動かない。
- 元に戻すときの手順と手間：ファイル1つと組み立ての場所を消すか、案 B の構成に移す。手間は小。

## 見直す条件
- Release の実行ファイルの確かめで、つなぎ口の文字が1件でも出た（そのとき案 B を考える）。
- XCUIApplication.open で確認のダイアログが出て、URL scheme が使えないと CI の出力で分かった（そのとき contracts/test-hooks.md の T16 の代わりの案に替える）。
- 環境変数の長さの上限で UITEST_SEED が渡せないと分かった（そのとき T2 の代わりの案に替える）。
- 受け入れテストを Release ビルドで走らせる必要が出た。

## 確かめたこと
- A22 XCUIApplication（launchArguments、launchEnvironment）https://developer.apple.com/documentation/xcuiautomation/xcuiapplication
- A23 と A55 XCUIApplication.open(_:) iOS 16.4+。本文「Launches the application by URL.」https://developer.apple.com/documentation/xcuiautomation/xcuiapplication/open(_:)
- A16 onOpenURL(perform:) iOS 14.0+ https://developer.apple.com/documentation/swiftui/view/onopenurl(perform:)
- A104 CFBundleURLTypes iOS 2.0 https://developer.apple.com/documentation/bundleresources/information-property-list/cfbundleurltypes （2026-10-21 に JSON を取得）
- A105 ProcessInfo.environment iOS 2.0。本文「The variable names (keys) and their values in the environment from which the process was launched.」https://developer.apple.com/documentation/foundation/processinfo/environment （2026-10-21 に JSON を取得）
- A64 accessibilityIdentifier(_:)。本文「Use this value for testing. It isn't visible to the user.」（識別子は Release に残してよい根拠）
- 未確認：環境変数の長さの上限。XCUIApplication.open で確認のダイアログが出るか。-AppleLocale の効き方。Release の strings の確かめのコマンドが CI で動くこと（どれも G2 の CI の出力で確かめる）。
- spike：Mac がないので、していない。

## 確かめ（B）
- [x] 案が2つ以上あり、どの案にも悪い点が書いてある
- [x] 反論、悪い結果、見直す条件が空でない
- [x] 確かめたことに、URL かコマンドの出力がある
