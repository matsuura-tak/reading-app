（指揮役の注）G0 の狭い判定（tech-lead、実現性。裁定 19）。対象は docs/prd/001-reading-session.md（コミット 98e0200。AC 129件）のうち、Takuma の決定で足した部分。1体目は手数の上限で報告を出さずに止まったので、裁定 20 のとおり2体に分けて呼び直した（その1：G1-16 の3点、AC-114〜AC-126 の実現性、H32、G4-21 と G4-22／その2：AC-127〜AC-129、H10、H17、H23 の追記、12 の非機能の行、回す順と見積もりの注、G1-17〜G1-20、費用と審査）。2つの報告の文はそのまま保存した。合わせた結果は FAIL（その1 が FAIL、その2 が PASS）。

# その1：G1-16 の3点、AC-114〜AC-126 の実現性、H32、G4-21 と G4-22

FAIL

（tech-lead その1：G1-16 の3点、AC-114〜AC-126 の実現性、H32、G4-21 と G4-22）
- 対象：docs/prd/001-reading-session.md（コミット 98e0200、1410行）
- 前の tech-lead が取った文書と spike 1、2 を引き継ぎ、生の出力で確かめ直した。
- spike 3 を足した。アプリのプロセスを消してから、Live Activity の「終える」を押した。
- 作業のメモ：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g0-intents-tech-lead/part1-notes.md

## 結論
13件の判定は、作れる7件、条件つき5件、今の書き方では作れない1件（AC-123）。どの AC も、G3 は H32 のテスト用の口で動かす前提になる（要修正1）。

直さないと通さない点は2つ。
1. ロック中に Live Activity の「終える」を押す場面（11 の決まり、AC-116 (2)、G4-21 の「10分置いた回」）
   - WidgetKit の文書には、ロック中は認証してロックを外すまでボタンが働かない、とある。
   - iPhone には、押した瞬間の時刻を取る API がない。
   - 入口ごとに分けると、文書どうしは食い違っていない。
     - Control、Action ボタン、Siri：ロック中も動く。
     - Live Activity のボタン：ロック中は動かない。
2. 「出さない設定がオンのときだけ、ロック中に認証を求める」作り
   - authenticationPolicy は、設定に合わせて変えられない（spike 1）。
   - ほかにも確かな手段がない。
   - どの案を選ぶかで、AC-123、H32、G4-22 が変わる。

## 指摘

### 重大1：ロック中に「終える」を押したときの決まりと AC-116 (2)、G4-21 の「10分置いた回」が、Apple の文書と合わない

**場所**
- :293（11 の「終える」）：「押した時刻で読書を終えて記録を残し」「ロックを外さずに置いたときも記録は押した時刻で残り、次にアプリが前に来たときはしおりの画面を出す」
- :782（AC-116 の題）
- :784〜785（AC-116 (2)）
- :1165（G4-21 の「押してからロックを外さずに10分置いてから開く回」「10分置いた回も、記録は押した時刻までの分」）

**理由**
1. ロック中のボタンについて、WidgetKit の文書は "On a locked device, buttons and toggles are inactive and the system doesn't perform actions unless a person authenticates and unlocks their device." と書く。これはウィジェットにも Live Activity にも当てはまる。
   - ロック中に押して認証しなければ、インテントは動かない。読書は `reading` のままで、Live Activity も残る。
   - 認証すれば、ロックは外れる。
   - どちらにしても、「ロックを外さずに置いて、押した時刻で記録が残る」場面は起きない。
2. G3 では H32 がロックの状態を差し替えるので、AC-116 (2) は通ってしまう。食い違いが見つかるのは G4-21 になる。
3. iPhone には、押した瞬間の時刻を取る API がない。
   - preciseTimestamp は "when a person starts the app intent's action using the Action button on Apple Watch Ultra" だけ。
   - アプリが残せるのは、インテントが動いた時刻（perform の始まり）。
   - spike 3 では、押してから perform まで約9秒あいた。テストの activate() と重なったので、原因は決めきれない。
4. 文書どうしは食い違っていない。
   - authenticationPolicy の既定（"including when the device is locked"）と Controls の文書は、インテント自体の決まり。
   - WidgetKit の文は、その上に重なる「ウィジェットと Live Activity のボタン」の関門。
   - 入口ごとの整理は、証拠の G1-16 (1) の表にある。

**直し方の案**（実機でどちらの振る舞いになっても、合否が1つに決まる形）
- :293
  - 「押した時刻」を「インテントが動いた時刻（iPhone では押した瞬間の時刻を取れない）」にする。
  - 最後の文を次に置き換える。
    - 「前に出せないとき（canContinueInForeground が偽か、前に出す要求が notAllowed で断られたとき）は、前に出さずに記録を残し、次にアプリが前に来たときにしおりの画面を出す。」
    - 「ロック中に押してシステムが認証を求め、認証されなかったときは、インテントは動かず何も変わらない（`reading` のまま、Live Activity も残る）。」
- AC-116
  - 題：「押した時刻で」を「動いた時刻で」にする。
  - (2) の When：「1,800秒後に『終える』を、前に出せない状態（H32 で canContinueInForeground を偽にする）で動かし、さらに3,600秒後にアプリを前に出す」にする。Then はそのまま。
- G4-21 の「10分置いた回」を、次の2つに分ける。ロック中（鍵が閉じた状態）に「終える」を押す。
  - (a) 認証を求められたら、断って10分置き、ロックを外して開く。合格は、`reading` のままで Live Activity が残り、開くと読書中の画面が出て、記録が0件のとき。
  - (b) 求められずに動いたら、10分置いてから開く。合格は、記録が押した時刻±1分までの分で、開くとしおりの画面が出るとき。
  - どちらが起きたかを記録する。
- 実機の確かめ（証拠の D1）
  - G0 の承認の前には要らない。上の形にすれば、合否はどちらの振る舞いでも決まる。
  - designer が G1-15 で「終える」の形と文を決める前に行うと、案内の文を1つに絞れる。

### 重大2：「出さない設定がオンのときだけ、ロック中に認証を求める」作りに、確かな手段がない

**場所**
- :295（11 の認証）
- :824〜828（AC-123）
- :332（H32 の「認証の結果（通る、断る）を差し替えられる」「認証を求めたか」）
- :1166（G4-22）
- :1201（プライバシー）
- :1406（G1-16）

**理由**
- authenticationPolicy は static の定数でなければならない。設定から計算すると、ビルドが落ちる。
  - build1.log:1269 "error: The property 'authenticationPolicy' must be static, have a compile-time constant value, and cannot be computed or dynamic"
  - build1.log:1279 "** BUILD FAILED **"
- App Intents には、ロックの状態を知らせる値がない。SDK の IntentSystemContext にあるのは、preciseTimestamp、isVoiceOnly（iOS 27.0）、currentMode だけ。
- requestConfirmation は、認証ではない（"asks the person to confirm or cancel the operation"）。
- 前に出してロックを外させる案は、ロック中に前に出せるかが文書にない（未確認）。

**直し方の案**
- 証拠の G1-16 (3) の表から選ぶ。推すのは案1。
  - 案1：alwaysAllowed のままにし、perform の中で「設定オンかつロック中」なら答えない。
  - いちばん強い反論：ロックを外して聞き直す手間が1回増える。
  - それでも推す理由：設定をオンにする人は、見られないことを手間より重く見ると考える。
  - 案3（いつも認証）も確かに作れる。ただし :295 の pdm の決め（「オフなら、ロック中でも答える」）が変わる。
- 案1 にしたときの AC-123 の案文
  - When：(1) ロック中の状態で「どこまで読んだ？」を動かす (2) ロックを外した状態で動かす（どちらも H32 で差し替える）。
  - Then：どちらも認証を求めない。
    - (1) 声の全文は、文言キー `intent.whereStopped.unlockFirst`（仮）の文とちょうど同じ。ページの値、一行、書名を、声にも小窓にも出さない。インテントの結果は「アプリを前に出さない」。
    - (2) 声の全文は AC-121 と同じ文。
