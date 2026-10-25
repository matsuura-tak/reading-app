# 使ってよい依存ライブラリ

ここに書いたライブラリだけを使います。ここにないライブラリは足しません（要るときは報告に書き、tech-lead が判断して追加します）。
足すときは、公式のページで存在と保守の状況を確かめ、決めた理由を書きます。元に戻しにくいものは docs/adr/ にも残します。
reviewer は G2 で、差分の依存がこの表にあるかを確かめます。

- 書いた役：tech-lead　日付：2026-10-25（G1 の 7 の続き。2026-10-20 の版を、PRD 2e26444 の「外部通信0件・書誌は Background Assets の端末内 DB」に合わせて直した）

## アプリの依存（ios/。アプリと拡張に入るもの）
- 001-reading-session（v1.0、AC-1〜AC-149）は、外部のライブラリなし（ADR 0001）。Apple のフレームワークと、OS に入っている SQLite（libsqlite3）だけを使う。だから下の表は空で、Package.resolved もない。
- 外部のフォントも入れない。書体は iOS に入ったヒラギノ明朝 ProN とシステムの書体だけ（design/001-reading-session/tokens.md の 2「外からフォントを入れない」）。
- 広告、解析、クラッシュ収集、通信のライブラリは入れない（AC-103。アプリのコードから外部への HTTP 通信は0件）。
- 足すときは、パッケージの URL を開き、実際に解決してビルドした出力を設計メモに貼ってから、表に1行足す。Package.resolved はコミットする。

| ライブラリ | 領域（ios / backend） | 何に使うか | 固定した版 | ライセンス | 最後の更新日 | Swift 6 と対応 OS | Apple の「よく使われる SDK」の一覧に載るか | プライバシーマニフェスト | 代わりの標準フレームワーク | 外す手間 | 選んだ理由 | 追加した日と ADR |
|---|---|---|---|---|---|---|---|---|---|---|---|---|

### 使う Apple のフレームワーク（iOS 26 SDK。表に載せないが、使う所を決めておく）
| フレームワーク | 使う所（ADR 0001 の単位） | 何に使うか | 関わる AC |
|---|---|---|---|
| SwiftUI | アプリ、ウィジェットの拡張、ReadingCore（W-1、W-2 の View） | 全画面、ウィジェット、Live Activity の描画、読み終えのカードの ImageRenderer | 全画面、AC-84 |
| SwiftData | ReadingStore | 主の保存先（VersionedSchema。ADR 0002） | AC-89〜AC-91 ほか |
| WidgetKit | ウィジェットの拡張、ReadingStore（再読み込み） | W-1、W-2、W-4（ControlWidget）、`reloadAllTimelines` | AC-27〜AC-35、AC-102、AC-126 |
| ActivityKit | ReadingStore（要求）、ウィジェットの拡張（描画） | W-3 の予約（`request(...start:)`。iOS 26）、すぐ始める、更新、終わり。pushType は nil | AC-36〜AC-41、AC-97、AC-98、AC-114〜AC-120、AC-130〜AC-132、AC-136、AC-144 |
| AppIntents | ReadingCore（インテントの型）、アプリ（perform の中身） | 「読み始める」「終える」（LiveActivityIntent）、「どこまで読んだ？」（ShowsSnippetIntent）、「続きを読む」、App Shortcuts、Control のボタン | AC-114〜AC-126、AC-131〜AC-136、AC-143 |
| Vision | アプリ | 文字の読み取り（ページの縦の列、表紙・背表紙、本棚、奥付）。設定は ADR 0004 | AC-65〜AC-69、AC-94、AC-113、AC-137、AC-138、AC-142 |
| VisionKit、AVFoundation | アプリ | バーコードの連続の読み取り（DataScannerViewController、EAN-13）、撮影、カメラの許可 | AC-2、AC-3、AC-11、AC-12、AC-70 |
| PhotosUI | アプリ | PhotosPicker（`.screenshots` と写真）。写真ライブラリの許可は求めない | AC-12、AC-70、AC-137、AC-142 |
| StoreKit | ReadingStore | StoreKit 2 の買い切り「よむま＋」（品の ID `jp.yomuma.plus`。design/001-reading-session/tokens.md の 1） | AC-104〜AC-111 |
| BackgroundAssets | 書誌の拡張、ReadingStore | Apple-Hosted Background Assets の asset pack（書誌・共起の SQLite）を受け取る（AssetPackManager、ManagedDownloaderExtension） | AC-2〜AC-6、AC-9〜AC-11、AC-92、AC-93、AC-148、AC-149 |
| SQLite3（libsqlite3.tbd。OS に入っているもの） | ReadingStore | 書誌・共起の DB を読むだけ（読み取り専用、FTS5 trigram）。DDL は ADR 0004 | AC-2〜AC-6、AC-78〜AC-81、AC-87、AC-138、AC-146〜AC-149 |
| UIKit | アプリ | 触覚（UIImpactFeedbackGenerator）、読み上げ（UIAccessibility.post）、向き（UIDevice の faceDown）、openURL | AC-3、AC-44〜AC-51、AC-88、AC-93 |
| Foundation、os | 全部 | Codable、日時、Logger（個人情報は既定の非公開）、os_signpost（区間の時間） | AC-55、AC-101、AC-114、AC-149 |

