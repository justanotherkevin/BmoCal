#!/usr/bin/env swift

import Cocoa

// ============================================================
// Preview Renderer for BmoCal Desktop Widget
// Renders the circular workday visualization as a PNG
// ============================================================

let widgetWidth: CGFloat = 280
let widgetHeight: CGFloat = 300
let circleDiameter: CGFloat = 200
let circleRadius = circleDiameter / 2
let centerX = widgetWidth / 2
let centerY = widgetHeight / 2 + 10
let ringThickness: CGFloat = 10
let eventArcThickness: CGFloat = 6
let handLength: CGFloat = circleRadius - 4

// Configure a sample workday
let workdayStartHour = 9   // 9 AM
let workdayEndHour = 17    // 5 PM (8-hour day)
let totalWorkSeconds = Double((workdayEndHour - workdayStartHour) * 3600)

// Sample current time: 1:30 PM (4.5 hours into an 8-hour day = 56.25%)
let currentHour = 13
let currentMinute = 30
let currentSecond = 0
let elapsedSeconds = Double((currentHour - workdayStartHour) * 3600 + currentMinute * 60 + currentSecond)
let progress = min(1.0, max(0.0, elapsedSeconds / totalWorkSeconds))

// Sample events for the day
struct SampleEvent {
    let title: String
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int
    let color: NSColor
}

let sampleEvents = [
    SampleEvent(title: "Standup", startHour: 9, startMinute: 0, endHour: 9, endMinute: 15, color: NSColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0)),
    SampleEvent(title: "Design Review", startHour: 10, startMinute: 0, endHour: 11, endMinute: 0, color: NSColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 1.0)),
    SampleEvent(title: "Lunch", startHour: 12, startMinute: 0, endHour: 13, endMinute: 0, color: NSColor(red: 0.5, green: 0.8, blue: 0.3, alpha: 1.0)),
    SampleEvent(title: "Sprint Planning", startHour: 14, startMinute: 0, endHour: 15, endMinute: 30, color: NSColor(red: 0.9, green: 0.3, blue: 0.5, alpha: 1.0)),
]

func timeToProgress(hour: Int, minute: Int) -> CGFloat {
    let totalMinutes = Double((hour - workdayStartHour) * 60 + minute)
    let workdayMinutes = Double((workdayEndHour - workdayStartHour) * 60)
    return CGFloat(max(0.0, min(1.0, totalMinutes / workdayMinutes)))
}

// Create image
let image = NSImage(size: NSSize(width: widgetWidth, height: widgetHeight))
image.lockFocus()

// --- Draw background ---
let backgroundPath = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: widgetWidth, height: widgetHeight),
                                  xRadius: 16, yRadius: 16)
NSColor(white: 0.11, alpha: 0.92).setFill()
backgroundPath.fill()

// --- Draw subtle border ---
NSColor(white: 0.25, alpha: 0.5).setStroke()
backgroundPath.lineWidth = 1
backgroundPath.stroke()

// --- Draw outer ring track ---
let trackPath = NSBezierPath()
trackPath.appendArc(withCenter: NSPoint(x: centerX, y: centerY),
                    radius: circleRadius + ringThickness/2,
                    startAngle: 0, endAngle: 360)
NSColor(white: 0.3, alpha: 0.4).setStroke()
trackPath.lineWidth = ringThickness
trackPath.stroke()

// --- Draw event arcs ---
for event in sampleEvents {
    let startProg = timeToProgress(hour: event.startHour, minute: event.startMinute)
    let endProg = timeToProgress(hour: event.endHour, minute: event.endMinute)
    
    if endProg > 0 && startProg < 1 {
        let clampedStart = max(0, startProg)
        let clampedEnd = min(1, endProg)
        let startAngle = CGFloat(clampedStart * 360.0 - 90.0)
        let endAngle = CGFloat(clampedEnd * 360.0 - 90.0)
        
        let arcPath = NSBezierPath()
        arcPath.appendArc(withCenter: NSPoint(x: centerX, y: centerY),
                          radius: circleRadius + ringThickness/2,
                          startAngle: startAngle,
                          endAngle: endAngle)
        event.color.setStroke()
        arcPath.lineWidth = eventArcThickness
        arcPath.lineCapStyle = .round
        arcPath.stroke()
    }
}

// --- Draw elapsed fill (gradient) ---
let fillPath = NSBezierPath()
let fillEndAngle = CGFloat(progress * 360.0 - 90.0)
fillPath.appendArc(withCenter: NSPoint(x: centerX, y: centerY),
                   radius: circleRadius + ringThickness/2,
                   startAngle: -90,
                   endAngle: fillEndAngle)

if let context = NSGraphicsContext.current?.cgContext {
    context.saveGState()
    fillPath.addClip()
    
    let colors = [
        CGColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0),
        CGColor(red: 0.1, green: 0.85, blue: 0.7, alpha: 1.0)
    ] as CFArray
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0.0, 1.0])!
    
    context.drawLinearGradient(gradient,
                               start: CGPoint(x: centerX - circleRadius, y: centerY),
                               end: CGPoint(x: centerX + circleRadius, y: centerY),
                               options: [])
    context.restoreGState()
}