- 案1 にしたときに、ほかに直す所
  - :295 を次にする。「出さない設定がオンでロック中なら、ページを答えず、ロックを外してから聞くよう答える。ロックの状態は isProtectedDataAvailable で決める。パスコードのない端末では、いつもロックを外した扱いになる。」
  - H32：認証の差し替えと「認証を求めたか」を外す。案3 なら、「authenticationPolicy の値を返す」に替える。
  - G4-22：「出さない設定がオンでロック中は、ページを言わず、ロックを外すよう言う。外して聞き直すと答える」にする。
  - :1201：「認証のあとでだけ答える」を「ロック中は答えない」にする。
  - 文言キーは、designer が G1-15 で決める。

### 要修正1：H32 の「直接動かす」「プロセスがない状態から」「前に出したか」を、作れる形に書き直す

**場所**：:332、:290

**理由**
- XCTest には、インテントを直接動かす API がない。Xcode 27.0 の XCUIAutomation にあるのは、XCUISiriService の activate(voiceRecognitionText:) だけで、これは Siri に文を渡す道。
- そのため H32 は、テストの構成でだけ有効にした口から、インテントと同じ処理を動かす形になる。
- その口は、launch か open(URL) でアプリを起こすので、アプリは前面に出る。
  - 「プロセスがない状態から、前に出さずに動く」は、そのままでは再現できない。
  - 「前に出したか」は、インテントが前に出す要求をしたかで読むことになる。
- シミュレーターでは、本当のロックを作れない。パスコードがないので、isProtectedDataAvailable はいつも真（文書："set to true if the device is unlocked or if content protection is not enabled"）。
- 一覧の読み方
  - Control：返す API が文書にない。ビルドの産物にも入らない（spike 2）。
  - App Shortcuts：産物から読めるが、形式に文書がない。

**直し方の案**
- H32 を次の形に書き直す。形は G1-17 で contracts/ に書く。
  - 動かし方：テストの構成だけで有効な口から、インテントと同じ処理で動かす。
  - 差し替えるもの：端末のロックの状態、前に出せるか（canContinueInForeground と、前に出す要求の成否）、時計。
  - 返すもの：インテントが決めたこと（前に出す要求をしたか、声の文言キーと値、小窓の中身、エラーの文言キー）と、そのあとの前面の画面。
  - 「前に出さない」は、インテントが前に出す要求をしなかったことで読む。
  - App Shortcuts の一覧は、ビルドの産物（Metadata.appintents）から読む。
  - Control の一覧は、アプリが ControlWidget を組む表から読む。G2 では reviewer が、ControlWidget がその表だけから組まれていることを grep で見る。
- AC-116 (1)(3) は、システムを通る道でも確かめられる。
  - 通知センターの Live Activity の「終える」を、XCUITest で押す（spike 3。ロックなし）。
  - 押してから数秒あくので、H5 ではなく実時間で待つ。
  - この道を足すかは、verifier と G1 で決める。

### 要修正2：G4-21 と G4-22 に「本当にロックした状態」を作る手順がない

**場所**：:1165、:1166

**理由**
- Face ID の機種は、画面を見ると鍵が開く。「ロックを外さずに」のつもりの回が、認証済みの回になるおそれがある。
- ロック中の Siri は、設定で許していないと使えない。
- 声で答えるかは、応答の設定で変わる。
- ロック直後に鍵が消えるまでの時間は、開いた文書にない。
- このままでは、G1-16 の未確認が G4 で決まらない。

**直し方の案**
G4-21 と G4-22 の頭に、次の手順を足す。設定の名前は未確認なので、Takuma が実機で確かめる。
- パスコードを付けておく。
- 確かめる間だけ、Face ID の「iPhone のロック解除」をオフにする。
- ロックして1分以上待ち、鍵が閉じていることを見てから操作する。
- G4-22 は、「ロック中に Siri を許可」をオンにし、応答を「話す」側にする。
- 回ごとに、次の3つを記録する：認証を求められたか、前に出たか、出た画面。

### 要修正3：G4-21 の「Live Activity を切った回」が、ロック中に前に出せることを前提にしている

**場所**：:1165（「ロックを外すと読書中の画面が出る」）、:292

**理由**
- ロック中に Control か Siri で「読み始める」を動かしたとき、continueInForeground がどうなるかは文書にない（未確認）。ロック解除を求めるのか、notAllowed になるのかが分からない。
- notAllowed なら、ロックを外しても、アプリは自動では前に出ない。

**直し方の案**
- :292 に、「前に出せないときは `reading` のままにし、次にアプリが前に来たときに読書中の画面を出す」を足す。
- G4-21 の期待を、「ロックを外してアプリを前に出すと、読書中の画面が出る」にする。自動で前に出たかは、記録するだけで合否に使わない。

### 要修正4：:264 と G1-16（:1406）は、文書で決まった部分と、まだ決まらない部分が混ざっている

**場所**：:264、:1406、:1165 の末尾

**理由**
- 保護の等級は、文書でもう決まる。既定（completeUntilFirstUserAuthentication）なら、最初のロック解除のあとは、ロック中も読み書きできる。ロック画面のウィジェットの今の AC も、同じ前提に立っている。
- まだ決まらないのは、次の2つ。
  - ロック中に Live Activity のボタンが動くか（重大1）
  - ロック中に前に出せるか（要修正3）

**直し方の案**
- G1-16 を2つに分ける。
  - (a) 主の保存先と App Group の入れ物の等級を、既定にする ADR。Apple は利用者のデータに complete を勧めているので、悪い結果と見直す条件を書く。
  - (b) Live Activity のボタンと、ロック中の前面化は、G4-21 で見る。
- :264 のよりどころは、G4-21 で保存に失敗したときの手だてとしてだけ残す。

### 提案
1. AC-115 (4) は、予約中の取り消しの未検証（:109）に乗っている。G1 の前の予約の spike に、「インテントから取り消す」場合を入れる。
2. G4-21 の機内モードの回は、入口を Control にする。機内モードで Siri が動くかは、確かめていない。
3. 12 の「iOS 26.x のシミュレーターでも動かすテスト」（:1169）に、AC-114〜AC-126 を入れる。
   - 使う API は iOS 26.0 から。
   - いまの runtime は iOS 27.0 だけで、spike もすべて iOS 27.0 で動かした。
4. G4-21 の「3秒以内［推測の線］」は、9回すべての秒数を記録する。
   - H10 の500ミリ秒には、プロセスを起こす時間が入らない。
   - spike 3 では、数秒あいた。
5. G4 に、「再起動のあと、最初のロック解除の前に Control を押す」回を1回足す。AC-119 の道になるかを見る。合否に使うかは pdm が決める。
6. 「読み始める」と「終える」のインテントは、アプリと widget の拡張の両方のターゲットに入れる。
   - Controls の文書："The system requires the Target Membership of the app intent to be set to both the app and the widget extension to open the app."
   - WidgetKit の文書："Make sure to add your custom app intent to your app target."
   - spike 2 では、両方のメタデータに出た。
7. 軽い脅威モデルは、G1 の設計メモの 7 に書く。
   - 新しい境界は、ロックした端末を手にした人。
   - その人ができること：
     - 偽の記録を作る。記録は消せるので、害は小さい。
     - 設定がオフなら、ページを聞く（pdm の決め）。
     - Live Activity の書名を見る。AC-120 で伏せられる。
   - 外への送信はない。

## 証拠

実行したコマンドと結果（要点。詳しくは下の「実行したコマンドと出力」）
- 文書の原文
  - `python3 -I -` で、dl/docc と dl/hig の生の JSON から段落を抜き出した。下の「開いた Apple の文書と原文」の引用は、すべてこの出力にある。
- SDK と Xcode
  - `xcodebuild -version` → `Xcode 27.0 / Build version 27A266a`
  - XCUIAutomation の Headers を grep → インテントにかかわるのは XCUISiriService だけ（XCUISiriService.h:30 "Presents the Siri UI, if it is not currently active, and accepts a string"、apinotes:61 `activate(voiceRecognitionText:)`）。
  - AppIntents の arm64e-apple-ios.swiftinterface を grep → `public struct IntentSystemContext`（5037）の中身は preciseTimestamp（5038）、isVoiceOnly（5050）だけ。ほかに currentMode（3245）、canContinueInForeground（3292）がある。ロックの状態を返すものはない。
  - `xcrun simctl list runtimes` → `iOS 27.0 (27.0 - 24A434)` だけ。
