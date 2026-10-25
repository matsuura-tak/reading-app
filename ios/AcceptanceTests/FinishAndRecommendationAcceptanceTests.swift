import XCTest

final class FinishAndRecommendationAcceptanceTests: AcceptanceTestBase {

    private let finishSeed = #"{"books":[{"id":"book-a","title":"蜜蜂と遠雷","author":"恩田陸","status":"current","savedLine":"風が吹いていた。","savedPage":120},{"id":"book-p","title":"夜のピクニック","author":"恩田陸","status":"tsundoku"},{"id":"book-q","title":"宝島","author":"真藤順丈","status":"tsundoku"},{"id":"book-r","title":"銀河鉄道の夜","author":"宮沢賢治","status":"tsundoku"},{"id":"book-s","title":"走れメロス","author":"太宰治","status":"tsundoku"}],"records":[{"id":"r1","bookID":"book-a","nightDate":"2026-10-15","minutes":20},{"id":"r2","bookID":"book-a","nightDate":"2026-10-16","minutes":15},{"id":"r3","bookID":"book-a","nightDate":"2026-10-17","minutes":30}]}"#

    private let awardsStub = #"{"awards":[{"award":"直木三十五賞","sessionOrYear":"第156回","title":"蜜蜂と遠雷","author":"恩田陸"},{"award":"直木三十五賞","sessionOrYear":"第160回","title":"宝島","author":"真藤順丈"},{"award":"直木三十五賞","sessionOrYear":"第157回","title":"月の満ち欠け","author":"佐藤正午"}]}"#

