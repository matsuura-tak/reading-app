#if UITEST_HOOKS
import SwiftUI
import ReadingCore
import ReadingStore

public struct UITestHookOverlayView: View {
    @Bindable var model: ReadingAppModel
    @Bindable var coordinator: UITestHookCoordinator

    public init(model: ReadingAppModel, coordinator: UITestHookCoordinator = .shared) {
        self.model = model
        self.coordinator = coordinator
    }

    public var body: some View {
        let _ = model.hookGeneration
        let _ = model.store.books.count
        let _ = model.store.records.count
        let _ = model.store.books.first?.title
        let _ = model.store.books.first?.isTitlePending
        let _ = model.store.books.first?.currentPage
        let _ = model.store.books.first?.lastSavedLine
        let _ = model.store.sessionState
        let _ = model.store.hapticCount
        let _ = model.store.activeErrorKey
        let _ = model.store.activeNoticeKey
        let _ = model.store.storeStatusMessageKey
        let _ = model.store.settings.isPlusPurchased
        let _ = model.store.settings.appearanceID
        let _ = model.store.openedURLs.count
        let _ = model.store.shareCards.count
        let _ = model.store.intentInvocations.count
        let stateStr = UITestHookReadoutBuilder.stateJSON(model: model)
        let storeStr = UITestHookReadoutBuilder.storeJSON(model: model)
        let widgetStr = UITestHookReadoutBuilder.widgetJSON(model: model)
        let outboundStr = UITestHookReadoutBuilder.outboundJSON(model: model)
        let liveActivityStr = UITestHookReadoutBuilder.liveActivityJSON(model: model)
        let storekitStr = UITestHookReadoutBuilder.storekitJSON(model: model)
        let intentsStr = UITestHookReadoutBuilder.intentsJSON(model: model)
        let shareCardStr = UITestHookReadoutBuilder.shareCardJSON(model: model)
        let awardsStr = UITestHookReadoutBuilder.awardsJSON(model: model)
        let mediaAuditStr = UITestHookReadoutBuilder.mediaAuditJSON(model: model)

        VStack(alignment: .leading, spacing: 0) {
            readoutElement(id: "hook.state", value: stateStr)
            readoutElement(id: "hook.store", value: storeStr)
            readoutElement(id: "hook.widget", value: widgetStr)
            readoutElement(id: "hook.outbound", value: outboundStr)
            readoutElement(id: "hook.liveActivity", value: liveActivityStr)
            readoutElement(id: "hook.storekit", value: storekitStr)
            readoutElement(id: "hook.intents", value: intentsStr)
            readoutElement(id: "hook.shareCard", value: shareCardStr)
            readoutElement(id: "hook.awards", value: awardsStr)
            readoutElement(id: "hook.mediaAudit", value: mediaAuditStr)
        }
        .opacity(0.02)
        .allowsHitTesting(false)
    }

    private func readoutElement(id: String, value: String) -> some View {
        Text(id)
            .font(.caption2)
            .frame(width: 1, height: 1)
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier(id)
            .accessibilityLabel(id)
            .accessibilityValue(value)
    }
}
#endif
