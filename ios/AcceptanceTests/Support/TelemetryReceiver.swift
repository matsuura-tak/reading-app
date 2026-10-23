import Foundation
// @preconcurrency：SDK の版によっては Network の型（NWListener、NWConnection など）の Sendable の注釈がそろっておらず、
// Swift 6 の言語モード（target.yml の SWIFT_VERSION 6.0）でハンドラーの閉包が誤りになることがあるため、警告に下げる。
// 並行の安全は、下の TelemetryReceiver の lock と直列の queue で守る。
@preconcurrency import Network
import XCTest

/// 計測の受け口（contracts/telemetry.md の「テストの受け口」、test-hooks.md の T6、T7、T13、T19）。
/// テストの側に NWListener（A47）で localhost の HTTP の受け口を立て、POST /events と POST /flushed を受ける。
/// 127.0.0.1 は使わない（A48）。アプリには http://localhost:<port> を渡す。
/// @unchecked Sendable の理由：NWListener と NWConnection のハンドラーは queue（直列）から呼ばれ、テストの側（MainActor）からも
/// requests などを読む。可変の状態（listener、connections、received、boundPort）は、すべて lock の中で読み書きする。
/// mode、queue、lock は let。これをコンパイラーに示す方法がないので、@unchecked にして lock で守る。
final class TelemetryReceiver: @unchecked Sendable {
    enum Mode: Sendable {
        /// 204 を返す
        case ok
        /// 500 を返す（AC-20）
        case status500
        /// 接続を受けたまま返さず、30秒たったら閉じる（AC-20。T19 の「verifier の受け口の動き」）
        case hang
    }

    struct Request: Sendable {
        let method: String
        let path: String
        /// 受け取った要求のバイト列すべて（要求行、ヘッダー、本文）
        let raw: Data
        let body: Data
    }

    enum ReceiverError: Error {
        case notReady
    }

    let mode: Mode
    private let queue = DispatchQueue(label: "acceptance.telemetry.receiver")
    private let lock = NSLock()
    private var listener: NWListener?
    private var connections: [NWConnection] = []
    private var received: [Request] = []
    private var boundPort: UInt16 = 0

    init(mode: Mode) {
        self.mode = mode
    }

    /// 待ち受けを始め、準備ができるまで待つ。
    func start(timeout: TimeInterval) throws {
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        let newListener = try NWListener(using: parameters, on: .any)
        let ready = XCTestExpectation(description: "受け口が待ち受けを始めた")
        ready.assertForOverFulfill = false
        newListener.stateUpdateHandler = { state in
            if case .ready = state { ready.fulfill() }
        }
        newListener.newConnectionHandler = { [weak self] connection in
            self?.accept(connection)
        }
        lock.lock()
        listener = newListener
        lock.unlock()
        newListener.start(queue: queue)
        guard XCTWaiter.wait(for: [ready], timeout: timeout) == .completed, let port = newListener.port?.rawValue else {
            throw ReceiverError.notReady
        }
        lock.lock()
        boundPort = port
        lock.unlock()
    }

    func stop() {
        lock.lock()
        let open = connections
        let current = listener
        connections = []
        lock.unlock()
        current?.cancel()
        open.forEach { $0.cancel() }
    }

    var baseURL: String {
        lock.lock()
        defer { lock.unlock() }
        return "http://localhost:\(boundPort)"
    }

    var requests: [Request] {
        lock.lock()
        defer { lock.unlock() }
        return received
    }

    /// POST /events の本文（イベント1件ずつ。telemetry-events.schema.json）。
    var eventBodies: [Data] {
        requests.filter { $0.path.hasSuffix("/events") }.map(\.body)
    }

    /// POST /flushed の sent + failed のいちばん大きい値（起動してからの累計。T13）。
    var flushedTotals: (sent: Int, failed: Int)? {
        var best: (sent: Int, failed: Int)?
        for request in requests where request.path.hasSuffix("/flushed") {
            guard let object = try? JSONSerialization.jsonObject(with: request.body) as? [String: Any],
                let sent = object["sent"] as? Int, let failed = object["failed"] as? Int
            else { continue }
            if best == nil || sent + failed > best!.sent + best!.failed { best = (sent, failed) }
        }
        return best
    }

