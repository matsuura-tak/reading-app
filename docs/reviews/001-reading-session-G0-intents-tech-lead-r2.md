（指揮役の注）G0 の狭い判定 r2（tech-lead、実現性。裁定 21。足した部分の往復2回のうち2回目で、最後の回）。対象は docs/prd/001-reading-session.md と docs/prd/product.md（コミット 3e521dd。AC 136件）のうち、pdm が r1 の指摘で直した所と、足した AC-130〜AC-136。報告の文はそのまま保存した。

PASS

（tech-lead による G0 の狭い判定 r2、実現性の担当。裁定 21 による最後の回）
- 対象：docs/prd/001-reading-session.md と docs/prd/product.md のコミット 3e521dd（AC 136件）。見たのは 98e0200..3e521dd の差分。
- 差分の hunk はすべて読んだ。
- 前の回の文書、spike、メモを引き継いだうえで、次の4つを新しく行った。
  - SDK を確かめた。
  - spike r2 を1つ行った。ビルドだけで、シミュレーターの端末は作っていない。
  - Apple Platform Security を開いた。
  - Apple の利用者ガイドを日本語と英語の2ページ取った。

## 結論
- 直さないと通さない点はない。
- その1 の重大2件は、どちらも直った。
  - 重大1：
    - 「終える」は「インテントが動いた時刻」で記録するようになった。
    - ロック中に押して認証されなければ、何も変わらない形になった。
    - AC-116 の (2) は「前に出せない状態」に替わった。
    - G4-21 の (6) は、認証を求められた場合と求められずに動いた場合の2つに分かれた。
  - 重大2：案1 になった。認証の決まりは alwaysAllowed のままで、出さない設定がオンでロック中ならページを答えない。AC-123、H32、G4-22、:1253 がそろっている。
- 足した AC-130〜AC-136 と、直した AC-41、AC-114〜AC-123、AC-125〜AC-127 は、どれも今の構成で作れる。
  - 新しい API も依存も要らない。
  - 条件は前の回と同じで、次の3つ。
    - G3 は H32 で動かす。
    - システムの入口は G4 で見る。
    - 予約の取り消しは G1-4 の spike で確かめる。
- H32 の (i) の AppIntentsTesting は、Xcode 27 に実在した。ただし、宣言はすべて iOS 27.0 からである。
- 要修正は3件ある。
  1. 「どこまで読んだ？」を置くターゲットの決まりがない。ウィジェットの拡張にも入れると、ビルドが落ちる（spike r2）。
  2. :1450 の「直さない」理由に、事実の誤りがある。
  3. G4-21 と G4-22 の準備に、「パスコードを要求」が「即時」であることの確かめがない。
- 見積もりは、今回の直しでおよそ 1.0〜2.1日増える［推測］。
  - 要る速さは、上の端で最大 +0.14倍。
  - 回す順を決め直すほどではない（提案2）。

## 指摘

### 重大（直さないと通さない）
- なし

### 要修正（直すとよい）

**要修正1：「どこまで読んだ？」を置くターゲットと、動くプロセスが決まっていない**
- 場所：:298（ロックの状態は isProtectedDataAvailable で決める）、G1-17（:1472）
- 理由
  - isProtectedDataAvailable は UIApplication のインスタンスの値である。
  - UIApplication.shared は、拡張では使えない。SDK の UIApplication.h:87 に `@property(class, nonatomic, readonly) UIApplication *sharedApplication NS_EXTENSION_UNAVAILABLE_IOS("Use view controller based solutions where appropriate instead.");` とある。
  - G1-17 は、「読み始める」と「終える」を、アプリとウィジェットの拡張の両方のターゲットに入れると決めた。同じファイルか、拡張とつなぐ共有の置き場所に「どこまで読んだ？」も入れると、拡張の側で組めない。
  - spike r2 で確かめた。
    - 前の IntentSpike を写し、両方のターゲットが組む Shared.swift に `UIApplication.shared.isProtectedDataAvailable` を足して、ビルドした。
    - 結果は exit 65 だった。
    - 落ちたのは、ターゲット IntentSpikeWidgets の `Shared.swift:141:67: error: 'shared' is unavailable in application extensions for iOS: Use view controller based solutions where appropriate instead.` と `** BUILD FAILED **` である。
  - アプリのターゲットだけに置けば、アプリのプロセスで動く。v1.0 には App Intents の拡張がないからである。
    - IntentExecutionTargets の文書（iOS 27.0）："By default, the system performs an intent or entity query using any available target."
    - 前の spike 3 では、アプリのプロセスの perform の中でこの値を読めた（events.log の `protectedData=true`）。
  - 共有の Swift パッケージに入れたとき、組む時に落ちるか、動かして初めて分かるかは未確認。
