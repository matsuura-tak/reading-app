#if UITEST_HOOKS
import Foundation
import ReadingCore

public struct UITestHookOCRPayload: Codable, Sendable, Equatable {
    public var mode: String
    public var isHoldReleased: Bool
    public var selectedColumnIndex: Int?
    public var detectedPageNumber: Int?
    public var columnsCount: Int

    public init(
        mode: String = "empty",
        isHoldReleased: Bool = false,
        selectedColumnIndex: Int? = nil,
        detectedPageNumber: Int? = nil,
        columnsCount: Int = 0
    ) {
        self.mode = mode
        self.isHoldReleased = isHoldReleased
        self.selectedColumnIndex = selectedColumnIndex
        self.detectedPageNumber = detectedPageNumber
        self.columnsCount = columnsCount
    }
}

public struct UITestHookA11yPayload: Codable, Sendable, Equatable {
    public var reduceMotionEnabled: Bool
    public var dynamicTypeSize: String
    public var activeTab: String
    public var currentScreen: String

    public init(
        reduceMotionEnabled: Bool = false,
        dynamicTypeSize: String = "large",
        activeTab: String = "bookmark",
        currentScreen: String = "bookmarkEmpty"
    ) {
        self.reduceMotionEnabled = reduceMotionEnabled
        self.dynamicTypeSize = dynamicTypeSize
        self.activeTab = activeTab
        self.currentScreen = currentScreen
    }
}
#endif
