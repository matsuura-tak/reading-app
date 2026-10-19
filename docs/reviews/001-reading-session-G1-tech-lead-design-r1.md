（指揮役の注）G1 のデザインの判定（tech-lead、r1。今の構成で作れるか、契約に何が要るか）。対象は芯の画面の仕様（design/001-reading-session.md、tokens.md、screens.md。コミット 4b947e8）。範囲は芯（裁定 24）。報告の文はそのまま保存した。

PASS

## 指摘
重大0件、要修正3件、提案5件です。

- **要修正1**：W-1 のページの置き場所と、字の大きさを決める手順に要る値
  - 場所
    - /Users/takumamatsuura/reading-app/design/001-reading-session/screens.md:9-15
    - /Users/takumamatsuura/reading-app/design/001-reading-session/tokens.md:32、:45、:57
    - /Users/takumamatsuura/reading-app/design/001-reading-session.md:279（決定 8）
  - 何が問題か
    - W-1 の図は、「p.61」を4字の列の下の行に置いています。
    - 17pt で1列4字なら、列だけで高さ 68pt です。12pt の「p.61」の行（約14pt）を下に足すと約82pt になり、いちばん大きい枠の高さ 76pt にも入りません（いちばん小さい枠は 68pt）。
    - 列と列の間隔の値がトークンにありません。このままでは、「1pt ずつ下げる」手順で枠に入ったかを決められません。
    - ページが4桁（p.9999）のときに、列と重ならない決まりもありません。
  - 根拠：AC-27（14字すべて、欠けた字0）、AC-28（L を H22 で読む）、tokens.md:45（W-1 は1列4字）。
  - 直す方向
    - (a) W-1 のページは列の下に置かず、左端の帯の下に置くと、図と文に書く。帯の幅は「p.9999」が入る幅で固定し、列は帯の右から組む。
    - (b) 列の間隔を、字の大きさの割合で1つ決める（例 0.25em）。
    - (c) 下げる手順の式は、tech-lead が縦書きの ADR に書く。
      - L＝⌊内側の高さ÷字の大きさ⌋。
      - 追い出しのあとの列の数を C とし、C×字の大きさ＋(C−1)×間隔 ≤ 内側の幅−ページの帯、で入るかを見る。
      - 入らなければ 1pt 下げ、13pt まで下げる。
      - この式なら、25字は 172×76 で 15pt、153×68 で 13pt で入る計算です（「p.9999」の幅を約38pt と見積もった［推測］）。
    - W-2 は今の図のままでよい。列の下にページを置いても、内側 116pt 四方に 25字が 19pt で入る計算です。

- **要修正2**：縦書き用の字の置き換えが足りない
  - 場所
    - /Users/takumamatsuura/reading-app/design/001-reading-session/tokens.md:45
    - /Users/takumamatsuura/reading-app/design/001-reading-session.md:277（決定 6）
  - 何が問題か
    - 置き換えるのは「、」「。」「「」「」」と「ー」と小さい仮名だけです。
    - PRD の縮め方（/Users/takumamatsuura/reading-app/docs/prd/001-reading-session.md:276）は、合う「、」「。」がなければ「先頭24字と『…』」を出します。だから、26字以上の一行では列に「…」がよく入ります。横書きの「…」（U+2026）のままでは、縦の列に横向きの点が並びます。
    - 「『』」「（）」「―」「〜」と半角の英数字（例：iPhone、3章）の扱いもありません。
    - AC-28 は「組み方の結果の字を並べると、一行の字がすべてそろう」を見ます。だから、置き換えた字と元の字の対応の決まりも要ります。
  - 根拠：iOS 27.0 のシミュレーターで、ヒラギノ明朝 ProN の W3 と W6 に次の字形があると確かめた（証拠の G3）。U+FE19（︙）、U+FE35・U+FE36（︵︶）、U+FE43・U+FE44（﹃﹄）、U+FE31（︱）。
  - 直す方向
    - 表を次のように広げる。
      - 「…」は U+FE19。
      - 「（」「）」は U+FE35、U+FE36。
      - 「『」「』」は U+FE43、U+FE44。
      - 「―」は U+FE31。
      - 「〜」「～」は「ー」と同じく 90度回す。
      - 「！」「？」「・」はそのまま。
    - 半角の英数字は、全角に直して1字ずつ立てるか、横に寝かせるかを決める。推奨は全角に直して立てる形です。組みの結果に元の字と出す字の両方を持たせ、AC-28 は元の字で比べる。
    - 表の案は tech-lead が ADR に出し、見た目は designer が決める形でよい。

