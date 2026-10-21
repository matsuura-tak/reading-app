#if DEBUG
// テストのつなぎ口の2ファイルの片方（ADR 0005）。ファイル全体が Debug ビルドだけにある。Release の実行ファイルに入らない。
// contracts/telemetry.md の「テストの受け口」と contracts/test-hooks.md の T6、T7、T13、T19、T22。
import Foundation
import Observation

/// 起動してからの累計（POST /flushed の本文。contracts/telemetry-flushed.schema.json）。
nonisolated struct TelemetryDeliveryCounts: Codable, Equatable, Sendable {
    var sent = 0
    var failed = 0
}

/// 受け口へ1件ずつ、出た順に、前の送信が終わってから POST する送り先（T6）。
/// 2xx 以外、接続の失敗、待ち切れ（T19）は失敗として数え、送り直さず捨てる。待ち行列が空になるたびに /flushed を送る（T13）。
actor HTTPTelemetrySink: TelemetrySink {
    private let eventsURL: URL
    private let flushedURL: URL
    private let session: URLSession
    private let onCountsChanged: @Sendable (TelemetryDeliveryCounts) async -> Void
    private var queue: [TelemetryEvent] = []
    private var isDraining = false
    private var counts = TelemetryDeliveryCounts()

    init(
        baseURL: URL, controlURL: URL?, timeoutSeconds: Int,
        onCountsChanged: @escaping @Sendable (TelemetryDeliveryCounts) async -> Void = { _ in }
    ) {
        eventsURL = baseURL.appending(path: "events", directoryHint: .notDirectory)
        flushedURL = (controlURL ?? baseURL).appending(path: "flushed", directoryHint: .notDirectory)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = TimeInterval(timeoutSeconds)
        configuration.timeoutIntervalForResource = TimeInterval(timeoutSeconds)
        configuration.waitsForConnectivity = false
        session = URLSession(configuration: configuration)
        self.onCountsChanged = onCountsChanged
    }

    /// 待ち行列に足してすぐ戻る（画面と計測の順番を止めない）。
    func send(_ event: TelemetryEvent) async {
        queue.append(event)
        guard !isDraining else { return }
        isDraining = true
        Task { await self.drain() }
    }

    private func drain() async {
        while !queue.isEmpty {
            let event = queue.removeFirst()
            if await post(event) {
                counts.sent += 1
            } else {
                counts.failed += 1
            }
            await onCountsChanged(counts)
            if queue.isEmpty {
                await postFlushed()
            }
        }
        isDraining = false
    }

    private func post(_ event: TelemetryEvent) async -> Bool {
        guard let body = try? event.jsonData() else { return false }
        return await postJSON(body, to: eventsURL)
    }

    /// /flushed そのものは数えず、送り直さない。
    private func postFlushed() async {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let body = try? encoder.encode(counts) else { return }
        _ = await postJSON(body, to: flushedURL)
    }

    private func postJSON(_ body: Data, to url: URL) async -> Bool {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        do {
            let (_, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }
            return (200..<300).contains(http.statusCode)
        } catch {
            return false
        }
    }
}

/// T22：送り先に渡されたイベントを順に覚える（送信の成否を待たない）。uitest.telemetry.log の accessibilityValue の元。
@MainActor
@Observable
final class TelemetryLog {
    private(set) var events: [TelemetryEvent] = []
    private(set) var counts = TelemetryDeliveryCounts()
    /// 1行の JSON {"events":[…],"failed":m,"sent":n}（キーは並べ替える。events の各要素は telemetry-events.schema.json の形）。
    private(set) var json = ""

    init() {
        render()
    }

    func append(_ event: TelemetryEvent) {
        events.append(event)
        render()
    }

    func update(_ counts: TelemetryDeliveryCounts) {
        self.counts = counts
        render()
    }

    private func render() {
        let payload = TelemetryLogPayload(
            events: events.map { TelemetryPayload(event: $0) }, sent: counts.sent, failed: counts.failed)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        guard let data = try? encoder.encode(payload) else { return }
        json = String(decoding: data, as: UTF8.self)
    }
}

nonisolated struct TelemetryLogPayload: Encodable, Sendable {
    let events: [TelemetryPayload]
    let sent: Int
    let failed: Int
}

/// T22 の覚える包み。どちらの送り先（端末の中で数える、HTTP）の前にも挟む。
nonisolated struct RecordingTelemetrySink: TelemetrySink {
    let log: TelemetryLog
    let inner: any TelemetrySink

    func send(_ event: TelemetryEvent) async {
        await log.append(event)
        await inner.send(event)
    }
}
#endif
