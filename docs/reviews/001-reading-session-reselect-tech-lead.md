（指揮役の注）これは判定ではなく、課題の選び直しのための調べもの（tech-lead）の報告。指揮役の仮説「本棚にカメラを向けると今夜の1冊が光る」の技術の危険を調べた。報告の文はそのまま保存した。

# 課題の選び直し その4：本棚をカメラで読み取り、今夜の1冊を選ぶ技術（tech-lead の調べもの。BASE=9b91ec5）

判定の前の調べものなので、PASS や FAIL は付けていません。リポジトリの中のファイルは書いていません。spike は1つだけです（Mac の Vision と Foundation Models を使い、リポジトリの外で手数は約7回）。根拠はすべて 2026-10-16 に開きました。自分の見立てには［推測］、確かめていないものには「未検証」と付けています。

## 結論
- **iOS だけで作れます。サーバーと外部の API は、最初の形では要りません。** 月の費用は1,000人あたり0ドルです。
- **前回の見立てが1つ変わりました。縦書きの背表紙は、向きを変えずに読めました。**
  - 合成の棚の写真で、macOS 27 の Vision は、縦書きの日本語の背表紙を 8/8、90度回った英語の背表紙を 6/6 読みました。
  - iOS 26 で、読む向きの値に `topToBottom`（上から下）が足されています。
  - 前回の「縦書きは横書きに直してから読む必要がありそう」は、iOS 18 のころ（2025年1月）の DTS の回答が根拠でした。新しい OS の文書と spike の結果を理由に改めます。
  - ただし、確かめたのは合成の画像と Mac だけです。本物の棚の写真と iPhone では未検証です。
- **いちばん大きい危険は、本物の棚で読み取れる割合です。** 光る表紙、飾った字体、帯、暗さ、斜めからの写真が当たります。いちばん安い確かめ方は、Takuma の本棚の写真を5〜10枚もらい、今回の Mac のプログラムで読ませることです（半日）。
- **今夜の1冊を「選ぶ」のは、ルールを主にすることを推します。** Foundation Models は候補の中から選ぶことはできました。ただし、本の中身については作り話をしました。写真から背表紙を読む力も、Vision よりはっきり劣りました。
- **本を見分けるのに ISBN は要りません。** 読み取った題名と著者で、利用者が自分で登録した積読の一覧と照らします（候補の決まった照合）。書誌の API は、表紙やページ数がほしいときだけの任意にします。

## 前回までの調べものとの関係
| 項目 | 前回 | 今回 | 変える理由 |
|---|---|---|---|
| Vision の縦書き | 向きを変える必要がありそう（angles の②、DTS 772972、2025-01） | **背表紙のような短い1列なら、そのまま読めた（合成、macOS 27）** | iOS 26.0 で `RecognizedTextObservation.Direction.topToBottom` が足された。spike で 8/8 読めた。ルビ付きの本文のページは今回も未検証のまま |
| 伏せた向き | UIDevice の faceDown。許可なし（flip-research の 1） | 変えない | - |
| 画面の向きのロックがオンでも faceDown が届くか | 未検証（Q-A。方向が変わり、実機での確かめは止まった） | **未検証のまま。伏せて始める形を使うなら、また要る** | - |
| 時刻の方針 1-b | 保存した開始の時刻から数える | 変えない | - |
| 許可0回（001 の AC-24） | 伏せる道を含めて0回 | **カメラで1回になる。** 写真から選ぶ道（PhotosPicker）だけなら0回 | カメラを使うため |

## 1. 背表紙の読み取り
### spike の結果（Mac の Vision。Xcode 27.0、macOS 27.0.1、RecognizeTextRequest の revision3、言語は ja と en、accurate）
合成の画像は、Core Text の縦組みで描いた日本の文庫8冊と、90度回した英語の本6冊です。目で見て、縦書きで描けていることを確かめました（shelf_mix_hard.png）。

| 画像 | 向きの指定 up | right | left |
|---|---|---|---|
| 日本語の縦書き8冊（644×1060） | **8/8** | 8/8 | 8/8 |
| 英語の回った背表紙6冊 | **6/6** | 6/6 | 6/6 |
| 混ぜた14冊（1124×1060） | **14/14** | 14/14 | 14/14 |
| 0.4倍に縮めた（背の幅は約27px、題名の字は約16px） | 13/14（1冊は LCS 0.94） | 12/14 | 13/14 |
| 暗く（−1.8EV）、ぼかし、遠近で7%、4度回し、0.55倍 | **14/14** | 13/14 | 11/14（人間失格 0.50、ハーモニー 0.20、火花 0.00） |
| 1冊ずつ切り出し | 14/14 | 14/14 | 13/14 |
| RecognizeDocumentsRequest（iOS 26 から） | 日本語 8/8。向きはすべて `topToBottom`。混ぜた14冊では 14/14（`topToBottom` 12行、`leftToRight` 30行） | 14/14 | - |

