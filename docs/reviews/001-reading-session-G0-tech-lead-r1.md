FAIL

## 指摘
- 重大、docs/prd/001-reading-session.md:38-41 と docs/prd/product.md:41-45、競合の URL を1件も開けず、引用した不満がページにあるかを確かめられなかった。G0 の tech-lead の条件「競合の URL を1件以上開き、引用した不満がページにあるかを確かめる」を満たさない。この環境の外向きの通信は developer.apple.com と api.github.com しか通らない。apps.apple.com、itunes.apple.com、web.archive.org、appfollow、makeheadway、houselucia、applion、app-liv、justuseapp、appmatch は、どれも curl が CONNECT 403、WebFetch が ENOTFOUND か取得不可だった。検索の抜粋で照らした結果（ページは開いていない）は次のとおり。Bookly の「Full-page ads are ridiculous…」と「$30 a year…steep」は、justuseapp のページの抜粋に出ていた（PRD が出典にした apps.apple.com のページではない）。無料版の10冊の上限は bookriot などの抜粋と合う。「The free version is basically just a demo」は見つからなかった。Bookmory の「課金圧が強い」「入力に手間が掛かりすぎる」「ページ数を入れないと読めない」は2回検索しても見つからず、pdm も「どのページの文かは確かめていない」と書いている（001:39、product.md:42）。この Bookmory の引用は、E-5（001:28）、O-1 の根拠、4.3(b) の「Bookmory との違い」（001:47）を支えている。直す方向（どちらか）：(a) Takuma が、この環境から apps.apple.com、web.archive.org、applion.jp、makeheadway.com への接続を許す。G1 のために telemetrydeck.com と github.com/TelemetryDeck も許す。(b) Takuma が自分の端末で Bookly の App Store のレビューと applion の Bookmory のページを開き、該当の文をそのまま貼る。どちらでも確かめられない引用は、pdm が外すか［推測］に下げ、E-5 に頼る結論（O-1 を選んだ理由、Bookmory との違い）を書き直す。
- 要修正、docs/prd/001-reading-session.md:68、O-1 を選んだ理由が「［推測］」の1文だけで、根拠の E-2（スマホに時間を取られる）も E-5 も引いていない。「G0 の前の確認」の2つ目（［推測］だけで支えた結論がない）に触れる。直す方向：E-2 を引く。E-5 は確かめられた後にだけ引く。
- 要修正、docs/prd/001-reading-session.md:27、E-4 の「競合の不満の1位」の順位に根拠がない（2件のアプリの抜粋しかない）。「1位」を消すか、［推測］を付ける。
- 要修正、docs/prd/001-reading-session.md:85、6 の「実現性」の行の「今ある証拠（印）」が「なし。要確認」で印がない。この報告の AC の表（下の 1）を証拠として［公開情報 URL］で書き直す。
- 要修正、docs/prd/product.md:72、「同意の割合が27%と32%の例がある」の32%は、出典の https://developer.apple.com/forums/thread/735513 になかった（27%はあった。開いて確認）。32%を消すか、出典を足す。
- 要修正、docs/prd/001-reading-session.md:300、速さの3行に、数字はあるが測り方がない。基準の「iPhone 12 相当」は、どの最低 OS の一番遅い機種でもない（iOS 26 は iPhone 11 と SE 第2世代から、iOS 17 と 18 は XS と XR から。どちらも報道の抜粋で、apple.com は開けず未確認）。直す方向：起動は、Release ビルドを実機で測る。XCTApplicationLaunchMetric(waitUntilResponsive: true) で5回測った中央値を2.0秒以内とし、公開後は MetricKit の起動時間の p90 で見る。読み始めから0.5秒以内は、XCTOSSignpostMetric で操作から最初の表示までを測る。500冊と10,000件で1.0秒以内は、起動の設定で大きなデータを入れ、XCTClockMetric で測る。基準の機種は Takuma が持つ実機に合わせる（下の質問 Q4）。
- 要修正、docs/prd/001-reading-session.md:301、オフラインの行の「貯めて後で送るか捨て」が決まっていない。TelemetryDeck の SDK の動きを確かめられなかった（下の未検証）。G1 で tech-lead が決める項目として残し、決めるまでは「未定（理由）」と書く。
- 要修正、docs/prd/001-reading-session.md:331-342、15 の表は、こちらが送るプロパティの区分しか書いていない。SDK が自分で送るもの（端末ごとの ID、OS の版、機種など）がない。検索の抜粋では、TelemetryDeck の手引き（https://telemetrydeck.com/docs/articles/apple-app-privacy/ 、開けず未検証）は、既定の設定で「Device ID」と「Product Interaction」を集めるので、Device ID を Analytics として申告するよう書いている。Apple の分け方では、Device ID は「other device-level ID」も含む（https://developer.apple.com/app-store/app-privacy-details/ 、開いて確認）。直す方向：「SDK が自動で送るもの」の行を足し、「識別子：デバイス ID」を候補として置く。G1 で SDK のソースを見て決める。001 の指標（I-1、North Star）は利用者の ID がなくても数えられる。なので、端末ごとの ID を送らない設定にできるかを G1 で確かめる案を足す。
- 要修正、docs/prd/001-reading-session.md:272、AC-20 の確かめ方「ネットワークを切ったシミュレーター」は、公式の方法を見つけられなかった（シミュレーターは Mac のネットワークを使う。機内モードを切り替える API は developer.apple.com で見つからず、未確認）。直す方向：画面のテストでは、計測の送り先を必ず失敗するものに差し替え、通信のエラーの表示が0回であることを確かめる。G4 では、Takuma の実機を機内モードにして一度通す。
- 要修正、docs/prd/product.md:129 と 001:362-369、002 の「アプリを止める機能」には Family Controls の配布の許可が要ると確かめた。申請は Account Holder が行い、Screen Time の拡張（Device Activity Monitor、Shield Configuration など）にも同じ申請が要る。Apple が審査して承認する（https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement 、開いて確認）。承認までの日数は書かれていない。v1.0（2027-01-31）、Pro の中身、4.3(b) の手当ての3つともがこの承認に頼っているのに、承認されないときの代わりの案と判定日がない。直す方向：Takuma が早く申請する（Q3）。product.md の 10 か 13 に「2026-12-15 までに承認されなければ、v1.0 はアプリを止める機能なしで出し、Pro の中身を 003 と 004 で組み直す」のような行を足す。
- 要修正、docs/prd/product.md:69、I-3（引き戻されなかった読書の割合）は、そのままでは測れない。Screen Time の利用の報告の拡張は、通信も、データを拡張の外に出すこともできない（https://developer.apple.com/documentation/deviceactivity/deviceactivityreport 、開いて確認）。アプリが分かるのは、読書中に scenePhase が background になったことだけ。それが画面のロックか他のアプリへの切り替えかを区別する公式の方法は見つけていない（未確認）。002 の PRD で、測れる近い値（読書中に background にならなかった読書の割合）に定義し直す。
- 要修正（Takuma に伝える権限の項目）、.claude/org/app.json の commands.ios_build と ios_test が空。.github/workflows/ios.yml:43-45 は、ios/ ができた時点で失敗にするので、G2 を通れない。Mac のないこの環境では、iOS のビルドとテストは CI（macos-latest）でしか動かない。値は tech-lead が G1 で出し、Takuma が app.json に書く（Q5）。
- 提案、docs/prd/product.md:146、英語のサブタイトル「Quiet reading timer & book log」は、4.3(b) が名指しする「simple timers」を先頭に出している。「timer」を前に出さない言い方にする。
- 提案、4.3(b) の手当て（001 を単独で出さない）は筋が通っている。ただ、上位3件との違いの多くは「広告がない」「入力が少ない」という引き算で、ガイドラインの「meaningfully different or improved experience」を示す力は弱い。審査メモに、002（読書と Screen Time の遮断を結び付けたもの）と 003 の違いを書く準備を G5 の前に入れる。
- 提案、docs/prd/001-reading-session.md:124、9 の最後の行の「効く機会」が O-n でなく「当たり前」になっている。利用者にとって計測は「無関心」に近いので、「やらないと信頼を失う当たり前（害の手当て）」として 6 の害の行に結び付ける。
- 提案、docs/prd/001-reading-session.md:287、AC-23 の「計測が有効で」とあるが、9 に計測を切る設定がない。001 では切る画面を置かず、常に有効だと明記する（置くなら AC を足す）。
- 提案、docs/prd/001-reading-session.md:205 と 235、進み具合の%の丸め方が書いていない（299/300 が 99% か 100% か）。切り捨てと決める。AC-3 の「空白だけ」には全角の空白も含めると書く。
- 提案、docs/prd/001-reading-session.md:366、P-5 の上限 €2,700 は、Bold の Winner Package（€3,000〜、product.md:107 の抜粋）と応募料を足した額に届かない。どの段の受賞まで払うかの決まりを書く。
- 提案、時間の枠の2週（001:5）は、24 の AC があり、ビルドが CI だけで回る（指揮役が push するたびに macOS で動く）ことを考えると厳しい。削る順（性能の行から）は書いてあるので、G1 で日数を見直す。

