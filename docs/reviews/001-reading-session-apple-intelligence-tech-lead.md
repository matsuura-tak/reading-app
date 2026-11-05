（指揮役の注）これは判定ではなく、Takuma の「apple インテリジェンスとか上手いこと使えないのかな」を受けた調べもの（tech-lead）の報告。担当は、Apple Intelligence を文を作らせない形で使う道が作れるか（Visual Intelligence、App Intents と Siri とショートカットと Spotlight と Controls、読み終えのふりかえりの spike、Image Playground、PCC、課金との関係）。報告の文はそのまま保存した。

# Apple Intelligence を「文を作らせない形」で使う道（tech-lead の調べもの）
- 書いた役：tech-lead　日付：2026-10-18　リポジトリのファイルは書いていません。

## 結論
1. 安くて効くのは、Apple Intelligence そのものより、その土台の App Intents です。「読み始める」（LiveActivityIntent。Controls、Action ボタン、ロック画面から、アプリを開かずに始める）とショートカット（「続きを読む」「どこまで読んだ？」）は、全機種で動き、作り話も出ません。Live Activity を v1.0 で作るなら、足す手間は S〜M です。v1.0 に入れる候補にしてよいのはここだけです（入れるかは速さを測ってから決めます）。
2. Visual Intelligence との統合は作れます（iOS 26 の IntentValueQuery）。ただしアプリに渡るのは、写した画像と英語の一般的なラベルだけです。本の照合（ISBN のバーコード、表紙の書名の読み取り）はアプリが Vision で行います。負担は M、対応機種だけで動き、日本語の環境でアプリの結果が出るかは未検証です。v1.1 の候補とします。
3. 読み終えのふりかえりを Foundation Models に言わせる形は、spike で使える文が自由文 0/10、差し込み形 0/10 でした。差し込み形では数字の誤りを0にできましたが、文が崩れ、10回中3回は文を出し続けて上限で落ちました。AI を使わず、アプリの決まった文の型で書く方がよいです（全機種、S）。
4. Image Playground（v1.1 の候補。「静か」との相性は弱い）と PCC（資格と entitlement が要る。通信が要り、使える量に上限があり、将来は有料。あらすじの品質が上がる証拠はない。v1.2 以降）は急ぎません。Siri AI の個人の文脈は、2026-10-18 の時点で英語だけです。
5. 課金：Apple Intelligence の機能そのものに値段を付けると、4.10 に当たるおそれが高いです［推測］。AI を使う部分は無料の側に置き（裁定 13 と同じ線）、有料は全機種で使える見た目だけにすることを推奨します。

## 判定の表
負担の目安は、S が1日以内、M が2〜5日、L が6日以上です（人の速さの見積もり［推測］。AI の役の速さはまだ測っていません）。

| 候補 | 判定 | 負担 | v1.0 か v1.1 か | 作り話の危険 | 対応機種 |
|---|---|---|---|---|---|
| 1 Visual Intelligence（本を写すと「p.61 から」か「積読に加える」） | 条件付き | M | v1.1 の候補 | 文は作らないのでなし。別の本と取り違える危険はある | Apple Intelligence の iPhone と iOS 26 以上。日本語の環境でアプリの結果が出るかは未検証 |
| 2a 読み始める（Controls、Action ボタン、ロック画面、Live Activity のボタン） | できる | S〜M（Live Activity があれば S） | v1.0 の候補 | なし（アプリの記録だけ） | 全機種（control は iOS 18 以上。Action ボタンはボタンがある機種だけ） |
| 2b ショートカットと Siri（「続きを読む」「どこまで読んだ？」） | できる | S | v1.0 の候補。あふれたら v1.1 の先頭 | なし（答えはアプリの文の型） | 全機種（iOS 16 以上） |
| 2c Spotlight で本を探す | できる | S（BookEntity が先にあれば） | v1.1（2a、2b のあと） | なし | 全機種（iOS 18 以上）。意味で探す部分は対応機種だけかもしれない［推測］ |
| 2d Siri AI の個人の文脈（自由な言い方で聞く） | 条件付き（日本語を待つ） | S（2b、2c の上に乗る） | v1.1 以降 | 低〜中（答えの文は Apple のモデルが作る。未検証） | 対応機種、iOS 27、Siri AI の日本語（2026-10-18 は英語のみ） |
| 3 読み終えのふりかえり（Foundation Models） | 難しい | M | 入れない。AI なしの文の型なら S で、読み終えのカードと同じ版に入れる | 高い（spike で 0/10） | 対応機種だけ（AI なしの型は全機種） |
| 4 Image Playground（カードの背景） | 条件付き | S〜M | v1.1 の候補（カード自体が v1.1 に回る順の (3)） | 事実は作らない。絵が本の表紙と誤解される危険は低い | 対応機種だけ。iOS 27 ではサーバーのモデルを使い、1日の上限の対象 |
| 5 PCC（前回のあらすじの品質を上げる道） | 条件付き（資格が要る） | L | v1.2 以降 | 中〜高（未検証。前回は36件中22件に誤り） | 対応機種、iOS 27、通信が要る |
| 6 課金との関係 | AI の部分は無料の側に置くのを推奨 | ー | ー | ー | ー |

