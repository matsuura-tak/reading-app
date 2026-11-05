（指揮役の注）これは判定ではなく、機能を統合した体験を検討するための調べもの（designer）の報告。担当は、Takuma の4つと「続きの一行」を1つの体験に統合する案、友人の見え方、書誌とおすすめの出し方、登録の流れ、象徴の瞬間、Apple Design Award。報告の文はそのまま保存した。

# 調べもの：機能を統合した読書アプリの体験の案（designer、2026-10-18）

- リポジトリのファイルは書いていません。作業用のファイルは、リポジトリの外の /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/integrate-designer/ にだけ置きました。
- 開いた日はすべて 2026-10-18 です。R-n はこの報告の中だけの番号で、根拠の表は 7 のあとにあります。推測には［推測］と付けました。
- 秒数はすべて designer の見積もりで、測ってはいません［推測］。
- 競合の機能の地図、需要、作れるかどうかは、ほかの役が調べています。作れるか分からない所には「tech-lead に要確認」と書きました。
- ツールの呼び出しは、この報告を入れて28回でした。

## 0. 結論
1. 推すのは統合案1「一冊のしおり」です。タブのない1画面で、開くといま読んでいる本の続きだけがあります。友人、書誌、おすすめ、登録は、本の一生の決まった瞬間にだけ出します。毎晩の道（ロック画面の続きの一行 → 押す → 伏せる。約3.5〜4.5秒）には何も足しません。
2. 友人はフィードにしません。20人までの「友人の机」（友人ごとに、いま読んでいる1冊だけ）と、読んだあとの1行「同じ夜、ゆうこさんも本を開いていました。」で見せます。自由に書ける文、通知、数の比べ合いは持ちません。
3. 書誌は、読み終えた瞬間に「奥付」の形で5行まで出します。おすすめは「次の1冊」を3冊までにし、理由は確かめられる事実を1行だけ添えます。利用者が0人の日は、自分の積読、友人、受賞、著者で埋めます。「これを読んだ人は」という言葉は、本当の人数を出せるようになるまで使いません。
4. いちばん強い反論：続きの一行は「毎晩、止めたページを撮る」手間（約5〜8秒）と、まだ確かめていない読み取りに頼っています。撮らない夜が続けば、ほかのアプリのロック画面の表示と変わらなくなります。
5. ADA は Interaction を主に、Inclusivity を従に狙います。次の手は、絵コンテ1枚と主な画面の静止画8枚です。10秒の試作は、確かめ4が終わるまで直しません。

## 1. 体験の案

### 1-0. 3つの案に共通する前提
- **本の一生と、起きる回数**
  - 見つける → 登録する → 積む → 選ぶ → 毎晩読む → 読み終える → 次へ。友人は、このあいだに入ります。
  - 毎晩読むのは週に何度も起きます。選ぶ、読み終えるは数週間に1回、登録は本を手に入れたときだけです［推測］。
  - 前の報告の型 P-6「喜びは、使う回数の少ない所に置く」（docs/reviews/001-reading-session-reselect-designer.md の 1-2）に従います。回数の多い毎晩の道は速く静かにします。書誌、おすすめ、友人は、回数の少ない瞬間に置きます。
- **毎晩の入口の制約（3案に共通）**
  - 伏せた向きは、アプリが前面にあり、画面が点いているときにしか取れません（design/001-reading-session-research.md の R-11）。ロック画面のまま伏せても、読書は始まりません。
  - そこで入口を2つにします。1つは「ウィジェットを押してアプリを開き、伏せる」。もう1つは「ロック画面の Controls か Action ボタンで、アプリを開かずに始める」です。HIG は「People can add controls to Control Center …, to the Lock Screen by customizing their Lock Screen, and to the Action button」と書いています（R-5）。
  - HIG はロック画面のウィジェットについて、「Provide useful information in your Lock Screen widget, and don't treat it as an additional way for people to launch into your app.」と書いています（R-3）。続きの一行は、それだけで役に立つ情報なので、この線に合います。
- **c1 の試作と実際の画面の違い**
  - c1 では、一行を画面の中ほどに、画面の高さの6割ほどの大きさで描きました（design/explore/concepts/index.html の .vline。top:21%、font-size:2.6em）。
  - 実際にアプリが一行を出せる場所は、次の3つです。どれも c1 と同じ大きさにはならない見込みです［推測。tech-lead に要確認］。
    - 時計の下の、小さなウィジェットの枠
    - 画面の下の方の Live Activity
    - 充電中の StandBy。小さなウィジェット2つを大きくして並べ、暗い所では赤みの単色で描きます（R-3）。枕元で充電する夜には、ここがいちばん大きく見えます。

### 1-1. 統合案1「一冊のしおり」　推す案
- **ひとことで**：アプリは、いま読んでいる1冊の「しおり」です。開くと、その本の続きだけがあります。ほかの機能は、本の一生の決まった瞬間にだけ出てきます。
- **審査メモの1文の案**：「ロック画面に、自分の本の昨夜の続きの一行が出て、iPhone を伏せるとその本の読書が始まります。友人、出版社と受賞、次の1冊は、本を読み終えたときにだけ出ます。」

| 本の一生 | 起きること | 入るもの |
|---|---|---|
| 見つける | アプリの外で見つける。友人がメッセージで送ってきた本のリンクを押すと、1タップで積読に入る | 友人（手渡し）、登録 |
| 登録する | 本を手に入れたとき。バーコード、背表紙の写真、書名で探すの3つ（4 に詳しく書いた） | 簡単な登録。書誌は、本を確かめるための1行だけ |
| 積む | 「本棚」シート。読んでいる、積読、読み終えた の3つに分けた一覧。毎晩の道には出ない | 書誌（本ごとの奥付） |
| 選ぶ | 読み終えた瞬間と、本棚の「次を選ぶ」のときだけ。「次の1冊」を3冊まで出し、理由は事実1行 | おすすめ、受賞、友人 |
| 毎晩読む | ロック画面の続きの一行 → 押してしおりの画面へ → 伏せる → 起こして「終える」 → しおりを挟む（止めたページを撮る） → 結果 | 続きの一行。友人は結果の下に1行だけ |
| 読み終える | しおりの画面の「読み終えた」 → 奥付（5行まで） → 次の1冊 | 書誌、受賞、おすすめ、友人（手渡す） |
| 次へ | 選んだ本がしおりの画面に入る。その夜から、その本の続きの一行が出る | - |
| 友人（あいだ） | 「友人の机」シート。友人ごとに、いま机にある1冊だけを出す。20人まで | 友人 |

- **画面の骨組み**
  - 最初の画面はしおりの画面です。NavigationStack の根に置き、TabView は使いません。上から順に、次のものが並びます。
    1. ツールバー：「本棚」（books.vertical）、「友人」（person.2）、設定（ellipsis.circle）。ナビゲーションの層なので、標準のツールバーのまま使います。
    2. 書名と著者（小さく、横書き）
    3. 続きの一行（縦書き、明朝、大きく）と、p.61
    4. 今夜の量「15分なら p.76 あたりまで」（灰色の文字。出すかは選べる）
    5. 主操作「読み始める」と、その下に「伏せても始まります」
  - シートは5つです：登録、本棚（本を押すと奥付の画面）、読み終えた（奥付 → 次の1冊）、友人の机、設定。
  - 数は、画面1つとシート5つで、タブは0です。
  - システムの面（アプリの外に出る部分）
    - ロック画面のウィジェット：続きの一行とページ
    - Controls と Action ボタン：「読み始める」
    - Live Activity（読書中）：書名と経過時間。ボタンは「終える」1つだけです。HIG は「prefer limiting it to a single」と書いています（R-4）。
    - StandBy

