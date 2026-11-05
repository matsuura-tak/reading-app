（指揮役の注）これは判定ではなく、課題の選び直しのための調べもの（designer）の報告。担当はポートフォリオ映えと、課題ごとの象徴の瞬間。報告の文はそのまま保存した。

# 調べもの：課題の選び直し その3　ポートフォリオ映えと、課題ごとの象徴の瞬間（designer、2026-10-16）

リポジトリのファイルは書いても直してもいません。確認日はすべて 2026-10-16 です。点は1〜5点です。R-n はこの報告の中だけの番号で、T-1〜T-8 は前回の docs/reviews/001-reading-session-angles-designer.md のものです。ツールの呼び出しは、この報告を入れて30回でした。

## 0. 結論
- **ポートフォリオで受けるのは、「現実の物が1つの動作で意味を持ち、そのあと画面が引っ込む」形です。**
  - 近い受賞は2つあります。CapWords は、撮ると物の名前を覚えられます（R-1）。Crouton は、画面ではなく台所を見ていられます（R-2）。
- **10秒の動画は2本要ります。**
  - App Store の版：プレビューは最初から音が消えていて、手や端末を映せません（R-7）。アプリの画面だけで伝わる作りにします。
  - ポートフォリオと SNS の版：手と本を映せます。「おっ」と思わせるのはこちらです。
- **指揮役の仮説は、10秒の動画なら「おっ」と思わせます。ただし、部品はもう全部あります。**
  - 本棚の写真から背表紙を読むアプリが、2025-11〜2026-08 に少なくとも7本出ています（R-9）。
  - いちばん近いのは Readpick です（日本の個人の開発者、2026-08-18）。カメラはありませんが、次のように書いてあります。
    - 説明文：「積んである本の中から、いま読むべき1冊を名指しします」「候補は出しません」「選ぶ処理は、iPhoneの中のAIが行います」
    - 画面写真：「→ 第1章の終わりまで読む。」「いまじゃない」
  - Bookpather（2026-07-18、日本語あり）は「本棚をスキャンして次に読む本を決め、読書時間を計り」で、仮説の流れとほぼ同じです。
  - iOS 26 のビジュアルインテリジェンスも、本を見分けると報じられています（R-12。Apple の文書では確かめていません）。
  - 「AI が背表紙を読んで1冊選ぶ」は、もう差になりません。差になり得るのは、選んだ後の流れ（本を抜く、伏せる、閉じてよい所で終わる）と、作りの質と、縦書きの背表紙です。
- **ギミックに見せないための条件を8つ挙げます（3 の G-1〜G-8）。** 中心は次の2つです。
  - カメラは、本を登録するときだけ使います。毎晩の道には入れません（R-5、R-6）。
  - 「光る」はやめて、細い線1本と言葉1行にします。選んだ理由は、確かめられる事実だけにします。
- **designer が推すのは、3つの課題をまとめた案「積読の山から、今夜の数ページへ」です（4、5）。**
  - 点：ポートフォリオ映え 5、独自性 3、賞の筋 3、性格語 4（合計 15/20）
  - いちばん強い反論：部品はどれも先行があり、差は「流れ」と「縦書きの背表紙」に頼っています。ほかのアプリが縦書きの背表紙を読めるなら、独自性は 2 に下がります。Takuma の本棚で15分試せば確かめられます。

## 1. ポートフォリオで受けるアプリの型
### 1-1. 根拠（確認日はすべて 2026-10-16）
- **R-1 CapWords**（ADA 2025 Delight and Fun の受賞。HappyPlan Tech、中国）
  - 「offers an idea that's as simple as it is revolutionary: Learn the name of a thing by taking a picture of it. With the snap of a camera and a fun animation, CapWords transforms everyday objects … into interactive stickers」「it's hard to stop snapping pictures of everything around you」
  - https://developer.apple.com/design/awards/2025/ （前回保存した本文を grep しました）
  - App Store Awards の App of the Year にも選ばれたという話は、SNS の投稿の要約で見ただけです。確かめていません。
- **R-2 Crouton**（ADA 2024 Interaction の受賞。Devin Davies、ニュージーランド）
  - 「its effortless series of interactions mean people can keep their focus on the counter rather than their screen」
  - https://developer.apple.com/design/awards/2024/
- **R-3 Mela**（ADA 2025 Interaction の最終候補。Silvio Rizzi、スイス）
  - 「recipe scanning is powered by the Vision framework」「Timers integrate with the Dynamic Island」
  - https://developer.apple.com/design/awards/2025/
- **R-4 (Not Boring) Camera**（ADA 2026 Visuals and Graphics の最終候補）
  - 「the team blew up a common idea and rebuilt it with big loud capital-V Vibes」「Ensure the products excel in all other areas too」
  - https://developer.apple.com/design/awards/
