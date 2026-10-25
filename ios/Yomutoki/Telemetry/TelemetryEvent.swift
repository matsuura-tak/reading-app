import Foundation

// 計測のイベント（PRD 15、contracts/telemetry.md、contracts/telemetry-events.schema.json、ADR 0003）。
// イベント名とプロパティ名の文字は、このファイルの TelemetryEvent.name と properties の1か所でだけ作る。
// 関連値は区間の enum と Bool だけ（題名とページの生の値を型の上で渡せなくする。AC-23）。

/// 追加した後の冊数の区間。
nonisolated enum BookCountBucket: String, Sendable, CaseIterable {
    case one = "1"
    case twoToFive = "2-5"
    case sixToTwenty = "6-20"
    case twentyOneOrMore = "21+"

    init(count: Int) {
        switch count {
        case ...1: self = .one
        case 2...5: self = .twoToFive
        case 6...20: self = .sixToTwenty
        default: self = .twentyOneOrMore
        }
    }
}

/// 保存した durationSeconds を分（切り捨て）にした区間。
nonisolated enum DurationBucket: String, Sendable, CaseIterable {
    case m1to4 = "1-4"
    case m5to14 = "5-14"
    case m15to29 = "15-29"
    case m30to59 = "30-59"
    case m60to119 = "60-119"
    case m120OrMore = "120+"

    init(seconds: Int) {
        switch ReadingMath.wholeMinutes(seconds: seconds) {
        case ...4: self = .m1to4
        case 5...14: self = .m5to14
        case 15...29: self = .m15to29
        case 30...59: self = .m30to59
        case 60...119: self = .m60to119
        default: self = .m120OrMore
        }
    }
}

/// 保存した pagesRead の区間（読み返しは0）。
nonisolated enum PagesBucket: String, Sendable, CaseIterable {
    case zero = "0"
    case p1to9 = "1-9"
    case p10to29 = "10-29"
    case p30to99 = "30-99"
    case p100OrMore = "100+"

    init(pagesRead: Int) {
        switch pagesRead {
        case ...0: self = .zero
        case 1...9: self = .p1to9
        case 10...29: self = .p10to29
        case 30...99: self = .p30to99
        default: self = .p100OrMore
        }
    }
}

/// 記録の savedAt − telemetry.firstOpenedAt の区間。負のときも "0-24h"。
nonisolated enum SinceFirstOpenBucket: String, Sendable, CaseIterable {
    case within24h = "0-24h"
    case days1to7 = "1-7d"
    case days8OrMore = "8d+"

    init(seconds: TimeInterval) {
        if seconds < 86_400 {
            self = .within24h
        } else if seconds < 691_200 {
            self = .days1to7
        } else {
            self = .days8OrMore
        }
    }
}

/// 読み始めた場所（design 1：S1 の主操作、S3、S2 で追加した直後の S3）。
nonisolated enum StartSource: String, Sendable, CaseIterable {
    case home
    case bookDetail = "book_detail"
    case afterAdd = "after_add"
}

/// 起動して戻した読書の状態。
nonisolated enum RestoredState: String, Sendable, CaseIterable {
    case reading
    case paused
    case finishing

    init(_ state: ReadingState) {
        switch state {
        case .reading: self = .reading
        case .paused: self = .paused
        case .finishing: self = .finishing
        }
    }
}

/// Save Failed の operation（contracts/telemetry.md）。読み込み（load）は Load Failed なのでここにない。
nonisolated enum SaveOperation: String, Sendable, CaseIterable {
    case bookAdd = "book_add"
    case sessionStart = "session_start"
    case sessionPause = "session_pause"
    case sessionResume = "session_resume"
    case sessionFinish = "session_finish"
    case sessionDelete = "session_delete"
    case sessionBeginFinish = "session_begin_finish"
    case sessionCancelFinish = "session_cancel_finish"
    case sessionDiscard = "session_discard"
}

/// Reading Session Finished のプロパティ。pages が nil なら page_entered = false で pages_bucket を送らない。
nonisolated struct SessionFinishedProperties: Sendable, Equatable {
    var duration: DurationBucket
    var pages: PagesBucket?
    var minutesEdited: Bool
    var wasPaused: Bool
    var isFirst5min: Bool
    var sinceFirstOpen: SinceFirstOpenBucket
}

/// PRD 15 の9イベント。
nonisolated enum TelemetryEvent: Sendable, Equatable {
    case appFirstOpened
    case bookAdded(hasTotalPages: Bool, bookCount: BookCountBucket)
    case readingSessionStarted(isFirstSession: Bool, startSource: StartSource)
    case readingSessionFinished(SessionFinishedProperties)
    /// reason は "relaunch" だけ。
    case readingSessionRestored(state: RestoredState)
    /// reason は "too_short" だけ。
    case readingSessionDiscarded
    /// threshold_min は "60" だけ。
    case readingWeekReached
    case saveFailed(operation: SaveOperation)
    case loadFailed

    var name: String {
        switch self {
        case .appFirstOpened: "App First Opened"
        case .bookAdded: "Book Added"
        case .readingSessionStarted: "Reading Session Started"
        case .readingSessionFinished: "Reading Session Finished"
        case .readingSessionRestored: "Reading Session Restored"
        case .readingSessionDiscarded: "Reading Session Discarded"
        case .readingWeekReached: "Reading Week Reached"
        case .saveFailed: "Save Failed"
        case .loadFailed: "Load Failed"
        }
    }

    var properties: [String: TelemetryValue] {
        switch self {
        case .appFirstOpened, .loadFailed:
            return [:]
        case .bookAdded(let hasTotalPages, let bookCount):
            return ["has_total_pages": .bool(hasTotalPages), "book_count_bucket": .string(bookCount.rawValue)]
        case .readingSessionStarted(let isFirstSession, let startSource):
            return ["is_first_session": .bool(isFirstSession), "start_source": .string(startSource.rawValue)]
        case .readingSessionFinished(let finished):
            var values: [String: TelemetryValue] = [
                "duration_bucket": .string(finished.duration.rawValue),
                "page_entered": .bool(finished.pages != nil),
                "minutes_edited": .bool(finished.minutesEdited),
                "was_paused": .bool(finished.wasPaused),
                "is_first_5min": .bool(finished.isFirst5min),
                "since_first_open": .string(finished.sinceFirstOpen.rawValue),
            ]
            if let pages = finished.pages {
                values["pages_bucket"] = .string(pages.rawValue)
            }
            return values
        case .readingSessionRestored(let state):
            return ["reason": .string("relaunch"), "state": .string(state.rawValue)]
        case .readingSessionDiscarded:
            return ["reason": .string("too_short")]
        case .readingWeekReached:
            return ["threshold_min": .string("60")]
        case .saveFailed(let operation):
            return ["operation": .string(operation.rawValue)]
        }
    }

    /// telemetry-events.schema.json の形（{"name": …, "properties": {…}}）の JSON。キーは並べ替える。
    func jsonData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(TelemetryPayload(event: self))
    }
}

/// プロパティの値は区間の文字か真偽の2つだけ。
nonisolated enum TelemetryValue: Sendable, Equatable, Encodable {
    case string(String)
    case bool(Bool)

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        }
    }
}

/// POST /events の本文と、T22 の events の各要素の形。
nonisolated struct TelemetryPayload: Encodable, Sendable, Equatable {
    let name: String
    let properties: [String: TelemetryValue]

    init(event: TelemetryEvent) {
        name = event.name
        properties = event.properties
    }
}
