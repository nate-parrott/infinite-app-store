//
//  AppDelegate.swift
//  InfiniteAppStore
//
//  Created by nate parrott on 6/8/24.
//

import Cocoa
import ChatToys

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBAction func showStoreVC(_ sender: Any?) {
        if let match = NSApplication.shared.windows.first(where: { $0.contentViewController is StoreViewController }) {
            match.makeKeyAndOrderFront(nil)
        } else {
            // Load "StoreWindowController" from storyboard
            let storyboard = NSStoryboard(name: "Main", bundle: nil)
            let storeVC = storyboard.instantiateController(withIdentifier: "StoreWindowController") as! NSWindowController
            storeVC.showWindow(nil)
        }
    }

    @IBAction func updateOpenAIKey(_ sender: Any?) {
        DefaultsKeys.openAIKey.stringValue = ""
        Task {
            _ = try? await OpenAICredentials.getOrPromptForCreds()
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        _ = StatusMenuManager.shared
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
            showStoreVC(nil)
        }
        return true
    }
}

