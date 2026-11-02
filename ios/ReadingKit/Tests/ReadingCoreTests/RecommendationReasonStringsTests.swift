import Foundation
import Testing
@testable import ReadingCore

// design/ 7 の ja・en の写し（テストのターゲットの中だけに置く。パッケージの中には持たない）。
extension RecommendationReasonStrings {
    static let testJapanese = RecommendationReasonStrings(
        nextTsundoku: "積読から",
        nextReaders: "積読から・この本を読み終えた人が、次に読んだ本",
        nextNextVolume: "積読から・シリーズの次の巻",
        nextSameAuthor: "積読から・同じ著者",
        nextSameAwardFormat: "積読から・同じ賞（%@）",
        nextSameLabelFormat: "積読から・同じレーベル（%@）",
        recReaders: "この本を読み終えた人が、次に読んだ本",
        recNextVolume: "シリーズの次の巻",
        recSameAuthor: "同じ著者の本",
        recSameAwardFormat: "同じ賞（%@）",
        recSameLabelFormat: "同じレーベル（%@）"
    )

    static let testEnglish = RecommendationReasonStrings(
        nextTsundoku: "From your pile",
        nextReaders: "From your pile · Read next by people who finished this book",
        nextNextVolume: "From your pile · Next volume in the series",
        nextSameAuthor: "From your pile · Same author",
        nextSameAwardFormat: "From your pile · Same award (%@)",
        nextSameLabelFormat: "From your pile · Same imprint (%@)",
        recReaders: "Read next by people who finished this book",
        recNextVolume: "Next volume in the series",
        recSameAuthor: "By the same author",
        recSameAwardFormat: "Same award (%@)",
        recSameLabelFormat: "Same imprint (%@)"
    )
}

struct RecommendationReasonStringsTests {
    struct ReasonCase: Sendable, CustomTestStringConvertible {
        let axis: RecommendationAxis
        let owned: Bool
        let name: String?
        let ja: String
        let en: String
        var testDescription: String { "\(axis.rawValue) owned=\(owned)" }
    }

    @Test("軸と「積読にある本か」の組ごとに1つのキーの文（決定 85）", arguments: [
        ReasonCase(axis: .readers, owned: true, name: nil,
                   ja: "積読から・この本を読み終えた人が、次に読んだ本", en: "From your pile · Read next by people who finished this book"),
        ReasonCase(axis: .nextVolume, owned: true, name: nil, ja: "積読から・シリーズの次の巻", en: "From your pile · Next volume in the series"),
        ReasonCase(axis: .sameAuthor, owned: true, name: nil, ja: "積読から・同じ著者", en: "From your pile · Same author"),
        ReasonCase(axis: .sameAward, owned: true, name: "直木三十五賞", ja: "積読から・同じ賞（直木三十五賞）", en: "From your pile · Same award (直木三十五賞)"),
        ReasonCase(axis: .sameLabel, owned: true, name: "新潮文庫", ja: "積読から・同じレーベル（新潮文庫）", en: "From your pile · Same imprint (新潮文庫)"),
        ReasonCase(axis: .readers, owned: false, name: nil, ja: "この本を読み終えた人が、次に読んだ本", en: "Read next by people who finished this book"),
        ReasonCase(axis: .nextVolume, owned: false, name: nil, ja: "シリーズの次の巻", en: "Next volume in the series"),
        ReasonCase(axis: .sameAuthor, owned: false, name: nil, ja: "同じ著者の本", en: "By the same author"),
        ReasonCase(axis: .sameAward, owned: false, name: "第157回 直木三十五賞", ja: "同じ賞（第157回 直木三十五賞）", en: "Same award (第157回 直木三十五賞)"),
        ReasonCase(axis: .sameLabel, owned: false, name: "文春文庫", ja: "同じレーベル（文春文庫）", en: "Same imprint (文春文庫)")
    ])
    func reasonPerCombination(_ c: ReasonCase) {
        #expect(RecommendationReasonStrings.testJapanese.reason(axis: c.axis, isOwnedTsundoku: c.owned, name: c.name) == c.ja)
        #expect(RecommendationReasonStrings.testEnglish.reason(axis: c.axis, isOwnedTsundoku: c.owned, name: c.name) == c.en)
    }

