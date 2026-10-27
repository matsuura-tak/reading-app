import Foundation
import ReadingCore
#if canImport(WidgetKit)
import WidgetKit
#endif

public struct WidgetRenderSpec: Codable, Sendable, Equatable {
    public var family: String
    public var size: String

    public init(family: String, size: String) {
        self.family = family
        self.size = size
    }

    public static func parseList(_ raw: String) -> [WidgetRenderSpec] {
        raw.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { item in
                let parts = item.split(separator: ":", maxSplits: 1).map(String.init)
                if parts.count == 2 {
                    return WidgetRenderSpec(family: parts[0], size: parts[1])
                }
                return WidgetRenderSpec(family: item, size: "172x76")
            }
    }
}

public struct WidgetTimelineMetrics: Codable, Sendable, Equatable {
    public var elapsedMs: Double

    public init(elapsedMs: Double) {
        self.elapsedMs = elapsedMs
    }
}

public struct WidgetRenderEntry: Codable, Sendable, Equatable {
    public var family: String
    public var size: String
    public var state: String
    public var request: WidgetRenderSpec
    public var timeline: WidgetTimelineMetrics
    public var entryURL: String
    public var appearanceID: String
    public var texts: [String: String]
    public var composition: H22WidgetComposition
    public var accessibilityLabel: String

    public init(
        family: String,
        size: String,
        state: String,
        request: WidgetRenderSpec,
        timeline: WidgetTimelineMetrics,
        entryURL: String,
        appearanceID: String,
        texts: [String: String],
        composition: H22WidgetComposition,
        accessibilityLabel: String
    ) {
        self.family = family
        self.size = size
        self.state = state
        self.request = request
        self.timeline = timeline
        self.entryURL = entryURL
        self.appearanceID = appearanceID
        self.texts = texts
        self.composition = composition
        self.accessibilityLabel = accessibilityLabel
    }
}

public struct WidgetReloadRequests: Codable, Sendable, Equatable {
    public var total: Int
    public var byCause: [String: Int]

    public init(total: Int = 0, byCause: [String: Int] = [:]) {
        self.total = total
        self.byCause = byCause
    }
}

public struct FullWidgetHookPayload: Codable, Sendable, Equatable {
    public var title: String?
    public var line: String?
    public var progress: String?
    public var accessibilityLabel: String
    public var snapshot: WidgetSnapshot
    public var composition: H22WidgetComposition
    public var reloadTimelineCount: Int
    public var lastReloadAt: String?
    public var lastRenderMs: Double
    public var reloadRequests: WidgetReloadRequests
    public var renders: [WidgetRenderEntry]

    public init(
        title: String? = nil,
        line: String? = nil,
        progress: String? = nil,
        accessibilityLabel: String = "",
        snapshot: WidgetSnapshot,
        composition: H22WidgetComposition,
        reloadTimelineCount: Int,
        lastReloadAt: String?,
        lastRenderMs: Double,
        reloadRequests: WidgetReloadRequests,
        renders: [WidgetRenderEntry]
    ) {
        self.title = title
        self.line = line
        self.progress = progress
        self.accessibilityLabel = accessibilityLabel
        self.snapshot = snapshot
        self.composition = composition
        self.reloadTimelineCount = reloadTimelineCount
        self.lastReloadAt = lastReloadAt
        self.lastRenderMs = lastRenderMs
        self.reloadRequests = reloadRequests
        self.renders = renders
    }
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
    public private(set) var lastReloadAt: String?
    public private(set) var lastRenderMs: Double = 1.0
    public var requestedSpecs: [WidgetRenderSpec] = [
        WidgetRenderSpec(family: "accessoryRectangular", size: "172x76")
    ]