- **毎晩の入口から伏せるまで**

| # | すること | 手数 | 秒［推測］ |
|---|---|---|---|
| 1 | iPhone を手に取る。ロック画面に続きの一行と p.61 が出ている | 0 | 約1〜2（一行を読む時間） |
| 2 | ウィジェットを押す。Face ID のあと、しおりの画面が開く | 1タップ | 約1.5 |
| 3 | 机に伏せる。触覚が1回返り、読書が始まる | 伏せる動作1回 | 約1 |
| 計 | | 1タップと伏せる動作 | 約3.5〜4.5 |

  - 伏せない道
    - 2 のあとに「読み始める」を押す：2タップで約3秒
    - Controls か Action ボタン：アプリを開かず、1回押せば始まる（約2秒）。始まりの時刻を残すだけなので作れる見込みです。tech-lead に要確認。
  - 伏せたあと（読み終わり）
    - 起こして「終える」を押す（1タップ）。
    - しおりを挟む：止めたページを撮り（約3秒）、止めた行を押す（約2〜3秒）。結果「p.43 → p.61　18分」が出ます。
    - 撮らないなら「ページ数だけ」（約3秒）か「あとで」を選べます。
  - ToRead と比べると：ToRead は「ワンタップで読書開始」です（research の R-1）。手数は同じか少し多く、速さでは勝てません。勝てるのは、手に取った瞬間にどこまで読んだかが分かることと、伏せる動作のほうです［推測］。
- **目的に沿って足すもの（Takuma の「他にも」への答え）**
  - 今夜の量：自分の読む速さ（前の回のページ数÷分）から「15分なら p.76 あたりまで」と出します。疲れ（38.9%）に対して、「少しでいい」を数で示します。利用者0人でも、通信がなくても出せます［推測］。章の終わりまでを出すには目次の写真が要るので、後の版にします。
  - Controls と Action ボタンで始める（R-5。R-4 の「start your Live Activity using the Action button on iPhone」）。
  - 奥付の棚：本棚の「読み終えた」に、読み終えた本が奥付の形で並びます。「本を読む人」でいる自分を確かめるためのものです（docs/prd/product.md の 2、人の目の面）。
  - 足さないもの：統計の画面、目標、連続日数、ランキング、環境音（7 の「捨てるもの」）。
- **HIG とアクセシビリティ**
  - HIG
    - ロック画面のウィジェットは、それだけで情報として成り立たせます（R-3）。
    - Live Activity のボタンは1つにします（R-4）。
    - オンボーディングは「fast, fun, and optional」にし、本を1冊加えるという本当の作業そのものにします（R-6）。
  - Dynamic Type
    - 続きの一行は縦書きの独自の組みなので、Dynamic Type への追従は自分で作ります。
    - AX5 では横書きに切り替えます（design/explore/README.md の名作の案と同じ線）。
    - ウィジェットに入りきらないときは、書名とページだけにします。
  - VoiceOver
    - 一行は本文として読み上げます（「『小さな舟』61ページ。雨は、まだやまなかった。」）。
    - 伏せられない人には、同じ重みの「読み始める」ボタンを置きます。
    - 始まったことは、読み上げと触覚で伝えます。
  - 動きを減らす設定：動くのはシートの出入りだけで、それはシステムに任せます。
  - ダークモード
    - 夜に使うので、しおりの画面とウィジェットはダークを先に決めます。
    - 写真から切り出した活字（5 の S-2）を出すなら、白い紙のままにせず、文字の形だけにします。夜にまぶしくしないためです。tech-lead に要確認。
  - プライバシー
    - ロック画面の一行と書名は、そばにいる人にも見えます。
    - 設定に「ロック中は隠す」を置きます。HIG Controls の「redact the title and value」（R-5）と、Live Activities の「could be viewed by casual observers」（R-4）に合わせます。

### 1-2. 統合案2「机と本棚」
- **ひとことで**：今夜の「机」と、すべての本の「本棚」という2つの場所を持ちます。

| 本の一生 | 起きること | 入るもの |
|---|---|---|
| 見つける | 本棚タブの「次の候補」の段（友人が読み終えた本、同じ賞、同じ著者） | おすすめ、受賞、友人 |
| 登録する | 本棚タブの「＋」 | 登録 |
| 積む | 本棚タブ（積読の山の写真か、一覧） | 書誌（奥付） |
| 選ぶ | 本棚から、いつでも1冊を「机に置く」 | おすすめ |
| 毎晩読む | 机タブ（ウィジェットから直接開く） → 伏せる | 続きの一行 |
| 読み終える | 机の「読み終えた」 → 奥付 → 本棚へ | 書誌、受賞 |
| 友人 | 本棚タブのいちばん上に「友人の机」を横一列に並べる（友人ごとに、いま読んでいる1冊） | 友人 |

- **骨組み**：TabView に2つ（机、本棚）。画面は、机、本棚、本の画面、登録、友人、設定の約6つです。
- **毎晩**：統合案1と同じです（1タップと伏せる動作で、約3.5〜4.5秒）。ただし、本棚タブがいつも1タップ先にあります。
- **良い所**：Takuma の4つの機能が、いつでも見えます。標準の TabView と List で作れ、機能を見つけやすい形です。
- **弱い所**
  - 本棚が「見て回る場所」になり、アプリの中にいる時間が増えます（緊張1）。
  - 構成がブクログや Bookmory と同じ「本棚とタブ」の形になり、画面写真では違いが見えません（緊張2）。
  - 本棚タブの仕事を1文で書けません（B-1。緊張5）。
- **HIG とアクセシビリティ**
  - TabView と List なら、Dynamic Type、VoiceOver、ダークモードへの対応が標準で付いてきます。
  - 積読の山の写真は、VoiceOver では同じ中身の一覧に置き換えます（前の報告の 2-1）。
  - 友人の横一列は、AX5 では縦の一覧にします。
  - 動きを減らす設定で困る所はありません。

### 1-3. 統合案3「同じ夜の輪」
- **ひとことで**：20人までの小さな輪で、今夜だれが本を開いたかだけを分け合います。その気配を、本を開く後押しにします。

| 本の一生 | 起きること | 入るもの |
|---|---|---|
| 見つける | 輪の人が読み終えた本が、自分の「次の1冊」の候補に入る | 友人、おすすめ（友人1人から成り立つ「これを読んだ人は」） |
| 登録する | 輪の人の本から1タップで加える。ほかはバーコードなど | 登録 |
| 積む | 本棚（飾りのない一覧） | 書誌 |
| 選ぶ | 輪の人が読み終えた本を先に出す | おすすめ、受賞 |
| 毎晩読む | ロック画面のウィジェットに、続きの一行と「今夜　ゆうこ、まこと」が出る。伏せると、自分の名前も相手のウィジェットに出る | 続きの一行、友人 |
| 読み終える | 奥付を輪に「置く」 | 書誌、友人 |

