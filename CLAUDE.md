# アプリの地図

このファイルはこのアプリの地図です。tech-lead（テックリード）が手入れし、100行以内に保ちます。
アプリ名と一言の説明は .claude/org/app.json の app_name と idea にあります。
組織の決まりは .claude/rules/org.md、関門は docs/org/gates.md、進み具合は docs/progress.md を読みます。

## 概要
- 何のアプリか：読む時間そのものを美しく残す iPhone の読書アプリ「よむとき（Yomutoki: Reading Time）」。本を題名だけで足し、読んだ時間とページを残して、次は1回の操作で続きから読む。
- データは端末の中だけ（アカウントなし、サーバーなし、計測の SDK なし。ADR 0001、0003）。権限を1つも求めない。
- 使う人：紙の本か電子書籍を読み、読んだ時間と進んだページを手間なく残して、次は前回のページから読みたい人。主に日本（ja）、次に米国（en）の iPhone の利用者（docs/prd/001-reading-session.md の 2、18 の P-2）。
- いまの段階：001-reading-session の G1（設計）。ios/ はまだない。001 は内部の TestFlight まで（単独では App Store に出さない）。

## ビルド/テストのコマンド
.claude/org/app.json の commands と同じものを書きます。CI は app.json の方を使います。
コマンドを変えたら、app.json の更新を Takuma に頼みます（.claude/ は Takuma だけが直せます）。
受け入れテストは、受け入れテストのフォルダの中の設定だけで動く形にします。
どれもリポジトリの直下で、macOS（CI の macos-latest）と Xcode 26 で動かす1行です。Makefile の ios-build と ios-test も同じ1行です。
- iOS のビルド（commands.ios_build）：**未確認**（この環境は Linux で、brew、xcodegen、xcodebuild が動かない。最初の CI の出力で確かめる）
  `cd ios && (command -v xcodegen >/dev/null || brew install xcodegen) && xcodegen --version && xcodegen generate && xcodebuild -version && xcodebuild build -project Yomutoki.xcodeproj -scheme Yomutoki -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO`
- iOS のテスト（commands.ios_test）：**未確認**（同上）。単体テスト（ios/YomutokiTests/Unit.xctestplan）、受け入れテスト（ios/AcceptanceTests/Acceptance.xctestplan）、AC-18 の再起動の2段（ios/AcceptanceTests/ac18-reboot.sh）の順に動く
  `cd ios && (command -v xcodegen >/dev/null || brew install xcodegen) && xcodegen generate && xcrun simctl list devices available && xcodebuild test -project Yomutoki.xcodeproj -scheme Yomutoki -testPlan Unit -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO && xcodebuild test -project Yomutoki.xcodeproj -scheme Yomutoki -testPlan Acceptance -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO && bash AcceptanceTests/ac18-reboot.sh 'iPhone 16'`
- バックエンドのテスト：なし（001 にサーバーはない）
- 契約の検査（Linux で動く。動かした）：`make contracts-check`（JSON Schema と例。contracts/README.md の1）
- 文言の表の検査（AC-39。Linux で動く。ios/ ができてから）：`python3 -I contracts/tools/xcstrings_untranslated.py ios/Yomutoki/Resources/*.xcstrings`

決まり：
- 受け入れテストの判定の実行（G2 の red、G3）では `-retry-tests-on-failure` を付けない（落ちたテストを通ったことにしない）。
- シミュレーターの名前「iPhone 16」は暫定（macos-latest にあるかは未確認）。決め方：最初の CI の ios_test のログにある `xcrun simctl list devices available` の出力から、iOS 26 のランタイムの iPhone を1つ選ぶ。違う名前なら、ここと Makefile と app.json（Takuma）を同じ名前に直す。ビルドは名前の要らない generic の行き先にしてある。
- ios/AcceptanceTests/ の Acceptance.xctestplan と ac18-reboot.sh は verifier が書く。ないうちは ios_test が落ちる（docs/adr/features/001-reading-session.md の「雛形の作り方」）。
- 署名なし（CODE_SIGNING_ALLOWED=NO）で UI テストが動くかは未確認。動かなければ設計メモの 10 の代わりの案にする。

