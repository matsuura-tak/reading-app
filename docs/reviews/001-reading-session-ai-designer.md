（指揮役の注）これは判定ではなく、収益とローカル AI を検討するための調べもの（designer）の報告。担当は、ローカル AI の機能と課金を体験のどこにどう入れるか、AI を芯にした方向の象徴の瞬間、ADA。前の体が利用量の上限で止まったので、同じ指示で呼び直した体の報告。報告の文はそのまま保存した。

# 調べもの：ローカル AI と課金を、体験のどこにどう入れるか（designer、呼び直し、2026-10-18）

- これは調べものの報告で、判定ではありません。リポジトリのファイルは書いていません。
- 秒数はすべて見積もりで、測っていません［推測］。
- R-n はこの報告の中だけの番号です（末尾の「根拠」の表）。

## 0. 結論
1. 推す組み合わせ：今の形は変えません。ローカル AI は1つだけ入れます。久しぶりの夜にだけ、しおりの画面に出る「前回まで」の2行です（自分が撮ったページだけから作ります）。ふだんの夜は +0秒、出る夜だけ +6〜9秒です［推測］。言葉の説明は標準の辞書を使い、読み上げは入れず、次の1冊の理由は事実の1行のままにします。
2. AI を芯にした方向は推しません。ADA 2025・2026 の紹介文で AI を名乗った受賞作は0本で、Foundation Models を使った作は最終候補の4本だけです。読み上げは OS と Speechify に重なるうえ、日本語の縦書きとルビで崩れます。
3. 課金：毎晩の入口と本の出口は、有料の壁の外に置きます。有料は1つにまとめます。試用は「1冊目は全部使える。カードは要らない」にします。案内を置くのは、読み終えた画面のいちばん下の文字ボタンと、設定だけです。
4. G-3 は改めます。名前と売り文句に「AI」を使わない線は続けます。そのうえで、生成した文には必ず印と、1タップで開く説明を付けます（HIG が開示を求めているため）。
5. いちばん強い反論：フリーミアムのインストールあたり収益は、硬い壁の約8分の1です（RevenueCat 2026）。有料の出番がまれで、AI の部分は Apple Intelligence の機種でしか動きません。

## 1. 今の形の中で、ローカル AI をどこに入れるか
### 1-1. 候補ごとの置き場所と秒数
| 候補 | 置き場所 | ふだんの夜 | 出る夜 | 待ち | 本を開く時間への効き | 判断 |
|---|---|---|---|---|---|---|
| 前回のあらすじ（2行） | しおりの画面の一行の上。前に読んだ夜から4晩以上空いたときだけ（線は仮。G1 で決める） | +0秒 | +6〜9秒。約60字を、黙読 400〜600字/分で読むとして［推測］ | 0秒。毎晩しおりを挟んだあと、裏で作っておく（tech-lead に要確認） | 増やす。間が空いたあと「何が起きていたか」を埋めて、再開の壁を下げる。Kindle も同じ働きの機能を出した（R-13） | 推す |
| 言葉の説明 | しおりを挟む画面と、しおりの画面の一行の中の語を押したとき | +0秒 | 1語につき +5〜10秒［推測］ | 0秒 | ほぼ変わらない。読書中に引くには iPhone を起こすので、伏せる芯とぶつかる | 入れるなら生成 AI でなく標準の辞書（R-5）。お金にはならない |
| 撮ったページの読み上げ | 毎晩の道の外（別の読み方になる） | +0秒 | 撮るのに約3秒、1ページ約2分（約600字÷約300字/分）［推測］ | 読み取りの待ちあり（tech-lead に要確認） | 目で読む時間を耳に置き換えるだけ。iPhone を起こしたまま使う | 入れない（2 の (i)） |
| 次の1冊の理由の1文 | 読み終えた画面 | +0秒 | +1〜2秒［推測］ | 数秒（tech-lead に要確認）。出したあとで文が入れ替わらないよう、出す前に作る必要がある | 変わらない。事実の1行（「積読から・同じ著者」）で足り、生成しても増える情報がない | 入れない（PRD 9 の RICE 75 のまま） |

