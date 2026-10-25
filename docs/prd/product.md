# アプリ全体：よむとき（仮）

- 状態：G0 で判定済み（2026-10-21。docs/approvals/001-reading-session-G0.md）。機能ごとの PRD で変わるときに直す
- 書いた役：pdm　日付：2026-10-21　調べた日：2026-10-21
- 出発点：.claude/org/app.json の idea「読む時間そのものが美しくなる、デザイン賞を狙う読書アプリ」。Takuma の指標は「稼ぐこと」と「Red Dot 賞」（docs/approvals/000-takuma-standing-approval.md）。idea は出発点として扱い、4 で別の形と比べた。

根拠の印：［実データ］［公開情報 URL］［推測］。
調べ方の注記：この環境からは App Store（apps.apple.com、itunes.apple.com）、red-dot.org、web.archive.org、レビューの第三者サイト、telemetrydeck.com を開けない（プロキシが接続を拒む。docs/reviews/001-reading-session-G0-ruling.md）。開けるのは developer.apple.com で、開いたものは「（開いて確認）」と書く。「（抜粋。ページは開いていない）」は WebSearch の結果の抜粋で見ただけで、それだけで結論を立てない。競合の不満の引用は、裁定に従ってすべて［推測］に下げた。接続が許されたら G1 の間に tech-lead が確かめ、G5 の前までに必ず確かめる（裁定の3）。

## 1. 対象の層
- 中心：本が好きだった、または読みたい本があるのに、スマホに時間を取られて「最近読めていない」と感じている社会人。紙の本と電子書籍の両方を読む人。
- 根拠：1か月に本を1冊も読まない人は 62.6%（2018年度は 47.3%）（文化庁 令和5年度 国語に関する世論調査、16歳以上、有効回収 3,559人）［公開情報（抜粋。ページは開いていない） https://www.nippon.com/ja/japan-data/h02135/ 、https://webtan.impress.co.jp/n/2024/09/20/47773 。数字は pdm と tech-lead の別々の検索の抜粋で一致］。読書量が減った理由に「携帯電話、スマートフォンなどで時間が取られる」が主に挙がる［推測（抜粋。ページは開いていない） https://jounan-j.saitama-city.ed.jp/files/59315/353352375.pdf 、二次資料］。r1 に書いた「69.1%」と「43.6%」は、r2 の検索の抜粋で見つからず消した。
- 年代を20〜40代に絞るのは［推測］（調査の年代別の数字は見ていない）。
- 対象にしない層：蔵書の管理や読書 SNS が目的の人。読書メーターやブクログが無料で応えている［公開情報（抜粋。ページは開いていない） https://apps.apple.com/jp/app/id509979590 ］。

## 2. 中心の Job
- 本を読みたいのにスマホに時間を取られがちなとき、本と向き合う時間をつくって続けたい。そうすれば、読書を自分の暮らしに取り戻せる。
- 機能の面：読む時間を始めやすく、途切れにくく、残しやすくする。
- 気持ちの面：「読めていない」後ろめたさを、「今週も読めた」という手応えに変える。
- 人の目の面：読書をする自分を静かに確かめ、ときどき人にも見せたい。

## 3. 対象のストアの国と言語
- 国：JP（主）、US（従）。言語：ja、en。
- 理由：1 の根拠が日本の調査で、Takuma の指示が日本語［推測］。Red Dot は国際の審査なので英語の画面と文言が要る［推測］。

## 4. 検討した形（読書アプリの土俵の中で、2つの指標に効くもの）
| 案 | 中身 | 稼ぐ | Red Dot | いちばんの不安 | 判定 |
|---|---|---|---|---|---|
| A 読む時間の道具 | 読む時間を始め、スマホから離れ、残し、形にする | 中：同じ Job の Bookly が US で約6万件の評価、年額 $29.99 で成り立っている［公開情報（抜粋。ページは開いていない） https://apps.appfollow.io/ios/bookly-book-tracker/1085047737?country=us ］ | 高：画面が少なく、体験の質で見せられる［推測］ | 「ただのタイマー」と見なされる。審査 4.3(b) は simple timers を名指ししている［公開情報 https://developer.apple.com/app-store/review/guidelines/ （開いて確認）］ | 推奨 |
| B 本棚と蔵書の管理 | ISBN で本を登録し、本棚と感想を残す | 低：読書メーター、ブクログが無料［公開情報（抜粋。ページは開いていない） https://apps.apple.com/jp/app/id509979590 、https://apps.apple.com/jp/app/id359066582 ］ | 中［推測］ | 書誌 API への依存。openBD の v1 は提供終了を発表［公開情報（抜粋。ページは開いていない） https://current.ndl.go.jp/car/185804 ］ | 捨てる |
| C 青空文庫の縦書きリーダー | 著作権の切れた作品を美しく組んで読む | 低：本文が無料で、新しい本は読めない［推測］ | 高：組版で見せられる［推測］ | 同じ作品を無料で読める場所が多い［推測］ | 捨てる |
| D 一文を集める | 心に残った一文を写真から文字にして集める | 中［推測］ | 中［推測］ | 使う人が限られる［推測］ | A の 004 として取り込む |

