（指揮役の注）これは判定ではなく、方向の見直しのための調べもの（designer）の報告。担当は Apple Design Awards（ADA）の傾向と、角度①〜④の賞の筋と独自性。報告の文はそのまま保存した。

# 調べもの その4：ADA の傾向と、角度①〜④の賞の筋と独自性（designer、2026-10-16）

リポジトリのファイルは書いていませんし、直してもいません。この文書の確認日はすべて 2026-10-16 です。点の付け方は「賞の筋、独自性、性格語との合い方」をそれぞれ1〜5点で付け、合計は15点満点です。

## 0. 結論
- **ADA が賞を出すアプリ：** 特定の人のはっきりした困りごとを、標準の機能（Dynamic Type、VoiceOver、触覚、ウィジェット）を深く使って、飾らずに解いたアプリです。
- **読書のアプリは受賞も最終候補もない：** 2023〜2026年に、読書の記録、読書タイマー、ハイライトのアプリは一つもありません。読むことにいちばん近い受賞は Speechify（2025年 Inclusivity）です。
- **①と②は日本に先行がある：** どちらも、同じ「象徴の瞬間」を出すアプリが日本にあります。「日本にない」は当たりません。
  - ①は Pause（2026-06-25 公開）の「開く前に、読書という選択肢。」です。Opal と one sec も、日本語で JP のストアに出ています。
  - ②はよみかえし（2026-07-18 公開）の「読んだ本を、忘れない。」「撮るだけ。毎日1枚、もどってくる。」です。縦書きにも対応しています。
- **③は賞の筋がいちばん強いが、独自性がない：**
  - 2025年の受賞作 Speechify がすでに同じことをしていて、日本語にも対応しています。
  - Apple も 2025年に、拡大鏡にアクセシビリティリーダーを組み込み、OS の機能にしました（「like in books」）。
  - 違いが残るのは、日本語の縦書きの本で両方がうまく動かない場合だけです。ここは確かめていません。
- **④は独自性がいちばん高い：**
  - 海外の先行は、AI が画面の中の本を読む子どもを直す道具です（Google の Read Along は Android とブラウザ、Ello は英語だけ）。
  - JP の先行はおんどくノート（評価3件）だけで、紙のカードを画面に写した形です。
  - 賞の筋は中くらいです。子ども、文化、控えめさを評価した受賞はありますが、アプリの部で同じ種類の受賞はありません。
- **designer が推すのは④です。** 理由といちばん強い反論は 5 に書きました。ただし、pdm が需要を確かめることと、Takuma が対象を「小学生の子と親」に変えると決めることが前提です。

## 1. ADA 2023〜2026 の受賞と最終候補
### 1-0. 出典と部門の定義
**出典**（4つとも curl で HTTP 200 が返り、HTML を文字にして読みました）
- 2026：https://developer.apple.com/design/awards/
- 2025：https://developer.apple.com/design/awards/2025/
- 2024：https://developer.apple.com/design/awards/2024/
- 2023：https://developer.apple.com/design/awards/2023/

**ページの制約**
- 2024年と2023年は、最終候補の名前だけが載っていて、理由の文はありません。
- 2023年のページは国を載せていません。
- 2023年と2024年の最終候補は、アプリかゲームかの区別がページにありません。並び順から「前の2つがアプリ」と読みました。

**部門の定義**（2026年のページ）
- Delight and Fun：「provide memorable, engaging, and satisfying experiences enhanced by Apple technologies」
- Inclusivity：「provide a great experience for all by reflecting a variety of backgrounds, abilities, and languages」
- Innovation：「provide a state‑of‑the‑art experience through a novel use of Apple technologies that sets them apart in their genre」
- Interaction：「deliver intuitive interfaces and effortless controls that are perfectly tailored to their platform」
- Social Impact：「improve lives in a meaningful way and shine a light on crucial issues」
- Visuals and Graphics：「feature stunning imagery, skillfully drawn interfaces, and high-quality animations with a distinctive and cohesive theme」

### 1-1. アプリの部（W は受賞、F は最終候補）
**Inclusivity**
- 2023：
  - W：Universe — Website Builder「a fantastic implementation of Dynamic Type and VoiceOver, and supports building websites in more than 17 languages. By consistently reducing complexity and removing barriers to entry」
  - F：Anne、Passenger Assistance