- 数字は「題名がそのまま含まれた冊数」です。LCS は、題名の字のうち順に読めた割合です。
- 時間：初回だけ 22.69秒、2回目からは画像1枚 0.25〜0.36秒でした（Mac）。iPhone での時間は未計測です。初回の遅さへの手当て（起動のときに先に1回動かす）が要る見込みです［推測］。
- 向きの指定は、写真の本当の向き（up）を渡すのがいちばん安定しました。間違った向きを渡すと、劣化した画像では落ちます。
- 横に積んだ「積読の山」は、棚の写真を90度回した形になります。合成の画像では、その形（right と left）でも 8/8 読めました。

### 合成の画像の限界
- 字体はシステムのもので、地は単色、ピントは完全です。光る表紙、箔押し、飾った字体、帯、背の丸み、強い斜め（20〜30度）、暗い所の粒状のノイズは入っていません。
- 本物の写真での精度は**未検証**です。

### VisionKit の DataScannerViewController（ライブの映像）
- 「An object that scans the camera live video for text, data in text, and machine-readable codes.」（iOS 16.0 から）
- 位置は四隅で取れます。RecognizedItem.Bounds：「An object that represents the four corners of a recognized item.」
- 映像の中で動きを追えます：「you can track items that appear in the live video using the asynchronous recognizedItems array.」
- 縦書きの日本語を DataScanner で読めるかは**未検証**です。Mac では動かないので、実機でしか確かめられません。

### バーコード（ISBN）の逃げ道
- Vision の DetectBarcodesRequest は、合成の EAN-13 を2本とも読みました。20度回し、暗く、ぼかし、0.6倍（1本の線の幅が約1.8px）でも読めました。0.3倍（約0.9px）では0本でした。
- **日本の本の裏には、バーコードが2段あります。** 上が ISBN（978 で始まる）、下が分類と値段（192 で始まる）です。Vision は2本とも返したので（`[1920193006001, 9784101006055]`）、978 と 979 で始まるものだけを使う処理が要ります。2段の決まりそのものは、公式の文書では確かめていません。
- DataScanner では `barcode(symbologies:)`（iOS 16.0 から）で読めます。
- 弱み：本を1冊ずつ棚から出して裏返すことになります。「棚にかざす」体験にはなりません。登録のときの確かな道として使います。

## 2. 読み取った文字から本を見分ける
**推す形：候補の決まった照合。** 利用者の積読の一覧（数十冊）に、読み取った題名と著者を似ている度合いで照らします。端末の中だけで済み、通信は要りません。一覧の作り方は次の2つです。
- 棚を撮る。読み取った題名の候補を、利用者が確かめて残す。
- バーコードで1冊ずつ足す。

「今夜の1冊」を選ぶのに、版や ISBN は要りません。外部の API は、表紙やページ数を出したいときの任意にします。

| API | 題名で探せるか | 鍵 | 無料か、使える条件 | 表紙の画像 | 実際に呼んだ結果 |
|---|---|---|---|---|---|
| openBD | **ISBN だけ**（`/get?isbn=`） | 要らない | 「利用者は、APIを本を紹介する目的に無償で利用することができます。」「本の販促・紹介目的に限り使用できます。」「任意に改変してはいけません。」「中断なく稼動することなど如何なる保証も致しません。」 | 書影はある。削除の求めにはすぐ従う決まり | HTTP 200。人間失格、新潮社。`cover` は空だった |
| 国立国会図書館サーチ（OpenSearch など） | **できる**（title、creator、any） | 要らない（ページに鍵の記載なし） | 個人や非営利で「収益を得ない場合は…利用申請は不要」。「何らかの経済的な対価を受け取っている場合は営利目的にあたり、利用申請が必要」。広告の収入も営利の例 | サムネイルの URL は curl で 403。条件は未確認 | 題名と著者で345件。上位5件は別の版や全集だった。読み取った文字そのまま（any）では4件で、正しい本は3番目 |
| Google Books | できる（`intitle:`、`isbn:`） | **要る**：「must send an API key」 | 「You may not charge users for your application without a separate agreement or written permission from Google.」 | 表示の決まり：「the "powered by Google" logo must appear adjacent to these results」、本ごとに Google Books のページへのリンク | 鍵なしは HTTP 429（共用の1日の枠が尽きていた） |
| 楽天ブックス | できる（title、isbn） | **applicationId と accessKey の両方が必須** | クレジットが必須：「Giving credit with a badge is required for all apps that use the Rakuten API.」 | 200×200 まで | 呼んでいない（鍵がない） |

