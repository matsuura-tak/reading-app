（指揮役の注）これは判定ではなく、方向の見直しの確かめ（tech-lead）の報告。「毎日の名作」と「音読の宿題」の技術の危険を調べた。報告の文はそのまま保存した。

# 方向の見直し：「毎日の名作」と「音読の宿題」の技術の危険（tech-lead の調べもの。BASE=c50f2ba）

判定の前の調べものなので、PASS や FAIL は付けていません。リポジトリの中のファイルは何も書いていません。spike は1つ（縦書きの表示の比べ）だけで、リポジトリの外で行いました。根拠はすべて 2026-10-16 に開いたものです。自分の見立てには［推測］、確かめていないものには「未検証」と付けています。

## 結論
- **2つとも iOS だけで作れます。** サーバー、通信、外部のライブラリは要りません。月の費用はどちらも0ドルです。
- **技術の面で安全なのは「音読の宿題」（AI の採点なし）です。**
  - 使う部品は、録音、再生、触覚、向きの検知という標準のものだけです。001 の伏せる作りも使い回せます。
  - いちばん強い反論は、下の「どちらが安全か」に書きます。
- **毎日の名作：いちばん心配だった「縦書きとルビ」は、表示までは確かめられました。**
  - spike では、WKWebView の CSS と Core Text のどちらも、縦書きとルビを正しく出しました（羅生門の全文）。
  - TextKit 1 と TextKit 2 は使えませんでした。1 は起動の直後に落ち、2 は字が横に寝た1行になって、ルビも出ませんでした。
  - SwiftUI だけで縦書きにする指定も、文書に見当たりません。
  - 残る危険は次の4つです。
    - VoiceOver の読み方
    - ページ送り
    - 最初の表示にかかる時間（シミュレーターで約3秒）
    - 作品ごとの注記の手当て
- **音読の宿題：残る危険は「伏せている間に画面が消えたら、録音がどうなるか」です。**
  - 自動ロックで画面が消えると、アプリは後ろに回り、録音は止まります。続けるには Background Modes の audio が要る、と文書にあります。
  - シミュレーターでは決められません。Takuma の実機で30分確かめるのが、いちばん安い方法です。

## 新しく分かったこと（ほかの役の判断に効くもの）
1. （designer）文字を最大（AX5）にすると、羅生門（5,749字）は WKWebView で約116画面、Core Text で87ページになります。普通の大きさでは12〜13です。縦書きのまま読むのはつらい見込みです［推測］。大きな文字のときに横書きへ切り替えるかを決めてください。
2. （designer、verifier）WKWebView では、VoiceOver に渡る文に、ルビが本文の後ろに続けて入ります（例：「下人げにんが、」）。縦中横にした数字は抜けます（「傍点と12月」が「傍点と月」になる）。HTML の書き方で手当てが要ります。
3. （pdm、designer）5分の回は、段落だけでは切れません。『吾輩は猫である』の最長の段落は9,521字あり、1段落だけで5分を何倍も超えます。文の切れ目でも切る必要があります。
4. （pdm）青空文庫の外字は、6作品のファイル全体で46個ありました。そのうち44個は、Python の標準の文字コード（euc_jis_2004）で Unicode の字に直せました。残る2個はどちらも「小書きの『ん』」で、Unicode に字がありません。代わりの見せ方が要ります。
5. （designer）AVAudioSession には、録音中に触覚とシステムの音を鳴らすかを決める設定があります（iOS 13 から）。伏せて始めた合図の触覚は、録音を始める前に出す形にします。録音を始めた後だと鳴らないおそれがあります（未検証）。
6. （designer）iOS で鳴る SensoryFeedback は success、selection、impact、alignment、pathComplete です。increase は watchOS と visionOS だけ、levelChange は macOS だけで、iPhone では鳴りません。
7. （pdm）3分の声は、AAC 32kbps で約0.75MB です。毎日録ると、1年で約0.27GB、6年で約1.65GB です（Mac で測った値）。

## 2つの比べ
| 観点 | 毎日の名作 | 音読の宿題 |
|---|---|---|
| 中心の部品 | WKWebView（または Core Text）、WidgetKit、UserNotifications | AVAudioRecorder と AVAudioPlayer、SwiftUI の sensoryFeedback、UIDevice の向き |
| 許可のダイアログ | 通知の1回（ウィジェットだけなら0回） | マイクの1回（通知も使うなら、もう1回） |
| バックエンドと通信 | 要らない（作品をアプリに入れる） | 要らない（録音は端末の中） |
| entitlement と capability | App Groups（ウィジェットとのデータの受け渡し） | なし。ロック中も録るなら Background Modes の audio |
| 外部のライブラリ | なし（青空文庫の変換は、ビルドの前に Mac でスクリプトを動かす） | なし |
| データの申告 | 収集なしの見込み | 収集なしの見込み（声を端末の外に出さない場合）。子ども向けの決まりは別にかかる |
| 2週間で最初の形［推測］ | 作れる。作品を10〜30に絞り、横に流すスクロールで読む形まで | 作れる。録る、聞く、判を押す、伏せて始める、まで |
| いちばんの技術の危険 | 縦書きの VoiceOver とページ送り。作品ごとの注記 | 伏せている間に画面が消えたときの録音。中断（電話など）のあとの保存 |
| シミュレーターで決められる範囲 | 広い（表示、変換、ウィジェットと通知の予定）。VoiceOver の聞こえ方と表示の速さは実機 | 中くらい。録音の流れは差し替えのつなぎ口で試せる見込み。音、ロック、触覚は実機 |
| 001 の使い回し | 低い（時刻の方針くらい） | 中〜高（伏せる始め方、つなぎ口 H15〜H18、時刻の方針 1-b） |
| 審査で気をつけること | 4.3（青空文庫を読むアプリはすでに多い［推測］） | 1.3、2.3.8、5.1.4（子ども）、2.5.14（録音中の表示）、2.5.4（後ろで録る場合） |
| 月の費用（1,000人あたり） | 0ドル | 0ドル |