- 直し方の案：G1-17 に次の1文を足す。AC は変わらない。
  - 「『どこまで読んだ？』と『続きを読む』は、アプリのターゲットだけに置く。ウィジェットの拡張にも、拡張とつなぐ共有のパッケージにも入れない。ロックの状態を読む部品は、アプリのプロセスでだけ使う（UIApplication.shared は拡張で使えない）。」
  - 別の案もある。拡張でも動く確かめ方にする形で、たとえば complete の等級の目印のファイルが読めるかで決める。この案なら、:298 の「isProtectedDataAvailable で決める」を、その形に替える。

**要修正2：:1450 の理由「声の道は『続きを読む』で残る」が、回す順と合わない**
- 場所：付記の :1450（その2 の提案6 を採らない理由）
- 理由
  - 回す順は積み上げである。:7 の (iii) に「下の順で回す」とあり、(ショートカット) は (5) より前にある。
  - だから (5) まで回すときは、(ショートカット) ももう回っていて、「続きを読む」も Siri も残らない。:353 の「予約した Live Activity も回したら、AC-125 と AC-126 も外す」も、同じ読み方をしている。
  - 採らないこと自体は、pdm と Takuma が決める優先の話なので、受け入れる。直すのは理由の文だけである。
- 直し方の案
  - 理由を次の文に直す。「(5) まで回すときは (ショートカット) も回っているので、声の道もボタン1回の道も残らない。それでも、約1日［推測］を戻すと回す意味が減るので採らない。測った速さに余りが出たら、(iii) で指揮役が Takuma に出せる。」

**要修正3：G4-21 と G4-22 の準備に、「パスコードを要求」が「即時」であることの確かめがない**
- 場所：:1217（G4-21 の準備）、:1218（G4-22 の準備）
- 理由
  - Apple Platform Security には、complete の等級の鍵について "Shortly after the user locks a device (10 seconds, if the Require Password setting is Immediately)" とある。
  - 「即時」でなければ、ロックしたあとも鍵がしばらく残る。そのあいだ isProtectedDataAvailable は真のままなので、「ロック中」のつもりの回が「ロックを外した」回として動く。すると G4-22 の「出さない設定がオンでロック中」の回が、作りの誤りがなくても落ちうる。
  - 今の準備では、Face ID の「iPhone のロック解除」をオフにする。オフにしたとき「パスコードを要求」の値がどうなるかは、未確認である。Apple の利用者ガイドのパスコードのページを日英で取ったが（どちらも HTTP 200）、この項目の記述はなかった。
- 直し方の案
  - 準備に次の1つを足す。「『パスコードを要求』が『即時』であることを確かめる。項目がなければ、そのことを記録する。設定の名前は Takuma が実機で確かめる。」
  - G4-22 の記録に、「ロックしてから頼むまでの秒数」を足す。
  - 今の「ロックして1分以上待つ」は10秒より長いので、そのままでよい。

### 提案
1. **:298 に「ロックしてから約10秒」の注を足す（pdm の頼みの2の答え）**
   - 「即時」のときでも、ロックしてから約10秒は鍵が残る。そのあいだは、ロックを外した扱いになる。
   - だから出さない設定がオンでも、この間はページを答える。
   - 足す1文の案：「ロックしてから約10秒（パスコードを要求が即時のとき）は、ロックを外した扱いになる［公開情報 Apple Platform Security］」
   - H32 で差し替えるので、AC は変わらない。
