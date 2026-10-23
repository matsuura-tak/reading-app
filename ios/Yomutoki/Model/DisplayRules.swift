import Foundation

// 画面の入力と表示の決まり（design/001-reading-session.md の 7 の「入力の決まり」と「経過の表示と読み上げ」）。
// 純粋な関数だけを置き、単体テストで確かめる（YomutokiTests/DisplayRulesTests.swift）。

/// 数字の欄の読み方（D-13、design 7 の入力の決まり）。
nonisolated enum NumberInput {
    /// 欄の文字を読んだ結果。
    enum Parsed: Equatable, Sendable {
        /// 前後の空白を除くと何もない。
        case empty
        /// 数字だけでできた値。
        case number(Int)
        /// 数字以外の文字がある（桁区切り、小数点、符号、文字）か、桁がとても多い。範囲の外と同じ誤りにする。
        case invalid
    }

    /// これを超える値は、どの欄でも範囲の外なので数えるのをやめる（とても長い数字で落ちないため）。
    static let ceiling = 1_000_000

    /// 前後の空白（半角、全角、改行、タブ）を除き、全角の数字は半角として読む。欄の文字そのものは変えない。
    static func parse(_ text: String) -> Parsed {
        let trimmed = TitleRules.trimmed(text)
        guard !trimmed.isEmpty else { return .empty }
        var value = 0
        var overflow = false
        for scalar in trimmed.unicodeScalars {
            let digit: UInt32
            switch scalar.value {
            case 0x30...0x39: digit = scalar.value - 0x30
            case 0xFF10...0xFF19: digit = scalar.value - 0xFF10
            default: return .invalid
            }
            if overflow { continue }
            value = value * 10 + Int(digit)
            if value > ceiling { overflow = true }
        }
        return overflow ? .invalid : .number(value)
    }

    /// 範囲の中の値なら返す。空、数字でない、範囲の外は nil。
    static func value(_ text: String, in range: ClosedRange<Int>) -> Int? {
        guard case .number(let value) = parse(text), range.contains(value) else { return nil }
        return value
    }
}

/// 経過の見える文字（design 7 の経過の表）。60分未満は「分:秒」、60分以上は「時:分:秒」。区切りは ja と en ともにコロン。
nonisolated enum ElapsedFormat {
    struct Parts: Equatable, Sendable {
        let hours: Int
        let minutes: Int
        let seconds: Int
    }

    /// 負の値は 0 にする（AC-41）。
    static func parts(_ totalSeconds: Int) -> Parts {
        let total = max(0, totalSeconds)
        return Parts(hours: total / 3_600, minutes: (total % 3_600) / 60, seconds: total % 60)
    }

    /// 60分未満か（読み上げのキーを reading.elapsed.ms と reading.elapsed.hms で分ける）。
    static func isUnderOneHour(_ totalSeconds: Int) -> Bool {
        max(0, totalSeconds) < 3_600
    }

    /// 0:00、12:30、59:59、1:00:00、30:00:00。分（60分未満）と時は0で埋めず、秒と（60分以上の）分は2桁。
    static func clock(_ totalSeconds: Int) -> String {
        let value = parts(totalSeconds)
        let seconds = twoDigits(value.seconds)
        if isUnderOneHour(totalSeconds) {
            return "\(value.minutes):\(seconds)"
        }
        return "\(value.hours):\(twoDigits(value.minutes)):\(seconds)"
    }

    private static func twoDigits(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }
}
