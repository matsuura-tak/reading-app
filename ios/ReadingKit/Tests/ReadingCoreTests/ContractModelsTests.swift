import Foundation
import Testing
@testable import ReadingCore

@Suite("Contract Models & Entry URL Tests")
struct ContractModelsTests {

    /// contracts/widget-snapshot.schema.json の examples の8つ（写し）。
    static let widgetSnapshotExamples: [String] = [
        #"{"schemaVersion":1,"hideOnWidgets":false,"appearanceID":"default","currentBook":{"title":"羅生門","line":"下人は、雨やみを待っていた。","progress":{"unit":"page","value":61}}}"#,
        #"{"schemaVersion":1,"hideOnWidgets":false,"appearanceID":"default","currentBook":{"title":"檸檬","progress":{"unit":"page","value":120}}}"#,
        #"{"schemaVersion":1,"hideOnWidgets":false,"currentBook":{"title":"檸檬"}}"#,
        #"{"schemaVersion":1,"hideOnWidgets":false,"appearanceID":"kinari","currentBook":{"title":"夜のピクニック","line":"歩行祭は、いつも同じ道を歩く。","progress":{"unit":"location","value":1450}}}"#,
        #"{"schemaVersion":1,"hideOnWidgets":false,"currentBook":{"title":"夜のピクニック","progress":{"unit":"percent","value":52}}}"#,
        #"{"schemaVersion":1,"hideOnWidgets":false,"currentBook":{"isTitlePending":true,"progress":{"unit":"page","value":45}}}"#,
        #"{"schemaVersion":1,"hideOnWidgets":true,"appearanceID":"default","currentBook":{"progress":{"unit":"page","value":61}}}"#,
        #"{"schemaVersion":1,"hideOnWidgets":false,"appearanceID":"default"}"#
    ]

    @Test("WidgetSnapshot decodes the contract examples and round-trips", arguments: ContractModelsTests.widgetSnapshotExamples)
    func widgetSnapshotContractExamples(_ json: String) throws {
        let snapshot = try WidgetSnapshot.decodeAndValidate(from: Data(json.utf8))
        #expect(snapshot.schemaVersion == 1)
        let encoded = try JSONEncoder().encode(snapshot)
        let roundTripped = try WidgetSnapshot.decodeAndValidate(from: encoded)
        #expect(roundTripped == snapshot)
        // 書いた形は契約の項目だけ（知らない項目を足さない、null を書かない）。
        let object = try #require(try JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        #expect(Set(object.keys).isSubset(of: ["schemaVersion", "hideOnWidgets", "appearanceID", "currentBook"]))
        if let book = object["currentBook"] as? [String: Any] {
            #expect(Set(book.keys).isSubset(of: ["title", "isTitlePending", "line", "progress"]))
            #expect(!encoded.contains(Data("null".utf8)))
        }
    }

    @Test("WidgetSnapshot の読む側の決まり（4）〜（7）と、前の版の形")
    func widgetSnapshotReaderRules() throws {
        func reason(_ json: String) -> WidgetUnavailableReason? {
            WidgetSnapshotReader.read(data: Data(json.utf8)).unavailableReason
        }
        #expect(reason(#"{"schemaVersion":2,"hideOnWidgets":false}"#) == .version)
        // 前の版の形（G3 r2 までのアプリが書いた形）は、次に書くまで読めない（version）。落ちない。
        #expect(reason(#"{"version":1,"updatedAt":"2026-10-18T21:00:00+09:00","appearanceID":"default","hideOnWidgets":false,"currentBook":{"id":"550e8400-e29b-41d4-a716-446655440000","title":"羅生門","isTitlePending":false,"progressUnit":"page","progressDisplay":"p.61","latestLine":"下人は"}}"#) == .version)
        #expect(reason(#"{"schemaVersion":1}"#) == .malformed)
        #expect(reason(#"{"schemaVersion":1,"hideOnWidgets":false,"currentBook":{"isTitlePending":false,"title":"羅生門"}}"#) == .malformed)
        #expect(reason(#"{"schemaVersion":1,"hideOnWidgets":false,"currentBook":{"isTitlePending":true,"title":"羅生門"}}"#) == .malformed)
        #expect(reason(#"{"schemaVersion":1,"hideOnWidgets":true,"currentBook":{"title":"羅生門","progress":{"unit":"page","value":61}}}"#) == .hiddenConflict)
        #expect(reason(#"{"schemaVersion":1,"hideOnWidgets":true,"currentBook":{"line":"下人は"}}"#) == .hiddenConflict)
        #expect(reason(#"{"schemaVersion":1,"hideOnWidgets":true,"currentBook":{"isTitlePending":true}}"#) == .hiddenConflict)
        #expect(reason(#"{"schemaVersion":1,"hideOnWidgets":false,"currentBook":{"title":"   "}}"#) == .range)
        #expect(reason("{\"schemaVersion\":1,\"hideOnWidgets\":false,\"currentBook\":{\"title\":\"\(String(repeating: "あ", count: 101))\"}}") == .range)
        #expect(reason("{\"schemaVersion\":1,\"hideOnWidgets\":false,\"currentBook\":{\"title\":\"a\",\"line\":\"\(String(repeating: "あ", count: 61))\"}}") == .range)
        #expect(reason("{\"schemaVersion\":1,\"hideOnWidgets\":false,\"currentBook\":{\"title\":\"a\",\"line\":\"\(String(repeating: "あ", count: 60))\"}}") == nil)
        #expect(reason(#"{"schemaVersion":1,"hideOnWidgets":false,"currentBook":{"title":"a","progress":{"unit":"page","value":0}}}"#) == .range)
        #expect(reason(#"{"schemaVersion":1,"hideOnWidgets":false,"currentBook":{"title":"a","progress":{"unit":"percent","value":101}}}"#) == .range)
        #expect(reason(#"{"schemaVersion":1,"hideOnWidgets":false,"currentBook":{"title":"a","progress":{"unit":"percent","value":0}}}"#) == nil)
        #expect(reason(#"{"schemaVersion":1,"hideOnWidgets":false,"currentBook":{"title":"a","progress":{"unit":"chapter","value":3}}}"#) == .range)
        // 読み流す：知らない項目、知らない見た目の id。
        let lenient = WidgetSnapshotReader.read(data: Data(#"{"schemaVersion":1,"hideOnWidgets":false,"appearanceID":"neon","future":1,"currentBook":{"title":"a","extra":true}}"#.utf8))
        #expect(lenient.snapshot?.appearanceID == .default)
        #expect(lenient.snapshot?.currentBook?.title == "a")
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