- **骨組み**：TabView に2つ（今夜、輪）。画面は、今夜、輪、本の画面、登録、設定の約5つです。
- **毎晩**：1タップと伏せる動作で約3.5〜4.5秒です。ロック画面で友人の名前を読む約1秒が加わります。
- **良い所**
  - 「これを読んだ人は」が、友人1人からでも本当に成り立ちます（緊張3に強い）。
  - Takuma の「友人が何を読んでるか」に、正面から答えます。
  - mekuru の「気配」（R-9）を、知り合いどうしで使う形です。
- **弱い所**
  - 輪の中で同期するために、サーバーか iCloud の共有が要ります。しかも、何を読んでいるかという私的な情報を、毎晩やりとりすることになります（緊張4）［推測］。
  - 友人がいない人には、アプリの中心が空になります。0人の問題が、利用者一人ひとりの側に移るだけです。
  - 気配が「みんな読んでいるのに」という圧になり、性格語「静か」とぶつかります。
  - ロック画面に友人の名前が出ると、そばにいる人にも見えます（R-4）。
- **HIG とアクセシビリティ**
  - 友人が読んでいるかは名前が出るかどうかで示し、色や光で「灯る」形にはしません。
  - ロック中は、友人の名前を隠すのを最初の設定にします。
  - VoiceOver では「今夜、ゆうこさんとまことさんが本を開いています」と読み上げます。
  - AX5 でウィジェットに名前が入らないときは、「2人」と人数だけにします。
  - 動きを減らす設定では、名前が灯る動きを止めます。

### 1-4. 5つの緊張への答え

| 緊張 | 統合案1 しおり | 統合案2 机と本棚 | 統合案3 同じ夜の輪 |
|---|---|---|---|
| 1 スマホに時間を取られる | ○ 毎晩の道に何も足さない。友人が出るのは読んだあとだけ | △ 本棚タブがいつも1タップ先にある | △ 読む前に友人の名前を見る。ただしロック画面で見るので、アプリの中にはいない |
| 2 ほかのアプリに埋もれる | ○ 機能は同じでも、出す時が違う。入口は「続き」 | × 構成が、いまある読書記録のアプリと同じ | △ 友人が主役になり、読書の SNS に近づく |
| 3 利用者が0人 | ○ 積読、友人、受賞、著者の順に埋まる | ○ 統合案1と同じ | △ 友人がいないと空になる |
| 4 サーバー、審査、プライバシーの負担 | ○〜△ 20人まで、自由に書ける文なし、通知なし。iCloud の共有なら自前のサーバーは要らない（tech-lead に要確認） | △ 仕組みは統合案1と同じだが、見える面が広い | × 毎晩の気配のやりとりが中心で、負担がいちばん大きい |
| 5 体験がぼやける | ○ 画面は1つ。機能はそれぞれ1つの瞬間に結びつく | × 本棚にすべてが集まる | △ 輪と読書という2つの中心がある |

## 2. 友人の見え方
### 2-1. 決まり
- **F-1 人ではなく、本に付ける**：友人の情報は、本の一生の3つの瞬間（読んだあと、次を選ぶとき、本の奥付）にだけ、1行で出します。スクロールして見て回る面は作りません。
- **F-2 終わりのある一覧にする**：「友人の机」は、友人1人につき1行（いま机にある1冊）です。
  - 履歴、数、反応は持ちません。友人は20人までにします（Locket と同じ数。R-10）。
  - Apple のアクティビティ共有と同じく、「自分の机を隠す」と「友人から外す」を置きます（R-11）。
- **F-3 自由に書ける文を持たない**
  - 分け合うのは次の3つだけです：本の書誌の ID、状態（読んでいる／読み終えた）、今夜本を開いたか（はい／いいえ）。
  - 分数、ページ、続きの一行は出しません。
    - 分数とページを出すと比べる数字になり、「数えることが重荷にならない」（research の 6-1）に逆らうためです。
    - 一行は本の文の引用になるためです［推測］。
  - 名前は、送る人が書く表示名を使わず、iCloud の名前か、受け取る人の連絡先の名前にします［推測。tech-lead に要確認］。こうして、ガイドライン 1.2 の「create, generate, upload, share, or otherwise contribute content」に当たる範囲を小さくします（R-8）。それでも 1.2 に当たるかどうかは、pdm と tech-lead に要確認です。
- **F-4 通知を出さない**
  - 友人が読み終えても、通知しません。アプリを開かせる仕掛けにはしません。
  - Apple のアクティビティ共有は、友人が目標を達したときに通知します（R-11）。ここはあえて逆にします。
- **F-5 1人ずつ招き、アカウントを作らせない**
  - 招待は、メッセージで1人ずつリンクを送る形にします。ガイドライン 5.1.2(v) は「do not include a Select All option」と書いています（R-8）。
  - アカウントは作らせません。5.1.1(v) は「inviting friends to use the app are not considered core app functionality」と書いています。友人の機能を使わなくても、アプリのすべてが動くようにします。
  - 同期は、iCloud の共有（CKShare）で自前のサーバーを持たない案にします。tech-lead に要確認。

### 2-2. 出る場所
| 出る場所 | 出るもの（1行） | 本を開く時間に効く理由 |
|---|---|---|
| 読書の結果（起こしたとき） | 「同じ夜、ゆうこさんも本を開いていました。」書名は出さない | 読んだあとにしか出ないので、読む前にアプリへ引き込まない。読んだことへの静かなお返しになる［推測］ |
| 次の1冊を選ぶとき | 候補の理由に「ゆうこさんが読み終えた本」 | 選ぶ迷い（3.6%）を、知っている人という事実で短くする |
| 本の奥付 | 「ゆうこさんも読みました（2025年3月）」 | その本の値打ちを、知っている人で確かめられる |
| 友人の机（シート） | 友人ごとに、いま机にある1冊。20行まで | 終わりのある一覧で、5秒ほどで見終わる［推測］ |
| 手渡す（読み終えた奥付から） | システムの共有シートで、メッセージに本のリンクを送る | アプリの中に文を置かない。受け取った人は1タップで積読に入れられる |

- 読む前（ロック画面、しおりの画面）には、友人の情報を出しません。続きの一行と競わせないためです。ここが統合案3との違いです。
- リンクを開くにはユニバーサルリンクのためのドメインが要るかもしれません（静的なページだけで済むかを含めて、tech-lead に要確認）。