- 久しぶりの夜に「前回まで」を足しても、1晩の合計は約17〜25秒です（今の道が約11〜16秒）。中央値30秒のガードレール（integrate-proposal の 1）の内側に収まります［推測］。

### 1-2. 「前回まで」の作り方（推す形）
- **材料**
  - 毎晩しおりを挟むときに撮るページの文字だけを使います。写真は PRD どおり残しません。
  - 今の PRD が残すのは止めた一行だけです。ページの文字を端末に残す変更が要ります（未解決に書きました）。
- **生成の仕方**
  - 端末のモデルの文脈は、1回のセッションで 4,096 トークンです。日本語は「roughly one character per token」です（R-7）。
  - 文庫1ページは約600〜700字です［推測］。そこで、毎晩そのページを1行にまとめておき、久しぶりの夜はその1行たちから2行を作ります。TN3193 にある「小分けに要約してからつなぐ」型と同じです。
- **出し方**
  - 並び：書名 → 「前回まで（10月12日の晩まで）」の2行 → 縦書きの一行 → ページ → 「読み始める」。
  - 「6晩ぶり」のような数は出しません。間が空いたことを責める形になり、PRD の「急かさない」に逆らうためです。日付で示します。
  - ロック画面のウィジェットには出しません。ウィジェットは本人が撮った一行のままにします。ロック画面は周りの人にも見えます。Apple も、ロック画面の通知の要約が誤報になったあと、要約を斜体にし、注意書きを足しました（R-17）。
  - 「まとめを出さない」で消せます（設定でも切れます）。「もとの文を見る」で、まとめの材料にした一行たちを出せます（HIG ML の Attribution（R-3）、HIG Generative AI の dismiss と revert（R-1））。
- **作り話を減らす**
  - 本の外の事実はモデルに頼みません（HIG「Avoid requesting factual information unless ...」、R-1）。
  - 撮った所しか渡さないので、作りのうえでネタばれが起きません。
  - Kindle の Ask this Book には、Authors Guild が「not licensed」と反対しました（R-14）。この案は本の全文を使わず、自分が撮った所だけを端末の中で使います。法務の見込み（私的使用）は前の調べもののままで、Takuma を通します。
  - 読み取りの悪いページ（ルビの崩れが多いなど）からはまとめを作らず、止めた一行をそのまま出します。HIG ML は、頼まれずに出す結果は質が低いと受け入れられにくいと書いています（「less tolerance for low-quality information」、R-3）。どこで線を引くかは tech-lead に要確認です。
- **AI が使えないとき**
  - 対象は、機種が合わない、Apple Intelligence がオフ、準備中、ガードレールで止まった、の4つです（R-6）。
  - このときは止めた一行を3晩分そのまま出します（AI を使わない代わりの道。R-1 の「consider offering a non-AI fallback」）。
  - 「Apple Intelligence をオンに」という案内は、毎晩の道に出しません。設定の中だけに置きます。

### 1-3. G-3 を続けるか、変えるか
推奨は「変える」です。今の G-3 は3つの決まりでできているので、1つずつ扱います。
1. 理由は、確かめられる事実だけにする → **続けます**。次の1冊の理由は事実の1行のままです。
2. AI は背表紙を読むことにだけ使う → **変えます**。端末の中の要約を「前回まで」と「この本の3行」にだけ広げます。
3. 画面で「AI」と言わない → **分けます**。
   - 製品名、機能名、売り文句には「AI」を使いません。動作の言葉で言います（「撮ったページからまとめました」）。
   - 生成した文の横には、記号と小さな見出し「撮ったページからのまとめ」を必ず付けます。
   - 見出しを押すと、次の説明と2つのボタン（「もとの文を見る」「まとめを出さない」）が出ます。
     - 日本語：「この iPhone の Apple Intelligence が、あなたが撮ったページだけからまとめました。まちがうことがあります。本の文は、この iPhone の外に出ません。」
     - 英語：「Summarized from pages you captured」／「Apple Intelligence on this iPhone summarized only the pages you captured. It can make mistakes. Your book's text never leaves this iPhone.」
   - 生成でない読み取り（Vision の文字読み取り、バーコード）は、今のまま動作の言葉で言います（「読み取りました」）。

