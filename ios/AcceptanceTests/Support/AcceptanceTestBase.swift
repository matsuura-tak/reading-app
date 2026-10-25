import XCTest
import Darwin
import notify

let uiTimeout: TimeInterval = 5.0

class AcceptanceTestBase: XCTestCase {
    var app: XCUIApplication!
    private var accumulatedClockMs: UInt64 = 0
    private var notifyTokens: [String: Int32] = [:]

    let uuidBookA = "00000000-0000-4000-8000-000000000001"
    let uuidBookB = "00000000-0000-4000-8000-000000000002"
    let uuidBookC = "00000000-0000-4000-8000-000000000003"
    let uuidBookD = "00000000-0000-4000-8000-000000000004"
    let uuidBookE = "00000000-0000-4000-8000-000000000005"
    let uuidBookF = "00000000-0000-4000-8000-000000000006"
    let uuidBookG = "00000000-0000-4000-8000-000000000007"
    let uuidBookH = "00000000-0000-4000-8000-000000000008"
    let uuidBookI = "00000000-0000-4000-8000-000000000009"
    let uuidBookJ = "00000000-0000-4000-8000-00000000000a"
    let uuidBookK = "00000000-0000-4000-8000-00000000000b"
    let uuidBookK2 = "00000000-0000-4000-8000-00000000000c"
    let uuidBookL = "00000000-0000-4000-8000-00000000000d"
    let uuidBookM = "00000000-0000-4000-8000-00000000000e"
    let uuidBookP = "00000000-0000-4000-8000-000000000010"
    let uuidBookQ = "00000000-0000-4000-8000-000000000011"
    let uuidBookR = "00000000-0000-4000-8000-000000000012"
    let uuidBookS = "00000000-0000-4000-8000-000000000013"
    let uuidBookT = "00000000-0000-4000-8000-000000000014"

    func makeUUID(_ index: Int) -> String {
        String(format: "00000000-0000-4000-8000-%012d", index)
    }

    func makeRecordUUID(_ index: Int) -> String {
        String(format: "00000000-0000-4000-9000-%012d", index)
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        accumulatedClockMs = 0
        app = XCUIApplication()
        registerDarwinTokens()
    }

    override func tearDown() {
        for (_, token) in notifyTokens {
            notify_cancel(token)
        }
        notifyTokens.removeAll()
        XCUIDevice.shared.orientation = .portrait
        super.tearDown()
    }

    private func registerDarwinTokens() {
        let names = [
            "yomuma.uitest.clock",
            "yomuma.uitest.offline",
            "yomuma.uitest.ocr.release",
            "yomuma.uitest.barcode",
            "yomuma.uitest.liveactivity.transition",
            "yomuma.uitest.storekit.refund",
            "yomuma.uitest.intent.run"
        ]
        for name in names {
            var token: Int32 = 0
            notify_register_check(name, &token)
            notifyTokens[name] = token
        }
    }

    func postDarwinNotification(_ name: String, state: UInt64? = nil) {
        if let state = state, let token = notifyTokens[name] {
            notify_set_state(token, state)
        }
        notify_post(name)
    }