### 2-3. 手本（フィードを持たない友人の形）
| 手本 | 引用 | 取り入れること、取り入れないこと |
|---|---|---|
| mekuru（JP 368件、平均4.69、5.1.0） | 「同じ時間に読んでいる誰かの気配だけが、そっと伝わります」「DM、いいね、コメント、フォロー、ランキングはありません」（R-9） | 気配だけを伝える形は取り入れる。mekuru は知らない人と同じ部屋で読む形で、こちらは知り合いだけ |
| Locket Widget（US 580,078件） | 「a widget that shows live photos from your best friends, right to your Home Screen」「you can only have 20 friends on the app」「there's no worrying about follower count」（R-10） | 人数の上限と、フォロー数を持たないことは取り入れる。Locket にある反応（reaction）と、送った写真の履歴は取り入れない |
| Apple のアクティビティ共有 | 「Tap Hide my Activity.」「Tap Mute Notifications.」「Tap Remove Friend.」（R-11） | 隠す、外すは取り入れる。友人が目標を達したときの通知は取り入れない |

### 2-4. 空のときと、うまくいかないとき
- 友人が0人のとき
  - 友人の机は ContentUnavailableView にします。文は「友人はまだいません」、ボタンは「1人を招く」です。
  - 読書の結果の1行は、出しません。「誰も読んでいません」とも書きません。
- 同期が遅れたとき：その夜の1行が出ないだけにし、エラーは出しません。
- 見せたくない本：本ごとに「友人に見せない」を選べるようにします。何を読んでいるかは、病気、信仰、政治など、人に知られたくない情報になりえます［推測］。

## 3. 書誌とおすすめ
### 3-1. 書誌（出版社、受賞）
| 瞬間 | 出す量 | 形と理由 |
|---|---|---|
| 登録の確かめ | 書名、著者、出版社（レーベル）の1行 | 違う版を選ばないため。受賞は出さない |
| 次の1冊の候補 | 理由の1行。受賞があれば、それを使う（例：「第〇回 〇〇賞」） | 確かめられる事実だけにする（前の報告の G-3） |
| 読み終えた瞬間 | 奥付の形で5行まで：書名、著者、発行所（出版社）、初版の年、受賞 | 日本の本の最後のページにある型。HIG の「Use concepts that people know」（research の R-12） |
| 本の画面（本棚から） | 奥付と、自分の読書（回数、合計の時間） | いつでも見られる |
| 毎晩の道 | 出さない | 続きの一行と競わせない |

- 奥付を選んだ理由：日本の読者が知っている型で、飾りではありません。出版社と受賞を、文字だけで、決まった量の中に収められます。表紙、あらすじ、レビューは置きません。
- 受賞のない本では、「受賞」の行そのものを出しません。「なし」とは書きません。賞を取っていないのではなく、データがないだけかもしれないからです。
- あらすじ、レビュー、AI の紹介文は出しません。Foundation Models は、本の中身について作り話をしました（docs/reviews/001-reading-session-reselect-tech-lead.md の 3）。
- データの出どころ
  - 出版社：ISBN から openBD で引きます（通信が要ります）。背表紙の写真のときは、背表紙の下の行で補います。Vision は、題名、著者、出版社を別々の行で返しました（同じ tech-lead の報告の 2 と 6）。
  - 受賞：Wikidata だけでは足りません。2026-10-18 に SPARQL で数えた結果は次のとおりです（R-12）。
    - 芥川龍之介賞：受賞の記録のある項目が201件。そのうち作品の項目は23件、作品を示す修飾（P1686）は14件だけ
    - 直木三十五賞：68件。作品の項目は18件
    - 本屋大賞：13件。作品の項目は8件
  - 公式の受賞作の一覧から作った表を、アプリに入れておく必要があります。作る手間と、毎年更新する手間は、tech-lead と pdm に要確認です。Wikidata の構造化データは CC0 です（R-12）。

### 3-2. おすすめ（「これを読んだ人は」）
- **置き場所**：「次の1冊」の枠を1つだけ持ちます。出るのは、読み終えた瞬間と、本棚の「次を選ぶ」のときだけです。3冊までで、1冊ごとに事実1行を添え、「ほかの本にする」を置きます（前の報告の G-4）。読んでいる途中には出しません。
- **出どころの段**（利用者0人の日は上から使います）

| 段 | 出どころ | 0人の日に使えるか | 理由の1行の例 |
|---|---|---|---|
| 1 | 自分の積読（いちばん先に出す） | 使える | 「積読から。同じ著者」「積読から。p.1から約15分」 |
| 2 | 友人が読み終えた本と、友人がその次に読んだ本 | 友人が1人いれば使える | 「ゆうこさんが、この本の次に読んだ本」（友人1人から成り立つ「これを読んだ人は」） |
| 3 | アプリに入れた受賞の表 | 使える（通信なし） | 「同じ〇〇賞の、次の年の受賞作」 |
| 4 | 著者とシリーズ（書誌） | 使える（通信は書誌を取るときだけ） | 「同じ著者の次の作品」 |
| 5 | 2段目のバーコードの分類（Cコード） | 使える（通信なし） | 「同じ分類（文庫、日本文学）」。根拠が弱いので最後に回す |
| 6 | 利用者の集計「この本を読み終えた人が次に開いた本」 | 人数がそろってから | 「この本を読み終えた34人のうち、9人が次に開いた本」 |

- **言葉を正直にする**
  - 「これを読んだ人は」という言葉は、段6で本当の人数を出せるときだけ使います。
  - 段2では「ゆうこさんは」と名前で言います。
  - それ以外の段では、枠の名前を「次の1冊」にし、理由の行に本当の出どころを書きます。性格語「確か」と、Dieter Rams の「正直」に合わせるためです。
- **段6の条件**
  - サーバーと、匿名にした集計が要ります。利用者が自分で選んだときだけ集計に入れます。
  - 何人以上なら出すかの線（例：20人以上）を決めます［推測］。
  - プライバシーの申告も要ります。tech-lead と pdm に要確認です。
- **持っていない本のとき**：段2〜6の本は「積読に加える」にし、v1 では買うためのリンクを置きません。店にしないためです。アフィリエイトにするかは pdm が決めます。
- **似た先行**：Readpick は「積んである本の中から、いま読むべき1冊を名指しします」と書いています（前の報告の R-9）。違いは3つです。
  - 候補を3冊にし、理由を事実で書くこと
  - 友人と受賞を出どころに入れること
  - 出すのを、読み終えた瞬間だけにすること
- **空のとき**
  - 積読が0冊なら、文は「積読はありません」、ボタンは「本を加える」です。
  - 段3と段4の本は、自分の本棚になくても「積読に加える」の形で出せます。
- **通信がないとき**：書誌を取れない本は、書名と著者だけを出し、あとで自動で埋めます。受賞の表はアプリの中にあるので、通信がなくても出ます。

