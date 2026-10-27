import XCTest

final class FinishAndRecommendationAcceptanceTests: AcceptanceTestBase {

    private var finishSeed: String {
        makeSeedJSON(
            books: [
                makeSeedBook(
                    id: uuidBookA,
                    isbn13: "9784167911300",
                    title: "蜜蜂と遠雷",
                    author: "恩田陸",
                    publisher: "文藝春秋",
                    label: "文春文庫",
                    publishedYear: 2019,
                    status: "current",
                    page: 120,
                    lastLine: "風が吹いていた。"
                ),
                makeSeedBook(
                    id: uuidBookP,
                    title: "夜のピクニック",
                    author: "恩田陸",
                    status: "tsundoku",
                    tsundokuAt: "2026-10-14T21:00:00+09:00"
                ),
                makeSeedBook(
                    id: uuidBookQ,
                    title: "宝島",
                    author: "真藤順丈",
                    status: "tsundoku",
                    tsundokuAt: "2026-10-13T21:00:00+09:00"
                ),
                makeSeedBook(
                    id: uuidBookR,
                    title: "銀河鉄道の夜",
                    author: "宮沢賢治",
                    status: "tsundoku",
                    tsundokuAt: "2026-10-12T21:00:00+09:00"
                ),
                makeSeedBook(
                    id: uuidBookS,
                    title: "走れメロス",
                    author: "太宰治",
                    status: "tsundoku",
                    tsundokuAt: "2026-10-11T21:00:00+09:00"
                )
            ],
            records: [
                makeSeedRecord(
                    id: makeRecordUUID(1),
                    bookId: uuidBookA,
                    startedAt: "2026-10-15T21:00:00+09:00",
                    endedAt: "2026-10-15T21:20:00+09:00",
                    minutes: 20,
                    nightDate: "2026-10-15"
                ),
                makeSeedRecord(
                    id: makeRecordUUID(2),
                    bookId: uuidBookA,
                    startedAt: "2026-10-16T21:00:00+09:00",
                    endedAt: "2026-10-16T21:15:00+09:00",
                    minutes: 15,
                    nightDate: "2026-10-16"
                ),
                makeSeedRecord(
                    id: makeRecordUUID(3),
                    bookId: uuidBookA,
                    startedAt: "2026-10-17T21:00:00+09:00",
                    endedAt: "2026-10-17T21:30:00+09:00",
                    minutes: 30,
                    nightDate: "2026-10-17"
                )
            ]
        )
    }

    private let emptyCatalogStub = #"{"stubVersion":1,"status":"ready","books":[],"cooccurrences":[]}"#
    private let emptyAwardsStub = #"{"mode":"override","items":[]}"#

    private let awardsStub = """
    {
      "mode": "override",
      "items": [
        {
          "id": "naoki-156",
          "award": "直木三十五賞",
          "sessionOrYear": "第156回",
          "order": 1,
          "title": "蜜蜂と遠雷",
          "author": "恩田陸"
        },
        {
          "id": "naoki-157",
          "award": "直木三十五賞",
          "sessionOrYear": "第157回",
          "order": 2,
          "title": "月の満ち欠け",
          "author": "佐藤正午"
        },
        {
          "id": "naoki-160",
          "award": "直木三十五賞",
          "sessionOrYear": "第160回",
          "order": 3,
          "title": "宝島",
          "author": "真藤順丈"
        }
      ]
    }
    """

