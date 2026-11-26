//
//  WorkdayWidgetWindowController.swift
//  BmoCal
//

import Cocoa
import EventKit

class WorkdayWidgetWindowController: NSWindowController {

    var widgetView: WorkdayWidgetView!

    static let windowSize: CGFloat = 200

    init(floatOnTop: Bool, savedOrigin: CGPoint?) {
        let size = WorkdayWidgetWindowController.windowSize
        let rect = NSRect(x: 0, y: 0, width: size, height: size)

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
        effect.maskImage = NSImage(size: rect.size, flipped: false) { r in
            NSBezierPath(ovalIn: r).fill()
            return true
        }
        widgetView = WorkdayWidgetView(frame: rect)
        widgetView.autoresizingMask = [.width, .height]
        effect.addSubview(widgetView)
        window.contentView = effect

        // Restore saved position or default to top-right corner
        if let origin = savedOrigin,
           let ok = Self.clamped(NSRect(origin: origin, size: rect.size)) {
            window.setFrameOrigin(ok)
        } else if let screen = NSScreen.main {
            let sf = screen.visibleFrame
            window.setFrameOrigin(NSPoint(
                x: sf.maxX - size - 20,
                y: sf.maxY - size - 20
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

    // Called every second from AppDelegate.update()
    func tick() {
        widgetView.needsDisplay = true
    }

    // Called when calendar data changes
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
