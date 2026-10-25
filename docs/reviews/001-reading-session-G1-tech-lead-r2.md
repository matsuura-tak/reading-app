PASS

## 指摘
- 要修正 1：docs/reviews/001-reading-session-G1-ruling.md:8-15。裁定の1の一覧に、designer が r2 で足した次の3つが入っていません。どれも Mac がないため CI でしか確かめられない動きです。
  - (1) D-46（design/001-reading-session.md:218）：ツールバーの .borderedProminent に付けた .tint と .foregroundStyle を、iOS 26 のツールバーが実際に使うか。A89 の本文に「Some controls adapt to the tint color differently based on their style, the current platform, and the surrounding context.」とあります。
  - (2) D-48（:220）：List、Form、LabeledContent、ContentUnavailableView、ProgressView が既定で付ける secondaryLabel を、中の Text の色で替えられるか。
  - (3) D-53（:225）：ToolbarItemPlacement.keyboard（A69）が、.numberPad のキーボードとシートの中で出るか。
  委任指示書が designer の5点を「未確認（G2 の CI の出力で確かめる）」でよいとしたので、この判定ではこの3つを裁定の対象と同じに数え、PASS にしました。ただ、裁定の3の「これら」に名前がないと、ios-engineer の確かめと G3 の止め方から漏れます。直す方向：指揮役が裁定の1にこの3行と、証拠(3)の代わりの案を書き足す。
- 提案 1：design/tokens.md:27-30（実装での当て方）と D-48（design/001-reading-session.md:220）。color.text.primary は Color の値（`Color.primary` か Asset Catalog の色）で渡し、階層の形の `.primary`（HierarchicalShapeStyle）は使わない。根拠は A90 の本文「Hierarchical foreground styles like … don't impose a style of their own, but instead modify other styles. … SwiftUI looks for the innermost containing style」。部品が内側で secondary を付けている所では、階層の形では色が替わらないおそれがあります（推測）。手順7の設計メモの実装の決まりに書きます。tokens.md にも書くかは designer に任せます。
- 提案 2：design/tokens.md:43 と :103。用意された代わりの値は、コントラストを上げる設定のライトでシステムが黒いラベルを描いた場合の分だけです。ダークでシステムが白いラベルを描いた場合（#FFFFFF / #E3B994 = 1.81:1、:103）の値がありません。直す方向：その場合に替える Asset Catalog の値を、designer が1組足す（A93 のとおり、コントラストごとの値は Asset Catalog に置けるので、コードを変えない形を保てる）。作れるかどうかには関わらないので、判定は design-reviewer の範囲です。
- 提案 3：docs/prd/001-reading-session.md:162、AC-56〜AC-61（:501-535）。次の2つは手順7の設計メモと contracts/ で決めます（tech-lead の次の作業。ここでは書き残すだけ）。
  - 画面とメモリ上の進行中の読書の状態は、保存が通ってから変える。失敗した値は残さない。
  - T5 に操作 session_start、session_pause、session_resume を足す。