- **バックエンド**
  - 国立国会図書館サーチと openBD なら要りません。
  - 楽天の accessKey を隠す必要があるかは未確認です。隠すなら中継のサーバーが要り、stacks の変更になります（Takuma が決める）。
  - Google Books は、有料のアプリで使うと別の合意が要り、表示の決まりも重いので推しません。
- **収益化との関係**：有料にすると、国立国会図書館サーチは利用申請が要ります。PRD の 16 に効きます。

## 3. 今夜の1冊を選ぶ AI（Foundation Models）
- **使える範囲**
  - iOS 26.0 から使えます。文書は「To use Apple Foundation Models, people need a device that supports Apple Intelligence.」としています。
  - 機種は、Apple のサポートの記事によると「iPhone 16 models or later, iPhone 15 Pro, iPhone 15 Pro Max, iPhone Air」です（iOS 27 の記事。WebFetch で読みました）。
  - 言語の一覧に Japanese があります。中国本土で買った端末では動きません。
  - 使えない理由は `appleIntelligenceNotEnabled`、`deviceNotEligible`、`modelNotReady` の3つです。対応しない機種の人には、ルールで同じことができる必要があります。
- **大きさ**：「context window of 4096 tokens per LanguageModelSession」「For multi-byte languages like Chinese, Japanese, and Korean, it is roughly one character per token.」。50冊の題名なら足ります。
- **spike の結果（この Mac。availability は available、ja_JP にも対応）**

| 試したこと | 結果 |
|---|---|
| 14冊の候補と気分（疲れている、20分、重くない）から1冊を選ばせる（greedy で1回、ふつうに3回） | 4回とも候補の中から選んだ。4回とも同じ『コンビニ人間』で、1回1.5〜2.3秒。理由は「軽めの内容」などで、題名からの印象で書いていて、中身を知っている根拠はない［私の判断］ |
| 架空の本『夜の図書館と七つの鍵』の内容を聞く | **作り話をした**（「図書館で起こる奇妙な出来事を描いた推理小説」） |
| 『ハーモニー』（伊藤計劃）の内容を聞く | 「記憶を管理するシステム」と答えた。実際の筋（医療で管理された社会）とずれている［私の知識での判断］ |
| 写真から背表紙を読ませる（iOS 27 から画像を入力にできる） | 日本語の棚は 7/8（ハーモニーを「ハーモニクス」と読んだ）。英語は 5/6。劣化した混ぜた棚では、英語の題名を日本語に訳し、崩した（「原子の習慣」「深遠な仕事」「コンビネーション」「ハーパーノワール」など）。**読み取りには使えない** |

- 文書も、得意でない仕事として「Do basic math」「Perform logical reasoning」を挙げ、拒むことがあるとも書いています：「A model can freely refuse to respond to an input.」
- Private Cloud Compute（iOS 27）は、32K の大きさと強い推論があります。ただし、通信が要り、1人あたり1日の上限があり、管理された entitlement の申請と資格の条件があります。「端末の中」とは言えないので推しません。
- **推す形**
  - 選ぶのはルールにします。例：利用者が選ぶ気分の札、ページ数、最後に触った日、利用者が付けた印。結果が決まった形になるので、テストもできます。
  - Foundation Models は、対応機種で「理由の1文」を作る飾りにだけ使います。渡すのは利用者が入れた事実だけで、本の中身は言わせません。
  - 「AI は端末の中」は、Vision（端末の中の機械学習）で言えます。

