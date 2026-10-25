# G3標準SwiftUI部品の対照実験（2026-10-23）

標準部品だけの独立アプリでも、Form見出しのcontrast（type 1）、標準toolbarのdynamicType（type 65536）、標準alertのdynamicType（type 65536）が再現した。通常とAX5の両方で各10件のfindingがあり、UIテストはそれぞれ失敗（exit 65）。これは製品G3の合格判定、監査findingの抑制、または全件を誤検知と認定する資料ではない。

標準List 3行＋swipeActionsだけでは、製品S3のhitRegion（type 4）3件は再現しなかった。製品側には行のVStack、accessibilityElement(children: .contain)、ForEach.onDeleteとEditButtonの併用という追加条件があるため、製品S3の問題は未解決のまま。

## 範囲と環境

- 作業先は `/private/tmp/reading-app-native-audit-control-20261023/` のみ。製品・既存テスト・共有clone内のファイルは変更していない。commit、push、PR作成なし。
- Xcode 27.1（27A9275）、Swift 6、iOS 26.0（23A343）、新規専用iPhone 17。UDID `0DD0727D-F16F-4DD6-8759-549D6FAB596F`。他のsimulatorは操作していない。
- XcodeGen 2.46.0は既存バイナリを外から参照。SHA-256 `8774da746668bc18fe74e54cbaf10f2631a1fb05947cd374179aa912f14f99db`。新規依存なし。
- 日本語・ライトモード。通常はシステムの `large`、AX5は `accessibility-extra-extra-extra-large`。アプリ側にdynamicTypeSizeや固定サイズfontの上書きなし。
- 親から指定された製品基準は `6442fe2`。比較資料は `/private/tmp/reading-app-g3-visual-r2-20261023.log` と共有cloneのS5画像。製品のソース参照はFinishSessionViewの必要範囲に限定した。

## 対照の構成

[対照アプリ](001-reading-session-G3-native-controls-r1/sources/NativeAuditControlApp.swift.txt)は、次の4状態だけを持つ。製品のモデル、トークン、ロジックは取り込んでいない。比較に必要な日本語文言は揃えている。

| 状態 | 標準部品 | 実装行 |
|---|---|---:|
| form | NavigationStack、Form、Section、footnote/primary/textCase(nil)の見出し、標準TextField 2個、confirmation/cancellation toolbar Button | 30–54 |
| deleteAlert | 標準alert、題名・本文、cancel/destructive Button | 55–64 |
| errorAlert | 標準alert、題名・本文、cancel Button | 65–73 |
| list | List 3行、Text、swipeActions内destructive Button | 74–81 |

4状態のPreviewあり。固定フォントサイズ、固定の文字領域高さ、RGB直書き、自作ジェスチャー、製品モデル・トークンは0件。この日本語の一時対照では翻訳、製品の状態遷移、永続化、性能、受け入れテストは対象外。

[UIテスト](001-reading-session-G3-native-controls-r1/sources/NativeAuditControlUITests.swift.txt:5)はcontinueAfterFailure=trueで4状態を順に観測。各状態で監査前のPNG、AXtree、要素座標を保存し、`performAccessibilityAudit(for: .all)`を実行する。issueHandlerは全件falseを返し、findingを一切抑制していない（38–40行）。ソースは最初の実監査の後には変更していない。

## 監査の観測結果

| 部品・製品との対応 | 種別 | 通常 | AX5 | 解釈の範囲 |
|---|---:|---:|---:|---|
| Form「坊っちゃん」見出し：製品S5と同じstyle指定、S2も同じ部品種 | 1 contrast | 1 | 1 | 標準でも再現。S5は後述の画素比較もほぼ同一 |
| toolbar保存・キャンセル：製品S2/S5 | 65536 dynamicType | 2 | 2 | 標準配置・標準Button/Textだけでも再現 |
| 標準削除alert：製品S6 | 65536 dynamicType | 4 | 4 | 題名・本文・element=nilのfindingを含め再現 |
| 標準エラーalert：製品S7 | 65536 dynamicType | 3 | 3 | 題名・本文・element=nilのfindingを含め再現 |
| 標準List 3行＋swipeActions：製品S3の最小対照 | 4 hitRegion | 0 | 0 | 今回の条件では再現せず。製品との差があり、S3を除外できない |
| 合計 | 全種別 | 10 | 10 | いずれも監査は失敗として残した |

