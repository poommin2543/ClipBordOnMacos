import AppKit
import Foundation

extension NSImage {
    var pngData: Data? {
        guard
            let tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffRepresentation)
        else {
            return nil
        }

        return bitmap.representation(using: .png, properties: [:])
    }

    var pixelSize: CGSize {
        guard let representation = representations.first else {
            return size
        }

        let width = representation.pixelsWide > 0 ? representation.pixelsWide : Int(size.width)
        let height = representation.pixelsHigh > 0 ? representation.pixelsHigh : Int(size.height)
        return CGSize(width: width, height: height)
    }
}
