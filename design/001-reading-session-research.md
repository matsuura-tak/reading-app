# デザイン調査 001-reading-session：読んだ時間とページを残して、続きから読む

- 対象の PRD：docs/prd/001-reading-session.md（G0 承認済み。docs/approvals/001-reading-session-G0.md）。アプリ全体は docs/prd/product.md
- 書いた役：designer　日付：2026-10-21
- この文書は仕様（design/001-reading-session.md）より先に書く。仕様の決定は、8 の R 番号を根拠に引く。
- 見られなかったもの、開けなかったページは「見ていない」と書く。推測で埋めない。
- 調べ方の注記：この環境から開けたのは developer.apple.com だけ（HIG、Apple Design Awards、開発者向けの記事、WWDC26 の動画ページ）。App Store、red-dot.org、support.apple.com、競合の公式サイト、レビューと紹介の第三者サイト、NN/g、論文のページは、プロキシが接続を拒んだ（2026-10-21 に curl で各1回、どれも CONNECT に 403。WebFetch は nngroup.com で1回試し、名前解決できずに失敗）。開いたものは「（開いて確認）」、WebSearch の抜粋で見ただけのものは「（抜粋。ページは開いていない）」と書く。抜粋だけの R は、それ1つで決定を支えない。開いて確かめた R か PRD と組にして使う。
- 競合の調べもの（評価の数、価格、不満の全文）は PRD 3 と product.md 5 にあり、やり直さない。ここで足すのは見た目と操作の比較だけ。

## 1. 問いと範囲
- この調査で決めたいこと：
  1. 誰が、どんな場面で、何秒で使うか（2 のターゲットの仮説）
  2. 見た目と文言の性格（5 の性格語と文言の調子）
  3. 業界の当たり前のどれに合わせ、どこで差をつけるか。差は Takuma の指標「Red Dot 賞」（Brands & Communication Design の Apps 区分。PRD 18 の P-4）に効き、PRD の AC と矛盾しない形にする（6）
  4. 方向性（7 の2案から1つ）と、色の量と情報の密度
- 範囲：001 の画面（ホーム、本の追加、本の詳細、読書中、終える入力、記録を消す確認）。002〜004 の画面、アプリのアイコン、ストアの画像は範囲の外（6 の Red Dot の項に、後の作業へ渡すことだけ書く）。
- 関係する受け入れ条件（AC 番号）：
  - 始め方：AC-1（空の状態）、AC-2〜AC-4（題名だけで追加し、3回以下で読書中）、AC-5、AC-25〜AC-27（前の本を1回で）、AC-17（読書中は1件だけ）
  - 読書中：AC-6〜AC-8、AC-33、AC-41（経過の表示と復元）、AC-40（VoiceOver の読み上げ）
  - 終える：AC-9〜AC-13、AC-29〜AC-32、AC-34、AC-45、AC-46（ページは1つで飛ばせる、分を直せる、やめられる）
  - 見返す：AC-14、AC-15、AC-28、AC-36、AC-37、AC-44（合計、空、進み具合）
  - 消す：AC-16、AC-38、AC-43
  - エラーと通信：AC-19、AC-35、AC-42（保存の失敗）、AC-20（計測が届かなくても画面に何も出さない）
  - 出さないもの：AC-21（権限0個）、AC-22（冊数の制限、広告、課金の画面なし）、PRD 10（連続日数と目標を出さない）
  - 文言：AC-39（ja と en）
  - 非機能：PRD 12（AX5、VoiceOver、コントラスト、ダークモード、44×44pt）

## 2. ターゲット（仮説）
人に聞いた調査ではなく、PRD と検索の抜粋から立てた仮説。PRD 18 の 4（知人5人への聞き取り）が行われたら、ここを見直す。
- 誰が：本が好きだった、または読みたい本があるのに、スマホに時間を取られて「最近読めていない」と感じている社会人（product.md 1。20〜40代は［推測］）。紙の本と電子書籍の両方を読む。読書の記録をつけたことがあっても、目標や数字に追われてやめた人も含む（R-18、R-22。どちらも抜粋）。
- 使う場面（片手か、移動中か、何秒か）：
  - S-1 寝る前（主）：ベッドや布団で、部屋の明かりを落として読む。社会人が本を読む時間は「就寝前」が46.7%で最も多いという調査の抜粋がある（R-23）。片手に本、もう片方の手でスマホを持つ。スマホを片手で持って操作する人は49%という観察の抜粋がある（R-24）。アプリを開いてから読書中になるまで3秒ほど（起動2.0秒以内は PRD 12、操作は1回で AC-5）。ダークモードで、画面の明るさを下げていることが多い［推測。HIG は Dark Mode を「low-light environments」向けとする。R-9］。
  - S-2 通勤の電車と休日（従）：同じ調査で「休日」「通勤など移動時間」が続く（R-23）。立ったまま片手で始め、スマホをしまって本を開く。読んでいる間は画面を見ない（経過は時刻から数える。AC-7）。
  - S-3 終えるとき：本にしおりを挟みながら、片手で今のページを1つ入れる。10〜20秒。急ぐときはページを飛ばして終える（AC-10）［推測］。
  - S-4 見返すとき：読む前か後に、今週の合計と本の進み具合を数十秒見る（AC-14、AC-15）［推測］。
