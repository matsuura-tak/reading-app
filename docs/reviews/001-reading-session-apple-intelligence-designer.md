（指揮役の注）これは判定ではなく、Takuma の「apple インテリジェンスとか上手いこと使えないのかな」を受けた調べもの（designer）の報告。担当は、Apple Intelligence を文を作らせない形で体験のどこに入れるか（Visual Intelligence、Siri とショートカットと Controls と Action ボタン、読み終えのふりかえり、Image Playground、ADA）。報告の文はそのまま保存した。

# 調べもの：Apple Intelligence を「文を作らせない形」で体験のどこに入れるか（designer、2026-10-18）

- これは調べものの報告で、判定ではありません。リポジトリのファイルは書いていません。
- 秒数はすべて見積もりで、測っていません［推測］。R-n はこの報告の中だけの番号です（末尾の「根拠」）。
- Apple の文書（HIG と Developer Documentation）は JSON を curl で取り、全文を読みました。WebFetch の引用は、取り込みの道具が抜き出した文です。

## 0. 結論
1. **推すのは候補2です。** App Intents で「読み始める」と「どこまで読んだ？」をシステムに渡します。ロック画面の Control と Action ボタンから、ボタンが1つの Live Activity で読書を始めます。毎晩の道は +0秒です。使う夜は、アプリを前に出す時間がほぼ0秒になります。全機種で動き、Siri AI の機種では言い方を自由にできる見込みです［推測］。
2. **2番目は条件つきで候補1（Visual Intelligence）です。** 本の入口（積読の山、書店）で「本棚にあるか、何ページからか」を返します。10秒で伝わりますが、毎晩の読書時間にはあまり効きません。iOS 27 では Camera の Siri モードに移り、Siri AI が要ります（日本語は2026年10月の予定）。本を1枚の画像から見分けられるかは tech-lead に要確認です。v1.0 には入れません。
3. **候補3と候補4は推しません。** 候補3（読み終えの1〜2文）は、事実を差し込む文の型で同じ文が出せます。AI に作らせると PRD 10 と裁定 12 に当たります。候補4（Image Playground）は、絵柄が「静か」と白黒の決まりに合いません。
4. **ADA 2025・2026 の紹介文で、Visual Intelligence、Siri、Controls、Action ボタンを名指しした作は0本です。** App Intents と Image Playground は、2025年の Inclusivity の最終候補に1本ずつだけです。Interaction と Inclusivity の両方に効くのは候補2です。
5. **いちばん強い反論：候補2は ToRead にもある分野の当たり前です。** Apple Intelligence らしさが目に見えにくいです。Action ボタンは1枠しかないので、設定する人は少ないかもしれません。

## 1. 前提：文を作らせずに Apple Intelligence を使う道
- **土台は App Intents です。**
  - アプリがシステムに渡すのは「本」（エンティティ）と「読み始める」（インテント）だけです。
  - 言葉の理解は Siri AI がします。答えの中身はアプリが持つ事実（ページ、止めた一行）なので、文を作りません。
  - HIG：「In order for an app to work with Siri, the app has to make its features and content available to Apple Intelligence using the App Intents framework.」（R-8）
- **同じ土台を、いくつものシステムの機能が使います。**
  - Siri、Spotlight、ショートカット、Controls、Action ボタン、Visual Intelligence です。
  - Visual Intelligence の結果も、AppEntity で返し、OpenIntent でアプリを開きます（R-2）。
  - 候補2で土台を作れば、候補1はその上に足す形になります［推測。tech-lead に要確認］。
- **2026年秋の状況**
  - **Siri AI の言語**
    - 2026-09-14 に英語のベータで始まりました（R-13）。
    - 日本語については「Support for French, Japanese, Korean, Portuguese, and Spanish is coming next month.」（R-13）。
    - 今日（10-18）日本語で使えるかは確かめていません。MacRumors は「iOS 27.2 のベータで」と書いています（R-16。検索結果の要約だけ）。
  - **Apple Intelligence の機種**：iOS 27 でも「iPhone 16 models or later, iPhone 15 Pro, iPhone 15 Pro Max」です（R-13）。
  - **Camera の Siri モード**
    - iOS 27 の Camera に「Siri」モードが入り、Camera Control に結び付いていた Visual Intelligence の機能がそこへ移りました。
    - 「It requires enabling Siri AI support first.」（R-15）
    - 開発者向けの文書の 2026年6月の更新は、macOS への対応だけです（R-3）。
  - **Books の schema は使えません。** App Intents の Books の schema は「Shortcuts-specific domains」に入っていて、電子書籍リーダー向けです（R-9）。紙の本のアプリは、App Shortcuts と、Spotlight に索引した本のエンティティを使うことになります［推測］。

