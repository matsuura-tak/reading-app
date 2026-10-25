import ActivityKit
import Foundation

public struct ReadingActivityAttributes: ActivityAttributes, Codable, Sendable {
    public struct ContentState: Codable, Hashable, Sendable {
        public var mode: String
        public var title: String
        public var line: String?
        public var progressText: String?
        public var summaryText: String?

        public init(
            mode: String = "reading",
            title: String,
            line: String? = nil,
            progressText: String? = nil,
            summaryText: String? = nil
        ) {
            self.mode = mode
            self.title = title
            self.line = line
            self.progressText = progressText
            self.summaryText = summaryText
        }
    }

    public var bookId: UUID?
    public var startedAt: Date?

    public init(bookId: UUID? = nil, startedAt: Date? = nil) {
        self.bookId = bookId
        self.startedAt = startedAt
    }
}
