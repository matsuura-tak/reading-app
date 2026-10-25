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
        if let testRun, testRun.totalFailureCount > 0 {
            let testName = name
            let shotNote = lastShotName.map { "あり（\(shotCount)枚。最後は \($0)）" } ?? "なし"
            let limit = Self.diagnosticLineLimit
            print("[AT-DIAG] 落ちたテスト：\(testName)")
            // xcodebuild はログに構成（ja_JP／en_US）の名前を出さないので、どの回で落ちたかを run-acceptance.sh の要約が結べるように出す
            // （ci-runs/c9e7427-acceptance.md の 3）。
            let lang = ProcessInfo.processInfo.environment["ACCEPTANCE_LANG"] ?? "なし"
            print("[AT-DIAG] 構成：ACCEPTANCE_LANG=\(lang)")
            print("[AT-DIAG] 直前のスクリーンショット（AppSession.shot）：\(shotNote)")
            // UI テストの tearDown は主スレッドで呼ばれる。XCUIApplication は MainActor なので、その上で動いていると宣言して使う。
            // self を閉包に持ち込まないよう、Sendable な値（文字と PNG）だけを返し、添付は閉包の外で行う。
            let snapshot: (state: String, lines: [String], png: Data?, systemAlerts: [String]) = MainActor.assumeIsolated {
                let app = XCUIApplication()
                // システムのダイアログ（T16 の「開く」の確かめなど）はアプリの要素の木に入らないので、SpringBoard の alert を別に見る
                // （ci-runs/c9e7427-acceptance.md の 4 の見立て (i)）。
                let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
                let systemAlerts: [String] = springboard.alerts.allElementsBoundByIndex.prefix(3).map { alert in
                    let buttons = alert.buttons.allElementsBoundByIndex.map { $0.label }.joined(separator: "／")
                    return "「\(alert.label)」 ボタン：\(buttons)"
                }
                switch app.state {
                case .notRunning, .unknown:
                    return ("動いていない（rawValue=\(app.state.rawValue)）", [], nil, systemAlerts)
                default:
                    let png = app.screenshot().pngRepresentation
                    let lines = app.debugDescription.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
                    return ("動いている（rawValue=\(app.state.rawValue)）", lines, png, systemAlerts)
                }
            }
            let alertNote = snapshot.systemAlerts.isEmpty ? "なし" : snapshot.systemAlerts.joined(separator: "、")
            print("[AT-DIAG] システムのダイアログ（SpringBoard の alert、3つまで）：\(alertNote)")
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
