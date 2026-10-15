FAIL

（指揮役の注）tech-lead の G0 判定は、1体目が手数の上限に達して報告を出さずに止まったため、範囲を2つに分けて2体の tech-lead に呼び直した。このファイルには2体の報告をそのまま並べる。全体の判定は、どちらか一方でも FAIL なら FAIL。
- その2：第1部の根拠と、G0 の前の確認 → FAIL
- その1：実現性、非機能、費用、プライバシー → FAIL（このファイルの後半）

# その2：第1部の根拠と、G0 の前の確認

FAIL

## 指摘
- 重大、docs/prd/001-reading-session.md:45（同じ件が :36 と docs/prd/product.md:31 にもある）
  - 何が問題か：ToRead との違いとして「後から分数を直せること」を挙げているが、事実と違う。ToRead の製品ページには「編集と手動入力ができるセッション履歴」「忘れた時の自動セッション終了」「ロック画面とDynamic Islandでの読書時間の表示(ToRead Plus)」「読書セッションを開始し、スマホを置いて、ただ読む」と書いてある。この文には印もない。3 の表の ToRead の強みの欄も、このうち2点（履歴の編集と手入力、ロック画面の表示）を落としている。この違いの文は、17（:374）の 4.3(b) への手当てと、8 の差の説明を支えている。確認項目2を満たさない。
  - 根拠：https://apps.apple.com/jp/app/toread-%E8%AA%AD%E6%9B%B8%E3%82%BF%E3%82%A4%E3%83%9E%E3%83%BC/id6757129946 （2026-10-15）
  - 直す方向：
    - ToRead の強みの欄に「履歴の編集と手入力」と「ロック画面と Dynamic Island（Plus）」を足す。
    - :45 は本当の違い（自動で終えない、押せるものが1つの読書中の画面）だけにして、印を付ける。
    - 8 の反論に「ToRead は無料で広告がなく、数え続け、履歴も直せる」を印つきで書く。そのうえで「作る」を推すかを書き直す。
- 重大、docs/prd/001-reading-session.md の AC-6（:191）、AC-7（:197）、AC-8（:203）、AC-17（:257）、AC-25（:305）。AC-15（:245）も境界にある。
  - 何が問題か：「効く機会」に「当たり前」と書いてある。ひな形（docs/templates/prd.md:93）が「当たり前」を許すのは、空、エラー、オフライン、権限の AC だけ。それ以外は O-n を書く決まり。これらの AC は直す、消す、やめる、日付をまたぐ、残り続けるで、どれにも当たらない。gates.md:32 の「全 AC に効く機会」と確認項目9を満たさない。pdm の [x] は誤り。
  - 直す方向：9 の表の対応を写せば済む。AC-6〜8 は O-2、AC-15 は O-4、AC-17 は O-1 か O-4、AC-25 は O-1。
- 要修正、:98：8 のいちばん強い反論の3文に印がない。
  - 直す方向：「ToRead や Bookmory、ストップウォッチでほぼ同じことができ」には［公開情報 3 の表、E-6］を付け、残りは［推測］にする。
- 要修正、:64：O-3「通知や SNS に引っ張られて、読書がそこで終わる」の印は［公開情報 E-1］だが、E-1 の出典にあるのは「携帯電話、スマートフォンなどで時間が取られる」だけ。
  - 直す方向：E-1 を超える部分は［推測］にするか、そう書いた声を出典にする（mekuru の RSS 2026-09-23「snsに疲れる日々ですが」が近い）。
- 要修正、:25 と product.md:10：「」の中の文が原文と違う。原文は「携帯電話、スマートフォンなどで時間が取られる」。数字はすべて合っている。
  - 直す方向：原文のとおりに書く。
- 要修正、:27：E-3 の「開きっぱなしでないと数えない」「2時間で終わった」は言い換えなのに「」で書いている。件数の4件は合っている。
  - 直す方向：原文を引用するか、「」を外して要約と書く。
- 要修正、:17：「2時間操作がないと終わる」は、製品ページの 2.1.0 の更新内容と少し違う。実際は「2時間ほど画面に触れられていないと『まだ読んでいますか?』と一度おたずねし、返事がなければ15分後に読書を終了」。
  - 直す方向：「2時間触れないと確認が出て、返事がなければ15分後に終わる」と書く。「開いたままでないと数えない」は、開発者の返答（2026-09-29「部屋を画面に出しているあいだの時間を数える作り」）で確かめられた。
- 要修正、:332 と :345：「クラッシュしない利用者の割合」の出典は Apple の同業比較のページだが、そのページにあるのは「Crash Rate：Crashes divided by total sessions」で、利用者の割合ではない。このままでは 14 の3行目を判定する数字が取れない。
  - 直す方向：定義を Crash Rate（セッションあたり）に合わせて数値を決め直すか、「取り方は tech-lead が G1 で決める」と書く。
- 要修正、:345：3行目の行動「段階リリースの一時停止」は初版では使えない。Apple の説明では、段階リリースは版の更新を、自動アップデートの利用者に7日かけて配るもの。
  - 直す方向：「段階リリース中なら一時停止、初版なら配信の停止を推奨」と分けて書く。2行目（:344）は「段階リリース中なら」と条件が付いているので、問題ない。
- 要修正、:328、:333、:356、:361：I-1（初めて開いて24時間以内）と I-3（次の週も読んだ）は、同じ人の記録をつなげないと計算できない。15 のイベントには、端末の ID も、「初めて開いてから何時間か」「先週も残したか」のプロパティもない。このままでは 7 の5行目（計測の仕組みがなく、撤退基準を判定できない）がそのまま起きる。
  - 直す方向：端末で計算したプロパティを足す（例：Reading Ended に is_first_saved と hours_since_first_open の区分）。または、ランダムな ID を持つと決めて、プライバシー表示に反映する。その1 の判定と重なるかもしれない。
- 要修正、product.md:13：読書メーターの「7,187件」に出典の URL がない（付いているのはブクログの URL）。件数そのものは search API の結果と合う。
  - 直す方向：https://apps.apple.com/jp/app/id509979590 を付ける。
- 提案、:79〜83 と product.md:30：mekuru は動きが速い。
  - 2026-08-12 の公開から 10-12 の 5.1.0 まで、2か月で版を重ねている。
  - 開発者の返答には「9月28日から…6分のあいだ同じ部屋の席を取っておく」「アプリを切り替えた時点までの読書時間は、記録に残る作り」とある。O-1 の証拠（09-23〜24）は、この変更より前のもの。
  - 開発者は「いまは数えられません」とも書いている。
  - 6 に「mekuru が数え続ける作りに変われば差がなくなる」というリスクを足し、product.md:30 に開発者の返答を添えるとよい。