## 証拠
- 対象：docs/prd/001-reading-session.md（コミット 53ae2fa）、docs/prd/product.md（同じ）。観点は G0 の tech-lead の行（docs/org/gates.md:32-35）。

### 1. AC ごとの実現性
前提：stacks は ios だけ、バックエンドなし。SwiftUI と SwiftData を使い、最低の OS は iOS 17 以上にする想定（G1 の ADR で決める）。下の API の存在と対応 OS は、developer.apple.com の各ページの .md の本文に入っている availability で確かめた（2026-10-21）。

API の一覧（A-n）：
- A1 SwiftData https://developer.apple.com/documentation/swiftdata iOS 17.0+
- A2 Query https://developer.apple.com/documentation/swiftdata/query iOS 17.0+
- A3 ModelContext.save()（throws） https://developer.apple.com/documentation/swiftdata/modelcontext/save() iOS 17.0+
- A4 ModelContext.autosaveEnabled https://developer.apple.com/documentation/swiftdata/modelcontext/autosaveenabled iOS 17.0+。本文：「The default value is false. SwiftData automatically sets this property to true for the model container's mainContext.」
- A5 ModelContext.rollback() https://developer.apple.com/documentation/swiftdata/modelcontext/rollback() iOS 17.0+
- A6 ModelContext.fetchCount(_:) https://developer.apple.com/documentation/swiftdata/modelcontext/fetchcount(_:) iOS 17.0+
- A7 ModelConfiguration（url、allowsSave、cloudKitDatabase） https://developer.apple.com/documentation/swiftdata/modelconfiguration iOS 17.0+
- A8 VersionedSchema と SchemaMigrationPlan https://developer.apple.com/documentation/swiftdata/versionedschema https://developer.apple.com/documentation/swiftdata/schemamigrationplan iOS 17.0+
- A9 #Index https://developer.apple.com/documentation/swiftdata/index(_:)-74ia2 iOS 18.0+
- A10 Observation https://developer.apple.com/documentation/observation iOS 17.0+
- A11 ContentUnavailableView https://developer.apple.com/documentation/swiftui/contentunavailableview iOS 17.0+
- A12 FocusState https://developer.apple.com/documentation/swiftui/focusstate iOS 15.0+
- A13 TimelineView https://developer.apple.com/documentation/swiftui/timelineview iOS 15.0+
- A14 Text(timerInterval:pauseTime:countsDown:showsHours:) https://developer.apple.com/documentation/swiftui/text/init(timerinterval:pausetime:countsdown:showshours:) iOS 16.0+
- A15 ScenePhase https://developer.apple.com/documentation/swiftui/scenephase iOS 14.0+
- A16 onOpenURL(perform:) https://developer.apple.com/documentation/swiftui/view/onopenurl(perform:) iOS 14.0+
- A17 confirmationDialog https://developer.apple.com/documentation/swiftui/view/confirmationdialog(_:ispresented:titlevisibility:actions:) iOS 16.0+
- A18 Calendar.dateInterval(of:for:) https://developer.apple.com/documentation/foundation/calendar/dateinterval(of:for:) iOS 10.0+。firstWeekday https://developer.apple.com/documentation/foundation/calendar/firstweekday iOS 8.0+
- A19 Duration.UnitsFormatStyle https://developer.apple.com/documentation/swift/duration/unitsformatstyle iOS 16.0+。DateComponentsFormatter https://developer.apple.com/documentation/foundation/datecomponentsformatter iOS 8.0+
- A20 accessibilityLabel(_:) https://developer.apple.com/documentation/swiftui/view/accessibilitylabel(_:)-1d7jv iOS 14.0+。DynamicTypeSize https://developer.apple.com/documentation/swiftui/dynamictypesize iOS 15.0+
- A21 UserDefaults https://developer.apple.com/documentation/foundation/userdefaults iOS 2.0+
- A22 XCUIApplication（launchArguments、launchEnvironment、terminate()、activate()、init(bundleIdentifier:)） https://developer.apple.com/documentation/xcuiautomation/xcuiapplication Xcode 16.3+（XCUIAutomation）
- A23 XCUIApplication.open(_:) https://developer.apple.com/documentation/xcuiautomation/xcuiapplication/open(_:) iOS 16.4+
- A24 XCUIDevice.press(_:) https://developer.apple.com/documentation/xcuiautomation/xcuidevice/press(_:)
- A25 isEnabled https://developer.apple.com/documentation/xcuiautomation/xcuielementattributes/isenabled
- A26 performAccessibilityAudit(for:_:) https://developer.apple.com/documentation/xcuiautomation/xcuiapplication/performaccessibilityaudit(for:_:) iOS 17.0+
- A27 XCTNSPredicateExpectation https://developer.apple.com/documentation/xctest/xctnspredicateexpectation
- A28 XCTApplicationLaunchMetric(waitUntilResponsive:) https://developer.apple.com/documentation/xctest/xctapplicationlaunchmetric/init(waituntilresponsive:) iOS 14.0+。XCTClockMetric と XCTOSSignpostMetric は iOS 13.0+
- A29 MXAppLaunchMetric https://developer.apple.com/documentation/metrickit/mxapplaunchmetric iOS 13.0〜27.2（終わりの版が付いている）。後継の TimeToFirstDrawMetric https://developer.apple.com/documentation/metrickit/timetofirstdrawmetric は iOS 27.0+
- A30 String Catalog https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog
- A31 iCloud のバックアップ https://developer.apple.com/documentation/foundation/optimizing-your-app-s-data-for-icloud-backup 。isExcludedFromBackup iOS 8.0+
- A32 ファイルの暗号化 https://developer.apple.com/documentation/uikit/encrypting-your-app-s-files
- A33 プライバシーマニフェスト https://developer.apple.com/documentation/bundleresources/privacy-manifest-files 。required reason API https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
- A34 isIdleTimerDisabled https://developer.apple.com/documentation/uikit/uiapplication/isidletimerdisabled

