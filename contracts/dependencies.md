# 使ってよい依存ライブラリ

ここに書いたライブラリだけを使います。ここにないライブラリは足しません（要るときは報告に書き、tech-lead が判断して追加します）。
足すときは、公式のページで存在と保守の状況を確かめ、決めた理由を書きます。元に戻しにくいものは docs/adr/ にも残します。
reviewer は G2 で、差分の依存がこの表にあるかを確かめます。

| ライブラリ | 領域（ios / backend） | 何に使うか | 選んだ理由 | 追加した日と ADR |
|---|---|---|---|---|
| XcodeGen（https://github.com/yonaskolb/XcodeGen） | ios（ビルドの道具。アプリに入らない） | ios/project.yml から ios/Yomutoki.xcodeproj を CI で作る（`xcodegen generate`） | この環境に Mac と Xcode がなく、pbxproj を手で書くと壊しやすい。project.yml は読める文字で、差分を reviewer が読める | 2026-10-21、ADR 0004 |
| ajv-cli（https://www.npmjs.com/package/ajv-cli） | contracts/CI（契約の検査の道具。アプリに入らない） | `make contracts-check` で contracts/ の JSON Schema（draft-07）と例を照らす（contracts/README.md の1） | Node があればコマンド1つで Linux でも動き、契約の形を機械で確かめられる | 2026-10-21、ADR なし（道具） |

## 001 のランタイムのライブラリ
0件。アプリに入るのは Apple の標準フレームワーク（SwiftUI、SwiftData、Foundation、OSLog）だけです。Swift パッケージを足さないので、Package.resolved はまだありません（足したときにコミットします）。
計測の SDK（TelemetryDeck など）は入れていません（ADR 0003。003 の G1 で決め直す）。

## 詳しい列（tech-lead の手引きの列。上の表の行ごとに1行）
| ライブラリ | 固定した版 | ライセンス | 最後の更新日 | Swift 6 と対応 OS | Apple の「よく使われる SDK」の一覧に載るか | プライバシーマニフェスト | 代わりの標準 | 外す手間 |
|---|---|---|---|---|---|---|---|---|
| XcodeGen | 2.46.0。GitHub Releases の https://github.com/yonaskolb/XcodeGen/releases/download/2.46.0/xcodegen.zip を、SHA-256 `4d9e34b62172d645eed6457cac13fc222569974098ef4ee9c3368bedf0196806` で CI が確かめてから使う（`shasum -a 256 -c`。ADR 0004 の決定、CLAUDE.md の ios_build と ios_test、Makefile と同じ） | MIT（https://raw.githubusercontent.com/yonaskolb/XcodeGen/master/LICENSE を 2026-10-21 に取得。1行目「MIT License」。zip の中にも xcodegen/LICENSE がある） | 2.46.0 の zip の中のファイルの日付は 2026-07-16（リリースの画面の日付は見ていない）。CHANGELOG の最新の見出しも 2.46.0 | 対象外（macOS で動く道具で、アプリに入らない。zip の中は x86_64 と arm64 の Mach-O。作ったプロジェクトは Swift 6、iOS 17.0。ADR 0002） | 対象外（アプリに入らない） | 対象外（アプリに入らない） | Xcode で作った .xcodeproj をコミットする（Mac が要る） | 小：一度 `xcodegen generate` した ios/Yomutoki.xcodeproj をコミットし、.gitignore の行と CLAUDE.md、Makefile のコマンドから xcodegen を外す（1日以内。以後は pbxproj を Xcode で直す） |
| ajv-cli | 5.0.0（`npx -y ajv-cli@5.0.0`）。ajv-cli が使う ajv（^8.0.0）、glob（^7.1.0）などは ajv-cli の package.json の幅で決まり、lockfile がないので固定していない | MIT（`npm view ajv-cli@5.0.0 license` → 'MIT'、2026-10-21） | 2023-04-28（`npm view ajv-cli time.modified` → 2023-04-28T02:15:19.206Z。dist-tags.latest は 5.0.0） | 対象外（Node の道具。アプリに入らない） | 対象外 | 対象外 | Apple の標準に JSON Schema の検査はない。Python の jsonschema も第三者 | 小：Makefile と contracts/README.md の4行ずつと、CLAUDE.md の1行を消す（契約の例を目で確かめることになる） |

解決とビルドの出力：
- XcodeGen：zip の取得と SHA-256 はこの環境で確かめた（ADR 0004 の A112）。実行ファイルは macOS 用なので、この環境（Linux）では動かしていない。最初の CI の ios_build のログ（`shasum` の「OK」、`xcodegen --version`、`xcodegen generate`、xcodebuild の出力）を ios-engineer が報告に貼る（裁定の追記2 の (1)）。
- ajv-cli：この環境で `make contracts-check` を動かし、4行とも valid、終了コード0（設計メモの 4）。
