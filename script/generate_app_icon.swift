import AppKit
import Foundation

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "Resources/AppIcon.iconset")
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

struct IconImage {
    let name: String
    let size: CGFloat
}

let images: [IconImage] = [
    IconImage(name: "icon_16x16.png", size: 16),
    IconImage(name: "icon_16x16@2x.png", size: 32),
    IconImage(name: "icon_32x32.png", size: 32),
    IconImage(name: "icon_32x32@2x.png", size: 64),
    IconImage(name: "icon_128x128.png", size: 128),
    IconImage(name: "icon_128x128@2x.png", size: 256),
    IconImage(name: "icon_256x256.png", size: 256),
    IconImage(name: "icon_256x256@2x.png", size: 512),
    IconImage(name: "icon_512x512.png", size: 512),
    IconImage(name: "icon_512x512@2x.png", size: 1024),
]

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
}

func rect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> NSRect {
    NSRect(x: x, y: y, width: width, height: height)
}

func roundedRect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, _ radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect(x, y, width, height), xRadius: radius, yRadius: radius)
}

/// Draw a filled circle centred at (cx, cy) with the given radius.
func fillCircle(cx: CGFloat, cy: CGFloat, radius: CGFloat) {
    let path = NSBezierPath(ovalIn: NSRect(x: cx - radius, y: cy - radius, width: radius * 2, height: radius * 2))
    path.fill()
}

/// Draw a stroked circle centred at (cx, cy) with the given radius.
func strokeCircle(cx: CGFloat, cy: CGFloat, radius: CGFloat, lineWidth: CGFloat) {
    let path = NSBezierPath(ovalIn: NSRect(x: cx - radius, y: cy - radius, width: radius * 2, height: radius * 2))
    path.lineWidth = lineWidth
    path.stroke()
}

