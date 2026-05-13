//
//  WorkdayWidgetWindowController.swift
//  BmoCal
//

import Cocoa
import EventKit

class WorkdayWidgetWindowController: NSWindowController {

    var widgetView: WorkdayWidgetView!

    // 170px widget + 14px padding each side for hour labels = 198 → 200px
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
        window.hasShadow = false
        window.acceptsMouseMovedEvents = true
        window.isMovableByWindowBackground = false

        super.init(window: window)

        widgetView = WorkdayWidgetView(frame: rect)
        window.contentView = widgetView

        // Restore saved position or default to top-right corner
        if let origin = savedOrigin {
            window.setFrameOrigin(origin)
        } else if let screen = NSScreen.main {
            let sf = screen.visibleFrame
            window.setFrameOrigin(NSPoint(
                x: sf.maxX - size - 20,
                y: sf.maxY - size - 20
            ))
        }
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