- 提案、:43〜46：JP の「読書 タイマー」の上位3件は、mekuru、ToRead、ネコノホンシツジ。10位の ReadShelf は「あなたのデータを外に出すことは一切ありません」と打ち出していて、1 の「読んだ本の名前は端末の外に出ません」と同じ点を売りにしている。違いの文に ReadShelf か Honno を足すとよい。
- 提案、:38、:73、product.md:33：引用に日付を添える。
  - Bookmory の2つの引用は、2024-10-13 の同じ1件のレビュー。
  - Bookly JP の引用は 2022-07-11、Bookmory のバックアップの引用は 2023-09-24。
  - 「繰り返し出る」と言うなら、日付と件数を書く。
- 提案、:44：mekuru にも「ひとりの部屋」がある（開発者の返答と 1.2.0 の更新内容）。「一人で読む」は違いになりにくいので、違いは「上限なく、ロック中もほかのアプリの間も数える」に絞る。
- 提案、:66 と :45：「いちばん近い競合」が、:66 では mekuru、:45 では ToRead（「機能はもっとも近い」）になっている。どちらかにそろえる。
- 提案、:21：「人に見せる仕組みは持たない」は製品の決め事なので、Job ではなく 10 に移す。
- 提案、:83：「プレッシャーなし」の出典は 3 の表ではなく、ToRead の製品ページ（「プレッシャー、目標、気を散らすものなしで」）。製品ページの URL を付ける。
- 提案、:332 と :333：クラッシュの目標 99.5% に印がない。I-3 の種類「見守り」は、ひな形の「主 / ガードレール」のどちらでもない。
- 提案、:341〜347：相対の日付は日付として認める（下の表の11を参照）。そのうえで「公開日＝JP の App Store で配信が始まった日（日本時間）」と1行書き、実際の日付を docs/approvals/ の承認の記録に書くと決めておく。

## 採点表（design-reviewer だけ）
対象外

## 前回の指摘の追跡（r2 だけ）
対象外（r1）

## 証拠
- 対象：BASE=ea9fc51 の docs/prd/001-reading-session.md（1〜8 と「G0 の前の確認」。関係する範囲で 9、11、13〜15、17、18）と docs/prd/product.md（1 と 4）。
  - 作業中に HEAD が f112613 に進んだ。足されたのは docs/reviews/001-reading-session-G0-verifier-r1.md だけで、対象のファイルの差分は0行（`git diff ea9fc51 HEAD -- docs/prd/001-reading-session.md docs/prd/product.md docs/templates/prd.md docs/org/gates.md | wc -l` の結果が 0）。
  - 判定が引きずられないように、verifier の報告は読んでいない。

### 表1 引用の確かめ
| # | 引用（PRD と product.md の行） | アプリ | 見た URL | 結果 |
|---|---|---|---|---|
| 1 | 「開きっぱなしじゃないと時間がカウントされません」（:35、p:30） | mekuru | JP RSS p1 | あった（2026-09-23 ★3） |
| 2 | 「画面閉じれるようにして欲しい」（:35、p:30） | mekuru | JP RSS p1 | あった（2026-09-23 ★3） |
| 3 | 「読書時間が2時間しか記録されていなかった」（:35、p:30） | mekuru | JP RSS p1 | あった（2026-09-24 ★1） |
| 4 | 「スリープモードでも途切れずに使えたら」（p:30、:27） | mekuru | JP RSS p1 | あった（2026-09-23 ★3） |
| 5 | 「バッテリー」の不満（:71、:386） | mekuru | JP RSS p1 | あった（2026-09-23 のレビューの題「毎日使いたいけどバッテリー消費がきになる」） |
| 6 | 要約：ほかのアプリから戻ると部屋に入れず、読書時間がリセット（p:30） | mekuru | 製品ページ | あった（涼町、2026-09-27 ★5）。開発者は「切り替えた時点までの読書時間は、記録に残る作り」と返答している |
| 7 | 要約：手入力を求める声（:73） | mekuru | 製品ページ | あった（6 と同じレビュー「読書時間を手動で入力できるようにしていただけると助かります」） |
| 8 | 開いたままでないと数えず、2時間で終わる（:17） | mekuru | 製品ページ | 近い内容があった（09-29 の開発者の返答と 2.1.0 の更新内容）。指摘7 |
| 9 | 不満の記録なし（:36、p:31） | ToRead | JP RSS p1、US RSS p1、製品ページ | 本当。レビューの本文は JP 0件、US 0件、製品ページにもない |
| 10 | 「Free version gives you a limit of 10 books」 | Bookly | US RSS p1 | あった（2026-10-11 ★1） |
| 11 | 「Ads in the free version are all the sudden out of control」 | Bookly | US RSS p1 | あった（2026-10-13 ★2） |
| 12 | 「got asked more questions than I have at most job interviews」 | Bookly | US RSS p2 | あった（2026-09-18 ★1） |
| 13 | 「Constantly asking to be paid」（p:32） | Bookly | US RSS p2 | あった（2026-09-16 ★1） |
| 14 | 「When I don't remember a reading time, it is very inconvenient to record its time」（:73） | Bookly | JP RSS p1 | あった（2022-07-11 ★2。原文のアポストロフィは「’」） |
| 15 | 「9月発売の本を検索しても見つからない」 | Bookmory | JP RSS p1 | あった（2024-10-13 ★3） |
| 16 | 「バーコードの読み取りに失敗した場合、フリーズ」 | Bookmory | JP RSS p1 | あった（15 と同じレビュー） |
| 17 | 「バックアップ作成でうまくいくときと、うまくいかない時がある」（p:33） | Bookmory | JP RSS p1 | あった（2023-09-24 ★3） |
| 18 | 要約：入力の手順が多い（p:33、E-4） | Bookmory | 製品ページ | あった（2025-07-26「入力に手間が掛かりすぎる」） |
| 19 | 「豪華なデザインとかアニメーションとか要らない」 | Forest | JP RSS p1 | あった（2026-10-09 ★1） |
| 20 | 「作業終了時に余計なアニメーションやひと手間が増えて」 | Forest | JP RSS p1 | あった（2026-10-13 ★1。原文は「増えており」） |
| 21 | 「今では無駄な演出や増えた手順のせいでストレス」（p:34） | Forest | JP RSS p1 | あった（2026-09-26 ★1。同じ趣旨が 09-22 と 09-27 にもある） |
| 22 | 「バーコードで本登録できんくなった」 | ブクログ | JP RSS p1 | あった（2026-05-19 ★1） |
| 23 | 「表紙が出なくなってしまった」 | ブクログ | JP RSS p1 | あった（2026-07-08 ★2） |
| 24 | 「検索機能がいけてなくて使いづらい」 | ブクログ | JP RSS p1 | あった（2026-05-07 ★2） |
| 25 | 「月額料金を払わないと…フォルダ分け・並べ替えすらできず」 | ブクログ | JP RSS p1 | あった（2026-03-02 ★1。省いた部分は「登録した本の」） |
| 26 | E-6：ほかのアプリの間も数え、ロック画面に出る。名前を付ける記載はない | ストップウォッチ | apollomaniacs | あった（「カウントはバックグラウンドでちゃんと続いています」「ロック画面に進捗状況が表示」。「名前」は0件） |
| 27 | 紙の読書ノートに、読んだ時間の欄はない（:51、p:37） | 紙のノート | 横浜市泉区 | あった（記録の項目はタイトル、著作者名、出版社、日付、星取表、感想など） |