## 毎日の名作

### 1. 縦書きとルビの表示の方法
spike では、羅生門の全文（5,749字、ルビ129か所、外字3字）を、iPhone 17 のシミュレーターに4つの方法で出しました。文字の大きさは、標準（Large）と最大（AX5）の2つです。

| 方法 | 縦書きとルビ | Dynamic Type（AX5） | VoiceOver | 文字の選択 | ページ送り | 性能（シミュレーター） | 判定 |
|---|---|---|---|---|---|---|---|
| SwiftUI だけ | 縦書きの指定が文書にない（Text のページに vertical や writing mode の語が0件）。回すと字も横に寝る | - | - | - | - | - | 使えない |
| Core Text（縦の字形、右から左に行を重ねる枠、CTRubyAnnotation） | **正しく出た** | UIFontMetrics で 17pt から 48pt に。87ページに組み直せた | **何も読まれない**。部品の木に文がない。UIAccessibilityReadingContent を自分で作る | 選べない。自分で作る（重い［推測］） | 作りやすい。枠ごとに入りきる範囲が分かる（13ページ） | 全ページの組みで 23ms（AX5 で 30ms） | 次の候補 |
| TextKit 1（UITextView と、縦を返す NSTextContainer） | **起動の直後に落ちた**（原因は調べていない） | - | - | - | - | - | 使えない（この形では） |
| TextKit 2（NSTextLayoutManager と、縦を返す NSTextContainer） | **字が横に寝た1行だけ。ルビなし**。中身の大きさは 394×0 | - | - | - | - | - | 使えない |
| WKWebView の CSS（writing-mode: vertical-rl、ruby） | **正しく出た**。傍点（text-emphasis）と縦中横（text-combine-upright）も出た | `font: -apple-system-body` で 17px から 53px に | 部品の木は右の行から左へ、1行ずつの文。ただし、ルビが本文に続けて入り、縦中横の数字が抜ける | 標準で選べる見込み（spike では触っていない） | そのままだと横に流れるスクロール（画面の12.4倍、AX5 で116倍）。1ページずつめくるには CSS の段組か JS が要る（未検証） | 最初の表示まで 3,054ms（AX5 で 2,895ms。Web の処理の起動を含む） | **推す** |

- **推すのは WKWebView です。** 最低の対応 OS が iOS 26 なら、SwiftUI の WebView でも包めます。
  - 理由：禁則、傍点、縦中横、文字の選択を自分で作らずに済みます。Dynamic Type も CSS の1行で追えます。
  - 手当てが要ること：
    - ルビを VoiceOver が2回読まないようにする（例：rt を読み上げから外す。未検証）。
    - 縦中横の数字を読ませる。
    - 最初の表示を待たせない（アプリの起動のときに先に作っておく［推測］）。
- **いちばん強い反論**
  - 「Web のページをアプリに入れた」作りは、デザイン賞の審査で、ネイティブらしさに欠けると見られるおそれがあります［推測］。
  - めくる手触り、最初の表示の遅さ、VoiceOver の癖を細かく直せません。
  - Core Text なら、1ページの組みを完全に決められます。VoiceOver に「ルビの読み」を渡すこともできます。その代わり、VoiceOver と文字の選択をすべて自分で作ることになります。
- **TextKit 1 について**
  - Apple の文書には「縦を返す NSTextContainer を作れば縦に組める」とありますが、UITextView では落ちました。
  - 自前の view で NSLayoutManager に描かせれば、動く可能性は残ります（未検証）。それでも VoiceOver と選択は自分で作るので、Core Text より得はありません［推測］。

### 2. 青空文庫の本文をアプリの形に直す
6作品をダウンロードして数えました。文字コードは Shift_JIS で、読めない文字は0でした。

| 作品 | 字数 | 最長の段落 | ルビ | ｜ | 注記（外字を含む） | UTF-8 | 圧縮後 | 5分の回の数（2,500字のとき） |
|---|---|---|---|---|---|---|---|---|
| 羅生門 | 5,679 | 431 | 129 | 1 | 4 | 19KB | 7KB | 2.3 |
| 走れメロス | 9,806 | 1,500 | 88 | 4 | 1 | 30KB | 11KB | 3.9 |
| 銀河鉄道の夜 | 38,283 | 1,023 | 693 | 14 | 19 | 123KB | 36KB | 15.3 |
| 坊っちゃん | 88,272 | 2,137 | 3,042 | 119 | 40 | 305KB | 102KB | 35.3 |
| こころ | 160,230 | 977 | 4,567 | 149 | 235 | 543KB | 166KB | 64.1 |
| 吾輩は猫である | 318,320 | 9,521 | 9,214 | 393 | 459 | 1,090KB | 374KB | 127.3 |