- spike 1、2
  - build1.log:1269 の error、:1279 `** BUILD FAILED **`
  - build2.log:226 `** BUILD SUCCEEDED **`
  - extract.actionsdata を直接読んだ：authenticationPolicy は 0、1、2。supportedModes は 1、2、9。autoShortcuts は3件で、どれも `${applicationName}` 入り。
- spike 3
  - `xcodebuild test … -only-testing:IntentSpikeUITests/SpikeUITests/test03_endFromLiveActivityWithoutProcess` を2回動かし、どちらも exit 65。
  - 2回目は "SPIKE tapping id=liveActivity.end label=End" まで進んだ。落ちたのはそのあと、UI でログを読む部分。
  - events.log は、端末の data container から直接読んだ。
- 片づけ
  - `xcrun simctl delete 58323D6C-D06F-4398-A3F8-E4C84DE871D9` → exit 0
  - `xcrun simctl list devices | grep TL-Spike` → 0行（grep の exit=1）
- 見たファイルのパス
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g0-intents-tech-lead/spike/test3.log
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g0-intents-tech-lead/spike/results/t3.xcresult
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g0-intents-tech-lead/spike/build1.log
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g0-intents-tech-lead/spike/build2.log
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g0-intents-tech-lead/spike/dd/Build/Products/Debug-iphonesimulator/IntentSpike.app/Metadata.appintents/extract.actionsdata
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g0-intents-tech-lead/spike/IntentSpike/UITests/SpikeUITests.swift

### AC-114〜AC-126 の実現性
どの AC も、G3 は H32 のテスト用の口で動かす前提（要修正1）。

| AC | 判定 | 根拠と条件 |
|---|---|---|
| AC-114 | 条件つき | 根拠：LiveActivityIntent の文書（"launches your app process without opening the app"）、Activity の文書、spike 2（SessionStarting）、spike 3（アプリのプロセスで、mode=background で動いた）。条件：H32。G4 の「ロックを外さずに」は、文書上は作れるが、実機は未確認。製品では supportedModes を [.background, .foreground(.dynamic)] にする（AC-117、AC-118 のため。spike 2 の EndReadingIntent で、この形がビルドを通った） |
| AC-115 | 条件つき | (1)(2)(5) はアプリの決まり。(3) は、後ろからの更新ができる（"You can update or end a Live Activity while your app is in the background"）。(4) は、予約中の取り消しが未検証（:109。提案1） |
| AC-116 | 条件つき | (1)(3) は作れる（文書、spike 3）。(2) は重大1 |
| AC-117 | 作れる | dynamic と continueInForeground（文書、spike 3）。ロック中は未確認だが、G4 はない |
| AC-118 | 条件つき | G3 は作れる。G4-21 の期待が要修正3 |
| AC-119 | 作れる | perform からエラーを投げ、文言キーを返す。H7 で失敗させる。Control から押したときにエラーがどう見えるかは文書にないが、G4 はない |
| AC-120 | 作れる | 中身はアプリが決める。HIG の "Avoid displaying sensitive information" と合う |
| AC-121 | 作れる | alwaysAllowed（"including when the device is locked"）、background。既定の等級なら、ロック中も読める。声の全文は、返す dialog を H32 で記録する。実際の読み上げは G4-22 |
| AC-122 | 作れる | アプリの決まり |
| AC-123 | 作れない（今の書き方） | spike 1。重大2。案1 なら作れる |
| AC-124 | 作れる | foreground（spike 2 で supportedModes=2）。ロック中は、ロック解除が要ると見込む（未確認。G4-22 の期待と同じ） |
| AC-125 | 作れる | インテントは通信しない。機内モードの回は提案2 |
| AC-126 | 条件つき | App Shortcuts は、ビルドの産物から読めた（spike 2）。ただし形式に文書がなく、日本語は試していない。Control は、アプリの表を H32 で返す |

### G1-16 の3点

#### (1) ロック中（最初のロック解除のあと）に、アプリを前に出さずに保存できるか
入口ごとに、文書の記述と、確かめる回をまとめる。実機ではどれも未確認。

- ロック画面とコントロールセンターの Control
  - ロック中に動くか：動く。Controls の文書の "For added privacy, require device authentication before a control performs its action" と、HIG の "Require authentication for actions that affect security... see IntentAuthenticationPolicy" から、既定では認証なしで動くと読める。
  - 認証：既定では求めない（alwaysAllowed）。
  - 動くプロセス：アプリ（LiveActivityIntent。spike 3）。
  - 確かめる回：G4-21
- Action ボタン
  - ロック中に動くか：Control と同じ（"Perform your app's actions from Control Center, the Lock Screen, and the Action button"）。
  - 認証、プロセス：Control と同じ。
  - 確かめる回：G4-21
- ロック中の Siri
  - ロック中に動くか：動く（"including when the device is locked"）。
  - 認証：求めない。
  - 動くプロセス：アプリのターゲットにだけ置けば、アプリ（"By default, the system performs an intent ... using any available target"）。
  - 確かめる回：G4-21、G4-22（ロック中の Siri を許す設定が要る）
- Live Activity の「終える」
  - ロック中に動くか：動かない（"inactive ... unless a person authenticates and unlocks their device"）。
  - 認証：システムが求める。動くのは、ロックが外れたあと。
  - 動くプロセス：アプリ（"the system runs the app intent in the app's process"。spike 3）。
  - 確かめる回：G4-21（重大1の形）

保存の決め手は、保護の等級。
- 既定の等級なら書ける。
  - "Complete until first user authentication. (Default) ... After the first unlocking of the device, the file remains accessible until the device shuts down or reboots."
  - "your app can access the file and continue to access it even if the user subsequently locks the device."
- complete か completeUnlessOpen にすると、ロック中は読めず書けない（isProtectedDataAvailable の文書）。

結論
- 「読み始める」は、Control、Action ボタン、Siri から、ロック中でも保存できる（文書上）。
- 「終える」は、ロック中には動かない（文書上）。

#### (2) 押した時刻を残してから、前に出せるか
結論：作れる。

作り方
- supportedModes は [.background, .foreground(.dynamic)]（"Combine the background and dynamic foreground mode ... prefer the background"。iOS 26.0）。
- perform の中の順：
  1. 保存し、Live Activity を終える。
  2. canContinueInForeground が真なら、continueInForeground(nil, alwaysConfirm: false) を呼ぶ。
  3. 偽か notAllowed なら、前に出さずに返す（"If you call this method and it's not possible to transition the app to the foreground, the system throws an notAllowed error"）。
- openAppWhenRun と ForegroundContinuableIntent は、iOS 26.0 で非推奨なので使わない。
- deferred は "ensures the transition" なので、ロック中に止まるおそれがある。dynamic を推す。

spike 3（iOS 27.0、パスコードなし、ロックなし）の events.log
```
11:35:39Z pid=20897 proc=IntentSpike EndReadingIntent.perform begin mode=background canFG=true app=inactive protectedData=true
11:35:39Z ReadingCore.end source=liveActivityButton pressedAt=1792323339.2 activities=1
11:35:39Z ReadingCore.end done activities=0
11:35:39Z scenePhase=active
11:35:39Z EndReadingIntent continued in foreground mode=foreground app=active
```
読み取れること：保存を済ませてから、前面に出た。

未確認
- ロック中に前に出せるか。
- 押してから perform までの遅れ。押して6.7秒後もプロセスは notRunning で、perform は約9秒後だった。App.init（11:35:36）が activate() と重なったので、原因は決めきれない。

#### (3) 出さない設定がオンのときだけの認証
spike 1 で、authenticationPolicy を設定に合わせて変えることはできないと分かった。

