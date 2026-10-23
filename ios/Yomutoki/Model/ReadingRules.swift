import Foundation

// 数と境界の決まり（PRD 10、contracts/data-model.md の「計算する値」）。純粋な関数と値の型だけを置く。
// どの分離からでも呼べるよう nonisolated と明示する（アプリのターゲットの既定は MainActor。ADR 0002）。

/// 読書の状態（PRD 9）。idle は ActiveReading がないこと。
nonisolated enum ReadingState: String, Sendable, CaseIterable {
    case reading
    case paused
    case finishing
}

/// 題名の整え方（PRD 10、data-model.md の Book.title、設計メモ 5 の形B）。
nonisolated enum TitleRules {
    /// 1字は Character（書記素クラスタ）。
    static let maxLength = 100

    /// 中の改行（LF、CR、CRLF、U+2028、U+2029）。CRLF は1つの Character。
    static func isLineBreak(_ character: Character) -> Bool {
        character == "\n" || character == "\r" || character == "\r\n" || character == "\u{2028}"
            || character == "\u{2029}"
    }

    /// 前後から除く空白4種（半角空白、U+3000、改行、タブ）。
    static func isEdgeWhitespace(_ character: Character) -> Bool {
        character == " " || character == "\u{3000}" || character == "\t" || isLineBreak(character)
    }

    /// 前後の空白4種を除く。
    static func trimmed(_ text: some StringProtocol) -> String {
        guard let first = text.firstIndex(where: { !isEdgeWhitespace($0) }),
            let last = text.lastIndex(where: { !isEdgeWhitespace($0) })
        else { return "" }
        return String(text[first...last])
    }

    /// 整えた値：前後の空白を除き、中の改行を1つずつ半角空白1つにする（並んだ改行はまとめない。タブは置き換えない）。
    static func normalized(_ raw: String) -> String {
        String(trimmed(raw).map { isLineBreak($0) ? " " : $0 })
    }

    /// 保存する値：整えた後に100字を超えたら先頭の100字に切り、もう一度前後の空白を除く。
    static func stored(_ raw: String) -> String {
        let value = normalized(raw)
        guard value.count > maxLength else { return value }
        return trimmed(value.prefix(maxLength))
    }

    /// 1字以上あるか（AC-3）。
    static func isValid(_ raw: String) -> Bool {
        !normalized(raw).isEmpty
    }

    /// 整えた後の字数が100を超えているか（D-57 の形B：book.add.titleLimit.onSave を出す間）。
    static func exceedsLimit(_ raw: String) -> Bool {
        normalized(raw).count > maxLength
    }
}

/// 時間とページの計算（data-model.md の「計算する値」、PRD 10 の丸め）。
nonisolated enum ReadingMath {
    /// 1分未満の読書は記録しない（PRD 9）。
    static let minimumSessionSeconds = 60
    /// Reading Week Reached の境目（週の合計 3,600 秒）。
    static let weekThresholdSeconds = 3_600
    static let pageRange = 0...9_999
    static let totalPagesRange = 1...9_999

    /// 経過 = max(0, 終わりの時刻 − 開始 − 止めていた合計)。時刻が戻っても負にしない（AC-41）。
    static func elapsed(start: Date, end: Date, pausedTotal: Double) -> TimeInterval {
        max(0, end.timeIntervalSince(start) - max(0, pausedTotal))
    }

    /// 秒の切り捨て。範囲の外の値（負、無限、とても大きい値）でも落ちない。
    static func wholeSeconds(_ interval: TimeInterval) -> Int {
        guard interval.isFinite, interval > 0 else { return 0 }
        return Int(min(interval, 1e12).rounded(.down))
    }

    /// 秒から分は切り捨て（90秒は1分）。
    static func wholeMinutes(seconds: Int) -> Int {
        max(0, seconds) / 60
    }

    /// 合計は秒で足してから分にする（90秒の記録3件は270秒で4分）。
    static func totalMinutes(_ durations: some Sequence<Int>) -> Int {
        wholeMinutes(seconds: durations.reduce(0, +))
    }

    /// 進み具合の % は切り捨て（299/300 は99%）。totalPages が nil なら出さない。
    static func progressPercent(lastPage: Int, totalPages: Int?) -> Int? {
        guard let totalPages, totalPages > 0 else { return nil }
        return max(0, lastPage) * 100 / totalPages
    }

    /// 読んだページ：入れたページが前より小さければ0（読み返し。AC-29）。
    static func pagesRead(endPage: Int?, previousLastPage: Int) -> Int? {
        endPage.map { max(0, $0 - previousLastPage) }
    }

    /// その時刻を含む週（Calendar.dateInterval(of: .weekOfYear, for:)。週の始めは暦の設定に従う）。
    static func week(containing date: Date, calendar: Calendar) -> DateInterval? {
        calendar.dateInterval(of: .weekOfYear, for: date)
    }

    /// 週に入るか。終わりの時刻は次の週の始まりなので含めない。
    static func contains(_ week: DateInterval, _ date: Date) -> Bool {
        date >= week.start && date < week.end
    }
}

