# ios-engineer：S5 保存ボタンの表示修正（検証記録）

G2/G3 全体は未完了。これは iPhone 17 / iOS 26.0 / Xcode 27.1 の局所修正と検証。基点 HEAD 274adc0、作業コピー /private/tmp/reading-app-pr2-20261022。コミット・push・ブランチ変更なし。

## 変更したファイル

- ios/Yomutoki/Screens/FinishSessionView.swift:79：上部保存の Text 自身へ既存 AppColor.onAccent を指定。Button 外側の指定だけではダークのシステムツールバーが黒を描いていた。
- 同:93：キーボード保存 Button に fixedSize(horizontal: true, vertical: false)。親からの狭い幅の提案で「保」や「...」になっていたラベルが、標準ボタンの理想幅を使うようになる。固定の幅・高さ、文字サイズの数値、色の新設はない。.bordered と keyboard の右端配置を維持。
- 新しい状態やロジックはないため実装をなぞる単体テストは追加していない。既存 Unit 全件と関係する Acceptance を使う。受け入れテスト、契約、design、保護設定、ルート設定は変更していない。

## API の確認

| API | Apple 一次資料 | 対応 OS | 最低 iOS17 以下 |
|---|---|---|---|
| View.fixedSize(horizontal:vertical:) | https://developer.apple.com/documentation/swiftui/view/fixedsize(horizontal:vertical:) | iOS13+ | はい |
| View.foregroundStyle(_:)（既存 API の指定先をラベルへ） | https://developer.apple.com/documentation/swiftui/view/foregroundstyle(_:) | iOS15+ | はい |

Apple の .md 本文を同フォルダ fixedsize.md、foregroundstyle.md に保存。fixedSize は理想の幅を使い、文字列全体を表すための幅になる。境界を超える可能性もある API なので、4条件の実画面で収まりを確認した。

## 画面の状態と識別子

以下はソース上の対応（画面全体の視覚合否や全 Preview の実レンダーを示さない）。今回の画面撮影は S5 の通常・日英・AX5・ダークのみ。

| 画面 | 通常 | 空 | 読み込み中 | エラー | Preview（ソースに存在） |
|---|---|---|---|---|---|
| S1 | HomeView.swift:151,192 | :123 | :56 | :95,192 | 通常 / 通常（読書中） / 空 / 読み込み中 / エラー（読み込みの失敗） / エラー（読み始めの保存の失敗） / AX5 / ダーク（:259〜） |
| S2 | AddBookView.swift:48 | :48、canSave :44 | なし：読むデータなし、保存後 didSave :15 | :52（保存失敗）、総ページ数入力の検証 | 通常 / 空 / エラー（総ページ数が範囲の外） / エラー（保存の失敗） / 題名の上限（形B） / AX5 / ダーク（:193〜） |
| S3 | BookDetailView.swift:138,219 | :138（記録0件） | :81 | :110,219、削除失敗はS7 | 通常 / 空 / 読み込み中 / エラー（読み込みの失敗） / エラー（読み始めの保存の失敗） / 別の本が読書中 / AX5 / ダーク（:413〜） |
| S4 | ReadingView.swift:219、状態の分岐 | なし：本が確定した後に入る | なし：開始時刻から即時計算 | ReadingView.swift:311、ReadingFailure :13 | 通常（読書中） / 通常（一時停止中） / エラー（一時停止の保存の失敗） / エラー（再開の保存の失敗） / エラー（終えるの保存の失敗） / AX5 / ダーク（:378〜） |
| S5 | FinishSessionView.swift:20、入力 :129 | :26、空ページは保存可 | なし：開く時点で値確定。保存後 canSave false（ReadingView.swift:126） | FinishSessionView.swift:38,51,156（数値・保存・キャンセル） | 通常 :193 / 空（今のページが空）:199 / エラー（範囲の外）:205 / エラー（保存の失敗）:211 / エラー（やめる保存の失敗）:217 / AX5 :223 / ダーク :231 |
| S6 | BookDetailView.swift:38（alert） | なし：対象1件 | なし：読むものなし | 失敗時S7へ | S6/通常（記録を消す確認）:455 |
| S7 | BookDetailView.swift:54（alert） | なし：知らせだけ | なし | これ自体がエラー | S7/通常（記録を消せなかった知らせ）:465 |

オフラインは全 S1〜7 で通常と同じ（画面の処理は端末内だけ）。権限を断られた状態は全画面なし（権限を求めない）。一部だけ読めた状態は S1/S3 は保存先を一度に読むためなし、S2 は入力だけ、S4 は読書1件、S5 は入力で読むのが1件、S6 は対象1件、S7 は知らせだけなのでなし。以上は design 5 の理由。

