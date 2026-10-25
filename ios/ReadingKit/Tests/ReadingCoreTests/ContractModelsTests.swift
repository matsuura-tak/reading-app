import Foundation
import Testing
@testable import ReadingCore

@Suite("Contract Models & Entry URL Tests")
struct ContractModelsTests {

    @Test("WidgetSnapshot decodes all 4 contract examples and round-trips")
    func widgetSnapshotContractExamples() throws {
        let example1 = """
        {
          "version": 1,
          "updatedAt": "2026-10-24T22:15:00Z",
          "appearanceID": "default",
          "hideOnWidgets": false,
          "currentBook": {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "title": "コンビニ人間",
            "author": "村田沙耶香",
            "isTitlePending": false,
            "progressUnit": "page",
            "progressDisplay": "p. 142",
            "latestLine": "世界の部品になることで、わたしはようやく息ができた",
            "latestLineId": "660e8400-e29b-41d4-a716-446655440001"
          }
        }
        """
        let snap1 = try WidgetSnapshot.decodeAndValidate(from: Data(example1.utf8))
        #expect(snap1.version == 1)
        #expect(snap1.appearanceID == .default)
        #expect(snap1.hideOnWidgets == false)
        let book1 = try #require(snap1.currentBook)
        #expect(book1.title == "コンビニ人間")
        #expect(book1.author == "村田沙耶香")
        #expect(book1.progressUnit == .page)
        #expect(book1.progressDisplay == "p. 142")
        #expect(book1.latestLine?.count == 25)

        let example2 = """
        {
          "version": 1,
          "updatedAt": "2026-10-24T22:16:00Z",
          "appearanceID": "dark",
          "hideOnWidgets": true,
          "currentBook": {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "title": "コンビニ人間",
            "author": "村田沙耶香",
            "isTitlePending": false,
            "progressUnit": "page",
            "progressDisplay": "p. 142",
            "latestLine": null,
            "latestLineId": null
          }
        }
        """
        let snap2 = try WidgetSnapshot.decodeAndValidate(from: Data(example2.utf8))
        #expect(snap2.appearanceID == .dark)
        #expect(snap2.hideOnWidgets == true)
        #expect(snap2.currentBook?.latestLine == nil)
        #expect(snap2.currentBook?.latestLineId == nil)

        let example3 = """
        {
          "version": 1,
          "updatedAt": "2026-10-24T22:17:00Z",
          "appearanceID": "light",
          "hideOnWidgets": false,
          "currentBook": {
            "id": "770e8400-e29b-41d4-a716-446655440002",
            "title": null,
            "author": null,
            "isTitlePending": true,
            "progressUnit": "page",
            "progressDisplay": null,
            "latestLine": null,
            "latestLineId": null
          }
        }
        """
        let snap3 = try WidgetSnapshot.decodeAndValidate(from: Data(example3.utf8))
        #expect(snap3.appearanceID == .light)
        #expect(snap3.currentBook?.isTitlePending == true)
        #expect(snap3.currentBook?.title == nil)

        let example4 = """
        {
          "version": 1,
          "updatedAt": "2026-10-24T22:18:00Z",
          "appearanceID": "default",
          "hideOnWidgets": false,
          "currentBook": null
        }
        """
        let snap4 = try WidgetSnapshot.decodeAndValidate(from: Data(example4.utf8))
        #expect(snap4.currentBook == nil)

        // Round-trip encode & decode
        let encoded = try JSONEncoder().encode(snap1)
        let roundTripped = try WidgetSnapshot.decodeAndValidate(from: encoded)
        #expect(roundTripped == snap1)
    }

    @Test("WidgetSnapshot validation catches version!=1, privacy violation, titlePending violation, and unknown appearance fallback")
    func widgetSnapshotValidationErrorsAndFallback() throws {
        let wrongVersion = """
        {
          "version": 2,
          "updatedAt": "2026-10-24T22:18:00Z",
          "appearanceID": "default",
          "hideOnWidgets": false,
          "currentBook": null
        }
        """
        #expect(throws: WidgetSnapshotValidationError.unsupportedVersion(2)) {
            _ = try WidgetSnapshot.decodeAndValidate(from: Data(wrongVersion.utf8))
        }
        // Widget renderer safe fallback returns empty currentBook without crashing
        let fallback = WidgetSnapshot.decodeForWidgetRenderer(from: Data(wrongVersion.utf8))
        #expect(fallback.currentBook == nil)
        #expect(fallback.version == 1)

        // Unknown appearanceID falls back to .default
        let unknownAppearance = """
        {
          "version": 1,
          "updatedAt": "2026-10-24T22:18:00Z",
          "appearanceID": "sepia-future-theme",
          "hideOnWidgets": false,
          "currentBook": null
        }
        """
        let decodedAppearance = try WidgetSnapshot.decodeAndValidate(from: Data(unknownAppearance.utf8))
        #expect(decodedAppearance.appearanceID == .default)

