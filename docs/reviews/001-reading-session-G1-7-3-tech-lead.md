（指揮役の注）G1 の 7-3（縦書きの spike、ADR 0003、ウィジェットの写しと入口の URL の契約）の、tech-lead の報告。designer、verifier、7-4 への申し送りを残すため保存した。判定ではない。報告の文はそのまま保存した。

## 変更したファイル
3ファイルとも新しく作りました。コミットはしていません。`git status --short` で増えたのは、この3つだけです。
- /Users/takumamatsuura/reading-app/docs/adr/0003-vertical-composition.md
  - ADR 0003（縦書きの組み）。型 B のすべての節があり、確かめ（B）の3つに印を付けました。
  - 中身：組みの手順、入るかの式、記号の値の表、25字のときの結果、置き換えの表（写しと、足した字）、小さい仮名と回す字のずらし、読み上げ、H22 の口と H22 が返す組みの結果の案、拡張の分離、5案の比較、いちばん強い反論、見直す条件、確かめたことと未確認。
- /Users/takumamatsuura/reading-app/contracts/widget-snapshot.schema.json
  - 写しの形（JSON Schema 2020-12、大きな版 1）。
  - 書く側と読む側の決まり、読めないときと知らない版のときの扱い（widget.unavailable）、状態ごとの出し方を description に書きました。
- /Users/takumamatsuura/reading-app/contracts/entry-urls.md
  - 入口の URL は `yomuma://open?entry=lock_widget|small_widget|live_activity` です。
  - 受ける側の読み方、URL では保存を変えないこと、AC-40 の印の決まり（300秒は両端を含む）、境界と脅威、spike の結果を書きました。

## 決めたこと
- **描き方**
  - 1字ずつ 1em の升目を ReadingCore の純粋な関数で計算し、SwiftUI の Text を ZStack に置きます。位置は frame、offset、rotationEffect だけで決めます。
  - W-1、W-2、S-1、S-5、H22 は、同じ関数と同じ View を使います。
- **入るかの式**
  - L＝⌊A_h÷s⌋ で、C×s＋(C−1)×0.25s ≤ A_w なら入ります。
  - A_w は W−2i−B−g、A_h は H−2i−R です。
  - s を開始の値（W-1 は 17、W-2 は 20）から 13pt まで1pt ずつ下げます。13pt でも入らなければ、追い出しをせずに 13pt で組みます。
- **帯の幅**：実測の 43pt にしました（推測は 38〜40pt でした）。
- **25字のときの字の大きさ**
  - W-1 は仕様と同じで、172×76 が 15pt（余り 35.0。列が1つ増えると 16.25）、153×68 が 13pt（余り 28.0。列が1つ増えると 11.75）です。
  - W-2 は、170 が 20pt、148 が 19pt です。追い出しで列が増えると、19pt と 16pt に下がります。
- **置き換えの表**
  - 足した字：〈〉《》【】［］〔〕と「‥」。どれも W3 と W6 に字形があります。
  - 「：」は足しませんでした。U+FE13 の字形が W3 にも W6 にもありません。
  - 半角の印字できる字は、全部を全角に直してから表を当てます。半角の括弧もこれで扱います。
  - 行頭の禁則に、足した閉じ括弧を加えました。
- **小さい仮名と「ー」**
  - 手でずらします。ずらす量は字ごとに、Core Text（kCTVerticalFormsAttributeName）で引いたフォントの縦書き用の字形の位置から、組むときに出します。
  - Text にフォントの縦書きの置き換えを任せる道（AAT type 4、OpenType vert）は、22字のうち0字しか置き換わりませんでした。
- **読み上げ**：.accessibilityElement(children: .ignore) と、PRD の形のラベルを付けます。
- **拡張の既定の分離**：nonisolated にします。
- **写し**
  - ISBN は入れません。理由は、指示書は ISBN を挙げていますが、PRD 12 が App Group に置くものを「書名、一行、ページ、出さない設定だけ」と決めているためです。
  - 隠す設定のときは、書名と一行を書きません（ページだけ）。
  - 今の本がないときは、currentBook のキーを書きません。
