# 001-reading-session G3 r2 製品の直し（3体目）ios-engineer の報告

## 要約
BASE は 563aa31 で、始める前に `git rev-parse --short HEAD` が 563aa31 であることを確かめました。コミットはしていません。触ったのは ios/ の中だけで、ios/AcceptanceTests/ には触っていません。

- **監査の42件は、なくなっていません。**
  - 確実に消えたのは、プレースホルダーと値が横に切れていた S-3a 2件、S-3b 1件、S-3c 1件です。2体目までの直しで W-1 の 11×132pt と W-2 の4件も消えています。
  - 一方で、W-1・W-2 と、その見本（S-5、S-10a）の縦書きの各字は、design/ が字の大きさを固定しているため、監査の「Dynamic Type font sizes are unsupported」がまとまって出ます。S-5 と S-10a は見本を design/ どおり「W-1 と同じ描画」にしたので、件数は**増えました**（S-5 は 13→24、S-10a は 5→14）。
  - 監査の合計は、直す前の HEAD で79件、直したあとで96件です（どちらも hook.* の要素を含む）。
  - 見本を直す前に戻すか、design/ を変えるかは、designer とテックリードに決めてほしいです（下の未解決の1）。
- **H33 の `catalog.lookup` の門は入れました。** シミュレーターで止めて撮る確かめはしていません。
- **AC-91 は、アプリが遅くなったのではなく、テストそのものが長いためでした。** ほかの負荷のない1台で動かしても、ja と en の両方が2分の上限を超えます。待ちはアプリの起動と終了（14回）でほぼ埋まっています。
- 関係する受け入れテスト74件（37件×ja/en）は全部通りました。

## 監査の42件（ja、light。`G3EvidenceCaptureTests/test_G3_accessibilityAudit` を、テストのファイルを変えずに環境変数 `TEST_RUNNER_G3_CAPTURE=1` で動かした）
| 画面 | 元の件数 | 直す前の HEAD | 直したあと | 何をしたか、なぜ直さないか |
|---|---|---|---|---|
| W-1 | 14 | 27 | 27 | 2体目までで、`widget.line` の 11×132pt の要素はなくなった。残りは3種類で、どれも直していない。①縦書きの14字の「unsupported」：design/ 9 の `type.book.line.widget.rectangular`（W6、17/15pt 固定）と ADR 0003 の収め方で大きさを固定しているため。`accessibilityHidden(true)` でも監査は字を数える。② `p.61` の「partially」と「clipped」：design/ の43pt の帯の中で縮めているため。③「Label not human-readable」：読み上げが「羅生門、芥川龍之介。p.61。…」で、design/ 6 の「羅生門、61ページ。…」と違う（未解決の2） |
| W-2 | 4 | 25 | 25 | 元の4件（ヒット領域、`羅生門`、`p.61` の切れ）はなくなった。いまは、20pt 固定の字14件と読み上げの1件が出る。理由は W-1 と同じ |
| W-3 | 1 | 監査できない | 監査できない | 撮影用のテストが、契約にない指定 `w3:waiting` を使っていて `hook.error=H22:w3:waiting` になる（W-4、W-5 も同じ）。テストは verifier の範囲。いまの W-3 は高さが中身に合うので、切れは消えている見込みだが、確かめていない |
| S-3a | 2 | 2 | 0（別に1） | `mark.lineField` と `mark.pageField` を `TextField(axis: .vertical)` にした（`lineLimit(1...6)`、`1...3`）。大きい文字で1行の欄の幅を超えて、横に切れていた。改行は `onChange` で取り除く。別に「Contrast failed」が1件、欄の上の見出し「ページ数（1〜9999）」に出た。同じ見出しの S-3b では出ていないので、画面の移り変わりの途中の判定とみているが、確かめていない |
| S-3b | 1 | 1 | 0 | 同じ直し |
| S-3c | 1 | 1 | 0 | `mark.lineField` を同じ直しにした。要素が nil の「Text clipped」3件は42件の外で、そのまま残る |
| S-5 | 13 | 13 | 24 | `widgetGuide.preview` を、拡張と同じ `ReadingLockScreenWidgetView` を 172×76 pt で描く形にした（design/ 3「W-1 と同じ縦書き描画」）。読み上げも design/ 3 の「ロック画面での見え方。」＋W-1 のラベルにした。その結果、固定の大きさの字21件、`p.61` 2件、読み上げ1件が出る |
| S-8 | 1 | 1 | 1 | `register.footer` に `frame(maxWidth:)` と `lineLimit(nil)` を足したが、変わらなかった。原因は分かっていない |
| S-10a | 5 | 5 | 14 | 見本の中の W-1 の縮小見本を、同じ `ReadingLockScreenWidgetView`（選んだ見た目の色）にした（design/ 3「W-1 の縮小見本」）。元の文字の切れ3件はなくなったが、固定の字12件と `p.61` 2件が出る |