- 起こしたい感情：落ち着き（読む前に気が散らない）、静かな手応え（「今週は60分読めた」）、安心（記録が消えない、責められない）。高揚や達成の祝いではない。
  - 根拠：HIG は起こしたい感情を決めよと言い、「a meditation app might calm」と例を挙げる（R-1）。Gentler Streak は「not by insistent reminders but an optimistic and encouraging vibe」と評されて受賞した（R-4）。連続日数が切れると意欲が下がるという研究の紹介（R-22。抜粋）と、タイマーと読了の予測で読書が締め切りのように感じたという投稿（R-18。抜粋）は、祝いと数字の圧を避ける向きに働く。
- 見た目の好み（色の量、情報の密度）と根拠（R 番号）：
  - 好みは国、性別、学歴で変わり、全員に合う色の量はない（R-25。抜粋）。だから好みの平均ではなく、使う場面と性格語から決める。
  - 色の量：少なくする。背景と文字はシステムの色にし、色はアクセント1色を主操作と状態にだけ使う。暗い所では色が明るく鮮やかに見え（R-10）、寝る前の暗い部屋で使う（S-1、R-23）ので、広い面を色で塗らない。内容が無彩色のアプリでは1色のアクセントがブランドを表せる（R-10）。
  - 情報の密度：読書中は最小（題名、経過、2つの操作）。ホームは少なめ（読み始める操作、今週の合計、本の一覧）。本の詳細は中くらい（数字4つと記録の一覧）。根拠：Crouton は作業の最中に「only the current step」を出す（R-3）。機能はどれも時間と注意と信頼を求める（R-2）。競合は多機能を前に出す（R-14、R-19）ので、密度を下げること自体が見分けになる。
- アクセシビリティで必要なこと：
  - いちばん大きい文字（AX5）で、経過時間とすべての操作が切れない（PRD 12）。HIG は200%以上の拡大と、大きくしたときの切り詰めを最小にすることを求める（R-11、R-12）。
  - VoiceOver で全操作ができ、経過は分と秒で読み、毎秒は読まない（AC-40、PRD 12）。
  - ダークモードと「コントラストを上げる」「透明度を下げる」の組み合わせで読める（R-9）。独自の色の組は 7:1 を目指す（R-9）。
  - 「視差効果を減らす」で、自動で繰り返す動きを減らす（R-11）。
  - 片手の親指で主操作に届く（S-1、R-24）。押せる範囲は 44×44pt 以上（R-11、PRD 12）。
  - 暗い部屋でも読める太さ。Ultralight、Thin、Light は使わない（R-12）。

## 3. 競合
直接の競合を3本。どれも App Store と公式サイトを開けず、アプリの画面は1枚も見ていない。表の値は WebSearch の抜粋（ページは開いていない）か PRD による。「見ていない」の欄は推測で埋めていない。

| 項目 | 競合A Bookly | 競合B Bookmory | 競合C Apple ブックの読書目標 |
|---|---|---|---|
| 名前、URL、選んだ理由 | Bookly: Book Tracker。https://apps.apple.com/us/app/bookly-book-tracker/id1085047737 と https://getbookly.com/ （どちらも開けない）。同じ Job（読む時間を測り、ページを残す）で、US の評価の数が多い（PRD 3、E-3） | Bookmory - reading tracker（韓国語の題「북모리 - 책을 기록하고 기억하는 감성 독서 노트」）。https://apps.apple.com/jp/app/id1515533482 （開けない）。日本の App Store にあるタイマー付きの記録アプリで US 4.8（PRD 3）。「すべてを1か所に」の多機能の型の代表（R-19） | ブック App の「読書目標」（標準の機能）。https://support.apple.com/en-me/guide/iphone/iph6013e96f4/ios （開けない）。iPhone に最初からあり、利用者が「読書の時間を数える」型として最初に覚える。目標と連続日数の当たり前を作っている（R-21） |
| 良い点（取り入れる考え、R 番号） | 1回で始めるタイマー「You start the timer when you want to read, and the app handles the rest.」（R-14）。画面を離れても数え続ける「The timer will keep on ticking.」（R-17）。取り入れる：1回で始める、閉じても進む（AC-5、AC-7。PRD で決まっている形と同じ） | タイマーが本のページにあり、時間が本に結び付く（R-19）。月のカレンダーで読んだ日を見せる（R-19）。取り入れる：時間を本に結び付ける（PRD 5 の S-4 を捨てた理由と同じ）。カレンダーは 001 にないので取り入れない | 設定しなくても始まる（既定で1日5分。R-21）。取り入れる：設定なしで始める（R-7 と同じ向き。AC-1、AC-4） |
| 主な作業のタップ数 | 見ていない | 見ていない（タイマーは本の詳細から使うという抜粋がある。R-19） | 見ていない |
| ナビゲーションの構成 | 見ていない | 見ていない | 新しい版は「Reading Now」タブ → 下へスワイプ → Reading Goals → Today's Reading。古い版は Home の右上のボタンから（R-21。抜粋） |
| 最初の価値までの画面数 | 見ていない。オンボーディングの途中に課金の画面（ソフトペイウォール）が出て、閉じると割引を出すという分析の抜粋がある（R-15） | 見ていない。「no tutorial」という不満の抜粋がある（R-20） | 見ていない |
| 空の状態 | 見ていない | 見ていない | 見ていない |
| 権限の求め方 | 見ていない（目標とリマインダーの機能があるので、通知の許可を求める可能性はある［推測］。R-14） | 見ていない。App Store のプライバシーの欄に、追跡に使われうる識別子と使用状況データがあるという抜粋（R-20） | 目標を達成したときと記録を更新したときに通知を出す。通知は設定で切れる（R-21。抜粋） |
| 色、文字、情報の密度 | 色と文字は見ていない。機能は多い（統計、連続日数、目標、リマインダー、蔵書、評価、環境音、実績、Readathon。R-14）。タイマーの流れで引用、考え、登場人物を足す道具を出す（R-15）。密度は高いと見る［推測］ | 色と文字は見ていない。テーマは有料（R-19）。題の「감성」（感性。情緒的な雰囲気を指す語）から、情緒的な見た目を売りにしている［推測］。記録、日記、タイマー、目標、カレンダー、写真の文字の読み取りがあり、密度は高いと見る［推測］ | 見ていない |
| 文言の調子 | サイトの題「Stay Motivated and Reach Your Reading Goals with Bookly」（R-14）。目標と動機づけを前に出す、熱っぽい側［推測］ | 「It's a reading log, reading journal, reading timer, and reading goal app — all in one place.」（R-19）。多機能を前に出す | 達成を知らせ「send your achievement to friends」（R-21）。祝う、熱っぽい側 |
| App Store の評価 | US 約6.1万件・4.6（PRD 3 の抜粋。ページは開いていない） | US 2.4K件・4.8（PRD 3 の抜粋。ページは開いていない） | 見ていない（標準のアプリ） |
| 悪い点（レビューの不満の上位3つ、R 番号） | 順位は付けない。(1)「Full-page ads are ridiculous, especially when the user just wants to add a book.」(2)「$30 a year for an app is pretty steep」（PRD 3 の引用。自分の検索では同じレビューの要約だけを見た）(3) Android 版で「the timer stops 5—10 minutes into the reading session」（R-16）。ほかに、タイマーと読了の予測で読書が締め切りのように感じたという投稿（R-18） | 順位は付けない。(1)「nothing is really available without watching ads or paying for premium」(2) プライバシーポリシーが「all in Chinese」で「too worried about tracking me」(3)「no tutorial, barely anything to trial」（R-20） | 不満の記録なし（検索で見つからなかった）。代わりに分かったこと：目標の機能そのものを切る設定と、連続日数のデータを消す設定がある（R-21）。数えるのはブック App で読んだ時間で、紙の本を数えるかは見ていない |

