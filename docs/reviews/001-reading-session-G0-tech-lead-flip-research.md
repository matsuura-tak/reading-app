（指揮役の注）これは判定ではなく、判定の前の調べもの（tech-lead）の報告。案 A「伏せて読み始める」の実現性を調べたもので、PRD の作り直し その2（第2部）と G1 の入力にする。報告の文はそのまま保存した。

# 001-reading-session 案 A「伏せて読み始める」の実現性（tech-lead の調べもの。BASE=92409d6）

判定の前の調べものなので、PASS や FAIL は付けていません。リポジトリの中のファイルは何も書いていません。

## 結論
- **作れます。** 向きの取り方は UIDevice の向き（faceDown）を推します。Apple の文書には、許可のダイアログも Info.plist の説明文も出てきません。通信なし、バックグラウンドの実行なしのまま作れます。r1 の時刻の方針 1-b は変えません。
- **G3 のシミュレーターで決められるのは、アプリの中の動きです。** 向きの知らせを受けてから `reading` になるまでの流れ、待つ秒数、どの画面で始めてよいか、合図を出した回数、許可のダイアログが0回であること、がこれに当たります。
  - spike で、テストから XCUIDevice の orientation に faceDown を入れると、アプリの `UIDevice.current.orientation` が faceDown（値 6）になり、知らせが1回届くことを確かめました。シミュレーターは iPhone 17 と、iPhone 用のアプリを iPad の互換表示で動かした iPad mini（どちらも iOS 27.0）です。
- **シミュレーターで決められないものは、G4 で Takuma が実機で確かめます。** センサーが実際にどう判定するか（置き方、ケース、柔らかい面、寝転んで持ち上げたとき、画面の向きのロック）、触覚の感じ方、自動ロックで画面が消えるか、です。
- **新しく見つかった重大な点が2つあります。**
  1. designer の下書き（candidate-A-flip.md の 3-2 と 3-4）は、触覚に `SensoryFeedback.start` と `.stop` を使っています。Apple の文書にはどちらも「Only plays feedback on watchOS.」とあり、**iPhone では鳴りません**。iOS で鳴る種類（`.success` や `.impact` など）に替える必要があります。
  2. **画面の向きのロック（縦の固定）がオンのときに faceDown が UIDevice に届くかは、未検証です。** Apple の文書に記載がなく、シミュレーターにはロックがありません。届かなければ、ロックを使う人には伏せる道が効きません。Core Motion なら届く見込みですが、HIG に「許可の要求が出る」と読める文があり、AC-24 との関係が文書だけでは決まりません。そこで、G0 r2 の前に Takuma の実機で10分ほど確かめることを勧めます（質問 Q-A）。

---

## 1. 伏せた向きの取り方

| 選択肢 | 許可のダイアログと Info.plist | 取れるのはいつか | 電池 | 誤検知 | シミュレーターで試せるか | 判定 |
|---|---|---|---|---|---|---|
| (a) UIDevice の向き（`beginGeneratingDeviceOrientationNotifications()`、`orientationDidChangeNotification`、`.faceDown`） | 文書に許可も説明文も出てこない。NSMotionUsageDescription の対象の一覧にも入っていない。spike では許可のダイアログ0件（シミュレーターのみ。実機は G4） | 知らせが届くのはアプリが動いている間だけ。バックグラウンドの実行を使わないので、ロック中やほかのアプリを使っている間は届かない（仕組みからの判断） | begin で加速度計が動き始める。end で「power down the accelerometer hardware if it isn't in use elsewhere」（ほかで使っていなければ電源を落とす）と文書にある。一覧が前面で `idle` の間だけ begin すれば小さい（数字は未測定） | 「水平で画面が下」をシステムが決める。静止しているかは見ないので、仰向けで iPhone を顔の上に持ち上げても faceDown になる。どれだけ傾けると faceDown になるか、どのくらい揺れを吸収するかは文書になく、未検証 | **試せる**（spike で確認。つなぎ口は要らない） | **推す** |
| (b) Core Motion の CMMotionManager（加速度の z か、deviceMotion の重力と回転の速さ） | 決まらない。NSMotionUsageDescription の文書が対象として挙げるのは CMSensorRecorder、CMPedometer、CMMotionActivityManager、CMMovementDisorderManager で、CMMotionManager はない（ただし「including」なので全部を挙げた一覧ではない）。一方、HIG の Gyroscope and accelerometer には「the system includes your copy in a permission request」とある。実機で未検証 | 同上（前面だけ） | 更新の間隔しだい。deviceMotion はジャイロも使うので重い。HIG にも「may affect battery usage」とある | 自分でしきい値（例：z > 0.9）と「静止が N 秒」を決められるので、手で持ち上げた場合と区別しやすい。ただし実機で調整が要る | **試せない**。spike ではシミュレーターで `isAccelerometerAvailable=false`、`isDeviceMotionAvailable=false`。値を外から入れるつなぎ口が要り、G3 で確かめられるのは「入れた値への反応」だけ | v1 では使わない。(a) が向きのロックで届かないと分かったときの代わり |
| (c) 近接センサー（`proximityState`）を引き金にする | 許可は要らない | 前面だけ | 小さい | 有効にすると、近づいたものがあるだけで画面が消える。Apple は「Enable proximity monitoring only when your application needs to be notified」（知らせが要るときだけ有効にする）と書いている | 試せない（spike で `prox=false`） | 使わない。「Not all iOS devices have proximity sensors.」（全機種にはない） |
| (d) 画面の向き（interface orientation） | 要らない | 前面だけ | - | faceDown という値そのものがない | - | 使えない |
| (e) CMMotionActivityManager や CMPedometer | **要る**（NSMotionUsageDescription の対象） | - | - | - | - | AC-24 に反するので外す |
| (f) カメラ、光のセンサー | **要る**（カメラ） | - | - | - | - | 外す |

