# 指揮役の裁定 001-reading-session G0

- 日付：2026-10-21
- 対象：docs/reviews/001-reading-session-G0-tech-lead-r1.md の重大1件（競合の URL を1件も開けず、引用を確かめられない）
- 根拠：docs/approvals/000-takuma-standing-approval.md（「権限周りで引っかかるようだったらすぐに伝えて」「推奨で進めて」）、.claude/rules/org.md（返事を待つ間は、元に戻せる作業だけを進める）

## 何が起きたか
この作業環境（Claude Code のクラウド）のネットワーク方針が、apps.apple.com、itunes.apple.com、red-dot.org、web.archive.org と、レビューを引用した第三者のページ（applion.jp、makeheadway.com、justuseapp.com など）への接続を拒んでいる（プロキシが CONNECT に 403）。開けるのは developer.apple.com と api.github.com だけ。pdm も tech-lead も、競合のページを1件も開けなかった。

G0 の合格条件「競合の URL を1件以上開き、引用した不満がページにあるかを確かめる（tech-lead）」は、PRD をどう直しても、この環境では満たせない。r2 を回しても同じ点で FAIL になる。

## 裁定
1. この1件は「未検証（環境のネットワーク方針）」として記録し、G0 を止める理由にしない。ただし G0 の承認の記録（docs/approvals/001-reading-session-G0.md）に、未検証のまま進めたことを明記する。
2. 代わりに pdm は、開いて確かめられていない引用を、すべて外すか［推測］に下げ、それに頼っていた結論（E-5、O-1 を選んだ理由、4.3(b) の「Bookmory との違い」）を、開いて確かめた根拠か［推測］だけで書き直す。引用を残すなら「（抜粋。ページは開いていない）」の印を付けたまま、結論の支えにしない。
3. Takuma に、この環境のネットワークの許可（apps.apple.com、itunes.apple.com、web.archive.org、red-dot.org、applion.jp、makeheadway.com、telemetrydeck.com、github.com）を頼む。許されたら、G1 の間に tech-lead が競合の URL を開いて引用を確かめ、結果を docs/reviews/ に追記する。G5（審査提出前）までには必ず確かめる（pdm が Red Dot の要項を開き直す段取りが product.md の 9 にある）。
4. この裁定で進める作業（G1 の設計、受け入れテスト、実装）はすべて元に戻せる。main へのマージ、ストアへの提出、課金は Takuma だけが行うので、未検証の引用が後で誤りと分かっても、取り返せない結果にはならない。

## いちばん強い反論と、それでも進める理由
- 反論：競合の不満の引用は、何を作るかの根拠なので、確かめずに進めると、まちがった前提の上に2週分の作業を積む。
- それでも進める理由：001 の中身（読んだ時間とページを端末の中に残す、広告なし、権限なし）は、競合の個別の引用に頼らず、開いて確かめた根拠（審査ガイドライン 4.3(b)、プライバシーの定義）と、文化庁の調査の数字（抜粋）で立っている。引用が外れても変わるのは位置づけの文言で、作るものの形は変わらない。Takuma が接続を許せば、G1 の間に確かめ直せる。
