（指揮役の注）これは判定ではなく、方向の見直しのための調べもの（pdm）の報告。担当は、指揮役が出した①〜④以外で、海外で育ち日本で弱い読書の分野を広く探すこと。報告の文はそのまま保存した。

# 読書アプリの方向の調べもの その3（海外で育ち、日本で弱い分野）

- 調べた日：2026-10-16（JST）。評価の数と順位は、その日の App Store の値です。値は lookup API、検索 API、カテゴリ「ブック」（genre=6018）の順位 RSS から取りました。
- 範囲：①〜④（スマホ時間を減らす、Readwise 型、Speechify 型、Read Along 型）は外しました。重なる所は分野ごとに書きました。
- 順位の出典（以下 R1〜R4 と書きます）
  - R1 US 無料：https://itunes.apple.com/us/rss/topfreeapplications/limit=60/genre=6018/json
  - R2 US セールス：https://itunes.apple.com/us/rss/topgrossingapplications/limit=60/genre=6018/json
  - R3 JP 無料：https://itunes.apple.com/jp/rss/topfreeapplications/limit=60/genre=6018/json
  - R4 JP セールス：https://itunes.apple.com/jp/rss/topgrossingapplications/limit=60/genre=6018/json
- 評価の数の出典：各アプリの製品ページの URL（下に書きます）と、lookup API（`https://itunes.apple.com/lookup?id=<ID>&country=<us|jp|kr>`）。
- 「検索の要約」と書いた数字は、WebSearch の要約で読んだだけで、元のページは開いていません。

## 0. 全体の見取り図と、前提への反論
- **US のブック無料上位60に入っているもの**［公開情報 R1］
  - 図書館：Libby 2位、Hoopla 5位、cloudLibrary 27位
  - 本の会：Fable 12位
  - 聖書のフィード：Scroll The Bible 4位
  - 記録：Goodreads 6位、Bookly 19位、StoryGraph 32位、SlowRead 44位、Shelfy 51位
- **JP のブック無料上位60**は、ほぼマンガと Web 小説です［公開情報 R3］。
  - 読書の道具はネコノホンシツジ（30位）、ブクログ（36位）、ビブリア（49位）、本コレ（50位）だけです。
  - 図書館、本の会、名作を毎日少しずつ読むアプリは入っていません。
- **前提への反論**：「海外で伸びた分野なら日本で売れる」とは限りません。
  - 海外の記録アプリは、JP のストアにあっても伸びていません。Goodreads は JP で評価1,450、StoryGraph は10、Fable は51 で、Fable と StoryGraph は英語だけです。一方、日本のブクログは28,252 です［公開情報 lookup］。
  - 大事なのは、日本に無い理由（言葉、文化、権利）が、こちらで越えられる種類のものかどうかです［推測］。

## 分野1：図書館とつながる読書（Libby・Hoopla 型）
1. **説明**：図書館のカードとつないで、借りる、予約する、返す日を守る、読む、を1つのアプリでする分野です。
2. **海外の代表**
   - Libby https://apps.apple.com/us/app/id1076402606
     - 公開 2016-12-12。US の評価 4,564,401（平均4.85）。無料。US 無料2位［公開情報 R1、lookup］。
   - Hoopla https://apps.apple.com/us/app/id580643740
     - 公開 2013-01-24。US の評価 1,390,826。無料。US 無料5位［公開情報 R1、lookup］。
   - cloudLibrary https://apps.apple.com/us/app/id466446054
     - US の評価 261,605。US 無料27位［公開情報 R1、lookup］。
   - 育っている手がかり：OverDrive（Libby と Sora）の電子の貸出は、2024年が7億3,950万件（前年比+17%）、2025年が8億2,000万件超（+10.9%）でした［公開情報 https://www.infodocket.com/2026/01/21/new-data-from-overdrive-libraries-break-digital-lending-records-in-2025-with-over-820-million-checkouts-and-over-1-billion-minutes-streamed/ 、https://rightstech.com/2025/01/digital-checkouts-rose-17-at-overdrive/ 。検索の要約］。
