# デザイン調査 001-reading-session：夜の入口、本の出口（v1）

- 対象の PRD：docs/prd/001-reading-session.md（コミット 9f7c5d9。G0 は承認済み、docs/approvals/001-reading-session-G0.md）。アプリ全体は docs/prd/product.md（アプリ名「よむま」、サブタイトル「今夜も、本の続きの一行から」）
- 書いた役：designer　日付：2026-10-19（R はすべて 2026-10-19 に開き直した。8 の確認日）
- この文書は仕様（design/001-reading-session.md）より先に書く。仕様の決定は、8 の R 番号を根拠に引く。
- 見られなかったもの、開けなかったページは「見ていない」と書く。推測で埋めない。推測には［推測］と書く。
- 前の版（2026-10-16。製品の形が「夜の入口、本の出口」に決まる前の、伏せて読む読書タイマーのときの調査）は git に残る。この版で全部を書き直し、R の番号を振り直した。
- 調べ方
  - App Store は、lookup と search の API（製品ページと同じ説明文、評価の数、画面写真の URL を返す）と、レビューの RSS で読んだ。apps.apple.com の HTML そのものは開いていない。
  - 画面写真は、lookup の screenshotUrls の画像をリポジトリの外（スクラッチパッド）で一覧の台紙にして見た。リポジトリには入れていない。
  - HIG は、developer.apple.com/tutorials/data/design/human-interface-guidelines/<ページ>.json を curl で取り、本文を取り出して読んだ（16ページ、どれも HTTP 200）。
  - どのアプリも、designer は入れて使っていない。

## 1. 問いと範囲
- この調査で決めたいこと（仕様の段の土台にする問い）
  1. 毎晩の入口（ロック画面の長方形のウィジェット、StandBy、予約した Live Activity）に何を出し、何を出さないか。小さな枠（172×76 pt。PRD E-9）と、システムが色を抜く描き方（vibrant）の中で、縦書きの一行をどう読ませるか。
  2. しおりの画面（1画面、タブなし）で、主操作「読み始める」と伏せる道を、同じ重みのままどう見せるか。
  3. 登録（バーコードを続けて読む、書名で探す、手で入れる）で、ほかのアプリの不満（見つからない、読み取れない、許可の項目が出ない）をどう避けるか。
  4. 読み終えた夜（奥付、次の1冊、カード、ふりかえりの1行）を、祝う演出なしで、どう決定的な瞬間にするか。
  5. アプリの外の入口（Control、Action ボタン、Siri、ショートカット）の名前、記号、声の調子（付記の G1-15 の下地）。
  6. 「一行と書名を出さない」設定のときの見え方（ウィジェット、Live Activity、Siri の声と小窓）。
  7. 「よむま」と「今夜も、本の続きの一行から」に合う性格語、文言の調子、見た目の方向。
- 調べる深さ（PRD 冒頭の回す順に合わせた）
  - 芯（毎晩の入口と本の出口の骨。回さないもの）を先に深く見た：ロック画面のウィジェット、しおりの画面と「読み始める」と伏せて読む、しおりを挟む（撮らない道）、登録、奥付、積読からの次の1冊、「一行と書名を出さない」設定。
  - v1.1 に回しうるもの（読み終えのカードとふりかえりの1行、受賞、予約した Live Activity とアプリの外からの「読み始める」、ショートカット、撮る道、有料の見た目）は、仕様で形を決めるのに要る所までにした。
- 関係する受け入れ条件（AC 番号）
  - 芯
    - 毎晩の入口：AC-27〜AC-35、AC-39、AC-40、AC-96、AC-99
    - 読み始める、伏せて読む、数える：AC-42〜AC-62
    - しおりを挟む（撮らない道）：AC-63、AC-64、AC-71〜AC-76、AC-95
    - 登録と最初の本：AC-1〜AC-12、AC-92、AC-113
    - 本棚と本の画面：AC-13〜AC-18、AC-22〜AC-26
    - 読み終えた夜（骨）：AC-77〜AC-83、AC-86、AC-87（3b が届かなかったとき）
    - 設定と保存、速さ：AC-88〜AC-91、AC-93、AC-103、AC-100〜AC-102
  - 回しうるもの（仕様の判断に要る所まで）
    - (5) 予約した Live Activity とアプリの外からの「読み始める」：AC-36〜AC-38、AC-41、AC-97、AC-98、AC-114〜AC-120、AC-130〜AC-132、AC-136
    - (ショートカット)：AC-121〜AC-126、AC-133〜AC-135
    - (3) 読み終えのカードとふりかえりの1行：AC-84、AC-85、AC-127〜AC-129
    - (4) 受賞：AC-19〜AC-21、AC-112
    - (6) 撮る道：AC-65〜AC-70、AC-94
    - (課金) 有料の見た目：AC-104〜AC-111
  - designer への申し送り：付記の G1-7（古くなった Live Activity の見え方）、G1-8（有料の見た目の id と見本）、G1-9（「しおりどき」を「よむま」に直す。識別子の対応表）、G1-13（ラテン文字の著者の並び）、G1-15（App Intents の名前、言い方、記号、声の文、小窓、「終える」の形とラベル、大きい文字のときの並び）
- 結果待ち（Takuma の実機の確かめ。2026-10-19 の時点で届いていない）
  - 伏せた向きの取れ方（縦の固定、仰向け。PRD 6 の Q-A、G4-7、G4-14）：伏せる案内の1行（仮の識別子 `bookmark.flipHint`）を出すか、文をどうするか。PRD では伏せる道と「読み始める」は同じ重みの道なので、しおりの画面の目に見える主操作が「読み始める」であることは、結果では変わらない。
  - ロック中の Live Activity の「終える」（付記の G1-16 (b)）：「終える」の読み上げのラベルと案内の文を1つに絞れるか。
  - ロック画面の vibrant の実際の色と字の太さ（G4-1）：縦書きの一行の太さ（探りの絵では W6）。

## 2. ターゲット（仮説）
人に聞いた調査ではなく、PRD とレビューなどから立てた仮説として書く。
- 誰が（仮説）
  - 日本に住み、紙の本を読みたいのに、平日の夜はスマホに流れて読めずに終わる、働いている人（product.md の 1）。読書量が減った理由の1位はスマホなどの情報機器 43.6%、2位は「仕事や勉強が忙しくて読む時間がない」38.9%（PRD E-1。pdm が 10-18 に読んだ値で、designer は開き直していない）。
  - 次の層：積読があり、1冊を読み終えたあと次の本が決まらない人（PRD E-7［推測を含む］）。
  - 対象にしない：蔵書の管理、感想の公開、読書の SNS が目的の人。ブクログが機能の量で強く、その量への不満もある（R-8、R-9）。
- 使う場面（片手か、移動中か、何秒か）
  - 家の夜、ソファかベッドで、手がスマホに伸びた瞬間。ロック画面を見るのは1〜2秒。手に取ってから読み始めまで約3.5〜4.5秒［推測。docs/reviews/001-reading-session-integrate-designer.md の 1-1］。
  - 片手でスマホを取り、読み始めたら両手は本。スマホは机か布団に伏せるか、枕元で充電する（StandBy）［推測］。
  - 暗い部屋で、隣で人が寝ていることがある［推測］。音と光を足さず、声に一行を出さない（R-22 の「others nearby might hear the response」）。
  - 移動中は主な場面ではない。電車で立って読む人は伏せる場所がないので、ボタン1回の道が要る［推測］（R-29）。
  - 1晩にアプリを前に出している時間は、中央値で30秒以内にしたい（PRD の G-1［推測］）。
