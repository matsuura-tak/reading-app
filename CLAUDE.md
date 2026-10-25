# アプリの地図

このファイルはこのアプリの地図です。tech-lead（テックリード）が手入れし、100行以内に保ちます。
アプリ名と一言の説明は .claude/org/app.json の app_name と idea にあります。
組織の決まりは .claude/rules/org.md、関門は docs/org/gates.md、進み具合は docs/progress.md を読みます。

## 概要
- 何のアプリか：読む時間そのものを美しく残す iPhone の読書アプリ「よむとき（Yomutoki: Reading Time）」。本を題名だけで足し、読んだ時間とページを残して、次は1回の操作で続きから読む。
- データは端末の中だけ（アカウントなし、サーバーなし、計測の SDK なし。ADR 0001、0003）。権限を1つも求めない。
- 使う人：紙の本か電子書籍を読み、読んだ時間と進んだページを手間なく残して、次は前回のページから読みたい人。主に日本（ja）、次に米国（en）の iPhone の利用者（docs/prd/001-reading-session.md の 2、18 の P-2）。
- いまの段階：001-reading-session の G2 は、6442fe2 のコード・受け入れテストの独立レビューがPASS。指揮役裁定（docs/reviews/001-reading-session-G2-ruling.md）に従い、実装前UIテストの赤を実行していない履歴と当時の未完了を保持し、現在の実装とテストを評価した。6442fe2 の全体CIは成功（単体69件、受け入れテスト ja/en 各80件、AC-18 の再起動前後2段階）。
- S2「追加」のラベルへ既存の AppColor.onAccent を指定する1行修正を加えた。修正後のDebug/Releaseビルド、単体69件、AC-2/42/49の ja/en 計6実行と、verifierの画面4条件（ライト・ダーク・AX5・英語）が成功した（docs/reviews/001-reading-session-s2-implementation.md、docs/verification/001-reading-session/evidence/g3-20261023/s2-after/final-integrity.json）。このS2修正後の全体CIは未実行。
- G3はFAILのまま。アクセシビリティ監査の23件の指摘、反復検証・探索・全画面の全状態確認が未完了。S2の4条件成功をG3全体の合格とは扱わない。001は内部のTestFlightまで（単独ではApp Storeに出さない）。