        // Privacy violation: hideOnWidgets == true with non-nil latestLine
        let privacyViolation = """
        {
          "version": 1,
          "updatedAt": "2026-10-24T22:16:00Z",
          "appearanceID": "dark",
          "hideOnWidgets": true,
          "currentBook": {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "title": "コンビニ人間",
            "author": "村田沙耶香",
            "isTitlePending": false,
            "progressUnit": "page",
            "progressDisplay": "p. 142",
            "latestLine": "漏れてはいけない1行",
            "latestLineId": null
          }
        }
        """
        #expect(throws: WidgetSnapshotValidationError.privacyInvariantViolation) {
            _ = try WidgetSnapshot.decodeAndValidate(from: Data(privacyViolation.utf8))
        }

        // Title pending violation: isTitlePending == true with non-nil title
        let pendingViolation = """
        {
          "version": 1,
          "updatedAt": "2026-10-24T22:17:00Z",
          "appearanceID": "light",
          "hideOnWidgets": false,
          "currentBook": {
            "id": "770e8400-e29b-41d4-a716-446655440002",
            "title": "題名あり",
            "author": null,
            "isTitlePending": true,
            "progressUnit": "page",
            "progressDisplay": null,
            "latestLine": null,
            "latestLineId": null
          }
        }
        """
        #expect(throws: WidgetSnapshotValidationError.titlePendingInvariantViolation) {
            _ = try WidgetSnapshot.decodeAndValidate(from: Data(pendingViolation.utf8))
        }
    }

    @Test("All 7 hook schemas decode their contract examples cleanly")
    func hookSchemaExamplesDecode() throws {
        let h02JSON = """
        {
          "books": [
            {
              "id": "550e8400-e29b-41d4-a716-446655440000",
              "isbn13": "9784167911300",
              "ndc": "913.6",
              "title": "コンビニ人間",
              "author": "村田沙耶香",
              "publisher": "文藝春秋",
              "label": "文春文庫",
              "publishedYear": 2018,
              "award": "芥川龍之介賞",
              "seriesTitle": null,
              "volumeNumber": null,
              "status": "reading",
              "progressUnit": "page",
              "currentPage": 142,
              "entrySource": "barcode",
              "isTitlePending": false,
              "addedAt": "2026-10-20T12:00:00Z",
              "startedReadingAt": "2026-10-20T12:05:00Z",
              "finishedAt": null,
              "updatedAt": "2026-10-24T13:15:00Z"
            }
          ],
          "settings": {
            "appearanceID": "default",
            "hideLineOnWidgets": false,
            "hasSeenOnboarding": true,
            "hasShownWidgetGuideBanner": false,
            "defaultProgressUnit": "page"
          }
        }
        """
        let h02 = try JSONDecoder().decode(H02SeedPayload.self, from: Data(h02JSON.utf8))
        #expect(h02.books?.count == 1)
        #expect(h02.books?.first?.title == "コンビニ人間")

        let h13JSON = """
        {
          "books": [],
          "readingRecords": [],
          "bookMarks": [],
          "lineMarks": [],
          "recommendationWeights": [
            { "axis": "readers", "chosenCount": 2, "skippedCount": 1, "score": 3 }
          ],
          "cooccurrenceCache": [],
          "settings": {
            "appearanceID": "default",
            "hideLineOnWidgets": false,
            "hasSeenOnboarding": false,
            "hasShownWidgetGuideBanner": false,
            "defaultProgressUnit": "page"
          },
          "outboundNetworkCount": 0
        }
        """
        let h13 = try JSONDecoder().decode(H13StoreReadout.self, from: Data(h13JSON.utf8))
        #expect(h13.recommendationWeights.first?.score == 3)

        let h17JSON = """
        {
          "state": "active",
          "startedAt": "2026-10-24T13:00:00Z",
          "elapsedSeconds": 900,
          "bookId": "550e8400-e29b-41d4-a716-446655440000",
          "startedBy": "widget",
          "liveActivityActive": true,
          "pendingPromptSessionId": null
        }
        """
        let h17 = try JSONDecoder().decode(H17StateReadout.self, from: Data(h17JSON.utf8))
        #expect(h17.state == .active)
        #expect(h17.startedBy == .widget)
        #expect(h17.compactSummary == "state=active,elapsed=900,liveActivity=true")

        let h20JSON = """
        {
          "defaultMode": "empty",
          "defaultDelayMs": 0,
          "isbnResponses": {
            "9784167911300": {
              "mode": "fixture",
              "items": [
                {
                  "isbn13": "9784167911300",
                  "title": "コンビニ人間",
                  "author": "村田沙耶香",
                  "rawDcCreator": "村田, 沙耶香, 1979-",
                  "publisher": "文藝春秋",
                  "label": "文春文庫",
                  "publishedYear": 2018,
                  "ndc": "913.6"
                }
              ]
            }
          }
        }
        """
        let h20 = try JSONDecoder().decode(H20NDLStubConfig.self, from: Data(h20JSON.utf8))
        #expect(h20.isbnResponses["9784167911300"]?.items.first?.title == "コンビニ人間")

        let h22JSON = """
        {
          "snapshot": {
            "version": 1,
            "updatedAt": "2026-10-24T13:15:00Z",
            "appearanceID": "default",
            "hideOnWidgets": false,
            "currentBook": {
              "id": "550e8400-e29b-41d4-a716-446655440000",
              "title": "コンビニ人間",
              "author": "村田沙耶香",
              "isTitlePending": false,
              "progressUnit": "page",
              "progressDisplay": "p. 142",
              "latestLine": "世界の部品になることで、わたしはようやく息ができた",
              "latestLineId": "770e8400-e29b-41d4-a716-446655440020"
            }
          },
          "composition": {
            "orientation": "vertical",
            "displayedLine": "世界の部品になることで、わたしはようやく息ができた",
            "shortened": false,
            "columnCount": 4,
            "rowsPerColumn": 8,
            "accessibilityLabel": "コンビニ人間、村田沙耶香。p. 142。世界の部品になることで、わたしはようやく息ができた。",
            "cells": [
              { "column": 1, "row": 1, "source": "世", "display": "世", "rotation": 0, "dx": 0, "dy": 0 },
              { "column": 1, "row": 8, "source": "、", "display": "︑", "rotation": 0, "dx": 0, "dy": 0 }
            ]
          },
          "reloadTimelineCount": 2,
          "lastReloadAt": "2026-10-24T13:15:00Z"
        }
        """
        let h22 = try JSONDecoder().decode(H22WidgetReadout.self, from: Data(h22JSON.utf8))
        #expect(h22.composition.orientation == .vertical)
        #expect(h22.composition.cells.count == 2)
        #expect(h22.reloadTimelineCount == 2)

        let h29JSON = """
        {
          "totalCount": 1,
          "requests": [
            {
              "url": "https://ndlsearch.ndl.go.jp/api/opensearch?isbn=9784167911300",
              "host": "ndlsearch.ndl.go.jp",
              "method": "GET",
              "purpose": "ndlIsbn",
              "timestamp": "2026-10-24T13:00:01Z",
              "hasTrackingIdentifiers": false
            }
          ]
        }
        """
        let h29 = try JSONDecoder().decode(H29OutboundReadout.self, from: Data(h29JSON.utf8))
        #expect(h29.totalCount == 1)
        #expect(h29.requests.first?.purpose == .ndlIsbn)

        let hookConfigJSON = """
        {
          "schemaVersion": 1,
          "nowISO8601": "2026-10-25T03:59:59+09:00",
          "entryURL": "yomuma://reading/start?source=widget",
          "permissionStates": {
            "camera": "authorized",
            "liveActivitiesEnabled": true,
            "networkOnline": true
          }
        }
        """
        let hookConfig = try JSONDecoder().decode(HookConfigEnvelope.self, from: Data(hookConfigJSON.utf8))
        #expect(hookConfig.schemaVersion == 1)
        #expect(hookConfig.permissionStates?.camera == .authorized)
    }

    @Test("EntryURLParser parses all 4 valid schemes and rejects malformed URLs")
    func entryURLParsing() throws {
        #expect(EntryURLParser.parse("yomuma://reading/start?source=widget") == .startReading(source: .widget))
        #expect(EntryURLParser.parse("yomuma://reading/start?source=control") == .startReading(source: .control))
        #expect(EntryURLParser.parse("yomuma://reading/mark") == .openMarkSheet)
        #expect(EntryURLParser.parse("yomuma://reading/end") == .endReading)

        let uuid = try #require(UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000"))
        #expect(EntryURLParser.parse("yomuma://book/550e8400-e29b-41d4-a716-446655440000") == .openBook(bookID: uuid))

        // Invalid / ignored URLs
        #expect(EntryURLParser.parse("https://reading/start?source=widget") == nil)
        #expect(EntryURLParser.parse("yomuma://reading/start") == nil)
        #expect(EntryURLParser.parse("yomuma://reading/start?source=unknown") == nil)
        #expect(EntryURLParser.parse("yomuma://book/not-a-uuid") == nil)
        #expect(EntryURLParser.parse("yomuma://unknown/path") == nil)
    }
}
