（指揮役の注）これは判定ではなく、機能を統合した体験を検討するための調べもの（tech-lead）の報告。担当は、Takuma の4つと「続きの一行」の作れるかと負担、v1 の切り方。spike は2つ（縦書きの表示とルビ付きのページの読み取り、Wikidata の受賞の数え上げ）。報告の文はそのまま保存した。

# 機能を統合した読書アプリの、作れるかと負担（tech-lead の調べもの。BASE=ab9ffa5）

これは判定の前の調べものなので、PASS や FAIL は付けていません。リポジトリのファイルは書いていません。
spike は2つで、どちらもリポジトリの外で行いました（手数は6回）。
- 縦書きの表示と、ルビ付きのページの読み取り
- Wikidata の受賞の数え上げ

根拠は、ことわりがない限り 2026-10-18 に開いたものです。自分の見立てには［推測］、確かめていないものには「未検証」、出どころを開いていない記憶には［私の知識］と付けています。

## 結論
- 「続きの一行」と、Takuma の4つのうち3つ（登録、出版社と受賞、中身の近さで出すおすすめ）は、iOS だけで作れます。サーバーなしで、月0ドルのままです。サーバーが要るのは「友人」と、本当の意味の「これを読んだ人は」（読んだ人のデータを集めて数える）の2つです。
- 新しく分かったことが3つあります。
  - iOS 26 から、Live Activity を決めた時刻に始める予約がサーバーなしでできます（`request(...start:)`）。
  - 縦書きの一行は、SwiftUI だけでロック画面のウィジェットの大きさに組めました（spike）。
  - ルビはページの読み取りを下げます。ルビの付いた漢字が崩れます。ただし、最後の行の位置は 4/4 正しく取れました。
- 書誌の状態が変わっています。openBD は 2023 年に JPRO のデータが止まり、国立国会図書館の CC BY の書誌をもとにした代わりの API に移りました。書影は大きく減りました。受賞の情報は、Wikidata では日本の賞が薄いです（芥川賞は、受賞の記載がある作品が26件、そのうち ISBN 付きは5件）。手で作る一覧が要ります。
- 「これを読んだ人は」は、出した日は0人なので、v1 では作れません。v1 は「同じ著者、同じ賞、同じレーベル」の近さで出し、名前を変えることを推します。友人は L の負担です（アカウント、1.2、5.1.1(v)、年齢の決まり）。v1 から外し、代わりに画像のカードを送る形にすることを推します。
- v1（2週間）の切り方：続きの一行（手入力と写真）、ロック画面（ウィジェットと予約した Live Activity）、伏せて読む、バーコードの連続登録と題名の検索、出版社とレーベル、日本の3賞。友人、集計のおすすめ、取り込み、背表紙のカメラは入れません。

## 機能ごとの判定の表
負担の目安：S は1日以内、M は2〜4日、L は1週間以上か、新しい仕組み（サーバー、アカウント）が要るもの。

| # | 機能 | 判定 | 負担 | v1 | ひとことの根拠 |
|---|---|---|---|---|---|
| 1 | 続きの一行：ロック画面のウィジェット（縦書き） | できる | M | 入れる | SwiftUI だけで組めた（spike A）。許可は要らない。時刻での切り替えは、先に並べたタイムラインで足りる |
| 2 | 続きの一行：決めた時刻に出る Live Activity（予約） | 条件付き | S（1 に足す） | 入れる | iOS 26 から。アプリが前にあるときに、翌晩の分を予約する。始まるときの知らせ（AlertConfiguration）が必須。同時に置ける数に上限がある |
| 3 | 続きの一行：StandBy | できる | S | 入れる（おまけ） | 小のウィジェットと Live Activity が出る。Live Activity は全画面に広がる |
| 4 | 続きの一行：決めた時刻の通知 | できる | S | 任意 | 横書きだけ。許可が1回要る |
| 5 | 一行の取り方：手で入れる | できる | S | 入れる | - |
| 6 | 一行の取り方：ページを撮って最後の行を取る | 条件付き | M | 入れる（直す画面を付ける） | 最後の行の位置は 4/4。ルビの付いた漢字が崩れる。本物の紙は未検証 |
| 7 | 登録：バーコードの連続 | できる | S〜M | 入れる | DataScanner（iOS 16 から）。978 と 979 で始まるものだけ拾う |
| 8 | 登録：題名で探す | できる | S | 入れる | 国立国会図書館サーチ。有料のアプリなら利用申請が要る |
| 9 | 登録：背表紙の写真から何冊も | 条件付き | M | 確かめ1の結果しだい | 合成の画像では 14/14。本物の写真は未検証 |
| 10 | 登録：ほかのアプリからの取り込み | 条件付き | M | 入れない | ブクログと Goodreads は CSV（今の形は未検証）。読書メーターは公式の書き出しが見つからない |
| 11 | 出版社とレーベル | できる | S | 入れる | 国立国会図書館の dc:publisher と dcndl:seriesTitle、openBD の ImprintName と Collection |
| 12 | 受賞（まず日本の3賞） | 条件付き | M（一覧づくり1〜1.5日と、年3回の更新） | 入れる（3賞） | Wikidata は日本の賞が薄い。手で一覧を作る |
| 13 | 友人：CloudKit の共有（サーバーなし） | 条件付き | L | 入れない | 相手も iCloud のアカウントが要る。見つける手段はリンクだけ。SwiftData の同期の文書に共有の記載がない |
| 14 | 友人：自前のサーバー | 条件付き | L | 入れない | stacks を変える（Takuma が決める）。アカウント、削除、1.2、年齢の決まり |
| 15 | 友人の代わり：画像のカードを送る（ShareLink） | できる | S | 入れる候補 | サーバーなし。アプリの中に他人の投稿がない |
| 16 | これを読んだ人は：みんなのデータの集計 | 難しい（v1 の時点） | L | 入れない | 0人から始まる。サーバー、匿名化、人数のしきい値が要る |
| 17 | これを読んだ人は：中身の近さ（同じ著者、賞、レーベル） | できる | S〜M | 入れる（名前は変える） | 端末の中で済む。分類（NDC）は小説だと 913.6 にまとまり、手がかりとして弱い |
| 18 | Foundation Models（理由の1文） | 条件付き | S | 入れない（任意） | 対応する機種だけ。本の中身は言わせない |

## 1. 簡単な登録
### バーコードの連続の読み取り
- 使う部品は VisionKit の DataScannerViewController です（iOS 16 から）。
  - `recognizesMultipleItems`：「A Boolean value that indicates whether the scanner should identify all items in the live video.」
  - `recognizedItems`：「An asynchronous array of items that the data scanner currently recognizes in the camera's live video.」（`AsyncStream<[RecognizedItem]>`）
