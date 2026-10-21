PASS

## 指摘
- 重大：なし。
  - r1 の重大1件（競合の URL を開けない）は、裁定（docs/reviews/001-reading-session-G0-ruling.md:13）のとおり「未検証（環境のネットワーク方針）」として扱った。裁定の2も守られていた。開いていない引用はすべて［推測］と「（抜粋。ページは開いていない）」の印に下げてある。その引用に頼っていた結論（E-5、O-1 を選んだ理由、Bookmory との違い）は、I-1 の定義と 001 の AC で書き直してあった（下の追跡の1行目）。確かめていない引用が結論の支えに残っている箇所は見つからなかった。
  - r1 の要修正11件は、すべて直っていた。
- 新しい要修正と提案は、指示書に従って挙げない。G1 で扱う気づきは、証拠の表の「懸念」の列と「未検証」に書いた。
- PASS にした理由：review-report.md の形には「未検証が1つでもあれば PASS にしない」とある。一方 G0 の条件（docs/org/gates.md:35）は、「未確認」に spike の出力か Takuma への質問があればよい、としている。残る未検証は2種類だけ。(a) 裁定1で未検証にしたもの。(b) G1 で確かめるもの。(b) にはどれも Takuma への質問（P-9〜P-13）か代わりの案がある。代わりの案の例は、SDK を入れない案（001:440）、AC-40 は整形の出力に合わせる案（001:401）。代わりの案を取れば、どれも 001 を作れるかの判定は変わらない。この読み方が違うと指揮役が判断するなら、FAIL に読み替えてほしい。

## 前回の指摘の追跡
| 前回の指摘 | 直った / 直っていない / 裁定で未検証 | 証拠 |
|---|---|---|
| 重大：競合の URL を1件も開けず、引用を確かめられない | 裁定で未検証。裁定の2は守られている | 開いていない引用をすべて［推測］に下げた旨の注記：001:9、product.md:8、product.md:37。E-4 は［推測］：001:27。E-5 は［推測］で、Bookmory の引用は外した：001:28。Bookly の引用は［推測］：001:38。Bookmory は「不満の記録なし」：001:39、product.md:42。違いは 001 の AC で書き、競合の欠点は［推測］：001:45-49、product.md:58-62。O-1 の理由は I-1 の定義で書いた：001:69。不満の候補は「順位なし、結論の支えにしない」：product.md:50-53。PRD の確認欄も未チェックのまま理由がある：001:546 |
| 要修正1：O-1 を選んだ理由が［推測］1文だけ | 直った | 001:69。I-1 は「読み始める前に離れた人は数に入らない」という定義から理由を立てた。E-2 は引いているが、抜粋だけ［推測］と明記し、理由の支えにしていない |
| 要修正2：E-4 の「1位」に根拠がない | 直った | 001:27「順位は付けない」、product.md:50 |
| 要修正3：6 の実現性の行に印がない | 直った | 001:86。tech-lead r1 の表を引き、developer.apple.com の URL（開いて確認）を書いた。G1 の spike と合格の線もある |
| 要修正4：32% の出典がない | 直った | product.md:73 は 27% だけ。フォーラムを開き直して、27% だけで 32% がないことを確かめた（証拠の6） |
| 要修正5：速さの3行に測り方がない | 直った | 001:436-438。XCTApplicationLaunchMetric(waitUntilResponsive: true) で5回測った中央値、XCTOSSignpostMetric、XCTClockMetric。基準の機種は G1 の ADR で決める。P-11（001:519） |
| 要修正6：オフラインの「貯めるか捨てるか」が決まっていない | 直った | 001:439「未定（SDK の動きを G1 で…）。どちらでも画面には何も出さない」 |
| 要修正7：15 に SDK が自動で送るものがない | 直った | 001:488 に行を足した（候補の項目、識別子：デバイス ID の候補、G1 で確かめる）。001:476、001:491 |
| 要修正8：AC-20 の「ネットワークを切ったシミュレーター」 | 直った | 001:277-281。届かない先、500、30秒応答しない先の3通り。T6、T7。実機の機内モードは G4 |
| 要修正9：Family Controls の承認がないときの案と判定日がない | 直った | product.md:127、product.md:166（2026-12-15 の行）、product.md:133、001:518（P-10） |
| 要修正10：I-3 をそのままでは測れない | 直った | product.md:70、product.md:120（002 の PRD で測れる値に定義し直す） |
| 要修正11：app.json の commands が空 | 直った（PRD 側の手当て） | 001:520（P-12）。.claude/org/app.json の commands はまだ空で、G1 の後に Takuma が書く段取り |
| 提案1：英語のサブタイトルが「timer」を前に出している | 直った | product.md:152「Phone down, quiet reading log」（29字）、product.md:155 |
| 提案2：審査メモに 002 と 003 の違いを書く | 直った | 001:49、001:497、product.md:62 |
| 提案3：9 の最後の行の機会 | 直った | 001:126「害の手当て（6 の害の行）」 |
| 提案4：AC-23 の「計測が有効で」 | 直った | 001:296 から消した。001:111、001:144 に「計測は常に有効」と書いた |
| 提案5：% の丸めと全角の空白 | 直った | 001:157（切り捨て、秒で足してから分）、001:176（U+3000、改行、タブ）、001:334（16% の例） |
| 提案6：P-5 の上限と払う段 | 直った | 001:513、product.md:114。Latecomer €470＋Regular €2,200＝€2,670 で、上限 €2,700 に収まる |
| 提案7：時間の枠の2週 | 直った | 001:5（3週。理由あり）、product.md:125 |

