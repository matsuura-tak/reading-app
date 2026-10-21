FAIL

## 指摘
判定の理由は2つ。(1) 重大が1件ある。(2) 82本の XCUITest は、コンパイルも「赤」の実行もこの環境では確かめられない（未検証の1）。重大1を直して macOS の CI で一度動かし、出力を red.log の 6 に貼れば r2 で判定できる。

- 重大1 ios/AcceptanceTests/Tests/TelemetryAndPrivacyAcceptanceTests.swift:122-126（AC-23）。パーセントエンコードした形の数えが働いていない。`addingPercentEncoding(withAllowedCharacters: .alphanumerics)` は「坊っちゃん」を変えずに返す（.alphanumerics は L*、M*、N* を含み、5文字はすべて Lo）。結果、3つのアサーションは UTF-8 の「坊っちゃん」を数えるだけで、`%E5%9D%8A…` の形は一度も探していない。前提 `!encodedUpper.isEmpty` も通る。根拠：PRD AC-23 の Then、test-plan 2 の AC-23 の行、Apple の文書「Returns a character set containing the characters in Unicode General Categories L*, M*, and N*.」。直す方向：UTF-8 のバイト列から自分で作る（`Fixture.botchan.utf8.map { String(format: "%%%02X", $0) }.joined()` → %E5%9D%8A%E3%81%A3%E3%81%A1%E3%82%83%E3%82%93）。前提は「元の文字と違う」「この文字に等しい」にする。
- 提案1 ReadingSessionAcceptanceTests.swift:33-48（AC-5）：基準値のない measure は落ちないので0.5秒に自動の合否はない。G3 の検証レポートで5回の値と平均を貼ることを決めておく。
- 提案2 TelemetryAndPrivacyAcceptanceTests.swift:79-94（AC-21）：SpringBoard のアラートを数えるのは手順の区切りの4か所だけ。addUIInterruptionMonitor で割り込みを記録して XCTFail する。.userTracking もリセットに足す。
- 提案3 LibraryAcceptanceTests.swift:64-66（AC-3）：貼り付けが黙って失敗すると空文字の例と同じになる。貼り付けの後に欄の value が空でないことを見る。
- 提案4 LibraryAcceptanceTests.swift:90-114（AC-4）：`XCTAssertLessThanOrEqual(taps, 3)` は手順で決まった数なので必ず通る。注に書くか消す。
- 提案5 Support/L10n.swift:33-34、45-80、97-98：使われていない定数（actionStart、actionContinue、errorSaveFailed*、errorRetry*、readingState*）。使って「どの操作の再試行か」まで確かめるか、消す。
- 提案6 Support/TelemetryReceiver.swift:8、33、56、70：@unchecked Sendable の理由のコメントがない。listener は lock の外で読み書き。
- 提案7 target.yml:37-38：Unit.xctestplan が並び、include で2回並ぶおそれ。どちらが持つかを tech-lead と決める。
- 差分の中にエージェントへの指示のような文はない。

