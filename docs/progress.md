# 進捗ログ

指揮役（メインセッション）だけが書きます。セッションを始めたら、まずここを読みます。
関門を通ったとき、止まったとき、Takuma の返事を待つときに、「## 記録」のいちばん下へ1行ずつ書き足します。
古い行は書き換えません。セッションの最初に、最後の3行が表示されます。

1行の形：`- 日付 機能名 関門かステップ 結果 根拠のファイル`
例：`- 2026-10-09 001-sign-in G0 PASS docs/approvals/001-sign-in-G0.md`
例：`- 2026-10-10 001-sign-in G1 Takuma待ち デザインの色を決めてほしい（docs/reviews/001-sign-in-G1-design-reviewer-r1.md）`

## 記録
- 組織を導入した。最初の機能は Takuma が /feature で始める。
- 2026-10-15 001-reading-session 開始 着手 依頼「読書の時間（本を選んで読み始め、静かで美しい画面で読み、終えると時間が残る）」
- 2026-10-15 001-reading-session G0 r1 FAIL（verifier 重大2、tech-lead その1 重大1、その2 重大2。pdm が直して r2 へ） docs/reviews/001-reading-session-G0-verifier-r1.md、docs/reviews/001-reading-session-G0-tech-lead-r1.md
- 2026-10-15 001-reading-session G0 Takuma待ち pdm の推奨が「作らない（今の範囲と形のままでは）」に変わった。18 の Q8（作るか、形を変えるか、やめるか）を聞く。第2部の直しと r2 は Q8 の答えまで止める docs/prd/001-reading-session.md の 8、17、18
- 2026-10-15 001-reading-session G0 Q8 決定 (a)「違いを先に決める」。designer が差をつける点の候補を調べる。Takuma が ToRead を3回試してメモを送る。両方がそろったら pdm が PRD を作り直す docs/approvals/001-reading-session-G0-Q8.md
