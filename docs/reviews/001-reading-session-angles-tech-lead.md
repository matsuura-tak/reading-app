（指揮役の注）これは判定ではなく、方向の見直しのための調べもの（tech-lead）の報告。Takuma が「ニーズにコミットしているか、埋もれないか」を問い直したため、指揮役が出した4つの角度（①スマホを開いた瞬間を読書に、②読んだことを忘れない、③読みにくい目でも紙の本を、④音読の宿題）の実現性を調べた。報告の文はそのまま保存した。

# 読書アプリの方向の調べもの その5：4つの角度の実現性（tech-lead。BASE=64d1446）

判定の前の調べものなので、PASS や FAIL は付けていません。リポジトリの中のファイルは何も書いていません。spike もしていません。根拠はすべて 2026-10-16 に開いたもので、Apple の文書が中心です。公式でないものには「公式でない」、自分の見立てには［推測］と付けています。

## 結論
- **4つとも iOS だけで作れます。サーバーも要りません。** 例外は③で、端末の中の読み取りでは足りず外部の OCR を使う場合だけ、API の鍵を隠すサーバーが要ります。
- **一番の問題は角度ごとに違います。**
  - ①：配るには、Apple に Family Controls の entitlement を承認してもらう必要があります。承認までの期間は読めません。
  - ②③④：Vision は縦書きの日本語をそのままでは読めない見込みです。
  - ④：さらに、子どもの声の聞き取りの精度と、子ども向けアプリの審査の決まりが重なります。
- **2週間で作れる範囲［推測］**
  - ②と、①のショートカット型は、最初の形まで通しで作れます。
  - ④は「録音と時間の記録、励まし」までです。聞き取っての判定は入りません。
  - ①の Screen Time 型は、コードと Takuma の実機での試作までは作れます。ただし、外の人に配れるのは Apple の承認が出てからです。
  - ③は、横書きの試作までです。
- **新しく分かったこと（ほかの役の判断に効くもの）**
  1. **①：止める画面から自分のアプリを開けます。** `ShieldActionResponse.openParentalControlsApp` を使います。対応は **iOS 26.5 から**で、26.0〜26.4 では開けません。
  2. **①：ガイドライン 4.10 に「Screen Time の API を課金の対象にしてはいけない」とあります。** 止める機能そのものを有料にはできません。PRD の 16（収益化）に効きます。
  3. **②③④：縦書きは横書きに直してから読む必要がありそうです。** Apple の DTS の回答は「行を90度回して横に並べ、1字ずつ起こしてから読む」でした。文庫本と小学校の国語の教科書は縦書きが多く、3つの角度すべてに効きます。
  4. **③：iOS 26 の Accessibility Reader と重なります。** Apple は、拡大鏡の中で「本などの文字を読みやすい形にし、読み上げる」と発表しています（2025-05-13）。③の中心と同じです。
  5. **④：SpeechAnalyzer（iOS 26）は、声を Apple のサーバーに送りません。** 許可はマイクの1回で済む見込みです。日本語が使えるかは、端末で実行して確かめる必要があります。
  6. **④：子ども向けに見せると、審査で次のどちらかがかかります。**
     - Kids カテゴリに入れる場合：外部の分析を入れない、保護者のゲートを置く、という決まりがあります。
     - 入れない場合：名前や画面写真に「子どもが主な利用者」と読める言葉を使えません（2.3.8、5.1.4）。
     - r1 で推した計測（Q4 の (b) 外部の分析）は、Kids カテゴリの決まりとぶつかります。