変える理由
- HIG Generative AI（2026-06-08 改訂）に「Clearly identify when and where you use AI.」「Communicate where your app uses AI.」とあります（R-1）。今の G-3 のまま生成した文を出すと、これに反します。
- Apple も、通知の要約を斜体にし、「Summaries may contain errors」を足しました（R-17。検索結果の要約で、記事の本文は開いていません）。
- 日本語の斜体は合成の斜めになり読みにくいので［推測］、斜体は使いません。記号と見出しの言葉で分け、色だけに頼りません。
- 日本の個人の生成 AI の利用経験は、2024年度が 26.7%、2025年度は 58.8% とされます（R-18。検索結果の要約）。慣れてきてはいますが、売り文句にするほどの得は見えません［推測］。
- Apple Intelligence のロゴを印に使えるかは調べていません（商標の扱い。tech-lead と reviewer に要確認）。

## 2. AI を芯にした方向の象徴の瞬間（10秒）
App Store のプレビューは音が消えた状態で始まり、手を映せません（reselect-designer の R-7）。そのため、案ごとに「音なしで伝わるか」も書きました。

### (i) 撮ったページの読み上げ「目を閉じても、続きが聞こえる」
- 0〜2秒：夜のベッド。文庫を開いたまま目をこする。
- 2〜5秒：iPhone をページにかざすと、右の行から細い線が縦に下りていく。
- 5〜8秒：読んでいる行だけが濃くなり、声はルビのとおりに読む。
- 8〜10秒：声が止まった行に、しおりと「p.62 から」が出る。
- 音なしで伝わるか：弱いです。中心が声なので、線で補うしかありません。
- 合う部門：Inclusivity（Speechify と同じ型）。
- 弱い所
  - OS がすでに無料で同じことをします。Accessibility Reader は「can be launched from any app」で、拡大鏡からも「text in the real world, like in books」を読めます（R-12）。日本語の縦書きを読めるかは調べていません。
  - Speechify の日本のレビュー（R-15）では、まさにここに不満が集まっています。
    - 「縦書きの本は１ページ２行ぐらいしか読み込まず殆ど飛ばして読み上げる」（★1、2026-03-14）
    - 「よみがな…いちいち2回読み上げるのはすごく気になります」（★3、2026-08-19）
    - 漢字の読み間違いが多い（★1、2026-07-11 など）
  - こちらの読み取りもルビで崩れます（前の調べもの）。
  - 一方で、払う気の声もあります。縦書きの PDF について「これが改善されるなら喜んで課金し続ける」（★2、2026-03-07）。縦書きとルビを正しく読めれば、日本ではお金になる筋です［推測。作れるかは tech-lead に要確認］。

### (ii) 前回のあらすじ「間が空いても、続きから」
- 0〜2秒：机の上に文庫。iPhone を手に取ると、ロック画面にいつもの一行。
- 2〜5秒：押すと「前回まで（10月12日の晩まで）」の2行と、印「撮ったページからのまとめ」。
- 5〜8秒：本を開き、2行と同じ場面を目で見つける。
- 8〜10秒：iPhone を伏せると、画面が消える。
- 音なしで伝わるか：伝わります（文字だけで足ります）。
- 合う部門：今の形と同じ Interaction。それに少し Inclusivity（覚えておくのが苦手な人が再開しやすくなる［推測］）。
- 型：Structured の「a thoughtful touch」と、Harvee の「on-device ... stays secure」に近いです（R-10）。
- 1文で言える違い：「あなたが撮った所しか知らないので、先を明かさない」。
- 弱い所：ページの文字を残す変更が要ります。ルビの崩れた文から日本語で要約したときの質は試していません。Apple Intelligence の機種だけで動きます。

