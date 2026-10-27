（指揮役の注）本の情報の取り方を初めから考え直す調べもの（Takuma の 2026-10-20 の「思考を拡張しより良い体験を」）のうち、tech-lead の報告（紙の本のどこから何が取れるか、iOS の機能、spike）。pdm と designer も並べて考えた。判定ではない。報告の文はそのまま保存した。

（指揮役へ：保存先は docs/reviews/001-reading-session-rethink-tech-lead.md の想定です。判定ではなく、調べものと spike の報告です。）

# 本の情報の取り方を端末の機能から考え直す（tech-lead の調べものと spike）

## 変更したファイル
- リポジトリのファイルは変えていません。コミットもしていません。
- 作業はすべて /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/rethink-tech/ の中です（以下 S/ と書きます）。
  - spike のプログラム：S/spike/main.swift（柱とノンブル、表紙と帯、背表紙の数）、S/spike/vk.swift（VisionKit の言語の一覧）
  - 実行ファイル：S/bin/rethink（Mac）、S/bin/rethink_sim、S/bin/vk_sim（iOS 26.0 シミュレーター）
  - 画像44枚：S/out/img/*.png（ページ15、表紙21、棚8）
  - 記録：S/out/mac_run1.log、S/out/mac_run2.log、S/out/sim_run1.log
  - 落としたもの：S/dl/c_code_list.png（日本図書コード管理センターの C コードの表）
- シミュレーターの端末 rethink-tech-ios26（17620D58-2980-4150-99F0-0217A0BE5D64）は自分で作り、使ったあと消しました（`simctl list devices | grep -c rethink-tech` → 0）。
- 手数は40回です。

## 1. 結論

**一言でいうと：** 外部の API なしで、すべての項目を確かに取れる場所は1つもありません。ただし、場所と時を分けると、どの項目にも確かな取り場所があります。

### 項目ごとの、いちばん確かな場所
- **ISBN**：バーコード
- **出版社**
  - 候補はバーコードから出せます（ISBN の出版者記号を表で引く）。
  - 確かな値は奥付です。
- **レーベル**
  - 文庫、新書、単行本の別は、バーコードの2段目から確かに取れます。
  - レーベルの名前は、候補ならバーコード、確かな値は奥付です。
- **書名と著者**：表紙か背表紙の行を押して選ぶ形です。自動で選ぶのは確かではありません。
- **出版年**：奥付だけです。
- **章とページ**（毎晩）：柱とノンブル。ただし候補として出す扱いです。

### 確かなもの（文書、SDK、spike の裏付けあり）
1. **バーコードの1段目（ISBN）**：チェックディジットで確かめられます。今の計画の道です。
2. **バーコードの2段目（日本図書コードの C コード）**
   - 公式の表で意味が決まっています。2桁目が発行形態で、0 単行本、1 文庫、2 新書です。
   - 3〜4桁目が内容です。93 は日本文学の小説・物語、97 は外国文学の小説です（翻訳書の手がかりになります）。
   - 本体価格も入っています。
   - いまの AC-3 は、2段目（1920193006001）を「本でないコード」として捨てています。これを使う側に回せます。
3. **ISBN の出版者記号から出版社を当てる表（通信なし）**
   - JAPAN/MARC の1週分（1,655件）で測りました。記号ごとの多数派の出版社名と一致したのは 94.5% です。
   - 半分のデータで表を作り、残り半分で試しました（5回の平均）。記号が表にあったのは 75.7%、あったときに正しかったのは 91.9% です。
   - 「記号＋次の1桁」でレーベルを当てると 77.8% です。例：4-10-1 は新潮文庫、4-16-7 は文春文庫、4-12-2 は中公文庫、4-488-4 は創元推理文庫。
4. **Vision は iOS 26 で、日本語の縦書きと横書きを端末の中で読めます**
   - 今回、iOS 26.0 のシミュレーターで同じ spike を動かしました。RecognizeTextRequest は revision3 で、ja を含む30言語でした。RecognizeDocumentsRequest も ja に対応していました。
   - 縦の柱、縦書きの表紙、背表紙を読めました（合成の画像）。
5. **表紙では、書名と著者が帯の文と混ざらず、別々の行として出ます**
   - 書名に別の文がくっついた行は、Mac とシミュレーターとも 0/21 でした。
   - そのため「行を押して選ぶ」形は作れます。書名の行が出たのは Mac 17/21、シミュレーター 20/21 です。
6. **柱は、本文と別の小さい行として取れます**：きれいな画像と写真に寄せた画像で 10/10 です（Mac もシミュレーターも）。書名の柱なら、今の本の確かめに使えます（2/2）。
7. **奥付は、5項目がそろう唯一の場所です**（前回の spike）。

### 確かでないもの
1. **本物の写真での精度**：すべて合成の画像で、規則も私がこの画像を見ながら書きました。どの数字も上ぶれします。
2. **iPhone での速さ**
   - しばらく使わなかったあとの最初の1回は、Mac で 27.96秒、シミュレーターで 13.75秒でした。
   - そのあとの1枚あたりの中央値は、Mac 0.35〜0.83秒、シミュレーター 2.10秒です。
   - iPhone では測っていません。
3. **表紙で書名を自動で選ぶこと**
   - 「いちばん大きい字が書名」は Mac 9/21、シミュレーター 11/21 です。帯の字の方が大きいことが多いためです。
   - 帯によく出る語を除いても、書名と著者が両方正しいのは 12/21 と 13/21 です。
4. **背表紙を1冊ごとにまとめること**
   - 書名は読めます。ただ、書名と著者を同じ本として組むのは、正面からの合成でも 118/180 でした。
   - 傾いた写真では 0/50 です（私の規則が崩れます）。
5. **私の環境で確かめられなかったもの**
   - DataScanner のライブの映像で縦書きが読めるか（シミュレーターでは動きません）。
   - 「テキストをスキャン」（captureTextFromCamera）について、許可が要るか、日本語、縦書き。
6. **どの本に書名の柱があるか**：慣習の出典を見つけられませんでした［推測］。
7. **2段目のバーコードがない本の割合**と、先頭の「192」の正式な意味は未確認です。
8. **出版者記号の桁の決まり**は、私の覚えで使いました［推測］。データとは矛盾しませんでした。

## 2. 推す案（tech-lead の見立て。どれを採るかは pdm と designer の案と合わせて決めることです）

**「1回で全部」をやめ、場面ごとに確かなものから取る形を推します。** 何も外に送らず、AI に文を作らせず（裁定 12）、Apple Intelligence にも頼りません（裁定 17 に関わりません）。

1. **加えるとき**
   - バーコードで ISBN を取ります。2段目のコードから文庫、新書、単行本の別と、小説か翻訳かを取ります。出版者記号の表から、出版社とレーベルの候補を出します。
   - 続けて表紙を1枚撮り、書名と著者の行を押します。候補は先に選んでおき、合っていれば押すだけにします。打つのは、字の読み違いを直すときだけです。
   - 出版者記号の表は、小さな種の表に加えて、利用者が直した結果から端末の中で学ぶ形にできます（外のデータに頼る量を減らせます）。
2. **積読をまとめて入れるとき**
   - 本棚の写真（カメラか写真のライブラリ）から、背表紙の書名を押して加えます。書名だけでも加えられるようにし、著者は候補にとどめます。
   - 1段ずつ撮る案内にすると、字が大きくなり、傾きも小さくなります［推測］。
3. **毎晩**
   - 撮る道で撮るページから、柱を章の名前と「この本で合っているか」の確かめに使います。ノンブルはページの候補にします。
   - どちらも候補として出すだけです。前の値を黙って上書きしません（デザインの決定 18 と同じ線）。
4. **読み終えた夜**
   - 奥付を撮り、出版年、版、正式な出版社とレーベルを確かめて埋めます。読み終えた画面の奥付（AC-77）を、本物の奥付に合わせられます。
5. **いつでも使える道**
   - 手で入れる道。
   - 写真から選ぶ道（PhotosPicker）。許可は要らず、スクリーンショットも選べます。手元にない本（書店のページのスクリーンショットなど）の代わりの道にもなります。

**v1.0 に推さないもの**
- Visual Intelligence：対応機種だけで、日本語の環境で結果が出るかは未確認です。
- カメラコントロールとロック画面のカメラ：自前のカメラ画面が要ります。
- App Intents で写真から加える道：価値が小さいです。
- 書誌の判定に Foundation Models を使うこと：前回、規則より正しくならず、使える機種も限られました。
- 書誌データを丸ごと入れる形（C）と、国立国会図書館サーチ（A）。

**いちばん強い反論**
- 書名と著者は、どの場所から取っても「押して確かめる」1〜2手が残ります。他のアプリのような「向けるだけで全部埋まる」にはなりません。
- 背表紙から加えた本は、著者や出版社が欠けたまま積読に入ります。「次の1冊」（同じ著者、同じレーベル）と受賞の照らし合わせが弱くなります。

**これは私の判断です。** 決める前に reviewer に反論を出してもらってください。

## 3. 場所ごと・項目ごとの取れ方の表
印の意味
- ◎：決まった形で確かに取れる
- ○：読めばほぼ取れる（行を押して選ぶ）
- △：候補として出せる
- ×：載っていない

| 場所 | 書名 | 著者 | 出版社 | レーベル | 出版年 | ほか | 根拠 |
|---|---|---|---|---|---|---|---|
| バーコード1段目（ISBN） | × | × | △（出版者記号の表。多数派と一致 94.5%） | △（記号＋1桁で 77.8%） | × | ISBN ◎ | 今回の Python。前回の spike |
| バーコード2段目（192＋C コード＋本体価格） | × | × | × | 形 ◎（文庫、新書、単行本） | × | 小説か翻訳か ◎、本体価格 ◎ | 日本図書コード管理センターの表。「192」の意味は未確認 |
| 表紙 | ○（行が出た：Mac 17/21、シミュ 20/21。自動の正解は 9〜14/21） | ○（Mac 21/21、シミュ 20/21） | △（単行本は表紙に版元名があることが多い［推測］） | △（文庫のロゴや字［推測］） | × | 翻訳書は原題と訳者の行も出る | 今回の spike B |
| 帯 | ×（罠：別の本の書名、表紙より大きい宣伝の字） | × | × | × | × | 受賞などの宣伝文（使わない） | spike B の C3、C6 |
| 背表紙（棚の写真） | ○（字が約36px で Mac 180/180、シミュ 172/180） | △（Mac 169/180、シミュ 150/180。小さい字に弱い） | △（文字なら大きく写ったときだけ） | △（同上。ロゴは絵［推測］） | × | 本ごとの組は弱い | spike C |
| 柱（毎晩のページの上か端） | △（書名の柱がある本だけ。確かめには 2/2） | × | × | × | × | 章の名前 ○ | spike A。慣習は［推測］ |
| ノンブル | × | × | × | × | × | ページ △（Mac 12/18、シミュ 16/18） | spike A |
| 奥付 | ○ | ○ | ○ | ○ | ◎（初版と改版の年。前回 8/8） | ISBN ○、版と刷 | 前回の spike：書名・著者・出版社の3つがそろったのは 7/8、5/8、1/8 |
| 毎晩のページの本文 | × | × | × | × | × | 続きの一行（AC-65） | 前回までの spike |

**本の種類による違い（［推測］の部分が多い）**
- **文庫**
  - 表紙の書名は縦書きが多い［推測］。背にはレーベル名、ロゴ、著者の記号が付きます。
  - 奥付は縦書きが多く、改版の年があります。
  - C コードの2桁目は1です。記号＋1桁でレーベルが決まりやすいです（今回のデータ）。
- **新書**：装丁が決まった形です［推測］。C コードの2桁目は2です。
- **単行本**
  - 表紙のデザインが自由で、飾り文字や大きい帯があり、自動では取りにくいです。今回の飾り文字の表紙（C2）は、Mac で書名の行が 1/3 しか正しく出ませんでした。
  - 背に出版社名が字で入ることが多いです［推測］。C コードの2桁目は0です。
- **翻訳書**
  - 著者はカタカナで、表紙と奥付で同じ表記です。訳者の行と英字の原題があるので、規則で訳者を除く必要があります。
  - C コードの内容は 97（外国文学の小説）です。

## 4. iOS の機能の表
最低の OS は iOS 26 です。iOS 26 の iPhone はすべて A13 以上と見ています［推測］。

| 機能 | 使える OS と機種 | 日本語 | 縦書き | 速さ | シミュレーター | 許可 | 根拠 |
|---|---|---|---|---|---|---|---|
| VisionKit の DataScanner（コードと文字を同時に。押せる、光らせる、撮る） | iOS 16 から、A12 以上（isSupported） | ○（iOS 26.0 の supportedTextRecognitionLanguages に ja-JP。30言語） | 未確認（実機が要る） | 未測定 | 動かない（isSupported=false） | カメラ | SDK の swiftinterface の `text(languages:textContentType:)`、`didTapOn`、`capturePhoto()`。vk_sim の出力 |
| Live Text と ImageAnalysisInteraction（止めた画像の字を、利用者がシステムの操作で選ぶ） | iOS 16 から［機種は推測：A12 以上］ | ○（ImageAnalyzer の言語に ja-JP） | 未確認 | 未測定 | ImageAnalyzer.isSupported=true | 自分の画像なら不要［推測］ | `selectedText`（swiftinterface 153行） |
| テキストをスキャン（captureTextFromCamera：入力欄にカメラから字を入れる） | iOS 15 から。Neural Engine のある iPhone で、対応言語が優先言語にあること | Live Text の対応言語に Japanese があるので使える見込み［推測］ | 未確認 | 未測定 | 使えない見込み［推測］ | 未確認（システムの画面で、アプリには字だけ渡る［推測］） | WWDC21 10276、UIKit の文書 |
| Vision の RecognizeTextRequest（止めた画像） | iOS 18 から（Swift の API）。revision3 | ○ | ○（合成：縦の柱 3/3、縦の表紙 6/6、背表紙） | Mac：最初 27.96秒、以後の中央値 0.35〜0.83秒。シミュ：最初 13.75秒、中央値 2.10秒。iPhone は未測定 | 動く（iOS 26.0 で確認） | 不要（画像の出どころによる） | 今回の spike |
| Vision の RecognizeDocumentsRequest | iOS 26 から | ○ | ○（topToBottom を返す） | RecognizeTextRequest と同じくらい | 動く | 不要 | SDK `@available(macOS 26.0, iOS 26.0, …)` |
| 最小の字の高さ（minimumTextHeightFraction） | iOS 18 から | - | - | 既定 1/32。下げると背表紙で大きく効く | - | - | 文書と spike C |
| VNDocumentCameraViewController（書類を撮るシステムの画面。縁を見つけて切り抜く） | iOS 13 から | 画像だけを返す | - | 未測定 | 動かない［推測］ | カメラ［推測］ | 文書。spike はしていない |
| PhotosPicker（写真から選ぶ。スクリーンショットも含む） | iOS 16 から | - | - | - | 動く | 不要 | 前の調べもの |
| カメラコントロール（AVCaptureControl） | iOS 18 から。文書には「iPhone 16 devices」 | - | - | - | 動かない | カメラ。自前の AVCaptureSession の画面が要る | Apple の文書 |
| LockedCameraCapture（ロック画面、コントロールセンター、アクションボタンからアプリのカメラを開く拡張） | iOS 18 から | - | - | - | - | カメラ | Apple の文書 |
| Visual Intelligence へ結果を出す（IntentValueQuery） | iOS 26 から。Apple Intelligence の機種だけ（iPhone 15 Pro 以降、iPhone 16 以降、iPhone Air：前の報告） | Visual Intelligence の既存の機能は日本語あり。アプリの結果が出るかは未確認。「Siri AI: Visual Intelligence」は英語だけ | アプリが Vision で読む | 未測定 | - | 不要（写すのはシステム） | SDK：`labels: [String]`、`pixelBuffer`。apple.com の機能の一覧 |
| App Intents（ショートカット、Spotlight、アクションボタンの入口） | iOS 16 から。全機種 | - | - | - | - | - | 前の報告。取り方ではなく入口 |

## 5. 部品ごとの手間と危険の表
- 単位は r2 と同じ「1人の作り手の日」（G1〜G3 を含む）で、すべて［推測］です。
- 基準は今の A です。r2 の「登録2.5日」のうち、A だけの分（問い合わせと XML、待ちと問い合わせ直し、書名で探す）は約1.5日でした。

| 部品 | 手間（A との差） | 主な危険 | 端末の条件 | 推す |
|---|---|---|---|---|
| P0 A を外す（NDL の問い合わせ、待ち、書名で探す） | −1.5 | 書名で探す（AC-4〜AC-6）が消える | - | 外す |
| P1 バーコードの ISBN（続けて読む、重なりを除く） | 0（今の見積もりに入っている） | - | A12 以上（DataScanner） | v1.0 |
| P2 2段目のコード（C コード、本体価格） | +0.1〜0.25 | 2段目のない本［推測］。2冊が同じ画面のとき、どの ISBN と組むかの取り違え（近い方と組み、組めなければ捨てる） | 同上 | v1.0 |
| P3 出版者記号の表（小さな種の表＋端末で学ぶ） | +0.25〜0.5 | 記号の共有（講談社と星海社）、子会社、社名の変更、表の古さ。種の表を NDL のデータから作るなら出典の記載が要る | なし | v1.0（候補として出す） |
| P4 止めた写真で行を押す（表紙、奥付、スクリーンショット） | +0.25〜0.75（撮る道の列を選ぶ部品を使い回す） | 字の読み違い（「蜜蜂ど遠雷」「ここころ」「バカの蟹」）。押したあと直せる欄が要る | 全機種 | v1.0 |
| P5 奥付を規則で先に埋める | +0.25〜0.5（前回のコードがある） | 前回の結果：3項目そろいは 7/8、5/8、1/8 | 全機種 | v1.0 |
| P6 表紙で書名と著者の候補を先に選ぶ（帯の語を除く） | +0.1〜0.25 | 自動の正解は 12〜13/21。候補を出すだけにする | 全機種 | v1.0 |
| P7 テキストをスキャンの欄 | +0.25〜0.5（SwiftUI には直の API が見当たらず、UIKit の欄を包む［未確認］） | 機種と言語の条件、許可、縦書きが未確認。使えないときは隠す | Neural Engine | 任意 |
| P8 DataScanner のライブの文字（コードと同じ画面で行を押す） | +0.5〜1.0 | 縦書きが未確認。シミュレーターで動かないので、受け入れテストは差し替えの口でしか確かめられない | A12 以上 | 実機で縦書きを確かめてから |
| P9 柱とノンブル（毎晩の撮る道のついで） | +0.25〜0.5 | 柱のない本、章の柱、読み違い（「第一の手を」）。候補だけにして上書きしない | 全機種 | v1.0 |
| P10 読み終えた夜に奥付で確かめて直す | +0.25〜0.5（P4、P5 を使う） | 読み終えた夜の流れが長くなる（designer の判断） | 全機種 | v1.0 |
| P11 本棚の写真から背表紙を押して加える | +1.0〜2.0 | 本物の棚の写真は未確認。傾くと本ごとの組が 0/50。大きな写真の時間とメモリ（4,000px くらいに縮める）。著者が欠ける | 全機種 | 速さに余裕があれば v1.0 |
| P12 写真から選ぶ（PhotosPicker） | +0.1〜0.25 | なし（カメラを断った人の道にもなる） | 全機種 | v1.0 |
| P13 手で入れる | 0（今の見積もり） | - | - | v1.0 |
| P14 Visual Intelligence | +1.0〜1.5 | 対応機種だけ。日本語の環境で出るか未確認。裁定 17 | AI の機種 | 推さない |
| P15 カメラコントロール、ロック画面のカメラ | +1.5〜3.0 | 自前のカメラ画面と拡張が要る。価値が小さい | iPhone 16 以降 | 推さない |
| P16 App Intents で写真から加える | +0.5 | 価値が小さい | 全機種 | 推さない |

**組み合わせごとの見当（A との差）**
- 前回の F（奥付か表紙で行を押す＋手で入れる）：+0.25〜1.0
- 推す案（P0〜P6、P9、P10、P12、P13）：+0.05〜+2.0
  - P7 を足すと、さらに +0.25〜0.5。
  - P11 を足すと、+1.05〜+4.0。
- 全体の見積もり 37.96〜53.85日と、速さ 13.2〜18.2倍（要るのは最大 3.59倍）の中に収まる見込みです［推測］。

**テストの口**
- H21（コードを流す）に、2段目のコードを足す必要があります。
- 表紙、奥付、棚の「画像そのもの」を差し込む口を足すと、シミュレーターで本物の Vision が動きます。これは今回、iOS 26.0 で確かめました。より本物に近い G3 のテストができます。ただし最初の1回が遅い（シミュで 13.75秒）ので、先に温める手当てが要ります。

**変わる AC の見当**（細かくは pdm が書き直します）
- AC-2、AC-3：行に書名が出ない形になります。2段目を捨てずに使います。
- AC-4〜AC-6、AC-9〜AC-11、AC-113：消えるか、書き直します。
- AC-12：写真から選ぶ道が足されます。
- 撮る道（AC-65）：ページの候補が足されます。
- 読み終えた夜（AC-77）：奥付を撮る道が足されます。
- AC-103：通信の要求は0件になります。

## 6. spike の結果
**条件**：Mac（macOS 27.0.1、Xcode 27.1、Vision revision3）と、iOS 26.0 シミュレーター（同じソースをビルドし、simctl spawn で実行）。合成の画像を3つの状態で読みました。
- きれい
- 写真に寄せた：−0.5EV、ぼかし1.2、約2.3度、0.6倍
- 悪い：−1.0EV、ぼかし1.8、約4.6度、0.45倍

### A. 柱とノンブル（毎晩撮る文庫のページ。本文は縦書き 36px、柱とノンブルは 22px）
置き方は5つです：天に横書きの章の柱、天に横書きの書名の柱、小口に縦書きの柱、見開き（書名と章）、柱なし。

| 状態 | 柱が1行として出た（Mac／シミュ） | 規則で柱を拾えた（誤って拾った数） | ノンブル（Mac／シミュ） | 書名の柱で今の本と照らせた |
|---|---|---|---|---|
| きれい | 5/5 ／ 5/5 | 5/5（1）／ 5/5（0） | 5/6 ／ 6/6 | 2/2 ／ 2/2 |
| 写真に寄せた | 5/5 ／ 5/5 | 5/5（1）／ 5/5（0） | 4/6 ／ 6/6 | 2/2 ／ 2/2 |
| 悪い | 3/5 ／ 4/5 | 3/5（3）／ 4/5（1） | 3/6 ／ 4/6 | 2/2 ／ 1/2 |

- 規則：本文の字の中央値の 0.8倍より小さく、数字だけでない2〜20字の行を柱とします。数字だけの1〜4字はノンブルとします。
- 誤りの例：「第一の手記」→「第一の手を」「第一の手起」。
- 章の柱（「第一の手記」「上　先生と私」）では、書名の照合は「なし」が正しい結果です。
- 柱なしのページで柱を誤って拾ったのは 0 でした。

### B. 表紙と帯（7種、21枚）
7種の中身
- 文庫の縦書きに黄色い帯（「累計７００万部突破！」）
- 単行本の飾り文字（凸版文久見出し明朝）に赤い帯
- 翻訳書（帯に別の本の題『カササギ殺人事件』）
- 新書（帯「４５０万部突破」）
- にぎやかな地の上の低いコントラストの書名
- 帯の字が書名より大きい（「芥川賞受賞！」120px と書名 72px）
- 帯のない縦書き

| 状態 | 書名の行が出た（1〜2行。Mac／シミュ） | 著者の行が出た | 両方（押せば入る） | 最大の字＝書名 | 帯の語を除く規則で書名と著者が正しい | 書名が他の文と結合 |
|---|---|---|---|---|---|---|
| きれい | 7/7 ／ 7/7 | 7/7 ／ 7/7 | 7/7 ／ 7/7 | 5/7 ／ 5/7 | 6/7 ／ 6/7 | 0 ／ 0 |
| 写真に寄せた | 5/7 ／ 6/7 | 7/7 ／ 7/7 | 5/7 ／ 6/7 | 2/7 ／ 4/7 | 3/7 ／ 4/7 | 0 ／ 0 |
| 悪い | 5/7 ／ 7/7 | 7/7 ／ 6/7 | 5/7 ／ 6/7 | 2/7 ／ 2/7 | 3/7 ／ 3/7 | 0 ／ 0 |

- 翻訳書の書名「ヨルガオ殺人事件　上」は、「ヨルガオ殺人事件」と「上」の2行に分かれました（押すのが2回になります）。
- 字の読み違い（Mac）：「蜜蜂ど遠雷」（飾り文字）、「ここころ」（にぎやかな地）、「バカの蟹」。
- 著者の行の前後に「_」「。」が付くことがありました。記号を落とす整え方が要ります（今回の数字は整えたあとの値です）。

### C. 背表紙（何冊を一度に読めるか）
- 文庫の背を合成しました。書名は明朝 W6 の縦書き（字の大きさ g）、著者は 0.7g、レーベルは 0.42g です。50種を順に並べました。
- 本ごとの組は、写真を「段」に分け、縦に重なる行を1冊にまとめる規則で作りました（最初の規則は 1/20 だったので直しました）。

| 画像 | 冊数 | 書名（Mac／シミュ） | 著者 | レーベル | 書名と著者の組 | 秒（Mac／シミュ） |
|---|---|---|---|---|---|---|
| 1段×20、g=40px（1600×780） | 20 | 20 ／ 19 | 20 ／ 17 | 18 ／ 20 | 17 ／ 14 | 0.63 ／ 1.62 |
| 3段×30、g=30（1770×1683）、最小の高さ 0.005 | 90 | 89 ／ 89 | 86 ／ 78 | 65 ／ 76 | 57 ／ 62 | 1.61 ／ 4.17 |
| 同、既定（1/32） | 90 | 86 ／ 84 | 63 ／ 59 | 5 ／ 3 | 45 ／ 44 | 1.62 ／ 4.03 |
| 同、写真に寄せた（傾きと遠近）、0.005 | 90（50種） | 50/50 ／ 46/50 | - | - | 0/50 ／ 0/50 | 1.26 ／ 4.18 |
| 同、悪い、0.005 | 90（50種） | 44/50 ／ 41/50 | - | - | 0/50 ／ 0/50 | 1.98 ／ 4.17 |
| 4段×45、g=36（3132×2679）、0.005 | 180 | 180 ／ 172 | 169 ／ 150 | 109 ／ 118 | 118 ／ 102 | 3.32 ／ 5.86 |
| 同、既定 | 180 | 155 ／ 146 | 58 ／ 40 | 0 ／ 0 | 0 ／ 0 | 2.93 ／ 6.28 |
| 0.5倍（g=18）、0.005 | 180 | 171 ／ 155 | 142 ／ 119 | 9 ／ 8 | 1 ／ 0 | 3.35 ／ 7.95 |
| 0.5倍、既定 | 180 | 152 ／ **1** | 63 ／ 2 | 0 | 0 | 2.82 ／ 4.04 |
| 0.33倍（g=12） | 180 | 140 ／ 127 | 27 ／ 18 | 0 | 0 | 1.97 ／ 4.35 |
| 0.25倍（g=9） | 180 | 66 ／ 54 | 1 ／ 2 | 0 | 0 | 3.83 ／ 4.99 |

**読み取りの結果**
- 書名は、字が約18px 以上あれば9割前後読めます。12px で7〜8割、9px で3割に落ちます。著者は約25px 以上が要ります。
- 最小の字の高さの既定（1/32）は、棚の写真で著者を大きく落とします。シミュレーターの0.5倍の画像では、既定だと書名が 1/180 になりました。必ず小さく設定する必要があります。

**写真に当てはめた見当**［推測］
- 12MP の写真の幅 4,032px で幅 90cm の本棚を撮ると、文庫の背の字は約30〜40px になる見込みです。合成と同じ条件なら、1枚で百冊台の書名が読める計算です。
- 本物の写真では、ピント、反射、上下の段の遠近で下がります。1段ずつ撮れば、字は2倍ほどになります。

**弱いところ**
- 本ごとの組（書名と著者）が弱い点です。
- 設計は「書名を押して加える。著者は同じ背の行から候補を出す」にするのが安全です。

**上ぶれの注意（すべて）**
- 合成の画像で、システムの字体、平らな紙、完全なピントです。反射、箔押し、紙の曲がり、のどの影、夜の明かりはありません。
- 規則は私がこの画像を見て書きました。シミュレーターの速さは、Mac の CPU の上のものです。

### D. 出版者記号から出版社（JAPAN/MARC 2026-10-16 提供分、ISBN 978-4 で出版社のある 1,655件）
- 記号485個のうち、名前が1つだけの記号は457個です。
- 多数派の名前と一致したのは 1,564/1,655（94.5%）です。
- 多い順の記号が占める割合
  - 上位50個で 55.4%
  - 上位100個で 68.6%
  - 上位200個で 82.3%
- 半分ずつに分けて5回試した平均：表にあった 75.7%、正しかった 91.9%。
- 記号の例
  - 4-10 新潮社×21、4-08 集英社×52、4-09 小学館×49
  - 4-06 講談社×35（星海社×4）
  - 4-04 KADOKAWA×97（ブシロードワークス×4）
  - 4-344 幻冬舎×9（幻冬舎メディアコンサルティング×6）
- レーベル（490 の叢書）を「記号＋次の1桁」で当てると、600/771（77.8%）でした。講談社と KADOKAWA は割れました。
- この1週分は、学術書や官公庁の本も含みます。読書の棚の分布とは違います。

## 7. 本物の写真で確かめる手順（書くだけ。頼むかは指揮役が決める。Takuma は奥付の確かめを「行わない」と決めた）
1. **表紙**：帯の付いた本10冊（文庫4、新書2、単行本3、翻訳書1）を、ふだんの明かりで1枚ずつ撮ります。
   - 合格の線［推測］：書名と著者が押すだけで正しく入るのが8冊以上。
2. **背表紙**：1段ずつの写真を3枚と、本棚全体の写真を1枚。
   - 合格の線［推測］：1段の写真で書名が9割以上。
3. **毎晩のページ**：柱のある本とない本を合わせて5冊、読みかけのページを撮ります。
   - 合格の線［推測］：柱かノンブルが候補として正しく出るのが4冊以上。
4. **バーコード**：手元の10冊の裏表紙を見て、2段目があるかを数えます。撮らずに目で見るだけです。
5. **扱い**
   - 写真は AirDrop で Mac に送ります。tech-lead が S/spike/main.swift に「フォルダを読む」口を足して読ませます（約30分）。
   - 正解は手で打ちます。写真はリポジトリに入れず、終わったら消します。

## 実行したコマンドと結果
（S/ は /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/rethink-tech/ です。）

**環境と SDK**
- `xcodebuild -version` → `Xcode 27.1 Build version 27A9275`。`sw_vers` → macOS 27.0.1。
- iPhoneOS27.1.sdk の swiftinterface を grep した結果
  - Vision：`@available(macOS 26.0, iOS 26.0, …) public struct RecognizeDocumentsRequest`、`minimumTextHeightFraction`、`supportedRecognitionLanguages`
  - VisionKit：153行 `selectedText`、255行と339行 `supportedTextRecognitionLanguages`、270行 `didTapOn`、290行 `text(languages:textContentType:)`、384行 `capturePhoto()`
  - VisualIntelligence：`public let labels: [Swift.String]`、`public var pixelBuffer: CoreVideo.CVReadOnlyPixelBuffer?`
  - UIKit：`- (void)captureTextFromCamera:(nullable id)sender API_AVAILABLE(ios(15.0))`
  - フレームワークの一覧に LockedCameraCapture、VisualIntelligence がある。

**Mac の spike**
- `swiftc -O -swift-version 5 S/spike/main.swift -o S/bin/rethink` → エラー0、警告1（main actor の変数 ocrTimes）。
- `S/bin/rethink render S/out/img` → 2.27秒。
  - 棚：1600x780、1770x1683、1837x1753、1414x1353、3132x2679、1566x1340、1043x893、783x670。
  - 字体はすべて指定どおり解決した（凸版文久見出し明朝を含む）。
- `S/bin/rethink ocr S/out/img`（1回目、記録は S/out/mac_run1.log）
  - `real 121.29`。
  - `RecognizeTextRequest revision=revision3 default minimumTextHeightFraction=0.03125 ja=true langs=33`、`RecognizeDocumentsRequest ja=true`。
  - `FIRST OCR CALL secs=27.96`、`median=0.35 max=3.28`。
  - 背表紙の組が 1/20 だったので、束ね方の規則と記号の整え方を直した。
- 2回目（S/out/mac_run2.log）
  - `real 89.00`、`FIRST OCR CALL secs=2.63`（すぐ続けたため）、`n=52 median=0.83 max=3.82`。
  - ページの結果は1回目と同じだった（diff なし）。表の値は2回目。

**iOS 26.0 シミュレーター**
- `xcrun --sdk iphonesimulator swiftc -O -swift-version 5 -target arm64-apple-ios26.0-simulator S/spike/main.swift -o S/bin/rethink_sim` → エラー0。
- `xcrun simctl create rethink-tech-ios26 com.apple.CoreSimulator.SimDeviceType.iPhone-17 com.apple.CoreSimulator.SimRuntime.iOS-26-0` → `17620D58-2980-4150-99F0-0217A0BE5D64`。そのあと boot。
- `xcrun simctl spawn 17620D58-… S/bin/rethink_sim ocr S/out/img PCS`（記録は S/out/sim_run1.log）
  - exit 0。
  - `RecognizeTextRequest revision=revision3 default minimumTextHeightFraction=0.03125 ja=true langs=30`、`FIRST OCR CALL secs=13.75`、`n=52 median=2.10 max=7.95`。
- `xcrun simctl spawn 17620D58-… S/bin/vk_sim`
  - `iOS 26.0`、`DataScannerViewController.isSupported = false`。
  - `DataScanner text languages (30): en-US,…,ko-KR,ja-JP,…`、`DataScanner has ja: true`。
  - `ImageAnalyzer (Live Text) languages (30): …ja-JP…`、`ImageAnalyzer.isSupported = true`。
- `xcrun simctl shutdown 17620D58-…; xcrun simctl delete 17620D58-…` → `deleted=0`。`simctl list devices | grep -c rethink-tech` → `0`。

**JAPAN/MARC の集計**
- `python3 -I - …/biblio-alt-tech/dl-jm/jmo202639_confirmation.txt`（6 の D の値）。
- 先頭の出力：`records with 978-4 ISBN and publisher: 1655`、`distinct prefixes: 485 prefixes with a single publisher name: 457`、`… 1564/1655 (94.5%)`、`half/half split x5: prefix known in table 75.7%, publisher correct when known 91.9%`、`series == … 600/771 (77.8%)`。

**落としたもの**
- `curl … c_code_list.png` → `PNG image data, 737 x 1043`。目で読んだ（8 の表）。
- Apple の文書は developer.apple.com/tutorials/data/documentation/…json を Python で読んだ（8）。

**読んだリポジトリのファイル**
- docs/approvals/001-reading-session-G1-decisions.md
- docs/reviews/001-reading-session-biblio-alt-tech-lead.md、-biblio-alt-proposal.md、-reselect-tech-lead.md（1〜140行）、-apple-intelligence-tech-lead.md（Visual Intelligence の節）、-integrate-tech-lead.md（grep）
- docs/prd/001-reading-session.md（AC-1〜AC-3、AC-7、AC-17、AC-65〜AC-69、AC-77〜AC-79）
- design/001-reading-session.md（見出し、S-3 の行）
- 前回の spike の …/biblio-alt-tech/spike/main.swift と scripts/jm_size.py

## 8. 開いた URL と原文
- **https://developer.apple.com/videos/play/wwdc2021/10276/**（WebFetch。テキストをスキャン）
  - 「our UIAction works by invoking a new method on UIResponder objects called captureTextFromCamera」
  - 「The device should be an iPhone. And not just any iPhone, one with the machine learning super powers of the Neural Engine.」
  - 「users must have at least one of these seven supported languages in their list of preferred languages.」（iOS 15 のときの7言語。一覧はページの文に無い）
  - 「Before you add any camera launchers, you'll first want to check the result of canPerformAction withSender.」
  - 許可については、ページに書かれていない。
- **developer.apple.com/documentation/uikit/uiresponder/capturetextfromcamera(_:)**（JSON）
  - 「Starts scanning text using the device's camera.」iOS 15.0。
  - 「To determine whether the data scanner runs on the user's device, pass captureTextFromCamera(_:) to the canPerformAction(_:withSender:) method.」
- **…/visionkit/datascannerviewcontroller/issupported**：「For this property to be true, the device must have the A12 Bionic chip or later.」
- **…/visionkit/datascannerviewcontroller/supportedtextrecognitionlanguages**：「The identifiers for the languages that the data scanner recognizes.」iOS 16.0。
- **…/vision/recognizetextrequest/minimumtextheightfraction**
  - 「Increasing the size reduces memory consumption and expedites recognition with the tradeoff of ignoring text smaller than the minimum height. The default value is 1/32, or 0.03125.」
- **…/visionkit/vndocumentcameraviewcontroller**
  - 「An object that presents UI for a camera pass-through that helps people scan physical documents.」
  - 「The results of a scan include images, by page number.」
- **…/avfoundation/enhancing-your-app-experience-with-the-camera-control**
  - 「iPhone 16 devices provide a new hardware interface — the Camera Control — that enables direct interaction with the camera system. By default, iOS configures the Camera Control to launch and control the Camera app.」
  - 「The items this menu presents are instances of AVCaptureControl」
- **…/avfoundation/avcapturecontrol**（iOS 18.0）：「Capture controls provide the interface for interacting with the camera system from the Camera Control button on iPhone 16 devices.」
- **…/lockedcameracapture**（iOS 18.0）
  - 「Use the LockedCameraCapture framework to create an extension that allows people to launch your app's camera experience and capture content quickly when the device is locked. This extension makes your camera experience accessible to people from Control Center, the Lock Screen, or the Action button.」
- **https://www.apple.com/ios/feature-availability/**（WebFetch、2回）
  - Live Text の一覧に「Japanese」。
  - Visual Look Up の一覧に「Japanese」。
  - Visual Intelligence の「Add Event from Flyer or Poster」「Identify Places」「Plants and Animals」に「Japanese」。
  - 「Siri AI: Visual Intelligence」は「Available in English - Not available in China mainland or the European Union」。
- **https://isbn.jpo.or.jp/**（トップ）：リンク「分類記号(Cコード)一覧」、「ISBN(国際標準図書番号)および日本図書コード・書籍JANコード利用の手引き2025年版」。
- **https://isbn.jpo.or.jp/index.php/fix__about/fix__about_13/**：「日本図書コードの分類記号（Cコード）の1桁目から4桁目のコードを下記一覧表より作成してください。」。表は画像。
- **https://isbn.jpo.or.jp/wordpress/wp-content/themes/isbn-jpo/assets/images/fix__about/c_code_list.png**（目で読んだ）
  - 1桁目の販売対象：0 一般、1 教養、2 実用、3 専門、4 検定教科書・消費税非課税品、5 女性、6 学参I、7 学参II、8 児童、9 雑誌扱いコミックスおよびムック。
  - 2桁目の発行形態：0 単行本、1 文庫、2 新書、3 全集・双書、4 ムック・その他、5 辞典・事典、6 図鑑、7 絵本、8 磁性媒体など、9 コミックス。
  - 内容の 9 文学：90 文学総記、91 日本文学総記、92 日本文学詩歌、93 日本文学小説物語、95 日本文学評論随筆その他、97 外国文学小説、98 外国文学その他。
- **https://isbn.jpo.or.jp/doc/ISBN_jp2025.pdf**：落とせたが、暗号化されていて読めなかった。「192」と出版者記号の桁の決まりは未確認。
- **WebSearch**（日本図書コードの C コード。開いたのは上の公式ページだけ）
  - 結果の要約に、infosta.or.jp の PDF の「「日本図書コード」は，ISBN のほかに分類コードおよび本体価格（消費税を含まない）を加えたセットで，「書籍 JAN コード」はこのセットをバーコードにしたもの」があった（PDF そのものは開いていない）。
  - 結果の URL：https://www.choge-blog.com/%E9%9B%91%E5%AD%A6/ccode/ 、https://www.infosta.or.jp/journal/rensai2/rensaikoramu03.pdf
- **WebSearch**（柱の慣習）：日本の柱の慣習の出典は見つからなかった。英語の組版の解説に、小説は通読されるので柱の必要が小さい、という趣旨があった（https://www.firstwriter.com/layout/running_heads_feet.shtml 。開いていない）。ノンブルの位置は https://art-design-glossary.musabi.ac.jp/?p=686 （開いていない）。

## 未解決
- **本物の写真での精度**：すべての部品で未確認です。合成で、規則も同じ画像で書いたので上ぶれします。7 の手順で確かめられます。
- **iPhone での速さとメモリ**：最初の1回、1枚あたり、24〜48MP の写真を縮める処理は未測定です。先に温める手当てが効くかも未確認です。
- **確かめられなかった iOS の機能**
  - DataScanner のライブで縦書きの日本語が読めるか（実機が要ります）。
  - テキストをスキャンの許可、日本語、縦書き、SwiftUI から使う形。
  - ImageAnalysisInteraction で縦書きを選べるか。
- **背表紙を本ごとにまとめる規則**：傾いた写真で 0/50 です。背の縁を見つける処理か、「書名を押す」設計が要ります。
- **2段目のバーコード**：ない本の割合、先頭の「192」の正式な意味、同じ画面に2冊あるときの組み方。
- **出版者記号の桁の決まり**（2桁 00〜19、3桁 200〜699、4桁 7000〜8499、5桁 85000〜89999、6桁 900000〜949999、7桁 9500000〜9999999）は私の覚えです［推測］。データとは矛盾しませんでした。国際 ISBN 機関の範囲の表で確かめる必要があります。
- **種の表の出どころ**
  - NDL のデータから作るなら、出典の記載と加工したことの記載が要ります（前回の quickguide の文）。申請は要りません。
  - 手で作る場合（事実の一覧）と比べてどちらにするか、法的な不安の残り方は［推測］です。Takuma の判断です。
- **柱の慣習**：どの本に書名の柱があるか、柱のない本の割合は［推測］です。
- **カメラコントロールのある機種**：iPhone 16 より後の機種の一覧は［推測］です。
- **Visual Intelligence**：日本語の環境でアプリの結果が出るかは未確認です。
- **シミュレーターの異常**：0.5倍の棚の画像で、最小の字の高さが既定のとき、書名が 1/180 になりました。Mac は 152/180 です。設定は必ず明示し、iPhone で確かめます。
- **見積もり**：すべて［推測］です。PRD の直しのあと、G2 のあとの測り直しで確かめます。
- **この推奨は私の判断です**：決める前に、reviewer に反論を出してもらってください。

## 記録（指揮役が保存するときに書き足す）
- 種類：調べものと spike（tech-lead）
- 日付：2026-10-20
- spike の産物はリポジトリの外（scratchpad の rethink-tech/）。合成の画像と JAPAN/MARC の集計はリポジトリに入れない