結論：(a) にします。理由は4つです。
- 許可について、文書に出てくる条件が何もない。
- シミュレーターで、本物の知らせの流れを通して試せる。
- コードがいちばん少ない。
- 加速度計をシステムと分け合う。

アプリの側で、「伏せが1秒続いたら始める」と「一覧が前面で `idle` のときだけ見る」を足します。
加速度計が要るものとして `UIRequiredDeviceCapabilities` に accelerometer を入れることはしません。センサーのない環境は「読む」ボタンで受けるので、要りません。

## 2. 伏せたあとの画面

| 案 | 利点 | 危険 | 判定 |
|---|---|---|---|
| 何もしない（`isIdleTimerDisabled` も `isProximityMonitoringEnabled` も既定の false のまま） | 自動ロックの時間がたつと画面が消えてロックされ、アプリは止まる。数え方は r1 の 1-b（保存した開始の時刻との差）のまま。文書には「When most apps have no touches as user input for a short period, the system puts the device into a "sleep" state」とあり、加速度だけを入力にするアプリは自分で止めないと眠る、とも読める（「apps that don't have user input except for the accelerometer — games … can … disable the "idle timer"」） | 自動ロックまで（30秒〜5分。「なし」にしている人は消えない）、伏せた画面が点いたまま。机の上に光が漏れ、電池も少し使う | **推す**。AC-12 と同じ形 |
| 近接センサーで消す（始まったあとに有効にする） | 机に伏せればすぐ消える | ① ない機種がある（「Not all iOS devices have proximity sensors.」）。② 近接センサーで画面が消えている間に自動ロックが進むかは、文書に記載がなく未検証。進まなければ、ロックされないままアプリが前面で動き続け、起こしたときに認証なしで画面が出る（designer の心配のとおり）。③ 読書中の画面を見ているときにも、手が上に来ると消える。④ AC-10 と AC-12 の前提（ロックされて止まる）が変わる | 使わない（v1） |
| `isIdleTimerDisabled = true` | - | AC-12 に反する。Apple も「Most apps should let the system turn off the screen when the idle timer elapses.」と書いている | 使わない |
| 読書中の画面を暗い地にする | 光漏れと有機 EL の電力が減る | 見た目の判断になる | designer に任せる（任意） |

AC-12 との合わせ方：
- AC-12 はそのまま残し、「伏せて始めた」場合の行を足します（9 の AC-F5）。
- G3 では r1 の 1-c を広げます。`grep -rn isIdleTimerDisabled ios/` に加え、`grep -rn isProximityMonitoringEnabled ios/` も0行であることを見ます。さらに H9 の拡張（H17）で、`idleTimerDisabled=false;proximity=false` を読みます。
- G4 では、実機で自動ロックを30秒にし、伏せて始めて40秒以内に画面が消えることを見ます。

## 3. 誤って始まったときの扱い

想定する場面：
- S1：会議や食事のために伏せた。
- S2：仰向けに寝て、一覧を見ながら iPhone を顔の上に持ち上げた（画面が下を向く）。
- S3：手の中で一瞬ひっくり返した。
- S4：かばんに平らに入れた。
- S5：読み終えた直後に、いつもの癖で伏せた。