### (iii) 言葉と登場人物の整理「紙の本に、自分だけの索引」
- 0〜3秒：人物の多い翻訳小説。しおりを挟むときにページを撮る。
- 3〜6秒：人名に細い下線が引かれ、「人物 7人」の札が1つ増える。
- 6〜10秒：名前を押すと「初めて出たのは p.12」と、そのとき撮った一行が出る。
- 音なしで伝わるか：伝わります。
- 合う部門：Innovation 寄り。Kindle の X-Ray の紙の本版に見えます［推測。X-Ray は今回開いていません］。
- 弱い所
  - 撮るのは1晩に1ページなので、撮らなかったページの人物は抜けます。
  - 人物の説明文を生成すると作り話になるので（R-1）、出たページと一行だけを出します。
  - 日本語の人名をどこまで正しく抜き出せるかは未確認です（tech-lead に要確認）。

### 2-1. 3案の比べ
| | (i) 読み上げ | (ii) 前回まで | (iii) 索引 |
|---|---|---|---|
| 今の形との相性 | ぶつかる（iPhone を起こしたまま） | 強める | 中くらい |
| 音なしの10秒 | 弱い | 伝わる | 伝わる |
| 先にあるもの | Speechify、OS の Accessibility Reader | Kindle（電子書籍だけ、米国だけ。R-13） | Kindle X-Ray（電子書籍） |
| 日本語の難所 | 縦書き、ルビ、漢字の読み | ルビの崩れた文の要約 | 人名の抜き出し |

- 推すのは、(ii) を今の形に足すことです。(i) は芯にしません。(iii) は後の版の候補にします。

## 3. 課金の体験
### 3-1. 毎晩の入口は、壁の外に置く
- 無料にするもの：ウィジェット、Live Activity、伏せる、終える、しおり、結果、登録、奥付、次の1冊、カード。つまり v1 のすべてです。
- 理由
  - HIG に「Let people experience your app before making a purchase.」とあります（R-2）。
  - ロック画面のウィジェットは、それだけで役に立つ情報にするものです（integrate-designer の R-3）。鍵の付いたウィジェットでは、毎晩の約束が守れません。
  - 1年後の継続率は、硬い壁 27%、フリーミアム 28% で、差はありません（R-16）。
- 自分のデータは人質にしません。自分の記録、毎晩の一行、書き出しは無料のままにします［推測。信頼のため］。
- 有料にしてよいのは、端末が新しく作るもの、見た目の選択、まとまった道具だけです。

### 3-2. 有料の中身（候補。決めるのは pdm）
- 有料は1つにまとめ、次を入れます。
  - 「前回まで」のまとめ（Apple Intelligence の機種）
  - 読み終えた夜の「この本の3行」（カードには載せない）
  - 言葉の手帳：語を押すと標準の辞書が開き、押した語だけを本ごとに残す。辞書の文は残さない（R-5 の「should not be used to display wordlists ... or republish the content」。読み方は reviewer に要確認）
  - 見た目の選択
- 払わない人も、久しぶりの夜には止めた一行を3晩分そのまま見られます（AI なし）。
- 買う画面には、使える機種の条件を書きます（3.1.2(c)「clearly describe what the user will get for the price」、R-9）。
- 払い方は2つまでにします（例：年額と買い切り）。期限つきの値引きと、数え下ろしの時計は置きません。値段と形は pdm が決めます。

### 3-3. どこで払う気になるか
- **決定的な瞬間は、1冊目を読み終えた夜です［推測］。**
  - カードの下に「この本の3行」と14晩分の一行が並び、積み重ねが目に見えます。
  - そこには文字ボタン「次の本でも残す」を1つだけ置き、押すとシートが開きます。主操作「この本を読む」は1つのままです（B-2）。
- **試用は「1冊」単位にし、7日にはしません。**
  - 1冊は何晩もかかります（絵コンテの例は14晩）。
  - 試用は長いほど有料になりやすく、17〜32日で 42.5%、4日未満で 25.5% です（R-16）。
  - 短い試用は不満のもとです。Speechify では「お試し期間が1週間程で…2万円のプレミアム勝手に移行されてた」（★1、2026-07-13）。3日の試用の解約は、55.4% が初日に起きています（R-16）。
  - そこで「1冊目は全部使える。カードは要らない。自動で払いは始まらない」にします。
  - これは使った量で区切る無料で、3.1.1 の「XX-day Trial」の型とは違います。審査で通るかは tech-lead と reviewer に要確認です（R-9）。
  - 1冊目で作ったまとめは、払わなくても消しません。

