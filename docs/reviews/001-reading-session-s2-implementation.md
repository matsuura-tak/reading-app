# S2 追加ボタンのラベル色 最小修正（ios-engineer）

- 対象: /private/tmp/reading-app-pr2-20261023-resume、基準HEAD 6442fe2e5b1ad1f4956123c938076c6da462b874。
- 製品コードの差分: `ios/Yomutoki/Screens/AddBookView.swift:129` の1行追加だけ。commit / push / branch操作なし。ユーザーの元checkoutは読み取りだけ。
- ビルドと重点テストの結果は以下。修正後S2ダーク画像の目視確認は未実施で、verifierへ引き継ぐ。G2/G3全体のPASS判定は行わない。

## 変更したファイル

`ios/Yomutoki/Screens/AddBookView.swift:129`: 確定ツールバーの `Text("book.save")` に `.foregroundStyle(AppColor.onAccent)` を指定した。

既存G3画像 `docs/verification/001-reading-session/evidence/g3-20261023/screens/S2_normal_dark.png` をview_imageで確認し、栗色の塗りの上の「追加」が黒字であることを再確認した。design/tokens.md:24,30 と design/001-reading-session.md D-46（234行）は、塗りの上のラベルへ color.text.onAccent を明示する。既存の `accentProminentButton()` はButton側に指定していたため、S5と同様にラベル自身へ指定を加えた。S5の既存修正4125f7cの `FinishSessionView.swift:79` と同じ方法で、新しい色や寸法は導入していない。今回の修正で画面が解消したとの判断は、再撮影待ち。

`save()`、`canSave`、`didSave`、`.disabled`、識別子、String Catalog、確認ダイアログ、エラー、ルーター、ファイル保護、契約、ルート設定、受け入れテストは無変更。`source-checks.json` に、追加した1行を取り除けばHEADのAddBookViewと完全一致する検査を保存した。

## API の確認

| API | Apple公式URL | 対応OS | 最低対応OSとの適合 |
|---|---|---|---|
| `Text.foregroundStyle<S>(_ style: S) -> Text` | https://developer.apple.com/documentation/swiftui/text/foregroundstyle%28_%3A%29 | iOS 17.0以降 | project.ymlのiOS 17.0と同じ。適合。公式.mdのavailabilityを確認し `apple-text-foregroundstyle.md` に保存 |

既存の `AppColor.onAccent = Color("OnAccent")` を使う。アセット変更なし。新規Apple APIの導入ではなく、既存S5と同じAPIの呼び出しをラベルへ追加した。

## 画面の状態と識別子

今回の変更はS2ラベルだけ。既存の状態とPreviewを維持し、Previewの表示・全状態の目視は今回実行していない。

| S2の状態（design 5章） | 実装の場所 | Preview |
|---|---|---|
| 通常 | AddBookView.swift:49（Form）、71（題名）、89（総ページ数）、124（確定操作） | S2/通常（194）、S2/AX5（219）、S2/ダーク（226） |
| 空 | AddBookView.swift:43-45（canSave）、132（無効条件） | S2/空（199） |
| 読み込み中 | designでは「なし。読むデータがない」。保存中の二度押し防止は didSave:15、132、169-171 | 読み込み用Previewなし（designどおり） |
| エラー: 総ページ数 | AddBookView.swift:106-109（FieldErrorText）、132（無効） | S2/エラー（総ページ数が範囲の外）（204） |
| エラー: 保存失敗 | AddBookView.swift:51-68、175-177（saveFailed/通知） | S2/エラー（保存の失敗）（209） |
| オフライン | design「通常と同じ」（端末内の入力のみ） | S2/通常 |
| 権限を断られたとき | design「なし（上の理由）」: 001は権限を1つも求めない | 対象なし |
| 一部だけ読めたとき | design「なし。入力だけの画面で、読み込むものがない」 | 対象なし |
| 題名の上限（形B） | AddBookView.swift:81-85、159-160 | S2/題名の上限（形B）（214） |

S2の識別子は11/11一致。AddBookView内の10個（`error.saveFailed.book`、`error.retry`、`book.add.title`、`book.add.titleLimit`、`book.add.totalPages`、`book.add.totalPagesHint`、`book.add.totalPagesOutOfRange`、`book.add.cancel`、`book.save`、`book.add.discard.confirm`）と、共通SaveFailedTitleの`error.saveFailed`。直接指定と引数の識別子リストはHEADと同一。String Catalogは75/75キーでja/enがそろい、欠落0。今回文言変更0。

## 実行したコマンドと結果

環境: Xcode 27.1 (27A9275)、XcodeGen 2.46.0。専用シミュレーター `B18DB71A-DB50-4F84-9DDD-7D63541CF3BB`（iPhone 17 / iOS 26.0）だけを使用。テスト後は専用シミュレーターがすでにShutdown（終了時のshutdown要求は現状態Shutdownのため405/終了149、状態読み取りでもShutdownを確認。テストの終了コードとは別）。別診断担当のシミュレーターには触れていない。全exec_commandは `/bin/sh`, `login:false`。

1. リポジトリ直下 `make ios-build`: 終了0。Debug/ReleaseともBUILD SUCCEEDED。XcodeGen SHA-256、entitlements NSFileProtectionComplete、Releaseにテスト接続文字列・CFBundleURLTypesがないことの既存チェックも成功。`ios-build.log` / `ios-build.exit`。警告2件は既存AppIntentsメタデータ抽出警告。Swiftコンパイラ警告0。
2. ios/内の次のUnit: 終了0、69件/12suite成功、失敗0、skip0。`Unit.log` / `Unit-summary.json` / `Unit.xcresult`。Swift Testingのパラメーター展開は上位テスト件数69と区別。警告3件は既存AppIntentsメタデータ抽出警告。Swiftコンパイラ警告0。

