# PR #2 の CI 設定・実行確認

- 確認日：2026-10-22（日本時間）
- 対象：PR #2、設定変更 a4065e3。iOS の実装とテストは fd7f57f から変更していない。
- 許可の根拠：docs/approvals/001-reading-session-ci-settings.md
- この記録は CI 設定の動作確認であり、G2 r2・G3 の合格判定ではない。

## 原因と変更

旧 CI の plan は `.claude/org/app.json` の `commands.ios_test` が空で終了コード1になり、iOS ジョブを起動できなかった。

`ios_build` を `make ios-build`、`ios_test` を `make ios-test` に設定。iOS ジョブの時間上限を60分から150分にし、そのファイルの SHA-256 を lock.json に記録した。他の管理対象のハッシュ、テスト、ガードは変えていない。

## 実行した確認と結果

| 確認 | コマンド・方法 | 結果 |
|---|---|---|
| 設定の整合 | `python3 .claude/org/bin/org check .` | 終了0。管理対象39ファイルが一致 |
| 差分の形式 | `git diff --check` | 終了0 |
| CI plan | ios.yml 内の Python 処理を抽出し、一時 GITHUB_OUTPUT に出力 | 終了0、`run=true` |
| 実行コマンド | `make --dry-run ios-build`、`make --dry-run ios-test` | 両ターゲットが解決する |
| Debug・Release のビルド | `make ios-build` | 終了0、`BUILD SUCCEEDED` が2回 |
| 日本語・英語の翻訳 | `python3 -I contracts/tools/xcstrings_untranslated.py ios/Yomutoki/Resources/InfoPlist.xcstrings ios/Yomutoki/Resources/Localizable.xcstrings` | 終了0、`untranslated_keys=0` |
| 単体テスト | 下記の xcodebuild と xcresulttool | 終了0。67件成功、失敗0、スキップ0 |

ローカルの Xcode は27.1（27A9275）。ビルドコマンドは、指定された XcodeGen 2.46.0 の SHA-256、ファイル保護、テスト用文字列の配置、Release の文字列と URL scheme を含む既存の検査まで実行した。AppIntents.framework を使っていないためのメタデータ抽出警告が Debug・Release で各1件あり、Swift のコンパイル警告・エラーはなかった。

単体テストは利用可能な iOS 26.0 の iPhone 17 を指定した。最初の GitHub CI は、Debug・Release のビルドを通過後、暫定の iPhone 16 指定がランナーに存在せず終了70になった。ログに iPhone 17（iOS 26.2、26.4.1、26.5）が存在するため、Makefile と CLAUDE.md のテスト先を iPhone 17 にそろえた。GitHub ランナーでの最終結果は別途確認が必要。

```sh
xcodebuild test -project ios/Yomutoki.xcodeproj -scheme Yomutoki -testPlan Unit \
  -destination 'platform=iOS Simulator,id=B18DB71A-DB50-4F84-9DDD-7D63541CF3BB' \
  -resultBundlePath /private/tmp/reading-app-pr2-unit.xcresult CODE_SIGNING_ALLOWED=NO
xcrun xcresulttool get test-results summary --path /private/tmp/reading-app-pr2-unit.xcresult --format json
```

結果概要：`result=Passed`、`totalTestCount=67`、`passedTests=67`、`failedTests=0`、`skippedTests=0`。端末ごとの内訳は、パラメータ別実行を含み `passedTests=168`。

ローカルの出力：

- `/private/tmp/reading-app-pr2-build.log`
- `/private/tmp/reading-app-pr2-unit.log`
- `/private/tmp/reading-app-pr2-unit.xcresult`

## GitHub と残る確認

a4065e3 の [CI 実行](https://github.com/matsuura-tak/reading-app/actions/runs/39774245085)では plan が成功し、iOS ジョブが起動した。org-check も成功。ビルドは2構成とも成功、テストは iPhone 16 がなく終了70。実装のコンパイル失敗ではない。機種指定修正後の結果は [PR #2 の Checks](https://github.com/matsuura-tak/reading-app/pull/2/checks) で確認する。

org-guard は `.claude/` と `.github/` の変更を所有者に確認してもらう仕組みのため失敗する。ガードの削除や例外化は行っていない。

単体テストのローカル成功は、全受け入れテスト・G2 r2 レビュー・G3 の画面と機能検証の代わりにはならない。PR は Draft のままとし、main へのマージや公開は行っていない。