- **要修正3**：S-8a で、閉じる以外の道で読んだ本がどうなるかがない
  - 場所
    - /Users/takumamatsuura/reading-app/design/001-reading-session/screens.md:205
    - /Users/takumamatsuura/reading-app/design/001-reading-session.md:297（決定 26）、:349、:362
  - 何が問題か
    - S-8a には、戻る（<）と閉じる（xmark）の2つがあります。確認を出すのは、閉じるだけです。
    - 次の3つの操作で、読んだ本の一覧を捨てるのか残すのかが書かれていません。
      - 戻るボタン
      - 画面の端からのスワイプ
      - シートを下に払って閉じる操作
  - 直す方向
    - 読んだ本が1冊以上のときは、次のように書く。
      - 戻るボタンを隠す（navigationBarBackButtonHidden）。
      - シートを払って閉じる操作を止める（interactiveDismissDisabled。iOS 26.0 にあると typecheck で確かめた）。
      - 道は「閉じる → 確認」だけにする。
    - 0冊のときは今のままでよい。

- **提案1**：systemRed の値が古い
  - 場所
    - /Users/takumamatsuura/reading-app/design/001-reading-session/tokens.md:20
    - /Users/takumamatsuura/reading-app/design/001-reading-session.md:766
  - systemRed の値（#FF3B30、#FF453A、#D70015、#FF6961）は、iOS 26 より前の色です。
  - iOS 27.0 の実測は、ライト #FF383C、ダーク #FF4245、コントラストを上げる設定でライト #E9152D、ダーク #FF6165 です。
  - 記号に要る 3:1 は、どれも満たします（WCAG の式で手計算）。
    - #FF383C：白の上 3.57、#F2F2F7 の上 3.20
    - #E9152D：#EBEBF0 の上 3.83
    - #FF4245：#1C1C1E の上 約4.96
    - #FF6165：#242426 の上 約5.27
  - 値を直し、出典を「実測」にする。iOS 26 の値は G1-3 で測る。

- **提案2**：コントラストを上げる設定の背景の「想定」を実測に替える
  - 場所：/Users/takumamatsuura/reading-app/design/001-reading-session.md:760、:779
  - ライトの Form の地は #EBEBF0 でした（想定の #E5E5EA ではない）。#48484A の文字で 7.68:1 です（仕様は 7.27:1）。
  - ダークの行の地 #242426（9.20:1）と、シートの中の行の地 #363638（7.16:1）は、想定どおりでした。

- **提案3**：2つ目の文字の色を置かない地を書いておく
  - 場所：/Users/takumamatsuura/reading-app/design/001-reading-session/tokens.md:16
  - ダークのシートの中の3段目の地（tertiarySystemGroupedBackground、#3A3A3C）の上では、`color.text.secondary`（#98989F）が 3.96:1 で、4.5:1 に届きません。
  - 今の仕様にこの組はない見込みです。使う所の欄に「シートの中の入れ子の地には置かない」と書いておく。

- **提案4**：S-8a の閉じるの role
  - 場所：/Users/takumamatsuura/reading-app/design/001-reading-session.md:326（決定 55）、:610
  - Apple の説明では、.close は「a close operation doesn't lose progress」です。
  - S-8a の `scan.cancel` は読んだ本を捨てうるので、読んだ本が1冊以上のときは role を .cancel にする。確認はそのまま。

- **提案5**：W-2 の「内側 16pt」がどちらの余白かを書く
  - 場所
    - /Users/takumamatsuura/reading-app/design/001-reading-session/tokens.md:53
    - /Users/takumamatsuura/reading-app/design/001-reading-session.md:678
  - 「内側 16pt」が、システムの既定の余白のことか、自分で足す余白のことかが書かれていません。両方が効くと、余白が二重になります。
  - 推奨：W-1 と W-2 とも既定の余白を切る（contentMarginsDisabled）。そのうえで W-1 は 0、W-2 は 16pt を自分で付ける。こうすると、アプリの中の描画（H22、S-5）と本物のウィジェットで、組みの計算が同じになります。

## 証拠
実行したコマンドと結果の要点です（詳しくは下の G）。
- `git rev-parse HEAD` → c2689c5791fb783ae4c435ddb1bb4a486578cc68（BASE と同じ）。
- `xcodebuild -version` → Xcode 27.1（27A9275）。`xcrun simctl list runtimes` → iOS 27.0 だけ（iOS 26.x はない）。
- typecheck の結果
  - `xcrun --sdk iphonesimulator swiftc -typecheck -target arm64-apple-ios26.0-simulator typecheck.swift` → exit 0、出力0行。
  - 同じファイルを `-target arm64-apple-ios18.0-simulator` で動かす → exit 1。「'close' is only available in iOS 26.0 or newer」ほか。
