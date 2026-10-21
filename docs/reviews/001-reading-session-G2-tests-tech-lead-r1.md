PASS

## 指摘
- 要修正（verifier）、ios/AcceptanceTests/target.yml:35-38：Unit.xctestplan が target.yml の testPlans に入っている。設計メモ 11（docs/adr/features/001-reading-session.md:301）では ios-engineer が project.yml に Unit.xctestplan を defaultPlan として書く決まり。XcodeGen の include は配列を後ろに足すだけで重複を消さず、SpecValidation.swift:235-242 も存在と「既定の計画が2つ以上」しか見ない。決定：Unit.xctestplan は project.yml の側だけに defaultPlan: true 付きで書く。target.yml には Acceptance.xctestplan と AC18Reboot.xctestplan だけを残す。35-36行のコメント「どちらにも付けなければ最初の計画（Unit）が既定」は誤り（include では target.yml が先に合わさり project.yml が上に重なる）。既定の計画は project.yml の defaultPlan で決まる、と書き直す。
- 要修正（verifier）、ios/AcceptanceTests/Tests/TelemetryAndPrivacyAcceptanceTests.swift:122-126：AC-23 の「パーセントエンコードした形で0回」を実際には確かめていない。.alphanumerics は Unicode の L*、M*、N* を含み、「坊っちゃん」の5文字は Lo なので変換されない。直す方向：許す文字を ASCII の英数字と -._~ だけにし、前提として encodedUpper == "%E5%9D%8A%E3%81%A3%E3%81%A1%E3%82%83%E3%82%93" を確かめる。根拠：PRD AC-23 の Then。
- 要修正（verifier）、ios/AcceptanceTests/ac18-reboot.sh:36-54、67：「passed 2 of 2」は xcodebuild の終了コードだけを見て出しており、動いたテストの数を数えていない。xctestplan のターゲットの ID か -only-testing の名前が合わないと0本のまま成功で終わる見込み。直す方向：run_one で出力を tee で残し `Executed 1 test, with 0 failures` を grep するか、xcresult の数を確かめる。G3 までに直せばよい。
- 要修正（tech-lead、次の作業で書く）、CLAUDE.md:20 と docs/adr/features/001-reading-session.md:301-302、308：AC18Reboot.xctestplan（3つ目の計画）は認める。CLAUDE.md の ios_test の説明に AC18Reboot を足す。設計メモ 11 の testPlans の行で、Unit は project.yml の defaultPlan、Acceptance と AC18Reboot は target.yml と書き、include の順の説明を直す。ios-engineer への決まり：project.yml の name は Yomutoki のまま（xctestplan の ID がこの名前から作られる）。スキーム Yomutoki は最上位の schemes: に書く。CI の時間の見積もりと Takuma に頼む内容を書く。
- 提案、TelemetryAndPrivacyAcceptanceTests.swift:176：threshold_min は `as? String == "60"` で確かめる。
- 提案、同 :121-139：JSON の \uXXXX で題名が書き出された場合に備え、読み込み直した events の全部の値にも題名が0回であることを足す。
- 提案、Support/TelemetryReceiver.swift:2、8：@preconcurrency import Network と @unchecked Sendable に理由のコメント。
- 提案、test-plan.md の 5：G3 で xcresult の実行数（Acceptance 160本＝80×2、AC18Reboot 2本）を確かめる行と、AC-5 の0.5秒を xcresult から取り出すコマンド。