- **URL スキーム yomuma は登録します。**
  - 理由1：widgetURL に登録が要るかを Apple の文書が書いていないので、G4-18 で開かない恐れを避けます。
  - 理由2：H28 が OS の URL の道を通れます。
- **いちばん強い反論**：自前の組みは OS の文字組みを捨てるので、表にない字（「：」、絵文字、結合文字）は正しい縦書きの形にならず、組みと表を持ち続けることになります。
  - それでも選んだ理由：AC-28 と H22 は、字ごとの結果と L を、描いたものと同じ組みから読むことを求めます。Core Text に組ませると、その改行と禁則を AC-28 の決まりに合わせられません。
  - 崩れても欠けることはありません（升目は書記素で切ります）。
- **お願い**：ADR も契約も、私が書いて私が印を付けました。合格にはしていないので、reviewer に反論を出してもらってください。特に見てほしいのは次の3つです。
  - 写しから ISBN を外したことと、隠す設定のときに書名を書かないこと
  - URL スキームを App Store の版にも登録すること
  - 小さい仮名のずらしを組むときに Core Text で引くこと

## 実行したコマンドと結果
spike のフォルダは /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-7-3/ です。

- **環境**：Xcode 27.1（27A9275）、iPhoneSimulator27.1.sdk、runtime は iOS 27.0、端末は iPhone 17 Pro（g1-7-3-spike）。
- **作り**：アプリ（MainActor）、ウィジェットの拡張（nonisolated）、ローカルのパッケージ SpikeCore。プロジェクトは gen_pbxproj.py で作りました。

### ビルド
- `xcodebuild -project Spike.xcodeproj -scheme SpikeApp -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath ../dd ARCHS=arm64 SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build`
  - 結果：exit 0、`** BUILD SUCCEEDED **`
  - コンパイラーの警告は0件です。warning の行は1つだけで、`appintentsmetadataprocessor … warning: Metadata extraction skipped`（道具の知らせ）でした。
- 拡張を MainActor にした変種も exit 0 でした。
  - ただし、その設定が拡張のコンパイルに渡ったかを、ログから特定できませんでした（未確認）。
- SDK の宣言：TimelineProvider の `getSnapshot` と `getTimeline` の completion は `@escaping @Sendable` で、`@preconcurrency` が付いています。どの actor にも属しません。

### 拡張の登録と実行
- `xcrun simctl spawn <端末> pluginkit -mAvvv -p com.apple.widgetkit-extension` の出力は、`dev.spike.g173.app.widget(1.0)`、`SDK = com.apple.widgetkit-extension` でした。
- `xcrun simctl launch --console-pty … --spike` の出力は `SPIKE_DONE …/Documents/out` でした。結果は out2/results.json と out2/sheet.png にあります。

### 測った値
- **Text の箱**：ヒラギノの Text の箱は s×s でした（13〜28pt。leading は入りません）。上下の補正は要りません（差は 0.011em 以下）。
- **升目の中の置き場所**：国、︑、﹁、回した ー と 〜 は、計算した位置から 0.08pt 以内でした。すべて升目の中に入りました。
- **帯の幅**：「p.9999」を 12pt Semibold、monospacedDigit で描くと、43.0×14.33pt でした（UIKit では 42.89pt）。
- **組みの結果**
  - 4つの枠で15通りの一行を組みました。どの列の先頭にも禁則の字がなく、出した字を並べると元の一行と同じでした。
  - AC-28 の (4)〜(6)：L＝5、送り1回、6列で、字の大きさは変わりませんでした。
- **小さい仮名**
  - kCTVerticalFormsAttributeName では、22字とも置き換わりました。形は同じで、位置だけが違います。
  - W6 の差は、右へ 0.089〜0.164em、上へ 0.083〜0.143em でした。
  - 平均の1つの値でずらすと、17pt で最大 0.44pt ずれました。だから字ごとの値にします。
