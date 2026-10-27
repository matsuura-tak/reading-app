（指揮役の注）判定（reviewer、観点：設計、r1）。対象は tech-lead の調べもの（docs/reviews/001-reading-session-ai-tech-lead.md）の判断1（端末の AI のあらすじを v1 に入れない）と判断2（課金は全機種で動く価値に付ける）。報告の文はそのまま保存した。報告の末尾の「記録」は reviewer 自身が書いたもので、指揮役の記録はそのあとに足した。

FAIL

## 判断ごとの判定
| 判断 | 判定 | ひとことで |
|---|---|---|
| 1. 端末の Foundation Models で「前回のあらすじ」を作るのは、今の品質では難しい。v1 に入れない | PASS（文を作らせる形について） | fm.log の36件を全部読み直しました。はっきりした誤りは22件で、tech-lead の数と同じです。境界の5件を軽いずれに回しても17件（47%）です。OCR の崩れのない文でも、8回中6回に誤りが出ました。同じモデルでの検査を足しても、出す文の23%に誤りが残ります。ただし「端末の AI を v1 に入れない」まで広げる根拠はありません（指摘1） |
| 2. 課金はどの機種でも動く価値に付け、AI は対応機種での上乗せにとどめる | PASS（筋は通る） | 届く人の数（2026年8月で iPhone 利用者の約4〜5割）と品質で支えられます。ただし審査の理由付けは違います。3.1.2 は定期課金だけの決まりです（指摘5）。有料の中身に入れた「辞書」は、4.10 に当たるおそれがあります（指摘3） |

- 全体を FAIL にした理由：直さないと通さない指摘が3件あります。iPhone、本物の紙、PCC での確かめもできていません（未検証）。
- 判断1の PASS について：未検証の3つは、結果が今と同じか悪くなる向きにしか効かない見込みです［推測］。そのため「入れない」という判断は崩れないと見ています。iPhone で品質が良くなるという根拠は見つかりませんでした。
- 指示書のあとに f79117a が入りました。Takuma は「端末の AI（前回のあらすじ）を最初の版に入れない」「主はポートフォリオ」「有料の中身に読む手すり」と決めています。下の指摘はこの決定を覆すものではありません。PRD r2 と G1 で直す点、または指揮役が Takuma に伝え直すかを決める点として書いています。

## 指摘
### 指摘1　直さないと通さない（重大）：結論が証拠より広い
文を作らせない形を試していないのに、「端末の AI を入れない」としています。
- 場所
  - /Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-ai-tech-lead.md:10（結論5「AI は対応機種での上乗せにとどめ、v1 には入れない」）
  - 同じファイルの :15〜19（表には A1〜A3 しかない）と :47（grounded を「ほぼ抜き書きするだけ」として退けた）
  - /Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-money-ai-proposal.md:15、:47、:97〜99
  - /Users/takumamatsuura/reading-app/docs/approvals/001-reading-session-G0-Q8.md の「追加の決定」（f79117a）にある「端末の AI は v1 に入れない」
- 理由と証拠
  - spike で試したのは、モデルに文を作らせる形だけです。
  - tech-lead の作業メモ /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ai-tech/notes.md の49行目には、「あらすじ（抜き書き＝grounded の引用だけ見せる）：条件付き、M」とあります。報告の表では、理由を書かずに消えています。
  - 私は抜き出しの形を試しました（証拠の［R2］の B）。本文の文に番号を付けて渡し、番号を3つ選ばせる形です（`.count(3)` と `.element(.range(1...80))`）。
    - 12回中12回が有効でした（範囲内で重複なし）。時間は0.97〜1.84秒です（Mac）。
    - 出すのは本文の文そのものなので、作り話は形の上で0です。
  - 弱みもあります。
    - 毎晩撮る1ページだけなら、最後の3文（A2）との重なりは3文中2文でした。ほぼ A2 と同じです。
    - 見開きや3ページでは重なりが0で、前半の文に寄ります。「『遥へ。」のような中身の薄い文も選びました。
    - A2 より役に立つかは確かめていません。
  - 証拠が支えるのは「文を作らせるあらすじは入れない」までです。「端末の AI を v1 に入れない」までは支えられません。
