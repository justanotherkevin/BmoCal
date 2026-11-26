//
//  WorkdayWidgetView.swift
//  BmoCal
//

import Cocoa
import EventKit

class WorkdayWidgetView: NSView {

    var todayEvents: [EKEvent] = []
    var workStart: Int = 8
    var workEnd: Int = 18

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

    private let lineWidth: CGFloat = 4

    private func outerRadius() -> CGFloat { min(bounds.width, bounds.height) / 2 }

    // Maps a decimal hour to a CGFloat angle in the NSView (Y-up) coordinate system.
    // Workday start = π/2 (top, 12 o'clock); advances clockwise.
    private func timeToAngle(_ t: Double) -> CGFloat {
        let frac = (t - Double(workStart)) / Double(workEnd - workStart)
        return CGFloat(Double.pi / 2 - frac * 2 * Double.pi)
    }

    private func decimalHour(_ d: Date) -> Double {
        let c = Calendar.current.dateComponents([.hour, .minute, .second], from: d)
        return Double(c.hour!) + Double(c.minute!) / 60 + Double(c.second!) / 3600
    }

    // MARK: - Text helpers

    private func fit(_ s: String, font: NSFont, width: CGFloat) -> String {
        func w(_ t: String) -> CGFloat { (t as NSString).size(withAttributes: [.font: font]).width }
        if w(s) <= width { return s }
        var t = s
        while t.count > 1 && w(t + "…") > width { t.removeLast() }
        return t + "…"
    }

    private func duration(_ mins: Int) -> String {
        mins < 60 ? "\(mins)m" : "\(mins / 60)h\(mins % 60)m"
    }

    // Draws centered on cx.
    private func drawCentered(_ s: String, font: NSFont, color: NSColor, cx: CGFloat, y: CGFloat) {
        let attr = NSAttributedString(string: s, attributes: [.font: font, .foregroundColor: color])
        attr.draw(at: NSPoint(x: cx - attr.size().width / 2, y: y))
    }

