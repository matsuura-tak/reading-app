FAIL

# PR #2 の Mac 検証と追加修正

- 日付：2026-10-22（日本時間）
- 検証環境：Xcode 27.1、iPhone 17 シミュレーター、iOS 26.0。
- 対象：Claude の修正 ba8b82a・059a6dc と、その後に追加した保存・画面表示の修正（6f714ed、0cda7b6、3710550）、テスト補助の修正3c3f790。
- この記録は G2・G3 の最終合格を示さない。全受け入れテストと画面確認は引き続き必要。

## 指摘と対応

1. **AC-35：保存に一度失敗すると再試行も失敗する。修正済み。**
   - Claude が追加した単体テストを Mac で実行し、3ケースの失敗を再現した。rollback で無効になった新しい ReadingSession が Book の逆参照に残り、次の保存で必須属性が nil の記録を再挿入しようとした。ログは NSCocoaErrorDomain 1560（内訳1570）。
   - LibraryStore.finishSession は、rollback の前に新しい記録の book 参照を外し、前の lastPage を戻す。既存の save・rollback・エラー通知と、成功後だけ画面用の値を更新する順序は維持した。変更は 6f714ed。
   - 同じ単体テスト69件がすべて成功。ディスクへ保存したケースは、記録がちょうど1件増え、再起動に相当する別コンテナで開いても3件残ることまで確認した。
   - 画面の AC-35 も成功（38.913秒）。
2. **AC-3：追加画面を閉じた後、再び開かない。修正済み。**
   - 空の題名を試してキャンセルした後、ホームの追加ボタンを押しても追加画面が出ないケースを Mac で再現した。
   - AddBookView のキャンセル・破棄は、表示元の router.isAddBookPresented を false にして閉じる。変更は 0cda7b6。
   - AC-3 の全7種の空白入力、無効ボタン、保存されないこと、毎回のキャンセルと再表示、起動し直しても本0冊を確認した（136.672秒）。
3. **AC-56：ホームで読み始めの保存に失敗した後、エラー表示が残らない。修正済み。**
   - 同じ画面テストで error.saveFailed が存在せず、ホームが通常表示のままになることを再現した。失敗時の要素の木を取得済み。
   - HomeView の onDisappear でエラーを消すと、画面の再構成でも消える。router.path が空ではなくなり、実際に別画面へ移ったときにだけ消すよう変更した。
   - AC-56（ホームで保存失敗、待機状態を維持）と AC-57（再試行時刻から読書開始）がともに成功。2件成功・失敗0、終了0（24.378秒、33.692秒）。
   - 同じ本の詳細からの AC-56・AC-57 も2件とも成功。詳細画面のコードは変更していない。
   - ホームの失敗画面と再試行後の画面を実際に開き、説明・再試行ボタンが欠けず、再試行直後が0:00であることを確認した。画像は `docs/verification/001-reading-session/evidence/mac-20261022/home-start-save-failed.png` と `home-start-retried.png`。この2枚だけで全状態のデザイン審査を完了したとは扱わない。
4. **AC-63・AC-64：保存ボタンを外枠と本体の2個に数える。修正済み。**
   - 3710550 の全体実行は、29件完了（成功28・失敗1）の時点で修正のため中断した（終了75、TEST INTERRUPTED）。全体成功には数えない。唯一の失敗は AC-64 の `session.finish.save` の全種類の要素数が2になること。取得した要素の木には同じ識別子の Other と中の Button が1つずつあり、ページ72、分10、エラーと再試行ボタンは残っていた。
   - 根拠は PRD の AC-63・AC-64 と design/001-reading-session.md の3・6章（S5 のツールバーの保存ボタン）。「保存ボタンが1つ」の判定なので `buttonCount` で実際の Button を数える。2つの保存ボタンがあれば2と数え、期待値1を維持する。識別子が外枠だけなら中の Button を数える。
   - AC-63 の reading / paused、AC-64 の計3ケースを両言語で実行し、6件すべて成功、失敗0・スキップ0、終了0。期待する状態、時間、ページ数、記録件数、エラーの有無は変更していない。
   - 二重に数えた要素の木の抜粋は `docs/verification/001-reading-session/evidence/mac-20261022/toolbar-save-hierarchy-before.txt`。

## 既存の修正の確認

- T16 の XCUIApplication.open は起動を伴い、seed と失敗回数が初期化され、画面が戻ることを Mac でも再現した。XCUIDevice.shared.system.open への変更後、AC-5 と AC-6 が成功。
- ツールバーの book.save は、同じ識別子を持つ Other と Button が存在し、Other は有効・Button は無効と実測した。Claude の control ヘルパーは実際の Button を判定するため、期待値の緩和ではない。
- 入力置き換えのカーソル位置と空欄確認の修正後、AC-31 と AC-47 の失敗が解消した。
- 受け入れテストの期待する記録件数・時間・ページ数を、この追加修正に合わせて変更していない。

