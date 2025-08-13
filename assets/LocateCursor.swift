import Cocoa
import Foundation

let pidFilePath = "/tmp/LocateCursor.pid"

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

class OverlayView: NSView {
    let cursorRadius: CGFloat
    let dimOpacity: CGFloat
    let screenFrame: NSRect

    init(frame: NSRect, cursorRadius: CGFloat, dimOpacity: CGFloat, screenFrame: NSRect) {
        self.cursorRadius = cursorRadius
        self.dimOpacity = dimOpacity
        self.screenFrame = screenFrame
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.setFillColor(NSColor.black.withAlphaComponent(dimOpacity).cgColor)
        context.fill(bounds)

        let mouseLocation = NSEvent.mouseLocation
        var containingScreen: NSScreen? = NSScreen.screens.first
        for screen in NSScreen.screens {
            if screen.frame.contains(mouseLocation) {
                containingScreen = screen
                break
            }
        }
        let screenFrame = containingScreen?.frame ?? NSScreen.main?.frame ?? .zero
        let cursorX = mouseLocation.x - screenFrame.origin.x
        let cursorY = mouseLocation.y - screenFrame.origin.y
        let cursorCenter = CGPoint(x: cursorX, y: cursorY)

        context.setBlendMode(.clear)
        context.addEllipse(in: CGRect(
            x: cursorCenter.x - cursorRadius,
            y: cursorCenter.y - cursorRadius,
            width: cursorRadius * 2,
            height: cursorRadius * 2
        ))
        context.fillPath()
        context.setBlendMode(.normal)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: OverlayWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let args = CommandLine.arguments
        if args.count > 1 {
            switch args[1] {
            case "off":
                terminateRunningInstance()
                NSApp.terminate(nil)
                return
            case "on":
                setupOverlay()
                handleOnCommand(args: args)
            default:
                // Fallback for any other argument, could be the duration for backward compatibility
                setupOverlay()
                handleLegacyOrDurationCommand(args: args)
            }
        } else {
            // No arguments, run for 1 second
            setupOverlay()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                NSApp.terminate(nil)
            }
        }
    }

    func setupOverlay() {
        let mouseLocation = NSEvent.mouseLocation
        var containingScreen: NSScreen? = NSScreen.screens.first
        for screen in NSScreen.screens {
            if screen.frame.contains(mouseLocation) {
                containingScreen = screen
                break
            }
        }
        let screenFrame = containingScreen?.frame ?? NSScreen.main?.frame ?? .zero
        let frame = screenFrame
        let window = OverlayWindow(frame: frame)
        let view = OverlayView(
            frame: NSRect(origin: .zero, size: frame.size),
            cursorRadius: 80,
            dimOpacity: 0.8,
            screenFrame: frame
        )
        window.contentView = view
        window.setFrameOrigin(frame.origin)
        window.makeKeyAndOrderFront(nil)
        self.window = window
    }

    func handleOnCommand(args: [String]) {
        writePidToFile()
        if args.count > 2, let duration = Double(args[2]), duration > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                self.cleanupAndTerminate()
            }
        }
        // If no duration, it runs indefinitely
    }

    func handleLegacyOrDurationCommand(args: [String]) {
        if let duration = Double(args[1]), duration > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                NSApp.terminate(nil)
            }
        } else {
            // Default to 1 second if argument is not a valid duration
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                NSApp.terminate(nil)
            }
        }
    }

    func writePidToFile() {
        let pid = getpid()
        do {
            try String(pid).write(toFile: pidFilePath, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to write PID file: \(error)")
        }
    }

    func terminateRunningInstance() {
        do {
            let pidString = try String(contentsOfFile: pidFilePath, encoding: .utf8)
            if let pid = Int32(pidString.trimmingCharacters(in: .whitespacesAndNewlines)) {
                kill(pid, SIGTERM)
            }
            try FileManager.default.removeItem(atPath: pidFilePath)
        } catch {
            // PID file might not exist, which is fine.
        }
    }

    func cleanupAndTerminate() {
        do {
            try FileManager.default.removeItem(atPath: pidFilePath)
        } catch {
            print("Failed to remove PID file on exit: \(error)")
        }
        NSApp.terminate(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // This is a fallback cleanup
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: pidFilePath) {
            do {
                let pidString = try String(contentsOfFile: pidFilePath, encoding: .utf8)
                let currentPid = getpid()
                if pidString.trimmingCharacters(in: .whitespacesAndNewlines) == String(currentPid) {
                    try fileManager.removeItem(atPath: pidFilePath)
                }
            } catch {
                // Ignore
            }
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
