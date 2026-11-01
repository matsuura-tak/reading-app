PASS

（観点：設計。対象：fc844a7...ae6956e、001-reading-session G3 の契約の直し。重大 0、要修正 3、提案 4。要修正は ios-engineer が H33 と W-3 の見本に着手する前に、契約の文を直してから渡すことを勧める）

## 指摘

### 要修正
1. **contracts/test-hooks.md:596（H33「本番」）と docs/adr/0005-test-hooks.md:146** — 「読み込みの関数に置く止める所も `#if UITEST_HOOKS` で包む」は、止める対象の読み込みが置かれている場所と合わない。`store.load`、`storekit.*`、`catalog.lookup` などの読み込みはローカルパッケージ `ReadingStore`（`ios/ReadingKit/Sources/ReadingStore/ReadingDataStore.swift`）にあり、`UITEST_HOOKS` は `ios/ReadingApp.xcodeproj/project.pbxproj:544,565` のアプリのターゲットにしか定義がない（`ios/ReadingKit/Package.swift` に `swiftSettings`/`define` なし）。既存の H7 も同じ事情で、パッケージ内の `consumeFailSave(for: "store.load")`（ReadingDataStore.swift:791、979）は `#if` なしの実行時の門で、アプリ側の `#if UITEST_HOOKS` のコーディネータ（UITestHookCoordinator.swift:88-89）が設定するだけ。契約 1-1 の19行（「ローカルのパッケージとウィジェットの拡張には置かない」。e8fa4eb、2026-10-20）とも矛盾する。このまま渡すと、ios-engineer がパッケージに `UITEST_HOOKS` の define を足す（SwiftPM では Release でも有効になり、ADR 0005 の「Release から完全除外」が崩れる）か、1-1 違反かの二択になる。
   - 直す方向：H33 の「本番」を H7 と同じ形に書き直す。「止める門は `ReadingStore` の読み込みの関数に実行時の門（`consumeFailSave` と同じ形。既定は素通り）として置き、設定するのはアプリの `#if UITEST_HOOKS` の中だけ。Release は門を設定する入口を持たないので止まらない」。ADR 0005 の追記にも同じ文と、「Release バイナリに門の関数は残るが型名は `UITestHook` で始めない／nm 検査の対象外」を書く。
2. **contracts/test-hooks.md:431（H22 `reading` の「『終える』ボタン（`liveActivity.end`）は描くが、見本の中では押しても何もしない」）** — 仕組みが決まっていない。拡張の本物の View は `Button(intent: EndReadingFromActivityIntent())`（ios/ReadingWidgetExtension/ReadingWidgets.swift:370）で、同じ型をアプリの中で描くとアプリ内でも intent が実行される（`EndReadingFromActivityIntent` は両ターゲットに入る ReadingAppIntents.swift:30）。撮影中に誤って押すと読書の状態が変わる。
   - 直す方向：共有する View が「終えるの操作」を引数で受ける（拡張は `Button(intent:)`、見本は何もしないクロージャ）と契約に書くか、「押しても何もしない」を消して「テストは押さない」に変える。
3. **contracts/dependencies.md:21（Apple のフレームワーク表の SwiftUI の行「ReadingCore（W-1、W-2 の View）」）** — 今回の決定（ADR 0005 追記の案1：View は「アプリと拡張の両方のターゲットに入る1つのファイル」、案3 のパッケージ配置は不採用）と食い違う。実際に `ios/ReadingKit/Sources/ReadingCore` に `import SwiftUI` も `: View` も0件。行自体は d9b050a（2026-10-25）からある既存の記述だが、この差分で dependencies.md を触り、設計を確定したのに直っていない（文書の更新漏れ）。
   - 直す方向：SwiftUI の行の「使う所」を「アプリ、ウィジェットの拡張（W-1〜W-5 の View は両ターゲット共有の1ファイル。ADR 0005 追記）」に直す。

