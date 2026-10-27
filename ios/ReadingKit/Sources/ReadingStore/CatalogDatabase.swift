import Foundation
import SQLite3
import ReadingCore

public enum CatalogStatus: String, Codable, Sendable, Equatable {
    case ready
    case notDownloaded
}

public enum CatalogLookupOutcome: Sendable, Equatable {
    case found(H20BiblioItem)
    case notFound(offlineMetadata: BarcodeMetadataResult)
    case databaseNotReady(offlineMetadata: BarcodeMetadataResult)
    case invalidBarcode(BarcodeParseError)
}

public struct CatalogQueryLog: Codable, Sendable, Equatable {
    public var kind: String
    public var query: String
    public var resultCount: Int
    public var elapsedMs: Double

    public nonisolated init(kind: String, query: String, resultCount: Int, elapsedMs: Double) {
        self.kind = kind
        self.query = query
        self.resultCount = resultCount
        self.elapsedMs = elapsedMs
    }
}

public struct CatalogCooccurrenceRow: Codable, Sendable, Equatable {
    public var fromISBN13: String
    public var toISBN13: String
    public var count: Int
    public var ndc: String?

    public nonisolated init(fromISBN13: String, toISBN13: String, count: Int, ndc: String? = nil) {
        self.fromISBN13 = fromISBN13
        self.toISBN13 = toISBN13
        self.count = count
        self.ndc = ndc
    }
}

public struct CatalogMetadata: Codable, Sendable, Equatable {
    public var version: String
    public var updatedAt: String
    public var sourceAttribution: String
    public var licenseURL: String

    public nonisolated static let defaultMetadata = CatalogMetadata(
        version: "1.0",
        updatedAt: "2026-10-25",
        sourceAttribution: "国立国会図書館サーチの書誌データを加工して作成（国立国会図書館のAPIを直接呼び出すものではなく、国立国会図書館とは無関係です。CC BY 4.0）",
        licenseURL: "https://creativecommons.org/licenses/by/4.0/deed.ja"
    )
}

private let sqliteTransientDestructor = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

@MainActor
public final class CatalogDatabase {
    public private(set) var databaseURL: URL
    public private(set) var status: CatalogStatus = .ready
    public private(set) var delayMs: Int = 0
    public private(set) var queryLogs: [CatalogQueryLog] = []
    public private(set) var metadata: CatalogMetadata = .defaultMetadata
    private var readOnlyHandle: OpaquePointer?
    private var fts5Available: Bool = false

    public init(
        databaseURL: URL? = nil,
        status: CatalogStatus = .ready,
        books: [H20BiblioItem] = [],
        cooccurrences: [CatalogCooccurrenceRow] = [],
        delayMs: Int = 0
    ) {
        let resolvedURL = databaseURL ?? Self.defaultCatalogURL()
        self.databaseURL = resolvedURL
        self.status = status
        self.delayMs = delayMs
        rebuildDatabase(status: status, books: books, cooccurrences: cooccurrences, delayMs: delayMs)
    }

    public func closeConnection() {
        if let handle = readOnlyHandle {
            sqlite3_close_v2(handle)
            readOnlyHandle = nil
        }
    }

