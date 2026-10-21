import Foundation

/// テストを動かす言語。Acceptance.xctestplan の構成（ja_JP、en_US）が、テストを動かす側の環境変数 ACCEPTANCE_LANG で渡す。
enum Lang: String, Sendable {
    case ja, en
}

/// 期待する文字。design/001-reading-session.md の 7（文言の表と、経過の表示と読み上げの表）の ja と en をそのまま写した。
/// 実装の出力に合わせて直さない。直すのは design/ の 7 が変わったときだけ（変えた行を verification.md に書く）。
enum L10n {
    static let lang: Lang = {
        if let value = ProcessInfo.processInfo.environment["ACCEPTANCE_LANG"], let lang = Lang(rawValue: value) {
            return lang
        }
        return (Locale.preferredLanguages.first ?? "ja").hasPrefix("en") ? .en : .ja
    }()

    /// T4：-AppleLanguages の値と、-AppleLocale と UITEST_LOCALE の値。
    static var appleLanguages: String { lang == .ja ? "(ja)" : "(en)" }
    static var localeID: String { lang == .ja ? "ja_JP" : "en_US" }

    static func pick(_ ja: String, _ en: String) -> String { lang == .ja ? ja : en }

    // MARK: 7 の文言（キーの名前をそのまま関数の名前にした）

    static var homeTitle: String { pick("読書", "Reading") }
    static var libraryEmptyTitle: String { pick("本がまだありません", "No Books Yet") }
    static var libraryEmptyMessage: String {
        pick(
            "読んでいる本の題名を入れると、すぐに読み始められます。",
            "Enter the title of a book you're reading, and you can start right away.")
    }
    static var actionStart: String { pick("読み始める", "Start Reading") }
    static var actionContinue: String { pick("続きを読む", "Continue Reading") }
    static var actionResume: String { pick("読書に戻る", "Return to Reading") }
    static var actionResumePaused: String { pick("一時停止中の読書に戻る", "Return to Paused Reading") }
    static func actionReadFromPage(_ page: Int) -> String { pick("\(page)ページから読む", "Read from Page \(page)") }
    /// home.primary.a11y（%1$@、%2$@）
    static func homePrimary(_ title: String, _ action: String) -> String { pick("\(title)、\(action)", "\(title), \(action)") }
    static var bookAddTotalPagesOutOfRange: String { pick("1から9999までの数字で入れてください。", "Enter a number from 1 to 9999.") }
    static var commonCancel: String { pick("キャンセル", "Cancel") }
    static var commonOK: String { pick("OK", "OK") }
    static var bookAddDiscardConfirm: String { pick("追加せずに閉じる", "Close Without Adding") }
    static var errorSaveFailed: String { pick("変更を保存できませんでした", "Couldn't Save Changes") }
    static var errorSaveFailedBook: String {
        pick("入れた題名はそのままです。もう一度保存してください。", "What you entered is still here. Try saving again.")
    }
    static var errorSaveFailedSession: String {
        pick(
            "読書は消えていません。読んだ時間も変わっていません。もう一度保存してください。",
            "Your reading session is still here, and the time hasn't changed. Try saving again.")
    }
    static var errorSaveFailedDelete: String {
        pick("記録は消えていません。もう一度消してください。", "The session wasn't deleted. Try deleting it again.")
    }
    static var errorSaveFailedStart: String {
        pick("読書はまだ始まっていません。時間は数えていません。", "Your reading session hasn't started, and the timer isn't running.")
    }
    static var errorSaveFailedPause: String {
        pick("読書は止まっていません。時間は数え続けています。", "Your reading isn't paused. The timer is still running.")
    }
    static var errorSaveFailedResume: String {
        pick("読書は一時停止のままです。時間は止まっています。", "Your reading is still paused. The timer is stopped.")
    }
    static var errorSaveFailedFinish: String {
        pick(
            "読書はまだ終わっていません。ここまでの時間は消えていません。",
            "Your reading session hasn't ended. The time so far hasn't been lost.")
    }
    static var errorSaveFailedCancel: String {
        pick(
            "まだ読書に戻っていません。入れた値はそのままです。この画面にいる間の時間は数えません。",
            "You haven't returned to reading yet. What you entered is still here. Time on this screen isn't counted.")
    }
    static var errorRetry: String { pick("もう一度保存", "Save Again") }
    static var errorRetryStart: String { pick("もう一度読み始める", "Try Starting Again") }
    static var errorRetryPause: String { pick("もう一度一時停止", "Try Pausing Again") }
    static var errorRetryResume: String { pick("もう一度再開", "Try Resuming Again") }
    static var errorRetryFinish: String { pick("もう一度終える", "Try Finishing Again") }
    static var errorRetryCancel: String { pick("もう一度読書に戻る", "Try Returning to Reading Again") }
    static var errorLoadFailedTitle: String { pick("本と記録を読み込めませんでした", "Couldn't Load Your Books") }
    static var errorLoadFailedMessage: String {
        pick("端末の中の記録は消していません。もう一度読み込んでください。", "Nothing on this iPhone was deleted. Try loading again.")
    }
    static var errorLoadFailedRetry: String { pick("もう一度読み込む", "Load Again") }
    static var bookSessionsEmpty: String {
        pick("まだ記録はありません。読書を終えると、ここに残ります。", "No sessions yet. Finished sessions appear here.")
    }
    static var sessionRowDelete: String { pick("削除", "Delete") }
    static func bookStartBusy(_ title: String) -> String {
        pick("「\(title)」を読書中です。その読書を終えると、この本で読み始められます。", "You're reading “\(title).” Finish that session to start this book.")
    }
    static var sessionFinishTooShort: String {
        pick("1分未満だったので、記録しませんでした。", "That was under a minute, so it wasn't saved.")
    }
    static var sessionDeleteConfirm: String { pick("記録を消す", "Delete Session") }
    static var readingStateReading: String { pick("読書中", "Reading") }
    static var readingStatePaused: String { pick("一時停止中", "Paused") }
    static func sessionFinishPageOutOfRange(_ max: Int) -> String {
        pick("0から\(max)までの数字で入れてください。", "Enter a number from 0 to \(max).")
    }
    static func sessionFinishMinutesOutOfRange(_ max: Int) -> String {
        pick("1から\(max)までの数字で入れてください。", "Enter a number from 1 to \(max).")
    }