3. **日本の状況**
   - Libby は JP のストアにあり、日本語に対応しています。JP の評価は2,899です。cloudLibrary は JP で44。Hoopla は JP の lookup で0件で、日本語もありません［公開情報 lookup］。
   - 日本の図書館アプリ［公開情報 検索 API、lookup の説明文］
     - 図書館日和 https://apps.apple.com/jp/app/id402215845 ：公開 2010-11-12、評価203（平均3.95）。7,300館以上の蔵書の検索と予約、返却期限の管理ができます。
     - 図書館利用アプリ https://apps.apple.com/jp/app/id6464382249 ：公開 2023-10、評価59（平均2.31）。使える図書館は6館だけです。
     - 図書館貸出検索：評価30。図書館イズム：評価19。
   - JP の無料上位60に、図書館のアプリはありません［公開情報 R3］。
4. **日本の需要の手がかり**
   - 公共図書館は2024年に3,322館あります。貸出は年6億冊台で、減る向きです。ただし、年ごとの値の対応は確かめられませんでした［公開情報 https://www.jpic.or.jp/topics/docs/4530c486f605a77e6b66adfa463db92989c4d52d.pdf 。検索の要約］。
   - 文部科学省の社会教育調査は、国民1人あたりの貸出冊数と貸出回数が減ったとしています［公開情報 https://www.mext.go.jp/content/20230323-mxt_chousa01-000023559_1.pdf 。検索の要約］。
   - 電子図書館を入れた自治体は、2026-01-01 に611、電子図書館の数は491館です［公開情報 https://aebs.or.jp/pdf/E-library_Introduction_press_release20260128.pdf 。検索の要約］。
5. **日本で弱い理由の見立て**
   - 図書館ごとに業者の違うシステムを使っていて、アプリからつなぐ共通の入口がありません［推測］。
   - 電子の品ぞろえが少なく、紙の貸出が中心です［推測］。
6. **独自性の種**
   - (a) 返す日から逆算して「1日あと何分読めば読み切れるか」を出し、001 の読書時間とつなぐ［推測］。
   - (b) 図書館のログインは預からず、貸出レシートを撮って、返す日を端末の中で読み取る［推測］。
7. **評価**：需要4、空き4、独自性3、お金2、近さ2、iOS だけ3（点はすべて［推測］）。
   - お金が2なのは、Libby が無料で、図書館を使う人は無料を選ぶ人だからです［推測］。
   - 近さが2なのは、美しい時間というより手続きの道具だからです。
   - iOS だけが3なのは、予約や延長には図書館側のシステムが要るからです［推測］。
8. **いちばん強い反論**：図書館日和は2010年から同じことを無料で続けて、評価は203件です。日本の図書館の利用者は、アプリを求めていない可能性があります。

## 分野2：本の会（Fable・Bookclubs 型）
1. **説明**：同じ本を仲間と読み、章ごとにネタバレを分けて話す場を、アプリで持つ分野です。
2. **海外の代表**
   - Fable https://apps.apple.com/us/app/fable-track-discuss-books/id1488170618
     - 公開 2020-12-01。US の評価 81,844（平均4.77）。無料。
     - 課金は Fable Plus の月$5.99と年$49.99。本も1冊ずつ売っています（$3.99〜$14.99）。
     - 章ごとの「spoiler-free chapter rooms」があります。
     - US 無料12位、セールス34位［公開情報 製品ページを WebFetch で確認、R1、R2］。
     - 不満の例：「I hate hate hate! that my only option to remove content I'm not a fan of」（2025-12-07）［同じ製品ページ］。
   - Bookclubs https://apps.apple.com/us/app/id1485140274
     - 公開 2019-11-05。US の評価 15,063［公開情報 lookup］。
   - 育っている手がかり
     - Fable の2024年の報告では、利用者150万人、本の会は1年で220%増えました［公開情報 https://fable.co/blog/fable-2024-trend-report 。検索の要約］。
     - 2025年6月に Everand が買収し、利用者は300万人という報道があります［公開情報 https://finder.techleap.nl/news/feed/everand-acquires-fable-for-27-25m 。二次の報道で、一次の発表は見ていません］。
     - カナダでは、2020年から2023年にかけて読書会への参加が増え、18〜29歳がいちばん多く参加しています［公開情報 https://www.booknetcanada.ca/blog/2024/7/18/book-clubs-on-the-rise 。検索の要約］。
   - 中国：微信读书 は、本の中でほかの読者の考えを見られる作り（「书中讨论交流」）です。評価は US で27,776、JP で6,617。言語は中国語と英語だけです［公開情報 https://apps.apple.com/jp/app/id952059546 、lookup］。