## ビルド/テストのコマンド
.claude/org/app.json の commands は `make ios-build` / `make ios-test`。CI は app.json から Makefile の各ターゲットを実行します。下にはその中身を示します。
コマンドを変えたら、app.json の更新を Takuma に頼みます（.claude/ は Takuma だけが直せます）。
受け入れテストは、受け入れテストのフォルダの中の設定だけで動く形にします。
どれもリポジトリの直下で、macOS（CI の macos-latest）と Xcode 26 以降で動かす1行です。下の各行は Makefile の ios-build と ios-test の中身とそろえます。
- iOS のビルド（commands.ios_build）：2026-10-23 に9f32800の全体CI（Xcode 26.6）と、S5修正4125f7c後のMac（Xcode 27.1）で成功。中身は順に、XcodeGen 2.46.0 の zip を SHA-256 で確かめて入れる（ADR 0004）、Xcode の大きな版が 26 以上でなければ落とす（ADR 0002）、entitlements のファイルの保護が NSFileProtectionComplete（ADR 0001）、UITEST_ を持つ Swift のファイルが Debug/ の2つと受け入れテストの外に0件、Debug と Release のビルド、Release の実行ファイルの strings につなぎ口の文字が0件、Release の Info.plist に CFBundleURLTypes がない（ADR 0005）
  `mkdir -p build/tools && curl -fsSL -o build/tools/xcodegen-2.46.0.zip https://github.com/yonaskolb/XcodeGen/releases/download/2.46.0/xcodegen.zip && echo '4d9e34b62172d645eed6457cac13fc222569974098ef4ee9c3368bedf0196806  build/tools/xcodegen-2.46.0.zip' | shasum -a 256 -c - && rm -rf build/tools/xcodegen && unzip -q build/tools/xcodegen-2.46.0.zip -d build/tools && build/tools/xcodegen/bin/xcodegen --version && xcodebuild -version && xcodebuild -version | grep -qE '^Xcode (2[6-9]|[3-9][0-9])' && cd ios && ../build/tools/xcodegen/bin/xcodegen generate && /usr/libexec/PlistBuddy -c 'Print :com.apple.developer.default-data-protection' Yomutoki/Yomutoki.entitlements | grep -qx NSFileProtectionComplete && ! grep -rlE 'UITEST_' . --include='*.swift' | grep -vE '^\./(Yomutoki/Debug/(UITestHooks|HTTPTelemetrySink)\.swift|AcceptanceTests/|build/)' && xcodebuild build -project Yomutoki.xcodeproj -scheme Yomutoki -configuration Debug -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO && xcodebuild build -project Yomutoki.xcodeproj -scheme Yomutoki -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath build/release CODE_SIGNING_ALLOWED=NO && test -f build/release/Build/Products/Release-iphonesimulator/Yomutoki.app/Yomutoki && ! strings -a build/release/Build/Products/Release-iphonesimulator/Yomutoki.app/Yomutoki | grep -E 'UITEST_|readingapp-uitest|-UITest|uitest\.' && test -f build/release/Build/Products/Release-iphonesimulator/Yomutoki.app/Info.plist && ! /usr/libexec/PlistBuddy -c 'Print :CFBundleURLTypes' build/release/Build/Products/Release-iphonesimulator/Yomutoki.app/Info.plist`
- iOS のテスト（commands.ios_test）：9f32800の全体CI（Xcode 26.6、iPhone 17 / iOS 26.5）で単体69件、受け入れテスト ja_JP/en_US 各80件が成功（失敗0・飛ばした0）、AC-18は再起動の前後が各1件成功し「passed 2 of 2」。単体テスト（ios/YomutokiTests/Unit.xctestplan）、受け入れテスト（ios/AcceptanceTests/Acceptance.xctestplan）、AC-18 の再起動の2段（ios/AcceptanceTests/ac18-reboot.sh。AC18Reboot.xctestplan を使う）の順に動く。Acceptance は ios/AcceptanceTests/run-acceptance.sh が再試行なしで動かし（全体CIで実行確認済み）、出力をリポジトリの外の Acceptance.log に残して、終わりに両方の回の要約（`=== ACCEPTANCE SUMMARY ===`）を出す（CI のログは末尾 5,000 行しか取れず、先に走る ja_JP の回の失敗の文言が切れるため）。既定の計画は Unit（project.yml の defaultPlan）。AC-39 の ios/AcceptanceTests/ac39-xcstrings.sh は入っておらず、verifier が別に実行する（CI に入れるなら Takuma が ios_test の頭に `bash ios/AcceptanceTests/ac39-xcstrings.sh &&` を足し、tech-lead がここと Makefile を直す）
  `mkdir -p build/tools && curl -fsSL -o build/tools/xcodegen-2.46.0.zip https://github.com/yonaskolb/XcodeGen/releases/download/2.46.0/xcodegen.zip && echo '4d9e34b62172d645eed6457cac13fc222569974098ef4ee9c3368bedf0196806  build/tools/xcodegen-2.46.0.zip' | shasum -a 256 -c - && rm -rf build/tools/xcodegen && unzip -q build/tools/xcodegen-2.46.0.zip -d build/tools && cd ios && ../build/tools/xcodegen/bin/xcodegen generate && xcrun simctl list devices available && xcodebuild test -project Yomutoki.xcodeproj -scheme Yomutoki -testPlan Unit -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO && bash AcceptanceTests/run-acceptance.sh 'iPhone 17' && bash AcceptanceTests/ac18-reboot.sh 'iPhone 17'`