比較から外したもの：
- 読書メーター（PRD 3）：読み終えた本の登録が中心で、001 の Job（読んでいる途中の時間とページ）と違う。画面は見ていない。
- Forest と伏せると始まるタイマー（product.md 5）：「スマホから離れる」002 の Job に近い。002 の調査で扱う。

3本から分かること（設計への意味）：
- 3本とも、時間を測ることに目標、連続日数、統計、通知、課金を重ねて「続けさせる」形をとる（R-14、R-19、R-21）。001 は PRD 10 でこれらを出さないと決めている。だから見分けは「足したもの」では作れず、「始めてから終えるまでの手触り」で作る（6 の差をつける点）。
- 不満は、広告と課金の圧（R-16、R-20）、記録とタイマーへの不信（R-16）、数字の圧（R-18）に集まる。どれも抜粋で、順位は付けない。001 の AC（AC-7、AC-8、AC-19、AC-22）がすでに手当てしているので、デザインでは手当てしていることが画面から伝わる形にする（例：保存できなかったときに、読書が消えていないと分かる文言）。

## 4. 手本（別カテゴリー）
- 名前と選んだ理由：Crouton（レシピと料理の手順のアプリ。2024 Apple Design Award の Interaction 部門の受賞。R-3、R-4。どちらも developer.apple.com で開いて確認）。手がふさがる現実の作業の最中に使うアプリで、「画面よりも作業へ早く戻す」を設計の中心に置いている。読書も、手に本を持ち、目を本に向けている間に使うので、問いが同じ。料理は読書と別のカテゴリで、見た目をまねる対象にならない。
- 取り入れる考え方（R 番号）：
  1. 作業の最中は、今の一歩に要るものだけを出す。「Crouton reduces everything to the basics by displaying only the current step, ingredients, and measurements」（R-3）→ 読書中の画面は、題名、経過、一時停止、終えるだけにする（6 の差2）。
  2. 画面より作業に戻す速さを問う。「The key for me is: How quickly can I get you back to preparing the meal, rather than reading?」（R-3）、「people can keep their focus on the counter rather than their screen」（R-4）→ 全画面に「どれだけ早く本に戻せるか」を問う。ホームの1回（AC-5）と、終える入力の1つ（AC-9、AC-10）。
  3. 足すより外すことに時間を使う。「I spent a lot of time figuring out what to leave out rather than bring in.」（R-3）→ PRD 10 のやらないことを、画面の要素の引き算にも当てる（B-1、B-2）。
  4. 標準の型に乗る。「Davies leaned on platform conventions to make navigating Crouton familiar and easy.」（R-3）→ 標準部品を先に使う。
- 取り入れないこと：Crouton の手放しの操作（目の動きで次の手順へ進む。検索の抜粋で見ただけ）は、001 の PRD にないので入れない。
- 補う手本（同じく Apple Design Awards。開いて確認）：
  - Gentler Streak（2024 Social Impact 部門の受賞。R-4）：月のまとめは「less about hard comparisons and more about progress」→ 今週の合計を、目標や他人と比べずに出す（AC-15、AC-36）。文言の調子の手本。
  - grug（2026 Delight and Fun 部門の受賞。R-5）：「there's no login, no cloud syncing, nothing extraneous — just a simple idea」→ 登録なし、端末の中だけ（PRD 10、AC-21）を、足りないものではなく性格として見せる。grug の手描きの見た目とおどけた調子は取り入れない（5 の調子と合わない）。

