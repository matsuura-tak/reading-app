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
        let stateStr = UITestHookReadoutBuilder.stateJSON(model: model)
        let storeStr = UITestHookReadoutBuilder.storeJSON(model: model)
        let widgetStr = UITestHookReadoutBuilder.widgetJSON(model: model)
        let verticalStr = UITestHookReadoutBuilder.verticalJSON(model: model)
        let ocrStr = UITestHookReadoutBuilder.ocrJSON(model: model, coordinator: coordinator)
        let ndlStr = UITestHookReadoutBuilder.ndlJSON(model: model)
        let outboundStr = UITestHookReadoutBuilder.outboundJSON(model: model)
        let latencyStr = UITestHookReadoutBuilder.latencyJSON(model: model)
        let liveActivityStr = UITestHookReadoutBuilder.liveActivityJSON(model: model)
        let storekitStr = UITestHookReadoutBuilder.storekitJSON(model: model)
        let intentsStr = UITestHookReadoutBuilder.intentsJSON(model: model)
        let shareCardStr = UITestHookReadoutBuilder.shareCardJSON(model: model)
        let awardsStr = UITestHookReadoutBuilder.awardsJSON(model: model)
        let mediaAuditStr = UITestHookReadoutBuilder.mediaAuditJSON(model: model)
        let a11yStr = UITestHookReadoutBuilder.a11yJSON(model: model, coordinator: coordinator)

        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 2) {
                TextField("hook.cmd", text: $coordinator.commandInputText)
                    .font(.caption2)
                    .accessibilityIdentifier("hook.command.input")
                Button("Run") {
                    let cmd = coordinator.commandInputText
                    coordinator.commandInputText = ""
                    coordinator.executeCommand(cmd, model: model)
                }
                .font(.caption2)
                .accessibilityIdentifier("hook.command.submit")
            }

            Group {
                readoutElement(id: "hook.state", value: stateStr)
                readoutElement(id: "hook.state.json", value: stateStr)
                readoutElement(id: "hook.store", value: storeStr)
                readoutElement(id: "hook.store.json", value: storeStr)
                readoutElement(id: "hook.widget", value: widgetStr)
                readoutElement(id: "hook.widget.json", value: widgetStr)
                readoutElement(id: "hook.vertical.json", value: verticalStr)
                readoutElement(id: "hook.ocr.json", value: ocrStr)
                readoutElement(id: "hook.ndl", value: ndlStr)
                readoutElement(id: "hook.ndl.json", value: ndlStr)
            }

            Group {
                readoutElement(id: "hook.outbound", value: outboundStr)
                readoutElement(id: "hook.outbound.json", value: outboundStr)
                readoutElement(id: "hook.latency", value: latencyStr)
                readoutElement(id: "hook.latency.json", value: latencyStr)
                readoutElement(id: "hook.liveActivity", value: liveActivityStr)
                readoutElement(id: "hook.liveActivity.json", value: liveActivityStr)
                readoutElement(id: "hook.storekit", value: storekitStr)
                readoutElement(id: "hook.storekit.json", value: storekitStr)
                readoutElement(id: "hook.intents", value: intentsStr)
                readoutElement(id: "hook.intents.json", value: intentsStr)
            }

            Group {
                readoutElement(id: "hook.shareCard", value: shareCardStr)
                readoutElement(id: "hook.shareCard.json", value: shareCardStr)
                readoutElement(id: "hook.awards", value: awardsStr)
                readoutElement(id: "hook.awards.json", value: awardsStr)
                readoutElement(id: "hook.mediaAudit", value: mediaAuditStr)
                readoutElement(id: "hook.mediaAudit.json", value: mediaAuditStr)
                readoutElement(id: "hook.a11y.json", value: a11yStr)
            }
        }
        .opacity(0.02)
        .allowsHitTesting(true)
    }

    private func readoutElement(id: String, value: String) -> some View {
        Text(value)
            .font(.caption2)
            .lineLimit(1)
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier(id)
            .accessibilityLabel(value)
            .accessibilityValue(value)
    }
}
#endif
