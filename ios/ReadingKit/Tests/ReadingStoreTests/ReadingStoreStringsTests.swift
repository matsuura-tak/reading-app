import Foundation
import Testing
@testable import ReadingCore
@testable import ReadingStore

/// テスト用の文。値は design/ 7 の文言キーの ja・en の写し（アプリでは ReadingStoreStrings.localized が String Catalog から組む）。
extension ReadingStoreStrings {
    static let testJapanese = ReadingStoreStrings(
        intentStartStarted: "読書を始めました。",
        intentStartAlreadyReading: "すでに読書中です。",
        sessionStartError: "読み始めを保存できませんでした。もう一度「読み始める」を押してください。",
        sessionTooShort: "1分未満の読書は記録に残しません。",
        sessionSaveError: "終わりを保存できませんでした。読書は続いています。もう一度「終える」を押してください。",
        whereStoppedPageFormat: "%lldページからです。",
        whereStoppedLocationFormat: "位置%lldからです。",
        whereStoppedPercentFormat: "%lldパーセントからです。",
        whereStoppedNoPage: "今の本には、まだページが記録されていません。",
        whereStoppedNoCurrent: "いま読んでいる本が選ばれていません。",
        whereStoppedError: "しおりを読み込めませんでした。よむまを開いて確かめてください。",
        durationMinutesFormat: "%lld分",
        resultSummaryPagesFormat: "p.%1$lld → p.%2$lld\u{3000}%3$@",
        resultSummaryLocationsFormat: "位置%1$lld → 位置%2$lld\u{3000}%3$@",
        resultSummaryPercentsFormat: "%1$lld%% → %2$lld%%\u{3000}%3$@"
    )

    static let testEnglish = ReadingStoreStrings(
        intentStartStarted: "Started reading.",
        intentStartAlreadyReading: "A reading session is already running.",
        sessionStartError: "Couldn't start the session. Tap Start Reading again.",
        sessionTooShort: "Sessions shorter than 1 minute aren't saved.",
        sessionSaveError: "Couldn't save the end of this session. It's still running. Tap End Reading again.",
        whereStoppedPageFormat: "From page %lld.",
        whereStoppedLocationFormat: "From location %lld.",
        whereStoppedPercentFormat: "From %lld percent.",
        whereStoppedNoPage: "No page is saved for your current book yet.",
        whereStoppedNoCurrent: "No current book is selected.",
        whereStoppedError: "Couldn't load your bookmark. Open Yomuma to check.",
        durationMinutesFormat: "%lld min",
        resultSummaryPagesFormat: "p.%1$lld → p.%2$lld  %3$@",
        resultSummaryLocationsFormat: "Loc %1$lld → Loc %2$lld  %3$@",
        resultSummaryPercentsFormat: "%1$lld%% → %2$lld%%  %3$@"
    )
}

struct ReadingStoreStringsTests {
    struct WhereCase: Sendable, CustomTestStringConvertible {
        let unit: ProgressUnit
        let value: Int
        let ja: String
        let en: String
        var testDescription: String { "\(unit.rawValue) \(value)" }
    }

    @Test("どこまで読んだ？の答えは言語ごとの文で、書名と一行を含まない（AC-121、AC-143）", arguments: [
        WhereCase(unit: .page, value: 61, ja: "61ページからです。", en: "From page 61."),
        WhereCase(unit: .location, value: 1450, ja: "位置1450からです。", en: "From location 1450."),
        WhereCase(unit: .percent, value: 52, ja: "52パーセントからです。", en: "From 52 percent.")
    ])
    func whereStopped(_ c: WhereCase) {
        #expect(ReadingStoreStrings.testJapanese.whereStopped(unit: c.unit, value: c.value) == c.ja)
        #expect(ReadingStoreStrings.testEnglish.whereStopped(unit: c.unit, value: c.value) == c.en)
    }

    struct SummaryCase: Sendable, CustomTestStringConvertible {
        let unit: ProgressUnit
        let previous: Int?
        let current: Int?
        let ja: String
        let en: String
        var testDescription: String { "\(unit.rawValue) \(String(describing: previous)) -> \(String(describing: current))" }
    }