- 字数は、ルビ、注記、空白を除いた本文の字です。UTF-8 はルビと注記を含む本文の大きさで、圧縮後は zlib（レベル9）です。
- **ルビ（《》と｜）：やさしい。**
  - 決まりはこうです。｜があれば、そこから《まで。なければ、《の前にある同じ字の種類（漢字、ひらがな、カタカナなど）の続き。
  - Python 60行ほどの変換の試作で、羅生門の129か所を直せました。Web と Core Text の両方で正しく出ました。
- **外字：ほぼやさしい。**
  - 注記の中の面区点番号（例：第3水準1-84-77）を、Python の標準の euc_jis_2004 で Unicode に直せます。46個のうち44個を直せました。
  - 直せない2個は「※［＃小書き平仮名ん、168-12］」です。小さく組んだ「ん」か、画像で見せます。
- **［＃…］の注記：中くらい。種類が多く、作品ごとに確かめが要ります。**
  - 6作品で多かったもの：傍点333、字下げ（1行145、ブロック30）、中見出し141、下付きの小さい字15、地から字上げ6、「底本では」の注5、改ページ2。
  - 注記一覧には「古い時点で作成されたものには、過去に推奨されていた古い記法が残っている可能性があります」とあります。
  - 使う作品を絞り、知らない注記を数えて出すスクリプトで、1作品ずつ確かめるのが安全です［推測］。
- **直す場所は、アプリの外を推します（ビルドの前に Mac で動かすスクリプト）。**
  - アプリには、直し終えた HTML（または JSON）と、回の切れ目だけを入れます。アプリの中に、青空文庫の記法を読む処理は持ちません。
  - すでにある変換の道具（例：aozora2html）を使えるかは見ていません（未確認）。使うなら、ビルドの道具として dependencies.md の表に足します。
- 青空文庫の決まり（底本や入力者の表示など）は、pdm が別に確かめています。

### 3. 容量と通信
- 本文は、1字あたり約3.4バイトです（ルビと注記を含む UTF-8）。圧縮すると約1.1〜1.2バイトです（上の表から）。
- 平均10万字の作品を30入れると、約10MB（圧縮して約3.5MB）の見込みです［推測。上の表からの見積もり］。最初の形なら、アプリに入れて足ります。
- **バックエンドと通信は要りません。** ネットから取る形にすると、通信、失敗したときの表示、プライバシーの申告の確かめが増えます。最初の形では勧めません。

### 4. 5分の回と、毎日届ける仕組み
- **切り方**
  - ビルドの前に、字数で切れ目を決めます。
  - 目安の字数に近い段落の終わりを選びます。なければ、文の終わり（。や」）で切ります。ルビと注記の途中では切りません。
  - 最長9,521字の段落があるので、文の終わりで切る処理は必ず要ります。
- **読む速さ：確かな出典は見つかりませんでした（未検証）。**
  - 日本語の黙読の速さ（1分に何字か）は確かめられませんでした。
  - IReST（17言語の読む速さの標準の文）の論文の要旨には「Reading time (aloud) was measured by stopwatch」とあり、測ったのは音読です。日本語の値は本文の表にありますが、本文のページは 403 で開けませんでした。
  - 最初は仮の字数（例：2,000〜2,500字［推測］）で切ります。読み始めと読み終わりの時刻を端末の中で測り、あとで直せる形にします。
- **毎日届ける**
  - ウィジェット（WidgetKit）
    - 許可は要りません。1日1つの入れ替えなら、先に並べた予定で足ります（前回の調べもの）。
    - 今の作品と回の番号をアプリと分け合うために、App Groups が要ります。
    - App Group の UserDefaults の申告の理由は、まだ確かめていません（G1 で確かめる）。
  - ローカル通知
    - `UNCalendarNotificationTrigger` の繰り返しで、毎日同じ時刻に出せます。
    - 1つの予約は毎回同じ中身です。その日の作品名を入れるなら、日ごとに予約します。予約できる数の上限は、今の文書で確かめていません（未確認）。
    - 初回に許可のダイアログが出ます。
  - サーバーからの push は要りません。

### 5. 2週間で作れるか
- **作れる見込みです［推測］。** ただし、次の範囲に絞ります。
  - 作品は10〜30にし、変換はビルドの前に済ませる。
  - 読む画面は、WKWebView の縦書きで、横に流れるスクロールにする。
  - 今日の回、続きの位置、ウィジェット、通知、文字の大きさ。
  - 1ページずつめくる動きを足すなら、数日増える見込みです（未検証）。
- **いちばん大きい危険**
  - 縦書きの見え方は確かめられました。
  - 残るのは、VoiceOver での聞こえ方、実機での最初の表示の速さ、めくる作りです。どれもデザイン賞の審査で効きます。
- **いちばん安い確かめ方**
  1. 実機で30分（Takuma の iPhone）：今回の spike を入れ、VoiceOver をオンにして、ルビと縦中横の聞こえ方を聞きます。最初の表示の時間も見ます。
  2. Mac で半日：候補の作品をすべて変換するスクリプトを動かし、知らない注記と直せない外字を数えて出します。

## 音読の宿題（AI の採点はしない）

