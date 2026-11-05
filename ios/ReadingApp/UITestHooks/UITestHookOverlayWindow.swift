#if UITEST_HOOKS
import SwiftUI
import UIKit
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
        if coordinator.areReadoutsEnabled {
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
            let _ = coordinator.widgetShowcaseReadout
            let _ = model.store.loadGate.phases
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

            ZStack(alignment: .topLeading) {
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
            .allowsHitTesting(false)
        }
    }

    private func readoutElement(id: String, value: String) -> some View {
        HookReadoutAccessibleView(id: id, value: value)
            .frame(minWidth: 44, maxWidth: 44, minHeight: 44, maxHeight: 44)
    }
}

struct HookReadoutAccessibleView: UIViewRepresentable {
    let id: String
    let value: String

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        view.isAccessibilityElement = true
        view.accessibilityTraits = .none
        view.accessibilityIdentifier = id
        view.accessibilityLabel = id
        view.accessibilityValue = value
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        uiView.accessibilityIdentifier = id
        uiView.accessibilityLabel = id
        uiView.accessibilityValue = value
    }
}

// MARK: - H22 の撮影用の見本（-uitest-widget-show）

/// `-uitest-widget-show <面>:<幅>x<高さ>[:<種類>]` を契約 H22 の文法どおりに読んだ結果。
public struct UITestHookWidgetShowcaseSpec: Equatable, Sendable {
    public enum Surface: String, Sendable {
        case accessoryRectangular, systemSmall, liveActivity, control, snippet

        var allowedVariants: [String] {
            switch self {
            case .accessoryRectangular, .systemSmall: return ["normal", "placeholder"]
            case .liveActivity: return ["waiting", "reading", "ended"]
            case .control: return ["startReading"]
            case .snippet: return ["whereStopped"]
            }
        }

        var defaultVariant: String? {
            switch self {
            case .accessoryRectangular, .systemSmall: return "normal"
            case .liveActivity: return nil
            case .control: return "startReading"
            case .snippet: return "whereStopped"
            }
        }

        /// 中身に合わせ、指定の高さを上限とする面。
        var fitsContentHeight: Bool { self == .liveActivity || self == .snippet }
    }

    public let raw: String
    public let surface: Surface
    public let width: Double
    public let height: Double
    public let variant: String

    /// 読めなければ `.failure("H22:<値>")`。
    public static func parse(_ raw: String) -> Result<UITestHookWidgetShowcaseSpec, UITestHookShowcaseError> {
        let parts = raw.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 2 || parts.count == 3, let surface = Surface(rawValue: parts[0]) else {
            return .failure(UITestHookShowcaseError(value: "H22:\(raw)"))
        }
        let dims = parts[1].split(separator: "x", omittingEmptySubsequences: false).map(String.init)
        guard dims.count == 2, let width = Double(dims[0]), let height = Double(dims[1]),
              width.isFinite, height.isFinite, width > 0, height > 0 else {
            return .failure(UITestHookShowcaseError(value: "H22:\(raw)"))
        }
        if surface == .liveActivity && height > 160 {
            return .failure(UITestHookShowcaseError(value: "H22:\(raw)"))
        }
        let variant: String
        if parts.count == 3 {
            guard surface.allowedVariants.contains(parts[2]) else {
                return .failure(UITestHookShowcaseError(value: "H22:\(raw)"))
            }
            variant = parts[2]
        } else if let fallback = surface.defaultVariant {
            variant = fallback
        } else {
            return .failure(UITestHookShowcaseError(value: "H22:\(raw)"))
        }
        return .success(UITestHookWidgetShowcaseSpec(raw: raw, surface: surface, width: width, height: height, variant: variant))
    }
}

public struct UITestHookShowcaseError: Error, Equatable, Sendable {
    public let value: String
}

/// hook.widget の `showcase`（contracts/hooks/h22-widget.schema.json の $defs/showcase）。
public struct UITestHookWidgetShowcaseReadout: Codable, Equatable, Sendable {
    public var spec: String
    public var surface: String
    public var variant: String
    public var viewType: String
    public var requestedWidth: Double
    public var requestedHeight: Double
    public var canvasWidth: Double
    public var canvasHeight: Double
    public var idealHeight: Double
    public var contentOverflow: Bool
    public var colorScheme: String
    public var dynamicTypeSize: String
}