2. **冒頭の見積もり（:6）に、今回の直しで増えた分を足すか、G1-20 で測り直すと書く**
   - 増えた作業：AC-130〜AC-136、予約の決まりの変更、エラーの道、AC-41 の形、文言キー3つ。合わせて +1.0〜2.1日［推測］。内訳は証拠の「見積もりの差分」。
   - 回す所が変わるのは、測った速さが境目のすぐ上にあるときだけ。
3. **H32 は (ii) を土台にする（pdm の頼みの1）**
   - AppIntentsTesting は、宣言がすべて `@available(macOS 27.0, iOS 27.0, …)` である。iOS 26.x のシミュレーターでは使えない。
   - :1221 は、インテントのテストを iOS 26.x でも動かすと決めている。runtime が入れば、(ii) は必ず要る。
   - 2つの口を作るより、次の分け方の方が安い［推測］。
     - (ii) を土台にする。
     - (i) は、iOS 27 でシステムを通す確かめに使う。
   - どちらにするかは G1-17 で決める。
4. **システムが終えた Live Activity に終わりの要求を出したときの振る舞いを、G1-4 の spike に入れる（pdm の頼みの3）**
   - 文書にあるのは "After the eight-hour limit, the system automatically ends the Live Activity" と、終わったあと消える時刻は end(_:dismissalPolicy:) で決まる、というところまで。終わったものに end を出したときの振る舞いは書かれていない（未確認）。
   - AC-136 は、終えたあとの終わりの要求を数えていないので、どちらでも合否は変わらない。
   - 終わったあとロック画面に最長4時間残る「終える」を押せるかも、G1-7 の見え方と一緒に記録するとよい。

## その1 と その2 の指摘の追跡
行番号は 3e521dd のもの。

**その1**
| 番号 | 中身 | 結果 | 確かめた所 |
|---|---|---|---|
| 重大1 | ロック中の「終える」と押した時刻 | 直った | :294（動いた時刻、preciseTimestamp の注、ロック中は認証まで動かない、認証されなければ何も変わらない、前に出せないとき）、AC-116 の題と (2)（:798、:800〜801）、G4-21 の (6) |
| 重大2 | 出さない設定のときの認証 | 直った（案1） | :298、:102、:111、:172、AC-121（:849）、AC-123（:864〜869）、H32（:339 に認証の差し替えがない。:341 で authenticationPolicy を産物から読む）、G4-22、:1253、G1-16 |
| 要修正1 | H32 を作れる形に | 直った | :335〜342。(i) の API は実在（証拠） |
| 要修正2 | G4 で本当にロックした状態を作る | 直った（「即時」の確かめだけ足りない。要修正3） | :1217、:1218 |
| 要修正3 | ロック中に前に出せないとき | 直った | :293 の末尾、AC-118 の (2)、G4-21 の (4) |
| 要修正4 | :264 と G1-16 を分ける | 直った | :264、G1-16 の (a) と (b)（:1471） |
| 提案1 | インテントから取り消す spike | 直った | G1-4（:1459） |
| 提案2 | 機内モードの回は Control で | 直った | G4-21 の (2) |
| 提案3 | iOS 26.x の G3 にインテントを入れる | 直った | :1221 |
| 提案4 | 回ごとの秒数を記録 | 直った | G4-21 の準備、:1232 |
| 提案5 | 最初のロック解除の前の回 | 直った | G4-21 の (7)（記録だけ。合否は「前の本と記録が残る」） |
| 提案6 | 両方のターゲットに入れる | 直った | G1-17。「どこまで読んだ？」の置き場所は、新しい要修正1 |
| 提案7 | 軽い脅威モデル | 直った | G1-16 |