## 4. 登録の流れ
### 4-1. 3つの道
| 道 | いつ使うか | 何冊を何秒で［推測］ | 確かさ | 許可と通信 |
|---|---|---|---|---|
| バーコード（DataScanner で続けて読む） | 手元の本を1冊ずつ | 1冊4〜6秒、10冊で40〜60秒。かかる時間のほとんどは、本を取って裏返す手間 | 高い。ISBN で版まで分かる。2段あるバーコードのうち、上の 978、979 で始まるものだけを使う（tech-lead の報告の 1） | カメラの許可が1回。書誌は openBD（通信が要る）。通信がなければ ISBN だけ残し、あとで埋める |
| 背表紙の写真（1枚に積読の山か棚） | 積読をまとめて加える | 撮るのに約3秒。読み取りは Mac で1枚0.25〜0.36秒、初回だけ22.69秒（iPhone では測っていない）。読み違えた本を1冊約5秒で直すとして、10〜15冊で30〜60秒 | 本物の棚では未検証（確かめ1）。ISBN がないので版はあいまいになり、出版社は背表紙の下の行で補う | カメラの許可が1回。写真ライブラリから選ぶ道なら許可は要らない（PhotosPicker。tech-lead の報告の 5） |
| 書名で探す | 電子書籍、図書館の本、手元にない本 | 1冊10〜20秒。かな漢字の変換と、版の選び直しを含む | 中くらい。国立国会図書館サーチでは、上位5件が別の版や全集だったことがある（tech-lead の報告の 2） | 許可は要らない。通信が要る |
| 友人のリンク | 友人に勧められた本 | 1タップ、約1秒 | 高い（書誌の ID がそのまま来る） | 通信が要る |

- 参考：ブックカタログは「一度に最大40冊」「500冊のライブラリは約13枚の棚の写真です」と説明しています（前の報告の R-9）。

### 4-2. 最初に開いたとき
| # | 画面 | すること | 秒［推測］ |
|---|---|---|---|
| 1 | 「いま読んでいる本を1冊」 | 主操作は「バーコードを読む」、そのほかに「書名で探す」。説明の画面は置かない（R-6 の「fast, fun, and optional」） | 約2 |
| 2 | システムのカメラの許可 → バーコード | 許可は、ボタンを押したときに求める（R-7 の「wait to request permission until people actually use an app feature that requires access」） | 約2＋約4 |
| 3 | 「この本です」 | 書名、著者、出版社の1行を見て押す | 約2 |
| 4 | 「どこまで読みましたか」 | 主操作は「止めたページを撮る」（続きの一行とページが取れる）、そのほかに「ページ数を入れる」「はじめから」 | 約5〜8 |
| 5 | しおりの画面 | 自分の本の続きの一行が出る。その下に「ロック画面にも出せます」の1行を置き、押すと加え方の説明が出る | - |

- 合計は約20〜30秒です［推測］。書名で探すときは約25〜35秒です。
- アプリから自動でウィジェットを加えることはできない見込みです［推測。tech-lead に要確認］。
- 最初の流れに入れないもの
  - 積読をまとめて加えること：最初の本を読み終えたときか、本棚から勧めます。
  - 友人：最初の本を読み終えた奥付の画面で、「手渡す」を初めて見せます。
  - 通知：出しません。
- いちばん安い確かめ方：Takuma の手元の10冊で、バーコードと背表紙の写真のそれぞれにかかる秒数を測ります（15分ほど）。確かめ1（背表紙の読み取り）と一緒にできます。

## 5. 象徴の瞬間
| # | 瞬間 | 10秒の芯 | いまの試作との関係 |
|---|---|---|---|
| S-1 | 続きの一行（毎晩） | 手に取る → ロック画面の縦書きの一行 → 伏せる → 本を開く → 起こすと「p.43 → p.61　18分」と「同じ夜、ゆうこさんも本を開いていました。」 | c1 を使い回し、最後の1枚に1行だけ足す。友人がいることを、フィードなしで見せられる |
| S-2 | 自分の本の活字 | ロック画面の一行が、自分の本のページから切り出した活字そのもの | c1 を変える版。文字を読み取って組み直すのではなく、行の画像を切り出せば、ルビ付きの本文の読み取りが要らない。VoiceOver のために、文字の読み取りは別に要る。tech-lead に要確認 |
| S-3 | 読み終えた夜 | 最後のページを閉じる → 奥付が5行（出版社、受賞） → 積読の山にカメラを向ける → 次の1冊に線1本と事実1行「ゆうこさんが読み終えた本」 → その本を抜く | c2 を変えて使う。場面を「読み終えた夜」に移し、理由の行を受賞と友人の事実にする |
| S-4 | 1枚で積む | 積読の山を1枚撮る → 背表紙に細い線 → 「12冊を積みました。2冊は確かめてください」 | c2 の前半を、登録の場面として使い回す |
| 捨てる | 夜の盾 | SNS を開くと、本の1ページが出る | c3 は捨てる。理由は3つ。Family Controls に Apple の承認が要ること。止める仕組みは頼まれた機能の外であること。「スマホが手の中にある瞬間」は S-1 のロック画面で取れること。紙の色の画面と縦書きのページ番号という見た目だけ、しおりの画面に使い回す |

- ポートフォリオでは、主役を S-1 の10秒にします。統合した体験は、20〜30秒の「一冊の一生」の絵コンテで見せます（S-4 → 夜を3回早送りした S-1 → S-3）。
- 事例の文章の中心には、次のような判断を置きます。採用する側は、捨てた案と判断を見たがります（前の報告の R-18）［推測］。
  - なぜフィードを作らなかったか
  - なぜ0人の日に「これを読んだ人は」と言わないか
  - なぜ機能をタブではなく瞬間に置いたか
- 確かめ4（6人に3つの10秒を見せ比べる。docs/reviews/001-reading-session-validation-plan.md）は、いま続いています。途中で c1〜c3 を直すと、人によって見たものが変わってしまいます。だから試作は今は直さず、統合した案は別の絵として作ります。

## 6. Apple Design Award
### 6-1. 部門（2025年と2026年は同じ6つ）
- Delight and Fun：「provide memorable, engaging, and satisfying experiences enhanced by Apple technologies」
- Inclusivity：「provide a great experience for all by reflecting a variety of backgrounds, abilities, and languages」
- Innovation：「provide a state-of-the-art experience through a novel use of Apple technologies that sets them apart in their genre」
- Interaction：「deliver intuitive interfaces and effortless controls that are perfectly tailored to their platform」
- Social Impact：「improve lives in a meaningful way and shine a light on crucial issues」
- Visuals and Graphics：「feature stunning imagery, skillfully drawn interfaces, and high-quality animations with a distinctive and cohesive theme」
（R-1、R-2）

### 6-2. 受賞作
| 部門 | 2026 アプリ | 2026 ゲーム | 2025 アプリ | 2025 ゲーム |
|---|---|---|---|---|
| Delight and Fun | grug | Is This Seat Taken? | CapWords | Balatro |
| Inclusivity | Guitar Wiz | Pine Hearts | Speechify | Art of Fauna |
| Innovation | NBA: Live Games & Scores | Blue Prince | Play | PBJ — The Musical |
| Interaction | Moonlitt: Moon Phase Tracker | Sago Mini Jinja's Garden | Taobao | DREDGE |
| Social Impact | Primary: News in Depth | Consume Me | Watch Duty: Wildfire Maps | Neva |
| Visuals and Graphics | Tide Guide: Charts & Tables | Cyberpunk 2077 Ultimate Edition | Feather: Draw in 3D | Infinity Nikki |

- 関係の深い最終候補
  - 2026 Interaction：The Outsiders、Tide Guide、Grand Mountain Adventure 2、TR-49
  - 2026 Inclusivity：Hearing Buddy、Structured、Sago Mini Jinja's Garden、Civilization VII
  - 2025 Interaction：iA Writer、Mela
  - 2025 Social Impact：Opal、Ground News