- 作り：読み取りの画面を開いたままにします。新しい EAN-13 のうち、978 と 979 で始まるものだけを一覧に足し、触覚を鳴らします。
  - 下の段の 192 で始まるコード（分類と値段）は捨てます（前回の spike）。
  - 同じ ISBN は1回だけ数えます。
  - 書誌は通信が要ります。ISBN を先に保存して、あとで埋める順番待ちにします。通信がなくても登録できます。
- 1冊あたりの秒数は未計測です。実機が要ります。
  - ［推測］本を取って裏返し、枠に入れるまでが2〜4秒、読み取りは1秒より短い。20冊で1〜1.5分くらい。
  - 文書には、続けて読める冊数の上限の記載がありません。
  - 測り方の案：G3 か G4 の実機で、10冊を続けて登録する時間を3回測ります。
- 許可：カメラが1回要ります（前回と同じ）。

### 背表紙の写真から何冊も
- 前回の spike から変わったところはありません。合成の画像では 14/14 読めました。本物の写真は確かめ1の結果待ちです。
- 統合した形での使い道：読み取った題名と著者を候補の一覧にし、利用者が確かめてから残します。
  - ISBN は要りません（前回の結論のまま）。
  - 書誌が欲しいときは、国立国会図書館サーチで題名と著者から探します。

### 題名で探す
- 国立国会図書館サーチの OpenSearch で探せます（前回、HTTP 200 で確かめました）。
- 同じ本の版が多く出ます（人間失格は345件で、上位5件は別の版や全集でした）。図書で ISBN のあるものに絞り、版をまとめる処理が要ります。手間は S です。
- 営利になるときの条件を、今日もう一度見ました。「何らかの経済的な対価を受け取っている場合は営利目的にあたり、利用申請が必要です」。広告の収入も営利の例に挙がっています。
- openBD は ISBN でしか引けません（前回のとおり）。

### 書誌の出どころの、2026-10 の状態（変わった所と足りなかった所だけ）
| 出どころ | 今日わかったこと | 推す使い方 |
|---|---|---|
| openBD | **2023-07-25 のお知らせ**（下に引用）：2023-06-05 に JPRO から版元ドットコムへのデータの配信が止まった。続けるのは「困難と判断」し、「openBD API（バージョン1）」の提供を終える。代わりの API を「すくなくとも60か月以上」出す。中身は「国立国会図書館が提供するCC-BYライセンスの書誌情報をベース」で、「特に書影の収録範囲は大幅に低下します」。版元ドットコムの会員社（520社、2023-07-25 の時点）の書誌と書影は、これまでどおり配る。2023-08-29 に国立国会図書館の書誌への切り替えを始めた。使う条件は今も「本の販促・紹介目的に限り使用できます」。前回の spike で人間失格の `cover` が空だったのは、これと合う［推測］ | ISBN から出版社、レーベル、ページ数を取る。表紙の画像には頼らない |
| 版元ドットコム | 書誌と書影を使う条件のページ（/about_bookdata）は 404 で、確かめられなかった（未検証）。openBD の中身として使える | openBD を通して使う |
| カーリル | 「法人・個人を問わず無償で利用できます」。アプリケーションキーの申請が要る。中身は ISBN で図書館の蔵書と貸し出しの状態を引くもので、書誌の出どころではない | 後の版で「近くの図書館にあるか」に使える |
| 国立国会図書館の書影 | ヘルプの API のページに書影の記載を見つけられず、/help/api/thumbnail は 404。前回は書影の URL を curl で開いて 403 だった。条件は未確認 | v1 では使わない |
| Google Books と楽天 | 前回から変えていない（表示の決まりが重く、楽天は鍵が2つ要る） | v1 では使わない |

- openBD の 2023-07-25 のお知らせの原文：「この結果、書誌も含めて再配信は現行規約違反との方針が示され、現状のスキームによるオープンな書誌・書影情報の提供継続は困難と判断するに至りました。」「すくなくとも60か月以上の期間、国立国会図書館が提供するCC-BYライセンスの書誌情報をベースとした代替API（仮称）を提供します。」
- 60か月を2023年の夏から数えると、2028年の夏までは続く見込みです［推測］。その後は国立国会図書館サーチに直接つなぎ替えられる形にしておきます（書誌を取る部分を1か所にまとめる）。

### ほかのアプリからの取り込み
| アプリ | 書き出し | 今日わかったこと | 判定 |
|---|---|---|---|
| Goodreads | CSV（My Books の Import and export）［私の知識］ | ヘルプのページは 404 で、今の項目は未検証。［私の知識］ISBN と ISBN13、Exclusive Shelf（read、currently-reading、to-read）、Date Read があり、ISBN は Excel 向けに `="…"` の形で入っている | 条件付き。本物のファイルを1つもらって確かめる |
| ブクログ | CSV（ヘルプから） | 見つかったのは2013年の個人のブログだけ。項目は、サービスID、アイテムID、13桁の ISBN、カテゴリ、評価、読書状況、レビュー、タグ、読書メモ（非公開）。今の形は未検証。文字コードも未検証（Shift_JIS かもしれない［推測］） | 条件付き |
| 読書メーター | 公式の書き出しが見つからない | 見つかったのは他人が作った道具（bookmeter_exporter）だけ。メールとパスワードで画面を読み取る形。**使わない**（他人のサービスのパスワードを預かることになり、5.1.1 と相手の規約に触れるおそれがある［推測］） | 難しい |

- 作り：SwiftUI の `fileImporter` で CSV を選び、ISBN の一覧にして、書誌の順番待ちに入れます。ファイルを選ぶ画面は、許可のダイアログなしで使える見込みです［推測］。手間は M（形の違い、文字コード、ISBN の崩れ）。
- v1 には入れません。最初に乗り換えてくる人が出てきたら足します。

## 2. 出版社と受賞
### 出版社とレーベル
前回の spike で保存した応答を見直して、項目があることを確かめました（今日 grep しました）。
- 国立国会図書館サーチ
  - `dc:publisher`（例：早川書房、ほるぷ出版）
  - `dcndl:seriesTitle`（例：「ハヤカワ文庫 JA ; 1518」「角川文庫」）。「 ; 」の前をレーベルにします。
  - `dc:subject` の NDC8 と NDC9（例：913.6）、NDLC（例：KH84）
- openBD
  - `"publisher":"新潮社"`、`"ImprintName":"新潮社"`
  - Collection の `TitleText` が「新潮文庫」
- 手間は S です。出版社とレーベルは、どちらの出どころでも取れます。
- 気をつけること：見た2つの応答では、小説の分類はどれも 913.6（日本の小説）でした。分類は「似た本」の手がかりとしてはほとんど効きません［推測。2件の応答から］。件名（NDLSH）は、この2件にはありませんでした。

