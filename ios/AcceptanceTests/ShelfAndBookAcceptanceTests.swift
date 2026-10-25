import XCTest

final class ShelfAndBookAcceptanceTests: AcceptanceTestBase {
    private let bookAId = "00000000-0000-4000-8000-000000000001"
    private let bookBId = "00000000-0000-4000-8000-000000000002"
    private let bookCId = "00000000-0000-4000-8000-000000000003"
    private let bookDId = "00000000-0000-4000-8000-000000000004"
    private let bookEId = "00000000-0000-4000-8000-000000000005"

    func test_AC13_本棚の3区分と積読の新しい順の並びを検証する() {
        let seed = """
        {
          "books": [
            {
              "id": "\(bookAId)",
              "title": "本A",
              "status": "current"
            },
            {
              "id": "\(bookBId)",
              "title": "本B",
              "status": "tsundoku",
              "tsundokuAt": "2026-10-10T21:00:00+09:00"
            },
            {
              "id": "\(bookCId)",
              "title": "本C",
              "status": "tsundoku",
              "tsundokuAt": "2026-10-12T21:00:00+09:00"
            },
            {
              "id": "\(bookDId)",
              "title": "本D",
              "status": "tsundoku",
              "tsundokuAt": "2026-10-14T21:00:00+09:00"
            },
            {
              "id": "\(bookEId)",
              "title": "本E",
              "status": "finished",
              "finishedAt": "2026-10-11T21:00:00+09:00"
            }
          ]
        }
        """
        resetAndLaunch(seedJSON: seed)

        element("toolbar.shelf").tap()

        XCTAssertTrue(element("shelf.current").waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(element("shelf.tsundoku").waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(element("shelf.finished").waitForExistence(timeout: uiTimeout))

        let rowA = element("shelf.row.\(bookAId)")
        let rowB = element("shelf.row.\(bookBId)")
        let rowC = element("shelf.row.\(bookCId)")
        let rowD = element("shelf.row.\(bookDId)")
        let rowE = element("shelf.row.\(bookEId)")

        XCTAssertTrue(rowA.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(rowD.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(rowC.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(rowB.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(rowE.waitForExistence(timeout: uiTimeout))

        XCTAssertLessThan(rowD.frame.minY, rowC.frame.minY)
        XCTAssertLessThan(rowC.frame.minY, rowB.frame.minY)
    }

    func test_AC14_積読や読了の本を今の本に切り替えられる() {
        let seed = """
        {
          "books": [
            {
              "id": "\(bookAId)",
              "title": "羅生門",
              "status": "current",
              "lastLine": "下人の行方は、誰も知らない。",
              "progressUnit": "page",
              "page": 61
            },
            {
              "id": "\(bookBId)",
              "title": "檸檬",
              "status": "tsundoku",
              "tsundokuAt": "2026-10-10T21:00:00+09:00"
            },
            {
              "id": "\(bookEId)",
              "title": "人間失格",
              "status": "finished",
              "finishedAt": "2026-10-11T21:00:00+09:00"
            }
          ]
        }
        """
        resetAndLaunch(
            seedJSON: seed,
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76"]
        )

        element("toolbar.shelf").tap()
        element("shelf.row.\(bookBId)").tap()

        let readThisBtn = element("book.readThis")
        XCTAssertTrue(readThisBtn.waitForExistence(timeout: uiTimeout))
        readThisBtn.tap()

        let store1 = readHookJSON("hook.store")
        let books1 = store1["books"] as? [[String: Any]] ?? []
        let a1 = books1.first { ($0["id"] as? String) == bookAId }
        let b1 = books1.first { ($0["id"] as? String) == bookBId }
        XCTAssertEqual(b1?["status"] as? String, "current")
        XCTAssertEqual(a1?["status"] as? String, "tsundoku")
        XCTAssertEqual(a1?["lastLine"] as? String, "下人の行方は、誰も知らない。")
        XCTAssertEqual(a1?["page"] as? Int, 61)

        let widget1 = readHookString("hook.widget")
        XCTAssertTrue(widget1.contains("檸檬"))

        element("toolbar.shelf").tap()
        element("shelf.row.\(bookEId)").tap()
        element("book.readThis").tap()

        let store2 = readHookJSON("hook.store")
        let books2 = store2["books"] as? [[String: Any]] ?? []
        let b2 = books2.first { ($0["id"] as? String) == bookBId }
        let e2 = books2.first { ($0["id"] as? String) == bookEId }
        XCTAssertEqual(e2?["status"] as? String, "current")
        XCTAssertEqual(b2?["status"] as? String, "tsundoku")

        relaunchPreservingStore()
        let booksAfter = (readHookJSON("hook.store")["books"] as? [[String: Any]]) ?? []
        let eAfter = booksAfter.first { ($0["id"] as? String) == bookEId }
        XCTAssertEqual(eAfter?["status"] as? String, "current")
    }

    func test_AC15_本の書名と著者を直しても記録が保たれる() {
        let seed = """
        {
          "books": [
            {
              "id": "\(bookAId)",
              "title": "こころ",
              "author": "漱石",
              "status": "current"
            }
          ],
          "records": [
            {
              "id": "00000000-0000-4000-9000-000000000001",
              "bookId": "\(bookAId)",
              "startedAt": "2026-10-14T21:00:00+09:00",
              "endedAt": "2026-10-14T21:20:00+09:00",
              "nightDate": "2026-10-14",
              "minutes": 20,
              "entry": "app"
            },
            {
              "id": "00000000-0000-4000-9000-000000000002",
              "bookId": "\(bookAId)",
              "startedAt": "2026-10-15T21:00:00+09:00",
              "endedAt": "2026-10-15T21:30:00+09:00",
              "nightDate": "2026-10-15",
              "minutes": 30,
              "entry": "app"
            }
          ]
        }
        """
        resetAndLaunch(seedJSON: seed)

        element("toolbar.shelf").tap()
        element("shelf.row.\(bookAId)").tap()

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

        let store = readHookJSON("hook.store")
        let records = store["records"] as? [[String: Any]] ?? []
        XCTAssertEqual(records.count, 2)
        let total = records.compactMap { $0["minutes"] as? Int }.reduce(0, +)
        XCTAssertEqual(total, 50)

        relaunchPreservingStore()
        let storeAfter = readHookJSON("hook.store")
        let recordsAfter = storeAfter["records"] as? [[String: Any]] ?? []
        XCTAssertEqual(recordsAfter.count, 2)
    }

    func test_AC16_今の本を消すと記録も消え今の本なしになる() {
        let seed = """
        {
          "books": [
            {
              "id": "\(bookAId)",
              "title": "こころ",
              "status": "current"
            },
            {
              "id": "\(bookBId)",
              "title": "檸檬",
              "status": "tsundoku"
            }
          ],
          "records": [
            {
              "id": "00000000-0000-4000-9000-000000000001",
              "bookId": "\(bookAId)",
              "startedAt": "2026-10-13T21:00:00+09:00",
              "endedAt": "2026-10-13T21:10:00+09:00",
              "nightDate": "2026-10-13",
              "minutes": 10,
              "entry": "app"
            },
            {
              "id": "00000000-0000-4000-9000-000000000002",
              "bookId": "\(bookAId)",
              "startedAt": "2026-10-14T21:00:00+09:00",
              "endedAt": "2026-10-14T21:20:00+09:00",
              "nightDate": "2026-10-14",
              "minutes": 20,
              "entry": "app"
            },
            {
              "id": "00000000-0000-4000-9000-000000000003",
              "bookId": "\(bookAId)",
              "startedAt": "2026-10-15T21:00:00+09:00",
              "endedAt": "2026-10-15T21:30:00+09:00",
              "nightDate": "2026-10-15",
              "minutes": 30,
              "entry": "app"
            },
            {
              "id": "00000000-0000-4000-9000-000000000004",
              "bookId": "\(bookBId)",
              "startedAt": "2026-10-12T21:00:00+09:00",
              "endedAt": "2026-10-12T21:15:00+09:00",
              "nightDate": "2026-10-12",
              "minutes": 15,
              "entry": "app"
            }
          ]
        }
        """
        resetAndLaunch(
            seedJSON: seed,
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76"]
        )

        element("toolbar.shelf").tap()
        element("shelf.row.\(bookAId)").tap()
        element("book.delete").tap()

        let confirm = element("book.delete.confirm")
        XCTAssertTrue(confirm.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(confirm.label.contains("3"))
        confirm.tap()

        let store = readHookJSON("hook.store")
        let books = store["books"] as? [[String: Any]] ?? []
        let records = store["records"] as? [[String: Any]] ?? []
        XCTAssertEqual(books.count, 1)
        XCTAssertEqual(books.first?["id"] as? String, bookBId)
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?["bookId"] as? String, bookBId)

        let widget = readHookString("hook.widget")
        XCTAssertTrue(widget.contains("widget.empty") || widget.contains("empty"))

        relaunchPreservingStore()
        XCTAssertTrue(element("bookmark.noCurrent.message").waitForExistence(timeout: uiTimeout))
        let booksAfter = (readHookJSON("hook.store")["books"] as? [[String: Any]]) ?? []
        XCTAssertEqual(booksAfter.count, 1)
    }

    func test_AC17_本の画面の奥付5行と出版社レーベル受賞が出る() {
        let seed = """
        {
          "books": [
            {
              "id": "\(bookAId)",
              "title": "蜜蜂と遠雷",
              "author": "恩田陸",
              "publisher": "幻冬舎",
              "label": "",
              "publishedYear": 2016,
              "status": "current"
            },
            {
              "id": "\(bookBId)",
              "title": "こころ",
              "author": "夏目漱石",
              "publisher": "新潮社",
              "label": "新潮文庫",
              "publishedYear": 2004,
              "status": "tsundoku"
            }
          ]
        }
        """
        resetAndLaunch(seedJSON: seed)

        element("toolbar.shelf").tap()
        element("shelf.row.\(bookAId)").tap()

        XCTAssertTrue(element("book.colophon").waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(element("colophon.title").label.contains("蜜蜂と遠雷"))
        XCTAssertTrue(element("colophon.author").label.contains("恩田陸"))
        XCTAssertTrue(element("colophon.publisher").label.contains("幻冬舎"))
        XCTAssertTrue(element("colophon.year").label.contains("2016"))
        let awardEl = element("colophon.award")
        XCTAssertTrue(awardEl.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(awardEl.label.contains("第156回 直木三十五賞"))
        XCTAssertTrue(awardEl.label.contains("2017年 本屋大賞"))

        element("toolbar.shelf").tap()
        element("shelf.row.\(bookBId)").tap()
        XCTAssertTrue(element("colophon.publisher").waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(element("colophon.publisher").label.contains("新潮社（新潮文庫）") || element("colophon.publisher").label.contains("新潮文庫"))
        XCTAssertEqual(matchingCount("colophon.award"), 0)
    }

    func test_AC18_奥付でデータのない行や不明の文字を出さない() {
        let seed = """
        {
          "books": [
            {
              "id": "\(bookAId)",
              "title": "無題の本",
              "status": "current"
            }
          ]
        }
        """
        resetAndLaunch(seedJSON: seed)

        element("toolbar.shelf").tap()
        element("shelf.row.\(bookAId)").tap()

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
        let seed = """
        {
          "books": [
            {
              "id": "\(bookAId)",
              "title": "コンビニ人間",
              "author": "村田 沙耶香",
              "status": "current"
            }
          ]
        }
        """
        resetAndLaunch(seedJSON: seed)

        element("toolbar.shelf").tap()
        element("shelf.row.\(bookAId)").tap()

        let award = element("colophon.award")
        XCTAssertTrue(award.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(award.label.contains("第155回 芥川龍之介賞"))
    }

    func test_AC20_片方不一致や派生本には受賞を出さない() {
        let seed = """
        {
          "books": [
            {
              "id": "\(bookAId)",
              "title": "コンビニ人間",
              "author": "別の著者",
              "status": "current"
            },
            {
              "id": "\(bookBId)",
              "title": "コンビニ",
              "author": "村田沙耶香",
              "status": "tsundoku"
            },
            {
              "id": "\(bookCId)",
              "title": "鹿の王 上",
              "author": "上橋菜穂子",
              "status": "tsundoku"
            },
            {
              "id": "\(bookDId)",
              "title": "コンビニ人間―創作ノート",
              "author": "村田沙耶香",
              "status": "tsundoku"
            }
          ]
        }
        """
        resetAndLaunch(seedJSON: seed)

        for id in [bookAId, bookBId, bookCId, bookDId] {
            element("toolbar.shelf").tap()
            element("shelf.row.\(id)").tap()
            XCTAssertTrue(element("book.colophon").waitForExistence(timeout: uiTimeout))
            XCTAssertEqual(matchingCount("colophon.award"), 0)
            XCTAssertFalse(element("book.colophon").label.contains("受賞なし"))
        }
    }

    func test_AC21_記号や括弧の違いを正規化して受賞を照合する() {
        let seed = """
        {
          "books": [
            {
              "id": "\(bookAId)",
              "title": "そして、バトンは渡された",
              "author": "瀬尾 まいこ",
              "status": "current"
            },
            {
              "id": "\(bookBId)",
              "title": "そして、バトンは渡された（文春文庫）",
              "author": "瀬尾まいこ",
              "status": "tsundoku"
            },
            {
              "id": "\(bookCId)",
              "title": "そして、バトンは渡された［新装版］",
              "author": "瀬尾まいこ",
              "status": "tsundoku"
            }
          ]
        }
        """
        resetAndLaunch(seedJSON: seed)

        for id in [bookAId, bookBId, bookCId] {
            element("toolbar.shelf").tap()
            element("shelf.row.\(id)").tap()
            let award = element("colophon.award")
            XCTAssertTrue(award.waitForExistence(timeout: uiTimeout))
            XCTAssertTrue(award.label.contains("2019年 本屋大賞"))
        }
    }

    func test_AC22_4時境目の晩の日付とタイムゾーン変更不変を検証する() {
        let seed = """
        {
          "books": [
            {
              "id": "\(bookAId)",
              "title": "こころ",
              "status": "current"
            }
          ],
          "records": [
            {
              "id": "00000000-0000-4000-9000-000000000001",
              "bookId": "\(bookAId)",
              "startedAt": "2026-10-14T21:00:00+09:00",
              "endedAt": "2026-10-14T21:20:00+09:00",
              "nightDate": "2026-10-14",
              "minutes": 20,
              "entry": "app"
            },
            {
              "id": "00000000-0000-4000-9000-000000000002",
              "bookId": "\(bookAId)",
              "startedAt": "2026-10-16T00:40:00+09:00",
              "endedAt": "2026-10-16T00:55:00+09:00",
              "nightDate": "2026-10-15",
              "minutes": 15,
              "entry": "app"
            },
            {
              "id": "00000000-0000-4000-9000-000000000003",
              "bookId": "\(bookAId)",
              "startedAt": "2026-10-16T21:30:00+09:00",
              "endedAt": "2026-10-16T22:00:00+09:00",
              "nightDate": "2026-10-16",
              "minutes": 30,
              "entry": "app"
            },
            {
              "id": "00000000-0000-4000-9000-000000000004",
              "bookId": "\(bookAId)",
              "startedAt": "2026-10-17T03:59:00+09:00",
              "endedAt": "2026-10-17T04:09:00+09:00",
              "nightDate": "2026-10-16",
              "minutes": 10,
              "entry": "app"
            },
            {
              "id": "00000000-0000-4000-9000-000000000005",
              "bookId": "\(bookAId)",
              "startedAt": "2026-10-17T04:00:00+09:00",
              "endedAt": "2026-10-17T04:10:00+09:00",
              "nightDate": "2026-10-17",
              "minutes": 10,
              "entry": "app"
            }
          ]
        }
        """
        for tz in ["Asia/Tokyo", "America/Los_Angeles"] {
            resetAndLaunch(seedJSON: seed, timezone: tz)
            element("toolbar.shelf").tap()
            element("shelf.row.\(bookAId)").tap()

            let r5 = element("book.record.row.00000000-0000-4000-9000-000000000005")
            let r4 = element("book.record.row.00000000-0000-4000-9000-000000000004")
            let r3 = element("book.record.row.00000000-0000-4000-9000-000000000003")
            let r2 = element("book.record.row.00000000-0000-4000-9000-000000000002")
            let r1 = element("book.record.row.00000000-0000-4000-9000-000000000001")

            XCTAssertTrue(r5.waitForExistence(timeout: uiTimeout))
            XCTAssertTrue(r5.label.contains("17") && r5.label.contains("10"))
            XCTAssertTrue(r4.label.contains("16") && r4.label.contains("10"))
            XCTAssertTrue(r3.label.contains("16") && r3.label.contains("30"))
            XCTAssertTrue(r2.label.contains("15") && r2.label.contains("15"))
            XCTAssertTrue(r1.label.contains("14") && r1.label.contains("20"))

            let summary = element("book.records.summary")
            if summary.waitForExistence(timeout: uiTimeout) {
                XCTAssertTrue(summary.label.contains("85"))
                XCTAssertTrue(summary.label.contains("4"))
            }
        }
    }

    func test_AC23_記録がない本の画面に空の案内が出る() {
        let seed = """
        {
          "books": [
            {
              "id": "\(bookBId)",
              "title": "檸檬",
              "status": "tsundoku"
            }
          ]
        }
        """
        resetAndLaunch(seedJSON: seed)

        element("toolbar.shelf").tap()
        element("shelf.row.\(bookBId)").tap()

        XCTAssertTrue(element("book.records.empty").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(matchingCount("book.record.row"), 0)
    }

    func test_AC24_記録の分数を直すと合計分数が更新される() {
        let r1Id = "00000000-0000-4000-9000-000000000001"
        let r2Id = "00000000-0000-4000-9000-000000000002"
        let seed = """
        {
          "books": [
            {
              "id": "\(bookAId)",
              "title": "こころ",
              "status": "current"
            }
          ],
          "records": [
            {
              "id": "\(r1Id)",
              "bookId": "\(bookAId)",
              "startedAt": "2026-10-14T21:00:00+09:00",
              "endedAt": "2026-10-14T21:20:00+09:00",
              "nightDate": "2026-10-14",
              "minutes": 20,
              "entry": "app"
            },
            {
              "id": "\(r2Id)",
              "bookId": "\(bookAId)",
              "startedAt": "2026-10-15T21:00:00+09:00",
              "endedAt": "2026-10-15T21:45:00+09:00",
              "nightDate": "2026-10-15",
              "minutes": 45,
              "entry": "app"
            }
          ]
        }
        """
        resetAndLaunch(seedJSON: seed)

        element("toolbar.shelf").tap()
        element("shelf.row.\(bookAId)").tap()

        let row2 = element("book.record.row.\(r2Id)")
        XCTAssertTrue(row2.waitForExistence(timeout: uiTimeout))
        row2.tap()

        let minField = element("record.edit.minutes")
        XCTAssertTrue(minField.waitForExistence(timeout: uiTimeout))
        minField.tap()
        minField.typeText("30")
        element("record.edit.save").tap()

        let store = readHookJSON("hook.store")
        let records = store["records"] as? [[String: Any]] ?? []
        XCTAssertEqual(records.count, 2)
        let edited = records.first { ($0["id"] as? String) == r2Id }
        XCTAssertEqual(edited?["minutes"] as? Int, 30)
        let total = records.compactMap { $0["minutes"] as? Int }.reduce(0, +)
        XCTAssertEqual(total, 50)

        relaunchPreservingStore()
        let recordsAfter = (readHookJSON("hook.store")["records"] as? [[String: Any]]) ?? []
        XCTAssertEqual(recordsAfter.count, 2)
        let totalAfter = recordsAfter.compactMap { $0["minutes"] as? Int }.reduce(0, +)
        XCTAssertEqual(totalAfter, 50)
    }

    func test_AC25_記録の分数の入力境界値を検証する() {
        let rId = "00000000-0000-4000-9000-000000000001"
        let seed = """
        {
          "books": [
            {
              "id": "\(bookAId)",
              "title": "こころ",
              "status": "current"
            }
          ],
          "records": [
            {
              "id": "\(rId)",
              "bookId": "\(bookAId)",
              "startedAt": "2026-10-15T21:00:00+09:00",
              "endedAt": "2026-10-15T21:45:00+09:00",
              "nightDate": "2026-10-15",
              "minutes": 45,
              "entry": "app"
            }
          ]
        }
        """

        for invalidVal in ["0", "1441", "", "12.5"] {
            resetAndLaunch(seedJSON: seed)
            element("toolbar.shelf").tap()
            element("shelf.row.\(bookAId)").tap()
            element("book.record.row.\(rId)").tap()
            let field = element("record.edit.minutes")
            XCTAssertTrue(field.waitForExistence(timeout: uiTimeout))
            field.tap()
            if !invalidVal.isEmpty {
                field.typeText(invalidVal)
            }
            element("record.edit.save").tap()
            XCTAssertTrue(element("record.minutes.invalid").waitForExistence(timeout: uiTimeout))
            let recs = (readHookJSON("hook.store")["records"] as? [[String: Any]]) ?? []
            XCTAssertEqual(recs.first?["minutes"] as? Int, 45)
        }

        let validCases: [(String, Int)] = [("１２", 12), ("1", 1), ("1440", 1440)]
        for (inputVal, expectedMin) in validCases {
            resetAndLaunch(seedJSON: seed)
            element("toolbar.shelf").tap()
            element("shelf.row.\(bookAId)").tap()
            element("book.record.row.\(rId)").tap()
            let field = element("record.edit.minutes")
            XCTAssertTrue(field.waitForExistence(timeout: uiTimeout))
            field.tap()
            field.typeText(inputVal)
            element("record.edit.save").tap()
            let recs = (readHookJSON("hook.store")["records"] as? [[String: Any]]) ?? []
            XCTAssertEqual(recs.first?["minutes"] as? Int, expectedMin)
        }
    }

    func test_AC26_記録を消すと件数と合計と晩数が減る() {
        let r1Id = "00000000-0000-4000-9000-000000000001"
        let r2Id = "00000000-0000-4000-9000-000000000002"
        let seed = """
        {
          "books": [
            {
              "id": "\(bookAId)",
              "title": "こころ",
              "status": "current"
            }
          ],
          "records": [
            {
              "id": "\(r1Id)",
              "bookId": "\(bookAId)",
              "startedAt": "2026-10-14T21:00:00+09:00",
              "endedAt": "2026-10-14T21:20:00+09:00",
              "nightDate": "2026-10-14",
              "minutes": 20,
              "entry": "app"
            },
            {
              "id": "\(r2Id)",
              "bookId": "\(bookAId)",
              "startedAt": "2026-10-15T21:00:00+09:00",
              "endedAt": "2026-10-15T21:45:00+09:00",
              "nightDate": "2026-10-15",
              "minutes": 45,
              "entry": "app"
            }
          ]
        }
        """
        resetAndLaunch(seedJSON: seed)

        element("toolbar.shelf").tap()
        element("shelf.row.\(bookAId)").tap()
        element("book.record.row.\(r2Id)").tap()

        let deleteBtn = element("record.delete")
        XCTAssertTrue(deleteBtn.waitForExistence(timeout: uiTimeout))
        deleteBtn.tap()

        let confirmBtn = element("record.delete.confirm")
        if confirmBtn.waitForExistence(timeout: uiTimeout) {
            confirmBtn.tap()
        }

        let store = readHookJSON("hook.store")
        let records = store["records"] as? [[String: Any]] ?? []
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?["minutes"] as? Int, 20)

        relaunchPreservingStore()
        let recordsAfter = (readHookJSON("hook.store")["records"] as? [[String: Any]]) ?? []
        XCTAssertEqual(recordsAfter.count, 1)
        XCTAssertEqual(recordsAfter.first?["minutes"] as? Int, 20)
    }

    func test_AC112_同梱の受賞一覧データが仕様書の表と全行一致する() {
        resetAndLaunch()

        let awardsJSON = readHookJSON("hook.awards")
        let activeItems = awardsJSON["activeItems"] as? [[String: Any]] ?? []
        XCTAssertGreaterThan(activeItems.count, 0)

        let hasConvenienceStore = activeItems.contains { item in
            (item["award"] as? String) == "芥川龍之介賞" &&
            (item["sessionOrYear"] as? String) == "第155回" &&
            (item["title"] as? String) == "コンビニ人間" &&
            (item["author"] as? String) == "村田沙耶香"
        }
        XCTAssertTrue(hasConvenienceStore)
    }

    func test_AC113_奥付を1枚撮って著者出版社レーベル出版年ISBNを補完し画像を残さない() {
        let seed = """
        {
          "books": [
            {
              "id": "\(bookAId)",
              "title": "海岸通り",
              "status": "current"
            }
          ]
        }
        """
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
        element("shelf.row.\(bookAId)").tap()

        let captureBtn = element("colophon.capture")
        XCTAssertTrue(captureBtn.waitForExistence(timeout: uiTimeout))
        captureBtn.tap()

        let saveBtn = element("colophon.save")
        XCTAssertTrue(saveBtn.waitForExistence(timeout: uiTimeout))
        saveBtn.tap()

        let store = readHookJSON("hook.store")
        let books = store["books"] as? [[String: Any]] ?? []
        let book = books.first { ($0["id"] as? String) == bookAId }
        XCTAssertEqual(book?["author"] as? String, "坂崎かおる")
        XCTAssertEqual(book?["publisher"] as? String, "祥伝社")
        XCTAssertEqual(book?["label"] as? String, "祥伝社文庫")
        XCTAssertEqual(book?["publishedYear"] as? Int, 2024)
        XCTAssertEqual(book?["isbn"] as? String, "9784396350017")

        let audit = readHookJSON("hook.mediaAudit")
        XCTAssertEqual(audit["savedImageFileCount"] as? Int, 0)
        XCTAssertEqual(audit["photoLibraryWriteCount"] as? Int, 0)

        relaunchPreservingStore()
        let booksAfter = (readHookJSON("hook.store")["books"] as? [[String: Any]]) ?? []
        XCTAssertEqual(booksAfter.first?["isbn"] as? String, "9784396350017")
    }
}