## 証拠
- 対象：BASE 0a45a49...HEAD 2c0d980。観点は受け入れテスト（G2、verifier の変更）。23ファイルを全部全体を読んだ。読んだファイル：PRD（全部）、design の 1、2、6、7、10、contracts/ の test-hooks.md、telemetry.md、README.md、seed.schema.json、data-model.md、gates.md の G2 と G3、G1 の裁定、設計メモの 11、ADR 0004・0005、review-report.md。
- 表1 AC 対応表：AC-1〜AC-67 のすべてに、テスト（ファイル:行）、確かめている結果、Then の値との一致（AC-23 だけ不一致：パーセントエンコードを数えていない）、design 7 の文字と L10n の一致（カーリークォート、アポストロフィ、one/other、桁区切りまで全部一致）。要素の有無だけのテストはない。
- 表2 テストを弱める書き方：差分の中の受け入れテストと設定 21（すべて ios/AcceptanceTests/ の中）。.claude/ と .github/ 0。skip の類は test-plan の文1件のみ。アサーション +131/−0。本番のコードのテスト用の分岐 0（ios/ は AcceptanceTests/ だけ）。sleep 0。skip 3（xctestplan の skippedTests と説明のコメント）。xfail、XCTExpectFailure、@testable 0。retry 51（アプリの再試行の識別子とキー、AC の中身を表すテスト名、注記1行。動かす側の再試行は0）。表示の文字や並び順 17（識別子の前方一致と design 6 (b) の代わりの案。並び順は UIHelpers.swift:224 の1か所で理由がある）。
- 表3 test-plan の確かめ：1〜7 は満たす。8 は AC-39 の赤は自分で再現（exit 1、String Catalog がない）。XCUITest の82本は red.log の 6 が空で、満たさない（未検証）。
- 表4 契約との一致：UITEST_ の名前は契約の12個。seed は Fixture.swift から自分で11個を作り ajv で全部 valid、data-model の制約の違反0、libraryOfFive は seed.example.json と一致。受け口は telemetry.md:75-80 と合う（/events、/flushed、204、30秒、localhost、T22 の切り替え）。
- 表5 設定：target.yml は bundle.ui-testing、依存、SWIFT_VERSION 6.0、excludes。Acceptance.xctestplan は ja_JP と en_US、random、keepAlways、screenshots、再試行なし、skippedTests は AC-18 の2本。AC18Reboot.xctestplan は ja_JP で AC-18 の2本。ターゲットの ID は XcodeProj 9.14.0 の .xcode 形式で再現。ac18-reboot.sh は bash -n 通り、set -euo pipefail、再試行なし、落ちたらその終了コード。ac39-xcstrings.sh も bash -n 通り。
- 表6 Swift の読み：明らかな文法の誤りなし。XCUITest の API は知られている形（XCUIProtectedResource.camera は未検証）。Swift 6 の並行処理で止まりそうな書き方は見つからず（理由のコメントがないのは提案6）。
- 実行したコマンド：git diff --name-only の grep → 21。.claude/.github → 0。skip の類 → 1。アサーション → 131 +。テスト用の分岐 → 0。`git ls-files ios | grep -v AcceptanceTests` → 0。sleep 0、skip 3、retry 51、@testable 0、表示の文字 17。UITEST_ の comm → 0。PRD と テスト名の AC の comm → 0（67個、func test_AC 82個）。bash -n 2本 → exit 0。ac39-xcstrings.sh → FAIL、exit 1。xctestplan の JSON の読み → ja_JP/en_US、repetition False、random、skipped AC-18。unicodedata → 5文字とも Lo。mkseeds.py → 11個、違反0、libraryOfFive 一致。ajv → 11個 valid。md5 → DC1C774817D8D1F9A3D54A52 一致。
- 開いた URL（2026-10-21）：characterset/alphanumerics（JSON）、xctest/handling-ui-interruptions、xcuiprotectedresource（取得できず）、XcodeProj 9.14.0 の ReferenceGenerator.swift、registry.npmjs.org。
- 未検証：(1) XCUITest 82本のコンパイルと赤の実行（red.log の 6 が空）。(2) XCUIProtectedResource.camera。(3) CI でしか確かめられない動き（session.state.*、システムの部品の識別子、swipeDown、open の確認、localhost、-AppleLocale、約3KB の環境変数、-testPlan、include の testPlans、CODE_SIGNING_ALLOWED=NO、ac18 の2回目のデータ、XcodeGen の識別子の形、OSSignposter と XCTOSSignpostMetric）。(4) XCTest が SpringBoard のアラートを自分で閉じるか。(5) org-check の CI の状態。

## 記録（指揮役）
- 関門：G2（verifier の変更：受け入れテスト）
- 判定した役：reviewer（model: opus。fable が上限のため）
- 回：r1
- 対象：BASE 0a45a49...HEAD 2c0d980
- 日付：2026-10-21
- 指揮役の扱い：重大1と tech-lead r1 の要修正3件を verifier に直させる。未検証(1)（コンパイルと赤の実行）は CI（macOS）でしか閉じられず、CI は Takuma が app.json の commands を書くまで動かない。直した版を push して draft PR を作り、Takuma の P-12 の後に CI の出力を red.log に足して r2 を回す。その間は裁定（G1 の追記2 の要修正4）のとおり、元に戻せる作業（ios-engineer の実装）を進める。