/// 画面に渡す本の値（保存の層が保存の通った後に作る）。
nonisolated struct BookSnapshot: Identifiable, Equatable, Sendable {
    let id: UUID
    var title: String
    var totalPages: Int?
    var lastPage: Int
    var addedAt: Date
    /// 記録の durationSeconds の和。
    var totalSeconds: Int
    var sessionCount: Int
    /// 記録の savedAt の最大。記録がなければ nil。
    var lastSavedAt: Date?

    var totalMinutes: Int { ReadingMath.wholeMinutes(seconds: totalSeconds) }
    var progressPercent: Int? { ReadingMath.progressPercent(lastPage: lastPage, totalPages: totalPages) }

    /// 記録から合計、件数、最後の保存の時刻を数え直す（最後のページは変えない。AC-16）。
    mutating func recount(_ sessions: [SessionSnapshot]) {
        totalSeconds = sessions.reduce(0) { $0 + $1.durationSeconds }
        sessionCount = sessions.count
        lastSavedAt = sessions.map(\.savedAt).max()
    }
}

/// 画面に渡す記録の値。
nonisolated struct SessionSnapshot: Identifiable, Equatable, Sendable {
    let id: UUID
    let bookID: UUID
    var startedAt: Date
    var durationSeconds: Int
    var endPage: Int?
    var pagesRead: Int?
    var savedAt: Date

    var minutes: Int { ReadingMath.wholeMinutes(seconds: durationSeconds) }

    /// 記録の行は読み始めた時刻の新しい順（D-32）。
    static func newestFirst(_ lhs: SessionSnapshot, _ rhs: SessionSnapshot) -> Bool {
        if lhs.startedAt != rhs.startedAt { return lhs.startedAt > rhs.startedAt }
        return lhs.id.uuidString < rhs.id.uuidString
    }
}

/// 画面に渡す進行中の読書の値。
nonisolated struct ActiveSnapshot: Equatable, Sendable {
    var bookID: UUID
    var state: ReadingState
    var startedAt: Date
    var pausedTotalSeconds: Double
    var pausedAt: Date?
    var finishedAt: Date?
    var wasPaused: Bool

    /// 経過の終わりの時刻：reading は今、paused は pausedAt、finishing は finishedAt。
    func endOfElapsed(now: Date) -> Date {
        switch state {
        case .reading: now
        case .paused: pausedAt ?? now
        case .finishing: finishedAt ?? now
        }
    }

    func elapsedInterval(now: Date) -> TimeInterval {
        ReadingMath.elapsed(start: startedAt, end: endOfElapsed(now: now), pausedTotal: pausedTotalSeconds)
    }

    func elapsedSeconds(now: Date) -> Int {
        ReadingMath.wholeSeconds(elapsedInterval(now: now))
    }

    /// 終える入力の分の欄の初めの値（finishing のとき。finishedAt から計算し、保存しない。AC-30、AC-34）。
    var initialMinutes: Int? {
        guard state == .finishing, let finishedAt else { return nil }
        return ReadingMath.wholeMinutes(seconds: elapsedSeconds(now: finishedAt))
    }
}

/// 「終える」を押した結果（D-59：押した時点の経過で分ける）。
nonisolated enum FinishOutcome: Equatable, Sendable {
    /// 60秒以上：finishing になり、終える入力を開く。
    case finishing
    /// 60秒未満：記録せずに idle になる。本の詳細に出す。
    case discarded(bookID: UUID)
}
