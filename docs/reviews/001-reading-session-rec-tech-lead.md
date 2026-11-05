（指揮役の注）Takuma の 2026-10-21 の決定「本物まで出しましょう。機械学習とかの方向も検討して」への調べもののうち、tech-lead の報告（集める道、冷たい始まりの模型、端末の中の機械学習の spike、版ごとの案）。pdm も並べて調べた。判定ではない。報告の文はそのまま保存した。

# 本物のレコメンド（他人の読書から作る推薦）と機械学習の方向：技術の調べと spike（tech-lead）

- 日付：2026-10-21
- 種類：調べものと spike。リポジトリには書いていません。書いたのは scratchpad の rec-tech/ だけです。
- 以下、R/ は /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/rec-tech/ を指します。
- 手数：41回。

## 全体の結論（先に）
1. **他人の読書から作る推薦は、作れます。ただし、出した日は0人です。**
   - 要るものは3つです。
     - 集める場所（自前の小さなサーバーか CloudKit）
     - 同意と取り消し（審査ガイドライン 5.1.1(ii)。匿名でも要ります）
     - 人数のしきい値
   - 匿名の集計や中継を Apple が第三者のアプリに出している仕組みは、文書では見つかりませんでした。だから「サーバーなし」と「本物」は両立しません。
   - 集計の結果（この本を読み終えた人が次に読み終えた本の表）は、書誌データと同じ asset pack で端末に配れます。そうすれば、推薦は端末の中で動き、問い合わせの通信は要りません。外に出るのは「同意した人が送る組」だけです。
2. **冷たい始まりは重いです**（模型の spike［推測］）。
   - 送るのが「続けて読み終えた2冊の組」で、しきい値が5人の場合：
     - 送る人が 1,000人：「これを読んだ人は」が出る夜は 0%。
     - 送る人が 10,000人：3冊以上出る夜は 25%。
     - 送る人が 100,000人：同じく 46%。
   - PRD 16 の1年のダウンロードの見込みは 3,000〜50,000 です。そのため、1年目に「本物」が出る夜は少数の見込みです。
3. **機械学習（サーバーなし、端末の中）でできるのは、「内容が似た本」と「その人の好みの並べ替え」までです。**
   - 「これを読んだ人は」は、他人のデータなしには作れません。端末の中で学習できるのは、利用者1人の好みの重み付けまでです。
   - NLContextualEmbedding は日本語で動きました（macOS 27）。効き目は控えめです。
     - 本の分野（NDC の頭2桁）を当てる割合（上位5件で）：埋め込み 0.279、規則 0.171、でたらめ 0.063。
     - 小説の型（4種、上位3件で）：埋め込み 0.458、でたらめ 0.226。
   - iOS 27 のシミュレーターでは、モデルが見つからず動きませんでした（3分42秒で失敗）。

---

## 1. 他人の読書から作る推薦に要るもの（道ごと）

### 結論
- **推すのは (b) 自前の最小のサーバーです。** (d) で集めるものを最小にし、(e) の Background Assets で配ります。
  - 受け口は1つです。生の記録は持たず、組ごとの数だけを足します。毎月、しきい値を超えた組だけを表にして、asset pack で配ります。
- (a) CloudKit の公開 DB でも集められます。ただし匿名になりません。書いた人の creatorUserRecordID が付き、iCloud にサインインしていない人は書けません。集計の仕組みもないので、集計は結局 Mac かサーバーで動かすことになります。
- (c) Apple の匿名の集計の仕組みで第三者が使えるものは、ありませんでした（下の表）。

