import Foundation
import SwiftUI
import AppIntents
import ReadingCore
import ReadingStore

extension ReadingStoreStrings {
    /// ReadingStore が組む文を、design/ 7 の文言キーで今の言語の文にして渡す（Siri・ショートカットの答え、S-4、W-3）。
    /// アプリ（ReadingAppModel）と、アプリが動いていないときにインテントが作る ReadingDataStore の両方で使う。
    public static var localized: ReadingStoreStrings {
        ReadingStoreStrings(
            intentStartStarted: String(localized: "intent.start.started"),
            intentStartAlreadyReading: String(localized: "intent.start.alreadyReading"),
            sessionStartError: String(localized: "session.start.error"),
            sessionTooShort: String(localized: "session.tooShort"),
            sessionSaveError: String(localized: "session.save.error"),
            whereStoppedPageFormat: String(localized: "intent.whereStopped.page"),
            whereStoppedLocationFormat: String(localized: "intent.whereStopped.location"),
            whereStoppedPercentFormat: String(localized: "intent.whereStopped.percent"),
            whereStoppedNoPage: String(localized: "intent.whereStopped.noPage"),
            whereStoppedNoCurrent: String(localized: "intent.whereStopped.noCurrent"),
            whereStoppedError: String(localized: "intent.whereStopped.error"),
            durationMinutesFormat: String(localized: "duration.minutes"),
            resultSummaryPagesFormat: String(localized: "result.summary.pages"),
            resultSummaryLocationsFormat: String(localized: "result.summary.locations"),
            resultSummaryPercentsFormat: String(localized: "result.summary.percents"),
            resultSummaryPagesFirstFormat: String(localized: "result.summary.pages.first"),
            resultSummaryLocationsFirstFormat: String(localized: "result.summary.locations.first"),
            resultSummaryPercentsFirstFormat: String(localized: "result.summary.percents.first"),
            intentStartNoCurrent: String(localized: "intent.start.noCurrent"),
            intentEndCompleted: String(localized: "intent.end.completed"),
            liveActivityEndLabel: String(localized: "liveActivity.end.label"),
            liveActivityEndedSummaryFormat: String(localized: "liveActivity.ended.summary")
        )
    }
}

extension RecommendationReasonStrings {
    /// 推薦の理由の文（design/ 7「推薦の理由のキーの選び方」、決定 85）を今の言語で渡す。
    public static var localized: RecommendationReasonStrings {
        RecommendationReasonStrings(
            nextTsundoku: String(localized: "next.reason.tsundoku"),
            nextReaders: String(localized: "next.reason.readers"),
            nextNextVolume: String(localized: "next.reason.nextVolume"),
            nextSameAuthor: String(localized: "next.reason.sameAuthor"),
            nextSameAwardFormat: String(localized: "next.reason.sameAward"),
            nextSameLabelFormat: String(localized: "next.reason.sameLabel"),
            recReaders: String(localized: "rec.reason.readers"),
            recNextVolume: String(localized: "rec.reason.nextVolume"),
            recSameAuthor: String(localized: "rec.reason.sameAuthor"),
            recSameAwardFormat: String(localized: "rec.reason.sameAward"),
            recSameLabelFormat: String(localized: "rec.reason.sameLabel")
        )
    }
}

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
            created.storeStrings = ReadingStoreStrings.localized
            created.snapshotStore.spokenStrings = ReadingWidgetStrings.spoken
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
            created.storeStrings = ReadingStoreStrings.localized
            created.snapshotStore.spokenStrings = ReadingWidgetStrings.spoken
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
            view: WhereStoppedSnippetView(text: spokenText)
        )
    }

    /// Formats the voice and snippet response for `WhereStoppedIntent`.
    /// Never includes the book title, saved line, or app name.
    public static func formatResponse(for snapshot: WidgetSnapshot) -> String {
        guard let book = snapshot.currentBook else {
            return String(localized: "intent.whereStopped.noCurrent")
        }
        guard let progress = book.progress else {
            return String(localized: "intent.whereStopped.noPage")
        }
        let value = progress.value
        switch progress.unit {
        case .page:
            return String(format: String(localized: "intent.whereStopped.page"), value)
        case .location:
            return String(format: String(localized: "intent.whereStopped.location"), value)
        case .percent:
            return String(format: String(localized: "intent.whereStopped.percent"), value)
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
            created.storeStrings = ReadingStoreStrings.localized
            created.snapshotStore.spokenStrings = ReadingWidgetStrings.spoken
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