    public nonisolated static func defaultCatalogURL() -> URL {
        let fm = FileManager.default
        let appSupport = (try? fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fm.temporaryDirectory
        let dir = appSupport.appendingPathComponent("Catalog", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("catalog.sqlite", isDirectory: false)
    }

    /// Configures and rebuilds the SQLite catalog from a `UITEST_NDL_STUB` JSON string (supports both acceptance test format and H20NDLStubConfig).
    public func configure(fromStubJSON jsonString: String) {
        guard let data = jsonString.data(using: .utf8) else {
            rebuildDatabase(status: .ready, books: Self.defaultBundledSeedBooks(), cooccurrences: [], delayMs: 0)
            return
        }

        if let rawObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let statusStr = (rawObj["status"] as? String) ?? "ready"
            let resolvedStatus: CatalogStatus = (statusStr == "notDownloaded") ? .notDownloaded : .ready
            let delay = (rawObj["delayMs"] as? Int) ?? (rawObj["defaultDelayMs"] as? Int) ?? 0

            var parsedBooks: [H20BiblioItem] = []
            if let booksArr = rawObj["books"] as? [[String: Any]] {
                for dict in booksArr {
                    let isbn = (dict["isbn13"] as? String) ?? (dict["isbn"] as? String)
                    let title = (dict["title"] as? String) ?? ""
                    guard !title.isEmpty else { continue }
                    let rawCreator = (dict["rawDcCreator"] as? String) ?? (dict["rawCreator"] as? String)
                    let rawAuthor = (dict["author"] as? String)
                    let cleanedAuthor: String?
                    if let rawCreator, !rawCreator.isEmpty {
                        let formatted = AuthorNameFormatter.format(rawCreator)
                        cleanedAuthor = formatted.isEmpty ? nil : formatted
                    } else if let rawAuthor, !rawAuthor.isEmpty {
                        let formatted = AuthorNameFormatter.format(rawAuthor)
                        cleanedAuthor = formatted.isEmpty ? rawAuthor : formatted
                    } else {
                        cleanedAuthor = nil
                    }
                    let publisher = dict["publisher"] as? String
                    let label = dict["label"] as? String
                    let publishedYear = dict["publishedYear"] as? Int
                    let ndc = dict["ndc"] as? String
                    let seriesTitle = dict["seriesTitle"] as? String
                    let volumeNumber = dict["volumeNumber"] as? Int
                    parsedBooks.append(
                        H20BiblioItem(
                            isbn13: isbn,
                            title: title,
                            author: cleanedAuthor,
                            rawDcCreator: rawCreator,
                            publisher: publisher,
                            label: label,
                            publishedYear: publishedYear,
                            ndc: ndc,
                            seriesTitle: seriesTitle,
                            volumeNumber: volumeNumber
                        )
                    )
                }
            }

            // Also support H20NDLStubConfig isbnResponses / searchResponses
            if let isbnMap = rawObj["isbnResponses"] as? [String: [String: Any]] {
                for (isbnKey, entryDict) in isbnMap {
                    if let items = entryDict["items"] as? [[String: Any]] {
                        for item in items {
                            let title = (item["title"] as? String) ?? ""
                            guard !title.isEmpty else { continue }
                            let rawCreator = (item["rawDcCreator"] as? String) ?? (item["rawCreator"] as? String)
                            let rawAuthor = (item["author"] as? String) ?? rawCreator
                            let cleaned = AuthorNameFormatter.format(rawAuthor)
                            parsedBooks.append(
                                H20BiblioItem(
                                    isbn13: (item["isbn13"] as? String) ?? isbnKey,
                                    title: title,
                                    author: cleaned.isEmpty ? nil : cleaned,
                                    rawDcCreator: rawCreator,
                                    publisher: item["publisher"] as? String,
                                    label: item["label"] as? String,
                                    publishedYear: item["publishedYear"] as? Int,
                                    ndc: item["ndc"] as? String,
                                    seriesTitle: item["seriesTitle"] as? String,
                                    volumeNumber: item["volumeNumber"] as? Int
                                )
                            )
                        }
                    }
                }
            }

            var parsedCooc: [CatalogCooccurrenceRow] = []
            if let coocArr = rawObj["cooccurrences"] as? [[String: Any]] {
                for dict in coocArr {
                    guard let fromISBN = (dict["fromISBN"] as? String) ?? (dict["sourceISBN13"] as? String),
                          let toISBN = (dict["toISBN"] as? String) ?? (dict["candidateISBN13"] as? String),
                          let count = dict["count"] as? Int else {
                        continue
                    }
                    let ndc = dict["ndc"] as? String
                    parsedCooc.append(
                        CatalogCooccurrenceRow(
                            fromISBN13: fromISBN,
                            toISBN13: toISBN,
                            count: count,
                            ndc: ndc
                        )
                    )
                }
            }

            rebuildDatabase(status: resolvedStatus, books: parsedBooks, cooccurrences: parsedCooc, delayMs: delay)
            return
        }

        rebuildDatabase(status: .ready, books: Self.defaultBundledSeedBooks(), cooccurrences: [], delayMs: 0)
    }

    public func rebuildDatabase(
        status: CatalogStatus,
        books: [H20BiblioItem],
        cooccurrences: [CatalogCooccurrenceRow],
        delayMs: Int = 0
    ) {
        closeConnection()
        self.status = status
        self.delayMs = delayMs
        self.queryLogs.removeAll()

        let fm = FileManager.default
        var parentDir = databaseURL.deletingLastPathComponent()
        try? fm.createDirectory(at: parentDir, withIntermediateDirectories: true)
        var dirValues = URLResourceValues()
        dirValues.isExcludedFromBackup = true
        try? parentDir.setResourceValues(dirValues)

        if fm.fileExists(atPath: databaseURL.path) {
            try? fm.removeItem(at: databaseURL)
        }

        guard status == .ready else {
            return
        }

        var writeDB: OpaquePointer?
        let openFlags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_NOMUTEX
        guard sqlite3_open_v2(databaseURL.path, &writeDB, openFlags, nil) == SQLITE_OK,
              let db = writeDB else {
            if let writeDB { sqlite3_close_v2(writeDB) }
            return
        }

        _ = execSQL(db, "PRAGMA journal_mode = DELETE;")
        _ = execSQL(db, "PRAGMA synchronous = NORMAL;")

        _ = execSQL(db, """
        CREATE TABLE IF NOT EXISTS catalog_meta (
            version TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            source_attribution TEXT NOT NULL,
            license_url TEXT NOT NULL
        );
        """)

        _ = execSQL(db, """
        CREATE TABLE IF NOT EXISTS books (
            isbn13 TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            author TEXT,
            raw_creator TEXT,
            publisher TEXT,
            label TEXT,
            published_year INTEGER,
            ndc TEXT,
            series_title TEXT,
            volume_number INTEGER
        );
        """)

        _ = execSQL(db, "CREATE INDEX IF NOT EXISTS idx_books_author ON books(author);")
        _ = execSQL(db, "CREATE INDEX IF NOT EXISTS idx_books_series ON books(series_title, volume_number);")

        // Create FTS5 virtual table with trigram tokenizer, falling back to unicode61 if trigram is unsupported
        if execSQL(db, "CREATE VIRTUAL TABLE IF NOT EXISTS books_fts USING fts5(isbn13 UNINDEXED, title, author, tokenize='trigram');") {
            fts5Available = true
        } else if execSQL(db, "CREATE VIRTUAL TABLE IF NOT EXISTS books_fts USING fts5(isbn13 UNINDEXED, title, author);") {
            fts5Available = true
        } else {
            fts5Available = false
        }

        _ = execSQL(db, """
        CREATE TABLE IF NOT EXISTS cooccurrence (
            from_isbn13 TEXT NOT NULL,
            to_isbn13 TEXT NOT NULL,
            count INTEGER NOT NULL,
            ndc TEXT,
            PRIMARY KEY (from_isbn13, to_isbn13)
        );
        """)

        // Insert metadata
        var metaStmt: OpaquePointer?
        if sqlite3_prepare_v2(db, "INSERT INTO catalog_meta(version, updated_at, source_attribution, license_url) VALUES (?1, ?2, ?3, ?4);", -1, &metaStmt, nil) == SQLITE_OK,
           let stmt = metaStmt {
            bindText(stmt, index: 1, value: metadata.version)
            bindText(stmt, index: 2, value: metadata.updatedAt)
            bindText(stmt, index: 3, value: metadata.sourceAttribution)
            bindText(stmt, index: 4, value: metadata.licenseURL)
            _ = sqlite3_step(stmt)
        }
        if let metaStmt { sqlite3_finalize(metaStmt) }

        // Insert books
        _ = execSQL(db, "BEGIN TRANSACTION;")
        var bookStmt: OpaquePointer?
        var ftsStmt: OpaquePointer?
        let bookSQL = """
        INSERT OR REPLACE INTO books(isbn13, title, author, raw_creator, publisher, label, published_year, ndc, series_title, volume_number)
        VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10);
        """
        _ = sqlite3_prepare_v2(db, bookSQL, -1, &bookStmt, nil)
        if fts5Available {
            _ = sqlite3_prepare_v2(db, "INSERT INTO books_fts(isbn13, title, author) VALUES (?1, ?2, ?3);", -1, &ftsStmt, nil)
        }

        for (idx, item) in books.enumerated() {
            let resolvedISBN = item.isbn13 ?? String(format: "978400999%04d", idx + 1)
            let formattedAuthor: String?
            if let raw = item.rawDcCreator, !raw.isEmpty {
                let cleaned = AuthorNameFormatter.format(raw)
                formattedAuthor = cleaned.isEmpty ? item.author : cleaned
            } else if let a = item.author, !a.isEmpty {
                let cleaned = AuthorNameFormatter.format(a)
                formattedAuthor = cleaned.isEmpty ? a : cleaned
            } else {
                formattedAuthor = nil
            }

            if let stmt = bookStmt {
                sqlite3_reset(stmt)
                sqlite3_clear_bindings(stmt)
                bindText(stmt, index: 1, value: resolvedISBN)
                bindText(stmt, index: 2, value: item.title)
                bindOptionalText(stmt, index: 3, value: formattedAuthor)
                bindOptionalText(stmt, index: 4, value: item.rawDcCreator)
                bindOptionalText(stmt, index: 5, value: item.publisher)
                bindOptionalText(stmt, index: 6, value: item.label)
                bindOptionalInt(stmt, index: 7, value: item.publishedYear)
                bindOptionalText(stmt, index: 8, value: item.ndc)
                bindOptionalText(stmt, index: 9, value: item.seriesTitle)
                bindOptionalInt(stmt, index: 10, value: item.volumeNumber)
                _ = sqlite3_step(stmt)
            }

            if let fStmt = ftsStmt {
                sqlite3_reset(fStmt)
                sqlite3_clear_bindings(fStmt)
                bindText(fStmt, index: 1, value: resolvedISBN)
                bindText(fStmt, index: 2, value: item.title)
                bindText(fStmt, index: 3, value: formattedAuthor ?? "")
                _ = sqlite3_step(fStmt)
            }
        }
        if let bookStmt { sqlite3_finalize(bookStmt) }
        if let ftsStmt { sqlite3_finalize(ftsStmt) }

        // Insert cooccurrences
        var coocStmt: OpaquePointer?
        if sqlite3_prepare_v2(db, "INSERT OR REPLACE INTO cooccurrence(from_isbn13, to_isbn13, count, ndc) VALUES (?1, ?2, ?3, ?4);", -1, &coocStmt, nil) == SQLITE_OK,
           let stmt = coocStmt {
            for row in cooccurrences {
                sqlite3_reset(stmt)
                sqlite3_clear_bindings(stmt)
                bindText(stmt, index: 1, value: row.fromISBN13)
                bindText(stmt, index: 2, value: row.toISBN13)
                sqlite3_bind_int(stmt, 3, Int32(row.count))
                bindOptionalText(stmt, index: 4, value: row.ndc)
                _ = sqlite3_step(stmt)
            }
        }
        if let coocStmt { sqlite3_finalize(coocStmt) }
        _ = execSQL(db, "COMMIT;")
        sqlite3_close_v2(db)

        // Exclude catalog.sqlite from iCloud/iTunes backup (ADR-0002, ADR-0004)
        var fileValues = URLResourceValues()
        fileValues.isExcludedFromBackup = true
        try? databaseURL.setResourceValues(fileValues)

        openReadOnlyConnection()
    }

    private func openReadOnlyConnection() {
        closeConnection()
        guard status == .ready, FileManager.default.fileExists(atPath: databaseURL.path) else {
            return
        }
        var db: OpaquePointer?
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX
        if sqlite3_open_v2(databaseURL.path, &db, flags, nil) == SQLITE_OK, let handle = db {
            _ = execSQL(handle, "PRAGMA query_only = ON;")
            self.readOnlyHandle = handle
        } else if let db {
            sqlite3_close_v2(db)
        }
    }

    public func isExcludedFromBackup() -> Bool {
        (try? databaseURL.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup) ?? false
    }

    // MARK: - Queries

    /// Looks up a book by ISBN-13 and optional 2nd-tier `192` C-code (AC-2, AC-3, AC-9, AC-10, AC-11, AC-92).
    public func lookupByISBN(
        _ rawISBN: String,
        supplementalCode: String? = nil,
        clock: ReadingClock? = nil
    ) -> CatalogLookupOutcome {
        let startNs = DispatchTime.now().uptimeNanoseconds
        clock?.beginInterval(.barcodeLookup)

        switch ISBNAndCCodeParser.resolveMetadata(isbn13: rawISBN, supplementalCode: supplementalCode) {
        case .failure(let error):
            _ = clock?.endInterval(.barcodeLookup)
            return .invalidBarcode(error)
        case .success(let offlineMeta):
            if status == .notDownloaded {
                let elapsed = finishTiming(startNs: startNs, clock: clock, metric: .barcodeLookup)
                queryLogs.append(CatalogQueryLog(kind: "isbn", query: offlineMeta.isbn13, resultCount: 0, elapsedMs: elapsed))
                return .databaseNotReady(offlineMetadata: offlineMeta)
            }

            guard let db = readOnlyHandle else {
                let elapsed = finishTiming(startNs: startNs, clock: clock, metric: .barcodeLookup)
                queryLogs.append(CatalogQueryLog(kind: "isbn", query: offlineMeta.isbn13, resultCount: 0, elapsedMs: elapsed))
                return .notFound(offlineMetadata: offlineMeta)
            }

            let sql = """
            SELECT isbn13, title, author, raw_creator, publisher, label, published_year, ndc, series_title, volume_number
            FROM books
            WHERE isbn13 = ?1
            LIMIT 1;
            """
            var stmt: OpaquePointer?
            defer {
                if let stmt { sqlite3_finalize(stmt) }
            }
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let s = stmt {
                bindText(s, index: 1, value: offlineMeta.isbn13)
                if sqlite3_step(s) == SQLITE_ROW {
                    var item = readBookRow(s)
                    // Enrich missing publisher or label from barcode / C-code (AC-3)
                    if (item.publisher ?? "").isEmpty, let pub = offlineMeta.publisher {
                        item.publisher = pub
                    }
                    if (item.label ?? "").isEmpty, let fmtLabel = offlineMeta.formatLabel {
                        item.label = fmtLabel
                    }
                    let elapsed = finishTiming(startNs: startNs, clock: clock, metric: .barcodeLookup)
                    queryLogs.append(CatalogQueryLog(kind: "isbn", query: offlineMeta.isbn13, resultCount: 1, elapsedMs: elapsed))
                    return .found(item)
                }
            }

            let elapsed = finishTiming(startNs: startNs, clock: clock, metric: .barcodeLookup)
            queryLogs.append(CatalogQueryLog(kind: "isbn", query: offlineMeta.isbn13, resultCount: 0, elapsedMs: elapsed))
            return .notFound(offlineMetadata: offlineMeta)
        }
    }

    /// Searches books by title or author using FTS5 trigram and LIKE fallback (AC-4, AC-5, AC-149).
    public func searchByTitleOrAuthor(
        _ rawQuery: String,
        limit: Int = 20,
        clock: ReadingClock? = nil
    ) -> [H20BiblioItem] {
        let startNs = DispatchTime.now().uptimeNanoseconds
        clock?.beginInterval(.titleSearch)

        let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, status == .ready, let db = readOnlyHandle else {
            let elapsed = finishTiming(startNs: startNs, clock: clock, metric: .titleSearch)
            if !query.isEmpty {
                queryLogs.append(CatalogQueryLog(kind: "search", query: query, resultCount: 0, elapsedMs: elapsed))
            }
            return []
        }

        var results: [H20BiblioItem] = []
        var seenISBNs = Set<String>()

        // 1. Try FTS5 trigram search if query has >= 3 characters
        if fts5Available && query.count >= 3 {
            let ftsSQL = """
            SELECT b.isbn13, b.title, b.author, b.raw_creator, b.publisher, b.label, b.published_year, b.ndc, b.series_title, b.volume_number
            FROM books_fts f
            JOIN books b ON b.isbn13 = f.isbn13
            WHERE books_fts MATCH ?1
            ORDER BY b.published_year DESC, b.isbn13 ASC
            LIMIT ?2;
            """
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, ftsSQL, -1, &stmt, nil) == SQLITE_OK, let s = stmt {
                let escaped = "\"" + query.replacingOccurrences(of: "\"", with: "\"\"") + "\""
                bindText(s, index: 1, value: escaped)
                sqlite3_bind_int(s, 2, Int32(limit))
                while sqlite3_step(s) == SQLITE_ROW {
                    let item = readBookRow(s)
                    let key = item.isbn13 ?? item.title
                    if !seenISBNs.contains(key) {
                        seenISBNs.insert(key)
                        results.append(item)
                    }
                }
            }
            if let stmt { sqlite3_finalize(stmt) }
        }

        // 2. Supplement with parameterized LIKE query so 1-2 char queries and exact substrings always match
        if results.count < limit {
            let likeSQL = """
            SELECT isbn13, title, author, raw_creator, publisher, label, published_year, ndc, series_title, volume_number
            FROM books
            WHERE title LIKE ?1 OR author LIKE ?1
            ORDER BY CASE WHEN title = ?2 THEN 0 WHEN title LIKE ?3 THEN 1 ELSE 2 END, published_year DESC, isbn13 ASC
            LIMIT ?4;
            """
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, likeSQL, -1, &stmt, nil) == SQLITE_OK, let s = stmt {
                let pattern = "%\(query)%"
                let prefixPattern = "\(query)%"
                bindText(s, index: 1, value: pattern)
                bindText(s, index: 2, value: query)
                bindText(s, index: 3, value: prefixPattern)
                sqlite3_bind_int(s, 4, Int32(limit))
                while sqlite3_step(s) == SQLITE_ROW {
                    let item = readBookRow(s)
                    let key = item.isbn13 ?? item.title
                    if !seenISBNs.contains(key) && results.count < limit {
                        seenISBNs.insert(key)
                        results.append(item)
                    }
                }
            }
            if let stmt { sqlite3_finalize(stmt) }
        }