### 3-4. 割り込まない見せ方
| 置く所 | 形 | 根拠 |
|---|---|---|
| 読み終えた画面のいちばん下 | 文字ボタン1つ → シート | HIG「Prompt people to subscribe at relevant times」（R-2） |
| 設定 | 案内の行。払ったあとは次の更新日と「管理」（showManageSubscriptions） | HIG「Include a sign-up opportunity in your app's settings」「Always make it easy for customers to cancel」（R-2） |
| 有料の機能に自分から触れた所 | シート | 自分から求めたときだけ出す |
| 置かない所 | ウィジェット、Live Activity、読書中、結果、しおり、最初の起動 | 30秒のガードレール、3-1 |

- 最初の起動では案内しません。HIG には「Call attention to subscription benefits during onboarding」とあり（R-2）、ここは HIG から外れます。最初の起動の仕事は、1冊を加えて今夜の入口を作ることだからです。G1 の仕様に、外れる理由を書きます。
- シートの決まり
  - 標準の部品を使います。年額は SubscriptionStoreView、買い切りは ProductView です（R-4）。
  - SubscriptionStoreView は、利用規約とプライバシーのボタン、閉じるボタンを自動で出します。閉じるボタンは隠しません。
  - 次のものを出します：名前、期間、中身、地域の通貨での総額、購入の復元（R-2）。
  - システムの確認シートは、まねも改変もしません（「Don't modify or replicate this sheet.」）。
  - 払えない端末では、ストアを隠すか、使えない理由を書きます（HIG「Display your store only when people can make payments」）。
  - 見た目はアプリと同じ調子にします（「Design an integrated shopping experience」）。

### 3-5. 前の不満の型と、それを避ける形
| 不満の型 | 例 | 避け方 |
|---|---|---|
| 使う前に払わせる壁 | 前の調べもの | 入口と出口は無料。1冊目は全部使える |
| 割り込む案内 | 前の調べもの | 毎晩の道には案内を0にする。モーダルで出さない |
| 試用からいつの間にか課金 | Speechify ★1、2026-07-13 | カードの要らない1冊の試用 |
| 解約しにくい | Speechify ★1、2026-09-30「解約手続きが難しい」 | 設定に管理の行を置く |
| 親が管理する端末で試用に入ってしまう | Speechify ★2、2026-06-09 | 払えない端末では買う画面を出さないか、理由を書く |
| 広告と中身が違う | Speechify ★1、2025-09-20「誇大広告」 | 機種の条件を書く。ストアの画像は実際の大きさで見せる |

## 4. Apple Design Award と AI
### 4-1. AI を使った作（紹介文の引用。R-10、R-11）
| 年 | 部門 | 作 | 立場 | 使い方 |
|---|---|---|---|---|
| 2026 | Inclusivity | Hearing Buddy | 最終候補 | 「uses the Foundation Models framework and on-device speech-to-text features to quickly generate real-time captions and summaries」 |
| 2026 | Inclusivity | Structured | 最終候補 | 「incorporates the Foundation Models framework to suggest and pre-fill tasks — a thoughtful touch」 |
| 2026 | Innovation | Detail: AI Video Editor | 最終候補 | 「turn a draft or outline into a ready-to-record teleprompter script」 |
| 2026 | Social Impact | Harvee | 最終候補 | 「powered by on-device foundation models, sensitive health data stays secure」 |
| 2025 | Innovation | Moises | 最終候補 | 「using machine learning models to separate out the vocals」 |
| 2025 | Innovation | Capybara AI Meeting Translator | 最終候補 | 「powered by the Apple Intelligence Translate API」 |
| 2025 | Inclusivity | Train Fitness | 最終候補 | 「CoreMotion and CoreML ... eliminating the need for interaction with a screen」 |
| 2025 | Interaction | Mela | 最終候補 | 「recipe scanning is powered by the Vision framework」 |

- 2026年と2025年の受賞作（アプリ各6本）の紹介文に、AI の語は1つもありません。