| 案 | 防げる場面 | 利点 | 危険 | 推奨 |
|---|---|---|---|---|
| O1 伏せが N 秒続いたら始める | S3、短い S4 | 一瞬の裏返しで始まらない。H4 と H5 の時計に乗せれば、sleep なしでテストできる | N が長いと、触覚が来る前に手を離して気づけない。S1 と S2 は防げない | **入れる。N=1.0秒**（G4 で 0.5〜2.0秒の間で見直す）。開始の時刻は「始めると決めた時刻」（AC-13 の「読み始めの日時」と同じ定義） |
| O2 始まったら触覚1回 | S1〜S4 に気づける | 伏せたまま知らせられる | 手が触れていないと感じない。システムの触覚を切っている人には出ない。iPad では出ない見込み（HIG：「on supported iPhone models」）。`.start` は iOS で鳴らない | **入れる。ただし補助として。** iOS で鳴る種類にする（Q-C） |
| O3 読書中の画面に「取り消す」を出す | すべて | すぐ戻せる | AC-9（押せるのは「終える」1つ）を壊す | 入れない |
| O4 1分未満は残さない（AC-15） | 1分以内に気づいた S1〜S4 | すでにある | 1分を超えると記録が残る | **そのまま使う** |
| O5 記録を消す（AC-21）、直す（AC-19） | 気づくのが遅れた S1、S2 | すでにある | 手順が3回以上になる | **そのまま使う** |
| O6 伏せる始め方を切れる設定（既定はオン） | 何度も誤って始まる人 | WCAG 2.5.4 の「responding to the motion can be disabled to prevent accidental actuation」（動きへの反応を切れること）に合う | 設定の行か画面が増える（PRD の 10 との関係） | **推す。決めるのは pdm**（Q-B） |
| O7 静止しているかを確かめる（Core Motion） | S2 | 持ち上げた状態と区別できる | 許可の扱いが決まらない。シミュレーターで試せない。調整が要る | v1 は入れない。G4 で S2 の誤りが多いときに見直す |
| O8 見るのは一覧（読む前）が前面のときだけ。終わりの画面では見ない | S5 | 読み終えた直後に伏せる癖での誤りを防ぐ | designer の「伏せ直すと続きが始まる」案とぶつかる | **入れる**（Q-D） |
| O9 一覧が前面になってから faceDown に「変わった」ときだけ数える | 伏せたまま起動したとき | 起動しただけで始まらない | ない | **入れる** |
| O10 終え忘れの上限（r1 の指摘 6 で求めた AC-26、AC-27） | 伏せたまま一晩たった S1 | 1440分を超える記録を残さない | ない | **r1 のとおり pdm が足す** |

## 4. テスト（シミュレーターでどこまで決められるか）

### 4-1. spike の結果（リポジトリの外。Xcode 27.0（27A266a）、iOS 27.0 のシミュレーター（24A434））
| 項目 | iPhone 17 | iPad mini (A17 Pro)（iPhone 用のアプリを互換表示） |
|---|---|---|
| 起動したとき | `o=1`（portrait） | `o=1`、`idiom=0`（phone）、`model=iPad` |
| テストから `XCUIDevice.shared.orientation = .faceDown` | アプリの向きは `o=6`（faceDown）、届いた知らせ `ev=6`（1回） | 同じ |
| `.portrait` に戻し、もう一度 `.faceDown` | `ev=6,1,6`（変わるたびに1回ずつ） | 同じ |
| Core Motion | `acc=false`、`dm=false` | 同じ |
| 近接センサー | `prox=false` | 同じ |
| 許可のダイアログ | springboard の alert 0、アプリの alert 0 | 同じ |
| テスト | passed（16.2秒） | passed（12.2秒） |

文書にも、この動きを支える一文があります（XCUIDevice.orientation）。「This impacts the orientation property UIKit uses to identify a device's physical orientation.」

