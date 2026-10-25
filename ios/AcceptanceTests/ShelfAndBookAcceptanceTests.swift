import XCTest

final class ShelfAndBookAcceptanceTests: AcceptanceTestBase {
    func test_AC13_本棚の3区分と積読の新しい順の並びを検証する() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "本A",
                status: "current"
            ),
            makeSeedBook(
                id: uuidBookB,
                title: "本B",
                status: "tsundoku",
                tsundokuAt: "2026-10-10T21:00:00+09:00"
            ),
            makeSeedBook(
                id: uuidBookC,
                title: "本C",
                status: "tsundoku",
                tsundokuAt: "2026-10-12T21:00:00+09:00"
            ),
            makeSeedBook(
                id: uuidBookD,
                title: "本D",
                status: "tsundoku",
                tsundokuAt: "2026-10-14T21:00:00+09:00"
            ),
            makeSeedBook(
                id: uuidBookE,
                title: "本E",
                status: "finished",
                finishedAt: "2026-10-11T21:00:00+09:00"
            )
        ])
        resetAndLaunch(seedJSON: seed)

        element("toolbar.shelf").tap()

        XCTAssertTrue(element("shelf.current").waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(element("shelf.tsundoku").waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(element("shelf.finished").waitForExistence(timeout: uiTimeout))

        let rowA = element("shelf.row.\(uuidBookA)")
        let rowB = element("shelf.row.\(uuidBookB)")
        let rowC = element("shelf.row.\(uuidBookC)")
        let rowD = element("shelf.row.\(uuidBookD)")
        let rowE = element("shelf.row.\(uuidBookE)")

        XCTAssertTrue(rowA.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(rowD.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(rowC.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(rowB.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(rowE.waitForExistence(timeout: uiTimeout))

        XCTAssertLessThan(rowD.frame.minY, rowC.frame.minY)
        XCTAssertLessThan(rowC.frame.minY, rowB.frame.minY)
    }

    func test_AC14_積読や読了の本を今の本に切り替えられる() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                status: "current",
                progressUnit: "page",
                page: 61,
                lastLine: "下人の行方は、誰も知らない。"
            ),
            makeSeedBook(
                id: uuidBookB,
                title: "檸檬",
                status: "tsundoku",
                tsundokuAt: "2026-10-10T21:00:00+09:00"
            ),
            makeSeedBook(
                id: uuidBookE,
                title: "人間失格",
                status: "finished",
                finishedAt: "2026-10-11T21:00:00+09:00"
            )
        ])
        resetAndLaunch(
            seedJSON: seed,
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76"]
        )

        element("toolbar.shelf").tap()
        element("shelf.row.\(uuidBookB)").tap()

        let readThisBtn = element("book.readThis")
        XCTAssertTrue(readThisBtn.waitForExistence(timeout: uiTimeout))
        readThisBtn.tap()

        let books1 = readStoreBooks()
        let a1 = books1.first { ($0["id"] as? String) == uuidBookA }
        let b1 = books1.first { ($0["id"] as? String) == uuidBookB }
        XCTAssertEqual(b1?["status"] as? String, "current")
        XCTAssertEqual(a1?["status"] as? String, "tsundoku")
        XCTAssertEqual(a1?["lastLine"] as? String, "下人の行方は、誰も知らない。")
        XCTAssertEqual(a1?["page"] as? Int, 61)

        let widget1 = readHookString("hook.widget")
        XCTAssertTrue(widget1.contains("檸檬"))

        element("toolbar.shelf").tap()
        element("shelf.row.\(uuidBookE)").tap()
        element("book.readThis").tap()

        let books2 = readStoreBooks()
        let b2 = books2.first { ($0["id"] as? String) == uuidBookB }
        let e2 = books2.first { ($0["id"] as? String) == uuidBookE }
        XCTAssertEqual(e2?["status"] as? String, "current")
        XCTAssertEqual(b2?["status"] as? String, "tsundoku")

        relaunchPreservingStore()
        let booksAfter = readStoreBooks()
        let eAfter = booksAfter.first { ($0["id"] as? String) == uuidBookE }
        XCTAssertEqual(eAfter?["status"] as? String, "current")
    }

    func test_AC15_本の書名と著者を直しても記録が保たれる() {
        let seed = makeSeedJSON(
            books: [
                makeSeedBook(
                    id: uuidBookA,
                    title: "こころ",
                    author: "漱石",
                    status: "current"
                )
            ],
            records: [
                makeSeedRecord(
                    id: makeRecordUUID(1),
                    bookId: uuidBookA,
                    startedAt: "2026-10-14T21:00:00+09:00",
                    endedAt: "2026-10-14T21:20:00+09:00",
                    minutes: 20,
                    nightDate: "2026-10-14",
                    entry: "app"
                ),
                makeSeedRecord(
                    id: makeRecordUUID(2),
                    bookId: uuidBookA,
                    startedAt: "2026-10-15T21:00:00+09:00",
                    endedAt: "2026-10-15T21:30:00+09:00",
                    minutes: 30,
                    nightDate: "2026-10-15",
                    entry: "app"
                )
            ]
        )
        resetAndLaunch(seedJSON: seed)

        element("toolbar.shelf").tap()
        element("shelf.row.\(uuidBookA)").tap()

        let editBtn = element("book.edit")
        XCTAssertTrue(editBtn.waitForExistence(timeout: uiTimeout))
        editBtn.tap()

        let titleField = element("book.edit.title")
        let authorField = element("book.edit.author")
        XCTAssertTrue(titleField.waitForExistence(timeout: uiTimeout))
        titleField.tap()
        titleField.typeText("こゝろ")

        authorField.tap()
        authorField.typeText("夏目漱石")

        element("book.edit.save").tap()

        let colophonTitle = element("colophon.title")
        let colophonAuthor = element("colophon.author")
        XCTAssertTrue(colophonTitle.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(colophonTitle.label.contains("こゝろ"))
        XCTAssertTrue(colophonAuthor.label.contains("夏目漱石"))

        let records = readStoreRecords()
        XCTAssertEqual(records.count, 2)
        let total = records.compactMap { $0["minutes"] as? Int }.reduce(0, +)
        XCTAssertEqual(total, 50)

        relaunchPreservingStore()
        let recordsAfter = readStoreRecords()
        XCTAssertEqual(recordsAfter.count, 2)
    }

    func test_AC16_今の本を消すと記録も消え今の本なしになる() {
        let seed = makeSeedJSON(
            books: [
                makeSeedBook(
                    id: uuidBookA,
                    title: "こころ",
                    status: "current"
                ),
                makeSeedBook(
                    id: uuidBookB,
                    title: "檸檬",
                    status: "tsundoku"
                )
            ],
            records: [
                makeSeedRecord(
                    id: makeRecordUUID(1),
                    bookId: uuidBookA,
                    startedAt: "2026-10-13T21:00:00+09:00",
                    endedAt: "2026-10-13T21:10:00+09:00",
                    minutes: 10,
                    nightDate: "2026-10-13",
                    entry: "app"
                ),
                makeSeedRecord(
                    id: makeRecordUUID(2),
                    bookId: uuidBookA,
                    startedAt: "2026-10-14T21:00:00+09:00",
                    endedAt: "2026-10-14T21:20:00+09:00",
                    minutes: 20,
                    nightDate: "2026-10-14",
                    entry: "app"
                ),
                makeSeedRecord(
                    id: makeRecordUUID(3),
                    bookId: uuidBookA,
                    startedAt: "2026-10-15T21:00:00+09:00",
                    endedAt: "2026-10-15T21:30:00+09:00",
                    minutes: 30,
                    nightDate: "2026-10-15",
                    entry: "app"
                ),
                makeSeedRecord(
                    id: makeRecordUUID(4),
                    bookId: uuidBookB,
                    startedAt: "2026-10-12T21:00:00+09:00",
                    endedAt: "2026-10-12T21:15:00+09:00",
                    minutes: 15,
                    nightDate: "2026-10-12",
                    entry: "app"
                )
            ]
        )
        resetAndLaunch(
            seedJSON: seed,
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76"]
        )

        element("toolbar.shelf").tap()
        element("shelf.row.\(uuidBookA)").tap()
        element("book.delete").tap()

        let confirm = element("book.delete.confirm")
        XCTAssertTrue(confirm.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(confirm.label.contains("3"))
        let confirmBtn = element("book.delete.confirmButton")
        if confirmBtn.exists {
            confirmBtn.tap()
        } else {
            confirm.tap()
        }

        let books = readStoreBooks()
        let records = readStoreRecords()
        XCTAssertEqual(books.count, 1)
        XCTAssertEqual(books.first?["id"] as? String, uuidBookB)
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?["bookId"] as? String, uuidBookB)

        let widget = readHookString("hook.widget")
        XCTAssertTrue(widget.contains("widget.empty") || widget.contains("empty"))

        relaunchPreservingStore()
        XCTAssertTrue(element("bookmark.noCurrent.message").waitForExistence(timeout: uiTimeout))
        let booksAfter = readStoreBooks()
        XCTAssertEqual(booksAfter.count, 1)
    }

    func test_AC17_本の画面の奥付5行と出版社レーベル受賞が出る() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "蜜蜂と遠雷",
                author: "恩田陸",
                publisher: "幻冬舎",
                label: nil,
                publishedYear: 2016,
                status: "current"
            ),
            makeSeedBook(
                id: uuidBookB,
                title: "こころ",
                author: "夏目漱石",
                publisher: "新潮社",
                label: "新潮文庫",
                publishedYear: 2004,
                status: "tsundoku"
            )
        ])
        resetAndLaunch(seedJSON: seed)

        element("toolbar.shelf").tap()
        element("shelf.row.\(uuidBookA)").tap()

        XCTAssertTrue(element("book.colophon").waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(element("colophon.title").label.contains("蜜蜂と遠雷"))
        XCTAssertTrue(element("colophon.author").label.contains("恩田陸"))
        XCTAssertTrue(element("colophon.publisher").label.contains("幻冬舎"))
        XCTAssertTrue(element("colophon.year").label.contains("2016"))
        let awardEl = element("colophon.award")
        XCTAssertTrue(awardEl.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(awardEl.label.contains("第156回 直木三十五賞"))
        XCTAssertTrue(awardEl.label.contains("2017年 本屋大賞"))

        navigateBackToBookmark()
        element("shelf.row.\(uuidBookB)").tap()
        XCTAssertTrue(element("colophon.publisher").waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(element("colophon.publisher").label.contains("新潮社（新潮文庫）") || element("colophon.publisher").label.contains("新潮文庫"))
        XCTAssertEqual(matchingCount("colophon.award"), 0)
    }

    func test_AC18_奥付でデータのない行や不明の文字を出さない() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "無題の本",
                status: "current"
            )
        ])
        resetAndLaunch(seedJSON: seed)

        element("toolbar.shelf").tap()
        element("shelf.row.\(uuidBookA)").tap()

        let colophon = element("book.colophon")
        XCTAssertTrue(colophon.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(element("colophon.title").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(matchingCount("colophon.author"), 0)
        XCTAssertEqual(matchingCount("colophon.publisher"), 0)
        XCTAssertEqual(matchingCount("colophon.year"), 0)
        XCTAssertEqual(matchingCount("colophon.award"), 0)
        XCTAssertFalse(colophon.label.contains("不明"))
        XCTAssertFalse(colophon.label.contains("なし"))
        XCTAssertFalse(colophon.label.contains("受賞なし"))
    }

    func test_AC19_書名と著者の両方が一致するとき受賞が出る() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "コンビニ人間",
                author: "村田 沙耶香",
                status: "current"
            )
        ])
        resetAndLaunch(seedJSON: seed)

        element("toolbar.shelf").tap()
        element("shelf.row.\(uuidBookA)").tap()

        let award = element("colophon.award")
        XCTAssertTrue(award.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(award.label.contains("第155回 芥川龍之介賞"))
    }

    func test_AC20_片方不一致や派生本には受賞を出さない() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "コンビニ人間",
                author: "別の著者",
                status: "current"
            ),
            makeSeedBook(
                id: uuidBookB,
                title: "コンビニ",
                author: "村田沙耶香",
                status: "tsundoku"
            ),
            makeSeedBook(
                id: uuidBookC,
                title: "鹿の王 上",
                author: "上橋菜穂子",
                status: "tsundoku"
            ),
            makeSeedBook(
                id: uuidBookD,
                title: "コンビニ人間―創作ノート",
                author: "村田沙耶香",
                status: "tsundoku"
            )
        ])
        resetAndLaunch(seedJSON: seed)

        element("toolbar.shelf").tap()
        for id in [uuidBookA, uuidBookB, uuidBookC, uuidBookD] {
            element("shelf.row.\(id)").tap()
            XCTAssertTrue(element("book.colophon").waitForExistence(timeout: uiTimeout))
            XCTAssertEqual(matchingCount("colophon.award"), 0)
            XCTAssertFalse(element("book.colophon").label.contains("受賞なし"))
            navigateBackToBookmark()
        }
    }

    func test_AC21_記号や括弧の違いを正規化して受賞を照合する() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "そして、バトンは渡された",
                author: "瀬尾 まいこ",
                status: "current"
            ),
            makeSeedBook(
                id: uuidBookB,
                title: "そして、バトンは渡された（文春文庫）",
                author: "瀬尾まいこ",
                status: "tsundoku"
            ),
            makeSeedBook(
                id: uuidBookC,
                title: "そして、バトンは渡された［新装版］",
                author: "瀬尾まいこ",
                status: "tsundoku"
            )
        ])
        resetAndLaunch(seedJSON: seed)

        element("toolbar.shelf").tap()
        for id in [uuidBookA, uuidBookB, uuidBookC] {
            element("shelf.row.\(id)").tap()
            let award = element("colophon.award")
            XCTAssertTrue(award.waitForExistence(timeout: uiTimeout))
            XCTAssertTrue(award.label.contains("2019年 本屋大賞"))
            navigateBackToBookmark()
        }
    }

    func test_AC22_4時境目の晩の日付とタイムゾーン変更不変を検証する() {
        let seed = makeSeedJSON(
            books: [
                makeSeedBook(
                    id: uuidBookA,
                    title: "こころ",
                    status: "current"
                )
            ],
            records: [
                makeSeedRecord(
                    id: makeRecordUUID(1),
                    bookId: uuidBookA,
                    startedAt: "2026-10-14T21:00:00+09:00",
                    endedAt: "2026-10-14T21:20:00+09:00",
                    minutes: 20,
                    nightDate: "2026-10-14",
                    entry: "app"
                ),
                makeSeedRecord(
                    id: makeRecordUUID(2),
                    bookId: uuidBookA,
                    startedAt: "2026-10-16T00:40:00+09:00",
                    endedAt: "2026-10-16T00:55:00+09:00",
                    minutes: 15,
                    nightDate: "2026-10-15",
                    entry: "app"
                ),
                makeSeedRecord(
                    id: makeRecordUUID(3),
                    bookId: uuidBookA,
                    startedAt: "2026-10-16T21:30:00+09:00",
                    endedAt: "2026-10-16T22:00:00+09:00",
                    minutes: 30,
                    nightDate: "2026-10-16",
                    entry: "app"
                ),
                makeSeedRecord(
                    id: makeRecordUUID(4),
                    bookId: uuidBookA,
                    startedAt: "2026-10-17T03:59:00+09:00",
                    endedAt: "2026-10-17T04:09:00+09:00",
                    minutes: 10,
                    nightDate: "2026-10-16",
                    entry: "app"
                ),
                makeSeedRecord(
                    id: makeRecordUUID(5),
                    bookId: uuidBookA,
                    startedAt: "2026-10-17T04:00:00+09:00",
                    endedAt: "2026-10-17T04:10:00+09:00",
                    minutes: 10,
                    nightDate: "2026-10-17",
                    entry: "app"
                )
            ]
        )
        for tz in ["Asia/Tokyo", "America/Los_Angeles"] {
            resetAndLaunch(seedJSON: seed, timezone: tz)
            element("toolbar.shelf").tap()
            element("shelf.row.\(uuidBookA)").tap()

            let r5 = element("book.record.row.\(makeRecordUUID(5))")
            let r4 = element("book.record.row.\(makeRecordUUID(4))")
            let r3 = element("book.record.row.\(makeRecordUUID(3))")
            let r2 = element("book.record.row.\(makeRecordUUID(2))")
            let r1 = element("book.record.row.\(makeRecordUUID(1))")

            XCTAssertTrue(r5.waitForExistence(timeout: uiTimeout))
            XCTAssertTrue(r5.label.contains("17") && r5.label.contains("10"))
            XCTAssertTrue(r4.label.contains("16") && r4.label.contains("10"))
            XCTAssertTrue(r3.label.contains("16") && r3.label.contains("30"))
            XCTAssertTrue(r2.label.contains("15") && r2.label.contains("15"))
            XCTAssertTrue(r1.label.contains("14") && r1.label.contains("20"))

            let nightsEl = element("book.nights")
            let totalEl = element("book.total")
            XCTAssertTrue(nightsEl.waitForExistence(timeout: uiTimeout))
            XCTAssertTrue(totalEl.waitForExistence(timeout: uiTimeout))
            XCTAssertTrue(nightsEl.label.contains("4"))
            XCTAssertTrue(totalEl.label.contains("1") && totalEl.label.contains("25") || totalEl.label.contains("85"))
        }
    }

    func test_AC23_記録がない本の画面に空の案内が出る() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookB,
                title: "檸檬",
                status: "tsundoku"
            )
        ])
        resetAndLaunch(seedJSON: seed)

        element("toolbar.shelf").tap()
        element("shelf.row.\(uuidBookB)").tap()

        XCTAssertTrue(element("book.records.empty").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(matchingCount("book.record.row"), 0)
    }

    func test_AC24_記録の分数を直すと合計分数が更新される() {
        let r1Id = makeRecordUUID(1)
        let r2Id = makeRecordUUID(2)
        let seed = makeSeedJSON(
            books: [
                makeSeedBook(
                    id: uuidBookA,
                    title: "こころ",
                    status: "current"
                )
            ],
            records: [
                makeSeedRecord(
                    id: r1Id,
                    bookId: uuidBookA,
                    startedAt: "2026-10-14T21:00:00+09:00",
                    endedAt: "2026-10-14T21:20:00+09:00",
                    minutes: 20,
                    nightDate: "2026-10-14",
                    entry: "app"
                ),
                makeSeedRecord(
                    id: r2Id,
                    bookId: uuidBookA,
                    startedAt: "2026-10-15T21:00:00+09:00",
                    endedAt: "2026-10-15T21:45:00+09:00",
                    minutes: 45,
                    nightDate: "2026-10-15",
                    entry: "app"
                )
            ]
        )
        resetAndLaunch(seedJSON: seed)

        element("toolbar.shelf").tap()
        element("shelf.row.\(uuidBookA)").tap()

        let row2 = element("book.record.row.\(r2Id)")
        XCTAssertTrue(row2.waitForExistence(timeout: uiTimeout))
        row2.tap()

        let minField = element("record.minutesField")
        XCTAssertTrue(minField.waitForExistence(timeout: uiTimeout))
        minField.tap()
        minField.typeText("30")
        element("record.save").tap()

        let records = readStoreRecords()
        XCTAssertEqual(records.count, 2)
        let edited = records.first { ($0["id"] as? String) == r2Id }
        XCTAssertEqual(edited?["minutes"] as? Int, 30)
        let total = records.compactMap { $0["minutes"] as? Int }.reduce(0, +)
        XCTAssertEqual(total, 50)

        relaunchPreservingStore()
        let recordsAfter = readStoreRecords()
        XCTAssertEqual(recordsAfter.count, 2)
        let totalAfter = recordsAfter.compactMap { $0["minutes"] as? Int }.reduce(0, +)
        XCTAssertEqual(totalAfter, 50)
    }

    func test_AC25_記録の分数の入力境界値を検証する() {
        let rId = makeRecordUUID(1)
        let seed = makeSeedJSON(
            books: [
                makeSeedBook(
                    id: uuidBookA,
                    title: "こころ",
                    status: "current"
                )
            ],
            records: [
                makeSeedRecord(
                    id: rId,
                    bookId: uuidBookA,
                    startedAt: "2026-10-15T21:00:00+09:00",
                    endedAt: "2026-10-15T21:45:00+09:00",
                    minutes: 45,
                    nightDate: "2026-10-15",
                    entry: "app"
                )
            ]
        )

        for invalidVal in ["0", "1441", "", "12.5"] {
            resetAndLaunch(seedJSON: seed)
            element("toolbar.shelf").tap()
            element("shelf.row.\(uuidBookA)").tap()
            element("book.record.row.\(rId)").tap()
            let field = element("record.minutesField")
            XCTAssertTrue(field.waitForExistence(timeout: uiTimeout))
            field.tap()
            if !invalidVal.isEmpty {
                field.typeText(invalidVal)
            }
            element("record.save").tap()
            XCTAssertTrue(element("record.minutes.invalid").waitForExistence(timeout: uiTimeout))
            let recs = readStoreRecords()
            XCTAssertEqual(recs.first?["minutes"] as? Int, 45)
        }

        let validCases: [(String, Int)] = [("１２", 12), ("1", 1), ("1440", 1440)]
        for (inputVal, expectedMin) in validCases {
            resetAndLaunch(seedJSON: seed)
            element("toolbar.shelf").tap()
            element("shelf.row.\(uuidBookA)").tap()
            element("book.record.row.\(rId)").tap()
            let field = element("record.minutesField")
            XCTAssertTrue(field.waitForExistence(timeout: uiTimeout))
            field.tap()
            field.typeText(inputVal)
            element("record.save").tap()
            let recs = readStoreRecords()
            XCTAssertEqual(recs.first?["minutes"] as? Int, expectedMin)
        }
    }

    func test_AC26_記録を消すと件数と合計と晩数が減る() {
        let r1Id = makeRecordUUID(1)
        let r2Id = makeRecordUUID(2)
        let seed = makeSeedJSON(
            books: [
                makeSeedBook(
                    id: uuidBookA,
                    title: "こころ",
                    status: "current"
                )
            ],
            records: [
                makeSeedRecord(
                    id: r1Id,
                    bookId: uuidBookA,
                    startedAt: "2026-10-14T21:00:00+09:00",
                    endedAt: "2026-10-14T21:20:00+09:00",
                    minutes: 20,
                    nightDate: "2026-10-14",
                    entry: "app"
                ),
                makeSeedRecord(
                    id: r2Id,
                    bookId: uuidBookA,
                    startedAt: "2026-10-15T21:00:00+09:00",
                    endedAt: "2026-10-15T21:45:00+09:00",
                    minutes: 45,
                    nightDate: "2026-10-15",
                    entry: "app"
                )
            ]
        )
        resetAndLaunch(seedJSON: seed)

        element("toolbar.shelf").tap()
        element("shelf.row.\(uuidBookA)").tap()
        element("book.record.row.\(r2Id)").tap()

        let deleteBtn = element("record.delete")
        XCTAssertTrue(deleteBtn.waitForExistence(timeout: uiTimeout))
        deleteBtn.tap()

        let confirmBtn = element("record.delete.confirmButton")
        if confirmBtn.waitForExistence(timeout: uiTimeout) {
            confirmBtn.tap()
        } else if element("record.delete.confirm").exists {
            element("record.delete.confirm").tap()
        }

        let records = readStoreRecords()
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?["minutes"] as? Int, 20)

        relaunchPreservingStore()
        let recordsAfter = readStoreRecords()
        XCTAssertEqual(recordsAfter.count, 1)
        XCTAssertEqual(recordsAfter.first?["minutes"] as? Int, 20)
    }

    func test_AC112_同梱の受賞一覧データが仕様書の表と全行一致する() {
        resetAndLaunch()

        let awardsJSON = readHookJSON("hook.awards")
        XCTAssertEqual(awardsJSON["mode"] as? String, "bundled")
        XCTAssertEqual(awardsJSON["bundledCount"] as? Int, 76)

        let activeItems = awardsJSON["activeItems"] as? [[String: Any]] ?? []
        XCTAssertEqual(activeItems.count, 76)

        var akutagawaCount = 0
        var naokiCount = 0
        var hontaiCount = 0

        for (idx, item) in activeItems.enumerated() {
            let award = item["award"] as? String ?? ""
            let sessionOrYear = item["sessionOrYear"] as? String ?? ""
            let title = item["title"] as? String ?? ""
            let author = item["author"] as? String ?? ""
            XCTAssertFalse(award.isEmpty, "Empty award at index \(idx)")
            XCTAssertFalse(sessionOrYear.isEmpty, "Empty sessionOrYear at index \(idx)")
            XCTAssertFalse(title.isEmpty, "Empty title at index \(idx)")
            XCTAssertFalse(author.isEmpty, "Empty author at index \(idx)")

            switch award {
            case "芥川龍之介賞":
                akutagawaCount += 1
            case "直木三十五賞":
                naokiCount += 1
            case "本屋大賞":
                hontaiCount += 1
            default:
                XCTFail("Unexpected award name: \(award)")
            }
        }

        XCTAssertEqual(akutagawaCount, 23)
        XCTAssertEqual(naokiCount, 31)
        XCTAssertEqual(hontaiCount, 22)

        let expectedEntries: [(String, String, String, String)] = [
            ("芥川龍之介賞", "第130回", "蹴りたい背中", "綿矢りさ"),
            ("芥川龍之介賞", "第130回", "蛇にピアス", "金原ひとみ"),
            ("芥川龍之介賞", "第155回", "コンビニ人間", "村田沙耶香"),
            ("芥川龍之介賞", "第174回", "時の家", "鳥山まこと"),
            ("芥川龍之介賞", "第174回", "叫び", "畠山丑雄"),
            ("直木三十五賞", "第134回", "容疑者Ｘの献身", "東野圭吾"),
            ("直木三十五賞", "第156回", "蜜蜂と遠雷", "恩田陸"),
            ("直木三十五賞", "第174回", "カフェーの帰り道", "嶋津輝"),
            ("本屋大賞", "2004年", "博士の愛した数式", "小川洋子"),
            ("本屋大賞", "2017年", "蜜蜂と遠雷", "恩田陸"),
            ("本屋大賞", "2019年", "そして、バトンは渡された", "瀬尾まいこ"),
            ("本屋大賞", "2025年", "カフネ", "阿部暁子")
        ]

        for (award, sessionOrYear, title, author) in expectedEntries {
            let found = activeItems.contains { item in
                (item["award"] as? String) == award &&
                (item["sessionOrYear"] as? String) == sessionOrYear &&
                (item["title"] as? String) == title &&
                (item["author"] as? String) == author
            }
            XCTAssertTrue(found, "Missing expected award entry: \(award) \(sessionOrYear) \(title) \(author)")
        }
    }

    func test_AC113_奥付を1枚撮って著者出版社レーベル出版年ISBNを補完し画像を残さない() {
        let seed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "海岸通り",
                status: "current"
            )
        ])
        let ocrStub = """
        {
          "colophon": {
            "lines": [
              "著者 坂崎かおる",
              "発行所 株式会社祥伝社",
              "祥伝社文庫",
              "2024年10月15日 初版第1刷発行",
              "ISBN978-4-396-35001-7"
            ]
          }
        }
        """
        resetAndLaunch(seedJSON: seed, ocrJSON: ocrStub)

        element("toolbar.shelf").tap()
        element("shelf.row.\(uuidBookA)").tap()

        let captureBtn = element("colophon.capture")
        XCTAssertTrue(captureBtn.waitForExistence(timeout: uiTimeout))
        captureBtn.tap()

        let saveBtn = element("colophon.save")
        XCTAssertTrue(saveBtn.waitForExistence(timeout: uiTimeout))
        saveBtn.tap()

        let books = readStoreBooks()
        let book = books.first { ($0["id"] as? String) == uuidBookA }
        XCTAssertEqual(book?["author"] as? String, "坂崎かおる")
        XCTAssertEqual(book?["publisher"] as? String, "祥伝社")
        XCTAssertEqual(book?["label"] as? String, "祥伝社文庫")
        XCTAssertEqual(book?["publishedYear"] as? Int, 2024)
        XCTAssertEqual(book?["isbn13"] as? String, "9784396350017")

        let audit = readHookJSON("hook.mediaAudit")
        XCTAssertEqual(audit["savedImageFileCount"] as? Int, 0)
        XCTAssertEqual(audit["photoLibraryWriteCount"] as? Int, 0)

        relaunchPreservingStore()
        let booksAfter = readStoreBooks()
        XCTAssertEqual(booksAfter.first?["isbn13"] as? String, "9784396350017")
    }
}
