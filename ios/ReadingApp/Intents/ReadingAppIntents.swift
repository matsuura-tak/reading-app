import Foundation
import SwiftUI
import AppIntents
import ReadingCore
import ReadingStore

public struct StartReadingIntent: LiveActivityIntent {
    public static let title: LocalizedStringResource = "今夜の読書を始める"
    public static let description = IntentDescription("今夜の読書とLive Activityを始めます。")
    public static let openAppWhenRun: Bool = false
    public static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let store: ReadingDataStore
        if let shared = ReadingDataStore.shared {
            store = shared
        } else {
            let created = ReadingDataStore(containerDirectory: ReadingSharedContainer.containerDirectoryURL())
            created.loadFromDisk()
            store = created
        }
        let log = store.handleExternalIntent("StartReadingIntent:fg=1")
        return .result(dialog: IntentDialog(stringLiteral: log.spokenText))
    }
}

public struct EndReadingFromActivityIntent: LiveActivityIntent {
    public static let title: LocalizedStringResource = "読書を終える"
    public static let description = IntentDescription("進行中の読書を終えて時間を記録します。")
    public static let openAppWhenRun: Bool = false
    public static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let store: ReadingDataStore
        if let shared = ReadingDataStore.shared {
            store = shared
        } else {
            let created = ReadingDataStore(containerDirectory: ReadingSharedContainer.containerDirectoryURL())
            created.loadFromDisk()
            store = created
        }
        let log = store.handleExternalIntent("EndReadingFromActivityIntent:fg=1")
        return .result(dialog: IntentDialog(stringLiteral: log.spokenText))
    }
}

public struct WhereStoppedIntent: AppIntent {
    public static let title: LocalizedStringResource = "どこまで読んだか聞く"
    public static let description = IntentDescription("いま読んでいる本のしおりのページ位置だけを答えます。")
    public static let openAppWhenRun: Bool = false
    public static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let spokenText: String
        if let shared = ReadingDataStore.shared {
            let log = shared.handleExternalIntent("WhereStoppedIntent")
            spokenText = log.spokenText
        } else {
            let snapshot = ReadingSharedContainer.loadWidgetSnapshot()
            spokenText = Self.formatResponse(for: snapshot)
        }
        return .result(
            dialog: IntentDialog(stringLiteral: spokenText),
            view: VStack(alignment: .leading, spacing: 4) {
                Text(spokenText)
                    .font(.body)
            }
            .padding()
        )
    }

    /// Formats the voice and snippet response for `WhereStoppedIntent`.
    /// Never includes the book title, saved line, or app name.
    public static func formatResponse(for snapshot: WidgetSnapshot) -> String {
        guard let book = snapshot.currentBook else {
            return "いま読んでいる本はまだありません。"
        }
        guard let rawProgress = book.progressDisplay?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawProgress.isEmpty else {
            return "まだページが記録されていません。"
        }
        let digits = rawProgress.filter(\.isNumber)
        guard !digits.isEmpty else {
            return "まだページが記録されていません。"
        }
        switch book.progressUnit {
        case .page:
            return "\(digits)ページからです。"
        case .location:
            return "位置\(digits)からです。"
        case .percent:
            return "\(digits)パーセントからです。"
        }
    }
}

public struct ContinueReadingIntent: AppIntent {
    public static let title: LocalizedStringResource = "続きを読む"
    public static let description = IntentDescription("アプリを開いてしおり画面を表示します。")
    public static let openAppWhenRun: Bool = true
    public static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        if let shared = ReadingDataStore.shared {
            _ = shared.handleExternalIntent("ContinueReadingIntent:fg=1")
        } else {
            let created = ReadingDataStore(containerDirectory: ReadingSharedContainer.containerDirectoryURL())
            created.loadFromDisk()
            _ = created.handleExternalIntent("ContinueReadingIntent:fg=1")
        }
        return .result()
    }
}

public struct ReadingAppShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartReadingIntent(),
            phrases: [
                "\(.applicationName) 読書を始める",
                "\(.applicationName) 読み始める"
            ],
            shortTitle: "今夜の読書を始める",
            systemImageName: "book.circle.fill"
        )
        AppShortcut(
            intent: WhereStoppedIntent(),
            phrases: [
                "\(.applicationName) どこまで読んだ",
                "\(.applicationName) しおりを確認"
            ],
            shortTitle: "どこまで読んだか聞く",
            systemImageName: "bookmark.fill"
        )
        AppShortcut(
            intent: ContinueReadingIntent(),
            phrases: [
                "\(.applicationName) 続きを読む",
                "\(.applicationName) しおりを開く"
            ],
            shortTitle: "続きを読む",
            systemImageName: "book.fill"
        )
    }
}