- **R-5 HIG の Design principles**
  - 「Create defining moments. Every interaction is a chance to show what your software stands for.」
  - 「Don't mistake delight for decoration. … don't let pursuit of delight for its own sake get in the way of your product's core purpose.」
  - 「Investigate existing solutions, and avoid re-creating them. Define what sets your product apart」
  - 「Stay out of the way.」
  - HTML（https://developer.apple.com/design/human-interface-guidelines/design-principles ）は本文が取れませんでした。https://developer.apple.com/tutorials/data/design/human-interface-guidelines/design-principles.json で読みました。
- **R-6 benji.org の「Family Values」**（2024-07-08。本文に著者名はありません）
  - 「the potential for delight increases as the frequency of feature usage decreases.」
  - 「For frequently used features, the value of adding further delight gradually diminishes.」
  - https://benji.org/family-values
- **R-7 App Store のプレビュー**
  - 「each preview can be up to 30 seconds long」
  - 「By default, app previews play with the sound muted, so consider using copy to add additional context to your footage.」
  - 「Stay within the app. … Don't film people interacting with a device, such as an over-the-shoulder angle or fingers tapping the screen.」
  - 「Select a visually compelling poster frame from your footage that conveys the essence of your app.」
  - AR のアプリには「use the first few seconds of your app preview to show the object being placed into a user's surrounding」とあります。
  - https://developer.apple.com/app-store/app-previews/
- **R-8 話題になったが効かなかった例：Bionic Reading**
  - 2022年に SNS で広まりました。
  - Readwise の実験（n=1916）では、速さはほぼ同じでした（Bionic のほうが毎分2.6語遅い）。
  - 2024年の Acta Psychologica の論文でも、差はありませんでした。
  - どちらも検索結果の要約で読み、ページは開いていません。Readwise は読書アプリの会社で、参加者は自分から応じた人たちです。
  - https://blog.readwise.io/bionic-reading-results/ 、https://research.vu.nl/en/publications/no-bionic-reading-does-not-work/
- **R-9 本棚を撮るアプリと、次の1冊を決めるアプリ**（App Store の検索と lookup の API。画面写真は8本の各4枚を見ました）

| アプリ | 国、公開日、評価の数 | 説明文（引用） | 画面写真で見たもの |
|---|---|---|---|
| Readpick | JP、2026-08-18、0件 | 「積んである本の中から、いま読むべき1冊を名指しします」「『どれくらい時間がある？』『いまの調子は？』の2タップで、1冊とその理由が出ます」「候補は出しません。候補が多いことが問題だからです」 | 「これを読む」「巨匠とマルガリータ」と理由の文、「→ 第1章の終わりまで読む。」、茶色の「読みはじめる」、「いまじゃない」。本の一覧「積んで412日」。生成りの地に明朝の見出し |
| Bookpather | JP、2026-07-18、0件 | 「本棚をスキャンして次に読む本を決め、読書時間を計り」「本棚全体に向けるか、写真を選ぶだけで」 | 「本棚を、読む順番に」（読書ルート）、要点、スタンプ、「6日連続」と週の棒グラフ |
| ブックカタログ：棚スキャナー | JP、2026-08-18、0件 | 「デバイス上で背表紙を認識」「一度に最大40冊」「500冊のライブラリは約13枚の棚の写真です」 | カメラの上に背表紙の枠と「8 spines detected / 6 confident, 2 to check」。見本の棚の絵で、題は英語が横に寝た文字 |
| Shelf Scan | US、2025-11-05、2件 | 「Can't decide which book to read next? Shelf Scan uses AI to instantly identify books from a single photo」 | 写真を上げる画面、星の評価、Amazon と Goodreads のボタン |
| Spines | US、2026-02-04、2件 | 「Point your camera at a shelf … Spines identifies the books in seconds and highlights the ones worth grabbing」 | 棚に向けたカメラ（枠だけ）、「Ooh — 55 gems on this shelf」、「Worth Grabbing」「NYT」「Pulitzer」の札。光らせる画面は、最初の4枚にはありませんでした |
| ShelfSnap、Passim、FlipLit | US 2026-05-03、JP 2026-05-12、US 2026-03-26 | 「scan … a full bookshelf」「AIが背表紙を読み取って一括登録」「Scan Shelves. Find Value.」 | 見ていません |

- **R-10 私は積読家**（JP、2026-02-16、評価149件、平均4.7、日本語だけ）
  - 「積読は、減らさなくていい。」「83冊で2m65cm。『未読83冊』だと気が重いのに、『2m65cm』だと誇らしい。」
  - 画面写真：積読を色の帯の塔にして「265.9cm」と見せ、「SNSにシェア」があります。登録はバーコードを続けて読む形で、カメラで背表紙は読みません。
- **R-11 くじ引きと瓶で選ぶもの**
  - TBR Book Jar（US、2026-04-09）「the reading app BookTok has been waiting for — a digital TBR jar」
  - TBR Jar: Bookish Garden（US、2026-07-21）「give your phone a shake, and let the jar decide!」
  - 読みくじ（JP、2024-02-08）「抽選演出のあと、今日の一冊が表示されます」。楽天ブックスで買えて、広告があります。
