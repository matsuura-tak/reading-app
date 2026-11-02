（指揮役の注）G3 r2 の製品の直し、2体目（ios-engineer）。手数の上限で途中まで。作り手の報告で、判定ではない。

## 要約
手数の上限（約70回）に近づいたので、ここまでの結果を返します。**完了ではありません。**

いちばん大事な点は次の3つです。
- **AC-142 の停止は、アプリの不具合でもテストの不具合でもありませんでした。** Mac が電池切れで眠ったことが原因です。根拠は下の節に書きました。
- **`make ios-test` はまだ動いています。** 背景で `caffeinate -dims` を付けて動かしました。ログは /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g3fix/ios-test-r2b.log で、最後に `exit=` の行が付きます。このテストはシミュレーター E5664965（iPhone 17、OS 26.0）を使っています。**終わるまで、次の役（reviewer、verifier r3）は始められません。**
- 監査の残り（項目9）は手を付けていません。`make check-contracts` も動かしていません。

BASE は 14737ca で、始める前に HEAD と同じことを確かめました。コミットはしていません。触ったのは ios/ の下だけで、ios/AcceptanceTests/ には触っていません。

## AC-142 の切り分け（項目1）
- **原因は Mac の眠りです。** `pmset -g log` に次の2行があります。
  - `2026-11-02 02:34:23 Sleep Entering Sleep state due to 'Low Power Sleep'`
  - `2026-11-02 07:25:04 Wake from Hibernate [CDNVA] : due to acattach/UserActivity`
- テストのログの時刻と、ぴったり重なります。
  - AC-142 が始まったのは 02:34:21 で、眠りに入る2秒前でした。
  - 失敗は開始から 17,469 秒後で、07:25 ごろにあたります。電源につないで目覚めた直後です。
  - 目覚めたあと、アプリのアクセシビリティの受け口が無くなっていたため、`kAXErrorServerNotFound` が出ました。そのあと実行役が立ち直しています。
- 同じ回の ja 側では、AC-142 は 18.3 秒で成功していました。
- **再現しないことも確かめました。** HEAD のコードで、AC-142 だけを ja と en それぞれ3回動かし、6回とも成功しました（約20〜30秒ずつ、Executed 3 tests, 0 failures が2回）。終了コードは 0 です。
  - コマンド：`caffeinate -dims xcodebuild test ... -destination 'platform=iOS Simulator,id=E5664965-…' -derivedDataPath …/scratchpad/g3fix/dd-ac142 -test-iterations 3 -only-testing:ReadingAcceptanceTests/BookmarkAcceptanceTests/test_AC142_…`
  - ログ：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g3fix/ac142-iter.log
  - 結果のファイル：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g3fix/ac142-iter.xcresult
- テストの側にもアプリの側にも直すところはありません。
- 次の役への頼み：長いテストは電源につなぎ、`caffeinate -dims` を付けて動かしてください。いまの設定は `lowpowermode 1` です。verifier r2 の不時停止も同じ原因かどうかは、確かめていません。

## 変更したファイル
- `ios/ReadingApp/Views/BookRegistrationViews.swift`
  - 警告を直しました。PhotosPicker のラベルの中で main actor の `palette` を読んでいたので、閉包の外で作る `PhotosPickerThemedLabel` に替えました。
  - S-8a：まだ1冊も読んでいないとき、一覧の所に `scan.hint` を出すようにしました。
  - S-8b の保存：書名が空、または101字以上のときは `book.title.invalid` を出して保存しません。これまでは、先頭の候補で黙って書名を埋めていました。`cover.save` を押せなくする条件も外しました。
  - S-8b の0件：`ContentUnavailableView` で `mark.ocr.none`、`cover.retake`（撮り直す）、`register.manual`（手で入れる）を出すようにしました。これまでは `cover.toManual` だけでした。
- `ios/ReadingApp/Views/BookmarkMarkFlowViews.swift`
  - S-3：前のしおりがないときは、識別子を `mark.later.note.empty` にしました。
  - en の文を design 7 の "Your bookmark stays where it was." に合わせました。
