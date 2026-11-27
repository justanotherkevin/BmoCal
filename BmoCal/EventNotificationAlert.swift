import Cocoa
import SwiftUI

// MARK: - View

struct EventAlertView: View {
    let design: AlertDesign
    let title: String
    let start: Date
    let link: URL?
    let color: NSColor
    let onJoin: () -> Void
    let onDismiss: () -> Void
    /// Shown in the meta line when the location is plain text rather than a link.
    var locationText: String? = nil

    @State private var opened = Date()

    private var cal: Color { Color(nsColor: color) }
    private let track = Color(white: 0.23)
    private let muted = Color(white: 0.6)

    /// m:ss (h:mm:ss from one hour), rounded up so 0:00 only shows once the event has started.
    static func countdownText(_ secs: TimeInterval) -> String {
        guard secs > 0 else { return "Started" }
        let t = Int(ceil(secs))
        let (h, m, s) = (t / 3600, t % 3600 / 60, t % 60)
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }

    private var meta: String {
        var s = start.formatted(date: .omitted, time: .shortened)
        if let host = link?.host { s += " · \(host)" } else if let t = locationText, !t.isEmpty { s += " · \(t)" }
        return s
    }

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 1)) { ctx in
            let remaining = start.timeIntervalSince(ctx.date)
            let total = max(start.timeIntervalSince(opened), 1)
            let fraction = min(max(remaining / total, 0), 1)
            content(time: Self.countdownText(remaining), fraction: fraction, started: remaining <= 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environment(\.colorScheme, .dark)
        .foregroundColor(.white) // ImageRenderer ignores the forced scheme, so set the text color directly
    }

    @ViewBuilder
    private func content(time: String, fraction: Double, started: Bool) -> some View {
        let timeColor = started ? cal : Color.white
        switch design {
        case .ring: ring(time, fraction, timeColor)
        case .card: card(time, fraction, timeColor)
        case .edge: edge(time, fraction, timeColor)
        }
    }

    private var buttons: some View {
        HStack(spacing: Theme.Space.s) {
            if link != nil {
                Button(action: onJoin) { Text("Join") + Text("  ↩").font(.caption).foregroundColor(.white.opacity(0.7)) }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
            Button(action: onDismiss) { Text("Dismiss") + Text("  esc").font(.caption).foregroundColor(.white.opacity(0.6)) }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
        }
        .controlSize(.large)
    }

    // Ring: dark veil over a blurred screen, calendar colored ring drains toward the start.
    private func ring(_ time: String, _ f: Double, _ timeColor: Color) -> some View {
        ZStack {
            Color(red: 10 / 255, green: 10 / 255, blue: 12 / 255).opacity(0.82)
            VStack(spacing: Theme.Space.m) {
                ZStack {
                    Circle().stroke(track, lineWidth: 12)
                    Circle().trim(from: 0, to: f)
                        .stroke(cal, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 2) {
                        Text(time).font(.system(size: 56, weight: .semibold)).monospacedDigit().foregroundColor(timeColor)
                        Text("until start").font(.system(size: 14)).foregroundColor(muted)
                    }
                }
                .frame(width: 320, height: 320)
                .padding(.bottom, Theme.Space.s)
                Text(title).font(.system(size: 28, weight: .semibold)).multilineTextAlignment(.center)
                Text(meta).font(.system(size: 15)).foregroundColor(muted)
                buttons.padding(.top, Theme.Space.xs)
            }
            .padding(48)
        }
    }

    // Card: focused panel over a dimmed, blurred screen.
    private func card(_ time: String, _ f: Double, _ timeColor: Color) -> some View {
        ZStack {
            Color.black.opacity(0.45)
            VStack(spacing: 0) {
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        track
                        cal.frame(width: g.size.width * f)
                    }
                }
                .frame(height: 6)
                HStack(alignment: .top, spacing: Theme.Space.m) {
                    RoundedRectangle(cornerRadius: 2).fill(cal).frame(width: 5)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("STARTING SOON").font(.system(size: 12)).tracking(0.8).foregroundColor(muted)
                        Text(title).font(.system(size: 24, weight: .semibold))
                        Text(time).font(.system(size: 48, weight: .semibold)).monospacedDigit().foregroundColor(timeColor)
                        Text(meta).font(.system(size: 14)).foregroundColor(muted)
                    }
                    Spacer(minLength: 0)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 28).padding(.vertical, 24)
                HStack { Spacer(); buttons.environment(\.layoutDirection, .rightToLeft) }
                    .padding(.horizontal, 28).padding(.bottom, 22)
            }
            .frame(width: 640)
            .background(Color(white: 0.11))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.panel))
            .shadow(color: .black.opacity(0.5), radius: 30, y: 16)
        }
    }

    // Edge: solid screen, huge countdown, full width bar drains along the top.
    private func edge(_ time: String, _ f: Double, _ timeColor: Color) -> some View {
        ZStack(alignment: .topLeading) {
            Color(red: 15 / 255, green: 15 / 255, blue: 16 / 255)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    track
                    cal.frame(width: g.size.width * f)
                }
            }
            .frame(height: 12)
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                Text("STARTS IN").font(.system(size: 18, weight: .semibold)).tracking(1).foregroundColor(cal)
                Text(time).font(.system(size: 160, weight: .bold)).monospacedDigit().foregroundColor(timeColor)
                    .minimumScaleFactor(0.5).lineLimit(1)
                Text(title).font(.system(size: 34, weight: .semibold)).padding(.top, Theme.Space.s)
                Text(meta).font(.system(size: 16)).foregroundColor(muted)
                buttons.padding(.top, Theme.Space.l)
            }
            .padding(.horizontal, 130)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Window

