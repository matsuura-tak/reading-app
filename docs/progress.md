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