## 構成
app.json の paths を変えたら、この表も同じに直します。

| 場所 | 中身 | 書く役 |
|---|---|---|
| ios/project.yml | XcodeGen のプロジェクトの定義（ADR 0004）。ios/Yomutoki.xcodeproj は CI で作り、コミットしない | ios-engineer |
| ios/Yomutoki/ | iOS アプリ（SwiftUI、SwiftData）。テストのつなぎ口は ios/Yomutoki/Debug/UITestHooks.swift の1ファイルだけ（ADR 0005） | ios-engineer |
| ios/YomutokiTests/ | 単体テストと Unit.xctestplan | ios-engineer |
| ios/AcceptanceTests/ | iOS の受け入れテスト（XCUITest）、Acceptance.xctestplan、ac18-reboot.sh、テストの受け口 | verifier |
| contracts/ | 端末の中の契約（データモデル、テストのつなぎ口、計測のイベントと JSON Schema）、依存ライブラリの許可リスト（contracts/dependencies.md）。HTTP の API はない | tech-lead |
| .gitignore、README.md、Makefile など | ルートの設定ファイル | tech-lead |
| design/ | 調査（<機能名>-research.md）、画面の仕様、デザイントークン（design/tokens.md）、文言 | designer |
| docs/prd/、docs/support/、metadata/ | PRD、サポートページ、ストア掲載文 | pdm |
| docs/adr/ | 技術判断の記録（0001〜0005）、機能ごとの技術設計メモ（docs/adr/features/） | tech-lead |
| docs/verification/ | テスト計画、検証レポート、証拠 | verifier |
| docs/progress.md、docs/reviews/、docs/approvals/ | 進捗、判定の記録、Takuma の承認 | 指揮役 |
| .claude/、.github/ | 組織の定義と CI（キットが管理） | Takuma だけ |

## このアプリだけの決まり
- 最低の対応 OS は iOS 17.0、iPhone だけ。Xcode 26 と iOS 26 SDK でビルドする（ADR 0002）。
- Swift 6 の言語モード、並行性の検査は完全、警告は0件。アプリのターゲットの既定の actor 分離は MainActor（ADR 0002）。
- プロジェクトは XcodeGen の ios/project.yml から作る。ターゲットは Yomutoki、YomutokiTests、YomutokiAcceptanceTests の3つ。ローカルの Swift パッケージは作らない（ADR 0002、0004）。
- 保存は SwiftData（VersionedSchema の SchemaV1）。1つの操作は1回の明示の save。mainContext の自動保存は切る。保存が通ってから画面の状態を変える（ADR 0001、contracts/data-model.md）。
- 外部のライブラリは contracts/dependencies.md にあるものだけ（001 のランタイムは0件）。
- 識別子（accessibilityIdentifier）は design/001-reading-session.md の 6 の名前だけを使う。文言は String Catalog（ios/Yomutoki/Resources/Localizable.xcstrings）に ja と en をそろえ、キーは design/ の 7 の名前。
- 色、文字、余白は design/tokens.md のトークンだけ。色は Asset Catalog の Color（Color の値）で .foregroundStyle と .tint に渡す。`.primary` などの階層の形（HierarchicalShapeStyle）を文字の色に使わない。
- テストのつなぎ口（UITEST_ の環境変数、readingapp-uitest:// の URL）は Debug ビルドで -UITest のときだけ働き、Release に入らない（ADR 0005、contracts/test-hooks.md）。
- ログは Logger。題名とページは既定の非公開のまま。`privacy: .public` にするのは操作の名前と状態の名前だけで、理由をコメントに書く。
- 計測のイベントの型に String と Int の値を持たせない（題名とページを送れない形。contracts/telemetry.md）。
