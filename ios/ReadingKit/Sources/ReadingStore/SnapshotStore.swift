import Foundation
import ReadingCore
#if canImport(WidgetKit)
import WidgetKit
#endif

/// `-uitest-widget` の1つ（`<ファミリー>:<幅>x<高さ>`）。
public struct WidgetRenderSpec: Sendable, Equatable {
    public var family: WidgetSurfaceFamily
    public var width: Double
    public var height: Double

    public init(family: WidgetSurfaceFamily, width: Double, height: Double) {
        self.family = family
        self.width = width
        self.height = height
    }

    public static let defaultSpec = WidgetRenderSpec(family: .accessoryRectangular, width: 172, height: 76)

    /// 1つを読む。ファミリーか枠が読めなければ nil。
    public static func parse(_ item: String) -> WidgetRenderSpec? {
        let parts = item.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 2, let family = WidgetSurfaceFamily(rawValue: parts[0]) else { return nil }
        let size = parts[1].split(separator: "x", omittingEmptySubsequences: false).map(String.init)
        guard size.count == 2,
              let width = Double(size[0]), let height = Double(size[1]),
              width.isFinite, height.isFinite, width > 0, height > 0 else { return nil }
        return WidgetRenderSpec(family: family, width: width, height: height)
    }

    /// 並びを読む。読めない1つがあれば `.failure(その1つ)`。
    public static func parseList(_ raw: String) -> Result<[WidgetRenderSpec], WidgetRenderSpecError> {
        var specs: [WidgetRenderSpec] = []
        for item in raw.split(separator: ",").map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) }) where !item.isEmpty {
            guard let spec = parse(item) else { return .failure(WidgetRenderSpecError(value: item)) }
            specs.append(spec)
        }
        guard !specs.isEmpty else { return .failure(WidgetRenderSpecError(value: raw)) }
        return .success(specs)
    }
}

public struct WidgetRenderSpecError: Error, Sendable, Equatable {
    public let value: String
}

/// `UITEST_WIDGET_SNAPSHOT` の差し替え（アプリの `UITestHooks/` だけが設定する）。
public enum WidgetSnapshotOverride: Sendable, Equatable {
    /// `@missing`：ファイルがないのと同じ。
    case missing
    /// 写しの文字列そのもの。
    case contents(String)
}

// MARK: - H22 の読み出し（contracts/hooks/h22-widget.schema.json）

public struct WidgetRenderRequest: Encodable, Sendable, Equatable {
    public var family: String
    public var width: Double
    public var height: Double
}

public struct WidgetRenderAccessibility: Encodable, Sendable, Equatable {
    public var identifier: String
    public var label: String
    public var groupCount: Int
}

public struct WidgetRenderTimelineEntry: Encodable, Sendable, Equatable {
    public var date: String
    public var state: WidgetRenderState
}

public enum WidgetRenderTimelinePolicy: Encodable, Sendable, Equatable {
    case never
    case atEnd
    case after(String)

    private enum AfterKey: String, CodingKey { case after }

    public func encode(to encoder: any Encoder) throws {
        switch self {
        case .never:
            var c = encoder.singleValueContainer()
            try c.encode("never")
        case .atEnd:
            var c = encoder.singleValueContainer()
            try c.encode("atEnd")
        case .after(let date):
            var c = encoder.container(keyedBy: AfterKey.self)
            try c.encode(date, forKey: .after)
        }
    }
}

public struct WidgetRenderTimeline: Encodable, Sendable, Equatable {
    public var entries: [WidgetRenderTimelineEntry]
    public var policy: WidgetRenderTimelinePolicy
    public var elapsedMs: Double
}

public struct WidgetRenderEntry: Encodable, Sendable, Equatable {
    public var request: WidgetRenderRequest
    public var seq: Int
    public var producedAt: String
    public var snapshotSource: String
    public var state: WidgetRenderState
    public var unavailableReason: WidgetUnavailableReason?
    public var url: String
    public var appearanceID: String
    public var accessibility: WidgetRenderAccessibility
    public var texts: [String: String]
    public var timeline: WidgetRenderTimeline
    public var composition: WidgetLineComposition?
}