## 証拠
- 対象：docs/prd/001-reading-session.md、docs/prd/product.md（コミット a4a3f43、HEAD＝a4a3f438c120d583aa253b447edd16fa931b5ca0）。`git diff --stat 53ae2fa..a4a3f43 -- docs/prd/` → 001 は +312/-151 行の一部、product.md は 106 行が変わった。どちらも全文を読んだ。
- 観点：G0 の tech-lead の行（docs/org/gates.md:32-35）と、裁定の1と2。

### 1. 新しい AC-25〜AC-45 の実現性
前提は r1 と同じ。iOS だけで、SwiftUI と SwiftData、最低の OS は iOS 17 以上の想定（G1 の ADR で決める）。A1〜A35 は r1 の一覧（docs/reviews/001-reading-session-G0-tech-lead-r1.md:30-64）。

足した API。存在と対応 OS は developer.apple.com の各ページの .md の availability で確かめた（2026-10-21、すべて 200）。
- A40 FetchDescriptor（sortBy、fetchLimit）iOS 17.0+ https://developer.apple.com/documentation/swiftdata/fetchdescriptor
- A41 ModelContext.delete(_:) iOS 17.0+ https://developer.apple.com/documentation/swiftdata/modelcontext/delete(_:)
- A42 XCUIElementAttributes の label と identifier、Xcode 16.3+ https://developer.apple.com/documentation/xcuiautomation/xcuielementattributes/label
- A43 Calendar.timeZone iOS 8.0+ https://developer.apple.com/documentation/foundation/calendar/timezone
- A44 DateComponentsFormatter.UnitsStyle.full iOS 8.0+ https://developer.apple.com/documentation/foundation/datecomponentsformatter/unitsstyle-swift.enum/full
- A45 ButtonRole.cancel iOS 15.0+ https://developer.apple.com/documentation/swiftui/buttonrole/cancel
- A46 String Catalog の状態。本文：「When you add a translation, the state changes from new to translated」 https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog
- A47 NWListener iOS 12.0+ https://developer.apple.com/documentation/network/nwlistener
- A48 NSAllowsLocalNetworking。本文：「In iOS 17, iPadOS 17, and macOS 14, ATS no longer allows connections to IP addresses by default.」。unqualified domain（localhost など）は iOS 10 から既定で許される。https://developer.apple.com/documentation/bundleresources/information-property-list/nsapptransportsecurity/nsallowslocalnetworking
- A49 TN3179。本文：「The simulator doesn't support local network privacy.」 https://developer.apple.com/documentation/technotes/tn3179-understanding-local-network-privacy
- A50 XCTOSSignpostMetric の init(subsystem:category:name:) iOS 13.0+。クラスそのものは非推奨ではない。Deprecated の節にあるのは applicationLaunch などの class var だけ。https://developer.apple.com/documentation/xctest/xctossignpostmetric
- A51 MXAppLaunchMetric は「iOS: 13.0.0 - 27.2.0」、TimeToFirstDrawMetric は iOS 27.0+（開き直して確かめた）
- A52 Xcode Organizer。本文：「view anonymized performance data from your app's users, including launch times」 https://developer.apple.com/documentation/xcode/analyzing-the-performance-of-your-shipping-app
- A53 simctl の boot と shutdown。WWDC19 418 の書き起こし：「Boot as you might expect boots a device. Shutdown also pretty obvious; it shuts down the device.」 https://developer.apple.com/videos/play/wwdc2019/418/
- A54 XCUIAccessibilityAuditType.contrast iOS 17.0+ https://developer.apple.com/documentation/xcuiautomation/xcuiaccessibilityaudittype/contrast
- A55 XCUIApplication.open(_:)（A23 を開き直した）。本文：「Launches the application by URL.」 iOS 16.4+