- **ー**：ただ回すと、フォントの縦書き用の字形より 0.05em 右に出ます。
- **時間**：組み1回は 0.045ms でした（Debug）。

### 読み上げ
- VoiceOver と同じたどり方では、要素は1つで、ラベルは「羅生門、61ページ。下人は、雨やみを待っていた。」でした。
- XCUITest の結果は `AX_MATCHES=1`、ラベルは同じで、テストは passed でした。
- ただし、XCUITest が見る自動化の木には、子が15個（`AX_DESCENDANTS_OF_WIDGET=15`）残っていました。

### 写しの読み方（spike の関数）
| 写し | 結果 |
|---|---|
| ファイルがない | missing |
| JSON でない | unreadable |
| 版が 2 | unknownVersion(2) |
| 隠すのに書名がある | invalid |
| ページが 0 | invalid |
| 知らない項目がある | ok（無視して読む） |
| line が null | ok（ないものとして読む） |

### URL の届き方
- `simctl openurl` を送ると、「“SpikeApp” で開きますか?」の確認が出て、アプリに届かないまま止まりました。
- springboard の「開く」を押すと、onOpenURL に `yomuma://open?entry=unknown` が届き、「なし（app）」と読みました。

### JSON Schema の確かめ（jsonschema 4.25.1）
- `check_schema` は OK でした。
- examples の5件と、Swift が書いた写しの5件は valid でした。
- 正しくない10件は、どれも INVALID でした：隠すのに書名がある、書名がない、ページ 0、ページ 10000、空の一行、null の一行、版が 2、知らない項目、隠す設定の項目がない、見た目の id の誤り。

### Apple の文書
- widgetkit/swiftui-views、linking-to-specific-app-scenes…、swiftui/view/widgeturl(_:) の3つを JSON で取得し、引用は ADR と entry-urls.md に書きました。

### 後片付け
- `xcrun simctl delete` は exit 0 でした。`xcrun simctl list devices` で g1-7-3 の行と UDID の行は、どちらも0行です。

### 手数
- 41回で終えました（この報告を含みます）。未着手の項目はありません。

## 申し送り
### designer
- tokens.md の帯の幅を「約38〜40pt［推測］」から 43pt（実測）に直してください。仕様 9 の余りの値も変わります（字の大きさは変わりません）。
- 置き換えの表に次を写してください。
  - 足した字：〈〉《》【】［］〔〕と「‥」
  - 「：」は縦書き用の字形がないので、立てたままか 90度回すかを決めてください。
  - 半角の記号を全部全角に直すこと。全角に直した「－」「，」「．」「；」を回すかも決めてください。
- 行頭の禁則に、足した閉じ括弧を入れました。「！」「？」「・」「々」と小さい仮名を入れるか、決めてください。
- W-2 の列とページの間の値が tokens にありません。仮に space.4 にしています（ページの行と合わせて 20pt）。
- screens.md の W-2 の図は、最後の列が下にそろい、1列4字になっています。式どおりなら、上にそろい、170 は 20pt で1列5字です。
- S-1 の縦書きの場所の大きさ（A_w、A_h）を決めてください。
- アプリが動いていて、シートが開いているときに URL が来たときの画面の扱いを決めてください。
- 小さい仮名の位置は、フォントの縦書き用の字形と同じになります。「ー」は 0.05em 左に寄ります。

### verifier
- AC-28 の (4)〜(6) は25字の一行で作ってください。そうしないと字の大きさが変わり、L がずれます。
  - L は H22 の referenceL で読んでください。
  - W-2 では、送りで字の大きさが下がることがあります（148 では 19pt から 16pt）。
- AC-99 のまとまりの数は、XCUITest の子の数で数えないでください（自動化の木に子が15個残ります）。H22 が返す数で見てください。
- H28：`simctl openurl` と Safari の道では確認が出ます。springboard の「開く」を押せば届くことは、spike で確かめました。
- 写しのテストは、アプリが書いた JSON を contracts/widget-snapshot.schema.json で検査し、壊れた写しでは widget.unavailable が出ることを見てください。
- AC-40 の 300秒は、両端を含みます。

