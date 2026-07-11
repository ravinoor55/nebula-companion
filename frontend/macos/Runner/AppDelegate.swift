import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
    var popover: NSPopover!
    var statusBarItem: NSStatusItem!

    override func applicationDidFinishLaunching(_ aNotification: Notification) {
        let flutterViewController = FlutterViewController()
        RegisterGeneratedPlugins(registry: flutterViewController)
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 600)
        popover.behavior = .transient
        popover.contentViewController = flutterViewController

        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusBarItem.button {
            button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Nebula")
            button.action = #selector(togglePopover(_:))
        }

        // Hide default window
        if let window = mainFlutterWindow {
            window.close()
        }
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusBarItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                popover.contentViewController?.view.window?.makeKey()
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