- 読書のアプリは、2025年と2026年の受賞作にも最終候補にもありません。近いのは、書く道具の iA Writer と、読み上げの Speechify です。

### 6-3. 受賞作の型（紹介文から）
- **W-1 1つの考えを、小さく深く**
  - grug：「no login, no cloud syncing, nothing extraneous — just a simple idea」
  - Moonlitt：「this SwiftUI-built utility brings a simple elegance」
- **W-2 システムの面に乗る**
  - Moonlitt：「best-in-class Liquid Glass integration, and easy onboarding」
  - Tide Guide：「its powerful widgets help swimmers and boat captains save a step right from the Home Screen」
- **W-3 アクセシビリティを名指しで作り込む**
  - Guitar Wiz：「Robust VoiceOver integration」「supports Dynamic Type, Increased Contrast, and Differentiate Without Color to enable people of all abilities to play with autonomy」
  - Guitar Wiz は「all-in-one toolkit」で受賞しています。機能が多くても、すべてに行き届けば勝てる例です。
- **W-4 個人の開発者**
  - Guitar Wiz：「solo developer」
  - Hearing Buddy：「Created by a solo developer with hearing loss」
- **W-5 控えめで、あおらない**
  - Primary：「without once resorting to sensationalism or clickbait」「with a properly minimal UI, Primary wisely gets out of the way」
- **W-6 プラットフォームの幅**
  - Moonlitt：「broad platform support — check it out on Apple Vision Pro」
  - 2025 Interaction の Taobao と、2026 Innovation の NBA は、どちらも Apple Vision Pro のアプリです。
  - 幅が加点になっていると見ます［推測］。

### 6-4. 狙う部門と、3案との比べ
- **主に狙う：Interaction（統合案1）**
  - 伏せる、ロック画面の一行、Controls と Action ボタン、ボタンが1つの Live Activity。どれも「effortless controls … tailored to their platform」に当たります。
  - 型は W-1 と W-2 で、Moonlitt と同じです。
  - 弱い所：Interaction のアプリの受賞は、Vision Pro（Taobao）か、多くのプラットフォームに出ているもの（Moonlitt）です。iPhone だけでは W-6 の幅がありません。幅を出す案はあります（Apple Watch で「終える」、StandBy、iPad）［推測。範囲は pdm と tech-lead が決める］。
- **従に狙う：Inclusivity**
  - W-3 を名指しで作り込みます。縦書きの一行の VoiceOver、縦書きでの Dynamic Type と AX5 での横書きへの切り替え、Increased Contrast、Differentiate Without Color、伏せられない人の道です。
  - 弱い所：読むのは紙の本なので、目の見えない人には中心の価値が届きにくいです。
- **統合案2**：Guitar Wiz の「all-in-one」の型で Inclusivity を狙う筋はあります。Interaction には弱いです（標準の本棚アプリの形だからです）。
- **統合案3**：合う部門がほとんどありません。Social Impact は「crucial issues」が対象で、受賞は山火事、ニュース、心の健康です。スマホの時間を減らす Opal も、2025年は最終候補どまりでした。
- **狙わない部門**
  - Delight and Fun：CapWords のような積読カメラなら近いです。ただ、毎晩の道に演出を置かない方針と逆になります。
  - Visuals and Graphics：縦書きの組みで近づけはしますが、絵とデータの量が少ないです。
  - Innovation：技術の新しさが中心の部門です。

## 7. 推す案：統合案1「一冊のしおり」
### 7-1. 理由
1. 緊張1：毎晩の道に、ほかの機能を出しません。友人が出るのは読んだあとだけです。「1晩にアプリの中にいる時間」に上限を決めて、設計の線にできます（例：真ん中の値で30秒以内［推測］）。
2. 緊張2：機能はブクログなどと同じでも、出す時が違います。ブクログの強みは「250万人の本棚」「感想1,400万件」という人の集まりで（product.md の 4）、こちらはそこでは競いません。入口は「続き」です。
3. 緊張3：おすすめは、積読、友人、受賞、著者の順で、0人の日から埋まります。「これを読んだ人は」の言葉は、人数がそろってから使います。
4. 緊張4：友人は20人まで、自由に書ける文なし、通知なしにします。iCloud の共有なら、自前のサーバーなしで始められる見込みです（tech-lead に要確認）。
5. 緊張5：画面は1つです。機能はシートに分け、どのシートも1つの瞬間に結びつきます（B-1）。
6. 性格語：静か（フィードと通知がない）、確か（事実だけを出す）、まっすぐ（1画面）、手で感じる（伏せる動作と、自分の本の活字）。

### 7-2. 捨てるもの
- フィード、いいね、コメント、フォロー数、ランキング、連続日数、目標、統計の画面
- 友人への通知と、友人どうしで分数やページを比べること
- あらすじ、レビュー、AI の紹介文
- v1 では、外の API から取る表紙の画像と、買うためのリンク
- タブ
- 夜の盾の仕組み（c3）と、光らせる演出
- 「これを読んだ人は」の言葉（人数がそろうまで）

### 7-3. いちばん強い反論
- 続きの一行は、毎晩の終わりに止めたページを撮ってもらうことで成り立ちます。
  - これは「美しさのために手順を1つも増やさない」（product.md の 5）に逆らいます。毎晩、約5〜8秒の手間です。
  - しかも、ルビ付きの縦書きの本文の読み取りは、まだ確かめていません（tech-lead の報告の 7）。
- 撮らない夜が続くと、ロック画面は「書名と p.61」だけになり、ToRead Plus や Bookmory のロック画面の表示と同じになります。
- 主役が崩れると、統合案1は「機能を隠しただけの読書記録のアプリ」になり、緊張2（埋もれる）に負けます。
- 友人がいない人、積読のない人にとっても、統合案1の違いは小さくなります。

反論に答える材料
- 撮るのは読み終えたあとなので、読み始めは遅れません。
- 撮らない「ページ数だけ」の道（約3秒）があります。
- 行の画像を切り出す案（S-2）なら、文字を読み取らなくて済みます（tech-lead に要確認）。
- 確かめ2（7晩の記録）に「止めたページを撮ってもよいと思ったか」を1問足せば、安く確かめられます［推測］。

### 7-4. 次の手で Takuma に見せるもの
1. **統合した流れの絵コンテ**：1枚。横長で8コマにします。
   - 見つける（友人のリンク） → 登録（バーコード） → 積む（山を1枚撮る） → 毎晩1（ロック画面の一行） → 毎晩2（伏せる） → 毎晩3（結果と友人の1行） → 読み終える（奥付） → 次の1冊（積読から3冊）
   - 各コマの下に、そこで出る機能と秒数を書きます。
2. **主な画面の静止画**：iPhone の縦の画面（393×852pt）でライトを6枚、ダークを2枚の、合わせて8枚。
   - ①ロック画面のウィジェット（StandBy の小さな図を添える） ②しおりの画面 ③読書の結果と友人の1行 ④読み終えた（奥付） ⑤次の1冊 ⑥友人の机
   - ダークは①と②の2枚です。