| AC | 判定 | 使う API | 難しさ | 懸念 |
|---|---|---|---|---|
| AC-1 | 今の構成で作れる | A1、A6、A11、A22、XCUIScreenshot | 低 | なし |
| AC-2 | 作れる | A1、A3（Book：title、totalPages: Int?、lastPage = 0） | 低 | なし |
| AC-3 | 作れる | A25、SwiftUI の disabled | 低 | 全角の空白も空白として扱うテストを入れる |
| AC-4 | 作れる | A12（題名の欄に最初から入力の印を置く）、A22 | 低 | 題名の欄を押すことが1回に数わるかを designer が決める |
| AC-5 | 作れる | A13 か A14、A27（sleep を使わず、表示が 0:02 になるのを待つ） | 低 | なし |
| AC-6 | 作れる | 時計を差し替えた単体テスト。経過＝今−開始−一時停止の合計 | 低 | なし |
| AC-7 | 作れる（テストのつなぎ口は G1） | A15、A13/A14、A22（activate）、A24（press(.home)）。時計のつなぎ口は A22 の launchEnvironment、または A16 と A23 | 中 | G3 は sleep を禁じるので、10分を本当に待てない。DEBUG のときだけ有効な時計の差し替えで、裏から戻ったときに時計を進める。1秒ずつ足す作りならこのテストで落ちるので、確かめる意味は残る |
| AC-8 | 作れる | 読書中の状態（本、開始の時刻、一時停止の合計、一時停止した時刻）を、状態が変わるたびに A1/A3 か A21 に保存する。A22（terminate と、時計を+5分進めた launchEnvironment） | 中 | 端末の時計（Date）で数える。単調な時計は再起動で0に戻り、systemUptime などは required reason API になる。利用者が時計を戻したら0で止め、長すぎる分は AC-12 で直す |
| AC-9 | 作れる | A1、A3 | 低 | %の丸めを決める（提案） |
| AC-10 | 作れる | A1 | 低 | なし |
| AC-11 | 作れる | 入力の確かめ | 低 | なし |
| AC-12 | 作れる | 分を選ぶ部品（1〜経過の分） | 低 | なし |
| AC-13 | 作れる | 59秒は記録しない | 低 | なし |
| AC-14 | 作れる | A1。合計時間、記録の数、最後のページを Book に持たせ、保存と削除のときに同じ処理の中で更新する | 低〜中 | 毎回 10,000 件を足すと 1.0 秒を超えるおそれがある。A9 の索引は iOS 18 以上 |
| AC-15 | 作れる（テストのつなぎ口は G1） | A18 | 中 | テストからシミュレーターの「週の始め」を変える公式の方法は見つけていない（未確認）。DEBUG のときだけ Calendar と時計を launchEnvironment で差し替える |
| AC-16 | 作れる | A17、A3 | 低 | 最後のページは変えない（PRD どおり） |
| AC-17 | 作れる | 読書中は1件だけという決まりを、保存の層で守る | 低 | なし |
| AC-18 | 未確認 | A7（保存先を Application Support に固定する）。再起動は Mac 側の `xcrun simctl shutdown` と `boot` を、2回の xcodebuild test の間に挟む | 中 | simctl の公式の文書ページを developer.apple.com で見つけられなかった。この環境に Mac がなく、spike もできない（Q5） |
| AC-19 | 作れる（つなぎ口は G1） | A3、A4、A5。DEBUG の起動の設定で、保存の層が save の前に失敗を投げる | 中 | mainContext は既定で自動の保存が有効（A4）。そのままだと、失敗させても後で勝手に保存される。自動の保存を切るか、失敗したら rollback する。allowsSave=false で save() が失敗するかは文書にない（A7、未確認）ので頼らない |
| AC-20 | 作れる（確かめ方を直す） | 通信は計測だけ。失敗する送り先に差し替える | 中 | 上の要修正（シミュレーターは機内モードにできない） |
| AC-21 | 作れる（動的な確かめ方の一部は未確認） | Info.plist に NS…UsageDescription と NSUserTrackingUsageDescription がないことを grep で見る。A22 の init(bundleIdentifier:) で SpringBoard の alerts.count が0であることを、各手順の後に見る。addUIInterruptionMonitor は付けない | 低〜中 | SpringBoard の bundle ID「com.apple.springboard」は慣例で、Apple の文書にはない（未確認。G2 で CI の出力で確かめる） |
| AC-22 | 作れる | 起動の設定で20冊を入れる。001 では StoreKit を入れない | 低 | なし |
| AC-23 | 作れる（本番の送り先の SDK は新しい依存で未確認） | 計測の送り先を protocol にし、本番（TelemetryDeck）とテスト用の記録係の2つの実装を持つ。イベントは区間の値だけを持つ型にし、題名やページの生の値を型として渡せなくする | 低 | SDK が自動で足すプロパティと、自動で送るイベントは未確認 |
| AC-24 | 作れる | A18、A21（送った週の始めの日付を持つ） | 低 | UserDefaults を使うなら、プライバシーマニフェストに理由を書く（A33。理由のコードは本文の .md になく未確認） |