全機種で動く部分と、対応機種だけで動く部分
- 全機種：App Shortcuts（Siri の決まった言い方、ショートカット、Spotlight の行）、Controls（コントロールセンター、ロック画面）、Action ボタン（ボタンがある機種）、LiveActivityIntent、IndexedEntity による Spotlight、AI を使わないふりかえりの文の型。
- 対応機種だけ：Visual Intelligence、Siri AI（iOS 27）、Foundation Models、Image Playground、PCC。

## 1. Visual Intelligence との統合
- 仕組み
  - IntentValueQuery を1つ作り、values(for: SemanticContentDescriptor) で受けます。「Your app can't contain more than one IntentValueQuery that takes a SemanticContentDescriptor」と書かれています。
  - 返すのは AppEntity の配列です。本棚の本と「積読に加える」の候補を混ぜるときは @UnionValue を使います。
  - 結果を押したときに開くのは OpenIntent です。「その他の結果」をアプリで見せるには、semanticContentSearch の schema に合わせた intent を作ります。
  - 出典：Integrating your app with visual intelligence。
- アプリに渡るもの
  - labels と pixelBuffer（写した画像）だけです。
  - labels については「Labels are general, high-level terms in the en_US locale … It won't provide the building's actual name as a label」とあります。書名は渡りません。
  - 読み取った文字も渡りません。照合はアプリが自分で行い、文書の例では画像検索をしています。
  - 「Returning results quickly makes for a good search experience」とあります。時間の上限の数字は書かれていません（未検証）。
- 写った本を本棚の本と照らす方法
  - バーコード：裏表紙の ISBN（978 か 979 で始まる EAN-13）を DetectBarcodesRequest で読み、ISBN で本棚を引きます。一致は確実です。前の Mac の spike では、合成した EAN-13 を、回したり暗くしたりぼかしたりしても読めました（docs/reviews/001-reading-session-validate-tech-lead.md の57行）。ただし表紙の側にはバーコードがありません。
  - 表紙：RecognizeTextRequest（revision3 は ja に対応。同じレビューの216行）で書名を読み、正規化して本棚の書名と比べます。崩した字体の表紙でどこまで読めるかは未検証です。
  - 背表紙：縦書きで字が小さく、何冊も写ります。読めるかは未検証で、確かめ1 と同じ課題です。
  - 表紙の絵どうしを比べる方法は、アプリが書影を持たず（E-11）、写真も残さない（AC-69）ので、今の設計では使えません。
- 出す答え（設計の案［推測］）
  - 本棚にある本：題に書名、副題に「p.61 から」を出します。続きの一行を出すかは AC-34 の「隠す」設定に従います。
  - 本棚にない本：「積読に加える」の entity を返します。押すとアプリの登録画面が開き、ISBN か読み取った書名が入った状態にします。国立国会図書館の検索はアプリの中で行い、照合の中では通信しません。
  - 自信のない一致では「p.」を出さず、「よむまで探す」に回します（別の本の続きを出すと信頼を失うため）。
- 対応機種と入り口
  - Apple Intelligence の iPhone だけです。
  - iOS 27 の利用者ガイドでは、入り口は次のとおりです：Camera Control（「On supported models」）、Action ボタン、ロック画面の control、そして Siri AI があればカメラの Siri。
  - 日本語：Visual Intelligence の既存の機能（チラシから予定を足す、場所、動植物）は日本語に対応しています。アプリの結果を出す連携の言語は書かれておらず、未検証です。「Siri AI: Visual Intelligence」は「Available in English」です。