推奨は A［推測］。中心の Job（スマホに時間を取られて読めない。1 の根拠は抜粋だけ）に直接効き、紙でも電子書籍でも使え、外部 API と権限なしで端末の中で完結でき（001 の AC-21）、画面の少なさをデザインの見せ場にできる。A を選ぶ根拠は抜粋と推測が中心なので、作る前に確かめる線を置いた：Takuma の実機の7日（001 の 14）と、週の読書者数（13）。いちばん強い反論は「スマホを別の部屋に置けば0円で済む」こと（5 の代替）。それでも作るのは、記録と続きのページが残らない代替では「続けたい」に応えられないため［推測］。

## 5. 競合と代替
「強み」の列は、同じ行の URL の説明文の抜粋による［公開情報（抜粋。ページは開いていない）］。不満の列の引用は、どれもページを開いて確かめていない［推測］。

| 名前 | URL | 評価の数 | 価格と課金の形 | 強み | 繰り返し出る不満（引用と URL） |
|---|---|---|---|---|---|
| Bookly | https://apps.apple.com/us/app/bookly-book-tracker/id1085047737 | US 約6.1万件・平均4.6［公開情報（抜粋。ページは開いていない） https://apps.appfollow.io/ios/bookly-book-tracker/1085047737?country=us ］。別の出典は3.8万件［公開情報（抜粋。ページは開いていない） https://adapty.io/paywall-library/bookly/ ］ | 無料＋Pro。月 $4.99、6か月 $19.99、年 $29.99、7日の試用（US）［公開情報（抜粋。ページは開いていない） 上の appfollow］。無料は10冊まで［公開情報（抜粋。ページは開いていない） https://makeheadway.com/blog/bookly-app-review/ 。tech-lead r1 の検索では bookriot などの抜粋とも合う］ | 1タップのタイマー、環境音、統計 | 「Full-page ads are ridiculous, especially when the user just wants to add a book.」「$30 a year for an app is pretty steep」（抜粋。ページは開いていない）［推測 https://apps.apple.com/us/app/bookly-book-tracker/id1085047737?see-all=reviews 。tech-lead r1 の検索では、この2文は justuseapp のページの抜粋に出た］。r1 の「The free version is basically just a demo」は、tech-lead r1 の検索で見つからず外した |
| Bookmory | https://apps.apple.com/jp/app/id1515533482 | US 2.4K件・4.8［公開情報（抜粋。ページは開いていない） https://apps.apple.com/US/app/id1515533482 ］ | 無料＋Premium。月 $3.49、年 $30.99［公開情報（抜粋。ページは開いていない） https://makeheadway.com/blog/bookmory-review/ ］ | タイマー、ロック画面と Dynamic Island の表示、読了の予測 | 不満の記録なし。r1 の引用（「課金圧が強い」「ページ数を入れないと読めない」「入力に手間が掛かりすぎる」「設定した時間になっても音が鳴らない」）は、どのページの文かを確かめられず、tech-lead r1 の検索でも見つからなかったので外した。接続が許されたら https://applion.jp/Bookmory/iphone-1515533482/ で確かめる |
| 読書メーター | https://apps.apple.com/jp/app/id509979590 | 見ていない | 無料（提供は BOOKWALKER）［公開情報（抜粋。ページは開いていない） 同じ行の URL］ | 読んだ本の登録、読書量のグラフ、バーコードの連続読み取り | 「アプリはWeb版に比べて機能が限定的で使いづらさもあります」（紹介記事の文で、利用者のレビューではない。抜粋。ページは開いていない）［推測 https://app-liv.jp/9688/ ］ |
| Forest | https://apps.apple.com/jp/app/id866450515 | 見ていない | iOS は買い切り $3.99［公開情報（抜粋。ページは開いていない） https://toolradar.com/tools/forest/pricing ］ | 集中した時間を木の育ちで見せる | 更新の後に育てた木や購入が消えた、許可するアプリの設定が難しい（抜粋。ページは開いていない）［推測 https://appmatch.jp/866450515-2/ ］ |
| 伏せると始まるタイマー（Focus Flip ほか） | https://apps.apple.com/us/app/-/id6756534301 | 見ていない | 無料＋課金［公開情報（抜粋。ページは開いていない） 同じ行の URL］ | 置くだけで始まる。同じ仕組みのアプリが5件以上ある（抜粋。ページは開いていない）［推測 https://apps.apple.com/us/app/focusdown/id6755708778 、https://apps.apple.com/us/app/flipocus/id6759856814 、https://apps.apple.com/us/app/-/id6756480514 ］ | 「the timer stops when the app is moved to the background or the screen turns off」（同じ型の FLIP の、AI によるレビューの要約。レビューそのものではない。抜粋。ページは開いていない）［推測 https://marlvel.ai/apps/flip-focus-timer-for-study/reviews ］ |
| Apple ブックの読書目標（標準） | https://support.apple.com/en-me/guide/iphone/iph6013e96f4/ios | なし | 無料 | 既定で1日5分の目標と、連続日数 | 不満の記録なし。数えるのはブック App で読んだ時間［公開情報（抜粋。ページは開いていない） 同じ URL］。紙の本を数えないかは見ていない |
| アプリ以外：紙の読書ノートと時計 | なし | なし | ノート代 | 書くこと自体が楽しい［推測］ | 毎回、日付、始めと終わりの時刻、ページの4つを手で書く［推測］ |
| アプリ以外：スマホを別の部屋に置く、何もしない | なし | なし | 0円 | いちばん安い | 記録も続きのページも残らない［推測］。「スマホがそばにあるだけで頭が鈍る」研究（Ward ほか 2017）は追試で再現されていない［公開情報（抜粋。ページは開いていない） https://www.bps.org.uk/research-digest/revisiting-brain-drain-effect ］ので、この製品の根拠にしない |