### できること・できないことの表
| 項目 | 判定 | 根拠 |
|---|---|---|
| (a) CloudKit の公開 DB に「組」を書く | できる | 公開 DB は RBAC。「Roles include World, Authenticated, and Creator.」 |
| (a) 他の利用者に生の組を読ませない | できる | 権限を Authenticated＝create、Creator＝read/write、World＝なし にする。「The Creator role includes only the authenticated user who has created a record.」 |
| (a) 匿名で書く | できない | どの記録にも creatorUserRecordID が付く（「The ID of the user who creates the record.」）。開発者の側では、仮名の利用者に結び付く |
| (a) iCloud にサインインしていない人が送る | できない | create は Authenticated の役だけ。World には書く権限を付けられない（2016年の記事。Apple の今の文書では未確認） |
| (a) CloudKit の中で数える | できない | 集計の問い合わせはない［推測。文書に記載なし］。全件をサーバー間キーで読み、外で数える |
| (a) 上限と費用 | 未確認 | 公式は「up to 1PB of storage for your app's public data」だけ。DPLA 2.8：「Apple reserves the right to charge fees for Your use of the Apple Services.」 |
| (a) 規約で集計に使ってよいか | 禁止は見つからない | DPLA：公開 DB の保存は許される（「permitted to use the CloudKit APIs for storing, retrieving, and querying of structured data that You choose to store in public or private containers」）。守る義務は「must take reasonable and appropriate steps to protect information You store through the iCloud service」と、3.2 の「access, collect, or transmit user data beyond what was disclosed when consent was requested」の禁止 |
| (b) 自前の最小のサーバー（受け口1つ、集計、静的な表） | できる | Cloudflare Workers の無料の枠は「100,000 per day」。D1 の無料の枠は書き込み「100,000 / day」、保存「5 GB (total)」 |
| (c) Apple の差分プライバシーを第三者が使う | ない | 公開の API は見つからない。Apple の crowd anonymity は AdAttributionKit（広告の計測）の中だけ |
| (c) Apple の OHTTP 中継を使う | 一般のアプリはできない | Apple の中継は Live Caller ID Lookup 用（「requires you to use Apple relay servers」）。フォームで申し込み、許可を待つ（フォーラム 817921。製品版で通らない報告あり） |
| (c) OS の OHTTP の機能で、他社の中継を使う | 仕組みはある。中継が手に入らない | ProxyConfiguration（iOS 17）：「A proxy configuration for Relays, Oblivious HTTP, HTTP CONNECT, or SOCKSv5.」。Cloudflare の中継は「Enterprise-only」「currently in closed beta」 |
| (d) ISBN をハッシュにして匿名にする | 効かない | ISBN は約295万種しかないので、辞書で総当たりすれば戻せる［推測。計算するまでもない］。守りになるのは、しきい値と、生の記録を残さないこと |
| (d) 端末の側で雑音を足す（局所差分プライバシー） | この人数では使えない［推測］ | 数千〜数万人では、雑音が組の数を消してしまう |
| (e) 集計の表を Background Assets で配り、端末で引く | できる | 表は小さい。模型では、送る人10万人でも「表に載る本」は1,128冊で、1冊10件までなら約200 KB［推測］。asset pack の版を出すたびに審査が要る（expand-tech-lead の 1） |

### 集めるものを最小にする形（推す形）
- **送るもの**
  - 「前に読み終えた本 → 今読み終えた本」の ISBN の組を、読み終えるたびに1件だけ送ります。
  - 両方が同梱データにあり、両方が NDC 9（文学）の組だけを送ります。これで、医療、宗教、性などの扱いに気をつける本の組は外に出ません。
  - 送らないもの：時刻（端末で週1回にまとめ、時刻はぼかす）、一行、ページ、分数、端末の ID。
- **サーバーの側**
  - 組ごとの数を1つ足すだけで、受けた行は残しません。IP の記録も残しません（Workers は既定で残さない［推測。Logpush を入れなければ］）。
- **出す条件**
  - 組の数が k 以上（5〜10）で、両方の本がそれぞれ k 人以上に読まれているもの。
  - 1冊につき上位 N 件まで。数は丸めます。出すのは毎月だけにし、数が動くのを見て人を当てられないようにします。
- **版の扱い**
  - 同じ作品の単行本と文庫は、別々の ISBN です。作品の単位にまとめないと、数が割れます。同梱データには作品の ID がないので、書名と著者をそろえてまとめる必要があります（手間と精度は未確認）。

### 冷たい始まり（spike。模型なので数字は全部［推測］）
模型の仮定は次のとおりです。
- 本は 40万冊。人気は Zipf（s＝1.0 と 0.8）。好みの群は30個で、7割を自分の群から選びます。
- 1人が1年に読み終える本は、平均12冊です。

| 送る形 | k | 人気 s | 送る人 1,000 | 3,000 | 10,000 | 30,000 | 100,000 |
|---|---|---|---|---|---|---|---|
| 続けて読んだ組 | 5 | 1.0 | 0% / 0% | 20% / 9% | 32% / 25% | 42% / 36% | 52% / 46% |
| 続けて読んだ組 | 10 | 1.0 | 0% / 0% | 9% / 0% | 24% / 18% | 35% / 28% | 45% / 39% |
| 1年の組の全部 | 5 | 1.0 | 33% / 27% | 44% / 38% | 54% / 48% | 63% / 58% | ー |
| 続けて読んだ組 | 5 | 0.8 | 0% / 0% | 0% / 0% | 6% / 0% | 10% / 6% | 18% / 12% |