## 比べの表
| 角度 | 作れるか | 許可のダイアログ | entitlement | バックエンド | 2週間で最初の形［推測］ | いちばんの危険 | 費用（1,000人あたり／月） | 001 の使い回し |
|---|---|---|---|---|---|---|---|---|
| ① Screen Time 型（止めて、続きに誘う） | 作れる。本人の承認（individual）は iOS 16 から。止める画面から開くのは 26.5 から | Family Controls の承認が1回で、続けて Face ID か Touch ID。26.5 より前に通知で誘うなら、通知の許可でもう1回 | **要る**：com.apple.developer.family-controls。配るには Apple の承認が要り、**アプリと拡張のそれぞれに申請する**（拡張は止める画面の見た目、ボタンの処理、時間の監視の3つの見込み）。データの受け渡しに App Groups（承認は不要） | 要らない | コードと実機の試作は作れる。外への配布（TestFlight の外部テスト、App Store）は承認待ち。待ちはフォーラムの報告で数日から1か月超、返事がない例もある（公式でない） | 承認の待ちと可否を、こちらで決められない。中心の流れはシミュレーターで試せない見込み（未検証） | 0ドル | 高い。本、読書の記録、時刻の方針 1-b、伏せる始め方をそのまま使える |
| ①' ショートカット型（one sec の方法） | 作れる | 0回。代わりに、利用者がショートカットのアプリで、対象のアプリごとにオートメーションを手で作る | なし | 要らない | 作れる | 設定の手間で離脱する。止めずに割り込むだけ。OS の更新で動きが変わっても、守られる約束がない | 0ドル | 高い（①と同じ） |
| ② Readwise 型（一節を撮って残し、忘れたころに戻す） | 横書きは作れる。縦書きは spike が要る | カメラが1回。写真から選ぶだけなら0回。通知は1回（仮の許可にすれば0回だが、通知センターに静かに入るだけ） | なし。ウィジェットとの受け渡しに App Groups | 要らない（あとで iCloud の同期） | 作れる。撮る、範囲を選ぶ、残す、ウィジェットと通知で戻す、までの通し。読めないときは手で打つ逃げ道を置く | 縦書きの読み取り。ルビが混ざる | 0ドル | 低い〜中くらい。本の型と保存の土台だけ |
| ③ 読みにくい目（大きな文字にする、読み上げる） | 横書きは作れる。縦書きとルビは自前の処理か外部の OCR が要る | カメラが1回 | なし | 端末の中で足りれば要らない。外部の OCR を使うなら要る（stacks の変更なので Takuma が決める） | 横書きの試作まで。縦書きとルビを含めると4〜8週。精度が出る保証はない | 縦書きとルビの読み取り、読む順番。Accessibility Reader と重なる | 0ドル。外部の OCR なら約450ドル（Google Cloud Vision。1人1日10ページの仮定） | 低い |
| ④ 音読の宿題 | 作れる。SpeechAnalyzer（iOS 26）で端末の中で聞き取る。日本語が使えるかは実行時に確かめる | マイクが1回（SpeechAnalyzer だけを使う場合）。SFSpeechRecognizer を使うなら、音声認識の許可でもう1回 | なし | 要らない（親が別の端末で見るなら要る） | 録音、時間、親のサイン、励ましまで。「聞いて判定する」は4〜6週 | 子どもの声の精度。手本の文（教科書は縦書きで、文を取り込むと権利の問題もある）。子ども向けの審査 | 0ドル | 中くらい。読む時間の数え方と時刻の方針 1-b を使える |

## 角度ごとの中身

### ① スマホを開いた瞬間を読書に変える
- **本人の承認（individual）は使えます。**
  - Apple の文書：「Authorizing parental controls for an individual requires approval from the owner of the device. The system displays a biometric authentication alert」
  - 一度承認すれば、そのあとは Face ID も出ません。
  - 本人はいつでもアプリを消せます（「the user can delete an authorized app」）。続けるかどうかは本人しだいの仕組みです。
- **配布用の entitlement の手順**
  - 申請は Account Holder（Takuma）が行います。窓口は「Family Controls distribution」のフォームか、Certificates, Identifiers & Profiles の Capability Requests です。
  - 拡張にも同じ申請が要ります：「submit the same request for the extension」。
  - 承認されると状態が Assigned になります。配り方の一覧（Provisioning Support）に、要る配り方がすべて入っているかを確かめます。
  - 審査の基準と期間は公開されていません。フォーラムの報告では2日〜1か月超で、返事がない例もあります（公式でない）。
  - 本人用（individual）は API が正式に想定している使い方で、one sec も Screen Time の API を使っています（検索の要約で見たもの）。なので、断られる危険は中くらい以下と見ます［推測］。
  - 申請のページはサインインが要り、本文は見られませんでした。