繰り返し出る不満の候補（すべて［推測］。抜粋で見ただけで、ページは開いていない。順位は付けず、結論の支えにしない）：
1. 広告と課金の圧：Bookly の2文。ブクログも広告を消すのは有料プラン（抜粋。ページは開いていない）［推測 https://apps.apple.com/jp/app/id359066582 ］。
2. 入力の手間：紙のノートの欄の数から［推測］。Bookmory の引用は外したので、アプリでは2件に届かない。
3. 記録とタイマーへの不信：Forest のデータが消えた件、伏せるタイマーが裏で止まる件、Bookly の Android 版で「the timer stops 5—10 minutes into the reading session」（抜粋。ページは開いていない）［推測 https://justuseapp.com/en/app/1085047737/bookly-track-books-stats/problems ］。

## 6. 位置づけ
スマホに読書の時間を取られている人のための、広告も登録もない「読む時間」の道具。

上位3件との違い（審査 4.3(b) のため）。違いは自分の側の事実（001 の AC と 8 の課金の形）で言い、確かめていない競合の欠点としては言わない：
- Bookly とは：開始は1回の操作（001 の AC-5）、記録の入力はページ1つで飛ばせる（AC-9、AC-10）、冊数の制限と広告を置かない（AC-22）。課金は買い切り1回（8）。Bookly の広告と10冊の上限は抜粋で見ただけ［推測］。
- Bookmory とは：本棚の管理を持たず、読む時間とページだけを残す。必須の入力は題名1つ（AC-2）。Bookmory の入力の項目数は開いて確かめていない［推測］。
- Forest や伏せるタイマーとは：時間を本に結び付けて、続きのページと積み重ねを残す（AC-9、AC-14）。002 でスマホを使わずに読み続けられる仕組みを足す。
- 引き算の違いが多く、4.3(b) の「meaningfully different」を示す力は弱い［推測］。001 を単独で出さず、G5 の前に審査メモへ 002 と 003 の違いを書く（001 の 17）。