- バックエンドのテスト：なし（001 にサーバーはない）
- 契約の検査（Linux で動く。動かした）：`make contracts-check`（`npx -y ajv-cli@5.0.0 validate` の4行。JSON Schema と例。contracts/README.md の1）
- 文言の表の検査（AC-39。Linux で動く。ios/ ができてから）：`python3 -I contracts/tools/xcstrings_untranslated.py ios/Yomutoki/Resources/*.xcstrings`（ios/AcceptanceTests/ac39-xcstrings.sh がこれを包む）

決まり：
- 受け入れテストの判定の実行（G2 の red、G3）では `-retry-tests-on-failure` を付けない（落ちたテストを通ったことにしない）。
- シミュレーターは「iPhone 17」。初回 CI のログで暫定の iPhone 16 が存在せず、iPhone 17（iOS 26.2、26.4.1、26.5）が実在することを確認して Makefile とそろえた。app.json は Makefile を呼ぶ。ビルドは generic の行き先を使う。
- ios/AcceptanceTests/ の target.yml、Acceptance.xctestplan、AC18Reboot.xctestplan、run-acceptance.sh、ac18-reboot.sh、ac39-xcstrings.sh は verifier が書く。target.yml がないと xcodegen generate が落ち（確認済み。XcodeGen 2.46.0 の Sources/ProjectSpec/SpecFile.swift:95、:100-105。G1 reviewer r2 の参考2）、ios_build も ios_test も落ちる。雛形だけの変更は G2 に出さない（設計メモの 11）。
- 署名なし（CODE_SIGNING_ALLOWED=NO）で UI テストが動くことは確認済み（2026-10-22 の CI run 21。受け入れテストの2つの回で160本が動いた。docs/verification/001-reading-session/ci-runs/c9e7427-acceptance.md）。
- CI の時間の見積もりは70〜135分（推測）。2026-10-22 の Takuma の許可で .github/workflows/ios.yml の timeout-minutes を150に設定済み（docs/approvals/001-reading-session-ci-settings.md）。
- XcodeGen の版とチェックサムを変えるときは ADR 0004、contracts/dependencies.md、ここ、Makefile の4か所を一緒に直す。ajv-cli の版はここ、Makefile、contracts/README.md、contracts/dependencies.md。

## 構成
app.json の paths を変えたら、この表も同じに直します。

| 場所 | 中身 | 書く役 |
|---|---|---|
| ios/project.yml | XcodeGen のプロジェクトの定義（ADR 0004）。テストの設定として扱い、G2 の reviewer が差分を全部読む。ios/AcceptanceTests/target.yml を include する（:REPLACE は使わない）。name は Yomutoki のまま、スキーム Yomutoki は最上位の schemes: に書く（設計メモの 11 の 13）。ios/Yomutoki.xcodeproj は CI で作り、コミットしない | ios-engineer |
| ios/Yomutoki/ | iOS アプリ（SwiftUI、SwiftData）。テストのつなぎ口は Debug/UITestHooks.swift と Debug/HTTPTelemetrySink.swift の2つだけ（ADR 0005）。Yomutoki.entitlements（ファイルの保護。ADR 0001）は project.yml から作る | ios-engineer |
| ios/YomutokiTests/ | 単体テストと Unit.xctestplan（project.yml のスキームに defaultPlan: true で書く） | ios-engineer |
| ios/AcceptanceTests/ | iOS の受け入れテスト（XCUITest）、target.yml（受け入れテストのターゲットとテスト計画の定義）、Acceptance.xctestplan、AC18Reboot.xctestplan（ac18-reboot.sh だけが使う）、run-acceptance.sh（Acceptance の実行と要約。ios_test から呼ぶ）、ac18-reboot.sh、ac39-xcstrings.sh（AC-39。ios_test の外）、テストの受け口 | verifier |
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