- 審査の論点［推測］
  - 写すのはシステムなので、アプリにカメラの許可は要らない見込みです。
  - pixelBuffer はメモリの中で処理し、残しません（AC-69 と同じ線）。端末の外に出さなければ、プライバシーの表記は変わりません。
- 製品との合い方［推測］
  - 毎晩の入口は、ロック画面のウィジェットが操作0回ですでに担っています。
  - Visual Intelligence が効くのは、昼の書店や本棚の場面（「もう積読にある」「積読に加える」）です。芯の夜の入口には寄与が小さいので、v1.1 とします。
  - G1 で作る BookEntity を、ISBN と DisplayRepresentation を持つ形にしておけば、後で足す手間が減ります。

## 2. App Intents と Siri、ショートカット、Spotlight、Controls
- 2a 読み始める
  - LiveActivityIntent（iOS 17 以上）の文書に「the system launches your app process without opening the app, performs the intent, and starts the Live Activity. For example, people might place a control in Control Center that performs a LiveActivityIntent」とあります。
  - Controls の文書には「Perform your app's actions from Control Center, the Lock Screen, and the Action button」「require device authentication … redact the text in a control when the device is locked」とあります。
  - したがって、designer の案「アプリを開かず、1回押せば始まる」は作れます。PRD の RICE の表にある「作れるかは tech-lead に未確認」は、この調べで「作れる」に変わります。
  - 伏せる道との関係
    - 伏せる道は、しおりの画面が前に出ているときだけ働きます（PRD）。Controls はアプリを開かない別の入口です。
    - 読書のセッションは1つだけ持つ作りにし、どちらから始めても二重になりません（すでに始まっていれば何もしない）。
    - 終えるのは Live Activity のボタン（同じく LiveActivityIntent）か、アプリの中です。
    - 今の本が0冊のときは、control の動きを「アプリを開く」（OpenIntent）に切り替えます。
- 2b ショートカットと Siri
  - AppShortcutsProvider（iOS 16 以上）を使います。
  - 「続きを読む」は、しおりの画面を開く OpenIntent にします（開いた画面で伏せて始める）。2a と同じ「読み始める」に当てる案もあります。
  - 「どこまで読んだ？」は、アプリの記録からアプリの文の型で答えを組んで返します。文を作らないので、作り話は出ません。
  - ロックしたまま答えを読み上げる場合は、AC-34 の「隠す」設定に合わせて答えを伏せるか、認証を求めます（authenticationPolicy。今回は文書を開いていないので未検証）。
  - 日本語の言い回しを Siri がどこまで聞き取れるかは未検証で、実機で確かめる必要があります。
- 2c Spotlight
  - IndexedEntity（iOS 18 以上）を使います。文書には「Adding entities to Spotlight makes them discoverable by Apple Intelligence」とあります。
  - BookEntity を索引に入れ、結果を押すとその本の画面を開く形です。
- 2d Siri AI の個人の文脈
  - iOS 26：個人の文脈を使う Siri は出ていません。Siri AI は iOS 27 で、2026-09-14 に英語のベータとして始まりました。
  - 日本語は、2026-09-14 の発表では「next month」とされていました。しかし 2026-10-18 に開いた機能の一覧では、まだ「Available in English」です。
  - Siri AI は「Spotlight index and App Toolbox」を使います。
  - 本や読書を扱う Primary の domain はありません。Books の domain は電子書籍リーダー向けで、ショートカットのアプリだけが対象です（「don't make your conforming types discoverable by Apple Intelligence」）。紙の本の記録には合わず、「genuinely match」の条件にも外れます。
  - 合うのは System domain の searchInApp と open です。
  - 自由な言い方の「どこまで読んだ？」に Siri AI が答えるには、索引に入れた BookEntity が要ります。答えの文は Apple のモデルが作るので、誤る危険が残ります（未検証）。
  - 2b と 2c を先に作っておけば、日本語の Siri AI が来たときに足す手間は小さい見込みです［推測］。

## 3. 読み終えのふりかえり（spike）
- 環境：macOS 27.0.1、Xcode 27.0、Swift 6.4。availability は available、supportsLocale(ja_JP) は true、contextSize は 4096。
  - 文書によると、端末のモデルの版は 26.0〜26.3、26.4、27.0 の3つで、macOS 27 は iOS 27 と同じ版です。
