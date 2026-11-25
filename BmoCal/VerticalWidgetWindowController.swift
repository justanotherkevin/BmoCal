//
//  VerticalWidgetWindowController.swift
//  BmoCal
//

import Cocoa
import EventKit

class VerticalWidgetWindowController: NSWindowController {

    var widgetView: VerticalWidgetView!

    static let windowWidth: CGFloat = 64

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
        window.hasShadow = false
        window.acceptsMouseMovedEvents = true
        window.isMovableByWindowBackground = false

        super.init(window: window)

        widgetView = VerticalWidgetView(frame: rect)
        window.contentView = widgetView

        if let origin = savedOrigin {
            window.setFrameOrigin(origin)
        } else if let screen = NSScreen.main {
            window.setFrameOrigin(Self.defaultOrigin(in: screen.visibleFrame, height: height))
        }
    }

    // Left edge, below the round widget's default spot
    static func defaultOrigin(in sf: NSRect, height: CGFloat) -> NSPoint {
        let below = sf.maxY - 20 - WorkdayWidgetWindowController.windowSize - 20 - height
        return NSPoint(x: sf.minX + 20, y: max(below, sf.minY + 20))
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
