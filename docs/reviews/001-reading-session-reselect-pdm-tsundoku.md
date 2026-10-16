（指揮役の注）これは判定ではなく、課題の選び直しのための調べもの（pdm）の報告。担当は課題2「積読が増えていく／次の1冊が選べない」。報告の文はそのまま保存した。

# 課題2「積読が増えていく／次の1冊が選べない」の需要と競合（pdm の調べもの）

- 調べた日：2026-10-16（JST）。評価の数はこの日の App Store の値で、検索 API と lookup API から取りました。
- 根拠の印は［公開情報 URL］と［推測］です。「検索の要約」と書いたものは WebSearch の要約で読んだだけで、元のページは開いていません。
- リポジトリのファイルは書いていませんし、直してもいません。ツールは36回使いました。

## 0. 結論
- **積読があること自体は、多くの人に通じます。** 丸善・ジュンク堂で本を買った人の79%に積読があり、66%が6冊以上、23%が31冊以上と答えています［公開情報 https://prtimes.jp/main/html/rd/p/000000012.000027516.html 2019-07-16、N=2,104］。tsundoku は BBC が記事にし、Cambridge Dictionary にも載っています（1-5）。
- **ただし、「選べないから読まない」という証拠は弱いです。**
  - 同じ調査で、積読の理由の上位は「他に優先して読む本が増えた」と「本を読む時間がない」でした。
  - 36%は、はじめから積読にするつもりで買っています。
  - 調べた会社自身が「必ずしも積読を解消したい訳ではない」と書いています［公開情報 同 PR TIMES］。
- **「積読から1冊を選ぶ」アプリは日米にいくつもありますが、どれも伸びていません。**
  - 評価の数は、Readpick 0、次、何読む？ 0、読みくじ 0（2024年公開）、Bookpather 0、TBR Book Jar 3 です。
  - 大きいアプリは、この機能を一部として持っています。Fable には「Ask Scout to randomly select your next read from your TBR」が、私は積読家には「AI選書」があります（2）。
- **伸びているのは、積読を肯定して眺める形です。** 私は積読家は 2026-02 の公開で評価149件です。説明文は「積読は、減らさなくていい。」で、積読タワーがあります［公開情報 https://apps.apple.com/jp/app/id6758698105］。
- **指揮役の仮説「カメラを向けると今夜の1冊が光る」は、まったく同じ形を見た範囲では見つけていません。ただし、使う部品はどれもすでにあります（3）。**
  - 写真を撮るアプリのうち評価がいちばん多い Shelf Scanner. は、低評価の多くが「本が見つからない」という不満です。
- **推奨：形を変える。**
  - 「カメラで光る瞬間」を中心にした独立のアプリにはしません。
  - 2 は、共通の芯「読みたいのに、たどり着けない」の入口の一つに下げます［推測］。
  - その前に、Takuma の積読で5分の確かめ（5 の T1）をします。

## 1. 日本の需要
### 1-1 積読がある人の割合と冊数
- **丸善ジュンク堂書店「読書環境に関するアンケート調査」**（2019-06-15〜23、40店舗、レシートの QR から答えた購入者 N=2,104）［公開情報 https://prtimes.jp/main/html/rd/p/000000012.000027516.html を curl で開いた］
  - 積読がある 79%、6冊以上 66%、31冊以上 23%。
  - 理由は「他に優先して読む本が増えた」が最多で、「本を読む時間がない」が続く。積読にするつもりで買った人が合わせて36%。
  - その他の答えに「その日の気分によって読みたい本が変わる」「その本を読む気分を待っている」がある。
  - 1か月に読む冊数は「2〜3冊」が41%。答えたのは、よく読む人に偏っている。
  - 読書の時間を増やしたい人は70%。
- **2020年以降の全国の積読調査は見つかりませんでした**（2回検索）。マナカレの調査（「積読を減らすためにしていること」の1位が「見えるところに置く」）は検索の要約で見ただけです［https://codezine.jp/news/detail/25795］。
- **全体では、本を読む人自体が少ないです。**
  - 20〜69歳の51.6%が、半年に1冊も読んでいません［公開情報 https://www.cross-m.co.jp/news/release/20251008 、2025-10、N=1,100。WebFetch で開いた］。
  - 16歳以上の62.6%が、1か月に1冊も読みません［公開情報 docs/prd/product.md の 1、文化庁］。
  - このため、積読は「本を買う人」の困りごとです。課題1の「働いていると読めない」より対象は狭いと考えます［推測］。