- **止める画面（ShieldConfiguration）で変えられるもの**
  - 変えられるのは次の項目だけです。ビューを自由に置くことはできません。
    - 背景のぼかしと色
    - アイコン
    - 見出しと副題
    - 主のボタンの文字と色
    - 副のボタンの文字
    - 副のボタンの小さなメニュー（最大3項目。iOS 26.4 から。例は「1 more minute」）
  - 拡張は閉じた環境で動き、「prevents your extension from making network requests」とあります。返すのが遅いと、標準の見た目に戻ります。
  - 本の名前やページを画面に出すには、App Group から読めるかを試す必要があります（未検証）。
- **止める画面から自分のアプリを開けるか**
  - iOS 26.5 からは開けます：`.openParentalControlsApp`「An instruction for the system to open your parental controls app」。
  - iOS 26.4 までの応答は `.close`、`.defer`、`.none` だけで、開けません。
    - その場合は、閉じたあと通知で誘う形になり、通知の許可が要ります。拡張から通知を出せるかは未検証です。
  - r1 の T1（最低の対応 OS を iOS 26.0 にする案）を保つなら、版で分けます。26.5 以上は直接開き、それより前は通知にします。
- **流れの案**
  1. 始めの案内で承認してもらう。
  2. FamilyActivityPicker で SNS を選んでもらう。選んだものはアプリの名前でなく、中身の見えない値で返る。
  3. ManagedSettingsStore で止める。
  4. 止める画面に「続きを読む」と「あと5分」を出す。
  5. 「続きを読む」でアプリを開き、001 の読書の画面から始める。伏せて始めてもよい。
  6. 「あと5分」なら止めるのを外し、DeviceActivity の監視でまた止める。
  - 作るものは、アプリと拡張3つの、合わせて4つです［推測］。
- **ショートカット型（①'）**
  - Apple のサポート文書：「Some personal automations can run without asking you for confirmation」「The automation will not notify you when it's triggered.」。確認なしで動かせる一覧に「App」が入っています。
  - アプリを前に出す仕組みは、AppIntent の `supportedModes`（iOS 26。`openAppWhenRun` は deprecated）を使います。
  - 利点：entitlement なしで、許可のダイアログも0回です。
  - 制限：
    - 利用者が対象のアプリごとに手でオートメーションを作る。アプリから作る API は見つけていない（未確認）。
    - 止めずに割り込むだけ。
    - 元のアプリに戻すと、オートメーションがまた動く。戻してから一定の時間は割り込まない、といった手当てが要る［推測］。
    - 画面のテストで設定まで通すのは難しい［推測］。
- **審査で気をつけること**
  - 4.10：「You may not monetize … Screen Time APIs」。
  - 5.1.2(iv)：ほかにどのアプリが入っているかの情報を、分析や広告に使えない。①' で対象のアプリの名前がアプリに分かっても、計測のイベントには入れません。
  - visionOS では承認がいつも失敗します（「authorization attempts always fail」）。前回の Q-E（Vision Pro に配らない）と合います。
- **いちばん安い確かめ方**
  1. 承認の待ちが一番長い工程なので、①を候補に残すなら、Takuma が今日、アプリと拡張の Bundle ID で申請を出します。申請だけなら費用はかかりません。
  2. Takuma の実機で、開発用の entitlement を使って1日の spike をします。見ること：承認、アプリを選ぶ、止める、止める画面の見た目、App Group のデータを読めるか、26.5 で自分のアプリが開くか。

### ② 読んだことを忘れない
- **文字の読み取り**
  - Vision の読み取りは端末の中で動きます：「all of Vision's processing happens on the user's device」。
  - 日本語：Apple の機能の対応表で、Live Text の言語に Japanese が入っています。API で使う言語は `recognitionLanguages` で決めます。指定しないと英語に寄ります（「biases its results toward English」）。
  - 使える部品：
    - DataScannerViewController：カメラの映像で読む。カメラの許可が要り、A12 以上。
    - ImageAnalyzer と ImageAnalysisInteraction：撮った写真の上で、利用者が文字を選べる（Live Text）。
    - RecognizeDocumentsRequest：iOS 26 から。説明に「textbook pages」とある。
- **縦書き**
  - Apple の文書に記載はありません。
  - Apple の DTS の回答（開発者フォーラム 772972、2025年1月）：「rotate a line of characters 90 degrees to a form horizontal line, and then rotate each character 90 degrees」。さらに、VNRecognizeTextRequest は向きを渡せないので RecognizeTextRequest を勧めています。
  - iOS 26 の RecognizeDocumentsRequest が縦書きを読めるかは、未検証です。