**その2**
| 番号 | 中身 | 結果 | 確かめた所 |
|---|---|---|---|
| 要修正1 | 見積もりの単位 | 直った | :6、:11、G1-20。数字は、その2 の証拠の3の表と一致する（36.95〜51.75日。2.5〜3.5、2.2〜3.1、2.1〜2.9、2.0〜2.8、1.8〜2.6、1.5〜2.0、1.3〜1.8倍。2.35〜4.25、1.0〜2.0、0.6〜1.0日。計 3.95〜7.25日、うち実装 2.0〜3.75日） |
| 要修正2 | H10 の区間の端 | 直った | H10（:317）、:1232、AC-114（:789、:790 の Release） |
| 要修正3 | H23 の押せる要素の読み方 | 直った | H23（:326） |
| 要修正4 | すぐ始める要求の失敗 | 直った（案A） | :293、AC-131、H23 と H17（:320、:326） |
| 要修正5 | G1-19 は G0 で決める | 直った | :263、:286〜287、AC-130、G1-19。AC-36 の (1)(2)、AC-37、AC-38、AC-56、AC-97、AC-98、AC-115 の値が、新しい決まりで変わらないことを手で追った（AC-36 の (2) の 10/19 21:00 は晩が 10/19 なので「今夜」でない） |
| 要修正6 | iOS 26 の G3 | 直った | :1221 |
| 要修正7 | BookEntity | 直った | G1-18（:1473）、:1253 |
| 要修正8 | 審査メモ | 直った | :1355 |
| 提案1 | 「終える」の読み上げ | 直った | G1-15、:1264、H23 |
| 提案2 | staleDate と8時間 | 直った | :290、:295（原文を確かめた。証拠）、AC-136、AC-114 |
| 提案3 | 2.5.1 | 直った | :1364 |
| 提案4 | ふりかえりの年 | 直った | :302 |
| 提案5 | product.md の I-2 | 直った | product.md:92 |
| 提案6 | (5) を回すときに、前に出す形の「読み始める」を残す | 採らない。採らないことは受け入れる。ただし理由の文に誤りがある（要修正2） | :1450 |
| 提案7 | INAlternativeAppNames | 直った | G1-15 |
| 提案8 | ふりかえりの組 | 組は変えない。理由で受け入れる | :11 の末尾（技術の依存はない、と書いた）、:1451 |

## 証拠
実行したコマンドと結果（すべて 2026-10-19 に実行）
- `git log --oneline -12`：9078b43 と 3e521dd がある。
- `git diff --stat 98e0200 3e521dd -- docs/prd/`：`2 files changed, 147 insertions(+), 82 deletions(-)`
- `git diff -U0 98e0200 3e521dd -- docs/prd/001-reading-session.md | grep '^@@'`：新しい側の hunk は 3,6,11,102,111,172,263,286,290,301,310,317,320,326,335,352,623,644,788〜897 の各所,1068,1217,1221,1232,1253,1264,1355,1364,1406,1430,1448,1459,1462,1470〜1475。すべて読んだ。
- `grep -nE '^- AC-(41|11[4-9]|12[0-9]|13[0-6])：' docs/prd/001-reading-session.md`：AC-41 は :620、AC-130 は :644、AC-114〜AC-126 と AC-131〜AC-136 は :786〜:894、AC-127〜AC-129 は :1066〜:1078。
- `xcodebuild -version`：`Xcode 27.0`、`Build version 27A266a`。SDK は iPhoneOS27.0.sdk。
- `xcrun simctl list runtimes`：`iOS 27.0 (27.0 - 24A434)` と visionOS 27.0 だけで、iOS 26 の runtime はない。
- `find "$DEV/Platforms/iPhoneOS.platform" "$DEV/Platforms/iPhoneSimulator.platform" … -iname '*AppIntentsTest*'`：次の2つにある。
  - …/iPhoneOS.platform/Developer/Library/Frameworks/AppIntentsTesting.framework
  - …/iPhoneSimulator.platform/Developer/Library/Frameworks/AppIntentsTesting.framework