### 受賞：出どころとライセンス
| 出どころ | ライセンス（原文） | 網羅 | 判定 |
|---|---|---|---|
| Wikidata | 「All structured data from the main, Property, Lexeme, and EntitySchema namespaces is available under the Creative Commons CC0 License」 | 下の spike の表。英語の賞はほぼそろう。日本の賞は作品の単位で薄い | 英語の賞の一覧の下書きに使う。**アプリから直接は呼ばない**（今日、窓口が「1 req / min」に絞られていた） |
| Wikipedia（日本語） | CC BY-SA 4.0。「引用の範囲を超えて転載を行う場合、『クリエイティブ・コモンズ 表示-継承 4.0 国際ライセンスの下で利用可能です』という一文を加え、ライセンスを継承してください。」 | 一覧の記事は多い［私の知識］ | 一覧をそのまま写すと、継承の条件がかかるおそれがある［推測］。確かめるためだけに使う |
| 各賞の公式のページ（日本文学振興会、本屋大賞など） | 今回は開いていない（未検証） | 正しさの基準になる | 手で作る一覧の出どころにする |
| 手で作る一覧（賞、回か年、題名、著者） | 自分たちで作る。「だれが何年に何の賞を取ったか」という事実を、自分の言葉で並べる［推測。法務の確認は Takuma を通す］ | 範囲は自分で決められる | **推す** |

### spike：Wikidata の SPARQL（query.wikidata.org、2026-10-18）
- 数えたもの
  - 受賞（P166）の記載がある、人ではない項目（作品）の数
  - そのうち、作品か、その版（P629）に ISBN（P212、P957）があるものの数
  - 受賞の記載がある人の数
  - 人の記載に「対象の作品」（P1686）が付いているものの数
- 窓口の状態：最初の1件のあと、`HTTP 429: Aggressively rate-limiting to 1 req / min - this rule was created during active wdqs outage` が返りました。残りは70秒おきに流しました。

| 賞 | QID | 作品 | ISBN あり | 人 | 人に「対象の作品」あり | 実際の受賞の数（［私の知識］、だいたいの数） |
|---|---|---|---|---|---|---|
| 芥川龍之介賞 | Q424160 | 26 | 5 | 175 | 0 | 約180 |
| 直木三十五賞 | Q224573 | 20 | 4 | 48 | 0 | 約180 |
| 本屋大賞 | Q1548835 | 9 | 3 | 4 | 0 | 23（2004〜2026） |
| Booker Prize | Q160082 | 60 | 42 | 56 | 0 | 約60 |
| Hugo Award for Best Novel | Q255032 | 77 | 68 | 52 | 0 | 約75 |

- 読み方
  - 日本の賞は、作品の単位で1〜4割しかありません。芥川賞は人の単位ならほぼそろっていますが、どの作品で取ったかが書かれていません（P1686 が0件）。「この本が芥川賞を取った」は Wikidata だけでは言えません。
  - 英語の2つは作品がほぼそろい、ISBN も7〜9割あります。
  - 結論：日本の賞は手で作ります。英語の賞は Wikidata（CC0）から下書きを作り、手で直します。

### 本と照らす方法
- ISBN では照らしません。単行本と文庫で ISBN が違い、Wikidata の ISBN もまばらだからです。
- 本の書誌（題名と著者）をそろえた形に直して、一覧と照らします。
  - そろえ方：NFKC にする、空白と記号を除く、副題を落とす。
  - 題名と著者の両方が合うときだけ「受賞」と出します。
- 手間は S です。同じ題名で著者の違う本を間違えないかを、テストの表で確かめます。

### どこまで網羅できるか、更新の手間
- v1：芥川賞、直木賞、本屋大賞。一覧は約380行の見込みで［推測］、作るのに1〜1.5日かかります（だれが作るかは指揮役が決める）。
- 後の版の候補
  - 日本：江戸川乱歩賞、谷崎潤一郎賞、山本周五郎賞、日本SF大賞など
  - 海外：Booker、International Booker、Pulitzer（Fiction）、Hugo、Nebula、National Book Award
  - 海外の作品は、日本語の版の題名とつなぐ手間が別にかかります。Wikidata の日本語の名前（Booker は 24/60、Hugo は 69/77 にある）が、本の題名と同じかは未検証です。
- 更新：芥川賞と直木賞は1月と7月、本屋大賞は4月で、年3回です［私の知識］。
  - v1 は一覧をアプリに入れ、アプリの更新で配ります。
  - 外のファイルから取る形にすると、置き場所が要り、端末から外への通信も増えます。

## 3. 友人の読書
### 比べ
| 観点 | (a) CloudKit の共有（CKShare） | (b) CloudKit の公開のデータベース | (c) 自前のサーバー（backend/） |
|---|---|---|---|
| 仕組み | 自分の非公開のデータの一部を、リンクで決めた人と分け合う。公式のサンプル：「With the CloudKit sharing UI, users can send a share link, stop sharing topics, and manage permissions for a shared topic. Users who accept the share, called participants, can view or edit the shared record, or stop participating」 | だれでも読める［私の知識］ | 自分で決める |
| 友人の見つけ方 | **リンクだけ**。連絡先や メールでの発見（CKDiscoverAllUserIdentitiesOperation、`discoverUserIdentity(withEmailAddress:)`）は iOS 17 で非推奨になった：「No longer supported. Please see Sharing CloudKit Data with Other iCloud Users.」 | 自分で作る | 招待のリンク、短いコード、連絡先（下の注） |
| アカウント | iCloud を使う。アプリのアカウントは作らない。相手も iCloud が要る［推測］ | 書くには iCloud が要る［私の知識］ | 要る。Sign in with Apple を推す |
| SwiftData | 同期の文書には、共有と公開のデータベースの記載がない。CloudKit を直接使うか Core Data を使うことになる見込み［推測］ | 同じ | 関係しない |
| 1.2（他人の投稿） | 自由な文を見せるならかかる。共有を外すことはブロックに近い［推測］ | 他人がだれでも書けるので重い | かかる（フィルター、通報、ブロック、連絡先） |
| 5.1.1(v)（アカウントの削除） | アプリのアカウントがないので、かからない見込み［推測］。共有をやめる画面は要る | 同じ | **かかる**。Sign in with Apple なら、トークンの取り消しも要る［私の知識。未検証］ |
| 月の費用 | 0ドルの見込み。CloudKit の今の無料の枠は、公式ページに見つからず未確認 | 同じ | 下の 6 を見る |
| 負担 | L | L（友人だけに見せる作りに向かない） | L。stacks に backend を足すので、Takuma が決める |