### 1. 録音と再生、保存、容量
- **AVAudioRecorder で足ります。**
  - 文書には「An object that records audio data to a file.」とあります。再生は AVAudioPlayer です。
  - AVAudioEngine が要るのは、録りながら音を加工するときや、あとで SpeechAnalyzer に流すときです。今回の範囲では要りません（AVAudioEngine の文書は今回開いていません）。
- **セッションの種類は playAndRecord を推します。**
  - record の文書：「This category has the effect of silencing virtually all output on the system … Unless you need to prevent any unexpected sounds from being played, use playAndRecord instead.」
- **中断への備え**
  - 文書：「Using this category doesn't prevent phone calls, alarms, or other nonmixable audio sessions from interrupting the audio session.」
  - 中断の知らせ（interruptionNotification）を受けたら、それまでの分を保存します。
- **端末の中だけに保存する**
  - 置き場所は Application Support にします。ファイルの保護は `completeUnlessOpen` を推します。
    - `complete` は「cannot be read from or written to while the device is locked」です。録音の途中でロックされると、書けなくなります。
    - `completeUnlessOpen` は「If the file is opened when unlocked, you may continue to access the file normally, even if the user locks the device.」です。閉じたあとは暗号化されます。
  - iCloud バックアップ
    - 何もしなければ、アプリのデータはバックアップに入ります。
    - 外す目印（isExcludedFromBackup）について、文書は「not a mechanism to guarantee those items never appear in a backup」としています。
    - Apple の「Collect」の定義では、バックアップは開発者の収集に当たりません。外すかどうかは Takuma が決めます（Q2）。
- **容量**（Mac で測った値。Kyoko の声で羅生門の1,100字を読ませ、195.5秒の音を作った）

| 形式 | 3分あたり | 毎日で1年 | 毎日で6年 |
|---|---|---|---|
| AAC 32kbps、モノラル、22.05kHz | 0.75MB | 0.27GB | 1.65GB |
| AAC 64kbps、モノラル、44.1kHz | 1.45MB | 0.53GB | 3.19GB |
| 圧縮なし（AIFF） | 7.94MB | 2.90GB | 17.39GB |

  - 声だけなら、32kbps のモノラルで足りる見込みです［推測。聞き比べはしていない］。
  - 何年分を残すか（例：判を押したものだけ残す）は pdm が決めます。

### 2. マイクの許可と、録音中の表示
- **許可を聞くのは、初めて「録る」を押したときにします。** 起動のときには聞きません。
  - HIG：「Request permission only when your app clearly needs access to the data or resource.」「Ideally, wait to request permission until people actually use an app feature…」
  - API は `AVAudioApplication.requestRecordPermission()`（iOS 17 から）です。
  - 説明の文（NSMicrophoneUsageDescription）がないままマイクを使うと、アプリは終わります（「the app exits」）。
  - 断られると、無音しか録れません（「it captures only silence」）。設定の開き方を出し、録らずに判を押す道を残します［推測］。
- **説明の文の案**：「音読の声を録って、あとで親子で聞き返すためにマイクを使います。録った声はこの iPhone の中だけに保存し、外には送りません。」
  - HIG は「Aim for a brief, complete sentence」としています。最後の文言は designer が決めます。
- **録音中の表示（2.5.14）**
  - 2.5.14：「Apps must request explicit user consent and provide a clear visual and/or audible indication when recording, logging, or otherwise making a record of user activity. This includes any use of the device camera, microphone…」
  - 画面には、赤い印、経った時間、音の大きさのメーターを出します。
  - 伏せている間は画面が見えません。始まりと終わりに短い音（耳で分かる合図）を足すのが安全です［推測。審査がどう読むかは未確認］。
  - システムが出すマイクの印（色の点）の公式の文書は、今回は開いていません。

### 3. 伏せたら録音を始める
- **001 の作りは、そのまま使えます。**
  - 使えるのは次のものです。どれも許可は要りません（前回の spike）。
    - UIDevice の向き（faceDown）
    - 伏せが1秒続いたら始める（O1）
    - 準備の画面が前にあるときだけ見る（O8、O9）
    - テストのつなぎ口 H15〜H18
- **ロックの影響はあります。ここが一番の論点です。**
  - 伏せて触らなければ、自動ロックの時間（30秒〜5分）で画面が消え、アプリは後ろに回ります。
  - record の文書：「To continue recording audio when your app transitions to the background (for example, when the screen locks), add the audio value to the UIBackgroundModes key」。audio を入れなければ、ロックで録音は止まります。
  - 選べる案は2つです。
    - (a) 録音中だけ画面を消さない（isIdleTimerDisabled を録音の間だけ true にする）。
      - アプリが前にいるので、向きの知らせが届きます。表に返したら止める、という動きを保てます。
      - Background Modes の文書は「If an alternative to executing in the background exists, use the alternative instead.」としています。(a) はこの「代わりの方法」に当たります。
      - 弱み：サイドボタンでロックすると、録音は止まります。止まるまでの分を保存する処理が要ります。
    - (b) Background Modes の audio を入れる。
      - ロックしても録り続けます。
      - 弱み：ロック中は向きの知らせが届かないので、表に返しても止まりません。顔認証で開いてから止めることになります［推測］。2.5.4 の「intended purposes」の説明も要ります。
  - 推奨は (a) です（Q1）。
  - どちらの案でも、ファイルの保護は completeUnlessOpen にします（1 に書いたとおり）。
