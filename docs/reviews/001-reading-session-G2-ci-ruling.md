# 001-reading-session G2 CI 807f934 の結果に対する指揮役の裁定

- 日付：2026-10-22
- 対象：PR #2 の HEAD 807f934 の ios ジョブ（Acceptance、en_US の回。80本中35本が失敗）
- 入力：docs/verification/001-reading-session/ci-runs/807f934-acceptance-en.md（verifier の仕分け）、docs/reviews/001-reading-session-G1-ruling.md の (a)〜(g)
- 元に戻せる：すべて元に戻せる（コードと文書の変更だけ）

## 裁定
1. **AC-56（session.state.idle が2個）→ 実装で 1pt の要素（UITestMarker の状態の印）を外す。**
   - 理由：G1 の裁定 (a)「根の accessibilityIdentifier が XCUITest に見えるか」の答えが「見える」だった（S1、S3 で根の識別子と 1pt の要素の両方が見えて2個になった）。代わりの案は要らなくなった。PRD の Then は「状態は idle のまま」で、テストはそれを識別子1個で確かめる。
   - いちばん強い反論：根が見えたと確かめたのは S1 と S3 だけで、S4（積んだ画面）と S5（シート）は未確認。外して見えなければ、状態を確かめる多くのテストが落ちて CI をもう1回回す。
   - 反論への答え：S4 の識別子は S1、S3 と同じ RootView の根に付いており、同じ仕組みで見える見込み。S5 の根（FinishSessionView.swift:102）も同じ付け方。見えなければ次の CI の [AT-DIAG] の木で分かり、そのときだけ S5 に限って戻す。
   - 付随：ADR 0005 の 2026-10-21 の追記（2か所の例外）と contracts/test-hooks.md の T8 の備考は、要らなくなったので tech-lead が取り下げの追記を書く。
2. **T16（時計の URL の送り方）→ verifier の直し（XCUIDevice.shared.system.open）を採る。** contracts/test-hooks.md の T16 の備考「XCUIApplication.open(_:) で送る」を tech-lead が今の送り方に直す。system.open でも起動し直すか確かめのダイアログを押せないと次の CI で分かったら、契約にある代わりの案（uitest.clock.advance.<秒> のボタン）に替える。
3. **T6（計測の受け口 localhost）→ 今は T22 に替えない。** 計測の6本は受け口に届く前に原因Aで落ちており、localhost に届かない証拠がない。次の CI で届かなければ替える。
4. **AC-35（再試行の後に本の詳細が出ない）→ ios-engineer が実装を調べる。** verifier の指摘（rollback の後の2回目の save）を単体テストで再現し、不具合なら直す。再現しなければ、次の CI の [AT-DIAG] で判断する。
5. **AC-32、ReadingScreen の10本（ログの範囲外）→ 次の CI で判断する。** verifier の見立て（原因A、原因B）は［推測］のまま受け取る。
6. **ja_JP の回のログ→ 次の CI でも末尾しか取れないことを前提に、[AT-DIAG] と error の行で判断する。** 取れなければ Takuma に Mac での `make ios-test` の xcresult を頼む。

## 次の順
verifier（済）→ ios-engineer（1 と 4）→ tech-lead（1 の付随、2、設計メモ 10 の CI の事実）→ 指揮役が push → CI。