3. **日本の状況**
   - Fable は JP で評価51（英語だけ）。Bookclubs は JP で2［公開情報 lookup］。
   - 日本語の近いアプリ［公開情報 検索 API、lookup、product.md の 4］
     - Reads https://apps.apple.com/jp/app/id6673894498 ：公開 2025-02、評価176。
     - rlog（ひとりの読書会）https://apps.apple.com/jp/app/id6759821209 ：公開 2026-03、評価2。
     - mekuru：評価360。読む気配を分け合う作りで、会話はありません。
     - 読書メーター：評価7,187。
4. **日本の需要の手がかり**
   - オシロ株式会社の集計で、2025年1月1日〜11月10日に574件のブッククラブが開かれたとされています［公開情報 https://osiro.it/news/14052 。検索の要約だけで見た数字で、WebFetch では題しか読めませんでした］。
   - 日本の読書会の参加者数の統計は見つかりませんでした。
5. **日本で弱い理由の見立て**
   - 日本の読書会は対面のイベントの文化です［推測］。
   - 感想を人と分けるのは、読書メーター、ブクログ、X で足りています［推測］。
   - Fable は英語の本の販売と一体になっています［公開情報 製品ページ］。
6. **独自性の種**
   - (a) 2〜6人だけの閉じた会を、サーバーを持たずに作る［推測。iCloud の共有で作れるかは tech-lead に確かめてもらう］。
   - (b) 自分が読んだページまでの感想しか見えない作りと、「いま一緒に開いている」気配を組み合わせる［推測］。
7. **評価**：需要2、空き4、独自性3、お金3、近さ3、iOS だけ2［推測］。
   - iOS だけが2なのは、人の書き込みを扱うと、通報やブロックの仕組みが要るからです［推測。審査の条件は確かめていません］。
8. **いちばん強い反論**：本の会は、人が集まって初めて価値が出ます。最初の利用者は空の部屋を見て離れます。

## 分野3：毎日少しずつ読む名作（Scroll The Bible・Serial Reader 型）
1. **説明**：名作や聖典を、1日数分の「回」や1節ずつの縦スクロールで届けて、なんとなくスクロールする癖を、読むことに置き換える分野です。
2. **海外の代表**
   - Scroll The Bible https://apps.apple.com/us/app/scroll-the-bible/id6756558351
     - 公開 2025-12-17。約10か月で US の評価 17,117（平均4.82）を集めました。
     - 無料で、Premium は月$4.99〜$9.99、年$5.99〜$39.99。$29.99 の項目もあります。
     - US 無料4位、セールス6位。
     - 説明文：「turns the same scrolling habit that drains your day into the one that fills it. Verse by verse.」
     - ［公開情報 製品ページを WebFetch で確認、R1、R2、lookup］
     - 不満の例（星の数は見えませんでした）：「I received an automated email stating that they couldn't refund any money」（Aug 1）、「asking me to rate the app every time I open it」（Sep 6）［同じ製品ページ］。
   - Serial Reader https://apps.apple.com/us/app/id1077180804
     - 公開 2016-01-28。US の評価 4,106。名作を毎日1回分ずつ届けます。最後の更新は 2025-05 で、伸びはゆるやかです［公開情報 lookup］。課金は見ていません。
   - 韓国：세계문학 일력 https://apps.apple.com/kr/app/id6752370745
     - 公開 2025-12-28。KR の評価104。出版社の民音社が選んだ一文を毎日、ウィジェットで届け、書き写して残します［公開情報 lookup の説明文］。
