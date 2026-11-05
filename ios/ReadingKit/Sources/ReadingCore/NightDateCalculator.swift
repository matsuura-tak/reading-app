import Foundation

public struct NightRecordInput: Sendable, Equatable {
    public var startedAt: String
    public var durationSeconds: Int
    public var timeZoneID: String
    public var precomputedNightDate: String?

    public nonisolated init(
        startedAt: String,
        durationSeconds: Int,
        timeZoneID: String = "Asia/Tokyo",
        precomputedNightDate: String? = nil
    ) {
        self.startedAt = startedAt
        self.durationSeconds = durationSeconds
        self.timeZoneID = timeZoneID
        self.precomputedNightDate = precomputedNightDate
    }
}

public struct NightTotal: Sendable, Equatable {
    public var nightDate: String
    public var totalSeconds: Int
    public var totalMinutes: Int
    public var month: Int
    public var day: Int

    public nonisolated init(
        nightDate: String,
        totalSeconds: Int,
        totalMinutes: Int,
        month: Int,
        day: Int
    ) {
        self.nightDate = nightDate
        self.totalSeconds = totalSeconds
        self.totalMinutes = totalMinutes
        self.month = month
        self.day = day
    }
}

public struct FinishReflectionSummary: Sendable, Equatable {
    public var uniqueNights: Int
    public var totalSeconds: Int
    public var totalMinutes: Int
    public var longestNight: NightTotal
    public var japaneseText: String
    public var englishText: String

    public nonisolated init(
        uniqueNights: Int,
        totalSeconds: Int,
        totalMinutes: Int,
        longestNight: NightTotal,
        japaneseText: String,
        englishText: String
    ) {
        self.uniqueNights = uniqueNights
        self.totalSeconds = totalSeconds
        self.totalMinutes = totalMinutes
        self.longestNight = longestNight
        self.japaneseText = japaneseText
        self.englishText = englishText
    }
}

public enum NightDateCalculator: Sendable {
    public static let boundaryHour: Int = 4