- 2024：
  - W：oko「alerts pedestrians to the state of lighted signals through haptic and audio feedback, an immediately impactful approach for those with low to no vision … flawless VoiceOver and Dynamic Type implementation」
  - F：Complete Anatomy 2024、Tiimo
- 2025：
  - W：Speechify「turns any written text into audio — everything from websites, documents, scans, PDFs … auditory learners and people with low vision … worked to reduce cognitive load … a critical resource that helps people live their lives」
  - F：Evolve（LGBTQ+ 向け）
  - F：Train Fitness「eliminating the need for interaction with a screen or UI」
- 2026：
  - W：Guitar Wiz「Robust VoiceOver integration … Dynamic Type, Increased Contrast, and Differentiate Without Color to enable people of all abilities to play with autonomy」
  - F：Hearing Buddy「Created by a solo developer with hearing loss, Hearing Buddy is shaped by experience」
  - F：Structured「Members of the neurodivergent community have praised Structured for its simple layout」

**Social Impact**
- 2023：
  - W：Headspace
  - F：Duolingo、Sago Mini First Words
- 2024：
  - W：Gentler Streak「powered not by insistent reminders but an optimistic and encouraging vibe … less about hard comparisons and more about progress」
  - F：How We Feel、Ahead
- 2025：
  - W：Watch Duty（山火事）
  - F：Ground News
  - F：Opal「helps people establish a more intentional relationship with technology by encouraging less time on devices … haptics when unlocking "gems"」
- 2026：
  - W：Primary「without once resorting to sensationalism or clickbait … a properly minimal UI」
  - F：Katha Room「A bedtime stories app from India … a commitment to cultural representation」
  - F：Harvee「on-device foundation models, sensitive health data stays secure」

**Interaction**
- 2023：
  - W：Flighty「a look that mirrors time-honored airport design conventions」
  - F：Shuffles、Tide Guide
- 2024：
  - W：Crouton「its effortless series of interactions mean people can keep their focus on the counter rather than their screen」
  - F：Procreate Dreams、Arc Search
- 2025：
  - W：Taobao（visionOS）
  - F：iA Writer「helping people tune out interruptions and focus on the words」
  - F：Mela「recipe scanning is powered by the Vision framework」
- 2026：
  - W：Moonlitt「this SwiftUI-built utility brings a simple elegance」
  - F：The Outsiders、Tide Guide

**Delight and Fun**
- 2023：W Duolingo「committed to their learning streak」。F：CREME
- 2024：W Bears Gratitude。F：Rooms、Dudel Draw
- 2025：
  - W：CapWords「Learn the name of a thing by taking a picture of it」
  - F：Lumy「simple design, carefully curated color palette」
  - F：Denim「custom haptics」
- 2026：
  - W：grug「no login, no cloud syncing, nothing extraneous — just a simple idea」
  - F：Blippo+、Metaballs

**Visuals and Graphics**
- 2023：W Any Distance。F：Gentler Streak、Riveo
- 2024：W Rooms。F：Sunlitt、Meditate
- 2025：
  - W：Feather
  - F：Vocabulary「A subtle example of excellence … quietly does everything right」
  - F：CellWalk
- 2026：
  - W：Tide Guide「in a crisp, clear manner … save a step right from the Home Screen」
  - F：Caradise
  - F：(Not Boring) Camera「a tactile throwback … giant buttons and haptic scroll wheels」

**Innovation**
- 2023：W SwingVision。F：Camo Studio、Rise
- 2024：W Procreate Dreams。F：Copilot Money、SmartGym、Wavelength
- 2025：W Play。F：Moises、Capybara
- 2026：W NBA（visionOS）。F：D-Day、Detail

**その他**
- 2024年だけ Spatial Computing の部門があります（W：djay）。