### 7-4
- 契約に書くもの
  - H22 の組みの結果の形（ADR 0003 の「H22 の口」の案）を contracts/ に書いてください。
  - H28 の形を (a)〜(c) から決めてください（entry-urls.md の 6）。
- 設計メモの直し
  - 5：写しの項目を contracts/widget-snapshot.schema.json を指す形にしてください。ISBN なし、隠すときは書名と一行なし、appearanceID は省けます。
  - 5：知らない値の扱いの［推測］が決まりました。入口の印は app、見た目は default です。
  - 7：T の行は entry-urls.md を指すようにしてください。D の行の［推測］（読めなければ unavailable で描く）は決まりました。
  - 10：未確認のうち、拡張の分離はビルドで確かめました。ロック中の読み込みと、システムが描いたときの見え方は G4 に残ります。
- ADR 0001 の拡張の行の［推測］：nonisolated のビルドが通ったので、［推測］を外してください。7-3 では 0001 を書けないので、7-4 でお願いします。
- dependencies.md：新しい依存はありません。Core Text は Apple のフレームワークです。
- G1-3：iOS 26.x の runtime は入っていません（`xcrun simctl list runtimes` は iOS 27.0 だけです）。

## 未解決
1. **写しの ISBN**：指示書の項目と、PRD 12 と設計メモ 5 が食い違っています。PRD に合わせて外しました。ISBN が要る理由があれば教えてください。足すのは同じ大きな版の中でできます。
2. **システムが描いたときの見え方は未確認です。** ロック画面、ホーム画面、StandBy での見え方と vibrant を、まだ見ていません。
   - UI テストでホーム画面にウィジェットを置く試みを2回しましたが、前の手順で残った URL の確認の窓に止められました。
   - 確かめたのは、拡張のビルド、システムへの登録、同じ View をアプリで描いたところまでです。
   - G4-1 と G4-3 の前に見るなら、ios-engineer が Xcode のウィジェットのプレビューで見る形があります。
3. **MainActor の変種**：その設定が拡張のコンパイルに渡ったかは未確認です。
4. **小さい仮名を字ごとの値でずらして描いたときのずれ**は、測っていません（平均の値では最大 0.44pt でした）。
5. **拡張のターゲットで Core Text を呼ぶビルド**はしていません［推測で使えるとしました］。
6. **widgetURL に URL スキームの登録が要るか**と、本物のウィジェットを押したときに確認が出ないことは、G4-18 で見ます。
7. **ロック中に写しを読めるか**は、G4-1 で見ます（シミュレーターでは保護の等級が効きません）。
8. **designer に決めてもらうこと**（申し送りに書いたもの）：
   - 「：」の扱い
   - 禁則の字を足すか
   - W-2 の列とページの間
   - S-1 の縦書きの場所の大きさ
   - アプリが動いているときに URL が来たときの画面

spike の生の出力は、次のファイルにあります。
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-7-3/out2/results.json
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-7-3/out2/sheet.png
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-7-3/out2/ax-tree.txt
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-7-3/out2/url-shot.png
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-7-3/build-ni.log
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-7-3/build-ma.log
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-7-3/uitest2.log

## 記録（指揮役が保存するときに書き足す）
- 種類：作り手（tech-lead）の報告（判定ではない）
- 書いた物：docs/adr/0003-vertical-composition.md、contracts/widget-snapshot.schema.json、contracts/entry-urls.md（コミット f4bb5e5）
- 日付：2026-10-20
- 指揮役が確かめたこと：spike の組みの絵（scratchpad の g1-7-3/out2/sheet.png）を見た。列は右から左、ページは左下の帯、句読点は升目の右上、小さい仮名はずらしてあり、「ー」と括弧は回り、半角の英字は全角で立っている
- 写しから ISBN を外したのは、PRD 12（App Group に置くものは書名、一行、ページ、出さない設定だけ）に合わせたもので、指揮役の指示書の項目のほうが PRD とずれていた。PRD のとおりでよい
