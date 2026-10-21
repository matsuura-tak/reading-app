import Foundation

// 受け入れテストの決まったデータ（contracts/seed.schema.json の形。contracts/test-hooks.md の T2、T3、T15、T17）。
// 時刻はすべて UITEST_TIME_ZONE（Asia/Tokyo）の壁時計で、オフセットなし、秒まで。

/// 壁時計の時刻（seed.schema.json の wallClock と、T3 の UITEST_NOW の形 `YYYY-MM-DDTHH:MM:SS`）。
struct WallClock: Equatable, Sendable {
    let date: Date

    /// T15。夏時間の切り替えがない時間帯（test-hooks.md の T15 の勧め）。
    static let timeZoneID = "Asia/Tokyo"

    private static func formatter() -> DateFormatter {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: timeZoneID)
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return f
    }

    init(_ text: String) {
        guard let parsed = WallClock.formatter().date(from: text) else {
            preconditionFailure("壁時計の形ではない: \(text)")
        }
        date = parsed
    }

    private init(date: Date) {
        self.date = date
    }

    var text: String { WallClock.formatter().string(from: date) }

    func adding(seconds: Int) -> WallClock { WallClock(date: date.addingTimeInterval(TimeInterval(seconds))) }
    func adding(minutes: Int) -> WallClock { adding(seconds: minutes * 60) }
    /// Asia/Tokyo に夏時間はないので、1日は86,400秒。
    func adding(days: Int) -> WallClock { adding(seconds: days * 86_400) }
}

private func orNull(_ value: Any?) -> Any { value ?? NSNull() }

struct SeedBook: Sendable {
    var id: String
    var title: String
    var totalPages: Int?
    var lastPage: Int
    var addedAt: WallClock

    var json: [String: Any] {
        ["id": id, "title": title, "totalPages": orNull(totalPages), "lastPage": lastPage, "addedAt": addedAt.text]
    }
}

struct SeedSession: Sendable {
    var id: String
    var bookId: String
    var startedAt: WallClock
    var durationSeconds: Int
    var endPage: Int?
    var pagesRead: Int?
    var savedAt: WallClock

    var json: [String: Any] {
        [
            "id": id, "bookId": bookId, "startedAt": startedAt.text, "durationSeconds": durationSeconds,
            "endPage": orNull(endPage), "pagesRead": orNull(pagesRead), "savedAt": savedAt.text,
        ]
    }
}

struct SeedActive: Sendable {
    var bookId: String
    var state: String
    var startedAt: WallClock
    var pausedTotalSeconds: Double
    var pausedAt: WallClock?
    var finishedAt: WallClock?
    var wasPaused: Bool

    var json: [String: Any] {
        [
            "bookId": bookId, "state": state, "startedAt": startedAt.text, "pausedTotalSeconds": pausedTotalSeconds,
            "pausedAt": orNull(pausedAt?.text), "finishedAt": orNull(finishedAt?.text), "wasPaused": wasPaused,
        ]
    }
}

struct SeedFlags: Sendable {
    var firstOpenedAt: WallClock?
    var firstSessionStarted: Bool
    var first5minDone: Bool
    var weekReachedWeekStart: WallClock?

    var json: [String: Any] {
        [
            "firstOpenedAt": orNull(firstOpenedAt?.text), "firstSessionStarted": firstSessionStarted,
            "first5minDone": first5minDone, "weekReachedWeekStart": orNull(weekReachedWeekStart?.text),
        ]
    }
}

/// UITEST_SEED に渡す JSON（version 1）。
struct Seed: Sendable {
    var books: [SeedBook]
    var sessions: [SeedSession] = []
    var active: SeedActive?
    var flags: SeedFlags = Fixture.flags

    func jsonString() -> String {
        let object: [String: Any] = [
            "version": 1,
            "books": books.map(\.json),
            "sessions": sessions.map(\.json),
            "active": orNull(active?.json),
            "flags": flags.json,
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]) else {
            preconditionFailure("UITEST_SEED を JSON にできない")
        }
        return String(decoding: data, as: UTF8.self)
    }
}

enum Fixture {
    /// 基準の「今」。2026-10-21 は水曜（python3 の datetime で確かめた）。
    static let now = WallClock("2026-10-21T21:30:00")

    static let botchan = "坊っちゃん"
    static let kokoro = "こころ"

    /// seed.schema.json の uuid（小文字の16進）。n はそのまま10進の数字で末尾12桁に入る。
    static func id(_ n: Int) -> String { String(format: "00000000-0000-4000-8000-%012ld", n) }
    static let botchanId = id(1)
    static let kokoroId = id(2)

    /// App First Opened は送り済み、ほかの印も済み、今週の Reading Week Reached は未送信。
    static let flags = SeedFlags(
        firstOpenedAt: WallClock("2026-10-01T19:55:00"), firstSessionStarted: true, first5minDone: true,
        weekReachedWeekStart: nil)

    static func book(
        _ n: Int, _ title: String, totalPages: Int? = 300, lastPage: Int = 0,
        addedAt: WallClock = WallClock("2026-10-01T20:00:00")
    ) -> SeedBook {
        SeedBook(id: id(n), title: title, totalPages: totalPages, lastPage: lastPage, addedAt: addedAt)
    }