- **連絡先で探す場合**
  - ContactAccessButton（iOS 18）で、利用者が選んだ人だけを渡す形があります：「A SwiftUI button that you use to add to the set of contacts someone shares with your app.」
  - 審査の 5.1.2 の決まりがあります：「Do not use information from Contacts … to build a contact database for your own use」「do not include a Select All option or default the selection of all contacts.」
  - 電話番号をサーバーで照らすと、連絡先を外に送ることになり、申告が要ります［推測］。v1.x でも、リンクかコードを推します。
- **審査の論点**（ガイドラインの Last Updated は October 16, 2026）
  - 1.2：「A method for filtering objectionable material」「A mechanism to report offensive content and timely responses to concerns」「The ability to block abusive users」「Published contact information」
  - 5.1.1(v)：「If your app supports account creation, you must also offer account deletion within the app.」
  - 4.8：自前のアカウントだけなら、ほかのログインは要りません（「Your app exclusively uses your company's own account setup and sign-in systems.」）。Google などのログインを使うなら、同等のものが要ります。
  - 子ども
    - Kids カテゴリーには入れません。
    - Declared Age Range（iOS 26 から。com.apple.developer.declared-age-range の entitlement）の文書には、こうあります：「You are solely responsible for ensuring compliance with associated laws or regulations that may apply to your app.」
    - 米国のテキサス、ユタ、ルイジアナで年齢の決まりが始まった、と二次の記事にあります。友人の機能を足す前に、どこまでかかるかを確かめます（未検証）。
- **プライバシーの申告**（(c) のとき［推測］）
  - ユーザー ID と、ユーザーのコンテンツ（読んでいる本と進み）を「結び付く」で申告します。
  - 連絡先を使うなら、連絡先も申告します。
  - (a) は、データが Apple の CloudKit にあり、開発者が中を読めない形なら「収集」に当たらない可能性があります（未検証。G5 で決める）。
- **著作権**：友人に「一行」を見せると、公衆送信（著作権法23条）に当たるおそれがあります。下の 5 を見てください。友人に見せるのは、題名、ページ、分だけにすることを推します。
- **緊張の1（スマホの時間）への技術の答え**
  - アプリの中に流れる一覧（フィード）は作りません。
  - 友人の様子は、ロック画面のウィジェットか、読み終えた画面にだけ出します。
  - サーバーからウィジェットを更新する仕組み（iOS 26 の WidgetPushHandler：「Use WidgetKit push notifications to request timeline reloads from the system」）はありますが、これもサーバーが要ります。
- **v1 の代わり（S）**
  - 読み終えたときの「p.43 → p.61　18分」と題名を、端末で画像のカードにします。ShareLink でメッセージなどに送ります。
  - サーバーも、アプリの中の他人の投稿もありません。収集にも当たりません［推測］。
  - 「友人が何を読んでいるか」は、相手もこのアプリを使っていれば、カードで伝わります。

## 4. 「これを読んだ人は」
- **0人への手当て**
  - 読んだ人の重なりで出すには、同じ本を読んだ人が何人も要ります。日本の本は種類が多く、意味のある数になるのは利用者が数千人を超えてからです［推測］。
  - v1 は他人のデータを使わず、名前も「これを読んだ人は」にしません。他人のデータに見え、誤解させるからです。名前は pdm と designer に任せます。
- **読んだ人のデータを集める形**（後の版。負担は L）
  - 利用者の本棚から「本Aと本Bを両方読んだ」という組を、サーバーで数えます。
  - 匿名にする：ID を送らない。ただ、同じ人の重複を除くには、続けて使う ID が要ります。そうすると、Device ID の申告が要ります（r1 の 4）。
  - 人数のしきい値：組を出すのは、別の人が k 人以上（例：20）のときだけ［推測］。珍しい本の組からは、人を当てられるおそれがあるからです。
  - 読書の履歴は気をつけるべき個人の情報です［推測］。「送ってよい」を利用者に選ばせ、初めは送らない設定にすることを推します。
- **中身で似た本を出す形**（v1。端末の中。負担は S〜M）
  - 手がかりの強さの順［推測］
    1. 同じ著者
    2. 同じ賞（2 の一覧）
    3. 同じレーベル（seriesTitle）
    4. 利用者の積読の中にあるか
  - 分類（NDC）は、小説だと 913.6 にまとまり、効きません（2 を見る）。件名は、見た応答にはありませんでした。
  - NLContextualEmbedding（iOS 17 から）で題名の文の近さを出せますが、日本語の対応は未検証です。題名だけでは弱い見込みです［推測］。
- **友人のデータを使う形**：友人の機能を作った後です（3）。
- **外部の出どころ**：公開で使える「読んだ人のつながり」のデータは、今回の調べでは見つかりませんでした。Goodreads、読書メーター、ブクログの API が今どうなっているかは、今回は開いていません（未検証）。
- **Foundation Models**
  - 使う形：対応する機種で、「同じ著者」「本屋大賞」など、こちらが渡した事実だけから理由の1文を作らせます。利用者の自分のメモをまとめる用にも使えます。
  - 使わない形：本の中身の説明や、知識からのおすすめです。前回の spike で作り話をしました。

## 5. 続きの一行（ロック画面）
### 出し方の比べ
| 出し方 | 大きさ（430×932 の画面） | 決めた時刻に出せるか | 主な制約 | サーバー | 許可 | 判定 |
|---|---|---|---|---|---|---|
| ロック画面のウィジェット（accessoryRectangular） | 172×76 pt（HIG の表） | 出せる。21:00 の項目をタイムラインに先に入れておく | 置くのは利用者。更新の枠は「from 40 to 70 refreshes」（よく見られるウィジェットの1日）。項目の間は「at least about 5 minutes apart」。ロック画面では vibrant の描き方になり、色が抜ける | 要らない | 要らない | **v1 の主** |
| 小のウィジェット（systemSmall） | 170×170 pt | 同じ | ホーム画面と StandBy に出る（HIG の表：「Home Screen, Today View, StandBy, CarPlay」） | 要らない | 要らない | v1（同じ部品） |
| 予約した Live Activity | ロック画面の表示は 408×84〜160 pt | **出せる**（iOS 26）：「The system starts the Live Activity at the specified date, even if the app is in the background.」 | 予約はアプリが前にあるときだけ。「you must provide an AlertConfiguration」なので、始まるときに知らせが出る。「Scheduled Live Activities count towards this limit」（同時に置ける数）。動くのは8時間までで、その後ロック画面に最長4時間残る。画像は表示の大きさ以下にする | 要らない（サーバーから push で始める形は要る。iOS 17.2 から） | 設定でアプリごとに切れる（`areActivitiesEnabled`） | **v1 に入れる**。読み終えた画面で翌晩の分を予約する |
| StandBy | Live Activity は全画面に広がる（`isActivityFullscreen`）。小のウィジェットも出る | 上の2つに従う | 充電中で、横向きで、ロックしているときだけ［私の知識］。暗いと vibrant | 要らない | 要らない | おまけ（作る物は増えない） |
| 決めた時刻の通知 | 通知の枠（横書き） | 出せる（UNCalendarNotificationTrigger） | 縦書きにできない | 要らない | 1回要る | 任意（ウィジェットも Live Activity も使わない人向け） |
| AlarmKit（iOS 26） | 目立つアラーム | 出せる | 「Schedule prominent alarms」。夜の一行には強すぎる | 要らない | 要る | 使わない |