private func showcaseTypeName<T>(_ type: T.Type) -> String {
    let full = String(describing: type)
    return full.split(separator: "<").first.map(String.init) ?? full
}

/// 拡張と同じ View の型を、実寸の枠（hook.widget.canvas）に1つだけ描く。
public struct UITestHookWidgetShowcaseView: View {
    @Bindable var model: ReadingAppModel
    let spec: UITestHookWidgetShowcaseSpec
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var idealHeight: CGFloat = 0

    public init(model: ReadingAppModel, spec: UITestHookWidgetShowcaseSpec) {
        self.model = model
        self.spec = spec
    }

    /// 拡張と同じ読み方（UITEST_WIDGET_SNAPSHOT があればその中身）。H22 の読み出しと同じ関数。
    private var readResult: WidgetSnapshotReadResult {
        let _ = model.hookGeneration
        return model.store.snapshotStore.readForRender().result
    }

    private var snapshot: WidgetSnapshot {
        readResult.snapshot ?? WidgetSnapshot()
    }

    /// W-3・W-5 は写しのファイルを使わない（ADR 0002）。アプリの中の今の本の写しから作る。
    private var appSnapshot: WidgetSnapshot {
        let _ = model.hookGeneration
        return model.store.snapshotStore.currentSnapshot
    }

    private var colorScheme: ColorScheme {
        spec.surface == .accessoryRectangular ? .dark : systemColorScheme
    }

    private var canvasSize: CGSize {
        let width = CGFloat(spec.width)
        let height = CGFloat(spec.height)
        guard spec.surface.fitsContentHeight else { return CGSize(width: width, height: height) }
        return CGSize(width: width, height: idealHeight > 0 ? min(idealHeight, height) : height)
    }

    public var body: some View {
        ZStack {
            rootBackground
                .ignoresSafeArea()
            // 枠は実寸（契約 H22）。大きい文字で中身が枠を超えても、XCUITest の `hook.widget.canvas` の frame は
            // 子の要素を合わせた大きさにならず、枠の大きさのままにする（G3 r3：AX5 で 170→171.67、160→191 になった）。
            // 動かないスクロールの入れ物は自分の大きさを要素の frame に持ち、はみ出した中身は枠で切る。
            ScrollView(.vertical) {
                // 固定の面は枠の高さで描く（中身に合わせる面は中身の高さ。はみ出せば枠で切れる）。
                surface
                    .frame(
                        width: canvasSize.width,
                        height: spec.surface.fitsContentHeight ? nil : canvasSize.height,
                        alignment: .topLeading
                    )
            }
            .scrollDisabled(true)
            .scrollIndicators(.hidden)
            .frame(width: canvasSize.width, height: canvasSize.height, alignment: .topLeading)
            .background(canvasBackground)
            .clipped()
            .accessibilityIdentifier("hook.widget.canvas")
                .background(alignment: .top) {
                    surface
                        .frame(width: canvasSize.width)
                        .fixedSize(horizontal: false, vertical: true)
                        .hidden()
                        .accessibilityHidden(true)
                        .onGeometryChange(for: CGFloat.self, of: { $0.size.height }, action: { newValue in
                            idealHeight = newValue
                            publishReadout()
                        })
                }
        }
        .environment(\.colorScheme, colorScheme)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("hook.widget.showcase")
        .onAppear { publishReadout() }
    }

    private var rootBackground: Color {
        spec.surface == .accessoryRectangular ? Color.black : Color(uiColor: .systemBackground)
    }

    private var canvasBackground: Color {
        switch spec.surface {
        case .accessoryRectangular: return Color.black
        case .systemSmall: return ThemePalette(appearanceID: snapshot.appearanceID).bgPrimary
        case .liveActivity: return Color("DefaultBackgroundSecondary")
        case .control: return Color(uiColor: .secondarySystemFill)
        case .snippet: return Color(uiColor: .secondarySystemBackground)
        }
    }

    private var size: CGSize { CGSize(width: spec.width, height: spec.height) }