- 直し方の案
  - tech-lead の表に A4 を足します。中身は「抜き出し（番号で選ばせ、本文の文をそのまま出す。対応機種だけ。使えない機種は A2）」です。
  - A4 の判定は「作れる（Mac で 12/12）。1枚なら A2 とほぼ同じ。数晩分をまとめると差が出る。価値は未検証」とし、負担は S〜M とします。
  - 決定の文は「端末の AI に文を作らせる機能は v1 に入れない」に狭めます。
  - Takuma の答え（3：入れない）は、作る形のあらすじへの答えとして残します。抜き出しを別の問いとして出すかは指揮役が決めます。Takuma が「主はポートフォリオ」と決めたので、この問いの重みは上がっています。

### 指摘2　直さないと通さない（重大）：まとめの「いちばん強い反論」が、推す案への反論になっていない
- 場所
  - /Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-money-ai-proposal.md:75〜83（4）と :97〜99（6-3）
  - f79117a で Takuma に伝えた前提（「spike で出力の61%に本文と違う事実が入った」）
- 理由と証拠
  - 4 の2「ローカル AI は、今の品質では売りにできません」は、推す案を支える理由です。推す案（AI を入れない）への反論になっていません。
  - 「AI を入れない」へのいちばん強い反論は、どこにも書かれていません。6-3 の反論も「見どころに入らない」の1行だけです。
  - 61% は、ばらばらに36回試した率ではありません（［R1］の出力）。
    - 誤りの型の内訳は「父や店の取り違え」8件、「翌朝」4件、「見せた」の主語3件、「金庫」2件で、残りは各1件です。
    - 22件のうち14件が、この3つの型の繰り返しです。
    - 金庫の2件は、同じ設定（greedy）から出た同じ文です。
  - 境界の5件を軽いずれに回すと、17/36（47%）になります。境界の5件は「遥の店」型3件、「現像を依頼する」、「売却を相談」です。
  - 使った文は、前の体が書いた合成の物語1つ（3ページ）と、事件の場面1つです。Mac で試し、判定したのは1人で、誤りの基準も書かれていません。
- 直し方の案
  - 4 の2を次の反論に書き換えます。「spike は合成の4場面、Mac、判定は1人。誤り22件のうち14件は3つの型の繰り返し。文を作らない抜き出しは試していない（reviewer の試しでは作れた）。Takuma が頼んだローカル AI が v1 にない」。
  - 61% は「36件中22件（4場面×3つの出させ方。厳しく数えると17件）」と書きます。
  - Takuma に伝え直すかは指揮役が決めます。

### 指摘3　直さないと通さない（重大）：有料の「辞書」が審査ガイドライン 4.10 に当たるおそれ
- 場所
  - /Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-money-ai-proposal.md:66（有料の「読む手すり：読みがな、辞書、続きを声で」）
  - /Users/takumamatsuura/reading-app/docs/approvals/001-reading-session-G0-Q8.md の「追加の決定」（有料の中身に読む手すり）
  - /Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-ai-designer.md:214（「言葉の手帳（標準の辞書）」を有料にしている）
- 理由と証拠
  - 4.10 の文（2026-10-18 に開いた）："You may not monetize built-in capabilities provided by the hardware or operating system, such as Push Notifications, the camera, or the gyroscope; or Apple services and technologies, such as Apple Music access, iCloud storage, or Screen Time APIs."
  - 辞書（UIReferenceLibraryViewController）は、端末の辞書の画面を出すだけです。定義の文は取り出せません（tech-lead 報告:21、:64）。
  - アプリが足す価値がないので、ここに課金の壁を置くと、OS の機能に値段を付ける形にいちばん近くなります。
  - 読み上げと読みがなも OS の機能を使います。ただ、撮った文からルビを除く、撮ったページに重ねて出す、というアプリの処理が乗るので、辞書より危うさは低いです。
  - 審査で実際にどう扱われるかは確かめていません（未検証）。
- 直し方の案
  - PRD r2 で、辞書の画面は無料の側に置きます。
  - 有料にするのは、アプリが足す処理です（撮ったページに重ねる読みがな、ルビを除いた読み上げ、言葉の手帳の記録と並べ替え）。
  - 値段を決める前に App Review に問い合わせる手順を、PRD に書きます。

