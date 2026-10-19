# アプリの地図

このファイルはこのアプリの地図です。tech-lead（テックリード）が手入れし、100行以内に保ちます。
アプリ名と一言の説明は .claude/org/app.json の app_name と idea にあります。
組織の決まりは .claude/rules/org.md、関門は docs/org/gates.md、進み具合は docs/progress.md を読みます。

## 概要
- 何のアプリか：夜、ロック画面のウィジェットに出る「自分の本の続きの一行」から読み始め、伏せて読み、しおり（一行とページ）を挟んで閉じる iPhone の読書アプリ（仮の名前「よむま」）。データは端末の中だけで、サーバーもアカウントもない。
- 使う人：平日の夜にスマホへ流れて、本を開けずにいる人（PRD の 13）。iOS 26 以上の iPhone を使う人。
- いまの段階：001-reading-session の G1（設計）。芯の AC 85件の設計メモ、契約、ADR 0001〜0005 を書き、reviewer の判定を待つ。ios/ はまだない。

## ビルド/テストのコマンド
.claude/org/app.json の commands と同じものを書きます。CI は app.json の方を使います。
コマンドを変えたら、app.json の更新を Takuma に頼みます（.claude/ は Takuma だけが直せます）。
受け入れテストは、受け入れテストのフォルダの中の設定だけで動く形にします。
いまの app.json の commands は3つとも空です（2026-10-20）。下の案を入れるよう Takuma に頼んでいます。

### iOS（ios/ がまだないので、どれも未確認。形だけ。<> の名前は ios/ を作る最初の PR で決めて直す）
- ビルド（未確認）：`xcodebuild -project ios/<プロジェクト>.xcodeproj -scheme <アプリのスキーム> -configuration Debug -destination 'generic/platform=iOS Simulator' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build`
- テスト（未確認）：`xcodebuild test -project ios/<プロジェクト>.xcodeproj -scheme <アプリのスキーム> -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=27.0' -skip-testing:<受け入れテストのターゲット>/FirstLaunchTests`
- 速さの AC（未確認）：上のテストを `-configuration Perf -only-testing:<受け入れテストのターゲット>/<速さのテストの組>` で動かす（G3 は Perf で測る。裁定 29、ADR 0005）。
- 初めて起動した端末（H14。未確認）：テストだけの端末を `xcrun simctl erase <端末>` で消してから、`-destination id=<端末> -only-testing:<受け入れテストのターゲット>/FirstLaunchTests` だけを動かす。ほかのテストと同じ実行に混ぜない（contracts/test-hooks.md の H14）。
- iOS 26 のシミュレーター（G1-3。未確認）：この機械の runtime は iOS 27.0 だけ。入れるなら `xcodebuild -downloadPlatform iOS -buildVersion 26.5`（Apple silicon 用で約 8.5 GB）。入れたらウィジェットと伏せる道のテストを `OS=26.5` の端末でも動かす。入れるかは Takuma が決め、入れなければ iOS 26 は G4 の実機だけで確かめる（設計メモの 10）。

### バックエンド
- なし（サーバーを持たない。PRD 10）。

### 契約の検査（7-4b で動かした。道具はリポジトリの外に置く。版と入れ方は contracts/dependencies.md）
- 形式（spectral 6.17.0）：`spectral lint contracts/ndl-opensearch.yaml --ruleset contracts/.spectral.yaml --fail-severity hint` → `No results with a severity of 'hint' or higher found!`
- 互換性（oasdiff 1.34.0）：`git show origin/main:contracts/ndl-opensearch.yaml > <外のフォルダ>/main.yaml` のあと `oasdiff breaking --fail-on ERR <外のフォルダ>/main.yaml contracts/ndl-opensearch.yaml`。main に契約がなければ「新規」で、`openapi: 3.1.0` と `paths: {}` だけの空の基準と比べる（7-4b は `No breaking changes to report`）。
- JSON Schema（jsonschema 4.25.1。`python3 -m venv <外のフォルダ>/venv` と `<外のフォルダ>/venv/bin/pip install 'jsonschema==4.25.1'` で入れる）。出力は `schemas 8 examples 16 OK`：