- 表の数字は「読み終えた夜のうち、その本の『これを読んだ人は』が1冊以上出る割合 / 3冊以上出る割合」です。
- 「送る人」は、同意して送った人の数です。同意する人が3割なら、要る利用者はこの約3.3倍です。
- 「1年の組の全部」を送ると、少ない人数で出るようになります。そのかわり、1人の読書の一覧を丸ごと送ることになり、人を当てられやすくなります。推しません。
- 人気の偏りが小さい（s＝0.8）と、10万人でも12%です。偏りの実際の値は確かめていません。

### 道ごとの手間、費用、危険
手間は、1人の作り手の日です。G1〜G3 を含みます。

| 道 | 手間 | 月の費用（利用者1,000人） | 危険 | 冷たい始まり |
|---|---|---|---|---|
| (a) CloudKit の公開 DB | +4.0〜7.0日［推測］：権限と記録の型 0.5〜1.0、iCloud のない人・同意・取り消し 1.0〜1.5、Mac での集計 1.0〜2.0、表の配布と表示 1.0〜1.5、テスト 0.5〜1.0 | 0ドル［推測。無料の枠は公開されていない］ | 仮名の ID に結び付く（プライバシー表示は「ユーザーに関連付けられたデータ」になる見込み［推測］）。iCloud のない人は送れない。Apple が上限と料金を変えうる（DPLA 2.8） | (b) と同じ |
| (b) 自前の最小のサーバー（推す） | +5.0〜8.0日［推測］：受け口 1.0〜1.5、App Attest 1.0〜1.5、同意・取り消し・ポリシーと表示の直し 1.0〜1.5、毎月の集計と asset pack への書き出し 0.5〜1.0、表示（しきい値に満たない本は規則に戻る）1.0〜1.5、脅威モデル・RUNBOOK・契約・受け入れテスト 0.5〜1.0。運用は毎月 0.25〜0.5日 | 0ドル。1,000人なら月 約1,000件の送信で、無料の枠（1日 10万件）の中。上限を広げるなら Workers の有料の枠で月5ドル。ドメインの費用は未確認 | 運用（止まったとき、偽の送信）。偽の送り手は App Attest で減らせる。ただ、同じ端末が同じ組を何度も押し上げるのを防ぐには端末ごとの記録が要り、匿名と引き換えになる（設計が要る） | 上の表 |
| (c) Apple の匿名の仕組み | ー | ー | 使える仕組みがない | ー |

### 審査と法律で変わること（(a) と (b) で共通）
- **5.1.1(ii)**：「Apps that collect user or usage data must secure user consent for the collection, even if such data is considered to be anonymous」。
  - 同意の画面と、取り消しの道が要ります。
  - 「Paid functionality must not be dependent on or require a user to grant access to this data」。推薦は無料の側に置いているので当たりません。
- **5.1.1(i)**：ポリシーに、保持と削除と取り消しの方法を書きます。
  - (b) では、送った組は数にまとめた時点で個別に消せません。そのことと「取り消しは、送るのをやめること」を書きます［推測。G5 で reviewer が見る］。
- **5.1.1(iii)**：「only collect and use data that is required to accomplish the relevant task」。
  - 「出す前から集める」は、この線とぶつかるおそれがあります［推測］。
- **プライバシー表示**
  - 「データの収集なし」から「収集あり」に変わります。
  - 区分は「使用状況データ」か「その他のユーザーコンテンツ」の見込みです［推測］。
  - (b) で ID を持たず数だけを残す形なら、「ユーザーに関連付けられないデータ」にできる見込みです。Apple の条件は「Stripping data of any direct identifiers … before collection」「You must not attempt to link the data back」です［推測］。
- **外部送信規律**
  - 総務省のページでは、アプリの提供者も対象です。送信先が自社のときに通知・公表が要らないのは「サービス提供に当たって必要な情報」などに限られます。ページは文字化けしていて、取得の道具が文脈から戻した部分を含むので、原文の確かめは未了です。
  - 他人への推薦のための組は「必要な情報」に当たらない見込みです［推測］。だから同意か通知・公表が要ります。同意を取る形なら満たせる見込みです。今の K1 と合わせて、法律の判断は Takuma を通します。
- **製品の約束**：「読んだ本の名前は端末の外に出ない」を「同意した人の、読み終えた文学の2冊の組だけが、名前のない数として出る」に変えます。掲載文に「何も外に送らない」とは書けません（PRD 17 はすでにそうしています）。
- **1.2（他人の投稿）**：数を出すだけで、他人の文や名前は出ないので、当たらない見込みです［推測］。
- **新しい境界**：サーバーができます。(b) の軽い STRIDE は次のとおりです。
  - なりすまし：App Attest。
  - 改ざん（組を押し上げて特定の本を売り込む）：1端末1日の上限と、しきい値。
  - 情報の漏れ（珍しい組から人を当てる）：k と NDC 9 だけ、毎月だけ出す。
  - 止める攻撃：Workers の上限。
  - 管理の入口：持たない（集計は手元で行う）。

