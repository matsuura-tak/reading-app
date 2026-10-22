# PR #2 の CI 設定変更に対する Takuma の許可

- 日付：2026-10-22（日本時間）
- 受け取った場所：Codex のチャット。対象は https://github.com/matsuura-tak/reading-app/pull/2

## Takuma の依頼（そのまま引用）

> これ何をすればいいの、あなたができそうなら許可するので実行して

## この依頼で行う変更

PR の本文と CI の失敗ログに記された、未設定の実行コマンドと実行時間上限を修正する許可として扱う。

- `.claude/org/app.json`：`commands.ios_build` を `make ios-build`、`commands.ios_test` を `make ios-test` にする。
- `.github/workflows/ios.yml`：iOS ジョブの時間上限を60分から150分にする。既存のビルド・テストとガードは維持する。
- `.claude/org/lock.json`：上記の許可されたワークフロー変更のハッシュだけを更新する。キットの版や他の管理対象は変えない。このローカル差分は将来のキット更新時に整合を確認する。

`org-guard` は所有者が設定変更を確認するためのチェックなので、今回の差分で失敗することを隠さず、そのまま残す。アプリの動作検証、G2・G3 の判定、main へのマージや公開を完了したことにはしない。