- 事実（合成）：書名「コンビニ人間」、6晩、合計142分、合計160ページ、2026-10-03〜10-15、晩ごとのページと分（合計は事実と一致させた）。
- A（事実の JSON をそのまま渡し、自由に1〜2文で書かせる）を10回
  - 10回とも文にならず、JSON を返しました（例 `{"minutes":142,"totalPages":160}`。2回は入力を丸ごと返した）。
  - 数字の誤りは0ですが、使える文は 0/10 です。1回あたり0.7〜3.9秒。
- B（@Generable。モデルには数字を見せず、差し込みの記号で書かせ、アプリが値を入れる）を10回
  - 3回は文を出し続けて落ちました（「Content contains 4098 tokens, which exceeds the maximum allowed context size of 4096.」）。
  - 1回は指示の文を漏らして同じように止まらず、「1〜2文」の数字が混じりました。
  - 1回は、ない記号を作り、「{最後の晩がいちばん長く読んだ晩}でした。」が画面に残る形になりました。
  - 残りの5回は、記号の説明まで写して文が崩れました（例：「6（読んだ晩の数）142（読んだ時間の合計の分）160（読んだページの合計）の時間を過ごしました」。ページを時間と言っている）。
  - 差し込んだ数字そのものの誤りは、仕組みのうえで0です。使える文は 0/10 です。
- 読み取れること
  - 差し込みで数字の誤りは消せますが、文の形と意味の誤り（単位の取り違え、止まらない出力、指示の漏れ）は残ります。
  - 試したプロンプトは1種だけで、10回の枠を使い切りました。事実を JSON でなく文で渡すと結果が変わるかは未検証です。
  - モデルは OS の版ごとに変わるので、毎年プロンプトを試し直す必要もあります（SystemLanguageModel の文書）。
- 推奨
  - アプリの文の型で書きます（例「6晩、合計2時間22分で読み終えました。いちばん読んだのは10月15日の38ページでした。」）。全機種で動き、誤りは出ません。読み終えのカード（回す順の (3)）と同じ版に入れます。
  - それでも AI で試すなら、アプリが書いた文の型からモデルに選ばせるだけの形で、10回の spike をし直します。ただし、その形なら AI がなくても同じ価値が出ます。

## 4. Image Playground
- API
  - imagePlaygroundSheet（iOS 18.1 以上）は、利用者がシステムの画面で絵を作る形です。
  - プログラムで絵を作る ImageCreator は iOS 27 で非推奨になり、「Use ImagePlaygroundViewController or imagePlaygroundSheet」と書かれています。利用者が選んで作る形だけが正道です。
  - imagePlaygroundGenerationStyle(_:in:)（iOS 18.4 以上）で出す画風を絞れます（例：sketch だけにして、外部の提供者の画風（externalProvider）を外す）。
  - ImagePlaygroundOptions（iOS 26.4 以上）で、personalization（人の写真を使う機能）を切れます。
  - supportsImagePlayground で、使える機種かどうかを見て出し分けます。
- 対応：対応機種だけです。日本語には対応しています（機能の一覧）。iOS 27 では、Image Playground もサーバーのモデルを使う機能として1日の上限の対象です（機能の一覧と PCC のページの脚注）。通信がないときや上限に達したときに作れない場合があります（詳しくは未検証）。
- 作った絵の扱い：「The system saves the file at a temporary location inside your app container. Move the file to a new location if you intend to keep it」。カードの背景として端末に移して残し、送るのは利用者です。
- 審査［推測］
  - 任意の飾りなので、4.3 には当たりにくい見込みです。中身の決まりは Apple のガードレールが担います。
  - 外部の画風は、外部の提供者に渡る可能性があるので出しません。
  - 書名の上に絵を重ねず、本の表紙と誤解されない置き方にします。
- 「静か」との相性［推測。決めるのは designer］：画風は animation、illustration、sketch などで、紙の色と縦書きの見た目とぶつかりやすいです。使うなら sketch だけ、任意、既定は無地にします。

