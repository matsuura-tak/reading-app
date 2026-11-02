import Foundation

/// ReadingStore が組む文（Siri・ショートカットの答え、S-4 の `result.summary`、W-3 の終えた直後の分数）。
/// ReadingCore と ReadingStore は String Catalog を持たないので、アプリと拡張が design/ 7 の文言キーを通した文を入れて渡す
/// （`ReadingStoreStrings.localized`、ReadingApp/Intents/ReadingAppIntents.swift）。
/// パッケージの中には ja・en の文を持たない。渡されないときは `keys`（文言キーの名前そのもの）が出るので、渡し忘れが分かる。
public struct ReadingStoreStrings: Sendable, Equatable {
    /// `intent.start.started`
    public var intentStartStarted: String
    /// `intent.start.alreadyReading`
    public var intentStartAlreadyReading: String
    /// `session.start.error`
    public var sessionStartError: String
    /// `session.tooShort`
    public var sessionTooShort: String
    /// `session.save.error`
    public var sessionSaveError: String
    /// `intent.whereStopped.page`（%lld）
    public var whereStoppedPageFormat: String
    /// `intent.whereStopped.location`（%lld）
    public var whereStoppedLocationFormat: String
    /// `intent.whereStopped.percent`（%lld）
    public var whereStoppedPercentFormat: String
    /// `intent.whereStopped.noPage`
    public var whereStoppedNoPage: String
    /// `intent.whereStopped.noCurrent`
    public var whereStoppedNoCurrent: String
    /// `intent.whereStopped.error`
    public var whereStoppedError: String
    /// `duration.minutes`（%lld）
    public var durationMinutesFormat: String
    /// `result.summary.pages`（%1$lld、%2$lld、%3$@）
    public var resultSummaryPagesFormat: String
    /// `result.summary.locations`（%1$lld、%2$lld、%3$@）
    public var resultSummaryLocationsFormat: String
    /// `result.summary.percents`（%1$lld、%2$lld、%3$@）
    public var resultSummaryPercentsFormat: String

    public nonisolated init(
        intentStartStarted: String,
        intentStartAlreadyReading: String,
        sessionStartError: String,
        sessionTooShort: String,
        sessionSaveError: String,
        whereStoppedPageFormat: String,
        whereStoppedLocationFormat: String,
        whereStoppedPercentFormat: String,
        whereStoppedNoPage: String,
        whereStoppedNoCurrent: String,
        whereStoppedError: String,
        durationMinutesFormat: String,
        resultSummaryPagesFormat: String,
        resultSummaryLocationsFormat: String,
        resultSummaryPercentsFormat: String
    ) {
        self.intentStartStarted = intentStartStarted
        self.intentStartAlreadyReading = intentStartAlreadyReading
        self.sessionStartError = sessionStartError
        self.sessionTooShort = sessionTooShort
        self.sessionSaveError = sessionSaveError
        self.whereStoppedPageFormat = whereStoppedPageFormat
        self.whereStoppedLocationFormat = whereStoppedLocationFormat
        self.whereStoppedPercentFormat = whereStoppedPercentFormat
        self.whereStoppedNoPage = whereStoppedNoPage
        self.whereStoppedNoCurrent = whereStoppedNoCurrent
        self.whereStoppedError = whereStoppedError
        self.durationMinutesFormat = durationMinutesFormat
        self.resultSummaryPagesFormat = resultSummaryPagesFormat
        self.resultSummaryLocationsFormat = resultSummaryLocationsFormat
        self.resultSummaryPercentsFormat = resultSummaryPercentsFormat
    }

    /// 文言キーの名前そのもの（アプリが文を渡す前の既定値）。String Catalog にないキーを引いたときと同じく、キーが見える。
    public static let keys = ReadingStoreStrings(
        intentStartStarted: "intent.start.started",
        intentStartAlreadyReading: "intent.start.alreadyReading",
        sessionStartError: "session.start.error",
        sessionTooShort: "session.tooShort",
        sessionSaveError: "session.save.error",
        whereStoppedPageFormat: "intent.whereStopped.page",
        whereStoppedLocationFormat: "intent.whereStopped.location",
        whereStoppedPercentFormat: "intent.whereStopped.percent",
        whereStoppedNoPage: "intent.whereStopped.noPage",
        whereStoppedNoCurrent: "intent.whereStopped.noCurrent",
        whereStoppedError: "intent.whereStopped.error",
        durationMinutesFormat: "duration.minutes",
        resultSummaryPagesFormat: "result.summary.pages",
        resultSummaryLocationsFormat: "result.summary.locations",
        resultSummaryPercentsFormat: "result.summary.percents"
    )

    /// 「どこまで読んだ？」の答え（`intent.whereStopped.page` / `location` / `percent`）。書名と一行は入れない（AC-121、AC-143）。
    public nonisolated func whereStopped(unit: ProgressUnit, value: Int) -> String {
        let format: String
        switch unit {
        case .page: format = whereStoppedPageFormat
        case .location: format = whereStoppedLocationFormat
        case .percent: format = whereStoppedPercentFormat
        }
        return String(format: format, locale: nil, Int64(value))
    }

    /// 分数（`duration.minutes`。「18分」「18 min」）。
    public nonisolated func durationMinutes(_ minutes: Int) -> String {
        String(format: durationMinutesFormat, locale: nil, Int64(minutes))
    }

    /// S-4 の `result.summary`（AC-75、AC-76、AC-141）。
    /// - 進み具合がない（あとで挟む、場所を変えない）：分数だけ（「18分」）。
    /// - 前の値があって変わった：`result.summary.pages` / `locations` / `percents`（「p.43 → p.61　18分」）。
    /// - 前の値がない、または変わらない：今の値と分数（「p.61　18分」）。design/ 7 にこの形のキーはないため、
    ///   同じ単位の `result.summary.*` の「%2$lld の後ろから %3$@ の前まで」を区切りとして使う（ja は全角の空白、en は空白2つ）。
    /// - Parameter currentDisplay: 今の値の短い形（`InputValidator.formatProgressDisplay` の文。「p.61」「Loc 1450」）。
    public nonisolated func resultSummary(
        unit: ProgressUnit,
        previous: Int?,
        current: Int?,
        currentDisplay: String?,
        minutes: Int
    ) -> String {
        let duration = durationMinutes(minutes)
        guard let current, let currentDisplay else { return duration }
        let format: String
        switch unit {
        case .page: format = resultSummaryPagesFormat
        case .location: format = resultSummaryLocationsFormat
        case .percent: format = resultSummaryPercentsFormat
        }
        if let previous, previous != current {
            return String(format: format, locale: nil, Int64(previous), Int64(current), duration)
        }
        return currentDisplay + Self.separator(in: format) + duration
    }

    /// `result.summary.*` の書式から、場所と分数の間の区切りを取り出す。見つからなければ空白1つ。
    static func separator(in format: String) -> String {
        guard let afterCurrent = format.range(of: "%2$lld"),
              let durationRange = format.range(of: "%3$@", range: afterCurrent.upperBound..<format.endIndex) else {
            return " "
        }
        var between = String(format[afterCurrent.upperBound..<durationRange.lowerBound])
        // 「%2$lld%%　%3$@」（％）のように、値の後ろに単位が付く形は、区切りの前の単位の印を除く。
        if between.hasPrefix("%%") {
            between.removeFirst(2)
        }
        return between.isEmpty ? " " : between
    }
}
