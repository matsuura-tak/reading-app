#if UITEST_HOOKS
import Foundation
import Observation
import UIKit
import Darwin
import ReadingCore
import ReadingStore

@_silgen_name("notify_register_check")
private func c_notify_register_check(_ name: UnsafePointer<CChar>, _ out_token: UnsafeMutablePointer<Int32>) -> UInt32

@_silgen_name("notify_check")
private func c_notify_check(_ token: Int32, _ check: UnsafeMutablePointer<Int32>) -> UInt32

@_silgen_name("notify_get_state")
private func c_notify_get_state(_ token: Int32, _ state64: UnsafeMutablePointer<UInt64>) -> UInt32

@MainActor
@Observable
public final class UITestHookCoordinator {
    public static let shared = UITestHookCoordinator()

    public var commandInputText: String = ""
    public var reduceMotionEnabled: Bool = false
    public var dynamicTypeSizeName: String = "large"
    public var selectedOCRColumnIndex: Int?
    public var barcodeStubString: String?
    public var isFakeBarcodeScannerEnabled: Bool = false

    private weak var activeModel: ReadingAppModel?
    private var isMonitoringInstalled = false
    private var barcodePostCount = 0

    public init() {}

    private func argValue(_ flag: String, in args: [String]) -> String? {
        guard let idx = args.firstIndex(of: flag), idx + 1 < args.count else {
            return nil
        }
        return args[idx + 1]
    }

    public func applyLaunchConfiguration(
        model: ReadingAppModel,
        env: [String: String] = ProcessInfo.processInfo.environment,
        args: [String] = ProcessInfo.processInfo.arguments
    ) {
        self.activeModel = model
        let store = model.store

        let shouldReset = (env["UITEST_RESET"] == "1") || args.contains("-UITEST_RESET") || args.contains("-uitest-reset")
        if shouldReset {
            store.resetAllData()
        }

        isFakeBarcodeScannerEnabled = args.contains("-uitest-barcode-fake") || (env["UITEST_BARCODE_FAKE"] == "1")

        let clockNow = argValue("-uitest-now", in: args) ?? env["UITEST_CLOCK_NOW"]
        if let clockNow, !clockNow.isEmpty {
            store.clock.setNow(iso8601: clockNow)
        }

        let tzIdentifier = argValue("-uitest-timezone", in: args) ?? env["UITEST_TIMEZONE"]
        if let tzIdentifier, !tzIdentifier.isEmpty {
            store.clock.setTimeZone(identifier: tzIdentifier)
        }

        let failSave = argValue("-uitest-fail-save", in: args) ?? env["UITEST_FAIL_SAVE"]
        store.configureFailSave(failSave)

        let widgetSpec = argValue("-uitest-widget", in: args) ?? env["UITEST_WIDGET"]
        store.snapshotStore.configureSpecs(from: widgetSpec)

        let isOfflineArg = args.contains("-uitest-offline") || (env["UITEST_OFFLINE"] == "1") || (env["UITEST_OFFLINE"]?.lowercased() == "true")
        store.isOffline = isOfflineArg

        let cameraMode = argValue("-uitest-camera", in: args) ?? env["UITEST_CAMERA_AUTH"] ?? "authorized"
        store.cameraAuthorization = cameraMode

        let flipUnavailable = args.contains("-uitest-flip-unavailable") || (env["UITEST_FLIP_AVAILABLE"] == "0") || (env["UITEST_FLIP_AVAILABLE"]?.lowercased() == "false")
        store.isFlipAvailable = !flipUnavailable

        let ndlStub = env["UITEST_NDL_STUB"]
        if let ndlStub, !ndlStub.isEmpty {
            store.catalogDB.configure(fromStubJSON: ndlStub)
        } else {
            store.catalogDB.configure(fromStubJSON: "")
        }

        let ocrStub = env["UITEST_OCR"] ?? env["UITEST_OCR_STUB"]
        store.configureOCR(from: ocrStub)

        if let barcodeStub = env["UITEST_BARCODE_STUB"], !barcodeStub.isEmpty {
            barcodeStubString = barcodeStub
        }

        let laStub = env["UITEST_LIVE_ACTIVITY"] ?? env["UITEST_LIVE_ACTIVITY_STUB"]
        store.configureLiveActivity(from: laStub)

        let intentsStub = env["UITEST_INTENT"] ?? env["UITEST_INTENTS_STUB"]
        store.configureIntents(from: intentsStub)

        let awardsStub = env["UITEST_AWARDS"] ?? env["UITEST_AWARDS_OVERRIDE"]
        store.configureAwardsOverride(from: awardsStub)

        if let reduceMotion = env["UITEST_REDUCE_MOTION"] {
            reduceMotionEnabled = (reduceMotion == "1" || reduceMotion.lowercased() == "true")
        }

        if let dtSize = env["UITEST_DYNAMIC_TYPE"], !dtSize.isEmpty {
            dynamicTypeSizeName = dtSize
        }

        let seedJSON = env["UITEST_SEED"] ?? env["UITEST_SEED_JSON"]
        let seedPreset = argValue("-uitest-seed-preset", in: args) ?? env["UITEST_SEED_PRESET"]
        if let seedJSON, !seedJSON.isEmpty {
            try? store.seedFromJSON(seedJSON)
        } else if let seedPreset, !seedPreset.isEmpty {
            try? store.seedPreset(seedPreset)
        } else if !shouldReset {
            store.loadFromDisk()
        }

        let skStub = env["UITEST_STOREKIT"] ?? env["UITEST_STOREKIT_STUB"]
        store.configureStoreKit(from: skStub)

        if let initOrient = env["UITEST_INITIAL_ORIENTATION"], !initOrient.isEmpty {
            store.setOrientation(initOrient, isInitialLaunch: true)
        } else {
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            let devOrient = UIDevice.current.orientation
            if devOrient == .faceDown {
                store.setOrientation("faceDown", isInitialLaunch: true)
            }
        }

        if store.sessionState == .reading {
            model.currentScreen = .sessionActive
        } else if store.currentBook != nil {
            model.currentScreen = .bookmarkCurrent
        } else {
            model.currentScreen = .bookmarkEmpty
        }

        if let openURL = env["UITEST_OPEN_URL"], !openURL.isEmpty {
            store.openEntryURL(openURL)
            if store.sessionState == .reading {
                model.currentScreen = .sessionActive
            }
        }

        installSystemAndDarwinObserversIfNeeded()
        model.notifyHookChanged()
    }

