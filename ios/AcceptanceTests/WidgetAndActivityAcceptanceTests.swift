import XCTest

final class WidgetAndActivityAcceptanceTests: AcceptanceTestBase {
    func test_AC27_ロック画面ウィジェットに縦書きの一行とページが出る() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                status: "current",
                progressUnit: "page",
                page: 61,
                lastLine: "下人の行方は、誰も知らない。"
            )
        ])
        resetAndLaunch(
            seedJSON: seed,
            extraArgs: ["-uitest-widget", "accessoryRectangular:153x68,accessoryRectangular:172x76"]
        )

        let raw = readHookString("hook.widget")
        XCTAssertTrue(raw.contains("p.61"))
        XCTAssertTrue(raw.contains("yomuma://open?entry=lock_widget"))
        XCTAssertTrue(raw.contains("下人の行方は"))
        XCTAssertTrue(raw.contains("誰も知らない"))
        attachScreenshot(name: "AC27_lock_widget")
    }

    func test_AC28_縦書きの字形置換と行頭禁則処理を検証する() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                status: "current",
                progressUnit: "page",
                page: 61,
                lastLine: "「下人の行方は、誰も知らなーい。」"
            )
        ])
        resetAndLaunch(
            seedJSON: seed,
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76"]
        )

        let raw = readHookString("hook.widget")
        XCTAssertTrue(raw.contains("\u{FE11}") || raw.contains("\u{FE12}") || raw.contains("\u{FE41}") || raw.contains("\u{FE42}"))
    }

    func test_AC29_26字以上の一行の句読点位置による縮め方を検証する() {
        let cases: [(String, Int)] = [
            (String(repeating: "あ", count: 25), 25),
            (String(repeating: "あ", count: 17) + "、" + String(repeating: "い", count: 13), 18),
            (String(repeating: "あ", count: 9) + "、" + String(repeating: "い", count: 21), 25),
            (String(repeating: "あ", count: 12) + "、" + String(repeating: "い", count: 18), 13),
            (String(repeating: "あ", count: 11) + "、" + String(repeating: "い", count: 19), 25),
            (String(repeating: "あ", count: 7) + "、" + String(repeating: "い", count: 11) + "。" + String(repeating: "う", count: 11), 20)
        ]

        for (lineText, _) in cases {
            let seed = makeSeedJSON(books: [
                makeSeedBook(
                    id: uuidBookA,
                    title: "羅生門",
                    status: "current",
                    progressUnit: "page",
                    page: 61,
                    lastLine: lineText
                )
            ])
            resetAndLaunch(
                seedJSON: seed,
                extraArgs: ["-uitest-widget", "accessoryRectangular:172x76"]
            )
            let bmLine = element("bookmark.line")
            XCTAssertTrue(bmLine.waitForExistence(timeout: uiTimeout))
            XCTAssertEqual(bmLine.label, lineText)
            let widgetRaw = readHookString("hook.widget")
            XCTAssertFalse(widgetRaw.isEmpty)
        }
    }

    func test_AC30_欧文のみの一行は横書き1行で出る() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "Rain",
                status: "current",
                progressUnit: "page",
                page: 61,
                lastLine: "It was raining."
            )
        ])
        resetAndLaunch(
            seedJSON: seed,
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76"]
        )

        let raw = readHookString("hook.widget")
        XCTAssertTrue(raw.contains("It was raining."))
        XCTAssertTrue(raw.contains("horizontal"))
    }

    func test_AC31_一行がないときは書名とページをウィジェットに出す() {
        let seedWithPage = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookB,
                title: "檸檬",
                status: "current",
                progressUnit: "page",
                page: 120
            )
        ])
        resetAndLaunch(
            seedJSON: seedWithPage,
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76,systemSmall:170x170"]
        )
        let raw1 = readHookString("hook.widget")
        XCTAssertTrue(raw1.contains("檸檬"))
        XCTAssertTrue(raw1.contains("p.120"))

        let seedNoPage = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookB,
                title: "檸檬",
                status: "current"
            )
        ])
        resetAndLaunch(
            seedJSON: seedNoPage,
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76,systemSmall:170x170"]
        )
        let raw2 = readHookString("hook.widget")
        XCTAssertTrue(raw2.contains("檸檬"))
        XCTAssertFalse(raw2.contains("p.120"))
    }

    func test_AC32_今の本がないときはウィジェットに空の文言が出る() {
        resetAndLaunch(extraArgs: ["-uitest-widget", "accessoryRectangular:172x76,systemSmall:170x170"])
        let raw1 = readHookString("hook.widget")
        XCTAssertTrue(raw1.contains("empty") || raw1.contains("widget.empty"))

        let seedTsundokuOnly = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookB,
                title: "檸檬",
                status: "tsundoku"
            )
        ])
        resetAndLaunch(
            seedJSON: seedTsundokuOnly,
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76,systemSmall:170x170"]
        )
        let raw2 = readHookString("hook.widget")
        XCTAssertTrue(raw2.contains("empty") || raw2.contains("widget.empty"))
    }

    func test_AC33_しおり保存でウィジェットが1回だけ再読み込みされる() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                status: "current",
                progressUnit: "page",
                page: 43,
                lastLine: "旧の一行"
            )
        ])
        resetAndLaunch(
            seedJSON: seed,
            now: "2026-10-18T21:00:00+09:00",
            timezone: "Asia/Tokyo",
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76"]
        )

        element("bookmark.start").tap()
        advanceClock(seconds: 600)
        element("reading.end").tap()

        element("mark.manual").tap()
        let lineField = element("mark.lineField")
        let pageField = element("mark.pageField")
        XCTAssertTrue(lineField.waitForExistence(timeout: uiTimeout))
        lineField.tap()
        lineField.typeText("下人の行方は、誰も知らない。")
        pageField.tap()
        pageField.typeText("61")
        element("mark.save").tap()

        let closeBtn = element("result.close")
        if closeBtn.waitForExistence(timeout: uiTimeout) {
            closeBtn.tap()
        }

        let hookState = readHookState()
        let reloadsRaw = hookState["widgetReloads"] ?? ""
        XCTAssertTrue(reloadsRaw.contains("mark.save:1"), "Expected mark.save:1 in widgetReloads, got: \(reloadsRaw)")

        let widgetJSON = readHookJSON("hook.widget")
        let reloadRequests = widgetJSON["reloadRequests"] as? [String: Any] ?? [:]
        let byCause = reloadRequests["byCause"] as? [String: Int] ?? [:]
        XCTAssertEqual(byCause["mark.save"], 1)

        let widgetRaw = readHookString("hook.widget")
        XCTAssertTrue(widgetRaw.contains("p.61"))
    }

    func test_AC34_隠す設定オンでウィジェットとLiveActivityから書名と一行を隠す() {
        let seed = makeSeedJSON(
            books: [
                makeSeedBook(
                    id: uuidBookA,
                    title: "羅生門",
                    status: "current",
                    progressUnit: "page",
                    page: 61,
                    lastLine: "下人の行方は、誰も知らない。"
                )
            ],
            settings: makeSeedSettings(
                flipToStartEnabled: true,
                hideOnWidgets: true,
                entryTime: "21:00",
                widgetGuideShown: true
            )
        )
        resetAndLaunch(
            seedJSON: seed,
            now: "2026-10-18T20:00:00+09:00",
            timezone: "Asia/Tokyo",
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76,systemSmall:170x170"]
        )

        let bmLine = element("bookmark.line")
        XCTAssertTrue(bmLine.waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(bmLine.label, "下人の行方は、誰も知らない。")

        let widgetRaw = readHookString("hook.widget")
        XCTAssertFalse(widgetRaw.contains("羅生門"))
        XCTAssertFalse(widgetRaw.contains("下人の行方は"))
        XCTAssertTrue(widgetRaw.contains("p.61"))

        let laRaw = readHookString("hook.liveActivity")
        XCTAssertFalse(laRaw.contains("羅生門"))
        XCTAssertFalse(laRaw.contains("下人の行方は"))
    }

    func test_AC35_StandBy用の小ウィジェットに縦書きの一行とページが出る() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                status: "current",
                progressUnit: "page",
                page: 61,
                lastLine: "下人の行方は、誰も知らない。"
            )
        ])
        resetAndLaunch(
            seedJSON: seed,
            extraArgs: ["-uitest-widget", "systemSmall:148x148,systemSmall:170x170"]
        )

        let raw = readHookString("hook.widget")
        XCTAssertTrue(raw.contains("p.61"))
        XCTAssertTrue(raw.contains("yomuma://open?entry=small_widget"))
        XCTAssertTrue(raw.contains("下人の行方は"))
        attachScreenshot(name: "AC35_small_widget")
    }

    func test_AC36_しおり保存で翌晩21時のLiveActivityが1件予約される() {
        let seed = makeSeedJSON(
            books: [
                makeSeedBook(
                    id: uuidBookA,
                    title: "羅生門",
                    status: "current",
                    progressUnit: "page",
                    page: 43,
                    lastLine: "旧の一行"
                )
            ],
            settings: makeSeedSettings(
                flipToStartEnabled: true,
                hideOnWidgets: false,
                entryTime: "21:00",
                widgetGuideShown: true
            )
        )
        for startAt in ["2026-10-18T22:00:00+09:00", "2026-10-19T00:00:00+09:00"] {
            resetAndLaunch(seedJSON: seed, now: startAt, timezone: "Asia/Tokyo")

            element("bookmark.start").tap()
            advanceClock(seconds: 1800)
            element("reading.end").tap()

            element("mark.pageOnly").tap()
            let pageField = element("mark.pageField")
            XCTAssertTrue(pageField.waitForExistence(timeout: uiTimeout))
            pageField.tap()
            pageField.typeText("61")
            element("mark.save").tap()

            let la = readHookJSON("hook.liveActivity")
            let activities = la["activities"] as? [[String: Any]] ?? []
            XCTAssertEqual(activities.count, 1)
            let laRaw = readHookString("hook.liveActivity")
            XCTAssertTrue(laRaw.contains("2026-10-19"))
            XCTAssertTrue(laRaw.contains("p.61"))
        }
    }

    func test_AC37_LiveActivityオフ時は予約要求を出さず設定に案内を出す() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                status: "current",
                progressUnit: "page",
                page: 43
            )
        ])
        let laConfig = """
        {
          "areActivitiesEnabled": false
        }
        """
        resetAndLaunch(
            seedJSON: seed,
            now: "2026-10-18T22:00:00+09:00",
            timezone: "Asia/Tokyo",
            liveActivityJSON: laConfig,
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76"]
        )

        element("bookmark.start").tap()
        advanceClock(seconds: 600)
        element("reading.end").tap()

        element("mark.pageOnly").tap()
        element("mark.pageField").tap()
        element("mark.pageField").typeText("61")
        element("mark.save").tap()

        XCTAssertEqual(app.alerts.count, 0)
        let closeBtn = element("result.close")
        if closeBtn.waitForExistence(timeout: uiTimeout) {
            closeBtn.tap()
        }

        let la = readHookJSON("hook.liveActivity")
        let requests = la["requests"] as? [Any] ?? []
        XCTAssertEqual(requests.count, 0)

        let widgetRaw = readHookString("hook.widget")
        XCTAssertTrue(widgetRaw.contains("p.61"))

        element("toolbar.settings").tap()
        XCTAssertTrue(element("settings.liveActivity.off").waitForExistence(timeout: uiTimeout))
    }

    func test_AC38_夜の入口の時刻を15分刻みで変えると予約時刻が変わる() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                status: "current",
                progressUnit: "page",
                page: 43
            )
        ])
        resetAndLaunch(
            seedJSON: seed,
            now: "2026-10-18T22:00:00+09:00",
            timezone: "Asia/Tokyo"
        )

        element("toolbar.settings").tap()
        let entryPicker = element("settings.entryTime")
        XCTAssertTrue(entryPicker.waitForExistence(timeout: uiTimeout))
        entryPicker.tap()

        let opt2245 = element("settings.entryTime.22:45")
        if opt2245.waitForExistence(timeout: uiTimeout) {
            opt2245.tap()
        }

        let settingsSnapshot = readStoreSettings()
        XCTAssertEqual(settingsSnapshot["entryTime"] as? String, "22:45")

        navigateBackToBookmark()
        element("bookmark.start").tap()
        advanceClock(seconds: 600)
        element("reading.end").tap()
        element("mark.later").tap()

        let laRaw = readHookString("hook.liveActivity")
        XCTAssertTrue(laRaw.contains("22:45") || laRaw.contains("13:45:00"))
    }

    func test_AC39_予約がない晩でもアイコン起動でしおり画面が開き伏せ監視がオンになる() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                status: "current",
                progressUnit: "page",
                page: 61,
                lastLine: "下人の行方は、誰も知らない。"
            )
        ])
        resetAndLaunch(seedJSON: seed, now: "2026-10-18T22:30:00+09:00", timezone: "Asia/Tokyo")

        XCTAssertTrue(element("bookmark.line").waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(element("bookmark.page").waitForExistence(timeout: uiTimeout))
        let startBtn = element("bookmark.start")
        XCTAssertTrue(startBtn.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(startBtn.isEnabled)
        XCTAssertEqual(app.alerts.count, 0)
        XCTAssertEqual(app.sheets.count, 0)

        let hookState = readHookState()
        XCTAssertEqual(hookState["flipMonitoring"], "on")
    }

    func test_AC40_入口のURLと300秒境界で記録の入口の印が決まる() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                status: "current"
            )
        ])

        // (1) lock_widget, (2) small_widget, (3) live_activity
        for entry in ["lock_widget", "small_widget", "live_activity"] {
            resetAndLaunch(seedJSON: seed, now: "2026-10-18T21:00:00+09:00", timezone: "Asia/Tokyo")
            openEntryURL(entry)
            element("bookmark.start").tap()
            advanceClock(seconds: 120)
            element("reading.end").tap()
            element("mark.later").tap()
            let hookState = readHookState()
            XCTAssertEqual(hookState["entry"], entry)
        }

        // (4) アイコン起動 -> app
        resetAndLaunch(seedJSON: seed, now: "2026-10-18T21:00:00+09:00", timezone: "Asia/Tokyo")
        element("bookmark.start").tap()
        advanceClock(seconds: 120)
        element("reading.end").tap()
        element("mark.later").tap()
        XCTAssertEqual(readHookState()["entry"], "app")

        // (5) URL起動後バックグラウンド経由 -> app
        resetAndLaunch(seedJSON: seed, now: "2026-10-18T21:00:00+09:00", timezone: "Asia/Tokyo")
        openEntryURL("lock_widget")
        XCUIDevice.shared.press(.home)
        app.activate()
        element("bookmark.start").tap()
        advanceClock(seconds: 120)
        element("reading.end").tap()
        element("mark.later").tap()
        XCTAssertEqual(readHookState()["entry"], "app")

        // (6) 299秒後開始 -> lock_widget
        resetAndLaunch(seedJSON: seed, now: "2026-10-18T21:00:00+09:00", timezone: "Asia/Tokyo")
        openEntryURL("lock_widget")
        advanceClock(seconds: 299)
        element("bookmark.start").tap()
        advanceClock(seconds: 120)
        element("reading.end").tap()
        element("mark.later").tap()
        XCTAssertEqual(readHookState()["entry"], "lock_widget")

        // (7) 301秒後開始 -> app
        resetAndLaunch(seedJSON: seed, now: "2026-10-18T21:00:00+09:00", timezone: "Asia/Tokyo")
        openEntryURL("lock_widget")
        advanceClock(seconds: 301)
        element("bookmark.start").tap()
        advanceClock(seconds: 120)
        element("reading.end").tap()
        element("mark.later").tap()
        XCTAssertEqual(readHookState()["entry"], "app")
    }

    func test_AC41_表示中の予約LiveActivityが読書中から結果表示へ遷移する() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                status: "current",
                progressUnit: "page",
                page: 43,
                lastLine: "下人の行方は、誰も知らない。"
            )
        ])
        resetAndLaunch(seedJSON: seed, now: "2026-10-18T20:00:00+09:00", timezone: "Asia/Tokyo")
        transitionLiveActivity("started")

        element("bookmark.start").tap()
        let laDuring = readHookString("hook.liveActivity")
        XCTAssertTrue(laDuring.contains("reading"))
        XCTAssertTrue(laDuring.contains("liveActivity.end"))

        advanceClock(seconds: 600)
        element("reading.end").tap()
        element("mark.pageOnly").tap()
        element("mark.pageField").tap()
        element("mark.pageField").typeText("61")
        element("mark.save").tap()

        let laAfter = readHookString("hook.liveActivity")
        XCTAssertTrue(laAfter.contains("10") && laAfter.contains("p.61"))
    }

    func test_AC96_ウィジェットの置き方案内は最初の1回だけ出る() {
        let seed = makeSeedJSON(
            books: [
                makeSeedBook(
                    id: uuidBookA,
                    title: "羅生門",
                    status: "current"
                )
            ],
            settings: makeSeedSettings(
                flipToStartEnabled: true,
                hideOnWidgets: false,
                entryTime: "21:00",
                widgetGuideShown: false
            )
        )
        resetAndLaunch(seedJSON: seed, now: "2026-10-18T21:00:00+09:00", timezone: "Asia/Tokyo")

        element("bookmark.setMark").tap()
        element("mark.manual").tap()
        element("mark.lineField").tap()
        element("mark.lineField").typeText("下人の行方は、誰も知らない。")
        element("mark.save").tap()

        let guide = element("widgetGuide")
        XCTAssertTrue(guide.waitForExistence(timeout: uiTimeout))
        let hookState1 = readHookState()
        XCTAssertTrue((hookState1["notice"] ?? "").contains("widgetGuide:1"))

        let closeGuide = element("widgetGuide.close")
        if closeGuide.waitForExistence(timeout: uiTimeout) {
            closeGuide.tap()
        }

        // 2回目
        element("bookmark.setMark").tap()
        element("mark.manual").tap()
        element("mark.lineField").tap()
        element("mark.lineField").typeText("二回目の一行。")
        element("mark.save").tap()
        XCTAssertEqual(matchingCount("widgetGuide"), 0)

        // 再起動後3回目
        relaunchPreservingStore()
        element("bookmark.setMark").tap()
        element("mark.manual").tap()
        element("mark.lineField").tap()
        element("mark.lineField").typeText("三回目の一行。")
        element("mark.save").tap()
        XCTAssertEqual(matchingCount("widgetGuide"), 0)
    }

    func test_AC97_LiveActivity予約失敗時はアラートを出さず次回前面復帰時に予約し直す() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                status: "current"
            )
        ])
        let laConfig = """
        {
          "areActivitiesEnabled": true,
          "failScheduleCount": 1
        }
        """
        resetAndLaunch(
            seedJSON: seed,
            now: "2026-10-18T22:00:00+09:00",
            timezone: "Asia/Tokyo",
            liveActivityJSON: laConfig,
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76"]
        )

        element("bookmark.start").tap()
        advanceClock(seconds: 600)
        element("reading.end").tap()
        element("mark.later").tap()

        XCTAssertEqual(app.alerts.count, 0)
        XCTAssertTrue(element("result.summary").waitForExistence(timeout: uiTimeout))

        XCUIDevice.shared.press(.home)
        app.activate()

        let la = readHookJSON("hook.liveActivity")
        let activities = la["activities"] as? [[String: Any]] ?? []
        XCTAssertEqual(activities.count, 1)
        let laRaw = readHookString("hook.liveActivity")
        XCTAssertTrue(laRaw.contains("2026-10-19"))
    }

    func test_AC98_読まなかった晩のLiveActivityは翌朝前面復帰で終了し今夜分を予約する() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                status: "current"
            )
        ])
        resetAndLaunch(seedJSON: seed, now: "2026-10-19T20:00:00+09:00", timezone: "Asia/Tokyo")

        let laInitial = readHookString("hook.liveActivity")
        XCTAssertTrue(laInitial.contains("2026-10-20") || laInitial.contains("19:00:00"))

        transitionLiveActivity("started")

        XCUIDevice.shared.press(.home)
        advanceClock(seconds: 11 * 3600)
        app.activate()

        let laAfter = readHookString("hook.liveActivity")
        XCTAssertTrue(laAfter.contains("2026-10-20"))
    }

    func test_AC99_ウィジェットとしおり画面のVoiceOverラベルに縦書き用字形が含まれない() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                status: "current",
                progressUnit: "page",
                page: 61,
                lastLine: "「下人の行方は、誰も知らなーい。」"
            )
        ])
        resetAndLaunch(
            seedJSON: seed,
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76"]
        )

        let bmLine = element("bookmark.line")
        XCTAssertTrue(bmLine.waitForExistence(timeout: uiTimeout))
        let label = bmLine.label
        XCTAssertEqual(label, "「下人の行方は、誰も知らなーい。」")
        for scalar in label.unicodeScalars {
            XCTAssertFalse((0xFE10...0xFE4F).contains(scalar.value))
        }

        let widgetJSON = readHookJSON("hook.widget")
        let widgetRaw = "\(widgetJSON)"
        XCTAssertTrue(widgetRaw.contains("羅生門"))
        XCTAssertTrue(widgetRaw.contains("61ページ") || widgetRaw.contains("61"))
    }

    func test_AC130_入口時刻前の読書開始で今夜の予約を取り消し終了時に予約を見直す() {
        let seed = makeSeedJSON(
            books: [
                makeSeedBook(
                    id: uuidBookA,
                    title: "羅生門",
                    status: "current"
                )
            ],
            settings: makeSeedSettings(
                flipToStartEnabled: true,
                hideOnWidgets: false,
                entryTime: "21:00",
                widgetGuideShown: true
            )
        )

        // (1) 20:30 開始 -> 背面復帰を挟み 21:05 (35分) で終了 -> 翌晩 2026-10-19 21:00 予約
        resetAndLaunch(seedJSON: seed, now: "2026-10-18T20:30:00+09:00", timezone: "Asia/Tokyo")
        element("bookmark.start").tap()

        XCUIDevice.shared.press(.home)
        advanceClock(seconds: 2100)
        app.activate()

        element("reading.end").tap()
        element("mark.later").tap()

        let recs1 = readStoreRecords()
        XCTAssertEqual(recs1.count, 1)
        XCTAssertEqual(recs1.first?["minutes"] as? Int, 35)

        let la1 = readHookString("hook.liveActivity")
        XCTAssertTrue(la1.contains("2026-10-19"))

        // (2) 20:30 開始 -> 50秒（1分未満）で終了 -> session.tooShort + 今夜 2026-10-18 21:00 予約が戻る
        resetAndLaunch(seedJSON: seed, now: "2026-10-18T20:30:00+09:00", timezone: "Asia/Tokyo")
        element("bookmark.start").tap()
        advanceClock(seconds: 50)
        element("reading.end").tap()

        XCTAssertTrue(element("session.tooShort").waitForExistence(timeout: uiTimeout))
        let la2 = readHookString("hook.liveActivity")
        XCTAssertTrue(la2.contains("2026-10-18"))
    }
}