### 4-2. G3（シミュレーター）と G4（実機、Takuma）の分け方
| 確かめること | G3 | G4 |
|---|---|---|
| 一覧が前面、`idle`、本が1冊以上で faceDown にし、1秒進めると `reading`。本は決めた本。触覚と読み上げを1回ずつ出した | ○（H15、H16、H17、H2） | 実機で、触覚を感じるか、読み上げが聞こえるか |
| 1秒未満で起こすと `idle` のまま。触覚は0回 | ○（H5 を進めない） | - |
| 一覧以外の画面（追加、直す、消す確認、記録の一覧、読書中、終わりの画面）と、本が0冊のときは始まらない | ○ | - |
| 起こしても止まらない。読書中に伏せ直しても2件目は始まらない | ○ | - |
| 伏せの検知を使えない、または設定でオフのとき：案内の文が出ず、「読む」で始められる | ○（H18） | - |
| 許可のダイアログ0回（AC-24。伏せる道も含める） | ○（H14 と H15） | 実機の新しい状態で、ダイアログ0回 |
| 画面を点けたままにしない、近接センサーを使わない | ○（H17 と grep） | 自動ロック30秒で、40秒以内に消える |
| 監視は一覧が前面で `idle` の間だけ | ○（H17 の `flipMonitoring`） | 任意：Xcode の Energy で一覧を5分開いて見る |
| センサーの実際の判定：机、厚いケース、ベッドやソファや膝、本を立てる台、**画面の向きのロックがオンのとき** | ×（シミュレーターにはセンサーも向きのロックもない） | ○ |
| 誤って始まる場面：仰向けで持ち上げる（S2）、かばん（S4） | × | ○（結果で O7 を見直す） |

### 4-3. つなぎ口の案（r1 の H1〜H14 の続き）
| 番号 | 名前 | 何のためか | 使う AC（9 の案） | 形 | 要否 |
|---|---|---|---|---|---|
| H15 | 伏せた向きを起こす（テストの側） | 実機の向きの変化を、本物の知らせの流れで起こす | F1〜F4、F6、AC-24 | `XCUIDevice.shared.orientation = .faceDown / .portrait / .faceUp`。アプリの側のつなぎ口は要らない（spike で確認）。向きは次のテストにも残るので、**各テストの setUp で `.portrait` に戻す**（文書：「Set the property once in your test fixture's setup」） | 要（テストの側だけ） |
| H16 | 伏せの待ちの時計 | 「伏せが1秒続いたか」を、sleep なしで決める | F1、F2 | 待ちを H4 の置き換えた時計で数え、H5 で進めたときに判定し直す（アプリの側の要件） | 要 |
| H17 | 合図と監視の状態を読む（H9 の拡張） | 触覚と読み上げを「アプリが出した回数」として数え、監視と画面の設定を読む | F1、F2、F4、F5、AC-12 | テストの構成でだけ、根の要素の accessibilityValue に `flipMonitoring=on|off;proximity=false;startedBy=flip|button;haptic=<回数>;announce=<最後の文言キー>` を足す。押せる要素は増やさない | 要 |
| H18 | 伏せの検知を使えない状態のまね | Mac で動くときや設定でオフのときと同じ動きを、シミュレーターで作る | F6 | 起動の引数 `-uitest-flip-unavailable` | 要 |
| （H2 の拡張） | 設定の値を入れる | O6 を入れたときの、オフの状態 | O6 の AC | H2 の JSON に `flipToStart=false` を足す | O6 を入れるなら要 |

どれも r1 と同じく、`#if DEBUG` かテストの構成でだけ有効にします。
H17 で分かるのは「出した」までです。「体に届いた」かは G4 で確かめます。

## 5. アクセシビリティ

| 人や支援技術 | 読み始められるか | 根拠と条件 |
|---|---|---|
| 伏せられない人、台に立てる人、立って読む人 | できる（「読む」） | HIG：「Offer alternatives to gestures … offer onscreen ways to achieve the same outcome.」。WCAG 2.5.4 も、画面の部品で同じことができることを求めている |
| VoiceOver | できる（「読む」）。伏せても始められる | 始まったら `AccessibilityNotification.Announcement`（iOS 17 から）で1回読み上げる。読み上げの文言キーは designer が決める |
| スイッチコントロール、音声コントロール、フルキーボードアクセス | できる（「読む」） | HIG：「Support Switch Control.」。ボタンに名前を付ける |
| 手が震える人 | 誤って始まりうる | O1（1秒待つ）と O6（切れる設定） |
| 音のない触覚だけで知らせてよいか | **触覚だけを知らせにするのは不可。補助としてならよい** | HIG：「Prefer using haptics to complement other feedback」「Make haptics optional … make sure people can still enjoy your app or game without them」。伏せている間は画面が見えないので、知らせは次の3つで組む：① 触覚（補助）、② VoiceOver の読み上げ、③ 起こしたときの読書中の画面（必ず見える）。音を足すかは「静か」の性格語との兼ね合いで、designer が決める |