（p: は product.md の行）

### 表2 数字の確かめ
| 数字 | 行 | 結果 |
|---|---|---|
| 62.6%、69.1%、43.6%、回答3,559人 | :25 | すべてあった。ページには「3559人(59.3%)」「文化庁が実施した2023年度の『国語に関する世論調査』」とある |
| mekuru の評価360件、平均4.7、公開日 2026-08-12 | :26 | lookup では 362件、4.685、releaseDate 2026-08-12。件数の差は、同じ日に増えた分と見た |
| 「読書 タイマー」の上位10件のうち7件 | :374 | 7件で合う：1 mekuru、2 ToRead、3 ネコノホンシツジ、4 Honno、5 ツンドク、8 読書タイマー〜読書記録&習慣化〜、10 ReadShelf。残りの SwingCat、Forest、ポモキャットは集中タイマー |
| 3 の表の評価の数 | :35〜39 | ToRead JP 3（PRD は2）、US 8。Bookly JP 237、US 62,090。Bookmory JP 189、US 16,163。Forest 10,738。ブクログ 28,252。読書メーター 7,187。差はどれも、同じ日に増えた分の範囲 |
| 価格 | :35〜38 | 合う：mekuru ¥580/¥5,800、ToRead Plus ¥1,500、Bookly $4.99/$29.99 と広告、Bookmory ¥380/¥3,400 と広告 |
| 「Bookly の不満の多くは課金の壁と広告」 | :389 | US の直近100件のうち★1〜2 が10件。そのうち8件が課金、広告、上限の話 |

### 表3 G0 の前の確認（12項目）
| # | 判定 | 根拠の行 | メモ |
|---|---|---|---|
| 1 | 満たす | :33〜41 | アプリ5件、代替2つ。引用は全件あった。ToRead の行の中身は不完全（指摘1） |
| 2 | 満たさない | :45、:98、:64 | 出典と食い違う文に印がない（重大）。印のない反論、中身を支えない印もある。URL は3つより多い。［推測］だけで支えた結論は見つからない |
| 3 | 満たす | :20〜21 | Job は1つ。画面名も機能名もない |
| 4 | 満たす | :61〜74 | 機会4つ、解決案5つ。選んだ理由（:66）と捨てた理由がある |
| 5 | 満たす | :77〜94 | 6 は全行、全列が埋まっている。7 の結び付け先はすべて PRD の中に実在する |
| 6 | 満たす | :97〜99 | 3つともある。印は指摘3 |
| 7 | 満たす | :106〜118 | 11行すべてに Kano（当たり前8、性能2、魅力1）と O-n がある |
| 8 | 満たす | :133〜144 | 11項目すべてに理由がある |
| 9 | 満たさない | :191、:197、:203、:245、:257、:305 | 25件×5つの欄はそろい、測れない言葉は0件。効く機会のうち6件がひな形の書き方の外（重大） |
| 10 | 満たす | :326〜335 | ガードレールは4つ。主の指標は見かけの指標ではない。基準値はひな形 :109 の書き方どおり。Apple の URL は開けた（200） |
| 11 | 満たす | :341〜349 | 4つの欄が全行にあり、判定は pdm 以外の役。「公開28日後」は公開日が決まれば1つの暦の日に決まる。G0 の今の時点で暦の日を書くほうが作り話になるので、日付として認める |
| 12 | 満たす | :356〜364 | 9つのイベントすべてに区分がある |

### 表4 8 と AC の効く機会
- 推奨（:97）：E-1、E-2、E-3、E-5 に支えられていて、どれも出典で確かめた。［推測］だけではない。
- 反論（:98）：印がない。ToRead が実際にできることを入れると、反論はもっと強くなる。
- 作らない場合（:99）：ブクログの件数は合う（28,252件）。
- AC の効く機会の内訳：
  - O-n が12件（AC-2、4、5、9〜14、16、19、21）
  - 許される「当たり前」が7件（AC-1、3、18、20、22、23、24）
  - 許されない「当たり前」が6件（AC-6、7、8、15、17、25）

### 読んだファイル
- docs/prd/001-reading-session.md
- docs/prd/product.md
- docs/templates/prd.md
- docs/templates/review-report.md
- docs/org/gates.md

### 実行したコマンドと結果
- RSS：`curl -s <RSS> | python3 -I <scratchpad>/check.py <ラベル> <引用…>` をアプリごとに実行。結果は表1。
- 製品ページ：`curl -s -A <Safari の UA> <URL> | python3 -I <scratchpad>/page.py <ラベル> <語…>`。結果は表1と表2。
- lookup と search の API を curl で取り、python3 で読んだ。結果は表2。
- nippon.com、apollomaniacs、横浜市、Apple の2ページも curl で取って page.py で読んだ。
  - Apple の2ページは、最初の試しで `-w '@@HTTP…'` と書いて curl がエラーになった。`-w '\n==HTTP %{http_code}==\n'` に直して取り直し、どちらも HTTP 200 だった。
- grep で数えた結果：
  - AC の見出しは25件。Given、When、Then、確かめ方、効く機会は、それぞれ25件。
  - 測れない言葉は0件。
  - 第1部は88行。
- `git status --short` の出力は空。
- スクリプトはリポジトリの外に置いた：
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/check.py
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/page.py

### 開いた URL（すべて 2026-10-15）
- RSS（URL はすべて `https://itunes.apple.com/<国>/rss/customerreviews/page=<N>/id=<ID>/sortby=mostrecent/json` の形）：
  - JP p1：6792955764（mekuru）、6757129946（ToRead）、1085047737（Bookly）、1515533482（Bookmory）、866450515（Forest）、359066582（ブクログ）
  - US p1：6757129946（ToRead）、1085047737（Bookly）
  - US p2：1085047737（Bookly）
- 製品ページ：
  - mekuru：https://apps.apple.com/jp/app/mekuru/id6792955764
  - Bookmory：https://apps.apple.com/jp/app/bookmory-%E6%9C%AC%E6%A3%9A-%E8%AA%AD%E6%9B%B8%E8%A8%98%E9%8C%B2-%E8%AA%AD%E6%9B%B8%E7%AE%A1%E7%90%86/id1515533482
  - ToRead：https://apps.apple.com/jp/app/toread-%E8%AA%AD%E6%9B%B8%E3%82%BF%E3%82%A4%E3%83%9E%E3%83%BC/id6757129946
  - Bookly：https://apps.apple.com/us/app/bookly-book-tracker/id1085047737
