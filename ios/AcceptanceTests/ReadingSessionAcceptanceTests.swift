import XCTest

final class ReadingSessionAcceptanceTests: AcceptanceTestBase {

    private let currentBookSeed = #"{"books":[{"id":"book-a","title":"羅生門","author":"芥川龍之介","status":"current","savedLine":"ある日の暮方の事である。","savedPage":43}],"records":[]}"#

    func test_AC42_起動から1タップで確認や入力なしに読み始められる() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        let startBtn = element("bookmark.start")
        XCTAssertTrue(startBtn.waitForExistence(timeout: uiTimeout))
        startBtn.tap()

        XCTAssertTrue(element("reading.end").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readHookJSON("hook.state")["state"] as? String, "reading")
        XCTAssertEqual(app.alerts.count, 0)
        XCTAssertEqual(app.sheets.count, 0)
        XCTAssertEqual(app.textFields.count, 0)
        XCTAssertEqual(app.pickers.count, 0)
        XCTAssertEqual(app.segmentedControls.count, 0)
        XCTAssertEqual(app.menus.count, 0)
    }

    func test_AC43_読書中の画面は押せる要素が終えるの1つだけになる() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        let startBtn = element("bookmark.start")
        XCTAssertTrue(startBtn.waitForExistence(timeout: uiTimeout))
        startBtn.tap()

        let endBtn = element("reading.end")
        XCTAssertTrue(endBtn.waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readHookJSON("hook.state")["state"] as? String, "reading")
        let titleEl = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "羅生門")).firstMatch
        XCTAssertTrue(titleEl.exists)
        XCTAssertEqual(app.buttons.count, 1)
        XCTAssertEqual(app.tabBars.count, 0)
        XCTAssertEqual(app.navigationBars.count, 0)
    }

    func test_AC44_しおり画面で伏せて1秒たつと触覚が1回鳴り読み始める() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        XCTAssertTrue(element("bookmark.start").waitForExistence(timeout: uiTimeout))

        setOrientation(.faceDown)
        advanceClockMs(1000)

        XCTAssertTrue(element("reading.end").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readHookJSON("hook.state")["state"] as? String, "reading")
        let events = readHookJSON("hook.events")
        XCTAssertEqual(events["startedBy"] as? String, "flip")
        XCTAssertEqual(events["haptic"] as? Int, 1)
    }

    func test_AC45_伏せて1秒未満で起こすと読み始めない() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        XCTAssertTrue(element("bookmark.start").waitForExistence(timeout: uiTimeout))

        setOrientation(.faceDown)
        advanceClockMs(900)
        setOrientation(.portrait)
        advanceClockMs(2000)

        XCTAssertEqual(readHookJSON("hook.state")["state"] as? String, "idle")
        XCTAssertEqual(readHookJSON("hook.events")["haptic"] as? Int, 0)
        let store = readHookJSON("hook.store")
        let records = store["records"] as? [[String: Any]] ?? []
        XCTAssertEqual(records.count, 0)
    }

    func test_AC46_今の本がないときは伏せの監視がオフで始まらない() {
        resetAndLaunch(seedJSON: #"{"books":[],"records":[]}"#, now: "2026-10-18T21:00:00+09:00")
        XCTAssertTrue(element("bookmark.empty.message").waitForExistence(timeout: uiTimeout))
        setOrientation(.faceDown)
        advanceClockMs(2000)
        XCTAssertEqual(readHookJSON("hook.state")["state"] as? String, "idle")
        XCTAssertEqual(readHookJSON("hook.events")["haptic"] as? Int, 0)
        XCTAssertEqual(readHookJSON("hook.state")["flipMonitoring"] as? String, "off")
        setOrientation(.portrait)

        let tsundokuSeed = #"{"books":[{"id":"book-b","title":"銀河鉄道の夜","author":"宮沢賢治","status":"tsundoku"}],"records":[]}"#
        resetAndLaunch(seedJSON: tsundokuSeed, now: "2026-10-18T21:00:00+09:00")
        XCTAssertTrue(element("bookmark.noCurrent.message").waitForExistence(timeout: uiTimeout))
        setOrientation(.faceDown)
        advanceClockMs(2000)
        XCTAssertEqual(readHookJSON("hook.state")["state"] as? String, "idle")
        XCTAssertEqual(readHookJSON("hook.events")["haptic"] as? Int, 0)
        XCTAssertEqual(readHookJSON("hook.state")["flipMonitoring"] as? String, "off")
    }

    func test_AC47_しおり画面以外や知らせ表示中は伏せても始まらない() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        let shelfTab = element("tab.shelf")
        XCTAssertTrue(shelfTab.waitForExistence(timeout: uiTimeout))
        shelfTab.tap()

        setOrientation(.faceDown)
        advanceClockMs(2000)
        XCTAssertEqual(readHookJSON("hook.state")["state"] as? String, "idle")
        XCTAssertEqual(readHookJSON("hook.state")["flipMonitoring"] as? String, "off")
        XCTAssertEqual(readHookJSON("hook.events")["haptic"] as? Int, 0)
        setOrientation(.portrait)

        let settingsTab = element("tab.settings")
        if settingsTab.exists {
            settingsTab.tap()
            setOrientation(.faceDown)
            advanceClockMs(2000)
            XCTAssertEqual(readHookJSON("hook.state")["state"] as? String, "idle")
            XCTAssertEqual(readHookJSON("hook.state")["flipMonitoring"] as? String, "off")
            setOrientation(.portrait)
        }
    }

    func test_AC48_読書中に起こしても止まらず伏せ直しても二重に始まらない() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        XCTAssertTrue(element("bookmark.start").waitForExistence(timeout: uiTimeout))

        setOrientation(.faceDown)
        advanceClockMs(1000)
        XCTAssertTrue(element("reading.end").waitForExistence(timeout: uiTimeout))

        advanceClock(seconds: 180)
        setOrientation(.portrait)
        XCTAssertEqual(readHookJSON("hook.state")["state"] as? String, "reading")

        advanceClock(seconds: 10)
        setOrientation(.faceDown)
        advanceClock(seconds: 420)
        setOrientation(.portrait)

        element("reading.end").tap()
        let laterBtn = element("mark.later")
        XCTAssertTrue(laterBtn.waitForExistence(timeout: uiTimeout))
        laterBtn.tap()

        let store = readHookJSON("hook.store")
        let records = store["records"] as? [[String: Any]] ?? []
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?["minutes"] as? Int, 10)
        XCTAssertEqual(readHookJSON("hook.events")["haptic"] as? Int, 1)
    }

    func test_AC49_伏せて読み始めたときにVoiceOver読み上げが1回出る() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        XCTAssertTrue(element("bookmark.start").waitForExistence(timeout: uiTimeout))

        setOrientation(.faceDown)
        advanceClockMs(1000)
        XCTAssertTrue(element("reading.end").waitForExistence(timeout: uiTimeout))

        let events = readHookJSON("hook.events")
        let announce = events["announce"] as? String ?? ""
        XCTAssertTrue(announce.contains("session.flipStarted.announcement:1"))
        XCTAssertTrue(announce.contains("羅生門"))
    }

    func test_AC50_しおり画面に伏せて始める案内の1行が出る() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        XCTAssertTrue(element("bookmark.flipHint").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(matchingCount("bookmark.flipHint"), 1)
    }

    func test_AC51_伏せる設定オフまたは非対応環境では伏せても始まらない() {
        let disabledFlipSeed = #"{"books":[{"id":"book-a","title":"羅生門","author":"芥川龍之介","status":"current"}],"records":[],"settings":{"flipToStart":false}}"#
        resetAndLaunch(seedJSON: disabledFlipSeed, now: "2026-10-18T21:00:00+09:00")
        XCTAssertTrue(element("bookmark.start").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(matchingCount("bookmark.flipHint"), 0)

        setOrientation(.faceDown)
        advanceClockMs(2000)
        XCTAssertEqual(readHookJSON("hook.state")["state"] as? String, "idle")
        XCTAssertEqual(readHookJSON("hook.events")["haptic"] as? Int, 0)
        XCTAssertEqual(readHookJSON("hook.state")["flipMonitoring"] as? String, "off")
        setOrientation(.portrait)
        XCTAssertTrue(element("bookmark.start").isEnabled)

        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", flipUnavailable: true)
        XCTAssertTrue(element("bookmark.start").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(matchingCount("bookmark.flipHint"), 0)
        setOrientation(.faceDown)
        advanceClockMs(2000)
        XCTAssertEqual(readHookJSON("hook.state")["state"] as? String, "idle")
        XCTAssertEqual(readHookJSON("hook.events")["haptic"] as? Int, 0)
        XCTAssertEqual(readHookJSON("hook.state")["flipMonitoring"] as? String, "off")
    }

    func test_AC52_バックグラウンドの間も開始時刻からの差で時間を数える() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        let startBtn = element("bookmark.start")
        XCTAssertTrue(startBtn.waitForExistence(timeout: uiTimeout))
        startBtn.tap()
        XCTAssertTrue(element("reading.end").waitForExistence(timeout: uiTimeout))

        XCUIDevice.shared.press(.home)
        advanceClock(seconds: 600)
        app.activate()

        let endBtn = element("reading.end")
        XCTAssertTrue(endBtn.waitForExistence(timeout: uiTimeout))
        endBtn.tap()
        let laterBtn = element("mark.later")
        XCTAssertTrue(laterBtn.waitForExistence(timeout: uiTimeout))
        laterBtn.tap()

        let store = readHookJSON("hook.store")
        let records = store["records"] as? [[String: Any]] ?? []
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?["minutes"] as? Int, 10)

        relaunchPreservingStore(now: "2026-10-18T21:10:00+09:00")
        let afterStore = readHookJSON("hook.store")
        let afterRecords = afterStore["records"] as? [[String: Any]] ?? []
        XCTAssertEqual(afterRecords.count, 1)
        XCTAssertEqual(afterRecords.first?["minutes"] as? Int, 10)
    }

    func test_AC53_読書中に強制終了しても再起動後に続きから数える() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        let startBtn = element("bookmark.start")
        XCTAssertTrue(startBtn.waitForExistence(timeout: uiTimeout))
        startBtn.tap()
        advanceClock(seconds: 300)

        relaunchPreservingStore(now: "2026-10-18T21:10:00+09:00")
        let endBtn = element("reading.end")
        XCTAssertTrue(endBtn.waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readHookJSON("hook.state")["state"] as? String, "reading")

        endBtn.tap()
        let laterBtn = element("mark.later")
        XCTAssertTrue(laterBtn.waitForExistence(timeout: uiTimeout))
        laterBtn.tap()

        let store = readHookJSON("hook.store")
        let records = store["records"] as? [[String: Any]] ?? []
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?["minutes"] as? Int, 10)
    }

    func test_AC54_読書中も自動ロック無効化と近接センサー監視を使わない() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        let startBtn = element("bookmark.start")
        XCTAssertTrue(startBtn.waitForExistence(timeout: uiTimeout))
        startBtn.tap()

        XCTAssertEqual(readHookJSON("hook.state")["idleTimerDisabled"] as? Bool, false)
        XCTAssertEqual(readHookJSON("hook.events")["proximity"] as? Bool, false)
        advanceClock(seconds: 60)
        XCTAssertEqual(readHookJSON("hook.state")["idleTimerDisabled"] as? Bool, false)
        XCTAssertEqual(readHookJSON("hook.events")["proximity"] as? Bool, false)

        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        setOrientation(.faceDown)
        advanceClockMs(1000)
        XCTAssertEqual(readHookJSON("hook.state")["idleTimerDisabled"] as? Bool, false)
        XCTAssertEqual(readHookJSON("hook.events")["proximity"] as? Bool, false)
    }

    func test_AC55_終える1タップで確認なしに500ミリ秒以内にしおり画面が出る() {
        for _ in 0..<5 {
            resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
            let startBtn = element("bookmark.start")
            XCTAssertTrue(startBtn.waitForExistence(timeout: uiTimeout))
            startBtn.tap()
            advanceClock(seconds: 120)

            let endBtn = element("reading.end")
            XCTAssertTrue(endBtn.waitForExistence(timeout: uiTimeout))
            endBtn.tap()

            XCTAssertTrue(element("mark.later").waitForExistence(timeout: uiTimeout))
            XCTAssertEqual(app.alerts.count, 0)
            let perf = readHookJSON("hook.perf")
            let endToMarkMs = perf["endToMark"] as? Double ?? 9999.0
            XCTAssertLessThanOrEqual(endToMarkMs, 500.0)
        }
    }

    func test_AC56_59秒は記録せず60秒ちょうどから1分として記録する() {
        let seedWith20Min = #"{"books":[{"id":"book-a","title":"羅生門","author":"芥川龍之介","status":"current"}],"records":[{"id":"r1","bookID":"book-a","nightDate":"2026-10-17","minutes":20}]}"#
        resetAndLaunch(seedJSON: seedWith20Min, now: "2026-10-18T21:00:00+09:00")
        element("bookmark.start").tap()
        advanceClock(seconds: 59)
        element("reading.end").tap()

        XCTAssertTrue(element("session.tooShort").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual((readHookJSON("hook.store")["records"] as? [[String: Any]] ?? []).count, 1)

        element("bookmark.start").tap()
        advanceClock(seconds: 60)
        element("reading.end").tap()
        XCTAssertTrue(element("mark.later").waitForExistence(timeout: uiTimeout))
        element("mark.later").tap()

        let records = readHookJSON("hook.store")["records"] as? [[String: Any]] ?? []
        XCTAssertEqual(records.count, 2)
    }

    func test_AC57_24時間超は1440分で止めて上限の知らせを出す() {
        let durations = [(86400, 0), (86459, 0), (86460, 1), (108000, 1)]
        for (secs, expectedNoticeCount) in durations {
            resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
            element("bookmark.start").tap()
            advanceClock(seconds: secs)
            element("reading.end").tap()
            XCTAssertTrue(element("mark.later").waitForExistence(timeout: uiTimeout))
            element("mark.later").tap()

            XCTAssertEqual(matchingCount("session.capped"), expectedNoticeCount)
            let records = readHookJSON("hook.store")["records"] as? [[String: Any]] ?? []
            XCTAssertEqual(records.first?["minutes"] as? Int, 1440)
        }
    }

    func test_AC58_端末時刻が開始より前に戻ったときは記録せず知らせを出す() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        element("bookmark.start").tap()
        XCTAssertTrue(element("reading.end").waitForExistence(timeout: uiTimeout))

        relaunchPreservingStore(now: "2026-10-18T20:30:00+09:00")
        let endBtn = element("reading.end")
        if endBtn.exists {
            endBtn.tap()
        }
        XCTAssertTrue(element("session.invalidTime").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readHookJSON("hook.state")["state"] as? String, "idle")
        XCTAssertEqual(matchingCount("mark.later"), 0)
        XCTAssertEqual((readHookJSON("hook.store")["records"] as? [[String: Any]] ?? []).count, 0)
    }

    func test_AC59_読み始めの保存失敗時はidleのままエラーを出す() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", failSave: "session.start:1")
        element("bookmark.start").tap()
        XCTAssertTrue(element("session.start.error").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readHookJSON("hook.state")["state"] as? String, "idle")
        XCTAssertEqual(readHookJSON("hook.events")["haptic"] as? Int, 0)

        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", failSave: "session.start:1")
        setOrientation(.faceDown)
        advanceClockMs(1000)
        XCTAssertTrue(element("session.start.error").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readHookJSON("hook.state")["state"] as? String, "idle")
        XCTAssertEqual(readHookJSON("hook.events")["haptic"] as? Int, 0)
    }

    func test_AC60_終わりの保存失敗時は読書中を保ち再試行で合算保存される() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", failSave: "session.end:2")
        element("bookmark.start").tap()
        advanceClock(seconds: 900)

        element("reading.end").tap()
        XCTAssertTrue(element("session.save.error").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readHookJSON("hook.state")["state"] as? String, "reading")

        advanceClock(seconds: 300)
        element("reading.end").tap()
        XCTAssertTrue(element("session.save.error").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readHookJSON("hook.state")["state"] as? String, "reading")

        advanceClock(seconds: 300)
        element("reading.end").tap()
        let laterBtn = element("mark.later")
        XCTAssertTrue(laterBtn.waitForExistence(timeout: uiTimeout))
        laterBtn.tap()

        let records = readHookJSON("hook.store")["records"] as? [[String: Any]] ?? []
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?["minutes"] as? Int, 25)
    }

    func test_AC61_開始と終了の二度押しで記録や画面が重複しない() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        let startBtn = element("bookmark.start")
        XCTAssertTrue(startBtn.waitForExistence(timeout: uiTimeout))
        startBtn.tap()
        if startBtn.exists {
            startBtn.tap()
        }

        XCTAssertEqual(matchingCount("reading.end"), 1)
        advanceClock(seconds: 120)

        let endBtn = element("reading.end")
        endBtn.tap()
        if endBtn.exists {
            endBtn.tap()
        }

        let laterBtn = element("mark.later")
        XCTAssertTrue(laterBtn.waitForExistence(timeout: uiTimeout))
        laterBtn.tap()

        let records = readHookJSON("hook.store")["records"] as? [[String: Any]] ?? []
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?["minutes"] as? Int, 2)
    }

    func test_AC62_オフラインでもウィジェット起動からしおり保存まで完走する() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", offline: true)
        openEntryURL("lock_widget")

        let startBtn = element("bookmark.start")
        XCTAssertTrue(startBtn.waitForExistence(timeout: uiTimeout))
        startBtn.tap()
        advanceClock(seconds: 120)
        element("reading.end").tap()

        let manualBtn = element("mark.manual")
        XCTAssertTrue(manualBtn.waitForExistence(timeout: uiTimeout))
        manualBtn.tap()

        let lineField = element("mark.lineField")
        XCTAssertTrue(lineField.waitForExistence(timeout: uiTimeout))
        lineField.tap()
        lineField.typeText("下人の行方は、誰も知らない。")

        let pageField = element("mark.pageField")
        pageField.tap()
        pageField.typeText("61")
        element("mark.save").tap()

        let store = readHookJSON("hook.store")
        let records = store["records"] as? [[String: Any]] ?? []
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?["minutes"] as? Int, 2)
        XCTAssertEqual(app.alerts.count, 0)
    }
}