| 案 | 作れるか | AC-123 の形 |
|---|---|---|
| 案1（推す）：alwaysAllowed のまま、perform で「設定オンかつ isProtectedDataAvailable が偽」なら断る | 作れる。spike 2 の WhereStoppedDynamicIntent でビルドが通った。ロックの合図は isProtectedDataAvailable だけ。パスコードがないと、いつも真。ロック直後の鍵の時間は未確認 | (1)(2) を1つにする：「認証を求めず、ロックを外すよう言う文だけを返す。ページは出さない」。H32 の認証の差し替えは要らない |
| 案2：needsToContinueInForegroundError か continueInForeground(alwaysConfirm: true) でロックを外させる | 未確認（ロック中の前面化が文書にない。できないと notAllowed） | (1) は前に出てから答える（「前に出さない」が崩れる）。(2) は notAllowed か取りやめ |
| 案3：いつも requiresAuthentication | 作れる。spike 2 で authenticationPolicy=1。文書："If both devices are locked, the system prompts the person to authenticate before running the app intent." | 設定がオフでも、ロック中は認証することになる。AC-121 と :295 が変わる。G3 で見られるのはメタデータの値だけ |
| 案4：インテントを2つにする | App Shortcuts はビルド時に静的に書き出される（spike 2）。設定で行き先を替えられない | App Shortcuts が4つになり、AC-126 が崩れる |
| requestConfirmation | 認証ではない | 満たさない |

### 未確認と、どちらでも合否が決まる直し方、実機の回

| 番号 | 未確認 | 直し方 | 実機の回 |
|---|---|---|---|
| U1 | ロック中の Live Activity のボタン | 重大1 | G4-21、D1 の 1〜4 |
| U2 | ロック中の continueInForeground | 要修正3 | G4-21、D1 の 6 |
| U3 | Control、Action ボタン、Siri で、ロック中に保存できるか（文書では「できる」） | AC は変えない | G4-21（要修正2の手順で）、D1 の 5 |
| U4 | ロック中の Siri の振る舞い、ロック直後の鍵 | 重大2 の案1 | G4-22 |
| U5 | App Shortcuts の産物の形式 | 読めなければ、G2 の reviewer がソースを grep する | G2、G3 |
| U6 | 押してから動くまでの遅れ | 「動いた時刻」と書く | G4-21 で秒数を記録 |
| U7 | 機内モードでの Siri | 入口を Control にする | G4-21 |

実機の手順 D1（約5分。G1-15 の前を推す）
準備
- iOS 26 以上の端末に、パスコードを付ける。
- Face ID の「iPhone のロック解除」をオフにする（名前は未確認）。
- tech-lead が、Takuma の Team で署名できる試しのビルドを用意する。

手順
1. アプリで読み始めて、Live Activity を出す。ロックして1分待つ。
2. ロック画面の「終える」を押す。記録すること：認証を求められたか、Live Activity が消えたか。
3. 認証を求められたら断り、10秒待つ。記録すること：Live Activity が残っているか。
4. もう一度押して、認証する。記録すること：前に出たか、出た画面、終わりの時刻。
5. ロック画面に「読み始める」の Control を置く。ロックして1分待ってから押す。記録すること：認証を求められたか、Live Activity が出たか。
6. Live Activity を設定で切ってから、5 をもう一度行う。記録すること：ロック解除を求められたか、外したあと前に出たか。

Takuma の端末の機種は、PRD から読み取れない（:1073 と :1169 の iPhone 17 はシミュレーター）。要修正2の手順を足せば、G4-21 と G4-22 は Takuma が行える。

### 審査と権限で気になる点
- データ保護
  - ロック中に保存するには、既定の等級が要る。
  - entitlement の com.apple.developer.default-data-protection を complete にすると、ロック中に読めず書けない。
  - Apple の推奨と違うので、ADR が要る（要修正4）。
- 許可のダイアログ
  - App Intents、App Shortcuts、Control、LiveActivityIntent について、開いた文書に、実行時に許可を求める手順はなかった。
  - Live Activity には NSSupportsLiveActivities が要る（spike で設定してビルドが通った。文書はこの回は開いていない）。
  - 利用者が Live Activity を切った場合は、AC-118 で受ける。
- バックグラウンドの実行
  - システムがアプリのプロセスを起こすので、UIBackgroundModes は要らない。
- 非推奨の API と新しい API
  - openAppWhenRun と ForegroundContinuableIntent は、iOS 26.0 で非推奨。警告0件の決まりに当たる。
  - allowedExecutionTargets、IntentExecutionTargets、isVoiceOnly は iOS 27.0 から。最低 iOS 26 では使わないか、#available で囲む。
- 周りに見える、聞こえる
  - HIG Siri："Be aware that Siri may also respond aloud, and others nearby might hear the response."
  - HIG Live Activities："could be viewed by casual observers; for example, on the Lock Screen"
  - どちらも AC-120、AC-121 と合う。
  - Control のラベルには、個人の情報がない。
- 外への送信
  - なし。新しい境界は、ロックした端末を手にした人（提案7）。

### 実行したコマンドと出力
1. 対象の確認
   - `git log --oneline -1 -- docs/prd/001-reading-session.md` → 98e0200
   - `wc -l` → 1410
2. 入力を読んだ
   - PRD の 268〜346、769〜848、1160〜1172、1400〜1410 を sed で読んだ。
   - 裁定 19、20 を読んだ。
3. 文書の原文
   - `python3 -I -` で、dl/docc と dl/hig の段落を抜き出した → 下の原文
4. SDK
   - `xcodebuild -version` → Xcode 27.0、27A266a
   - XCUIAutomation と XCTest を grep → XCUISiriService だけ（`NS_AVAILABLE_IOS(10_3)`、`activate(voiceRecognitionText:)`）
   - AppIntents の swiftinterface を grep → IntentSystemContext は preciseTimestamp と isVoiceOnly だけ。currentMode と canContinueInForeground はある。ロックの状態はない
5. runtime
   - `xcrun simctl list runtimes` → iOS 27.0 だけ
6. spike 1、2
   - build1.log:1269 の error、:1279 BUILD FAILED
   - build2.log:226 BUILD SUCCEEDED
   - extract.actionsdata：
     - ContinueReadingIntent 0/2
     - EndReadingIntent 0/9
     - StartReadingIntent 0/1
     - WhereStoppedDynamicIntent 0/9
     - WhereStoppedLiteralIntent 1/1
     - WhereStoppedLocalIntent 2/1
     - autoShortcuts 3件
7. 前のテスト test2.log
   - test01：launch のあと runningForeground、terminate のあと notRunning
   - test02：ショートカットのアプリの木を読めた（新機能のシート、「ショートカットなし」）。App Shortcuts は「すべてのショートカット」に出ないので、動かす道にしない
8. spike 3
   - コマンド：`xcodebuild test -project …/spike/IntentSpike/IntentSpike.xcodeproj -scheme IntentSpike -destination id=58323D6C-D06F-4398-A3F8-E4C84DE871D9 -parallel-testing-enabled NO -only-testing:IntentSpikeUITests/SpikeUITests/test03_endFromLiveActivityWithoutProcess -derivedDataPath …/spike/dd -resultBundlePath …/spike/results/t3.xcresult`
   - 1回目：exit 65。"End button not found"（待ちが短かった）
   - 2回目：exit 65。出力は "Activity.request ok … state=active"、"SPIKE state after terminate: notRunning"、"SPIKE tapping id=liveActivity.end label=End"、"SPIKE state after End tap: notRunning"。落ちたのは、そのあと UI でログを読む部分（テスト側）
   - events.log は、端末の data container から直接読んだ（上に引用）。端末と一緒に消えたが、part1-notes.md に写してある
9. 片づけ
   - `xcrun simctl delete 58323D6C-D06F-4398-A3F8-E4C84DE871D9` → exit 0
   - `xcrun simctl list devices | grep TL-Spike` → 0行（exit=1）
   - ほかの端末には触っていない

