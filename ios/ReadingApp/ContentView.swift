import SwiftUI
import ReadingCore
import ReadingStore

public struct ContentView: View {
    @Bindable var model: ReadingAppModel

    public init(model: ReadingAppModel) {
        self.model = model
    }

    private var palette: ThemePalette {
        ThemePalette.palette(for: model.settings.appearanceID)
    }

    private var effectiveColorScheme: ColorScheme? {
        #if UITEST_HOOKS
        if let override = UITestHookCoordinator.shared.appearanceSchemeOverride {
            if override == "dark" { return .dark }
            if override == "light" { return .light }
        }
        #endif
        return palette.preferredColorScheme
    }

    public var body: some View {
        ZStack(alignment: .bottomLeading) {
            #if UITEST_HOOKS
            if let errorValue = UITestHookCoordinator.shared.hookErrorValue {
                UITestHookErrorView(value: errorValue)
            } else if let showcase = UITestHookCoordinator.shared.widgetShowcase {
                UITestHookWidgetShowcaseView(model: model, spec: showcase)
            } else {
                gatedMainAppContent
            }
            #else
            gatedMainAppContent
            #endif

            #if UITEST_HOOKS
            if UITestHookCoordinator.shared.hookErrorValue == nil {
                UITestHookOverlayView(model: model)
            }
            #endif
        }
        .environment(\.themePalette, palette)
        .preferredColorScheme(effectiveColorScheme)
        .modifier(DynamicTypeOverrideModifier())
    }

    /// 起動の読み込み（H33 `store.load`）が 0.3秒を超えたら、S-1 の灰の帯を出す（design/ 5 の S-1）。
    private var gatedMainAppContent: some View {
        GatedLoadView(gate: model.store.loadGate, point: .storeLoad) {
            mainAppContent
        } placeholder: {
            BookmarkLoadingPlaceholderView()
        }
    }

    @ViewBuilder
    private var mainAppContent: some View {
        if model.sessionState == .reading {
            ReadingSessionView(model: model)
                .tint(palette.actionTint)
        } else if let sheet = model.activeSheet {
            VStack(spacing: 0) {
                switch sheet {
                case .addBook(let pendingMode):
                    BookAddFlowSheetView(model: model, titlePendingMode: pendingMode)
                case .markFlow:
                    BookmarkMarkFlowSheet(model: model, initialStep: .select)
                case .resultSheet:
                    SessionResultSheetView(model: model)
                case .widgetGuide:
                    WidgetGuideSheetView(model: model)
                case .finishNight(let bookId):
                    FinishNightView(model: model, bookId: bookId)
                case .manualInput(let isbn, let title, let author, let pub, _, _, let pending):
                    BookAddFlowSheetView(
                        model: model,
                        titlePendingMode: pending,
                        initialStep: .manualInput(isbn13: isbn, prefillTitle: title, prefillAuthor: author, prefillPublisher: pub)
                    )
                case .coverCapture(let isbn, let pending):
                    BookAddFlowSheetView(
                        model: model,
                        titlePendingMode: pending,
                        initialStep: .coverCandidates(isbn13: isbn, candidates: model.store.ocrConfiguration?.coverLines ?? [])
                    )
                case .colophonCapture(let bookId):
                    ColophonOCRSheetView(model: model, bookId: bookId) {
                        model.activeSheet = nil
                        model.notifyHookChanged()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(palette.bgPrimary)
            .tint(palette.actionTint)
        } else {
            NavigationStack(path: $model.navigationPath) {
                BookmarkHomeView(model: model)
                    .navigationDestination(for: NavigationDestinationItem.self) { dest in
                        switch dest {
                        case .shelf:
                            ShelfListView(model: model)
                        case .settings:
                            SettingsView(model: model)
                        case .bookDetail(let bookId):
                            BookDetailView(model: model, bookId: bookId)
                        }
                    }
            }
            .tint(palette.actionTint)
        }
    }
}

private struct DynamicTypeOverrideModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if UITEST_HOOKS
        if UITestHookCoordinator.shared.isAX5Override {
            content.environment(\.dynamicTypeSize, .accessibility5)
        } else {
            content
        }
        #else
        content
        #endif
    }
}

#Preview("ContentView - Idle") {
    let model = ReadingAppModel()
    ContentView(model: model)
}