## 2. 候補ごとの評価
### 2-1. 候補1：Visual Intelligence との統合
**仕組み（R-1、R-2）**
- 利用者がカメラか画面写真で検索ボタンを押すと、アプリの IntentValueQuery に SemanticContentDescriptor（labels と pixelBuffer）が届きます。
- labels は「general, high-level terms in the en_US locale」で、固有の名前は来ません（文書の例は tower、building）。書名や ISBN を画像から読み取って本を見分けるのは、アプリの仕事です。
- 結果は AppEntity の DisplayRepresentation（title、subtitle、image）で、システムの結果の画面に並びます。押すと OpenIntent でアプリが開きます。
- 結果の画面でできるのは「view and open items」までです。「積読に加える」はシステムの画面の中では押せません。押してアプリを開き、確かめて加える（1タップ）流れになります。

| 項目 | 中身 |
|---|---|
| 置き場所 | アプリの外。iOS 27 は Camera の Siri モードで、Camera Control の長押しでそこが開く（R-16、検索結果の要約だけ）。Camera Control があるのは「iPhone 16 and iPhone 16 Pro models」（R-4）以降で、16e にはない［推測］。結果の画面に、よむまの段が出る（実際の見た目は見ていない） |
| 毎晩の道に足す秒数 | +0秒（毎晩の道の外）。使うときは1回 約5〜8秒（長押し1秒、向ける1〜2秒、検索0.5秒、待ち1〜3秒、読む1秒）。アプリを開くなら +1.5秒［推測］ |
| 本を開く時間への効き | 弱く、間接。毎晩の「どこから」はロック画面のウィジェットが操作0回で出しているので、枕元で使う理由がない。効くのは本の入口：積読の山の本を本棚に入れる、書店で「もう持っているか」を確かめる。本棚の本が増えると次の1冊の候補が増える［推測］ |
| 10秒の象徴の瞬間 | 「ほこりをかぶった文庫を手に取る。カメラを向けて検索すると、システムの結果に『小さな舟　61ページから』。押すと、しおりの画面に縦書きの一行。そのまま本を開く。」。一目で分かる。ただ、10秒のうち約7秒は Apple の画面で、私たちの見た目は最後にしか出ない［推測］。主役（S-1：ロック画面の一行と伏せる）の代わりにはならない。「一冊の一生」の絵コンテで、登録の場面と差し替えるくらい |
| 対応機種でないときの道 | アプリの登録（バーコードを続けて読む、書名で探す）と本棚で、同じことができる。対応機種でない人に、アプリの中で Visual Intelligence を案内しない |
| 判断 | 条件つきで2番目。v1.0 には入れない |

**HIG とアクセシビリティで気をつける所**
- **結果に出す画像**
  - 文書は「localized, concise, and high-quality display representations that consist of a title, subtitle, and an image」を求めています（R-2）。
  - v1 には表紙の画像がありません（integrated/README の「後の版」）。代わりに SF Symbols の book.closed か、書名を明朝で組んだ小さな札にします［推測。札を作れるかは tech-lead］。
  - HIG に visual-intelligence という名前のページはありませんでした（JSON は 404。別の名前で存在するかは調べていません）。
- **副題の文言（すべて仮）**
  - 「61ページから」/「From page 61」。「p.61」と書くと読み上げで「p」を読んでしまうので避けます［推測］。
  - 本棚にない本は「本棚にない本」/「Not on your shelf」。
  - 書店の本はまだ買っていない本なので、「積読に加える」とは言いません。その言葉はアプリを開いた後の画面に出します。
- **止めた一行は、システムの画面に出しません。** 横書きの小さな字になってしまい、書店ではそばの人にも見えます。一行はアプリを開いてから縦書きで出します。「ロック中は隠す」がオンなら、書名とページだけにします［推測］。
- **写真は残しません。** pixelBuffer は保存しません（PRD の「写真は保存しません」と同じ）。
- **速さ**：文書は「Returning results quickly makes for a good search experience」と書いています（R-2）。本でないもの、本棚にない本は早めに打ち切ります。
- **通信できないとき**：本棚との照合は端末の中でできます。本棚にない本の書誌（国立国会図書館）は通信が要ります。7つの状態は G1 で決めます。
- **Inclusivity には効きにくい**：見えにくい人にとっては、カメラを本に向ける操作そのものが難しいです。
- **対応する人の割合**
  - Apple Intelligence の機種（約4〜5割）の中の一部で、そのうえ iOS 27 では日本語の Siri AI が要ります。
  - 日本のメインの iPhone はシリーズで iPhone 16 が最多ですが（R-19、検索結果の要約だけ）、Camera Control のある機種の割合の数字は見ていません。
  - Visual Intelligence の機能の一部（Identify Places など）には Japanese が載っています（R-14）。他社アプリの検索が日本語で動くかは、載っている所を見ていません。