3. **日本の状況**
   - Scroll The Bible は JP で評価4、Serial Reader は30。どちらも英語だけです［公開情報 lookup］。
   - 青空文庫のアプリはあります［公開情報 検索 API、lookup］。
     - ソラリ https://apps.apple.com/jp/app/id1207167864 ：評価17,981（平均4.72）。最後の更新は 2024-10-05 です。
     - コトリ https://apps.apple.com/jp/app/id6759166859 ：公開 2026-03、評価53。縦書き、ルビ、辞書があり、気分から本を探せます。
     - 一度は読みたい、人気の名作小説集 https://apps.apple.com/jp/app/id979051152 ：評価3,831。
     - 2026年9月にも、青空文庫のアプリが2つ出ています。
   - どれも「本棚と読む画面」の形です。毎日の回や1節ずつ流れる形のアプリは、検索「青空文庫」「名作 毎日 読む」の上位6件にありませんでした（その下は見ていません）。
   - Motto https://apps.apple.com/jp/app/id6478363388 ：公開 2024-02、評価9,230。落ち着いた背景と BGM で短い言葉を毎日届けます［公開情報 lookup］。
4. **日本の需要の手がかり**
   - 読書量が減った理由の1位はスマホで、43.6%です［公開情報 https://www.nippon.com/ja/japan-data/h02135/］。
   - ソラリの17,981件は、iPhone で名作を読む人がいることを示しています。Motto の9,230件は、短い言葉を毎日受け取る習慣があることを示しています［公開情報 上の URL］。
5. **日本で弱い理由の見立て**
   - Scroll The Bible の伸びは、毎日聖書を読む習慣に支えられています。日本にはその習慣がありません［推測］。
   - 日本の名作アプリは「本を丸ごと読む」作りで、毎日の回に切っていません［推測］。
6. **独自性の種**
   - (a) 縦書きとルビの画面を「1日5分で読み切れる回」に区切り、回の終わりで止まる。どこまでも続くフィードにはしない［推測］。
   - (b) 二十四節気に合わせて名作を選ぶ。季節と日本語の見た目を賞の柱にする［推測］。
7. **評価**：需要3、空き3、独自性4、お金3、近さ5、iOS だけ5［推測］。
   - お金が3なのは、著作権の切れた聖書でも US セールス6位まで行った前例がある一方、日本で払われるかはまだ確かめていないからです。
   - iOS だけが5なのは、作品をアプリに入れれば、サーバーが要らないからです。青空文庫の取り扱い規準は確かめていません。
8. **いちばん強い反論**
   - アプリの Job が「紙の本に戻る」から「スマホで名作を読む」に変わります。
   - Scroll The Bible を支えた信仰の習慣が日本にはありません。
   - スクロールを置き換えるという動機は、①と同じです。

## 分野4：一日一文の書き写し（韓国の필사 型）
1. **説明**：本の一文を毎日手で書き写して、ゆっくり読む時間を残す分野です。
2. **海外の代表**
   - 韓国の教保文庫によると、2024年の書き写しの本の販売は前年の692.8%増え、出版の点数は57から81になりました。この記事は紙とペンの書き写しの話で、アプリには触れていません［公開情報 https://m.seoul.co.kr/news/2025/02/14/20250214022001 を WebFetch で確認、2025-02-14］。
   - アプリはまだ小さいです［公開情報 検索 API、lookup］。
     - 세계문학 일력（上の分野3）：KR の評価104。
     - 필사 https://apps.apple.com/kr/app/id6474996320 ：公開 2024-01、評価36。
     - 쓰담 https://apps.apple.com/kr/app/id6759362379 ：公開 2026-02、評価8。
   - どれも無料です。課金は見ていません。