    // MARK: システムの部品の文字（design 6 の (b)。識別子が付かないときだけ使う）

    /// 戻るボタン。前の画面の題（S1 は home.title）か、システムの「戻る」。
    static var backButtonLabels: [String] { [homeTitle, pick("戻る", "Back")] }
    /// 編集メニューの「ペースト」（システムの文字。AC-3 の改行とタブを入れるため）。
    static var systemPaste: String { pick("ペースト", "Paste") }

    // MARK: 数の書式（7 の決まり：分、冊、件は地域の書式で桁区切りあり。ページの数は桁区切りなし）

    static func grouped(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: localeID)
        f.usesGroupingSeparator = true
        return f.string(from: NSNumber(value: n)) ?? String(n)
    }

    private static func plural(_ n: Int, _ one: String, _ other: String) -> String {
        n == 1 ? "\(grouped(n)) \(one)" : "\(grouped(n)) \(other)"
    }

    /// format.minutes（「60分」「60 minutes」「1 minute」）
    static func minutes(_ n: Int) -> String { lang == .ja ? "\(grouped(n))分" : plural(n, "minute", "minutes") }
    /// home.bookCount（「21冊」「21 books」）
    static func bookCount(_ n: Int) -> String { lang == .ja ? "\(grouped(n))冊" : plural(n, "book", "books") }
    /// book.sessionCount（「記録 3件」「3 sessions」）
    static func sessionCount(_ n: Int) -> String { lang == .ja ? "記録 \(grouped(n))件" : plural(n, "session", "sessions") }
    /// session.row.pages（「32ページ進んだ」「32 pages read」「1 page read」）。ページの数は桁区切りなし。
    static func pagesRead(_ n: Int) -> String {
        lang == .ja ? "\(n)ページ進んだ" : (n == 1 ? "1 page read" : "\(n) pages read")
    }
    /// format.percent（ja と en ともに「24%」）
    static func percent(_ n: Int) -> String { "\(n)%" }

    /// reading.elapsed の label（7 の経過の表。reading.elapsed.ms と reading.elapsed.hms。0 の単位も省かない）。
    static func elapsedLabel(_ totalSeconds: Int) -> String {
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        let s = totalSeconds % 60
        func unit(_ v: Int, _ one: String, _ other: String) -> String { "\(v) \(v == 1 ? one : other)" }
        if totalSeconds < 3600 {
            return lang == .ja ? "\(m)分\(s)秒" : "\(unit(m, "minute", "minutes")), \(unit(s, "second", "seconds"))"
        }
        return lang == .ja
            ? "\(h)時間\(m)分\(s)秒"
            : "\(unit(h, "hour", "hours")), \(unit(m, "minute", "minutes")), \(unit(s, "second", "seconds"))"
    }

    /// 範囲の秒（両端を含む）の label の並び。AC の「11:00 以上 11:05 以下」をそのまま表す。
    static func elapsedLabels(_ seconds: ClosedRange<Int>) -> [String] { seconds.map { elapsedLabel($0) } }
}