- **R-12 iOS 26 のビジュアルインテリジェンス**（検索結果の要約。MacRumors の記事を転載したページで、開いていません）
  - 「The expanded object identification now includes art, books, and landmarks」
  - https://thenote.app/post/en/heres-whats-new-with-visual-intelligence-in-ios-26-xnuqvopgat
- **R-13 「tsundoku」は海外でも知られた言葉**
  - BBC の2018年の記事が取り上げました。BBC の本文は開いていません。URL は Gigazine のリンクから見た https://www.bbc.com/news/world-44981013 です。
  - 要約には、Andrew Gerstle 教授の「侮辱に聞こえるかもしれないが、日本では汚名ではない」という趣旨の言葉があります。
  - https://www.gigazine.net/news/20180730-tsundoku/
- **R-14 課題4の物語（海外）**：The Atlantic、Rose Horowitch「The Elite College Students Who Can't Read Books」（2024年10月）
  - 本文は開いておらず、紹介記事の要約で読みました。
  - 要約によると、33人の大学教員に話を聞いています。「前の年に1冊も本を読まなかった高校3年生」は、1976年の11.5%から2022年の40%に増えたとあります。批判する記事（Education Next）もあります。
  - https://pittnews.com/article/191303/featured/the-atlantic-says-some-elite-college-students-cant-read-books-can-pitt-students/ 、https://www.educationnext.org/seven-thoughts-about-elite-college-students-who-cant-read-books/
- **R-15 課題1の物語（日本）**：三宅香帆『なぜ働いていると本が読めなくなるのか』（集英社新書、2024年4月）
  - 検索結果の要約に「発売1週間で累計発行部数10万部を突破」とあります。どのページの文かは、要約からはわかりません。「年間1位」は確かめられませんでした。
  - 出典の候補：https://www.advertimes.com/?p=484225 、https://www.newsweekjapan.jp/articles/-/56932 、https://gendai.media/articles/-/137165
- **R-16 長文の課題に、いまのアプリが出している答え**（App Store の検索 API）
  - JP の「長文 読めない」は0件でした。
  - 新しい「あとで読む」のアプリは、AI の要約を売りにしています。
    - シンプルあとで読む（2026-05-08）「Apple Intelligence で自動要約」
    - Omoidase（2026-08-12）「保存するだけでAIが要約とタグを付け」
  - Readrrr（US、2026-01-14、27件）「uses Rapid Serial Visual Presentation to show words one at a time」
- **R-17 Margins: Book Tracker**（Paratext Inc.）
  - Similarweb の集計ページに「20か国以上で App of the Day」とある、と検索結果の要約にありました。ページも Apple の記録も見ていません。
  - https://www.similarweb.com/app/apple/6737528718/mauritius/
- **R-18 採用する側がポートフォリオで見るもの**（NN/g の原文は検索に出ず、二次の要約です）
  - NN/g が200人以上の採用担当に聞いたそうです。採用担当は、調べ方とそこから学んだこと、仮説、やり直し、捨てた案を見たい、とあります。
  - https://www.lyssna.com/blog/ux-designer-portfolio/ 、https://blogs.ulster.ac.uk/bethbuchanan/2021/10/04/ixd301-week-2-the-neilson-norman-groups-portfolio-advice

### 1-2. 型
- **P-1 現実の物が、1つの動作で意味を持つ（R-1、R-3、R-9）**
  - CapWords は、撮る1回で物が言葉のカードになります。Mela は Vision でレシピを読みます。
  - 前（ただの物）と後（意味のある物）が同じ画面の中で変わるので、10秒で伝わります［推測］。
  - 条件は、その動作が本来の手間を減らしていることです。ブックカタログの「500冊…約13枚の棚の写真」が、手間の差を数で言っている例です。
- **P-2 画面から目を離させる（R-2、T-3）**
  - 「画面が消える」瞬間は強い絵になります［推測］。
  - ただし、App Store の版では手を映せません（R-7）。
- **P-3 ありふれた道具を、1つの視点で作り直す（R-4、T-4）**
  - ポートフォリオで問われるのは、見た目より「なぜこうしたか」です（R-18）。
- **P-4 1つの数字か1枚の絵で、気持ちを変える（R-10）**
  - 「2m65cm」の塔は、静止画で伝わり、共有されます。
  - 評価の数は、私は積読家が149件です。Readpick、Bookpather、ブックカタログは0件です。公開からの月数が違うので、単純には比べられません。
- **P-5 個人か小さなチーム（R-2、R-3）**
  - ADA の受賞と最終候補に、個人名の開発者が並びます（Devin Davies、Silvio Rizzi、Raja V）。
- **P-6 喜びは、使う回数の少ない所に置く（R-5、R-6）**
  - 毎日通る道は、速く静かにします。演出は、1回だけの瞬間に置きます。
  - Forest の不満「豪華なデザインとかアニメーションとか要らない」は、毎日の道に演出を置いたときに出ると読めます［推測］。