### 指摘4　直すとよい（要修正）：「見直す道」に、誤りの原因を直さない道が入っている
- 場所：/Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-money-ai-proposal.md:47（見直す道は PCC、OS の更新、ページの写真を直接渡す形）
- 理由と証拠
  - きれいな文での試し（［R2］の A）
    - OCR の崩れのない文（p3、p2+p3）を、同じ指示で8回まとめさせました。8回中6回に、はっきりした誤りが出ました。
    - 内訳は「祖母の名前を尋ねた」2回（本文では告げた）、「遥の父の店」1回、「翌朝、灯台守の家を訪れた」3回です。
    - 崩れを消しても、誤りの主な原因（誰の、いつ、誰が）は残ります。写真を直接渡しても、良くてきれいな文と同じなので、直らない見込みです［推測］。
  - 同じモデルでの検査（作った文が本文と合うかを、同じモデルに聞く形）
    - 出力まるごとで検査すると（［R3］）、誤り22件のうち11件が通りました。通ったものだけ出しても、出す23件のうち11件（48%）に誤りが残ります。
    - 1文ずつ検査すると（［R4］）、誤りの文23のうち8が通りました。出す35件のうち8件（23%）に誤りが残り、正しい文48のうち14を落としました。
    - 見逃したのは、主語のない文（「翌朝、灯台守の家を訪ねた。」「若い男の写真を見せた。」）です。
    - 自分で書いた1文だけの検査（［R2］の D）は 11/12 でしたが、本物の出力では大きく下がりました。D の数字は根拠に使いません。
  - 決まった形で出させたときの、止まらない出力
    - 正規表現の @Guide で防ぐ道は使えませんでした。10回とも UnsupportedGuide です（［R2］の C）。
- 直し方の案
  - 見直す道を「PCC（大きいモデル）、抜き出し、1文ずつの検査と主語を必ず書かせる指示」に替えます。
  - 見直すときの合格の線を先に決めます。案は「本物の文庫20晩分で、出した文のはっきりした誤りが1件以下」です。
  - v1 は iOS 26 から（Q8）です。今回の数字はすべて macOS 27 のモデルなので、iOS 26 のモデルでも同じ線で測ります。

### 指摘5　直すとよい（要修正）：判断2の、審査ガイドラインの理由付けが違う
- 場所
  - /Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-ai-tech-lead.md:27 と :95
  - /Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-ai-direction-pdm.md:354
- 理由と証拠（どれも 2026-10-18 に開いた）
  - 3.1.2(a) は、自動更新の定期課金だけの決まりです："Subscriptions must work on all of the user's devices where the app is available."
    - PRD:194 は、iPad で互換表示のまま動くことを止めていません。AI だけを中身にした定期課金なら、対応しない iPad では働かず、この文に当たります。
  - 決まった買い切り（非消耗型）には、3.1.2 は当たりません。当たるのは次の2つです。
    - 2.3 "Customers should know what they're getting when they download or buy your app"
    - 2.3.2 "clearly indicate whether any featured items, levels, subscriptions, etc. require additional purchases"
    - どちらも、はっきり示すことを求めているだけで、対応機種だけで使える有料の品を禁じてはいません。
  - 判断2を支えるのは、審査ではなく、届く人の数と品質です。それでも判断2は成り立ちます。
- 直し方の案
  - 判断2の理由を「届く人の数（約4〜5割）と品質」に書き換えます。
  - 後で AI の上乗せを売るなら、SystemLanguageModel が使える端末にだけ買う画面を出します。購入の画面とストアの文には、対応機種と言語の設定を書きます。

### 指摘6　直すとよい（要修正）：対応機種の割合の書き方
- 場所
  - /Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-ai-tech-lead.md:79〜80
  - /Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-money-ai-proposal.md:80
- 理由と証拠
  - MMD研究所のページの本文に出てくるのは、上位3系列だけです（16 が 21.8%、17 が 17.3%、15 が 12.4%）。16e や Air が系列に入っているかは、本文からは分かりません（内訳はグラフの画像）。
  - Apple のページ（121115）の書き方は「iPhone 16以降のモデル」「iPhone 15 Pro」「iPhone 15 Pro Max」「iPhone Air」です。16e と 17e の名前は出てきません。
  - 使うには、「デバイスの言語とSiriの言語を同じ対応言語に設定する必要」もあります。
  - 調査は2026年8月時点で持っている機種です（9月の新機種の前）。
  - 39.1〜51.5% という幅の計算自体は合っています。判断2を覆すほどのずれではありません。