        let elapsed = finishTiming(startNs: startNs, clock: clock, metric: .titleSearch)
        queryLogs.append(CatalogQueryLog(kind: "search", query: query, resultCount: results.count, elapsedMs: elapsed))
        return results
    }

    /// Returns all books currently in the SQLite catalog.
    public func allBooks() -> [H20BiblioItem] {
        guard status == .ready, let db = readOnlyHandle else { return [] }
        let sql = """
        SELECT isbn13, title, author, raw_creator, publisher, label, published_year, ndc, series_title, volume_number
        FROM books
        ORDER BY rowid ASC;
        """
        var stmt: OpaquePointer?
        defer {
            if let stmt { sqlite3_finalize(stmt) }
        }
        var items: [H20BiblioItem] = []
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let s = stmt {
            while sqlite3_step(s) == SQLITE_ROW {
                items.append(readBookRow(s))
            }
        }
        return items
    }

    /// Queries the `cooccurrence` table joined with `books`, enforcing `count >= 10` and `ndc LIKE '9%'` (AC-148).
    public func cooccurrenceCandidates(forISBN13 sourceISBN13: String) -> [H24CooccurrenceCandidate] {
        guard status == .ready, let db = readOnlyHandle, !sourceISBN13.isEmpty else { return [] }
        let sql = """
        SELECT c.to_isbn13, b.title, b.author, b.publisher, b.label, COALESCE(c.ndc, b.ndc, '') AS resolved_ndc, c.count
        FROM cooccurrence c
        LEFT JOIN books b ON b.isbn13 = c.to_isbn13
        WHERE c.from_isbn13 = ?1
          AND c.count >= 10
          AND COALESCE(c.ndc, b.ndc, '') LIKE '9%'
        ORDER BY c.count DESC, c.to_isbn13 ASC;
        """
        var stmt: OpaquePointer?
        defer {
            if let stmt { sqlite3_finalize(stmt) }
        }
        var results: [H24CooccurrenceCandidate] = []
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let s = stmt {
            bindText(s, index: 1, value: sourceISBN13)
            while sqlite3_step(s) == SQLITE_ROW {
                let toISBN = columnText(s, index: 0) ?? ""
                let title = columnText(s, index: 1) ?? toISBN
                let author = columnText(s, index: 2)
                let publisher = columnText(s, index: 3)
                let label = columnText(s, index: 4)
                let ndc = columnText(s, index: 5) ?? ""
                let count = Int(sqlite3_column_int(s, 6))
                if !toISBN.isEmpty {
                    results.append(
                        H24CooccurrenceCandidate(
                            isbn13: toISBN,
                            title: title,
                            author: author,
                            publisher: publisher,
                            label: label,
                            ndc: ndc,
                            count: count
                        )
                    )
                }
            }
        }
        return results
    }

    // MARK: - Default Bundled Seed

    public nonisolated static func defaultBundledSeedBooks() -> [H20BiblioItem] {
        [
            H20BiblioItem(isbn13: "9784101010014", title: "こころ", author: "夏目漱石", publisher: "新潮社", label: "新潮文庫", publishedYear: 2004, ndc: "913.6"),
            H20BiblioItem(isbn13: "9784101010038", title: "坊っちゃん", author: "夏目漱石", publisher: "新潮社", label: nil, publishedYear: 2003, ndc: "913.6"),
            H20BiblioItem(isbn13: "9784101033013", title: "羅生門・鼻", author: "芥川龍之介", publisher: "新潮社", label: "新潮文庫", publishedYear: 2005, ndc: "913.6"),
            H20BiblioItem(isbn13: "9784101006055", title: "人間失格", author: "太宰治", publisher: "新潮社", label: "新潮文庫", publishedYear: 1952, ndc: "913.6"),
            H20BiblioItem(isbn13: "9784167911300", title: "コンビニ人間", author: "村田沙耶香", publisher: "文藝春秋", label: "文春文庫", publishedYear: 2018, ndc: "913.6")
        ]
    }

    // MARK: - SQLite Helpers

    private func finishTiming(startNs: UInt64, clock: ReadingClock?, metric: LatencyMetric) -> Double {
        if let clock {
            return clock.endInterval(metric)
        }
        let endNs = DispatchTime.now().uptimeNanoseconds
        return Double(endNs >= startNs ? endNs - startNs : 0) / 1_000_000.0
    }

    private func execSQL(_ db: OpaquePointer, _ sql: String) -> Bool {
        sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK
    }

    private func bindText(_ stmt: OpaquePointer, index: Int32, value: String) {
        _ = value.withCString { cStr in
            sqlite3_bind_text(stmt, index, cStr, -1, sqliteTransientDestructor)
        }
    }

    private func bindOptionalText(_ stmt: OpaquePointer, index: Int32, value: String?) {
        if let value, !value.isEmpty {
            bindText(stmt, index: index, value: value)
        } else {
            sqlite3_bind_null(stmt, index)
        }
    }

    private func bindOptionalInt(_ stmt: OpaquePointer, index: Int32, value: Int?) {
        if let value {
            sqlite3_bind_int(stmt, index, Int32(value))
        } else {
            sqlite3_bind_null(stmt, index)
        }
    }

    private func columnText(_ stmt: OpaquePointer, index: Int32) -> String? {
        guard sqlite3_column_type(stmt, index) != SQLITE_NULL,
              let cStr = sqlite3_column_text(stmt, index) else {
            return nil
        }
        return String(cString: cStr)
    }

    private func columnInt(_ stmt: OpaquePointer, index: Int32) -> Int? {
        guard sqlite3_column_type(stmt, index) != SQLITE_NULL else {
            return nil
        }
        return Int(sqlite3_column_int(stmt, index))
    }

    private func readBookRow(_ stmt: OpaquePointer) -> H20BiblioItem {
        let isbn = columnText(stmt, index: 0)
        let title = columnText(stmt, index: 1) ?? ""
        let author = columnText(stmt, index: 2)
        let rawCreator = columnText(stmt, index: 3)
        let publisher = columnText(stmt, index: 4)
        let label = columnText(stmt, index: 5)
        let publishedYear = columnInt(stmt, index: 6)
        let ndc = columnText(stmt, index: 7)
        let seriesTitle = columnText(stmt, index: 8)
        let volumeNumber = columnInt(stmt, index: 9)
        return H20BiblioItem(
            isbn13: isbn,
            title: title,
            author: author,
            rawDcCreator: rawCreator,
            publisher: publisher,
            label: label,
            publishedYear: publishedYear,
            ndc: ndc,
            seriesTitle: seriesTitle,
            volumeNumber: volumeNumber
        )
    }
}