- **反対の型：話題になったが効かない（R-8、R-16）**
  - Bionic Reading と、一語ずつ見せる表示（RSVP）が例です。課題4は、この罠にいちばん近い課題です。
- **調べていないこと**
  - SNS での広がり（再生数など）は調べていません。注目の度合いは、ADA と App Store の評価の数で代わりに見ました。
  - Dribbble と Behance の読書アプリ、Apple の Today の記事は開いていません。

### 1-3. 10秒の動画で伝わる形
1. 音がなくても伝わる（R-7）。
2. 前と後が、1つの画面の中で変わる（P-1）。
3. 文字は1行、多くても2行。
4. 映るのは手、本、iPhone だけ（ポートフォリオの版）。
5. 最初の3秒で、何に困っているかが見える。積読の山が映れば、説明は要らないと見ます［推測］。
6. 最後の1枚（ポスター）だけでも、本質が伝わる（R-7「conveys the essence」）。
7. App Store の版は、アプリの画面だけで同じ話ができる（R-7）。

### 1-4. 読書アプリの見た目の今
- 画面写真を見た8本のうち4本（Readpick、Bookpather、私は積読家、ブックカタログ）が、ほぼ同じ見た目でした。生成りの地、明朝の見出し、茶か朱の差し色です。
- 「上品で美しい読書アプリ」は、もう既定の見た目です。ポートフォリオでは、これだけでは目立ちません［推測］。
- 案：アプリは自分の色を持たず、画面の色は利用者の本の背表紙から来るようにします（B-5）。

## 2. 課題ごとの象徴の瞬間
### 2-1. 課題2「積読が増えていく／次の1冊が選べない」
**案 2-A　山が答える（はじめての1回）**
- 0〜3秒：夜の机に、積読が7冊ほど積んであり、縦書きの背表紙が見えます。手が iPhone を山に向けると、読めた背表紙に細い線が1本ずつ付きます。
- 3〜6秒：線は1本だけ残ります。その横に「今夜は、これ。p.43から、約15分。」と出て、触覚が1回返ります。
- 6〜10秒：手が山からその本を抜いて開きます。
- 見た人が感じること：「選べない」が3秒で終わる。

**案 2-B　背表紙のしおり線（毎晩）**
- 0〜3秒：アプリを開くと、前に撮った自分の山の写真が出ます。表紙を並べた画面ではありません。
- 3〜7秒：読みかけの背表紙には、読んだ分の長さの細い線があります。今夜の1冊にだけ「p.43から」と書いてあります。
- 7〜10秒：「ほかの本にする」を押すと、言葉が別の背表紙に移ります。
- 見た人が感じること：自分の本の山が、そのまま読める地図になる。

**いまあるアプリとの違い（R-9、R-10）**
- 先行の画面は、どれも次の3つのどれかでした。
  - 一覧と理由の文（Readpick）
  - カードと連続日数（Bookpather）
  - 買うための札（Spines、Shelf Scan）や登録の確認（ブックカタログ）
- 私は積読家は、色の帯の塔です。
- 撮った自分の山の写真を毎晩の画面にする形は、見た画面写真の中にはありませんでした。アプリを入れて使ってはいません。

**性格語**
- 静か：○。札、星、連続日数を出しません。ただし、カメラの演出を足すと×になります。
- 確か：○。読めなかった背表紙は「確かめてください」と出し、理由は事実だけにします。
- まっすぐ：○。向けると1冊が出ます。
- 手で感じる：◎。本物の本を山から抜きます。

**飾りで手順が増える危険：中から高**
- 毎晩カメラを向けさせると、紙の本を手に取るより手間が増えます。
- 光、粒、揺れの演出を毎日の道に置くと、Forest の不満と同じになります（P-6）。
- 山が変わるたびに撮り直すのは、雑用になります。撮り直しを勧めるのは、読み終えたときだけにします。

**アクセシビリティ**
- カメラを使えない、または使いにくい人がいます。目の見えない人、見えにくい人、手が震える人、高い棚に届かない人、家の中を撮りたくない人、積読が電子書籍の人です。
  - 写真を選ぶ、バーコード、書名で探す、ブクログや読書メーターの書き出しを読む、のどれでも同じ結果に着けるようにします。
- VoiceOver では、写真を飾りとして扱い、同じ中身の一覧を読ませます。
  - 例：「今夜の1冊、〇〇、山の上から3冊目、43ページから」
  - 位置の言葉は、見える人が本を探すときにも役立ちます。
  - 撮ったあとは「背表紙を7冊読み取りました。2冊は確かめてください」と、数で伝えます。
- 動きを減らす設定では、線を一度に出します。
- AX5 では、写真の上の言葉が入らないので、写真の下に出します。
- 今夜の1冊は、太い線と言葉で示し、色だけに頼りません。

