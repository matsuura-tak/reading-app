import Foundation

/// W-1・W-2・W-3 の読み上げに使う文（design/ 6 の W-1〜W-3、design/ 7 の文言キー、決まり 53、AC-99）。
/// ReadingCore は String Catalog を持たないので、アプリと拡張が文言キーを通した文を入れて渡す
/// （`ReadingWidgetStrings.spoken`）。`japanese` と `english` は design/ 7 の値の写しで、単体テストと既定値に使う。
public struct WidgetSpokenStrings: Sendable, Equatable {
    /// `widget.empty`
    public var empty: String
    /// `widget.unavailable`
    public var unavailable: String
    /// `widget.hidden`
    public var hidden: String
    /// `widget.currentBookAsTitle`
    public var currentBookAsTitle: String
    /// `page.spoken`（%lld）
    public var pageFormat: String
    /// `location.spoken`（%lld）
    public var locationFormat: String
    /// `percent.spoken`（%lld）
    public var percentFormat: String
    /// `widget.spoken`（書名、場所、一行）
    public var spokenFormat: String
    /// `widget.spoken.noPage`（書名、一行）
    public var spokenNoPageFormat: String
    /// `widget.spoken.noLine`（書名、場所）
    public var spokenNoLineFormat: String

    public nonisolated init(
        empty: String,
        unavailable: String,
        hidden: String,
        currentBookAsTitle: String,
        pageFormat: String,
        locationFormat: String,
        percentFormat: String,
        spokenFormat: String,
        spokenNoPageFormat: String,
        spokenNoLineFormat: String
    ) {
        self.empty = empty
        self.unavailable = unavailable
        self.hidden = hidden
        self.currentBookAsTitle = currentBookAsTitle
        self.pageFormat = pageFormat
        self.locationFormat = locationFormat
        self.percentFormat = percentFormat
        self.spokenFormat = spokenFormat
        self.spokenNoPageFormat = spokenNoPageFormat
        self.spokenNoLineFormat = spokenNoLineFormat
    }

    public static let japanese = WidgetSpokenStrings(
        empty: "今の本を選ぶと、ここに続きの一行が出ます。",
        unavailable: "よむまを開くと、ここに続きの一行が出ます。",
        hidden: "しおり",
        currentBookAsTitle: "今の本",
        pageFormat: "%lldページ",
        locationFormat: "位置%lld",
        percentFormat: "%lldパーセント",
        spokenFormat: "%1$@、%2$@。%3$@",
        spokenNoPageFormat: "%1$@。%2$@",
        spokenNoLineFormat: "%1$@、%2$@"
    )

    public static let english = WidgetSpokenStrings(
        empty: "Choose a book in Yomuma to see your place here.",
        unavailable: "Open Yomuma to show your place here.",
        hidden: "Bookmark",
        currentBookAsTitle: "Reading Now",
        pageFormat: "page %lld",
        locationFormat: "location %lld",
        percentFormat: "%lld percent",
        spokenFormat: "%1$@, %2$@. %3$@",
        spokenNoPageFormat: "%1$@. %2$@",
        spokenNoLineFormat: "%1$@, %2$@"
    )

    /// 場所の表示（「p.61」「位置1450」「Loc 1450」「52%」）を読み上げの文（「61ページ」「位置1450」「52パーセント」）にする。
    /// 単位が分からないとき（Live Activity の状態など）は表示の形から決める。数字がなければ nil。
    public nonisolated func spokenProgress(unit: ProgressUnit?, display: String?) -> String? {
        guard let display, let number = Self.firstInteger(in: display) else { return nil }
        let resolved: ProgressUnit
        if let unit {
            resolved = unit
        } else if display.contains("%") {
            resolved = .percent
        } else if display.lowercased().hasPrefix("p") {
            resolved = .page
        } else {
            resolved = .location
        }
        let format: String
        switch resolved {
        case .page: format = pageFormat
        case .location: format = locationFormat
        case .percent: format = percentFormat
        }
        return String(format: format, locale: nil, number)
    }

    /// 書名、場所、一行を design/ 6 の書式で1つの文にする（どれがないかで `widget.spoken`、`.noPage`、`.noLine`、書名だけを選ぶ）。
    public nonisolated func spokenLabel(title: String, place: String?, line: String?) -> String {
        switch (place, line) {
        case let (place?, line?):
            return String(format: spokenFormat, locale: nil, title, place, line)
        case let (nil, line?):
            return String(format: spokenNoPageFormat, locale: nil, title, line)
        case let (place?, nil):
            return String(format: spokenNoLineFormat, locale: nil, title, place)
        case (nil, nil):
            return title
        }
    }

    private nonisolated static func firstInteger(in text: String) -> Int64? {
        var digits = ""
        for character in text {
            if let value = character.wholeNumberValue, character.isASCII {
                digits.append(String(value))
            } else if !digits.isEmpty {
                break
            }
        }
        return Int64(digits)
    }
}
