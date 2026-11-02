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
                .japaneseTextTypesetting()
                .background(JapaneseWindowTypesettingInstaller().accessibilityHidden(true))
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

/// UIKit が描く文字（ナビゲーションバーの題、`TextField` の中、確認ダイアログ）には SwiftUI の
/// `typesettingLanguage` が届かない。窓の trait（`UITraitCollection.typesettingLanguage`、iOS 17）を日本語にして、
/// 英語だけの端末でも和文の書名・著者・一行をヒラギノで組む（tokens.md 3。文言の言語は変えない）。
/// シートと確認ダイアログは同じ窓の上に出るので、この trait を受け継ぐ。
private struct JapaneseWindowTypesettingInstaller: UIViewRepresentable {
    func makeUIView(context: Context) -> InstallerView {
        let view = InstallerView()
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: InstallerView, context: Context) {}

    final class InstallerView: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard let window else { return }
            // 上書きしていない trait を読むと UIKit が止まる（_UITraitOverrides の assert）ので、読まずに入れる。
            window.traitOverrides.typesettingLanguage = ThemeTypography.japaneseTypesettingLanguage
        }
    }
}