### 1-2. ゲームの受賞（名前だけ）
- 2023：stitch.、Afterplace、Railbound、Endling、Resident Evil Village、MARVEL SNAP
- 2024：Crayola Adventures（Inclusivity）「full narration for non-readers or those with reading challenges … reading storybooks」、NYT Games、Rytmos、The Wreck、Lies of P、Lost in Play
- 2025：Art of Fauna、Balatro、DREDGE、Neva、Infinity Nikki、PBJ
- 2026：Pine Hearts、Is This Seat Taken?、Sago Mini Jinja's Garden（Interaction）「a masterclass in intuitive interaction … interactions that require no reading … perfecting something simple」、Consume Me、Cyberpunk 2077、Blue Prince
  - Sago Mini Jinja's Garden は 2026年 Inclusivity の最終候補でもあります。理由は「There's no timer, no to-do lists」です。

### 1-3. 読書、学び、健康、アクセシビリティに近いもの
- **読書：** 受賞は Speechify だけです。最終候補に iA Writer と Vocabulary があります。Readwise は4年のどこにもありません。
- **学び：** Duolingo、CapWords、Sago Mini First Words、Crayola Adventures（ゲーム）
- **健康と心：** Headspace、Gentler Streak、How We Feel、Ahead、Opal、Harvee、The Outsiders
- **アクセシビリティ：** 各年の Inclusivity の受賞（Universe、oko、Speechify、Guitar Wiz）と、Train Fitness、Hearing Buddy、Structured、Tiimo

## 2. 受賞の傾向（アプリの部から読み取ったこと）
- **T-1 対象の人がはっきりしている。** Inclusivity の受賞4件は、どれも特定の困りごとか、言語の幅を名指ししています。4件とも、Dynamic Type か VoiceOver を名指しで評価しています。Hearing Buddy は、作った人が当事者であることも評価されました。
- **T-2 課題が大きい。** Social Impact の受賞は、山火事、扇情的でないニュース、心の健康です。スマホの時間を減らす Opal は最終候補止まりでした。
- **T-3 現実の作業から目を離させない。** 例は Crouton「focus on the counter rather than their screen」、Train Fitness「eliminating the need for interaction with a screen」、iA Writer、Flighty（空港の慣習に操作を合わせた）です。
- **T-4 控えめさが評価の言葉になる。** 例は grug「nothing extraneous」、Vocabulary「quietly」、Primary「properly minimal UI」、Gentler Streak「not by insistent reminders」、Sago Mini「no timer, no to-do lists」です。連続記録を評価した文は、Duolingo（2023年）の1件だけです。
- **T-5 文化の固有性。** 例は Katha Room「cultural representation」、Civilization VII、Despelote です。
  - 4年の受賞と最終候補に、日本の開発者のアプリ（ゲームを除く）は見当たりません。2023年は国の記載がないので、名前から判断しました［推測を含む］。
- **T-6 触覚が質として評価される。** oko、PowerWash Simulator「specific haptic feedback for each hose nozzle」、(Not Boring) Camera、Denim、Vocabulary、Opal です。
- **T-7 2025〜2026年は端末の中の AI。** Hearing Buddy、Structured、Detail、Harvee が Foundation Models を使っています。
- **T-8 自然の時間を扱う小さな道具が繰り返し出る。** Tide Guide、Sunlitt、Lumy、Moonlitt です。

## 3. 角度ごとの評価
### ① スマホを開いた瞬間を、読書に変える
**象徴の瞬間の案**
- SNS を開こうとすると盾の画面が出て、そこには読みかけの本の題と「124ページから」だけがあります。
- 「本に戻る」を押すと盾が閉じ、iPhone を伏せると読書が始まります（001 の A につながります）。

**近い受賞の理由**
- Opal（2025年 Social Impact の最終候補、URL は 1-0）の、上に引いた文です。
- 押しつけない調子は、Gentler Streak（2024年）の「not by insistent reminders」に近いです。

**先行と比べて**
- **Opal**（評価 US 89,826件、JP 3,417件、日本語あり）
  - 画面写真の2枚目が盾の画面で、「Instagram is Blocked by Opal」「You set this rule yesterday. Past you was right.」と ADA 2025 の月桂樹があります。
  - 説明文に「Mindful Block Screens: Discover quotes, puns and more every time you try to open an app」とあり、盾に言葉を出す形はすでにあります。
- **one sec**（US 23,708件、JP 7,645件、日本語あり）
  - 画面いっぱいの介入「Do you still need Instagram?」「17 Attempts to open Instagram.」を出します。
  - 説明文は「uses Shortcuts Automation to toggle a deep breath animation」です。