- design 6 の識別子欄から抽出した固有名73件：70件は製品 Swift に同じ文字列、3件の session.state.idle/reading/paused は RootView.swift:84,113 の stateName と rawValue で生成。静的な対応73/73。実行時の全73件の合否をここで主張しない。詳細 design-id-audit.json。
- S5 の既存識別子・押せる条件・保存処理は不変。session.finish.save と saveKeyboard は同じ model.saveSession、同じ !model.canSave を使う。
- Localizable75キー、InfoPlist1キー。AC39 スクリプトの判定は untranslated_keys=0。

## 修正前後の証拠

同じ finishing-seed.json を使い、同じ専用端末に simctl launch した。capture.py に環境変数と引数、撮影コマンドを保存。

| 条件 | 修正前 | 修正後 | 実画像で確認した内容 |
|---|---|---|---|
| 日本語・通常ライト | before-light.png | candidate-light.png | キーボード保存「保」程度→「保存」全文 |
| 日本語・通常ダーク | before-dark.png | candidate-dark.png | キーボード保存全文、上部保存ラベル黒→白 |
| 日本語・AX5ライト | before-ax5.png | candidate-ax5.png | キーボード保存全文。スクロールする既存フォームは維持 |
| 英語・通常ライト | before-en.png | candidate-en.png | キーボード「...」→ Save 全文。日本語題名は四角のまま |

ダークの上部保存文字の同一矩形 (1020,270)-(1120,330)、画像1206×2622の元解像度で比較：修正前 black=1457px,white=0px、修正後black=0px,white=1457px。主な塗りは両方 (159,88,51)=#9F5833 で3716px。dark-label-pixels.txt。日本語・AX5・英語のいずれもキーボード保存を削除せず、標準部品のまま表示した。

## 実行したコマンドと結果

- 最初の Debug：xcodebuild build -project ios/Yomutoki.xcodeproj -scheme Yomutoki -configuration Debug -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO。終了0、BUILD SUCCEEDED。debug-build.log。
- make ios-build：終了0。Debug/Release BUILD SUCCEEDED、XcodeGen2.46.0 SHA検査、ファイル保護、Releaseのテスト文字列・URL scheme非混入も成功。ios-build.log。warning 1件（AppIntentsメタデータ、Debugが既にビルド済みのためRelease分のみ）。Swiftコンパイラ警告0。
- xcodebuild test -project ios/Yomutoki.xcodeproj -scheme Yomutoki -testPlan Unit -destination 'platform=iOS Simulator,id=B18DB71A-DB50-4F84-9DDD-7D63541CF3BB' -resultBundlePath /private/tmp/reading-app-pr2-s5-fix-20261023/unit.xcresult CODE_SIGNING_ALLOWED=NO：終了0、TEST SUCCEEDED。69件・12suite成功、失敗0・skip0。unit.log / unit-summary.json。warning2件（AppIntentsのみ）、Swift警告0。
- Acceptance：下記。終了0、TEST SUCCEEDED、ja_JP/en_US 各3件（計6件）成功、失敗0・skip0。acceptance.log / acceptance-summary.json / acceptance.xcresult。warning6件は各ケース1件の既存 Invalid frame dimension（Swiftのコンパイル警告0）。最終ケース終了後、診断収集が600秒で timeout したが、xcodebuild は終了0で結果保存した。診断収集が完全に成功したとは扱わない。

```sh
xcodebuild test -project ios/Yomutoki.xcodeproj -scheme Yomutoki -testPlan Acceptance \
  -only-testing:YomutokiAcceptanceTests/FinishInputAcceptanceTests/test_AC48_swipeDownDismissEqualsCancel \
  -only-testing:YomutokiAcceptanceTests/FinishSessionAcceptanceTests/test_AC9_enteringPageRecordsProgress \
  -only-testing:YomutokiAcceptanceTests/ReadingScreenAcceptanceTests/test_AC63_beginFinishRetryWhileReading \
  -destination 'platform=iOS Simulator,id=B18DB71A-DB50-4F84-9DDD-7D63541CF3BB' \
  -resultBundlePath /private/tmp/reading-app-pr2-s5-fix-20261023/acceptance.xcresult CODE_SIGNING_ALLOWED=NO
```

再試行オプション、待機上限や期待値の変更なし。新たな全160件の実行とは区別する。make ios-test 全体は今回未実行（親の指定した局所完了条件に従う）。

手引き4章の検査（対象 ios/Yomutoki 内Swift、body処理だけScreens）：concurrency0、legacy0、数値font/固定高さ/直書き色0、onTapGesture0、強制アンラップ0、print/apiKey/secret0、TODO等0、Formatter/sorted/filter0、階層foregroundStyle0、privacy API13行。static-audit.jsonに全件の場所と文。

