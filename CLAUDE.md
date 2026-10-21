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
どれもリポジトリの直下で、macOS（CI の macos-latest）と Xcode 26 で動かす1行です。`$` を使わないので、Makefile の ios-build と ios-test も一字一句同じ1行です。
- iOS のビルド（commands.ios_build）：**未確認**（この環境は Linux で、xcodebuild、strings の Mach-O、PlistBuddy が動かない。最初の CI の出力で確かめる。裁定の追記2）。中身は順に、XcodeGen 2.46.0 の zip を SHA-256 で確かめて入れる（ADR 0004）、Xcode の大きな版が 26 以上でなければ落とす（ADR 0002）、entitlements のファイルの保護が NSFileProtectionComplete（ADR 0001）、UITEST_ を持つ Swift のファイルが Debug/ の2つと受け入れテストの外に0件、Debug と Release のビルド、Release の実行ファイルの strings につなぎ口の文字が0件、Release の Info.plist に CFBundleURLTypes がない（ADR 0005）
  `mkdir -p build/tools && curl -fsSL -o build/tools/xcodegen-2.46.0.zip https://github.com/yonaskolb/XcodeGen/releases/download/2.46.0/xcodegen.zip && echo '4d9e34b62172d645eed6457cac13fc222569974098ef4ee9c3368bedf0196806  build/tools/xcodegen-2.46.0.zip' | shasum -a 256 -c - && rm -rf build/tools/xcodegen && unzip -q build/tools/xcodegen-2.46.0.zip -d build/tools && build/tools/xcodegen/bin/xcodegen --version && xcodebuild -version && xcodebuild -version | grep -qE '^Xcode (2[6-9]|[3-9][0-9])' && cd ios && ../build/tools/xcodegen/bin/xcodegen generate && /usr/libexec/PlistBuddy -c 'Print :com.apple.developer.default-data-protection' Yomutoki/Yomutoki.entitlements | grep -qx NSFileProtectionComplete && ! grep -rlE 'UITEST_' . --include='*.swift' | grep -vE '^\./(Yomutoki/Debug/(UITestHooks|HTTPTelemetrySink)\.swift|AcceptanceTests/|build/)' && xcodebuild build -project Yomutoki.xcodeproj -scheme Yomutoki -configuration Debug -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO && xcodebuild build -project Yomutoki.xcodeproj -scheme Yomutoki -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath build/release CODE_SIGNING_ALLOWED=NO && test -f build/release/Build/Products/Release-iphonesimulator/Yomutoki.app/Yomutoki && ! strings -a build/release/Build/Products/Release-iphonesimulator/Yomutoki.app/Yomutoki | grep -E 'UITEST_|readingapp-uitest|-UITest|uitest\.' && test -f build/release/Build/Products/Release-iphonesimulator/Yomutoki.app/Info.plist && ! /usr/libexec/PlistBuddy -c 'Print :CFBundleURLTypes' build/release/Build/Products/Release-iphonesimulator/Yomutoki.app/Info.plist`
- iOS のテスト（commands.ios_test）：**未確認**（同上）。単体テスト（ios/YomutokiTests/Unit.xctestplan）、受け入れテスト（ios/AcceptanceTests/Acceptance.xctestplan）、AC-18 の再起動の2段（ios/AcceptanceTests/ac18-reboot.sh）の順に動く
  `mkdir -p build/tools && curl -fsSL -o build/tools/xcodegen-2.46.0.zip https://github.com/yonaskolb/XcodeGen/releases/download/2.46.0/xcodegen.zip && echo '4d9e34b62172d645eed6457cac13fc222569974098ef4ee9c3368bedf0196806  build/tools/xcodegen-2.46.0.zip' | shasum -a 256 -c - && rm -rf build/tools/xcodegen && unzip -q build/tools/xcodegen-2.46.0.zip -d build/tools && cd ios && ../build/tools/xcodegen/bin/xcodegen generate && xcrun simctl list devices available && xcodebuild test -project Yomutoki.xcodeproj -scheme Yomutoki -testPlan Unit -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO && xcodebuild test -project Yomutoki.xcodeproj -scheme Yomutoki -testPlan Acceptance -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO && bash AcceptanceTests/ac18-reboot.sh 'iPhone 16'`
- バックエンドのテスト：なし（001 にサーバーはない）
- 契約の検査（Linux で動く。動かした）：`make contracts-check`（`npx -y ajv-cli@5.0.0 validate` の4行。JSON Schema と例。contracts/README.md の1）
- 文言の表の検査（AC-39。Linux で動く。ios/ ができてから）：`python3 -I contracts/tools/xcstrings_untranslated.py ios/Yomutoki/Resources/*.xcstrings`

