import SwiftUI
import ReadingCore
import ReadingStore

public struct ContentView: View {
    @Bindable var model: ReadingAppModel

    public init(model: ReadingAppModel) {
        self.model = model
    }

    private var palette: ThemePalette {
        ThemePalette(appearanceID: model.settings.appearanceID)
    }

    public var body: some View {
        ZStack(alignment: .bottomLeading) {
            if model.sessionState == .reading {
                ReadingSessionView(model: model)
                    .tint(palette.accent)
            } else if let sheet = model.activeSheet {
                VStack {
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
                .background(Color(uiColor: .systemBackground))
                .tint(palette.accent)
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
                .tint(palette.accent)
            }

            #if UITEST_HOOKS
            UITestHookOverlayView(model: model)
            #endif
        }
        .environment(\.themePalette, palette)
        .preferredColorScheme(palette.preferredColorScheme)
    }
}

#Preview("ContentView - Idle") {
    let model = ReadingAppModel()
    ContentView(model: model)
}