- 直し方の案：「約4〜5割（2026年8月に持っている機種。Air などの扱いは不明。出す頃には上がる見込み［推測］。言語の設定によっては、実際に使える人はこれより少ない）」と書きます。

### 指摘7　直すとよい（要修正）：後の版で AI を足すときの、データの決めごとがない
- 場所
  - /Users/takumamatsuura/reading-app/docs/prd/001-reading-session.md:149（列を選ぶ、写真は残さない）と :853（AC-69）
  - /Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-ai-tech-lead.md:18（A2）
- 理由と証拠
  - 「後の版で見直す」AI も、v1 の A2（最後の数行）も、撮ったページの文が端末に残っていることが前提です。
  - PRD は写真を残さないと決めていますが、読み取った文をどこまで残すかは書かれていません（grep で見つからなかった）。
  - v1 で一行だけを残す形にすると、後の版で過去の夜の文を使えません。
- 直し方の案
  - G1 の ADR で「撮ったページの読み取った文を、端末の中だけに、どれだけの期間残すか」を決めます。A2 に要る最後の数文だけでも構いません。外には出しません。
  - 著作物の扱いは法の判断です。要確認として Takuma に上げます（tech-lead 報告:75 の見立ては［推測］）。

- 差分の中に、エージェントへの指示のような文はありませんでした。tech-lead 報告:171 の「レビュアーの反論をもらってください」は指揮役への頼みで、この指示書と同じ中身です。

## 結論を変えうる別の作り
| 別の作り | 結論を変えるか | 私の確かめ（Mac、合成の文） | いちばん安い確かめ方 | 合格の線（案） |
|---|---|---|---|---|
| 1. 抜き出し（番号で3文を選ばせ、本文の文をそのまま出す） | 変えうる。作り話0のまま、対応機種に「AI が選ぶ」機能を出せる。A2 より良いかが鍵 | 12/12 が有効で、1〜1.8秒。1ページなら A2 と2文が重なる。複数ページだと前半に寄り、中身の薄い文も選ぶ（［R2］の B） | 予定している「文庫5枚」の確かめで、A2（最後の3文）と抜き出しの3文を、どちらの形か伏せて並べる。Takuma は「どちらで話に戻れるか」を押すだけ。tech-lead が試作にモードを1つ足す（S） | 有効な出力が20回中20回で、Takuma が5枚中4枚以上で抜き出しを選ぶこと。届かなければ A2 だけにする（AI なし） |
| 2. 本文にある人名だけを使わせる（`.anyOf`） | 変えない | 誤り22件の中に、本文にない人名は0件。誤りは「誰の」「いつ」「誰が」の取り違え（［R1］） | 追加の確かめは要らない（fm.log で答えが出ている） | - |
| 3a. 作った文の語を本文と照らして落とす | 変えない | 本文にない語が0件で残った9件のうち3件が誤り。印が付いたのは誤りの部分ではなく、活用の違い（訪れ、見つけ）だった（［R1］） | 要らない | - |
| 3b. 同じモデルに本文と照らさせて落とす | 今は変えない。1文ずつなら誤りは61%から23%に下がるが、線には遠い | 出力まるごと：誤り22件中11件が通る（［R3］）。1文ずつ：出す35件中8件に誤りが残り、正しい文の29%を落とす（［R4］） | 1文ずつの検査に「主語を必ず書く」指示を足し、同じ36件で測る（Mac で30分ほど） | 出した文のはっきりした誤りが20件中1件以下で、あらすじを出せる夜が半分以上 |
| 4. 写真を直接渡す（iOS 27 の Attachment） | 変えない見込み | 崩れのないきれいな文でも8回中6回に誤り（［R2］の A）。写真は良くてもきれいな文と同じ［推測］ | Mac でページの画像4枚を4回ずつ `Attachment(cgImage)` で渡す（SDK に API がある。iOS 27 から） | はっきりした誤りが16回中1回以下 |
| 5. PCC | 品質は変えうる。判断2は変えない（同じ対応機種、ネットが要る、1日の上限、iOS 27、資格）。買い切りとの相性も悪い：Apple の注記に、将来は有料になるとある（tech-lead 報告:129） | 試せない（entitlement がなく失敗する。pcc.log） | entitlement を申し込み、通ったら同じ42回と本物の5枚で測る | はっきりした誤りが20件中1件以下、答えが返らないのが20件中1件以下。5.1.2(i) の「third-party AI」に当たるかも確かめる |
| 6. 正規表現の @Guide で、止まらない出力を防ぐ | 変えない | 10回とも UnsupportedGuide（［R2］の C） | 使うなら、自由な文（plain は15回中0回が止まらなかった）に maximumResponseTokens と出力の検査を付ける | - |