- 色と書体の実測：iOS 27.0 のシミュレーターで、自分の名前の端末を作って動かし、あとで消した。
- 読み上げの形の spike：`xcodebuild test`（XCUITest）→ TEST SUCCEEDED。端末はあとで消した。
- 国立国会図書館サーチへの問い合わせ：`curl`（totalResults 264、50件、ISBN のある件21件）。
- PRD と仕様の照合：`python3 -I check_ids.py`（芯の AC 85、選択肢の AC 51）。
- 作った端末は2台（tl-g1-design-review-techlead、tl-g1-design-review-techlead-ax）で、2台とも消した。`xcrun simctl list devices | grep -c tl-g1-design-review-techlead` → 0。

**A. 対象と読んだもの**
- **対象**：BASE＝HEAD＝c2689c5791fb783ae4c435ddb1bb4a486578cc68。次の3つを全行読みました。
  - /Users/takumamatsuura/reading-app/design/001-reading-session.md（804行）
  - /Users/takumamatsuura/reading-app/design/001-reading-session/tokens.md（71行）
  - /Users/takumamatsuura/reading-app/design/001-reading-session/screens.md（281行）
- **読んだファイル**
  - PRD /Users/takumamatsuura/reading-app/docs/prd/001-reading-session.md：冒頭の進め方、6 の「書誌」の行、11 の冒頭と H1〜H32、12、付記の G1-1〜G1-20。AC は 3、4、9、11、13、22、27、28、35、44、51、78、79、82、93、99、102 を読みました。
  - /Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-G1-5b-designer.md
  - /Users/takumamatsuura/reading-app/docs/org/gates.md（G1）
  - /Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-G0-ruling.md（裁定 24、25）
  - /Users/takumamatsuura/reading-app/docs/approvals/001-reading-session-G1-decisions.md
  - /Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-G0-prd2-tech-lead-r2.md（見積もりの表）
  - /Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-G0-verifier-r1.md（H1〜H14）
  - /Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-G0-tech-lead-flip-research.md（H15〜H18）
  - /Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-integrate-tech-lead.md（spike A）
  - /Users/takumamatsuura/reading-app/docs/templates/adr.md、/Users/takumamatsuura/reading-app/docs/templates/review-report.md
  - /Users/takumamatsuura/reading-app/contracts/dependencies.md、/Users/takumamatsuura/reading-app/.claude/org/app.json（commands は空）
- 1つだけ開いていないもの：/Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-G0-intents-tech-lead-r2.md は、時間がなく開いていません。中身は芯の範囲の外（App Intents）で、PRD の付記 G1-16〜G1-20 に入っている所だけを使いました。

**B. 画面ごとの実現性の表**
前提は、最低 iOS 26、SwiftUI、WidgetKit、サーバーなしです。標準の API は、すべて iOS 26.0 を対象にした typecheck で通りました（G1）。

| 画面 | 判定 | 作り（標準の部品） | 条件、手間、確かめる段 | 根拠 |
|---|---|---|---|---|
| W-1 | 作れる（条件つき） | accessoryRectangular。縦書きは1字ずつの升目（1em 四方）で組む。位置は Swift の計算で出し、描くのは WidgetKit の一覧にある Text、HStack、VStack、ZStack と、frame、rotationEffect、offset だけにする。読み上げは children: .ignore と1つのラベル | 要修正1、2。升目のそろえ方と、拡張の中で描けるかは縦書きの ADR の spike（0.25日）で見る。vibrant の見え方は G4-1 | G3、H の widgetkit/swiftui-views、spike A |
| W-2 | 作れる（条件つき） | systemSmall、containerBackground、widgetURL。StandBy はシステムが大きく描き、暗い所では赤にする | 提案5。見え方は G4-3 | 同上 |
| S-1 | 作れる（条件つき） | NavigationStack、toolbar、ContentUnavailableView、ViewThatFits、redacted。一行は W-1 と同じ組みを Font.custom(_:size:relativeTo: .title) で大きくし、isAccessibilitySize のときは横書きの Text にする。伏せる道は UIDevice の faceDown | 縦の固定がオンでも向きが届くかは、Q-A（Takuma の実機）で決まる。届かなくても、案2の文で作れる。主操作は .borderedProminent に tint と foregroundStyle を必ず付ける（spike で、付けないとダークで文字が地と同じ白になり、暗い画素が 0.000 だった） | G1、G4 |
| S-2 | 作れる | fullScreenCover、Text、Button | なし | G1 |
| S-3 | 作れる | 全画面の中での入れ替えとシート、NavigationStack、Button(role: .close) | なし | G1、G2 |
| S-3a、S-3b | 作れる | Form、TextField(axis: .vertical)、numberPad、FocusState、Button(role: .confirm) | なし | G1、G2 |
| S-4 | 作れる | Text、Button | S-5 は、全画面を閉じ終えたとき（onDismiss）に出す | G1 |
| S-5 | 作れる（条件つき） | シート。見本は、W-1 と同じ描く部品をアプリの中で 172×76pt に描く | アプリの中では vibrant にならない。並びは同じで、色だけ違う。これは受け入れてよい | G1 |
| S-6 | 作れる | List(.insetGrouped)、NavigationLink、redacted | 読み終えた日時を持つ（問い4）。行の中の `book.pendingInfo` もテストから読める | G4（n.pending exists=true） |
| S-7 | 作れる | List、Grid、confirmationDialog、safeAreaInset。AX のサイズでは Grid をやめて VStack にする | なし | G1 |
| S-7a、S-7b | 作れる | シート、Form、role .cancel と .confirm | なし | G1、G2 |
| S-8 | 作れる | List、AVCaptureDevice の許可、openSettingsURLString、DataScannerViewController の isSupported と isAvailable | isSupported は A12 以降でだけ真。Mac で動くときなどのために `register.scanUnavailable` を残す仕様は正しい | G1、H |
| S-8a | 作れる（条件つき） | DataScannerViewController（.barcode(symbologies: [.ean13])、recognizesMultipleItems）を UIViewControllerRepresentable で包む。978 か 979 で始まり、チェックの数字が合うコードだけを本とする（AC-3 の 1920193006001 と 4901234567894 を捨てる）。sensoryFeedback(.success) | 要修正3。シミュレーターでは動かないので H21 で差し替える。本物の読み取りは G4-10 | G1、H |
| S-8b | 作れる | 仕様どおり TextField と .isSearchField の印。URLSession と XMLParser で国立国会図書館サーチに問い合わせる | .searchable の欄には識別子を付けられない（問い2） | G2、G4、G6 |
| S-8c | 作れる | Form、TextField | なし | G1 |
| S-9 | 作れる | シート、ScrollView、Grid、Button(.bordered) | 候補の行の中の `next.reason` と `next.choose` も、テストから読める | G4（c.reason exists=true、k.row の中の k.choose exists=true） |
| S-10 | 作れる | Form、Toggle、Link | Link で開いた URL を H31 で記録するため、テストの構成で openURL を差し替える | G1 |
| 部品 N | 作れる | GroupBox、Label、AccessibilityNotification.Announcement | なし | G1 |