- **ルビ**：文書に記載はありません。本文に小さな文字が混ざると見込みます（未検証）。
- **許可**
  - カメラ：DataScanner の文書に「NSCameraUsageDescription … a person must agree when the system dialog first appears」。
  - 写真から選ぶ（PHPicker）は許可不要：「The user doesn't need to explicitly authorize your app to select photos」。
- **忘れたころに戻す仕組み**
  - ウィジェット：ホーム画面とロック画面に置けて、許可は要りません。更新には1日の枠があります（「WidgetKit uses a budget」）。1日1つ出す程度なら、先に並べたタイムラインで足ります［推測］。
  - ローカル通知：初回に許可のダイアログが出ます。仮の許可（provisional）ならダイアログは出ませんが、「only appear in the notification center's history」（通知センターの履歴に入るだけ）です。
- **いちばん安い確かめ方**
  - Mac で半日。Vision は macOS にもあるので、Swift の小さなスクリプトで次を比べます：文庫本の縦書き10ページと横書き10ページの写真について、RecognizeTextRequest（向きを変えたものも含む）と RecognizeDocumentsRequest の、文字の誤りの率。
  - 正解の文は手で打ちます。実機での確かめは、あとで2〜3枚だけ行います。

### ③ 読みにくくなった目でも紙の本を
- **読み取り**：②の危険に加えて、1ページ全体の読む順番（右の行から左へ）と、ルビを外す（または読みとして使う）処理が要ります。縦書きの小説では、ここが中心で、いちばん難しい所です。
- **読み上げ（AVSpeechSynthesizer）**
  - 声の質は default、enhanced、premium の3段階です。
  - この Mac には日本語の声として Kyoko などが入っていました（`say -v '?'` で見た macOS の一覧で、参考だけ）。
  - iOS で拡張版の声をアプリから入れる API は、読んだ文書の範囲で見つけていません（未確認）。利用者に設定から入れてもらう前提です。
- **読み上げの位置**：`willSpeakRangeOfSpeechString` は「once for each unit of speech … which is generally a word」です。日本語でどの細かさで届くかは未検証です。
- **読みの直し**：漢字の読み違いは `AVSpeechSynthesisIPANotationAttribute` と SSML で直せる見込みですが、日本語で効くかは未検証です。
- **大きな文字で組み直す**
  - 横書きに流し直すのは、Dynamic Type で簡単です。
  - 縦書きとルビで組むなら、Core Text の CTRubyAnnotation（文書のページはある）か、WKWebView の CSS を使います（どちらも未検証）。
- **権利（気づいた範囲）**：本人が自分の本を撮って自分で読むのは、私的な使用のための複製に当たる見込みです［未確認。法務の確認が要る］。読み取った文を送る、共有する、書き出す機能を付けると危険が上がるので、端末の中だけにします。
- **重なり**：Apple の発表は「Accessibility Reader can be launched from any app, and is built into the Magnifier app … so users can interact with text in the real world, like in books」。iOS 26 で出たか、日本語の縦書きに対応しているかは確かめていません。
- **外部の OCR を使うときの費用**：Google Cloud Vision は「the first 1000 units used each month are free」、その上は1,000枚あたり1.50ドルです。1,000人が毎日10ページなら、月に30万枚で約450ドルです［仮定］。本のページの画像を外に送るので、5.1.2(i) の明示の同意と、プライバシーの申告が要ります。
- **いちばん安い確かめ方**：②と同じ Mac のスクリプトに加えて、Takuma の iPhone の拡大鏡で、縦書きの文庫本に Accessibility Reader を5分試します。標準の機能で十分に読めるなら、③の差はほとんど残りません。

### ④ 音読の宿題を、親子の楽しい時間に
- **端末の中だけで聞き取れるか**
  - SpeechAnalyzer と SpeechTranscriber（iOS 26）：「SpeechAnalyzer transcriber modules don't send audio data of the user's voice to Apple's servers.」
  - 対応する言語は、実行時に `supportedLocales` で確かめます（「including locales that may not be installed but are downloadable」。端末が対応しないと空になる）。対応しなければ DictationTranscriber に切り替えます（「compatible with older devices」）。
  - 日本語の手がかり：Apple の機能の対応表で、端末の中の音声入力、メモの音声の書き起こし、ライブキャプションに Japanese が入っています。ただし、これは API が日本語に対応している証拠にはならず、未検証です。
  - 古い SFSpeechRecognizer は向きません。通信を使う形には「one-minute limit on audio duration」があり、端末の中の形は「won't be as accurate」です。