各サイズともテストケース開始1回、audit開始4回・終了4回。通常51.837秒、AX5 54.805秒、各1テスト失敗・10 failures・0 unexpected・0 skipped。監査後に期待する結果へ合わせるコード変更・再試行はしていない。

証拠： [通常raw log](001-reading-session-G3-native-controls-r1/logs/normal.log)、[AX5 raw log](001-reading-session-G3-native-controls-r1/logs/AX5.log)、[機械集計](001-reading-session-G3-native-controls-r1/audit-summary.json)、[製品raw指摘の行番号付き抜粋](001-reading-session-G3-native-controls-r1/product-reference-issues.txt)。結果bundleは `evidence/normal-final.xcresult` と `evidence/AX5-final.xcresult`。

## 実画像と寸法

8画像すべてを実際に開いて確認した。画像はすべて1206×2622px（3px/pt）。Formの見出しは両サイズとも黒く、全文が見える。Listの3行も両サイズで表示される。通常alertは題名・本文・操作を表示する。AX5の削除alertでは本文がスクロール領域に入り、初期画像には全文が収まらない。スクロール操作後の全文確認までは行っていない。AX5 alertも「全状態で切れなし・問題なし」とは判定しない。

| 観測対象 | 通常 | AX5 |
|---|---|---|
| Form見出しAX frame | 370×35.7pt | 370×72.7pt |
| Form見出しの暗いglyph画素外接矩形 | 176×32px | 600×111px |
| 保存Button AX frame | 48×36pt | 55.3×36pt |
| 保存の暗いglyph画素外接矩形 | 92×44px | 114×55px |
| 削除alert題名AX frame | 260×20.3pt | 306×125.3pt（折返しを含む） |
| 削除alert本文AX frame | 260×58pt | 306×406.7pt（折返しを含む） |
| エラーalert題名AX frame | 260×20.3pt | 306×187.3pt（折返しを含む） |
| エラーalert本文AX frame | 260×38pt | 306×232.7pt（折返しを含む） |
| List各行AX frame | 370×52.3pt | 370×93.3pt |

見出しのglyph高さは約3.47倍、保存文字のglyph高さは1.25倍になった。標準部品にも実際の拡大はあり、全く変化しないわけではない。一方でtoolbarはAX5でもButton高さ36ptのままなど、拡大に制約がある。これが仕様かOS・監査の不具合かまでは今回の観測から確定できない。

| 状態 | 通常PNG | AX5 PNG | AXtree |
|---|---|---|---|
| form | [通常](001-reading-session-G3-native-controls-r1/screens/form_normal.png) | [AX5](001-reading-session-G3-native-controls-r1/screens/form_AX5.png) | [通常](001-reading-session-G3-native-controls-r1/trees/form_normal.txt)、[AX5](001-reading-session-G3-native-controls-r1/trees/form_AX5.txt) |
| deleteAlert | [通常](001-reading-session-G3-native-controls-r1/screens/deleteAlert_normal.png) | [AX5](001-reading-session-G3-native-controls-r1/screens/deleteAlert_AX5.png) | [通常](001-reading-session-G3-native-controls-r1/trees/deleteAlert_normal.txt)、[AX5](001-reading-session-G3-native-controls-r1/trees/deleteAlert_AX5.txt) |
| errorAlert | [通常](001-reading-session-G3-native-controls-r1/screens/errorAlert_normal.png) | [AX5](001-reading-session-G3-native-controls-r1/screens/errorAlert_AX5.png) | [通常](001-reading-session-G3-native-controls-r1/trees/errorAlert_normal.txt)、[AX5](001-reading-session-G3-native-controls-r1/trees/errorAlert_AX5.txt) |
| list | [通常](001-reading-session-G3-native-controls-r1/screens/list_normal.png) | [AX5](001-reading-session-G3-native-controls-r1/screens/list_AX5.png) | [通常](001-reading-session-G3-native-controls-r1/trees/list_normal.txt)、[AX5](001-reading-session-G3-native-controls-r1/trees/list_AX5.txt) |