3. **日本の状況**
   - 検索「書き写し」「写経」の上位に、本の一文を写すアプリはありませんでした。
   - 上位にあったのは、The 清書 https://apps.apple.com/jp/app/id6503187351 （公開 2024-06、評価3,167。美文字をなぞる練習）と、般若心経365（2,686）です［公開情報 検索 API］。
4. **日本の需要の手がかり**
   - 「天声人語書き写しノート」は、2011年4月の発行から2021年7月15日までに、累計500万冊を超えました（朝日新聞社）［公開情報 https://voix.jp/edu/?p=16970 を WebFetch で確認］。
5. **日本で弱い理由の見立て**
   - 日本では、書き写しは紙で足りています［推測］。
   - iPhone の画面は、指で書くには小さいです［推測］。
6. **独自性の種**
   - (a) 紙の本の一文を写真から端末の中で文字にし、縦書きの手本を出す。紙に写したら、その紙を撮って帳面に残す［推測］。
   - (b) 書き写した時間を、001 の本ごとの時間に足す［推測］。
7. **評価**：需要3、空き4、独自性4、お金3、近さ5、iOS だけ4［推測］。
8. **いちばん強い反論**：書き写しの価値は「紙に手で書く」ことにあり、アプリは要りません。韓国でも、伸びたのは紙の本です。

## 分野5：本の AI 相棒（Kindle「Ask this Book」型）
1. **説明**：いま読んでいる本について、読んだ所までの範囲で AI にたずねられる分野です。
2. **海外の代表**
   - Kindle（https://apps.apple.com/us/app/id302584613 、公開 2009-03-04、US の評価 5,872,336、US 無料3位）の iOS 版に、2025年12月、「Ask this Book」が加わりました。
     - 対象は US の英語の本、数千冊です。
     - 答えは、読んでいる位置までに限られます。著者と出版社は、この機能から外すことができません。
     - ［公開情報 https://9to5mac.com/2025/12/15/kindle-ask-this-book-ai-powered-feature-launches-in-ios-app/ 。検索の要約］
     - この機能の料金は見ていません。
   - Shelfy は、Pro の機能として「Reading companion」を持っています［公開情報 製品ページを WebFetch で確認］。
   - BeFreed は公開 2025-01、US の評価4,058、US 無料39位です［公開情報 R1、lookup］。
3. **日本の状況**
   - 「Ask this Book」は US の英語の本だけです［上の記事。JP で出ていないことは推して書いています］。
   - JP の検索「読書 AI」の上位は小さいアプリだけです。Buy Best Book（公開 2026-09、評価3）、フクドク（公開 2026-09、評価0）、MarginNote 4（138）［公開情報 検索 API］。
4. **日本の需要の手がかり**：見つかりませんでした（未確認）。
5. **日本で弱い理由の見立て**
   - 出版などの4団体が、2023年8月に、生成 AI と著作権について声明を出しています［公開情報 https://dempa-digital.com/?p=465334 。検索の要約］。
   - 本の本文を AI に渡すことに、出版社は慎重です［推測］。
6. **独自性の種**
   - (a) 自分で撮ったページと自分のメモだけを、端末の中の AI に渡す［推測］。
   - (b) 読んだ所までの人物の関係を、図にする［推測］。
7. **評価**：需要2、空き4、独自性3、お金3、近さ2、iOS だけ2［推測］。
8. **いちばん強い反論**：Amazon が日本の Kindle に出せば、一晩で埋まります。紙の本では本文が手に入りません。

