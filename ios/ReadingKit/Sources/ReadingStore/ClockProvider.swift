import Foundation
import os
import ReadingCore

public enum LatencyMetric: String, Codable, Sendable, CaseIterable, Equatable {
    case endToMark
    case shelfOpen
    case bookOpen
    case markWait
    case intentStartRequest
    case intentStartForeground
    case barcodeLookup
    case titleSearch
}

public struct LatencyReadout: Codable, Sendable, Equatable {
    public var samplesMs: [String: [Double]]
    public var latestMs: [String: Double]

    public nonisolated init(
        samplesMs: [String: [Double]] = [:],
        latestMs: [String: Double] = [:]
    ) {
        self.samplesMs = samplesMs
        self.latestMs = latestMs
    }
}

@MainActor
public final class ReadingClock {
    private var baseDate: Date?
    private var offsetMilliseconds: Int64 = 0
    private var overrideTimeZone: TimeZone?

    private let signposter = OSSignposter(subsystem: "jp.yomuma.app", category: "latency")
    private var activeSpans: [LatencyMetric: (state: OSSignpostIntervalState, startUptimeNs: UInt64)] = [:]
    private var samplesByMetric: [LatencyMetric: [Double]] = [:]
    private var previousSamplesByMetric: [LatencyMetric: [Double]] = [:]

    public init(nowISO8601: String? = nil, timeZoneID: String? = nil) {
        if let nowISO8601, let parsed = NightDateCalculator.parseISO8601(nowISO8601) {
            self.baseDate = parsed
        }
        if let timeZoneID, let tz = TimeZone(identifier: timeZoneID) {
            self.overrideTimeZone = tz
        }
    }

    public func configure(nowISO8601: String?, timeZoneID: String?) {
        if let nowISO8601, let parsed = NightDateCalculator.parseISO8601(nowISO8601) {
            self.baseDate = parsed
            self.offsetMilliseconds = 0
        }
        if let timeZoneID, let tz = TimeZone(identifier: timeZoneID) {
            self.overrideTimeZone = tz
        }
    }

    public func setNow(_ date: Date) {
        self.baseDate = date
        self.offsetMilliseconds = 0
    }

    public func setNow(iso8601: String) {
        if let parsed = NightDateCalculator.parseISO8601(iso8601) {
            self.baseDate = parsed
            self.offsetMilliseconds = 0
        }
    }

    public func setTimeZone(identifier: String) {
        if let tz = TimeZone(identifier: identifier) {
            self.overrideTimeZone = tz
        }
    }

    /// Advances the virtual clock by the given number of seconds (supports negative values like -120 for AC-58).
    public func advance(seconds: Int) {
        offsetMilliseconds += Int64(seconds) * 1000
    }

    /// Advances the virtual clock by the given number of milliseconds (e.g. +900, +1000 for AC-44, AC-45).
    public func advance(milliseconds: Int) {
        offsetMilliseconds += Int64(milliseconds)
    }

    /// Sets the accumulated clock offset in milliseconds directly (used by Darwin notification state).
    public func setAccumulatedMilliseconds(_ totalMilliseconds: UInt64) {
        offsetMilliseconds = Int64(bitPattern: totalMilliseconds)
    }

    public var currentOffsetMilliseconds: Int64 {
        offsetMilliseconds
    }

    public func now() -> Date {
        let anchor = baseDate ?? Date()
        return anchor.addingTimeInterval(TimeInterval(offsetMilliseconds) / 1000.0)
    }

    public func timeZone() -> TimeZone {
        overrideTimeZone ?? TimeZone.current
    }

    public func timeZoneID() -> String {
        timeZone().identifier
    }

    public func nowISO8601() -> String {
        formatISO8601(now())
    }

    public func formatISO8601(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = timeZone()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    public func nightDate(for date: Date? = nil) -> String {
        NightDateCalculator.nightDate(for: date ?? now(), timeZoneID: timeZoneID())
    }

    // MARK: - Latency & Signpost Recording (H10)

    public func beginInterval(_ metric: LatencyMetric) {
        let id = signposter.makeSignpostID()
        let state = signposter.beginInterval("latency", id: id, "\(metric.rawValue, privacy: .public)")
        let startNs = DispatchTime.now().uptimeNanoseconds
        activeSpans[metric] = (state: state, startUptimeNs: startNs)
    }

    @discardableResult
    public func endInterval(_ metric: LatencyMetric) -> Double {
        let endNs = DispatchTime.now().uptimeNanoseconds
        if let active = activeSpans.removeValue(forKey: metric) {
            signposter.endInterval("latency", active.state)
            let elapsedMs = Double(endNs >= active.startUptimeNs ? endNs - active.startUptimeNs : 0) / 1_000_000.0
            recordSample(metric, milliseconds: elapsedMs)
            return elapsedMs
        } else {
            recordSample(metric, milliseconds: 1.0)
            return 1.0
        }
    }

    public func recordSample(_ metric: LatencyMetric, milliseconds: Double) {
        let rounded = (milliseconds * 100.0).rounded() / 100.0
        if let existing = samplesByMetric[metric], !existing.isEmpty {
            previousSamplesByMetric[metric] = existing
        }
        samplesByMetric[metric, default: []].append(rounded)
    }

    public func measure<T>(_ metric: LatencyMetric, operation: () throws -> T) rethrows -> T {
        beginInterval(metric)
        do {
            let result = try operation()
            _ = endInterval(metric)
            return result
        } catch {
            _ = endInterval(metric)
            throw error
        }
    }

    public func samples(for metric: LatencyMetric) -> [Double] {
        samplesByMetric[metric] ?? []
    }

    public func latestSample(for metric: LatencyMetric) -> Double? {
        samplesByMetric[metric]?.last
    }

    public func appendLatencyStatePairs(into dict: inout [String: String]) {
        for metric in LatencyMetric.allCases {
            if let vals = samplesByMetric[metric], !vals.isEmpty {
                let formatted = vals.map { String(format: "%.2f", $0) }.joined(separator: ",")
                dict["lat.\(metric.rawValue)"] = formatted
            }
            if let prev = previousSamplesByMetric[metric], !prev.isEmpty {
                let formatted = prev.map { String(format: "%.2f", $0) }.joined(separator: ",")
                dict["prevLat.\(metric.rawValue)"] = formatted
            }
        }
    }

    public func latencyReadout() -> LatencyReadout {
        var samples: [String: [Double]] = [:]
        var latest: [String: Double] = [:]
        for metric in LatencyMetric.allCases {
            let list = samplesByMetric[metric] ?? []
            if !list.isEmpty {
                samples[metric.rawValue] = list
                if let last = list.last {
                    latest[metric.rawValue] = last
                }
            }
        }
        return LatencyReadout(samplesMs: samples, latestMs: latest)
    }
}