## H33 の `catalog.lookup`（ios/ReadingApp/Views/BookRegistrationViews.swift）
- `runCatalogLookup(coalesce:perform:)` を足しました。
  - 門が素通りのとき（Release とふつうの起動）は、これまでどおり同期で引き、待ちを足しません。
  - 止めるときは、`ContinuousClock` で 0.3 秒を超えたら灰の帯を出します。帯は新しく足した `RedactedRowListView`（S-8a は1行、S-8c は3行）で、出たときに `markShown` を呼びます。
  - 放されてから引きます。
- S-8a はバーコードの1件（`appendScannedRow`）、S-8c は `manual.title` の入力で門を通ります。
- 止めている間は、`scan.hint` と `search.noResults` を出しません（「空の状態を先に出さない」）。S-8c は止めている間の入力では引き直さず、放したあとに最新の入力で1回引きます。
- 門は、ほかの対象と同じく View の側で `pass` しています。契約の「ReadingStore の読み込みの関数の中」と同じ形かは、reviewer の判断を待ちます。

## AC-91 の速さ
- `-only-testing:…/test_AC91_7種類の保存失敗時にエラーが出て変更前のデータが保たれる` を、シミュレーター E5664965（iPhone 17、OS 26.0）1台だけで動かしました。
  - 結果は ja と en の両方が `exceeded execution time allowance of 2 minutes` でした。止まった時点で、ja は92手、en は99手まで進んでいました。終了コード 65。
- xcresult の時間の内訳です。
  - アプリの起動（Open）から次の操作まで、1回 4.8〜6.9 秒です。中身は XCTest の automation session の準備に約2〜3秒、終了に約1.6秒、idle の待ちです。
  - 起動は14回以上あります。`waitForExistence` は、すでにある要素でも1回約1.1秒かかります。
- アプリの側に、余計なアニメーションや遅延はありません。`GatedLoadView` は門が素通りなら最初から中身を出し、何も待ちません。
- 直す前の HEAD でも同じでした（ほかのテストと並べて動かした回で、en が2分5秒）。テストの長さの問題なので、テストを分けるか上限を延ばすかを verifier に頼みます。
- ログ：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/r3/ac91-2.log、xcresult：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/r3/ac91-2.xcresult

## AX5 の S-1（項目4）
- 撮った画像は次の4枚です。
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/r3/shots/S1_ax5_light_ja.png
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/r3/shots/S1_ax5_dark_ja.png
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/r3/shots/S1_ax5_dark_en.png
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/r3/shots/S1_ax5_light_en.png
- 目で見たのは前の3枚です。3枚とも、一行（2〜3行）が全部読め、「読み始める」とも重なっていません。
- ただし、ja の明るい画面と dark では、スクロールの中の2つめのボタン（「しおりを挟む」）が、下に固定したボタンの帯に途中で隠れて見えています。en の dark では見えていません。スクロールすれば出るはずですが、確かめていません。
- 撮影の台本は /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/r3/ax5shots.sh です。文字の大きさと見た目は元に戻し、シミュレーター C91AC080 を止めました。