### 2-2. 候補2：Siri、ショートカット、Controls、Action ボタン
**置く物**：App Intents を2つ置きます。HIG の上限は1アプリ10個です（R-7）。
- **「読み始める」**
  - 読書を始め、Live Activity（書名と経過時間、ボタンは「終える」1つ）を出します。アプリは開きません。
  - HIG Action button：「Let people use your actions without leaving their current context ... Live Activities」（R-5）
  - HIG Controls：「launching a Live Activity from a control creates an easy and seamless experience」（R-6）
  - Control は、トグルではなくボタンにします。終えるには「しおりを挟む」画面が要るためです。
- **「どこまで読んだ？」**
  - 答えは事実だけです。声の全文は「61ページからです。」/「You left off on page 61.」（仮）。
  - 画面の小窓（snippet）には、止めた一行を縦書きで出し、声には出しません。

| 入口 | 動き | 秒［推測］ | アプリを前に出す時間［推測］ | 機種 |
|---|---|---|---|---|
| 今の道（比べるため） | ウィジェットを押す → 伏せる | 約3.5〜4.5 | 約1〜2 | 全機種 |
| ロック画面の Control | 一行を見る → 記号を長押し → Live Activity → 置いて本を開く | 約2〜3 | 約0 | iOS 18 以降 |
| Action ボタン | 長押し → 同じ | 約1〜2（一行を見るなら +1〜2） | 約0 | Action ボタンのある機種 |
| Siri | 「よむま、続きを読む」（仮）→ 同じ | 約3〜4 | 約0 | 全機種（Siri AI の機種は言い方が自由になる見込み） |

- **置き場所**
  - 新しい画面は0です。入口はアプリの外（ロック画面、Action ボタン、Siri、Spotlight）にあります。
  - アプリの中では、設定の「伏せる道」の近くに説明を1つ置きます。
  - 今の道（ウィジェット → 伏せる）が主役のままです。Control と Action ボタンは「伏せない道」の近道になり、今の伏せない道（押して「読み始める」、2タップ約3秒）より短くなります。
- **毎晩の道に足す秒数**
  - +0秒です。終わりは Live Activity の「終える」→ しおりを挟む、で今と同じです。
  - 「どこまで読んだ？」はウィジェットと答えが重なるので、毎晩は使わない想定です。
- **本を開く時間への効き**
  - 中くらいから小さいですが、入口に直接効きます。
  - ロックを外さずに始められるので、ホーム画面や通知を見ずに済みます。PRD 1 の「夜にスマホへ手が伸びて、紙の本を開けないまま終わる人」に向いています［推測］。
  - ただし v1.0 は App Store Connect だけで測るので（裁定 10）、効いたかどうかは v1.0 では測れません。
  - 毎晩「読み始める」をシステムに寄付すると（R-10「Apple Intelligence can proactively suggest the same action」）、いつもの時刻にシステムが提案してくれる余地があります。通知を送らずに夜の入口を作れます［推測。どこに出るかは見ていない］。
- **10秒の象徴の瞬間**
  - 「暗い寝室。ロック画面に縦書きの一行。Action ボタンを長押しすると、Dynamic Island に『小さな舟　読書中』。iPhone を置いて本を開く。ロックは一度も外していない。」
  - 別の形：「両手で文庫を持ったまま『よむまの本、どこまで読んだ？』。枕元の iPhone が『61ページからです』。」
  - どちらも主役 S-1 の脇の1カットです。

**HIG とアクセシビリティで気をつける所**
- **名前と文言（仮）**
  - Action ボタンの名前は、動詞で始めて3語までにします（R-5）。「読み始める」/「Start Reading」。
  - ヒント文も動詞にします（R-6）。「長押しで読み始める」/「Hold to Start Reading」。