## S5の画素比較とcontrast

製品S5の見出しframeは `(16,132,370,35.7)pt`、標準対照は `(16,116,370,35.7)pt`。双方を3倍座標で、製品 `(48,396,1110,108)px`、対照 `(48,348,1110,108)px` として比較した。119,880画素中、異なる画素は2個だけで、最大RGB channel差は1/255。文字の暗い画素の外接矩形は双方176×32px。製品側は黒いglyph core RGB(0,0,0)が698画素、直近4点の背景はRGB(241–244,242–244,245–248)で、coreと各背景のsRGB相対輝度比は18.76–19.14:1。対照の同じ4相対座標でも同じ値だった。領域の最頻背景RGB(245,245,249)との比は19.31:1。

これは保存済み画像の限定した範囲での測定であり、AX audit内部がどのforeground/backgroundを選んだかを示すものではない。また全画面・全状態・全glyphのWCAG適合を認定するものでもない。しかし、このS5題名について製品固有の低contrast色を原因とみなし、type 1だけを根拠に色を変更することは、この観測からは支持できない。

測定ソース： [画素計測](001-reading-session-G3-native-controls-r1/sources/pixel_measure.swift.txt)、[範囲比較](001-reading-session-G3-native-controls-r1/sources/compare_header.swift.txt)。結果： [製品S5画素](001-reading-session-G3-native-controls-r1/product_S5_header_pixels.json)、[通常対照画素](001-reading-session-G3-native-controls-r1/control_form_normal_header_pixels.json)、[AX5対照画素](001-reading-session-G3-native-controls-r1/control_form_AX5_header_pixels.json)、[製品と対照の比較](001-reading-session-G3-native-controls-r1/product_control_header_comparison.json)。

## API確認

使用前にインストール済みApple SDKの宣言で確認した。確認した宣言の抜粋は [api-sdk-confirmation.txt](001-reading-session-G3-native-controls-r1/api-sdk-confirmation.txt)。対照のdeployment targetはiOS 26.0で、いずれも対象OS以下。

| API | SDKでの確認 | 対応OS |
|---|---|---|
| XCUIApplication.performAccessibilityAudit(for:_:) | XCUIApplication.h:149、XCUIAutomation.swiftinterface:14でSwift名・signatureを確認 | iOS 17.0+ |
| XCUIAccessibilityAuditIssueのauditType/element/compactDescription/detailedDescription、AuditType.all | XCUIAccessibilityAuditIssue.h、XCUIAccessibilityAuditTypes.h | iOS 17.0+ |
| XCUIDevice.appearance | XCUIDevice.h:124 | iOS 15.0+ |

SwiftUIのNavigationStack/Form/Section/TextField/ToolbarItem/alert/List/swipeActionsは標準frameworkのみを使用し、このdeployment targetのビルドを通した。監査ビットはSDKの宣言通り1=contrast、4=hitRegion、65536=dynamicType。

## ビルド・実行と準備上の失敗

[project.yml](001-reading-session-G3-native-controls-r1/sources/project.yml.txt)からXcodeGenで生成し、専用ディレクトリ内で次を実行した。

```sh
xcodebuild build-for-testing -project NativeAuditControl.xcodeproj -scheme NativeAuditControl -destination 'platform=iOS Simulator,id=0DD0727D-F16F-4DD6-8759-549D6FAB596F' -derivedDataPath DerivedData -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
xcrun simctl ui 0DD0727D-F16F-4DD6-8759-549D6FAB596F content_size large
xcodebuild test-without-building -project NativeAuditControl.xcodeproj -scheme NativeAuditControl -destination 'platform=iOS Simulator,id=0DD0727D-F16F-4DD6-8759-549D6FAB596F' -derivedDataPath DerivedData -parallel-testing-enabled NO -resultBundlePath evidence/normal-final.xcresult CODE_SIGNING_ALLOWED=NO
xcrun simctl ui 0DD0727D-F16F-4DD6-8759-549D6FAB596F content_size accessibility-extra-extra-extra-large
xcodebuild test-without-building -project NativeAuditControl.xcodeproj -scheme NativeAuditControl -destination 'platform=iOS Simulator,id=0DD0727D-F16F-4DD6-8759-549D6FAB596F' -derivedDataPath DerivedData -parallel-testing-enabled NO -resultBundlePath evidence/AX5-final.xcresult CODE_SIGNING_ALLOWED=NO
```

