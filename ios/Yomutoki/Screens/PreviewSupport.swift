#if DEBUG
import SwiftUI

/// #Preview 用の保存の層（メモリの中の保存先と、止めた時計）。Debug ビルドだけにあり、製品の画面からは使わない。
/// 本と記録は、本物の保存の操作（LibraryStore）を通して作る。題名はプレビューの見た目を確かめるための例。
@MainActor
enum PreviewLibrary {
    /// 2026-10-21T21:30:00+09:00。
    static let start = Date(timeIntervalSince1970: 1_792_585_800)
    /// どの本にも当たらない ID（読み込み中と読み込みの失敗のプレビュー用）。
    static let missingBookID = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))

    struct Built {
        let store: LibraryStore
        let clock: ClockController
        let router: AppRouter
        let botchan: UUID?
        let kokoro: UUID?
    }

    private struct PreviewLoadFailure: Error {}

    /// - books: false なら本が0冊。sessions: false なら記録が0件。active：進行中の読書の状態（坊っちゃん）。
    /// - load: false なら読み込み中のまま。failLoad: true なら読み込みの失敗。
    static func make(
        books: Bool = true, sessions: Bool = true, active: ReadingState? = nil, load: Bool = true,
        failLoad: Bool = false
    ) -> Built {
        let clock = ClockController(start: start, frozen: true)
        let store = LibraryStore(
            clock: clock.clock, calendar: Calendar.autoupdatingCurrent, telemetry: nil,
            openContainer: {
                if failLoad { throw PreviewLoadFailure() }
                return try LibraryContainer.makeInMemory()
            })
        let router = AppRouter()
        guard load else { return Built(store: store, clock: clock, router: router, botchan: nil, kokoro: nil) }
        store.load()
        guard books else { return Built(store: store, clock: clock, router: router, botchan: nil, kokoro: nil) }
        let kokoro = try? store.addBook(title: "こころ", totalPages: nil)
        clock.apply(.advance(60))
        let botchan = try? store.addBook(title: "坊っちゃん", totalPages: 300)
        if sessions, let botchan {
            _ = try? store.startReading(bookID: botchan, source: .home)
            clock.apply(.advance(24 * 60))
            _ = try? store.finish()
            _ = try? store.finishSession(endPage: 72, minutes: 24)
        }
        if let active, let botchan {
            clock.apply(.advance(3_600))
            _ = try? store.startReading(bookID: botchan, source: .home)
            clock.apply(.advance(750))
            switch active {
            case .reading:
                break
            case .paused:
                _ = try? store.pause()
            case .finishing:
                _ = try? store.finish()
            }
        }
        return Built(store: store, clock: clock, router: router, botchan: botchan, kokoro: kokoro)
    }

    /// S5 のプレビュー用のモデル（finishing の読書の下書きを作って開いた形）。
    static func finishingModel(
        _ built: Built, pageText: String = "", minutesText: String? = nil, finishFailure: FinishFailure? = nil
    ) -> ReadingModel {
        let model = ReadingModel(store: built.store, router: built.router, finishFailure: finishFailure)
        let minutes = built.store.active?.initialMinutes ?? 0
        model.draft = FinishDraft(
            pageText: pageText, minutesText: minutesText ?? String(minutes), minutesInitial: minutes)
        model.isFinishSheetPresented = true
        return model
    }
}

extension View {
    /// 画面が読む環境（保存の層、行き先、時計）を入れる。
    func previewEnvironment(_ built: PreviewLibrary.Built) -> some View {
        environment(built.store)
            .environment(built.router)
            .environment(\.appClock, built.clock.clock)
    }
}
#endif