---

## 2. 機械学習の方向（サーバーなし、端末の中）

### 結論
- **内容に基づく推薦は作れます。** ただし「これを読んだ人は」の代わりにはなりません。
  - NLContextualEmbedding（iOS 17 から）は日本語で動き、書名の意味の近さを少し捉えます。小説の型は半分も当てません。
  - 実機では、Apple から模型を落とす必要があります（Apple への通信で、こちらへの通信ではありません）。大きさと時間は未確認です。シミュレーターでは動かないので、G3 のテストでは差し替えが要ります。
- **NLEmbedding（文と単語の埋め込み）は日本語がありません**（spike で nil）。
- **Create ML の MLRecommender は、多くの人の記録で学習した模型を配る道具です。** 1人分のデータでは推薦が0件でした（spike）。
  - 学習は macOS だけです。「これを読んだ人は」を配る形としては、(e) の表と同じことをするだけです。しかもしきい値をかけられないので、自前の表を推します。
- **日本語の読書の記録で、営利に使える公開データは見つかりませんでした。**
  - 楽天データセットは大学と公的な研究機関だけです（ALAGIN：「民間企業等の方は、申し訳ありませんがご利用いただけません」）。
  - Goodreads 系は英語の本で、日本の本には効かない見込みです［推測］。
- **Foundation Models は、選ばせることには使いません**（前の spike：理由がデータと合わない 32/48、別の版を選ぶ 5/48）。
  - 使い道があるとすれば、規則で決めた候補と理由の型の上で、並べ替えの入力に「利用者が自分で書いた一行の雰囲気」を足すことくらいです。対応する機種が約4〜5割で、裁定 12（AI に文を作らせない）と裁定 17（AI の部分は無料）もあるので、v1.0 では推しません。
  - FoundationModels の文書の冒頭には、埋め込みを返す API の記載はありませんでした。全部は見ていないので未確認です。
- **「学習する」の正直な線**
  - 端末の中で学べるのは、その人の好みの重み付けまでです。たとえば、出した理由の種類（同じ著者、次の巻、同じ賞、内容が近い）ごとに「選んだ / 見送った」を数え、並びの重みを変えます。
  - Core ML の更新できる模型（MLUpdateTask）までは要りません。数を数えるだけで足ります［推測］。

### できること・できないことの表
| 項目 | 判定 | 根拠 |
|---|---|---|
| NLEmbedding.sentenceEmbedding(.japanese) | できない | spike：false（英語は true、簡体中国語も false） |
| NLEmbedding.wordEmbedding(.japanese) | できない | spike：false |
| NLContextualEmbedding(.japanese)（macOS 27） | できる | 次元 512、最大 256 トークン、rev 1。1つの模型で ja、ko、zh-Hans、zh-Hant を扱う。模型は Mac に入っていた |
| 同じもの（iOS 27 シミュレーター） | できない | hasAssets=false。requestAssets は 3分42秒後に「Failed to locate embedding model」 |
| 同じもの（iPhone の実機） | 未確認 | 文書：「Call [requestAssets] before computing the embedding to confirm assets are available.」。Takuma の端末で確かめる |
| 同梱の全冊の埋め込みを前もって作って配る | 大きすぎる | 計算：295万冊 × 512 × 1バイト ＝ 1.51 GB。文学40万冊で 205 MB。64次元に縮めても 189 MB と 25.6 MB。端末の模型の版（revision）とずれると使えない |
| 候補（200冊まで）だけ端末で埋め込み、並べ替える | できる（速さは実機で未確認） | Mac で書名1件あたり中央値 14.86 ms。200冊なら約3秒［計算。M2 Pro］ |
| MLRecommender を多くの人のデータで学習して同梱する | できる（学習は macOS だけ） | 2,000人の合成データで、5件全部が同じ好みの群。模型は 5,000冊で 1.77 MB。推薦は 0.1 ms。対応 OS は「macOS 10.15」だけ |
| MLRecommender を1人のデータで学習する | 推薦が出ない | spike：0件 |
| 日本語の読書の記録の公開データ（営利に使える） | 見つからない | 検索2回。楽天データセットは研究だけ。大学図書館の貸出の研究は、データが公開されていない |

### spike の結果
**A. 日本語の埋め込み（R/spike/emb.swift）**
- 材料：本物の書誌 895件（前の spike の oai_sample.sqlite）と、私が型を付けた小説32冊（R/out/novels32.tsv。型の付け方は私の知識［推測］）。
- 本の分野を当てる割合（NDC のある661件。NDC の頭2桁が同じ本が、上位5件に入る割合）：

