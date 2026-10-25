# 001-reading-session G0 承認

- 日付：2026-10-19
- 承認したもの
  - docs/prd/001-reading-session.md（コミット 9f7c5d9。AC 136件）
  - 同じ時点の docs/prd/product.md
- 判定の経過
  - G0 r1、r2：tech-lead 2体と verifier が判定した。r2 の「直さないと通さない」4件は、pdm が直し、指揮役が確かめた（裁定 15。docs/reviews/001-reading-session-G0-r2-fix-check.md）。
  - Takuma の決定で足した部分（App Intents とふりかえりの1行）：verifier と tech-lead が狭く2回判定し、2回目は2体とも PASS（裁定 18〜22）。
  - そのあとの直しは、指揮役が確かめた。
    - 最後の小さな直し：docs/reviews/001-reading-session-G0-intents-final-fix-check.md
    - Siri の答え方（Takuma の決定）：docs/reviews/001-reading-session-G0-siri-decision-check.md
  - 指揮役の裁定は 1〜23（docs/reviews/001-reading-session-G0-ruling.md）。Takuma の決定の記録は docs/approvals/001-reading-session-G0-Q8.md。
- 承認の直前に Takuma に伝えていたこと
  - PRD の直しは終わり、受け入れ条件は136件。
  - 承認のときに聞く予定だったこと：実機の確かめの結果の要約、18 の Q6。
  - アプリ本体のコードはまだなく、G1（デザインと設計）、G2（受け入れテスト）、実装の順に進む。
- Takuma の返事（そのまま引用）：

> 承認するので進めて、API 契約って何

## 指揮役の読み方
- 「承認するので進めて」は、条件の付いていない承認。「API 契約って何」は質問で、承認の条件ではない。
- **実機の確かめ**
  - 結果（①〜③ 伏せた向き、D1 ロック中のボタン、1c、1d、読む手すり）は、承認の時点で届いていない。
  - PRD の 8 の「条件：Q-A は G0 の承認の前に行う（Takuma の決定）」と、前の決定「承認の前に行う」（docs/approvals/001-reading-session-G0-Q8.md）は、この承認で置き換わったと読む。
  - 確かめは続ける。結果は届いた所から G1 以降で使う。使う所は次のとおり。
    - 伏せる道の形（①〜③）
    - 「終える」の案内の文（G1-15。D1）
    - 写真の道（1c）
    - v1.1 の抜き出し（1d）
  - PRD の文は変えない（承認のあとに PRD を変えるなら、承認を取り直すため）。
- **18 の Q6（強い保護の等級）**：PRD のとおり、G1 の ADR でその選択が出たときに、指揮役が Takuma に聞く。
- **手順からずれたこと**：/feature の G0 の 3（PRD の要約、判定の結果、決めてほしいことへの推奨を、承認の前に1通で送る）は、1通では送っていない。要約は、この承認のあとの返事で送る。

## 次
- G1 に入る。順は /feature の 5a〜8：designer の調査 → designer の仕様 → design-reviewer と tech-lead の判定 → tech-lead の設計メモ、契約、ADR → reviewer の判定。
- PRD の冒頭の進め方：まず芯の G1 を行い、その日数で速さを測ってから、v1.1 に回す所を決める（(i)〜(iii)）。

---

## G1 決定反映後の PRD 再承認（2026-10-25）
- 日付：2026-10-25
- 承認したもの
  - docs/prd/001-reading-session.md（コミット 2e26444。AC 149件）
  - 同じ時点の docs/prd/product.md
- 判定の経過
  - G1 途中での Takuma の決定（全部 v1.0 搭載、外部 API 通信0件＋Background Assets による NDL CC BY 書誌 DB 配信、表紙・背表紙・本棚写真・奥付・「あとで」登録、電子書籍の単位とスクリーンショット、次の1冊・この本のあとに・端末内の重み付け・共起テーブルの器）を pdm が1回で反映した。
  - verifier と tech-lead が狭い判定を行い、2体とも PASS（重大0件、要修正0件）。
    - docs/reviews/001-reading-session-G0-prd3-verifier-r1.md
    - docs/reviews/001-reading-session-G0-prd3-tech-lead-r1.md
- Takuma の承認（2026-10-25、docs/approvals/001-reading-session-G1-decisions.md よりそのまま引用）：

> 全て承認で良いので推奨案で進めてください。基本的には体験としてより良く、価値を最大化して届けられるものになればどんどんブラッシュアップしていただいて問題ないです。必ずユーザーの課題を解決し、レッドドット賞やグットデザイン賞を取れるレベルのアプリまで磨き上げてください。（後ほどポートフォリオに載せます）
> 権限周りで不足があればトークンを無駄にしたくないのですぐに依頼してください
> アプリ開発におけるガードレールとして法的リスクは最大限遵守し申請が必要になる外部APiを踏むなどのリスクを踏むようなことはしないでください。
> 基本的にはアプリが完成したら再度確認させてください。FBします
