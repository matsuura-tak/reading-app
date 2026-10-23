# S3 A/B/C標準部品対照（第2フェーズ、2026-10-23）

A（swipeActionsのみ）、B（onDelete＋EditButtonのみ）、C（両方）のすべてで、hitRegion/type 4・element=nilが各3件再現した。すべてのfindingを失敗として残し、合計15 failures、UIテストexit 65。標準部品だけでも同型の指摘が出ることを確認したが、製品の指摘対象を特定した結果でも、製品G3を合格に変える結果でもない。

## 条件

[アプリsource](001-reading-session-G3-native-controls-r2/App/S3ABCControlApp.swift.txt)、[UIテスト](001-reading-session-G3-native-controls-r2/UITests/S3ABCControlUITests.swift.txt)、[XcodeGen spec](001-reading-session-G3-native-controls-r2/project.yml.txt)。製品のモデル・依存・トークン・実装コードを取り込まず、標準SwiftUIだけで独立した対照を作成した。

3条件に共通して次を含めた。

- 集計4行：最後のページ72、進み具合24%、総ページ数300、合計時間60分。Group内のLabeledContent、value TextのmonospacedDigitとprimary、Groupのprimary、accessibilityElement(children:.ignore)、accessibilityLabel/value/identifier。
- 記録3行：VStack(dateのsubheadline、HStack(minutesのbody＋monospacedDigit、pagesのbody))。VStackにはaccessibilityElement(children:.contain)を指定。
- Aは記録行にswipeActions内のdestructive Buttonのみ。BはForEach.onDeleteとtoolbar EditButtonのみ。Cは両方。削除callbackは空で、削除動作や編集モードへの切替は今回の試験対象外。初期の一覧状態を監査した。
- 日本語・ライト・通常large。第1フェーズの専用iPhone 17/iOS 26.0（23A343）、UDID `0DD0727D-F16F-4DD6-8759-549D6FAB596F`だけを再使用。AX5試験は追加していない。Xcode 27.1（27A9275）、Swift 6、deployment iOS 26.0。
- UIテストはcontinueAfterFailure=true、performAccessibilityAudit(for:.all)、全issueHandler=false。各状態の監査前PNG・AXtreeと全findingを保存した。

## 結果

| 条件 | type 4 hitRegion | type 4のelement | type 1 contrast | type 65536 dynamicType | 全finding |
|---|---:|---|---:|---:|---:|
| A swipeActionsのみ | 3 | 全3件nil | 2 | 0 | 5 |
| B onDelete＋EditButtonのみ | 3 | 全3件nil | 2 | 0 | 5 |
| C 両方 | 3 | 全3件nil | 2 | 0 | 5 |

[A/B/C raw log](001-reading-session-G3-native-controls-r2/ABC.log)、[機械集計](001-reading-session-G3-native-controls-r2/evidence/audit-summary.json)、`evidence/ABC.xcresult`に保存。テストケース開始1回、audit開始3回・終了3回。22.808秒、1テスト失敗・15 failures・0 unexpected・0 skipped。finding後のソース変更・再試行はない。第2フェーズではcompile/ハーネス修正も不要だった。

type 1の追加2件も除外していない。A/BではデフォルトSection header「坊っちゃん」「記録 3件」が対象で、Contrast nearly passedとの記述。Cは同じ記述の2件ともelement=nil。製品S3の元の指摘集合にはない追加所見なので、製品の同じ箇所への指摘と同一視しない。

## 画像とAXtreeの確認

3画像を実際に開いて確認した。各1206×2622px。集計4行、記録3行が初期画面に表示され、B/Cには標準の「編集」が表示される。対照のデフォルトSection headerは灰色、行の本文は黒く描画されている。

| 条件 | PNG | AXtree |
|---|---|---|
| A | [画像](001-reading-session-G3-native-controls-r2/evidence/screens/A.png) | [要素ツリー](001-reading-session-G3-native-controls-r2/evidence/trees/A.txt) |
| B | [画像](001-reading-session-G3-native-controls-r2/evidence/screens/B.png) | [要素ツリー](001-reading-session-G3-native-controls-r2/evidence/trees/B.txt) |
| C | [画像](001-reading-session-G3-native-controls-r2/evidence/screens/C.png) | [要素ツリー](001-reading-session-G3-native-controls-r2/evidence/trees/C.txt) |

AXtreeを読み、ポインタとpidを正規化して全構造を比較した（[差分](001-reading-session-G3-native-controls-r2/evidence/normalized-tree-diffs.txt)）。A→Bの差分はtoolbarの編集Button追加だけ、B→Cの可視tree差分はなかった。これは閉じた一覧のdebugDescriptionの比較であり、隠れたcontextual actionや操作の挙動が等しいと証明するものではない。

