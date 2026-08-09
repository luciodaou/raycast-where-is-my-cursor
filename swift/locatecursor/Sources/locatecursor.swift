import Cocoa
import Foundation
import RaycastSwiftMacros

// MARK: - Data Structures
struct CircleConfig: Codable {
    let radius: CGFloat
    let opacity: CGFloat
    let color: String
    let border: BorderConfig?
}

struct BorderConfig: Codable {
    let width: CGFloat
    let color: String
}

struct PresetConfig: Codable {
    let duration: TimeInterval
    let screenOpacity: CGFloat
    let circle: CircleConfig
}

struct Config: Codable {
    let `default`: PresetConfig
    let presentation: PresetConfig
    let simple: PresetConfig
}

// MARK: - Configuration Loader
class ConfigLoader {
    func loadConfig() -> Config? {
        if let url = Bundle.main.url(forResource: "../locatecursor", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                return try decoder.decode(Config.self, from: data)
            } catch {
                NSLog("Error loading or decoding config: \(error)")
                return nil
            }
        } else {
            NSLog("Warning: locatecursor.json not found. Using default configuration.")
            return Config(
                default: PresetConfig(
                    duration: 2,
                    screenOpacity: 0.5,
                    circle: CircleConfig(
                        radius: 80,
                        opacity: 0.0,
                        color: "clear",
                        border: BorderConfig(width: 2, color: "white")
                    )
                ),
                presentation: PresetConfig(
                    duration: 0,
                    screenOpacity: 0.0,
                    circle: CircleConfig(
                        radius: 80,
                        opacity: 0.2,
                        color: "yellow",
                        border: BorderConfig(width: 0, color: "white")
                    )
                ),
                simple: PresetConfig(
                    duration: 5,
                    screenOpacity: 0,
                    circle: CircleConfig(
                        radius: 100,
                        opacity: 0.5,
                        color: "red",
                        border: BorderConfig(width: 5, color: "yellow")
                    )
                )
            )
        }
    }
}

// MARK: - UI Classes
class OverlayWindow: NSWindow {
    init(frame: NSRect) {
        super.init(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .mainMenu + 1
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }
}

private let namedColors: [String: NSColor] = [
    "red": .red, "green": .green, "blue": .blue, "white": .white,
    "black": .black, "yellow": .yellow, "cyan": .cyan, "magenta": .magenta,
    "orange": .orange, "purple": .purple, "brown": .brown, "clear": .clear
]

func colorFromString(_ colorString: String) -> NSColor {
    let lowercased = colorString.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    
    if let color = namedColors[lowercased] {
        return color
    }
    
    if lowercased.hasPrefix("#") {
        let hexString = String(lowercased.dropFirst())
        let len = hexString.count
        if len == 3, let hexValue = UInt32(hexString, radix: 16) {
            let r = CGFloat((hexValue & 0xF00) >> 8) / 15.0
            let g = CGFloat((hexValue & 0x0F0) >> 4) / 15.0
            let b = CGFloat(hexValue & 0x00F) / 15.0
            return NSColor(red: r, green: g, blue: b, alpha: 1.0)
        } else if len == 6, let hexValue = UInt32(hexString, radix: 16) {
            let r = CGFloat((hexValue & 0xFF0000) >> 16) / 255.0
            let g = CGFloat((hexValue & 0x00FF00) >> 8) / 255.0
            let b = CGFloat(hexValue & 0x0000FF) / 255.0
            return NSColor(red: r, green: g, blue: b, alpha: 1.0)
        } else if len == 8, let hexValue = UInt32(hexString, radix: 16) {
            let r = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
            let g = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
            let b = CGFloat((hexValue & 0x0000FF00) >> 8) / 255.0
            let a = CGFloat(hexValue & 0x000000FF) / 255.0
            return NSColor(red: r, green: g, blue: b, alpha: a)
        }
    }
    
    return .black
}

class OverlayView: NSView {
    let config: PresetConfig
    private let isClearCircle: Bool
    private let screenColor: CGColor
    private let circleColor: CGColor
    private let borderColor: CGColor?
    private let borderWidth: CGFloat
    private var lastInvalidRect: CGRect = .zero
    private var currentCircleRect: CGRect = .zero