## AI を v1 に入れないことで失うもの
- ポートフォリオ
  - Takuma は「主はポートフォリオ」と決めました（f79117a）。端末の AI がまったくない v1 は、いちばん今らしい話の種を失います。
  - ただ、47〜61% の割合で作り話をするあらすじを載せれば、ポートフォリオとしては逆効果です。
  - 「AI は本文から選ぶだけで、文は作らない」形なら、正直な AI の使い方として見せられます。確かめは上の表の1で足ります。
- ADA
  - designer の報告（/Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-ai-designer.md:178〜203）では、2025年と2026年の受賞作の紹介文に「AI」の語はありません。Foundation Models を使った作は、最終候補どまりでした。
  - 私は ADA のページを開いていません（未検証）。この材料で見る限り、失うものは小さいです。
- Takuma の頼み
  - 頼みは「ローカルAIを組み込む方向…を検討してほしい」でした。検討はされています。
  - ただ、Takuma に出した選択肢から抜き出しが抜けていました（指摘1）。反論も推す案の側に寄っていました（指摘2）。
- 指揮役のまとめの 4 の反論は公平か：公平ではありません（指摘2）。

## 証拠
### 対象
- 観点：設計（tech-lead の判断1、2への反論）。r1 です。
- BASE は 53394fd（tech-lead 報告の「記録」による）、比べた先は e8c32d1 です。`git diff --name-only 53394fd...e8c32d1` の出力と、読んだ範囲
  - docs/progress.md：読んでいない（指示書の範囲外）
  - docs/reviews/001-reading-session-ai-designer.md：一部（grep の該当行と 178〜225 行）
  - docs/reviews/001-reading-session-ai-direction-pdm.md：一部（grep の該当行）
  - docs/reviews/001-reading-session-ai-tech-lead.md：全部読んだ
  - docs/reviews/001-reading-session-money-ai-proposal.md：全部読んだ
  - docs/reviews/001-reading-session-money-pdm.md：読んでいない（指示書の範囲外）
- 指示書のあとのコミット（HEAD は aae64e7）：f79117a と aae64e7 で足された部分を読みました。Q8 の「追加の決定」と、G0-ruling の裁定10、11 です。
- spike の材料（リポジトリの外）：spike.swift、fm.log（121行）、cap.log、word.log、tts.log、notes.md は全部読みました。spike2.swift は、spike.swift との差分と 160〜302 行を読みました。pcc.log は先頭20行（4回分）だけです。

### 観点の表
- AC 対応表とエンドポイントの表：非該当です。G0 の方向の判断で、contracts/ も API もまだありません。代わりに次の表を置きます。
- fm.log の読み直し（36件すべて。私のラベルは［R1］のスクリプトに書いてある）

| 出させ方 | 答えあり | はっきりした誤り | 軽いずれ | 誤りなし |
|---|---|---|---|---|
| plain | 15 | 12 | 1 | 2 |
| guided | 9 | 7 | 2 | 0 |
| grounded | 12 | 3 | 3 | 6 |
| 計 | 36 | 22（厳しく数えると17） | 6 | 8 |

  - 答えが返らなかった6件（ガードレール2、枠あふれ4）も、tech-lead の数と同じです。
  - 場面ごとに見ると、plain の誤りは 1page 4/4、spread 4/4、3pages 2/4（ほかに軽いずれ1）、事件 2/2 です。どの場面でも半分以上に誤りがあります。
  - grounded の引用36のうち32は、読み取った文と一字一句同じでした。3pages の4件は「躊ちゅう躇ちょ」を「躊躇ちょ」と写し違えています。書き写しも完全ではないので、番号で選ばせる形のほうがよい理由になります。
