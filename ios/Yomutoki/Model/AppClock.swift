import Foundation
import SwiftUI

/// 今の時刻を返す値（設計メモ 3、11 の 7）。Swift 標準の Clock とぶつけないため AppClock と呼ぶ。
/// Date() を直接呼ぶのはここと Debug/ の中だけ。ほかは組み立ての場所で入れたこの値から読む（テストのつなぎ口 T3、T16 が効くように）。
/// Debug の差し替え（起動のときの今、止める、進める）は Debug/UITestHooks.swift の ClockController が作る（ADR 0005）。
nonisolated struct AppClock: Sendable {
    var now: @Sendable () -> Date

    init(now: @escaping @Sendable () -> Date) {
        self.now = now
    }

    /// 端末の時計。
    static let system = AppClock(now: { Date() })

    /// 決まった時刻を返し続ける（プレビューと単体テスト用）。
    static func fixed(_ date: Date) -> AppClock {
        AppClock(now: { date })
    }
}

nonisolated struct AppClockKey: EnvironmentKey {
    static let defaultValue = AppClock.system
}

nonisolated extension EnvironmentValues {
    /// 画面が経過を計算するときの時計。暦（calendar、timeZone、locale）は SwiftUI の環境の値をそのまま使う。
    var appClock: AppClock {
        get { self[AppClockKey.self] }
        set { self[AppClockKey.self] = newValue }
    }
}