### 2. 審査と権限で気になる点
- 4.3(b)：本文を開いて確かめた。「Certain kinds of apps, such as dating, flashlight, sound effects, wallpaper, simple timers, and fortune telling, are well established on the App Store and we will not accept new submissions unless they offer a meaningfully different or improved experience.」（https://developer.apple.com/app-store/review/guidelines/ ）。001 を単独で出さず、内部の TestFlight に留めるのは妥当。TestFlight の文書は、審査が要るのを外部のテスターの場合として書いている（「If you invite external testers, your beta build may require review.」 https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/ ）。内部だけなら審査がないとは明記されていないが、そう読める。手当てが足りるかは、002 と 003 の中身しだい（上の提案）。
- Family Controls（002）：配布の前に Account Holder の申請と Apple の承認が要る。拡張にも同じ申請が要る。開発中は申請なしでも使える（A35：https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.family-controls iOS 15.0+、requestAuthorization(for:) iOS 16.0+、https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement ）。002 では、システムの許可のダイアログが出る。
- TelemetryDeck の匿名 ID：Apple の定義（開いて確認）では、集める前に「direct identifiers」を取り除くか、「break the linkage and prevent re-linkage」の処理をし、集めた後に結び付け直さなければ「ユーザーと結び付けない」にできる。ただし、端末ごとの ID を送るなら、データの種類として「Device ID」の申告そのものは要る。TelemetryDeck が端末の上と自社のサーバーで二重にハッシュすることは検索の抜粋で見ただけ（未検証）。判断は G1 で SDK のソースと文書を開いてから行う。端末ごとの ID を送らない設定にできれば、申告は「使用状況データ」と「診断」だけで済む（未確認）。
- TelemetryDeck は Apple の「よく使われる第三者の SDK」の一覧になかった（https://developer.apple.com/support/third-party-SDK-requirements/ 、開いて確認）。それでも required reason API を使うかデータを集めるなら、SDK 自身のプライバシーマニフェストが要る（A33）。SDK に入っているかは未確認。
- 001 が使う権限は0個。トラッキングはしない（Apple の定義では、第三者のデータと広告のために結び付けていない）。ATT は不要。
- 提出の条件：2026-04-28 から Xcode 26 と iOS 26 SDK でビルドすること（https://developer.apple.com/news/upcoming-requirements/ 、開いて確認）。CI の macos-latest にどの Xcode が入っているかは未確認なので、G1 のコマンドで版を選ぶ。
- 5.1.1(i)：プライバシーポリシーへのリンクを App Store Connect とアプリの中に置く（開いて確認）。PRD の 17 と合う。

