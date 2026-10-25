import SwiftUI
import ReadingCore
import ReadingStore

@main
struct ReadingApp: App {
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
                    model.store.openEntryURL(url.absoluteString)
                    if model.store.sessionState == .reading {
                        model.currentScreen = .sessionActive
                    }
                    model.notifyHookChanged()
                }
        }
    }
}