### 4-2. 使い方の型
- **A：1つの作業を軽くする「さりげない一手」**。Structured、Detail。
- **B：端末の中で処理するから、敏感なものを預けられる**。Harvee、Hearing Buddy。
- **C：アクセシビリティの道具**。Hearing Buddy、Train Fitness、Speechify。
- (ii) の「前回まで」は A と B に当たります。

### 4-3. AI を前に出さない受賞作
- **CapWords**（2025 Delight and Fun）：紹介文は「Learn the name of a thing by taking a picture of it」だけです。
- **Speechify**（2025 Inclusivity）：「turns any written text into audio」。AI の語はなく、ほめているのは「Dynamic Type and VoiceOver」と「reduce cognitive load」です。
- **Sago Mini Jinja's Garden**（2026 Interaction のゲーム部門）：「integrates inclusivity features so organically that players and caregivers may not even notice them」。
- 受賞作は、AI で何ができるようになったかを、人に見える体験として語っています［推測］。部門の狙いは今のまま、Interaction を主、Inclusivity を従にします。

## 5. 推す組み合わせと、いちばん強い反論
### 5-1. 推す組み合わせ
| 場面 | 中身 | 無料／有料 |
|---|---|---|
| 毎晩の入口 | 一行 → 伏せる → 終える → しおり → 結果。何も足さない | 無料 |
| 久しぶりの夜 | 止めた一行を3晩分（AI なし） | 無料 |
| 久しぶりの夜 | 「前回まで」の2行（印つき） | 有料（AI の機種） |
| 本の出口 | 奥付、次の1冊（事実の1行）、カード | 無料 |
| 本の出口 | 「この本の3行」と「次の本でも残す」の文字ボタン | 有料（1冊目は無料） |
| 道具 | 言葉の手帳（標準の辞書）、見た目の選択 | 有料 |
| 入れないもの | 読み上げ、生成した理由の文、「AI」という名前 | - |

### 5-2. いちばん強い反論
- **お金が少ないおそれ。**
  - フリーミアムの Day-60 のインストールあたり収益は $0.38 で、硬い壁は $3.09 です（R-16）。
  - 有料の出番は、久しぶりの夜と読み終えた夜だけで、まれです。
  - AI の部分は対応機種でしか動きません。日本の iPhone のうち対応機種の割合は調べていません（pdm と tech-lead に要確認）。
- **それでも壁を作らない理由。**
  - 入口に壁を置くと、ウィジェットの約束、共感の広さ、10秒の映像が壊れます。
  - 1年後の継続率は、壁があってもなくても同じです（R-16）。
  - 収益が足りなければ、値段と見た目の選択で調整し、壁は作りません［推測］。
- **次に強い反論：要約の質が確かめられていません。**
  - 予定している「文庫のページを5枚撮る」確かめで、まとめも作ります。5枚中4枚以上で Takuma が「合っている」と言えるかを見ます。

### 5-3. HIG とアクセシビリティで気をつける所
- **VoiceOver**
  - まとめは印から先に読みます（「撮ったページからのまとめ。前回まで、…」）。
  - 読む順は、書名 → 前回まで → 一行 → ページ → 読み始める、です。
- **Dynamic Type**：大きい文字ではまとめを省略せず、折り返して全部出します。AX5 で一行が横書きに変わるときは、まとめを一行の下に回します。
- **動きを減らす設定**：1字ずつ出る演出はしません。作っておいた文を一度に出します。待ちがあるときは、何をしているかを言います（「撮ったページをまとめています」、R-1）。
- **ダークモード**
  - まとめの文字は補足の灰にします。コントラストは白地で約5.1:1、黒地で約7.3:1 です（README の値）。
  - コントラストを上げる設定のときは本文の色にします。
  - 斜体は使いません。色だけで印を示しません。
- **素材**：まとめは内容の層なので、素材を使いません。シートは標準のままです。
- **権限**：処理は端末の中なので、外へ送る許可は要りません（5.1.2(i) は第三者の AI に送るときの決まり、R-9）。