### 3. 利用者1,000人あたりの月の費用
- サーバー：0（バックエンドなし）。書誌 API：0（使わない）。クラッシュと性能：App Store Connect と MetricKit で0。
- 計測（TelemetryDeck）：1人が月約25〜30件（こちらのイベント。SDK が自動で送る分は未確認で、起動ごとに1件なら +30件）なので、1,000人で月3万〜6万件。2026年7月の改定後に新しく作るアカウントの無料枠は未確認。検索の抜粋では、既存の無料の利用者は月10万件のまま、新しい無料枠は「more limited」。有料の最小は €19/月という第三者の抜粋がある（古い可能性あり）。なので月 €0〜€19 程度（未確認、Q6）。
- Apple Developer Program：年 $99（「$99 annual membership」 https://developer.apple.com/programs/ 、開いて確認）。月にすると約 $8.25 の固定費で、利用者の数では増えない。円の価格は未確認。
- CI：リポジトリは public（api.github.com で visibility: public を確かめた）。GitHub が持つ macOS のランナーは public なら無料という一般の決まりだが、docs.github.com が開けず未確認。private にしたら分ごとに課金される。
- 合計：利用者1,000人あたり月 約 $8.25（固定費）＋計測 €0〜€19（未確認）。Red Dot の費用（応募料 €250〜€470、受賞したら €2,200〜。抜粋で未検証）は、利用者の数で増えない別の費用。手数料は Small Business Program で15%（「reduced commission rate of 15%」 https://developer.apple.com/app-store/small-business-program/ 、開いて確認）。