### 開いた Apple の文書と原文
前の tech-lead が https://developer.apple.com/tutorials/data/documentation/<path>.json（HIG も同じ形）から取った生の JSON を使い、段落を抜いて確かめた。取り直しはしていない。
- https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities
  - "On a locked device, buttons and toggles are inactive and the system doesn't perform actions unless a person authenticates and unlocks their device."
  - "If you adopt the LiveActivityIntent or AudioPlaybackIntent protocol, the system runs the app intent in the app's process. Make sure to add your custom app intent to your app target."
- https://developer.apple.com/documentation/appintents/liveactivityintent
  - "the system launches your app process without opening the app, performs the intent, and starts the Live Activity. For example, people might place a control in Control Center that performs a LiveActivityIntent"
- https://developer.apple.com/documentation/activitykit/activity
  - "You can update or end a Live Activity while your app is in the background, but you can only start a Live Activity while the app is in the foreground, unless you adopt App Intents and start the Live Activity using a LiveActivityIntent."
- https://developer.apple.com/documentation/appintents/appintent/authenticationpolicy
  - "The default value of this property is IntentAuthenticationPolicy.alwaysAllowed, which allows the intent to run without authentication, including when the device is locked."
- https://developer.apple.com/documentation/appintents/intentauthenticationpolicy/requiresauthentication
  - "If both devices are locked, the system prompts the person to authenticate before running the app intent."
- https://developer.apple.com/documentation/appintents/intentauthenticationpolicy/requireslocaldeviceauthentication
  - "you might use this option if your app intent accesses data on disk that's encrypted when the device is locked."
- https://developer.apple.com/documentation/widgetkit/creating-controls-to-perform-actions-across-the-system
  - "Perform your app's actions from Control Center, the Lock Screen, and the Action button."
  - "For added privacy, require device authentication before a control performs its action, as well as redact the text in a control when the device is locked."
  - "The system requires the Target Membership of the app intent to be set to both the app and the widget extension to open the app."
- https://developer.apple.com/design/human-interface-guidelines/controls
  - "Require authentication for actions that affect security. … For developer guidance, see IntentAuthenticationPolicy."
  - "Hide sensitive information when the device is locked."
- https://developer.apple.com/documentation/appintents/appintent/supportedmodes（iOS 26.0）
  - "Combine the background and dynamic foreground mode to run the app in either the foreground or background, but to prefer the background."
- https://developer.apple.com/documentation/appintents/intentmodes/foregroundmode/dynamic
  - "If you don't call one of these methods, the app continues running the app intent's code in the background."
- https://developer.apple.com/documentation/appintents/intentmodes/foregroundmode/deferred
  - "This option ensures the transition of the app to the foreground."
- https://developer.apple.com/documentation/appintents/appintent/continueinforeground(_:alwaysconfirm:)（iOS 26.0）
  - "If you call this method and it's not possible to transition the app to the foreground, the system throws an notAllowed error."
- https://developer.apple.com/documentation/appintents/intentmodes/current/cancontinueinforeground
  - "A Boolean value that indicates whether running the app intent in the foreground is possible."
- https://developer.apple.com/documentation/appintents/appintent/openappwhenrun（iOS 26.0 で非推奨）
  - "Please provide 'supportedModes' instead"
- https://developer.apple.com/documentation/appintents/foregroundcontinuableintent（iOS 26.0 で非推奨）
  - "Please include '.foreground(.dynamic)' in the 'supportedModes' of your app intent instead"
- https://developer.apple.com/documentation/appintents/appintent/requestconfirmation()
  - "The method displays a prompt that asks the person to confirm or cancel the operation."
- https://developer.apple.com/documentation/appintents/intentsystemcontext/precisetimestamp
  - "The system records this timestamp when a person starts the app intent's action using the Action button on Apple Watch Ultra."
- https://developer.apple.com/documentation/appintents/intentexecutiontargets（iOS 27.0）
  - "By default, the system performs an intent or entity query using any available target."
- https://developer.apple.com/documentation/uikit/encrypting-your-app-s-files
  - "Complete until first user authentication. (Default) … After the first unlocking of the device, the file remains accessible until the device shuts down or reboots."
  - "Assign the complete protection level to user data files"
- https://developer.apple.com/documentation/uikit/uiapplication/isprotecteddataavailable
  - "false if data protection is enabled and the device is currently locked … set to true if the device is unlocked or if content protection is not enabled."
  - "files that were assigned the complete or completeUnlessOpen protection key cannot be read or written by your app."
- https://developer.apple.com/documentation/foundation/fileprotectiontype/completeuntilfirstuserauthentication
  - "your app can access the file and continue to access it even if the user subsequently locks the device."
- https://developer.apple.com/design/human-interface-guidelines/siri
  - "Be aware that Siri may also respond aloud, and others nearby might hear the response."
- https://developer.apple.com/design/human-interface-guidelines/live-activities
  - "Avoid displaying sensitive information. Live Activities are prominently visible and could be viewed by casual observers"

### 読んだファイル
- docs/prd/001-reading-session.md
  - :109、:263〜265、:268〜346、:769〜848、:1165〜1166、:1169、:1201、:1400〜1410
- docs/reviews/001-reading-session-G0-ruling.md（裁定 19、20）
- docs/reviews/001-reading-session-apple-intelligence-tech-lead.md
  - :78、:197。authenticationPolicy は「未検証」としていた
- docs/reviews/001-reading-session-G0-prd2-tech-lead-r2.md
- scratchpad の g0-intents-tech-lead/ の中
  - notes.md
  - spike/ の App.swift、Shared.swift、Widgets.swift、SpikeUITests.swift
  - evidence-1、evidence-2
  - build1.log、build2.log、test1.log、test2.log
  - scripts/fetch.sh、scripts/fetch_hig.sh

書いたのは scratchpad の g0-intents-tech-lead/ の中だけ（part1-notes.md と spike/IntentSpike/UITests/SpikeUITests.swift）。リポジトリのファイルは変えていない。

# その2：AC-127〜AC-129、つなぎ口の追記、12 の非機能の行、見積もり、G1-17〜G1-20、費用と審査

PASS

（tech-lead その2。担当は AC-127〜AC-129、H10・H17・H23 の追記、12 に足した行、回す順と見積もりの注、G1-17〜G1-20、費用と審査です。対象は docs/prd/001-reading-session.md と docs/prd/product.md のコミット 98e0200 で、HEAD との間に docs/prd/ の差分はありません。G1-16 の3点、AC-114〜AC-126、H32、G4-21、G4-22 はその1が見ます。重大な指摘はありません。要修正は8件で、どれも直し方がはっきりしており、作れるかどうかには響きません。）

## 指摘

### 重大
- なし

### 要修正

**1. 見積もりの単位が前回の表と違う**
- 場所：冒頭の時間の枠（:6）、App Intents の位置（:11）、付記の G1-20（:1410）
- 理由：
  - 「S×3＝最大3日」は実装の日だけを数えています。
  - 前回の表（r2 の表1〜3）は、切り分けごとに G1（designer、tech-lead）、G2、G3 の日を足して「要る速さ」を出しています。
  - 同じ単位にそろえると、足す分は 3.95〜7.25日［推測］です。全部を入れるときの要る速さは +0.26〜+0.48倍 上がります。
  - したがって「最大3日」「最大で約0.2倍」は、上限として誤りです。
- 証拠：
  - r2 の表2では、(3) が実装0.5日＋関門0.5日、(5) が実装1.5〜2日＋関門1.25〜1.5日です。
  - この判定の est2.py の出力（証拠の 3）。
- 直し方：
  - 冒頭の注を「実装 2.0〜3.75日、関門を入れて 3.95〜7.25日［推測。tech-lead その2 の G0 intents の判定］」に替えます。
  - 回す順ごとの要る速さを、証拠の 3 の表で出し直します。
  - G1-20 は「芯の G1 のあと、測った速さで確かめ直す」に軽くしてよいです。

**2. H10 の区間の端があいまい**
- 場所：H10（:314）、12 の速さの行（:1180）、AC-114 の Then（:773）
- 理由：
  - AC-114 の Given は「プロセスがない状態」です。このとき「インテントを受けた時」がプロセスの起動と保存先の準備を含むかで、値が変わります。
  - LiveActivityIntent はアプリのプロセスで動きます（証拠の 8）。アプリの中で測れるのは perform() に入ってからです。
  - 「要求を出した時」も、request を呼ぶ前か返った後かが決まっていません。