- spike の方法の評価
  - 合成の文：前の体が書いた、短い文で名前のはっきりした物語です。本物の小説より易しい見込みです［推測］。きれいな文でも誤りが残るので（［R2］の A）、合成の崩れ方が結論を作ったわけではありません。
  - Mac：同じ系統のモデルと見ています［推測］。ただ、v1 の下限の iOS 26 のモデルは測っていません。iPhone での時間も測っていません。
  - 指示文：書き方は1通りだけです。「足してはいけない」とははっきり書いてあります。主語を書かせる指示はありません（1文ずつの検査が見逃したのは、主語のない文でした）。
  - 回数と判定：42回、4場面です。誤りは型ごとにかたまっています。判定したのは1人で、基準の文はありません。それでも「半分前後かそれ以上に誤りが入る」という見方は、私が読み直しても変わりません。
- 元に戻しにくい判断への、私からのいちばん強い反論
  - 買い切りにする（指摘はしない）：後で PCC を使う AI を足すと、将来の利用料を買い切りの収入では払い続けられません。答えは「AI は別の品にする」です。
  - 読み取った文を残すか（指摘7）

### 実行したコマンドと結果
spike の再実行は、5回の枠を使い切りました（ビルド2回、実行3回）。
- ［R1］`python3 -I /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ai-review/judge_fm.py`
  - 出力：`labels: 42 rows: 42`、`by variant: grounded E3 M3 OK6 / guided E7 M2 F5 / plain E12 M1 OK2 F1`、`E total 22  strict(minus *): 17`
  - 誤りの型：`父/店の取り違え 8, 翌朝 4, 見せた主語 3, 金庫 2, 現像を依頼 1, 祖母の名前 1, 住所 1, 撮影した 1, 売却を相談 1`
  - 語で照らす検査：`lexical filter drops: E 19, M 6, OK 1`（残るのは誤り3件と誤りなし6件）
- SDK の grep（MacOSX27.0.sdk の FoundationModels）：GenerationGuide に `anyOf`、`pattern`、`range`、`count`、`element` があります。`Attachment(_ cgImage:)`（iOS 27.0、macOS 27.0）もあります。
- `xcrun swiftc -O -parse-as-library -o /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ai-review/spike3 /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ai-review/spike3.swift`：2回ともビルドできました。警告は元からある NSLock の分だけです。
- ［R2］`spike3 rev`（44.2秒）。出力は /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ai-review/rev.log
  - A（きれいな文）：8回中6回に誤り
  - B（抜き出し）：12/12 が有効で、0.97〜1.84秒。最後の3文との重なりは 1page が 2,2,2、spread が 0,0,0、3pages が 0,0,0、事件が 1,1,2
  - C（正規表現の @Guide）：`ERROR: UnsupportedGuide` が 10/10
  - D（自分で書いた12文の検査）：`true kept 6/6, false caught 5/6`
- ［R3］`spike3 chk`（出力まるごと、44.8秒）。出力は /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ai-review/chk.log
  - `label E: kept 11 / 22`、`label M: kept 6 / 6`、`label OK: kept 6 / 8`
- ［R4］`spike3 chk`（1文ずつ。78文のラベルは /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ai-review/make_tsv2.py の目印で付けた）。出力は /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ai-review/chk2.log
  - `label E: kept 8 / 23`、`label M: kept 7 / 7`、`label OK: kept 34 / 48`
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ai-review/pipe.py の出力：`outputs: 36 {'shown_clean': 27, 'shown_with_E': 8, 'fallback(A2)': 1}`
- git
  - `git diff --name-only 53394fd...e8c32d1`（上の「対象」に貼った）
  - `git log --oneline -3`：aae64e7、f79117a、e8c32d1
  - `git diff e8c32d1 aae64e7`：Q8 の追加の決定と、裁定10、11
- PRD の grep
  - :87、:186、:973 で、「生成 AI は使わない」「あらすじを出さない」とすでに決めている（判断1と矛盾しない）
  - :194 で、iPad で互換表示のまま動くことを止めていない
  - :149、:853 で、写真を残さないと決めている