## 4. 1冊を「光らせる」見せ方
| 案 | 作りやすさ | 見た目 | テスト | 判定 |
|---|---|---|---|---|
| (a) 撮った写真を止めて、Vision の四隅の枠に光を重ねる（SwiftUI の Canvas とぼかし） | いちばん易しい | 静かで安定する | 決まった写真を差し込めば、シミュレーターで試せる見込み［推測］ | **v1 に推す** |
| (b) DataScanner のライブの映像に光を重ねる | 中くらい。`overlayContainerView`：「add custom highlights to this view」。標準の枠は `isHighlightingEnabled`（既定は false） | 本を追って光が動く。10秒で伝わる | 実機だけ | 縦書きを読めると実機で確かめられたら、v1.5 |
| (c) AVCaptureSession と1コマごとの Vision | 枠の変換（`layerRectConverted`）、ぶれの手当てを自分で作る | (b) と同じ | 実機だけ | (b) がだめなときの代わり |
| (d) ARKit と RealityKit（`ARFrame.capturedImage` に Vision をかけ、縦の面に固定する） | いちばん重い。棚の面の検出も要る | 3次元で本に貼り付き、いちばん映える | 実機だけ | 後の版 |

## 5. 許可と審査
- **カメラ**
  - 「This key is required if your app uses APIs that access the device's camera.」（NSCameraUsageDescription）
  - DataScanner では「a person must agree when the system dialog first appears」です。
  - 写真から選ぶ道は許可が要りません（前回引いた PhotosPicker の文）。カメラを断られたときの道にします。
  - スクリーンタイムの制限でもカメラが使えなくなります：「may be false if a person has Screen Time restrictions」（isAvailable）。
- **通信**：外へのふつうの通信に許可のダイアログはありません［今回は文書を開いていない］。
- **申告**
  - 読み取りと選ぶ処理が端末の中だけなら、「収集」に当たりません（前回引いた「Data that is processed only on device is not "collected"」）。
  - 題名や ISBN を外部の API に送るときに申告が要るかは未確認です。G5 で決めます。v1 では送らない形を推します。
- **審査で気をつけること**
  - カメラの使用中の表示（2.5.14）：プレビューを出していれば満たす見込みです［推測］。
  - 表紙の画像：出すなら、各 API の表示の決まりがかかります（Google のロゴとリンク、楽天のバッジ、openBD の目的の制限と削除の求め）。

## 6. 2週間で作れるか
- **作れる見込みです［推測］。** 範囲は次のとおりです。
  1. 撮る、または写真を選ぶ。
  2. Vision で読み、背表紙ごとにまとめる。
  3. 一覧と照らす。
  4. ルールで1冊を選び、止めた写真の上で光らせる。
  5. 伏せて始める（001 の作りを使い回す）。
  6. 短い回で終える。
  - バーコードでの登録も入れます。外部の API、Foundation Models、ライブの光は入れません。
- **背表紙ごとにまとめる処理が必要です。** Vision は、題名、著者、出版社を別々の行で返しました（14冊で42行）。横の位置が重なる行を1冊にまとめるルールが要ります。
- **いちばん大きい危険**：本物の棚の写真での読み取りの割合と、背表紙ごとのまとめ方です。
- **いちばん安い確かめ方**
  1. Takuma が、文庫の棚、混ざった棚、積読の山、暗い所、斜めから、を合わせて5〜10枚撮ります。
  2. 今回のプログラムを写真を受け取る形に直して（数行）、題名が読めた割合を出します。正解の題名は手で打ちます。半日です。
  3. 合格の線は pdm が決めます。例：ふつうの明るさで7割以上［推測］。
- **次に安い確かめ方**：実機で15分です。DataScanner で縦書きの背表紙を読めるかを見ます。試作は tech-lead が作ります（手数10回ほど［推測］）。

## 7. 課題4と課題1の技術の壁
- **大きな壁は「なし」です。**
  - 課題4：読むのは紙の本で、スマホは伏せるので、長い文章をスマホで出す技術は要りません。スマホで出す場合も、縦書きの表示は前回の spike で解けています。
  - 課題1：短い回、通知（許可は1回）、ウィジェットで足ります。
- **条件付きの壁が2つあります。**
  - ほかのアプリを止めるなら、Family Controls の entitlement に Apple の承認が要ります（angles の①）。
  - 読んだページを撮って自動で数えるなら、ルビ付きの縦書きの本文の読み取りが要ります。今回の背表紙より難しく、未検証です。

## 質問（指揮役から Takuma へ）
- **Q1：本棚の写真5〜10枚で、読み取りの確かめをしますか。**
  - 推奨：する。いちばん大きい危険を、半日で消せます。
  - いちばん強い反論：撮影の手間がかかる。手元の本の題名が写真に写る。写真はリポジトリの外で扱い、終わったら消します。
  - 元に戻せるか：戻せる。
  - 見てほしいもの：この報告の 1 と 6。