- `ios/ReadingApp/Views/ShelfAndBookDetailViews.swift`
  - S-6：`ShelfListViewState.loadError` を足しました。`shelf.load.error` と `shelf.retry` を出します。Preview「S-6/empty」「S-6/loadError」も足しました。
  - S-7：`colophon.capture` を常に出すようにし、文を「奥付を撮って補う」にしました。根拠は screens.md の S-7 の例です。奥付がそろった本でもボタンを出しています。
  - S-7 の記録の節を H33 の `book.load` の門で包みました。
  - S-7c：カメラの許可が拒否されているとき、`camera.denied` と `camera.openSettings` を出すようにしました。S-7c は S-7 と S-9 の両方から開きます。
- `ios/ReadingApp/Views/FinishNightView.swift`：S-9 の候補の節を H33 の `recommend.load` の門で包みました。
- `ios/ReadingApp/Views/SettingsAndStoreViews.swift`
  - S-10a の `store.buy`：`storekit.products` の門と `storekit.purchase` の門を置き、止めている間はボタンの位置に ProgressView を出します。
  - 購入の処理は、ボタンの action の中の Task で動かす形に変えました。
- `ios/ReadingApp.xcodeproj/project.pbxproj`
  - プロジェクトの3つの構成に `COPY_PHASE_STRIP = NO` を入れました。拡張を埋め込むときの「not stripping binary」の警告を消すためです。
  - Background Assets 拡張の埋め込み先が `ReadingApp.app/ReadingApp.app/Extensions` と二重になっていたので、`dstSubfolderSpec 1→16` で直しました。いまの成果物では `ReadingApp.app/Extensions/ReadingBackgroundAssetsExtension.appex` にあることを確かめました。
- `ios/ReadingBackgroundAssetsExtension/BackgroundAssetsHandler.swift`：`import ExtensionFoundation` を足しました（`@main` の警告）。
- `ios/docs/001-reading-session-implementation-notes.md`：2章の H33 の表を更新し、5章（2体目で足したこと）を足しました。

## API の確認
- `ContentUnavailableView`、`PhotosPicker`、`ContinuousClock` は、前からこのコードで使っているものです。今回の新しい使い方は `ContentUnavailableView` だけです（iOS 17 から使えるので、最低 iOS 26 以下）。
- `ExtensionFoundation` の import は、コンパイラの警告が名指ししたものです。developer.apple.com は今回開いていません。根拠はビルドが通ったことだけです。

## 画面の状態と識別子
全部のマスを照らす表は、時間切れで作れていません。今回足した状態は次のとおりです。

| 画面と状態 | 識別子 | Preview |
|---|---|---|
| S-6 の読めない | `shelf.load.error`、`shelf.retry` | 「S-6/loadError」 |
| S-6 の0冊 | （既存） | 「S-6/empty」 |
| S-8b の0件 | `mark.ocr.none`、`cover.retake`、`register.manual` | Preview なし |
| S-8a のまだ読んでいない | `scan.hint` | Preview なし |
| S-7c のカメラ拒否 | `camera.denied`、`camera.openSettings` | Preview なし |

- S-7、S-9、S-10a の読み込み中は H33 の門で出ます。Preview は足していません。
- 文言：今回の文はアプリの今の書き方（`AppL10n.pick`）に合わせ、String Catalog には足していません（下の未解決に書きました）。

## 実行したコマンドと結果
- **`make ios-build`（clean のあと）**：終了コード 0、`** BUILD SUCCEEDED **`。SwiftCompile と SwiftDriver の段が276あり、全部を作り直したことを確かめました。
  - ログ：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g3fix/build-clean.log
  - コンパイラの警告は0件です（前の25行のうち、palette の6件×2、strip、ExtensionFoundation、ExtensionKit の埋め込み先は消えました）。
  - 「warning:」を含む行が1つだけ残っています：`appintentsmetadataprocessor ... warning: Metadata extraction skipped, no AppIntents.framework dependency found`。ReadingBackgroundAssetsExtension の AppIntents のメタデータ抜き出しという道具のログで、コンパイラの警告ではありません。ただし、消す設定は確かめていません。
- **`make ios-test`**：まだ動いています（上のログ）。結果は出ていません。
- **`make check-contracts`**：今回は動かしていません。contracts/ には触っていません。
- **S-1 の AX5（項目8）**
  - 撮影の台本は /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g3fix/ax5shots.sh です。シミュレーター C91AC080 を使い、文字の大きさの設定と `-uitest-ax5` の両方で AX5 にしました。
  - en の明るい画面：一行（3行）が全部読め、ボタンより上にあり、重なっていません。画像は /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g3fix/shots/S1_ax5_light_en.png
  - ja の明るい画面は、起動直後で真っ白のまま撮れていました（S1_ax5_light_ja.png）。撮り直しが要ります。
  - dark の ja と en の2枚は、同じフォルダに撮れたはずですが、見ていません。
  - C91AC080 は、元からあったものを使って停止しました。新しくは作っていないので、消していません。
