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
- 2026-10-23 001-reading-session G2 設定差分を解消：Takuma が設定PR #3をマージ（main 0e2c062）、274adc0で機能ブランチに取り込み、保護設定の差分0・手元のorg check/guard成功。9f32800の全体CIも単体69・日英160・再起動2段階まで成功。S5をライト・ダーク・AX5・英語で実際に確認し、キーボード上の保存の文字の欠けと英語時の日本語題名の四角表示を観測。実装担当が再現・修正、技術担当がテスト側の補助レビューを継続中。G2/G3は未完了。docs/reviews/001-reading-session-G3-s5-visual-r1.md
- 2026-10-23 001-reading-session S5表示を4125f7cで修正：キーボード保存の文字の欠けとダーク上部保存の黒字を既存トークン・標準ボタンの2行変更で解消し、ライト・ダーク・AX5・英語の前後画像で確認。Debug/Release、単体69件、AC9/48/63-readingの日英計6件が成功（再試行なし）。英語単独での日本語題名の四角は独立した標準UIKit/SwiftUIでも再現し、(en,ja)では全文表示。既存の実行時レイアウト警告と別環境の確認は残る。テスト補助レビューの未追記記録・古い実行手順をverifierが訂正中。正式なG2/G3完了とはしない。docs/reviews/001-reading-session-s5-implementation.md
- 2026-10-23 001-reading-session 検証記録を訂正：verifierが初回macOS CI 807f934の失敗69回の最初のエラー等を実ログから補記し、224引用行を原本と照合。現行iPhone 17・実行スクリプト・結果保存先へ手順を統一。実装前UI-redは未実行の履歴不足として残し、チェックを未完了に訂正。正式レビューとG3は引き続き未完了。docs/reviews/001-reading-session-G2-tests-tech-lead-r2.md
- 2026-10-23 001-reading-session 再開：6442fe2の最新全体CIが14:01 JSTに成功。Debug/Release・単体69・日英各80・AC18前後成功、org-check/guardも成功。AC5平均0.0866852/0.0760372秒、AC39別実行も成功。新しい一時cloneを復元。追加判定担当の利用上限による停止を記録し、合格扱いにせず、指揮役が画面/監査の実行を代行中。docs/reviews/001-reading-session-G2-ci-6442fe2.md
- 2026-10-23 001-reading-session G2コードr2 PASS：利用枠復帰後、独立reviewer gpt-6-solが6442fe2のiOS実装・単体・設定を通読し前回指摘の解消、AC対応、弱体化/秘密情報/依存/Release非混入と全体CIを照合。コード観点に未検証なし。テスト観点・G3の確認は別に継続。docs/reviews/001-reading-session-G2-code-reviewer-r2.md
- 2026-10-23 001-reading-session G2テストr2 PASS（裁定後の通常G2）：reviewer gpt-6-solとtech-lead gpt-6-astraが同じ6442fe2の全23ファイル/67AC/82メソッドを独立照合し、欠落・弱体化・実行対応不備なし。実装前UI-red不足は維持し過去PASSを遡及せず、完成HEADを通常G2で評価する裁定を記録。時計URLとUI sleep0/CLI状態待ち1の文書誤記を訂正。G3監査に指摘が残り、PRはDraftのまま。docs/reviews/001-reading-session-G2-ruling.md
- 2026-10-23 001-reading-session S2追加のdarkラベルを修正：G3画像で黒字を確認し、S5と同じ既存onAccentをTextへ1行追加。Debug/Release・単体69・AC2/42/49日英計6件が成功、コンパイラ警告0。保存処理・条件・識別子・恒久テスト変更0。修正後4条件の再撮影をverifierが担当中。docs/reviews/001-reading-session-s2-implementation.md
- 2026-10-23 001-reading-session S2局所確認完了：verifierの修正後ライト/ダーク/AX5/英語4件が成功、黒1474画素が同位置で白へ変化し背景一致。reviewer gpt-6-solとtech-lead gpt-6-astraの1行差分判定もPASS。未コミット修正の限定結果と6442fe2の全CIを区別し、G3全体はFAILを維持。docs/reviews/001-reading-session-G2-s2-label-reviewer-r1.md
- 2026-10-23 001-reading-session G3標準対照：標準SwiftUIだけの画面でもdynamicType/contrast指摘が再現。S3の削除方法A/B/C対照でもhitRegion/nil各3件を再現したが、対象要素と原因の帰属は未確定。失敗を除外せず全原本を保存。実画面のdesign-reviewer判定と次の反復/探索を継続する。docs/reviews/001-reading-session-G3-native-controls-r2.md