- **AX5 での並び替え**：どれも標準で作れます（dynamicTypeSize.isAccessibilitySize、ViewThatFits。G1 で通った）。
- **読み上げを作り直す独自部品**：縦書きの一行（W-1、W-2、S-1、S-5）と奥付の Grid の2つだけです。どちらも、仕様に読み上げの形が書いてあります。

**C. designer の問い7つへの答え**
| # | 問い | 答え | 決める段 |
|---|---|---|---|
| 1 | `settings.dataSources` の文字列 | 案は下の注1 | G1 設計の書誌の ADR |
| 2 | `.searchable` に識別子を付けられるか | 付けられない。TextField のままにし、.searchable には戻さない。SDK の searchable の宣言44個に、識別子の引数はない。spike では、`.searchable` の直後に付けた `search.field` は一覧（collectionView）に付き、検索欄の識別子は空で、`searchFields["search.field"]` は見つからなかった | ここで決着 |
| 3 | 縦書きの作りと、W-1 の内側の余白 | 方針はここで答える（注3）。式と置き換えの表は ADR で決める。列の間隔の値は designer が決める | ここ（方針）、G1 設計の縦書きの ADR（式と表） |
| 4 | 「読み終えた」を並べる日時 | 持つ。置き場所を「読み終えた」にした日時を入れ、ほかへ移したら消す。PRD の H2 の一覧にないので、H2 で入れられ H13 で読める形を、つなぎ口の契約に足す。S-6 の並びは仕様のままでよい | ここ（答え）、設計メモの 5（型と名前） |
| 5 | コントラストを上げる設定の背景の実際の値 | iOS 27.0 の実測。ライトの Form の地 #EBEBF0（#48484A で 7.68:1）、ダークの行の地 #242426（9.20:1）、シートの中の行の地 #363638（7.16:1）。どれも 4.5:1 を超える | ここ。iOS 26 の値は G1-3 で、同じ測り方のプログラムで測る |
| 6 | 書名で探す1回の件数 | 推奨は cnt=50 を1回で、ページ送りはしない（注6） | 推奨はここ、決めるのは書誌の ADR |
| 7 | Button の role .close と .confirm | iOS 26.0 から使える。ラベルなしの init(role:action:) も iOS 26.0 から。最低 iOS 26 なので、そのまま使える。意味の注意は提案4 | ここで決着 |

- **注1（問い1の案）**
  - 日本語：「書誌は、国立国会図書館サーチ（NDLサーチ）の API を用いて取得しています。データ提供機関：国立国会図書館。使う書誌：国立国会図書館蔵書、新着書誌情報」
  - 英語：「Book details are retrieved using the NDL Search API. Data provider: National Diet Library, Japan.」に、書誌の英語の正式名を足す。
  - 英語の正式名と、英語の構成で日本語の名前も出すかは、データプロバイダの一覧（https://ndlsearch.ndl.go.jp/help/api/provider 。今回は開いていない）を読んで ADR で決める。
  - 守る条件は2つ。
    - API のヘルプの 17-4 (2)「本APIを利用するサイトやアプリケーションには、NDLサーチのAPIを用いていることを明記してください。」（G0 r2 で原文と照らした）
    - CC BY のクレジット