### 1-2 「次に読む本が決められない」の声
- **日本の利用者の声は、調査の自由回答にしかありませんでした。** 上の「その日の気分によって読みたい本が変わる」「その本を読む気分を待っている」です［公開情報 PR TIMES］。
- **アプリの説明文にはあります。** ただし売り手の言葉で、利用者の声ではありません。
  - 読みくじ「「次に読む本が決まらない」そんな日は」［公開情報 https://apps.apple.com/jp/app/id6476876922］
  - Readpick「本はもう持っている。どれを読むかが決まらないだけ。」［公開情報 https://apps.apple.com/jp/app/id6797449879］
- **日本の読書アプリ5本の最近のレビュー516件に、「積読から選べない」という不満はありませんでした。** 読んだのはブクログ150、読書メーター150、ビブリア150、ネコノホンシツジ31、私は積読家35件です［公開情報 RSS］。
  - 出てきたのは、ビブリアの「積読本と、買いたい本、が仕分け出来るとありがたいです」（2026-10-12 ★5）のような、整理についての要望です。
  - キーワードで拾ったので、取りこぼしはありえます［推測］。
- **海外では、TBR（読みたい本の山）の扱いについて声があります。**
  - Goodreads「wish there was an easier way to reorder/organize your TBR … in the order I plan on reading」（2026-10-12 ★3）［公開情報 https://itunes.apple.com/us/rss/customerreviews/page=1/id=355833469/sortby=mostrecent/json］
  - StoryGraph「my already-unmanageable TBR」（2026-08-16 ★5）［公開情報 https://itunes.apple.com/us/rss/customerreviews/page=1/id=1570489264/sortby=mostrecent/json］
  - Goodreads のグループに「How do you pick your next book?」という話題があり、気分で選ぶ、ルーレットを回す、目を閉じて選ぶ、などの答えがあります。紙に書いて瓶から引く「TBR jar」もあります。どちらも検索の要約で見ただけです［https://www.goodreads.com/topic/show/22805201 、https://www.lemon8-app.com/@yamithereader/7516703673834013197］。

### 1-3 積読を扱った本と話題
- **永田希『積読こそが完全な読書術である』**（イースト・プレス、2020-04）。積読を肯定する本です。検索の要約で見ただけです［https://realsound.jp/book/2020/04/post-540914_2.html］。
- **石井千湖『積ん読の本』**は、メモのページの題として出てきただけで、出版社と年は確かめていません。
- **SNS の話題：** 私は積読家のレビューに「Xで拝見して」「このアプリの名物「積読タワー」に衝撃を受けインストール」（どちらも 2026-10-08 ★5）があります［公開情報 https://itunes.apple.com/jp/rss/customerreviews/page=1/id=6758698105/sortby=mostrecent/json］。X の投稿の数は調べられていません（見ていない）。
- **作る側も積読に注目しています。** 2025-12〜2026-09 の約10か月で、名前に積読を含むアプリが日本で9本出ました。評価が100件を超えたのは私は積読家（149）だけで、残りの8本は合わせて31件です（tsumu 2、おうち本棚 5、積読生活 0、ツンドク 18、つんドク 0、積ん読ボード 0、Book Memo 1、ツミアゲ 5）［公開情報 検索 API］。

### 1-4 紙の本の買われ方
- 2025年の紙の書籍の推定販売金額は5,939億円で、前年と同じ水準（2億円増、4年ぶりのプラス）でした。紙の出版物全体は9,647億円で、1975年以来はじめて1兆円を下回りました［公開情報 https://www.fashionsnap.com/article/2026-01-27/print-publications-market/ 、出版科学研究所の発表］。
- 本の手に入れ方の1位は「新品の紙の本を買う」46.6%、2位は図書館35.0%です［公開情報 cross-m 2025］。
- 「1人が年に何冊買うか」の全国データは見つかりませんでした（未確認）。