- lookup と search：
  - https://itunes.apple.com/lookup?id=6792955764,6757129946,1085047737,1515533482,866450515,359066582&country=jp
  - https://itunes.apple.com/lookup?id=6757129946,1085047737,1515533482&country=us
  - https://itunes.apple.com/search?term=読書%20タイマー&entity=software&country=jp&limit=10
  - https://itunes.apple.com/search?term=読書メーター&entity=software&country=jp&limit=5
- そのほか：
  - https://www.nippon.com/ja/japan-data/h02135/
  - https://www.apollomaniacs.com/ipod/howto_touch_clock_stopwatch.htm
  - https://www.city.yokohama.lg.jp/izumi/kurashi/kyodo_manabi/manabi/dokusho/dokushokiroku.html
  - https://developer.apple.com/help/app-store-connect-analytics/benchmarks/peer-group-benchmarks/
  - https://developer.apple.com/help/app-store-connect/update-your-app/release-a-version-update-in-phases

### 未検証
- ToRead が実機で、ロック中も数え続けるか（製品ページの説明から読み取っただけ）。
- product.md:35 のブクログの強みとプレミアム、:34 の Forest Plus の中身、:32 の Bookly の強み。
- App Store Connect に「クラッシュしない利用者の割合」の指標がないこと（同業比較のページの定義しか見ていない）。
- 15 の区分が正しいか（その1 の範囲なので見ていない）。

### git status --short
（出力なし）

### 記録（判定役が書いたもの）
- 関門：G0
- 判定した役：tech-lead（その2）
- 回：r1
- 対象：feat/001-reading-session、BASE ea9fc51（HEAD f112613。対象のファイルは同じ）
- 日付：2026-10-15

# その1：実現性、非機能、費用、プライバシー

FAIL

以下、「PRD」は /Users/takumamatsuura/reading-app/docs/prd/001-reading-session.md（BASE=ea9fc51 から変わっていない）を指します。

## 指摘
重大1件、要修正7件、提案5件です。どれも PRD の文を直せば済み、作るものの考え方は変えなくてよい内容です。25件の AC は、標準のフレームワークだけで作れます。許可のダイアログもバックグラウンドの実行も要りません。

1. 重大、PRD:332 と PRD:345
   - 問題：「クラッシュしない利用者の割合」を「App Store Connect と Xcode のクラッシュの記録」で測るとしています。しかし App Store Connect が定めているのは Crash Rate（"Crashes divided by total sessions"、つまりセッションあたり）で、利用者の割合ではありません。対象も、分析の共有に同意した利用者だけです。利用者の割合を出せる Apple の定義は見つかりませんでした。
   - なぜ重大か：この行は撤退基準（段階リリースの一時停止）に使われます。14 は「公開の前に決め、後から動かさない」（PRD:339）ので、承認のあとでは直せません。
   - 根拠：https://developer.apple.com/help/app-store-connect-analytics/benchmarks/peer-group-benchmarks/
   - 直す方向：13 と 14 の指標を「Crash Rate（App Store Connect、クラッシュ数÷セッション数）」に替え、目標と撤退の数値を置き直します。利用者の割合のまま残すなら、(b) のときに MetricKit の診断から求める式とイベントを 15 に足します（MetricKit の使い方は G1 で確かめる）。

2. 要修正、PRD:374（17 の 4.3(b)）、PRD:43-46、PRD:98
   - 問題：今の 4.3(b) は "simple timers" を名指しし、"we will not accept new submissions unless they offer a meaningfully different or improved experience" と書いています。PRD は、ストアの検索の件数と違いの文で受けているだけです。しかも 8 の反論で「機能だけなら…ほぼ同じことができ」と自分で認めています。却下されると、2週の枠が無駄になります。
   - 根拠：https://developer.apple.com/app-store/review/guidelines/ の 4.3(b) と 2.3.1(a)（審査メモに具体的に書くこと）
   - 直す方向：17 に本文を引きます。審査メモで見せる違いを書きます（本ごとに時間が残る、ロックやほかのアプリや強制終了をまたいで数える、記録を直せる）。6 のリスクの表に「審査」の行を足し、このリスクを受け入れるかを 18 で Takuma に聞きます。

3. 要修正、PRD:377（17）、PRD:103-118（9）、PRD:153-305（11）
   - 問題：5.1.1(i) は "All apps must include a link to their privacy policy in the App Store Connect metadata field and within the app in an easily accessible manner." と定めています。PRD は「Q4 で計測を入れるならプライバシーポリシーが要る」と読めます。アプリの中でリンクを置く場所も、9 と AC にありません。
   - 直す方向：17 を「Q4 によらず要る」に直します。9 に「アプリの中にプライバシーポリシーへのリンクを置く（読書中の画面には置かない。AC-9 の押せる要素を増やさないため）」を足し、11 にその AC を足します。

4. 要修正、PRD:356-364、PRD:366（15）、PRD:388（Q4）
   - 問題（ID を送る場合）：続けて使うランダムな ID をイベントに付けると、「結び付くか：いいえ」は成り立たないおそれが高いです。
     - Apple は Device ID を "the device's advertising identifier, or other device-level ID" とし、"'Personal Information' and 'Personal Data', as defined under relevant privacy laws, are considered linked to the user" と書いています。
     - 結び付くとされれば、5.1.2(i)（個人データを送る前に許可を得る）にも当たりえます。
   - 問題（ID を送らない場合）：I-1（初回から24時間以内）と I-3（翌週も読んだ）を出すためのプロパティが、表にありません。
   - 根拠：https://developer.apple.com/app-store/app-privacy-details/ 、ガイドライン 5.1.2(i)
   - 直す方向：ID を送らない形にします。Reading Ended に、端末の中で求める真偽を3つ足します（`first_saved_within_24h`、`first_saved_this_week`、`saved_last_week`）。区分は「使用状況データ（製品の操作）」と「診断（その他の診断データ）」で、結び付かない、トラッキングしない、と書けます。

5. 要修正、PRD:349（14 の注記）、PRD:326-333（13）
   - 問題：Q4 で (a) を選んだときに置き換えるのは、14 の1行目と2行目だけです。次の行もイベントがないと測れません。
     - 14 の4行目（6時間以上の記録の割合）と5行目（I-3）
     - 13 の I-2、6時間以上の割合、直されたか消された記録の割合
   - 直す方向：(a) のときの置き換えを、イベントに頼る全部の行に書きます。例：I-3 は App Store Connect の Day 7 / Day 28 Retention にする。6時間以上の割合は測れないので、行を外す理由と代わりの手当てを書く。