- **記号と色**
  - Control の記号は SF Symbols の book です。ロック画面では記号だけが出ます（R-6）。読み上げのラベルは「読み始める」です。
  - tint は付けず、白黒のままにします（B-5）。
- **Siri の答え方**
  - HIG：「Keep responses as succinct as possible」「Avoid including unnecessary words or attempts at humor」「Omit your app name from responses」（R-8）。
  - ページは声の全文に入れます（R-7「Include all critical information in the full dialogue text」）。
  - 止めた一行は声に出しません。HIG に「Siri may also respond aloud, and others nearby might hear the response」とあり（R-8）、夜は隣で人が寝ていることがあります。
- **ロック中**：「ロック中は隠す」がオンなら、「どこまで読んだ？」は Face ID のあとで答えます（R-6「Hide sensitive information when the device is locked」）。
- **大きい文字と読み上げ**：小窓の縦書きの一行は、アプリと同じく AX のサイズで横書きに替えます。VoiceOver は一行を1つのラベルで読みます。
- **伏せられない人の道**：伏せられない人や画面を見られない人に、ボタン1回の道と声の道ができます。伏せる動作の代わりの道です（PRD 12、WCAG 2.5.4）。
- **知らせ方**
  - 独自の案内画面は作りません（R-5「Prefer letting the system show people how to use the Action button」）。
  - SiriTipUIView（R-7）を1度だけ、毎晩の道の外で出します［推測。場所は G1］。
- **言い方とアプリの名前**
  - App Shortcut の言い方にはアプリの名前が要ります（R-7）。
  - 「よむまで〜」は「読むまで」と聞こえるので使いません。「よむま、続きを読む」「よむまの本、どこまで読んだ？」のように区切るか「の」でつなぎます。
  - 造語の名前を Siri が聞き取れるかは確かめていません（tech-lead と ios-engineer に要確認）。英語の名前は決まっていません。

**対応機種でないときの道**
- Apple Intelligence がなくても、次のものはそのまま動きます：App Shortcuts の決まった言い方（今の Siri）、Controls、Action ボタン、ショートカットのアプリ、背面タップ。失うのは Siri AI の自由な言い方だけです。
- Action ボタンがない機種では、ロック画面の Control かコントロールセンターを使います。
- Controls がない古い iOS では、今の道を使います。

**判断**：推す1です。ただし、PRD 9 で削った候補「Controls と Action ボタンで始める」（RICE 300、「Takuma の範囲になく」）を戻すことになります（pdm と Takuma が決める）。

### 2-3. 候補3：読み終えのふりかえり
- **アプリが持つ事実**：書名、著者、出版社、出版年、受賞、何晩読んだか、合計の時間、始めた日と終えた日、毎晩のページ、止めた一行。止めた一行は本の文です。
- **置き場所（入れるなら）**
  - 読み終えた画面の奥付の下、次の1冊の上に、補足の灰色の文字で1〜2行置きます。
  - 印「端末で作った文」とⓘを付けます。押すと、使った事実の一覧と「作り直す」「消す」が出ます（R-11「surfacing controls like Edit, Undo, Retry, or Adjust near generated content」）。
  - 文は画面を開く前に裏で作り、1字ずつ出しません。カードには載せません。
- **毎晩の道に足す秒数**：+0秒です。読み終えた夜だけ、40〜60字を1分に400〜600字の速さで読むとして +4〜9秒です［推測］。
- **本を開く時間への効き**：ありません。読み終えた余韻は深まっても、次の本を開く時間は増えません［推測］。
- **10秒の象徴の瞬間**：「奥付の下に『14晩、合計5時間12分。いちばん長く読んだのは10月25日の晩でした。』」。文の型でも同じ文が出るので、AI ならではの瞬間にはなりません。
- **推さない理由**
  - 事実から1〜2文を作るなら、文の型（String Catalog の複数形）で足ります。全機種で動き、作り話が0で、日英もそろいます。AI にしても増えるのは言い回しの揺れだけです。
  - AI は数を言い間違えるおそれがあります。止めた一行を渡すと、話の中身を作ってしまうおそれもあります（E-17：あらすじは36件中22件に、本文と違う事実が入った）。HIG も「Avoid requesting factual information unless you're confident the model has access to verified and up-to-date information」と書いています（R-11）。
  - 印、説明、作り直す・消すを置くと、読み終えた画面の要素が増えます（B-2、「静か」）。
  - PRD（読んだ時点で1171行目）の「AI に文を作らせる機能は v1 で使わない」と、裁定 12 に当たります。事実だけから作る文も、AI に文を作らせることに変わりありません。
