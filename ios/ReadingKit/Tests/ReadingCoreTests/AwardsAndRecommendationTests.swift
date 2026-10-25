import Foundation
import Testing
@testable import ReadingCore

@Suite("AwardsCatalog & RecommendationEngine Tests")
struct AwardsAndRecommendationTests {

    @Test("Bundled awards.json contains all 76 rows in exact order across the 3 awards (AC-112)")
    func bundledAwardsCatalogIntegrity() {
        let all = AwardsCatalog.allBundledAwards()
        #expect(all.count == 76)

        let akutagawa = AwardsCatalog.awards(named: "芥川龍之介賞")
        let naoki = AwardsCatalog.awards(named: "直木三十五賞")
        let hontai = AwardsCatalog.awards(named: "本屋大賞")

        #expect(akutagawa.count == 23)
        #expect(naoki.count == 31)
        #expect(hontai.count == 22)

        #expect(akutagawa.first?.title == "蹴りたい背中")
        #expect(akutagawa.last?.title == "叫び")
        #expect(naoki.first?.title == "容疑者Ｘの献身")
        #expect(naoki.last?.title == "カフェーの帰り道")
        #expect(hontai.first?.title == "博士の愛した数式")
        #expect(hontai.last?.title == "カフネ")

        // Verify 1..N ordering within each award
        for (i, item) in akutagawa.enumerated() {
            #expect(item.order == i + 1)
        }
        for (i, item) in naoki.enumerated() {
            #expect(item.order == i + 1)
        }
        for (i, item) in hontai.enumerated() {
            #expect(item.order == i + 1)
        }
    }

    @Test("Award matching requires both normalized title and normalized author, rejecting volumes and derivatives (AC-18..21)")
    func awardMatchingNormalizationAndRejection() {
        // Exact match
        #expect(AwardsCatalog.matchAwardName(title: "コンビニ人間", author: "村田沙耶香") == "芥川龍之介賞")

        // Bracketed edition label stripped + NDL raw dc:creator author
        #expect(AwardsCatalog.matchAwardName(title: "コンビニ人間（文春文庫）", author: "村田, 沙耶香, 1979-") == "芥川龍之介賞")

        // Full-width / half-width NFKC normalization (容疑者Xの献身 vs 容疑者Ｘの献身)
        #expect(AwardsCatalog.matchAwardName(title: "容疑者Xの献身", author: "東野圭吾") == "直木三十五賞")

        // Punctuation normalization (サラバ! vs サラバ！)
        #expect(AwardsCatalog.matchAwardName(title: "サラバ!", author: "西加奈子") == "直木三十五賞")

        // Multi-award work (蜜蜂と遠雷 won both 直木三十五賞 and 本屋大賞)
        let mitsubachi = AwardsCatalog.matchAwards(title: "蜜蜂と遠雷", author: "恩田陸")
        #expect(mitsubachi.count == 2)

        // Reject different author (AC-18)
        #expect(AwardsCatalog.matchAwardName(title: "コンビニ人間", author: "別の著者") == nil)

        // Reject missing/empty author (AC-19)
        #expect(AwardsCatalog.matchAwardName(title: "コンビニ人間", author: nil) == nil)
        #expect(AwardsCatalog.matchAwardName(title: "コンビニ人間", author: "") == nil)

        // Reject sequels / volumes (AC-20)
        #expect(AwardsCatalog.matchAwardName(title: "コンビニ人間 2", author: "村田沙耶香") == nil)
        #expect(AwardsCatalog.matchAwardName(title: "コンビニ人間 上", author: "村田沙耶香") == nil)
        #expect(AwardsCatalog.matchAwardName(title: "コンビニ人間 下", author: "村田沙耶香") == nil)
        #expect(AwardsCatalog.matchAwardName(title: "コンビニ人間（上）", author: "村田沙耶香") == nil)
        #expect(AwardsCatalog.matchAwardName(title: "コンビニ人間（下）", author: "村田沙耶香") == nil)

        // Reject derivative works (AC-21)
        #expect(AwardsCatalog.matchAwardName(title: "コンビニ人間 創作ノート", author: "村田沙耶香") == nil)
        #expect(AwardsCatalog.matchAwardName(title: "『コンビニ人間』を歩く", author: "村田沙耶香") == nil)
    }