6. 要修正、PRD:148（10）、PRD:154、PRD:216-221（AC-11）、PRD:270-275（AC-20）
   - 問題：時刻の扱いは「証拠 1-b」の方針にします。ただ、計算した分が0未満（端末の時刻を戻した）か1440を超える（終え忘れ、時刻を進めた）ときの決まりと AC がありません。今のままだと、30時間の終え忘れは「終える」で1800分の記録になり、直す画面では今の値が1〜1440の外になって保存できません。
   - 直す方向：pdm が AC を2つ足します（例：AC-26 経過が1440分を超えたとき、AC-27 端末の時刻が読み始めより前に戻されたとき）。記録に残す値は1〜1440にそろえ、負の値は残しません。扱い方（分を入れてもらう、1440で止める など）は pdm が決めます。

7. 要修正、PRD:214（AC-10 の確かめ方）
   - 問題：画面のテストでは、画面をロックできません。XCUIDevice.Button の値は home、volumeUp、volumeDown、action、camera だけです。
   - 根拠：https://developer.apple.com/documentation/xcuiautomation/xcuidevice/button
   - 直す方向：「ほかのアプリ（ホームで離れる）は画面のテスト、ロックは実機の確認」と書き分けます。

8. 要修正、PRD:308-312（12 の速さ）
   - 問題：4行とも数字はありますが、測り方と測る機種がありません。
   - 直す方向：機種は Takuma への質問 T2 の答えにします。測り方は「証拠 1-d」の表を写します。

9. 提案、PRD:162-173（AC-2、AC-3）
   - 問題：「字」の数え方が決まっていません。
   - 直す方向：前後の空白を除いたあとの Swift の Character（書記素）の数にします。テストの値に「全角空白（U+3000）だけ」と「絵文字を含む100字」を足します。

10. 提案、PRD:174-179（AC-4）
    - 問題：記録を消したり分を直したりしたあと、「最後に読んだ日時」をどう求めるかが決まっていません。
    - 直す方向：「残っている記録で最も新しい読み始めの日時。記録がなければ加えた日時」と書きます。

11. 提案、PRD:362（Reading Save Failed の error_kind）
    - 問題：disk_full を空き容量の API で求めると、申告の理由 E174.1 が "Information accessed for this reason, or any derived information, may not be sent off-device." と定めているため、外に送れません。
    - 直す方向：保存のエラーの種類から決める、と書きます。

12. 提案、PRD:319（12）、PRD:387（Q3）
    - 直す方向：バックアップの答え（証拠 5）を 12 と docs/support/ に書きます。アプリを消すと記録が消えることも書きます。

13. 提案、PRD:370（16）
    - 直す方向：月の費用を、証拠 3 の数字で埋めます。

## 採点表（design-reviewer だけ）
対象外です。

## 前回の指摘の追跡（r2 だけ）
対象外です（r1）。

## 証拠
- 対象：BASE=ea9fc51 の PRD（とくに 9〜18）と /Users/takumamatsuura/reading-app/docs/prd/product.md の 6。
  - 終わりの時点で HEAD は 8f8504e に進んでいました。間のコミット（f112613、8f8504e）は docs/reviews/ に2ファイルを足しただけで、`git diff --stat ea9fc51 HEAD -- docs/prd` は空です。判定は同じ PRD に対するものです。
  - 判定を独立に保つため、足された2つの報告は読んでいません。
- 観点：その1（実現性、非機能、費用、プライバシー）だけを見ました。第1部の根拠と「G0 の前の確認」は、その2 の担当なので見ていません。

### 1. AC ごとの実現性の表（25行）
| AC | 実現できるか | 使う iOS の仕組み | 気になる点 |
|---|---|---|---|
| AC-1 | できる | SwiftUI の標準の一覧と空の表示、SwiftData の取得 | ツールバーの「+」と空の表示のボタンを両方出すと `books.add` が2つになる。G1 でどちらか1つにする |
| AC-2 | できる | TextField。前後の空白は `.whitespacesAndNewlines` で除く | 「字」の数え方が決まっていない（指摘 9） |
| AC-3 | できる | 同上。加える操作を無効にする | 全角空白だけのタイトルも「空白文字だけ」に入れる |
| AC-4 | できる | SwiftData の並べ替え。最後の日時は記録から求める | 記録を消した・直したあとの並び（指摘 10） |
| AC-5 | できる | 一覧の行から読み始める。初回の案内の画面を置かない | 起動時に `reading` なら読書中の画面に戻る（AC-11）ので、AC-5 は `idle` のときだけ |
| AC-6 | できる | 記録は本への関係でタイトルを引き、写して持たない | 記録にタイトルを写すと、直したときにずれる。設計メモで禁止する |
| AC-7 | できる | SwiftData の関係の削除規則（cascade）、確認のダイアログ、件数は String Catalog の複数形 | 将来 iCloud を足すため、関係は optional にしておく（証拠 5） |
| AC-8 | できる | 同上 | なし |
| AC-9 | できる | 読書中の画面を全画面の表示にし、ナビゲーションバーとタブバーを出さない | シートで出すと、下に引いて閉じる操作が残る。押せる要素は、ボタン、リンク、スイッチ、入力欄の数の合計で数える |
| AC-10 | 条件付き（確かめ方） | 読み始めの時刻を保存し、戻ったときに差で数える。バックグラウンドの実行は使わない。プロセスが生きている間は ContinuousClock（"does not stop incrementing while the system is asleep"） | ロックは画面のテストでできない（指摘 7）。テストでは起動引数（DEBUG ビルドだけ）で読み始めを10分前にし、10分待たない。実機での10分の確認は G3 |
| AC-11 | 条件付き（時刻の方針） | 読み始めに状態を保存してから画面を出す。開き直したら、保存した時刻から数え直す | ContinuousClock の時刻は "only comparable locally during the execution of a program" なので、強制終了のあとは端末の時刻（Date）に頼る（1-b、指摘 6）。強制終了は XCUIApplication の terminate() を使う見込み（文書は G1 で確かめる） |
| AC-12 | できる（確かめ方は 1-c） | `isIdleTimerDisabled` に触らない（既定は false）。音や動画を流さない | シミュレーターの画面のテストでは、自動ロックを確かめられない |
| AC-13 | できる | 分＝秒÷60 の切り捨て。合計は記録ごとの分の和 | 秒の和を切り捨てると、20＋12＝32 とずれることがある。記録ごとの分の和にそろえる |
| AC-14 | 条件付き（測り方） | 保存は1件の書き込み | XCUITest の待ちには、テストの道具そのものの遅れが入る。測り方は 1-d |
| AC-15 | できる | 59秒は0分なので保存しない | (b) なら Reading Ended（saved=false）が I-2 の分母に入る |
| AC-16 | できる | 開始の時刻を、開始のときのタイムゾーンで日付にする | 日英の日付の書式は designer が決める |
| AC-17 | できる | 開始の時刻（Date）とタイムゾーン ID を保存し、その日の記録にする | 分は Date どうしの差なので、タイムゾーンに左右されない |
| AC-18 | できる | 空の表示 | なし |
| AC-19 | できる | 記録の分を書き換え、合計は記録から求める | なし |
| AC-20 | できる | 1〜1440 の外では保存の操作を無効にする | 「終える」で1440分を超える記録ができてしまう（指摘 6） |
| AC-21 | できる | 記録を消し、合計は記録から求める | なし |
| AC-22 | 条件付き（つなぎ口） | DEBUG ビルドだけで効く起動引数で、保存を次の N 回失敗させる。読書ごとの ID で1件にまとめる | 一意の制約は将来の iCloud で使えないので、保存の前に同じ ID を探す形にする。つなぎ口は G1 で contracts/ に書く |
| AC-23 | できる | (a) なら通信のコードがない。(b) なら送信の失敗を画面に出さない | 確かめ方は 1-c |
| AC-24 | できる | 通知、カメラ、写真、位置、トラッキング、iCloud を使わない | テストではホーム画面側（springboard）のダイアログを0と数える（書き方は G1 で確かめる）。Q1 で (b) を選ぶとカメラの許可が出る |
| AC-25 | できる | SwiftData に保存し、開き直して読む | なし |

