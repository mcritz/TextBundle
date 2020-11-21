extension TextBundle {
    enum Constants: String, RawRepresentable {
        case infoFileName = "info.json"
        case markdownContentsFileName = "text.markdown"
        case assetsFolderName = "assets"
        case bundle = "textbundle"
        case pack = "textpack"
        
        var ext: String {
            "." + self.rawValue
        }
    }
}