## 根拠
| R | 中身 | URL | 開いた日 |
|---|---|---|---|
| R-1 | HIG Generative AI（改訂 2026-06-08） | https://developer.apple.com/design/human-interface-guidelines/generative-ai （本文は .../tutorials/data/design/human-interface-guidelines/generative-ai.json） | 2026-10-18 |
| R-2 | HIG Apple In-App Purchase（改訂 2026-09-17） | https://developer.apple.com/design/human-interface-guidelines/apple-in-app-purchase | 2026-10-18 |
| R-3 | HIG Machine learning | https://developer.apple.com/design/human-interface-guidelines/machine-learning （前の体の JSON。取り直していない） | 2026-10-18 |
| R-4 | ProductView、SubscriptionStoreView | https://developer.apple.com/documentation/storekit/productview 、https://developer.apple.com/documentation/storekit/subscriptionstoreview （前の体の JSON） | 2026-10-18 |
| R-5 | UIReferenceLibraryViewController | https://developer.apple.com/documentation/uikit/uireferencelibraryviewcontroller （前の体の JSON） | 2026-10-18 |
| R-6 | SystemLanguageModel.Availability | https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum （前の体の JSON） | 2026-10-18 |
| R-7 | TN3193（4,096 トークン、日本語は約1字で1トークン） | https://developer.apple.com/documentation/technotes/tn3193-managing-the-on-device-foundation-model-s-context-window | 2026-10-18 |
| R-8 | Foundation Models の利用の決まり（本の文の要約を名指しで禁じる項目はない。知的財産を侵さないこと、と AI 生成のラベルを消さないことはある） | https://developer.apple.com/apple-intelligence/acceptable-use-requirements-for-the-foundation-models-framework/ | 2026-10-18 |
| R-9 | 審査ガイドライン 3.1.1、3.1.2(a)(c)、5.1.2(i) | https://developer.apple.com/app-store/review/guidelines/ | 2026-10-18 |
| R-10 | ADA 2026 | https://developer.apple.com/design/awards/ | 2026-10-18 |
| R-11 | ADA 2025 | https://developer.apple.com/design/awards/2025/ | 2026-10-18 |
| R-12 | Apple Newsroom 2025-05-13（Accessibility Reader） | https://www.apple.com/newsroom/2025/05/apple-unveils-powerful-accessibility-features-coming-later-this-year/ | 2026-10-18 |
| R-13 | BGR 2026-06-12（Kindle の Story So Far。「catch up ... after a long break」、米国だけ。料金は書いていない） | https://bgr.com/2192985/kindle-cool-new-feature-story-so-far-june/ | 2026-10-18 |
| R-14 | Kindle の Recaps と Ask this Book（検索結果の要約だけ） | https://wbgsv0a.gigazine.net/gsc_news/en/20250407-kindle-recaps 、https://gigazine.net/gsc_news/en/20251216-ask-this-book | 2026-10-18（本文は開いていない） |
| R-15 | Speechify の日本のレビュー（新しい順に50件。評価 4.41、4,430件） | https://itunes.apple.com/jp/rss/customerreviews/page=1/id=1209815023/sortby=mostrecent/json | 前の体が 2026-10-18 に取得。フィードの更新は 2026-10-17 |
| R-16 | RevenueCat 2026（2026-03-19、115,000本超） | https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026 | 2026-10-18 |
| R-17 | iOS 18.3 の要約の斜体と注意書き（検索結果の要約だけ） | https://9to5mac.com/2025/01/17/ios-18-3-beta-3-changes-features-notification-summary-fix-video/ | 2026-10-18（本文は開いていない） |
| R-18 | 日本の生成 AI の利用経験（検索結果の要約だけ） | https://www.sakigake.jp/news/article/20250708CO0101/ 、https://www.soumu.go.jp/main_content/001082851.pdf | 2026-10-18（本文は開いていない） |

- リポジトリで読んだもの：integrate-designer（1-1、5、6）、reselect-designer（0、3）、integrate-proposal、PRD の 9 と 10、design/explore/integrated/README.md、design/001-reading-session-research.md の冒頭。

## 変更したファイル
- リポジトリ：なし。
- 作業用（リポジトリの外）：
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ai-designer/notes.md：新しく作り、進めながら書き足した
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ai-designer/dl/tn3193/tn3193.json と /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ai-designer/out/tn3193.txt
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ai-designer/dl/verify/（前の体の取り込みを確かめるための取り直し）

