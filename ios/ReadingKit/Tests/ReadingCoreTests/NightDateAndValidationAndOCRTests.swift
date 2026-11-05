import Foundation
import Testing
@testable import ReadingCore

@Suite("NightDateCalculator, InputValidator & OCRPipeline Tests")
struct NightDateAndValidationAndOCRTests {

    @Test("NightDateCalculator uses 4:00 AM boundary in the record's timeZoneID (AC-22)")
    func nightDateFourAMBoundary() {
        // 03:59:59 JST on 2026-10-16 -> 2026-10-15
        let before4AM = NightDateCalculator.nightDate(
            startedAtISO8601: "2026-10-16T03:59:59+09:00",
            timeZoneID: "Asia/Tokyo"
        )
        #expect(before4AM == "2026-10-15")

        // 04:00:00 JST on 2026-10-16 -> 2026-10-16
        let at4AM = NightDateCalculator.nightDate(
            startedAtISO8601: "2026-10-16T04:00:00+09:00",
            timeZoneID: "Asia/Tokyo"
        )
        #expect(at4AM == "2026-10-16")

        // Preserves recorded timeZoneID (e.g. America/New_York)
        // 2026-10-16T03:30:00-04:00 in America/New_York -> 2026-10-15
        let nyBefore4AM = NightDateCalculator.nightDate(
            startedAtISO8601: "2026-10-16T03:30:00-04:00",
            timeZoneID: "America/New_York"
        )
        #expect(nyBefore4AM == "2026-10-15")
    }

    @Test("Finish reflection text handles 0, 1, and multi-night records with newer-date tie-breaker (AC-85, AC-127..129)")
    func finishReflectionFormatting() throws {
        // 0 records -> nil (AC-129)
        #expect(NightDateCalculator.buildFinishReflection(from: []) == nil)

        // 1 night (even with 2 sessions on the same night -> 1 unique night, AC-85 & AC-128)
        let singleNightRecords = [
            NightRecordInput(startedAt: "2026-10-15T22:00:00+09:00", durationSeconds: 900, timeZoneID: "Asia/Tokyo"),
            NightRecordInput(startedAt: "2026-10-16T01:30:00+09:00", durationSeconds: 900, timeZoneID: "Asia/Tokyo")
        ]
        let singleSummary = try #require(NightDateCalculator.buildFinishReflection(from: singleNightRecords))
        #expect(singleSummary.uniqueNights == 1)
        #expect(singleSummary.totalMinutes == 30)
        #expect(singleSummary.japaneseText == "1晩、30分で読み終えました。")
        #expect(!singleSummary.japaneseText.contains("いちばん長かったのは"))

        // 6 nights (AC-127)
        let multiRecords = [
            NightRecordInput(startedAt: "2026-10-10T22:00:00+09:00", durationSeconds: 1200, precomputedNightDate: "2026-10-10"),
            NightRecordInput(startedAt: "2026-10-11T22:00:00+09:00", durationSeconds: 1500, precomputedNightDate: "2026-10-11"),
            NightRecordInput(startedAt: "2026-10-12T22:00:00+09:00", durationSeconds: 1800, precomputedNightDate: "2026-10-12"),
            NightRecordInput(startedAt: "2026-10-13T22:00:00+09:00", durationSeconds: 900, precomputedNightDate: "2026-10-13"),
            NightRecordInput(startedAt: "2026-10-15T22:00:00+09:00", durationSeconds: 2280, precomputedNightDate: "2026-10-15"),
            NightRecordInput(startedAt: "2026-10-16T22:00:00+09:00", durationSeconds: 840, precomputedNightDate: "2026-10-16")
        ]
        let multiSummary = try #require(NightDateCalculator.buildFinishReflection(from: multiRecords))
        #expect(multiSummary.uniqueNights == 6)
        #expect(multiSummary.totalMinutes == 142)
        #expect(multiSummary.japaneseText.contains("6晩"))
        #expect(multiSummary.japaneseText.contains("142分（2時間22分）"))
        #expect(multiSummary.japaneseText.contains("10月15日"))
        #expect(multiSummary.japaneseText.contains("38分"))

        // Tie on longest night -> picks newer nightDate (AC-128)
        let tieRecords = [
            NightRecordInput(startedAt: "2026-10-13T22:00:00+09:00", durationSeconds: 1800, precomputedNightDate: "2026-10-13"),
            NightRecordInput(startedAt: "2026-10-14T22:00:00+09:00", durationSeconds: 600, precomputedNightDate: "2026-10-14"),
            NightRecordInput(startedAt: "2026-10-15T22:00:00+09:00", durationSeconds: 1800, precomputedNightDate: "2026-10-15")
        ]
        let tieSummary = try #require(NightDateCalculator.buildFinishReflection(from: tieRecords))
        #expect(tieSummary.longestNight.nightDate == "2026-10-15")
        #expect(tieSummary.japaneseText.contains("3晩"))
        #expect(tieSummary.japaneseText.contains("70分（1時間10分）"))
        #expect(tieSummary.japaneseText.contains("10月15日"))
    }