- **注3（問い3の方針）**
  - 組み方
    - 1字ずつ、1em 四方の升目に置き、列は右から左へ並べる。
    - 自作の Layout は、WidgetKit の使える部品の一覧で確かめていないので使わない。
  - 升目のそろえ方（実測）
    - ヒラギノ明朝 ProN（W3、W6）は、17pt で ascender 14.96、descender −2.04 で、合わせて 17.00（1em）。leading 8.50 は升目に入れない。
    - 縦書き用の字形は em の枠の中の決まった位置に描かれている（U+FE11 の黒い所は x12.2、y9.7 で、枠の右上）。だから、升目を em の枠に合わせれば正しい位置に出る。
  - 小さい仮名：手でずらすか、フォントの縦書きの置き換え（AAT の type 4。W3、W6 ともある）を使うかを、spike で比べる。
  - 余白：提案5のとおり、既定の余白を切って W-1 は 0、W-2 は 16pt にする。
- **注6（問い6の根拠）**
  - dpid を2つ入れ、書名「人間失格」、cnt=50 で問い合わせると、totalResults 264 のうち 50件が返り、ISBN のある件は21件（重なりなし）、応答は約160KB でした。
  - 仕様の「ISBN のない結果は出さない」の決まりでは、約20行になります。

**D. 仕様とつなぎ口の照合**
- **AC の数**：芯の AC 85件、選択肢の AC 51件。designer の数と同じです（G5）。
- **芯の AC が使うつなぎ口**
  - 次の23個：H1、H2、H4〜H10、H12〜H18、H20〜H22、H26、H28、H29、H31。
  - H23（3件）、H24（1件）、H25（8件）は、芯の AC の中の選択肢の部分（Live Activity、カード、受賞）だけで使います。だから、冒頭の (iii) で残すと決まったときだけ契約に入れます。
  - H19、H27、H30、H32 は選択肢だけで使います。
- **識別子**
  - 芯の AC に出る識別子は、すべて仕様の 6 にあります（`<名前>.<id>` の行の形を含む）。
  - 仕様にない名前は、つなぎ口の値だけでした。これらはつなぎ口の契約に書くので、designer の直しは要りません。
    - H7 の対象：book.add、book.update、book.status、record.update
    - H13 の置き場所：current、tsundoku、finished
    - H15 の向き：faceDown、portrait
    - H17 の入口の印と読み上げ：entry、app、lock_widget、small_widget、live_activity、announce
    - AC-62 の `error`
- **行の中の要素も読める**
  - spike で、次の要素が XCUITest で見つかりました。
    - .combine でまとめた行の中の子
    - NavigationLink の行の中の文
    - .contain の行の中のボタン
  - だから、`next.reason`、`next.choose`、行の中の `book.pendingInfo` は、今の仕様のまとめ方のままテストから読めます。
- **XCUITest の数と VoiceOver のまとまりの数は違う**
  - .combine の子も XCUITest には見えるので、要素の数は VoiceOver のまとまりの数と同じになりません。
  - AC-99 の「まとまりの数」は、XCUITest の要素を数えず、H22 がアプリの中で UIAccessibility の要素を数えて返す形にします。これを契約に書き、作りは設計の段の spike で確かめます。
- **仕様にないが要るもの（契約で決める）**
  - H9 と H17 の値を載せる、根の要素の識別子。
  - S-10 の保存の失敗（仕様の 5）を確かめるなら、H7 の対象に `settings.save` を足す。
  - 見た目の文字と読み上げが違う要素を、テストがどの属性で読むか：`bookmark.page`、`result.summary`、`book.record.row.<id>`、`colophon.*`。
  - H22 の出力の形：
    - 字ごとの元の字、出す字、回すか、列、行
    - 字の大きさ、L、ページの場所、余白
    - 読み上げのラベルとまとまりの数
    - URL、再読み込みの回数、かかった時間、見た目の id
- **H22 の作り**
  - H22 は、アプリの中でウィジェットと同じ部品を描く口にします。
  - widgetURL はアプリの中では働きません。だから URL は描画の元のデータから返し、ウィジェットが同じ値を使っていることを G2 で reviewer が grep で見ます。
  - `widget.line` などは読み上げから隠すので、XCUITest でなく H22 の出力で読みます。