### 4. 非機能要件に無理がないか
- 速さ：作れる。データの数に対して保存の仕組み（A1、合計を本に持たせる）は足りる。測り方と基準の機種がない（要修正）。測る道具は A28 と A29。
- オフライン：画面は通信に頼らないので作れる。SDK が送れなかった分をどう扱うかは未確認。
- セキュリティとプライバシー：作れる。端末の中のファイルは、既定で「Complete until first user authentication」の保護がかかる（A32、開いて確認）。計測に出すのは区間の値だけ（AC-23）。直すこと：15 に SDK が自動で送る分を足す（要修正）。プライバシーマニフェストを用意する（A33）。cloudKitDatabase は既定で自動なので、iCloud の権限を付けないか、none を指定して、同期しないことを G1 の ADR に書く（A7）。
- アクセシビリティ：作れる。AX5（A20）、監査（A26、iOS 17 以上）。「12分30秒」の読み上げは A19 で作れるが、ja で出る文字の並び（空白が入るか）は未確認。テストは整形の結果と比べる。経過時間の表示を毎秒読み上げさせない作りが要る。
- 言語：String Catalog（A30）の各言語の状態（new、translated）を JSON から数えれば、そろっていないキーが0件かを Linux の CI でも確かめられる。
- 電池：A34 が false のまま、と確かめられる。数字はないが、ふるまいとして確かめられる。

### 5. 「G0 の前の確認」を自分で確かめた結果（印は信じていない）
| # | 項目 | 結果 | 証拠 |
|---|---|---|---|
| 1 | 3 にアプリ3件以上、アプリ以外1つ以上。アプリの行に URL と、引用か「不満の記録なし」 | 形は満たす（アプリ4件：001:38-41、アプリ以外2つ：001:42-43）。引用の実在は確かめられない（重大の指摘） | 下の 6 |
| 2 | 根拠のすべてに印。［推測］だけの結論がない。URL 3つ以上 | 一部満たさない（001:68、001:27、001:85、product.md:72）。URL は 001 に20個、product.md に45個 | grep の数え |
| 3 | Job が1つで、画面名や機能名がない | 満たす | 001:17 |
| 4 | 機会と解決案が3つ以上で、理由がある | 満たす（O-1〜O-4、S-1〜S-7） | 001:63-78 |
| 5 | 6 の全行と 7 の5行が埋まり、結び付け先がある | 満たす（6 の実現性の行に印がないのは要修正） | 001:81-98 |
| 6 | 8 に推奨、反論、作らない場合 | 満たす | 001:100-103 |
| 7 | 9 の全行に Kano と機会。無関心と逆効果がない | おおむね満たす（001:124 の機会が O-n でない。提案） | 001:111-124 |
| 8 | 10 のやらないことに理由がある | 満たす | 001:133-142 |
| 9 | 全 AC に Given、When、Then、確かめ方、効く機会があり、数字のない形容詞がない | 満たす（24/24/24/24/24/24。測れない言葉の grep は AC に0件）。ただし AC-20 の確かめ方は直す（要修正） | 下のコマンド |
| 10 | 13 にガードレール1つ以上、主が見かけの指標でない、全行に出典と判定日 | 満たす（主は I-1、ガードレール3つ）。Crash Rate は「Crashes divided by total sessions」、Day 35 Download to Paid Conversion の定義も開いて確かめた | https://developer.apple.com/help/app-store-connect-analytics/benchmarks/peer-group-benchmarks/ |
| 11 | 14 の全行に数値、日付、行動、pdm 以外の判定役 | 満たす（5行） | 001:322-328 |
| 12 | 15 の全イベントに区分 | 満たす（8/8）。SDK が自動で送る分がない（要修正） | 001:333-342 |
- 推奨といちばん強い反論：ある（001:101-103、product.md:34）。全 AC に効く機会：ある（24/24）。
- 根拠のうち開いて確かめたもの：E-7（4.3(b)）、3.1.2(a) の「ongoing value」、5.1.1(i)、Small Business Program の15%、peer group の指標の名前（数値は公開ページにない）、フォーラムの27%（32%はない）。E-1 の62.6%、47.3%、3,559人は検索の抜粋で合っていた（開いてはいない）。E-2 の43.6%は抜粋でも見つからなかった（未検証）。