    @Test("賞やレーベルの名前が空なら、その軸の理由を出さない", arguments: [
        (RecommendationAxis.sameAward, true), (.sameAward, false), (.sameLabel, true), (.sameLabel, false)
    ])
    func emptyNameSkipsAxis(_ axis: RecommendationAxis, _ owned: Bool) {
        for name in [nil, "", "  "] as [String?] {
            #expect(RecommendationReasonStrings.testEnglish.reason(axis: axis, isOwnedTsundoku: owned, name: name) == nil)
        }
        #expect(RecommendationEngine.formatReason(axis: axis, isOwnedTsundoku: owned, award: "", label: "", strings: .testJapanese) == nil)
    }

    @Test("賞の表示名は回や年を前に付け、名前が空なら nil")
    func awardDisplayName() {
        #expect(RecommendationEngine.awardDisplayName(award: "直木三十五賞", sessionOrYear: "第157回") == "第157回 直木三十五賞")
        #expect(RecommendationEngine.awardDisplayName(award: "直木三十五賞", sessionOrYear: nil) == "直木三十五賞")
        #expect(RecommendationEngine.awardDisplayName(award: " ", sessionOrYear: "第157回") == nil)
    }

    @Test("英語の文を渡すと、S-9・S-7・S-1 の候補の理由に日本語の地の文が入らない")
    func candidatesUseGivenStrings() throws {
        let finished = RecommendableBook(
            id: UUID(), isbn13: "9784167911300", title: "コンビニ人間", author: "村田沙耶香",
            label: "文春文庫", award: "芥川龍之介賞", status: .finished
        )
        let sameAuthor = RecommendableBook(
            id: UUID(), isbn13: "9784167911317", title: "消滅世界", author: "村田沙耶香", status: .tsundoku, addedAt: "2026-10-02"
        )
        let unrelated = RecommendableBook(id: UUID(), title: "檸檬", author: "梶井基次郎", status: .tsundoku, addedAt: "2026-10-01")
        let extLabel = RecommendableBook(isbn13: "9784167999999", title: "文春文庫の未所有作", author: "別の作家", label: "文春文庫")

        let s9 = RecommendationEngine.nextCandidates(
            justFinishedBook: finished, shelfBooks: [finished, sameAuthor, unrelated], externalPool: [extLabel], awardsCatalog: [],
            reasonStrings: .testEnglish
        )
        let reasons = Dictionary(uniqueKeysWithValues: s9.map { ($0.title, $0.reason) })
        #expect(reasons["消滅世界"] == "From your pile · Same author")
        #expect(reasons["文春文庫の未所有作"] == "Same imprint (文春文庫)")

        let s1 = RecommendationEngine.noCurrentCandidates(shelfBooks: [unrelated], reasonStrings: .testEnglish)
        #expect(s1.first?.reason == "From your pile")

        let s7 = RecommendationEngine.afterCandidates(
            shelfBooks: [finished, sameAuthor], externalPool: [extLabel], awardsCatalog: [], reasonStrings: .testEnglish
        )
        let s7Reasons = s7.map(\.reason)
        #expect(s7Reasons.contains("Same imprint (文春文庫)"))
        #expect(s7Reasons.allSatisfy { $0.range(of: "\\p{Hiragana}|積読|同じ", options: .regularExpression) == nil })
    }

    @Test("レーベルが空の本どうしは、同じレーベルの軸に当たらない")
    func emptyLabelDoesNotMatch() {
        let base = RecommendableBook(title: "A", author: "著者1", label: "")
        let cand = RecommendableBook(title: "B", author: "著者2", label: "")
        #expect(RecommendationEngine.matchAxis(.sameLabel, candidate: cand, baseBook: base, strings: .testJapanese) == nil)
    }
}