- Live Activity は、HIG に「work best for tracking short to medium duration activities that don't exceed eight hours」とあります。
  - 一行を見せるだけのものにせず、「今夜の読書」という始まりと終わりのある活動にします（待つ → 読む → 読み終えた p.43 → p.61）。
  - こうすれば、決まりに沿います［推測］。審査で「一節を見せるだけ」と見られる危険を下げられます。
- 予約は1晩ずつです。アプリを開かなかった夜の翌晩は出ません。ウィジェットは毎晩出せるので、ウィジェットを主にして、Live Activity は「開いた人へのごほうび」にします［推測］。

### 縦書きで出せるか（spike A）
- SwiftUI に縦書きの指定はありません。June 2026 の SwiftUI の更新の一覧にも、縦書きの項目はありません（TextRenderer などの文字の描き方の拡張だけ）。
- ウィジェットでは、WKWebView や UIKit の部品が使えません：「not all SwiftUI views work in widgets」「WidgetKit ignores other views when it renders the widget's content.」
- **spike で、SwiftUI の部品だけで縦書きの一行を組めました。**
  - 作り：文字を1字ずつ縦に積み、右の列から左へ並べます。
  - 句読点とかぎ括弧は、Unicode の縦書き用の字に置き換えます（、→U+FE11、。→U+FE12、「→U+FE41、」→U+FE42）。ヒラギノ明朝に4字とも字形があることを確かめました。
  - 「ー」は90度回し、小さい「ょ」「っ」は右上へずらします。
  - 画像で確かめました（下の widget_vertical_0.png）。左の素朴な積み方では、句読点が左下に来て、かぎ括弧と長音が横を向きます。右の置き換えた積み方では、どちらも正しい向きになりました。
  - 172×76 pt に入る文字の大きさ
    - 14字：22pt、3字ずつ5列
    - 24字：17pt、4字ずつ6列
    - 35字：14pt、4字ずつ9列
    - 158×72 pt（小さい機種の私の仮の値）では、35字が 12.5pt
- 読み方
  - 文庫の1行（約40字［推測］）は、ロック画面の長方形のウィジェットには1列で入りません。「一行」は15〜25字の句にするのがよい見込みです（designer に渡す）。
  - Live Activity（高さ160 pt まで）なら、16pt で1列に9字ほど入ります。
- 残る手間
  - 行頭の禁則（列の頭に「、」「。」「」」を置かない）。spike では入れていません。S。
  - ルビ：積む形では出せません。要るときは、アプリの中で Core Text の縦組み（前回うまく出た）で画像を作り、ウィジェットに画像で渡します。
  - VoiceOver：一行全体を1つのラベルにする（spike のコードに書きました）。実機での読み上げは未検証。
  - ロック画面で文字の大きさの設定が効くか、vibrant でどう見えるかは未検証です。

### 一行の取り方（spike B）
- 合成のページを使いました。Core Text の縦組みで羅生門の冒頭を組み、ルビを9か所付けました（1000×1400px、38px の明朝）。それを Mac の Vision（RecognizeTextRequest、ja、accurate）で読みました。

| 画像 | 取れた列 | 完全に合った列 | 字の一致（LCS） | 余分な字 | ルビの読みが文字で出たか | 最後の行（いちばん左の列） |
|---|---|---|---|---|---|---|
| ルビあり、きれい | 6/6 | 3/6 | 0.945 | 8 | 0件 | 正しい（「ほかには誰もいない。」） |
| ルビなし、きれい | 6/6 | 5/6 | 0.994 | 1 | - | 正しい |
| ルビあり、−0.7EV、ぼかし、3度、0.6倍 | 6/6 | 2/6 | 0.853 | 21 | 0件 | 正しい |
| ルビあり、−1.2EV、強いぼかし、5度、0.45倍 | 6/6 | 2/6 | 0.871 | 19 | 0件 | 正しい |

- ルビの読みそのものは文字として出ません。かわりに、**ルビの付いた漢字が崩れました**：暮方→幕が、下人→Fん、羅生門→羅生際、円柱→円様、蟋蟀→蟋蠣、揉→採。丹塗は「丹」が落ちました。崩れるのは固有の名前や難しい字で、利用者が直したくなる所です。
- RecognizeDocumentsRequest は、6行とも向きを `topToBottom` と返し、字の一致は同じ 0.945 でした。RecognizeTextRequest の向きは6行とも nil でした。
- 時間：初回は 38.25秒（モデルの読み込み）、2回目からは 0.32〜0.45秒（Mac）。iPhone の時間は未計測です。
- 推す形
  1. ページを撮る（または写真を選ぶ）。
  2. Vision の枠を画面に重ね、利用者が「ここまで読んだ」行をタップする。いちばん左の列を最初から選んでおく。
  3. 文字を直せる欄に入れてから保存する。
  - 写真は保存せず、一行の文字だけを残します。手間は M です。
- 本物の文庫のページ（紙の湾曲、のどの影、小さい字、つまったルビ）は未検証です。いちばん安い確かめ方は、Takuma が文庫のページを5枚撮り、今回のプログラムに読ませることです（半日。確かめ1と一緒にできる）。

### 著作権（e-Gov の著作権法の本文で確かめた条文と、私の読み）
- 自分だけが見る場合
  - 30条：「個人的に又は家庭内その他これに準ずる限られた範囲内において使用すること（以下「私的使用」という。）を目的とするときは、…その使用する者が複製することができる。」
  - 利用者が自分の本から一行を写し、自分のロック画面に出すのは、この範囲に入る見込みです［推測］。iCloud の自分のデータへの同期も同じと見ています［推測］。
- 友人に見せる場合
  - 23条：「著作者は、その著作物について、公衆送信…を行う権利を専有する。」
  - 2条5項：「『公衆』には、特定かつ多数の者を含むものとする。」
  - 32条の引用：「公正な慣行に合致するものであり、かつ、報道、批評、研究その他の引用の目的上正当な範囲内で行なわれるものでなければならない。」
  - 自分の文を添えずに一行だけを友人の多くに見せる形は、引用として弱い見込みです［推測］。
  - **友人に見せるのは、題名、ページ、分だけにすること**を推します。法務の確認は Takuma を通して行います。