## 7. North Star と入力指標
- North Star：週の読書者数。その週（端末の暦の週）に、アプリで合計60分以上の読書を記録した利用者の数。
  - 理由：「本と向き合う時間を取り戻せた」が利用者の受け取る価値で、売上より先に動く［推測］。60分は30分の読書2回分［推測］。
- 入力指標：
  - I-1 初日の読書：新規利用者のうち、初めて開いてから24時間以内に5分以上の読書を1回終えた割合（001 が動かす）
  - I-2 週の読書回数：その週に1回以上読書を終えた利用者1人あたりの、終えた読書の回数（001、004）
  - I-3 引き戻されなかった読書の割合：読書中に他のアプリを開かずに終えた読書の割合（002）。このままでは測れない：Screen Time の利用の報告の拡張は、通信も、データを拡張の外に出すこともできない［公開情報 https://developer.apple.com/documentation/deviceactivity/deviceactivityreport （開いて確認）］。アプリにわかるのは、読書中に background になったことだけ（tech-lead r1）。002 の PRD で、測れる近い値（読書中に background にならなかった読書の割合）に定義し直す。
  - I-4 読み終えた本の割合：1回以上読んだ本のうち、90日以内に最後のページまで記録された本の割合（003）
- 事業の指標（North Star とは別に見る）：35日以内の購入率（App Store Connect の Day 35 Download to Paid Conversion）と売上（Proceeds）［公開情報 https://developer.apple.com/help/app-store-connect-analytics/benchmarks/peer-group-benchmarks/ （開いて確認。公開ページに数値はない）］。
- 測り方：App Store Connect の利用の数字は、共有に同意した人の分だけで、同意の割合が27%の例がある［公開情報 https://developer.apple.com/forums/thread/735513 （開いて確認）］。North Star と入力指標は、題名を送らない匿名のイベントで測る（11 と、001 の PRD の 15）。

## 8. 収益化の方針
同じカテゴリの相場（円の価格は見ていない）：
| アプリ | 形 | 価格（US） | 出典 |
|---|---|---|---|
| Bookly | サブスク | 月 $4.99、6か月 $19.99、年 $29.99 | ［公開情報（抜粋。ページは開いていない） https://apps.appfollow.io/ios/bookly-book-tracker/1085047737?country=us ］ |
| Bookmory | サブスク | 月 $3.49、年 $30.99 | ［公開情報（抜粋。ページは開いていない） https://makeheadway.com/blog/bookmory-review/ ］ |
| Forest | 買い切り | $3.99 | ［公開情報（抜粋。ページは開いていない） https://toolradar.com/tools/forest/pricing ］ |
| 読書メーター | 無料と広告 | 0 | ［公開情報（抜粋。ページは開いていない） https://apps.apple.com/jp/app/id509979590 ］ |

買い切りとサブスクの比較：
| 観点 | 買い切り（非消耗型の Pro） | サブスク（年額） |
|---|---|---|
| 1人あたりの売上 | 1回だけ | 続く限り毎年 |
| 競合の不満との関係 | 広告と課金の圧への不満（5 の候補。抜粋だけで［推測］）の逆を言える［推測］ | Bookly の「$30 a year ... steep」（抜粋。ページは開いていない）［推測］と同じ土俵 |
| 審査 | 特になし | 3.1.2(a) で「ongoing value」が要る［公開情報 https://developer.apple.com/app-store/review/guidelines/ （開いて確認）］。サーバーのない端末内のアプリでは示しにくい［推測］ |
| 運営の費用 | サーバーがなく、毎月の費用はほぼ0［推測］ | 同じ |
| 相場の数字 | 日本と韓国の DL から課金への転換は2%強（2024年版）［公開情報（抜粋。ページは開いていない） https://www.revenuecat.com/state-of-subscription-apps-2024 ］ | 健康とフィットネスでは年額が売上の60.6%（2026年版の要約）［公開情報（抜粋。ページは開いていない） https://chuvak-pavel.medium.com/state-of-app-monetization-2026-key-trends-from-revenuecat-and-adapty-8bdc23a4bb6f ］ |

