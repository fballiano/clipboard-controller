import AppKit

/// The "clipboard" outline from Tabler Icons, MIT licensed, Copyright (c)
/// 2020-2026 Paweł Kuna. See https://tabler.io/icons.
///
/// `Tools/make-icon.swift` holds the same path for the application icon. That
/// script runs on its own, outside the application, so it cannot import this
/// file. Change the two together.
@MainActor
enum ClipboardGlyph {
    /// Tabler draws on a 24 x 24 grid, with the y axis pointing down.
    static let grid: CGFloat = 24

    /// The stroke width Tabler ships.
    static let strokeWidth: CGFloat = 2

    /// The image for the menu bar. It is a template, so the menu bar colours it
    /// itself: it follows light and dark, and it inverts while the menu is open.
    static let menuBar: NSImage = image(side: 20, privateMode: false)

    /// The same board with a line through it. The line says that the app stores
    /// nothing at the moment.
    static let menuBarPrivate: NSImage = image(side: 20, privateMode: true)

    /// The outline in its own 24 x 24 space.
    ///
    /// The corners use `appendArc(from:to:radius:)`, the tangent arc. It is the
    /// same shape that the `a 2 2 0 0 0` command of the SVG draws, and it needs
    /// no angle, so a flipped y axis changes nothing.
    static func outline(privateMode: Bool = false) -> NSBezierPath {
        let path = NSBezierPath()

        // <path d="M9 5h-2a2 2 0 0 0 -2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-12a2 2 0 0 0 -2 -2h-2" />
        // The board: a rounded rectangle with a gap on the top edge.
        path.move(to: NSPoint(x: 9, y: 5))
        path.appendArc(from: NSPoint(x: 5, y: 5), to: NSPoint(x: 5, y: 21), radius: 2)
        path.appendArc(from: NSPoint(x: 5, y: 21), to: NSPoint(x: 19, y: 21), radius: 2)
        path.appendArc(from: NSPoint(x: 19, y: 21), to: NSPoint(x: 19, y: 5), radius: 2)
        path.appendArc(from: NSPoint(x: 19, y: 5), to: NSPoint(x: 9, y: 5), radius: 2)
        path.line(to: NSPoint(x: 15, y: 5))

        // <path d="M9 5a2 2 0 0 1 2 -2h2a2 2 0 0 1 2 2a2 2 0 0 1 -2 2h-2a2 2 0 0 1 -2 -2" />
        // The clip on top: a rectangle with two half circle ends.
        path.append(NSBezierPath(
            roundedRect: NSRect(x: 9, y: 3, width: 6, height: 4),
            xRadius: 2,
            yRadius: 2
        ))

        if privateMode {
            // A line through the board.
            path.move(to: NSPoint(x: 4, y: 20))
            path.line(to: NSPoint(x: 20, y: 4))
        }

        return path
    }

    private static func image(side: CGFloat, privateMode: Bool) -> NSImage {
        // `flipped: true` points the y axis down, as SVG does, so the path
        // needs no mirroring.
        let image = NSImage(size: NSSize(width: side, height: side), flipped: true) { _ in
            let scale = side / grid

            let glyph = outline(privateMode: privateMode)
            var transform = AffineTransform()
            transform.scale(scale)
            glyph.transform(using: transform)

            glyph.lineWidth = strokeWidth * scale
            glyph.lineCapStyle = .round // stroke-linecap="round"
            glyph.lineJoinStyle = .round // stroke-linejoin="round"

            // A template image only keeps its shape. The colour comes from the
            // menu bar.
            NSColor.black.setStroke()
            glyph.stroke()

            return true
        }

        image.isTemplate = true
        return image
    }
}
