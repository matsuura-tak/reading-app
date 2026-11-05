# 001-reading-session G3 r2 製品の直し（4体目）ios-engineer の報告

ios-engineer（4体目）の報告です。BASE は 2daf7d6 で、始める前に `git rev-parse --short HEAD` で確かめました。コミットはしていません。

**結論**：頼まれた3件は直り、完了条件のコマンドはすべて通りました。
- W-1・W-2 の読み上げは「羅生門、61ページ。…」の形になりました。
- S-8 の `register.footer` の「Text clipped」は監査から消えました。
- S-1 の AX5 では、「しおりを挟む」が帯に隠れなくなりました。

残っている点は2つです。
- `widget.unavailable` の見た目の状態は、まだ作っていません。
- 監査で N（BannerNotice）に Contrast failed が1件、新しく出ました。原因は確かめていません。

どちらも「未解決」に書きました。

## 変更したファイル
- `/Users/takumamatsuura/reading-app/ios/ReadingKit/Sources/ReadingCore/WidgetSpokenStrings.swift`（新規）：読み上げの文を入れる型 `WidgetSpokenStrings` です。
  - 場所の読み方を作ります（`p.61` は「61ページ」、`位置1450`・`Loc 1450` は「位置1450」、`52%` は「52パーセント」）。
  - 書式は design/ 6 のとおりに選びます（`widget.spoken`、`.noPage`、`.noLine`、書名だけ）。
  - `.japanese` と `.english` は design/ 7 の値の写しです。
- `/Users/takumamatsuura/reading-app/ios/ReadingKit/Sources/ReadingCore/VerticalLineLayout.swift`：`buildWidgetAccessibilityLabel(snapshot:strings:)` を「書名、場所。一行」にしました。
  - 著者は入れません。一行は保存した `latestLine` から作り、縦書き用の字形は外します。
  - 隠す設定では書名の所を `widget.hidden` にし、一行を読みません。名無しの今の本では `widget.currentBookAsTitle`、今の本がなければ `widget.empty` を読みます。
  - `composeWidget` に `strings:` を足しました。
- `/Users/takumamatsuura/reading-app/ios/ReadingKit/Sources/ReadingStore/SnapshotStore.swift`：H22 のラベルも同じ関数と同じ文で組むようにし（`spokenStrings`）、書名を2回つないでいた所をやめました。
- `/Users/takumamatsuura/reading-app/ios/ReadingApp/Shared/ReadingWidgetSurfaceViews.swift`
  - `ReadingWidgetStrings.spoken`（String Catalog を通した文）と `widgetLabel(for:)` を足しました。W-1・W-2 はこれを使います。
  - W-3 の文の部分を1つのラベルにしました。待つ状態は「書名、61ページ。一行」、読書中は「書名、22:00 から読書中」、終えた直後は「書名、10分、61ページ」です。
- `/Users/takumamatsuura/reading-app/ios/ReadingApp/Model/ReadingAppModel.swift`：起動時に `snapshotStore.spokenStrings` を入れます。
- `/Users/takumamatsuura/reading-app/ios/ReadingApp/UITestHooks/UITestHookReadoutBuilder.swift`：縦書きの読み出しを、同じ文で組むようにしました。
- `/Users/takumamatsuura/reading-app/ios/ReadingApp/Views/SessionResultAndGuideViews.swift`：S-5 の読み上げを `widgetGuide.preview.label` ＋ W-1 のラベルにしました。
  - S-10a は中の W-1 の View が新しいラベルを持つだけで、`store.preview` のラベルは変えていません。
- `/Users/takumamatsuura/reading-app/ios/ReadingApp/Views/BookRegistrationViews.swift`：`register.footer` を直しました。
  - **原因**：Text 自身の要素の枠は、一番長い行の幅（341pt、親は 354pt）になります。監査はその幅で組み直すので行が増え、切れていると判定していました。`frame(maxWidth:)` も `lineLimit(nil)` も Text 自身の要素の枠を変えないため、3体目の試しでは変わりませんでした。
  - **直し方**：幅いっぱいの枠に `.accessibilityElement(children: .combine)` を付け、その枠を1つの要素にしました。
  - 文も design/ 7 の `register.footer` にしました。これまでは design/ と違う文を `AppL10n.pick` で書いていました。
