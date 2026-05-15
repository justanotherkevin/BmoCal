//
//  VerticalWidgetView.swift
//  BmoCal
//

import Cocoa
import EventKit

class VerticalWidgetView: NSView {

    var todayEvents: [EKEvent] = []
    var workStart: Int = 9
    var workEnd: Int = 18

    private let vPad: CGFloat = 12
    private let trackWidth: CGFloat = 28
    private let pillCorner: CGFloat = 5
    private let bgCorner: CGFloat = 16

    private var initialMouseLocation: NSPoint?

    override init(frame: NSRect) {
        super.init(frame: frame)
        buildContextMenu()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        buildContextMenu()
    }

    // MARK: - Geometry

    private var trackLeft: CGFloat { (bounds.width - trackWidth) / 2 }
    private var trackTop: CGFloat { bounds.height - vPad }
    private var trackBottom: CGFloat { vPad }
    private var trackHeight: CGFloat { trackTop - trackBottom }

    // Maps decimal hour to Y in NSView coordinates (Y-up: workday start → high Y, end → low Y)
    private func timeToY(_ t: Double) -> CGFloat {
        let frac = (t - Double(workStart)) / Double(workEnd - workStart)
        return trackTop - CGFloat(frac) * trackHeight
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        let cal = Calendar.current
        let hms = cal.dateComponents([.hour, .minute, .second], from: Date())
        let currentTime = Double(hms.hour!) + Double(hms.minute!) / 60 + Double(hms.second!) / 3600

        // ── Background pill ──────────────────────────────────────────────────
        let bgRect = bounds.insetBy(dx: 5, dy: 5)
        let bgPath = CGPath(roundedRect: bgRect, cornerWidth: bgCorner, cornerHeight: bgCorner, transform: nil)
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -1), blur: 10,
                      color: NSColor.black.withAlphaComponent(0.20).cgColor)
        ctx.addPath(bgPath)
        ctx.setFillColor(NSColor.white.withAlphaComponent(0.96).cgColor)
        ctx.fillPath()
        ctx.restoreGState()

        // ── Track background ─────────────────────────────────────────────────
        let trackRect = CGRect(x: trackLeft, y: trackBottom, width: trackWidth, height: trackHeight)
        let trackPath = CGPath(roundedRect: trackRect,
                               cornerWidth: trackWidth / 2, cornerHeight: trackWidth / 2,
                               transform: nil)
        ctx.saveGState()
        ctx.addPath(trackPath)
        ctx.setFillColor(NSColor.systemBlue.withAlphaComponent(0.07).cgColor)
        ctx.fillPath()
        ctx.restoreGState()

        // ── Event pills ──────────────────────────────────────────────────────
        for event in todayEvents {
            guard let startDate = event.startDate, let endDate = event.endDate else { continue }
            let sComps = cal.dateComponents([.hour, .minute], from: startDate)
            let eComps = cal.dateComponents([.hour, .minute], from: endDate)
            let evStart = Double(sComps.hour!) + Double(sComps.minute!) / 60
            let evEnd   = Double(eComps.hour!) + Double(eComps.minute!) / 60

            let clampedStart = max(evStart, Double(workStart))
            let clampedEnd   = min(evEnd,   Double(workEnd))
            guard clampedEnd > clampedStart else { continue }

            // yTop > yBottom in NSView Y-up coordinates (earlier time = higher Y)
            let yTop    = timeToY(clampedStart)
            let yBottom = timeToY(clampedEnd)
            let pillH   = yTop - yBottom
            guard pillH > 1 else { continue }

            let isPast = evEnd <= currentTime
            let alpha: CGFloat = isPast ? 0.35 : 0.85
            let color = (event.calendar?.color ?? NSColor.systemBlue).withAlphaComponent(alpha)

            let pillRect = CGRect(x: trackLeft, y: yBottom, width: trackWidth, height: pillH)
            let pillPath = CGPath(roundedRect: pillRect,
                                  cornerWidth: pillCorner, cornerHeight: pillCorner,
                                  transform: nil)
            ctx.saveGState()
            ctx.addPath(pillPath)
            ctx.setFillColor(color.cgColor)
            ctx.fillPath()
            ctx.restoreGState()
        }

        // ── Now pointer (red dot + horizontal line to track) ─────────────────
        if currentTime >= Double(workStart) && currentTime <= Double(workEnd) {
            let nowY = timeToY(currentTime)
            let dotR: CGFloat = 5
            let dotCenterX = trackLeft - dotR - 4

            ctx.saveGState()
            ctx.setFillColor(NSColor.systemRed.cgColor)
            ctx.fillEllipse(in: CGRect(x: dotCenterX - dotR, y: nowY - dotR,
                                       width: dotR * 2, height: dotR * 2))
            ctx.setStrokeColor(NSColor.systemRed.cgColor)
            ctx.setLineWidth(1.5)
            ctx.move(to: CGPoint(x: dotCenterX + dotR, y: nowY))
            ctx.addLine(to: CGPoint(x: trackLeft, y: nowY))
            ctx.strokePath()
            ctx.restoreGState()
        }
    }

    // MARK: - Dragging

    override func mouseDown(with event: NSEvent) {
        initialMouseLocation = event.locationInWindow
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window = self.window, let init_ = initialMouseLocation else { return }
        let cur = event.locationInWindow
        var frame = window.frame
        frame.origin.x += cur.x - init_.x
        frame.origin.y += cur.y - init_.y
        window.setFrameOrigin(frame.origin)
    }

    override func mouseUp(with event: NSEvent) {
        initialMouseLocation = nil
        if let app = NSApp.delegate as? AppDelegate, let window = self.window {
            app.settings.data.verticalWidgetX = Double(window.frame.origin.x)
            app.settings.data.verticalWidgetY = Double(window.frame.origin.y)
            app.settings.archive()
        }
    }

    // MARK: - Context menu

    private func buildContextMenu() {
        let m = NSMenu()
        let floatItem = NSMenuItem(title: "Float on Top",
                                   action: #selector(toggleFloat),
                                   keyEquivalent: "")
        floatItem.target = self
        m.addItem(floatItem)
        m.addItem(.separator())
        let closeItem = NSMenuItem(title: "Close Widget",
                                   action: #selector(closeWidget),
                                   keyEquivalent: "")
        closeItem.target = self
        m.addItem(closeItem)
        self.menu = m
    }

    override func rightMouseDown(with event: NSEvent) {
        menu?.item(at: 0)?.state = (window?.level == .floating) ? .on : .off
        super.rightMouseDown(with: event)
    }

    @objc private func toggleFloat() {
        guard let w = window else { return }
        w.level = (w.level == .floating) ? .normal : .floating
        if let app = NSApp.delegate as? AppDelegate {
            app.settings.data.verticalWidgetFloatsOnTop = (w.level == .floating)
            app.settings.archive()
        }
    }

    @objc private func closeWidget() {
        (NSApp.delegate as? AppDelegate)?.hideVerticalWidget()
    }
}
