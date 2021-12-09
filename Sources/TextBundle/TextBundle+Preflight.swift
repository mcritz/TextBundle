import Foundation

extension TextBundle {
    func makeLocalAssetLinks() {
        // find all asset filenames
        // find if they are referenced in the text
        // if their links don't match the format `./assets/\(filename)` then copy asset
    }
    
    func findUnmatchedAssets() {
        // find all asset filenames
        // find if they are referenced in the text
        // delete them if not referenced
    }
    
    func copyAssets() {
        // find all image links that are not in the `./assets/\(filename)` format
        // if the image links don't start with `http`
        // if image links don't match `./assets/\(filename)`
        // copy / download assets to the `./assets/` directory as `filename`
        // replace all links in text to `./assets/\(filename)`
    }
}
