import Foundation
import SwiftUI

/// 計測の送り先（contracts/telemetry.md、ADR 0003）。実装が本番と Debug の2つあるので protocol にする。
/// 送ることで画面を止めない。送り先の失敗は画面に何も出さない（AC-20）。
nonisolated protocol TelemetrySink: Sendable {
    func send(_ event: TelemetryEvent) async
}

/// 本番の送り先：端末の中で、イベント名ごとの回数を UserDefaults の telemetry.localCounts に足すだけ。ネットワークに出ない。
actor LocalCountingTelemetrySink: TelemetrySink {
    private let suiteName: String?

    /// suiteName が nil なら UserDefaults.standard（単体テストは別の suite を渡す）。
    init(suiteName: String? = nil) {
        self.suiteName = suiteName
    }

    func send(_ event: TelemetryEvent) async {
        let defaults = suiteName.flatMap { UserDefaults(suiteName: $0) } ?? UserDefaults.standard
        var counts = defaults.dictionary(forKey: TelemetryFlagKey.localCounts) as? [String: Int] ?? [:]
        counts[event.name, default: 0] += 1
        defaults.set(counts, forKey: TelemetryFlagKey.localCounts)
    }

    /// 数えた回数（単体テストで読む）。
    func counts() -> [String: Int] {
        let defaults = suiteName.flatMap { UserDefaults(suiteName: $0) } ?? UserDefaults.standard
        return defaults.dictionary(forKey: TelemetryFlagKey.localCounts) as? [String: Int] ?? [:]
    }
}

nonisolated struct TelemetrySinkKey: EnvironmentKey {
    static let defaultValue: any TelemetrySink = LocalCountingTelemetrySink()
}

nonisolated extension EnvironmentValues {
    /// 組み立ての場所で決めた送り先。イベントは保存の層（TelemetryRecorder）が出すので、画面が直接送る所は 001 にない。
    var telemetrySink: any TelemetrySink {
        get { self[TelemetrySinkKey.self] }
        set { self[TelemetrySinkKey.self] = newValue }
    }
}