## 変更したファイル
- ios/ReadingApp/Views/BookRegistrationViews.swift：`catalog.lookup` の門と S-8a・S-8c の灰の帯、`register.footer` の配置（効果なし）
- ios/ReadingApp/Views/BookmarkMarkFlowViews.swift：`mark.lineField` 2か所と `mark.pageField` を折り返す欄にし、改行を取り除く
- ios/ReadingApp/Views/LoadingPlaceholderViews.swift：`RedactedRowListView` を足し、`RedactedRowsPlaceholderView` はそれを使う形に。Preview「S-8c/loading」を足した
- ios/ReadingApp/Views/SessionResultAndGuideViews.swift：S-5 の見本を共有の W-1 の View にし、読み上げを design/ 3 に合わせた
- ios/ReadingApp/Views/SettingsAndStoreViews.swift：S-10a の W-1 の縮小見本を共有の View にした
- ios/docs/001-reading-session-implementation-notes.md：2章の H33 の表、6章（3体目）を足した
- 差分は6ファイル、+175 行、−57 行です。

## API の確認
- `TextField(_:text:axis:)` は iOS 16 から使えます（最低 iOS 26 以下）。developer.apple.com は今回開いておらず、根拠はビルドが通ったことだけです。
- `ContinuousClock`、`.redacted` は前からこのコードで使っているもので、新しくはありません。

## 実行したコマンドと結果
- `make ios-build`：終了コード 0、`** BUILD SUCCEEDED **`、warning の行は0です（最後の回は差分のビルド）。
  - その前の全体のビルドで出た「warning」は `appintentsmetadataprocessor … Metadata extraction skipped` の1行だけで、コンパイラの警告ではありません。
- `swift test --package-path ios/ReadingKit`：17件、5スイートが通りました。ReadingKit は変えていません。
- 受け入れテスト（`xcodebuild test-without-building`、E5664965、ja と en）：終了コード 0、全部で74件成功、失敗0、飛ばした0です。
  - 動かしたのは `BookmarkAcceptanceTests`（18件）、`RegistrationAcceptanceTests`（16件）、`test_AC96`、`test_AC99`、`test_AC105` で、ja・en でそれぞれ37件です。
  - xcresult：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/r3/accept.xcresult
- 監査
  - 直す前：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/r3/audit-base/accessibility-audit.log
  - 直したあと：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/r3/audit2/accessibility-audit.log
  - テストは W-3〜W-5 の `hook.error` で失敗扱いになりますが、ログは最後まで書かれています。
- Release のビルド（-derivedDataPath はスクラッチパッド）：終了コード 0 です。アプリ、ReadingWidgetExtension、ReadingBackgroundAssetsExtension のどれも、`nm -a` と `strings -a` の `UITestHook` は0件でした。`LoadHoldGate` の記号は、アプリと Widget 拡張に残ります（契約どおり）。
- 4章の検査（ios/ の中、テストを除く）
  - 並行処理を黙らせる書き方：1件。UITestHookCoordinator.swift:418 の `DispatchQueue.main.async` で、前からある `#if UITEST_HOOKS` の中の Darwin 通知の受け口です。
  - 古い書き方：0件。
  - `.system(size:)`・`.frame(height:)`・色の直書き：1件。ReadingWidgetSurfaceViews.swift:324 の W-2 の場所の行の高さ 16pt で、design/ screens.md の W-2 の値です。
  - `onTapGesture`：0件。`print`・`apiKey`・`secret`：0件。TODO・FIXME・lorem・dummy：0件。
- PrivacyInfo.xcprivacy は変えていません。

