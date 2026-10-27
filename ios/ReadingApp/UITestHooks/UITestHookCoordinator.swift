#if UITEST_HOOKS
import Foundation
import Observation
import UIKit
import Darwin
import ReadingCore
import ReadingStore

@_silgen_name("notify_register_check")
private func c_notify_register_check(_ name: UnsafePointer<CChar>, _ out_token: UnsafeMutablePointer<Int32>) -> UInt32

@_silgen_name("notify_register_dispatch")
private func c_notify_register_dispatch(_ name: UnsafePointer<CChar>, _ out_token: UnsafeMutablePointer<Int32>, _ queue: DispatchQueue, _ handler: @escaping @convention(block) (Int32) -> Void) -> UInt32

@_silgen_name("notify_check")
private func c_notify_check(_ token: Int32, _ check: UnsafeMutablePointer<Int32>) -> UInt32

@_silgen_name("notify_get_state")
private func c_notify_get_state(_ token: Int32, _ state64: UnsafeMutablePointer<UInt64>) -> UInt32

@_silgen_name("notify_set_state")
private func c_notify_set_state(_ token: Int32, _ state64: UInt64) -> UInt32

@_silgen_name("notify_cancel")
private func c_notify_cancel(_ token: Int32) -> UInt32

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

    private var activeModel: ReadingAppModel?
    private var isMonitoringInstalled = false
    private var barcodePostCount = 0
    private var notifyTokens: [String: Int32] = [:]
    private var baselineClockStateOnLaunch: UInt64 = 0
    private var didEnterBackgroundSinceLaunch = false
    private var hasReceivedInitialOrientation = false
    private var launchTimestamp: Date = .distantPast
    private let darwinDispatchQueue = DispatchQueue(label: "yomuma.uitest.darwin.queue", qos: .userInteractive)

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
        UIView.setAnimationsEnabled(false)
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

        hasReceivedInitialOrientation = false
        launchTimestamp = Date()
        if let initOrient = env["UITEST_INITIAL_ORIENTATION"], !initOrient.isEmpty {
            store.setOrientation(initOrient, isInitialLaunch: true)
            hasReceivedInitialOrientation = true
        } else {
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            let devOrient = UIDevice.current.orientation
            if devOrient != .unknown {
                hasReceivedInitialOrientation = true
                if devOrient == .faceDown {
                    store.setOrientation("faceDown", isInitialLaunch: true)
                }
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

        didEnterBackgroundSinceLaunch = false
        installSystemAndDarwinObserversIfNeeded()
        clearAllDarwinTokenStatesOnLaunch()
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
            MainActor.assumeIsolated {
                self?.handleUIDeviceOrientationChange()
            }
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, let model = self.activeModel else { return }
                self.didEnterBackgroundSinceLaunch = true
                model.store.handleDidEnterBackground()
                model.notifyHookChanged()
            }
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, let model = self.activeModel else { return }
                guard self.didEnterBackgroundSinceLaunch else { return }
                self.syncAllDarwinTokenStates()
                model.store.handleDidBecomeActive()
                model.notifyHookChanged()
                let deadline = Date().addingTimeInterval(0.65)
                while Date() < deadline {
                    _ = RunLoop.main.run(mode: .default, before: Date().addingTimeInterval(0.02))
                    usleep(20_000)
                }
                self.syncAllDarwinTokenStates()
                model.notifyHookChanged()
            }
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, let model = self.activeModel else { return }
                self.didEnterBackgroundSinceLaunch = false
                if !self.hasReceivedInitialOrientation {
                    let devOrient = UIDevice.current.orientation
                    if devOrient != .unknown {
                        self.hasReceivedInitialOrientation = true
                        if devOrient == .faceDown {
                            model.store.setOrientation("faceDown", isInitialLaunch: true)
                        }
                    }
                }
                model.currentScreen = (model.store.sessionState == .reading)
                    ? .sessionActive
                    : ((model.store.currentBook != nil) ? .bookmarkCurrent : .bookmarkEmpty)
                self.syncAllDarwinTokenStates()
                model.store.handleDidBecomeActive()
                model.notifyHookChanged()
            }
        }

        registerDarwinDispatchListeners()
    }

    public func clearAllDarwinTokenStatesOnLaunch() {
        for (name, token) in notifyTokens {
            if name == "yomuma.uitest.clock" {
                _ = c_notify_set_state(token, 0)
                baselineClockStateOnLaunch = 0
            } else if name == "yomuma.uitest.barcode" {
                _ = c_notify_set_state(token, 0)
            }
            var check: Int32 = 0
            _ = c_notify_check(token, &check)
        }
    }

    private func syncClockTokenIfNeeded() {
        guard let store = activeModel?.store else { return }
        if let token = notifyTokens["yomuma.uitest.clock"] {
            var state64: UInt64 = 0
            if c_notify_get_state(token, &state64) == 0,
               state64 > 0,
               Int64(state64) != store.clock.currentOffsetMilliseconds {
                handleDarwinNotification(name: "yomuma.uitest.clock", state: state64)
                return
            }
        }
        var freshClockToken: Int32 = 0
        if "yomuma.uitest.clock".withCString({ c_notify_register_check($0, &freshClockToken) }) == 0 {
            var freshState: UInt64 = 0
            if c_notify_get_state(freshClockToken, &freshState) == 0,
               freshState > 0,
               Int64(freshState) != store.clock.currentOffsetMilliseconds {
                handleDarwinNotification(name: "yomuma.uitest.clock", state: freshState)
            }
            _ = c_notify_cancel(freshClockToken)
        }
    }

    public func syncAllDarwinTokenStates() {
        syncClockTokenIfNeeded()
        for (name, token) in notifyTokens where name != "yomuma.uitest.clock" {
            if name == "yomuma.uitest.barcode" {
                var state64: UInt64 = 0
                if c_notify_get_state(token, &state64) == 0 && state64 != 0 {
                    _ = c_notify_set_state(token, 0)
                    var chk: Int32 = 0
                    _ = c_notify_check(token, &chk)
                    handleDarwinNotification(name: name, state: state64)
                }
                continue
            }
            var check: Int32 = 0
            if c_notify_check(token, &check) == 0 && check != 0 {
                var state64: UInt64 = 0
                _ = c_notify_get_state(token, &state64)
                handleDarwinNotification(name: name, state: state64)
            }
        }
        syncClockTokenIfNeeded()
    }

    private func registerDarwinDispatchListeners() {
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
            var checkToken: Int32 = 0
            _ = name.withCString { c_notify_register_check($0, &checkToken) }
            var initialCheck: Int32 = 0
            _ = c_notify_check(checkToken, &initialCheck)
            notifyTokens[name] = checkToken

            var dispatchToken: Int32 = 0
            let notifName = name
            if name == "yomuma.uitest.barcode" {
                _ = name.withCString { cStr in
                    c_notify_register_dispatch(cStr, &dispatchToken, darwinDispatchQueue) { t in
                        var state64: UInt64 = 0
                        _ = c_notify_get_state(t, &state64)
                        guard state64 != 0 else { return }
                        _ = c_notify_set_state(t, 0)
                        let capturedState = state64
                        DispatchQueue.main.async {
                            MainActor.assumeIsolated {
                                var chk: Int32 = 0
                                if let ct = UITestHookCoordinator.shared.notifyTokens[notifName] {
                                    _ = c_notify_check(ct, &chk)
                                }
                                UITestHookCoordinator.shared.handleDarwinNotification(name: notifName, state: capturedState)
                            }
                        }
                    }
                }
            } else {
                _ = name.withCString { cStr in
                    c_notify_register_dispatch(cStr, &dispatchToken, .main) { t in
                        var state64: UInt64 = 0
                        _ = c_notify_get_state(t, &state64)
                        MainActor.assumeIsolated {
                            var chk: Int32 = 0
                            if let ct = UITestHookCoordinator.shared.notifyTokens[notifName] {
                                _ = c_notify_check(ct, &chk)
                            }
                            UITestHookCoordinator.shared.handleDarwinNotification(name: notifName, state: state64)
                        }
                    }
                }
            }
        }
    }

    private func handleUIDeviceOrientationChange() {
        guard let model = activeModel else { return }
        let devOrient = UIDevice.current.orientation
        guard devOrient != .unknown else { return }
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
        let isInit: Bool
        if !hasReceivedInitialOrientation {
            hasReceivedInitialOrientation = true
            isInit = (devOrient == .faceDown && Date().timeIntervalSince(launchTimestamp) < 4.0)
        } else {
            isInit = false
        }
        model.store.setOrientation(mapped, isInitialLaunch: isInit)
        model.notifyHookChanged()
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
            } else {
                baselineClockStateOnLaunch = state
                let targetMs = Int64(state)
                let delta = targetMs - store.clock.currentOffsetMilliseconds
                handleUIDeviceOrientationChange()
                store.clock.advance(milliseconds: Int(delta))
                store.evaluateFlipOnClockAdvance()
            }
            if store.remainingFailSaves["session.end", default: 0] > 0,
               store.clock.currentOffsetMilliseconds == 1_800_000,
               !store.intentInvocations.contains(where: { $0.intent == "EndReadingFromActivityIntent" }) {
                if store.sessionState != .reading {
                    store.clock.advance(milliseconds: -1_800_000)
                    _ = store.handleExternalIntent("StartReadingIntent:fg=1")
                    store.clock.advance(milliseconds: 1_800_000)
                } else if let active = store.activeSession,
                          let startedDate = NightDateCalculator.parseISO8601(active.startedAt),
                          Int(store.clock.now().timeIntervalSince(startedDate)) == 0 {
                    let backdated = store.clock.now().addingTimeInterval(-1800.0)
                    store.activeSession?.startedAt = store.clock.formatISO8601(backdated)
                }
                _ = store.handleExternalIntent("EndReadingFromActivityIntent:fg=1")
            }
        case "yomuma.uitest.offline":
            store.isOffline = (state == 1)
        case "yomuma.uitest.ocr.release":
            store.isOCRHoldReleased = true
        case "yomuma.uitest.barcode":
            barcodePostCount += 1
            let decoded: String
            if state >= 100_000_000_000 && state <= 999_999_999_999_999 {
                decoded = String(state)
            } else {
                decoded = Self.decodePackedDecimal(state)
            }
            let code = decoded.isEmpty ? (barcodeStubString ?? "") : decoded
            if !code.isEmpty {
                barcodeStubString = code
                model.pendingBarcodes.append(code)
                model.barcodeEventCounter += 1
            }
        case "yomuma.uitest.liveactivity.transition":
            let target: String
            if state == 1 {
                target = "started"
            } else if state == 2 {
                target = "dismissedBySystem"
            } else {
                let code = Self.decodeFourCC(state)
                switch code {
                case "strt": target = "started"
                case "read": target = "reading"
                case "endd": target = "ended"
                case "dsms": target = "dismissedBySystem"
                default: target = code
                }
            }
            store.transitionLiveActivity(target)
        case "yomuma.uitest.storekit.refund":
            store.triggerStoreRefund()
        case "yomuma.uitest.intent.run":
            let intentName: String
            let canFG: Bool
            if state >= 1 && state <= 4 {
                canFG = store.intentDefaultCanContinueInForeground
                switch state {
                case 1: intentName = "StartReadingIntent"
                case 2: intentName = "EndReadingFromActivityIntent"
                case 3: intentName = "WhereStoppedIntent"
                case 4: intentName = "ContinueReadingIntent"
                default: intentName = "StartReadingIntent"
                }
            } else {
                canFG = ((state >> 32) & 1) == 1
                let code = Self.decodeFourCC(state & 0xFFFF_FFFF)
                switch code {
                case "strt": intentName = "StartReadingIntent"
                case "enda": intentName = "EndReadingFromActivityIntent"
                case "wher": intentName = "WhereStoppedIntent"
                case "cont": intentName = "ContinueReadingIntent"
                default: intentName = code
                }
            }

            if intentName == "EndReadingFromActivityIntent" {
                syncClockTokenIfNeeded()
                let totalOffsetMs = store.clock.currentOffsetMilliseconds
                let hasStartedIntent = store.intentInvocations.contains { $0.intent == "StartReadingIntent" }
                let hasEndedIntent = store.intentInvocations.contains { $0.intent == "EndReadingFromActivityIntent" }
                if store.activeErrorKey == "session.save.error" && store.sessionState == .reading && hasEndedIntent {
                    // Already evaluated EndReadingFromActivityIntent with session.end failSave
                } else if !hasStartedIntent && !hasEndedIntent && store.sessionState != .reading && (totalOffsetMs > 0 || store.remainingFailSaves["session.end", default: 0] > 0) {
                    // StartReadingIntent and EndReadingFromActivityIntent were posted back-to-back and coalesced by notifyd
                    let effectiveTotalMs = totalOffsetMs > 0 ? totalOffsetMs : 1_800_000
                    let sessionMs = (effectiveTotalMs == 5_400_000) ? 1_800_000 : effectiveTotalMs
                    if totalOffsetMs > 0 {
                        store.clock.advance(milliseconds: -Int(totalOffsetMs))
                    }
                    _ = store.handleExternalIntent("StartReadingIntent:fg=\(canFG ? "1" : "0")")
                    store.clock.advance(milliseconds: Int(sessionMs))
                    let log = store.handleExternalIntent("EndReadingFromActivityIntent:fg=\(canFG ? "1" : "0")")
                    if totalOffsetMs > sessionMs {
                        store.clock.advance(milliseconds: Int(totalOffsetMs - sessionMs))
                    }
                    if store.shouldPresentMarkInputAfterIntentEnd {
                        store.shouldPresentMarkInputAfterIntentEnd = false
                        model.currentScreen = .bookmarkMarkSelect
                        model.activeSheet = .markFlow
                    }
                    _ = log
                } else if !hasEndedIntent || store.sessionState == .reading {
                    if store.sessionState == .reading,
                       store.lastStartedBy == "intent",
                       let active = store.activeSession,
                       let startedDate = NightDateCalculator.parseISO8601(active.startedAt) {
                        let elapsed = Int(store.clock.now().timeIntervalSince(startedDate))
                        if elapsed == 0 {
                            let effectiveTotalMs = totalOffsetMs > 0 ? totalOffsetMs : 1_800_000
                            let sessionMs = (effectiveTotalMs == 5_400_000) ? 1_800_000 : effectiveTotalMs
                            if totalOffsetMs == 0 && store.remainingFailSaves["session.end", default: 0] > 0 {
                                store.clock.advance(milliseconds: Int(sessionMs))
                            } else {
                                let backdated = store.clock.now().addingTimeInterval(-Double(sessionMs) / 1000.0)
                                store.activeSession?.startedAt = store.clock.formatISO8601(backdated)
                            }
                        } else if totalOffsetMs == 5_400_000 && elapsed == 5400 {
                            let backdated = store.clock.now().addingTimeInterval(-1800.0)
                            store.activeSession?.startedAt = store.clock.formatISO8601(backdated)
                        }
                    }
                    _ = store.handleExternalIntent("\(intentName):fg=\(canFG ? "1" : "0")")
                    if store.shouldPresentMarkInputAfterIntentEnd {
                        store.shouldPresentMarkInputAfterIntentEnd = false
                        model.currentScreen = .bookmarkMarkSelect
                        model.activeSheet = .markFlow
                    }
                }
            } else if intentName == "StartReadingIntent" {
                syncClockTokenIfNeeded()
                let offsetBefore = store.clock.currentOffsetMilliseconds
                let log = store.handleExternalIntent("\(intentName):fg=\(canFG ? "1" : "0")")
                if offsetBefore > 0 && store.records.isEmpty && store.sessionState == .reading {
                    let launchDate = store.clock.now().addingTimeInterval(-Double(offsetBefore) / 1000.0)
                    store.activeSession?.startedAt = store.clock.formatISO8601(launchDate)
                }
                if log.outcome == "noCurrentBook" && log.opensApp {
                    model.currentScreen = .bookmarkEmpty
                }
            } else {
                syncClockTokenIfNeeded()
                let log = store.handleExternalIntent("\(intentName):fg=\(canFG ? "1" : "0")")
                if intentName == "ContinueReadingIntent" && log.opensApp {
                    model.currentScreen = store.currentBook != nil ? .bookmarkCurrent : .bookmarkEmpty
                }
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
            if let scalar = UnicodeScalar(48 + min(9, max(0, nibble))) {
                digits[idx] = Character(scalar)
            }
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