    init(frame: NSRect, config: PresetConfig) {
        self.config = config
        self.isClearCircle = (config.circle.color.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "clear")
        self.screenColor = NSColor.black.withAlphaComponent(config.screenOpacity).cgColor
        let rawCircleColor = colorFromString(config.circle.color)
        self.circleColor = rawCircleColor.withAlphaComponent(config.circle.opacity).cgColor
        if let border = config.circle.border {
            self.borderColor = colorFromString(border.color).cgColor
            self.borderWidth = border.width
        } else {
            self.borderColor = nil
            self.borderWidth = 0
        }
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        NSLog("Error: init(coder:) is not implemented.")
        return nil
    }

    func updateCursorLocation(_ mouseLocation: NSPoint) {
        guard let window = self.window else { return }

        let screenContainingMouse = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) ?? window.screen ?? NSScreen.main
        let screenFrame = screenContainingMouse?.frame ?? window.frame

        if window.frame != screenFrame {
            window.setFrame(screenFrame, display: true)
            self.frame = NSRect(origin: .zero, size: screenFrame.size)
            self.lastInvalidRect = .zero
            self.currentCircleRect = .zero
            self.needsDisplay = true
            return
        }

        let cursorInWindow = CGPoint(x: mouseLocation.x - screenFrame.origin.x, y: mouseLocation.y - screenFrame.origin.y)
        let radius = config.circle.radius
        let padding = borderWidth + 4
        let circleRect = CGRect(
            x: cursorInWindow.x - radius,
            y: cursorInWindow.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        self.currentCircleRect = circleRect
        let currentInvalidRect = circleRect.insetBy(dx: -padding, dy: -padding)

        if lastInvalidRect.isEmpty {
            setNeedsDisplay(currentInvalidRect)
        } else {
            setNeedsDisplay(lastInvalidRect.union(currentInvalidRect))
        }

        lastInvalidRect = currentInvalidRect
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let circleRect: CGRect
        if !currentCircleRect.isEmpty {
            circleRect = currentCircleRect
        } else {
            let mouseLocation = NSEvent.mouseLocation
            let windowFrame = window?.frame ?? bounds
            let cursorInWindow = CGPoint(x: mouseLocation.x - windowFrame.origin.x, y: mouseLocation.y - windowFrame.origin.y)
            let radius = config.circle.radius
            circleRect = CGRect(
                x: cursorInWindow.x - radius,
                y: cursorInWindow.y - radius,
                width: radius * 2,
                height: radius * 2
            )
        }

        context.setFillColor(screenColor)
        context.fill(dirtyRect)

        if isClearCircle {
            context.saveGState()
            context.addEllipse(in: circleRect)
            context.clip()
            context.clear(circleRect)
            context.restoreGState()
        } else {
            context.setFillColor(circleColor)
            context.fillEllipse(in: circleRect)
        }

        if let borderColor = borderColor, borderWidth > 0 {
            context.setStrokeColor(borderColor)
            context.setLineWidth(borderWidth)
            context.strokeEllipse(in: circleRect)
        }
    }
}


class LocateCursorTool: NSObject, NSApplicationDelegate {
    var window: OverlayWindow?
    var mouseMoveMonitor: Any?
    var keyDownMonitor: Any?

