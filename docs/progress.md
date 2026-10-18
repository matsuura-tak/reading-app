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
- 2026-10-16 001-reading-session Q8(a) designer の調査 済み。推す候補 A「伏せて読み始める」（ToRead にはないが、伏せるタイマーは JP3本・US2本ある）。Takuma の ToRead のメモと、違いを比べる相手の答え待ち design/001-reading-session-research.md
- 2026-10-16 001-reading-session G0 決定 違いは ToRead と比べる（1）。案 A「伏せて読み始める」を中心に pdm が PRD を作り直す。並行して tech-lead が案 A の実現性を調べる docs/approvals/001-reading-session-G0-Q8.md
- 2026-10-16 001-reading-session G0 Takuma待ち pdm が案 A で第1部を作り直した（推奨：形を変える。承認は ToRead のメモと Q9 のあと）。新しい事実（伏せるタイマーは2018年から、US に読書の Offshelf、ToRead は背面タップで始められる）で Q9 を聞く。tech-lead は案 A を作れると見たが、向きのロック中に伏せが届くかは実機でしか分からない（Q-A） docs/prd/001-reading-session.md の 8、17、18、docs/reviews/001-reading-session-G0-tech-lead-flip-research.md
- 2026-10-16 001-reading-session G0 決定 Q9 (a) 案 A で進める。実機の確かめを Takuma が行う（結果待ち）。pdm が PRD の後半（9〜16、18、G0 の前の確認）を作り直す docs/approvals/001-reading-session-G0-Q8.md
- 2026-10-16 001-reading-session G0 Takuma待ち PRD の作り直しが終わった（AC 40件、G3 と G4 に分けた）。G0 r2 は Takuma の実機の確かめ①〜③の結果を待って始める。承認には ToRead のメモも要る docs/prd/001-reading-session.md、docs/reviews/001-reading-session-G0-ruling.md
- 2026-10-16 001-reading-session G0 一時停止 Takuma が方向を問い直した（ニーズへの効き、埋もれる心配、日本になく海外で育つ分野、独自性と賞）。角度の調べもの（pdm 3体、designer、tech-lead。書かない）を始めた。実機の確かめと ToRead のメモは、案 A を続けると決まるまで保留 なし（調べものの報告は届いたら docs/reviews/ に保存）
- 2026-10-16 001-reading-session 方向の見直し Takuma待ち 調べもの5体がそろった。①②は日本にこの夏同じ形のアプリが出ていた（Pause、よみかえし）。③は OS と受賞作 Speechify と重なる。新しい候補は「音読の宿題」（pdm と designer が推す）と「毎日の名作」（Scroll The Bible 型）。どちらを確かめるかを聞く docs/reviews/001-reading-session-angles-*.md
- 2026-10-16 001-reading-session 方向の見直し 決定「音読の宿題」と「毎日の名作」を並べて1週間確かめる。designer が両方の画面案、pdm 2体と tech-lead が調べもの（書かない）。Takuma は小学生の親3人に問いを聞く docs/approvals/001-reading-session-G0-Q8.md
- 2026-10-16 001-reading-session 方向の見直し Takuma待ち 確かめの4体がそろった（pdm 音読・名作、designer 画面案6枚、tech-lead）。判定の材料は Takuma の聞き取り（親3人、大人3人）。期日の目安 2026-10-23 docs/reviews/001-reading-session-validate-*.md、design/explore/
- 2026-10-16 001-reading-session 方向の見直し 決定 課題を選び直す。Takuma が共感したのは 2 積読・次の1冊、4 長い文章が読めない、1 働いていると読めない。音読と名作は止めた。4体が調べもの（書かない） docs/approvals/001-reading-session-G0-Q8.md
- 2026-10-16 001-reading-session 方向の見直し Takuma待ち 課題の選び直しの調べもの4体がそろった。つまずきはスマホ（43.6%）と疲れ（38.9%）が大きく、迷う（3.6%、H25）は小さい。designer と pdm の推しは「疲れた夜の入口」を毎晩の中心にし、積読のカメラは本を読み終えたときの1回にする形 docs/reviews/001-reading-session-reselect-*.md
- 2026-10-16 001-reading-session 方向の見直し 決定「まだ決めない」。確かめを4つ行う（本棚の写真、7晩の記録、5人への聞き取り、10秒の動画の見比べ）。期日の目安 10/23 docs/reviews/001-reading-session-validation-plan.md
- 2026-10-16 001-reading-session 方向の見直し 確かめ4 試作ページを Artifact で公開した（Takuma だけが開ける。https://claude.ai/artifact/PaXtA3AiLPRSns13Q4xifw）。人に見せる前に、見せる順番の6通りの切り替えと、見出しの強さをそろえる直しを designer に頼んだ design/explore/concepts/
- 2026-10-16 001-reading-session 方向の見直し 確かめ4 試作ページを直して公開し直した（同じリンク、版2）。見せる順番を6通りから選べる（6人に1つずつ使えば、どの案も各位置に2回ずつ）。見出しは番号と比喩を外し、3つを同じ型にそろえた。designer が指示の外で直した2点（説明の2行、読み上げの頭の呼び名）は、そろえる目的に沿うので指揮役が受け入れた。「SNS」の語は場面そのものなので残す（指揮役の裁定）。Takuma の答えは順番1として数え、残りの5人に2〜6を使う。リポジトリに AGENTS.md、.agents/、.codex/ が 18:35 にできていた（役も指揮役も作っていない）。コミットに入れていない design/explore/concepts/
- 2026-10-18 001-reading-session 方向の見直し 指示 Takuma：「続きの一行」は機能の1つとしてあり。友人の読書、出版社と受賞、「これを読んだ人は」のおすすめ、簡単な登録を含め、目的に沿う機能を統合した体験を検討する。4体が調べもの（書かない） docs/approvals/001-reading-session-G0-Q8.md
- 2026-10-18 001-reading-session 方向の見直し Takuma待ち 統合の調べもの4体がそろった。4体とも、毎晩は続きの一行→伏せて読むだけにし、Takuma の4つは1冊を読み終えた夜に集める形を推した。v1 はサーバーなしで、友人と本当の「これを読んだ人は」は後の版。聞いたこと：製品の形、v1 の範囲、おすすめで欲しいもの、確かめの追加 docs/reviews/001-reading-session-integrate-proposal.md
- 2026-10-18 001-reading-session 方向の見直し 決定 製品の形は「夜の入口、本の出口」（画面は「一冊のしおり」）。v1 はサーバーなし。次の1冊は積読から選ぶのが先。確かめを3つ足す（文庫のページ5枚、7晩の記録に1項目、聞き取りに1問）。次は pdm が product.md と v1 の PRD を書く docs/approvals/001-reading-session-G0-Q8.md
- 2026-10-18 001-reading-session G0 判定中 pdm が product.md と v1 の PRD を書いた（1,008行、AC 91件。G3 で合否、うち25件に G4 の実機の確かめ）。G0 の判定を r1 から数え直す（裁定 7〜9）。tech-lead 2体と verifier が判定、並べて designer が統合した流れの絵コンテと主な画面を作る docs/prd/001-reading-session.md、docs/reviews/001-reading-session-G0-ruling.md
- 2026-10-18 001-reading-session G0 r1 FAIL tech-lead（その1 FAIL：名前のそろえ方、国立国会図書館のクレジット、2週に入らない、計測の同意、読み取りの初回の待ち／その2 PASS）、verifier（FAIL：決まりと AC の食い違い4か所ほか）。指揮役が確かめの計画に 1b と 2b の読み方と 1c を足した。Takuma待ち：期間と範囲、名義、実機の確かめの時期、残りの問い docs/reviews/001-reading-session-G0-prd2-*-r1.md
- 2026-10-18 001-reading-session G0 一時停止 Takuma：「お金にならないのは厳しい。ローカル AI を組み込む方向や他の方向をもう少し検討してほしい」。名義は個人、実機の確かめは承認の前、PRD の残りの問いは推奨どおり（課金の Q5 は返事1を優先して未決）。聞き取りに問い5を足した。収益の筋、ローカル AI、ほかの方向を4体が調べる（書かない）。G0 の直しは止める docs/approvals/001-reading-session-G0-Q8.md
- 2026-10-18 001-reading-session 方向の見直し 探り designer が v1 の絵コンテ（8コマ）と主な画面10枚を作り、Artifact で公開した（Takuma だけが開ける。https://claude.ai/artifact/RFFVa2GyoNJpX48XjQqrgh）。収益とローカル AI の調べもの4体は作業中 design/explore/integrated/
- 2026-10-18 001-reading-session 方向の見直し 再開 収益とローカル AI の調べもの4体が、利用量の上限（13時に戻る）で途中で止まった。決まりどおり SendMessage は使わず、同じ指示で新しく4体を呼び直す。前の体の作業用ファイル（scratchpad の money-pdm、ai-direction-pdm、ai-tech、ai-designer）は確かめてから使ってよいことにした