### 1-5 tsundoku が海外で知られていること（出典を開いて確かめた）
- **BBC News**「Tsundoku: The art of buying books and never reading them」2018-07-29［公開情報 https://www.bbc.com/news/world-44981013 、curl で 200］。
  - 「it can be found in print as early as 1879」、「the "tsun" in "tsundoku" originates in "tsumu" - a word meaning "to pile up"」、「the word does not carry any stigma in Japan」。
  - 指揮役が見た worklife の URL と world-asia-44981013 は、どちらも 404 でした。筆者が Tom Gerken であることは Wikipedia の検索の要約で見ただけです。
- **Cambridge Dictionary** の項目は実在します（名詞）。定義は「the practice of buying a lot of books and keeping them in a pile because you intend to read them but have not done so yet; also used to refer to the pile itself」です［公開情報 https://dictionary.cambridge.org/dictionary/english/tsundoku 、curl で 200］。

### 1-6 Job と4つの力（仮説）
- **Job：** 積んである本が何冊もあって夜に少し時間ができたとき、迷わずに1冊を手に取りたい。そうすれば、選ぶのに疲れてスマホに戻ることなく、読み始められる［推測。「選べないからスマホに戻る」の証拠はない］。
- **押し：** 積読の山の重さ（積読ありが79%）［公開情報］。
- **引き：** 1冊だけ決まる気楽さ［推測］。
- **不安：** 選ばれた本が気分に合わない。写真を撮られることへの不安［推測］。
- **習慣：** 気分で手に取る。山を眺めること自体が楽しい［公開情報 PR TIMES、私は積読家の評価］。

## 2. 競合（低評価のレビューは RSS の mostrecent、1〜3ページで読んだ）
### 2-1 日本（JP の評価）
| 名前 | URL | 評価 | 価格 | 積読と次の1冊の扱い | 不満（引用、日付、星） |
|---|---|---|---|---|---|
| 私は積読家 | https://apps.apple.com/jp/app/id6758698105 | 149（4.7）。2026-02-16 公開 | 無料。PRO 買い切り¥480 | 副題「積読が楽しくなる蔵書管理・読書管理アプリ」。積読タワー（本の厚みから高さを出す）。**AI選書「積んだ本の中から、テーマに合わせて「今読むべき一冊」を提案」（無料は週2回）**。バーコードで一度に最大30冊。SNS 用の画像。背表紙を写す機能はない（WebFetch で確かめた） | 「毎日毎日毎日アップデートの通知が鬱陶しいです」（10-12 ★1）、「なぜ毎日アップデートするの？」（10-07 ★1） |
| Readpick | https://apps.apple.com/jp/app/id6797449879 | 0。2026-08-18 公開 | 無料は1日1回。Pro 月¥500・年¥2,500。iOS 26 以上 | 「積んである本の中から、いま読むべき1冊を名指しします」「候補は出しません」「選ぶ処理は、iPhoneの中のAIが行います」。副題「積んだ1冊を、いま決める。」。カメラはない（WebFetch で確かめた） | レビューなし |
| Bookpather | https://apps.apple.com/jp/app/id6790094219 | 0。2026-07-18 公開 | 無料と Pro（価格は見ていない） | 「本棚をスキャンして次に読む本を決め、読書時間を計り」。本棚まるごとスキャン、自分の棚から読む順番を出す「読書ルート」、タイマー。AI には同意したときだけ本の情報を送る | レビューなし |
| ブックカタログ：棚スキャナー | https://apps.apple.com/jp/app/id6801512523 | 0。2026-08-18 公開 | 無料（課金は見ていない） | 「デバイス上で背表紙を認識」「一度に最大40冊」。画面は日本語あり。日本語の背表紙を読めるかは書かれていない | レビューなし |
| ブクログ | https://apps.apple.com/jp/app/id359066582 | 28,252（4.54） | 無料。プレミアムは月額 | 積読を状態として持つ。おすすめは新しい本 | 「数年間オススメの本が何読んでも変わらない」（08-29 ★1）、「バーコードで本登録できんくなった」（05-19 ★1）、「表紙が出なくなってしまった」（07-08 ★2） |
| 読書メーター | https://apps.apple.com/jp/app/id509979590 | 7,187（4.47） | 無料 | 「読んだ本、読みたい本、積読本など、本をステータス別に登録」 | 「バーコード読み取りが機能しない」（10-10 ★1）、「以前の読書記録が全て消えてしまっていた」（09-19 ★1）、「一字一句間違えのないタイトルを入力しても、掠りもしない」（08-16 ★2） |
| ビブリア | https://apps.apple.com/jp/app/id894377244 | 11,927（4.57） | 無料（広告と有料プランが始まった） | バーコードで登録する | 「遂に広告や有料プランのご案内が始まり残念」（07-01 ★1）、「記録が全て消えて復元も出来なかった」（09-04 ★2）、「エラーになり本の登録ができません」（07-11 ★1） |
| ネコノホンシツジ | https://apps.apple.com/jp/app/id6752113848 | 275（US 42） | 無料（広告あり） | 名前に「積読・本棚管理」。「猫がおすすめしてくれます」。一文をカメラで読み取る | 「読書終了時に広告が強制で出るようになり使いづらい」（09-08 ★2） |
| そのほか（選ぶ、棚を写す） | 次、何読む？ id6796737085、読みくじ id6476876922、Buy Best Book id6747279391、Libra〜AI本棚スキャナー〜 id6763660264 | 0、0、3、1 | 無料 | 積読から次の1冊を出す。くじで選ぶ。選書 AI。棚を写す | レビューは見ていない（件数が少ない） |

