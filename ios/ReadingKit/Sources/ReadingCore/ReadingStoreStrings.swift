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
    /// `result.summary.pages.first`（%1$lld、%2$@）。前の場所がない晩（AC-76）
    public var resultSummaryPagesFirstFormat: String
    /// `result.summary.locations.first`（%1$lld、%2$@）
    public var resultSummaryLocationsFirstFormat: String
    /// `result.summary.percents.first`（%1$lld、%2$@）
    public var resultSummaryPercentsFirstFormat: String
    /// `intent.start.noCurrent`（「読み始める」で今の本がないときの声。決定 84）
    public var intentStartNoCurrent: String
    /// `intent.end.completed`（Live Activity の「終える」で保存できたときの声。決定 84）
    public var intentEndCompleted: String
    /// `liveActivity.end.label`（H23 の `endButtonLabel`。AC-114）
    public var liveActivityEndLabel: String
    /// `liveActivity.ended.summary`（%1$@ 分数、%2$@ 場所）。W-3 の終えた直後
    public var liveActivityEndedSummaryFormat: String

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
        resultSummaryPercentsFormat: String,
        resultSummaryPagesFirstFormat: String = "result.summary.pages.first",
        resultSummaryLocationsFirstFormat: String = "result.summary.locations.first",
        resultSummaryPercentsFirstFormat: String = "result.summary.percents.first",
        intentStartNoCurrent: String = "intent.start.noCurrent",
        intentEndCompleted: String = "intent.end.completed",
        liveActivityEndLabel: String = "liveActivity.end.label",
        liveActivityEndedSummaryFormat: String = "liveActivity.ended.summary"
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
        self.resultSummaryPagesFirstFormat = resultSummaryPagesFirstFormat
        self.resultSummaryLocationsFirstFormat = resultSummaryLocationsFirstFormat
        self.resultSummaryPercentsFirstFormat = resultSummaryPercentsFirstFormat
        self.intentStartNoCurrent = intentStartNoCurrent
        self.intentEndCompleted = intentEndCompleted
        self.liveActivityEndLabel = liveActivityEndLabel
        self.liveActivityEndedSummaryFormat = liveActivityEndedSummaryFormat
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
    /// - 進み具合がない（あとで挟む、場所を変えない）：分数だけ（`duration.minutes`。「18分」）。
    /// - 前の値があって変わった：`result.summary.pages` / `locations` / `percents`（「p.43 → p.61　18分」）。
    /// - 前の値がない、または変わらない：`result.summary.*.first`（「p.61　18分」）。
    public nonisolated func resultSummary(
        unit: ProgressUnit,
        previous: Int?,
        current: Int?,
        minutes: Int
    ) -> String {
        let duration = durationMinutes(minutes)
        guard let current else { return duration }
        if let previous, previous != current {
            let format: String
            switch unit {
            case .page: format = resultSummaryPagesFormat
            case .location: format = resultSummaryLocationsFormat
            case .percent: format = resultSummaryPercentsFormat
            }
            return String(format: format, locale: nil, Int64(previous), Int64(current), duration)
        }
        let firstFormat: String
        switch unit {
        case .page: firstFormat = resultSummaryPagesFirstFormat
        case .location: firstFormat = resultSummaryLocationsFirstFormat
        case .percent: firstFormat = resultSummaryPercentsFirstFormat
        }
        return String(format: firstFormat, locale: nil, Int64(current), duration)
    }

    /// W-3 の終えた直後の見える文字（`liveActivity.ended.summary`「10分 · p.61」）。場所がなければ分数だけ。
    public nonisolated func liveActivityEndedSummary(minutes: Int, progressText: String?) -> String {
        let duration = durationMinutes(minutes)
        guard let progressText, !progressText.isEmpty else { return duration }
        return String(format: liveActivityEndedSummaryFormat, locale: nil, duration, progressText)
    }
}

/// S-4 のまとめの値（見える文字 `result.summary` と読み上げ `result.summary.spoken` を同じ値から組むため）。
/// `previous` は前の値があって今の値と違うときだけ入る。`current` が nil なら分数だけの晩（あとで挟む、場所を変えない）。
public struct SessionResultFigures: Sendable, Equatable {
    public var unit: ProgressUnit
    public var previous: Int?
    public var current: Int?
    public var minutes: Int

    public nonisolated init(unit: ProgressUnit, previous: Int?, current: Int?, minutes: Int) {
        self.unit = unit
        self.current = current
        self.previous = (previous != nil && previous != current && current != nil) ? previous : nil
        self.minutes = minutes
    }
}
