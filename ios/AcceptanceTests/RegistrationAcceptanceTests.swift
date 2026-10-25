import XCTest

final class RegistrationAcceptanceTests: AcceptanceTestBase {
    private let defaultCatalogStub = """
    {
      "status": "ready",
      "books": [
        {
          "isbn": "9784101000015",
          "title": "こころ",
          "author": "夏目漱石",
          "publisher": "新潮社",
          "label": "新潮文庫",
          "publishedYear": 2004
        },
        {
          "isbn": "9784101000022",
          "title": "坊っちゃん",
          "author": "夏目漱石",
          "publisher": "新潮社",
          "label": "",
          "publishedYear": 2003
        },
        {
          "isbn": "9784101000039",
          "title": "羅生門",
          "author": "芥川龍之介",
          "publisher": "新潮社",
          "label": "新潮文庫",
          "publishedYear": 2005
        },
        {
          "isbn": "9784101000046",
          "title": "人間失格",
          "author": "太宰治",
          "publisher": "新潮社",
          "label": "新潮文庫",
          "publishedYear": 1952
        },
        {
          "isbn": "9784040000053",
          "title": "人間失格",
          "author": "太宰治",
          "publisher": "KADOKAWA",
          "label": "角川文庫",
          "publishedYear": 1989
        },
        {
          "isbn": "9784480000064",
          "title": "人間失格",
          "author": "太宰治",
          "publisher": "筑摩書房",
          "label": "",
          "publishedYear": 1998
        }
      ]
    }
    """