- CoreMotion と近接センサーは使わない（PRD 12「近接センサーと、画面を点けたままにする設定は使わない」。伏せた向きは UIDevice の faceDown）。
- URLSession、Network、WebKit は使わない（AC-103）。G2 で reviewer が `grep -rnE 'URLSession|NWConnection|NWPathMonitor|WKWebView|SFSafariViewController|URLRequest' ios/ --include='*.swift'` で見る。テストの構成だけの H29 の記録の部品（`UITestHooks/` の下）は数えない。

## 同梱のデータ（コードではない。出どころと表示の義務を決めておく）
| データ | 置き場所 | 出どころとライセンス | 表示の義務 | 関わる AC |
|---|---|---|---|---|
| 書誌・共起の DB（`catalog.sqlite`） | Apple-Hosted Background Assets の asset pack `catalog`（アプリの外で作る。ADR 0004） | 国立国会図書館が作成した書誌データ（iss-ndl-opac、iss-ndl-opac-inprocess、iss-ndl-opac-national）。CC BY 4.0（https://ndlsearch.ndl.go.jp/help/api/provider の「○：利用申請は不要」） | 設定の「データの出典」に3つの条件と版（AC-93、ADR 0004） | AC-2〜AC-6、AC-9〜AC-11、AC-92、AC-93、AC-148、AC-149 |
| 共起の表（同じ DB の `cooccurrence`） | 同上 | v1.0 は空の表で配る（組の収集は別 PRD `002`）。入れるときは文学 NDC 9、10人以上の組だけ | 「読んだ人」は国立国会図書館と関係がない旨（AC-93） | AC-148 |
| 受賞の一覧（`awards.json`） | アプリの束 | docs/prd/001-reading-session-awards.md の表（賞、回か年、題名、著者）。事実の一覧。**このファイルは 2026-10-25 時点でリポジトリにない**（`ls docs/prd/` で確かめた。pdm が作る。設計メモの 10） | なし | AC-17〜AC-21、AC-112 |
| ISBN の出版者記号の種（`publisher-prefixes.json`） | アプリの束 | 書誌 DB から前処理で作る（出版者記号ごとに、いちばん多い出版社名）。出どころは上の書誌と同じ | 書誌と同じ（AC-93） | AC-11 |

## 契約の検査の道具（アプリの依存ではない）
アプリにも拡張にも入らず、Package.resolved にも出ない。リポジトリの外に置いて、contracts/ を検査するためだけに使う。動かし方は CLAUDE.md と Makefile の `check-contracts`。CI に入れるには .github/ の変更が要るので、Takuma に頼む。

| 道具 | 版 | 何に使うか | 入れ方（確かめた形） | 確かめた出力（2026-10-25） |
|---|---|---|---|---|
| jsonschema（と、一緒に入る referencing 0.36.2） | 4.25.1 | contracts/hooks/ と widget-snapshot.schema.json の metaschema と examples の検査（Draft202012Validator） | `python3 -m venv <外のフォルダ>/venv` のあと `<外のフォルダ>/venv/bin/pip install 'jsonschema==4.25.1'`（Python 3.9.6） | 設計メモの 4 |

- OpenAPI の契約（contracts/ndl-opensearch.yaml）は、アプリの外部通信を0件にしたので消した（ADR 0004）。だから Spectral と oasdiff は今は使わない。サーバーか外部 API の契約を足すときに、2026-10-20 の版（git の fc5906e^）の行を戻す。
