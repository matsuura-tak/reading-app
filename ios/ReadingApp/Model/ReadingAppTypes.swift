import Foundation
import ReadingCore
import ReadingStore

public enum AppActiveTab: String, Codable, Sendable, Equatable {
    case bookmark
    case shelf
}

public enum AppScreenID: String, Codable, Sendable, Equatable {
    case bookmarkEmpty
    case bookmarkCurrent
    case sessionActive
    case markInput
    case sessionDone
    case shelf
    case bookAdd
    case bookDetail
    case recordList
    case settings
    case storePaywall
}