- 直し方：
  - H10 を「perform() に入った時 → Activity.request が返った時」と書きます。
  - プロセスの起動は区間に含めません。起動を含む体感は G4-21 の3秒で見ます。
  - 区間に「読み始めの保存」と「予約の取り消し」を含むと書きます。AC-119 では保存に失敗すると要求が0件なので、保存が先になります。
  - 区間の長さは、signpost と同じ所でアプリが ContinuousClock でも測り、H10 の口から返してよいです。テストのプロセスから signpost を拾えるかは H32 の形しだいです［推測］。
  - ビルドの構成は、AC-100〜102 と同じ Release にそろえます。

**3. H23 の「押せる要素の数と、動かすインテントの名前」は、要求からは読めない**
- 場所：H23（:323）、AC-114（:773）、AC-120
- 理由：
  - ActivityKit の request に入るのは、attributes、content（ContentState）、pushType などだけです（証拠の 8 の request の形）。
  - ボタンは、ウィジェットの拡張の ActivityConfiguration の画面にあります。要求を記録しても、ボタンの数とインテントは出てきません。
  - 描いた SwiftUI のボタンから、動かすインテントを公開の API で読めるかは未確認です。
- 直し方：H23 に次の3点を書きます。AC の Then は変えずに済みます。
  - 押せる要素は、ContentState に持たせた操作の一覧（例 [.end]）から描き、H23 はその一覧を記録する。
  - 描いた画面の押せる要素の数と識別子は、H22 と同じ描き方で数える。
  - 識別子とインテントの対応は、単体テストで見る。

**4. すぐ始める要求が失敗したときの動きがない**
- 場所：「読み始める」の場合分け（:292）、H23（:323）
- 理由：
  - 場合分けにあるのは、areActivitiesEnabled が偽のときだけです。
  - 真でも request は失敗しえます。原文に「An error that indicates why the request to start a Live Activity failed. enum ActivityAuthorizationError」とあります。
  - 今の書き方では、保存は済んで `reading` になったまま、Live Activity も前面の画面もありません。外に「終える」のない読書が、1440分まで数え続けられます。
- 直し方：場合分けに1行足し、AC も1つ足します（verifier と）。案は2つです。
  - 案A：AC-118 と同じく、`reading` のままアプリを前に出し、読書中の画面を出す。
  - 案B：`idle` に戻し、`session.start.error` を返す。
  - どちらでも、H23 の「要求の失敗」はすぐ始める要求にも効く、と書きます。

**5. G1-19 は G0 で決める**
- 場所：10（:263）、付記（:1409）、予約を見直す時（:286）
- 理由：
  - 予約は AlertConfiguration つきの request（request(…alertConfiguration:start:)、証拠の 8）で作られ、始まるときに知らせが出ます（:248）。
  - 20:30 にアプリの中で読み始めると、21:00 に「待つ」の中身（一行、ページ）の Live Activity が、知らせと一緒に読書中に出ます。音が鳴るかは未確認です。
  - 見直す時の列（:286）に「読み始めたとき」がありません。
  - 直し方によっては、11 の決まりと AC-41、AC-115 の要求の数が変わります。G1 に回すと、承認した PRD を直すことになります。
- 直し方：既存の Given と Then を変えない、足すだけの形です。
  - :286 に足す1行：「`idle` から `reading` になったとき（アプリの中でもインテントでも）、まだ始まっていない今夜の予約があれば取り消す。新しい予約は、記録が残ったときの見直しで入れる。」
  - 足す AC の例：入口 21:00、時計 20:30、今夜の予約が1件。`bookmark.start` で読み始めると、取り消しが1件、すぐ始める要求は0件。20:45 に終えて保存すると、新しい予約は翌日 21:00。
  - 確かめた結果：AC-36（(1)、(2)）、AC-38、AC-41、AC-97、AC-98、AC-115 (4) の期待値は、どれも変わりません。
  - 取り消しの作りは G1-4 の spike と同じもので、条件は今のまま（(5) を残すときだけ要る）です。
  - アプリの中で始めたときもすぐ始める Live Activity を出す案にすると AC-41 などが変わるので、選ぶなら G0 で決めます。

**6. iOS 26 のシミュレーターで動かす G3 のテストに、アプリの外のインテントが入っていない**
- 場所：12 の速さの前書き（:1169）
- 理由：
  - 最低の対応は iOS 26 です。
  - インテントの動きは、iOS 26 で入った supportedModes に寄ります。openAppWhenRun は iOS 26.0 で非推奨です。
  - 前の tech-lead の spike は、iOS 27.0 の runtime でしか動かしていません（notes.md）。
- 直し方：:1169 の列に「アプリの外からのインテント（AC-114〜AC-126）」を足します。

**7. G1-18 の BookEntity は、「一行と書名を出さない」設定を抜ける道を作りうる**
- 場所：G1-18（:1408）、12 のセキュリティ（:1201）
- 理由：
  - EnumerableEntityQuery を付けると、原文のとおり「you enable the Shortcuts app to generate a Find action and do filtering automatically」です。EntityPropertyQuery も、生成された Find の操作を持ちます。
  - BookEntity の DisplayRepresentation は書名と著者です。ショートカットから本の一覧が取れ、AC-34 と AC-123 の「出さない」の外に出ます。ロック中に Find の操作が動くかは未確認です。
  - App Shortcuts の引数に使うと、原文のとおり「Apple may extract anonymized App Shortcuts data such as … display representation values」です。
  - 12 の「システムに渡すもの」（:1201）に BookEntity がありません。
  - v1.0 の AC に、BookEntity を使うものはありません。
- 直し方：G1-18 を次の形に直します。
  - v1.0 では、形を ADR に書くだけにする。
  - 作るなら、Find の操作を生む query（EnumerableEntityQuery、EntityPropertyQuery）を付けず、App Shortcuts の引数にも使わない。
  - 付けるなら、12 の渡すものに足し、「出さない」設定のときの扱いを決める。

**8. 審査メモにアプリの外の入口がない**
- 場所：17 の審査メモ（:1300〜1302）
- 理由：
  - 2.3.1(a) に「All new features, functionality, and product changes must be described with specificity in the Notes for Review section」とあります。
  - Control、Action ボタン、Siri、ショートカットは、審査する人が見つけにくい機能です。
- 直し方：
  - App Intents を入れる版では、確かめる手順に1文足します。例：「コントロールセンターに『読み始める』を加えて押すと、アプリを開かずに読書が始まり、ロック画面に書名、経過時間、『終える』だけの Live Activity が出ます。Siri に『よむまの本、どこまで読んだ？』と聞くと、ページを答えます。」言い方は G1-15 で決まってから入れます。
  - 回したときは外します。
  - ふりかえりの1行も、読み終えた夜の1文に足すとよいです。

### 提案
1. **Live Activity の「終える」の読み上げ（:1212）**：読み上げのラベルの文言キーと、大きい文字のときの並びを決めます（designer、G1）。H23 の記録にもラベルを足します。
2. **すぐ始める Live Activity の staleDate と8時間（:291、:1310）**：HIG には「don't exceed eight hours」とある一方、読書の上限は1440分です。すぐ始める方の staleDate（例：AC-98 と同じ 4:00）と、Live Activity が先に消えたときの扱い（読書は続き、次に前に出すと読書中の画面）を決めます。システムが8時間で自動で終えるかは、この判定では原文で確かめていません（未確認）。
3. **2.5.1 への合わせ方**：openAppWhenRun は使わず supportedModes にします（原文「This property is deprecated.」、iOS 26.0）。掲載文には Siri とショートカットへの対応を事実のとおり書いてよく（2.5.1「indicate that integration in their app description」）、Apple Intelligence とは書きません。
4. **ふりかえりの日付（:299）**：年をまたいで読んだ本だと「10月15日」がどの年か分かりません。今年でない晩は年を出すかを design/ で決めます。AC は変わりません。
5. **product.md の I-2 の注（product.md:92）**：`intent_start` だけが書かれています。PRD :298 では `intent_open` も I-2 に数えないので、そろえます。
6. **(5) を回すときの「読み始める」**：アプリを前に出す形（AC-118 の道）だけを残す案があります。ボタン1回の道と声の道（12 のアクセシビリティ）を小さな手間で残せます（実装約0.5日、関門約0.5日［推測］）。決めるのは pdm と Takuma です。
7. **G1-15 での Siri のアプリ名の別名**：Info.plist の別名（INAlternativeAppNames）が App Shortcuts に効くか、確かめておきます（未確認）。
8. **ふりかえりの1行を (3) と組にする理由**：技術の依存ではありません。晩の数え方は芯の AC-22 にあるので、(3) を回しても、ふりかえりは 0.6〜1.0日で残せます［推測］。