- 本コレ（評価141,676件）は書店のクーポンと新刊情報のアプリで、積読の機能はありません［公開情報 lookup の説明文］。
- 2件以上のアプリに出る不満：
  - 本の登録の失敗（バーコード、検索）：ブクログ、読書メーター、ビブリア
  - 記録が消える：読書メーター、ビブリア
  - 広告と課金：ビブリア、ネコノホンシツジ

### 2-2 海外（US の評価）
| 名前 | URL | 評価 | 価格 | 積読と次の1冊の扱い | 不満（引用、日付、星） |
|---|---|---|---|---|---|
| Goodreads | https://apps.apple.com/us/app/id355833469 | 758,376（JP 1,450） | 無料 | Want to Read の棚。表紙を写して本を加える | 上の TBR の並べ替え（10-12 ★3）、「No dark mode」（10-10 ★1） |
| StoryGraph | https://apps.apple.com/us/app/id1570489264 | 3,590（JP 10） | 無料と有料 | 「filters to choose your next perfect book」。おすすめを機械学習で出す | 「Can't scan my books」（10-11 ★2）、「You can't import any of your Goodreads books」（08-14 ★1）、「Extremely Buggy」（09-06 ★2） |
| Fable | https://apps.apple.com/us/app/id1488170618 | 81,844 | 無料 | **「Ask Scout to randomly select your next read from your TBR」** | 見ていない（RSS を読んでいない） |
| TBR - Bookshelf | https://apps.apple.com/us/app/id1614891654 | 4,405 | 無料と Pro | TBR を棚として見せる | 「The BOOKSHELF is behind the paywall」（10-13 ★1）、「you can't even have your TBR displayed as a shelf without paying」（09-14 ★1） |
| Shelf Scanner. | https://apps.apple.com/us/app/id6503261472 | 260 | 無料と年額 | 棚の写真から本ごとの売値を出す（転売向け） | 「Shelf scan doesn't work at all / Shows no books can be identified」（2025-06-03 ★1）、「I scanned shelves and it said it found no books」（2025-03-10 ★2）、「It couldn't find any books on my shelves」（2025-03-02 ★1）、「I tried taking photos of books on the shelf … Nothing worked」（2025-03-25 ★1） |
| Shelf Scan: Book Spine Scanner | https://apps.apple.com/us/app/id6754824642 | 2 | 無料 | **「Can't decide which book to read next?」「Books on your reading list are automatically highlighted with a special badge」**（写真の上で印を付ける） | 見ていない |
| Bookshelf Scanner: Spines | https://apps.apple.com/us/app/id6757425414 | 2 | 無料 | 古本屋の棚を撮ると「identifies the books in seconds and highlights the ones worth…」 | 見ていない |
| FlipLit / Better Bookshelf / Mibrary | id6755661340、id6791765002、id6758561299 | 5、5、179 | 無料と有料 | カメラを動かすとその場で何冊も見分ける（転売向け）。1枚の写真で本と位置を残す（棚まるごとは有料）。背表紙を並べた棚を作る | Mibrary は「has a spine display for your shelf that I've never seen on any book tracking app!」（2026-04-02 ★5）と好評。FlipLit と Better Bookshelf は見ていない |
| Siftivo / Shelf: Your Next Read / TBR Book Jar | id6805487396、id6775563720、id6761447804 | 3、2、3 | 無料 | 次の1冊を選ぶ。デジタルの TBR jar | 見ていない |