- **Pause**（JP、18件、平均4.72）
  - アプリの中の画面写真4枚目が、ちょうどこの瞬間です。「開く前に、読書という選択肢。」、黄色の「読書をする」と「アプリを使う」、キャラクターの「長い一日だったね。ここから少し、自分に戻ろうか。」が並びます。
  - 3枚目は「SNSの時間、本なら何ページ？」です。
- **ReadTime**（JP、8件、平均2.88）
  - 読書の時間をコインに換え、ロック中のアプリの時間と交換します。画面は見ていません。
- **盾の画面の作りの制約**
  - 変えられるのは、背景のぼかしと色、アイコン、題、副題、ボタン2つだけです。ShieldConfiguration には「The system provides a default appearance for any properties you set to nil.」とあります。
  - どのアプリの盾も同じ型になり、見た目で違いを出しにくいです。
  - 盾のボタンから自分のアプリを開けるかは、確かめていません。
- **判定：** 独自に見えません。

**性格語との合い方**
- 静か：△（割り込むことが仕組みそのもの）
- 確か：○
- まっすぐ：△（最初に許可を求め、止めるアプリを選ぶ）
- 手で感じる：△（瞬間が画面の上で起きる）

**手順が増える危険：高い**
- 手間を足すこと自体が仕組みです（one sec「adds friction」）。
- requestAuthorization は「the device tries to authorize that individual using Face ID or Touch ID」で、許可のダイアログが出ます。001 の AC-24 と合いません。
- Family Controls の entitlement は「Before submitting your app to the App Store, you must … to use the entitlement」と、提出の前に Apple への手続きが要ります。抜き出した文ではリンクの語が抜けています。

**点：賞の筋 2、独自性 1、性格語 2**

### ② 読んだことを忘れない
**象徴の瞬間の案**
- 紙の一行に指を当てて撮ると、その一行だけが残ります。
- 3週間後、ロック画面の小さな枠に、その一行が本の題とページだけを添えて戻ってきます。

**近い受賞の理由**
- Vocabulary（2025年 V&G の最終候補）「quietly does everything right」
- CapWords（2025年 D&F の受賞）「Learn the name of a thing by taking a picture of it」
- Tide Guide（2026年 V&G の受賞）「save a step right from the Home Screen」

**先行と比べて**
- **Readwise**（US 1,513件。英語だけで、JP は19件、平均2.89）
  - 画面写真は「Daily Review」と、撮った紙のページに黄色の線を引いた「Capture new quotes from paper books」です。
  - 説明文は「Spaced Repetition and Active Recall」です。
- **よみかえし**（JP、0件）
  - 見出しは「読んだ本を、忘れない。」「打ち込まない。撮るだけ。」「ホーム画面にも、今日の1枚。」です。
  - 説明文に「日本語の縦書きにも対応しています」「冊数も、読了日も、星評価も、積読リストもありません」とあります。
  - 画面は、生成りの地に太い黒の見出しです。
- **Quotelog**（JP、0件）
  - 「なぞるだけで簡単スムーズにテキスト化」とあります。画面は見ていません。
- **判定：** 独自に見えません。角度の言葉まで、よみかえしと同じです。

**性格語との合い方**
- 4語とも合います。

**手順が増える危険：中**
- 毎日の通知と、戻ってくるときの動きが、飾りになりやすいです。

**点：賞の筋 2、独自性 2、性格語 5**

### ③ 読みにくくなった目でも、紙の本を
**象徴の瞬間の案**
- 文庫本のページを撮ると、その人の文字の大きさで、元の順のまま組み直されます。縦書きの本も正しい順で読めます。
- 読み上げると、いまの行が光ります。

**近い受賞の理由**
- Speechify（2025年 Inclusivity の受賞）と oko（2024年）の、上に引いた文です。

**先行と比べて**
- **Speechify**（US 526,347件、JP 4,431件、日本語あり）
  - 説明文に「Listen to Any Book on Your Shelf — Use the app to snap a pic of a page in any book or printed material and hear it read out loud to you」「Designed to help people with dyslexia, ADHD, low vision acuity…」とあります。
  - 画面写真の最初の4枚は、「Read 3x Faster by Listening」「Choose from 200+ Voices」（有名人の声）「Read More in Less Time」と、速さを売っています。
  - 撮る画面は、最初の4枚にありませんでした。