3. **機能の地図**：本の一生×機能×出す量を、表1つにします。絵コンテに添えます。
4. **形**：SVG と PNG です。design/explore/ と同じ描き方（黒、白、灰。縦書きはヒラギノ明朝）にします。置き場所は design/explore/integrated/ を提案します。
5. **10秒の試作**：確かめ4が終わるまで直しません。終わったら、c1 の最後の1枚に友人の1行を足した版を1本作ります（作るかは選べます）。

## 根拠
| R | 発見（引用は「」） | 出典 URL | 開いた日 |
|---|---|---|---|
| R-1 | ADA 2026 の6部門と定義、受賞作、最終候補。紹介文：grug「no login, no cloud syncing, nothing extraneous」、Guitar Wiz「Robust VoiceOver integration」「supports Dynamic Type, Increased Contrast, and Differentiate Without Color」、Moonlitt「simple elegance」「best-in-class Liquid Glass integration, and easy onboarding」「broad platform support」、Tide Guide「save a step right from the Home Screen」、Primary「without once resorting to sensationalism or clickbait」、Hearing Buddy「Created by a solo developer with hearing loss」 | https://developer.apple.com/design/awards/ | 2026-10-18 |
| R-2 | ADA 2025 の6部門、受賞作、最終候補（CapWords、Speechify、Play、Taobao、Watch Duty、Feather。最終候補に iA Writer、Mela、Opal） | https://developer.apple.com/design/awards/2025/ | 2026-10-18 |
| R-3 | HIG Widgets：「Provide useful information in your Lock Screen widget, and don't treat it as an additional way for people to launch into your app.」「People tap or click a widget to launch its corresponding app.」「Deep link to details and actions that directly relate to the widget's content」「inline accessory widgets offer only one tap target」。StandBy は小さなウィジェット2つを大きくして並べ、暗い所では赤みで描く | https://developer.apple.com/design/human-interface-guidelines/widgets （本文は https://developer.apple.com/tutorials/data/design/human-interface-guidelines/widgets.json で読んだ） | 2026-10-18 |
| R-4 | HIG Live Activities：「Only include interactive elements for essential functionality … prefer limiting it to a single」「Live Activities are prominently visible and could be viewed by casual observers」「create an App Shortcut that allows people to start your Live Activity using the Action button on iPhone」 | https://developer.apple.com/design/human-interface-guidelines/live-activities （JSON で読んだ） | 2026-10-18 |
| R-5 | HIG Controls：「People can add controls to Control Center …, to the Lock Screen by customizing their Lock Screen, and to the Action button」「launching a Live Activity from a control creates an easy and seamless experience」「When the device is locked, consider having the system redact the title and value to hide personal or security-related information.」。App Shortcuts：「available immediately when installation finishes」 | https://developer.apple.com/design/human-interface-guidelines/controls 、https://developer.apple.com/design/human-interface-guidelines/app-shortcuts （JSON で読んだ） | 2026-10-18 |
| R-6 | HIG Onboarding：「design a flow that's fast, fun, and optional」「provide an interactive onboarding experience where people can safely test an action」「Provide reasonable default settings so most people can immediately start interacting」 | https://developer.apple.com/design/human-interface-guidelines/onboarding （JSON で読んだ） | 2026-10-18 |
| R-7 | HIG Privacy：「Ideally, wait to request permission until people actually use an app feature that requires access.」「asking for data before a person shows interest in the feature — can make it hard for people to trust your app」 | https://developer.apple.com/design/human-interface-guidelines/privacy （JSON で読んだ） | 2026-10-18 |
| R-8 | 審査ガイドライン 1.2：「Apps that enable users to create, generate, upload, share, or otherwise contribute content … must include: A method for filtering objectionable material … A mechanism to report offensive content … The ability to block abusive users … Published contact information」。5.1.1(v)：「inviting friends to use the app are not considered core app functionality」。5.1.2(v)：「except at the explicit initiative of that user on an individualized basis; do not include a Select All option」。4.3(b)：「simple timers … meaningfully different or improved experience」 | https://developer.apple.com/app-store/review/guidelines/ （前から100,000字だけ読んだ。最後の14,428字は読んでいない） | 2026-10-18 |
| R-9 | mekuru（JP 368件、平均4.69、5.1.0、2026-10-12）：「同じ時間に読んでいる誰かの気配だけが、そっと伝わります」「DM、いいね、コメント、フォロー、ランキングはありません」 | https://itunes.apple.com/lookup?id=6792955764&country=jp | 2026-10-18 |
| R-10 | Locket Widget（id 1600525061、US 580,078件、2021-12-30 公開）：「a widget that shows live photos from your best friends, right to your Home Screen」「you can only have 20 friends on the app」「there's no worrying about follower count」。反応と、送った写真の履歴もある | https://itunes.apple.com/search?term=locket%20widget&entity=software&country=us&limit=3 | 2026-10-18 |
| R-11 | Apple Watch ユーザガイド「Share your activity」：「Tap Hide my Activity.」「Tap Mute Notifications.」「Tap Remove Friend.」。友人が「meet their goals, finish workouts, and earn achievements」したときに通知が来る。ページに版の記載はなく、版の選択の最初は watchOS 27。検索の要約にあった「up to 40 friends」は、このページでは確かめられなかった | https://support.apple.com/en-eg/guide/watch/apd68a69f5c7 | 2026-10-18 |
| R-12 | Wikidata の受賞の数（3-1 の数字）。ライセンスのページに、構造化データは「CC0 license, which is equivalent to public domain」とある | https://query.wikidata.org/sparql （SPARQL、HTTP 200）、https://www.wikidata.org/wiki/Wikidata:Licensing | 2026-10-18 |
| R-13 | 書籍 JAN コード：「日本図書コードはISBNに、分類コードと価格コードを加え」たもの。Cコードの1桁目は読者対象、2桁目は発行形態。検索の要約だけで、日本図書コード管理センターの PDF は落としたが文字を取り出せなかった。2段目が「192」で始まる決まりは確かめていない | https://isbn.jpo.or.jp/doc/「分類記号・各コードの内容解説・注意事項」_2025.04.01.pdf （開いたが本文を読めていない）、https://www.city.higashiyamato.lg.jp/_res/projects/default_project/_page_/001/003/427/20140331-134030.pdf （要約のみ） | 2026-10-18 |
| - | リポジトリの前の調べもの：tech-lead の報告（Vision の読み取り、2段のバーコード、openBD、国立国会図書館サーチ、Foundation Models の作り話）、designer の前の報告（P-6、G-1〜G-8、Readpick、ブックカタログ）、research（性格語、ToRead の R-1、伏せた向きの R-11）、pdm-core の 4（つまずく所の大きさ、案 A の流れ）、product.md、試作の README と index.html | docs/reviews/001-reading-session-reselect-tech-lead.md、docs/reviews/001-reading-session-reselect-designer.md、design/001-reading-session-research.md、docs/reviews/001-reading-session-reselect-pdm-core.md、docs/prd/product.md、design/explore/concepts/ | 2026-10-18 に読んだ |