### 伏せて始める仕組みの制約（前回から変わらない所）
- 向きの知らせは、アプリが前で動いている間だけ届きます（flip-research の 1）。ロック中に伏せても始まりません。
- 流れ：ロック画面の一行をタップする → アプリが開く → 伏せる。操作は2つです。
- 画面の向きのロックがオンのときに faceDown が届くかは、まだ未検証です（Q-A）。

## 6. 全体
### 最低の iOS のバージョン
- **iOS 26 を推します**（r1 と同じ）。
- 必要な理由：Live Activity の予約、RecognizeDocumentsRequest、Foundation Models、Declared Age Range が、どれも iOS 26 からです。
- iOS 27 だけで使えるもの（Foundation Models に画像を渡す、Private Cloud Compute）は要りません。

### サーバーの要否
- **v1 はサーバーなしにできます。** 書誌は端末から国立国会図書館サーチと openBD を直接呼びます。受賞の一覧はアプリに入れます。
- サーバーが要るのは、友人（CloudKit の共有を選べば要らない）と、集計のおすすめです。
- app.json の stacks は "ios" だけなので、backend を足すかは Takuma が決めます。

### v1（2週間、10日）の切り方［推測］
| 順 | 中身 | 日 |
|---|---|---|
| 1 | 土台：SwiftData（VersionedSchema）。本、読書の回、一行の型。ウィジェットと分け合う App Group | 1 |
| 2 | 登録：バーコードの連続、題名で探す、手で入れる。書誌の取り込み（出版社、レーベル、ページ数）と、通信がないときの順番待ち | 2.5 |
| 3 | 一行：手で入れる。ページの写真から最後の行の候補を出し、直して保存する | 2 |
| 4 | ロック画面：長方形と小のウィジェット（縦書きと禁則）。予約した Live Activity（今夜の読書） | 2.5 |
| 5 | 伏せて読む。終わりの「p.43 → p.61　18分」（001 の作りを使い回す） | 1 |
| 6 | 受賞（3賞）の照合と表示。「この本の近く」（同じ著者、賞、レーベル） | 1 |
| 合計 | | 10（受賞の一覧づくり1〜1.5日は別） |

- 入れないもの：友人、集計のおすすめ、ほかのアプリからの取り込み、背表紙のカメラ（確かめ1が8割を超えたら v1.x）、Foundation Models、通知。
- あふれたら削る順：6 → 4 の Live Activity（ウィジェットは残す）→ 3 の写真（手入力は残す）。
- 画像のカード（3 の代わり。S）は、余裕があれば 5 に足します。

### 主な危険
1. 本物の文庫のページの写真で、最後の行を読み取れる割合（ルビ、湾曲、小さい字）。未検証です。
2. ロック画面に出るまでの手間。ウィジェットは利用者が自分で置く必要があります。Live Activity は毎晩アプリを開くことが前提です。開かない夜は、一行の入口が弱くなります。
3. 書誌の網羅。openBD は書影が減り、2028年ごろより後は決まっていません［推測］。有料にすると国立国会図書館サーチの利用申請が要ります。
4. 受賞の一覧の正しさと、年3回の更新の手間。
5. 機能を足すほど、作る量とテストが増え、1つの明快な体験がぼやけます（技術の面でも、2週間に入るのは上の範囲まで）。
6. 4.3(b)。読書の記録のアプリは多くあります。違いはロック画面の縦書きの一行と、伏せて読むことです。その違いが審査の担当に1分で伝わる審査メモが要ります［推測］。

### 審査の論点
| 番号 | v1（サーバーなし） | 友人を足したとき |
|---|---|---|
| 4.2 | 低い。保存、登録、ウィジェット、Live Activity がある | 同じ |
| 4.3(b) | 中くらい。「simple timers」が名指しされている（r1）。統合した体験で和らげる | 同じ |
| 5.1.1(v) | かからない（アカウントなし） | (c) ならかかる |
| 1.2 | かからない（他人の投稿なし） | かかる（自由な文を見せるなら重い） |
| 5.1.2 | かからない | 連絡先を使うならかかる |
| 4.8 | かからない | 自前のアカウントだけなら、ほかのログインは要らない |
| 年齢の決まり | 影響は小さい見込み［推測］ | 確かめが要る（二次の記事。未検証） |
| 許可 | カメラ1回（バーコードと写真）。通知は使うなら1回 | 同じ |

### 月の費用
| 形 | 1,000人 | 10,000人 | 根拠 |
|---|---|---|---|
| v1（サーバーなし） | 0ドル | 0ドル | 書誌の API は無料。国立国会図書館サーチは有料のアプリなら利用申請。申請の費用は未確認 |
| 友人を CloudKit の共有で | 0ドル［推測］ | 0ドル［推測］ | CloudKit の今の無料の枠は、公式ページに見つからず未確認 |
| 自前のサーバー（Cloudflare Workers の有料の枠） | 5ドル | 5ドル［推測］ | 「minimum charge of $5 USD per month」「10 million included per month」「+$0.30 per additional million」。1人1日10回の呼び出しなら、10,000人で月300万回なので枠の中［推測］。DB とドメインの費用は未確認 |

- Apple Developer Program の年会費は、人数に関係しないので入れていません。
- 自前のサーバーで重いのは、お金より運用です（1.2 の「timely responses」、通報への対応、運用手順書）。

## ほかの役に効くこと
- （designer）ロック画面の長方形は 172×76 pt です。縦書きの一行は15〜25字の句が収まりのよい長さです（24字で17pt）。Live Activity のロック画面の表示は 408×84〜160 pt です。ロック画面と暗い StandBy では色が抜けます（vibrant）。
- （designer、pdm）書影は減っています。表紙の画像に頼らない、文字で本を見せる形が合っています。
- （pdm）中身の近さで出すおすすめに、「これを読んだ人は」という名前は使わないことを推します。受賞の範囲（v1 は3賞）を決めてください。
- （pdm）友人に見せるのは、題名、ページ、分だけにすることを推します（著作権）。

## 質問（指揮役から Takuma へ）
- **Q1：v1 から友人と集計のおすすめを外し、サーバーなし（月0ドル）にしますか。**
  - 推奨：外す。友人の代わりに画像のカード、おすすめは「同じ著者、賞、レーベル」にする。
  - いちばん強い反論：Takuma が欲しいと言った「これを読んだ人は」が、その名前と意味では v1 に出ない。
  - 元に戻せるか：戻せる。ただし、後から友人を足すときに、CloudKit の共有か自前のサーバーかを決める必要がある（ADR）。