- 起こしたい感情
  - 「今夜も、続きから戻れた」という小さな安心と、スマホに流された後ろめたさから離れること（PRD 2 の気持ちの面［推測］）。HIG の言う「a meditation app might calm」の側（R-23）で、達成感、競争、ごほうびの側ではない。
  - 根拠：静かさを喜ぶ声「SNSに疲れる日々ですが、いいねやコメントなどもなく、とても落ち着くし集中できます。」と、入口が読書を増やした声「これを開きたくて、勝手に読書時間が増えました笑」（R-11）。ToRead は「点数はつかない」を打ち出している（R-2）。Bookmory の連続日数（ストリーク）には不満が出ている（R-5）。
- 見た目の好み（色の量、情報の密度）と根拠（R 番号）
  - 色は少なく（白、黒、灰。アクセント色なし）、密度は低く（1画面に今夜の本だけ）する［仮説］。
  - 根拠1：飾りと手間を嫌う声。Forest「豪華なデザインとかアニメーションとか要らない」「作業終了時に余計なアニメーションやひと手間が増えており」（R-12）。
  - 根拠2：いちばん目に触れる面（ロック画面と暗い所の StandBy）は、システムが色を抜く（vibrant）か、赤の単色で描く（R-19）。色で個性を出しても、毎晩の入口には届かない。
  - 根拠3：近い競合の見た目は、生成りと濃紺と淡い橙（ToRead、R-2）、青と紙吹雪（Bookmory、R-4）、線画の猫と色とりどりの表紙（ネコノホンシツジ、R-6）、水色と表紙の棚とグラフ（ブクログ、R-8）。白黒灰と縦書きの明朝は、どれとも重ならない。
  - 注意：好みは人で違う。色の多さの好みは性別や学歴で変わり（「Females, for example, liked colorful websites more than males.」「A high education level generally lowers this preference for colorfulness.」R-34）、かわいい見た目のネコノホンシツジは売れている（PRD E-16）。だから「色は少ないほど良い」は一般則ではなく、この対象と夜の場面についての仮説として扱う［推測］。
- アクセシビリティで必要なこと
  - 大きい文字（AX5）。夜に、老眼の人も読む［推測］。縦書きの一行は自前の組みなので、大きい文字では並びを変える（R-24 の「consider using a stacked layout」）。
  - 暗い部屋でまぶしくないこと。ダークを先に決める（R-25 の「dimmer background colors and brighter foreground colors」）。
  - 伏せられない人（片手、手のふるえ、スタンドに置く人）：同じことがボタンでできて、伏せる道を切れること（R-29）。アプリの外の入口は、ボタン1回の道と声の道になる（PRD 12）。
  - VoiceOver：縦書きの一行を、1つのラベルとして読む（PRD 12、AC-99）。
  - 触覚だけに頼らない。触覚は短く、切れるようにする（R-28）。
  - 色だけで区別しない。動きを減らす設定で動きを止める（R-24、R-25）。

## 3. 競合
直接の競合を4本選んだ。どれも PRD の 3 と product.md の 4 にあるアプリで、需要と不満の調べものはやり直さず、見た目と操作の比較を足した（不満の引用は 10-19 に RSS で原文を確かめ直した）。画面は lookup の画面写真から読み、アプリは使っていない。

| 項目 | 競合A ToRead: 読書タイマー | 競合B Bookmory | 競合C ネコノホンシツジ | 競合D 読書管理ブクログ |
|---|---|---|---|---|
| 名前、URL、選んだ理由 | https://apps.apple.com/jp/app/toread-%E8%AA%AD%E6%9B%B8%E3%82%BF%E3%82%A4%E3%83%9E%E3%83%BC/id6757129946 。毎晩の入口の当たり前（ワンタップ、ロック画面の読書時間、Siri とショートカット）を持つ、いちばん近い読書タイマー（PRD 3 の上位3件） | https://apps.apple.com/jp/app/id1515533482 。ロック画面と Dynamic Island のタイマーを持つ、多機能な記録アプリの代表（product.md の 4） | https://apps.apple.com/jp/app/id6752113848 。ロック画面の読書カードを持ち、見た目（猫の着せ替え）で選ばれている日本の新しいアプリ（PRD 3、E-16） | https://apps.apple.com/jp/app/id359066582 。本の出口の当たり前（連続スキャン、本屋大賞、おすすめ）を持つ最大手（PRD 3、E-8） |
| 良い点（取り入れる考え、R 番号） | 数で責めない（「ゲーミフィケーション、連続記録、競争なしで」、画面の見出し「点数はつかない」）。誤って終えても戻れる（「誤って『終了』を押しても読書を続けられ、間違えて始めたセッションは取り消せます」）。どちらも取り入れる（R-1、R-2） | ロック画面で読書中だと分かる（「ロック画面やDynamic Islandでタイマーを確認」）。当たり前として合わせる（R-4） | 「読書中」を親しみのある絵にして、開く理由を作る（R-6）。絵は取り入れず、開く理由は「続きの一行」で作る | 「連続スキャン対応でまとめて登録もOK」。取り入れる（1冊ごとの登録ボタンを置かない。AC-3）（R-8） |
| 主な作業のタップ数 | 読み始め1（中央の「読む」）、終わり1（「終了」）。画面写真から（R-2） | 見ていない（タイマーの画面に一時停止と「Save」がある。R-4） | 見ていない（ホームの読書中の札に「一時停止」「読書終了」「文章収集」の3つが並ぶ。R-6） | 見ていない（バーコードの画面は、上に赤い枠、下に読んだ本の一覧。R-8） |
| ナビゲーションの構成 | タブバーは写っていない。右端に縦の点がある（ページの印か［推測］）（R-2） | 見ていない（見た7枚にタブバーは写っていない。R-4） | 下にタブが5つ（R-6） | 下にタブが5つ（R-8） |
| 最初の価値までの画面数 | 見ていない | 見ていない | 見ていない | 見ていない |
| 空の状態 | 見ていない | 見ていない（「Welcome :)」「What book did you read today?」の画面はある。R-4） | 見ていない | 見ていない |
| 権限の求め方 | 見ていない | 見ていない | 見ていない | 見ていない。レビューに「カメラへのアクセスを許可する項目が出てこず利用できない。」（R-9） |
| 色、文字、情報の密度 | 生成りと濃紺の地。見出しは明朝に近い書体で、一部が淡い橙。経過は細く大きな数字（23:46）。1画面の要素は数個で、密度は低い（R-2） | 青と生成り。カレンダーに表紙が並ぶ。読み終えに紙吹雪と「Congratulations! You're all done!」。メモの画像に桃色の山の背景（「美しい背景でメモを保存します。」）。密度は中くらい（R-4） | 白地に黒の線画の猫、色とりどりの表紙の棚とカレンダー、着せ替えの部屋の絵。ゴシック。密度は中〜高（R-6） | 水色の地、表紙の棚、キャンペーンの帯、グラフ、新刊の通知。ロック画面に「バーコードで本を登録」「本を検索」を開くウィジェット（小さな字を画像から読んだ）。ゴシック。密度は高い（R-8） |
| 文言の調子 | 詩的で静か。「座って。ただ、読む。」「流れるのは時間。数字ではなく。」「読書は終わる。一文は残る。」（R-2） | 売り込み調。「シンプルだが完全読書管理」「モチベーションを保つのがこれまでになく簡単になります。」（R-4） | やわらかく親しい。「猫と過ごす、読書のたのしみ」「どの本を読めばいいか分からない時は?猫がおすすめしてくれます。」（R-6） | にぎやか。「話題の本から気になる1冊に出会える」「新刊情報をいち早くお届け！」（R-8） |
| App Store の評価 | JP 3件、平均5.0（R-1） | JP 189件、平均4.72（R-4） | JP 308件、平均4.60（R-6） | JP 28,267件、平均4.54（R-8） |
| 悪い点（レビューの不満の上位3つ、R 番号） | 不満の記録なし（JP の RSS は本文0件。R-3） | 1）登録：「9月発売の本を検索しても見つからないのは少し困ります。そして、バーコードの読み取りに失敗した場合、フリーズする場合があります。」（2024-10-13 ★3）　2）割り込み：「The two seperate pop ups you have to close out of EVERY time you open this app are horrid.」（2026-09-07 ★1）　3）連続日数：「every time I go in to log finishing a book that I’ve always started a one day streak」（2026-10-12 ★1）（R-5） | 1）登録：「検索してもヒットしない本が多くてなかなか他の管理アプリから移行しきれない。」（2026-10-03 ★3）　2）直せない時間：「時間の編集機能もつけてほしい。すぐ忘れて読書時間10時間‼️とかになってしまう」（2025-12-26 ★3）　3）更新の多さ：「アップデートが多い。頻回すぎて面倒。」（2026-07-12 ★3）（R-7） | 1）おすすめ：「好きでもない表紙の絵をここ数年毎回見せられること。全く更新されることもない」（2026-08-29 ★1）　2）登録と許可：「バーコードで本登録できんくなった」（2026-05-19 ★1）、「カメラへのアクセスを許可する項目が出てこず利用できない。」（2025-12-22 ★1）　3）有料化：「有料化が進みすぎている。」（2026-06-13 ★3）（R-9） |