- **HIG とアクセシビリティ（入れるなら）**
  - VoiceOver は印から先に読みます。斜体にはしません。
  - 文字は補足の灰色にします（白地 約5.1:1、黒地 約7.3:1。integrated/README の値）。コントラストを上げる設定では本文の色にします。
  - AX5 でも省略せず、折り返して全部出します。
- **対応機種でないときの道**：文の型の1行を出します（全機種）。これが既定になるなら、AI の版は要りません。
- **判断**：AI では入れません。ふりかえりが要るなら、文の型で作ります（今の「14晩・合計5時間12分」を伸ばす形）。

### 2-4. 候補4：Image Playground
- **仕組み**
  - システムのシート（imagePlaygroundSheet）か、対話なしで作る ImageCreator を使います。
  - スタイルは animation、illustration（「2D cartoon」）、sketch（手描き）、emoji、externalProvider（外の提供者）、any です（R-12）。
  - HIG に image-playground という名前のページはありませんでした（JSON は 404）。
- **置き場所（入れるなら）**：読み終えた画面のいちばん下、カードの見本の下に、文字のボタン「背景の絵を作る」を置きます。
- **毎晩の道に足す秒数**：+0秒です。読み終えた夜に使うと +20〜60秒です（言葉を入れる、待つ、選ぶ）［推測］。
- **本を開く時間への効き**：ありません。カードを送る人は少し増えるかもしれませんが、読む時間には関係しません［推測］。
- **10秒の象徴の瞬間**：「白いカードに、自分で作った淡い絵」。一冊のしおりの芯（続きの一行と伏せる）とつながりません。
- **合わない所**
  - **絵柄**：どのスタイルも色と飾りが強いです。いちばん近い sketch でも飾りの絵になります（B-2）。色は意味のためだけに使う決まり（B-5）と、いつも白地のカードにも合いません。
  - **本の文**：本の文や止めた一行を絵の言葉に使うと、「カードに本の文を載せない」決まり（前の Q4）を形を変えて破ります。書名から作った絵が、本の装画や登場人物に似るおそれもあります［推測。法務のことは reviewer］。
  - **送る先**：AI の絵を人に送るなら、受け取った人にも分かる印が要ります（R-11「Never trick someone into thinking ... authored by a human」）。その分、カードの字が増えます。
  - **外の提供者**：externalProvider は外の提供者を使うスタイルなので、プライバシーの説明が要ります［推測］。
- **ADA の前例**：Evolve（2025 Inclusivity の最終候補）が「nicely integrated with features like Image Playground and the State of Mind API」でした（R-18）。ただ、Evolve はセルフケアのアプリで（紹介文は「safe space for all」）、「静か」を目指す私たちとは筋が違います。
- **対応機種でないときの道**：今の白地のカードにし、ボタンは出しません。
- **判断**：推しません。

## 3. ADA（2025・2026）
| 年 | 部門 | 作 | 立場 | 紹介文 |
|---|---|---|---|---|
| 2026 | Inclusivity | Hearing Buddy、Structured | 最終候補 | Foundation Models（字幕と要約、予定の提案と下書き） |
| 2026 | Innovation／Social Impact | Detail／Harvee | 最終候補 | Foundation Models（台本／体の記録から回復の助言） |
| 2026 | Interaction（最終候補）、Visuals（受賞） | Tide Guide | 両方 | 「its powerful widgets help swimmers and boat captains save a step right from the Home Screen」 |
| 2025 | Interaction | Mela | 最終候補 | 「Timers integrate with the Dynamic Island, recipe scanning is powered by the Vision framework, and ingredients plug right into the Reminders app」 |
| 2025 | Inclusivity | Train Fitness | 最終候補 | 「eliminating the need for interaction with a screen or UI」 |
| 2025 | Inclusivity（ゲーム） | Land of Livia | 最終候補 | 「takes advantage of App Intents to let players carry out complex actions」 |
| 2025 | Inclusivity | Evolve | 最終候補 | 「nicely integrated with features like Image Playground」 |
| 2025 | Delight and Fun | Lumy／CapWords | 最終候補／受賞 | 「elegant widgets and Live Activities」／カメラで身の回りの物をステッカーに |
| 2025 | Social Impact／Innovation | Opal／Capybara | 最終候補 | 「widgets, Shortcuts」／「Apple Intelligence Translate API」 |