- **Q2：v1 で外部の書誌の API を使いますか。**
  - 推奨：使わない。一覧との照合とバーコードで足ります。
  - いちばん強い反論：表紙の画像がないと、画面が地味になる。
  - 元に戻せるか：戻せる。あとから国立国会図書館サーチや openBD を足せます。有料にするなら、国立国会図書館サーチは利用申請が要ります。
- **Q3：今夜の1冊は、ルールで選びますか。**
  - 推奨：ルールで選ぶ。Foundation Models は、対応機種で理由の1文だけにし、本の中身は言わせない。
  - いちばん強い反論：「AI が選ぶ」という見出しが弱くなる。
  - 元に戻せるか：戻せる。
- この見立ての大きな判断（縦書きの見直し、候補の決まった照合、ルールを主にすること、止めた写真で光らせること）は私の判断です。決める前に、reviewer に反論を出してもらってください。

## 根拠（開いた日はすべて 2026-10-16）
Apple の開発者の文書は、developer.apple.com/tutorials/data/documentation/<パス>.json の JSON で本文を読みました。
- VisionKit
  - https://developer.apple.com/documentation/visionkit/datascannerviewcontroller （上に引いた3つの文。iOS 16.0 から）
  - …/datascannerviewcontroller/overlaycontainerview 、…/ishighlightingenabled 、…/isavailable 、…/capturephoto() （「Captures a high-resolution photo of the camera's live video.」）、…/qualitylevel-swift.enum （「The quality levels mostly impact the camera resolution.」）、…/recognizeddatatype/barcode(symbologies:)
  - https://developer.apple.com/documentation/visionkit/recognizeditem/bounds-swift.struct
- Vision
  - https://developer.apple.com/documentation/vision/recognizedtextobservation/direction （iOS 26.0 から。「An enum representing which direction the text is read.」。leftToRight、rightToLeft、topToBottom）
  - https://developer.apple.com/documentation/vision/recognizetextrequest （iOS 18.0 から。revision は revision3 だけ）
  - https://developer.apple.com/documentation/vision/recognizedocumentsrequest （iOS 26.0 から）
  - https://developer.apple.com/documentation/vision/detectbarcodesrequest
- Foundation Models
  - https://developer.apple.com/documentation/foundationmodels （機種の文と、「When you need more reasoning capabilities and context size, use Private Cloud Compute」）
  - https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel （「Model availability depends on whether the device and region supports Apple Intelligence.」。モデルの版は 26.0〜26.3、26.4、27.0 の3つ）
  - …/systemlanguagemodel/availability-swift.enum/unavailablereason
  - …/generating-content-and-performing-tasks-with-foundation-models （「Capabilities to avoid」の表）
  - …/improving-the-safety-of-generative-model-output （拒む文）
  - …/supporting-languages-and-locales-with-foundation-models
  - https://developer.apple.com/documentation/technotes/tn3193-managing-the-on-device-foundation-model-s-context-window
  - …/analyzing-images-with-multimodal-prompting 、…/imageattachmentcontent （iOS 27.0 から）、https://developer.apple.com/documentation/updates/foundationmodels （June 2026 の項目）
  - …/privatecloudcomputelanguagemodel 、…/adding-server-side-intelligence-with-private-cloud-compute （「32K-token context size」「daily request limit」）、https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.private-cloud-compute
- Apple Intelligence：https://support.apple.com/en-us/121115 （WebFetch。機種、言語、中国本土の文）
- 光らせる：https://developer.apple.com/documentation/arkit/arframe/capturedimage 、https://developer.apple.com/documentation/avfoundation/avcapturevideopreviewlayer/layerrectconverted(frommetadataoutputrect:) 。arkit/arsession/raycast(_:) は取れましたが、本文は読んでいません。
- 許可：https://developer.apple.com/documentation/bundleresources/information-property-list/nscamerausagedescription
- 書誌の API
  - https://openbd.jp/ と https://openbd.jp/terms/ （WebFetch）
  - https://ndlsearch.ndl.go.jp/help/api （WebFetch と curl。上に引いた文）
  - https://developers.google.com/books/docs/v1/using 、https://developers.google.com/books/terms 、https://developers.google.com/books/branding （WebFetch）
  - https://webservice.rakuten.co.jp/documentation/books-book-search 、https://webservice.rakuten.co.jp/guide/credit （WebFetch）
- 前回の調べもの（読み直しただけ）：docs/reviews/001-reading-session-angles-tech-lead.md、docs/reviews/001-reading-session-validate-tech-lead.md、docs/reviews/001-reading-session-G0-tech-lead-flip-research.md、docs/approvals/001-reading-session-G0-Q8.md