- **許可**
  - マイクは要ります。
  - 音声認識の許可について、文書は「This process only applies to speech recognition using SFSpeechRecognizer」としています。NSSpeechRecognitionUsageDescription も「APIs that send user data to Apple's speech recognition servers」のためのものです。SpeechAnalyzer だけなら、ダイアログはマイクの1回の見込みです（実機では未検証）。
- **子どもの声の精度**：Apple の文書には記載がありません。研究では、子どもの読み上げの単語の誤りの率が約40%（CSLU Kids）、大人が2%未満（LibriSpeech）という報告があります（arXiv 2502.08587。英語で、検索の要約で見たもの）。日本語の子どもの声での数字は見つかりませんでした。
- **手本の文**：国語の教科書は縦書きにルビ付きが多く、②③と同じ読み取りの問題が出ます。教科書の文をアプリに入れて配るのは権利の上で難しいので、手本と比べるなら、利用者が撮った文を端末の中だけで使います。
- **子ども向けの審査**
  - 1.3：「must not include links out of the app, purchasing opportunities … unless reserved for a designated area behind a parental gate」「should not include third-party analytics or third-party advertising」
  - 5.1.4：未成年から写真、動画、声などの個人データを集める、送る、共有できるアプリは、プライバシーポリシーと子どものプライバシーの法令に従う必要があります。さらに「Apps not in the Kids Category cannot include any terms … that imply the main audience for the app is children.」
  - 録音を端末の中から出さなければ、「集める」には当たりにくいです（r1 の 4：端末の中だけのデータは収集に当たらない）。
- **テスト**：AssetInputSequenceProvider で、音声のファイルを入れて試せます。シミュレーターでも、マイクなしで受け入れテストを組める見込みです［推測］。
- **いちばん安い確かめ方**：Mac で `SpeechTranscriber.supportedLocales` を表示します（5分）。そのうえで、家族の同意を得た子どもの音読の録音3〜5本を書き起こし、文字の誤りの率を出します。録音は端末の外に出さず、終わったら消します。

## すべての角度に共通すること
- **最低の対応 OS への影響**
  - ①：直接開くのは 26.5 から。止める画面の小さなメニューは 26.4 から。
  - ④：SpeechAnalyzer が 26.0 から。
  - ②③：RecognizeDocumentsRequest が 26.0 から。
  - どれも、r1 の T1 で推した iOS 26.0 とは、版で分けて扱えます。
- **申告（PrivacyInfo.xcprivacy）**
  - カメラ、マイク、音声認識、Screen Time は、理由の申告が要る5つの区分に入りません（前回の調べもの 7）。
  - App Group の UserDefaults を使う場合（①と、②のウィジェット）は、CA92.1 と別の理由になる見込みです（未確認。G1 で確かめる）。
- **審査 4.3(b)**：4つとも、r1 の指摘2の「simple timers」からは遠ざかります。
- **これまでの 001 の作業の使い回し**
  - ①：時刻の方針 1-b、本と読書の記録、伏せる始め方を、誘ったあとの読書でそのまま使えます。
  - ④：時間の数え方を使えます。
  - ②③：本の型だけです。
  - 許可0回（AC-24）の約束は、①'（ショートカット型）以外の全部で崩れます。

## tech-lead として、技術の面で推す角度
- **推すのは②です。**
  - 理由：
    - entitlement も、サーバーも、通信も要りません。
    - 2週間で通しの形まで作れます。
    - 受け入れテストの大半をシミュレーターで回せます［推測］。画像を入れて読み取る、ウィジェットのタイムラインを見る、予定した通知を見る、の3つです。この組織の G3 の進め方（verifier が画面のテストを書く）に合います。
    - 縦書きが読めなくても、「撮った写真の上で利用者が範囲を選ぶ」「手で打つ」で、価値の筋は残ります。
  - いちばん強い反論：日本の紙の本の多くは縦書きです。撮って残す体験が縦書きで崩れると、手で打つだけの弱いアプリになります。それに、Readwise の価値の大きな部分は電子書籍のハイライトを自動で取り込むことで、紙を撮るだけでは弱い、とも言えます［推測］。だから、pdm が決める前に、縦書きの spike（Mac で半日）を入れるべきです。
