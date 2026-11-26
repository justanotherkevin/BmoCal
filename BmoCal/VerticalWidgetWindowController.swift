//
//  VerticalWidgetWindowController.swift
//  BmoCal
//

import Cocoa
import EventKit

class VerticalWidgetWindowController: NSWindowController {

    var widgetView: VerticalWidgetView!

    static let windowWidth: CGFloat = 150

    init(floatOnTop: Bool, savedOrigin: CGPoint?, height: CGFloat) {
        let w = VerticalWidgetWindowController.windowWidth
        let rect = NSRect(x: 0, y: 0, width: w, height: height)

        let window = NSWindow(
            contentRect: rect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = floatOnTop ? .floating : .normal
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.hasShadow = true
        window.acceptsMouseMovedEvents = true
        window.isMovableByWindowBackground = false

        super.init(window: window)

        let effect = NSVisualEffectView(frame: rect)
        effect.material = .popover
        effect.blendingMode = .behindWindow
        effect.state = .active
        let radius = Theme.Radius.panel
        let side = radius * 2 + 1
        let mask = NSImage(size: NSSize(width: side, height: side), flipped: false) { r in
            NSBezierPath(roundedRect: r, xRadius: radius, yRadius: radius).fill()
            return true
        }
        mask.capInsets = NSEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
        mask.resizingMode = .stretch
        effect.maskImage = mask
        widgetView = VerticalWidgetView(frame: rect)
        widgetView.autoresizingMask = [.width, .height]
        effect.addSubview(widgetView)
        window.contentView = effect

        if let origin = savedOrigin,
           let ok = Self.clamped(NSRect(origin: origin, size: rect.size)) {
            window.setFrameOrigin(ok)
        } else if let screen = NSScreen.main {
            let sf = screen.visibleFrame
            window.setFrameOrigin(NSPoint(
                x: sf.maxX - w - 20,
                y: sf.midY - height / 2
            ))
        }
        window.invalidateShadow()
    }

    // Keep the frame fully inside the screen it overlaps; nil if it overlaps none.
    private static func clamped(_ f: NSRect) -> NSPoint? {
        guard let vf = NSScreen.screens.map({ $0.visibleFrame }).first(where: { $0.intersects(f) }) else { return nil }
        return NSPoint(x: min(max(f.minX, vf.minX), vf.maxX - f.width),
                       y: min(max(f.minY, vf.minY), vf.maxY - f.height))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    func tick() {
        widgetView.needsDisplay = true
    }

    func refreshEvents(events: [EKEvent], workStart: Int, workEnd: Int) {
        widgetView.todayEvents = events
        widgetView.workStart = workStart
        widgetView.workEnd = workEnd
        widgetView.needsDisplay = true
    }

    func setFloating(_ floating: Bool) {
        window?.level = floating ? .floating : .normal
    }
}