**E. 次の段で書くもの**
- **設計メモ** /Users/takumamatsuura/reading-app/docs/adr/features/001-reading-session.md の章立て（ひな形 A のとおり）
  1. 範囲：芯の 85件。選択肢の 51件は (iii) のあとに足す。
  2. 対応表：85行。列は AC、画面、操作、保存の項目、外への問い合わせかつなぎ口、確かめるテスト。サーバーがないので operationId の列は、NDL の問い合わせとつなぎ口の番号で代える。
  3. 構成図：アプリ、ウィジェットの拡張、ローカルのパッケージ3つまで（ドメインと保存と書誌と組みの計算／アプリと拡張で共有する描画／画面）、App Group の写し、国立国会図書館サーチ。
  4. 契約と互換性：spectral の出力、oasdiff は「新規」。
  5. データモデル
     - SwiftData を VersionedSchema v1 から使う。
     - 本：id、ISBN、書名、著者、出版社、レーベル、出版年、置き場所、加えた日時、積読に加えた日時、読み終えた日時、一行、ページ、書誌の状態、前に問い合わせた日時、手で直した印。
     - 記録：読み始めの日時、タイムゾーン、分、入口の印。
     - 設定2つと、置き方の案内を見た印。
     - ウィジェットの写しの形と版。
     - pdm に聞くこと：今の本を替えたとき、前の今の本の置き場所と、積読の並びに使う日時。PRD に決まりを見つけられませんでした。
  6. 非機能：PRD 12 の芯の行を、数字と測り方つきで書く。UIBackgroundModes なし、保存1回で再読み込み1回を含める。
  7. 脅威モデル（STRIDE を軽く）
     - 外への送信（ISBN と書名を HTTPS で送る）
     - ロック中に読める App Group の写し
     - ロック画面に一行が見えること
     - つなぎ口がストアの版に入らないこと
  8. 観測：v1.0 は外に送らない。Logger、MetricKit、signpost。G1-11 の代わりの出し方。
  9. 依存：なし（Apple のフレームワークだけ）。
  10. ADR と未確認。
- **契約**（contracts/）
  - contracts/test-hooks.md と、hooks/ の下の JSON Schema。中身は、芯の23個の形、上の D の足すもの、G1-10 の G4-15 用の作り。JSON Schema は次の6つ。
    - H2 の投入
    - H13 の読み出し
    - H22 の出力
    - H17 の値の書き方
    - H20 の差し替え（国立国会図書館の要素名のまま。PRD 11 の冒頭）
    - H29 の記録
  - contracts/ndl-opensearch.yaml：OpenAPI 3.1 で、使う GET の1つだけを書く。
    - 引数は dpid、title、isbn、cnt。
    - 応答は application/xml の例と、要素の対応表（dc:title、dc:creator、author、dc:publisher、dcndl:seriesTitle、dcterms:issued、dcndl:ISBN の dc:identifier）。
    - XML なので、クライアントは生成せず、URLSession と XMLParser で読む（ADR に理由を書く）。
  - contracts/widget-snapshot.schema.json：版、今の本（書名、ISBN、一行、ページ）、隠す設定。
  - contracts/entry-urls.md：AC-40 の入口ごとの URL。
  - contracts/dependencies.md：「芯は外部のライブラリなし」の1行。
- **ADR の候補**（5本）
  - 0001 iOS の土台
    - 最低 iOS 26。ビルドは Xcode 27.x（この機械は 27.1）。
    - Swift 6、MainActor を既定にする、パッケージは3つまで。
    - 強制アップデートは、サーバーがないので入れない。理由と見直す条件を書く。
  - 0002 保存と共有
    - 主の保存先は SwiftData（Application Support）、ウィジェットとは App Group の JSON の写しで分け合う。
    - 保護の等級（G1-16 (a)）は、両方とも既定（completeUntilFirstUserAuthentication）にする。ロック中に読めない等級を選ばないので、18 の Q6 には触れない。
    - 比べる案として「主の保存先だけ complete」を書く。
      - 芯だけなら成り立つ見込み［推測］。
      - (5) と (ショートカット) を残すと、ロック中の「読み始める」と「どこまで読んだ？」が崩れ、Q6 に触れるので採らない。
    - PrivacyInfo の申告（時計と App Group）もここで決める。
  - 0003 縦書きの組み：B の作り、要修正1の式、要修正2の表。比べる案は「Core Text で画像にする」で、vibrant と読み上げと H22 の理由で採らない。
  - 0004 書誌の問い合わせ
    - dpid、cnt=50、問い合わせ直しの決まり。
    - openBD を使うか（使うなら AC を足す）。
    - クレジットの文字列（G1-5）、送ることが「収集」に当たるか（G1-12）、ATS の例外なし。
  - 0005 テストのつなぎ口
    - テスト用の構成でだけ入れ、App Store の版に入れない。G2 で grep と nm で確かめる。
    - H22 はアプリの中の描画の口にする。
    - 速さを測る Release の構成を作る。G1-10 で G4-15 の本500冊と記録5,000件を入れる方法も、ここで決める。
