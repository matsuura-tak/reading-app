PASS

## 指摘
パスはリポジトリからの相対で、行番号は HEAD 86022e3 のもの。

### 重大
なし。r1 の後に変わった16ファイルの中で、AC を満たせなくなる変更、データが消える変更、悪用できる穴、エージェントへの指示のような文、見えない文字は見つからなかった。

### 要修正
なし（基準は r1 と同じ）。

### 参考（判定に数えない）
- 参考1：app.json に貼るときのエスケープが書かれていない（CLAUDE.md:14-15）。ios_build にはバックスラッシュが3つあり（`\./`、`\.swift`、`uitest\.`）、そのまま JSON に貼ると壊れる（json.loads で「Invalid \escape: line 1 column 774」）。json.dumps で作れば元に戻る。P-12 のときに json.dumps で作った値を渡すことを勧める。
- 参考2：target.yml がないと generate が落ちることは、XcodeGen 2.46.0 のソース（Sources/ProjectSpec/SpecFile.swift:95、:100-105）で確かめられた。「推測」は「確認済み」に直せる。
- 参考3：設計メモ:268 の「まだ裁定にない」は古い（追記3の (i)〜(v) に入っている）。
- 参考4（未確認）：最適化したビルドでは15バイト以下の Swift の文字列の定数が strings に出ないおそれ。長い文字（readingapp-uitest、uitest.telemetry.log、UITEST_TELEMETRY_URL）で引き続き見つけられる。ソースの grep は `UITEST_` だけで `-UITest` は探していない。
- 参考5：`xcodebuild -version | grep -qE …` は SIGPIPE（141）でまれに落ちる形。出力は2行なので見込みは低く、追記3の (iii) で直せる。

### tech-lead が反論を求めた6点
- (a) .complete を entitlement で：妥当。entitlement が新しいファイルの既定を変えるとは Apple の文書に書かれていない（ADR 0001:21 の「推測、未確認」は正しい）。実機の確かめは追記3の (v)。勧め：単体テストで Library.store、-wal、-shm の .protectionKey を読む。
- (b) zip とチェックサム対 Mint：妥当。zip を取って計算した SHA-256 は記録の値と一致した。
- (c) target.yml まで CI が落ちる順番：G1 を止める理由ではない（追記2の要修正4）。勧め：verifier の最初の push は target.yml、Acceptance.xctestplan、ac18-reboot.sh の雛形だけにし、ビルドが緑になってから受け入れテストを足す。
- (d) AC-23、AC-53 を T2 に：妥当。
- (e) Debug と Release の2回ビルド：妥当。時間を測る申し送りがある（設計メモ:308）。
- (f) 単体テストのフォルダに UITEST_ を書けない厳しさ：妥当。読む関数が [String:String] を受け取り名前を定数から引けば試せる。

## 前回の指摘の追跡
| r1 | 結果 | 証拠 |
|---|---|---|
| 重大1 | 直った | ruling.md:30-41（(1)〜(10)）、:47-53（(i)〜(v)）。T4 の代わり UITEST_LOCALE（test-hooks.md:31）、T6 の代わり T22（test-hooks.md:49、telemetry.md:82、ADR 0003:50、ADR 0005:25）。確かめ（A）の9は裁定の (1) で未検証 |
| 要修正2 | 直った | ADR 0001:19-23、:37-43、設計メモ:206、:215、:222、CLAUDE.md:56。Apple の文書を開いて引用を確かめた |
| 要修正3 | 直った | (a) CLAUDE.md:19、Makefile:11。(b) 同じ行と ADR 0002:16。(c) ADR 0002:19-21、:50-51、設計メモ:279。論理を18通り試した |
| 要修正4 | 裁定で決まった | ruling.md:42-45、設計メモ:295 |
| 要修正5 | 直った | 2.46.0 と SHA-256 が ADR 0004:28-30、dependencies.md:19、CLAUDE.md:19、:21、Makefile:11、:14。zip の値も一致 |
| 要修正6 | 直った | ADR 0004:23、:51-52、:61、CLAUDE.md:38、:41 |
| 要修正7 | 直った | T1〜T7、T11〜T17、T19〜T22 が一致。違いは書かないと決めた T8〜T10、T18 だけ |
| 要修正8 | 直った | ajv-cli@5.0.0 の12か所が同じ版。dependencies.md:10、:20 |
| 提案9〜18 | 採った / 直った | ADR 0001:60、data-model.md:16、:36、設計メモ:87、:97、:166、:191、:287、:306、:308、ADR 0005:15-17、:38、:42、ADR 0004:26、xcstrings_untranslated.py:7、:44-45、`grep -rn '次の作業' docs/adr/` が0行 |