## 前回の指摘の追跡
| 前回の指摘 | 結果 | 証拠 |
|---|---|---|
| 重大（未検証の扱い） | (1) 基本の部品の対応 OS：直った。(2) Mac が要る動き：裁定で未検証 | (1) 一覧の18件（23ページ）はすべて取れ、404 は0件（証拠(1)の A66〜A88）。(2) docs/reviews/001-reading-session-G1-ruling.md:8-15。r2 で増えた同じ種類の3件は要修正1 |
| 要修正 1（題名の上限と変換中の文字） | 直った。どちらの形にするかは手順7の設計メモで決める。動きは裁定で未検証 | PRD:158 で形A と形B の両方を許した。design:163 の S2 の行に、形A を選んだときの本来の部品、理由、Dynamic Type、VoiceOver、見た目、焦点の対応がある。D-57（:229）、6 の (f)（:275）。形A の部品は存在と版を確かめた（A100 UIViewRepresentable iOS 13.0、A101 markedTextRange iOS 3.2）。A79 TextField のページには marked と composition の語が0件（selection を受ける init はある） |
| 要修正 2（読み始め、一時停止、再開の保存の失敗） | 直った | PRD：AC-56〜AC-61（:501-535）、10 の時刻の決まり（:162）、15 の Save Failed に3つの操作（:591）。design：1 の流れ（:41、:51、:58）、2 の表（:150-155）、5 の S1、S3、S4 に start、pause、resume の文言キー（:236-239）、D-51、D-52（:223-224）。AC は61件、2 の表も61行。T5 の3操作は手順7で contracts/ に足す（提案3） |
| 要修正 3（iOS 26 で「キャンセル」が出るか） | 直った。iOS 26 で実際に出るかは裁定で未検証 | D-16（:188）で S6 を alert に替えた（A83 alert iOS 16.0、A45 ButtonRole.cancel）。6 の (e)（:274）、S6 の行（:332）、AC-38 の行（:132）、PRD の AC-38 の When の注記（:394）。alert は外側をタップしても閉じないので、注記の「外側をタップ」は confirmationDialog に戻した場合だけの代わりとして扱う |
| 提案 1（AC-54 の計測） | 直った | PRD:592 に Load Failed、:597 に送る条件 |
| 提案 2（最低対応 OS、ADR、CLAUDE.md） | 手順7で扱う（この判定の対象外） | なし |

## 証拠
- 対象：HEAD 3b8e3cd。r1（02a6952）の後の変更は 77baf92（PRD）、fa6a553 と 3b8e3cd（design/）。観点は docs/org/gates.md:39-52 の G1 のうち、tech-lead の「今の構成でこのデザインを作れる」。

### (1) まとめて開いた部品の表
元の URL は https://developer.apple.com/tutorials/data/documentation/<パス>.json（2026-10-21）。版は metadata.platforms の iOS の introducedAt。

| A | 名前 | パス | iOS | 結果 |
|---|---|---|---|---|
| A66 | toolbar(content:) | swiftui/view/toolbar(content:) | 14.0 | 取れた |
| A67 | ToolbarItem | swiftui/toolbaritem | 14.0 | 取れた |
| A68 | ToolbarItemPlacement | swiftui/toolbaritemplacement | 14.0 | 取れた |
| A69 | ToolbarItemPlacement.keyboard | swiftui/toolbaritemplacement/keyboard | 15.0 | 取れた。本文「A placement for items in the keyboard section.」 |
| A70 | .cancellationAction | swiftui/toolbaritemplacement/cancellationaction | 14.0 | 取れた |
| A71 | .confirmationAction | swiftui/toolbaritemplacement/confirmationaction | 14.0 | 取れた |
| A72 | borderedProminent | swiftui/primitivebuttonstyle/borderedprominent | 15.0 | 取れた |
| A73 | controlSize(_:) | swiftui/view/controlsize(_:) | 15.0 | 取れた |
| A74 | redacted(reason:) | swiftui/view/redacted(reason:) | 14.0 | 取れた |
| A75 | ProgressView | swiftui/progressview | 14.0 | 取れた |
| A76 | sheet(isPresented:onDismiss:content:) | swiftui/view/sheet(ispresented:ondismiss:content:) | 13.0 | 取れた |
| A77 | sheet(item:onDismiss:content:) | swiftui/view/sheet(item:ondismiss:content:) | 13.0 | 取れた |
| A78 | Form | swiftui/form | 13.0 | 取れた |
| A79 | TextField | swiftui/textfield | 13.0 | 取れた |
| A80 | keyboardType(_:) | swiftui/view/keyboardtype(_:) | 13.0 | 取れた |
| A81 | EditButton | swiftui/editbutton | 13.0 | 取れた |
| A82 | onDelete(perform:) | swiftui/dynamicviewcontent/ondelete(perform:) | 13.0 | 取れた |
| A83 | alert(_:isPresented:actions:message:) | swiftui/view/alert(_:ispresented:actions:message:) | 16.0 | 取れた |
| A84 | accessibilityAddTraits(_:) | swiftui/view/accessibilityaddtraits(_:) | 14.0 | 取れた |
| A85 | navigationBarTitleDisplayMode(_:) | swiftui/view/navigationbartitledisplaymode(_:) | 14.0 | 取れた |
| A86 | Text.monospacedDigit() | swiftui/text/monospaceddigit() | 15.0 | 取れた |
| A87 | ScrollView | swiftui/scrollview | 13.0 | 取れた |
| A88 | NavigationPath | swiftui/navigationpath | 16.0 | 取れた |