## 参考（5つの外）：001 の方向そのものも、海外で伸びている
- Shelfy https://apps.apple.com/us/app/shelfy-book-tracker-tbr/id6755626127
  - 公開 2025-12-10。US の評価1,149。US 無料51位、セールス36位。
  - 機能：本棚、環境音つきの読書タイマー、写真から引用を取る機能、AI 相棒。
  - 課金：週$4.99〜年$38.99。買い切りは$99.99。
  - 不満の例：「the entire app locks down after setup unless you agree to a 3 day free trial」（Jul 2）
  - ［公開情報 製品ページを WebFetch で確認、R1、R2］
- SlowRead https://apps.apple.com/us/app/id6763293288
  - 公開 2026-07-04。US の評価730。US 無料44位。アプリを制限する読書の時間があります。日本語はありません［公開情報 R1、lookup］。
- 日本で近いのは、ネコノホンシツジ https://apps.apple.com/jp/app/id6752113848 です。公開 2025-10-16、評価275、JP 無料30位［公開情報 R3、lookup］。
- 読み方：001 の方向に需要がないとは言えません。ただ、海外の勢いのあるアプリは、①（アプリの制限）と②（引用）も束ねています。「伏せて始める」だけで並ぶのは弱いです［推測］。

## 避ける分野
1. **Web 小説とマンガの連載**（Wattpad、GoodNovel 型）
   - JP セールス1位はピッコマ（評価1,578,115）、2位は LINE マンガ。カクヨムは23,394です。GoodNovel も JP セールス6位に入っています［公開情報 R4、lookup］。
   - US で伸びている AI と話して進む物語（Y/n、Janitor）も、JP には plaitoon（JP セールス44位）とプリ小説（61,321）があり、最初の発想からも遠いです［公開情報 R2、R4、検索 API］。
2. **本の要約と AI の学び**（Blinkist、BeFreed 型）
   - フライヤー（評価2,875、JP セールス37位）と、Flashbook（公開 2026-03、JP セールス55位）があります。BeFreed は日本語にも対応しています［公開情報 R4、lookup］。
   - 「読まずに済ませる」方向で、最初の発想と逆です［推測］。
3. **読書記録の SNS**（Goodreads、StoryGraph 型）
   - ブクログ（28,252）、ビブリア（11,927）、読書メーター（7,187）が強く、ネコノホンシツジも JP 無料30位にいます［公開情報 lookup、R3］。

## 比べの表（点は［推測］）
| 分野 | 海外の伸びの手がかり | 日本の最大の相手（評価の数） | 需要 | 空き | 独自性 | お金 | 近さ | iOS だけ | 計 |
|---|---|---|---|---|---|---|---|---|---|
| 1 図書館 | Libby US 456万件、無料2位。2025年の電子の貸出 8.2億件 | 図書館日和 203 | 4 | 4 | 3 | 2 | 2 | 3 | 18 |
| 2 本の会 | Fable US 8.2万件、無料12位、セールス34位 | Reads 176 | 2 | 4 | 3 | 3 | 3 | 2 | 17 |
| 3 毎日の名作 | Scroll The Bible、10か月で1.7万件、無料4位、セールス6位 | ソラリ 17,981（2024-10から更新なし） | 3 | 3 | 4 | 3 | 5 | 5 | 23 |
| 4 書き写し | 韓国の紙の本 +692.8%。アプリは KR 104件まで | The 清書 3,167（美文字） | 3 | 4 | 4 | 3 | 5 | 4 | 23 |
| 5 AI 相棒 | Kindle の Ask this Book（2025-12、US） | MarginNote 4 138 | 2 | 4 | 3 | 3 | 2 | 2 | 16 |

## pdm として推す1つ：分野3（毎日少しずつ読む名作）。ただし「作る」ではなく「形を変える前に確かめる」
- **理由**
  - 海外で「アプリとして」伸びている証拠がいちばん強いです（Scroll The Bible は10か月で評価17,117、無料4位、セールス6位）［公開情報］。同じ点数の分野4は、伸びたのが紙の本です。
  - 著作権の切れた文章（聖書）でも、お金が払われている前例があります。青空文庫には約18,000作品があります［公開情報 コトリの説明文］。
  - 縦書き、ルビ、季節は、日本語でしか作れない見た目で、「読む時間そのものが美しくなる」に最も近いです［推測］。
  - iOS だけで作れます。分野4の書き写しは、回の終わりに「この一文を写す」として、後から足せます［推測］。