    @Test("InputValidator enforces all character and integer boundaries, full-width digit conversion, and decimal rejection")
    func inputValidationBoundaries() {
        // Title: 1..100
        #expect(InputValidator.validateTitle("   ") == .failure(.empty))
        #expect(InputValidator.validateTitle("あ") == .success("あ"))
        let title100 = String(repeating: "あ", count: 100)
        #expect(InputValidator.validateTitle(title100) == .success(title100))
        let title101 = String(repeating: "あ", count: 101)
        #expect(InputValidator.validateTitle(title101) == .failure(.tooLong(max: 100, actual: 101)))

        // Author: 0..100
        #expect(InputValidator.validateAuthor("") == .success(""))
        #expect(InputValidator.validateAuthor(title100) == .success(title100))
        #expect(InputValidator.validateAuthor(title101) == .failure(.tooLong(max: 100, actual: 101)))

        // Line: 1..60
        #expect(InputValidator.validateLine("") == .failure(.empty))
        let line60 = String(repeating: "あ", count: 60)
        #expect(InputValidator.validateLine(line60) == .success(line60))
        let line61 = String(repeating: "あ", count: 61)
        #expect(InputValidator.validateLine(line61) == .failure(.tooLong(max: 60, actual: 61)))

        // Page: 1..9999 with full-width digits and decimal rejection
        #expect(InputValidator.validatePage("0") == .failure(.outOfRange(min: 1, max: 9999, actual: 0)))
        #expect(InputValidator.validatePage("1") == .success(1))
        #expect(InputValidator.validatePage("９９９９") == .success(9999))
        #expect(InputValidator.validatePage("10000") == .failure(.outOfRange(min: 1, max: 9999, actual: 10000)))
        #expect(InputValidator.validatePage("12.5") == .failure(.containsDecimal))

        // Location: 1..999999
        #expect(InputValidator.validateLocation("0") == .failure(.outOfRange(min: 1, max: 999999, actual: 0)))
        #expect(InputValidator.validateLocation("1") == .success(1))
        #expect(InputValidator.validateLocation("999999") == .success(999999))
        #expect(InputValidator.validateLocation("1000000") == .failure(.outOfRange(min: 1, max: 999999, actual: 1000000)))

        // Percent: 0..100
        #expect(InputValidator.validatePercent("-1") == .failure(.outOfRange(min: 0, max: 100, actual: -1)))
        #expect(InputValidator.validatePercent("0") == .success(0))
        #expect(InputValidator.validatePercent("100") == .success(100))
        #expect(InputValidator.validatePercent("101") == .failure(.outOfRange(min: 0, max: 100, actual: 101)))

        // Minutes: 1..1440
        #expect(InputValidator.validateMinutes("0") == .failure(.outOfRange(min: 1, max: 1440, actual: 0)))
        #expect(InputValidator.validateMinutes("1") == .success(1))
        #expect(InputValidator.validateMinutes("1440") == .success(1440))
        #expect(InputValidator.validateMinutes("1441") == .failure(.outOfRange(min: 1, max: 1440, actual: 1441)))
    }