- `grep -nE … AppIntentsTesting.swiftmodule/arm64e-apple-ios.swiftinterface`（311行）
  - :153 `public struct IntentDefinitions : Swift::Sendable`
  - :155 `public init(bundleIdentifier: Swift::String)`
  - :271 `public func run() async throws -> AppIntentsTesting::ResolvedIntentResult`
  - 宣言はどれも `@available(macOS 27.0, iOS 27.0, watchOS 27.0, tvOS 27.0, visionOS 27.0, *)`
- `grep -nE "isProtectedDataAvailable|sharedApplication" …/UIKit.framework/Headers/UIApplication.h`
  - :87 `sharedApplication NS_EXTENSION_UNAVAILABLE_IOS("Use view controller based solutions where appropriate instead.")`
  - :161 `getter=isProtectedDataAvailable … API_AVAILABLE(ios(4.0)) NS_SWIFT_NONISOLATED`
- `grep`、`sed` で ActivityKit の arm64e-apple-ios.swiftinterface を見た。
  - :68 `request(…alertConfiguration:…, start: Foundation::Date) throws` は `@available(iOS 26.0, *)`。startDate の形は `deprecated: 26.0`。
  - :179、:185、:191 は `end(…)` の3種類。
  - :385〜394 の ActivityState は、`pending`（iOS 26.0）、`active`、`ended`、`dismissed`、`stale`。
  - :560 `public enum ActivityAuthorizationError`
- spike r2
  - `rsync` で、前の回の IntentSpike を g0-intents-tech-lead-r2/spike/ に写した。
  - Shared.swift の末尾に `import UIKit` と `@MainActor static func isLockedNow() -> Bool { !UIApplication.shared.isProtectedDataAvailable }` を足した。
  - `xcodebuild build -project IntentSpike.xcodeproj -scheme IntentSpike -destination 'generic/platform=iOS Simulator' -derivedDataPath …/r2/spike/dd CODE_SIGNING_ALLOWED=NO`
  - 結果：exit=65。build-r2.log:612 `Shared.swift:141:67: error: 'shared' is unavailable in application extensions for iOS: Use view controller based solutions where appropriate instead.`、:943 `** BUILD FAILED **`、:946〜948 `(in target 'IntentSpikeWidgets' from project 'IntentSpike')`。pbxproj で、拡張の設定は `APPLICATION_EXTENSION_API_ONLY = YES`、配備の下限は `IPHONEOS_DEPLOYMENT_TARGET = 26.0`、`SWIFT_VERSION = 6.0`。
- `python3 -I …/g0-intents-tech-lead-r2/para.py <正規表現> <JSON>`：la.json、activitykit_activity.json、appintents_intentexecutiontargets.json、appintents_appintent.json、ipda.json、hig/live-activities.json から段落を抜いた。原文は下の「開いた文書と原文」にある。
- `python3 -I -`（見積もりの計算）：`A delta [0.76, 1.6] B delta [0.25, 0.5] total 1.01 2.1`。`none 37.96-53.85 speed 2.53-3.59 (before 2.46-3.45)` ほか（下の「見積もりの差分」の表）。
- `curl -sL` で Apple の利用者ガイドを取った。
  - 日本語：`ja 200 1412585`。英語：`en 200 1443771`。
  - 本文を抜いても、「パスコードを要求」「Require Passcode」の記述はなかった。
- WebFetch で https://support.apple.com/guide/security/data-protection-classes-secb010e978a/web を開いた（原文は下）。
- `sed -n` で AC-36、AC-37、AC-38、AC-56、AC-127 と、変わった hunk を読んだ。
- 端末の確かめ：`xcrun simctl list devices | grep -c "TL-R2"` → `0`
  - spike の端末は作っていない。ビルドは generic の destination だけで行った。
  - ほかの端末と、scratchpad の device-check/ には触っていない。

見たファイルのパス
- /Users/takumamatsuura/reading-app/docs/prd/001-reading-session.md
  - :1〜16、:100〜112、:170〜173、:255〜359、:618〜649、:786〜899、:1066〜1071、:1214〜1255、:1262〜1266、:1350〜1366、:1404〜1413、:1430、:1444〜1475
  - AC-36〜AC-38、AC-56