- **いちばん強い反論**
  - Job が product.md の「紙の本に戻る」から「スマホで名作を読む」に変わり、作り直しになります。
  - 日本は空いていません。ソラリ（17,981）があり、2026年には新しい青空文庫アプリが3つ出ています。
  - 代わりのアプリや手段より何がどれだけよいかを、まだ数字で言えません。
- **作らない場合**：001 は ToRead、mekuru、ネコノホンシツジ、Shelfy と同じ棚に並び、違いは「伏せる」だけのまま残ります［推測］。
- **いちばん安い確かめ方**
  - (1) ソラリとコトリの低評価のレビューを読む（今回は RSS が読めず、未確認です）。
  - (2) Takuma に、縦書きで1回5分の画面案3枚を見てもらう。
  - (3) TestFlight で、10人のうち5人以上が、7日のうち4日以上、回を読み終えることを合格の線の案にする［推測。線は G0 で決める］。

## 変更したファイル
- リポジトリの中：なし。
- 作業用のスクリプト（リポジトリの外）：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ に lk.py、sr.py、rv.py、iap.py を置きました。

## 実行したコマンドと結果
- `cat .claude/org/app.json`、`wc -l docs/prd/product.md`、`date` を実行しました。product.md は80行で、日付は 2026-10-16 09:31 JST でした。product.md は Read で読みました。
- curl で順位の RSS（R1〜R4、各60位まで）を取りました。4本とも読めました。
- curl で lookup API を引きました。US 15件、JP 25件、KR 3件で、説明文も一緒に取りました。
- curl で検索 API を引きました。JP 16語、KR 2語、US 6語です。途中で 403（呼びすぎの制限）が出たので、待ってからやり直し、「그믐」以外は読めました。「그믐」は見ていません。
- curl で RSS のレビューを取ろうとしました（図書館日和、ソラリ、Scroll The Bible、Shelfy、Fable）。JSON が返らず、読めませんでした。
- curl で apps.apple.com の製品ページを取ろうとしましたが、0バイトで読めませんでした。
- ガードが、`$` の入った書き先を止めました。書き先の名前をそのまま書いて、やり直しました。
- WebFetch で開いたページ（どれも 2026-10-16）
  - 読めたもの：nippon.com、seoul.co.kr、voix.jp、Shelfy の製品ページ、Scroll The Bible の製品ページ、Fable の製品ページ（後ろの2つは、1回目が途中で切れたので、やり直して読めました）。
  - 題しか読めなかったもの：osiro.it/news/14052。
- WebSearch で調べたこと（9回）：Kindle の Ask this Book、OverDrive の2025年、電子図書館の自治体数、필사の流行、Fable の伸び、日本の図書館の統計（2回）、天声人語書き写しノート、読書会、出版団体の生成 AI の声明。
- `git status --short` の出力は空でした（作業ツリーに変更なし）。

## 未解決
- **Takuma に決めてほしいこと**
  1. 中心の Job を「紙の本に戻る」から「スマホの数分を名作に置き換える」に変えてよいか。
     - 推奨：画面案3枚で確かめてから決める。
     - 反論：001 の G0 の積み上げを捨てることになる。
     - 元に戻せるか：戻せる（文書だけの話）。
  2. 青空文庫の作品をアプリに入れて配ってよいか（取り扱い規準と、底本や入力者の表示の確認）。
  3. 分野3は、①（スマホの時間を減らす）と Job が重なります。指揮役が、①の報告と並べて決めてほしいです。
- **実際のユーザーに聞く問いの案**（過去の行動を聞く形）
  - 最後に名作を読んだのはいつで、何で読みましたか。
  - 最後に本の一文を書き写したのはいつで、何に書きましたか。
  - 最後に図書館の本を、読み切れないまま返したのはいつですか。