## 5. PCC（iOS 27）
- API：PrivateCloudComputeLanguageModel（iOS 27 以上）。LanguageModelSession(model:) の1行で切り替えられます。
- 資格：「enrolled in the App Store Small Business Program」「fewer than 2 million first-time app downloads」「Private Cloud Compute entitlement」の3つです。2百万を超えたら「must migrate … within 6 months」。
- 費用：いまは「no cloud API cost」です。ただし「Expanded access to such features will be available for a fee in the future」とあります。
- 使える量：利用者ごとの1日の上限があります（QuotaUsage の isLimitReached、resetDate、limitIncreaseSuggestion）。
- オフライン：使えません。Error に networkFailure と serviceUnavailable があり、通信が前提です［一部推測］。
- 機種：使えない理由に deviceNotEligible があり、対応機種だけです。使える人の割合は広がりません。
- 品質：「more reasoning capabilities and a larger context size」とありますが、あらすじの事実の誤りが減る証拠はありません。
- 検討するとき
  - 先に entitlement を取り、前回と同じ4場面・36件で spike をし直します。
  - 撮ったページの本文をサーバーへ送ることになるので、新しい外へ送る経路として、脅威モデル、プライバシーの表記、利用者への説明が要ります。
  - Foundation Models の利用条件は知的財産の侵害を禁じています。本文の要約がそれに当たるかは未検証です。

## 6. 課金との関係
- 4.10 の条文：「You may not monetize built-in capabilities provided by the hardware or operating system … or Apple services and technologies, such as Apple Music access, iCloud storage, or Screen Time APIs.」。Apple Intelligence を名指しした条文はありません。
- Image Playground、Siri、Visual Intelligence に「対応していること」自体を有料にする形は、"Apple services and technologies" に当たるおそれが高いです［推測］。
- アプリが自分の価値（独自のデータ、文の型、意匠）を足し、AI がその中の道具にすぎない場合は当たりにくいです［推測］。ただし境目は審査の担当の判断です。
- 推奨：裁定 13 と同じ線で、AI の部分は無料の側に置きます。値段を付けるなら、PRD 16 の読む手すりと同じく App Review に問い合わせてからにします。
- 対応機種だけで使える有料の品は勧めません。もし出すなら次を守ります：
  - 2.3.2 の「clearly indicate whether any featured items … require additional purchases」。
  - 2.3.1(a) の誤解させる宣伝を避けるため、ストアの説明と購入の画面に「Apple Intelligence 対応機種のみ」と書き、使えない機種では買えないようにする［推測］。
  - 3.1.1 の購入の復元。
- いちばん安全なのは、全員が使える見た目「よむま＋」だけを売る今の PRD の S-11 です。

## レビュアーに反論を出してほしい点
- 2a と 2b を v1.0 の候補にしてよいか（3週の枠と、AC が増えること）。
- Visual Intelligence を v1.1 に置く判断（書店で取り違えて二重に買うのを防ぐ価値を、低く見すぎていないか）。
- 4.10 の読み方（AI を使う部分を無料にする線が厳しすぎないか）。

## 変更したファイル
- リポジトリ：なし（git status の docs/prd/ の変更は、並べて動いている pdm のもの）。
- リポジトリの外の作業用ファイル
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ai-integration-tech/notes.md
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ai-integration-tech/spike/reflection.swift
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ai-integration-tech/spike/run1.txt
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ai-integration-tech/scripts/docc.py
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ai-integration-tech/txt/all.txt
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ai-integration-tech/txt/all2.txt
  - 取ってきた文書は /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ai-integration-tech/dl/ に置きました。

## 実行したコマンドと結果
- `sw_vers; swift --version; xcodebuild -version` → macOS 27.0.1、Swift 6.4、Xcode 27.0。
- `curl https://developer.apple.com/tutorials/data/documentation/<path>.json` を約30ページ分実行し、`python3 -I docc.py` で文字にしました。
  - updates/imageplayground と appintents/app-intent-domains は JSON が返らず、代わりに app-schema-domains を読みました。
