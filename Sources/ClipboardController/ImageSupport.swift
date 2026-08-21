import AppKit
import Foundation

/// Reads an image from the clipboard and makes a small copy for the menu.
@MainActor
enum ImageSupport {
    /// The width and the height of the picture in the menu row and in the
    /// history window.
    static let thumbnailSide: CGFloat = 48

    /// The pasteboard types that hold a picture, best first.
    static let types: [NSPasteboard.PasteboardType] = [
        .png,
        .tiff,
        NSPasteboard.PasteboardType("public.jpeg"),
        NSPasteboard.PasteboardType("com.compuserve.gif"),
        NSPasteboard.PasteboardType("public.heic"),
    ]

    struct Picture {
        let png: Data
        let thumbnail: Data
        let width: Int
        let height: Int
    }

    /// Turns the data of the clipboard into a PNG and a thumbnail.
    ///
    /// Every picture becomes a PNG, so the store holds one format and the menu
    /// needs no reader for the rest.
    static func picture(from data: Data) -> Picture? {
        guard let image = NSBitmapImageRep(data: data) else { return nil }

        let width = image.pixelsWide
        let height = image.pixelsHigh
        guard width > 0, height > 0 else { return nil }

        guard let png = image.representation(using: .png, properties: [:]) else { return nil }
        guard let thumbnail = makeThumbnail(from: image) else { return nil }

        return Picture(png: png, thumbnail: thumbnail, width: width, height: height)
    }

    /// A square PNG that fits the menu row. The picture keeps its proportions.
    private static func makeThumbnail(from source: NSBitmapImageRep) -> Data? {
        let side = thumbnailSide * 2 // Two pixels for each point, for a Retina screen.
        let width = CGFloat(source.pixelsWide)
        let height = CGFloat(source.pixelsHigh)
        let scale = min(side / width, side / height, 1)

        let targetWidth = max(1, Int((width * scale).rounded()))
        let targetHeight = max(1, Int((height * scale).rounded()))

        guard let target = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: targetWidth,
            pixelsHigh: targetHeight,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }

        target.size = NSSize(width: targetWidth, height: targetHeight)

        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }

        guard let context = NSGraphicsContext(bitmapImageRep: target) else { return nil }
        NSGraphicsContext.current = context
        context.imageInterpolation = .high

        source.draw(in: NSRect(x: 0, y: 0, width: targetWidth, height: targetHeight))

        return target.representation(using: .png, properties: [:])
    }

    /// The thumbnail on a square canvas, in the middle.
    ///
    /// A menu row puts the title after the icon, so a wide picture pushes its
    /// title further to the right than a tall one. A square icon gives every
    /// image row the same indent. Empty data gives a clear square, which holds
    /// the same space for a text row.
    ///
    /// The square is made here and not when the picture arrives, because a clip
    /// of an older version already holds a thumbnail of its own proportions.
    static func squareIcon(from data: Data?, side sideLength: CGFloat = thumbnailSide) -> NSImage {
        let side = NSSize(width: sideLength, height: sideLength)
        let canvas = NSImage(size: side)

        canvas.lockFocus()
        defer { canvas.unlockFocus() }

        if let data, let image = NSImage(data: data) {
            let size = image.size
            guard size.width > 0, size.height > 0 else { return canvas }

            let scale = min(side.width / size.width, side.height / size.height, 1)
            let width = size.width * scale
            let height = size.height * scale

            image.draw(in: NSRect(
                x: (side.width - width) / 2,
                y: (side.height - height) / 2,
                width: width,
                height: height
            ))
        }

        return canvas
    }

    /// `1280 × 720`, for the row title. The function only formats two numbers,
    /// so it needs no actor and `Clip` can call it.
    nonisolated static func sizeText(width: Int, height: Int) -> String {
        "\(width) × \(height)"
    }
}