- **0本だったもの**：両年とも、Visual Intelligence、Siri、Controls、Action ボタン、Camera Control の語は、受賞作にも最終候補にもありません（R-17、R-18）。
- **型**
  - Interaction は、システムの面を「手間を1つ減らす」ものとして語っています（Mela、Tide Guide）。
  - Inclusivity は「画面を触らずに済む」（Train Fitness）、「App Intents で複雑な操作を」（Land of Livia）です。
  - AI は受賞作の紹介文には出ず、最終候補に「さりげない一手」として出ます（前の報告の 4-2 と同じ）。
- **候補ごとの部門への効き**

| 候補 | Interaction | Inclusivity |
|---|---|---|
| 1 VI | 少し（前例なし。Innovation 寄り） | 弱い（カメラを向けるのが難しい人がいる） |
| 2 Siri など | 強い（ボタン1回、ロックのまま、ボタン1つの Live Activity。Mela、Tide Guide の型） | 強い（伏せる動作と画面を使わない道。Train Fitness、Land of Livia の型） |
| 3 ふりかえり | なし | 前例（Structured）はあるが、「確か」を壊すおそれ |
| 4 Image Playground | なし | 前例（Evolve）はあるが、性格語に合わない |

## 4. 推す1〜2つと、いちばん強い反論
### 推す1：候補2
- **形**
  - App Intents を2つ置きます（読み始める、どこまで読んだ？）。
  - 入口は、ロック画面の Control、Action ボタン、Siri、Spotlight です。始めるとボタン1つの Live Activity が出ます。答えは事実だけです。
- **量**：毎晩の道は変えません。新しい画面は0です。アプリの中で足すのは、設定の説明1つだけです。
- **理由**
  1. 毎晩の入口に直接効き、アプリを前に出す時間が減ります（中央値30秒のガードレールの内側で、さらに短くなる）。
  2. 全機種で動きます。Apple Intelligence は上乗せで、自由な言い方と提案が加わります［推測］。
  3. 文を作りません。AI は言葉を理解するだけで、答えはアプリが持つ事実です。
  4. ADA の Interaction と Inclusivity の両方に効きます。
  5. 候補1の土台になります［推測。tech-lead に要確認］。

### 推す2（条件つき、v1.x）：候補1
- **形**
  - 本の入口だけで使います。
  - 本棚の本なら「61ページから」「積読」「読み終えた」を返し、ない本なら「本棚にない本」を返します。
  - 押すと、アプリの本の画面か登録の画面が開きます。
- **条件**
  - (a) 日本語の本を、1枚の画像から見分けられること（表紙の縦書きの書名を読み取る、帯がかかっていても読める、2段のバーコードから 978 で始まる方を選ぶ）。
  - (b) iOS 27 の Camera の Siri モードで、他社アプリの結果が日本語で出ること。
  - (c) 候補2の土台ができていること。
  - (a) と (b) は tech-lead が確かめます。
- **見せ方**：10秒の映像は、主役 S-1 の後の「一冊の一生」の1場面にします。

### いちばん強い反論
- **候補2に対して**
  - **分野の当たり前で、差にならない**：ToRead は「ショートカットや背面タップで読書を開始・終了。」です（PRD E-12）。Takuma の「Apple Intelligence を上手いこと使う」に、目に見える形では応えません。
  - **使う人が少ないかもしれない**：Action ボタンは1つしかなく、カメラ、ライト、消音と取り合います。ロック画面の Control も2枠で、ライトとカメラと取り合います［推測］。
  - **入口が増えて、伏せる話がぼやける**：10秒の映像と審査メモの1文が散ります。ウィジェット、Live Activity、アプリの状態のずれを確かめる手間も増えます［推測。tech-lead］。
  - **それでも推す理由**：毎晩の読書時間に直接効くのは、4つの候補のうちこれだけです。AI の見せ場が要るなら、候補1を条件つきで後から足します。
- **候補1に対して**
  - 毎晩の道の外にあり、同じ答えはウィジェットが操作0回で出しています。
  - カメラの道は約5〜8秒かかります。
  - 動くには、AI の機種、日本語の Siri AI、本の見分けの3つがそろう必要があります。
  - ADA に前例がありません。