    /// Computes the `YYYY-MM-DD` night date by subtracting 4 hours in the given `timeZoneID` (AC-22).
    public nonisolated static func nightDate(for startedAt: Date, timeZoneID: String) -> String {
        let timeZone = TimeZone(identifier: timeZoneID) ?? TimeZone(identifier: "Asia/Tokyo") ?? .gmt
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let shifted = calendar.date(byAdding: .hour, value: -boundaryHour, to: startedAt)
            ?? startedAt.addingTimeInterval(TimeInterval(-boundaryHour * 3600))
        let components = calendar.dateComponents([.year, .month, .day], from: shifted)
        let year = components.year ?? 1970
        let month = components.month ?? 1
        let day = components.day ?? 1
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    /// Parses an ISO-8601 timestamp string into a `Date`.
    public nonisolated static func parseISO8601(_ isoString: String) -> Date? {
        let withFractional = ISO8601DateFormatter()
        withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFractional.date(from: isoString) {
            return date
        }
        let standard = ISO8601DateFormatter()
        standard.formatOptions = [.withInternetDateTime]
        return standard.date(from: isoString)
    }

    /// Computes the `YYYY-MM-DD` night date from an ISO-8601 string and `timeZoneID`.
    public nonisolated static func nightDate(startedAtISO8601: String, timeZoneID: String) -> String? {
        guard let date = parseISO8601(startedAtISO8601) else {
            return nil
        }
        return nightDate(for: date, timeZoneID: timeZoneID)
    }

    /// Extracts `(month, day)` from a `YYYY-MM-DD` string.
    public nonisolated static func parseMonthAndDay(from nightDate: String) -> (month: Int, day: Int) {
        let parts = nightDate.split(separator: "-")
        guard parts.count == 3,
              let month = Int(parts[1]),
              let day = Int(parts[2]) else {
            return (1, 1)
        }
        return (month, day)
    }

    /// Formats total minutes as hours+minutes in Japanese (e.g. 142 -> "2時間22分", 120 -> "2時間", 45 -> "45分").
    public nonisolated static func formatHoursAndMinutesJapanese(_ totalMinutes: Int) -> String {
        let hours = totalMinutes / 60
        let rem = totalMinutes % 60
        if hours > 0 {
            if rem > 0 {
                return "\(hours)時間\(rem)分"
            } else {
                return "\(hours)時間"
            }
        }
        return "\(totalMinutes)分"
    }

    /// Formats total minutes as hours+minutes in English (e.g. 142 -> "2 hr 22 min").
    public nonisolated static func formatHoursAndMinutesEnglish(_ totalMinutes: Int) -> String {
        let hours = totalMinutes / 60
        let rem = totalMinutes % 60
        if hours > 0 {
            if rem > 0 {
                return "\(hours) hr \(rem) min"
            } else {
                return "\(hours) hr"
            }
        }
        return "\(totalMinutes) min"
    }

    /// Aggregates reading records by `nightDate` and builds the S-8 finish reflection summary (AC-85, AC-127, AC-128, AC-129).
    /// Returns `nil` when `records` is empty (AC-129).
    public nonisolated static func buildFinishReflection(from records: [NightRecordInput]) -> FinishReflectionSummary? {
        guard !records.isEmpty else {
            return nil
        }

        var secondsByNight: [String: Int] = [:]
        var totalSeconds = 0

        for record in records {
            let resolvedNight: String
            if let pre = record.precomputedNightDate, !pre.isEmpty {
                resolvedNight = pre
            } else if let computed = nightDate(startedAtISO8601: record.startedAt, timeZoneID: record.timeZoneID) {
                resolvedNight = computed
            } else {
                resolvedNight = "1970-01-01"
            }
            let clamped = max(0, record.durationSeconds)
            secondsByNight[resolvedNight, default: 0] += clamped
            totalSeconds += clamped
        }

        guard !secondsByNight.isEmpty else {
            return nil
        }

        let nightTotals: [NightTotal] = secondsByNight.map { (night, secs) in
            let mins = secs > 0 ? max(1, Int((Double(secs) / 60.0).rounded())) : 0
            let md = parseMonthAndDay(from: night)
            return NightTotal(
                nightDate: night,
                totalSeconds: secs,
                totalMinutes: mins,
                month: md.month,
                day: md.day
            )
        }

        // Longest night: highest totalMinutes (or totalSeconds); ties broken by newer nightDate (AC-128)
        let sortedNights = nightTotals.sorted { lhs, rhs in
            if lhs.totalMinutes != rhs.totalMinutes {
                return lhs.totalMinutes > rhs.totalMinutes
            }
            if lhs.totalSeconds != rhs.totalSeconds {
                return lhs.totalSeconds > rhs.totalSeconds
            }
            return lhs.nightDate > rhs.nightDate
        }

        guard let longestNight = sortedNights.first else {
            return nil
        }

        let uniqueNights = nightTotals.count
        let totalMinutes = totalSeconds > 0 ? max(1, Int((Double(totalSeconds) / 60.0).rounded())) : 0

        let japaneseText: String
        let englishText: String

        if uniqueNights == 1 {
            japaneseText = "1晩、\(totalMinutes)分で読み終えました。"
            englishText = "Finished in 1 night, \(totalMinutes) min."
        } else {
            let hmJa = formatHoursAndMinutesJapanese(totalMinutes)
            let hmEn = formatHoursAndMinutesEnglish(totalMinutes)
            japaneseText = "\(uniqueNights)晩、合計\(totalMinutes)分（\(hmJa)）。いちばん長かったのは\(longestNight.month)月\(longestNight.day)日の晩の\(longestNight.totalMinutes)分でした。"
            englishText = "\(uniqueNights) nights, \(totalMinutes) min (\(hmEn)) total. Longest was \(longestNight.totalMinutes) min on \(longestNight.month)/\(longestNight.day)."
        }

        return FinishReflectionSummary(
            uniqueNights: uniqueNights,
            totalSeconds: totalSeconds,
            totalMinutes: totalMinutes,
            longestNight: longestNight,
            japaneseText: japaneseText,
            englishText: englishText
        )
    }
}