### 2-2. 課題4「スマホで長い文章が読めなくなった」
**案 4-A　要約しないで、区切る**
- 0〜3秒：Safari の長い記事が、指で何度も流されます。
- 3〜6秒：記事を共有でアプリに渡すと、1本の縦の帯になり、細い切れ目が2本入ります。「3晩で読めます。今夜は、ここまで。約12分。」
- 6〜10秒：読む画面には本文だけがあり、切れ目で「ここまで。」と止まります。
- 見た人が感じること：読まずに済ませるのではなく、読める長さにしてくれる。

**案 4-B　紙に戻す**
- 0〜3秒：通知が積もった画面が映ります。
- 3〜6秒：手が iPhone を伏せて、紙の本を開きます。画面が消えます。
- 6〜10秒：時間が飛び、iPhone を起こすと「18分。p.43 → p.61」とだけ出ます。

**いまあるアプリとの違い（R-16）**
- 答えは2つに割れています。要約で読まずに済ませる形と、一語ずつ速く読ませる形です。「読む力を取り戻す」と言うアプリは、検索では見つかりませんでした。
- ただし、4-A の「区切って毎日読む」は、Serial Reader（2016年から。pdm の前回の報告）と同じ形です。
- 4-B は、2018年からある「伏せると始まるタイマー」と同じです。

**性格語**
- 4-A：静か○、確か○（切れ目は段落に置き、時間は見積もりと明記する）、まっすぐ○、手で感じる×（画面で読む）
- 4-B：4語とも○

**飾りで手順が増える危険：高い（4-A）**
- 読む画面の文字を工夫すると、Bionic Reading や RSVP と同じ罠に入ります（R-8）。
- 「集中の点数」も同じ罠です。

**アクセシビリティ**
- スマホの読む助けに頼る人がいます（VoiceOver、画面の読み上げ、Dynamic Type、Speechify）。
- 4-B で「紙のほうが正しい」と語ると、この人たちを外すことになります。そう語らないようにします。

**ポートフォリオとしての評価**
- 物語はいちばん強い課題です（R-14、R-15）。
- 一方で、画面の瞬間は作りにくく、作り込むほど R-8 の罠に近づきます。
- 課題4は「なぜ」（物語）に使い、「何が起きるか」（瞬間）は課題2と1に任せるのがよいと見ます［推測］。

### 2-3. 課題1「働いていると、本が読めない」
**案 1-A　数ページで閉じられる**
- 0〜3秒：夜の11時半、ネクタイをゆるめた手が、本の横に iPhone を伏せます。
- 3〜7秒：時間が飛び、手の中で触覚が1回あります。
- 7〜10秒：起こすと「p.43 → p.58。ここで閉じられます。」と出ます。しおりを挟んで、本を閉じます。
- 見た人が感じること：短くても、終われたことが残る。読めなかった日は責められない。

**案 1-B　帰り道に、もう決まっている**
- 夕方から、ロック画面の小さな枠に「今夜：〇〇　p.43から　約15分」と出ています。家に着いてから選ばなくて済みます。

**いまあるアプリとの違い**
- 先行は ToRead、mekuru、Honno、FLIP（2018年から）、Offshelf と、Bookpather のタイマーと「6日連続」です。
- 違いは2つだけです。終わりを時間ではなく「閉じてよい所」として言うことと、連続日数を持たないことです。画面に見える違いとしては弱いです。

**性格語**：4語とも合います（もともとこの課題のために決めた語です）。

**飾りで手順が増える危険：低いから中**
- 「今夜も読みましょう」の通知、連続日数、BGM（ツンドクというアプリにあります）を足すと、手順が増えます。

**アクセシビリティ**
- 伏せるのが難しい人や、スタンドに立てて使う人には、「読み始める」のボタンを置きます（001 と同じ）。
- 触覚を切っている人には、起こしたときの文字で伝えます。

## 3. 指揮役の仮説の評価
- **「おっ」と思わせるか：思わせます（10秒の動画では）。**
  - P-1（CapWords）の型にそのまま乗ります。山、向ける動作、1冊が、音なしで3秒に入ります。伏せたあとに画面が消えるのは、P-2 の絵です。
- **そのままの形では、ギミックに見えるおそれが高いです。**
  1. 部品はもう全部あります（R-9、R-12）。アプリを追っている人には「7本目の本棚スキャナー」に見えます。「AI は端末の中」も、Readpick とブックカタログがもう言っています。
  2. 毎晩カメラを向ける人はいないと見ます［推測］。動画の瞬間が、毎日の体験とずれます。
  3. 「光る」は、HIG の「Don't mistake delight for decoration」（R-5）に当たります。
  4. 生成 AI に理由の文を書かせると、事実でない理由が出るおそれがあり、「確か」を壊します［推測］。
  5. App Store の版では手を映せないので（R-7）、「伏せる」を画面だけで伝えるのが難しいです。