    /// 記録1件。savedAt は終わった30秒後。
    static func session(
        _ n: Int, book: String, startedAt: WallClock, seconds: Int, endPage: Int? = nil, pagesRead: Int? = nil
    ) -> SeedSession {
        SeedSession(
            id: id(n), bookId: book, startedAt: startedAt, durationSeconds: seconds, endPage: endPage,
            pagesRead: endPage == nil ? nil : (pagesRead ?? 0), savedAt: startedAt.adding(seconds: seconds + 30))
    }

    /// reading。経過 elapsed 秒（startedAt = now − elapsed）。
    static func reading(_ book: String, elapsed: Int, now: WallClock = now) -> SeedActive {
        SeedActive(
            bookId: book, state: "reading", startedAt: now.adding(seconds: -elapsed), pausedTotalSeconds: 0,
            pausedAt: nil, finishedAt: nil, wasPaused: false)
    }

    /// paused。経過 elapsedAtPause 秒のときに止め、止めてから pausedFor 秒たった。
    static func paused(_ book: String, elapsedAtPause: Int, pausedFor: Int, now: WallClock = now) -> SeedActive {
        let pausedAt = now.adding(seconds: -pausedFor)
        return SeedActive(
            bookId: book, state: "paused", startedAt: pausedAt.adding(seconds: -elapsedAtPause),
            pausedTotalSeconds: 0, pausedAt: pausedAt, finishedAt: nil, wasPaused: true)
    }

    /// finishing。経過 elapsed 秒のときに「終える」をし、それから finishedAgo 秒たった。
    static func finishing(_ book: String, elapsed: Int, finishedAgo: Int = 0, now: WallClock = now) -> SeedActive {
        let finishedAt = now.adding(seconds: -finishedAgo)
        return SeedActive(
            bookId: book, state: "finishing", startedAt: finishedAt.adding(seconds: -elapsed),
            pausedTotalSeconds: 0, pausedAt: nil, finishedAt: finishedAt, wasPaused: false)
    }

    /// AC-17、AC-27 の3通り（reading 経過5:00、paused 経過5:00 で1分止めた、finishing 経過10:00）。
    static func active(_ state: String, book: String) -> SeedActive {
        switch state {
        case "paused": return paused(book, elapsedAtPause: 300, pausedFor: 60)
        case "finishing": return finishing(book, elapsed: 600)
        default: return reading(book, elapsed: 300)
        }
    }
}

/// テストで使う決まったデータの組。
enum Seeds {
    /// 「坊っちゃん」（総ページ数300、最後のページ lastPage）に記録1件（前の日、20分）。
    static func botchanOneSession(lastPage: Int = 40, active: SeedActive? = nil) -> Seed {
        Seed(
            books: [Fixture.book(1, Fixture.botchan, totalPages: 300, lastPage: lastPage)],
            sessions: [
                Fixture.session(
                    101, book: Fixture.botchanId, startedAt: WallClock("2026-10-20T21:00:00"), seconds: 1200,
                    endPage: lastPage, pagesRead: lastPage)
            ],
            active: active)
    }

    /// 「坊っちゃん」（300、72）と「こころ」（未設定、40）に記録1件ずつ。active は「坊っちゃん」に付ける。
    static func twoBooks(active: SeedActive?) -> Seed {
        Seed(
            books: [
                Fixture.book(1, Fixture.botchan, totalPages: 300, lastPage: 72),
                Fixture.book(2, Fixture.kokoro, totalPages: nil, lastPage: 40, addedAt: WallClock("2026-10-02T20:00:00")),
            ],
            sessions: [
                Fixture.session(
                    101, book: Fixture.botchanId, startedAt: WallClock("2026-10-20T21:00:00"), seconds: 1200,
                    endPage: 72, pagesRead: 30),
                Fixture.session(
                    201, book: Fixture.kokoroId, startedAt: WallClock("2026-10-19T22:00:00"), seconds: 900,
                    endPage: 40, pagesRead: 40),
            ],
            active: active)
    }

    /// contracts/seed.example.json と同じ中身（AC-18、AC-54、AC-55。「坊っちゃん」10分・20分・30分、「こころ」15分・25分）。
    static func libraryOfFive() -> Seed {
        Seed(
            books: [
                Fixture.book(1, Fixture.botchan, totalPages: 300, lastPage: 72, addedAt: WallClock("2026-10-01T20:00:00")),
                Fixture.book(2, Fixture.kokoro, totalPages: nil, lastPage: 40, addedAt: WallClock("2026-10-02T20:00:00")),
            ],
            sessions: [
                Fixture.session(101, book: Fixture.botchanId, startedAt: WallClock("2026-10-05T21:00:00"), seconds: 600, endPage: 20, pagesRead: 20),
                Fixture.session(102, book: Fixture.botchanId, startedAt: WallClock("2026-10-12T21:00:00"), seconds: 1200, endPage: 45, pagesRead: 25),
                Fixture.session(103, book: Fixture.botchanId, startedAt: WallClock("2026-10-20T21:00:00"), seconds: 1800, endPage: 72, pagesRead: 27),
                Fixture.session(201, book: Fixture.kokoroId, startedAt: WallClock("2026-10-03T22:00:00"), seconds: 900),
                Fixture.session(202, book: Fixture.kokoroId, startedAt: WallClock("2026-10-10T22:00:00"), seconds: 1500, endPage: 40, pagesRead: 40),
            ])
    }
}
