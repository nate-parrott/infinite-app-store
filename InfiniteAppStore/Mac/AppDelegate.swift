//
//  AppDelegate.swift
//  InfiniteAppStore
//
//  Created by nate parrott on 6/8/24.
//

import Cocoa
import ChatToys

func isPreview() -> Bool {
    return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBAction func controlPanel(_ sender: Any?) {
        showSettingsView()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if !isPreview() {
            _ = Server.shared
            _ = StatusMenuManager.shared
        }
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    // When app icon is clicked, and no windows are shown, show the store
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            StatusMenuManager.shared.showMenu()
        }
        return true
    }
}

