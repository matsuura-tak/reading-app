# よむま（ReadingApp）ルートの Makefile
# .claude/org/app.json の commands（make ios-build / make ios-test）に対応する。

SHELL := /bin/zsh
XCODEPROJ := ios/ReadingApp.xcodeproj
SCHEME := ReadingApp
SIM_DESTINATION ?= platform=iOS Simulator,name=iPhone 17,OS=26.5
SCHEMA_PYTHON ?= /tmp/reading-app-schema-venv/bin/python

.PHONY: ios-build ios-test ios-test-first-launch ios-test-perf check-contracts

ios-build:
	@if [ ! -d "$(XCODEPROJ)" ]; then \
		echo "ERROR: $(XCODEPROJ) does not exist yet (G1 design phase; ios-engineer will create ios/ in G2/G3)." >&2; \
		exit 1; \
	fi
	xcodebuild -project "$(XCODEPROJ)" \
		-scheme "$(SCHEME)" \
		-configuration Debug \
		-destination 'generic/platform=iOS Simulator' \
		SWIFT_TREAT_WARNINGS_AS_ERRORS=YES \
		build

ios-test:
	@if [ ! -d "$(XCODEPROJ)" ]; then \
		echo "ERROR: $(XCODEPROJ) does not exist yet (G1 design phase; ios-engineer/verifier will create ios/ in G2/G3)." >&2; \
		exit 1; \
	fi
	swift test --package-path ios/ReadingKit
	xcodebuild test -project "$(XCODEPROJ)" \
		-scheme "$(SCHEME)" \
		-configuration Debug \
		-destination "$(SIM_DESTINATION)" \
		-skip-testing:AcceptanceTests/FirstLaunchTests

ios-test-first-launch:
	@if [ ! -d "$(XCODEPROJ)" ]; then \
		echo "ERROR: $(XCODEPROJ) does not exist yet." >&2; \
		exit 1; \
	fi
	xcodebuild test -project "$(XCODEPROJ)" \
		-scheme "$(SCHEME)" \
		-configuration Debug \
		-destination "$(SIM_DESTINATION)" \
		-only-testing:AcceptanceTests/FirstLaunchTests

ios-test-perf:
	@if [ ! -d "$(XCODEPROJ)" ]; then \
		echo "ERROR: $(XCODEPROJ) does not exist yet." >&2; \
		exit 1; \
	fi
	xcodebuild test -project "$(XCODEPROJ)" \
		-scheme "$(SCHEME)" \
		-configuration Perf \
		-destination "$(SIM_DESTINATION)" \
		-only-testing:AcceptanceTests/PerformanceTests

# check-contracts: Python jsonschema.Draft202012Validator ワンライナーによる全8スキーマ＋全25 examples の自動検証（外部スクリプト不使用）
check-contracts:
	"$(SCHEMA_PYTHON)" -I -c 'import json,sys; from jsonschema import Draft202012Validator as V; from referencing import Registry,Resource; S=[json.load(open(p,encoding="utf-8")) for p in sys.argv[1:]]; [V.check_schema(s) for s in S]; R=Registry().with_resources([(s["$$id"],Resource.from_contents(s)) for s in S]); n=sum(1 for s in S for e in s.get("examples",[]) if V(s,registry=R).validate(e) is None)+sum(1 for s in S for d in s.get("$$defs",{}).values() for e in d.get("examples",[]) if V(d,registry=R).validate(e) is None); print(f"ALL PASSED: {len(S)} schemas, {n} examples validated with 0 errors.")' contracts/hooks/*.schema.json contracts/widget-snapshot.schema.json
