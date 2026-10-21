import Foundation
import SwiftData

// 保存の形の版1（contracts/data-model.md、docs/adr/0001-local-storage-swiftdata.md）。
// 形を変えるときは SchemaV2 と MigrationStage を足す（項目を消す、名前や型を変える変更は新しい ADR）。
// アプリのターゲットは既定の分離が MainActor なので、モデルと版の型は nonisolated と明示する
// （PersistentModel と VersionedSchema の要件は nonisolated。SE-0449、SE-0466）。

nonisolated enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Book.self, ReadingSession.self, ActiveReading.self]
    }

    /// 本（data-model.md の Book）。
    @Model
    nonisolated final class Book {
        /// 行の識別子 library.book.<小文字の UUID>（design 6）。作るときに決め、変えない。
        var id: UUID
        /// 整えた後の1〜100字（TitleRules.stored。形B）。
        var title: String
        /// nil か 1〜9,999。
        var totalPages: Int?
        /// 0〜9,999。totalPages があればそれ以下。記録を消しても変えない（AC-16）。
        var lastPage: Int
        /// 追加の保存が通った時刻。
        var addedAt: Date
        /// 記録。消す決まりは cascade（001 に本を消す操作はない）。
        @Relationship(deleteRule: .cascade, inverse: \ReadingSession.book)
        var sessions: [ReadingSession] = []

        init(id: UUID = UUID(), title: String, totalPages: Int?, lastPage: Int = 0, addedAt: Date) {
            self.id = id
            self.title = title
            self.totalPages = totalPages
            self.lastPage = lastPage
            self.addedAt = addedAt
        }
    }

    /// 記録（data-model.md の ReadingSession）。book は必須だが、SwiftData の関係は insert の後に付けるので Optional で持つ。
    @Model
    nonisolated final class ReadingSession {
        var id: UUID
        var book: Book?
        /// 読み始めた時刻。週の集計はこの時刻の週に数える。
        var startedAt: Date
        /// 60 以上。
        var durationSeconds: Int
        var endPage: Int?
        /// endPage が nil なら nil。あれば max(0, endPage − 保存の前の book.lastPage)。
        var pagesRead: Int?
        /// 記録の保存が通った時刻。
        var savedAt: Date

        init(
            id: UUID = UUID(), startedAt: Date, durationSeconds: Int, endPage: Int?, pagesRead: Int?, savedAt: Date
        ) {
            self.id = id
            self.startedAt = startedAt
            self.durationSeconds = durationSeconds
            self.endPage = endPage
            self.pagesRead = pagesRead
            self.savedAt = savedAt
        }
    }

    /// 進行中の読書（0件か1件。idle は「この行がない」こと）。
    @Model
    nonisolated final class ActiveReading {
        var book: Book?
        /// "reading" / "paused" / "finishing"。知らない値は読み込みの失敗（ReadingState）。
        var state: String
        var startedAt: Date
        /// 0 以上。finishing にいてやめた時間もここに足す。
        var pausedTotalSeconds: Double
        /// state が paused のときだけ値がある。
        var pausedAt: Date?
        /// state が finishing のときだけ値がある。経過はここで止まる。
        var finishedAt: Date?
        /// 一度でも一時停止したか（計測の was_paused）。
        var wasPaused: Bool

        init(
            state: String, startedAt: Date, pausedTotalSeconds: Double = 0, pausedAt: Date? = nil,
            finishedAt: Date? = nil, wasPaused: Bool = false
        ) {
            self.state = state
            self.startedAt = startedAt
            self.pausedTotalSeconds = pausedTotalSeconds
            self.pausedAt = pausedAt
            self.finishedAt = finishedAt
            self.wasPaused = wasPaused
        }
    }
}

typealias Book = SchemaV1.Book
typealias ReadingSession = SchemaV1.ReadingSession
typealias ActiveReading = SchemaV1.ActiveReading

/// 移行の計画。001 は最初の版なので stages は空。
nonisolated enum LibraryMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

/// 保存先の作り方（ADR 0001：Application Support/Yomutoki/Library.store、cloudKitDatabase は none、バックアップから除かない）。
nonisolated enum LibraryContainer {
    static let directoryName = "Yomutoki"
    static let storeFileName = "Library.store"

    /// Application Support/Yomutoki/。テストのつなぎ口の T1 もこのフォルダを消す（Debug/UITestHooks.swift）。
    static func storeDirectory() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return base.appending(path: directoryName, directoryHint: .isDirectory)
    }

    /// 端末のファイルに置く ModelContainer。作れなければ throws（AC-54 の読み込みの失敗になる）。
    static func makeOnDisk() throws -> ModelContainer {
        let directory = try storeDirectory()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let schema = Schema(versionedSchema: SchemaV1.self)
        let configuration = ModelConfiguration(
            schema: schema,
            url: directory.appending(path: storeFileName, directoryHint: .notDirectory),
            cloudKitDatabase: .none)
        return try ModelContainer(for: schema, migrationPlan: LibraryMigrationPlan.self, configurations: configuration)
    }

    /// 単体テストとプレビュー用。呼ぶたびに別の名前のメモリの中の保存先を作る（ほかのテストと共有しない）。
    static func makeInMemory() throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let configuration = ModelConfiguration(
            UUID().uuidString, schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, migrationPlan: LibraryMigrationPlan.self, configurations: configuration)
    }
}