    var flushedCount: Int {
        guard let totals = flushedTotals else { return 0 }
        return totals.sent + totals.failed
    }

    // MARK: HTTP（要求1つを読み、決まった応答を返して閉じる）

    private func accept(_ connection: NWConnection) {
        lock.lock()
        connections.append(connection)
        lock.unlock()
        connection.start(queue: queue)
        receive(on: connection, buffer: Data())
    }

    private func receive(on connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1 << 16) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            var next = buffer
            if let data { next.append(data) }
            if let request = TelemetryReceiver.parse(next) {
                self.lock.lock()
                self.received.append(request)
                self.lock.unlock()
                self.respond(on: connection)
                return
            }
            if isComplete || error != nil {
                connection.cancel()
                return
            }
            self.receive(on: connection, buffer: next)
        }
    }

    private func respond(on connection: NWConnection) {
        switch mode {
        case .ok:
            send("HTTP/1.1 204 No Content", on: connection)
        case .status500:
            send("HTTP/1.1 500 Internal Server Error", on: connection)
        case .hang:
            queue.asyncAfter(deadline: .now() + 30) { connection.cancel() }
        }
    }

    private func send(_ statusLine: String, on connection: NWConnection) {
        let text = "\(statusLine)\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
        connection.send(content: Data(text.utf8), completion: .contentProcessed { _ in connection.cancel() })
    }

    static func parse(_ buffer: Data) -> Request? {
        guard let headerEnd = buffer.range(of: Data("\r\n\r\n".utf8)) else { return nil }
        let head = String(decoding: buffer[buffer.startIndex..<headerEnd.lowerBound], as: UTF8.self)
        let lines = head.components(separatedBy: "\r\n")
        let requestLine = (lines.first ?? "").split(separator: " ")
        guard requestLine.count >= 2 else { return nil }
        var length = 0
        for header in lines.dropFirst() {
            let pair = header.split(separator: ":", maxSplits: 1)
            if pair.count == 2, pair[0].trimmingCharacters(in: .whitespaces).lowercased() == "content-length" {
                length = Int(pair[1].trimmingCharacters(in: .whitespaces)) ?? 0
            }
        }
        let bodyStart = headerEnd.upperBound
        guard buffer.distance(from: bodyStart, to: buffer.endIndex) >= length else { return nil }
        let body = Data(buffer[bodyStart..<buffer.index(bodyStart, offsetBy: length)])
        return Request(method: String(requestLine[0]), path: String(requestLine[1]), raw: buffer, body: body)
    }
}

/// 受け口に届いたもの（または T22 の uitest.telemetry.log）をまとめたもの。
struct TelemetrySnapshot {
    /// イベント（telemetry-events.schema.json の形。届いた順）
    var events: [[String: Any]]
    /// 届いたものの全体（HTTP の要求のバイト列か、T22 の要素の value の文字）。題名を数えるのに使う。
    var rawTexts: [String]
    var sent: Int
    var failed: Int

    var names: [String] { events.compactMap { $0["name"] as? String } }

    /// PRD 15 の9つの名前
    static let prdEventNames: Set<String> = [
        "App First Opened", "Book Added", "Reading Session Started", "Reading Session Finished",
        "Reading Session Restored", "Reading Session Discarded", "Reading Week Reached", "Save Failed", "Load Failed",
    ]
}

/// 計測の確かめ方を1か所で切り替える。既定は localhost の受け口（T6、T13）。
/// localhost に届かないと CI で分かったら、test plan の ACCEPTANCE_TELEMETRY_PATH を log にして T22 に替える（test-hooks.md の T6 の備考）。
@MainActor
final class TelemetryProbe {
    enum Path: String {
        case http, log
    }