    func resetAndLaunch(
        seedJSON: String? = nil,
        now: String? = nil,
        timezone: String? = nil,
        failSave: String? = nil,
        offline: Bool = false,
        camera: String = "authorized",
        flipUnavailable: Bool = false,
        ocrJSON: String? = nil,
        ndlStubJSON: String? = nil,
        liveActivityJSON: String? = nil,
        awardsJSON: String? = nil,
        storeKitJSON: String? = nil,
        intentJSON: String? = nil,
        extraArgs: [String] = []
    ) {
        accumulatedClockMs = 0
        var args: [String] = ["-uitest-reset", "-uitest-barcode-fake"]
        if let now = now {
            args.append(contentsOf: ["-uitest-now", now])
        }
        if let timezone = timezone {
            args.append(contentsOf: ["-uitest-timezone", timezone])
        }
        if let failSave = failSave {
            args.append(contentsOf: ["-uitest-fail-save", failSave])
        }
        if offline {
            args.append("-uitest-offline")
        }
        if !camera.isEmpty {
            args.append(contentsOf: ["-uitest-camera", camera])
        }
        if flipUnavailable {
            args.append("-uitest-flip-unavailable")
        }
        args.append(contentsOf: extraArgs)

        var env: [String: String] = [:]
        if let seedJSON = seedJSON {
            env["UITEST_SEED"] = seedJSON
        }
        if let ocrJSON = ocrJSON {
            env["UITEST_OCR"] = ocrJSON
        }
        if let ndlStubJSON = ndlStubJSON {
            env["UITEST_NDL_STUB"] = ndlStubJSON
        }
        if let liveActivityJSON = liveActivityJSON {
            env["UITEST_LIVE_ACTIVITY"] = liveActivityJSON
        }
        if let awardsJSON = awardsJSON {
            env["UITEST_AWARDS"] = awardsJSON
        }
        if let storeKitJSON = storeKitJSON {
            env["UITEST_STOREKIT"] = storeKitJSON
        }
        if let intentJSON = intentJSON {
            env["UITEST_INTENT"] = intentJSON
        }

        app.launchArguments = args
        app.launchEnvironment = env
        app.launch()
        assertNoHookError()
    }

    func relaunchPreservingStore(
        now: String? = nil,
        timezone: String? = nil,
        extraArgs: [String] = []
    ) {
        app.terminate()
        var args: [String] = []
        if let now = now {
            accumulatedClockMs = 0
            args.append(contentsOf: ["-uitest-now", now])
        }
        if let timezone = timezone {
            args.append(contentsOf: ["-uitest-timezone", timezone])
        }
        args.append(contentsOf: extraArgs)
        app.launchArguments = args
        app.launchEnvironment = [:]
        app.launch()
        assertNoHookError()
    }

    func assertNoHookError() {
        let errElem = element("hook.error")
        XCTAssertEqual(matchingCount("hook.error"), 0, "Unexpected hook.error: \(errElem.value as? String ?? "")")
    }

    func advanceClock(seconds: Int) {
        accumulatedClockMs += UInt64(max(0, seconds)) * 1000
        postDarwinNotification("yomuma.uitest.clock", state: accumulatedClockMs)
    }

    func advanceClockMs(_ milliseconds: Int) {
        accumulatedClockMs += UInt64(max(0, milliseconds))
        postDarwinNotification("yomuma.uitest.clock", state: accumulatedClockMs)
    }

    func setOffline(_ isOffline: Bool) {
        postDarwinNotification("yomuma.uitest.offline", state: isOffline ? 1 : 0)
    }

    func setOrientation(_ orientation: UIDeviceOrientation) {
        XCUIDevice.shared.orientation = orientation
    }

    func sendBarcode(_ code: String, supplemental: String? = nil) {
        if let firstVal = UInt64(code) {
            postDarwinNotification("yomuma.uitest.barcode", state: firstVal)
        }
        if let supplemental = supplemental, let secondVal = UInt64(supplemental) {
            postDarwinNotification("yomuma.uitest.barcode", state: secondVal)
        }
    }

    func releaseOCR() {
        postDarwinNotification("yomuma.uitest.ocr.release")
    }

    func transitionLiveActivity(_ state: String) {
        let code: UInt64 = (state == "started") ? 1 : 2
        postDarwinNotification("yomuma.uitest.liveactivity.transition", state: code)
    }

    func triggerStoreRefund() {
        postDarwinNotification("yomuma.uitest.storekit.refund", state: 1)
    }

    func runExternalIntent(_ name: String, canContinueInForeground: Bool = true) {
        _ = canContinueInForeground
        let baseCode: UInt64
        switch name {
        case "StartReadingIntent":
            baseCode = 1
        case "EndReadingFromActivityIntent":
            baseCode = 2
        case "WhereStoppedIntent":
            baseCode = 3
        case "ContinueReadingIntent":
            baseCode = 4
        default:
            baseCode = 1
        }
        postDarwinNotification("yomuma.uitest.intent.run", state: baseCode)
    }