404 は0件。いちばん新しいのは A83 と A88 の iOS 16.0 で、SwiftData（A2）と Announcement（A62）の iOS 17 より低い。最低の OS は iOS 17 以上の見込みで、手順7の ADR で決める。

一覧の外で開いたページ（Bash 4回、15ページ）：
- A89 tint(_:)：iOS 15.0。本文「Use this method to override the default accent color for this view.」
- A90 foregroundStyle(_:)：iOS 15.0。
- A91 Xcode「Specifying your app's color scheme」。本文「You can set an accent for your app by specifying an accent color in your asset catalog.」「Global Accent Color Name」。
- A92 ColorSchemeContrast：iOS 13.0。A93 EnvironmentValues.colorSchemeContrast：iOS 13.0。本文「If you only need to provide different colors or images for different color scheme and contrast settings, do that in your app's Asset Catalog.」
- A94 UIKit「Supporting Dark Mode in your interface」。
- A95 String.count、A96 Character（拡張書記素クラスタ）、A97 prefix(_:)。
- A98 PrimitiveButtonStyle.bordered：iOS 15.0。A99 accessibilityAction(named:_:)：iOS 16.0。
- A100 UIViewRepresentable：iOS 13.0。A101 UITextInput.markedTextRange：iOS 3.2。
- A102 ModelContainer.init(for:migrationPlan:configurations:)：iOS 17.0。宣言に throws がある。

### (2) 新しいトークンの作りが SwiftUI で作れるか
- 目立つボタンに .borderedProminent（A72）、.tint(color.accent.fill)（A89）、ラベルに .foregroundStyle(color.text.onAccent)（A90）：どれも iOS 15.0 からあり、作れる。ツールバーの中でシステムがこの色を実際に使うかは未確認で、G2 の CI のスクリーンショットで確かめる（要修正1）。
- .bordered（A98）に .tint(color.text.primary)（A89）：作れる。
- Asset Catalog の AccentColor に文字用の値：作れる（A91）。コントラストを上げる設定の値も Asset Catalog に置ける（A93）。欄が使えなければ colorSchemeContrast（A92、A93）でコードから選ぶ。