- 上位3つの分け方：星3以下のレビューを designer が読んで種類で分けた。数は数えていない（登録の失敗の割合は PRD E-4 の数え方を使う）。ブクログは page=1〜2 の星3以下39件のうち先頭24件、Bookmory は JP 3件と US 5件、ネコノホンシツジは6件を読んだ。
- 隣の競合：ロック画面とウィジェットに「言葉」を出すアプリ（R-13。説明文だけで、画面は Kotoba の3枚のほかは見ていない）
  - Kotoba「本の一文、映画や推しのセリフ、自分と決めた約束。」「ウィジェットに好きな一つを固定表示（ホーム画面の小・中・大、ロック画面の3種）」「書体（ゴシック／明朝／丸ゴシック）」。
  - 名言ウィジェット「iPhoneのホーム画面・ロック画面・スタンバイに表示できる名言アプリ」。ことばめくり「日本の文学と古典の言葉が毎朝ひとつ」「充電中に横置きしたスタンバイ画面にも出る」。
  - よみかえし（引用カード）「その一文を撮って残し、毎日1枚あなたのもとへ返す」「日本語の縦書きにも対応しています」「ホーム画面ウィジェット」。hanjul-note と WordDrop も、本の一文をホーム画面のウィジェットに出す。
  - わかったこと：「ロック画面に本の言葉を、明朝で出す」こと自体は、もう当たり前になりつつある。説明文の範囲では、どれも選んだ言葉を眺める形で、読書の記録や読み始めの入口にはつながっていない。だから違いは見た目ではなく、「自分が昨夜止めた一行とページ（＝続き）」という中身と、押すとその本の読書が始まる道にある（6 の D-1）。
- 伏せる道の先行：伏せると始まるタイマーは2018年からある（FLIP、ベアフォーカスタイマー。US には読書の Offshelf）。PRD E-13 の値で、designer は 10-19 に開き直していない。伏せる道は差をつける点にしない（6）。

## 4. 手本（別カテゴリー）
- 名前と選んだ理由：Flighty – Live Flight Tracker（旅行。Apple Design Awards 2023 の Interaction 部門の受賞）
  - ロック画面の Live Activity と Dynamic Island で、手に取った瞬間に「いま要る事実1つ」を出している。画面写真に「Live Activities」「Dynamic Island」「Track your flight status on your lock and home screen」と、ロック画面の「1h 20m UNTIL GATE ARRIVAL」「Departs Gate in 45m」がある（R-14）。
  - 受賞の紹介文は「With key information where you need it most, an intuitive interface, comprehensive live maps, and a look that mirrors time-honored airport design conventions」（R-15）。PRD が主に狙う Interaction 部門（product.md の 5）の受賞で、部門の定義は「deliver intuitive interfaces and effortless controls that are perfectly tailored to their platform」（R-15）。
  - 声の入口も、アプリの名前を入れた言い方で持つ。「Hey Siri, ask Flighty, what's the status of my flight?」（R-14）。
- 取り入れる考え方（R 番号）
  - T-1 いま要る事実1つを、要る場所に出す。Flighty はゲートまでの時間、こちらは続きの一行とページ（R-14、R-15）。HIG も「Provide useful information in your Lock Screen widget, and don’t treat it as an additional way for people to launch into your app.」と書く（R-18）。
  - T-2 昔からの慣習の見た目を借りる。Flighty は空港の案内の慣習（R-15）、こちらは本の慣習（縦書き、しおり、奥付、明朝）。HIG の「Use concepts that people know.」（R-23）。借りるのは組みの決まり（行頭と行末の禁則、小さい仮名の位置。R-30）で、紙の質感の飾りではない。
  - T-3 1つの Live Activity が、時間につれて状態を変える。Flighty は出発までの時間とゲートを出し続ける（R-14。出発前から到着までのすべての状態は見ていない）。こちらは「待つ → 読む → 結果」（R-20 の「Offer Live Activities for tasks and events that have a defined beginning and end.」）。
  - T-4 声の入口は、アプリの名前を入れた短い言い方にし、答えは短くしてアプリの名前を入れない（R-14、R-22）。
  - 取り入れないこと：Flighty の不満「the constant popups pushing the Pro subscription make it a chore to use」（2026-10-06 ★3）と「Broken. Flood of worthless notifications」（2026-10-13 ★1）（R-16）。購入の案内を割り込ませず、通知を出さない（product.md の守ること）。
- もう1本（参考）：Moonlitt: Moon Phase Tracker（月の満ち欠け）。「Widgets, Apple Watch app, and Live Activity for moon phase, moonrise, and moonset.」「Refined widgets, Live Activities, and StandBy for the new displays.」（R-17）。自然の時間を扱う小さな道具を、ウィジェット、Live Activity、StandBy の面で作った例。ADA 2026 の Interaction の受賞は integrate-designer が 10-18 に読んだもので、designer は 10-19 に ADA 2026 のページを開き直していない。画面は見ていない。
- 見ていないもの：Flighty を実機で使っていない。画面写真は10枚のうち4枚だけ見た。Live Activity の動き、Siri の実際の答え、出発前から到着までの状態の移り変わりは見ていない。