public struct WidgetReloadRequests: Codable, Sendable, Equatable {
    public var total: Int
    public var byCause: [String: Int]

    public init(total: Int = 0, byCause: [String: Int] = [:]) {
        self.total = total
        self.byCause = byCause
    }
}

public struct FullWidgetHookPayload: Encodable, Sendable, Equatable {
    public var outputVersion: Int = 1
    public var renders: [WidgetRenderEntry]
    public var reloadRequests: WidgetReloadRequests
}

@MainActor
public final class SnapshotStore {
    public nonisolated static let appGroupIdentifier = "group.com.takumamatsuura.readingapp"

    public nonisolated static func defaultContainerDirectoryURL() -> URL {
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            return groupURL
        }
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
    }

    public let fileURL: URL
    public private(set) var currentSnapshot: WidgetSnapshot
    public private(set) var reloadTimelineCount: Int = 0
    public private(set) var reloadsByCause: [String: Int] = [:]
    public var requestedSpecs: [WidgetRenderSpec] = [WidgetRenderSpec.defaultSpec]
    /// `UITEST_WIDGET_SNAPSHOT` の差し替え。設定するのはアプリの `#if UITEST_HOOKS` の中だけ（Release は常に nil）。
    public var snapshotOverride: WidgetSnapshotOverride?
    /// このプロセスで組んだ render の番号（h22 の `seq`）。
    private var renderSeq: Int = 0
    /// 最後に組んだ renders と、その入力（入力が同じなら組み直さない。h22 の「最新の1回分」）。
    private var lastRenderKey: RenderKey?
    private var lastRenders: [WidgetRenderEntry] = []

    private struct RenderKey: Equatable {
        var result: WidgetSnapshotReadResult
        var source: String
        var specs: [WidgetRenderSpec]
        var reloadTimelineCount: Int
        var strings: WidgetSpokenStrings
    }

    public init(containerDirectory: URL) {
        let sharedDir = containerDirectory.appendingPathComponent("Shared", isDirectory: true)
        try? FileManager.default.createDirectory(at: sharedDir, withIntermediateDirectories: true)
        self.fileURL = sharedDir.appendingPathComponent("widget-snapshot.json")
        // 前の版の形や壊れた写しは読めない（WidgetSnapshot.decodeAndValidate）。そのときは今の本なしから始め、次の書き込みで直す。
        if FileManager.default.fileExists(atPath: fileURL.path),
           let data = try? Data(contentsOf: fileURL),
           let decoded = try? WidgetSnapshot.decodeAndValidate(from: data) {
            self.currentSnapshot = decoded
        } else {
            self.currentSnapshot = WidgetSnapshot()
        }
    }

    /// `-uitest-widget` の値を読む。読めない1つがあれば、それを返す（呼ぶ側が `hook.error`（`H22:<値>`）にする）。
    @discardableResult
    public func configureSpecs(from raw: String?) -> String? {
        guard let raw, !raw.isEmpty else { return nil }
        switch WidgetRenderSpec.parseList(raw) {
        case .success(let specs):
            requestedSpecs = specs
            return nil
        case .failure(let error):
            return error.value
        }
    }

    public func resetCounts() {
        reloadTimelineCount = 0
        reloadsByCause = [:]
    }

    @discardableResult
    public func writeSnapshot(
        currentBook: BookSnapshot?,
        settings: SettingsSnapshot,
        nowISO: String,
        cause: String?,
        recordReload: Bool,
        reloadOnlyIfChanged: Bool = false
    ) throws -> WidgetSnapshot {

        let snapshot = Self.makeSnapshot(currentBook: currentBook, settings: settings)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(snapshot)
        let dir = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        #if os(iOS)
        // 契約の書き方：Data.write(options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])（ADR 0002）。
        try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        #else
        try data.write(to: fileURL, options: .atomic)
        #endif
        var rv = URLResourceValues()
        rv.isExcludedFromBackup = true
        var mutableURL = fileURL
        try? mutableURL.setResourceValues(rv)

        let changed = currentSnapshot != snapshot
        self.currentSnapshot = snapshot
        // 写しを変えない保存では、reloadOnlyIfChanged のとき再読み込みを求めない（G3 契約 r4 の指揮役の裁定）。
        if recordReload && (!reloadOnlyIfChanged || changed) {
            reloadTimelineCount += 1
            if let cause, !cause.isEmpty {
                reloadsByCause[cause, default: 0] += 1
            }
            #if canImport(WidgetKit)
            WidgetCenter.shared.reloadAllTimelines()
            #endif
        }
        return snapshot
    }

    /// 写しの中身を組む（contracts/widget-snapshot.schema.json の書く側の決まり）。
    /// - 隠す設定のときは進み具合だけ（書名、一行、名無しの本フラグを書かない。ロック中にも読める写しのため）。
    /// - 名無しの今の本は title を書かず isTitlePending を真にする。
    /// - 一行は縮めない全文。範囲の外（書名 1〜100 字、一行 1〜60 字、進み具合）は読む側が読めなくなるので書かない。
    /// - ISBN、著者、本の id、日時、電子書籍フラグは書かない（PRD 12）。
    public nonisolated static func makeSnapshot(currentBook: BookSnapshot?, settings: SettingsSnapshot) -> WidgetSnapshot {
        guard let book = currentBook else {
            return WidgetSnapshot(appearanceID: settings.appearanceID, hideOnWidgets: settings.hideOnWidgets, currentBook: nil)
        }
        let progress = WidgetSnapshotProgress.make(
            unit: book.progressUnit,
            page: book.currentPage,
            location: book.currentLocation,
            percent: book.currentPercent
        )
        let snapshotBook: WidgetSnapshotBook
        if settings.hideOnWidgets {
            snapshotBook = WidgetSnapshotBook(progress: progress)
        } else {
            let title = book.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let line = (book.lastSavedLine ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            snapshotBook = WidgetSnapshotBook(
                title: (book.isTitlePending || !(1...100).contains(title.count)) ? nil : title,
                isTitlePending: book.isTitlePending,
                line: (1...60).contains(line.count) ? line : nil,
                progress: progress
            )
        }
        return WidgetSnapshot(appearanceID: settings.appearanceID, hideOnWidgets: settings.hideOnWidgets, currentBook: snapshotBook)
    }

    /// 読み上げの文（アプリが String Catalog を通した文を入れる。既定は design/ 7 の ja の値）。
    public var spokenStrings: WidgetSpokenStrings = .japanese

    /// 拡張と同じ読み方で写しを読む（差し替えがあればその中身）。H22 の読み出しと撮影用の見本が使う。
    public func readForRender() -> (result: WidgetSnapshotReadResult, source: String) {
        switch snapshotOverride {
        case .none:
            return (WidgetSnapshotReader.read(fileURL: fileURL), "file")
        case .missing:
            return (.unavailable(.missing), "override")
        case .contents(let text):
            return (WidgetSnapshotReader.read(data: Data(text.utf8)), "override")
        }
    }

    /// H22 の読み出しの全体（contracts/hooks/h22-widget.schema.json）。renders は request ごとに、その枠で組む。
    public func fullHookPayload(now: Date = Date()) -> FullWidgetHookPayload {
        let specs = requestedSpecs.isEmpty ? [WidgetRenderSpec.defaultSpec] : requestedSpecs
        let read = readForRender()
        let key = RenderKey(
            result: read.result,
            source: read.source,
            specs: specs,
            reloadTimelineCount: reloadTimelineCount,
            strings: spokenStrings
        )
        if key != lastRenderKey {
            let producedAt = Self.formatProducedAt(now)
            lastRenders = specs.map { spec in
                renderSeq += 1
                return makeRender(spec: spec, seq: renderSeq, producedAt: producedAt, now: now)
            }
            lastRenderKey = key
        }
        return FullWidgetHookPayload(
            renders: lastRenders,
            reloadRequests: WidgetReloadRequests(total: reloadTimelineCount, byCause: reloadsByCause)
        )
    }

    /// 1つの request を組む。elapsedMs は、拡張のタイムラインと同じく写しを読んでから項目を返すまでの実時間。
    private func makeRender(spec: WidgetRenderSpec, seq: Int, producedAt: String, now: Date) -> WidgetRenderEntry {
        let clock = ContinuousClock()
        let start = clock.now
        let read = readForRender()
        let state = WidgetRenderStateResolver.state(for: read.result)
        let plan = WidgetTimelinePlan.make(now: now)
        let strings = spokenStrings
        let snapshot = read.result.snapshot
        let book = snapshot?.currentBook

        var texts: [String: String] = [:]
        var composition: WidgetLineComposition?
        switch state {
        case .unavailable:
            texts["messageKey"] = "widget.unavailable"
            texts["message"] = strings.unavailable
        case .empty:
            texts["messageKey"] = "widget.empty"
            texts["message"] = strings.empty
        case .hidden:
            texts["messageKey"] = "widget.hidden"
            texts["message"] = strings.hidden
            if let page = strings.progressText(book?.progress) { texts["widget.page"] = page }
        case .normal:
            let page = strings.progressText(book?.progress)
            let comp = WidgetLineComposer.compose(
                family: spec.family,
                width: spec.width,
                height: spec.height,
                rawLine: book?.line ?? "",
                pageText: page
            )
            composition = comp
            texts["widget.line"] = comp.displayedLine
            if let page { texts["widget.page"] = page }
        case .noLine, .noLineNoPage:
            if let book {
                texts["widget.title"] = Self.displayTitle(for: book, strings: strings)
                if state == .noLine, let page = strings.progressText(book.progress) { texts["widget.page"] = page }
            }
        }

        let label: String
        if let snapshot {
            label = VerticalLineLayout.buildWidgetAccessibilityLabel(snapshot: snapshot, strings: strings)
        } else {
            label = strings.unavailable
        }
        let entries = plan.entryDates.map { WidgetRenderTimelineEntry(date: Self.formatProducedAt($0), state: state) }
        let policy: WidgetRenderTimelinePolicy
        switch plan.policy {
        case .never: policy = .never
        case .atEnd: policy = .atEnd
        case .after(let date): policy = .after(Self.formatProducedAt(date))
        }
        let elapsed = start.duration(to: clock.now)
        let elapsedMs = Double(elapsed.components.seconds) * 1000 + Double(elapsed.components.attoseconds) / 1e15

        return WidgetRenderEntry(
            request: WidgetRenderRequest(family: spec.family.rawValue, width: spec.width, height: spec.height),
            seq: seq,
            producedAt: producedAt,
            snapshotSource: read.source,
            state: state,
            unavailableReason: read.result.unavailableReason,
            url: spec.family == .systemSmall ? "yomuma://open?entry=small_widget" : "yomuma://open?entry=lock_widget",
            appearanceID: (snapshot?.appearanceID ?? .default).rawValue,
            accessibility: WidgetRenderAccessibility(
                identifier: spec.family == .systemSmall ? "widget.small" : "widget.rectangular",
                label: label,
                // W-1・W-2 の View は全体を `accessibilityRepresentation` の Text 1つに置き換える
                // （ReadingWidgetSurfaceViews.swift の widgetSingleAccessibilityElement）。読み上げのまとまりは常に1つ。
                groupCount: 1
            ),
            texts: texts,
            timeline: WidgetRenderTimeline(entries: entries, policy: policy, elapsedMs: max(elapsedMs, 0)),
            composition: composition
        )
    }

    /// 一行がないときの書名の所（名無しの今の本は widget.currentBookAsTitle の文）。
    private static func displayTitle(for book: WidgetSnapshotBook, strings: WidgetSpokenStrings) -> String {
        if let title = book.title?.trimmingCharacters(in: .whitespacesAndNewlines), !book.isTitlePending, !title.isEmpty { return title }
        return strings.currentBookAsTitle
    }

    /// 読み出す時刻（契約 1-7：UTC の Z とミリ秒）。
    public nonisolated static func formatProducedAt(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    public func formattedReloadsSummary() -> String {
        reloadsByCause.keys.sorted().compactMap { key in
            guard let count = reloadsByCause[key] else { return nil }
            return "\(key):\(count)"
        }.joined(separator: ",")
    }
}