- **tech-lead に確かめてほしいこと**
  - 青空文庫の作品をアプリに入れるときの量と、縦書きとルビの表示（分野3）
  - 端末の中での文字の読み取り（分野1、分野4）
  - iCloud の共有で、閉じた本の会を作れるか（分野2）
  - 端末の中の AI の、日本語の質（分野5）
- **designer に確かめてほしいこと**
  - 1回5分の縦書きの画面が、読みやすいか
  - iPhone で指で書き写すことが、成り立つか
- **確かめきれなかったこと**
  - レビューの RSS と製品ページの curl は読めませんでした。WebFetch で読めた製品ページは3つ（Shelfy、Scroll The Bible、Fable）だけです。
  - OSIRO の本文、aebs、JPIC、文部科学省の PDF、9to5mac、Fable の利用者数は、検索の要約だけで見ました。
  - Libby、Serial Reader、SlowRead、コトリ、ネコノホンシツジ、Motto の課金は見ていません。
  - 「그믐」、Beanstack、本の交換、韓国の読書の部屋（열품타）は見ていません。
  - 外国語の多読は、JP の Langaku（評価10,470）と LingQ（JP 評価1,460）を見たところで、US でも大きな伸びが見えなかったため、5つから外しました。

Sources:
- [nippon.com 文化庁 国語に関する世論調査](https://www.nippon.com/ja/japan-data/h02135/)
- [OverDrive 2025 records (infodocket)](https://www.infodocket.com/2026/01/21/new-data-from-overdrive-libraries-break-digital-lending-records-in-2025-with-over-820-million-checkouts-and-over-1-billion-minutes-streamed/)
- [OverDrive 2024 (rightstech)](https://rightstech.com/2025/01/digital-checkouts-rose-17-at-overdrive/)
- [電流協 2026-01 発表](https://aebs.or.jp/pdf/E-library_Introduction_press_release20260128.pdf)
- [JPIC 資料](https://www.jpic.or.jp/topics/docs/4530c486f605a77e6b66adfa463db92989c4d52d.pdf)
- [文部科学省 社会教育調査](https://www.mext.go.jp/content/20230323-mxt_chousa01-000023559_1.pdf)
- [Fable 2024 Trend Report](https://fable.co/blog/fable-2024-trend-report)
- [Everand acquires Fable (techleap)](https://finder.techleap.nl/news/feed/everand-acquires-fable-for-27-25m)
- [BookNet Canada book clubs](https://www.booknetcanada.ca/blog/2024/7/18/book-clubs-on-the-rise)
- [OSIRO 2025](https://osiro.it/news/14052)
- [서울신문 필사책](https://m.seoul.co.kr/news/2025/02/14/20250214022001)
- [VOIX 天声人語書き写しノート 500万冊](https://voix.jp/edu/?p=16970)
- [9to5mac Ask this Book](https://9to5mac.com/2025/12/15/kindle-ask-this-book-ai-powered-feature-launches-in-ios-app/)
- [alternativeto Ask this Book](https://alternativeto.net/news/2025/12/amazon-adds-ask-this-book-to-the-kindle-ios-app-for-interactive-and-spoiler-free-qanda)
- [電波新聞 4団体声明](https://dempa-digital.com/?p=465334)
- [Scroll The Bible](https://apps.apple.com/us/app/scroll-the-bible/id6756558351)
- [Shelfy](https://apps.apple.com/us/app/shelfy-book-tracker-tbr/id6755626127)
- [Fable](https://apps.apple.com/us/app/fable-track-discuss-books/id1488170618)

## 記録（指揮役が保存するときに書き足す）
- 種類：方向の見直しのための調べもの（pdm、①〜④以外の分野）。PASS / FAIL なし
- BASE=64d14463c31dac576a8fe585d7391815b8f0f67d
- 日付：2026-10-16
