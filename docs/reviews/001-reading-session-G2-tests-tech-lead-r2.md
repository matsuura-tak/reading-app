FAIL

# 受け入れテストの補助レビュー r2（2026-10-23）

tech-lead の独立した文脈での読み取りレビューを、指揮役が要約保存した。対象は `0a45a49..274adc0` のテストと設定。進行中の S5 の製品修正は対象外。正式な G2 r2 PASS の代替にはしない。

## 指摘

- 重大（証拠の未完了）：`docs/verification/001-reading-session/evidence/red.log:85-86` は、最初の macOS 実行の出力を追記する指示のまま。テスト後半の `2c0d980..274adc0` で変更0。現在のコンパイルと正常実行はCIで確認できたが、実装前にUIテストが機能不足で落ちたという履歴証拠は未確認。現在の緑を過去の赤の証明にせず、初回CIの実際の失敗理由と履歴上の不足を記録する必要がある。
- 要修正（手順の文書）：`docs/verification/001-reading-session/test-plan.md:153` と `ios/AcceptanceTests/ac18-reboot.sh:3` に iPhone 16 の古い呼び方が残る。実際は Makefile の iPhone 17 と run-acceptance.sh を使う。期待値を変えず手順をそろえる。
- 未確認（正式な判定役の条件）：このCodex環境で、修正を作った側と別モデルであることは確認できない。役と文脈を分けた補助レビューであり、craft-tech-lead の別モデル条件を満たしたとは記録しない。

期待値を弱める変更、未対応のAC、失敗後の再試行を合格にする設定は見つからなかった。

## 前回の指摘の追跡

| 前回の指摘 | 結果・証拠 |
|---|---|
| AC-23 のパーセントエンコード | 修正済み。TelemetryAndPrivacyAcceptanceTests:138-168でUTF-8から%XX/%xxを生成し、固定値・元の文字との違い・生の要求・JSONの値を確認 |
| target.yml の Unit 重複 | 修正済み。target.yml:35-41はAcceptance/AC18のみ、project.yml:107-109にUnitとdefaultPlan |
| AC-18 の終了コードだけの合格 | 修正済み。ac18-reboot.sh:55-65,134-139で各終了0とExecuted 1 test / 0 failuresを必須化 |
| 3計画と既定計画 | 実行上解消。Unit/Acceptance/AC18RebootをCIで実行 |
| threshold_min の型 | 修正済み。TelemetryAndPrivacyAcceptanceTests:217-218でStringとして確認 |
| JSONのUnicodeエスケープ | 修正済み。同150-168でキーと入れ子も検査 |
| AC-5 の計測値 | 計測値が2構成分存在。test-plan:158に5回の平均値を別途判定する手順 |
| AC-21 途中の権限ダイアログ | 強化。同78-108でuserTracking追加、割り込み監視と失敗記録 |
| AC-3 貼り付け失敗の見落とし | 修正済み。LibraryAcceptanceTests:64-70で空・placeholderでない前提を確認 |
| AC-4 必ず通るタップ数比較 | 修正済み。同92-116で実際の3タップ後の状態と題名を確認 |
| listener の並行性 | 修正済み。TelemetryReceiver:2-14,61-64,74-79に理由とlock |
| 未使用の文言 | 一部対応。再試行の文はnoteRetryLabelで記録。他の整理は提案 |
| コンパイルと現在の実行 | 修正済み。9f32800でUnit69、Acceptance160、AC18の2段階成功 |
| 実装前のUIの赤 | 未完了。red.logの6章が未追記 |

## 証拠

