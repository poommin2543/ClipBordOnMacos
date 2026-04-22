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

func drawSparkle(center: CGPoint, radius: CGFloat) {
    let path = NSBezierPath()
    path.move(to: CGPoint(x: center.x, y: center.y + radius))
    path.line(to: CGPoint(x: center.x + radius * 0.28, y: center.y + radius * 0.28))
    path.line(to: CGPoint(x: center.x + radius, y: center.y))
    path.line(to: CGPoint(x: center.x + radius * 0.28, y: center.y - radius * 0.28))
    path.line(to: CGPoint(x: center.x, y: center.y - radius))
    path.line(to: CGPoint(x: center.x - radius * 0.28, y: center.y - radius * 0.28))
    path.line(to: CGPoint(x: center.x - radius, y: center.y))
    path.line(to: CGPoint(x: center.x - radius * 0.28, y: center.y + radius * 0.28))
    path.close()
    color(255, 250, 220).setFill()
    path.fill()
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

    let scale = size / 1024
    context.cgContext.scaleBy(x: scale, y: scale)

    NSColor.clear.setFill()
    rect(0, 0, 1024, 1024).fill()

    let shadow = NSShadow()
    shadow.shadowBlurRadius = 38
    shadow.shadowOffset = NSSize(width: 0, height: -20)
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)

    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    let base = roundedRect(104, 88, 816, 816, 190)
    NSGradient(
        colors: [
            color(126, 224, 204),
            color(102, 171, 252),
            color(176, 155, 242),
        ]
    )!.draw(in: base, angle: -42)
    NSGraphicsContext.restoreGraphicsState()

    let glass = roundedRect(144, 142, 736, 724, 154)
    color(255, 255, 255, 0.20).setFill()
    glass.fill()

    let backCard = roundedRect(246, 222, 500, 578, 74)
    color(248, 251, 255, 0.72).setFill()
    backCard.fill()

    let cardShadow = NSShadow()
    cardShadow.shadowBlurRadius = 24
    cardShadow.shadowOffset = NSSize(width: 0, height: -10)
    cardShadow.shadowColor = NSColor.black.withAlphaComponent(0.16)

    NSGraphicsContext.saveGraphicsState()
    cardShadow.set()
    let frontCard = roundedRect(292, 188, 508, 612, 76)
    color(255, 253, 247).setFill()
    frontCard.fill()
    color(95, 111, 132, 0.18).setStroke()
    frontCard.lineWidth = 8
    frontCard.stroke()
    NSGraphicsContext.restoreGraphicsState()

    let clip = roundedRect(392, 722, 308, 120, 52)
    color(64, 102, 224).setFill()
    clip.fill()

    let clipHole = roundedRect(458, 748, 176, 48, 24)
    color(202, 228, 255).setFill()
    clipHole.fill()

    let faceColor = color(44, 56, 74)
    faceColor.setFill()
    roundedRect(424, 494, 42, 50, 21).fill()
    roundedRect(624, 494, 42, 50, 21).fill()

    let smile = NSBezierPath()
    smile.move(to: CGPoint(x: 468, y: 412))
    smile.curve(to: CGPoint(x: 622, y: 412), controlPoint1: CGPoint(x: 510, y: 354), controlPoint2: CGPoint(x: 580, y: 354))
    smile.lineWidth = 24
    smile.lineCapStyle = .round
    faceColor.setStroke()
    smile.stroke()

    color(255, 134, 150, 0.22).setFill()
    roundedRect(350, 434, 80, 38, 19).fill()
    roundedRect(660, 434, 80, 38, 19).fill()

    color(94, 119, 150, 0.22).setFill()
    roundedRect(376, 326, 352, 24, 12).fill()
    roundedRect(428, 280, 250, 22, 11).fill()

    let smallCopy = roundedRect(680, 214, 118, 118, 30)
    color(255, 198, 105).setFill()
    smallCopy.fill()
    color(255, 255, 255, 0.72).setFill()
    roundedRect(708, 246, 62, 52, 14).fill()

    drawSparkle(center: CGPoint(x: 744, y: 678), radius: 38)
    drawSparkle(center: CGPoint(x: 278, y: 692), radius: 26)

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
