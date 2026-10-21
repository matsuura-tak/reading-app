# 使ってよい依存ライブラリ

ここに書いたライブラリだけを使います。ここにないライブラリは足しません（要るときは報告に書き、tech-lead が判断して追加します）。
足すときは、公式のページで存在と保守の状況を確かめ、決めた理由を書きます。元に戻しにくいものは docs/adr/ にも残します。
reviewer は G2 で、差分の依存がこの表にあるかを確かめます。

| ライブラリ | 領域（ios / backend） | 何に使うか | 選んだ理由 | 追加した日と ADR |
|---|---|---|---|---|
| XcodeGen（https://github.com/yonaskolb/XcodeGen） | ios（ビルドの道具。アプリに入らない） | ios/project.yml から ios/Yomutoki.xcodeproj を CI で作る（`xcodegen generate`） | この環境に Mac と Xcode がなく、pbxproj を手で書くと壊しやすい。project.yml は読める文字で、差分を reviewer が読める | 2026-10-21、ADR 0004 |

## 001 のランタイムのライブラリ
0件。アプリに入るのは Apple の標準フレームワーク（SwiftUI、SwiftData、Foundation、OSLog）だけです。Swift パッケージを足さないので、Package.resolved はまだありません（足したときにコミットします）。
計測の SDK（TelemetryDeck など）は入れていません（ADR 0003。003 の G1 で決め直す）。

## 詳しい列（tech-lead の手引きの列。上の表の行ごとに1行）
| ライブラリ | 固定した版 | ライセンス | 最後の更新日 | Swift 6 と対応 OS | Apple の「よく使われる SDK」の一覧に載るか | プライバシーマニフェスト | 代わりの標準 | 外す手間 |
|---|---|---|---|---|---|---|---|---|
| XcodeGen | 固定しない（`brew install xcodegen` の最新。2026-10-21 の CHANGELOG の最新は 2.46.0）。CI のログに `xcodegen --version` を出して記録する。版の違いで壊れたら、GitHub の Releases の zip を版を決めて入れる形に替える | MIT（https://raw.githubusercontent.com/yonaskolb/XcodeGen/master/LICENSE を 2026-10-21 に取得。1行目「MIT License」） | CHANGELOG の最新の見出しは 2.46.0（日付は未確認） | 対象外（macOS で動く道具で、アプリに入らない。作ったプロジェクトは Swift 6、iOS 17.0。ADR 0002） | 対象外（アプリに入らない） | 対象外（アプリに入らない） | Xcode で作った .xcodeproj をコミットする（Mac が要る） | 小：一度 `xcodegen generate` した ios/Yomutoki.xcodeproj をコミットし、.gitignore の行と CLAUDE.md のコマンドから xcodegen を外す（1日以内。以後は pbxproj を Xcode で直す） |

解決とビルドの出力：この環境（Linux）では brew と xcodebuild が動かないので未確認です。最初の CI の「ios_build」のログ（`xcodegen --version` と `xcodegen generate` と xcodebuild の出力）を ios-engineer が報告に貼ります。
