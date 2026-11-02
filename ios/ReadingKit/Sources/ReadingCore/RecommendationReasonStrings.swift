import Foundation

/// 推薦の理由の文（S-9 の `next.reason`、S-1 の候補、S-7 の `after.reason`。design/ 7 の「推薦の理由のキーの選び方」、決定 85）。
/// 軸と「積読にある本か」の組ごとに1つの文言キーから作り、「積読から・」と軸の文をコードでつながない。
/// ReadingCore は String Catalog を持たないので、アプリが String Catalog を通した書式を入れて渡す
/// （`RecommendationReasonStrings.localized`、ReadingApp/Intents/ReadingAppIntents.swift）。
/// 渡されないときは `keys`（文言キーの名前そのもの）が出るので、渡し忘れが分かる。
public struct RecommendationReasonStrings: Sendable, Equatable {
    /// `next.reason.tsundoku`（どの軸にも当たらない積読の本）
    public var nextTsundoku: String
    /// `next.reason.readers`
    public var nextReaders: String
    /// `next.reason.nextVolume`
    public var nextNextVolume: String
    /// `next.reason.sameAuthor`
    public var nextSameAuthor: String
    /// `next.reason.sameAward`（%@ は賞の表示名）
    public var nextSameAwardFormat: String
    /// `next.reason.sameLabel`（%@ はレーベル名）
    public var nextSameLabelFormat: String
    /// `rec.reason.readers`
    public var recReaders: String
    /// `rec.reason.nextVolume`
    public var recNextVolume: String
    /// `rec.reason.sameAuthor`
    public var recSameAuthor: String
    /// `rec.reason.sameAward`（%@ は賞の表示名）
    public var recSameAwardFormat: String
    /// `rec.reason.sameLabel`（%@ はレーベル名）
    public var recSameLabelFormat: String

    public nonisolated init(
        nextTsundoku: String,
        nextReaders: String,
        nextNextVolume: String,
        nextSameAuthor: String,
        nextSameAwardFormat: String,
        nextSameLabelFormat: String,
        recReaders: String,
        recNextVolume: String,
        recSameAuthor: String,
        recSameAwardFormat: String,
        recSameLabelFormat: String
    ) {
        self.nextTsundoku = nextTsundoku
        self.nextReaders = nextReaders
        self.nextNextVolume = nextNextVolume
        self.nextSameAuthor = nextSameAuthor
        self.nextSameAwardFormat = nextSameAwardFormat
        self.nextSameLabelFormat = nextSameLabelFormat
        self.recReaders = recReaders
        self.recNextVolume = recNextVolume
        self.recSameAuthor = recSameAuthor
        self.recSameAwardFormat = recSameAwardFormat
        self.recSameLabelFormat = recSameLabelFormat
    }

    /// 文言キーの名前そのもの（アプリが文を渡す前の既定値）。
    public static let keys = RecommendationReasonStrings(
        nextTsundoku: "next.reason.tsundoku",
        nextReaders: "next.reason.readers",
        nextNextVolume: "next.reason.nextVolume",
        nextSameAuthor: "next.reason.sameAuthor",
        nextSameAwardFormat: "next.reason.sameAward",
        nextSameLabelFormat: "next.reason.sameLabel",
        recReaders: "rec.reason.readers",
        recNextVolume: "rec.reason.nextVolume",
        recSameAuthor: "rec.reason.sameAuthor",
        recSameAwardFormat: "rec.reason.sameAward",
        recSameLabelFormat: "rec.reason.sameLabel"
    )

    /// どの軸にも当たらない積読の本の理由（`next.reason.tsundoku`）。
    public nonisolated var tsundoku: String { nextTsundoku }

    /// 軸と「積読にある本か」の組の理由。賞やレーベルの名前が要る軸で名前が空なら nil（その軸を使わない。決定 85）。
    /// - Parameter name: 同じ賞なら賞の表示名、同じレーベルならレーベル名。ほかの軸では使わない。
    public nonisolated func reason(axis: RecommendationAxis, isOwnedTsundoku: Bool, name: String? = nil) -> String? {
        let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        switch axis {
        case .readers:
            return isOwnedTsundoku ? nextReaders : recReaders
        case .nextVolume:
            return isOwnedTsundoku ? nextNextVolume : recNextVolume
        case .sameAuthor:
            return isOwnedTsundoku ? nextSameAuthor : recSameAuthor
        case .sameAward:
            guard !trimmedName.isEmpty else { return nil }
            return Self.fill(isOwnedTsundoku ? nextSameAwardFormat : recSameAwardFormat, trimmedName)
        case .sameLabel:
            guard !trimmedName.isEmpty else { return nil }
            return Self.fill(isOwnedTsundoku ? nextSameLabelFormat : recSameLabelFormat, trimmedName)
        }
    }

    /// `%@` に名前を入れる。名前の中の `%` は書式として読まない。
    private nonisolated static func fill(_ format: String, _ name: String) -> String {
        String(format: format, locale: nil, name)
    }
}