- **Q2：文庫のページの写真5枚で、最後の行の読み取りを確かめますか。**
  - 推奨：する。確かめ1（本棚の写真）と一緒に、半日でできる。
  - いちばん強い反論：撮る手間がかかる。本文が写真に写る。写真はリポジトリの外で扱い、終わったら消す。
  - 元に戻せるか：戻せる。
- **Q3：受賞の一覧を手で作りますか（まず芥川賞、直木賞、本屋大賞）。**
  - 推奨：作る。
  - いちばん強い反論：年3回の更新の手間が、ずっと続く。
  - 元に戻せるか：戻せる。
- 大きな判断は私の判断です（友人と集計を外す、受賞は手で作る、予約した Live Activity を入口に使う、文字を積んで縦書きにする）。決める前に、reviewer に反論を出してもらってください。

## 根拠（開いた日：2026-10-18）
Apple の開発者の文書は、developer.apple.com/tutorials/data/documentation/<パス>.json で本文を読みました。
- ActivityKit
  - https://developer.apple.com/documentation/activitykit/activity （「you can only start a Live Activity while the app is in the foreground, unless you adopt App Intents」）
  - https://developer.apple.com/documentation/activitykit/activity/request(attributes:content:pushtype:style:alertconfiguration:start:) （iOS 26.0。上に引いた文）
  - https://developer.apple.com/documentation/activitykit/activity/request(attributes:content:pushtype:style:alertconfiguration:startdate:) （iOS 26.0）
  - https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities （8時間と4時間、StandBy、予約、同時の数）
  - https://developer.apple.com/documentation/activitykit/starting-and-updating-live-activities-with-activitykit-push-notifications （「On devices that run iOS or iPadOS 17.1 and earlier, you can't start Live Activities with ActivityKit push notifications」）
  - https://developer.apple.com/documentation/activitykit/activityauthorizationinfo/areactivitiesenabled
- WidgetKit
  - https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date （更新の枠、「at least about 5 minutes apart」、StandBy の更新は枠に数えない）
  - https://developer.apple.com/documentation/widgetkit/creating-a-widget-extension （使える部品の文）
  - https://developer.apple.com/documentation/widgetkit/creating-accessory-widgets-and-watch-complications
  - https://developer.apple.com/documentation/widgetkit/widgetfamily/accessoryrectangular
  - https://developer.apple.com/documentation/updates/widgetkit （WidgetPushHandler、WidgetAccentedRenderingMode）
- HIG
  - https://developer.apple.com/design/human-interface-guidelines/widgets （大きさの表、StandBy、vibrant）
  - https://developer.apple.com/design/human-interface-guidelines/live-activities （408×84–160、「don't exceed eight hours」）
- SwiftUI：https://developer.apple.com/documentation/updates/swiftui （June 2026 の項目に縦書きはない）
- CloudKit と SwiftData
  - https://developer.apple.com/documentation/cloudkit/sharing-cloudkit-data-with-other-icloud-users
  - https://developer.apple.com/documentation/cloudkit/ckshare
  - https://developer.apple.com/documentation/cloudkit/ckdiscoveralluseridentitiesoperation と https://developer.apple.com/documentation/cloudkit/ckcontainer/discoveruseridentity(withemailaddress:completionhandler:) （iOS 17.0 で非推奨。「No longer supported.」）
  - https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices
  - https://developer.apple.com/icloud/cloudkit/ （費用の記載を見つけられなかった）
- そのほかの Apple の文書
  - https://developer.apple.com/documentation/contactsui/contactaccessbutton
  - https://developer.apple.com/documentation/naturallanguage/nlcontextualembedding
  - https://developer.apple.com/documentation/declaredagerange
  - https://developer.apple.com/documentation/alarmkit
  - https://developer.apple.com/documentation/visionkit/datascannerviewcontroller/recognizesmultipleitems
  - https://developer.apple.com/documentation/visionkit/datascannerviewcontroller/recognizeditems
- 審査：https://developer.apple.com/app-store/review/guidelines/ （Last Updated: October 16, 2026。1.2、4.2、4.3、4.8、5.1.1(v)、5.1.2）
- 書誌
  - https://openbd.jp/
  - https://openbd.jp/news/20230725.html
  - https://openbd.jp/news/20230829.html
  - https://calil.jp/doc/api.html
  - https://ndlsearch.ndl.go.jp/help/api
  - 404 だったもの：https://www.hanmoto.com/about_bookdata 、https://ndlsearch.ndl.go.jp/help/api/thumbnail
- 受賞
  - https://www.wikidata.org/wiki/Wikidata:Copyright
  - https://ja.wikipedia.org/wiki/Wikipedia:著作権
  - https://query.wikidata.org/sparql （spike）
- 著作権：https://laws.e-gov.go.jp/api/1/lawdata/345AC0000000048 （e-Gov の法令の API。著作権法の2条、23条、30条、32条）。https://www.bunka.go.jp/seisaku/chosakuken/seidokaisetsu/gaiyo/chosakubutsu_jiyu.html は 404
- 費用：https://developers.cloudflare.com/workers/platform/pricing/
- 取り込み（WebSearch の結果。二次の資料）
  - https://www.bousaid.com/2013-12-07-184944/ （ブクログの CSV。2013年）
  - https://awesome.ecosyste.ms/projects/github.com%2Fikuwow%2Fbookmeter_exporter （読書メーターの、他人が作った道具）
  - Goodreads のヘルプ（https://help.goodreads.com/s/article/How-do-I-import-or-export-my-books-1553870934590 ）は 404
- 年齢の決まり（WebSearch の結果。二次の記事。未検証）
  - https://9to5mac.com/2025/10/08/apple-announces-new-requirements-for-apps-available-in-texas/
  - https://www.techrepublic.com/de/article/news-apple-expands-age-verification-api-global-compliance/
- 読み直した前回の報告
  - /Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-reselect-tech-lead.md
  - /Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-G0-tech-lead-r1.md
  - /Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-G0-tech-lead-flip-research.md
  - /Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-validate-tech-lead.md
  - /Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-validation-plan.md
  - /Users/takumamatsuura/reading-app/docs/org/gates.md
  - /Users/takumamatsuura/reading-app/CLAUDE.md
  - /Users/takumamatsuura/reading-app/.claude/org/app.json （読むだけ）

