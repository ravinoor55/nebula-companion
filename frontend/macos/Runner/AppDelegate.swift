import Cocoa
import FlutterMacOS

class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { return true }
    override var canBecomeMain: Bool { return true }
}

@main
class AppDelegate: FlutterAppDelegate {
    var panel: FloatingPanel!
    var statusBarItem: NSStatusItem!

    override func applicationDidFinishLaunching(_ aNotification: Notification) {
        guard let window = mainFlutterWindow,
              let flutterViewController = window.contentViewController as? FlutterViewController else {
            return
        }
        
        panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 600),
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.contentViewController = flutterViewController

        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusBarItem.button {
            button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Nebula")
            button.action = #selector(togglePanel(_:))
        }

        // Hide default window instead of closing it
        window.orderOut(nil)
    }

    @objc func togglePanel(_ sender: AnyObject?) {
        if let button = statusBarItem.button {
            if panel.isVisible {
                panel.orderOut(nil)
            } else {
                if let window = button.window {
                    let buttonRect = window.convertToScreen(button.convert(button.bounds, to: nil))
                    let x = buttonRect.midX - panel.frame.width / 2
                    let y = buttonRect.minY - panel.frame.height
                    panel.setFrameOrigin(NSPoint(x: x, y: y))
                }
                
                NSApp.activate(ignoringOtherApps: true)
                panel.makeKeyAndOrderFront(nil)
            }
        }
    }

    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