- **ギミックに見せないために要るもの**
  - G-1：カメラは登録の近道にだけ使います。毎晩の道に入れません。
  - G-2：「光る」をやめて、細い線1本と言葉1行にします。演出は、はじめて山を撮ったときの1回だけにします（R-6）。
  - G-3：理由は、確かめられる事実だけにします（「p.43で止まっている」「残り約120ページ」）。AI は、背表紙を読むことにだけ使います。画面では「AI」と言わず、「背表紙を読み取りました」と動作を言います。
  - G-4：選ばれた1冊は断れるようにします（「ほかの本にする」）。断っても、何も減りません。
  - G-5：アプリを開いてから紙の本を開くまでの操作は、2つ以内にします（見る、伏せる）。
  - G-6：カメラなしでも、同じ結果に着けるようにします。
  - G-7：写真は端末の外に出しません。保存するかは、本人が決めます。
  - G-8：動画は音を消して確かめます。アプリの画面だけの版でも、話が通じるかを確かめます。
- **残る差（あるとすれば）**
  - 縦書きの日本語の背表紙を、端末の中で読めること（T-5、R-13）。
    - ほかのアプリが読めるかは、確かめていません。
    - ブックカタログの画面写真は、見本の絵の棚で、題は英語でした。
  - 撮った山の写真を、毎晩の画面にすること。
  - 選ぶ、伏せて始める、閉じてよい所で終わる、が1本の流れになっていること。
    - Readpick は「読みはじめる」で止まります。
    - Bookpather は、タイマーと連続日数に進みます。

## 4. 3つを1つにまとめた案「積読の山から、今夜の数ページへ」
- **1文で言うと：** 読みたいのに読めない夜に、積読の山から今夜の1冊と、閉じてよい所までを差し出します。紙の本を開いたら、画面は消えます。
- **3つの課題との対応**
  - 課題2：山の写真の上で、1冊にだけ線と言葉を出します。
  - 課題1：「約15分」と「ここで閉じられます」を出し、連続日数は持ちません。
  - 課題4：長い文章を、スマホと戦わずに紙で読みます。スマホは伏せておきます。
- **象徴の瞬間（ポートフォリオの版、10秒）**
  - 0〜2秒：夜の机に、縦書きの背表紙の積読が8冊あります。手が iPhone を向けると、読めた背表紙に細い線が付きます。
  - 2〜4秒：線は1本だけ残り、「今夜は、これ。p.43から、約15分。」と出ます。触覚が1回あります。
  - 4〜7秒：その本を山から抜いて開き、iPhone を横に伏せます。画面が消えます。
  - 7〜10秒：時間が飛び、iPhone を起こします。撮った山の写真の、その背表紙に短い線が1本増えていて、「p.43 → p.61　18分」と出ます。
  - 見た人が感じること：選ぶことと始めることが10秒で終わり、読書の主役は紙の本のまま。
- **App Store の版（アプリの画面だけ、音なし）**
  - 流れ：カメラの画面で線が付く → 1本が残る → 「伏せると、始まります」の1行 → 黒い画面 → 写真の背表紙に線が1本増える。
  - 手が映らないので、「伏せる」は文字で伝えるしかありません。ここが弱いです。
- **毎晩の道（演出なし）**
  - ロック画面の枠「今夜：〇〇　p.43から」→ 本を手に取る → アプリを開いて伏せる（操作は2つ）。
- **見た目**
  - 色は利用者の本の背表紙だけにし、アプリの部品は黒、白、灰にします（B-5）。1-4 で見た「生成りと明朝」の型から外れます。
  - 今夜の印は、線と言葉で示します。
- **ADA の型**
  - 重なるもの：T-3（紙の本から目を離させない）、T-4（札も星も連続日数もない）、T-6（決まったとき、終わったときに触覚1回）、T-7（端末の中の Vision）
  - 縦書きの背表紙が読めれば、T-5 も加わります。
  - 部門は Interaction（Crouton）か Delight and Fun（CapWords）に近いと見ます［推測］。
- **アクセシビリティ**
  - 2-1 と 2-3 に書いたとおりです。土台は一覧で、写真とカメラは近道として置きます。
- **増える許可**
  - カメラの許可が要ります。001 の AC-24（許可のダイアログ0回）とは合いません。

## 5. 物差しごとの評価と、推す案
| 案 | ポートフォリオ映え | 独自性 | デザイン賞の筋 | 性格語との合い方 | 合計（20点満点） |
|---|---|---|---|---|---|
| 課題2だけ（2-A と 2-B） | 4 | 2 | 3 | 3 | 12 |
| 課題4だけ（4-A） | 2 | 2 | 3 | 3 | 10 |
| 課題1だけ（1-A） | 2 | 1 | 3 | 5 | 11 |
| 指揮役の仮説のまま（毎晩カメラ、光る、AI が選ぶ） | 5 | 2 | 2 | 2 | 11 |
| まとめた案（designer が直した形） | 5 | 3 | 3 | 4 | 15 |