### 1-b. 時刻の方針（AC-10、AC-11、PRD:148 の「要確認」と PRD:81 の実現性への根拠）
1. 読み始めに、読書の ID、本、開始の時刻（Date）、開始のときのタイムゾーン ID を保存します。保存できてから読書中の画面を出します。
2. プロセスが生きている間（ロック中や、ほかのアプリの間で止められているだけのときも含む）は、ContinuousClock の差で数えます。眠っている間も進み、端末の時刻を手で変えても影響を受けません。
3. 開き直したあと（強制終了、システムによる終了、再起動）は「今の Date − 開始の Date」で数えます。
4. 分は、秒を60で割って切り捨てます。結果が0未満か1440を超えるときは、そのまま残しません（指摘 6）。こうすれば、負の値や極端な値は記録に入りません。
5. 日付は、開始の Date を開始のときのタイムゾーンで表した日です。分は Date どうしの差なので、タイムゾーンをまたいでも変わりません。
6. 使わないもの：
   - `ProcessInfo.systemUptime`（"The amount of time the system has been awake since..."。眠っている間を数えない）
   - `SuspendingClock`（"stops incrementing while the system is asleep"）
7. 弱い所：強制終了のあとに時刻を手で変えると、3 の差がずれます。4 の範囲の中なら気づけません。再起動をまたいでも比べられる時計（mach_continuous_time など）が申告の一覧に入るかは未確認で、G1 の ADR で決めます。
8. 実機での確かめ（PRD:81 の合格の線）は G3 で行います。今回は指示どおり spike をしていません。

### 1-c. AC-12、AC-22、AC-23 の確かめ方
- AC-12：
  - (1) `grep -rn isIdleTimerDisabled ios/` が0行であることを、受け入れテストの前提として CI で見ます。Apple は "Most apps should let the system turn off the screen when the idle timer elapses." と書いています。
  - (2) 実機で自動ロックを30秒にし、40秒以内に画面が消えることと、戻ったときに `reading` のままであることを見ます（G3）。
  - 値を出す隠れた要素を画面に置く案は、AC-9 の要素の数と VoiceOver の読み上げに混ざるので採りません。
- AC-22：起動引数（例：`-UITest-FailNextSaves 1`、DEBUG ビルドだけ）で、保存が次の1回だけ失敗するようにします。読み始めは起動引数で15分前にします。
  - 1回目の「終える」：`session.save.error` が出て、状態が `reading` のままかを見ます。
  - 2回目の「終える」：記録が1件で15分以上かを見ます。
  - 空き容量を本当に0にする方法は使いません。再現しにくく、空き容量の API には E174.1 の制約があるためです。
- AC-23：
  - (a) なら、通信のコードがないこと（`grep -rn URLSession ios/` が0行）と、画面のテストで記録が残り、エラーの表示が0回であることで足ります。
  - (b) なら、起動引数で送信を必ず失敗させ、保存と画面に影響しないことを見ます（12 の行）。
  - 機内モードでの通しは、実機で確かめます（G3）。

### 1-d. 速さの線と最低対応の機種（AC-14 と 12）
- 最低対応 OS の案：iOS 26.0。
  - 2026-06-07 の時点で、iPhone 全体の79%、最近4年に出た機種の86% が iOS 26 です（Apple の公表値）。
  - iOS 26 だけにすれば、見た目（Liquid Glass）が1通りで済み、G3 のスクリーンショットと見た目の確かめが半分になります。
  - 反論：2026-06 の時点で約21% の iPhone が入れられず、iPhone XS と XR の人を外します。
- 測る機種の案：iOS 26 が動くいちばん古い機種、iPhone 11 の各機種か iPhone SE（第2世代）。Apple の対応機種のページで確かめましたが、検索の結果の要約で見ただけで、本文は開いていません。

| 12 の行 | 測り方 | 合格の線 |
|---|---|---|
| 起動から一覧を操作できるまで1秒 | 性能テストで `XCTApplicationLaunchMetric(waitUntilResponsive:)` を5回動かす | 平均1.0秒以内 |
| 「終える」から終わりの画面まで0.5秒 | 押したときと終わりの画面の表示に os_signpost を置き、`XCTOSSignpostMetric(subsystem:category:name:)` で5回測る | 平均0.5秒以内 |
| 200冊・5,000件で一覧が1秒 | 起動引数でデータを入れ、一覧の表示を os_signpost で区切って測る | 1.0秒以内。超えたら記録の一覧を分けて読み込む |
| 演出で待たせる時間が0秒 | 画面のテストで、演出の途中に次の操作を押して効くかを見る。演出の間に操作を止める書き方を grep で探す | 0件 |

- 見込み：1件の書き込みと200行の一覧は、A13 の機種でも線に収まると見ています［推測］。確かめるのは G2 で、実機の出力を設計メモの 6 に貼ります。

### 2. 審査と権限で気になる点
| 項目 | 見立て | 根拠 |
|---|---|---|
| 許可のダイアログ | 0回で作れる。通知、カメラ、写真、位置、トラッキング、iCloud を使わない。(b) のインターネットへの送信にも許可は要らない | ATT の文書は、追跡するアプリだけに要るとする |
| バックグラウンド（2.5.4） | 使わない。UIBackgroundModes も BGTask も要らない。時刻の差で数えるので、アプリが止められても困らない | 2.5.4 |
| entitlement | v1 では要らない。Q3 で (b) を選ぶと iCloud と CloudKit が要る | SwiftData の同期の文書 |
| 4.2 | 低いか中くらい。保存するデータ、2つの一覧、直す・消す操作があり、ウェブの包み直しではない | 4.2 |
| 4.3(b) | 高い。"simple timers" が名指しされている（指摘 2）。ToRead と mekuru が JP のストアにあることは、和らげる材料にはなる。ただ、名指しの文が入った時期との前後は確かめていない | 4.3(b) |
| 2.3、2.3.1 | 「通信なし」「何も送らない」と書けるのは (a) のときだけ。審査メモには機能を具体的に書く | 2.3、2.3.1(a) |
| 5.1.1(i) | すべてのアプリに、アプリの中のリンクも要る（指摘 3） | 5.1.1(i) |
| 5.1.2(i) | 個人データを送るなら許可が要る。ID を送らない形で避ける（指摘 4） | 5.1.2(i) |
| PrivacyInfo.xcprivacy | 下に分けて書く | 公式の理由の一覧 |