    func test_AC77_読み終えたボタンで読了になり奥付5行と奥付撮影ボタンが出る() {
        resetAndLaunch(seedJSON: finishSeed, now: "2026-10-18T21:00:00+09:00", awardsJSON: awardsStub)
        let finishBtn = element("bookmark.finish")
        XCTAssertTrue(finishBtn.waitForExistence(timeout: uiTimeout))
        finishBtn.tap()

        XCTAssertTrue(element("finish.colophon").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(matchingCount("colophon.capture"), 1)
        let books = readHookJSON("hook.store")["books"] as? [[String: Any]] ?? []
        let bookA = books.first { ($0["id"] as? String) == "book-a" }
        XCTAssertEqual(bookA?["status"] as? String, "finished")
    }

    func test_AC78_次の1冊に積読の関連本2冊と未所有の関連本1冊が順に並ぶ() {
        resetAndLaunch(seedJSON: finishSeed, now: "2026-10-18T21:00:00+09:00", awardsJSON: awardsStub)
        element("bookmark.finish").tap()

        XCTAssertTrue(element("finish.colophon").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(matchingCount("next.candidate"), 3)
        let firstTitle = readHookString("next.candidate.0.title")
        let secondTitle = readHookString("next.candidate.1.title")
        let thirdTitle = readHookString("next.candidate.2.title")
        XCTAssertEqual(firstTitle, "夜のピクニック")
        XCTAssertEqual(secondTitle, "宝島")
        XCTAssertEqual(thirdTitle, "月の満ち欠け")
    }

    func test_AC79_次の1冊の各候補に事実1行の理由が出る() {
        resetAndLaunch(seedJSON: finishSeed, now: "2026-10-18T21:00:00+09:00", awardsJSON: awardsStub)
        element("bookmark.finish").tap()

        XCTAssertTrue(element("finish.colophon").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readHookString("next.reason.0"), "積読から・同じ著者")
        XCTAssertEqual(readHookString("next.reason.1"), "積読から・同じ賞（直木三十五賞）")
        XCTAssertEqual(readHookString("next.reason.2"), "同じ賞（第157回 直木三十五賞）")
    }

    func test_AC80_未所有の候補がないときは積読から最大3冊を出す() {
        let seedNoUnowned = #"{"books":[{"id":"book-a","title":"蜜蜂と遠雷","author":"恩田陸","status":"current"},{"id":"book-p","title":"夜のピクニック","author":"恩田陸","status":"tsundoku"},{"id":"book-r","title":"銀河鉄道の夜","author":"宮沢賢治","status":"tsundoku"},{"id":"book-s","title":"走れメロス","author":"太宰治","status":"tsundoku"}],"records":[]}"#
        resetAndLaunch(seedJSON: seedNoUnowned, now: "2026-10-18T21:00:00+09:00", awardsJSON: #"{"awards":[]}"#)
        element("bookmark.finish").tap()

        XCTAssertTrue(element("finish.colophon").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(matchingCount("next.candidate"), 3)
        XCTAssertEqual(readHookString("next.reason.0"), "積読から・同じ著者")
        XCTAssertEqual(readHookString("next.reason.1"), "積読から")
        XCTAssertEqual(readHookString("next.reason.2"), "積読から")
    }

    func test_AC81_積読も未所有の候補もないときは本を加える案内が出る() {
        let onlyCurrent = #"{"books":[{"id":"book-a","title":"孤独な本","author":"無名著者","status":"current"}],"records":[]}"#
        resetAndLaunch(seedJSON: onlyCurrent, now: "2026-10-18T21:00:00+09:00", ndlStubJSON: #"{"books":[]}"#, awardsJSON: #"{"awards":[]}"#)
        element("bookmark.finish").tap()

        XCTAssertTrue(element("next.empty.message").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(matchingCount("next.candidate"), 0)
        XCTAssertEqual(matchingCount("next.addBook"), 1)
    }

    func test_AC82_次の1冊で積読の本を選ぶと今の本になりウィジェットも更新される() {
        resetAndLaunch(seedJSON: finishSeed, now: "2026-10-18T21:00:00+09:00", awardsJSON: awardsStub)
        element("bookmark.finish").tap()

        let chooseBtn = element("next.choose.0")
        XCTAssertTrue(chooseBtn.waitForExistence(timeout: uiTimeout))
        chooseBtn.tap()

        XCTAssertEqual(readHookString("bookmark.title"), "夜のピクニック")
        let widget = readHookJSON("hook.widgets")
        XCTAssertEqual(widget["title"] as? String, "夜のピクニック")
    }

    func test_AC83_受賞一覧から出た未所有の本を積読に加えられる() {
        resetAndLaunch(seedJSON: finishSeed, now: "2026-10-18T21:00:00+09:00", awardsJSON: awardsStub)
        element("bookmark.finish").tap()

        let addBtn = element("next.addToShelf.2")
        XCTAssertTrue(addBtn.waitForExistence(timeout: uiTimeout))
        addBtn.tap()

        let books = readHookJSON("hook.store")["books"] as? [[String: Any]] ?? []
        let added = books.first { ($0["title"] as? String) == "月の満ち欠け" }
        XCTAssertEqual(added?["author"] as? String, "佐藤正午")
        XCTAssertEqual(added?["status"] as? String, "tsundoku")
        XCTAssertEqual(matchingCount("next.addToShelf.2"), 0)
    }

    func test_AC84_読み終えのカード画像に書名著者晩数分数だけを描き一行を含めない() {
        resetAndLaunch(seedJSON: finishSeed, now: "2026-10-18T21:00:00+09:00", awardsJSON: awardsStub)
        element("bookmark.finish").tap()

        let shareBtn = element("finish.card.share")
        XCTAssertTrue(shareBtn.waitForExistence(timeout: uiTimeout))
        shareBtn.tap()

        let shareHook = readHookJSON("hook.share")
        let texts = shareHook["renderedTexts"] as? [String] ?? []
        XCTAssertTrue(texts.contains("蜜蜂と遠雷"))
        XCTAssertTrue(texts.contains("恩田陸"))
        XCTAssertTrue(texts.contains("3晩"))
        XCTAssertTrue(texts.contains("65分"))
        XCTAssertEqual(shareHook["containsSavedLine"] as? Bool, false)
        XCTAssertEqual(shareHook["containsPhoto"] as? Bool, false)
    }

    func test_AC85_読み終えのカードの晩数を4時境目のユニーク晩数で数える() {
        let sameNightSeed = #"{"books":[{"id":"book-a","title":"蜜蜂と遠雷","author":"恩田陸","status":"current"}],"records":[{"id":"r1","bookID":"book-a","startedAt":"2026-10-15T23:30:00+09:00","nightDate":"2026-10-15","minutes":20},{"id":"r2","bookID":"book-a","startedAt":"2026-10-16T00:40:00+09:00","nightDate":"2026-10-15","minutes":15},{"id":"r3","bookID":"book-a","startedAt":"2026-10-16T21:00:00+09:00","nightDate":"2026-10-16","minutes":30}]}"#
        resetAndLaunch(seedJSON: sameNightSeed, now: "2026-10-18T21:00:00+09:00")
        element("bookmark.finish").tap()
        element("finish.card.share").tap()

        let texts = readHookJSON("hook.share")["renderedTexts"] as? [String] ?? []
        XCTAssertTrue(texts.contains("2晩"))
        XCTAssertTrue(texts.contains("65分"))
    }

    func test_AC86_今の本がある毎晩の道には次の1冊の候補を出さない() {
        resetAndLaunch(seedJSON: finishSeed, now: "2026-10-18T21:00:00+09:00", awardsJSON: awardsStub)
        XCTAssertEqual(matchingCount("next.candidate"), 0)
        XCTAssertEqual(matchingCount("bookmark.noCurrent.next"), 0)

        element("bookmark.start").tap()
        XCTAssertEqual(matchingCount("next.candidate"), 0)
        advanceClock(seconds: 120)

        element("reading.end").tap()
        XCTAssertEqual(matchingCount("next.candidate"), 0)

        element("mark.later").tap()
        XCTAssertEqual(matchingCount("next.candidate"), 0)
        XCTAssertEqual(app.alerts.count, 0)
    }

    func test_AC87_端末内書誌DBからシリーズの次の巻と同じ著者の本を推薦し書誌つきで積読に加える() {
        let seriesSeed = #"{"books":[{"id":"book-a","title":"鹿の王 1","author":"上橋菜穂子","status":"current"},{"id":"book-p","title":"獣の奏者","author":"上橋菜穂子","status":"tsundoku"}],"records":[]}"#
        let ndlStub = #"{"books":[{"isbn":"9784041026000","title":"鹿の王 2","author":"上橋菜穂子","publisher":"KADOKAWA","label":"角川文庫","year":2019,"series":"鹿の王","volume":2},{"isbn":"9784101302720","title":"狐笛のかなた","author":"上橋菜穂子","publisher":"新潮社","label":"新潮文庫","year":2006}]}"#
        resetAndLaunch(seedJSON: seriesSeed, now: "2026-10-18T21:00:00+09:00", ndlStubJSON: ndlStub, awardsJSON: #"{"awards":[]}"#)
        element("bookmark.finish").tap()

        XCTAssertTrue(element("finish.colophon").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readHookString("next.reason.1"), "シリーズの次の巻")
        XCTAssertEqual(readHookString("next.reason.2"), "同じ著者の本")

        element("next.addToShelf.1").tap()
        let books = readHookJSON("hook.store")["books"] as? [[String: Any]] ?? []
        let u1 = books.first { ($0["title"] as? String) == "鹿の王 2" }
        XCTAssertEqual(u1?["publisher"] as? String, "KADOKAWA")
        XCTAssertEqual(u1?["label"] as? String, "角川文庫")
        XCTAssertEqual(u1?["isbn"] as? String, "9784041026000")
        XCTAssertEqual(u1?["status"] as? String, "tsundoku")
    }

    func test_AC127_読み終えのふりかえり1行に晩数と合計時間と最長の晩が出てカードには載らない() {
        let multiRecordSeed = #"{"books":[{"id":"book-a","title":"蜜蜂と遠雷","author":"恩田陸","status":"current"}],"records":[{"id":"r1","bookID":"book-a","nightDate":"2026-10-11","minutes":20},{"id":"r2","bookID":"book-a","nightDate":"2026-10-12","minutes":20},{"id":"r3","bookID":"book-a","nightDate":"2026-10-13","minutes":20},{"id":"r4","bookID":"book-a","nightDate":"2026-10-14","minutes":22},{"id":"r5","bookID":"book-a","nightDate":"2026-10-15","minutes":18},{"id":"r6","bookID":"book-a","nightDate":"2026-10-15","minutes":20},{"id":"r7","bookID":"book-a","nightDate":"2026-10-16","minutes":22}]}"#
        resetAndLaunch(seedJSON: multiRecordSeed, now: "2026-10-18T21:00:00+09:00")
        element("bookmark.finish").tap()

        let reflection = readHookString("finish.reflection")
        XCTAssertTrue(reflection.contains("6晩"))
        XCTAssertTrue(reflection.contains("142分（2時間22分）"))
        XCTAssertTrue(reflection.contains("10月15日"))
        XCTAssertTrue(reflection.contains("38分"))

        element("finish.card.share").tap()
        let texts = readHookJSON("hook.share")["renderedTexts"] as? [String] ?? []
        XCTAssertFalse(texts.joined(separator: " ").contains("10月15日"))
        XCTAssertFalse(texts.joined(separator: " ").contains("38分"))
    }

    func test_AC128_ふりかえり1行の1晩のみの文言と同点最長晩の新しい日付選択を検証する() {
        let singleNightSeed = #"{"books":[{"id":"book-a","title":"蜜蜂と遠雷","author":"恩田陸","status":"current"}],"records":[{"id":"r1","bookID":"book-a","nightDate":"2026-10-15","minutes":30}]}"#
        resetAndLaunch(seedJSON: singleNightSeed, now: "2026-10-18T21:00:00+09:00")
        element("bookmark.finish").tap()
        let singleRef = readHookString("finish.reflection")
        XCTAssertTrue(singleRef.contains("1晩"))
        XCTAssertTrue(singleRef.contains("30分"))
        XCTAssertFalse(singleRef.contains("10月15日"))

        let tieSeed = #"{"books":[{"id":"book-a","title":"蜜蜂と遠雷","author":"恩田陸","status":"current"}],"records":[{"id":"r1","bookID":"book-a","nightDate":"2026-10-13","minutes":30},{"id":"r2","bookID":"book-a","nightDate":"2026-10-14","minutes":10},{"id":"r3","bookID":"book-a","nightDate":"2026-10-15","minutes":30}]}"#
        resetAndLaunch(seedJSON: tieSeed, now: "2026-10-18T21:00:00+09:00")
        element("bookmark.finish").tap()
        let tieRef = readHookString("finish.reflection")
        XCTAssertTrue(tieRef.contains("3晩"))
        XCTAssertTrue(tieRef.contains("70分（1時間10分）"))
        XCTAssertTrue(tieRef.contains("10月15日"))
    }

    func test_AC129_記録が0件の本を読み終えたときはふりかえり1行を出さない() {
        let zeroRecordSeed = #"{"books":[{"id":"book-a","title":"蜜蜂と遠雷","author":"恩田陸","status":"current"}],"records":[]}"#
        resetAndLaunch(seedJSON: zeroRecordSeed, now: "2026-10-18T21:00:00+09:00")
        element("bookmark.finish").tap()

        XCTAssertTrue(element("finish.colophon").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(matchingCount("finish.reflection"), 0)
        XCTAssertEqual(app.alerts.count, 0)
    }

    func test_AC145_今の本が0冊で積読があるときしおり画面に最大3冊出て1タップで今の本になる() {
        let noCurrentSeed = #"{"books":[{"id":"book-a","title":"蜜蜂と遠雷","author":"恩田陸","status":"finished","finishedAt":"2026-10-17T22:00:00+09:00"},{"id":"book-r","title":"銀河鉄道の夜","author":"宮沢賢治","status":"tsundoku"},{"id":"book-s","title":"走れメロス","author":"太宰治","status":"tsundoku"},{"id":"book-p","title":"夜のピクニック","author":"恩田陸","status":"tsundoku"},{"id":"book-t","title":"檸檬","author":"梶井基次郎","status":"tsundoku"}],"records":[]}"#
        resetAndLaunch(seedJSON: noCurrentSeed, now: "2026-10-18T21:00:00+09:00")

        XCTAssertTrue(element("bookmark.noCurrent.message").waitForExistence(timeout: uiTimeout))
        let choose0 = element("bookmark.noCurrent.choose.0")
        XCTAssertTrue(choose0.waitForExistence(timeout: uiTimeout))
        choose0.tap()

        XCTAssertEqual(readHookString("bookmark.title"), "夜のピクニック")
        XCTAssertTrue(element("bookmark.start").exists)
    }

    func test_AC146_読み終えた本の詳細画面にこの本のあとにが最大5冊出てその場で積読に加えられる() {
        let finishedSeed = #"{"books":[{"id":"book-a","title":"蜜蜂と遠雷","author":"恩田陸","status":"finished"}],"records":[]}"#
        let ndlStub = #"{"books":[{"isbn":"9784101234014","title":"夜のピクニック","author":"恩田陸"},{"isbn":"9784101234021","title":"ユージニア","author":"恩田陸"},{"isbn":"9784101234038","title":"六番目の小夜子","author":"恩田陸"}]}"#
        let awardsMany = #"{"awards":[{"award":"直木三十五賞","sessionOrYear":"第156回","title":"蜜蜂と遠雷","author":"恩田陸"},{"award":"直木三十五賞","sessionOrYear":"第157回","title":"月の満ち欠け","author":"佐藤正午"},{"award":"直木三十五賞","sessionOrYear":"第158回","title":"おらおらでひとりいぐも","author":"若竹千佐子"},{"award":"直木三十五賞","sessionOrYear":"第160回","title":"宝島","author":"真藤順丈"}]}"#
        resetAndLaunch(seedJSON: finishedSeed, now: "2026-10-18T21:00:00+09:00", ndlStubJSON: ndlStub, awardsJSON: awardsMany)

        element("tab.shelf").tap()
        element("shelf.row.book-a").tap()

        XCTAssertTrue(element("after.header").waitForExistence(timeout: uiTimeout))
        XCTAssertLessThanOrEqual(matchingCount("after.candidate"), 5)
        element("after.addToShelf.0").tap()
        XCTAssertTrue(element("after.added.0").waitForExistence(timeout: uiTimeout))
    }

    func test_AC147_端末内の重み付けでよく選ぶ理由の候補が既定の順より上に繰り上がる() {
        let weightSeed = #"{"books":[{"id":"book-a","title":"蜜蜂と遠雷","author":"恩田陸","status":"current"}],"records":[],"recommendationWeights":{"sameAward":{"chosen":3,"skipped":0},"sameAuthor":{"chosen":0,"skipped":3}}}"#
        let ndlStub = #"{"books":[{"isbn":"9784101234014","title":"夜のピクニック","author":"恩田陸"}]}"#
        resetAndLaunch(seedJSON: weightSeed, now: "2026-10-18T21:00:00+09:00", ndlStubJSON: ndlStub, awardsJSON: awardsStub)
        element("bookmark.finish").tap()

        XCTAssertTrue(element("finish.colophon").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(readHookString("next.candidate.0.title"), "月の満ち欠け")
        XCTAssertEqual(readHookString("next.candidate.1.title"), "夜のピクニック")
    }

    func test_AC148_共起テーブルから文学NDC9かつ10人以上の本だけを人数を出さずに推薦する() {
        let coocSeed = #"{"books":[{"id":"book-a","title":"蜜蜂と遠雷","author":"恩田陸","isbn":"9784863893894","status":"current"}],"records":[]}"#
        let ndlCooc = #"{"books":[{"isbn":"9784101234014","title":"夜のピクニック","author":"恩田陸","ndc":"913.6"},{"isbn":"9784101234021","title":"ユージニア","author":"恩田陸","ndc":"913.6"},{"isbn":"9784101234038","title":"経営の教科書","author":"山田太郎","ndc":"336"}],"cooccurrence":[{"fromISBN":"9784863893894","toISBN":"9784101234014","count":12},{"fromISBN":"9784863893894","toISBN":"9784101234021","count":9},{"fromISBN":"9784863893894","toISBN":"9784101234038","count":25}]}"#
        resetAndLaunch(seedJSON: coocSeed, now: "2026-10-18T21:00:00+09:00", ndlStubJSON: ndlCooc, awardsJSON: #"{"awards":[]}"#)
        element("bookmark.finish").tap()

        XCTAssertTrue(element("finish.colophon").waitForExistence(timeout: uiTimeout))
        XCTAssertEqual(matchingCount("next.candidate"), 1)
        XCTAssertEqual(readHookString("next.candidate.0.title"), "夜のピクニック")
        let reason = readHookString("next.reason.0")
        XCTAssertFalse(reason.contains("12"))
    }
}
