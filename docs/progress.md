# 進捗ログ

指揮役（メインセッション）だけが書きます。セッションを始めたら、まずここを読みます。
関門を通ったとき、止まったとき、Takuma の返事を待つときに、「## 記録」のいちばん下へ1行ずつ書き足します。
古い行は書き換えません。セッションの最初に、最後の3行が表示されます。

1行の形：`- 日付 機能名 関門かステップ 結果 根拠のファイル`
例：`- 2026-10-09 001-sign-in G0 PASS docs/approvals/001-sign-in-G0.md`
例：`- 2026-10-10 001-sign-in G1 Takuma待ち デザインの色を決めてほしい（docs/reviews/001-sign-in-G1-design-reviewer-r1.md）`

## 記録
- 組織を導入した。最初の機能は Takuma が /feature で始める。
- 2026-10-21 全体 開始 Takuma の包括承認を記録。この依頼はブランチ claude/cool-ptolemy-17gnb3 で進める（環境は Linux、Mac なし） docs/approvals/000-takuma-standing-approval.md
- 2026-10-21 001-reading-session G0 r1 verifier PASS（要修正15件）、tech-lead FAIL（競合の URL をこの環境のネットワーク方針で開けず。裁定 docs/reviews/001-reading-session-G0-ruling.md）。pdm が直して r2 へ。Takuma に接続の許可を依頼中 docs/reviews/001-reading-session-G0-tech-lead-r1.md
- 2026-10-21 001-reading-session G0 PASS（tech-lead r2、verifier r2。競合 URL の確認は裁定で未検証）。Takuma の包括承認で承認 docs/approvals/001-reading-session-G0.md
- 2026-10-21 001-reading-session G1 デザインの判定 PASS（design-reviewer r2 16/16、tech-lead r2。CI でしか確かめられない動きは裁定 docs/reviews/001-reading-session-G1-ruling.md）。次は tech-lead の設計メモと契約 docs/reviews/001-reading-session-G1-design-reviewer-r2.md
- 2026-10-21 001-reading-session G1 PASS（design-reviewer r2 16/16、tech-lead r2、reviewer r2。CI でしか確かめられない動きは裁定 docs/reviews/001-reading-session-G1-ruling.md の一覧で G2 に送る）。次は verifier の受け入れテスト docs/reviews/001-reading-session-G1-reviewer-r2.md
- 2026-10-21 001-reading-session 受け入れテスト G2 r1 tech-lead PASS、reviewer FAIL（AC-23 を直した。残りはコンパイルと赤の実行で、CI でしか確かめられない）。draft PR https://github.com/matsuura-tak/reading-app/pull/2 を作成。Takuma待ち：app.json の commands（P-12）、ios.yml の timeout docs/reviews/001-reading-session-G2-tests-reviewer-r1.md
- 2026-10-21 001-reading-session 実装 G2 r1 reviewer FAIL（重大0件。コンパイルと CI を実行できないため。要修正1〜2と提案3、6、7、9、11、12、13 は c11db99 と 9e78bed で反映）。実装はコミット済みで Mac では未ビルド。Takuma待ち：app.json の commands、ios.yml の timeout。CI が緑になった HEAD で r2（テストとコード）、red.log、G3 docs/reviews/001-reading-session-G2-code-reviewer-r1.md
- 2026-10-22 001-reading-session CI設定 Takuma が PR #2 の保留解除作業を許可。app.json の commands と iOS ジョブの時間上限を修正し、Mac でビルドを検証中。所有者確認の org-guard は維持 docs/approvals/001-reading-session-ci-settings.md
- 2026-10-22 001-reading-session CI設定 実行確認：GitHub の plan と org-check が成功し iOS ジョブが起動。Mac の Debug/Release ビルド成功、iOS 26.0 単体テスト67件成功（失敗0・スキップ0）。全受け入れテストと G2 r2・G3 は未完了 docs/reviews/001-reading-session-ci-settings-verification.md
- 2026-10-22 001-reading-session G2 CI 初回の結果：807f934 の ios ジョブは ios_build（Xcode 26.6、警告0）と単体テスト67件が PASS、Acceptance の en_US で80本中35本 FAIL。verifier の仕分けでテスト側31本（主因は XCUIApplication.open による起動し直し）、実装の疑い1本（AC-35）、裁定2本（AC-56：1pt の要素を外す）。e43d611（verifier）、8034689（ios-engineer）で反映。次は CI の再実行と [AT-DIAG] の確認 docs/reviews/001-reading-session-G2-ci-ruling.md
- 2026-10-22 001-reading-session G2 Mac検証：AC-35 の保存再試行、AC-3 の追加画面再表示、AC-56 のホームの失敗表示を再現し修正。単体69件成功・失敗0・スキップ0、AC-35・AC-3・ホームの AC-56/57 が成功。全受け入れテストと G3 は未完了のため PR #2 は Draft。docs/reviews/001-reading-session-G2-mac-r1.md
- 2026-10-22 001-reading-session G2 Mac検証の続き：全体実行は成功28・失敗1で修正のため中断（全体成功に数えない）。AC-64 の保存ボタンを外枠と本体の2個に数える補助を修正し、AC-63/64 の日英6件が成功。英語の AC-3・31・35・47・ホームの56/57 も6件成功。画面の実行時警告と全受け入れテスト・G2 r2・G3 は未完了。docs/reviews/001-reading-session-G2-mac-r1.md
- 2026-10-22 001-reading-session G2 CI run 21（c9e7427）：ビルドと単体テスト PASS、Acceptance は en_US 80/80 PASS、ja_JP で AC-60・AC-62(b)・AC-63(a) の3本 FAIL（157/160）。ログは末尾5,000行しか取れず ja の文言は不明。verifier が run-acceptance.sh（要約をログの末尾に出す）を足した（2ed7279）。次は Makefile/CLAUDE.md の置き換え（tech-lead）と CI の再実行 docs/verification/001-reading-session/ci-runs/c9e7427-acceptance.md
- 2026-10-22 001-reading-session G2 CI run 22（cec65d5）：ビルドと単体テスト PASS、Acceptance は ja_JP 80/80・en_US 80/80 の160本 PASS（前回 ja で落ちた AC-60/62/63 も通過。原因は未確定で G3 で揺れを確かめる）。残る赤は ac18-reboot.sh の simctl shutdown（すでに Shutdown で code 405）だけ。verifier が直す。次の CI が緑なら G2 r2（reviewer のテストとコード） docs/verification/001-reading-session/ci-runs/
- 2026-10-23 001-reading-session G2 安定性の修正：run 23 は ja 78/80・en 80/80。AC-48 のスワイプ失敗を Mac でも再現し、1回の下向きジェスチャの起点と終点を明示。単一ラベル・消失の待機を標準APIに替え、AC-9 は StaticText で検索。日英各5回の計20回成功・失敗0・スキップ0、AC-18 の専用シミュレーター再起動も2段階成功。全体 CI・G2 r2・G3 は未完了。docs/reviews/001-reading-session-G2-stability-mac-r1.md
- 2026-10-23 001-reading-session G2 CI全体成功：6b979bb の run 39862607381 で Debug/Release、単体69件、受け入れ ja/en 各80件、AC-18 再起動前後の2段階まで成功。AC-5 の5回平均は両構成で0.5秒以下。Mac で既往失敗の AC-60/62 paused/63 reading を日英各5回、計30回成功・失敗0・飛ばした0。AC-39 の Bash 3.2 での表示エラーを7123291で修正し、正常・異常の判定を確認。設定3ファイルは PR #3 に分離して Takuma の確認・mainへの取り込み待ち。追加 HEAD の CI、G2 r2、G3 は未完了（シートの実行時警告も残る）。docs/reviews/001-reading-session-G2-ci-complete-r1.md
