# ルートの Makefile（tech-lead が手入れする）。
# ios-build と ios-test の中身は、CLAUDE.md と .claude/org/app.json の commands.ios_build、commands.ios_test と同じ1行にする。
# 片方を変えたら、もう片方も同じに直す（CI は app.json の方を使う）。make の中で意味を持つ $ を使わない形にしてあるので、一字一句同じでよい。
# ios-build と ios-test は macOS と Xcode 26 でしか動かない（未確認。最初の CI の出力で確かめる）。
# XcodeGen の版（2.46.0）とチェックサムは ADR 0004、contracts/dependencies.md、CLAUDE.md とそろえる。
# contracts-check は Linux でも動く（Node が要る）。ajv-cli の版（5.0.0）は contracts/README.md、contracts/dependencies.md、CLAUDE.md とそろえる。

.PHONY: ios-build ios-test contracts-check

ios-build:
	mkdir -p build/tools && curl -fsSL -o build/tools/xcodegen-2.46.0.zip https://github.com/yonaskolb/XcodeGen/releases/download/2.46.0/xcodegen.zip && echo '4d9e34b62172d645eed6457cac13fc222569974098ef4ee9c3368bedf0196806  build/tools/xcodegen-2.46.0.zip' | shasum -a 256 -c - && rm -rf build/tools/xcodegen && unzip -q build/tools/xcodegen-2.46.0.zip -d build/tools && build/tools/xcodegen/bin/xcodegen --version && xcodebuild -version && xcodebuild -version | grep -qE '^Xcode (2[6-9]|[3-9][0-9])' && cd ios && ../build/tools/xcodegen/bin/xcodegen generate && /usr/libexec/PlistBuddy -c 'Print :com.apple.developer.default-data-protection' Yomutoki/Yomutoki.entitlements | grep -qx NSFileProtectionComplete && ! grep -rlE 'UITEST_' . --include='*.swift' | grep -vE '^\./(Yomutoki/Debug/(UITestHooks|HTTPTelemetrySink)\.swift|AcceptanceTests/|build/)' && xcodebuild build -project Yomutoki.xcodeproj -scheme Yomutoki -configuration Debug -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO && xcodebuild build -project Yomutoki.xcodeproj -scheme Yomutoki -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath build/release CODE_SIGNING_ALLOWED=NO && test -f build/release/Build/Products/Release-iphonesimulator/Yomutoki.app/Yomutoki && ! strings -a build/release/Build/Products/Release-iphonesimulator/Yomutoki.app/Yomutoki | grep -E 'UITEST_|readingapp-uitest|-UITest|uitest\.' && test -f build/release/Build/Products/Release-iphonesimulator/Yomutoki.app/Info.plist && ! /usr/libexec/PlistBuddy -c 'Print :CFBundleURLTypes' build/release/Build/Products/Release-iphonesimulator/Yomutoki.app/Info.plist

ios-test:
	mkdir -p build/tools && curl -fsSL -o build/tools/xcodegen-2.46.0.zip https://github.com/yonaskolb/XcodeGen/releases/download/2.46.0/xcodegen.zip && echo '4d9e34b62172d645eed6457cac13fc222569974098ef4ee9c3368bedf0196806  build/tools/xcodegen-2.46.0.zip' | shasum -a 256 -c - && rm -rf build/tools/xcodegen && unzip -q build/tools/xcodegen-2.46.0.zip -d build/tools && cd ios && ../build/tools/xcodegen/bin/xcodegen generate && xcrun simctl list devices available && xcodebuild test -project Yomutoki.xcodeproj -scheme Yomutoki -testPlan Unit -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO && xcodebuild test -project Yomutoki.xcodeproj -scheme Yomutoki -testPlan Acceptance -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO && bash AcceptanceTests/ac18-reboot.sh 'iPhone 16'

contracts-check:
	npx -y ajv-cli@5.0.0 validate -s contracts/seed.schema.json -d contracts/seed.example.json
	npx -y ajv-cli@5.0.0 validate -s contracts/seed.schema.json -d "contracts/examples/seed-*.json"
	npx -y ajv-cli@5.0.0 validate -s contracts/telemetry-events.schema.json -d "contracts/examples/telemetry-*.json"
	npx -y ajv-cli@5.0.0 validate -s contracts/telemetry-flushed.schema.json -d contracts/examples/flushed.json