- 2件以上のアプリに出る不満：
  - 認識とスキャンの失敗：Shelf Scanner.（棚の写真の失敗だけで4件）、StoryGraph、Bookshelf Scanner（「Camera setting to scan isbn numbers is never working」2025-12-12 ★2）
  - 課金の壁：TBR - Bookshelf の2件、Bookshelf Scanner（「Only allows 10 books on Free version」）

### 2-3 アプリ以外の代替
- **積読の山を見て、気分で手に取る：** 0円で、時間もほとんどかかりません［推測］。調査の自由回答に「その日の気分によって読みたい本が変わる」があります［公開情報 PR TIMES］。
- **紙の TBR jar（題名を書いた紙を瓶から引く）：** 検索の要約で見ただけです［Lemon8 の上の URL］。
- **ChatGPT などに棚の写真を渡して選ばせる：** 記者が試した記事があります。検索の要約で見ただけです［https://techradar.com/ai-platforms-assistants/i-gave-chatgpt-my-entire-bookshelf-and-it-became-the-worlds-most-personalized-librarian］。
- **LoveReading Shelfie Decoder（Web、無料）：** 開いて確かめました。「Snap your bookshelf. Our AI reads the spines … plus the three books you should read next.」「the image is analysed in the moment and discarded.」。エラーの画面には「We couldn't read that shelf」とあります［公開情報 https://tools.lovereading.co.uk/shelfie］。出す3冊が棚の中の本か新しい本かは、確かめていません。

## 3. 独自性
- **近い先行**（どれも［公開情報 2 の URL］）
  - 写真の上で本に印を付ける：Shelf Scan（読みたい本のリストにある本に印）、Spines、LoveReading（次の3冊）
  - 端末の中で背表紙を見分ける：ブックカタログ（最大40冊）
  - 本棚をスキャンし、自分の棚から次の1冊を決めて、タイマーで測る：Bookpather
  - 端末の AI が積読から1冊を名指しする：Readpick（カメラなし）
  - 積読の中から AI が「今読むべき一冊」を出す：私は積読家（カメラなし）
  - カメラを動かすとその場で何冊も見分ける：FlipLit
- **見つからなかったもの：** 次の形を一度に満たすアプリは、見た範囲にはありませんでした。
  - 止めた写真ではなく、カメラの映像の上で光る
  - 自分の積読が対象
  - 光るのは今夜の1冊だけ
  - 処理は端末の中だけ
  - 伏せると読み始める
  - 見た範囲は、検索 API（JP と US、19語、各8〜15件）と Web 検索3回です。Google Play、X、YouTube のデモは見ていません。
- **新しいのは「組み合わせ」だけです。** 部品はどれもあるので、まねされやすいです［推測］。
  - 海外の棚を写すアプリはすべて英語です。日本語の縦書きの背表紙を読めることが違いになりうるが、読めるかどうかは確かめていません（tech-lead に要確認）。
  - 「AI は端末の中」は、LoveReading（サーバーで処理）や Bookpather（同意を得て送る）とは違います。Readpick とブックカタログとは同じです。
- **代替より何がどれだけよいかを数字で言えるのは、本の登録だけです。** ブックカタログは「500冊のライブラリは約13枚の棚の写真です」と書いています（売り手の主張）［公開情報］。毎晩の1冊を選ぶ場面では、積読の山を見て手に取るより速いと言える数字はありません［推測］。