- **次点は①です（条件付き）。**
  - 技術の面の壁は「Apple の承認の待ち」と「中心の流れを実機でしか試せない」の2つです。コードの難しさではありません。
  - ニーズへの踏み込みが一番強いのが①なら（決めるのは pdm）、承認の待ちが一番長い工程なので、今日申請を出し、並べて実機で1日の spike をすれば、技術の危険は早く消せます。
  - ショートカット型（①'）は承認が要りませんが、設定の手間と「止めない」性質があり、one sec と同じ作りになります。
- **推さないもの**
  - ③：差になるはずの縦書きとルビが一番難しく、しかも標準の Accessibility Reader と重なります。
  - ④：子どもの声の精度、教科書の縦書きと権利、子ども向けの審査が重なり、2週間では「聞いて励ます」の核まで届きません。
- この推奨は私の判断です。G0 で、reviewer に反論を出してもらってください。

## 質問（指揮役から Takuma へ）
- **Q1：①を候補に残すなら、Family Controls の配布用の申請を今出しますか。**
  - 推奨：出す。アプリと拡張3つの Bundle ID で出します。Account Holder だけが出せます。
  - いちばん強い反論：方向が決まる前の申請は、無駄になりうる。
  - 元に戻せるか：戻せる。費用はかかりません。
  - 見てほしいもの：この報告の①。
- **Q2：縦書きの読み取りの spike（Mac で半日、リポジトリの外）をしてよいですか。**
  - 写真は、手元の文庫本の縦書き10ページと横書き10ページを、Takuma に撮ってもらいます。
  - 推奨：する。②③④のすべてにかかるためです。
  - いちばん強い反論：撮影の手間がかかる。
  - 元に戻せるか：戻せる。
- **Q3：④を残すなら、子どもの声の録音を spike に使ってよいですか。**
  - 条件：家族の同意、端末の中だけ、終わったら消す。
  - 推奨：④を残す場合だけ行う。
  - いちばん強い反論：子どもの声のデータは扱いが重い。
  - 元に戻せるか：消せば戻せる。

## 根拠（開いた日はすべて 2026-10-16）
Apple の開発者の文書は、developer.apple.com/tutorials/data/documentation/<パス>.json の JSON で本文を読みました。
- ①
  - https://developer.apple.com/documentation/familycontrols ：individual の承認の文と、visionOS で失敗する文（上に引いたもの）
  - https://developer.apple.com/documentation/familycontrols/authorizationcenter ：「the system displays an alert. If the individual chooses to continue, the device asks to authorize that individual using Face ID or Touch ID.」
  - https://developer.apple.com/documentation/familycontrols/authorizationcenter/requestauthorization(for:) ：iOS 16.0 から。削除できる旨の文
  - https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.family-controls ：「Before submitting your app to the App Store, you must request permission to use the entitlement.」
  - https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement ：「submit the same request for the extension」「Apple reviews your app, and if it's approved…」
  - https://developer.apple.com/documentation/familycontrols/familyactivitypicker ：「includes applications and websites from that same device」「opaque values」
  - https://developer.apple.com/documentation/managedsettingsui ：「custom button style, titles, icons, colors, and submenu items」
  - https://developer.apple.com/documentation/managedsettingsui/shieldconfiguration ：初期化の項目（上に並べたもの）
  - https://developer.apple.com/documentation/managedsettingsui/shieldconfiguration/secondarybuttonsubmenuitems ：iOS 26.4 から、「Add up to three array elements」
  - https://developer.apple.com/documentation/managedsettingsui/shieldconfigurationdatasource ：閉じた環境と、遅いときの標準の見た目の文
  - https://developer.apple.com/documentation/managedsettings/shieldactionresponse ：close、defer、none、openParentalControlsApp
  - https://developer.apple.com/documentation/managedsettings/shieldactionresponse/openparentalcontrolsapp ：iOS 26.5 から（文は上に引いたもの）
  - https://developer.apple.com/documentation/deviceactivity/deviceactivitymonitor ：「Shielding an app dims the app's icon … When the app launches, the system covers it with a view that your app can configure.」
  - https://developer.apple.com/documentation/appintents/appintent/openappwhenrun ：「This property is deprecated. Use supportedModes instead.」
  - https://developer.apple.com/documentation/appintents/appintent/supportedmodes ：iOS 26.0 から。「Specify the immediate foreground mode to bring the app to the foreground before the action runs.」
  - https://support.apple.com/guide/shortcuts/add-automations-apdfbdbd7123/ios （intro-to-personal-automation から転送された）：上に引いた2つの文と、一覧の「App」
  - https://developer.apple.com/app-store/review/guidelines/ ：4.10、5.1.2(iv)、1.3、2.3.8、5.1.4（上に引いたもの）