## 実行の証拠

| 検証 | 結果 | ローカルのログ・結果 |
|---|---|---|
| Claude の追加単体テストを含む69件、修正前 | 3ケース失敗 | `/private/tmp/reading-app-pr2-latest-unit2.log` |
| 同じ69件、保存処理修正後 | 成功69・失敗0・スキップ0、終了0 | `/private/tmp/reading-app-pr2-rollback-unit.log`、`/private/tmp/reading-app-pr2-rollback-unit.xcresult` |
| 保存・追加画面の修正後、ホームのエラー修正前の AC-35・AC-3・AC-56 | 2件成功・1件失敗 | `/private/tmp/reading-app-pr2-current-focus.log`、`/private/tmp/reading-app-pr2-current-focus.xcresult` |
| ホームのエラー修正後の AC-56・AC-57 | 2件成功・失敗0、終了0 | `/private/tmp/reading-app-pr2-home-failure.log`、`/private/tmp/reading-app-pr2-home-failure.xcresult` |
| 本の詳細からの AC-56・AC-57 | 2件成功・失敗0、終了0 | `/private/tmp/reading-app-pr2-detail-failure.log`、`/private/tmp/reading-app-pr2-detail-failure.xcresult` |
| 3710550 の `make ios-build` | Debug・Release 成功、終了0。テスト文字列・URL scheme の非混入とファイル保護の検査も成功 | `/private/tmp/reading-app-pr2-build-r2.log` |
| ボタン数の補助修正後、AC-63 の2ケースと AC-64 を日英で実行 | 計6件成功・失敗0・スキップ0、終了0 | `/private/tmp/reading-app-pr2-button-count.log`、`/private/tmp/reading-app-pr2-button-count.xcresult` |
| 英語の重点確認 AC-3・AC-31・AC-35・AC-47・ホームの AC-56/57 | XCTest の出力は6件成功・失敗0。終了後の診断ログ収集・結果保存中で、CLI の終了コードと xcresult の集計は未確定 | `/private/tmp/reading-app-pr2-en-regression.log`、`/private/tmp/reading-app-pr2-en-regression.xcresult` |

ビルドの警告は従来と同じ AppIntents の metadata extraction skipped が各構成に1件で、Swift の新しい警告は0件。未翻訳キー0件、`org check` は39件一致。

診断の注意：従来の `AcceptanceTestCase.tearDownWithError` の `testRun.hasSucceeded` は終了前には false になるため、成功したテストでも `[AT-DIAG] 落ちたテスト` と `FAIL_...png` が出ていた。この文字列を失敗件数とは数えず、Test Case の最終結果・終了コード・xcresult の集計で判定した。診断条件は `totalFailureCount > 0` に修正した。Apple の XCTestRun.h:147-150 で、失敗と未処理例外の合計を表すことを確認した。アサーションや合否を変える変更ではない。

単体テストの実行：

```sh
xcodebuild test -project ios/Yomutoki.xcodeproj -scheme Yomutoki -testPlan Unit \
  -destination 'platform=iOS Simulator,id=B18DB71A-DB50-4F84-9DDD-7D63541CF3BB' \
  -resultBundlePath /private/tmp/reading-app-pr2-rollback-unit.xcresult CODE_SIGNING_ALLOWED=NO
```

画面テストは同じ行き先で `-testPlan Acceptance -only-test-configuration ja_JP` を指定し、AC-35・AC-3・AC-56 の各テスト名を `-only-testing` に渡した。判定の再試行、スキップ、期待値の緩和は追加していない。

ボタン数の検証は `-testPlan Acceptance` と AC-63 の reading / paused、AC-64 の3つの `-only-testing` で両構成を実行。英語の重点確認は `-only-test-configuration en_US` と AC-3・AC-31・AC-35・AC-47・ホームの AC-56/57 の6つの `-only-testing` を指定した。どちらも対象を絞った確認であり、全160件の完走には数えない。

## 未検証

- 全受け入れテストの日本語・英語の最終結果と G3 の画面確認。
- Xcode 27.1 / iOS 26.0 の AC-63・AC-64 の実行に `Invalid frame dimension (negative or non-finite)` の実行時警告が計6件ある。テストは6件すべて成功したが、警告の発生元は未特定。activities では終えるシートが開く時点に記録され、アプリのファイル・行は付いていない。コンパイル警告とは分けて記録し、警告0件を達成したとは扱わない。
- 保護された CI 設定変更に対する所有者確認（org-guard）。ガード自体は変更していない。
- main へのマージ・公開は実行していない。