- `/Users/takumamatsuura/reading-app/ios/ReadingApp/Views/BookmarkHomeView.swift`：S-1 の下の帯を変えました。
  - `VStack` の下に置いていた帯を `safeAreaBar(edge: .bottom)` に替え、帯の自作の背景をやめました。帯の裏に入る中身は、OS の端の効果でぼけます。
  - design/ 9 の S-1 に合わせ、AX1 以上では伏せる案内（`bookmark.flipHint`、`bookmark.flipHint.ebook`）をスクロールの一番下に移しました（`flipHints(book:)`）。帯は「読み始める」だけです。
- `/Users/takumamatsuura/reading-app/ios/ReadingApp/Resources/Localizable.xcstrings`：8キーを足しました（`page.spoken`、`location.spoken`、`percent.spoken`、`widget.spoken`、`widget.spoken.noPage`、`widget.spoken.noLine`、`widgetGuide.preview.label`、`register.footer`）。
  - どれも ja と en があり、コメントと manual が付いています。もとの並びと書式はそのままで、差分は足した行だけです。
- `/Users/takumamatsuura/reading-app/ios/ReadingKit/Tests/ReadingCoreTests/VerticalLineLayoutTests.swift`：期待値を「コンビニ人間、142ページ。…」にし、著者を含まないことを確かめるようにしました。
- `/Users/takumamatsuura/reading-app/ios/ReadingKit/Tests/ReadingCoreTests/WidgetSpokenLabelTests.swift`（新規）：design/ 6 の場合を9つ、ja と en で確かめます。
  - 場合：ページ、位置、％、場所なし、一行なし（檸檬）、場所も一行もなし、隠す設定、名無しの今の本、縦書き用の字形。
  - ほかに、今の本なし（`widget.empty`）と、表示の形から場所の読み方を決める4件を確かめます。
- `/Users/takumamatsuura/reading-app/ios/docs/001-reading-session-implementation-notes.md`：「7. 4体目」の節を足しました。
- 範囲の外（ios/AcceptanceTests/、contracts/、design/、docs/）は触っていません。

## API の確認
| API | URL | 対応 OS | 最低 iOS 26 以下か |
|---|---|---|---|
| `View.safeAreaBar(edge:alignment:spacing:content:)` | https://developer.apple.com/documentation/swiftui/view/safeareabar(edge:alignment:spacing:content:) | iOS 26.0〜 | はい |
| `View.scrollEdgeEffectStyle(_:for:)` | https://developer.apple.com/documentation/swiftui/view/scrolledgeeffectstyle(_:for:) | iOS 26.0〜 | はい。ただし試しただけで、最後のコードでは使っていません |

- 文書で開いたのは HorizontalEdge の版です。使ったのは `edge: .bottom`（VerticalEdge）の版で、文書は開いていません。ビルドが通ったことで在ることを確かめました。
- `String(format:locale:_:)` と `accessibilityElement(children:)` は、前から使っている API です。

## 画面の状態と識別子
- 今回変えたマスだけを書きます。
  - W-1・W-2 の読み上げの全部の場合（design/ 6 の505行目）：`VerticalLineLayout.swift` の `buildWidgetAccessibilityLabel`。単体テストは `WidgetSpokenLabelTests` です。
  - W-3：`ReadingWidgetSurfaceViews.swift` の `liveActivityLabel`。
  - S-1 の AX5：`BookmarkHomeView.swift` の `activeBookSection` と `activeBookBottomBar`。
  - S-8 の `register.footer`：`BookRegistrationViews.swift` の menuContent の末尾。