| 並べ方 | 割合 |
|---|---|
| でたらめ（期待値） | 0.063 |
| 規則（著者 3、叢書 2、出版社 1 の点） | 0.171 |
| 書名の2文字の重なり（ML なし） | 0.173 |
| 埋め込み（書名だけ） | 0.248 |
| 埋め込み（書名＋著者＋出版社＋叢書） | 0.279 |

- 小説32冊（4つの型。同じ型が上位3件に入る割合）：でたらめ 0.226、書名だけ 0.427、書名＋著者 0.458。
- 例
  - 『竜馬がゆく』→『燃えよ剣』(0.856)。同じ著者の名前が効いています。
  - 『ノルウェイの森』→『蝉しぐれ』（時代小説）。
  - 『日本沈没』→『八つ墓村』（推理）。
  - 「女特攻捜査官」→『刑事訴訟法』。書名の語に引きずられています。
- 速さとメモリ（Mac M2 Pro）：模型を開くのに 0.525秒。1件あたり中央値 14.86 ms、いちばん遅い1件で 88.2 ms。プロセスのメモリの最大は 169.6 MB。
- 読み方
  - 実用書では、分野の近さを規則より拾います。
  - 小説では、書名だけでは型をほとんど知りません。帯の文やあらすじがないためです。NDL の書誌にはあらすじがありません。
  - だから小説の推薦の芯は、規則（著者、次の巻、賞、レーベル）のままにします。埋め込みは「同じ規則の点のときの並べ替え」に使うのが上限です［推測］。

**B. 冷たい始まりの模型（R/scripts/coldstart.py）**：1 の表のとおり。

**C. MLRecommender（R/spike/mlrec.swift）**
- 3回動かしました。どの回も、多くの人で学習した模型は5件全部が同じ群でした（でたらめなら約0.25件）。学習は約0.33秒、模型は約1.77 MB です。
- 1人では推薦が0件でした。
- `recommendations(fromUsers:)` と、String を MLIdentifier にする使い方は、macOS 14 で非推奨になっています（警告）。

### 手間と費用と危険（v1.0 の端末の中の部分）
| 部分 | 手間 | 費用 | 危険 |
|---|---|---|---|
| 規則と同梱データ（この著者のほかの本、次の巻、同じ賞） | +1.0〜2.0日（前の報告で数えた分） | 0 | 著者の書き方をそろえること |
| 内容の近さ（ML なし。NDC、件名、レーベル、書名の文字の重なり） | +0.5〜1.0日［推測］ | 0 | 小説では弱い |
| NLContextualEmbedding での並べ替え | +1.5〜3.0日［推測］（模型の取得、版の確かめ、模型がないときの道、テストの差し替え） | 0（Apple から模型を落とす） | シミュレーターで動かない。実機の速さとメモリは未確認。効き目が控えめ |
| 好みの重み付け（端末で数える） | +0.5〜1.0日［推測］ | 0 | 数が少ないうちは効かない |

---

## 3. 版ごとの道筋の案

### 案の表
| 案 | v1.0 | v1.x | 手間（足す分） | 費用（月） | 危険 | 審査と法律 |
|---|---|---|---|---|---|---|
| 甲：v1.0 から集める（推す） | 端末の中の推薦（規則＋同梱データ＋好みの重み付け）。同意した人から文学の組を送る。表が人数に届いた本だけ「これを読んだ人は」を出し、届かない本は規則に戻る（名前は pdm と designer） | 毎月の表を asset pack で配る。埋め込みの並べ替えは、実機で確かめてから | +6.0〜10.0日［推測］（サーバー 5.0〜8.0 ＋ 端末の中 1.0〜2.0） | 0ドル（無料の枠）〜5ドル | 3週の枠がさらに苦しくなる。最初の数か月は、ほぼ出ない。運用 | 表示は「収集あり」。5.1.1(ii) の同意。外部送信規律。出す前から集めること（5.1.1(iii)）の説明 |
| 乙：v1.1 から集める | 端末の中の推薦だけ。表示は「データの収集なし」のまま | 同意と送信を足し、人数がそろってから出す | v1.0 は +1.0〜2.0日。v1.1 で +5.0〜8.0日 | v1.0 は0ドル | 集め始めが数か月遅れ、本物が出る時期がそのぶん遅れる | v1.0 は今の約束のまま |
| 丙：CloudKit で v1.0 から | 甲と同じ。ただし iCloud の人だけ | 同じ | +5.0〜9.0日［推測］ | 0ドル［推測］ | 仮名の ID に結び付く。集計を Mac で回す。Apple が上限と料金を変えうる | 表示は「関連付けられたデータ」の見込み［推測］ |