推奨：
- 無料：読む時間の記録（001）と、スマホを置いて読む基本（002 のうち権限の要らない部分）。冊数も回数も制限せず、広告も出さない。001 の機能は永久に無料にする。
- 有料：「Pro」を買い切り ¥2,000／US$12.99（非消耗型）。中身は 003 の形に残す表現と画像の書き出し、002 のアプリを止める機能、004 の一文の保存。Bookly の年額の約4割［推測：根拠は相場との比較だけ］。v1.0 から売る。002 のアプリを止める機能が v1.0 に入らないときは 13 の行に従う。
- 手数料：Small Business Program で15%［公開情報 https://developer.apple.com/app-store/small-business-program/ （開いて確認）］。
- 見直し：v1.0 公開の90日後（2027-05-01）に、35日以内の購入率が1.0%未満なら、年額サブスクを足す案か値下げの案を Takuma に出す（13）。
- 試算［推測］：公開から半年で1万 DL × 購入率2% × ¥2,000 × 0.85 = 約34万円。Red Dot を受賞したときの費用（約 €2,450＋VAT、9）とほぼ同じ額。賞は売上を生むより費用がかかる側なので、受賞をストアの掲載文とスクリーンショットに使って転換率を上げる宣伝の資産として扱う。

## 9. Red Dot への道筋
確認日：2026-10-21。red-dot.org は開けず、以下はすべて WebSearch の抜粋（ページは開いていない）。2027年の公式の要項が出たら、G5 の前に pdm が開き直して確かめる。
- 応募先：Red Dot Award: Brands & Communication Design（BCD）。デジタルの区分に「Apps」と「Interface & User Experience Design」が別々にある（全18区分）［公開情報（抜粋。ページは開いていない） https://www.red-dot.org/bcd ］。CleanMy®Phone は2024年に両方の区分で受賞［公開情報（抜粋。ページは開いていない） https://macpaw.com/news/cleanmyphone-wins-design-awards ］。
- 推奨の区分：Apps に1件。アプリ全体（見た目、文言、体験）を1件で見せられる［推測］。Interface & User Experience Design は対話の使いやすさが中心と読める［公開情報（抜粋。ページは開いていない） https://www.red-dot.org/magazine/communication-design-at-the-highest-level-awarded-interface-user-experience-design ］。2件出すと応募料も、受賞したときの費用も2倍になる。
- 応募条件（2026年の回、公式 FAQ の抜粋）：2023-07-01 より後に公開されたか、2026-07-01 より前に公開される予定で、過去に応募していない作品。応募のためだけに作った作品は対象外［公開情報（抜粋。ページは開いていない） https://www.red-dot.org/bcd/faq ］。2027年の回は1年ずれて「2024-07-01〜2027-07-01」と見込む［推測］。
- 公開済みであることが要るか：文言の上では「公開の予定」でも出せる。ただし「応募のためだけ」と見なされないよう、App Store で一般に売っている製品として出す［推測］。だから v1.0 を応募の前に公開する。
- 締切（2027年。第三者のまとめで、公式は未発表）：Early Bird 2027-02-12、Regular 2027-04-23、Latecomer 2027-05-07［公開情報（抜粋。ページは開いていない） https://award-service.net/en/award-deadlines ］。
- 応募料（2026年の回、1件あたり、税抜き）：Early Bird（1/26〜2/13）€250、Regular（2/14〜4/24）€330、Latecomer（4/25〜5/8）€470［公開情報（抜粋。ページは開いていない） https://www.red-dot.org/bcd/termine-kosten ］。
- 受賞したときの費用：Winner Package の購入が必須。Red Dot は Regular €2,200〜、Bold €3,000〜（税抜き）。オンラインの受賞者ページは追加で €950［公開情報（抜粋。ページは開いていない） https://www.red-dot.org/bcd/termine-kosten ］。2025年の資料では €2,100［公開情報（抜粋。ページは開いていない） https://www.red-dot.org/fileadmin/downloads/Downloadmaterial_BCD_2025/Cost-benefit_overview_BCD_EN.pdf ］。
- 結果：2026年の回の授賞式は 2026-11-06（Berlin）［公開情報（抜粋。ページは開いていない） https://www.flandersdistrictofcreativity.be/kalender/red-dot-award-brands-communication-design-2026 ］。2027年の発表日は見ていない。
- 段取り：
  1. 2027-01-31 までに v1.0（001〜003 と Pro）を JP と US で公開する。
  2. 2027-02-01 に判定する。design-reviewer の採点が16点中14点以上で、クラッシュしない割合が99.5%以上なら Early Bird（2027-02-12 まで）に1件出す。満たさなければ直して Regular（2027-04-23 まで）に出す。
  3. 応募の登録と支払いは Takuma が行う（課金の操作は Takuma だけ）。応募の画像と動画は designer と verifier が用意する。必要な形式は見ていないので、2027年の要項（Guide to Success）が出たら確かめる。
  4. 受賞したら Regular の Winner Package まで払う。それより上の段（Bold など）が必要になったら、そのときに Takuma が決める（001 の 18 の P-5。上限 €2,700＋VAT）。