### 提案
4. **test-hooks.md:410（`.contentMarginsDisabled()` を W-1・W-2 の本物の Widget に付ける）** — 見本の都合で本物のウィジェットの余白の決め方が変わる（今は `.padding` なし、ReadingWidgets.swift に `padding(16)` は Live Activity のみ）。契約に「View の `padding` はシステム既定の余白と同じ値にする」と一言足し、G4 の実機確認の項目に「余白が変わっていない」を入れる。
5. **Makefile:69-78** — `check-contracts` は `SCHEMA_PYTHON` を差し替えても必ず `contracts-venv` を通る（別の Python を使いたいときも venv を作る）。`SCHEMA_PYTHON` を明示したときは venv 作成を飛ばすか、コメントにその挙動を書く。実害なし。
6. **test-hooks.md:1（見出し「H1〜H32」）** — 本文は H33 まで足したのに見出しが古い。
7. **既存**：拡張の View の「しおり」「いま読んでいる本はありません」「今夜の読書を始める」が Localizable を通らない直書き（ReadingWidgets.swift:102,155,233,368 ほか。BASE より前）。見本を共有すると英語の撮影でそのまま出るので、ios-engineer の直しの機会に文言キー化を勧める（判定に数えない）。

### 指示書で頼まれた反論への答え
1. **W-1〜W-5 の View の共有（案1）**：反論を立てて潰した。(a) 本物の見た目：`ReadingLockScreenWidgetView` は `@Environment(\.widgetFamily)` で inline/circular/rectangular を分けている（ReadingWidgets.swift:187,201）が、ファミリーを引数で受けて拡張側が環境から渡せば描画は変わらない。変わるのは `.contentMarginsDisabled()` の余白だけ（提案4）。(b) 大きさ・起動：WidgetKit と ActivityKit はすでに `ReadingStore` から link 済み（SnapshotStore.swift:3-4、ReadingDataStore.swift:5-6）で、新しいフレームワークの読み込みは増えない。View の型は `-uitest-widget-show` の起動でしか生成されず、AC-100/AC-114 の起動経路には入らない。(c) もっと軽い案：`ReadingCore` に置く案は、View が `ThemePalette`/`ThemeTypography`（ThemeTokens.swift、両ターゲット共有）と `EndReadingFromActivityIntent`（ReadingAppIntents.swift、両ターゲット共有）に依存するため、ADR の案3 の「一緒に移すことになる」という退け方は正しい。見本専用の View を残す案2は G3 r2 の2字欠けの原因そのものなので不可。→ 案1 で妥当。ただし要修正1・2。
2. **H33 が Release に入らないこと**：契約 1-1（12-20行）と ADR 0005 の構成表で `UITEST_HOOKS` は Debug/Perf のみ、Release は未定義（pbxproj:544,565 で確認）。ただし止める門の置き場所の記述が実態と合わない（要修正1）。AC に使わないことは test-hooks.md:570「使う AC：なし」と 596「速さの AC の起動には付けない」、CLAUDE.md の差分で明記。sleep なしは `hold.<対象>` の `waiting→held→shown→released`（h17-state.schema.json のパターン。`hold.unknown` は弾かれることを確認）で `shown` を待つ設計になっており、H19 の `hold`/`ocr.release` と同じ形。
3. **H8・H30 の通信なしの復元**：design/001-reading-session.md:473 の S-10 のオフライン列「購入の復元で通信がないときは知らせ `store.offline` を出す」と一致。PRD は AC-108（復元、通信あり）と AC-110（商品の取得が通信なし）しか決めておらず、PRD 173行「払えない端末、通信なし、取りやめ、返金を扱う」の範囲内。`restoreAttempts` は hook-config.schema.json:808,823 に既にある必須項目。食い違いなし。
4. **大きな版1の中で足すだけ**：受け入れテストが使うのは `-uitest-widget accessoryRectangular:172x76` 等（BookmarkAcceptanceTests.swift:46 ほか21か所）で、その文法は触っていない。`-uitest-widget-show` の旧形 `accessoryRectangular:172x76` は hook-config の `widget.show` でエラー0件（下の負のテスト）。`w3:waiting` 等が `hook.error` になるのは G3 撮影用クラス（WidgetAndActivityAcceptanceTests.swift:1171-1179）だけで、AC のテストではなく、作り手の報告も verifier への伝達を書いている。
5. **venv と AC-103**：AC-103 は「アプリのコードから外部への HTTP 通信」（PRD:1157-1160、G2 の grep は ios/ が対象）。`contracts/check-requirements.txt` は Package.resolved にも pbxproj にも現れず、dependencies.md は「契約の検査の道具（アプリの依存ではない）」の節で分けている。置き場所は `$(HOME)/.cache`（リポジトリ外）。反しない。
6. **`make check-contracts`**：下の証拠。既定の venv と、空のフォルダから作った venv の両方で終了コード 0。