- **持ち越しの未検証**
  - 画面の向きのロックがオンのときに、faceDown が届くかは未検証です。
  - 001 では確かめが要らなくなりました。ただ、音読で伏せる始め方を使うなら、また要ります。

### 4. 判を長押ししたときの触覚
- **iOS で鳴る種類**（SwiftUI の SensoryFeedback の文書）
  - success、impact、selection：「Only plays feedback on iOS and watchOS.」
  - alignment：「Only plays feedback on iOS and macOS.」
  - pathComplete：「Only plays feedback on iOS.」（iOS 17.5 から）
  - iPhone で鳴らないもの：increase（watchOS と visionOS だけ）、levelChange（macOS だけ）、start と stop（watchOS だけ。前回の調べもの）。
- **推す形**
  - 押し始めに `.selection` を、押し切って判が付いたときに `.impact(weight: .heavy)` か `.success` を鳴らします。
  - 「ぐっと押し込む」感じを細かく作るなら、Core Haptics（CHHapticEngine）で強さを上げていく形も作れます。許可は要りません。
  - ただし、文書は「the operating system could still override the request with system services」としていて、鳴らないこともあります。
- **気をつけること**
  - 録音中は、触覚とシステムの音を鳴らすかを決める設定があります（`setAllowHapticsAndSystemSoundsDuringRecording`、iOS 13 から）。判は、録音を止めてから押す流れにします。
  - iPad には触覚がありません（前回の調べもの）。見た目と音でも分かるようにします。
  - 長押しは、VoiceOver やスイッチコントロールでは難しい操作です。代わりの操作（accessibilityAction）を付けます（前回引いた HIG の「Offer alternatives to gestures」）。

### 5. Kids カテゴリーに入れるか、親向けとして出すか
| 作りで変わること | Kids カテゴリーに入れる | 親向けとして出す（Kids に入れない） |
|---|---|---|
| 外部の計測と広告 | 入れない。1.3：「should not include third-party analytics or third-party advertising」。例外は限られる | 入れられる。ただし、子どもの使い方を送ると 5.1.4 と法令がかかる。v1 は入れないことを推す |
| 外へのリンク、課金 | 保護者のゲートの奥にだけ置く。1.3：「unless reserved for a designated area behind a parental gate」 | 制限なし |
| 保護者のゲート | 作る。Apple の kids のページでは「adult-level tasks」。Apple の部品は見つけていないので、自分で作る | 要らない |
| 年齢帯 | 「5 and under, 6-8, or 9-11」から選ぶ | なし |
| 名前、画面写真、説明 | 子ども向けと書ける | 子どもが主な利用者と読める言葉を使えない（5.1.4：「Apps not in the Kids Category cannot include any terms in app name, subtitle, icon, screenshots or description that imply the main audience for the app is children.」）。2.3.8 でも「For Kids」「For Children」は Kids 用 |
| あとから外せるか | 1.3：「once customers expect your app to follow the Kids Category requirements, it will need to continue to meet…」 | - |
| 年齢の確かめ | Declared Age Range（iOS 26 から）で、保護者が子どもの年齢の幅を渡せる。文書には「You are solely responsible for ensuring compliance」とある。使う義務があるかは pdm と法務が確かめる（未確認） | 同じ |

- 「音読の宿題」という名前が「子どもが主な利用者」と読めるかは、pdm が決める範囲です。Kids に入れないなら、親が主な利用者だと読める名前にする必要がある見込みです［推測］。
- **子どもの声を端末の外に出さない場合に、要らなくなるもの**
  - App Privacy の申告の「Audio Data」。文書：「Data that is processed only on device is not "collected" and does not need to be disclosed in your answers.」
  - サーバー、送るときの暗号化、サーバーでの保存期間と消す仕組み、外の会社との契約。
  - 送る前の同意（前回の調べもので引いた 5.1.2(i)）。
  - 保護者の同意を取る仕組み（COPPA など）まで要らなくなるかは、法務の確認が要ります（未確認）。
- **それでも要るもの**
  - マイクの説明の文。
  - プライバシーポリシー（5.1.4 は、Kids のアプリに求めている）。
  - 親が録音を消せる画面。ファイルの保護。バックアップの扱いの決定。
  - 書き出しや共有の機能は付けない方が安全です。5.1.4 は、未成年の個人データを「have the capability to share」するアプリにも、プライバシーポリシーと子どものプライバシーの法令を求めています。

### 6. 2週間で作れるか
- **作れる見込みです［推測］。** 範囲は次のとおりです。
  - 録る、聞き返す、一覧、判を押す（触覚と動き）、伏せて始める。
  - 許可を断られたとき、中断のあとの保存。
- **いちばん大きい危険は、伏せている間の録音です。**
  - 自動ロック、中断、ファイルの保護、触覚が鳴るか、が重なります。どれもシミュレーターでは決められません。
  - 受け入れテスト（G3）には、録音の部品を差し替えるつなぎ口が要る見込みです（例：起動の引数で、決まった音のファイルを「録った」ことにする）。
  - シミュレーターで Mac のマイクから録れるかは、確かめていません（未検証）。
- **いちばん安い確かめ方は、Takuma の実機で30分です。**
  - flipspike に AVAudioRecorder を足した試作を入れ、自動ロックを30秒にして、伏せて3分録ります。
  - 見ること：
    - (a) と (b) で、録れた長さ
    - 伏せて始めた合図の触覚が鳴るか
    - 画面の向きのロックがオンのときの動き