## 証拠
読んだファイル：
- docs/prd/001-reading-session.md の :1〜22、:148〜346、:580〜640、:769〜848、:947〜1032、:1071〜1090、:1168〜1215、:1256〜1410
- docs/prd/product.md の差分と I-2（:92）
- docs/reviews/001-reading-session-G0-ruling.md の裁定 10、11、16〜20
- docs/approvals/001-reading-session-G0-Q8.md の :305 から最後まで
- docs/reviews/001-reading-session-apple-intelligence-tech-lead.md の判定の表と 2
- docs/reviews/001-reading-session-G0-prd2-tech-lead-r2.md の見積もりの表1〜3
- 前の tech-lead の notes.md、dl/ の Apple の文書、spike/evidence-2-metadata-app.txt、spike/build2.log（読むだけ）

主なコマンドと結果は 7 に、開いた URL と原文は 8 にあります。

### 1. AC-127〜AC-129 の実現性

| 項目 | 判定 | 根拠 |
|---|---|---|
| AC-127 | 今の構成で作れる。新しい API も依存も要らない | 要るのは、記録ごとの読み始めの日時、タイムゾーン、分数だけ（:272、:273、H2 :311）。reflection.py の結果は 6晩、142分、10/15、38分で、AC の値と同じ |
| AC-128 | 作れる | (1) single、1晩、30分、日付なし。(2) 3晩、70分。同じ30分の 10/13 と 10/15 から、新しい 10/15 を選ぶ |
| AC-129 | 作れる | 記録が0件なら出さない（計算の結果は None） |
| ふりかえりの決まり（:299） | 作れる | 晩ごとの合計、4:00 の境目、同じ分なら新しい晩、何晩の数え方は AC-85 と同じ（AC-85 も 2晩、65分で合う）。夏時間のある地域（America/New_York、2026-03-08）でも、境目は記録の地方時で決まる |
| 晩ごとのページを残さない（:230） | 成り立つ | ページを使わず、分だけで組む。前の調べものの例「38ページ」は v1.0 のデータからは出せないので、pdm が分に替えたのは正しい |
| 手間 | 実装 0.25〜0.5日、関門 0.35〜0.5日［推測］ | 文の型（日英、複数形）と、芯にある晩のまとめ方の使い回し |

### 2. つなぎ口と 12 の行

**つなぎ口**
- H10（:314）：作れます。区間の端は要修正2で決めます。
- H17（:317）：作れます。
  - `intent_start` は、「読み始める」の perform で記録に付けます。
  - 「続きを読む」はアプリを前に出す形なので、perform はアプリのプロセスで動きます（原文「if the app intent's openAppWhenRun property is true, or if the intent conforms to … the system performs the app intent in the app's process」）。開いた時刻を持てるので、`intent_open` には AC-40 と同じ300秒の決まりを使えます。
  - v1.0 は最初の版なので、この2つの値は入口の印に最初から入れておけば済み、データの移し替えは要りません。
- H23（:323）：一部は作れます。残りは要修正3と4です。

**12 の行**
- 速さ（:1180）：無理はありません［推測］。
  - 区間の中の仕事は4つです。今の本を読む、読み始めを保存する、まだ始まっていない予約を取り消す、request を出す。どれも端末の中で済みます。
  - プロセスの起動は区間の外です。push は使いません（:1198）。
- セキュリティ（:1201）：成り立ちます。
  - 足すのは G1-18（要修正7）だけです。
  - Apple は App Shortcuts の言い方とインテントの名前を匿名で取り出しえますが、v1.0 の言い方に利用者のデータの引数はありません。出るのはアプリの決まった文だけです。
- アクセシビリティ（:1212）：成り立ちます。測り方は AC-114（ボタン1回）、AC-121（声）、AC-126（ラベル）です。「終える」のラベルは提案1です。
- 前書き（:1169）：要修正6です。

**新しい入口の軽い脅威モデル**

| 脅威 | 中身 | 扱い |
|---|---|---|
| なりすまし | ロック中の端末を手にした人が、Control や Siri で「読み始める」「終える」を動かす | 認証の既定はその1が見る。害は、記録が1件増えることと、Live Activity に書名が出ること（出さない設定なら隠れる）。記録は消せる |
| 改ざん | ショートカットの自動化で、始めると終えるを繰り返す | 読書は1つだけ（AC-115）。1分未満は残らない |
| 漏れ | 「どこまで読んだ？」のページ、BookEntity の Find | ページは、pdm の決定でロック中も答える（:295）。BookEntity は要修正7 |
| 否認、DoS、権限の昇格 | サーバーもアカウントもないので、新しい境界はない | ー |

### 3. 見積もりの確かめ（単位は r2 と同じ「1人の作り手の日」。どれも［推測］）

**足す分の内訳**

| 足すもの | 実装 | G1 designer | G1 tech-lead | G2 | G3 | 計 |
|---|---|---|---|---|---|---|
| A 「読み始める」（(5) と組。H32 の土台を含む） | 1.25〜2.25 | 0.25〜0.5 | 0.25〜0.5 | 0.5〜0.75 | 0.1〜0.25 | 2.35〜4.25 |
| B ショートカット | 0.5〜1.0 | 0.1〜0.25 | 0.1〜0.25 | 0.25〜0.4 | 0.05〜0.1 | 1.0〜2.0 |
| C ふりかえり（(3) と組） | 0.25〜0.5 | 0.1〜0.15 | ー | 0.25〜0.35 | ー | 0.6〜1.0 |
| 計 | 2.0〜3.75 | | | | | 3.95〜7.25 |

**回す順ごとの合計と要る速さ（15日で割ったもの）**

| どこまで回すか | 合計の日 | 要る速さ | r2 の値 |
|---|---|---|---|
| 回さない | 36.95〜51.75 | 2.5〜3.5倍 | 2.2〜3.0倍 |
| (課金) まで | 32.95〜46.05 | 2.2〜3.1倍 | 1.9〜2.6倍 |
| (ショートカット) まで | 31.95〜44.05 | 2.1〜2.9倍 | ー |
| (3) まで | 30.35〜42.05 | 2.0〜2.8倍 | 1.9〜2.5倍 |
| (4) まで | 27.55〜38.55 | 1.8〜2.6倍 | 1.7〜2.3倍 |
| (5) まで | 22.5〜30.8 | 1.5〜2.0倍 | 変わらない |
| (6) まで | 19.9〜27.3 | 1.3〜1.8倍 | 変わらない |

**結論**
- **前回の表と合うか**：単位が合いません（要修正1）。S の値そのものは、出どころの判定の表（2a「S〜M（Live Activity があれば S）」、2b「S」、3「AI なしの文の型なら S」）と合っています。
- **「読み始める」を (5) と組にした理由**：技術として正しいです。
  - 同じ Activity<Attributes> の型に、すぐ始める request(attributes:content:pushType:) と、予約の request(…alertConfiguration:start:) の両方があります（原文）。
  - 分け合うものは、属性と中身の型、ウィジェットの拡張の ActivityConfiguration（ロック画面と Dynamic Island）、`reading` への更新（AC-41）、1つに保つ決まり（AC-115 (3)(4)）、終わりの要求です。
  - (5) なしで作ると、これをすべて「読み始める」が持つので M になります。
  - 新しい target は要りません。Control も Live Activity も、芯のウィジェットの拡張に入ります。