- **Apple**（2025-05-13 の発表）
  - 「Accessibility Reader can be launched from any app, and is built into the Magnifier app for iOS, iPadOS, and macOS, so users can interact with text in the real world, like in books or on dining menus」
  - 画面は見ていません。日本語と縦書きでどう動くかも、確かめていません。
- **JP**
  - SeeAll（0件）、大きなテキスト（108件）があります。
  - Read Along（作者 Eric Tee、0件）は、撮った文字を OpenDyslexic の書体に変えます。
  - どれも画面は見ていません。
- **判定：** 中心の機能は、受賞作と OS がすでに持っています。残る違いは、縦書きと振り仮名の扱いだけで、確かめていません。

**性格語との合い方**
- 静か：○
- 確か：△（読み違えると、読むための道具として信頼を失う）
- まっすぐ：○
- 手で感じる：○

**手順が増える危険：低い**
- ただし、縦組みで組み直すなら独自に描くことになり、Dynamic Type と VoiceOver への対応を自分で作る必要があります（前回の候補 E と同じ問題です）。

**点：賞の筋 5、独自性 1（縦書きの穴が確かめられれば 3）、性格語 4**

### ④ 音読の宿題を、親子の楽しい時間に
**象徴の瞬間の案**
- 夜、台所で手を止めた親が、子どもが夕方に読んだ3分を聞きます。
- 聞き終えて判を長押しすると、触覚が1回返り、今日の欄に判が付きます。翌朝、子どもがそれを見ます。
- 子どもが読むあいだ、iPhone は伏せてあり、子どもは教科書を見ます（001 の「伏せる」をここで使います）。
- 判は朱肉の質感をまねせず、形と文字と触覚だけで表します。

**近い受賞の理由**
- Sago Mini Jinja's Garden（2026年 Interaction の受賞、ゲーム）「interactions that require no reading … perfecting something simple」
- Crouton（2024年）「focus on the counter rather than their screen」
- Katha Room（2026年 Social Impact の最終候補）「commitment to cultural representation」
- Crayola Adventures（2024年 Inclusivity の受賞、ゲーム）「reading storybooks」
- Gentler Streak「less about hard comparisons」

**先行と比べて**
- **Google の Read Along**
  - Android のアプリとブラウザ版です（検索結果の要約から。記事は開いていません）。
  - App Store の検索（US と JP）の上位に、Google のものは出ませんでした。画面は見ていません。
- **Ello 2.0**（US、2026-05-01、29件、平均3.86、英語だけ）
  - 説明文は「Ello listens to your child, catches mistakes」です。
  - 画面写真は、画面の中の本の文、星の点数（32、126、324、85）、キャラクター、「Daily Quests」です。
- **おんどくノート**（JP、2025-01-16、3件、広告あり、公開後の更新なし）
  - 画面は、紙の音読カードの表をそのまま写したもので、列は「日付、よむところ、録音、サイン」です。
  - ほかに、どんぐりやカエルのスタンプ、「カエル先生」と4桁のパスワード、「録音する、聞く、消す」の画面があります。
- **判定：** 独自に見えます。「紙の教科書を、画面を見ずに読み、親が聞いて判1つで返す」形は、AI が直す海外の道具とも、表を写した JP の道具とも違います。
  - ただし、学校の GIGA の端末で録音して先生に出す学校があるかは、見ていません。

**課題の根拠**
- 根拠は編集記事1本だけで、量を測った調査ではありません。記事はスクールコンパス編集部のもので、公開日の記載はありません。
  - 「夕食の支度をしながら「はい、聞いてるよ」と返し、カードにサインをする。音読の宿題が、こうした流れ作業になっているご家庭は多いと思います。」
  - 「サインだけして、中身は聞いていない日がある。そのたびに、少し後ろめたい。」
  - 「毎日3分を、毎日ちゃんと聞ける家のほうが少ないです。」
  - https://eleschool-compass.com/education/tsumazuki/ondoku-imi.php