```sh
xcodebuild test -project Yomutoki.xcodeproj -scheme Yomutoki -testPlan Unit -destination 'platform=iOS Simulator,id=B18DB71A-DB50-4F84-9DDD-7D63541CF3BB' -parallel-testing-enabled NO -derivedDataPath /private/tmp/reading-app-s2-fix-20261023/DerivedData -resultBundlePath /private/tmp/reading-app-s2-fix-20261023/Unit.xcresult CODE_SIGNING_ALLOWED=NO
```

3. ios/内の重点Acceptance（テスト内容はHEADから無変更。再試行なし）。結果は `Acceptance-S2.log` / `Acceptance-S2-summary.json` / `Acceptance-S2.xcresult`。

```sh
xcodebuild test -project Yomutoki.xcodeproj -scheme Yomutoki -testPlan Acceptance -destination 'platform=iOS Simulator,id=B18DB71A-DB50-4F84-9DDD-7D63541CF3BB' -parallel-testing-enabled NO -derivedDataPath /private/tmp/reading-app-s2-fix-20261023/DerivedData -resultBundlePath /private/tmp/reading-app-s2-fix-20261023/Acceptance-S2.xcresult -only-testing:YomutokiAcceptanceTests/LibraryAcceptanceTests/test_AC2_addBookWithTitleOnly -only-testing:YomutokiAcceptanceTests/AddBookAcceptanceTests/test_AC42_bookAddFailureKeepsTitle -only-testing:YomutokiAcceptanceTests/AddBookAcceptanceTests/test_AC49_afterAddShowsNewBookDetail CODE_SIGNING_ALLOWED=NO
```

終了0、TEST SUCCEEDED。ja_JP/en_US各3件、合計6実行すべて成功、失敗0・skip0。xcresultの上位件数は3（同じ3ケースを2構成で実行）。Acceptanceの警告行0、コンパイラ警告0、runtimeWarnings空。今回の6実行ではInvalid frame dimension / unsatisfiable constraintsとも0行。既存の全体レイアウト問題が解消したとの証明には扱わない。

既存のAppIntents警告はdocs/reviews/001-reading-session-s5-implementation.md:56-58およびG2-ci-6442fe2.md:34にも記録されている。OSビルド文字列を読むXcodeの `invalidDigitCount(94232)` 診断はUnitログ3行、Acceptanceログ30行。Swiftコンパイラ警告と区別する。テスト失敗・実行時警告としては記録されていない。

結果要約抽出: `xcrun xcresulttool get test-results summary --path <Unit.xcresultまたはAcceptance-S2.xcresult>`。抽出JSONをそれぞれ保存。

4. `git diff --check`: 終了0。`git diff --numstat -- ios` は AddBookView.swiftの追加1、削除0だけ。`git diff -- ios/AcceptanceTests ios/Yomutoki/Yomutoki.entitlements ios/project.yml Makefile` は空。
5. 役の静的検査を製品Swift（ios/Yomutoki）で実行。結果は `source-checks.json`。今回のAddBookViewだけでは全項目0、差分に追加の指摘0。

| 検査 | 製品全体の該当行数 | 今回追加 |
|---|---:|---:|
| 並行処理を黙らせる | 0 | 0 |
| 古い書き方 | 0 | 0 |
| 固定サイズ・色の直書き | 0 | 0 |
| onTapGesture | 0 | 0 |
| 強制アンラップ | 0 | 0 |
| print・秘密語 | 0 | 0 |
| TODO/FIXME/mock/dummy/sample/lorem | 0 | 0 |
| Formatter/sorted/filter（全製品の候補） | 9（Screens内0） | 0 |
| privacy APIの候補 | 13 | 0 |

9行の理由（いずれも既存でView.body外）: Debug/HTTPTelemetrySink.swift:70,117 と Telemetry/TelemetryEvent.swift:190はJSONのsortedKeys。Debug/UITestHooks.swift:55はテストseed用DateFormatter、452,455は不正キーの診断順、595,596は環境の不正キー検査。Model/LibraryStore.swift:469はモデルで本を並べる計算。画面のbody候補0。

privacyの13行はいずれも既存のUserDefaults参照または説明コメント: App/YomutokiApp.swift:55,68（組み立て）、Debug/UITestHooks.swift:529,562,738（seed）、Screens/ReadingView.swift:3（保存しない旨のコメント）、Telemetry/TelemetryRecorder.swift:3,19,25（計測の印）、Telemetry/TelemetrySink.swift:10,14,20,28（端末内イベント回数）。PrivacyInfo.xcprivacyのNSPrivacyAccessedAPICategoryUserDefaults/CA92.1に対応。色の1行だけの修正のためマニフェスト変更なし。

## 未解決・引き継ぎ

- 修正後のS2ダーク画面は未撮影・未目視。親が別途verifierへ依頼する前後画像・高コントラスト・無効時・文字サイズの確認が残る。元の黒字だけは既存画像で確認済み。
- 全受け入れテスト、AC18、VoiceOver実機、Instruments、weak参照、Thread Sanitizerの再実行は今回の1行修正の対象外で未実施。既存実績を今回の成功に代用していない。
- 新しい単体テスト・一時Acceptanceは追加しない。受け入れテストの変更はverifier専有。
- 未実施項目を合格とはせず、G2/G3全体の判定は行わない。レポート・ログはすべてこのtmpディレクトリに置き、cloneのdocsには書いていない。

最終成果物: report.md、summary.json、diff.patch、source-checks.json、ios-build.log/.exit、Unit.log/.exit/-summary.json/.xcresult、Acceptance-S2.log/.exit/-summary.json/.xcresult、Apple公式API本文、専用sim状態JSON。