## 変更したファイル
- リポジトリの中：なし。
- リポジトリの外（どれも消してかまいません）
  - spike のプログラム：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/shelf7/spike/shelf/main.swift、/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/shelf7/spike/fm/main.swift
  - ビルドしたもの：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/shelf7/bin/shelfspike、/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/shelf7/bin/fmspike
  - 合成の画像：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/shelf7/out/（shelf_jp.png、shelf_en.png、shelf_mix.png、shelf_mix_small.png、shelf_mix_hard.png、barcode.png、barcode_hard.png）
  - API の応答：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/shelf7/api/
  - 文書：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/shelf7/dl、/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/shelf7/txt

## 実行したコマンドと結果
- `git rev-parse HEAD` → `9b91ec57d4819344440631429cf413e5effd3d4d`
- `xcodebuild -version` → `Xcode 27.0 / 27A266a`。`sw_vers` → macOS 27.0.1。`swift --version` → Swift 6.4
- 文書の取り込み（前回の fetch_docs.sh）：48件
  - 404 は `vision/imageprocessingrequest/perform(on:orientation:)` の1件です。
  - arkit の raycast はファイル名を取り違えて、本文を読んでいません。
- `swiftc -O -swift-version 5 main.swift`（2つとも）→ エラー0でビルドできました。
- `shelfspike` の出力は「1」の表のとおりです。合わせて 59.97秒でした。
  - `RecognizeTextRequest revision=revision3 supports ja? true`
  - `BARCODE clean: [1920193006001, 9784101006055]`
  - `BARCODE rot20deg_dark_blur_scale0.6: [1920193006001, 9784101006055]`
  - `BARCODE scale0.3: []`
- `fmspike` の出力は「3」の表のとおりです。合わせて 31.52秒でした。
  - `FM availability: available`
  - `FM supportsLocale(ja_JP): true`
- curl
  - openBD：HTTP 200
  - 国立国会図書館サーチの OpenSearch：HTTP 200（345件と4件）
  - 国立国会図書館サーチのサムネイル：HTTP 403
  - Google Books（鍵なし）：HTTP 429
- ガードに1回止められました（書き先と cd の行き先に `$` があったため）。回り道はせず、書き先をすべてそのままのパスで書いて、実行し直しました。
- WebFetch は8回です（Apple Intelligence、openBD の2ページ、国立国会図書館サーチ、Google の3ページ、楽天の2ページ）。WebSearch は0回です。

## 未検証
1. 本物の棚の写真での読み取りの割合（光る表紙、飾った字体、帯、強い斜め、暗い所のノイズ）。いちばん大きい危険です。Q1 で確かめます。
2. iPhone（iOS 27）の Vision が、Mac と同じ結果を出すか。初回と2回目の時間とメモリ。
3. DataScanner で縦書きの日本語の背表紙を読めるか。ライブで追う枠のぶれ。
4. 背表紙ごとにまとめるルールの精度（本が傾いている、隣と接している）。
5. ルビ付きの縦書きの本文のページの読み取り（前回からの持ち越し。今回は背表紙だけ）。
6. Foundation Models の結果は Mac で確かめました。iPhone でも同じ版のモデル（27.0）になるはずですが、確かめていません。シミュレーターで動くかも未検証です。
7. 楽天の accessKey を隠す必要があるか。国立国会図書館サーチのサムネイルを使う条件。openBD の「販促・紹介目的」に読書アプリの表示が入るか（openBD に聞く必要がある）。
8. 題名や ISBN を外部の API に送るときの、App Privacy の申告の要否。
9. 日本の本の2段のバーコード（978 と 192）の決まりの公式の出典。
10. 画面の向きのロックがオンのときに faceDown が届くか（001 からの持ち越し）。
11. Vision がシミュレーターで動き、受け入れテストに写真を差し込めるか［推測］。
12. 2週間の見積もり（spike は読み取りの部分だけ。ほかは［推測］）。

## git status --short
最後に `cd /Users/takumamatsuura/reading-app && git status --short` を実行しました。出力は空でした（変更なし）。

## 記録（指揮役が保存するときに書き足す）
- 種類：課題の選び直しのための調べもの（tech-lead）。PASS / FAIL なし
- 対象：指揮役の仮説「本棚にカメラを向けると、背表紙を読み取り、今夜の1冊が光る（AI は端末の中）。伏せると読み始める」。BASE=9b91ec57d4819344440631429cf413e5effd3d4d
- 日付：2026-10-16
