# [mcritz / TextBundle](https://github.com/mcritz/TextBundle)

Swift-first, Swift-best package for [TextBundle](http://textbundle.org). Supports [version 2 of the spec](http://textbundle.org/spec/).

If you’re looking for an alternative implemenetation, try [shinyfrog/TextBundle](https://github.com/shinyfrog/TextBundle).

---

## Installation

In `Package.swift`

```
dependencies: [
    .package(url: "https://github.com/mcritz/TextBundle.git", .upToNextMajor(from: "1.0.0")),
],
```

... and further down in targets…

```
dependencies: [
    .product(name: "TextBundle", package: "TextBundle"),
],
```

## Usage


### Reading from Disk
Read a TextBundle as either `.textbundle` or `.textpack` from disk

```
let myFileURL: URL = ...
let myTextBundle = try TextBundle.read(myFileURL)
let contents: String = myTextBundle.textContents
```

### Creating a bundle

```
let myBundle = TextBundle(name: "HelloWorld", contents: "# Hello, World!")
```

### Writing to disk

```
myBundle.bundle(destinationURL: myURL) { bundleFileURL in
    print(bundleFileURL.path)
}
```

---

Thanks to Guillermo Casales @gcasales for making this photo available freely on Unsplash 🎁
https://unsplash.com/photos/LQfcolSv2M0