- Preview は増やしていません。
- 識別子は名前を変えていません（`widget.rectangular`、`widget.small`、`widgetGuide.preview`、`liveActivity.banner`、`register.footer`、`bookmark.flipHint`、`bookmark.flipHint.ebook`、`bookmark.start`）。
- 足した8キーは ja と en がそろっていて、そろっていないものは0です。
- 全マスの表と、6章の識別子の一致数の表は、今回も作っていません（未解決 6）。

## 実行したコマンドと結果
- `make ios-build`：終了コード 0、`** BUILD SUCCEEDED **`、warning は0行です（ログ：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/r4/build.log）。
- `swift test --package-path ios/ReadingKit`：終了コード 0。ReadingCoreTests は 20件・6スイート、ReadingStoreTests は 8件・1スイートで、どちらも全部通りました。
- テスト用のビルド：`xcodebuild build-for-testing … -derivedDataPath …/scratchpad/r3/dd` が終了コード 0 で、warning も error も0です。
- 受け入れテスト：`xcodebuild test-without-building … -only-testing:ReadingAcceptanceTests/WidgetAndActivityAcceptanceTests -only-testing:ReadingAcceptanceTests/BookmarkAcceptanceTests -only-testing:ReadingAcceptanceTests/RegistrationAcceptanceTests`（iPhone 17、iOS 26.0、E5664965）
  - 結果は `** TEST EXECUTE SUCCEEDED **` です。
  - 内訳は WidgetAndActivity 20件、Bookmark 18件、Registration 16件です。Japanese (ja) と English (en) でそれぞれ 54件成功、失敗0、飛ばした0でした。
  - G3EvidenceCaptureTests は別のクラスなので、この指定には入りません。
  - 結果のファイル：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/r4/accept.xcresult
- 監査：`TEST_RUNNER_G3_CAPTURE=1 TEST_RUNNER_G3_VARIANT=light TEST_RUNNER_G3_OUT_DIR=…/r4/audit` で `G3EvidenceCaptureTests/test_G3_accessibilityAudit` を ja で動かしました。テストのファイルは変えていません。
  - ログ：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/r4/audit/accessibility-audit.log。比べた元は r3/audit2 です。
  - テストは W-3〜W-5 の `hook.error`（`H22:w3:waiting` など）で失敗扱いになります。前からある件で、verifier の担当です。ログは最後まで書かれています。
  - S-8 は 1件から0件になり、`register.footer` の Text clipped は消えました。
  - `widget.rectangular`、`widget.small`、`widgetGuide.preview` の「Label not human-readable」は、3件から0件になりました。残っている「not human-readable」の20件は、どれもテストのつなぎ口の読み出しの要素（`hook.*`）です。
  - 件数の変化：W-1 は 27件から26件、W-2 は 25件から24件、S-5 は 24件から23件、S-3a は 1件から0件になりました。
  - 新しく出たもの：N（BannerNotice）に「Contrast failed [element=nil]」が1件です（前は0件）。
  - 変わらないもの：S-1 の縦書きの字「方」の Contrast 1件と、S-10a の14件は前からあります。
- AX5 の撮り直し：台本 /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/r4/ax5shots.sh を使いました（r3 の台本から、置き場所の行だけを変えたもの）。
  - 画像：
    - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/r4/shots/S1_ax5_light_ja.png
    - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/r4/shots/S1_ax5_dark_ja.png
    - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/r4/shots/S1_ax5_light_en.png
    - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/r4/shots/S1_ax5_dark_en.png
  - ja の light と dark では、「しおりを挟む」が全部見えます。3つめの「読み終えた」は帯の裏に入り、OS の端の効果でぼけて見えます。スクロールすると帯の上まで送れます。
  - 一度 `.scrollEdgeEffectStyle(.hard)` を試しましたが、「しおりを挟む」が字の途中で切れたのでやめました。
  - 台本が読む seed.json の本は「蜜蜂と遠雷」です。r3 の画像の本（羅生門）とは違います。
- Release：`xcodebuild … -configuration Release … -derivedDataPath …/r3/dd-rel build` が終了コード 0 で、warning は0です。
  - アプリ、ReadingWidgetExtension、ReadingBackgroundAssetsExtension のどれも、`nm -a` と `strings -a` の `UITestHook` は0件でした。