## 変更したファイル
- リポジトリの中：なし。
- リポジトリの外（どれも消してかまいません）
  - spike のプログラム：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/integrate-tech/spike/vt/main.swift
  - ビルドしたもの：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/integrate-tech/bin/vtspike
  - 縦書きの画像：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/integrate-tech/out/widget_vertical_0.png 、/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/integrate-tech/out/widget_vertical_1.png
  - ページの画像：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/integrate-tech/out/page_ruby.png 、/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/integrate-tech/out/page_plain.png 、/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/integrate-tech/out/page_ruby_hard.png 、/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/integrate-tech/out/page_ruby_hard2.png
  - 道具：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/integrate-tech/tools/fetch.py 、/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/integrate-tech/tools/wd.py 、/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/integrate-tech/tools/wd2.py
  - Wikidata の結果：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/integrate-tech/wd/wd2.out
  - 取り込んだ文書とページ：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/integrate-tech/dl 、/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/integrate-tech/txt 、/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/integrate-tech/web

## 実行したコマンドと結果
- `git rev-parse HEAD` → `ab9ffa5c2c4567906d92f82aac4cebfff3eea4da`
- `xcodebuild -version` → Xcode 27.0（27A266a）。`sw_vers` → macOS 27.0.1
- Apple の文書の取り込み（前回の fetch_docs.sh を使った）
  - 1回目は26件で、23件が HTTP 200 でした。404 は3件です：activitykit/updates、widgetkit/preparing-widgets-for-additional-platforms-contexts-and-appearances、widgetkit/displaying-live-data-with-live-activities。
  - 2回目は3件で、すべて 200 でした。
  - 非推奨かどうかは、JSON の deprecatedAt（iOS 17.0）と deprecationSummary で確かめました。
- 審査のガイドライン：/app-review/guidelines/ は 404、/app-store/review/guidelines/ は 200。
- ガードに1回止められました（curl の書き先に `$i` があったため）。回り道はせず、書き先をそのまま書く Python の道具（fetch.py）に分けて、実行し直しました。
- fetch.py の結果
  - openbd.jp：200
  - hanmoto.com/about_bookdata：404
  - calil.jp/doc/api.html：200
  - ndlsearch help/api：200
  - help/api/thumbnail：404
  - icloud/cloudkit：200
  - Cloudflare の料金：200
  - Goodreads のヘルプ：404
  - openBD のお知らせ：2件とも 200
  - 文化庁のページ：404
  - Wikidata:Copyright：200
  - ja.wikipedia の著作権のページ：200
  - e-Gov の法令の API：200（945,280バイト）
- Wikidata の SPARQL
  - 1回目：芥川賞だけが取れました。続く9件と見本の取得は `HTTP Error 429: Aggressively rate-limiting to 1 req / min - this rule was created during active wdqs outage (797a132)` でした。
  - 2回目：70秒おきに、後ろで流しました。直木賞、本屋大賞、Booker、Hugo の4件が取れました（上の表）。
- `swiftc -O -swift-version 5 main.swift -o …/bin/vtspike` → エラー0でビルドできました。
- `vtspike` の出力（要点。合わせて 41.99秒）
  - `A: fit 14 chars -> 172x76: 22.0pt 3/col 5 cols` / `24 chars -> 17.0pt 4/col 6 cols` / `35 chars -> 14.0pt 4/col 9 cols`（158x72 では 21.5、16.0、12.5pt）
  - `A: Hiragino Mincho has glyphs for FE11 FE12 FE41 FE42: [true, true, true, true]`
  - `B[ruby_clean] obs=6 truthCols=6 exactCols=3/6 coverage=0.945 extraChars=8 rubyStringsFound=[] … time=38.25s`
  - `B[plain_clean] … exactCols=5/6 coverage=0.994 extraChars=1 … time=0.45s`
  - `B[ruby_photoish…] exactCols=2/6 coverage=0.853 extraChars=21` / `B[ruby_harder…] exactCols=2/6 coverage=0.871 extraChars=19`
  - 最後の行は4つとも `exact=true`
  - `B[docs ruby_clean] lines=6 dirs=["topToBottom": 6] coverage=0.945`
- widget_vertical_0.png を開き、目で確かめました（上の 5 に書いた見え方）。
- 前回保存した応答（shelf7/api の ndl.xml、ndl2.xml、openbd.json）を grep して、出版社とレーベルの項目を確かめました。
- WebSearch は2回（年齢の決まり、取り込みの形式）。WebFetch は0回です（curl と Python で読んだ）。
- `git status --short` → `?? .agents/`、`?? .codex/`、`?? AGENTS.md` だけでした。どれも始める前からあったもので、私の変更ではありません。

## 未検証
1. 本物の文庫のページの写真で、最後の行を読み取れる割合（ルビ、湾曲、のどの影、小さい字）。Q2 で確かめます。
2. iPhone での Vision の時間（初回の読み込みは Mac で 38秒）。
3. 予約した Live Activity
   - AlertConfiguration を音なしにできるか
   - 最初の Live Activity で許可の確認が出るか
   - 同時に置ける数
   - 審査で「今夜の読書」として通るか
4. ロック画面の実物での縦書きの見え方。spike は Mac の ImageRenderer です。vibrant の描き方、文字の大きさの設定、VoiceOver の読み上げは確かめていません。
5. 行頭の禁則の処理（spike では入れていない）。
6. DataScanner での1冊あたりの秒数と、続けて読める冊数。
7. 背表紙の本物の写真（確かめ1）。
8. 画面の向きのロックがオンのときに faceDown が届くか（Q-A。前回からの持ち越し）。
9. ブクログと Goodreads の今の CSV の形。読書メーターの公式の書き出しの有無。
10. 国立国会図書館の書影の条件。版元ドットコムの、書誌と書影の利用条件のページ。
11. 受賞の一覧の出どころ（各賞の公式のページ）。受賞の数の概数は私の知識です。
12. CloudKit の今の無料の枠と、共有のデータがだれの iCloud の容量に数えられるか。SwiftData で共有が使えないこと（文書に記載がないことしか確かめていない）。
13. NLContextualEmbedding の日本語の対応。
14. 米国の州の年齢の決まりの今の状態と、v1 にかかるか（二次の記事だけ）。
15. 著作権の読み（私的使用、引用、友人に見せる場合）。法務の確認が要ります。
16. 2週間の見積もり（すべて［推測］）。
17. Cloudflare の DB の費用、Universal Links のためのドメインの費用、国立国会図書館の営利の申請の費用。
18. 小さい機種のロック画面の長方形の大きさ（158×72 pt は仮の値。HIG の表の下の行は写していない）。

## 記録（指揮役が保存するときに書き足す）
- 種類：機能を統合した体験を検討するための調べもの（tech-lead）。PASS / FAIL なし
- 対象：Takuma の指示（2026-10-18。docs/approvals/001-reading-session-G0-Q8.md の最後の節）。BASE=ab9ffa5c2c4567906d92f82aac4cebfff3eea4da
- 日付：2026-10-18
