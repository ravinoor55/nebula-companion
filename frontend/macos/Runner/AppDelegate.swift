import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
    var popover: NSPopover!
    var statusBarItem: NSStatusItem!

    override func applicationDidFinishLaunching(_ aNotification: Notification) {
        guard let window = mainFlutterWindow,
              let flutterViewController = window.contentViewController as? FlutterViewController else {
            return
        }
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 600)
        popover.behavior = .transient
        popover.contentViewController = flutterViewController

        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusBarItem.button {
            button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Nebula")
            button.action = #selector(togglePopover(_:))
        }

        // Hide default window instead of closing it
        window.orderOut(nil)
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusBarItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                NSApp.activate(ignoringOtherApps: true)
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                self.popover.contentViewController?.view.window?.makeKey()
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
