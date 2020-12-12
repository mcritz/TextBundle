import Foundation

public protocol TextBundleRepresentable {
    var name: String { get set }
    var textContents: String { get set }
    var assetURLS: [URL]? { get set }
    var meta: TextBundle.Metadata { get set }
}