- 4章の検査（ios/ の中、テストを除く）
  - 並行処理を黙らせる書き方：1件。UITestHookCoordinator.swift の `#if UITEST_HOOKS` の中の `DispatchQueue.main.async` で、前からあるものです。
  - 古い書き方：0件。
  - `.system(size:)`・`.frame(height:)`・色の直書き：1件。W-2 の場所の行の高さ 16pt で、前からある design/ の値です。
  - `onTapGesture`：0件。`print`・`apiKey`・`secret`：0件。
  - TODO・FIXME・lorem・dummy：製品のコードは0件です。`ios/ReadingKit/.build` の中の SwiftPM が作ったファイルに6件ありますが、自分で書いたものではありません。
  - PrivacyInfo.xcprivacy は変えていません。Logger の書き方も変えていません。
- 差分は既存の11ファイルで +304 行・−75 行、ほかに新しいファイルが2つです。

## 未解決
1. **`widget.unavailable` の状態は作っていません。** 文は `WidgetSpokenStrings.unavailable` に入れました。ただ拡張は、写しを読めないときも空の写しを作って `widget.empty` を出します（`ReadingSharedContainer.loadWidgetSnapshot`）。見た目と読み上げを分けるには、拡張に状態を足す作業が別に要ります。
2. **監査の N（BannerNotice）の Contrast failed 1件が新しく出ました。** 要素は nil です。S-1 の帯の背景をやめたことが関わるかもしれませんが、確かめていません。verifier r3 か design-reviewer に見てほしいです。
3. **S-1 の AX5 で、3つめのボタンが端の効果でぼけて帯の裏に入ります。** design/ 決まり 59（主操作を下に固定し、上の内容だけを送る）に従った結果です。これで足りるかは design-reviewer に判定してほしいです。
4. **W-3 の読み上げの時刻と英語の文には、design/ 7 に専用のキーがありません。**
   - 時刻は design/ の「22時0分」でなく、`liveActivity.readingSince` の「22:00 から読書中」になります。
   - 終えた直後の英語は「…, 10 min, page 61」になります。
   - 専用のキーが要るなら designer に頼みたいです。
5. **H22 の `texts`（`widget.title` の「しおり」や `widget.empty`）には、ReadingStore の日本語の直書きが残っています。** 今回の範囲の外なので触っていません。
6. **画面の状態の表の全マスと、識別子の一致数の表は、今回も作れていません。**
7. **3体目の未解決 4〜7 はそのままです**（W-3〜W-5 を監査できない件、AC-91、`catalog.lookup` の灰の帯の撮影など。verifier r3 の担当）。

## 記録（指揮役が保存するときに書き足す）
- 日付：2026-11-02。BASE 2daf7d6。
- 指揮役の確かめ
  - 差分は ios/ の中だけ（ios/AcceptanceTests/ は触っていない）。既存11ファイル＋新規2ファイル。
  - scratchpad/r4/build.log に `** BUILD SUCCEEDED **`、コンパイラーの warning 0行。
  - scratchpad/r4/accept.xcresult の要約：`result Passed、totalTestCount 54、passed 54、failed 0、skipped 0`。
  - scratchpad/r4/shots/S1_ax5_light_ja.png を見た：一行が全部読め、「しおりを挟む」は全部見え、「読み終えた」は下の帯の裏で OS の端の効果でぼける（スクロールで送れる）。
- 指揮役の裁定
  - 未解決 1（`widget.unavailable` の状態）と未解決 5（H22 の texts の日本語の直書き）は、reviewer（コード）の判定の中で見てもらい、要修正なら次の直しでまとめて直す。
  - 未解決 2（N の Contrast 1件）と未解決 3（S-1 の AX5 の帯の裏）は、verifier r3 と design-reviewer r2 が見る。
  - 未解決 4（W-3 の読み上げのキー）は、design-reviewer r2 の指摘を待つ。