    private var lockFileURL: URL? = {
        guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            NSLog("Error: Unable to find Application Support directory.")
            return nil
        }
        let directoryURL = appSupportURL.appendingPathComponent("com.raycast.where-is-my-cursor")
        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            return directoryURL.appendingPathComponent("LocateCursor.lock")
        } catch {
            NSLog("Error: Unable to create directory \(directoryURL): \(error)")
            return nil
        }
    }()

    func start(with config: PresetConfig, duration: TimeInterval) {
        if let pid = readLockFile() {
            terminateProcess(pid: pid)
        }

        writeLockFile()
        setupOverlay(with: config)

        if duration > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                self.cleanupAndTerminate()
            }
        }

        let app = NSApplication.shared
        app.delegate = self
        app.run()
    }

    func stop() {
        if let pid = readLockFile() {
            terminateProcess(pid: pid)
        }
        if let lockURL = lockFileURL {
            try? FileManager.default.removeItem(at: lockURL)
        }
    }

    private func writeLockFile() {
        guard let lockURL = lockFileURL else { return }
        let pid = ProcessInfo.processInfo.processIdentifier
        try? String(pid).write(to: lockURL, atomically: true, encoding: .utf8)
    }

    private func readLockFile() -> Int32? {
        guard let lockURL = lockFileURL, let pidString = try? String(contentsOf: lockURL, encoding: .utf8) else { return nil }
        return Int32(pidString)
    }

    private func isAnotherInstanceRunning() -> Bool {
        guard let pid = readLockFile() else { return false }
        return NSRunningApplication(processIdentifier: pid) != nil
    }

    private func terminateProcess(pid: Int32) {
        if let runningApp = NSRunningApplication(processIdentifier: pid),
           runningApp.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            let isLocateCursorApp = runningApp.bundleIdentifier == "com.raycast.where-is-my-cursor" ||
                                    runningApp.executableURL?.lastPathComponent == "locatecursor"
            if isLocateCursorApp {
                runningApp.terminate()
                if !runningApp.isTerminated {
                    runningApp.forceTerminate()
                }
            }
        }
    }

    private func terminateRunningInstance() {
        stop()
    }

    private func cleanupAndTerminate() {
        removeMonitors()
        if let pid = readLockFile(), pid == ProcessInfo.processInfo.processIdentifier {
            if let lockURL = lockFileURL {
                try? FileManager.default.removeItem(at: lockURL)
            }
        }
        if NSApp.delegate === self {
            DispatchQueue.main.async {
                NSApp.terminate(nil)
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        cleanupAndTerminate()
    }

    private func setupOverlay(with config: PresetConfig) {
        let mouseLocation = NSEvent.mouseLocation
        let screenFrame = NSScreen.screens.first { $0.frame.contains(mouseLocation) }?.frame ?? NSScreen.main?.frame ?? .zero

        let window = OverlayWindow(frame: screenFrame)
        let view = OverlayView(frame: NSRect(origin: .zero, size: screenFrame.size), config: config)

        window.contentView = view
        window.setFrameOrigin(screenFrame.origin)
        window.makeKeyAndOrderFront(nil)

        self.window = window

        startMonitors()
        emitRaycastSuccess()
    }

    private func startMonitors() {
        mouseMoveMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            guard let self = self, let overlayView = self.window?.contentView as? OverlayView else { return }
            overlayView.updateCursorLocation(NSEvent.mouseLocation)
        }

        let escapeKeyCode: UInt16 = 53

        keyDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == escapeKeyCode {
                self?.cleanupAndTerminate()
            }
        }
    }

    private func removeMonitors() {
        if let monitor = mouseMoveMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = keyDownMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}

private func emitRaycastSuccess() {
    fputs("{}\n", stdout)
    fflush(stdout)
}

@raycast func locatecursor(arg1: String, arg2: String, arg3: String) {
    let tool = LocateCursorTool()

    if arg1 == "off" {
        tool.stop()
        emitRaycastSuccess()
        return
    }
    
    let configLoader = ConfigLoader()
    guard let config = configLoader.loadConfig() else {
        NSLog("Failed to load config.")
        emitRaycastSuccess()
        return
    }

    var preset: PresetConfig

    if !arg1.isEmpty {
        switch arg1 {
        case "-p":
            let presetName = arg2
            switch presetName {
            case "presentation":
                preset = config.presentation
            case "simple":
                preset = config.simple
            default:
                preset = config.default
            }
        case "-c":
            if !arg2.isEmpty,
               let data = arg2.data(using: .utf8),
               let customPreset = try? JSONDecoder().decode(PresetConfig.self, from: data) {
                preset = customPreset
            } else {
                preset = config.default
            }
        default:
            preset = config.default
        }
    } else {
        preset = config.default
    }

    tool.start(with: preset, duration: preset.duration)
}