## 4. 物差しごとの評価（1〜5点）
| 物差し | 点 | 理由 |
|---|---|---|
| 共感の広さ | 3 | 積読は広く通じる言葉で、79%に積読がある。英語の辞書にもあり、積読のアプリも10か月で9本出た［公開情報 1-1、1-3、1-5］。ただし対象は本を買う人に限られる。大人の半数は半年に1冊も読まない［公開情報 cross-m］。「選べない」に共感する人は、さらに少ない（下の確かさ） |
| ポートフォリオ映え | 4 | 積読の山にカメラを向けて1冊だけが光る絵は、10秒で伝わる［推測］。tsundoku は英語でも説明できる。ADA には物を撮る CapWords（2025年の受賞）や、端末の中の AI の受賞がある［docs/reviews/001-reading-session-angles-designer.md の T-7］。ただし、棚が光る絵は Shelf Scan、Spines、LoveReading がすでに出している。日本語の背表紙が動画の中で正しく光らなければ成り立たない（Shelf Scanner. の不満） |
| 困りごとの確かさ | 2 | 積読の多さは確か。しかし理由の上位は「優先する本が増えた」と「時間がない」で、「解消したい訳ではない」と調査に書かれている［公開情報 PR TIMES］。日本のレビュー516件に「選べない」の不満はない。選ぶアプリは評価0〜3件で伸びていない［公開情報 2］ |
| 独自性 | 2 | 部品はすべてある（3）。違いは組み合わせと、まだ確かめていない日本語の背表紙だけ |
| お金の筋 | 2 | 相場は私は積読家の買い切り¥480、Readpick の月¥500。Fable の無作為の選択は無料［公開情報 2］。選ぶアプリに払う人がいる証拠はない。棚を写すアプリでお金になっているのは、転売で売値を見る用途（Shelf Scanner.、FlipLit）［公開情報］ |
| 最初の発想との近さ | 3 | 美しくなるのは「読む時間」ではなく「読む前の一瞬」。伏せて読み始める所までつなげると Job が2つ（選ぶ、読む時間）になり、機能を分けることになる。積読を登録する作りは、product.md の 1 で「対象にしない層」とした本の管理（ブクログの土俵）に近づく［公開情報 docs/prd/product.md］ |
| 参考：デザイン賞の筋 | 3 | 物を撮る、端末の中の AI、控えめ、という ADA の型に合う。ただし 2023〜2026年に、読書のアプリは受賞も最終候補もない［designer の調べもの］。毎晩カメラを開く手順が増えると、Forest に出たような「手順が増えた」という不満を受ける［公開情報 product.md の 4］ |
| 参考：作れるか | 判定は tech-lead | 公開情報で言えるのは2つだけ。ブックカタログは「デバイス上で背表紙を認識」と書いている。Readpick は端末の中の AI を使い、iOS 26 以上が必要 |

- 主な6つの合計は16点（30点満点）です。

## 5. いちばん強い反論と、いちばん安い確かめ方
- **いちばん強い反論：** 積読は困りごとではなく楽しみで、選べないことは読まない理由ではありません。
  - 36%は積読にするつもりで買い、「解消したい訳ではない」と調査に書かれています。BBC も「日本では悪い意味がない」と伝えています。
  - 実際の市場でも、伸びているのは積読を肯定する形（私は積読家 149件）で、選ぶ形（Readpick、Bookpather、読みくじ）は0件です。
  - 毎晩カメラを開くことは、山を見て手に取るより手順が1つ多くなります［推測］。
- **作らない場合に起きること：** 利用者は今のまま、気分で手に取るか、私は積読家の AI選書や Fable を使います。困る人は少ないと考えます［推測］。ポートフォリオの題材は 1 か 4 から選ぶことになります。
- **T1（Takuma、5〜10分、今夜できる）**
  - やること：
    1. 自分の積読（10冊以上）を部屋の明かりで撮る。
    2. 写真アプリのテキスト認識表示で、題名が拾える冊数を数える。
    3. 同じ写真を ChatGPT か Claude に渡し、「写っている本の題名をすべて書き出し、今夜の1冊を1つ選んで、理由を1行で」と頼む。
    4. 選ばれた本を、その夜に読むかどうかを見る。
  - 合格の線：日本語の背表紙の題名が10冊中8冊以上正しく、かつ選ばれた本をその夜10分以上読んだ。
  - 認識が外れたら、カメラを中心にしません。読まなかったら、選ぶことは読まない理由ではないと判断します。