### 6. 競合の URL を開いた結果
- 開けたもの：0件。
- 試して開けなかったもの（すべて 2026-10-21）：https://apps.apple.com/us/app/bookly-book-tracker/id1085047737?see-all=reviews （curl は CONNECT 403、WebFetch は ENOTFOUND）、https://itunes.apple.com/us/rss/customerreviews/id=1085047737/json （403）、https://web.archive.org/web/2026/https://apps.apple.com/us/app/bookly-book-tracker/id1085047737 （curl は 403、WebFetch は取得不可）、https://makeheadway.com/blog/bookly-app-review/ 、https://houselucia.com/book-tracking-apps-2026/ 、https://apps.appfollow.io/ios/bookly-book-tracker/1085047737?country=us 、https://applion.jp/Bookmory/iphone-1515533482/ 、https://app-liv.jp/9688/ 、https://justuseapp.com/en/app/1085047737/bookly-track-books-stats/problems 、https://appmatch.jp/866450515-2/ 、https://marlvel.ai/apps/flip-focus-timer-for-study/reviews 、https://tesukoume.com/recommended-reading-management-apps/ 、https://toolradar.com/tools/forest/pricing 、https://adapty.io/paywall-library/bookly/ （いずれも 403 か ENOTFOUND）。プロキシの状態のページも、拒まれた理由を connect_rejected と記録していた。
- 検索の抜粋で照らしたもの（開いていない。確かめたことには数えない）：Bookly の広告の引用は justuseapp のページの抜粋にある。10冊の上限は bookriot（https://bookriot.com/bookly-review/ ）などの抜粋と合う。「basically just a demo」は見つからない。Bookmory の3つの引用は見つからない。読書メーターの app-liv の文は抜粋にある（紹介記事の文で、利用者の不満ではない）。

### 7. pdm から確かめてほしいと言われた点への答え
- AC-7、AC-8、AC-18 の時刻の計算と保存：実現できる。読書中の状態を、状態が変わるたびに端末の時計の時刻で保存し、経過はその時刻から毎回計算する（1秒ずつ足さない）。表示は A13 か A14。強制終了と再起動の後は、保存した時刻から戻す。テストは DEBUG のときだけ有効な時計の差し替えで行う。AC-18 の再起動は simctl に頼るので未確認（Q5）。
- AC-19 の保存の失敗の起こし方：DEBUG のときだけ有効な起動の設定（例 `-UITest.failSaves`）で、保存の層が save() の前に失敗を投げる。mainContext の自動の保存（A4）を切り、失敗したら rollback（A5）する。読書中の状態は保存に失敗しても画面の中に残す。リリースのビルドには入れない（#if DEBUG）。
- AC-21 のシステムのアラートを0回と確かめる方法：(1) Info.plist に許可を求める説明のキーがない、コードに requestAuthorization などがない、を grep で見る（説明のキーがないと、カメラや写真などの許可は出せない）。(2) 各手順の後に SpringBoard の alerts.count が0であることを見る（API は A22。bundle ID は未確認）。割り込みを自動で閉じる仕組みは付けない。
- AC-23 の計測の送り先の差し替え：送り先を protocol にし、本番とテスト用の2つの実装を持つ（protocol を足す理由は、テストで中身を見るため）。テストはドメインの層で、本を足し、読み始め、終える流れを動かし、記録係が受け取った全プロパティの文字列に「坊っちゃん」と「72」がないことを見る。
- TelemetryDeck の匿名 ID と、2026年7月の改定後の無料枠：どちらも未確認（telemetrydeck.com も GitHub も開けない）。上の 2 と 3、Q6。
- 起動2.0秒の基準の機種：iPhone 12 には根拠がない。Takuma が持つ実機で測り、最低の OS が動く一番遅い機種に近いものを選ぶ（Q4）。
- 端末のバックアップに記録が入るか：入る。iCloud のバックアップが除くのは /tmp と /Library/Caches だけで、それ以外のアプリのデータは入る（A31。本文：「iCloud Backup excludes them by default」）。保存先を Application Support に固定すれば入る。isExcludedFromBackup は付けない。
- 002 の Family Controls の配布の許可：要る（上の 2）。Account Holder が、アプリと各拡張ごとに申請する。

### 未確認に付ける Takuma への質問
- Q1：競合のページを確かめる方法。推奨：この環境から apps.apple.com、web.archive.org、applion.jp、makeheadway.com、telemetrydeck.com、github.com/TelemetryDeck への接続を許す。反論：許す先が増える。元に戻せる。代わりの案：Takuma が Bookly の App Store のレビューと applion の Bookmory のページを開き、該当の文を貼る。
- Q2：Apple Developer Program に Account Holder として入っているか（内部の TestFlight、2026-11-30 の実機での7日、Family Controls の申請に要る）。
- Q3：Family Controls の配布の申請をいつ出すか。推奨：001 の G1 で bundle ID（アプリと拡張2つ）を決めたらすぐ（目安 2026-11-10）。反論：002 の設計の前に申請すると、説明が薄くなる。元に戻せる（申請は取り下げられる。未確認）。
- Q4：持っている iPhone の機種（起動2.0秒の基準と、G4 で実機で確かめるために使う）。
- Q5：app.json の commands（ios_build、ios_test）。G1 で tech-lead が値を出すので、Takuma が書く。あわせて、simctl の再起動を確かめる spike を CI で一度流してよいか。それが無理なら、Mac で `xcrun simctl help shutdown` と `xcrun simctl help boot` の出力を貼ってほしい。
- Q6：TelemetryDeck に新しく作るアカウントの無料枠（Q1 で接続が許されなければ、https://telemetrydeck.com/pricing/ の表を貼ってほしい）。月3万件に届かない場合は、送る数を間引くか、App Store Connect だけにする。

