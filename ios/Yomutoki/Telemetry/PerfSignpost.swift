import os

/// T20 の signpost（contracts/test-hooks.md：subsystem "yomutoki"、category "perf"、区間の名前 "FirstElapsedShown"。OSSignposter。A103）。
/// 始まり：home.startReading、book.startReading、読み始めの error.retry の操作の最初。終わり：その後に reading.elapsed が初めて出たとき。
/// Release にも残す（テストの文字を含まない）。subsystem は Bundle ID と別の固定の文字。
enum PerfSignpost {
    private static let signposter = OSSignposter(subsystem: "yomutoki", category: "perf")
    private static var pending: OSSignpostIntervalState?

    /// 読み始めの操作の最初に呼ぶ。前の区間が終わっていなければ（読み始めの保存の失敗の後）新しい区間で置き換える。
    static func beginFirstElapsedShown() {
        pending = signposter.beginInterval("FirstElapsedShown")
    }

    /// 経過の文字が初めて出たときに呼ぶ。始まりがなければ何もしない（起動して戻したときなど）。
    static func endFirstElapsedShown() {
        guard let state = pending else { return }
        signposter.endInterval("FirstElapsedShown", state)
        pending = nil
    }

    /// 読み始めが通らなかったときに、測る区間を捨てる。
    static func discardFirstElapsedShown() {
        pending = nil
    }
}