    private func installSystemAndDarwinObserversIfNeeded() {
        guard !isMonitoringInstalled else { return }
        isMonitoringInstalled = true

        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleUIDeviceOrientationChange()
            }
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, let model = self.activeModel else { return }
                model.store.handleDidEnterBackground()
                model.notifyHookChanged()
            }
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, let model = self.activeModel else { return }
                model.store.handleDidBecomeActive()
                model.notifyHookChanged()
            }
        }

        startDarwinPollingThread()
    }

    private func handleUIDeviceOrientationChange() {
        guard let model = activeModel else { return }
        let devOrient = UIDevice.current.orientation
        let mapped: String
        switch devOrient {
        case .faceDown:
            mapped = "faceDown"
        case .faceUp:
            mapped = "faceUp"
        case .landscapeLeft, .landscapeRight:
            mapped = "landscape"
        case .portraitUpsideDown:
            mapped = "portraitUpsideDown"
        default:
            mapped = "portrait"
        }
        model.store.setOrientation(mapped, isInitialLaunch: false)
        model.notifyHookChanged()
    }

    private nonisolated func startDarwinPollingThread() {
        let names = [
            "yomuma.uitest.clock",
            "yomuma.uitest.offline",
            "yomuma.uitest.ocr.release",
            "yomuma.uitest.barcode",
            "yomuma.uitest.liveactivity.transition",
            "yomuma.uitest.storekit.refund",
            "yomuma.uitest.intent.run"
        ]
        var tokens: [Int32] = Array(repeating: 0, count: names.count)
        for (i, name) in names.enumerated() {
            var t: Int32 = 0
            _ = name.withCString { c_notify_register_check($0, &t) }
            var check: Int32 = 0
            _ = c_notify_check(t, &check)
            tokens[i] = t
        }

        let thread = Thread {
            while true {
                for (i, t) in tokens.enumerated() {
                    var check: Int32 = 0
                    if c_notify_check(t, &check) == 0, check != 0 {
                        var state64: UInt64 = 0
                        _ = c_notify_get_state(t, &state64)
                        let notifName = names[i]
                        Task { @MainActor in
                            UITestHookCoordinator.shared.handleDarwinNotification(name: notifName, state: state64)
                        }
                    }
                }
                usleep(5)
            }
        }
        thread.qualityOfService = QualityOfService.userInteractive
        thread.start()
    }

    public func handleDarwinNotification(name: String, state: UInt64) {
        guard let model = activeModel else { return }
        let store = model.store

        switch name {
        case "yomuma.uitest.clock":
            let mode = state >> 62
            if mode == 1 {
                let mag = Int64(state & ((1 << 61) - 1))
                let isNeg = ((state >> 61) & 1) == 1
                let delta = isNeg ? -mag : mag
                handleUIDeviceOrientationChange()
                store.clock.advance(milliseconds: Int(delta))
                store.evaluateFlipOnClockAdvance()
            } else if mode == 2 {
                let epochSec = TimeInterval(state & ((1 << 62) - 1))
                store.clock.setNow(Date(timeIntervalSince1970: epochSec))
            }
        case "yomuma.uitest.offline":
            store.isOffline = (state == 1)
        case "yomuma.uitest.ocr.release":
            store.isOCRHoldReleased = true
        case "yomuma.uitest.barcode":
            barcodePostCount += 1
            let decoded = Self.decodePackedDecimal(state)
            let code = decoded.isEmpty ? (barcodeStubString ?? "") : decoded
            if !code.isEmpty {
                barcodeStubString = code
                model.pendingBarcodes.append(code)
                model.barcodeEventCounter += 1
            }
        case "yomuma.uitest.liveactivity.transition":
            let code = Self.decodeFourCC(state)
            let target: String
            switch code {
            case "strt": target = "started"
            case "read": target = "reading"
            case "endd": target = "ended"
            case "dsms": target = "dismissedBySystem"
            default: target = code
            }
            store.transitionLiveActivity(target)
        case "yomuma.uitest.storekit.refund":
            store.triggerStoreRefund()
        case "yomuma.uitest.intent.run":
            let canFG = ((state >> 32) & 1) == 1
            let code = Self.decodeFourCC(state & 0xFFFF_FFFF)
            let intentName: String
            switch code {
            case "strt": intentName = "StartReadingIntent"
            case "enda": intentName = "EndReadingFromActivityIntent"
            case "wher": intentName = "WhereStoppedIntent"
            case "cont": intentName = "ContinueReadingIntent"
            default: intentName = code
            }
            let log = store.handleExternalIntent("\(intentName):fg=\(canFG ? "1" : "0")")
            if intentName == "EndReadingFromActivityIntent" && store.shouldPresentMarkInputAfterIntentEnd {
                store.shouldPresentMarkInputAfterIntentEnd = false
                model.currentScreen = .bookmarkMarkSelect
                model.activeSheet = .markFlow
            } else if intentName == "StartReadingIntent" && log.outcome == "noCurrentBook" && log.opensApp {
                model.currentScreen = .bookmarkEmpty
            } else if intentName == "ContinueReadingIntent" && log.opensApp {
                model.currentScreen = store.currentBook != nil ? .bookmarkCurrent : .bookmarkEmpty
            }
        default:
            break
        }

        if store.sessionState == .reading {
            model.currentScreen = .sessionActive
        } else if model.currentScreen == .sessionActive {
            model.currentScreen = store.currentBook != nil ? .bookmarkCurrent : .bookmarkEmpty
        }
        model.notifyHookChanged()
    }

    private static func decodePackedDecimal(_ packed: UInt64) -> String {
        let len = Int((packed >> 56) & 0xFF)
        guard len > 0 && len <= 14 else { return "" }
        var digits: [Character] = Array(repeating: "0", count: len)
        var acc = packed & 0x00FF_FFFF_FFFF_FFFF
        for idx in stride(from: len - 1, through: 0, by: -1) {
            let nibble = Int(acc & 0xF)
            digits[idx] = Character(UnicodeScalar(48 + min(9, max(0, nibble)))!)
            acc >>= 4
        }
        return String(digits)
    }

    private static func decodeFourCC(_ code: UInt64) -> String {
        var bytes: [UInt8] = []
        for shift in [24, 16, 8, 0] {
            let b = UInt8((code >> shift) & 0xFF)
            if b != 0 && b != 32 {
                bytes.append(b)
            }
        }
        return String(bytes: bytes, encoding: .utf8) ?? ""
    }

    public func executeCommand(_ rawCommand: String, model: ReadingAppModel) {
        let trimmed = rawCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let store = model.store

        if trimmed.hasPrefix("clock.advance:") {
            let val = String(trimmed.dropFirst("clock.advance:".count))
            if let seconds = Int(val) {
                store.clock.advance(seconds: seconds)
                store.evaluateFlipOnClockAdvance()
            }
        } else if trimmed.hasPrefix("clock.set:") {
            let iso = String(trimmed.dropFirst("clock.set:".count))
            store.clock.setNow(iso8601: iso)
        } else if trimmed.hasPrefix("orientation:") {
            let orient = String(trimmed.dropFirst("orientation:".count))
            store.setOrientation(orient, isInitialLaunch: false)
        } else if trimmed.hasPrefix("url.open:") {
            let urlStr = String(trimmed.dropFirst("url.open:".count))
            store.openEntryURL(urlStr)
        } else if trimmed.hasPrefix("intent:") {
            let payload = String(trimmed.dropFirst("intent:".count))
            _ = store.handleExternalIntent(payload)
        } else if trimmed.hasPrefix("liveActivity.transition:") {
            let target = String(trimmed.dropFirst("liveActivity.transition:".count))
            store.transitionLiveActivity(target)
        } else if trimmed == "app.enterBackground" {
            store.handleDidEnterBackground()
        } else if trimmed == "app.becomeActive" {
            store.handleDidBecomeActive()
        } else if trimmed == "store.refund" {
            store.triggerStoreRefund()
        } else if trimmed == "ocr.release" {
            store.isOCRHoldReleased = true
        } else if trimmed.hasPrefix("failSave:") {
            let spec = String(trimmed.dropFirst("failSave:".count))
            store.configureFailSave(spec)
        }

        if store.sessionState == .reading {
            model.currentScreen = .sessionActive
        }
        model.notifyHookChanged()
    }
}
#endif