## 根拠
| R | 中身 | URL | 開いた日 |
|---|---|---|---|
| R-1 | Visual Intelligence の概要（カメラか画面写真で検索。アプリの結果は「view and open」） | https://developer.apple.com/documentation/visualintelligence （JSON は https://developer.apple.com/tutorials/data/documentation/visualintelligence.json ） | 2026-10-18 |
| R-2 | Integrating your app with visual intelligence（IntentValueQuery、labels は en_US の一般語、DisplayRepresentation、OpenIntent、速く返す） | https://developer.apple.com/documentation/visualintelligence/integrating-your-app-with-visual-intelligence | 2026-10-18 |
| R-3 | Visual Intelligence updates（2026年6月は macOS への対応だけ） | https://developer.apple.com/documentation/updates/visualintelligence | 2026-10-18 |
| R-4 | HIG Camera Control（2024-09-09） | https://developer.apple.com/design/human-interface-guidelines/camera-control | 2026-10-18 |
| R-5 | HIG Action button | https://developer.apple.com/design/human-interface-guidelines/action-button | 2026-10-18 |
| R-6 | HIG Controls | https://developer.apple.com/design/human-interface-guidelines/controls | 2026-10-18 |
| R-7 | HIG App Shortcuts（2026-06-08 に app schema を追記） | https://developer.apple.com/design/human-interface-guidelines/app-shortcuts | 2026-10-18 |
| R-8 | HIG Siri（2026-06-08「Revised for Siri AI」） | https://developer.apple.com/design/human-interface-guidelines/siri | 2026-10-18 |
| R-9 | App schema domains（Books は Shortcuts-specific） | https://developer.apple.com/documentation/appintents/app-schema-domains | 2026-10-18 |
| R-10 | Apple Intelligence and Siri AI（索引、寄付、画面の文脈） | https://developer.apple.com/documentation/appintents/apple-intelligence-and-siri-ai | 2026-10-18 |
| R-11 | HIG Generative AI | https://developer.apple.com/design/human-interface-guidelines/generative-ai | 2026-10-18 |
| R-12 | Image Playground、ImageCreator、ImagePlaygroundStyle | https://developer.apple.com/documentation/imageplayground 、https://developer.apple.com/documentation/imageplayground/imagecreator 、https://developer.apple.com/documentation/imageplayground/imageplaygroundstyle | 2026-10-18 |
| R-13 | Apple Newsroom 2026-09-14（Siri AI。言語、機種、Camera の Siri モード） | https://www.apple.com/newsroom/2026/09/siri-ai-a-profoundly-more-capable-and-personal-assistant-is-here/ | 2026-10-18 |
| R-14 | iOS 27 Feature Availability（179,741字のうち前半100,000字だけ） | https://www.apple.com/ios/feature-availability/ | 2026-10-18 |
| R-15 | 9to5Mac 2026-09-15（Camera の Siri モード） | https://9to5mac.com/2026/09/15/ios-27-gives-camera-app-on-iphone-three-powerful-new-features/ | 2026-10-18 |
| R-16 | 検索結果の要約だけ（本文は開いていない）：MacRumors 2026-09-16、9to5Mac 2026-06-11、AppleInsider 2026-04-29 | https://www.macrumors.com/2026/09/16/siri-ai-new-languages-ios-27-2/ 、https://9to5mac.com/2026/06/11/ios-27-brings-another-very-welcome-improvement-to-camera-control-on-iphone/ 、https://appleinsider.com/articles/26/04/29/visual-intelligence-to-be-added-to-ios-27-camera-app-as-siri-mode | 2026-10-18 |
| R-17 | ADA 2026 | https://developer.apple.com/design/awards/ | 2026-10-18 |
| R-18 | ADA 2025 | https://developer.apple.com/design/awards/2025/ | 2026-10-18 |
| R-19 | MMD研究所 2026年8月の調査（検索結果の要約だけ） | https://k-tai.watch.impress.co.jp/docs/news/2141870.html 、https://www.watch.impress.co.jp/docs/news/2141787.html | 2026-10-18 |

- リポジトリで読んだもの：docs/reviews/001-reading-session-ai-designer.md（全文）、docs/reviews/001-reading-session-integrate-designer.md（1-1、5、6）、design/explore/integrated/README.md、docs/prd/001-reading-session.md（grep だけ。E-12、E-17、9 の RICE の表、10、生成 AI の行）

## 変更したファイル
- リポジトリ：なし
- 作業用（リポジトリの外）
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ai-integration-designer/notes.md：新しく作り、5回書き足した
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ai-integration-designer/scripts/j2t.py：Apple の JSON を文字にするだけのスクリプト（通信とファイルへの書き込みはしない）
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ai-integration-designer/dl/：取った JSON（1つずつ別のフォルダ）
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ai-integration-designer/out/：文字にしたもの