| AC | 判定 | 使う API | 難しさ | 懸念 |
|---|---|---|---|---|
| AC-25 | 作れる | A1、A40（記録の保存の時刻で降順、1件）、T2、T3 | 低 | 記録に「保存した時刻」を持たせる（読書の開始の時刻とは別） |
| AC-26 | 作れる | A1、A40（本の追加の時刻で降順） | 低 | 本に追加の時刻を持たせる |
| AC-27 | 作れる | A2、SwiftUI の条件分岐 | 低 | なし |
| AC-28 | 作れる | A2（総ページ数が nil なら book.progress を置かない） | 低 | なし |
| AC-29 | 作れる | 計算（読んだページ＝max(0, 新−前)） | 低 | % は整数の割り算で切り捨てる（50×100÷300＝16）。浮動小数の誤差を避ける |
| AC-30 | 作れる | 入力の確かめ | 低 | 上限の「経過の分数」は、終えた時刻で止めた経過（AC-45）から出す |
| AC-31 | 作れる | 入力の確かめ、A25 | 低 | 数字以外を貼り付けたときの扱いは、G1 で designer と決める |
| AC-32 | 作れる | 入力の確かめ | 低 | なし |
| AC-33 | 作れる | A1 と A3 か A21（paused、一時停止した時刻、止めていた合計を保存）、A22（terminate と launchEnvironment で時計を5分進める） | 中 | AC-8 と同じつなぎ口。経過＝一時停止した時刻−開始−止めていた合計 |
| AC-34 | 作れる | 同上（finishing と終えた時刻を保存） | 中 | ページの下書きは保存しない（Then が「空」） |
| AC-35 | 作れる | A3、A5、T5（N 回だけ失敗） | 中 | 失敗のたびに rollback し、再試行で入れ直して保存する。入れたまま残すと、自動の保存（A4）で後から保存され、記録が二重になるおそれ |
| AC-36 | 作れる | A18、A2 | 低 | なし |
| AC-37 | 作れる | A11 か独自の空の表示、A25 | 低 | なし |
| AC-38 | 作れる | A17、A45 | 低 | なし |
| AC-39 | 作れる（数え方の細部は G1） | A30、A46 | 低 | 走らせる場所は ios_test の中（macOS の CI）。Linux の CI で走らせるには .github の変更が要り、それは Takuma だけ。元の言語の値と複数形（variations）を数えるかは G1 で決める |
| AC-40 | 作れる（整形の出力は未確認） | A20、A42（label で読む）、A44 か A19、A13 | 低〜中 | ja の出力に空白が入るか（「12分30秒」か「12 分 30 秒」か）は、Mac がなく動かせていない。PRD の確かめ方（001:401）のとおり、整形の出力を design/ の文言表に写す。読み上げの文は、表示と同じ時刻から TimelineView の中で作る |
| AC-41 | 作れる | T3、max(0, 今−開始−止めていた合計) | 低 | r1 の「端末の時計（Date）で数える」と合う |
| AC-42 | 作れる | T5（book_add）、A5 | 低 | 失敗したら rollback し、入力は画面の状態に残す |
| AC-43 | 作れる | T5（session_delete）、A41、A5 | 中 | save に失敗した後に rollback しないと、一覧から消えたままに見え（未確認）、自動の保存（A4）で後から本当に消えるおそれ |
| AC-44 | 作れる | A18、A43、firstWeekday、T3、T4 | 中 | 「土曜 23:50」は時間帯で変わる。T4 に時間帯（例 Asia/Tokyo）を足す。CI のシミュレーターの時間帯は未確認 |
| AC-45 | 作れる | 終えた時刻を保存する（AC-34 と同じ） | 低 | なし |

