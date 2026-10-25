import BackgroundAssets
import Foundation

@main
final class BackgroundAssetsHandler: NSObject, BADownloaderExtension {
    override init() {
        super.init()
    }

    func downloads(
        for request: BAContentRequest,
        manifestURL: URL,
        extensionInfo: BAAppExtensionInfo
    ) -> Set<BADownload> {
        guard let data = try? Data(contentsOf: manifestURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let urlStr = json["catalogURL"] as? String,
              let assetURL = URL(string: urlStr),
              let appGroup = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String ?? Optional("group.com.takumamatsuura.readingapp") else {
            return []
        }
        let download = BAURLDownload(
            identifier: "com.takumamatsuura.readingapp.catalog.sqlite",
            request: URLRequest(url: assetURL),
            essential: false,
            fileSize: (json["fileSize"] as? Int) ?? 1024 * 1024,
            applicationGroupIdentifier: appGroup,
            priority: .default
        )
        return [download]
    }

    func backgroundDownload(_ download: BADownload, finishedWithFileURL fileURL: URL) {
        let fm = FileManager.default
        guard let containerURL = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.com.takumamatsuura.readingapp") else {
            return
        }
        let catalogDir = containerURL.appendingPathComponent("Catalog", isDirectory: true)
        try? fm.createDirectory(at: catalogDir, withIntermediateDirectories: true)
        var destURL = catalogDir.appendingPathComponent("catalog.sqlite")
        if fm.fileExists(atPath: destURL.path) {
            try? fm.removeItem(at: destURL)
        }
        try? fm.moveItem(at: fileURL, to: destURL)
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try? destURL.setResourceValues(resourceValues)
    }
}
