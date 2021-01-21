import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if flag {
            return false
        }
        else {
            guard let controller = NSStoryboard(name: "Main", bundle: nil).instantiateInitialController() as? NSWindowController else {
                return true
            }

            controller.showWindow(nil)
            return false
        }
    }
}