## 実行したコマンドと結果
- **前の体の残り物**
  - ls と cat で中身を見ました。notes.md はありませんでした。
  - scripts は JSON を読んで文字にするだけで、通信もファイルへの書き込みもしません。
  - 使ったもの：out/iap.txt、out/genai.txt、out/ml-docs.txt、dl/speechify-*.json（`python3 -I scripts/rss.py` で抜き出した）。
  - iap2.json と genai.json は、curl で取り直した JSON と cmp でバイト単位まで同じでした（HTTP 200、71,599 と 47,058 バイト）。古い in-app-purchase.json は 404 で、ページの名前が変わっていました。
  - 取り直していないもの：ml、fm-availability、productview、subscriptionstoreview、reflib の各 JSON と、Speechify の2つのファイル。
- **WebFetch**：ADA 2026、ADA 2025、Apple Newsroom、BGR、審査ガイドライン、RevenueCat、FM の利用の決まり。
  - 審査ガイドラインは 0〜100,000 字まで読みました。残りの 14,428 字は読んでいません。
- **開けなかったもの**：TN3193 の HTML は、WebFetch で本文が取れませんでした。代わりに JSON を curl で取りました（HTTP 200、37,161 バイト）。
- **WebSearch**：Kindle、情報通信白書、RevenueCat、iOS 18.3 の4件。R-14、R-17、R-18 は検索結果の要約だけで、記事の本文は開いていません。
- **ガードに止められたこと**：Bash の書き先に変数を使って2回止められました。パスをそのまま書いて実行し直しました。curl の1回目はフォルダがなく 0 バイトだったので、--create-dirs を付けて取り直しました。
- ツールの呼び出しは約35回でした。

## 未解決
- **PRD との衝突（pdm と Takuma）**
  - PRD 10 の「あらすじ、生成 AI の紹介文は出さない（S-10）」と、9 の削った候補（RICE 75）。
  - 「写真は残さない」は保ちつつ、ページの文字を端末に残す変更が要ります。本を消すときの扱いも決める必要があります。
  - PRD 16 と Q5 の課金の書き換え。
  - PRD にない提案：言葉の手帳、見た目の選択、この本の3行、14晩の一行の並び、1冊の試用。
- **tech-lead に要確認**
  - 日本語の文庫（ルビの崩れを含む）から、正しい2行のまとめが作れるか。
  - 裏での生成が、時間と電池の面で成り立つか。
  - Availability の4つの状態の扱い。
  - 「1冊目は無料」を審査で通せるか（reviewer にも）。
  - Apple Intelligence のロゴを印に使えるか。
  - Accessibility Reader が日本語の縦書きを読めるか。
  - 端末に日本語の辞書が入っているか。
  - 日本の iPhone のうち、対応機種の割合（pdm にも）。
- **Takuma に決めてほしいこと**
  - G-3 を改めるか。
  - 「前回まで」を出すまでの空きの線（仮に4晩）と、日付で示すこと。
  - 課金の案内を、読み終えた画面と設定だけに置くこと（HIG の onboarding の一文から外れる）。
- **確かめの追加の案**
  - 5人への聞き取りに1問足す：「間が空いたあと、前に何が起きていたか思い出せず読み返したことはあるか。それを2行で出すものに、年に〇〇円なら払うか」。
  - 予定の「文庫のページを5枚撮る」確かめで、まとめの正しさも見る。
- **テンプレートの「確かめ」**：調べものなので、印は付けていません。
- **見ていないもの**：Kindle の画面と、そこに AI の表示があるかどうか。国内アプリで「AI」の語がどう受け止められているか。Accessibility Reader の実際の画面。実機。

## 記録（指揮役が保存するときに書き足す）
- 種類：収益とローカル AI を検討するための調べもの（designer）。PASS / FAIL なし
- 対象：Takuma の返事（2026-10-18。docs/approvals/001-reading-session-G0-Q8.md の最後の節）。BASE=53394fd
- 日付：2026-10-18