r2 で変わった AC-1〜24 で、作り方に関わるもの：
- AC-5（001:190）：作れる。ただし「操作から0.5秒以内に 0:00 か 0:01」を実時間で見ると、UI テストの問い合わせの遅れで結果が揺れる。T3 で時計を止めて 0:00 を見る形にし、0.5秒の線は 12 の XCTOSSignpostMetric（A50）で測ると安定する（verifier への申し送り）。
- AC-6、AC-23、AC-24（画面のテストに変えた）：作れる。T3 と T6 は G1 で contracts/ に書く。
- AC-20、AC-23、AC-24 の受け口：作れる見込み。UI テストの実行側で、A47 で localhost の受け口を立て、500 と30秒の無応答も返す。127.0.0.1 は iOS 17 から ATS の既定で拒まれる（A48）ので localhost を使う。シミュレーターは Local Network の許可を扱わない（A49）ので、AC-21 のダイアログは出ない。アプリから実際に届くかは spike をしておらず未確認。SDK の送り先をこの受け口に向けられるかも未確認（SDK のページを開けない）。向けられなければ、001:440 の「SDK を入れない」案にする。
- AC-18：simctl の boot と shutdown が存在することは A53 で確かめた（r1 では未確認だった）。CI で動かすことはまだしていない（下の未検証）。
- まとめ：45件中44件が「作れる」。AC-18 だけ、確かめ方を CI でまだ動かしていない。r1 から変わった AC で、作れなくなったものはない。

### 2. 審査と権限で気になる点（r1 からの変化だけ）
- 001 の権限は0個のまま。テスト用の localhost の受け口は DEBUG だけで使う。Release では接続しないので、Local Network の許可は求めない（A49 はシミュレーターについての文。実機の Release はそもそも接続しない）。
- 4.3(b) と Family Controls の扱いは r1 と同じ。product.md:166 の判定日で、承認されないときの道筋もできた。
- 提出の条件：「Since April 28, 2026 Apps uploaded to App Store Connect must be built with Xcode 26 or later using an SDK for iOS 26」（https://developer.apple.com/news/upcoming-requirements/ を開き直して確認）。それより新しい Xcode の条件はページになかった。

