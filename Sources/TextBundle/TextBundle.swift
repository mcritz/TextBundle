import Foundation
import Zip

public struct TextBundle: Codable {
    public var name: String
    public var textContents: String
    public var assetURLs: [URL]?
    public var meta: Metadata
    
    public init(name: String, contents: String, metadata: Metadata = Metadata(), assetURLs: [URL]?) {
        self.name = name
        self.textContents = contents
        self.meta = metadata
        self.assetURLs = assetURLs
    }
}

extension TextBundle: Equatable { }

// MARK: - Metadata

extension TextBundle {
    public struct Metadata: Codable, Equatable {
        
        public typealias UTI = UniversalTypeIdentifier
        public enum UniversalTypeIdentifier: String, Codable {
            case html = "public.html"
            case markdown = "net.daringfireball.markdown"
            case package = "org.textbundle.package"
        }
        
        public var version: Int = 2
        public var type: String = UTI.markdown.rawValue
        public var transient: Bool? = false
        public var creatorURL: URL?
        public var creatorIdentifier: String?
        public var sourceURL: URL?
        
        public init(_ version: Int = 2, type: String = UTI.markdown.rawValue, transient: Bool? = false, creatorURL: URL? = nil, creatorIdentifier: String? = nil, sourceURL: URL? = nil) {
            self.version = version
            self.type = type
            self.transient = transient
            self.creatorURL = creatorURL
            self.creatorIdentifier = creatorIdentifier
            self.sourceURL = sourceURL
        }
    }
}

// MARK: - Pack
public extension TextBundle {
    
    /// Compresses a file as a `.textpack`
    /// - Parameters:
    ///   - url: filesystem `URL` of the source file
    ///   - progress: handler for Zip progress
    /// - Returns: `URL` of the compressed file
    private func compress(_ url: URL, progress: ((Double) -> ())? ) throws -> URL {
        let fileName = self.name + Constants.pack.ext
        let destination = url.deletingLastPathComponent()
            .appendingPathComponent(fileName)
        do {
            try Zip.zipFiles(paths: [url],
                             zipFilePath: destination,
                             password: nil,
                             progress: { (inProgress) -> () in
                if let progress = progress { progress(inProgress) }
            })
        } catch {
            throw error
        }
        return destination
    }
    
    /// Writes a `TextBundle` to disk as either uncompressed `.textbundle` or compressed `.textpack`
    /// - Parameters:
    ///   - destinationURL: directory where the bundle will be saved
    ///   - compressed: `true` will save as Zip-compressed `.textpack` file. Default `false` will save as uncompressed `.textpack` bundle.
    ///   - progress: handler for compression progress
    ///   - completion: handler with the destination `URL`
    func bundle(destinationURL: URL,
                       compressed: Bool = false,
                       progress: ((Double) -> ())? = nil,
                       completion: (URL) -> ()) throws {
        
        var isDirectory = ObjCBool(true)
        guard FileManager.default.fileExists(atPath: destinationURL.path,
                                             isDirectory: &isDirectory) else {
            throw Errors.invalidDirectory
        }
        
        let bundleDirectoryURL = destinationURL.appendingPathComponent(name.appending(Constants.bundle.ext),
                                                                       isDirectory: true)
        try FileManager.default.createDirectory(at: bundleDirectoryURL,
                                                withIntermediateDirectories: false,
                                                attributes: nil)
        
        // info.json
        let infoData = try JSONEncoder().encode(meta)
        FileManager.default.createFile(atPath:
                                        bundleDirectoryURL.appendingPathComponent(Constants.infoFileName.rawValue,
                                                                                  isDirectory: false).path,
                                           contents: infoData,
                                           attributes: nil)
        
        
        // text.markdown
        FileManager.default.createFile(atPath: bundleDirectoryURL.appendingPathComponent(Constants.markdownContentsFileName.rawValue,
                                                                                         isDirectory: false).path,
                                       contents: textContents.data(using: .utf8),
                                       attributes: nil)
        
        // assets/
        let assetsDirectory = bundleDirectoryURL.appendingPathComponent(Constants.assetsFolderName.rawValue,
                                                                        isDirectory: true)
        try FileManager.default.createDirectory(at: assetsDirectory,
                                                withIntermediateDirectories: false,
                                                attributes: nil)
        if let assetURLs = assetURLs {
            try assetURLs.forEach { url in
                let fileName = url.lastPathComponent
                try FileManager.default.copyItem(at: url,
                                             to: assetsDirectory.appendingPathComponent(fileName,
                                                                                        isDirectory: false))
            }
        }
        
        if compressed {
            let packURL = try compress(bundleDirectoryURL, progress: progress)
            try FileManager.default.removeItem(at: bundleDirectoryURL)
            completion(packURL)
            return
        }
        completion(bundleDirectoryURL)
    }
}