    @Test("OCRPipeline processes vertical page columns, colophon, cover 2-tap, and bookshelf spines (AC-65..68, AC-113, AC-137, AC-138)")
    func ocrPipelineModes() {
        // 1. Vertical page OCR (AC-65..67)
        let rawCols = [
            H23OCRColumn(text: "左端の三番目の列の文章です。", normalizedX: 0.25, normalizedY: 0.5, isPageNumber: false),
            H23OCRColumn(text: "右端の最初の列の文章です。", normalizedX: 0.85, normalizedY: 0.5, isPageNumber: false),
            H23OCRColumn(text: "真ん中の二番目の列の文章です。", normalizedX: 0.55, normalizedY: 0.5, isPageNumber: false),
            H23OCRColumn(text: "188", normalizedX: 0.12, normalizedY: 0.92, isPageNumber: true)
        ]
        let pageResult = OCRPipeline.processPageOCR(rawColumns: rawCols)
        #expect(pageResult.columns.count == 3)
        #expect(pageResult.columns[0].index == 1)
        #expect(pageResult.columns[0].text == "右端の最初の列の文章です。")
        #expect(pageResult.columns[1].index == 2)
        #expect(pageResult.columns[1].text == "真ん中の二番目の列の文章です。")
        #expect(pageResult.columns[2].index == 3)
        #expect(pageResult.columns[2].text == "左端の三番目の列の文章です。")
        #expect(pageResult.initialSelectedIndices == [3])
        #expect(pageResult.initialLineText == "左端の三番目の列の文章です。")
        #expect(pageResult.detectedPageNumber == 188)

        // Combining multiple columns clamps to 60 characters (AC-66)
        let combined = OCRPipeline.combineSelectedColumns(columns: pageResult.columns, selectedIndices: [1, 2, 3])
        #expect(combined.count <= 60)
        #expect(combined.hasPrefix("右端の最初の列の文章です。真ん中の二番目の列の文章です。"))

        // 2. Colophon extraction (AC-113)
        let colophonStub = H23OCRColophon(rawLines: [
            "古都",
            "著者 川端康成",
            "発行所 株式会社新潮社",
            "レーベル 新潮文庫",
            "1968年5月15日 発行",
            "ISBN978-4-10-100120-3"
        ])
        let colophon = OCRPipeline.parseColophon(colophonStub)
        #expect(colophon.title == "古都")
        #expect(colophon.author == "川端康成")
        #expect(colophon.publisher == "新潮社")
        #expect(colophon.label == "新潮文庫")
        #expect(colophon.publishedYear == 1968)
        #expect(colophon.isbn13 == "9784101001203")

        // 3. Cover 2-tap selection (AC-137)
        let cover = OCRPipeline.resolveCoverSelection(
            coverLines: ["新潮文庫", "雪国", "川端 康成 著"],
            titleLineIndex: 1,
            authorLineIndex: 2
        )
        #expect(cover?.title == "雪国")
        #expect(cover?.author == "川端康成")

        // 4. Bookshelf spines auto-completion only on unique catalog match (AC-138)
        let spines = [
            H23OCRSpineItem(id: "s1", title: "コンビニ人間", normalizedX: 0.2),
            H23OCRSpineItem(id: "s2", title: "同名異作の本", normalizedX: 0.5),
            H23OCRSpineItem(id: "s3", title: "カタログ未掲載の本", normalizedX: 0.8)
        ]
        let catalog = [
            H20BiblioItem(isbn13: "9784167911300", title: "コンビニ人間", author: "村田沙耶香", publisher: "文藝春秋", label: "文春文庫", publishedYear: 2018, ndc: "913.6"),
            H20BiblioItem(isbn13: "9784000000010", title: "同名異作の本", author: "著者甲", publisher: "甲社"),
            H20BiblioItem(isbn13: "9784000000027", title: "同名異作の本", author: "著者乙", publisher: "乙社")
        ]
        let resolvedSpines = OCRPipeline.processBookshelfSpines(spines: spines, catalog: catalog)
        #expect(resolvedSpines.count == 3)
        // Unique match -> auto-completed
        #expect(resolvedSpines[0].author == "村田沙耶香")
        #expect(resolvedSpines[0].publisher == "文藝春秋")
        #expect(resolvedSpines[0].catalogMatchCount == 1)
        // 2 matches -> NOT guessed
        #expect(resolvedSpines[1].author == nil)
        #expect(resolvedSpines[1].publisher == nil)
        #expect(resolvedSpines[1].catalogMatchCount == 2)
        // 0 matches -> NOT guessed
        #expect(resolvedSpines[2].author == nil)
        #expect(resolvedSpines[2].catalogMatchCount == 0)
    }
}
