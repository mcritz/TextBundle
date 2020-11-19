import Foundation
import Zip

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

// MARK: -

extension TextBundle {
    
    static func unpack(_ packURL: URL) throws -> URL {
        let caches = try FileManager.default
            .url(for: .cachesDirectory,
                 in: .userDomainMask,
                 appropriateFor: packURL,
                 create: false)
        Zip.addCustomFileExtension("textpack")
        try Zip.unzipFile(packURL,
                            destination: caches,
                            overwrite: true,
                            password: nil)
        return caches.appendingPathComponent(packURL.lastPathComponent)
    }
    
    static func readTextPack(_ packURL: URL) throws -> TextBundle {
        try TextBundle.readTextBundle(try TextBundle.unpack(packURL))
    }
    
    static func readTextBundle(_ baseURL: URL) throws -> TextBundle {
        let jsonDecoder = JSONDecoder()
        let assetsURL = baseURL.appendingPathComponent("assets")
        let assetsURLs = try FileManager.default
                .contentsOfDirectory(at: assetsURL,
                                        includingPropertiesForKeys: nil,
                                        options: [
                                            .skipsSubdirectoryDescendants, .skipsHiddenFiles
                                        ])
        let infoJsonURL = baseURL.appendingPathComponent("info.json")
        let markdownContents = baseURL.appendingPathComponent("text.markdown")
        guard let infoData = FileManager.default.contents(atPath: infoJsonURL.path),
              let textContentsData = FileManager.default.contents(atPath: markdownContents.path),
              let textContents = String(data: textContentsData, encoding: .utf8)
               else {
            throw Errors.invalidFormat
        }
        let metaData = try jsonDecoder.decode(TextBundle.Metadata.self, from: infoData)
        return TextBundle(name: "Name", contents: textContents, metadata: metaData, assetURLs: assetsURLs)
    }
    
    static func read(_ url: URL) throws -> TextBundle {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "textbundle":
            return try TextBundle.readTextBundle(url)
        case "textpack":
            return try TextBundle.readTextPack(url)
        default:
            throw Errors.invalidFormat
        }
    }
}

// MARK: - Pack
extension TextBundle {
    
    private func compress(_ url: URL, progress: ((Double) -> ())? ) throws -> URL {
        let destination = url.deletingLastPathComponent()
            .appendingPathComponent("\(self.name).textpack")
        do {
            try Zip.zipFiles(paths: [url], zipFilePath: destination, password: nil, progress: { (inProgress) -> () in
                if let progress = progress { progress(inProgress) }
            })
        } catch {
            throw error
        }
        return destination
    }
    
    public func bundle(destinationURL: URL,
                       compressed: Bool = false,
                       progress: ((Double) -> ())? = nil,
                       completion: (URL) -> ()) throws {
        
        var isDirectory = ObjCBool(true)
        guard FileManager.default.fileExists(atPath: destinationURL.path, isDirectory: &isDirectory) else {
            throw Errors.invalidDirectory
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
        
        if compressed {
            completion(try compress(bundleDirectoryURL, progress: progress))
            return
        }
        completion(bundleDirectoryURL)
    }
}