**点の理由**
- **課題2だけ**
  - 映え 4：山から1冊が3秒で伝わります。ただし、話が「選ぶ」で終わり、読むところまで映りません。
  - 独自性 2：R-9 の7本と Readpick、R-12 があります。
  - 賞の筋 3：CapWords と Mela の型に近いです。ただし、何を読むかを機械が決めることを評価した受賞の文は、4年の受賞の中に見当たりません。
  - 性格語 3：カメラが中心になるので、「静か」と合わない場面が増えます。
- **課題4だけ**
  - 映え 2：物語は強いですが、画面の瞬間が弱いです。
  - 独自性 2：Serial Reader、Instapaper、要約のアプリがあります。
  - 賞の筋 3：iA Writer（「focus on the words」）や Vocabulary（「quietly」）と同じ、読む画面の質で勝負する型です。
  - 性格語 3：「手で感じる」と合いません。
- **課題1だけ**
  - 映え 2：伏せると画面が消えるので、映るのは手の動きだけで、2018年からある絵です。
  - 独自性 1：ToRead、mekuru、Honno、FLIP、Offshelf、Bookpather があります。
  - 賞の筋 3：T-3 と T-4 に合います。
  - 性格語 5：もともとこの課題のために決めた語です。
- **仮説のまま**
  - 映え 5：動画ではいちばん「おっ」となります。
  - 独自性 2：光らせる形は、Spines の「highlights」と同じ向きです。
  - 賞の筋 2：「光る」と「AI が選ぶ」は、受賞の言葉（nothing extraneous、quietly、not by insistent reminders）と逆の向きです。
  - 性格語 2：毎晩の道にカメラと光があり、最初の語「静か」とぶつかります。
- **まとめた案**
  - 映え 5：2つの体の動き（向ける、伏せる）で、山から紙の本までが10秒に入ります。ポスターの1枚（山の写真に線1本と1行）でも伝わります。
  - 独自性 3：部品はどれも先行があります。つないだ流れ、山の写真を毎晩の画面にすること、縦書きの背表紙は、見た画面写真の中にはありませんでした。使っては確かめていません。
  - 賞の筋 3：T-3、T-4、T-6、T-7 が重なります。縦書きが読めれば T-5 が加わって 4 です。T-1（はっきりした対象）と T-2（大きな課題）は弱く、読書のアプリの受賞はまだありません。
  - 性格語 4：手で感じる◎、まっすぐ○、確か○、静か△（はじめて撮るときだけ演出がある）。

**designer が推す案：まとめた案（designer が直した形）**
- **理由**
  1. 困りごと、瞬間、結果の3つを、音なしの10秒で言えるのは、この案だけです（1-3 の7つの条件を満たします）。
  2. 喜びを置く場所が P-6 に合います。演出は、はじめて撮るときの1回だけで、毎晩の道にはありません。Forest の不満を、先に避けられます。
  3. 001 の「伏せる」と、名作の案の「ここまで」の調子を、そのまま使えます。
  4. これまでに捨てた案（角度①〜④、音読、名作）と、捨てた理由が、そのまま事例の中身になります。採用する側が見たい「捨てた案と仮説」（R-18）にあたります［推測］。
- **いちばん強い反論**
  - 部品がもう全部あります。Readpick（1冊を名指しし、理由と小さな最初の一歩を出す。端末の中で動く）と、Bookpather（本棚を撮って次の1冊を決め、時間を計る）を知っている人には、「2つを足しただけ」に見えます。
  - 差は、流れと作りの質と縦書きの背表紙にあります。流れと質は静止画では見せにくく、縦書きはまだ確かめていません。
  - カメラの瞬間は、使う人にとっては最初の1回の出来事です。動画の主役が、毎日の体験ではありません。
- **進める前に確かめること**
  - Takuma の15分の確かめ（未解決の4）
  - 「選べない」が毎晩起きるのか、ときどきなのか（pdm）
  - AC-24 の書き直し（カメラの許可が要るため）
  - 縦書きの背表紙を読めるか（tech-lead）
- **目的によって、独自性の重みが変わります。** ポートフォリオが目的なら、縦書きで差が出なくても、進める価値はあると見ます［推測］。事例の中心は「なぜカメラを1回にしたか」「なぜ光らせないか」という判断になります。ADA や市場が目的なら、差が要ります。

## 変更したファイル
- リポジトリ：なし
- スクラッチパッド（リポジトリの外。見るためのデータです）：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/designer3/ の scripts/（search.py、lookup.py、search4.py、compose.swift）、dl/itunes/、dl/shots/（画面写真32枚）、dl/web/hig_principles.json、sheets/（a_readpick_bookpather.png、b_shelfscan_spines.png、c_tsundokuka_catalog.png）