    func makeIntentConfigJSON(canContinueInForeground: Bool = true) -> String {
        return "{\"canContinueInForeground\":\(canContinueInForeground ? "true" : "false")}"
    }

    func makeSeedBook(
        id: String,
        isbn13: String? = nil,
        title: String,
        author: String = "",
        publisher: String? = nil,
        label: String? = nil,
        publishedYear: Int? = nil,
        seriesTitle: String? = nil,
        volumeNumber: Int? = nil,
        ndc: String? = nil,
        status: String = "current",
        isEbook: Bool = false,
        isTitlePending: Bool = false,
        progressUnit: String = "page",
        page: Int? = nil,
        location: Int? = nil,
        percent: Int? = nil,
        lastLine: String? = nil,
        createdAt: String = "2026-10-10T21:00:00+09:00",
        updatedAt: String = "2026-10-10T21:00:00+09:00",
        tsundokuAt: String? = nil,
        finishedAt: String? = nil
    ) -> [String: Any] {
        let resolvedTsundokuAt: Any
        if let tsundokuAt = tsundokuAt {
            resolvedTsundokuAt = tsundokuAt
        } else if status == "tsundoku" {
            resolvedTsundokuAt = createdAt
        } else {
            resolvedTsundokuAt = NSNull()
        }

        let resolvedFinishedAt: Any
        if let finishedAt = finishedAt {
            resolvedFinishedAt = finishedAt
        } else if status == "finished" {
            resolvedFinishedAt = updatedAt
        } else {
            resolvedFinishedAt = NSNull()
        }

        return [
            "id": id,
            "isbn13": isbn13 ?? NSNull(),
            "title": title,
            "author": author,
            "publisher": publisher ?? NSNull(),
            "label": label ?? NSNull(),
            "publishedYear": publishedYear ?? NSNull(),
            "seriesTitle": seriesTitle ?? NSNull(),
            "volumeNumber": volumeNumber ?? NSNull(),
            "ndc": ndc ?? NSNull(),
            "status": status,
            "isEbook": isEbook,
            "isTitlePending": isTitlePending,
            "progressUnit": progressUnit,
            "page": page ?? NSNull(),
            "location": location ?? NSNull(),
            "percent": percent ?? NSNull(),
            "lastLine": lastLine ?? NSNull(),
            "createdAt": createdAt,
            "updatedAt": updatedAt,
            "tsundokuAt": resolvedTsundokuAt,
            "finishedAt": resolvedFinishedAt
        ]
    }

    func makeSeedRecord(
        id: String,
        bookId: String,
        startedAt: String = "2026-10-15T21:00:00+09:00",
        endedAt: String = "2026-10-15T21:20:00+09:00",
        minutes: Int? = nil,
        durationMinutes: Int? = nil,
        nightDate: String = "2026-10-15",
        entry: String = "app",
        progressUnit: String = "page",
        startPage: Int? = nil,
        endPage: Int? = nil,
        startLocation: Int? = nil,
        endLocation: Int? = nil,
        startPercent: Int? = nil,
        endPercent: Int? = nil,
        savedLine: String? = nil
    ) -> [String: Any] {
        let resolvedMinutes = minutes ?? durationMinutes ?? 20
        return [
            "id": id,
            "bookId": bookId,
            "startedAt": startedAt,
            "endedAt": endedAt,
            "minutes": resolvedMinutes,
            "nightDate": nightDate,
            "entry": entry,
            "progressUnit": progressUnit,
            "startPage": startPage ?? NSNull(),
            "endPage": endPage ?? NSNull(),
            "startLocation": startLocation ?? NSNull(),
            "endLocation": endLocation ?? NSNull(),
            "startPercent": startPercent ?? NSNull(),
            "endPercent": endPercent ?? NSNull(),
            "savedLine": savedLine ?? NSNull()
        ]
    }