HIG の Gyroscope and accelerometer には「Outside of active gameplay, avoid using accelerometers or gyroscopes for the direct manipulation of your interface」とあります。伏せる道は、画面を動きで直接動かすのではなく、1回だけ引き金を引くものなので、当てはまりは弱いと見ます。それでも、**ボタンを主の道とし、伏せるのは近道と書く**のが安全です（4.3(b) の説明でも同じ）。

## 6. iPad、Mac、Vision Pro、ケースと置き方

| 環境 | 動き | 根拠 | 扱い |
|---|---|---|---|
| iPad（iPhone 用のアプリを互換表示） | シミュレーターでは faceDown が同じように届いた（`idiom=0`、`model=iPad`） | spike。実機の iPad は未検証 | そのまま。触覚は出ない見込み（HIG：「on supported iPhone models」）。近接センサーは使わない |
| Apple シリコンの Mac で iPhone 用のアプリとして動くとき | 向きが変わらないので、伏せる道は効かない | `ProcessInfo.isiOSAppOnMac`：「true only when the process is an iOS app running on a Mac」 | 案内の文を隠す（H18 と同じ動き）か、Mac に配らない（Q-E） |
| Vision Pro の互換表示 | 伏せる道は効かない見込み | 判定する API は未確認 | Vision Pro に配らない（Q-E）。配るなら G1 で確かめる |
| 厚いケース、柔らかい面、傾いた面 | どこまで傾けると faceDown になるかは文書にない | 未検証 | G4 の確認リストに入れる |
| 向きが取れないとき（unknown、立てて置く台） | 何も起きない | - | 「読む」で受ける |

## 7. PrivacyInfo.xcprivacy
- **申告が要る API は増えません。** 申告が要る API の区分は、ActiveKeyboards、DiskSpace、FileTimestamp、SystemBootTime、UserDefaults の5つです（NSPrivacyAccessedAPIType の文書）。UIDevice の向き、近接センサー、Core Motion、触覚、読み上げは、どれも載っていません。
- 気をつけること：1秒の待ちを `systemUptime` や `mach_absolute_time` で測ると、SystemBootTime（35F9.1）の申告が要ります。待ちは r1 の 1-b と同じ時計（置き換えられる時計）で測ります。この時計を申告の一覧と照らすのは、r1 のとおり G1 の ADR で行います。
- 向きの値は端末の外に送らないので、NSPrivacyCollectedDataTypes は増えません。Q4 (b) でイベントに `started_by=flip|button` を足すとしても、r1 で書いた「製品の操作」の中に入ります。
- Info.plist の説明文：(a) では要りません。(b) を採るなら、実機でダイアログが出ないことを先に確かめます。

## 8. 4.3(b) の説明に付けられる技術の裏付け
- **ToRead との違いそのものを技術で裏付けるものは「なし」です。** UIDevice の faceDown は標準の API で、FocusFlip などの伏せるタイマーも同じことをしている見込みです。
- 添えられるのは、伏せるタイマー（R-8、R-9）との違いを、審査の担当が1分で確かめられる手順にすることだけです。持ち上げても止まらない、ロックしても止まらない、アプリが強制終了されても続く、の3つです。r1 の 1-b で、保存した開始の時刻から数えるので成り立ちます。Studydown の「アプリを離れた後の時間は加算されません」（R-8）とは逆の動きです。
  - 手順の例：伏せて始め、起こしてサイドボタンでロックし、30秒待って開くと数え続けている。

## 9. 推奨と、pdm が AC に書く値の案

推す組み合わせ：
- 向きの取り方は (a) UIDevice の faceDown。
- 見る条件：アプリが前面で、一覧（読む前）が前面にあり、シートや確認は出ておらず、状態が `idle` で、本が1冊以上あり、O6 を入れるなら設定がオン。
- 判定：一覧が前面になってから faceDown に変わり、それが1.0秒続いたら始める。
- 合図：触覚は iOS で鳴る種類を1回、VoiceOver がオンなら読み上げを1回。
- 始まったら向きを見るのをやめる（end を呼ぶ）。起こしても止めない。
- 近接センサーと `isIdleTimerDisabled` には触れない。
- 「読む」ボタンは同じ重みで残す。

AC の案（番号は pdm が付け直す）：
- AC-F1 伏せて始める
  - Given：本が1冊以上、`idle`、一覧が前面（シートや確認なし）
  - When：画面を下にして水平に置き、1秒以上そのままにする
  - Then：`reading` になり、本は一覧の先頭の本（または選んだ本。Q-D）。触覚1回。VoiceOver がオンなら、始まったことの文言が1回読み上げられる。許可のダイアログ0回。
  - 確かめ方：画面のテスト（H15、H16、H17）と、実機（G4）