## 10. 機能の並び
| # | 機能名 | Job（1つ） | 動かす入力指標 | 時間の枠 | v1.0 |
|---|---|---|---|---|---|
| 001 | reading-session | 本を開いて読み始めるとき、読んだ時間と進んだページを手間なく残したい。そうすれば、次は前回のページから読み始められ、どれだけ読めているかを確かめられる。 | I-1 | 3週 | 入れる |
| 002 | phone-away | 読んでいる途中でスマホに手が伸びそうなとき、他のアプリや通知に引き戻されずに本へ戻りたい。そうすれば、まとまった時間を本に使える。 | I-3（002 の PRD で測れる値に定義し直す。7） | 2週 | 入れる |
| 003 | reading-trace | 1冊を読み終えたとき、その本と過ごした時間を美しい形で残したい。そうすれば、読書を自分の積み重ねとして見返せ、人にも見せられる。 | I-4、購入率 | 3週 | 入れる（Pro もここで入れる） |
| 004 | keep-a-line | 読んでいて心に残る一文に出会ったとき、読む流れを止めずにその一文を残したい。そうすれば、後で読み返して思い出せる。 | I-2 | 2週 | v1.1 |

- 001 が最小の縦切り：本を1冊入れ、読み始め、終えてページを入れ、記録を見て、次は続きから始める。ここまでを端末の中だけで最初から最後まで使える。
- 001 の時間の枠は r1 の2週から3週にした。iOS のビルドとテストが CI でしか回らず、AC を境界とエラーまで値で決めたため（001 の冒頭）。3週でも 001〜003 は 2026-12-16 ごろに終わる見込みで、v1.0 の 2027-01-31 に間に合う［推測］。
- 001 だけでは App Store に出さない。単独では 4.3(b) の simple timers に当たるおそれがある［公開情報 https://developer.apple.com/app-store/review/guidelines/ （開いて確認）、当たるかの判断は推測］。
- 002 のアプリを止める機能には Family Controls の配布の許可が要る。Account Holder が申請し、Apple が審査して承認する。Screen Time の拡張（Device Activity Monitor、Shield Configuration ほか）にも同じ申請が要る［公開情報 https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement （開いて確認）］。承認までの日数は書かれていない。承認されないときは 13 の行に従う。

RICE（Reach は四半期の人数。新規を四半期3,000人と仮定［推測］。Effort の代わりに時間の枠で割る）：
| 機能 | Reach | Impact | Confidence | 時間の枠 | 点 | メモ |
|---|---|---|---|---|---|---|
| 001 | 3,000 | 3 | 80% | 3週 | 2,400 | ほかの機能の土台 |
| 002 | 2,100（7割が読書中にスマホに触る［推測］） | 2 | 50% | 2週 | 1,050 | アプリを止める機能は Family Controls の配布の許可が要る（上）。2026-12-15 の判定は 13 |
| 003 | 1,200（4割が四半期に1冊読み終える［推測］） | 2 | 50% | 3週 | 400 | 点は低いが、Pro の中身で Red Dot の見せ場。点だけで外さない |
| 004 | 900 | 1 | 50% | 2週 | 225 | v1.1 に回す |

並びから外したもの：本棚と ISBN の登録（案 B。無料の強い競合がある）、読書 SNS（中心の Job の「スマホに引き戻されない」と逆向き［推測］）、連続日数と目標（読めない日の罪悪感を生む［推測］）。

