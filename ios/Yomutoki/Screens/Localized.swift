import Foundation
import SwiftUI

/// design 7 の文言のうち、数や題名を入れる文（書式のキー）。数を入れない文は Text("キー") で String Catalog から直接引く。
/// キーは String Catalog（Resources/Localizable.xcstrings）に手で登録したもの（extractionState は manual）。
/// 数の書式（design 7 の決まり）：
/// - 分、冊、件は地域の書式（桁区切りあり）。String(localized:defaultValue:locale:) の locale が数の書式を決める。
/// - ページの数（ページ番号、読んだページ、入力の範囲の文の数）は桁区切りなし。書式の文を引いて String(format:) で入れる。
enum Loc {
    // MARK: 分、冊、件（桁区切りあり）

    static func minutes(_ value: Int, locale: Locale) -> String {
        String(
            localized: "format.minutes", defaultValue: "\(value)分", locale: locale,
            comment: "分の数（S1 の今週、S3 の合計時間、記録の行の分）")
    }

    static func bookCount(_ value: Int, locale: Locale) -> String {
        String(localized: "home.bookCount", defaultValue: "\(value)冊", locale: locale, comment: "S1 の冊数の見出し")
    }

    static func sessionCount(_ value: Int, locale: Locale) -> String {
        String(
            localized: "book.sessionCount", defaultValue: "記録 \(value)件", locale: locale, comment: "S3 の記録の見出し")
    }

    static func percent(_ value: Int, locale: Locale) -> String {
        String(localized: "format.percent", defaultValue: "\(value)%", locale: locale, comment: "S3 の進み具合の値")
    }

    static func savedAnnouncement(minutes value: Int, locale: Locale) -> String {
        String(
            localized: "session.saved.announcement", defaultValue: "\(value)分を記録しました。", locale: locale,
            comment: "読書を保存して S3 に出たときの VoiceOver の知らせ")
    }

    static func deleteMessage(minutes value: Int, locale: Locale) -> String {
        String(
            localized: "session.delete.message",
            defaultValue: "合計時間から\(value)分を引きます。最後のページは変わりません。消した記録は元に戻せません。", locale: locale,
            comment: "S6 の alert の本文")
    }

    static func minutesHint(minutes value: Int, locale: Locale) -> String {
        String(
            localized: "session.finish.minutes.hint", defaultValue: "経過は\(value)分です。読んでいない時間があれば、短く直せます。",
            locale: locale, comment: "S5 の読んだ時間の下")
    }

    static func titleLimitOnSave(_ limit: Int, locale: Locale) -> String {
        String(
            localized: "book.add.titleLimit.onSave", defaultValue: "題名は\(limit)字までです。超えた分は保存しません。",
            locale: locale, comment: "S2 の題名の欄の下（形B）")
    }

    // MARK: 題名を入れる文

    /// home.primary.a11y：S1 の主操作と、その場所の error.retry の VoiceOver のラベル（題名が先頭）。
    static func homePrimary(title: String, action: String) -> String {
        String(localized: "home.primary.a11y", defaultValue: "\(title)、\(action)", comment: "1つ目は題名、2つ目は操作の文")
    }

    static func startBusy(title: String) -> String {
        String(
            localized: "book.start.busy", defaultValue: "「\(title)」を読書中です。その読書を終えると、この本で読み始められます。",
            comment: "S3 の主操作の上（別の本が読書中）")
    }

    // MARK: ページの数（桁区切りなし）

    static func readFromPage(_ page: Int) -> String { ungrouped("action.readFromPage", page) }

    static func fromPage(_ page: Int) -> String { ungrouped("reading.fromPage", page) }

    static func pagesRead(_ pages: Int) -> String { ungrouped("session.row.pages", pages) }

    static func pageHint(lastPage: Int) -> String { ungrouped("session.finish.page.hint", lastPage) }

    static func pageOutOfRange(max: Int) -> String { ungrouped("session.finish.pageOutOfRange", max) }

    static func minutesOutOfRange(max: Int) -> String { ungrouped("session.finish.minutesOutOfRange", max) }

    /// String Catalog の書式の文を引き、locale なし（桁区切りなし）で数を入れる。複数形の形は書式の文が持つ。
    private static func ungrouped(_ key: String, _ value: Int) -> String {
        let format = Bundle.main.localizedString(forKey: key, value: nil, table: nil)
        return String(format: format, value)
    }

    // MARK: 操作の文

    static var startText: String { String(localized: "action.start", defaultValue: "読み始める") }
    static var continueText: String { String(localized: "action.continue", defaultValue: "続きを読む") }
    static var resumeText: String { String(localized: "action.resume", defaultValue: "読書に戻る") }
    static var resumePausedText: String { String(localized: "action.resumePaused", defaultValue: "一時停止中の読書に戻る") }
    static var retryStartText: String { String(localized: "error.retry.start", defaultValue: "もう一度読み始める") }
    static var saveFailedText: String { String(localized: "error.saveFailed", defaultValue: "変更を保存できませんでした") }
    static var tooShortText: String {
        String(localized: "session.finish.tooShort", defaultValue: "1分未満だったので、記録しませんでした。")
    }

    /// S1 と S3 の主操作（idle）の文（D-7）：最後のページが1以上なら「72ページから読む」、0で記録があれば「続きを読む」、なければ「読み始める」。
    static func startAction(for book: BookSnapshot) -> String {
        if book.lastPage >= 1 { return readFromPage(book.lastPage) }
        return book.sessionCount >= 1 ? continueText : startText
    }

    /// 読書中の本へ戻る操作の文（AC-52）：paused は「一時停止中の読書に戻る」、reading と finishing は「読書に戻る」。
    static func resumeAction(for state: ReadingState) -> String {
        switch state {
        case .paused: resumePausedText
        case .reading: resumeText
        case .finishing: resumeText
        }
    }

    // MARK: 経過の読み上げ（design 7 の経過の表。0の単位も省かない）

    static func elapsed(_ totalSeconds: Int, locale: Locale) -> String {
        let parts = ElapsedFormat.parts(totalSeconds)
        if ElapsedFormat.isUnderOneHour(totalSeconds) {
            return String(
                localized: "reading.elapsed.ms", defaultValue: "\(parts.minutes)分\(parts.seconds)秒", locale: locale,
                comment: "S4 の経過の VoiceOver のラベル（60分未満）")
        }
        return String(
            localized: "reading.elapsed.hms", defaultValue: "\(parts.hours)時間\(parts.minutes)分\(parts.seconds)秒",
            locale: locale, comment: "S4 の経過の VoiceOver のラベル（60分以上）")
    }
}

/// VoiceOver への知らせ（design 9 の「知らせ」。AccessibilityNotification.Announcement。A62）。
enum Announce {
    static func post(_ text: String) {
        AccessibilityNotification.Announcement(text).post()
    }

    /// 保存に失敗したとき（再試行がまた失敗したときも）1回。
    static func saveFailed() {
        post(Loc.saveFailedText)
    }
}
