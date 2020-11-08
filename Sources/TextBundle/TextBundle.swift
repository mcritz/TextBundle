import Foundation

public struct TextBundle: Codable {
    var name: String
    var textContents: String
    var assetURLs: [URL]?
    var meta: Metadata
    
    init(name: String, contents: String, metadata: Metadata = Metadata(), assetURLs: [URL]?) {
        self.name = name
        self.textContents = contents
        self.meta = metadata
        self.assetURLs = assetURLs
    }
}

extension TextBundle {
    public struct Metadata: Codable {
        public enum BundleType: String, Codable {
            case markdown = "net.daringfireball.markdown"
        }
        
        var version: Int = 3
        var type: BundleType = .markdown
        var transient: Bool? = false
        var creatorURL: URL?
        var creatorIdentifier: String?
        var sourceURL: URL?
    }
}

extension TextBundle {
    enum Fail: Error {
        case invalidDirectory
    }
}

extension TextBundle {
    public func pack(destinationURL: URL, completion: (Bool) -> ()) throws {
        
        var isDirectory = ObjCBool(true)
        guard FileManager.default.fileExists(atPath: destinationURL.path, isDirectory: &isDirectory) else {
            throw TextBundle.Fail.invalidDirectory
        }
        
        let bundleDirectoryURL = destinationURL.appendingPathComponent(name.appending(".textbundle"), isDirectory: true)
        try FileManager.default.createDirectory(at: bundleDirectoryURL,
                                                withIntermediateDirectories: false,
                                                attributes: nil)
        
        // info.json
        let infoData = try JSONEncoder().encode(meta)
        FileManager.default.createFile(atPath:
                                            bundleDirectoryURL.appendingPathComponent("info.json", isDirectory: false).path,
                                           contents: infoData,
                                           attributes: nil)
        
        
        // text.markdown
        FileManager.default.createFile(atPath: bundleDirectoryURL.appendingPathComponent("text.markdown", isDirectory: false).path,
                                       contents: textContents.data(using: .utf8),
                                       attributes: nil)
        
        // assets/
        let assetsDirectory = bundleDirectoryURL.appendingPathComponent("assets", isDirectory: true)
        try FileManager.default.createDirectory(at: assetsDirectory,
                                                withIntermediateDirectories: false,
                                                attributes: nil)
        if let assetURLs = assetURLs {
            try assetURLs.forEach { url in
                let fileName = url.lastPathComponent
                try FileManager.default.copyItem(at: url,
                                             to: assetsDirectory.appendingPathComponent(fileName, isDirectory: false))
            }
        }
        completion(true)
    }
}