```
<外のフォルダ>/venv/bin/python -I -c 'import json,sys; from jsonschema import Draft202012Validator as V; from referencing import Registry,Resource; S=[json.load(open(p,encoding="utf-8")) for p in sys.argv[1:]]; [V.check_schema(s) for s in S]; R=Registry().with_resources([(s["$id"],Resource.from_contents(s)) for s in S]); n=sum(1 for s in S for e in s.get("examples",[]) if V(s,registry=R).validate(e) is None); print("schemas",len(S),"examples",n,"OK")' contracts/hooks/*.schema.json contracts/widget-snapshot.schema.json
```

## 構成
既定の場所です。app.json の paths を変えたら、この表も同じに直します。使わない行は消してかまいません（バックエンドの行は、サーバーがないので消した）。

| 場所 | 中身 | 書く役 |
|---|---|---|
| ios/ | iOS アプリ（SwiftUI）、ウィジェットの拡張、ローカルの Swift パッケージ2つ（ReadingCore、ReadingStore）と単体テスト | ios-engineer |
| ios/AcceptanceTests/ | iOS の受け入れテスト | verifier |
| contracts/ | 契約（ndl-opensearch.yaml、widget-snapshot.schema.json、entry-urls.md、test-hooks.md、hooks/）、spectral のルール（.spectral.yaml）、依存ライブラリの許可リスト（dependencies.md） | tech-lead |
| .gitignore、README.md、Makefile、fastlane/ など | ルートの設定ファイル | tech-lead |
| design/ | 調査（<機能名>-research.md）、画面の仕様、デザイントークン、文言 | designer |
| docs/prd/、docs/support/、metadata/ | PRD、サポートページ、ストア掲載文 | pdm |
| docs/adr/ | 技術判断の記録、機能ごとの技術設計メモ（docs/adr/features/） | tech-lead |
| docs/verification/ | テスト計画、検証レポート、証拠 | verifier |
| docs/progress.md、docs/reviews/、docs/approvals/ | 進捗、判定の記録、Takuma の承認 | 指揮役 |
| .claude/、.github/ | 組織の定義と CI（キットが管理） | Takuma だけ |

## このアプリだけの決まり
- 最低 iOS 26.0、iPhone だけ。Xcode 26 以降と iOS 26 以降の SDK でビルドする（この機械は Xcode 27.1）。ADR 0001。
- Swift 6 の言語モード、並行性の検査は完全、警告は0件（SWIFT_TREAT_WARNINGS_AS_ERRORS=YES）。`@unchecked Sendable`、`nonisolated(unsafe)`、`@preconcurrency` は使わない（使うなら、その行に理由）。
- 外部のライブラリはなし。Apple のフレームワークだけを使う（contracts/dependencies.md）。
- 作り：アプリ、ウィジェットの拡張、ローカルのパッケージ ReadingCore（両方が使う。nonisolated）と ReadingStore（アプリだけ。MainActor）。拡張は SwiftData を開かず、App Group の写しだけを読む（ADR 0001、0002）。
- 構成は3つ：Debug、Perf（Release を写し、コンパイルの条件 `UITEST_HOOKS` だけを足す。速さの AC を G3 で測る）、Release（TestFlight と App Store）。ADR 0005。
- テストのつなぎ口はテストの構成だけ：アプリのターゲットの `UITestHooks/` の下に書き、`#if UITEST_HOOKS` で包む。Release には入れず、パッケージと拡張にも書かない。形は contracts/test-hooks.md。
- 識別子（accessibilityIdentifier）と文言キーは、design/001-reading-session.md の 6（要素と識別子）と 7（文言）を正とする。そこにない名前を作らない。
- 通信は国立国会図書館サーチの HTTPS だけ（ADR 0004、AC-103）。通信のコードは ReadingStore の1ファイルだけに置く。
- ログ（Logger）の書名、著者、一行、ISBN、検索の文字は、既定の非公開のまま。
- SwiftData は VersionedSchema で包む。出したあとは、変えるたびに版と MigrationStage を足す（ADR 0002）。