## 変更したファイル
- リポジトリ：なし
- スクラッチパッド（リポジトリの外。調べものの元データです）：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/integrate-designer/
  - scripts/hig.py（HIG の JSON を落として段落を抜き出す）、scripts/pdftext.swift（PDF の文字を取り出す。うまくいかなかった）
  - dl/hig/（widgets、live-activities、onboarding、privacy、controls、app-shortcuts の JSON）
  - dl/wd/（awards.json、lic.html）
  - dl/itunes/（locket.json、mekuru.json）
  - dl/jpo/ccode.pdf

## 実行したコマンドと結果
実行した順に書きます。日付はすべて 2026-10-18 です。
- Read：design/001-reading-session-research.md、design/explore/README.md、design/explore/concepts/README.md、docs/reviews/001-reading-session-reselect-designer.md、docs/prd/product.md、docs/reviews/001-reading-session-reselect-pdm-core.md（0 と 4）、docs/reviews/001-reading-session-validation-plan.md、docs/reviews/001-reading-session-reselect-tech-lead.md（結論〜質問）
- Bash：`grep -n "^## \|^### "`（pdm-core の見出し）と `ls design docs/reviews`。`grep -n "T-[1-8]"`（angles-designer）
- WebFetch https://developer.apple.com/design/awards/ ：2026 の6部門、受賞作、最終候補が取れた。2回目で紹介文の全文が取れた
- WebFetch https://developer.apple.com/design/awards/2025/ ：2025 の6部門、受賞作、最終候補が取れた
- Bash `python3 -I …/scripts/hig.py`：HIG の JSON 6ページ（widgets、live-activities、onboarding、privacy、controls、app-shortcuts）がすべて取れた。出力が大きかったので、保存された出力を grep した
- WebFetch https://developer.apple.com/app-store/review/guidelines/ ：1.2、1.2.1、4.3(b)、5.1.1(v)、5.1.2(iv)(v) が取れた。最後の14,428字は読んでいない
- WebSearch「Apple Support share your Activity rings with friends …」：要約だけを読んだ。iPhone 向けの記事（https://apple.co/32Z38Dv ）は開いていない
- Bash `curl https://query.wikidata.org/sparql`：HTTP 200。受賞の数が取れた。`curl https://www.wikidata.org/wiki/Wikidata:Licensing`：HTTP 200。CC0 の文が取れた
- WebFetch https://support.apple.com/en-eg/guide/watch/apd68a69f5c7 ：取れた
- Bash `curl` で iTunes の search（locket widget、US）と lookup（mekuru、JP）：どちらも HTTP 200
- WebSearch「書籍JANコード 2段目 192 Cコード …」：要約だけを読んだ
- Bash `curl` で日本図書コード管理センターの PDF：HTTP 200、445,765バイト。`swift …/pdftext.swift` では、6ページから13行しか取れず、本文を読めなかった（開けなかったのと同じ扱いにした）
- Bash `grep` と `sed`（design/explore/concepts/index.html）：c1 の .vline（top:21%、font-size:2.6em）と .result の位置を確かめた

## 未解決
1. **Takuma に決めてほしいこと：統合案1「一冊のしおり」で、絵コンテと静止画に進むか**
   - 推奨：進む。
   - いちばん強い反論：毎晩、止めたページを撮る手間と、まだ確かめていない読み取りに、主役が頼っている（7-3）。
   - 元に戻せるか：戻せる。まだ何も描いていない。
   - 見てほしい所：この報告の 1-1 と 7。
2. **Takuma に決めてほしいこと：友人の決まり**
   - 決めてほしいのは、20人まで、自由に書ける文なし、通知なし、分数とページを出さない、という形でよいか。
   - 推奨：この形。
   - いちばん強い反論：物足りないかもしれない。Locket には反応と履歴があり、Apple のアクティビティ共有には通知がある。
   - 元に戻せるか：戻せる。足すのはあとからでもできる。
3. **Takuma に決めてほしいこと：「これを読んだ人は」の言葉を、人数がそろうまで使わないか**
   - 推奨：使わない。それまでは「次の1冊」と、本当の出どころを書く。
   - いちばん強い反論：Takuma の言葉どおりの機能が、最初は画面に出ない。
   - 元に戻せるか：戻せる。
4. **Takuma に確かめたいこと**：「これを読んだ人は」で欲しいのは、新しい本を見つけることか、手元の積読から選ぶことか。答えによって、段1（積読）を先に出すか、段2〜4（持っていない本）を先に出すかが変わります。
5. **tech-lead に要確認**
   - ロック画面のウィジェットに縦書きの一行を組めるか。枠の大きさ、StandBy での見え方、ロック中に隠す作り。
   - 夕方から一行を出す仕組み（ウィジェットの更新の予定、決まった時刻に Live Activity を始められるか）。
   - Controls と Action ボタンで、アプリを開かずに読書を始められるか。
   - 止めたページの写真から、ページ番号と止めた行を取れるか（ルビ付きの縦書きの本文）。行の画像を切り出して出す案（S-2）と、その画像をダークモードで文字の形だけにする処理。
   - 友人：iCloud の共有（CKShare）で自前のサーバーなしにできるか。名前の出どころ、同期の遅れ、手渡しのリンクに要るドメイン。
   - 受賞の表をアプリに入れる作りと、毎年の更新。openBD で出版社を取る条件。
   - 2段目のバーコードから Cコードを取ってよいか。公式の文書で確かめる。
   - アプリから自動でウィジェットを加えられるか。
6. **pdm に要確認**
   - ガイドライン 1.2 が、本の ID と「開いたか」だけを分け合う作りにもかかるか。かかるなら、友人の行に「報告」と連絡先を足す。
   - 段6の集計を出す人数の線と、プライバシーの申告。
   - 入力指標に「1晩のアプリの前面の時間（真ん中の値）」を足すか。
   - 友人の機能を v1 に入れるか、後の版にするか。
7. **確かめ4との関係**：いまの試作（c1〜c3）は、確かめ4が終わるまで直さないことを指揮役に勧めます。直すと、人によって見たものが変わってしまうためです。
8. **見ていないもの**
   - 読書メーター、ブクログ、Goodreads の友人とおすすめの画面（pdm の機能の地図に任せた）
   - Locket の画面（説明文だけ見た）
   - iPhone のフィットネスアプリの共有の記事（Apple Watch のガイドだけ見た）
   - 日本図書コード管理センターの PDF の本文
   - 審査ガイドラインの最後の14,428字
   - ロック画面のウィジェットの実際の大きさ（文書の数字は見ていない）
   - 実機。秒数はすべて見積もりで、測っていない
9. **テンプレートの「確かめ」**：この仕事は、文書を書かない調べものなので、design-research と design-spec のテンプレートの「確かめ」には印を付けていません。絵コンテと静止画に進むときに、design/explore/ の README に書きます。

## 記録（指揮役が保存するときに書き足す）
- 種類：機能を統合した体験を検討するための調べもの（designer）。PASS / FAIL なし
- 対象：Takuma の指示（2026-10-18。docs/approvals/001-reading-session-G0-Q8.md の最後の節）。BASE=ab9ffa5c2c4567906d92f82aac4cebfff3eea4da
- 日付：2026-10-18
