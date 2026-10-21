# ルートの Makefile（tech-lead が手入れする）。
# ios-build と ios-test の中身は、CLAUDE.md と .claude/org/app.json の commands.ios_build、commands.ios_test と同じ1行にする。
# 片方を変えたら、もう片方も同じに直す（CI は app.json の方を使う）。
# ios-build と ios-test は macOS と Xcode 26 でしか動かない（未確認。最初の CI の出力で確かめる）。
# contracts-check は Linux でも動く（Node が要る）。

.PHONY: ios-build ios-test contracts-check

ios-build:
	cd ios && (command -v xcodegen >/dev/null || brew install xcodegen) && xcodegen --version && xcodegen generate && xcodebuild -version && xcodebuild build -project Yomutoki.xcodeproj -scheme Yomutoki -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO

ios-test:
	cd ios && (command -v xcodegen >/dev/null || brew install xcodegen) && xcodegen generate && xcrun simctl list devices available && xcodebuild test -project Yomutoki.xcodeproj -scheme Yomutoki -testPlan Unit -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO && xcodebuild test -project Yomutoki.xcodeproj -scheme Yomutoki -testPlan Acceptance -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO && bash AcceptanceTests/ac18-reboot.sh 'iPhone 16'

contracts-check:
	npx -y ajv-cli@5 validate -s contracts/seed.schema.json -d contracts/seed.example.json
	npx -y ajv-cli@5 validate -s contracts/seed.schema.json -d "contracts/examples/seed-*.json"
	npx -y ajv-cli@5 validate -s contracts/telemetry-events.schema.json -d "contracts/examples/telemetry-*.json"
	npx -y ajv-cli@5 validate -s contracts/telemetry-flushed.schema.json -d contracts/examples/flushed.json