- /Users/takumamatsuura/reading-app/docs/prd/product.md:92
- /Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-G0-intents-tech-lead.md（全文）
- /Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-G0-intents-pdm-fix.md
- /Users/takumamatsuura/reading-app/docs/reviews/001-reading-session-G0-ruling.md
- 前の回のメモ（読むだけ）
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g0-intents-tech-lead/notes.md
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g0-intents-tech-lead/part1-notes.md
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g0-intents-tech-lead/part2-notes.md
- 自分の産物
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g0-intents-tech-lead-r2/notes.md
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g0-intents-tech-lead-r2/para.py
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g0-intents-tech-lead-r2/spike/build-r2.log
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g0-intents-tech-lead-r2/spike/IntentSpike/Shared/Shared.swift（末尾に足した行が spike）
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g0-intents-tech-lead-r2/dl/passcode-ja.html
  - /private/tmp/claude-501/-Users-takumamatsuura-reading-app/54111b04-6b80-410d-9782-7fbf5f807550/scratchpad/g0-intents-tech-lead-r2/dl/passcode-en.html
- リポジトリのファイルは書いていない。コミットもしていない。

### 足した AC と直した AC の実現性
| AC | 判定 | 根拠と条件 |
|---|---|---|
| AC-41（直した） | 今の構成で作れる | 予約もすぐ始めるも、同じ Activity<Attributes> の型で描く。中身の操作の一覧 [.end] から「終える」を描く（H23 の新しい形）。更新は後ろからもできる（Activity の文書） |
| AC-114 | 作れる（条件：H32） | H10 は perform() から request が返るまでで、アプリの中で測れる。staleDate は中身に入る。押せる要素は H23 の一覧と、H22 の数え方 |
| AC-115 | 作れる（(4) は G1-4 が条件） | 数え始めを最後の「読み始める」にしたので、起動と前面化の見直しに左右されない。(4) は、まだ始まっていない予約の取り消し（ActivityState.pending は iOS 26.0。取り消せるかは G1-4） |
| AC-116 | 作れる | (2) は H32 で canContinueInForeground を偽にする。記録は perform の始まりの時刻 |
| AC-117〜AC-120 | 作れる | foreground(.dynamic) と continueInForeground（前の回の原文と spike 3） |
| AC-121、AC-122 | 作れる | alwaysAllowed。値は Metadata.appintents から読める（前の spike 2 で 0/1/2） |
| AC-123 | 作れる（前の回は作れなかった） | 案1。perform の中で、ロックの値と設定を見て答えを替える。条件は要修正1 |
| AC-125、AC-126 | 作れる | 通信しない。App Shortcuts の言い方の数は産物の phraseTemplates から、Control はアプリの表から数える |
| AC-127（直した） | 作れる | H24 の描いた文字の一覧で見る。カードの合計（142分、2時間22分）に「38分」は入らない |
| AC-130 | 作れる（条件：G1-4） | 前面で取り消す。20:30 から 21:05 で35分。読書中は見直さないので、前面化での要求は0件 |
| AC-131 | 作れる | request は throws（ActivityAuthorizationError）。H23 で失敗させたあと continueInForeground |
| AC-132 | 作れる | 保存に失敗したあと continueInForeground。spike 3 で「保存してから前に出す」の順が動いた。前に出せなければ perform からエラーを投げる |
| AC-133〜AC-135 | 作れる | H7 の store.load。「続きを読む」は今の状態の画面を出すだけ |
| AC-136 | 作れる | H23 は、アプリが ActivityKit を包んだ部品の差し替え。ActivityState に ended と dismissed がある。アプリは前面から request をしない。22:00 から 07:00 で540分 |

