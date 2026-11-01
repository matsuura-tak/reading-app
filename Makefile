# よむま（ReadingApp）ルートの Makefile
# .claude/org/app.json の commands（make ios-build / make ios-test）に対応する。

SHELL := /bin/zsh
XCODEPROJ := ios/ReadingApp.xcodeproj
SCHEME := ReadingApp
SIM_DESTINATION ?= platform=iOS Simulator,name=iPhone 17,OS=26.0
# 契約の検査（JSON Schema）に使う Python の venv。リポジトリの外の利用者のキャッシュ（~/.cache）に置き、/tmp に頼らない
# （/tmp は再起動などで消える。リポジトリの中はどの役も書かない決まり）。
# 初めての時だけ contracts-venv が作る（ネットワークが要る）。版は contracts/check-requirements.txt と contracts/dependencies.md。
BOOTSTRAP_PYTHON ?= /usr/bin/python3
SCHEMA_VENV ?= $(HOME)/.cache/reading-app/contracts-schema-venv
SCHEMA_PYTHON ?= $(SCHEMA_VENV)/bin/python
SCHEMA_REQUIREMENTS := contracts/check-requirements.txt
SCHEMA_STAMP := $(SCHEMA_VENV)/.installed

.PHONY: ios-build ios-test ios-test-first-launch ios-test-perf check-contracts contracts-venv

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
		-skip-testing:ReadingAcceptanceTests/FirstLaunchTests \
		-skip-testing:ReadingAcceptanceTests/PerformanceTests

ios-test-first-launch:
	@if [ ! -d "$(XCODEPROJ)" ]; then \
		echo "ERROR: $(XCODEPROJ) does not exist yet." >&2; \
		exit 1; \
	fi
	xcodebuild test -project "$(XCODEPROJ)" \
		-scheme "$(SCHEME)" \
		-configuration Debug \
		-destination "$(SIM_DESTINATION)" \
		-only-testing:ReadingAcceptanceTests/FirstLaunchTests

ios-test-perf:
	@if [ ! -d "$(XCODEPROJ)" ]; then \
		echo "ERROR: $(XCODEPROJ) does not exist yet." >&2; \
		exit 1; \
	fi
	xcodebuild test -project "$(XCODEPROJ)" \
		-scheme "$(SCHEME)" \
		-configuration Perf \
		-destination "$(SIM_DESTINATION)" \
		-only-testing:ReadingAcceptanceTests/PerformanceTests

# contracts-venv: 検査用の venv を作り、contracts/check-requirements.txt の固定版を入れる。
# 印のファイル（.installed）が requirements より新しければ何もしない。作り直すときは SCHEMA_VENV のフォルダを消す。
contracts-venv: $(SCHEMA_STAMP)

$(SCHEMA_STAMP): $(SCHEMA_REQUIREMENTS)
	@if [ ! -x "$(SCHEMA_VENV)/bin/python" ]; then \
		echo "creating $(SCHEMA_VENV) with $(BOOTSTRAP_PYTHON)"; \
		mkdir -p "$(dir $(SCHEMA_VENV))" || exit 1; \
		"$(BOOTSTRAP_PYTHON)" -m venv "$(SCHEMA_VENV)" || exit 1; \
	fi
	"$(SCHEMA_VENV)/bin/python" -m pip install --quiet --disable-pip-version-check -r "$(SCHEMA_REQUIREMENTS)"
	"$(SCHEMA_VENV)/bin/python" -I -c 'import jsonschema,referencing; from importlib.metadata import version as v; print("jsonschema", v("jsonschema"), "referencing", v("referencing"))'
	@touch "$(SCHEMA_STAMP)"

# check-contracts: Python jsonschema.Draft202012Validator ワンライナーによる全スキーマ＋全 examples の自動検証（外部スクリプト不使用）
check-contracts: contracts-venv
	"$(SCHEMA_PYTHON)" -I -c 'import json,sys; from jsonschema import Draft202012Validator as V; from referencing import Registry,Resource; S=[json.load(open(p,encoding="utf-8")) for p in sys.argv[1:]]; [V.check_schema(s) for s in S]; R=Registry().with_resources([(s["$$id"],Resource.from_contents(s)) for s in S]); n=sum(1 for s in S for e in s.get("examples",[]) if V(s,registry=R).validate(e) is None)+sum(1 for s in S for d in s.get("$$defs",{}).values() for e in d.get("examples",[]) if V(d,registry=R).validate(e) is None); print(f"ALL PASSED: {len(S)} schemas, {n} examples validated with 0 errors.")' contracts/hooks/*.schema.json contracts/widget-snapshot.schema.json
