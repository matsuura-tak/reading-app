FAIL

## 指摘
パスはリポジトリからの相対。行番号は HEAD 6a35516 のもの。

### 重大
1. 重大：裁定の一覧に入っていない「Mac がないと確かめられない」項目が残っている。設計メモの確かめ（A）の9も満たしていない。
   - 場所：docs/adr/features/001-reading-session.md:280（確かめ（A）の9は [ ] のまま）、:232、:237-250（10 の未確認の表）、docs/adr/0003-telemetry-without-sdk-in-001.md:50、contracts/README.md:43、contracts/test-hooks.md:30（T4）、:32（T6）。
   - 根拠：docs/org/gates.md:11、:49。裁定（docs/reviews/001-reading-session-G1-ruling.md）に名前がある項目だけが G1 を止めない扱い。
   - 裁定にない項目：(1) XcodeGen を入れた出力とビルドの出力（確かめ（A）の9）、(2) D-60 の開き直し、(3) シミュレーターの名前「iPhone 16」、(4) 手で書いた xctestplan が -testPlan で動くか、(5) CODE_SIGNING_ALLOWED=NO で UI テストが動くか、(6) macos-latest の Xcode が 26 か、(7) T2 の環境変数の長さ、T16 の open で出る確認、T4 の -AppleLocale、T20 の signpost、(8) ビルドの設定の名前、(9) シミュレーターのアプリから localhost の受け口に届くか（ADR 0003:50、T6）、(10) contracts/README.md の4の macOS のコマンド。
   - 代わりの案がないもの：(9) T6 と (7) の T4 の -AppleLocale。(9) が CI で通らなければ、AC-20、AC-23、AC-24 のテストが今の形では作れない。
   - 直す方向：指揮役は上の項目を裁定の1に書き足す。tech-lead は T6（localhost に届かない場合。例：-UITest のときだけ、送ったイベントを並べた要素を accessibilityValue で出し XCUITest が読む）と T4（-AppleLocale が効かない場合）に代わりの案を足す。

### 要修正
2. 要修正：ADR 0001 のファイルの保護を .complete にしない理由（prewarm）が Apple の文書と合わない。場所：docs/adr/0001-local-storage-swiftdata.md:17、:33-34、:67、設計メモ:191、:200。Apple の文書（2026-10-21）：起動の順番「Prewarming creates your process and loads the libraries your app links against, then suspends your process without allowing any application code to run.」。ファイルの暗号化「Files containing personal information about the user … always warrant the strongest level of protection. Assign the complete protection level to user data files」「Assign the complete protection level to files that your app accesses only when it is in the foreground.」。001 はバックグラウンドの処理が0件。PRD 6 の害の行に「題名は好み、健康、信仰を表しうる」。直す方向：.complete にするか、.completeUnlessOpen を案に足して選び直す。既定のままなら Apple の文書で確かめた別の理由を書く。
3. 要修正：ADR が「CI で確かめる」としたことが、CI のコマンドに入っていない。(a) Release の strings と Info.plist の確かめ（ADR 0005:18、README:36-43、設計メモ:204、:209）が CLAUDE.md と Makefile にない。(b) ADR 0002:16「26 未満なら落とす」が、xcodebuild -version を出すだけで落とさない。(c) ADR 0002:38「iOS 17 は CI で受け入れテストを1回通す」の行き先がどのコマンドにもない。直す方向：ios_build に Release のビルドと strings の検査（PlistBuddy は `!` で反転）、Xcode の版の検査を足す。iOS 17 の1回の実行を足すか、いつ誰が確かめるかを ADR 0002 に書き直す。
4. 要修正：ios_test に受け入れテストを入れたので、ios-engineer の変更が G2 の「CI が緑」を満たせない期間ができる（CLAUDE.md:21、設計メモ:269）。根拠：gates.md:54-55。直す方向：雛形と実装の途中の変更に G2 をどう当てるかを設計メモの 11 に書き、指揮役の裁定を求める。
5. 要修正：XcodeGen の版を固定していない（ADR 0004:26、:31、:38-39、dependencies.md:18、CLAUDE.md:19、:21）。G2 の依存の基準は「版が固定」。直す方向：GitHub Releases の zip を版とチェックサムで入れるか、`mint install yonaskolb/xcodegen@2.46.0`。
6. 要修正：ADR 0004 で、受け入れテストを動かす設定（UI テストのターゲット、スキームのテスト計画、Info.plist の分け方）が ios/project.yml（ios-engineer が書く）に移ったことが書かれていない。CLAUDE.md:16 を一部満たさない。G2 でテストを弱める変更を探す対象に project.yml が入らない。直す方向：ADR 0004 の「結果」に project.yml はテストの設定として扱い G2 で全部読むと書く。XcodeGen の include で、受け入れテストのターゲットとテスト計画の定義を ios/AcceptanceTests/ の中の YAML に置くことを検討する（:REPLACE の点も ADR に）。
7. 要修正：T16 が AC-20、21、23、24、50、51 の対応表から抜けている（設計メモ:37、:38、:40、:41、:67、:68、test-hooks.md:42）。T3 だけでは実時間で待つことになる。表のずれ：AC-23 は設計メモで T1、test-hooks で T2。AC-6、40、42、46〜48、53 が T2 の使う AC にない。
8. 要修正：contracts-check で使う ajv-cli が contracts/dependencies.md になく、版も `@5` の幅（Makefile:16-19、README:25-28、CLAUDE.md:23）。直す方向：`ajv-cli@5.0.0` に固定して行を足す（npm view：5.0.0、MIT、2023-04-28）。