    func makeSeedActiveSession(
        bookId: String,
        startedAt: String,
        entry: String = "app",
        liveActivityId: String? = nil
    ) -> [String: Any] {
        return [
            "bookId": bookId,
            "startedAt": startedAt,
            "entry": entry,
            "liveActivityId": liveActivityId ?? NSNull()
        ]
    }

    func makeSeedSettings(
        flipToStartEnabled: Bool = true,
        hideOnWidgets: Bool = false,
        entryTime: String = "21:00",
        appearanceID: String? = nil,
        appearanceMode: String? = nil,
        isPlusPurchased: Bool? = nil,
        plusPurchased: Bool? = nil,
        widgetGuideShown: Bool = true,
        onboardingCompleted: Bool = true,
        recommendationWeights: [String: [String: Int]]? = nil,
        firstNightCompletedAt: String? = nil,
        seventhNightReachedAt: String? = nil
    ) -> [String: Any] {
        _ = onboardingCompleted
        var dict: [String: Any] = [
            "flipToStartEnabled": flipToStartEnabled,
            "hideOnWidgets": hideOnWidgets,
            "widgetGuideShown": widgetGuideShown,
            "entryTime": entryTime,
            "appearanceID": appearanceID ?? appearanceMode ?? "default",
            "isPlusPurchased": isPlusPurchased ?? plusPurchased ?? false,
            "firstNightCompletedAt": firstNightCompletedAt ?? NSNull(),
            "seventhNightReachedAt": seventhNightReachedAt ?? NSNull()
        ]
        if let recommendationWeights = recommendationWeights {
            dict["recommendationWeights"] = recommendationWeights
        }
        return dict
    }

    func makeSeedJSON(
        books: [[String: Any]] = [],
        records: [[String: Any]] = [],
        activeSession: [String: Any]? = nil,
        settings: [String: Any]? = nil
    ) -> String {
        let payload: [String: Any] = [
            "schemaVersion": 1,
            "books": books,
            "records": records,
            "activeSession": activeSession ?? NSNull(),
            "settings": settings ?? makeSeedSettings()
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let str = String(data: data, encoding: .utf8) else {
            XCTFail("Failed to serialize seed JSON")
            return "{}"
        }
        return str
    }

    func openEntryURL(_ entry: String) {
        if let url = URL(string: "yomuma://open?entry=\(entry)") {
            app.open(url)
        }
    }

    func navigateBackToBookmark() {
        let navBack = app.navigationBars.buttons.firstMatch
        if navBack.exists {
            navBack.tap()
        }
    }

    func element(_ id: String) -> XCUIElement {
        return app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    func matchingCount(_ id: String) -> Int {
        return app.descendants(matching: .any).matching(identifier: id).count
    }

    func readHookString(_ id: String) -> String {
        let el = element(id)
        XCTAssertTrue(el.waitForExistence(timeout: uiTimeout), "Missing hook element: \(id)")
        return (el.value as? String) ?? el.label
    }

    func readHookState() -> [String: String] {
        let raw = readHookString("hook.state")
        var result: [String: String] = [:]
        for pair in raw.split(separator: ";", omittingEmptySubsequences: false) {
            let parts = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            if parts.count == 2 {
                result[String(parts[0])] = String(parts[1])
            }
        }
        return result
    }

    func readHookJSON(_ id: String) -> [String: Any] {
        let raw = readHookString(id)
        guard let data = raw.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("Failed to parse JSON from \(id): \(raw)")
            return [:]
        }
        return obj
    }

    func readStoreState() -> [String: Any] {
        return readHookJSON("hook.store")["state"] as? [String: Any] ?? [:]
    }

    func readStoreBooks() -> [[String: Any]] {
        return readStoreState()["books"] as? [[String: Any]] ?? []
    }

    func readStoreRecords() -> [[String: Any]] {
        return readStoreState()["records"] as? [[String: Any]] ?? []
    }

    func readStoreSettings() -> [String: Any] {
        return readStoreState()["settings"] as? [String: Any] ?? [:]
    }

    func attachScreenshot(name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
