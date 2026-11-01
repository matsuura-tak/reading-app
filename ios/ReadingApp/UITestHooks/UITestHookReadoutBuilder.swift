#if UITEST_HOOKS
import Foundation
import ReadingCore
import ReadingStore

@MainActor
public enum UITestHookReadoutBuilder {
    private static func encodeJSON<T: Encodable>(_ value: T) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(value),
              let text = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return text
    }

    public static func stateJSON(model: ReadingAppModel) -> String {
        let base = model.store.hookStateString()
        let holds = model.store.loadGate.phases
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { "hold.\($0.key.rawValue)=\($0.value.rawValue)" }
        return ([base] + holds).joined(separator: ";")
    }

    public static func storeJSON(model: ReadingAppModel) -> String {
        // H33：store.load を止めている間、hook.store は空の文字列（H13 の失敗と同じ）。
        if model.store.loadGate.isHolding(.storeLoad) { return "" }
        return model.store.hookStoreJSONString()
    }

    public static func widgetJSON(model: ReadingAppModel) -> String {
        let base = model.store.hookWidgetJSONString()
        guard let showcase = UITestHookCoordinator.shared.widgetShowcaseReadout,
              let baseData = base.data(using: .utf8),
              var object = (try? JSONSerialization.jsonObject(with: baseData)) as? [String: Any],
              let showcaseData = try? JSONEncoder().encode(showcase),
              let showcaseObject = try? JSONSerialization.jsonObject(with: showcaseData) else {
            return base
        }
        object["showcase"] = showcaseObject
        guard let merged = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys, .withoutEscapingSlashes]),
              let text = String(data: merged, encoding: .utf8) else {
            return base
        }
        return text
    }

    public static func verticalJSON(model: ReadingAppModel) -> String {
        let snapshot = model.store.snapshotStore.currentSnapshot
        let comp = VerticalLineLayout.composeWidget(snapshot: snapshot)
        return encodeJSON(UITestHookVerticalPayload(composition: comp))
    }

    public static func ocrJSON(model: ReadingAppModel, coordinator: UITestHookCoordinator) -> String {
        let config = model.store.ocrConfiguration
        let payload = UITestHookOCRPayload(
            mode: config?.mode?.rawValue ?? "empty",
            isHoldReleased: model.store.isOCRHoldReleased,
            selectedColumnIndex: coordinator.selectedOCRColumnIndex,
            detectedPageNumber: config?.detectedPageNumber,
            columnsCount: config?.columns?.count ?? 0
        )
        return encodeJSON(payload)
    }

    public static func ndlJSON(model: ReadingAppModel) -> String {
        model.store.hookNDLJSONString()
    }

    public static func outboundJSON(model: ReadingAppModel) -> String {
        model.store.hookOutboundJSONString()
    }

    public static func latencyJSON(model: ReadingAppModel) -> String {
        model.store.hookLatencyJSONString()
    }

    public static func liveActivityJSON(model: ReadingAppModel) -> String {
        model.store.hookLiveActivityJSONString()
    }

    public static func storekitJSON(model: ReadingAppModel) -> String {
        model.store.hookStoreKitJSONString()
    }

    public static func intentsJSON(model: ReadingAppModel) -> String {
        model.store.hookIntentsJSONString()
    }

    public static func shareCardJSON(model: ReadingAppModel) -> String {
        model.store.hookShareCardJSONString()
    }

    public static func awardsJSON(model: ReadingAppModel) -> String {
        model.store.hookAwardsJSONString()
    }

    public static func mediaAuditJSON(model: ReadingAppModel) -> String {
        model.store.hookMediaAuditJSONString()
    }

    public static func a11yJSON(model: ReadingAppModel, coordinator: UITestHookCoordinator) -> String {
        let payload = UITestHookA11yPayload(
            reduceMotionEnabled: coordinator.reduceMotionEnabled,
            dynamicTypeSize: coordinator.dynamicTypeSizeName,
            activeTab: model.activeTab.rawValue,
            currentScreen: model.currentScreen.rawValue
        )
        return encodeJSON(payload)
    }
}
#endif