## 5. ブランドの性格語と文言の調子
性格語は5語。前の版の「静か」「確か」「まっすぐ」は残し、「手で感じる」を「紙の側」に言い換え、「急かさない」を足した。製品の形が「夜の入口、本の出口」になり、読まなかった晩と読み終えた夜の扱いが性格に入ったため。NN/g は性格を「a set of traits that inform everything from product or service development to identity systems」とし、作る側の意図（brand intention）と、使う人の受け取り方（brand interpretation）を分ける（R-32）。受け取り方は G3 で design-reviewer が画面だけを見て確かめる。

| 性格語 | 意味すること | 意味しないこと |
|---|---|---|
| 静か | 画面に出すのは今夜の本と続きだけ。音、通知、祝う絵、数のバッジを出さない。読書中に押せるのは「終える」1つ。色は意味のためだけに使う | 寂しい、暗い、何が起きたか分からない（状態は必ず文字で言う）、大事な情報を隠す |
| 確か | 読んだ時間とページが消えない、ずれない。奥付はデータのある行だけ。次の1冊の理由は確かめられる事実1行。写真を残さないこと、外に送らないものを言い切る | 機械的、冷たい、秒まで見せる細かさ、責める数字、根拠のない「あなたへのおすすめ」 |
| まっすぐ | 1画面に主操作1つ。ボタンは動詞。置く動作がそのまま始まりになる。説明の画面を挟まない | 素っ気ない、説明が足りない、命令口調 |
| 急かさない | 読まなかった晩を責めない（連続日数、目標、未読の数を出さない）。次の本は読み終えた夜にだけ出す。読まなかった晩の Live Activity は翌朝に残さない | 放っておく、何も勧めない、使い方を教えない、読んだことに何も返さない |
| 紙の側 | 紙の本の慣習（縦書き、しおり、奥付、明朝）を、組みの決まりとして借りる。伏せる、起こすという動作と触覚で伝える | 紙や革の質感の飾り、懐古趣味、体の動きしか道がないこと、本の文を外に出すこと |

- 名前とサブタイトルとの結びつき
  - 「よむま」は「読む間」。「静か」と「急かさない」は、読むための間を守る言葉。
  - 「今夜も」は「急かさない」：昨夜読めなかったことを責めず、今夜また戻れることだけを言う。
  - 「本の続きの一行から」は「紙の側」と「まっすぐ」：自分の本の具体的な一行から、操作なしで始める。

文言の調子（NN/g の4軸。R-31）
- かしこまる ⇔ くだける：まんなかより、かしこまる寄り。です・ます。見出し、ボタン、ウィジェットは体言止めか動詞（「読み始める」）。
- まじめ ⇔ おどける：まじめ。冗談、絵文字、感嘆符を使わない。ブクログの「！」や、ネコノホンシツジの「猫がおすすめしてくれます」と逆（R-8、R-6）。
- ていねい ⇔ ちゃかす：ていねい。
- 淡々 ⇔ 熱っぽい：淡々。ほめない、祝わない。Bookmory の「Congratulations! You're all done!」と紙吹雪と逆（R-4）。ToRead の詩的な見出し（R-2）とも違い、起きたことを短く言う。温かさは形容詞ではなく、出す時（今夜、読み終えた夜）と、出さないもの（数、勧め）で出す。HIG の「Match your tone to the context.」（R-26）。
- 例（PRD にある形。文の確定は仕様で行う）：「p.43 → p.61　18分」、「61ページからです。」、「6晩、合計2時間22分で読み終えました。いちばん長く読んだのは10月15日の晩で、38分でした。」
- 英語も同じ調子にする：平らな文、感嘆符なし、ボタンは動詞で始める（R-21 の Action ボタンの決まり、R-26）。

## 6. 合わせる当たり前と、差をつける点
- 合わせる当たり前（利用者がほかのアプリで覚えた型）と R 番号
  1. 読み始めは1回の操作。ToRead「ワンタップで読書開始」（R-1）。しおりの画面の「読み始める」がそれに当たり、伏せる道はその近道にする（R-29）。
  2. ロック中も、ほかのアプリの間も数える。mekuru への「画面閉じれるようにして欲しい」と、2時間で止まった不満（R-11）。Bookmory はロック画面でタイマーを見せる（R-4）。
  3. 間違いを直せる。ToRead の「間違えて始めたセッションは取り消せます」（R-1）、ネコノホンシツジへの「時間の編集機能もつけてほしい」（R-7）、HIG の「Help people recover from mistakes.」（R-23）。記録の分数を直す、消すを置く。
  4. 登録はバーコードを続けて読む。ブクログ「連続スキャン対応でまとめて登録もOK」（R-8）、読書メーター「連続読み取り機能で手間いらず！」（R-10）。見つからない本と許可の不満（R-5、R-7、R-9）があるので、書名で探す道と手で入れる道を同じ所に並べ、カメラの許可はボタンを押したときに求める（R-27）。
  5. 連続日数、目標、競争を置かない。ToRead「ゲーミフィケーション、連続記録、競争なしで」（R-1）と、Bookmory の連続日数への不満（R-5）。
  6. ライトとダーク、大きい文字、コントラスト（R-24、R-25）。
  7. ロック画面の言葉は、小さな枠に明朝で出す（Kotoba は書体に明朝を選べる。R-13）［推測：利用者が見慣れた型］。ロック画面のウィジェットを、アプリを開くだけのボタンにしない（R-18。ブクログのロック画面のウィジェットは「バーコードで本を登録」「本を検索」を開く形。R-8）。
  8. Live Activity はボタン1つで、始まりと終わりがある（R-20）。Control、Action ボタン、Siri の入口は、読書アプリにも旅行のアプリにもある（ToRead「Siriとショートカットがお使いの言語に対応し」R-1、Flighty の Siri R-14）。
  9. 購入の案内と通知を割り込ませない（Flighty と Bookmory のポップアップへの不満 R-16、R-5、ブクログの「課金誘導っぽいエラー表記」R-9）。
  10. 空の画面は、何が起きているかと次の一手を出す（R-33、R-26 の「Provide clear next steps on any blank screens.」）。たとえば本が0冊のしおりの画面（AC-1 の `bookmark.empty.message` と `bookmark.addBook`）。エラーは問題の近くに、責めずに、直し方を書く（R-26）。
