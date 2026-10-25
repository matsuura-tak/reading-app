import XCTest

final class SettingsStoreIntentsAcceptanceTests: AcceptanceTestBase {

    private var currentBookSeed: String {
        makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                author: "芥川龍之介",
                status: "current",
                progressUnit: "page",
                page: 61,
                lastLine: "ある日の暮方の事である。"
            )
        ])
    }

    func test_AC88_設定画面からプライバシーポリシーのURLを開く() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        element("toolbar.settings").tap()
        let policyBtn = element("settings.privacyPolicy")
        XCTAssertTrue(policyBtn.waitForExistence(timeout: uiTimeout))
        policyBtn.tap()

        let outbound = readHookJSON("hook.outbound")
        let opened = outbound["openedURLs"] as? [[String: Any]] ?? []
        XCTAssertEqual(opened.count, 1)
        let firstURL = opened.first?["url"] as? String ?? ""
        XCTAssertTrue(firstURL.hasPrefix("https://"))
    }

    func test_AC89_画面操作で入れた本と記録としおりと設定が再起動後もすべて残る() {
        resetAndLaunch(now: "2026-10-16T21:00:00+09:00", timezone: "Asia/Tokyo")

        // 1冊目（本E：こころ）を手入力で登録し、読み終えたにする
        element("bookmark.addBook").tap()
        let manualReg1 = element("register.manual")
        if manualReg1.waitForExistence(timeout: uiTimeout) {
            manualReg1.tap()
        }
        let title1 = element("manual.title")
        XCTAssertTrue(title1.waitForExistence(timeout: uiTimeout))
        title1.tap()
        title1.typeText("こころ")
        let author1 = element("manual.author")
        author1.tap()
        author1.typeText("夏目漱石")
        element("manual.save").tap()

        let finishBtn = element("bookmark.finish")
        XCTAssertTrue(finishBtn.waitForExistence(timeout: uiTimeout))
        finishBtn.tap()
        let finishClose = element("finish.close")
        if finishClose.waitForExistence(timeout: uiTimeout) {
            finishClose.tap()
        } else {
            navigateBackToBookmark()
        }

        // 2冊目（本A：羅生門）を手入力で登録（今の本になる）
        let addBtn2 = element("bookmark.addBook")
        if addBtn2.waitForExistence(timeout: uiTimeout) {
            addBtn2.tap()
        } else {
            element("toolbar.shelf").tap()
            element("shelf.addBook").tap()
        }
        let manualReg2 = element("register.manual")
        if manualReg2.waitForExistence(timeout: uiTimeout) {
            manualReg2.tap()
        }
        let title2 = element("manual.title")
        XCTAssertTrue(title2.waitForExistence(timeout: uiTimeout))
        title2.tap()
        title2.typeText("羅生門")
        let author2 = element("manual.author")
        author2.tap()
        author2.typeText("芥川龍之介")
        element("manual.save").tap()

        // 3冊目（本B：銀河鉄道の夜）を本棚から手入力で登録（積読になる）
        element("toolbar.shelf").tap()
        element("shelf.addBook").tap()
        let manualReg3 = element("register.manual")
        if manualReg3.waitForExistence(timeout: uiTimeout) {
            manualReg3.tap()
        }
        let title3 = element("manual.title")
        XCTAssertTrue(title3.waitForExistence(timeout: uiTimeout))
        title3.tap()
        title3.typeText("銀河鉄道の夜")
        let author3 = element("manual.author")
        author3.tap()
        author3.typeText("宮沢賢治")
        element("manual.save").tap()
        navigateBackToBookmark()

        // 読書記録1件目（15分）
        element("bookmark.start").tap()
        advanceClock(seconds: 900)
        element("reading.end").tap()
        element("mark.later").tap()
        element("result.close").tap()

        // 読書記録2件目（25分）
        advanceClock(seconds: 3600)
        element("bookmark.start").tap()
        advanceClock(seconds: 1500)
        element("reading.end").tap()
        element("mark.later").tap()
        element("result.close").tap()

        // 読書記録3件目（30分）＋しおり手入力保存（雨は、まだやまなかった。 / p.61）
        advanceClock(seconds: 3600)
        element("bookmark.start").tap()
        advanceClock(seconds: 1800)
        element("reading.end").tap()
        element("mark.manual").tap()
        let lineField = element("mark.lineField")
        XCTAssertTrue(lineField.waitForExistence(timeout: uiTimeout))
        lineField.tap()
        lineField.typeText("雨は、まだやまなかった。")
        let pageField = element("mark.pageField")
        pageField.tap()
        pageField.typeText("61")
        element("mark.save").tap()
        let guideClose = element("widgetGuide.close")
        if guideClose.waitForExistence(timeout: uiTimeout) {
            guideClose.tap()
        }
        let resClose = element("result.close")
        if resClose.waitForExistence(timeout: uiTimeout) {
            resClose.tap()
        }

        // 設定画面でトグル変更
        element("toolbar.settings").tap()
        let flipToggle = element("settings.flipToStart")
        XCTAssertTrue(flipToggle.waitForExistence(timeout: uiTimeout))
        flipToggle.tap()
        let hideToggle = element("settings.hideOnWidgets")
        hideToggle.tap()
        navigateBackToBookmark()

        // 再起動して永続化を検証
        relaunchPreservingStore(now: "2026-10-18T21:05:00+09:00", timezone: "Asia/Tokyo")

        XCTAssertEqual(readHookString("bookmark.title"), "羅生門")
        XCTAssertEqual(readHookString("bookmark.line"), "雨は、まだやまなかった。")
        XCTAssertEqual(readHookString("bookmark.page"), "p.61")

        let books = readStoreBooks()
        let records = readStoreRecords()
        let settings = readStoreSettings()
        XCTAssertEqual(books.count, 3)
        XCTAssertEqual(records.count, 3)
        let bookA = books.first { ($0["title"] as? String) == "羅生門" }
        let bookB = books.first { ($0["title"] as? String) == "銀河鉄道の夜" }
        let bookE = books.first { ($0["title"] as? String) == "こころ" }
        XCTAssertEqual(bookA?["status"] as? String, "current")
        XCTAssertEqual(bookA?["lastLine"] as? String, "雨は、まだやまなかった。")
        XCTAssertEqual(bookA?["page"] as? Int, 61)
        XCTAssertEqual(bookB?["status"] as? String, "tsundoku")
        XCTAssertEqual(bookE?["status"] as? String, "finished")
        XCTAssertEqual(settings["flipToStartEnabled"] as? Bool, false)
        XCTAssertEqual(settings["hideOnWidgets"] as? Bool, true)
    }

    func test_AC90_起動時の保存先読込失敗でエラーを出し再起動で元のデータが戻る() {
        let seed = makeSeedJSON(
            books: [
                makeSeedBook(id: uuidBookA, title: "羅生門", author: "芥川龍之介", status: "current"),
                makeSeedBook(id: uuidBookB, title: "こころ", author: "夏目漱石", status: "tsundoku")
            ],
            records: [
                makeSeedRecord(id: makeRecordUUID(1), bookId: uuidBookA, minutes: 10, nightDate: "2026-10-16"),
                makeSeedRecord(id: makeRecordUUID(2), bookId: uuidBookA, minutes: 20, nightDate: "2026-10-17"),
                makeSeedRecord(id: makeRecordUUID(3), bookId: uuidBookA, minutes: 30, nightDate: "2026-10-18")
            ]
        )
        resetAndLaunch(seedJSON: seed, now: "2026-10-18T21:00:00+09:00", failSave: "store.load:1")
        XCTAssertTrue(element("store.load.error").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(matchingCount("bookmark.start"), 0)
        XCTAssertEqual(matchingCount("bookmark.addBook"), 0)

        relaunchPreservingStore(now: "2026-10-18T21:01:00+09:00")
        XCTAssertEqual(readStoreBooks().count, 2)
        XCTAssertEqual(readStoreRecords().count, 3)
    }

    func test_AC91_7種類の保存失敗時にエラーが出て変更前のデータが保たれる() {
        let baseSeed = makeSeedJSON(
            books: [
                makeSeedBook(
                    id: uuidBookA,
                    title: "羅生門",
                    author: "芥川龍之介",
                    status: "current",
                    page: 43,
                    lastLine: "雨は、まだやまなかった。"
                )
            ],
            records: [
                makeSeedRecord(id: makeRecordUUID(1), bookId: uuidBookA, minutes: 20, nightDate: "2026-10-16"),
                makeSeedRecord(id: makeRecordUUID(2), bookId: uuidBookA, minutes: 30, nightDate: "2026-10-17")
            ]
        )

        // (1) book.add:1
        resetAndLaunch(seedJSON: baseSeed, now: "2026-10-18T21:00:00+09:00", failSave: "book.add:1")
        element("toolbar.shelf").tap()
        element("shelf.addBook").tap()
        let regManual = element("register.manual")
        if regManual.waitForExistence(timeout: uiTimeout) {
            regManual.tap()
        }
        let mt = element("manual.title")
        XCTAssertTrue(mt.waitForExistence(timeout: uiTimeout))
        mt.tap()
        mt.typeText("新しい本")
        element("manual.save").tap()
        XCTAssertTrue(element("common.save.error").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readStoreBooks().count, 1)
        relaunchPreservingStore()
        XCTAssertEqual(readStoreBooks().count, 1)

        // (2) book.update:1
        resetAndLaunch(seedJSON: baseSeed, now: "2026-10-18T21:00:00+09:00", failSave: "book.update:1")
        element("toolbar.shelf").tap()
        element("shelf.row.\(uuidBookA)").tap()
        element("book.edit").tap()
        let et = element("book.edit.title")
        XCTAssertTrue(et.waitForExistence(timeout: uiTimeout))
        et.tap()
        et.typeText("変更後の書名")
        element("book.edit.save").tap()
        XCTAssertTrue(element("common.save.error").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readStoreBooks().first?["title"] as? String, "羅生門")
        relaunchPreservingStore()
        XCTAssertEqual(readStoreBooks().first?["title"] as? String, "羅生門")

        // (3) book.delete:1
        resetAndLaunch(seedJSON: baseSeed, now: "2026-10-18T21:00:00+09:00", failSave: "book.delete:1")
        element("toolbar.shelf").tap()
        element("shelf.row.\(uuidBookA)").tap()
        element("book.delete").tap()
        let confirmDelBook = element("book.delete.confirmButton")
        if confirmDelBook.waitForExistence(timeout: uiTimeout) {
            confirmDelBook.tap()
        }
        XCTAssertTrue(element("common.save.error").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readStoreBooks().count, 1)
        XCTAssertEqual(readStoreRecords().count, 2)
        relaunchPreservingStore()
        XCTAssertEqual(readStoreBooks().count, 1)

        // (4) book.status:1
        resetAndLaunch(seedJSON: baseSeed, now: "2026-10-18T21:00:00+09:00", failSave: "book.status:1")
        element("bookmark.finish").tap()
        XCTAssertTrue(element("common.save.error").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readStoreBooks().first?["status"] as? String, "current")
        relaunchPreservingStore()
        XCTAssertEqual(readStoreBooks().first?["status"] as? String, "current")

        // (5) record.update:1
        resetAndLaunch(seedJSON: baseSeed, now: "2026-10-18T21:00:00+09:00", failSave: "record.update:1")
        element("toolbar.shelf").tap()
        element("shelf.row.\(uuidBookA)").tap()
        element("book.record.row.\(makeRecordUUID(1))").tap()
        let mf = element("record.minutesField")
        XCTAssertTrue(mf.waitForExistence(timeout: uiTimeout))
        mf.tap()
        mf.typeText("45")
        element("record.save").tap()
        XCTAssertTrue(element("common.save.error").waitForExistence(timeout: uiTimeout))
        let rec1 = readStoreRecords().first { ($0["id"] as? String) == makeRecordUUID(1) }
        XCTAssertEqual(rec1?["minutes"] as? Int, 20)
        relaunchPreservingStore()
        let rec1After = readStoreRecords().first { ($0["id"] as? String) == makeRecordUUID(1) }
        XCTAssertEqual(rec1After?["minutes"] as? Int, 20)

        // (6) record.delete:1
        resetAndLaunch(seedJSON: baseSeed, now: "2026-10-18T21:00:00+09:00", failSave: "record.delete:1")
        element("toolbar.shelf").tap()
        element("shelf.row.\(uuidBookA)").tap()
        element("book.record.row.\(makeRecordUUID(1))").tap()
        element("record.delete").tap()
        let confirmDelRec = element("record.delete.confirmButton")
        if confirmDelRec.waitForExistence(timeout: uiTimeout) {
            confirmDelRec.tap()
        }
        XCTAssertTrue(element("common.save.error").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readStoreRecords().count, 2)
        relaunchPreservingStore()
        XCTAssertEqual(readStoreRecords().count, 2)

        // (7) mark.save:1
        resetAndLaunch(seedJSON: baseSeed, now: "2026-10-18T21:00:00+09:00", failSave: "mark.save:1")
        element("bookmark.setMark").tap()
        element("mark.pageOnly").tap()
        let pf = element("mark.pageField")
        XCTAssertTrue(pf.waitForExistence(timeout: uiTimeout))
        pf.tap()
        pf.typeText("80")
        element("mark.save").tap()
        XCTAssertTrue(element("common.save.error").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readStoreBooks().first?["page"] as? Int, 43)
        XCTAssertEqual(readStoreBooks().first?["lastLine"] as? String, "雨は、まだやまなかった。")
        relaunchPreservingStore()
        XCTAssertEqual(readStoreBooks().first?["page"] as? Int, 43)
    }

    func test_AC93_設定画面にNDLの3条件とCCBYリンクが出てしおり画面と読書中画面には出ない() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        XCTAssertEqual(matchingCount("settings.dataSources"), 0)
        XCTAssertEqual(matchingCount("settings.dataSources.license"), 0)

        element("toolbar.settings").tap()
        let ds = element("settings.dataSources")
        XCTAssertTrue(ds.waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(matchingCount("settings.dataSources"), 1)
        let dsText = readHookString("settings.dataSources")
        XCTAssertTrue(dsText.contains("国立国会図書館"))
        XCTAssertTrue(dsText.contains("加工"))
        XCTAssertTrue(dsText.contains("API"))
        XCTAssertTrue(dsText.contains("CC BY 4.0"))
        XCTAssertTrue(dsText.contains("無関係"))

        let licenseBtn = element("settings.dataSources.license")
        XCTAssertTrue(licenseBtn.exists)
        XCTAssertEqual(matchingCount("settings.dataSources.license"), 1)
        licenseBtn.tap()

        let outbound = readHookJSON("hook.outbound")
        let opened = outbound["openedURLs"] as? [[String: Any]] ?? []
        XCTAssertEqual(opened.count, 1)
        let urlStr = opened.first?["url"] as? String ?? ""
        XCTAssertTrue(urlStr.hasPrefix("https://creativecommons.org/licenses/by/4.0/"))

        navigateBackToBookmark()
        XCTAssertEqual(matchingCount("settings.dataSources"), 0)
        XCTAssertEqual(matchingCount("settings.dataSources.license"), 0)

        element("bookmark.start").tap()
        XCTAssertTrue(element("reading.end").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(matchingCount("settings.dataSources"), 0)
        XCTAssertEqual(matchingCount("settings.dataSources.license"), 0)
    }

    func test_AC103_登録から読了カード共有まで外部HTTP通信が0件である() {
        let catalogStub = """
        {
          "stubVersion": 1,
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
              "isbn": "9784101000046",
              "title": "人間失格",
              "author": "太宰治",
              "publisher": "新潮社",
              "label": "新潮文庫",
              "publishedYear": 1952
            }
          ],
          "cooccurrences": []
        }
        """
        let ocrStub = #"{"page":{"columns":["下人の行方は、誰も知らない。"],"detectedPage":61}}"#
        resetAndLaunch(now: "2026-10-18T21:00:00+09:00", ocrJSON: ocrStub, ndlStubJSON: catalogStub)

        // (1) バーコード登録（S-8a）
        element("bookmark.addBook").tap()
        let barcodeBtn = element("register.barcode")
        if barcodeBtn.waitForExistence(timeout: uiTimeout) {
            barcodeBtn.tap()
        }
        sendBarcode("9784101000015")
        XCTAssertTrue(element("scan.row.9784101000015").waitForExistence(timeout: uiTimeout))
        element("scan.addToShelf").tap()

        // (2) 書名検索登録（S-8c）
        element("toolbar.shelf").tap()
        element("shelf.addBook").tap()
        let manualBtn = element("register.manual")
        if manualBtn.waitForExistence(timeout: uiTimeout) {
            manualBtn.tap()
        }
        let titleField = element("manual.title")
        XCTAssertTrue(titleField.waitForExistence(timeout: uiTimeout))
        titleField.tap()
        titleField.typeText("人間失格")
        let searchRow = element("search.row.9784101000046")
        if searchRow.waitForExistence(timeout: uiTimeout) {
            searchRow.tap()
        }
        element("manual.save").tap()
        navigateBackToBookmark()

        // (3) 読まずにしおり（S-1 -> S-3）
        element("bookmark.setMark").tap()
        element("mark.pageOnly").tap()
        let pf1 = element("mark.pageField")
        XCTAssertTrue(pf1.waitForExistence(timeout: uiTimeout))
        pf1.tap()
        pf1.typeText("12")
        element("mark.save").tap()
        let guideClose = element("widgetGuide.close")
        if guideClose.waitForExistence(timeout: uiTimeout) {
            guideClose.tap()
        }

        // (4) 読書開始 -> 終了 -> ページ写真OCRしおり保存（S-2 -> S-3c）
        element("bookmark.start").tap()
        advanceClock(seconds: 120)
        element("reading.end").tap()
        element("mark.photo").tap()
        XCTAssertTrue(element("mark.ocr.column.1").waitForExistence(timeout: uiTimeout))
        element("mark.save").tap()
        element("result.close").tap()

        // (5) 読了とカード共有（S-9）
        element("bookmark.finish").tap()
        element("finish.card.share").tap()

        let outbound = readHookJSON("hook.outbound")["requests"] as? [Any] ?? []
        XCTAssertEqual(outbound.count, 0)
    }

    func test_AC104_未購入でも毎晩の道と読み終えた画面に課金案内が出ない() {
        resetAndLaunch(
            seedJSON: currentBookSeed,
            now: "2026-10-18T21:00:00+09:00",
            storeKitJSON: #"{"initialPurchased":false}"#
        )
        XCTAssertEqual(matchingCount("store.buy"), 0)
        element("bookmark.start").tap()
        XCTAssertEqual(matchingCount("store.buy"), 0)
        advanceClock(seconds: 120)
        element("reading.end").tap()
        XCTAssertEqual(matchingCount("store.buy"), 0)
        element("mark.pageOnly").tap()
        let pf = element("mark.pageField")
        XCTAssertTrue(pf.waitForExistence(timeout: uiTimeout))
        pf.tap()
        pf.typeText("61")
        element("mark.save").tap()
        XCTAssertEqual(matchingCount("store.buy"), 0)
        element("result.close").tap()
        element("bookmark.finish").tap()
        XCTAssertEqual(matchingCount("store.buy"), 0)
        XCTAssertEqual(app.alerts.count, 0)
    }

    func test_AC105_鍵つき見た目を押すと見本と購入シートが出て閉じると標準に戻る() {
        resetAndLaunch(
            seedJSON: currentBookSeed,
            now: "2026-10-18T21:00:00+09:00",
            storeKitJSON: #"{"initialPurchased":false}"#
        )
        element("toolbar.settings").tap()
        element("settings.appearance").tap()
        element("appearance.kinari").tap()

        XCTAssertEqual(readHookString("store.preview"), "kinari")
        XCTAssertEqual(matchingCount("store.buy"), 1)
        XCTAssertEqual(matchingCount("store.restore"), 1)
        XCTAssertEqual(matchingCount("store.close"), 1)
        element("store.close").tap()

        let settings = readStoreSettings()
        XCTAssertEqual(settings["appearanceID"] as? String ?? "default", "default")
    }

    func test_AC106_購入すると見た目を選べてウィジェットと再起動後にも反映される() {
        resetAndLaunch(
            seedJSON: currentBookSeed,
            now: "2026-10-18T21:00:00+09:00",
            storeKitJSON: #"{"initialPurchased":false,"purchaseOutcome":"success"}"#,
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76"]
        )
        element("toolbar.settings").tap()
        element("settings.appearance").tap()
        element("appearance.kinari").tap()
        element("store.buy").tap()

        let settings = readStoreSettings()
        XCTAssertEqual(settings["isPlusPurchased"] as? Bool, true)
        XCTAssertEqual(settings["appearanceID"] as? String, "kinari")
        let skReadout = readHookJSON("hook.storekit")
        XCTAssertEqual(skReadout["isPlusPurchased"] as? Bool, true)

        let renders = readHookJSON("hook.widget")["renders"] as? [[String: Any]] ?? []
        XCTAssertEqual(renders.first?["appearanceID"] as? String, "kinari")

        relaunchPreservingStore(
            now: "2026-10-18T21:05:00+09:00",
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76"]
        )
        let afterSettings = readStoreSettings()
        XCTAssertEqual(afterSettings["isPlusPurchased"] as? Bool, true)
        XCTAssertEqual(afterSettings["appearanceID"] as? String, "kinari")
    }

    func test_AC107_購入の取りやめとエラー時に未購入と標準の見た目が保たれる() {
        resetAndLaunch(
            seedJSON: currentBookSeed,
            now: "2026-10-18T21:00:00+09:00",
            storeKitJSON: #"{"initialPurchased":false,"purchaseOutcome":"userCancelled"}"#
        )
        element("toolbar.settings").tap()
        element("settings.appearance").tap()
        element("appearance.kinari").tap()
        element("store.buy").tap()

        XCTAssertEqual(matchingCount("store.purchase.error"), 0)
        let s1 = readStoreSettings()
        XCTAssertEqual(s1["isPlusPurchased"] as? Bool ?? false, false)
        XCTAssertEqual(s1["appearanceID"] as? String ?? "default", "default")

        resetAndLaunch(
            seedJSON: currentBookSeed,
            now: "2026-10-18T21:00:00+09:00",
            storeKitJSON: #"{"initialPurchased":false,"purchaseOutcome":"error"}"#
        )
        element("toolbar.settings").tap()
        element("settings.appearance").tap()
        element("appearance.kinari").tap()
        element("store.buy").tap()
        XCTAssertEqual(matchingCount("store.purchase.error"), 1)
        let s2 = readStoreSettings()
        XCTAssertEqual(s2["isPlusPurchased"] as? Bool ?? false, false)
        XCTAssertEqual(s2["appearanceID"] as? String ?? "default", "default")
    }

    func test_AC108_購入の復元で履歴の有無に応じた結果と文言が出る() {
        resetAndLaunch(
            seedJSON: currentBookSeed,
            now: "2026-10-18T21:00:00+09:00",
            storeKitJSON: #"{"initialPurchased":false,"restoreOutcome":"hasEntitlement"}"#
        )
        element("toolbar.settings").tap()
        element("settings.restorePurchases").tap()
        XCTAssertEqual(matchingCount("store.restore.done"), 1)
        let s1 = readStoreSettings()
        XCTAssertEqual(s1["isPlusPurchased"] as? Bool, true)

        resetAndLaunch(
            seedJSON: currentBookSeed,
            now: "2026-10-18T21:00:00+09:00",
            storeKitJSON: #"{"initialPurchased":false,"restoreOutcome":"none"}"#
        )
        element("toolbar.settings").tap()
        element("settings.restorePurchases").tap()
        XCTAssertEqual(matchingCount("store.restore.none"), 1)
        let s2 = readStoreSettings()
        XCTAssertEqual(s2["isPlusPurchased"] as? Bool, false)
    }

    func test_AC109_決済不可の端末では購入ボタンを出さず案内を出す() {
        resetAndLaunch(
            seedJSON: currentBookSeed,
            now: "2026-10-18T21:00:00+09:00",
            storeKitJSON: #"{"canMakePayments":false}"#
        )
        element("toolbar.settings").tap()
        element("settings.appearance").tap()
        element("appearance.kinari").tap()

        XCTAssertEqual(matchingCount("store.buy"), 0)
        XCTAssertEqual(matchingCount("store.unavailable"), 1)
        XCTAssertEqual(readStoreSettings()["appearanceID"] as? String ?? "default", "default")
    }

    func test_AC110_オフラインで商品を読めないときは案内を出し読書は妨げない() {
        resetAndLaunch(
            seedJSON: currentBookSeed,
            now: "2026-10-18T21:00:00+09:00",
            offline: true,
            storeKitJSON: #"{"productLoadAvailable":false}"#
        )
        element("toolbar.settings").tap()
        element("settings.appearance").tap()
        element("appearance.kinari").tap()

        XCTAssertEqual(matchingCount("store.offline"), 1)
        XCTAssertEqual(matchingCount("store.buy"), 0)
        XCTAssertEqual(app.alerts.count, 0)

        let closeBtn = element("store.close")
        if closeBtn.exists {
            closeBtn.tap()
        }
        navigateBackToBookmark()
        XCTAssertTrue(element("bookmark.start").waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(element("bookmark.start").isEnabled)
    }

    func test_AC111_購入が返金されると前面復帰時に標準の見た目へ戻る() {
        let purchasedSeed = makeSeedJSON(
            books: [
                makeSeedBook(
                    id: uuidBookA,
                    title: "羅生門",
                    author: "芥川龍之介",
                    status: "current",
                    page: 61,
                    lastLine: "ある日の暮方の事である。"
                )
            ],
            settings: makeSeedSettings(appearanceID: "kinari", isPlusPurchased: true)
        )
        resetAndLaunch(
            seedJSON: purchasedSeed,
            now: "2026-10-18T21:00:00+09:00",
            storeKitJSON: #"{"initialPurchased":true}"#,
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76"]
        )
        triggerStoreRefund()
        XCUIDevice.shared.press(.home)
        app.activate()

        let settings = readStoreSettings()
        XCTAssertEqual(settings["isPlusPurchased"] as? Bool, false)
        XCTAssertEqual(settings["appearanceID"] as? String, "default")
        let renders = readHookJSON("hook.widget")["renders"] as? [[String: Any]] ?? []
        XCTAssertEqual(renders.first?["appearanceID"] as? String, "default")
    }

    func test_AC114_読み始めるインテントでアプリを開かず読書とLiveActivityが始まる() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T22:00:00+09:00", timezone: "Asia/Tokyo")
        runExternalIntent("StartReadingIntent")

        let intentHook = readHookJSON("hook.intents")
        let invocations = intentHook["invocations"] as? [[String: Any]] ?? []
        let firstInv = invocations.last ?? [:]
        XCTAssertEqual(firstInv["opensApp"] as? Bool, false)
        XCTAssertEqual(firstInv["dialogKey"] as? String, "intent.start.started")

        let state = readHookState()
        XCTAssertEqual(state["state"], "reading")
        let reqLat = Double((state["lat.intentStartRequest"] ?? "9999").split(separator: ",").first ?? "9999") ?? 9999.0
        XCTAssertLessThanOrEqual(reqLat, 500.0)

        let laHook = readHookJSON("hook.liveActivity")
        let activities = laHook["activities"] as? [[String: Any]] ?? []
        let activeLA = activities.first ?? [:]
        XCTAssertEqual(activeLA["state"] as? String, "reading")
        XCTAssertEqual(activeLA["title"] as? String, "羅生門")
        XCTAssertNil(activeLA["line"] as? String)
        XCTAssertNil(activeLA["progressText"] as? String)
        XCTAssertEqual(activeLA["endButtonIdentifier"] as? String, "liveActivity.end")
        XCTAssertEqual(activeLA["endIntentName"] as? String, "EndReadingFromActivityIntent")

        advanceClock(seconds: 1800)
        element("reading.end").tap()
        element("mark.later").tap()

        let records = readStoreRecords()
        XCTAssertEqual(records.first?["minutes"] as? Int, 30)
        XCTAssertEqual(readHookState()["entry"], "intent_start")
    }

    func test_AC115_どの状態から読み始めるインテントを動かしても二重に始まらない() {
        // (1) bookmark.start で読み始めて60秒後に StartReadingIntent
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T22:00:00+09:00", timezone: "Asia/Tokyo")
        element("bookmark.start").tap()
        advanceClock(seconds: 60)
        runExternalIntent("StartReadingIntent")

        XCTAssertEqual(readHookState()["state"], "reading")
        let invs1 = readHookJSON("hook.intents")["invocations"] as? [[String: Any]] ?? []
        XCTAssertEqual(invs1.last?["dialogKey"] as? String, "intent.start.alreadyReading")
        advanceClock(seconds: 120)
        element("reading.end").tap()
        element("mark.later").tap()
        XCTAssertEqual(readStoreRecords().count, 1)

        // (2) StartReadingIntent を動かし、10秒後にもう一度動かす
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T22:00:00+09:00", timezone: "Asia/Tokyo")
        runExternalIntent("StartReadingIntent")
        advanceClock(seconds: 10)
        runExternalIntent("StartReadingIntent")
        let invs2 = readHookJSON("hook.intents")["invocations"] as? [[String: Any]] ?? []
        XCTAssertEqual(invs2.last?["dialogKey"] as? String, "intent.start.alreadyReading")
        advanceClock(seconds: 120)
        element("reading.end").tap()
        element("mark.later").tap()
        XCTAssertEqual(readStoreRecords().count, 1)

        // (3) 予約した Live Activity が started 状態のときに StartReadingIntent
        let startedLA = """
        {
          "areActivitiesEnabled": true,
          "initialActivities": [
            {
              "id": "la-1",
              "kind": "scheduled",
              "state": "started",
              "scheduledFor": "2026-10-18T21:00:00+09:00",
              "staleDate": "2026-10-19T04:00:00+09:00",
              "url": "yomuma://open?entry=live_activity",
              "title": "羅生門",
              "line": "ある日の暮方の事である。",
              "progressText": "p.61",
              "startedAt": null,
              "endButtonIdentifier": null,
              "endButtonLabel": null,
              "endIntentName": null
            }
          ]
        }
        """
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T22:00:00+09:00", timezone: "Asia/Tokyo", liveActivityJSON: startedLA)
        runExternalIntent("StartReadingIntent")
        let laReqs3 = (readHookJSON("hook.liveActivity")["requests"] as? [[String: Any]] ?? []).filter { ($0["source"] as? String) == "intent" }
        XCTAssertEqual(laReqs3.count, 1)
        XCTAssertEqual(laReqs3.first?["kind"] as? String, "updateToReading")
        advanceClock(seconds: 120)
        element("reading.end").tap()
        element("mark.later").tap()
        XCTAssertEqual(readStoreRecords().count, 1)

        // (4) 20:30 で今夜 21:00 の予約が scheduled のときに StartReadingIntent
        let scheduledLA = """
        {
          "areActivitiesEnabled": true,
          "initialActivities": [
            {
              "id": "la-2",
              "kind": "scheduled",
              "state": "scheduled",
              "scheduledFor": "2026-10-18T21:00:00+09:00",
              "staleDate": "2026-10-19T04:00:00+09:00",
              "url": "yomuma://open?entry=live_activity",
              "title": "羅生門",
              "line": "ある日の暮方の事である。",
              "progressText": "p.61",
              "startedAt": null,
              "endButtonIdentifier": null,
              "endButtonLabel": null,
              "endIntentName": null
            }
          ]
        }
        """
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T20:30:00+09:00", timezone: "Asia/Tokyo", liveActivityJSON: scheduledLA)
        runExternalIntent("StartReadingIntent")
        let laReqs4 = (readHookJSON("hook.liveActivity")["requests"] as? [[String: Any]] ?? []).filter { ($0["source"] as? String) == "intent" }
        let kinds4 = laReqs4.compactMap { $0["kind"] as? String }
        XCTAssertTrue(kinds4.contains("cancel"))
        XCTAssertTrue(kinds4.contains("startImmediate"))
        advanceClock(seconds: 120)
        element("reading.end").tap()
        element("mark.later").tap()
        XCTAssertEqual(readStoreRecords().count, 1)

        // (5) しおり画面が前面のときに StartReadingIntent（1000ms 以内に S-2 が出る）
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T22:00:00+09:00", timezone: "Asia/Tokyo")
        XCTAssertTrue(element("bookmark.start").waitForExistence(timeout: uiTimeout))
        runExternalIntent("StartReadingIntent")
        XCTAssertTrue(element("reading.end").waitForExistence(timeout: uiTimeout))
        let fgLat = Double((readHookState()["lat.intentStartForeground"] ?? "9999").split(separator: ",").first ?? "9999") ?? 9999.0
        XCTAssertLessThanOrEqual(fgLat, 1000.0)
        advanceClock(seconds: 120)
        element("reading.end").tap()
        element("mark.later").tap()
        XCTAssertEqual(readStoreRecords().count, 1)
    }

    func test_AC116_LiveActivityの終えるで動いた時刻で記録し場面に応じて画面を出す() {
        // (1) 1800秒後、canContinueInForeground = true
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T22:00:00+09:00", timezone: "Asia/Tokyo")
        runExternalIntent("StartReadingIntent")
        advanceClock(seconds: 1800)
        runExternalIntent("EndReadingFromActivityIntent", canContinueInForeground: true)

        let inv1 = (readHookJSON("hook.intents")["invocations"] as? [[String: Any]] ?? []).last ?? [:]
        XCTAssertEqual(inv1["requestedForeground"] as? Bool, true)
        XCTAssertTrue(element("mark.later").waitForExistence(timeout: uiTimeout))
        element("mark.later").tap()

        let records1 = readStoreRecords()
        XCTAssertEqual(records1.count, 1)
        XCTAssertEqual(records1.first?["minutes"] as? Int, 30)
        XCTAssertEqual(records1.first?["nightDate"] as? String, "2026-10-18")
        XCTAssertEqual(readHookState()["entry"], "intent_start")

        // (2) 1800秒後、canContinueInForeground = false で終え、さらに3600秒後に前面に戻す
        resetAndLaunch(
            seedJSON: currentBookSeed,
            now: "2026-10-18T22:00:00+09:00",
            timezone: "Asia/Tokyo",
            intentJSON: makeIntentConfigJSON(canContinueInForeground: false)
        )
        runExternalIntent("StartReadingIntent")
        advanceClock(seconds: 1800)
        runExternalIntent("EndReadingFromActivityIntent", canContinueInForeground: false)
        advanceClock(seconds: 3600)
        app.activate()

        let inv2 = (readHookJSON("hook.intents")["invocations"] as? [[String: Any]] ?? []).last ?? [:]
        XCTAssertEqual(inv2["requestedForeground"] as? Bool, false)
        XCTAssertEqual(readHookState()["state"], "idle")
        let records2 = readStoreRecords()
        XCTAssertEqual(records2.count, 1)
        XCTAssertEqual(records2.first?["minutes"] as? Int, 30)

        // (3) 50秒後に終える（1分未満）
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T22:00:00+09:00", timezone: "Asia/Tokyo")
        runExternalIntent("StartReadingIntent")
        advanceClock(seconds: 50)
        runExternalIntent("EndReadingFromActivityIntent", canContinueInForeground: true)

        XCTAssertTrue(element("session.tooShort").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readStoreRecords().count, 0)
    }

    func test_AC117_今の本がないときに読み始めるインテントはアプリを開いて空状態を見せる() {
        // (1) 本0冊
        resetAndLaunch(seedJSON: makeSeedJSON(), now: "2026-10-18T21:00:00+09:00")
        runExternalIntent("StartReadingIntent")
        XCTAssertTrue(element("bookmark.empty.message").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readHookState()["state"], "idle")
        let inv1 = (readHookJSON("hook.intents")["invocations"] as? [[String: Any]] ?? []).last ?? [:]
        XCTAssertEqual(inv1["opensApp"] as? Bool, true)

        // (2) 積読だけで今の本なし
        let tsundokuOnly = makeSeedJSON(books: [
            makeSeedBook(id: uuidBookB, title: "こころ", author: "夏目漱石", status: "tsundoku")
        ])
        resetAndLaunch(seedJSON: tsundokuOnly, now: "2026-10-18T21:00:00+09:00")
        runExternalIntent("StartReadingIntent")
        XCTAssertTrue(element("bookmark.noCurrent.message").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readHookState()["state"], "idle")
        let inv2 = (readHookJSON("hook.intents")["invocations"] as? [[String: Any]] ?? []).last ?? [:]
        XCTAssertEqual(inv2["opensApp"] as? Bool, true)
    }

    func test_AC118_LiveActivityオフ時の読み始めるインテントは読書を開始し前面可ならS2を出す() {
        // (1) canContinueInForeground = true
        resetAndLaunch(
            seedJSON: currentBookSeed,
            now: "2026-10-18T21:00:00+09:00",
            liveActivityJSON: #"{"areActivitiesEnabled":false}"#
        )
        runExternalIntent("StartReadingIntent", canContinueInForeground: true)

        let inv1 = (readHookJSON("hook.intents")["invocations"] as? [[String: Any]] ?? []).last ?? [:]
        XCTAssertEqual(inv1["opensApp"] as? Bool, true)
        XCTAssertTrue(element("reading.end").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readHookState()["state"], "reading")
        XCTAssertEqual(app.alerts.count, 0)
        advanceClock(seconds: 120)
        element("reading.end").tap()
        element("mark.later").tap()
        XCTAssertEqual(readStoreRecords().first?["minutes"] as? Int, 2)
        XCTAssertEqual(readHookState()["entry"], "intent_start")

        // (2) canContinueInForeground = false
        resetAndLaunch(
            seedJSON: currentBookSeed,
            now: "2026-10-18T21:00:00+09:00",
            liveActivityJSON: #"{"areActivitiesEnabled":false}"#,
            intentJSON: makeIntentConfigJSON(canContinueInForeground: false)
        )
        runExternalIntent("StartReadingIntent", canContinueInForeground: false)
        advanceClock(seconds: 120)
        app.activate()

        let inv2 = (readHookJSON("hook.intents")["invocations"] as? [[String: Any]] ?? []).last ?? [:]
        XCTAssertEqual(inv2["requestedForeground"] as? Bool, false)
        XCTAssertEqual(readHookState()["state"], "reading")
        XCTAssertTrue(element("reading.end").waitForExistence(timeout: uiTimeout))
    }

    func test_AC119_読み始めるインテントで保存失敗時はエラーを返しLiveActivityを出さない() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", failSave: "session.start:1")
        runExternalIntent("StartReadingIntent")

        XCTAssertEqual(readHookState()["state"], "idle")
        let inv = (readHookJSON("hook.intents")["invocations"] as? [[String: Any]] ?? []).last ?? [:]
        XCTAssertEqual(inv["outcome"] as? String, "error")
        XCTAssertEqual(inv["dialogKey"] as? String, "session.start.error")
        let laReqs = (readHookJSON("hook.liveActivity")["requests"] as? [[String: Any]] ?? []).filter { ($0["source"] as? String) == "intent" }
        XCTAssertEqual(laReqs.count, 0)
        XCTAssertTrue(element("bookmark.start").isEnabled)
    }

    func test_AC120_隠す設定オンのとき読み始めるインテントのLiveActivityに書名を出さない() {
        let hideSeed = makeSeedJSON(
            books: [
                makeSeedBook(
                    id: uuidBookA,
                    title: "羅生門",
                    author: "芥川龍之介",
                    status: "current",
                    page: 61,
                    lastLine: "ある日の暮方の事である。"
                )
            ],
            settings: makeSeedSettings(hideOnWidgets: true)
        )
        resetAndLaunch(seedJSON: hideSeed, now: "2026-10-18T22:00:00+09:00")
        runExternalIntent("StartReadingIntent")

        let laHook = readHookJSON("hook.liveActivity")
        let activities = laHook["activities"] as? [[String: Any]] ?? []
        let activeLA = activities.first ?? [:]
        XCTAssertEqual(activeLA["title"] as? String, "しおり")
        XCTAssertNil(activeLA["line"] as? String)
        XCTAssertEqual(activeLA["endButtonIdentifier"] as? String, "liveActivity.end")
        let laRaw = readHookString("hook.liveActivity")
        XCTAssertFalse(laRaw.contains("羅生門"))
    }

    func test_AC121_どこまで読んだインテントは認証なしでページだけ答え一行と書名を出さない() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        runExternalIntent("WhereStoppedIntent")

        let inv = (readHookJSON("hook.intents")["invocations"] as? [[String: Any]] ?? []).last ?? [:]
        XCTAssertEqual(inv["opensApp"] as? Bool, false)
        XCTAssertEqual(inv["authenticationPolicy"] as? String, "alwaysAllowed")
        XCTAssertEqual(inv["dialogKey"] as? String, "intent.whereStopped.page")
        let spoken = inv["spokenText"] as? String ?? ""
        XCTAssertEqual(spoken, "61ページからです。")
        XCTAssertFalse(spoken.contains("羅生門"))
        XCTAssertFalse(spoken.contains("ある日の暮方の事である。"))
        let snippets = inv["snippetTexts"] as? [String] ?? []
        XCTAssertFalse(snippets.joined(separator: " ").contains("羅生門"))
        XCTAssertFalse(snippets.joined(separator: " ").contains("ある日の暮方の事である。"))
    }

    func test_AC122_どこまで読んだインテントでページや今の本がないときの応答を検証する() {
        // (1) 今の本Bで一行もページもない
        let noLineNoPageSeed = makeSeedJSON(books: [
            makeSeedBook(id: uuidBookB, title: "檸檬", author: "梶井基次郎", status: "current")
        ])
        resetAndLaunch(seedJSON: noLineNoPageSeed, now: "2026-10-18T21:00:00+09:00")
        runExternalIntent("WhereStoppedIntent")
        let inv1 = (readHookJSON("hook.intents")["invocations"] as? [[String: Any]] ?? []).last ?? [:]
        XCTAssertEqual(inv1["dialogKey"] as? String, "intent.whereStopped.noPage")
        XCTAssertEqual(inv1["opensApp"] as? Bool, false)

        // (2) 積読だけで今の本なし
        let tsundokuOnlySeed = makeSeedJSON(books: [
            makeSeedBook(id: uuidBookB, title: "檸檬", author: "梶井基次郎", status: "tsundoku")
        ])
        resetAndLaunch(seedJSON: tsundokuOnlySeed, now: "2026-10-18T21:00:00+09:00")
        runExternalIntent("WhereStoppedIntent")
        let inv2 = (readHookJSON("hook.intents")["invocations"] as? [[String: Any]] ?? []).last ?? [:]
        XCTAssertEqual(inv2["dialogKey"] as? String, "intent.whereStopped.noCurrent")
        XCTAssertEqual(inv2["opensApp"] as? Bool, false)

        // (3) 本0冊
        resetAndLaunch(seedJSON: makeSeedJSON(), now: "2026-10-18T21:00:00+09:00")
        runExternalIntent("WhereStoppedIntent")
        let inv3 = (readHookJSON("hook.intents")["invocations"] as? [[String: Any]] ?? []).last ?? [:]
        XCTAssertEqual(inv3["dialogKey"] as? String, "intent.whereStopped.noCurrent")
        XCTAssertEqual(inv3["opensApp"] as? Bool, false)

        // (4) 今の本Aで一行があり、ページがない
        let lineOnlySeed = makeSeedJSON(books: [
            makeSeedBook(id: uuidBookA, title: "羅生門", author: "芥川龍之介", status: "current", lastLine: "下人は、雨やみを待っていた。")
        ])
        resetAndLaunch(seedJSON: lineOnlySeed, now: "2026-10-18T21:00:00+09:00")
        runExternalIntent("WhereStoppedIntent")
        let inv4 = (readHookJSON("hook.intents")["invocations"] as? [[String: Any]] ?? []).last ?? [:]
        XCTAssertEqual(inv4["dialogKey"] as? String, "intent.whereStopped.noPage")
        XCTAssertEqual(inv4["opensApp"] as? Bool, false)
        let spoken4 = inv4["spokenText"] as? String ?? ""
        XCTAssertFalse(spoken4.contains("下人は、雨やみを待っていた。"))
    }

    func test_AC123_隠す設定オンでもどこまで読んだインテントはページを答え書名と一行を出さない() {
        let hideSeed = makeSeedJSON(
            books: [
                makeSeedBook(
                    id: uuidBookA,
                    title: "羅生門",
                    author: "芥川龍之介",
                    status: "current",
                    page: 61,
                    lastLine: "ある日の暮方の事である。"
                )
            ],
            settings: makeSeedSettings(hideOnWidgets: true)
        )
        resetAndLaunch(seedJSON: hideSeed, now: "2026-10-18T21:00:00+09:00")
        runExternalIntent("WhereStoppedIntent")

        let inv = (readHookJSON("hook.intents")["invocations"] as? [[String: Any]] ?? []).last ?? [:]
        XCTAssertEqual(inv["opensApp"] as? Bool, false)
        XCTAssertEqual(inv["authenticationPolicy"] as? String, "alwaysAllowed")
        XCTAssertEqual(inv["spokenText"] as? String, "61ページからです。")
        let snippets = inv["snippetTexts"] as? [String] ?? []
        XCTAssertFalse(snippets.joined(separator: " ").contains("羅生門"))
        XCTAssertFalse(snippets.joined(separator: " ").contains("ある日の暮方の事である。"))
    }

    func test_AC124_続きを読むインテントはしおり画面を開き始まった読書にintent_openを付ける() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        runExternalIntent("ContinueReadingIntent")

        let inv = (readHookJSON("hook.intents")["invocations"] as? [[String: Any]] ?? []).last ?? [:]
        XCTAssertEqual(inv["opensApp"] as? Bool, true)
        XCTAssertEqual(readHookState()["flipMonitoring"], "on")
        advanceClock(seconds: 120)
        element("bookmark.start").tap()
        advanceClock(seconds: 120)
        element("reading.end").tap()
        element("mark.later").tap()

        XCTAssertEqual(readHookState()["entry"], "intent_open")
    }

    func test_AC125_オフラインでも外からの3つのインテントとしおり保存がすべて動く() {
        let seed43 = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookA,
                title: "羅生門",
                author: "芥川龍之介",
                status: "current",
                page: 43,
                lastLine: "雨は、まだやまなかった。"
            )
        ])
        resetAndLaunch(
            seedJSON: seed43,
            now: "2026-10-18T21:00:00+09:00",
            offline: true,
            extraArgs: ["-uitest-widget", "accessoryRectangular:172x76"]
        )
        runExternalIntent("WhereStoppedIntent")
        let inv = (readHookJSON("hook.intents")["invocations"] as? [[String: Any]] ?? []).last ?? [:]
        XCTAssertEqual(inv["spokenText"] as? String, "43ページからです。")

        runExternalIntent("StartReadingIntent")
        advanceClock(seconds: 120)
        runExternalIntent("EndReadingFromActivityIntent", canContinueInForeground: true)

        let manualBtn = element("mark.manual")
        XCTAssertTrue(manualBtn.waitForExistence(timeout: uiTimeout))
        manualBtn.tap()
        let lineField = element("mark.lineField")
        lineField.tap()
        lineField.typeText("下人の行方は、誰も知らない。")
        let pageField = element("mark.pageField")
        pageField.tap()
        pageField.typeText("61")
        element("mark.save").tap()

        let records = readStoreRecords()
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?["minutes"] as? Int, 2)
        XCTAssertTrue(readHookString("hook.widget").contains("p.61"))
        XCTAssertEqual(app.alerts.count, 0)
    }

    func test_AC126_AppShortcuts3種とControl1種の登録内容と言い方を検証する() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00")
        let intentHook = readHookJSON("hook.intents")
        let shortcuts = intentHook["registeredShortcuts"] as? [[String: Any]] ?? []
        let controls = intentHook["registeredControls"] as? [[String: Any]] ?? []
        XCTAssertEqual(shortcuts.count, 3)

        let intents = shortcuts.compactMap { $0["intent"] as? String }
        XCTAssertTrue(intents.contains("StartReadingIntent"))
        XCTAssertTrue(intents.contains("WhereStoppedIntent"))
        XCTAssertTrue(intents.contains("ContinueReadingIntent"))

        for sc in shortcuts {
            let phrases = sc["phrases"] as? [String] ?? []
            XCTAssertFalse(phrases.isEmpty)
            for phrase in phrases {
                XCTAssertTrue(phrase.contains("${applicationName}") || phrase.contains("applicationName"))
                XCTAssertFalse(phrase.contains("${applicationName}で"))
                XCTAssertFalse(phrase.contains("applicationName)で"))
            }
        }

        XCTAssertEqual(controls.count, 1)
        XCTAssertEqual(controls.first?["kind"] as? String, "button")
        XCTAssertEqual(controls.first?["intent"] as? String, "StartReadingIntent")
        XCTAssertEqual(controls.first?["labelKey"] as? String, "control.startReading")
    }

    func test_AC131_読み始めるインテントでLiveActivity要求が失敗したらアプリを開いて読書を続ける() {
        resetAndLaunch(
            seedJSON: currentBookSeed,
            now: "2026-10-18T21:00:00+09:00",
            liveActivityJSON: #"{"failStartImmediateCount":1}"#
        )
        runExternalIntent("StartReadingIntent")

        let inv = (readHookJSON("hook.intents")["invocations"] as? [[String: Any]] ?? []).last ?? [:]
        XCTAssertEqual(inv["opensApp"] as? Bool, true)
        XCTAssertEqual(readHookState()["state"], "reading")
        XCTAssertEqual(app.alerts.count, 0)
        advanceClock(seconds: 120)
        element("reading.end").tap()
        element("mark.later").tap()

        let records = readStoreRecords()
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?["minutes"] as? Int, 2)
        XCTAssertEqual(readHookState()["entry"], "intent_start")
    }

    func test_AC132_LiveActivityの終えるで保存失敗時は読書を消さずS2にエラーを出す() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T22:00:00+09:00", failSave: "session.end:1")
        runExternalIntent("StartReadingIntent")
        advanceClock(seconds: 1800)
        runExternalIntent("EndReadingFromActivityIntent", canContinueInForeground: true)

        XCTAssertTrue(element("session.save.error").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readHookState()["state"], "reading")

        advanceClock(seconds: 300)
        element("reading.end").tap()
        element("mark.later").tap()

        let records = readStoreRecords()
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?["minutes"] as? Int, 35)
    }

    func test_AC133_どこまで読んだインテントで読込失敗時はエラー文言だけを返し書名やページを出さない() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T21:00:00+09:00", failSave: "store.load:1")
        runExternalIntent("WhereStoppedIntent")

        let inv = (readHookJSON("hook.intents")["invocations"] as? [[String: Any]] ?? []).last ?? [:]
        XCTAssertEqual(inv["opensApp"] as? Bool, false)
        XCTAssertEqual(inv["dialogKey"] as? String, "intent.whereStopped.error")
        let spoken = inv["spokenText"] as? String ?? ""
        XCTAssertFalse(spoken.contains("61"))
        XCTAssertFalse(spoken.contains("羅生門"))
        let snippets = inv["snippetTexts"] as? [String] ?? []
        XCTAssertFalse(snippets.joined(separator: " ").contains("61"))
        XCTAssertFalse(snippets.joined(separator: " ").contains("羅生門"))
    }

    func test_AC134_読書中に続きを読むインテントを動かすと読書中の画面を出す() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T22:00:00+09:00")
        element("bookmark.start").tap()
        advanceClock(seconds: 600)
        XCUIDevice.shared.press(.home)

        runExternalIntent("ContinueReadingIntent")
        XCTAssertTrue(element("reading.end").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readHookState()["state"], "reading")
        let inv = (readHookJSON("hook.intents")["invocations"] as? [[String: Any]] ?? []).last ?? [:]
        XCTAssertEqual(inv["opensApp"] as? Bool, true)
    }

    func test_AC135_今の本がないときに続きを読むインテントはしおり画面の空状態を出す() {
        let tsundokuOnly = makeSeedJSON(books: [
            makeSeedBook(id: uuidBookB, title: "こころ", author: "夏目漱石", status: "tsundoku")
        ])
        resetAndLaunch(seedJSON: tsundokuOnly, now: "2026-10-18T21:00:00+09:00")
        runExternalIntent("ContinueReadingIntent")
        XCTAssertTrue(element("bookmark.noCurrent.message").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readHookState()["state"], "idle")

        resetAndLaunch(seedJSON: makeSeedJSON(), now: "2026-10-18T21:00:00+09:00")
        runExternalIntent("ContinueReadingIntent")
        XCTAssertTrue(element("bookmark.empty.message").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readHookState()["state"], "idle")
    }

    func test_AC136_4時をまたぎLiveActivityが8時間上限で消えても読書は続き全分数が記録される() {
        resetAndLaunch(seedJSON: currentBookSeed, now: "2026-10-18T22:00:00+09:00", timezone: "Asia/Tokyo")
        runExternalIntent("StartReadingIntent")
        advanceClock(seconds: 23400)
        XCTAssertEqual(readHookState()["state"], "reading")

        advanceClock(seconds: 5400)
        transitionLiveActivity("dismissedBySystem")
        advanceClock(seconds: 3600)
        XCTAssertEqual(readHookState()["state"], "reading")

        element("reading.end").tap()
        element("mark.later").tap()

        let records = readStoreRecords()
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?["minutes"] as? Int, 540)
        XCTAssertEqual(records.first?["nightDate"] as? String, "2026-10-18")
    }

    func test_AC143_電子書籍の位置番号とパーセントに応じてどこまで読んだインテントが答える() {
        let locSeed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookE,
                title: "羅生門",
                author: "芥川龍之介",
                status: "current",
                isEbook: true,
                progressUnit: "location",
                location: 1450,
                lastLine: "下人は、雨やみを待っていた。"
            )
        ])
        resetAndLaunch(seedJSON: locSeed, now: "2026-10-18T21:00:00+09:00")
        runExternalIntent("WhereStoppedIntent")
        let inv1 = (readHookJSON("hook.intents")["invocations"] as? [[String: Any]] ?? []).last ?? [:]
        XCTAssertEqual(inv1["dialogKey"] as? String, "intent.whereStopped.location")
        let spoken1 = inv1["spokenText"] as? String ?? ""
        XCTAssertEqual(spoken1, "位置1450からです。")
        XCTAssertFalse(spoken1.contains("羅生門"))
        XCTAssertFalse(spoken1.contains("下人は、雨やみを待っていた。"))

        let pctSeed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookE,
                title: "羅生門",
                author: "芥川龍之介",
                status: "current",
                isEbook: true,
                progressUnit: "percent",
                percent: 52,
                lastLine: "下人は、雨やみを待っていた。"
            )
        ])
        resetAndLaunch(seedJSON: pctSeed, now: "2026-10-18T21:00:00+09:00")
        runExternalIntent("WhereStoppedIntent")
        let inv2 = (readHookJSON("hook.intents")["invocations"] as? [[String: Any]] ?? []).last ?? [:]
        XCTAssertEqual(inv2["dialogKey"] as? String, "intent.whereStopped.percent")
        let spoken2 = inv2["spokenText"] as? String ?? ""
        XCTAssertEqual(spoken2, "52パーセントからです。")
        XCTAssertFalse(spoken2.contains("羅生門"))
        XCTAssertFalse(spoken2.contains("下人は、雨やみを待っていた。"))
    }

    func test_AC144_電子書籍のしおり画面と読書中画面に専用案内が出てLiveActivityから終えられる() {
        let ebookSeed = makeSeedJSON(books: [
            makeSeedBook(
                id: uuidBookE,
                title: "羅生門",
                author: "芥川龍之介",
                status: "current",
                isEbook: true
            )
        ])
        resetAndLaunch(seedJSON: ebookSeed, now: "2026-10-18T21:00:00+09:00")
        XCTAssertEqual(matchingCount("bookmark.flipHint.ebook"), 1)

        element("bookmark.start").tap()
        XCTAssertEqual(matchingCount("reading.ebookNote"), 1)
        advanceClock(seconds: 600)

        runExternalIntent("EndReadingFromActivityIntent", canContinueInForeground: true)
        element("mark.later").tap()

        let records = readStoreRecords()
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?["minutes"] as? Int, 10)
    }
}