- 集計行のidentifier/label/valueが4組存在し、外側の各frameは370×52.3pt。
- 記録のcontain要素が3個存在。各frameは幅116.7–118.0pt、高さ40.3pt。各List Cellは370×70.3pt。
- type 4のComplete Issue Descriptionも確認したが、すべて「The size of this SwiftUI.AccessibilityNode is too small for user to interact.」という説明だけで、要素や座標を示していない。対象を特定する情報は増えなかった。

記録contain要素の40.3ptという高さと3個という数は候補を考える材料になる。しかし、element=nilを根拠にこの3個が指摘対象だと断定しない。共通に追加した集計4行と記録の構造を分離した試験ではないため、どちらが必要条件かも確定していない。

## 製品r2との差と解釈の限界

[製品S3の保存画像](../verification/001-reading-session/evidence/g3-20261023/screens/S3_normal_light.png)も実際に開いた。製品はinlineの書名、戻る操作、独立した書名の行、下部の読書開始Buttonを持つ。対照はlargeの「本の詳細」とSection headerで、日付・ページ文言、spacing、画面内の位置も完全一致ではない。製品モデル、日時format、画面遷移、製品のstyleは持ち込んでいない。

1. 第1フェーズの単純Text行List＋swipeActionsではtype 4が0件だったが、今回の共通構造ではA/B/Cすべて3件になった。標準SwiftUIの構成でも製品と同型のhitRegion/nil3を生じさせられる。
2. Bでも再現するので、この構成ではswipeActionsの存在は再現の必要条件ではない。Aでも再現するためonDelete/EditButtonの存在も必要条件ではない。両方の併用だけを原因とする説明は支持されない。
3. 共通するVStack/contain、集計行のignore＋label/value、他の共通の一覧構成のどれが原因かは、この1組から確定できない。標準だから誤検知だとも、製品だから不具合だとも断定しない。
4. 製品S3にはtype 65536が5件あったが、この対照では0件。追加type 1は各2件出た。指摘集合全体が一致する再現ではなく、hitRegion/nil3という部分的再現。
5. 第2フェーズはこのA/B/Cの1組で終了した。さらに条件を増やす再監査、AX5の再実行、製品変更は行っていない。製品の元のG3結果は失敗のまま保持し、全G2/G3 PASSは宣言しない。

## 実行・API・保存

```sh
xcodebuild build-for-testing -project S3ABCControl.xcodeproj -scheme S3ABCControl -destination 'platform=iOS Simulator,id=0DD0727D-F16F-4DD6-8759-549D6FAB596F' -derivedDataPath DerivedData -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
xcrun simctl ui 0DD0727D-F16F-4DD6-8759-549D6FAB596F content_size large
xcodebuild test-without-building -project S3ABCControl.xcodeproj -scheme S3ABCControl -destination 'platform=iOS Simulator,id=0DD0727D-F16F-4DD6-8759-549D6FAB596F' -derivedDataPath DerivedData -parallel-testing-enabled NO -resultBundlePath evidence/ABC.xcresult CODE_SIGNING_ALLOWED=NO
```

[ビルド](001-reading-session-G3-native-controls-r2/build.log)はexit 0。Swift compile warning 0件、AppIntents未使用のmetadata extraction warning 2件。新規依存なし。LabeledContent（iOS 16+）、onDelete（iOS 13+）、EditButtonの名前と宣言を使用前にSDK swiftinterfaceで確認した（[抜粋](001-reading-session-G3-native-controls-r2/evidence/api-sdk-confirmation.txt)）。audit APIの確認は第1フェーズと同じ。

[ソースSHA-256](001-reading-session-G3-native-controls-r2/evidence/source-sha256.txt)、画像、AXtree、全failureの詳細・画像attachment、xcresult、生成project、ビルド生成物をこの専用tmpに保持した。第1フェーズの証拠は維持。共有clone、製品、既存テストは変更していない。commit/pushなし。

最後にdiag appとUIテストrunnerを専用simからuninstallし、専用simだけshutdown。各exit 0（[cleanup.log](001-reading-session-G3-native-controls-r2/cleanup.log)）。

## 指揮役による保存

上の相対リンクの証拠を同名フォルダへ保存した。Swift/設定ソースは参考資料として `.txt` を付けた。xcresult、生成プロジェクト、ビルド出力の全量は原本tmpに残し、Gitには含めない。元の製品監査のFAILを保持する。