## 5. ブランドの性格語と文言の調子
性格語は4語。括弧の英語は、英語の文言と応募の資料で使う。

| 性格語 | 意味すること | 意味しないこと |
|---|---|---|
| 静か（Quiet） | 画面が本より前に出ない。読書中は色の面、動き、数字を盛り上げる演出を出さない。通知と音を出さない（PRD 10）。目立つ操作は1画面に1つ | 暗い、さびしい、情報が足りない。押したのに反応が見えない（状態の表示と手応えは省かない。R-1 の「Provide clear feedback」） |
| 確か（Trustworthy） | 時間とページを事実のまま示す。閉じても強制終了しても戻る（AC-7、AC-8）。保存できなかったときはそう言い、読書を消さない（AC-19）。誇張と課金の誘導がない（AC-22） | 堅い、事務的。秒や読書の速さ、読了の予測のような細かい数字を並べること（R-18） |
| すぐ（Immediate） | 開いて1回で読み始める（AC-5）。聞くのは題名とページだけ（AC-2、AC-9、AC-10）。設定と説明の画面を挟まない（R-7） | 雑、急かす、確認なしで消える（消すときは確認する。AC-16、AC-38）。間違えた操作を取り消せない |
| おだやか（Gentle） | 読めない週も責めない。0分は0分と淡々と出す（AC-36）。分を直せる、終える入力をやめられる（AC-12、AC-46） | 甘い、褒めすぎ、絵文字、なれなれしい口調、子どもっぽい絵 |

文言の調子（NN/g の4軸。R-26。HIG の「Determine your app's voice」「Match your tone to the context」も同じ考え。R-8）
- かしこまる ⇔ くだける：かしこまる寄り。文は「です・ます」で短く、ボタンは動詞にする（R-8）。友だち口調（「〜しよう！」）にしない。英語は sentence case で、感嘆符を使わない。「私たち」「we」を主語にしない（R-8）。
- まじめ ⇔ おどける：まじめ寄り。冗談、絵文字、「おっと」「oops」を使わない（R-8 は「oops!」を不誠実に聞こえうるとする）。
- ていねい ⇔ ちゃかす：ていねい寄り。責めない（R-8 の「avoid blame」）。「読めていません」「さぼった」のように、読まなかったことを言葉にしない。
- 淡々 ⇔ 熱っぽい：淡々寄り。祝わない、煽らない。終えたときは事実（分とページ）を返すところまで。「すごい」「達成」「連続」を使わない（R-21 の型の逆。R-22）。ただし冷たくしない（おだやか）。
- 調子の例（調子を示すだけ。キーと最終の文は仕様で決める）：
  - 合う：「72ページから読む」「24分、32ページを記録しました」「保存できませんでした。読書はそのまま残っています。もう一度保存してください」
  - 合わない：「今日も読めたね！」「3日連続！」「おっと、エラーです」「今週はまだ読めていません」「最高の読書体験」

## 6. 合わせる当たり前と、差をつける点
- 合わせる当たり前（利用者がほかのアプリで覚えた型）と R 番号：

| 当たり前 | 根拠 | 001 で満たす AC |
|---|---|---|
| 1回のタップでタイマーを始める | R-14、R-21 | AC-5 |
| アプリを閉じても時間は進む | R-17 | AC-7 |
| 開き直すと、前の状態から続けられる | R-6 | AC-8、AC-33、AC-34 |
| 本ごとに今のページを残し、進み具合を%で出す | R-14 | AC-9、AC-14、AC-28 |
| 設定せずに始められる | R-7、R-21 | AC-1、AC-4 |
| 見た目はシステムのライトとダークに従い、アプリ独自の外観の設定を置かない | R-9 | PRD 12 |
| 消すときは確認し、間違いを取り返せる | R-1 の「Help people recover from mistakes」 | AC-16、AC-38 |
| 空の画面には次の一手のボタンを置く | R-8 の「Provide clear next steps on any blank screens」 | AC-1、AC-37 |
| 標準の部品と並びを使い、よくある操作を作り直さない | R-2 の「there's no need to reinvent the wheel」、R-3 | 全画面 |