    // MARK: - Drawing

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        effectiveAppearance.performAsCurrentDrawingAppearance { self.drawContent() }
    }

    private func drawContent() {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let R = outerRadius()
        let eventR = R - 12   // event ring center radius
        let innerR = R - 20   // progress ring center radius

        let now = Date()
        let currentTime = decimalHour(now)
        let ws = Double(workStart), we = Double(workEnd)

        drawProgressRing(ctx, center: center, innerR: innerR, currentTime: currentTime, ws: ws, we: we)
        drawEventArcs(ctx, center: center, eventR: eventR, currentTime: currentTime, ws: ws, we: we)
        drawTicksAndNow(ctx, center: center, innerR: innerR, eventR: eventR, currentTime: currentTime, ws: ws, we: we)
        drawCenterText(center: center, R: R, innerR: innerR, now: now, currentTime: currentTime, ws: ws, we: we)
    }

    private func drawProgressRing(_ ctx: CGContext, center: CGPoint, innerR: CGFloat, currentTime: Double, ws: Double, we: Double) {
        let cx = center.x, cy = center.y
        // Inner track
        ctx.setStrokeColor(NSColor.separatorColor.cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.strokeEllipse(in: CGRect(x: cx - innerR, y: cy - innerR, width: innerR * 2, height: innerR * 2))

        // Elapsed arc
        if currentTime > ws {
            ctx.saveGState()
            ctx.setStrokeColor(NSColor.labelColor.cgColor)
            ctx.setLineWidth(lineWidth)
            ctx.setLineCap(.round)
            ctx.addArc(center: center, radius: innerR, startAngle: timeToAngle(ws),
                       endAngle: timeToAngle(min(currentTime, we)), clockwise: true)
            ctx.strokePath()
            ctx.restoreGState()
        }

    }

    private func drawEventArcs(_ ctx: CGContext, center: CGPoint, eventR: CGFloat, currentTime: Double, ws: Double, we: Double) {
        for event in todayEvents {
            guard let sd = event.startDate, let ed = event.endDate else { continue }
            let evStart = decimalHour(sd), evEnd = decimalHour(ed)
            let cs = max(evStart, ws), ce = min(evEnd, we)
            guard ce > cs else { continue }
            let base = event.calendar?.color ?? NSColor.systemBlue
            let color = evEnd <= currentTime ? base.withAlphaComponent(0.35) : base
            ctx.saveGState()
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(lineWidth)
            ctx.setLineCap(.butt)
            ctx.addArc(center: center, radius: eventR, startAngle: timeToAngle(cs),
                       endAngle: timeToAngle(ce), clockwise: true)
            ctx.strokePath()
            ctx.restoreGState()
        }

    }

    private func drawTicksAndNow(_ ctx: CGContext, center: CGPoint, innerR: CGFloat, eventR: CGFloat, currentTime: Double, ws: Double, we: Double) {
        let cx = center.x, cy = center.y
        let span = we - ws
        // Ticks at 0, 1/4, 1/2, 3/4
        ctx.setStrokeColor(NSColor.tertiaryLabelColor.cgColor)
        ctx.setLineWidth(1)
        for i in 0..<4 {
            let a = timeToAngle(ws + span * Double(i) / 4)
            ctx.move(to: CGPoint(x: cx + (innerR - 12) * cos(a), y: cy + (innerR - 12) * sin(a)))
            ctx.addLine(to: CGPoint(x: cx + (innerR - 6) * cos(a), y: cy + (innerR - 6) * sin(a)))
            ctx.strokePath()
        }

        // Now marker
        if currentTime >= ws && currentTime <= we {
            let a = timeToAngle(currentTime)
            ctx.setStrokeColor(NSColor.systemRed.cgColor)
            ctx.setLineWidth(2)
            ctx.setLineCap(.butt)
            ctx.move(to: CGPoint(x: cx + (innerR - 5) * cos(a), y: cy + (innerR - 5) * sin(a)))
            ctx.addLine(to: CGPoint(x: cx + (eventR + 5) * cos(a), y: cy + (eventR + 5) * sin(a)))
            ctx.strokePath()
        }

    }

    private func drawCenterText(center: CGPoint, R: CGFloat, innerR: CGFloat, now: Date, currentTime: Double, ws: Double, we: Double) {
        let cx = center.x, cy = center.y
        let scale = R / 100
        let mainFont = NSFont.monospacedDigitSystemFont(ofSize: 22 * scale, weight: .semibold)
        let subFont = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        let maxW = innerR * 1.5

        if currentTime < ws || currentTime >= we {
            let msg = currentTime < ws ? "Starts \(workStart):00" : "Done"
            let font = NSFont.monospacedDigitSystemFont(ofSize: 18 * scale, weight: .semibold)
            let h = (msg as NSString).size(withAttributes: [.font: font]).height
            drawCentered(msg, font: font, color: .labelColor, cx: cx, y: cy - h / 2)
            return
        }

        let remMins = Int((we - currentTime) * 60)
        let remStr = String(format: "%d:%02d", remMins / 60, remMins % 60)
        let next = todayEvents.filter { ($0.startDate ?? .distantPast) > now }.min { ($0.startDate ?? .distantFuture) < ($1.startDate ?? .distantFuture) }
        let mainH = (remStr as NSString).size(withAttributes: [.font: mainFont]).height
        if let next, let nextStart = next.startDate {
            drawCentered(remStr, font: mainFont, color: .labelColor, cx: cx, y: cy - 1)
            let suffix = " in " + duration(max(0, Int(nextStart.timeIntervalSince(now) / 60)))
            let sufW = (suffix as NSString).size(withAttributes: [.font: subFont]).width
            let title = fit(next.title ?? "Event", font: subFont, width: maxW - sufW)
            drawCentered(title + suffix, font: subFont, color: .secondaryLabelColor, cx: cx, y: cy - 1 - 14)
        } else {
            drawCentered(remStr, font: mainFont, color: .labelColor, cx: cx, y: cy - mainH / 2)
        }
    }

    // MARK: - Dragging

    override func mouseDown(with event: NSEvent) {
        let loc = event.locationInWindow
        let cx = bounds.midX
        let cy = bounds.midY
        let r = outerRadius()
        let dx = loc.x - cx
        let dy = loc.y - cy
        if dx * dx + dy * dy <= r * r {
            initialMouseLocation = loc
        }
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
        // Persist position
        if let appDelegate = NSApp.delegate as? AppDelegate, let window = self.window {
            appDelegate.settings.data.widgetX = Double(window.frame.origin.x)
            appDelegate.settings.data.widgetY = Double(window.frame.origin.y)
            appDelegate.settings.archive()
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
            app.settings.data.widgetFloatsOnTop = (w.level == .floating)
            app.settings.archive()
        }
    }

    @objc private func closeWidget() {
        (NSApp.delegate as? AppDelegate)?.hideWidget()
    }
}
