// Draws the app icon as a 1024×1024 PNG: a yellow note with a red pin.
// Usage: swift scripts/generate-icon.swift <output.png>
// Run `make icon` to turn it into Support/AppIcon.icns.
import AppKit

let canvas = 1024.0
// Apple's macOS icon grid: an 824-point rounded square, centered.
let body = NSRect(x: 100, y: 100, width: 824, height: 824)
let cornerRadius = 185.0

func color(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
    NSColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

func drawNote() {
    let shape = NSBezierPath(roundedRect: body, xRadius: cornerRadius, yRadius: cornerRadius)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowOffset = NSSize(width: 0, height: -12)
    shadow.shadowBlurRadius = 28
    shadow.shadowColor = color(0x000000, alpha: 0.28)
    shadow.set()
    color(0xFFDD55).setFill()
    shape.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGradient(starting: color(0xFFEE88), ending: color(0xFFD23F))?.draw(in: shape, angle: -90)
}

func drawTextLines() {
    let lineColor = color(0xB8860B, alpha: 0.45)
    lineColor.setFill()
    let lines: [(y: Double, width: Double)] = [(610, 584), (500, 520), (390, 584), (280, 360)]
    for line in lines {
        let rect = NSRect(x: 220, y: line.y, width: line.width, height: 40)
        NSBezierPath(roundedRect: rect, xRadius: 20, yRadius: 20).fill()
    }
}

func drawPin() {
    let center = NSPoint(x: 512, y: 790)
    let radius = 78.0

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowOffset = NSSize(width: 10, height: -14)
    shadow.shadowBlurRadius = 16
    shadow.shadowColor = color(0x000000, alpha: 0.35)
    shadow.set()
    let head = NSBezierPath(
        ovalIn: NSRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    )
    color(0xE0362C).setFill()
    head.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGradient(starting: color(0xFF6B5E), ending: color(0xC4231B))?
        .draw(in: head, relativeCenterPosition: NSPoint(x: -0.35, y: 0.35))

    let highlight = NSBezierPath(ovalIn: NSRect(x: center.x - 44, y: center.y + 12, width: 44, height: 30))
    color(0xFFFFFF, alpha: 0.55).setFill()
    highlight.fill()
}

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("Usage: generate-icon.swift <output.png>\n".utf8))
    exit(64)
}

guard
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(canvas),
        pixelsHigh: Int(canvas),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )
else {
    fatalError("Could not create the bitmap")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
drawNote()
drawTextLines()
drawPin()
NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not encode the PNG")
}
try png.write(to: URL(filePath: CommandLine.arguments[1]))