privacy13行はすべて既存UserDefaults：App/YomutokiApp.swift55,68（組み立て）、Debug/UITestHooks.swift529,562,738（テストseedの印）、Screens/ReadingView.swift3（下書きは入れないというコメント）、Telemetry/TelemetryRecorder.swift3,19,25（端末内計測の印）、Telemetry/TelemetrySink.swift10,14,20,28（端末内イベント回数）。PrivacyInfo.xcprivacy はNSPrivacyAccessedAPICategoryUserDefaults/CA92.1に対応済み。新規APIがないので変更なし。

## 未解決

- 英語のみの優先言語で日本語の題名が四角になる件は、下記対照で製品の外でも再現した。ランタイムと言語指定のフォント代替に依存すると推定する。ほかのランタイム・実機での確認は未完了。製品のフォントや locale は固定していない。
- Invalid frame dimension (negative or non-finite) は今回も残る。AC9/48の修正前 baseline ログ、AC63の過去ログでも観測済み。アプリのファイル・行は出ず、OS/Xcodeの差もあるため原因は未特定。表示の欠けと同じ原因であるとは主張しない。
- 全画面・全状態の正式なデザイン審査、AX監査、全高影響AC5回、探索、iOS17実機、Instruments、weak参照寿命テスト、Thread Sanitizerは今回未検証。G3 PASSや完成とはしない。

## 英語の日本語題名：標準部品との対照

同じ iPhone17 / iOS26.0 上で、製品を変更せず優先言語だけ変えて撮影した。UITEST_LOCALE=en_US、-AppleLocale en_US は同じ。

| 表示 | -AppleLanguages (en) | -AppleLanguages (en,ja) |
|---|---|---|
| 製品の S5 | 坊っちゃん が5個の四角 | 坊っちゃん が全文表示 |
| 製品と別の一時アプリ：UIKit UILabel / UIFont.preferredFont footnote・body・headline | 同じ5文字が四角 | 全文表示 |
| 同一時アプリ：SwiftUI Text(verbatim:) / .footnote・.body | 同じ5文字が四角 | 全文表示 |

font-product-en.png、font-product-en-ja.png、font-native-en.png、font-native-en-ja.png を実際に開いて確認した。したがって S5 の独自な文字加工・色・フォームだけの不具合としての根拠はなく、当ランタイムの標準フォント代替と言語の組み合わせに依存すると推定する（OS全般や実機にも共通とは断定しない）。製品のフォントや言語を無条件に日本語へ固定する変更は加えない。

対照は製品に入らない一時アプリ（com.example.yomutoki.fontdiagnostic）。FontDiagnostic.swift / FontDiagnostic.app、font-compare.py、font-compare.log に再現内容を残した。ネイティブUILabelとSwiftUI Text以外に製品のデータ・モデル・スタイルを使っていない。診断専用コードは数値間隔などがあるが製品へ追加していない。

診断アプリのコンパイル（終了0、警告0）：

```sh
xcrun --sdk iphonesimulator swiftc -parse-as-library \
  -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk \
  -target arm64-apple-ios17.0-simulator \
  /private/tmp/reading-app-pr2-s5-fix-20261023/FontDiagnostic.swift \
  -o /private/tmp/reading-app-pr2-s5-fix-20261023/FontDiagnostic.app/FontDiagnostic
```

診断だけで使ったAPIの確認：UILabel https://developer.apple.com/documentation/uikit/uilabel （iOS2+）、UIFont.preferredFont(forTextStyle:) https://developer.apple.com/documentation/uikit/uifont/preferredfont(fortextstyle:) （iOS7+）、UIViewRepresentable https://developer.apple.com/documentation/swiftui/uiviewrepresentable （iOS13+）。.mdの本文を保存。

## 引き渡し

- 診断アプリは専用端末から uninstall 済み（restore.log 終了0）。再現用ソースと .app はこの証拠フォルダだけに残す。
- 専用端末 B18DB71A-DB50-4F84-9DDD-7D63541CF3BB は Booted、appearance=light、ja_JP / (ja)、通常サイズL、finishing のS5を表示して引き渡す。ほかの端末は操作していない。
- 製品ファイルのSHA-256：d056eb4a904342171c4193dcf1e25f94623dcae4eefa8544dd9da0d44069fea8（FinishSessionView.swift）。product.patch に2行の差分。git diff --check は終了0。
- 親の文書変更（docs/approvals、docs/reviews、docs/progress）以外に、今回の製品差分はこの1ファイルだけ。
