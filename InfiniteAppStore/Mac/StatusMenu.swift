import Foundation
import AppKit
import SwiftUI

class StatusMenuManager: NSObject {
    static let shared = StatusMenuManager()

    let statusItem: NSStatusItem
    private var window: BorderlessSwiftUIWindow<AppMenuView>?

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.setAccessibilityLabel("Infinite App Store Apps")
            button.image = NSImage(named: "icon95") // NSImage(systemSymbolName: "app.gift.fill", accessibilityDescription: "Infinite App Store Apps")
            button.imageScaling = .scaleProportionallyDown
        }
        super.init()

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(toggleMenu(sender:))
        }
    }

    func showMenu() {
        if !isVisible {
            toggleMenu(sender: nil)
        }
    }

    var isVisible: Bool {
        window?.isVisible ?? false
    }

    @objc private func toggleMenu(sender: Any?) {
        let visibleWindow = window?.isVisible ?? false ? window : nil
        if visibleWindow == nil {
            let window = BorderlessSwiftUIWindow(resizable: false, dialog: false) {
                AppMenuView()
            }
            window.level = .popUpMenu
            window.makeKeyAndOrderFront(nil)

            // TODO: is there a better way to do this?
            window.makeMain()
            NSApp.activate()
            window.closeOnResignMain = true

            // Position menu to beneath the status item (aligned to the right side of the status item button)
            let buttonRect = statusItem.button!.convert(statusItem.button!.bounds, to: nil)
            let screenRect = statusItem.button!.window!.convertToScreen(buttonRect)
            let windowRect = window.frame
            window.setFrameOrigin(NSPoint(x: screenRect.maxX - windowRect.width, y: screenRect.minY - windowRect.height))

            self.window = window
        } else {
            visibleWindow?.close()
            window = nil
        }
    }
}

extension NSApplication {
    @MainActor
    func openOrFocusProgram(id: String) {
        //             view.window?.frameAutosaveName
        if let win = windows.first(where: { ($0.contentViewController as? AppViewController)?.programID == id }) {
            win.makeKeyAndOrderFront(nil)
        } else {
            let windowController = NSStoryboard.main!.instantiateController(withIdentifier: "AppWindowController") as! NSWindowController
            let vc = windowController.window!.contentViewController!  as! AppViewController
            vc.programID = id
            windowController.window?.setFrameUsingName("Program:\(id)", force: false)
            windowController.window?.makeKeyAndOrderFront(nil)
            windowController.window?.setFrameAutosaveName("Program:\(id)")
        }
    }
}