## 未解決
1. **W-1・W-2 の見本の固定の大きさの字（S-5 と S-10a）**（designer とテックリードに決めてほしい）：
   - design/ が字の大きさを固定し、OS もウィジェットの枠を固定しているので、監査の「Dynamic Type unsupported」は直せません。
   - 選べる道は3つです。(a) 監査の例外として受け入れる。(b) アプリの中の見本（S-5、S-10a）だけを、画像に描いてラベルを付ける。監査は字を見なくなりますが、大きくならないことは変わりません。(c) S-5・S-10a を直す前の見本に戻す。こちらも固定の枠なので、元の13件と5件は残ります。
   - 私は、design/ に合うので今の形がよいと考えます。
2. **W-1・W-2 の読み上げ**：design/ 6 は「羅生門、61ページ。…」（著者なし、場所を読む形）です。実装の `VerticalLineLayout.buildWidgetAccessibilityLabel` は「羅生門、芥川龍之介。p.61。…」で、監査は「not human-readable」と出します。ReadingKit の単体テストも今の形を期待しています（VerticalLineLayoutTests.swift:147〜148）。手数が足りず、直していません。
3. `register.footer` の切れの原因は分かっていません。
4. W-3〜W-5 は、撮影用のテストの指定（`w3:waiting` など）が今の H22 と合わず、監査できていません（verifier）。受け入れテストのターゲットには `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES` で落ちる警告があります（WidgetAndActivityAcceptanceTests.swift:1163 ほか）。`make ios-test` はこの設定を付けないので影響はありませんが、知らせておきます。
5. AC-91 はテストの長さの問題です（verifier）。
6. `catalog.lookup` を止めて灰の帯が出ることを、シミュレーターでは確かめていません。r2b の「未解決 5」（S-3c の61字、`settings.save` の失敗、`shelf.load.error`、`scan.hint`、`book.title.invalid`、S-8b の0件、S-7c の `camera.denied`）も手を付けていません。verifier r3 に頼みます。
7. 縦に伸びる欄に変えた `mark.lineField` と `mark.pageField` の見た目は、撮って確かめていません。S-3a の「Contrast failed」1件の再確認も残っています。
8. 画面の状態の表の全マスと、識別子の一致数の表は、今回も作れていません。

## 記録（指揮役が保存するときに書き足す）
- 日付：2026-11-02。BASE 563aa31。3体目は100手の上限で止まり、そのあと報告を返した。
- 指揮役の確かめ
  - コードの最後の変更は 11:05。受け入れテスト（accept.log）は 11:05:50 のテスト用ビルドで 11:21 に始まり、37件×ja/en で失敗0。監査（audit2、11:11）も最後のコードで撮っている。
  - Release（scratchpad/r3/dd-rel）の `nm -a` と `strings` で `UITestHook` は0件（指揮役が数え直した）。
  - AC-91 は直す前の HEAD（ac91-base）でも2分の上限を超えている。3体目の変更が原因ではない。
- 指揮役の裁定
  1. **W-1・W-2 と、その見本（S-5、S-10a）の縦書きの字の「Dynamic Type font sizes are unsupported」**：(a) 受け入れる（監査の例外）。理由：ロック画面のウィジェットは OS が枠の大きさを決め、design/ 9 が字の大きさを固定している。アプリの中の見本は「ロック画面でこう見える」を見せるためのものなので、大きくすると嘘になる。読み上げは全体を1つのラベルにしてある（AC-99）。verifier r3 と design-reviewer r2 には、この例外を伝える。
  2. **W-1・W-2 の読み上げ（未解決 2）**：AC-99 と design/ 6 の文「（書名）、61ページ。（一行）」と違うので、直す（ios-engineer の4体目。ReadingKit の単体テストも合わせて直す）。
  3. **`register.footer` の切れ（未解決 3）**と、**AX5 の S-1 で2つめのボタンが下の帯に隠れる件**：ios-engineer の4体目に頼む。
  4. **W-3〜W-5 を監査できない件、受け入れテストの警告、AC-91 の長さ**：verifier r3 に頼む。
  5. **`catalog.lookup` の灰の帯、r2b の「未解決 5」、縦に伸びる欄の見た目の撮影**：verifier r3 が撮る。