    func test_AC77_読み終えたボタンで読了になり奥付5行と奥付撮影ボタンが出る() {
        resetAndLaunch(
            seedJSON: finishSeed,
            now: "2026-10-18T21:00:00+09:00",
            ndlStubJSON: emptyCatalogStub,
            awardsJSON: awardsStub
        )
        let finishBtn = element("bookmark.finish")
        XCTAssertTrue(finishBtn.waitForExistence(timeout: uiTimeout))
        finishBtn.tap()

        XCTAssertTrue(element("finish.colophon").waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(element("colophon.title").exists)
        XCTAssertTrue(element("colophon.author").exists)
        XCTAssertTrue(element("colophon.publisher").exists)
        XCTAssertTrue(element("colophon.year").exists)
        XCTAssertTrue(element("colophon.award").exists)
        XCTAssertEqual(matchingCount("colophon.capture"), 1)

        let books = readStoreBooks()
        let bookA = books.first { ($0["id"] as? String) == uuidBookA }
        XCTAssertEqual(bookA?["status"] as? String, "finished")
        let currentCount = books.filter { ($0["status"] as? String) == "current" }.count
        XCTAssertEqual(currentCount, 0)
    }

    func test_AC78_次の1冊に積読の関連本2冊と未所有の関連本1冊が順に並ぶ() {
        resetAndLaunch(
            seedJSON: finishSeed,
            now: "2026-10-18T21:00:00+09:00",
            ndlStubJSON: emptyCatalogStub,
            awardsJSON: awardsStub
        )
        element("bookmark.finish").tap()

        XCTAssertTrue(element("finish.colophon").waitForExistence(timeout: uiTimeout))
        let candP = element("next.candidate.\(uuidBookP)")
        let candQ = element("next.candidate.\(uuidBookQ)")
        let candN = element("next.candidate.naoki-157")

        XCTAssertTrue(candP.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(candQ.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(candN.waitForExistence(timeout: uiTimeout))

        let allCount = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "next.candidate.")).count
        XCTAssertEqual(allCount, 3)

        XCTAssertTrue(candP.label.contains("夜のピクニック"))
        XCTAssertTrue(candQ.label.contains("宝島"))
        XCTAssertTrue(candN.label.contains("月の満ち欠け"))
        XCTAssertLessThan(candP.frame.minY, candQ.frame.minY)
        XCTAssertLessThan(candQ.frame.minY, candN.frame.minY)
    }

    func test_AC79_次の1冊の各候補に事実1行の理由が出る() {
        resetAndLaunch(
            seedJSON: finishSeed,
            now: "2026-10-18T21:00:00+09:00",
            ndlStubJSON: emptyCatalogStub,
            awardsJSON: awardsStub
        )
        element("bookmark.finish").tap()

        XCTAssertTrue(element("finish.colophon").waitForExistence(timeout: uiTimeout))
        let candP = element("next.candidate.\(uuidBookP)")
        let candQ = element("next.candidate.\(uuidBookQ)")
        let candN = element("next.candidate.naoki-157")

        let reasonP = candP.descendants(matching: .any).matching(identifier: "next.reason").firstMatch
        let reasonQ = candQ.descendants(matching: .any).matching(identifier: "next.reason").firstMatch
        let reasonN = candN.descendants(matching: .any).matching(identifier: "next.reason").firstMatch

        XCTAssertTrue(reasonP.waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(reasonP.label, "積読から・同じ著者")
        XCTAssertEqual(reasonQ.label, "積読から・同じ賞（直木三十五賞）")
        XCTAssertEqual(reasonN.label, "同じ賞（第157回 直木三十五賞）")
    }

    func test_AC80_未所有の候補がないときは積読から最大3冊を出す() {
        let seedNoUnowned = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "蜜蜂と遠雷",
                author: "恩田陸",
                status: "current"
            ),
            makeSeedBook(
                id: uuidBookP,
                title: "夜のピクニック",
                author: "恩田陸",
                status: "tsundoku",
                tsundokuAt: "2026-10-14T21:00:00+09:00"
            ),
            makeSeedBook(
                id: uuidBookR,
                title: "銀河鉄道の夜",
                author: "宮沢賢治",
                status: "tsundoku",
                tsundokuAt: "2026-10-13T21:00:00+09:00"
            ),
            makeSeedBook(
                id: uuidBookS,
                title: "走れメロス",
                author: "太宰治",
                status: "tsundoku",
                tsundokuAt: "2026-10-12T21:00:00+09:00"
            )
        ])
        resetAndLaunch(
            seedJSON: seedNoUnowned,
            now: "2026-10-18T21:00:00+09:00",
            ndlStubJSON: emptyCatalogStub,
            awardsJSON: emptyAwardsStub
        )
        element("bookmark.finish").tap()

        XCTAssertTrue(element("finish.colophon").waitForExistence(timeout: uiTimeout))
        let candP = element("next.candidate.\(uuidBookP)")
        let candR = element("next.candidate.\(uuidBookR)")
        let candS = element("next.candidate.\(uuidBookS)")