**性格語との合い方**
- 静か：△から○（アプリが音、点数、キャラクターを足さない、という意味にすれば合う）
- 確か：○
- まっすぐ：○
- 手で感じる：○
- 性格語は大人を対象に決めたので、子どもと親に合うかは見直しが要ります。

**手順が増える危険：中から高**
- 子ども向けのアプリは、点数とスタンプに流れやすいです。
- 親の手順が、紙のサイン（1秒）より増えます。

**点：賞の筋 3、独自性 4、性格語 3**

### ⑤ 追加の角度：足しません
- **読み聞かせの記録：** 「絵本の読み聞かせ記録 ユリウス」（JP、4,807件、平均4.76）が強い先行です。
- **自然の時間の道具（T-8 の型）：** 課題と需要の物語になりません。

## 4. 比べの表
| 角度 | 象徴の瞬間 | いちばん近い受賞の理由 | 同じ瞬間の先行 | 賞の筋 | 独自性 | 性格語 | 合計（15点満点） | 手順が増える危険 |
|---|---|---|---|---|---|---|---|---|
| ① | 盾の画面に、読みかけの本とページ | Opal（2025年 SI の最終候補） | Pause（JP、同じ） | 2 | 1 | 2 | 5 | 高い |
| ② | 撮った一行が、3週間後にロック画面へ | Vocabulary（2025年 V&G の最終候補） | よみかえし（JP、同じ） | 2 | 2 | 5 | 9 | 中 |
| ③ | 撮った文庫のページが、自分の文字の大きさで | Speechify（2025年 Incl の受賞） | Speechify（日本語あり）と OS の機能 | 5 | 1 | 4 | 10 | 低い |
| ④ | 親が3分を聞き、判を長押し | Sago Mini（2026年 Int の受賞）、Crouton、Katha Room | おんどくノート（3件。形が違う） | 3 | 4 | 3 | 10 | 中から高 |

## 5. designer として推す角度：④
### 理由
1. 海外の先行と日本の先行の、どちらとも違う形を取れるのは④だけです。①と②は日本に同じ瞬間があり、③は受賞作と OS が同じことをしています。
2. ADA が評価してきた型（T-3 画面を見ない、T-4 控えめ、T-5 文化、T-6 触覚）を、1つの場面に重ねられます［推測］。
3. 001 の「伏せる」に、「子どもに画面を見せず、紙の教科書を読ませる」という強い理由が生まれます［推測］。
4. 「日本になく、海外で発展している」という Takuma の見立てに合うのは、④だけです。

### いちばん強い反論
- 音読カードは学校に出す紙で、サインは1秒で終わります。アプリは「録音、聞く、判」の3手を足し、紙のサインもなくなりません。Forest の不満と同じ形になるおそれがあります。
- 親の負担を示す根拠は記事1本だけで、何割の家庭が困っているかはわかっていません。
- GIGA の端末で録音して先生に出す学校が多ければ、それが代わりになります（見ていません）。

### 推す前提
- pdm が需要を確かめること。
- Takuma が対象を変えると決めること。product.md の 1、2、5 が変わります。
- 子どもの声は端末の中だけに置くこと。ガイドラインの 5.1.4 に「Apps intended primarily for kids should not include third-party analytics or third-party advertising」とあります。
  - Kids カテゴリーに入れるなら、1.3 の「links out of the app, purchasing opportunities, or other distractions」を、保護者の確認の後ろに置く決まりにも従います。
- 次点は③です。Takuma の iPhone で、拡大鏡のアクセシビリティリーダーに縦書きの文庫本のページを読ませてみてください（15分ほど）。正しい順で読めなければ、③の独自性が上がり、賞の筋がいちばん強い角度になります。

## 変更したファイル
- リポジトリ：なし
- スクラッチパッド（リポジトリの外。見るためのデータです）
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/designer2/dl/ada/ ：ADA の HTML 4つ
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/designer2/text/ ：上の HTML を文字にしたもの
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/designer2/dl/itunes/ ：検索と lookup の JSON
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/designer2/dl/shots/ ：画面写真
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/designer2/dl/docs/ ：Apple のドキュメントと Newsroom
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/designer2/sheets/ ：画面写真を並べた図4枚
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/designer2/scripts/ ：使ったスクリプト