    @Test("S-4 の result.summary の3つの形（AC-75、AC-76、AC-141）", arguments: [
        SummaryCase(unit: .page, previous: 43, current: 61, ja: "p.43 → p.61\u{3000}18分", en: "p.43 → p.61  18 min"),
        SummaryCase(unit: .page, previous: nil, current: 61, ja: "p.61\u{3000}18分", en: "p.61  18 min"),
        SummaryCase(unit: .page, previous: 61, current: 61, ja: "p.61\u{3000}18分", en: "p.61  18 min"),
        SummaryCase(unit: .page, previous: nil, current: nil, ja: "18分", en: "18 min"),
        SummaryCase(unit: .location, previous: 1200, current: 1450, ja: "位置1200 → 位置1450\u{3000}18分", en: "Loc 1200 → Loc 1450  18 min"),
        SummaryCase(unit: .location, previous: nil, current: 1450, ja: "位置1450\u{3000}18分", en: "Loc 1450  18 min"),
        SummaryCase(unit: .percent, previous: 34, current: 52, ja: "34% → 52%\u{3000}18分", en: "34% → 52%  18 min"),
        SummaryCase(unit: .percent, previous: nil, current: 52, ja: "52%\u{3000}18分", en: "52%  18 min")
    ])
    func resultSummary(_ c: SummaryCase) {
        let jaDisplay = c.current.flatMap {
            InputValidator.formatProgressDisplay(unit: c.unit, page: $0, location: $0, percent: Double($0), strings: .japanese)
        }
        let enDisplay = c.current.flatMap {
            InputValidator.formatProgressDisplay(unit: c.unit, page: $0, location: $0, percent: Double($0), strings: .english)
        }
        let ja = ReadingStoreStrings.testJapanese.resultSummary(
            unit: c.unit, previous: c.previous, current: c.current, currentDisplay: jaDisplay, minutes: 18
        )
        let en = ReadingStoreStrings.testEnglish.resultSummary(
            unit: c.unit, previous: c.previous, current: c.current, currentDisplay: enDisplay, minutes: 18
        )
        #expect(ja == c.ja)
        #expect(en == c.en)
    }

    @Test("formatProgressDisplay の位置は location.short（ja は「位置1450」、en は「Loc 1450」）")
    func progressDisplayLocation() {
        #expect(InputValidator.formatProgressDisplay(unit: .location, page: nil, location: 1450, percent: nil, strings: .japanese) == "位置1450")
        #expect(InputValidator.formatProgressDisplay(unit: .location, page: nil, location: 1450, percent: nil, strings: .english) == "Loc 1450")
        #expect(InputValidator.formatProgressDisplay(unit: .page, page: 61, location: nil, percent: nil, strings: .english) == "p.61")
        #expect(InputValidator.formatProgressDisplay(unit: .percent, page: nil, location: nil, percent: 51.6, strings: .english) == "52%")
        #expect(InputValidator.formatProgressDisplay(unit: .location, page: nil, location: 0, percent: nil, strings: .english) == nil)
    }

    @MainActor
    @Test("英語の文を渡した店は、Siri の答えを英語で返し、日本語を含まない（AC-121〜AC-123、AC-133、AC-143）")
    func storeAnswersInEnglish() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReadingStoreStringsTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = ReadingDataStore(containerDirectory: dir, clock: ReadingClock(nowISO8601: "2026-10-18T21:00:00+09:00"))
        store.storeStrings = .testEnglish
        store.snapshotStore.spokenStrings = .english
        store.resetAllData()

        #expect(store.handleExternalIntent("WhereStoppedIntent").spokenText == "No current book is selected.")

        _ = store.addBook(id: ReadingDataStore.uuidBookA, title: "羅生門", author: "芥川龍之介")
        #expect(store.handleExternalIntent("WhereStoppedIntent").spokenText == "No page is saved for your current book yet.")

        _ = store.saveBookmark(mode: "manual", rawLine: "ある日の暮方の事である。", rawProgress: "61")
        let page = store.handleExternalIntent("WhereStoppedIntent")
        #expect(page.spokenText == "From page 61.")
        #expect(page.snippetTexts == ["From page 61."])
        #expect(!page.spokenText.contains("羅生門"))
        #expect(!page.spokenText.contains("ある日の暮方の事である。"))

        let started = store.handleExternalIntent("StartReadingIntent")
        #expect(started.spokenText == "Started reading.")
        #expect(store.handleExternalIntent("StartReadingIntent").spokenText == "A reading session is already running.")

        store.isStoreLoadFailed = true
        #expect(store.handleExternalIntent("WhereStoppedIntent").spokenText == "Couldn't load your bookmark. Open Yomuma to check.")
    }
}