    func test_AC2_バーコードで最初の1冊を加えると今の本になる() {
        resetAndLaunch(ndlStubJSON: defaultCatalogStub)

        let addBtn = element("bookmark.addBook")
        XCTAssertTrue(addBtn.waitForExistence(timeout: uiTimeout))
        addBtn.tap()

        let barcodeBtn = element("register.barcode")
        if barcodeBtn.waitForExistence(timeout: uiTimeout) {
            barcodeBtn.tap()
        }

        sendBarcode("9784101000015")

        let row = element("scan.row.9784101000015")
        XCTAssertTrue(row.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(row.label.contains("こころ"))
        XCTAssertTrue(row.label.contains("夏目漱石"))
        XCTAssertTrue(row.label.contains("新潮社"))
        XCTAssertTrue(row.label.contains("新潮文庫"))

        let commitBtn = element("scan.commit")
        XCTAssertTrue(commitBtn.waitForExistence(timeout: uiTimeout))
        commitBtn.tap()

        let bmTitle = element("bookmark.title")
        XCTAssertTrue(bmTitle.waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(bmTitle.label, "こころ")

        let store = readHookJSON("hook.store")
        let books = store["books"] as? [[String: Any]] ?? []
        XCTAssertEqual(books.count, 1)
        XCTAssertEqual(books.first?["title"] as? String, "こころ")
        XCTAssertEqual(books.first?["status"] as? String, "current")
        XCTAssertEqual(books.first?["isbn"] as? String, "9784101000015")

        let outbound = readHookJSON("hook.outbound")
        let requests = outbound["requests"] as? [Any] ?? []
        XCTAssertEqual(requests.count, 0)

        relaunchPreservingStore()
        let storeAfter = readHookJSON("hook.store")
        let booksAfter = storeAfter["books"] as? [[String: Any]] ?? []
        XCTAssertEqual(booksAfter.count, 1)
        XCTAssertEqual(booksAfter.first?["status"] as? String, "current")

        attachScreenshot(name: "AC2_barcode_first_book")
    }

    func test_AC3_バーコード連続読取で重複と非図書を除きCコードで文庫を補う() {
        let seed = """
        {
          "books": [
            {
              "id": "00000000-0000-4000-8000-000000000001",
              "title": "こころ",
              "author": "夏目漱石",
              "isbn": "9784101000015",
              "status": "current"
            }
          ]
        }
        """
        resetAndLaunch(seedJSON: seed, ndlStubJSON: defaultCatalogStub)

        let addBtn = element("bookmark.addBook")
        XCTAssertTrue(addBtn.waitForExistence(timeout: uiTimeout))
        addBtn.tap()

        let barcodeBtn = element("register.barcode")
        if barcodeBtn.waitForExistence(timeout: uiTimeout) {
            barcodeBtn.tap()
        }

        sendBarcode("9784101000022", supplemental: "1920193006001")
        sendBarcode("9784101000022")
        sendBarcode("9784101000015")
        sendBarcode("9784101000039")
        sendBarcode("4901234567894")

        let row2 = element("scan.row.9784101000022")
        let row3 = element("scan.row.9784101000039")
        XCTAssertTrue(row2.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(row3.waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(matchingCount("scan.row.9784101000015"), 0)
        XCTAssertEqual(matchingCount("scan.row.4901234567894"), 0)
        XCTAssertTrue(row2.label.contains("文庫"))

        let stateStr = readHookString("hook.state")
        XCTAssertTrue(stateStr.contains("haptic=2") || stateStr.contains("\"haptic\":2"))
        XCTAssertTrue(stateStr.contains("scan.duplicate:1"))

        element("scan.commit").tap()

        let store = readHookJSON("hook.store")
        let books = store["books"] as? [[String: Any]] ?? []
        XCTAssertEqual(books.count, 3)

        let i2Book = books.first { ($0["isbn"] as? String) == "9784101000022" }
        let i3Book = books.first { ($0["isbn"] as? String) == "9784101000039" }
        let i1Book = books.first { ($0["isbn"] as? String) == "9784101000015" }
        XCTAssertEqual(i2Book?["status"] as? String, "tsundoku")
        XCTAssertEqual(i2Book?["label"] as? String, "文庫")
        XCTAssertEqual(i3Book?["status"] as? String, "tsundoku")
        XCTAssertEqual(i1Book?["status"] as? String, "current")

        relaunchPreservingStore()
        let booksAfter = (readHookJSON("hook.store")["books"] as? [[String: Any]]) ?? []
        XCTAssertEqual(booksAfter.count, 3)
    }

    func test_AC4_手入力欄で端末内書誌DBの候補から選んで保存できる() {
        resetAndLaunch(ndlStubJSON: defaultCatalogStub)

        element("bookmark.addBook").tap()
        let manualBtn = element("register.manual")
        if manualBtn.waitForExistence(timeout: uiTimeout) {
            manualBtn.tap()
        }

        let titleField = element("manual.title")
        XCTAssertTrue(titleField.waitForExistence(timeout: uiTimeout))
        titleField.tap()
        titleField.typeText("人間失格")

        let row4 = element("search.row.9784101000046")
        let row5 = element("search.row.9784040000053")
        let row6 = element("search.row.9784480000064")
        XCTAssertTrue(row4.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(row5.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(row6.waitForExistence(timeout: uiTimeout))

        row5.tap()
        element("manual.save").tap()

        let store = readHookJSON("hook.store")
        let books = store["books"] as? [[String: Any]] ?? []
        XCTAssertEqual(books.count, 1)
        XCTAssertEqual(books.first?["isbn"] as? String, "9784040000053")
        XCTAssertEqual(books.first?["publisher"] as? String, "KADOKAWA")
        XCTAssertEqual(books.first?["label"] as? String, "角川文庫")
        XCTAssertEqual(books.first?["publishedYear"] as? Int, 1989)
        XCTAssertEqual(books.first?["status"] as? String, "current")

        relaunchPreservingStore()
        let booksAfter = (readHookJSON("hook.store")["books"] as? [[String: Any]]) ?? []
        XCTAssertEqual(booksAfter.first?["isbn"] as? String, "9784040000053")
    }

    func test_AC5_書誌DBの候補が0件でもそのまま手入力で保存できる() {
        resetAndLaunch(ndlStubJSON: defaultCatalogStub)

        element("bookmark.addBook").tap()
        let manualBtn = element("register.manual")
        if manualBtn.waitForExistence(timeout: uiTimeout) {
            manualBtn.tap()
        }

        let titleField = element("manual.title")
        XCTAssertTrue(titleField.waitForExistence(timeout: uiTimeout))
        titleField.tap()
        titleField.typeText("あいうえおかきくけこ")

        XCTAssertTrue(element("search.noResults").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(matchingCount("search.row"), 0)
        XCTAssertEqual(app.alerts.count, 0)

        element("manual.save").tap()

        let store = readHookJSON("hook.store")
        let books = store["books"] as? [[String: Any]] ?? []
        XCTAssertEqual(books.count, 1)
        XCTAssertEqual(books.first?["title"] as? String, "あいうえおかきくけこ")
        XCTAssertEqual(books.first?["status"] as? String, "current")

        relaunchPreservingStore()
        let booksAfter = (readHookJSON("hook.store")["books"] as? [[String: Any]]) ?? []
        XCTAssertEqual(booksAfter.first?["title"] as? String, "あいうえおかきくけこ")
    }

    func test_AC6_機内モードでも端末内書誌DBでバーコード登録が動く() {
        resetAndLaunch(offline: true, ndlStubJSON: defaultCatalogStub)

        element("bookmark.addBook").tap()
        let barcodeBtn = element("register.barcode")
        if barcodeBtn.waitForExistence(timeout: uiTimeout) {
            barcodeBtn.tap()
        }

        sendBarcode("9784101000015")

        let row = element("scan.row.9784101000015")
        XCTAssertTrue(row.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(row.label.contains("こころ"))
        XCTAssertEqual(app.alerts.count, 0)

        element("scan.commit").tap()

        let store = readHookJSON("hook.store")
        let books = store["books"] as? [[String: Any]] ?? []
        XCTAssertEqual(books.count, 1)
        XCTAssertEqual(books.first?["status"] as? String, "current")

        let outbound = readHookJSON("hook.outbound")
        let requests = outbound["requests"] as? [Any] ?? []
        XCTAssertEqual(requests.count, 0)
    }

    func test_AC7_候補を選ばずに前後空白を除いて積読に保存できる() {
        let seed = """
        {
          "books": [
            {
              "id": "00000000-0000-4000-8000-000000000001",
              "title": "こころ",
              "author": "夏目漱石",
              "status": "current"
            }
          ]
        }
        """
        resetAndLaunch(seedJSON: seed, ndlStubJSON: defaultCatalogStub)

        element("bookmark.addBook").tap()
        let manualBtn = element("register.manual")
        if manualBtn.waitForExistence(timeout: uiTimeout) {
            manualBtn.tap()
        }

        let titleField = element("manual.title")
        XCTAssertTrue(titleField.waitForExistence(timeout: uiTimeout))
        titleField.tap()
        titleField.typeText(" 羅生門　")

        let authorField = element("manual.author")
        XCTAssertTrue(authorField.waitForExistence(timeout: uiTimeout))
        authorField.tap()
        authorField.typeText("芥川龍之介")

        element("manual.save").tap()

        let store = readHookJSON("hook.store")
        let books = store["books"] as? [[String: Any]] ?? []
        XCTAssertEqual(books.count, 2)
        let added = books.first { ($0["title"] as? String) == "羅生門" }
        XCTAssertNotNil(added)
        XCTAssertEqual(added?["author"] as? String, "芥川龍之介")
        XCTAssertEqual((added?["isbn"] as? String) ?? "", "")
        XCTAssertEqual((added?["publisher"] as? String) ?? "", "")
        XCTAssertEqual(added?["status"] as? String, "tsundoku")

        relaunchPreservingStore()
        let booksAfter = (readHookJSON("hook.store")["books"] as? [[String: Any]]) ?? []
        XCTAssertEqual(booksAfter.count, 2)
        let addedAfter = booksAfter.first { ($0["title"] as? String) == "羅生門" }
        XCTAssertEqual(addedAfter?["status"] as? String, "tsundoku")
    }

    func test_AC8_手入力の書名と著者の文字数境界を検証する() {
        resetAndLaunch(ndlStubJSON: defaultCatalogStub)

        element("bookmark.addBook").tap()
        let manualBtn = element("register.manual")
        if manualBtn.waitForExistence(timeout: uiTimeout) {
            manualBtn.tap()
        }

        let titleField = element("manual.title")
        let authorField = element("manual.author")
        let saveBtn = element("manual.save")
        XCTAssertTrue(titleField.waitForExistence(timeout: uiTimeout))

        // (1) 書名空
        saveBtn.tap()
        XCTAssertTrue(element("book.title.invalid").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(((readHookJSON("hook.store")["books"] as? [Any]) ?? []).count, 0)

        // (2) 全角空白のみ
        titleField.tap()
        titleField.typeText("　　")
        saveBtn.tap()
        XCTAssertTrue(element("book.title.invalid").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(((readHookJSON("hook.store")["books"] as? [Any]) ?? []).count, 0)

        // (3) 絵文字込み101字
        resetAndLaunch(ndlStubJSON: defaultCatalogStub)
        element("bookmark.addBook").tap()
        if element("register.manual").waitForExistence(timeout: uiTimeout) {
            element("register.manual").tap()
        }
        let str100 = String(repeating: "あ", count: 100)
        element("manual.title").tap()
        element("manual.title").typeText(str100 + "📕")
        element("manual.save").tap()
        XCTAssertTrue(element("book.title.invalid").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(((readHookJSON("hook.store")["books"] as? [Any]) ?? []).count, 0)

        // (4) 書名100字 + 著者101字
        resetAndLaunch(ndlStubJSON: defaultCatalogStub)
        element("bookmark.addBook").tap()
        if element("register.manual").waitForExistence(timeout: uiTimeout) {
            element("register.manual").tap()
        }
        element("manual.title").tap()
        element("manual.title").typeText(str100)
        element("manual.author").tap()
        element("manual.author").typeText(str100 + "あ")
        element("manual.save").tap()
        XCTAssertTrue(element("book.author.invalid").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(((readHookJSON("hook.store")["books"] as? [Any]) ?? []).count, 0)

        // (5) 書名100字 + 著者100字
        resetAndLaunch(ndlStubJSON: defaultCatalogStub)
        element("bookmark.addBook").tap()
        if element("register.manual").waitForExistence(timeout: uiTimeout) {
            element("register.manual").tap()
        }
        element("manual.title").tap()
        element("manual.title").typeText(str100)
        element("manual.author").tap()
        element("manual.author").typeText(str100)
        element("manual.save").tap()
        let books5 = (readHookJSON("hook.store")["books"] as? [[String: Any]]) ?? []
        XCTAssertEqual(books5.count, 1)
        XCTAssertEqual((books5.first?["title"] as? String)?.count, 100)
        XCTAssertEqual((books5.first?["author"] as? String)?.count, 100)

        // (6) 書名「羅生門」 + 著者空
        resetAndLaunch(ndlStubJSON: defaultCatalogStub)
        element("bookmark.addBook").tap()
        if element("register.manual").waitForExistence(timeout: uiTimeout) {
            element("register.manual").tap()
        }
        element("manual.title").tap()
        element("manual.title").typeText("羅生門")
        element("manual.save").tap()
        let books6 = (readHookJSON("hook.store")["books"] as? [[String: Any]]) ?? []
        XCTAssertEqual(books6.count, 1)
        XCTAssertEqual(books6.first?["title"] as? String, "羅生門")
        XCTAssertEqual((books6.first?["author"] as? String) ?? "", "")
    }

    func test_AC9_書誌DB未取得時にその場で書名を入れて追加できる() {
        let notDownloadedStub = """
        {
          "status": "notDownloaded",
          "books": []
        }
        """
        resetAndLaunch(ndlStubJSON: notDownloadedStub)

        element("bookmark.addBook").tap()
        let barcodeBtn = element("register.barcode")
        if barcodeBtn.waitForExistence(timeout: uiTimeout) {
            barcodeBtn.tap()
        }

        sendBarcode("9784101000015")

        XCTAssertTrue(element("scan.dbNotReady").waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(element("scan.row.captureCover").waitForExistence(timeout: uiTimeout))
        let editTitle = element("scan.row.editTitle")
        XCTAssertTrue(editTitle.waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(app.alerts.count, 0)

        editTitle.tap()
        editTitle.typeText("こころ")
        element("scan.commit").tap()

        let store = readHookJSON("hook.store")
        let books = store["books"] as? [[String: Any]] ?? []
        XCTAssertEqual(books.count, 1)
        XCTAssertEqual(books.first?["title"] as? String, "こころ")
        XCTAssertEqual(books.first?["isbn"] as? String, "9784101000015")
        XCTAssertEqual(books.first?["status"] as? String, "current")

        let outbound = readHookJSON("hook.outbound")
        XCTAssertEqual(((outbound["requests"] as? [Any]) ?? []).count, 0)
    }

    func test_AC10_書誌DBにないISBNをその場で書名入力して追加できる() {
        let emptyStub = """
        {
          "status": "ready",
          "books": []
        }
        """
        resetAndLaunch(ndlStubJSON: emptyStub)

        element("bookmark.addBook").tap()
        let barcodeBtn = element("register.barcode")
        if barcodeBtn.waitForExistence(timeout: uiTimeout) {
            barcodeBtn.tap()
        }

        sendBarcode("9784101000046")

        XCTAssertTrue(element("scan.notFound").waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(element("scan.row.captureCover").waitForExistence(timeout: uiTimeout))
        let editTitle = element("scan.row.editTitle")
        XCTAssertTrue(editTitle.waitForExistence(timeout: uiTimeout))

        editTitle.tap()
        editTitle.typeText("青を売る")
        element("scan.commit").tap()

        let store = readHookJSON("hook.store")
        let books = store["books"] as? [[String: Any]] ?? []
        XCTAssertEqual(books.count, 1)
        XCTAssertEqual(books.first?["title"] as? String, "青を売る")
        XCTAssertEqual(books.first?["isbn"] as? String, "9784101000046")
        XCTAssertEqual(books.first?["status"] as? String, "current")

        let outbound = readHookJSON("hook.outbound")
        XCTAssertEqual(((outbound["requests"] as? [Any]) ?? []).count, 0)
    }

    func test_AC11_未収録ISBNとCコードから岩波書店と文庫を補完する() {
        let emptyStub = """
        {
          "status": "ready",
          "books": []
        }
        """
        resetAndLaunch(ndlStubJSON: emptyStub)

        element("bookmark.addBook").tap()
        let barcodeBtn = element("register.barcode")
        if barcodeBtn.waitForExistence(timeout: uiTimeout) {
            barcodeBtn.tap()
        }

        sendBarcode("9784003101018", supplemental: "1920193006001")

        let row = element("scan.row.9784003101018")
        XCTAssertTrue(row.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(row.label.contains("岩波書店"))
        XCTAssertTrue(row.label.contains("文庫"))

        let editTitle = element("scan.row.editTitle")
        XCTAssertTrue(editTitle.waitForExistence(timeout: uiTimeout))
        editTitle.tap()
        editTitle.typeText("こころ")
        element("scan.commit").tap()

        let store = readHookJSON("hook.store")
        let books = store["books"] as? [[String: Any]] ?? []
        XCTAssertEqual(books.count, 1)
        XCTAssertEqual(books.first?["title"] as? String, "こころ")
        XCTAssertEqual(books.first?["publisher"] as? String, "岩波書店")
        XCTAssertEqual(books.first?["label"] as? String, "文庫")
        XCTAssertEqual(books.first?["isbn"] as? String, "9784003101018")
    }

    func test_AC12_カメラ拒否時に設定とスクショと手入力の導線が出る() {
        resetAndLaunch(camera: "denied", ndlStubJSON: defaultCatalogStub)

        element("bookmark.addBook").tap()
        let barcodeBtn = element("register.barcode")
        if barcodeBtn.waitForExistence(timeout: uiTimeout) {
            barcodeBtn.tap()
        }

        XCTAssertTrue(element("camera.denied").waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(element("camera.openSettings").waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(element("register.screenshot").waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(element("register.manual").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(matchingCount("scan.camera"), 0)

        let store = readHookJSON("hook.store")
        let books = store["books"] as? [[String: Any]] ?? []
        XCTAssertEqual(books.count, 0)
    }

    func test_AC92_NDL書誌の著者名から生没年や役割語や2人目以降を除いて整形する() {
        let ndlRawStub = """
        {
          "status": "ready",
          "books": [
            {
              "isbn": "9784101000015",
              "title": "本1",
              "rawCreator": "伴名, 練, 1988- 著 ; 解説者 解説"
            },
            {
              "isbn": "9784101000022",
              "title": "本2",
              "rawCreator": "遠藤, 周作, 1923-1996 作"
            },
            {
              "isbn": "9784101000039",
              "title": "本3",
              "rawCreator": "幸田, 文, 1904-1990 著"
            },
            {
              "isbn": "9784101000046",
              "title": "本4",
              "rawCreator": "坂崎, かおる (小説家) 著"
            },
            {
              "isbn": "9784040000053",
              "title": "本5",
              "rawCreator": "渡邊, 朋子 (ピアニスト) 編著"
            },
            {
              "isbn": "9784480000064",
              "title": "本6",
              "rawCreator": "中林, くみこ 監修"
            }
          ]
        }
        """
        resetAndLaunch(ndlStubJSON: ndlRawStub)

        element("bookmark.addBook").tap()
        let barcodeBtn = element("register.barcode")
        if barcodeBtn.waitForExistence(timeout: uiTimeout) {
            barcodeBtn.tap()
        }

        let isbns = [
            "9784101000015",
            "9784101000022",
            "9784101000039",
            "9784101000046",
            "9784040000053",
            "9784480000064"
        ]
        for isbn in isbns {
            sendBarcode(isbn)
        }

        XCTAssertTrue(element("scan.row.9784480000064").waitForExistence(timeout: uiTimeout))
        element("scan.commit").tap()

        let store = readHookJSON("hook.store")
        let books = store["books"] as? [[String: Any]] ?? []
        XCTAssertEqual(books.count, 6)

        let expected: [String: String] = [
            "9784101000015": "伴名練",
            "9784101000022": "遠藤周作",
            "9784101000039": "幸田文",
            "9784101000046": "坂崎かおる",
            "9784040000053": "渡邊朋子",
            "9784480000064": "中林くみこ"
        ]
        for (isbn, author) in expected {
            let matched = books.first { ($0["isbn"] as? String) == isbn }
            XCTAssertEqual(matched?["author"] as? String, author, "Author mismatch for \(isbn)")
        }
    }

    func test_AC137_表紙写真とスクリーンショットから2タップで書名と著者を選んで登録できる() {
        let ocrStub = """
        {
          "cover": {
            "lines": ["新潮文庫", "こころ", "夏目漱石"]
          }
        }
        """
        // (1) register.cover
        resetAndLaunch(ocrJSON: ocrStub, ndlStubJSON: defaultCatalogStub)
        element("bookmark.addBook").tap()
        let coverBtn = element("register.cover")
        XCTAssertTrue(coverBtn.waitForExistence(timeout: uiTimeout))
        coverBtn.tap()

        let line2 = element("cover.ocr.line.2")
        let line3 = element("cover.ocr.line.3")
        XCTAssertTrue(line2.waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(line3.waitForExistence(timeout: uiTimeout))

        line2.tap()
        line3.tap()
        element("cover.save").tap()

        let store1 = readHookJSON("hook.store")
        let books1 = store1["books"] as? [[String: Any]] ?? []
        XCTAssertEqual(books1.count, 1)
        XCTAssertEqual(books1.first?["title"] as? String, "こころ")
        XCTAssertEqual(books1.first?["author"] as? String, "夏目漱石")
        XCTAssertEqual(books1.first?["status"] as? String, "current")

        let audit1 = readHookJSON("hook.mediaAudit")
        XCTAssertEqual(audit1["savedImageFileCount"] as? Int, 0)
        XCTAssertEqual(audit1["photoLibraryWriteCount"] as? Int, 0)

        // (2) register.screenshot
        resetAndLaunch(ocrJSON: ocrStub, ndlStubJSON: defaultCatalogStub)
        element("bookmark.addBook").tap()
        let screenshotBtn = element("register.screenshot")
        XCTAssertTrue(screenshotBtn.waitForExistence(timeout: uiTimeout))
        screenshotBtn.tap()

        XCTAssertTrue(element("cover.ocr.line.2").waitForExistence(timeout: uiTimeout))
        element("cover.ocr.line.2").tap()
        element("cover.ocr.line.3").tap()
        element("cover.save").tap()

        let store2 = readHookJSON("hook.store")
        let books2 = store2["books"] as? [[String: Any]] ?? []
        XCTAssertEqual(books2.count, 1)
        XCTAssertEqual(books2.first?["title"] as? String, "こころ")
        XCTAssertEqual(books2.first?["author"] as? String, "夏目漱石")

        let audit2 = readHookJSON("hook.mediaAudit")
        XCTAssertEqual(audit2["savedImageFileCount"] as? Int, 0)
        XCTAssertEqual(audit2["photoLibraryWriteCount"] as? Int, 0)
    }

    func test_AC138_本棚の1枚の写真から複数の背表紙を選んで一括で積読に加え1件一致の書誌を補う() {
        let seed = """
        {
          "books": [
            {
              "id": "00000000-0000-4000-8000-000000000001",
              "title": "吾輩は猫である",
              "author": "夏目漱石",
              "status": "current"
            }
          ]
        }
        """
        let stub = """
        {
          "status": "ready",
          "books": [
            {
              "isbn": "9784101000015",
              "title": "こころ",
              "author": "夏目漱石",
              "publisher": "新潮社",
              "label": "新潮文庫",
              "publishedYear": 2004
            },
            {
              "isbn": "9784003101018",
              "title": "こころ",
              "author": "夏目漱石",
              "publisher": "岩波書店",
              "label": "岩波文庫",
              "publishedYear": 1995
            },
            {
              "isbn": "9784101000039",
              "title": "羅生門",
              "author": "芥川龍之介",
              "publisher": "新潮社",
              "label": "新潮文庫",
              "publishedYear": 2005
            }
          ]
        }
        """
        let ocrStub = """
        {
          "bookshelf": {
            "spines": ["こころ", "人間失格", "羅生門", "檸檬"]
          }
        }
        """
        resetAndLaunch(seedJSON: seed, ocrJSON: ocrStub, ndlStubJSON: stub)

        element("bookmark.addBook").tap()
        let shelfScanBtn = element("register.bookshelf")
        XCTAssertTrue(shelfScanBtn.waitForExistence(timeout: uiTimeout))
        shelfScanBtn.tap()

        let spine1 = element("bookshelf.row.1")
        let spine2 = element("bookshelf.row.2")
        let spine3 = element("bookshelf.row.3")
        XCTAssertTrue(spine1.waitForExistence(timeout: uiTimeout))
        spine1.tap()
        spine2.tap()
        spine3.tap()

        element("bookshelf.commit").tap()

        let store = readHookJSON("hook.store")
        let books = store["books"] as? [[String: Any]] ?? []
        XCTAssertEqual(books.count, 4)

        let rashomon = books.first { ($0["title"] as? String) == "羅生門" }
        XCTAssertEqual(rashomon?["status"] as? String, "tsundoku")
        XCTAssertEqual(rashomon?["author"] as? String, "芥川龍之介")
        XCTAssertEqual(rashomon?["publisher"] as? String, "新潮社")
        XCTAssertEqual(rashomon?["isbn"] as? String, "9784101000039")

        let kokoro = books.first { ($0["title"] as? String) == "こころ" }
        XCTAssertEqual(kokoro?["status"] as? String, "tsundoku")
        XCTAssertEqual((kokoro?["author"] as? String) ?? "", "")

        let audit = readHookJSON("hook.mediaAudit")
        XCTAssertEqual(audit["savedImageFileCount"] as? Int, 0)
    }

    func test_AC139_書名をあとでにして今すぐ読み始められ名無しの本は1冊に制限される() {
        resetAndLaunch(
            now: "2026-10-18T21:00:00+09:00",
            timezone: "Asia/Tokyo",
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76"]
        )

        element("bookmark.addBook").tap()
        let laterBtn = element("register.later")
        XCTAssertTrue(laterBtn.waitForExistence(timeout: uiTimeout))
        laterBtn.tap()

        let endBtn = element("reading.end")
        XCTAssertTrue(endBtn.waitForExistence(timeout: uiTimeout))

        let stateStr = readHookString("hook.state")
        XCTAssertTrue(stateStr.contains("state=reading") || stateStr.contains("\"state\":\"reading\""))

        advanceClock(seconds: 1200)
        endBtn.tap()

        let pageOnlyBtn = element("mark.pageOnly")
        XCTAssertTrue(pageOnlyBtn.waitForExistence(timeout: uiTimeout))
        pageOnlyBtn.tap()

        let pageField = element("mark.pageField")
        XCTAssertTrue(pageField.waitForExistence(timeout: uiTimeout))
        pageField.tap()
        pageField.typeText("45")
        element("mark.save").tap()

        let closeBtn = element("result.close")
        if closeBtn.waitForExistence(timeout: uiTimeout) {
            closeBtn.tap()
        }

        XCTAssertTrue(element("bookmark.setBookTitle").waitForExistence(timeout: uiTimeout))

        let store = readHookJSON("hook.store")
        let books = store["books"] as? [[String: Any]] ?? []
        XCTAssertEqual(books.count, 1)
        XCTAssertEqual(books.first?["isTitlePending"] as? Bool, true)
        XCTAssertEqual(books.first?["page"] as? Int, 45)
        let records = store["records"] as? [[String: Any]] ?? []
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?["minutes"] as? Int, 20)

        element("bookmark.addBook").tap()
        XCTAssertEqual(matchingCount("register.later"), 0)
    }

    func test_AC140_名無しの今の本に後からバーコードで書名と奥付を入れると記録を保って更新される() {
        let seed = """
        {
          "books": [
            {
              "id": "00000000-0000-4000-8000-000000000001",
              "title": "",
              "isTitlePending": true,
              "status": "current",
              "progressUnit": "page",
              "page": 45
            }
          ],
          "records": [
            {
              "id": "00000000-0000-4000-9000-000000000001",
              "bookId": "00000000-0000-4000-8000-000000000001",
              "startedAt": "2026-10-18T21:00:00+09:00",
              "endedAt": "2026-10-18T21:20:00+09:00",
              "nightDate": "2026-10-18",
              "minutes": 20,
              "entry": "app"
            }
          ]
        }
        """
        resetAndLaunch(
            seedJSON: seed,
            ndlStubJSON: defaultCatalogStub,
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76"]
        )

        let setTitleBtn = element("bookmark.setBookTitle")
        XCTAssertTrue(setTitleBtn.waitForExistence(timeout: uiTimeout))
        setTitleBtn.tap()

        let barcodeBtn = element("register.barcode")
        if barcodeBtn.waitForExistence(timeout: uiTimeout) {
            barcodeBtn.tap()
        }

        sendBarcode("9784101000015")
        XCTAssertTrue(element("scan.row.9784101000015").waitForExistence(timeout: uiTimeout))
        element("scan.commit").tap()

        XCTAssertEqual(matchingCount("bookmark.setBookTitle"), 0)

        let store = readHookJSON("hook.store")
        let books = store["books"] as? [[String: Any]] ?? []
        XCTAssertEqual(books.count, 1)
        let book = books.first
        XCTAssertEqual(book?["isTitlePending"] as? Bool, false)
        XCTAssertEqual(book?["title"] as? String, "こころ")
        XCTAssertEqual(book?["author"] as? String, "夏目漱石")
        XCTAssertEqual(book?["publisher"] as? String, "新潮社")
        XCTAssertEqual(book?["label"] as? String, "新潮文庫")
        XCTAssertEqual(book?["publishedYear"] as? Int, 2004)
        XCTAssertEqual(book?["isbn"] as? String, "9784101000015")
        XCTAssertEqual(book?["page"] as? Int, 45)

        let records = store["records"] as? [[String: Any]] ?? []
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?["minutes"] as? Int, 20)

        let widget = readHookJSON("hook.widget")
        let widgetRaw = "\(widget)"
        XCTAssertTrue(widgetRaw.contains("こころ"))
    }
}