- AC-F2 すぐ起こしたら始まらない
  - When：伏せて1秒未満で起こす
  - Then：`idle` のまま。触覚0回。記録は増えない。
- AC-F3 一覧のほかでは始まらない
  - Given：本の追加、本を直す画面、消す確認、記録の一覧、終わりの画面のどれかが前面。または本が0冊
  - When：伏せて2秒置く
  - Then：状態は変わらない。
- AC-F4 起こしても止まらない
  - Given：伏せて始めた
  - When：起こし、もう一度伏せ、また起こす
  - Then：`reading` のまま。読書は1件。触覚は最初の1回だけ。
- AC-F5 伏せたあと画面は自動ロックで消える
  - Given：自動ロック30秒で、伏せて始めた
  - When：触れずに置く
  - Then：40秒以内に画面が消え、`reading` のまま。
  - 確かめ方：G3 は H17 と grep、G4 は実機
- AC-F6 伏せる道がないときも始められる
  - Given：伏せの検知が使えない（H18）か、設定でオフ
  - When：一覧を開き、「読む」を押す
  - Then：伏せる案内の文は0個で、AC-5 のとおり始まる。
- O6 を入れる場合
  - Given：設定でオフ
  - When：伏せて2秒置く
  - Then：`idle` のまま。

値の案：
- 伏せてから始まるまで：1.0秒（G4 で 0.5〜2.0秒の間で見直す）
- 触覚：始まるときに1回。起こしたときと伏せ直したときは0回
- 読み上げ：1回
- 誤って始まったとき：1分未満は AC-15 で残らない。それより長いものは AC-21 で消す。r1 の指摘 6 の上限の AC も足す

12 の非機能に足す行の案：
- 向きの監視は、一覧が前面で `idle` の間だけ動く。測り方は、H17 の `flipMonitoring` を画面ごとに読み、一覧の `idle` 以外ではすべて off。

## r1 との関係
- 1-b（時刻の方針）：変えません。伏せて始めるときも、「読む」と同じく、開始の時刻とタイムゾーンを保存してから読書中の画面を出します。
- 1-c（AC-12）：近接センサーの grep と、H17 の読み取りを足します。
- 2（許可0回、バックグラウンドなし）：(a) を選べばそのまま成り立ちます。HIG の動きの注意（5、8 を参照）が新しく加わります。
- 申告の見込み：変わりません。

## 根拠（開いた日：すべて 2026-10-16。Apple の文書は developer.apple.com/tutorials/data/… の JSON で本文を読んだ）
- https://developer.apple.com/documentation/uikit/uidevice/orientation ：「This value represents the physical orientation of the device and may be different from the current orientation of your application's user interface.」「always returns 0 unless orientation notifications have been enabled by calling beginGeneratingDeviceOrientationNotifications()」
- https://developer.apple.com/documentation/uikit/uidevice/begingeneratingdeviceorientationnotifications() ：「This method enables the device's accelerometer hardware and begins the delivery of acceleration events to the device.」
- https://developer.apple.com/documentation/uikit/uidevice/endgeneratingdeviceorientationnotifications() ：「notifies the system that it can power down the accelerometer hardware if it isn't in use elsewhere.」
- https://developer.apple.com/documentation/uikit/uideviceorientation/facedown ：「The device is held parallel to the ground with the screen facing downwards.」
- https://developer.apple.com/documentation/uikit/uidevice/isproximitymonitoringenabled ：「Enable proximity monitoring only when your application needs to be notified of changes to the proximity state.」「Not all iOS devices have proximity sensors.」
- https://developer.apple.com/documentation/uikit/uiapplication/isidletimerdisabled ：上の 2 で引いた3つの文
- https://developer.apple.com/documentation/coremotion/cmmotionmanager ：「Create only one CMMotionManager object for your app.」
- https://developer.apple.com/documentation/coremotion ：「An iOS app must include usage description keys in its Info.plist file for the types of data it needs. … To access motion and fitness data, include NSMotionUsageDescription.」
- https://developer.apple.com/documentation/bundleresources/information-property-list/nsmotionusagedescription ：「This key is required if your app uses APIs that access the device's motion data, including CMSensorRecorder, CMPedometer, CMMotionActivityManager, and CMMovementDisorderManager.」
- https://developer.apple.com/documentation/coremotion/getting-raw-accelerometer-events ：「If your app relies on the presence of accelerometer hardware, configure the UIRequiredDeviceCapabilities key … with the accelerometer value.」
- https://developer.apple.com/design/human-interface-guidelines/gyro-and-accelerometer ：「the system includes your copy in a permission request」「Outside of active gameplay, avoid using accelerometers or gyroscopes for the direct manipulation of your interface. Some motion-based gestures may be difficult to replicate precisely, may be physically challenging for some people to perform, and may affect battery usage.」
- https://developer.apple.com/documentation/xcuiautomation/xcuidevice/orientation （Xcode 16.3 から）：「To simulate a change in the physical orientation of a device under test, set the value of the orientation property … This impacts the orientation property UIKit uses to identify a device's physical orientation.」
- https://developer.apple.com/documentation/swiftui/sensoryfeedback/start ：「Use this haptic when starting a timer …」「Only plays feedback on watchOS.」。…/stop も「Only plays feedback on watchOS.」。…/success：「Indicates that a task or action has completed.」「Only plays feedback on iOS and watchOS.」。…/impact(weight:intensity:)：「Use this to provide feedback for UI elements colliding. It should supplement the user experience」「Only plays feedback on iOS and watchOS.」
- https://developer.apple.com/design/human-interface-guidelines/playing-haptics ：「Prefer using haptics to complement other feedback」「Make haptics optional.」「on supported iPhone models」「build a clear, causal relationship between each haptic and the action that causes it」
- https://developer.apple.com/documentation/accessibility/accessibilitynotification/announcement ：「A notification that an app posts when it needs to convey an announcement to an assistive app.」（iOS 17.0 から）
- https://developer.apple.com/design/human-interface-guidelines/accessibility ：「Offer alternatives to gestures. … offer onscreen ways to achieve the same outcome.」「Support Switch Control.」
- https://developer.apple.com/documentation/foundation/processinfo/isiosapponmac ：上の 6 で引いた文
- https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype ：区分は5つ（上の 7）。Core Motion と向きの記載はない
- https://www.w3.org/WAI/WCAG22/Understanding/motion-actuation.html （W3C。Apple の文書ではない）：「Functionality that can be operated by device motion or user motion can also be operated by user interface components and responding to the motion can be disabled to prevent accidental actuation」