func drawIcon(size: CGFloat) throws -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size),
        pixelsHigh: Int(size),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    rep.size = NSSize(width: size, height: size)

    guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
        throw NSError(domain: "ClipBordIcon", code: 1)
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.cgContext.setShouldAntialias(true)
    context.cgContext.setAllowsAntialiasing(true)

    // All drawing coordinates are in a 1024×1024 canvas, scaled to the target size.
    let scale = size / 1024
    context.cgContext.scaleBy(x: scale, y: scale)

    // ── Clear ────────────────────────────────────────────────────────────
    NSColor.clear.setFill()
    rect(0, 0, 1024, 1024).fill()

    // ── Background rounded-rect with deep indigo→violet gradient ─────────
    let bgShadow = NSShadow()
    bgShadow.shadowBlurRadius = 48
    bgShadow.shadowOffset = NSSize(width: 0, height: -24)
    bgShadow.shadowColor = NSColor.black.withAlphaComponent(0.30)

    NSGraphicsContext.saveGraphicsState()
    bgShadow.set()
    let bg = roundedRect(88, 72, 848, 848, 200)
    // Deep indigo (#1C1B4B) → electric violet (#6C3CE8)
    NSGradient(colors: [
        color(28, 27, 75),
        color(57, 35, 155),
        color(108, 60, 232),
    ])!.draw(in: bg, angle: -55)
    NSGraphicsContext.restoreGraphicsState()

    // Subtle inner highlight (gloss on top-left)
    let gloss = roundedRect(108, 640, 480, 260, 170)
    color(255, 255, 255, 0.07).setFill()
    gloss.fill()

    // ── Clipboard body ───────────────────────────────────────────────────
    // Back card (slightly offset for depth)
    let backCard = roundedRect(232, 202, 516, 618, 72)
    color(255, 255, 255, 0.12).setFill()
    backCard.fill()

    // Front card (main clipboard body)
    let cardShadow = NSShadow()
    cardShadow.shadowBlurRadius = 36
    cardShadow.shadowOffset = NSSize(width: 0, height: -16)
    cardShadow.shadowColor = NSColor.black.withAlphaComponent(0.28)

    NSGraphicsContext.saveGraphicsState()
    cardShadow.set()
    let frontCard = roundedRect(258, 188, 508, 618, 68)
    // Very slightly warm white card
    color(245, 244, 255).setFill()
    frontCard.fill()
    NSGraphicsContext.restoreGraphicsState()

    // Card border
    color(150, 130, 220, 0.25).setStroke()
    let cardBorder = roundedRect(258, 188, 508, 618, 68)
    cardBorder.lineWidth = 6
    cardBorder.stroke()

    // ── Clipboard clip (top centre) ──────────────────────────────────────
    let clipBody = roundedRect(388, 736, 248, 106, 44)
    // Violet clip
    color(108, 60, 232).setFill()
    clipBody.fill()

    // Clip hole
    let clipHole = roundedRect(438, 758, 148, 42, 21)
    color(195, 175, 255).setFill()
    clipHole.fill()

    // ── History lines (3 rows, decreasing opacity = older items fade) ─────
    // Row 1 – most recent (opaque, accent violet left pill)
    let row1Pill = roundedRect(304, 658, 18, 44, 9)
    color(108, 60, 232).setFill()
    row1Pill.fill()
    let row1 = roundedRect(336, 662, 300, 36, 10)
    color(60, 50, 120).setFill()
    row1.fill()
    let row1Short = roundedRect(648, 662, 80, 36, 10)
    color(60, 50, 120, 0.5).setFill()
    row1Short.fill()

    // Row 2 – second item (medium opacity)
    let row2Pill = roundedRect(304, 598, 18, 44, 9)
    color(108, 60, 232, 0.65).setFill()
    row2Pill.fill()
    let row2 = roundedRect(336, 602, 260, 36, 10)
    color(60, 50, 120, 0.55).setFill()
    row2.fill()
    let row2Short = roundedRect(608, 602, 110, 36, 10)
    color(60, 50, 120, 0.30).setFill()
    row2Short.fill()

    // Row 3 – third item (faded, older)
    let row3Pill = roundedRect(304, 538, 18, 44, 9)
    color(108, 60, 232, 0.35).setFill()
    row3Pill.fill()
    let row3 = roundedRect(336, 542, 200, 36, 10)
    color(60, 50, 120, 0.30).setFill()
    row3.fill()
    let row3Short = roundedRect(548, 542, 80, 36, 10)
    color(60, 50, 120, 0.16).setFill()
    row3Short.fill()

    // ── Copy icon (two overlapping cards in the clipboard body) ──────────
    // Back mini-card
    let copyBack = roundedRect(306, 310, 190, 186, 28)
    color(108, 60, 232, 0.18).setFill()
    copyBack.fill()

    // Front mini-card
    let copyFront = roundedRect(328, 284, 190, 186, 28)
    color(255, 255, 255, 0.88).setFill()
    copyFront.fill()
    color(108, 60, 232, 0.30).setStroke()
    let copyFrontBorder = roundedRect(328, 284, 190, 186, 28)
    copyFrontBorder.lineWidth = 5
    copyFrontBorder.stroke()

    // Lines inside copy mini-card
    color(108, 60, 232, 0.55).setFill()
    roundedRect(352, 416, 140, 16, 8).fill()
    roundedRect(352, 388, 100, 14, 7).fill()
    roundedRect(352, 362, 120, 14, 7).fill()

    // ── History / Clock badge (bottom-right corner) ───────────────────────
    // Badge background circle
    let badgeCX: CGFloat = 672
    let badgeCY: CGFloat = 248
    let badgeR:  CGFloat = 112

    // Drop shadow for badge
    let badgeShadow = NSShadow()
    badgeShadow.shadowBlurRadius = 28
    badgeShadow.shadowOffset = NSSize(width: 0, height: -10)
    badgeShadow.shadowColor = NSColor.black.withAlphaComponent(0.30)

    NSGraphicsContext.saveGraphicsState()
    badgeShadow.set()
    color(108, 60, 232).setFill()
    fillCircle(cx: badgeCX, cy: badgeCY, radius: badgeR)
    NSGraphicsContext.restoreGraphicsState()

    // Inner circle (clock face)
    color(245, 244, 255).setFill()
    fillCircle(cx: badgeCX, cy: badgeCY, radius: badgeR - 14)

    // Clock ticks (4 major, short lines)
    color(108, 60, 232, 0.40).setFill()
    for i in 0..<12 {
        let angle = CGFloat(i) * CGFloat.pi / 6
        let isMajor = (i % 3 == 0)
        let outerR = badgeR - 22
        let tickLen: CGFloat = isMajor ? 18 : 10
        let tickW:   CGFloat = isMajor ? 8  : 5
        let ox = badgeCX + outerR * sin(angle)
        let oy = badgeCY + outerR * cos(angle)
        let ix = badgeCX + (outerR - tickLen) * sin(angle)
        let iy = badgeCY + (outerR - tickLen) * cos(angle)
        let tickPath = NSBezierPath()
        tickPath.move(to: CGPoint(x: ox, y: oy))
        tickPath.line(to: CGPoint(x: ix, y: iy))
        tickPath.lineWidth = tickW
        tickPath.lineCapStyle = .round
        color(108, 60, 232, isMajor ? 0.55 : 0.28).setStroke()
        tickPath.stroke()
    }

    // Hour hand (pointing to ~10 o'clock)
    let hourPath = NSBezierPath()
    hourPath.move(to: CGPoint(x: badgeCX, y: badgeCY))
    hourPath.line(to: CGPoint(x: badgeCX - 38, y: badgeCY + 34))
    hourPath.lineWidth = 12
    hourPath.lineCapStyle = .round
    color(57, 35, 155).setStroke()
    hourPath.stroke()

    // Minute hand (pointing to ~1 o'clock)
    let minPath = NSBezierPath()
    minPath.move(to: CGPoint(x: badgeCX, y: badgeCY))
    minPath.line(to: CGPoint(x: badgeCX + 28, y: badgeCY + 54))
    minPath.lineWidth = 9
    minPath.lineCapStyle = .round
    color(57, 35, 155).setStroke()
    minPath.stroke()

    // Centre dot
    color(108, 60, 232).setFill()
    fillCircle(cx: badgeCX, cy: badgeCY, radius: 10)

    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [.compressionFactor: 1.0]) else {
        throw NSError(domain: "ClipBordIcon", code: 2)
    }

    return data
}

for image in images {
    let data = try drawIcon(size: image.size)
    try data.write(to: outputDirectory.appendingPathComponent(image.name), options: .atomic)
}
