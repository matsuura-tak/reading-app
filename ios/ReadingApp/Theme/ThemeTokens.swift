import SwiftUI
import ReadingCore

public enum ReadingSharedContainer {
    public static let appGroupIdentifier = "group.com.example.readingapp"

    public nonisolated static func containerDirectoryURL() -> URL {
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            return groupURL
        }
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
    }

    public nonisolated static func widgetSnapshotFileURL() -> URL {
        containerDirectoryURL()
            .appendingPathComponent("Shared", isDirectory: true)
            .appendingPathComponent("widget-snapshot.json", isDirectory: false)
    }

    public nonisolated static func loadWidgetSnapshot() -> WidgetSnapshot {
        let url = widgetSnapshotFileURL()
        if let data = try? Data(contentsOf: url) {
            return WidgetSnapshot.decodeForWidgetRenderer(from: data)
        }
        return WidgetSnapshot(
            version: 1,
            updatedAt: "1970-01-01T00:00:00Z",
            appearanceID: .default,
            hideOnWidgets: false,
            currentBook: nil
        )
    }
}

public enum ThemeColorToken: String, Sendable {
    case bgPrimary = "BgPrimary"
    case bgSecondary = "BgSecondary"
    case textPrimary = "TextPrimary"
    case textSecondary = "TextSecondary"
    case accent = "Accent"
    case hairline = "Hairline"

    public func assetName(for appearanceID: AppearanceID) -> String {
        let prefix: String
        switch appearanceID {
        case .default, .light, .dark:
            prefix = "Default"
        case .kinari:
            prefix = "Kinari"
        case .sumi:
            prefix = "Sumi"
        case .shu:
            prefix = "Shu"
        }
        return "\(prefix)\(rawValue)"
    }
}

public struct ThemePalette: Sendable, Equatable {
    public let appearanceID: AppearanceID

    public init(appearanceID: AppearanceID = .default) {
        self.appearanceID = appearanceID
    }

    public var bgPrimary: Color {
        Color(ThemeColorToken.bgPrimary.assetName(for: appearanceID))
    }

    public var bgSecondary: Color {
        Color(ThemeColorToken.bgSecondary.assetName(for: appearanceID))
    }

    public var textPrimary: Color {
        Color(ThemeColorToken.textPrimary.assetName(for: appearanceID))
    }

    public var textSecondary: Color {
        Color(ThemeColorToken.textSecondary.assetName(for: appearanceID))
    }

    public var accent: Color {
        Color(ThemeColorToken.accent.assetName(for: appearanceID))
    }

    public var hairline: Color {
        Color(ThemeColorToken.hairline.assetName(for: appearanceID))
    }

    public var semanticError: Color {
        Color("SemanticError")
    }

    public var ocrSelectedFill: Color {
        Color("OCRSelectedFill")
    }

    public var ocrSelectedStroke: Color {
        Color("OCRSelectedStroke")
    }

    public var ocrUnselectedFill: Color {
        Color("OCRUnselectedFill")
    }

    public var ocrUnselectedStroke: Color {
        Color("OCRUnselectedStroke")
    }

    public var preferredColorScheme: ColorScheme? {
        switch appearanceID {
        case .default, .kinari, .shu:
            return nil
        case .light:
            return .light
        case .dark, .sumi:
            return .dark
        }
    }
}

extension EnvironmentValues {
    @Entry public var themePalette: ThemePalette = ThemePalette(appearanceID: .default)
}