## 実行したコマンドと結果
確認日はすべて 2026-10-16。上から実行した順です。

- `cat /Users/takumamatsuura/reading-app/.claude/org/app.json` と `ls`
  - 結果：idea は「読む時間そのものが美しくなる、デザイン賞を狙う読書アプリ」でした。
  - Read で docs/prd/product.md と design/001-reading-session-research.md を読みました。
- `curl`（パスに変数を使った最初の版）
  - 結果：ガードに止められました（書き先に $ がある）。パスをそのまま書いて、やり直しました。
- `curl -sL` で ADA の4ページを取得
  - 対象：https://developer.apple.com/design/awards/ と、/2025/ /2024/ /2023/
  - 結果：4つとも HTTP 200。
- `python3 -I .../scripts/html2text.py`（4回）
  - 結果：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/designer2/text/ada_current.txt ほか3つができました（行数は 411、387、373、357）。
  - Read で読み、1 と 2 の引用はここから取りました。
- `python3 -I .../scripts/itunes.py`（検索 API）
  - 対象：https://itunes.apple.com/search?term=opal+screen+time&entity=software&country=us&limit=5 ほか
  - 結果（数は評価の件数）：
    - Opal 89,826、ScreenZen 51,682、one sec 23,708、Readwise 1,513、Speechify 526,347
    - US の「read along by google」に Google のアプリはありませんでした。
    - JP では、Pause、ReadTime、よみかえし、Quotelog、ユリウスが見つかりました。
  - 403 で取れなかったもの：「ello reading」「read instead of scrolling」
- `python3 -I .../scripts/lookup.py`（lookup API）
  - 対象：https://itunes.apple.com/lookup?id=1497465230,1532875441,1476885528,1209815023&country=us （同じ ID で country=jp も）、https://itunes.apple.com/lookup?id=6780103972,6790185992,6790213020,6781592566,1487352741&country=jp
  - 結果：説明文、対応言語、画面写真の URL が取れ、3 の数字と引用はここからです。
  - 403 だった「ello reading」「read instead of scrolling」は、やり直しても 403 でした。
- `python3 -I .../scripts/getshots.py` と `swift .../scripts/compose.swift`（3回）
  - 結果：画面写真24枚を落とし、次の図にしました。
    - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/designer2/sheets/s1_opal_onesec.png
    - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/designer2/sheets/s2_pause_yomikaeshi.png
    - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/designer2/sheets/s3_readwise_speechify.png
  - Read で見ました。3 の画面の記述はここからです。
- `python3 -I .../scripts/docs.py`
  - 対象：https://developer.apple.com/tutorials/data/documentation/managedsettingsui/shieldconfiguration.json （HTTP 200）、.../familycontrols/authorizationcenter/requestauthorization(for:).json （200）、.../bundleresources/entitlements/com.apple.developer.family-controls.json （200）、https://www.apple.com/newsroom/2025/05/apple-unveils-powerful-accessibility-features-coming-later-this-year/ （200）
  - 結果：盾の画面で変えられる項目、Face ID での許可、entitlement、アクセシビリティリーダーの引用が取れました。
  - JP の「音読 記録」で、ユリウス（4,807件）が見つかりました。「音読 宿題」は 403 でした。
- `python3 -I .../scripts/grep_desc.py`
  - 結果：保存した説明文から、Speechify の「snap a pic of a page in any book」、Readwise の「HIGHLIGHT PAPER BOOKS」、one sec の「Shortcuts Automation」、Opal の「Mindful Block Screens」を抜き出しました。
  - JP の「音読 宿題」で、おんどくノートと「大人の音読 毎日宿題」が見つかりました。
  - JP の「read along」に Google のアプリはありませんでした。
  - JP の「音読カード」（limit=25）は 403 でした。
- `python3 -I .../scripts/lookup2.py`
  - 対象：https://itunes.apple.com/lookup?id=6740389182,1552319952,6761912573,6761271180,1545317988&country=jp
  - 結果：おんどくノート（3件、広告あり）、Read Along（作者 Eric Tee）、ユリウスの説明文が取れました。