- **ショートカットを (課金) のすぐ後に置いたこと**：技術の無理はありません。
  - (課金)、(3)〜(6) のどれも、ショートカットに依りません。
  - ショートカットだけを回して (5) を残すと、App Shortcuts は「読み始める」の1つになります（:343 に書いてある）。AppShortcutsProvider と H32 の土台は残るので、回して減るのは B の 1.0〜2.0日だけです。

### 4. G1-17〜G1-20 の振り分け
- G1-17：一部は G0 で決めます。H10 の区間の端（要修正2）と H23 の押せる要素の読み方（要修正3）は、AC-114、AC-120 の Then の意味を決めるからです。契約の形そのものは G1 で書きます。
- G1-18：G1 でよいです（AC は変わらない）。ただし、公開する範囲は今書きます（要修正7）。
- G1-19：G0 で決めます（要修正5）。
- G1-20：G1 でよいですが、冒頭の数字は今直します（要修正1）。

### 5. 審査と権限で気になる点
- **App Shortcuts の言い方とアプリの名前**：
  - HIG に「You have to include your app name, but you can be creative with it.」とあります。
  - spike の産物（spike/evidence-2-metadata-app.txt）では、phraseTemplates に ${applicationName} が入っています。
  - 「よむまで〜」を避ける決まり（:297）は妥当です。日本語の Siri の聞き取りは未確認で、G4-22 で見ます。
- **Siri**：
  - HIG の「Omit your app name from responses.」は、:294 と AC-121 に合っています。
  - spike/IntentSpike には .entitlements も com.apple.developer.siri もありませんが、build2.log は成功し、autoShortcuts が出ました。App Shortcuts の登録に Siri の entitlement は要らない見込みです［推測。spike の出力］。
  - Siri から実際に動くかは未確認です（G4-22）。
- **4.10**：原文は「You may not monetize built-in capabilities … or Apple services and technologies」です。足した部分はどれも無料の側（:1273）なので当たりません。v1.0 に Apple Intelligence を使う部分はありません。
- **「Apple Intelligence 対応」と書かない（:1311）**：2.3.1(a) の「marketing your app in a misleading way, such as by promoting content or services that it does not actually offer」に合っています。妥当です。
- **2.5 の系列**：
  - 2.5.1「Apps may only use public APIs」：使うのはどれも公開の API です。同じ条の「phase out any deprecated features」は提案3。
  - 2.5.4「may only use background services for their intended purposes」：LiveActivityIntent はアプリを開かずにプロセスを起こすので、UIBackgroundModes は要りません。12 の電池の行と合っています。
  - 2.5.16「Widgets, extensions, and notifications should be related to the content and functionality of your app」：Control と Live Activity は読書の操作なので、これを満たします。
- **プライバシーの表示（15）**：
  - 入口の印は端末の中だけで、送りません（:298）。表示は「データの収集なし」のままでよい見込みです［推測］。
  - AppShortcutsProvider には「Apple may extract anonymized App Shortcuts data such as localized phrases, display representation values, and the title and description of related intents. Machine learning models use this data when training…」とあります。Apple が集めるものなので、開発者の表示の外です。BookEntity を引数にした場合は要修正7。
- **権限**：新しい許可のダイアログはありません。Live Activity は利用者が設定で切れ、areActivitiesEnabled で見ます。

### 6. 利用者1,000人あたりの月の費用
- 0ドルのままで、変わりません。
- 足した部分は端末の中で動きます（LiveActivityIntent の原文）。Live Activity は push を使わないので（:1198）、APNs に送るサーバーも要りません。外部の API も、依存のライブラリも足しません。
- 固定費は、16（:1294）にある Apple Developer Program の年会費だけです。料金のページは、この判定では開き直していません。

### 7. 実行したコマンドと出力
- `git diff --stat 0fe6aee 98e0200 -- docs/prd/001-reading-session.md docs/prd/product.md` → 2 files, 183 insertions, 30 deletions
- `git diff --stat 98e0200 HEAD -- docs/prd/` → 空
- `python3 -I scratchpad/part2-scripts/reflection.py` → AC-127 {multi, 6, 142, 10-15, 38}、AC-128(1) {single, 1, 30}、(2) {multi, 3, 70, 10-15, 30}、AC-85 {2, 65}、AC-129 None、DST {2晩, 03-07, 40}
- `python3 -I scratchpad/part2-scripts/est2.py` → 証拠の 3 の表の値
- `curl` で enumerableentityquery.json（200、14100 B）、entitypropertyquery.json（200、27732 B）、guidelines（200、240818 B）を scratchpad/dl-part2/ に取得
- `find spike/IntentSpike -name '*.entitlements'`、`grep -rl com.apple.developer.siri` → どちらも0件
- 前の tech-lead が取った文書の引用は、すべて dl/ の生の JSON から scratchpad/part2-scripts/ctx.py で取り出して確かめました。

### 8. 開いた文書と原文
- https://developer.apple.com/documentation/appintents/liveactivityintent ：「In general, your app needs to be in the foreground to start a Live Activity. However, you can use a LiveActivityIntent … the system launches your app process without opening the app, performs the intent, and starts the Live Activity.」
- https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities ：「If you adopt the LiveActivityIntent or AudioPlaybackIntent protocol, the system runs the app intent in the app's process.」
- https://developer.apple.com/documentation/activitykit/activity ：「Requests and schedules a Live Activity for a specific date. static func request(attributes:content:pushType:style:alertConfiguration:start:) throws」、「An error that indicates why the request to start a Live Activity failed. enum ActivityAuthorizationError」
- https://developer.apple.com/documentation/appintents/appshortcutsprovider ：上に引いた「Apple may extract anonymized…」
- https://developer.apple.com/documentation/appintents/appintent/openappwhenrun ：「This property is deprecated.」、iOS 16.0 から、26.0 で非推奨
- https://developer.apple.com/documentation/appintents/enumerableentityquery （新しく取得）：「By implementing an EnumerableEntityQuery, you enable the Shortcuts app to generate a Find action and do filtering automatically.」
- https://developer.apple.com/documentation/appintents/entitypropertyquery （新しく取得）：「Defines how the generated 'Find' Shortcuts action of this query type is displayed to the user.」
- HIG live-activities：「Live Activities work best for tracking short to medium duration activities that don't exceed eight hours.」
- HIG app-shortcuts、HIG siri：5 に引いたもの
- https://developer.apple.com/app-store/review/guidelines/ （新しく取得）：2.3.1(a)、2.5.1、2.5.4、2.5.16、4.10 の引用は 5 と要修正8 のとおり

### 9. 作業のメモと産物
- メモ：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g0-intents-tech-lead/part2-notes.md
- スクリプト：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/part2-scripts/ （ctx.py、reflection.py、est2.py）
- 新しく取った文書：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/dl-part2/
- リポジトリのファイルは書いていません。spike のビルドとシミュレーターの操作もしていません。

## 記録（指揮役が保存するときに書き足す）
- 種類：G0 の狭い判定（tech-lead、実現性。裁定 19、20）。結果：FAIL（その1：重大2件、要修正4件、提案7件／その2：重大0件、要修正8件、提案8件）
- 対象：docs/prd/001-reading-session.md と docs/prd/product.md。BASE=98e02009cc3510d3ca7db1dde99258756c39a206（足した差分は 0fe6aee..98e0200）
- 日付：2026-10-18
- 指揮役が確かめたこと：その1 の根拠（SDK の IntentSystemContext に、ロックの状態を返すものがない。preciseTimestamp の原文は Apple Watch Ultra の Action ボタンだけ。spike 1 のビルドの失敗）と、その2 の見積もりの足し算（r2 の表3 に 3.95〜7.25日を足すと、回さないときは 36.95〜51.75日、2.5〜3.5倍）
- 作業の材料（リポジトリの外。scratchpad）：g0-intents-tech-lead/（notes.md、part1-notes.md、part2-notes.md、spike）、part2-scripts/、dl-part2/。spike の端末は、その1 が消した
