#!/usr/bin/swift
import AppKit

// Usage: sfsymbol <name> <size> <output.png> [color_hex]
// Example: sfsymbol checkmark 32 /tmp/check.png 4CD964

guard CommandLine.arguments.count >= 4 else {
    fputs("Usage: sfsymbol <name> <size> <output.png> [color_hex]\n", stderr)
    exit(1)
}

let symbolName = CommandLine.arguments[1]
let size = CGFloat(Double(CommandLine.arguments[2]) ?? 32)
let outputPath = CommandLine.arguments[3]
let colorHex = CommandLine.arguments.count > 4 ? CommandLine.arguments[4] : "FFFFFF"

func hexColor(_ hex: String) -> NSColor {
    var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    h = h.replacingOccurrences(of: "#", with: "")
    var rgb: UInt64 = 0
    Scanner(string: h).scanHexInt64(&rgb)
    return NSColor(
        red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(rgb & 0x0000FF) / 255.0,
        alpha: 1.0
    )
}

guard let symbol = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) else {
    fputs("Error: Symbol '\(symbolName)' not found\n", stderr)
    exit(1)
}

let config = NSImage.SymbolConfiguration(pointSize: size, weight: .medium)
    .applying(.init(paletteColors: [hexColor(colorHex)]))

guard let configured = symbol.withSymbolConfiguration(config) else {
    fputs("Error: Failed to configure symbol\n", stderr)
    exit(1)
}

let symbolSize = configured.size
let finalSize = NSSize(width: max(symbolSize.width, size), height: max(symbolSize.height, size))

let finalImage = NSImage(size: finalSize)
finalImage.lockFocus()
let rect = NSRect(
    x: (finalSize.width - symbolSize.width) / 2,
    y: (finalSize.height - symbolSize.height) / 2,
    width: symbolSize.width,
    height: symbolSize.height
)
configured.draw(in: rect)
finalImage.unlockFocus()

guard let tiff = finalImage.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Error: Failed to create PNG\n", stderr)
    exit(1)
}

do {
    try png.write(to: URL(fileURLWithPath: outputPath))
    print(outputPath)
} catch {
    fputs("Error: \(error)\n", stderr)
    exit(1)
}
