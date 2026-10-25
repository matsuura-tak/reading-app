import Foundation
import Testing
@testable import ReadingCore

@Suite("AuthorNameFormatter & ISBNAndCCodeParser Tests")
struct AuthorAndISBNTests {

    @Test("AuthorNameFormatter cleans NDL dc:creator patterns accurately (AC-92)")
    func authorNameFormatting() {
        #expect(AuthorNameFormatter.format("村田, 沙耶香, 1979-") == "村田沙耶香")
        #expect(AuthorNameFormatter.format("村上 春樹 (小説家) 著") == "村上春樹")
        #expect(AuthorNameFormatter.format("東野 圭吾 著 ; 解説 太郎 解説") == "東野圭吾")
        #expect(AuthorNameFormatter.format("恩田, 陸, 1964- (小説家) ; ピアニスト, 太郎 (ピアニスト) 編") == "恩田陸")
        #expect(AuthorNameFormatter.format("夏目, 漱石, 1867-1916") == "夏目漱石")
        #expect(AuthorNameFormatter.format("村上, 春樹 (1949-)") == "村上春樹")
        #expect(AuthorNameFormatter.format("小川洋子 [著]") == "小川洋子")
        #expect(AuthorNameFormatter.format("リリー・フランキー 著") == "リリー・フランキー")
        #expect(AuthorNameFormatter.format(nil) == "")
        #expect(AuthorNameFormatter.format("   ") == "")
    }

    @Test("ISBNAndCCodeParser validates ISBN-13, rejects non-book barcodes, and derives publisher & label (AC-3, AC-5, AC-11)")
    func isbnAndCCodeParsing() throws {
        // Valid ISBN-13
        let valid = ISBNAndCCodeParser.validateISBN13("978-4-16-791130-0")
        #expect(valid == .success("9784167911300"))

        // Invalid check digit
        let badCheck = ISBNAndCCodeParser.validateISBN13("9784167911309")
        #expect(badCheck == .failure(.invalidCheckDigit))

        // Non-book barcode (JAN 490...)
        let nonBook = ISBNAndCCodeParser.validateISBN13("4901234567894")
        #expect(nonBook == .failure(.nonBookBarcode("4901234567894")))

        // 2nd-tier 192 barcode passed as primary ISBN should be rejected as nonBookBarcode
        let cCodeAsPrimary = ISBNAndCCodeParser.validateISBN13("1920193006001")
        #expect(cCodeAsPrimary == .failure(.nonBookBarcode("1920193006001")))

        // Parse 2nd-tier 192 barcode (5th digit '1' = 文庫, '2' = 新書, '0' = 単行本)
        let bunkoCCode = try #require(ISBNAndCCodeParser.parseCCode("1920193006001"))
        #expect(bunkoCCode.formatDigit == "1")
        #expect(bunkoCCode.formatLabel == "文庫")
        #expect(bunkoCCode.contentCode == "93")

        let shinshoCCode = try #require(ISBNAndCCodeParser.parseCCode("1920295008005"))
        #expect(shinshoCCode.formatDigit == "2")
        #expect(shinshoCCode.formatLabel == "新書")

        let tankobonCCode = try #require(ISBNAndCCodeParser.parseCCode("1920093016002"))
        #expect(tankobonCCode.formatDigit == "0")
        #expect(tankobonCCode.formatLabel == "単行本")

        // Combine ISBN-13 + 192 C-code for Iwanami (9784003101018 + 1920193006001 -> 岩波書店, 文庫 / 岩波文庫)
        let iwanamiMeta = try ISBNAndCCodeParser.resolveMetadata(
            isbn13: "9784003101018",
            supplementalCode: "1920193006001"
        ).get()
        #expect(iwanamiMeta.publisher == "岩波書店")
        #expect(iwanamiMeta.formatLabel == "文庫")
        #expect(iwanamiMeta.imprintLabel == "岩波文庫")

        // Combine ISBN-13 + 192 C-code for Shinchosha (9784101000022 + 1920193006001 -> 新潮社, 文庫 / 新潮文庫)
        let shinchoMeta = try ISBNAndCCodeParser.resolveMetadata(
            isbn13: "9784101000022",
            supplementalCode: "1920193006001"
        ).get()
        #expect(shinchoMeta.publisher == "新潮社")
        #expect(shinchoMeta.formatLabel == "文庫")
        #expect(shinchoMeta.imprintLabel == "新潮文庫")
    }
}