- `git log --reverse -- ios/AcceptanceTests` で最初のテストコミット `037a276` と後半 `2c0d980`、後続7コミットを確認。`git show 274adc0:...` と `git diff 2c0d980 274adc0` で固定対象を読んだ。
- `274adc0^{tree}` と `9f32800^{tree}` はともに `be58df05dd7fe22a3be8147f050cc8f52a6b91b7`。検証済み9f32800とツリー同一。
- 対象24ファイルを全体まで読了：test-plan、Acceptance/AC18Rebootの両計画、target.yml、SupportのAcceptanceTestCase/AppSession/Fixture/L10n/TelemetryReceiver/UIHelpers、Testsの全11ファイル、ac18-reboot/ac39-xcstrings/run-acceptanceの3シェル。PRD、design、test-hooks/data-model/telemetry/seedの契約、r1レビュー2件、CI裁定・Mac検証・全体CI記録、Makefile、project.ymlも照合した。
- PRDのAC67個、Swiftメソッド82本、AC-39のシェルを含むAC番号67個。不足・余分・重複メソッド名0。test-planに全82メソッド名がある。各ACの対応と実行数は `001-reading-session-G2-ci-complete-r1.md` の表と一致した。
- UITEST名12個が契約内、識別子と動的識別子の前方53種類がdesign/test-hooks内。契約にないもの0。
- Swift/計画のXCTSkip、XCTExpectFailure、@testable、xfail、UIのsleep、テストのretry/repetition設定0。Acceptanceの除外はAC18の2本だけで、別計画のselectedTestsと一致。
- 直接existsの16行は、診断・選択・移動8行と結果の補助確認8行。存在確認だけで終わるACはない。
- 差分のアサーション追加18・削除12。削除は以下の置換か、必ず通るタップ数比較の除去であり、個別に確認した。
- Fixture、seed Schema/例、telemetry契約はr1から変更なし。3シェルのbash -nと差分のgit diff --checkは終了0。
- AC-39を自分で実行：翻訳不足0、PASS、終了0。負の対照のコピーはaction.continueのenのstateだけがneeds_reviewになっており、他の検査器・シェル・InfoPlistは同一。自分で実行して不足1、FAIL、終了1を確認した。

### 重要な変更の照合

- AppSession:114-125のsystem.openはT16のURLと適用数照合を維持。test-hooks:45とCI裁定に根拠があり、起動し直しでseed/reset/失敗数が再投入される問題への対応。
- UIHelpers:86-93,147-157のcontrol/buttonCountはButtonの有効性・個数を確認する変更で、AC63/64の期待1と0個の確認を維持。
- 同120-137のreplaceTextは消す位置を修正し、空と入力結果の確認を追加した。期待値を変える再試行ではない。
- 同10,29-43のWaitは単一ラベル・消失を標準APIへ置換。10秒の上限・期待値を維持し、時間切れ後の一致も失敗のまま。
- AC9はStaticTextに絞るが、件数2、ページ72、24%、進んだ32、再起動保持を削っていない。
- AC48はバーからの1回のジェスチャ。キャンセルへの代用・閉じるまでの反復はなく、PRDとdesign 6(d)の起点・結果を維持。
- AC39は変数境界を明示しただけで、Pythonの判定・0件条件・非0終了を維持。
- AC18は二重停止を避けた後、boot/bootstatusを通り、RESET/SEEDなしの後半で確認。CIの状態ログも一致する。

### 実行結果の読み取り

`/private/tmp/reading-app-pr2-ci-9f32800.log` を自分で解析した。2720行にUnit69、18217-18218行にja/en各80/0/0。生のTest Case passedは162行、固有82メソッドでソースとの差0（通常80メソッド各2回とAC18の各1回）。18312行に前半終了0、18441-18442行に後半終了0とpassed 2 of 2。AC5の実測5値も2構成分あり、すべて0.5秒未満。前の6b979bbの同じ全体成功も照合した。

既存summary JSONも直接確認：AC9/48は20回成功、両構成10回、失敗0・飛ばした0。AC60/62 paused/63 readingは30回成功、両構成15回、失敗0・飛ばした0。トップレベルの固有テスト数2/3と実行数20/30を区別した。

## 未検証と限界

- 実装前にUIが機能不足で落ちたという履歴証拠、正式な別モデル条件。
- 今回はフルテスト・反復・再起動を再実行せず、既存CIと結果を読んだ補助レビュー。
- G3の全高リスク5回、全画面・全状態、アクセシビリティ監査、探索、S5の進行中の製品修正は対象外。
- 元チェックアウトも作業コピーも書き込まず、コミット・push・端末操作もしていない。

## 記録

- 関門：G2テスト側のr2用の補助レビュー
- 役：tech-lead（Codexサブエージェント、別の文脈。別モデルの保証なし）
- 対象：274adc0固定
- 日付：2026-10-23

## 訂正の追跡（同日）

verifierが初回macOS CIの実ログを読み、red.logの6章とhistory-807f934.logに失敗69回の開始・最初のエラー・終了を補記した。指揮役も抜粋224行を完全ログの原本行と照合し、改変・不足0を確認した。現行のiPhone 17・run-acceptance.sh・結果保存先へ手順をそろえ、ac18-reboot.shは機種名コメントだけを訂正した。test-plan末尾の赤の確認は未完了のチェックへ訂正した。

未追記と古い手順は訂正済み。実装前のUI赤実行の履歴不足と、正式な別モデルレビューの条件はこの訂正でも未解決であり、上のFAILをPASSに変更しない。現在の全体CI成功は実装前の赤の代替ではない。
