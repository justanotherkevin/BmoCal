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

    private let ringWidth: CGFloat = 20
    // Extra space on each side so hour labels outside the ring aren't clipped
    private let padding: CGFloat = 14

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

    private func outerRadius() -> CGFloat {
        min(bounds.width, bounds.height) / 2 - padding
    }

    // Maps a decimal hour to a CGFloat angle in the NSView (Y-up) coordinate system.
    // Workday start = π/2 (top, 12 o'clock); advances clockwise.
    private func timeToAngle(_ t: Double) -> CGFloat {
        let frac = (t - Double(workStart)) / Double(workEnd - workStart)
        return CGFloat(Double.pi / 2 - frac * 2 * Double.pi)
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        let cx = bounds.midX
        let cy = bounds.midY
        let outerR = outerRadius()
        let midR   = outerR - ringWidth / 2
        let innerR = outerR - ringWidth

        let now = Date()
        let cal = Calendar.current
        let hms = cal.dateComponents([.hour, .minute, .second], from: now)
        let currentTime = Double(hms.hour!) + Double(hms.minute!) / 60 + Double(hms.second!) / 3600

        let workDuration = Double(workEnd - workStart)

        // ── Background circle ────────────────────────────────────────────────
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: 18,
                      color: NSColor(calibratedRed: 0.2, green: 0.3, blue: 1, alpha: 0.28).cgColor)
        let bgRect = CGRect(x: cx - outerR, y: cy - outerR, width: outerR * 2, height: outerR * 2)
        ctx.addEllipse(in: bgRect)
        ctx.setFillColor(NSColor(calibratedWhite: 0.04, alpha: 0.75).cgColor)
        ctx.fillPath()
        ctx.addEllipse(in: bgRect)
        ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.12).cgColor)
        ctx.setLineWidth(1)
        ctx.strokePath()
        ctx.restoreGState()

        // ── Track ring (full workday, dim) ───────────────────────────────────
        ctx.saveGState()
        ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.06).cgColor)
        ctx.setLineWidth(ringWidth)
        ctx.strokeEllipse(in: CGRect(x: cx - midR, y: cy - midR, width: midR * 2, height: midR * 2))
        ctx.restoreGState()

        // ── Event arcs ───────────────────────────────────────────────────────
        for event in todayEvents {
            guard let startDate = event.startDate, let endDate = event.endDate else { continue }
            let sComps = cal.dateComponents([.hour, .minute], from: startDate)
            let eComps = cal.dateComponents([.hour, .minute], from: endDate)
            let evStart = Double(sComps.hour!) + Double(sComps.minute!) / 60
            let evEnd   = Double(eComps.hour!) + Double(eComps.minute!) / 60

            let clampedStart = max(evStart, Double(workStart))
            let clampedEnd   = min(evEnd,   Double(workEnd))
            guard clampedEnd > clampedStart else { continue }

            let a1 = timeToAngle(clampedStart)
            let a2 = timeToAngle(clampedEnd)

            let color = event.calendar?.color ?? NSColor.systemBlue
            ctx.saveGState()
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(ringWidth)
            ctx.setLineCap(.butt)
            // Clockwise in Y-up = screen-clockwise; angles decrease with time
            ctx.addArc(center: CGPoint(x: cx, y: cy), radius: midR,
                       startAngle: a1, endAngle: a2, clockwise: true)
            ctx.strokePath()
            ctx.restoreGState()
        }

        // ── Hour tick marks (cut through the ring) ───────────────────────────
        for h in workStart...workEnd {
            let a = timeToAngle(Double(h))
            let ca = cos(a), sa = sin(a)
            let isMajor = (h % 2 == 0)
            let gap: CGFloat = isMajor ? 1 : 2
            let x1 = cx + (outerR - gap) * ca
            let y1 = cy + (outerR - gap) * sa
            let x2 = cx + (innerR + gap) * ca
            let y2 = cy + (innerR + gap) * sa

            ctx.saveGState()
            ctx.setStrokeColor(NSColor.black.withAlphaComponent(0.85).cgColor)
            ctx.setLineWidth(isMajor ? 2 : 1.5)
            ctx.move(to: CGPoint(x: x1, y: y1))
            ctx.addLine(to: CGPoint(x: x2, y: y2))
            ctx.strokePath()
            ctx.restoreGState()
        }

        // ── Hour labels outside the ring ─────────────────────────────────────
        let labelR = outerR + 10
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 7, weight: .medium),
            .foregroundColor: NSColor.white.withAlphaComponent(0.40),
        ]
        for h in stride(from: workStart, through: workEnd, by: 2) {
            let a = timeToAngle(Double(h))
            let lx = cx + labelR * cos(a)
            let ly = cy + labelR * sin(a)
            let hh = h % 12 == 0 ? 12 : h % 12
            let ap = h < 12 ? "a" : "p"
            let s = NSAttributedString(string: "\(hh)\(ap)", attributes: labelAttrs)
            let sz = s.size()
            s.draw(at: NSPoint(x: lx - sz.width / 2, y: ly - sz.height / 2))
        }

        // ── White wedge: progress through the current event ──────────────────
        let currentEvent = todayEvents.first(where: { ev -> Bool in
            guard let s = ev.startDate, let e = ev.endDate else { return false }
            let sc = cal.dateComponents([.hour, .minute], from: s)
            let ec = cal.dateComponents([.hour, .minute], from: e)
            let evS = Double(sc.hour!) + Double(sc.minute!) / 60
            let evE = Double(ec.hour!) + Double(ec.minute!) / 60
            return currentTime >= evS && currentTime < evE
        })

        if let ev = currentEvent, let startDate = ev.startDate {
            let sc = cal.dateComponents([.hour, .minute], from: startDate)
            let evStart = Double(sc.hour!) + Double(sc.minute!) / 60
            let a1 = timeToAngle(evStart)
            let a2 = timeToAngle(currentTime)
            // a1 > a2 because angles decrease as time increases (clockwise sweep)
            if a1 > a2 {
                ctx.saveGState()
                ctx.setShadow(offset: .zero, blur: 8,
                              color: NSColor.white.withAlphaComponent(0.35).cgColor)
                ctx.beginPath()
                ctx.move(to: CGPoint(x: cx, y: cy))
                ctx.addArc(center: CGPoint(x: cx, y: cy), radius: innerR - 3,
                           startAngle: a1, endAngle: a2, clockwise: true)
                ctx.closePath()
                ctx.setFillColor(NSColor.white.withAlphaComponent(0.88).cgColor)
                ctx.fillPath()
                ctx.restoreGState()
            }
        }

        // ── Glowing dot at current time position ─────────────────────────────
        if currentTime >= Double(workStart) && currentTime <= Double(workEnd) {
            let ca = timeToAngle(currentTime)
            let dotX = cx + midR * cos(ca)
            let dotY = cy + midR * sin(ca)
            ctx.saveGState()
            ctx.setShadow(offset: .zero, blur: 6, color: NSColor.white.cgColor)
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fillEllipse(in: CGRect(x: dotX - 3, y: dotY - 3, width: 6, height: 6))
            ctx.restoreGState()
        }

        // ── Center text ───────────────────────────────────────────────────────
        let timeFontSize = innerR * 0.30
        let subFontSize  = innerR * 0.19

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeStr = formatter.string(from: now)

        let timeAttrStr = NSAttributedString(string: timeStr, attributes: [
            .font: NSFont.systemFont(ofSize: timeFontSize, weight: .semibold),
            .foregroundColor: NSColor.white.withAlphaComponent(0.95),
        ])
        let tSz = timeAttrStr.size()
        // Draw time slightly above center
        timeAttrStr.draw(at: NSPoint(x: cx - tSz.width / 2, y: cy + 2))

        let subText: String
        let subColor: NSColor
        if let ev = currentEvent, let endDate = ev.endDate {
            let secs = endDate.timeIntervalSince(now)
            let mins = max(0, Int(secs / 60))
            subText = mins < 60 ? "\(mins)m left" : "\(mins / 60)h \(mins % 60)m left"
            subColor = (ev.calendar?.color ?? NSColor.systemBlue).withAlphaComponent(0.85)
        } else if currentTime < Double(workStart) {
            let mins = Int((Double(workStart) - currentTime) * 60)
            subText = "starts \(mins)m"
            subColor = NSColor.white.withAlphaComponent(0.35)
        } else if currentTime >= Double(workEnd) {
            subText = "day done"
            subColor = NSColor.white.withAlphaComponent(0.30)
        } else {
            let next = todayEvents.first(where: {
                guard let s = $0.startDate else { return false }
                let sc = cal.dateComponents([.hour, .minute], from: s)
                return Double(sc.hour!) + Double(sc.minute!) / 60 > currentTime
            })
            if let n = next, let ns = n.startDate {
                let free = Int(ns.timeIntervalSince(now) / 60)
                subText = "free · \(free)m"
            } else {
                subText = "free time"
            }
            subColor = NSColor.white.withAlphaComponent(0.35)
        }

        let subAttrStr = NSAttributedString(string: subText, attributes: [
            .font: NSFont.systemFont(ofSize: subFontSize),
            .foregroundColor: subColor,
        ])
        let sSz = subAttrStr.size()
        subAttrStr.draw(at: NSPoint(x: cx - sSz.width / 2, y: cy - sSz.height - 1))

        // Faint workday-remaining arc on the outer edge
        if currentTime >= Double(workStart) && currentTime < Double(workEnd) {
            let a1 = timeToAngle(currentTime)
            let a2 = timeToAngle(Double(workEnd))
            ctx.saveGState()
            ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.09).cgColor)
            ctx.setLineWidth(2)
            ctx.setLineCap(.round)
            ctx.addArc(center: CGPoint(x: cx, y: cy), radius: outerR - 1,
                       startAngle: a1, endAngle: a2, clockwise: true)
            ctx.strokePath()
            ctx.restoreGState()
        }

        _ = workDuration  // suppress unused-variable warning
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