決まり：
- 受け入れテストの判定の実行（G2 の red、G3）では `-retry-tests-on-failure` を付けない（落ちたテストを通ったことにしない）。
- シミュレーターの名前「iPhone 16」は暫定（裁定の追記2 の (3)）。最初の CI の ios_test のログの `xcrun simctl list devices available` から iOS 26 のランタイムの iPhone を1つ選び、違う名前ならここと Makefile と app.json（Takuma）を同じ名前に直す。ビルドは名前の要らない generic の行き先にしてある。
- ios/AcceptanceTests/ の target.yml、Acceptance.xctestplan、ac18-reboot.sh は verifier が書く。target.yml がないうちは xcodegen generate が落ち（推測）、ios_build も ios_test も落ちる。雛形だけの変更は G2 に出さない（設計メモの 11）。
- 署名なし（CODE_SIGNING_ALLOWED=NO）で UI テストが動くかは未確認。動かなければ設計メモの 10 の代わりの案にする。
- XcodeGen の版とチェックサムを変えるときは ADR 0004、contracts/dependencies.md、ここ、Makefile の4か所を一緒に直す。ajv-cli の版はここ、Makefile、contracts/README.md、contracts/dependencies.md。

## 構成
app.json の paths を変えたら、この表も同じに直します。

| 場所 | 中身 | 書く役 |
|---|---|---|
| ios/project.yml | XcodeGen のプロジェクトの定義（ADR 0004）。テストの設定として扱い、G2 の reviewer が差分を全部読む。ios/AcceptanceTests/target.yml を include する（:REPLACE は使わない）。ios/Yomutoki.xcodeproj は CI で作り、コミットしない | ios-engineer |
| ios/Yomutoki/ | iOS アプリ（SwiftUI、SwiftData）。テストのつなぎ口は Debug/UITestHooks.swift と Debug/HTTPTelemetrySink.swift の2つだけ（ADR 0005）。Yomutoki.entitlements（ファイルの保護。ADR 0001）は project.yml から作る | ios-engineer |
| ios/YomutokiTests/ | 単体テストと Unit.xctestplan | ios-engineer |
| ios/AcceptanceTests/ | iOS の受け入れテスト（XCUITest）、target.yml（受け入れテストのターゲットとテスト計画の定義）、Acceptance.xctestplan、ac18-reboot.sh、テストの受け口 | verifier |
| contracts/ | 端末の中の契約（データモデル、テストのつなぎ口、計測のイベントと JSON Schema）、依存ライブラリと道具の許可リスト（contracts/dependencies.md）。HTTP の API はない | tech-lead |
| .gitignore、README.md、Makefile など | ルートの設定ファイル。build/ は CI の道具とビルドの置き場（コミットしない） | tech-lead |
| design/ | 調査（<機能名>-research.md）、画面の仕様、デザイントークン（design/tokens.md）、文言 | designer |
| docs/prd/、docs/support/、metadata/ | PRD、サポートページ、ストア掲載文 | pdm |
| docs/adr/ | 技術判断の記録（0001〜0005）、機能ごとの技術設計メモ（docs/adr/features/） | tech-lead |
| docs/verification/ | テスト計画、検証レポート、証拠 | verifier |
| docs/progress.md、docs/reviews/、docs/approvals/ | 進捗、判定の記録、Takuma の承認 | 指揮役 |
| .claude/、.github/ | 組織の定義と CI（キットが管理） | Takuma だけ |

## このアプリだけの決まり
- 最低の対応 OS は iOS 17.0、iPhone だけ。Xcode 26 と iOS 26 SDK でビルドする。毎回の CI は iOS 26 だけで、iOS 17 は G4 の前に1回確かめる（ADR 0002）。
- Swift 6 の言語モード、並行性の検査は完全、警告は0件。アプリのターゲットの既定の actor 分離は MainActor（ADR 0002）。
- プロジェクトは XcodeGen 2.46.0 の ios/project.yml から作る。ターゲットは Yomutoki、YomutokiTests、YomutokiAcceptanceTests の3つ。ローカルの Swift パッケージは作らない（ADR 0002、0004）。
- 保存は SwiftData（VersionedSchema の SchemaV1）。1つの操作は1回の明示の save。mainContext の自動保存は切る。保存が通ってから画面の状態を変える（ADR 0001、contracts/data-model.md）。
- ファイルの保護は .complete（Data Protection の entitlement、NSFileProtectionComplete）。バックグラウンドの処理を足さない（足すなら ADR 0001 を見直す）。
- 外部のライブラリは contracts/dependencies.md にあるものだけ（001 のランタイムは0件）。
- 識別子（accessibilityIdentifier）は design/001-reading-session.md の 6 の名前だけを使う。文言は String Catalog（ios/Yomutoki/Resources/Localizable.xcstrings）に ja と en をそろえ、キーは design/ の 7 の名前。
- 色、文字、余白は design/tokens.md のトークンだけ。色は Asset Catalog の Color（Color の値）で .foregroundStyle と .tint に渡す。`.primary` などの階層の形（HierarchicalShapeStyle）を文字の色に使わない。
- テストのつなぎ口（UITEST_ の環境変数、readingapp-uitest:// の URL、uitest. の要素）は Debug ビルドで -UITest のときだけ働き、Release に入らない（ADR 0005、contracts/test-hooks.md）。
- ログは Logger。題名とページは既定の非公開のまま。`privacy: .public` にするのは操作の名前と状態の名前だけで、理由をコメントに書く。
- 計測のイベントの型に String と Int の値を持たせない（題名とページを送れない形。contracts/telemetry.md）。