### 3. 利用者1,000人あたりの月の費用（変更なし）
- サーバー 0。書誌 API 0。クラッシュと性能は App Store Connect と Xcode Organizer（A52）で 0。
- 計測（TelemetryDeck）：月3万〜6万件。新しいアカウントの無料枠は、2026-10-21 に検索し直しても抜粋に出ず、未確認。既存の無料の利用者は月10万件のまま（抜粋）。なので €0〜€19 程度（未確認）。001 で SDK を入れない案（001:440）になれば、003 まで 0。
- Apple Developer Program：年 $99（月約 $8.25。r1 で開いて確認）。
- 合計：利用者1,000人あたり、月 約 $8.25（固定）＋計測 €0〜€19（未確認）。r1 から変わらない。
- 別枠（利用者の数で増えない）：Red Dot。product.md:108 の「オンラインの受賞者ページは追加で €950」が必須なら、P-5 の上限 €2,700 を超える。抜粋では必須か読めない（未検証。G5 の前に pdm が要項で確かめる段取りがある：product.md:101）。

### 4. 非機能要件に無理がないか
- 速さ（001:436-438）：無理はない。3行とも数字と道具がそろった（A28、A50、XCTClockMetric）。G1 に渡すこと：
  - (1) 0.5秒と1.0秒の行には、測る機種とビルドが書いていない。設計メモの6で、起動の行と同じ「G4 の実機、Release」にそろえる。CI のシミュレーターの値は参考にとどめる。
  - (2) 実機で XCTest の性能テストを動かすには、Mac と Xcode につないだ実機が要る［推測］。Takuma が Mac を持っているかは未確認。
  - (3) 公開後の p90：MetricKit の値は端末に届くだけ。見るには、アプリから送る（プライバシー表示に「診断：パフォーマンスデータ」が増える）か、Organizer の起動時間（A52、匿名）を使う。Organizer で p90 が見えるかは未確認。最低の OS を iOS 17 にするなら、MXAppLaunchMetric（〜27.2）と TimeToFirstDrawMetric（27.0+）の両方が要る（A51）。
- オフライン（001:439）：無理はない。画面は通信に頼らない。AC-20 は「画面に何も出さない」ことだけを求めるので、SDK が送れなかった分を貯めても捨てても満たせる。
- プライバシーの表の SDK の行（001:488）：無理はない。候補の列挙、「端末ごとの ID を送らない設定にできるか」、どちらも G1 で確かめる。確かめられなければ SDK を入れない案（001:440、product.md:146）がある。ただし、候補の列（ID、OS の版、機種、アプリの版、時刻）が全部かどうかは未確認。G1 では SDK のソースから既定で送る項目をすべて並べ、Apple の区分（Device ID は「or other device-level ID」を含む。https://developer.apple.com/app-store/app-privacy-details/ を開き直して確認）に1つずつ当てる。この環境からは SDK のソースも読めない（下の未検証）。
- テストのつなぎ口を Release で働かせないこと（001:441）、アクセシビリティ（001:442-446。コントラストは A54 で監査できる）、電池（001:448）、前の版からの更新（001:449）：どれも無理はない。

