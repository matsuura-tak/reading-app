import SwiftUI
import ReadingCore
import ReadingStore

public enum ReadingSessionViewState: Equatable, Sendable {
    case active(title: String)
    case saveError(title: String, errorText: String)
}

public struct ReadingSessionView: View {
    @Bindable var model: ReadingAppModel
    public let previewState: ReadingSessionViewState?

    public init(model: ReadingAppModel, previewState: ReadingSessionViewState? = nil) {
        self.model = model
        self.previewState = previewState
    }

    private var resolvedState: ReadingSessionViewState {
        if let previewState { return previewState }
        let book = model.store.currentBook
        let title = (book?.isTitlePending == true) ? "あとで書名を入れる本" : (book?.title ?? "")
        if let errKey = model.store.activeErrorKey {
            return .saveError(title: title, errorText: BannerNoticeView.message(forKey: errKey))
        }
        return .active(title: title)
    }

    public var body: some View {
        VStack(spacing: 32) {
            Spacer()

            switch resolvedState {
            case .active(let title):
                Text(title)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("reading.title")
                    .accessibilityLabel(title)
                    .accessibilityValue(title)
            case .saveError(let title, let errorText):
                Text(title)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("reading.title")
                    .accessibilityLabel(title)
                    .accessibilityValue(title)

                Text(errorText)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier(model.store.activeErrorKey ?? "session.save.error")
                    .accessibilityLabel(errorText)
                    .accessibilityValue(errorText)
            }

            if model.store.currentBook?.isEbook == true {
                Text("電子書籍で読んでいる間も時間を記録しています")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("reading.ebookNote")
            }

            Button {
                #if UITEST_HOOKS
                UITestHookCoordinator.shared.syncAllDarwinTokenStates()
                #endif
                let res = model.store.endReadingSession(source: "app")
                switch res {
                case .saved:
                    model.currentScreen = .bookmarkMarkSelect
                    model.activeSheet = .markFlow
                case .discardedTooShort, .discardedInvalidTime:
                    model.currentScreen = (model.store.currentBook != nil) ? .bookmarkCurrent : .bookmarkEmpty
                case .failedSave, .ignoredDuplicate:
                    break
                }
                model.notifyHookChanged()
            } label: {
                Text("読み終える")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("reading.end")

            Spacer()
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screen.reading")
        .onAppear {
            model.currentScreen = .sessionActive
            model.notifyHookChanged()
        }
    }
}

#Preview("S-2 Reading Session Active") {
    let model = ReadingAppModel()
    ReadingSessionView(model: model, previewState: .active(title: "羅生門"))
}

#Preview("S-2 Reading Session Save Error") {
    let model = ReadingAppModel()
    ReadingSessionView(model: model, previewState: .saveError(title: "羅生門", errorText: "記録を保存できませんでした。もう一度お試しください。"))
}

#Preview("S-2 Reading Session AX5 Dark") {
    let model = ReadingAppModel()
    ReadingSessionView(model: model, previewState: .active(title: "吾輩は猫である"))
        .environment(\.dynamicTypeSize, .accessibility5)
        .preferredColorScheme(.dark)
}