- **4章の検査**：数えていません。

## 監査の42件（項目9）
手を付けていません。S-3a 2、S-3b 1、S-3c 1、S-5 13、S-8 1、S-10a 5、W-1〜W-5 の約19件のどれも、監査を動かしておらず、0件になったかどうかは分かりません。

## 未解決（上の番号で）
- **1**：`make ios-test` の終わりを待つ必要があります。一緒に、S-8b の保存の挙動の変更（書名が空なら保存しない）と、`store.buy` の Task 化が、受け入れテストを落とさないかも確かめます。
- **2**：ja の明るい画面と dark の2枚を目で確かめる作業が残っています。
- **3**：`catalog.lookup` の門（S-8a の行の灰の帯と、S-8c の候補の待ち）がまだありません。
  - `store.load` を「画面に渡す所」で止める件は、1体目の実装ノートの2章のまま残しました。reviewer の判断を待ちます。
  - 門は、契約が求める ReadingStore の読み込みの関数の中ではなく、View の側（`GatedLoadView`、ボタンの action）で `pass` しています。1体目のやり方と同じです。これも reviewer の判断を待ちます。
- **5**：直したもののうち、シミュレーターで確かめられていない項目があります。
  - S-3c の61字、`settings.save` の失敗（1体目が直したもの）
  - 今回足した `shelf.load.error`、`scan.hint`、`book.title.invalid`、S-8b の0件、S-7c の `camera.denied`
  - S-9 から `colophon.capture` を押したときは、S-7c の中に `camera.denied` が出るはずですが、撮っていません。
- **6**：上の appintentsmetadataprocessor の1行が残っています。「警告0」に数えるかどうかは、テックリードに決めてほしいです。
- **9**：全部が残っています。
- **4章の検査、全部のマスの表、識別子の一致数、check-contracts**：まだです。
- **前からの欠け（範囲の外）**：アプリの文の多くが String Catalog を通さず、`AppL10n.pick` で直書きされています。今回の文も同じ書き方です。design 7 のキーを記号で使う形への移行は、別の作業として頼みたいです。

## 記録（指揮役が保存するときに書き足す）
- 日付：2026-11-02。BASE 14737ca
- 指揮役の確かめ：`pmset -g log` に `2026-11-02 02:34:23 Sleep Entering Sleep state due to 'Low Power Sleep' ... Using Batt (Charge:1%) 17441 secs` と `07:25:04 Wake from Hibernate ... due to acattach` がある。AC-142 の停止は Mac の電池切れの眠りと重なる。`lowpowermode 1`。
- 2体目が始めた `make ios-test`（電源につなぎ、`caffeinate` 付き。08:23〜10:06）の結果：終了コード2（`make: *** [ios-test] Error 65`）。
  - 落ちたのは1件だけ：`SettingsStoreIntentsAcceptanceTests.test_AC91_7種類の保存失敗時にエラーが出て変更前のデータが保たれる()`。2回とも `exceeded execution time allowance of 2 minutes` で、テストの実行役が立ち上げ直した（`Restarting after unexpected exit, crash, or test timeout` が2回）。止まった所は2回とも t≈125 秒の `mark.pageField` への入力の途中で、2分の上限に当たった所。
  - 前の回（01:44 の xcresult）でも AC-91 は ja が 118.7 秒で通り、en が2分の上限で落ちている。7種類の失敗を1つのテストで流すので、もともと上限の際にある。
  - ほかのテストは通った（最後の立ち上げの分で `Executed 23 tests, with 0 failures`）。AC-142 は今回は通った。
  - 指揮役の裁定：AC-91 はアプリが止まったのではなく、1つのテストの長さが上限を超えた。直すのは verifier（テストを7つに分けるか、このテストだけ `executionTimeAllowance` を延ばす）。ただし、ios-engineer の3体目には、AC-91 の1回の流れが前より遅くなっていないか（門や読み込み中の帯で待ちが増えていないか）を確かめてもらう。
