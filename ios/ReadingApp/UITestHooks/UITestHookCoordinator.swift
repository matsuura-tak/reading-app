#if UITEST_HOOKS
import Foundation
import Observation
import ReadingCore
import ReadingStore

@MainActor
@Observable
public final class UITestHookCoordinator {
    public static let shared = UITestHookCoordinator()

    public var commandInputText: String = ""
    public var reduceMotionEnabled: Bool = false
    public var dynamicTypeSizeName: String = "large"
    public var selectedOCRColumnIndex: Int?
    public var barcodeStubString: String?

    public init() {}

    public func applyLaunchConfiguration(
        model: ReadingAppModel,
        env: [String: String] = ProcessInfo.processInfo.environment,
        args: [String] = ProcessInfo.processInfo.arguments
    ) {
        let store = model.store
        let shouldReset = (env["UITEST_RESET"] == "1") || args.contains("-UITEST_RESET")
        if shouldReset {
            store.resetAllData()
        }

        if let clockNow = env["UITEST_CLOCK_NOW"], !clockNow.isEmpty {
            store.clock.setNow(iso8601: clockNow)
        }

        if let failSave = env["UITEST_FAIL_SAVE"], !failSave.isEmpty {
            store.configureFailSave(failSave)
        }

        if let ndlStub = env["UITEST_NDL_STUB"], !ndlStub.isEmpty {
            store.catalogDB.configure(fromStubJSON: ndlStub)
        }

        if let offline = env["UITEST_OFFLINE"] {
            store.isOffline = (offline == "1" || offline.lowercased() == "true")
        }

        if let cameraAuth = env["UITEST_CAMERA_AUTH"], !cameraAuth.isEmpty {
            store.cameraAuthorization = cameraAuth
        }

        if let ocrStub = env["UITEST_OCR_STUB"], !ocrStub.isEmpty,
           let ocrData = ocrStub.data(using: .utf8),
           let decodedOCR = try? JSONDecoder().decode(H23OCRStubConfig.self, from: ocrData) {
            store.ocrConfiguration = decodedOCR
            store.isOCRHoldReleased = false
        }

        if let barcodeStub = env["UITEST_BARCODE_STUB"], !barcodeStub.isEmpty {
            barcodeStubString = barcodeStub
        }

        if let flipAvail = env["UITEST_FLIP_AVAILABLE"] {
            store.isFlipAvailable = (flipAvail != "0" && flipAvail.lowercased() != "false")
        }

        if let initOrient = env["UITEST_INITIAL_ORIENTATION"], !initOrient.isEmpty {
            store.setOrientation(initOrient, isInitialLaunch: true)
        }

        if let laStub = env["UITEST_LIVE_ACTIVITY_STUB"], !laStub.isEmpty {
            store.configureLiveActivity(from: laStub)
        }

        if let skStub = env["UITEST_STOREKIT_STUB"], !skStub.isEmpty,
           let skData = skStub.data(using: .utf8),
           let skObj = try? JSONSerialization.jsonObject(with: skData) as? [String: Any] {
            if let canPay = skObj["canMakePayments"] as? Bool {
                store.storeCanMakePayments = canPay
            }
            if let prodAvail = skObj["productLoadAvailable"] as? Bool {
                store.storeProductLoadAvailable = prodAvail
            }
            if let purchaseOut = skObj["purchaseOutcome"] as? String {
                store.storePurchaseOutcome = purchaseOut
            }
            if let restoreOut = skObj["restoreOutcome"] as? String {
                store.storeRestoreOutcome = restoreOut
            }
        }

        if let intentsStub = env["UITEST_INTENTS_STUB"], !intentsStub.isEmpty {
            store.configureIntents(from: intentsStub)
        }

        if let awardsStub = env["UITEST_AWARDS_OVERRIDE"], !awardsStub.isEmpty {
            store.configureAwardsOverride(from: awardsStub)
        }

        if let reduceMotion = env["UITEST_REDUCE_MOTION"] {
            reduceMotionEnabled = (reduceMotion == "1" || reduceMotion.lowercased() == "true")
        }

        if let dtSize = env["UITEST_DYNAMIC_TYPE"], !dtSize.isEmpty {
            dynamicTypeSizeName = dtSize
        }

        if let seedJSON = env["UITEST_SEED_JSON"], !seedJSON.isEmpty {
            try? store.seedFromJSON(seedJSON)
        } else if let seedPreset = env["UITEST_SEED_PRESET"], !seedPreset.isEmpty {
            try? store.seedPreset(seedPreset)
        } else if !shouldReset {
            store.loadFromDisk()
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

        model.notifyHookChanged()
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