### 提案
9. ActiveReading.state の知らない値を読み込みの失敗にする決まり（data-model.md:39）への反論：題名や記録まで見えなくなり再試行でも直らない。v1.0 の前に ADR 0001 に前方互換の方針を書き、代わりの案（知らない値は paused として読む、など）と比べる。
10. 題名の形B（設計メモ:176、data-model:15）：整えた後に先頭100字を取ると末尾が空白になることがある。切った後にもう一度前後の空白を除くかを決めて書く。
11. 構成図（設計メモ:87-97）に OS のバックアップ（iCloud と Mac）を外のシステムとして足す。
12. つなぎ口を置くファイルの数が文書の間でそろっていない（ADR 0005:15、test-hooks:11 は1ファイル。telemetry.md:70 と図:113 は HTTPTelemetrySink を別の部品。README:38 の grep は UITestHooks.swift だけ）。
13. 読み込みで ActiveReading が2件見つかったときの扱いが data-model（:34-35）にない。
14. ADR の古い参照（0001:5、0002:5、0004:5 の「次の作業で書く」、0004:16）を直す。
15. Takuma が実機で使う7日間（ADR 0004:24）は Release（TestFlight）のビルドにすることを勧める。
16. xcstrings_untranslated.py は、en の state が translated で値が空のキーを通す。
17. AC-18 の2つのテストは skippedTests に入る（設計メモ:267）。G3 の「飛ばされていない」（gates.md:67）に対し、ac18-reboot.sh で動いた数を検証レポートで数える決まりを verifier に伝える。
18. CI の ios ジョブの上限は60分（ios.yml:52）。受け入れテストは約90本、AC-20 の30秒待ち×3、シミュレーターの再起動。最初の CI で時間を測り、超えそうなら Takuma に上限の変更を頼む。