- 差をつける点（2個。どの画面のどの瞬間か）と R 番号
  - D-1 手に取った瞬間の「続き」
    - どこで：ロック画面の長方形のウィジェット。毎晩、iPhone を手に取った瞬間（操作0回）。同じ一行を、押して開いたしおりの画面と、充電中の StandBy で大きく出す。
    - 何が違うか：読書アプリのロック画面は読書時間（ToRead、Bookmory。R-1、R-4）か猫の絵（ネコノホンシツジ。PRD E-12）。言葉を出すアプリは多いが、出すのは選んだ名言や引用で、読書の記録と入口につながらない（R-13）。こちらは自分の紙の本の、昨夜止めた一行とページで、言葉がそのまま続きの位置（しおり）になり、押すとその本の読書が始まる入口になる。
    - 根拠：HIG の「Provide useful information in your Lock Screen widget」（R-18）と「Create defining moments.」（R-23）、Flighty の「With key information where you need it most」（R-15）。
    - 弱い所：一行が古いか空の夜が続くと、書名とページだけになり、ほかと同じになる（PRD I-4）。見た目は名言のウィジェットに似る（R-13）ので、差は見た目でなく中身にある。ストアの画面写真は、実際の 172×76 pt の大きさで見せる（PRD 17）。
  - D-2 読み終えた夜だけの「奥付と次の1冊」
    - どこで：読み終えた画面（数週間に1回）。毎晩の道には出さない。
    - 何が違うか：ブクログとネコノホンシツジは、おすすめをいつでも出す（ブクログへの不満「好きでもない表紙の絵をここ数年毎回見せられること」R-9、ネコノホンシツジ「猫がおすすめしてくれます」R-6）。Bookmory は読み終えを紙吹雪で祝う（R-4）。こちらは読み終えた夜にだけ、奥付（日本の本の最後のページの型）と、自分の積読からの次の1冊を事実の理由1行つきで出し、祝う演出を置かない。
    - 根拠：HIG の「Use concepts that people know.」「Don’t mistake delight for decoration.」（R-23）、Rams の「Good design is honest」（R-35）。
- 差にしないもの
  - 伏せて読む：2018年から先行がある（PRD E-13）。性格語「紙の側」の表れとして扱い、違いの芯にはしない（PRD 5 の S-5 と同じ扱い）。
  - 縦書きの見た目だけ：明朝の言葉のウィジェットはすでにある（R-13）。
- 「一行と書名を出さない」設定で、HIG が言っていること（仕様の判断に渡す）
  - Live Activity：「Avoid displaying sensitive information. Live Activities are prominently visible and could be viewed by casual observers」で、当たり障りのない要約を出すように勧める（R-20）。
  - Control：ロック中は、システムに題と値を隠させることを勧める（「Hide sensitive information when the device is locked.」R-21）。
  - Siri：「Siri may also respond aloud, and others nearby might hear the response」（R-22）。

## 7. 方向性の2案
| | 案A 紙の版面 | 案B 夜の灯り |
|---|---|---|
| ひとことで | 白、黒、灰と、縦書きの明朝の一行だけ。標準部品と、タブのない1画面。ライトとダークはシステムに従う。design/explore/integrated/ の探りの絵（Takuma が見たもの）の方向 | いつも暗い地に、灯りのような暖色をアクセントにし、時刻で地の色を変える。Live Activity と StandBy を主役にして、夜の雰囲気を作る |
| 性格語との合い方 | 「静か」「確か」「まっすぐ」「紙の側」に強い。「急かさない」は、出す時と出さないもので表す | 「静か」「急かさない」には合う。色を意味なしに使う（B-5）ので、「確か」「まっすぐ」に弱い。時刻で見せ方を変えるのは、ウィジェットを時刻で切り替えない決まり（PRD 10）とぶつかる |
| ターゲットとの合い方 | 暗い部屋はダークで受ける。ロック画面で色が抜けても、一行の形が残る（R-19）。4本の競合のどれとも見た目が重ならない（R-2、R-4、R-6、R-8） | 夜の場面には合う。ただ、いちばん目に触れるロック画面と暗い所の StandBy では、色が抜けるか赤の単色になり（R-19）、案の個性が入口に届かない。ToRead の生成りと濃紺と淡い橙（R-2）に近く、埋もれる |
| 選んだか、その理由 | 選ぶ。入口の制約（R-19）の中で個性が残り、性格語の5語すべてに合う | 選ばない。理由は、入口で色が届かないこと（R-19）、色を意味なしに使うこと（B-5）、ToRead に近いこと（R-2）。夜らしさは、案A のダークの地と、Live Activity の「待つ → 読む → 結果」の3つの状態で出す |