## 技術の面でどちらが安全か
- **音読の宿題（AI の採点なし）が安全です。**
  - 部品が標準のもの（録音、再生、触覚、向き）だけで、使い方の例も多いです。VoiceOver と Dynamic Type も、標準の SwiftUI の部品のままで効きます。
  - 中身の変換（青空文庫）がなく、データの形も小さいです。
  - 001 の伏せる作り、つなぎ口、時刻の方針を使い回せます。
  - 残る危険（伏せている間の録音）は、実機の30分でほぼ決まります。
- **いちばん強い反論**
  - 音読の危険は、コードではなく、審査と子どものデータにあります。Kids の決まり、名前の言葉、保護者のゲートは、コードの出来に関係なく公開を止めうります。
  - 中心の体験（伏せて録る、ロック、触覚）はシミュレーターで試せません。G3 で verifier が決められる範囲は、名作より狭いです。
  - 一方、名作のいちばんの技術の危険（縦書きとルビ）は、今日の spike で大きく下がりました。
  - さらに、学校の端末で音読の宿題がすでに済んでいるなら（pdm が確かめ中）、技術の安全さは決め手になりません。
- この判断は私のものです。決める前に、reviewer に反論を出してもらってください。

## 質問（指揮役から Takuma へ）
- **Q1：音読の宿題を選んだ場合、伏せている間に画面が消えるとき、どう録り続けますか。**
  - 推奨：(a) 録音中だけ画面を消さない。
  - いちばん強い反論：サイドボタンでロックすると録音が止まる。机の上で画面が光り続ける。
  - 元に戻せるか：戻せる（あとで (b) を足せる）。
  - 見てほしいもの：この報告の「音読の宿題 3」。
- **Q2：音読の録音を、iCloud バックアップに入れますか。**
  - 推奨：入れる（何もしない）。機種を変えても子どもの声が残るためです。Apple の定義では、開発者の収集に当たりません。
  - いちばん強い反論：「声は端末の外に出ない」と言い切れなくなる（Apple の iCloud には入る）。
  - 元に戻せるか：これから録る分は切り替えられる。すでに取られたバックアップは戻せない。
  - 見てほしいもの：この報告の「音読の宿題 1」。
- **Q3：Takuma の実機で、30分の確かめをしますか。**
  - すること：
    - (1) 名作の縦書きの spike を VoiceOver で聞き、最初の表示の時間を見る。
    - (2) 音読の録音の試作で、伏せて3分録る。
  - 推奨：する。2つの候補の、いちばん大きい技術の危険を、両方ともいちばん安く消せます。
  - いちばん強い反論：1週間の確かめの中で、Takuma の時間を30分使う。録音の試作は、まだこれから作る（tech-lead の spike で手数10回ほど［推測］）。
  - 元に戻せるか：戻せる。
  - 見てほしいもの：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/two6/tatespike/FlipSpike/FlipSpikeApp.swift

## 根拠（開いた日はすべて 2026-10-16）
Apple の開発者の文書は、developer.apple.com/tutorials/data/documentation/<パス>.json の JSON で本文を読みました。

- 縦書きとルビ
  - https://developer.apple.com/documentation/coretext/ctframeprogression/righttoleft ：「Lines stack right to left for vertical text.」
  - https://developer.apple.com/documentation/coretext/kctverticalformsattributename ：「kCFBooleanTrue indicates that vertical glyph forms are to be used.」
  - https://developer.apple.com/documentation/coretext/kctrubyannotationattributename ：iOS 8.0 から
  - https://developer.apple.com/documentation/coretext/ctrubyannotation
  - https://developer.apple.com/documentation/coretext/kctframeprogressionattributename
  - https://developer.apple.com/documentation/uikit/uiaccessibilityreadingcontent ：「To give VoiceOver users a superior, continuous reading experience, you can implement this protocol on an element that represents readable content, characterize it with the causesPageTurn trait…」（iOS 5.0 から）
  - https://developer.apple.com/documentation/uikit/nstextlayoutorientationprovider ：「in iOS, only the NSTextContainer class implements it … If you define a custom NSTextContainer object, you can override this method and return NSLayoutManager.TextLayoutOrientation.vertical to support laying out text vertically.」
  - https://developer.apple.com/documentation/uikit/nstextlayoutmanager 、https://developer.apple.com/documentation/uikit/uitextview/init(usingtextlayoutmanager:)
  - https://developer.apple.com/documentation/webkit/webview-swift.struct ：iOS 26.0 から。「Present HTML, CSS, and JavaScript content alongside your app's native views with WebView.」。変える部品に webViewTextSelection(_:) がある
  - https://developer.apple.com/documentation/webkit/webpage
  - https://developer.apple.com/documentation/swiftui/text ：vertical と writing mode の語が0件（swiftui/view/writingmode は 404）