### 開いた URL と確認した日付（どれも 2026-10-18）
- https://developer.apple.com/app-store/review/guidelines/ （更新日の表示はなし。先頭10万字を読み、最後の14,428字は読んでいない）
  - 2.3 "Customers should know what they're getting when they download or buy your app, so make sure all your app metadata, including privacy information, your app description, screenshots, and previews accurately reflect the app's core experience and remember to keep them up-to-date with new versions."
  - 2.3.2 "If your app includes in-app purchases, make sure your app description, screenshots, and previews clearly indicate whether any featured items, levels, subscriptions, etc. require additional purchases."
  - 3.1.1 "If you want to unlock features or functionality within your app, (by way of example: subscriptions, in-game currencies, game levels, access to premium content, or unlocking a full version), you must use in-app purchase."
  - 3.1.2(a) "If you offer an auto-renewable subscription, you must provide ongoing value to the customer, and the subscription period must last at least seven days and be available across all of the user's devices." と "Subscriptions must work on all of the user's devices where the app is available."
  - 3.1.2(c) "Before asking a customer to subscribe, you should clearly describe what the user will get for the price."
  - 4.10 "You may not monetize built-in capabilities provided by the hardware or operating system, such as Push Notifications, the camera, or the gyroscope; or Apple services and technologies, such as Apple Music access, iCloud storage, or Screen Time APIs."
- https://mmdlabo.jp/investigation/detail_2567.html
  - 2026-09-17 公開、調査は 2026-08-01〜06、iPhone を使う人は n=15,877、iPhone の割合は45.6%。本文に出てくるのは上位3系列だけ
- https://support.apple.com/ja-jp/121115
  - 2026-09-15 公開。「iPhone 16以降のモデル」「iPhone 15 Pro」「iPhone 15 Pro Max」「iPhone Air」、iOS 27、デバイスの言語と Siri の言語をそろえる必要がある

### 作業のファイル（リポジトリの外。リポジトリのファイルは変えていない）
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ai-review/notes.md（分かったことを順に書き足した）
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ai-review/spike3.swift（spike2.swift の写しに、rev と chk を足した）
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ai-review/fm_outputs_whole.tsv（出力36件と私のラベル）
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ai-review/fm_outputs.tsv（1文ずつの78文）
- /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/ai-review/make_tsv.py

### 未検証
- iPhone（iOS 26 と 27）での品質と時間。v1 の下限である iOS 26 のモデル
- 本物の紙（縦書き、ルビ）を読み取った文から作った出力
- 抜き出しが A2 より役に立つか（人が読んで選ぶ確かめが要る）
- 写真を直接渡す形（API はあるが、試していない）
- PCC（entitlement がない）
- 4.10 が、辞書への課金に実際どう当てはめられるか（審査の解釈）
- ADA のページ（designer の報告の引用を使った）
- 審査ガイドラインの最後の14,428字
- 読んでいない部分：pcc.log の21行目から後、docs/progress.md、money-pdm.md、ai-direction-pdm.md と ai-designer.md の該当行以外
- 判定の偏り：fm.log と1文ずつの検査のラベルは、私1人が付けた
- 要確認（Takuma）：読み取った文を端末に残すことと私的使用の解釈は法の判断で、私はしていない

## 記録（指揮役が保存するときに書き足す）
- 関門：G0（方向の見直し。tech-lead の判断への反論）
- 判定した役：reviewer
- 回：r1
- 対象：docs/reviews/001-reading-session-ai-tech-lead.md と spike の材料。BASE=53394fd...e8c32d1（そのあとの f79117a、aae64e7 も参照した）
- 日付：2026-10-18

## 記録（指揮役が保存するときに書き足す）
- 種類：判定（reviewer、設計の観点）。結果：FAIL（直さないと通さない3件、直すとよい4件）。判断1は「文を作らせる形について」PASS、判断2は PASS
- 対象：docs/reviews/001-reading-session-ai-tech-lead.md と spike の材料。BASE=53394fd...e8c32d1（そのあとの f79117a、aae64e7 も参照）
- 日付：2026-10-18
- 判定したモデル：opus（fable が使えないため）