## 証拠
- 対象：BASE 0a45a49...HEAD。23ファイル（ios/AcceptanceTests/ と docs/verification/001-reading-session/ の外は0件）。
- コマンド：UITEST_* の comm → 契約にない名前0件。識別子の文字を design と test-hooks に grep → 見つからないもの0件。PRD の AC 67個とテストの名前の AC 67個の comm → 空。func test_AC は82本、重複0。`.exists` で Wait. を使わないのは8件（補助の確かめ）。禁止の書き方の grep → target.yml:34 のコメント1行だけ。`bash ios/AcceptanceTests/ac39-xcstrings.sh` → FAIL（.xcstrings がない）、exit 1。ios.yml:51-52 は macos-latest で60分。app.json の commands は3つとも空。unicodedata で「坊っちゃん」は5文字とも Lo。urllib.parse.quote → %E5%9D%8A%E3%81%A3%E3%81%A1%E3%82%83%E3%82%93。XcodeGen 2.46.0 の Scheme.swift:641-645、SpecValidation.swift:235-242 を取得。md5("NT_PBXNativeTarget-Yomutoki-YomutokiAcceptanceTests_1") の先頭24文字＝DC1C774817D8D1F9A3D54A52 で xctestplan と一致。
- 1. つなぎ口の表：-UITest、-AppleLanguages/-AppleLocale、UITEST_LOCALE、UITEST_TIME_ZONE、UITEST_RESET、UITEST_SEED（version 1、UUID 小文字、allOf、durationSeconds 最小90）、UITEST_NOW/CLOCK_FROZEN、UITEST_FIRST_WEEKDAY（1、2）、UITEST_FAIL（12通り、1つの操作だけ）、UITEST_TELEMETRY_URL/CONTROL_URL（localhost、127.0.0.1 なし）、UITEST_TELEMETRY_TIMEOUT=3、UITEST_TELEMETRY_LOG と uitest.telemetry.log、受け口（POST /events、/flushed、204/500/30秒）、T16（advance 3〜900、set、uitest.clock.applied を待つ）、T8、T20、T14、T11、T12 — すべて契約と一致。ACCEPTANCE_LANG と ACCEPTANCE_TELEMETRY_PATH はテストを動かす側だけ。
- 2. AC ごとの表：AC-1〜AC-67 のどの行も値か数か状態まで確かめている。要素の有無だけのテストはない。AC-23 だけ一部不足（パーセントエンコードが空振り）。AC-5 の0.5秒は signpost を測り G3 で xcresult を読む。
- 3. 設定：target.yml は ADR 0004 と合う（ターゲット、依存、Bundle ID、iOS 17.0、Swift 6.0、excludes、:REPLACE 0件、スキーム Yomutoki の testPlans）。testPlans のパスは include の相対。Unit は project.yml 側だけに決めた。xctestplan の ID は md5 と一致（前提：プロジェクト名 Yomutoki、XcodeProj の .xcode 形式。写しの出どころは未確認。最初の CI で pbxproj の ID と照らす）。AC18Reboot.xctestplan を認める。ac18-reboot.sh は CLAUDE.md の呼び方と合い、再試行なし。
- 4. red.log：この環境では実行できない。落ちる理由は「project.yml とアプリがまだない」か「識別子が見つからない」。app.json の commands が空なので ios.yml の plan が落ち、赤の実行もできない（P-12）。AC-39 の赤は自分でも再現。
- 5. CI の時間（推測）：Acceptance 160本で53〜107分、ビルド5〜8分、単体2〜3分、ac18 4〜6分、ios_build 6〜10分。合計70〜135分で timeout-minutes: 60 を超えるおそれが高い。Takuma に頼む：ios.yml:52 を 150 にするか、ジョブを分ける（app.json の commands も分ける）。ios_test の頭に `bash ios/AcceptanceTests/ac39-xcstrings.sh &&` を足すことも勧める。縮める案（未確認）：-parallel-testing-enabled YES。
- 6. verifier の7点：(1) Swift 6 は Xcode のひな形と同じ形で問題になりそうな行はない（CI で確かめる）。(2) AC-48 の swipeDown はナビゲーションバーで正しい。閉じなければ press(forDuration:thenDragTo:)。(3) 文字で探す部品は届く見込み。(4) isEnabled の KVC は動く見込み。だめなら "enabled == %@"。(5) T16 の set は契約どおり。(6) AC-31 の10000 は欄にそのまま入るのが正しく、切ったら実装の誤り。(7) AC-39 は G3 で手で動かす形を認める。CI に入れるなら Takuma。
- 7. 未検証（G2 の例外と裁定の範囲）：コンパイルと実行、xctestplan の ID、-testPlan、swipeDown、識別子、isEnabled、open の確認、localhost、-AppleLocale、再起動後のデータ、CI の実際の時間、XcodeProj の写しの出どころ。これら以外に未検証はない。

## 記録（指揮役）
- 関門：G2（verifier の変更：受け入れテスト）
- 判定した役：tech-lead
- 回：r1
- 対象：BASE 0a45a49...HEAD 2c0d980
- 日付：2026-10-21
- 指揮役の扱い：要修正3件は verifier に直させる（reviewer の判定と合わせて1回で）。tech-lead の要修正1件は次の tech-lead の作業で。CI の時間は Takuma への依頼に加える。
