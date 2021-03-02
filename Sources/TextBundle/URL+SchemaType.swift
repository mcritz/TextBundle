import Foundation

extension URL {
    enum SchemaType: Int, Codable {
        case unknown = -1
        case none = 0
        case filesystem = 1
        case network = 2
        
        init(_ schema: String?) {
            guard schema == schema else {
                self = .none
                return
            }
            switch schema {
            case "https", "http", "ftp", "sftp":
                self = .network
            case "file":
                self = .filesystem
            case "":
                self = .none
            default:
                self = .unknown
            }
        }
        
        init(_ url: URL) {
            self.init(url.scheme)
        }
    }
}