- **T2（Takuma の知人3人、過去の行動を聞く、1人10分）**
  - 問い：
    - 「この1か月で、読もうと思ったのに読まなかった夜は何回？ 代わりに何をした？」
    - 「最後に積読から1冊を選んで読み始めたのはいつ？ どう選び、何分かかった？」
    - 「この1か月で、どれを読むか決められずにやめたことは何回？」
  - 合格の線：3人中2人以上が「決められずにやめた」を1回以上と答え、その理由が時間や疲れではない。
  - この答えは、課題1と4の判断にも使えます。
- **T3（任意、1週間、0円）**
  - やること：私は積読家の AI選書（無料で週2回）を3回使う。
  - 合格の線：3回中2回以上、選ばれた本をその夜10分以上読んだ。
  - 合格なら、価値はあるが先行も同じことを提供している、ということです。違いはカメラと美しさで出す必要があります。

## 変更したファイル
- リポジトリ：なし。
- scratchpad だけに書きました（リポジトリの外です）。
  - 使い捨ての読み取りスクリプト：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/scripts/lk.py、/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/scripts/rss.py、/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/scripts/ext.py
  - 取ってきたページ：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ の cam.html、bbc.html、bbc2.html、bbc3.html、prt.html、fs.html

## 実行したコマンドと結果
すべて 2026-10-16 に実行しました。

- **見たファイル（読むだけ）**：.claude/org/app.json、docs/approvals/001-reading-session-G0-Q8.md、docs/prd/product.md、docs/reviews/001-reading-session-angles-pdm-open.md、docs/reviews/001-reading-session-angles-designer.md。読み方は `cat`、`sed -n`、`grep -n`。
- **競合を集める：** `curl -s --get https://itunes.apple.com/search --data-urlencode 'term=<語>' -d entity=software -d country=<jp|us> -d limit=<8〜15>` を20回実行しました。
  - JP の語：積読、積ん読、本棚 スキャン、背表紙、次に読む本、読書管理、本棚 AI、積読 AI、本棚 カメラ、今日の一冊、本コレ
  - US の語：tsundoku、bookshelf scanner、book spine scanner、scan bookshelf、what to read next、TBR、bookshelf AI recommend、pick my next book、TBR picker
  - 結果の例：「積読」(jp) は14件。私は積読家 149、ブクログ 28,252、ネコノホンシツジ 275、ビブリア 11,927、ツンドク 18 など。「bookshelf scanner」(us) では Shelf Scanner. 260、Bookshelf Scanner 40、Bookshelf Scanner: Spines 2、FlipLit 5 など。
- **説明文と評価の数：** `python3 -I .../scratchpad/scripts/lk.py <ID,...> '<キーワード>'`（lookup API、JP と US）を2回実行し、26件の評価、価格、公開日、説明文の該当行を取りました。結果は 2 の表の値です。
  - 1回目は書き先に `$S` を使ったためガードに止められ、絶対パスで実行し直しました。
  - `curl -s 'https://itunes.apple.com/lookup?id=6797449879,6790094219,6801512523,391429128,6758698105&country=jp'` で説明文の全文を、`...lookup?id=1488170618&country=us` で Fable の「Ask Scout to randomly select your next read from your TBR」を確かめました。
- **レビュー：** `python3 -I .../scratchpad/scripts/rss.py` で、`https://itunes.apple.com/<jp|us>/rss/customerreviews/page=<1-3>/id=<ID>/sortby=mostrecent/json` を12本について読みました。
  - 読んだ数：私は積読家 35、ネコノホンシツジ 31、ブクログ 150、読書メーター 150、ビブリア 150、StoryGraph 150、Goodreads 150、TBR Bookshelf 150、Mibrary 16、Shelf Scanner. 13、Bookshelf Scanner 4、ネコノホンシツジ（US）7。
