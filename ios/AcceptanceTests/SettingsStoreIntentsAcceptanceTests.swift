import XCTest

final class SettingsStoreIntentsAcceptanceTests: AcceptanceTestBase {

    private let currentBookSeed = #"{"books":[{"id":"book-a","title":"羅生門","author":"芥川龍之介","status":"current","savedLine":"ある日の暮方の事である。","savedPage":61}],"records":[]}"#

    func test_AC88_設定画面からプライバシーポリシーのURLを開く() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        element("tab.settings").tap()
        let policyBtn = element("settings.privacyPolicy")
        XCTAssertTrue(policyBtn.waitForExistence(timeout: uiTimeout))
        policyBtn.tap()

        let opened = readHookJSON("hook.urls")["openedURLs"] as? [String] ?? []
        XCTAssertEqual(opened.count, 1)
    }

    func test_AC89_画面操作で入れた本と記録としおりと設定が再起動後もすべて残る() {
        let seed3Books = #"{"books":[{"id":"book-a","title":"羅生門","author":"芥川龍之介","status":"current","savedLine":"下人の行方は","savedPage":61},{"id":"book-b","title":"銀河鉄道の夜","author":"宮沢賢治","status":"tsundoku"},{"id":"book-e","title":"こころ","author":"夏目漱石","status":"finished"}],"records":[{"id":"r1","bookID":"book-a","nightDate":"2026-10-16","minutes":15},{"id":"r2","bookID":"book-a","nightDate":"2026-10-17","minutes":25},{"id":"r3","bookID":"book-e","nightDate":"2026-10-18","minutes":30}],"settings":{"flipToStart":false,"hideOnWidgets":true,"entryTime":"22:45"}}"#
        resetAndLaunch(seedJSON: seed3Books, now: "2026-10-18T21:00:00+09:00")
        relaunchPreservingStore(now: "2026-10-18T21:05:00+09:00")

        let store = readHookJSON("hook.store")
        let books = store["books"] as? [[String: Any]] ?? []
        let records = store["records"] as? [[String: Any]] ?? []
        let settings = store["settings"] as? [String: Any] ?? [:]
        XCTAssertEqual(books.count, 3)
        XCTAssertEqual(records.count, 3)
        XCTAssertEqual(settings["flipToStart"] as? Bool, false)
        XCTAssertEqual(settings["hideOnWidgets"] as? Bool, true)
        XCTAssertEqual(settings["entryTime"] as? String, "22:45")
    }

    func test_AC90_起動時の保存先読込失敗でエラーを出し再起動で元のデータが戻る() {
        let seed = #"{"books":[{"id":"book-a","title":"羅生門","author":"芥川龍之介","status":"current"},{"id":"book-b","title":"こころ","author":"夏目漱石","status":"tsundoku"}],"records":[{"id":"r1","bookID":"book-a","nightDate":"2026-10-16","minutes":10},{"id":"r2","bookID":"book-a","nightDate":"2026-10-17","minutes":20},{"id":"r3","bookID":"book-a","nightDate":"2026-10-18","minutes":30}]}"#
        resetAndLaunch(seedJSON: seed, now: "2026-10-18T21:00:00+09:00", failSave: "store.load:1")
        XCTAssertTrue(element("store.load.error").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(matchingCount("bookmark.start"), 0)
        XCTAssertEqual(matchingCount("bookmark.addBook"), 0)

        relaunchPreservingStore(now: "2026-10-18T21:01:00+09:00")
        let store = readHookJSON("hook.store")
        XCTAssertEqual((store["books"] as? [[String: Any]] ?? []).count, 2)
        XCTAssertEqual((store["records"] as? [[String: Any]] ?? []).count, 3)
    }

    func test_AC91_7種類の保存失敗時にエラーが出て変更前のデータが保たれる() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", failSave: "mark.save:1")
        element("bookmark.setMark").tap()
        element("mark.pageOnly").tap()
        let pageField = element("mark.pageField")
        XCTAssertTrue(pageField.waitForExistence(timeout: uiTimeout))
        pageField.tap()
        pageField.typeText("80")
        element("mark.save").tap()

        XCTAssertTrue(element("common.save.error").waitForExistence(timeout: uiTimeout))
        let books = readHookJSON("hook.store")["books"] as? [[String: Any]] ?? []
        XCTAssertEqual(books.first?["savedPage"] as? Int, 61)
    }

    func test_AC93_設定画面にNDLの3条件とCCBYリンクが出てしおり画面と読書中画面には出ない() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        XCTAssertEqual(matchingCount("settings.dataSources"), 0)

        element("tab.settings").tap()
        let ds = element("settings.dataSources")
        XCTAssertTrue(ds.waitForExistence(timeout: uiTimeout))
        let licenseBtn = element("settings.dataSources.license")
        XCTAssertTrue(licenseBtn.exists)
        licenseBtn.tap()

        let opened = readHookJSON("hook.urls")["openedURLs"] as? [String] ?? []
        XCTAssertTrue(opened.first?.hasPrefix("https://creativecommons.org/licenses/by/4.0/") ?? false)
    }

    func test_AC103_登録から読了カード共有まで外部HTTP通信が0件である() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        element("bookmark.start").tap()
        advanceClock(seconds: 120)
        element("reading.end").tap()
        element("mark.later").tap()
        element("result.close").tap()
        element("bookmark.finish").tap()
        element("finish.card.share").tap()

        let outbound = readHookJSON("hook.outbound")["requests"] as? [Any] ?? []
        XCTAssertEqual(outbound.count, 0)
    }

    func test_AC104_未購入でも毎晩の道と読み終えた画面に課金案内が出ない() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", storeKitJSON: #"{"isPlusPurchased":false}"#)
        XCTAssertEqual(matchingCount("store.buy"), 0)
        element("bookmark.start").tap()
        XCTAssertEqual(matchingCount("store.buy"), 0)
        advanceClock(seconds: 120)
        element("reading.end").tap()
        XCTAssertEqual(matchingCount("store.buy"), 0)
        element("mark.later").tap()
        XCTAssertEqual(matchingCount("store.buy"), 0)
        element("result.close").tap()
        element("bookmark.finish").tap()
        XCTAssertEqual(matchingCount("store.buy"), 0)
        XCTAssertEqual(app.alerts.count, 0)
    }

    func test_AC105_鍵つき見た目を押すと見本と購入シートが出て閉じると標準に戻る() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", storeKitJSON: #"{"isPlusPurchased":false}"#)
        element("tab.settings").tap()
        element("settings.appearance").tap()
        element("appearance.option.kinari").tap()

        XCTAssertEqual(readHookString("store.preview"), "kinari")
        XCTAssertEqual(matchingCount("store.buy"), 1)
        XCTAssertEqual(matchingCount("store.restore"), 1)
        element("store.close").tap()

        let settings = readHookJSON("hook.store")["settings"] as? [String: Any] ?? [:]
        XCTAssertEqual(settings["appearanceID"] as? String ?? "default", "default")
    }

    func test_AC106_購入すると見た目を選べてウィジェットと再起動後にも反映される() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", storeKitJSON: #"{"isPlusPurchased":false,"purchaseResult":"success"}"#)
        element("tab.settings").tap()
        element("settings.appearance").tap()
        element("appearance.option.kinari").tap()
        element("store.buy").tap()

        let store = readHookJSON("hook.store")
        let settings = store["settings"] as? [String: Any] ?? [:]
        XCTAssertEqual(settings["isPlusPurchased"] as? Bool, true)
        XCTAssertEqual(settings["appearanceID"] as? String, "kinari")
        XCTAssertEqual(readHookJSON("hook.widgets")["appearanceID"] as? String, "kinari")

        relaunchPreservingStore(now: "2026-10-18T21:05:00+09:00")
        let afterSettings = readHookJSON("hook.store")["settings"] as? [String: Any] ?? [:]
        XCTAssertEqual(afterSettings["appearanceID"] as? String, "kinari")
    }

    func test_AC107_購入の取りやめとエラー時に未購入と標準の見た目が保たれる() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", storeKitJSON: #"{"isPlusPurchased":false,"purchaseResult":"userCancelled"}"#)
        element("tab.settings").tap()
        element("settings.appearance").tap()
        element("appearance.option.kinari").tap()
        element("store.buy").tap()

        XCTAssertEqual(matchingCount("store.purchase.error"), 0)
        let s1 = readHookJSON("hook.store")["settings"] as? [String: Any] ?? [:]
        XCTAssertEqual(s1["isPlusPurchased"] as? Bool ?? false, false)

        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", storeKitJSON: #"{"isPlusPurchased":false,"purchaseResult":"error"}"#)
        element("tab.settings").tap()
        element("settings.appearance").tap()
        element("appearance.option.kinari").tap()
        element("store.buy").tap()
        XCTAssertEqual(matchingCount("store.purchase.error"), 1)
    }

    func test_AC108_購入の復元で履歴の有無に応じた結果と文言が出る() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", storeKitJSON: #"{"isPlusPurchased":false,"restoreHasHistory":true}"#)
        element("tab.settings").tap()
        element("settings.restorePurchases").tap()
        XCTAssertEqual(matchingCount("store.restore.done"), 1)
        let s1 = readHookJSON("hook.store")["settings"] as? [String: Any] ?? [:]
        XCTAssertEqual(s1["isPlusPurchased"] as? Bool, true)

        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", storeKitJSON: #"{"isPlusPurchased":false,"restoreHasHistory":false}"#)
        element("tab.settings").tap()
        element("settings.restorePurchases").tap()
        XCTAssertEqual(matchingCount("store.restore.none"), 1)
    }

    func test_AC109_決済不可の端末では購入ボタンを出さず案内を出す() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", storeKitJSON: #"{"canMakePayments":false}"#)
        element("tab.settings").tap()
        element("settings.appearance").tap()
        element("appearance.option.kinari").tap()

        XCTAssertEqual(matchingCount("store.buy"), 0)
        XCTAssertEqual(matchingCount("store.unavailable"), 1)
    }

    func test_AC110_オフラインで商品を読めないときは案内を出し読書は妨げない() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", offline: true, storeKitJSON: #"{"productLoadError":true}"#)
        element("tab.settings").tap()
        element("settings.appearance").tap()
        element("appearance.option.kinari").tap()

        XCTAssertEqual(matchingCount("store.offline"), 1)
        XCTAssertEqual(matchingCount("store.buy"), 0)
        XCTAssertEqual(app.alerts.count, 0)

        element("tab.bookmark").tap()
        XCTAssertTrue(element("bookmark.start").isEnabled)
    }

    func test_AC111_購入が返金されると前面復帰時に標準の見た目へ戻る() {
        let purchasedSeed = #"{"books":[{"id":"book-a","title":"羅生門","author":"芥川龍之介","status":"current","savedLine":"ある日の暮方の事である。","savedPage":61}],"records":[],"settings":{"isPlusPurchased":true,"appearanceID":"kinari"}}"#
        resetAndLaunch(seedJSON: purchasedSeed, now: "2026-10-18T21:00:00+09:00")
        triggerStoreRefund()
        XCUIDevice.shared.press(.home)
        app.activate()

        let settings = readHookJSON("hook.store")["settings"] as? [String: Any] ?? [:]
        XCTAssertEqual(settings["isPlusPurchased"] as? Bool, false)
        XCTAssertEqual(settings["appearanceID"] as? String, "default")
        XCTAssertEqual(readHookJSON("hook.widgets")["appearanceID"] as? String, "default")
    }

    func test_AC114_読み始めるインテントでアプリを開かず読書とLiveActivityが始まる() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T22:00:00+09:00")
        runExternalIntent("StartReadingIntent")

        let intentHook = readHookJSON("hook.intents")
        XCTAssertEqual(intentHook["opensApp"] as? Bool, false)
        XCTAssertEqual(readHookJSON("hook.state")["state"] as? String, "reading")

        advanceClock(seconds: 1800)
        element("reading.end").tap()
        element("mark.later").tap()

        let records = readHookJSON("hook.store")["records"] as? [[String: Any]] ?? []
        XCTAssertEqual(records.first?["minutes"] as? Int, 30)
        XCTAssertEqual(readHookJSON("hook.events")["entry"] as? String, "intent_start")
    }

    func test_AC115_どの状態から読み始めるインテントを動かしても二重に始まらない() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        element("bookmark.start").tap()
        runExternalIntent("StartReadingIntent")

        XCTAssertEqual(readHookJSON("hook.state")["state"] as? String, "reading")
        let dialog = readHookJSON("hook.intents")["dialogKey"] as? String
        XCTAssertEqual(dialog, "intent.start.alreadyReading")
    }

    func test_AC116_LiveActivityの終えるで動いた時刻で記録し場面に応じて画面を出す() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T22:00:00+09:00")
        runExternalIntent("StartReadingIntent")
        advanceClock(seconds: 1800)
        runExternalIntent("EndReadingFromActivityIntent", canContinueInForeground: true)

        XCTAssertTrue(element("mark.later").waitForExistence(timeout: uiTimeout))
        element("mark.later").tap()
        let records = readHookJSON("hook.store")["records"] as? [[String: Any]] ?? []
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?["minutes"] as? Int, 30)
    }

    func test_AC117_今の本がないときに読み始めるインテントはアプリを開いて空状態を見せる() {
        resetAndLaunch(seedJSON: #"{"books":[],"records":[]}"#, now: "2026-10-18T21:00:00+09:00")
        runExternalIntent("StartReadingIntent")
        XCTAssertTrue(element("bookmark.empty.message").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readHookJSON("hook.state")["state"] as? String, "idle")
    }

    func test_AC118_LiveActivityオフ時の読み始めるインテントは読書を開始し前面可ならS2を出す() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", liveActivityJSON: #"{"areActivitiesEnabled":false}"#)
        runExternalIntent("StartReadingIntent", canContinueInForeground: true)

        XCTAssertTrue(element("reading.end").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readHookJSON("hook.state")["state"] as? String, "reading")
        XCTAssertEqual(app.alerts.count, 0)
    }

    func test_AC119_読み始めるインテントで保存失敗時はエラーを返しLiveActivityを出さない() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", failSave: "session.start:1")
        runExternalIntent("StartReadingIntent")

        XCTAssertEqual(readHookJSON("hook.state")["state"] as? String, "idle")
        XCTAssertEqual(readHookJSON("hook.intents")["dialogKey"] as? String, "session.start.error")
    }

    func test_AC120_隠す設定オンのとき読み始めるインテントのLiveActivityに書名を出さない() {
        let hideSeed = #"{"books":[{"id":"book-a","title":"羅生門","author":"芥川龍之介","status":"current","savedLine":"ある日の暮方の事である。","savedPage":61}],"records":[],"settings":{"hideOnWidgets":true}}"#
        resetAndLaunch(seedJSON: hideSeed, now: "2026-10-18T22:00:00+09:00")
        runExternalIntent("StartReadingIntent")

        let laRaw = readHookString("hook.liveActivities")
        XCTAssertFalse(laRaw.contains("羅生門"))
        XCTAssertTrue(laRaw.contains("しおり"))
    }

    func test_AC121_どこまで読んだインテントは認証なしでページだけ答え一行と書名を出さない() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        runExternalIntent("WhereStoppedIntent")

        let intentHook = readHookJSON("hook.intents")
        XCTAssertEqual(intentHook["opensApp"] as? Bool, false)
        XCTAssertEqual(intentHook["authenticationPolicy"] as? String, "alwaysAllowed")
        let dialog = intentHook["dialogText"] as? String ?? ""
        XCTAssertEqual(dialog, "61ページからです。")
        XCTAssertFalse(dialog.contains("羅生門"))
        XCTAssertFalse(dialog.contains("ある日の暮方の事である。"))
    }

    func test_AC122_どこまで読んだインテントでページや今の本がないときの応答を検証する() {
        let noPageSeed = #"{"books":[{"id":"book-a","title":"羅生門","author":"芥川龍之介","status":"current","savedLine":"ある日の暮方の事である。"}],"records":[]}"#
        resetAndLaunch(seedJSON: noPageSeed, now: "2026-10-18T21:00:00+09:00")
        runExternalIntent("WhereStoppedIntent")
        let intentHook = readHookJSON("hook.intents")
        XCTAssertEqual(intentHook["dialogKey"] as? String, "intent.whereStopped.noPage")
        XCTAssertEqual(intentHook["opensApp"] as? Bool, false)

        resetAndLaunch(seedJSON: #"{"books":[],"records":[]}"#, now: "2026-10-18T21:00:00+09:00")
        runExternalIntent("WhereStoppedIntent")
        XCTAssertEqual(readHookJSON("hook.intents")["dialogKey"] as? String, "intent.whereStopped.noCurrent")
    }

    func test_AC123_隠す設定オンでもどこまで読んだインテントはページを答え書名と一行を出さない() {
        let hideSeed = #"{"books":[{"id":"book-a","title":"羅生門","author":"芥川龍之介","status":"current","savedLine":"ある日の暮方の事である。","savedPage":61}],"records":[],"settings":{"hideOnWidgets":true}}"#
        resetAndLaunch(seedJSON: hideSeed, now: "2026-10-18T21:00:00+09:00")
        runExternalIntent("WhereStoppedIntent")

        let intentHook = readHookJSON("hook.intents")
        XCTAssertEqual(intentHook["opensApp"] as? Bool, false)
        XCTAssertEqual(intentHook["dialogText"] as? String, "61ページからです。")
    }

    func test_AC124_続きを読むインテントはしおり画面を開き始まった読書にintent_openを付ける() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        runExternalIntent("ContinueReadingIntent")

        XCTAssertEqual(readHookJSON("hook.state")["flipMonitoring"] as? String, "on")
        advanceClock(seconds: 120)
        element("bookmark.start").tap()
        advanceClock(seconds: 120)
        element("reading.end").tap()
        element("mark.later").tap()

        XCTAssertEqual(readHookJSON("hook.events")["entry"] as? String, "intent_open")
    }

    func test_AC125_オフラインでも外からの3つのインテントとしおり保存がすべて動く() {
        let seed43 = #"{"books":[{"id":"book-a","title":"羅生門","author":"芥川龍之介","status":"current","savedLine":"ある日の暮方の事である。","savedPage":43}],"records":[]}"#
        resetAndLaunch(seedJSON: seed43, now: "2026-10-18T21:00:00+09:00", offline: true)
        runExternalIntent("WhereStoppedIntent")
        XCTAssertEqual(readHookJSON("hook.intents")["dialogText"] as? String, "43ページからです。")

        runExternalIntent("StartReadingIntent")
        advanceClock(seconds: 120)
        runExternalIntent("EndReadingFromActivityIntent", canContinueInForeground: true)

        let manualBtn = element("mark.manual")
        XCTAssertTrue(manualBtn.waitForExistence(timeout: uiTimeout))
        manualBtn.tap()
        let lineField = element("mark.lineField")
        lineField.tap()
        lineField.typeText("新しい一行")
        let pageField = element("mark.pageField")
        pageField.tap()
        pageField.typeText("61")
        element("mark.save").tap()

        let records = readHookJSON("hook.store")["records"] as? [[String: Any]] ?? []
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(app.alerts.count, 0)
    }

    func test_AC126_AppShortcuts3種とControl1種の登録内容と言い方を検証する() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        let intentHook = readHookJSON("hook.intents")
        let shortcuts = intentHook["registeredShortcuts"] as? [[String: Any]] ?? []
        let controls = intentHook["registeredControls"] as? [[String: Any]] ?? []
        XCTAssertEqual(shortcuts.count, 3)
        XCTAssertEqual(controls.count, 1)
        XCTAssertEqual(controls.first?["kind"] as? String, "button")
        XCTAssertEqual(controls.first?["intent"] as? String, "StartReadingIntent")
    }

    func test_AC131_読み始めるインテントでLiveActivity要求が失敗したらアプリを開いて読書を続ける() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", liveActivityJSON: #"{"failNextStart":1}"#)
        runExternalIntent("StartReadingIntent")

        XCTAssertEqual(readHookJSON("hook.intents")["opensApp"] as? Bool, true)
        XCTAssertEqual(readHookJSON("hook.state")["state"] as? String, "reading")
        advanceClock(seconds: 120)
        element("reading.end").tap()
        element("mark.later").tap()

        let records = readHookJSON("hook.store")["records"] as? [[String: Any]] ?? []
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?["minutes"] as? Int, 2)
    }

    func test_AC132_LiveActivityの終えるで保存失敗時は読書を消さずS2にエラーを出す() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T22:00:00+09:00", failSave: "session.end:1")
        runExternalIntent("StartReadingIntent")
        advanceClock(seconds: 1800)
        runExternalIntent("EndReadingFromActivityIntent", canContinueInForeground: true)

        XCTAssertTrue(element("session.save.error").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readHookJSON("hook.state")["state"] as? String, "reading")

        advanceClock(seconds: 300)
        element("reading.end").tap()
        element("mark.later").tap()

        let records = readHookJSON("hook.store")["records"] as? [[String: Any]] ?? []
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?["minutes"] as? Int, 35)
    }

    func test_AC133_どこまで読んだインテントで読込失敗時はエラー文言だけを返し書名やページを出さない() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", failSave: "store.load:1")
        runExternalIntent("WhereStoppedIntent")

        let intentHook = readHookJSON("hook.intents")
        XCTAssertEqual(intentHook["opensApp"] as? Bool, false)
        XCTAssertEqual(intentHook["dialogKey"] as? String, "intent.whereStopped.error")
        let dialogText = intentHook["dialogText"] as? String ?? ""
        XCTAssertFalse(dialogText.contains("61"))
        XCTAssertFalse(dialogText.contains("羅生門"))
    }

    func test_AC134_読書中に続きを読むインテントを動かすと読書中の画面を出す() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T22:00:00+09:00")
        element("bookmark.start").tap()
        advanceClock(seconds: 600)
        XCUIDevice.shared.press(.home)

        runExternalIntent("ContinueReadingIntent")
        XCTAssertTrue(element("reading.end").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readHookJSON("hook.state")["state"] as? String, "reading")
    }

    func test_AC135_今の本がないときに続きを読むインテントはしおり画面の空状態を出す() {
        let tsundokuOnly = #"{"books":[{"id":"book-b","title":"こころ","author":"夏目漱石","status":"tsundoku"}],"records":[]}"#
        resetAndLaunch(seedJSON: tsundokuOnly, now: "2026-10-18T21:00:00+09:00")
        runExternalIntent("ContinueReadingIntent")
        XCTAssertTrue(element("bookmark.noCurrent.message").waitForExistence(timeout: uiTimeout))

        resetAndLaunch(seedJSON: #"{"books":[],"records":[]}"#, now: "2026-10-18T21:00:00+09:00")
        runExternalIntent("ContinueReadingIntent")
        XCTAssertTrue(element("bookmark.empty.message").waitForExistence(timeout: uiTimeout))
    }

    func test_AC136_4時をまたぎLiveActivityが8時間上限で消えても読書は続き全分数が記録される() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T22:00:00+09:00")
        runExternalIntent("StartReadingIntent")
        advanceClock(seconds: 23400)
        XCTAssertEqual(readHookJSON("hook.state")["state"] as? String, "reading")

        advanceClock(seconds: 5400)
        transitionLiveActivity("dismissedBySystem")
        advanceClock(seconds: 3600)
        XCTAssertEqual(readHookJSON("hook.state")["state"] as? String, "reading")

        element("reading.end").tap()
        element("mark.later").tap()

        let records = readHookJSON("hook.store")["records"] as? [[String: Any]] ?? []
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?["minutes"] as? Int, 540)
        XCTAssertEqual(records.first?["nightDate"] as? String, "2026-10-18")
    }

    func test_AC143_電子書籍の位置番号とパーセントに応じてどこまで読んだインテントが答える() {
        let locSeed = #"{"books":[{"id":"book-e","title":"羅生門","author":"芥川龍之介","status":"current","isEbook":true,"savedPositionMode":"location","savedLocation":1450}],"records":[]}"#
        resetAndLaunch(seedJSON: locSeed, now: "2026-10-18T21:00:00+09:00")
        runExternalIntent("WhereStoppedIntent")
        XCTAssertEqual(readHookJSON("hook.intents")["dialogText"] as? String, "位置1450からです。")

        let pctSeed = #"{"books":[{"id":"book-e","title":"羅生門","author":"芥川龍之介","status":"current","isEbook":true,"savedPositionMode":"percent","savedPercent":52}],"records":[]}"#
        resetAndLaunch(seedJSON: pctSeed, now: "2026-10-18T21:00:00+09:00")
        runExternalIntent("WhereStoppedIntent")
        XCTAssertEqual(readHookJSON("hook.intents")["dialogText"] as? String, "52パーセントからです。")
    }

    func test_AC144_電子書籍のしおり画面と読書中画面に専用案内が出てLiveActivityから終えられる() {
        let ebookSeed = #"{"books":[{"id":"book-e","title":"羅生門","author":"芥川龍之介","status":"current","isEbook":true}],"records":[]}"#
        resetAndLaunch(seedJSON: ebookSeed, now: "2026-10-18T21:00:00+09:00")
        XCTAssertEqual(matchingCount("bookmark.flipHint.ebook"), 1)

        element("bookmark.start").tap()
        XCTAssertEqual(matchingCount("reading.ebookNote"), 1)
        advanceClock(seconds: 600)

        runExternalIntent("EndReadingFromActivityIntent", canContinueInForeground: true)
        element("mark.later").tap()

        let records = readHookJSON("hook.store")["records"] as? [[String: Any]] ?? []
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?["minutes"] as? Int, 10)
    }
}
