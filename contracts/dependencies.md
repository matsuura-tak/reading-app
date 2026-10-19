# 使ってよい依存ライブラリ

ここに書いたライブラリだけを使います。ここにないライブラリは足しません（要るときは報告に書き、tech-lead が判断して追加します）。
足すときは、公式のページで存在と保守の状況を確かめ、決めた理由を書きます。元に戻しにくいものは docs/adr/ にも残します。
reviewer は G2 で、差分の依存がこの表にあるかを確かめます。

## アプリの依存（ios/。アプリやウィジェットの拡張に入るもの）
- 001-reading-session の芯（v1）は、外部のライブラリなし（ADR 0001。2026-10-20、G1 の 7-4b）。Apple のフレームワークだけを使う。だから下の表は空で、Package.resolved もない。
- 使う Apple のフレームワークは、設計メモ docs/adr/features/001-reading-session.md の 9 にある。
- 足すときは、パッケージの URL を開き、実際に解決してビルドした出力を設計メモに貼ってから、表に1行足す。Package.resolved はコミットする。

| ライブラリ | 領域（ios / backend） | 何に使うか | 固定した版 | ライセンス | 最後の更新日 | Swift 6 と対応 OS | Apple の「よく使われる SDK」の一覧に載るか | プライバシーマニフェスト | 代わりの標準フレームワーク | 外す手間 | 選んだ理由 | 追加した日と ADR |
|---|---|---|---|---|---|---|---|---|---|---|---|---|

## 契約の検査の道具（アプリの依存ではない）
アプリにもウィジェットの拡張にも入らず、Package.resolved にも出ない。リポジトリの外に置いて、contracts/ を検査するためだけに使う。動かし方は CLAUDE.md。CI に入れるには .github/ の変更が要るので、Takuma に頼む。

| 道具 | 版 | 何に使うか | 入れ方（確かめた形） | 確かめた出力（2026-10-20） |
|---|---|---|---|---|
| Spectral（stoplightio/spectral） | 6.17.0 | OpenAPI の形式（contracts/.spectral.yaml） | GitHub の公式リリースの spectral-macos-arm64。sha256 `cb7e1bd31d85a9920100d79e7ba138cc75cf529dfa8e7492c69affe52e38d142` が、配布元の公開値（GitHub の API `repos/stoplightio/spectral/releases/tags/v6.17.0` の assets の digest）と一致した（2026-10-20。reviewer r1 の P7）。CI では、この値と照らしてから動かすか、npx で版を固定する。node があれば `npx --yes @stoplight/spectral-cli@6.17.0` でもよい（node のある機械では未確認） | contracts/ndl-opensearch.yaml：`No results with a severity of 'hint' or higher found!` |
| oasdiff | 1.34.0 | OpenAPI の互換性（main の契約と比べる） | GitHub の公式リリースの oasdiff_1.34.0_darwin_all.tar.gz（sha256 34f5713d…7952 が checksums.txt と一致） | 空の基準と比べて `No breaking changes to report` |
| jsonschema（と、一緒に入る referencing） | 4.25.1 | contracts/hooks/ と widget-snapshot.schema.json の metaschema と examples の検査 | `python3 -m venv <外のフォルダ>/venv` のあと `pip install 'jsonschema==4.25.1'`（Python 3.9.6） | `schemas 8 examples 16 OK` |