## 証拠
- 対象：BASE 41679463...HEAD 6a35516。観点は設計（G1）。`git diff --name-only` の37件をすべて読んだ（印は元の報告のとおり。design/ は差分の行、ほかは全体）。一覧の外：gates.md、review-report.md、adr.md、G0 verifier r1・r2、G1 の裁定、G1 tech-lead r1・r2、app.json、ios.yml、reviewer.md。
- AC 対応表（1）：AC-1〜AC-67 のすべてに設計メモの2の行があり、データ、つなぎ口、計測で満たせる。足りないのは表の書き漏れ（指摘7）と CI でしか確かめられないもの（重大1）。
- エンドポイントの表：HTTP API なし（openapi.yaml なし）。Release の画面、Release の URL scheme なし、Debug の起動の引数と UITEST_*（XCUITest のランナーだけ。-UITest がなければ読まない）、Debug の readingapp-uitest://（-UITest のときだけ受ける）、Debug の HTTPTelemetrySink（区間と真偽だけ）、OS のバックアップ。認可の空欄なし。
- つなぎ口の表（2）：T1〜T20 はすべて contracts/ にある。T4 の -AppleLocale と T6 の localhost に代わりの案がない。
- 確かめ（A）：A1 満たす（67行、空欄0）、A2 満たす（バックアップが抜け：提案11）、A3 該当なし、A4 満たす（ajv を自分で動かした）、A5 満たす、A6 満たす（strings の確かめが CI につながっていない：指摘3）、A7 満たす（ファイルの保護の理由は誤り：指摘2）、A8 満たす、A9 満たさない（重大1）。確かめ（B）：5つとも形は満たす（案は 5+2、5、5、5、4）。中身の誤りと抜けは指摘2、3、5、6。
- tech-lead が反論を求めた6点：題名の形B は妥当（提案10）。XcodeGen の版は要修正5。ios_test に受け入れテストは要修正4。MetricKit を購読しないのは妥当（MXAppLaunchMetric は deprecatedAt 27.2「Use MetricResult instead.」を開いて確認）。state の知らない値は提案9。ファイルの保護は要修正2。
- 信頼の境界（5）：端末の中と Debug の受け口の2つで妥当。localhost は ATS が通す（NSAllowsLocalNetworking の文書を開いて確認）。ADR 0005 の作りは足りるが Release に入らないことを機械で確かめる手段が CI にない（指摘3 (a)）。
- 実行したコマンド（6）：`make contracts-check` → 13ファイル valid、exit 0。拒まれるはずの例（telemetry t1〜t7、seed s1〜s7）はすべて exit 1、正しい finishing の例は exit 0。`git diff origin/main -- contracts/ | grep -cE '^-[^-]'` → 0。xcstrings_untranslated.py：good → untranslated_keys=0、bad → 6件 exit 1（k.enTranslatedEmpty は数えられない）、引数なし exit 2、合うファイルなし exit 1。設計メモと test-hooks の T の照合：T1、T2、T3、T5、T15、T16、T17 にずれ（指摘7）。`wc -l CLAUDE.md` → 60。CLAUDE.md と Makefile のコマンドは同じ。`npm view ajv-cli@5` → 5.0.0、MIT、2023-04-28。秘密情報の grep → 0件。
- 開いた URL（2026-10-21）：nsallowslocalnetworking.json、about-the-app-launch-sequence.json、encrypting-your-app-s-files.json、mxapplaunchmetric.json、upcoming-requirements、XcodeGen の ProjectSpec.md（missingTestPlans、Include、:REPLACE）と CHANGELOG.md、describing-use-of-required-reason-api.json。
- エージェントへの指示のような文（7）：なし。見えない文字0件。
- 未検証（8）：裁定にあり代わりの案もあるもの（FAIL の理由にしない）。裁定にないもの＝重大1の (1)〜(10)。Mermaid の描画は試していない。

## 記録（指揮役）
- 関門：G1（手順8、設計）
- 判定した役：reviewer（model: opus。fable が上限のため）
- 回：r1
- 対象：BASE 41679463...HEAD 6a35516
- 日付：2026-10-21
- 指揮役の扱い：重大1は裁定に追記して閉じる（T4、T6 の代わりの案は tech-lead が足す）。要修正2〜8は tech-lead に直させ、r2 を回す。要修正4は裁定で決める。