PrivacyInfo.xcprivacy で申告が要る見込みのもの：
- UserDefaults（初回の起動の印など）を使うなら、NSPrivacyAccessedAPICategoryUserDefaults と CA92.1（アプリだけが読み書きする）。
- systemUptime など起動からの時間の API を使うなら、NSPrivacyAccessedAPICategorySystemBootTime と 35F9.1。35F9.1 には "an exception for information about the amount of time that has elapsed between events that occurred within the app, which may be sent off-device" があり、duration_minutes は送ってかまいません。
- 今の時刻（Date）は、申告の一覧にありません。ファイルの作成・変更の日時（NSFileModificationDate など）は一覧にあるので使いません。
- 空き容量の API は使いません。
- (b) では、NSPrivacyCollectedDataTypes に「製品の操作」と「その他の診断データ」を書き、NSPrivacyTracking は false にします。

### 3. 利用者1,000人あたりの月の費用
- 送る件数の見積もり［推測］：1日1回読む人で、Reading Started 30件、Reading Ended 30件、そのほか約5件で、月に約65件です。1日2回なら約125件です。1,000人なら月に6.5万〜12.5万件です。

| 案 | サーバー | 外部のサービス | 1,000人あたりの月 | 根拠（開いた日 2026-10-15） |
|---|---|---|---|---|
| (a) イベントを送らない | 0 | 0 | 0ドル | Apple の App Analytics は "You are not responsible for disclosing data collected by Apple." |
| (b) Aptabase | 0 | 無料は月2万件まで。20万件の枠が "$10/month" | 約10ドル | https://aptabase.com/pricing 。枠を超えると "analytics are temporarily paused until the start of the next month"。28日目の判定が欠けないよう、余裕のある枠にする |
| (b) Google Analytics for Firebase | 0 | Spark と Blaze のどちらでも "No-cost" | 0ドル | https://firebase.google.com/pricing 。送る識別子と広告の機能の扱いは未確認 |

- TelemetryDeck も候補に考えましたが、料金のページ（/pricing/ と /pricing）は 404 で、dashboard の料金表は本文を取れなかったため、候補から外しました。
- Apple Developer Program の年会費は、利用者の数に関係しない固定費なので、ここには入れていません（額は確かめていません）。

### 4. プライバシー（Q4 で (b) を選んだとき）
- ATT は要りません。
  - Apple の文書は "Your app needs to use the App Tracking Transparency framework if it collects data about people and shares it with other companies to track them across apps and websites." と書いています。
  - トラッキングの定義は「Third-Party Data と結び付けて広告やその計測に使うこと、またはデータブローカーと共有すること」です。
  - 条件：ほかの開発者のアプリのデータと合わせて広告に使う SDK を入れないこと（"even if you don't use the SDK for these purposes"）。
- 端末の中のランダムな ID：
  - Device ID の定義に "other device-level ID" が入り、法律でいう個人データは「結び付く」とみなされます。続けて使う ID を送るなら、「Identifiers > Device ID、結び付く」と申告するのが安全で、PRD の「いいえ」は成り立ちません。
  - ID を送らなければ、"Stripping data of any direct identifiers... before collection" に当たり、「結び付かない」と書けます（指摘 4）。
- 端末の中だけのデータ：収集に当たりません（"Data that is processed only on device is not 'collected'"）。PRD:366 の見立ては正しいです。
  - ただし "If you derive anything from that data and send it off device, the resulting data should be considered separately" とあり、送るプロパティ（分など）は申告します。
- IP アドレス：受け取っても残さなければ申告は要りません（"if an authentication token or IP address is sent on a server call and not retained"）。Aptabase のページには IP を残すかの記載がなく、(b) を選んだら G1 で相手の文書を確かめます。

### 5. Q3：バックアップから記録が戻るか
- iCloud のバックアップ："iCloud Backup includes app data for the apps that you've downloaded on your device."（https://support.apple.com/en-us/108770）
- パソコンへのバックアップ："includes almost all of your device's data and settings"。ただし Keychain は暗号化したバックアップのときだけ入ります（https://support.apple.com/en-us/108771）。
- 新しい機種へは "you can use a backup to transfer your information to a new device" とあり、戻ります。
- 開発者の文書では、tmp と Library/Caches はバックアップから外れます。記録はそこに置きません（https://developer.apple.com/documentation/foundation/optimizing-your-app-s-data-for-icloud-backup）。記録を Keychain にも置きません。
- アプリを消すと、記録は消えます。
- あとで iCloud の同期を足すとき：CloudKit は一意の制約を使えず、関係はすべて optional にする必要があります。CloudKit の型は、本番に上げたあと足すことしかできません（SwiftData の同期の文書）。v1 から、この制約に合う型を VersionedSchema で包んでおけば、型を移し替える手間はなくなります。今あるローカルの記録が同期を入れたときに自動で上がるかは未確認で、Q3 で (b) を選ぶときに ADR と spike で確かめます。

### 6. 18 への tech-lead の推奨と、Takuma への新しい質問
- Q1：(a) を推奨します。
  - 理由：AC-24 の「許可0回」と AC-23 の「通信なし」を保てます。(b) と (c) は、ISBN や検索の語を外部の書誌サービスに送るので、12 の「タイトルと著者は外に送らない」（PRD:316）と食い違います。
  - 元に戻しにくい点：一度送る作りにすると、この約束は戻せません。
- Q3：(a) と、iCloud に合わせた型を推奨します（証拠 5）。
  - 機種を変えても、iCloud かパソコンのバックアップから戻ります。
  - 反論：アプリを消すと記録が消えます。
- Q4：(b) を推奨します。条件は、続けて使う ID を送らないこと、端末の中で求める真偽を足すこと（指摘 4）、送る先は相手の文書で IP を残すかとトラッキングを確かめてから決めることです。
  - 理由：(a) では I-1、I-2、I-3、6時間以上の割合が測れず、撤退基準の4行が判定できません。費用は1,000人あたり月10ドルまでです。
  - いちばん強い反論：「何も送らない」と言えなくなり、外部のサービスと送信のコードが増えます。
- T1（新しい質問）：最低対応 OS
  - 決めてほしいこと：最低対応 OS を iOS 26.0 にするか。
  - 推奨：iOS 26.0（1-d の理由）。
  - いちばん強い反論：約21% の iPhone が入れられない。
  - 元に戻せるか：あとで下げられるが、作業が要る。
  - 見てほしいファイル：この報告の 1-d。