## 実行したコマンドと結果
- **Bash（リポジトリは読むだけ）**：ls、cat、sed、grep で、上の4つのファイルを読みました。
- **curl（--create-dirs で dl/<名前>/page.json に保存）**
  - HIG：controls、app-shortcuts、siri、camera-control、action-button、generative-ai は 200。image-playground と visual-intelligence は 404。
  - Docs：visualintelligence、integrating-your-app-with-visual-intelligence、updates/visualintelligence、imageplayground、imagecreator、imageplaygroundstyle、appintents/app-schema-domains、appintents/apple-intelligence-and-siri-ai は、どれも 200。
  - 取った JSON は `python3 -I scripts/j2t.py` で文字にしました。
- **WebFetch**
  - apple.com/ios/feature-availability：前半の100,000字だけ読みました。注1と後半の79,741字は読んでいません。
  - Apple Newsroom 2026-09-14（2回）、9to5Mac 2026-09-15、ADA 2026、ADA 2025。
- **WebSearch（3回）**
  - Siri AI の日本語の時期、iOS 27 の Camera の Siri モード、MMD研究所の機種の割合。
  - R-16 と R-19 は検索結果の要約だけで、本文は開いていません。
- **ガードに止められたこと**：1回目の Bash で、書き先のパスに変数を使っていて止められました。パスをそのまま書いて実行し直しました。
- **その他のエラー**：zsh で `echo ======` が「not found」になりました（= が展開されるため）。調べた中身には影響ありません。
- **開けなかった URL**：HIG の image-playground と visual-intelligence（JSON が 404）。
- ツールの呼び出しは約27回でした。

## 未解決
- **PRD との関係（pdm と Takuma が決める）**
  - 候補2は、PRD 9 で削った「Controls と Action ボタンで始める」（RICE 300）を戻す提案です。Siri の App Shortcuts（読み始める、どこまで読んだ？）は PRD にありません。v1.0 に入れるか、v1.1 にするかを決める必要があります。
  - 候補1は PRD にありません。v1.x の候補として記録するだけです。
  - 候補3を入れたいなら、文の型（AI なし）にするかどうか。AI で作ると、PRD 10、生成 AI の行、裁定 12 に当たります。
  - v1.0 は App Store Connect だけで測るので（裁定 10）、候補2の効き（ロックを外さずに始めた割合、アプリを前に出す時間）は v1.0 では測れません。
- **tech-lead に要確認**
  - 候補2
    - ロック中に Control から読書を始めて、記録を書けるか（データの保護の種類）。
    - App Intent から Live Activity を始められるか。
    - ウィジェット、Live Activity、アプリの状態がずれないか。
    - 造語「よむま」を Siri が聞き取れるか。別名を登録できるか。
    - Siri AI が、アプリの名前のない「いまの本、どこまで読んだ？」を、schema のない App Intent に結び付けられるか。
    - 寄付した操作の提案が、どこに出るか。
    - 対応する iOS の最低版（Controls は iOS 18 から）。
  - 候補1
    - 1枚の画像から日本語の本を見分けられるか（縦書きの書名の読み取り、帯、2段のバーコード）。
    - 結果を返すまでの時間。
    - iOS 27 の Camera の Siri モードで、他社アプリの結果が出るか。日本語で出るか。
    - 表紙の画像がないときの、結果に出す画像。
    - ロック中の扱い。
- **見ていないもの**
  - 今日の時点で、Siri AI が日本語で使えるか。
  - Visual Intelligence の結果の画面、Camera の Siri モード、ロック画面の Control、Action ボタンを押したときの Dynamic Island の、実際の見た目（実機でも画像でも見ていない）。
  - 日本で Camera Control のある機種の割合の数字。
- **気づき（PRD にないので記録だけ）**：Camera Control と Controls の「Camera experiences on a locked device」（LockedCameraCapture。R-4、R-6）を使うと、しおりを挟む撮影をロックのまま開けます。AI ではありませんが、読み終わりの道を短くする候補です。
- **テンプレートの「確かめ」**：この仕事は調べものの報告で、design/<機能名>-research.md ではありません。そのため、docs/templates の「確かめ」には印を付けていません。

## 記録（指揮役が保存するときに書き足す）
- 種類：Apple Intelligence の使い道の調べもの（designer）。PASS / FAIL なし
- 対象：Takuma の頼み（2026-10-18。docs/approvals/001-reading-session-G0-Q8.md の最後の節）。BASE=61739e0
- 日付：2026-10-18