### v1.0 から集め始める是非
- 良い所
  - 冷たい始まりを縮める手は、早く集め始めることしかありません。
  - Takuma の「本物まで出す」に、仕組みとしては v1.0 で応えられます。
- 悪い所
  - 出した日は0人で、v1.0 の利用者には見返りがほとんど見えません。同意する人が少なくなる見込みです［推測］。
  - 「データの収集なし」の表示と、「通信0件」の約束がなくなります。
  - サーバーの運用が、公開の日から始まります。
  - 1年目の見込みの人数（3,000〜50,000）では、出る夜は少数です（模型［推測］）。
  - いまの全体の見積もり（44.1〜64.8日）にさらに +5.0〜8.0日を足すことになり、要る速さが上がります。

---

## 実行したコマンドと結果
- `python3 -I R/scripts/appledoc2.py R/dl-apple '…' naturallanguage/nlcontextualembedding 'naturallanguage/nlembedding/sentenceembedding(for:)' 'naturallanguage/nlembedding/wordembedding(for:)' createml/mlrecommender coreml/mlupdatetask cloudkit/ckrecord/creatoruserrecordid`
  - 出力：nlcontextualembedding は iOS 17.0。mlrecommender は「macOS 10.15」だけ。mlupdatetask は iOS 13.0。
- `python3 -I R/scripts/appledoc2.py … network/proxyconfiguration network/proxyconfiguration/relayhop identitylookup/getting-up-to-date-calling-and-blocking-information-for-your-app adattributionkit/receiving-ad-attributions-and-postbacks foundationmodels` → 原文は下の URL の節。
- `curl -sL … apple-developer-program-license-agreement/ -o R/dl-web/dpla.html` と Python で CloudKit の文を抜き出し → 原文は下。
- `sqlite3 … oai_sample.sqlite "select isbn,title,author,publisher,series,ndc from b" > R/out/oai895.tsv` → 895行。
- `sw_vers` → macOS 27.0.1。`swiftc --version` → Apple Swift version 6.4。機械は Apple M2 Pro、メモリ 16 GB。
- `xcrun swiftc -O -swift-version 5 spike/emb.swift -o bin/emb` → エラー0、警告0。`time bin/emb out/oai895.tsv out/novels32.tsv`（R/out/emb_run1.log）の出力：
  ```
  NLEmbedding.sentenceEmbedding(ja) = false / wordEmbedding(ja) = false / sentenceEmbedding(en) = true / (zh-Hans) = false
  contextual ja: dim=512 maxSeq=256 rev=1 langs=["ja","ko","zh-Hans","zh-Hant"] hasAssets=true
  load 0.525s / embed 895x2: total 32.11s, title median 14.86ms max 88.2ms, rss 168.7MB
  P@5 same NDC-2: random 0.063 / rule 0.171 / char-bigram 0.173 / contextual(title) 0.248 / contextual(all) 0.279
  novels P@3 same genre: random 0.226, title 0.427, title+author 0.458
  final rss 169.6MB / 36.130 total
  ```
- iOS 27 のシミュレーター
  - `xcrun --sdk iphonesimulator swiftc -target arm64-apple-ios26.0-simulator spike/emb.swift -o bin/emb_sim`
  - `xcrun simctl create rec-tech-tl-spike "iPhone 17" com.apple.CoreSimulator.SimRuntime.iOS-27-0` → EA8F85BB-3EE1-4EB1-91AB-E875D253EC07
  - boot して `simctl spawn`（R/out/emb_sim_run1.log）の出力：
    ```
    NLEmbedding.sentenceEmbedding(en) = false … contextual ja … hasAssets=false
    requestAssets error … Code=8 "Failed to locate embedding model" / 3:42.48 total
    ```
  - そのあと shutdown と delete をし、`simctl list devices | grep -c rec-tech-tl-spike` → 0。
- `time python3 -I scripts/coldstart.py`（R/out/coldstart_run1.log）→ 1 の表の数字。全体で 26.9秒。
- MLRecommender
  - `xcrun swiftc -O -swift-version 5 spike/mlrec.swift -o bin/mlrec` → エラー0。非推奨の警告2種。
  - 3回動かした出力（R/out/mlrec_run2.log）の例：
    ```
    [many] users=2000 rows=24000 train 0.33s / recs for u0: 5件とも同じ群 / mlmodel bytes 1767170
    inputs ["exclude","items","k","restrict"] outputs ["recommendations","scores"] / on-device predict 0.10ms
    on-device recs for a new group-0 reader: 5 items, in group 0: 5
    [one] users=1 rows=12 → recs 0 rows / mlmodel bytes 2510
    ```