- **CLAUDE.md**
  - 書くもの
    - 概要
    - 構成：バックエンドの行は使わない。
    - このアプリの決まり：最低 iOS 26、Swift 6、外部のライブラリなし、識別子は design/ の 6 と 7 を正とする、つなぎ口はテストの構成だけ。
  - コマンド
    - ios/ がまだないので「未確認」と書く。コマンドの形だけ、スクラッチで確かめる。
    - 確かめたあと、app.json の commands の更新を Takuma に頼む。
  - G1-3：この機械の runtime は iOS 27.0 だけです。`xcodebuild -downloadPlatform iOS -buildVersion 26.x` を試し、入れば手順を、入らなければ「iOS 26 は G4 の実機だけ」と書く。
- **書誌の30件の手順**（PRD 6 の「書誌」の行どおり）
  1. 問い合わせる前に、確かめる本を書き出してコミットする。
     - 既刊20件：文庫、新書、単行本で、出版社10社以上。
     - 新刊10件：国立国会図書館と関係のない新刊の一覧から、確かめる日の15〜28日前に出た本。出どころの URL も書く。
     - 出て14日以内の本5件：記録だけにする。
  2. 1件ずつ `dpid=iss-ndl-opac iss-ndl-opac-inprocess&isbn=<ISBN>` で問い合わせる。
  3. 書名、著者（AC-92 の決まりで取れる）、出版社がそろったかを記録する。
  4. 30件のうち27件以上そろえば合格。openBD の結果は、補いとして別に記録する。
  5. 結果を書誌の ADR に書く。
  6. 書名で探す形（AC-4）も1回試す。

**F. 見積もり（芯の G1 の tech-lead の分）**
r2 の見積もりは 1.5〜2日です。この仕様を見たあとの見積もりは 2.2〜3.25日［推測］で、0.7〜1.25日足りません。

| 中身 | 日［推測］ |
|---|---|
| 設計メモ（85行の対応表） | 0.5 |
| つなぎ口の契約（23個と Schema 6つ） | 0.5〜0.75 |
| ADR 5本 | 0.5〜0.75 |
| 縦書きの spike（r2 の表になかった） | 0.25 |
| 書誌の30件 | 0.25〜0.5 |
| CLAUDE.md と G1-3 | 0.1〜0.25 |
| G1-10〜G1-13（r2 の表になかった） | 0.1〜0.25 |

- 速さの式は、芯の G1 の見積もりを 3.25〜4.5日に固めています（裁定 24）。この分だけ、測る速さが約2割低く出ます。その結果、回す範囲は広い方へ倒れます。
- 測る前に記録しておくかは、指揮役が決めることです。

**G. 実行したコマンドと出力（詳しく）**
1. 環境
   - `git rev-parse HEAD` → c2689c5791fb783ae4c435ddb1bb4a486578cc68
   - `xcodebuild -version` → Xcode 27.1（27A9275）
   - `xcrun simctl list runtimes` → iOS 27.0 だけ
2. typecheck
   - `xcrun --sdk iphonesimulator swiftc -typecheck -target arm64-apple-ios26.0-simulator typecheck.swift`（SDK は iPhoneSimulator27.1）→ exit 0、出力0行。
   - 比べるために `-target arm64-apple-ios18.0-simulator` で動かす → exit 1。
     - `'init(role:action:)' is only available in iOS 26.0 or newer`
     - `'close' is only available in iOS 26.0 or newer`
     - `'confirm' is only available in iOS 26.0 or newer`
   - SwiftUI.swiftinterface:11767-11770
     - `@available(iOS 26.0, ...)` `public static let confirm: SwiftUI.ButtonRole`
     - `public static let close: SwiftUI.ButtonRole`
     - searchable の宣言は44個で、識別子の引数は0個。
3. 色と書体の実測
   - `xcrun simctl create tl-g1-design-review-techlead`（iPhone 17、iOS 27.0）→ `simctl spawn` でプログラムを動かした → `simctl delete`。
   - 色の出力
     - `light/high/base: systemGroupedBackground=#EBEBF0 ... systemRed=#E9152D`、`text.secondary #48484A on: ... systemGroupedBackground=7.68`
     - `dark/high/base: secondarySystemGroupedBackground=#242426`（9.20）
     - `dark/high/elevated: secondarySystemGroupedBackground=#363638`（7.16）
     - `dark/normal/elevated: tertiarySystemGroupedBackground=#3A3A3C`（3.96）
     - `light/normal: systemRed=#FF383C`、`dark/normal: systemRed=#FF4245`
   - 書体の出力
     - `HiraMinProN-W3 pt=17 lineHeight=17.00 ascender=14.96 descender=-2.04 leading=8.50`
     - U+FE11、FE12、FE41〜FE44、FE19、FE35、FE36、FE31 が、W3 と W6 の両方で ok。
     - `AAT feature type 4 (vertical substitution) present: true`
