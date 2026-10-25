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
        model.store.hookStateString()
    }

    public static func storeJSON(model: ReadingAppModel) -> String {
        model.store.hookStoreJSONString()
    }

    public static func widgetJSON(model: ReadingAppModel) -> String {
        model.store.hookWidgetJSONString()
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
