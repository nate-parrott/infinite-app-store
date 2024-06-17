import Foundation

@discardableResult
func contactDevForProgram(id: String) -> BorderlessSwiftUIWindow<ContactDevView> {
    let win = BorderlessSwiftUIWindow(resizable: true, dialog: false) {
        ContactDevView(programId: id)
    }
    win.makeKeyAndOrderFront(nil)
    return win
}

func getOrCreateContactDevWindow(id: String) -> BorderlessSwiftUIWindow<ContactDevView> {
    if let existing = NSApp.windows.compactMap({ $0 as? BorderlessSwiftUIWindow<ContactDevView> }).first {
        return existing
    }
    return contactDevForProgram(id: id)
}