- 合わせない当たり前（PRD で出さないと決めたもの。見た目の上でも置かない）：連続日数、目標、達成の通知と共有（R-14、R-19、R-21）、オンボーディング中の課金の画面（R-15。HIG は課金を求める前に体験させよとする。R-7）、読書の速さと読了の予測（R-14、R-18）。根拠は PRD 10、AC-22 と R-22。
- 差をつける点（2つ。どちらも「しおり＝読む時間」という1つの考えから出す）と R 番号：
  - 差1「しおりの往復」：ホームを開いた瞬間と、「終える」を押した瞬間
    - 何をするか：紙の本のしおりと同じ働きを、2つの瞬間に置く。開く：アプリを開くと、ホームの主操作が前の本の「続き」そのものになる（題名と前回のページ。例「こころ　72ページから」）。押せば読書中になる（1回。AC-5、AC-25〜AC-27）。挟む：終えるときに聞くのは「今のページ」1つだけで、すぐ数字を打てて、飛ばせる（AC-9、AC-10、AC-46）。挟んだページが次の「開く」に出る。
    - どの画面のどの瞬間か：ホーム（アプリを開いた直後。読書中は「戻る」操作になる。AC-27）と、終える入力（「終える」を押した直後）。
    - なぜ差になるか：競合の始め方は「タイマーを始める」（R-14）で、記録の対象は本、日記、目標、カレンダーと多い（R-19）。001 は、始める操作と記録の入力の両方を「ページ」に結び付ける。しおりは誰もが知る物で、文字どおりに描かなくても働きが予測できる（R-2 の「aren't too literal or abstract」）。紙のしおりの絵や質感は描かない（B-2。7 で案B を選ばない理由と同じ）。
    - AC との関係：機能は足さない。前回のページは AC-9 で残る値で、ホームの主操作のラベルに出すだけ（表示の決めごとで、識別子 home.startReading は変えない）。本が0冊の最初の流れは AC-1、AC-4 のとおり。
  - 差2「読む間、画面は退く」：読み始めの1回の直後から、本を閉じるまで
    - 何をするか：読書中の画面には、題名、経過時間、一時停止、終えるだけを置く。合計、一覧、統計、色の面、動く飾りを出さない。経過は大きな等幅の数字で、ひと目で読め、桁が揺れない。アクセント色は主操作にだけ使う。
    - どの画面のどの瞬間か：読書中（AC-5 の1回の直後、AC-8 の復元の直後、一時停止中）。
    - なぜ差になるか：手本 Crouton の「only the current step」と「How quickly can I get you back」（R-3、R-4）を読書に移す。Bookly のタイマーの流れは、読書中に引用、考え、登場人物を足す道具を出す（R-15。抜粋）。001 は逆に、読む間に画面がすることを最小にする。寝る前の暗い部屋で（R-23）、画面が本より明るく目立たない（R-9、R-10）。
    - AC との関係：経過の表示（AC-5〜AC-8、AC-33、AC-41）、VoiceOver（AC-40）、AX5（PRD 12）を満たす範囲で引く。一時停止と終える以外の操作を足さない。
- Red Dot（Brands & Communication Design の Apps 区分）との結び付き：
  - 審査は「Idea（originality、creativity）」「Form（design quality、innovation）」「Impact（comprehensibility、emotionality）」で見る。審査員は「whether the work gets the message across adequately towards the target group, and if it affects the viewer in an emotional and sustainable way」を見る（R-27。抜粋。ページは開いていない）。
  - Apps の受賞作の抜粋に共通する点（R-28。抜粋。ページは開いていない。どれも受賞者側の発表で、審査員の講評ではない）：(a) アプリ全体に1つのブランドの考えが通っている（CleanMy®Phone の「holistic brand presence」、BARMER はアプリとデザインシステムの両方で受賞）、(b) 複雑な手順を単純にしている（BARMER の「simplify complex processes through intuitive digital experiences」）、(c) ミニマルで上品と説明される（Denver Life Sciences のアプリ）。
  - だから差は2つに絞り、どちらも「しおり＝読む時間」という1つの考えから出す（Idea と (a)）。差1は、何をするアプリかを1回の操作で分からせる（comprehensibility と (b)）。差2は、読む時間そのものを静かにする（emotionality と (c)）。どちらも PRD の AC の中で作れ、AC を足さない。
  - 後の作業に渡すこと（001 の範囲の外）：アイコン、ストアの画像、003 の形に残す表現も、同じ「しおり」の考えでそろえる（(a)）。応募の画像と動画の形式は見ていない（product.md 9）。

## 7. 方向性の2案

| | 案A「しおりと時計」 | 案B「紙と活字」 |
|---|---|---|
| ひとことで | 道具として静かな画面。背景と文字はシステムの色、書体はシステムの1つ（R-12）、経過時間は大きな等幅の数字。アクセント1色を「しおりの色」として、主操作と読書中の状態にだけ使う（R-10）。質感と絵は使わない。Liquid Glass は標準部品が操作の層に付ける分だけで、内容の層には使わない（R-13） | 本の世界を画面に持ち込む。題名をセリフ体（New York）で組み、生成りの紙の色の背景、表紙風のカードを並べた棚、ページをめくるような動き |
| 性格語との合い方 | 静か、確か、すぐ、おだやかの4語に合う。目立つ操作は1画面に1つ、色は意味だけ（B-2、B-5） | おだやかには合う。静か（画面が本と張り合う）と、すぐ（棚とカードの中で続きの1回が埋もれる）に反する。紙の質感とめくる動きは、役目のない飾りになりやすい（R-1 の「Don't mistake delight for decoration」、B-2） |
| ターゲットとの合い方 | 寝る前の暗い部屋で、システムのダークモードに従い、明るい面がない（R-9、R-10、R-23）。片手で主操作は1つ（R-24）。AX5 では数字と操作が大きくなるだけで、並びが崩れにくい（R-11、R-12） | 紙の色の背景は暗い部屋で明るい面になる。ダークモードでは独自の背景色を作ることになるが、HIG はシステムの背景色を勧める（R-9）。カードの棚は AX5 で崩れやすい［推測］ |
| 競合との違い | 競合が多機能と情緒で埋めている場所（R-14、R-19）から離れ、引き算と2つの瞬間で見分けを作る | Bookmory の「감성 독서 노트（感性の読書ノート）」（R-19）と同じ場所に立つ |
| Red Dot との合い方 | 1つの考え（しおり）が全画面に通り、分かりやすい（R-27、R-28） | 第一印象は強いが、作り込みが「comprehensibility」より見た目に寄る［推測］ |
| 選んだか、その理由 | 選ぶ。性格語、使う場面、Red Dot の見方のどれにも合い、標準部品で作れる（Dynamic Type、ダークモード、VoiceOver が付いてくる） | 選ばない。理由は上の4行。紙の温かさは、003（読んだ時間を形に残す）の表現で検討する余地がある（001 の範囲の外） |