## 11. 外部サービスを使うかの比較（利用者1,000人あたりの月額）
| 用途 | 使う案 | 費用 | 使わない案 | 推奨 |
|---|---|---|---|---|
| 書誌データ（題名、著者、表紙） | Google Books API（既定の無料枠は1日1,000回と言われる［公開情報（抜粋。ページは開いていない） https://www.drupal.org/node/1925058 ］）。openBD（v1 は終了を発表、代わりの API は範囲が変わる［公開情報（抜粋。ページは開いていない） https://current.ndl.go.jp/car/185804 ］）。国立国会図書館サーチ（利用条件は見ていない） | 1人が月5回探すと月5,000回、1日約170回で、無料枠の中なら0円［推測］。枠の引き上げは保証されない［公開情報（抜粋。ページは開いていない） https://discuss.google.dev/t/requesting-higher-quota-for-google-books-api-bookquest-app/286093 ］ | 題名を手で1つ入れる。表紙は 003 で自分で撮る | 使わない（001〜004）。入力1つで足り、依存とカメラの権限が増えない |
| バーコード | カメラで ISBN を読む（書誌 API と組で使う） | 上と同じ | 上と同じ | 使わない |
| 計測 | TelemetryDeck（匿名をうたう。既存の無料枠は月10万イベント［公開情報（抜粋。ページは開いていない） https://telemetrydeck.com/blog/pricing-update-2026/ ］） | 1人が月約25〜30イベントで、1,000人なら月3万件。SDK が自動で送る分を足すと月6万件まで（tech-lead r1）。2026年7月の改定後の、新しいアカウントの無料枠は見ていない（001 の 18 の P-13） | App Store Connect だけ（同意した人の分だけで、独自のイベントはない） | 使う。North Star と撤退基準を測るため。プライバシー表示の区分と端末 ID の扱いは tech-lead が G1 で確かめる |

- 計測の代わりの案：G1 までに無料枠と端末 ID の扱いを確かめられなければ、001 は送り先の差し替え口だけを持ち、第三者の SDK は入れない（イベントは端末の中で数えるだけ）。SDK の採用は 003 で決め直す。

## 12. アプリ名、サブタイトル、キーワードの案
| | 日本語（JP） | 英語（US） |
|---|---|---|
| 名前（30字以内） | よむとき（4字） | Yomutoki: Reading Time（22字） |
| サブタイトル（30字以内） | スマホを置いて、本と過ごす時間を記録（18字） | Phone down, quiet reading log（29字） |
| キーワード（100バイト以内） | 読書,タイマー,習慣,ページ,読了,積読,集中,しおり,読書ノート,紙の本（93バイト） | tracker,habit,pages,focus,journal,minutes,library,novel,bookmark,progress,calm（78バイト） |

- 英語のサブタイトルは r1 の「Quiet reading timer & book log」から変えた。4.3(b) が名指しする「simple timers」の「timer」を前に出さないため（tech-lead r1 の提案）。
- 別案：「余白（Yohaku）」「しおりの時間（Shiori Time）」。
- 同じ名前のアプリがないかは見ていない（App Store を開けない）。App Store Connect で名前を登録するときに確かめる。
- キーワードに、競合のアプリ名、商標、「app」、カテゴリ名を入れていない［公開情報 2.3.7 https://developer.apple.com/app-store/review/guidelines/ （開いて確認）］。

## 13. アプリ全体の見直しの線
| 状態（指標と数値） | 判定日 | 取る行動 | 判定する役 |
|---|---|---|---|
| 週の読書者数が100人未満 | 2027-04-30（v1.0 公開の約90日後） | 案 A を続けるか、案 C か D に形を変えるかの案を Takuma に出す | 指揮役 |
| 35日以内の購入率が1.0%未満 | 2027-05-01 | 年額サブスクを足す案か、値下げの案を Takuma に出す | 指揮役 |
| v1.0 が 2027-04-23 までに公開できていない | 2027-04-23 | 2027年の Red Dot を見送り、2028年に出す案を Takuma に出す | 指揮役 |
| Family Controls の配布の許可が承認されていない | 2026-12-15 | v1.0 はアプリを止める機能なしで出し、Pro の中身を 003 と 004 で組み直す | 指揮役 |

## 14. Takuma に決めてほしいこと
docs/prd/001-reading-session.md の 18 に、001 の問いと一緒にまとめた（アプリ全体の問いは P- の行。P-9〜P-13 は tech-lead r1 の質問から足した）。
