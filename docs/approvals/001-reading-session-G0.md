# 承認 001-reading-session G0（PRD 承認）

- 日付：2026-10-21
- 対象：docs/prd/001-reading-session.md と docs/prd/product.md（コミット 7809c64d18414eb98aca54caacb1386d881b0772）
- 判定：tech-lead r1 FAIL → r2 PASS（docs/reviews/001-reading-session-G0-tech-lead-r1.md、-r2.md）、verifier r1 PASS（要修正15）→ r2 PASS（docs/reviews/001-reading-session-G0-verifier-r1.md、-r2.md）。指揮役の裁定：docs/reviews/001-reading-session-G0-ruling.md
- 承認の根拠：Takuma の包括承認（docs/approvals/000-takuma-standing-approval.md）。この依頼の最初に Takuma が書いた返事をそのまま引用する。

## Takuma の返事（2026-10-21、そのまま引用）

> このリポジトリで作成しているアプリを完成させて。
> 私に確認する部分は全て承認しますので推奨で進めて。
> アプリとしてできたらレビューします。権限周りで引っかかるようだったらすぐに伝えて。
> 現状稼ぐことかつレッドドット賞をとるのが指標なので変に今のAPIの案に縛られずよりあったものを検討し進めて

条件は付いていないので、承認として扱う。個別の問いへの返事はまだないため、下の「決めたこと」は、PRD 18 の推奨の列をそのまま採った（「推奨で進めて」）。Takuma が後で別の答えを返したら、その点だけ PRD を直して承認を取り直す。

## 決めたこと（PRD 18 の推奨どおり）
| # | 決めたこと |
|---|---|
| P-1 | アプリの形は A「読む時間の道具」。D「一文を集める」は 004 として取り込む |
| P-2 | 対象の国は JP（主）と US。言語は ja と en |
| P-3 | 課金は買い切りの Pro（¥2,000／US$12.99）。v1.0 から売り、2027-05-01 に見直す |
| P-4 | Red Dot は Brands & Communication Design の Apps 区分に1件。2027-02-01 の判定で Early Bird か Regular を選ぶ |
| P-5 | Red Dot の予算は上限 €2,700＋VAT。受賞したら Regular の Winner Package まで払う。それより上の段はそのとき Takuma が決める。支払いは Takuma |
| P-6 | アプリ名は「よむとき」（英語 Yomutoki: Reading Time）。同名のアプリの有無は App Store Connect で登録するときに確かめる |
| P-7 | 計測の送り先は TelemetryDeck を第一候補。G1 までに無料枠と端末 ID の扱いを確かめられなければ、001 は差し替え口だけで SDK を入れず、003 で決め直す |
| P-8 | v1.0 は 001〜003 と Pro を 2027-01-31 に公開する目標 |
| P-9〜P-14 | Takuma の操作か返事が要る（下の「Takuma にしかできないこと」）。推奨どおりに進める準備をする |
| 001-1 | 001 を単独で App Store に出さない（内部の TestFlight まで） |
| 001-2 | 週の始めは端末の暦の設定に従う |
| 001-3 | 1分未満の読書は記録しない |
| 001-4 | 知人5人への聞き取りは任意。聞けなくても進める |

verifier r2 の Q3・Q4、tech-lead r2 の追加の質問は、推奨どおりに PRD に反映した（AC-27 を3状態に、AC-46、P-14）。AC-27 の `finishing` の通りは、終える入力がホームを覆う形なら「やめてから」（AC-17 と同じ）とする。これは G1 で designer が形を決めたあとに verifier が test-plan で読む。

## 未検証のまま進めること（裁定1）
- 競合の URL を1件も開けず、引用した不満がページにあるかを確かめていない（この環境のネットワーク方針）。PRD では、開いていない引用をすべて［推測］に下げ、結論の支えから外した。Takuma が接続を許したら G1 の間に tech-lead が確かめ、遅くとも G5 の前に pdm が Red Dot の要項と一緒に確かめ直す。

## Takuma にしかできないこと（まとめて1通で頼む）
1. この環境のネットワークの許可：apps.apple.com、itunes.apple.com、web.archive.org、red-dot.org、applion.jp、makeheadway.com、telemetrydeck.com、github.com（環境の設定の Network access）。
2. P-9：Apple Developer Program に Account Holder として入っているか（入っていなければ 2026-11-10 までに）。
3. P-10：Family Controls の配布の申請（001 の G1 で bundle ID が決まり次第。目安 2026-11-10）。
4. P-11：持っている iPhone の機種。
5. P-12：.claude/org/app.json の commands（ios_build、ios_test）に、G1 で tech-lead が出す値を書く。
6. P-13：TelemetryDeck の新しいアカウントの無料枠（接続が許されれば tech-lead が確かめる）。
7. P-14：Mac と Xcode を持っているか。

## 追記（2026-10-21、G1 の途中）：AC-47〜AC-55 と 18 の 5
- 対象：docs/prd/001-reading-session.md のコミット d8bdc9015fed2e48b95c81b1e8a4d2f0443e7ea5（AC-47〜AC-55、10 の題名の上限と検索を置かないこと、18 の 5）。
- 経緯：G1 のデザイン仕様（design/001-reading-session.md）が決めた画面の動き（終える入力のキャンセル、保存の後の画面、読み込みの失敗）に PRD の AC がなかったので、pdm が足した。AC-1〜AC-46、13、14 は変えていない。
- 承認：Takuma の包括承認（docs/approvals/000-takuma-standing-approval.md）に基づき、18 の 5（題名の上限は100字）を推奨どおりに決め、追記を承認の範囲に含める。
- 再判定の扱い：G0 の判定役を呼び直さず、G1 の判定で覆う。tech-lead は G1 の構成の判定（手順6）で AC-47〜AC-55 の実現性を見る。verifier は受け入れテストを書くとき（手順9）に AC-47〜AC-55 のテスト可能性を見て、決められない AC があれば止まって報告する。design-reviewer は仕様の2章の対応表に AC-47〜AC-55 があるかを見る。