- 青空文庫
  - https://www.aozora.gr.jp/annotation/etc.html ：「ルビの付く文字が、漢字と仮名…異なった文字種によって構成されているときは、先頭に「｜」を入れて範囲を特定してください。」「一つの文字種のみからなるときは、「｜」はいりません。（平仮名と片仮名は、別の文字種とみなします。）」
  - https://www.aozora.gr.jp/annotation/external_character.html ：「※［＃「てへん＋劣」、第3水準1-84-77］」「「第3水準1-84-77」にあたる部分は、JIS X 0213 で規定されたコード番号（面区点番号）です。」「JIS X 0213にはないけれど、Unicodeにあるものは…※［＃「口＋世」、U+546D、ページ数-行数］」
  - https://www.aozora.gr.jp/annotation/ ：上に引いた「古い記法が残っている可能性」の文
  - 作品のページと zip：https://www.aozora.gr.jp/cards/000148/card773.html （こころ。zip は 153,688 バイト）。ほかに card127（羅生門）、card456（銀河鉄道の夜）、card1567（走れメロス）、card789（吾輩は猫である）、card752（坊っちゃん）
- 読む速さ
  - Europe PMC の要旨（DOI 10.1167/iovs.11-8284、PMID 22661485）：「436 normally-sighted native speakers (age 18-35 years, 25 per language, 36 in Japanese)」「Reading time (aloud) was measured by stopwatch.」
  - https://iovs.arvojournals.org/article.aspx?doi=10.1167/iovs.11-8284 ：403 で本文を読めなかった
  - WebSearch 2回では、日本語の黙読の値は見つからなかった
- 毎日届ける
  - https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app ：「Configuring the trigger with the repeats parameter set to true causes the system to reschedule the event after its delivery.」
  - https://developer.apple.com/documentation/usernotifications/uncalendarnotificationtrigger
- 録音
  - https://developer.apple.com/documentation/avfaudio/avaudiorecorder ：「An object that records audio data to a file.」
  - https://developer.apple.com/documentation/avfaudio/avaudiosession/category-swift.struct/record ：上に引いた3つの文
  - https://developer.apple.com/documentation/avfaudio/avaudiosession/category-swift.struct/playandrecord ：「To continue playing audio when your app transitions to the background (for example, when the screen locks), add the audio value to the UIBackgroundModes key」
  - https://developer.apple.com/documentation/xcode/configuring-background-execution-modes ：「Use background execution modes sparingly … If an alternative to executing in the background exists, use the alternative instead.」
  - https://developer.apple.com/documentation/bundleresources/information-property-list/uibackgroundmodes
  - https://developer.apple.com/documentation/avfaudio/avaudiosession/interruptionnotification
  - https://developer.apple.com/documentation/foundation/fileprotectiontype/complete と …/completeunlessopen ：上に引いた文
  - https://developer.apple.com/documentation/foundation/optimizing-your-app-s-data-for-icloud-backup ：上に引いた文
  - https://developer.apple.com/documentation/avfaudio/avaudioapplication/requestrecordpermission(completionhandler:) ：iOS 17.0 から。「captures only silence (zeroed out audio samples)」「the app exits」
  - https://developer.apple.com/design/human-interface-guidelines/privacy ：上に引いた3つの文
- 触覚
  - https://developer.apple.com/documentation/swiftui/sensoryfeedback と …/success、…/impact、…/selection、…/alignment、…/pathcomplete、…/increase、…/levelchange、…/impact(weight:intensity:) ：上に引いた「Only plays feedback on …」の文
  - https://developer.apple.com/documentation/avfaudio/avaudiosession/setallowhapticsandsystemsoundsduringrecording(_:) ：「Sets a Boolean value that indicates whether system sounds and haptics play while recording from audio input.」（iOS 13.0 から）
  - https://developer.apple.com/documentation/corehaptics/chhapticengine ：上に引いた文
- 審査と子ども
  - https://developer.apple.com/app-store/review/guidelines/ ：1.3、2.3.8、2.5.4（「Multitasking apps may only use background services for their intended purposes: VoIP, audio playback, location, task completion, local notifications, etc.」）、2.5.14、5.1.4（上に引いた文）
  - https://developer.apple.com/app-store/app-privacy-details/ ：「"Collect" refers to transmitting data off the device in a way that allows you and/or your third-party partners to access it for a period longer than what is necessary to service the transmitted request in real time.」と、上に引いた「processed only on device」の文、「"Audio Data" for voice recordings」
  - https://developer.apple.com/app-store/kids-apps/ （https://developer.apple.com/kids/ に転送された）：「Choose whether your app or game is appropriate for ages 5 and under, 6-8, or 9-11.」「Parental gates … are adult-level tasks that must be completed in order to continue using your app or game.」
  - https://developer.apple.com/documentation/declaredagerange ：iOS 26.0 から。上に引いた文
- 前回の調べもの（読み直しただけで、開き直していない）：docs/reviews/001-reading-session-angles-tech-lead.md、docs/reviews/001-reading-session-G0-tech-lead-flip-research.md、docs/reviews/001-reading-session-G0-tech-lead-r1.md（1-b）

## 変更したファイル
- リポジトリの中：なし。
- リポジトリの外（どれも消してかまいません）
  - spike の本体（前回の flipspike を写して作った）
    - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/two6/tatespike/FlipSpike/FlipSpikeApp.swift
    - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/two6/tatespike/FlipSpike/Content.swift （gen.py が作った羅生門の本文）
    - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/two6/tatespike/FlipSpikeUITests/FlipSpikeUITests.swift
  - 画面の写しと部品の木：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/two6/shots/（web_default.png、ct_default.png、tk1_default.png、web_ax5.png、ct_ax5.png、tk2_ax5.png と .txt）
  - スクリプト：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/two6/scripts/（dl.py、aoz.py、gen.py、gaiji_all.py）
  - 取ったもの：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/two6/ の aozora、audio、dl、txt、html
  - シミュレーター（iPhone 17、C91AC080-8604-4C83-BB86-1B3B6AB25726）は起動したままです。文字の大きさは、最後に Large に戻しました。

