import XCTest
import Darwin
import notify

let uiTimeout: TimeInterval = 5.0

class AcceptanceTestBase: XCTestCase {
    var app: XCUIApplication!
    private var accumulatedClockMs: UInt64 = 0
    private var notifyTokens: [String: Int32] = [:]

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
        let code: UInt64
        switch name {
        case "StartReadingIntent":
            code = 1
        case "EndReadingFromActivityIntent":
            code = 2
        case "WhereStoppedIntent":
            code = 3
        case "ContinueReadingIntent":
            code = 4
        default:
            code = 1
        }
        postDarwinNotification("yomuma.uitest.intent.run", state: code)
    }

    func openEntryURL(_ entry: String) {
        if let url = URL(string: "yomuma://open?entry=\(entry)") {
            app.open(url)
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

    func readHookJSON(_ id: String) -> [String: Any] {
        let raw = readHookString(id)
        guard let data = raw.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("Failed to parse JSON from \(id): \(raw)")
            return [:]
        }
        return obj
    }

    func attachScreenshot(name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