### (3) designer が tech-lead に確かめてほしいとした5点への答え
1. ツールバーの .borderedProminent の tint と foregroundStyle：API はある（A72、A89、A90、A71）。iOS 26 のツールバーが使うかは未確認で、G2 の CI のスクリーンショットで確かめる。代わりの案は2段。ラベルの色だけが無視された場合：tokens.md:43 の代わりの値（Asset Catalog だけで替える。ダークで白が描かれた場合の値は提案2）。塗りも無視された場合：確定のボタンから .borderedProminent を外し、.confirmationAction の文字のボタンに戻す（AccentColor = color.accent.text。tokens 5 の A3 が 4.5:1 を満たす）。
2. List などの secondaryLabel の置き換え（D-48）：中の Text に .foregroundStyle（A90）を付け、色は Color の値で渡す（提案1）。部品が上書きするかは未確認で、G2 の CI で確かめ、G3 で design-reviewer が測る。代わりはその所だけ標準の Text の並びにする（LabeledContent をやめ、Text を横に並べ .accessibilityElement(children: .combine)。A61）。
3. ToolbarItemPlacement.keyboard が .numberPad で出るか（D-53）：API はある（A69、A80）。シートの中の Form と数字のキーボードで出るかは未確認で、G2 の CI で確かめる。代わりは (a) safeAreaInset(edge: .bottom)（A65）に .bordered の「保存」、(b) D-53 をやめる（結び付いた AC はなく、右上の session.finish.save は残る）。
4. 題名の上限は形A か形B か：手順7の設計メモで決める。形A は UIViewRepresentable（A100）と markedTextRange（A101）。形B は標準の TextField。どちらも String.count（A95、A96）と prefix(100)（A97）。形A の入力中の動きは裁定で未検証。だめなら形B。
5. 6章の (a)〜(g)：(a) 未確認（CI）。.contain（A61）→ .accessibilityIdentifier（A64）。代わりは 1pt の要素。(b) 未確認（CI）。代わりは 7 の文字で探す。(c) 未確認（CI。読めなければ G4 で人）。accessibilityAction(named:_:) は iOS 16.0（A99）。(d) 未確認（CI）。swipeDown()（A63）、S5 に A60 を付けない。(e) alert（A83）と ButtonRole.cancel（A45）で作れる。iOS 26 で出るかは CI。(f) 上の4。(g) AC-49 は sheet(item:onDismiss:)（A77）の onDismiss で NavigationPath（A88）に積む。AC-54 の ModelContainer の作成が throws は閉じた（A102）。@Query の失敗の扱いは未確認（裁定の対象）。

### (4) 未検証の一覧
- 裁定の対象（G2 の CI の出力で確かめる）：6章の (a)〜(d)、形A の入力中の動き、AC-49 の push、AC-54 の @Query と fetch、iOS 26 の alert と confirmationDialog の「キャンセル」。
- 同じ種類で、裁定の一覧に名前がないもの（要修正1）：D-46 のツールバーでの色、D-48 の secondaryLabel の置き換え、D-53 の数字のキーボードの上のツールバー。
- 範囲の外で手順7と G2 で扱うもの：契約の案の未確認（環境変数の長さ、XCUIApplication.open の確認のダイアログ、-AppleLocale、名前 Clock の衝突）。G0 r2 の 7(b) の残り（TelemetryDeck、AC-18 の CI、AC-21 の SpringBoard）。
- 裁定の対象の外で残っている未検証：なし。

### 読んだファイル、実行したコマンド
- 読んだファイル：docs/reviews/001-reading-session-G1-tech-lead-r1.md、-ruling.md、docs/templates/review-report.md、docs/org/gates.md:1-15,39-55、docs/prd/001-reading-session.md:155-162,392-400,499-536、design/001-reading-session.md:157-169,218-229,236-241,269-276,595-613、design/tokens.md:1-50,79-131、G0 の tech-lead r1・r2 の A-n の行。
- 実行したコマンド：for ループで23ページの JSON を取得し jq で版を読んだ（1回目はガードに止められ、2回目は jq の誤り、3回目で取れた）。一覧の外の15ページを Bash 4回。`git log --oneline -8` → HEAD 3b8e3cd。`command -v swift` → なし。
- 書いたファイル：なし。

## 記録（指揮役）
- 関門：G1（手順6、構成の判定）
- 判定した役：tech-lead
- 回：r2
- 対象：design/001-reading-session.md、design/tokens.md、design/001-reading-session/screens.md（コミット 3b8e3cd）、docs/prd/001-reading-session.md（77baf92）
- 日付：2026-10-21
- 指揮役の扱い：要修正1は裁定ファイルに追記して閉じる。提案1、3は手順7の tech-lead の設計メモへ。提案2は designer に次の直しで足させる（design-reviewer r2 の結果と一緒に）。