## 8. 発見の一覧

| R | 発見（引用は「」で） | 出典 URL | 確認日 |
|---|---|---|---|
| R-1 | HIG Design principles（開いて確認）。「Investigate existing solutions, and avoid re-creating them. Define what sets your product apart」「Know the feeling you want to evoke」「A fitness app might energize; a meditation app might calm」「Create defining moments.」「Don't mistake delight for decoration.」「Provide clear feedback.」「Help people recover from mistakes.」。変更履歴は「June 8, 2026 Reintroduced design principles.」 | https://developer.apple.com/design/human-interface-guidelines/design-principles | 2026-10-21 |
| R-2 | WWDC26「Principles of great design」の書き起こし（開いて確認）。「Every feature you add to your product, asks something of the person using it. It asks for their time, their attention, and their trust.」「choosing what to build, is often a matter of deciding what not to include」「The trick to metaphors, is making sure they aren't too literal or abstract.」「For common actions, there's no need to reinvent the wheel.」 | https://developer.apple.com/videos/play/wwdc2026/250/ | 2026-10-21 |
| R-3 | Crouton の Behind the Design（2024-11-04 の記事。開いて確認）。「Crouton reduces everything to the basics by displaying only the current step, ingredients, and measurements」「The key for me is: How quickly can I get you back to preparing the meal, rather than reading?」「I spent a lot of time figuring out what to leave out rather than bring in.」「Davies leaned on platform conventions to make navigating Crouton familiar and easy.」 | https://developer.apple.com/news/?id=9x75y43e | 2026-10-21 |
| R-4 | 2024 Apple Design Awards（開いて確認）。Crouton（Interaction の受賞）は「people can keep their focus on the counter rather than their screen」。Gentler Streak（Social Impact の受賞）は「powered not by insistent reminders but an optimistic and encouraging vibe」「relies on a subtle and consistently pleasing design language」、月のまとめは「less about hard comparisons and more about progress」 | https://developer.apple.com/design/awards/2024/ | 2026-10-21 |
| R-5 | 2026 Apple Design Awards（開いて確認）。grug（Delight and Fun の受賞）は「there's no login, no cloud syncing, nothing extraneous — just a simple idea」。Moonlitt（Interaction の受賞）は「brings a simple elegance」「easy onboarding」。Structured（Inclusivity の候補）は「prioritizes downtime as much as productivity」 | https://developer.apple.com/design/awards/ | 2026-10-21 |
| R-6 | HIG Launching（開いて確認）。「Launch instantly.」「Restore the previous state when your app restarts so people can continue where they left off.」 | https://developer.apple.com/design/human-interface-guidelines/launching | 2026-10-21 |
| R-7 | HIG Onboarding（開いて確認）。「Provide reasonable default settings so most people can immediately start interacting with your app or game」「Prefer letting people experience your app or game before prompting them for ratings or purchases.」 | https://developer.apple.com/design/human-interface-guidelines/onboarding | 2026-10-21 |
| R-8 | HIG Writing（開いて確認）。「Determine your app's voice.」「Match your tone to the context.」「When labeling buttons and links, it's almost always best to use a verb.」「Avoid using we altogether」「display it as close to the problem as possible, avoid blame, and be clear about what someone can do to fix it」「Interjections like "oops!" or "uh-oh" are typically unnecessary and can sound insincere.」「Provide clear next steps on any blank screens.」 | https://developer.apple.com/design/human-interface-guidelines/writing | 2026-10-21 |
| R-9 | HIG Dark Mode（開いて確認）。「a dark color palette to provide a comfortable viewing experience tailored for low-light environments」「Avoid offering an app-specific appearance setting.」「For custom foreground and background colors, strive for a contrast ratio of 7:1, especially in small text.」「Prefer the system background colors.」。ダークで Increase Contrast と Reduce Transparency を入れて読めるかを確かめるよう求める | https://developer.apple.com/design/human-interface-guidelines/dark-mode | 2026-10-21 |
| R-10 | HIG Color（開いて確認）。「In dark environments, colors appear bright and saturated.」「in apps with primarily monochromatic content or backgrounds, choosing your brand color as the app accent color can be an effective way to tailor your app experience」「Refrain from adding color to the background of multiple controls.」「Avoid relying solely on color to differentiate between objects」 | https://developer.apple.com/design/human-interface-guidelines/color | 2026-10-21 |
| R-11 | HIG Accessibility（開いて確認）。コントラストの表（17pt まで 4.5:1、18pt と太字は 3:1）。iOS の操作部品は既定 44x44pt、最小 28x28pt。「give people the option to enlarge text by at least 200 percent」。Reduce Motion のときは自動で繰り返す動き（拡大、縮小など）を減らす | https://developer.apple.com/design/human-interface-guidelines/accessibility | 2026-10-21 |
| R-12 | HIG Typography（開いて確認）。「avoid Ultralight, Thin, and Light font weights」「Minimize the number of typefaces you use, even in a highly customized interface.」「Keep text truncation to a minimum as font size increases.」。New York は SF と並べて使えるセリフ体 | https://developer.apple.com/design/human-interface-guidelines/typography | 2026-10-21 |
| R-13 | HIG Materials（開いて確認）。「Don't use Liquid Glass in the content layer.」「Use Liquid Glass effects sparingly.」 | https://developer.apple.com/design/human-interface-guidelines/materials | 2026-10-21 |
| R-14 | Bookly の公式サイトの説明（抜粋。ページは開いていない）。「You start the timer when you want to read, and the app handles the rest.」止めるたびに読み終えるまでの時間を出す。統計に「days you read in a row, reading streak」。目標とリマインダー、蔵書、評価、環境音、実績、Readathon。サイトの題「Stay Motivated and Reach Your Reading Goals with Bookly, the Book Tracker App」 | https://getbookly.com/ | 2026-10-21 |
| R-15 | Bookly の画面の流れの分析（抜粋。ページは開いていない）。「a soft paywall during onboarding」と、閉じると割引を出す流れ。年額に「-75%」の札。Pro の機能に鍵の印。タイマーの流れで「add quotes, thoughts, and characters in the moment」。AI の助手「Bloo」 | https://screensdesign.com/showcase/bookly-tbr-book-tracker | 2026-10-21 |
| R-16 | Bookly の利用者の不満（抜粋。ページは開いていない）。「Full-page ads are ridiculous, especially when the user just wants to add a book.」は完全一致の検索で justuseapp のページが出た（2022年4月の1件のレビュー。年 $30 前後は高い、買い切りなら払うという趣旨が同じレビューにあると要約された。「$30 a year for an app is pretty steep」の文そのものは PRD 3 の引用で、自分の検索では見ていない）。Android 版で「the timer stops 5—10 minutes into the reading session」（2022年10月の報告） | https://justuseapp.com/en/app/1085047737/bookly-book-tracker/contact 、https://justuseapp.com/en/app/1085047737/bookly-book-tracker/problems | 2026-10-21 |
| R-17 | Book Riot の Bookly の紹介（抜粋。ページは開いていない）。画面を離れても「The timer will keep on ticking.」。無料は「up to ten books」 | https://bookriot.com/bookly-review/ | 2026-10-21 |
| R-18 | Reddit r/books「reading tracker caused my reading slump」（抜粋。ページは開いていない。見えたのはミラーの URL）。投稿者は Bookly のタイマーと読了時間の予測で読書が締め切りや競争のように感じ、アプリを消したと要約された。コメントには、年の目標が励みになる人と、低い目標でも不安になる人の両方がいる | https://lr.ggtyler.dev/r/books/comments/1fhkuem/reading_tracker_caused_my_reading_slump/lnaybwr/?context=3 | 2026-10-21 |
| R-19 | Bookmory の説明（抜粋。ページは開いていない）。「It's a reading log, reading journal, reading timer, and reading goal app — all in one place.」。韓国語の題は「북모리 - 책을 기록하고 기억하는 감성 독서 노트」（検索結果の URL の文字列を戻して確認）。月の読書カレンダー、写真の文字の読み取り、連続日数。タイマーは本のページから使い、テーマは有料（Book Riot） | https://apps.apple.com/US/app/id1515533482 、https://apps.apple.com/us/app/%EB%B6%81%EB%AA%A8%EB%A6%AC-%EC%B1%85%EC%9D%84-%EA%B8%B0%EB%A1%9D%ED%95%98%EA%B3%A0-%EA%B8%B0%EC%96%B5%ED%95%98%EB%8A%94-%EA%B0%90%EC%84%B1-%EB%8F%85%EC%84%9C-%EB%85%B8%ED%8A%B8/id1515533482?l=vi 、https://bookriot.com/bookmory-review | 2026-10-21 |
| R-20 | Bookmory の利用者の不満（抜粋。ページは開いていない）。「nothing is really available without watching ads or paying for premium」。プライバシーポリシーが「all in Chinese」で「too worried about tracking me」。「no tutorial, barely anything to trial」。Gizmodo は統計などに「view advertisements or buy subscriptions」が要るとする。App Store のプライバシーの欄に追跡に使われうる識別子と使用状況データがあるという要約 | https://justuseapp.com/en/app/1515533482/bookmory-book-tracker/reviews 、https://gizmodo.com/download/bookmory | 2026-10-21 |
| R-21 | Apple ブックの読書目標（抜粋。ページは開いていない）。既定は1日5分。「Books lets you know how many days in a row you reach your daily reading goal and notifies you when you set a record.」。達成すると通知が来て「send your achievement to friends」。新しい版は Reading Now タブ → Reading Goals → Today's Reading。Mac 版には読書目標を切る設定と「Clear Reading Goals Data」がある | https://support.apple.com/en-me/guide/iphone/iph6013e96f4/ios 、https://support.apple.com/guide/books/ibks7c41beea/mac | 2026-10-21 |
| R-22 | 連続日数の研究の紹介（抜粋。ページは開いていない。元の論文は見ていない）。連続を保つことは励みになるが、切れると少なくとも短い間は意欲が下がる。切れた連続を目立たせると続けにくくなる、と要約された | https://www.psychologytoday.com/us/blog/ulterior-motives/202306/how-broken-streaks-sap-motivation 、https://knowledge.insead.edu/marketing/consumer-streaks-are-motivating-key-keeping-them-alive | 2026-10-21 |
| R-23 | 社会人の読書習慣の調査（壺中天調べ、2023年11月の記事。抜粋。ページは開いていない。母集団と人数は見ていない）。いつ読むかは「就寝前」46.7%が最も多く、「休日」「通勤など移動時間」「仕事の休憩時間」が続く（複数回答） | https://webtan.impress.co.jp/n/2023/11/02/45907 | 2026-10-21 |
| R-24 | Hoober「How Do Users Really Hold Mobile Devices?」（2013。抜粋。ページは開いていない）。街で1,333件を観察し、画面に触れていた780件の持ち方は片手49%、もう片方の手で支える36%、両手15%（要約の記事による。元の記事の数字の分け方は確かめていない） | https://www.uxmatters.com/mt/archives/2013/02/how-do-users-really-hold-mobile-devices.php 、https://www.smartinsights.com/mobile-marketing/mobile-design/research-on-mobile-interaction-behaviour-and-design/ | 2026-10-21 |
| R-25 | Reinecke と Gajos「Quantifying Visual Preferences Around the World」（CHI 2014。抜粋。ページは開いていない）。約4万人の240万件の評価で、好む色の量と複雑さは属性で変わる。女性は男性より色の多いサイトを好み、学歴が高いほど色の多さと複雑さを好まない傾向 | https://eecs.harvard.edu/~kgajos/papers/2014/reinecke14visual.shtml | 2026-10-21 |
| R-26 | NN/g の文言の調子の4軸（抜粋。ページは開いていない）。funny と serious、formal と casual、respectful と irreverent、enthusiastic と matter-of-fact。どれも両端の間の位置で決める | https://www.nngroup.com/videos/tone-of-voice-dimensions/ | 2026-10-21 |
| R-27 | Red Dot: Brands & Communication Design の審査の見方（抜粋。ページは開いていない）。Communication Design は「Idea（originality、creativity）」「Form（design quality、innovation）」「Impact（comprehensibility、emotionality）」で見て、重みは作品の種類で変わる。審査員は「whether the work gets the message across adequately towards the target group, and if it affects the viewer in an emotional and sustainable way」を見る | https://red-dot.org/communication-snippets-bcd-2023 、https://red-dot.org/magazine/how-to-convince-the-red-dot-jury-this-is-what-the-experts-for-communication-design-pay-attention-to | 2026-10-21 |
| R-28 | Red Dot の Apps の受賞作に共通する点（抜粋。ページは開いていない。どれも受賞者側の発表で、審査員の講評ではない）。CleanMy®Phone（2024、Apps と Interface & User Experience Design）は「sleek design and holistic brand presence」で受賞と発表。BARMER の Apps（2026、Brands & Communication Design の「Apps (Health)」）は「simplify complex processes through intuitive digital experiences」とされ、デザインシステムも別の区分で受賞。Denver Life Sciences のアプリ（2026、User Experience と Lifestyle Apps。どの賞の区分かは抜粋で確かめられない）はミニマルで上品と説明された。Apps には「Apps (Health)」のような小分けがある | https://macpaw.com/news/cleanmyphone-wins-design-awards 、https://ibmix.de/en/news/ibm-ix-wins-two-red-dot-awards/ 、https://www.streetinsider.com/PRNewswire/Denver+Life+Sciences+Wins+Two+Red+Dot+Design+Awards/26863927.html | 2026-10-21 |