## 開いた URL と原文
- https://developer.apple.com/icloud/cloudkit/designing/ ：「CloudKit uses role-based access control (RBAC) to manage privileges and control access to data in public databases」「Roles include World, Authenticated, and Creator.」「The Creator role includes only the authenticated user who has created a record.」
- https://developer.apple.com/icloud/cloudkit/ ：「get up to 1PB of storage for your app's public data」。料金の記載はない。
- https://developer.apple.com/documentation/cloudkit/ckrecord/creatoruserrecordid （JSON）：「The ID of the user who creates the record.」「Every user of the app has a unique user record that is empty by default.」
- https://mjtsai.com/blog/2026/06/05/permissions-in-the-cloudkit-public-database/ ：「You can definitely have data in the public database that's only readable by the user who created it.」（Sternemann。Apple の答えではない）
- https://developer.apple.com/support/terms/apple-developer-program-license-agreement/ （2.8 と CloudKit の節）：「Apple reserves the right to charge fees for Your use of the Apple Services.」「there may be storage capacity, transmission, and/or transactional limits」「permitted to use the CloudKit APIs for storing, retrieving, and querying of structured data that You choose to store in public or private containers」「must take reasonable and appropriate steps to protect information You store through the iCloud service」、3.2：「access, collect, or transmit user data beyond what was disclosed when consent was requested」
- https://developer.apple.com/documentation/network/proxyconfiguration ：「A proxy configuration for Relays, Oblivious HTTP, HTTP CONNECT, or SOCKSv5.」（iOS 17.0）
- https://developer.apple.com/documentation/identitylookup/getting-up-to-date-calling-and-blocking-information-for-your-app ：「The Live Caller ID Lookup app extension requires you to use Apple relay servers to support making calls to your server endpoints.」
- https://developer.apple.com/forums/thread/817921 ：「Applied via the form in September 2025.」「The setup works perfectly in TestFlight, but the release version of the app is consistently being rejected by the Apple OHTTP Relay」。Apple の答えはない。
- https://developers.cloudflare.com/privacy-gateway/ ：「Enterprise-only」「Cloudflare OHTTP Relay is currently in closed beta – available to select privacy-oriented companies and partners.」
- https://developer.apple.com/documentation/adattributionkit/receiving-ad-attributions-and-postbacks ：「subject to their Crowd Anonymity tier」（広告の計測だけ）
- https://developers.cloudflare.com/workers/platform/pricing/ ：Workers の無料の枠は「100,000 per day」。有料の枠は「a minimum charge of $5 USD per month」「10 million included per month」。D1 の無料の枠は「100,000 / day」（書き込み）、「5 GB (total)」。R2 の外への転送は「Free」。
- https://developer.apple.com/app-store/app-privacy-details/ ：「"Collect" refers to transmitting data off the device in a way that allows you and/or your third-party partners to access it for a period longer than what is necessary to service the transmitted request in real time.」「Stripping data of any direct identifiers, such as user ID or name, before collection.」「You must not attempt to link the data back to the user's identity.」「Data that is processed only on device is not "collected"」
- https://developer.apple.com/app-store/review/guidelines/ ：5.1.1(ii)「Apps that collect user or usage data must secure user consent for the collection, even if such data is considered to be anonymous at the time of or immediately following collection. Paid functionality must not be dependent on or require a user to grant access to this data. Apps must also provide the customer with an easily accessible and understandable way to withdraw consent.」、5.1.1(iii)「should only collect and use data that is required to accomplish the relevant task」、5.1.1(i)「describe how a user can revoke consent and/or request deletion of the user's data」
- https://www.soumu.go.jp/main_sosiki/joho_tsusin/d_syohi/gaibusoushin_kiritsu.html ：対象に「アプリケーション提供者」を含む。自社が送信先のとき不要なのは「サービス提供に当たって必要な情報」と「First Party Cookieに保存されたID」。対応は「通知・公表、同意取得、オプトアウト」のどれか。ページの本文が文字化けしていて、取得の道具が文脈から戻した部分を含むので、原文の確かめは未了。
- https://alaginrc.nict.go.jp/rakuten-dataset.html （検索の要約）：「民間企業等の方は、申し訳ありませんがご利用いただけません。」
- https://kaken.nii.ac.jp/grant/KAKENHI-PROJECT-20H04478 （検索の結果）：公共図書館の貸出データは研究で使われているが、公開のダウンロードではない。
- Apple のドキュメント（JSON）：NLContextualEmbedding（「Call [requestAssets] before computing the embedding to confirm assets are available.」）、MLRecommender（「Use an [MLRecommender] to train a machine learning model that you include in your app to make recommendations for the user, while keeping their data on-device.」「find similarity patterns by looking at items that occur in groups」）、MLUpdateTask。