private final class AlertWindow: NSWindow {
    override var canBecomeKey: Bool { true }
}

final class EventAlertWindowController: NSWindowController, NSWindowDelegate {
    private static var open: [EventAlertWindowController] = []
    private var soundTimer: Timer?

    /// A link only if it parses and is http(s); returns the newline-flattened text either way.
    static func parse(location: String) -> (text: String, url: URL?) {
        let text = location.replacingOccurrences(of: "\n", with: ", ")
        let url = URL(string: text).flatMap { ["http", "https"].contains($0.scheme?.lowercased() ?? "") ? $0 : nil }
        return (text, url)
    }

    static func show(design: AlertDesign, title: String, start: Date, location: String, color: NSColor, playSound: Bool) {
        guard let frame = NSScreen.main?.frame else { return }
        let (text, url) = parse(location: location)

        let window = AlertWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)))
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let controller = EventAlertWindowController(window: window)
        window.delegate = controller

        let root = EventAlertView(
            design: design, title: title, start: start, link: url, color: color,
            onJoin: { [weak controller] in
                if let url { NSWorkspace.shared.open(url) }
                controller?.close()
            },
            onDismiss: { [weak controller] in controller?.close() },
            locationText: url == nil ? text : nil)
        let host = NSHostingView(rootView: root)
        host.frame = NSRect(origin: .zero, size: frame.size)
        host.autoresizingMask = [.width, .height]

        if design == .edge {
            window.contentView = host
        } else {
            let blur = NSVisualEffectView(frame: host.frame)
            blur.material = .hudWindow
            blur.blendingMode = .behindWindow
            blur.state = .active
            blur.appearance = NSAppearance(named: .darkAqua)
            blur.autoresizingMask = [.width, .height]
            blur.addSubview(host)
            window.contentView = blur
        }
        window.setFrame(frame, display: true)

        open.append(controller)
        controller.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        if playSound {
            NSSound.beep()
            let wait = start.timeIntervalSinceNow
            if wait > 0 {
                let t = Timer(timeInterval: wait, repeats: false) { _ in NSSound.beep() }
                RunLoop.main.add(t, forMode: .common)
                controller.soundTimer = t
            }
        }
    }

    func windowWillClose(_ notification: Notification) {
        soundTimer?.invalidate()
        Self.open.removeAll { $0 === self }
    }
}
