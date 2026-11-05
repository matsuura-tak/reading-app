import Foundation
import ReadingCore
import ReadingStore

public enum AppActiveTab: String, Codable, Sendable, Equatable {
    case bookmark
    case shelf
    case settings
}

public enum AppScreenID: String, Codable, Sendable, Equatable {
    case bookmarkEmpty
    case bookmarkCurrent
    case sessionActive
    case markInput
    case bookmarkMarkSelect
    case bookmarkMarkLineInput
    case bookmarkMarkPageInput
    case bookmarkMarkCamera
    case sessionDone
    case sessionResult
    case widgetGuide
    case shelf
    case shelfList
    case bookAdd
    case bookAddActionSheet
    case barcodeScan
    case coverScan
    case colophonScan
    case bookSearchList
    case bookManualInput
    case bookshelfScan
    case bookDetail
    case bookEdit
    case recordList
    case recordEdit
    case shareCardPreview
    case finishNight
    case settings
    case settingsMain
    case storePaywall
    case storePurchasePreview
}