## Takuma に決めてほしいこと
1. **本物の「これを読んだ人は」のために、v1.0 から集め始めるか**
   - 推奨：甲。v1.0 で、同意した人から文学の組だけを、自前の最小のサーバーに送ります。出すのは、表が人数に届いた本だけです。届かない本は、規則と同梱データの推薦に戻ります。
   - いちばん強い反論：出した日は0人で、模型では送る人が1万人でも3冊以上出るのは25%の夜です。それなのに、v1.0 の「データの収集なし」と通信0件の約束を手放し、+5.0〜8.0日とサーバーの運用を背負います。乙（v1.1 から）なら v1.0 の約束と日程を守れますが、本物が出る時期は数か月遅れます。
   - 元に戻せるか：一部だけです。送るのを止めることはできます。ただ、一度「収集あり」で出した事実と、集めた数は残ります。数は名前のないものなので、消すならサーバーの表を消します（データの削除は Takuma だけが行う操作です）。
   - 見てほしい所：この報告の 1 の冷たい始まりの表と、3 の案の表。
2. **集める場所**
   - 推奨：(b) 自前の最小のサーバー（Cloudflare Workers と D1。ID を持たず、組の数だけを残す）。
   - いちばん強い反論：CloudKit なら、自前の受け口がなく、Apple が守ってくれます。ただ、仮名の ID に結び付き、iCloud のない人は送れず、集計は結局 Mac で回します。
   - 元に戻せるか：はい。公開の前なら替えられます。公開のあとは、古い版が送り続ける受け口を残す必要があります。
3. **機械学習の範囲（v1.0）**
   - 推奨：v1.0 は、規則、同梱データ、内容の近さ（ML なし）、端末での好みの重み付けまでにします。NLContextualEmbedding は、Takuma の iPhone で模型の取得、速さ、メモリを確かめてから v1.x で足します。
   - いちばん強い反論：「機械学習の方向」を v1.0 で見せられません。ただ、spike では小説での効き目が控えめで、シミュレーターでは動きませんでした。
   - 元に戻せるか：はい。
4. **集める本の範囲**
   - 推奨：NDC 9（文学）の組だけにします。扱いに気をつける分野を外へ出さないためです。
   - いちばん強い反論：新書、実用書、漫画の「これを読んだ人は」は出ません。
   - 元に戻せるか：はい。

決まったら要るもの：
- PRD の 12、15、16、17 と product.md の約束の直し（pdm）
- 同意の画面と、表の出し方（designer）
- 新しい ADR（サーバーを入れること、集める形、しきい値）、契約（受け口1つ。Idempotency-Key）、脅威モデル（tech-lead）
- app.json の stacks と backend/ の使い始め（Takuma）

## 未解決
1. NLContextualEmbedding の実機での動き（模型を落とす大きさと時間、1件の速さ、メモリ、Mac と同じ revision か）。シミュレーターでは動かないので、Takuma の iPhone で確かめる必要があります。
2. 外部送信規律で、自社サーバーへ送る推薦のための組が「必要な情報」に当たるか。総務省のページが文字化けしていて、原文の確かめは未了です。法律の判断は Takuma を通します。
3. CloudKit の公開 DB の無料の枠と上限。公式の数字は見つかりませんでした。
4. 「出す前から集める」形が 5.1.1(iii) の審査で通るか［推測］。
5. 単行本と文庫を作品の単位にまとめる方法と精度。同梱データに作品の ID がありません。
6. App Attest で偽の送信を減らすことと、端末ごとの記録を持たない匿名さを、どう両立させるか（設計が要ります）。
7. 冷たい始まりの模型の仮定（人気の偏り s、1人が1年に読み終える冊数、同意する人の割合）。どれも確かめていません。公開のあとの実際の数で見直します。
8. FoundationModels に埋め込みの API があるか（文書の冒頭しか見ていません）。
9. 毎月の表を asset pack で出すときの、審査の日数。
10. 試作のファイル：R/spike/emb.swift、R/spike/mlrec.swift、R/scripts/coldstart.py、R/scripts/appledoc2.py、R/out/（oai895.tsv、novels32.tsv、emb_run1.log、emb_sim_run1.log、coldstart_run1.log、mlrec_run1.log、mlrec_run2.log、rec_many.mlmodel、rec_one.mlmodel）、R/dl-apple/、R/dl-web/dpla.html。リポジトリには入れていません。シミュレーターの端末は消しました。

## 記録（指揮役が保存するときに書き足す）
- 種類：調べものと spike（tech-lead）
- 日付：2026-10-21
- spike の産物はリポジトリの外（scratchpad の rec-tech/）。シミュレーターの端末は役が消した
