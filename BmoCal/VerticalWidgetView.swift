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

    private let pad: CGFloat = 12
    private let headerHeight: CGFloat = 16
    private let labelWidth: CGFloat = 32
    private let blockRadius: CGFloat = 3

    private var trackLeft: CGFloat { pad + labelWidth + 4 }
    private var trackWidth: CGFloat { bounds.width - trackLeft - pad }
    private var trackTop: CGFloat { bounds.height - pad - headerHeight - 8 }
    private var trackBottom: CGFloat { pad }
    private var trackHeight: CGFloat { trackTop - trackBottom }

    // Maps decimal hour to Y in NSView coordinates (Y-up: workday start → high Y, end → low Y)
    private func timeToY(_ t: Double) -> CGFloat {
        let frac = (t - Double(workStart)) / Double(workEnd - workStart)
        return trackTop - CGFloat(frac) * trackHeight
    }

    private func decimalHour(_ d: Date) -> Double {
        let c = Calendar.current.dateComponents([.hour, .minute, .second], from: d)
        return Double(c.hour!) + Double(c.minute!) / 60 + Double(c.second!) / 3600
    }

    private static let clockFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm"
        return f
    }()

    // MARK: - Drawing

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        effectiveAppearance.performAsCurrentDrawingAppearance { self.drawContent() }
    }

    private func attrs(_ size: CGFloat, _ weight: NSFont.Weight, _ color: NSColor, align: NSTextAlignment = .left) -> [NSAttributedString.Key: Any] {
        let p = NSMutableParagraphStyle()
        p.alignment = align
        p.lineBreakMode = .byTruncatingTail
        return [.font: NSFont.monospacedDigitSystemFont(ofSize: size, weight: weight),
                .foregroundColor: color, .paragraphStyle: p]
    }

    private func drawContent() {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        let now = Date()
        let currentTime = decimalHour(now)
        let ws = Double(workStart), we = Double(workEnd)

        drawHeader(currentTime: currentTime, ws: ws, we: we)

        // Track
        let trackRect = CGRect(x: trackLeft, y: trackBottom, width: trackWidth, height: trackHeight)
        ctx.addPath(CGPath(roundedRect: trackRect, cornerWidth: blockRadius, cornerHeight: blockRadius, transform: nil))
        ctx.setFillColor(NSColor.separatorColor.cgColor)
        ctx.fillPath()

        let nowVisible = currentTime >= ws && currentTime <= we
        let nowY = timeToY(currentTime)

        drawHourLabels(nowVisible: nowVisible, nowY: nowY)
        drawEventBlocks(ctx, currentTime: currentTime, ws: ws, we: we)
        if nowVisible { drawNowLine(ctx, now: now, nowY: nowY) }
    }

    // Header: remaining "4:32" + "left"
    private func drawHeader(currentTime: Double, ws: Double, we: Double) {
        let hy = bounds.height - pad - headerHeight
        if currentTime < ws || currentTime >= we {
            let msg = currentTime < ws ? "Starts \(workStart):00" : "Done"
            NSAttributedString(string: msg, attributes: attrs(13, .semibold, .labelColor))
                .draw(at: NSPoint(x: pad, y: hy))
        } else {
            let remMins = Int((we - currentTime) * 60)
            let remStr = NSAttributedString(string: String(format: "%d:%02d", remMins / 60, remMins % 60),
                                            attributes: attrs(13, .semibold, .labelColor))
            let leftStr = NSAttributedString(string: "left", attributes: attrs(11, .regular, .secondaryLabelColor))
            remStr.draw(at: NSPoint(x: pad, y: hy))
            leftStr.draw(at: NSPoint(x: pad + remStr.size().width + 4, y: hy))
        }
    }

    // Hour labels every 2 hours
    private func drawHourLabels(nowVisible: Bool, nowY: CGFloat) {
        let labelAttrs = attrs(10, .regular, .tertiaryLabelColor, align: .right)
        for h in stride(from: workStart, through: workEnd, by: 2) {
            let y = timeToY(Double(h))
            if nowVisible && abs(y - nowY) < 12 { continue }
            let hh = h % 12 == 0 ? 12 : h % 12
            ("\(hh)" as NSString).draw(in: CGRect(x: pad, y: y - 6, width: labelWidth, height: 13),
                                       withAttributes: labelAttrs)
        }
    }

    private func drawEventBlocks(_ ctx: CGContext, currentTime: Double, ws: Double, we: Double) {
        for event in todayEvents {
            guard let sd = event.startDate, let ed = event.endDate else { continue }
            let evStart = decimalHour(sd), evEnd = decimalHour(ed)
            let cs = max(evStart, ws), ce = min(evEnd, we)
            guard ce > cs else { continue }

            let yTop = timeToY(cs), yBottom = timeToY(ce)
            let h = yTop - yBottom
            guard h > 1 else { continue }

            let base = event.calendar?.color ?? NSColor.systemBlue
            let isPast = evEnd <= currentTime
            let rect = CGRect(x: trackLeft, y: yBottom, width: trackWidth, height: h)

            ctx.saveGState()
            ctx.addPath(CGPath(roundedRect: rect, cornerWidth: blockRadius, cornerHeight: blockRadius, transform: nil))
            ctx.clip()
            let a: CGFloat = isPast ? 0.35 : 1
            ctx.setFillColor(base.withAlphaComponent(0.25 * a).cgColor)
            ctx.fill(rect)
            ctx.setFillColor(base.withAlphaComponent(a).cgColor)
            ctx.fill(CGRect(x: rect.minX, y: rect.minY, width: 3, height: h))
            ctx.restoreGState()

            if h >= 18 {
                ((event.title ?? "") as NSString).draw(
                    in: CGRect(x: rect.minX + 7, y: yTop - 15, width: rect.width - 11, height: 13),
                    withAttributes: attrs(10, .regular, NSColor.labelColor.withAlphaComponent(a)))
            }
        }
    }

    // Now line + label
    private func drawNowLine(_ ctx: CGContext, now: Date, nowY: CGFloat) {
        ctx.setFillColor(NSColor.systemRed.cgColor)
        ctx.fill(CGRect(x: trackLeft, y: nowY - 0.75, width: trackWidth, height: 1.5))
        (VerticalWidgetView.clockFormatter.string(from: now) as NSString).draw(
            in: CGRect(x: pad, y: nowY - 6, width: labelWidth, height: 13),
            withAttributes: attrs(10, .regular, .systemRed, align: .right))
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