- ②③
  - https://developer.apple.com/documentation/vision/recognizing-text-in-images ：端末の中で動く文と、英語に寄る文
  - https://developer.apple.com/documentation/visionkit/datascannerviewcontroller と …/issupported ：カメラの許可、A12、visionOS では false
  - https://developer.apple.com/documentation/vision/recognizedocumentsrequest ：iOS 26.0 から、「textbook pages」
  - https://developer.apple.com/documentation/vision/recognizetextrequest （iOS 18 から）、https://developer.apple.com/documentation/vision/vnrecognizetextrequest
  - https://www.apple.com/ios/feature-availability/ ：Live Text、端末の中の音声入力、メモの音声の書き起こし、ライブキャプションの言語に Japanese がある
  - https://developer.apple.com/forums/thread/772972 （DTS の回答。上に引いたもの）
  - https://developer.apple.com/documentation/photokit/delivering-an-enhanced-privacy-experience-in-your-photos-app ：上に引いた文
  - https://developer.apple.com/documentation/widgetkit と …/keeping-a-widget-up-to-date ：ロック画面、更新の枠
  - https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications ：初回のダイアログと、仮の許可の文
  - https://developer.apple.com/documentation/avfaudio/avspeechsynthesizerdelegate/speechsynthesizer(_:willspeakrangeofspeechstring:utterance:) ：上に引いた文
  - https://developer.apple.com/documentation/avfaudio/avspeechsynthesisvoicequality 、…/avspeechutterance （init(ssmlRepresentation:) が一覧にある）、…/avspeechsynthesisipanotationattribute
  - https://developer.apple.com/documentation/coretext/ctrubyannotation （ページがあることだけを確かめた）
  - https://www.apple.com/newsroom/2025/05/apple-unveils-powerful-accessibility-features-coming-later-this-year/ （2025-05-13）：上に引いた文
  - https://cloud.google.com/vision/pricing ：「first 1000 units used each month are free」、1,000枚あたり1.50ドル、「Charges are incurred per image.」
- ④
  - https://developer.apple.com/documentation/speech/asking-permission-to-use-speech-recognition ：上に引いた注
  - https://developer.apple.com/documentation/speech/speechtranscriber 、…/supportedlocales 、…/dictationtranscriber 、…/speechanalyzer
  - https://developer.apple.com/documentation/speech/sfspeechrecognizer ：1分の制限と、1日の回数の制限
  - https://developer.apple.com/documentation/speech/sfspeechrecognitionrequest/requiresondevicerecognition ：「on-device requests won't be as accurate」
  - https://developer.apple.com/documentation/bundleresources/information-property-list/nsspeechrecognitionusagedescription 、…/nsmicrophoneusagedescription 、…/nscamerausagedescription