    static var path: Path {
        Path(rawValue: ProcessInfo.processInfo.environment["ACCEPTANCE_TELEMETRY_PATH"] ?? "http") ?? .http
    }

    /// POST /events を受ける口（AC-20 では失敗する口）
    let events: TelemetryReceiver
    /// POST /flushed を受ける正常な口（T13。AC-20 だけ別に立てる）
    let control: TelemetryReceiver?

    init(eventsMode: TelemetryReceiver.Mode, separateControl: Bool, test: XCTestCase) throws {
        let events = TelemetryReceiver(mode: eventsMode)
        try events.start(timeout: Wait.timeout)
        self.events = events
        var control: TelemetryReceiver?
        if separateControl {
            let receiver = TelemetryReceiver(mode: .ok)
            try receiver.start(timeout: Wait.timeout)
            control = receiver
        }
        self.control = control
        let toStop = [events] + (control.map { [$0] } ?? [])
        test.addTeardownBlock {
            toStop.forEach { $0.stop() }
        }
    }

    /// 起動の設定に受け口をつなぐ。eventsURL を渡すと、その先（届かない先など）に送らせる。
    func apply(to config: inout LaunchConfig, eventsURL: String? = nil) {
        config.telemetryURL = eventsURL ?? events.baseURL
        if let control { config.telemetryControlURL = control.baseURL }
        if TelemetryProbe.path == .log { config.telemetryLog = true }
    }

    /// 送り終わり（sent + failed が total 以上）を待ってから、届いたものを返す。
    func waitDrained(
        _ session: AppSession, total: Int, file: StaticString = #filePath, line: UInt = #line
    ) -> TelemetrySnapshot {
        switch TelemetryProbe.path {
        case .http:
            let flushReceiver = control ?? events
            let drained = Wait.until(
                NSPredicate(block: { @Sendable _, _ in flushReceiver.flushedCount >= total }), nil, timeout: Wait.telemetry)
            XCTAssertTrue(drained, "POST /flushed の sent + failed が \(total) に届かない（今は \(flushReceiver.flushedCount)）", file: file, line: line)
            let totals = flushReceiver.flushedTotals ?? (0, 0)
            let all = events.requests + (control?.requests ?? [])
            return TelemetrySnapshot(
                events: events.eventBodies.compactMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] },
                rawTexts: all.map { String(decoding: $0.raw, as: UTF8.self) },
                sent: totals.sent, failed: totals.failed)
        case .log:
            return waitForLog(session, total: total, file: file, line: line)
        }
    }

    /// T22：uitest.telemetry.log の value（1行の JSON {"events":[…],"sent":n,"failed":m}）が変わるのを待ちながら読む。
    private func waitForLog(
        _ session: AppSession, total: Int, file: StaticString, line: UInt
    ) -> TelemetrySnapshot {
        let element = session.app.descendants(matching: .any)["uitest.telemetry.log"]
        Wait.exists(element, "uitest.telemetry.log", file: file, line: line)
        let deadline = Date().addingTimeInterval(Wait.telemetry)
        var text = (element.value as? String) ?? ""
        var snapshot = TelemetryProbe.parseLog(text)
        while snapshot.sent + snapshot.failed < total && Date() < deadline {
            Wait.until(NSPredicate(format: "value != %@", text), element, timeout: deadline.timeIntervalSinceNow)
            text = (element.value as? String) ?? ""
            snapshot = TelemetryProbe.parseLog(text)
        }
        XCTAssertGreaterThanOrEqual(snapshot.sent + snapshot.failed, total, "uitest.telemetry.log の sent + failed", file: file, line: line)
        return snapshot
    }

    static func parseLog(_ text: String) -> TelemetrySnapshot {
        guard let object = try? JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any] else {
            return TelemetrySnapshot(events: [], rawTexts: [text], sent: 0, failed: 0)
        }
        return TelemetrySnapshot(
            events: (object["events"] as? [[String: Any]]) ?? [], rawTexts: [text],
            sent: (object["sent"] as? Int) ?? 0, failed: (object["failed"] as? Int) ?? 0)
    }
}