- 読んだファイル：docs/prd/001-reading-session.md、docs/prd/product.md、docs/templates/prd.md、docs/templates/review-report.md、docs/org/gates.md、docs/approvals/000-takuma-standing-approval.md、docs/progress.md、.claude/org/app.json、.claude/agents/tech-lead.md、contracts/dependencies.md（表は空）、CLAUDE.md、.github/workflows/ios.yml（読むだけ）。docs/adr/ は空。
- 実行したコマンドと結果：
  - `grep -cE '^- AC-[0-9]+：'` → 24。Given、When、Then、確かめ方、効く機会の数 → それぞれ 24。
  - 測れない言葉の grep（適切、すばやく、十分など） → AC には0件（001:83 の「十分」はリスクの前提の文で、合格の線がある）。
  - 15 のイベントの行 → 8。URL の数 → 001 に20、product.md に45。
  - curl で apps.apple.com、itunes.apple.com、red-dot.org、web.archive.org と、第三者のページ15件を試した → すべて 000（CONNECT 403）。github.com → 403（このセッションでは許されていない）。docs.github.com、bunka.go.jp → 000。developer.apple.com → 200。
  - `curl -sS "$HTTPS_PROXY/__agentproxy/status"` → 拒まれた理由は connect_rejected（ポリシーによる拒否）。
  - developer.apple.com の文書の .md を、スクラッチパッドのスクリプトで取得した → 上の A1〜A34 は 200 で、availability を確かめた。xcuiapplication/state と running-your-app-in-simulator-or-on-a-device は 404。
  - `curl https://api.github.com/repos/matsuura-tak/reading-app` → visibility: public。
  - spike：Mac も Xcode もないので、ビルドの spike はしていない。
- 開いた URL と確認した日付（2026-10-21）：https://developer.apple.com/app-store/review/guidelines/ 、https://developer.apple.com/app-store/app-privacy-details/ 、https://developer.apple.com/programs/ 、https://developer.apple.com/support/compare-memberships/ 、https://developer.apple.com/news/upcoming-requirements/ 、https://developer.apple.com/support/third-party-SDK-requirements/ 、https://developer.apple.com/help/app-store-connect-analytics/benchmarks/peer-group-benchmarks/ 、https://developer.apple.com/app-store/small-business-program/ 、https://developer.apple.com/forums/thread/735513 、https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/ 、上の A1〜A36 の文書。検索だけで開いていないもの：https://telemetrydeck.com/blog/pricing-update-2026/ 、https://telemetrydeck.com/docs/articles/apple-app-privacy/ 、https://telemetrydeck.com/docs/articles/anonymization-how-it-works/ 、https://justuseapp.com/en/app/1085047737/bookly-book-tracker/contact 、https://bookriot.com/bookly-review/ 、https://www.tckpublishing.com/bookly-app-review/ 、https://app-liv.jp/9688/ 、https://webtan.impress.co.jp/n/2024/09/20/47773 、https://9to5mac.com/2025/09/15/ios-26-supports-these-recent-iphones-but-drops-three-models/ 、https://www.techradar.com/phones/ios/ios-26-compatibility-does-your-iphone-support-it-heres-the-full-list-of-supported-devices 。
- 未検証：
  - 競合の引用すべて（上の 6）。
  - E-1 と E-2 の出典のページ（nippon.com、webtan、bunka.go.jp は開けない。43.6% は抜粋でも見つからない）。
  - Red Dot の要項、締切、費用（red-dot.org は 403）。
  - Apple ブックの読書目標のページ（support.apple.com は開けない）。
  - TelemetryDeck の価格、匿名 ID、SDK の API、プライバシーマニフェスト、送れなかったときの動き。
  - simctl の再起動、SpringBoard の bundle ID、シミュレーターのネットワークを切る方法、UI テストから週の始めを変える方法、allowsSave=false のときの save() の動き、Duration の ja の整形の結果。
  - 対応 OS ごとの機種の一覧（apple.com を開けない）。
  - GitHub の macOS ランナーの料金。
  - required reason API の理由のコード。

## 記録（指揮役）
- 関門：G0
- 判定した役：tech-lead
- 回：r1
- 対象：docs/prd/001-reading-session.md、docs/prd/product.md（ブランチ claude/cool-ptolemy-17gnb3、コミット 53ae2fa）
- 日付：2026-10-21
- 指揮役の扱い：重大1件は環境のネットワーク方針によるもので、PRD の直しでは解けない。docs/reviews/001-reading-session-G0-ruling.md に裁定を書き、Takuma に接続の許可を頼む。要修正は pdm に直させ、r2 を回す。
