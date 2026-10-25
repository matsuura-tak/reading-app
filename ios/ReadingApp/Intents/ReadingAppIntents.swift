import Foundation
import AppIntents
import ReadingCore
import ReadingStore

public struct WhereStoppedIntent: AppIntent {
    public static let title: LocalizedStringResource = "intent.whereStopped.title"
    public static let description = IntentDescription("intent.whereStopped.description")
    public static let openAppWhenRun: Bool = false

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let snapshot = ReadingSharedContainer.loadWidgetSnapshot()
        let dialogText = WhereStoppedIntent.formatResponse(for: snapshot)
        return .result(dialog: IntentDialog(stringLiteral: dialogText))
    }

    public static func formatResponse(for snapshot: WidgetSnapshot) -> String {
        guard let book = snapshot.currentBook else {
            return String(localized: "intent.whereStopped.empty")
        }
        let titleText = book.isTitlePending ? String(localized: "common.book.titlePending") : (book.title ?? "")
        let progressText = book.progressDisplay ?? ""
        if !snapshot.hideOnWidgets, let line = book.latestLine, !line.isEmpty {
            return "『\(titleText)』の\(progressText)まで読みました。最後の一行は「\(line)」です。"
        } else if !progressText.isEmpty {
            return "『\(titleText)』の\(progressText)まで読みました。"
        } else {
            return "『\(titleText)』を読んでいます。"
        }
    }
}

public struct ContinueReadingIntent: AppIntent {
    public static let title: LocalizedStringResource = "intent.continueReading.title"
    public static let description = IntentDescription("intent.continueReading.description")
    public static let openAppWhenRun: Bool = true

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let snapshot = ReadingSharedContainer.loadWidgetSnapshot()
        let dialogText = ContinueReadingIntent.formatResponse(for: snapshot)
        return .result(dialog: IntentDialog(stringLiteral: dialogText))
    }

    public static func formatResponse(for snapshot: WidgetSnapshot) -> String {
        if let book = snapshot.currentBook {
            let titleText = book.isTitlePending ? String(localized: "common.book.titlePending") : (book.title ?? "")
            return "『\(titleText)』の読書を始めます。"
        } else {
            return String(localized: "intent.continueReading.empty")
        }
    }
}

public struct ReadingAppShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: WhereStoppedIntent(),
            phrases: [
                "\(.applicationName) どこまで読んだ",
                "\(.applicationName) 栞を確認"
            ],
            shortTitle: "intent.whereStopped.shortTitle",
            systemImageName: "bookmark.fill"
        )
        AppShortcut(
            intent: ContinueReadingIntent(),
            phrases: [
                "\(.applicationName) 続きを読む",
                "\(.applicationName) 読書を始める"
            ],
            shortTitle: "intent.continueReading.shortTitle",
            systemImageName: "book.fill"
        )
    }
}
