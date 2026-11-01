import Foundation
import Observation

/// 読み込みの「実行時の門」（contracts/test-hooks.md 1-1 の例外、H33）。
///
/// 読み込みの関数は、読み込みに入る所で `pass(_:)` を待つ。既定は止める対象が空なので、すぐに返る（素通り）。
/// 止める対象を `arm(_:)` で設定し、`release(_:)` で放すのは、アプリの `#if UITEST_HOOKS` の中だけ。
/// Release には設定する入口がないため、門は常に素通りする。型と関数の名前は `UITestHook` で始めない（ADR 0005）。
@MainActor
@Observable
public final class LoadHoldGate {
    public enum Point: String, CaseIterable, Sendable {
        case storeLoad = "store.load"
        case shelfLoad = "shelf.load"
        case bookLoad = "book.load"
        case recommendLoad = "recommend.load"
        case catalogLookup = "catalog.lookup"
        case storekitProducts = "storekit.products"
        case storekitPurchase = "storekit.purchase"
        case storekitRestore = "storekit.restore"

        /// `yomuma.uitest.load.release` の状態の番号（H33 の表）。
        public var releaseNumber: UInt64 {
            UInt64((Point.allCases.firstIndex(of: self) ?? 0) + 1)
        }
    }

    public enum Phase: String, Sendable {
        case waiting, held, shown, released
    }

    public private(set) var phases: [Point: Phase] = [:]
    @ObservationIgnored private var armed: Set<Point> = []
    @ObservationIgnored private var continuations: [Point: CheckedContinuation<Void, Never>] = [:]

    public init() {}

    /// その対象の次の読み込みを止めるか（止めるなら、画面は読み込み中の形で始める）。
    public func willHold(_ point: Point) -> Bool {
        armed.contains(point) || phases[point] == .held || phases[point] == .shown
    }

    /// 止めている最中か。
    public func isHolding(_ point: Point) -> Bool {
        phases[point] == .held || phases[point] == .shown
    }

    /// 門。止める対象でなければ、すぐに返る。止める対象なら、放されるまで待つ（最初の1回だけ）。
    public func pass(_ point: Point) async {
        guard armed.remove(point) != nil else { return }
        phases[point] = .held
        await withCheckedContinuation { continuation in
            continuations[point] = continuation
        }
    }

    /// 読み込み中の形を画面に出した。
    public func markShown(_ point: Point) {
        guard phases[point] == .held else { return }
        phases[point] = .shown
    }

    /// 止める対象を設定する（アプリの #if UITEST_HOOKS の中だけから呼ぶ）。
    public func arm(_ points: Set<Point>) {
        armed = points
        for point in points {
            phases[point] = .waiting
        }
    }

    /// 放す。nil はすべて。止めていない対象は無視する。
    public func release(_ point: Point?) {
        let targets = point.map { [$0] } ?? Array(continuations.keys)
        for target in targets {
            guard let continuation = continuations.removeValue(forKey: target) else { continue }
            phases[target] = .released
            continuation.resume()
        }
    }
}