### 5. 「G0 の前の確認」を自分で確かめた結果（印は信じていない）
| # | 項目 | 結果 | 証拠 |
|---|---|---|---|
| 1 | 3 にアプリ3件以上、アプリ以外1つ以上。アプリの行に URL と、引用か「不満の記録なし」 | 満たす（形）。アプリ4件、アプリ以外2つ。引用が本当にページにあるかは裁定で未検証 | 001:38-43 |
| 2 | 根拠のすべてに印。［推測］だけの結論がない。URL 3つ以上 | 満たす（裁定の範囲で）。URL があって印がない行は001:521 の1行だけで、これは P-13 で確かめる先で根拠ではない。URL は 001 に28個、product.md に46個（重複を除く）。O-1、4.3(b) の違い、実現性の行は、定義、AC、開いた URL で支えている。product.md:34 の推奨 A は抜粋と［推測］が中心だと自分で書き、確かめる線（14 の実機の7日、13 の週の読書者数）を置いている | 001:69、001:45-49、001:86、product.md:34 |
| 3 | Job が1つで、画面名や機能名がない | 満たす | 001:17 |
| 4 | 機会と解決案が3つ以上で、理由がある | 満たす（O-1〜O-4、S-1〜S-7） | 001:64-79 |
| 5 | 6 の全行と 7 の5行が埋まり、結び付け先がある | 満たす | 001:82-88、001:93-99 |
| 6 | 8 に推奨、反論、作らない場合 | 満たす | 001:101-104 |
| 7 | 9 の全行に Kano と機会。無関心と逆効果がない | 満たす（12行） | 001:113-126 |
| 8 | 10 のやらないことに理由がある | 満たす（10項目） | 001:135-145 |
| 9 | 全 AC に Given、When、Then、確かめ方、効く機会。数字のない形容詞がない | 満たす（45/45/45/45/45/45。測れない言葉は0件） | 下のコマンド |
| 10 | 13 にガードレール1つ以上、主が見かけの指標でない、全行に出典と判定日 | 満たす（主は I-1、ガードレール3つ、判定日の読み替えの決まりあり） | 001:454-462 |
| 11 | 14 の全行に数値、日付、行動、pdm 以外の判定役 | 満たす（5行） | 001:467-473 |
| 12 | 15 の全イベントに区分 | 満たす（8イベント＋SDK の行） | 001:478-488 |
| （13） | 競合の URL を1件以上開いた（gates.md:33） | 裁定で未検証。今回は試していない（指示書） | 001:546、裁定1 |

### 6. 読んだファイル、実行したコマンド、開いた URL
- 読んだファイル：docs/prd/001-reading-session.md（全546行）、docs/prd/product.md（全169行）、docs/reviews/001-reading-session-G0-tech-lead-r1.md、docs/reviews/001-reading-session-G0-verifier-r1.md、docs/reviews/001-reading-session-G0-ruling.md、docs/org/gates.md、docs/templates/review-report.md、docs/templates/prd.md（137-150）、docs/progress.md、docs/approvals/000-takuma-standing-approval.md、.claude/agents/tech-lead.md、.claude/org/app.json（commands は3つとも空）、.github/workflows/ios.yml と org-check.yml（読むだけ）、contracts/dependencies.md（表は空）。docs/adr/ と design/ は空。
- 実行したコマンドと結果：
  - `git log --oneline`、`git diff --stat 53ae2fa..a4a3f43 -- docs/prd/` → 変わったのは PRD の2ファイルだけ。
  - `grep -cE '^- AC-[0-9]+：'` → 45。番号は1〜45で抜けなし。11 を切り出して、Given、When、Then、確かめ方、効く機会の数を数えた → どれも45。
  - 測れない言葉の grep（verifier r1 と同じパターン）→ 11 で0件、ファイル全体でも0件。
  - URL の数（重複を除く）→ 001 に28、product.md に46。URL があって印がない行 → 001:521 だけ。
  - 15 の行 → 9（8イベント＋SDK）。13 → 4行。14 → 5行。
  - developer.apple.com の .md を、スクラッチパッドのスクリプトで取得 → A40〜A55 は 200 で、availability を確かめた。accessibilityValue は推した URL が 404 で、使っていない。
  - `curl https://api.github.com/repos/TelemetryDeck/SwiftSDK` → 403「GitHub access to this repository is not enabled for this session」。この環境の api.github.com は、このリポジトリだけ。権限を広げる操作はしていない。
  - spike：Mac も Xcode もないので、ビルドの spike はしていない。
- 開いた URL と確認した日付（2026-10-21）：
  - https://developer.apple.com/forums/thread/735513 （WebFetch。「27% of all users ... agreed to share their data」。数字は 27% だけ）
  - https://developer.apple.com/news/upcoming-requirements/
  - https://developer.apple.com/app-store/app-privacy-details/
  - https://developer.apple.com/videos/play/wwdc2019/418/
  - 上の A40〜A55 の文書