## 8. 発見の一覧
| R | 発見（引用は「」で） | 出典 URL | 確認日 |
|---|---|---|---|
| R-1 | ToRead（JP 3件、平均5.0、版 1.1.0）の説明文と更新内容：「ワンタップで読書開始」「邪魔にならないミニマルインターフェース」「ToReadは静かに読書時間を記録するので、ゲーミフィケーション、連続記録、競争なしで習慣を把握できます。」「ロック画面とDynamic Islandでの読書時間の表示（ToRead Plus）」「ホーム画面とロック画面の週間ウィジェット（ToRead Plus）」「優しいリマインダーは、すでに読んだ日には届きません」「誤って『終了』を押しても読書を続けられ、間違えて始めたセッションは取り消せます」「Siriとショートカットがお使いの言語に対応し、一時停止と再開もできます」「『本』ページ：本ごとの読書時間、セッション、残した一文」 | https://apps.apple.com/jp/app/toread-%E8%AA%AD%E6%9B%B8%E3%82%BF%E3%82%A4%E3%83%9E%E3%83%BC/id6757129946 （説明文は https://itunes.apple.com/lookup?id=6757129946,1515533482,359066582,509979590,6792955764,6752113848&country=jp で取得） | 2026-10-19 |
| R-2 | ToRead の画面写真6枚：1枚目は生成りの地に「座って。ただ、読む。」と中央の「読む」、2枚目は濃紺の地に「流れるのは時間。数字ではなく。」と細く大きな「23:46」と「一時停止」「終了」、3枚目「窓を打つ雨の音。」と音の選択、4枚目「読書は終わる。一文は残る。」と「23 分」、5枚目「読んだ時間は、ここにある。」と「31分 こころ」の行、6枚目「静かな気づき。点数はつかない。」と週の「31 分」。見出しは明朝に近い書体で一部が淡い橙。タブバーは写っていない。ロック画面の表示の画面はない | https://apps.apple.com/jp/app/toread-%E8%AA%AD%E6%9B%B8%E3%82%BF%E3%82%A4%E3%83%9E%E3%83%BC/id6757129946 の画面写真（https://itunes.apple.com/lookup?id=6757129946,1515533482,359066582,509979590,6792955764,6752113848&country=jp の screenshotUrls の6枚） | 2026-10-19 |
| R-3 | ToRead のレビューの本文は JP の RSS で0件 | https://itunes.apple.com/jp/rss/customerreviews/page=1/id=6757129946/sortby=mostrecent/json | 2026-10-19 |
| R-4 | Bookmory（JP 189件、平均4.72、版 1.4.26）の説明文：「強力な読書タイマー、カレンダー表示、詳細な読書統計で、モチベーションを保つのがこれまでになく簡単になります。」「ロック画面やDynamic Islandでタイマーを確認」「連続読書（ストリーク）で読書習慣をキープ」。画面写真（10枚のうち7枚）：「シンプルだが完全読書管理」、表紙の並ぶ Book Calendar、紙吹雪と「Congratulations! You're all done!」、「Welcome :)」「What book did you read today?」、青い地のタイマー「00:15」「Reading...」と一時停止と「Save」、「美しい背景でメモを保存します。」（桃色の山の背景）。タブバーは写っていない | https://apps.apple.com/jp/app/id1515533482 （R-1 の lookup） | 2026-10-19 |
| R-5 | Bookmory の不満：JP「ただ、9月発売の本を検索しても見つからないのは少し困ります。そして、バーコードの読み取りに失敗した場合、フリーズする場合があります。」（2024-10-13 ★3）。US「The two seperate pop ups you have to close out of EVERY time you open this app are horrid.」（2026-09-07 ★1）、「It’s very annoying that every time I go in to log finishing a book that I’ve always started a one day streak.」（2026-10-12 ★1）、「This app has so little to offer compared to how many ads it forces on you」（2026-09-11 ★1）。JP は34件中星3以下3件、US は50件中5件 | https://itunes.apple.com/jp/rss/customerreviews/page=1/id=1515533482/sortby=mostrecent/json 、https://itunes.apple.com/us/rss/customerreviews/page=1/id=1515533482/sortby=mostrecent/json | 2026-10-19 |
| R-6 | ネコノホンシツジ（JP 308件、平均4.60、版 2.1.10）の説明文：「可愛い猫と一緒に本を読みながら読書タイマーを活用してみてください。」「一般検索はもちろん、手動追加とバーコード認識まで対応しており、本の登録がとても簡単です。」「どの本を読めばいいか分からない時は?猫がおすすめしてくれます。」。画面写真（8枚のうち7枚）：「猫と過ごす、読書のたのしみ」（線画の猫と、下の札「猫と読書中…」「一時停止」「読書終了」「文章収集」）、表紙の並ぶカレンダー、「心に残った文章を逃さない」（写真の文字を選ぶ）、表紙の棚、「次に読む本が見つかる」。下にタブが5つ | https://apps.apple.com/jp/app/id6752113848 （R-1 の lookup） | 2026-10-19 |
| R-7 | ネコノホンシツジの不満（page=1 の31件のうち星3以下6件。どれも★3）：「でも、検索してもヒットしない本が多くてなかなか他の管理アプリから移行しきれない。」（2026-10-03）、「可愛くて使いやすいんだけど、アップデートが多い。頻回すぎて面倒。」（2026-07-12）、「時間の編集機能もつけてほしい。すぐ忘れて読書時間10時間‼️とかになってしまう」（2025-12-26）。PRD にある広告の不満（2026-09-08 ★2）は、この日の page=1 には見つからなかった | https://itunes.apple.com/jp/rss/customerreviews/page=1/id=6752113848/sortby=mostrecent/json | 2026-10-19 |
| R-8 | ブクログ（JP 28,267件、平均4.54、版 14.1.1）の説明文：「連続スキャン対応でまとめて登録もOK」「話題の本・ランキング・本屋大賞などもアプリ内でチェック可能」「読書履歴や評価に応じたおすすめ本も自動で提案」「キーワードや著者を登録しておけば新刊通知が届く」。画面写真（10枚のうち7枚）：水色の地に「話題の本から気になる1冊に出会える」「感想・レビューから次に読みたい本が見つかる」「バーコードを読み取り本をサクサク登録」（赤い枠と一覧）「読書傾向をグラフで振り返り」「新刊情報をいち早くお届け！」「ウィジェットで手軽に読書記録！」（ロック画面に「バーコードで本を登録」「本を検索」を開くウィジェット）。下にタブが5つ | https://apps.apple.com/jp/app/id359066582 （R-1 の lookup） | 2026-10-19 |
| R-9 | ブクログの不満（page=1 と page=2 の100件のうち星3以下39件。先頭の24件を読んだ）：「一番不満なのが、オススメの本というお題目で、好きでもない表紙の絵をここ数年毎回見せられること。全く更新されることもないから」（2026-08-29 ★1）、「バーコードで本登録できんくなった」（2026-05-19 ★1）、「カメラへのアクセスを許可する項目が出てこず利用できない。」（2025-12-22 ★1）、「バーコードを全ッ然読み取ってくれず、課金誘導っぽいエラー表記も併せて表示されてイライラしたので5分でアンスコした。」（2025-12-14 ★1）、「とても使いやすいけれど、有料化が進みすぎている。」（2026-06-13 ★3）、「何故ユーザーの感想を勝手にAIに読み込ませ要約しようなど思ったのですか？」（2026-02-27 ★1） | https://itunes.apple.com/jp/rss/customerreviews/page=1/id=359066582/sortby=mostrecent/json 、https://itunes.apple.com/jp/rss/customerreviews/page=2/id=359066582/sortby=mostrecent/json | 2026-10-19 |
| R-10 | 読書メーター（JP 7,190件、平均4.47）の説明文：「◆バーコード連続読取で 登録も簡単」「・連続読み取り機能で手間いらず！」 | https://apps.apple.com/jp/app/id509979590 （R-1 の lookup） | 2026-10-19 |
| R-11 | mekuru（JP 373件、平均4.69、版 6.0.0）のレビュー：「SNSに疲れる日々ですが、いいねやコメントなどもなく、とても落ち着くし集中できます。」（2026-09-23 ★4）、「これを開きたくて、勝手に読書時間が増えました笑」（2026-09-26 ★5）、「画面閉じれるようにして欲しい」（2026-09-23 ★3）、「スマホを見ると『2時間何の操作も行われなかったため終了しました』というような内容が表示されており」（2026-09-24 ★1） | https://itunes.apple.com/jp/rss/customerreviews/page=1/id=6792955764/sortby=mostrecent/json （評価の数は R-1 の lookup） | 2026-10-19 |
| R-12 | Forest のレビュー：「豪華なデザインとかアニメーションとか要らない」（2026-10-09 ★1）、「作業終了時に余計なアニメーションやひと手間が増えており」（2026-10-13 ★1）、「集中アプリとして全く不要な演出や機能が無駄に追加され」（2026-09-27 ★1） | https://itunes.apple.com/jp/rss/customerreviews/page=1/id=866450515/sortby=mostrecent/json | 2026-10-19 |
| R-13 | ロック画面とウィジェットに言葉を出すアプリ（説明文）：Kotoba（2026-08-05 公開）「本の一文、映画や推しのセリフ、自分と決めた約束。」「ウィジェットに好きな一つを固定表示（ホーム画面の小・中・大、ロック画面の3種）」「書体（ゴシック／明朝／丸ゴシック）」。名言ウィジェット（JP 92件）「iPhoneのホーム画面・ロック画面・スタンバイに表示できる名言アプリ」。ことばめくり（2026-10-04）「日本の文学と古典の言葉が毎朝ひとつ」「充電中に横置きしたスタンバイ画面にも出る」。よみかえし：読書記録・引用カード「その一文を撮って残し、毎日1枚あなたのもとへ返す」「日本語の縦書きにも対応しています」「ホーム画面ウィジェット：今日の1枚をホーム画面に表示」。hanjul-note「お気に入りの一文を記録し、ウィジェットでいつでも再び出会えるアプリ」。WordDrop「本で見つけた言葉を、カメラで保存。ウィジェットで何度も振り返れる読書メモアプリ」。Kotoba の画面写真3枚は、ホーム画面の言葉のウィジェットと編集の画面（ロック画面の画面はない） | https://itunes.apple.com/search?term=%E5%90%8D%E8%A8%80%20%E3%83%AD%E3%83%83%E3%82%AF%E7%94%BB%E9%9D%A2&entity=software&country=jp&limit=10 、https://itunes.apple.com/search?term=%E8%AA%AD%E6%9B%B8%20%E3%82%A6%E3%82%A3%E3%82%B8%E3%82%A7%E3%83%83%E3%83%88&entity=software&country=jp&limit=15 、https://itunes.apple.com/search?term=%E3%82%88%E3%81%BF%E3%81%8B%E3%81%88%E3%81%97&entity=software&country=jp&limit=5 | 2026-10-19 |
| R-14 | Flighty – Live Flight Tracker（JP 1,569件、平均4.75、版 4.11.1）：説明文「Lock screen widgets (limited refresh for costs)」「Live lock screen widgets」、更新内容「A refined Dynamic Island, flight answers from Siri, and two new looks for your Home Screen.」「“Hey Siri, ask Flighty, what's the status of my flight?”」。画面写真（10枚のうち4枚）：「Apple Design Award」「Winner 2023」、「Live Activities」「Dynamic Island」「Track your flight status on your lock and home screen」と、ロック画面の「1h 20m UNTIL GATE ARRIVAL」「Departs Gate in 45m」 | https://apps.apple.com/jp/app/id1358823008 （説明文は https://itunes.apple.com/lookup?id=1358823008&country=jp で取得） | 2026-10-19 |
| R-15 | Apple Design Awards 2023 の Interaction 部門：「Winners in this category deliver intuitive interfaces and effortless controls that are perfectly tailored to their platform.」。受賞の APP は Flighty で、紹介文は「Flighty is a beautifully designed flight tracker, travel planner, airport navigator, and concierge.」「With key information where you need it most, an intuitive interface, comprehensive live maps, and a look that mirrors time-honored airport design conventions, Flighty might be the easiest part of your whole trip.」 | https://developer.apple.com/design/awards/2023/ | 2026-10-19 |
| R-16 | Flighty の不満（US の page=1 の50件のうち星3以下17件）：「Flighty is genuinely well designed, but the constant popups pushing the Pro subscription make it a chore to use.」（2026-10-06 ★3）、題「Broken. Flood of worthless notifications」（2026-10-13 ★1） | https://itunes.apple.com/us/rss/customerreviews/page=1/id=1358823008/sortby=mostrecent/json | 2026-10-19 |
| R-17 | Moonlitt: Moon Phase Tracker（US 950件、平均4.66、版 2.10）：「Widgets, Apple Watch app, and Live Activity for moon phase, moonrise, and moonset.」「Refined widgets, Live Activities, and StandBy for the new displays.」 | https://itunes.apple.com/search?term=moonlitt&entity=software&country=us&limit=3 | 2026-10-19 |
| R-18 | HIG Widgets：「Provide useful information in your Lock Screen widget, and don’t treat it as an additional way for people to launch into your app.」「Your app can offer widgets on the Lock Screen in three different styles: as inline text that appears above the clock, and as circular and rectangular shapes that appear below the clock.」「Balance information density. Sparse layouts can make the widget seem unnecessary, while overly dense layouts are less glanceable.」「Ensure that a widget interaction opens your app at the right location.」「Use the standard margin width for widgets — 16 points for most widgets」 | https://developer.apple.com/design/human-interface-guidelines/widgets （本文は https://developer.apple.com/tutorials/data/design/human-interface-guidelines/widgets.json で読んだ） | 2026-10-19 |
| R-19 | HIG Widgets の描き方：「The system uses the vibrant rendering mode for widgets on the Lock Screen of iPhone and iPad, and on iPhone in StandBy in low-light conditions. It desaturates text, images, and gauges」「On iPhone in StandBy, the system displays two small system family widgets side-by-side, scaled up so they fill the Lock Screen.」「When the ambient light falls below a threshold, the system renders the widget with a monochromatic red tint.」「Limit usage of rich images or color to convey meaning in StandBy. Instead, make use of the additional space by scaling up and rearranging text so people can glance at the widget content from a greater distance.」 | https://developer.apple.com/design/human-interface-guidelines/widgets （R-18 と同じ JSON で読んだ） | 2026-10-19 |
| R-20 | HIG Live Activities：「Offer Live Activities for tasks and events that have a defined beginning and end. Live Activities work best for tracking short to medium duration activities that don’t exceed eight hours.」「Avoid displaying sensitive information. Live Activities are prominently visible and could be viewed by casual observers」「Focus on simple, direct actions.」「Use large, heavier-weight text — a medium weight or higher.」「Offer an App Shortcut that starts your Live Activity.」「Alert people only for essential updates that require their attention.」「The standard layout margin for Live Activities on the Lock Screen is 14 points.」「On iPhone in StandBy, your Live Activity appears in the minimal presentation. When someone taps it, it transitions to the Lock Screen presentation, scaled up by 2x to fill the screen.」、動きは「a maximum duration of two seconds」 | https://developer.apple.com/design/human-interface-guidelines/live-activities （JSON で読んだ） | 2026-10-19 |
| R-21 | HIG Controls：「On the Lock Screen, a control displays its symbol.」「Choose a descriptive symbol that suggests the behavior of the control.」「Provide hint text for the Action button.」「Use verbs to construct the hint text.」「Hide sensitive information when the device is locked.」。HIG Action button：ラベルは「begin with a verb, use present tense, and exclude articles and prepositions. Keep labels as short as possible, with a maximum of three words.」「Prefer letting the system show people how to use the Action button with your app.」 | https://developer.apple.com/design/human-interface-guidelines/controls 、https://developer.apple.com/design/human-interface-guidelines/action-button （JSON で読んだ） | 2026-10-19 |
| R-22 | HIG App Shortcuts：「Keep voice interactions simple.」「You have to include your app name, but you can be creative with it.」「Make App Shortcuts discoverable in your app.」「Consider showing occasional tips in your app when people perform common actions」。HIG Siri：「Keep responses as succinct as possible.」「Avoid including unnecessary words or attempts at humor」「Omit your app name from responses.」「Be aware that Siri may also respond aloud, and others nearby might hear the response」「Provide responses that Siri can deliver audibly and visually.」 | https://developer.apple.com/design/human-interface-guidelines/app-shortcuts 、https://developer.apple.com/design/human-interface-guidelines/siri （JSON で読んだ） | 2026-10-19 |
| R-23 | HIG Design principles：「Find new ways to solve the problem. Investigate existing solutions, and avoid re-creating them. Define what sets your product apart」「Help people recover from mistakes.」「Use concepts that people know.」「Identify the emotion you want to inspire.」「a meditation app might calm」「Create defining moments.」「Don’t mistake delight for decoration.」 | https://developer.apple.com/design/human-interface-guidelines/design-principles （JSON で読んだ） | 2026-10-19 |
| R-24 | HIG Accessibility のコントラストの表（「Up to 17 pts」は 4.5:1、「18 pts」は 3:1、「Bold」は 3:1）、押せる範囲「44x44 pt」、「If your app supports dark-mode, make sure to check the minimum contrast in both light and dark appearances.」。HIG Typography：「avoid Ultralight, Thin, and Light font weights」「Keep text truncation to a minimum as font size increases.」「Consider adjusting your layout at large font sizes.」「consider using a stacked layout」 | https://developer.apple.com/design/human-interface-guidelines/accessibility 、https://developer.apple.com/design/human-interface-guidelines/typography （JSON で読んだ） | 2026-10-19 |
| R-25 | HIG Materials：「Liquid Glass forms a distinct functional layer for controls and navigation elements」「Don’t use Liquid Glass in the content layer.」。HIG Color：「Avoid using the same color to mean different things.」「Make sure all your app’s colors work well in light, dark, and increased contrast contexts.」。HIG Dark Mode：「The color palette in Dark Mode includes dimmer background colors and brighter foreground colors.」 | https://developer.apple.com/design/human-interface-guidelines/materials 、https://developer.apple.com/design/human-interface-guidelines/color 、https://developer.apple.com/design/human-interface-guidelines/dark-mode （JSON で読んだ） | 2026-10-19 |
| R-26 | HIG Writing：「Determine your app’s voice.」「Match your tone to the context.」「Be clear.」「Be action oriented.」「When labeling buttons and links, it’s almost always best to use a verb.」「Provide clear next steps on any blank screens.」「Write clear error messages.」「display it as close to the problem as possible, avoid blame, and be clear about what someone can do to fix it.」 | https://developer.apple.com/design/human-interface-guidelines/writing （JSON で読んだ） | 2026-10-19 |
| R-27 | HIG Privacy：「Request permission only when your app clearly needs access to the data or resource.」、許可の前の画面は「Include only one button and make it clear that it opens the system alert.」「Never precede the system-provided alert with a custom screen or window that could confuse or mislead people.」。HIG Onboarding：「design a flow that’s fast, fun, and optional」 | https://developer.apple.com/design/human-interface-guidelines/privacy 、https://developer.apple.com/design/human-interface-guidelines/onboarding （JSON で読んだ） | 2026-10-19 |
| R-28 | HIG Playing haptics：「Use system-provided haptic patterns according to their documented meanings.」「Avoid overusing haptics.」「In most apps, prefer playing short haptics that complement discrete events.」「Make haptics optional.」 | https://developer.apple.com/design/human-interface-guidelines/playing-haptics （JSON で読んだ） | 2026-10-19 |
| R-29 | WCAG 2.2 の 2.5.4 Motion Actuation（Level A）の解説：「Content is not dependent on a user's ability to move a device.」「Don't rely solely on device motion to control page content.」、本文は動きで動く機能が「also be operated by user interface components and responding to the motion can be disabled to prevent accidental actuation」であることを求める | https://www.w3.org/WAI/WCAG22/Understanding/motion-actuation.html | 2026-10-19 |
| R-30 | W3C Requirements for Japanese Text Layout（JLREQ）：節「行頭禁則」「Characters Not Ending a Line 行末禁則」「Positioning of Closing Brackets, Full Stops, Commas and Middle Dots」と、「In vertical writing mode, the letter face of small kana (cl-11) characters (ぁぃぅァィゥ etc.) is placed at the vertical center and to the right of the horizontal center of the character frame」 | https://www.w3.org/TR/jlreq/ | 2026-10-19 |
| R-31 | NN/g の文言の調子の4軸：「Formal vs. casual」「Serious vs. funny」「Respectful vs. irreverent」「Matter-of-fact vs. enthusiastic」 | https://www.nngroup.com/articles/tone-of-voice-dimensions/ | 2026-10-19 |
| R-32 | NN/g：「Brand intention (the way a company attempts to construct its identity) and Brand interpretation (the way customers experience a Brand).」、性格は「a set of traits that inform everything from product or service development to identity systems」 | https://www.nngroup.com/articles/brand-intention-interpretation/ | 2026-10-19 |
| R-33 | NN/g の空の状態：「Empty states provide opportunities for designers to communicate system status, increase learnability of the system, and deliver direct pathways for key tasks.」 | https://www.nngroup.com/articles/empty-state-interface-design/ | 2026-10-19 |
| R-34 | Reinecke と Gajos（CHI 2014）「Quantifying Visual Preferences Around the World」：「the level of colorfulness and visual complexity at which visual appeal is highest strongly varies: Females, for example, liked colorful websites more than males.」「A high education level generally lowers this preference for colorfulness.」 | https://eecs.harvard.edu/~kgajos/papers/2014/reinecke14visual.shtml | 2026-10-19 |
| R-35 | Dieter Rams の10原則：「Good design is honest It does not make a product more innovative, powerful or valuable than it really is.」「Good design is unobtrusive Products fulfilling a purpose are like tools.」「Good design is as little design as possible Less, but better」 | https://vitsoe.com/gb/about/good-design （https://www.vitsoe.com/gb/about/good-design に移った） | 2026-10-19 |