## 証拠
- 対象：BASE 41679463...HEAD 86022e3。観点は設計（G1）r2。`git diff --name-only 41679463...HEAD` の39件（r2 で差分と該当の節を読んだもの、r1 で全体を読み変更のないもの）。`git diff 6a35516...HEAD -- docs/prd/ design/` は0行。
- AC 対応表：設計メモの2に67行。照合で AC-1〜67 のすべてに T がある（missing: []）。r1 の後の変更は代わりの案を足すだけ。
- エンドポイントの表：Release の画面、Debug の起動の引数と UITEST_*、Debug の readingapp-uitest://、Debug の HTTPTelemetrySink と T22 の要素、OS のバックアップ。認可の空欄なし。
- 実行したコマンド（2026-10-21）：`make contracts-check` → 4行とも valid、exit 0。xcstrings_untranslated.py：good 0件、bad 6件（k.enTranslatedEmpty を数えた）、引数なし exit 2。`grep -rhoE 'ajv-cli@[0-9.]+'` → 12 ajv-cli@5.0.0。チェックサム7件、URL 7件が同じ。`wc -l CLAUDE.md` → 62。`git diff origin/main -- contracts/ | grep -cE '^-[^-]'` → 0。`npm view ajv-cli@5.0.0` → 5.0.0、MIT。XcodeGen の zip を取得（curl exit 0、4,278,764 バイト）し `sha256sum` が一致。ios_build / ios_test を偽物の xcodebuild などで `bash -eo pipefail -c` で18通り試し、すべて期待どおり（clean 0、チェックサム不一致 1、Screens に UITEST_ 1、YomutokiTests に UITEST_ 1、ios/build に UITEST_ 0、entitlement CompleteUnlessOpen 1、Xcode 16.4 は 1、27.1 は 0、Release に uitest.clock.applied 1、CFBundleURLTypes 1、xcodebuild 失敗 65、target.yml なし 1、ios_test clean 0、ac18-reboot.sh なし 127）。`bash -n` ok。JSON：ios_build はバックスラッシュ3（json.dumps で戻る）。2つの表の照合は T8〜T10、T18 以外すべて一致。秘密情報の grep 0。.claude/ と .github/ の変更 0。見えない文字 0。
- 開いた URL（2026-10-21）：XcodeGen 2.46.0 の zip、ProjectSpec.md（2.46.0）:88-89、SpecFile.swift:95、:100-105、com.apple.developer.default-data-protection.json、encrypting-your-app-s-files.json。
- 未検証：裁定の対象の外はなし。裁定にあり代わりの案があるもの（追記2の (1)〜(10)、追記3の (i)〜(v)、裁定1の (a)〜(g)、D-46、D-48、D-53）は G2 の最初の CI か G4 の前の Mac で確かめる。判定に関わらないもの：参考4（swiftc なし）、Mermaid の描画。

## 記録（指揮役）
- 関門：G1（手順8、設計）
- 判定した役：reviewer（model: opus。fable が上限のため）
- 回：r2
- 対象：BASE 41679463...HEAD 86022e3
- 日付：2026-10-21
- 指揮役の扱い：G1 通過。参考1（app.json の JSON のエスケープ）は Takuma への最終報告で json.dumps の値を渡す。参考2・3は設計メモの文言の更新として次の tech-lead の作業に含める。参考4・5は ios-engineer への申し送り。