    @Test("RecommendationEngine scores weights, filters cooccurrence, and generates S-9 / S-7 / S-1 candidates (AC-75..87, AC-145..148)")
    func recommendationEngineRules() {
        // 1. Weight score sorting (chosen*2 - skipped) and tie-breaking (AC-147)
        let weights: [H02SeedRecommendationWeight] = [
            H02SeedRecommendationWeight(axis: .readers, chosenCount: 0, skippedCount: 2),    // -2
            H02SeedRecommendationWeight(axis: .sameAward, chosenCount: 3, skippedCount: 1),  // +5
            H02SeedRecommendationWeight(axis: .sameLabel, chosenCount: 2, skippedCount: 0)   // +4
        ]
        let ordered = RecommendationEngine.orderedAxes(from: weights)
        #expect(ordered == [.sameAward, .sameLabel, .nextVolume, .sameAuthor, .readers])

        // 2. Cooccurrence filter: count >= 10 AND ndc starts with "9", reason has no headcount (AC-148)
        let coocRaw: [H24CooccurrenceCandidate] = [
            H24CooccurrenceCandidate(isbn13: "9784167900001", title: "件数不足の本", author: "著者A", ndc: "913.6", count: 9),
            H24CooccurrenceCandidate(isbn13: "9784167900002", title: "非文学の本", author: "著者B", ndc: "336.1", count: 25),
            H24CooccurrenceCandidate(isbn13: "9784167900003", title: "合格する文学の本", author: "著者C", ndc: "913.6", count: 18)
        ]
        let filteredCooc = RecommendationEngine.filterCooccurrenceCandidates(coocRaw)
        #expect(filteredCooc.count == 1)
        #expect(filteredCooc.first?.title == "合格する文学の本")

        let reason = RecommendationEngine.formatReason(axis: .readers, baseBookTitle: "コンビニ人間")
        #expect(reason == "この本を読み終えた人が、次に読んだ本")
        #expect(!reason.contains("18"))

        // 3. Next volume matching (volumeNumber + 1 only, AC-87)
        let vol1 = RecommendableBook(title: "坂の上の雲 1", author: "司馬遼太郎", seriesTitle: "坂の上の雲", volumeNumber: 1)
        let vol2 = RecommendableBook(title: "坂の上の雲 2", author: "司馬遼太郎", seriesTitle: "坂の上の雲", volumeNumber: 2)
        let vol3 = RecommendableBook(title: "坂の上の雲 3", author: "司馬遼太郎", seriesTitle: "坂の上の雲", volumeNumber: 3)
        #expect(RecommendationEngine.isNextVolume(candidate: vol2, of: vol1) == true)
        #expect(RecommendationEngine.isNextVolume(candidate: vol3, of: vol1) == false)

        // 4. S-9 nextCandidates: prioritizes owned tsundoku books first, up to 3 total
        let finished = RecommendableBook(
            id: UUID(),
            isbn13: "9784167911300",
            title: "コンビニ人間",
            author: "村田沙耶香",
            label: "文春文庫",
            award: "芥川龍之介賞",
            status: .finished
        )
        let ownedTsundoku = RecommendableBook(
            id: UUID(),
            isbn13: "9784167911317",
            title: "消滅世界",
            author: "村田沙耶香",
            label: "文春文庫",
            status: .tsundoku
        )
        let s9 = RecommendationEngine.nextCandidates(
            justFinishedBook: finished,
            shelfBooks: [finished, ownedTsundoku],
            cooccurrence: coocRaw
        )
        #expect(s9.count == 3)
        #expect(s9.first?.title == "消滅世界")
        #expect(s9.first?.isOwnedTsundoku == true)

        // 5. S-7 afterCandidates: unowned only, round-robin across multiple axes up to 5 (AC-146)
        let extLabelBook = RecommendableBook(
            isbn13: "9784167999999",
            title: "文春文庫の未所有作",
            author: "別の作家",
            label: "文春文庫"
        )
        let s7 = RecommendationEngine.afterCandidates(
            shelfBooks: [finished, ownedTsundoku],
            externalPool: [extLabelBook],
            cooccurrence: coocRaw
        )
        #expect(s7.count <= 5)
        #expect(s7.allSatisfy { !$0.isOwnedTsundoku })
        #expect(!s7.contains { $0.title == "コンビニ人間" || $0.title == "消滅世界" })
        let distinctAxes = Set(s7.map(\.axis))
        #expect(distinctAxes.count >= 2)

        // 6. S-1 noCurrentCandidates: selects up to 3 from tsundoku (AC-145)
        let s1 = RecommendationEngine.noCurrentCandidates(shelfBooks: [finished, ownedTsundoku])
        #expect(s1.count == 1)
        #expect(s1.first?.title == "消滅世界")
        #expect(s1.first?.isOwnedTsundoku == true)
    }
}
