import SwiftUI
import ReadingCore
import ReadingStore

@main
struct ReadingApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var model: ReadingAppModel

    init() {
        let appModel = ReadingAppModel()
        #if UITEST_HOOKS
        UITestHookCoordinator.shared.applyLaunchConfiguration(model: appModel)
        #else
        appModel.store.loadFromDisk()
        #endif
        _model = State(initialValue: appModel)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .onOpenURL { url in
                    let prevOpenedAt = model.store.pendingEntryURL?.openedAt
                    model.store.openEntryURL(url)
                    if model.store.pendingEntryURL?.openedAt != prevOpenedAt {
                        if model.store.sessionState == .reading {
                            model.currentScreen = .sessionActive
                        } else {
                            model.activeSheet = nil
                            model.navigationPath = []
                            model.currentScreen = model.store.currentBook != nil ? .bookmarkCurrent : .bookmarkEmpty
                        }
                    }
                    model.notifyHookChanged()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    #if !UITEST_HOOKS
                    switch newPhase {
                    case .background:
                        model.store.handleDidEnterBackground()
                        model.notifyHookChanged()
                    case .active:
                        model.currentScreen = (model.store.sessionState == .reading)
                            ? .sessionActive
                            : ((model.store.currentBook != nil) ? .bookmarkCurrent : .bookmarkEmpty)
                        model.store.handleDidBecomeActive()
                        model.notifyHookChanged()
                    default:
                        break
                    }
                    #endif
                }
        }
    }
}
