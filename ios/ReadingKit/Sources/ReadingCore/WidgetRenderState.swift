import Foundation

// W-1・W-2 の状態（ADR 0003、contracts/test-hooks.md H22「出力」の state と texts の表）と、写しの読み方
// （contracts/widget-snapshot.schema.json の読む側の決まり）。拡張、アプリの中の見本、H22 の読み出しが同じ関数を使う。

public enum WidgetRenderState: String, Sendable, Equatable, Codable, CaseIterable {
    case normal
    case noLine
    case noLineNoPage
    case hidden
    case empty
    case unavailable
}

/// 写しを読めない理由（h22 の `unavailableReason`）。
public enum WidgetUnavailableReason: String, Sendable, Equatable, Codable, CaseIterable {
    case missing
    case unopenable
    case malformed
    case version
    case range
    case hiddenConflict
}

/// 写しを読んだ結果。
public enum WidgetSnapshotReadResult: Sendable, Equatable {
    case readable(WidgetSnapshot)
    case unavailable(WidgetUnavailableReason)

    public var snapshot: WidgetSnapshot? {
        if case .readable(let snapshot) = self { return snapshot }
        return nil
    }

    public var unavailableReason: WidgetUnavailableReason? {
        if case .unavailable(let reason) = self { return reason }
        return nil
    }
}

public enum WidgetSnapshotReader {
    /// ファイルを読む。ファイルがなければ `missing`、開けなければ `unopenable`。
    public nonisolated static func read(fileURL: URL) -> WidgetSnapshotReadResult {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return .unavailable(.missing)
        }
        guard let data = try? Data(contentsOf: fileURL) else {
            return .unavailable(.unopenable)
        }
        return read(data: data)
    }

    /// 読んだ中身を確かめる。
    public nonisolated static func read(data: Data) -> WidgetSnapshotReadResult {
        do {
            return .readable(try WidgetSnapshot.decodeAndValidate(from: data))
        } catch {
            return .unavailable(reason(for: error, data: data))
        }
    }

    nonisolated static func reason(for error: WidgetSnapshotValidationError, data: Data) -> WidgetUnavailableReason {
        switch error {
        case .malformedJSON:
            return .malformed
        case .unsupportedVersion:
            return .version
        case .fieldConstraintViolation:
            return .range
        case .privacyInvariantViolation:
            return .hiddenConflict
        case .titlePendingInvariantViolation:
            // 名無しなのに書名がある（7）は h22 の enum にないので malformed（G3 r2 の指揮役の裁定 3）。
            return .malformed
        }
    }
}

public enum WidgetRenderStateResolver {
    /// 写しから状態を決める（上から順に当てはまった最初の行）。
    public nonisolated static func state(for result: WidgetSnapshotReadResult) -> WidgetRenderState {
        guard case .readable(let snapshot) = result else { return .unavailable }
        return state(for: snapshot)
    }

    public nonisolated static func state(for snapshot: WidgetSnapshot) -> WidgetRenderState {
        guard let book = snapshot.currentBook else { return .empty }
        if snapshot.hideOnWidgets { return .hidden }
        if let line = book.line, !line.isEmpty { return .normal }
        if book.progress != nil { return .noLine }
        return .noLineNoPage
    }
}

/// タイムラインの更新の決まり（拡張の `TimelineProvider` と H22 の `timeline` が同じ値を使う）。
public enum WidgetTimelinePolicy: Sendable, Equatable {
    /// 次の項目を求めない（アプリが写しを書いたときの再読み込みだけで変わる）。
    case never
    case atEnd
    case after(Date)
}

public enum WidgetTimelinePlan {
    /// 項目の時刻（いまの1件）と更新の決まり。
    public nonisolated static func make(now: Date) -> (entryDates: [Date], policy: WidgetTimelinePolicy) {
        ([now], .never)
    }
}