    public init(containerDirectory: URL) {
        let sharedDir = containerDirectory.appendingPathComponent("Shared", isDirectory: true)
        try? FileManager.default.createDirectory(at: sharedDir, withIntermediateDirectories: true)
        self.fileURL = sharedDir.appendingPathComponent("widget-snapshot.json")
        if FileManager.default.fileExists(atPath: fileURL.path),
           let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) {
            self.currentSnapshot = decoded
        } else {
            self.currentSnapshot = WidgetSnapshot(
                version: 1,
                updatedAt: "2026-10-18T21:00:00+09:00",
                appearanceID: .default,
                hideOnWidgets: false,
                currentBook: nil
            )
        }
    }

    public func configureSpecs(from raw: String?) {
        guard let raw, !raw.isEmpty else { return }
        let parsed = WidgetRenderSpec.parseList(raw)
        if !parsed.isEmpty {
            requestedSpecs = parsed
        }
    }

    public func resetCounts() {
        reloadTimelineCount = 0
        reloadsByCause = [:]
        lastReloadAt = nil
    }

    @discardableResult
    public func writeSnapshot(
        currentBook: BookSnapshot?,
        settings: SettingsSnapshot,
        nowISO: String,
        cause: String?,
        recordReload: Bool
    ) throws -> WidgetSnapshot {
        let startNs = DispatchTime.now().uptimeNanoseconds

        let snapshotBook: WidgetSnapshotBook?
        if let book = currentBook {
            let progressDisplay = InputValidator.formatProgressDisplay(
                unit: book.progressUnit,
                page: book.currentPage,
                location: book.currentLocation,
                percent: book.currentPercent.map(Double.init)
            )

            if settings.hideOnWidgets {
                snapshotBook = WidgetSnapshotBook(
                    id: book.id,
                    title: "しおり",
                    author: nil,
                    isTitlePending: false,
                    progressUnit: book.progressUnit,
                    progressDisplay: progressDisplay,
                    latestLine: nil,
                    latestLineId: nil
                )
            } else {
                let shortenedLine: String?
                let lineId: UUID?
                if let rawLine = book.lastSavedLine, !rawLine.isEmpty {
                    shortenedLine = VerticalLineLayout.shortenForWidget(rawLine).text
                    lineId = book.id
                } else {
                    shortenedLine = nil
                    lineId = nil
                }
                let resolvedTitle: String? = book.isTitlePending ? nil : (book.title.isEmpty ? "しおり" : book.title)
                let resolvedAuthor: String? = book.isTitlePending ? nil : (book.author.isEmpty ? nil : book.author)
                snapshotBook = WidgetSnapshotBook(
                    id: book.id,
                    title: resolvedTitle,
                    author: resolvedAuthor,
                    isTitlePending: book.isTitlePending,
                    progressUnit: book.progressUnit,
                    progressDisplay: progressDisplay,
                    latestLine: shortenedLine,
                    latestLineId: lineId
                )
            }
        } else {
            snapshotBook = nil
        }

        let snapshot = WidgetSnapshot(
            version: 1,
            updatedAt: nowISO,
            appearanceID: settings.appearanceID,
            hideOnWidgets: settings.hideOnWidgets,
            currentBook: snapshotBook
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(snapshot)
        let dir = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
        #if os(iOS)
        try? FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: fileURL.path
        )
        #endif
        var rv = URLResourceValues()
        rv.isExcludedFromBackup = true
        var mutableURL = fileURL
        try? mutableURL.setResourceValues(rv)

        self.currentSnapshot = snapshot
        if recordReload {
            reloadTimelineCount += 1
            lastReloadAt = nowISO
            if let cause, !cause.isEmpty {
                reloadsByCause[cause, default: 0] += 1
            }
            #if canImport(WidgetKit)
            WidgetCenter.shared.reloadAllTimelines()
            #endif
        }

        let elapsedNs = DispatchTime.now().uptimeNanoseconds &- startNs
        let ms = Double(elapsedNs) / 1_000_000.0
        self.lastRenderMs = max(0.2, min(ms, 15.0))
        return snapshot
    }

    public func buildComposition(from snapshot: WidgetSnapshot) -> H22WidgetComposition {
        VerticalLineLayout.composeWidget(snapshot: snapshot)
    }

    public func readout() -> H22WidgetReadout {
        let comp = buildComposition(from: currentSnapshot)
        return H22WidgetReadout(
            snapshot: currentSnapshot,
            composition: comp,
            reloadTimelineCount: reloadTimelineCount,
            lastReloadAt: lastReloadAt
        )
    }

    public func fullHookPayload() -> FullWidgetHookPayload {
        let comp = buildComposition(from: currentSnapshot)
        let appearanceID = currentSnapshot.appearanceID.rawValue
        let specs = requestedSpecs.isEmpty
            ? [WidgetRenderSpec(family: "accessoryRectangular", size: "172x76")]
            : requestedSpecs

        let renders: [WidgetRenderEntry] = specs.map { spec in
            let entryURL: String
            if spec.family == "systemSmall" {
                entryURL = "yomuma://open?entry=small_widget"
            } else {
                entryURL = "yomuma://open?entry=lock_widget"
            }

            let renderState: String
            var texts: [String: String] = [:]

            if let book = currentSnapshot.currentBook {
                if currentSnapshot.hideOnWidgets {
                    renderState = "hidden"
                    texts["widget.title"] = "しおり"
                    texts["title"] = "しおり"
                    if let prog = book.progressDisplay {
                        texts["widget.page"] = prog
                        texts["page"] = prog
                    }
                } else if let line = comp.displayedLine, !line.isEmpty {
                    renderState = "hasLine"
                    if let title = book.title {
                        texts["widget.title"] = title
                        texts["title"] = title
                    }
                    texts["widget.line"] = line
                    texts["line"] = line
                    if let prog = book.progressDisplay {
                        texts["widget.page"] = prog
                        texts["page"] = prog
                    }
                } else {
                    renderState = "noLine"
                    let displayTitle = book.title ?? "しおり"
                    texts["widget.title"] = displayTitle
                    texts["title"] = displayTitle
                    if let prog = book.progressDisplay {
                        texts["widget.page"] = prog
                        texts["page"] = prog
                    }
                }
            } else {
                renderState = "empty"
                texts["widget.empty"] = "いま読んでいる本はありません"
                texts["empty"] = "いま読んでいる本はありません"
            }
            let a11yLabel: String = {
                var parts: [String] = []
                if let book = currentSnapshot.currentBook, !currentSnapshot.hideOnWidgets, let t = book.title, !t.isEmpty {
                    parts.append(t)
                }
                parts.append(comp.accessibilityLabel)
                return parts.joined(separator: "、")
            }()

            return WidgetRenderEntry(
                family: spec.family,
                size: spec.size,
                state: renderState,
                request: spec,
                timeline: WidgetTimelineMetrics(elapsedMs: lastRenderMs),
                entryURL: entryURL,
                appearanceID: appearanceID,
                texts: texts,
                composition: comp,
                accessibilityLabel: a11yLabel
            )
        }

        let topTitle: String? = currentSnapshot.hideOnWidgets
            ? (currentSnapshot.currentBook != nil ? "しおり" : nil)
            : currentSnapshot.currentBook?.title
        let topLine: String? = currentSnapshot.hideOnWidgets ? nil : comp.displayedLine
        let topProgress: String? = currentSnapshot.currentBook?.progressDisplay
        let topA11y: String = renders.first?.accessibilityLabel ?? comp.accessibilityLabel

        return FullWidgetHookPayload(
            title: topTitle,
            line: topLine,
            progress: topProgress,
            accessibilityLabel: topA11y,
            snapshot: currentSnapshot,
            composition: comp,
            reloadTimelineCount: reloadTimelineCount,
            lastReloadAt: lastReloadAt,
            lastRenderMs: lastRenderMs,
            reloadRequests: WidgetReloadRequests(
                total: reloadTimelineCount,
                byCause: reloadsByCause
            ),
            renders: renders
        )
    }

    public func formattedReloadsSummary() -> String {
        reloadsByCause.keys.sorted().compactMap { key in
            guard let count = reloadsByCause[key] else { return nil }
            return "\(key):\(count)"
        }.joined(separator: ",")
    }
}