## 証拠
- 対象：fc844a7...ae6956e、観点：設計（G3 の契約の直し）。`git diff --name-only fc844a7...ae6956e`：
  - [読んだ] CLAUDE.md
  - [読んだ] Makefile
  - [読んだ] contracts/check-requirements.txt
  - [読んだ] contracts/dependencies.md（差分と 1-45行）
  - [読んだ] contracts/hooks/h17-state.schema.json
  - [読んだ] contracts/hooks/h22-widget.schema.json
  - [読んだ] contracts/hooks/hook-config.schema.json
  - [読んだ] contracts/test-hooks.md（差分全体と 1-1、H8、H19、H22、H33、8章）
  - [読んだ] docs/adr/0005-test-hooks.md（追記全体と 1-60行）
  - [読んだ] docs/progress.md
  - [読んだ] docs/reviews/001-reading-session-G3-tech-lead-contracts-r2.md（データとして。判定の後に読んだ）
  - 背景として読んだ：docs/reviews/001-reading-session-G3-verifier-r2.md 全文、design-reviewer-r1 の先頭、PRD の AC-27/35/100/103/108/110、design/ 5 の状態表（447-474行）と 6 の識別子（505-510行）、ios/ReadingWidgetExtension/ReadingWidgets.swift 全文、ios/ReadingApp/UITestHooks/UITestHookOverlayWindow.swift 全文、UITestHookCoordinator.swift の該当行、ContentView.swift:15-45、ReadingAppIntents.swift:7-110、ReadingDataStore.swift:777-992、pbxproj のターゲット所属

### AC 対応表（この差分が触る AC と、使うつなぎ口・データ）
| AC | つなぎ口 | データ／要素 | 判定 |
|---|---|---|---|
| AC-27（172×76、153×68 で14字欠け0） | H22 `-uitest-widget`（不変）＋ `-uitest-widget-show accessoryRectangular:<幅>x<高さ>` | `hook.widget.canvas` の frame、`showcase.contentOverflow`、`renders.composition` | 契約で枠の実寸と欠け0を同時に確かめる形になった。可 |
| AC-35（170×170、148×148） | 同上 `systemSmall` | 同上 | 可 |
| AC-108（復元） | H30 `restoreOutcome`、H13 | `store.restore.done/none`、`restoreAttempts` | 通信ありの振る舞いは不変 |
| AC-110（通信なし商品取得） | H8、H30 | `store.offline` | 不変。復元の通信なしは design 473 に合わせて追加 |
| AC-99/101/102（監査） | H22 見本を `-uitest-readouts off` で撮る例外（1-5） | `hook.widget.showcase` | 監査に 1×1 要素が混ざらない。可 |
| AC-55/100〜102/114/115/149（速さ） | H33 は付けない（596行） | — | 影響なし |
| AC なし | H33 `-uitest-hold-load`、`yomuma.uitest.load.release` | `hook.state` の `hold.<対象>` | 置き場所の記述に矛盾（要修正1） |

### つなぎ口の表（エンドポイントの代わり。誰が呼べるか／信頼の境界／Release）
| つなぎ口 | 呼べるもの | 入口 | Release | 境界を越えるデータ |
|---|---|---|---|---|
| H22 `-uitest-widget-show` | テストの起動引数・設定ファイル | アプリ（`#if UITEST_HOOKS`） | 入らない（pbxproj:565 Perf のみ定義、Release は未定義） | App Group の写し（既存の読む関数）。外部なし |
| H33 `-uitest-hold-load` | テストの起動引数のみ（設定ファイル不可：585行） | アプリの入口はあるが止める門は ReadingStore | 門の関数は残る（H7 と同じ）。契約の記述と不一致 → 要修正1 | なし |
| `yomuma.uitest.load.release` | Darwin 通知（同一端末の任意プロセス） | 1-4 | 入らない | 番号のみ。Release は受け口がない |
| H8/H30 復元の通信なし | 既存 | 既存 | 既存 | なし |