- 公式でない手がかり（根拠にはしていない）
  - [Family Controls (Distribution) entitlement — typical review timeline?](https://developer.apple.com/forums/thread/809190)
  - [Family Controls Distribution Entitlement — 13 Days, No Response](https://developer.apple.com/forums/thread/826427)
  - [Family Controls entitlement request submitted on March 9, 2026 — no response](https://developer.apple.com/forums/thread/818553)
  - [3+ weeks of waiting for Family Controls entitlement](https://developer.apple.com/forums/thread/725036)
  - [Causal Analysis of ASR Errors for Children（arXiv 2502.08587）](https://arxiv.org/pdf/2502.08587)
  - [one sec：Re-Intervention の説明](https://tutorials.one-sec.app/re-intervention)
  - [one sec の App Store のページ](https://apps.apple.com/app/id1532875441)（検索の要約で「uses Shortcuts Automation」と見ただけで、本文は開いていない）
  - [Chinese の縦書きの読み取りのスレッド](https://developer.apple.com/forums/thread/749234)
  - [iOS 18 beta の日本語の読み取りのスレッド](https://developer.apple.com/forums/thread/758846)
  - [SpeechAnalyzer の解説（issoh）](https://www.issoh.co.jp/tech/details/8929/)

## 変更したファイル
- リポジトリの中：なし。
- リポジトリの外（消してかまいません）
  - スクリプト：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/tools5/fetch_docs.sh
  - スクリプト：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/tools5/fetch_html.sh
  - スクリプト：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/tools5/strip.py
  - 文書の一覧：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/tools5/list1.txt、list2.txt、list3.txt
  - 取った文書と本文：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/angles5/dl と /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/angles5/txt
  - 文書の JSON を読む道具は、前回の /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/tools/docc.py をそのまま使いました。

## 実行したコマンドと結果
- `git rev-parse HEAD` → `64d14463c31dac576a8fe585d7391815b8f0f67d`
- fetch_docs.sh で、Apple の文書を70件取りました。
  - 404 は `avspeechutterance/init(ssmlrepresentation:)` と `familycontrols/configuring-family-controls` の2件です。前者は AVSpeechUtterance の一覧に `init(ssmlRepresentation:)` があることで代わりに確かめました。
  - `imageprocessingrequest/perform(on:orientation:)` は取れましたが、出力のファイル名を取り違えて、本文を読んでいません。
- fetch_html.sh の結果
  - ガイドライン：200
  - 機能の対応表：200
  - ショートカットの2ページ：200（1つは add-automations に転送された）
  - Apple Newsroom：200
  - Family Controls の申請のページ：サインインのページに転送され、本文なし
- ガードに2回止められました（書き先のパスに `$` があったため）。回り道をせず、書き先をそのまま書いたスクリプトのファイルに分けて、実行し直しました。
- `say -v '?' | grep ja_JP`（macOS の声の一覧。参考だけ）→ Kyoko、Eddy、Flo などの日本語の声がある。
- WebSearch 5回、WebFetch 2回（フォーラム 772972 と Cloud Vision の料金）。
- 最後の `git status --short` の出力：（出力なし）

## 未解決（未検証）
1. 縦書きとルビの、日本語の読み取りの精度。RecognizeDocumentsRequest（iOS 26）で縦書きが読めるかも含みます。Q2 の spike で確かめます。
2. SpeechTranscriber の `supportedLocales` に ja_JP が入るか。子どもの声での精度。SpeechAnalyzer だけのときに、実機で音声認識の許可が出ないか。
3. Family Controls の配布用の承認にかかる期間と、通るかどうか。Screen Time の API がシミュレーターで動くか。止める画面の拡張が App Group のデータを読めるか。26.5 より前に、拡張から通知を出せるか。
4. ショートカット型で、アプリからオートメーションを作る API がないこと（見つけていないだけ）。元のアプリに戻したときに、また動くかどうか。
5. iOS 26 の Accessibility Reader が実際に出たか。日本語の縦書きに対応しているか。
6. 日本語の読み上げで、`willSpeakRange` がどの細かさで届くか。IPA と SSML で読みを直せるか。拡張版の声をアプリから入れられないこと。
7. 写真を撮って自分で読むことと、教科書の文を端末の中で使うことが、権利の上で問題ないか（法務。未確認）。
8. App Group の UserDefaults の申告の理由（G1 で確かめる）。
9. 各角度の2週間の見積もりは、spike なしの［推測］です。

## 記録（指揮役が保存するときに書き足す）
- 種類：方向の見直しのための調べもの（tech-lead）。PASS / FAIL なし
- 対象：指揮役が出した4つの角度（①〜④）。BASE=64d14463c31dac576a8fe585d7391815b8f0f67d
- 日付：2026-10-16
- 同時に動いている調べもの：pdm（①②、③④、それ以外の分野）、designer（賞の傾向と独自性）