// MARK: - Unpack

public extension TextBundle {
    
    /// Reads a `.textbundle` or `.textpack`.
    /// - Parameter url: FileSystem `URL` of the Bundle
    /// - Throws: “Invalid Format” if nothing can be read
    /// - Returns: `TextBundle`
    static func read(_ url: URL) throws -> TextBundle {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case Constants.bundle.rawValue:
            return try TextBundle.readTextBundle(url)
        case Constants.pack.rawValue:
            return try TextBundle.readTextPack(url)
        default:
            throw Errors.invalidFormat
        }
    }
    
    /// Uncompresses a file as a `.textbundle` Bundle in the `Caches` directory
    /// - Parameter packURL: FileSystem `URL` of the source file. Ex: `helloworld.textpack`
    /// - Returns: `URL` of the uncompressed contents as a `.textbundle`
    static func unpack(_ packURL: URL) throws -> URL {
        let caches = try FileManager.default
            .url(for: .cachesDirectory,
                 in: .userDomainMask,
                 appropriateFor: packURL,
                 create: false)
        Zip.addCustomFileExtension(Constants.pack.rawValue)
        try Zip.unzipFile(packURL,
                            destination: caches,
                            overwrite: true,
                            password: nil)
        let bundleFilename = packURL.deletingPathExtension()
            .lastPathComponent
            .appending(Constants.bundle.ext)
        return caches.appendingPathComponent(bundleFilename)
    }
    
    /// Reads a `.textpack` bundle
    /// - Parameter packURL:  FileSystem `URL` of the bundle
    static func readTextPack(_ packURL: URL) throws -> TextBundle {
        try TextBundle.readTextBundle(try TextBundle.unpack(packURL))
    }
    
    /// Reads a `.textbundle` Bundle.
    /// Consider calling `TextBundle.read(_:)` which can handle `.textbundle` or `.textpack`.
    /// - Parameter baseURL: `URL` of the Textbundle
    /// - Returns: `TextBundle` of the contents
    static func readTextBundle(_ baseURL: URL) throws -> TextBundle {
        let bundleName = baseURL.deletingPathExtension().lastPathComponent
        let jsonDecoder = JSONDecoder()
        let assetsURL = baseURL.appendingPathComponent(Constants.assetsFolderName.rawValue)
        let assetsURLs = try FileManager.default
                .contentsOfDirectory(at: assetsURL,
                                     includingPropertiesForKeys: nil,
                                     options: [
                                        .skipsSubdirectoryDescendants, .skipsHiddenFiles
                                     ])
        let infoJsonURL = baseURL.appendingPathComponent(Constants.infoFileName.rawValue)
        let markdownContents = baseURL.appendingPathComponent(Constants.markdownContentsFileName.rawValue)
        guard let infoData = FileManager.default.contents(atPath: infoJsonURL.path),
              let textContentsData = FileManager.default.contents(atPath: markdownContents.path),
              let textContents = String(data: textContentsData, encoding: .utf8)
               else {
            throw Errors.invalidFormat
        }
        let metaData = try jsonDecoder.decode(TextBundle.Metadata.self, from: infoData)
        return TextBundle(name: bundleName,
                          contents: textContents,
                          metadata: metaData,
                          assetURLs: assetsURLs)
    }
}
