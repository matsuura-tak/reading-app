import XCTest

final class ReadingSessionAcceptanceTests: AcceptanceTestBase {

    private var currentBookSeed: String {
        makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                author: "芥川龍之介",
                status: "current",
                progressUnit: "page",
                page: 43,
                lastLine: "ある日の暮方の事である。"
            )
        ])
    }

    func test_AC42_起動から1タップで確認や入力なしに読み始められる() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        let startBtn = element("bookmark.start")
        XCTAssertTrue(startBtn.waitForExistence(timeout: uiTimeout))
        startBtn.tap()

        XCTAssertTrue(element("reading.end").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readHookState()["state"], "reading")
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
        XCTAssertEqual(readHookState()["state"], "reading")
        let titleEl = element("reading.title")
        XCTAssertTrue(titleEl.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(titleEl.label.contains("羅生門"))
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
        let state = readHookState()
        XCTAssertEqual(state["state"], "reading")
        XCTAssertEqual(state["startedBy"], "flip")
        XCTAssertEqual(state["haptic"], "1")
    }

    func test_AC45_伏せて1秒未満で起こすと読み始めない() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        XCTAssertTrue(element("bookmark.start").waitForExistence(timeout: uiTimeout))

        setOrientation(.faceDown)
        advanceClockMs(900)
        setOrientation(.portrait)
        advanceClockMs(2000)

        let state = readHookState()
        XCTAssertEqual(state["state"], "idle")
        XCTAssertEqual(state["haptic"], "0")
        let records = readStoreRecords()
        XCTAssertEqual(records.count, 0)
    }

    func test_AC46_今の本がないときは伏せの監視がオフで始まらない() {
        resetAndLaunch(seedJSON: makeSeedJSON(), now: "2026-10-18T21:00:00+09:00")
        XCTAssertTrue(element("bookmark.empty.message").waitForExistence(timeout: uiTimeout))
        setOrientation(.faceDown)
        advanceClockMs(2000)
        let stateEmpty = readHookState()
        XCTAssertEqual(stateEmpty["state"], "idle")
        XCTAssertEqual(stateEmpty["haptic"], "0")
        XCTAssertEqual(stateEmpty["flipMonitoring"], "off")
        setOrientation(.portrait)

        let tsundokuSeed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookB,
                title: "銀河鉄道の夜",
                author: "宮沢賢治",
                status: "tsundoku"
            )
        ])
        resetAndLaunch(seedJSON: tsundokuSeed, now: "2026-10-18T21:00:00+09:00")
        XCTAssertTrue(element("bookmark.noCurrent.message").waitForExistence(timeout: uiTimeout))
        setOrientation(.faceDown)
        advanceClockMs(2000)
        let stateNoCurrent = readHookState()
        XCTAssertEqual(stateNoCurrent["state"], "idle")
        XCTAssertEqual(stateNoCurrent["haptic"], "0")
        XCTAssertEqual(stateNoCurrent["flipMonitoring"], "off")
    }

    func test_AC47_しおり画面以外や知らせ表示中は伏せても始まらない() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")

        // (1) 本棚画面（S-6）
        let shelfBtn = element("toolbar.shelf")
        XCTAssertTrue(shelfBtn.waitForExistence(timeout: uiTimeout))
        shelfBtn.tap()
        XCTAssertTrue(element("shelf.row.\(uuidBookA)").waitForExistence(timeout: uiTimeout))
        setOrientation(.faceDown)
        advanceClockMs(2000)
        let s1 = readHookState()
        XCTAssertEqual(s1["state"], "idle")
        XCTAssertEqual(s1["flipMonitoring"], "off")
        XCTAssertEqual(s1["haptic"], "0")
        setOrientation(.portrait)

        // (2) 本の詳細画面（S-7）
        element("shelf.row.\(uuidBookA)").tap()
        XCTAssertTrue(element("book.colophon").waitForExistence(timeout: uiTimeout))
        setOrientation(.faceDown)
        advanceClockMs(2000)
        let s2 = readHookState()
        XCTAssertEqual(s2["state"], "idle")
        XCTAssertEqual(s2["flipMonitoring"], "off")
        XCTAssertEqual(s2["haptic"], "0")
        setOrientation(.portrait)
        navigateBackToBookmark()

        // (3) 本を加える画面（S-8）
        let addBtn = element("shelf.addBook")
        if addBtn.waitForExistence(timeout: uiTimeout) {
            addBtn.tap()
            setOrientation(.faceDown)
            advanceClockMs(2000)
            let s3 = readHookState()
            XCTAssertEqual(s3["state"], "idle")
            XCTAssertEqual(s3["flipMonitoring"], "off")
            XCTAssertEqual(s3["haptic"], "0")
            setOrientation(.portrait)
            let cancelBtn = element("register.cancel")
            if cancelBtn.exists {
                cancelBtn.tap()
            }
        }
        navigateBackToBookmark()

        // (4) 設定画面（S-10）
        let settingsBtn = element("toolbar.settings")
        XCTAssertTrue(settingsBtn.waitForExistence(timeout: uiTimeout))
        settingsBtn.tap()
        XCTAssertTrue(element("settings.flipToStart").waitForExistence(timeout: uiTimeout))
        setOrientation(.faceDown)
        advanceClockMs(2000)
        let s4 = readHookState()
        XCTAssertEqual(s4["state"], "idle")
        XCTAssertEqual(s4["flipMonitoring"], "off")
        XCTAssertEqual(s4["haptic"], "0")
        setOrientation(.portrait)
        navigateBackToBookmark()

        // (5) しおり入力シート（S-3）
        let setMarkBtn = element("bookmark.setMark")
        XCTAssertTrue(setMarkBtn.waitForExistence(timeout: uiTimeout))
        setMarkBtn.tap()
        XCTAssertTrue(element("mark.manual").waitForExistence(timeout: uiTimeout))
        setOrientation(.faceDown)
        advanceClockMs(2000)
        let s5 = readHookState()
        XCTAssertEqual(s5["state"], "idle")
        XCTAssertEqual(s5["flipMonitoring"], "off")
        XCTAssertEqual(s5["haptic"], "0")
        setOrientation(.portrait)
        let markCancel = element("mark.cancel")
        if markCancel.exists {
            markCancel.tap()
        }

        // (6) session.tooShort の知らせ表示中
        element("bookmark.start").tap()
        advanceClock(seconds: 30)
        element("reading.end").tap()
        XCTAssertTrue(element("session.tooShort").waitForExistence(timeout: uiTimeout))
        setOrientation(.faceDown)
        advanceClockMs(2000)
        let s6 = readHookState()
        XCTAssertEqual(s6["state"], "idle")
        XCTAssertEqual(s6["haptic"], "0")
        setOrientation(.portrait)

        // (7) 起動前から faceDown の状態（一度 portrait に戻すまで始まらないこと）
        setOrientation(.faceDown)
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        advanceClockMs(2000)
        let s7 = readHookState()
        XCTAssertEqual(s7["state"], "idle")
        XCTAssertEqual(s7["haptic"], "0")
        setOrientation(.portrait)
    }

    func test_AC48_読書中に起こしても止まらず伏せ直しても二重に始まらない() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        XCTAssertTrue(element("bookmark.start").waitForExistence(timeout: uiTimeout))

        setOrientation(.faceDown)
        advanceClockMs(1000)
        XCTAssertTrue(element("reading.end").waitForExistence(timeout: uiTimeout))

        advanceClock(seconds: 180)
        setOrientation(.portrait)
        XCTAssertEqual(readHookState()["state"], "reading")

        advanceClock(seconds: 10)
        setOrientation(.faceDown)
        advanceClock(seconds: 420)
        setOrientation(.portrait)

        element("reading.end").tap()
        let laterBtn = element("mark.later")
        XCTAssertTrue(laterBtn.waitForExistence(timeout: uiTimeout))
        laterBtn.tap()

        let records = readStoreRecords()
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?["minutes"] as? Int, 10)
        XCTAssertEqual(readHookState()["haptic"], "1")
    }

    func test_AC49_伏せて読み始めたときにVoiceOver読み上げが1回出る() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        XCTAssertTrue(element("bookmark.start").waitForExistence(timeout: uiTimeout))

        setOrientation(.faceDown)
        advanceClockMs(1000)
        XCTAssertTrue(element("reading.end").waitForExistence(timeout: uiTimeout))

        let announce = readHookState()["announce"] ?? ""
        XCTAssertTrue(announce.contains("session.flipStarted.announcement:1"))
    }

    func test_AC50_しおり画面に伏せて始める案内の1行が出る() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        XCTAssertTrue(element("bookmark.flipHint").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(matchingCount("bookmark.flipHint"), 1)
    }

    func test_AC51_伏せる設定オフまたは非対応環境では伏せても始まらない() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        element("toolbar.settings").tap()
        let flipToggle = element("settings.flipToStart")
        XCTAssertTrue(flipToggle.waitForExistence(timeout: uiTimeout))
        flipToggle.tap()
        relaunchPreservingStore(now: "2026-10-18T21:01:00+09:00")

        XCTAssertTrue(element("bookmark.start").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(matchingCount("bookmark.flipHint"), 0)

        setOrientation(.faceDown)
        advanceClockMs(2000)
        let stateOff = readHookState()
        XCTAssertEqual(stateOff["state"], "idle")
        XCTAssertEqual(stateOff["haptic"], "0")
        XCTAssertEqual(stateOff["flipMonitoring"], "off")
        setOrientation(.portrait)
        XCTAssertTrue(element("bookmark.start").isEnabled)

        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", flipUnavailable: true)
        XCTAssertTrue(element("bookmark.start").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(matchingCount("bookmark.flipHint"), 0)
        setOrientation(.faceDown)
        advanceClockMs(2000)
        let stateUnavail = readHookState()
        XCTAssertEqual(stateUnavail["state"], "idle")
        XCTAssertEqual(stateUnavail["haptic"], "0")
        XCTAssertEqual(stateUnavail["flipMonitoring"], "off")
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

        let records = readStoreRecords()
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?["minutes"] as? Int, 10)

        relaunchPreservingStore(now: "2026-10-18T21:10:00+09:00")
        let afterRecords = readStoreRecords()
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
        XCTAssertEqual(readHookState()["state"], "reading")

        endBtn.tap()
        let laterBtn = element("mark.later")
        XCTAssertTrue(laterBtn.waitForExistence(timeout: uiTimeout))
        laterBtn.tap()

        let records = readStoreRecords()
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?["minutes"] as? Int, 10)
    }

    func test_AC54_読書中も自動ロック無効化と近接センサー監視を使わない() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        let startBtn = element("bookmark.start")
        XCTAssertTrue(startBtn.waitForExistence(timeout: uiTimeout))
        startBtn.tap()

        let s1 = readHookState()
        XCTAssertEqual(s1["idleTimerDisabled"], "false")
        XCTAssertEqual(s1["proximity"], "false")
        advanceClock(seconds: 60)
        let s2 = readHookState()
        XCTAssertEqual(s2["idleTimerDisabled"], "false")
        XCTAssertEqual(s2["proximity"], "false")

        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        setOrientation(.faceDown)
        advanceClockMs(1000)
        let s3 = readHookState()
        XCTAssertEqual(s3["idleTimerDisabled"], "false")
        XCTAssertEqual(s3["proximity"], "false")
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
            let state = readHookState()
            let rawLat = state["lat.endToMark"] ?? state["prevLat.endToMark"] ?? "9999"
            let firstVal = Double(rawLat.split(separator: ",").first ?? "9999") ?? 9999.0
            XCTAssertLessThanOrEqual(firstVal, 500.0)
        }
    }

    func test_AC56_59秒は記録せず60秒ちょうどから1分として記録する() {
        let seedWith20Min = makeSeedJSON(
            books: [
                makeSeedBook(
                    id: uuidBookA,
                    title: "羅生門",
                    author: "芥川龍之介",
                    status: "current"
                )
            ],
            records: [
                makeSeedRecord(
                    id: makeRecordUUID(1),
                    bookId: uuidBookA,
                    minutes: 20,
                    nightDate: "2026-10-17"
                )
            ]
        )
        resetAndLaunch(seedJSON: seedWith20Min, now: "2026-10-18T21:00:00+09:00")
        element("bookmark.start").tap()
        advanceClock(seconds: 59)
        element("reading.end").tap()

        XCTAssertTrue(element("session.tooShort").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readStoreRecords().count, 1)

        element("bookmark.start").tap()
        advanceClock(seconds: 60)
        element("reading.end").tap()
        XCTAssertTrue(element("mark.later").waitForExistence(timeout: uiTimeout))
        element("mark.later").tap()

        let records = readStoreRecords()
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
            let records = readStoreRecords()
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
        XCTAssertEqual(readHookState()["state"], "idle")
        XCTAssertEqual(matchingCount("mark.later"), 0)
        XCTAssertEqual(readStoreRecords().count, 0)
    }

    func test_AC59_読み始めの保存失敗時はidleのままエラーを出す() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", failSave: "session.start:1")
        element("bookmark.start").tap()
        XCTAssertTrue(element("session.start.error").waitForExistence(timeout: uiTimeout))
        let s1 = readHookState()
        XCTAssertEqual(s1["state"], "idle")
        XCTAssertEqual(s1["haptic"], "0")

        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", failSave: "session.start:1")
        setOrientation(.faceDown)
        advanceClockMs(1000)
        XCTAssertTrue(element("session.start.error").waitForExistence(timeout: uiTimeout))
        let s2 = readHookState()
        XCTAssertEqual(s2["state"], "idle")
        XCTAssertEqual(s2["haptic"], "0")
    }

    func test_AC60_終わりの保存失敗時は読書中を保ち再試行で合算保存される() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", failSave: "session.end:2")
        element("bookmark.start").tap()
        advanceClock(seconds: 900)

        element("reading.end").tap()
        XCTAssertTrue(element("session.save.error").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readHookState()["state"], "reading")

        advanceClock(seconds: 300)
        element("reading.end").tap()
        XCTAssertTrue(element("session.save.error").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readHookState()["state"], "reading")

        advanceClock(seconds: 300)
        element("reading.end").tap()
        let laterBtn = element("mark.later")
        XCTAssertTrue(laterBtn.waitForExistence(timeout: uiTimeout))
        laterBtn.tap()

        let records = readStoreRecords()
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

        let records = readStoreRecords()
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?["minutes"] as? Int, 2)
    }

    func test_AC62_オフラインでもウィジェット起動からしおり保存まで完走する() {
        resetAndLaunch(
            seedJSON: currentBookSeed,
            now: "2026-10-18T21:00:00+09:00",
            offline: true,
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76"]
        )
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

        let records = readStoreRecords()
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?["minutes"] as? Int, 2)
        let books = readStoreBooks()
        XCTAssertEqual(books.first?["lastLine"] as? String, "下人の行方は、誰も知らない。")
        XCTAssertEqual(books.first?["page"] as? Int, 61)
        let widgetRaw = readHookString("hook.widget")
        XCTAssertTrue(widgetRaw.contains("下人の行方は"))
        XCTAssertTrue(widgetRaw.contains("p.61"))
        XCTAssertEqual(app.alerts.count, 0)
    }
}