### 元に戻しにくい判断への反論と ADR の答え
| 判断 | いちばん強い反論 | ADR 0005 追記の答え | 見直し条件 |
|---|---|---|---|
| View を両ターゲット共有 | 本物の描画・余白が変わる、Release に未使用の型が残る | 「数 KB」「余白は View の padding」「G4 の実機で見る」と明記 | 「1ファイルで持てなくなったら案3」あり |
| H33 を止める方式 | Release への混入、読み込み関数の可読性 | `#if` で包む（実態と不一致：要修正1）、「`#if` が3か所を超えたら actor に」 | あり |

### 実行したコマンドと出力
- `git diff --name-only fc844a7...ae6956e` → 上の11ファイル（`--stat`：476 insertions, 23 deletions）
- `make check-contracts` → `ALL PASSED: 8 schemas, 28 examples validated with 0 errors.` EXIT=0（2回目も同じ、venv を作り直さない）
- `make check-contracts SCHEMA_VENV=/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/fresh/venv`（空のフォルダから）→ `creating … with /usr/bin/python3` / `jsonschema 4.25.1 referencing 0.36.2` / `ALL PASSED: 8 schemas, 28 examples validated with 0 errors.` EXIT=0
- 既定 venv の `pip freeze` と `contracts/check-requirements.txt` の diff → `SAME`（attrs 26.1.0、jsonschema 4.25.1、jsonschema-specifications 2025.9.1、referencing 0.36.2、rpds-py 0.27.1、typing_extensions 4.16.0）
- 負のテスト（venv の python -I、スクラッチパッドのスクリプト）：`showcase good: 0` / `surface=w3: 1` / `missing contentOverflow: 1` / `viewType lowercase: 1` / `widget.show family=w3: 1` / `widget.show old form: 0` / `widget.show liveActivity reading: 0` / `h17 hold.shelf.load matches: True | hold.unknown matches: False` / `h17 additionalProperties: False`
- `grep -n 'UITEST_HOOKS' ios/ReadingKit/Package.swift ios/ReadingKit/Sources …` → パッケージ側 0件。pbxproj:544 `"DEBUG UITEST_HOOKS"`、:565 `"UITEST_HOOKS"` のみ
- `grep -n 'func consumeFailSave' …ReadingDataStore.swift` → 791行（`#if` なし）。`store.load` の門は 979、1077行
- pbxproj：ReadingAppIntents.swift、ThemeTokens.swift、ReadingActivityAttributes.swift はアプリ（449-453行）と拡張（476-478行）の両 Sources に所属
- `grep -rln 'import SwiftUI' ios/ReadingKit/Sources/ReadingCore` → 0件
- `grep -rn 'WidgetKit\|WidgetCenter' ios/ReadingApp ios/ReadingKit/Sources` → SnapshotStore.swift:3-4,269-270（`#if canImport(WidgetKit)`）
- `grep -rn 'uitest-widget-show\|172x76\|w3:' ios/AcceptanceTests` → AC テストは `-uitest-widget` のみ（21か所）、`w3:waiting` 等は撮影用クラス（1171-1179行）のみ
- `git blame -L 19,19 contracts/test-hooks.md` → e8fa4eb（2026-10-20）、`git blame -L 24,24 contracts/dependencies.md` → d9b050a（2026-10-25）：どちらも BASE より前
- `git status --short` → `?? .agents/ ?? .codex/ ?? AGENTS.md`（差分外、未追跡）。`.venv/` はリポジトリ内に存在するが .gitignore:54 で除外（作り手の報告どおり Takuma が消す）

### 開いた規則・資料
- Web は開いていない（設計の観点で OWASP／Apple の審査要件の引用は不要と判断。ADR が引用する Apple の `widgetFamily` の get-only と Live Activity 160pt は、この判定には使っていない）。

### 未検証
- 案1（View の共有）が `make ios-build`（SWIFT_TREAT_WARNINGS_AS_ERRORS）で通るか、および `.contentMarginsDisabled()` で本物の W-1/W-2 の余白がどう変わるかは、ios/ が未変更のため確かめていない（ios-engineer の実装後に G2 の観点で見る）。
- `liveActivity:370x160`、`control:160x72`、`snippet:360x200` の実寸は G4 の実機で見るとされ、ここでは確かめていない。

## 記録（指揮役が保存するときに書き足す）
- 観点：設計。対象 fc844a7..ae6956e。日付 2026-11-02
- 指揮役の扱い：PASS だが要修正3件は ios-engineer の前に直す。tech-lead に直させ、狭い文の直しなので指揮役が差分で確かめる（裁定 22 と同じ扱い）