- 検索だけで、ページは開いていないもの：
  - TelemetryDeck の料金：https://telemetrydeck.com/blog/pricing-update-2026/ 。新しいアカウントの枠は抜粋になかった。
  - SpringBoard の使い方：https://developer.apple.com/forums/thread/15971 、https://developer.apple.com/forums/thread/701473 。利用者の投稿で、公式の文書ではない。

### 7. 未検証
(a) 裁定で未検証にしたもの（環境のネットワーク方針。裁定の3で、接続が許されたら G1 の間に、遅くとも G5 の前に確かめる）
- 競合の引用すべて（Bookly、読書メーター、Forest、伏せるタイマー、ブクログ）。競合の評価の数と価格（E-3、product.md の 5 と 8）。
- E-1 と E-2 の出典のページ（nippon.com、webtan、二次資料の PDF）。
- Red Dot の要項、締切、費用。受賞者ページの €950 が必須かどうかも含む。
- Apple ブックの読書目標のページ。

(b) G1 で確かめるもの（どれも代わりの案か Takuma への質問がある）
- TelemetryDeck：新しいアカウントの無料枠（P-13）。SDK が既定で送る項目と端末の ID。送り先の URL を受け口に向けられるか（T6）。送れないときに貯めるか捨てるか。SDK のプライバシーマニフェスト。telemetrydeck.com、github.com、api.github.com のほかのリポジトリは、どれも開けない。代わりの案：001 では SDK を入れない（001:440）。
- AC-18 の simctl の再起動を CI で動かせるか。コマンドが存在することは A53 で確かめた。CI で流すには、次の2つが先に要る：P-12（Takuma が app.json の commands を書く）と、ios/ を含むブランチの PR（ios.yml:43-45 は、ios/ があって commands.ios_test が空なら失敗する）。「spike はリポジトリの外」の決まりとの折り合いは G1 で決める（案：使い捨てのブランチで PR を出し、終わったら消す）。CI で動かなければ、アプリの終了と起動し直しで確かめ、端末の再起動は G4 で人が確かめる。
- SpringBoard の bundle ID（AC-21）。公式の文書はない。主な確かめは、Info.plist に UsageDescription のキーがないかを見る静的な確かめにする。
- AC-40 の整形の出力（ja と en の実際の文字列）。
- localhost の受け口（A47〜A49）に、アプリから実際に届くか。
- String Catalog で「translated」を数えるとき、元の言語の値と複数形をどう数えるか（AC-39）。
- 最低の OS、基準の機種（P-11）、MetricKit の新旧の使い分け、Organizer で p90 が見えるか。
- GitHub の macOS ランナーの料金（public なら無料という一般の決まり。docs.github.com は開けない）。UserDefaults の required reason API の理由のコード。

(c) Takuma の返事か操作が要るもの（包括承認では代われない。1通にまとめて頼む案）
- P-9（Developer Program への加入）、P-10（Family Controls の申請）、P-11（持っている iPhone の機種）、P-12（app.json の commands を書く）、P-13（料金表を貼る）、裁定の3（ネットワークの許可）。
- 足してほしい質問：Takuma は Mac と Xcode を持っているか。12 の起動の測定を実機で行い、AC-40 の整形の出力を確かめるのに使う。推奨：持っていれば G4 で使う。持っていなければ、起動は CI のシミュレーターの値を参考にし、公開後は Organizer で見る。いちばん強い反論：実機の数字が公開まで出ない。元に戻せる。

## 記録（指揮役）
- 関門：G0
- 判定した役：tech-lead
- 回：r2
- 対象：docs/prd/001-reading-session.md、docs/prd/product.md（コミット a4a3f43）
- 日付：2026-10-21
- 指揮役の判断：PASS の読み方（docs/org/gates.md:35「未確認には spike の出力か Takuma への質問がある」）に同意する。未検証 (a) は裁定、(b) は G1 の確かめと代わりの案、(c) は Takuma への1通にまとめる。