4. 読み上げの形の spike
   - `xcrun simctl create tl-g1-design-review-techlead-ax` → `xcodebuild test -project FlipSpike.xcodeproj -scheme FlipSpike` → TEST SUCCEEDED → `simctl delete`。
   - 出力
     - `c.row exists=true type=48 label=羅生門, 積読から・同じ著者`
     - `c.reason exists=true`
     - `k.row > k.choose exists=true`
     - `n.row exists=true type=9`、`n.pending exists=true`
     - `searchFields.count=1 first.identifier=''`
     - `searchFields[search.field].exists=false any[search.field].type=32`
     - `primary.styled darkFraction=0.147`、`primary.default darkFraction=0.000`
5. `python3 -I check_ids.py <PRD> <design>`
   - `core AC: 85 option AC: 51`
   - 芯の AC が使うつなぎ口：上の D のとおり。
   - design/ にない名前は、つなぎ口の値だけ（D のとおり）。
6. 国立国会図書館サーチへの問い合わせ
   - `curl 'https://ndlsearch.ndl.go.jp/api/opensearch?dpid=iss-ndl-opac%20iss-ndl-opac-inprocess&title=人間失格&cnt=50'`
   - → `bytes: 159572 totalResults: 264 items: 50 items_with_ISBN: 21 unique_first_ISBN: 21`
- spike で作った物と記録は、すべてリポジトリの外にあります。リポジトリには何も書いていません。
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-tech-design-review/spike/typecheck.swift
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-tech-design-review/spike/runtime.swift
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-tech-design-review/spike/probe-out.txt
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-tech-design-review/axspike/xcb.log
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g1-tech-design-review/check_ids.py

**H. 開いた URL と原文の引用（2026-10-20）**
JSON は https://developer.apple.com/tutorials/data/documentation/... から開きました。
- https://developer.apple.com/documentation/swiftui/buttonrole/close
  - 「A role that indicates a button that closes the current operation.」
  - 「Unlike a cancel operation, a close operation doesn't lose progress for a user.」
- https://developer.apple.com/documentation/swiftui/buttonrole/confirm
  - 「A role that indicates a button that confirms an operation.」
- https://developer.apple.com/documentation/swiftui/accessibilitychildbehavior/combine
  - 「Any child accessibility element's properties are merged into the new accessibility element.」
- https://developer.apple.com/documentation/swiftui/accessibilitychildbehavior/contain
  - 「Any child accessibility elements become children of the new accessibility element.」
- https://developer.apple.com/documentation/swiftui/widgetconfiguration/contentmarginsdisabled()
  - 「When you disable content margins for a widget, the system doesn't automatically add margins around the widget's content, and you are responsible for specifying margins and padding around your widget content for each context.」
- https://developer.apple.com/documentation/foundation/fileprotectiontype/completeuntilfirstuserauthentication
  - 「After the user unlocks the device for the first time, your app can access the file and continue to access it even if the user subsequently locks the device.」
- https://developer.apple.com/documentation/visionkit/datascannerviewcontroller/issupported
  - 「For this property to be true, the device must have the A12 Bionic chip or later.」
- https://developer.apple.com/documentation/widgetkit/swiftui-views
  - 「Widgets can use many, but not all, SwiftUI views to present content. Use the views listed below to implement your widget's view. Widgets can't use UIKit or AppKit views wrapped with UIViewRepresentable or NSViewRepresentable.」
  - 一覧に Text、HStack、VStack、ZStack、GeometryReader、Spacer、Image、GroupBox がある。
- https://developer.apple.com/documentation/widgetkit/creating-a-widget-extension
  - 「WidgetKit ignores other views when it renders the widget's content.」
- https://ndlsearch.ndl.go.jp/api/opensearch（上の G の 6）

**未検証**
- この判定（今の構成で作れるか）の前提で、確かめられなかったものはありません。
- この判定では見ていないことは、次の5つです。どれも、作れるかの答えは変えません。
  - 拡張の中で縦書きを描いた絵：縦書きの ADR の spike と G4-1 で見る。作りは spike A と字形の実測と、WidgetKit の一覧で裏づけた。
  - ロック画面の vibrant の見え方：G4-1。
  - iOS 26 での色の値：G1-3。
  - 縦の固定がオンのときの伏せる道（Q-A）：Takuma の実機。
  - 本物のカメラでの続けての読み取り：G4-10。

## 記録（指揮役が保存するときに書き足す）
- 関門：G1。判定した役：tech-lead。回：r1。結果：PASS（重大0件、要修正3件、提案5件）
- 対象：BASE=c2689c5791fb783ae4c435ddb1bb4a486578cc68
- 日付：2026-10-20
- spike の端末2台は、判定役が消した（報告の G）