    @ViewBuilder
    private var surface: some View {
        switch spec.surface {
        case .accessoryRectangular:
            if spec.variant == "placeholder" {
                ReadingLockScreenWidgetView(family: .accessoryRectangular, snapshot: ReadingWidgetPlaceholder.snapshot, size: size, contentMargins: ReadingWidgetMetrics.lockScreenContentMargins)
                    .redacted(reason: .placeholder)
            } else {
                ReadingLockScreenWidgetView(family: .accessoryRectangular, snapshot: snapshot, unavailableReason: readResult.unavailableReason, size: size, contentMargins: ReadingWidgetMetrics.lockScreenContentMargins)
            }
        case .systemSmall:
            if spec.variant == "placeholder" {
                ReadingHomeSmallWidgetView(snapshot: ReadingWidgetPlaceholder.snapshot, size: size, contentMargins: ReadingWidgetMetrics.homeSmallContentMargins)
                    .redacted(reason: .placeholder)
            } else {
                ReadingHomeSmallWidgetView(snapshot: snapshot, unavailableReason: readResult.unavailableReason, size: size, contentMargins: ReadingWidgetMetrics.homeSmallContentMargins)
            }
        case .liveActivity:
            if let state = liveActivityState {
                ReadingLiveActivityLockScreenView(attributes: liveActivityAttributes, state: state) { label in
                    Button(action: {}) { label }
                }
            }
        case .control:
            ReadingControlLabelView()
                .font(.body)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
                .accessibilityIdentifier("control.startReading")
        case .snippet:
            WhereStoppedSnippetView(text: WhereStoppedIntent.formatResponse(for: appSnapshot))
        }
    }

    private var liveActivityAttributes: ReadingActivityAttributes {
        let startedAt: Date
        if let iso = model.store.activeSession?.startedAt, let parsed = NightDateCalculator.parseISO8601(iso) {
            startedAt = parsed
        } else {
            startedAt = model.store.clock.now()
        }
        return ReadingActivityAttributes(bookId: model.store.currentBook?.id, startedAt: startedAt)
    }

    private var liveActivityState: ReadingActivityAttributes.ContentState? {
        switch spec.variant {
        case "waiting":
            return ReadingLiveActivityStateFactory.waiting(from: appSnapshot)
        case "reading":
            return ReadingLiveActivityStateFactory.reading(from: appSnapshot)
        default:
            guard let record = UITestHookWidgetShowcaseView.latestRecord(model: model) else { return nil }
            return ReadingLiveActivityStateFactory.ended(from: appSnapshot, minutes: record.durationMinutes, progressText: ReadingWidgetStrings.progressText(for: appSnapshot.currentBook))
        }
    }

    static func latestRecord(model: ReadingAppModel) -> ReadingRecordSnapshot? {
        guard let bookId = model.store.currentBook?.id else { return nil }
        return model.store.records.filter { $0.bookId == bookId }.max { $0.endedAt < $1.endedAt }
    }

    private var viewTypeName: String {
        switch spec.surface {
        case .accessoryRectangular: return showcaseTypeName(ReadingLockScreenWidgetView.self)
        case .systemSmall: return showcaseTypeName(ReadingHomeSmallWidgetView.self)
        case .liveActivity: return showcaseTypeName(ReadingLiveActivityLockScreenView<Button<Text>>.self)
        case .control: return showcaseTypeName(ReadingControlLabelView.self)
        case .snippet: return showcaseTypeName(WhereStoppedSnippetView.self)
        }
    }

    private func publishReadout() {
        let canvas = canvasSize
        let readout = UITestHookWidgetShowcaseReadout(
            spec: spec.raw,
            surface: spec.surface.rawValue,
            variant: spec.variant,
            viewType: viewTypeName,
            requestedWidth: spec.width,
            requestedHeight: spec.height,
            canvasWidth: Double(canvas.width),
            canvasHeight: Double(canvas.height),
            idealHeight: Double(idealHeight),
            contentOverflow: idealHeight > canvas.height + 0.5,
            colorScheme: colorScheme == .dark ? "dark" : "light",
            dynamicTypeSize: String(describing: dynamicTypeSize)
        )
        if UITestHookCoordinator.shared.widgetShowcaseReadout != readout {
            UITestHookCoordinator.shared.widgetShowcaseReadout = readout
        }
    }
}

/// 契約 1-6：空の画面に hook.error の要素だけを出す。
public struct UITestHookErrorView: View {
    let value: String

    public init(value: String) {
        self.value = value
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            HookReadoutAccessibleView(id: "hook.error", value: value)
                .frame(width: 44, height: 44)
        }
    }
}
#endif