## 実行したコマンドと結果
実行した順です。日付はすべて 2026-10-16 です。
- **入力ファイルを読みました。** docs/reviews/001-reading-session-angles-designer.md、docs/approvals/001-reading-session-G0-Q8.md、design/explore/README.md を Read で。`cat .claude/org/app.json`、`wc -l`、`ls -la design docs/reviews`。`grep -n "性格語|…" design/001-reading-session-research.md` と `sed -n 1,60p docs/reviews/001-reading-session-validate-designer.md`。
- **最初の検索のコマンドは、ガードに止められました。** 書き先のパスに $ を使ったためです。パスをそのまま書いて、やり直しました。
- `python3 -I …/designer3/scripts/search.py`：8件とも結果が返りました（403 はありませんでした）。US の bookshelf scanner、book spine scan、what to read next、tbr jar。JP の「積読」「本棚 スキャン」「背表紙」「次に読む本」。
- `python3 -I …/designer3/scripts/lookup.py`：https://itunes.apple.com/lookup?id=6790094219,6797449879,6801512523,6758698105,6761805831,6476876922&country=jp と https://itunes.apple.com/lookup?id=6754824642,6757425414&country=us 。説明文が取れ、画面写真32枚を落としました。
- `swift …/compose.swift`（3回）：図を3枚作り、Read で見ました（R-9、R-10 の画面の記述はここからです）。
- **WebFetch**：https://benji.org/family-values（取れた）、https://developer.apple.com/app-store/app-previews/（取れた）、HIG の design-principles の HTML（本文なし）。
- **WebSearch**（ページは開いていません。要約だけです）：Bionic Reading、BBC tsundoku、Behind the Design CapWords、NN/g portfolio、三宅香帆 年間ベストセラー、The Atlantic Horowitch、Visual Intelligence books iOS 26、App of the Day reading app。
- `grep`（designer2 が保存した ADA の本文）：CapWords、Crouton、Mela、(Not Boring) Camera、Detail の文を取りました。
- `curl -sL https://developer.apple.com/tutorials/data/design/human-interface-guidelines/design-principles.json`：HTTP 200、26,295バイト。R-5 の引用を取りました。
- `python3 -I …/designer3/scripts/search4.py`：JP「長文 読めない」（0件）、JP「あとで読む」、US「deep reading focus」、US「read long articles」。
- **SubagentHandback の1回目は、証拠チェックに止められました。** 見出しに括弧書きを付けていたためです。見出しを直して出し直しています。
- `cd /Users/takumamatsuura/reading-app && git status --short`：出力なし、exit=0。

## 未解決
1. **Takuma に決めてほしいこと：まとめた案「積読の山から、今夜の数ページへ」で進めるか**
   - 推奨：進めます。ただし、4 の「確かめること」を済ませてからにします。
   - いちばん強い反論：Readpick と Bookpather があり、差は流れと縦書きに頼っています。
   - 元に戻せるか：戻せます（まだ書いていません）。
   - 見てほしいファイル：この報告と、/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/designer3/sheets/a_readpick_bookpather.png
2. **Takuma に決めてほしいこと：いちばんの目的はどれか（ポートフォリオ、ADA、ストアで使われること）**
   - 独自性の重みと、縦書きを差にするかが、これで変わります。
   - ポートフォリオを見るのが日本の採用担当か、海外のデザイナーかによっても変わります。
3. **Takuma に決めてほしいこと：課題4を「紙で読む」で受けるか**
   - 受けると、電子書籍の積読がある人と、スマホで長文を読みたい人は、カメラの道から外れます。
4. **Takuma に頼みたい確かめ（15分ほど）**
   - 自分の積読の山（縦書きの背表紙）を、Bookpather、ブックカタログ、iOS のビジュアルインテリジェンスに読ませて、何冊読めたかを数えてください。
   - 3つとも読めるなら、独自性は 2 に下がります。
5. **tech-lead へ**：縦書きの日本語の背表紙を端末の中で読めるか、写真1枚で足りるか（ARKit なしで）、伏せたことの検知（001 の調べもの）、カメラの許可を求める時と理由
6. **pdm へ**：「選べない」は毎晩起きるのか、ときどきなのか。Readpick、Bookpather、ブックカタログの評価が0件なのは、需要が小さいからか、出たばかりだからか。積読のうち、電子書籍はどれくらいか
7. **性格語**：「静か」と、はじめて撮るときの演出の線引きを決める必要があります（演出を許すのは1回だけ、とするか）。
8. **PRD**：AC-24（許可のダイアログ0回）は、カメラを使うと守れません。書き直しが要ります。
9. **見ていないもの**：8本のアプリは、どれも入れて使っていません（画面写真だけです）。Spines の光らせる画面と、Readpick の5枚目以降の画面写真。BBC、The Atlantic、NN/g の原文、Bionic Reading の論文の本文。ビジュアルインテリジェンスの画面。Margins が App of the Day になった記録。Dribbble と Behance の読書アプリ、Apple の Today の記事。SNS での再生数などの広がり。

## 記録（指揮役が保存するときに書き足す）
- 種類：課題の選び直しのための調べもの（designer）。PASS / FAIL なし
- BASE=9b91ec57d4819344440631429cf413e5effd3d4d
- 日付：2026-10-16