- `xcrun swiftc -O -parse-as-library -o reflection reflection.swift` → 警告なしでビルドできました。
- `./reflection` → A と B を10回ずつ実行しました。結果は 3 の節のとおりで、出力は run1.txt にあります。
- `curl` で機能の一覧、審査ガイドライン、利用者ガイド、Foundation Models の利用条件を取り、`python3 -I` で必要な節を抜き出しました。
- WebFetch で PCC のページと Siri AI の発表を、WebSearch で Siri AI の状況（1回）を調べました。
- `grep` で docs/reviews/ の前の spike（Vision の文字の読み取りとバーコード）を確かめました。
- 開いた URL（どれも 2026-10-18 に開いた）
  - https://developer.apple.com/documentation/visualintelligence/integrating-your-app-with-visual-intelligence 、/visualintelligence/semanticcontentdescriptor 、/updates/visualintelligence
  - https://developer.apple.com/documentation/updates/appintents 、/appintents/liveactivityintent 、/appintents/indexedentity 、/appintents/making-app-entities-available-in-spotlight 、/appintents/app-schema-domains 、/appintents/app-schema-domain-books 、/appintents/app-schema-domain-system-and-in-app-search 、/appintents/app-schema-domain-visual-intelligence 、/appintents/apple-intelligence-and-siri-ai 、/appintents/making-actions-and-content-discoverable-by-apple-intelligence 、/appintents/appshortcutsprovider 、/appintents/appshortcut
  - https://developer.apple.com/documentation/widgetkit/creating-controls-to-perform-actions-across-the-system 、/updates/widgetkit 、/updates/corespotlight
  - https://developer.apple.com/documentation/updates/foundationmodels 、/foundationmodels/systemlanguagemodel 、/foundationmodels/generating-swift-data-structures-with-guided-generation 、/foundationmodels/privatecloudcomputelanguagemodel （その中の availability の UnavailableReason、QuotaUsage、Error も）
  - https://developer.apple.com/private-cloud-compute/
  - https://developer.apple.com/documentation/imageplayground 、/imageplayground/imagecreator 、/imageplayground/imageplaygroundoptions 、/imageplayground/imageplaygroundstyle 、SwiftUI の imagePlaygroundSheet、imagePlaygroundGenerationStyle(_:in:)、supportsImagePlayground
  - [Apple Newsroom：Siri AI（2026-09-14）](https://www.apple.com/newsroom/2026/09/siri-ai-a-profoundly-more-capable-and-personal-assistant-is-here/)
  - [iOS の機能と言語の一覧](https://www.apple.com/ios/feature-availability/)
  - [iPhone 利用者ガイド：Visual Intelligence](https://support.apple.com/guide/iphone/use-visual-intelligence-iph12eb1545e/ios)
  - [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
  - [Foundation Models の利用条件](https://developer.apple.com/apple-intelligence/acceptable-use-requirements-for-the-foundation-models-framework/)
  - 検索で出たが根拠にしていないページ：[iPhone in Canada](https://www.iphoneincanada.ca/2026/09/14/siri-ai-is-now-available-across-ios-27-ipados-27-and-macos-27/)、[Medium](https://medium.com/@shashidj206/your-app-is-invisible-to-siri-on-ios-27-unless-you-do-this-20bb70b59ff8)、[ecorpit](https://ecorpit.com/ios-27-app-intents-siri-ai-developer-guide-2026/)、[MacRumors（日本の側面ボタン）](https://www.macrumors.com/2025/11/17/ios-26-2-iphone-users-japan-siri/)

## 未検証
- Visual Intelligence
  - 日本語の環境で、アプリの結果が出るか。
  - 表紙と背表紙から書名を読み取る精度。
  - IntentValueQuery に許される時間。
  - どれも Takuma の対応機種で、実機の spike が要ります。
- ショートカット：Siri が日本語の言い回しをどこまで聞き取るか。authenticationPolicy の正確な仕様（今回は文書を開いていない）。
- Siri AI の日本語がいつ始まるか（2026-10-18 の機能の一覧では英語のみ）。自由な言い方の質問に、索引した BookEntity から正しく答えるか。
- ふりかえり：プロンプトは1種だけです。事実を文で渡す形と、文の型から選ばせる形は試していません（10回の枠を使い切った）。
- Image Playground：iOS 27 で通信がないときの動き、1日の上限の数字、作った絵に付く来歴の印。
- PCC：supportedLanguages に日本語が入るか、将来の値段、あらすじの品質、本文を送ることが利用条件の知的財産の項に当たるか。
- 4.10：AI の機能に値段を付けたときの審査の判断（条文に名指しがないので、App Review への問い合わせが要る）。
- 負担の日数はどれも人の速さの見積もりです［推測］。

## 記録（指揮役が保存するときに書き足す）
- 種類：Apple Intelligence の使い道の調べもの（tech-lead）。PASS / FAIL なし
- 対象：Takuma の頼み（2026-10-18。docs/approvals/001-reading-session-G0-Q8.md の最後の節）。BASE=61739e0
- 日付：2026-10-18