- 最初のビルドはUIテストclass全体のMainActor指定とXCTestのnonisolated override/initializerが衝突して失敗。1回だけ準備を修正し、UIテストtargetのdefault isolationをnonisolated、実行methodをMainActorにした。対照UI自体は修正していない。`build-preparation1.log`（exit 65）に保持。
- 次のビルド成功（exit 0）： [build.log](001-reading-session-G3-native-controls-r1/logs/build.log)。Swiftコンパイルwarningは0件。AppIntents未使用に伴うmetadata extraction warningが2件ある。
- 実監査前に、retryオプションへの不正なNO引数、既存resultパス、test-iterations=1の不正指定による実行準備エラーがあった。各準備ログとexitファイルを`normal-*-preparation.*`として保持した。いずれもテスト開始前であり、監査結果による再試行ではない。
- 実際の通常/AX5監査はそれぞれ1回だけ。retryフラグとiterationフラグは使用していない。各4状態を最後まで監査した。test結果にhost OS build表記の診断も残るが、auditの10 failuresと分けて扱った。
- 再現ソースのSHA-256は [source-sha256.txt](001-reading-session-G3-native-controls-r1/source-sha256.txt)。PNG/AXtreeの元attachment、監査が自動生成したfailure画像・説明も各attachmentsフォルダとxcresultに保持。

## 一般化の限界と未解決

1. このOS/runtime/端末/文字サイズで標準部品が同種findingを出すことまで確認した。Apple側の不具合、監査側の誤検知、標準部品の仕様のどれかを確定していない。標準部品だから製品で許容されるとも判定していない。
2. 製品S1の集計表示、S3の進み具合・総ページ数・記録見出しなどのdynamicTypeはこの最小対照にない。それらの問題は除外できない。
3. S3のhitRegion 3件はelement=nilで、今回の簡単なText行のListでは再現しなかった。製品のVStack(date subheadline＋HStack(minutes body,pages body))、children:.contain、ForEach.onDelete/EditButtonとswipeActionsの併用条件は未検証。加えて、製品にあるLabeledContentをchildren:.ignoreでまとめてaccessibilityLabel/accessibilityValueを与える4つのStatRowも未検証。element=nilの3件をsession行3件に対応付ける根拠はなく、StatRow由来かどうかも未確定。閉じたswipeActionsを監査しており、展開後の操作テストも対象外。
4. S2見出しの日本語glyph/状態の画素比較はしていない。S5と同じ部品種でtype 1が再現したことのみ。S5の強い画素一致を全画面へ広げない。
5. 製品S5はsheet、対照Formは独立NavigationStackのためy座標が16pt違う。製品の保存Buttonには製品styleがあるが、対照は標準Button。今回の証拠は製品のstyle全体の適合確認ではない。
6. 製品の元のG3監査は失敗のまま保持する。全G2/G3 PASS、修正完了、アクセシビリティ適合完了は宣言しない。

## 後片付け

専用simから対照appとUIテストrunnerをuninstallし、専用simをshutdownした。3操作ともexit 0（[cleanup.log](001-reading-session-G3-native-controls-r1/logs/cleanup.log)）。専用simは停止状態で残し、再現source・生成project・build生成物・raw log・PNG・AXtree・xcresultをこの専用tmpに保持している。

## 指揮役による証拠の保存

再現ソース（.swift/.ymlは.txt付き）、8枚のPNGと8件のAXtree、機械集計・画素/領域比較・API宣言・rawログを同名フォルダへコピーした。元レポート内の保存済みファイルのリンクを相対パスへ更新した。xcresult/生成project/build生成物/全自動添付はtmpに保持し、リポジトリへは入れない。再現するときはsourcesの.txtを外し元のApp/UITests構成に置き、project.ymlで生成する。画像加工や監査除外は行っていない。この対照でG3全体のFAILをPASSへ変更していない。