**直した決まり（11 の冒頭）**
- 次の5つは作れる。アプリの決まりでそのまま作れるか、ActivityContent の staleDate を使う。
  - :286 `reading` の間は見直さない。
  - :286 1分未満で終わったときも見直す。
  - :290 すぐ始める Live Activity の staleDate。"At the specified date, the activityState changes to ActivityState.stale"
  - :290 `reading` の Live Activity を、アプリから終わらせない。end を呼ばないだけで、AC-98 は `idle` のときだけに効く。
  - :295 アプリは Live Activity を出し直さない。
- :287 の取り消しは、前面（アプリの中、伏せて）からと、インテントのプロセスからの両方で行う。どちらも G1-4 で確かめる（:1459 に入った）。
- :293 と :294 の「前に出せないとき」は、前の回の原文で決まる。"If you call this method and it's not possible to transition the app to the foreground, the system throws an notAllowed error."
- つなぎ口の新しい形は、どれも作れる。
  - H10（:317）、H23（:326）、H32（:335〜342）
  - H32 の (i) は iOS 27.0 だけ（上のコマンドの出力）。
- G4-21 と G4-22 の手順は iPhone で行える。足りないのは要修正3 だけ。
  - Action ボタンの割り当て、ロック画面の Control、ロック中の Siri は、iOS 26 の機能の中にある。
  - 設定の名前は、PRD のとおり Takuma が実機で確かめる。

### 「どこまで読んだ？」のロックの判定（範囲の4）
- アプリのプロセスで動くと決まっているか：PRD には決まりがない。
  - G1-17 は、両方のターゲットに入れるのを「読み始める」と「終える」とだけ書いている。
  - アプリのターゲットだけに置けば、App Intents の拡張がないのでアプリで動く。
- 拡張にも入れたとき：spike r2 で、拡張のターゲットのコンパイルが落ちた（要修正1）。
  - 黙って動かなくなるのではなく、ビルドで見つかる。
  - 共有のパッケージにした場合は未確認。
- ロック直後の時間：約10秒。「Require Password」が「Immediately」のときの値（Platform Security）。

### pdm の頼み6つの振り分け
6つとも「G1 でよい」。どれも AC を変えない。

| # | 頼み | 答え | G0 か G1 か |
|---|---|---|---|
| 1 | H32 を (i) と (ii) のどちらにするか、iOS 26.x でどう動かすか | (i) は実在するが iOS 27.0 だけ。iOS 26.x では (ii) が要る（提案3） | G1 でよい。AC の読み方は :337 で (ii) についても決まっている |
| 2 | ロック直後に isProtectedDataAvailable が偽になるまで | 「即時」のとき約10秒 | G1 でよい。G4 の準備は今直すとよい（要修正3）。:298 の注は提案1 |
| 3 | システムが終えた Live Activity に終わりの要求を出せるか | 文書にない（未確認）。AC-136 は数えていない | G1 でよい（提案4） |
| 4 | H23 で「システムが終えた状態」と「すぐ始める要求の失敗」を差し替えられるか | できる。アプリが包んだ部品を差し替える。システムが起こしたプロセスでは、App Group のファイルで効かせる（:338） | G1 でよい。形は G1-17 |
| 5 | AC-132：保存の失敗のあと、前に出してエラーを出せるか | できる（上の表） | G1 でよい |
| 6 | G1-4 の spike に、インテントのプロセスからの取り消しを入れる | :1459 に入っている。外れたら (5) の作りが変わる（もとからの条件） | G1 でよい |

### 見積もりの差分（範囲の6。単位は r2 と同じ「1人の作り手の日」。どれも［推測］）
- 冒頭の :6 と :11 の数字は、その2 の表と一致した。
- 足した作業の内訳
  - A「読み始める」と (5)：+0.76〜1.6日。実装 0.4〜0.85、G1 0.07〜0.15、G2 0.22〜0.45、G3 0.07〜0.15。中身は AC-130、AC-131、AC-132、AC-136、AC-41 の形、予約の決まり。
  - B ショートカット：+0.25〜0.5日。実装 0.1〜0.2、G1 0.03〜0.1、G2 0.1〜0.15、G3 0.02〜0.05。中身は AC-133〜AC-135 と、AC-123 の形の差し替え。
