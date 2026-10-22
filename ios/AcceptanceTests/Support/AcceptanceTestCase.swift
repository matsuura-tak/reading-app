import XCTest

/// 受け入れテストの共通の基底。落ちたテストの直後に、画面の要素の木（app.debugDescription の先頭 diagnosticLineLimit 行）と、
/// 直前のスクリーンショット（AppSession.shot）の有無を標準出力に出す。CI のログだけで落ちた理由を読めるようにするため
/// （CI 807f934 の仕分けでは、ログに画面の様子がなく原因を決められないテストがあった。
/// docs/verification/001-reading-session/ci-runs/807f934-acceptance-en.md の 5）。
/// 落ちた直後の画面のスクリーンショットも添付する（lifetime は keepAlways）。合否は変えない（XCTAssert を足さない）。
/// grep の目印は行頭の「[AT-DIAG]」。
class AcceptanceTestCase: XCTestCase {
    /// 要素の木を出す行数の上限（CI のログの長さを抑える。1本あたり200行）。
    static let diagnosticLineLimit = 200
    /// AppSession.shot が残した最後のスクリーンショットの名前と枚数（落ちたときに出す）。
    var lastShotName: String?
    var shotCount = 0

    override func tearDownWithError() throws {
        if testRun?.hasSucceeded == false {
            let testName = name
            let shotNote = lastShotName.map { "あり（\(shotCount)枚。最後は \($0)）" } ?? "なし"
            let limit = Self.diagnosticLineLimit
            print("[AT-DIAG] 落ちたテスト：\(testName)")
            print("[AT-DIAG] 直前のスクリーンショット（AppSession.shot）：\(shotNote)")
            // UI テストの tearDown は主スレッドで呼ばれる。XCUIApplication は MainActor なので、その上で動いていると宣言して使う。
            // self を閉包に持ち込まないよう、Sendable な値（文字と PNG）だけを返し、添付は閉包の外で行う。
            let snapshot: (state: String, lines: [String], png: Data?) = MainActor.assumeIsolated {
                let app = XCUIApplication()
                switch app.state {
                case .notRunning, .unknown:
                    return ("動いていない（rawValue=\(app.state.rawValue)）", [], nil)
                default:
                    let png = app.screenshot().pngRepresentation
                    let lines = app.debugDescription.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
                    return ("動いている（rawValue=\(app.state.rawValue)）", lines, png)
                }
            }
            print("[AT-DIAG] アプリ：\(snapshot.state)")
            if let png = snapshot.png {
                let attachment = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
                attachment.name = "FAIL_\(testName)"
                attachment.lifetime = .keepAlways
                add(attachment)
                print("[AT-DIAG] 落ちた直後のスクリーンショットを添付した：FAIL_\(testName)")
            }
            if !snapshot.lines.isEmpty {
                print("[AT-DIAG] 要素の木（先頭 \(min(snapshot.lines.count, limit)) 行／全 \(snapshot.lines.count) 行）")
                for line in snapshot.lines.prefix(limit) {
                    print("[AT-DIAG] \(line)")
                }
            }
        }
        try super.tearDownWithError()
    }
}