見られなかったもの：
- 競合3本（Bookly、Bookmory、Apple ブックの読書目標）のアプリの画面と、App Store の画面写真。App Store（apps.apple.com）、公式サイト（getbookly.com）、support.apple.com がプロキシに拒まれた。主な作業のタップ数、ナビゲーションの構成、空の状態、色、文字は見ていない。
- 競合の App Store のレビューのページそのもの。不満の引用は、どれも検索の抜粋で見ただけ（R-16、R-20）。
- red-dot.org の受賞作のページ、Apps 区分の要項と小分けの一覧、審査員の講評（R-27、R-28 は抜粋だけ）。
- NN/g の記事、Hoober の元の記事、Reinecke と Gajos の論文、壺中天の調査の元の記事、連続日数の研究の元の論文（R-22〜R-26 は抜粋だけ）。
- Crouton、Gentler Streak、grug のアプリの画面（Apple の受賞ページと記事の文で見ただけ）。

## 確かめ（提出前に designer が印を付ける。design-reviewer はこれを信じずに確かめる）
- [x] R が5つ以上あり、どれにも出典 URL と確認日がある（R-1〜R-28。開いて確かめたのは R-1〜R-13、抜粋だけは R-14〜R-28）
- [x] 競合を2つ以上と、手本を1つ調べた。不満は引用と URL 付き（競合は Bookly、Bookmory、Apple ブックの読書目標。手本は Crouton。不満の引用は R-16、R-20。Apple ブックは不満の記録なし。競合の画面は見ていない）
- [x] ターゲットは「仮説」と書き、根拠に R 番号がある（2。場面は R-23、R-24、感情は R-1、R-4、R-18、R-22、好みは R-9、R-10、R-25）
- [x] 性格語ごとに「意味しないこと」がある（5。静か、確か、すぐ、おだやか）
- [x] 差をつける点が1から2個ある（6。差1 しおりの往復：ホームと終える入力。差2 読む間、画面は退く：読書中）
- [x] 方向性の2案と、選ばなかった理由がある（7。案A を選び、案B を選ばない理由を書いた）