// Fill arc border glow
NSColor.white.withAlphaComponent(0.3).setStroke()
let fillStrokePath = NSBezierPath()
fillStrokePath.appendArc(withCenter: NSPoint(x: centerX, y: centerY),
                         radius: circleRadius + ringThickness/2 + 2,
                         startAngle: -92, endAngle: fillEndAngle + 2)
fillStrokePath.lineWidth = 1
fillStrokePath.stroke()

// --- Draw clock hand ---
let handAngle = CGFloat(progress * 360.0 - 90.0)
let rad = handAngle * .pi / 180.0

let handPath = NSBezierPath()
handPath.move(to: NSPoint(x: centerX, y: centerY))
let handTip = NSPoint(x: centerX + CGFloat(cos(rad)) * handLength,
                      y: centerY + CGFloat(sin(rad)) * handLength)
handPath.line(to: handTip)
NSColor.white.withAlphaComponent(0.9).setStroke()
handPath.lineWidth = 2.5
handPath.lineCapStyle = .round
handPath.stroke()

// Center dot
let centerDot = NSBezierPath(ovalIn: NSRect(x: centerX - 4, y: centerY - 4, width: 8, height: 8))
NSColor.white.setFill()
centerDot.fill()

// Tip dot
let tipDot = NSBezierPath(ovalIn: NSRect(x: handTip.x - 4, y: handTip.y - 4, width: 8, height: 8))
NSColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0).setFill()
tipDot.fill()
NSColor.white.setStroke()
tipDot.lineWidth = 1.5
tipDot.stroke()

// --- Center text: remaining time ---
let remainingSecs = Int(totalWorkSeconds - elapsedSeconds)
let remH = remainingSecs / 3600
let remM = (remainingSecs % 3600) / 60

let remainingStr = "\(remH)h \(remM)m"
let remainingAttr: [NSAttributedString.Key: Any] = [
    .font: NSFont(name: "Helvetica Neue", size: 28) ?? NSFont.systemFont(ofSize: 28),
    .foregroundColor: NSColor.white
]
let remainingSize = remainingStr.size(withAttributes: remainingAttr)
let remainingPoint = NSPoint(x: centerX - remainingSize.width / 2,
                              y: centerY - remainingSize.height / 2 + 8)
remainingStr.draw(at: remainingPoint, withAttributes: remainingAttr)

let ofStr = "of 8h workday"
let ofAttr: [NSAttributedString.Key: Any] = [
    .font: NSFont(name: "Helvetica Neue", size: 12) ?? NSFont.systemFont(ofSize: 12),
    .foregroundColor: NSColor(white: 0.6, alpha: 1.0)
]
let ofSize = ofStr.size(withAttributes: ofAttr)
let ofPoint = NSPoint(x: centerX - ofSize.width / 2,
                       y: centerY - remainingSize.height / 2 - 16)
ofStr.draw(at: ofPoint, withAttributes: ofAttr)

// --- Bottom labels ---
let timeStr = "\(currentHour):\(String(format: "%02d", currentMinute))"
let timeAttr: [NSAttributedString.Key: Any] = [
    .font: NSFont(name: "Helvetica Neue", size: 13) ?? NSFont.systemFont(ofSize: 13),
    .foregroundColor: NSColor(white: 0.7, alpha: 1.0)
]
let timeSize = timeStr.size(withAttributes: timeAttr)
timeStr.draw(at: NSPoint(x: centerX - timeSize.width / 2, y: 62), withAttributes: timeAttr)

let pctStr = "\(Int(progress * 100))% complete"
let pctAttr: [NSAttributedString.Key: Any] = [
    .font: NSFont(name: "Helvetica Neue", size: 11) ?? NSFont.systemFont(ofSize: 11),
    .foregroundColor: NSColor(white: 0.5, alpha: 1.0)
]
let pctSize = pctStr.size(withAttributes: pctAttr)
pctStr.draw(at: NSPoint(x: centerX - pctSize.width / 2, y: 42), withAttributes: pctAttr)

let legendStr = "9:00 AM — 5:00 PM"
let legendAttr: [NSAttributedString.Key: Any] = [
    .font: NSFont(name: "Helvetica Neue", size: 10) ?? NSFont.systemFont(ofSize: 10),
    .foregroundColor: NSColor(white: 0.45, alpha: 1.0)
]
let legendSize = legendStr.size(withAttributes: legendAttr)
legendStr.draw(at: NSPoint(x: centerX - legendSize.width / 2, y: 22), withAttributes: legendAttr)

image.unlockFocus()

// Save to current directory
let filePath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("bmo_widget_preview.png")

if let tiffData = image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiffData),
   let pngData = bitmap.representation(using: .png, properties: [:]) {
    try pngData.write(to: filePath)
    print("✅ Preview saved to: \(filePath.path)")
} else {
    print("❌ Failed to render preview")
}