- 要る速さ（直しの前 → 直しのあと）

| どこまで回すか | 直しの前 | 直しのあと |
|---|---|---|
| 回さない | 2.46〜3.45倍 | 2.53〜3.59倍 |
| (課金) まで | 2.20〜3.07倍 | 2.26〜3.21倍 |
| (ショートカット) まで | 2.13〜2.94倍 | 2.18〜3.04倍 |
| (3) まで | 2.02〜2.80倍 | 2.07〜2.91倍 |
| (4) まで | 1.84〜2.57倍 | 1.89〜2.68倍 |
| (5)、(6) まで | 変わらない | 変わらない |

- G4-21（17回）と G4-22（12回）は G4 の作業で、3週の枠（G1〜G3）の外にある。増えるのは Takuma の時間。

### 開いた文書と原文
Apple の文書の JSON は、前の回の tech-lead と pdm が取ったものを使った。段落は自分で para.py で抜いた。
- https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities
  - "A Live Activity can be active for up to eight hours unless its app or a person ends it before this limit. After the eight-hour limit, the system automatically ends the Live Activity, and immediately removes it from the Dynamic Island. However, the Live Activity remains on the Lock Screen until a person removes it or for up to four additional hours before the system removes it — whichever comes first. As a result, a Live Activity remains on the Lock Screen for a maximum of 12 hours."
  - "The automatic removal depends on the dismissal policy you provide to the end(_:dismissalPolicy:) function."
  - "When a person or the system removes a Live Activity, its ActivityState changes to ActivityState.dismissed."
  - "At the specified date, the activityState changes to ActivityState.stale and isStale changes to true."
- https://developer.apple.com/documentation/activitykit/activity
  - "You can update or end a Live Activity while your app is in the background, but you can only start a Live Activity while the app is in the foreground, unless you adopt App Intents and start the Live Activity using a LiveActivityIntent."
- https://developer.apple.com/documentation/appintents/intentexecutiontargets （iOS 27.0）
  - "If you reuse intents and entities between your app, widget extension, or App Intents extension by using a Swift package or framework, the system may perform your AppIntent or EntityQuery from the app or App Intents extension. By default, the system performs an intent or entity query using any available target."
- https://developer.apple.com/documentation/uikit/uiapplication/isprotecteddataavailable
  - "The value of this property is false if data protection is enabled and the device is currently locked. The value of this property is set to true if the device is unlocked or if content protection is not enabled."
- https://support.apple.com/guide/security/data-protection-classes-secb010e978a/web （WebFetch）
  - "Shortly after the user locks a device (10 seconds, if the Require Password setting is Immediately)"
  - "This class behaves in the same way as Complete Protection, except that the decrypted class key isn't removed from memory when the device is locked or the user logged out."
  - "This is the default class for all third-party app data not otherwise assigned to a Data Protection class."
- https://developer.apple.com/design/human-interface-guidelines/live-activities
  - "On the Lock Screen, in the Mac menu bar, and the watchOS Smart Stack, it remains for up to four hours."
- https://support.apple.com/ja-jp/guide/iphone/iph14a867ae/ios と https://support.apple.com/guide/iphone/set-a-passcode-iph14a867ae/ios
  - 取れたが、「パスコードを要求」の記述はない。G4 の設定の名前は、PRD のとおり Takuma が実機で確かめる。

## 記録（指揮役が保存するときに書き足す）
- 種類：G0 の狭い判定 r2（tech-lead、実現性。裁定 21）。結果：PASS（重大0件、要修正3件、提案4件）
- 対象：docs/prd/001-reading-session.md と docs/prd/product.md。BASE=3e521dd55613eea68d1c59b3f122c6da3032bc88（直しの差分は 98e0200..3e521dd）
- 日付：2026-10-19
- 作業の材料（リポジトリの外。scratchpad）：g0-intents-tech-lead-r2/（notes.md、para.py、spike r2 の build-r2.log）。spike の端末は作っていない