- T2（新しい質問）：性能を測る実機
  - 決めてほしいこと：12 の性能を測る実機を、手元のどの機種にするか。
  - 推奨：iPhone 11 か SE（第2世代）。手元になければ手元の機種で測り、線を半分の秒数にする。
  - いちばん強い反論：古い機種がないと、遅い端末での体験を確かめられない。
  - 元に戻せるか：戻せる。
  - 見てほしいファイル：PRD:308-312。
- 4.3(b) を受け入れるかの問いは、指摘 2 のとおり、pdm が 18 に足します。

### 15 のイベントをどこで取れるか
- 9種類とも、アプリの中で取れます。サーバーはありません。
- App First Opened は初回の印（UserDefaults）で取ります。アプリを入れ直すと、もう一度送られます。
- I-1 と I-3 は、指摘 4 の真偽を足せば ID なしで出せます。

### 読んだファイル
- /Users/takumamatsuura/reading-app/docs/prd/001-reading-session.md（406行すべて）
- /Users/takumamatsuura/reading-app/docs/prd/product.md
- /Users/takumamatsuura/reading-app/.claude/org/app.json
- /Users/takumamatsuura/reading-app/CLAUDE.md
- /Users/takumamatsuura/reading-app/docs/org/gates.md
- /Users/takumamatsuura/reading-app/docs/templates/review-report.md
- /Users/takumamatsuura/reading-app/contracts/dependencies.md（表は空）
- /Users/takumamatsuura/reading-app/docs/progress.md
- docs/adr/ は空でした。

### 実行したコマンドと結果
- 開始時：`git rev-parse HEAD` は ea9fc51…、`git status --short` は空。
- Apple の DocC の JSON を curl で取り、スクラッチパッドのスクリプトで本文を出しました（リポジトリの外。/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/tools/docc.py と /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/tools/ctx.py）。分かったこと：
  - ContinuousClock と SuspendingClock の説明（上に引いたとおり）
  - systemUptime は「眠っている間を数えない」、申告が要る
  - isIdleTimerDisabled の既定は false
  - XCTApplicationLaunchMetric に `init(waitUntilResponsive:)` がある
  - XCTOSSignpostMetric に `init(subsystem:category:name:)` がある
  - accessibilityReduceMotion がある
  - ATT の概要の文
  - SwiftData の CloudKit の制約の表
  - XCUIDevice.Button は home、volumeUp、volumeDown、action、camera だけ（XCUIDevice は今は xcuiautomation の下にある）
  - 申告の理由 35F9.1、CA92.1、E174.1 の本文
- 引用符の多いコマンドが1回ガードに止められたため、回り道をせず、スクリプトをファイルに分けて実行し直しました。
- `git log --oneline ea9fc51..HEAD` は f112613 と 8f8504e（どちらも docs/reviews/ の保存）。`git diff --stat ea9fc51 HEAD -- docs/prd` は空。
- 最後の `git status --short` は出力なし（空）でした。

### 開いた URL（すべて 2026-10-15）
- https://developer.apple.com/documentation/swift/continuousclock
- https://developer.apple.com/documentation/swift/suspendingclock
- https://developer.apple.com/documentation/foundation/processinfo/systemuptime
- https://developer.apple.com/documentation/uikit/uiapplication/isidletimerdisabled
- https://developer.apple.com/documentation/xcuiautomation/xcuidevice/button
- https://developer.apple.com/documentation/xctest/xctapplicationlaunchmetric
- https://developer.apple.com/documentation/xctest/xctossignpostmetric
- https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion
- https://developer.apple.com/documentation/apptrackingtransparency
- https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons
- https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype
- https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices
- https://developer.apple.com/documentation/foundation/optimizing-your-app-s-data-for-icloud-backup
- https://developer.apple.com/app-store/app-privacy-details/
- https://developer.apple.com/app-store/review/guidelines/（10万字まで読んだ。引いた節はその中にある）
- https://support.apple.com/en-us/108770
- https://support.apple.com/en-us/108771
- https://aptabase.com/pricing
- https://firebase.google.com/pricing
- https://developer.apple.com/help/app-store-connect-analytics/benchmarks/peer-group-benchmarks/
- https://developer.apple.com/support/app-store/
- 検索だけで本文は開いていないもの：https://support.apple.com/guide/iphone/iphone-models-compatible-with-ios-26-iphe3fa5df43/26/ios/26
- 開けなかったもの：TelemetryDeck の料金（404、本文なし）、PostHog の料金（本文なし）

### 未検証
次のものが残っているので、PASS にはできません。
- A13 の機種での速さの線。G2 に実機で測り、T2 で機種を決めます。
- 再起動をまたぐ時計が申告の一覧に入るか。G1 の ADR で決めます。
- Aptabase が IP を残すか、ほかのアプリのデータと合わせるか。Firebase が送る識別子。どちらも (b) を選んだときに G1 で確かめます。
- 今あるローカルの記録が、iCloud の同期を入れたときに上がるか。Q3 で (b) を選ぶときに確かめます。
- iOS 26 の対応機種（検索の要約だけで見た）。
- XCUIApplication の terminate() と springboard のダイアログの数え方。G1 で文書を確かめます。
- 4.3(b) に "simple timers" が入った時期。
- AC-10、AC-11、AC-12 の実機での動き。G3 で確かめます。

### git status --short
（出力なし）

### 記録（判定役が書いたもの）
- 関門：G0
- 判定した役：tech-lead（その1：実現性、非機能、費用、プライバシー）
- 回：r1
- 対象：docs/prd/001-reading-session.md（feat/001-reading-session、BASE ea9fc51。HEAD 8f8504e でも PRD は同じ）
- 日付：2026-10-15
- メモ：docs/reviews/001-reading-session-G0-tech-lead-r1.md には、すでに その2 が保存されています。別の名前で保存してください。（指揮役の注：1つの役の1回分として、同じファイルに続けて保存した）

## 記録（指揮役が保存するときに書き足す）
- 関門：G0
- 判定した役：tech-lead（2体に分けた。その1 と その2。model は役割ファイルの opus。作り手の pdm も今回は fable が使えず opus で動いたため、別のモデルの判定役はこの回に入っていない）
- 回：r1（1体目は手数の上限で報告なし。範囲を分けて呼び直したものを r1 とする）
- 対象：docs/prd/001-reading-session.md、docs/prd/product.md（ブランチ feat/001-reading-session、BASE=ea9fc51fd31ed7fe73357e4f2b5523a8dcded7d1。判定中に HEAD は f112613、8f8504e に進んだが、どちらも docs/reviews/ の保存だけで PRD は同じ）
- 日付：2026-10-15
- 全体の判定：FAIL（その1 FAIL、その2 FAIL）
