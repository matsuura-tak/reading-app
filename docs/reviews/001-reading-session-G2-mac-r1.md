FAIL

# PR #2 の Mac 検証と追加修正

- 日付：2026-10-22（日本時間）
- 検証環境：Xcode 27.1、iPhone 17 シミュレーター、iOS 26.0。
- 対象：Claude の修正 ba8b82a・059a6dc と、その後に追加した保存・画面表示の修正。
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

単体テストの実行：

```sh
xcodebuild test -project ios/Yomutoki.xcodeproj -scheme Yomutoki -testPlan Unit \
  -destination 'platform=iOS Simulator,id=B18DB71A-DB50-4F84-9DDD-7D63541CF3BB' \
  -resultBundlePath /private/tmp/reading-app-pr2-rollback-unit.xcresult CODE_SIGNING_ALLOWED=NO
```

画面テストは同じ行き先で `-testPlan Acceptance -only-test-configuration ja_JP` を指定し、AC-35・AC-3・AC-56 の各テスト名を `-only-testing` に渡した。判定の再試行、スキップ、期待値の緩和は追加していない。

## 未検証

- 全受け入れテストの日本語・英語の最終結果と G3 の画面確認。
- 保護された CI 設定変更に対する所有者確認（org-guard）。ガード自体は変更していない。
- main へのマージ・公開は実行していない。