見られなかったもの
- どのアプリも入れて使っていない。タップ数、ナビゲーション、最初の価値までの画面数、空の状態、権限の求め方は、画面写真と説明文に出ているものしか見ていない（3 の表の「見ていない」）。
- 画面写真のうち見たのは、ToRead 6枚、ネコノホンシツジ 7枚（8枚中）、Bookmory 7枚（10枚中）、ブクログ 7枚（10枚中）、Kotoba 3枚、Flighty 4枚（10枚中）。読書メーター、mekuru、Moonlitt、名言ウィジェット、ことばめくり、よみかえし、hanjul-note、WordDrop の画面は見ていない（説明文だけ）。
- ToRead のロック画面と Dynamic Island の表示（Plus）、ネコノホンシツジのロック画面の読書カード、Kotoba のロック画面のウィジェット、Flighty の Live Activity の動き。
- ToRead の「背面タップ」の記載（PRD E-12 が 10-18 に製品ページで読んだもの）は、10-19 の lookup の説明文には見つからなかった。製品ページの HTML は開いていない。
- HIG Widgets の大きさの表（172×76 pt、いちばん小さい機種で 153×68 pt）は、今回 JSON から取り出した文字には見つからなかった。PRD E-9 の値（verifier と tech-lead が読んだもの）を使う。
- ADA 2026 のページ（Moonlitt の受賞）は、10-19 に開き直していない（integrate-designer が 10-18 に読んだもの）。
- 伏せるタイマー（FLIP、ベアフォーカスタイマー、Offshelf ほか）は、10-19 に開き直していない（PRD E-13）。
- 審査ガイドラインの本文（PRD 17 の引用だけ）。
- NN/g のブランドの記事は、定義の文だけを読んだ。性格語の数の目安は見つけていない（3〜5語は手引きの決まり）。
- 文化庁の調査（PRD E-1）と積読の調査（E-7）は、10-19 に開き直していない。
- 実機。秒数はすべて見積もり。Takuma の実機の確かめ（伏せた向き、ロック中のボタン）の結果は、まだ届いていない（1 の「結果待ち」）。

## 確かめ（提出前に designer が印を付ける。design-reviewer はこれを信じずに確かめる）
- [x] R が5つ以上あり、どれにも出典 URL と確認日がある（R-1〜R-35。確認日はすべて 2026-10-19）
- [x] 競合を2つ以上と、手本を1つ調べた。不満は引用と URL 付き（競合は ToRead、Bookmory、ネコノホンシツジ、ブクログ。手本は Flighty。ToRead はレビューの本文が0件で、不満の記録なし）
- [x] ターゲットは「仮説」と書き、根拠に R 番号がある
- [x] 性格語ごとに「意味しないこと」がある
- [x] 差をつける点が1から2個ある（D-1 手に取った瞬間の「続き」、D-2 読み終えた夜だけの「奥付と次の1冊」）
- [x] 方向性の2案と、選ばなかった理由がある
