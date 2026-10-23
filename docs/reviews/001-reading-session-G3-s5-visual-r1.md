FAIL

# S5 の画面確認（2026-10-23）

全画面のG3判定ではなく、終える入力 S5 の初回の実画面確認。未確認を合格にせず、原因未特定の項目を製品の不具合と断定しない。

## 修正と切り分けの追記

実装担当が `FinishSessionView.swift` の2行だけを修正した。キーボード上の保存に `.fixedSize(horizontal: true, vertical: false)` を指定し、上部保存の `Text` 自体に既存の `AppColor.onAccent` を指定した。ボタンや機能の削除、色の直書き、受け入れテストの変更はない。指摘1と3は下の前後画像で改善を確認した。

- `S5-finishing-{light,dark,ax5,en}-after.png`：4通りで「保存」/Saveが全文表示される。ダークの上部保存が白字になる。指揮役も4画像を実際に開き、改善を確認した。
- ダーク上部ボタンの同じ領域を実装担当が比較：背景 `#9F5833` は同一で、文字の黒1457pxが白1457pxに変わった。既存トークンの白字を適用する修正であり、背景色は変更していない。
- [fixedSize(horizontal:vertical:)](https://developer.apple.com/documentation/swiftui/view/fixedsize(horizontal:vertical:)) はiOS13以降、[foregroundStyle](https://developer.apple.com/documentation/swiftui/view/foregroundstyle(_:)) はiOS15以降。Appleの本文で名前と対応OSを確認し、最低対応iOS17以下。
- `make ios-build`：Debug/Release成功、Releaseへのつなぎ口の非混入などの検査も成功。単体69件成功。実装担当のログは `/private/tmp/reading-app-pr2-s5-fix-20261023/{ios-build,unit}.log`。
- AC9 / AC48 / AC63 readingを日英で再試行なしに実行：成功6・失敗0・飛ばした0、終了0、TEST SUCCEEDED。隣の `s5-fix-acceptance-summary.json` で構成別各3件、失敗・飛ばした0を指揮役も確認した。Xcodeの診断収集は600秒で時間切れになったが、テストの結果は保存され終了0だった。
- この6件の実行に既知の `Invalid frame dimension (negative or non-finite)` が6件残る。レイアウト警告が解消したとは扱わない。全体CIとG3の未完了も維持する。

指摘2は別の対照で切り分けた。同じ製品バイナリで `AppleLanguages=(en)` のとき日本語題名が四角、`(en,ja)` のときは英語UIと日本語題名の両方が正しく表示された。製品を含まない一時アプリでも標準UIKit UILabelのfootnote/body/headlineとSwiftUI Textのfootnote/bodyで同じ差が出た。

- `font-product-en.png` / `font-product-en-ja.png`：同じ製品の言語指定だけの比較。
- `font-native-en.png` / `font-native-en-ja.png`：独立した標準部品での対照。
- 指揮役も製品のen/ja指定後と、標準部品の両画像を実際に確認した。フォント代替・ランタイム・言語指定の組み合わせに依存することを示す証拠であり、保存データの変更や製品での文字化けとは断定しない。追加の製品修正は行っていない。実機など別環境のen単独での確認は未完了。

結果ファイル・画像は同名フォルダに保存した。S5以外の状態、操作の5回確認、監査、探索を完了したことにはしない。

## 指摘

1. 要修正（design D-53、S5）：キーボード上の保存ボタン `session.finish.saveKeyboard` の文字が読めない。日本語の通常・ダーク・AX5で「保」の一部のように欠け、英語では `...` になる。ナビゲーションバーの保存は読める。保存操作そのものが壊れたと判断する証拠ではないが、仕様の「保存」と読めるボタンを満たしたとは扱わない。
2. 要確認（S5、本の題名）：英語UIで同じseedの日本語の題名「坊っちゃん」が四角5つに見える。日本語UIでは表示される。フォント・シミュレーターの言語設定を含めて調べる。題名が消えた、データが変わったとは判断しない。
3. 要確認（tokens の onAccent）：ダークの上部保存ボタンの文字が黒く見える。トークンは通常ダークで白なので、実際の適用とコントラストを確認する。画像だけで数値の不合格とは判定しない。

これらの補助確認の後に実装担当へ再現・最小修正を委任した。受け入れ条件の期待値を変更していない。

## 証拠

- 対象：`274adc0`（main `0e2c062` 取り込み後、`9f32800` とファイルの差分0）。製品のSwiftソースとビルド済みアプリは前回テスト時から同一。
- 環境：Xcode 27.1、iPhone 17 / iOS 26.0、専用端末 `B18DB71A-DB50-4F84-9DDD-7D63541CF3BB`。CI の iOS 26.5 と異なる。
- 使用アプリ：`/Users/takumamatsuura/Library/Developer/Xcode/DerivedData/Yomutoki-boohoquzvkiszmacczioafaukjry/Build/Products/Debug-iphonesimulator/Yomutoki.app`、`com.example.yomutoki`。
- 起動：`xcrun simctl launch --terminate-running-process`。`SIMCTL_CHILD_UITEST_SEED` に隣の `finishing-seed.json` を渡し、`UITEST_NOW=2026-10-21T21:30:00`、`UITEST_CLOCK_FROZEN=1`、`UITEST_TIME_ZONE=Asia/Tokyo`。アプリ引数 `-UITest -AppleLanguages '(ja)' -AppleLocale ja_JP`、英語では `(en)` と `en_US`。通常は `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryL`、AX5は `UICTContentSizeCategoryAccessibilityXXXL`。
- appearance は専用端末を `xcrun simctl ui <UDID> appearance light/dark` で切り替えた。ほかの端末は操作していない。
- 各画像は `xcrun simctl io <UDID> screenshot <path>` で取得し、実際に開いて確認した。

| ファイル（隣の同名フォルダ） | 表示 |
|---|---|
| `S5-finishing-light.png` | 日本語・ライト・通常文字 |
| `S5-finishing-dark.png` | 日本語・ダーク・通常文字 |
| `S5-finishing-ax5.png` | 日本語・ライト・AX5 |
| `S5-finishing-en.png` | 英語・ライト・通常文字、日本語の本の題名 |

保存先：`docs/reviews/001-reading-session-G3-s5-visual-r1/`。これは4通りの見た目の証拠であり、タップやスクロール、VoiceOver、`performAccessibilityAudit()` の実行結果ではない。AX5で下の分の欄をスクロールして操作できるかも未確認。G3の画面全体・全状態、監査、探索は未完了。