## 実行したコマンドと結果
- 文書の取り込み：前回の fetch_docs.sh と fetch_html.sh で、Apple の文書42件とページ6件を取りました。
  - 404 は3件：uikit/nstextcontainer/layoutorientation、bundleresources/privacy-manifest-files/describing-use-of-required-reason-api、swiftui/view/writingmode。
  - 申告の理由のページ（nsprivacyaccessedapitypereasons）は取れましたが、App Group の語は出ませんでした。
- 青空文庫：dl.py で6作品を取り、aoz.py で数えました（上の表）。gaiji_all.py の出力は「mapped=44 unmapped=2」です。
- 変換：gen.py で羅生門を変換しました。出力は「runs=258 ruby=129 gaiji ok=3 ng=0 chars=5749」です。
- spike（Xcode 27.0（27A266a）、iPhone 17 のシミュレーター）
  - 1回目（Large）：`xcodebuild test`
    - web：`web load=3054ms js=4972,402,17px,vertical-rl`。部品の木に StaticText が297。ラベルの例は「下人げにんが、」と「試し：傍点と月、「かぎ括弧」。」。
    - ct：`ct pages=13 chars=5749 layoutAll=23.0ms font=17.0pt`。部品の木に文がない。
    - tk1：`com.example.flipspike crashed`、`Failed to get matching snapshot: Application com.example.flipspike is not running`。画面の写しはホーム画面。
    - このあと xcodebuild が診断を集め続け、600秒で終わらなかったので、`pkill -f` でこの xcodebuild だけを止めました。
  - 2回目（AX5）：`xcrun simctl ui … content_size accessibility-extra-extra-extra-large` のあと、`xcodebuild test … -collect-test-diagnostics never`
    - 結果：`** TEST SUCCEEDED **`（41.6秒）
    - web：`web load=2895ms js=46799,402,53px,vertical-rl`
    - ct：`ct pages=87 chars=5749 layoutAll=30.2ms font=48.0pt`
    - tk2：`tk tk2=true containerOrientation=vertical content=394x0 bounds=402x764`。画面の写しは、横に寝た字の1行で、ルビなし。
- 音：`say -v Kyoko` で195.5秒の音を作り、`afconvert` で AAC にしました。`afinfo` の値は `bit rate: 32613 bits per second` です。大きさは上の表のとおりです。
- ガードに2回止められました（書き先のパスに `$` があったため）。回り道はせず、書き先をそのまま書くか、Python のスクリプトの中で書く形にして、実行し直しました。
- WebSearch 2回、WebFetch 1回（IOVS で 403）、Europe PMC の API 1回。

## 未検証
1. 日本語の黙読の速さ（1分に何字か）の確かな出典。IReST の日本語の値は、本文が 403 で読めなかった。
2. 実機での WKWebView の最初の表示の時間とメモリ（シミュレーターでは 2.9〜3.1秒）。
3. WKWebView を VoiceOver で読んだときの実際の聞こえ方（部品の木だけを見た）。rt を読み上げから外す手当てが効くか。
4. WKWebView で縦書きを1ページずつめくる作り（CSS の段組か JS）。
5. WKWebView の文字の選択（spike では触っていない）。
6. TextKit 1 が落ちた原因。自前の view で NSLayoutManager に描く形なら動くか。TextKit 2 は1つの組み方しか試していない。
7. SwiftUI に縦書きの指定がないこと（Text のページを見ただけ。iOS 27 の新しい API は全部は見ていない）。
8. Core Text で傍点を出す属性（今回は見ていない）。
9. すでにある変換の道具（aozora2html など）の有無とライセンス。
10. ローカル通知を予約できる数の上限（今の文書）。
11. App Group の UserDefaults の申告の理由（G1 で確かめる）。
12. `allowHapticsAndSystemSoundsDuringRecording` の既定の値と、録音中に触覚が本当に止まるか。
13. シミュレーターで録音できるか（Mac のマイク）。G3 の差し替えのつなぎ口の形。
14. 画面の向きのロックがオンのときに faceDown が届くか（001 からの持ち越し）。
15. Background Modes の audio を使ったときの審査（2.5.4）の受け止め。
16. システムが出すマイクの印の公式の文書。伏せている間の音の合図で 2.5.14 を満たせるか。
17. 端末の中だけに置く子どもの声が、COPPA や個人情報保護法でどう扱われるか（法務）。
18. Declared Age Range を使う義務があるか（pdm と法務）。
19. 32kbps の音質で、音読の聞き返しに足りるか（聞き比べはしていない）。
20. 2つの候補の2週間の見積もり（どちらも［推測］。表示の部分だけ spike がある）。

## git status --short
最後に `cd /Users/takumamatsuura/reading-app && git status --short` を実行しました。出力は空でした（変更なし）。

## 記録（指揮役が保存するときに書き足す）
- 種類：方向の見直しの確かめ（tech-lead）。PASS / FAIL なし
- BASE=c50f2baf01780251357744afb8bc9d042db7236a
- 日付：2026-10-16