        XCTAssertTrue(candP.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(candR.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(candS.waitForExistence(timeout: uiTimeout))

        let reasonP = candP.descendants(matching: .any).matching(identifier: "next.reason").firstMatch
        let reasonR = candR.descendants(matching: .any).matching(identifier: "next.reason").firstMatch
        let reasonS = candS.descendants(matching: .any).matching(identifier: "next.reason").firstMatch
        XCTAssertEqual(reasonP.label, "積読から・同じ著者")
        XCTAssertEqual(reasonR.label, "積読から")
        XCTAssertEqual(reasonS.label, "積読から")
    }

    func test_AC81_積読も未所有の候補もないときは本を加える案内が出る() {
        let onlyCurrent = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "孤独な本",
                author: "無名著者",
                status: "current"
            )
        ])
        resetAndLaunch(
            seedJSON: onlyCurrent,
            now: "2026-10-18T21:00:00+09:00",
            ndlStubJSON: emptyCatalogStub,
            awardsJSON: emptyAwardsStub
        )
        element("bookmark.finish").tap()

        XCTAssertTrue(element("next.empty.message").waitForExistence(timeout: uiTimeout))
        let allCandidates = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "next.candidate.")).count
        XCTAssertEqual(allCandidates, 0)
        XCTAssertEqual(matchingCount("next.addBook"), 1)
    }

    func test_AC82_次の1冊で積読の本を選ぶと今の本になりウィジェットも更新される() {
        resetAndLaunch(
            seedJSON: finishSeed,
            now: "2026-10-18T21:00:00+09:00",
            ndlStubJSON: emptyCatalogStub,
            awardsJSON: awardsStub,
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76"]
        )
        element("bookmark.finish").tap()

        let candP = element("next.candidate.\(uuidBookP)")
        XCTAssertTrue(candP.waitForExistence(timeout: uiTimeout))
        let chooseBtn = candP.descendants(matching: .any).matching(identifier: "next.choose").firstMatch
        XCTAssertTrue(chooseBtn.waitForExistence(timeout: uiTimeout))
        chooseBtn.tap()

        XCTAssertEqual(readHookString("bookmark.title"), "夜のピクニック")
        let widgetJSON = readHookJSON("hook.widget")
        let renders = widgetJSON["renders"] as? [[String: Any]] ?? []
        let texts = renders.first?["texts"] as? [String: Any] ?? [:]
        XCTAssertEqual(texts["widget.title"] as? String, "夜のピクニック")
        XCTAssertNil(texts["widget.line"])

        relaunchPreservingStore()
        let booksAfter = readStoreBooks()
        let pAfter = booksAfter.first { ($0["id"] as? String) == uuidBookP }
        XCTAssertEqual(pAfter?["status"] as? String, "current")
    }

    func test_AC83_受賞一覧から出た未所有の本を積読に加えられる() {
        resetAndLaunch(
            seedJSON: finishSeed,
            now: "2026-10-18T21:00:00+09:00",
            ndlStubJSON: emptyCatalogStub,
            awardsJSON: awardsStub
        )
        element("bookmark.finish").tap()

        let candN = element("next.candidate.naoki-157")
        XCTAssertTrue(candN.waitForExistence(timeout: uiTimeout))
        let addBtn = candN.descendants(matching: .any).matching(identifier: "next.addToShelf").firstMatch
        XCTAssertTrue(addBtn.waitForExistence(timeout: uiTimeout))
        addBtn.tap()

        let books = readStoreBooks()
        let added = books.first { ($0["title"] as? String) == "月の満ち欠け" }
        XCTAssertEqual(added?["author"] as? String, "佐藤正午")
        XCTAssertEqual(added?["status"] as? String, "tsundoku")
        XCTAssertNil(added?["isbn13"] as? String)
        XCTAssertNil(added?["publisher"] as? String)
        XCTAssertEqual(candN.descendants(matching: .any).matching(identifier: "next.addToShelf").count, 0)

        relaunchPreservingStore()
        let booksAfter = readStoreBooks()
        let addedAfter = booksAfter.first { ($0["title"] as? String) == "月の満ち欠け" }
        XCTAssertEqual(addedAfter?["status"] as? String, "tsundoku")
    }

    func test_AC84_読み終えのカード画像に書名著者晩数分数だけを描き一行を含めない() {
        resetAndLaunch(
            seedJSON: finishSeed,
            now: "2026-10-18T21:00:00+09:00",
            ndlStubJSON: emptyCatalogStub,
            awardsJSON: awardsStub
        )
        element("bookmark.finish").tap()

        let shareBtn = element("finish.card.share")
        XCTAssertTrue(shareBtn.waitForExistence(timeout: uiTimeout))
        shareBtn.tap()

        let shareHook = readHookJSON("hook.shareCard")
        let cards = shareHook["cards"] as? [[String: Any]] ?? []
        let firstCard = cards.first ?? [:]
        let texts = firstCard["renderedTexts"] as? [String] ?? []
        XCTAssertTrue(texts.contains("蜜蜂と遠雷"))
        XCTAssertTrue(texts.contains("恩田陸"))
        XCTAssertTrue(texts.contains("3晩"))
        XCTAssertTrue(texts.contains("65分"))
        XCTAssertEqual(firstCard["containsSavedLine"] as? Bool, false)
        XCTAssertEqual(firstCard["containsPhoto"] as? Bool, false)
    }

    func test_AC85_読み終えのカードの晩数を4時境目のユニーク晩数で数える() {
        let sameNightSeed = makeSeedJSON(
            books: [
                makeSeedBook(
                    id: uuidBookA,
                    title: "蜜蜂と遠雷",
                    author: "恩田陸",
                    status: "current"
                )
            ],
            records: [
                makeSeedRecord(
                    id: makeRecordUUID(1),
                    bookId: uuidBookA,
                    startedAt: "2026-10-15T23:30:00+09:00",
                    endedAt: "2026-10-15T23:50:00+09:00",
                    minutes: 20,
                    nightDate: "2026-10-15"
                ),
                makeSeedRecord(
                    id: makeRecordUUID(2),
                    bookId: uuidBookA,
                    startedAt: "2026-10-16T00:40:00+09:00",
                    endedAt: "2026-10-16T00:55:00+09:00",
                    minutes: 15,
                    nightDate: "2026-10-15"
                ),
                makeSeedRecord(
                    id: makeRecordUUID(3),
                    bookId: uuidBookA,
                    startedAt: "2026-10-16T21:00:00+09:00",
                    endedAt: "2026-10-16T21:30:00+09:00",
                    minutes: 30,
                    nightDate: "2026-10-16"
                )
            ]
        )
        resetAndLaunch(
            seedJSON: sameNightSeed,
            now: "2026-10-18T21:00:00+09:00",
            timezone: "Asia/Tokyo"
        )
        element("bookmark.finish").tap()
        element("finish.card.share").tap()

        let cards = readHookJSON("hook.shareCard")["cards"] as? [[String: Any]] ?? []
        let texts = cards.first?["renderedTexts"] as? [String] ?? []
        XCTAssertTrue(texts.contains("2晩"))
        XCTAssertTrue(texts.contains("65分"))
    }

    func test_AC86_今の本がある毎晩の道には次の1冊の候補を出さない() {
        resetAndLaunch(seedJSON: finishSeed, now: "2026-10-18T21:00:00+09:00", awardsJSON: awardsStub)
        XCTAssertEqual(app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "next.candidate.")).count, 0)
        XCTAssertEqual(app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "bookmark.noCurrent.next.")).count, 0)

        element("bookmark.start").tap()
        XCTAssertEqual(app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "next.candidate.")).count, 0)
        advanceClock(seconds: 120)

        element("reading.end").tap()
        XCTAssertEqual(app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "next.candidate.")).count, 0)

        element("mark.pageOnly").tap()
        let pf = element("mark.pageField")
        XCTAssertTrue(pf.waitForExistence(timeout: uiTimeout))
        pf.tap()
        pf.typeText("61")
        element("mark.save").tap()

        XCTAssertEqual(app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "next.candidate.")).count, 0)
        XCTAssertEqual(app.alerts.count, 0)
    }

    func test_AC87_端末内書誌DBからシリーズの次の巻と同じ著者の本を推薦し書誌つきで積読に加える() {
        let seriesSeed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "鹿の王 1",
                author: "上橋菜穂子",
                seriesTitle: "鹿の王",
                volumeNumber: 1,
                status: "current"
            ),
            makeSeedBook(
                id: uuidBookP,
                title: "獣の奏者",
                author: "上橋菜穂子",
                status: "tsundoku"
            )
        ])
        let ndlStub = """
        {
          "stubVersion": 1,
          "status": "ready",
          "books": [
            {
              "isbn": "9784041026000",
              "title": "鹿の王 2",
              "author": "上橋菜穂子",
              "publisher": "KADOKAWA",
              "label": "角川文庫",
              "publishedYear": 2019,
              "seriesTitle": "鹿の王",
              "volumeNumber": 2,
              "ndc": "913.6"
            },
            {
              "isbn": "9784101302720",
              "title": "狐笛のかなた",
              "author": "上橋菜穂子",
              "publisher": "新潮社",
              "label": "新潮文庫",
              "publishedYear": 2006,
              "ndc": "913.6"
            }
          ],
          "cooccurrences": []
        }
        """
        resetAndLaunch(
            seedJSON: seriesSeed,
            now: "2026-10-18T21:00:00+09:00",
            ndlStubJSON: ndlStub,
            awardsJSON: emptyAwardsStub
        )
        element("bookmark.finish").tap()

        XCTAssertTrue(element("finish.colophon").waitForExistence(timeout: uiTimeout))
        let candP = element("next.candidate.\(uuidBookP)")
        let candU1 = element("next.candidate.9784041026000")
        let candU2 = element("next.candidate.9784101302720")

        XCTAssertTrue(candP.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(candU1.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(candU2.waitForExistence(timeout: uiTimeout))

        let reasonP = candP.descendants(matching: .any).matching(identifier: "next.reason").firstMatch
        let reasonU1 = candU1.descendants(matching: .any).matching(identifier: "next.reason").firstMatch
        let reasonU2 = candU2.descendants(matching: .any).matching(identifier: "next.reason").firstMatch
        XCTAssertEqual(reasonP.label, "積読から・同じ著者")
        XCTAssertEqual(reasonU1.label, "シリーズの次の巻")
        XCTAssertEqual(reasonU2.label, "同じ著者の本")

        let addU1 = candU1.descendants(matching: .any).matching(identifier: "next.addToShelf").firstMatch
        addU1.tap()

        let books = readStoreBooks()
        let u1 = books.first { ($0["title"] as? String) == "鹿の王 2" }
        XCTAssertEqual(u1?["author"] as? String, "上橋菜穂子")
        XCTAssertEqual(u1?["publisher"] as? String, "KADOKAWA")
        XCTAssertEqual(u1?["label"] as? String, "角川文庫")
        XCTAssertEqual(u1?["publishedYear"] as? Int, 2019)
        XCTAssertEqual(u1?["isbn13"] as? String, "9784041026000")
        XCTAssertEqual(u1?["status"] as? String, "tsundoku")

        relaunchPreservingStore()
        let booksAfter = readStoreBooks()
        let u1After = booksAfter.first { ($0["isbn13"] as? String) == "9784041026000" }
        XCTAssertEqual(u1After?["status"] as? String, "tsundoku")
    }

    func test_AC127_読み終えのふりかえり1行に晩数と合計時間と最長の晩が出てカードには載らない() {
        let multiRecordSeed = makeSeedJSON(
            books: [
                makeSeedBook(
                    id: uuidBookA,
                    title: "蜜蜂と遠雷",
                    author: "恩田陸",
                    status: "current"
                )
            ],
            records: [
                makeSeedRecord(id: makeRecordUUID(1), bookId: uuidBookA, startedAt: "2026-10-03T21:00:00+09:00", endedAt: "2026-10-03T21:20:00+09:00", minutes: 20, nightDate: "2026-10-03"),
                makeSeedRecord(id: makeRecordUUID(2), bookId: uuidBookA, startedAt: "2026-10-05T21:30:00+09:00", endedAt: "2026-10-05T21:55:00+09:00", minutes: 25, nightDate: "2026-10-05"),
                makeSeedRecord(id: makeRecordUUID(3), bookId: uuidBookA, startedAt: "2026-10-08T22:00:00+09:00", endedAt: "2026-10-08T22:15:00+09:00", minutes: 15, nightDate: "2026-10-08"),
                makeSeedRecord(id: makeRecordUUID(4), bookId: uuidBookA, startedAt: "2026-10-11T21:00:00+09:00", endedAt: "2026-10-11T21:20:00+09:00", minutes: 20, nightDate: "2026-10-11"),
                makeSeedRecord(id: makeRecordUUID(5), bookId: uuidBookA, startedAt: "2026-10-15T21:00:00+09:00", endedAt: "2026-10-15T21:18:00+09:00", minutes: 18, nightDate: "2026-10-15"),
                makeSeedRecord(id: makeRecordUUID(6), bookId: uuidBookA, startedAt: "2026-10-16T01:30:00+09:00", endedAt: "2026-10-16T01:50:00+09:00", minutes: 20, nightDate: "2026-10-15"),
                makeSeedRecord(id: makeRecordUUID(7), bookId: uuidBookA, startedAt: "2026-10-17T21:00:00+09:00", endedAt: "2026-10-17T21:24:00+09:00", minutes: 24, nightDate: "2026-10-17")
            ]
        )
        resetAndLaunch(seedJSON: multiRecordSeed, now: "2026-10-18T21:00:00+09:00", timezone: "Asia/Tokyo")
        element("bookmark.finish").tap()

        let reflection = readHookString("finish.reflection")
        XCTAssertTrue(reflection.contains("6晩"))
        XCTAssertTrue(reflection.contains("142分（2時間22分）"))
        XCTAssertTrue(reflection.contains("10月15日"))
        XCTAssertTrue(reflection.contains("38分"))

        element("finish.card.share").tap()
        let cards = readHookJSON("hook.shareCard")["cards"] as? [[String: Any]] ?? []
        let firstCard = cards.first ?? [:]
        let texts = firstCard["renderedTexts"] as? [String] ?? []
        XCTAssertFalse(texts.joined(separator: " ").contains("10月15日"))
        XCTAssertFalse(texts.joined(separator: " ").contains("38分"))
        XCTAssertEqual(firstCard["containsReflection"] as? Bool, false)
    }

    func test_AC128_ふりかえり1行の1晩のみの文言と同点最長晩の新しい日付選択を検証する() {
        let singleNightSeed = makeSeedJSON(
            books: [
                makeSeedBook(
                    id: uuidBookA,
                    title: "蜜蜂と遠雷",
                    author: "恩田陸",
                    status: "current"
                )
            ],
            records: [
                makeSeedRecord(id: makeRecordUUID(1), bookId: uuidBookA, minutes: 30, nightDate: "2026-10-15")
            ]
        )
        resetAndLaunch(seedJSON: singleNightSeed, now: "2026-10-18T21:00:00+09:00", timezone: "Asia/Tokyo")
        element("bookmark.finish").tap()
        let singleRef = readHookString("finish.reflection")
        XCTAssertTrue(singleRef.contains("1晩"))
        XCTAssertTrue(singleRef.contains("30分"))
        XCTAssertFalse(singleRef.contains("10月15日"))

        let tieSeed = makeSeedJSON(
            books: [
                makeSeedBook(
                    id: uuidBookA,
                    title: "蜜蜂と遠雷",
                    author: "恩田陸",
                    status: "current"
                )
            ],
            records: [
                makeSeedRecord(id: makeRecordUUID(1), bookId: uuidBookA, startedAt: "2026-10-13T21:00:00+09:00", endedAt: "2026-10-13T21:30:00+09:00", minutes: 30, nightDate: "2026-10-13"),
                makeSeedRecord(id: makeRecordUUID(2), bookId: uuidBookA, startedAt: "2026-10-14T21:00:00+09:00", endedAt: "2026-10-14T21:10:00+09:00", minutes: 10, nightDate: "2026-10-14"),
                makeSeedRecord(id: makeRecordUUID(3), bookId: uuidBookA, startedAt: "2026-10-15T21:00:00+09:00", endedAt: "2026-10-15T21:30:00+09:00", minutes: 30, nightDate: "2026-10-15")
            ]
        )
        resetAndLaunch(seedJSON: tieSeed, now: "2026-10-18T21:00:00+09:00", timezone: "Asia/Tokyo")
        element("bookmark.finish").tap()
        let tieRef = readHookString("finish.reflection")
        XCTAssertTrue(tieRef.contains("3晩"))
        XCTAssertTrue(tieRef.contains("70分（1時間10分）"))
        XCTAssertTrue(tieRef.contains("10月15日"))
    }

    func test_AC129_記録が0件の本を読み終えたときはふりかえり1行を出さない() {
        let zeroRecordSeed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "蜜蜂と遠雷",
                author: "恩田陸",
                status: "current"
            )
        ])
        resetAndLaunch(seedJSON: zeroRecordSeed, now: "2026-10-18T21:00:00+09:00")
        element("bookmark.finish").tap()

        XCTAssertTrue(element("finish.colophon").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(matchingCount("finish.reflection"), 0)
        XCTAssertEqual(app.alerts.count, 0)
    }

    func test_AC145_今の本が0冊で積読があるときしおり画面に最大3冊出て1タップで今の本になる() {
        let noCurrentSeed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "蜜蜂と遠雷",
                author: "恩田陸",
                status: "finished",
                finishedAt: "2026-10-17T22:00:00+09:00"
            ),
            makeSeedBook(
                id: uuidBookR,
                title: "銀河鉄道の夜",
                author: "宮沢賢治",
                status: "tsundoku",
                tsundokuAt: "2026-10-15T21:00:00+09:00"
            ),
            makeSeedBook(
                id: uuidBookS,
                title: "走れメロス",
                author: "太宰治",
                status: "tsundoku",
                tsundokuAt: "2026-10-14T21:00:00+09:00"
            ),
            makeSeedBook(
                id: uuidBookP,
                title: "夜のピクニック",
                author: "恩田陸",
                status: "tsundoku",
                tsundokuAt: "2026-10-13T21:00:00+09:00"
            ),
            makeSeedBook(
                id: uuidBookT,
                title: "檸檬",
                author: "梶井基次郎",
                status: "tsundoku",
                tsundokuAt: "2026-10-12T21:00:00+09:00"
            )
        ])
        resetAndLaunch(seedJSON: noCurrentSeed, now: "2026-10-18T21:00:00+09:00")

        XCTAssertTrue(element("bookmark.noCurrent.message").waitForExistence(timeout: uiTimeout))
        let rowP = element("bookmark.noCurrent.next.\(uuidBookP)")
        let rowR = element("bookmark.noCurrent.next.\(uuidBookR)")
        let rowS = element("bookmark.noCurrent.next.\(uuidBookS)")
        XCTAssertTrue(rowP.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(rowR.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(rowS.waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(matchingCount("bookmark.noCurrent.next.\(uuidBookT)"), 0)

        let chooseP = rowP.descendants(matching: .any).matching(identifier: "bookmark.noCurrent.choose").firstMatch
        XCTAssertTrue(chooseP.waitForExistence(timeout: uiTimeout))
        chooseP.tap()

        XCTAssertEqual(readHookString("bookmark.title"), "夜のピクニック")
        XCTAssertTrue(element("bookmark.start").exists)

        relaunchPreservingStore()
        let booksAfter = readStoreBooks()
        let pAfter = booksAfter.first { ($0["id"] as? String) == uuidBookP }
        XCTAssertEqual(pAfter?["status"] as? String, "current")
    }

    func test_AC146_読み終えた本の詳細画面にこの本のあとにが最大5冊出てその場で積読に加えられる() {
        let finishedSeed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "蜜蜂と遠雷",
                author: "恩田陸",
                status: "finished",
                finishedAt: "2026-10-17T22:00:00+09:00"
            )
        ])
        let ndlStub = """
        {
          "stubVersion": 1,
          "status": "ready",
          "books": [
            {
              "isbn": "9784101234014",
              "title": "夜のピクニック",
              "author": "恩田陸",
              "publisher": "新潮社",
              "label": "新潮文庫",
              "publishedYear": 2006
            },
            {
              "isbn": "9784101234021",
              "title": "ユージニア",
              "author": "恩田陸",
              "publisher": "角川書店",
              "publishedYear": 2005
            },
            {
              "isbn": "9784101234038",
              "title": "六番目の小夜子",
              "author": "恩田陸",
              "publisher": "新潮社",
              "publishedYear": 1998
            }
          ],
          "cooccurrences": []
        }
        """
        let awardsMany = """
        {
          "mode": "override",
          "items": [
            {
              "id": "naoki-156",
              "award": "直木三十五賞",
              "sessionOrYear": "第156回",
              "order": 1,
              "title": "蜜蜂と遠雷",
              "author": "恩田陸"
            },
            {
              "id": "naoki-157",
              "award": "直木三十五賞",
              "sessionOrYear": "第157回",
              "order": 2,
              "title": "月の満ち欠け",
              "author": "佐藤正午"
            },
            {
              "id": "naoki-159",
              "award": "直木三十五賞",
              "sessionOrYear": "第159回",
              "order": 3,
              "title": "ファーストラヴ",
              "author": "島本理生"
            },
            {
              "id": "naoki-160",
              "award": "直木三十五賞",
              "sessionOrYear": "第160回",
              "order": 4,
              "title": "宝島",
              "author": "真藤順丈"
            }
          ]
        }
        """
        resetAndLaunch(
            seedJSON: finishedSeed,
            now: "2026-10-18T21:00:00+09:00",
            ndlStubJSON: ndlStub,
            awardsJSON: awardsMany
        )

        element("toolbar.shelf").tap()
        element("shelf.row.\(uuidBookA)").tap()

        XCTAssertTrue(element("after.header").waitForExistence(timeout: uiTimeout))
        let afterCount = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "after.candidate.")).count
        XCTAssertEqual(afterCount, 5)

        let candU1 = element("after.candidate.9784101234014")
        XCTAssertTrue(candU1.waitForExistence(timeout: uiTimeout))
        let addBtn = candU1.descendants(matching: .any).matching(identifier: "after.addToShelf").firstMatch
        XCTAssertTrue(addBtn.waitForExistence(timeout: uiTimeout))
        addBtn.tap()

        let addedLabel = candU1.descendants(matching: .any).matching(identifier: "after.added").firstMatch
        XCTAssertTrue(addedLabel.waitForExistence(timeout: uiTimeout))

        let books = readStoreBooks()
        let addedU1 = books.first { ($0["isbn13"] as? String) == "9784101234014" }
        XCTAssertEqual(addedU1?["status"] as? String, "tsundoku")

        relaunchPreservingStore()
        let booksAfter = readStoreBooks()
        let addedAfter = booksAfter.first { ($0["isbn13"] as? String) == "9784101234014" }
        XCTAssertEqual(addedAfter?["status"] as? String, "tsundoku")
    }

    func test_AC147_端末内の重み付けでよく選ぶ理由の候補が既定の順より上に繰り上がる() {
        let weightSeed = makeSeedJSON(
            books: [
                makeSeedBook(
                    id: uuidBookA,
                    title: "蜜蜂と遠雷",
                    author: "恩田陸",
                    status: "current"
                )
            ],
            settings: makeSeedSettings(
                recommendationWeights: [
                    "readers": ["chosen": 0, "skipped": 0],
                    "nextVolume": ["chosen": 0, "skipped": 0],
                    "sameAuthor": ["chosen": 0, "skipped": 3],
                    "sameAward": ["chosen": 3, "skipped": 0],
                    "sameLabel": ["chosen": 0, "skipped": 0]
                ]
            )
        )
        let ndlStub = """
        {
          "stubVersion": 1,
          "status": "ready",
          "books": [
            {
              "isbn": "9784101234014",
              "title": "夜のピクニック",
              "author": "恩田陸"
            }
          ],
          "cooccurrences": []
        }
        """
        resetAndLaunch(
            seedJSON: weightSeed,
            now: "2026-10-18T21:00:00+09:00",
            ndlStubJSON: ndlStub,
            awardsJSON: awardsStub
        )
        element("bookmark.finish").tap()

        XCTAssertTrue(element("finish.colophon").waitForExistence(timeout: uiTimeout))
        let candAward = element("next.candidate.naoki-157")
        let candAuthor = element("next.candidate.9784101234014")
        XCTAssertTrue(candAward.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(candAuthor.waitForExistence(timeout: uiTimeout))
        XCTAssertLessThan(candAward.frame.minY, candAuthor.frame.minY)
    }

    func test_AC148_共起テーブルから文学NDC9かつ10人以上の本だけを人数を出さずに推薦する() {
        let coocSeed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                isbn13: "9784863893894",
                title: "蜜蜂と遠雷",
                author: "恩田陸",
                status: "current"
            )
        ])
        let ndlCooc = """
        {
          "stubVersion": 1,
          "status": "ready",
          "books": [
            {
              "isbn": "9784101234014",
              "title": "夜のピクニック",
              "author": "別著者A",
              "ndc": "913.6"
            },
            {
              "isbn": "9784101234021",
              "title": "ユージニア",
              "author": "別著者B",
              "ndc": "913.6"
            },
            {
              "isbn": "9784101234038",
              "title": "経営の教科書",
              "author": "山田太郎",
              "ndc": "336"
            }
          ],
          "cooccurrences": [
            {
              "fromISBN": "9784863893894",
              "toISBN": "9784101234014",
              "count": 12,
              "ndc": "913.6"
            },
            {
              "fromISBN": "9784863893894",
              "toISBN": "9784101234021",
              "count": 9,
              "ndc": "913.6"
            },
            {
              "fromISBN": "9784863893894",
              "toISBN": "9784101234038",
              "count": 25,
              "ndc": "336"
            }
          ]
        }
        """
        resetAndLaunch(
            seedJSON: coocSeed,
            now: "2026-10-18T21:00:00+09:00",
            ndlStubJSON: ndlCooc,
            awardsJSON: emptyAwardsStub
        )
        element("bookmark.finish").tap()

        XCTAssertTrue(element("finish.colophon").waitForExistence(timeout: uiTimeout))
        let candI2 = element("next.candidate.9784101234014")
        XCTAssertTrue(candI2.waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(matchingCount("next.candidate.9784101234021"), 0)
        XCTAssertEqual(matchingCount("next.candidate.9784101234038"), 0)

        let reasonEl = candI2.descendants(matching: .any).matching(identifier: "next.reason").firstMatch
        XCTAssertEqual(reasonEl.label, "この本を読み終えた人が、次に読んだ本")
        XCTAssertFalse(reasonEl.label.contains("12"))
        XCTAssertFalse(candI2.label.contains("12"))
    }
}