- **curl で開いたページ**
  - `https://dictionary.cambridge.org/dictionary/english/tsundoku`：HTTP 200。題は「TSUNDOKU | English meaning - Cambridge Dictionary」で、定義は 1-5 のとおり。
  - `https://www.bbc.com/worklife/article/20180727-tsundoku-the-art-of-buying-books-and-never-reading-them`：HTTP 404。
  - `https://www.bbc.com/news/world-asia-44981013`：HTTP 404。
  - `https://www.bbc.com/news/world-44981013`：HTTP 200。datePublished は 2018-07-29T00:14:13Z。引用は 1-5 のとおり。
  - `https://prtimes.jp/main/html/rd/p/000000012.000027516.html`：HTTP 200。datePublished は 2019-07-16 13:00:53。数字は 1-1 のとおり。
  - `https://tools.lovereading.co.uk/shelfie`：HTTP 200。引用は 2-3 のとおり。
  - `https://www.fashionsnap.com/article/2026-01-27/print-publications-market/`：HTTP 200。数字は 1-4 のとおり。
- **WebFetch**
  - 開けた：https://financial-field.com/living/entry-307105 （79%、66% の二次報道）、https://www.cross-m.co.jp/news/release/20251008 （積読の項目はない）、Readpick の製品ページ（iOS 26.0 以上、Pro ¥500 と ¥2,500、カメラなし）、私は積読家の製品ページ（PRO ¥480、AI選書、背表紙を写す機能なし）。
  - 断られた：bbc.com。
- **WebSearch（13回）：** 積読の調査の割合（3回）、ChatGPT と本棚、BBC tsundoku 2018、丸善ジュンク堂の調査、永田希の本、年間の購入冊数、出版科学研究所 2025、積読のどれから、TBR jar、積読タワーと X、次に読む本が決まらない、TBR の調査。要約で見ただけのものは、本文で「検索の要約」と書きました。
- **`git status --short`：** 出力なし（作業ツリーはきれい）。ブランチは feat/001-reading-session。

## 未解決
- **Takuma に聞きたいこと**
  - Q-a：2 を単独のアプリの中心にしますか。それとも、共通の芯「読みたいのに、たどり着けない」の入口の一つにしますか。推奨は入口の一つです。確かさが2点で、選ぶアプリが伸びていないためです。いちばん強い反論は、2 は Takuma が推した課題で、カメラの絵はいちばん映えることです。今は調べものの段階なので、どちらを選んでも元に戻せます。
  - Q-b：T1（自分の積読を撮る5分）と T2（3人に聞く）を、G0 の前にやってもらえますか。
  - Q-c：「積読を減らす」ではなく「積読を楽しむ」方向も候補に入れますか。私は積読家が先行していて、読む時間からは離れます。
- **tech-lead に確かめてほしいこと**
  - 日本語の縦書きの背表紙を、端末の中（Vision）で何割読めるか。文庫は背のデザインがそろっていて、帯もある。
  - カメラの映像の上で1冊だけを光らせる手間。
  - 選ぶ処理を Foundation Models で行うと iOS 26 以上になる（Readpick と同じ）。
  - 2週間で作れるか。
- **designer に確かめてほしいこと**
  - 10秒の動画として、Shelf Scan、Spines、LoveReading、私は積読家の積読タワーと見比べ、違いが見えるか。
  - 毎晩カメラを開く手順を増やさない形にできるか。
- **確かめきれなかったこと**
  - 1人が年に何冊買うかの全国データ。
  - 日本の利用者自身の「選べない」という声（売り手の文と調査の自由回答しかない）。
  - X での積読の話題の量。
  - Fable、Shelf Scan、Spines、FlipLit、Better Bookshelf のレビュー。
  - 石井千湖『積ん読の本』の出版情報。
  - LoveReading の「次の3冊」が棚の中の本かどうか。
  - BBC の筆者名（Wikipedia の検索の要約だけ）。
  - 2020年以降の全国の積読調査。

## 記録（指揮役が保存するときに書き足す）
- 種類：課題の選び直しのための調べもの（pdm、課題2）。PASS / FAIL なし
- BASE=9b91ec57d4819344440631429cf413e5effd3d4d
- 日付：2026-10-16