向きのロックについて検索しましたが、公式の答えは見つかりませんでした。次の結果は**根拠にしていません**。「物理的な向きの知らせは画面の向きと別に届く」という公式でない手がかりがあるだけです。
- [codemia: getting device orientation in swift](https://codemia.io/knowledge-hub/path/getting_device_orientation_in_swift)
- [Apple Developer Forums thread 769541](https://developer.apple.com/forums/thread/769541)
- [RemObjects blog (2010): handling faceUp/faceDown](https://blogs.remobjects.com/2010/06/29/handling-uideviceorientationfaceup-uideviceorientationfacedown)
- [CocoaPods: MotionOrientation](https://cocoapods.org/pods/MotionOrientation@PTEz)

## 変更したファイル
- リポジトリの中：なし。
- spike（リポジトリの外。消してかまいません）：/private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/flipspike
  - アプリは、向き（`o=`）、知らせの並び、加速度の z、Core Motion と近接センサーの有無を画面に出します。最後の版では、実機での確かめ（Q-A）のために、加速度を 10Hz で読む処理を足しています。

## 実行したコマンドと結果
- `git rev-parse HEAD` → `92409d653a5a96eda5b29bf102bbdfdeef85d568`
- `xcodebuild -version` → `Xcode 27.0 / Build version 27A266a`。シミュレーターの実行環境は iOS 27.0（24A434）だけ。iOS 26 のシミュレーターはない。
- spike：
  - `xcodebuild test -project FlipSpike.xcodeproj -scheme FlipSpike -destination 'platform=iOS Simulator,name=iPhone 17' -destination 'platform=iOS Simulator,name=iPad mini (A17 Pro)' -derivedDataPath …/flipspike/dd`
    → `** TEST SUCCEEDED **`、`Test case 'FlipSpikeUITests.testFaceDown()' passed on 'iPad mini (A17 Pro)' (12.205 seconds)`、`… passed on 'iPhone 17' (16.234 seconds)`
  - `xcrun xcresulttool get test-results activities --test-id 'FlipSpikeUITests/testFaceDown()' --path …xcresult` の抜き出し：
    - `SPIKE start: o=1 | acc=false dm=false prox=false idiom=0 model=iPhone`
    - `SPIKE after faceDown: o=6 | ev=6 | waitResult=1`
    - `SPIKE after portrait: o=1 | ev=6,1 | waitResult=1`
    - `SPIKE after 2nd faceDown: o=6 | ev=6,1,6 | waitResult=1`
    - `SPIKE alerts springboard=0 app=0`
    - iPad mini でも同じ値（`model=iPad`、`idiom=0`）。
    - 活動の記録に `Device orientation changed to Face Down` もあった。
  - 加速度を読む処理を足したあとに `xcodebuild build … -destination 'platform=iOS Simulator,name=iPhone 17'` → `** BUILD SUCCEEDED **`
- 最後の `git status --short`（リポジトリ）：
```
 M docs/prd/001-reading-session.md
```
  - この変更は、同じ時間に作業している pdm の書き換えです。私の変更ではありません。1回目に実行したときは何も出ませんでした（変更なし）。

## 未解決（未検証）
1. 画面の向きのロックがオンのときに、UIDevice に faceDown が届くか（実機のみで確かめられる。案 A の価値に直接かかわる）。
2. CMMotionManager で加速度を読むと、実機で許可のダイアログが出るか（(a) が使えないときの代わりの前提）。
3. faceDown になる傾きの範囲と、知らせのぶれ（ケース、柔らかい面、膝）。仰向けで持ち上げたとき（S2）の誤りの多さ。
4. 近接センサーで画面が消えている間に自動ロックが進むか（使わないので、実害はない）。
5. 実機の iPad、Vision Pro の互換表示での動き。Vision Pro で動いていることを判定する API。iPhone と iPad のアプリが Mac と Vision Pro に初期設定で配られるか（App Store Connect の設定）。
6. iOS 26 のシミュレーターでの動き（iOS 27 だけで確かめた）。
7. VoiceOver の読み上げを XCUITest で直接確かめられるか（H17 で「出した」ことだけを見る前提にした）。
8. 監視による電池の消費の数字（測っていない）。

## 質問（指揮役から各役へ）
- Q-A（Takuma）：G0 r2 の前に、実機で10分の確認をしますか。
  - 決めてほしいこと：上の spike のアプリを Xcode で手元の iPhone に入れ（署名に自分のチームを設定する）、次の3つを見るか。① 向きのロックがオンとオフのそれぞれで伏せて `o=6` になるか、② 加速度の z が出るときに許可のダイアログが出るか、③ ベッドで仰向けに持ち上げたときに `o=6` になるか。
  - 推奨：する。①で届かないと、案 A の取り方が (b) に変わり、AC-24 の扱いも変わるため。
  - いちばん強い反論：G4 まで待てば手間が1回で済む。
  - 元に戻せるか：戻せる（何も残らない）。
  - 見てほしいもの：この報告の 1 と 4-1。spike は一時フォルダにあるので、消えていたら作り直します（約40行）。
- Q-B（pdm）：伏せる始め方を切れる設定（O6）を入れますか。推奨は入れる（WCAG 2.5.4）です。反論は、設定の行が増え、PRD の 10 の範囲が広がることです。
- Q-C（designer）：触覚の種類を `.start` と `.stop` から替えてください（iOS では鳴らない）。候補は `.success`（「task or action has completed」）か `.impact`（「supplement」）です。読み始めと終わりで、同じ触覚にしないでください（HIG の「clear, causal relationship」）。
- Q-D（pdm）：どの本で始めるか（先頭の本か、選んだ本か）。読み終えた画面で伏せ直すと続きが始まる案は、読み終えた直後に伏せる癖で誤って始まる（S5）ので、推しません。
- Q-E（Takuma）：Mac と Vision Pro に配りますか。推奨は v1 では配らないです。伏せる道が効かず、確かめる手間が増えるためです。元に戻せます（App Store Connect の設定）。
- この見立ての大きな判断（(a) を選ぶこと、近接センサーを使わないこと、1.0秒、O8）は、私の判断です。作るのは pdm の AC が決まってからですが、G0 r2 か G1 で、reviewer に反論を出してもらってください。

## 記録（指揮役が保存するときに書き足す）
- 種類：判定の前の調べもの（tech-lead）。PASS / FAIL なし
- 関門：G0（r2 の前）
- 対象：案 A「伏せて読み始める」（design/001-reading-session/candidate-A-flip.md）、BASE=92409d653a5a96eda5b29bf102bbdfdeef85d568
- 日付：2026-10-16
- 指揮役のメモ：pdm（作り直し その1）は、伏せる道を切る設定（O6）を v1 に入れないと決めた。tech-lead は WCAG 2.5.4 を根拠に入れることを推す。食い違いなので、作り直し その2 で pdm に根拠を渡して決め直させ、G0 r2 で判定役に見てもらう。