- `python3 -I .../scripts/kids.py` と `swift .../scripts/compose.swift`
  - 対象：https://itunes.apple.com/lookup?id=6739630070&country=us 、https://itunes.apple.com/lookup?id=6740389182&country=jp 、https://developer.apple.com/app-store/review/guidelines/
  - 結果：Ello 2.0（29件、英語だけ）とおんどくノートの説明文、ガイドラインの 1.3 と 5.1.4 の本文が取れました。
  - 図 /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/designer2/sheets/s4_ello_ondoku.png を作り、Read で見ました。
- WebSearch（3回）
  - 「Read Along の iOS 版」：Android とブラウザ版。iOS 版は確かめられませんでした。
  - 「Ello」：紙の本と画面の本の両方を読む AI のコーチ。
  - 「音読カード 保護者 負担」：スクールコンパスと小樽市の PDF が出ました。
  - 結果に出たが、開いていないページ：
    - [TechCrunch（Read Along の公開）](https://techcrunch.com/2020/05/07/google-launches-read-along-a-free-app-that-helps-young-children-practice-reading)
    - [Android Central](https://www.androidcentral.com/apps-software/google-read-along-web-browser)
    - [ello.com の古いページ](https://ello.com/home-2023-archive)
    - [eSchool News](https://www.eschoolnews.com/newsline/2024/09/26/edtech-startup-ello-named-no-5-on-fortunes-change-the-world-list-2024/)
    - [mwm.ai の Ello のページ](https://mwm.ai/ja/apps/learn-math-and-reading-ello/6739630070)
    - [小樽市の PDF](https://www.city.otaru.lg.jp/docs/2020110900784/file_contents/kateigakusyuhaonndokukara.pdf)
- WebFetch https://eleschool-compass.com/education/tsumazuki/ondoku-imi.php
  - 結果：④の引用3つを、原文で確かめました。公開日の記載はありませんでした。
- 開けなかった URL
  - 検索 API が 403 を返したもの：US の「ello reading」「read instead of scrolling」「ello」、JP の「音読カード」（limit=25 のとき）
- `cd /Users/takumamatsuura/reading-app && git status --short`
  - 結果：出力は空です（変更なし。終了コードは 0）。

## 未解決
1. **Takuma に決めてほしいこと：④を選ぶなら、対象を変えるか。**
   - 推奨：pdm の需要の結果を見てから決めます。
   - いちばん強い反論：大人が「スマホに時間を取られる」という課題を捨てることになります。
   - 元に戻せるか：戻せます（まだ実装していません）。
   - 見てほしいファイル：docs/prd/product.md
2. **Takuma に頼みたい確かめ：** 拡大鏡のアクセシビリティリーダーと Speechify で、縦書きの文庫本のページが正しい順で読めるか。③の独自性がこれで決まります。
3. **pdm へ：**
   - ④の需要（音読カードを使う学校の割合、親の負担の量、GIGA の端末が代わりになっていないか）
   - Pause とよみかえしの評価が少ないのは、需要が小さいからか、出たばかりだからか。
4. **tech-lead へ：**
   - ①：盾のボタンから自分のアプリを開けるか。entitlement の手続き。
   - ④：子どもの声を端末の中だけに置く方法。Kids カテゴリーに入れるか。マイクの許可を求める時と理由。伏せたことを録音の開始に使えるか。
5. **001 の AC-24（許可のダイアログ0回）について：** ①（Family Controls）でも④（マイク）でも守れません。PRD の書き直しが要ります。
6. **性格語：** ④を選ぶなら、「静か」の意味を見直します。
7. **見ていないもの：**
   - Read Along の画面と iOS 版の有無
   - Ello の紙の本を使っていた版
   - ReadTime、Quotelog、SeeAll、ユリウスの画面
   - アクセシビリティリーダーの画面
   - Speechify の撮る画面
   - Opal と Pause を実機で使った流れ
   - ADA の「Behind the Design」の記事と、2022年以前の ADA
   - 2023年と2024年の最終候補の理由の文（ページにありません）
   - 小樽市の PDF の本文

## 記録（指揮役が保存するときに書き足す）
- 種類：方向の見直しのための調べもの（designer）。PASS / FAIL なし
- 対象：指揮役が出した角度①〜④。BASE=64d14463c31dac576a8fe585d7391815b8f0f67d
- 日付：2026-10-16
