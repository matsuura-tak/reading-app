import Foundation
import Testing

@testable import Yomutoki

@MainActor
struct ReadingModelTests {
    private func finishing(
        fail: [StoreOperation: FailureBudget] = [:]
    ) throws -> (harness: StoreHarness, model: ReadingModel) {
        let h = try StoreHarness(fail: fail)
        h.store.load()
        let bookID = try h.store.addBook(title: "坊っちゃん", totalPages: 300)
        try h.store.startReading(bookID: bookID, source: .home)
        h.advance(600)
        _ = try h.store.finish()
        return (h, ReadingModel(store: h.store, router: AppRouter()))
    }

    @Test("初回finishing復元後、スワイプ途中のS4再表示で編集値を初期化しない")
    func appearanceDuringDismissalKeepsDraft() throws {
        let (h, model) = try finishing()
        model.appeared()
        try #require(model.isFinishSheetPresented)
        try #require(model.draft.minutesText == "10")
        model.draft.pageText = "72"
        model.draft.minutesText = "5"
        let edited = model.draft

        // システムがsheetの表示bindingをfalseにした後、dismiss完了より先にS4が再表示される境界。
        model.isFinishSheetPresented = false
        model.appeared()
        #expect(!model.isFinishSheetPresented)
        #expect(model.draft == edited)
        #expect(h.store.active?.state == .finishing)
    }

    @Test(
        "スワイプ保存失敗の復旧表示は古いdismissで保存されず、利用者の次の取消だけが通る",
        arguments: [false, true])
    func failedSwipeNeedsAnotherUserCancellation(retryBySwiping: Bool) throws {
        let (h, model) = try finishing(fail: [.sessionCancelFinish: .times(1)])
        model.appeared()
        model.draft.pageText = "72"
        let edited = model.draft
        var cancelAttempts = 0
        let beforeSave = h.store.beforeSave
        h.store.beforeSave = { operation in
            if operation == .sessionCancelFinish { cancelAttempts += 1 }
            try beforeSave(operation)
        }

        model.isFinishSheetPresented = false
        model.finishSheetDismissed()
        try #require(model.isFinishSheetPresented)
        try #require(model.finishFailure == .cancel)
        try #require(model.draft == edited)
        try #require(h.store.active?.state == .finishing)

        // 復旧の再提示後に届くS4の表示通知と古いdismissは、新しい利用者操作ではない。
        model.appeared()
        model.finishSheetDismissed()
        #expect(cancelAttempts == 1)
        #expect(model.isFinishSheetPresented)
        #expect(model.finishFailure == .cancel)
        #expect(model.draft == edited)
        #expect(h.store.active?.state == .finishing)

        h.advance(60)
        if retryBySwiping {
            model.isFinishSheetPresented = false
            model.finishSheetDismissed()
        } else {
            model.cancelFinish()
        }
        #expect(cancelAttempts == 2)
        #expect(!model.isFinishSheetPresented)
        #expect(model.finishFailure == nil)
        #expect(model.draft == FinishDraft())
        #expect(h.store.active?.state == .reading)
        #expect(h.store.active?.elapsedSeconds(now: h.clock.now()) == 600)
        #expect(try h.count(ReadingSession.self) == 0)
    }

    @Test("通常の下スワイプ成功後は閉じ、次の終える入力は新しい経過と空のページで開く")
    func successfulSwipeStartsFreshDraftNextTime() throws {
        let (h, model) = try finishing()
        model.appeared()
        model.draft.pageText = "72"
        model.draft.minutesText = "5"
        model.isFinishSheetPresented = false
        model.finishSheetDismissed()
        model.appeared()
        #expect(!model.isFinishSheetPresented)
        #expect(h.store.active?.state == .reading)
        #expect(model.draft == FinishDraft())

        h.advance(60)
        model.finish()
        #expect(model.isFinishSheetPresented)
        #expect(model.draft.pageText.isEmpty)
        #expect(model.draft.minutesText == "11")
        #expect(model.draft.minutesInitial == 11)
        #expect(model.finishFailure == nil)
    }
}
